// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.type_variable_owner;

import "dart:mirrors";

import "package:expect/expect.dart";

class C<T> {}

typedef bool Predicate<T>(T t);

main() {
  Expect.isFalse(reflectType(C).typeVariables.single.isStatic);
  Expect.isFalse(reflectType(Predicate).typeVariables.single.isStatic);
}
