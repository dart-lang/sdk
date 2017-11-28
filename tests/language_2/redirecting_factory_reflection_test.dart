// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';
import 'package:expect/expect.dart';

abstract class A<T> {
  get t;
  factory A() = B<T, A<T>>;
}

class B<X, Y> implements A<X> {
  final t;
  B() : t = Y;
}

main() {
  ClassMirror m = reflectClass(A);
  var i = m.newInstance(const Symbol(''), []).reflectee;
  Expect.equals(i.t.toString(), 'A');
}
