// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// Regression test for https://github.com/dart-lang/sdk/issues/45966.
// Verifies that compiler doesn't crash if Typedef is only used from
// function type of a call.

import 'package:expect/expect.dart';

class Message {}

typedef void FooHandler(Message message);

class A {
  A(this.handler);
  final FooHandler handler;
}

A a;

main() {
  a?.handler(Message());
}
