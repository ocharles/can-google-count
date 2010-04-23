package SearchFrequencies;
use Moose;
use Module::Pluggable require => 1, sub_name => '_providers', search_path => 'SearchFrequencies::Search';
use Try::Tiny;

has 'providers' => (
    isa => 'ArrayRef',
    is => 'ro',
    default => sub {
        my $self = shift;
        return [ map { $_->new } $self->_providers ];
    }
);

sub search {
    my ($self, $query) = @_;
    my $results = {};
    for my $provider (@{ $self->providers }) {
        try {
            my $count = $provider->search($query);
            $results->{ $provider->name } = $count;
        }
            catch {
                warn $_;
            }
    }
    return $results;
}

__PACKAGE__->meta->make_immutable;
1;
