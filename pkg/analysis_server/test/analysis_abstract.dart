// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.domain.analysis.abstract;

import 'dart:async';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/domain_analysis.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/services/index/index.dart';
import 'mock_sdk.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:unittest/unittest.dart';

import 'mocks.dart';


int findIdentifierLength(String search) {
  int length = 0;
  while (length < search.length) {
    int c = search.codeUnitAt(length);
    if (!(c >= 'a'.codeUnitAt(0) && c <= 'z'.codeUnitAt(0) ||
          c >= 'A'.codeUnitAt(0) && c <= 'Z'.codeUnitAt(0) ||
          c >= '0'.codeUnitAt(0) && c <= '9'.codeUnitAt(0))) {
      break;
    }
    length++;
  }
  return length;
}



/**
 * An abstract base for all 'analysis' domain tests.
 */
class AbstractAnalysisTest {
  MockServerChannel serverChannel;
  MemoryResourceProvider resourceProvider;
  MockPackageMapProvider packageMapProvider;
  AnalysisServer server;
  RequestHandler handler;

  Map<AnalysisService, List<String>> analysisSubscriptions = {};

  String projectPath = '/project';
  String testFolder = '/project/bin/';
  String testFile = '/project/bin/test.dart';
  String testCode;

//  Map<String, List<AnalysisError>> filesErrors = {};
//  Map<String, List<Map<String, Object>>> filesHighlights = {};
//  Map<String, List<Map<String, Object>>> filesNavigation = {};


  AbstractAnalysisTest() {
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

  String addFile(String path, String content) {
    resourceProvider.newFile(path, content);
    return path;
  }

  String addTestFile(String content) {
    addFile(testFile, content);
    this.testCode = content;
    return testFile;
  }

  Index createIndex() {
    return null;
  }

  /**
   * Creates a project `/project`.
   */
  void createProject() {
    resourceProvider.newFolder(projectPath);
    Request request = new AnalysisSetAnalysisRootsParams([projectPath],
        []).toRequest('0');
    handleSuccessfulRequest(request);
  }

  /**
   * Returns the offset of [search] in [testCode].
   * Fails if not found.
   */
  int findFileOffset(String path, String search) {
    File file = resourceProvider.getResource(path) as File;
    String code = file.createSource().contents.data;
    int offset = code.indexOf(search);
    expect(offset, isNot(-1), reason: '"$search" in\n$code');
    return offset;
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
   * Validates that the given [request] is handled successfully.
   */
  Response handleSuccessfulRequest(Request request) {
    Response response = handler.handleRequest(request);
    expect(response, isResponseSuccess('0'));
    return response;
  }

//  /**
//   * Returns [AnalysisError]s recorded for the given [file].
//   * May be empty, but not `null`.
//   */
//  List<AnalysisError> getErrors(String file) {
//    List<AnalysisError> errors = filesErrors[file];
//    if (errors != null) {
//      return errors;
//    }
//    return <AnalysisError>[];
//  }
//
//  /**
//   * Returns highlights recorded for the given [file].
//   * May be empty, but not `null`.
//   */
//  List<Map<String, Object>> getHighlights(String file) {
//    List<Map<String, Object>> highlights = filesHighlights[file];
//    if (highlights != null) {
//      return highlights;
//    }
//    return [];
//  }
//
//  /**
//   * Returns navigation regions recorded for the given [file].
//   * May be empty, but not `null`.
//   */
//  List<Map<String, Object>> getNavigation(String file) {
//    List<Map<String, Object>> navigation = filesNavigation[file];
//    if (navigation != null) {
//      return navigation;
//    }
//    return [];
//  }
//
//  /**
//   * Returns [AnalysisError]s recorded for the [testFile].
//   * May be empty, but not `null`.
//   */
//  List<AnalysisError> getTestErrors() {
//    return getErrors(testFile);
//  }
//
//  /**
//   * Returns highlights recorded for the given [testFile].
//   * May be empty, but not `null`.
//   */
//  List<Map<String, Object>> getTestHighlights() {
//    return getHighlights(testFile);
//  }
//
//  /**
//   * Returns navigation information recorded for the given [testFile].
//   * May be empty, but not `null`.
//   */
//  List<Map<String, Object>> getTestNavigation() {
//    return getNavigation(testFile);
//  }

  void processNotification(Notification notification) {
//    if (notification.event == NOTIFICATION_ERRORS) {
//      String file = notification.getParameter(FILE);
//      List<Map<String, Object>> errorMaps = notification.getParameter(ERRORS);
//      filesErrors[file] = errorMaps.map(jsonToAnalysisError).toList();
//    }
//    if (notification.event == NOTIFICATION_HIGHLIGHTS) {
//      String file = notification.getParameter(FILE);
//      filesHighlights[file] = notification.getParameter(REGIONS);
//    }
//    if (notification.event == NOTIFICATION_NAVIGATION) {
//      String file = notification.getParameter(FILE);
//      filesNavigation[file] = notification.getParameter(REGIONS);
//    }
  }

//  /**
//   * Creates a project with a single Dart file `/project/bin/test.dart` with
//   * the given [code].
//   */
//  void createSingleFileProject(code) {
//    this.testCode = _getCodeString(code);
//    resourceProvider.newFolder('/project');
//    resourceProvider.newFile(testFile, testCode);
//    Request request = new AnalysisSetAnalysisRootsParams(['/project'],
//        []).toRequest('0');
//    handleSuccessfulRequest(request);
//  }

  void setUp() {
    serverChannel = new MockServerChannel();
    resourceProvider = new MemoryResourceProvider();
    packageMapProvider = new MockPackageMapProvider();
    Index index = createIndex();
    server = new AnalysisServer(
        serverChannel, resourceProvider, packageMapProvider, index,
        new MockSdk());
    handler = new AnalysisDomainHandler(server);
    // listen for notifications
    Stream<Notification> notificationStream = serverChannel.notificationController.stream;
    notificationStream.listen((Notification notification) {
      processNotification(notification);
    });
  }

  void tearDown() {
    server.done();
    handler = null;
    server = null;
    resourceProvider = null;
    serverChannel = null;
  }

  /**
   * Returns a [Future] that completes when the [AnalysisServer] finishes
   * all its scheduled tasks.
   */
  Future waitForTasksFinished() {
    return waitForServerOperationsPerformed(server);
  }

  static String _getCodeString(code) {
    if (code is List<String>) {
      code = code.join('\n');
    }
    return code as String;
  }
}
