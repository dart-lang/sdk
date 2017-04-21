// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

bool getter_visited = false;

class Class {
  static final int getter = () {
    getter_visited = true;
  }();

  method() {
    try {
      getter++; //# 01: static type warning
    } on NoSuchMethodError catch (e) {
      Expect.isTrue(getter_visited); //# 01: continued
      return;
    }
    Expect.fail('Expected NoSuchMethodError'); //# 01: continued
  }
}

main() {
  new Class().method();
}
