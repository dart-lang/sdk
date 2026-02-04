// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/analytics/analytics_manager.dart';
import 'package:analysis_server/src/legacy_analysis_server.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/server/crash_reporting_attachments.dart';
import 'package:analysis_server/src/services/user_prompts/dart_fix_prompt_manager.dart';
import 'package:analysis_server/src/session_logger/session_logger.dart';
import 'package:analysis_server/src/utilities/mocks.dart';
import 'package:analyzer/dart/analysis/analysis_options.dart' as analysis;
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/instrumentation/service.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/platform.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer_testing/experiments/experiments.dart';
import 'package:analyzer_testing/mock_packages/mock_packages.dart';
import 'package:analyzer_testing/resource_provider_mixin.dart';
import 'package:analyzer_testing/utilities/extensions/resource_provider.dart';
import 'package:analyzer_testing/utilities/utilities.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';
import 'package:unified_analytics/unified_analytics.dart';

import 'constants.dart';
import 'mocks.dart';
import 'support/configuration_files.dart';
import 'utils/message_scheduler_test_view.dart';

class BlazeWorkspaceAnalysisServerTest extends ContextResolutionTest {
  String get myPackageLibPath => '$myPackageRootPath/lib';

  String get myPackageRootPath => '$workspaceRootPath/dart/my';

  Folder get workspaceRoot => getFolder(workspaceRootPath);

  String get workspaceRootPath => '/workspace';

  @override
  void createDefaultFiles() {
    newFile('$workspaceRootPath/${file_paths.blazeWorkspaceMarker}', '');
  }
}

abstract class ContextResolutionTest with ResourceProviderMixin {
  /// The byte store that is reused between tests. This allows reusing all
  /// unlinked and linked summaries for SDK, so that tests run much faster.
  /// However nothing is preserved between Dart VM runs, so changes to the
  /// implementation are still fully verified.
  static final MemoryByteStore _sharedByteStore = MemoryByteStore();

  /// The next ID to use in a request to the server.
  var nextRequestId = 0;

  MemoryByteStore _byteStore = _sharedByteStore;

  final TestPluginManager pluginManager = TestPluginManager();
  late final MockServerChannel serverChannel;
  MessageSchedulerTestView? testView;
  late final LegacyAnalysisServer server;

  DartFixPromptManager? dartFixPromptManager;

  final List<GeneralAnalysisService> _analysisGeneralServices = [];
  final Map<AnalysisService, List<String>> _analysisFileSubscriptions = {};

  void Function(Notification)? notificationListener;

  bool get retainDataForTesting => false;

  Folder get sdkRoot => newFolder('/sdk');

  Future<void> addGeneralAnalysisSubscription(
    GeneralAnalysisService service,
  ) async {
    _analysisGeneralServices.add(service);
    await _setGeneralAnalysisSubscriptions();
  }

  void assertResponseFailure(
    Response response, {
    required String requestId,
    required RequestErrorCode errorCode,
  }) {
    expect(response, isResponseFailure(requestId, errorCode));
  }

  void createDefaultFiles() {}

  Future<Response> handleRequest(Request request) async {
    return await serverChannel.simulateRequestFromClient(request);
  }

  /// Validates that the given [request] is handled successfully.
  Future<Response> handleSuccessfulRequest(Request request) async {
    var response = await handleRequest(request);
    expect(response, isResponseSuccess(request.id));
    return response;
  }

  void processNotification(Notification notification) {
    notificationListener?.call(notification);
  }

  Future<void> removeGeneralAnalysisSubscription(
    GeneralAnalysisService service,
  ) async {
    _analysisGeneralServices.remove(service);
    await _setGeneralAnalysisSubscriptions();
  }

  void setPriorityFiles(List<File> files) {
    handleSuccessfulRequest(
      AnalysisSetPriorityFilesParams(
        files.map((e) => e.path).toList(),
      ).toRequest(
        '${nextRequestId++}',
        clientUriConverter: server.uriConverter,
      ),
    );
  }

  Future<void> setPriorityFiles2(List<File> files) async {
    await handleSuccessfulRequest(
      AnalysisSetPriorityFilesParams(
        files.map((e) => e.path).toList(),
      ).toRequest(
        '${nextRequestId++}',
        clientUriConverter: server.uriConverter,
      ),
    );
  }

  Future<void> setRoots({
    required List<String> included,
    required List<String> excluded,
  }) async {
    var includedConverted = included.map(convertPath).toList();
    var excludedConverted = excluded.map(convertPath).toList();
    await handleSuccessfulRequest(
      AnalysisSetAnalysisRootsParams(
        includedConverted,
        excludedConverted,
        packageRoots: {},
      ).toRequest(
        '${nextRequestId++}',
        clientUriConverter: server.uriConverter,
      ),
    );
  }

  @mustCallSuper
  void setUp() {
    serverChannel = MockServerChannel(printMessages: debugPrintCommunication);

    createMockSdk(resourceProvider: resourceProvider, root: sdkRoot);

    createDefaultFiles();

    serverChannel.notifications.listen(processNotification);

    testView = retainDataForTesting ? MessageSchedulerTestView() : null;
    server = LegacyAnalysisServer(
      serverChannel,
      resourceProvider,
      AnalysisServerOptions(),
      DartSdkManager(sdkRoot.path),
      AnalyticsManager(NoOpAnalytics()),
      CrashReportingAttachmentsBuilder.empty,
      InstrumentationService.NULL_SERVICE,
      SessionLogger(),
      dartFixPromptManager: dartFixPromptManager,
      providedByteStore: _byteStore,
      pluginManager: pluginManager,
      messageSchedulerListener: testView,
    );

    server.completionState.budgetDuration = const Duration(seconds: 30);
  }

  Future<void> tearDown() async {
    await server.shutdown();
  }

  /// Returns a [Future] that completes when the server's analysis is complete.
  Future<void> waitForTasksFinished() async {
    await pumpEventQueue(times: 1 << 10);
    await server.onAnalysisComplete;
  }

  Future<void> _setGeneralAnalysisSubscriptions() async {
    await handleSuccessfulRequest(
      AnalysisSetGeneralSubscriptionsParams(_analysisGeneralServices).toRequest(
        '${nextRequestId++}',
        clientUriConverter: server.uriConverter,
      ),
    );
  }
}

class PubPackageAnalysisServerTest extends ContextResolutionTest
    with MockPackagesMixin, ConfigurationFilesMixin {
  // TODO(scheglov): Consider turning it back into a getter.
  late String testFilePath = resourceProvider.convertPath(
    '$testPackageLibPath/test.dart',
  );

  late String pubspecFilePath = pathContext.normalize(
    resourceProvider.convertPath('$testPackageRootPath/pubspec.yaml'),
  );

  late TestCode parsedTestCode;

  final String testPackageName = 'test';

  /// Return a list of the experiments that are to be enabled for tests in this
  /// class, an empty list if there are no experiments that should be enabled.
  List<String> get experiments => experimentsForTests;

  /// The path that is not in [workspaceRootPath], contains external packages.
  @override
  String get packagesRootPath => resourceProvider.convertPath('/packages');

  List<TestCodePosition> get parsedPositions => parsedTestCode.positions;

  TestCodeRange get parsedRange => parsedTestCode.range;

  List<TestCodeRange> get parsedRanges => parsedTestCode.ranges;

  SourceRange get parsedSourceRange => parsedTestCode.range.sourceRange;

  File get testFile => getFile(testFilePath);

  analysis.AnalysisOptions get testFileAnalysisOptions {
    var analysisDriver = server.getAnalysisDriver(testFile.path)!;
    return analysisDriver.getAnalysisOptionsForFile(testFile);
  }

  String get testFileContent => testFile.readAsStringSync();

  String get testPackageLibPath => '$testPackageRootPath/lib';

  Folder get testPackageRoot => getFolder(testPackageRootPath);

  @override
  String get testPackageRootPath => '$workspaceRootPath/$testPackageName';

  String get testPackageTestPath => '$testPackageRootPath/test';

  Folder get workspaceRoot => getFolder(workspaceRootPath);

  String get workspaceRootPath => '/home';

  Future<void> addAnalysisSubscription(
    AnalysisService service,
    File file,
  ) async {
    (_analysisFileSubscriptions[service] ??= []).add(file.path);
    await handleSuccessfulRequest(
      AnalysisSetSubscriptionsParams(_analysisFileSubscriptions).toRequest(
        '${nextRequestId++}',
        clientUriConverter: server.uriConverter,
      ),
    );
  }

  // TODO(scheglov): rename
  void addTestFile(String content) {
    parsedTestCode = TestCode.parseNormalized(content);
    newFile(testFilePath, parsedTestCode.code);
  }

  @override
  void createDefaultFiles() {
    writeTestPackageConfig();
    writeTestPackagePubspecYamlFile('name: $testPackageName');

    writeTestPackageAnalysisOptionsFile(
      analysisOptionsContent(experiments: experiments),
    );
  }

  /// Deletes the analysis options YAML file at [testPackageRootPath].
  void deleteTestPackageAnalysisOptionsFile() {
    var path = join(testPackageRootPath, file_paths.analysisOptionsYaml);
    deleteFile(path);
  }

  /// Deletes the `package_config.json` file at [testPackageRootPath].
  void deleteTestPackageConfigJsonFile() {
    var filePath = join(
      testPackageRootPath,
      file_paths.dotDartTool,
      file_paths.packageConfigJson,
    );
    deleteFile(filePath);
  }

  /// Returns the offset of [search] in [testFileContent].
  /// Fails if not found.
  // TODO(scheglov): Rename it.
  int findOffset(String search) {
    return offsetInFile(testFile, search);
  }

  void modifyTestFile(String content) {
    modifyFile2(testFile, content);
  }

  @override
  File newFile(String path, String content) {
    content = normalizeNewlinesForPlatform(content);
    return super.newFile(path, content);
  }

  /// Returns the offset of [search] in [file].
  /// Fails if not found.
  int offsetInFile(File file, String search) {
    var content = file.readAsStringSync();
    var offset = content.indexOf(search);
    expect(offset, isNot(-1));
    return offset;
  }

  /// Call this method if the test needs to use the empty byte store, without
  /// any information cached.
  void useEmptyByteStore() {
    _byteStore = MemoryByteStore();
  }

  void writeTestPackageAnalysisOptionsFile(String content) {
    newAnalysisOptionsYamlFile(testPackageRootPath, content);
  }

  void writeTestPackagePubspecYamlFile(String content) {
    newPubspecYamlFile(testPackageRootPath, content);
  }
}
