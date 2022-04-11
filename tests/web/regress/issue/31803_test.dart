// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

// Tests that the compiler doesn't crash on an annotation with fields

class Annotation {
  final Object obj;
  const Annotation(this.obj);
}

class UnusedClass {
  final Object x;

  const factory UnusedClass(UnusedArgumentClass x) = UnusedClass._;

  const UnusedClass._(this.x);
}

class UnusedArgumentClass {
  const UnusedArgumentClass();
}

@Annotation(const UnusedClass(arg))
class A {}

const arg = const UnusedArgumentClass();

main() {
  var a = new A();
  Expect.isTrue(a != null);
}
