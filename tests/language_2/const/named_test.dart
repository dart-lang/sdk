// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check that const constructors work with named arguments.

import "package:expect/expect.dart";

main() {
  var d = const Duration(milliseconds: 499);
  Expect.equals(499, d.inMilliseconds);
}
