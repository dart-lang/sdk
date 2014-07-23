// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_js_helper";
import "package:expect/expect.dart";

@Native("A")
class A {}

main() {
  var a = [new Object()];
  Expect.isFalse(a[0] is A);
}
