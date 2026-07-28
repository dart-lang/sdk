// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Micro-benchmark for the [IOSink] returned by [File.openWrite].

import 'dart:io';
import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';

const numBytesToWrite = 200000; // Write 200KiB in all benchmarks runs.

/// Benchmark building a [numBytesToWrite] byte file a single byte at a time.
///
/// Based on https://github.com/dart-lang/sdk/issues/32874#issue-314022259
class BenchmarkManySmallAdds extends AsyncBenchmarkBase {
  late Directory _tempDir;
  late IOSink _ioSink;
  final _singleByte = Uint8List(1);

  BenchmarkManySmallAdds() : super('FileIOSink.Add.ManySmall');

  @override
  Future<void> setup() async {
    _tempDir = Directory.systemTemp.createTempSync();
    _ioSink = File(_tempDir.uri.resolve('many-small').toFilePath()).openWrite();
  }

  @override
  Future<void> teardown() async {
    await _ioSink.close();
    _tempDir.deleteSync(recursive: true);
  }

  @override
  Future<void> run() async {
    for (var i = 0; i < numBytesToWrite; ++i) {
      _ioSink.add(_singleByte);
    }
    await _ioSink.flush();
  }
}

/// Benchmark building a [numBytesToWrite] byte file with a single call to
/// [IOSink.add].
class BenchmarkOneLargeAdd extends AsyncBenchmarkBase {
  late final Directory _tempDir;
  late final IOSink _ioSink;
  final _largeData = Uint8List(numBytesToWrite);

  BenchmarkOneLargeAdd() : super('FileIOSink.Add.OneLarge');

  @override
  Future<void> setup() async {
    _tempDir = Directory.systemTemp.createTempSync();
    _ioSink = File(_tempDir.uri.resolve('one-large').toFilePath()).openWrite();
  }

  @override
  Future<void> teardown() async {
    await _ioSink.close();
    _tempDir.deleteSync(recursive: true);
  }

  @override
  Future<void> run() async {
    _ioSink.add(_largeData);
    await _ioSink.flush();
  }
}

/// Benchmark building a file by alternating calls to [IOSink.add] with large
/// and small amounts of data.
class BenchmarkAlternatingSizedAdd extends AsyncBenchmarkBase {
  late final Directory _tempDir;
  late final IOSink _ioSink;
  final _largeData = Uint8List(numBytesToWrite - 1);
  final _smallData = Uint8List(1);

  BenchmarkAlternatingSizedAdd() : super('FileIOSink.Add.AlternatingAddSize');

  @override
  Future<void> setup() async {
    _tempDir = Directory.systemTemp.createTempSync();
    _ioSink = File(_tempDir.uri.resolve('alternative-add-size').toFilePath())
        .openWrite();
  }

  @override
  Future<void> teardown() async {
    await _ioSink.close();
    _tempDir.deleteSync(recursive: true);
  }

  @override
  Future<void> run() async {
    _ioSink.add(_largeData);
    _ioSink.add(_smallData);
    await _ioSink.flush();
  }
}

void main() async {
  final benchmarks = [
    BenchmarkManySmallAdds(),
    BenchmarkOneLargeAdd(),
    BenchmarkAlternatingSizedAdd(),
  ];

  for (final benchmark in benchmarks) {
    await benchmark.report();
  }
}
