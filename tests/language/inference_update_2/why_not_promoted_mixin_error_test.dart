// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that when a non-promotable field or getter is declared in a mixin
// and then included in a class (via a `with` clause), the appropriate "why not
// promoted" context message is generated.

// This test exercises both syntactic forms of creating mixin applications
// (`class C = B with M;` and `class C extends B with M {}`), since these are
// represented differently in the analyzer.

// This test exercises both the scenario in which the mixin declaration precedes
// the application, and the scenario in which it follows it. This ensures that
// the order in which the mixin declaration and application are analyzed does
// not influence the behavior.

// SharedOptions=--enable-experiment=inference-update-2

class C1 = Object with M;

class C2 extends Object with M {}

mixin M {
  int? get _notField => 0;
  //       ^^^^^^^^^
  // [context 1] '_notField' refers to a getter so it couldn't be promoted.  See http://dart.dev/go/non-promo-non-field
  // [context 7] '_notField' refers to a getter so it couldn't be promoted.  See http://dart.dev/go/non-promo-non-field
  // [context 13] '_notField' refers to a getter so it couldn't be promoted.  See http://dart.dev/go/non-promo-non-field
  // [context 19] '_notField' refers to a getter so it couldn't be promoted.  See http://dart.dev/go/non-promo-non-field
  // [context 25] '_notField' refers to a getter so it couldn't be promoted.
  // [context 31] '_notField' refers to a getter so it couldn't be promoted.
  // [context 37] '_notField' refers to a getter so it couldn't be promoted.
  // [context 43] '_notField' refers to a getter so it couldn't be promoted.
  final int? notPrivate = 0;
  //         ^^^^^^^^^^
  // [context 2] 'notPrivate' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 8] 'notPrivate' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 14] 'notPrivate' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 20] 'notPrivate' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 26] 'notPrivate' refers to a public field so it couldn't be promoted.
  // [context 32] 'notPrivate' refers to a public field so it couldn't be promoted.
  // [context 38] 'notPrivate' refers to a public field so it couldn't be promoted.
  // [context 44] 'notPrivate' refers to a public field so it couldn't be promoted.
  int? _notFinal = 0;
  //   ^^^^^^^^^
  // [context 3] '_notFinal' refers to a non-final field so it couldn't be promoted.  See http://dart.dev/go/non-promo-non-final-field
  // [context 9] '_notFinal' refers to a non-final field so it couldn't be promoted.  See http://dart.dev/go/non-promo-non-final-field
  // [context 15] '_notFinal' refers to a non-final field so it couldn't be promoted.  See http://dart.dev/go/non-promo-non-final-field
  // [context 21] '_notFinal' refers to a non-final field so it couldn't be promoted.  See http://dart.dev/go/non-promo-non-final-field
  // [context 27] '_notFinal' refers to a non-final field so it couldn't be promoted.
  // [context 33] '_notFinal' refers to a non-final field so it couldn't be promoted.
  // [context 39] '_notFinal' refers to a non-final field so it couldn't be promoted.
  // [context 45] '_notFinal' refers to a non-final field so it couldn't be promoted.
  final int? _conflictingGetter = 0;
  final int? _conflictingField = 0;
  final int? _conflictingNsmForwarder = 0;
}

class C3 = Object with M;

class C4 extends Object with M {}

class C5 {
  int? get _conflictingGetter => 0;
  //       ^^^^^^^^^^^^^^^^^^
  // [context 4] '_conflictingGetter' couldn't be promoted because there is a conflicting getter in class 'C5'.  See http://dart.dev/go/non-promo-conflicting-getter
  // [context 10] '_conflictingGetter' couldn't be promoted because there is a conflicting getter in class 'C5'.  See http://dart.dev/go/non-promo-conflicting-getter
  // [context 16] '_conflictingGetter' couldn't be promoted because there is a conflicting getter in class 'C5'.  See http://dart.dev/go/non-promo-conflicting-getter
  // [context 22] '_conflictingGetter' couldn't be promoted because there is a conflicting getter in class 'C5'.  See http://dart.dev/go/non-promo-conflicting-getter
  // [context 28] '_conflictingGetter' couldn't be promoted because there is a conflicting getter in class 'C5'.
  // [context 34] '_conflictingGetter' couldn't be promoted because there is a conflicting getter in class 'C5'.
  // [context 40] '_conflictingGetter' couldn't be promoted because there is a conflicting getter in class 'C5'.
  // [context 46] '_conflictingGetter' couldn't be promoted because there is a conflicting getter in class 'C5'.
  int? _conflictingField = 0;
  //   ^^^^^^^^^^^^^^^^^
  // [context 5] '_conflictingField' couldn't be promoted because there is a conflicting non-promotable field in class 'C5'.  See http://dart.dev/go/non-promo-conflicting-non-promotable-field
  // [context 11] '_conflictingField' couldn't be promoted because there is a conflicting non-promotable field in class 'C5'.  See http://dart.dev/go/non-promo-conflicting-non-promotable-field
  // [context 17] '_conflictingField' couldn't be promoted because there is a conflicting non-promotable field in class 'C5'.  See http://dart.dev/go/non-promo-conflicting-non-promotable-field
  // [context 23] '_conflictingField' couldn't be promoted because there is a conflicting non-promotable field in class 'C5'.  See http://dart.dev/go/non-promo-conflicting-non-promotable-field
  // [context 29] '_conflictingField' couldn't be promoted because there is a conflicting non-promotable field in class 'C5'.
  // [context 35] '_conflictingField' couldn't be promoted because there is a conflicting non-promotable field in class 'C5'.
  // [context 41] '_conflictingField' couldn't be promoted because there is a conflicting non-promotable field in class 'C5'.
  // [context 47] '_conflictingField' couldn't be promoted because there is a conflicting non-promotable field in class 'C5'.
}

class C6 {
  final int? _conflictingNsmForwarder = 0;
}

class C7 implements C6 {
//    ^^
// [context 6] '_conflictingNsmForwarder' couldn't be promoted because there is a conflicting noSuchMethod forwarder in class 'C7'.  See http://dart.dev/go/non-promo-conflicting-noSuchMethod-forwarder
// [context 12] '_conflictingNsmForwarder' couldn't be promoted because there is a conflicting noSuchMethod forwarder in class 'C7'.  See http://dart.dev/go/non-promo-conflicting-noSuchMethod-forwarder
// [context 18] '_conflictingNsmForwarder' couldn't be promoted because there is a conflicting noSuchMethod forwarder in class 'C7'.  See http://dart.dev/go/non-promo-conflicting-noSuchMethod-forwarder
// [context 24] '_conflictingNsmForwarder' couldn't be promoted because there is a conflicting noSuchMethod forwarder in class 'C7'.  See http://dart.dev/go/non-promo-conflicting-noSuchMethod-forwarder
// [context 30] '_conflictingNsmForwarder' couldn't be promoted because there is a conflicting noSuchMethod forwarder in class 'C7'.
// [context 36] '_conflictingNsmForwarder' couldn't be promoted because there is a conflicting noSuchMethod forwarder in class 'C7'.
// [context 42] '_conflictingNsmForwarder' couldn't be promoted because there is a conflicting noSuchMethod forwarder in class 'C7'.
// [context 48] '_conflictingNsmForwarder' couldn't be promoted because there is a conflicting noSuchMethod forwarder in class 'C7'.
  noSuchMethod(invocation) => 0;
}

void test1(C1 c) {
  if (c._notField != null) {
    c._notField.isEven;
    //          ^^^^^^
    // [analyzer 1] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 25] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
  if (c.notPrivate != null) {
    c.notPrivate.isEven;
    //           ^^^^^^
    // [analyzer 2] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 26] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
  if (c._notFinal != null) {
    c._notFinal.isEven;
    //          ^^^^^^
    // [analyzer 3] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 27] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
  if (c._conflictingGetter != null) {
    c._conflictingGetter.isEven;
    //                   ^^^^^^
    // [analyzer 4] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 28] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
  if (c._conflictingField != null) {
    c._conflictingField.isEven;
    //                  ^^^^^^
    // [analyzer 5] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 29] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
  if (c._conflictingNsmForwarder != null) {
    c._conflictingNsmForwarder.isEven;
    //                         ^^^^^^
    // [analyzer 6] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 30] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
}

void test2(C2 c) {
  if (c._notField != null) {
    c._notField.isEven;
    //          ^^^^^^
    // [analyzer 7] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 31] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
  if (c.notPrivate != null) {
    c.notPrivate.isEven;
    //           ^^^^^^
    // [analyzer 8] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 32] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
  if (c._notFinal != null) {
    c._notFinal.isEven;
    //          ^^^^^^
    // [analyzer 9] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 33] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
  if (c._conflictingGetter != null) {
    c._conflictingGetter.isEven;
    //                   ^^^^^^
    // [analyzer 10] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 34] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
  if (c._conflictingField != null) {
    c._conflictingField.isEven;
    //                  ^^^^^^
    // [analyzer 11] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 35] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
  if (c._conflictingNsmForwarder != null) {
    c._conflictingNsmForwarder.isEven;
    //                         ^^^^^^
    // [analyzer 12] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 36] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
}

void test3(C3 c) {
  if (c._notField != null) {
    c._notField.isEven;
    //          ^^^^^^
    // [analyzer 13] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 37] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
  if (c.notPrivate != null) {
    c.notPrivate.isEven;
    //           ^^^^^^
    // [analyzer 14] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 38] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
  if (c._notFinal != null) {
    c._notFinal.isEven;
    //          ^^^^^^
    // [analyzer 15] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 39] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
  if (c._conflictingGetter != null) {
    c._conflictingGetter.isEven;
    //                   ^^^^^^
    // [analyzer 16] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 40] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
  if (c._conflictingField != null) {
    c._conflictingField.isEven;
    //                  ^^^^^^
    // [analyzer 17] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 41] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
  if (c._conflictingNsmForwarder != null) {
    c._conflictingNsmForwarder.isEven;
    //                         ^^^^^^
    // [analyzer 18] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 42] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
}

void test4(C4 c) {
  if (c._notField != null) {
    c._notField.isEven;
    //          ^^^^^^
    // [analyzer 19] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 43] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
  if (c.notPrivate != null) {
    c.notPrivate.isEven;
    //           ^^^^^^
    // [analyzer 20] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 44] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
  if (c._notFinal != null) {
    c._notFinal.isEven;
    //          ^^^^^^
    // [analyzer 21] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 45] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
  if (c._conflictingGetter != null) {
    c._conflictingGetter.isEven;
    //                   ^^^^^^
    // [analyzer 22] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 46] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
  if (c._conflictingField != null) {
    c._conflictingField.isEven;
    //                  ^^^^^^
    // [analyzer 23] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 47] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
  if (c._conflictingNsmForwarder != null) {
    c._conflictingNsmForwarder.isEven;
    //                         ^^^^^^
    // [analyzer 24] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 48] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
}

main() {}
