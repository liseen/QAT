use strict;
use warnings;

use FindBin;

# 加载QAT所需
use lib "$FindBin::Bin/../../../../inc";
use lib "$FindBin::Bin/../../../../lib";

#use QAT::Test::Filter;
use QAT::Test;

plan tests => 1 * blocks() + 11;

$ENV{QAT_ENV_HOST} = 'www.qunar.com';
$ENV{QAT_ENV_PORT} = 80;

filters_delay;
filters qw/chomp qat_expand_var/;

run_blocks;

__END__

=== TEST 1  请求URL并测试返回的http code
--- url
http://www.qunar.com/
--- response_code
200



=== TEST 2 不直接给出URL，url = http://$host:$port/$uri
--- host
www.qunar.com
--- port
80
--- uri
/
--- response_code
200



=== TEST 3 使用环境变量QAT_ENV_HOST QAT_ENV_PORT
--- uri
/
--- response_code
200



=== TEST 4 response_code
--- uri
/adsalaslsaf
--- response_code
404



=== TEST 5 response, 返回结果， 字符串相等
--- url
http://upd.qunar.com/api/imgup/iapp?app=test
--- response_code
200
--- response
{"errcode":"100","errmsg":"无效请求","ret":false}



=== TEST 6 response, 返回结果， JSON解析后数据结构比较， 相等
--- url
http://upd.qunar.com/api/imgup/iapp?app=test
--- response_code
200
--- response_deep
{"errmsg":"无效请求", "errcode":"100", "ret":false}



=== TEST 7 response, 返回结果， 正则匹配
--- url
http://upd.qunar.com/api/imgup/iapp?app=test
--- response_code
200
--- response_like
无效请求.*



=== TEST 8 response validator, 验证返回的结果是否符合格式
--- url
http://upd.qunar.com/api/imgup/iapp?app=test
--- response_code
200
--- response_validator
{"errcode": INT :required, "errmsg": STRING, "ret": BOOL}



=== TEST 9 另一个validator
--- url
http://upd.qunar.com/api/imgup/iapp?app=test
--- response_code
200
--- response_validator
{"errcode": INT, "errmsg": "无效请求", "ret": BOOL}



=== TEST 10 response header验证
--- url
http://www.qunar.com/
--- response_code
200
--- response_header
Server: QWS/1.0
Content-Type: text/html



=== TEST 11 set context variable from regular expresssion
--- url
http://upd.qunar.com/api/imgup/iapp?app=test
--- response_code
200
--- response_like
(?<QAT_CONTEXT_ERRCODE>\d+)



=== TEST 12 get context variable
--- url
http://upd.qunar.com/api/imgup/iapp?app=test
--- response_code
200
--- response_like
$QAT_CONTEXT_ERRCODE


=== TEST 13 test sql
--- db_dsn
DBI:mysql:database=$QAT_ENV_DB_NAME;host=$QAT_ENV_DB_HOST;port=$QAT_ENV_DB_PORT;mysql_enable_utf8=1
--- db_user
user
--- db_password
pass
--- sql
select * from aaa limit 1;
--- response_like
.+
--- SKIP


=== TEST 14 response_elapsed_limit
--- url
http://upd.qunar.com/api/imgup/iapp?app=test
--- response_code
200
--- response_like
$QAT_CONTEXT_ERRCODE
--- response_elapsed_limit
50



