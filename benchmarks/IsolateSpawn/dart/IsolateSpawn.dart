// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';
import 'dart:isolate';
import 'dart:math';

import 'package:meta/meta.dart';

import 'package:compiler/src/dart2js.dart' as dart2js_main;
import 'package:vm_service/vm_service.dart' as vm_service;
import 'package:vm_service/vm_service_io.dart' as vm_service_io;

class SpawnLatencyAndMemory {
  SpawnLatencyAndMemory(this.name, this.wsUri, this.groupRefId);

  Future<ResultMessageLatencyAndMemory> run() async {
    final completerResult = Completer();
    final receivePort = ReceivePort()..listen(completerResult.complete);
    final Completer<DateTime> isolateExitedCompleter = Completer<DateTime>();
    final onExitReceivePort = ReceivePort()
      ..listen((_) {
        isolateExitedCompleter.complete(DateTime.now());
      });
    final DateTime beforeSpawn = DateTime.now();
    await Isolate.spawn(
        isolateCompiler,
        StartMessageLatencyAndMemory(receivePort.sendPort, beforeSpawn,
            await currentHeapUsage(wsUri, groupRefId), wsUri, groupRefId),
        onExit: onExitReceivePort.sendPort,
        onError: onExitReceivePort.sendPort);
    final DateTime afterSpawn = DateTime.now();

    final ResultMessageLatencyAndMemory result = await completerResult.future;
    receivePort.close();
    final DateTime isolateExited = await isolateExitedCompleter.future;
    result.timeToExitUs = isolateExited.difference(beforeSpawn).inMicroseconds;
    result.timeToIsolateSpawnUs =
        afterSpawn.difference(beforeSpawn).inMicroseconds;
    onExitReceivePort.close();

    return result;
  }

  Future<AggregatedResultMessageLatencyAndMemory> measureFor(
      int minimumMillis) async {
    final minimumMicros = minimumMillis * 1000;
    final watch = Stopwatch()..start();
    final Metric toAfterIsolateSpawnUs = LatencyMetric("${name}ToAfterSpawn");
    final Metric toStartRunningCodeUs = LatencyMetric("${name}ToStartRunning");
    final Metric toFinishRunningCodeUs =
        LatencyMetric("${name}ToFinishRunning");
    final Metric toExitUs = LatencyMetric("${name}ToExit");
    final Metric deltaHeap = MemoryMetric("${name}Delta");
    while (watch.elapsedMicroseconds < minimumMicros) {
      final ResultMessageLatencyAndMemory result = await run();
      toAfterIsolateSpawnUs.add(result.timeToIsolateSpawnUs);
      toStartRunningCodeUs.add(result.timeToStartRunningCodeUs);
      toFinishRunningCodeUs.add(result.timeToFinishRunningCodeUs);
      toExitUs.add(result.timeToExitUs);
      deltaHeap.add(result.deltaHeap);
    }
    return AggregatedResultMessageLatencyAndMemory(toAfterIsolateSpawnUs,
        toStartRunningCodeUs, toFinishRunningCodeUs, toExitUs, deltaHeap);
  }

  Future<AggregatedResultMessageLatencyAndMemory> measure() async {
    await measureFor(500); // warm-up
    return measureFor(4000); // actual measurement
  }

  Future<void> report() async {
    final AggregatedResultMessageLatencyAndMemory result = await measure();
    print(result);
  }

  final String name;
  final String wsUri;
  final String groupRefId;
  RawReceivePort receivePort;
}

class Metric {
  Metric({@required this.prefix, @required this.suffix});

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

  toString() => "$prefix): ${_average()}$suffix\n"
      "${prefix}Max): $max$suffix\n"
      "${prefix}RMS): ${_rms()}$suffix";

  final String prefix;
  final String suffix;
  int max = 0;
  double sum = 0;
  double sumOfSquares = 0;
  int count = 0;
}

class LatencyMetric extends Metric {
  LatencyMetric(String name) : super(prefix: "$name(Latency", suffix: " us.");
}

class MemoryMetric extends Metric {
  MemoryMetric(String name)
      : super(prefix: "${name}Heap(MemoryUse", suffix: "");

  toString() => "$prefix): ${_average()}$suffix\n";
}

class StartMessageLatencyAndMemory {
  StartMessageLatencyAndMemory(
      this.sendPort, this.spawned, this.rss, this.wsUri, this.groupRefId);

  final SendPort sendPort;
  final DateTime spawned;
  final int rss;

  final String wsUri;
  final String groupRefId;
}

class ResultMessageLatencyAndMemory {
  ResultMessageLatencyAndMemory(
      {this.timeToStartRunningCodeUs,
      this.timeToFinishRunningCodeUs,
      this.deltaHeap});

  final int timeToStartRunningCodeUs;
  final int timeToFinishRunningCodeUs;
  final int deltaHeap;

  int timeToIsolateSpawnUs;
  int timeToExitUs;
}

class AggregatedResultMessageLatencyAndMemory {
  AggregatedResultMessageLatencyAndMemory(
    this.toAfterIsolateSpawnUs,
    this.toStartRunningCodeUs,
    this.toFinishRunningCodeUs,
    this.toExitUs,
    this.deltaHeap,
  );

  String toString() => """$toAfterIsolateSpawnUs
$toStartRunningCodeUs
$toFinishRunningCodeUs
$toExitUs
$deltaHeap""";

  final Metric toAfterIsolateSpawnUs;
  final Metric toStartRunningCodeUs;
  final Metric toFinishRunningCodeUs;
  final Metric toExitUs;
  final Metric deltaHeap;
}

Future<void> isolateCompiler(StartMessageLatencyAndMemory start) async {
  final DateTime timeRunningCodeUs = DateTime.now();
  await runZoned(
      () => dart2js_main.internalMain(<String>[
            "benchmarks/IsolateSpawn/dart/helloworld.dart",
            '--libraries-spec=sdk/lib/libraries.json'
          ]),
      zoneSpecification: ZoneSpecification(
          print: (Zone self, ZoneDelegate parent, Zone zone, String line) {}));
  final DateTime timeFinishRunningCodeUs = DateTime.now();
  start.sendPort.send(ResultMessageLatencyAndMemory(
      timeToStartRunningCodeUs:
          timeRunningCodeUs.difference(start.spawned).inMicroseconds,
      timeToFinishRunningCodeUs:
          timeFinishRunningCodeUs.difference(start.spawned).inMicroseconds,
      deltaHeap:
          await currentHeapUsage(start.wsUri, start.groupRefId) - start.rss));
}

Future<int> currentHeapUsage(String wsUri, String groupRefId) async {
  final vm_service.VmService vmService =
      await vm_service_io.vmServiceConnectUri(wsUri);
  final vm_service.MemoryUsage usage =
      await vmService.getIsolateGroupMemoryUsage(groupRefId);
  vmService.dispose();
  return usage.heapUsage + usage.externalUsage;
}

Future<void> main() async {
  final ServiceProtocolInfo info = await Service.controlWebServer(enable: true);
  final Uri observatoryUri = info.serverUri;
  final String wsUri =
      'ws://${observatoryUri.authority}${observatoryUri.path}ws';
  final vm_service.VmService vmService =
      await vm_service_io.vmServiceConnectUri(wsUri);
  final String mainGroupRefId = await getMainGroupRefId(vmService);
  vmService.dispose();

  await SpawnLatencyAndMemory("IsolateSpawn.Dart2JS", wsUri, mainGroupRefId)
      .report();
}

Future<String> getMainGroupRefId(vm_service.VmService vmService) async {
  final vm = await vmService.getVM();
  for (vm_service.IsolateGroupRef groupRef in vm.isolateGroups) {
    final vm_service.IsolateGroup group =
        await vmService.getIsolateGroup(groupRef.id);
    for (vm_service.IsolateRef isolateRef in group.isolates) {
      final isolateOrSentinel = await vmService.getIsolate(isolateRef.id);
      if (isolateOrSentinel is vm_service.Isolate) {
        final vm_service.Isolate isolate = isolateOrSentinel;
        if (isolate.name == 'main') {
          return groupRef.id;
        }
      }
    }
  }
  throw "Could not find main isolate";
}
