// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.domain.analysis.abstract;

import 'dart:async';

import 'package:analysis_server/plugin/protocol/protocol.dart'
    hide AnalysisOptions;
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/domain_analysis.dart';
import 'package:analysis_server/src/plugin/server_plugin.dart';
import 'package:analysis_server/src/provisional/completion/dart/completion_plugin.dart';
import 'package:analysis_server/src/services/index/index.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:plugin/manager.dart';
import 'package:plugin/plugin.dart';
import 'package:test/test.dart';

import 'mock_sdk.dart';
import 'mocks.dart';

int findIdentifierLength(String search) {
  int length = 0;
  while (length < search.length) {
    int c = search.codeUnitAt(length);
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

/**
 * An abstract base for all 'analysis' domain tests.
 */
class AbstractAnalysisTest {
  bool enableNewAnalysisDriver = false;
  bool generateSummaryFiles = false;
  MockServerChannel serverChannel;
  MemoryResourceProvider resourceProvider;
  MockPackageMapProvider packageMapProvider;
  AnalysisServer server;
  RequestHandler handler;

  final List<ServerErrorParams> serverErrors = <ServerErrorParams>[];
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

  AnalysisOptions get analysisOptions => enableNewAnalysisDriver
      ? testDiver.analysisOptions
      : testContext.analysisOptions;

  AnalysisContext get testContext => server.getAnalysisContext(testFile);

  AnalysisDriver get testDiver => server.getAnalysisDriver(testFile);

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

  String addFile(String path, String content) {
    path = resourceProvider.convertPath(path);
    resourceProvider.newFile(path, content);
    return path;
  }

  void addGeneralAnalysisSubscription(GeneralAnalysisService service) {
    generalServices.add(service);
    Request request = new AnalysisSetGeneralSubscriptionsParams(generalServices)
        .toRequest('0');
    handleSuccessfulRequest(request);
  }

  void addServerPlugins(List<Plugin> plugins) {}

  String addTestFile(String content) {
    addFile(testFile, content);
    this.testCode = content;
    return testFile;
  }

  AnalysisServer createAnalysisServer(Index index) {
    //
    // Collect plugins
    //
    ServerPlugin serverPlugin = new ServerPlugin();
    List<Plugin> plugins = <Plugin>[];
    plugins.addAll(AnalysisEngine.instance.requiredPlugins);
    plugins.add(serverPlugin);
    plugins.add(dartCompletionPlugin);
    addServerPlugins(plugins);
    //
    // Process plugins
    //
    ExtensionManager manager = new ExtensionManager();
    manager.processPlugins(plugins);
    //
    // Create an SDK in the mock file system.
    //
    new MockSdk(
        generateSummaryFiles: generateSummaryFiles,
        resourceProvider: resourceProvider);
    //
    // Create server
    //
    AnalysisServerOptions options = new AnalysisServerOptions();
    options.enableNewAnalysisDriver = enableNewAnalysisDriver;
    return new AnalysisServer(
        serverChannel,
        resourceProvider,
        packageMapProvider,
        index,
        serverPlugin,
        options,
        new DartSdkManager(resourceProvider.convertPath('/'), true),
        InstrumentationService.NULL_SERVICE);
  }

  Index createIndex() {
    return null;
  }

  /**
   * Creates a project `/project`.
   */
  void createProject({Map<String, String> packageRoots}) {
    resourceProvider.newFolder(projectPath);
    Request request = new AnalysisSetAnalysisRootsParams([projectPath], [],
            packageRoots: packageRoots)
        .toRequest('0');
    handleSuccessfulRequest(request, handler: analysisHandler);
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
  Response handleSuccessfulRequest(Request request, {RequestHandler handler}) {
    handler ??= this.handler;
    Response response = handler.handleRequest(request);
    expect(response, isResponseSuccess(request.id));
    return response;
  }

  String modifyTestFile(String content) {
    String path = resourceProvider.convertPath(testFile);
    resourceProvider.updateFile(path, content);
    this.testCode = content;
    return testFile;
  }

  void processNotification(Notification notification) {
    if (notification.event == SERVER_ERROR) {
      var params = new ServerErrorParams.fromNotification(notification);
      serverErrors.add(params);
    }
  }

  void removeGeneralAnalysisSubscription(GeneralAnalysisService service) {
    generalServices.remove(service);
    Request request = new AnalysisSetGeneralSubscriptionsParams(generalServices)
        .toRequest('0');
    handleSuccessfulRequest(request);
  }

  void setUp() {
    serverChannel = new MockServerChannel();
    resourceProvider = new MemoryResourceProvider();
    projectPath = resourceProvider.convertPath('/project');
    testFolder = resourceProvider.convertPath('/project/bin');
    testFile = resourceProvider.convertPath('/project/bin/test.dart');
    packageMapProvider = new MockPackageMapProvider();
    Index index = createIndex();
    server = createAnalysisServer(index);
    handler = analysisHandler;
    // listen for notifications
    Stream<Notification> notificationStream =
        serverChannel.notificationController.stream;
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
   * Returns a [Future] that completes when the server's analysis is complete.
   */
  Future waitForTasksFinished() {
    return server.onAnalysisComplete;
  }

  /**
   * Completes with a successful [Response] for the given [request].
   * Otherwise fails.
   */
  Future<Response> waitResponse(Request request) async {
    return serverChannel.sendRequest(request);
  }
}
