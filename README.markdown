Name
===

**QAT** Qunar Auto Test Util library

SAYNOPSIS
===

    QAT::Util

        my $res = QAT::Util::do_http_request({
            url => 'http://www.qunar.com/'
        });

        # check request is success
        $res->is_success

        # get http code
        $res->code

        # get location header
        $res->header('Location');

    QAT::Validaotr

        use QAT::Validator;

        my $spec = '{"foo": INT}';

        my $validator = QAT::Validator->new(spec => $spec);

        my $data = { foo => 4 };
        eval {
            $validator->validate($data)
        };
        if ($@) {
            # invalid
        } else {
            # valid
        }

    QAT::Validator::QuasiQuote;

        use QAT::Validator::QuasiQuote;
        my $data = { foo => 4};

        my $foo;
        eval {
            [:validator|
                $data ~~ {
                    foo2: INT :to($foo)
                }
            |]
        };
        if ($@) {
            # invalid
        } else {
            # valid
        }

QAT Util
===

my $res = do_http_request({
    host => '',
    port => '',
    uri => '',
    url => '',
    data => '',
    data_urlencode => ''
    form => '',
});


QAT Validator Spec Syntax
===

    validator: lhs(?) value <commit> eofile

    lhs: variable '~~'

    variable: { Text::Balanced::extract_variable($text) }

    value: hash
            | array
            | scalar
            | 'true'
            | 'false'
            | 'null'
            | /\-?\d+(\.\d+)?/
            | { extract_quotelike($text) }

    hash: '{' pair(s? /,/) /,?/ '}' attr(s?)

    pair: key ':' value

    key: { extract_delimited($text, '"') }
            | ident

    array: '[' <commit> array_elem ']' attr(s?)

    array_elem: value

    scalar: type <commit> attr(s?)

    type: 'STRING'|'INT'| 'IDENT' | 'BOOL'| 'ANY'

    attr: ':' ident '(' argument(s /,/) ')'  | ':' ident

    ident: /^[A-Za-z]\w*/

    argument: /^\d+/
            | '[]'
            | variable
            | { extract_quotelike($text) }
            | { extract_codeblock($text) }

    eofile: /^\Z/

    Details see:
        http://search.cpan.org/~dconway/Parse-RecDescent-1.965001/lib/Parse/RecDescent.pm
        http://search.cpan.org/~adamk/Text-Balanced-2.02/lib/Text/Balanced.pm

QAT Validator Spec Samples:
===

    1. nonempty string
    STRING :nonempty

        --- valid
        "hello"

        --- invalid
        ""

    2. simple hash
    { foo: STRING }

        --- valid
        {"foo":"dog"}
        {"foo":32}
        null
        {}

        --- invalid
        {"foo2":32}
        32
        []

    3. hash required
    { "foo": STRING } :required

        --- valid
        {"foo":"hello"}
        {}
        {"foo":null}

        --- invalid
        null
        {"blah":"hi"}
        []
        32

    4. nonempty hash
    {"foo":STRING} :nonempty

        --- valid
        {"foo": "hello"}
        {"foo": null}

        --- invalid
        null

    5. required array
    [INT] :required

        --- valid
        [1,2]
        [0]

        --- invalid
        ["hello"]
        [1,2,"hello"]
        [1.32]
        null

    6. nonempty array
    [INT :required] :nonempty

        --- valid
        [1]

        --- invalid
        []

    7. regex matched string
    STRING :match(/^\d{4}-\d{2}-\d{2}$/, 'Date')

        --- valid
        2011-01-20

        --- invalid
        2011-aaa

    9. allowed string
    STRING :allowed('password', 'login', 'anonymous')

        --- valid
        "password"
        "login"

        --- invalid
        "abcd"

    10.  complex sampe 1
    {
        ret: BOOL :allowed('false') :required,
        errcode: INT :required,
        errmsg: STRING :required
    }

        --- valid
        { "ret": false, "errcode": 100, "errmsg": "No such user." }
        --- invalid
        { "ret": true }
        { "ret": false, "errcode": 100, "errmsg": "No such user." }

    11. complex sample 2
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

        --- valid
        {"ret": true, "data": []}
        {"ret": true, "data": [{"id": 1, "name": "zhang", "sex": "male"}]}

        --- invalid
        {"ret": false}
        {"ret": true, "data": [{"id": "aaa", "name": "zhang", "sex": "male"}]}
        {"ret": true, "data": [{"id": 2, "name": "", "sex": "male"}]}
        {"ret": true, "data": [{"id": 2, "name": "zhang", "sex": "ssss"}]}

    11. json data also is spec
        { "ret": true}
        { "foo": "abcd"}
        { "foo": null}
        { "foo": 10.24}

Install
===

    Extra dependencies are in inc directory.

    use FindBin;
    use lib "$FindBin::Bin/../inc";
    use lib "$FindBin::Bin/../lib";

Test Samples
===

    Simple project
    see:
        samples/Simple

Author
===

"liseen" <liseen.wan@gmail.com>
