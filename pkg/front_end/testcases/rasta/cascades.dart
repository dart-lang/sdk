// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

class A {
  add(x) => x;
}

main() {
  var a = new A();
  f(x) => x;
  a..add(f)('WHAT');
}
