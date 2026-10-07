// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:analysis_server/src/plugin/plugin_isolate.dart';
import 'package:analysis_server/src/session_logger/session_logger.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/analysis/context_root.dart';
import 'package:analyzer/src/workspace/basic.dart';
import 'package:analyzer_plugin/channel/channel.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart'
    hide ContextRoot;
import 'package:analyzer_testing/resource_provider_mixin.dart';
import 'package:analyzer_testing/utilities/extensions/resource_provider.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../mocks.dart';
import 'plugin_test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PluginIsolateTest);
    defineReflectiveTests(PluginSessionTest);
    defineReflectiveTests(PluginSessionFromDiskTest);
  });
}

@reflectiveTest
class PluginIsolateTest with ResourceProviderMixin, _ContextRoot {
  late TestNotificationManager notificationManager;
  String pluginPath = '/pluginDir';
  String executionPath = '/pluginDir/bin/plugin.dart';
  String packagesPath = '/pluginDir/.packages';
  late PluginIsolate pluginIsolate;

  void setUp() {
    notificationManager = TestNotificationManager();
    pluginIsolate = PluginIsolate(
      pluginPath,
      executionPath,
      packagesPath,
      notificationManager,
      InstrumentationService.NULL_SERVICE,
      SessionLogger(),
      isLegacy: true,
    );
  }

  void test_addContextRoot() {
    var optionsFile = getFile('/pkg1/analysis_options.yaml');
    var contextRoot = _newContextRoot('/pkg1', optionsFile: optionsFile);
    var session = PluginSession(pluginIsolate);
    var channel = TestServerCommunicationChannel(session);
    pluginIsolate.currentSession = session;
    pluginIsolate.addContextRoot(contextRoot);
    expect(pluginIsolate.contextRoots, [contextRoot]);
    pluginIsolate.addContextRoot(contextRoot);
    expect(pluginIsolate.contextRoots, [contextRoot]);
    var sentRequests = channel.sentRequests;
    // Two requests: `analysis.setContextRoots` and
    // `analysis.setAnalysisRoots`; adding the same context root again is a
    // no-op.
    expect(sentRequests, hasLength(2));
    expect(sentRequests[0].method, 'analysis.setContextRoots');
    var roots1 = sentRequests[0].params['roots'] as List<Map>;
    expect(roots1[0]['optionsFile'], optionsFile.path);
    expect(sentRequests[1].method, 'analysis.setAnalysisRoots');
    var roots2 = sentRequests[1].params['included'] as List<String>;
    expect(roots2, [contextRoot.root.path]);
  }

  void test_creation() {
    expect(pluginIsolate.executionPath, executionPath);
    expect(pluginIsolate.contextRoots, isEmpty);
    expect(pluginIsolate.currentSession, isNull);
  }

  void test_removeContextRoot() {
    var contextRoot1 = _newContextRoot('/pkg1');
    var contextRoot2 = _newContextRoot('/pkg2');
    pluginIsolate.addContextRoot(contextRoot1);
    expect(pluginIsolate.contextRoots, unorderedEquals([contextRoot1]));
    pluginIsolate.addContextRoot(contextRoot2);
    expect(
      pluginIsolate.contextRoots,
      unorderedEquals([contextRoot1, contextRoot2]),
    );
    pluginIsolate.removeContextRoot(contextRoot1);
    expect(pluginIsolate.contextRoots, unorderedEquals([contextRoot2]));
    pluginIsolate.removeContextRoot(contextRoot2);
    expect(pluginIsolate.contextRoots, isEmpty);
  }

  void test_setAnalysisRoots_beforeAddContextRoot() {
    var session = PluginSession(pluginIsolate);
    var channel = TestServerCommunicationChannel(session);
    pluginIsolate.currentSession = session;

    // Client sets analysis roots before the plugin has any context roots.
    pluginIsolate.setAnalysisRoots(
      AnalysisSetAnalysisRootsParams([convertPath('/workspace')], []),
    );

    // No request should be sent when there are no context roots yet.
    expect(channel.sentRequests, isEmpty);

    // Adding a context root now should compute the narrowed analysis roots.
    var contextRoot = _newContextRoot('/workspace/pkg1');
    pluginIsolate.addContextRoot(contextRoot);

    var sentRequests = channel.sentRequests;
    // Two requests: `analysis.setContextRoots` and
    // `analysis.setAnalysisRoots` (setting analysis roots earlier sent no
    // requests because context roots were empty).
    expect(sentRequests, hasLength(2));
    expect(sentRequests[0].method, 'analysis.setContextRoots');
    expect(sentRequests[1].method, 'analysis.setAnalysisRoots');
    var roots = sentRequests[1].params['included'] as List<String>;
    expect(roots, [contextRoot.root.path]);
  }

  void test_setAnalysisRoots_excluded() {
    var contextRoot = _newContextRoot('/workspace/pkg1');
    var session = PluginSession(pluginIsolate);
    var channel = TestServerCommunicationChannel(session);
    pluginIsolate.currentSession = session;
    pluginIsolate.addContextRoot(contextRoot);

    var excludedPath = convertPath('/workspace/pkg1/test');
    pluginIsolate.setAnalysisRoots(
      AnalysisSetAnalysisRootsParams(
        [convertPath('/workspace')],
        [excludedPath],
      ),
    );

    var sentRequests = channel.sentRequests;
    // Four requests:
    // 0: 'analysis.setContextRoots'
    // 1: 'analysis.setAnalysisRoots'
    // 2: 'analysis.setContextRoots'
    // 3: 'analysis.setAnalysisRoots'
    expect(sentRequests, hasLength(4));
    var roots = sentRequests[3].params['included'] as List<String>;
    expect(roots, [contextRoot.root.path]);
    var excluded = sentRequests[3].params['excluded'] as List<String>;
    expect(excluded, [excludedPath]);
  }

  void test_setAnalysisRoots_narrowedToContextRoot() {
    var contextRoot = _newContextRoot('/workspace/pkg1');
    var session = PluginSession(pluginIsolate);
    var channel = TestServerCommunicationChannel(session);
    pluginIsolate.currentSession = session;
    pluginIsolate.addContextRoot(contextRoot);

    // Client sets analysis roots to workspace root '/workspace'.
    pluginIsolate.setAnalysisRoots(
      AnalysisSetAnalysisRootsParams([convertPath('/workspace')], []),
    );

    var sentRequests = channel.sentRequests;
    // Four requests:
    // 0: 'analysis.setContextRoots'
    // 1: 'analysis.setAnalysisRoots'
    // 2: 'analysis.setContextRoots'
    // 3: 'analysis.setAnalysisRoots'
    expect(sentRequests, hasLength(4));
    expect(sentRequests[3].method, 'analysis.setAnalysisRoots');
    var roots = sentRequests[3].params['included'] as List<String>;
    // The included root sent to the plugin should be narrowed to the context
    // root, not the client workspace root.
    expect(roots, [contextRoot.root.path]);
  }

  void test_setAnalysisRoots_subpath() {
    var contextRoot = _newContextRoot('/workspace/pkg1');
    var session = PluginSession(pluginIsolate);
    var channel = TestServerCommunicationChannel(session);
    pluginIsolate.currentSession = session;
    pluginIsolate.addContextRoot(contextRoot);

    var subpath = convertPath('/workspace/pkg1/lib');
    pluginIsolate.setAnalysisRoots(
      AnalysisSetAnalysisRootsParams([subpath], []),
    );

    var sentRequests = channel.sentRequests;
    // Four requests:
    // 0: 'analysis.setContextRoots'
    // 1: 'analysis.setAnalysisRoots'
    // 2: 'analysis.setContextRoots'
    // 3: 'analysis.setAnalysisRoots'
    expect(sentRequests, hasLength(4));
    var roots = sentRequests[3].params['included'] as List<String>;
    expect(roots, [subpath]);
  }

  void test_setAnalysisRoots_unrelatedWorkspaceFolder() {
    var contextRoot = _newContextRoot('/workspace1/pkg1');
    var session = PluginSession(pluginIsolate);
    var channel = TestServerCommunicationChannel(session);
    pluginIsolate.currentSession = session;
    pluginIsolate.addContextRoot(contextRoot);

    // Client sets analysis roots to a different workspace folder.
    pluginIsolate.setAnalysisRoots(
      AnalysisSetAnalysisRootsParams([convertPath('/workspace2')], []),
    );

    var sentRequests = channel.sentRequests;
    // Four requests:
    // 0: 'analysis.setContextRoots'
    // 1: 'analysis.setAnalysisRoots'
    // 2: 'analysis.setContextRoots'
    // 3: 'analysis.setAnalysisRoots'
    expect(sentRequests, hasLength(4));
    var roots = sentRequests[3].params['included'] as List<String>;
    expect(roots, isEmpty);
  }

  @failingTest
  Future<void> test_start_notRunning() {
    fail('Not tested');
  }

  Future<void> test_start_running() async {
    pluginIsolate.currentSession = PluginSession(pluginIsolate);
    expect(() => pluginIsolate.start('', ''), throwsStateError);
  }

  void test_stop_notRunning() {
    expect(() => pluginIsolate.stop(), throwsStateError);
  }

  Future<void> test_stop_running() async {
    var session = PluginSession(pluginIsolate);
    var channel = TestServerCommunicationChannel(session);
    pluginIsolate.currentSession = session;
    await pluginIsolate.stop();
    expect(pluginIsolate.currentSession, isNull);
    expect(channel.sentRequests, hasLength(1));
    expect(channel.sentRequests[0].method, 'plugin.shutdown');
  }
}

@reflectiveTest
class PluginSessionFromDiskTest extends PluginTestSupport {
  @SkippedTest(
    reason: 'flaky timeouts',
    issue: 'https://github.com/dart-lang/sdk/issues/38629',
  )
  Future<void> test_start_notRunning() async {
    await withPlugin(
      test: (String pluginPath) async {
        var packagesPath = path.join(pluginPath, '.packages');
        var mainPath = path.join(pluginPath, 'bin', 'plugin.dart');
        var byteStorePath = path.join(pluginPath, 'byteStore');
        io.Directory(byteStorePath).createSync();
        var pluginIsolate = PluginIsolate(
          pluginPath,
          mainPath,
          packagesPath,
          notificationManager,
          InstrumentationService.NULL_SERVICE,
          SessionLogger(),
          isLegacy: true,
        );
        var session = PluginSession(pluginIsolate);
        pluginIsolate.currentSession = session;
        expect(await session.start(byteStorePath, ''), isTrue);
        await session.stop();
      },
    );
  }
}

@reflectiveTest
class PluginSessionTest with ResourceProviderMixin {
  late TestNotificationManager notificationManager;
  late String pluginPath;
  late String executionPath;
  late String packagesPath;
  late String sdkPath;
  late PluginIsolate pluginIsolate;
  late PluginSession session;

  void setUp() {
    notificationManager = TestNotificationManager();
    pluginPath = resourceProvider.convertPath('/pluginDir');
    executionPath = resourceProvider.convertPath('/pluginDir/bin/plugin.dart');
    packagesPath = resourceProvider.convertPath('/pluginDir/.packages');
    sdkPath = resourceProvider.convertPath('/sdk');
    pluginIsolate = PluginIsolate(
      pluginPath,
      executionPath,
      packagesPath,
      notificationManager,
      InstrumentationService.NULL_SERVICE,
      SessionLogger(),
      isLegacy: true,
    );
    session = PluginSession(pluginIsolate);
  }

  void test_handleNotification() {
    var notification = AnalysisErrorsParams(
      '/test.dart',
      <AnalysisError>[],
    ).toNotification();
    expect(notificationManager.notifications, hasLength(0));
    session.handleNotification(notification);
    expect(notificationManager.notifications, hasLength(1));
    expect(notificationManager.notifications[0], notification);
  }

  void test_handleOnDone() {
    var channel = TestServerCommunicationChannel(session);
    session.handleOnDone();
    expect(channel.closeCount, 1);
    expect(session.pluginStoppedCompleter.isCompleted, isTrue);
  }

  void test_handleOnError() {
    session.handleOnError(<String>['message', 'trace']);
    expect(
      notificationManager.pluginErrors.first,
      'An error occurred while executing an analyzer plugin: message\ntrace',
    );
  }

  Future<void> test_handleResponse() async {
    TestServerCommunicationChannel(session);
    var response = PluginVersionCheckResult(
      true,
      'name',
      'version',
      <String>[],
      contactInfo: 'contactInfo',
    ).toResponse('0', 1);
    var future = session.sendRequest(PluginVersionCheckParams('', '', ''));
    expect(session.pendingRequests, hasLength(1));
    session.handleResponse(response);
    expect(session.pendingRequests, hasLength(0));
    var result = await future;
    expect(result, same(response));
  }

  Future<void> test_handleResponse_withError() async {
    TestServerCommunicationChannel(session);
    var response = Response(
      '0' /* id */,
      1 /* requestTime */,
      error: RequestError(
        RequestErrorCode.PLUGIN_ERROR,
        'exception',
        stackTrace: 'some stackTrace',
      ),
    );

    var responseFuture = session.sendRequest(
      PluginVersionCheckParams('', '', ''),
    );
    session.handleResponse(response);
    await responseFuture;
    expect(
      notificationManager.pluginErrors,
      equals([
        'An error occurred while executing an analyzer plugin: exception\n'
            'some stackTrace',
      ]),
    );
  }

  void test_nextRequestId() {
    expect(session.requestId, 0);
    expect(session.nextRequestId, '0');
    expect(session.requestId, 1);
  }

  void test_sendRequest() {
    var channel = TestServerCommunicationChannel(session);
    session.sendRequest(PluginVersionCheckParams('', '', ''));
    expect(channel.sentRequests, hasLength(1));
    expect(channel.sentRequests[0].method, 'plugin.versionCheck');
  }

  Future<void> test_start_notCompatible() async {
    session.isCompatible = false;
    expect(
      await session.start(path.join(pluginPath, 'byteStore'), sdkPath),
      isFalse,
    );
    expect(
      notificationManager.pluginErrors.first,
      startsWith(
        'An error occurred while executing an analyzer plugin: Plugin is not '
        'compatible.',
      ),
    );
  }

  Future<void> test_start_running() async {
    TestServerCommunicationChannel(session);
    expect(() => session.start('', ''), throwsStateError);
  }

  void test_stop_notRunning() {
    expect(() => session.stop(), throwsStateError);
  }

  Future<void> test_stop_running() async {
    var channel = TestServerCommunicationChannel(session);
    await session.stop();
    expect(channel.sentRequests, hasLength(1));
    expect(channel.sentRequests[0].method, 'plugin.shutdown');
  }
}

class TestServerCommunicationChannel implements ServerCommunicationChannel {
  final PluginSession session;
  int closeCount = 0;
  List<Request> sentRequests = <Request>[];

  new(this.session) {
    session.channel = this;
  }

  @override
  void close() {
    closeCount++;
  }

  @override
  void kill() {
    fail('Unexpected invocation of kill');
  }

  @override
  void listen(
    void Function(Response response) onResponse,
    void Function(Notification notification) onNotification, {
    void Function(dynamic error)? onError,
    void Function()? onDone,
  }) {
    fail('Unexpected invocation of listen');
  }

  @override
  void sendRequest(Request request) {
    sentRequests.add(request);
    if (request.method == 'plugin.shutdown') {
      session.handleOnDone();
    }
  }
}

mixin _ContextRoot on ResourceProviderMixin {
  ContextRootImpl _newContextRoot(String rootPath, {File? optionsFile}) {
    rootPath = convertPath(rootPath);
    return ContextRootImpl(
      resourceProvider,
      resourceProvider.getFolder(rootPath),
      BasicWorkspace.find(resourceProvider, Packages.empty, rootPath),
      optionsFile: optionsFile,
    );
  }
}
