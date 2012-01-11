use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../inc";
use lib "$FindBin::Bin/../lib";

use Test::Base;
use JSON;

plan tests => 5 * blocks() + 23;

require QAT::Validator::Compiler;

my $json = JSON->new->allow_nonref;

my $val = QAT::Validator::Compiler->new;

#no_diff;

sub validate { 1; }

run {
    my $block = shift;
    my $name = $block->name;
    my $perl;
    if (!$block->spec) { die "$name - No spec specified.\n" }
    eval {
        $perl = $val->validator($block->spec);
    };
    if ($@) {
        die "$name - $@";
    }
    my $expected = $block->perl;
    $expected =~ s/^\s+//gm;
    is $perl, $expected, "$name - perl code match";
    my $code = "*validate = sub { local \$_ = shift; $perl }";
    {
        no warnings 'redefine';
        no strict;
        eval $code;
        if ($@) {
            fail "$name - Bad perl code emitted - $@";
            *validate = sub { 1 };
        } else {
            pass "$name - perl code emitted is well formed";
        }
    }
    my $spec = $block->valid;
    if ($spec) {
        my @ln = split /\n/, $spec;
        for my $ln (@ln) {
            my $data = $json->decode($ln);
            eval {
                validate($data);
            };
            if ($@) {
                fail "$name - Valid data <<$ln>> is valid - $@";
            } else {
                pass "$name - Valid data <<$ln>> is valid";
            }
        }
    }
    $spec = $block->invalid;
    if ($spec) {
        my @ln = split /\n/, $spec;
        while (@ln) {
            my $ln = shift @ln;
            my $excep = shift @ln;
            my $data = $json->decode($ln);
            eval {
                validate($data);
            };
            unless ($@) {
                fail "$name - Invalid data <<$ln>> is invalid - $@";
            } else {
                is $@, "$excep\n", "$name - Invalid data <<$ln>> is invalid";
            }
        }
    }

};

__DATA__

=== TEST 1: simple hash
---  spec
{ foo: STRING }
--- perl
if (defined) {
    ref and ref eq 'HASH' or die qq{Invalid value: Hash expected.\n};
    {
        local *_ = \( $_->{"foo"} );
        if (defined) {
            !ref or die qq{Bad value for "foo": String expected.\n};
        }
    }
    for (keys %$_) {
        $_ eq "foo" or die qq{Unrecognized key in hash: $_\n};
    }
}
--- valid
{"foo":"dog"}
{"foo":32}
null
{}
--- invalid
{"foo2":32}
Unrecognized key in hash: foo2
32
Invalid value: Hash expected.
[]
Invalid value: Hash expected.



=== TEST 2: strings
---  spec
STRING
--- perl
if (defined) {
    !ref or die qq{Bad value: String expected.\n};
}
--- valid
"hello"
32
3.14
null
0
--- invalid
{"cat":32}
Bad value: String expected.
[1,2,3]
Bad value: String expected.



=== TEST 3: numbers
---  spec
INT
--- perl
if (defined) {
    /^[-+]?\d+$/ or die qq{Bad value: Integer expected.\n};
}
--- valid
32
0
null
-56
--- invalid
3.14
Bad value: Integer expected.
"hello"
Bad value: Integer expected.
[0]
Bad value: Integer expected.
{}
Bad value: Integer expected.



=== TEST 4: identifiers
---  spec
IDENT
--- perl
if (defined) {
    /^[A-Za-z]\w*$/ or die qq{Bad value: Identifier expected.\n};
}
--- valid
"foo"
"hello_world"
"HiBoy"
--- invalid
"_foo"
Bad value: Identifier expected.
"0a"
Bad value: Identifier expected.
32
Bad value: Identifier expected.
[]
Bad value: Identifier expected.
{"cat":3}
Bad value: Identifier expected.



=== TEST 5: arrays
--- spec
[STRING]
--- perl
if (defined) {
    ref and ref eq 'ARRAY' or die qq{Invalid value: Array expected.\n};
    for (@$_) {
        if (defined) {
            !ref or die qq{Bad value for array element: String expected.\n};
        }
    }
}
--- valid
[1,2]
["hello"]
null
[]

--- invalid
[[1]]
Bad value for array element: String expected.
32
Invalid value: Array expected.
"hello"
Invalid value: Array expected.
{}
Invalid value: Array expected.



=== TEST 6: hashes of arrays
--- spec
{ columns: [ { name: STRING, type: STRING } ] }
--- perl
if (defined) {
    ref and ref eq 'HASH' or die qq{Invalid value: Hash expected.\n};
    {
        local *_ = \( $_->{"columns"} );
        if (defined) {
            ref and ref eq 'ARRAY' or die qq{Invalid value for "columns": Array expected.\n};
            for (@$_) {
                if (defined) {
                    ref and ref eq 'HASH' or die qq{Invalid value for "columns" array element: Hash expected.\n};
                    {
                        local *_ = \( $_->{"name"} );
                        if (defined) {
                            !ref or die qq{Bad value for "name" for "columns" array element: String expected.\n};
                        }
                    }
                    {
                        local *_ = \( $_->{"type"} );
                        if (defined) {
                            !ref or die qq{Bad value for "type" for "columns" array element: String expected.\n};
                        }
                    }
                    for (keys %$_) {
                        $_ eq "name" or $_ eq "type" or die qq{Unrecognized key in hash for "columns" array element: $_\n};
                    }
                }
            }
        }
    }
    for (keys %$_) {
        $_ eq "columns" or die qq{Unrecognized key in hash: $_\n};
    }
}
--- valid
{"columns":[]}
{"columns":[{"name":"Carrie"}]}
{"columns":null}
{"columns":[{"name":null,"type":null}]}
{}
null
--- invalid
{"bar":[]}
Unrecognized key in hash: bar
{"columns":[{"default":32,"blah":[]}]}
Unrecognized key in hash for "columns" array element: blah
{"columns":[32]}
Invalid value for "columns" array element: Hash expected.
32
Invalid value: Hash expected.



=== TEST 7: simple hash required
---  spec
{ "foo": STRING } :required
--- perl
defined or die qq{Value required.\n};
ref and ref eq 'HASH' or die qq{Invalid value: Hash expected.\n};
{
    local *_ = \( $_->{"foo"} );
    if (defined) {
        !ref or die qq{Bad value for "foo": String expected.\n};
    }
}
for (keys %$_) {
    $_ eq "foo" or die qq{Unrecognized key in hash: $_\n};
}
--- valid
{"foo":"hello"}
{}
{"foo":null}

--- invalid
null
Value required.
{"blah":"hi"}
Unrecognized key in hash: blah
[]
Invalid value: Hash expected.
32
Invalid value: Hash expected.



=== TEST 8: array required
--- spec
[INT] :required
--- perl
defined or die qq{Value required.\n};
ref and ref eq 'ARRAY' or die qq{Invalid value: Array expected.\n};
for (@$_) {
    if (defined) {
        /^[-+]?\d+$/ or die qq{Bad value for array element: Integer expected.\n};
    }
}
--- valid
[1,2]
[0]
--- invalid
["hello"]
Bad value for array element: Integer expected.
[1,2,"hello"]
Bad value for array element: Integer expected.
[1.32]
Bad value for array element: Integer expected.
null
Value required.



=== TEST 9: array elem required
--- spec
[INT :required]
--- perl
if (defined) {
    ref and ref eq 'ARRAY' or die qq{Invalid value: Array expected.\n};
    for (@$_) {
        defined or die qq{Value for array element required.\n};
        /^[-+]?\d+$/ or die qq{Bad value for array element: Integer expected.\n};
    }
}

--- valid
[32]
null
[]
--- invalid
[null]
Value for array element required.



=== TEST 10: nonempty array
--- spec
[INT] :nonempty
--- perl
if (defined) {
    ref and ref eq 'ARRAY' or die qq{Invalid value: Array expected.\n};
    @$_ or die qq{Array cannot be empty.\n};
    for (@$_) {
        if (defined) {
            /^[-+]?\d+$/ or die qq{Bad value for array element: Integer expected.\n};
        }
    }
}
--- valid
[32]
[1,2]
null
--- invalid
[]
Array cannot be empty.



=== TEST 11: nonempty required array
--- spec
[INT] :nonempty :required
--- perl
defined or die qq{Value required.\n};
ref and ref eq 'ARRAY' or die qq{Invalid value: Array expected.\n};
@$_ or die qq{Array cannot be empty.\n};
for (@$_) {
    if (defined) {
        /^[-+]?\d+$/ or die qq{Bad value for array element: Integer expected.\n};
    }
}
--- valid
[32]
[1,2]
--- invalid
[]
Array cannot be empty.
null
Value required.
["hello"]
Bad value for array element: Integer expected.



=== TEST 12: nonempty hash
--- spec
{"cat":STRING}:nonempty
--- perl
if (defined) {
    ref and ref eq 'HASH' or die qq{Invalid value: Hash expected.\n};
    %$_ or die qq{Hash cannot be empty.\n};
    {
        local *_ = \( $_->{"cat"} );
        if (defined) {
            !ref or die qq{Bad value for "cat": String expected.\n};
        }
    }
    for (keys %$_) {
        $_ eq "cat" or die qq{Unrecognized key in hash: $_\n};
    }
}
--- valid
{"cat":32}
null
--- invalid
32
Invalid value: Hash expected.
{}
Hash cannot be empty.



=== TEST 13: scalar required
--- spec
IDENT :required
--- perl
defined or die qq{Value required.\n};
/^[A-Za-z]\w*$/ or die qq{Bad value: Identifier expected.\n};



=== TEST 14: scalar required
--- spec
STRING :required
--- perl
defined or die qq{Value required.\n};
!ref or die qq{Bad value: String expected.\n};



=== TEST 15: scalar required in a hash
--- spec
{ name: STRING :required, type: STRING :required }
--- perl
if (defined) {
    ref and ref eq 'HASH' or die qq{Invalid value: Hash expected.\n};
    {
        local *_ = \( $_->{"name"} );
        defined or die qq{Value for "name" required.\n};
        !ref or die qq{Bad value for "name": String expected.\n};
    }
    {
        local *_ = \( $_->{"type"} );
        defined or die qq{Value for "type" required.\n};
        !ref or die qq{Bad value for "type": String expected.\n};
    }
    for (keys %$_) {
        $_ eq "name" or $_ eq "type" or die qq{Unrecognized key in hash: $_\n};
    }
}
--- invalid
{"name":"hi","type":"text","default":"Howdy"}
Unrecognized key in hash: default



=== TEST 16: scalar required in a hash which is required also
--- spec
{ name: STRING :required, type: STRING :required } :required
--- perl
defined or die qq{Value required.\n};
ref and ref eq 'HASH' or die qq{Invalid value: Hash expected.\n};
{
    local *_ = \( $_->{"name"} );
    defined or die qq{Value for "name" required.\n};
    !ref or die qq{Bad value for "name": String expected.\n};
}
{
    local *_ = \( $_->{"type"} );
    defined or die qq{Value for "type" required.\n};
    !ref or die qq{Bad value for "type": String expected.\n};
}
for (keys %$_) {
    $_ eq "name" or $_ eq "type" or die qq{Unrecognized key in hash: $_\n};
}



=== TEST 17: default string
--- spec
STRING :default('hello')
--- perl
if (defined) {
    !ref or die qq{Bad value: String expected.\n};
}
else {
    $_ = 'hello';
}



=== TEST 18: default array
--- spec
[STRING :default(32)] : default([])
--- perl
if (defined) {
    ref and ref eq 'ARRAY' or die qq{Invalid value: Array expected.\n};
    for (@$_) {
        if (defined) {
            !ref or die qq{Bad value for array element: String expected.\n};
        }
        else {
            $_ = 32;
        }
    }
}
else {
    $_ = [];
}
--- valid
[]
null



=== TEST 19: assign for array and scalar
--- spec
[STRING :default(32) :to($bar) ] :to($foo) :default([])
--- perl
if (defined) {
    ref and ref eq 'ARRAY' or die qq{Invalid value: Array expected.\n};
    for (@$_) {
        if (defined) {
            !ref or die qq{Bad value for array element: String expected.\n};
        }
        else {
            $_ = 32;
        }
        $bar = $_;
    }
}
else {
    $_ = [];
}
$foo = $_;



=== TEST 20: assign for hash
--- spec
{"name": STRING :to($name) :required, "type": STRING :to($type) :default("text")} :to($column)
--- perl
if (defined) {
    ref and ref eq 'HASH' or die qq{Invalid value: Hash expected.\n};
    {
        local *_ = \( $_->{"name"} );
        defined or die qq{Value for "name" required.\n};
        !ref or die qq{Bad value for "name": String expected.\n};
        $name = $_;
    }
    {
        local *_ = \( $_->{"type"} );
        if (defined) {
            !ref or die qq{Bad value for "type": String expected.\n};
        }
        else {
            $_ = "text";
        }
        $type = $_;
    }
    for (keys %$_) {
        $_ eq "name" or $_ eq "type" or die qq{Unrecognized key in hash: $_\n};
    }
}
$column = $_;
--- valid
{"name":"Hello","type":"text"}



=== TEST 21: $foo ~~
--- spec
$data ~~ { "name": STRING }
--- perl
{
    local *_ = \( $data );
    if (defined) {
        ref and ref eq 'HASH' or die qq{Invalid value: Hash expected.\n};
        {
            local *_ = \( $_->{"name"} );
            if (defined) {
            !ref or die qq{Bad value for "name": String expected.\n};
            }
        }
        for (keys %$_) {
            $_ eq "name" or die qq{Unrecognized key in hash: $_\n};
        }
    }
}



=== TEST 22: $foo->{bar} ~~
--- spec
$foo->{bar} ~~ { "name": STRING }
--- perl
{
    local *_ = \( $foo->{bar} );
    if (defined) {
        ref and ref eq 'HASH' or die qq{Invalid value: Hash expected.\n};
        {
            local *_ = \( $_->{"name"} );
            if (defined) {
            !ref or die qq{Bad value for "name": String expected.\n};
            }
        }
        for (keys %$_) {
            $_ eq "name" or die qq{Unrecognized key in hash: $_\n};
        }
    }
}



=== TEST 23: match(/.../, '...')
--- spec
STRING :match(/^\d{4}-\d{2}-\d{2}$/, 'Date')
--- perl
if (defined) {
    !ref or die qq{Bad value: String expected.\n};
    /^\d{4}-\d{2}-\d{2}$/ or die qq{Invalid value: Date expected.\n};
}



=== TEST 24: :allowed
--- spec
STRING :allowed('password', 'login', 'anonymous')
--- perl
if (defined) {
    !ref or die qq{Bad value: String expected.\n};
    $_ eq 'password' or $_ eq 'login' or $_ eq 'anonymous' or die qq{Invalid value: Allowed values are 'password', 'login', 'anonymous'.\n};
}
--- valid
"password"
"login"
"anonymous"
null
--- invalid
""
Invalid value: Allowed values are 'password', 'login', 'anonymous'.



=== TEST 25: :allowed and :match in hashes
--- spec
{
    cat: STRING :match(/mimi|papa/, 'Cat name') :required,
    dog: STRING :allowed('John', 'Mike'),
}
--- perl
if (defined) {
    ref and ref eq 'HASH' or die qq{Invalid value: Hash expected.\n};
    {
        local *_ = \( $_->{"cat"} );
        defined or die qq{Value for "cat" required.\n};
        !ref or die qq{Bad value for "cat": String expected.\n};
        /mimi|papa/ or die qq{Invalid value for "cat": Cat name expected.\n};
    }
    {
        local *_ = \( $_->{"dog"} );
        if (defined) {
            !ref or die qq{Bad value for "dog": String expected.\n};
            $_ eq 'John' or $_ eq 'Mike' or die qq{Invalid value for "dog": Allowed values are 'John', 'Mike'.\n};
        }
    }
    for (keys %$_) {
        $_ eq "cat" or $_ eq "dog" or die qq{Unrecognized key in hash: $_\n};
    }
}
--- valid
null
{"cat":"mimi"}
{"cat":"mimi","dog":"John"}
{"cat":"papa","dog":"Mike"}
--- invalid
{"cat":"mini"}
Invalid value for "cat": Cat name expected.
{"cat":"papa","dog":"John Zhang"}
Invalid value for "dog": Allowed values are 'John', 'Mike'.



=== TEST 26: nonempty values
--- spec
STRING :nonempty
--- perl
if (defined) {
    !ref or die qq{Bad value: String expected.\n};
    length or die qq{Invalid value: Nonempty scalar expected.\n};
}

--- valid
null
"hello"
0
1
--- invalid
""
Invalid value: Nonempty scalar expected.
true
Bad value: String expected.
false
Bad value: String expected.



=== TEST 27: BOOL
--- spec
BOOL
--- perl
if (defined) {
    JSON::is_bool($_) or die qq{Bad value: Boolean expected.\n};
}
--- valid
true
false
null
--- invalid
"hello"
Bad value: Boolean expected.
0
Bad value: Boolean expected.
1
Bad value: Boolean expected.



=== TEST 28: required array elme in nonempty array
--- spec
[INT :required] :nonempty
--- perl
if (defined) {
 ref and ref eq 'ARRAY' or die qq{Invalid value: Array expected.\n};
@$_ or die qq{Array cannot be empty.\n};
for (@$_) {
defined or die qq{Value for array element required.\n};
/^[-+]?\d+$/ or die qq{Bad value for array element: Integer expected.\n};
}
}
--- valid
[1]
--- invalid
[null]
Value for array element required.
[]
Array cannot be empty.



=== TEST 29 Qunar JSON API, error

--- spec
{
    ret: BOOL :allowed('false') :required,
    errcode: INT :required,
    errmsg: STRING :required
}
--- perl
if (defined) {
ref and ref eq 'HASH' or die qq{Invalid value: Hash expected.\n};
{
local *_ = \( $_->{"ret"} );
defined or die qq{Value for "ret" required.\n};
JSON::is_bool($_) or die qq{Bad value for "ret": Boolean expected.\n};
$_ eq 'false' or die qq{Invalid value for "ret": Allowed values are 'false'.\n};
}
{
local *_ = \( $_->{"errcode"} );
defined or die qq{Value for "errcode" required.\n};
/^[-+]?\d+$/ or die qq{Bad value for "errcode": Integer expected.\n};
}
{
local *_ = \( $_->{"errmsg"} );
defined or die qq{Value for "errmsg" required.\n};
!ref or die qq{Bad value for "errmsg": String expected.\n};
}
for (keys %$_) {
$_ eq "ret" or $_ eq "errcode" or $_ eq "errmsg" or die qq{Unrecognized key in hash: $_\n};
}
}
--- valid
{ "ret": false, "errcode": 100, "errmsg": "No such user." }
--- invalid
{ "ret": true }
Invalid value for "ret": Allowed values are 'false'.
{ "ret": false, "errcode": 100 }
Value for "errmsg" required.



=== TEST 30 Qunar JSON API, okay

--- spec
{
    ret: BOOL :allowed('true') :required,
    data: [
        {
            id: INT :required,
            name: STRING :match(/^\w+$/, "Name") :nonempty,
            sex: STRING :allowed('male', 'female')
        }
    ] :required
}
--- perl
if (defined) {
ref and ref eq 'HASH' or die qq{Invalid value: Hash expected.\n};
{
local *_ = \( $_->{"ret"} );
defined or die qq{Value for "ret" required.\n};
JSON::is_bool($_) or die qq{Bad value for "ret": Boolean expected.\n};
$_ eq 'true' or die qq{Invalid value for "ret": Allowed values are 'true'.\n};
}
{
local *_ = \( $_->{"data"} );
defined or die qq{Value for "data" required.\n};
ref and ref eq 'ARRAY' or die qq{Invalid value for "data": Array expected.\n};
for (@$_) {
if (defined) {
ref and ref eq 'HASH' or die qq{Invalid value for "data" array element: Hash expected.\n};
{
local *_ = \( $_->{"id"} );
defined or die qq{Value for "id" for "data" array element required.\n};
/^[-+]?\d+$/ or die qq{Bad value for "id" for "data" array element: Integer expected.\n};
}
{
local *_ = \( $_->{"name"} );
if (defined) {
!ref or die qq{Bad value for "name" for "data" array element: String expected.\n};
/^\w+$/ or die qq{Invalid value for "name" for "data" array element: Name expected.\n};
length or die qq{Invalid value for "name" for "data" array element: Nonempty scalar expected.\n};
}
}
{
local *_ = \( $_->{"sex"} );
if (defined) {
!ref or die qq{Bad value for "sex" for "data" array element: String expected.\n};
$_ eq 'male' or $_ eq 'female' or die qq{Invalid value for "sex" for "data" array element: Allowed values are 'male', 'female'.\n};
}
}
for (keys %$_) {
$_ eq "id" or $_ eq "name" or $_ eq "sex" or die qq{Unrecognized key in hash for "data" array element: $_\n};
}
}
}
}
for (keys %$_) {
$_ eq "ret" or $_ eq "data" or die qq{Unrecognized key in hash: $_\n};
}
}

--- valid
{"ret": true, "data": []}
{"ret": true, "data": [{"id": 1, "name": "zhang", "sex": "male"}]}
--- invalid
{"ret": false}
Invalid value for "ret": Allowed values are 'true'.
{"ret": true, "data": [{"id": "aaa", "name": "zhang", "sex": "male"}]}
Bad value for "id" for "data" array element: Integer expected.
{"ret": true, "data": [{"id": 2, "name": "", "sex": "male"}]}
Invalid value for "name" for "data" array element: Name expected.
{"ret": true, "data": [{"id": 2, "name": "zhang", "sex": "ssss"}]}
Invalid value for "sex" for "data" array element: Allowed values are 'male', 'female'.



=== TEST 31 true

--- spec
{ret: true }
--- perl
if (defined) {
ref and ref eq 'HASH' or die qq{Invalid value: Hash expected.\n};
{
local *_ = \( $_->{"ret"} );
(JSON::is_bool($_) && $_ == JSON::true) or die qq{Bad value for "ret": Boolean value true expected.\n};
}
for (keys %$_) {
$_ eq "ret" or die qq{Unrecognized key in hash: $_\n};
}
}

--- valid
{"ret": true}
--- invalid
{"ret": false}
Bad value for "ret": Boolean value true expected.



=== TEST 32 false

--- spec
{ret: false }
--- perl
if (defined) {
ref and ref eq 'HASH' or die qq{Invalid value: Hash expected.\n};
{
local *_ = \( $_->{"ret"} );
(JSON::is_bool($_) && $_ == JSON::false) or die qq{Bad value for "ret": Boolean value false expected.\n};
}
for (keys %$_) {
$_ eq "ret" or die qq{Unrecognized key in hash: $_\n};
}
}

--- valid
{"ret": false}
--- invalid
{"ret": true}
Bad value for "ret": Boolean value false expected.



=== TEST 33 null
--- spec
{foo: null}
--- perl
if (defined) {
ref and ref eq 'HASH' or die qq{Invalid value: Hash expected.\n};
{
local *_ = \( $_->{"foo"} );
!defined or die qq{Bad value for "foo": null expected.\n};
}
for (keys %$_) {
$_ eq "foo" or die qq{Unrecognized key in hash: $_\n};
}
}
--- valid
{"foo": null}
--- invalid
{"foo": "abcda"}
Bad value for "foo": null expected.



=== TEST 34 number
--- spec
{foo: 10.2}
--- perl
if (defined) {
ref and ref eq 'HASH' or die qq{Invalid value: Hash expected.\n};
{
local *_ = \( $_->{"foo"} );
$_ == 10.2 or die qq{Bad value for "foo": number 10.2 expected.\n};
}
for (keys %$_) {
$_ eq "foo" or die qq{Unrecognized key in hash: $_\n};
}
}
--- valid
{"foo": 10.2}
--- invalid
{"foo": 1}
Bad value for "foo": number 10.2 expected.
{"foo": 10}
Bad value for "foo": number 10.2 expected.



=== TEST 35 minus number
--- spec
{foo: -0.2}
--- perl
if (defined) {
ref and ref eq 'HASH' or die qq{Invalid value: Hash expected.\n};
{
local *_ = \( $_->{"foo"} );
$_ == -0.2 or die qq{Bad value for "foo": number -0.2 expected.\n};
}
for (keys %$_) {
$_ eq "foo" or die qq{Unrecognized key in hash: $_\n};
}
}
--- valid
{"foo": -0.2}
--- invalid
{"foo": 10.2}
Bad value for "foo": number -0.2 expected.
{"foo": 0.2}
Bad value for "foo": number -0.2 expected.



=== TEST 36 string hash value
--- spec
{foo: "abcd"}
--- perl
if (defined) {
ref and ref eq 'HASH' or die qq{Invalid value: Hash expected.\n};
{
local *_ = \( $_->{"foo"} );
$_ eq "abcd" or die qq{Bad value for "foo": string "abcd" expected.\n};
}
for (keys %$_) {
$_ eq "foo" or die qq{Unrecognized key in hash: $_\n};
}
}
--- valid
{"foo": "abcd"}
--- invalid
{"foo": 10}
Bad value for "foo": string "abcd" expected.
{"foo": "abc"}
Bad value for "foo": string "abcd" expected.



=== TEST 37 utf8 string
--- spec
{foo: "你好"}
--- perl
if (defined) {
ref and ref eq 'HASH' or die qq{Invalid value: Hash expected.\n};
{
local *_ = \( $_->{"foo"} );
$_ eq "你好" or die qq{Bad value for "foo": string "你好" expected.\n};
}
for (keys %$_) {
$_ eq "foo" or die qq{Unrecognized key in hash: $_\n};
}
}
--- valid
{"foo": "你好"}
--- invalid
{"foo": 10}
Bad value for "foo": string "你好" expected.



=== TEST 38 allowed utf8 string
--- spec
{foo: STRING :allowed("你好")}
--- perl
if (defined) {
ref and ref eq 'HASH' or die qq{Invalid value: Hash expected.\n};
{
local *_ = \( $_->{"foo"} );
if (defined) {
!ref or die qq{Bad value for "foo": String expected.\n};
$_ eq "你好" or die qq{Invalid value for "foo": Allowed values are "你好".\n};
}
}
for (keys %$_) {
$_ eq "foo" or die qq{Unrecognized key in hash: $_\n};
}
}
--- valid
{"foo": "你好"}
--- invalid
{"foo": 10}
Invalid value for "foo": Allowed values are "你好".


=== TEST 39 string hash value with attrs
--- spec
{foo: "abcd" :to($ENV{QAT_ENV_FOO})}
--- perl
if (defined) {
ref and ref eq 'HASH' or die qq{Invalid value: Hash expected.\n};
{
local *_ = \( $_->{"foo"} );
$_ eq "abcd" or die qq{Bad value for "foo": string "abcd" expected.\n};
$ENV{QAT_ENV_FOO} = $_;
}
for (keys %$_) {
$_ eq "foo" or die qq{Unrecognized key in hash: $_\n};
}
}
--- valid
{"foo": "abcd"}
--- invalid
{"foo": 10}
Bad value for "foo": string "abcd" expected.
{"foo": "abc"}
Bad value for "foo": string "abcd" expected.


