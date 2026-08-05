// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

void code() {
  final Foo foo1 = Foo(); // LINE_A
  print(foo1.x);
  final Foo foo2 = Foo.named();
  print(foo2.x);
  final Foo foo3 = const Foo();
  print(foo3.x);
  final Foo foo4 = const Foo.named();
  print(foo4.x);
  final Foo foo5 = Foo.named2(1, 2, 3);
  print(foo5.x);
}

class Foo {
  final int x;

  const Foo() : x = 1;

  const Foo.named() : x = 2;

  const Foo.named2(int aaaaaaaa, int bbbbbbbbbb, int ccccccccccccc)
      : x = aaaaaaaa + bbbbbbbbbb + ccccccccccccc;
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: code);
}
