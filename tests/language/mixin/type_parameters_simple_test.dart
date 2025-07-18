// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "package:expect/variations.dart";

class S {}

mixin M1<X> {
  m1() => X;
}

mixin M2<Y> {
  m2() => Y;
}

class A<T> extends S with M1<T>, M2<T> {}

main() {
  // In dart2wasm's `--minify` mode we do not special case `bool/int/String` all
  // type names will get minified.
  if (!readableTypeStrings &&
      const bool.fromEnvironment('dart.tool.dart2wasm')) {
    return;
  }

  var a = new A<int>();
  // Getting "int" when calling toString() on the int type is not required.
  // However, we want to keep the original names for the most common core types
  // so we make sure to handle these specifically in the compiler.
  Expect.equals("int", a.m1().toString());
  Expect.equals("int", a.m2().toString());
  var a2 = new A<String>();
  Expect.equals("String", a2.m1().toString());
  Expect.equals("String", a2.m2().toString());
}
