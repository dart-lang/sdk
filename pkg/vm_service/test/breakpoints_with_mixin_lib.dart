// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

mixin class Foo {
  void foo() {
    print('I should be breakable!'); // LINE_A
  }
}

class Bar {
  void bar() {
    print('I should be breakable too!'); // LINE_B
  }
}

class Test1 extends Object with Foo {}

class Test2 extends Object with Foo {}

void code() {
  final Test1 test1 = Test1();
  test1.foo();
  final Test2 test2 = Test2();
  test2.foo();
  final Foo foo = Foo();
  foo.foo();
  final Bar bar = Bar();
  bar.bar();
  test1.foo();
  test2.foo();
  foo.foo();
  bar.bar();
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: code);
}
