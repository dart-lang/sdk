// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.analysis.get_navigation;

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/domain_analysis.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'notification_navigation_test.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GetNavigationTest);
    defineReflectiveTests(GetNavigationTest_Driver);
  });
}

@reflectiveTest
class GetNavigationTest extends AbstractNavigationTest {
  static const String requestId = 'test-getNavigation';

  @override
  void setUp() {
    super.setUp();
    server.handlers = [
      new AnalysisDomainHandler(server),
    ];
    createProject();
  }

  test_beforeAnalysisComplete() async {
    addTestFile('''
main() {
  var test = 0;
  print(test);
}
''');
    await _getNavigation(testFile, testCode.indexOf('test);'), 0);
    assertHasRegion('test);');
    assertHasTarget('test = 0');
  }

  test_fileDoesNotExist() {
    String file = '$projectPath/doesNotExist.dart';
    return _checkInvalid(file, -1, -1);
  }

  test_importDirective() async {
    addTestFile('''
import 'dart:math';

main() {
}''');
    await waitForTasksFinished();
    await _getNavigation(testFile, 0, 17);
    expect(regions, hasLength(1));
    assertHasRegionString("'dart:math'");
    expect(testTargets, hasLength(1));
    expect(testTargets[0].kind, ElementKind.LIBRARY);
  }

  test_importKeyword() async {
    addTestFile('''
import 'dart:math';

main() {
}''');
    await waitForTasksFinished();
    await _getNavigation(testFile, 0, 1);
    expect(regions, hasLength(1));
    assertHasRegionString("'dart:math'");
    expect(testTargets, hasLength(1));
    expect(testTargets[0].kind, ElementKind.LIBRARY);
  }

  test_importUri() async {
    addTestFile('''
import 'dart:math';

main() {
}''');
    await waitForTasksFinished();
    await _getNavigation(testFile, 7, 11);
    expect(regions, hasLength(1));
    assertHasRegionString("'dart:math'");
    expect(testTargets, hasLength(1));
    expect(testTargets[0].kind, ElementKind.LIBRARY);
  }

  test_multipleRegions() async {
    addTestFile('''
main() {
  var aaa = 1;
  var bbb = 2;
  var ccc = 3;
  var ddd = 4;
  print(aaa + bbb + ccc + ddd);
}
''');
    await waitForTasksFinished();
    // request navigation
    String navCode = ' + bbb + ';
    await _getNavigation(testFile, testCode.indexOf(navCode), navCode.length);
    // verify
    {
      assertHasRegion('aaa +');
      assertHasTarget('aaa = 1');
    }
    {
      assertHasRegion('bbb +');
      assertHasTarget('bbb = 2');
    }
    {
      assertHasRegion('ccc +');
      assertHasTarget('ccc = 3');
    }
    assertNoRegionAt('ddd)');
  }

  test_operator_index() async {
    addTestFile('''
class A {
  A operator [](index) => null;
  operator []=(index, A value) {}
}
main() {
  var a = new A();
  a[0] // [];
  a[1] = 1; // []=;
  a[2] += 2;
}
''');
    await waitForTasksFinished();
    {
      String search = '[0';
      await _getNavigation(testFile, testCode.indexOf(search), 1);
      assertHasOperatorRegion(search, 1, '[](index)', 2);
    }
    {
      String search = '] // []';
      await _getNavigation(testFile, testCode.indexOf(search), 1);
      assertHasOperatorRegion(search, 1, '[](index)', 2);
    }
    {
      String search = '[1';
      await _getNavigation(testFile, testCode.indexOf(search), 1);
      assertHasOperatorRegion(search, 1, '[]=(index', 3);
    }
    {
      String search = '] = 1';
      await _getNavigation(testFile, testCode.indexOf(search), 1);
      assertHasOperatorRegion(search, 1, '[]=(index', 3);
    }
    {
      String search = '[2';
      await _getNavigation(testFile, testCode.indexOf(search), 1);
      assertHasOperatorRegion(search, 1, '[]=(index', 3);
    }
    {
      String search = '] += 2';
      await _getNavigation(testFile, testCode.indexOf(search), 1);
      assertHasOperatorRegion(search, 1, '[]=(index', 3);
    }
  }

  test_removeContextAfterRequest() async {
    addTestFile('''
main() {
  var test = 0;
  print(test);
}
''');
    // handle the request synchronously
    Request request =
        _createGetNavigationRequest(testFile, testCode.indexOf('test);'), 0);
    server.handleRequest(request);
    // remove context, causes sending an "invalid file" error
    {
      Folder projectFolder = resourceProvider.getResource(projectPath);
      server.contextManager.callbacks.removeContext(projectFolder, <String>[]);
    }
    // wait for an error response
    Response response = await serverChannel.waitForResponse(request);
    expect(response.error, isNotNull);
    expect(response.error.code, RequestErrorCode.GET_NAVIGATION_INVALID_FILE);
  }

  test_zeroLength_end() async {
    addTestFile('''
main() {
  var test = 0;
  print(test);
}
''');
    await waitForTasksFinished();
    await _getNavigation(testFile, testCode.indexOf(');'), 0);
    assertHasRegion('test);');
    assertHasTarget('test = 0');
  }

  test_zeroLength_start() async {
    addTestFile('''
main() {
  var test = 0;
  print(test);
}
''');
    await waitForTasksFinished();
    await _getNavigation(testFile, testCode.indexOf('test);'), 0);
    assertHasRegion('test);');
    assertHasTarget('test = 0');
  }

  _checkInvalid(String file, int offset, int length) async {
    Request request = _createGetNavigationRequest(file, offset, length);
    Response response = await serverChannel.sendRequest(request);
    expect(response.error, isNotNull);
    expect(response.error.code, RequestErrorCode.GET_NAVIGATION_INVALID_FILE);
  }

  Request _createGetNavigationRequest(String file, int offset, int length) {
    return new AnalysisGetNavigationParams(file, offset, length)
        .toRequest(requestId);
  }

  _getNavigation(String file, int offset, int length) async {
    Request request = _createGetNavigationRequest(file, offset, length);
    Response response = await serverChannel.sendRequest(request);
    AnalysisGetNavigationResult result =
        new AnalysisGetNavigationResult.fromResponse(response);
    targetFiles = result.files;
    targets = result.targets;
    regions = result.regions;
  }
}

@reflectiveTest
class GetNavigationTest_Driver extends GetNavigationTest {
  @override
  void setUp() {
    enableNewAnalysisDriver = true;
    generateSummaryFiles = true;
    super.setUp();
  }

  test_fileOutsideOfRoot() async {
    testFile = '/outside.dart';
    addTestFile('''
main() {
  var test = 0;
  print(test);
}
''');
    await _getNavigation(testFile, testCode.indexOf('test);'), 0);
    assertHasRegion('test);');
    assertHasTarget('test = 0');
  }
}
