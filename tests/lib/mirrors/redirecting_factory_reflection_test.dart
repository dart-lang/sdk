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

void main() {
  ClassMirror cm = reflectClass(A);
  var i = cm.newInstance(Symbol.empty, []).reflectee;
  Expect.equals(
    A<dynamic>,
    i.t,
    'mirrors should create the correct reified generic type',
  );
  cm = reflectType(A<String>) as ClassMirror;
  i = cm.newInstance(Symbol.empty, []).reflectee;
  Expect.equals(
    A<String>,
    i.t,
    'mirrors should create the correct reified generic type',
  );
}
