// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class Bound {
  run() {
    return 42;
  }
}

void main() {
  var runner = new Bound().run;
  Expect.equals(42, runner());
}
