// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart' show BenchmarkBase;
import 'package:meta/meta.dart';

class JsonDecodingBenchmark {
  JsonDecodingBenchmark(this.name,
      {@required this.sample, @required this.numTasks});

  Future<void> report() async {
    final stopwatch = Stopwatch()..start();
    final decodedFutures = <Future>[];
    for (int i = 0; i < numTasks; i++) {
      decodedFutures.add(decodeJson(sample));
    }
    await Future.wait(decodedFutures);

    print("$name(RunTime): ${stopwatch.elapsedMicroseconds} us.");
  }

  final String name;
  final Uint8List sample;
  final int numTasks;
}

Uint8List createSampleJson(final size) {
  final list = List.generate(size, (i) => i);
  final map = <dynamic, dynamic>{};
  for (int i = 0; i < size; i++) {
    map['$i'] = list;
  }
  return utf8.encode(json.encode(map));
}

class JsonDecodeRequest {
  final SendPort sendPort;
  final Uint8List encodedJson;
  const JsonDecodeRequest(this.sendPort, this.encodedJson);
}

Future<Map> decodeJson(Uint8List encodedJson) async {
  final port = ReceivePort();
  final inbox = StreamIterator<dynamic>(port);
  final workerExitedPort = ReceivePort();
  await Isolate.spawn(
      jsonDecodingIsolate, JsonDecodeRequest(port.sendPort, encodedJson),
      onExit: workerExitedPort.sendPort);
  await inbox.moveNext();
  final decodedJson = inbox.current;
  await workerExitedPort.first;
  port.close();
  return decodedJson;
}

Future<void> jsonDecodingIsolate(JsonDecodeRequest request) async {
  request.sendPort.send(json.decode(utf8.decode(request.encodedJson)));
}

class SyncJsonDecodingBenchmark extends BenchmarkBase {
  SyncJsonDecodingBenchmark(String name,
      {@required this.sample, @required this.iterations})
      : super(name);

  @override
  void run() {
    int l = 0;
    for (int i = 0; i < iterations; i++) {
      final Map map = json.decode(utf8.decode(sample));
      l += map.length;
    }
    assert(l > 0);
  }

  final Uint8List sample;
  final int iterations;
}

class BenchmarkConfig {
  BenchmarkConfig(this.suffix, this.sample);

  final String suffix;
  final Uint8List sample;
}

Future<void> main() async {
  final jsonString =
      File('benchmarks/IsolateJson/dart/sample.json').readAsStringSync();
  final json250KB = utf8.encode(jsonString); // 294356 bytes
  final decoded = json.decode(utf8.decode(json250KB));
  final decoded1MB = <dynamic, dynamic>{
    "1": decoded["1"],
    "2": decoded["1"],
    "3": decoded["1"],
    "4": decoded["1"],
  };
  final json1MB = utf8.encode(json.encode(decoded1MB)); // 1177397 bytes
  decoded["1"] = (decoded["1"] as List).sublist(0, 200);
  final json100KB = utf8.encode(json.encode(decoded)); // 104685 bytes
  decoded["1"] = (decoded["1"] as List).sublist(0, 100);
  final json50KB = utf8.encode(json.encode(decoded)); // 51760 bytes

  final configs = <BenchmarkConfig>[
    BenchmarkConfig("50KB", json50KB),
    BenchmarkConfig("100KB", json100KB),
    BenchmarkConfig("250KB", json250KB),
    BenchmarkConfig("1MB", json1MB),
  ];

  for (BenchmarkConfig config in configs) {
    for (final iterations in <int>[1, 4]) {
      await JsonDecodingBenchmark(
              "IsolateJson.Decode${config.suffix}x$iterations",
              sample: config.sample,
              numTasks: iterations)
          .report();
      SyncJsonDecodingBenchmark(
              "IsolateJson.SyncDecode${config.suffix}x$iterations",
              sample: config.sample,
              iterations: iterations)
          .report();
    }
  }
}
