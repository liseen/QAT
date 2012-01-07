use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../inc";
use lib "$FindBin::Bin/../lib";

use Test::Base;
use JSON;

my $json = JSON->new->allow_nonref;

use QAT::Validator;

plan tests => 9;

run {
    my $block = shift;

    my $name = $block->name;
    my $spec = $block->spec;

    my $validator = QAT::Validator->new(spec => $spec);

    my $valid = $block->valid;
    for my $ln (split /\n/, $valid) {
        #### $ln
        my $data = $json->decode($ln);
        eval {
            $validator->validate($data);
        };
        ok !$@, $name . ": " .  $@;
    }

    my $invalid = $block->invalid || '';
    for my $ln (split /\n/, $invalid) {
        #### $ln
        my $data = $json->decode($ln);
        eval {
            $validator->validate($data);
        };
        ok $@, $name . ": " . $@;
    }
};


__END__

=== TEST 1
--- spec
{ foo: STRING }
--- valid
{"foo":"dog"}
{"foo":32}
null
{}
--- invalid
{"foo2":32}
[]
32



=== TEST 2
--- spec
{"errcode": INT, "errmsg": "invalid request", "ret": BOOL}
--- valid
{"errcode":"100","errmsg":"invalid request","ret":false}



=== TEST 3
--- spec
{"errcode": INT, "errmsg":"无效请求", "ret": BOOL}
--- valid
{"errcode":"100","errmsg":"无效请求","ret":false}
