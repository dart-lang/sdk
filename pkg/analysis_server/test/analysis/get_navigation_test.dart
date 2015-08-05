// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.analysis.get_navigation;

import 'package:analysis_server/src/domain_analysis.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:unittest/unittest.dart';

import '../utils.dart';
import 'notification_navigation_test.dart';

main() {
  initializeTestEnvironment();
  defineReflectiveTests(GetNavigationTest);
}

@reflectiveTest
class GetNavigationTest extends AbstractNavigationTest {
  static const String requestId = 'test-getNavigtion';

  @override
  void setUp() {
    super.setUp();
    server.handlers = [new AnalysisDomainHandler(server),];
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

  test_fileWithoutContext() {
    String file = '/outside.dart';
    addFile(
        file,
        '''
main() {
  print(42);
}
''');
    return _checkInvalid(file, -1, -1);
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
