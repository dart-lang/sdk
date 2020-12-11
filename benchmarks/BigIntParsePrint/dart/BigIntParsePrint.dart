// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: avoid_function_literals_in_foreach_calls

import 'dart:math' show pow;

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

class ParseBigIntBenchmark extends BenchmarkBase {
  final int bits;
  final BigInt seed;
  final List<String> strings = [];

  ParseBigIntBenchmark(String name, this.bits)
      : seed = (BigInt.one << bits) - BigInt.one,
        super(name);

  @override
  void setup() {
    var b = seed;
    var totalLength = 0;
    while (totalLength < requiredDigits) {
      if (b.bitLength < bits) {
        b = seed;
      }
      final string = b.toString();
      strings.add(string);
      totalLength += string.length;
      b = b - (b >> 8);
    }
  }

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

int int64UnsignedBitLength(Int64 i) => i.isNegative ? 64 : i.bitLength;

class ParseInt64Benchmark extends BenchmarkBase {
  final int bits;
  final Int64 seed;
  final List<String> strings = [];

  ParseInt64Benchmark(String name, this.bits)
      : seed = (Int64.ONE << bits) - Int64.ONE,
        super(name);

  @override
  void setup() {
    var b = seed;
    var totalLength = 0;
    while (totalLength < requiredDigits) {
      if (int64UnsignedBitLength(b) < bits) {
        b = seed;
      }
      final string = b.toStringUnsigned();
      strings.add(string);
      totalLength += string.length;
      b = b - b.shiftRightUnsigned(8);
    }
  }

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

class ParseIntBenchmark extends BenchmarkBase {
  final int bits;
  final int seed;
  final List<String> strings = [];

  ParseIntBenchmark(String name, this.bits)
      : seed = (pow(2, bits) as int) - 1,
        super(name);

  @override
  void setup() {
    var b = seed;
    var totalLength = 0;
    while (totalLength < requiredDigits) {
      if (b.bitLength < bits) {
        b = seed;
      }
      final string = b.toString();
      strings.add(string);
      totalLength += string.length;
      b = b - b ~/ 256;
    }
  }

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

class ParseJsBigIntBenchmark extends BenchmarkBase {
  final int bits;
  final Object seed;
  final List<String> strings = [];

  ParseJsBigIntBenchmark(String name, this.bits)
      : seed = nativeBigInt.subtract(
            nativeBigInt.shiftLeft(
                nativeBigInt.one, nativeBigInt.fromInt(bits)),
            nativeBigInt.one),
        super(name);

  @override
  void setup() {
    var b = seed;
    var totalLength = 0;
    while (totalLength < requiredDigits) {
      if (nativeBigInt.bitLength(b) < bits) {
        b = seed;
      }
      final string = nativeBigInt.toStringMethod(b);
      strings.add(string);
      totalLength += string.length;
      b = nativeBigInt.subtract(
          b, nativeBigInt.shiftRight(b, nativeBigInt.eight));
    }
  }

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

class FormatBigIntBenchmark extends BenchmarkBase {
  final int bits;
  final BigInt seed;
  final List<BigInt> values = [];

  FormatBigIntBenchmark(String name, this.bits)
      : seed = (BigInt.one << bits) - BigInt.one,
        super(name);

  @override
  void setup() {
    var b = seed;
    var totalLength = 0;
    while (totalLength < requiredDigits) {
      if (b.bitLength < bits) {
        b = seed;
      }
      final string = b.toString();
      values.add(b - BigInt.one); // We add 'one' back later.
      totalLength += string.length;
      b = b - (b >> 8);
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

class FormatIntBenchmark extends BenchmarkBase {
  final int bits;
  final int seed;
  final List<int> values = [];

  FormatIntBenchmark(String name, this.bits)
      : seed = (pow(2, bits) as int) - 1,
        super(name);

  @override
  void setup() {
    var b = seed;
    var totalLength = 0;
    int kk = b ~/ 100000;
    while (totalLength < requiredDigits) {
      if (b.bitLength < bits) {
        b = seed - ++kk;
      }
      final string = b.toString();
      values.add(b - 4096); // We add 'one' back later.
      totalLength += string.length;
      b = b - (b ~/ 256);
    }
  }

  @override
  void run() {
    for (final b0 in values) {
      // Instances might cache `toString()`, so use arithmetic to create a new
      // instance to try to protect against measuring a cached string.
      final b = b0 + 4096;
      final s = b.toString();
      sink1 = s;
      sink2 = b;
    }
    check(sink2.isEven);
  }
}

class FormatInt64Benchmark extends BenchmarkBase {
  final int bits;
  final Int64 seed;
  final List<Int64> values = [];

  FormatInt64Benchmark(String name, this.bits)
      : seed = (Int64.ONE << bits) - Int64.ONE,
        super(name);

  @override
  void setup() {
    var b = seed;
    var totalLength = 0;
    while (totalLength < requiredDigits) {
      if (int64UnsignedBitLength(b) < bits) {
        b = seed;
      }
      final string = b.toStringUnsigned();
      values.add(b - Int64.ONE);
      totalLength += string.length;
      b = b - b.shiftRightUnsigned(8);
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

class FormatJsBigIntBenchmark extends BenchmarkBase {
  final int bits;
  final Object seed;
  final List<Object> values = [];

  FormatJsBigIntBenchmark(String name, this.bits)
      : seed = nativeBigInt.subtract(
            nativeBigInt.shiftLeft(
                nativeBigInt.one, nativeBigInt.fromInt(bits)),
            nativeBigInt.one),
        super(name);

  @override
  void setup() {
    final one = nativeBigInt.one;
    var b = seed;
    var totalLength = 0;
    while (totalLength < requiredDigits) {
      if (nativeBigInt.bitLength(b) < bits) {
        b = seed;
      }
      final string = nativeBigInt.toStringMethod(b);
      values.add(nativeBigInt.subtract(b, one)); // We add 'one' back later.
      totalLength += string.length;
      b = nativeBigInt.subtract(
          b, nativeBigInt.shiftRight(b, nativeBigInt.eight));
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
  double measure() => 2000 * 1000 * 1.0; // A rate of one run per 2s.
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
    () => FormatIntBenchmark('Int.toString.0064.bits', 63),
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
