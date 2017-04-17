// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.generic_function_typedef;

import 'dart:mirrors';

import 'package:expect/expect.dart';

import 'generics_helper.dart';

class C<T> {
  makeClosure1() {
    T closure1(T t) {}
    return closure1;
  }

  makeClosure2() {
    enclosing() {
      T closure2(T t) {}
      return closure2;
    }

    ;
    return enclosing();
  }
}

main() {
  ClosureMirror closure1 = reflect(new C<String>().makeClosure1());
  Expect.equals(reflectClass(String), closure1.function.returnType);
  Expect.equals(reflectClass(String), closure1.function.parameters[0].type);

  ClosureMirror closure2 = reflect(new C<String>().makeClosure2());
  Expect.equals(reflectClass(String), closure2.function.returnType);
  Expect.equals(reflectClass(String), closure2.function.parameters[0].type);
}
