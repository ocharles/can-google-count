use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/../lib";

use bigint;
use DBI;
use DateTime::Format::SQLite;
use Dissertation::Sample;
use SQL::Abstract;

my $dbh = DBI->connect("dbi:SQLite:dbname=$Bin/../search_results.db", '', '')
    or die "Cant open database connection to $Bin/../search_results.db";

my $sql = SQL::Abstract->new();

my $query    = (join " ", @ARGV) or die usage();

my ($sqlquery, @bind) = $sql->select('search_results', [qw( date provider estimated_count )],
                                 { query => '"' . $query . '"' },
                                 { -asc => 'date' });

my $sth = $dbh->prepare($sqlquery);
print "$sqlquery\n", @bind;
$sth->execute(@bind) or die "Could not execute $sqlquery";

my %counts;

while (my $row = $sth->fetchrow_hashref) {
    my $date  = DateTime::Format::SQLite->parse_datetime($row->{date});
    last if ($date->day > 9 && $date->month == 2);

    my $prov  = $row->{provider};
    my $count = $row->{estimated_count};

    $counts{$prov} ||= [];
    push @{ $counts{$prov} }, { date => $date, count => $count };
}

my $out;

while (my ($prov, $counts) = each %counts) {
    open($out, '>', "$query-$prov-freq.csv");

    for my $count (@$counts) {
        print $out sprintf "%s,%0.5f\n", $count->{date}, $count->{count};
    }

    close($out);
}

sub usage {
    print "Usage: all-query-shift.pl QUERY\n";
}

