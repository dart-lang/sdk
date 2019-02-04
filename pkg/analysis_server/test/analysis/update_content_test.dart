// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_abstract.dart';
import '../mocks.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UpdateContentTest);
  });
}

@reflectiveTest
class UpdateContentTest extends AbstractAnalysisTest {
  Map<String, List<String>> filesErrors = {};
  int serverErrorCount = 0;
  int navigationCount = 0;

  @override
  void processNotification(Notification notification) {
    if (notification.event == ANALYSIS_NOTIFICATION_ERRORS) {
      var decoded = new AnalysisErrorsParams.fromNotification(notification);
      String _format(AnalysisError e) =>
          "${e.location.startLine}: ${e.message}";
      filesErrors[decoded.file] = decoded.errors.map(_format).toList();
    }
    if (notification.event == ANALYSIS_NOTIFICATION_NAVIGATION) {
      navigationCount++;
    }
    if (notification.event == SERVER_NOTIFICATION_ERROR) {
      serverErrorCount++;
    }
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

  test_invalidFilePathFormat_notAbsolute() async {
    var request = new AnalysisUpdateContentParams(
      {'test.dart': AddContentOverlay('')},
    ).toRequest('0');
    var response = await waitResponse(request);
    expect(
      response,
      isResponseFailure('0', RequestErrorCode.INVALID_FILE_PATH_FORMAT),
    );
  }

  test_invalidFilePathFormat_notNormalized() async {
    var request = new AnalysisUpdateContentParams(
      {convertPath('/foo/../bar/test.dart'): AddContentOverlay('')},
    ).toRequest('0');
    var response = await waitResponse(request);
    expect(
      response,
      isResponseFailure('0', RequestErrorCode.INVALID_FILE_PATH_FORMAT),
    );
  }

  test_multiple_contexts() async {
    String project1path = convertPath('/project1');
    String project2path = convertPath('/project2');
    String fooPath = newFile('/project1/foo.dart', content: '''
library foo;
import '../project2/baz.dart';
main() { f(); }''').path;
    String barPath = newFile('/project2/bar.dart', content: '''
library bar;
import 'baz.dart';
main() { f(); }''').path;
    String bazPath = newFile('/project2/baz.dart', content: '''
library baz;
f(int i) {}
''').path;
    Request request =
        new AnalysisSetAnalysisRootsParams([project1path, project2path], [])
            .toRequest('0');
    handleSuccessfulRequest(request);
    {
      await server.onAnalysisComplete;
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
    }
    {
      await server.onAnalysisComplete;
      // The overlay should have been propagated to both contexts, causing both
      // foo.dart and bar.dart to be reanalyzed and found to be free of errors.
      expect(filesErrors[fooPath], isEmpty);
      expect(filesErrors[barPath], isEmpty);
    }
  }

  @failingTest
  test_overlay_addPreviouslyImported() async {
    // The list of errors doesn't include errors for '/project/target.dart'.
    Folder project = newFolder('/project');
    handleSuccessfulRequest(
        new AnalysisSetAnalysisRootsParams([project.path], []).toRequest('0'));

    server.updateContent('1',
        {'/project/main.dart': new AddContentOverlay('import "target.dart";')});
    await server.onAnalysisComplete;
    expect(filesErrors, {
      '/project/main.dart': ["1: Target of URI doesn't exist: 'target.dart'."],
      '/project/target.dart': []
    });

    server.updateContent('1',
        {'/project/target.dart': new AddContentOverlay('import "none.dart";')});
    await server.onAnalysisComplete;
    expect(filesErrors, {
      '/project/main.dart': ["1: Unused import."],
      '/project/target.dart': ["1: Target of URI doesn't exist: 'none.dart'."],
      '/project/none.dart': []
    });
  }

  test_overlayOnly() async {
    var filePath1 = convertPath('/User/project1/test.dart');
    var filePath2 = convertPath('/User/project2/test.dart');
    var folderPath1 = newFolder('/User/project1').path;
    var folderPath2 = newFolder('/User/project2').path;

    handleSuccessfulRequest(new AnalysisSetAnalysisRootsParams(
      [folderPath1, folderPath2],
      [],
    ).toRequest('0'));

    // exactly 2 contexts
    expect(server.driverMap, hasLength(2));
    AnalysisDriver driver1 = server.getAnalysisDriver(filePath1);
    AnalysisDriver driver2 = server.getAnalysisDriver(filePath2);

    // no sources
    expect(_getUserSources(driver1), isEmpty);
    expect(_getUserSources(driver2), isEmpty);

    // add an overlay - new Source in context1
    server.updateContent('1', {filePath1: new AddContentOverlay('')});
    expect(_getUserSources(driver1), [filePath1]);
    expect(_getUserSources(driver2), isEmpty);

    // remove the overlay - no sources
    server.updateContent('2', {filePath1: new RemoveContentOverlay()});

    // The file isn't removed from the list of added sources.
//    expect(_getUserSources(driver1), isEmpty);
    expect(_getUserSources(driver2), isEmpty);
  }

  @failingTest
  test_sendNoticesAfterNopChange() async {
    // The errors are empty on the last line.
    createProject();
    addTestFile('');
    await server.onAnalysisComplete;
    // add an overlay
    server.updateContent(
        '1', {testFile: new AddContentOverlay('main() {} main() {}')});
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

  @failingTest
  test_sendNoticesAfterNopChange_flushedUnit() async {
    // The list of errors is empty on the last line.
    createProject();
    addTestFile('');
    await server.onAnalysisComplete;
    // add an overlay
    server.updateContent(
        '1', {testFile: new AddContentOverlay('main() {} main() {}')});
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

  test_sentToPlugins() {
    String filePath = convertPath('/project/target.dart');
    String fileContent = 'import "none.dart";';
    //
    // Add
    //
    handleSuccessfulRequest(new AnalysisUpdateContentParams(
            <String, dynamic>{filePath: new AddContentOverlay(fileContent)})
        .toRequest('0'));
    plugin.AnalysisUpdateContentParams params =
        pluginManager.analysisUpdateContentParams;
    expect(params, isNotNull);
    Map<String, dynamic> files = params.files;
    expect(files, hasLength(1));
    Object overlay = files[filePath];
    expect(overlay, const TypeMatcher<plugin.AddContentOverlay>());
    plugin.AddContentOverlay addOverlay = overlay;
    expect(addOverlay.content, fileContent);
    //
    // Change
    //
    pluginManager.analysisUpdateContentParams = null;
    handleSuccessfulRequest(new AnalysisUpdateContentParams(<String, dynamic>{
      filePath: new ChangeContentOverlay(
          <SourceEdit>[new SourceEdit(8, 1, "'"), new SourceEdit(18, 1, "'")])
    }).toRequest('1'));
    params = pluginManager.analysisUpdateContentParams;
    expect(params, isNotNull);
    files = params.files;
    expect(files, hasLength(1));
    overlay = files[filePath];
    expect(overlay, const TypeMatcher<plugin.ChangeContentOverlay>());
    plugin.ChangeContentOverlay changeOverlay = overlay;
    expect(changeOverlay.edits, hasLength(2));
    //
    // Remove
    //
    pluginManager.analysisUpdateContentParams = null;
    handleSuccessfulRequest(new AnalysisUpdateContentParams(
            <String, dynamic>{filePath: new RemoveContentOverlay()})
        .toRequest('2'));
    params = pluginManager.analysisUpdateContentParams;
    expect(params, isNotNull);
    files = params.files;
    expect(files, hasLength(1));
    overlay = files[filePath];
    expect(overlay, const TypeMatcher<plugin.RemoveContentOverlay>());
  }

//  CompilationUnit _getTestUnit() {
//    ContextSourcePair pair = server.getContextSourcePair(testFile);
//    AnalysisContext context = pair.context;
//    Source source = pair.source;
//    return context.getResolvedCompilationUnit2(source, source);
//  }

  List<String> _getUserSources(AnalysisDriver driver) {
    List<String> sources = <String>[];
    driver.addedFiles.forEach((path) {
      if (path.startsWith(convertPath('/User/'))) {
        sources.add(path);
      }
    });
    return sources;
  }
}
