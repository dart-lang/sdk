// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A1 {
  method1() {}
}

extension A2 on A1 {
  method2() {
    super.method1(); // Error
  }
}

main() {}
