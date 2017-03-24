// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class A {
  toString() {
    if (false
          || true // //# 01: runtime error
        ) {
      return 499;
    } else {
      return "ok";
    }
  }
}

main() {
  print(new A());
}
