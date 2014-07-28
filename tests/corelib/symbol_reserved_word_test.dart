// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

void checkBadSymbol(String s) {
  Expect.throws(() => new Symbol(s), (e) => e is ArgumentError);
}

main() {
  var x;

  // 'void' is allowed as a symbol name.
  x = const Symbol('void');     /// 01: ok
  x = #void;                    /// 02: ok
  x = new Symbol('void');       /// 03: ok

  // However, it is not allowed as a part of a symbol name.
  x = const Symbol('void.foo'); /// 04: compile-time error
  x = #void.foo;                /// 05: compile-time error
  checkBadSymbol('void.foo');   /// 06: ok
  x = const Symbol('foo.void'); /// 07: compile-time error
  x = #foo.void;                /// 08: compile-time error
  checkBadSymbol('foo.void');   /// 09: ok

  // All other reserved words are disallowed.
  x = const Symbol('assert');   /// 10: compile-time error
  x = const Symbol('break');    /// 10: continued
  x = const Symbol('case');     /// 10: continued
  x = const Symbol('catch');    /// 10: continued
  x = const Symbol('class');    /// 10: continued
  x = const Symbol('const');    /// 10: continued
  x = const Symbol('continue'); /// 10: continued
  x = const Symbol('default');  /// 10: continued
  x = const Symbol('do');       /// 10: continued
  x = const Symbol('else');     /// 10: continued
  x = const Symbol('enum');     /// 10: continued
  x = const Symbol('extends');  /// 10: continued
  x = const Symbol('false');    /// 10: continued
  x = const Symbol('final');    /// 10: continued
  x = const Symbol('finally');  /// 10: continued
  x = const Symbol('for');      /// 10: continued
  x = const Symbol('if');       /// 10: continued
  x = const Symbol('in');       /// 10: continued
  x = const Symbol('is');       /// 10: continued
  x = const Symbol('new');      /// 10: continued
  x = const Symbol('null');     /// 10: continued
  x = const Symbol('rethrow');  /// 10: continued
  x = const Symbol('return');   /// 10: continued
  x = const Symbol('super');    /// 10: continued
  x = const Symbol('switch');   /// 10: continued
  x = const Symbol('this');     /// 10: continued
  x = const Symbol('throw');    /// 10: continued
  x = const Symbol('true');     /// 10: continued
  x = const Symbol('try');      /// 10: continued
  x = const Symbol('var');      /// 10: continued
  x = const Symbol('while');    /// 10: continued
  x = const Symbol('with');     /// 10: continued
  x = #assert;                  /// 11: compile-time error
  x = #break;                   /// 11: continued
  x = #case;                    /// 11: continued
  x = #catch;                   /// 11: continued
  x = #class;                   /// 11: continued
  x = #const;                   /// 11: continued
  x = #continue;                /// 11: continued
  x = #default;                 /// 11: continued
  x = #do;                      /// 11: continued
  x = #else;                    /// 11: continued
  x = #enum;                    /// 11: continued
  x = #extends;                 /// 11: continued
  x = #false;                   /// 11: continued
  x = #final;                   /// 11: continued
  x = #finally;                 /// 11: continued
  x = #for;                     /// 11: continued
  x = #if;                      /// 11: continued
  x = #in;                      /// 11: continued
  x = #is;                      /// 11: continued
  x = #new;                     /// 11: continued
  x = #null;                    /// 11: continued
  x = #rethrow;                 /// 11: continued
  x = #return;                  /// 11: continued
  x = #super;                   /// 11: continued
  x = #switch;                  /// 11: continued
  x = #this;                    /// 11: continued
  x = #throw;                   /// 11: continued
  x = #true;                    /// 11: continued
  x = #try;                     /// 11: continued
  x = #var;                     /// 11: continued
  x = #while;                   /// 11: continued
  x = #with;                    /// 11: continued
  checkBadSymbol('assert');     /// 12: ok
  checkBadSymbol('break');      /// 12: continued
  checkBadSymbol('case');       /// 12: continued
  checkBadSymbol('catch');      /// 12: continued
  checkBadSymbol('class');      /// 12: continued
  checkBadSymbol('const');      /// 12: continued
  checkBadSymbol('continue');   /// 12: continued
  checkBadSymbol('default');    /// 12: continued
  checkBadSymbol('do');         /// 12: continued
  checkBadSymbol('else');       /// 12: continued
  checkBadSymbol('enum');       /// 12: continued
  checkBadSymbol('extends');    /// 12: continued
  checkBadSymbol('false');      /// 12: continued
  checkBadSymbol('final');      /// 12: continued
  checkBadSymbol('finally');    /// 12: continued
  checkBadSymbol('for');        /// 12: continued
  checkBadSymbol('if');         /// 12: continued
  checkBadSymbol('in');         /// 12: continued
  checkBadSymbol('is');         /// 12: continued
  checkBadSymbol('new');        /// 12: continued
  checkBadSymbol('null');       /// 12: continued
  checkBadSymbol('rethrow');    /// 12: continued
  checkBadSymbol('return');     /// 12: continued
  checkBadSymbol('super');      /// 12: continued
  checkBadSymbol('switch');     /// 12: continued
  checkBadSymbol('this');       /// 12: continued
  checkBadSymbol('throw');      /// 12: continued
  checkBadSymbol('true');       /// 12: continued
  checkBadSymbol('try');        /// 12: continued
  checkBadSymbol('var');        /// 12: continued
  checkBadSymbol('while');      /// 12: continued
  checkBadSymbol('with');       /// 12: continued
}
