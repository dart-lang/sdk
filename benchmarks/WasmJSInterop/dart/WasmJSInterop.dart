// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Benchmarks passing small and large integers to JS via `js_interop`.
//
// In Wasm, integers that fit into 31 bits can be passed without allocation by
// by passing them as `i31ref`. To take advantage of this, dart2wasm checks the
// size of the integer before passing to JS and passes the integer as `i31ref`
// when possible.
//
// This benchmark compares performance of `int` passing for integers that fit
// into 31 bits and those that don't.

import 'dart:js_interop';

import 'package:benchmark_harness/benchmark_harness.dart';

@JS()
external void eval(String code);

// These return `void` to avoid adding `dartify` overheads to the benchmark
// results.
// V8 can't figure out that these don't do anything so the loops and JS calls
// aren't eliminated.
@JS()
external void intFun(int i);

@JS()
external void doubleFun(double d);

// Run benchmarked code for at least 2 seconds.
const int minimumMeasureDurationMillis = 2000;

class IntPassingBenchmark {
  final int start;
  final int end;

  IntPassingBenchmark(this.start, this.end);

  double measure() =>
      BenchmarkBase.measureFor(() {
        for (int i = start; i < end; i += 1) {
          intFun(i);
        }
      }, minimumMeasureDurationMillis) /
      (end - start);
}

class DoublePassingBenchmark {
  final double start;
  final double step;
  final int calls;

  DoublePassingBenchmark(this.start, this.step, this.calls);

  double measure() =>
      BenchmarkBase.measureFor(() {
        double d = start;
        for (int i = 0; i < calls; i += 1) {
          doubleFun(d);
          d *= step;
        }
      }, minimumMeasureDurationMillis) /
      calls;
}

@JS()
external bool dartifyBool();

@JS()
external bool? dartifyNullableBool();

@JS()
external num dartifyNum();

@JS()
external num? dartifyNullableNum();

@JS()
external double dartifyDouble();

@JS()
external double? dartifyNullableDouble();

@JS()
external int dartifyInt();

@JS()
external int? dartifyNullableInt();

@JS()
external String dartifyString();

@JS()
external String? dartifyNullableString();

@JS()
external JSArray dartifyJSArray();

@JS()
external JSArray? dartifyNullableJSArray();

// `dart:typed_data` types are all boxed the same way, so no need to test each
// one of them separately.
@JS()
external JSUint8Array dartifyJSUint8Array();

@JS()
external JSUint8Array? dartifyNullableJSUint8Array();

const int ITERATIONS = 10000;

bool boolSink = false;

double dartifyBoolBenchmark() =>
    BenchmarkBase.measureFor(() {
      for (int i = 0; i < ITERATIONS; i += 1) {
        boolSink = dartifyBool();
      }
    }, minimumMeasureDurationMillis) /
    ITERATIONS;

bool? nullableBoolSink;

double dartifyNullableBoolBenchmark() =>
    BenchmarkBase.measureFor(() {
      for (int i = 0; i < ITERATIONS; i += 1) {
        nullableBoolSink = dartifyNullableBool();
      }
    }, minimumMeasureDurationMillis) /
    ITERATIONS;

num numSink = 1;

double dartifyNumBenchmark() =>
    BenchmarkBase.measureFor(() {
      for (int i = 0; i < ITERATIONS; i += 1) {
        numSink = dartifyNum();
      }
    }, minimumMeasureDurationMillis) /
    ITERATIONS;

num? nullableNumSink;

double dartifyNullableNumBenchmark() =>
    BenchmarkBase.measureFor(() {
      for (int i = 0; i < ITERATIONS; i += 1) {
        nullableNumSink = dartifyNullableNum();
      }
    }, minimumMeasureDurationMillis) /
    ITERATIONS;

double doubleSink = 0.0;

double dartifyDoubleBenchmark() =>
    BenchmarkBase.measureFor(() {
      for (int i = 0; i < ITERATIONS; i += 1) {
        doubleSink = dartifyDouble();
      }
    }, minimumMeasureDurationMillis) /
    ITERATIONS;

double? nullableDoubleSink;

double dartifyNullableDoubleBenchmark() =>
    BenchmarkBase.measureFor(() {
      for (int i = 0; i < ITERATIONS; i += 1) {
        nullableDoubleSink = dartifyNullableDouble();
      }
    }, minimumMeasureDurationMillis) /
    ITERATIONS;

int intSink = 0;

double dartifyIntBenchmark() =>
    BenchmarkBase.measureFor(() {
      for (int i = 0; i < ITERATIONS; i += 1) {
        intSink = dartifyInt();
      }
    }, minimumMeasureDurationMillis) /
    ITERATIONS;

int? nullableIntSink;

double dartifyNullableIntBenchmark() =>
    BenchmarkBase.measureFor(() {
      for (int i = 0; i < ITERATIONS; i += 1) {
        nullableIntSink = dartifyNullableInt();
      }
    }, minimumMeasureDurationMillis) /
    ITERATIONS;

String stringSink = '';

double dartifyStringBenchmark() =>
    BenchmarkBase.measureFor(() {
      for (int i = 0; i < ITERATIONS; i += 1) {
        stringSink = dartifyString();
      }
    }, minimumMeasureDurationMillis) /
    ITERATIONS;

String? nullableStringSink;

double dartifyNullableStringBenchmark() =>
    BenchmarkBase.measureFor(() {
      for (int i = 0; i < ITERATIONS; i += 1) {
        nullableStringSink = dartifyNullableString();
      }
    }, minimumMeasureDurationMillis) /
    ITERATIONS;

JSArray jsArraySink = JSArray();

double dartifyJSArrayBenchmark() =>
    BenchmarkBase.measureFor(() {
      for (int i = 0; i < ITERATIONS; i += 1) {
        jsArraySink = dartifyJSArray();
      }
    }, minimumMeasureDurationMillis) /
    ITERATIONS;

JSArray? nullableJsArraySink;

double dartifyNullableJSArrayBenchmark() =>
    BenchmarkBase.measureFor(() {
      for (int i = 0; i < ITERATIONS; i += 1) {
        nullableJsArraySink = dartifyNullableJSArray();
      }
    }, minimumMeasureDurationMillis) /
    ITERATIONS;

JSUint8Array jsUint8ArraySink = JSUint8Array();

double dartifyJSUint8ArrayBenchmark() =>
    BenchmarkBase.measureFor(() {
      for (int i = 0; i < ITERATIONS; i += 1) {
        jsUint8ArraySink = dartifyJSUint8Array();
      }
    }, minimumMeasureDurationMillis) /
    ITERATIONS;

JSUint8Array? nullableJsUint8ArraySink;

double dartifyNullableJSUint8ArrayBenchmark() =>
    BenchmarkBase.measureFor(() {
      for (int i = 0; i < ITERATIONS; i += 1) {
        nullableJsUint8ArraySink = dartifyNullableJSUint8Array();
      }
    }, minimumMeasureDurationMillis) /
    ITERATIONS;

void main() {
  eval('''
    self.intFun = (i) => i;
    self.doubleFun = (d) => d;
    self.dartifyBool = () => true;
    self.dartifyNullableBool = () => false;
    self.dartifyNum = () => 12.34;
    self.dartifyNullableNum = () => 56.78;
    self.dartifyDouble = () => 10.20;
    self.dartifyNullableDouble = () => 30.40;
    self.dartifyInt = () => 123;
    self.dartifyNullableInt = () => 456;
    self.dartifyString = () => "abc";
    self.dartifyNullableString = () => "def";

    // Arrays are all empty to not add element conversion overheads to the
    // benchmark results.
    self.dartifyJSArray = () => new Array();
    self.dartifyNullableJSArray = () => new Array();
    self.dartifyJSUint8Array = () => new Uint8Array(0);
    self.dartifyNullableJSUint8Array = () => new Uint8Array(0);
    ''');

  final maxI31 = (1 << 30) - 1;

  final small = IntPassingBenchmark(maxI31 - 1000000, maxI31).measure();
  report('WasmJSInterop.call.void.1ArgsSmi', small);

  final large = IntPassingBenchmark(maxI31 + 1, maxI31 + 1000001).measure();
  report('WasmJSInterop.call.void.1ArgsInt', large);

  // Have more than one call site to the `double` benchmark to avoid inlining
  // too much, and for fair comparison with the `int` benchmark above.
  DoublePassingBenchmark(1.0, 1.0, 10).measure();
  final double = DoublePassingBenchmark(1.0, 12.34, 1000000).measure();
  report('WasmJSInterop.call.void.1ArgsDouble', double);

  report('WasmJSInterop.call.bool.0Args', dartifyBoolBenchmark());
  report(
    'WasmJSInterop.call.nullableBool.0Args',
    dartifyNullableBoolBenchmark(),
  );
  report('WasmJSInterop.call.num.0Args', dartifyNumBenchmark());
  report('WasmJSInterop.call.nullableNum.0Args', dartifyNullableNumBenchmark());
  report('WasmJSInterop.call.double.0Args', dartifyDoubleBenchmark());
  report(
    'WasmJSInterop.call.nullableDouble.0Args',
    dartifyNullableDoubleBenchmark(),
  );
  report('WasmJSInterop.call.int.0Args', dartifyIntBenchmark());
  report('WasmJSInterop.call.nullableInt.0Args', dartifyNullableIntBenchmark());
  report('WasmJSInterop.call.string.0Args', dartifyStringBenchmark());
  report(
    'WasmJSInterop.call.nullableString.0Args',
    dartifyNullableStringBenchmark(),
  );
  report('WasmJSInterop.call.JSArray.0Args', dartifyJSArrayBenchmark());
  report(
    'WasmJSInterop.call.nullableJSArray.0Args',
    dartifyNullableJSArrayBenchmark(),
  );
  report(
    'WasmJSInterop.call.JSUint8Array.0Args',
    dartifyJSUint8ArrayBenchmark(),
  );
  report(
    'WasmJSInterop.call.nullableJSUint8Array.0Args',
    dartifyNullableJSUint8ArrayBenchmark(),
  );

  // To keep the sinks alive
  if (int.parse('1') == 0) {
    print(boolSink);
    print(nullableBoolSink);
    print(numSink);
    print(nullableNumSink);
    print(doubleSink);
    print(nullableDoubleSink);
    print(intSink);
    print(nullableIntSink);
    print(stringSink);
    print(nullableStringSink);
    print(jsArraySink);
    print(nullableJsArraySink);
    print(jsUint8ArraySink);
    print(nullableJsUint8ArraySink);
  }
}

/// Reports in Golem-specific format.
void report(String name, double usPerCall) {
  print('$name(RunTimeRaw): ${usPerCall * 1000} ns.');
}
