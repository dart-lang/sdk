// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:expect/expect.dart';

StackTrace? stackTrace;

main() async {
  final values = [];
  await for (final value in produce()) {
    values.add(value);
  }
  Expect.equals('foo', values.single);
  Expect.isNotNull(stackTrace!);
}

Stream<String> produce() async* {
  await for (String response in produceInner()) {
    yield response;
  }
}

Stream<String> produceInner() async* {
  yield 'foo';
  stackTrace = StackTrace.current;
}
