// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.driver;

import 'dart:async';
import 'dart:convert';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
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
    defineReflectiveTests(AnalysisDriverTest);
    defineReflectiveTests(AnalysisDriverSchedulerTest);
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
class AnalysisDriverSchedulerTest {
  static final MockSdk sdk = new MockSdk();

  final MemoryResourceProvider provider = new MemoryResourceProvider();
  final ByteStore byteStore = new _TestByteStore();
  final FileContentOverlay contentOverlay = new FileContentOverlay();

  final StringBuffer logBuffer = new StringBuffer();
  PerformanceLog logger;

  AnalysisDriverScheduler scheduler;

  List<AnalysisResult> allResults = [];

  AnalysisDriver newDriver() {
    AnalysisDriver driver = new AnalysisDriver(
        scheduler,
        logger,
        provider,
        byteStore,
        contentOverlay,
        new SourceFactory(
            [new DartUriResolver(sdk), new ResourceUriResolver(provider)],
            null,
            provider),
        new AnalysisOptionsImpl()..strongMode = true);
    driver.results.forEach(allResults.add);
    return driver;
  }

  void setUp() {
    logger = new PerformanceLog(logBuffer);
    scheduler = new AnalysisDriverScheduler(logger);
    scheduler.start();
  }

  test_priorities_getResult_beforePriority() async {
    AnalysisDriver driver1 = newDriver();
    AnalysisDriver driver2 = newDriver();

    String a = _p('/a.dart');
    String b = _p('/b.dart');
    String c = _p('/c.dart');
    provider.newFile(a, 'class A {}');
    provider.newFile(b, 'class B {}');
    provider.newFile(c, 'class C {}');
    driver1.addFile(a);
    driver2.addFile(b);
    driver2.addFile(c);
    driver1.priorityFiles = [a];
    driver2.priorityFiles = [a];

    AnalysisResult result = await driver2.getResult(b);
    expect(result.path, b);

    await driver1.status.firstWhere((status) => status.isIdle);
    await driver2.status.firstWhere((status) => status.isIdle);

    expect(allResults, hasLength(3));
    expect(allResults[0].path, b);
    expect(allResults[1].path, a);
    expect(allResults[2].path, c);
  }

  test_priorities_priorityBeforeGeneral1() async {
    AnalysisDriver driver1 = newDriver();
    AnalysisDriver driver2 = newDriver();

    String a = _p('/a.dart');
    String b = _p('/b.dart');
    provider.newFile(a, 'class A {}');
    provider.newFile(b, 'class B {}');
    driver1.addFile(a);
    driver2.addFile(b);
    driver1.priorityFiles = [a];
    driver2.priorityFiles = [a];

    await driver1.status.firstWhere((status) => status.isIdle);
    await driver2.status.firstWhere((status) => status.isIdle);

    expect(allResults, hasLength(2));
    expect(allResults[0].path, a);
    expect(allResults[1].path, b);
  }

  test_priorities_priorityBeforeGeneral2() async {
    AnalysisDriver driver1 = newDriver();
    AnalysisDriver driver2 = newDriver();

    String a = _p('/a.dart');
    String b = _p('/b.dart');
    provider.newFile(a, 'class A {}');
    provider.newFile(b, 'class B {}');
    driver1.addFile(a);
    driver2.addFile(b);
    driver1.priorityFiles = [b];
    driver2.priorityFiles = [b];

    await driver1.status.firstWhere((status) => status.isIdle);
    await driver2.status.firstWhere((status) => status.isIdle);

    expect(allResults, hasLength(2));
    expect(allResults[0].path, b);
    expect(allResults[1].path, a);
  }

  test_priorities_priorityBeforeGeneral3() async {
    AnalysisDriver driver1 = newDriver();
    AnalysisDriver driver2 = newDriver();

    String a = _p('/a.dart');
    String b = _p('/b.dart');
    String c = _p('/c.dart');
    provider.newFile(a, 'class A {}');
    provider.newFile(b, 'class B {}');
    provider.newFile(c, 'class C {}');
    driver1.addFile(a);
    driver1.addFile(b);
    driver2.addFile(c);
    driver1.priorityFiles = [a, c];
    driver2.priorityFiles = [a, c];

    await driver1.status.firstWhere((status) => status.isIdle);
    await driver2.status.firstWhere((status) => status.isIdle);

    expect(allResults, hasLength(3));
    expect(allResults[0].path, a);
    expect(allResults[1].path, c);
    expect(allResults[2].path, b);
  }

  String _p(String path) => provider.convertPath(path);
}

@reflectiveTest
class AnalysisDriverTest {
  static final MockSdk sdk = new MockSdk();

  final MemoryResourceProvider provider = new MemoryResourceProvider();
  final ByteStore byteStore = new _TestByteStore();
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

  test_getResult_inferTypes_finalField() async {
    _addTestFile(
        r'''
class C {
  final f = 42;
}
''',
        priority: true);
    await _waitForIdle();

    AnalysisResult result = await driver.getResult(testFile);
    expect(_getClassFieldType(result.unit, 'C', 'f'), 'int');
  }

  test_getResult_mix_fileAndPackageUris() async {
    var a = _p('/test/bin/a.dart');
    var b = _p('/test/bin/b.dart');
    var c = _p('/test/lib/c.dart');
    var d = _p('/test/test/d.dart');
    provider.newFile(
        a,
        r'''
import 'package:test/c.dart';
int x = y;
''');
    provider.newFile(
        b,
        r'''
import '../lib/c.dart';
int x = y;
''');
    provider.newFile(
        c,
        r'''
import '../test/d.dart';
var y = z;
''');
    provider.newFile(
        d,
        r'''
String z = "string";
''');

    // Analysis of my_pkg/bin/a.dart produces no error because
    // file:///my_pkg/bin/a.dart imports package:my_pkg/c.dart, and
    // package:my_pkg/c.dart's import is erroneous, causing y's reference to z
    // to be unresolved (and therefore have type dynamic).
    {
      AnalysisResult result = await driver.getResult(a);
      expect(result.errors, isEmpty);
    }

    // Analysis of my_pkg/bin/b.dart produces the error "A value of type
    // 'String' can't be assigned to a variable of type 'int'", because
    // file:///my_pkg/bin/b.dart imports file:///my_pkg/lib/c.dart, which
    // successfully imports file:///my_pkg/test/d.dart, causing y to have an
    // inferred type of String.
    {
      AnalysisResult result = await driver.getResult(b);
      List<AnalysisError> errors = result.errors;
      expect(errors, hasLength(1));
      expect(errors[0].errorCode, StaticTypeWarningCode.INVALID_ASSIGNMENT);
    }
  }

  test_getResult_sameFile_twoUris() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    var c = _p('/test/test/c.dart');
    provider.newFile(a, 'class A<T> {}');
    provider.newFile(
        b,
        r'''
import 'a.dart';
var VB = new A<int>();
''');
    provider.newFile(
        c,
        r'''
import '../lib/a.dart';
var VC = new A<double>();
''');

    driver.addFile(a);
    driver.addFile(b);
    await _waitForIdle();

    {
      AnalysisResult result = await driver.getResult(b);
      expect(_getImportSource(result.unit, 0).uri.toString(),
          'package:test/a.dart');
      expect(_getTopLevelVarType(result.unit, 'VB'), 'A<int>');
    }

    {
      AnalysisResult result = await driver.getResult(c);
      expect(_getImportSource(result.unit, 0).uri,
          provider.pathContext.toUri(_p('/test/lib/a.dart')));
      expect(_getTopLevelVarType(result.unit, 'VC'), 'A<double>');
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

    // Update "a" so that "A1" is now "double".
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

  test_isAddedFile() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');

    driver.addFile(a);
    expect(driver.isAddedFile(a), isTrue);
    expect(driver.isAddedFile(b), isFalse);

    driver.removeFile(a);
    expect(driver.isAddedFile(a), isFalse);
    expect(driver.isAddedFile(b), isFalse);
  }

  test_part_getResult_afterLibrary() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    var c = _p('/test/lib/c.dart');
    provider.newFile(
        a,
        r'''
library a;
import 'b.dart';
part 'c.dart';
class A {}
var c = new C();
''');
    provider.newFile(b, 'class B {}');
    provider.newFile(
        c,
        r'''
part of a;
class C {}
var a = new A();
var b = new B();
''');

    driver.addFile(a);
    driver.addFile(b);
    driver.addFile(c);

    // Process a.dart so that we know that it's a library for c.dart later.
    {
      AnalysisResult result = await driver.getResult(a);
      expect(result.errors, isEmpty);
      expect(_getTopLevelVarType(result.unit, 'c'), 'C');
    }

    // Now c.dart can be resolved without errors in the context of a.dart
    {
      AnalysisResult result = await driver.getResult(c);
      expect(result.errors, isEmpty);
      expect(_getTopLevelVarType(result.unit, 'a'), 'A');
      expect(_getTopLevelVarType(result.unit, 'b'), 'B');
    }
  }

  test_part_getResult_beforeLibrary() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    var c = _p('/test/lib/c.dart');
    provider.newFile(
        a,
        r'''
library a;
import 'b.dart';
part 'c.dart';
class A {}
var c = new C();
''');
    provider.newFile(b, 'class B {}');
    provider.newFile(
        c,
        r'''
part of a;
class C {}
var a = new A();
var b = new B();
''');

    driver.addFile(a);
    driver.addFile(b);
    driver.addFile(c);

    // b.dart will be analyzed after a.dart is analyzed.
    // So, A and B references are resolved.
    AnalysisResult result = await driver.getResult(c);
    expect(result.errors, isEmpty);
    expect(_getTopLevelVarType(result.unit, 'a'), 'A');
    expect(_getTopLevelVarType(result.unit, 'b'), 'B');
  }

  test_part_getResult_noLibrary() async {
    var c = _p('/test/lib/c.dart');
    provider.newFile(
        c,
        r'''
part of a;
class C {}
var a = new A();
var b = new B();
''');

    driver.addFile(c);

    // There is no library which c.dart is a part of, so it has unresolved
    // A and B references.
    AnalysisResult result = await driver.getResult(c);
    expect(result.errors, isNotEmpty);
    expect(result.unit, isNotNull);
  }

  test_part_results_afterLibrary() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    var c = _p('/test/lib/c.dart');
    provider.newFile(
        a,
        r'''
library a;
import 'b.dart';
part 'c.dart';
class A {}
var c = new C();
''');
    provider.newFile(b, 'class B {}');
    provider.newFile(
        c,
        r'''
part of a;
class C {}
var a = new A();
var b = new B();
''');

    // The order is important for creating the test case.
    driver.addFile(a);
    driver.addFile(b);
    driver.addFile(c);

    {
      await _waitForIdle();

      // c.dart was added after a.dart, so it is analyzed after a.dart,
      // so we know that a.dart is the library of c.dart, so no errors.
      AnalysisResult result = allResults.lastWhere((r) => r.path == c);
      expect(result.errors, isEmpty);
      expect(result.unit, isNull);
    }

    // Update a.dart so that c.dart is not a part.
    {
      provider.updateFile(a, '// does not use c.dart anymore');
      driver.changeFile(a);
      await _waitForIdle();

      // Now c.dart does not have a library context, so A and B cannot be
      // resolved, so there are errors.
      AnalysisResult result = allResults.lastWhere((r) => r.path == c);
      expect(result.errors, isNotEmpty);
      expect(result.unit, isNull);
    }
  }

  test_part_results_beforeLibrary() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    var c = _p('/test/lib/c.dart');
    provider.newFile(
        a,
        r'''
library a;
import 'b.dart';
part 'c.dart';
class A {}
var c = new C();
''');
    provider.newFile(b, 'class B {}');
    provider.newFile(
        c,
        r'''
part of a;
class C {}
var a = new A();
var b = new B();
''');

    // The order is important for creating the test case.
    driver.addFile(c);
    driver.addFile(a);
    driver.addFile(b);

    await _waitForIdle();

    // c.dart was added before a.dart, so we attempt to analyze it before
    // a.dart, but we cannot find the library for it, so we delay analysis
    // until all other files are analyzed, including a.dart, after which we
    // analyze the delayed parts.
    AnalysisResult result = allResults.lastWhere((r) => r.path == c);
    expect(result.errors, isEmpty);
    expect(result.unit, isNull);
  }

  test_part_results_noLibrary() async {
    var c = _p('/test/lib/c.dart');
    provider.newFile(
        c,
        r'''
part of a;
class C {}
var a = new A();
var b = new B();
''');

    driver.addFile(c);

    await _waitForIdle();

    // There is no library which c.dart is a part of, so it has unresolved
    // A and B references.
    AnalysisResult result = allResults.lastWhere((r) => r.path == c);
    expect(result.errors, isNotEmpty);
    expect(result.unit, isNull);
  }

  test_part_results_priority_beforeLibrary() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    var c = _p('/test/lib/c.dart');
    provider.newFile(
        a,
        r'''
library a;
import 'b.dart';
part 'c.dart';
class A {}
var c = new C();
''');
    provider.newFile(b, 'class B {}');
    provider.newFile(
        c,
        r'''
part of a;
class C {}
var a = new A();
var b = new B();
''');

    // The order is important for creating the test case.
    driver.priorityFiles = [c];
    driver.addFile(c);
    driver.addFile(a);
    driver.addFile(b);

    await _waitForIdle();

    // c.dart was added before a.dart, so we attempt to analyze it before
    // a.dart, but we cannot find the library for it, so we delay analysis
    // until all other files are analyzed, including a.dart, after which we
    // analyze the delayed parts.
    AnalysisResult result = allResults.lastWhere((r) => r.path == c);
    expect(result.errors, isEmpty);
    expect(result.unit, isNotNull);
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

  ClassDeclaration _getClass(CompilationUnit unit, String name) {
    for (CompilationUnitMember declaration in unit.declarations) {
      if (declaration is ClassDeclaration) {
        if (declaration.name.name == name) {
          return declaration;
        }
      }
    }
    fail('Cannot find the class $name in\n$unit');
    return null;
  }

  VariableDeclaration _getClassField(
      CompilationUnit unit, String className, String fieldName) {
    ClassDeclaration classDeclaration = _getClass(unit, className);
    for (ClassMember declaration in classDeclaration.members) {
      if (declaration is FieldDeclaration) {
        for (var field in declaration.fields.variables) {
          if (field.name.name == fieldName) {
            return field;
          }
        }
      }
    }
    fail('Cannot find the field $fieldName in the class $className in\n$unit');
    return null;
  }

  String _getClassFieldType(
      CompilationUnit unit, String className, String fieldName) {
    return _getClassField(unit, className, fieldName).element.type.toString();
  }

  ImportElement _getImportElement(CompilationUnit unit, int directiveIndex) {
    var import = unit.directives[directiveIndex] as ImportDirective;
    return import.element as ImportElement;
  }

  Source _getImportSource(CompilationUnit unit, int directiveIndex) {
    return _getImportElement(unit, directiveIndex).importedLibrary.source;
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
