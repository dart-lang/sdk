// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

void main() {
  final runtimeTrue = int.parse('1') == 1;
  final dynamic object = runtimeTrue ? A() : 'a';

  // The purpose of this test is to ensure that dar2wasm's closed-world closure
  // layouter will consider `(foobar: 1)` as a closure call site and therefore
  // register `foobar` to be a used name combination.
  Expect.equals('foo<$int>(1)', object.closureGetter<int>(foobar: 1));
}

class A {
  void Function<T>() get closureGetter => foo;
}

String foo<T>({int? foobar}) => "foo<$T>($foobar)";
