// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/49424.
// Verifies that correct type argument is used for Future
// created by async closure.

import 'package:expect/expect.dart';

class Task<A> {
  final Future<A> Function() _run;

  const Task(this._run);

  factory Task.of(A a) => Task<A>(() async => a);

  Future<A> run() => _run();
}

void main() async {
  final task = Task.of(10);
  final future = task.run();
  Expect.type<Future<int>>(future);
  final r = await future;
  Expect.equals(10, r);
}
