// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: prefer_final_locals

import 'common/test_helper.dart';

void code() {
  final gen = generator(); // LINE_A
  for (int datapoint in gen) {
    print(datapoint);
  }
}

Iterable<dynamic> generator() sync* {
  var x = 3;
  var y = 4;
  yield x;
  yield x + y;
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: code);
}
