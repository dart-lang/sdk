// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.driver;

import 'dart:async';
import 'dart:convert';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/generated/source.dart';
import 'package:async/async.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../context/mock_sdk.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DriverTest);
  });
}

@reflectiveTest
class DriverTest {
  static final MockSdk sdk = new MockSdk();

  final MemoryResourceProvider provider = new MemoryResourceProvider();
  final ByteStore byteStore = new _TestByteStore();
  final ContentCache contentCache = new ContentCache();
  final StringBuffer logBuffer = new StringBuffer();

  AnalysisDriver driver;
  StreamSplitter<AnalysisStatus> statusSplitter;
  final List<AnalysisStatus> allStatuses = <AnalysisStatus>[];
  final List<AnalysisResult> allResults = <AnalysisResult>[];

  String testProject;
  String testFile;

  void setUp() {
    new MockSdk();
    testProject = _p('/test/lib');
    testFile = _p('/test/lib/test.dart');
    driver = new AnalysisDriver(
        new PerformanceLog(logBuffer),
        provider,
        byteStore,
        contentCache,
        new SourceFactory([
          new DartUriResolver(sdk),
          new PackageMapUriResolver(provider, <String, List<Folder>>{
            'test': [provider.getFolder(testProject)]
          })
        ], null, provider),
        new AnalysisOptionsImpl()..strongMode = true);
    statusSplitter = new StreamSplitter(driver.status);
    statusSplitter.split().listen(allStatuses.add);
    driver.results.listen(allResults.add);
  }

  test_getResult() async {
    String content = 'int f() => 42;';
    _addTestFile(content, priority: true);

    AnalysisResult result = await driver.getResult(testFile);
    expect(result.path, testFile);
    expect(result.uri.toString(), 'package:test/test.dart');
    expect(result.content, content);
    expect(result.contentHash, _md5(content));
    expect(result.unit, isNotNull);
    expect(result.errors, hasLength(0));

    var f = result.unit.declarations[0] as FunctionDeclaration;
    expect(f.name.staticType.toString(), '() → int');
    expect(f.returnType.type.toString(), 'int');

    // The same result is also received through the stream.
    await _waitForIdle();
    expect(allResults, [result]);
  }

  test_getResult_errors() async {
    String content = 'main() { int vv; }';
    _addTestFile(content, priority: true);

    AnalysisResult result = await driver.getResult(testFile);
    expect(result.path, testFile);
    expect(result.errors, hasLength(1));
    {
      AnalysisError error = result.errors[0];
      expect(error.offset, 13);
      expect(error.length, 2);
      expect(error.errorCode, HintCode.UNUSED_LOCAL_VARIABLE);
      expect(error.message, "The value of the local variable 'vv' isn't used.");
      expect(error.correction, "Try removing the variable, or using it.");
    }
  }

  test_results_priority() async {
    String content = 'int f() => 42;';
    _addTestFile(content, priority: true);

    await _waitForIdle();

    expect(allResults, hasLength(1));
    AnalysisResult result = allResults.single;
    expect(result.path, testFile);
    expect(result.uri.toString(), 'package:test/test.dart');
    expect(result.content, content);
    expect(result.contentHash, _md5(content));
    expect(result.unit, isNotNull);
    expect(result.errors, hasLength(0));

    var f = result.unit.declarations[0] as FunctionDeclaration;
    expect(f.name.staticType.toString(), '() → int');
    expect(f.returnType.type.toString(), 'int');
  }

  test_results_priorityFirst() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    var c = _p('/test/lib/c.dart');
    provider.newFile(a, 'class A {}');
    provider.newFile(b, 'class B {}');
    provider.newFile(c, 'class C {}');

    driver.addFile(a);
    driver.addFile(b);
    driver.addFile(c);
    driver.priorityFiles = [b];
    await _waitForIdle();

    expect(allResults, hasLength(3));
    AnalysisResult result = allResults[0];
    expect(result.path, b);
    expect(result.unit, isNotNull);
    expect(result.errors, hasLength(0));
  }

  test_results_regular() async {
    String content = 'int f() => 42;';
    _addTestFile(content);
    await _waitForIdle();

    expect(allResults, hasLength(1));
    AnalysisResult result = allResults.single;
    expect(result.path, testFile);
    expect(result.uri.toString(), 'package:test/test.dart');
    expect(result.content, isNull);
    expect(result.contentHash, _md5(content));
    expect(result.unit, isNull);
    expect(result.errors, hasLength(0));
  }

  test_results_status() async {
    _addTestFile('int f() => 42;');
    await _waitForIdle();

    expect(allStatuses, hasLength(2));
    expect(allStatuses[0].isAnalyzing, isTrue);
    expect(allStatuses[0].isIdle, isFalse);
    expect(allStatuses[1].isAnalyzing, isFalse);
    expect(allStatuses[1].isIdle, isTrue);
  }

  void _addTestFile(String content, {bool priority: false}) {
    provider.newFile(testFile, content);
    driver.addFile(testFile);
    if (priority) {
      driver.priorityFiles = [testFile];
    }
  }

  /**
   * Return the [provider] specific path for the given Posix [path].
   */
  String _p(String path) => provider.convertPath(path);

  Future<Null> _waitForIdle() async {
    await statusSplitter.split().firstWhere((status) => status.isIdle);
  }

  static String _md5(String content) {
    return hex.encode(md5.convert(UTF8.encode(content)).bytes);
  }
}

class _TestByteStore implements ByteStore {
  final map = <String, List<int>>{};

  @override
  List<int> get(String key) {
    return map[key];
  }

  @override
  void put(String key, List<int> bytes) {
    map[key] = bytes;
  }
}
