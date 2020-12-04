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
  final S.HeapSpace totalSpace;
  final Iterable<M.ClassHeapStats> members;

  AllocationProfile(S.ServiceMap map, {Map/*<String, List<String>>*/ defaults})
      : lastAccumulatorReset = _intString2DateTime(map[_lastAccumulatorReset]),
        lastServiceGC = _intString2DateTime(map[_lastServiceGC]),
        oldSpace = new S.HeapSpace()..update(map['_heaps']['old']),
        newSpace = new S.HeapSpace()..update(map['_heaps']['new']),
        totalSpace = new S.HeapSpace(),
        members = _convertMembers(map['members'], defaults: defaults) {
    totalSpace.add(oldSpace);
    totalSpace.add(newSpace);
  }

  static DateTime _intString2DateTime(String milliseconds) {
    if ((milliseconds == null) || milliseconds == '') {
      return null;
    }
    return new DateTime.fromMillisecondsSinceEpoch(int.parse(milliseconds));
  }

  static ClassHeapStats _convertMember(/*S.ServiceMap*/ map) {
    assert(map['type'] == 'ClassHeapStats');
    return new ClassHeapStats(map);
  }

  static List<M.ClassHeapStats> _convertMembers(Iterable/*<S.ServiceMap>*/ raw,
      {Map/*<String, List<String>>*/ defaults}) {
    final List<M.ClassHeapStats> members =
        raw.map<ClassHeapStats>(_convertMember).toList();
    if (defaults == null) {
      return members;
    }
    final Map<String, List<ClassHeapStats>> aliases =
        new Map.fromIterable(defaults.keys, value: (_) => <ClassHeapStats>[]);
    final Map<String, List<ClassHeapStats>> accumulators =
        <String, List<ClassHeapStats>>{};
    defaults.forEach((/*String*/ key, /*List<String>*/ values) {
      final classes = aliases[key];
      accumulators.addAll(new Map.fromIterable(values, value: (_) => classes));
    });
    final List<M.ClassHeapStats> result = <M.ClassHeapStats>[];
    members.forEach((M.ClassHeapStats member) {
      if (accumulators.containsKey(member.clazz.id)) {
        accumulators[member.clazz.id].add(member);
      } else {
        result.add(member);
      }
    });
    return result
      ..addAll(
          aliases.keys.map((key) => new ClassesHeapStats(key, aliases[key])));
  }
}

class ClassHeapStats implements M.ClassHeapStats {
  final S.Class clazz;
  final String displayName = null;
  final S.Allocations newSpace;
  final S.Allocations oldSpace;

  ClassHeapStats(Map map)
      : clazz = map['class'],
        oldSpace = new S.Allocations()..update(map['_old']),
        newSpace = new S.Allocations()..update(map['_new']);
}

class ClassesHeapStats implements M.ClassHeapStats {
  final S.Class clazz = null;
  final String displayName;
  final S.Allocations newSpace;
  final S.Allocations oldSpace;

  ClassesHeapStats(this.displayName, Iterable<ClassHeapStats> classes)
      : oldSpace = new S.Allocations()..combine(classes.map((m) => m.oldSpace)),
        newSpace = new S.Allocations()..combine(classes.map((m) => m.newSpace));
}
