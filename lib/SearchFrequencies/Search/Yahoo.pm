package SearchFrequencies::Search::Yahoo;
use Moose;
use XML::Simple qw( XMLin );

with 'SearchFrequencies::Search';
with 'SearchFrequencies::HttpSearch';

has '+end_point' => (
    default => 'http://boss.yahooapis.com/ysearch/web/v1/'
);
has '+name' => ( default => 'Yahoo!' );

has '_app_id' => (
    isa => 'Str',
    is => 'ro',
    default => 'NXDhgMjV34EpyKAPV_qguc5ulwSmZSAdYoQgqfBUnOpQfiCDDt_eg6aMA7.NONNBJStmVM4lJy.vfH38TbA-'
);

sub search {
    my ($self, $query) = @_;
    my $response = $self->_ua->get($self->form_url(query => $query));
    if ($response->is_success) {
        return XMLin($response->content)->{resultset_web}->{totalhits};
    }
}

around 'form_url' => sub {
    my $orig = shift;
    my ($self, %params) = @_;
    my $old = $self->end_point;
    $self->end_point($old . delete $params{query});
    $params{appid}  ||= $self->_app_id;
    $params{format} ||= 'xml';
    my $url = $orig->($self, %params);
    $self->end_point($old);
    return $url;
};

__PACKAGE__->meta->make_immutable;
1;
