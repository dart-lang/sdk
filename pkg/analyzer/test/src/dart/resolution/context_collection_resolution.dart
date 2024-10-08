// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_context.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/sdk/build_sdk_summary.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/driver_based_analysis_context.dart';
import 'package:analyzer/src/dart/analysis/results.dart';
import 'package:analyzer/src/dart/analysis/unlinked_unit_store.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/summary2/kernel_compilation_service.dart';
import 'package:analyzer/src/summary2/macro.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer/src/util/file_paths.dart' as file_paths;
import 'package:analyzer/src/workspace/basic.dart';
import 'package:analyzer/src/workspace/blaze.dart';
import 'package:analyzer/src/workspace/gn.dart';
import 'package:analyzer/src/workspace/pub.dart';
import 'package:analyzer_utilities/test/experiments/experiments.dart';
import 'package:analyzer_utilities/test/mock_packages/mock_packages.dart';
import 'package:analyzer_utilities/testing/tree_string_sink.dart';
import 'package:linter/src/rules.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

import '../../../generated/test_support.dart';
import '../../summary/macros_environment.dart';
import '../analysis/analyzer_state_printer.dart';
import 'node_text_expectations.dart';
import 'resolution.dart';

export 'package:analyzer/src/test_utilities/package_config_file_builder.dart';

// TODO(srawlins): This is duplicate with pkg/linter/test/rule_test_support.dart
// and pkg/analysis_server/test/analysis_server_base.dart.
// Keep them as consistent with each other as they are today. Ultimately combine
// them in a shared analyzer test utilities package (e.g. the analyzer_utilities
// package).
String analysisOptionsContent({
  List<String> experiments = const [],
  List<String> plugins = const [],
  List<String> rules = const [],
  bool strictCasts = false,
  bool strictInference = false,
  bool strictRawTypes = false,
  List<String> unignorableNames = const [],
}) {
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
  buffer.writeln('  cannot-ignore:');
  for (var name in unignorableNames) {
    buffer.writeln('    - $name');
  }

  if (plugins.isNotEmpty) {
    buffer.writeln('  plugins:');
    for (var plugin in plugins) {
      buffer.writeln('    - $plugin');
    }
  }

  buffer.writeln('linter:');
  buffer.writeln('  rules:');
  for (var rule in rules) {
    buffer.writeln('    - $rule');
  }

  return buffer.toString();
}

// TODO(scheglov): This is duplicate with
// pkg/linter/test/rule_test_support.dart. Keep them as consistent with each
// other as they are today. Ultimately combine them in a shared analyzer test
// utilities package.
String pubspecYamlContent({
  String? name,
  String? sdkVersion,
  List<PubspecYamlFileDependency> dependencies = const [],
}) {
  var buffer = StringBuffer();

  if (name != null) {
    buffer.writeln('name: $name');
  }

  if (sdkVersion != null) {
    buffer.writeln('environment:');
    buffer.writeln("  sdk: '$sdkVersion'");
  }

  if (dependencies.isNotEmpty) {
    buffer.writeln('dependencies:');
    for (var dependency in dependencies) {
      buffer.writeln('  ${dependency.name}: ${dependency.version}');
    }
  }

  return buffer.toString();
}

class BlazeWorkspaceResolutionTest extends ContextResolutionTest {
  @override
  List<String> get collectionIncludedPaths => [workspaceRootPath];

  String get myPackageLibPath => '$myPackageRootPath/lib';

  String get myPackageRootPath => '$workspaceRootPath/dart/my';

  @override
  File get testFile => getFile('$myPackageLibPath/my.dart');

  String get workspaceRootPath => '/workspace';

  String get workspaceThirdPartyDartPath {
    return '$workspaceRootPath/third_party/dart';
  }

  @override
  void setUp() {
    super.setUp();
    newFile('$workspaceRootPath/${file_paths.blazeWorkspaceMarker}', '');
    newFile('$myPackageRootPath/BUILD', '');
  }

  @override
  void verifyCreatedCollection() {
    super.verifyCreatedCollection();
    assertBlazeWorkspaceFor(testFile);
  }
}

/// [AnalysisContextCollection] based implementation of [ResolutionTest].
abstract class ContextResolutionTest
    with ResourceProviderMixin, ResolutionTest {
  static bool _lintRulesAreRegistered = false;

  /// The byte store that is reused between tests. This allows reusing all
  /// unlinked and linked summaries for SDK, so that tests run much faster.
  /// However nothing is preserved between Dart VM runs, so changes to the
  /// implementation are still fully verified.
  static final MemoryByteStore _sharedByteStore = MemoryByteStore();

  MemoryByteStore _byteStore = _sharedByteStore;

  Map<String, String> _declaredVariables = {};
  AnalysisContextCollectionImpl? _analysisContextCollection;

  /// If not `null`, [resolveFile] will use the context that corresponds
  /// to this file, instead of the given file.
  File? fileForContextSelection;

  /// Optional Dart SDK summary file, to be used instead of [sdkRoot].
  File? sdkSummaryFile;

  /// Optional summaries to provide for the collection.
  List<File>? librarySummaryFiles;

  /// By default the kernel implementation is used, this can override it.
  MacroSupportFactory? macroSupportFactory;

  AnalyzerStatePrinterConfiguration analyzerStatePrinterConfiguration =
      AnalyzerStatePrinterConfiguration();

  final IdProvider _idProvider = IdProvider();

  List<MockSdkLibrary> get additionalMockSdkLibraries => [];

  AnalysisContextCollectionImpl get analysisContextCollection {
    var collection = _analysisContextCollection;
    if (collection != null) {
      return collection;
    }

    createMockSdk(
      resourceProvider: resourceProvider,
      root: sdkRoot,
      additionalLibraries: additionalMockSdkLibraries,
    );

    collection = AnalysisContextCollectionImpl(
      byteStore: _byteStore,
      declaredVariables: _declaredVariables,
      enableIndex: true,
      includedPaths: collectionIncludedPaths.map(convertPath).toList(),
      resourceProvider: resourceProvider,
      retainDataForTesting: retainDataForTesting,
      sdkPath: sdkRoot.path,
      sdkSummaryPath: sdkSummaryFile?.path,
      librarySummaryPaths: librarySummaryFiles?.map((e) => e.path).toList(),
      updateAnalysisOptions2: updateAnalysisOptions,
      macroSupportFactory: macroSupportFactory,
      drainStreams: false,
    );

    _analysisContextCollection = collection;
    verifyCreatedCollection();

    return collection;
  }

  List<String> get collectionIncludedPaths;

  set declaredVariables(Map<String, String> map) {
    if (_analysisContextCollection != null) {
      throw StateError('Declared variables cannot be changed after analysis.');
    }

    _declaredVariables = map;
  }

  bool get retainDataForTesting => false;

  Folder get sdkRoot => newFolder('/sdk');

  void assertBasicWorkspaceFor(File file) {
    var workspace = contextFor(file).contextRoot.workspace;
    expect(workspace, TypeMatcher<BasicWorkspace>());
  }

  void assertBlazeWorkspaceFor(File file) {
    var workspace = contextFor(file).contextRoot.workspace;
    expect(workspace, TypeMatcher<BlazeWorkspace>());
  }

  void assertDriverStateString(File file, String expected) {
    var analysisDriver = driverFor(file);

    var buffer = StringBuffer();
    AnalyzerStatePrinter(
      byteStore: _byteStore,
      unlinkedUnitStore:
          analysisDriver.fsState.unlinkedUnitStore as UnlinkedUnitStoreImpl,
      idProvider: _idProvider,
      libraryContext: analysisDriver.libraryContext,
      configuration: analyzerStatePrinterConfiguration,
      resourceProvider: resourceProvider,
      sink: TreeStringSink(
        sink: buffer,
        indent: '',
      ),
      withKeysGetPut: false,
    ).writeAnalysisDriver(analysisDriver.testView!);
    var actual = buffer.toString();

    if (actual != expected) {
      print(actual);
      NodeTextExpectationsCollector.add(actual);
    }
    expect(actual, expected);
  }

  void assertGnWorkspaceFor(File file) {
    var workspace = contextFor(file).contextRoot.workspace;
    expect(workspace, TypeMatcher<GnWorkspace>());
  }

  void assertPackageConfigWorkspaceFor(File file) {
    var workspace = contextFor(file).contextRoot.workspace;
    expect(workspace, TypeMatcher<PackageConfigWorkspace>());
  }

  AnalysisContext contextFor(File file) {
    return _contextFor(file);
  }

  Future<void> disposeAnalysisContextCollection() async {
    var analysisContextCollection = _analysisContextCollection;
    if (analysisContextCollection != null) {
      await analysisContextCollection.dispose(
        forTesting: true,
      );
      _analysisContextCollection = null;
    }
  }

  AnalysisDriver driverFor(File file) {
    return _contextFor(file).driver;
  }

  Future<LibraryElementImpl> libraryElementForFile(File file) async {
    var analysisContext = contextFor(file);
    var analysisSession = analysisContext.currentSession;

    var uri = analysisSession.uriConverter.pathToUri(file.path);
    var uriStr = uri.toString();
    var libraryResult = await analysisSession.getLibraryByUri(uriStr);
    libraryResult as LibraryElementResultImpl;
    return libraryResult.element as LibraryElementImpl;
  }

  @override
  File newFile(String path, String content) {
    if (_analysisContextCollection != null && !path.endsWith('.dart')) {
      throw StateError('Only dart files can be changed after analysis.');
    }

    return super.newFile(path, content);
  }

  @override
  Future<ResolvedUnitResult> resolveFile(File file) async {
    var analysisContext = contextFor(fileForContextSelection ?? file);
    var session = analysisContext.currentSession;
    return await session.getResolvedUnit(file.path) as ResolvedUnitResult;
  }

  @mustCallSuper
  void setUp() {
    if (!_lintRulesAreRegistered) {
      registerLintRules();
      _lintRulesAreRegistered = true;
    }
  }

  @mustCallSuper
  Future<void> tearDown() async {
    await disposeAnalysisContextCollection();
    KernelCompilationService.disposeDelayed(
      const Duration(milliseconds: 500),
    );
  }

  /// Override this method to update [analysisOptions] for every context root,
  /// the default or already updated with `analysis_options.yaml` file.
  void updateAnalysisOptions({
    required AnalysisOptionsImpl analysisOptions,
    required ContextRoot contextRoot,
    required DartSdk sdk,
  }) {}

  /// Call this method if the test needs to use the empty byte store, without
  /// any information cached.
  void useEmptyByteStore() {
    _byteStore = MemoryByteStore();
  }

  void verifyCreatedCollection() {}

  DriverBasedAnalysisContext _contextFor(File file) {
    return analysisContextCollection.contextFor(file.path);
  }
}

class PubPackageResolutionTest extends ContextResolutionTest
    with MockPackagesMixin {
  AnalysisOptionsImpl get analysisOptions {
    return contextFor(testFile).getAnalysisOptionsForFile(testFile)
        as AnalysisOptionsImpl;
  }

  @override
  List<String> get collectionIncludedPaths => [workspaceRootPath];

  List<String> get experiments => experimentsForTests;

  @override
  String get packagesRootPath => '/packages';

  @override
  File get testFile => getFile('$testPackageLibPath/test.dart');

  /// The language version to use by default for `package:test`.
  String? get testPackageLanguageVersion => null;

  String get testPackageLibPath => '$testPackageRootPath/lib';

  String get testPackageRootPath => '$workspaceRootPath/test';

  String get workspaceRootPath => '/home';

  /// Creates `package:macro` and `package:_macro` files, adds to [config].
  void addMacrosEnvironment(
    PackageConfigFileBuilder config,
    MacrosEnvironment macrosEnvironment,
  ) {
    var packagesRootFolder = getFolder(packagesRootPath);
    macrosEnvironment.publicMacrosFolder.copyTo(packagesRootFolder);
    macrosEnvironment.privateMacrosFolder.copyTo(packagesRootFolder);
    config.add(
      name: '_macros',
      rootPath: getFolder('$packagesRootPath/_macros').path,
    );
    config.add(
      name: 'macros',
      rootPath: getFolder('$packagesRootPath/macros').path,
    );
  }

  /// Build summary bundle for a single URI `package:foo/foo.dart`.
  Future<File> buildPackageFooSummary({
    required Map<String, String> files,
  }) async {
    var rootFolder = getFolder('$workspaceRootPath/foo');

    writePackageConfig(
      rootFolder.path,
      PackageConfigFileBuilder()..add(name: 'foo', rootPath: rootFolder.path),
    );

    for (var entry in files.entries) {
      newFile('${rootFolder.path}/${entry.key}', entry.value);
    }

    var targetFile = getFile(rootFolder.path);
    var analysisDriver = driverFor(targetFile);
    var bundleBytes = await analysisDriver.buildPackageBundle(
      uriList: [
        Uri.parse('package:foo/foo.dart'),
      ],
    );

    var bundleFile = getFile('/home/summaries/packages.sum');
    bundleFile.writeAsBytesSync(bundleBytes);

    // Delete, so it is not available as a file.
    // We don't have a package config for it anyway, but just to be sure.
    rootFolder.delete();

    await disposeAnalysisContextCollection();

    return bundleFile;
  }

  bool configureWithCommonMacros() {
    try {
      writeTestPackageConfig(
        PackageConfigFileBuilder(),
        macrosEnvironment: MacrosEnvironment.instance,
      );

      newFile(
        '$testPackageLibPath/append.dart',
        getMacroCode('append.dart'),
      );

      return true;
    } catch (_) {
      markTestSkipped('Cannot initialize macro environment.');
      return false;
    }
  }

  @override
  void setUp() {
    super.setUp();
    writeTestPackageAnalysisOptionsFile(
      analysisOptionsContent(experiments: experiments),
    );
    writeTestPackageConfig(
      PackageConfigFileBuilder(),
    );
  }

  void writePackageConfig(
    String directoryPath,
    PackageConfigFileBuilder config,
  ) {
    var content = config.toContent(
      toUriStr: toUriStr,
    );
    newPackageConfigJsonFile(directoryPath, content);
  }

  Future<File> writeSdkSummary() async {
    var file = getFile('/home/summaries/sdk.sum');
    var bytes = await buildSdkSummary(
      resourceProvider: resourceProvider,
      sdkPath: sdkRoot.path,
    );
    file.writeAsBytesSync(bytes);
    return file;
  }

  void writeTestPackageAnalysisOptionsFile(String content) {
    newAnalysisOptionsYamlFile(testPackageRootPath, content);
  }

  void writeTestPackageConfig(
    PackageConfigFileBuilder config, {
    String? languageVersion,
    bool angularMeta = false,
    bool ffi = false,
    bool flutter = false,
    bool js = false,
    bool meta = false,
    MacrosEnvironment? macrosEnvironment,
  }) {
    config = config.copy();

    config.add(
      name: 'test',
      rootPath: testPackageRootPath,
      languageVersion: languageVersion ?? testPackageLanguageVersion,
    );

    if (angularMeta) {
      var angularMetaPath = addAngularMeta().parent.path;
      config.add(name: 'angular_meta', rootPath: angularMetaPath);
    }

    if (ffi) {
      var ffiPath = addFfi().parent.path;
      config.add(name: 'ffi', rootPath: ffiPath);
    }

    if (flutter) {
      var uiPath = addUI().parent.path;
      config.add(name: 'ui', rootPath: uiPath);

      var flutterPath = addFlutter().parent.path;
      config.add(name: 'flutter', rootPath: flutterPath);
    }

    if (js) {
      var jsPath = addJs().parent.path;
      config.add(name: 'js', rootPath: jsPath);
    }

    if (meta || flutter) {
      var metaPath = addMeta().parent.path;
      config.add(name: 'meta', rootPath: metaPath);
    }

    if (macrosEnvironment != null) {
      addMacrosEnvironment(config, macrosEnvironment);
    }

    writePackageConfig(testPackageRootPath, config);
  }

  void writeTestPackageConfigWithMeta() {
    writeTestPackageConfig(PackageConfigFileBuilder(), meta: true);
  }

  void writeTestPackagePubspecYamlFile(String content) {
    newPubspecYamlFile(testPackageRootPath, content);
  }
}

class PubspecYamlFileDependency {
  final String name;
  final String version;

  PubspecYamlFileDependency({
    required this.name,
    this.version = 'any',
  });
}

mixin WithLanguage219Mixin on PubPackageResolutionTest {
  @override
  String? get testPackageLanguageVersion => '2.19';
}

mixin WithoutConstructorTearoffsMixin on PubPackageResolutionTest {
  @override
  String? get testPackageLanguageVersion => '2.14';
}

mixin WithoutEnhancedEnumsMixin on PubPackageResolutionTest {
  @override
  String? get testPackageLanguageVersion => '2.16';
}

mixin WithStrictCastsMixin on PubPackageResolutionTest {
  /// Asserts that no errors are reported in [code] when implicit casts are
  /// allowed, and that [expectedErrors] are reported for the same [code] when
  /// implicit casts are not allowed.
  Future<void> assertErrorsWithStrictCasts(
    String code,
    List<ExpectedError> expectedErrors,
  ) async {
    await resolveTestCode(code);
    assertNoErrorsInResult();

    await disposeAnalysisContextCollection();

    writeTestPackageAnalysisOptionsFile(
      analysisOptionsContent(experiments: experiments, strictCasts: true),
    );

    await resolveTestFile();
    assertErrorsInResult(expectedErrors);
  }

  /// Asserts that no errors are reported in [code], both when implicit casts
  /// are allowed and when implicit casts are not allowed.
  Future<void> assertNoErrorsWithStrictCasts(String code) async =>
      assertErrorsWithStrictCasts(code, []);
}
