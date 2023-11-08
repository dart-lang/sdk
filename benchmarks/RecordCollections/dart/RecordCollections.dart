// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:benchmark_harness/benchmark_harness.dart';

// Micro-benchmark for List/Map/Set of records.
//
// The goal of this benchmark is to compare and track performance of
// the most common operations on List/Map/Set of records.

int N = 0;
int SUM = 0;

bool runtimeTrue = int.parse('1') == 1; // Not known at compile time.

class Pair {
  final int v0;
  final int v1;
  const Pair(this.v0, this.v1);
  @override
  bool operator ==(other) => other is Pair && v0 == other.v0 && v1 == other.v1;
  @override
  int get hashCode => Object.hash(v0, v1);
}

@pragma('vm:never-inline')
@pragma('dart2js:never-inline')
List<Object> getPolymorphicListOfClass(
    int length, bool growable, bool withValues) {
  if (runtimeTrue) {
    if (withValues) {
      return List<Pair>.generate(length, (i) => Pair(i, i), growable: growable);
    } else {
      return List<Pair>.filled(length, const Pair(-1, -1), growable: growable);
    }
  } else {
    return List<String>.filled(0, '', growable: growable);
  }
}

@pragma('vm:never-inline')
@pragma('dart2js:never-inline')
List<Object> getPolymorphicListOfRecords(
    int length, bool growable, bool withValues) {
  if (runtimeTrue) {
    if (withValues) {
      return List<(int, int)>.generate(length, (i) => (i, i),
          growable: growable);
    } else {
      return List<(int, int)>.filled(length, (-1, -1), growable: growable);
    }
  } else {
    return List<String>.filled(0, '', growable: growable);
  }
}

class BenchListAddClass extends BenchmarkBase {
  BenchListAddClass() : super('RecordCollections.ListAdd.Class');

  @override
  void run() {
    final list = <Pair>[];
    for (int i = 0; i < N; ++i) {
      list.add(Pair(i, i));
    }
    if (list[N ~/ 2].v0 != N ~/ 2) throw 'Bad result: ${list[N ~/ 2].v0}';
  }
}

class BenchListAddRecord extends BenchmarkBase {
  BenchListAddRecord() : super('RecordCollections.ListAdd.Record');

  @override
  void run() {
    final list = <(int, int)>[];
    for (int i = 0; i < N; ++i) {
      list.add((i, i));
    }
    if (list[N ~/ 2].$1 != N ~/ 2) throw 'Bad result: ${list[N ~/ 2].$1}';
  }
}

class BenchListAddPolyClass extends BenchmarkBase {
  BenchListAddPolyClass() : super('RecordCollections.ListAddPoly.Class');

  @override
  void run() {
    final List<Object> list = getPolymorphicListOfClass(0, runtimeTrue, false);
    for (int i = 0; i < N; ++i) {
      list.add(Pair(i, i));
    }
    final int mid = (list[N ~/ 2] as Pair).v0;
    if (mid != N ~/ 2) throw 'Bad result: $mid';
  }
}

class BenchListAddPolyRecord extends BenchmarkBase {
  BenchListAddPolyRecord() : super('RecordCollections.ListAddPoly.Record');

  @override
  void run() {
    final List<Object> list =
        getPolymorphicListOfRecords(0, runtimeTrue, false);
    for (int i = 0; i < N; ++i) {
      list.add((i, i));
    }
    final int mid = (list[N ~/ 2] as (int, int)).$1;
    if (mid != N ~/ 2) throw 'Bad result: $mid';
  }
}

class BenchListSetIndexedClass extends BenchmarkBase {
  BenchListSetIndexedClass() : super('RecordCollections.ListSetIndexed.Class');

  @override
  void run() {
    final list = List<Pair>.filled(N, const Pair(-1, -1), growable: false);
    for (int i = 0; i < N; ++i) {
      list[i] = Pair(i, i);
    }
    if (list[N ~/ 2].v0 != N ~/ 2) throw 'Bad result: ${list[N ~/ 2].v0}';
  }
}

class BenchListSetIndexedRecord extends BenchmarkBase {
  BenchListSetIndexedRecord()
      : super('RecordCollections.ListSetIndexed.Record');

  @override
  void run() {
    final list = List<(int, int)>.filled(N, (-1, -1), growable: false);
    for (int i = 0; i < N; ++i) {
      list[i] = (i, i);
    }
    if (list[N ~/ 2].$1 != N ~/ 2) throw 'Bad result: ${list[N ~/ 2].$1}';
  }
}

class BenchListSetIndexedPolyClass extends BenchmarkBase {
  BenchListSetIndexedPolyClass()
      : super('RecordCollections.ListSetIndexedPoly.Class');

  @override
  void run() {
    final List<Object> list = getPolymorphicListOfClass(N, !runtimeTrue, false);
    for (int i = 0; i < N; ++i) {
      list[i] = Pair(i, i);
    }
    final int mid = (list[N ~/ 2] as Pair).v0;
    if (mid != N ~/ 2) throw 'Bad result: $mid';
  }
}

class BenchListSetIndexedPolyRecord extends BenchmarkBase {
  BenchListSetIndexedPolyRecord()
      : super('RecordCollections.ListSetIndexedPoly.Record');

  @override
  void run() {
    final List<Object> list =
        getPolymorphicListOfRecords(N, !runtimeTrue, false);
    for (int i = 0; i < N; ++i) {
      list[i] = (i, i);
    }
    final int mid = (list[N ~/ 2] as (int, int)).$1;
    if (mid != N ~/ 2) throw 'Bad result: $mid';
  }
}

class BenchListGetIndexedClass extends BenchmarkBase {
  BenchListGetIndexedClass() : super('RecordCollections.ListGetIndexed.Class');

  final list = <Pair>[
    for (int i = 0; i < N; ++i) Pair(i, i),
  ];

  @override
  void run() {
    int sum = 0;
    for (int i = 0; i < list.length; ++i) {
      sum += list[i].v0;
    }
    if (sum != SUM) throw 'Bad result: $sum';
  }
}

class BenchListGetIndexedRecord extends BenchmarkBase {
  BenchListGetIndexedRecord()
      : super('RecordCollections.ListGetIndexed.Record');

  final list = <(int, int)>[
    for (int i = 0; i < N; ++i) (i, i),
  ];

  @override
  void run() {
    int sum = 0;
    for (int i = 0; i < list.length; ++i) {
      sum += list[i].$1;
    }
    if (sum != SUM) throw 'Bad result: $sum';
  }
}

class BenchListGetIndexedPolyClass extends BenchmarkBase {
  BenchListGetIndexedPolyClass()
      : super('RecordCollections.ListGetIndexedPoly.Class');

  final list = getPolymorphicListOfClass(N, runtimeTrue, true) as List<Pair>;

  @override
  void run() {
    int sum = 0;
    for (int i = 0; i < list.length; ++i) {
      sum += list[i].v0;
    }
    if (sum != SUM) throw 'Bad result: $sum';
  }
}

class BenchListGetIndexedPolyRecord extends BenchmarkBase {
  BenchListGetIndexedPolyRecord()
      : super('RecordCollections.ListGetIndexedPoly.Record');

  final list =
      getPolymorphicListOfRecords(N, runtimeTrue, true) as List<(int, int)>;

  @override
  void run() {
    int sum = 0;
    for (int i = 0; i < list.length; ++i) {
      sum += list[i].$1;
    }
    if (sum != SUM) throw 'Bad result: $sum';
  }
}

class BenchListIterateClass extends BenchmarkBase {
  BenchListIterateClass() : super('RecordCollections.ListIterate.Class');

  final list = <Pair>[
    for (int i = 0; i < N; ++i) Pair(i, i),
  ];

  @override
  void run() {
    int sum = 0;
    for (final v in list) {
      sum += v.v0;
    }
    if (sum != SUM) throw 'Bad result: $sum';
  }
}

class BenchListIterateRecord extends BenchmarkBase {
  BenchListIterateRecord() : super('RecordCollections.ListIterate.Record');

  final list = <(int, int)>[
    for (int i = 0; i < N; ++i) (i, i),
  ];

  @override
  void run() {
    int sum = 0;
    for (final v in list) {
      sum += v.$1;
    }
    if (sum != SUM) throw 'Bad result: $sum';
  }
}

class BenchListIteratePolyClass extends BenchmarkBase {
  BenchListIteratePolyClass()
      : super('RecordCollections.ListIteratePoly.Class');

  final list = getPolymorphicListOfClass(N, runtimeTrue, true) as List<Pair>;

  @override
  void run() {
    int sum = 0;
    for (final v in list) {
      sum += v.v0;
    }
    if (sum != SUM) throw 'Bad result: $sum';
  }
}

class BenchListIteratePolyRecord extends BenchmarkBase {
  BenchListIteratePolyRecord()
      : super('RecordCollections.ListIteratePoly.Record');

  final list =
      getPolymorphicListOfRecords(N, runtimeTrue, true) as List<(int, int)>;

  @override
  void run() {
    int sum = 0;
    for (final v in list) {
      sum += v.$1;
    }
    if (sum != SUM) throw 'Bad result: $sum';
  }
}

class BenchMapAddClassKey extends BenchmarkBase {
  BenchMapAddClassKey() : super('RecordCollections.MapAdd.ClassKey');

  @override
  void run() {
    final map = <Pair, int>{};
    for (int i = 0; i < N; ++i) {
      map[Pair(i, i)] = i;
    }
    if (map.length != N) throw 'Bad result: ${map.length}';
  }
}

class BenchMapAddRecordKey extends BenchmarkBase {
  BenchMapAddRecordKey() : super('RecordCollections.MapAdd.RecordKey');

  @override
  void run() {
    final map = <(int, int), int>{};
    for (int i = 0; i < N; ++i) {
      map[(i, i)] = i;
    }
    if (map.length != N) throw 'Bad result: ${map.length}';
  }
}

class BenchMapAddClassValue extends BenchmarkBase {
  BenchMapAddClassValue() : super('RecordCollections.MapAdd.ClassValue');

  @override
  void run() {
    final map = <int, Pair>{};
    for (int i = 0; i < N; ++i) {
      map[i] = Pair(i, i);
    }
    if (map.length != N) throw 'Bad result: ${map.length}';
  }
}

class BenchMapAddRecordValue extends BenchmarkBase {
  BenchMapAddRecordValue() : super('RecordCollections.MapAdd.RecordValue');

  @override
  void run() {
    final map = <int, (int, int)>{};
    for (int i = 0; i < N; ++i) {
      map[i] = (i, i);
    }
    if (map.length != N) throw 'Bad result: ${map.length}';
  }
}

class BenchMapLookupClass extends BenchmarkBase {
  BenchMapLookupClass() : super('RecordCollections.MapLookup.Class');

  final map = <Pair, int>{
    for (int i = 0; i < N; ++i) Pair(i, i): i,
  };

  @override
  void run() {
    int sum = 0;
    for (int i = 0; i < N; ++i) {
      sum += map[Pair(i, i)]!;
    }
    if (sum != SUM) throw 'Bad result: $sum';
  }
}

class BenchMapLookupRecord extends BenchmarkBase {
  BenchMapLookupRecord() : super('RecordCollections.MapLookup.Record');

  final map = <(int, int), int>{
    for (int i = 0; i < N; ++i) (i, i): i,
  };

  @override
  void run() {
    int sum = 0;
    for (int i = 0; i < N; ++i) {
      sum += map[(i, i)]!;
    }
    if (sum != SUM) throw 'Bad result: $sum';
  }
}

class BenchSetAddClass extends BenchmarkBase {
  BenchSetAddClass() : super('RecordCollections.SetAdd.Class');

  @override
  void run() {
    final set = <Pair>{};
    for (int i = 0; i < N; ++i) {
      set.add(Pair(i, i));
    }
    if (set.length != N) throw 'Bad result: ${set.length}';
  }
}

class BenchSetAddRecord extends BenchmarkBase {
  BenchSetAddRecord() : super('RecordCollections.SetAdd.Record');

  @override
  void run() {
    final set = <(int, int)>{};
    for (int i = 0; i < N; ++i) {
      set.add((i, i));
    }
    if (set.length != N) throw 'Bad result: ${set.length}';
  }
}

class BenchSetLookupClass extends BenchmarkBase {
  BenchSetLookupClass() : super('RecordCollections.SetLookup.Class');

  final set = <Pair>{
    for (int i = 0; i < N ~/ 2; ++i) Pair(i * 2, i * 2),
  };

  @override
  void run() {
    int sum = 0;
    for (int i = 0; i < N; ++i) {
      sum += set.contains(Pair(i, i)) ? 1 : 0;
    }
    if (sum != N ~/ 2) throw 'Bad result: $sum';
  }
}

class BenchSetLookupRecord extends BenchmarkBase {
  BenchSetLookupRecord() : super('RecordCollections.SetLookup.Record');

  final set = <(int, int)>{
    for (int i = 0; i < N ~/ 2; ++i) (i * 2, i * 2),
  };

  @override
  void run() {
    int sum = 0;
    for (int i = 0; i < N; ++i) {
      sum += set.contains((i, i)) ? 1 : 0;
    }
    if (sum != N ~/ 2) throw 'Bad result: $sum';
  }
}

void main() {
  N = int.parse('100000');
  SUM = N * (N - 1) ~/ 2;

  final benchmarks = [
    BenchListAddClass(),
    BenchListAddRecord(),
    BenchListAddPolyClass(),
    BenchListAddPolyRecord(),
    BenchListSetIndexedClass(),
    BenchListSetIndexedRecord(),
    BenchListSetIndexedPolyClass(),
    BenchListSetIndexedPolyRecord(),
    BenchListGetIndexedClass(),
    BenchListGetIndexedRecord(),
    BenchListGetIndexedPolyClass(),
    BenchListGetIndexedPolyRecord(),
    BenchListIterateClass(),
    BenchListIterateRecord(),
    BenchListIteratePolyClass(),
    BenchListIteratePolyRecord(),
    BenchMapAddClassKey(),
    BenchMapAddRecordKey(),
    BenchMapAddClassValue(),
    BenchMapAddRecordValue(),
    BenchMapLookupClass(),
    BenchMapLookupRecord(),
    BenchSetAddClass(),
    BenchSetAddRecord(),
    BenchSetLookupClass(),
    BenchSetLookupRecord(),
  ];

  for (final benchmark in benchmarks) {
    benchmark.warmup();
  }
  for (final benchmark in benchmarks) {
    benchmark.report();
  }
}
