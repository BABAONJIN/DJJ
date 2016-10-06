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
my ($err, $res);

$connection->on(
  message => sub {
    my ($self, $target, $data) = @_;
    diag "[$data->{type}] $data->{message}" if $ENV{HARNESS_IS_VERBOSE};
    $connection_log .= "[$data->{type}] $data->{message}\n";
    Mojo::IOLoop->stop if $data->{message} =~ $stop_re;
  }
);

$connection->url->parse("irc://$server");
$connection->url->query->param(tls => 0) unless $ENV{CONVOS_IRC_SSL};

$t->run(
  [],
  sub {
    $connection->send('' => '/connect', sub { ($err, $res) = @_[1, 2]; Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
    is $err, '',    'cmd /connect';
    is $res, undef, 'res /connect';
  }
);

$t->run(
  [qr{JOIN}, ['main', 'join-convos.irc']],
  sub {
    $connection->send(
      '#convos' => '/join ',    # join without a channel name
      sub { ($err, $res) = @_[1, 2]; Mojo::IOLoop->stop }
    );
    Mojo::IOLoop->start;
    is $err, 'Command missing arguments.', 'cmd /join convos';
  }
);

$t->run(
  [qr{JOIN \#convos key}, ['main', 'join-convos.irc']],
  sub {
    $connection->send(
      '#convos' => '/join #convos key',
      sub { ($err, $res) = @_[1, 2]; Mojo::IOLoop->stop }
    );
    Mojo::IOLoop->start;
    is $err, '', 'cmd /join convos';
    is $res->{topic}, 'some cool topic', 'res /join convos';
  }
);

$t->run(
  [qr{NICK}, ['main', 'nick-supermanx.irc']],
  sub {
    $connection->send(
      "#does_not_matter" => "/nick supermanx",
      sub { ($err, $res) = @_[1, 2]; Mojo::IOLoop->stop }
    );
    Mojo::IOLoop->start;
    is $err, '',    'cmd /nick supermanx';
    is $res, undef, 'res /nick supermanx';
  }
);

$t->run(
  [],
  sub {
    $connection->send(
      "#convos" => "/me is afk",
      sub { ($err, $res) = @_[1, 2]; Mojo::IOLoop->stop }
    );
    Mojo::IOLoop->start;
    is $err, '',    'cmd /say';
    is $res, undef, 'res /say';
  }
);

$t->run(
  [],
  sub {
    $connection->send(
      "#convos" => "/say /some/stuff",
      sub { ($err, $res) = @_[1, 2]; Mojo::IOLoop->stop }
    );
    Mojo::IOLoop->start;
    is $err, '',    'cmd /say';
    is $res, undef, 'res /say';
  }
);

$t->run(
  [],
  sub {
    $connection->send(
      "#convos" => "/msg somebody /some/stuff",
      sub { ($err, $res) = @_[1, 2]; Mojo::IOLoop->stop }
    );
    Mojo::IOLoop->start;
    is $err, '',    'cmd /say';
    is $res, undef, 'res /say';
  }
);

$t->run(
  [qr{TOPIC}, ['main', 'set-topic.irc']],
  sub {
    $connection->send(
      "#convos" => "/topic Cool topic",
      sub { ($err, $res) = @_[1, 2]; Mojo::IOLoop->stop }
    );
    Mojo::IOLoop->start;
    is $err, '', 'cmd /topic set';
  }
);

$t->run(
  [qr{TOPIC}, ['main', 'get-topic.irc']],
  sub {
    $connection->send("#convos" => "/topic", sub { ($err, $res) = @_[1, 2]; Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
    is $err, '', 'cmd /topic get';
    is $res->{topic}, 'Cool topic', 'res /topic get';
  }
);

$t->run(
  [qr{PART}, ['main', 'part-does-not-matter.irc']],
  sub {
    $connection->send(
      "#does_not_matter" => "/part",
      sub { ($err, $res) = @_[1, 2]; Mojo::IOLoop->stop }
    );
    Mojo::IOLoop->start;
    is $err, 'Illegal channel name', 'cmd /part does_not_matter';
    is $res, undef, 'res /part does_not_matter';
  }
);

$t->run(
  [qr{PART}, ['main', 'part-convos.irc']],
  sub {
    $connection->send(
      "#does_not_matter" => "/part #convos",
      sub { ($err, $res) = @_[1, 2]; Mojo::IOLoop->stop }
    );
    Mojo::IOLoop->start;
    is $err, '',    'cmd /part convos';
    is $res, undef, 'res /part convos';
  }
);

# make sure we have a dialog
$t->run(
  [qr{JOIN \#convos}, ['main', 'join-convos.irc']],
  sub {
    $connection->send('#convos' => '/join #convos', sub { Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
  }
);

$t->run(
  [],
  sub {
    $connection->send('' => '/disconnect', sub { ($err, $res) = @_[1, 2]; Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
    is $err, '',    'cmd /disconnect';
    is $res, undef, 'res /disconnect';
    ok !$connection->{_irc}, 'disconnected from irc server';
  }
);

$connection->on_connect_commands(['/msg NickServ identify s3cret']);

$t->run(
  [
    qr{NICK supermanx}   => ['main', 'welcome.irc'],
    qr{JOIN}             => ['main', 'join-convos.irc'],
    qr{PRIVMSG NickServ} => ['main', 'identify.irc'],
  ],
  sub {
    my $irc = $connection->_irc;
    my @e;
    $connection->connect(sub { });
    $t->on($irc, irc_join    => sub { push @e, 'irc_join' });
    $t->on($irc, irc_privmsg => sub { push @e, 'irc_privmsg' });
    $t->on($irc, irc_privmsg => sub { Mojo::IOLoop->stop });
    Mojo::IOLoop->start;
    is_deeply(\@e, [qw(irc_join irc_privmsg)], 'run through the correct events');
  }
);

done_testing;

__DATA__
@@ join-convos.irc
:Superman20001!superman@i.love.debian.org JOIN :#convos
:hybrid8.debian.local 332 Superman20001 #convos :some cool topic
:hybrid8.debian.local 333 Superman20001 #convos jhthorsen!jhthorsen@i.love.debian.org 1432932059
:hybrid8.debian.local 353 Superman20001 = #convos :Superman20001 @batman
:hybrid8.debian.local 366 Superman20001 #convos :End of /NAMES list.
@@ part-does-not-matter.irc
:hybrid8.debian.local 479 Superman20001 #does_not_matter :Illegal channel name
@@ part-convos.irc
:test21362!~test96908@0::1 PART #convos
@@ nick-supermanx.irc
:Superman20001!superman@i.love.debian.org NICK :supermanx
@@ get-topic.irc
:hybrid8.debian.local 332 batman_ #convos :Cool topic
:hybrid8.debian.local 333 batman_ #convos batman_!superman@i.love.debian.org 1433007153
@@ set-topic.irc
:batman_!superman@i.love.debian.org TOPIC #convos :Cool topic
@@ welcome.irc
:hybrid8.debian.local 001 superman :Welcome to the debian Internet Relay Chat Network superman
@@ identify.irc
:NickServ!clark.kent\@i.love.debian.org PRIVMSG #supermanx :You are now identified for batman
