// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test validates integration of "why not promoted" when the user tries to
// promote `this`.

// TODO(paulberry): once we support adding "why not promoted" information to
// errors that aren't related to null safety, test references to `this` in
// classes and mixins.

extension on int? {
  extension_explicit_this() {
    if (this == null) return;
    this.isEven;
//       ^^^^^^
// [analyzer 1] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
// [context 1] 'this' can't be promoted.  See http://dart.dev/go/non-promo-this
// [cfe 3] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
// [context 3] 'this' can't be promoted.
  }

  extension_implicit_this() {
    if (this == null) return;
    isEven;
//  ^^^^^^
// [analyzer 2] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
// [context 2] 'this' can't be promoted.  See http://dart.dev/go/non-promo-this
// [cfe 4] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
// [context 4] 'this' can't be promoted.
  }
}
