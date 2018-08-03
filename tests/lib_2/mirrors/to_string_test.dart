// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.to_string_test;

@MirrorsUsed(targets: "test.to_string_test")
import 'dart:mirrors';

import 'package:expect/expect.dart';

expect(expected, actual) => Expect.stringEquals(expected, '$actual');

class Foo {
  var field;
  method() {}
}

main() {
  var mirrors = currentMirrorSystem();
  expect("TypeMirror on 'dynamic'", mirrors.dynamicType);
  expect("TypeMirror on 'void'", mirrors.voidType);
  expect("LibraryMirror on 'test.to_string_test'",
      mirrors.findLibrary(#test.to_string_test));
  expect("InstanceMirror on 1", reflect(1));
  expect("ClassMirror on 'Foo'", reflectClass(Foo));
  expect("VariableMirror on 'field'", reflectClass(Foo).declarations[#field]);
  expect("MethodMirror on 'method'", reflectClass(Foo).declarations[#method]);
  String s = reflect(main).toString();
  Expect.isTrue(s.startsWith("ClosureMirror on '"), s);
}
