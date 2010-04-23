package SearchFrequencies::HttpSearch;
use Moose::Role;

has 'end_point' => (
    isa => 'Str',
    is => 'rw',
    required => 1,
);

has '_ua' => (
    isa => 'LWP::UserAgent',
    is => 'ro',
    default => sub {
        my $ua = LWP::UserAgent->new;
        $ua->env_proxy;
        return $ua;
    }
);

sub form_url {
    my ($self, %params) = @_;
    my $url = $self->end_point . '?' . join '&',
        map { $_ . '=' . $params{$_} } keys %params;
}

1;
