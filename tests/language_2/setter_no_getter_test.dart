// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

/* //   //# 01: runtime error
get topLevel => 42;
*/ //  //# 01: continued
set topLevel(var value) {}

main() {
  Expect.equals(42, topLevel++); //# 01: continued
}
