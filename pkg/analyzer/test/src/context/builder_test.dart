// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.src.context.context_builder_test;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/plugin/options.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/src/context/builder.dart';
import 'package:analyzer/src/context/source.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/plugin/options_plugin.dart';
import 'package:package_config/packages.dart';
import 'package:package_config/src/packages_impl.dart';
import 'package:path/path.dart' as path;
import 'package:plugin/src/plugin_impl.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../embedder_tests.dart';
import '../../generated/test_support.dart';
import 'mock_sdk.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ContextBuilderTest);
    defineReflectiveTests(EmbedderYamlLocatorTest);
  });
}

@reflectiveTest
class ContextBuilderTest extends EngineTestCase {
  /**
   * The resource provider to be used by tests.
   */
  MemoryResourceProvider resourceProvider;

  /**
   * The path context used to manipulate file paths.
   */
  path.Context pathContext;

  /**
   * The SDK manager used by the tests;
   */
  DartSdkManager sdkManager;

  /**
   * The content cache used by the tests.
   */
  ContentCache contentCache;

  /**
   * The context builder to be used in the test.
   */
  ContextBuilder builder;

  /**
   * The path to the default SDK, or `null` if the test has not explicitly
   * invoked [createDefaultSdk].
   */
  String defaultSdkPath = null;

  Uri convertedDirectoryUri(String directoryPath) {
    return new Uri.directory(resourceProvider.convertPath(directoryPath),
        windows: pathContext.style == path.windows.style);
  }

  void createDefaultSdk(Folder sdkDir) {
    defaultSdkPath = pathContext.join(sdkDir.path, 'default', 'sdk');
    String librariesFilePath = pathContext.join(defaultSdkPath, 'lib',
        '_internal', 'sdk_library_metadata', 'lib', 'libraries.dart');
    resourceProvider.newFile(
        librariesFilePath,
        r'''
const Map<String, LibraryInfo> libraries = const {
  "async": const LibraryInfo("async/async.dart"),
  "core": const LibraryInfo("core/core.dart"),
};
''');
    sdkManager =
        new DartSdkManager(defaultSdkPath, false, (_) => new MockSdk());
    builder = new ContextBuilder(resourceProvider, sdkManager, contentCache);
  }

  void createFile(String path, String content) {
    resourceProvider.newFile(path, content);
  }

  @override
  void setUp() {
    resourceProvider = new MemoryResourceProvider();
    pathContext = resourceProvider.pathContext;
    new MockSdk(resourceProvider: resourceProvider);
    sdkManager = new DartSdkManager('/', false, (_) {
      fail('Should not be used to create an SDK');
    });
    contentCache = new ContentCache();
    builder = new ContextBuilder(resourceProvider, sdkManager, contentCache);
  }

  @failingTest
  void test_buildContext() {
    fail('Incomplete test');
  }

  void test_convertPackagesToMap_noPackages() {
    expect(builder.convertPackagesToMap(Packages.noPackages), isEmpty);
  }

  void test_convertPackagesToMap_null() {
    expect(builder.convertPackagesToMap(null), isEmpty);
  }

  void test_convertPackagesToMap_packages() {
    String fooName = 'foo';
    String fooPath = resourceProvider.convertPath('/pkg/foo');
    Uri fooUri = pathContext.toUri(fooPath);
    String barName = 'bar';
    String barPath = resourceProvider.convertPath('/pkg/bar');
    Uri barUri = pathContext.toUri(barPath);

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
    defaultOptions.enableAssertMessage = !defaultOptions.enableAssertMessage;
    defaultOptions.enableGenericMethods = !defaultOptions.enableGenericMethods;
    defaultOptions.enableStrictCallChecks =
        !defaultOptions.enableStrictCallChecks;
    defaultOptions.enableSuperMixins = !defaultOptions.enableSuperMixins;
    builder.defaultOptions = defaultOptions;
    AnalysisOptions options = builder.createDefaultOptions();
    _expectEqualOptions(options, defaultOptions);
  }

  void test_createDefaultOptions_noDefault() {
    AnalysisOptions options = builder.createDefaultOptions();
    _expectEqualOptions(options, new AnalysisOptionsImpl());
  }

  void test_createPackageMap_fromPackageDirectory_explicit() {
    // Use a package directory that is outside the project directory.
    String rootPath = resourceProvider.convertPath('/root');
    String projectPath = pathContext.join(rootPath, 'project');
    String packageDirPath = pathContext.join(rootPath, 'packages');
    String fooName = 'foo';
    String fooPath = pathContext.join(packageDirPath, fooName);
    String barName = 'bar';
    String barPath = pathContext.join(packageDirPath, barName);
    resourceProvider.newFolder(projectPath);
    resourceProvider.newFolder(fooPath);
    resourceProvider.newFolder(barPath);

    builder.defaultPackagesDirectoryPath = packageDirPath;

    Packages packages = builder.createPackageMap(projectPath);
    expect(packages, isNotNull);
    Map<String, Uri> map = packages.asMap();
    expect(map, hasLength(2));
    expect(map[fooName], convertedDirectoryUri(fooPath));
    expect(map[barName], convertedDirectoryUri(barPath));
  }

  void test_createPackageMap_fromPackageDirectory_inRoot() {
    // Use a package directory that is inside the project directory.
    String projectPath = resourceProvider.convertPath('/root/project');
    String packageDirPath = pathContext.join(projectPath, 'packages');
    String fooName = 'foo';
    String fooPath = pathContext.join(packageDirPath, fooName);
    String barName = 'bar';
    String barPath = pathContext.join(packageDirPath, barName);
    resourceProvider.newFolder(fooPath);
    resourceProvider.newFolder(barPath);

    Packages packages = builder.createPackageMap(projectPath);
    expect(packages, isNotNull);
    Map<String, Uri> map = packages.asMap();
    expect(map, hasLength(2));
    expect(map[fooName], convertedDirectoryUri(fooPath));
    expect(map[barName], convertedDirectoryUri(barPath));
  }

  void test_createPackageMap_fromPackageFile_explicit() {
    // Use a package file that is outside the project directory's hierarchy.
    String rootPath = resourceProvider.convertPath('/root');
    String projectPath = pathContext.join(rootPath, 'project');
    String packageFilePath = pathContext.join(rootPath, 'child', '.packages');
    resourceProvider.newFolder(projectPath);
    Uri fooUri = convertedDirectoryUri('/pkg/foo');
    Uri barUri = convertedDirectoryUri('/pkg/bar');
    createFile(
        packageFilePath,
        '''
foo:$fooUri
bar:$barUri
''');

    builder.defaultPackageFilePath = packageFilePath;
    Packages packages = builder.createPackageMap(projectPath);
    expect(packages, isNotNull);
    Map<String, Uri> map = packages.asMap();
    expect(map, hasLength(2));
    expect(map['foo'], fooUri);
    expect(map['bar'], barUri);
  }

  void test_createPackageMap_fromPackageFile_inParentOfRoot() {
    // Use a package file that is inside the parent of the project directory.
    String rootPath = resourceProvider.convertPath('/root');
    String projectPath = pathContext.join(rootPath, 'project');
    String packageFilePath = pathContext.join(rootPath, '.packages');
    resourceProvider.newFolder(projectPath);
    Uri fooUri = convertedDirectoryUri('/pkg/foo');
    Uri barUri = convertedDirectoryUri('/pkg/bar');
    createFile(
        packageFilePath,
        '''
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
    String rootPath = resourceProvider.convertPath('/root');
    String projectPath = pathContext.join(rootPath, 'project');
    String packageFilePath = pathContext.join(projectPath, '.packages');
    resourceProvider.newFolder(projectPath);
    Uri fooUri = convertedDirectoryUri('/pkg/foo');
    Uri barUri = convertedDirectoryUri('/pkg/bar');
    createFile(
        packageFilePath,
        '''
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
    String rootPath = resourceProvider.convertPath('/root');
    resourceProvider.newFolder(rootPath);
    Packages packages = builder.createPackageMap(rootPath);
    expect(packages, same(Packages.noPackages));
  }

  void test_createSourceFactory_fileProvider() {
    String rootPath = resourceProvider.convertPath('/root');
    Folder rootFolder = resourceProvider.getFolder(rootPath);
    createDefaultSdk(rootFolder);
    String projectPath = pathContext.join(rootPath, 'project');
    String packageFilePath = pathContext.join(projectPath, '.packages');
    String packageA = pathContext.join(rootPath, 'pkgs', 'a');
    String packageB = pathContext.join(rootPath, 'pkgs', 'b');
    createFile(
        packageFilePath,
        '''
a:${pathContext.toUri(packageA)}
b:${pathContext.toUri(packageB)}
''');
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    UriResolver resolver = new ResourceUriResolver(resourceProvider);
    builder.fileResolverProvider = (folder) => resolver;
    SourceFactoryImpl factory =
        builder.createSourceFactory(projectPath, options);
    expect(factory.resolvers, contains(same(resolver)));
  }

  void test_createSourceFactory_noProvider_packages_embedder_extensions() {
    String rootPath = resourceProvider.convertPath('/root');
    Folder rootFolder = resourceProvider.getFolder(rootPath);
    createDefaultSdk(rootFolder);
    String projectPath = pathContext.join(rootPath, 'project');
    String packageFilePath = pathContext.join(projectPath, '.packages');
    String packageA = pathContext.join(rootPath, 'pkgs', 'a');
    String embedderPath = pathContext.join(packageA, '_embedder.yaml');
    String packageB = pathContext.join(rootPath, 'pkgs', 'b');
    String extensionPath = pathContext.join(packageB, '_sdkext');
    createFile(
        packageFilePath,
        '''
a:${pathContext.toUri(packageA)}
b:${pathContext.toUri(packageB)}
''');
    String asyncPath = pathContext.join(packageA, 'sdk', 'async.dart');
    String corePath = pathContext.join(packageA, 'sdk', 'core.dart');
    createFile(
        embedderPath,
        '''
embedded_libs:
  "dart:async": ${_relativeUri(asyncPath, from: packageA)}
  "dart:core": ${_relativeUri(corePath, from: packageA)}
''');
    String fooPath = pathContext.join(packageB, 'ext', 'foo.dart');
    createFile(
        extensionPath,
        '''{
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
    expect(packageSource.fullName, pathContext.join(packageB, 'b.dart'));
  }

  void test_createSourceFactory_noProvider_packages_embedder_noExtensions() {
    String rootPath = resourceProvider.convertPath('/root');
    Folder rootFolder = resourceProvider.getFolder(rootPath);
    createDefaultSdk(rootFolder);
    String projectPath = pathContext.join(rootPath, 'project');
    String packageFilePath = pathContext.join(projectPath, '.packages');
    String packageA = pathContext.join(rootPath, 'pkgs', 'a');
    String embedderPath = pathContext.join(packageA, '_embedder.yaml');
    String packageB = pathContext.join(rootPath, 'pkgs', 'b');
    createFile(
        packageFilePath,
        '''
a:${pathContext.toUri(packageA)}
b:${pathContext.toUri(packageB)}
''');
    String asyncPath = pathContext.join(packageA, 'sdk', 'async.dart');
    String corePath = pathContext.join(packageA, 'sdk', 'core.dart');
    createFile(
        embedderPath,
        '''
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
    expect(packageSource.fullName, pathContext.join(packageB, 'b.dart'));
  }

  @failingTest
  void test_createSourceFactory_noProvider_packages_noEmbedder_extensions() {
    fail('Incomplete test');
  }

  void test_createSourceFactory_noProvider_packages_noEmbedder_noExtensions() {
    String rootPath = resourceProvider.convertPath('/root');
    Folder rootFolder = resourceProvider.getFolder(rootPath);
    createDefaultSdk(rootFolder);
    String projectPath = pathContext.join(rootPath, 'project');
    String packageFilePath = pathContext.join(projectPath, '.packages');
    String packageA = pathContext.join(rootPath, 'pkgs', 'a');
    String packageB = pathContext.join(rootPath, 'pkgs', 'b');
    createFile(
        packageFilePath,
        '''
a:${pathContext.toUri(packageA)}
b:${pathContext.toUri(packageB)}
''');
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();

    SourceFactory factory = builder.createSourceFactory(projectPath, options);

    Source dartSource = factory.forUri('dart:core');
    expect(dartSource, isNotNull);
    expect(dartSource.fullName,
        pathContext.join(defaultSdkPath, 'lib', 'core', 'core.dart'));

    Source packageSource = factory.forUri('package:a/a.dart');
    expect(packageSource, isNotNull);
    expect(packageSource.fullName, pathContext.join(packageA, 'a.dart'));
  }

  void test_createSourceFactory_packageProvider() {
    String rootPath = resourceProvider.convertPath('/root');
    Folder rootFolder = resourceProvider.getFolder(rootPath);
    createDefaultSdk(rootFolder);
    String projectPath = pathContext.join(rootPath, 'project');
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    UriResolver resolver = new PackageMapUriResolver(resourceProvider, {});
    builder.packageResolverProvider = (folder) => resolver;
    SourceFactoryImpl factory =
        builder.createSourceFactory(projectPath, options);
    expect(factory.resolvers, contains(same(resolver)));
  }

  void test_declareVariables_emptyMap() {
    AnalysisContext context = AnalysisEngine.instance.createAnalysisContext();
    Iterable<String> expected = context.declaredVariables.variableNames;
    builder.declaredVariables = <String, String>{};

    builder.declareVariables(context);
    expect(context.declaredVariables.variableNames, unorderedEquals(expected));
  }

  void test_declareVariables_nonEmptyMap() {
    AnalysisContext context = AnalysisEngine.instance.createAnalysisContext();
    List<String> expected = context.declaredVariables.variableNames.toList();
    expect(expected, isNot(contains('a')));
    expect(expected, isNot(contains('b')));
    expected.addAll(['a', 'b']);
    builder.declaredVariables = <String, String>{'a': 'a', 'b': 'b'};

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

  void test_getAnalysisOptions_default_noOverrides() {
    AnalysisOptionsImpl defaultOptions = new AnalysisOptionsImpl();
    defaultOptions.enableGenericMethods = true;
    builder.defaultOptions = defaultOptions;
    AnalysisOptionsImpl expected = new AnalysisOptionsImpl();
    expected.enableGenericMethods = true;
    String path = resourceProvider.convertPath('/some/directory/path');
    String filePath =
        pathContext.join(path, AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE);
    resourceProvider.newFile(
        filePath,
        '''
linter:
  rules:
    - empty_constructor_bodies
''');

    AnalysisContext context = AnalysisEngine.instance.createAnalysisContext();
    AnalysisOptions options = builder.getAnalysisOptions(context, path);
    _expectEqualOptions(options, expected);
  }

  void test_getAnalysisOptions_default_overrides() {
    AnalysisOptionsImpl defaultOptions = new AnalysisOptionsImpl();
    defaultOptions.enableGenericMethods = true;
    builder.defaultOptions = defaultOptions;
    AnalysisOptionsImpl expected = new AnalysisOptionsImpl();
    expected.enableSuperMixins = true;
    expected.enableGenericMethods = true;
    String path = resourceProvider.convertPath('/some/directory/path');
    String filePath =
        pathContext.join(path, AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE);
    resourceProvider.newFile(
        filePath,
        '''
analyzer:
  language:
    enableSuperMixins : true
''');

    AnalysisEngine engine = AnalysisEngine.instance;
    OptionsPlugin plugin = engine.optionsPlugin;
    plugin.registerExtensionPoints((_) {});
    try {
      _TestOptionsProcessor processor = new _TestOptionsProcessor();
      processor.expectedOptions = <String, Object>{
        'analyzer': {
          'language': {'enableSuperMixins': true}
        }
      };
      (plugin.optionsProcessorExtensionPoint as ExtensionPointImpl)
          .add(processor);
      AnalysisContext context = engine.createAnalysisContext();
      AnalysisOptions options = builder.getAnalysisOptions(context, path);
      _expectEqualOptions(options, expected);
    } finally {
      plugin.registerExtensionPoints((_) {});
    }
  }

  void test_getAnalysisOptions_invalid() {
    String path = resourceProvider.convertPath('/some/directory/path');
    String filePath =
        pathContext.join(path, AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE);
    resourceProvider.newFile(filePath, ';');

    AnalysisEngine engine = AnalysisEngine.instance;
    OptionsPlugin plugin = engine.optionsPlugin;
    plugin.registerExtensionPoints((_) {});
    try {
      _TestOptionsProcessor processor = new _TestOptionsProcessor();
      (plugin.optionsProcessorExtensionPoint as ExtensionPointImpl)
          .add(processor);
      AnalysisContext context = engine.createAnalysisContext();
      AnalysisOptions options = builder.getAnalysisOptions(context, path);
      expect(options, isNotNull);
      expect(processor.errorCount, 1);
    } finally {
      plugin.registerExtensionPoints((_) {});
    }
  }

  void test_getAnalysisOptions_noDefault_noOverrides() {
    String path = resourceProvider.convertPath('/some/directory/path');
    String filePath =
        pathContext.join(path, AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE);
    resourceProvider.newFile(
        filePath,
        '''
linter:
  rules:
    - empty_constructor_bodies
''');

    AnalysisContext context = AnalysisEngine.instance.createAnalysisContext();
    AnalysisOptions options = builder.getAnalysisOptions(context, path);
    _expectEqualOptions(options, new AnalysisOptionsImpl());
  }

  void test_getAnalysisOptions_noDefault_overrides() {
    AnalysisOptionsImpl expected = new AnalysisOptionsImpl();
    expected.enableSuperMixins = true;
    String path = resourceProvider.convertPath('/some/directory/path');
    String filePath =
        pathContext.join(path, AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE);
    resourceProvider.newFile(
        filePath,
        '''
analyzer:
  language:
    enableSuperMixins : true
''');

    AnalysisContext context = AnalysisEngine.instance.createAnalysisContext();
    AnalysisOptions options = builder.getAnalysisOptions(context, path);
    _expectEqualOptions(options, expected);
  }

  void test_getOptionsFile_explicit() {
    String path = resourceProvider.convertPath('/some/directory/path');
    String filePath = resourceProvider.convertPath('/options/analysis.yaml');
    resourceProvider.newFile(filePath, '');

    builder.defaultAnalysisOptionsFilePath = filePath;
    File result = builder.getOptionsFile(path);
    expect(result, isNotNull);
    expect(result.path, filePath);
  }

  void test_getOptionsFile_inParentOfRoot_new() {
    String parentPath = resourceProvider.convertPath('/some/directory');
    String path = pathContext.join(parentPath, 'path');
    String filePath =
        pathContext.join(parentPath, AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE);
    resourceProvider.newFile(filePath, '');

    File result = builder.getOptionsFile(path);
    expect(result, isNotNull);
    expect(result.path, filePath);
  }

  void test_getOptionsFile_inParentOfRoot_old() {
    String parentPath = resourceProvider.convertPath('/some/directory');
    String path = pathContext.join(parentPath, 'path');
    String filePath =
        pathContext.join(parentPath, AnalysisEngine.ANALYSIS_OPTIONS_FILE);
    resourceProvider.newFile(filePath, '');

    File result = builder.getOptionsFile(path);
    expect(result, isNotNull);
    expect(result.path, filePath);
  }

  void test_getOptionsFile_inRoot_new() {
    String path = resourceProvider.convertPath('/some/directory/path');
    String filePath =
        pathContext.join(path, AnalysisEngine.ANALYSIS_OPTIONS_YAML_FILE);
    resourceProvider.newFile(filePath, '');

    File result = builder.getOptionsFile(path);
    expect(result, isNotNull);
    expect(result.path, filePath);
  }

  void test_getOptionsFile_inRoot_old() {
    String path = resourceProvider.convertPath('/some/directory/path');
    String filePath =
        pathContext.join(path, AnalysisEngine.ANALYSIS_OPTIONS_FILE);
    resourceProvider.newFile(filePath, '');

    File result = builder.getOptionsFile(path);
    expect(result, isNotNull);
    expect(result.path, filePath);
  }

  void _expectEqualOptions(
      AnalysisOptionsImpl actual, AnalysisOptionsImpl expected) {
    // TODO(brianwilkerson) Consider moving this to AnalysisOptionsImpl.==.
    expect(actual.analyzeFunctionBodiesPredicate,
        same(expected.analyzeFunctionBodiesPredicate));
    expect(actual.dart2jsHint, expected.dart2jsHint);
    expect(actual.enableAssertMessage, expected.enableAssertMessage);
    expect(actual.enableStrictCallChecks, expected.enableStrictCallChecks);
    expect(actual.enableGenericMethods, expected.enableGenericMethods);
    expect(actual.enableSuperMixins, expected.enableSuperMixins);
    expect(actual.enableTiming, expected.enableTiming);
    expect(actual.generateImplicitErrors, expected.generateImplicitErrors);
    expect(actual.generateSdkErrors, expected.generateSdkErrors);
    expect(actual.hint, expected.hint);
    expect(actual.incremental, expected.incremental);
    expect(actual.incrementalApi, expected.incrementalApi);
    expect(actual.incrementalValidation, expected.incrementalValidation);
    expect(actual.lint, expected.lint);
    expect(actual.preserveComments, expected.preserveComments);
    expect(actual.strongMode, expected.strongMode);
    expect(actual.strongModeHints, expected.strongModeHints);
    expect(actual.implicitCasts, expected.implicitCasts);
    expect(actual.implicitDynamic, expected.implicitDynamic);
    expect(actual.trackCacheDependencies, expected.trackCacheDependencies);
    expect(actual.disableCacheFlushing, expected.disableCacheFlushing);
    expect(actual.finerGrainedInvalidation, expected.finerGrainedInvalidation);
  }

  Uri _relativeUri(String path, {String from}) {
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

class _TestOptionsProcessor implements OptionsProcessor {
  Map<String, Object> expectedOptions = null;

  int errorCount = 0;

  @override
  void onError(Exception exception) {
    errorCount++;
  }

  @override
  void optionsProcessed(AnalysisContext context, Map<String, Object> options) {
    if (expectedOptions == null) {
      fail('Unexpected invocation of optionsProcessed');
    }
    expect(options, hasLength(expectedOptions.length));
    for (String key in expectedOptions.keys) {
      expect(options.containsKey(key), isTrue, reason: 'missing key $key');
      expect(options[key], expectedOptions[key],
          reason: 'values for key $key do not match');
    }
  }
}
