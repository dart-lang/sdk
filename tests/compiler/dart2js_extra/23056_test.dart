// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for http://dartbug.com/23056/
// Ensure that Mixin prototypes are initialized before first use.

// Mirrors is the only way to have a getter be equipped with metadata.
@MirrorsUsed(targets: 'M', override: '*')
import 'dart:mirrors';

import 'package:expect/expect.dart';

class M {
  @NoInline()
  bool get foo => true;
}

class A extends Object with M {
  @NoInline()
  bool get foo => super.foo;
}

@AssumeDynamic()
@NoInline()
bool hide(bool x) => x;

main() {
  Expect.isTrue((hide(true) ? new A() : new M()).foo);
}
