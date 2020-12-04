// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/command_line/arguments.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/context/context_root.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/context/source.dart';
import 'package:analyzer/src/dart/error/lint_codes.dart';
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
  DartSdkManager sdkManager;

  /// The content cache used by the tests.
  ContentCache contentCache;

  /// The options passed to the context builder.
  ContextBuilderOptions builderOptions = ContextBuilderOptions();

  /// The context builder to be used in the test.
  ContextBuilder builder;

  /// The path to the default SDK, or `null` if the test has not explicitly
  /// invoked [createDefaultSdk].
  String defaultSdkPath;

  _MockLintRule _mockLintRule;
  _MockLintRule _mockLintRule2;
  _MockLintRule _mockLintRule3;
  _MockLintRule _mockPublicMemberApiDocs;

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

  void test_cmdline_lint_defined() {
    _defineMockLintRules();
    ArgParser argParser = ArgParser();
    defineAnalysisArguments(argParser);
    ArgResults argResults = argParser.parse(['--$lintsFlag']);
    var builder = ContextBuilder(resourceProvider, sdkManager, contentCache,
        options: createContextBuilderOptions(resourceProvider, argResults));

    AnalysisOptionsImpl expected = AnalysisOptionsImpl();
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
    ArgParser argParser = ArgParser();
    defineAnalysisArguments(argParser);
    ArgResults argResults = argParser.parse(['--no-$lintsFlag']);
    var builder = ContextBuilder(resourceProvider, sdkManager, contentCache,
        options: createContextBuilderOptions(resourceProvider, argResults));

    AnalysisOptionsImpl expected = AnalysisOptionsImpl();
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
    ArgParser argParser = ArgParser();
    defineAnalysisArguments(argParser);
    ArgResults argResults = argParser.parse([]);
    var builder = ContextBuilder(resourceProvider, sdkManager, contentCache,
        options: createContextBuilderOptions(resourceProvider, argResults));

    AnalysisOptionsImpl expected = AnalysisOptionsImpl();
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
    ArgParser argParser = ArgParser();
    defineAnalysisArguments(argParser);
    ArgResults argResults = argParser.parse([]);
    var builder = ContextBuilder(resourceProvider, sdkManager, contentCache,
        options: createContextBuilderOptions(resourceProvider, argResults));

    AnalysisOptionsImpl expected = AnalysisOptionsImpl();
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

  void test_createDefaultOptions_default() {
    // Invert a subset of the options to ensure that the default options are
    // being returned.
    AnalysisOptionsImpl defaultOptions = AnalysisOptionsImpl();
    defaultOptions.implicitCasts = !defaultOptions.implicitCasts;
    builderOptions.defaultOptions = defaultOptions;
    AnalysisOptions options = builder.createDefaultOptions();
    _expectEqualOptions(options, defaultOptions);
  }

  void test_createDefaultOptions_noDefault() {
    AnalysisOptions options = builder.createDefaultOptions();
    _expectEqualOptions(options, AnalysisOptionsImpl());
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
    Packages packages = builder.createPackageMap(projectPath);
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

    Packages packages = builder.createPackageMap(projectPath);
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

    Packages packages = builder.createPackageMap(projectPath);
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
    Packages packages = builder.createPackageMap(rootPath);
    expect(packages.packages, isEmpty);
  }

  void test_createPackageMap_rootDoesNotExist() {
    String rootPath = convertPath('/root');
    Packages packages = builder.createPackageMap(rootPath);
    expect(packages.packages, isEmpty);
  }

  void test_createSourceFactory_bazelWorkspace_fileProvider() {
    String projectPath = convertPath('/workspace/my/module');
    newFile('/workspace/WORKSPACE');
    newFolder('/workspace/bazel-bin');
    newFolder('/workspace/bazel-genfiles');
    newFolder(projectPath);

    SourceFactoryImpl factory = builder.createSourceFactory(projectPath);
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

    SourceFactoryImpl factory = builder.createSourceFactory(projectPath);
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

    SourceFactory factory = builder.createSourceFactory(projectPath);

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
    createDefaultSdk();
    String projectPath = join(rootPath, 'project');
    String packageFilePath = join(projectPath, '.packages');
    String packageA = join(rootPath, 'pkgs', 'a');
    String packageB = join(rootPath, 'pkgs', 'b');
    newFile(packageFilePath, content: '''
a:${resourceProvider.pathContext.toUri(packageA)}
b:${resourceProvider.pathContext.toUri(packageB)}
''');

    SourceFactory factory = builder.createSourceFactory(projectPath);

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
    newFile('/workspace/pubspec.yaml', content: 'name: project');
    Workspace workspace = ContextBuilder.createWorkspace(resourceProvider,
        convertPath('/workspace/project/lib/lib.dart'), builder);
    expect(workspace, TypeMatcher<PackageBuildWorkspace>());
  }

  void test_createWorkspace_hasPackagesFile_hasPubspec() {
    newFile('/workspace/.packages');
    newFile('/workspace/pubspec.yaml', content: 'name: project');
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
    newFile('/workspace/pubspec.yaml', content: 'name: project');
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
    newFile('/workspace/pubspec.yaml', content: 'name: project');
    Workspace workspace = ContextBuilder.createWorkspace(resourceProvider,
        convertPath('/workspace/project/lib/lib.dart'), builder);
    expect(workspace, TypeMatcher<PubWorkspace>());
  }

  void test_createWorkspace_noPackagesFile_noMarkerFiles() {
    Workspace workspace = ContextBuilder.createWorkspace(resourceProvider,
        convertPath('/workspace/project/lib/lib.dart'), builder);
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
    Source htmlSource = sdk.mapDartUri('dart:html');
    expect(htmlSource.fullName,
        convertPath('/sdk/lib/html/dart2js/html_dart2js.dart'));
    expect(htmlSource.exists(), isTrue);
  }

  void test_getAnalysisOptions_default_bazel() {
    _defineMockLintRules();
    AnalysisOptionsImpl defaultOptions = AnalysisOptionsImpl();
    builderOptions.defaultOptions = defaultOptions;
    AnalysisOptionsImpl expected = AnalysisOptionsImpl();
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
    AnalysisOptionsImpl defaultOptions = AnalysisOptionsImpl();
    builderOptions.defaultOptions = defaultOptions;
    AnalysisOptionsImpl expected = AnalysisOptionsImpl();
    expected.lint = true;
    expected.lintRules = <Linter>[_mockLintRule];
    String packagesFilePath = convertPath('/some/directory/path/.packages');
    newFile(packagesFilePath, content: '''
flutter:${toUriStr('/pkg/flutter/lib/')}
''');
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
    AnalysisOptionsImpl defaultOptions = AnalysisOptionsImpl();
    builderOptions.defaultOptions = defaultOptions;
    AnalysisOptionsImpl expected = AnalysisOptionsImpl();
    String path = convertPath('/some/directory/path');
    String filePath = join(path, AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE);
    newFile(filePath, content: '''
linter:
  rules:
    - non_existent_lint_rule
''');

    AnalysisOptions options = builder.getAnalysisOptions(path);
    _expectEqualOptions(options, expected);
  }

  void test_getAnalysisOptions_default_overrides() {
    AnalysisOptionsImpl defaultOptions = AnalysisOptionsImpl();
    defaultOptions.implicitDynamic = true;
    builderOptions.defaultOptions = defaultOptions;
    AnalysisOptionsImpl expected = AnalysisOptionsImpl();
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
    ArgParser argParser = ArgParser();
    defineAnalysisArguments(argParser);
    ArgResults argResults = argParser.parse([]);
    builderOptions = createContextBuilderOptions(resourceProvider, argResults);
    builder = ContextBuilder(resourceProvider, sdkManager, contentCache,
        options: builderOptions);
    AnalysisOptionsImpl expected = AnalysisOptionsImpl();
    AnalysisOptions options = builder.getAnalysisOptions(projectPath);
    _expectEqualOptions(options, expected);
  }

  void test_getAnalysisOptions_includes() {
    _defineMockLintRules();
    AnalysisOptionsImpl defaultOptions = AnalysisOptionsImpl();
    builderOptions.defaultOptions = defaultOptions;
    AnalysisOptionsImpl expected = AnalysisOptionsImpl();
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
    - non_existent_lint_rule
''');

    AnalysisOptions options = builder.getAnalysisOptions(path);
    _expectEqualOptions(options, AnalysisOptionsImpl());
  }

  void test_getAnalysisOptions_noDefault_overrides() {
    AnalysisOptionsImpl expected = AnalysisOptionsImpl();
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
        ContextRoot(path, [], pathContext: resourceProvider.pathContext);
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

  void test_getOptionsFile_inRoot_new() {
    String path = convertPath('/some/directory/path');
    String filePath = join(path, AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE);
    newFile(filePath);

    File result = builder.getOptionsFile(path);
    expect(result, isNotNull);
    expect(result.path, filePath);
  }

  void _assertPackages(Packages packages, Map<String, String> nameToPath) {
    expect(packages, isNotNull);
    expect(packages.packages, hasLength(nameToPath.length));
    for (var name in nameToPath.keys) {
      var expectedPath = nameToPath[name];
      var path = packages[name].libFolder.path;
      expect(path, expectedPath, reason: 'package $name');
    }
  }

  _defineMockLintRules() {
    _mockLintRule = _MockLintRule('mock_lint_rule');
    Registry.ruleRegistry.register(_mockLintRule);
    _mockLintRule2 = _MockLintRule('mock_lint_rule2');
    Registry.ruleRegistry.register(_mockLintRule2);
    _mockLintRule3 = _MockLintRule('mock_lint_rule3');
    Registry.ruleRegistry.register(_mockLintRule3);
    _mockPublicMemberApiDocs = _MockLintRule('public_member_api_docs');
    Registry.ruleRegistry.register(_mockPublicMemberApiDocs);
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

  Uri _relativeUri(String path, {String from}) {
    var pathContext = resourceProvider.pathContext;
    String relativePath = pathContext.relative(path, from: from);
    return pathContext.toUri(relativePath);
  }
}

@reflectiveTest
class EmbedderYamlLocatorTest extends EmbedderRelatedTest {
  void test_empty() {
    EmbedderYamlLocator locator = EmbedderYamlLocator({
      'fox': <Folder>[pathTranslator.getResource(emptyPath)]
    });
    expect(locator.embedderYamls, hasLength(0));
  }

  void test_invalid() {
    EmbedderYamlLocator locator = EmbedderYamlLocator(null);
    locator.addEmbedderYaml(null, r'''{{{,{{}}},}}''');
    expect(locator.embedderYamls, hasLength(0));
  }

  void test_valid() {
    EmbedderYamlLocator locator = EmbedderYamlLocator({
      'fox': <Folder>[pathTranslator.getResource(foxLib)]
    });
    expect(locator.embedderYamls, hasLength(1));
  }
}

class _MockLintRule implements LintRule {
  final String _name;

  _MockLintRule(this._name);

  @override
  List<LintCode> get lintCodes => [LintCode(_name, '')];

  @override
  String get name => _name;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
