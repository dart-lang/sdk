// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

void code() {
  int? a; // LINE_A
  int? b;
  a = b = 42;
  print(a);
  print(b);
  a = 42;
  print(a);
  final int d = 42;
  print(d);
  int? e = 41, f, g = 42;
  print(e);
  print(f);
  print(g);
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: code);
}
