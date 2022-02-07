// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test asserts that we are not inlining accesses to typed data interfaces
// (e.g. Uint8List) if there are instantiated 3rd party classes (e.g.
// UnmodifiableUint8ListView).

import 'dart:typed_data';
import 'package:vm/testing/il_matchers.dart';

createThirdPartyUint8List() => UnmodifiableUint8ListView(Uint8List(10));

@pragma('vm:never-inline')
@pragma('vm:testing:print-flow-graph')
void foo(Uint8List list, int from) {
  if (from >= list.length) {
    list[from];
  }
}

void matchIL$foo(FlowGraph graph) {
  graph.match([
    match.block('Graph'),
    match.block('Function', [
      'list' << match.Parameter(index: 0),
      'from' << match.Parameter(index: 1),
      'v13' << match.LoadClassId('list'),
      match.PushArgument('list'),
      match.DispatchTableCall('v13', selector_name: 'get:length'),
      match.Branch(match.RelationalOp(match.any, match.any, kind: '>='),
          ifTrue: 'B3'),
    ]),
    'B3' <<
        match.block('Target', [
          'v15' << match.LoadClassId('list'),
          match.PushArgument('list'),
          match.PushArgument(/* BoxInt64(Parameter) or Parameter */),
          match.DispatchTableCall('v15', selector_name: '[]'),
        ]),
  ]);
}

void main() {
  foo(int.parse('1') == 1 ? createThirdPartyUint8List() : Uint8List(1),
      int.parse('0'));
}
