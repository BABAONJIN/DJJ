package Convos::Plugin::Bot::Action;
use Mojo::Base 'Mojo::EventEmitter';

use Carp 'confess';
use Mojo::Util 'decamelize';

has config      => sub { Mojo::JSON::Pointer->new({}) };
has description => 'No description.';
has enabled     => 1;

has moniker => sub {
  my $moniker = ref $_[0];
  $moniker =~ s!^Convos::Plugin::Bot::Action::!!;
  decamelize $moniker;
};

has usage => 'Not specified.';

sub event_config {
  my ($self, $event, $key) = @_;
  my $action_class = ref $self;
  my $global       = $self->config->data;

  my $action_config = $global->{action}{$action_class};
  my $conn_config   = $event->{connection_id} && $global->{connection}{$event->{connection_id}};
  my $dialog_config
    = $event->{dialog_id} && $conn_config && $conn_config->{dialogs}{$event->{dialog_id}};

  for my $section ($conn_config, $dialog_config) {
    $section = $section && $section->{actions} && $section->{actions}{$action_class};
  }

  for my $section ($dialog_config, $conn_config, $action_config) {
    return $section->{$key} if defined $section->{$key};
  }

  return undef;
}

sub register { }
sub reply    {undef}

1;

=encoding utf8

=head1 NAME

Convos::Plugin::Bot::Action - Base class for bot actions

=head1 SYNOPSIS

  package Convos::Plugin::Bot::Action::Beans;
  use Mojo::Base "Convos::Plugin::Bot::Action";

  sub reply {
    my ($self, $event) = @_;
    return "Cool beans!" if $event->{command} =~ m/^beans/;
  }

=head1 DESCRIPTION

L<Convos::Plugin::Bot::Action> must be used as base class for
L<Convos::Plugin::Bot> actions.

=head1 ATTRIBUTES

=head2 config

  $pointer = $action->config;

Shared config parameters with L<Convos::Plugin::Bot/config>.

=head2 description

  $str = $action->description;

Holds a description of the action, which can be displayed as aid in a
conversation with the bot.

=head2 enabled

  $bool = $action->enabled;
  $action = $action->enabled(0);

Can be set to a boolean value in the config file to enable/disable a given
action.

=head2 moniker

  $str = $action->moniker;

A short nick name for the action class name.

=head2 usage

  $str = $action->usage;

Holds information about the action, which can be displayed as aid in a
conversation with the bot.

=head1 METHODS

=head2 event_config

  $any = $action->event_config(\%event, $config_key);

Used to get a L</config> parameter for the current C<$action> and an event with
C<connection_id> and C<dialog_id>.

=head2 register

  $action->register($bot, \%config);

Called the first time the C<$action> is loaded by L<Convos::Plugin::Bot>.

=head2 reply

  $str = $action->reply(\%message_event);

Can be used to generate a reply to a C<%message_event>. C<$str> must be
C<undef> for the reply to be ignored.

=head1 SEE ALSO

L<Convos::Plugin::Bot>.

=cut
