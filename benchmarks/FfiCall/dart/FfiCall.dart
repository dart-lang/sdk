// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// These micro benchmarks track the speed of reading and writing C memory from
// Dart with a specific marshalling and unmarshalling of data.

import 'dart:ffi';
import 'dart:io';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:ffi/ffi.dart';

import 'dlopen_helper.dart';

part 'benchmark_generated.dart';

// Number of benchmark iterations per function.
const N = 1000;

// The native library that holds all the native functions being called.
DynamicLibrary ffiTestFunctions = dlopenPlatformSpecific('native_functions',
    path: Platform.script.resolve('../native/out/').path);

abstract class FfiBenchmarkBase extends BenchmarkBase {
  final bool isLeaf;

  FfiBenchmarkBase(String name, {this.isLeaf = false})
      : super('$name${isLeaf ? 'Leaf' : ''}');

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

class MyClass {
  int a;
  MyClass(this.a);
}

//
// Non-generated benchmark: This benchmark does not have a common structure with
// the generated benchmarks.
//

class Int64Mintx01 extends FfiBenchmarkBase {
  final Function1int f;

  Int64Mintx01({isLeaf = false})
      : f = isLeaf
            ? ffiTestFunctions.lookupFunction<NativeFunction1Int64,
                Function1int>('Function1Int64', isLeaf: true)
            : ffiTestFunctions.lookupFunction<NativeFunction1Int64,
                Function1int>('Function1Int64', isLeaf: false),
        super('FfiCall.Int64Mintx01', isLeaf: isLeaf);

  @override
  void run() {
    int x = 0x7FFFFFFF00000000;
    for (int i = 0; i < N; i++) {
      x = f(x);
    }
    expectEquals(x, 0x7FFFFFFF00000000 + N * 42);
  }
}

//
// Main driver.
//

void main(List<String> args) {
  // Force loading the dylib with RLTD_GLOBAL so that the
  // Native benchmarks below can do process lookup.
  dlopenGlobalPlatformSpecific('native_functions',
      path: Platform.script.resolve('../native/out/').path);

  final benchmarks = [
    Uint8x01.new,
    () => Uint8x01(isLeaf: true),
    Uint8x01Native.new,
    Uint8x01NativeLeaf.new,
    Uint16x01.new,
    Uint32x01.new,
    Uint64x01.new,
    Int8x01.new,
    () => Int8x01(isLeaf: true),
    Int8x01Native.new,
    Int8x01NativeLeaf.new,
    Int16x01.new,
    Int32x01.new,
    Int32x02.new,
    Int32x04.new,
    Int32x10.new,
    Int32x20.new,
    Int64x01.new,
    Int64x02.new,
    Int64x04.new,
    Int64x10.new,
    Int64x20.new,
    () => Int64x20(isLeaf: true),
    Int64x20Native.new,
    Int64x20NativeLeaf.new,
    Int64Mintx01.new,
    () => Int64Mintx01(isLeaf: true),
    Floatx01.new,
    Floatx02.new,
    Floatx04.new,
    Floatx10.new,
    Floatx20.new,
    () => Floatx20(isLeaf: true),
    Floatx20Native.new,
    Floatx20NativeLeaf.new,
    Doublex01.new,
    Doublex02.new,
    Doublex04.new,
    Doublex10.new,
    Doublex20.new,
    () => Doublex20(isLeaf: true),
    Doublex20Native.new,
    Doublex20NativeLeaf.new,
    PointerUint8x01.new,
    PointerUint8x02.new,
    PointerUint8x04.new,
    PointerUint8x10.new,
    PointerUint8x20.new,
    () => PointerUint8x20(isLeaf: true),
    PointerUint8x20Native.new,
    PointerUint8x20NativeLeaf.new,
    Handlex01.new,
    Handlex02.new,
    Handlex04.new,
    Handlex10.new,
    Handlex20.new,
    Handlex20Native.new,
  ];

  final filter = args.firstOrNull;
  for (var constructor in benchmarks) {
    final benchmark = constructor();
    if (filter == null || benchmark.name.contains(filter)) {
      benchmark.report();
    }
  }
}
