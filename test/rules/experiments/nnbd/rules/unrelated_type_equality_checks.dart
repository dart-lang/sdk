// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N unrelated_type_equality_checks`

bool m(int? a1, num a2) {
  var b1 = a1 == a2; // OK
  var b2 = a2 == a1; // OK
}
