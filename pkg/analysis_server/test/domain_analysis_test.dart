// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/domain_analysis.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:plugin/manager.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'analysis_abstract.dart';
import 'mock_sdk.dart';
import 'mocks.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisDomainTest);
    defineReflectiveTests(AnalysisDomainHandlerTest);
    defineReflectiveTests(SetSubscriptionsTest);
  });
}

@reflectiveTest
class AnalysisDomainHandlerTest extends AbstractAnalysisTest {
  Future outOfRangeTest(SourceEdit edit) async {
    AnalysisTestHelper helper = new AnalysisTestHelper();
    helper.createSingleFileProject('library A;');
    await helper.onAnalysisComplete;
    helper.sendContentChange(new AddContentOverlay('library B;'));
    await helper.onAnalysisComplete;
    ChangeContentOverlay contentChange = new ChangeContentOverlay([edit]);
    Request request =
        new AnalysisUpdateContentParams({helper.testFile: contentChange})
            .toRequest('0');
    Response response = helper.handler.handleRequest(request);
    expect(response,
        isResponseFailure('0', RequestErrorCode.INVALID_OVERLAY_CHANGE));
  }

  test_setAnalysisRoots_excludedFolder() async {
    newFile('/project/aaa/a.dart', content: '// a');
    newFile('/project/bbb/b.dart', content: '// b');
    var excludedPath = join(projectPath, 'bbb');
    var response = testSetAnalysisRoots([projectPath], [excludedPath]);
    expect(response, isResponseSuccess('0'));
  }

  test_setAnalysisRoots_included_newFolder() async {
    newFile('/project/pubspec.yaml', content: 'name: project');
    String file = newFile('/project/bin/test.dart', content: 'main() {}').path;
    var response = testSetAnalysisRoots([projectPath], []);
    var serverRef = server;
    expect(response, isResponseSuccess('0'));
    // verify that unit is resolved eventually
    await server.onAnalysisComplete;
    var unit = await serverRef.getResolvedCompilationUnit(file);
    expect(unit, isNotNull);
  }

  test_setAnalysisRoots_included_nonexistentFolder() async {
    String projectA = convertPath('/project_a');
    String projectB = convertPath('/project_b');
    String fileB = newFile('/project_b/b.dart', content: '// b').path;
    var response = testSetAnalysisRoots([projectA, projectB], []);
    var serverRef = server;
    expect(response, isResponseSuccess('0'));
    // Non-existence of /project_a should not prevent files in /project_b
    // from being analyzed.
    await server.onAnalysisComplete;
    var unit = await serverRef.getResolvedCompilationUnit(fileB);
    expect(unit, isNotNull);
  }

  test_setAnalysisRoots_included_notAbsolute() async {
    var response = testSetAnalysisRoots(['foo/bar'], []);
    expect(response,
        isResponseFailure('0', RequestErrorCode.INVALID_FILE_PATH_FORMAT));
  }

  test_setAnalysisRoots_included_notNormalized() async {
    var response = testSetAnalysisRoots(['/foo/../bar'], []);
    expect(response,
        isResponseFailure('0', RequestErrorCode.INVALID_FILE_PATH_FORMAT));
  }

  test_setAnalysisRoots_notAbsolute() async {
    var response = testSetAnalysisRoots([], ['foo/bar']);
    expect(response,
        isResponseFailure('0', RequestErrorCode.INVALID_FILE_PATH_FORMAT));
  }

  test_setAnalysisRoots_notNormalized() async {
    var response = testSetAnalysisRoots([], ['/foo/../bar']);
    expect(response,
        isResponseFailure('0', RequestErrorCode.INVALID_FILE_PATH_FORMAT));
  }

  test_setPriorityFiles_invalid() {
    var request = new AnalysisSetPriorityFilesParams(['/project/lib.dart'])
        .toRequest('0');
    var response = handler.handleRequest(request);
    expect(response, isResponseSuccess('0'));
  }

  test_setPriorityFiles_valid() {
    var p1 = convertPath('/p1');
    var p2 = convertPath('/p2');
    var aPath = convertPath('/p1/a.dart');
    var bPath = convertPath('/p2/b.dart');
    var cPath = convertPath('/p2/c.dart');
    newFile(aPath, content: 'library a;');
    newFile(bPath, content: 'library b;');
    newFile(cPath, content: 'library c;');

    var setRootsRequest =
        new AnalysisSetAnalysisRootsParams([p1, p2], []).toRequest('0');
    var setRootsResponse = handler.handleRequest(setRootsRequest);
    expect(setRootsResponse, isResponseSuccess('0'));

    void setPriorityFiles(List<String> fileList) {
      var request = new AnalysisSetPriorityFilesParams(fileList).toRequest('0');
      var response = handler.handleRequest(request);
      expect(response, isResponseSuccess('0'));
      // TODO(brianwilkerson) Enable the line below after getPriorityFiles
      // has been implemented.
      // expect(server.getPriorityFiles(), unorderedEquals(fileList));
    }

    setPriorityFiles([aPath, bPath]);
    setPriorityFiles([bPath, cPath]);
    setPriorityFiles([]);
  }

  test_updateContent_badType() async {
    AnalysisTestHelper helper = new AnalysisTestHelper();
    helper.createSingleFileProject('// empty');
    await helper.onAnalysisComplete;
    Request request = new Request('0', ANALYSIS_REQUEST_UPDATE_CONTENT, {
      ANALYSIS_REQUEST_UPDATE_CONTENT_FILES: {
        helper.testFile: {
          'type': 'foo',
        }
      }
    });
    Response response = helper.handler.handleRequest(request);
    expect(response, isResponseFailure('0'));
  }

  test_updateContent_changeOnDisk_duringOverride() async {
    AnalysisTestHelper helper = new AnalysisTestHelper();
    helper.createSingleFileProject('library A;');
    await helper.onAnalysisComplete;
    // update code
    helper.sendContentChange(new AddContentOverlay('library B;'));
    // There should be no errors
    await helper.onAnalysisComplete;
    expect(helper.getTestErrors(), hasLength(0));
    // Change file on disk, adding a syntax error.
    helper.resourceProvider.modifyFile(helper.testFile, 'library lib');
    // There should still be no errors (file should not have been reread).
    await helper.onAnalysisComplete;
    expect(helper.getTestErrors(), hasLength(0));
    // Send a content change with a null content param--file should be
    // reread from disk.
    helper.sendContentChange(new RemoveContentOverlay());
    // There should be errors now.
    await helper.onAnalysisComplete;
    expect(helper.getTestErrors(), hasLength(1));
  }

  test_updateContent_changeOnDisk_normal() async {
    AnalysisTestHelper helper = new AnalysisTestHelper();
    helper.createSingleFileProject('library A;');
    await helper.onAnalysisComplete;
    // There should be no errors
    expect(helper.getTestErrors(), hasLength(0));
    // Change file on disk, adding a syntax error.
    helper.resourceProvider.modifyFile(helper.testFile, 'library lib');
    // There should be errors now.
    await pumpEventQueue();
    await helper.onAnalysisComplete;
    expect(helper.getTestErrors(), hasLength(1));
  }

  test_updateContent_fullContent() async {
    AnalysisTestHelper helper = new AnalysisTestHelper();
    helper.createSingleFileProject('// empty');
    await helper.onAnalysisComplete;
    // no errors initially
    List<AnalysisError> errors = helper.getTestErrors();
    expect(errors, isEmpty);
    // update code
    helper.sendContentChange(new AddContentOverlay('library lib'));
    // wait, there is an error
    await helper.onAnalysisComplete;
    errors = helper.getTestErrors();
    expect(errors, hasLength(1));
  }

  test_updateContent_incremental() async {
    AnalysisTestHelper helper = new AnalysisTestHelper();
    String initialContent = 'library A;';
    helper.createSingleFileProject(initialContent);
    await helper.onAnalysisComplete;
    // no errors initially
    List<AnalysisError> errors = helper.getTestErrors();
    expect(errors, isEmpty);
    // Add the file to the cache
    helper.sendContentChange(new AddContentOverlay(initialContent));
    // update code
    helper.sendContentChange(new ChangeContentOverlay(
        [new SourceEdit('library '.length, 'A;'.length, 'lib')]));
    // wait, there is an error
    await helper.onAnalysisComplete;
    errors = helper.getTestErrors();
    expect(errors, hasLength(1));
  }

  test_updateContent_outOfRange_beyondEnd() {
    return outOfRangeTest(new SourceEdit(6, 6, 'foo'));
  }

  test_updateContent_outOfRange_negativeLength() {
    return outOfRangeTest(new SourceEdit(3, -1, 'foo'));
  }

  test_updateContent_outOfRange_negativeOffset() {
    return outOfRangeTest(new SourceEdit(-1, 3, 'foo'));
  }

  test_updateOptions_invalid() {
    var request = new Request('0', ANALYSIS_REQUEST_UPDATE_OPTIONS, {
      ANALYSIS_REQUEST_UPDATE_OPTIONS_OPTIONS: {'not-an-option': true}
    });
    var response = handler.handleRequest(request);
    // Invalid options should be silently ignored.
    expect(response, isResponseSuccess('0'));
  }

  test_updateOptions_null() {
    // null is allowed as a synonym for {}.
    var request = new Request('0', ANALYSIS_REQUEST_UPDATE_OPTIONS,
        {ANALYSIS_REQUEST_UPDATE_OPTIONS_OPTIONS: null});
    var response = handler.handleRequest(request);
    expect(response, isResponseSuccess('0'));
  }

  Response testSetAnalysisRoots(List<String> included, List<String> excluded) {
    Request request =
        new AnalysisSetAnalysisRootsParams(included, excluded).toRequest('0');
    return handler.handleRequest(request);
  }

  xtest_getReachableSources_invalidSource() async {
    // TODO(brianwilkerson) Re-enable this test if we re-enable the
    // analysis.getReachableSources request.
    newFile('/project/a.dart', content: 'import "b.dart";');
    server.setAnalysisRoots('0', ['/project/'], [], {});

    await server.onAnalysisComplete;

    var request = new AnalysisGetReachableSourcesParams('/does/not/exist.dart')
        .toRequest('0');
    var response = handler.handleRequest(request);
    expect(response.error, isNotNull);
    expect(response.error.code,
        RequestErrorCode.GET_REACHABLE_SOURCES_INVALID_FILE);
  }

  xtest_getReachableSources_validSources() async {
    // TODO(brianwilkerson) Re-enable this test if we re-enable the
    // analysis.getReachableSources request.
    String fileA = newFile('/project/a.dart', content: 'import "b.dart";').path;
    newFile('/project/b.dart');

    server.setAnalysisRoots('0', ['/project/'], [], {});

    await server.onAnalysisComplete;

    var request = new AnalysisGetReachableSourcesParams(fileA).toRequest('0');
    var response = handler.handleRequest(request);

    Map json = response.toJson()[Response.RESULT];

    // Sanity checks.
    expect(json['sources'], hasLength(6));
    expect(json['sources']['file:///project/a.dart'],
        unorderedEquals(['dart:core', 'file:///project/b.dart']));
    expect(json['sources']['file:///project/b.dart'], ['dart:core']);
  }
}

@reflectiveTest
class AnalysisDomainTest extends AbstractAnalysisTest {
  Map<String, List<AnalysisError>> filesErrors = {};

  void processNotification(Notification notification) {
    if (notification.event == ANALYSIS_NOTIFICATION_ERRORS) {
      var decoded = new AnalysisErrorsParams.fromNotification(notification);
      filesErrors[decoded.file] = decoded.errors;
    }
  }

  test_setRoots_packages() {
    // prepare package
    String pkgFile = newFile('/packages/pkgA/libA.dart', content: '''
library lib_a;
class A {}
''').path;
    newFile('/project/.packages', content: 'pkgA:file:///packages/pkgA');
    addTestFile('''
import 'package:pkgA/libA.dart';
main(A a) {
}
''');
    // create project and wait for analysis
    createProject();
    return waitForTasksFinished().then((_) {
      // if 'package:pkgA/libA.dart' was resolved, then there are no errors
      expect(filesErrors[testFile], isEmpty);
      // errors are not reported for packages
      expect(filesErrors[pkgFile], isNull);
    });
  }
}

/**
 * A helper to test 'analysis.*' requests.
 */
class AnalysisTestHelper extends Object with ResourceProviderMixin {
  MockServerChannel serverChannel;
  AnalysisServer server;
  AnalysisDomainHandler handler;

  Map<AnalysisService, List<String>> analysisSubscriptions = {};

  Map<String, List<AnalysisError>> filesErrors = {};
  Map<String, List<HighlightRegion>> filesHighlights = {};
  Map<String, List<NavigationRegion>> filesNavigation = {};

  String projectPath;
  String testFile;
  String testCode;

  AnalysisTestHelper() {
    projectPath = convertPath('/project');
    testFile = convertPath('/project/bin/test.dart');
    processRequiredPlugins();
    serverChannel = new MockServerChannel();
    // Create an SDK in the mock file system.
    new MockSdk(resourceProvider: resourceProvider);
    server = new AnalysisServer(
        serverChannel,
        resourceProvider,
        new MockPackageMapProvider(),
        new AnalysisServerOptions()..previewDart2 = true,
        new DartSdkManager(convertPath('/'), false),
        InstrumentationService.NULL_SERVICE);
    handler = new AnalysisDomainHandler(server);
    // listen for notifications
    Stream<Notification> notificationStream =
        serverChannel.notificationController.stream;
    notificationStream.listen((Notification notification) {
      if (notification.event == ANALYSIS_NOTIFICATION_ERRORS) {
        var decoded = new AnalysisErrorsParams.fromNotification(notification);
        filesErrors[decoded.file] = decoded.errors;
      }
      if (notification.event == ANALYSIS_NOTIFICATION_HIGHLIGHTS) {
        var params =
            new AnalysisHighlightsParams.fromNotification(notification);
        filesHighlights[params.file] = params.regions;
      }
      if (notification.event == ANALYSIS_NOTIFICATION_NAVIGATION) {
        var params =
            new AnalysisNavigationParams.fromNotification(notification);
        filesNavigation[params.file] = params.regions;
      }
    });
  }

  /**
   * Returns a [Future] that completes when the server's analysis is complete.
   */
  Future get onAnalysisComplete {
    return server.onAnalysisComplete;
  }

  void addAnalysisSubscription(AnalysisService service, String file) {
    // add file to subscription
    var files = analysisSubscriptions[service];
    if (files == null) {
      files = <String>[];
      analysisSubscriptions[service] = files;
    }
    files.add(file);
    // set subscriptions
    Request request = new AnalysisSetSubscriptionsParams(analysisSubscriptions)
        .toRequest('0');
    handleSuccessfulRequest(request);
  }

  void addAnalysisSubscriptionHighlights(String file) {
    addAnalysisSubscription(AnalysisService.HIGHLIGHTS, file);
  }

  void addAnalysisSubscriptionNavigation(String file) {
    addAnalysisSubscription(AnalysisService.NAVIGATION, file);
  }

  /**
   * Creates an empty project `/project`.
   */
  void createEmptyProject() {
    newFolder(projectPath);
    Request request =
        new AnalysisSetAnalysisRootsParams([projectPath], []).toRequest('0');
    handleSuccessfulRequest(request);
  }

  /**
   * Creates a project with a single Dart file `/project/bin/test.dart` with
   * the given [code].
   */
  void createSingleFileProject(code) {
    this.testCode = _getCodeString(code);
    newFolder(projectPath);
    newFile(testFile, content: testCode);
    Request request =
        new AnalysisSetAnalysisRootsParams([projectPath], []).toRequest('0');
    handleSuccessfulRequest(request);
  }

  /**
   * Returns the offset of [search] in [testCode].
   * Fails if not found.
   */
  int findOffset(String search) {
    int offset = testCode.indexOf(search);
    expect(offset, isNot(-1));
    return offset;
  }

  /**
   * Returns [AnalysisError]s recorded for the given [file].
   * May be empty, but not `null`.
   */
  List<AnalysisError> getErrors(String file) {
    List<AnalysisError> errors = filesErrors[file];
    if (errors != null) {
      return errors;
    }
    return <AnalysisError>[];
  }

  /**
   * Returns highlights recorded for the given [file].
   * May be empty, but not `null`.
   */
  List<HighlightRegion> getHighlights(String file) {
    List<HighlightRegion> highlights = filesHighlights[file];
    if (highlights != null) {
      return highlights;
    }
    return [];
  }

  /**
   * Returns navigation regions recorded for the given [file].
   * May be empty, but not `null`.
   */
  List<NavigationRegion> getNavigation(String file) {
    List<NavigationRegion> navigation = filesNavigation[file];
    if (navigation != null) {
      return navigation;
    }
    return [];
  }

  /**
   * Returns [AnalysisError]s recorded for the [testFile].
   * May be empty, but not `null`.
   */
  List<AnalysisError> getTestErrors() {
    return getErrors(testFile);
  }

  /**
   * Returns highlights recorded for the given [testFile].
   * May be empty, but not `null`.
   */
  List<HighlightRegion> getTestHighlights() {
    return getHighlights(testFile);
  }

  /**
   * Returns navigation information recorded for the given [testFile].
   * May be empty, but not `null`.
   */
  List<NavigationRegion> getTestNavigation() {
    return getNavigation(testFile);
  }

  /**
   * Validates that the given [request] is handled successfully.
   */
  void handleSuccessfulRequest(Request request) {
    Response response = handler.handleRequest(request);
    expect(response, isResponseSuccess('0'));
  }

  void processRequiredPlugins() {
    ExtensionManager manager = new ExtensionManager();
    manager.processPlugins(AnalysisEngine.instance.requiredPlugins);
  }

  /**
   * Send an `updateContent` request for [testFile].
   */
  void sendContentChange(dynamic contentChange) {
    Request request = new AnalysisUpdateContentParams({testFile: contentChange})
        .toRequest('0');
    handleSuccessfulRequest(request);
  }

  /**
   * Stops the associated server.
   */
  void stopServer() {
    server.done();
  }

  static String _getCodeString(code) {
    if (code is List<String>) {
      code = code.join('\n');
    }
    return code as String;
  }
}

@reflectiveTest
class SetSubscriptionsTest extends AbstractAnalysisTest {
  Map<String, List<HighlightRegion>> filesHighlights = {};

  Completer _resultsAvailable = new Completer();

  void processNotification(Notification notification) {
    if (notification.event == ANALYSIS_NOTIFICATION_HIGHLIGHTS) {
      var params = new AnalysisHighlightsParams.fromNotification(notification);
      filesHighlights[params.file] = params.regions;
      _resultsAvailable.complete(null);
    }
  }

  test_afterAnalysis() async {
    addTestFile('int V = 42;');
    createProject();
    // wait for analysis, no results initially
    await waitForTasksFinished();
    expect(filesHighlights[testFile], isNull);
    // subscribe
    addAnalysisSubscription(AnalysisService.HIGHLIGHTS, testFile);
    await _resultsAvailable.future;
    // there are results
    expect(filesHighlights[testFile], isNotEmpty);
  }

  test_afterAnalysis_noSuchFile() async {
    String file = convertPath('/no-such-file.dart');
    addTestFile('// no matter');
    createProject();
    // wait for analysis, no results initially
    await waitForTasksFinished();
    expect(filesHighlights[testFile], isNull);
    // subscribe
    addAnalysisSubscription(AnalysisService.HIGHLIGHTS, file);
    await _resultsAvailable.future;
    // there are results
    expect(filesHighlights[file], isEmpty);
  }

  test_afterAnalysis_packageFile_external() async {
    String pkgFile = newFile('/packages/pkgA/lib/libA.dart', content: '''
library lib_a;
class A {}
''').path;
    newFile('/project/.packages', content: 'pkgA:file:///packages/pkgA/lib');
    //
    addTestFile('''
import 'package:pkgA/libA.dart';
main() {
  new A();
}
''');
    createProject();
    // wait for analysis, no results initially
    await waitForTasksFinished();
    expect(filesHighlights[pkgFile], isNull);
    // subscribe
    addAnalysisSubscription(AnalysisService.HIGHLIGHTS, pkgFile);
    await _resultsAvailable.future;
    // there are results
    expect(filesHighlights[pkgFile], isNotEmpty);
  }

  test_afterAnalysis_packageFile_inRoot() async {
    String pkgA = convertPath('/pkgA');
    String pkgB = convertPath('/pkgA');
    String pkgFileA = newFile('$pkgA/lib/libA.dart', content: '''
library lib_a;
class A {}
''').path;
    newFile('$pkgA/lib/libB.dart', content: '''
import 'package:pkgA/libA.dart';
main() {
  new A();
}
''');
    packageMapProvider.packageMap = {
      'pkgA': [newFolder('$pkgA/lib'), newFolder('$pkgB/lib')]
    };
    // add 'pkgA' and 'pkgB' as projects
    newFolder(projectPath);
    handleSuccessfulRequest(
        new AnalysisSetAnalysisRootsParams([pkgA, pkgB], []).toRequest('0'));
    // wait for analysis, no results initially
    await waitForTasksFinished();
    expect(filesHighlights[pkgFileA], isNull);
    // subscribe
    addAnalysisSubscription(AnalysisService.HIGHLIGHTS, pkgFileA);
    await _resultsAvailable.future;
    // there are results
    expect(filesHighlights[pkgFileA], isNotEmpty);
  }

  test_afterAnalysis_packageFile_notUsed() async {
    String pkgFile = newFile('/packages/pkgA/lib/libA.dart', content: '''
library lib_a;
class A {}
''').path;
    newFile('/project/.packages', content: 'pkgA:/packages/pkgA/lib');
    //
    addTestFile('// no "pkgA" reference');
    createProject();
    // wait for analysis, no results initially
    await waitForTasksFinished();
    expect(filesHighlights[pkgFile], isNull);
    // make it a priority file, so make analyzable
    server.setPriorityFiles('0', [pkgFile]);
    // subscribe
    addAnalysisSubscription(AnalysisService.HIGHLIGHTS, pkgFile);
    await _resultsAvailable.future;
    // there are results
    expect(filesHighlights[pkgFile], isNotEmpty);
  }

  test_afterAnalysis_sdkFile() async {
    String file = convertPath('/lib/core/core.dart');
    addTestFile('// no matter');
    createProject();
    // wait for analysis, no results initially
    await waitForTasksFinished();
    expect(filesHighlights[file], isNull);
    // subscribe
    addAnalysisSubscription(AnalysisService.HIGHLIGHTS, file);
    await _resultsAvailable.future;
    // there are results
    expect(filesHighlights[file], isNotEmpty);
  }

  test_beforeAnalysis() async {
    addTestFile('int V = 42;');
    createProject();
    // subscribe
    addAnalysisSubscription(AnalysisService.HIGHLIGHTS, testFile);
    // wait for analysis
    await waitForTasksFinished();
    expect(filesHighlights[testFile], isNotEmpty);
  }

  test_sentToPlugins() async {
    addTestFile('int V = 42;');
    createProject();
    // subscribe
    addAnalysisSubscription(AnalysisService.HIGHLIGHTS, testFile);
    // wait for analysis
    await waitForTasksFinished();
    plugin.AnalysisSetSubscriptionsParams params =
        pluginManager.analysisSetSubscriptionsParams;
    expect(params, isNotNull);
    Map<plugin.AnalysisService, List<String>> subscriptions =
        params.subscriptions;
    expect(subscriptions, hasLength(1));
    List<String> files = subscriptions[plugin.AnalysisService.HIGHLIGHTS];
    expect(files, [testFile]);
  }
}
