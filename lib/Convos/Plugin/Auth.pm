package Convos::Plugin::Auth;
use Mojo::Base 'Convos::Plugin', -async_await;

use Mojo::JSON qw(encode_json false true);
use Mojo::Util;

sub register {
  my ($self, $app, $config) = @_;

  $app->helper('auth.login_p'    => \&_login_p);
  $app->helper('auth.logout_p'   => \&_logout_p);
  $app->helper('auth.register_p' => \&_register_p);
  $app->helper('backend.user_p'  => \&_backend_user_p);
}

async sub _backend_user_p {
  my $c     = shift;
  my $email = shift || $c->session('email')              or return undef;
  my $user  = $c->app->core->get_user({email => $email}) or return undef;

  # Keep track of remote address
  my $remote_address = $user && $c->tx->remote_address;
  $user->remote_address($remote_address)->save_p unless $user->remote_address eq $remote_address;

  # Save the user to stash for easier access later on
  return $c->stash->{user} = $user;
}

sub _login_p {
  my ($c, $args) = @_;
  my $user = $c->app->core->get_user($args);

  my $success = $user && $user->validate_password($args->{password});
  Convos::Plugin::Auth::_log_attempt($c, $user ? $user->TO_JSON : $args, $success);

  return Mojo::Promise->resolve($user) if $success;
  return Mojo::Promise->reject('Invalid email or password.');
}

sub _log_attempt {
  my ($c, $args, $success) = @_;
  my $level = $success ? 'info' : 'warn';
  $c->app->log->$level(
    sprintf 'login_p(%s) %s %s.',
    encode_json({email => $args->{email}, remote_address => $c->tx->remote_address}),
    $success ? 'SUCCESS' : 'FAIL',
    $success ? 'Valid email and password.' : $args->{uid} ? 'Invalid password' : 'Invalid email',
  );
}

sub _logout_p {
  my ($c, $args) = @_;
  return Mojo::Promise->resolve;
}

sub _register_p {
  my ($c, $args) = @_;
  my $core = $c->app->core;

  return Mojo::Promise->reject('Email is taken.') if $core->get_user($args);
  return $core->user($args)->set_password($args->{password})->save_p;
}

1;

=encoding utf8

=head1 NAME

Convos::Plugin::Auth - Convos plugin for handling authentication

=head1 DESCRIPTION

L<Convos::Plugin::Auth> is used to register, login and logout a user. This
plugin is always loaded by L<Convos>, but you can override the L</HELPERS>
with a custom auth plugin if you like.

Note that this plugin is currently EXPERIMENTAL. Let us know if you are/have
created a custom plugin.

=head1 HELPERS

=head2 auth.login_p

  $user = await $c->auth->login_p(\%credentials);

Used to login a user. C<%credentials> normally contains an C<email> and
C<password>.

=head2 auth.logout

  $p = $c->auth->logout_p({});

Used to log out a user.

=head2 auth.register

  $user = await $c->auth->register(\%credentials);

Used to register a user. C<%credentials> normally contains an C<email> and
C<password>.

=head2 backend.user_p

  $user = await $c->backend->user_p($email);
  $user = await $c->backend->user_p;

Used to return a L<Convos::User> object representing the logged in user
or a user with email C<$email>. This helper will also store the user
object in L<Mojolicious::Controller/stash> under the "user" key.

=head1 METHODS

=head2 register

  $auth->register($app, \%config);

=head1 SEE ALSO

L<Convos>

=cut
