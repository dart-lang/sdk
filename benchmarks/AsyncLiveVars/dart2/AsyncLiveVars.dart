// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Micro-benchmark for testing async/await performance in presence of
// different number of live values across await.

// @dart=2.9

import 'dart:async';

import 'async_benchmark_base.dart' show AsyncBenchmarkBase;

class MockClass {
  static final String str = "${int.parse('42')}";
  static final List<int> list =
      List<int>.filled(int.parse('3'), int.parse('42'));

  @pragma('vm:never-inline')
  @pragma('dart2js:noInline')
  String get1() => str;

  @pragma('vm:never-inline')
  @pragma('dart2js:noInline')
  List<int> get2() => list;

  @pragma('vm:never-inline')
  @pragma('dart2js:noInline')
  void use1(String a0) => a0.length;

  @pragma('vm:never-inline')
  @pragma('dart2js:noInline')
  void use2(String a0, List<int> a1) => a0.length + a1.length;

  @pragma('vm:never-inline')
  @pragma('dart2js:noInline')
  void use4(String a0, List<int> a1, String a2, List<int> a3) =>
      a0.length + a1.length + a2.length + a3.length;

  @pragma('vm:never-inline')
  @pragma('dart2js:noInline')
  void use8(String a0, List<int> a1, String a2, List<int> a3, String a4,
          List<int> a5, String a6, List<int> a7) =>
      a0.length +
      a1.length +
      a2.length +
      a3.length +
      a4.length +
      a5.length +
      a6.length +
      a7.length;

  @pragma('vm:never-inline')
  @pragma('dart2js:noInline')
  Future<void> asyncMethod() async {}
}

class MockClass2 {
  static int val1 = int.parse('42');
  static int val2 = int.parse('43');

  @pragma('vm:never-inline')
  @pragma('dart2js:noInline')
  int get1() => val1;

  @pragma('vm:never-inline')
  @pragma('dart2js:noInline')
  int get2() => val2;

  @pragma('vm:never-inline')
  @pragma('dart2js:noInline')
  void use1(int a0) => a0;

  @pragma('vm:never-inline')
  @pragma('dart2js:noInline')
  void use2(int a0, int a1) => a0 + a1;

  @pragma('vm:never-inline')
  @pragma('dart2js:noInline')
  void use4(int a0, int a1, int a2, int a3) => a0 + a1 + a2 + a3;

  @pragma('vm:never-inline')
  @pragma('dart2js:noInline')
  Future<void> asyncMethod() async {}
}

class LiveVarsBench extends AsyncBenchmarkBase {
  LiveVarsBench(String name) : super(name);
  @override
  Future<void> exercise() async {
    // These micro-benchmarks are too small, so
    // make a larger number of iterations per measurement.
    for (var i = 0; i < 10000; i++) {
      await run();
    }
  }
}

class LiveObj1 extends LiveVarsBench {
  LiveObj1() : super('AsyncLiveVars.LiveObj1');
  final field1 = MockClass();
  @override
  Future<void> run() async {
    final obj1 = field1.get1();
    await field1.asyncMethod();
    field1.use1(obj1);
    await field1.asyncMethod();
    field1.use1(obj1);
    await field1.asyncMethod();
    field1.use1(obj1);
  }
}

class LiveObj2 extends LiveVarsBench {
  LiveObj2() : super('AsyncLiveVars.LiveObj2');
  final field1 = MockClass();
  @override
  Future<void> run() async {
    final obj1 = field1.get1();
    final obj2 = field1.get2();
    await field1.asyncMethod();
    field1.use1(obj1);
    await field1.asyncMethod();
    field1.use1(obj1);
    await field1.asyncMethod();
    field1.use2(obj1, obj2);
  }
}

class LiveObj4 extends LiveVarsBench {
  LiveObj4() : super('AsyncLiveVars.LiveObj4');
  final field1 = MockClass();
  final field2 = MockClass();
  @override
  Future<void> run() async {
    final obj1 = field1.get1();
    final obj2 = field1.get2();
    final obj3 = field2.get1();
    final obj4 = field2.get2();
    await field1.asyncMethod();
    field1.use1(obj1);
    await field1.asyncMethod();
    field2.use1(obj3);
    await field2.asyncMethod();
    field1.use4(obj1, obj2, obj3, obj4);
  }
}

class LiveObj8 extends LiveVarsBench {
  LiveObj8() : super('AsyncLiveVars.LiveObj8');
  final field1 = MockClass();
  final field2 = MockClass();
  final field3 = MockClass();
  final field4 = MockClass();
  @override
  Future<void> run() async {
    final obj1 = field1.get1();
    final obj2 = field1.get2();
    final obj3 = field2.get1();
    final obj4 = field2.get2();
    final obj5 = field3.get1();
    final obj6 = field3.get2();
    final obj7 = field4.get1();
    final obj8 = field4.get2();
    await field1.asyncMethod();
    field1.use1(obj1);
    await field2.asyncMethod();
    field3.use2(obj5, obj6);
    await field4.asyncMethod();
    field2.use8(obj1, obj2, obj3, obj4, obj5, obj6, obj7, obj8);
  }
}

class LiveObj16 extends LiveVarsBench {
  LiveObj16() : super('AsyncLiveVars.LiveObj16');
  final field1 = MockClass();
  final field2 = MockClass();
  final field3 = MockClass();
  final field4 = MockClass();
  final field5 = MockClass();
  final field6 = MockClass();
  final field7 = MockClass();
  final field8 = MockClass();
  @override
  Future<void> run() async {
    final obj1 = field1.get1();
    final obj2 = field1.get2();
    final obj3 = field2.get1();
    final obj4 = field2.get2();
    final obj5 = field3.get1();
    final obj6 = field3.get2();
    final obj7 = field4.get1();
    final obj8 = field4.get2();
    final obj9 = field5.get1();
    final obj10 = field5.get2();
    final obj11 = field6.get1();
    final obj12 = field6.get2();
    final obj13 = field7.get1();
    final obj14 = field7.get2();
    final obj15 = field8.get1();
    final obj16 = field8.get2();
    await field1.asyncMethod();
    field1.use1(obj1);
    await field2.asyncMethod();
    field5.use2(obj11, obj12);
    await field4.asyncMethod();
    field2.use8(obj1, obj2, obj3, obj4, obj5, obj6, obj7, obj8);
    field3.use8(obj9, obj10, obj11, obj12, obj13, obj14, obj15, obj16);
  }
}

class LiveInt1 extends LiveVarsBench {
  LiveInt1() : super('AsyncLiveVars.LiveInt1');
  final field1 = MockClass2();
  @override
  Future<void> run() async {
    final int1 = field1.get1();
    await field1.asyncMethod();
    field1.use1(int1);
    await field1.asyncMethod();
    field1.use1(int1);
    await field1.asyncMethod();
    field1.use1(int1);
  }
}

class LiveInt4 extends LiveVarsBench {
  LiveInt4() : super('AsyncLiveVars.LiveInt4');
  final field1 = MockClass2();
  final field2 = MockClass2();
  @override
  Future<void> run() async {
    final int1 = field1.get1();
    final int2 = field1.get2();
    final int3 = field2.get1();
    final int4 = field2.get2();
    await field1.asyncMethod();
    field1.use1(int1);
    await field1.asyncMethod();
    field2.use1(int3);
    await field2.asyncMethod();
    field1.use4(int1, int2, int3, int4);
  }
}

class LiveObj2Int2 extends LiveVarsBench {
  LiveObj2Int2() : super('AsyncLiveVars.LiveObj2Int2');
  final field1 = MockClass();
  final field2 = MockClass2();
  @override
  Future<void> run() async {
    final obj1 = field1.get1();
    final obj2 = field1.get2();
    final int1 = field2.get1();
    final int2 = field2.get2();
    await field1.asyncMethod();
    field1.use1(obj1);
    await field1.asyncMethod();
    field2.use1(int1);
    await field2.asyncMethod();
    field1.use2(obj1, obj2);
    field2.use2(int1, int2);
  }
}

class LiveObj4Int4 extends LiveVarsBench {
  LiveObj4Int4() : super('AsyncLiveVars.LiveObj4Int4');
  final field1 = MockClass();
  final field2 = MockClass();
  final field3 = MockClass2();
  final field4 = MockClass2();
  @override
  Future<void> run() async {
    final obj1 = field1.get1();
    final obj2 = field1.get2();
    final obj3 = field2.get1();
    final obj4 = field2.get2();
    final int1 = field3.get1();
    final int2 = field3.get2();
    final int3 = field4.get1();
    final int4 = field4.get2();
    await field1.asyncMethod();
    field1.use1(obj1);
    await field2.asyncMethod();
    field3.use2(int2, int4);
    await field4.asyncMethod();
    field2.use4(obj1, obj2, obj3, obj4);
    field4.use4(int1, int2, int3, int4);
  }
}

Future<void> main() async {
  final benchmarks = [
    LiveObj1(),
    LiveObj2(),
    LiveObj4(),
    LiveObj8(),
    LiveObj16(),
    LiveInt1(),
    LiveInt4(),
    LiveObj2Int2(),
    LiveObj4Int4()
  ];
  for (final bench in benchmarks) {
    await bench.report();
  }
}
