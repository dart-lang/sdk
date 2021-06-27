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
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #foo.void;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  // ----- All other reserved words are disallowed.

  #assert;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #break;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #case;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #catch;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #class;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #const;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #continue;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #default;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #do;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #else;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #enum;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #extends;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #false;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #final;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #finally;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #for;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #if;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #in;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #is;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #new;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #null;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #rethrow;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #return;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #super;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #switch;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #this;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #throw;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #true;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #try;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #var;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #while;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #with;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  // ----- Reserved words also disallowed in dot-separated multi-part symbol.

  #foo.assert;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #foo.break;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #foo.case;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #foo.catch;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #foo.class;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #foo.const;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #foo.continue;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #foo.default;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #foo.do;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #foo.else;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #foo.enum;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #foo.extends;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #foo.false;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #foo.final;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #foo.finally;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #foo.for;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #foo.if;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #foo.in;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #foo.is;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #foo.new;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #foo.null;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #foo.rethrow;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #foo.return;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #foo.super;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #foo.switch;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #foo.this;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #foo.throw;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #foo.true;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #foo.try;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #foo.var;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #foo.while;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #foo.with;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #assert.foo;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #break.foo;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #case.foo;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #catch.foo;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #class.foo;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #const.foo;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #continue.foo;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #default.foo;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #do.foo;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #else.foo;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #enum.foo;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #extends.foo;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #false.foo;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #final.foo;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #finally.foo;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #for.foo;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #if.foo;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #in.foo;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #is.foo;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #new.foo;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #null.foo;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #rethrow.foo;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #return.foo;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #super.foo;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #switch.foo;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #this.foo;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #throw.foo;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #true.foo;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #try.foo;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #var.foo;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #while.foo;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified

  #with.foo;
  //^
  // [analyzer] unspecified
  // [cfe] unspecified
}
