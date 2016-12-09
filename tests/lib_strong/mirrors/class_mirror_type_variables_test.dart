// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:mirrors";

import "package:expect/expect.dart";

import "class_mirror_type_variables_data.dart";
import "class_mirror_type_variables_expect.dart";

class RuntimeEnv implements Env {
  ClassMirror getA() => reflectClass(A);
  ClassMirror getB() => reflectClass(B);
  ClassMirror getC() => reflectClass(C);
  ClassMirror getD() => reflectClass(D);
  ClassMirror getE() => reflectClass(E);
  ClassMirror getF() => reflectClass(F);
  ClassMirror getNoTypeParams() => reflectClass(NoTypeParams);
  ClassMirror getObject() => reflectClass(Object);
  ClassMirror getString() => reflectClass(String);
  ClassMirror getHelperOfString() => reflect(new Helper<String>()).type;
}

main() {
  test(new RuntimeEnv());
}
