// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test correct handling of NULL object in invocation and implicit closures.

import "package:expect/expect.dart";

main() {
  var nullObj = null;
  var x = nullObj.toString();
  Expect.isTrue(x is String);
  var y = nullObj.toString;
  Expect.isNotNull(y);
}
