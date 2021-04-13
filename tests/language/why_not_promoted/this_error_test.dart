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
    // TODO(paulberry): get this to work with the CFE.
    if (this == null) return;
    this.isEven;
//       ^^^^^^
// [analyzer 2] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
// [context 2] 'this' can't be promoted.  See http://dart.dev/go/non-promo-this
// [cfe] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }

  extension_implicit_this() {
    // TODO(paulberry): get this to work with the CFE.
    if (this == null) return;
    isEven;
//  ^^^^^^
// [analyzer 1] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
// [context 1] 'this' can't be promoted.  See http://dart.dev/go/non-promo-this
// [cfe] Property 'isEven' cannot be accessed on 'int?' because it is potentially null.
  }
}
