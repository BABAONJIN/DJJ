use t::Helper;
use Convos::Core;
use Convos::Core::Backend::File;

$ENV{CONVOS_HOME} = File::Spec->catdir(qw( t data convos-test-backend-file-messages ));

my $core = Convos::Core->new(backend => Convos::Core::Backend::File->new);
my $user = $core->user({email => 'superman@example.com'});
my $connection = $user->connection({name => 'localhost', protocol => 'irc'});
my $conversation = $connection->conversation('#convos', {});
my ($err, $messages);

$conversation->messages({}, sub { ($err, $messages) = @_[1, 2]; Mojo::IOLoop->stop; });
Mojo::IOLoop->start;
is int @$messages, 60, 'got max limit messages' or diag $err;
is $messages->[0]{ts},  '2015-06-21T14:12:17', 'first: 2015-06-21T14:12:17';
is $messages->[-1]{ts}, '2015-06-22T10:23:50', 'last: 2015-06-22T10:23:50';

$conversation->messages({match => 'iotop'}, sub { ($err, $messages) = @_[1, 2]; Mojo::IOLoop->stop; });
Mojo::IOLoop->start;
is int @$messages, 2, 'two messages matching iotop' or diag $err;
is $messages->[0]{ts}, '2015-06-21T10:13:32', 'first: 2015-06-21T10:13:32';

$conversation->messages({limit => 2, match => qr{\bpacka\w+\b}},
  sub { ($err, $messages) = @_[1, 2]; Mojo::IOLoop->stop; });
Mojo::IOLoop->start;
is int @$messages, 2, 'two messages matching package because of limit' or diag $err;
is $messages->[0]{ts}, '2015-06-22T10:13:29', 'first: 2015-06-22T10:13:29';

done_testing;
