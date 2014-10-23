// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library MirrorsTest;

import 'dart:mirrors';

import '../../light_unittest.dart';

bool isDart2js = false; // TODO(ahe): Remove this field.

var topLevelField;
u(a, b, c) => {"a": a, "b": b, "c": c};
_v(a, b) => a + b;

class Class<T> {
  Class() { this.field = "default value"; }
  Class.withInitialValue(this.field);
  var field;

  Class.generative(this.field);
  Class.redirecting(y) : this.generative(y*2);
  factory Class.faktory(y) => new Class.withInitialValue(y*3);
  factory Class.redirectingFactory(y) = Class.faktory;

  m(a, b, c) => {"a": a, "b": b, "c": c};
  _n(a, b) => a + b;
  noSuchMethod(invocation) => "DNU";

  static var staticField;
  static s(a, b, c) => {"a": a, "b": b, "c": c};
  static _t(a, b) => a + b;
}

typedef Typedef();

testInvoke(mirrors) {
  var instance = new Class();
  var instMirror = reflect(instance);

  expect(instMirror.invoke(#m, ['A', 'B', instance]).reflectee,
         equals({"a": 'A', "b":'B', "c": instance}));
  expect(instMirror.invoke(#notDefined, []).reflectee,
         equals("DNU"));
  expect(instMirror.invoke(#m, []).reflectee,
         equals("DNU"));  // Wrong arity.

  var classMirror = instMirror.type;
  expect(classMirror.invoke(#s, ['A', 'B', instance]).reflectee,
         equals({"a": 'A', "b":'B', "c": instance}));
  expect(() => classMirror.invoke(#notDefined, []).reflectee,
         throws);
  expect(() => classMirror.invoke(#s, []).reflectee,
         throws);  // Wrong arity.

  var libMirror = classMirror.owner;
  expect(libMirror.invoke(#u, ['A', 'B', instance]).reflectee,
         equals({"a": 'A', "b":'B', "c": instance}));
  expect(() => libMirror.invoke(#notDefined, []).reflectee,
         throws);
  expect(() => libMirror.invoke(#u, []).reflectee,
         throws);  // Wrong arity.
}

/// In dart2js, lists, numbers, and other objects are treated special
/// and their methods are invoked through a techique called interceptors.
testIntercepted(mirrors) {
  var instance = 1;
  var instMirror = reflect(instance);

  expect(instMirror.invoke(#toString, []).reflectee,
         equals('1'));

  instance = [];
  instMirror = reflect(instance);
  instMirror.setField(#length, 44);
  var resultMirror = instMirror.getField(#length);
  expect(resultMirror.reflectee, equals(44));
  expect(instance.length, equals(44));

  expect(instMirror.invoke(#toString, []).reflectee,
         equals('[null, null, null, null, null, null, null, null, null, null,'
                ' null, null, null, null, null, null, null, null, null, null,'
                ' null, null, null, null, null, null, null, null, null, null,'
                ' null, null, null, null, null, null, null, null, null, null,'
                ' null, null, null, null]'));
}

testFieldAccess(mirrors) {
  var instance = new Class();

  var libMirror = mirrors.findLibrary(#MirrorsTest);
  var classMirror = libMirror.declarations[#Class];
  var instMirror = reflect(instance);
  var fieldMirror = classMirror.declarations[#field];
  var future;

  expect(fieldMirror is VariableMirror, isTrue);
  expect(fieldMirror.type, equals(mirrors.dynamicType));

  libMirror.setField(#topLevelField, [91]);
  expect(libMirror.getField(#topLevelField).reflectee,
         equals([91]));
  expect(topLevelField, equals([91]));
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
}

testInvokeConstructor(mirrors) {
  var classMirror = reflectClass(Class);

  var instanceMirror = classMirror.newInstance(const Symbol(''),[]);
  expect(instanceMirror.reflectee is Class, equals(true));
  expect(instanceMirror.reflectee.field, equals("default value"));

  instanceMirror = classMirror.newInstance(#withInitialValue,
                                           [45]);
  expect(instanceMirror.reflectee is Class, equals(true));
  expect(instanceMirror.reflectee.field, equals(45));


  instanceMirror = classMirror.newInstance(#generative,
                                           [7]);
  expect(instanceMirror.reflectee is Class, equals(true));
  expect(instanceMirror.reflectee.field, equals(7));

  instanceMirror = classMirror.newInstance(#redirecting,
                                           [8]);
  expect(instanceMirror.reflectee is Class, equals(true));
  expect(instanceMirror.reflectee.field, equals(16));

  instanceMirror = classMirror.newInstance(#faktory,
                                           [9]);
  expect(instanceMirror.reflectee is Class, equals(true));
  expect(instanceMirror.reflectee.field, equals(27));

  instanceMirror = classMirror.newInstance(#redirectingFactory,
                                           [10]);
  expect(instanceMirror.reflectee is Class, equals(true));
  expect(instanceMirror.reflectee.field, equals(30));
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

testNames(mirrors) {
  var libMirror = mirrors.findLibrary(#MirrorsTest);
  var classMirror = libMirror.declarations[#Class];
  var typedefMirror = libMirror.declarations[#Typedef];
  var methodMirror = libMirror.declarations[#testNames];
  var variableMirror = classMirror.declarations[#field];

  expect(libMirror.simpleName, equals(#MirrorsTest));
  expect(libMirror.qualifiedName, equals(#MirrorsTest));

  expect(classMirror.simpleName, equals(#Class));
  expect(classMirror.qualifiedName, equals(#MirrorsTest.Class));

  TypeVariableMirror typeVariable = classMirror.typeVariables.single;
  expect(typeVariable.simpleName, equals(#T));
  expect(typeVariable.qualifiedName,
      equals(const Symbol('MirrorsTest.Class.T')));

  if (!isDart2js) { // TODO(ahe): Implement this in dart2js.
    expect(typedefMirror.simpleName, equals(#Typedef));
    expect(typedefMirror.qualifiedName,
           equals(const Symbol('MirrorsTest.Typedef')));

    var typedefMirrorDeNovo = reflectType(Typedef);
    expect(typedefMirrorDeNovo.simpleName, equals(#Typedef));
    expect(typedefMirrorDeNovo.qualifiedName,
           equals(const Symbol('MirrorsTest.Typedef')));
  }

  expect(methodMirror.simpleName, equals(#testNames));
  expect(methodMirror.qualifiedName,
         equals(const Symbol('MirrorsTest.testNames')));

  expect(variableMirror.simpleName, equals(#field));
  expect(variableMirror.qualifiedName,
         equals(const Symbol('MirrorsTest.Class.field')));
}

testLibraryUri(var value, bool check(Uri)) {
  var valueMirror = reflect(value);
  ClassMirror valueClass = valueMirror.type;
  LibraryMirror valueLibrary = valueClass.owner;
  Uri uri = valueLibrary.uri;
  if (uri.scheme != "https" ||
      uri.host != "dartlang.org" ||
      uri.path != "/dart2js-stripped-uri") {
    expect(check(uri), isTrue);
  }
}

main() {
  var mirrors = currentMirrorSystem();
  test("Test reflective method invocation", () { testInvoke(mirrors); });
  test('Test intercepted objects', () { testIntercepted(mirrors); });
  test("Test field access", () { testFieldAccess(mirrors); });
  test("Test closure mirrors", () { testClosureMirrors(mirrors); });
  test("Test invoke constructor", () { testInvokeConstructor(mirrors); });
  test("Test current library uri", () {
    testLibraryUri(new Class(),
      // TODO(floitsch): change this to "/mirrors_test.dart" when
      // dart2js_mirrors_test.dart has been removed.
      (Uri uri) => uri.path.endsWith('mirrors_test.dart'));
  });
  test("Test dart library uri", () {
    testLibraryUri("test",
                   (Uri uri) {
                     if (uri == Uri.parse('dart:core')) return true;
                     // TODO(floitsch): do we want to fake the interceptors to
                     // be in dart:core?
                     return (uri == Uri.parse('dart:_interceptors'));
                   });
  });
  test("Test simple and qualifiedName", () { testNames(mirrors); });
  test("Test reflect type", () { testReflectClass(mirrors); });
}
