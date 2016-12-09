// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

var array = [1];

main() {
  Expect.throws(() => -null, (e) => e is NoSuchMethodError);
  // Make sure we have an untyped call to operator-.
  print(-array[0]);
}
