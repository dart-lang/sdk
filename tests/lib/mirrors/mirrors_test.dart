// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(rmacnak): Move the existing mirror tests here (a place for 
// cross-implementation tests).

#library("MirrorsTest.dart");
#import("dart:mirrors");
#import("../../../pkg/unittest/unittest.dart");

var topLevelField;

class Class {
  Class() { this.field = "default value"; }
  Class.withInitialValue(this.field);
  var field;
  static var staticField;
}

testFieldAccess(mirrors) {
  var instance = new Class();

  var libMirror = mirrors.libraries()["MirrorsTest.dart"];
  var classMirror = libMirror.classes()["Class"];
  var instMirror = mirrors.mirrorOf(instance);

  libMirror.setField('topLevelField', 42);
  var future = libMirror.getField('topLevelField');
  future.then(expectAsync1((resultMirror) {
    expect(resultMirror.reflectee, equals(42));
    expect(topLevelField, equals(42));   
  }));
  
  classMirror.setField('staticField', 43);
  future = classMirror.getField('staticField');
  future.then(expectAsync1((resultMirror) {
    expect(resultMirror.reflectee, equals(43));
    expect(Class.staticField, equals(43)); 
  }));

  instMirror.setField('field', 44);
  future = instMirror.getField('field');
  future.then(expectAsync1((resultMirror) {
    expect(resultMirror.reflectee, equals(44));
    expect(instance.field, equals(44)); 
  }));
}

testClosureMirrors(mirrors) {
  var closure = (x, y, z) { return x + y + z; };
  
  var mirror = mirrors.mirrorOf(closure);
  expect(mirror is ClosureMirror, equals(true));
  
  var funcMirror = mirror.function();
  expect(funcMirror is MethodMirror, equals(true));
  expect(funcMirror.parameters().length, equals(3));

  var future = mirror.apply([2, 4, 8]);
  future.then(expectAsync1((resultMirror) {
    expect(resultMirror.reflectee, equals(14));
  }));
}

testInvokeConstructor(mirrors) {
  var libMirror = mirrors.libraries()["MirrorsTest.dart"];
  var classMirror = libMirror.classes()["Class"];
  
  var future = classMirror.newInstance('', []);
  future.then(expectAsync1((resultMirror) {
    var instance = resultMirror.reflectee;
    expect(instance is Class, equals(true));
    expect(instance.field, equals("default value"));
  }));

  future = classMirror.newInstance('withInitialValue', [45]);
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

