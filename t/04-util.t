use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../inc";
use lib "$FindBin::Bin/../lib";

use QAT::Util;

use Test::More;
plan tests => 18;

my $res = QAT::Util::do_http_request({
        url => 'http://www.qunar.com/'
    });

ok($res->is_success, 'request okay');
is($res->code, 200, 'http code okay');
is($res->header('Content-Type'), 'text/html', 'content-type');

$res = QAT::Util::do_http_request({
    url => 'http://localhost/echo',
    data => 'a=b=a'
});

ok($res->is_success, 'request okay');
is($res->code, 200, 'http code okay');
is($res->content, 'a=b=a', 'request data');

$res = QAT::Util::do_http_request({
    url => 'http://localhost/echo',
    data_urlencode => 'a=b=a'
});

ok($res->is_success, 'request okay');
is($res->code, 200, 'http code okay');
is($res->content, 'a=b%3Da', 'request data');



$res = QAT::Util::do_http_request({
    url => 'http://localhost/echo',
    data_urlencode => "a=b=a\nb=c"
});

ok($res->is_success, 'request okay');
is($res->code, 200, 'http code okay');
is($res->content, 'a=b%3Da&b=c', 'request data');

my $tmp_filename = "/tmp/tmp_file_for_qat_util";

open my $tmp_file, ">", $tmp_filename;
print $tmp_file "a=b%3Da";
close $tmp_file;

$res = QAT::Util::do_http_request({
    url => 'http://localhost/echo',
    data_urlencode => '@' . "$tmp_filename"
});

ok($res->is_success, 'request okay');
is($res->code, 200, 'http code okay');
is($res->content, 'a%3Db%253Da', 'request data');



open $tmp_file, ">", $tmp_filename;
print $tmp_file "a=b%3Da";
close $tmp_file;

$res = QAT::Util::do_http_request({
    url => 'http://localhost/echo',
    data_urlencode => 'a@' . "$tmp_filename"
});

ok($res->is_success, 'request okay');
is($res->code, 200, 'http code okay');
is($res->content, 'a=a%3Db%253Da', 'request data');



