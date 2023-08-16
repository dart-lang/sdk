// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/analytics/analytics_manager.dart';
import 'package:analysis_server/src/legacy_analysis_server.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/server/crash_reporting_attachments.dart';
import 'package:analysis_server/src/services/user_prompts/dart_fix_prompt_manager.dart';
import 'package:analysis_server/src/utilities/mocks.dart';
import 'package:analyzer/dart/analysis/analysis_options.dart' as analysis;
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/instrumentation/service.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:meta/meta.dart';
import 'package:test/test.dart';
import 'package:unified_analytics/unified_analytics.dart';

import 'mocks.dart';
import 'src/utilities/mock_packages.dart';

/// TODO(scheglov) this is duplicate
class AnalysisOptionsFileConfig {
  final List<String> experiments;
  final bool implicitCasts;
  final bool implicitDynamic;
  final List<String> lints;
  final bool strictCasts;
  final bool strictInference;
  final bool strictRawTypes;

  AnalysisOptionsFileConfig({
    this.experiments = const [],
    this.implicitCasts = true,
    this.implicitDynamic = true,
    this.lints = const [],
    this.strictCasts = false,
    this.strictInference = false,
    this.strictRawTypes = false,
  });

  String toContent() {
    var buffer = StringBuffer();

    buffer.writeln('analyzer:');
    if (experiments.isNotEmpty) {
      buffer.writeln('  enable-experiment:');
      for (var experiment in experiments) {
        buffer.writeln('    - $experiment');
      }
    }
    buffer.writeln('  language:');
    buffer.writeln('    strict-casts: $strictCasts');
    buffer.writeln('    strict-inference: $strictInference');
    buffer.writeln('    strict-raw-types: $strictRawTypes');
    if (!implicitCasts || !implicitDynamic) {
      buffer.writeln('  strong-mode:');
      if (!implicitCasts) {
        buffer.writeln('    implicit-casts: $implicitCasts');
      }
      if (!implicitDynamic) {
        buffer.writeln('    implicit-dynamic: $implicitDynamic');
      }
    }

    buffer.writeln('linter:');
    buffer.writeln('  rules:');
    for (var lint in lints) {
      buffer.writeln('    - $lint');
    }

    return buffer.toString();
  }
}

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

class ContextResolutionTest with ResourceProviderMixin {
  final TestPluginManager pluginManager = TestPluginManager();
  late final MockServerChannel serverChannel;
  late final LegacyAnalysisServer server;

  DartFixPromptManager? dartFixPromptManager;

  final List<GeneralAnalysisService> _analysisGeneralServices = [];
  final Map<AnalysisService, List<String>> _analysisFileSubscriptions = {};

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
    expect(
      response,
      isResponseFailure(requestId, errorCode),
    );
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

  void processNotification(Notification notification) {}

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
      ).toRequest('0'),
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
      ).toRequest('0'),
    );
  }

  @mustCallSuper
  void setUp() {
    serverChannel = MockServerChannel();

    createMockSdk(
      resourceProvider: resourceProvider,
      root: sdkRoot,
    );

    createDefaultFiles();

    serverChannel.notifications.listen(processNotification);

    server = LegacyAnalysisServer(
      serverChannel,
      resourceProvider,
      AnalysisServerOptions(),
      DartSdkManager(sdkRoot.path),
      AnalyticsManager(NoOpAnalytics()),
      CrashReportingAttachmentsBuilder.empty,
      InstrumentationService.NULL_SERVICE,
      dartFixPromptManager: dartFixPromptManager,
    );

    server.pluginManager = pluginManager;
    server.completionState.budgetDuration = const Duration(seconds: 30);
  }

  Future<void> tearDown() async {
    await server.dispose();
  }

  /// Returns a [Future] that completes when the server's analysis is complete.
  Future<void> waitForTasksFinished() async {
    await pumpEventQueue(times: 1 << 10);
    await server.onAnalysisComplete;
  }

  Future<void> _setGeneralAnalysisSubscriptions() async {
    await handleSuccessfulRequest(
      AnalysisSetGeneralSubscriptionsParams(
        _analysisGeneralServices,
      ).toRequest('0'),
    );
  }
}

class PubPackageAnalysisServerTest extends ContextResolutionTest {
  // If experiments are needed,
  // add `import 'package:analyzer/dart/analysis/features.dart';`
  // and list the necessary experiments here.
  List<String> get experiments => [
        Feature.inline_class.enableString,
        Feature.macros.enableString,
      ];

  /// The path that is not in [workspaceRootPath], contains external packages.
  String get packagesRootPath => '/packages';

  File get testFile => getFile(testFilePath);

  analysis.AnalysisOptions get testFileAnalysisOptions {
    var analysisDriver = server.getAnalysisDriver(testFile.path)!;
    return analysisDriver.analysisOptions;
  }

  String get testFileContent => testFile.readAsStringSync();

  String get testFilePath => '$testPackageLibPath/test.dart';

  String get testPackageLibPath => '$testPackageRootPath/lib';

  Folder get testPackageRoot => getFolder(testPackageRootPath);

  String get testPackageRootPath => '$workspaceRootPath/test';

  String get testPackageTestPath => '$testPackageRootPath/test';

  Folder get workspaceRoot => getFolder(workspaceRootPath);

  String get workspaceRootPath => '/home';

  Future<void> addAnalysisSubscription(
    AnalysisService service,
    File file,
  ) async {
    (_analysisFileSubscriptions[service] ??= []).add(file.path);
    await handleSuccessfulRequest(
      AnalysisSetSubscriptionsParams(
        _analysisFileSubscriptions,
      ).toRequest('0'),
    );
  }

  /// TODO(scheglov) rename
  void addTestFile(String content) {
    newFile(testFilePath, content);
  }

  @override
  void createDefaultFiles() {
    writeTestPackageConfig();

    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(
        experiments: experiments,
      ),
    );
  }

  void deleteTestPackageAnalysisOptionsFile() {
    deleteAnalysisOptionsYamlFile(testPackageRootPath);
  }

  void deleteTestPackageConfigJsonFile() {
    deletePackageConfigJsonFile(testPackageRootPath);
  }

  /// Returns the offset of [search] in [testFileContent].
  /// Fails if not found.
  /// TODO(scheglov) Rename it.
  int findOffset(String search) {
    return offsetInFile(testFile, search);
  }

  void modifyTestFile(String content) {
    modifyFile(testFilePath, content);
  }

  /// Returns the offset of [search] in [file].
  /// Fails if not found.
  int offsetInFile(File file, String search) {
    var content = file.readAsStringSync();
    var offset = content.indexOf(search);
    expect(offset, isNot(-1));
    return offset;
  }

  void writePackageConfig(Folder root, PackageConfigFileBuilder config) {
    newPackageConfigJsonFile(
      root.path,
      config.toContent(toUriStr: toUriStr),
    );
  }

  void writeTestPackageAnalysisOptionsFile(AnalysisOptionsFileConfig config) {
    newAnalysisOptionsYamlFile(
      testPackageRootPath,
      config.toContent(),
    );
  }

  void writeTestPackageConfig({
    PackageConfigFileBuilder? config,
    String? languageVersion,
    bool flutter = false,
    bool meta = false,
  }) {
    if (config == null) {
      config = PackageConfigFileBuilder();
    } else {
      config = config.copy();
    }

    config.add(
      name: 'test',
      rootPath: testPackageRootPath,
      languageVersion: languageVersion,
    );

    if (meta || flutter) {
      var libFolder = MockPackages.instance.addMeta(resourceProvider);
      config.add(name: 'meta', rootPath: libFolder.parent.path);
    }

    if (flutter) {
      {
        var libFolder = MockPackages.instance.addUI(resourceProvider);
        config.add(name: 'ui', rootPath: libFolder.parent.path);
      }
      {
        var libFolder = MockPackages.instance.addFlutter(resourceProvider);
        config.add(name: 'flutter', rootPath: libFolder.parent.path);
      }
    }

    writePackageConfig(testPackageRoot, config);
  }

  void writeTestPackagePubspecYamlFile(String content) {
    newPubspecYamlFile(testPackageRootPath, content);
  }
}
