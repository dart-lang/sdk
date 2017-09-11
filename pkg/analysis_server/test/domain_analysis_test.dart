// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/domain_analysis.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
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
    defineReflectiveTests(SetSubscriptionsTest);
  });

  MockServerChannel serverChannel;
  MemoryResourceProvider resourceProvider;
  AnalysisServer server;
  AnalysisDomainHandler handler;

  void processRequiredPlugins() {
    ExtensionManager manager = new ExtensionManager();
    manager.processPlugins(AnalysisEngine.instance.requiredPlugins);
  }

  setUp(() {
    serverChannel = new MockServerChannel();
    resourceProvider = new MemoryResourceProvider();
    processRequiredPlugins();
    // Create an SDK in the mock file system.
    new MockSdk(resourceProvider: resourceProvider);
    server = new AnalysisServer(
        serverChannel,
        resourceProvider,
        new MockPackageMapProvider(),
        new AnalysisServerOptions(),
        new DartSdkManager('/', false),
        InstrumentationService.NULL_SERVICE);
    handler = new AnalysisDomainHandler(server);
  });

  group('updateContent', testUpdateContent);

  group('AnalysisDomainHandler', () {
    // TODO(brianwilkerson) Re-enable these tests if we re-enable the
    // analysis.getReachableSources request.
//    group('getReachableSources', () {
//      test('valid sources', () async {
//        String fileA = '/project/a.dart';
//        String fileB = '/project/b.dart';
//        resourceProvider.newFile(fileA, 'import "b.dart";');
//        resourceProvider.newFile(fileB, '');
//
//        server.setAnalysisRoots('0', ['/project/'], [], {});
//
//        await server.onAnalysisComplete;
//
//        var request =
//            new AnalysisGetReachableSourcesParams(fileA).toRequest('0');
//        var response = handler.handleRequest(request);
//
//        Map json = response.toJson()[Response.RESULT];
//
//        // Sanity checks.
//        expect(json['sources'], hasLength(6));
//        expect(json['sources']['file:///project/a.dart'],
//            unorderedEquals(['dart:core', 'file:///project/b.dart']));
//        expect(json['sources']['file:///project/b.dart'], ['dart:core']);
//      });
//
//      test('invalid source', () async {
//        resourceProvider.newFile('/project/a.dart', 'import "b.dart";');
//        server.setAnalysisRoots('0', ['/project/'], [], {});
//
//        await server.onAnalysisComplete;
//
//        var request =
//            new AnalysisGetReachableSourcesParams('/does/not/exist.dart')
//                .toRequest('0');
//        var response = handler.handleRequest(request);
//        expect(response.error, isNotNull);
//        expect(response.error.code,
//            RequestErrorCode.GET_REACHABLE_SOURCES_INVALID_FILE);
//      });
//    });

    group('setAnalysisRoots', () {
      Response testSetAnalysisRoots(
          List<String> included, List<String> excluded) {
        Request request = new AnalysisSetAnalysisRootsParams(included, excluded)
            .toRequest('0');
        return handler.handleRequest(request);
      }

      group('excluded', () {
        test('excluded folder', () async {
          String fileA = '/project/aaa/a.dart';
          String fileB = '/project/bbb/b.dart';
          resourceProvider.newFile(fileA, '// a');
          resourceProvider.newFile(fileB, '// b');
          var response = testSetAnalysisRoots(['/project'], ['/project/bbb']);
          expect(response, isResponseSuccess('0'));
        });

        test('not absolute', () async {
          var response = testSetAnalysisRoots([], ['foo/bar']);
          expect(
              response,
              isResponseFailure(
                  '0', RequestErrorCode.INVALID_FILE_PATH_FORMAT));
        });

        test('not normalized', () async {
          var response = testSetAnalysisRoots([], ['/foo/../bar']);
          expect(
              response,
              isResponseFailure(
                  '0', RequestErrorCode.INVALID_FILE_PATH_FORMAT));
        });
      });

      group('included', () {
        test('new folder', () async {
          String file = '/project/bin/test.dart';
          resourceProvider.newFile('/project/pubspec.yaml', 'name: project');
          resourceProvider.newFile(file, 'main() {}');
          var response = testSetAnalysisRoots(['/project'], []);
          var serverRef = server;
          expect(response, isResponseSuccess('0'));
          // verify that unit is resolved eventually
          await server.onAnalysisComplete;
          var unit = await serverRef.getResolvedCompilationUnit(file);
          expect(unit, isNotNull);
        });

        test('nonexistent folder', () async {
          String fileB = '/project_b/b.dart';
          resourceProvider.newFile(fileB, '// b');
          var response = testSetAnalysisRoots(['/project_a', '/project_b'], []);
          var serverRef = server;
          expect(response, isResponseSuccess('0'));
          // Non-existence of /project_a should not prevent files in /project_b
          // from being analyzed.
          await server.onAnalysisComplete;
          var unit = await serverRef.getResolvedCompilationUnit(fileB);
          expect(unit, isNotNull);
        });

        test('not absolute', () async {
          var response = testSetAnalysisRoots(['foo/bar'], []);
          expect(
              response,
              isResponseFailure(
                  '0', RequestErrorCode.INVALID_FILE_PATH_FORMAT));
        });

        test('not normalized', () async {
          var response = testSetAnalysisRoots(['/foo/../bar'], []);
          expect(
              response,
              isResponseFailure(
                  '0', RequestErrorCode.INVALID_FILE_PATH_FORMAT));
        });
      });
    });

    group('setPriorityFiles', () {
      test('invalid', () {
        var request = new AnalysisSetPriorityFilesParams(['/project/lib.dart'])
            .toRequest('0');
        var response = handler.handleRequest(request);
        expect(response, isResponseSuccess('0'));
      });

      test('valid', () {
        resourceProvider.newFolder('/p1');
        resourceProvider.newFile('/p1/a.dart', 'library a;');
        resourceProvider.newFolder('/p2');
        resourceProvider.newFile('/p2/b.dart', 'library b;');
        resourceProvider.newFile('/p2/c.dart', 'library c;');

        var setRootsRequest =
            new AnalysisSetAnalysisRootsParams(['/p1', '/p2'], [])
                .toRequest('0');
        var setRootsResponse = handler.handleRequest(setRootsRequest);
        expect(setRootsResponse, isResponseSuccess('0'));

        void setPriorityFiles(List<String> fileList) {
          var request =
              new AnalysisSetPriorityFilesParams(fileList).toRequest('0');
          var response = handler.handleRequest(request);
          expect(response, isResponseSuccess('0'));
          // TODO(brianwilkerson) Enable the line below after getPriorityFiles
          // has been implemented.
          // expect(server.getPriorityFiles(), unorderedEquals(fileList));
        }

        setPriorityFiles(['/p1/a.dart', '/p2/b.dart']);
        setPriorityFiles(['/p2/b.dart', '/p2/c.dart']);
        setPriorityFiles([]);
      });
    });

    group('updateOptions', () {
      test('invalid', () {
        var request = new Request('0', ANALYSIS_REQUEST_UPDATE_OPTIONS, {
          ANALYSIS_REQUEST_UPDATE_OPTIONS_OPTIONS: {'not-an-option': true}
        });
        var response = handler.handleRequest(request);
        // Invalid options should be silently ignored.
        expect(response, isResponseSuccess('0'));
      });

      test('null', () {
        // null is allowed as a synonym for {}.
        var request = new Request('0', ANALYSIS_REQUEST_UPDATE_OPTIONS,
            {ANALYSIS_REQUEST_UPDATE_OPTIONS_OPTIONS: null});
        var response = handler.handleRequest(request);
        expect(response, isResponseSuccess('0'));
      });
    });
  });
}

testUpdateContent() {
  test('bad type', () {
    AnalysisTestHelper helper = new AnalysisTestHelper();
    helper.createSingleFileProject('// empty');
    return helper.onAnalysisComplete.then((_) {
      Request request = new Request('0', ANALYSIS_REQUEST_UPDATE_CONTENT, {
        ANALYSIS_REQUEST_UPDATE_CONTENT_FILES: {
          helper.testFile: {
            'type': 'foo',
          }
        }
      });
      Response response = helper.handler.handleRequest(request);
      expect(response, isResponseFailure('0'));
    });
  });

  test('full content', () {
    AnalysisTestHelper helper = new AnalysisTestHelper();
    helper.createSingleFileProject('// empty');
    return helper.onAnalysisComplete.then((_) {
      // no errors initially
      List<AnalysisError> errors = helper.getTestErrors();
      expect(errors, isEmpty);
      // update code
      helper.sendContentChange(new AddContentOverlay('library lib'));
      // wait, there is an error
      return helper.onAnalysisComplete.then((_) {
        List<AnalysisError> errors = helper.getTestErrors();
        expect(errors, hasLength(1));
      });
    });
  });

  test('incremental', () {
    AnalysisTestHelper helper = new AnalysisTestHelper();
    String initialContent = 'library A;';
    helper.createSingleFileProject(initialContent);
    return helper.onAnalysisComplete.then((_) {
      // no errors initially
      List<AnalysisError> errors = helper.getTestErrors();
      expect(errors, isEmpty);
      // Add the file to the cache
      helper.sendContentChange(new AddContentOverlay(initialContent));
      // update code
      helper.sendContentChange(new ChangeContentOverlay(
          [new SourceEdit('library '.length, 'A;'.length, 'lib')]));
      // wait, there is an error
      return helper.onAnalysisComplete.then((_) {
        List<AnalysisError> errors = helper.getTestErrors();
        expect(errors, hasLength(1));
      });
    });
  });

  test('change on disk, normal', () {
    AnalysisTestHelper helper = new AnalysisTestHelper();
    helper.createSingleFileProject('library A;');
    return helper.onAnalysisComplete.then((_) {
      // There should be no errors
      expect(helper.getTestErrors(), hasLength(0));
      // Change file on disk, adding a syntax error.
      helper.resourceProvider.modifyFile(helper.testFile, 'library lib');
      // There should be errors now.
      return pumpEventQueue().then((_) {
        return helper.onAnalysisComplete.then((_) {
          expect(helper.getTestErrors(), hasLength(1));
        });
      });
    });
  });

  test('change on disk, during override', () {
    AnalysisTestHelper helper = new AnalysisTestHelper();
    helper.createSingleFileProject('library A;');
    return helper.onAnalysisComplete.then((_) {
      // update code
      helper.sendContentChange(new AddContentOverlay('library B;'));
      // There should be no errors
      return helper.onAnalysisComplete.then((_) {
        expect(helper.getTestErrors(), hasLength(0));
        // Change file on disk, adding a syntax error.
        helper.resourceProvider.modifyFile(helper.testFile, 'library lib');
        // There should still be no errors (file should not have been reread).
        return helper.onAnalysisComplete.then((_) {
          expect(helper.getTestErrors(), hasLength(0));
          // Send a content change with a null content param--file should be
          // reread from disk.
          helper.sendContentChange(new RemoveContentOverlay());
          // There should be errors now.
          return helper.onAnalysisComplete.then((_) {
            expect(helper.getTestErrors(), hasLength(1));
          });
        });
      });
    });
  });

  group('out of range', () {
    Future outOfRangeTest(SourceEdit edit) {
      AnalysisTestHelper helper = new AnalysisTestHelper();
      helper.createSingleFileProject('library A;');
      return helper.onAnalysisComplete.then((_) {
        helper.sendContentChange(new AddContentOverlay('library B;'));
        return helper.onAnalysisComplete.then((_) {
          ChangeContentOverlay contentChange = new ChangeContentOverlay([edit]);
          Request request =
              new AnalysisUpdateContentParams({helper.testFile: contentChange})
                  .toRequest('0');
          Response response = helper.handler.handleRequest(request);
          expect(response,
              isResponseFailure('0', RequestErrorCode.INVALID_OVERLAY_CHANGE));
        });
      });
    }

    test('negative length', () {
      return outOfRangeTest(new SourceEdit(3, -1, 'foo'));
    });

    test('negative offset', () {
      return outOfRangeTest(new SourceEdit(-1, 3, 'foo'));
    });

    test('beyond end', () {
      return outOfRangeTest(new SourceEdit(6, 6, 'foo'));
    });
  });
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
    String pkgFile = '/packages/pkgA/libA.dart';
    resourceProvider.newFile(pkgFile, '''
library lib_a;
class A {}
''');
    resourceProvider.newFile(
        '/project/.packages', 'pkgA:file:///packages/pkgA');
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
class AnalysisTestHelper {
  MockServerChannel serverChannel;
  MemoryResourceProvider resourceProvider;
  AnalysisServer server;
  AnalysisDomainHandler handler;

  Map<AnalysisService, List<String>> analysisSubscriptions = {};

  Map<String, List<AnalysisError>> filesErrors = {};
  Map<String, List<HighlightRegion>> filesHighlights = {};
  Map<String, List<NavigationRegion>> filesNavigation = {};

  String testFile = '/project/bin/test.dart';
  String testCode;

  AnalysisTestHelper() {
    processRequiredPlugins();
    serverChannel = new MockServerChannel();
    resourceProvider = new MemoryResourceProvider();
    // Create an SDK in the mock file system.
    new MockSdk(resourceProvider: resourceProvider);
    server = new AnalysisServer(
        serverChannel,
        resourceProvider,
        new MockPackageMapProvider(),
        new AnalysisServerOptions(),
        new DartSdkManager('/', false),
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
    resourceProvider.newFolder('/project');
    Request request =
        new AnalysisSetAnalysisRootsParams(['/project'], []).toRequest('0');
    handleSuccessfulRequest(request);
  }

  /**
   * Creates a project with a single Dart file `/project/bin/test.dart` with
   * the given [code].
   */
  void createSingleFileProject(code) {
    this.testCode = _getCodeString(code);
    resourceProvider.newFolder('/project');
    resourceProvider.newFile(testFile, testCode);
    Request request =
        new AnalysisSetAnalysisRootsParams(['/project'], []).toRequest('0');
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

  String setFileContent(String path, String content) {
    resourceProvider.newFile(path, content);
    return path;
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
    String file = '/no-such-file.dart';
    addTestFile('// no matter');
    createProject();
    // wait for analysis, no results initially
    await waitForTasksFinished();
    expect(filesHighlights[testFile], isNull);
    // subscribe
    addAnalysisSubscription(AnalysisService.HIGHLIGHTS, file);
    await server.onAnalysisComplete;
    // there are results
    expect(filesHighlights[file], isNull);
  }

  test_afterAnalysis_packageFile_external() async {
    String pkgFile = '/packages/pkgA/lib/libA.dart';
    resourceProvider.newFile(pkgFile, '''
library lib_a;
class A {}
''');
    resourceProvider.newFile(
        '/project/.packages', 'pkgA:file:///packages/pkgA/lib');
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
    String pkgA = '/pkgA';
    String pkgB = '/pkgA';
    String pkgFileA = '$pkgA/lib/libA.dart';
    String pkgFileB = '$pkgA/lib/libB.dart';
    resourceProvider.newFile(pkgFileA, '''
library lib_a;
class A {}
''');
    resourceProvider.newFile(pkgFileB, '''
import 'package:pkgA/libA.dart';
main() {
  new A();
}
''');
    packageMapProvider.packageMap = {
      'pkgA': [
        resourceProvider.newFolder('$pkgA/lib'),
        resourceProvider.newFolder('$pkgB/lib')
      ]
    };
    // add 'pkgA' and 'pkgB' as projects
    {
      resourceProvider.newFolder(projectPath);
      handleSuccessfulRequest(
          new AnalysisSetAnalysisRootsParams([pkgA, pkgB], []).toRequest('0'));
    }
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
    String pkgFile = '/packages/pkgA/lib/libA.dart';
    resourceProvider.newFile(pkgFile, '''
library lib_a;
class A {}
''');
    resourceProvider.newFile('/project/.packages', 'pkgA:/packages/pkgA/lib');
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
    String file = '/lib/core/core.dart';
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
