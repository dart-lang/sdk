// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Allow assignment of string interpolation to a static const field

import "package:expect/expect.dart";

class A {
  static const x = 1;
  static const y = "Two is greater than ${x}";
}

main() {
  Expect.identical("Two is greater than 1", A.y);
}
