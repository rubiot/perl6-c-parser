#!/usr/bin/env perl6
# run: perl6 -I./lib t/01_grammar.t
use v6;
use Terminal::ANSIColor;
use C::Parser::Grammar;
#use C::Parser::Actions;
use Test;

plan 79;

#our $actions = C::Parser::Actions.new;

sub match(Str $test_case, Str $rule, Str $code) {
  C::Parser::Grammar.parse($code, :rule($rule));
  unless is($/.WHAT.perl, 'Match', "$rule: $test_case") {
    say colored($code, 'magenta');
  }
}

use-ok 'C::Parser::Grammar';
use-ok 'C::Parser::Actions';

for 'expression post-increment', 'i++',
    'expression pre-increment',  'i--',
    'expression 2',              'p == NULL',
    'expression 3',              '(x = 1) == 1',
    'expression function call',  'f(1)',
    'expression bracketed',      'f[1]',
    'expression member access',  'st.member',
    'expression indirect access','st->member'
   -> $t, $c
{
   match($t, 'expression', $c)
}

for 'empty compound statement',       '{ }',
    'non-empty compound statement',   '{ return 0; }',
    'body with declaration',          '{ int x; }',
    'body with declaration and stmt', '{ int x; return; }',
    'body with function call',        '{ exit(); }'
   -> $t, $c
{
   match($t, 'compound-statement', $c)
}

for 'selection statement if',            'if (1) {}',
    'selection statement if-else1',      'if (1) {} else {}',
    'selection statement switch',        'switch (1) {}',
    'selection statement switch nostmt', 'switch (1) { case 1:; }'
   -> $t, $c
{
   match($t, 'selection-statement', $c)
}

for 'labeled statement label',        'label: return;',
    'labeled statement case',         'case 1: break;',
    'labeled statement default',      'default: break;'
   -> $t, $c
{
   match($t, 'labeled-statement', $c)
}

match('iteration statement for empty',  'iteration-statement','for (;;) {}');
match('iteration statement bodyless for','iteration-statement','for (;;);');
match('iteration statement for',        'iteration-statement','for (i = 10; i; i--) {}');
match('iteration statement do',         'iteration-statement','do {} while (1);');
match('iteration statement while',      'iteration-statement','while (1) {}');

match('jump statement goto',            'jump-statement',     'goto label;');
match('jump statement continue',        'jump-statement',     'continue;');
match('jump statement break',           'jump-statement',     'break;');
match('jump statement return',          'jump-statement',     'return;');
match('jump statement return value',    'jump-statement',     'return 1;');

match('void main()',                    'function-definition','int main(void) { return 0; }');
match('non-void main()',                'function-definition','int main(int argc, const char **argv) { return 0; }');

match('function prototype 0',           'declaration',        'int main(int a);');
match('function prototype 1',           'declaration',        'int main(void);');
match('function prototype 2',           'declaration',        'int main(const long int a);');
match('function prototype - type-only', 'declaration',        'int main(int, short);');
match('function prototype - usertype',  'declaration',        'int main(usertype, short);');
match('struct declaration',             'declaration',        'struct s { int a; };');
match('union declaration',              'declaration',        'union s { int a; char b; };');
match('struct declaration - multiple',  'declaration',        'struct s { int a; short b; };');
match('struct declaration - recursive', 'declaration',        'struct s { struct ss { int a; } x; };');
match('typedef struct declaration',     'declaration',        'typedef struct { int a; } s;');
match('variable declaration',           'declaration',        'int x;');
match('long int variable declaration',  'declaration',        'long int x;');
match('long variable declaration',      'declaration',        'long x;');
match('long long variable declaration', 'declaration',        'long long x;');
match('short int variable declaration', 'declaration',        'short int x;');
match('short variable declaration',     'declaration',        'short x;');
match('unsigned variable declaration',  'declaration',        'unsigned x;');
match('const variable declaration',     'declaration',        'const int x;');
match('extern variable declaration',    'declaration',        'extern int x;');
match('static variable declaration',    'declaration',        'static int x;');
match('array declaration',              'declaration',        'int x[5];');
match('pointer declaration',            'declaration',        'int *x;');
match('pointer-to-pointer declaration', 'declaration',        'int **x;');
match('user type variable declaration', 'declaration',        'user_type x;');
match('multiple variable declarations', 'declaration',        'int x, y;');
match('multiple short declarations',    'declaration',        'short x, y;');
match('init int variable',              'declaration',        'int x = 0;');
match('init int ptr variable',          'declaration',        'int *x = &y;');
match('init char variable',             'declaration',        'const char *x = "abcd";');

match('string',                         'string',             '"xx xx"');
match('escaped string 1',               'string',             '"xx\\txx"');
match('escaped string 2',               'string',             '"xx \\"yy\\" xx"');
match('multi-piece string',             'string',             '"xx" "xx"');

match('single-digit integer',           'constant',           '0');
match('multi-digit integer',            'constant',           '1234');
match('float constant',                 'constant',           '3.1416');
match('float constant 2',               'constant',           '.1416');

match('assignment expression 1',        'assignment-expression', 'x = 1');
match('assignment expression 2',        'assignment-expression', '(x = 1)');
match('assignment expression 3',        'assignment-expression', 'x = f(1)');

match('pointer 1',                      'pointer',             '*');
match('pointer 2',                      'pointer',             '**');
match('pointer 3',                      'pointer',             '* const *');
match('pointer 4',                      'pointer',             '* const * const');

match('ternary if', 'conditional-expression', 'x ? 1 : 0');
