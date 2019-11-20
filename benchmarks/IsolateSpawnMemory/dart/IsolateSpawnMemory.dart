// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';

import 'package:compiler/src/dart2js.dart' as dart2js_main;
import 'package:vm_service/vm_service.dart' as vm_service;
import 'package:vm_service/vm_service_io.dart' as vm_service_io;

class Result {
  const Result(
      this.rssOnStart, this.rssOnEnd, this.heapOnStart, this.heapOnEnd);

  final int rssOnStart;
  final int rssOnEnd;
  final int heapOnStart;
  final int heapOnEnd;
}

class StartMessage {
  const StartMessage(this.wsUri, this.groupRefId, this.sendPort);

  final String wsUri;
  final String groupRefId;
  final SendPort sendPort;
}

class SpawnMemory {
  SpawnMemory(this.name, this.wsUri, this.groupRefId);

  Future<void> report() async {
    const numberOfRuns = 3;

    int sumDeltaRssOnStart = 0;
    int sumDeltaRssOnEnd = 0;
    int sumDeltaHeapOnStart = 0;
    int sumDeltaHeapOnEnd = 0;
    for (int i = 0; i < numberOfRuns; i++) {
      final receivePort = ReceivePort();
      final beforeRss = ProcessInfo.currentRss;
      final beforeHeap = await currentHeapUsage(wsUri, groupRefId);

      final startMessage =
          StartMessage(wsUri, groupRefId, receivePort.sendPort);
      await Isolate.spawn(isolateCompiler, startMessage);

      final Result result = await receivePort.first;
      sumDeltaRssOnStart += result.rssOnStart - beforeRss;
      sumDeltaRssOnEnd += result.rssOnEnd - beforeRss;
      sumDeltaHeapOnStart += result.heapOnStart - beforeHeap;
      sumDeltaHeapOnEnd += result.heapOnEnd - beforeHeap;
    }
    print(
        "${name}RssOnStart(MemoryUse): ${sumDeltaRssOnStart ~/ numberOfRuns}");
    print("${name}RssOnEnd(MemoryUse): ${sumDeltaRssOnEnd ~/ numberOfRuns}");
    print(
        "${name}HeapOnStart(MemoryUse): ${sumDeltaHeapOnStart ~/ numberOfRuns}");
    print("${name}HeapOnEnd(MemoryUse): ${sumDeltaHeapOnEnd ~/ numberOfRuns}");
  }

  final String name;
  final String wsUri;
  final String groupRefId;
  RawReceivePort receivePort;
}

Future<void> isolateCompiler(StartMessage startMessage) async {
  final rssOnStart = ProcessInfo.currentRss;
  final heapOnStart =
      await currentHeapUsage(startMessage.wsUri, startMessage.groupRefId);
  await runZoned(
      () => dart2js_main.internalMain(<String>[
            "benchmarks/IsolateSpawnMemory/dart/helloworld.dart",
            '--libraries-spec=sdk/lib/libraries.json'
          ]),
      zoneSpecification: ZoneSpecification(
          print: (Zone self, ZoneDelegate parent, Zone zone, String line) {}));
  startMessage.sendPort.send(Result(
      rssOnStart,
      ProcessInfo.currentRss,
      heapOnStart,
      await currentHeapUsage(startMessage.wsUri, startMessage.groupRefId)));
  ReceivePort(); // prevent isolate from exiting to ensure Rss monotonically grows
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

  await SpawnMemory("IsolateSpawnMemory.Dart2JSDelta", wsUri, mainGroupRefId)
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
