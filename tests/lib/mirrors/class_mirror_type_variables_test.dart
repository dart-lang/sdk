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
  Expect.equals(true, cm.typeVariables.containsKey(const Symbol("R")));
  Expect.equals(true, cm.typeVariables.containsKey(const Symbol("S")));
  Expect.equals(true, cm.typeVariables.containsKey(const Symbol("T")));
  var values = cm.typeVariables.values;
  values.forEach((e) {
    Expect.equals(true, e is TypeVariableMirror);
  });
  Expect.equals(const Symbol("R"), values.elementAt(0).simpleName);
  Expect.equals(const Symbol("S"), values.elementAt(1).simpleName);
  Expect.equals(const Symbol("T"), values.elementAt(2).simpleName);
  cm = reflectClass(NoTypeParams);
  Expect.equals(cm.typeVariables.length, 0);
}
