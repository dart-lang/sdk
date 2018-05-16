// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart'
    hide AnalysisOptions;
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/domain_analysis.dart';
import 'package:analysis_server/src/plugin/notification_manager.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/context/context_root.dart' as analyzer;
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer_plugin/protocol/protocol.dart' as plugin;
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:analyzer_plugin/src/protocol/protocol_internal.dart' as plugin;
import 'package:plugin/manager.dart';
import 'package:test/test.dart';
import 'package:watcher/watcher.dart';

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
class AbstractAnalysisTest extends Object with ResourceProviderMixin {
  bool generateSummaryFiles = false;
  MockServerChannel serverChannel;
  MockPackageMapProvider packageMapProvider;
  TestPluginManager pluginManager;
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

  AnalysisOptions get analysisOptions => testDiver.analysisOptions;

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

  void addGeneralAnalysisSubscription(GeneralAnalysisService service) {
    generalServices.add(service);
    Request request = new AnalysisSetGeneralSubscriptionsParams(generalServices)
        .toRequest('0');
    handleSuccessfulRequest(request);
  }

  String addTestFile(String content) {
    newFile(testFile, content: content);
    this.testCode = content;
    return testFile;
  }

  AnalysisServer createAnalysisServer() {
    //
    // Process plugins
    //
    ExtensionManager manager = new ExtensionManager();
    manager.processPlugins(AnalysisEngine.instance.requiredPlugins);
    //
    // Create an SDK in the mock file system.
    //
    new MockSdk(
        generateSummaryFiles: generateSummaryFiles,
        resourceProvider: resourceProvider);
    //
    // Create server
    //
    AnalysisServerOptions options = new AnalysisServerOptions()
      ..previewDart2 = true;
    return new AnalysisServer(
        serverChannel,
        resourceProvider,
        packageMapProvider,
        options,
        new DartSdkManager(resourceProvider.convertPath('/'), true),
        InstrumentationService.NULL_SERVICE);
  }

  /**
   * Creates a project `/project`.
   */
  void createProject({Map<String, String> packageRoots}) {
    newFolder(projectPath);
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
    File file = getFile(path);
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
    modifyFile(testFile, content);
    this.testCode = content;
    return testFile;
  }

  void processNotification(Notification notification) {
    if (notification.event == SERVER_NOTIFICATION_ERROR) {
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

  void setPriorityFiles(List<String> files) {
    var request = new AnalysisSetPriorityFilesParams(files).toRequest('0');
    handleSuccessfulRequest(request);
  }

  void setUp() {
    serverChannel = new MockServerChannel();
    projectPath = resourceProvider.convertPath('/project');
    testFolder = resourceProvider.convertPath('/project/bin');
    testFile = resourceProvider.convertPath('/project/bin/test.dart');
    packageMapProvider = new MockPackageMapProvider();
    pluginManager = new TestPluginManager();
    server = createAnalysisServer();
    server.pluginManager = pluginManager;
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

/**
 * A plugin manager that simulates broadcasting requests to plugins by
 * hard-coding the responses.
 */
class TestPluginManager implements PluginManager {
  plugin.AnalysisSetPriorityFilesParams analysisSetPriorityFilesParams;
  plugin.AnalysisSetSubscriptionsParams analysisSetSubscriptionsParams;
  plugin.AnalysisUpdateContentParams analysisUpdateContentParams;
  plugin.RequestParams broadcastedRequest;
  Map<PluginInfo, Future<plugin.Response>> broadcastResults;

  @override
  String get byteStorePath {
    fail('Unexpected invocation of byteStorePath');
  }

  @override
  InstrumentationService get instrumentationService {
    fail('Unexpected invocation of instrumentationService');
  }

  @override
  NotificationManager get notificationManager {
    fail('Unexpected invocation of notificationManager');
  }

  @override
  List<PluginInfo> get plugins {
    fail('Unexpected invocation of plugins');
  }

  @override
  ResourceProvider get resourceProvider {
    fail('Unexpected invocation of resourceProvider');
  }

  @override
  String get sdkPath {
    fail('Unexpected invocation of sdkPath');
  }

  @override
  Future<Null> addPluginToContextRoot(
      analyzer.ContextRoot contextRoot, String path) async {
    fail('Unexpected invocation of addPluginToContextRoot');
  }

  @override
  Map<PluginInfo, Future<plugin.Response>> broadcastRequest(
      plugin.RequestParams params,
      {analyzer.ContextRoot contextRoot}) {
    broadcastedRequest = params;
    return broadcastResults ?? <PluginInfo, Future<plugin.Response>>{};
  }

  @override
  Future<List<Future<plugin.Response>>> broadcastWatchEvent(
      WatchEvent watchEvent) async {
    return <Future<plugin.Response>>[];
  }

  @override
  List<String> pathsFor(String pluginPath) {
    fail('Unexpected invocation of pathsFor');
  }

  @override
  List<PluginInfo> pluginsForContextRoot(analyzer.ContextRoot contextRoot) {
    fail('Unexpected invocation of pluginsForContextRoot');
  }

  @override
  void recordPluginFailure(String hostPackageName, String message) {
    fail('Unexpected invocation of recordPluginFailure');
  }

  @override
  void removedContextRoot(analyzer.ContextRoot contextRoot) {
    fail('Unexpected invocation of removedContextRoot');
  }

  @override
  Future<Null> restartPlugins() async {
    // Nothing to restart.
    return null;
  }

  @override
  void setAnalysisSetPriorityFilesParams(
      plugin.AnalysisSetPriorityFilesParams params) {
    analysisSetPriorityFilesParams = params;
  }

  @override
  void setAnalysisSetSubscriptionsParams(
      plugin.AnalysisSetSubscriptionsParams params) {
    analysisSetSubscriptionsParams = params;
  }

  @override
  void setAnalysisUpdateContentParams(
      plugin.AnalysisUpdateContentParams params) {
    analysisUpdateContentParams = params;
  }

  @override
  Future<List<Null>> stopAll() async {
    fail('Unexpected invocation of stopAll');
  }
}
