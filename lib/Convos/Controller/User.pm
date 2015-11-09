package Convos::Controller::User;

=head1 NAME

Convos::Controller::User - Convos user actions

=head1 DESCRIPTION

L<Convos::Controller::User> is a L<Mojolicious::Controller> with
user related actions.

=cut

use Mojo::Base 'Mojolicious::Controller';

=head1 METHODS

=head2 delete

See L<Convos::Manual::API/deleteUser>.

=cut

sub delete {
  my ($self, $args, $cb) = @_;
  my $user = $self->backend->user or return $self->unauthorized($cb);

  if (@{$self->app->core->users} <= 1) {
    return $self->$cb($self->invalid_request('You are the only user left.'), 400);
  }

  $self->delay(
    sub { $self->app->core->backend->delete_object($user, shift->begin) },
    sub {
      my ($delay, $err) = @_;
      die $err if $err;
      delete $self->session->{email};
      $self->$cb({message => 'You have been erased.'}, 200);
    },
  );
}

=head2 get

See L<Convos::Manual::API/getUser>.

=cut

sub get {
  my ($self, $args, $cb) = @_;
  my $user = $self->backend->user or return $self->unauthorized($cb);

  $self->$cb($user->TO_JSON, 200);
}

=head2 login

See L<Convos::Manual::API/loginUser>.

=cut

sub login {
  my ($self, $args, $cb) = @_;
  my $user = $self->app->core->user($args->{body}{email});

  if ($user and $user->validate_password($args->{body}{password})) {
    $self->session(email => $user->email)->$cb($user->TO_JSON, 200);
  }
  else {
    $self->$cb($self->invalid_request('Invalid email or password.'), 400);
  }
}

=head2 logout

See L<Convos::Manual::API/logoutUser>.

=cut

sub logout {
  my ($self, $args, $cb) = @_;
  $self->session({expires => 1});
  $self->$cb({}, 200);
}

=head2 register

See L<Convos::Manual::API/registerUser>.

=cut

sub register {
  my ($self, $args, $cb) = @_;
  my $user = $self->app->core->user($args->{body}{email});

  # TODO: Add support for invite code

  if ($user) {
    return $self->$cb($self->invalid_request('Email is taken.', '/body/email'), 409);
  }

  $self->delay(
    sub {
      my ($delay) = @_;
      $user = $self->app->core->user($args->{body});
      $user->set_password($args->{body}{password});
      $user->save($delay->begin);
    },
    sub {
      my ($delay, $err) = @_;
      die $err if $err;
      $self->session(email => $user->email)->$cb($user->TO_JSON, 200);
    },
  );
}

=head2 update

See L<Convos::Manual::API/updateUser>.

=cut

sub update {
  my ($self, $args, $cb) = @_;
  my $user = $self->backend->user or return $self->unauthorized($cb);

  # TODO: Add support for changing email

  unless (%{$args->{body} || {}}) {
    return $self->$cb($user->TO_JSON, 200);
  }

  $self->delay(
    sub {
      my ($delay) = @_;
      $user->avatar($args->{body}{avatar}) if defined $args->{body}{avatar};
      $user->set_password($args->{body}{password}) if $args->{body}{password};
      $user->save($delay->begin);
    },
    sub {
      my ($delay, $err) = @_;
      die $err if $err;
      $self->$cb($user->TO_JSON, 200);
    },
  );
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut

1;
