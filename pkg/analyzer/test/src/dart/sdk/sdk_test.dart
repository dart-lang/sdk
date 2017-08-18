// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.generated.sdk_test;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/context/builder.dart' show EmbedderYamlLocator;
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_engine_io.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/summary/summarize_elements.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../embedder_tests.dart';
import '../../../generated/test_support.dart';
import '../../../resource_utils.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EmbedderSdkTest);
    defineReflectiveTests(FolderBasedDartSdkTest);
    defineReflectiveTests(SdkExtensionFinderTest);
    defineReflectiveTests(SdkLibrariesReaderTest);
  });
}

@reflectiveTest
class EmbedderSdkTest extends EmbedderRelatedTest {
  void test_creation() {
    EmbedderYamlLocator locator = new EmbedderYamlLocator({
      'fox': <Folder>[pathTranslator.getResource(foxLib)]
    });
    EmbedderSdk sdk = new EmbedderSdk(resourceProvider, locator.embedderYamls);

    expect(sdk.urlMappings, hasLength(5));
  }

  void test_fromFileUri() {
    EmbedderYamlLocator locator = new EmbedderYamlLocator({
      'fox': <Folder>[pathTranslator.getResource(foxLib)]
    });
    EmbedderSdk sdk = new EmbedderSdk(resourceProvider, locator.embedderYamls);

    expectSource(String posixPath, String dartUri) {
      Uri uri = Uri.parse(posixToOSFileUri(posixPath));
      Source source = sdk.fromFileUri(uri);
      expect(source, isNotNull, reason: posixPath);
      expect(source.uri.toString(), dartUri);
      expect(source.fullName, posixToOSPath(posixPath));
    }

    expectSource('$foxLib/slippy.dart', 'dart:fox');
    expectSource('$foxLib/deep/directory/file.dart', 'dart:deep');
    expectSource('$foxLib/deep/directory/part.dart', 'dart:deep/part.dart');
  }

  void test_getLinkedBundle_noBundle() {
    EmbedderYamlLocator locator = new EmbedderYamlLocator({
      'fox': <Folder>[pathTranslator.getResource(foxLib)]
    });
    EmbedderSdk sdk = new EmbedderSdk(resourceProvider, locator.embedderYamls);
    expect(sdk.getLinkedBundle(), isNull);
  }

  void test_getLinkedBundle_spec() {
    pathTranslator.newFileWithBytes('$foxPath/spec.sum',
        new PackageBundleAssembler().assemble().toBuffer());
    EmbedderYamlLocator locator = new EmbedderYamlLocator({
      'fox': <Folder>[pathTranslator.getResource(foxLib)]
    });
    EmbedderSdk sdk = new EmbedderSdk(resourceProvider, locator.embedderYamls);
    sdk.analysisOptions = new AnalysisOptionsImpl()..strongMode = false;
    sdk.useSummary = true;
    expect(sdk.getLinkedBundle(), isNotNull);
  }

  void test_getLinkedBundle_strong() {
    pathTranslator.newFileWithBytes('$foxPath/strong.sum',
        new PackageBundleAssembler().assemble().toBuffer());
    EmbedderYamlLocator locator = new EmbedderYamlLocator({
      'fox': <Folder>[pathTranslator.getResource(foxLib)]
    });
    EmbedderSdk sdk = new EmbedderSdk(resourceProvider, locator.embedderYamls);
    sdk.analysisOptions = new AnalysisOptionsImpl()..strongMode = true;
    sdk.useSummary = true;
    expect(sdk.getLinkedBundle(), isNotNull);
  }

  void test_getSdkLibrary() {
    EmbedderYamlLocator locator = new EmbedderYamlLocator({
      'fox': <Folder>[pathTranslator.getResource(foxLib)]
    });
    EmbedderSdk sdk = new EmbedderSdk(resourceProvider, locator.embedderYamls);

    SdkLibrary lib = sdk.getSdkLibrary('dart:fox');
    expect(lib, isNotNull);
    expect(lib.path, posixToOSPath('$foxLib/slippy.dart'));
    expect(lib.shortName, 'dart:fox');
  }

  void test_mapDartUri() {
    EmbedderYamlLocator locator = new EmbedderYamlLocator({
      'fox': <Folder>[pathTranslator.getResource(foxLib)]
    });
    EmbedderSdk sdk = new EmbedderSdk(resourceProvider, locator.embedderYamls);

    void expectSource(String dartUri, String posixPath) {
      Source source = sdk.mapDartUri(dartUri);
      expect(source, isNotNull, reason: posixPath);
      expect(source.uri.toString(), dartUri);
      expect(source.fullName, posixToOSPath(posixPath));
    }

    expectSource('dart:core', '$foxLib/core.dart');
    expectSource('dart:fox', '$foxLib/slippy.dart');
    expectSource('dart:deep', '$foxLib/deep/directory/file.dart');
    expectSource('dart:deep/part.dart', '$foxLib/deep/directory/part.dart');
  }
}

@reflectiveTest
class FolderBasedDartSdkTest {
  /**
   * The resource provider used by these tests.
   */
  MemoryResourceProvider resourceProvider;

  void test_addExtensions() {
    FolderBasedDartSdk sdk = _createDartSdk();
    String uri = 'dart:my.internal';
    sdk.addExtensions({uri: '/Users/user/dart/my.dart'});
    expect(sdk.mapDartUri(uri), isNotNull);
    // The `shortName` property must include the `dart:` prefix.
    expect(sdk.sdkLibraries, contains(predicate((SdkLibrary library) {
      return library.shortName == uri;
    })));
  }

  void test_analysisOptions_afterContextCreation() {
    FolderBasedDartSdk sdk = _createDartSdk();
    sdk.context;
    expect(() {
      sdk.analysisOptions = new AnalysisOptionsImpl();
    }, throwsStateError);
  }

  void test_analysisOptions_beforeContextCreation() {
    FolderBasedDartSdk sdk = _createDartSdk();
    sdk.analysisOptions = new AnalysisOptionsImpl();
    sdk.context;
    // cannot change "analysisOptions" in the context
    expect(() {
      sdk.context.analysisOptions = new AnalysisOptionsImpl();
    }, throwsStateError);
  }

  void test_creation() {
    FolderBasedDartSdk sdk = _createDartSdk();
    expect(sdk, isNotNull);
  }

  void test_fromFile_invalid() {
    FolderBasedDartSdk sdk = _createDartSdk();
    expect(
        sdk.fromFileUri(
            resourceProvider.getFile("/not/in/the/sdk.dart").toUri()),
        isNull);
  }

  void test_fromFile_library() {
    FolderBasedDartSdk sdk = _createDartSdk();
    Source source = sdk.fromFileUri(sdk.libraryDirectory
        .getChildAssumingFolder("core")
        .getChildAssumingFile("core.dart")
        .toUri());
    expect(source, isNotNull);
    expect(source.isInSystemLibrary, isTrue);
    expect(source.uri.toString(), "dart:core");
  }

  void test_fromFile_library_firstExact() {
    FolderBasedDartSdk sdk = _createDartSdk();
    Folder dirHtml = sdk.libraryDirectory.getChildAssumingFolder("html");
    Folder dirDartium = dirHtml.getChildAssumingFolder("dartium");
    File file = dirDartium.getChildAssumingFile("html_dartium.dart");
    Source source = sdk.fromFileUri(file.toUri());
    expect(source, isNotNull);
    expect(source.isInSystemLibrary, isTrue);
    expect(source.uri.toString(), "dart:html");
  }

  void test_fromFile_library_html_common_dart2js() {
    FolderBasedDartSdk sdk = _createDartSdk();
    Folder dirHtml = sdk.libraryDirectory.getChildAssumingFolder("html");
    Folder dirCommon = dirHtml.getChildAssumingFolder("html_common");
    File file = dirCommon.getChildAssumingFile("html_common_dart2js.dart");
    Source source = sdk.fromFileUri(file.toUri());
    expect(source, isNotNull);
    expect(source.isInSystemLibrary, isTrue);
    expect(source.uri.toString(), "dart:html_common/html_common_dart2js.dart");
  }

  void test_fromFile_part() {
    FolderBasedDartSdk sdk = _createDartSdk();
    Source source = sdk.fromFileUri(sdk.libraryDirectory
        .getChildAssumingFolder("core")
        .getChildAssumingFile("num.dart")
        .toUri());
    expect(source, isNotNull);
    expect(source.isInSystemLibrary, isTrue);
    expect(source.uri.toString(), "dart:core/num.dart");
  }

  void test_getDirectory() {
    FolderBasedDartSdk sdk = _createDartSdk();
    Folder directory = sdk.directory;
    expect(directory, isNotNull);
    expect(directory.exists, isTrue);
  }

  void test_getDocDirectory() {
    FolderBasedDartSdk sdk = _createDartSdk();
    Folder directory = sdk.docDirectory;
    expect(directory, isNotNull);
  }

  void test_getLibraryDirectory() {
    FolderBasedDartSdk sdk = _createDartSdk();
    Folder directory = sdk.libraryDirectory;
    expect(directory, isNotNull);
    expect(directory.exists, isTrue);
  }

  void test_getPubExecutable() {
    FolderBasedDartSdk sdk = _createDartSdk();
    File executable = sdk.pubExecutable;
    expect(executable, isNotNull);
    expect(executable.exists, isTrue);
  }

  void test_getSdkVersion() {
    FolderBasedDartSdk sdk = _createDartSdk();
    String version = sdk.sdkVersion;
    expect(version, isNotNull);
    expect(version.length > 0, isTrue);
  }

  /**
   * The "part" format should result in the same source as the non-part format
   * when the file is the library file.
   */
  void test_mapDartUri_partFormatForLibrary() {
    FolderBasedDartSdk sdk = _createDartSdk();
    Source normalSource = sdk.mapDartUri('dart:core');
    Source partSource = sdk.mapDartUri('dart:core/core.dart');
    expect(partSource, normalSource);
  }

  void test_useSummary_afterContextCreation() {
    FolderBasedDartSdk sdk = _createDartSdk();
    sdk.context;
    expect(() {
      sdk.useSummary = true;
    }, throwsStateError);
  }

  void test_useSummary_beforeContextCreation() {
    FolderBasedDartSdk sdk = _createDartSdk();
    sdk.useSummary = true;
    sdk.context;
  }

  FolderBasedDartSdk _createDartSdk() {
    resourceProvider = new MemoryResourceProvider();
    Folder sdkDirectory =
        resourceProvider.getFolder(resourceProvider.convertPath('/sdk'));
    _createFile(sdkDirectory,
        ['lib', '_internal', 'sdk_library_metadata', 'lib', 'libraries.dart'],
        content: _librariesFileContent());
    _createFile(sdkDirectory, ['bin', 'dart']);
    _createFile(sdkDirectory, ['bin', 'dart2js']);
    _createFile(sdkDirectory, ['bin', 'pub']);
    _createFile(sdkDirectory, ['lib', 'async', 'async.dart']);
    _createFile(sdkDirectory, ['lib', 'core', 'core.dart']);
    _createFile(sdkDirectory, ['lib', 'core', 'num.dart']);
    _createFile(sdkDirectory,
        ['lib', 'html', 'html_common', 'html_common_dart2js.dart']);
    _createFile(sdkDirectory, ['lib', 'html', 'dartium', 'html_dartium.dart']);
    _createFile(
        sdkDirectory, ['bin', (OSUtilities.isWindows() ? 'pub.bat' : 'pub')]);
    return new FolderBasedDartSdk(resourceProvider, sdkDirectory);
  }

  void _createFile(Folder directory, List<String> segments,
      {String content: ''}) {
    Folder parent = directory;
    int last = segments.length - 1;
    for (int i = 0; i < last; i++) {
      parent = parent.getChildAssumingFolder(segments[i]);
    }
    File file = parent.getChildAssumingFile(segments[last]);
    resourceProvider.newFile(file.path, content);
  }

  String _librariesFileContent() => '''
final Map<String, LibraryInfo> LIBRARIES = const <String, LibraryInfo> {
  "async": const LibraryInfo(
      "async/async.dart",
      categories: "Client,Server",
      maturity: Maturity.STABLE,
      dart2jsPatchPath: "_internal/js_runtime/lib/async_patch.dart"),

  "core": const LibraryInfo(
      "core/core.dart",
      categories: "Client,Server,Embedded",
      maturity: Maturity.STABLE,
      dart2jsPatchPath: "_internal/js_runtime/lib/core_patch.dart"),

  "html": const LibraryInfo(
      "html/dartium/html_dartium.dart",
      categories: "Client",
      maturity: Maturity.WEB_STABLE,
      dart2jsPath: "html/dart2js/html_dart2js.dart"),

  "html_common": const LibraryInfo(
      "html/html_common/html_common.dart",
      categories: "Client",
      maturity: Maturity.WEB_STABLE,
      dart2jsPath: "html/html_common/html_common_dart2js.dart",
      documented: false,
      implementation: true),
};
''';
}

@reflectiveTest
class SdkExtensionFinderTest {
  MemoryResourceProvider resourceProvider;

  void setUp() {
    resourceProvider = new MemoryResourceProvider();
    resourceProvider.newFolder(resourceProvider.convertPath('/empty'));
    resourceProvider.newFolder(resourceProvider.convertPath('/tmp'));
    resourceProvider.newFile(resourceProvider.convertPath('/tmp/_sdkext'), r'''
{
  "dart:fox": "slippy.dart",
  "dart:bear": "grizzly.dart",
  "dart:relative": "../relative.dart",
  "dart:deep": "deep/directory/file.dart",
  "fart:loudly": "nomatter.dart"
}''');
  }

  test_create_noSdkExtPackageMap() {
    var resolver = new SdkExtensionFinder({
      'fox': <Folder>[
        resourceProvider.getResource(resourceProvider.convertPath('/empty'))
      ]
    });
    expect(resolver.urlMappings.length, equals(0));
  }

  test_create_nullPackageMap() {
    var resolver = new SdkExtensionFinder(null);
    expect(resolver.urlMappings.length, equals(0));
  }

  test_create_sdkExtPackageMap() {
    var resolver = new SdkExtensionFinder({
      'fox': <Folder>[
        resourceProvider.getResource(resourceProvider.convertPath('/tmp'))
      ]
    });
    // We have four mappings.
    Map<String, String> urlMappings = resolver.urlMappings;
    expect(urlMappings.length, equals(4));
    // Check that they map to the correct paths.
    expect(urlMappings['dart:fox'],
        equals(resourceProvider.convertPath("/tmp/slippy.dart")));
    expect(urlMappings['dart:bear'],
        equals(resourceProvider.convertPath("/tmp/grizzly.dart")));
    expect(urlMappings['dart:relative'],
        equals(resourceProvider.convertPath("/relative.dart")));
    expect(urlMappings['dart:deep'],
        equals(resourceProvider.convertPath("/tmp/deep/directory/file.dart")));
  }
}

@reflectiveTest
class SdkLibrariesReaderTest extends EngineTestCase {
  /**
   * The resource provider used by these tests.
   */
  MemoryResourceProvider resourceProvider;

  @override
  void setUp() {
    resourceProvider = new MemoryResourceProvider();
  }

  void test_readFrom_dart2js() {
    LibraryMap libraryMap = new SdkLibrariesReader(true)
        .readFromFile(resourceProvider.getFile("/libs.dart"), r'''
final Map<String, LibraryInfo> LIBRARIES = const <String, LibraryInfo> {
  'first' : const LibraryInfo(
    'first/first.dart',
    categories: 'Client',
    documented: true,
    platforms: VM_PLATFORM,
    dart2jsPath: 'first/first_dart2js.dart'),
};''');
    expect(libraryMap, isNotNull);
    expect(libraryMap.size(), 1);
    SdkLibrary first = libraryMap.getLibrary("dart:first");
    expect(first, isNotNull);
    expect(first.category, "Client");
    expect(first.path, "first/first_dart2js.dart");
    expect(first.shortName, "dart:first");
    expect(first.isDart2JsLibrary, false);
    expect(first.isDocumented, true);
    expect(first.isImplementation, false);
    expect(first.isVmLibrary, true);
  }

  void test_readFrom_empty() {
    LibraryMap libraryMap = new SdkLibrariesReader(false)
        .readFromFile(resourceProvider.getFile("/libs.dart"), "");
    expect(libraryMap, isNotNull);
    expect(libraryMap.size(), 0);
  }

  void test_readFrom_normal() {
    LibraryMap libraryMap = new SdkLibrariesReader(false)
        .readFromFile(resourceProvider.getFile("/libs.dart"), r'''
final Map<String, LibraryInfo> LIBRARIES = const <String, LibraryInfo> {
  'first' : const LibraryInfo(
    'first/first.dart',
    categories: 'Client',
    documented: true,
    platforms: VM_PLATFORM),

  'second' : const LibraryInfo(
    'second/second.dart',
    categories: 'Server',
    documented: false,
    implementation: true,
    platforms: 0),
};''');
    expect(libraryMap, isNotNull);
    expect(libraryMap.size(), 2);
    SdkLibrary first = libraryMap.getLibrary("dart:first");
    expect(first, isNotNull);
    expect(first.category, "Client");
    expect(first.path, "first/first.dart");
    expect(first.shortName, "dart:first");
    expect(first.isDart2JsLibrary, false);
    expect(first.isDocumented, true);
    expect(first.isImplementation, false);
    expect(first.isVmLibrary, true);
    SdkLibrary second = libraryMap.getLibrary("dart:second");
    expect(second, isNotNull);
    expect(second.category, "Server");
    expect(second.path, "second/second.dart");
    expect(second.shortName, "dart:second");
    expect(second.isDart2JsLibrary, false);
    expect(second.isDocumented, false);
    expect(second.isImplementation, true);
    expect(second.isVmLibrary, false);
  }
}
