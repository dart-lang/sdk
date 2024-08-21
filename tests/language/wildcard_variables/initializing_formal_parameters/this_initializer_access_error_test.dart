// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// It's an error for `_` to be accessed inside an initializer list.

// SharedOptions=--enable-experiment=wildcard-variables

class C {
  var _;
  var other;

  C(this._) : other = _;
//                    ^
// [analyzer] COMPILE_TIME_ERROR.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER
// [cfe] Can't access 'this' in a field initializer to read '_'.
}

class CWithTypeParameter<_> {
  var _;
  var other;

  CWithTypeParameter(this._) : other = _;
//                                     ^
// [analyzer] COMPILE_TIME_ERROR.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER
// [cfe] Can't access 'this' in a field initializer to read '_'.
}
