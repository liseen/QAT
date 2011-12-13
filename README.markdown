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
            # valid
        } else {
            # invalid
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
            # valid
        } else {
            # invalid
        }

Install
===

cpan JSON::XS



Author
===

"liseen" <liseen.wan@gmail.com>
