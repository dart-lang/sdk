// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of allocation_profiler;

class AllocationProfile implements M.AllocationProfile {
  static const _lastServiceGC = 'dateLastServiceGC';
  final DateTime lastServiceGC;
  static const _lastAccumulatorReset = 'dateLastAccumulatorReset';
  final DateTime lastAccumulatorReset;
  final S.HeapSpace newSpace;
  final S.HeapSpace oldSpace;
  final Iterable<ClassHeapStats> members;

  AllocationProfile(S.ServiceMap map)
      : lastAccumulatorReset = _intString2DateTime(map[_lastAccumulatorReset]),
        lastServiceGC = _intString2DateTime(map[_lastServiceGC]),
        oldSpace = new S.HeapSpace()..update(map['heaps']['old']),
        newSpace = new S.HeapSpace()..update(map['heaps']['new']),
        members = map['members'].map(_convertMember).toList();

  static DateTime _intString2DateTime(String milliseconds) {
    if ((milliseconds == null) || milliseconds == '') {
      return null;
    }
    return new DateTime.fromMillisecondsSinceEpoch(int.parse(milliseconds));
  }

  static ClassHeapStats _convertMember(S.ServiceMap map) {
    assert(map['type'] == 'ClassHeapStats');
    return new ClassHeapStats(map);
  }
}

class ClassHeapStats implements M.ClassHeapStats {
  final S.Class clazz;
  final S.Allocations newSpace;
  final S.Allocations oldSpace;
  final int promotedInstances;
  final int promotedBytes;

  ClassHeapStats(S.ServiceMap map)
      : clazz = map['class'],
        oldSpace = new S.Allocations()..update(map['old']),
        newSpace = new S.Allocations()..update(map['new']),
        promotedInstances = map['promotedInstances'],
        promotedBytes = map['promotedBytes'];
}
