// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:path/src/context.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveTests(ServerPluginTest);
}

class MockAnalysisDriver extends AnalysisDriverGeneric {
  /**
   * The files that have been added to this driver.
   */
  List<String> addedFiles = <String>[];

  @override
  bool get hasFilesToAnalyze => false;

  @override
  set priorityFiles(List<String> priorityPaths) {}

  @override
  AnalysisDriverPriority get workPriority => AnalysisDriverPriority.nothing;

  @override
  void addFile(String path) {
    addedFiles.add(path);
  }

  @override
  void dispose() {}

  @override
  Future<Null> performWork() => new Future.value(null);
}

@reflectiveTest
class ServerPluginTest {
  MemoryResourceProvider resourceProvider = new MemoryResourceProvider();

  TestServerPlugin plugin;

  String packagePath1;
  String filePath1;
  ContextRoot contextRoot1;

  String packagePath2;
  String filePath2;
  ContextRoot contextRoot2;

  void setUp() {
    Context pathContext = resourceProvider.pathContext;

    packagePath1 = resourceProvider.convertPath('/package1');
    filePath1 = pathContext.join(packagePath1, 'lib', 'test.dart');
    resourceProvider.newFile(filePath1, '');
    contextRoot1 = new ContextRoot(packagePath1, <String>[]);

    packagePath2 = resourceProvider.convertPath('/package2');
    filePath2 = pathContext.join(packagePath2, 'lib', 'test.dart');
    resourceProvider.newFile(filePath2, '');
    contextRoot2 = new ContextRoot(packagePath2, <String>[]);

    plugin = new TestServerPlugin(resourceProvider);
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

  test_handleAnalysisHandleWatchEvents() async {
    var result = await plugin.handleAnalysisHandleWatchEvents(
        new AnalysisHandleWatchEventsParams([]));
    expect(result, isNotNull);
  }

  test_handleAnalysisReanalyze_all() async {
    await plugin.handleAnalysisSetContextRoots(
        new AnalysisSetContextRootsParams([contextRoot1]));
    var result =
        await plugin.handleAnalysisReanalyze(new AnalysisReanalyzeParams());
    expect(result, isNotNull);
  }

  @failingTest
  test_handleAnalysisReanalyze_subset() async {
    await plugin.handleAnalysisSetContextRoots(
        new AnalysisSetContextRootsParams([contextRoot1]));
    await plugin.handleAnalysisSetContextRoots(
        new AnalysisSetContextRootsParams([contextRoot2]));
    var result = await plugin.handleAnalysisReanalyze(
        new AnalysisReanalyzeParams(roots: [packagePath2]));
    expect(result, isNotNull);
  }

  @failingTest
  test_handleAnalysisSetContextBuilderOptions() async {
    var result = await plugin.handleAnalysisSetContextBuilderOptions(
        new AnalysisSetContextBuilderOptionsParams(
            new ContextBuilderOptions()));
    expect(result, isNotNull);
  }

  test_handleAnalysisSetContextRoots() async {
    var result = await plugin.handleAnalysisSetContextRoots(
        new AnalysisSetContextRootsParams([contextRoot1]));
    expect(result, isNotNull);
    AnalysisDriverGeneric driver = plugin.driverMap[contextRoot1];
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

  test_handleAnalysisUpdateContent() async {
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

  @failingTest
  void test_onDone() {
    fail('Not yet implemented.');
  }

  @failingTest
  void test_onError() {
    fail('Not yet implemented.');
  }

  @failingTest
  void test_start() {
    fail('Not yet implemented.');
  }
}

/**
 * A concrete implementation of a server plugin that is suitable for testing.
 */
class TestServerPlugin extends ServerPlugin {
  Map<String, List<AnalysisService>> latestSubscriptions;

  TestServerPlugin(ResourceProvider resourceProvider) : super(resourceProvider);

  @override
  List<String> get fileGlobsToAnalyze => <String>['*.dart'];

  @override
  String get name => 'Test Plugin';

  @override
  String get version => '0.1.0';

  @override
  AnalysisDriverGeneric createAnalysisDriver(ContextRoot contextRoot) {
    return new MockAnalysisDriver();
  }

  @override
  void sendNotificationsForSubscriptions(
      Map<String, List<AnalysisService>> subscriptions) {
    latestSubscriptions = subscriptions;
  }
}
