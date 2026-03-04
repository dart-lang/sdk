// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:analysis_server/protocol/protocol_constants.dart'
    show PROTOCOL_VERSION;
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/legacy_analysis_server.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart'
    show LspAnalysisServer;
import 'package:analysis_server/src/scheduler/message_scheduler.dart';
import 'package:analysis_server/src/scheduler/scheduler_tracking_listener.dart';
import 'package:analysis_server/src/status/diagnostics.dart';
import 'package:analysis_server/src/status/utilities/library_cycle_extensions.dart';
import 'package:analysis_server/src/utilities/profiling.dart';
import 'package:analysis_server_plugin/src/correction/performance.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/library_graph.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/util/platform_info.dart';
import 'package:collection/collection.dart';
import 'package:vm_service/vm_service_io.dart' as vm_service;

/// Returns a json encoding of a map containing the data to be collected.
Future<String> collectAllData(AnalysisServer server) async {
  Map<String, Object?> collectedData = {};

  _collectGeneralData(collectedData, server);
  _collectMessageSchedulerData(collectedData, server);
  await _collectProcessData(collectedData);
  collectCommunicationData(collectedData, server);
  collectContextData(collectedData, server);
  _collectAnalysisDriverData(collectedData, server);
  _collectFileByteStoreTimingData(collectedData, server);
  _collectPerformanceData(collectedData, server);
  _collectExceptionsData(collectedData, server);
  await _collectObservatoryData(collectedData);

  const JsonEncoder encoder = JsonEncoder.withIndent('  ');
  return encoder.convert(collectedData);
}

void collectCommunicationData(
  Map<String, Object?> collectedData,
  AnalysisServer server,
) {
  for (var data in {
    'startup': server.performanceDuringStartup,
    if (server.performanceAfterStartup != null)
      'afterStartup': server.performanceAfterStartup!,
  }.entries) {
    var perf = data.value;
    var perfData = {};
    collectedData[data.key] = perfData;

    var requestCount = perf.requestCount;
    var latencyCount = perf.latencyCount;
    var averageLatency = latencyCount > 0
        ? (perf.requestLatency ~/ latencyCount)
        : null;
    var maximumLatency = perf.maxLatency;
    var slowRequestCount = perf.slowRequestCount;

    perfData['RequestCount'] = requestCount;
    perfData['LatencyCount'] = latencyCount;
    perfData['AverageLatency'] = averageLatency;
    perfData['MaximumLatency'] = maximumLatency;
    perfData['SlowRequestCount'] = slowRequestCount;
  }
}

void collectContextData(
  Map<String, Object?> collectedData,
  AnalysisServer server,
) {
  var driverMapValues = server.driverMap.values.toList();
  var contexts = [];
  collectedData['contexts'] = contexts;

  Set<String> uniqueKnownFiles = {};
  for (var driver in driverMapValues) {
    var contextData = {};
    contexts.add(contextData);
    // We don't include the name because the name might include confidential
    // information.
    var knownFiles = driver.knownFiles.map((f) => f.path).toSet();
    contextData['priorityFiles'] = driver.priorityFiles.length;
    contextData['addedFiles'] = driver.addedFiles.length;
    contextData['knownFiles'] = knownFiles.length;
    uniqueKnownFiles.addAll(knownFiles);

    var collectedOptionsData = collectOptionsData(driver);
    contextData['lints'] = collectedOptionsData.lints.sorted();
    contextData['plugins'] = collectedOptionsData.plugins.toList();
    Set<LibraryCycle> cycles = {};
    var contextRoot = driver.analysisContext!.contextRoot;
    var pathContext = contextRoot.resourceProvider.pathContext;
    for (var filePath in contextRoot.analyzedFiles()) {
      if (!file_paths.isDart(pathContext, filePath)) continue;
      var fileState = driver.fsState.getFileForPath(filePath);
      var kind = fileState.kind;
      if (kind is LibraryFileKind) {
        cycles.add(kind.libraryCycle);
      }
    }
    var cycleData = <int, int>{};
    for (var cycle in cycles) {
      cycleData[cycle.size] = (cycleData[cycle.size] ?? 0) + 1;
    }
    // Json maps need string keys.
    var sortedCycleData = <String, int>{};
    for (var size in cycleData.keys.toList()..sort()) {
      sortedCycleData['$size'] = cycleData[size]!;
    }
    contextData['libraryCycleData'] = sortedCycleData;
  }
  collectedData['uniqueKnownFiles'] = uniqueKnownFiles.length;
}

void _collectAnalysisDriverData(
  Map<String, Object?> collectedData,
  AnalysisServer server,
) {
  var buffer = StringBuffer();
  server.analysisDriverScheduler.accumulatedPerformance.write(buffer: buffer);
  collectedData['accumulatedPerformance'] = buffer.toString();
}

void _collectExceptionsData(
  Map<String, Object?> collectedData,
  AnalysisServer server,
) {
  var exceptions = [];
  collectedData['exceptions'] = exceptions;
  for (var exception in server.exceptions.items) {
    exceptions.add({
      'exception': exception.exception?.toString(),
      'fatal': exception.fatal,
      'message': exception.message,
      'stackTrace': exception.stackTrace.toString(),
    });
  }
}

void _collectFileByteStoreTimingData(
  Map<String, Object?> collectedData,
  AnalysisServer server,
) {
  var byteStoreTimings = server.byteStoreTimings
      ?.where(
        (timing) => timing.readCount != 0 || timing.readTime != Duration.zero,
      )
      .toList();
  if (byteStoreTimings != null && byteStoreTimings.isNotEmpty) {
    var performance = [];
    collectedData['byteStoreTimings'] = performance;
    for (var i = 0; i < byteStoreTimings.length; i++) {
      var timing = byteStoreTimings[i];
      if (timing.readCount == 0) {
        continue;
      }

      var nextTiming = i + 1 < byteStoreTimings.length
          ? byteStoreTimings[i + 1]
          : null;
      var duration = (nextTiming?.time ?? DateTime.now()).difference(
        timing.time,
      );
      var value = duration.inMilliseconds;
      var description =
          'Between ${timing.reason} and ${nextTiming?.reason ?? 'now'} '
          '(${'$value ms'}).';

      var itemData = {};
      performance.add(itemData);
      itemData['file_reads'] = timing.readCount;
      itemData['time'] = timing.readTime.inMilliseconds;
      itemData['description'] = description;
    }
  }
}

void _collectGeneralData(
  Map<String, Object?> collectedData,
  AnalysisServer server,
) {
  collectedData['currentTime'] = DateTime.now().millisecondsSinceEpoch;
  collectedData['operatingSystem'] = platform.operatingSystem;
  collectedData['version'] = platform.version;
  collectedData['clientId'] = server.options.clientId;
  collectedData['clientVersion'] = server.options.clientVersion;
  collectedData['protocolVersion'] = PROTOCOL_VERSION;
  collectedData['serverType'] = server.runtimeType.toString();
  collectedData['uptime'] = server.uptime.toString();
  if (server is LegacyAnalysisServer) {
    collectedData['serverServices'] = server.serverServices
        .map((e) => e.toString())
        .toList();
  } else if (server is LspAnalysisServer) {
    collectedData['clientDiagnosticInformation'] =
        server.clientDiagnosticInformation;
  }
}

void _collectMessageSchedulerData(
  Map<String, Object?> collectedData,
  AnalysisServer server,
) {
  collectedData['allowOverlappingHandlers'] =
      MessageScheduler.allowOverlappingHandlers;

  var listener = server.messageScheduler.listener;
  if (listener is! SchedulerTrackingListener) {
    return;
  }

  collectedData['messageLog'] = listener.getMessageLog();
}

Future<void> _collectObservatoryData(Map<String, Object?> collectedData) async {
  var serviceProtocolInfo = await developer.Service.getInfo();
  var startedServiceProtocol = false;
  if (serviceProtocolInfo.serverUri == null) {
    startedServiceProtocol = true;
    serviceProtocolInfo = await developer.Service.controlWebServer(
      enable: true,
      silenceOutput: true,
    );
  }

  var serverUri = serviceProtocolInfo.serverUri;
  if (serverUri != null) {
    var path = serverUri.path;
    if (!path.endsWith('/')) path += '/';
    var wsUriString = 'ws://${serverUri.authority}${path}ws';
    var serviceClient = await vm_service.vmServiceConnectUri(wsUriString);
    var vm = await serviceClient.getVM();
    collectedData['vm.architectureBits'] = vm.architectureBits;
    collectedData['vm.hostCPU'] = vm.hostCPU;
    collectedData['vm.operatingSystem'] = vm.operatingSystem;
    collectedData['vm.startTime'] = vm.startTime;

    var processMemoryUsage = await serviceClient.getProcessMemoryUsage();
    collectedData['processMemoryUsage'] = processMemoryUsage.json;

    var isolateData = [];
    collectedData['isolates'] = isolateData;
    var isolates = [...?vm.isolates, ...?vm.systemIsolates];
    for (var isolate in isolates) {
      String? id = isolate.id;
      if (id == null) continue;
      var thisIsolateData = {};
      isolateData.add(thisIsolateData);
      thisIsolateData['id'] = id;
      thisIsolateData['isolateGroupId'] = isolate.isolateGroupId;
      thisIsolateData['name'] = isolate.name;
      var isolateMemoryUsage = await serviceClient.getMemoryUsage(id);
      thisIsolateData['memory'] = isolateMemoryUsage.json;
      var allocationProfile = await serviceClient.getAllocationProfile(id);
      var allocationMembers = allocationProfile.members ?? [];
      var allocationProfileData = <Map<String, Object?>>[];
      thisIsolateData['allocationProfile'] = allocationProfileData;
      for (var member in allocationMembers) {
        var bytesCurrent = member.bytesCurrent;
        // Filter out very small entries to avoid the report becoming too big.
        if (bytesCurrent == null || bytesCurrent < 1024) continue;

        var memberData = <String, Object?>{};
        allocationProfileData.add(memberData);
        memberData['bytesCurrent'] = bytesCurrent;
        memberData['instancesCurrent'] = member.instancesCurrent;
        memberData['accumulatedSize'] = member.accumulatedSize;
        memberData['instancesAccumulated'] = member.instancesAccumulated;
        memberData['className'] = member.classRef?.name;
        memberData['libraryName'] = member.classRef?.library?.name;
      }
      allocationProfileData.sort((a, b) {
        int bytesCurrentA = a['bytesCurrent'] as int;
        int bytesCurrentB = b['bytesCurrent'] as int;
        // Largest first.
        return bytesCurrentB.compareTo(bytesCurrentA);
      });
    }
  }

  if (startedServiceProtocol) {
    await developer.Service.controlWebServer(silenceOutput: true);
  }
}

void _collectPerformanceData(
  Map<String, Object?> collectedData,
  AnalysisServer server,
) {
  collectedData['performanceCompletion'] = _convertPerformance(
    server.recentPerformance.completion.items.toList(),
  );
  collectedData['performanceGetFixes'] = _convertPerformance(
    server.recentPerformance.getFixes.items.toList(),
  );
  collectedData['performanceRequests'] = _convertPerformance(
    server.recentPerformance.requests.items.toList(),
  );
  collectedData['performanceSlowRequests'] = _convertPerformance(
    server.recentPerformance.slowRequests.items.toList(),
  );
}

Future<void> _collectProcessData(Map<String, Object?> collectedData) async {
  var profiler = ProcessProfiler.getProfilerForPlatform();
  UsageInfo? usage;
  if (profiler != null) {
    usage = await profiler.getProcessUsage(pid);
  }
  collectedData['memoryKB'] = usage?.memoryKB;
  collectedData['cpuPercentage'] = usage?.cpuPercentage;
  collectedData['currentRss'] = ProcessInfo.currentRss;
  collectedData['maxRss'] = ProcessInfo.maxRss;
}

// Recorded performance data (timing and code completion).
List<Object> _convertPerformance(List<RequestPerformance> items) {
  var performance = <Object>[];

  for (var item in items) {
    var itemData = {};
    performance.add(itemData);

    itemData['id'] = item.id;
    itemData['operation'] = item.operation;
    itemData['requestLatency'] = item.requestLatency;
    itemData['elapsed'] = item.performance.elapsed.inMilliseconds;
    itemData['startTime'] = item.startTime?.toIso8601String();

    var buffer = StringBuffer();
    item.performance.write(buffer: buffer);
    itemData['performance'] = buffer.toString();
  }
  return performance;
}
