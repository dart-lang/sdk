// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.basic_types_in_dart_core;

@MirrorsUsed(targets: "dart.core")
import 'dart:mirrors';
import 'package:expect/expect.dart';

main() {
  LibraryMirror dartcore = currentMirrorSystem().findLibrary(#dart.core);
  ClassMirror cm;

  cm = dartcore.declarations[#int];
  Expect.equals(reflectClass(int), cm);
  Expect.equals(#int, cm.simpleName);

  cm = dartcore.declarations[#double];
  Expect.equals(reflectClass(double), cm);
  Expect.equals(#double, cm.simpleName);

  cm = dartcore.declarations[#num];
  Expect.equals(reflectClass(num), cm);
  Expect.equals(#num, cm.simpleName);

  cm = dartcore.declarations[#bool];
  Expect.equals(reflectClass(bool), cm);
  Expect.equals(#bool, cm.simpleName);

  cm = dartcore.declarations[#String];
  Expect.equals(reflectClass(String), cm);
  Expect.equals(#String, cm.simpleName);

  cm = dartcore.declarations[#List];
  Expect.equals(reflectClass(List), cm);
  Expect.equals(#List, cm.simpleName);

  cm = dartcore.declarations[#Null];
  Expect.equals(reflectClass(Null), cm);
  Expect.equals(#Null, cm.simpleName);

  cm = dartcore.declarations[#Object];
  Expect.equals(reflectClass(Object), cm);
  Expect.equals(#Object, cm.simpleName);

  cm = dartcore.declarations[#dynamic];
  Expect.isNull(cm);

  cm = dartcore.declarations[const Symbol('void')];
  Expect.isNull(cm);
}
