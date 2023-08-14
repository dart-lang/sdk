// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'package:expect/expect.dart';

bool getter_visited = false;

int get getter {
  getter_visited = true;
}

class Class {
  method() {
    getter++;
//  ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL
// [cfe] Setter not found: 'getter'.
  }
}

main() {
  new Class().method();
}
