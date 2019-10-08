// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'issue38750_lib1.dart';
import 'issue38750_lib2.dart';

main() {}

errors() {
  C c = new C();
  c._foo();
  C._staticFoo();
  c.foo();
  C.staticFoo();
  c._bar();
}
