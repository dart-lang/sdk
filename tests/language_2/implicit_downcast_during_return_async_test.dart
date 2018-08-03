// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import "package:expect/expect.dart";

class A {}

class B extends A {}

Future<B> f1(A a) async {
  return a as FutureOr<A>;
}

Future<B> f2(A a) async => a as FutureOr<A>;

main() async {
  Object b;
  A a = new B();
  b = await f1(a); // No error
  b = await f2(a); // No error
  a = new A();
  try {
    await f1(a);
    Expect.fail('await f1(a) should have thrown TypeError');
  } on TypeError {}
  try {
    await f2(a);
    Expect.fail('await f2(a) should have thrown TypeError');
  } on TypeError {}
}
