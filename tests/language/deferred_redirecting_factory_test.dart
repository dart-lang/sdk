// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library main;

import "deferred_redirecting_factory_lib1.dart" deferred as lib1;
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

class C {
  String get foo => "main";
  C();
  factory C.a() = lib1.C;
  factory C.b() = lib1.C.a;
}

test1() async {
  Expect.throws(() {
    new C.a();
  });
  Expect.throws(() {
    new C.b();
  });
}

test2() async {
  await lib1.loadLibrary();
  Expect.equals("lib1", new C.a().foo);
  Expect.throws(() {
    new C.b();
  });
}

test3() async {
  await lib1.loadLibrary();
  await lib1.loadLib2();
  Expect.equals("lib1", new C.a().foo);
  Expect.equals("lib2", new C.b().foo);
}

test() async {
  await test1();
  await test2();
  await test3();
}

void main() {
  asyncStart();
  test().then((_) => asyncEnd());
}
