// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

via_await(int? i) {
  void f() async {
    if (i == null) return;
    await null;
    // [error column 5, length 10]
    // [context 1] Variable 'i' could not be promoted due to an 'await' or 'yield'.  See http://dart.dev/go/non-promo-suspension
    // [context 3] Variable 'i' could not be promoted due to an 'await' or 'yield'.
    i.isEven;
    //^^^^^^
    // [analyzer 1] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 3] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }

  i = 0;
}

via_yield(int? i) {
  Stream<int> f() async* {
    if (i == null) return;
    yield 0;
    // [error column 5, length 8]
    // [context 2] Variable 'i' could not be promoted due to an 'await' or 'yield'.  See http://dart.dev/go/non-promo-suspension
    // [context 4] Variable 'i' could not be promoted due to an 'await' or 'yield'.
    i.isEven;
    //^^^^^^
    // [analyzer 2] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
    // [cfe 4] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }

  i = 0;
}
