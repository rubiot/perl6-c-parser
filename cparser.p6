#!/usr/bin/env perl6

use v6;
use lib './lib';
use C::Parser;
use C::AST;
use Terminal::ANSIColor;

our $level = 0;

our &inblue   := &colored.assuming(*, 'blue');
our &inyellow := &colored.assuming(*, 'yellow');
our &ingreen  := &colored.assuming(*, 'green');
our &inbold   := &colored.assuming(*, 'bold');

# Modificando o comportamento da funcao say(). Agora ela indenta tudo que
# imprime com base na variavel global $level.
&say.wrap: sub (|c) {
  print "│ " x $level;
  #print "▸ " x $level;
  nextsame;
};

# Trait que incrementa o nivel de indentacao antes de chamar uma funcao e
# decrementa-o depois da chamada.
multi sub trait_mod:<is>(Routine $r, :$indented!) {
  $r.wrap: {
    $level++;
    callsame;
    $level--;
  };
};

sub MAIN($file)
{
  my $m = C::Parser.parsefile($file);
  die "Couldn't parse $file" without $m;
  #say $m;
  say inyellow($m.ast.external-declarations.elems ~ " external declarations in $file");
  for $m.ast.external-declarations -> $d {
    #say '~' x 80;
    print-external-declaration($d);
  }
}

multi print-external-declaration(C::AST::external-declaration $e)
{
  say $e.WHAT;
  die "unhandled external-declaration";
}

multi print-external-declaration(C::AST::function-definition $f)
{
  state $first-external-declaration = True;
  print $first-external-declaration ?? '┌' !! '├─';
  $first-external-declaration = False;

  say $f.WHAT, " line $f.line(): ", inyellow($f.code);
  #say inbold("line &$f.line(): function");
  $level++; LEAVE { $level-- }
  for <identifier return-type parameters> -> $e {
    say inblue("$e: ") ~ inyellow($f."$e"());
  }
  say inblue( "body: " ~ inyellow($f.body.code) );
  print-declarations($f.body.declarations);
  print-statements($f.body.statements);
}

multi print-external-declaration(C::AST::declaration $d)
{
  print-declaration($d);
}

sub print-statements(C::AST::statement @stmts)
{
  print-statement($_) for @stmts;
}

sub print-statement(C::AST::statement $stmt)# is indented
{
  #print '├─';
  say '├─', inbold($stmt.^name), " line $stmt.line(): ", inyellow($stmt.code);
  #$level++; LEAVE { $level-- }
  (temp $level)++;

  given $stmt {
    when C::AST::goto-statement {
      say inblue("label: ") ~ $stmt.label;
    }
    when C::AST::continue-statement {
    }
    when C::AST::break-statement {
    }
    when C::AST::return-statement {
      print-expression($stmt.value) with $stmt.value;
    }
    when C::AST::if-statement {
      say inblue("condition: ");
      print-expression($stmt.condition);
      say inblue("then: ");
      print-statement($stmt.then);
      say inblue("else: ");
      print-statement($stmt.else) with $stmt.else;
    }
    when C::AST::switch-statement {
      say inblue("value:");
      print-expression($stmt.value);
      #say inblue("block:");
      print-statement($stmt.block);
    }
    when C::AST::case-statement {
      say inblue("value: $stmt.value()");
      #say inblue("block:");
      print-statement($stmt.block);
    }
    when C::AST::default-statement {
    }
    when C::AST::label-statement {
      # Label get coupled to its following statement.
      # Maybe we should decouple them.
      print-statement($stmt.block);
    }
    when C::AST::while-statement {
      say inblue("condition: ");
      print-expression($stmt.condition);
      print-statement($stmt.block);
    }
    when C::AST::do-statement {
      say inblue("condition: ");
      print-expression($stmt.condition);
      print-statement($stmt.block);
    }
    when C::AST::for-statement {
      say inblue("init: ");
      print-expression($stmt.init-expr);
      say inblue("condition: ");
      print-expression($stmt.condition-expr);
      say inblue("inc: ");
      print-expression($stmt.increment-expr);
      print-statement($stmt.block);
    }
    when C::AST::compound-statement {
      print-declarations($stmt.declarations);
      print-statements($stmt.statements);
    }
    when C::AST::expression-statement {
      print-expression($stmt.expr);
    }
    default {
      say $stmt.WHAT;
      die "unhandled statement: " ~ $stmt.code;
    }
  }
}

sub print-declarations(C::AST::declaration @decls)
{
  print-declaration($_) for @decls;
}

sub print-declaration(C::AST::declaration $decl) is indented
{
  #print '├─';
  say '├─', $decl.WHAT, " line $decl.line(): ", inyellow($decl.code);
  #$level++; LEAVE { $level-- }
  (temp $level)++;

  for <type identifier value> -> $e {
    say inblue("$e: ") ~ inyellow($decl."$e"());
  }
}

multi print-expression(C::AST::assignment-expression $expr)
{
  say inbold($expr.^name), " line $expr.line(): ", inyellow($expr.code);
  #$level++; LEAVE { $level-- }
  (temp $level)++;

  without $expr {
    say "<void>";
    return;
  }

  for $expr.assignment-list -> $a {
    say inblue("assignment: ") ~ $a.code;
  }
  print-expression($expr.expression);
}

multi print-expression(C::AST::constant $expr)
{
  say inbold($expr.^name), " line $expr.line(): ", inyellow($expr.code);
  #$level++; LEAVE { $level-- }
  (temp $level)++;

  say inblue("value: ") ~ inyellow($expr.value);
}

multi print-expression(C::AST::identifier $expr)
{
  say inbold($expr.^name), " line $expr.line(): ", inyellow($expr.code);
  #$level++; LEAVE { $level-- }
  (temp $level)++;

  say inblue("name: ") ~ inyellow($expr.name);
}

multi print-expression(C::AST::postfix-expression $expr)
{
  say inbold($expr.^name), " line $expr.line(): ", inyellow($expr.code);
  #$level++; LEAVE { $level-- }
  (temp $level)++;

  #say inblue("expression: ");
  print-expression($expr.expression);
  say inblue("postfix: ") ~ inyellow($expr.postfix.join);
}

multi print-expression(C::AST::prefix-expression $expr)
{
  say inbold($expr.^name), " line $expr.line(): ", inyellow($expr.code);
  #$level++; LEAVE { $level-- }
  (temp $level)++;

  say inblue("prefix: ") ~ inyellow($expr.prefix);
  #say inblue("expression: ");
  print-expression($expr.expression);
}

multi print-expression(C::AST::cast-expression $expr)
{
  say inbold($expr.^name), " line $expr.line(): ", inyellow($expr.code);
  #$level++; LEAVE { $level-- }
  (temp $level)++;

  say inblue("cast operator: ") ~ inyellow($expr.cast-operator.join);
  print-expression($expr.expression);
}

multi print-expression(C::AST::expression-list $expr)
{
  say inbold($expr.^name), " line $expr.line(): ", inyellow($expr.code);
  #$level++; LEAVE { $level-- }
  (temp $level)++;

  for roundrobin $expr.operands, $expr.operators -> [$e, $op = Nil] {
    print-expression($e);
    say ingreen($op) with $op;
  }
}

