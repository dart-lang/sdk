// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library MirrorsTest;

import 'dart:mirrors';
import 'package:expect/expect.dart';

bool isNSMContainingFieldName(e, String fieldName, bool isSetter) {
  print(e);
  if (e is! NoSuchMethodError) return false;
  String needle = fieldName;
  if (isSetter) needle += "=";
  return "$e".contains(needle) && ! "$e".contains(needle + "=");
}

final finalTopLevel = 0;
class A {
  final finalInstance = 0;
  static final finalStatic = 0;
}

testMessageContents() {
  var mirrors = currentMirrorSystem();
  var libMirror = mirrors.findLibrary(#MirrorsTest);
  Expect.throws(() => libMirror.invoke(#foo, []),
                (e) => isNSMContainingFieldName(e, "foo", false));
  Expect.throws(() => libMirror.getField(#foo),
                (e) => isNSMContainingFieldName(e, "foo", false));
  Expect.throws(() => libMirror.setField(#foo, null),
                (e) => isNSMContainingFieldName(e, "foo", true));
  Expect.throws(() => libMirror.setField(#finalTopLevel, null),
                (e) => isNSMContainingFieldName(e, "finalTopLevel", true));

  var classMirror = reflectClass(A);
  Expect.throws(() => classMirror.invoke(#foo, []),
                (e) => isNSMContainingFieldName(e, "foo", false));
  Expect.throws(() => classMirror.getField(#foo),
                (e) => isNSMContainingFieldName(e, "foo", false));
  Expect.throws(() => classMirror.setField(#foo, null),
                (e) => isNSMContainingFieldName(e, "foo", true));
  Expect.throws(() => classMirror.setField(#finalStatic, null),
                (e) => isNSMContainingFieldName(e, "finalStatic", true));

  var instanceMirror = reflect(new A());
  Expect.throws(() => instanceMirror.invoke(#foo, []),
                (e) => isNSMContainingFieldName(e, "foo", false));
  Expect.throws(() => instanceMirror.getField(#foo),
                (e) => isNSMContainingFieldName(e, "foo", false));
  Expect.throws(() => instanceMirror.setField(#foo, null),
                (e) => isNSMContainingFieldName(e, "foo", true));
  Expect.throws(() => instanceMirror.setField(#finalInstance, null),
                (e) => isNSMContainingFieldName(e, "finalInstance", true));
}

expectMatchingErrors(reflectiveAction, baseAction) {
  var reflectiveError, baseError;
  try {
    reflectiveAction();
  } catch(e) {
    reflectiveError = e;
  }
  try {
    baseAction();
  } catch(e) {
    baseError = e;
  }
  print("\n==Base==\n $baseError");
  print("\n==Reflective==\n $reflectiveError");
  Expect.stringEquals(baseError.toString(), reflectiveError.toString());
}

testMatchingMessages() {
  var mirrors = currentMirrorSystem();
  var libMirror = mirrors.findLibrary(#MirrorsTest);
  expectMatchingErrors(() => libMirror.invoke(#foo, []),
                       () => foo());
  expectMatchingErrors(() => libMirror.getField(#foo),
                       () => foo);
  expectMatchingErrors(() => libMirror.setField(#foo, null),
                       () => foo= null);
  expectMatchingErrors(() => libMirror.setField(#finalTopLevel, null),
                       () => finalTopLevel= null);

  var classMirror = reflectClass(A);
  expectMatchingErrors(() => classMirror.invoke(#foo, []),
                       () => A.foo());
  expectMatchingErrors(() => classMirror.getField(#foo),
                       () => A.foo);
  expectMatchingErrors(() => classMirror.setField(#foo, null),
                       () => A.foo= null);
  expectMatchingErrors(() => classMirror.setField(#finalStatic, null),
                       () => A.finalStatic= null);

  var instanceMirror = reflect(new A());
  expectMatchingErrors(() => instanceMirror.invoke(#foo, []),
                       () => new A().foo());
  expectMatchingErrors(() => instanceMirror.getField(#foo),
                       () => new A().foo);
  expectMatchingErrors(() => instanceMirror.setField(#foo, null),
                       () => new A().foo= null);
  expectMatchingErrors(() => instanceMirror.setField(#finalInstance, null),
                       () => new A().finalInstance= null);
}

main() {
  testMessageContents();
  testMatchingMessages(); /// dart2js: ok
}