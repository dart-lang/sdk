// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

patch() {
  return 12;
}

main() {
  var x = patch();
  Expect.equals(12, x);
}
