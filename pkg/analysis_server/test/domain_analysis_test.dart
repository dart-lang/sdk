// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/domain_analysis.dart';
import 'package:analysis_server/src/server/crash_reporting_attachments.dart';
import 'package:analysis_server/src/utilities/mocks.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'analysis_abstract.dart';
import 'mocks.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisDomainTest);
    defineReflectiveTests(AnalysisDomainHandlerTest);
    defineReflectiveTests(SetSubscriptionsTest);
  });
}

@reflectiveTest
class AnalysisDomainHandlerTest extends AbstractAnalysisTest {
  Future<void> outOfRangeTest(SourceEdit edit) async {
    var helper = AnalysisTestHelper();
    helper.createSingleFileProject('library A;');
    await helper.onAnalysisComplete;
    helper.sendContentChange(AddContentOverlay('library B;'));
    await helper.onAnalysisComplete;
    var contentChange = ChangeContentOverlay([edit]);
    var request = AnalysisUpdateContentParams({helper.testFile: contentChange})
        .toRequest('0');
    var response = helper.handler.handleRequest(request);
    expect(response,
        isResponseFailure('0', RequestErrorCode.INVALID_OVERLAY_CHANGE));
  }

  Future<void> test_setAnalysisRoots_excludedFolder() async {
    newFile('/project/aaa/a.dart', content: '// a');
    newFile('/project/bbb/b.dart', content: '// b');
    var excludedPath = join(projectPath, 'bbb');
    var response = testSetAnalysisRoots([projectPath], [excludedPath]);
    expect(response, isResponseSuccess('0'));
  }

  Future<void> test_setAnalysisRoots_included_newFolder() async {
    newFile('/project/pubspec.yaml', content: 'name: project');
    var file = newFile('/project/bin/test.dart', content: 'main() {}').path;
    var response = testSetAnalysisRoots([projectPath], []);
    var serverRef = server;
    expect(response, isResponseSuccess('0'));
    // verify that unit is resolved eventually
    await server.onAnalysisComplete;
    var resolvedUnit = await serverRef.getResolvedUnit(file);
    expect(resolvedUnit, isNotNull);
  }

  Future<void> test_setAnalysisRoots_included_nonexistentFolder() async {
    var projectA = convertPath('/project_a');
    var projectB = convertPath('/project_b');
    var fileB = newFile('/project_b/b.dart', content: '// b').path;
    var response = testSetAnalysisRoots([projectA, projectB], []);
    var serverRef = server;
    expect(response, isResponseSuccess('0'));
    // Non-existence of /project_a should not prevent files in /project_b
    // from being analyzed.
    await server.onAnalysisComplete;
    var resolvedUnit = await serverRef.getResolvedUnit(fileB);
    expect(resolvedUnit, isNotNull);
  }

  Future<void> test_setAnalysisRoots_included_notAbsolute() async {
    var response = testSetAnalysisRoots(['foo/bar'], []);
    expect(response,
        isResponseFailure('0', RequestErrorCode.INVALID_FILE_PATH_FORMAT));
  }

  Future<void> test_setAnalysisRoots_included_notNormalized() async {
    var response = testSetAnalysisRoots(['/foo/../bar'], []);
    expect(response,
        isResponseFailure('0', RequestErrorCode.INVALID_FILE_PATH_FORMAT));
  }

  Future<void> test_setAnalysisRoots_notAbsolute() async {
    var response = testSetAnalysisRoots([], ['foo/bar']);
    expect(response,
        isResponseFailure('0', RequestErrorCode.INVALID_FILE_PATH_FORMAT));
  }

  Future<void> test_setAnalysisRoots_notNormalized() async {
    var response = testSetAnalysisRoots([], ['/foo/../bar']);
    expect(response,
        isResponseFailure('0', RequestErrorCode.INVALID_FILE_PATH_FORMAT));
  }

  void test_setPriorityFiles_invalid() {
    var request = AnalysisSetPriorityFilesParams(
      [convertPath('/project/lib.dart')],
    ).toRequest('0');
    var response = handler.handleRequest(request);
    expect(response, isResponseSuccess('0'));
  }

  void test_setPriorityFiles_valid() {
    var p1 = convertPath('/p1');
    var p2 = convertPath('/p2');
    var aPath = convertPath('/p1/a.dart');
    var bPath = convertPath('/p2/b.dart');
    var cPath = convertPath('/p2/c.dart');
    newFile(aPath, content: 'library a;');
    newFile(bPath, content: 'library b;');
    newFile(cPath, content: 'library c;');

    var setRootsRequest =
        AnalysisSetAnalysisRootsParams([p1, p2], []).toRequest('0');
    var setRootsResponse = handler.handleRequest(setRootsRequest);
    expect(setRootsResponse, isResponseSuccess('0'));

    void setPriorityFiles(List<String> fileList) {
      var request = AnalysisSetPriorityFilesParams(fileList).toRequest('0');
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

  Future<void> test_updateContent_badType() async {
    var helper = AnalysisTestHelper();
    helper.createSingleFileProject('// empty');
    await helper.onAnalysisComplete;
    var request = Request('0', ANALYSIS_REQUEST_UPDATE_CONTENT, {
      ANALYSIS_REQUEST_UPDATE_CONTENT_FILES: {
        helper.testFile: {
          'type': 'foo',
        }
      }
    });
    var response = helper.handler.handleRequest(request);
    expect(response, isResponseFailure('0'));
  }

  Future<void> test_updateContent_changeOnDisk_duringOverride() async {
    var helper = AnalysisTestHelper();
    helper.createSingleFileProject('library A;');
    await helper.onAnalysisComplete;
    // update code
    helper.sendContentChange(AddContentOverlay('library B;'));
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
    helper.sendContentChange(RemoveContentOverlay());
    // There should be errors now.
    await helper.onAnalysisComplete;
    expect(helper.getTestErrors(), hasLength(1));
  }

  Future<void> test_updateContent_changeOnDisk_normal() async {
    var helper = AnalysisTestHelper();
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

  Future<void> test_updateContent_fullContent() async {
    var helper = AnalysisTestHelper();
    helper.createSingleFileProject('// empty');
    await helper.onAnalysisComplete;
    // no errors initially
    var errors = helper.getTestErrors();
    expect(errors, isEmpty);
    // update code
    helper.sendContentChange(AddContentOverlay('library lib'));
    // wait, there is an error
    await helper.onAnalysisComplete;
    errors = helper.getTestErrors();
    expect(errors, hasLength(1));
  }

  Future<void> test_updateContent_incremental() async {
    var helper = AnalysisTestHelper();
    var initialContent = 'library A;';
    helper.createSingleFileProject(initialContent);
    await helper.onAnalysisComplete;
    // no errors initially
    var errors = helper.getTestErrors();
    expect(errors, isEmpty);
    // Add the file to the cache
    helper.sendContentChange(AddContentOverlay(initialContent));
    // update code
    helper.sendContentChange(ChangeContentOverlay(
        [SourceEdit('library '.length, 'A;'.length, 'lib')]));
    // wait, there is an error
    await helper.onAnalysisComplete;
    errors = helper.getTestErrors();
    expect(errors, hasLength(1));
  }

  Future<void> test_updateContent_outOfRange_beyondEnd() {
    return outOfRangeTest(SourceEdit(6, 6, 'foo'));
  }

  Future<void> test_updateContent_outOfRange_negativeLength() {
    return outOfRangeTest(SourceEdit(3, -1, 'foo'));
  }

  Future<void> test_updateContent_outOfRange_negativeOffset() {
    return outOfRangeTest(SourceEdit(-1, 3, 'foo'));
  }

  void test_updateOptions_invalid() {
    var request = Request('0', ANALYSIS_REQUEST_UPDATE_OPTIONS, {
      ANALYSIS_REQUEST_UPDATE_OPTIONS_OPTIONS: {'not-an-option': true}
    });
    var response = handler.handleRequest(request);
    // Invalid options should be silently ignored.
    expect(response, isResponseSuccess('0'));
  }

  void test_updateOptions_null() {
    // null is allowed as a synonym for {}.
    var request = Request('0', ANALYSIS_REQUEST_UPDATE_OPTIONS,
        {ANALYSIS_REQUEST_UPDATE_OPTIONS_OPTIONS: null});
    var response = handler.handleRequest(request);
    expect(response, isResponseSuccess('0'));
  }

  Response testSetAnalysisRoots(List<String> included, List<String> excluded) {
    var request =
        AnalysisSetAnalysisRootsParams(included, excluded).toRequest('0');
    return handler.handleRequest(request);
  }

  Future<void> xtest_getReachableSources_invalidSource() async {
    // TODO(brianwilkerson) Re-enable this test if we re-enable the
    // analysis.getReachableSources request.
    newFile('/project/a.dart', content: 'import "b.dart";');
    server.setAnalysisRoots('0', ['/project/'], []);

    await server.onAnalysisComplete;

    var request = AnalysisGetReachableSourcesParams('/does/not/exist.dart')
        .toRequest('0');
    var response = handler.handleRequest(request);
    expect(response.error, isNotNull);
    expect(response.error.code,
        RequestErrorCode.GET_REACHABLE_SOURCES_INVALID_FILE);
  }

  Future<void> xtest_getReachableSources_validSources() async {
    // TODO(brianwilkerson) Re-enable this test if we re-enable the
    // analysis.getReachableSources request.
    var fileA = newFile('/project/a.dart', content: 'import "b.dart";').path;
    newFile('/project/b.dart');

    server.setAnalysisRoots('0', ['/project/'], []);

    await server.onAnalysisComplete;

    var request = AnalysisGetReachableSourcesParams(fileA).toRequest('0');
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

  @override
  void processNotification(Notification notification) {
    if (notification.event == ANALYSIS_NOTIFICATION_ERRORS) {
      var decoded = AnalysisErrorsParams.fromNotification(notification);
      filesErrors[decoded.file] = decoded.errors;
    }
  }

  Future<void> test_setRoots_packages() {
    // prepare package
    var pkgFile = newFile('/packages/pkgA/libA.dart', content: '''
library lib_a;
class A {}
''').path;
    newFile('/project/.packages',
        content: 'pkgA:${toUriStr('/packages/pkgA')}');
    addTestFile('''
import 'package:pkgA/libA.dart';
void f(A a) {
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

/// A helper to test 'analysis.*' requests.
class AnalysisTestHelper with ResourceProviderMixin {
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
    serverChannel = MockServerChannel();
    // Create an SDK in the mock file system.
    MockSdk(resourceProvider: resourceProvider);
    server = AnalysisServer(
        serverChannel,
        resourceProvider,
        AnalysisServerOptions(),
        DartSdkManager(convertPath('/sdk')),
        CrashReportingAttachmentsBuilder.empty,
        InstrumentationService.NULL_SERVICE);
    handler = AnalysisDomainHandler(server);
    // listen for notifications
    var notificationStream = serverChannel.notificationController.stream;
    notificationStream.listen((Notification notification) {
      if (notification.event == ANALYSIS_NOTIFICATION_ERRORS) {
        var decoded = AnalysisErrorsParams.fromNotification(notification);
        filesErrors[decoded.file] = decoded.errors;
      }
      if (notification.event == ANALYSIS_NOTIFICATION_HIGHLIGHTS) {
        var params = AnalysisHighlightsParams.fromNotification(notification);
        filesHighlights[params.file] = params.regions;
      }
      if (notification.event == ANALYSIS_NOTIFICATION_NAVIGATION) {
        var params = AnalysisNavigationParams.fromNotification(notification);
        filesNavigation[params.file] = params.regions;
      }
    });
  }

  /// Returns a [Future] that completes when the server's analysis is complete.
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
    var request =
        AnalysisSetSubscriptionsParams(analysisSubscriptions).toRequest('0');
    handleSuccessfulRequest(request);
  }

  void addAnalysisSubscriptionHighlights(String file) {
    addAnalysisSubscription(AnalysisService.HIGHLIGHTS, file);
  }

  void addAnalysisSubscriptionNavigation(String file) {
    addAnalysisSubscription(AnalysisService.NAVIGATION, file);
  }

  /// Creates an empty project `/project`.
  void createEmptyProject() {
    newFolder(projectPath);
    var request =
        AnalysisSetAnalysisRootsParams([projectPath], []).toRequest('0');
    handleSuccessfulRequest(request);
  }

  /// Creates a project with a single Dart file `/project/bin/test.dart` with
  /// the given [code].
  void createSingleFileProject(code) {
    testCode = _getCodeString(code);
    newFolder(projectPath);
    newFile(testFile, content: testCode);
    var request =
        AnalysisSetAnalysisRootsParams([projectPath], []).toRequest('0');
    handleSuccessfulRequest(request);
  }

  /// Returns the offset of [search] in [testCode].
  /// Fails if not found.
  int findOffset(String search) {
    var offset = testCode.indexOf(search);
    expect(offset, isNot(-1));
    return offset;
  }

  /// Returns [AnalysisError]s recorded for the given [file].
  /// May be empty, but not `null`.
  List<AnalysisError> getErrors(String file) {
    var errors = filesErrors[file];
    if (errors != null) {
      return errors;
    }
    return <AnalysisError>[];
  }

  /// Returns highlights recorded for the given [file].
  /// May be empty, but not `null`.
  List<HighlightRegion> getHighlights(String file) {
    var highlights = filesHighlights[file];
    if (highlights != null) {
      return highlights;
    }
    return [];
  }

  /// Returns navigation regions recorded for the given [file].
  /// May be empty, but not `null`.
  List<NavigationRegion> getNavigation(String file) {
    var navigation = filesNavigation[file];
    if (navigation != null) {
      return navigation;
    }
    return [];
  }

  /// Returns [AnalysisError]s recorded for the [testFile].
  /// May be empty, but not `null`.
  List<AnalysisError> getTestErrors() {
    return getErrors(testFile);
  }

  /// Returns highlights recorded for the given [testFile].
  /// May be empty, but not `null`.
  List<HighlightRegion> getTestHighlights() {
    return getHighlights(testFile);
  }

  /// Returns navigation information recorded for the given [testFile].
  /// May be empty, but not `null`.
  List<NavigationRegion> getTestNavigation() {
    return getNavigation(testFile);
  }

  /// Validates that the given [request] is handled successfully.
  void handleSuccessfulRequest(Request request) {
    var response = handler.handleRequest(request);
    expect(response, isResponseSuccess('0'));
  }

  /// Send an `updateContent` request for [testFile].
  void sendContentChange(dynamic contentChange) {
    var request =
        AnalysisUpdateContentParams({testFile: contentChange}).toRequest('0');
    handleSuccessfulRequest(request);
  }

  /// Stops the associated server.
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

  final Completer<void> _resultsAvailable = Completer();

  @override
  void processNotification(Notification notification) {
    if (notification.event == ANALYSIS_NOTIFICATION_HIGHLIGHTS) {
      var params = AnalysisHighlightsParams.fromNotification(notification);
      filesHighlights[params.file] = params.regions;
      _resultsAvailable.complete();
    }
  }

  Future<void> test_afterAnalysis() async {
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

  Future<void> test_afterAnalysis_noSuchFile() async {
    var file = convertPath('/no-such-file.dart');
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

  Future<void> test_afterAnalysis_packageFile_external() async {
    var pkgFile = newFile('/packages/pkgA/lib/libA.dart', content: '''
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

  Future<void> test_afterAnalysis_packageFile_inRoot() async {
    var pkgA = convertPath('/pkgA');
    var pkgB = convertPath('/pkgA');
    var pkgFileA = newFile('$pkgA/lib/libA.dart', content: '''
library lib_a;
class A {}
''').path;
    newFile('$pkgA/lib/libB.dart', content: '''
import 'package:pkgA/libA.dart';
main() {
  new A();
}
''');
    // add 'pkgA' and 'pkgB' as projects
    newFolder(projectPath);
    handleSuccessfulRequest(
        AnalysisSetAnalysisRootsParams([pkgA, pkgB], []).toRequest('0'));
    // wait for analysis, no results initially
    await waitForTasksFinished();
    expect(filesHighlights[pkgFileA], isNull);
    // subscribe
    addAnalysisSubscription(AnalysisService.HIGHLIGHTS, pkgFileA);
    await _resultsAvailable.future;
    // there are results
    expect(filesHighlights[pkgFileA], isNotEmpty);
  }

  Future<void> test_afterAnalysis_packageFile_notUsed() async {
    var pkgFile = newFile('/packages/pkgA/lib/libA.dart', content: '''
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

  Future<void> test_afterAnalysis_sdkFile() async {
    var file = convertPath('/sdk/lib/core/core.dart');
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

  Future<void> test_beforeAnalysis() async {
    addTestFile('int V = 42;');
    createProject();
    // subscribe
    addAnalysisSubscription(AnalysisService.HIGHLIGHTS, testFile);
    // wait for analysis
    await waitForTasksFinished();
    expect(filesHighlights[testFile], isNotEmpty);
  }

  Future<void> test_sentToPlugins() async {
    addTestFile('int V = 42;');
    createProject();
    // subscribe
    addAnalysisSubscription(AnalysisService.HIGHLIGHTS, testFile);
    // wait for analysis
    await waitForTasksFinished();
    var params = pluginManager.analysisSetSubscriptionsParams;
    expect(params, isNotNull);
    var subscriptions = params.subscriptions;
    expect(subscriptions, hasLength(1));
    var files = subscriptions[plugin.AnalysisService.HIGHLIGHTS];
    expect(files, [testFile]);
  }
}
