// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that class finalizer correctly marks supertypes of superinterfaces
// as implemented.

import 'package:expect/expect.dart';

abstract class A {
  String method();
}

abstract class B extends A {}

class D extends A {
  String method() => "D";
}

class C implements B {
  String method() => "C";
}

String invoke(A a) {
  return a.method();
}

void main(List<String> args) {
  Expect.equals("C", invoke(args.contains('--use-d') ? new D() : new C()));
}
