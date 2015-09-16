// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test that dart2js gets the right interceptor for an int.

main() {
  var a = [1];
  var b = a[0];
  Expect.equals('1', b.toString());
  Expect.isTrue(b.isOdd);
}
