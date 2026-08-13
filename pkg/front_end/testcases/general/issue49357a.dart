// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A extends B {
  A({
    required super.field,
  });
}

class C {
  void method(list) {
    for (final element in list) {
    //}
  }
}
