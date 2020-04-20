// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.basic_types_in_dart_core;

import 'dart:mirrors';
import 'package:expect/expect.dart';

main() {
  LibraryMirror dartcore = currentMirrorSystem().findLibrary(#dart.core);
  ClassMirror cm;
  TypeMirror? tm;

  cm = dartcore.declarations[#int] as ClassMirror;
  Expect.equals(reflectClass(int), cm);
  Expect.equals(#int, cm.simpleName);

  cm = dartcore.declarations[#double] as ClassMirror;
  Expect.equals(reflectClass(double), cm);
  Expect.equals(#double, cm.simpleName);

  cm = dartcore.declarations[#num] as ClassMirror;
  Expect.equals(reflectClass(num), cm);
  Expect.equals(#num, cm.simpleName);

  cm = dartcore.declarations[#bool] as ClassMirror;
  Expect.equals(reflectClass(bool), cm);
  Expect.equals(#bool, cm.simpleName);

  cm = dartcore.declarations[#String] as ClassMirror;
  Expect.equals(reflectClass(String), cm);
  Expect.equals(#String, cm.simpleName);

  cm = dartcore.declarations[#List] as ClassMirror;
  Expect.equals(reflectClass(List), cm);
  Expect.equals(#List, cm.simpleName);

  cm = dartcore.declarations[#Null] as ClassMirror;
  Expect.equals(reflectClass(Null), cm);
  Expect.equals(#Null, cm.simpleName);

  cm = dartcore.declarations[#Object] as ClassMirror;
  Expect.equals(reflectClass(Object), cm);
  Expect.equals(#Object, cm.simpleName);

  tm = dartcore.declarations[#dynamic] as TypeMirror?;
  Expect.isNull(tm);

  tm = dartcore.declarations[const Symbol('void')] as TypeMirror?;
  Expect.isNull(tm);
}
