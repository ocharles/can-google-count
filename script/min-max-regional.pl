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

my $dbh = DBI->connect("dbi:SQLite:dbname=$Bin/../regional.db", '', '')
    or die "Cant open database connection to $Bin/../regional.db";

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
my $cutoff = DateTime->new(day => 11, month => 2, year => 2010);
while (my $row = $sth->fetchrow_hashref) {
    print "Done $i\n" if ($i++ % 5000 == 0);

    my $date  = DateTime::Format::SQLite->parse_datetime($row->{date});
    $date     = DateTime->new( year => $date->year, month => $date->month, day => $date->day );

    next unless ($date > $cutoff);

    my $query = $row->{query};
    my $count = $row->{estimated_count};

    $dates{$date->ymd} ||= {};
    $dates{$date->ymd}->{$query} ||= Dissertation::Sample->new(date => $date);
    $dates{$date->ymd}->{$query}->add_count($count);
}

my $out;
open($out, '>', "minmax-$provider.csv");
print $out "date,q1,median,q2,avg,dev\n";

my @dates = sort keys %dates;
my $last = $dates{shift @dates};
while (@dates) {
    my $date = shift @dates;

    print "Analysing $date\n";
    my $active = $dates{$date};
    my @shifts = map { ($active->{$_}->count - $last->{$_}->count) / $last->{$_}->count }
        grep { exists $last->{$_} }
        keys %$active;

    my $stat = Statistics::Descriptive::Full->new();
    $stat->add_data(@shifts);

    printf $out sprintf "%s,%0.5f,%0.5f,%0.5f,%0.5f,%0.5f\n", $date, $stat->quantile(1),
        $stat->quantile(2), $stat->quantile(3), $stat->mean, $stat->standard_deviation;

    $last = $active;
}

close($out);

sub usage {
    print "Usage: min-max.pl PROVIDER\n";
}

