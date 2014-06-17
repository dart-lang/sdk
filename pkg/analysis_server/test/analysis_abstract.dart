// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.domain.analysis.abstract;

import 'dart:async';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/domain_analysis.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/resource.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:unittest/unittest.dart';

import 'mocks.dart';


/**
 * An abstract base for all 'analysis' domain tests.
 */
class AbstractAnalysisTest {
  MockServerChannel serverChannel;
  MemoryResourceProvider resourceProvider;
  AnalysisServer server;
  AnalysisDomainHandler handler;

  Map<String, List<String>> analysisSubscriptions = {};

  String projectPath = '/project';
  String testFile = '/project/bin/test.dart';
  String testCode;

//  Map<String, List<AnalysisError>> filesErrors = {};
//  Map<String, List<Map<String, Object>>> filesHighlights = {};
//  Map<String, List<Map<String, Object>>> filesNavigation = {};


  AbstractAnalysisTest() {
  }

  void setUp() {
    serverChannel = new MockServerChannel();
    resourceProvider = new MemoryResourceProvider();
    server = new AnalysisServer(serverChannel, resourceProvider);
    server.defaultSdk = new MockSdk();
    handler = new AnalysisDomainHandler(server);
    // listen for notifications
    Stream<Notification> notificationStream = serverChannel.notificationController.stream;
    notificationStream.listen((Notification notification) {
      processNotification(notification);
    });
  }

  void addAnalysisSubscription(AnalysisService service, String file) {
    // add file to subscription
    var files = analysisSubscriptions[service.name];
    if (files == null) {
      files = <String>[];
      analysisSubscriptions[service.name] = files;
    }
    files.add(file);
    // set subscriptions
    Request request = new Request('0', ANALYSIS_SET_SUBSCRIPTIONS);
    request.setParameter(SUBSCRIPTIONS, analysisSubscriptions);
    handleSuccessfulRequest(request);
  }

  void tearDown() {
    server.done();
    handler = null;
    server = null;
    resourceProvider = null;
    serverChannel = null;
  }

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

  /**
   * Returns a [Future] that completes when the [AnalysisServer] finishes
   * all its scheduled tasks.
   */
  Future waitForTasksFinished() {
    return waitForServerOperationsPerformed(server);
  }

  /**
   * Returns the offset of [search] in [testCode].
   * Fails if not found.
   */
  int findFileOffset(String path, String search) {
    File file = resourceProvider.getResource(path) as File;
    String code = file.createSource(UriKind.FILE_URI).contents.data;
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

  /**
   * Creates a project `/project`.
   */
  void createProject() {
    resourceProvider.newFolder(projectPath);
    Request request = new Request('0', ANALYSIS_SET_ANALYSIS_ROOTS);
    request.setParameter(INCLUDED, [projectPath]);
    request.setParameter(EXCLUDED, []);
    handleSuccessfulRequest(request);
  }

//  /**
//   * Creates a project with a single Dart file `/project/bin/test.dart` with
//   * the given [code].
//   */
//  void createSingleFileProject(code) {
//    this.testCode = _getCodeString(code);
//    resourceProvider.newFolder('/project');
//    resourceProvider.newFile(testFile, testCode);
//    Request request = new Request('0', METHOD_SET_ANALYSIS_ROOTS);
//    request.setParameter(INCLUDED, ['/project']);
//    request.setParameter(EXCLUDED, []);
//    handleSuccessfulRequest(request);
//  }

  String addFile(String path, String content) {
    resourceProvider.newFile(path, content);
    return path;
  }

  String addTestFile(String content) {
    addFile(testFile, content);
    this.testCode = content;
    return testFile;
  }

  /**
   * Validates that the given [request] is handled successfully.
   */
  void handleSuccessfulRequest(Request request) {
    Response response = handler.handleRequest(request);
    expect(response, isResponseSuccess('0'));
  }

  static String _getCodeString(code) {
    if (code is List<String>) {
      code = code.join('\n');
    }
    return code as String;
  }
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


AnalysisError _jsonToAnalysisError(Map<String, Object> json) {
  return new AnalysisError(
      json['file'],
      json['errorCode'],
      json['offset'],
      json['length'],
      json['message'],
      json['correction']);
}


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
