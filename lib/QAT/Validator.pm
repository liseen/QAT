package QAT::Validator;

use strict;
use warnings;

#use Smart::Comments;
use JSON;
use QAT::Validator::Compiler;
#use QTest::Validator::QuasiQuote;

our $Comp = QAT::Validator::Compiler->new;

sub validate {
    die "Execution aborted due to syntax errors in validator spec.\n";
}

sub new {
    my $class = ref $_[0] ? ref shift : shift;

    my %args = @_;

    my $name = $args{name} || '';
    my $spec = $args{spec};

    my $valid_code = $Comp->validator($spec, 1) or
        die "Execution aborted due to syntax errors in validator spec.\n";
    $valid_code =~ s/\n/ /sg;

    my $code = "*validate = sub { shift; local \$_ = shift; $valid_code }";
    {
        no warnings 'redefine';
        no strict;
        eval $code;
        if ($@) {
            die "$name - Bad perl code emitted - $@\n";
        } else {
            # "$name - perl code emitted is well formed\n";
        }
    }

    my $self = bless {
        name => $args{name},
        spec => $spec,
        valid_code => $valid_code
    }, $class;

    $self;
}

1;

