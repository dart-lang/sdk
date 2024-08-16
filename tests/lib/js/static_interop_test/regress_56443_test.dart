// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';

class A {
  A() {
    Function f = (int x) => x;
    f.toJS;
//    ^
// [web] `Function.toJS` requires a statically known function type, but Type 'Function' is not a precise function type, e.g., `void Function()`.
  }
}

void main() {
  A();
}
