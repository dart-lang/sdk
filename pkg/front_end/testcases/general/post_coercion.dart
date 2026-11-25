// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

dynamic createA() => A();

class A;

class B {
  A? _a;

  A get a {
    var value = _a;
    if (value != null) return value;
    return _a = createA();
  }
}
