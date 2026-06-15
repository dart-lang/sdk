// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common/test_helper.dart';

class Pair {
  // Make sure these fields are not removed by the tree shaker.
  @pragma('vm:entry-point') // Prevent obfuscation
  dynamic x;
  @pragma('vm:entry-point') // Prevent obfuscation
  dynamic y;
}

@pragma('vm:entry-point') // Prevent obfuscation
dynamic p1;
@pragma('vm:entry-point') // Prevent obfuscation
dynamic p2;

void buildGraph() {
  p1 = Pair();
  p2 = Pair();

  // Adds to both reachable and retained size.
  p1.x = <dynamic>[];
  p2.x = <dynamic>[];

  // Adds to reachable size only.
  p1.y = p2.y = <dynamic>[];
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeBefore: buildGraph);
}
