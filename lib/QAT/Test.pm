package QAT::Test;

use strict;
use warnings;
#use Smart::Comments;
#
use JSON;
use Time::HiRes qw/gettimeofday tv_interval/;
use Test::Deep;
use QAT;

use Test::Base -Base;
our @EXPORT = qw/run_blocks/;

my $json = JSON->new->allow_nonref;

our %DBHCache;
our %PerfStat;

END {
    # disconnect database
    for my $dbh (values %DBHCache) {
        $dbh->disconnect;
    }

    # stat the performance
}

sub check_response ($$) {
    my ($block, $content) = @_;

    my $name = $block->name;

    my $response            = $block->response;
    my $response_like       = $block->response_like;
    my $response_deep       = $block->response_deep;
    my $response_validator  = $block->response_validator;

    if ($response) {
        is($content, $response, "$name response");
    }

    if ($response_deep) {
        my $deep_content = $json->decode($content);
        my $deep_exp_content = $json->decode($response_deep);
        is_deep($deep_content, $deep_exp_content, "$name response deep equal");

    }

    if ($response_like) {
        my $pat = qr/$response_like/;
        if ($content =~ $pat) {
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
        my $data = $json->decode($content);
        eval {
            my $validator = QAT::Validator->new(spec => $response_validator);
            $validator->validate($data)
        };
        ok(!$@, "$name response validator $@");
    }

}

sub run_http_block ($) {
    my $block = shift;

    my $name = $block->name;

    my $url = $block->url;

    if (!$url) {
        my $host = $block->host || $ENV{QAT_ENV_HOST};
        my $port = $block->port || $ENV{QAT_ENV_PORT} || 80;
        my $uri = $block->uri;
        $url = "http://$host:$port/$uri";
    }

    my ($res, $elapsed) = QAT::Util::do_http_request({
        url => $url,
        timeout => $block->timeout || 10,
        useragent => $block->useragent || '',
        method => $block->method || '',
        data => $block->data || '',
        data_urlencode => $block->data_urlencode || '',
        form => $block->form || '',
    });

    ### $elapsed

    #ok($res->is_success, "$name request okay");
    my $response_code       = $block->response_code;
    my $response_header     = $block->response_header;

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

    my $content = $res->content;

    check_response($block, $content);
}

sub run_db_block ($) {
    my $block = shift;

    my $db_dsn = $block->db_dsn;
    my $db_user = $block->db_user;
    my $db_password = $block->db_password;

    my $sql = $block->sql;

    my $dbh;
    my $db_key = $db_dsn . $db_user . $db_password;
    if (exists $DBHCache{$db_key}) {
        $dbh = $DBHCache{$db_key};
    } else {
        require DBI;
        $dbh = DBI->connect($db_dsn, $db_user, $db_password);
    }


    my $data = [];

    my $sth = $dbh->prepare($sql);
    $sth->execute();
    while (my $ref = $sth->fetchrow_hashref()) {
        push @$data, $ref;
    }
    $sth->finish();

    my $r = {ret => JSON::true, data => $data };

    my $content = $json->encode($r);
    check_response($block, $content);
}

sub run_blocks () {
    for my $block (blocks) {
        if (!$block->is_filtered) {
            $block->run_filters;;
        }

        if ($block->uri || $block->url) {
            run_http_block($block);
        } elsif ($block->db_dsn) {
            run_db_block($block);
        } else {
            die "must have uri|url or db_dsn";
        }
    }
}

package  QAT::Test::Filter;

use Test::Base::Filter -base;

sub qat_expand_var {
    my $v = shift;

    $v =~ s/\$(QAT_[_A-Z0-9]+)/
        if (!defined $ENV{$1}) {
            die "No environment $1 defined.\n";
        }
    $ENV{$1}/eg;

    $v;
}

1;

