// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test uses a record with a static type dependent on a local function type
// variable.

import 'package:expect/expect.dart';

void main() {
  Object? foo<T>(T value) => (0, value);
  //                         ^ static type is (int, T)

  Expect.isTrue(foo<Pattern>('hi') is (int, String));
}
