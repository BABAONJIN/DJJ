use t::Helper;

{
  my $convos = Convos->new;
  is $convos->config->{backend}, 'Convos::Core::Backend::File', 'default backend';
  is $convos->config->{name}, 'Nordaaker', 'default name';
  is $convos->config->{hypnotoad}{pid_file}, undef, 'default pid_file';
  is_deeply $convos->config->{plugins}, {}, 'default plugins';
  ok !$convos->sessions->secure, 'insecure sessions';
  like $convos->secrets->[0], qr/^[a-z0-9]{32}$/, 'default secrets';
}

{
  #$ENV{CONVOS_PLUGINS}           = 'Something'; # TODO: Cannot test until there is an actual plugin
  $ENV{CONVOS_BACKEND}           = 'Convos::Core::Backend';
  $ENV{CONVOS_FRONTEND_PID_FILE} = 'pidfile.pid';
  $ENV{CONVOS_ORGANIZATION_NAME} = 'cool.org';
  $ENV{CONVOS_SECRETS}           = 'super:duper:secret';
  $ENV{CONVOS_SECURE_COOKIES}    = 1;
  my $convos = Convos->new;
  is $convos->config->{backend}, 'Convos::Core::Backend', 'env backend';
  is $convos->config->{name}, 'cool.org', 'env name';
  ok $convos->sessions->secure, 'secure sessions';
  is_deeply($convos->secrets, [qw( super duper secret )], 'env secrets')
}

done_testing;
