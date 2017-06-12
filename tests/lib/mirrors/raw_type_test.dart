// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library lib;

@MirrorsUsed(targets: "lib")
import 'dart:mirrors';

import 'package:expect/expect.dart';

class Foo<T> {}

class Bar<T> extends Foo<T> {}

main() {
  var fooType = reflectType(Foo);
  var fooDeclaration = fooType.originalDeclaration;
  var barSupertype = reflect(new Bar()).type.superclass;
  var barSuperclass = barSupertype.originalDeclaration;
  Expect.equals(fooDeclaration, barSuperclass, 'declarations');
  Expect.equals(fooType, barSupertype, 'types'); //# 01: ok
}
