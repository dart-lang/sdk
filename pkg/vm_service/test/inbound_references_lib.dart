// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

@pragma('vm:entry-point') // Prevent obfuscation
class Node {
  // Make sure this field is not removed by the tree shaker.
  @pragma('vm:entry-point') // Prevent obfuscation
  late Edge edge;
}

class Edge {}

@pragma('vm:entry-point') // Prevent obfuscation
late final Node n;
late final Edge e;
late final List<dynamic> array;

void script() {
  n = Node();
  e = Edge();
  n.edge = e;
  array = List<dynamic>.filled(2, null);
  array[0] = n;
  array[1] = e;
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeBefore: script);
}
