use strict;
use warnings;

use Math::BigInt;

use FindBin '$Bin';
use lib "$Bin/../lib";

use DBI;
use DateTime::Format::SQLite;
use SQL::Abstract;

my $dbh = DBI->connect("dbi:SQLite:dbname=$Bin/../search_results.db", '', '')
    or die "Cant open database connection to $Bin/../search_results.db";

my $sql = SQL::Abstract->new();

my $provider = (join " ", @ARGV) or die usage();

my ($sqlquery, @bind) = $sql->select('search_results', [qw( date query provider estimated_count )],
                                 { provider => $provider },
                                 { -asc => 'date' });

my $sth = $dbh->prepare($sqlquery);
print "$sqlquery\n", @bind;
$sth->execute(@bind) or die "Could not execute $sqlquery";

# Query => (Date => Freq)
my (%freqs);

while (my $row = $sth->fetchrow_hashref) {
    my $date  = DateTime::Format::SQLite->parse_datetime($row->{date});
    $date     = DateTime->new( year => $date->year, month => $date->month, day => $date->day );
    my $query = $row->{query};
    my $count = Math::BigInt->new($row->{estimated_count});

    $freqs{$query} ||= [];
    push @{ $freqs{$query} }, $count;
}

use IO::All;
use Statistics::LSNoHistory;
use Statistics::Descriptive;

my $out = io("regression-$provider.csv");
my $all = Statistics::Descriptive::Full->new;

$out < '';

while (my ($query, $freqs) = each %freqs) {
    my $regression = Statistics::LSNoHistory->new;

    my $i = 0;
    $regression->append_points( map { $i++ => $_} @$freqs );

    use Devel::Dwarn;
    Dwarn $regression->dump_stats;


    $all->add_data($regression->slope);
    $out << sprintf "%s,%0.5f\n", $query, $regression->slope;
}

$out << sprintf ",%0.5f,%0.5f\n", $all->mean, $all->standard_deviation;

sub usage {
    print "Usage: all-query-shift.pl QUERY\n";
}

