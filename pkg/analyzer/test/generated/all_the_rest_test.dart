// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/element/builder.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart' hide SdkLibrariesReader;
import 'package:analyzer/src/file_system/file_system.dart';
import 'package:analyzer/src/generated/java_engine_io.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/sdk_io.dart'; // ignore: deprecated_member_use_from_same_package
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/testing/ast_test_factory.dart';
import 'package:analyzer/src/generated/testing/test_type_provider.dart';
import 'package:analyzer/src/generated/testing/token_factory.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ContentCacheTest);
    // ignore: deprecated_member_use_from_same_package
    defineReflectiveTests(CustomUriResolverTest);
    defineReflectiveTests(DartUriResolverTest);
    defineReflectiveTests(EnumMemberBuilderTest);
    defineReflectiveTests(ErrorSeverityTest);
    defineReflectiveTests(FileBasedSourceTest);
    defineReflectiveTests(ResolveRelativeUriTest);
    // ignore: deprecated_member_use_from_same_package
    defineReflectiveTests(SDKLibrariesReaderTest);
    defineReflectiveTests(UriKindTest);
  });
}

@reflectiveTest
class ContentCacheTest {
  test_setContents() async {
    Source source = new TestSource();
    ContentCache cache = new ContentCache();
    expect(cache.getContents(source), isNull);
    expect(cache.getModificationStamp(source), isNull);
    String contents = "library lib;";
    expect(cache.setContents(source, contents), isNull);
    expect(cache.getContents(source), contents);
    expect(cache.getModificationStamp(source), isNotNull);
    expect(cache.setContents(source, contents), contents);
    expect(cache.setContents(source, null), contents);
    expect(cache.getContents(source), isNull);
    expect(cache.getModificationStamp(source), isNull);
    expect(cache.setContents(source, null), isNull);
  }
}

@deprecated
@reflectiveTest
class CustomUriResolverTest {
  void test_creation() {
    expect(new CustomUriResolver({}), isNotNull);
  }

  void test_resolve_unknown_uri() {
    UriResolver resolver = new CustomUriResolver({
      'custom:library': '/path/to/library.dart',
    });
    Source result = resolver.resolveAbsolute(Uri.parse("custom:non_library"));
    expect(result, isNull);
  }

  void test_resolve_uri() {
    String filePath =
        FileUtilities2.createFile("/path/to/library.dart").getAbsolutePath();
    UriResolver resolver = new CustomUriResolver({
      'custom:library': filePath,
    });
    Source result = resolver.resolveAbsolute(Uri.parse("custom:library"));
    expect(result, isNotNull);
    expect(result.fullName, filePath);
  }
}

@reflectiveTest
class DartUriResolverTest extends _SimpleDartSdkTest {
  DartUriResolver resolver;

  @override
  setUp() {
    super.setUp();
    resolver = new DartUriResolver(sdk);
  }

  void test_creation() {
    expect(new DartUriResolver(sdk), isNotNull);
  }

  void test_isDartUri_null_scheme() {
    Uri uri = Uri.parse("foo.dart");
    expect('', uri.scheme);
    expect(DartUriResolver.isDartUri(uri), isFalse);
  }

  void test_resolve_dart_library() {
    Source source = resolver.resolveAbsolute(Uri.parse('dart:core'));
    expect(source, isNotNull);
  }

  void test_resolve_dart_nonExistingLibrary() {
    Source result = resolver.resolveAbsolute(Uri.parse("dart:cor"));
    expect(result, isNull);
  }

  void test_resolve_dart_part() {
    Source source = resolver.resolveAbsolute(Uri.parse('dart:core/int.dart'));
    expect(source, isNotNull);
  }

  void test_resolve_nonDart() {
    Source result =
        resolver.resolveAbsolute(Uri.parse("package:some/file.dart"));
    expect(result, isNull);
  }

  void test_restoreAbsolute_library() {
    _SourceMock source = new _SourceMock();
    source.uri = toUri('/sdk/lib/core/core.dart');
    Uri dartUri = resolver.restoreAbsolute(source);
    expect(dartUri.toString(), 'dart:core');
  }

  void test_restoreAbsolute_part() {
    _SourceMock source = new _SourceMock();
    source.uri = toUri('/sdk/lib/core/int.dart');
    Uri dartUri = resolver.restoreAbsolute(source);
    expect(dartUri.toString(), 'dart:core/int.dart');
  }
}

@reflectiveTest
class EnumMemberBuilderTest extends EngineTestCase {
  test_visitEnumDeclaration_multiple() async {
    String firstName = "ONE";
    String secondName = "TWO";
    String thirdName = "THREE";
    EnumDeclaration enumDeclaration = AstTestFactory.enumDeclaration2(
        "E", [firstName, secondName, thirdName]);

    ClassElement enumElement = _buildElement(enumDeclaration);
    List<FieldElement> fields = enumElement.fields;
    expect(fields, hasLength(5));

    FieldElement constant = fields[2];
    expect(constant, isNotNull);
    expect(constant.name, firstName);
    expect(constant.isStatic, isTrue);
    expect((constant as FieldElementImpl).evaluationResult, isNotNull);
    _assertGetter(constant);

    constant = fields[3];
    expect(constant, isNotNull);
    expect(constant.name, secondName);
    expect(constant.isStatic, isTrue);
    expect((constant as FieldElementImpl).evaluationResult, isNotNull);
    _assertGetter(constant);

    constant = fields[4];
    expect(constant, isNotNull);
    expect(constant.name, thirdName);
    expect(constant.isStatic, isTrue);
    expect((constant as FieldElementImpl).evaluationResult, isNotNull);
    _assertGetter(constant);
  }

  test_visitEnumDeclaration_single() async {
    String firstName = "ONE";
    EnumDeclaration enumDeclaration =
        AstTestFactory.enumDeclaration2("E", [firstName]);
    enumDeclaration.constants[0].documentationComment =
        AstTestFactory.documentationComment(
            [TokenFactory.tokenFromString('/// aaa')..offset = 50], []);

    ClassElement enumElement = _buildElement(enumDeclaration);
    List<FieldElement> fields = enumElement.fields;
    expect(fields, hasLength(3));

    FieldElement field = fields[0];
    expect(field, isNotNull);
    expect(field.name, "index");
    expect(field.isStatic, isFalse);
    expect(field.isSynthetic, isTrue);
    _assertGetter(field);

    field = fields[1];
    expect(field, isNotNull);
    expect(field.name, "values");
    expect(field.isStatic, isTrue);
    expect(field.isSynthetic, isTrue);
    expect((field as FieldElementImpl).evaluationResult, isNotNull);
    _assertGetter(field);

    FieldElement constant = fields[2];
    expect(constant, isNotNull);
    expect(constant.name, firstName);
    expect(constant.isStatic, isTrue);
    expect((constant as FieldElementImpl).evaluationResult, isNotNull);
    expect(constant.documentationComment, '/// aaa');
    _assertGetter(constant);
  }

  void _assertGetter(FieldElement field) {
    PropertyAccessorElement getter = field.getter;
    expect(getter, isNotNull);
    expect(getter.variable, same(field));
    expect(getter.type, isNotNull);
  }

  ClassElement _buildElement(EnumDeclaration enumDeclaration) {
    ElementHolder holder = new ElementHolder();
    ElementBuilder elementBuilder = _makeBuilder(holder);
    enumDeclaration.accept(elementBuilder);
    EnumMemberBuilder memberBuilder =
        new EnumMemberBuilder(new TestTypeProvider());
    enumDeclaration.accept(memberBuilder);
    List<ClassElement> enums = holder.enums;
    expect(enums, hasLength(1));
    return enums[0];
  }

  ElementBuilder _makeBuilder(ElementHolder holder) =>
      new ElementBuilder(holder, new CompilationUnitElementImpl());
}

@reflectiveTest
class ErrorSeverityTest extends EngineTestCase {
  test_max_error_error() async {
    expect(ErrorSeverity.ERROR.max(ErrorSeverity.ERROR),
        same(ErrorSeverity.ERROR));
  }

  test_max_error_none() async {
    expect(
        ErrorSeverity.ERROR.max(ErrorSeverity.NONE), same(ErrorSeverity.ERROR));
  }

  test_max_error_warning() async {
    expect(ErrorSeverity.ERROR.max(ErrorSeverity.WARNING),
        same(ErrorSeverity.ERROR));
  }

  test_max_none_error() async {
    expect(
        ErrorSeverity.NONE.max(ErrorSeverity.ERROR), same(ErrorSeverity.ERROR));
  }

  test_max_none_none() async {
    expect(
        ErrorSeverity.NONE.max(ErrorSeverity.NONE), same(ErrorSeverity.NONE));
  }

  test_max_none_warning() async {
    expect(ErrorSeverity.NONE.max(ErrorSeverity.WARNING),
        same(ErrorSeverity.WARNING));
  }

  test_max_warning_error() async {
    expect(ErrorSeverity.WARNING.max(ErrorSeverity.ERROR),
        same(ErrorSeverity.ERROR));
  }

  test_max_warning_none() async {
    expect(ErrorSeverity.WARNING.max(ErrorSeverity.NONE),
        same(ErrorSeverity.WARNING));
  }

  test_max_warning_warning() async {
    expect(ErrorSeverity.WARNING.max(ErrorSeverity.WARNING),
        same(ErrorSeverity.WARNING));
  }
}

@reflectiveTest
class FileBasedSourceTest {
  test_equals_false_differentFiles() async {
    JavaFile file1 = FileUtilities2.createFile("/does/not/exist1.dart");
    JavaFile file2 = FileUtilities2.createFile("/does/not/exist2.dart");
    FileBasedSource source1 = new FileBasedSource(file1);
    FileBasedSource source2 = new FileBasedSource(file2);
    expect(source1 == source2, isFalse);
  }

  test_equals_false_null() async {
    JavaFile file = FileUtilities2.createFile("/does/not/exist1.dart");
    FileBasedSource source1 = new FileBasedSource(file);
    expect(source1 == null, isFalse);
  }

  test_equals_true() async {
    JavaFile file1 = FileUtilities2.createFile("/does/not/exist.dart");
    JavaFile file2 = FileUtilities2.createFile("/does/not/exist.dart");
    FileBasedSource source1 = new FileBasedSource(file1);
    FileBasedSource source2 = new FileBasedSource(file2);
    expect(source1 == source2, isTrue);
  }

  test_fileReadMode() async {
    expect(FileBasedSource.fileReadMode('a'), 'a');
    expect(FileBasedSource.fileReadMode('a\n'), 'a\n');
    expect(FileBasedSource.fileReadMode('ab'), 'ab');
    expect(FileBasedSource.fileReadMode('abc'), 'abc');
    expect(FileBasedSource.fileReadMode('a\nb'), 'a\nb');
    expect(FileBasedSource.fileReadMode('a\rb'), 'a\rb');
    expect(FileBasedSource.fileReadMode('a\r\nb'), 'a\r\nb');
  }

  test_fileReadMode_changed() async {
    FileBasedSource.fileReadMode = (String s) => s + 'xyz';
    expect(FileBasedSource.fileReadMode('a'), 'axyz');
    expect(FileBasedSource.fileReadMode('a\n'), 'a\nxyz');
    expect(FileBasedSource.fileReadMode('ab'), 'abxyz');
    expect(FileBasedSource.fileReadMode('abc'), 'abcxyz');
    FileBasedSource.fileReadMode = (String s) => s;
  }

  test_fileReadMode_normalize_eol_always() async {
    FileBasedSource.fileReadMode =
        PhysicalResourceProvider.NORMALIZE_EOL_ALWAYS;
    expect(FileBasedSource.fileReadMode('a'), 'a');

    // '\n' -> '\n' as first, last and only character
    expect(FileBasedSource.fileReadMode('\n'), '\n');
    expect(FileBasedSource.fileReadMode('a\n'), 'a\n');
    expect(FileBasedSource.fileReadMode('\na'), '\na');

    // '\r\n' -> '\n' as first, last and only character
    expect(FileBasedSource.fileReadMode('\r\n'), '\n');
    expect(FileBasedSource.fileReadMode('a\r\n'), 'a\n');
    expect(FileBasedSource.fileReadMode('\r\na'), '\na');

    // '\r' -> '\n' as first, last and only character
    expect(FileBasedSource.fileReadMode('\r'), '\n');
    expect(FileBasedSource.fileReadMode('a\r'), 'a\n');
    expect(FileBasedSource.fileReadMode('\ra'), '\na');

    FileBasedSource.fileReadMode = (String s) => s;
  }

  test_getEncoding() async {
    SourceFactory factory = new SourceFactory(
        [new ResourceUriResolver(PhysicalResourceProvider.INSTANCE)]);
    String fullPath = "/does/not/exist.dart";
    JavaFile file = FileUtilities2.createFile(fullPath);
    FileBasedSource source = new FileBasedSource(file);
    expect(factory.fromEncoding(source.encoding), source);
  }

  test_getFullName() async {
    String fullPath = "/does/not/exist.dart";
    JavaFile file = FileUtilities2.createFile(fullPath);
    FileBasedSource source = new FileBasedSource(file);
    expect(source.fullName, file.getAbsolutePath());
  }

  test_getShortName() async {
    JavaFile file = FileUtilities2.createFile("/does/not/exist.dart");
    FileBasedSource source = new FileBasedSource(file);
    expect(source.shortName, "exist.dart");
  }

  test_hashCode() async {
    JavaFile file1 = FileUtilities2.createFile("/does/not/exist.dart");
    JavaFile file2 = FileUtilities2.createFile("/does/not/exist.dart");
    FileBasedSource source1 = new FileBasedSource(file1);
    FileBasedSource source2 = new FileBasedSource(file2);
    expect(source2.hashCode, source1.hashCode);
  }

  test_isInSystemLibrary_contagious() async {
    DartSdk sdk = (new _SimpleDartSdkTest()..setUp()).sdk;
    UriResolver resolver = new DartUriResolver(sdk);
    SourceFactory factory = new SourceFactory([resolver]);
    // resolve dart:core
    Source result = resolver.resolveAbsolute(Uri.parse("dart:core"));
    expect(result, isNotNull);
    expect(result.isInSystemLibrary, isTrue);
    // system libraries reference only other system libraries
    Source partSource = factory.resolveUri(result, "num.dart");
    expect(partSource, isNotNull);
    expect(partSource.isInSystemLibrary, isTrue);
  }

  test_isInSystemLibrary_false() async {
    JavaFile file = FileUtilities2.createFile("/does/not/exist.dart");
    FileBasedSource source = new FileBasedSource(file);
    expect(source, isNotNull);
    expect(source.fullName, file.getAbsolutePath());
    expect(source.isInSystemLibrary, isFalse);
  }

  test_issue14500() async {
    // see https://code.google.com/p/dart/issues/detail?id=14500
    FileBasedSource source = new FileBasedSource(
        FileUtilities2.createFile("/some/packages/foo:bar.dart"));
    expect(source, isNotNull);
    expect(source.exists(), isFalse);
  }

  test_resolveRelative_file_fileName() async {
    if (OSUtilities.isWindows()) {
      // On Windows, the URI that is produced includes a drive letter,
      // which I believe is not consistent across all machines that might run
      // this test.
      return;
    }
    JavaFile file = FileUtilities2.createFile("/a/b/test.dart");
    FileBasedSource source = new FileBasedSource(file);
    expect(source, isNotNull);
    Uri relative = resolveRelativeUri(source.uri, Uri.parse("lib.dart"));
    expect(relative, isNotNull);
    expect(relative.toString(), "file:///a/b/lib.dart");
  }

  test_resolveRelative_file_filePath() async {
    if (OSUtilities.isWindows()) {
      // On Windows, the URI that is produced includes a drive letter,
      // which I believe is not consistent across all machines that might run
      // this test.
      return;
    }
    JavaFile file = FileUtilities2.createFile("/a/b/test.dart");
    FileBasedSource source = new FileBasedSource(file);
    expect(source, isNotNull);
    Uri relative = resolveRelativeUri(source.uri, Uri.parse("c/lib.dart"));
    expect(relative, isNotNull);
    expect(relative.toString(), "file:///a/b/c/lib.dart");
  }

  test_resolveRelative_file_filePathWithParent() async {
    if (OSUtilities.isWindows()) {
      // On Windows, the URI that is produced includes a drive letter, which I
      // believe is not consistent across all machines that might run this test.
      return;
    }
    JavaFile file = FileUtilities2.createFile("/a/b/test.dart");
    FileBasedSource source = new FileBasedSource(file);
    expect(source, isNotNull);
    Uri relative = resolveRelativeUri(source.uri, Uri.parse("../c/lib.dart"));
    expect(relative, isNotNull);
    expect(relative.toString(), "file:///a/c/lib.dart");
  }

  test_system() async {
    JavaFile file = FileUtilities2.createFile("/does/not/exist.dart");
    FileBasedSource source = new FileBasedSource(file, Uri.parse("dart:core"));
    expect(source, isNotNull);
    expect(source.fullName, file.getAbsolutePath());
    expect(source.isInSystemLibrary, isTrue);
  }
}

@reflectiveTest
class ResolveRelativeUriTest {
  test_resolveRelative_dart_dartUri() async {
    _assertResolve('dart:foo', 'dart:bar', 'dart:bar');
  }

  test_resolveRelative_dart_fileName() async {
    _assertResolve('dart:test', 'lib.dart', 'dart:test/lib.dart');
  }

  test_resolveRelative_dart_filePath() async {
    _assertResolve('dart:test', 'c/lib.dart', 'dart:test/c/lib.dart');
  }

  test_resolveRelative_dart_filePathWithParent() async {
    _assertResolve(
        'dart:test/b/test.dart', '../c/lib.dart', 'dart:test/c/lib.dart');
  }

  test_resolveRelative_package_dartUri() async {
    _assertResolve('package:foo/bar.dart', 'dart:test', 'dart:test');
  }

  test_resolveRelative_package_emptyPath() async {
    _assertResolve('package:foo/bar.dart', '', 'package:foo/bar.dart');
  }

  test_resolveRelative_package_fileName() async {
    _assertResolve('package:b/test.dart', 'lib.dart', 'package:b/lib.dart');
  }

  test_resolveRelative_package_fileNameWithoutPackageName() async {
    _assertResolve('package:test.dart', 'lib.dart', 'package:lib.dart');
  }

  test_resolveRelative_package_filePath() async {
    _assertResolve('package:b/test.dart', 'c/lib.dart', 'package:b/c/lib.dart');
  }

  test_resolveRelative_package_filePathWithParent() async {
    _assertResolve(
        'package:a/b/test.dart', '../c/lib.dart', 'package:a/c/lib.dart');
  }

  void _assertResolve(String baseStr, String containedStr, String expectedStr) {
    Uri base = Uri.parse(baseStr);
    Uri contained = Uri.parse(containedStr);
    Uri result = resolveRelativeUri(base, contained);
    expect(result, isNotNull);
    expect(result.toString(), expectedStr);
  }
}

@deprecated
@reflectiveTest
class SDKLibrariesReaderTest extends EngineTestCase {
  test_readFrom_dart2js() async {
    LibraryMap libraryMap = new SdkLibrariesReader(true)
        .readFromFile(FileUtilities2.createFile("/libs.dart"), r'''
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

  test_readFrom_empty() async {
    LibraryMap libraryMap = new SdkLibrariesReader(false)
        .readFromFile(FileUtilities2.createFile("/libs.dart"), "");
    expect(libraryMap, isNotNull);
    expect(libraryMap.size(), 0);
  }

  test_readFrom_normal() async {
    LibraryMap libraryMap = new SdkLibrariesReader(false)
        .readFromFile(FileUtilities2.createFile("/libs.dart"), r'''
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

@reflectiveTest
class UriKindTest {
  test_fromEncoding() async {
    expect(UriKind.fromEncoding(0x64), same(UriKind.DART_URI));
    expect(UriKind.fromEncoding(0x66), same(UriKind.FILE_URI));
    expect(UriKind.fromEncoding(0x70), same(UriKind.PACKAGE_URI));
    expect(UriKind.fromEncoding(0x58), same(null));
  }

  test_getEncoding() async {
    expect(UriKind.DART_URI.encoding, 0x64);
    expect(UriKind.FILE_URI.encoding, 0x66);
    expect(UriKind.PACKAGE_URI.encoding, 0x70);
  }
}

class _SimpleDartSdkTest with ResourceProviderMixin {
  DartSdk sdk;

  void setUp() {
    newFile('/sdk/lib/_internal/sdk_library_metadata/lib/libraries.dart',
        content: '''
const Map<String, LibraryInfo> libraries = const {
  "core": const LibraryInfo("core/core.dart")
};
''');

    newFile('/sdk/lib/core/core.dart', content: '''
library dart.core;
part 'int.dart';
''');

    newFile('/sdk/lib/core/int.dart', content: '''
part of dart.core;
''');

    Folder sdkFolder = newFolder('/sdk');
    sdk = new FolderBasedDartSdk(resourceProvider, sdkFolder);
  }
}

class _SourceMock implements Source {
  @override
  Uri uri;

  @override
  noSuchMethod(Invocation invocation) {
    throw new StateError('Unexpected invocation of ${invocation.memberName}');
  }
}
