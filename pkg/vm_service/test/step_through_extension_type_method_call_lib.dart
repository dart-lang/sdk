// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

extension type IdNumber(int i) {
  bool operator <(IdNumber other) => i < other.i;
}

void testMain() {
  final IdNumber id1 = IdNumber(123); // LINE_A
  final IdNumber id2 = IdNumber(999);
  id1 < id2;
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
