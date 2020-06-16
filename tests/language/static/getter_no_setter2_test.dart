// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

class Class {
  static int get getter => 0;

  method() {
    getter++;
//  ^^^^^^
// [analyzer] STATIC_WARNING.ASSIGNMENT_TO_FINAL_NO_SETTER
// [cfe] Setter not found: 'getter'.
  }

  noSuchMethod(i) => 42;
}

main() {
  new Class().method();
}
