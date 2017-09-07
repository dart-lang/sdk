// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:mirrors";

import "package:expect/expect.dart";
import "stringify.dart";

doNothing42() {}

main() {
  // Regression test for http://www.dartbug.com/6335
  var closureMirror = reflect(doNothing42);
  Expect.equals(
      stringifySymbol(closureMirror.function.simpleName), "s(doNothing42)");
}
