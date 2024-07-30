// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This test verifies that we invoke closure in fields correctly when going
// through the slow NSM path rather than the field invocation dispatchers
// when run in AOT mode.

import 'package:expect/expect.dart';

class C {
  dynamic field;
}

main() {
  var c = C();
  c.field = <T>(T x) => x.hashCode;
  Expect.equals(3.hashCode, c.field<dynamic>(3));
}
