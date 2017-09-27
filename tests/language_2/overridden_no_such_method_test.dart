// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program testing overridden messageNotUnderstood.

library OverriddenNoSuchMethodTest.dart;

import "dart:mirrors" show reflect;
import "package:expect/expect.dart";
part "overridden_no_such_method.dart";

main() {
  OverriddenNoSuchMethod.testMain(); /*@compile-error=unspecified*/
}
