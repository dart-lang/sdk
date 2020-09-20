// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'mocks.dart';

void main() {
  defineReflectiveTests(ServerPluginTest);
}

@reflectiveTest
class ServerPluginTest with ResourceProviderMixin {
  MockChannel channel;
  _TestServerPlugin plugin;

  String packagePath1;
  String filePath1;
  ContextRoot contextRoot1;

  String packagePath2;
  String filePath2;
  ContextRoot contextRoot2;

  void setUp() {
    packagePath1 = convertPath('/package1');
    filePath1 = join(packagePath1, 'lib', 'test.dart');
    newFile(filePath1);
    contextRoot1 = ContextRoot(packagePath1, <String>[]);

    packagePath2 = convertPath('/package2');
    filePath2 = join(packagePath2, 'lib', 'test.dart');
    newFile(filePath2);
    contextRoot2 = ContextRoot(packagePath2, <String>[]);

    channel = MockChannel();
    plugin = _TestServerPlugin(resourceProvider);
    plugin.start(channel);
  }

  Future<void> test_contextRootContaining_insideRoot() async {
    await plugin.handleAnalysisSetContextRoots(
        AnalysisSetContextRootsParams([contextRoot1]));

    expect(plugin.contextRootContaining(filePath1), isNotNull);
  }

  void test_contextRootContaining_noRoots() {
    expect(plugin.contextRootContaining(filePath1), isNull);
  }

  Future<void> test_contextRootContaining_outsideRoot() async {
    await plugin.handleAnalysisSetContextRoots(
        AnalysisSetContextRootsParams([contextRoot1]));

    expect(plugin.contextRootContaining(filePath2), isNull);
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

  Future<void> test_handleAnalysisSetContextRoots() async {
    var result = await plugin.handleAnalysisSetContextRoots(
        AnalysisSetContextRootsParams([contextRoot1]));
    expect(result, isNotNull);
    var driver = _getDriver(contextRoot1);
    expect(driver, isNotNull);
    expect((driver as MockAnalysisDriver).addedFiles, hasLength(1));
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
    var result = await channel
        .sendRequest(AnalysisSetContextRootsParams([contextRoot1]));
    expect(result, isNotNull);
    var driver = _getDriver(contextRoot1);
    expect(driver, isNotNull);
    expect((driver as MockAnalysisDriver).addedFiles, hasLength(1));
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
    var response = (await channel.sendRequest(
        PluginVersionCheckParams('byteStorePath', 'sdkPath', '0.1.0')));
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
    var notifications = plugin.sentNotifications;
    expect(notifications, hasLength(1));
    var services = notifications[filePath1];
    expect(services, unorderedEquals([service1, service2]));
  }

  void test_sendNotificationsForSubscriptions() {
    var subscriptions = <String, List<AnalysisService>>{};

    plugin.sendNotificationsForSubscriptions(subscriptions);
    var notifications = plugin.sentNotifications;
    expect(notifications, hasLength(subscriptions.length));
    for (var path in subscriptions.keys) {
      var subscribedServices = subscriptions[path];
      var notifiedServices = notifications[path];
      expect(notifiedServices, isNotNull,
          reason: 'Not notified for file $path');
      expect(notifiedServices, unorderedEquals(subscribedServices),
          reason: 'Wrong notifications for file $path');
    }
  }

  AnalysisDriverGeneric _getDriver(ContextRoot targetRoot) {
    for (var root in plugin.driverMap.keys) {
      if (root.root == targetRoot.root) {
        return plugin.driverMap[root];
      }
    }
    return null;
  }
}

class _TestServerPlugin extends MockServerPlugin {
  Map<String, List<AnalysisService>> sentNotifications =
      <String, List<AnalysisService>>{};

  _TestServerPlugin(ResourceProvider resourceProvider)
      : super(resourceProvider);

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
