// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@MirrorsUsed(targets: "A")
import 'dart:mirrors';

import 'package:expect/expect.dart';

class A {
  foo(y, [x]) => y;
  operator +(other) => null;
  get bar => 499;
  operator$foo([optional = 499]) => optional;
}

main() {
  // We are using `getField` to tear off `foo`. We must make sure that all
  // stub methods are installed.
  var closure = reflect(new A()).getField(#foo).reflectee;
  Expect.equals("b", closure("b"));

  closure = reflect(new A()).getField(#operator$foo).reflectee;
  Expect.equals(499, closure());
}
