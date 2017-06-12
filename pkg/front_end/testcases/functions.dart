// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  void local(void f({a})) {
    f(a: "Hello, World");
    f();
  }

  local(({a: "Default greeting!"}) {
    print(a);
  });
}
