// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This files contains methods for benchmarking Kernel binary serialization
// and deserialization routines.

import 'package:kernel/ast.dart';
import 'package:kernel/binary/ast_from_binary.dart';
import 'package:kernel/binary/ast_to_binary.dart';

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const usage = '''
Usage: binary_bench.dart [--golem] <Benchmark> <SourceDill>

Benchmark can be one of the following:

* ast-to-binary
* ast-from-binary-lazy
* ast-from-binary-eager
''';

enum Mode { astToBinary, astFromBinaryLazy, astFromBinaryEager }

Mode mode;
File sourceDill;
bool forGolem = false;

main(List<String> args) async {
  if (!_parseArgs(args)) {
    print(usage);
    exit(-1);
  }

  final bytes = sourceDill.readAsBytesSync();
  switch (mode) {
    case Mode.astFromBinaryLazy:
      _benchmarkAstFromBinary(bytes, eager: false);
      break;
    case Mode.astFromBinaryEager:
      _benchmarkAstFromBinary(bytes, eager: true);
      break;
    case Mode.astToBinary:
      _benchmarkAstToBinary(bytes);
      break;
  }
}

const warmupIterations = 100;
const benchmarkIterations = 50;

void _benchmarkAstFromBinary(Uint8List bytes, {bool eager: true}) {
  final sw = new Stopwatch()..start();
  _fromBinary(bytes, eager: eager);
  final coldRunUs = sw.elapsedMicroseconds;
  sw.reset();

  for (var i = 0; i < warmupIterations; i++) {
    _fromBinary(bytes, eager: eager);
  }
  final warmupUs = sw.elapsedMicroseconds / warmupIterations;

  final runsUs = new List<int>(benchmarkIterations);
  for (var i = 0; i < benchmarkIterations; i++) {
    sw.reset();
    _fromBinary(bytes, eager: eager);
    runsUs[i] = sw.elapsedMicroseconds;
  }

  final nameSuffix = eager ? 'Eager' : 'Lazy';
  new BenchmarkResult('AstFromBinary${nameSuffix}', coldRunUs, warmupUs, runsUs)
      .report();
}

void _benchmarkAstToBinary(Uint8List bytes) {
  final p = _fromBinary(bytes, eager: true);
  final sw = new Stopwatch()..start();
  _toBinary(p);
  final coldRunUs = sw.elapsedMicroseconds;
  sw.reset();

  for (var i = 0; i < warmupIterations; i++) {
    _toBinary(p);
  }
  final warmupUs = sw.elapsedMicroseconds / warmupIterations;

  final runsUs = new List<int>(benchmarkIterations);
  for (var i = 0; i < benchmarkIterations; i++) {
    sw.reset();
    _toBinary(p);
    runsUs[i] = sw.elapsedMicroseconds;
  }

  new BenchmarkResult('AstToBinary', coldRunUs, warmupUs, runsUs).report();
}

class BenchmarkResult {
  final String name;
  final int coldRunUs;
  final double warmupUs;
  final List<int> runsUs;

  BenchmarkResult(this.name, this.coldRunUs, this.warmupUs, this.runsUs);

  static T add<T extends num>(T x, T y) => x + y;

  void report() {
    runsUs.sort();

    P(int p) => runsUs[((runsUs.length - 1) * (p / 100)).ceil()];

    final sum = runsUs.reduce(add);
    final avg = sum / runsUs.length;
    final min = runsUs.first;
    final max = runsUs.last;
    final std =
        sqrt(runsUs.map((v) => pow(v - avg, 2)).reduce(add) / runsUs.length);

    if (!forGolem) {
      print('${name}Cold: ${coldRunUs} us');
      print('${name}Warmup: ${warmupUs} us');
      print('${name}: ${avg} us.');
      final prefix = '-' * name.length;
      print('${prefix}> Range: ${min}...${max} us.');
      print('${prefix}> Std Dev: ${std.toStringAsFixed(2)}');
      print('${prefix}> 50th percentile: ${P(50)} us.');
      print('${prefix}> 90th percentile: ${P(90)} us.');
    } else {
      print('${name}(RunTimeRaw): ${avg} us.');
      print('${name}P50(RunTimeRaw): ${P(50)} us.');
      print('${name}P90(RunTimeRaw): ${P(90)} us.');
    }
  }
}

bool _parseArgs(List<String> args) {
  if (args.length != 2 && args.length != 3) {
    return false;
  }

  if (args[0] == '--golem') {
    if (args.length != 3) {
      return false;
    }
    forGolem = true;
    args = args.skip(1).toList(growable: false);
  }

  switch (args[0]) {
    case 'ast-to-binary':
      mode = Mode.astToBinary;
      break;
    case 'ast-from-binary-lazy':
      mode = Mode.astFromBinaryLazy;
      break;
    case 'ast-from-binary-eager':
      mode = Mode.astFromBinaryEager;
      break;
    default:
      return false;
  }

  sourceDill = new File(args[1]);
  if (!sourceDill.existsSync()) {
    return false;
  }

  return true;
}

Program _fromBinary(List<int> bytes, {eager: true}) {
  var program = new Program();
  new BinaryBuilder(bytes, 'filename', eager).readSingleFileProgram(program);
  return program;
}

class SimpleSink implements Sink<List<int>> {
  final List<List<int>> chunks = <List<int>>[];

  @override
  void add(List<int> chunk) {
    chunks.add(chunk);
  }

  @override
  void close() {}
}

void _toBinary(Program p) {
  new BinaryPrinter(new SimpleSink()).writeProgramFile(p);
}
