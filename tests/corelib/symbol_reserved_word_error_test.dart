// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  // ----- 'void' is allowed as a symbol name.

  #void;
  const Symbol('void');
  new Symbol('void');

  // ----- 'void' is not allowed in a dot-separated multi-part symbol literal.

  #void.foo;
  //    ^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'foo' isn't defined for the class 'Symbol'.

  #foo.void;
  //   ^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'void' can't be used as an identifier because it's a keyword.

  // ----- All other reserved words are disallowed.

  #assert;
  // [error column 4, length 6]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'assert' can't be used as an identifier because it's a keyword.

  #break;
  // [error column 4, length 5]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'break' can't be used as an identifier because it's a keyword.

  #case;
  // [error column 4, length 4]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'case' can't be used as an identifier because it's a keyword.

  #catch;
  // [error column 4, length 5]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'catch' can't be used as an identifier because it's a keyword.

  #class;
  // [error column 4, length 5]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'class' can't be used as an identifier because it's a keyword.

  #const;
  // [error column 4, length 5]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'const' can't be used as an identifier because it's a keyword.

  #continue;
  // [error column 4, length 8]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'continue' can't be used as an identifier because it's a keyword.

  #default;
  // [error column 4, length 7]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'default' can't be used as an identifier because it's a keyword.

  #do;
  // [error column 4, length 2]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'do' can't be used as an identifier because it's a keyword.

  #else;
  // [error column 4, length 4]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'else' can't be used as an identifier because it's a keyword.

  #enum;
  // [error column 4, length 4]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'enum' can't be used as an identifier because it's a keyword.

  #extends;
  // [error column 4, length 7]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'extends' can't be used as an identifier because it's a keyword.

  #false;
  // [error column 4, length 5]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'false' can't be used as an identifier because it's a keyword.

  #final;
  // [error column 4, length 5]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'final' can't be used as an identifier because it's a keyword.

  #finally;
  // [error column 4, length 7]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'finally' can't be used as an identifier because it's a keyword.

  #for;
  // [error column 4, length 3]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'for' can't be used as an identifier because it's a keyword.

  #if;
  // [error column 4, length 2]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'if' can't be used as an identifier because it's a keyword.

  #in;
  // [error column 4, length 2]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'in' can't be used as an identifier because it's a keyword.

  #is;
  // [error column 4, length 2]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'is' can't be used as an identifier because it's a keyword.

  #new;
  // [error column 4, length 3]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'new' can't be used as an identifier because it's a keyword.

  #null;
  // [error column 4, length 4]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'null' can't be used as an identifier because it's a keyword.

  #rethrow;
  // [error column 4, length 7]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'rethrow' can't be used as an identifier because it's a keyword.

  #return;
  // [error column 4, length 6]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'return' can't be used as an identifier because it's a keyword.

  #super;
  // [error column 4, length 5]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'super' can't be used as an identifier because it's a keyword.

  #switch;
  // [error column 4, length 6]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'switch' can't be used as an identifier because it's a keyword.

  #this;
  // [error column 4, length 4]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'this' can't be used as an identifier because it's a keyword.

  #throw;
  // [error column 4, length 5]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'throw' can't be used as an identifier because it's a keyword.

  #true;
  // [error column 4, length 4]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'true' can't be used as an identifier because it's a keyword.

  #try;
  // [error column 4, length 3]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'try' can't be used as an identifier because it's a keyword.

  #var;
  // [error column 4, length 3]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'var' can't be used as an identifier because it's a keyword.

  #while;
  // [error column 4, length 5]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'while' can't be used as an identifier because it's a keyword.

  #with;
  // [error column 4, length 4]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'with' can't be used as an identifier because it's a keyword.

  // ----- Reserved words also disallowed in dot-separated multi-part symbol.

  #foo.assert;
  //   ^^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'assert' can't be used as an identifier because it's a keyword.

  #foo.break;
  //   ^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'break' can't be used as an identifier because it's a keyword.

  #foo.case;
  //   ^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'case' can't be used as an identifier because it's a keyword.

  #foo.catch;
  //   ^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'catch' can't be used as an identifier because it's a keyword.

  #foo.class;
  //   ^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'class' can't be used as an identifier because it's a keyword.

  #foo.const;
  //   ^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'const' can't be used as an identifier because it's a keyword.

  #foo.continue;
  //   ^^^^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'continue' can't be used as an identifier because it's a keyword.

  #foo.default;
  //   ^^^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'default' can't be used as an identifier because it's a keyword.

  #foo.do;
  //   ^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'do' can't be used as an identifier because it's a keyword.

  #foo.else;
  //   ^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'else' can't be used as an identifier because it's a keyword.

  #foo.enum;
  //   ^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'enum' can't be used as an identifier because it's a keyword.

  #foo.extends;
  //   ^^^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'extends' can't be used as an identifier because it's a keyword.

  #foo.false;
  //   ^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'false' can't be used as an identifier because it's a keyword.

  #foo.final;
  //   ^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'final' can't be used as an identifier because it's a keyword.

  #foo.finally;
  //   ^^^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'finally' can't be used as an identifier because it's a keyword.

  #foo.for;
  //   ^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'for' can't be used as an identifier because it's a keyword.

  #foo.if;
  //   ^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'if' can't be used as an identifier because it's a keyword.

  #foo.in;
  //   ^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'in' can't be used as an identifier because it's a keyword.

  #foo.is;
  //   ^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'is' can't be used as an identifier because it's a keyword.

  #foo.new;
  //   ^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'new' can't be used as an identifier because it's a keyword.

  #foo.null;
  //   ^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'null' can't be used as an identifier because it's a keyword.

  #foo.rethrow;
  //   ^^^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'rethrow' can't be used as an identifier because it's a keyword.

  #foo.return;
  //   ^^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'return' can't be used as an identifier because it's a keyword.

  #foo.super;
  //   ^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'super' can't be used as an identifier because it's a keyword.

  #foo.switch;
  //   ^^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'switch' can't be used as an identifier because it's a keyword.

  #foo.this;
  //   ^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'this' can't be used as an identifier because it's a keyword.

  #foo.throw;
  //   ^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'throw' can't be used as an identifier because it's a keyword.

  #foo.true;
  //   ^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'true' can't be used as an identifier because it's a keyword.

  #foo.try;
  //   ^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'try' can't be used as an identifier because it's a keyword.

  #foo.var;
  //   ^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'var' can't be used as an identifier because it's a keyword.

  #foo.while;
  //   ^^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'while' can't be used as an identifier because it's a keyword.

  #foo.with;
  //   ^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'with' can't be used as an identifier because it's a keyword.

  #assert.foo;
  // [error column 4, length 6]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'assert' can't be used as an identifier because it's a keyword.

  #break.foo;
  // [error column 4, length 5]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'break' can't be used as an identifier because it's a keyword.

  #case.foo;
  // [error column 4, length 4]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'case' can't be used as an identifier because it's a keyword.

  #catch.foo;
  // [error column 4, length 5]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'catch' can't be used as an identifier because it's a keyword.

  #class.foo;
  // [error column 4, length 5]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'class' can't be used as an identifier because it's a keyword.

  #const.foo;
  // [error column 4, length 5]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'const' can't be used as an identifier because it's a keyword.

  #continue.foo;
  // [error column 4, length 8]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'continue' can't be used as an identifier because it's a keyword.

  #default.foo;
  // [error column 4, length 7]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'default' can't be used as an identifier because it's a keyword.

  #do.foo;
  // [error column 4, length 2]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'do' can't be used as an identifier because it's a keyword.

  #else.foo;
  // [error column 4, length 4]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'else' can't be used as an identifier because it's a keyword.

  #enum.foo;
  // [error column 4, length 4]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'enum' can't be used as an identifier because it's a keyword.

  #extends.foo;
  // [error column 4, length 7]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'extends' can't be used as an identifier because it's a keyword.

  #false.foo;
  // [error column 4, length 5]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'false' can't be used as an identifier because it's a keyword.

  #final.foo;
  // [error column 4, length 5]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'final' can't be used as an identifier because it's a keyword.

  #finally.foo;
  // [error column 4, length 7]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'finally' can't be used as an identifier because it's a keyword.

  #for.foo;
  // [error column 4, length 3]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'for' can't be used as an identifier because it's a keyword.

  #if.foo;
  // [error column 4, length 2]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'if' can't be used as an identifier because it's a keyword.

  #in.foo;
  // [error column 4, length 2]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'in' can't be used as an identifier because it's a keyword.

  #is.foo;
  // [error column 4, length 2]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'is' can't be used as an identifier because it's a keyword.

  #new.foo;
  // [error column 4, length 3]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'new' can't be used as an identifier because it's a keyword.

  #null.foo;
  // [error column 4, length 4]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'null' can't be used as an identifier because it's a keyword.

  #rethrow.foo;
  // [error column 4, length 7]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'rethrow' can't be used as an identifier because it's a keyword.

  #return.foo;
  // [error column 4, length 6]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'return' can't be used as an identifier because it's a keyword.

  #super.foo;
  // [error column 4, length 5]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'super' can't be used as an identifier because it's a keyword.

  #switch.foo;
  // [error column 4, length 6]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'switch' can't be used as an identifier because it's a keyword.

  #this.foo;
  // [error column 4, length 4]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'this' can't be used as an identifier because it's a keyword.

  #throw.foo;
  // [error column 4, length 5]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'throw' can't be used as an identifier because it's a keyword.

  #true.foo;
  // [error column 4, length 4]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'true' can't be used as an identifier because it's a keyword.

  #try.foo;
  // [error column 4, length 3]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'try' can't be used as an identifier because it's a keyword.

  #var.foo;
  // [error column 4, length 3]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'var' can't be used as an identifier because it's a keyword.

  #while.foo;
  // [error column 4, length 5]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'while' can't be used as an identifier because it's a keyword.

  #with.foo;
  // [error column 4, length 4]
  // [analyzer] SYNTACTIC_ERROR.EXPECTED_IDENTIFIER_BUT_GOT_KEYWORD
  // [cfe] 'with' can't be used as an identifier because it's a keyword.
}
