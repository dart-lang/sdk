// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:collection/collection.dart';
import 'package:devtools_shared/devtools_shared.dart';
import 'package:logging/logging.dart';
import 'package:vm_service/vm_service.dart';

final _logger = Logger('$MemoryProfile');

/// Manages VM memory profiling and sample collection.
class MemoryProfile {
  MemoryProfile(this.service, String profileFilename, this._verboseMode) {
    onConnectionClosed.listen(_handleConnectionStop);
    service!.onEvent('Service').listen(handleServiceEvent);
    _jsonFile = MemoryJsonFile.create(profileFilename);
    _hookUpEvents();
  }

  late MemoryJsonFile _jsonFile;
  final bool _verboseMode;

  void _hookUpEvents() async {
    final streamIds = [
      EventStreams.kExtension,
      EventStreams.kGC,
      EventStreams.kIsolate,
      EventStreams.kLogging,
      EventStreams.kStderr,
      EventStreams.kStdout,
      EventStreams.kVM,
      EventStreams.kService,
    ];

    await Future.wait(
      streamIds.map((String id) async {
        try {
          await service!.streamListen(id);
        } catch (e) {
          if (!id.endsWith('Logging')) {
            _logger.warning("Service client stream not supported: '$id'\n  $e");
          }
        }
      }),
    );
  }

  bool get hasConnection => service != null;

  void handleServiceEvent(Event e) {
    if (e.kind == EventKind.kServiceRegistered) {
      final serviceName = e.service!;
      _registeredMethodsForService
          .putIfAbsent(serviceName, () => [])
          .add(e.method!);
    }

    if (e.kind == EventKind.kServiceUnregistered) {
      final serviceName = e.service!;
      _registeredMethodsForService.remove(serviceName);
    }
  }

  late IsolateRef _selectedIsolate;

  Future<Response?> getAdbMemoryInfo() async {
    return await callService(
      flutterMemory.service,
      isolateId: _selectedIsolate.id,
    );
  }

  /// Call a service that is registered by exactly one client.
  Future<Response?> callService(
    String name, {
    String? isolateId,
    Map<String, dynamic>? args,
  }) {
    final registered = _registeredMethodsForService[name] ?? const [];
    if (registered.isEmpty) {
      throw Exception('There are no registered methods for service "$name"');
    }
    return service!.callMethod(
      registered.first,
      isolateId: isolateId,
      args: args,
    );
  }

  Map<String, List<String>> get registeredMethodsForService =>
      _registeredMethodsForService;
  final _registeredMethodsForService = <String, List<String>>{};

  static const Duration updateDelay = Duration(milliseconds: 500);

  VmService? service;
  late Timer _pollingTimer;

  int? processRss;
  final Map<String, List<HeapSpace>> isolateHeaps = <String, List<HeapSpace>>{};
  final List<HeapSample> samples = <HeapSample>[];

  AdbMemoryInfo? adbMemoryInfo;
  EventSample eventSample = EventSample.empty();
  RasterCache? rasterCache;
  late int heapMax;

  Stream<void> get onConnectionClosed => _connectionClosedController.stream;
  final _connectionClosedController = StreamController<void>.broadcast();

  void _handleConnectionStop(dynamic event) {}

  void startPolling() {
    _pollingTimer = Timer(updateDelay, _pollMemory);
    service!.onGCEvent.listen(_handleGCEvent);
  }

  void _handleGCEvent(Event event) {
    final json = event.json!;
    final heaps = <HeapSpace>[
      HeapSpace.parse(json['new'] as Map<String, Object?>?)!,
      HeapSpace.parse(json['old'] as Map<String, Object?>?)!,
    ];
    _updateGCEvent(event.isolate!.id!, heaps);
  }

  void stopPolling() {
    _pollingTimer.cancel();
    service = null;
  }

  Future<void> _pollMemory() async {
    final service = this.service!;
    final vm = await service.getVM();

    final isolates = await Future.wait(
      vm.isolates!.map((IsolateRef ref) async {
        try {
          return await service.getIsolate(ref.id!);
        } catch (e, st) {
          _logger.warning('Error [MEMORY_PROTOCOL]', e, st);
          return Future<Isolate?>.value();
        }
      }),
    );

    final isolate = isolates[0]!;
    _selectedIsolate = IsolateRef(
      id: isolate.id,
      name: isolate.name,
      number: isolate.number,
      isSystemIsolate: isolate.isSystemIsolate,
    );

    if (hasConnection && vm.operatingSystem == 'android') {
      adbMemoryInfo = await _fetchAdbInfo();
    } else {
      adbMemoryInfo = AdbMemoryInfo.empty();
    }

    rasterCache = await _fetchRasterCacheInfo(_selectedIsolate);
    eventSample = EventSample.empty();
    _update(vm, isolates);
    _pollingTimer = Timer(updateDelay, _pollMemory);
  }

  Future<AdbMemoryInfo?> _fetchAdbInfo() async {
    final adbMemInfo = await getAdbMemoryInfo();
    if (adbMemInfo?.json != null) {
      return AdbMemoryInfo.fromJsonInKB(adbMemInfo!.json!);
    }
    return null;
  }

  Future<RasterCache?> _fetchRasterCacheInfo(IsolateRef selectedIsolate) async {
    final response = await getRasterCacheMetrics(selectedIsolate);
    return RasterCache.parse(response?.json);
  }

  Future<String?> getFlutterViewId(IsolateRef selectedIsolate) async {
    final flutterViewListResponse = await service!.callServiceExtension(
      flutterListViews,
      isolateId: selectedIsolate.id,
    );
    final views = (flutterViewListResponse.json!['views'] as List<dynamic>)
        .cast<Map<String, dynamic>>();

    final flutterView = views.firstWhereOrNull(
      (view) => view['type'] == 'FlutterView',
    );

    if (flutterView == null) {
      final message =
          'No Flutter Views to query: ${flutterViewListResponse.json}';
      _logger.severe(message);
      throw Exception(message);
    }

    final flutterViewId = flutterView['id'] as String;
    return flutterViewId;
  }

  Future<Response?> getRasterCacheMetrics(IsolateRef selectedIsolate) async {
    final viewId = await getFlutterViewId(selectedIsolate);

    return await service!.callServiceExtension(
      flutterEngineRasterCache,
      args: {'viewId': viewId},
      isolateId: selectedIsolate.id,
    );
  }

  void _update(VM vm, List<Isolate?> isolates) {
    processRss = vm.json!['_currentRSS'] as int?;

    isolateHeaps.clear();
    for (final isolate in isolates) {
      if (isolate != null) {
        isolateHeaps[isolate.id!] = getHeaps(isolate);
      }
    }

    _recalculate();
  }

  void _updateGCEvent(String id, List<HeapSpace> heaps) {
    isolateHeaps[id] = heaps;
    _recalculate(true);
  }

  /// Aggregates memory usage metrics (used, capacity, and external memory)
  /// across all isolate heaps, using the [HeapSpace] metrics returned by the
  /// VM service.
  void _recalculate([bool fromGC = false]) {
    var total = 0;
    var used = 0;
    var capacity = 0;
    var external = 0;

    for (final heaps in isolateHeaps.values) {
      used += heaps.fold<int>(0, (i, heap) => i + heap.used!);
      capacity += heaps.fold<int>(0, (i, heap) => i + heap.capacity!);
      external += heaps.fold<int>(0, (i, heap) => i + heap.external!);
      capacity += external;
      total += heaps.fold<int>(
        0,
        (i, heap) => i + heap.capacity! + heap.external!,
      );
    }

    heapMax = total;
    final time = DateTime.now().millisecondsSinceEpoch;
    final sample = HeapSample(
      time,
      processRss ?? -1,
      capacity,
      used,
      external,
      fromGC,
      adbMemoryInfo,
      eventSample,
      rasterCache,
    );

    if (_verboseMode) {
      final timeCollected = _formatTime(
        DateTime.fromMillisecondsSinceEpoch(time),
      );

      print(
        ' Collected Sample: [$timeCollected] capacity=$capacity, '
        'ADB MemoryInfo total=${adbMemoryInfo!.total}${fromGC ? ' [GC]' : ''}',
      );
    }

    _jsonFile.writeSample(sample);
  }

  static List<HeapSpace> getHeaps(Isolate isolate) {
    final heaps = isolate.json!['_heaps'] as Map<String, dynamic>;
    final heapList = <HeapSpace>[];
    for (final heapJson in heaps.values) {
      final heap = HeapSpace.parse(heapJson as Map<String, Object?>?);
      if (heap != null) {
        heapList.add(heap);
      }
    }
    return heapList;
  }

  static String _formatTime(DateTime value) {
    String toStringLength(int value, int length) {
      final result = '$value';
      assert(length >= result.length);
      return '0' * (length - result.length) + result;
    }

    return '${toStringLength(value.hour, 2)}:'
        '${toStringLength(value.minute, 2)}:'
        '${toStringLength(value.second, 2)}';
  }
}

class MemoryJsonFile {
  MemoryJsonFile.create(this._absoluteFileName) {
    file = io.File(_absoluteFileName);
    _outputStream = file.openWrite(mode: io.FileMode.append);
  }

  final String _absoluteFileName;
  late final io.File file;
  late final io.IOSink _outputStream;

  void writeSample(HeapSample sample) {
    _outputStream.writeln(jsonEncode(sample.toJson()));
  }

  void close() {
    _outputStream.close();
  }
}
