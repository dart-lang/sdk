// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.domain.analysis;

import 'dart:async';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/domain_analysis.dart';
import 'package:analysis_server/src/protocol.dart';
import 'mock_sdk.dart';
import 'reflective_tests.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:path/path.dart';
import 'package:unittest/unittest.dart';

import 'analysis_abstract.dart';
import 'mocks.dart';


main() {
  groupSep = ' | ';

  runReflectiveTests(AnalysisDomainTest);

  MockServerChannel serverChannel;
  MemoryResourceProvider resourceProvider;
  AnalysisServer server;
  AnalysisDomainHandler handler;

  setUp(() {
    serverChannel = new MockServerChannel();
    resourceProvider = new MemoryResourceProvider();
    server = new AnalysisServer(
        serverChannel,
        resourceProvider,
        new MockPackageMapProvider(),
        null,
        new MockSdk());
    handler = new AnalysisDomainHandler(server);
  });

  group('updateContent', testUpdateContent);
  group('setSubscriptions', test_setSubscriptions);

  group('AnalysisDomainHandler', () {
    group('setAnalysisRoots', () {
      Response testSetAnalysisRoots(List<String> included,
          List<String> excluded) {
        Request request = new AnalysisSetAnalysisRootsParams(included,
            excluded).toRequest('0');
        return handler.handleRequest(request);
      }

      group('excluded', () {
        test('excluded folder', () {
          String project = '/project';
          String fileA = '/project/aaa/a.dart';
          String fileB = '/project/bbb/b.dart';
          resourceProvider.newFolder(project);
          resourceProvider.newFile(fileA, '// a');
          resourceProvider.newFile(fileB, '// b');
          var response = testSetAnalysisRoots([project], ['/project/bbb']);
          var serverRef = server;
          expect(response, isResponseSuccess('0'));
          // unit "a" is resolved eventually
          // unit "b" is not resolved
          return waitForServerOperationsPerformed(server).then((_) {
            expect(serverRef.test_getResolvedCompilationUnit(fileA), isNotNull);
            expect(serverRef.test_getResolvedCompilationUnit(fileB), isNull);
          });
        });
      });

      group('included', () {
        test('new folder', () {
          resourceProvider.newFolder('/project');
          resourceProvider.newFile('/project/pubspec.yaml', 'name: project');
          resourceProvider.newFile('/project/bin/test.dart', 'main() {}');
          var response = testSetAnalysisRoots(['/project'], []);
          var serverRef = server;
          expect(response, isResponseSuccess('0'));
          // verify that unit is resolved eventually
          return waitForServerOperationsPerformed(server).then((_) {
            var unit =
                serverRef.test_getResolvedCompilationUnit('/project/bin/test.dart');
            expect(unit, isNotNull);
          });
        });
      });
    });

    group('setPriorityFiles', () {
      test('invalid', () {
        // TODO(paulberry): under the "eventual consistency" model this request
        // should not be invalid.
        var request = new AnalysisSetPriorityFilesParams(
            ['/project/lib.dart']).toRequest('0');
        var response = handler.handleRequest(request);
        expect(response, isResponseFailure('0'));
      });

      test('valid', () {
        resourceProvider.newFolder('/p1');
        resourceProvider.newFile('/p1/a.dart', 'library a;');
        resourceProvider.newFolder('/p2');
        resourceProvider.newFile('/p2/b.dart', 'library b;');
        resourceProvider.newFile('/p2/c.dart', 'library c;');

        var setRootsRequest = new AnalysisSetAnalysisRootsParams(
            ['/p1', '/p2'], []).toRequest('0');
        var setRootsResponse = handler.handleRequest(setRootsRequest);
        expect(setRootsResponse, isResponseSuccess('0'));

        void setPriorityFiles(List<String> fileList) {
          var request = new AnalysisSetPriorityFilesParams(
              fileList).toRequest('0');
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
        var request = new Request('0', ANALYSIS_UPDATE_OPTIONS, {OPTIONS: {
          'not-an-option': true
        }});
        var response = handler.handleRequest(request);
        // Invalid options should be silently ignored.
        expect(response, isResponseSuccess('0'));
      });

      test('null', () {
        // null is allowed as a synonym for {}.
        var request = new Request('0', ANALYSIS_UPDATE_OPTIONS, {OPTIONS: null});
        var response = handler.handleRequest(request);
        expect(response, isResponseSuccess('0'));
      });

      // TODO(paulberry): disabled because analyzeAngular is currently not in the API.
//      test('valid', () {
//        engine.AnalysisOptions oldOptions = server.contextDirectoryManager.defaultOptions;
//        bool analyzeAngular = !oldOptions.analyzeAngular;
//        bool enableDeferredLoading = oldOptions.enableDeferredLoading;
//        var newOptions = new AnalysisOptions(analyzeAngular: analyzeAngular,
//            enableDeferredLoading: enableDeferredLoading, enableEnums: false);
//        var request = new AnalysisUpdateOptionsParams(newOptions).toRequest('0');
//        var response = handler.handleRequest(request);
//        expect(response, isResponseSuccess('0'));
//        expect(oldOptions.analyzeAngular, equals(analyzeAngular));
//        expect(oldOptions.enableDeferredLoading, equals(enableDeferredLoading));
//      });
    });
  });
}


testUpdateContent() {
  test('bad type', () {
    AnalysisTestHelper helper = new AnalysisTestHelper();
    helper.createSingleFileProject('// empty');
    return helper.waitForOperationsFinished().then((_) {
      Request request = new Request('0', ANALYSIS_UPDATE_CONTENT, {
        'files': {
          helper.testFile: {
            TYPE: 'foo',
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
    return helper.waitForOperationsFinished().then((_) {
      // no errors initially
      List<AnalysisError> errors = helper.getTestErrors();
      expect(errors, isEmpty);
      // update code
      helper.sendContentChange(new AddContentOverlay('library lib'));
      // wait, there is an error
      return helper.waitForOperationsFinished().then((_) {
        List<AnalysisError> errors = helper.getTestErrors();
        expect(errors, hasLength(1));
      });
    });
  });

  test('incremental', () {
    AnalysisTestHelper helper = new AnalysisTestHelper();
    String initialContent = 'library A;';
    helper.createSingleFileProject(initialContent);
    return helper.waitForOperationsFinished().then((_) {
      // no errors initially
      List<AnalysisError> errors = helper.getTestErrors();
      expect(errors, isEmpty);
      // Add the file to the cache
      helper.sendContentChange(new AddContentOverlay(initialContent));
      // update code
      helper.sendContentChange(new ChangeContentOverlay([
          new SourceEdit('library '.length, 'A;'.length, 'lib')]));
      // wait, there is an error
      return helper.waitForOperationsFinished().then((_) {
        List<AnalysisError> errors = helper.getTestErrors();
        expect(errors, hasLength(1));
      });
    });
  });

  test('change on disk, normal', () {
    AnalysisTestHelper helper = new AnalysisTestHelper();
    helper.createSingleFileProject('library A;');
    return helper.waitForOperationsFinished().then((_) {
      // There should be no errors
      expect(helper.getTestErrors(), hasLength(0));
      // Change file on disk, adding a syntax error.
      helper.resourceProvider.modifyFile(helper.testFile, 'library lib');
      // There should be errors now.
      return pumpEventQueue().then((_) {
        return helper.waitForOperationsFinished().then((_) {
          expect(helper.getTestErrors(), hasLength(1));
        });
      });
    });
  });

  test('change on disk, during override', () {
    AnalysisTestHelper helper = new AnalysisTestHelper();
    helper.createSingleFileProject('library A;');
    return helper.waitForOperationsFinished().then((_) {
      // update code
      helper.sendContentChange(new AddContentOverlay('library B;'));
      // There should be no errors
      return helper.waitForOperationsFinished().then((_) {
        expect(helper.getTestErrors(), hasLength(0));
        // Change file on disk, adding a syntax error.
        helper.resourceProvider.modifyFile(helper.testFile, 'library lib');
        // There should still be no errors (file should not have been reread).
        return helper.waitForOperationsFinished().then((_) {
          expect(helper.getTestErrors(), hasLength(0));
          // Send a content change with a null content param--file should be
          // reread from disk.
          helper.sendContentChange(new RemoveContentOverlay());
          // There should be errors now.
          return helper.waitForOperationsFinished().then((_) {
            expect(helper.getTestErrors(), hasLength(1));
          });
        });
      });
    });
  });
}


void test_setSubscriptions() {
  test('before analysis', () {
    AnalysisTestHelper helper = new AnalysisTestHelper();
    // subscribe
    helper.addAnalysisSubscriptionHighlights(helper.testFile);
    // create project
    helper.createSingleFileProject('int V = 42;');
    // wait, there are highlight regions
    helper.waitForOperationsFinished().then((_) {
      var highlights = helper.getHighlights(helper.testFile);
      expect(highlights, isNot(isEmpty));
    });
  });

  test('after analysis', () {
    AnalysisTestHelper helper = new AnalysisTestHelper();
    // create project
    helper.createSingleFileProject('int V = 42;');
    // wait, no regions initially
    return helper.waitForOperationsFinished().then((_) {
      var highlights = helper.getHighlights(helper.testFile);
      expect(highlights, isEmpty);
      // subscribe
      helper.addAnalysisSubscriptionHighlights(helper.testFile);
      // wait, has regions
      return helper.waitForOperationsFinished().then((_) {
        var highlights = helper.getHighlights(helper.testFile);
        expect(highlights, isNot(isEmpty));
      });
    });
  });

  test('after analysis, no such file', () {
    AnalysisTestHelper helper = new AnalysisTestHelper();
    helper.createSingleFileProject('int V = 42;');
    return helper.waitForOperationsFinished().then((_) {
      String noFile = '/no-such-file.dart';
      helper.addAnalysisSubscriptionHighlights(noFile);
      return helper.waitForOperationsFinished().then((_) {
        var highlights = helper.getHighlights(noFile);
        expect(highlights, isEmpty);
      });
    });
  });

  test('after analysis, SDK file', () {
    AnalysisTestHelper helper = new AnalysisTestHelper();
    helper.createSingleFileProject('''
main() {
  print(42);
}
''');
    return helper.waitForOperationsFinished().then((_) {
      String file = '/lib/core/core.dart';
      helper.addAnalysisSubscriptionNavigation(file);
      return helper.waitForOperationsFinished().then((_) {
        var navigationRegions = helper.getNavigation(file);
        expect(navigationRegions, isNot(isEmpty));
      });
    });
  });
}


int _getSafeInt(Map<String, Object> json, String key, int defaultValue) {
  Object value = json[key];
  if (value is int) {
    return value;
  }
  return defaultValue;
}


@ReflectiveTestCase()
class AnalysisDomainTest extends AbstractAnalysisTest {
  Map<String, List<AnalysisError>> filesErrors = {};

  void processNotification(Notification notification) {
    if (notification.event == ANALYSIS_ERRORS) {
      var decoded = new AnalysisErrorsParams.fromNotification(notification);
      filesErrors[decoded.file] = decoded.errors;
    }
  }

  test_packageMapDependencies() {
    // Prepare a source file that has errors because it refers to an unknown
    // package.
    String pkgFile = '/packages/pkgA/libA.dart';
    resourceProvider.newFile(pkgFile, '''
library lib_a;
class A {}
''');
    addTestFile('''
import 'package:pkgA/libA.dart';
f(A a) {
}
''');
    String pkgDependency = posix.join(projectPath, 'package_dep');
    resourceProvider.newFile(pkgDependency, 'contents');
    packageMapProvider.dependencies.add(pkgDependency);
    // Create project and wait for analysis
    createProject();
    return waitForTasksFinished().then((_) {
      expect(filesErrors[testFile], isNot(isEmpty));
      // Add the package to the package map and tickle the package dependency.
      packageMapProvider.packageMap = {
        'pkgA': [resourceProvider.getResource('/packages/pkgA')]
      };
      resourceProvider.modifyFile(pkgDependency, 'new contents');
      // Let the server time to notice the file has changed, then let
      // analysis omplete.  There should now be no error.
      return pumpEventQueue().then((_) => waitForTasksFinished()).then((_) {
        expect(filesErrors[testFile], isEmpty);
      });
    });
  }

  test_setRoots_packages() {
    // prepare package
    String pkgFile = '/packages/pkgA/libA.dart';
    resourceProvider.newFile(pkgFile, '''
library lib_a;
class A {}
''');
    packageMapProvider.packageMap['pkgA'] = [
        resourceProvider.getResource('/packages/pkgA')];
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
    serverChannel = new MockServerChannel();
    resourceProvider = new MemoryResourceProvider();
    server = new AnalysisServer(
        serverChannel,
        resourceProvider,
        new MockPackageMapProvider(),
        null,
        new MockSdk());
    handler = new AnalysisDomainHandler(server);
    // listen for notifications
    Stream<Notification> notificationStream =
        serverChannel.notificationController.stream;
    notificationStream.listen((Notification notification) {
      if (notification.event == ANALYSIS_ERRORS) {
        var decoded = new AnalysisErrorsParams.fromNotification(notification);
        filesErrors[decoded.file] = decoded.errors;
      }
      if (notification.event == ANALYSIS_HIGHLIGHTS) {
        var params = new AnalysisHighlightsParams.fromNotification(notification);
        filesHighlights[params.file] = params.regions;
      }
      if (notification.event == ANALYSIS_NAVIGATION) {
        var params = new AnalysisNavigationParams.fromNotification(notification);
        filesNavigation[params.file] = params.regions;
      }
    });
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
    Request request = new AnalysisSetSubscriptionsParams(
        analysisSubscriptions).toRequest('0');
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
    Request request = new AnalysisSetAnalysisRootsParams(['/project'],
        []).toRequest('0');
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
    Request request = new AnalysisSetAnalysisRootsParams(['/project'],
        []).toRequest('0');
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

  /**
   * Send an `updateContent` request for [testFile].
   */
  void sendContentChange(dynamic contentChange) {
    Request request = new AnalysisUpdateContentParams({
      testFile: contentChange}).toRequest('0');
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

  /**
   * Returns a [Future] that completes when this this helper finished all its
   * scheduled tasks.
   */
  Future waitForOperationsFinished() {
    return waitForServerOperationsPerformed(server);
  }

  static String _getCodeString(code) {
    if (code is List<String>) {
      code = code.join('\n');
    }
    return code as String;
  }
}
