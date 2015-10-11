use t::Helper;

$ENV{CONVOS_BACKEND} = 'Convos::Core::Backend';
my $t = t::Helper->t;

$t->get_ok('/api/user')->status_is(401)->json_is('/errors/0/message', 'Need to log in first.');
$t->delete_ok('/api/user')->status_is(401)->json_is('/errors/0/message', 'Need to log in first.');
$t->post_ok('/api/user', json => {})->status_is(401)->json_is('/errors/0/message', 'Need to log in first.')
  ->json_is('/errors/0/path', '/');

$t->post_ok('/api/user/register', json => {email => 'superman', password => 'xyz'})->status_is(400)
  ->json_is('/errors/0', {message => 'Does not match email format.', path => '/body/email'});

$t->post_ok('/api/user/register', json => {email => 'superman@example.com', password => 's3cret'})->status_is(200)
  ->json_is('/avatar', '')->json_is('/email', 'superman@example.com')->json_like('/registered', qr/^[\d-]+T[\d:]+Z$/);

$t->post_ok('/api/user', json => {})->status_is(200)->json_is('/avatar', '');

my $registered = $t->tx->res->json->{registered};
$t->post_ok('/api/user', json => {avatar => 'avatar@example.com'})->status_is(200)
  ->json_is('/avatar', 'avatar@example.com');

$t->get_ok('/api/user')->status_is(200)
  ->json_is('', {avatar => 'avatar@example.com', email => 'superman@example.com', registered => $registered});

$t->delete_ok('/api/user')->status_is(400)->json_is('/errors/0/message', 'You are the only user left.');

$t->get_ok('/api/user/logout')->status_is(200);
$t->get_ok('/api/user')->status_is(401);

done_testing;
