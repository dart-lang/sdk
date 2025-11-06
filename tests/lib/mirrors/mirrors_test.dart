// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Retain library name, it"s used in test.
library MirrorsTest;

import "dart:mirrors";

import "package:expect/expect.dart";

var topLevelField;
u(a, b, c) => {"a": a, "b": b, "c": c};

class Class<T> {
  Class() {
    this.field = "default value";
  }
  Class.withInitialValue(this.field);
  var field;

  Class.generative(this.field);
  Class.redirecting(y) : this.generative(y * 2);
  factory Class.faktory(y) => Class.withInitialValue(y * 3);
  factory Class.redirectingFactory(y) = Class<T>.faktory;

  m(a, b, c) => {"a": a, "b": b, "c": c};
  noSuchMethod(invocation) => "DNU";

  static var staticField;
  static s(a, b, c) => {"a": a, "b": b, "c": c};
}

typedef Typedef();

void testInvoke() {
  var instance = Class();
  var instMirror = reflect(instance);

  Expect.mapEquals({
    "a": "A",
    "b": "B",
    "c": instance,
  }, instMirror.invoke(#m, ["A", "B", instance]).reflectee);
  Expect.equals("DNU", instMirror.invoke(#notDefined, []).reflectee);
  // Wrong arity.
  Expect.equals("DNU", instMirror.invoke(#m, []).reflectee);

  var classMirror = instMirror.type;
  Expect.mapEquals({
    "a": "A",
    "b": "B",
    "c": instance,
  }, classMirror.invoke(#s, ["A", "B", instance]).reflectee);
  Expect.throws(() => classMirror.invoke(#notDefined, []).reflectee);
  // Wrong arity.
  Expect.throws(() => classMirror.invoke(#s, []).reflectee);

  var libMirror = classMirror.owner as LibraryMirror;
  Expect.mapEquals({
    "a": "A",
    "b": "B",
    "c": instance,
  }, libMirror.invoke(#u, ["A", "B", instance]).reflectee);
  Expect.throws(() => libMirror.invoke(#notDefined, []).reflectee);
  // Wrong arity.
  Expect.throws(() => libMirror.invoke(#u, []).reflectee);
}

/// In dart2js, lists, numbers, and other objects are treated special
/// and their methods are invoked through a technique called interceptors.
///
/// These operations are not special on the VM. The test is retained mainly
/// as a sanity check.
void testIntercepted() {
  {
    var instance = 1;
    var instMirror = reflect(instance);

    Expect.equals("1", instMirror.invoke(#toString, []).reflectee);
  }

  var instance = <Object?>[];
  var instMirror = reflect(instance);
  instMirror.setField(#length, 44);
  var resultMirror = instMirror.getField(#length);
  Expect.equals(44, resultMirror.reflectee);
  Expect.equals(44, instance.length);

  Expect.equals(
    "[null, null, null, null, null, null, null, null, null, null,"
    " null, null, null, null, null, null, null, null, null, null,"
    " null, null, null, null, null, null, null, null, null, null,"
    " null, null, null, null, null, null, null, null, null, null,"
    " null, null, null, null]",
    instMirror.invoke(#toString, []).reflectee,
  );
}

void testFieldAccess(MirrorSystem mirrors) {
  var instance = Class();

  var libMirror = mirrors.findLibrary(#MirrorsTest);
  var classMirror = libMirror.declarations[#Class] as ClassMirror;
  var fieldMirror = classMirror.declarations[#field] as VariableMirror;

  Expect.equals(mirrors.dynamicType, fieldMirror.type);

  libMirror.setField(#topLevelField, [91]);
  Expect.listEquals([91], libMirror.getField(#topLevelField).reflectee);
  Expect.listEquals([91], topLevelField);
}

void testClosureMirrors() {
  // TODO(ahe): Test optional parameters (named or not).
  var closure = (x, y, z) {
    return x + y + z;
  };

  var mirror = reflect(closure) as ClosureMirror;

  var funcMirror = mirror.function;
  Expect.equals(3, funcMirror.parameters.length);

  Expect.equals(24, mirror.apply([7, 8, 9]).reflectee);
}

void testInvokeConstructor() {
  var classMirror = reflectClass(Class);

  var instanceMirror = classMirror.newInstance(Symbol.empty, []);
  Expect.isTrue(instanceMirror.reflectee is Class);
  Expect.equals("default value", instanceMirror.reflectee.field);

  instanceMirror = classMirror.newInstance(#withInitialValue, [45]);
  Expect.isTrue(instanceMirror.reflectee is Class);
  Expect.equals(45, instanceMirror.reflectee.field);

  instanceMirror = classMirror.newInstance(#generative, [7]);
  Expect.isTrue(instanceMirror.reflectee is Class);
  Expect.equals(7, instanceMirror.reflectee.field);

  instanceMirror = classMirror.newInstance(#redirecting, [8]);
  Expect.isTrue(instanceMirror.reflectee is Class);
  Expect.equals(16, instanceMirror.reflectee.field);

  instanceMirror = classMirror.newInstance(#faktory, [9]);
  Expect.isTrue(instanceMirror.reflectee is Class);
  Expect.equals(27, instanceMirror.reflectee.field);

  instanceMirror = classMirror.newInstance(#redirectingFactory, [10]);
  Expect.isTrue(instanceMirror.reflectee is Class);
  Expect.equals(30, instanceMirror.reflectee.field);
}

void testReflectClass() {
  var classMirror = reflectClass(Class);
  var symbolClassMirror = reflectClass(Symbol);
  var symbolMirror = symbolClassMirror.newInstance(Symbol.empty, [
    "withInitialValue",
  ]);
  var objectMirror = classMirror.newInstance(symbolMirror.reflectee, [1234]);
  Expect.isTrue(objectMirror.reflectee is Class);
  Expect.equals(1234, objectMirror.reflectee.field);
}

void testNames(MirrorSystem mirrors) {
  var libMirror = mirrors.findLibrary(#MirrorsTest);
  var classMirror = libMirror.declarations[#Class] as ClassMirror;
  var methodMirror = libMirror.declarations[#testNames] as MethodMirror;
  var variableMirror = classMirror.declarations[#field] as VariableMirror;

  Expect.equals(#MirrorsTest, libMirror.simpleName);
  Expect.equals(#MirrorsTest, libMirror.qualifiedName);

  Expect.equals(#Class, classMirror.simpleName);
  Expect.equals(#MirrorsTest.Class, classMirror.qualifiedName);

  TypeVariableMirror typeVariable = classMirror.typeVariables.single;
  Expect.equals(#X0, typeVariable.simpleName);
  Expect.equals(#MirrorsTest.Class.X0, typeVariable.qualifiedName);

  Expect.equals(#testNames, methodMirror.simpleName);
  Expect.equals(#MirrorsTest.testNames, methodMirror.qualifiedName);

  Expect.equals(#field, variableMirror.simpleName);
  Expect.equals(#MirrorsTest.Class.field, variableMirror.qualifiedName);
}

void testLibraryUri(Object? value, bool check(Uri uri)) {
  var valueMirror = reflect(value);
  ClassMirror valueClass = valueMirror.type;
  LibraryMirror valueLibrary = valueClass.owner as LibraryMirror;
  Uri uri = valueLibrary.uri;
  if (!uri.isScheme("https") || uri.host != "dartlang.org") {
    Expect.isTrue(check(uri));
  }
}

void main() {
  var mirrors = currentMirrorSystem();
  // Test reflective method invocation
  testInvoke();
  // Test intercepted objects
  testIntercepted();
  // Test field access
  testFieldAccess(mirrors);
  // Test closure mirrors
  testClosureMirrors();
  // Test invoke constructor
  testInvokeConstructor();
  // Test current library uri
  testLibraryUri(Class(), (Uri uri) => uri.path.endsWith("/mirrors_test.dart"));
  // Test dart library uri
  testLibraryUri("test", (Uri uri) => uri == Uri.parse("dart:core"));
  // Test simple and qualifiedName
  testNames(mirrors);
  // Test reflect type
  testReflectClass();
}
