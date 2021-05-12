// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/context/context_root.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/context/source.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer/src/workspace/basic.dart';
import 'package:analyzer/src/workspace/bazel.dart';
import 'package:analyzer/src/workspace/gn.dart';
import 'package:analyzer/src/workspace/package_build.dart';
import 'package:analyzer/src/workspace/pub.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../embedder_tests.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ContextBuilderTest);
    defineReflectiveTests(EmbedderYamlLocatorTest);
  });
}

@reflectiveTest
class ContextBuilderTest with ResourceProviderMixin {
  /// The SDK manager used by the tests;
  late final DartSdkManager sdkManager;

  /// The content cache used by the tests.
  late final ContentCache contentCache;

  /// The options passed to the context builder.
  ContextBuilderOptions builderOptions = ContextBuilderOptions();

  /// The context builder to be used in the test.
  late ContextBuilder builder;

  /// The path to the default SDK, or `null` if the test has not explicitly
  /// invoked [createDefaultSdk].
  late final String defaultSdkPath;

  Uri convertedDirectoryUri(String directoryPath) {
    return Uri.directory(convertPath(directoryPath),
        windows: resourceProvider.pathContext.style == path.windows.style);
  }

  void createDefaultSdk() {
    defaultSdkPath = convertPath(sdkRoot);
    MockSdk(resourceProvider: resourceProvider);
  }

  void setUp() {
    MockSdk(resourceProvider: resourceProvider);
    sdkManager = DartSdkManager(convertPath('/sdk'));
    contentCache = ContentCache();
    builder = ContextBuilder(
      resourceProvider,
      sdkManager,
      contentCache,
      options: builderOptions,
    );
  }

  @failingTest
  void test_buildContext() {
    fail('Incomplete test');
  }

  @failingTest
  void test_cmdline_options_override_options_file() {
    fail('No clear choice of option to override.');
//    ArgParser argParser = new ArgParser();
//    defineAnalysisArguments(argParser);
//    ArgResults argResults = argParser.parse(['--$enableSuperMixinFlag']);
//    var builder = new ContextBuilder(resourceProvider, sdkManager, contentCache,
//        options: createContextBuilderOptions(argResults));
//
//    AnalysisOptionsImpl expected = new AnalysisOptionsImpl();
//    expected.option = true;
//
//    String path = resourceProvider.convertPath('/some/directory/path');
//    String filePath =
//        join(path, AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE);
//    resourceProvider.newFile(filePath, '''
//analyzer:
//  language:
//    option: true
//''');
//
//    AnalysisOptions options = builder.getAnalysisOptions(path);
//    _expectEqualOptions(options, expected);
  }

  void test_createPackageMap_fromPackageFile_explicit() {
    // Use a package file that is outside the project directory's hierarchy.
    String rootPath = convertPath('/root');
    String projectPath = join(rootPath, 'project');
    String packageFilePath = join(rootPath, 'child', '.packages');
    newFolder(projectPath);
    newFile(packageFilePath, content: '''
foo:${toUriStr('/pkg/foo')}
bar:${toUriStr('/pkg/bar')}
''');

    builderOptions.defaultPackageFilePath = packageFilePath;
    Packages packages = _createPackageMap(projectPath);
    _assertPackages(
      packages,
      {
        'foo': convertPath('/pkg/foo'),
        'bar': convertPath('/pkg/bar'),
      },
    );
  }

  void test_createPackageMap_fromPackageFile_inParentOfRoot() {
    // Use a package file that is inside the parent of the project directory.
    String rootPath = convertPath('/root');
    String projectPath = join(rootPath, 'project');
    String packageFilePath = join(rootPath, '.packages');
    newFolder(projectPath);
    newFile(packageFilePath, content: '''
foo:${toUriStr('/pkg/foo')}
bar:${toUriStr('/pkg/bar')}
''');

    Packages packages = _createPackageMap(projectPath);
    _assertPackages(
      packages,
      {
        'foo': convertPath('/pkg/foo'),
        'bar': convertPath('/pkg/bar'),
      },
    );
  }

  void test_createPackageMap_fromPackageFile_inRoot() {
    // Use a package file that is inside the project directory.
    String rootPath = convertPath('/root');
    String projectPath = join(rootPath, 'project');
    String packageFilePath = join(projectPath, '.packages');
    newFolder(projectPath);
    newFile(packageFilePath, content: '''
foo:${toUriStr('/pkg/foo')}
bar:${toUriStr('/pkg/bar')}
''');

    Packages packages = _createPackageMap(projectPath);
    _assertPackages(
      packages,
      {
        'foo': convertPath('/pkg/foo'),
        'bar': convertPath('/pkg/bar'),
      },
    );
  }

  void test_createPackageMap_none() {
    String rootPath = convertPath('/root');
    newFolder(rootPath);
    Packages packages = _createPackageMap(rootPath);
    expect(packages.packages, isEmpty);
  }

  void test_createPackageMap_rootDoesNotExist() {
    String rootPath = convertPath('/root');
    Packages packages = _createPackageMap(rootPath);
    expect(packages.packages, isEmpty);
  }

  void test_createSourceFactory_bazelWorkspace_fileProvider() {
    String projectPath = convertPath('/workspace/my/module');
    newFile('/workspace/WORKSPACE');
    newFolder('/workspace/bazel-bin');
    newFolder('/workspace/bazel-genfiles');
    newFolder(projectPath);

    var factory = _createSourceFactory(projectPath);
    expect(factory.resolvers,
        contains(predicate((r) => r is BazelFileUriResolver)));
    expect(factory.resolvers,
        contains(predicate((r) => r is BazelPackageUriResolver)));
  }

  void test_createSourceFactory_bazelWorkspace_withPackagesFile() {
    String projectPath = convertPath('/workspace/my/module');
    newFile('/workspace/WORKSPACE');
    newFolder('/workspace/bazel-bin');
    newFolder('/workspace/bazel-genfiles');
    newFolder(projectPath);
    newFile(join(projectPath, '.packages'));

    var factory = _createSourceFactory(projectPath);
    expect(factory.resolvers,
        contains(predicate((r) => r is ResourceUriResolver)));
    expect(factory.resolvers,
        contains(predicate((r) => r is PackageMapUriResolver)));
  }

  void test_createSourceFactory_noProvider_packages_embedder_noExtensions() {
    String rootPath = convertPath('/root');
    createDefaultSdk();
    String projectPath = join(rootPath, 'project');
    String packageFilePath = join(projectPath, '.packages');

    String skyEnginePath = join(rootPath, 'pkgs', 'sky_engine');
    String embedderPath = join(skyEnginePath, '_embedder.yaml');
    String asyncPath = join(skyEnginePath, 'sdk', 'async.dart');
    String corePath = join(skyEnginePath, 'sdk', 'core.dart');
    newFile(embedderPath, content: '''
embedded_libs:
  "dart:async": ${_relativeUri(asyncPath, from: skyEnginePath)}
  "dart:core": ${_relativeUri(corePath, from: skyEnginePath)}
''');

    String packageB = join(rootPath, 'pkgs', 'b');
    newFile(packageFilePath, content: '''
sky_engine:${resourceProvider.pathContext.toUri(skyEnginePath)}
b:${resourceProvider.pathContext.toUri(packageB)}
''');

    SourceFactory factory = _createSourceFactory(projectPath);

    var dartSource = factory.forUri('dart:async')!;
    expect(dartSource, isNotNull);
    expect(dartSource.fullName, asyncPath);

    var packageSource = factory.forUri('package:b/b.dart')!;
    expect(packageSource, isNotNull);
    expect(packageSource.fullName, join(packageB, 'b.dart'));
  }

  @failingTest
  void test_createSourceFactory_noProvider_packages_noEmbedder_extensions() {
    fail('Incomplete test');
  }

  void test_createSourceFactory_noProvider_packages_noEmbedder_noExtensions() {
    String rootPath = convertPath('/root');
    createDefaultSdk();
    String projectPath = join(rootPath, 'project');
    String packageFilePath = join(projectPath, '.packages');
    String packageA = join(rootPath, 'pkgs', 'a');
    String packageB = join(rootPath, 'pkgs', 'b');
    newFile(packageFilePath, content: '''
a:${resourceProvider.pathContext.toUri(packageA)}
b:${resourceProvider.pathContext.toUri(packageB)}
''');

    SourceFactory factory = _createSourceFactory(projectPath);

    var dartSource = factory.forUri('dart:core')!;
    expect(dartSource, isNotNull);
    expect(
        dartSource.fullName, join(defaultSdkPath, 'lib', 'core', 'core.dart'));

    var packageSource = factory.forUri('package:a/a.dart')!;
    expect(packageSource, isNotNull);
    expect(packageSource.fullName, join(packageA, 'a.dart'));
  }

  void test_createWorkspace_hasPackagesFile_hasDartToolAndPubspec() {
    newFile('/workspace/.packages');
    newFolder('/workspace/.dart_tool/build/generated/project/lib');
    newPubspecYamlFile('/workspace', 'name: project');
    Workspace workspace = _createWorkspace('/workspace/project/lib/lib.dart');
    expect(workspace, TypeMatcher<PackageBuildWorkspace>());
  }

  void test_createWorkspace_hasPackagesFile_hasPubspec() {
    newFile('/workspace/.packages');
    newPubspecYamlFile('/workspace', 'name: project');
    Workspace workspace = _createWorkspace('/workspace/project/lib/lib.dart');
    expect(workspace, TypeMatcher<PubWorkspace>());
  }

  void test_createWorkspace_hasPackagesFile_noMarkerFiles() {
    newFile('/workspace/.packages');
    Workspace workspace = _createWorkspace('/workspace/project/lib/lib.dart');
    expect(workspace, TypeMatcher<BasicWorkspace>());
  }

  void test_createWorkspace_noPackagesFile_hasBazelMarkerFiles() {
    newFile('/workspace/WORKSPACE');
    newFolder('/workspace/bazel-genfiles');
    Workspace workspace = _createWorkspace('/workspace/project/lib/lib.dart');
    expect(workspace, TypeMatcher<BazelWorkspace>());
  }

  void test_createWorkspace_noPackagesFile_hasDartToolAndPubspec() {
    newFolder('/workspace/.dart_tool/build/generated/project/lib');
    newPubspecYamlFile('/workspace', 'name: project');
    Workspace workspace = _createWorkspace('/workspace/project/lib/lib.dart');
    expect(workspace, TypeMatcher<PackageBuildWorkspace>());
  }

  void test_createWorkspace_noPackagesFile_hasGnMarkerFiles() {
    newFolder('/workspace/.jiri_root');
    newFile(
        '/workspace/out/debug-x87_128/dartlang/gen/project/lib/lib_package_config.json',
        content: '''{
  "configVersion": 2,
  "packages": []
}''');
    Workspace workspace = _createWorkspace('/workspace/project/lib/lib.dart');
    expect(workspace, TypeMatcher<GnWorkspace>());
  }

  void test_createWorkspace_noPackagesFile_hasPubspec() {
    newPubspecYamlFile('/workspace', 'name: project');
    Workspace workspace = _createWorkspace('/workspace/project/lib/lib.dart');
    expect(workspace, TypeMatcher<PubWorkspace>());
  }

  void test_createWorkspace_noPackagesFile_noMarkerFiles() {
    Workspace workspace = _createWorkspace('/workspace/project/lib/lib.dart');
    expect(workspace, TypeMatcher<BasicWorkspace>());
  }

  @failingTest
  void test_findSdk_embedder_extensions() {
    // See test_createSourceFactory_noProvider_packages_embedder_extensions
    fail('Incomplete test');
  }

  @failingTest
  void test_findSdk_embedder_noExtensions() {
    // See test_createSourceFactory_noProvider_packages_embedder_noExtensions
    fail('Incomplete test');
  }

  @failingTest
  void test_findSdk_noEmbedder_extensions() {
    // See test_createSourceFactory_noProvider_packages_noEmbedder_extensions
    fail('Incomplete test');
  }

  @failingTest
  void test_findSdk_noEmbedder_noExtensions() {
    // See test_createSourceFactory_noProvider_packages_noEmbedder_noExtensions
    fail('Incomplete test');
  }

  void test_findSdk_noPackageMap() {
    DartSdk sdk = builder.findSdk(null);
    expect(sdk, isNotNull);
  }

  void test_findSdk_noPackageMap_html_strong() {
    DartSdk sdk = builder.findSdk(null);
    expect(sdk, isNotNull);
    Source htmlSource = sdk.mapDartUri('dart:html')!;
    expect(htmlSource.fullName,
        convertPath('/sdk/lib/html/dart2js/html_dart2js.dart'));
    expect(htmlSource.exists(), isTrue);
  }

  void test_getAnalysisOptions_gnWorkspace() {
    String projectPath = convertPath('/workspace/some/path');
    newFolder('/workspace/.jiri_root');
    newFile('/workspace/out/debug/gen/dart.sources/foo_pkg',
        content: convertPath('/workspace/foo_pkg/lib'));
    newFolder(projectPath);
    builder = ContextBuilder(resourceProvider, sdkManager, contentCache,
        options: builderOptions);
    AnalysisOptionsImpl expected = AnalysisOptionsImpl();
    var options = _getAnalysisOptions(builder, projectPath);
    _expectEqualOptions(options, expected);
  }

  void test_getAnalysisOptions_invalid() {
    String path = convertPath('/some/directory/path');
    newAnalysisOptionsYamlFile(path, content: ';');

    AnalysisOptions options = _getAnalysisOptions(builder, path);
    expect(options, isNotNull);
  }

  void test_getAnalysisOptions_noDefault_noOverrides() {
    String path = convertPath('/some/directory/path');
    newAnalysisOptionsYamlFile(path, content: '''
linter:
  rules:
    - non_existent_lint_rule
''');

    var options = _getAnalysisOptions(builder, path);
    _expectEqualOptions(options, AnalysisOptionsImpl());
  }

  void test_getAnalysisOptions_sdkVersionConstraint() {
    var projectPath = convertPath('/test');
    newPubspecYamlFile(projectPath, '''
environment:
  sdk: ^2.1.0
''');

    var options = _getAnalysisOptions(builder, projectPath);
    expect(options.sdkVersionConstraint.toString(), '^2.1.0');
  }

  void test_getAnalysisOptions_sdkVersionConstraint_any_noOptionsFile() {
    var projectPath = convertPath('/test');
    var options = _getAnalysisOptions(builder, projectPath);
    expect(options.sdkVersionConstraint, isNull);
  }

  void _assertPackages(Packages packages, Map<String, String> nameToPath) {
    expect(packages, isNotNull);
    expect(packages.packages, hasLength(nameToPath.length));
    for (var name in nameToPath.keys) {
      var expectedPath = nameToPath[name];
      var path = packages[name]!.libFolder.path;
      expect(path, expectedPath, reason: 'package $name');
    }
  }

  Packages _createPackageMap(String rootPath) {
    return ContextBuilder.createPackageMap(
      resourceProvider: resourceProvider,
      options: builderOptions,
      rootPath: rootPath,
    );
  }

  SourceFactoryImpl _createSourceFactory(String projectPath) {
    Workspace workspace = ContextBuilder.createWorkspace(
      resourceProvider: resourceProvider,
      options: builderOptions,
      rootPath: projectPath,
    );
    return builder.createSourceFactory(projectPath, workspace)
        as SourceFactoryImpl;
  }

  Workspace _createWorkspace(String posixPath) {
    return ContextBuilder.createWorkspace(
      resourceProvider: resourceProvider,
      options: ContextBuilderOptions(),
      rootPath: convertPath(posixPath),
    );
  }

  void _expectEqualOptions(
      AnalysisOptionsImpl actual, AnalysisOptionsImpl expected) {
    // TODO(brianwilkerson) Consider moving this to AnalysisOptionsImpl.==.
    expect(actual.enableTiming, expected.enableTiming);
    expect(actual.hint, expected.hint);
    expect(actual.lint, expected.lint);
    expect(
      actual.lintRules.map((l) => l.name),
      unorderedEquals(expected.lintRules.map((l) => l.name)),
    );
    expect(actual.implicitCasts, expected.implicitCasts);
    expect(actual.implicitDynamic, expected.implicitDynamic);
    expect(actual.strictInference, expected.strictInference);
    expect(actual.strictRawTypes, expected.strictRawTypes);
  }

  AnalysisOptionsImpl _getAnalysisOptions(ContextBuilder builder, String path,
      {ContextRoot? contextRoot}) {
    Workspace workspace = ContextBuilder.createWorkspace(
      resourceProvider: resourceProvider,
      options: builder.builderOptions,
      rootPath: path,
    );
    return builder.getAnalysisOptions(path, workspace,
        contextRoot: contextRoot);
  }

  Uri _relativeUri(String path, {String? from}) {
    var pathContext = resourceProvider.pathContext;
    String relativePath = pathContext.relative(path, from: from);
    return pathContext.toUri(relativePath);
  }
}

@reflectiveTest
class EmbedderYamlLocatorTest extends EmbedderRelatedTest {
  void test_empty() {
    EmbedderYamlLocator locator = EmbedderYamlLocator({
      'fox': <Folder>[pathTranslator.getResource(emptyPath) as Folder]
    });
    expect(locator.embedderYamls, hasLength(0));
  }

  void test_invalid() {
    EmbedderYamlLocator locator = EmbedderYamlLocator(null);
    locator.addEmbedderYaml(
      pathTranslator.getResource(foxLib) as Folder,
      r'''{{{,{{}}},}}''',
    );
    expect(locator.embedderYamls, hasLength(0));
  }

  void test_valid() {
    EmbedderYamlLocator locator = EmbedderYamlLocator({
      'fox': <Folder>[pathTranslator.getResource(foxLib) as Folder]
    });
    expect(locator.embedderYamls, hasLength(1));
  }
}
