// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that when an extension type declaration includes an "implements"
// clause, and an attempt is made to promote a getter or non-promotable field of
// the underlying representation type, the implementation generates the
// appropriate "why not promoted" context message.

// SharedOptions=--enable-experiment=inline-class

class C1 {
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

class C2 {
  int? get _conflictingGetter => 0;
  //       ^^^^^^^^^^^^^^^^^^
  // [context 4] '_conflictingGetter' couldn't be promoted because there is a conflicting getter in class 'C2'.  See http://dart.dev/go/non-promo-conflicting-getter
  // [context 10] '_conflictingGetter' couldn't be promoted because there is a conflicting getter in class 'C2'.  See http://dart.dev/go/non-promo-conflicting-getter
  // [context 16] '_conflictingGetter' couldn't be promoted because there is a conflicting getter in class 'C2'.  See http://dart.dev/go/non-promo-conflicting-getter
  // [context 22] '_conflictingGetter' couldn't be promoted because there is a conflicting getter in class 'C2'.  See http://dart.dev/go/non-promo-conflicting-getter
  // [context 28] '_conflictingGetter' couldn't be promoted because there is a conflicting getter in class 'C2'.
  // [context 34] '_conflictingGetter' couldn't be promoted because there is a conflicting getter in class 'C2'.
  // [context 40] '_conflictingGetter' couldn't be promoted because there is a conflicting getter in class 'C2'.
  // [context 46] '_conflictingGetter' couldn't be promoted because there is a conflicting getter in class 'C2'.
  int? _conflictingField = 0;
  //   ^^^^^^^^^^^^^^^^^
  // [context 5] '_conflictingField' couldn't be promoted because there is a conflicting non-promotable field in class 'C2'.  See http://dart.dev/go/non-promo-conflicting-non-promotable-field
  // [context 11] '_conflictingField' couldn't be promoted because there is a conflicting non-promotable field in class 'C2'.  See http://dart.dev/go/non-promo-conflicting-non-promotable-field
  // [context 17] '_conflictingField' couldn't be promoted because there is a conflicting non-promotable field in class 'C2'.  See http://dart.dev/go/non-promo-conflicting-non-promotable-field
  // [context 23] '_conflictingField' couldn't be promoted because there is a conflicting non-promotable field in class 'C2'.  See http://dart.dev/go/non-promo-conflicting-non-promotable-field
  // [context 29] '_conflictingField' couldn't be promoted because there is a conflicting non-promotable field in class 'C2'.
  // [context 35] '_conflictingField' couldn't be promoted because there is a conflicting non-promotable field in class 'C2'.
  // [context 41] '_conflictingField' couldn't be promoted because there is a conflicting non-promotable field in class 'C2'.
  // [context 47] '_conflictingField' couldn't be promoted because there is a conflicting non-promotable field in class 'C2'.
}

class C3 {
  final int? _conflictingNsmForwarder = 0;
}

class C4 implements C3 {
//    ^^
// [context 6] '_conflictingNsmForwarder' couldn't be promoted because there is a conflicting noSuchMethod forwarder in class 'C4'.  See http://dart.dev/go/non-promo-conflicting-noSuchMethod-forwarder
// [context 12] '_conflictingNsmForwarder' couldn't be promoted because there is a conflicting noSuchMethod forwarder in class 'C4'.  See http://dart.dev/go/non-promo-conflicting-noSuchMethod-forwarder
// [context 18] '_conflictingNsmForwarder' couldn't be promoted because there is a conflicting noSuchMethod forwarder in class 'C4'.  See http://dart.dev/go/non-promo-conflicting-noSuchMethod-forwarder
// [context 24] '_conflictingNsmForwarder' couldn't be promoted because there is a conflicting noSuchMethod forwarder in class 'C4'.  See http://dart.dev/go/non-promo-conflicting-noSuchMethod-forwarder
// [context 30] '_conflictingNsmForwarder' couldn't be promoted because there is a conflicting noSuchMethod forwarder in class 'C4'.
// [context 36] '_conflictingNsmForwarder' couldn't be promoted because there is a conflicting noSuchMethod forwarder in class 'C4'.
// [context 42] '_conflictingNsmForwarder' couldn't be promoted because there is a conflicting noSuchMethod forwarder in class 'C4'.
// [context 48] '_conflictingNsmForwarder' couldn't be promoted because there is a conflicting noSuchMethod forwarder in class 'C4'.
  noSuchMethod(invocation) => 0;
}

extension type E(C1 c) implements C1 {
  void viaImplicitThis() {
    if (_notField != null) {
      _notField.isEven;
      //        ^^^^^^
      // [analyzer 1] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
      // [cfe 25] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
    }
    if (notPrivate != null) {
      notPrivate.isEven;
      //         ^^^^^^
      // [analyzer 2] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
      // [cfe 26] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
    }
    if (_notFinal != null) {
      _notFinal.isEven;
      //        ^^^^^^
      // [analyzer 3] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
      // [cfe 27] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
    }
    if (_conflictingGetter != null) {
      _conflictingGetter.isEven;
      //                 ^^^^^^
      // [analyzer 4] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
      // [cfe 28] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
    }
    if (_conflictingField != null) {
      _conflictingField.isEven;
      //                ^^^^^^
      // [analyzer 5] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
      // [cfe 29] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
    }
    if (_conflictingNsmForwarder != null) {
      _conflictingNsmForwarder.isEven;
      //                       ^^^^^^
      // [analyzer 6] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
      // [cfe 30] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
    }
  }

  void viaExplicitThis() {
    if (this._notField != null) {
      this._notField.isEven;
      //             ^^^^^^
      // [analyzer 7] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
      // [cfe 31] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
    }
    if (this.notPrivate != null) {
      this.notPrivate.isEven;
      //              ^^^^^^
      // [analyzer 8] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
      // [cfe 32] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
    }
    if (this._notFinal != null) {
      this._notFinal.isEven;
      //             ^^^^^^
      // [analyzer 9] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
      // [cfe 33] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
    }
    if (this._conflictingGetter != null) {
      this._conflictingGetter.isEven;
      //                      ^^^^^^
      // [analyzer 10] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
      // [cfe 34] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
    }
    if (this._conflictingField != null) {
      this._conflictingField.isEven;
      //                     ^^^^^^
      // [analyzer 11] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
      // [cfe 35] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
    }
    if (this._conflictingNsmForwarder != null) {
      this._conflictingNsmForwarder.isEven;
      //                            ^^^^^^
      // [analyzer 12] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
      // [cfe 36] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
    }
  }
}

void viaGeneralPropertyAccess(E e) {
  if ((e)._notField != null) {
    (e)._notField.isEven;
    //            ^^^^^^
    // [analyzer 13] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 37] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
  if ((e).notPrivate != null) {
    (e).notPrivate.isEven;
    //             ^^^^^^
    // [analyzer 14] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 38] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
  if ((e)._notFinal != null) {
    (e)._notFinal.isEven;
    //            ^^^^^^
    // [analyzer 15] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 39] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
  if ((e)._conflictingGetter != null) {
    (e)._conflictingGetter.isEven;
    //                     ^^^^^^
    // [analyzer 16] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 40] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
  if ((e)._conflictingField != null) {
    (e)._conflictingField.isEven;
    //                    ^^^^^^
    // [analyzer 17] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 41] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
  if ((e)._conflictingNsmForwarder != null) {
    (e)._conflictingNsmForwarder.isEven;
    //                           ^^^^^^
    // [analyzer 18] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 42] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
}

void viaPrefixedIdentifier(E e) {
  // Note: the analyzer has a special representation for property accesses of
  // the form `IDENTIFIER.IDENTIFIER`, so we test it separately.
  if (e._notField != null) {
    e._notField.isEven;
    //          ^^^^^^
    // [analyzer 19] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 43] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
  if (e.notPrivate != null) {
    e.notPrivate.isEven;
    //           ^^^^^^
    // [analyzer 20] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 44] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
  if (e._notFinal != null) {
    e._notFinal.isEven;
    //          ^^^^^^
    // [analyzer 21] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 45] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
  if (e._conflictingGetter != null) {
    e._conflictingGetter.isEven;
    //                   ^^^^^^
    // [analyzer 22] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 46] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
  if (e._conflictingField != null) {
    e._conflictingField.isEven;
    //                  ^^^^^^
    // [analyzer 23] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 47] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
  if (e._conflictingNsmForwarder != null) {
    e._conflictingNsmForwarder.isEven;
    //                         ^^^^^^
    // [analyzer 24] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 48] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
}

main() {}
