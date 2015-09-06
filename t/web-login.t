use t::Helper;

$ENV{CONVOS_BACKEND} = 'Convos::Core::Backend';
my $t = t::Helper->t;

$t->app->core->user('superman@example.com', {avatar => 'avatar@example.com'})->set_password('s3cret');

$t->get_ok('/1.0/user')->status_is(401);

$t->post_ok('/1.0/user/login', json => {email => 'xyz', password => 'foo'})->status_is(400)
  ->json_is('/errors/0', {message => 'Does not match email format.', path => '/data/email'});

$t->post_ok('/1.0/user/login', json => {email => 'superman@example.com'})->status_is(400)
  ->json_is('/errors/0/path', '/data/password');

$t->post_ok('/1.0/user/login', json => {email => 'superman@example.com', password => 'xyz'})->status_is(400)
  ->json_is('/errors/0', {message => 'Invalid email or password.', path => '/'});

$t->post_ok('/1.0/user/login', json => {email => 'superman@example.com', password => 's3cret'})->status_is(200)
  ->json_is('/avatar', 'avatar@example.com')->json_is('/email', 'superman@example.com')
  ->json_like('/registered', qr/^[\d-]+T[\d:]+Z$/);

$t->get_ok('/1.0/user')->status_is(200);

done_testing;
