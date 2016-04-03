use Test::Mojo::IRC -basic;
use t::Helper;
use Mojo::IOLoop;
use Convos::Core;

my $t              = Test::Mojo::IRC->new;
my $server         = $t->start_server;
my $core           = Convos::Core->new;
my $user           = $core->user({email => 'superman@example.com'});
my $connection     = $user->connection({name => 'localhost', protocol => 'irc'});
my $stop_re        = qr{should_not_match};
my $connection_log = '';

$connection->on(
  message => sub {
    my ($self, $target, $data) = @_;
    diag "[$data->{type}] $data->{message}" if $ENV{HARNESS_IS_VERBOSE};
    $connection_log .= "[$data->{type}] $data->{message}\n";
    Mojo::IOLoop->stop if $data->{message} =~ $stop_re;
  }
);
$connection->on(
  dialog => sub {
    my ($self, $dialog, $changed) = @_;
    if ($ENV{HARNESS_IS_VERBOSE}) {
      diag "[dialog=$dialog->{id}] " . join ' ', map {
        sprintf '%s=%s', $_,
          Data::Dumper->new([$changed->{$_}])->Indent(0)->Sortkeys(1)->Terse(1)->Dump
      } keys %$changed;
    }
  }
);

is $connection->nick, "superman", 'nick attribute';
is $connection->nick("Superman20001", sub { }), $connection, 'set offline nick';
is $connection->nick, "Superman20001", 'changed nick attribute';

{
  my $err;
  $connection->url->parse("irc://$server");
  $connection->url->query->param(tls => 0) unless $ENV{CONVOS_IRC_SSL};
  is $connection->connect(sub { $err = $_[1]; Mojo::IOLoop->stop; }), $connection, 'connect: async';
  Mojo::IOLoop->start;
  is $err, '', 'connect: success';
}

$t->run(
  [qr{LIST}, ['main', 'channel-list.irc']],
  sub {
    my ($err, $list);
    $connection->rooms(sub { ($err, $list) = (@_[1, 2]); Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
    @$list = sort { $a->{name} cmp $b->{name} } @$list;
    is $err, '', 'rooms';
    ok @$list == 3, 'list of rooms' or diag int @$list;
    $list = [grep { $_->{name} eq "#Convos_irc_LIVE_20001" } @$list];
  }
);

$t->run(
  [qr{NICK}, ['main', 'nick-supermanx.irc'], qr{NICK}, ['main', 'nick-in-use.irc']],
  sub {
    my ($err, $nick);

    $connection->nick(sub { ($err, $nick) = @_[1, 2] });
    is $nick, "Superman20001", 'get online nick';

    $connection->nick("SupermanX20001", sub { $err = $_[1]; Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
    is $err, '', 'set online nick';

    $connection->nick(batman => sub { $err = $_[1]; Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
    like $err, qr{in use}, 'nick in use';
  }
);

$t->run(
  [qr{PRIVMSG}, ['main', 'no-such-channel.irc']],
  sub {
    $connection->send("#no_such_channel_" => "some message", sub { });
    $stop_re = qr{No such nick or channel};
    Mojo::IOLoop->start;
    like $connection_log, $stop_re, '...such nick or channel';
  }
);

$t->run(
  [],
  sub {
    my $err;
    $connection->send("#convos" => "i am test 20001", sub { $err = $_[1]; Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
    is $err, '', 'send: to convos';
  }
);

$t->run(
  [qr{TOPIC}, ['main', 'no-topic.irc']],
  sub {
    my ($err, $topic);
    $connection->topic("#convos_irc_live_20001",
      sub { ($err, $topic) = @_[1, 2]; Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
    is $err, '', 'no topic error';
    is_deeply $topic, {message => ''}, 'no topic';
  }
);

$t->run(
  [qr{TOPIC}, ['main', 'set-topic.irc'], qr{TOPIC}, ['main', 'get-topic.irc']],
  sub {
    my ($err, $topic);

    $connection->topic("#convos_irc_live_20001", "Cool topic",
      sub { $err = $_[1]; Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
    is $err, '', 'topic set error';

    $connection->topic("#convos_irc_live_20001",
      sub { ($err, $topic) = @_[1, 2]; Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
    is_deeply $topic, {message => 'Cool topic'}, 'topic was changed';
  }
);

$t->run(
  [qr{TOPIC}, ['main', 'topic-not-channel-operator.irc']],
  sub {
    my $err;
    $connection->topic("#convos", "Cool topic", sub { $err = $_[1]; Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
    is $err, "You're not channel operator", 'topic: not channel operator';
  }
);

my $json = $connection->TO_JSON(1);
cmp_deeply(
  $json,
  {
    dialogs => bag(
      {
        connection_id => 'irc-localhost',
        frozen        => '',
        id            => '#convos',
        is_private    => 0,
        name          => '#convos',
        password      => '',
        topic         => '',
      },
      {
        connection_id => 'irc-localhost',
        frozen        => '',
        id            => '#no_such_channel_',
        is_private    => 0,
        name          => '#no_such_channel_',
        password      => '',
        topic         => '',
      },
      {
        connection_id => 'irc-localhost',
        frozen        => '',
        id            => '#convos_irc_live_20001',
        is_private    => 0,
        name          => '#Convos_irc_LIVE_20001',
        password      => '',
        topic         => 'Cool topic',
      }
    ),
    id       => 'irc-localhost',
    name     => 'localhost',
    protocol => 'irc',
    state    => 'queued',
    url      => re(qr{^irc://.*\?tls=0}),
  },
  'connection->TO_JSON(1)'
);

done_testing;

__DATA__
@@ channel-list.irc
:hybrid8.debian.local 321 Superman20001 Channel :Users  Name
:hybrid8.debian.local 322 Superman20001 #Convos_irc_LIVE_20001 1 :[+nt]
:hybrid8.debian.local 322 Superman20001 #test123 1 :[+nt]
:hybrid8.debian.local 322 Superman20001 #convos 2 :[+nt] some cool topic
:hybrid8.debian.local 323 Superman20001 :End of /LIST
@@ nick-supermanx.irc
:Superman20001!superman@i.love.debian.org NICK :SupermanX20001
@@ nick-in-use.irc
:hybrid8.debian.local 433 SupermanX20001 batman :Nickname is already in use.
@@ no-topic.irc
:hybrid8.debian.local 331 batman_ #Convos_irc_LIVE_20001 :No topic is set.
@@ set-topic.irc
:batman_!superman@i.love.debian.org TOPIC #Convos_irc_LIVE_20001 :Cool topic
@@ get-topic.irc
:hybrid8.debian.local 332 batman_ #Convos_irc_LIVE_20001 :Cool topic
:hybrid8.debian.local 333 batman_ #Convos_irc_LIVE_20001 batman_!superman@i.love.debian.org 1433007153
@@ topic-not-channel-operator.irc
:hybrid8.debian.local 482 batman_ #convos :You're not channel operator
@@ no-such-channel.irc
:hybrid8.debian.local 401 batman_ #no_such_channel_ :No such nick/channel
