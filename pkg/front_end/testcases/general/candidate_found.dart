// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Fisk {
  Fisk(int x) {}

  Fisk.named(int x) {}

  void method(int x) {}

  static void staticMethod(int x) {}
}

test() {
  new Fisk();
  new Fisk.named();
  Fisk();
  Fisk.named();
  Fisk.staticMethod();
  (null as Fisk).method();
}

main() {}
