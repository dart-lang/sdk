// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for the dart2js mirrors implementation that triggers the
// generation of the declarations of a class in the presence of call stubs
// and non-reflectable methods. For neither of the latter an instance mirror
// should be constructed and they should not be contained in declarations.
@MirrorsUsed(metaTargets: "Meta")
import "dart:mirrors";
import "package:expect/expect.dart";

class Meta {
  const Meta();
}

class A {
  @Meta()
  reflectableThing(int a, [int b = 9, int c = 42]) => a + b + c;
  nonReflectableThing(int a, [int b = 4, int c = 21]) => a + b + c;
}

tryCall(object, symbol, values, expected) {
  var mirror = reflect(object);
  var result = mirror.invoke(symbol, values).reflectee;
  Expect.equals(result, expected);
}

@NoInline()
@AssumeDynamic()
hide(x) => x;

main() {
  var a = hide(new A());
  // Make sure we statically have some calls to reflectableThing with 1, 2 and
  // 3 arguments so that stubs are generated.
  Expect.equals(1 + 9 + 42, a.reflectableThing(1));
  Expect.equals(1 + 5 + 42, a.reflectableThing(1, 5));
  Expect.equals(1 + 22 + 3, a.reflectableThing(1, 22, 3));
  // Try calling methods through reflection.
  tryCall(a, #reflectableThing, [1], 1 + 9 + 42);
  tryCall(a, #reflectableThing, [1, 5], 1 + 5 + 42);
  tryCall(a, #reflectableThing, [1, 22, 3], 1 + 22 + 3);
  Expect.throws(() => tryCall(a, #nonReflectableThing, [1], 1 + 4 + 21));
  Expect.throws(() => tryCall(a, #nonReflectableThing, [1, 5], 1 + 5 + 21));
  Expect.throws(() => tryCall(a, #nonReflectableThing, [1, 13, 7], 1 + 13 + 7));
  // Trigger generation of all declarations and check they only contain a
  // a single entry.
  var declarations = reflect(a).type.declarations;
  Expect.equals(1, declarations.keys.length);
  Expect.equals(#reflectableThing, declarations.keys.first);
}
