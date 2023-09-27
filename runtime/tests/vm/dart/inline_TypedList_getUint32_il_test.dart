// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that compiler inlines _TypedList._getX when indexing into views
// using a trimmed version of runtime/tools/heapsnapshot/lib/src/analysis.dart.
// See dartbug.com/53513.

import 'dart:typed_data';

import 'package:expect/expect.dart';
import 'package:vm/testing/il_matchers.dart';
import 'package:vm_service/vm_service.dart';

typedef IntSet = Set<int>;

const int _rootObjectIdx = 1;

@pragma('vm:testing:print-flow-graph')
Uint32List calculateRetainers(HeapSnapshotGraph graph) {
  final retainers = Uint32List(graph.objects.length);

  var worklist = IntSet()..add(_rootObjectIdx);
  while (!worklist.isEmpty) {
    final next = IntSet();

    for (final objId in worklist) {
      final object = graph.objects[objId];
      final references = object.references;
      for (int i = 0; i < references.length; ++i) {
        final refId = references[i];
        if (retainers[refId] == 0) {
          retainers[refId] = objId;
          next.add(refId);
        }
      }
    }
    worklist = next;
  }
  return retainers;
}

void matchIL$calculateRetainers(FlowGraph graph) {
  graph.dump();
  final descriptors = graph.descriptors;
  for (var block in graph.blocks) {
    for (var instr in [...?block['is']]) {
      if (instr['o'] != 'StaticCall') continue;
      final function = graph.attributesFor(instr)?['function'];
      if (function == null) continue;
      if (!function.endsWith('_getUint32')) continue;
      final buffer = StringBuffer();
      buffer
        ..write('Found uninlined call to _getUint32 in block ')
        ..write(graph.blockName(block))
        ..writeln(':')
        ..write('  ');
      graph.formatInstruction(buffer, instr);
      throw buffer;
    }
  }
}

void main() {
  // To ensure _calculateRetainers is compiled.
  Expect.throws(
      () => calculateRetainers(HeapSnapshotGraph.fromChunks(<ByteData>[])));
}
