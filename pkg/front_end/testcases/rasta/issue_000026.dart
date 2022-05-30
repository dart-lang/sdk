// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

class C {
  var a;
  var b = 0;
  var c = 1 + 2;
}

class D {
  var a;
  var b = 1;
  var c = 2 - 3;
  D();
}

main() {
  new C();
  new D();
}
