use t::Helper;

$ENV{CONVOS_BACKEND} = 'Convos::Core::Backend';
my $t = t::Helper->t;
my $user = $t->app->core->user('superman@example.com', {avatar => 'avatar@example.com'})->set_password('s3cret');

$t->get_ok('/1.0/connections')->status_is(401);
$t->post_ok('/1.0/connections', json => {url => 'irc://localhost:3123'})->status_is(401);
$t->post_ok('/1.0/user/login', json => {email => 'superman@example.com', password => 's3cret'})->status_is(200);
$t->get_ok('/1.0/connections')->status_is(200)->json_is('/connections', []);

$t->post_ok('/1.0/connections', json => {url => 'irc://localhost:3123'})->status_is(200);

$t->post_ok('/1.0/connections', json => {url => 'irc://irc.perl.org:6667'})->status_is(200);

$t->post_ok('/1.0/connections', json => {url => 'irc://irc.perl.org:6667'})->status_is(400)
  ->json_is('/errors/0/message', 'Connection already exists.');

$t->post_ok('/1.0/connections', json => {url => 'foo://irc.perl.org:6667'})->status_is(400)
  ->json_is('/errors/0/message', 'Could not find connection class from scheme.');

$user->connection(irc => 'localhost', {})->state('connected');
$t->get_ok('/1.0/connections')->status_is(200)
  ->json_is('/connections/0', {name => 'localhost', state => 'connected',  url => 'irc://localhost:3123'})
  ->json_is('/connections/1', {name => 'magnet',    state => 'connecting', url => 'irc://irc.perl.org:6667'});

$t->post_ok('/1.0/connection/irc/doesnotexist', json => {url => 'foo://perl.org:9999'})->status_is(404);
$t->post_ok('/1.0/connection/irc/magnet',       json => {})->status_is(200);
$t->post_ok('/1.0/connection/irc/localhost',    json => {url => 'foo://perl.org:9999'})->status_is(200)
  ->json_is('/name' => 'localhost')->json_is('/state' => 'connecting')
  ->json_is('/url' => 'irc://perl.org:9999?nick=superman');

done_testing;
