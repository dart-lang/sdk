// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: avoid_function_literals_in_foreach_calls

import 'dart:math' show Random;

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:fixnum/fixnum.dart';

import 'native_version_dummy.dart'
    if (dart.library.js) 'native_version_javascript.dart';

// Benckmark BigInt and Int64 formatting and parsing.

// A global sink that is used in the [check] method ensures that the results are
// not optimized.
dynamic sink1, sink2;

void check(bool sink2isEven) {
  if (sink1.codeUnits.last.isEven != sink2isEven) {
    throw StateError('Inconsistent $sink1 vs $sink2');
  }
}

// These benchmarks measure digit-throughput for parsing and formatting.
//
// Each benchmark targets processing [requiredDigits] decimal digits, spread
// over a list of input values. This makes the benchmarks for different integer
// lengths roughly comparable.  The number is chosen so that most benchmarks
// have very close to this number of digits. It corresponds to nine 4096-bit
// integers.
const requiredDigits = 11106;

class Benchmark extends BenchmarkBase {
  final List<String> strings;
  Benchmark(String name, int bits, {bool forInt = false})
      : strings = generateStrings(bits, forInt),
        super(name);

  static List<String> generateStrings(int bits, bool forInt) {
    final List<String> strings = [];
    final BigInt seed = (BigInt.one << bits) - BigInt.one;
    var b = seed;
    var restartDelta = BigInt.zero;
    var totalLength = 0;
    while (totalLength < requiredDigits) {
      if (b.bitLength < bits) {
        restartDelta += seed >> 20;
        restartDelta += BigInt.one;
        // Restart from a slighly reduced seed to generate different numbers.
        b = seed - restartDelta;
      }
      var string = b.toString();

      // Web integers lose precision due to rounding for larger values. Make
      // sure the string will round-trip correctly.
      if (forInt) string = int.parse(string).toString();

      strings.add(string);
      totalLength += string.length;
      var delta = b >> 8;
      if (delta == BigInt.zero) delta = BigInt.one;
      b = b - delta;
    }
    return strings;
  }
}

class ParseBigIntBenchmark extends Benchmark {
  ParseBigIntBenchmark(String name, int bits) : super(name, bits);

  @override
  void run() {
    for (final s in strings) {
      final b = BigInt.parse(s);
      sink1 = s;
      sink2 = b;
    }
    check(sink2.isEven);
  }
}

class ParseInt64Benchmark extends Benchmark {
  ParseInt64Benchmark(String name, int bits) : super(name, bits);

  @override
  void run() {
    for (final s in strings) {
      final b = Int64.parseInt(s);
      sink1 = s;
      sink2 = b;
    }
    check(sink2.isEven);
  }
}

class ParseIntBenchmark extends Benchmark {
  ParseIntBenchmark(String name, int bits) : super(name, bits, forInt: true);

  @override
  void run() {
    for (final s in strings) {
      final b = int.parse(s);
      sink1 = s;
      sink2 = b;
    }
    check(sink2.isEven);
  }
}

class ParseJsBigIntBenchmark extends Benchmark {
  ParseJsBigIntBenchmark(String name, int bits) : super(name, bits);

  @override
  void run() {
    for (final s in strings) {
      final b = nativeBigInt.parse(s);
      sink1 = s;
      sink2 = b;
    }
    check(nativeBigInt.isEven(sink2));
  }
}

class FormatBigIntBenchmark extends Benchmark {
  final List<BigInt> values = [];

  FormatBigIntBenchmark(String name, int bits) : super(name, bits);

  @override
  void setup() {
    for (String s in strings) {
      final BigInt b = BigInt.parse(s);
      values.add(b - BigInt.one); // We add 'one' back later.
    }
  }

  @override
  void run() {
    final one = BigInt.one;
    for (final b0 in values) {
      // Instances might cache `toString()`, so use arithmetic to create a new
      // instance to try to protect against measuring a cached string.
      final b = b0 + one;
      final s = b.toString();
      sink1 = s;
      sink2 = b;
    }
    check(sink2.isEven);
  }
}

class FormatIntBenchmark extends Benchmark {
  final List<int> values = [];

  FormatIntBenchmark(String name, int bits) : super(name, bits, forInt: true);

  @override
  void setup() {
    for (String s in strings) {
      final int b = int.parse(s);
      values.add(b - 4096); // We add this back later.
    }
  }

  @override
  void run() {
    for (final b0 in values) {
      // Instances might cache `toString()`, so use arithmetic to create a new
      // instance to try to protect against measuring a cached string.  We use
      // 4096 to avoid the arithmetic being a no-op due to rounding on web
      // integers (i.e. doubles).
      final b = b0 + 4096;
      final s = b.toString();
      sink1 = s;
      sink2 = b;
    }
    check(sink2.isEven);
  }
}

class FormatInt64Benchmark extends Benchmark {
  final List<Int64> values = [];

  FormatInt64Benchmark(String name, int bits) : super(name, bits);

  @override
  void setup() {
    for (String s in strings) {
      final b = Int64.parseInt(s);
      values.add(b - Int64.ONE); // We add this back later.
    }
  }

  @override
  void run() {
    final one = Int64.ONE;
    for (final b0 in values) {
      // Instances might cache `toString()`, so use arithmetic to create a new
      // instance to try to protect against measuring a cached string.
      final b = b0 + one;
      final s = b.toStringUnsigned();
      sink1 = s;
      sink2 = b;
    }
    check(sink2.isEven);
  }
}

class FormatJsBigIntBenchmark extends Benchmark {
  final List<Object> values = [];

  FormatJsBigIntBenchmark(String name, int bits) : super(name, bits);

  @override
  void setup() {
    final one = nativeBigInt.one;
    for (String s in strings) {
      final b = nativeBigInt.parse(s);
      values.add(nativeBigInt.subtract(b, one)); // We add this back later.
    }
  }

  @override
  void run() {
    final one = nativeBigInt.one;
    for (final b0 in values) {
      // Instances might cache `toString()`, so use arithmetic to create a new
      // instance to try to protect against measuring a cached string.
      final b = nativeBigInt.add(b0, one);
      final s = nativeBigInt.toStringMethod(b);
      sink1 = s;
      sink2 = b;
    }
    check(nativeBigInt.isEven(sink2));
  }
}

/// [DummyBenchmark] instantly returns a fixed 'slow' result.
class DummyBenchmark extends BenchmarkBase {
  DummyBenchmark(String name) : super(name);
  @override
  // A rate of one run per 2s, with a millisecond of noise.  Some variation is
  // needed for Golem's noise-based filtering and regression detection.
  double measure() => (2000 + Random().nextDouble() - 0.5) * 1000;
}

/// Create [ParseJsBigIntBenchmark], or a dummy benchmark if JavaScript BigInt
/// is not available.  This is to satisfy Golem's constraint that group
/// benchmarks always produce results for the same set of series.
BenchmarkBase Function() selectParseNativeBigIntBenchmark(
    String name, int bits) {
  return nativeBigInt.enabled
      ? () => ParseJsBigIntBenchmark(name, bits)
      : () => DummyBenchmark(name);
}

/// Create [FormatJsBigIntBenchmark], or a dummy benchmark if JavaScript BigInt
/// is not available.  This is to satisfy Golem's constraint that group
/// benchmarks always produce results for the same set of series.
BenchmarkBase Function() selectFormatNativeBigIntBenchmark(
    String name, int bits) {
  return nativeBigInt.enabled
      ? () => FormatJsBigIntBenchmark(name, bits)
      : () => DummyBenchmark(name);
}

void main() {
  final benchmarks = [
    () => ParseIntBenchmark('Int.parse.0009.bits', 9),
    () => ParseIntBenchmark('Int.parse.0032.bits', 32),
    // Use '63' bits to avoid 64-bit arithmetic overflowing to negative. Keep
    // the name as '64' to help comparisons.  The effect of an incorrect number
    // is reduced since benchmark results are normalized to a 'per digit' score
    () => ParseIntBenchmark('Int.parse.0064.bits', 63),
    () => ParseInt64Benchmark('Int64.parse.0009.bits', 9),
    () => ParseInt64Benchmark('Int64.parse.0032.bits', 32),
    () => ParseInt64Benchmark('Int64.parse.0064.bits', 64),
    () => ParseBigIntBenchmark('BigInt.parse.0009.bits', 9),
    () => ParseBigIntBenchmark('BigInt.parse.0032.bits', 32),
    () => ParseBigIntBenchmark('BigInt.parse.0064.bits', 64),
    () => ParseBigIntBenchmark('BigInt.parse.0256.bits', 256),
    () => ParseBigIntBenchmark('BigInt.parse.1024.bits', 1024),
    () => ParseBigIntBenchmark('BigInt.parse.4096.bits', 4096),
    selectParseNativeBigIntBenchmark('JsBigInt.parse.0009.bits', 9),
    selectParseNativeBigIntBenchmark('JsBigInt.parse.0032.bits', 32),
    selectParseNativeBigIntBenchmark('JsBigInt.parse.0064.bits', 64),
    selectParseNativeBigIntBenchmark('JsBigInt.parse.0256.bits', 256),
    selectParseNativeBigIntBenchmark('JsBigInt.parse.1024.bits', 1024),
    selectParseNativeBigIntBenchmark('JsBigInt.parse.4096.bits', 4096),
    () => FormatIntBenchmark('Int.toString.0009.bits', 9),
    () => FormatIntBenchmark('Int.toString.0032.bits', 32),
    () => FormatIntBenchmark('Int.toString.0064.bits', 63), // '63': See above.
    () => FormatInt64Benchmark('Int64.toString.0009.bits', 9),
    () => FormatInt64Benchmark('Int64.toString.0032.bits', 32),
    () => FormatInt64Benchmark('Int64.toString.0064.bits', 64),
    () => FormatBigIntBenchmark('BigInt.toString.0009.bits', 9),
    () => FormatBigIntBenchmark('BigInt.toString.0032.bits', 32),
    () => FormatBigIntBenchmark('BigInt.toString.0064.bits', 64),
    () => FormatBigIntBenchmark('BigInt.toString.0256.bits', 256),
    () => FormatBigIntBenchmark('BigInt.toString.1024.bits', 1024),
    () => FormatBigIntBenchmark('BigInt.toString.4096.bits', 4096),
    selectFormatNativeBigIntBenchmark('JsBigInt.toString.0009.bits', 9),
    selectFormatNativeBigIntBenchmark('JsBigInt.toString.0032.bits', 32),
    selectFormatNativeBigIntBenchmark('JsBigInt.toString.0064.bits', 64),
    selectFormatNativeBigIntBenchmark('JsBigInt.toString.0256.bits', 256),
    selectFormatNativeBigIntBenchmark('JsBigInt.toString.1024.bits', 1024),
    selectFormatNativeBigIntBenchmark('JsBigInt.toString.4096.bits', 4096),
  ];

  // Warm up all benchmarks to ensure consistent behavious of shared code.
  benchmarks.forEach((bm) => bm()
    ..setup()
    ..run()
    ..run());

  benchmarks.forEach((bm) => bm().report());
}
