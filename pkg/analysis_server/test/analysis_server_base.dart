// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/domain_analysis.dart';
import 'package:analysis_server/src/domain_completion.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/server/crash_reporting_attachments.dart';
import 'package:analysis_server/src/utilities/mocks.dart';
import 'package:analyzer/dart/analysis/analysis_options.dart' as analysis;
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/instrumentation/service.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

import 'mocks.dart';

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
    buffer.writeln('  enable-experiment:');
    for (var experiment in experiments) {
      buffer.writeln('    - $experiment');
    }
    buffer.writeln('  language:');
    buffer.writeln('    strict-casts: $strictCasts');
    buffer.writeln('    strict-inference: $strictInference');
    buffer.writeln('    strict-raw-types: $strictRawTypes');
    buffer.writeln('  strong-mode:');
    buffer.writeln('    implicit-casts: $implicitCasts');
    buffer.writeln('    implicit-dynamic: $implicitDynamic');

    buffer.writeln('linter:');
    buffer.writeln('  rules:');
    for (var lint in lints) {
      buffer.writeln('    - $lint');
    }

    return buffer.toString();
  }
}

class PubPackageAnalysisServerTest with ResourceProviderMixin {
  final TestPluginManager pluginManager = TestPluginManager();
  late final MockServerChannel serverChannel;
  late final AnalysisServer server;

  final List<GeneralAnalysisService> _analysisGeneralServices = [];
  final Map<AnalysisService, List<String>> _analysisFileSubscriptions = {};

  AnalysisDomainHandler get analysisDomain {
    return server.handlers.whereType<AnalysisDomainHandler>().single;
  }

  CompletionDomainHandler get completionDomain {
    return server.handlers.whereType<CompletionDomainHandler>().single;
  }

  List<String> get experiments => [
        EnableString.enhanced_enums,
        EnableString.named_arguments_anywhere,
        EnableString.super_parameters,
      ];

  /// The path that is not in [workspaceRootPath], contains external packages.
  String get packagesRootPath => '/packages';

  Folder get sdkRoot => newFolder('/sdk');

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

  Future<void> addGeneralAnalysisSubscription(
    GeneralAnalysisService service,
  ) async {
    _analysisGeneralServices.add(service);
    await _setGeneralAnalysisSubscriptions();
  }

  /// TODO(scheglov) rename
  void addTestFile(String content) {
    newFile(testFilePath, content);
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

  Future<Response> handleRequest(Request request) async {
    return await serverChannel.sendRequest(request);
  }

  /// Validates that the given [request] is handled successfully.
  Future<Response> handleSuccessfulRequest(Request request) async {
    var response = await handleRequest(request);
    expect(response, isResponseSuccess(request.id));
    return response;
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

    writeTestPackageConfig();

    writeTestPackageAnalysisOptionsFile(
      AnalysisOptionsFileConfig(
        experiments: experiments,
      ),
    );

    serverChannel.notifications.listen(processNotification);

    server = AnalysisServer(
      serverChannel,
      resourceProvider,
      AnalysisServerOptions(),
      DartSdkManager(sdkRoot.path),
      CrashReportingAttachmentsBuilder.empty,
      InstrumentationService.NULL_SERVICE,
    );

    server.pendingFilesRemoveOverlayDelay = const Duration(milliseconds: 10);
    server.pluginManager = pluginManager;
    completionDomain.budgetDuration = const Duration(seconds: 30);
  }

  Future<void> tearDown() async {
    await server.dispose();
  }

  /// Returns a [Future] that completes when the server's analysis is complete.
  Future<void> waitForTasksFinished() async {
    await pumpEventQueue(times: 1 << 10);
    await server.onAnalysisComplete;
  }

  void writePackageConfig(Folder root, PackageConfigFileBuilder config) {
    newPackageConfigJsonFile(
      root.path,
      config.toContent(toUriStr: toUriStr),
    );
  }

  void writeTestPackageAnalysisOptionsFile(AnalysisOptionsFileConfig config) {
    newAnalysisOptionsYamlFile2(
      testPackageRootPath,
      config.toContent(),
    );
  }

  void writeTestPackageConfig({
    PackageConfigFileBuilder? config,
    String? languageVersion,
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

    writePackageConfig(testPackageRoot, config);
  }

  void writeTestPackagePubspecYamlFile(String content) {
    newPubspecYamlFile(testPackageRootPath, content);
  }

  Future<void> _setGeneralAnalysisSubscriptions() async {
    await handleSuccessfulRequest(
      AnalysisSetGeneralSubscriptionsParams(
        _analysisGeneralServices,
      ).toRequest('0'),
    );
  }
}
