// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  method1() {
    method2(b: true, 0);
    method3(c: this, 1);
  }

  method2(int a, {required bool b}) {}

  method3(int a, {required Class c}) {}
}
