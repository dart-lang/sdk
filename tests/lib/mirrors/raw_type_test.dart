// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';

import 'package:expect/expect.dart';

class Foo<T> {}

class Bar<T> extends Foo<T> {}

main() {
  TypeMirror fooType = reflectType(Foo);
  DeclarationMirror fooDeclaration = fooType.originalDeclaration;
  TypeMirror barSupertype = reflect(new Bar()).type.superclass!;
  TypeMirror barSuperclass = barSupertype.originalDeclaration;
  Expect.equals(fooDeclaration, barSuperclass, 'declarations');
  Expect.equals(fooType, barSupertype, 'type mirrors');
  Expect.equals(Foo<dynamic>, fooType.reflectedType, 'types');
}
