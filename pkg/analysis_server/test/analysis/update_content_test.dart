// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_server_base.dart';
import '../mocks.dart';
import '../services/refactoring/abstract_rename.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UpdateContentTest);
  });
}

@reflectiveTest
class UpdateContentTest extends PubPackageAnalysisServerTest {
  Map<File, List<String>> filesErrors = {};
  int serverErrorCount = 0;
  int navigationCount = 0;

  @override
  void processNotification(Notification notification) {
    if (notification.event == ANALYSIS_NOTIFICATION_ERRORS) {
      var decoded = AnalysisErrorsParams.fromNotification(notification);
      String _format(AnalysisError e) =>
          '${e.location.startLine}: ${e.message}';
      filesErrors[getFile(decoded.file)] = decoded.errors.map(_format).toList();
    }
    if (notification.event == ANALYSIS_NOTIFICATION_NAVIGATION) {
      navigationCount++;
    }
    if (notification.event == SERVER_NOTIFICATION_ERROR) {
      serverErrorCount++;
    }
  }

  void test_illegal_ChangeContentOverlay() async {
    // It should be illegal to send a ChangeContentOverlay for a file that
    // doesn't have an overlay yet.
    addTestFile('');
    await setRoots(included: [workspaceRootPath], excluded: []);
    var response = await handleRequest(
      AnalysisUpdateContentParams({
        testFile.path: ChangeContentOverlay([
          SourceEdit(0, 0, ''),
        ]),
      }).toRequest('0'),
    );
    assertResponseFailure(
      response,
      requestId: '0',
      errorCode: RequestErrorCode.INVALID_OVERLAY_CHANGE,
    );
  }

  Future<void> test_invalidFilePathFormat_notAbsolute() async {
    var response = await handleRequest(
      AnalysisUpdateContentParams({
        'test.dart': AddContentOverlay(''),
      }).toRequest('0'),
    );
    expect(
      response,
      isResponseFailure('0', RequestErrorCode.INVALID_FILE_PATH_FORMAT),
    );
  }

  Future<void> test_invalidFilePathFormat_notNormalized() async {
    var response = await handleRequest(
      AnalysisUpdateContentParams({
        convertPath('/foo/../bar/test.dart'): AddContentOverlay(''),
      }).toRequest('0'),
    );
    expect(
      response,
      isResponseFailure('0', RequestErrorCode.INVALID_FILE_PATH_FORMAT),
    );
  }

  Future<void> test_multiple_contexts() async {
    writePackageConfig(
      getFolder(workspaceRootPath),
      PackageConfigFileBuilder()
        ..add(name: 'aaa', rootPath: '$workspaceRootPath/aaa'),
    );

    var aaa = newFile2('$workspaceRootPath/aaa/lib/aaa.dart', r'''
void f(int _) {}
''');

    var foo = newFile2('$workspaceRootPath/foo/lib/foo.dart', r'''
import 'package:aaa/aaa.dart';
void main() {
  f();
}
''');

    var bar = newFile2('$workspaceRootPath/bar/lib/bar.dart', r'''
import 'package:aaa/aaa.dart';
void main() {
  f();
}
''');

    await setRoots(included: [
      foo.parent.path,
      bar.parent.path,
    ], excluded: []);

    {
      await waitForTasksFinished();
      // Files foo.dart and bar.dart should both have errors, since they both
      // call f() with the wrong number of arguments.
      expect(filesErrors[foo], hasLength(1));
      expect(filesErrors[bar], hasLength(1));
      // Overlay the content of baz.dart to eliminate the errors.
      await handleSuccessfulRequest(
        AnalysisUpdateContentParams(
            {aaa.path: AddContentOverlay('void f() {}')}).toRequest('0'),
      );
    }

    {
      await waitForTasksFinished();
      // The overlay should have been propagated to both contexts, causing both
      // foo.dart and bar.dart to be reanalyzed and found to be free of errors.
      expect(filesErrors[foo], isEmpty);
      expect(filesErrors[bar], isEmpty);
    }
  }

  @failingTest
  Future<void> test_overlay_addPreviouslyImported() async {
    // The list of errors doesn't include errors for '/project/target.dart'.
    var project = newFolder('/project');
    await setRoots(included: [project.path], excluded: []);

    await handleSuccessfulRequest(
      AnalysisUpdateContentParams({
        '/project/main.dart': AddContentOverlay('import "target.dart";'),
      }).toRequest('0'),
    );
    await waitForTasksFinished();
    expect(filesErrors, {
      '/project/main.dart': ["1: Target of URI doesn't exist: 'target.dart'."],
      '/project/target.dart': []
    });

    await handleSuccessfulRequest(
      AnalysisUpdateContentParams({
        '/project/target.dart': AddContentOverlay('import "none.dart";')
      }).toRequest('0'),
    );
    await waitForTasksFinished();
    expect(filesErrors, {
      '/project/main.dart': ['1: Unused import.'],
      '/project/target.dart': ["1: Target of URI doesn't exist: 'none.dart'."],
      '/project/none.dart': []
    });
  }

  Future<void> test_overlayOnly() async {
    var a = newFile2('$testPackageLibPath/a.dart', '');
    var b = getFile('$testPackageLibPath/b.dart');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await waitForTasksFinished();
    expect(filesErrors[a], isEmpty);
    expect(filesErrors[b], isNull);

    // Add `b.dart` overlay, analyzed.
    await handleSuccessfulRequest(
      AnalysisUpdateContentParams({
        b.path: AddContentOverlay(''),
      }).toRequest('0'),
    );
    await waitForTasksFinished();
    expect(filesErrors[a], isEmpty);
    expect(filesErrors[b], isEmpty);

    // Add `b.dart` overlay, analyzed.
    await handleSuccessfulRequest(
      AnalysisUpdateContentParams({
        b.path: RemoveContentOverlay(),
      }).toRequest('0'),
    );
    await waitForTasksFinished();
    expect(filesErrors[a], isEmpty);
    // TODO(scheglov) We should get "flush" notification.
    // expect(filesErrors[b], isNull);
  }

  @failingTest
  Future<void> test_sendNoticesAfterNopChange() async {
    // The errors are empty on the last line.
    addTestFile('');
    await setRoots(included: [workspaceRootPath], excluded: []);
    await waitForTasksFinished();
    // add an overlay
    await handleSuccessfulRequest(
      AnalysisUpdateContentParams({
        testFile.path: AddContentOverlay('main() {} main() {}'),
      }).toRequest('0'),
    );
    await waitForTasksFinished();
    // clear errors and make a no-op change
    filesErrors.clear();
    await handleSuccessfulRequest(
      AnalysisUpdateContentParams({
        testFile.path: ChangeContentOverlay([
          SourceEdit(0, 4, 'main'),
        ]),
      }).toRequest('0'),
    );
    await waitForTasksFinished();
    // errors should have been resent
    expect(filesErrors, isNotEmpty);
  }

  @failingTest
  Future<void> test_sendNoticesAfterNopChange_flushedUnit() async {
    // The list of errors is empty on the last line.
    addTestFile('');
    await setRoots(included: [workspaceRootPath], excluded: []);
    await waitForTasksFinished();
    // add an overlay
    await handleSuccessfulRequest(
      AnalysisUpdateContentParams({
        testFile.path: AddContentOverlay('main() {} main() {}'),
      }).toRequest('0'),
    );
    await waitForTasksFinished();
    // clear errors and make a no-op change
    filesErrors.clear();
    await handleSuccessfulRequest(
      AnalysisUpdateContentParams({
        testFile.path: ChangeContentOverlay([
          SourceEdit(0, 4, 'main'),
        ]),
      }).toRequest('0'),
    );
    await waitForTasksFinished();
    // errors should have been resent
    expect(filesErrors, isNotEmpty);
  }

  Future<void> test_sentToPlugins() async {
    var filePath = convertPath('$testPackageLibPath/a.dart');
    var fileContent = 'import "none.dart";';
    //
    // Add
    //
    await handleSuccessfulRequest(
      AnalysisUpdateContentParams(<String, Object>{
        filePath: AddContentOverlay(fileContent),
      }).toRequest('0'),
    );
    var params = pluginManager.analysisUpdateContentParams!;
    var files = params.files;
    expect(files, hasLength(1));
    var overlay = files[filePath];
    expect(overlay, const TypeMatcher<AddContentOverlay>());
    var addOverlay = overlay as AddContentOverlay;
    expect(addOverlay.content, fileContent);
    //
    // Change
    //
    pluginManager.analysisUpdateContentParams = null;
    await handleSuccessfulRequest(
      AnalysisUpdateContentParams(<String, Object>{
        filePath: ChangeContentOverlay(<SourceEdit>[
          SourceEdit(8, 1, "'"),
          SourceEdit(18, 1, "'"),
        ]),
      }).toRequest('1'),
    );
    params = pluginManager.analysisUpdateContentParams!;
    expect(params, isNotNull);
    files = params.files;
    expect(files, hasLength(1));
    overlay = files[filePath];
    expect(overlay, const TypeMatcher<ChangeContentOverlay>());
    var changeOverlay = overlay as ChangeContentOverlay;
    expect(changeOverlay.edits, hasLength(2));
    //
    // Remove
    //
    pluginManager.analysisUpdateContentParams = null;
    await handleSuccessfulRequest(
      AnalysisUpdateContentParams(<String, Object>{
        filePath: RemoveContentOverlay(),
      }).toRequest('2'),
    );
    params = pluginManager.analysisUpdateContentParams!;
    expect(params, isNotNull);
    files = params.files;
    expect(files, hasLength(1));
    overlay = files[filePath];
    expect(overlay, const TypeMatcher<RemoveContentOverlay>());
  }
}
