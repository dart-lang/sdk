// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/command_line/arguments.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/context/context_root.dart';
import 'package:analyzer/src/context/source.dart';
import 'package:analyzer/src/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/lint/linter.dart';
import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/services/lint.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer/src/workspace/basic.dart';
import 'package:analyzer/src/workspace/bazel.dart';
import 'package:analyzer/src/workspace/gn.dart';
import 'package:analyzer/src/workspace/package_build.dart';
import 'package:analyzer/src/workspace/pub.dart';
import 'package:analyzer/src/workspace/workspace.dart';
import 'package:args/args.dart';
import 'package:package_config/packages.dart';
import 'package:package_config/src/packages_impl.dart';
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
  /**
   * The SDK manager used by the tests;
   */
  DartSdkManager sdkManager;

  /**
   * The content cache used by the tests.
   */
  ContentCache contentCache;

  /**
   * The options passed to the context builder.
   */
  ContextBuilderOptions builderOptions = new ContextBuilderOptions();

  /**
   * The context builder to be used in the test.
   */
  ContextBuilder builder;

  /**
   * The path to the default SDK, or `null` if the test has not explicitly
   * invoked [createDefaultSdk].
   */
  String defaultSdkPath;

  _MockLintRule _mockLintRule;
  _MockLintRule _mockLintRule2;
  _MockLintRule _mockLintRule3;
  _MockLintRule _mockPublicMemberApiDocs;

  Uri convertedDirectoryUri(String directoryPath) {
    return new Uri.directory(convertPath(directoryPath),
        windows: resourceProvider.pathContext.style == path.windows.style);
  }

  void createDefaultSdk(Folder sdkDir) {
    defaultSdkPath = join(sdkDir.path, 'default', 'sdk');
    String librariesFilePath = join(defaultSdkPath, 'lib', '_internal',
        'sdk_library_metadata', 'lib', 'libraries.dart');
    newFile(librariesFilePath, content: r'''
const Map<String, LibraryInfo> libraries = const {
  "async": const LibraryInfo("async/async.dart"),
  "core": const LibraryInfo("core/core.dart"),
};
''');
    sdkManager = new DartSdkManager(defaultSdkPath, false);
    builder = new ContextBuilder(resourceProvider, sdkManager, contentCache,
        options: builderOptions);
  }

  void setUp() {
    new MockSdk(resourceProvider: resourceProvider);
    sdkManager = new DartSdkManager(convertPath('/sdk'), false);
    contentCache = new ContentCache();
    builder = new ContextBuilder(
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

  void test_cmdline_lint_defined() {
    _defineMockLintRules();
    ArgParser argParser = new ArgParser();
    defineAnalysisArguments(argParser);
    ArgResults argResults = argParser.parse(['--$lintsFlag']);
    var builder = new ContextBuilder(resourceProvider, sdkManager, contentCache,
        options: createContextBuilderOptions(argResults));

    AnalysisOptionsImpl expected = new AnalysisOptionsImpl();
    expected.lint = true;
    expected.lintRules = <LintRule>[
      Registry.ruleRegistry['mock_lint_rule'],
    ];

    String path = convertPath('/some/directory/path');
    String filePath = join(path, AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE);
    newFile(filePath, content: '''
linter:
  rules:
    - mock_lint_rule
''');

    AnalysisOptions options = builder.getAnalysisOptions(path);
    _expectEqualOptions(options, expected);
  }

  void test_cmdline_lint_off() {
    ArgParser argParser = new ArgParser();
    defineAnalysisArguments(argParser);
    ArgResults argResults = argParser.parse(['--no-$lintsFlag']);
    var builder = new ContextBuilder(resourceProvider, sdkManager, contentCache,
        options: createContextBuilderOptions(argResults));

    AnalysisOptionsImpl expected = new AnalysisOptionsImpl();
    expected.lint = false;
    expected.lintRules = <LintRule>[
      Registry.ruleRegistry['mock_lint_rule'],
    ];

    String path = convertPath('/some/directory/path');
    String filePath = join(path, AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE);
    newFile(filePath, content: '''
linter:
  rules:
    - mock_lint_rule
''');

    AnalysisOptions options = builder.getAnalysisOptions(path);
    _expectEqualOptions(options, expected);
  }

  void test_cmdline_lint_unspecified_1() {
    ArgParser argParser = new ArgParser();
    defineAnalysisArguments(argParser);
    ArgResults argResults = argParser.parse([]);
    var builder = new ContextBuilder(resourceProvider, sdkManager, contentCache,
        options: createContextBuilderOptions(argResults));

    AnalysisOptionsImpl expected = new AnalysisOptionsImpl();
    expected.lint = true;
    expected.lintRules = <LintRule>[
      Registry.ruleRegistry['mock_lint_rule'],
    ];

    String path = convertPath('/some/directory/path');
    String filePath = join(path, AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE);
    newFile(filePath, content: '''
linter:
  rules:
    - mock_lint_rule
''');

    AnalysisOptions options = builder.getAnalysisOptions(path);
    _expectEqualOptions(options, expected);
  }

  void test_cmdline_lint_unspecified_2() {
    ArgParser argParser = new ArgParser();
    defineAnalysisArguments(argParser);
    ArgResults argResults = argParser.parse([]);
    var builder = new ContextBuilder(resourceProvider, sdkManager, contentCache,
        options: createContextBuilderOptions(argResults));

    AnalysisOptionsImpl expected = new AnalysisOptionsImpl();
    expected.lint = false;
    expected.lintRules = <LintRule>[];

    String path = convertPath('/some/directory/path');
    String filePath = join(path, AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE);
    newFile(filePath, content: '''
''');

    AnalysisOptions options = builder.getAnalysisOptions(path);
    _expectEqualOptions(options, expected);
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

  void test_convertPackagesToMap_noPackages() {
    expect(builder.convertPackagesToMap(Packages.noPackages), isEmpty);
  }

  void test_convertPackagesToMap_null() {
    expect(builder.convertPackagesToMap(null), isEmpty);
  }

  void test_convertPackagesToMap_packages() {
    String fooName = 'foo';
    String fooPath = convertPath('/pkg/foo');
    Uri fooUri = resourceProvider.pathContext.toUri(fooPath);
    String barName = 'bar';
    String barPath = convertPath('/pkg/bar');
    Uri barUri = resourceProvider.pathContext.toUri(barPath);

    MapPackages packages = new MapPackages({fooName: fooUri, barName: barUri});
    Map<String, List<Folder>> result = builder.convertPackagesToMap(packages);
    expect(result, isNotNull);
    expect(result, hasLength(2));
    expect(result[fooName], hasLength(1));
    expect(result[fooName][0].path, fooPath);
    expect(result[barName], hasLength(1));
    expect(result[barName][0].path, barPath);
  }

  void test_createDefaultOptions_default() {
    // Invert a subset of the options to ensure that the default options are
    // being returned.
    AnalysisOptionsImpl defaultOptions = new AnalysisOptionsImpl();
    defaultOptions.dart2jsHint = !defaultOptions.dart2jsHint;
    defaultOptions.enableLazyAssignmentOperators =
        !defaultOptions.enableLazyAssignmentOperators;
    builderOptions.defaultOptions = defaultOptions;
    AnalysisOptions options = builder.createDefaultOptions();
    _expectEqualOptions(options, defaultOptions);
  }

  void test_createDefaultOptions_noDefault() {
    AnalysisOptions options = builder.createDefaultOptions();
    _expectEqualOptions(options, new AnalysisOptionsImpl());
  }

  void test_createPackageMap_fromPackageDirectory_explicit() {
    // Use a package directory that is outside the project directory.
    String rootPath = convertPath('/root');
    String projectPath = join(rootPath, 'project');
    String packageDirPath = join(rootPath, 'packages');
    String fooName = 'foo';
    String fooPath = join(packageDirPath, fooName);
    String barName = 'bar';
    String barPath = join(packageDirPath, barName);
    newFolder(projectPath);
    newFolder(fooPath);
    newFolder(barPath);

    builderOptions.defaultPackagesDirectoryPath = packageDirPath;

    Packages packages = builder.createPackageMap(projectPath);
    expect(packages, isNotNull);
    Map<String, Uri> map = packages.asMap();
    expect(map, hasLength(2));
    expect(map[fooName], convertedDirectoryUri(fooPath));
    expect(map[barName], convertedDirectoryUri(barPath));
  }

  void test_createPackageMap_fromPackageDirectory_inRoot() {
    // Use a package directory that is inside the project directory.
    String projectPath = convertPath('/root/project');
    String packageDirPath = join(projectPath, 'packages');
    String fooName = 'foo';
    String fooPath = join(packageDirPath, fooName);
    String barName = 'bar';
    String barPath = join(packageDirPath, barName);
    newFolder(fooPath);
    newFolder(barPath);

    Packages packages = builder.createPackageMap(projectPath);
    expect(packages, isNotNull);
    Map<String, Uri> map = packages.asMap();
    expect(map, hasLength(2));
    expect(map[fooName], convertedDirectoryUri(fooPath));
    expect(map[barName], convertedDirectoryUri(barPath));
  }

  void test_createPackageMap_fromPackageFile_explicit() {
    // Use a package file that is outside the project directory's hierarchy.
    String rootPath = convertPath('/root');
    String projectPath = join(rootPath, 'project');
    String packageFilePath = join(rootPath, 'child', '.packages');
    newFolder(projectPath);
    Uri fooUri = convertedDirectoryUri('/pkg/foo');
    Uri barUri = convertedDirectoryUri('/pkg/bar');
    newFile(packageFilePath, content: '''
foo:$fooUri
bar:$barUri
''');

    builderOptions.defaultPackageFilePath = packageFilePath;
    Packages packages = builder.createPackageMap(projectPath);
    expect(packages, isNotNull);
    Map<String, Uri> map = packages.asMap();
    expect(map, hasLength(2));
    expect(map['foo'], fooUri);
    expect(map['bar'], barUri);
  }

  void test_createPackageMap_fromPackageFile_inParentOfRoot() {
    // Use a package file that is inside the parent of the project directory.
    String rootPath = convertPath('/root');
    String projectPath = join(rootPath, 'project');
    String packageFilePath = join(rootPath, '.packages');
    newFolder(projectPath);
    Uri fooUri = convertedDirectoryUri('/pkg/foo');
    Uri barUri = convertedDirectoryUri('/pkg/bar');
    newFile(packageFilePath, content: '''
foo:$fooUri
bar:$barUri
''');

    Packages packages = builder.createPackageMap(projectPath);
    expect(packages, isNotNull);
    Map<String, Uri> map = packages.asMap();
    expect(map, hasLength(2));
    expect(map['foo'], fooUri);
    expect(map['bar'], barUri);
  }

  void test_createPackageMap_fromPackageFile_inRoot() {
    // Use a package file that is inside the project directory.
    String rootPath = convertPath('/root');
    String projectPath = join(rootPath, 'project');
    String packageFilePath = join(projectPath, '.packages');
    newFolder(projectPath);
    Uri fooUri = convertedDirectoryUri('/pkg/foo');
    Uri barUri = convertedDirectoryUri('/pkg/bar');
    newFile(packageFilePath, content: '''
foo:$fooUri
bar:$barUri
''');

    Packages packages = builder.createPackageMap(projectPath);
    expect(packages, isNotNull);
    Map<String, Uri> map = packages.asMap();
    expect(map, hasLength(2));
    expect(map['foo'], fooUri);
    expect(map['bar'], barUri);
  }

  void test_createPackageMap_none() {
    String rootPath = convertPath('/root');
    newFolder(rootPath);
    Packages packages = builder.createPackageMap(rootPath);
    expect(packages, same(Packages.noPackages));
  }

  void test_createPackageMap_rootDoesNotExist() {
    String rootPath = convertPath('/root');
    Packages packages = builder.createPackageMap(rootPath);
    expect(packages, same(Packages.noPackages));
  }

  void test_createSourceFactory_bazelWorkspace_fileProvider() {
    String projectPath = convertPath('/workspace/my/module');
    newFile('/workspace/WORKSPACE');
    newFolder('/workspace/bazel-bin');
    newFolder('/workspace/bazel-genfiles');
    newFolder(projectPath);

    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    SourceFactoryImpl factory =
        builder.createSourceFactory(projectPath, options);
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

    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    SourceFactoryImpl factory =
        builder.createSourceFactory(projectPath, options);
    expect(factory.resolvers,
        contains(predicate((r) => r is ResourceUriResolver)));
    expect(factory.resolvers,
        contains(predicate((r) => r is PackageMapUriResolver)));
  }

  void test_createSourceFactory_noProvider_packages_embedder_extensions() {
    String rootPath = convertPath('/root');
    Folder rootFolder = getFolder(rootPath);
    createDefaultSdk(rootFolder);
    String projectPath = join(rootPath, 'project');
    String packageFilePath = join(projectPath, '.packages');
    String packageA = join(rootPath, 'pkgs', 'a');
    String embedderPath = join(packageA, '_embedder.yaml');
    String packageB = join(rootPath, 'pkgs', 'b');
    String extensionPath = join(packageB, '_sdkext');
    newFile(packageFilePath, content: '''
a:${resourceProvider.pathContext.toUri(packageA)}
b:${resourceProvider.pathContext.toUri(packageB)}
''');
    String asyncPath = join(packageA, 'sdk', 'async.dart');
    String corePath = join(packageA, 'sdk', 'core.dart');
    newFile(embedderPath, content: '''
embedded_libs:
  "dart:async": ${_relativeUri(asyncPath, from: packageA)}
  "dart:core": ${_relativeUri(corePath, from: packageA)}
''');
    String fooPath = join(packageB, 'ext', 'foo.dart');
    newFile(extensionPath, content: '''{
"dart:foo": "${_relativeUri(fooPath, from: packageB)}"
}''');
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();

    SourceFactory factory = builder.createSourceFactory(projectPath, options);

    Source asyncSource = factory.forUri('dart:async');
    expect(asyncSource, isNotNull);
    expect(asyncSource.fullName, asyncPath);

    Source fooSource = factory.forUri('dart:foo');
    expect(fooSource, isNotNull);
    expect(fooSource.fullName, fooPath);

    Source packageSource = factory.forUri('package:b/b.dart');
    expect(packageSource, isNotNull);
    expect(packageSource.fullName, join(packageB, 'b.dart'));
  }

  void test_createSourceFactory_noProvider_packages_embedder_noExtensions() {
    String rootPath = convertPath('/root');
    Folder rootFolder = getFolder(rootPath);
    createDefaultSdk(rootFolder);
    String projectPath = join(rootPath, 'project');
    String packageFilePath = join(projectPath, '.packages');
    String packageA = join(rootPath, 'pkgs', 'a');
    String embedderPath = join(packageA, '_embedder.yaml');
    String packageB = join(rootPath, 'pkgs', 'b');
    newFile(packageFilePath, content: '''
a:${resourceProvider.pathContext.toUri(packageA)}
b:${resourceProvider.pathContext.toUri(packageB)}
''');
    String asyncPath = join(packageA, 'sdk', 'async.dart');
    String corePath = join(packageA, 'sdk', 'core.dart');
    newFile(embedderPath, content: '''
embedded_libs:
  "dart:async": ${_relativeUri(asyncPath, from: packageA)}
  "dart:core": ${_relativeUri(corePath, from: packageA)}
''');
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();

    SourceFactory factory = builder.createSourceFactory(projectPath, options);

    Source dartSource = factory.forUri('dart:async');
    expect(dartSource, isNotNull);
    expect(dartSource.fullName, asyncPath);

    Source packageSource = factory.forUri('package:b/b.dart');
    expect(packageSource, isNotNull);
    expect(packageSource.fullName, join(packageB, 'b.dart'));
  }

  @failingTest
  void test_createSourceFactory_noProvider_packages_noEmbedder_extensions() {
    fail('Incomplete test');
  }

  void test_createSourceFactory_noProvider_packages_noEmbedder_noExtensions() {
    String rootPath = convertPath('/root');
    Folder rootFolder = getFolder(rootPath);
    createDefaultSdk(rootFolder);
    String projectPath = join(rootPath, 'project');
    String packageFilePath = join(projectPath, '.packages');
    String packageA = join(rootPath, 'pkgs', 'a');
    String packageB = join(rootPath, 'pkgs', 'b');
    newFile(packageFilePath, content: '''
a:${resourceProvider.pathContext.toUri(packageA)}
b:${resourceProvider.pathContext.toUri(packageB)}
''');
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();

    SourceFactory factory = builder.createSourceFactory(projectPath, options);

    Source dartSource = factory.forUri('dart:core');
    expect(dartSource, isNotNull);
    expect(
        dartSource.fullName, join(defaultSdkPath, 'lib', 'core', 'core.dart'));

    Source packageSource = factory.forUri('package:a/a.dart');
    expect(packageSource, isNotNull);
    expect(packageSource.fullName, join(packageA, 'a.dart'));
  }

  void test_createWorkspace_hasPackagesFile_hasDartToolAndPubspec() {
    newFile('/workspace/.packages');
    newFolder('/workspace/.dart_tool/build/generated/project/lib');
    newFileWithBytes('/workspace/pubspec.yaml', 'name: project'.codeUnits);
    Workspace workspace = ContextBuilder.createWorkspace(resourceProvider,
        convertPath('/workspace/project/lib/lib.dart'), builder);
    expect(workspace, TypeMatcher<PackageBuildWorkspace>());
  }

  void test_createWorkspace_hasPackagesFile_hasPubspec() {
    newFile('/workspace/.packages');
    newFileWithBytes('/workspace/pubspec.yaml', 'name: project'.codeUnits);
    Workspace workspace = ContextBuilder.createWorkspace(resourceProvider,
        convertPath('/workspace/project/lib/lib.dart'), builder);
    expect(workspace, TypeMatcher<PubWorkspace>());
  }

  void test_createWorkspace_hasPackagesFile_noMarkerFiles() {
    newFile('/workspace/.packages');
    Workspace workspace = ContextBuilder.createWorkspace(resourceProvider,
        convertPath('/workspace/project/lib/lib.dart'), builder);
    expect(workspace, TypeMatcher<BasicWorkspace>());
  }

  void test_createWorkspace_noPackagesFile_hasBazelMarkerFiles() {
    newFile('/workspace/WORKSPACE');
    newFolder('/workspace/bazel-genfiles');
    Workspace workspace = ContextBuilder.createWorkspace(resourceProvider,
        convertPath('/workspace/project/lib/lib.dart'), builder);
    expect(workspace, TypeMatcher<BazelWorkspace>());
  }

  void test_createWorkspace_noPackagesFile_hasDartToolAndPubspec() {
    newFolder('/workspace/.dart_tool/build/generated/project/lib');
    newFileWithBytes('/workspace/pubspec.yaml', 'name: project'.codeUnits);
    Workspace workspace = ContextBuilder.createWorkspace(resourceProvider,
        convertPath('/workspace/project/lib/lib.dart'), builder);
    expect(workspace, TypeMatcher<PackageBuildWorkspace>());
  }

  void test_createWorkspace_noPackagesFile_hasGnMarkerFiles() {
    newFolder('/workspace/.jiri_root');
    newFile(
        '/workspace/out/debug-x87_128/dartlang/gen/project/lib/lib.packages');
    Workspace workspace = ContextBuilder.createWorkspace(resourceProvider,
        convertPath('/workspace/project/lib/lib.dart'), builder);
    expect(workspace, TypeMatcher<GnWorkspace>());
  }

  void test_createWorkspace_noPackagesFile_hasPubspec() {
    newFileWithBytes('/workspace/pubspec.yaml', 'name: project'.codeUnits);
    Workspace workspace = ContextBuilder.createWorkspace(resourceProvider,
        convertPath('/workspace/project/lib/lib.dart'), builder);
    expect(workspace, TypeMatcher<PubWorkspace>());
  }

  void test_createWorkspace_noPackagesFile_noMarkerFiles() {
    Workspace workspace = ContextBuilder.createWorkspace(resourceProvider,
        convertPath('/workspace/project/lib/lib.dart'), builder);
    expect(workspace, TypeMatcher<BasicWorkspace>());
  }

  void test_declareVariables_emptyMap() {
    AnalysisContext context = AnalysisEngine.instance.createAnalysisContext();
    Iterable<String> expected = context.declaredVariables.variableNames;
    builderOptions.declaredVariables = <String, String>{};

    builder.declareVariables(context);
    expect(context.declaredVariables.variableNames, unorderedEquals(expected));
  }

  void test_declareVariables_nonEmptyMap() {
    AnalysisContext context = AnalysisEngine.instance.createAnalysisContext();
    List<String> expected = context.declaredVariables.variableNames.toList();
    expect(expected, isNot(contains('a')));
    expect(expected, isNot(contains('b')));
    expected.addAll(['a', 'b']);
    builderOptions.declaredVariables = <String, String>{'a': 'a', 'b': 'b'};

    builder.declareVariables(context);
    expect(context.declaredVariables.variableNames, unorderedEquals(expected));
  }

  void test_declareVariables_null() {
    AnalysisContext context = AnalysisEngine.instance.createAnalysisContext();
    Iterable<String> expected = context.declaredVariables.variableNames;

    builder.declareVariables(context);
    expect(context.declaredVariables.variableNames, unorderedEquals(expected));
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
    DartSdk sdk = builder.findSdk(null, new AnalysisOptionsImpl());
    expect(sdk, isNotNull);
  }

  void test_findSdk_noPackageMap_html_strong() {
    DartSdk sdk = builder.findSdk(null, new AnalysisOptionsImpl());
    expect(sdk, isNotNull);
    Source htmlSource = sdk.mapDartUri('dart:html');
    expect(htmlSource.fullName,
        convertPath('/sdk/lib/html/dart2js/html_dart2js.dart'));
    expect(htmlSource.exists(), isTrue);
  }

  void test_getAnalysisOptions_default_bazel() {
    _defineMockLintRules();
    AnalysisOptionsImpl defaultOptions = new AnalysisOptionsImpl();
    builderOptions.defaultOptions = defaultOptions;
    AnalysisOptionsImpl expected = new AnalysisOptionsImpl();
    expected.lint = true;
    expected.lintRules = <Linter>[_mockLintRule];
    newFile('/root/WORKSPACE');
    newFile('/root/dart/analysis_options/lib/default.yaml', content: '''
linter:
  rules:
    - mock_lint_rule
''');
    newFile('/root/dart/analysis_options/lib/flutter.yaml', content: '''
linter:
  rules:
    - mock_lint_rule2
''');
    AnalysisOptions options =
        builder.getAnalysisOptions(convertPath('/root/some/path'));
    _expectEqualOptions(options, expected);
  }

  void test_getAnalysisOptions_default_flutter() {
    _defineMockLintRules();
    AnalysisOptionsImpl defaultOptions = new AnalysisOptionsImpl();
    builderOptions.defaultOptions = defaultOptions;
    AnalysisOptionsImpl expected = new AnalysisOptionsImpl();
    expected.lint = true;
    expected.lintRules = <Linter>[_mockLintRule];
    String packagesFilePath = convertPath('/some/directory/path/.packages');
    newFile(packagesFilePath, content: 'flutter:/pkg/flutter/lib/');
    newFile('/pkg/flutter/lib/analysis_options_user.yaml', content: '''
linter:
  rules:
    - mock_lint_rule
''');
    String projectPath = convertPath('/some/directory/path');
    AnalysisOptions options = builder.getAnalysisOptions(projectPath);
    _expectEqualOptions(options, expected);
  }

  void test_getAnalysisOptions_default_noOverrides() {
    AnalysisOptionsImpl defaultOptions = new AnalysisOptionsImpl();
    defaultOptions.enableLazyAssignmentOperators = true;
    builderOptions.defaultOptions = defaultOptions;
    AnalysisOptionsImpl expected = new AnalysisOptionsImpl();
    expected.enableLazyAssignmentOperators = true;
    String path = convertPath('/some/directory/path');
    String filePath = join(path, AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE);
    newFile(filePath, content: '''
linter:
  rules:
    - empty_constructor_bodies
''');

    AnalysisOptions options = builder.getAnalysisOptions(path);
    _expectEqualOptions(options, expected);
  }

  void test_getAnalysisOptions_default_overrides() {
    AnalysisOptionsImpl defaultOptions = new AnalysisOptionsImpl();
    defaultOptions.implicitDynamic = true;
    builderOptions.defaultOptions = defaultOptions;
    AnalysisOptionsImpl expected = new AnalysisOptionsImpl();
    expected.implicitDynamic = false;
    String path = convertPath('/some/directory/path');
    String filePath = join(path, AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE);
    newFile(filePath, content: '''
analyzer:
  strong-mode:
    implicit-dynamic: false
''');

    AnalysisOptions options = builder.getAnalysisOptions(path);
    _expectEqualOptions(options, expected);
  }

  void test_getAnalysisOptions_gnWorkspace() {
    String _p(String path) => convertPath(path);
    String projectPath = _p('/workspace/some/path');
    newFolder('/workspace/.jiri_root');
    newFile('/workspace/out/debug/gen/dart.sources/foo_pkg',
        content: _p('/workspace/foo_pkg/lib'));
    newFolder(projectPath);
    ArgParser argParser = new ArgParser();
    defineAnalysisArguments(argParser);
    ArgResults argResults = argParser.parse([]);
    builderOptions = createContextBuilderOptions(argResults);
    builder = new ContextBuilder(resourceProvider, sdkManager, contentCache,
        options: builderOptions);
    AnalysisOptionsImpl expected = new AnalysisOptionsImpl();
    AnalysisOptions options = builder.getAnalysisOptions(projectPath);
    _expectEqualOptions(options, expected);
  }

  void test_getAnalysisOptions_includes() {
    _defineMockLintRules();
    AnalysisOptionsImpl defaultOptions = new AnalysisOptionsImpl();
    builderOptions.defaultOptions = defaultOptions;
    AnalysisOptionsImpl expected = new AnalysisOptionsImpl();
    expected.lint = true;
    expected.lintRules = <Linter>[
      _mockLintRule,
      _mockLintRule2,
      _mockLintRule3
    ];
    newFile('/mypkgs/somepkg/lib/here.yaml', content: '''
linter:
  rules:
    - mock_lint_rule3
''');
    String path = convertPath('/some/directory/path');
    newFile(join(path, '.packages'), content: '''
somepkg:../../../mypkgs/somepkg/lib
''');
    newFile(join(path, 'bar.yaml'), content: '''
include: package:somepkg/here.yaml
linter:
  rules:
    - mock_lint_rule2
''');
    String filePath = join(path, AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE);
    newFile(filePath, content: '''
include: bar.yaml
linter:
  rules:
    - mock_lint_rule
''');

    AnalysisOptions options = builder.getAnalysisOptions(path);
    _expectEqualOptions(options, expected);
  }

  void test_getAnalysisOptions_invalid() {
    String path = convertPath('/some/directory/path');
    String filePath = join(path, AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE);
    newFile(filePath, content: ';');

    AnalysisOptions options = builder.getAnalysisOptions(path);
    expect(options, isNotNull);
  }

  void test_getAnalysisOptions_noDefault_noOverrides() {
    String path = convertPath('/some/directory/path');
    String filePath = join(path, AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE);
    newFile(filePath, content: '''
linter:
  rules:
    - empty_constructor_bodies
''');

    AnalysisOptions options = builder.getAnalysisOptions(path);
    _expectEqualOptions(options, new AnalysisOptionsImpl());
  }

  void test_getAnalysisOptions_noDefault_overrides() {
    AnalysisOptionsImpl expected = new AnalysisOptionsImpl();
    expected.implicitDynamic = false;
    String path = convertPath('/some/directory/path');
    String filePath = join(path, AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE);
    newFile(filePath, content: '''
analyzer:
  strong-mode:
    implicit-dynamic: false
''');

    AnalysisOptions options = builder.getAnalysisOptions(path);
    _expectEqualOptions(options, expected);
  }

  void test_getAnalysisOptions_optionsPath() {
    String path = convertPath('/some/directory/path');
    String filePath = join(path, AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE);
    newFile(filePath, content: '''
linter:
  rules:
    - empty_constructor_bodies
''');

    ContextRoot root =
        new ContextRoot(path, [], pathContext: resourceProvider.pathContext);
    builder.getAnalysisOptions(path, contextRoot: root);
    expect(root.optionsFilePath, equals(filePath));
  }

  void test_getAnalysisOptions_sdkVersionConstraint() {
    var projectPath = convertPath('/test');
    newFile(join(projectPath, AnalysisEngine.PUBSPEC_YAML_FILE), content: '''
environment:
  sdk: ^2.1.0
''');

    var options = builder.getAnalysisOptions(projectPath);
    expect(options.sdkVersionConstraint.toString(), '^2.1.0');
  }

  void test_getAnalysisOptions_sdkVersionConstraint_any_noOptionsFile() {
    var projectPath = convertPath('/test');
    var options = builder.getAnalysisOptions(projectPath);
    expect(options.sdkVersionConstraint, isNull);
  }

  void test_getOptionsFile_explicit() {
    String path = convertPath('/some/directory/path');
    String filePath = convertPath('/options/analysis.yaml');
    newFile(filePath);

    builderOptions.defaultAnalysisOptionsFilePath = filePath;
    File result = builder.getOptionsFile(path);
    expect(result, isNotNull);
    expect(result.path, filePath);
  }

  void test_getOptionsFile_inParentOfRoot_new() {
    String parentPath = convertPath('/some/directory');
    String path = join(parentPath, 'path');
    String filePath =
        join(parentPath, AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE);
    newFile(filePath);

    File result = builder.getOptionsFile(path);
    expect(result, isNotNull);
    expect(result.path, filePath);
  }

  void test_getOptionsFile_inParentOfRoot_old() {
    String parentPath = convertPath('/some/directory');
    String path = join(parentPath, 'path');
    String filePath = join(parentPath, AnalysisEngine.ANALYSIS_OPTIONS_FILE);
    newFile(filePath);

    File result = builder.getOptionsFile(path);
    expect(result, isNotNull);
    expect(result.path, filePath);
  }

  void test_getOptionsFile_inRoot_new() {
    String path = convertPath('/some/directory/path');
    String filePath = join(path, AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE);
    newFile(filePath);

    File result = builder.getOptionsFile(path);
    expect(result, isNotNull);
    expect(result.path, filePath);
  }

  void test_getOptionsFile_inRoot_old() {
    String path = convertPath('/some/directory/path');
    String filePath = join(path, AnalysisEngine.ANALYSIS_OPTIONS_FILE);
    newFile(filePath);

    File result = builder.getOptionsFile(path);
    expect(result, isNotNull);
    expect(result.path, filePath);
  }

  _defineMockLintRules() {
    _mockLintRule = new _MockLintRule('mock_lint_rule');
    Registry.ruleRegistry.register(_mockLintRule);
    _mockLintRule2 = new _MockLintRule('mock_lint_rule2');
    Registry.ruleRegistry.register(_mockLintRule2);
    _mockLintRule3 = new _MockLintRule('mock_lint_rule3');
    Registry.ruleRegistry.register(_mockLintRule3);
    _mockPublicMemberApiDocs = new _MockLintRule('public_member_api_docs');
    Registry.ruleRegistry.register(_mockPublicMemberApiDocs);
  }

  void _expectEqualOptions(
      AnalysisOptionsImpl actual, AnalysisOptionsImpl expected) {
    // TODO(brianwilkerson) Consider moving this to AnalysisOptionsImpl.==.
    expect(actual.analyzeFunctionBodiesPredicate,
        same(expected.analyzeFunctionBodiesPredicate));
    expect(actual.dart2jsHint, expected.dart2jsHint);
    expect(actual.enableLazyAssignmentOperators,
        expected.enableLazyAssignmentOperators);
    expect(actual.enableTiming, expected.enableTiming);
    expect(actual.generateImplicitErrors, expected.generateImplicitErrors);
    expect(actual.generateSdkErrors, expected.generateSdkErrors);
    expect(actual.hint, expected.hint);
    expect(actual.lint, expected.lint);
    expect(
      actual.lintRules.map((l) => l.name),
      unorderedEquals(expected.lintRules.map((l) => l.name)),
    );
    expect(actual.preserveComments, expected.preserveComments);
    expect(actual.strongMode, expected.strongMode);
    expect(actual.strongModeHints, expected.strongModeHints);
    expect(actual.implicitCasts, expected.implicitCasts);
    expect(actual.implicitDynamic, expected.implicitDynamic);
    expect(actual.strictInference, expected.strictInference);
    expect(actual.strictRawTypes, expected.strictRawTypes);
    expect(actual.trackCacheDependencies, expected.trackCacheDependencies);
    expect(actual.disableCacheFlushing, expected.disableCacheFlushing);
  }

  Uri _relativeUri(String path, {String from}) {
    var pathContext = resourceProvider.pathContext;
    String relativePath = pathContext.relative(path, from: from);
    return pathContext.toUri(relativePath);
  }
}

@reflectiveTest
class EmbedderYamlLocatorTest extends EmbedderRelatedTest {
  void test_empty() {
    EmbedderYamlLocator locator = new EmbedderYamlLocator({
      'fox': <Folder>[pathTranslator.getResource(emptyPath)]
    });
    expect(locator.embedderYamls, hasLength(0));
  }

  void test_invalid() {
    EmbedderYamlLocator locator = new EmbedderYamlLocator(null);
    locator.addEmbedderYaml(null, r'''{{{,{{}}},}}''');
    expect(locator.embedderYamls, hasLength(0));
  }

  void test_valid() {
    EmbedderYamlLocator locator = new EmbedderYamlLocator({
      'fox': <Folder>[pathTranslator.getResource(foxLib)]
    });
    expect(locator.embedderYamls, hasLength(1));
  }
}

class _MockLintRule implements LintRule {
  final String _name;

  _MockLintRule(this._name);

  @override
  String get name => _name;

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
