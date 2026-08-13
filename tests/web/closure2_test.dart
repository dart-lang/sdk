// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

closure0() {
  // A closure will be implemented as a class. Make sure everything is set up
  // correctly when no other class is generated. In particular we need
  // the Dart-Object class to be generated.
  var f = () => 42;
  Expect.equals(42, f());
}

main() {
  closure0();
}
