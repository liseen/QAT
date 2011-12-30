package Simple::Test;

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
        my $host = $block->host || $ENV{TEST_HOST};
        my $port = $block->port || $ENV{TEST_PORT} || 80;
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
        ok($res->content =~ $pat, "$name response like");
    }

    if ($response_validator) {
        my $content = $res->content;
        my $flag = utf8::is_utf8($content);
        ### $flag
        $flag = utf8::is_utf8($response_validator);
        ### $flag
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
        run_block($block);
    }
}


1;

