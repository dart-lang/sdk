// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//

/// Benchmark for UTF-8 decoding, complex cases.
///
/// This benckmark complements the `Utf8Decode` benchmarks by exploring
/// different scenarios. There are three axes of variation - input complexity,
/// conversion type, and polymorphism. The variantions are represented in the
/// benchmark name, roughly
///
///     Utf8DecodeComplex.<polymorphism>.<conversion>.<data>.<complexity>.10k
///
/// ### Complexity
///
/// The input complexity is explored by having input sequences that are the
/// UTF-8 encoding of (1) ASCII strings ('ascii'), (2) strings that can be
/// represented by one-byte strings ('1byte'), and (3) strings need to be
/// represented by two-byte strings ('2byte').
///
/// Both of of these benchmarks process 10k bytes of input:
///
///     Utf8DecodeComplex.mono.simple.ascii.10k
///     Utf8DecodeComplex.mono.simple.2byte.10k
///
/// The first has ascii bytes as input, the simplest case. The second requires
/// parsing the variable-length UTF-8 code points.
///
/// ### Conversion
///
/// The conversion variations are 'simple', for a one-shot conversion of a List
/// of bytes to a string, and 'chunked' for a conversion that uses the chunked
/// conversion API to process the 10k bytes in chunks of a few hundred
/// bytes. This exercises different paths through the decoder. We would expect
/// the chuncked version to be slower, but only by a few percent.
///
/// ### Data
///
/// The type of the input is part of the benchmark name. When the input is a
/// modifiable `Unit8List`, there is no `.<data>` part to the name. Otherwise:
///
///     .list  - Input is a system List (`List.of`)
///     .unmodifiable - Input is an ummodifiable `Uint8List`.
///
/// ### Polymorphism
///
/// Polymorphism is explored by compiling several programs that run different
/// subsets of the benchmarks.
///
/// Whole-program optimizing compilers like AOT or dart2js can sometimes 'see'
/// that the conversion code is called with a single implementation of List and
/// optimize the code accordingly. This can produce faster code, but might be
/// too optimistic as prediction of real-world performance.
///
/// These two benchmarks run the same code, on a `Uint8List` containing the same
/// values. Other than the name, the benchmarks are identical:
///
///     Utf8DecodeComplex.mono.simple.ascii.10k
///     Utf8DecodeComplex.poly.simple.ascii.10k
///
/// The difference is that the 'mono' benchmark is part of a program that passes
/// only modifiable `Uint8List` lists to `utf8.decode`, whereas the 'poly'
/// benchmark is part of a program that passes several different List
/// implementation type to `utf8.decode`, including system lists (`List.of`) and
/// and unmodifiable Uint8Lists.
///
/// There are three monomorphic entry points which are called from the `main`
/// method of an otherwise trivial program - `mainMono1`, `mainMono2` and
/// `mainMono3`.  `mainMono1` does conversions exclusively on the preferred data
/// type, `Uint8List`.  `mainMono2` does conversions exclusively on the system
/// list type (`List.of`). `mainMono3` does conversions exclusively on
/// unmodifiable `Uint8List`.
///
/// The primary program calls the `mainPoly` entry point.
///
/// Benchmark results from the different programs can be collected into a single
/// suite.
library;

import 'dart:convert';
import 'dart:math' show min;
import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:expect/expect.dart';

// ASCII values which are start the sequence for quick validation that
// conversion happened.
const bytes0tag = 0x30;
const bytes1tag = 0x31;
const bytes2tag = 0x32;

// Input which decodes to a string where all code units are 7-bit ASCII.
const bytes0 = [
  bytes0tag, //    0, U+0030
  0x48, 0x45, 0x4C, 0x4C, 0x4f, 0x0A, // "HELLO\n"
];

// Input which decodes to a string where all code units fit in 1 byte.
const bytes1 = [
  bytes1tag, //    1, U+0031
  0x41, //         A, U+0040
  0xC2, 0xB1, //   ±, U+00B1
  0xC3, 0xB7, //   ÷, U+00F7
  0x0A, //         \n, U+000A
];

// Input which decodes to a string where some code units require 2 bytes.
const bytes2 = [
  bytes2tag, //              2, U+0032
  0x41, //                   A, U+0040
  0xC2, 0xB1, //             ±, U+00B1
  0xC3, 0xB7, //             ÷, U+00F7
  0xC4, 0x90, //             Đ, U+0111
  0xE0, 0xA6, 0x86, //       আ, U+0986
  0xF0, 0x9F, 0x87, 0xB9, // 🇹, U+1F1F9
  0xF0, 0x9F, 0x87, 0xBB, // 🇻, U+1F1FB  🇹🇻
];

const targetSize = 10000;
const chunkSize = 250;

void check(String result, List<int> sequence) {
  // Each sequence starts with a different ASCII value so we can quickly 'look
  // up' the expected length of the decoded expanded sequence.
  final expectedLength = switch (sequence[0]) {
    bytes0tag => targetSize,
    bytes1tag => 7144,
    bytes2tag => 5266,
    _ => throw 'Unexpected sequence start: ${sequence[0]}'
  };
  Expect.equals(expectedLength, result.length);
}

/// Expands a sequence by repetition and padding to `targetSize` bytes.
Uint8List makeSequence(List<int> bytes) {
  Expect.equals(
      1,
      bytes.length.gcd(chunkSize),
      'Bad repeated size (${bytes.length}).'
      ' Repeated sequence should be co-prime with chunk size ($chunkSize)'
      ' to exercise more UTF-8 boundaries');
  final repeats =
      List.filled(targetSize ~/ bytes.length, bytes).expand((byte) => byte);
  final padding = List.filled(targetSize.remainder(bytes.length), 0); // NULs.
  final sequence = Uint8List.fromList([...repeats, ...padding]);
  Expect.equals(targetSize, sequence.length);
  return sequence;
}

final Uint8List sequence0 = makeSequence(bytes0);
final Uint8List sequence1 = makeSequence(bytes1);
final Uint8List sequence2 = makeSequence(bytes2);

class Utf8DecodeBenchmarkBase extends BenchmarkBase {
  Utf8DecodeBenchmarkBase(String name) : super('Utf8DecodeComplex.$name');

  late int totalInputSize;

  @override
  void exercise() {
    // Only a single run per measurement instead of the usual 10.
    run();
  }

  @override
  double measure() {
    // Report time per input byte.
    return super.measure() / totalInputSize;
  }

  @override
  void report() {
    // Report time in nanoseconds.
    final double score = measure() * 1000.0;
    print('$name(RunTime): $score ns.');
  }
}

class Simple extends Utf8DecodeBenchmarkBase {
  final List<int> sequence;
  Simple(super.name, this.sequence) {
    totalInputSize = sequence.length;
  }

  @override
  void run() {
    final result = utf8.decode(sequence);
    check(result, sequence);
  }
}

abstract class ChunkedBase extends Utf8DecodeBenchmarkBase {
  final List<int> sequence;
  late List<List<int>> chunks;
  ChunkedBase(super.name, this.sequence);

  List<int> slice(List<int> list, int start, int end);

  @override
  void setup() {
    totalInputSize = sequence.length;
    chunks = [];
    for (int i = 0; i < totalInputSize; i += chunkSize) {
      final chunk = slice(sequence, i, min(i + chunkSize, totalInputSize));
      chunks.add(chunk);
    }
  }

  @override
  void run() {
    late final String result;
    final byteSink = const Utf8Decoder().startChunkedConversion(
        StringConversionSink.withCallback((s) => result = s));

    for (final chunk in chunks) {
      byteSink.add(chunk);
    }
    byteSink.close();
    check(result, sequence);
  }
}

class Chunked extends ChunkedBase {
  Chunked(super.name, super.sequence);

  @override
  List<int> slice(List<int> list, int start, int end) {
    return list.sublist(start, end);
  }
}

class ChunkedUnmodifiable extends ChunkedBase {
  ChunkedUnmodifiable(super.name, Uint8List super.sequence);

  @override
  Uint8List slice(List<int> list, int start, int end) {
    return Uint8List.fromList(list.sublist(start, end)).asUnmodifiableView();
  }
}

void runAll(List<BenchmarkBase> benchmarks) {
  // Warm up all the benchmarks to avoid overly optimistic results for the first
  // few benchmarks due to temporary monomorphism in JIT compilers.
  for (var bm in benchmarks) {
    bm.setup();
    bm.warmup();
  }

  for (var bm in benchmarks) {
    bm.report();
  }
}

void mainPoly() {
  // Polymorphic: Inputs of several types.
  final benchmarks = [
    Simple('poly.simple.ascii.10k', sequence0),
    Simple('poly.simple.1byte.10k', sequence1),
    Simple('poly.simple.2byte.10k', sequence2),
    Simple('poly.simple.list.ascii.10k', List.of(sequence0)),
    Simple('poly.simple.list.1byte.10k', List.of(sequence1)),
    Simple('poly.simple.list.2byte.10k', List.of(sequence2)),
    Simple(
        'poly.simple.unmodifiable.ascii.10k', sequence0.asUnmodifiableView()),
    Simple(
        'poly.simple.unmodifiable.1byte.10k', sequence1.asUnmodifiableView()),
    Simple(
        'poly.simple.unmodifiable.2byte.10k', sequence2.asUnmodifiableView()),
    Chunked('poly.chunked.ascii.10k', sequence0),
    Chunked('poly.chunked.1byte.10k', sequence1),
    Chunked('poly.chunked.2byte.10k', sequence2),
    Chunked('poly.chunked.list.ascii.10k', List.of(sequence0)),
    Chunked('poly.chunked.list.1byte.10k', List.of(sequence1)),
    Chunked('poly.chunked.list.2byte.10k', List.of(sequence2)),
    ChunkedUnmodifiable(
        'poly.chunked.unmodifiable.ascii.10k', sequence0.asUnmodifiableView()),
    ChunkedUnmodifiable(
        'poly.chunked.unmodifiable.1byte.10k', sequence1.asUnmodifiableView()),
    ChunkedUnmodifiable(
        'poly.chunked.unmodifiable.2byte.10k', sequence2.asUnmodifiableView()),
  ];
  runAll(benchmarks);
}

void mainMono1() {
  // Monomorphic: All inputs are `Uint8List`s.
  final benchmarks = [
    Simple('mono.simple.ascii.10k', sequence0),
    Simple('mono.simple.1byte.10k', sequence1),
    Simple('mono.simple.2byte.10k', sequence2),
    Chunked('mono.chunked.ascii.10k', sequence0),
    Chunked('mono.chunked.1byte.10k', sequence1),
    Chunked('mono.chunked.2byte.10k', sequence2),
  ];
  runAll(benchmarks);
}

void mainMono2() {
  // Monomorphic: All inputs are ordinary (system) Lists.
  final benchmarks = [
    Simple('mono.simple.list.ascii.10k', List.of(sequence0)),
    Simple('mono.simple.list.1byte.10k', List.of(sequence1)),
    Simple('mono.simple.list.2byte.10k', List.of(sequence2)),
    Chunked('mono.chunked.list.ascii.10k', List.of(sequence0)),
    Chunked('mono.chunked.list.1byte.10k', List.of(sequence1)),
    Chunked('mono.chunked.list.2byte.10k', List.of(sequence2)),
  ];
  runAll(benchmarks);
}

void mainMono3() {
  // Monomorphic: All inputs are unmodifiable `Uint8List`s.
  final benchmarks = [
    Simple(
        'mono.simple.unmodifiable.ascii.10k', sequence0.asUnmodifiableView()),
    Simple(
        'mono.simple.unmodifiable.1byte.10k', sequence1.asUnmodifiableView()),
    Simple(
        'mono.simple.unmodifiable.2byte.10k', sequence2.asUnmodifiableView()),
    ChunkedUnmodifiable(
        'mono.chunked.unmodifiable.ascii.10k', sequence0.asUnmodifiableView()),
    ChunkedUnmodifiable(
        'mono.chunked.unmodifiable.1byte.10k', sequence1.asUnmodifiableView()),
    ChunkedUnmodifiable(
        'mono.chunked.unmodifiable.2byte.10k', sequence2.asUnmodifiableView()),
  ];
  runAll(benchmarks);
}
