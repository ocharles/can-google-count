use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/../lib";

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
    open($out, '>', "$query-$prov.csv");

    my $last = shift @samples;
    #print $out sprintf "%s,0", $last->date->ymd;
    while (@samples) {
        my $this = shift @samples;
        print $out sprintf "%s,%0.5f\n", $this->date->ymd, ($this->count - $last->count) / $last->count;
        $last = $this;
    }

    close($out);
}

sub usage {
    print "Usage: all-query-shift.pl QUERY\n";
}

