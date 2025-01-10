// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Base {
  int method1() => 1;
  int method2() => 2;
}

class Sub1 extends Base {
  @override
  int method1() => 3;
  @override
  int method2() => 4;
}
