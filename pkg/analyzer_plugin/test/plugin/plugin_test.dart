// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:isolate';

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/protocol/protocol_internal.dart';
import 'package:meta/meta.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'mocks.dart';

void main() {
  defineReflectiveTests(ServerPluginTest);
}

abstract class AbstractPluginTest with ResourceProviderMixin {
  final MockChannel channel = MockChannel();
  late final ServerPlugin plugin;

  Folder get byteStoreRoot => getFolder('/byteStore');

  Version get pluginSpecificationVersion => Version(0, 1, 0);

  Folder get sdkRoot => getFolder('/sdk');

  ServerPlugin createPlugin();

  @mustCallSuper
  Future<void> setUp() async {
    createMockSdk(
      resourceProvider: resourceProvider,
      root: sdkRoot,
    );

    plugin = createPlugin();
    plugin.start(channel);

    await plugin.handlePluginVersionCheck(
      PluginVersionCheckParams(
        byteStoreRoot.path,
        sdkRoot.path,
        pluginSpecificationVersion.canonicalizedVersion,
      ),
    );
  }
}

@reflectiveTest
class ServerPluginTest extends AbstractPluginTest {
  late String packagePath1;
  late String filePath1;
  late ContextRoot contextRoot1;

  late String packagePath2;
  late String filePath2;
  late ContextRoot contextRoot2;

  /// Asserts that [params] is valid to send to an [Isolate] started with
  /// [Isolate.spawnUri].
  Future<void> assertValidForIsolateSend(RequestParams params) async {
    const isolateSource = r'''
import 'dart:isolate';

void main(List<String> args, SendPort sendPort) {
  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);
  receivePort.listen((msg) => sendPort.send('ECHO: $msg'));
}
        ''';
    final isolateUri = Uri.dataFromString(isolateSource, encoding: utf8);
    final receivePort = ReceivePort();
    final isolate =
        await Isolate.spawnUri(isolateUri, [], receivePort.sendPort);
    final sendPort = (await receivePort.first) as SendPort;
    try {
      sendPort.send(params.toJson());
    } catch (e) {
      fail('Failed to send ${params.runtimeType} across Isolate: $e');
    }
    isolate.kill();
  }

  @override
  ServerPlugin createPlugin() {
    return _TestServerPlugin(resourceProvider);
  }

  @override
  Future<void> setUp() async {
    await super.setUp();
    packagePath1 = convertPath('/package1');
    filePath1 = join(packagePath1, 'lib', 'test.dart');
    newFile(filePath1, '');
    contextRoot1 = ContextRoot(packagePath1, <String>[]);

    packagePath2 = convertPath('/package2');
    filePath2 = join(packagePath2, 'lib', 'test.dart');
    newFile(filePath2, '');
    contextRoot2 = ContextRoot(packagePath2, <String>[]);
  }

  Future<void> test_handleAnalysisGetNavigation() async {
    var result = await plugin
        .handleAnalysisGetNavigation(AnalysisGetNavigationParams('', 1, 2));
    expect(result, isNotNull);
  }

  Future<void> test_handleAnalysisHandleWatchEvents() async {
    var result = await plugin
        .handleAnalysisHandleWatchEvents(AnalysisHandleWatchEventsParams([]));
    expect(result, isNotNull);
  }

  Future<void> test_handleAnalysisSetPriorityFiles() async {
    await plugin.handleAnalysisSetContextRoots(
        AnalysisSetContextRootsParams([contextRoot1]));

    var result = await plugin.handleAnalysisSetPriorityFiles(
        AnalysisSetPriorityFilesParams([filePath1]));
    expect(result, isNotNull);
  }

  Future<void> test_handleAnalysisSetSubscriptions() async {
    await plugin.handleAnalysisSetContextRoots(
        AnalysisSetContextRootsParams([contextRoot1]));
    expect(plugin.subscriptionManager.servicesForFile(filePath1), isEmpty);

    var result = await plugin
        .handleAnalysisSetSubscriptions(AnalysisSetSubscriptionsParams({
      AnalysisService.OUTLINE: [filePath1]
    }));
    expect(result, isNotNull);
    expect(plugin.subscriptionManager.servicesForFile(filePath1),
        [AnalysisService.OUTLINE]);
  }

  Future<void> test_handleAnalysisUpdateContent_addChangeRemove() async {
    await plugin.handleAnalysisSetContextRoots(
        AnalysisSetContextRootsParams([contextRoot1]));
    var addResult = await plugin.handleAnalysisUpdateContent(
        AnalysisUpdateContentParams(
            {filePath1: AddContentOverlay('class C {}')}));
    expect(addResult, isNotNull);
    var changeResult =
        await plugin.handleAnalysisUpdateContent(AnalysisUpdateContentParams({
      filePath1: ChangeContentOverlay([SourceEdit(7, 0, ' extends Object')])
    }));
    expect(changeResult, isNotNull);
    var removeResult = await plugin.handleAnalysisUpdateContent(
        AnalysisUpdateContentParams({filePath1: RemoveContentOverlay()}));
    expect(removeResult, isNotNull);
  }

  Future<void> test_handleAnalysisUpdateContent_changeNoAdd() async {
    await plugin.handleAnalysisSetContextRoots(
        AnalysisSetContextRootsParams([contextRoot1]));
    try {
      await plugin.handleAnalysisUpdateContent(AnalysisUpdateContentParams({
        filePath1: ChangeContentOverlay([SourceEdit(7, 0, ' extends Object')])
      }));
      fail('Expected RequestFailure');
    } on RequestFailure {
      // Expected
    }
  }

  Future<void> test_handleAnalysisUpdateContent_invalidChange() async {
    await plugin.handleAnalysisSetContextRoots(
        AnalysisSetContextRootsParams([contextRoot1]));
    await plugin.handleAnalysisUpdateContent(AnalysisUpdateContentParams(
        {filePath1: AddContentOverlay('class C {}')}));
    try {
      await plugin.handleAnalysisUpdateContent(AnalysisUpdateContentParams({
        filePath1: ChangeContentOverlay([SourceEdit(20, 5, 'class D {}')])
      }));
      fail('Expected RequestFailure');
    } on RequestFailure {
      // Expected
    }
  }

  Future<void> test_handleCompletionGetSuggestions() async {
    await plugin.handleAnalysisSetContextRoots(
        AnalysisSetContextRootsParams([contextRoot1]));

    var result = await plugin.handleCompletionGetSuggestions(
        CompletionGetSuggestionsParams(filePath1, 12));
    expect(result, isNotNull);
  }

  Future<void> test_handleEditGetAssists() async {
    await plugin.handleAnalysisSetContextRoots(
        AnalysisSetContextRootsParams([contextRoot1]));

    var result = await plugin
        .handleEditGetAssists(EditGetAssistsParams(filePath1, 10, 0));
    expect(result, isNotNull);
  }

  Future<void> test_handleEditGetAvailableRefactorings() async {
    await plugin.handleAnalysisSetContextRoots(
        AnalysisSetContextRootsParams([contextRoot1]));

    var result = await plugin.handleEditGetAvailableRefactorings(
        EditGetAvailableRefactoringsParams(filePath1, 10, 0));
    expect(result, isNotNull);
  }

  Future<void> test_handleEditGetFixes() async {
    await plugin.handleAnalysisSetContextRoots(
        AnalysisSetContextRootsParams([contextRoot1]));

    var result =
        await plugin.handleEditGetFixes(EditGetFixesParams(filePath1, 13));
    expect(result, isNotNull);
  }

  @failingTest
  Future<void> test_handleEditGetRefactoring() async {
    await plugin.handleAnalysisSetContextRoots(
        AnalysisSetContextRootsParams([contextRoot1]));

    var result = await plugin.handleEditGetRefactoring(EditGetRefactoringParams(
        RefactoringKind.RENAME, filePath1, 7, 0, false));
    expect(result, isNotNull);
  }

  Future<void> test_handlePluginShutdown() async {
    var result = await plugin.handlePluginShutdown(PluginShutdownParams());
    expect(result, isNotNull);
  }

  Future<void> test_handlePluginVersionCheck() async {
    var result = await plugin.handlePluginVersionCheck(
        PluginVersionCheckParams('byteStorePath', 'sdkPath', '0.1.0'));
    expect(result, isNotNull);
    expect(result.interestingFiles, ['*.dart']);
    expect(result.isCompatible, isTrue);
    expect(result.name, 'Test Plugin');
    expect(result.version, '0.1.0');
  }

  @failingTest
  void test_isCompatibleWith() {
    fail('Not yet implemented.');
  }

  Future<void> test_isolateSend_analysisGetNavigation() async {
    await assertValidForIsolateSend(AnalysisGetNavigationParams('', 1, 2));
  }

  Future<void> test_isolateSend_analysisHandleWatchEvents() async {
    await assertValidForIsolateSend(AnalysisHandleWatchEventsParams([]));
  }

  Future<void> test_isolateSend_analysisSetPriorityFiles() async {
    await assertValidForIsolateSend(
        AnalysisSetPriorityFilesParams([filePath1]));
  }

  Future<void> test_isolateSend_analysisSetSubscriptions() async {
    await assertValidForIsolateSend(AnalysisSetSubscriptionsParams({
      AnalysisService.OUTLINE: [filePath1]
    }));
  }

  Future<void> test_isolateSend_analysisUpdateContent_add() async {
    await assertValidForIsolateSend(AnalysisUpdateContentParams(
        {filePath1: AddContentOverlay('class C {}')}));
  }

  Future<void> test_isolateSend_analysisUpdateContent_change() async {
    await assertValidForIsolateSend(AnalysisUpdateContentParams({
      filePath1: ChangeContentOverlay([SourceEdit(7, 0, ' extends Object')])
    }));
  }

  Future<void> test_isolateSend_analysisUpdateContent_remove() async {
    await assertValidForIsolateSend(
        AnalysisUpdateContentParams({filePath1: RemoveContentOverlay()}));
  }

  Future<void> test_isolateSend_completionGetSuggestions() async {
    await assertValidForIsolateSend(
        CompletionGetSuggestionsParams(filePath1, 12));
  }

  Future<void> test_isolateSend_editGetAssists() async {
    await assertValidForIsolateSend(EditGetAssistsParams(filePath1, 10, 0));
  }

  Future<void> test_isolateSend_editGetAvailableRefactorings() async {
    await assertValidForIsolateSend(
        EditGetAvailableRefactoringsParams(filePath1, 10, 0));
  }

  Future<void> test_isolateSend_editGetFixes() async {
    await assertValidForIsolateSend(EditGetFixesParams(filePath1, 13));
  }

  Future<void> test_isolateSend_editGetRefactoring() async {
    await assertValidForIsolateSend(EditGetRefactoringParams(
        RefactoringKind.RENAME, filePath1, 7, 0, false));
  }

  Future<void> test_isolateSend_pluginShutdown() async {
    await assertValidForIsolateSend(PluginShutdownParams());
  }

  Future<void> test_isolateSend_pluginVersionCheck() async {
    await assertValidForIsolateSend(
        PluginVersionCheckParams('byteStorePath', 'sdkPath', '0.1.0'));
  }

  Future<void> test_isolateSend_setContextRoots() async {
    await assertValidForIsolateSend(
        AnalysisSetContextRootsParams([contextRoot1]));
  }

  void test_onDone() {
    channel.sendDone();
  }

  void test_onError() {
    channel.sendError(ArgumentError(), StackTrace.fromString(''));
  }

  Future<void> test_onRequest_analysisGetNavigation() async {
    var result =
        await channel.sendRequest(AnalysisGetNavigationParams('', 1, 2));
    expect(result, isNotNull);
  }

  Future<void> test_onRequest_analysisHandleWatchEvents() async {
    var result = await channel.sendRequest(AnalysisHandleWatchEventsParams([]));
    expect(result, isNotNull);
  }

  Future<void> test_onRequest_analysisSetContextRoots() async {
    final plugin = this.plugin as _TestServerPlugin;

    final analyzedPaths = <String>[];
    plugin.analyzeFileHandler = ({
      required AnalysisContext analysisContext,
      required String path,
    }) {
      analyzedPaths.add(path);
    };

    var result = await channel
        .sendRequest(AnalysisSetContextRootsParams([contextRoot1]));
    expect(result, isNotNull);

    expect(plugin.invoked_afterNewContextCollection, isTrue);
    expect(analyzedPaths, [getFile('/package1/lib/test.dart').path]);
  }

  Future<void> test_onRequest_analysisSetPriorityFiles() async {
    await channel.sendRequest(AnalysisSetContextRootsParams([contextRoot1]));

    var result =
        await channel.sendRequest(AnalysisSetPriorityFilesParams([filePath1]));
    expect(result, isNotNull);
  }

  Future<void> test_onRequest_analysisSetSubscriptions() async {
    await channel.sendRequest(AnalysisSetContextRootsParams([contextRoot1]));
    expect(plugin.subscriptionManager.servicesForFile(filePath1), isEmpty);

    var result = await channel.sendRequest(AnalysisSetSubscriptionsParams({
      AnalysisService.OUTLINE: [filePath1]
    }));
    expect(result, isNotNull);
    expect(plugin.subscriptionManager.servicesForFile(filePath1),
        [AnalysisService.OUTLINE]);
  }

  Future<void> test_onRequest_analysisUpdateContent_addChangeRemove() async {
    await channel.sendRequest(AnalysisSetContextRootsParams([contextRoot1]));
    var addResult = await channel.sendRequest(AnalysisUpdateContentParams(
        {filePath1: AddContentOverlay('class C {}')}));
    expect(addResult, isNotNull);
    var changeResult = await channel.sendRequest(AnalysisUpdateContentParams({
      filePath1: ChangeContentOverlay([SourceEdit(7, 0, ' extends Object')])
    }));
    expect(changeResult, isNotNull);
    var removeResult = await channel.sendRequest(
        AnalysisUpdateContentParams({filePath1: RemoveContentOverlay()}));
    expect(removeResult, isNotNull);
  }

  Future<void> test_onRequest_completionGetSuggestions() async {
    await channel.sendRequest(AnalysisSetContextRootsParams([contextRoot1]));

    var result = await channel
        .sendRequest(CompletionGetSuggestionsParams(filePath1, 12));
    expect(result, isNotNull);
  }

  Future<void> test_onRequest_editGetAssists() async {
    await channel.sendRequest(AnalysisSetContextRootsParams([contextRoot1]));

    var result =
        await channel.sendRequest(EditGetAssistsParams(filePath1, 10, 0));
    expect(result, isNotNull);
  }

  Future<void> test_onRequest_editGetAvailableRefactorings() async {
    await channel.sendRequest(AnalysisSetContextRootsParams([contextRoot1]));

    var result = await channel
        .sendRequest(EditGetAvailableRefactoringsParams(filePath1, 10, 0));
    expect(result, isNotNull);
  }

  Future<void> test_onRequest_editGetFixes() async {
    await channel.sendRequest(AnalysisSetContextRootsParams([contextRoot1]));

    var result = await channel.sendRequest(EditGetFixesParams(filePath1, 13));
    expect(result, isNotNull);
  }

  Future<void> test_onRequest_editGetRefactoring() async {
    await channel.sendRequest(AnalysisSetContextRootsParams([contextRoot1]));

    var result = await channel.sendRequest(EditGetRefactoringParams(
        RefactoringKind.RENAME, filePath1, 7, 0, false));
    expect(result, isNotNull);
  }

  Future<void> test_onRequest_pluginShutdown() async {
    var result = await channel.sendRequest(PluginShutdownParams());
    expect(result, isNotNull);
  }

  Future<void> test_onRequest_pluginVersionCheck() async {
    var response = await channel.sendRequest(
        PluginVersionCheckParams('byteStorePath', 'sdkPath', '0.1.0'));
    var result = PluginVersionCheckResult.fromResponse(response);
    expect(result, isNotNull);
    expect(result.interestingFiles, ['*.dart']);
    expect(result.isCompatible, isTrue);
    expect(result.name, 'Test Plugin');
    expect(result.version, '0.1.0');
  }

  void test_sendNotificationsForFile() {
    var service1 = AnalysisService.FOLDING;
    var service2 = AnalysisService.NAVIGATION;
    var service3 = AnalysisService.OUTLINE;
    plugin.subscriptionManager.setSubscriptions({
      service1: [filePath1, filePath2],
      service2: [filePath1],
      service3: [filePath2]
    });
    plugin.sendNotificationsForFile(filePath1);
    var notifications = (plugin as _TestServerPlugin).sentNotifications;
    expect(notifications, hasLength(1));
    var services = notifications[filePath1];
    expect(services, unorderedEquals([service1, service2]));
  }

  void test_sendNotificationsForSubscriptions() {
    var subscriptions = <String, List<AnalysisService>>{};

    plugin.sendNotificationsForSubscriptions(subscriptions);
    var notifications = (plugin as _TestServerPlugin).sentNotifications;
    expect(notifications, hasLength(subscriptions.length));
    for (var path in subscriptions.keys) {
      var subscribedServices = subscriptions[path];
      var notifiedServices = notifications[path];
      expect(notifiedServices, isNotNull,
          reason: 'Not notified for file $path');
      expect(notifiedServices, unorderedEquals(subscribedServices!),
          reason: 'Wrong notifications for file $path');
    }
  }
}

class _TestServerPlugin extends MockServerPlugin {
  Map<String, List<AnalysisService>> sentNotifications =
      <String, List<AnalysisService>>{};

  bool invoked_afterNewContextCollection = false;

  void Function({
    required AnalysisContext analysisContext,
    required String path,
  })? analyzeFileHandler;

  _TestServerPlugin(super.resourceProvider);

  @override
  Future<void> afterNewContextCollection({
    required AnalysisContextCollection contextCollection,
  }) async {
    invoked_afterNewContextCollection = true;
    return super.afterNewContextCollection(
      contextCollection: contextCollection,
    );
  }

  @override
  Future<void> analyzeFile({
    required AnalysisContext analysisContext,
    required String path,
  }) async {
    analyzeFileHandler?.call(
      analysisContext: analysisContext,
      path: path,
    );
  }

  @override
  Future<void> sendFoldingNotification(String path) {
    _sent(path, AnalysisService.FOLDING);
    return Future.value();
  }

  @override
  Future<void> sendHighlightsNotification(String path) {
    _sent(path, AnalysisService.HIGHLIGHTS);
    return Future.value();
  }

  @override
  Future<void> sendNavigationNotification(String path) {
    _sent(path, AnalysisService.NAVIGATION);
    return Future.value();
  }

  @override
  Future<void> sendOccurrencesNotification(String path) {
    _sent(path, AnalysisService.OCCURRENCES);
    return Future.value();
  }

  @override
  Future<void> sendOutlineNotification(String path) {
    _sent(path, AnalysisService.OUTLINE);
    return Future.value();
  }

  void _sent(String path, AnalysisService service) {
    sentNotifications.putIfAbsent(path, () => <AnalysisService>[]).add(service);
  }
}
