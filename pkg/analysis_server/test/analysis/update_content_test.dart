// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.analysis.updateContent;

import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:unittest/unittest.dart';

import '../analysis_abstract.dart';
import '../reflective_tests.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(UpdateContentTest);
}


@reflectiveTest
class UpdateContentTest extends AbstractAnalysisTest {
  Map<String, List<AnalysisError>> filesErrors = {};
  int serverErrorCount = 0;
  int navigationCount = 0;

  @override
  void processNotification(Notification notification) {
    if (notification.event == ANALYSIS_ERRORS) {
      var decoded = new AnalysisErrorsParams.fromNotification(notification);
      filesErrors[decoded.file] = decoded.errors;
    }
    if (notification.event == ANALYSIS_NAVIGATION) {
      navigationCount++;
    }
    if (notification.event == SERVER_ERROR) {
      serverErrorCount++;
    }
  }

  test_discardNotifications_onSourceChange() async {
    createProject();
    addTestFile('');
    await server.onAnalysisComplete;
    server.setAnalysisSubscriptions({
      AnalysisService.NAVIGATION: [testFile].toSet()
    });
    // update file, analyze, but don't sent notifications
    navigationCount = 0;
    server.updateContent('1', {
      testFile: new AddContentOverlay('foo() {}')
    });
    server.test_performAllAnalysisOperations();
    expect(serverErrorCount, 0);
    expect(navigationCount, 0);
    // replace the file contents,
    // should discard any pending notification operations
    server.updateContent('2', {
      testFile: new AddContentOverlay('bar() {}')
    });
    await server.onAnalysisComplete;
    expect(serverErrorCount, 0);
    expect(navigationCount, 1);
  }

  test_illegal_ChangeContentOverlay() {
    // It should be illegal to send a ChangeContentOverlay for a file that
    // doesn't have an overlay yet.
    createProject();
    addTestFile('library foo;');
    String id = 'myId';
    try {
      server.updateContent(id, {
        testFile: new ChangeContentOverlay([new SourceEdit(8, 3, 'bar')])
      });
      fail('Expected an exception to be thrown');
    } on RequestFailure catch (e) {
      expect(e.response.id, id);
      expect(e.response.error.code, RequestErrorCode.INVALID_OVERLAY_CHANGE);
    }
  }

  test_multiple_contexts() {
    String fooPath = '/project1/foo.dart';
    resourceProvider.newFile(fooPath, '''
library foo;
import '../project2/baz.dart';
main() { f(); }''');
    String barPath = '/project2/bar.dart';
    resourceProvider.newFile(barPath, '''
library bar;
import 'baz.dart';
main() { f(); }''');
    String bazPath = '/project2/baz.dart';
    resourceProvider.newFile(bazPath, '''
library baz;
f(int i) {}
''');
    Request request = new AnalysisSetAnalysisRootsParams(
        ['/project1', '/project2'],
        []).toRequest('0');
    handleSuccessfulRequest(request);
    return waitForTasksFinished().then((_) {
      // Files foo.dart and bar.dart should both have errors, since they both
      // call f() with the wrong number of arguments.
      expect(filesErrors[fooPath], hasLength(1));
      expect(filesErrors[barPath], hasLength(1));
      // Overlay the content of baz.dart to eliminate the errors.
      server.updateContent('1', {
        bazPath: new AddContentOverlay('''
library baz;
f() {}
''')
      });
      return waitForTasksFinished();
    }).then((_) {
      // The overlay should have been propagated to both contexts, causing both
      // foo.dart and bar.dart to be reanalyzed and found to be free of errors.
      expect(filesErrors[fooPath], isEmpty);
      expect(filesErrors[barPath], isEmpty);
    });
  }

  test_sendNoticesAfterNopChange() async {
    createProject();
    addTestFile('');
    await server.onAnalysisComplete;
    // add an overlay
    server.updateContent('1', {
      testFile: new AddContentOverlay('main() {} main() {}')
    });
    await server.onAnalysisComplete;
    // clear errors and make a no-op change
    filesErrors.clear();
    server.updateContent('2', {
      testFile: new ChangeContentOverlay([new SourceEdit(0, 4, 'main')])
    });
    await server.onAnalysisComplete;
    // errors should have been resent
    expect(filesErrors, isNotEmpty);
  }

  test_sendNoticesAfterNopChange_flushedUnit() async {
    createProject();
    addTestFile('');
    await server.onAnalysisComplete;
    // add an overlay
    server.updateContent('1', {
      testFile: new AddContentOverlay('main() {} main() {}')
    });
    await server.onAnalysisComplete;
    // clear errors and make a no-op change
    filesErrors.clear();
    server.test_flushResolvedUnit(testFile);
    server.updateContent('2', {
      testFile: new ChangeContentOverlay([new SourceEdit(0, 4, 'main')])
    });
    await server.onAnalysisComplete;
    // errors should have been resent
    expect(filesErrors, isNotEmpty);
  }
}
