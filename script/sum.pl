use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/../lib";

use DBI;
use DateTime::Format::SQLite;
use Dissertation::Sample;
use List::Util qw( min max sum );
use SQL::Abstract;
use Statistics::Descriptive;

my $dbh = DBI->connect("dbi:SQLite:dbname=$Bin/../search_results.db", '', '')
    or die "Cant open database connection to $Bin/../search_results.db";

my $sql = SQL::Abstract->new();

my $provider = join " ", @ARGV or die usage();

my ($sqlquery, @bind) = $sql->select('search_results', [qw( date query estimated_count )], { provider => $provider },
                                 { -asc => 'date' });


print "Stand by, fetching rows...\n";
my $sth = $dbh->prepare($sqlquery);
$sth->execute(@bind) or die "Could not execute $sqlquery";

my %dates;
my $i;

print "Parsing rows\n";
while (my $row = $sth->fetchrow_hashref) {
    print "Done $i\n" if ($i++ % 5000 == 0);

    my $date  = DateTime::Format::SQLite->parse_datetime($row->{date});
    $date     = DateTime->new( year => $date->year, month => $date->month, day => $date->day );

    my $query = $row->{query};
    my $count = $row->{estimated_count};

    $dates{$date->ymd} += $count;
}

my $out;
open($out, '>', "sum-$provider.csv");
print $out "date,sum\n";

my @dates = sort keys %dates;
my $last = $dates{shift @dates};
while (my ($date, $sum) = each %dates) {
    print "Analysing $date\n";
    printf $out sprintf "%s,%d\n", $date, $sum;
}

close($out);

sub usage {
    print "Usage: min-max.pl PROVIDER\n";
}

