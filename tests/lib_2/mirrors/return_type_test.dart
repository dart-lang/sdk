// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test of [MethodMirror.returnType].
library test.return_type_test;

@MirrorsUsed(targets: 'test.return_type_test', override: '*')
import 'dart:mirrors';

import 'stringify.dart';

class B {
  f() {}
  int g() {}
  List h() {}
  B i() {}

  // TODO(ahe): Test this when dart2js handles parameterized types.
  // List<int> j() {}
}

methodsOf(ClassMirror cm) {
  var result = new Map();
  cm.declarations.forEach((k, v) {
    if (v is MethodMirror && v.isRegularMethod) result[k] = v;
  });
  return result;
}

main() {
  var methods = methodsOf(reflectClass(B));

  expect(
      '{f: Method(s(f) in s(B)), '
      'g: Method(s(g) in s(B)), '
      'h: Method(s(h) in s(B)), '
      'i: Method(s(i) in s(B))}',
      methods);

  var f = methods[#f];
  var g = methods[#g];
  var h = methods[#h];
  var i = methods[#i];

  expect('Type(s(dynamic), top-level)', f.returnType);
  expect('Class(s(int) in s(dart.core), top-level)', g.returnType);
  expect('Class(s(List) in s(dart.core), top-level)', h.returnType);
  expect('Class(s(B) in s(test.return_type_test), top-level)', i.returnType);
}
