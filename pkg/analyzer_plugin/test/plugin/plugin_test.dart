// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

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
    contextRoot1 = new ContextRoot(packagePath1, <String>[]);

    packagePath2 = convertPath('/package2');
    filePath2 = join(packagePath2, 'lib', 'test.dart');
    newFile(filePath2);
    contextRoot2 = new ContextRoot(packagePath2, <String>[]);

    channel = new MockChannel();
    plugin = new _TestServerPlugin(resourceProvider);
    plugin.start(channel);
  }

  test_contextRootContaining_insideRoot() async {
    await plugin.handleAnalysisSetContextRoots(
        new AnalysisSetContextRootsParams([contextRoot1]));

    expect(plugin.contextRootContaining(filePath1), isNotNull);
  }

  void test_contextRootContaining_noRoots() {
    expect(plugin.contextRootContaining(filePath1), isNull);
  }

  test_contextRootContaining_outsideRoot() async {
    await plugin.handleAnalysisSetContextRoots(
        new AnalysisSetContextRootsParams([contextRoot1]));

    expect(plugin.contextRootContaining(filePath2), isNull);
  }

  test_handleAnalysisGetNavigation() async {
    var result = await plugin
        .handleAnalysisGetNavigation(new AnalysisGetNavigationParams('', 1, 2));
    expect(result, isNotNull);
  }

  test_handleAnalysisHandleWatchEvents() async {
    var result = await plugin.handleAnalysisHandleWatchEvents(
        new AnalysisHandleWatchEventsParams([]));
    expect(result, isNotNull);
  }

  test_handleAnalysisSetContextRoots() async {
    var result = await plugin.handleAnalysisSetContextRoots(
        new AnalysisSetContextRootsParams([contextRoot1]));
    expect(result, isNotNull);
    AnalysisDriverGeneric driver = _getDriver(contextRoot1);
    expect(driver, isNotNull);
    expect((driver as MockAnalysisDriver).addedFiles, hasLength(1));
  }

  test_handleAnalysisSetPriorityFiles() async {
    await plugin.handleAnalysisSetContextRoots(
        new AnalysisSetContextRootsParams([contextRoot1]));

    var result = await plugin.handleAnalysisSetPriorityFiles(
        new AnalysisSetPriorityFilesParams([filePath1]));
    expect(result, isNotNull);
  }

  test_handleAnalysisSetSubscriptions() async {
    await plugin.handleAnalysisSetContextRoots(
        new AnalysisSetContextRootsParams([contextRoot1]));
    expect(plugin.subscriptionManager.servicesForFile(filePath1), isEmpty);

    AnalysisSetSubscriptionsResult result = await plugin
        .handleAnalysisSetSubscriptions(new AnalysisSetSubscriptionsParams({
      AnalysisService.OUTLINE: [filePath1]
    }));
    expect(result, isNotNull);
    expect(plugin.subscriptionManager.servicesForFile(filePath1),
        [AnalysisService.OUTLINE]);
  }

  test_handleAnalysisUpdateContent_addChangeRemove() async {
    await plugin.handleAnalysisSetContextRoots(
        new AnalysisSetContextRootsParams([contextRoot1]));
    var addResult = await plugin.handleAnalysisUpdateContent(
        new AnalysisUpdateContentParams(
            {filePath1: new AddContentOverlay('class C {}')}));
    expect(addResult, isNotNull);
    var changeResult = await plugin
        .handleAnalysisUpdateContent(new AnalysisUpdateContentParams({
      filePath1:
          new ChangeContentOverlay([new SourceEdit(7, 0, ' extends Object')])
    }));
    expect(changeResult, isNotNull);
    var removeResult = await plugin.handleAnalysisUpdateContent(
        new AnalysisUpdateContentParams(
            {filePath1: new RemoveContentOverlay()}));
    expect(removeResult, isNotNull);
  }

  test_handleAnalysisUpdateContent_changeNoAdd() async {
    await plugin.handleAnalysisSetContextRoots(
        new AnalysisSetContextRootsParams([contextRoot1]));
    try {
      await plugin.handleAnalysisUpdateContent(new AnalysisUpdateContentParams({
        filePath1:
            new ChangeContentOverlay([new SourceEdit(7, 0, ' extends Object')])
      }));
      fail('Expected RequestFailure');
    } on RequestFailure {
      // Expected
    }
  }

  test_handleAnalysisUpdateContent_invalidChange() async {
    await plugin.handleAnalysisSetContextRoots(
        new AnalysisSetContextRootsParams([contextRoot1]));
    await plugin.handleAnalysisUpdateContent(new AnalysisUpdateContentParams(
        {filePath1: new AddContentOverlay('class C {}')}));
    try {
      await plugin.handleAnalysisUpdateContent(new AnalysisUpdateContentParams({
        filePath1:
            new ChangeContentOverlay([new SourceEdit(20, 5, 'class D {}')])
      }));
      fail('Expected RequestFailure');
    } on RequestFailure {
      // Expected
    }
  }

  test_handleCompletionGetSuggestions() async {
    await plugin.handleAnalysisSetContextRoots(
        new AnalysisSetContextRootsParams([contextRoot1]));

    CompletionGetSuggestionsResult result =
        await plugin.handleCompletionGetSuggestions(
            new CompletionGetSuggestionsParams(filePath1, 12));
    expect(result, isNotNull);
  }

  test_handleEditGetAssists() async {
    await plugin.handleAnalysisSetContextRoots(
        new AnalysisSetContextRootsParams([contextRoot1]));

    EditGetAssistsResult result = await plugin
        .handleEditGetAssists(new EditGetAssistsParams(filePath1, 10, 0));
    expect(result, isNotNull);
  }

  test_handleEditGetAvailableRefactorings() async {
    await plugin.handleAnalysisSetContextRoots(
        new AnalysisSetContextRootsParams([contextRoot1]));

    EditGetAvailableRefactoringsResult result =
        await plugin.handleEditGetAvailableRefactorings(
            new EditGetAvailableRefactoringsParams(filePath1, 10, 0));
    expect(result, isNotNull);
  }

  test_handleEditGetFixes() async {
    await plugin.handleAnalysisSetContextRoots(
        new AnalysisSetContextRootsParams([contextRoot1]));

    EditGetFixesResult result =
        await plugin.handleEditGetFixes(new EditGetFixesParams(filePath1, 13));
    expect(result, isNotNull);
  }

  @failingTest
  test_handleEditGetRefactoring() async {
    await plugin.handleAnalysisSetContextRoots(
        new AnalysisSetContextRootsParams([contextRoot1]));

    EditGetRefactoringResult result = await plugin.handleEditGetRefactoring(
        new EditGetRefactoringParams(
            RefactoringKind.RENAME, filePath1, 7, 0, false));
    expect(result, isNotNull);
  }

  test_handlePluginShutdown() async {
    var result = await plugin.handlePluginShutdown(new PluginShutdownParams());
    expect(result, isNotNull);
  }

  test_handlePluginVersionCheck() async {
    PluginVersionCheckResult result = await plugin.handlePluginVersionCheck(
        new PluginVersionCheckParams('byteStorePath', 'sdkPath', '0.1.0'));
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
    channel.sendError(new ArgumentError(), new StackTrace.fromString(''));
  }

  test_onRequest_analysisGetNavigation() async {
    var result =
        await channel.sendRequest(new AnalysisGetNavigationParams('', 1, 2));
    expect(result, isNotNull);
  }

  test_onRequest_analysisHandleWatchEvents() async {
    var result =
        await channel.sendRequest(new AnalysisHandleWatchEventsParams([]));
    expect(result, isNotNull);
  }

  test_onRequest_analysisSetContextRoots() async {
    var result = await channel
        .sendRequest(new AnalysisSetContextRootsParams([contextRoot1]));
    expect(result, isNotNull);
    AnalysisDriverGeneric driver = _getDriver(contextRoot1);
    expect(driver, isNotNull);
    expect((driver as MockAnalysisDriver).addedFiles, hasLength(1));
  }

  test_onRequest_analysisSetPriorityFiles() async {
    await channel
        .sendRequest(new AnalysisSetContextRootsParams([contextRoot1]));

    var result = await channel
        .sendRequest(new AnalysisSetPriorityFilesParams([filePath1]));
    expect(result, isNotNull);
  }

  test_onRequest_analysisSetSubscriptions() async {
    await channel
        .sendRequest(new AnalysisSetContextRootsParams([contextRoot1]));
    expect(plugin.subscriptionManager.servicesForFile(filePath1), isEmpty);

    var result = await channel.sendRequest(new AnalysisSetSubscriptionsParams({
      AnalysisService.OUTLINE: [filePath1]
    }));
    expect(result, isNotNull);
    expect(plugin.subscriptionManager.servicesForFile(filePath1),
        [AnalysisService.OUTLINE]);
  }

  test_onRequest_analysisUpdateContent_addChangeRemove() async {
    await channel
        .sendRequest(new AnalysisSetContextRootsParams([contextRoot1]));
    var addResult = await channel.sendRequest(new AnalysisUpdateContentParams(
        {filePath1: new AddContentOverlay('class C {}')}));
    expect(addResult, isNotNull);
    var changeResult =
        await channel.sendRequest(new AnalysisUpdateContentParams({
      filePath1:
          new ChangeContentOverlay([new SourceEdit(7, 0, ' extends Object')])
    }));
    expect(changeResult, isNotNull);
    var removeResult = await channel.sendRequest(
        new AnalysisUpdateContentParams(
            {filePath1: new RemoveContentOverlay()}));
    expect(removeResult, isNotNull);
  }

  test_onRequest_completionGetSuggestions() async {
    await channel
        .sendRequest(new AnalysisSetContextRootsParams([contextRoot1]));

    var result = await channel
        .sendRequest(new CompletionGetSuggestionsParams(filePath1, 12));
    expect(result, isNotNull);
  }

  test_onRequest_editGetAssists() async {
    await channel
        .sendRequest(new AnalysisSetContextRootsParams([contextRoot1]));

    var result =
        await channel.sendRequest(new EditGetAssistsParams(filePath1, 10, 0));
    expect(result, isNotNull);
  }

  test_onRequest_editGetAvailableRefactorings() async {
    await channel
        .sendRequest(new AnalysisSetContextRootsParams([contextRoot1]));

    var result = await channel
        .sendRequest(new EditGetAvailableRefactoringsParams(filePath1, 10, 0));
    expect(result, isNotNull);
  }

  test_onRequest_editGetFixes() async {
    await channel
        .sendRequest(new AnalysisSetContextRootsParams([contextRoot1]));

    var result =
        await channel.sendRequest(new EditGetFixesParams(filePath1, 13));
    expect(result, isNotNull);
  }

  test_onRequest_editGetRefactoring() async {
    await channel
        .sendRequest(new AnalysisSetContextRootsParams([contextRoot1]));

    var result = await channel.sendRequest(new EditGetRefactoringParams(
        RefactoringKind.RENAME, filePath1, 7, 0, false));
    expect(result, isNotNull);
  }

  test_onRequest_pluginShutdown() async {
    var result = await channel.sendRequest(new PluginShutdownParams());
    expect(result, isNotNull);
  }

  test_onRequest_pluginVersionCheck() async {
    var response = (await channel.sendRequest(
        new PluginVersionCheckParams('byteStorePath', 'sdkPath', '0.1.0')));
    PluginVersionCheckResult result =
        new PluginVersionCheckResult.fromResponse(response);
    expect(result, isNotNull);
    expect(result.interestingFiles, ['*.dart']);
    expect(result.isCompatible, isTrue);
    expect(result.name, 'Test Plugin');
    expect(result.version, '0.1.0');
  }

  test_sendNotificationsForFile() {
    AnalysisService service1 = AnalysisService.FOLDING;
    AnalysisService service2 = AnalysisService.NAVIGATION;
    AnalysisService service3 = AnalysisService.OUTLINE;
    plugin.subscriptionManager.setSubscriptions({
      service1: [filePath1, filePath2],
      service2: [filePath1],
      service3: [filePath2]
    });
    plugin.sendNotificationsForFile(filePath1);
    Map<String, List<AnalysisService>> notifications = plugin.sentNotifications;
    expect(notifications, hasLength(1));
    List<AnalysisService> services = notifications[filePath1];
    expect(services, unorderedEquals([service1, service2]));
  }

  test_sendNotificationsForSubscriptions() {
    Map<String, List<AnalysisService>> subscriptions =
        <String, List<AnalysisService>>{};

    plugin.sendNotificationsForSubscriptions(subscriptions);
    Map<String, List<AnalysisService>> notifications = plugin.sentNotifications;
    expect(notifications, hasLength(subscriptions.length));
    for (String path in subscriptions.keys) {
      List<AnalysisService> subscribedServices = subscriptions[path];
      List<AnalysisService> notifiedServices = notifications[path];
      expect(notifiedServices, isNotNull,
          reason: 'Not notified for file $path');
      expect(notifiedServices, unorderedEquals(subscribedServices),
          reason: 'Wrong notifications for file $path');
    }
  }

  AnalysisDriverGeneric _getDriver(ContextRoot targetRoot) {
    for (ContextRoot root in plugin.driverMap.keys) {
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
    return new Future.value();
  }

  @override
  Future<void> sendHighlightsNotification(String path) {
    _sent(path, AnalysisService.HIGHLIGHTS);
    return new Future.value();
  }

  @override
  Future<void> sendNavigationNotification(String path) {
    _sent(path, AnalysisService.NAVIGATION);
    return new Future.value();
  }

  @override
  Future<void> sendOccurrencesNotification(String path) {
    _sent(path, AnalysisService.OCCURRENCES);
    return new Future.value();
  }

  @override
  Future<void> sendOutlineNotification(String path) {
    _sent(path, AnalysisService.OUTLINE);
    return new Future.value();
  }

  void _sent(String path, AnalysisService service) {
    sentNotifications.putIfAbsent(path, () => <AnalysisService>[]).add(service);
  }
}
