package SearchFrequencies::Search::Bing;
use Moose;
use LWP::UserAgent;
use JSON::Any;

with 'SearchFrequencies::Search';
with 'SearchFrequencies::HttpSearch';

has '+end_point' => ( default => 'http://api.bing.net/json.aspx' );
has '+name' => ( default => 'Bing' );

has '_app_id' => (
    isa => 'Str',
    is => 'ro',
    default => '3E4EA85144DCB426BC375A71CC3686A60A0843C0',
);

sub search {
    my ($self, $query) = @_;
    my $response = $self->_ua->get($self->form_url(query => $query));
    if ($response->is_success) {
        my $results = JSON::Any->jsonToObj($response->content);
        return $results->{SearchResponse}->{Web}->{Total};
    }
}

around 'form_url' => sub {
    my $orig = shift;
    my ($self, %params) = @_;
    $params{AppId}   ||= $self->_app_id;
    $params{Version} ||= 2.2;
    $params{Market}  ||= 'en-GB';
    $params{Sources} ||= 'web';
    return $orig->($self, %params);
};

__PACKAGE__->meta->make_immutable;
1;
