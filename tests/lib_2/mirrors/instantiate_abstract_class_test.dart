// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

library test.instantiate_abstract_class;

import 'dart:mirrors';
import 'package:expect/expect.dart';

assertInstantiationErrorOnGenerativeConstructors(classMirror) {
  classMirror.declarations.values.forEach((decl) {
    if (decl is! MethodMirror) return;
    if (!decl.isGenerativeConstructor) return;
    var args = new List.filled(decl.parameters.length, null);
    Expect.throws(
        () => classMirror.newInstance(decl.constructorName, args),
        (e) => e is AbstractClassInstantiationError,
        '${decl.qualifiedName} should have failed');
  });
}

runFactoryConstructors(classMirror) {
  classMirror.declarations.values.forEach((decl) {
    if (decl is! MethodMirror) return;
    if (!decl.isFactoryConstructor) return;
    var args = new List.filled(decl.parameters.length, null);
    classMirror.newInstance(decl.constructorName, args); // Should not throw.
  });
}

abstract class AbstractClass {
  AbstractClass();
  AbstractClass.named();
  factory AbstractClass.named2() => new ConcreteClass();
}

class ConcreteClass implements AbstractClass {}

main() {
  assertInstantiationErrorOnGenerativeConstructors(reflectType(num));
  assertInstantiationErrorOnGenerativeConstructors(reflectType(double));
  assertInstantiationErrorOnGenerativeConstructors(reflectType(StackTrace));

  assertInstantiationErrorOnGenerativeConstructors(reflectType(AbstractClass));
  runFactoryConstructors(reflectType(AbstractClass));
}
