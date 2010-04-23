use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/../lib";

use DBI;
use DateTime::Format::SQLite;
use Dissertation::Sample;
use SQL::Abstract;
use Statistics::Descriptive;

my $dbh = DBI->connect("dbi:SQLite:dbname=$Bin/../search_results.db", '', '')
    or die "Cant open database connection to $Bin/../search_results.db";

my $sql = SQL::Abstract->new();

my ($sqlquery, @bind) = $sql->select('search_results', 'distinct(query)');
my $query_sth = $dbh->prepare($sqlquery);

printf "Finding all queries\n";
$query_sth->execute(@bind) or die "Could not execute $sqlquery";

my %devs = (
    'Google' => {},
    'Bing'   => {},
    'Yahoo!' => {},
);

while (my ($query) = $query_sth->fetchrow_array) {
#for my $query (qw( "America" "April" )) {
    print "Processing $query\n";

    my ($sqlquery, @bind) = $sql->select('search_results', [qw( date provider estimated_count )],
                                     { query => $query },
                                     { -asc => 'date' });

    my $sth = $dbh->prepare($sqlquery);
    $sth->execute(@bind) or die "Could not execute $sqlquery";

    my (%last, %active);
    my %samples;

    while (my $row = $sth->fetchrow_hashref) {
        my $date  = DateTime::Format::SQLite->parse_datetime($row->{date});
        $date     = DateTime->new( year => $date->year, month => $date->month, day => $date->day );
        my $prov  = $row->{provider};
        my $count = $row->{estimated_count};

        if (!$last{$prov} || $date->ymd ne $last{$prov}->date->ymd) {
            $last{$prov} = $active{$prov} = Dissertation::Sample->new(date => $date);

            $samples{$prov} ||= [];
            push @{ $samples{$prov} }, $active{$prov};
        }

        $active{$prov}->add_count($count);
    }

    my $out;
    while (my ($prov, $s) = each %samples) {
        my @samples = @$s;

        my $stat = Statistics::Descriptive::Sparse->new();

        my $last = shift @samples;
        while (@samples) {
            my $this = shift @samples;
            $stat->add_data(($this->count - $last->count) / $last->count);
            $last = $this;
        }

        $devs{ $prov }->{ $stat->standard_deviation } = $query;
    }
}

while (my ($prov, $devs) = each %devs) {
    my $out;
    open ($out, '>', "std-dev-$prov.csv");

    for my $stddev (sort { $b <=> $a } keys %$devs) {
        printf $out "%f,%s\n", $stddev, $devs->{$stddev};
    }
}
