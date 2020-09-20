// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

f(obj) {
  // 'Baz' is not loaded, throws a type error on test.
  return (obj is! Baz);
  //              ^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_TEST_WITH_UNDEFINED_NAME
  // [cfe] 'Baz' isn't a type.
}

main() {
  f(null);
}
