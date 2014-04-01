// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.invoke_closurization_test;

import 'dart:mirrors';

import 'package:expect/expect.dart';

class C {
  instanceMethod(x, y, z) => '$x+$y+$z';
  static staticFunction(x, y, z) => '$x-$y-$z';
}
libraryFunction(x, y, z) => '$x:$y:$z';

testSync() {
  var result;

  C c = new C();
  InstanceMirror im = reflect(c);
  result = im.getField(#instanceMethod);
  Expect.isTrue(result.reflectee is Function, "Should be closure");
  Expect.equals("A+B+C", result.reflectee('A', 'B', 'C'));

  ClassMirror cm = reflectClass(C);
  result = cm.getField(#staticFunction);                             /// static: ok
  Expect.isTrue(result.reflectee is Function, "Should be closure");  /// static: continued
  Expect.equals("A-B-C", result.reflectee('A', 'B', 'C'));           /// static: continued

  LibraryMirror lm = cm.owner;
  result = lm.getField(#libraryFunction);                            /// static: continued
  Expect.isTrue(result.reflectee is Function, "Should be closure");  /// static: continued
  Expect.equals("A:B:C", result.reflectee('A', 'B', 'C'));           /// static: continued
}

main() {
  testSync();
}
