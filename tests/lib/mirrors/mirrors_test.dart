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

testInstanceFieldAccess(mirrors) {
  var instance = new Class();
  var instMirror = reflect(instance);

  instMirror.setFieldAsync(const Symbol('field'), 44);
  instMirror.getFieldAsync(const Symbol('field')).then(
      expectAsync1((resultMirror) {
        expect(resultMirror.reflectee, equals(44));
        expect(instance.field, equals(44));
      }));
}

/// In dart2js, lists, numbers, and other objects are treated special
/// and their methods are invoked through a techique called interceptors.
testIntercepted(mirrors) {
  var instance = 1;
  var instMirror = reflect(instance);

  expect(instMirror.invoke(const Symbol('toString'), []).reflectee,
         equals('1'));

  instance = [];
  instMirror = reflect(instance);
  instMirror.setField(const Symbol('length'), 44);
  var resultMirror = instMirror.getField(const Symbol('length'));
  expect(resultMirror.reflectee, equals(44));
  expect(instance.length, equals(44));

  expect(instMirror.invoke(const Symbol('toString'), []).reflectee,
         equals('[null, null, null, null, null, null, null, null, null, null,'
                ' null, null, null, null, null, null, null, null, null, null,'
                ' null, null, null, null, null, null, null, null, null, null,'
                ' null, null, null, null, null, null, null, null, null, null,'
                ' null, null, null, null]'));
}

testFieldAccess(mirrors) {
  var instance = new Class();

  var libMirror = mirrors.findLibrary(const Symbol("MirrorsTest")).single;
  var classMirror = libMirror.classes[const Symbol("Class")];
  var instMirror = reflect(instance);
  var fieldMirror = classMirror.members[const Symbol('field')];

  expect(fieldMirror is VariableMirror, isTrue);
  expect(fieldMirror.type, equals(mirrors.dynamicType));

  libMirror.setField(const Symbol('topLevelField'), [91]);
  expect(libMirror.getField(const Symbol('topLevelField')).reflectee,
         equals([91]));
  expect(topLevelField, equals([91]));

  libMirror.setFieldAsync(const Symbol('topLevelField'), 42);
  var future = libMirror.getFieldAsync(const Symbol('topLevelField'));
  future.then(expectAsync1((resultMirror) {
    expect(resultMirror.reflectee, equals(42));
    expect(topLevelField, equals(42));
  }));

  classMirror.setFieldAsync(const Symbol('staticField'), 43);
  future = classMirror.getFieldAsync(const Symbol('staticField'));
  future.then(expectAsync1((resultMirror) {
    expect(resultMirror.reflectee, equals(43));
    expect(Class.staticField, equals(43));
  }));

  instMirror.setFieldAsync(const Symbol('field'), 44);
  future = instMirror.getFieldAsync(const Symbol('field'));
  future.then(expectAsync1((resultMirror) {
    expect(resultMirror.reflectee, equals(44));
    expect(instance.field, equals(44));
  }));
}

testClosureMirrors(mirrors) {
  // TODO(ahe): Test optional parameters (named or not).
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
  var classMirror = reflectClass(Class);

  var instanceMirror = classMirror.newInstance(const Symbol(''),[]);
  expect(instanceMirror.reflectee is Class, equals(true));
  expect(instanceMirror.reflectee.field, equals("default value"));

  instanceMirror = classMirror.newInstance(const Symbol('withInitialValue'),
                                           [45]);
  expect(instanceMirror.reflectee is Class, equals(true));
  expect(instanceMirror.reflectee.field, equals(45));

  var future = classMirror.newInstanceAsync(const Symbol(''), []);
  future.then(expectAsync1((resultMirror) {
    var instance = resultMirror.reflectee;
    expect(instance is Class, equals(true));
    expect(instance.field, equals("default value"));
  }));

  future = classMirror.newInstanceAsync(const Symbol('withInitialValue'), [45]);
  future.then(expectAsync1((resultMirror) {
    var instance = resultMirror.reflectee;
    expect(instance is Class, equals(true));
    expect(instance.field, equals(45));
  }));
}

testReflectClass(mirrors) {
  var classMirror = reflectClass(Class);
  expect(classMirror is ClassMirror, equals(true));
  var symbolClassMirror = reflectClass(Symbol);
  var symbolMirror = symbolClassMirror.newInstance(const Symbol(''),
                                                   ['withInitialValue']);
  var objectMirror = classMirror.newInstance(symbolMirror.reflectee,[1234]);
  expect(objectMirror.reflectee is Class, equals(true));
  expect(objectMirror.reflectee.field, equals(1234));
}

testNames(mirrors, isDart2js) {
  var libMirror = mirrors.findLibrary(const Symbol("MirrorsTest")).single;
  var classMirror = libMirror.classes[const Symbol('Class')];
  var typedefMirror = libMirror.members[const Symbol('Typedef')];
  var methodMirror = libMirror.functions[const Symbol('testNames')];
  var variableMirror = classMirror.variables[const Symbol('field')];

  expect(libMirror.simpleName, equals(const Symbol('MirrorsTest')));
  expect(libMirror.qualifiedName, equals(const Symbol('MirrorsTest')));

  expect(classMirror.simpleName, equals(const Symbol('Class')));
  expect(classMirror.qualifiedName, equals(const Symbol('MirrorsTest.Class')));

  if (!isDart2js) { // TODO(ahe): Implement this in dart2js.
    TypeVariableMirror typeVariable = classMirror.typeVariables.values.single;
    expect(typeVariable.simpleName, equals(const Symbol('T')));
    expect(typeVariable.qualifiedName,
           equals(const Symbol('MirrorsTest.Class.T')));

    expect(typedefMirror.simpleName, equals(const Symbol('Typedef')));
    expect(typedefMirror.qualifiedName,
           equals(const Symbol('MirrorsTest.Typedef')));
  }

  expect(methodMirror.simpleName, equals(const Symbol('testNames')));
  expect(methodMirror.qualifiedName,
         equals(const Symbol('MirrorsTest.testNames')));

  expect(variableMirror.simpleName, equals(const Symbol('field')));
  expect(variableMirror.qualifiedName,
         equals(const Symbol('MirrorsTest.Class.field')));
}

testLibraryUri(var value, bool check(Uri)) {
  var valueMirror = reflect(value);
  ClassMirror valueClass = valueMirror.type;
  LibraryMirror valueLibrary = valueClass.owner;
  expect(check(valueLibrary.uri), isTrue);
}

mainWithArgument({bool isDart2js: false, bool isMinified: false}) {
  var mirrors = currentMirrorSystem();
  test("Test reflective method invocation", () { testInvoke(mirrors); });
  if (isMinified) return;
  test("Test instance field access", () { testInstanceFieldAccess(mirrors); });
  test('Test intercepted objects', () { testIntercepted(mirrors); });
  test("Test field access", () { testFieldAccess(mirrors); });
  test("Test closure mirrors", () { testClosureMirrors(mirrors); });
  test("Test invoke constructor", () { testInvokeConstructor(mirrors); });
  test("Test current library uri", () {
    testLibraryUri(new Class(),
      (Uri uri) => uri.path.endsWith('/mirrors_test.dart'));
  });
  test("Test dart library uri", () {
    testLibraryUri("test", (Uri uri) => uri == Uri.parse('dart:core'));
  });
  test("Test simple and qualifiedName", () { testNames(mirrors, isDart2js); });
  if (isDart2js) return; // TODO(ahe): Remove this line.
  test("Test reflect type", () { testReflectClass(mirrors); });
}

main() {
  mainWithArgument();
}
