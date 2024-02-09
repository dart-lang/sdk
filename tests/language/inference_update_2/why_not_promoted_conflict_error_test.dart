// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that the appropriate "why not promoted" context messages are shown when
// field promotion fails due to a conflict with declarations elsewhere in the
// file.

// SharedOptions=--enable-experiment=inference-update-2

class C {
  final int? _i;
  C(this._i);
}

class D {
  int? _i;
  //   ^^
  // [context 1] '_i' couldn't be promoted because there is a conflicting non-promotable field in class 'D'.  See http://dart.dev/go/non-promo-conflicting-non-promotable-field
  // [context 2] '_i' couldn't be promoted because there is a conflicting non-promotable field in class 'D'.
}

class E {
  int? get _i => 0;
  //       ^^
  // [context 1] '_i' couldn't be promoted because there is a conflicting getter in class 'E'.  See http://dart.dev/go/non-promo-conflicting-getter
  // [context 2] '_i' couldn't be promoted because there is a conflicting getter in class 'E'.
}

class F implements C {
//    ^
// [context 1] '_i' couldn't be promoted because there is a conflicting noSuchMethod forwarder in class 'F'.  See http://dart.dev/go/non-promo-conflicting-noSuchMethod-forwarder
// [context 2] '_i' couldn't be promoted because there is a conflicting noSuchMethod forwarder in class 'F'.
  @override
  noSuchMethod(Invocation invocation) => 0;
}

void test(C c) {
  if (c._i != null) {
    c._i.isEven;
    //   ^^^^^^
    // [analyzer 1] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 2] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
}

main() {}
