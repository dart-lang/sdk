// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.instantiate_abstract_class;

@MirrorsUsed(targets: const ["dart.core", AbstractClass])
import 'dart:mirrors';
import 'package:expect/expect.dart';

assertInstanitationErrorOnGenerativeConstructors(classMirror) {
  classMirror.declarations.values.forEach((decl) {
    if (decl is! MethodMirror) return;
    if (!decl.isGenerativeConstructor) return;
    var args = new List(decl.parameters.length);
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
    var args = new List(decl.parameters.length);
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
  assertInstanitationErrorOnGenerativeConstructors(reflectType(num));
  assertInstanitationErrorOnGenerativeConstructors(reflectType(double));
  assertInstanitationErrorOnGenerativeConstructors(reflectType(StackTrace));

  assertInstanitationErrorOnGenerativeConstructors(reflectType(AbstractClass));
  runFactoryConstructors(reflectType(AbstractClass));
}
