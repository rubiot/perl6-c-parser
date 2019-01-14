use v6;
unit module C::Parser::Utils;

our sub extractFunctionId($/)
{
  ~$<declarator><direct-declarator><identifier>
}

our sub extractFunctionParameters($/)
{
  $<declarator><direct-declarator><parameter-type-list><parameter-list>\
    <parameter-declaration>.join(', ')
}

our sub extractFunctionReturnType($/)
{
  my @type;

  for $<declaration-type-specifiers><declaration-type-specifier> -> $t {
    next if $t<storage-class-specifier>;
    push @type, $t<type-only-specifier> // $t<type-qualifier>
  }

  @type.join(" ").trim || ('<void>' but False);
}

our sub extractDeclarationId($/)
{
  ~$<declarator><direct-declarator><identifier>;
}

our sub cleanCode($c is copy)
{
  $c = ~$c;
  $c ~~ s:g/ '/*' ~ '*/' .*? //;
  $c ~~ s:g/ '//' \N* //;
  $c ~~ s:g/[\s|\v]+/ /;
  $c.trim;
}
