// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:mirrors";
import "package:expect/expect.dart";

extension type T1(int value) {}

extension type T2(int value) {
  T2 add(int arg) => T2(value + arg);
}

extension type T3(int value) implements int {
  static T3 staticAdd(T3 a, int b) => T3(a + b);
  static String staticField = 'hi';
}

class C {
  final int value;
  C(this.value);
  C add(int arg) => C(value + arg);
}

checkIsExtensionTypeMember(closure, kind, simpleName) {
  var closureMirror = reflect(closure) as ClosureMirror;
  var methodMirror = closureMirror.function;
  Expect.equals(Symbol(simpleName), methodMirror.simpleName);
  Expect.equals(
      kind, methodMirror.isExtensionTypeMember, "isExtensionTypeMember");
}

String? getExtensionTypeName(sym) {
  final extensionTypeNames = {'T1', 'T2', 'T3'};
  for (final extTypeName in extensionTypeNames) {
    if (MirrorSystem.getName(sym).startsWith(extTypeName)) {
      return extTypeName;
    }
  }
  return null;
}

void testExtensionTypeMembers(sym, mirror) {
  String? extensionTypeName = getExtensionTypeName(sym);
  if (mirror is MethodMirror) {
    final methodMirror = mirror as MethodMirror;
    if (extensionTypeName != null) {
      Expect.equals(
          true, methodMirror.isExtensionTypeMember, "isExtensionTypeMember");
      Expect.isTrue(
          methodMirror.simpleName.toString().contains('$extensionTypeName.'));
    } else {
      Expect.equals(
          false, methodMirror.isExtensionTypeMember, "isExtensionTypeMember");
    }
  } else if (mirror is VariableMirror) {
    var variableMirror = mirror as VariableMirror;
    if (extensionTypeName != null) {
      Expect.equals(
          true, variableMirror.isExtensionTypeMember, "isExtensionTypeMember");
    } else {
      Expect.equals(
          false, variableMirror.isExtensionTypeMember, "isExtensionTypeMember");
    }
  }
}

main() {
  checkIsExtensionTypeMember(C(42).add, false, 'add');
  checkIsExtensionTypeMember(T2(42).add, true, 'T2.add');
  checkIsExtensionTypeMember(T3.staticAdd, true, 'T3.staticAdd');

  var libraryMirror = reflectClass(C).owner as LibraryMirror;
  libraryMirror.declarations.forEach(testExtensionTypeMembers);
}
