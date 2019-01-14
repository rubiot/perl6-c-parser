use v6;
unit module C::AST;

class node {
  has Str $!code;
  has Int $.line;

  submethod BUILD(Match :$match)
  {
    $!code = ~$match;
    $!line = substr($match.orig, 0, $match.from).lines.elems + 1;
  }

  method !clean($c is copy)
  {
    $c = ~$c;
    $c ~~ s:g/ '/*' ~ '*/' .*? //;
    $c ~~ s:g/ '//' \N* //;
    $c ~~ s:g/[\s|\v]+/ /;
    $c.trim;
  }
  method print { ... }
  method raw-code {
    $!code
  }
  method code {
    self!clean($!code)
  }
}

class external-declaration is node { }

class translation-unit is node {
  has external-declaration @.external-declarations;
}

class parameter is node {
  has $.type is required;
  has Str $.identifier is required;
}

class declaration is external-declaration {
  has $.type is required;
  has Str $.identifier is required;
  has $.value;
}

class statement is node { }

class rvalue-expression is node { }

class unary-expression is rvalue-expression { }

class postfix-expression is unary-expression {
  has $.expression is required;
  has @.postfix;
}

class prefix-expression is unary-expression {
  has $.prefix is required;
  has rvalue-expression $.expression is required;
}

class cast-expression is rvalue-expression {
  has @.cast-operator is required;
  has $.expression is required;
}

class expression-list is rvalue-expression {
  has @.operands is required;
  has @.operators is required;
}

class identifier is rvalue-expression {
  has Str $.name is required;
}

class constant is rvalue-expression {
  has Str $.value is required;
}

# a =
# a +=
class lvalue-assignment is node {
  #has unary-expression $.lvalue is required;
  has $.lvalue is required;
  has Str $.operator;
}

# a = b = c = 0
# a += b
class assignment-expression is rvalue-expression {
  #has lvalue-assignment @.assignment-list;
  has @.assignment-list;
  has rvalue-expression $.expression is required;
}

# a
# a = b
# a += b
# a = b, c = d
#class expression is node {
#  has assignment-expression @.assignment-expressions is required;
#}
#
class return-statement is statement {
  has $.value;
}

class continue-statement is statement { }

class break-statement is statement { }

class goto-statement is statement {
  has Str $.label is required;
}

class if-statement is statement {
  has $.condition is required;
  has statement $.then is required;
  has statement $.else;
}

class switch-statement is statement {
  has $.value is required;
  has statement $.block is required;
}

class case-statement is statement {
  has Str $.value is required;
  #has expression $.value is required;
  has statement $.block;
}

class default-statement is statement {
  has statement $.block;
}

class label-statement is statement {
  has Str $.label is required;
  has statement $.block;
}

class while-statement is statement {
  has $.condition is required;
  has statement $.block;
}

class do-statement is statement {
  has $.condition is required;
  has statement $.block;
}

class for-statement is statement {
  has $.init-expr;
  has $.condition-expr;
  has $.increment-expr;
  has statement $.block;
}

class compound-statement is statement {
  has declaration @.declarations;
  has statement @.statements is required;
}

class expression-statement is statement {
  has $.expr;
}

class function-definition is external-declaration {
  has $.return-type;
  has Str $.identifier is required;
  has Str $.parameters;
  has compound-statement $.body;
}

class macro-call is external-declaration {
  has Str $.macro is required;
  has Str $.args;
}

