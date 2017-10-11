// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:mirrors';

import "package:expect/expect.dart";

class A {
  var missingSetterField;
  var missingGetterField;
  var getterInSuperClassField;
  var setterInSuperClassField;
  var getterSetterField;
  var missingAllField;
  var indexField = new List(2);

  set setterInSuperClass(a) {
    setterInSuperClassField = a;
  }

  get getterInSuperClass => getterInSuperClassField;
}

class B extends A {
  get missingSetter => missingSetterField;
  get setterInSuperClass => setterInSuperClassField;

  set missingGetter(a) {
    missingGetterField = a;
  }

  set getterInSuperClass(a) {
    getterInSuperClassField = a;
  }

  get getterSetter => getterSetterField;
  set getterSetter(a) {
    getterSetterField = a;
  }

  operator [](index) => indexField[index];
  operator []=(index, value) {
    indexField[index] = value;
  }

  set missingSetter(a);
  get missingGetter;

  set missingAll(a);
  get missingAll;

  noSuchMethod(Invocation im) {
    String name = MirrorSystem.getName(im.memberName);
    if (name.startsWith('missingSetter')) {
      Expect.isTrue(im.isSetter);
      missingSetterField = im.positionalArguments[0];
    } else if (name.startsWith('missingGetter')) {
      Expect.isTrue(im.isGetter);
      return missingGetterField;
    } else if (name.startsWith('missingAll') && im.isGetter) {
      return missingAllField;
    } else if (name.startsWith('missingAll') && im.isSetter) {
      missingAllField = im.positionalArguments[0];
    } else {
      Expect.fail('Should not reach here');
    }
  }
}

class C extends B {
  test() {
    Expect.equals(42, super.missingSetter = 42);
    Expect.equals(42, super.missingSetter);
    Expect.equals(43, super.missingSetter += 1);
    Expect.equals(43, super.missingSetter);
    Expect.equals(43, super.missingSetter++);
    Expect.equals(44, super.missingSetter);

    Expect.equals(42, super.missingGetter = 42);
    Expect.equals(42, super.missingGetter);
    Expect.equals(43, super.missingGetter += 1);
    Expect.equals(43, super.missingGetter);
    Expect.equals(43, super.missingGetter++);
    Expect.equals(44, super.missingGetter);

    Expect.equals(42, super.setterInSuperClass = 42);
    Expect.equals(42, super.setterInSuperClass);
    Expect.equals(43, super.setterInSuperClass += 1);
    Expect.equals(43, super.setterInSuperClass);
    Expect.equals(43, super.setterInSuperClass++);
    Expect.equals(44, super.setterInSuperClass);

    Expect.equals(42, super.getterInSuperClass = 42);
    Expect.equals(42, super.getterInSuperClass);
    Expect.equals(43, super.getterInSuperClass += 1);
    Expect.equals(43, super.getterInSuperClass);
    Expect.equals(43, super.getterInSuperClass++);
    Expect.equals(44, super.getterInSuperClass);

    Expect.equals(42, super.missingAll = 42);
    Expect.equals(42, super.missingAll);
    Expect.equals(43, super.missingAll += 1);
    Expect.equals(43, super.missingAll);
    Expect.equals(43, super.missingAll++);
    Expect.equals(44, super.missingAll);

    Expect.equals(42, super[0] = 42);
    Expect.equals(42, super[0]);
    Expect.equals(43, super[0] += 1);
    Expect.equals(43, super[0]);
    Expect.equals(43, super[0]++);
    Expect.equals(44, super[0]);

    Expect.equals(2, super[0] = 2);
    Expect.equals(2, super[0]);
    Expect.equals(3, super[0] += 1);
    Expect.equals(3, super[0]);
    Expect.equals(3, super[0]++);
    Expect.equals(4, super[0]);
  }
}

main() {
  new C().test();
}
