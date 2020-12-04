// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/domain_analysis.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../mocks.dart';
import 'notification_navigation_test.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GetNavigationTest);
  });
}

@reflectiveTest
class GetNavigationTest extends AbstractNavigationTest {
  static const String requestId = 'test-getNavigation';

  @override
  void setUp() {
    super.setUp();
    server.handlers = [
      AnalysisDomainHandler(server),
    ];
    createProject();
  }

  Future<void> test_beforeAnalysisComplete() async {
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

  Future<void> test_comment_outsideReference() async {
    addTestFile('''
/// Returns a [String].
String main() {
}''');
    await waitForTasksFinished();
    var search = 'Returns';
    await _getNavigation(testFile, testCode.indexOf(search), 1);
    expect(regions, hasLength(0));
  }

  Future<void> test_comment_reference() async {
    addTestFile('''
/// Returns a [String].
String main() {
}''');
    await waitForTasksFinished();
    var search = '[String';
    await _getNavigation(testFile, testCode.indexOf(search), 1);
    expect(regions, hasLength(1));
    assertHasRegion('String]');
  }

  Future<void> test_fieldType() async {
    // This test mirrors test_navigation() from
    // test/integration/analysis/get_navigation_test.dart
    var text = r'''
class Foo {}

class Bar {
  Foo foo;
}
''';
    addTestFile(text);
    await _getNavigation(testFile, text.indexOf('Foo foo'), 0);
    expect(targets, hasLength(1));
    var target = targets.first;
    expect(target.kind, ElementKind.CLASS);
    expect(target.offset, text.indexOf('Foo {'));
    expect(target.length, 3);
    expect(target.startLine, 1);
    expect(target.startColumn, 7);
  }

  Future<void> test_fileDoesNotExist() async {
    var file = convertPath('$projectPath/doesNotExist.dart');
    var request = _createGetNavigationRequest(file, 0, 100);
    var response = await serverChannel.sendRequest(request);
    expect(response.error, isNull);
    expect(response.result['files'], isEmpty);
    expect(response.result['targets'], isEmpty);
    expect(response.result['regions'], isEmpty);
  }

  Future<void> test_fileOutsideOfRoot() async {
    testFile = convertPath('/outside.dart');
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

  Future<void> test_importDirective() async {
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

  Future<void> test_importUri() async {
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

  Future<void> test_invalidFilePathFormat_notAbsolute() async {
    var request = _createGetNavigationRequest('test.dart', 0, 0);
    var response = await waitResponse(request);
    expect(
      response,
      isResponseFailure(requestId, RequestErrorCode.INVALID_FILE_PATH_FORMAT),
    );
  }

  Future<void> test_invalidFilePathFormat_notNormalized() async {
    var request =
        _createGetNavigationRequest(convertPath('/foo/../bar/test.dart'), 0, 0);
    var response = await waitResponse(request);
    expect(
      response,
      isResponseFailure(requestId, RequestErrorCode.INVALID_FILE_PATH_FORMAT),
    );
  }

  Future<void> test_multipleRegions() async {
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
    var navCode = ' + bbb + ';
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

  Future<void> test_operator_index() async {
    addTestFile('''
class A {
  operator [](index) => 0;
  operator []=(index, int value) {}
}

void f(A a) {
  a[0]; // []
  a[1] = 1; // []=
  a[2] += 2;
}
''');
    await waitForTasksFinished();
    {
      var search = '[0';
      await _getNavigation(testFile, testCode.indexOf(search), 1);
      assertHasOperatorRegion(search, 1, '[](index)', 2);
    }
    {
      var search = ']; // []';
      await _getNavigation(testFile, testCode.indexOf(search), 1);
      assertHasOperatorRegion(search, 1, '[](index)', 2);
    }
    {
      var search = '[1';
      await _getNavigation(testFile, testCode.indexOf(search), 1);
      assertHasOperatorRegion(search, 1, '[]=(index', 3);
    }
    {
      var search = '] = 1';
      await _getNavigation(testFile, testCode.indexOf(search), 1);
      assertHasOperatorRegion(search, 1, '[]=(index', 3);
    }
    {
      var search = '[2';
      await _getNavigation(testFile, testCode.indexOf(search), 1);
      assertHasOperatorRegion(search, 1, '[]=(index', 3);
    }
    {
      var search = '] += 2';
      await _getNavigation(testFile, testCode.indexOf(search), 1);
      assertHasOperatorRegion(search, 1, '[]=(index', 3);
    }
  }

  Future<void> test_zeroLength_end() async {
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

  Future<void> test_zeroLength_start() async {
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

  Request _createGetNavigationRequest(String file, int offset, int length) {
    return AnalysisGetNavigationParams(file, offset, length)
        .toRequest(requestId);
  }

  Future<void> _getNavigation(String file, int offset, int length) async {
    var request = _createGetNavigationRequest(file, offset, length);
    var response = await serverChannel.sendRequest(request);
    var result = AnalysisGetNavigationResult.fromResponse(response);
    targetFiles = result.files;
    targets = result.targets;
    regions = result.regions;
  }
}
