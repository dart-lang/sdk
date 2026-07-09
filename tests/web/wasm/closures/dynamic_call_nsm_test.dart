// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

void main() {
  final runtimeTrue = int.parse('1') == 1;
  final recorder = Recorder();
  final dynamic object = runtimeTrue ? recorder : () {};

  // Dynamic closure call.

  object();
  expectInvocation(recorder, #call, [], {});

  object(a: 1);
  expectInvocation(recorder, #call, [], {#a: 1});

  object(1);
  expectInvocation(recorder, #call, [1], {});

  object(1, 2, a: 1);
  expectInvocation(recorder, #call, [1, 2], {#a: 1});

  // Dynamic closure call via field (i.e. `tmp = object.bar; tmp(...)`)

  object.bar();
  expectInvocation(recorder, #call, [], {});

  object.bar(a: 1, b: 2);
  expectInvocation(recorder, #call, [], {#a: 1, #b: 2});

  object.bar(1, 2, 3);
  expectInvocation(recorder, #call, [1, 2, 3], {});

  object.bar(1, 2, 3, 4, a: 1, b: 2);
  expectInvocation(recorder, #call, [1, 2, 3, 4], {#a: 1, #b: 2});

  // Dynamic method call.

  object.foo();
  expectInvocation(recorder, #foo, [], {});

  object.foo(a: 1, b: 2, c: 3);
  expectInvocation(recorder, #foo, [], {#a: 1, #b: 2, #c: 3});

  object.foo(1, 2, 3, 4, 5);
  expectInvocation(recorder, #foo, [1, 2, 3, 4, 5], {});

  object.foo(1, 2, 3, 4, 5, 6, a: 1, b: 2, c: 3);
  expectInvocation(recorder, #foo, [1, 2, 3, 4, 5, 6], {#a: 1, #b: 2, #c: 3});
}

void expectInvocation(
  Recorder recorder,
  Symbol name,
  List<Object?> positional,
  Map<Symbol, Object?> named,
) {
  final i = recorder.lastInvocation!;
  Expect.equals(name, i.memberName);
  Expect.deepEquals(positional, i.positionalArguments);
  Expect.deepEquals(named, i.namedArguments);
}

class Recorder {
  Invocation? lastInvocation;

  dynamic get bar => this;

  @override
  void noSuchMethod(Invocation invocation) {
    lastInvocation = invocation;
  }
}
