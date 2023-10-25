// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that the appropriate "why not promoted" context messages are shown when
// field promotion is disabled.
//
// The context message advising the user that field promotion is only available
// in Dart 3.2 and above is only shown if upgrading to Dart 3.2 would make field
// promotion work; otherwise, the context message explains the reason why the
// field would not be promotable even in Dart 3.2. Rationale: if a user,
// encouraged by a context message, decided to upgrade the required language
// version of their package to 3.2, only to discover that the field in question
// still wasn’t promotable, that could be very frustrating.

// @dart=3.1

class C1 {
  final int? _wouldBePromotable = 0;
  //         ^^^^^^^^^^^^^^^^^^
  // [context 1] '_wouldBePromotable' refers to a field. It couldn't be promoted because field promotion is only available in Dart 3.2 and above.  See http://dart.dev/go/non-promo-field-promotion-unavailable
  // [context 8] '_wouldBePromotable' refers to a field. It couldn't be promoted because field promotion is only available in Dart 3.2 and above.
  int? get _notField => 0;
  //       ^^^^^^^^^
  // [context 2] '_notField' refers to a getter so it couldn't be promoted.  See http://dart.dev/go/non-promo-non-field
  // [context 9] '_notField' refers to a getter so it couldn't be promoted.
  final int? notPrivate = 0;
  //         ^^^^^^^^^^
  // [context 3] 'notPrivate' refers to a public field so it couldn't be promoted.  See http://dart.dev/go/non-promo-public-field
  // [context 10] 'notPrivate' refers to a public field so it couldn't be promoted.
  int? _notFinal = 0;
  //   ^^^^^^^^^
  // [context 4] '_notFinal' refers to a non-final field so it couldn't be promoted.  See http://dart.dev/go/non-promo-non-final-field
  // [context 11] '_notFinal' refers to a non-final field so it couldn't be promoted.
  final int? _conflictingGetter = 0;
  final int? _conflictingField = 0;
  final int? _conflictingNsmForwarder = 0;
}

class C2 {
  int? get _conflictingGetter => 0;
  //       ^^^^^^^^^^^^^^^^^^
  // [context 5] '_conflictingGetter' couldn't be promoted because there is a conflicting getter in class 'C2'.  See http://dart.dev/go/non-promo-conflicting-getter
  // [context 12] '_conflictingGetter' couldn't be promoted because there is a conflicting getter in class 'C2'.
  int? _conflictingField = 0;
  //   ^^^^^^^^^^^^^^^^^
  // [context 6] '_conflictingField' couldn't be promoted because there is a conflicting non-promotable field in class 'C2'.  See http://dart.dev/go/non-promo-conflicting-non-promotable-field
  // [context 13] '_conflictingField' couldn't be promoted because there is a conflicting non-promotable field in class 'C2'.
}

class C3 {
  final int? _conflictingNsmForwarder = 0;
}

class C4 implements C3 {
//    ^^
// [context 7] '_conflictingNsmForwarder' couldn't be promoted because there is a conflicting noSuchMethod forwarder in class 'C4'.  See http://dart.dev/go/non-promo-conflicting-noSuchMethod-forwarder
// [context 14] '_conflictingNsmForwarder' couldn't be promoted because there is a conflicting noSuchMethod forwarder in class 'C4'.
  noSuchMethod(invocation) => 0;
}

test(C1 c) {
  if (c._wouldBePromotable != null) {
    c._wouldBePromotable.isEven;
    //                   ^^^^^^
    // [analyzer 1] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 8] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
  if (c._notField != null) {
    c._notField.isEven;
    //          ^^^^^^
    // [analyzer 2] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 9] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
  if (c.notPrivate != null) {
    c.notPrivate.isEven;
    //           ^^^^^^
    // [analyzer 3] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 10] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
  if (c._notFinal != null) {
    c._notFinal.isEven;
    //          ^^^^^^
    // [analyzer 4] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 11] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
  if (c._conflictingGetter != null) {
    c._conflictingGetter.isEven;
    //                   ^^^^^^
    // [analyzer 5] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 12] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
  if (c._conflictingField != null) {
    c._conflictingField.isEven;
    //                  ^^^^^^
    // [analyzer 6] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 13] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
  if (c._conflictingNsmForwarder != null) {
    c._conflictingNsmForwarder.isEven;
    //                         ^^^^^^
    // [analyzer 7] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 14] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
}

main() {}
