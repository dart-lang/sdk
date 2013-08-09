// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:mirrors";

import "package:expect/expect.dart";

class WannabeFunction {
  int call(int a, int b) => a + b;
  method(x) => x * x;
}

main() {
  Expect.isTrue(new WannabeFunction() is Function);

  ClosureMirror cm = reflect(new WannabeFunction());
  Expect.equals(7, cm.invoke(const Symbol("call"), [3,4]).reflectee);
  Expect.throws(() => cm.invoke(const Symbol("call"), [3]),
                (e) => e is NoSuchMethodError,
                "Wrong arity");
  Expect.equals(49, cm.invoke(const Symbol("method"), [7]).reflectee);
  Expect.throws(() => cm.invoke(const Symbol("method"), [3, 4]),
                (e) => e is NoSuchMethodError,
                "Wrong arity");
  Expect.equals(7, cm.apply([3,4]).reflectee);
  Expect.throws(() => cm.apply([3]),
                (e) => e is NoSuchMethodError,
                "Wrong arity");

  MethodMirror mm = cm.function;
  Expect.equals(const Symbol("call"), mm.simpleName);
  Expect.equals(reflectClass(WannabeFunction),
                mm.owner);
  Expect.isTrue(mm.isRegularMethod);
  Expect.equals(const Symbol("int"), mm.returnType.simpleName);
  Expect.equals(const Symbol("int"), mm.parameters[0].type.simpleName);
  Expect.equals(const Symbol("int"), mm.parameters[1].type.simpleName);

  ClassMirror km = cm.type;
  Expect.equals(reflectClass(WannabeFunction), km);
  Expect.equals(const Symbol("WannabeFunction"), km.simpleName);
  Expect.equals(mm, km.members[const Symbol("call")]);
  Expect.setEquals([const Symbol("call"), const Symbol("method")],
                   km.members.keys);
}
