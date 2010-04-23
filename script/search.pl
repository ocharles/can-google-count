use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use SearchFrequencies;
use SearchFrequencies::Search::Google;
use SearchFrequencies::Search::Yahoo;
use SearchFrequencies::Search::Bing;

use DBI;
use DateTime::Format::SQLite;

my $dbh =
  DBI->connect("dbi:SQLite:dbname=$FindBin::Bin/../search_results.db", "", "");
my $insert =
  "INSERT INTO search_results (query, date, estimated_count, provider) VALUES (?, ?, ?, ?)";
my $sth = $dbh->prepare($insert);

my @words;

open(my $term_file, '<', "$FindBin::Bin/queries.txt");
while (my $line = <$term_file>) {
    chomp $line;
    push @words, $line;
}
close($term_file);

my $search = SearchFrequencies->new(
     providers => [
#         SearchFrequencies::Search::Google->new,
#         SearchFrequencies::Search::Yahoo->new,
#         SearchFrequencies::Search::Bing->new,

	 # Some international ones
         SearchFrequencies::Search::Google->new(name => 'Google IE', gl => 'ie'),
         SearchFrequencies::Search::Google->new(name => 'Google UK', gl => 'uk'),
         SearchFrequencies::Search::Google->new(name => 'Google IM', gl => 'im'),
         SearchFrequencies::Search::Google->new(name => 'Google NZ', gl => 'nz'),
         SearchFrequencies::Search::Google->new(name => 'Google AU', gl => 'au'),
     ]
);
for my $word (@words) {
    $word = q{"} . $word . q{"};
    my $results = $search->search($word);
    while(my ($provider, $count) = each %$results) {
        next unless $count;
        $sth->execute(
            $word,
            DateTime::Format::SQLite->format_datetime(DateTime->now()),
            $count,
            $provider
        );
    }
}
