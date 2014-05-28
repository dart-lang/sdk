// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.domain.analysis;

import 'dart:async';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/domain_analysis.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/resource.dart';
import 'package:unittest/unittest.dart';

import 'mocks.dart';


main() {
  groupSep = ' | ';

  MockServerChannel serverChannel;
  AnalysisServer server;
  AnalysisDomainHandler handler;
  MemoryResourceProvider resourceProvider = new MemoryResourceProvider();

  setUp(() {
    serverChannel = new MockServerChannel();
    server = new AnalysisServer(serverChannel, resourceProvider);
    handler = new AnalysisDomainHandler(server);
  });

  group('notification.errors', testNotificationErrors);
  group('updateContent', testUpdateContent);

  group('AnalysisDomainHandler', () {
    test('getFixes', () {
      var request = new Request('0', AnalysisDomainHandler.GET_FIXES_METHOD);
      request.setParameter(AnalysisDomainHandler.ERRORS_PARAM, []);
      var response = handler.handleRequest(request);
      // TODO(scheglov) implement
      expect(response, isNull);
    });

    test('getMinorRefactorings', () {
      var request = new Request('0', AnalysisDomainHandler.GET_MINOR_REFACTORINGS_METHOD);
      request.setParameter(AnalysisDomainHandler.FILE_PARAM, 'test.dart');
      request.setParameter(AnalysisDomainHandler.OFFSET_PARAM, 10);
      request.setParameter(AnalysisDomainHandler.LENGTH_PARAM, 20);
      var response = handler.handleRequest(request);
      // TODO(scheglov) implement
      expect(response, isNull);
    });

    group('setAnalysisRoots', () {
      Request request;

      setUp(() {
        request = new Request('0', AnalysisDomainHandler.SET_ANALYSIS_ROOTS_METHOD);
        request.setParameter(AnalysisDomainHandler.INCLUDED_PARAM, []);
        request.setParameter(AnalysisDomainHandler.EXCLUDED_PARAM, []);
      });

      test('excluded', () {
        request.setParameter(AnalysisDomainHandler.EXCLUDED_PARAM, ['foo']);
        // TODO(scheglov) implement
        var response = handler.handleRequest(request);
        expect(response, isResponseFailure('0'));
      });

      group('included', () {
        test('new folder', () {
          resourceProvider.newFolder('/project');
          resourceProvider.newFile('/project/pubspec.yaml', 'name: project');
          resourceProvider.newFile('/project/bin/test.dart', 'main() {}');
          request.setParameter(
              AnalysisDomainHandler.INCLUDED_PARAM,
              ['/project']);
          var response = handler.handleRequest(request);
          var serverRef = server;
          expect(response, isResponseSuccess('0'));
          // verify that unit is resolved eventually
          return waitForServerTasksFinished(server).then((_) {
            var unit = serverRef.test_getResolvedCompilationUnit('/project/bin/test.dart');
            expect(unit, isNotNull);
          });
        });
      });
    });

    test('setPriorityFiles', () {
      var request = new Request('0', AnalysisDomainHandler.SET_PRIORITY_FILES_METHOD);
      request.setParameter(
          AnalysisDomainHandler.FILES_PARAM,
          ['projectA/aa.dart', 'projectB/ba.dart']);
      var response = handler.handleRequest(request);
      // TODO(scheglov) implement
      expect(response, isNull);
    });

    test('setSubscriptions', () {
      var request = new Request('0', AnalysisDomainHandler.SET_SUBSCRIPTIONS_METHOD);
      request.setParameter(
          AnalysisDomainHandler.SUBSCRIPTIONS_PARAM,
          {
            AnalysisService.HIGHLIGHTS : ['project/a.dart', 'project/b.dart'],
            AnalysisService.NAVIGATION : ['project/c.dart'],
            AnalysisService.OUTLINE : ['project/d.dart', 'project/e.dart']
          });
      var response = handler.handleRequest(request);
      // TODO(scheglov) implement
      expect(response, isNull);
    });

    test('updateOptions', () {
      var request = new Request('0', AnalysisDomainHandler.UPDATE_OPTIONS_METHOD);
      request.setParameter(
          AnalysisDomainHandler.OPTIONS_PARAM,
          {
            'analyzeAngular' : true,
            'enableDeferredLoading': true,
            'enableEnums': false
          });
      var response = handler.handleRequest(request);
      // TODO(scheglov) implement
      expect(response, isNull);
    });

    test('updateSdks', () {
      var request = new Request('0', AnalysisDomainHandler.UPDATE_SDKS_METHOD);
      request.setParameter(
          AnalysisDomainHandler.ADDED_PARAM,
          ['/dart/sdk-1.3', '/dart/sdk-1.4']);
      request.setParameter(
          AnalysisDomainHandler.REMOVED_PARAM,
          ['/dart/sdk-1.2']);
      request.setParameter(AnalysisDomainHandler.DEFAULT_PARAM, '/dart/sdk-1.4');
      var response = handler.handleRequest(request);
      // TODO(scheglov) implement
      expect(response, isNull);
    });
  });
}


/**
 * A helper to test 'analysis.*' requests.
 */
class AnalysisTestHelper {
  MockServerChannel serverChannel;
  MemoryResourceProvider resourceProvider;
  AnalysisServer server;
  AnalysisDomainHandler handler;

  Map<String, List<AnalysisError>> filesErrors = {};

  String testFile = '/project/bin/test.dart';
  String testCode;

  AnalysisTestHelper() {
    serverChannel = new MockServerChannel();
    resourceProvider = new MemoryResourceProvider();
    server = new AnalysisServer(serverChannel, resourceProvider);
    handler = new AnalysisDomainHandler(server);
    // listen for notifications
    Stream<Notification> notificationStream = serverChannel.notificationController.stream;
    notificationStream.listen((Notification notification) {
      if (notification.event == AnalysisDomainHandler.ERRORS_NOTIFICATION) {
        String file = notification.getParameter(AnalysisServer.FILE_PARAM);
        List<Map<String, Object>> errorMaps = notification.getParameter(AnalysisServer.ERRORS_PARAM);
        filesErrors[file] = errorMaps.map(jsonToAnalysisError).toList();
      }
    });
  }

  /**
   * Returns a [Future] that completes when this this helper finished all its
   * scheduled tasks.
   */
  Future waitForTasksFinished() {
    return waitForServerTasksFinished(server);
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
   * Returns [AnalysisError]s recorded for the [testFile].
   * May be empty, but not `null`.
   */
  List<AnalysisError> getTestErrors() {
    return getErrors(testFile);
  }

  /**
   * Creates a project with a single Dart file `/project/bin/test.dart` with
   * the given [code].
   */
  void createSingleFileProject(code) {
    this.testCode = _getCodeString(code);
    resourceProvider.newFolder('/project');
    resourceProvider.newFile('/project/pubspec.yaml', 'name: project');
    resourceProvider.newFile(testFile, testCode);
    Request request = new Request('0', AnalysisDomainHandler.SET_ANALYSIS_ROOTS_METHOD);
    request.setParameter(AnalysisDomainHandler.INCLUDED_PARAM, ['/project']);
    request.setParameter(AnalysisDomainHandler.EXCLUDED_PARAM, []);
    handleSuccessfulRequest(request);
  }

  /**
   * Validates that the given [request] is handled successfully.
   */
  void handleSuccessfulRequest(Request request) {
    Response response = handler.handleRequest(request);
    expect(response, isResponseSuccess('0'));
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


testNotificationErrors() {
  AnalysisTestHelper helper;

  setUp(() {
    helper = new AnalysisTestHelper();
  });

  test('ParserErrorCode', () {
    helper.createSingleFileProject('library lib');
    return helper.waitForTasksFinished().then((_) {
      List<AnalysisError> errors = helper.getTestErrors();
      expect(errors, hasLength(1));
      AnalysisError error = errors[0];
      expect(error.file, '/project/bin/test.dart');
      expect(error.errorCode, 'ParserErrorCode.EXPECTED_TOKEN');
      expect(error.offset, isPositive);
      expect(error.length, isNonNegative);
      expect(error.message, isNotNull);
    });
  });

  test('StaticWarningCode', () {
    helper.createSingleFileProject([
      'main() {',
      '  print(unknown);',
      '}']);
    return helper.waitForTasksFinished().then((_) {
      List<AnalysisError> errors = helper.getTestErrors();
      expect(errors, hasLength(1));
      AnalysisError error = errors[0];
      expect(error.errorCode, 'StaticWarningCode.UNDEFINED_IDENTIFIER');
    });
  });
}


testUpdateContent() {
  test('full content', () {
    AnalysisTestHelper helper = new AnalysisTestHelper();
    helper.createSingleFileProject('// empty');
    return helper.waitForTasksFinished().then((_) {
      // no errors initially
      List<AnalysisError> errors = helper.getTestErrors();
      expect(errors, isEmpty);
      // update code
      {
        Request request = new Request('0', AnalysisDomainHandler.UPDATE_CONTENT_METHOD);
        request.setParameter('files',
            {
              helper.testFile : {
                AnalysisDomainHandler.CONTENT_PARAM : 'library lib'
              }
            });
        helper.handleSuccessfulRequest(request);
      }
      // wait, there is an error
      helper.waitForTasksFinished().then((_) {
        List<AnalysisError> errors = helper.getTestErrors();
        expect(errors, hasLength(1));
      });
    });
  });

  test('incremental', () {
    AnalysisTestHelper helper = new AnalysisTestHelper();
    helper.createSingleFileProject('library A;');
    return helper.waitForTasksFinished().then((_) {
      // no errors initially
      List<AnalysisError> errors = helper.getTestErrors();
      expect(errors, isEmpty);
      // update code
      {
        Request request = new Request('0', AnalysisDomainHandler.UPDATE_CONTENT_METHOD);
        request.setParameter('files',
            {
              helper.testFile : {
                AnalysisDomainHandler.CONTENT_PARAM : 'library lib',
                AnalysisDomainHandler.OFFSET_PARAM : 'library '.length,
                AnalysisDomainHandler.OLD_LENGTH_PARAM : 'A;'.length,
                AnalysisDomainHandler.NEW_LENGTH_PARAM : 'lib'.length,
              }
            });
        helper.handleSuccessfulRequest(request);
      }
      // wait, there is an error
      helper.waitForTasksFinished().then((_) {
        List<AnalysisError> errors = helper.getTestErrors();
        expect(errors, hasLength(1));
      });
    });
  });
}


class AnalysisError {
  final String file;
  final String errorCode;
  final int offset;
  final int length;
  final String message;
  final String correction;
  AnalysisError(this.file, this.errorCode, this.offset, this.length,
      this.message, this.correction);

  @override
  String toString() {
    return 'NotificationError(file=$file; errorCode=$errorCode; '
        'offset=$offset; length=$length; message=$message)';
  }
}


AnalysisError jsonToAnalysisError(Map<String, Object> json) {
  return new AnalysisError(
      json['file'],
      json['errorCode'],
      json['offset'],
      json['length'],
      json['message'],
      json['correction']);
}
