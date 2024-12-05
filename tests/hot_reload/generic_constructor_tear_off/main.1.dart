// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:reload_test/reload_test_utils.dart';

// Adapted from:
// https://github.com/dart-lang/sdk/blob/f34a2ed99fc1b34cedbd974a5801f8d922121126/runtime/vm/isolate_reload_test.cc#L4638
// Regression test for https://github.com/dart-lang/sdk/issues/50148

typedef Create<T, R> = T Function(R ref);

class Base<Input> {
  Base(void Function(Create<void, Input> create) factory) : _factory = factory;

  final void Function(Create<void, Input> create) _factory;

  void fn() => _factory((ref) {});
}

class Check<T> {
  Check(Create<Object?, List<T>> create);
}

final f = Base<List<int>>(Check<int>.new);

helper() {
  f.fn();
}

Future<void> main() async {
  helper();
  await hotReload();
  helper();
}
/** DIFF **/
/*
*/
