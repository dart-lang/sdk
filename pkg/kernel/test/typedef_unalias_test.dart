// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.typedef_unalias_test;

import 'package:kernel/ast.dart';
import 'package:test/test.dart';
import 'verify_test.dart' show TestHarness;

void harnessTest(String name, void doTest(TestHarness harness)) {
  test(name, () {
    doTest(new TestHarness());
  });
}

main() {
  harnessTest('`Foo` where typedef Foo = C', (TestHarness harness) {
    var foo = new Typedef('Foo', harness.otherClass.rawType);
    harness.enclosingLibrary.addTypedef(foo);
    var type = new TypedefType(foo);
    expect(type.unalias, equals(harness.otherClass.rawType));
  });
  harnessTest('`Foo<Obj>` where typedef Foo<T> = C<T>', (TestHarness harness) {
    var param = harness.makeTypeParameter('T');
    var foo = new Typedef('Foo',
        new InterfaceType(harness.otherClass, [new TypeParameterType(param)]),
        typeParameters: [param]);
    harness.enclosingLibrary.addTypedef(foo);
    var input = new TypedefType(foo, [harness.objectClass.rawType]);
    var expected =
        new InterfaceType(harness.otherClass, [harness.objectClass.rawType]);
    expect(input.unalias, equals(expected));
  });
  harnessTest('`Bar<Obj>` where typedef Bar<T> = Foo<T>, Foo<T> = C<T>',
      (TestHarness harness) {
    var fooParam = harness.makeTypeParameter('T');
    var foo = new Typedef(
        'Foo',
        new InterfaceType(
            harness.otherClass, [new TypeParameterType(fooParam)]),
        typeParameters: [fooParam]);
    var barParam = harness.makeTypeParameter('T');
    var bar = new Typedef(
        'Bar', new TypedefType(foo, [new TypeParameterType(barParam)]),
        typeParameters: [barParam]);
    harness.enclosingLibrary.addTypedef(foo);
    harness.enclosingLibrary.addTypedef(bar);
    var input = new TypedefType(bar, [harness.objectClass.rawType]);
    var expected =
        new InterfaceType(harness.otherClass, [harness.objectClass.rawType]);
    expect(input.unalias, equals(expected));
  });
  harnessTest('`Foo<Foo<C>>` where typedef Foo<T> = C<T>',
      (TestHarness harness) {
    var param = harness.makeTypeParameter('T');
    var foo = new Typedef('Foo',
        new InterfaceType(harness.otherClass, [new TypeParameterType(param)]),
        typeParameters: [param]);
    harness.enclosingLibrary.addTypedef(foo);
    var input = new TypedefType(foo, [
      new TypedefType(foo, [harness.objectClass.rawType])
    ]);
    var expected = new InterfaceType(harness.otherClass, [
      new TypedefType(foo, [harness.objectClass.rawType])
    ]);
    expect(input.unalias, equals(expected));
  });
}
