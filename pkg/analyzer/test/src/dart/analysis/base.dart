// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/status.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/generated/source.dart';

import '../../context/mock_sdk.dart';

class BaseAnalysisDriverTest {
  static final MockSdk sdk = new MockSdk();

  final MemoryResourceProvider provider = new MemoryResourceProvider();
  final ByteStore byteStore = new MemoryByteStore();
  final FileContentOverlay contentOverlay = new FileContentOverlay();

  final StringBuffer logBuffer = new StringBuffer();
  PerformanceLog logger;

  AnalysisDriverScheduler scheduler;
  AnalysisDriver driver;
  final _Monitor idleStatusMonitor = new _Monitor();
  final List<AnalysisStatus> allStatuses = <AnalysisStatus>[];
  final List<AnalysisResult> allResults = <AnalysisResult>[];

  String testProject;
  String testFile;
  String testCode;

  void addTestFile(String content, {bool priority: false}) {
    testCode = content;
    provider.newFile(testFile, content);
    driver.addFile(testFile);
    if (priority) {
      driver.priorityFiles = [testFile];
    }
  }

  void setUp() {
    new MockSdk();
    testProject = _p('/test/lib');
    testFile = _p('/test/lib/test.dart');
    logger = new PerformanceLog(logBuffer);
    scheduler = new AnalysisDriverScheduler(logger);
    driver = new AnalysisDriver(
        scheduler,
        logger,
        provider,
        byteStore,
        contentOverlay,
        new SourceFactory([
          new DartUriResolver(sdk),
          new PackageMapUriResolver(provider, <String, List<Folder>>{
            'test': [provider.getFolder(testProject)]
          }),
          new ResourceUriResolver(provider)
        ], null, provider),
        new AnalysisOptionsImpl()..strongMode = true);
    scheduler.start();
    driver.status.lastWhere((status) {
      allStatuses.add(status);
      if (status.isIdle) {
        idleStatusMonitor.notify();
      }
    });
    driver.results.listen(allResults.add);
  }

  String _p(String path) => provider.convertPath(path);
}

class _Monitor {
  Completer<Null> _completer = new Completer<Null>();

  Future<Null> get signal async {
    await _completer.future;
    _completer = new Completer<Null>();
  }

  void notify() {
    if (!_completer.isCompleted) {
      _completer.complete(null);
    }
  }
}
