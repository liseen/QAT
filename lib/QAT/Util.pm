package QAT::Util;

use strict;
use warnings;
#use Smart::Comments;

use Time::HiRes qw/gettimeofday tv_interval/;
use URI::Escape;
use LWP::UserAgent;
use HTTP::Request::Common;
use File::Slurp qw/read_file/;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw/make_http_request do_http_request/;

sub make_http_request {
    my $args = shift;
    ### $args

    my $method = $args->{method} || '';
    my $url = $args->{url};

    my $header = $args->{header} || '';
    my $data = $args->{data} || '';
    my $data_urlencode = $args->{data_urlencode} || '';
    my $form = $args->{form} || '';

    if ($form && $method eq 'GET') {
        die "Can't use GET method send form data.\n";
    }

    if (!$method) {
        $method = $form || $data || $data_urlencode ? 'POST' : 'GET';
    }

    $header =~ s/^\s+|\s+$//gs;

    my @headers = split /\n/, $header;
    @headers = map {
                my ($k, $v) = split /\s*:\s*/;
                {$k => $v}
            } @headers;

    if ($data) {
        if ($data =~ /^@(.*)$/) {
            $data = read_file($1);
        }

        if ($method eq 'GET') {
            $url = $url . "?" . $data;
            return GET $url, @headers;
        } else {
            return POST $url, @headers, Content => $data;
        }
    } elsif ($data_urlencode) {
        my @lines = split /\n/, $data_urlencode;

        my @content = map {
            my $l = $_;
            my $el;
            if ($l =~ /^@(.+)$/) {
                $el = read_file($1);
                ### $el
                $el = uri_escape($el);
            } elsif ($l =~ /^(\w+)@(.+)$/) {
                $el = read_file($2);
                $el = uri_escape($el);
                $el = "$1=$el";
            } elsif ($l =~ /^(\w+)=(.+)$/) {
                $el = uri_escape($2);
                $el = "$1=$el";
            } else {
                $el = uri_escape($l);
                $el = "$1=$el";
            }

            $el;
        } @lines;

        my $d = join '&', @content;

        if ($method eq 'GET') {
            $url = $url . "?" . $d;
            return GET $url, @headers;
        } else {
            return POST $url, @headers, Content => $d;
        }
    } elsif ($form) {
        $form =~ s/^\s+|\s+$//gs;

        my @lines = split /\n/, $form;
        my @content = map {
                    my ($k, $v) = split /\s*=/, $_, 2;
                    if ($v =~ /^@(.*$)/) {
                        $v = [$1];
                    }
                    {$k => $v};
                } @lines;

        return POST $url,
                    Content_Type => 'form-data', @headers,
                    Content => \@content;
    } else {
        return GET $url, @headers;
    }
}

sub do_http_request {
    my $args = shift;

    my $ua = LWP::UserAgent->new();
    $ua->timeout($args->{timeout} || 10);

    my $req = make_http_request($args);

    my $t0 = [ gettimeofday ];
    return ($ua->request($req), tv_interval($t0));
}

1;
