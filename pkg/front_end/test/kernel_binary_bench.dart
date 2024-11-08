// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This files contains methods for benchmarking Kernel binary serialization
// and deserialization routines.

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:kernel/ast.dart';
import 'package:kernel/binary/ast_from_binary.dart';
import 'package:kernel/binary/ast_to_binary.dart';
import 'package:kernel/src/printer.dart';

import '../tool/_fasta/compile.dart' as compile;

final String usage = '''
Usage: kernel_binary_bench.dart [--golem|--raw] {--metadata|--onlyCold} <Benchmark> <SourceDill>

Benchmark can be one of: ${benchmarks.keys.join(', ')}
''';

typedef void Benchmark(Uint8List bytes);

final Map<String, Benchmark> benchmarks = {
  'AstFromBinaryEager': (Uint8List bytes) {
    return _benchmarkAstFromBinary(bytes, eager: true);
  },
  'AstFromBinaryLazy': (Uint8List bytes) {
    return _benchmarkAstFromBinary(bytes, eager: false);
  },
  'AstToBinary': (Uint8List bytes) {
    return _benchmarkAstToBinary(bytes);
  },
};

Benchmark? benchmark;
late File sourceDill;
bool forGolem = false;
bool forRaw = false;
bool metadataAware = false;
bool onlyCold = false;

void main(List<String> args) async {
  if (args.length == 1 && args[0] == "--compile") {
    // Allow - although in practise unused - to go to a bigger target (in this
    // case the compile target) - in order to get a more real polymorphic
    // potential (especially for AOT compiles).
    return await compile.main(args);
  }
  if (!_parseArgs(args)) {
    print(usage);
    exit(-1);
  }

  final Uint8List bytes = sourceDill.readAsBytesSync();
  benchmark!(bytes);
}

int warmupIterations = 100;
int benchmarkIterations = 50;

void _benchmarkAstFromBinary(Uint8List bytes, {bool eager = true}) {
  final String nameSuffix = eager ? 'Eager' : 'Lazy';

  final Stopwatch sw = new Stopwatch()..start();
  _fromBinary(bytes, eager: eager);
  final int coldRunUs = sw.elapsedMicroseconds;
  sw.reset();
  if (onlyCold) {
    new BenchmarkResult('AstFromBinary${nameSuffix}', coldRunUs,
        coldRunUs.toDouble(), [coldRunUs]).report();
    return;
  }

  for (int i = 0; i < warmupIterations; i++) {
    _fromBinary(bytes, eager: eager);
  }
  final double warmupUs = sw.elapsedMicroseconds / warmupIterations;

  final List<int> runsUs =
      new List<int>.filled(benchmarkIterations, /* dummy value = */ 0);
  for (int i = 0; i < benchmarkIterations; i++) {
    sw.reset();
    _fromBinary(bytes, eager: eager, verbose: i == benchmarkIterations - 1);
    runsUs[i] = sw.elapsedMicroseconds;
  }

  new BenchmarkResult('AstFromBinary${nameSuffix}', coldRunUs, warmupUs, runsUs)
      .report();
}

void _benchmarkAstToBinary(Uint8List bytes) {
  final Component p = _fromBinary(bytes, eager: true);
  final Stopwatch sw = new Stopwatch()..start();
  _toBinary(p);
  final int coldRunUs = sw.elapsedMicroseconds;
  sw.reset();

  for (int i = 0; i < warmupIterations; i++) {
    _toBinary(p);
  }
  final double warmupUs = sw.elapsedMicroseconds / warmupIterations;

  final List<int> runsUs =
      new List<int>.filled(benchmarkIterations, /* dummy value = */ 0);
  for (int i = 0; i < benchmarkIterations; i++) {
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

  static T add<T extends num>(T x, T y) => x + y as T;

  void report() {
    runsUs.sort();

    int P(int p) => runsUs[((runsUs.length - 1) * (p / 100)).ceil()];

    final int sum = runsUs.reduce(add);
    final double avg = sum / runsUs.length;
    final int min = runsUs.first;
    final int max = runsUs.last;
    final double std =
        sqrt(runsUs.map((v) => pow(v - avg, 2)).reduce(add) / runsUs.length);

    if (forGolem) {
      print('${name}(RunTimeRaw): ${avg} us.');
      print('${name}P50(RunTimeRaw): ${P(50)} us.');
      print('${name}P90(RunTimeRaw): ${P(90)} us.');
    } else if (forRaw) {
      runsUs.forEach(print);
    } else {
      print('${name}Cold: ${coldRunUs} us');
      print('${name}Warmup: ${warmupUs} us');
      print('${name}: ${avg} us.');
      final String prefix = '-' * name.length;
      print('${prefix}> Range: ${min}...${max} us.');
      print('${prefix}> Std Dev: ${std.toStringAsFixed(2)}');
      print('${prefix}> 50th percentile: ${P(50)} us.');
      print('${prefix}> 90th percentile: ${P(90)} us.');
    }
  }
}

bool _parseArgs(List<String> argsOrg) {
  List<String> trimmedArgs = [];
  for (String arg in argsOrg) {
    if (arg == "--golem") {
      forGolem = true;
    } else if (arg == "--raw") {
      forRaw = true;
    } else if (arg == "--metadata") {
      metadataAware = true;
    } else if (arg == "--onlyCold") {
      onlyCold = true;
    } else if (arg.startsWith("--warmups=")) {
      warmupIterations = int.parse(arg.substring("--warmups=".length));
    } else if (arg.startsWith("--iterations=")) {
      benchmarkIterations = int.parse(arg.substring("--iterations=".length));
    } else {
      trimmedArgs.add(arg);
    }
  }

  if (trimmedArgs.length != 2) {
    return false;
  }
  if (forGolem && forRaw) {
    return false;
  }

  benchmark = benchmarks[trimmedArgs[0]];
  if (benchmark == null) {
    return false;
  }

  sourceDill = new File(trimmedArgs[1]);
  if (!sourceDill.existsSync()) {
    return false;
  }

  return true;
}

Component _fromBinary(Uint8List bytes,
    {required bool eager, bool verbose = false}) {
  Component component = new Component();
  if (metadataAware) {
    // This is currently (October 2024) what VmTarget.configureComponent does.
    component.metadata.putIfAbsent(
        CallSiteAttributesMetadataRepository.repositoryTag,
        () => new CallSiteAttributesMetadataRepository());
    BinaryBuilderWithMetadata builder = new BinaryBuilderWithMetadata(bytes,
        filename: 'filename', disableLazyReading: eager);
    builder.readComponent(component);
    if (verbose) {
      // No current verbose output.
    }
  } else {
    new BinaryBuilder(bytes, filename: 'filename', disableLazyReading: eager)
        .readComponent(component);
  }
  return component;
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

void _toBinary(Component p) {
  new BinaryPrinter(new SimpleSink()).writeComponentFile(p);
}

// The below is copied from package:vm so to test metadata properly without
// depending on package:vm.

/// Metadata for annotating call sites with various attributes.
class CallSiteAttributesMetadata {
  final DartType receiverType;

  const CallSiteAttributesMetadata({required this.receiverType});

  @override
  String toString() =>
      "receiverType:${receiverType.toText(astTextStrategyForTesting)}";
}

/// Repository for [CallSiteAttributesMetadata].
class CallSiteAttributesMetadataRepository
    extends MetadataRepository<CallSiteAttributesMetadata> {
  static final repositoryTag = 'vm.call-site-attributes.metadata';

  @override
  final String tag = repositoryTag;

  @override
  final Map<TreeNode, CallSiteAttributesMetadata> mapping =
      <TreeNode, CallSiteAttributesMetadata>{};

  @override
  void writeToBinary(
      CallSiteAttributesMetadata metadata, Node node, BinarySink sink) {
    sink.writeDartType(metadata.receiverType);
  }

  @override
  CallSiteAttributesMetadata readFromBinary(Node node, BinarySource source) {
    final type = source.readDartType();
    return new CallSiteAttributesMetadata(receiverType: type);
  }
}
