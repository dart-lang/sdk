// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library lib_b;

import '4434_lib.dart';

class B extends A {}

main() {
  B b = new B();
  b.x(b);
}
