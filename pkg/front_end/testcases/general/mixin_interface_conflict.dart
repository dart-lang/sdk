// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class B {
  int get n => 1;
}

class C {
  double get n => 2.0;
}

mixin M on B, C {}

main() {}
