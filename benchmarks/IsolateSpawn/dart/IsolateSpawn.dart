// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:isolate';
import 'dart:math';

import 'package:compiler/src/dart2js.dart' as dart2js_main;

class SpawnLatency {
  SpawnLatency(this.name);

  Future<ResultMessageLatency> run() async {
    final completerResult = Completer();
    final receivePort = ReceivePort()..listen(completerResult.complete);
    final isolateExitedCompleter = Completer<DateTime>();
    final onExitReceivePort = ReceivePort()
      ..listen((_) {
        isolateExitedCompleter.complete(DateTime.now());
      });
    final beforeSpawn = DateTime.now();
    await Isolate.spawn(
        isolateCompiler, StartMessageLatency(receivePort.sendPort, beforeSpawn),
        onExit: onExitReceivePort.sendPort,
        onError: onExitReceivePort.sendPort);
    final afterSpawn = DateTime.now();

    final ResultMessageLatency result = await completerResult.future;
    receivePort.close();
    final DateTime isolateExited = await isolateExitedCompleter.future;
    result.timeToExitUs = isolateExited.difference(beforeSpawn).inMicroseconds;
    result.timeToIsolateSpawnUs =
        afterSpawn.difference(beforeSpawn).inMicroseconds;
    onExitReceivePort.close();

    return result;
  }

  Future<AggregatedResultMessageLatency> measureFor(int minimumMillis) async {
    final minimumMicros = minimumMillis * 1000;
    final watch = Stopwatch()..start();
    final Metric toAfterIsolateSpawnUs = LatencyMetric('${name}ToAfterSpawn');
    final Metric toStartRunningCodeUs = LatencyMetric('${name}ToStartRunning');
    final Metric toFinishRunningCodeUs =
        LatencyMetric('${name}ToFinishRunning');
    final Metric toExitUs = LatencyMetric('${name}ToExit');
    while (watch.elapsedMicroseconds < minimumMicros) {
      final result = await run();
      toAfterIsolateSpawnUs.add(result.timeToIsolateSpawnUs);
      toStartRunningCodeUs.add(result.timeToStartRunningCodeUs);
      toFinishRunningCodeUs.add(result.timeToFinishRunningCodeUs);
      toExitUs.add(result.timeToExitUs);
    }
    return AggregatedResultMessageLatency(toAfterIsolateSpawnUs,
        toStartRunningCodeUs, toFinishRunningCodeUs, toExitUs);
  }

  Future<AggregatedResultMessageLatency> measure() async {
    await measureFor(500); // warm-up
    return measureFor(4000); // actual measurement
  }

  Future<void> report() async {
    final result = await measure();
    print(result);
  }

  final String name;
  late RawReceivePort receivePort;
}

class Metric {
  Metric({required this.prefix, required this.suffix});

  void add(int value) {
    if (value > max) {
      max = value;
    }
    sum += value;
    sumOfSquares += value * value;
    count++;
  }

  double _average() => sum / count;
  double _rms() => sqrt(sumOfSquares / count);

  @override
  String toString() => '$prefix): ${_average()}$suffix\n'
      '${prefix}Max): $max$suffix\n'
      '${prefix}RMS): ${_rms()}$suffix';

  final String prefix;
  final String suffix;
  int max = 0;
  double sum = 0;
  double sumOfSquares = 0;
  int count = 0;
}

class LatencyMetric extends Metric {
  LatencyMetric(String name) : super(prefix: '$name(Latency', suffix: ' us.');
}

class StartMessageLatency {
  StartMessageLatency(this.sendPort, this.spawned);

  final SendPort sendPort;
  final DateTime spawned;
}

class ResultMessageLatency {
  ResultMessageLatency(
      {required this.timeToStartRunningCodeUs,
      required this.timeToFinishRunningCodeUs});

  final int timeToStartRunningCodeUs;
  final int timeToFinishRunningCodeUs;

  late int timeToIsolateSpawnUs;
  late int timeToExitUs;
}

class AggregatedResultMessageLatency {
  AggregatedResultMessageLatency(
    this.toAfterIsolateSpawnUs,
    this.toStartRunningCodeUs,
    this.toFinishRunningCodeUs,
    this.toExitUs,
  );

  @override
  String toString() => '''$toAfterIsolateSpawnUs
$toStartRunningCodeUs
$toFinishRunningCodeUs
$toExitUs''';

  final Metric toAfterIsolateSpawnUs;
  final Metric toStartRunningCodeUs;
  final Metric toFinishRunningCodeUs;
  final Metric toExitUs;
}

Future<void> isolateCompiler(StartMessageLatency start) async {
  final timeRunningCodeUs = DateTime.now();
  await runZoned(
      () => dart2js_main.internalMain(<String>[
            'benchmarks/IsolateSpawn/dart/helloworld.dart',
            '--libraries-spec=sdk/lib/libraries.json'
          ]),
      zoneSpecification: ZoneSpecification(
          print: (Zone self, ZoneDelegate parent, Zone zone, String line) {}));
  final timeFinishRunningCodeUs = DateTime.now();
  start.sendPort.send(ResultMessageLatency(
      timeToStartRunningCodeUs:
          timeRunningCodeUs.difference(start.spawned).inMicroseconds,
      timeToFinishRunningCodeUs:
          timeFinishRunningCodeUs.difference(start.spawned).inMicroseconds));
}

Future<void> main() async {
  await SpawnLatency('IsolateSpawn.Dart2JS').report();
}
