use MooseX::Declare;

class Dissertation::Sample {
    use List::Util qw( sum );
    use MooseX::Types::Moose qw( ArrayRef Int );
    use MooseX::Types::DateTime qw( DateTime );
    use Statistics::Descriptive;

    has 'count' => (
        isa => ArrayRef[Int],
        default => sub { [] },
        traits  => [ 'Array' ],
        handles => {
            add_count => 'push',
            all_counts => 'elements',
            n_counts => 'count',
        }
    );

    has 'date' => (
        isa => DateTime,
        is  => 'rw',
        required => 1
    );

    sub count {
        my ($self) = @_;
        return sum($self->all_counts) / $self->n_counts;
    }

    sub range {
        my $self = shift;
        my $stat = Statistics::Descriptive::Full->new;
        $stat->add_data($self->all_counts);
        return ($stat->quantile(3) - $stat->quantile(1)) / $stat->mean;
    }
};
