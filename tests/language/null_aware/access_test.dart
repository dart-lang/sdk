// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify semantics of the ?. operator when it does not appear on the LHS of an
// assignment.

import "package:expect/expect.dart";
import "conditional_access_helper.dart" as h;

class B {}

class C extends B {
  int? v;
  C(this.v);
  static int? staticInt;
}

C? nullC() => null;

main() {
  // Make sure the "none" test fails if property access using "?." is not
  // implemented.  This makes status files easier to maintain.
  nullC()?.v;

  // e1?.id is equivalent to ((x) => x == null ? null : x.id)(e1).
  Expect.equals(null, nullC()?.v);
  Expect.equals(1, new C(1)?.v);
  //                   ^
  // [cfe] Operand of null-aware operation '?.' has type 'C' which excludes null.
  //                       ^^
  // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR

  // C?.id is equivalent to C.id.
  {
    C.staticInt = 1;
    Expect.equals(1, C?.staticInt);
    //               ^
    // [cfe] The class 'C' cannot be null.
  }
  {
    h.C.staticInt = 1;
    Expect.equals(1, h.C?.staticInt);
    //                 ^
    // [cfe] The class 'C' cannot be null.
  }

  // The static type of e1?.d is the static type of e1.id.
  {
    int? i = new C(1)?.v;
    //           ^
    // [cfe] Operand of null-aware operation '?.' has type 'C' which excludes null.
    //               ^^
    // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
    Expect.equals(1, i);
  }
  {
    String? s = new C(null)?.v;
    //          ^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    //              ^
    // [cfe] A value of type 'int?' can't be assigned to a variable of type 'String?'.
    //              ^
    // [cfe] Operand of null-aware operation '?.' has type 'C' which excludes null.
    //                     ^^
    // [analyzer] STATIC_WARNING.INVALID_NULL_AWARE_OPERATOR
    Expect.equals(null, s);
  }
  {
    C.staticInt = 1;
    int? i = C?.staticInt;
    //       ^
    // [cfe] The class 'C' cannot be null.
    Expect.equals(1, i);
  }
  {
    h.C.staticInt = 1;
    int? i = h.C?.staticInt;
    //         ^
    // [cfe] The class 'C' cannot be null.
    Expect.equals(1, i);
  }
  {
    C.staticInt = null;
    String? s = C?.staticInt;
    //          ^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    // [cfe] The class 'C' cannot be null.
    //             ^
    // [cfe] A value of type 'int?' can't be assigned to a variable of type 'String?'.
    Expect.equals(null, s);
  }
  {
    h.C.staticNullable = null;
    String? s = h.C?.staticNullable;
    //          ^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    //            ^
    // [cfe] The class 'C' cannot be null.
    //               ^
    // [cfe] A value of type 'int?' can't be assigned to a variable of type 'String?'.
    Expect.equals(null, s);
  }

  // Let T be the static type of e1 and let y be a fresh variable of type T.
  // Exactly the same static warnings that would be caused by y.id are also
  // generated in the case of e1?.id.
  Expect.equals(null, nullC()?.bad);
  //                           ^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'bad' isn't defined for the class 'C'.
  {
    var b = new C(1) as B?;
    Expect.equals(1, b?.v);
    //                  ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'v' isn't defined for the class 'B'.
  }

  // '?.' cannot be used to access toplevel properties in libraries imported via
  // prefix.
  var x = h?.topLevelVar;
  //      ^
  // [analyzer] COMPILE_TIME_ERROR.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT
  // [cfe] A prefix can't be used with null-aware operators.

  // Nor can it be used to access the hashCode getter on the class Type.
  Expect.throwsNoSuchMethodError(() => C?.hashCode);
  //                                      ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] Getter not found: 'hashCode'.
  Expect.throwsNoSuchMethodError(() => h.C?.hashCode);
  //                                        ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] Getter not found: 'hashCode'.
}
