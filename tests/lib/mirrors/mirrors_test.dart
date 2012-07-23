// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(rmacnak): Move the existing mirror tests here (a place for 
// cross-implementation tests).

#library("MirrorsTest.dart");
#import("dart:mirrors");
#import("../../../lib/unittest/unittest.dart");

var topLevelField;

class Class {
  var field;
  static var staticField;
}

testFieldAccess(mirrors) {
  var instance = new Class();

  var libMirror = mirrors.rootLibrary;
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

main() {
  var mirrors = currentMirrorSystem();

  test("Test field access", () { testFieldAccess(mirrors); });
}

