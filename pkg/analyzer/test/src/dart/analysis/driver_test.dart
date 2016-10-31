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

/**
 * Returns a [Future] that completes after pumping the event queue [times]
 * times. By default, this should pump the event queue enough times to allow
 * any code to run, as long as it's not waiting on some external event.
 */
Future pumpEventQueue([int times = 5000]) {
  if (times == 0) return new Future.value();
  // We use a delayed future to allow microtask events to finish. The
  // Future.value or Future() constructors use scheduleMicrotask themselves and
  // would therefore not wait for microtask callbacks that are scheduled after
  // invoking this method.
  return new Future.delayed(Duration.ZERO, () => pumpEventQueue(times - 1));
}

@reflectiveTest
class DriverTest {
  static final MockSdk sdk = new MockSdk();

  final MemoryResourceProvider provider = new MemoryResourceProvider();
  final ByteStore byteStore = new _TestByteStore();
  final ContentCache contentCache = new ContentCache();
  final StringBuffer logBuffer = new StringBuffer();

  AnalysisDriver driver;
  final _Monitor idleStatusMonitor = new _Monitor();
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
    driver.status.lastWhere((status) {
      allStatuses.add(status);
      if (status.isIdle) {
        idleStatusMonitor.notify();
      }
    });
    driver.results.listen(allResults.add);
  }

  test_addFile_thenRemove() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    provider.newFile(a, 'class A {}');
    provider.newFile(b, 'class B {}');
    driver.addFile(a);
    driver.addFile(b);

    // Now remove 'a'.
    driver.removeFile(a);

    await _waitForIdle();

    // Only 'b' has been analyzed, because 'a' was removed before we started.
    expect(allResults, hasLength(1));
    expect(allResults[0].path, b);
  }

  test_changeFile_implicitlyAnalyzed() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    provider.newFile(
        a,
        r'''
import 'b.dart';
var A = B;
''');
    provider.newFile(b, 'var B = 1;');

    driver.priorityFiles = [a];
    driver.addFile(a);

    // We have a result only for "a".
    await _waitForIdle();
    expect(allResults, hasLength(1));
    {
      AnalysisResult ar = allResults.firstWhere((r) => r.path == a);
      expect(_getTopLevelVarType(ar.unit, 'A'), 'int');
    }
    allResults.clear();

    // Change "b" and notify.
    provider.updateFile(b, 'var B = 1.2;');
    driver.changeFile(b);

    // While "b" is not analyzed explicitly, it is analyzed implicitly.
    // The change causes "a" to be reanalyzed.
    await _waitForIdle();
    expect(allResults, hasLength(1));
    {
      AnalysisResult ar = allResults.firstWhere((r) => r.path == a);
      expect(_getTopLevelVarType(ar.unit, 'A'), 'double');
    }
  }

  test_changeFile_selfConsistent() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    provider.newFile(
        a,
        r'''
import 'b.dart';
var A1 = 1;
var A2 = B1;
''');
    provider.newFile(
        b,
        r'''
import 'a.dart';
var B1 = A1;
''');

    driver.priorityFiles = [a, b];
    driver.addFile(a);
    driver.addFile(b);
    await _waitForIdle();

    // We have results for both "a" and "b".
    expect(allResults, hasLength(2));
    {
      AnalysisResult ar = allResults.firstWhere((r) => r.path == a);
      expect(_getTopLevelVarType(ar.unit, 'A1'), 'int');
      expect(_getTopLevelVarType(ar.unit, 'A2'), 'int');
    }
    {
      AnalysisResult br = allResults.firstWhere((r) => r.path == b);
      expect(_getTopLevelVarType(br.unit, 'B1'), 'int');
    }

    // Clear the results and update "a".
    allResults.clear();
    provider.updateFile(
        a,
        r'''
import 'b.dart';
var A1 = 1.2;
var A2 = B1;
''');
    driver.changeFile(a);

    // We again get results for both "a" and "b".
    // The results are consistent.
    await _waitForIdle();
    expect(allResults, hasLength(2));
    {
      AnalysisResult ar = allResults.firstWhere((r) => r.path == a);
      expect(_getTopLevelVarType(ar.unit, 'A1'), 'double');
      expect(_getTopLevelVarType(ar.unit, 'A2'), 'double');
    }
    {
      AnalysisResult br = allResults.firstWhere((r) => r.path == b);
      expect(_getTopLevelVarType(br.unit, 'B1'), 'double');
    }
  }

  test_changeFile_single() async {
    _addTestFile('var V = 1;', priority: true);

    // Initial analysis.
    {
      await _waitForIdle();
      expect(allResults, hasLength(1));
      AnalysisResult result = allResults[0];
      expect(result.path, testFile);
      expect(_getTopLevelVarType(result.unit, 'V'), 'int');
    }

    // Update the file, but don't notify the driver.
    allResults.clear();
    provider.updateFile(testFile, 'var V = 1.2');

    // No new results.
    await pumpEventQueue();
    expect(allResults, isEmpty);

    // Notify the driver about the change.
    driver.changeFile(testFile);

    // We get a new result.
    {
      await _waitForIdle();
      expect(allResults, hasLength(1));
      AnalysisResult result = allResults[0];
      expect(result.path, testFile);
      expect(_getTopLevelVarType(result.unit, 'V'), 'double');
    }
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

  test_getResult_selfConsistent() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    provider.newFile(
        a,
        r'''
import 'b.dart';
var A1 = 1;
var A2 = B1;
''');
    provider.newFile(
        b,
        r'''
import 'a.dart';
var B1 = A1;
''');

    driver.addFile(a);
    driver.addFile(b);
    await _waitForIdle();

    {
      AnalysisResult result = await driver.getResult(a);
      expect(_getTopLevelVarType(result.unit, 'A1'), 'int');
      expect(_getTopLevelVarType(result.unit, 'A2'), 'int');
    }

    // Update "a" that that "A1" is now "double".
    // Get result for "a".
    //
    // Even though we have not notified the driver about the change,
    // we still get "double" for "A1", because getResult() re-read the content.
    //
    // We also get "double" for "A2", even though "A2" has the type from "b".
    // That's because we check for "a" API signature consistency, and because
    // it has changed, we invalidated the dependency cache, relinked libraries
    // and recomputed types.
    provider.updateFile(
        a,
        r'''
import 'b.dart';
var A1 = 1.2;
var A2 = B1;
''');
    {
      AnalysisResult result = await driver.getResult(a);
      expect(_getTopLevelVarType(result.unit, 'A1'), 'double');
      expect(_getTopLevelVarType(result.unit, 'A2'), 'double');
    }
  }

  test_getResult_thenRemove() async {
    _addTestFile('main() {}', priority: true);

    Future<AnalysisResult> resultFuture = driver.getResult(testFile);
    driver.removeFile(testFile);

    AnalysisResult result = await resultFuture;
    expect(result, isNotNull);
    expect(result.path, testFile);
    expect(result.unit, isNotNull);
  }

  test_getResult_twoPendingFutures() async {
    String content = 'main() {}';
    _addTestFile(content, priority: true);

    Future<AnalysisResult> future1 = driver.getResult(testFile);
    Future<AnalysisResult> future2 = driver.getResult(testFile);

    // Both futures complete, with the same result.
    AnalysisResult result1 = await future1;
    AnalysisResult result2 = await future2;
    expect(result2, same(result1));
    expect(result1.path, testFile);
    expect(result1.unit, isNotNull);
  }

  test_removeFile_changeFile_implicitlyAnalyzed() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    provider.newFile(
        a,
        r'''
import 'b.dart';
var A = B;
''');
    provider.newFile(b, 'var B = 1;');

    driver.priorityFiles = [a, b];
    driver.addFile(a);
    driver.addFile(b);

    // We have results for both "a" and "b".
    await _waitForIdle();
    expect(allResults, hasLength(2));
    {
      AnalysisResult ar = allResults.firstWhere((r) => r.path == a);
      expect(_getTopLevelVarType(ar.unit, 'A'), 'int');
    }
    {
      AnalysisResult br = allResults.firstWhere((r) => r.path == b);
      expect(_getTopLevelVarType(br.unit, 'B'), 'int');
    }
    allResults.clear();

    // Remove "b" and send the change notification.
    provider.updateFile(b, 'var B = 1.2;');
    driver.removeFile(b);
    driver.changeFile(b);

    // While "b" is not analyzed explicitly, it is analyzed implicitly.
    // We don't get a result for "b".
    // But the change causes "a" to be reanalyzed.
    await _waitForIdle();
    expect(allResults, hasLength(1));
    {
      AnalysisResult ar = allResults.firstWhere((r) => r.path == a);
      expect(_getTopLevelVarType(ar.unit, 'A'), 'double');
    }
  }

  test_removeFile_changeFile_notAnalyzed() async {
    _addTestFile('main() {}');

    // We have a result.
    await _waitForIdle();
    expect(allResults, hasLength(1));
    expect(allResults[0].path, testFile);
    allResults.clear();

    // Remove the file and send the change notification.
    // The change notification does nothing, because the file is explicitly
    // or implicitly analyzed.
    driver.removeFile(testFile);
    driver.changeFile(testFile);

    await _waitForIdle();
    expect(allResults, isEmpty);
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

  VariableDeclaration _getTopLevelVar(CompilationUnit unit, String name) {
    for (CompilationUnitMember declaration in unit.declarations) {
      if (declaration is TopLevelVariableDeclaration) {
        for (VariableDeclaration variable in declaration.variables.variables) {
          if (variable.name.name == name) {
            return variable;
          }
        }
      }
    }
    fail('Cannot find the top-level variable $name in\n$unit');
    return null;
  }

  String _getTopLevelVarType(CompilationUnit unit, String name) {
    return _getTopLevelVar(unit, name).element.type.toString();
  }

  /**
   * Return the [provider] specific path for the given Posix [path].
   */
  String _p(String path) => provider.convertPath(path);

  Future<Null> _waitForIdle() async {
    await idleStatusMonitor.signal;
  }

  static String _md5(String content) {
    return hex.encode(md5.convert(UTF8.encode(content)).bytes);
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
