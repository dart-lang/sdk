// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library lib;

@MirrorsUsed(targets: "lib")
import "dart:mirrors";

import "package:expect/expect.dart";

void voidFunc() {}

dynamicFunc1() {}

dynamic dynamicFunc2() {}

int intFunc() => 0;

class C<E> {
  E getE(E v) => v;
}

main() {
  MethodMirror mm;

  mm = (reflect(intFunc) as ClosureMirror).function;
  Expect.equals(true, mm.returnType is TypeMirror);
  Expect.equals(#int, mm.returnType.simpleName);
  Expect.equals(true, mm.returnType.owner is LibraryMirror);

  mm = (reflect(dynamicFunc1) as ClosureMirror).function;
  Expect.equals(true, mm.returnType is TypeMirror);
  Expect.equals(#dynamic, mm.returnType.simpleName);

  mm = (reflect(dynamicFunc2) as ClosureMirror).function;
  Expect.equals(true, mm.returnType is TypeMirror);
  Expect.equals(#dynamic, mm.returnType.simpleName);

  mm = (reflect(voidFunc) as ClosureMirror).function;
  Expect.equals(true, mm.returnType is TypeMirror);
  Expect.equals(const Symbol("void"), mm.returnType.simpleName);

  ClassMirror cm = reflectClass(C);
  mm = cm.declarations[#getE];
  Expect.equals(true, mm.returnType is TypeMirror);
  // The spec for this is ambiguous and needs to be updated before it is clear
  // what has to be returned.
  //Expect.equals("E", _n(mm.returnType.simpleName));
  Expect.equals(true, mm.owner is ClassMirror);
  Expect.equals(#C, mm.owner.simpleName);
}
