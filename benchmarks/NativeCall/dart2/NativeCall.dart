// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// These micro benchmarks track the speed of native calls.

// @dart=2.9

import 'dart:ffi';
import 'dart:io';

import 'package:benchmark_harness/benchmark_harness.dart';

import 'dlopen_helper.dart';

// Number of benchmark iterations per function.
const N = 1000;

// The native library that holds all the native functions being called.
final nativeFunctionsLib = dlopenPlatformSpecific('native_functions',
    path: Platform.script.resolve('../native/out/').path);

final getRootLibraryUrl = nativeFunctionsLib
    .lookupFunction<Handle Function(), Object Function()>('GetRootLibraryUrl');

final setNativeResolverForTest = nativeFunctionsLib.lookupFunction<
    Void Function(Handle), void Function(Object)>('SetNativeResolverForTest');

//
// Benchmark fixtures.
//

abstract class NativeCallBenchmarkBase extends BenchmarkBase {
  NativeCallBenchmarkBase(String name) : super(name);

  void expectEquals(actual, expected) {
    if (actual != expected) {
      throw Exception('$name: Unexpected result: $actual, expected $expected');
    }
  }

  void expectApprox(actual, expected) {
    if (0.999 * expected > actual || actual > 1.001 * expected) {
      throw Exception('$name: Unexpected result: $actual, expected $expected');
    }
  }

  void expectIdentical(actual, expected) {
    if (!identical(actual, expected)) {
      throw Exception('$name: Unexpected result: $actual, expected $expected');
    }
  }
}

class Uint8x01 extends NativeCallBenchmarkBase {
  Uint8x01() : super('NativeCall.Uint8x01');

  @pragma('vm:external-name', 'Function1Uint8')
  external static int f(int a);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += f(17);
    }
    expectEquals(x, N * 17 + N * 42);
  }
}

class Int64x20 extends NativeCallBenchmarkBase {
  Int64x20() : super('NativeCall.Int64x20');

  @pragma('vm:external-name', 'Function20Int64')
  external static int f(
      int a,
      int b,
      int c,
      int d,
      int e,
      int f,
      int g,
      int h,
      int i,
      int j,
      int k,
      int l,
      int m,
      int n,
      int o,
      int p,
      int q,
      int r,
      int s,
      int t);

  @override
  void run() {
    int x = 0;
    for (int i = 0; i < N; i++) {
      x += f(i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i, i);
    }
    expectEquals(x, N * (N - 1) * 20 / 2);
  }
}

class Doublex01 extends NativeCallBenchmarkBase {
  Doublex01() : super('NativeCall.Doublex01');

  @pragma('vm:external-name', 'Function1Double')
  external static double f(double a);

  @override
  void run() {
    double x = 0.0;
    for (int i = 0; i < N; i++) {
      x += f(17.0);
    }
    final double expected = N * (17.0 + 42.0);
    expectApprox(x, expected);
  }
}

class Doublex20 extends NativeCallBenchmarkBase {
  Doublex20() : super('NativeCall.Doublex20');

  @pragma('vm:external-name', 'Function20Double')
  external static double f(
      double a,
      double b,
      double c,
      double d,
      double e,
      double f,
      double g,
      double h,
      double i,
      double j,
      double k,
      double l,
      double m,
      double n,
      double o,
      double p,
      double q,
      double r,
      double s,
      double t);

  @override
  void run() {
    double x = 0;
    for (int i = 0; i < N; i++) {
      x += f(1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0,
          13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0);
    }
    final double expected = N *
        (1.0 +
            2.0 +
            3.0 +
            4.0 +
            5.0 +
            6.0 +
            7.0 +
            8.0 +
            9.0 +
            10.0 +
            11.0 +
            12.0 +
            13.0 +
            14.0 +
            15.0 +
            16.0 +
            17.0 +
            18.0 +
            19.0 +
            20.0);
    expectApprox(x, expected);
  }
}

class MyClass {
  int a;
  MyClass(this.a);
}

class Handlex01 extends NativeCallBenchmarkBase {
  Handlex01() : super('NativeCall.Handlex01');

  @pragma('vm:external-name', 'Function1Handle')
  external static Object f(Object a);

  @override
  void run() {
    final p1 = MyClass(123);
    Object x = p1;
    for (int i = 0; i < N; i++) {
      x = f(x);
    }
    expectIdentical(x, p1);
  }
}

class Handlex20 extends NativeCallBenchmarkBase {
  Handlex20() : super('NativeCall.Handlex20');

  @pragma('vm:external-name', 'Function20Handle')
  external static Object f(
      Object a,
      Object b,
      Object c,
      Object d,
      Object e,
      Object f,
      Object g,
      Object h,
      Object i,
      Object j,
      Object k,
      Object l,
      Object m,
      Object n,
      Object o,
      Object p,
      Object q,
      Object r,
      Object s,
      Object t);

  @override
  void run() {
    final p1 = MyClass(123);
    final p2 = MyClass(2);
    final p3 = MyClass(3);
    final p4 = MyClass(4);
    final p5 = MyClass(5);
    final p6 = MyClass(6);
    final p7 = MyClass(7);
    final p8 = MyClass(8);
    final p9 = MyClass(9);
    final p10 = MyClass(10);
    final p11 = MyClass(11);
    final p12 = MyClass(12);
    final p13 = MyClass(13);
    final p14 = MyClass(14);
    final p15 = MyClass(15);
    final p16 = MyClass(16);
    final p17 = MyClass(17);
    final p18 = MyClass(18);
    final p19 = MyClass(19);
    final p20 = MyClass(20);
    Object x = p1;
    for (int i = 0; i < N; i++) {
      x = f(x, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15,
          p16, p17, p18, p19, p20);
    }
    expectIdentical(x, p1);
  }
}

//
// Main driver.
//

void main() {
  setNativeResolverForTest(getRootLibraryUrl());

  final benchmarks = [
    () => Uint8x01(),
    () => Int64x20(),
    () => Doublex01(),
    () => Doublex20(),
    () => Handlex01(),
    () => Handlex20(),
  ];
  for (final benchmark in benchmarks) {
    benchmark().report();
  }
}
