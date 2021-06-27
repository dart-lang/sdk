// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  void set test(int v) {}
  dynamic get test => 3.14;
}

test() {
  C c = new C();
  c.test = 1;
  c.test;
}

main() {}
