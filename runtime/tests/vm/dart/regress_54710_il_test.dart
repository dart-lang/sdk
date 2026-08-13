// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Checks that we no longer expose unsafe untagged pointers for internal
// typed data objects in this trimmed example found by the Dart fuzzer.

import 'dart:typed_data';
import 'package:vm/testing/il_matchers.dart';

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
Uint32List create() => Uint32List.fromList(Uint32List.fromList(Uint8List(40)));

void main() async {
  print(create());
}

void matchIL$create(FlowGraph graph) {
  graph.dump();
  graph.match([
    match.block('Graph', [
      'c40' << match.Constant(value: 40),
      'c0' << match.Constant(value: 0),
    ]),
    match.block('Function', [
      // Only here to avoid inner32Alloc matching the first AllocateTypedData.
      'initial8Alloc' << match.AllocateTypedData('c40'),
      'inner32Alloc' << match.AllocateTypedData('c40'),
      'outer32Alloc' << match.AllocateTypedData('c40'),
      match.MemoryCopy('inner32Alloc', 'outer32Alloc', 'c0', 'c0', match.any),
    ]),
  ]);
}
