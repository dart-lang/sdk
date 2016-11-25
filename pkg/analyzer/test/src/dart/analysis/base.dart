// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/status.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/generated/source.dart';
import 'package:test/test.dart';

import '../../context/mock_sdk.dart';

/**
 * Finds an [Element] with the given [name].
 */
Element findChildElement(Element root, String name, [ElementKind kind]) {
  Element result = null;
  root.accept(new _ElementVisitorFunctionWrapper((Element element) {
    if (element.name != name) {
      return;
    }
    if (kind != null && element.kind != kind) {
      return;
    }
    result = element;
  }));
  return result;
}

typedef bool Predicate<E>(E argument);

/**
 * A function to be called for every [Element].
 */
typedef void _ElementVisitorFunction(Element element);

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

  int findOffset(String search) {
    int offset = testCode.indexOf(search);
    if (offset < 0) {
      fail("Did not find '$search' in\n$testCode");
    }
    return offset;
  }

  int getLeadingIdentifierLength(String search) {
    int length = 0;
    while (length < search.length) {
      int c = search.codeUnitAt(length);
      if (c >= 'a'.codeUnitAt(0) && c <= 'z'.codeUnitAt(0)) {
        length++;
        continue;
      }
      if (c >= 'A'.codeUnitAt(0) && c <= 'Z'.codeUnitAt(0)) {
        length++;
        continue;
      }
      if (c >= '0'.codeUnitAt(0) && c <= '9'.codeUnitAt(0)) {
        length++;
        continue;
      }
      break;
    }
    return length;
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

/**
 * Wraps an [_ElementVisitorFunction] into a [GeneralizingElementVisitor].
 */
class _ElementVisitorFunctionWrapper extends GeneralizingElementVisitor {
  final _ElementVisitorFunction function;

  _ElementVisitorFunctionWrapper(this.function);

  visitElement(Element element) {
    function(element);
    super.visitElement(element);
  }
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
