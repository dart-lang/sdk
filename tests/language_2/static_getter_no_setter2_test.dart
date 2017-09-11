// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class Class {
  static int get getter => 0;

  method() {
    try {
      getter++; //# 01: compile-time error
    } on NoSuchMethodError catch (e) {
      return;
    }
    Expect.fail('Expected NoSuchMethodError'); //# 01: continued
  }

  noSuchMethod(i) {
    return 42;
  }
}

class Subclass extends Class {
  method() {
    print(getter); //# 01: continued
    super.method();
  }
}

main() {
  new Subclass().method();
}
