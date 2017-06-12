// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is a test for a problem in how dart2js cached InstanceMirror.invoke,
// etc. The test is using getField, as invoke, setField, and getField all share
// the same caching.

library lib;

@MirrorsUsed(targets: const ["lib", "dart.core"])
import 'dart:mirrors';

import 'package:expect/expect.dart';

class Foo {
  Foo(this.length);
  int length;
}

main() {
  Expect.equals(1, reflect(new Foo(1)).getField(#length).reflectee);
  Expect.equals(2, reflect(new Foo(2)).getField(#length).reflectee);
  Expect.equals(0, reflect([]).getField(#length).reflectee);
}
