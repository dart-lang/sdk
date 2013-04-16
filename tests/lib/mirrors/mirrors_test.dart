// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(rmacnak): Move the existing mirror tests here (a place for
// cross-implementation tests).

library MirrorsTest;
import "dart:mirrors";
import "../../../pkg/unittest/lib/unittest.dart";

var topLevelField;

class Class<T> {
  Class() { this.field = "default value"; }
  Class.withInitialValue(this.field);
  var field;
  static var staticField;
  m(a, b, c) => {"a": a, "b": b, "c": c};
}

typedef Typedef();

testInvoke(mirrors) {
  var instance = new Class();
  var instMirror = reflect(instance);

  expect(instMirror.invoke(const Symbol("m"),['A', 'B', instance]).reflectee,
         equals({"a": 'A', "b":'B', "c": instance}));
}

testFieldAccess(mirrors) {
  var instance = new Class();

  var libMirror = mirrors.libraries[const Symbol("MirrorsTest")];
  var classMirror = libMirror.classes[const Symbol("Class")];
  var instMirror = reflect(instance);

  libMirror.setField(const Symbol('topLevelField'), [91]);
  expect(libMirror.getField(const Symbol('topLevelField')).reflectee,
         equals([91]));
  expect(topLevelField, equals([91]));

  libMirror.setFieldAsync(new Symbol('topLevelField'), 42);
  var future = libMirror.getFieldAsync(new Symbol('topLevelField'));
  future.then(expectAsync1((resultMirror) {
    expect(resultMirror.reflectee, equals(42));
    expect(topLevelField, equals(42));
  }));

  classMirror.setFieldAsync(new Symbol('staticField'), 43);
  future = classMirror.getFieldAsync(new Symbol('staticField'));
  future.then(expectAsync1((resultMirror) {
    expect(resultMirror.reflectee, equals(43));
    expect(Class.staticField, equals(43));
  }));

  instMirror.setFieldAsync(new Symbol('field'), 44);
  future = instMirror.getFieldAsync(new Symbol('field'));
  future.then(expectAsync1((resultMirror) {
    expect(resultMirror.reflectee, equals(44));
    expect(instance.field, equals(44));
  }));
}

testClosureMirrors(mirrors) {
  var closure = (x, y, z) { return x + y + z; };

  var mirror = reflect(closure);
  expect(mirror is ClosureMirror, equals(true));

  var funcMirror = mirror.function;
  expect(funcMirror is MethodMirror, equals(true));
  expect(funcMirror.parameters.length, equals(3));

  expect(mirror.apply([7, 8, 9]).reflectee, equals(24));

  var future = mirror.applyAsync([2, 4, 8]);
  future.then(expectAsync1((resultMirror) {
    expect(resultMirror.reflectee, equals(14));
  }));
}

testInvokeConstructor(mirrors) {
  var libMirror = mirrors.libraries[const Symbol("MirrorsTest")];
  var classMirror = libMirror.classes[const Symbol("Class")];

  var instanceMirror = classMirror.newInstance(const Symbol(''),[]);
  expect(instanceMirror.reflectee is Class, equals(true));
  expect(instanceMirror.reflectee.field, equals("default value"));

  instanceMirror = classMirror.newInstance(const Symbol('withInitialValue'),
                                           [45]);
  expect(instanceMirror.reflectee is Class, equals(true));
  expect(instanceMirror.reflectee.field, equals(45));

  var future = classMirror.newInstanceAsync(new Symbol(''), []);
  future.then(expectAsync1((resultMirror) {
    var instance = resultMirror.reflectee;
    expect(instance is Class, equals(true));
    expect(instance.field, equals("default value"));
  }));

  future = classMirror.newInstanceAsync(new Symbol('withInitialValue'), [45]);
  future.then(expectAsync1((resultMirror) {
    var instance = resultMirror.reflectee;
    expect(instance is Class, equals(true));
    expect(instance.field, equals(45));
  }));
}

testNames(mirrors) {
  var libMirror = mirrors.libraries[const Symbol('MirrorsTest')];
  var classMirror = libMirror.classes[const Symbol('Class')];
  var typedefMirror = libMirror.members[const Symbol('Typedef')];
  var methodMirror = libMirror.functions[const Symbol('testNames')];
  var variableMirror = classMirror.variables[const Symbol('field')];

  expect(libMirror.simpleName, equals(const Symbol('MirrorsTest')));
  expect(libMirror.qualifiedName, equals(const Symbol('MirrorsTest')));

  expect(classMirror.simpleName, equals(const Symbol('Class')));
  expect(classMirror.qualifiedName, equals(const Symbol('MirrorsTest.Class')));

  TypeVariableMirror typeVariable = classMirror.typeVariables.values.single;
  expect(typeVariable.simpleName, equals(const Symbol('T')));
  expect(typeVariable.qualifiedName,
         equals(const Symbol('MirrorsTest.Class.T')));

  expect(typedefMirror.simpleName, equals(const Symbol('Typedef')));
  expect(typedefMirror.qualifiedName,
         equals(const Symbol('MirrorsTest.Typedef')));

  expect(methodMirror.simpleName, equals(const Symbol('testNames')));
  expect(methodMirror.qualifiedName,
         equals(const Symbol('MirrorsTest.testNames')));

  expect(variableMirror.simpleName, equals(const Symbol('field')));
  expect(variableMirror.qualifiedName,
         equals(const Symbol('MirrorsTest.Class.field')));
}

main() {
  var mirrors = currentMirrorSystem();
  test("Test reflective method invocation", () { testInvoke(mirrors); });
  test("Test field access", () { testFieldAccess(mirrors); });
  test("Test closure mirrors", () { testClosureMirrors(mirrors); });
  test("Test invoke constructor", () { testInvokeConstructor(mirrors); });
  test("Test simple and qualifiedName", () { testNames(mirrors); });
}
