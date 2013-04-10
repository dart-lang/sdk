// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(rmacnak): Move the existing mirror tests here (a place for 
// cross-implementation tests).

library MirrorsTest;
import "dart:mirrors";
import "../../../pkg/unittest/lib/unittest.dart";

var topLevelField;

class Class {
  Class() { this.field = "default value"; }
  Class.withInitialValue(this.field);
  var field;
  static var staticField;
}

testFieldAccess(mirrors) {
  var instance = new Class();

  var libMirror = mirrors.libraries["MirrorsTest"];
  var classMirror = libMirror.classes["Class"];
  var instMirror = reflect(instance);

  libMirror.setFieldAsync('topLevelField', 42);
  var future = libMirror.getFieldAsync('topLevelField');
  future.then(expectAsync1((resultMirror) {
    expect(resultMirror.reflectee, equals(42));
    expect(topLevelField, equals(42));   
  }));
  
  classMirror.setFieldAsync('staticField', 43);
  future = classMirror.getFieldAsync('staticField');
  future.then(expectAsync1((resultMirror) {
    expect(resultMirror.reflectee, equals(43));
    expect(Class.staticField, equals(43)); 
  }));

  instMirror.setFieldAsync('field', 44);
  future = instMirror.getFieldAsync('field');
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

  var future = mirror.applyAsync([2, 4, 8]);
  future.then(expectAsync1((resultMirror) {
    expect(resultMirror.reflectee, equals(14));
  }));
}

testInvokeConstructor(mirrors) {
  var libMirror = mirrors.libraries["MirrorsTest"];
  var classMirror = libMirror.classes["Class"];
  
  var future = classMirror.newInstanceAsync('', []);
  future.then(expectAsync1((resultMirror) {
    var instance = resultMirror.reflectee;
    expect(instance is Class, equals(true));
    expect(instance.field, equals("default value"));
  }));

  future = classMirror.newInstanceAsync('withInitialValue', [45]);
  future.then(expectAsync1((resultMirror) {
    var instance = resultMirror.reflectee;
    expect(instance is Class, equals(true));
    expect(instance.field, equals(45));
  }));
}

main() {
  var mirrors = currentMirrorSystem();

  test("Test field access", () { testFieldAccess(mirrors); });
  test("Test closure mirrors", () { testClosureMirrors(mirrors); });
  test("Test invoke constructor", () { testInvokeConstructor(mirrors); });
}

