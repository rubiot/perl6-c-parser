#! /usr/bin/env perl6

use v6;
use Terminal::ANSIColor;
#use Grammar::Tracer;
#use Grammar::Debugger;

unit grammar C::Parser::Grammar;

token TOP {
  ^ <translation-unit>
  [ $ ||
    {
      my $bad    = $<translation-unit><external-declaration>[*-1];
      my $lineno = substr($<translation-unit>.orig, 0, $bad.to).lines.elems;
      my $msg    = substr($<translation-unit>.orig, $bad.to, min($bad.to + 60, $<translation-unit>.orig.chars));
      my $msg2   = substr($msg, 0, min(60, $msg.chars)).subst(/\s+/, ' ', :g);
      die("input:" ~ $lineno ~ ": expected external declaration, but got: `" ~
          colored($msg2, 'yellow') ~ "...`")
    }
  ]
}

token ws {
  <!ww> [ \s | <.comment> | <.compiler-directive> ]*
}

token compiler-directive {
  '#' \N+ [ <after '\\'> \n\N+ ]*
}

proto token comment {*}

token comment:sym<//> {
  <sym> \N*
}

token comment:sym</*> {
  <sym> ~ '*/' .*?
}

token translation-unit {
  <.ws> <( <external-declaration>+ % <.ws> )> <.ws>
}

proto token external-declaration {*}

token external-declaration:sym<function-definition> {
  <function-definition>
}

token external-declaration:sym<declaration> {
  <declaration>
}

#rule macro-call {
#  <postfix-expression> ';'? # MACRO(a, b, c)
#}

# For old-style functions:
#
# int max(a, b, c) // declarator
# int a, b, c;     // declaration list
# {                // compound statement
#   ...
# }
#
# For new style functions:
#
# int max(int a, int b, int c) // 'int' is the declaration specifier
#                              // 'max(int a, int b, int c)' is the declarator
# {                            // compound statement
#   ...
# }
rule function-definition {
  <declaration-type-specifiers>?
  <declarator>
  <declaration-list>?
  <compound-statement>
}

rule declaration {
  <declaration-specifiers> <init-declarator-list>? ';'
}

# variable declaration. E.g.: int a, b, c;
rule declaration-list {
  <!before '}'> # optimizing for empty bodies
  <declaration>+
}

rule declaration-type-specifiers { # used only on function parameters
  <declaration-type-specifier>* <type-only-specifier>
}

rule declaration-type-specifier {
  || <storage-class-specifier> # static, typedef, etc.
  || <type-qualifier>          # const, volatile
}

regex declaration-specifiers { # used only on declarations
  [ <declaration-specifier> <.ws> ]*?
  <type-specifier>
}

rule declaration-specifier {
  || <storage-class-specifier> # static, typedef, etc.
  || <type-qualifier>          # const, volatile
}

token storage-class-specifier {
  'auto' | 'register' | 'static' | 'extern' | 'typedef'
  | 'inline' | '__inline'  # gato!!
}

token type-only-specifier { # um tipo que pode ser usado no retorno de uma funcao, por ex.
  | 'void' | 'char' | 'short' | 'int' | 'long' | 'float' | 'double' | 'signed'
  | 'unsigned' | <struct-or-union-type-specifier> | <enum-type-specifier> | <typedef-name>
}

token type-specifier {
  | 'void' | 'char' | 'short' | 'int' | 'long' | 'float' | 'double' | 'signed'
  | 'unsigned' | <struct-or-union-specifier> | <enum-specifier> | <typedef-name>
}

token type-qualifier {
  | 'const' | 'volatile'
  | 'long'  | 'short' | 'unsigned'
}

rule struct-or-union-type-specifier {
  <struct-or-union> <identifier>
}

rule struct-or-union-specifier {
  <struct-or-union> <identifier>? [ '{' ~ '}' <struct-declaration-list> ]?
}

token struct-or-union {
  'struct' | 'union'
}

rule struct-declaration-list {
  <struct-declaration>+
}

rule init-declarator-list {
  <init-declarator>+ % ','
}

rule init-declarator {
  <declarator> [ '=' <initializer> ]?
}

rule struct-declaration {
  <!before <.ws> '}'> # speeding things up
  <specifier-qualifier-list> <struct-declarator-list> ';'
}

rule specifier-qualifier-list {
  [ <type-specifier> | <type-qualifier> ]+
}

rule struct-declarator-list {
  <struct-declarator>+ % ','
}

rule struct-declarator {
  || <declarator>
  || <declarator>? ':' <constant-expression>
}

rule enum-type-specifier {
  || 'enum' <identifier>
}

rule enum-specifier {
  || 'enum' <identifier>? '{' <enumerator-list> '}'
  || 'enum' <identifier>
}

rule enumerator-list {
  <enumerator>+ % ','
}

rule enumerator {
  || <identifier>
  || <identifier> '=' <constant-expression>
}

rule declarator {
  <pointer>? <direct-declarator>
}

rule direct-declarator {
  [
    | <identifier>
    | '(' <declarator> ')'
  ]
  [
    || '[' <constant-expression>? ']'
    || '(' <parameter-type-list>  ')'
    || '(' <identifier-list>?     ')'
  ]?
}

rule pointer {
  [ '*' <type-qualifier-list>? ]+
}

rule type-qualifier-list {
  <type-qualifier>+
}

rule parameter-type-list {
  <parameter-list> [ ',' '...' ]?
}

rule parameter-list {
  <parameter-declaration>+ % ','
}

rule parameter-declaration {
  #{ say substr($/.orig, $¢.pos, 16) }
  || <declaration-type-specifiers> <declarator>
  || <declaration-type-specifiers> <abstract-declarator>?
}

rule identifier-list {
  <identifier>+ % ','
}

rule initializer {
  || <assignment-expression>
  || '{' ~ '}' [ <initializer-list>+ % ',' ]
}

rule initializer-list {
  <initializer>+ % ','
}

rule type-name {
  <specifier-qualifier-list> <abstract-declarator>?
}

rule abstract-declarator {
  || <pointer>
  || <pointer>? <direct-abstract-declarator>
}

rule direct-abstract-declarator {
  '(' ~ ')' <abstract-declarator>
  [
    | '[' ~ ']' <constant-expression>
    | '(' ~ ')' <parameter-type-list>
  ]?
}

token typedef-name {
  <.identifier> <!before <.ws> <[(;[=]> >
}

proto rule statement {*}
rule statement:sym<labeled>    { <!before <[};]> > <labeled-statement>    }
rule statement:sym<compound>   { <!before <[};]> > <compound-statement>   }
rule statement:sym<selection>  { <!before <[};]> > <selection-statement>  }
rule statement:sym<iteration>  { <!before <[};]> > <iteration-statement>  }
rule statement:sym<jump>       { <!before <[};]> > <jump-statement>       }
rule statement:sym<expression> { <!before <[}]>  > <expression-statement> }

rule labeled-statement {
  || <identifier> ':' <statement>
  || $<cmd>='case' <constant-expression> ':' <statement>
  || $<cmd>='default' ':' <statement>
}

rule expression-statement {
  <expression>? ';'
}

# also called 'block'
rule compound-statement {
  '{' ~ '}' [ <declaration-list>? <statement-list>? ]
}

rule statement-list {
  <!before '}' > # optimizing for empty bodies
  <statement>+
}

rule selection-statement {
  | $<cmd>='if'     '(' <expression> ')' <then=.statement> [ 'else' <else=.statement> ]?
  | $<cmd>='switch' '(' <expression> ')' <statement>
}

rule iteration-statement {
  | $<cmd>='while' '(' <expression> ')' <statement>
  | $<cmd>='do' <statement> 'while' '(' <expression> ')' ';'
  | $<cmd>='for' '(' <init-expr=.expression>? ';' <condition-expr=.expression>? ';' <inc-expr=.expression>? ')' <statement>
}

rule jump-statement {
  [
    | $<cmd>='goto' <identifier>
    | $<cmd>='continue'
    | $<cmd>='break'
    | $<cmd>='return' <expression>?
  ]
  ';'
}

rule expression {
  <!before <[;)}]> >
  <assignment-expression>+ % ','
}

rule assignment-expression {
  <lvalue-assignment-list>? <conditional-expression>
}

rule lvalue-assignment-list {
  <lvalue-assignment>+
}

rule lvalue-assignment {
  <unary-expression> <assignment-operator>
}

token assignment-operator {
  [ <[ -*/%+&^| ]> | '<<' | '>>' ]? '='
}

proto rule conditional-expression {*}
rule conditional-expression:sym<single>  { <single-conditional-expression>  }
rule conditional-expression:sym<ternary> { <ternary-conditional-expression> }

rule single-conditional-expression {
  <logical-OR-expression> <!before '?'>
}

rule ternary-conditional-expression {
  <condition=.logical-OR-expression>
  '?' <then=.expression>
  ':' <else=.conditional-expression> # why isn't this an <expression> too?
}

token constant-expression {
  <.conditional-expression>
}

token logical-OR-op { '||' }
rule logical-OR-expression {
  <logical-AND-expression>+ % <op=.logical-OR-op>
}

token logical-AND-op { '&&' }
rule logical-AND-expression {
  <inclusive-OR-expression>+ % <op=.logical-AND-op>
}

token inclusive-OR-op { '|' }
rule inclusive-OR-expression {
  <exclusive-OR-expression>+ % <op=.inclusive-OR-op>
}

token exclusive-OR-op { '^' }
rule exclusive-OR-expression {
  <AND-expression>+ % <op=.exclusive-OR-op>
}

token AND-op { '&' <!before <[&=]> > }
rule AND-expression {
  <equality-expression>+ % <op=.AND-op>
}

rule equality-expression {
  <relational-expression>+ % <op=.equality-operator>
}

proto token equality-operator   {*}
token equality-operator:sym<==> { <sym> }
token equality-operator:sym<!=> { <sym> }

rule relational-expression {
  <shift-expression>+ % <op=.relational-operator>
}

proto token relational-operator   {*}
token relational-operator:sym«<»  { <sym> }
token relational-operator:sym«>»  { <sym> }
token relational-operator:sym«<=» { <sym> }
token relational-operator:sym«>=» { <sym> }

rule shift-expression {
  <additive-expression>+ % <op=.shift-operator>
}

proto token shift-operator   {*}
token shift-operator:sym«<<» { <sym> }
token shift-operator:sym«>>» { <sym> }

rule additive-expression {
  <multiplicative-expression>+ % <op=.additive-operator>
}

proto token additive-operator  {*}
token additive-operator:sym<+> { <sym> }
token additive-operator:sym<-> { <sym> }

rule multiplicative-expression {
  <cast-expression>+ % <op=.multiplicative-operator>
}

proto token multiplicative-operator  {*}
token multiplicative-operator:sym<*> { <sym> }
token multiplicative-operator:sym</> { <sym> }
token multiplicative-operator:sym<%> { <sym> }

rule cast-expression {
  <cast-operator>* <unary-expression>
}

rule cast-operator { '(' ~ ')' <type-name> }

proto rule unary-expression {*}
rule unary-expression:sym<postfix>     { <postfix-expression>       }
rule unary-expression:sym<++>          { <unary-pre-increment-expr> }
rule unary-expression:sym<-->          { <unary-pre-decrement-expr> }
rule unary-expression:sym<unary-cast>  { <unary-cast-expression>    }
rule unary-expression:sym<sizeof-expr> { <unary-sizeof-expression>  }
rule unary-expression:sym<sizeof-type> { <unary-sizeof-type>        }

proto token unary-operator {*}
token unary-operator:sym<&> { <sym> }
token unary-operator:sym<*> { <sym> }
token unary-operator:sym<+> { <sym> }
token unary-operator:sym<-> { <sym> }
token unary-operator:sym<~> { <sym> }
token unary-operator:sym<!> { <sym> }

rule unary-sizeof-type {
  $<sizeof>='sizeof' '(' <type-name> ')'
}

rule unary-sizeof-expression {
  $<sizeof>='sizeof' <unary-expression>
}

rule unary-cast-expression {
  <unary-operator> <cast-expression>
}

rule unary-pre-increment-expr {
  $<prefix>='++' <unary-expression>
}

rule unary-pre-decrement-expr {
  $<prefix>='--' <unary-expression>
}

rule postfix-expression {
  <postfix-expression-first> <postfix-expression-rest>*
}

proto rule postfix-expression-first {*}
rule postfix-expression-first:sym<primary> {
  <primary-expression>
}
rule postfix-expression-first:sym<initializer> {
  || '(' <type-name> ')'
  || '{' <initializer-list> ','? '}'
}

proto rule postfix-expression-rest {*}
rule postfix-expression-rest:sym<[ ]> { <postfix-bracketed-expr>      }
rule postfix-expression-rest:sym<( )> { <postfix-parens-expr>         }
rule postfix-expression-rest:sym<.>   { <postfix-member-expr>         }
rule postfix-expression-rest:sym«->»  { <postfix-indirection-expr>    }
rule postfix-expression-rest:sym<++>  { <postfix-post-increment-expr> }
rule postfix-expression-rest:sym<-->  { <postfix-post-decrement-expr> }

rule postfix-bracketed-expr      { '[' <expression> ']'                }
rule postfix-parens-expr         { '(' <argument-expression-list>? ')' }
rule postfix-member-expr         { '.' <identifier>                    }
rule postfix-indirection-expr    { '->' <identifier>                   }
rule postfix-post-increment-expr { '++'                                }
rule postfix-post-decrement-expr { '--'                                }

rule primary-expression {
  || '(' ~ ')' <expression>
  || <identifier>
  || <constant>
}

rule argument-expression-list {
  <!before ')'> <assignment-expression>+ % ','
}

proto token constant {*}
token constant:sym<float>   { <floating-constant>    }
token constant:sym<integer> { <integer-constant>     }
token constant:sym<char>    { <character-constant>   }
token constant:sym<enum>    { <enumeration-constant> }
token constant:sym<string>  { <string>               }

proto token integer-constant {*}
token integer-constant:sym<int>   { \d+ <[uUlL]>?                  }
token integer-constant:sym<octal> { '0' <[0..7]>+                  }
token integer-constant:sym<hex>   { '0' <[Xx]> <[0..9 a..f A..F]>+ }

token character-constant {
  '\'' ~ [ <!after '\\'> '\'' ] .*?
}

token floating-constant {
  [ \d+ ]? '.' \d+
}

token enumeration-constant {
  <.identifier>
}

token identifier {
  <!reserved-word> <?before <[ a..z A..Z _ ]>> <[ a..z A..Z 0..9 _]>+
}

token string {
  [ <single-string> <.ws> ]+
}

token single-string {
  '"' ~ [ <!after '\\'> '"' ] .*?
}

token reserved-word {
  <|w>
  [
    | 'auto'     | 'double' | 'int'      | 'struct'
    | 'break'    | 'else'   | 'long'     | 'switch'
    | 'case'     | 'enum'   | 'register' | 'typedef'
    | 'char'     | 'extern' | 'return'   | 'union'
    | 'const'    | 'float'  | 'short'    | 'unsigned'
    | 'continue' | 'for'    | 'signed'   | 'void'
    | 'default'  | 'goto'   | 'sizeof'   | 'volatile'
    | 'do'       | 'if'     | 'static'   | 'while'
  ]
  <|w>
}

#say C::Parser::Grammar.parse('short x, y;', :rule('declaration'));
