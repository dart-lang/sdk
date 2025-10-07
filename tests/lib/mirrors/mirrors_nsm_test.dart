// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Library name is used in test.
library MirrorsTest;

import 'dart:mirrors';
import 'package:expect/expect.dart';

bool isNSMContainingFieldName(Object? e, String fieldName, bool isSetter) {
  if (e is! NoSuchMethodError) return false;
  String needle = fieldName;
  if (isSetter) needle += "=";
  return "$e".contains(needle) && !"$e".contains(needle + "=");
}

class A {
  final finalInstance = 0;
}

void testMessageContents() {
  var mirrors = currentMirrorSystem();
  var libMirror = mirrors.findLibrary(#MirrorsTest);
  Expect.throws(
    () => libMirror.invoke(#foo, []),
    (e) => isNSMContainingFieldName(e, "foo", false),
  );
  Expect.throws(
    () => libMirror.getField(#foo),
    (e) => isNSMContainingFieldName(e, "foo", false),
  );
  Expect.throws(
    () => libMirror.setField(#foo, null),
    (e) => isNSMContainingFieldName(e, "foo", true),
  );
  Expect.throws(
    () => libMirror.setField(#finalTopLevel, null),
    (e) => isNSMContainingFieldName(e, "finalTopLevel", true),
  );

  var classMirror = reflectClass(A);
  Expect.throws(
    () => classMirror.invoke(#foo, []),
    (e) => isNSMContainingFieldName(e, "foo", false),
  );
  Expect.throws(
    () => classMirror.getField(#foo),
    (e) => isNSMContainingFieldName(e, "foo", false),
  );
  Expect.throws(
    () => classMirror.setField(#foo, null),
    (e) => isNSMContainingFieldName(e, "foo", true),
  );
  Expect.throws(
    () => classMirror.setField(#finalStatic, null),
    (e) => isNSMContainingFieldName(e, "finalStatic", true),
  );

  var instanceMirror = reflect(A());
  Expect.throws(
    () => instanceMirror.invoke(#foo, []),
    (e) => isNSMContainingFieldName(e, "foo", false),
  );
  Expect.throws(
    () => instanceMirror.getField(#foo),
    (e) => isNSMContainingFieldName(e, "foo", false),
  );
  Expect.throws(
    () => instanceMirror.setField(#foo, null),
    (e) => isNSMContainingFieldName(e, "foo", true),
  );
  Expect.throws(
    () => instanceMirror.setField(#finalInstance, null),
    (e) => isNSMContainingFieldName(e, "finalInstance", true),
  );
}

void expectMatchingErrors(
  void Function() reflectiveAction,
  void Function() baseAction,
) {
  Object? reflectiveError, baseError;
  try {
    reflectiveAction();
  } catch (e) {
    reflectiveError = e;
  }

  try {
    baseAction();
  } catch (e) {
    baseError = e;
  }

  Expect.equals(baseError.toString(), reflectiveError.toString());
}

void testMatchingMessages() {
  var mirrors = currentMirrorSystem();

  var instanceMirror = reflect(A());
  var instance = A() as dynamic;
  expectMatchingErrors(
    () => instanceMirror.invoke(#foo, []),
    () => instance.foo(),
  );
  expectMatchingErrors(() => instanceMirror.getField(#foo), () => instance.foo);
  expectMatchingErrors(
    () => instanceMirror.setField(#foo, null),
    () => instance.foo = null,
  );
  expectMatchingErrors(
    () => instanceMirror.setField(#finalInstance, null),
    () => instance.finalInstance = null,
  );
}

void main() {
  testMessageContents();
  testMatchingMessages();
}
