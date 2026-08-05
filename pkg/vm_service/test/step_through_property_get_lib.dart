// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

void code() {
  final bar = Bar();
  bar.doStuff();
}

class Foo {
  final List<String> data1;

  Foo() : data1 = ['a', 'b', 'c'];

  void doStuff() {
    print(data1);
    print(data1[1]);
  }
}

class Bar extends Foo {
  final List<String> data2;

  Bar() : data2 = ['d', 'e', 'f'];

  @override
  void doStuff() {
    print(data2); // LINE_A
    print(data2[1]);

    print(data1);
    print(data1[1]);

    print(super.data1);
    print(super.data1[1]);
  }
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: code);
}
