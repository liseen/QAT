package QAT::Util;

use strict;
use warnings;
#use Smart::Comments;

use LWP::UserAgent;
use HTTP::Request::Common;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/make_http_request do_http_request/;

sub make_http_request {
    my $args = shift;
    ### $args

    my $url = $args->{url};
    my $form = $args->{form} || '';
    my $data = $args->{data} || '';
    my $header = $args->{header} || '';

    if ($form && $data) {
        die "form && data fields.\n";
    }

    my $method = $form || $data ? 'POST' : 'GET';

    $header =~ s/(?:^\s+|\s+$)//gs; #把前后的空格(串首尾的)消去
    my @headers = split /\n/, $header;
    @headers = map {
                my ($k, $v) = split /\s*:\s*/;
                {$k => $v}
            } @headers;

    if ($method eq 'GET') {
        return GET $url, @headers;
    } else {
        if ($data) {
            $data =~ s/(?:^\s+|\s+$)//gs;
            my @lines = split /\n/, $data;
            my @data = map {
                            my ($k, $v) = split /\s*=/;
                            {$k => $v}
                       } @lines;
            return POST $url, \@data, @headers;
        } else {
            $form =~ s/(?:^\s+|\s+$)//gs;
            my @lines = split /\n/, $form;
            my @content = map {
                        my ($k, $v) = split /\s*=/;
                        if ($v =~ /^@(.*$)/) {
                            $v = [$1];
                        }
                        {$k => $v};
                   } @lines;
            return POST $url,
                        Content_Type => 'form-data', @headers,
                        Content => \@content;
        }
    }
}

sub do_http_request {
    my $args = shift;
    ### $args

    my $ua = LWP::UserAgent->new();
    $ua->timeout($args->{timeout} || 10);

    my $req = make_http_request($args);

    return $ua->request($req);
}

1;
