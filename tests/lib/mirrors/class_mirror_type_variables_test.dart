// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:mirrors";

import "package:expect/expect.dart";

class C<R,S,T> {
  R foo(R r) => r;
  S bar(S s) => s;
  T baz(T t) => t;
}

class NoTypeParams {}

main() {
  ClassMirror cm;
  cm = reflectClass(C);
  Expect.equals(3, cm.typeVariables.length);
  var values = cm.typeVariables;
  values.forEach((e) {
    Expect.equals(true, e is TypeVariableMirror);
  });
  Expect.equals(#R, values.elementAt(0).simpleName);
  Expect.equals(#S, values.elementAt(1).simpleName);
  Expect.equals(#T, values.elementAt(2).simpleName);
  cm = reflectClass(NoTypeParams);
  Expect.equals(cm.typeVariables.length, 0);
}
