Name
===

**QAT** Qunar Auto Test Util

SAYNOPSIS
===

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


Spec Syntax
===

    validator: lhs(?) value <commit> eofile
    lhs: variable '~~'
    variable: { Text::Balanced::extract_variable($text) }
    value: hash | array | scalar
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


Spec Samples:

    STRING :nonempty

        --- valid
        "hello"

        --- invalid
        ""

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

    {"foo":STRING} :nonempty

    [INT] :required

        --- valid
        [1,2]
        [0]
        --- invalid
        ["hello"]
        [1,2,"hello"]
        [1.32]
        null

    [INT :required] :nonempty

        --- valid
        [1]

        --- invalid
        [] conflict nonempty

    STRING :match(/^\d{4}-\d{2}-\d{2}$/, 'Date')

        --- valid
        2011-01-20
        --- invalid
        2011-aaa

    STRING :allowed('password', 'login', 'anonymous')

        --- valid
        "password"
        "login"
        --- invalid
        "abcd"

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

Install
===

    Extra dependencies in inc directory.

    use FindBin;
    use lib "$FindBin::Bin/../inc";
    use lib "$FindBin::Bin/../lib";

Author
===

"liseen" <liseen.wan@gmail.com>
