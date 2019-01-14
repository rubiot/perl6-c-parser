use v6;
#use lib './lib';
use C::Parser::Actions;
use C::Parser::Grammar;

unit class C::Parser;

method parse($line) {
  C::Parser::Grammar.parse($line, :actions(C::Parser::Actions.new));
}

method parsefile($file) {
  C::Parser::Grammar.parsefile($file, :actions(C::Parser::Actions.new));
}
