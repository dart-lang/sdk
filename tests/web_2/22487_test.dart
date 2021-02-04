// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Regression test for http://dartbug.com/22487

import 'package:expect/expect.dart';

divIsInt(a, b) => (a / b) is int;

main() {
  Expect.isFalse((divIsInt)(10, 3));
}
