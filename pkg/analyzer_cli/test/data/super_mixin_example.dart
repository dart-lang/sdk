// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This produces errors normally, but --supermixin disables them.
class Test extends Object with C {
  void foo() {}
}

abstract class B {
  void foo() {}
}

abstract class C extends B {
  void bar() {
    super.foo();
  }
}
