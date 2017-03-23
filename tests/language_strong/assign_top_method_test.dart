// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

method() {
  return 0;
}

main() {
  // Illegal, can't change a top level method
  Expect.throws(() { method = () { return 1; }; }, //# 01: static type warning
                (e) => e is NoSuchMethodError); //   //# 01: continued
}
