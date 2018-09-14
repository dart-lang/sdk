// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that async transformer produces correct Kernel ASTs and does
// not cause crashes in subsequent transformations.

import 'dart:async';

import 'package:expect/expect.dart';

bool global = false;

class Foo<T> {
  final T Function(int) wrap;
  final int Function(T) unwrap;

  Foo(this.wrap, this.unwrap);

  FutureOr<List<T>> get f => [wrap(21), wrap(20), wrap(1)];
  FutureOr<List<T>> get g => [wrap(-21), wrap(20), wrap(1)];

  Future<int> get one async =>
      (global ? await f : await g).map(unwrap).reduce((int a, int b) => a + b);

  Future<int> get two async =>
      (await f).map(unwrap).reduce((int a, int b) => a + b);
}

class Bar {
  final int value;
  Bar(this.value);
}

void main() async {
  final wrap = (int v) => new Bar(v);
  final unwrap = (Bar b) => b.value;

  Expect.equals(0, await new Foo<Bar>(wrap, unwrap).one);
  Expect.equals(42, await new Foo<Bar>(wrap, unwrap).two);
}
