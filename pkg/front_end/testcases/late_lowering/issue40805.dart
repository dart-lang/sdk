// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  D().x = 3.14;
}

class C {
  covariant late final int x;
}

class D extends C {
  set x(num value) { super.x = value.toInt(); }
}