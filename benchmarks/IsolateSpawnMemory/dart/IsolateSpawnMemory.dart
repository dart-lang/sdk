// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:compiler/src/dart2js.dart' as dart2js_main;
import 'package:vm_service/vm_service.dart' as vm_service;
import 'package:vm_service/vm_service_io.dart' as vm_service_io;

const String compilerIsolateName = 'isolate-compiler';

class Result {
  const Result(
      this.rssOnStart, this.rssOnEnd, this.heapOnStart, this.heapOnEnd);

  final int rssOnStart;
  final int rssOnEnd;
  final int heapOnStart;
  final int heapOnEnd;
}

class StartMessage {
  const StartMessage(this.wsUri, this.sendPort);

  final String wsUri;
  final SendPort sendPort;
}

class SpawnMemory {
  SpawnMemory(this.name, this.wsUri);

  Future<void> report() async {
    int maxProcessRss = 0;
    final timer = Timer.periodic(const Duration(microseconds: 100), (_) {
      maxProcessRss = math.max(maxProcessRss, ProcessInfo.currentRss);
    });

    const numberOfBenchmarks = 3;

    final beforeRss = ProcessInfo.currentRss;
    final beforeHeap = await currentHeapUsage(wsUri);

    final iterators = <StreamIterator>[];
    final continuations = <SendPort>[];

    // Start all isolates & make them wait.
    for (int i = 0; i < numberOfBenchmarks; i++) {
      final receivePort = ReceivePort();
      final startMessage = StartMessage(wsUri, receivePort.sendPort);
      await Isolate.spawn(isolateCompiler, startMessage,
          debugName: compilerIsolateName);
      final iterator = StreamIterator(receivePort);

      if (!await iterator.moveNext()) throw 'failed';
      continuations.add(iterator.current as SendPort);

      iterators.add(iterator);
    }

    final readyRss = ProcessInfo.currentRss;
    final readyHeap = await currentHeapUsage(wsUri);

    // Let all isolates do the dart2js compilation.
    for (int i = 0; i < numberOfBenchmarks; i++) {
      final iterator = iterators[i];
      final continuation = continuations[i];
      continuation.send(null);
      if (!await iterator.moveNext()) throw 'failed';
      if (iterator.current != 'done') throw 'failed';
    }

    final doneRss = ProcessInfo.currentRss;
    final doneHeap = await currentHeapUsage(wsUri);

    // Shut down helper isolates
    for (int i = 0; i < numberOfBenchmarks; i++) {
      final iterator = iterators[i];
      final continuation = continuations[i];
      continuation.send(null);
      if (!await iterator.moveNext()) throw 'failed';
      if (iterator.current != 'shutdown') throw 'failed';
      await iterator.cancel();
    }
    timer.cancel();

    final readyDiffRss =
        math.max(0, readyRss - beforeRss) ~/ numberOfBenchmarks;
    final readyDiffHeap =
        math.max(0, readyHeap - beforeHeap) ~/ numberOfBenchmarks;
    final doneDiffRss = math.max(0, doneRss - beforeRss) ~/ numberOfBenchmarks;
    final doneDiffHeap =
        math.max(0, doneHeap - beforeHeap) ~/ numberOfBenchmarks;

    print('${name}RssOnStart(MemoryUse): $readyDiffRss');
    print('${name}RssOnEnd(MemoryUse): $doneDiffRss');
    print('${name}HeapOnStart(MemoryUse): $readyDiffHeap');
    print('${name}HeapOnEnd(MemoryUse): $doneDiffHeap');
    print('${name}PeakProcessRss(MemoryUse): $maxProcessRss');
  }

  final String name;
  final String wsUri;
}

Future<void> isolateCompiler(StartMessage startMessage) async {
  final port = ReceivePort();
  final iterator = StreamIterator(port);

  // Let main isolate know we're ready.
  startMessage.sendPort.send(port.sendPort);
  await iterator.moveNext();

  await runZoned(
      () => dart2js_main.internalMain(<String>[
            'benchmarks/IsolateSpawnMemory/dart/helloworld.dart',
            '--libraries-spec=sdk/lib/libraries.json'
          ]),
      zoneSpecification: ZoneSpecification(
          print: (Zone self, ZoneDelegate parent, Zone zone, String line) {}));

  // Let main isolate know we're done.
  startMessage.sendPort.send('done');
  await iterator.moveNext();

  // Closes the port.
  startMessage.sendPort.send('shutdown');
  await iterator.cancel();
}

Future<int> currentHeapUsage(String wsUri) async {
  final vmService = await vm_service_io.vmServiceConnectUri(wsUri);
  final groupIds = await getGroupIds(vmService);
  int sum = 0;
  for (final groupId in groupIds) {
    final usage = await vmService.getIsolateGroupMemoryUsage(groupId);
    sum += usage.heapUsage + usage.externalUsage;
  }
  vmService.dispose();
  return sum;
}

Future<void> main() async {
  // Only if we successfully reach the end will we set 0 exit code.
  exitCode = 255;

  final info = await Service.controlWebServer(enable: true);
  final observatoryUri = info.serverUri!;
  final wsUri = 'ws://${observatoryUri.authority}${observatoryUri.path}ws';
  await SpawnMemory('IsolateSpawnMemory.Dart2JSDelta', wsUri).report();

  // Only if we successfully reach the end will we set 0 exit code.
  exitCode = 0;
}

// Returns the set of isolate groups for which we should count the heap usage.
//
// We have two cases
//
//   a) --enable-isolate-groups: All isolates will be within the same isolate
//   group.
//
//   b) --no-enable-isolate-groups: All isolates will be within their own,
//   separate isolate group.
//
// In both cases we want to sum up the heap sizes of all isolate groups.
Future<List<String>> getGroupIds(vm_service.VmService vmService) async {
  final groupIds = <String>{};
  final vm = await vmService.getVM();
  for (final groupRef in vm.isolateGroups) {
    final group = await vmService.getIsolateGroup(groupRef.id);
    for (final isolateRef in group.isolates) {
      final isolateOrSentinel = await vmService.getIsolate(isolateRef.id);
      if (isolateOrSentinel is vm_service.Isolate) {
        groupIds.add(groupRef.id);
      }
    }
  }
  if (groupIds.isEmpty) {
    throw 'Could not find main isolate';
  }
  return groupIds.toList();
}
