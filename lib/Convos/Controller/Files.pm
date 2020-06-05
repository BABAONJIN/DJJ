package Convos::Controller::Files;
use Mojo::Base 'Mojolicious::Controller';

use Convos::Util 'E';

sub get {
  my $self = shift;

  # Make sure we don't get 501 Not implemented if this is an API request
  $self->stash(for_cms => 1, handler => 'ep', openapi => 'Should never be rendered.');

  return $self->files->serve({
    fid    => $self->stash('fid'),
    format => $self->stash('format') || '',
    uid    => $self->stash('uid'),
  });
}

sub upload {
  my $self = shift;

  # TODO: Move this to Mojolicious::Plugin::OpenAPI
  # Handle "Maximum message size exceeded"
  my $error = $self->req->error;
  $self->render(openapi => E($error->{message}, '/file'), status => 400) if $error;

  return unless $self->openapi->valid_input;
  return $self->unauthorized unless my $user = $self->backend->user;

  my $upload = $self->req->upload('file');
  my $err;
  return $self->render(openapi => E($err, '/file'), status => 400)
    if $err = !$upload ? 'No upload.' : !$upload->filename ? 'Unknown filename.' : '';

  my %args = (filename => $upload->filename);
  $args{id}         = $self->param('id')         if defined $self->param('id');
  $args{write_only} = $self->param('write_only') if defined $self->param('write_only');
  return $self->files->save_p($upload->asset, \%args)
    ->then(sub { $self->render(openapi => {files => [shift]}) });
}

1;

=encoding utf8

=head1 NAME

Convos::Controller::Files - Convos file actions

=head1 DESCRIPTION

L<Convos::Controller::Files> is a L<Mojolicious::Controller> with
user files related actions.

=head1 METHODS

=head2 get

See L<https://convos.chat/api.html#op-get--file--uid--fid>.

=head2 upload

See L<https://convos.chat/api.html#op-post--file>.

=head1 SEE ALSO

L<Convos>.

=cut
