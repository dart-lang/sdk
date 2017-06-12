// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.private_types;

@MirrorsUsed(targets: "test.private_types")
import 'dart:mirrors';
import 'package:expect/expect.dart';

typedef int _F(int i);

class _C<_T> {}

typedef int F(int i);

class C<T> {}

main() {
  Expect.isTrue(reflectType(_F).isPrivate);
  Expect.isFalse((reflectType(_F) as TypedefMirror).referent.isPrivate);
  Expect.isTrue(reflectType(_C).isPrivate);
  Expect.isTrue(reflectClass(_C).typeVariables.single.isPrivate);

  Expect.isFalse(reflectType(F).isPrivate);
  Expect.isFalse((reflectType(F) as TypedefMirror).referent.isPrivate);
  Expect.isFalse(reflectType(C).isPrivate);
  Expect.isFalse(reflectClass(C).typeVariables.single.isPrivate);

  Expect.isFalse(reflectType(dynamic).isPrivate);
  Expect.isFalse(currentMirrorSystem().dynamicType.isPrivate);
  Expect.isFalse(currentMirrorSystem().voidType.isPrivate);
}
