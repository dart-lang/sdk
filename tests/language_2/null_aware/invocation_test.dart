// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify semantics of the ?. operator when it is used to invoke a method.

import "package:expect/expect.dart";
import "conditional_access_helper.dart" as h;

bad() {
  Expect.fail('Should not be executed');
}

class B {}

class C extends B {
  f(callback()) => callback();
  int g(int callback()) => callback();
  static staticF(callback()) => callback();
  static int staticG(int callback()) => callback();
}

C nullC() => null;

main() {
  // Make sure the "none" test fails if method invocation using "?." is not
  // implemented.  This makes status files easier to maintain.
  nullC()?.f(null);

  // o?.m(...) is equivalent to ((x) => x == null ? null : x.m(...))(o).
  Expect.equals(null, nullC()?.f(bad()));
  Expect.equals(1, new C()?.f(() => 1));

  // C?.m(...) is equivalent to C.m(...).
  Expect.equals(1, C?.staticF(() => 1));
  Expect.equals(1, h.C?.staticF(() => 1));

  // The static type of o?.m(...) is the same as the static type of
  // o.m(...).
  { int i = nullC()?.g(bad()); Expect.equals(null, i); }
  { int i = new C()?.g(() => 1); Expect.equals(1, i); }
  { String s = nullC()?.g(bad()); Expect.equals(null, s); }
  //           ^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'int' can't be assigned to a variable of type 'String'.
  { String s = new C()?.g(() => null); Expect.equals(null, s); }
  //           ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //               ^
  // [cfe] A value of type 'int' can't be assigned to a variable of type 'String'.
  { int i = C?.staticG(() => 1); Expect.equals(1, i); }
  { int i = h.C?.staticG(() => 1); Expect.equals(1, i); }
  { String s = C?.staticG(() => null); Expect.equals(null, s); }
  //           ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //              ^
  // [cfe] A value of type 'int' can't be assigned to a variable of type 'String'.
  { String s = h.C?.staticG(() => null); Expect.equals(null, s); }
  //           ^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //                ^
  // [cfe] A value of type 'int' can't be assigned to a variable of type 'String'.

  // Let T be the static type of o and let y be a fresh variable of type T.
  // Exactly the same static warnings that would be caused by y.m(...) are also
  // generated in the case of o?.m(...).
  { B b = new C(); Expect.equals(1, b?.f(() => 1)); }
  //                                   ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
  // [cfe] The method 'f' isn't defined for the class 'B'.
  { int i = 1; Expect.equals(null, nullC()?.f(i)); }
  //                                          ^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'int' can't be assigned to the parameter type 'dynamic Function()'.

  // '?.' can't be used to access toplevel functions in libraries imported via
  // prefix.
  h?.topLevelFunction();
//^
// [analyzer] COMPILE_TIME_ERROR.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT
// [cfe] A prefix can't be used with null-aware operators.

  // Nor can it be used to access the toString method on the class Type.
  Expect.throwsNoSuchMethodError(() => C?.toString());
  //                                      ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
  // [cfe] Method not found: 'C.toString'.
  Expect.throwsNoSuchMethodError(() => h.C?.toString());
  //                                        ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
  // [cfe] Method not found: 'C.toString'.
}
