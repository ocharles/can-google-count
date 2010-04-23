package SearchFrequencies::Search;
use Moose::Role;

requires 'search';

has 'name' => (
    isa => 'Str',
    is => 'ro',
    required => 1,
);

1;
