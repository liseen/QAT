package QAT::HTTP::Test;

use strict;
use warnings;
#use Smart::Comments;

use QAT;
use Test::Deep;
use JSON;
use Encode;

use Test::Base -Base;
our @EXPORT = qw/run_blocks/;

my $json = JSON->new->utf8->allow_nonref;

sub run_block ($) {
    my $block = shift;

    my $name = $block->name;

    my $url = $block->url;

    if (!$url) {
        my $host = $block->host || $ENV{TEST_ENV_HOST};
        my $port = $block->port || $ENV{TEST_ENV_PORT} || 80;
        my $uri = $block->uri;
        $url = "http://$host:$port/$uri";
    }

    my $res = QAT::Util::do_http_request({
        url => $url,
        timeout => $block->timeout || '',
        useragent => $block->useragent || '',
        method => $block->method || '',
        data => $block->data || '',
        data_urlencode => $block->data_urlencode || '',
        form => $block->form || '',
    });

    #ok($res->is_success, "$name request okay");

    my $response_code       = $block->response_code;
    my $response_header     = $block->response_header;
    my $response            = $block->response;
    my $response_like       = $block->response_like;
    my $response_deep       = $block->response_deep;
    my $response_validator  = $block->response_validator;

    if ($response_code) {
        is($res->code, $response_code, "$name response code");
    }

    if ($response_header) {
        my @headers = split /\n/, $response_header;
        for my $h (@headers) {
            my ($hk, $hv) = split /\s*:\s*/, $h, 2;
            next if !$hk;

            is($res->header($hk), $hv, "$name response header $hk");
        }

    }

    if ($response) {
        is($res->content, $response, "$name response");
    }

    if ($response_deep) {
        my $deep_content = decode_json($res->content);
        my $deep_exp_content = decode_json($response_deep);
        is_deep($deep_content, $deep_exp_content, "$name response deep equal");

    }

    if ($response_like) {
        my $pat = qr/$response_like/;
        if ($res->content =~ $pat) {
            while (my ($k, $v) = each %+) {
                $ENV{$k} = $v;
                ### key: $k
                ### value: $v
            }
            ok(1, "$name response like");
        } else {
            ok(0, "$name response like");
        }
    }

    if ($response_validator) {
        my $content = $res->content;

        #my $flag = utf8::is_utf8($content);
        # $flag
        #$flag = utf8::is_utf8($response_validator);
        # $flag
        #
        my $data = decode_json($res->content);
        eval {
            my $validator = QAT::Validator->new(spec => $response_validator);
            $validator->validate($data)
        };
        ok(!$@, "$name response validator $@");
    }
}


sub run_blocks () {
    for my $block (blocks) {
        if (!$block->is_filtered) {
            $block->run_filters;;
        }
        run_block($block);
    }
}

package  QAT::HTTP::Test::Filter;

use Test::Base::Filter -base;

sub qat_expand_var {
    my $v = shift;

    $v =~ s/\$(TEST_[_A-Z0-9]+)/
        if (!defined $ENV{$1}) {
            die "No environment $1 defined.\n";
        }
    $ENV{$1}/eg;

    $v;
}

1;

