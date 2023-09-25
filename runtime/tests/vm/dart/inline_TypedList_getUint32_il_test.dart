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

import '../../../tools/heapsnapshot/lib/src/format.dart';
import '../../../tools/heapsnapshot/lib/src/intset.dart';

const int _invalidIdx = 0;
const int _rootObjectIdx = 1;

class Analysis {
  final HeapSnapshotGraph graph;

  late final reachableObjects = transitiveGraph(roots);

  late final Uint32List _retainers = _calculateRetainers();

  late final _oneByteStringCid = _findClassId('_OneByteString');
  late final _twoByteStringCid = _findClassId('_TwoByteString');
  late final _nonGrowableListCid = _findClassId('_List');
  late final _immutableListCid = _findClassId('_ImmutableList');
  late final _weakPropertyCid = _findClassId('_WeakProperty');
  late final _weakReferenceCid = _findClassId('_WeakReference');
  late final _patchClassCid = _findClassId('PatchClass');
  late final _finalizerEntryCid = _findClassId('FinalizerEntry');

  late final _weakPropertyKeyIdx = _findFieldIndex(_weakPropertyCid, 'key_');
  late final _weakPropertyValueIdx =
      _findFieldIndex(_weakPropertyCid, 'value_');

  late final _finalizerEntryDetachIdx =
      _findFieldIndex(_finalizerEntryCid, 'detach_');
  late final _finalizerEntryValueIdx =
      _findFieldIndex(_finalizerEntryCid, 'value_');

  late final int _headerSize = 4;
  late final int _wordSize = 4;

  Analysis(this.graph) {}

  /// The roots from which alive data can be discovered.
  final IntSet roots = IntSet()..add(_rootObjectIdx);

  /// Calculates the set of objects transitively reachable by [roots].
  IntSet transitiveGraph(IntSet roots) {
    final objects = graph.objects;
    final reachable = SpecializedIntSet(objects.length);
    final worklist = <int>[];

    reachable.addAll(roots);
    worklist.addAll(roots);

    final weakProperties = IntSet();

    while (worklist.isNotEmpty) {
      while (worklist.isNotEmpty) {
        final objectIdToExpand = worklist.removeLast();
        final objectToExpand = objects[objectIdToExpand];
        final cid = objectToExpand.classId;

        // Weak references don't keep their value alive.
        if (cid == _weakReferenceCid) continue;

        // Weak properties keep their value alive if the key is alive.
        if (cid == _weakPropertyCid) {
          weakProperties.add(objectIdToExpand);
          continue;
        }

        // Normal object (or FinalizerEntry).
        final references = objectToExpand.references;
        final bool isFinalizerEntry = cid == _finalizerEntryCid;
        for (int i = 0; i < references.length; ++i) {
          // [FinalizerEntry] objects don't keep their "detach" and "value"
          // fields alive.
          if (isFinalizerEntry &&
              (i == _finalizerEntryDetachIdx || i == _finalizerEntryValueIdx)) {
            continue;
          }

          final successor = references[i];
          if (!reachable.contains(successor)) {
            reachable.add(successor);
            worklist.add(successor);
          }
        }
      }

      // Enqueue values of weak properties if their key is alive.
      weakProperties.removeWhere((int weakProperty) {
        final wpReferences = objects[weakProperty].references;
        final keyId = wpReferences[_weakPropertyKeyIdx];
        final valueId = wpReferences[_weakPropertyValueIdx];
        if (reachable.contains(keyId)) {
          if (!reachable.contains(valueId)) {
            reachable.add(valueId);
            worklist.add(valueId);
          }
          return true;
        }
        return false;
      });
    }
    return reachable;
  }

  int _findClassId(String className) {
    return graph.classes
        .singleWhere((klass) =>
            klass.name == className &&
            (klass.libraryUri.scheme == 'dart' ||
                klass.libraryUri.toString() == ''))
        .classId;
  }

  int _findFieldIndex(int cid, String fieldName) {
    return graph.classes[cid].fields
        .singleWhere((f) => f.name == fieldName)
        .index;
  }

  @pragma('vm:testing:print-flow-graph')
  Uint32List _calculateRetainers() {
    final retainers = Uint32List(graph.objects.length);

    var worklist = IntSet()..add(_rootObjectIdx);
    while (!worklist.isEmpty) {
      final next = IntSet();

      for (final objId in worklist) {
        final object = graph.objects[objId];
        final cid = object.classId;

        // Weak references don't keep their value alive.
        if (cid == _weakReferenceCid) continue;

        // Weak properties keep their value alive if the key is alive.
        if (cid == _weakPropertyCid) {
          final valueId = object.references[_weakPropertyValueIdx];
          if (reachableObjects.contains(valueId)) {
            if (retainers[valueId] == 0) {
              retainers[valueId] = objId;
              next.add(valueId);
            }
          }
          continue;
        }

        // Normal object (or FinalizerEntry).
        final references = object.references;
        final bool isFinalizerEntry = cid == _finalizerEntryCid;
        for (int i = 0; i < references.length; ++i) {
          // [FinalizerEntry] objects don't keep their "detach" and "value"
          // fields alive.
          if (isFinalizerEntry &&
              (i == _finalizerEntryDetachIdx || i == _finalizerEntryValueIdx)) {
            continue;
          }

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
}

void matchIL$_calculateRetainers(FlowGraph graph) {
  graph.dump();
  for (var block in graph.blocks) {
    for (var instr in [...?block['d'], ...?block['is']]) {
      final function = instr['f'] as String?;
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
  Expect.throws(() => Analysis(HeapSnapshotGraph.fromChunks(<ByteData>[]))
      ._retainers[_rootObjectIdx]);
}
