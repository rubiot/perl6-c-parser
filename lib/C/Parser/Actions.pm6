use v6;
use Terminal::ANSIColor;
use C::Parser::Utils;
use C::AST;

unit class C::Parser::Actions;

method TOP($/) {
  make $<translation-unit>.made;
}

method translation-unit($/) {
  #my @external-declarations = @<external-declaration>».made;
  my @external-declarations = map { |.made // () }, @<external-declaration>;
  make C::AST::translation-unit.new(:match($/), :@external-declarations);
}

method external-declaration:sym<function-definition>($/) {
  make $<function-definition>.made;
}

method external-declaration:sym<declaration>($/) {
  make $<declaration>.made;
}

method function-definition($/) {
  make C::AST::function-definition.new(
    :match($/),
    :return-type(C::Parser::Utils::extractFunctionReturnType($/)),
    :identifier(C::Parser::Utils::extractFunctionId($/)),
    :parameters(C::Parser::Utils::extractFunctionParameters($/)),
    :body($<compound-statement>.made // '<empty>' but False)
  );
}

method macro-call($/) {
  make C::AST::macro-call.new(
    :match($/),
    :macro(~$<postfix-expression><postfix-expression-first>),
    :args(~$<postfix-expression><postfix-expression-rest>)
  );
}

method declaration($/) {
  my @decls = gather for $<init-declarator-list><init-declarator> -> $d {
    #say $d;
    take C::AST::declaration.new(
      :match($/),
      :type($<declaration-specifiers> ~ ( $d<declarator><pointer> // '' )),
      :identifier(C::Parser::Utils::extractDeclarationId($d)),
      :value($d<initializer> ?? ~$d<initializer> !! '<uninitialized>' but False)
    );
  }
  make @decls;
}

#method declaration-list($/) {
#  say color('yellow'), $/.trim, color('reset'), color('bold'), " <-- declaration-list", color('reset')
#}
#
#method declaration-specifiers($/) {
#  say color('yellow'), $/.trim, color('reset'), color('bold'), " <-- declaration-specifiers", color('reset')
#}
#
#method declaration-specifier($/) {
#  say color('yellow'), $/.trim, color('reset'), color('bold'), " <-- declaration-specifier", color('reset');
#}
#
#method storage-class-specifier($/) {
#  say color('yellow'), $/.trim, color('reset'), color('bold'), " <-- storage-class-specifier", color('reset')
#}
#
#method type-specifier($/) {
#  say color('yellow'), $/.trim, color('reset'), color('bold'), " <-- type-specifier", color('reset')
#}
#
#method type-qualifier($/) {
#  say color('yellow'), $/.trim, color('reset'), color('bold'), " <-- type-qualifier", color('reset')
#}
#
#method struct-or-union-specifier($/) {
#  say color('yellow'), $/.trim, color('reset'), color('bold'), " <-- struct-or-union-specifier", color('reset')
#}
#
#method struct-or-union($/) {
#  say color('yellow'), $/.trim, color('reset'), color('bold'), " <-- struct-or-union", color('reset')
#}
#
#method struct-declaration-list($/) {
#  say color('yellow'), $/.trim, color('reset'), color('bold'), " <-- struct-declaration-list", color('reset')
#}
#
#method init-declarator-list($/) {
#  say color('yellow'), $/.trim, color('reset'), color('bold'), " <-- init-declarator-list", color('reset')
#}
#
#method init-declarator($/) {
#  say color('yellow'), $/.trim, color('reset'), color('bold'), " <-- init-declarator", color('reset')
#}
#
#method struct-declaration($/) {
#  say color('yellow'), $/.trim, color('reset'), color('bold'), " <-- struct-declaration", color('reset')
#}
#
#method specifier-qualifier-list($/) {
#  say color('yellow'), $/.trim, color('reset'), color('bold'), " <-- specifier-qualifier-list", color('reset')
#}
#
#method struct-declarator-list($/) {
#  say color('yellow'), $/.trim, color('reset'), color('bold'), " <-- struct-declarator-list", color('reset')
#}
#
#method struct-declarator($/) {
#  say color('yellow'), $/.trim, color('reset'), color('bold'), " <-- struct-declarator", color('reset')
#}
#
#method enum-specifier($/) {
#  say color('yellow'), $/.trim, color('reset'), color('bold'), " <-- enum-specifier", color('reset')
#}
#
#method enumerator-list($/) {
#  say color('yellow'), $/.trim, color('reset'), color('bold'), " <-- enumerator-list", color('reset')
#}
#
#method enumerator($/) {
#  say color('yellow'), $/.trim, color('reset'), color('bold'), " <-- enumerator", color('reset')
#}
#
#method declarator($/) {
#  say color('yellow'), $/.trim, color('reset'), color('bold'), " <-- declarator", color('reset')
#}
#
#method direct-declarator($/) {
#  say color('yellow'), $/.trim, color('reset'), color('bold'), " <-- direct-declarator", color('reset')
#}
#
#method pointer($/) {
#  say color('yellow'), $/.trim, color('reset'), color('bold'), " <-- pointer", color('reset')
#}
#
#method type-qualifier-list($/) {
#  say color('yellow'), $/.trim, color('reset'), color('bold'), " <-- type-qualifier-list", color('reset')
#}
#
#method parameter-type-list($/) {
#  say color('yellow'), $/.trim, color('reset'), color('bold'), " <-- parameter-type-list", color('reset')
#}
#
#method parameter-list($/) {
#  say color('yellow'), $/.trim, color('reset'), color('bold'), " <-- parameter-list", color('reset')
#}
#
#method parameter-declaration($/) {
#  say color('yellow'), $/.trim, color('reset'), color('bold'), " <-- parameter-declaration", color('reset')
#}
#
#method identifier-list($/) {
#  say color('yellow'), $/.trim, color('reset'), color('bold'), " <-- identifier-list", color('reset')
#}
#
#method initializer($/) {
#  say color('yellow'), $/.trim, color('reset'), color('bold'), " <-- initializer", color('reset')
#}
#
#method initializer-list($/) {
#  say color('yellow'), $/.trim, color('reset'), color('bold'), " <-- initializer-list", color('reset')
#}
#
#method type-name($/) {
#  say color('yellow'), $/.trim, color('reset'), color('bold'), " <-- type-name", color('reset')
#}
#
#method abstract-declarator($/) {
#  say color('yellow'), $/.trim, color('reset'), color('bold'), " <-- abstract-declarator", color('reset')
#}
#
#method direct-abstract-declarator($/) {
#  say color('yellow'), $/.trim, color('reset'), color('bold'), " <-- direct-abstract-declarator", color('reset')
#}
#
#method typedef-name($/) {
#  say color('yellow'), $/.trim, color('reset'), color('bold'), " <-- typedef-name", color('reset')
#}

method statement:sym<labeled>($/) {
  given $<labeled-statement><cmd> {
    when 'case' {
      make C::AST::case-statement.new(
        :match($/),
        :value(~$<labeled-statement><constant-expression>),
        :block($<labeled-statement><statement>.made),
      )
    }
    when 'default' {
      make C::AST::default-statement.new(
        :match($/),
        :block($<labeled-statement><statement>.made),
      )
    }
    default { # label
      make C::AST::label-statement.new(
        :match($/),
        :label(~$<labeled-statement><identifier>),
        :block($<labeled-statement><statement>.made),
      )
    }
  }
}

method statement:sym<compound>($/) {
  make $<compound-statement>.made;
}

method statement:sym<selection>($/) {
  given $<selection-statement><cmd> {
    when 'if' {
      make C::AST::if-statement.new(
        :match($/),
        :condition($<selection-statement><expression>.made),
        :then($<selection-statement><then>.made),
        :else($<selection-statement><else>.made)
      )
    }
    when 'switch' {
      make C::AST::switch-statement.new(
        :match($/),
        :value($<selection-statement><expression>.made),
        :block($<selection-statement><statement>.made)
      )
    }
  }
}

method statement:sym<iteration>($/) {
  given $<iteration-statement><cmd> {
    when 'while' {
      make C::AST::while-statement.new(
        :match($/),
        :condition($<iteration-statement><expression>.made),
        :block($<iteration-statement><statement>.made)
      )
    }
    when 'do' {
      make C::AST::do-statement.new(
        :match($/),
        :condition($<iteration-statement><expression>.made),
        :block($<iteration-statement><statement>.made)
      )
    }
    when 'for' {
      make C::AST::for-statement.new(
        :match($/),
        :init-expr($<iteration-statement><init-expr>.made),
        :condition-expr($<iteration-statement><condition-expr>.made),
        :increment-expr($<iteration-statement><inc-expr>.made),
        :block($<iteration-statement><statement>.made)
      )
    }
  }
}

method statement:sym<jump>($/) {
  given $<jump-statement><cmd> {
    when 'goto' {
      make C::AST::goto-statement.new(
        :match($/), :label(~$<jump-statement><identifier>))
    }
    when 'continue' {
      make C::AST::continue-statement.new(:match($/))
    }
    when 'break' {
      make C::AST::break-statement.new(:match($/))
    }
    when 'return' {
      make C::AST::return-statement.new(:match($/), :value($<jump-statement><expression>.made))
    }
  }
  #say $/.made;
}

method statement:sym<expression>($/) {
  make $<expression-statement>.made;
}

method expression-statement($/) {
  make C::AST::expression-statement.new(
    :match($/),
    :expr($<expression>.made)
  );
}

method compound-statement($/) {
  my @declarations = map { |.made // () }, $<declaration-list><declaration> // ();
  my @statements   = map { |.made // () }, $<statement-list><statement> // ();
  make C::AST::compound-statement.new(
    :match($/),
    :@declarations,
    :@statements
  );
}

method expression($/) {
  if @<assignment-expression>[0] ~~ Array[C::AST::lvalue-assignment] {
    my @assignment-expressions = map { .made // () }, @<assignment-expression>;
    make C::AST::expression.new(
      :match($/),
      :@assignment-expressions
    );
  } else {
    make @<assignment-expression>[0].made
  }
  #say $/.made;
}

method assignment-expression($/) {
  with $<lvalue-assignment-list> {
    make C::AST::assignment-expression.new(
      :match($/),
      :assignment-list($<lvalue-assignment-list>.made),
      :expression($<conditional-expression>.made)
    );
  } else {
    make $<conditional-expression>.made
  }
}

method lvalue-assignment-list($/) {
  my C::AST::lvalue-assignment @assignment-list = map { .made // () },
                                                      @<lvalue-assignment>;
  make @assignment-list;
}

method lvalue-assignment($/) {
  make C::AST::lvalue-assignment.new(
    :match($/),
    :lvalue($<unary-expression>.made),
    :operator(~$<assignment-operator>)
  );
}

method conditional-expression:sym<single>($/) {
  make $<single-conditional-expression>.made;
}

method conditional-expression:sym<ternary>($/) {
  # TODO: make an expression-list or something...
  make ~$/;
}

method single-conditional-expression($/) {
  make $<logical-OR-expression>.made;
}

method ternary-conditional-expression($/) {
  make ~$/;
}

method logical-OR-expression($/) {
  if @<logical-AND-expression>.elems == 1 {
    make @<logical-AND-expression>[0].made
  } else {
    my @list = map { .made // () }, @<logical-AND-expression>;
    make C::AST::expression-list.new(
      :match($/),
      :operands(@list),
      :operators($<op>.elems ?? [ $<op>».Str ] !! '')
    );
  }
}

method logical-AND-expression($/) {
  if @<inclusive-OR-expression>.elems == 1 {
    make @<inclusive-OR-expression>[0].made
  } else {
    my @list = map { .made // () }, @<inclusive-OR-expression>;
    make C::AST::expression-list.new(
      :match($/),
      :operands(@list),
      :operators($<op>.elems ?? [ $<op>».Str ] !! '')
    );
  }
}

method inclusive-OR-expression($/) {
  if @<exclusive-OR-expression>.elems == 1 {
    make @<exclusive-OR-expression>[0].made
  } else {
    my @list = map { .made // () }, @<exclusive-OR-expression>;
    make C::AST::expression-list.new(
      :match($/),
      :operands(@list),
      :operators($<op>.elems ?? [ $<op>».Str ] !! '')
    );
  }
}

method exclusive-OR-expression($/) {
  if @<AND-expression>.elems == 1 {
    make @<AND-expression>[0].made
  } else {
    my @list = map { .made // () }, @<AND-expression>;
    make C::AST::expression-list.new(
      :match($/),
      :operands(@list),
      :operators($<op>.elems ?? [ $<op>».Str ] !! '')
    );
  }
}

method AND-expression($/) {
  if @<equality-expression>.elems == 1 {
    make @<equality-expression>[0].made
  } else {
    my @list = map { .made // () }, @<equality-expression>;
    make C::AST::expression-list.new(
      :match($/),
      :operands(@list),
      :operators($<op>.elems ?? [ $<op>».Str ] !! '')
    );
  }
}

method equality-expression($/) {
  if @<relational-expression>.elems == 1 {
    make @<relational-expression>[0].made
  } else {
    my @list = map { .made // () }, @<relational-expression>;
    make C::AST::expression-list.new(
      :match($/),
      :operands(@list),
      :operators($<op>.elems ?? [ $<op>».Str ] !! '')
    );
  }
}

method relational-expression($/) {
  if @<shift-expression>.elems == 1 {
    make @<shift-expression>[0].made
  } else {
    my @list = map { .made // () }, @<shift-expression>;
    make C::AST::expression-list.new(
      :match($/),
      :operands(@list),
      :operators($<op>.elems ?? [ $<op>».Str ] !! '')
    );
  }
}

method shift-expression($/) {
  if @<additive-expression>.elems == 1 {
    make @<additive-expression>[0].made
  } else {
    my @list = map { .made // () }, @<additive-expression>;
    make C::AST::expression-list.new(
      :match($/),
      :operands(@list),
      :operators($<op>.elems ?? [ $<op>».Str ] !! '')
    );
  }
}

method additive-expression($/) {
  if @<multiplicative-expression>.elems == 1 {
    make @<multiplicative-expression>[0].made
  } else {
    my @list = map { .made // () }, @<multiplicative-expression>;
    make C::AST::expression-list.new(
      :match($/),
      :operands(@list),
      :operators($<op>.elems ?? [ $<op>».Str ] !! '')
    );
  }
}

method multiplicative-expression($/) {
  if @<cast-expression>.elems == 1 {
    make @<cast-expression>[0].made
  } else {
    my @list = map { .made // () }, @<cast-expression>;
    make C::AST::expression-list.new(
      :match($/),
      :operands(@list),
      :operators($<op>.elems ?? [ $<op>».Str ] !! '')
    );
  }
}

method cast-expression($/) {
  if @<cast-operator>.elems {
    make C::AST::cast-expression.new(
      :match($/),
      :cast-operator(@<cast-operator>».made),
      :expression($<unary-expression>.made)
    );
  } else {
    make $<unary-expression>.made
  }
}

method cast-operator($/) {
  make ~$/;
}

method unary-expression:sym<postfix>($/) {
  make $<postfix-expression>.made;
}

method unary-expression:sym<++>($/) {
  make C::AST::prefix-expression.new(
    :match($/),
    :prefix($<prefix>),
    :expression($<unary-expression>.made)
  );
}

method unary-expression:sym<-->($/) {
  make C::AST::prefix-expression.new(
    :match($/),
    :prefix($<prefix>),
    :expression($<unary-expression>.made)
  );
}

method unary-expression:sym<unary-cast>($/) {
  #say $/;
  make C::AST::prefix-expression.new(
    :match($/),
    :prefix($<unary-cast-expression><unary-operator>.made),
    :expression($<unary-cast-expression><cast-expression>.made)
  );
}

method unary-expression:sym<sizeof-expr>($/) {
  make C::AST::prefix-expression.new(
    :match($/),
    :prefix('sizeof'),
    :expression($<unary-expression>.made)
  );
}

method unary-expression:sym<sizeof-type>($/) {
  make C::AST::prefix-expression.new(
    :match($/),
    :prefix('sizeof'),
    :expression($<unary-expression>.made)
  );
}

method unary-operator:sym<&>($/) { make ~$/ }
method unary-operator:sym<*>($/) { make ~$/ }
method unary-operator:sym<+>($/) { make ~$/ }
method unary-operator:sym<->($/) { make ~$/ }
method unary-operator:sym<~>($/) { make ~$/ }
method unary-operator:sym<!>($/) { make ~$/ }

method postfix-expression($/) {
  if $<postfix-expression-rest> {
    make C::AST::postfix-expression.new(
      :match($/),
      :expression($<postfix-expression-first>.made)
      :postfix($<postfix-expression-rest>>>.made)
    );
  } else {
    make $<postfix-expression-first>.made
  }
}

method postfix-expression-first:sym<primary>($/) {
  make $<primary-expression>.made;
}

method postfix-expression-rest:sym<[ ]>($/) {
  make ~$/;
}

method postfix-expression-rest:sym<( )>($/) {
  make ~$/;
}
method postfix-expression-rest:sym<.>($/) {
  make ~$/;
}

method postfix-expression-rest:sym«->»($/) {
  make ~$/;
}

method postfix-expression-rest:sym<++>($/) {
  make ~$/;
}

method postfix-expression-rest:sym<-->($/) {
  make ~$/;
}

method primary-expression($/) {
  #say $<constant>.made with $<constant>;
  make $<expression>.made // $<identifier>.made // $<constant>.made;
}

method constant:sym<float>($/) {
  make C::AST::constant.new(
    :match($/),
    :value(~$/)
  );
}

method constant:sym<integer>($/) {
  make C::AST::constant.new(
    :match($/),
    :value(~$/)
  );
}

method constant:sym<char>($/) {
  make C::AST::constant.new(
    :match($/),
    :value(~$/)
  );
}

method constant:sym<enum>($/) {
  make C::AST::constant.new(
    :match($/),
    :value(~$/)
  );
}

method constant:sym<string>($/) {
  make C::AST::constant.new(
    :match($/),
    :value($<string><single-string>».made.join.fmt('"%s"'))
  );
}

method single-string($/) {
  make $/.substr(1, *-1);
}

method identifier($/) {
  make C::AST::identifier.new(
    :match($/),
    :name(~$/)
  );
}

