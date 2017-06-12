// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library lib;

@MirrorsUsed(targets: "lib")
import "dart:mirrors";

import "package:expect/expect.dart";

membersOf(ClassMirror cm) {
  var result = new Map();
  cm.declarations.forEach((k, v) {
    if (v is MethodMirror && !v.isConstructor) result[k] = v;
    if (v is VariableMirror) result[k] = v;
  });
  return result;
}

class WannabeFunction {
  int call(int a, int b) => a + b;
  method(x) => x * x;
}

main() {
  Expect.isTrue(new WannabeFunction() is Function);

  ClosureMirror cm = reflect(new WannabeFunction());
  Expect.equals(7, cm.invoke(#call, [3, 4]).reflectee);
  Expect.throws(() => cm.invoke(#call, [3]), (e) => e is NoSuchMethodError,
      "Wrong arity");
  Expect.equals(49, cm.invoke(#method, [7]).reflectee);
  Expect.throws(() => cm.invoke(#method, [3, 4]), (e) => e is NoSuchMethodError,
      "Wrong arity");
  Expect.equals(7, cm.apply([3, 4]).reflectee);
  Expect.throws(
      () => cm.apply([3]), (e) => e is NoSuchMethodError, "Wrong arity");

  MethodMirror mm = cm.function;
  Expect.equals(#call, mm.simpleName);
  Expect.equals(reflectClass(WannabeFunction), mm.owner);
  Expect.isTrue(mm.isRegularMethod);
  Expect.equals(#int, mm.returnType.simpleName);
  Expect.equals(#int, mm.parameters[0].type.simpleName);
  Expect.equals(#int, mm.parameters[1].type.simpleName);

  ClassMirror km = cm.type;
  Expect.equals(reflectClass(WannabeFunction), km);
  Expect.equals(#WannabeFunction, km.simpleName);
  Expect.equals(mm, km.declarations[#call]);
  Expect.setEquals([#call, #method], membersOf(km).keys);
}
