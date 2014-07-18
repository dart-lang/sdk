// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.local_function_is_static;

import 'dart:mirrors';
import 'package:expect/expect.dart';

topLevel() => 1;
topLevelLocal() => () => 2;
class C {
  static klass() => 3;
  static klassLocal() => () => 4;
  instance() => 5;
  instanceLocal() => () => 6;
}

main() {
  var f = topLevel;
  Expect.equals(1, f());
  Expect.isTrue((reflect(f) as ClosureMirror).function.isStatic);

  f = topLevelLocal();
  Expect.equals(2, f());
  Expect.isTrue((reflect(f) as ClosureMirror).function.isStatic);

  f = C.klass;
  Expect.equals(3, f());
  Expect.isTrue((reflect(f) as ClosureMirror).function.isStatic);

  f = C.klassLocal();
  Expect.equals(4, f());
  Expect.isTrue((reflect(f) as ClosureMirror).function.isStatic);

  f = new C().instance;
  Expect.equals(5, f());
  Expect.isFalse((reflect(f) as ClosureMirror).function.isStatic);

  f = new C().instanceLocal();
  Expect.equals(6, f());
  Expect.isFalse((reflect(f) as ClosureMirror).function.isStatic);
}