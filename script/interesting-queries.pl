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

my ($sqlquery, @bind) = $sql->select('search_results', [qw( date query estimated_count )],
                                 { provider => $provider, query => { 'not_like' => '% %' } },
                                 { -asc => 'date' });


print "Stand by, fetching rows...\n";
my $sth = $dbh->prepare($sqlquery);
$sth->execute(@bind) or die "Could not execute $sqlquery";

my %counts;
my $i;

print "Parsing rows\n";
while (my $row = $sth->fetchrow_hashref) {
    print "Done $i\n" if ($i++ % 5000 == 0);

    my $date  = DateTime::Format::SQLite->parse_datetime($row->{date});
    $date     = DateTime->new( year => $date->year, month => $date->month, day => $date->day );

    my $query = $row->{query};
    my $count = $row->{estimated_count};

    $counts{$query} ||= Dissertation::Sample->new(date => $date);
    $counts{$query}->add_count($count);
}

my $out;
open($out, '>', "interesting-$provider.csv");
print $out "query,iq_range\n";

use Statistics::Descriptive;
my $st = Statistics::Descriptive::Full->new;

while (my ($query, $counter) = each %counts) {
    print "Analysing $query\n";
    printf $out sprintf "%s,%0.5f\n", $query, $counter->range;
    $st->add_data($counter->range);
}

printf $out sprintf "everything,%0.5f,%0.5f", $st->mean, $st->standard_deviation;

close($out);

sub usage {
    print "Usage: interesting-queries.pl PROVIDER\n";
}

