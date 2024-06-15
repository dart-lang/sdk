// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';
import 'dart:math' as math;

import 'package:benchmark_harness/benchmark_harness.dart';

// Benchmark for converting Dart functions to JS and calling them.
//
// Contains the following benchmarks:
// - A series that determines how expensive calling `Function.toJS` is. These
//   are prefixed with `Convert`. These contain two dimensions in their names:
//   - Whether the function that is being wrapped is an `Instance` method,
//     `Static` method, `Closure`, or a closure that is stored in a field
//     (`ClosureField`).
//   - The arity of the function: `Zero`, `Two`, and `Eight` arguments.
// - A series that determines how expensive calling the result of a
//   `Function.toJS`-wrapped function using interop is. These are prefixed with
//   `CallJS`. These contain the same dimensions as the `Convert` series, except
//   there is no `ClosureField` series as it would be the same as `Closure`.
// - A series that determines how expensive calling a closure that's stored in a
//   field in Dart is. These are prefixed with `CallDartClosure`. They only
//   contain one dimension, which is the arity of the function. This is used to
//   compare the performance of calling a wrapped function versus calling it
//   directly.

// Caching the function to a global should help avoid V8 from optimizing the
// call away.
@JS()
external set cache(JSFunction jsFunction);

extension on JSFunction {
  external int call(
      [JSAny? thisArg,
      int? arg1,
      int? arg2,
      int? arg3,
      int? arg4,
      int? arg5,
      int? arg6,
      int? arg7,
      int? arg8]);
}

final random = math.Random();

class ConvertInstanceZeroBenchmark extends BenchmarkBase {
  ConvertInstanceZeroBenchmark() : super('FunctionToJs.Convert.Instance.0');

  final int randomInt = random.nextInt(10);

  @pragma('dart2js:never-inline')
  int zero() => randomInt;

  @override
  void run() {
    cache = zero.toJS;
  }
}

class ConvertInstanceTwoBenchmark extends BenchmarkBase {
  ConvertInstanceTwoBenchmark() : super('FunctionToJs.Convert.Instance.2');

  final int randomInt = random.nextInt(10);

  @pragma('dart2js:never-inline')
  int two(int arg1, int arg2) => randomInt + arg1 + arg2;

  @override
  void run() {
    cache = two.toJS;
  }
}

class ConvertInstanceEightBenchmark extends BenchmarkBase {
  ConvertInstanceEightBenchmark() : super('FunctionToJs.Convert.Instance.8');

  final int randomInt = random.nextInt(10);

  @pragma('dart2js:never-inline')
  int eight(int arg1, int arg2, int arg3, int arg4, int arg5, int arg6,
          int arg7, int arg8) =>
      randomInt + arg1 + arg2 + arg3 + arg4 + arg5 + arg6 + arg7 + arg8;

  @override
  void run() {
    cache = eight.toJS;
  }
}

class ConvertStaticZeroBenchmark extends BenchmarkBase {
  ConvertStaticZeroBenchmark() : super('FunctionToJs.Convert.Static.0');

  static final int randomInt = random.nextInt(10);

  static int zero() => randomInt;

  @override
  void run() {
    cache = zero.toJS;
  }
}

class ConvertStaticTwoBenchmark extends BenchmarkBase {
  ConvertStaticTwoBenchmark() : super('FunctionToJs.Convert.Static.2');

  static final int randomInt = random.nextInt(10);

  static int two(int arg1, int arg2) => randomInt + arg1 + arg2;

  @override
  void run() {
    cache = two.toJS;
  }
}

class ConvertStaticEightBenchmark extends BenchmarkBase {
  ConvertStaticEightBenchmark() : super('FunctionToJs.Convert.Static.8');

  static final int randomInt = random.nextInt(10);

  static int eight(int arg1, int arg2, int arg3, int arg4, int arg5, int arg6,
          int arg7, int arg8) =>
      randomInt + arg1 + arg2 + arg3 + arg4 + arg5 + arg6 + arg7 + arg8;

  @override
  void run() {
    cache = eight.toJS;
  }
}

class ConvertClosureZeroBenchmark extends BenchmarkBase {
  ConvertClosureZeroBenchmark() : super('FunctionToJs.Convert.Closure.0');

  final int randomInt = random.nextInt(10);

  @override
  void run() {
    cache = (() => randomInt).toJS;
  }
}

class ConvertClosureTwoBenchmark extends BenchmarkBase {
  ConvertClosureTwoBenchmark() : super('FunctionToJs.Convert.Closure.2');

  final int randomInt = random.nextInt(10);

  @override
  void run() {
    cache = ((int arg1, int arg2) => randomInt + arg1 + arg2).toJS;
  }
}

class ConvertClosureEightBenchmark extends BenchmarkBase {
  ConvertClosureEightBenchmark() : super('FunctionToJs.Convert.Closure.8');

  final int randomInt = random.nextInt(10);

  @override
  void run() {
    cache = ((int arg1, int arg2, int arg3, int arg4, int arg5, int arg6,
            int arg7, int arg8) =>
        randomInt + arg1 + arg2 + arg3 + arg4 + arg5 + arg6 + arg7 + arg8).toJS;
  }
}

class ConvertClosureFieldZeroBenchmark extends BenchmarkBase {
  ConvertClosureFieldZeroBenchmark()
      : super('FunctionToJs.Convert.ClosureField.0');

  late int Function() closure;
  final int randomInt = random.nextInt(10);

  @override
  void setup() {
    closure = () => randomInt;
  }

  @override
  void run() {
    cache = closure.toJS;
  }
}

class ConvertClosureFieldTwoBenchmark extends BenchmarkBase {
  ConvertClosureFieldTwoBenchmark()
      : super('FunctionToJs.Convert.ClosureField.2');

  late int Function(int, int) closure;
  final int randomInt = random.nextInt(10);

  @override
  void setup() {
    closure = (int arg1, int arg2) => randomInt + arg1 + arg2;
  }

  @override
  void run() {
    cache = closure.toJS;
  }
}

class ConvertClosureFieldEightBenchmark extends BenchmarkBase {
  ConvertClosureFieldEightBenchmark()
      : super('FunctionToJs.Convert.ClosureField.8');

  late int Function(int, int, int, int, int, int, int, int) closure;
  final int randomInt = random.nextInt(10);

  @override
  void setup() {
    closure = (int arg1, int arg2, int arg3, int arg4, int arg5, int arg6,
            int arg7, int arg8) =>
        randomInt + arg1 + arg2 + arg3 + arg4 + arg5 + arg6 + arg7 + arg8;
  }

  @override
  void run() {
    cache = closure.toJS;
  }
}

class CallJSInstanceZeroBenchmark extends BenchmarkBase {
  CallJSInstanceZeroBenchmark() : super('FunctionToJs.CallJS.Instance.0');

  late JSExportedDartFunction jsFunction;
  final int randomInt = random.nextInt(10);

  @pragma('dart2js:never-inline')
  int zero() => randomInt;

  @override
  void setup() {
    jsFunction = zero.toJS;
  }

  @override
  void run() {
    final val = jsFunction.call();
    if (val < 0 || val >= 10) throw 'Bad result: $val';
  }
}

class CallJSInstanceTwoBenchmark extends BenchmarkBase {
  CallJSInstanceTwoBenchmark() : super('FunctionToJs.CallJS.Instance.2');

  late JSExportedDartFunction jsFunction;
  final int randomInt = random.nextInt(10);

  @pragma('dart2js:never-inline')
  int two(int arg1, int arg2) => randomInt + arg1 + arg2;

  @override
  void setup() {
    jsFunction = two.toJS;
  }

  @override
  void run() {
    final val = jsFunction.call(null, 1, 1);
    if (val < 2 || val >= 12) throw 'Bad result: $val';
  }
}

class CallJSInstanceEightBenchmark extends BenchmarkBase {
  CallJSInstanceEightBenchmark() : super('FunctionToJs.CallJS.Instance.8');

  late JSExportedDartFunction jsFunction;
  final int randomInt = random.nextInt(10);

  @pragma('dart2js:never-inline')
  int eight(int arg1, int arg2, int arg3, int arg4, int arg5, int arg6,
          int arg7, int arg8) =>
      randomInt + arg1 + arg2 + arg3 + arg4 + arg5 + arg6 + arg7 + arg8;

  @override
  void setup() {
    jsFunction = eight.toJS;
  }

  @override
  void run() {
    final val = jsFunction.call(null, 1, 1, 1, 1, 1, 1, 1, 1);
    if (val < 8 || val >= 18) throw 'Bad result: $val';
  }
}

class CallJSStaticZeroBenchmark extends BenchmarkBase {
  CallJSStaticZeroBenchmark() : super('FunctionToJs.CallJS.Static.0');

  static final int randomInt = random.nextInt(10);

  static int zero() => randomInt;

  late JSExportedDartFunction jsFunction;

  @override
  void setup() {
    jsFunction = zero.toJS;
  }

  @override
  void run() {
    final val = jsFunction.call();
    if (val < 0 || val >= 10) throw 'Bad result: $val';
  }
}

class CallJSStaticTwoBenchmark extends BenchmarkBase {
  CallJSStaticTwoBenchmark() : super('FunctionToJs.CallJS.Static.2');

  static final int randomInt = random.nextInt(10);

  static int two(int arg1, int arg2) => randomInt + arg1 + arg2;

  late JSExportedDartFunction jsFunction;

  @override
  void setup() {
    jsFunction = two.toJS;
  }

  @override
  void run() {
    final val = jsFunction.call(null, 1, 1);
    if (val < 2 || val >= 12) throw 'Bad result: $val';
  }
}

class CallJSStaticEightBenchmark extends BenchmarkBase {
  CallJSStaticEightBenchmark() : super('FunctionToJs.CallJS.Static.8');

  static final int randomInt = random.nextInt(10);

  static int eight(int arg1, int arg2, int arg3, int arg4, int arg5, int arg6,
          int arg7, int arg8) =>
      randomInt + arg1 + arg2 + arg3 + arg4 + arg5 + arg6 + arg7 + arg8;

  late JSExportedDartFunction jsFunction;

  @override
  void setup() {
    jsFunction = eight.toJS;
  }

  @override
  void run() {
    final val = jsFunction.call(null, 1, 1, 1, 1, 1, 1, 1, 1);
    if (val < 8 || val >= 18) throw 'Bad result: $val';
  }
}

class CallJSClosureZeroBenchmark extends BenchmarkBase {
  CallJSClosureZeroBenchmark() : super('FunctionToJs.CallJS.Closure.0');

  late JSExportedDartFunction jsFunction;
  final int randomInt = random.nextInt(10);

  @override
  void setup() {
    jsFunction = (() => randomInt).toJS;
  }

  @override
  void run() {
    final val = jsFunction.call();
    if (val < 0 || val >= 10) throw 'Bad result: $val';
  }
}

class CallJSClosureTwoBenchmark extends BenchmarkBase {
  CallJSClosureTwoBenchmark() : super('FunctionToJs.CallJS.Closure.2');

  late JSExportedDartFunction jsFunction;
  final int randomInt = random.nextInt(10);

  @override
  void setup() {
    jsFunction = ((int arg1, int arg2) => randomInt + arg1 + arg2).toJS;
  }

  @override
  void run() {
    final val = jsFunction.call(null, 1, 1);
    if (val < 2 || val >= 12) throw 'Bad result: $val';
  }
}

class CallJSClosureEightBenchmark extends BenchmarkBase {
  CallJSClosureEightBenchmark() : super('FunctionToJs.CallJS.Closure.8');

  late JSExportedDartFunction jsFunction;
  final int randomInt = random.nextInt(10);

  @override
  void setup() {
    jsFunction = ((int arg1, int arg2, int arg3, int arg4, int arg5, int arg6,
            int arg7, int arg8) =>
        randomInt + arg1 + arg2 + arg3 + arg4 + arg5 + arg6 + arg7 + arg8).toJS;
  }

  @override
  void run() {
    final val = jsFunction.call(null, 1, 1, 1, 1, 1, 1, 1, 1);
    if (val < 8 || val >= 18) throw 'Bad result: $val';
  }
}

class CallDartClosureZeroBenchmark extends BenchmarkBase {
  CallDartClosureZeroBenchmark() : super('FunctionToJs.CallDart.Closure.0');

  late int Function() closure;
  final int randomInt = random.nextInt(10);

  @override
  void setup() {
    closure = () => randomInt;
  }

  @override
  void run() {
    final val = closure();
    if (val < 0 || val >= 10) throw 'Bad result: $val';
  }
}

class CallDartClosureTwoBenchmark extends BenchmarkBase {
  CallDartClosureTwoBenchmark() : super('FunctionToJs.CallDart.Closure.2');

  late int Function(int, int) closure;
  final int randomInt = random.nextInt(10);

  @override
  void setup() {
    closure = (int arg1, int arg2) => randomInt + arg1 + arg2;
  }

  @override
  void run() {
    final val = closure(1, 1);
    if (val < 2 || val >= 12) throw 'Bad result: $val';
  }
}

class CallDartClosureEightBenchmark extends BenchmarkBase {
  CallDartClosureEightBenchmark() : super('FunctionToJs.CallDart.Closure.8');

  late int Function(int, int, int, int, int, int, int, int) closure;
  final int randomInt = random.nextInt(10);

  @override
  void setup() {
    closure = (int arg1, int arg2, int arg3, int arg4, int arg5, int arg6,
            int arg7, int arg8) =>
        randomInt + arg1 + arg2 + arg3 + arg4 + arg5 + arg6 + arg7 + arg8;
  }

  @override
  void run() {
    final val = closure(1, 1, 1, 1, 1, 1, 1, 1);
    if (val < 8 || val >= 18) throw 'Bad result: $val';
  }
}

void main() {
  final benchmarks = [
    ConvertInstanceZeroBenchmark(),
    ConvertInstanceTwoBenchmark(),
    ConvertInstanceEightBenchmark(),
    ConvertStaticZeroBenchmark(),
    ConvertStaticTwoBenchmark(),
    ConvertStaticEightBenchmark(),
    ConvertClosureZeroBenchmark(),
    ConvertClosureTwoBenchmark(),
    ConvertClosureEightBenchmark(),
    ConvertClosureFieldZeroBenchmark(),
    ConvertClosureFieldTwoBenchmark(),
    ConvertClosureFieldEightBenchmark(),
    CallJSInstanceZeroBenchmark(),
    CallJSInstanceTwoBenchmark(),
    CallJSInstanceEightBenchmark(),
    CallJSStaticZeroBenchmark(),
    CallJSStaticTwoBenchmark(),
    CallJSStaticEightBenchmark(),
    CallJSClosureZeroBenchmark(),
    CallJSClosureTwoBenchmark(),
    CallJSClosureEightBenchmark(),
    CallDartClosureZeroBenchmark(),
    CallDartClosureTwoBenchmark(),
    CallDartClosureEightBenchmark(),
  ];
  // Warmup all benchmarks so that the first benchmark doesn't get overfitted by
  // a JIT compiler.
  for (final benchmark in benchmarks) {
    benchmark.setup();
  }
  for (var i = 0; i < 10; i++) {
    for (final benchmark in benchmarks) {
      benchmark.run();
    }
  }
  for (final benchmark in benchmarks) {
    benchmark.report();
  }
}
