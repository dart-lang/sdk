// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test reflection of private functions in core classes.

import "package:expect/expect.dart";
import "dart:mirrors";

main() {
  var s = "string";
  var im = reflect(s);
  Expect.throwsNoSuchMethodError(
      () => im.invoke(const Symbol("_setAt"), [0, 65]));
}
