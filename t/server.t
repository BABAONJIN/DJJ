use t::Helper;
use Mojo::JSON;
use Mojo::DOM;

plan skip_all => 'Live tests skipped. Set REDIS_TEST_DATABASE to "default" for db #14 on localhost or a redis:// url for custom.' unless $ENV{REDIS_TEST_DATABASE};

redis_do(
  [ hmset => 'user:doe', digest => 'E2G3goEIb8gpw', email => 'e1@convos.by', avatar => 'a1@convos.by' ],
  [ sadd => 'user:doe:connections', 'magnet' ],
  [ hmset => 'user:doe:connection:magnet', nick => 'doe' ],
);

{
  $t->get_ok('/magnet')->status_is(302);
  $t->post_ok('/login', form => { login => 'doe', password => 'barbar' })->status_is(302);
  $t->get_ok('/magnet')
    ->status_is(200)
    ->element_exists('.sidebar.container a[href="/connection/magnet/edit"]')
    ->element_exists('.sidebar.container a[href="/connection/magnet/delete"]')
    ;
}

{
  $t->get_ok('/connection/magnet/edit')
    ->status_is(200)
    ->element_exists('form[action="/connection/magnet/delete"][method="post"]')
    ;
}

if(0) {
  $t->get_ok('/connection/magnet/delete')
    ->status_is(200)
    ->element_exists('form[action="/connection/magnet/delete"][method="post"]')
    ->text_is('form .actions button', 'Yes')
    ->text_is('form .actions a[href="/magnet"]', 'No')
    ;

  $t->post_ok('/connection/magnet/delete')
    ->status_is(302)
    ->header_like(Location => qr{:\d+/convos$})
    ;
}

done_testing;
