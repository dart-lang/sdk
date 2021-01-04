// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart'
    hide AnalysisOptions;
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/domain_analysis.dart';
import 'package:analysis_server/src/server/crash_reporting_attachments.dart';
import 'package:analysis_server/src/utilities/mocks.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

import 'mocks.dart';

int findIdentifierLength(String search) {
  var length = 0;
  while (length < search.length) {
    var c = search.codeUnitAt(length);
    if (!(c >= 'a'.codeUnitAt(0) && c <= 'z'.codeUnitAt(0) ||
        c >= 'A'.codeUnitAt(0) && c <= 'Z'.codeUnitAt(0) ||
        c >= '0'.codeUnitAt(0) && c <= '9'.codeUnitAt(0) ||
        c == '_'.codeUnitAt(0))) {
      break;
    }
    length++;
  }
  return length;
}

/// An abstract base for all 'analysis' domain tests.
class AbstractAnalysisTest with ResourceProviderMixin {
  MockServerChannel serverChannel;
  TestPluginManager pluginManager;
  AnalysisServer server;
  RequestHandler handler;

  final List<GeneralAnalysisService> generalServices =
      <GeneralAnalysisService>[];
  final Map<AnalysisService, List<String>> analysisSubscriptions = {};

  String projectPath;
  String testFolder;
  String testFile;
  String testCode;

  AbstractAnalysisTest();

  AnalysisDomainHandler get analysisHandler => server.handlers
      .singleWhere((handler) => handler is AnalysisDomainHandler);

  AnalysisOptions get analysisOptions => testDiver.analysisOptions;

  AnalysisDriver get testDiver => server.getAnalysisDriver(testFile);

  void addAnalysisOptionsFile(String content) {
    newFile(
        resourceProvider.pathContext.join(projectPath, 'analysis_options.yaml'),
        content: content);
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

  void addGeneralAnalysisSubscription(GeneralAnalysisService service) {
    generalServices.add(service);
    var request =
        AnalysisSetGeneralSubscriptionsParams(generalServices).toRequest('0');
    handleSuccessfulRequest(request);
  }

  String addTestFile(String content) {
    newFile(testFile, content: content);
    testCode = content;
    return testFile;
  }

  /// Create an analysis options file based on the given arguments.
  void createAnalysisOptionsFile({List<String> experiments}) {
    var buffer = StringBuffer();
    if (experiments != null) {
      buffer.writeln('analyzer:');
      buffer.writeln('  enable-experiment:');
      for (var experiment in experiments) {
        buffer.writeln('    - $experiment');
      }
    }
    addAnalysisOptionsFile(buffer.toString());
  }

  AnalysisServer createAnalysisServer() {
    //
    // Create an SDK in the mock file system.
    //
    MockSdk(resourceProvider: resourceProvider);
    //
    // Create server
    //
    var options = AnalysisServerOptions();
    return AnalysisServer(
        serverChannel,
        resourceProvider,
        options,
        DartSdkManager(resourceProvider.convertPath('/sdk')),
        CrashReportingAttachmentsBuilder.empty,
        InstrumentationService.NULL_SERVICE);
  }

  /// Creates a project [projectPath].
  void createProject({Map<String, String> packageRoots}) {
    newFolder(projectPath);
    var request = AnalysisSetAnalysisRootsParams([projectPath], [],
            packageRoots: packageRoots)
        .toRequest('0');
    handleSuccessfulRequest(request, handler: analysisHandler);
  }

  void doAllDeclarationsTrackerWork() {
    while (server.declarationsTracker.hasWork) {
      server.declarationsTracker.doWork();
    }
  }

  /// Returns the offset of [search] in the file at the given [path].
  /// Fails if not found.
  int findFileOffset(String path, String search) {
    var file = getFile(path);
    var code = file.createSource().contents.data;
    var offset = code.indexOf(search);
    expect(offset, isNot(-1), reason: '"$search" in\n$code');
    return offset;
  }

  /// Returns the offset of [search] in [testCode].
  /// Fails if not found.
  int findOffset(String search) {
    var offset = testCode.indexOf(search);
    expect(offset, isNot(-1));
    return offset;
  }

  /// Validates that the given [request] is handled successfully.
  Response handleSuccessfulRequest(Request request, {RequestHandler handler}) {
    handler ??= this.handler;
    var response = handler.handleRequest(request);
    expect(response, isResponseSuccess(request.id));
    return response;
  }

  String modifyTestFile(String content) {
    modifyFile(testFile, content);
    testCode = content;
    return testFile;
  }

  void processNotification(Notification notification) {
    if (notification.event == SERVER_NOTIFICATION_ERROR) {
      fail('${notification.toJson()}');
    }
  }

  void removeGeneralAnalysisSubscription(GeneralAnalysisService service) {
    generalServices.remove(service);
    var request =
        AnalysisSetGeneralSubscriptionsParams(generalServices).toRequest('0');
    handleSuccessfulRequest(request);
  }

  void setPriorityFiles(List<String> files) {
    var request = AnalysisSetPriorityFilesParams(files).toRequest('0');
    handleSuccessfulRequest(request);
  }

  @mustCallSuper
  void setUp() {
    serverChannel = MockServerChannel();
    projectPath = convertPath('/project');
    testFolder = convertPath('/project/bin');
    testFile = convertPath('/project/bin/test.dart');
    pluginManager = TestPluginManager();
    server = createAnalysisServer();
    server.pluginManager = pluginManager;
    handler = analysisHandler;
    // listen for notifications
    var notificationStream = serverChannel.notificationController.stream;
    notificationStream.listen((Notification notification) {
      processNotification(notification);
    });
  }

  @mustCallSuper
  void tearDown() {
    server.done();
    handler = null;
    server = null;
    serverChannel = null;
  }

  /// Returns a [Future] that completes when the server's analysis is complete.
  Future waitForTasksFinished() {
    return server.onAnalysisComplete;
  }

  /// Completes with a successful [Response] for the given [request].
  /// Otherwise fails.
  Future<Response> waitResponse(Request request,
      {bool throwOnError = true}) async {
    return serverChannel.sendRequest(request, throwOnError: throwOnError);
  }
}
