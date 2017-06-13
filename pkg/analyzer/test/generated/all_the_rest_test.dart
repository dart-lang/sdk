// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.generated.all_the_rest_test;

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/ast/utilities.dart' hide ConstantEvaluator;
import 'package:analyzer/src/dart/element/builder.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart' hide SdkLibrariesReader;
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_engine_io.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/sdk_io.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/testing/ast_test_factory.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:analyzer/src/generated/testing/test_type_provider.dart';
import 'package:analyzer/src/generated/testing/token_factory.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/source/source_resource.dart';
import 'package:path/path.dart' as path;
import 'package:source_span/source_span.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:typed_mock/typed_mock.dart' show TypedMock, when;

import 'parser_test.dart';
import 'resolver_test_case.dart';
import 'test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ContentCacheTest);
    // ignore: deprecated_member_use
    defineReflectiveTests(CustomUriResolverTest);
    defineReflectiveTests(DartUriResolverTest);
    // ignore: deprecated_member_use
    defineReflectiveTests(DirectoryBasedDartSdkTest);
    // ignore: deprecated_member_use
    defineReflectiveTests(DirectoryBasedSourceContainerTest);
    defineReflectiveTests(ElementLocatorTest);
    defineReflectiveTests(EnumMemberBuilderTest);
    defineReflectiveTests(ErrorReporterTest);
    defineReflectiveTests(ErrorSeverityTest);
    defineReflectiveTests(ExitDetectorTest);
    defineReflectiveTests(ExitDetectorTest2);
    defineReflectiveTests(FileBasedSourceTest);
    defineReflectiveTests(ResolveRelativeUriTest);
    // ignore: deprecated_member_use
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
    Source source = new _SourceMock();
    Uri fileUri = resourceProvider.pathContext.toUri(coreCorePath);
    when(source.uri).thenReturn(fileUri);
    Uri dartUri = resolver.restoreAbsolute(source);
    expect(dartUri.toString(), 'dart:core');
  }

  void test_restoreAbsolute_part() {
    Source source = new _SourceMock();
    Uri fileUri = resourceProvider.pathContext.toUri(coreIntPath);
    when(source.uri).thenReturn(fileUri);
    Uri dartUri = resolver.restoreAbsolute(source);
    expect(dartUri.toString(), 'dart:core/int.dart');
  }
}

@deprecated
@reflectiveTest
class DirectoryBasedDartSdkTest {
  void fail_getDocFileFor() {
    DirectoryBasedDartSdk sdk = _createDartSdk();
    JavaFile docFile = sdk.getDocFileFor("html");
    expect(docFile, isNotNull);
  }

  void test_analysisOptions_afterContextCreation() {
    DirectoryBasedDartSdk sdk = _createDartSdk();
    sdk.context;
    expect(() {
      sdk.analysisOptions = new AnalysisOptionsImpl();
    }, throwsStateError);
  }

  void test_analysisOptions_beforeContextCreation() {
    DirectoryBasedDartSdk sdk = _createDartSdk();
    sdk.analysisOptions = new AnalysisOptionsImpl();
    sdk.context;
    // cannot change "analysisOptions" in the context
    expect(() {
      sdk.context.analysisOptions = new AnalysisOptionsImpl();
    }, throwsStateError);
  }

  void test_creation() {
    DirectoryBasedDartSdk sdk = _createDartSdk();
    expect(sdk, isNotNull);
  }

  void test_fromFile_invalid() {
    DirectoryBasedDartSdk sdk = _createDartSdk();
    expect(
        sdk.fromFileUri(new JavaFile("/not/in/the/sdk.dart").toURI()), isNull);
  }

  void test_fromFile_library() {
    DirectoryBasedDartSdk sdk = _createDartSdk();
    Source source = sdk.fromFileUri(new JavaFile.relative(
            new JavaFile.relative(sdk.libraryDirectory, "core"), "core.dart")
        .toURI());
    expect(source, isNotNull);
    expect(source.isInSystemLibrary, isTrue);
    expect(source.uri.toString(), "dart:core");
  }

  void test_fromFile_library_firstExact() {
    DirectoryBasedDartSdk sdk = _createDartSdk();
    JavaFile dirHtml = new JavaFile.relative(sdk.libraryDirectory, "html");
    JavaFile dirDartium = new JavaFile.relative(dirHtml, "dartium");
    JavaFile file = new JavaFile.relative(dirDartium, "html_dartium.dart");
    expect(file.isFile(), isTrue);
    Source source = sdk.fromFileUri(file.toURI());
    expect(source, isNotNull);
    expect(source.isInSystemLibrary, isTrue);
    expect(source.uri.toString(), "dart:html");
  }

  void test_fromFile_library_html_common_dart2js() {
    DirectoryBasedDartSdk sdk = _createDartSdk();
    JavaFile dirHtml = new JavaFile.relative(sdk.libraryDirectory, "html");
    JavaFile dirCommon = new JavaFile.relative(dirHtml, "html_common");
    JavaFile file =
        new JavaFile.relative(dirCommon, "html_common_dart2js.dart");
    expect(file.isFile(), isTrue);
    Source source = sdk.fromFileUri(file.toURI());
    expect(source, isNotNull);
    expect(source.isInSystemLibrary, isTrue);
    expect(source.uri.toString(), "dart:html_common/html_common_dart2js.dart");
  }

  void test_fromFile_part() {
    DirectoryBasedDartSdk sdk = _createDartSdk();
    Source source = sdk.fromFileUri(new JavaFile.relative(
            new JavaFile.relative(sdk.libraryDirectory, "core"), "num.dart")
        .toURI());
    expect(source, isNotNull);
    expect(source.isInSystemLibrary, isTrue);
    expect(source.uri.toString(), "dart:core/num.dart");
  }

  void test_getDart2JsExecutable() {
    DirectoryBasedDartSdk sdk = _createDartSdk();
    JavaFile executable = sdk.dart2JsExecutable;
    expect(executable, isNotNull);
    expect(executable.exists(), isTrue);
    expect(executable.isExecutable(), isTrue);
  }

  void test_getDirectory() {
    DirectoryBasedDartSdk sdk = _createDartSdk();
    JavaFile directory = sdk.directory;
    expect(directory, isNotNull);
    expect(directory.exists(), isTrue);
  }

  void test_getDocDirectory() {
    DirectoryBasedDartSdk sdk = _createDartSdk();
    JavaFile directory = sdk.docDirectory;
    expect(directory, isNotNull);
  }

  void test_getLibraryDirectory() {
    DirectoryBasedDartSdk sdk = _createDartSdk();
    JavaFile directory = sdk.libraryDirectory;
    expect(directory, isNotNull);
    expect(directory.exists(), isTrue);
  }

  void test_getPubExecutable() {
    DirectoryBasedDartSdk sdk = _createDartSdk();
    JavaFile executable = sdk.pubExecutable;
    expect(executable, isNotNull);
    expect(executable.exists(), isTrue);
    expect(executable.isExecutable(), isTrue);
  }

  void test_getSdkVersion() {
    DirectoryBasedDartSdk sdk = _createDartSdk();
    String version = sdk.sdkVersion;
    expect(version, isNotNull);
    expect(version.length > 0, isTrue);
  }

  void test_getVmExecutable() {
    DirectoryBasedDartSdk sdk = _createDartSdk();
    JavaFile executable = sdk.vmExecutable;
    expect(executable, isNotNull);
    expect(executable.exists(), isTrue);
    expect(executable.isExecutable(), isTrue);
  }

  void test_useSummary_afterContextCreation() {
    DirectoryBasedDartSdk sdk = _createDartSdk();
    sdk.context;
    expect(() {
      sdk.useSummary = true;
    }, throwsStateError);
  }

  void test_useSummary_beforeContextCreation() {
    DirectoryBasedDartSdk sdk = _createDartSdk();
    sdk.useSummary = true;
    sdk.context;
  }

  DirectoryBasedDartSdk _createDartSdk() {
    JavaFile sdkDirectory = DirectoryBasedDartSdk.defaultSdkDirectory;
    expect(sdkDirectory, isNotNull,
        reason:
            "No SDK configured; set the property 'com.google.dart.sdk' on the command line");
    return new DirectoryBasedDartSdk(sdkDirectory);
  }
}

@deprecated
@reflectiveTest
class DirectoryBasedSourceContainerTest {
  void test_contains() {
    MemoryResourceProvider resourceProvider = new MemoryResourceProvider();
    File file1 = resourceProvider.getFile('/does/not/exist/some.dart');
    File file2 = resourceProvider.getFile('/does/not/exist/folder/some2.dart');
    File file3 = resourceProvider.getFile('/does/not/exist3/some3.dart');
    Source source1 = new FileSource(file1);
    Source source2 = new FileSource(file2);
    Source source3 = new FileSource(file3);
    DirectoryBasedSourceContainer container =
        new DirectoryBasedSourceContainer.con2('/does/not/exist');
    expect(container.contains(source1), isTrue);
    expect(container.contains(source2), isTrue);
    expect(container.contains(source3), isFalse);
  }
}

@reflectiveTest
class ElementLocatorTest extends ResolverTestCase {
  void fail_locate_Identifier_partOfDirective() {
    // Can't resolve the library element without the library declaration.
    //    AstNode id = findNodeIn("foo", "part of foo.bar;");
    //    Element element = ElementLocator.locate(id);
    //    assertInstanceOf(LibraryElement.class, element);
    fail("Test this case");
  }

  @override
  void reset() {
    AnalysisOptionsImpl analysisOptions = new AnalysisOptionsImpl();
    analysisOptions.hint = false;
    resetWith(options: analysisOptions);
  }

  test_locate_AssignmentExpression() async {
    AstNode id = await _findNodeIn(
        "+=",
        r'''
int x = 0;
void main() {
  x += 1;
}''');
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is MethodElement, MethodElement, element);
  }

  test_locate_BinaryExpression() async {
    AstNode id = await _findNodeIn("+", "var x = 3 + 4;");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is MethodElement, MethodElement, element);
  }

  test_locate_ClassDeclaration() async {
    AstNode id = await _findNodeIn("class", "class A { }");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ClassElement, ClassElement, element);
  }

  test_locate_CompilationUnit() async {
    CompilationUnit cu = await _resolveContents("// only comment");
    expect(cu.element, isNotNull);
    Element element = ElementLocator.locate(cu);
    expect(element, same(cu.element));
  }

  test_locate_ConstructorDeclaration() async {
    AstNode id = await _findNodeIndexedIn(
        "bar",
        0,
        r'''
class A {
  A.bar() {}
}''');
    ConstructorDeclaration declaration =
        id.getAncestor((node) => node is ConstructorDeclaration);
    Element element = ElementLocator.locate(declaration);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ConstructorElement, ConstructorElement, element);
  }

  test_locate_ExportDirective() async {
    AstNode id = await _findNodeIn("export", "export 'dart:core';");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ExportElement, ExportElement, element);
  }

  test_locate_FunctionDeclaration() async {
    AstNode id = await _findNodeIn("f", "int f() => 3;");
    FunctionDeclaration declaration =
        id.getAncestor((node) => node is FunctionDeclaration);
    Element element = ElementLocator.locate(declaration);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is FunctionElement, FunctionElement, element);
  }

  test_locate_Identifier_annotationClass_namedConstructor_forSimpleFormalParameter() async {
    AstNode id = await _findNodeIndexedIn(
        "Class",
        2,
        r'''
class Class {
  const Class.name();
}
void main(@Class.name() parameter) {
}''');
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ClassElement, ClassElement, element);
  }

  test_locate_Identifier_annotationClass_unnamedConstructor_forSimpleFormalParameter() async {
    AstNode id = await _findNodeIndexedIn(
        "Class",
        2,
        r'''
class Class {
  const Class();
}
void main(@Class() parameter) {
}''');
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ConstructorElement, ConstructorElement, element);
  }

  test_locate_Identifier_className() async {
    AstNode id = await _findNodeIn("A", "class A { }");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ClassElement, ClassElement, element);
  }

  test_locate_Identifier_constructor_named() async {
    AstNode id = await _findNodeIndexedIn(
        "bar",
        0,
        r'''
class A {
  A.bar() {}
}''');
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ConstructorElement, ConstructorElement, element);
  }

  test_locate_Identifier_constructor_unnamed() async {
    AstNode id = await _findNodeIndexedIn(
        "A",
        1,
        r'''
class A {
  A() {}
}''');
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ConstructorElement, ConstructorElement, element);
  }

  test_locate_Identifier_fieldName() async {
    AstNode id = await _findNodeIn("x", "class A { var x; }");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is FieldElement, FieldElement, element);
  }

  test_locate_Identifier_libraryDirective() async {
    AstNode id = await _findNodeIn("foo", "library foo.bar;");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is LibraryElement, LibraryElement, element);
  }

  test_locate_Identifier_propertyAccess() async {
    AstNode id = await _findNodeIn(
        "length",
        r'''
void main() {
 int x = 'foo'.length;
}''');
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf((obj) => obj is PropertyAccessorElement,
        PropertyAccessorElement, element);
  }

  test_locate_ImportDirective() async {
    AstNode id = await _findNodeIn("import", "import 'dart:core';");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ImportElement, ImportElement, element);
  }

  test_locate_IndexExpression() async {
    AstNode id = await _findNodeIndexedIn(
        "\\[",
        1,
        r'''
void main() {
  List x = [1, 2];
  var y = x[0];
}''');
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is MethodElement, MethodElement, element);
  }

  test_locate_InstanceCreationExpression() async {
    AstNode node = await _findNodeIndexedIn(
        "A(",
        0,
        r'''
class A {}
void main() {
 new A();
}''');
    Element element = ElementLocator.locate(node);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ConstructorElement, ConstructorElement, element);
  }

  test_locate_InstanceCreationExpression_type_prefixedIdentifier() async {
    // prepare: new pref.A()
    SimpleIdentifier identifier = AstTestFactory.identifier3("A");
    PrefixedIdentifier prefixedIdentifier =
        AstTestFactory.identifier4("pref", identifier);
    InstanceCreationExpression creation =
        AstTestFactory.instanceCreationExpression2(
            Keyword.NEW, AstTestFactory.typeName3(prefixedIdentifier));
    // set ClassElement
    ClassElement classElement = ElementFactory.classElement2("A");
    identifier.staticElement = classElement;
    // set ConstructorElement
    ConstructorElement constructorElement =
        ElementFactory.constructorElement2(classElement, null);
    creation.constructorName.staticElement = constructorElement;
    // verify that "A" is resolved to ConstructorElement
    Element element = ElementLocator.locate(identifier);
    expect(element, same(classElement));
  }

  test_locate_InstanceCreationExpression_type_simpleIdentifier() async {
    // prepare: new A()
    SimpleIdentifier identifier = AstTestFactory.identifier3("A");
    InstanceCreationExpression creation =
        AstTestFactory.instanceCreationExpression2(
            Keyword.NEW, AstTestFactory.typeName3(identifier));
    // set ClassElement
    ClassElement classElement = ElementFactory.classElement2("A");
    identifier.staticElement = classElement;
    // set ConstructorElement
    ConstructorElement constructorElement =
        ElementFactory.constructorElement2(classElement, null);
    creation.constructorName.staticElement = constructorElement;
    // verify that "A" is resolved to ConstructorElement
    Element element = ElementLocator.locate(identifier);
    expect(element, same(classElement));
  }

  test_locate_LibraryDirective() async {
    AstNode id = await _findNodeIn("library", "library foo;");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is LibraryElement, LibraryElement, element);
  }

  test_locate_MethodDeclaration() async {
    AstNode id = await _findNodeIn(
        "m",
        r'''
class A {
  void m() {}
}''');
    MethodDeclaration declaration =
        id.getAncestor((node) => node is MethodDeclaration);
    Element element = ElementLocator.locate(declaration);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is MethodElement, MethodElement, element);
  }

  test_locate_MethodInvocation_method() async {
    AstNode id = await _findNodeIndexedIn(
        "bar",
        1,
        r'''
class A {
  int bar() => 42;
}
void main() {
 var f = new A().bar();
}''');
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is MethodElement, MethodElement, element);
  }

  test_locate_MethodInvocation_topLevel() async {
    String code = r'''
foo(x) {}
void main() {
 foo(0);
}''';
    CompilationUnit cu = await _resolveContents(code);
    int offset = code.indexOf('foo(0)');
    AstNode node = new NodeLocator(offset).searchWithin(cu);
    MethodInvocation invocation =
        node.getAncestor((n) => n is MethodInvocation);
    Element element = ElementLocator.locate(invocation);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is FunctionElement, FunctionElement, element);
  }

  test_locate_PartOfDirective() async {
    Source librarySource = addNamedSource(
        '/lib.dart',
        '''
library my.lib;
part 'part.dart';
''');
    Source unitSource = addNamedSource(
        '/part.dart',
        '''
part of my.lib;
''');
    CompilationUnit unit =
        analysisContext.resolveCompilationUnit2(unitSource, librarySource);
    PartOfDirective partOf = unit.directives.first;
    Element element = ElementLocator.locate(partOf);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is LibraryElement, LibraryElement, element);
  }

  test_locate_PostfixExpression() async {
    AstNode id = await _findNodeIn("++", "int addOne(int x) => x++;");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is MethodElement, MethodElement, element);
  }

  test_locate_PrefixedIdentifier() async {
    AstNode id = await _findNodeIn(
        "int",
        r'''
import 'dart:core' as core;
core.int value;''');
    PrefixedIdentifier identifier =
        id.getAncestor((node) => node is PrefixedIdentifier);
    Element element = ElementLocator.locate(identifier);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ClassElement, ClassElement, element);
  }

  test_locate_PrefixExpression() async {
    AstNode id = await _findNodeIn("++", "int addOne(int x) => ++x;");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is MethodElement, MethodElement, element);
  }

  test_locate_StringLiteral_exportUri() async {
    addNamedSource("/foo.dart", "library foo;");
    AstNode id = await _findNodeIn("'foo.dart'", "export 'foo.dart';");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is LibraryElement, LibraryElement, element);
  }

  test_locate_StringLiteral_expression() async {
    AstNode id = await _findNodeIn("abc", "var x = 'abc';");
    Element element = ElementLocator.locate(id);
    expect(element, isNull);
  }

  test_locate_StringLiteral_importUri() async {
    addNamedSource("/foo.dart", "library foo; class A {}");
    AstNode id = await _findNodeIn(
        "'foo.dart'", "import 'foo.dart'; class B extends A {}");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is LibraryElement, LibraryElement, element);
  }

  test_locate_StringLiteral_partUri() async {
    addNamedSource("/foo.dart", "part of app;");
    AstNode id =
        await _findNodeIn("'foo.dart'", "library app; part 'foo.dart';");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf((obj) => obj is CompilationUnitElement,
        CompilationUnitElement, element);
  }

  test_locate_VariableDeclaration() async {
    AstNode id = await _findNodeIn("x", "var x = 'abc';");
    VariableDeclaration declaration =
        id.getAncestor((node) => node is VariableDeclaration);
    Element element = ElementLocator.locate(declaration);
    EngineTestCase.assertInstanceOf((obj) => obj is TopLevelVariableElement,
        TopLevelVariableElement, element);
  }

  /**
   * Find the first AST node matching a pattern in the resolved AST for the given source.
   *
   * [nodePattern] the (unique) pattern used to identify the node of interest.
   * [code] the code to resolve.
   * Returns the matched node in the resolved AST for the given source lines.
   */
  Future<AstNode> _findNodeIn(String nodePattern, String code) async {
    return await _findNodeIndexedIn(nodePattern, 0, code);
  }

  /**
   * Find the AST node matching the given indexed occurrence of a pattern in the resolved AST for
   * the given source.
   *
   * [nodePattern] the pattern used to identify the node of interest.
   * [index] the index of the pattern match of interest.
   * [code] the code to resolve.
   * Returns the matched node in the resolved AST for the given source lines
   */
  Future<AstNode> _findNodeIndexedIn(
      String nodePattern, int index, String code) async {
    CompilationUnit cu = await _resolveContents(code);
    int start = _getOffsetOfMatch(code, nodePattern, index);
    int end = start + nodePattern.length;
    return new NodeLocator(start, end).searchWithin(cu);
  }

  int _getOffsetOfMatch(String contents, String pattern, int matchIndex) {
    if (matchIndex == 0) {
      return contents.indexOf(pattern);
    }
    Iterable<Match> matches = new RegExp(pattern).allMatches(contents);
    Match match = matches.toList()[matchIndex];
    return match.start;
  }

  /**
   * Parse, resolve and verify the given source lines to produce a fully
   * resolved AST.
   *
   * [code] the code to resolve.
   *
   * Returns the result of resolving the AST structure representing the content
   * of the source.
   *
   * Throws if source cannot be verified.
   */
  Future<CompilationUnit> _resolveContents(String code) async {
    Source source = addSource(code);
    LibraryElement library = resolve2(source);
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
    return analysisContext.resolveCompilationUnit(source, library);
  }
}

@reflectiveTest
class EnumMemberBuilderTest extends EngineTestCase {
  test_visitEnumDeclaration_multiple() async {
    String firstName = "ONE";
    String secondName = "TWO";
    String thirdName = "THREE";
    EnumDeclaration enumDeclaration = AstTestFactory
        .enumDeclaration2("E", [firstName, secondName, thirdName]);

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
    enumDeclaration.constants[0].documentationComment = AstTestFactory
        .documentationComment(
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
      new ElementBuilder(holder, new CompilationUnitElementImpl('test.dart'));
}

@reflectiveTest
class ErrorReporterTest extends EngineTestCase {
  /**
   * Create a type with the given name in a compilation unit with the given name.
   *
   * @param fileName the name of the compilation unit containing the class
   * @param typeName the name of the type to be created
   * @return the type that was created
   */
  InterfaceType createType(String fileName, String typeName) {
    CompilationUnitElementImpl unit = ElementFactory.compilationUnit(fileName);
    ClassElementImpl element = ElementFactory.classElement2(typeName);
    unit.types = <ClassElement>[element];
    return element.type;
  }

  test_creation() async {
    GatheringErrorListener listener = new GatheringErrorListener();
    TestSource source = new TestSource();
    expect(new ErrorReporter(listener, source), isNotNull);
  }

  test_reportErrorForElement_named() async {
    DartType type = createType("/test1.dart", "A");
    ClassElement element = type.element;
    GatheringErrorListener listener = new GatheringErrorListener();
    ErrorReporter reporter = new ErrorReporter(listener, element.source);
    reporter.reportErrorForElement(
        StaticWarningCode.CONFLICTING_INSTANCE_GETTER_AND_SUPERCLASS_MEMBER,
        element,
        ['A']);
    AnalysisError error = listener.errors[0];
    expect(error.offset, element.nameOffset);
  }

  test_reportErrorForElement_unnamed() async {
    ImportElementImpl element =
        ElementFactory.importFor(ElementFactory.library(null, ''), null);
    GatheringErrorListener listener = new GatheringErrorListener();
    ErrorReporter reporter = new ErrorReporter(
        listener,
        new NonExistingSource(
            '/test.dart', path.toUri('/test.dart'), UriKind.FILE_URI));
    reporter.reportErrorForElement(
        StaticWarningCode.CONFLICTING_INSTANCE_GETTER_AND_SUPERCLASS_MEMBER,
        element,
        ['A']);
    AnalysisError error = listener.errors[0];
    expect(error.offset, element.nameOffset);
  }

  test_reportErrorForSpan() async {
    GatheringErrorListener listener = new GatheringErrorListener();
    ErrorReporter reporter = new ErrorReporter(listener, new TestSource());

    var src = '''
foo: bar
zap: baz
''';

    int offset = src.indexOf('baz');
    int length = 'baz'.length;

    SourceSpan span = new SourceSpanBase(
        new SourceLocation(offset), new SourceLocation(offset + length), 'baz');

    reporter.reportErrorForSpan(
        AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITH_LEGAL_VALUE,
        span,
        ['test', 'zip', 'zap']);
    expect(listener.errors, hasLength(1));
    expect(listener.errors.first.offset, offset);
    expect(listener.errors.first.length, length);
  }

  test_reportTypeErrorForNode_differentNames() async {
    DartType firstType = createType("/test1.dart", "A");
    DartType secondType = createType("/test2.dart", "B");
    GatheringErrorListener listener = new GatheringErrorListener();
    ErrorReporter reporter =
        new ErrorReporter(listener, firstType.element.source);
    reporter.reportTypeErrorForNode(
        StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE,
        AstTestFactory.identifier3("x"),
        [firstType, secondType]);
    AnalysisError error = listener.errors[0];
    expect(error.message.indexOf("(") < 0, isTrue);
  }

  test_reportTypeErrorForNode_sameName() async {
    String typeName = "A";
    DartType firstType = createType("/test1.dart", typeName);
    DartType secondType = createType("/test2.dart", typeName);
    GatheringErrorListener listener = new GatheringErrorListener();
    ErrorReporter reporter =
        new ErrorReporter(listener, firstType.element.source);
    reporter.reportTypeErrorForNode(
        StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE,
        AstTestFactory.identifier3("x"),
        [firstType, secondType]);
    AnalysisError error = listener.errors[0];
    expect(error.message.indexOf("(") >= 0, isTrue);
  }
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

/**
 * Tests for the [ExitDetector] that do not require that the AST be resolved.
 *
 * See [ExitDetectorTest2] for tests that require the AST to be resolved.
 */
@reflectiveTest
class ExitDetectorTest extends ParserTestCase {
  test_asExpression() async {
    _assertFalse("a as Object;");
  }

  test_asExpression_throw() async {
    _assertTrue("throw '' as Object;");
  }

  test_assertStatement() async {
    _assertFalse("assert(a);");
  }

  test_assertStatement_throw() async {
    _assertFalse("assert((throw 0));");
  }

  test_assignmentExpression() async {
    _assertFalse("v = 1;");
  }

  test_assignmentExpression_compound_lazy() async {
    enableLazyAssignmentOperators = true;
    _assertFalse("v ||= false;");
  }

  test_assignmentExpression_lhs_throw() async {
    _assertTrue("a[throw ''] = 0;");
  }

  test_assignmentExpression_rhs_throw() async {
    _assertTrue("v = throw '';");
  }

  test_await_false() async {
    _assertFalse("await x;");
  }

  test_await_throw_true() async {
    _assertTrue("bool b = await (throw '' || true);");
  }

  test_binaryExpression_and() async {
    _assertFalse("a && b;");
  }

  test_binaryExpression_and_lhs() async {
    _assertTrue("throw '' && b;");
  }

  test_binaryExpression_and_rhs() async {
    _assertFalse("a && (throw '');");
  }

  test_binaryExpression_and_rhs2() async {
    _assertFalse("false && (throw '');");
  }

  test_binaryExpression_and_rhs3() async {
    _assertTrue("true && (throw '');");
  }

  test_binaryExpression_ifNull() async {
    _assertFalse("a ?? b;");
  }

  test_binaryExpression_ifNull_lhs() async {
    _assertTrue("throw '' ?? b;");
  }

  test_binaryExpression_ifNull_rhs() async {
    _assertFalse("a ?? (throw '');");
  }

  test_binaryExpression_ifNull_rhs2() async {
    _assertFalse("null ?? (throw '');");
  }

  test_binaryExpression_or() async {
    _assertFalse("a || b;");
  }

  test_binaryExpression_or_lhs() async {
    _assertTrue("throw '' || b;");
  }

  test_binaryExpression_or_rhs() async {
    _assertFalse("a || (throw '');");
  }

  test_binaryExpression_or_rhs2() async {
    _assertFalse("true || (throw '');");
  }

  test_binaryExpression_or_rhs3() async {
    _assertTrue("false || (throw '');");
  }

  test_block_empty() async {
    _assertFalse("{}");
  }

  test_block_noReturn() async {
    _assertFalse("{ int i = 0; }");
  }

  test_block_return() async {
    _assertTrue("{ return 0; }");
  }

  test_block_returnNotLast() async {
    _assertTrue("{ return 0; throw 'a'; }");
  }

  test_block_throwNotLast() async {
    _assertTrue("{ throw 0; x = null; }");
  }

  test_cascadeExpression_argument() async {
    _assertTrue("a..b(throw '');");
  }

  test_cascadeExpression_index() async {
    _assertTrue("a..[throw ''];");
  }

  test_cascadeExpression_target() async {
    _assertTrue("throw ''..b();");
  }

  test_conditional_ifElse_bothThrows() async {
    _assertTrue("c ? throw '' : throw '';");
  }

  test_conditional_ifElse_elseThrows() async {
    _assertFalse("c ? i : throw '';");
  }

  test_conditional_ifElse_noThrow() async {
    _assertFalse("c ? i : j;");
  }

  test_conditional_ifElse_thenThrow() async {
    _assertFalse("c ? throw '' : j;");
  }

  test_conditionalAccess() async {
    _assertFalse("a?.b;");
  }

  test_conditionalAccess_lhs() async {
    _assertTrue("(throw '')?.b;");
  }

  test_conditionalAccessAssign() async {
    _assertFalse("a?.b = c;");
  }

  test_conditionalAccessAssign_lhs() async {
    _assertTrue("(throw '')?.b = c;");
  }

  test_conditionalAccessAssign_rhs() async {
    _assertFalse("a?.b = throw '';");
  }

  test_conditionalAccessAssign_rhs2() async {
    _assertFalse("null?.b = throw '';");
  }

  test_conditionalAccessIfNullAssign() async {
    _assertFalse("a?.b ??= c;");
  }

  test_conditionalAccessIfNullAssign_lhs() async {
    _assertTrue("(throw '')?.b ??= c;");
  }

  test_conditionalAccessIfNullAssign_rhs() async {
    _assertFalse("a?.b ??= throw '';");
  }

  test_conditionalAccessIfNullAssign_rhs2() async {
    _assertFalse("null?.b ??= throw '';");
  }

  test_conditionalCall() async {
    _assertFalse("a?.b(c);");
  }

  test_conditionalCall_lhs() async {
    _assertTrue("(throw '')?.b(c);");
  }

  test_conditionalCall_rhs() async {
    _assertFalse("a?.b(throw '');");
  }

  test_conditionalCall_rhs2() async {
    _assertFalse("null?.b(throw '');");
  }

  test_creation() async {
    expect(new ExitDetector(), isNotNull);
  }

  test_doStatement_break_and_throw() async {
    _assertFalse("{ do { if (1==1) break; throw 'T'; } while (0==1); }");
  }

  test_doStatement_continue_and_throw() async {
    _assertFalse("{ do { if (1==1) continue; throw 'T'; } while (0==1); }");
  }

  test_doStatement_continueDoInSwitch_and_throw() async {
    _assertFalse('''
{
  D: do {
    switch (1) {
      L: case 0: continue D;
      M: case 1: break;
    }
    throw 'T';
  } while (0 == 1);
}''');
  }

  test_doStatement_continueInSwitch_and_throw() async {
    _assertFalse('''
{
  do {
    switch (1) {
      L: case 0: continue;
      M: case 1: break;
    }
    throw 'T';
  } while (0 == 1);
}''');
  }

  test_doStatement_return() async {
    _assertTrue("{ do { return null; } while (1 == 2); }");
  }

  test_doStatement_throwCondition() async {
    _assertTrue("{ do {} while (throw ''); }");
  }

  test_doStatement_true_break() async {
    _assertFalse("{ do { break; } while (true); }");
  }

  test_doStatement_true_continue() async {
    _assertTrue("{ do { continue; } while (true); }");
  }

  test_doStatement_true_continueWithLabel() async {
    _assertTrue("{ x: do { continue x; } while (true); }");
  }

  test_doStatement_true_if_return() async {
    _assertTrue("{ do { if (true) {return null;} } while (true); }");
  }

  test_doStatement_true_noBreak() async {
    _assertTrue("{ do {} while (true); }");
  }

  test_doStatement_true_return() async {
    _assertTrue("{ do { return null; } while (true);  }");
  }

  test_emptyStatement() async {
    _assertFalse(";");
  }

  test_forEachStatement() async {
    _assertFalse("for (element in list) {}");
  }

  test_forEachStatement_throw() async {
    _assertTrue("for (element in throw '') {}");
  }

  test_forStatement_condition() async {
    _assertTrue("for (; throw 0;) {}");
  }

  test_forStatement_implicitTrue() async {
    _assertTrue("for (;;) {}");
  }

  test_forStatement_implicitTrue_break() async {
    _assertFalse("for (;;) { break; }");
  }

  test_forStatement_implicitTrue_if_break() async {
    _assertFalse("{ for (;;) { if (1==2) { var a = 1; } else { break; } } }");
  }

  test_forStatement_initialization() async {
    _assertTrue("for (i = throw 0;;) {}");
  }

  test_forStatement_true() async {
    _assertTrue("for (; true; ) {}");
  }

  test_forStatement_true_break() async {
    _assertFalse("{ for (; true; ) { break; } }");
  }

  test_forStatement_true_continue() async {
    _assertTrue("{ for (; true; ) { continue; } }");
  }

  test_forStatement_true_if_return() async {
    _assertTrue("{ for (; true; ) { if (true) {return null;} } }");
  }

  test_forStatement_true_noBreak() async {
    _assertTrue("{ for (; true; ) {} }");
  }

  test_forStatement_updaters() async {
    _assertTrue("for (;; i++, throw 0) {}");
  }

  test_forStatement_variableDeclaration() async {
    _assertTrue("for (int i = throw 0;;) {}");
  }

  test_functionExpression() async {
    _assertFalse("(){};");
  }

  test_functionExpression_bodyThrows() async {
    _assertFalse("(int i) => throw '';");
  }

  test_functionExpressionInvocation() async {
    _assertFalse("f(g);");
  }

  test_functionExpressionInvocation_argumentThrows() async {
    _assertTrue("f(throw '');");
  }

  test_functionExpressionInvocation_targetThrows() async {
    _assertTrue("throw ''(g);");
  }

  test_identifier_prefixedIdentifier() async {
    _assertFalse("a.b;");
  }

  test_identifier_simpleIdentifier() async {
    _assertFalse("a;");
  }

  test_if_false_else_return() async {
    _assertTrue("if (false) {} else { return 0; }");
  }

  test_if_false_noReturn() async {
    _assertFalse("if (false) {}");
  }

  test_if_false_return() async {
    _assertFalse("if (false) { return 0; }");
  }

  test_if_noReturn() async {
    _assertFalse("if (c) i++;");
  }

  test_if_return() async {
    _assertFalse("if (c) return 0;");
  }

  test_if_true_noReturn() async {
    _assertFalse("if (true) {}");
  }

  test_if_true_return() async {
    _assertTrue("if (true) { return 0; }");
  }

  test_ifElse_bothReturn() async {
    _assertTrue("if (c) return 0; else return 1;");
  }

  test_ifElse_elseReturn() async {
    _assertFalse("if (c) i++; else return 1;");
  }

  test_ifElse_noReturn() async {
    _assertFalse("if (c) i++; else j++;");
  }

  test_ifElse_thenReturn() async {
    _assertFalse("if (c) return 0; else j++;");
  }

  test_ifNullAssign() async {
    _assertFalse("a ??= b;");
  }

  test_ifNullAssign_rhs() async {
    _assertFalse("a ??= throw '';");
  }

  test_indexExpression() async {
    _assertFalse("a[b];");
  }

  test_indexExpression_index() async {
    _assertTrue("a[throw ''];");
  }

  test_indexExpression_target() async {
    _assertTrue("throw ''[b];");
  }

  test_instanceCreationExpression() async {
    _assertFalse("new A(b);");
  }

  test_instanceCreationExpression_argumentThrows() async {
    _assertTrue("new A(throw '');");
  }

  test_isExpression() async {
    _assertFalse("A is B;");
  }

  test_isExpression_throws() async {
    _assertTrue("throw '' is B;");
  }

  test_labeledStatement() async {
    _assertFalse("label: a;");
  }

  test_labeledStatement_throws() async {
    _assertTrue("label: throw '';");
  }

  test_literal_boolean() async {
    _assertFalse("true;");
  }

  test_literal_double() async {
    _assertFalse("1.1;");
  }

  test_literal_integer() async {
    _assertFalse("1;");
  }

  test_literal_null() async {
    _assertFalse("null;");
  }

  test_literal_String() async {
    _assertFalse("'str';");
  }

  test_methodInvocation() async {
    _assertFalse("a.b(c);");
  }

  test_methodInvocation_argument() async {
    _assertTrue("a.b(throw '');");
  }

  test_methodInvocation_target() async {
    _assertTrue("throw ''.b(c);");
  }

  test_parenthesizedExpression() async {
    _assertFalse("(a);");
  }

  test_parenthesizedExpression_throw() async {
    _assertTrue("(throw '');");
  }

  test_propertyAccess() async {
    _assertFalse("new Object().a;");
  }

  test_propertyAccess_throws() async {
    _assertTrue("(throw '').a;");
  }

  test_rethrow() async {
    _assertTrue("rethrow;");
  }

  test_return() async {
    _assertTrue("return 0;");
  }

  test_superExpression() async {
    _assertFalse("super.a;");
  }

  test_switch_allReturn() async {
    _assertTrue("switch (i) { case 0: return 0; default: return 1; }");
  }

  test_switch_defaultWithNoStatements() async {
    _assertFalse("switch (i) { case 0: return 0; default: }");
  }

  test_switch_fallThroughToNotReturn() async {
    _assertFalse("switch (i) { case 0: case 1: break; default: return 1; }");
  }

  test_switch_fallThroughToReturn() async {
    _assertTrue("switch (i) { case 0: case 1: return 0; default: return 1; }");
  }

  // The ExitDetector could conceivably follow switch continue labels and
  // determine that `case 0` exits, `case 1` continues to an exiting case, and
  // `default` exits, so the switch exits.
  @failingTest
  test_switch_includesContinue() async {
    _assertTrue('''
switch (i) {
  zero: case 0: return 0;
  case 1: continue zero;
  default: return 1;
}''');
  }

  test_switch_noDefault() async {
    _assertFalse("switch (i) { case 0: return 0; }");
  }

  test_switch_nonReturn() async {
    _assertFalse("switch (i) { case 0: i++; default: return 1; }");
  }

  test_thisExpression() async {
    _assertFalse("this.a;");
  }

  test_throwExpression() async {
    _assertTrue("throw new Object();");
  }

  test_tryStatement_noReturn() async {
    _assertFalse("try {} catch (e, s) {} finally {}");
  }

  test_tryStatement_noReturn_noFinally() async {
    _assertFalse("try {} catch (e, s) {}");
  }

  test_tryStatement_return_catch() async {
    _assertFalse("try {} catch (e, s) { return 1; } finally {}");
  }

  test_tryStatement_return_catch_noFinally() async {
    _assertFalse("try {} catch (e, s) { return 1; }");
  }

  test_tryStatement_return_finally() async {
    _assertTrue("try {} catch (e, s) {} finally { return 1; }");
  }

  test_tryStatement_return_try_noCatch() async {
    _assertTrue("try { return 1; } finally {}");
  }

  test_tryStatement_return_try_oneCatchDoesNotExit() async {
    _assertFalse("try { return 1; } catch (e, s) {} finally {}");
  }

  test_tryStatement_return_try_oneCatchDoesNotExit_noFinally() async {
    _assertFalse("try { return 1; } catch (e, s) {}");
  }

  test_tryStatement_return_try_oneCatchExits() async {
    _assertTrue("try { return 1; } catch (e, s) { return 1; } finally {}");
  }

  test_tryStatement_return_try_oneCatchExits_noFinally() async {
    _assertTrue("try { return 1; } catch (e, s) { return 1; }");
  }

  test_tryStatement_return_try_twoCatchesDoExit() async {
    _assertTrue('''
try { return 1; }
on int catch (e, s) { return 1; }
on String catch (e, s) { return 1; }
finally {}''');
  }

  test_tryStatement_return_try_twoCatchesDoExit_noFinally() async {
    _assertTrue('''
try { return 1; }
on int catch (e, s) { return 1; }
on String catch (e, s) { return 1; }''');
  }

  test_tryStatement_return_try_twoCatchesDoNotExit() async {
    _assertFalse('''
try { return 1; }
on int catch (e, s) {}
on String catch (e, s) {}
finally {}''');
  }

  test_tryStatement_return_try_twoCatchesDoNotExit_noFinally() async {
    _assertFalse('''
try { return 1; }
on int catch (e, s) {}
on String catch (e, s) {}''');
  }

  test_tryStatement_return_try_twoCatchesMixed() async {
    _assertFalse('''
try { return 1; }
on int catch (e, s) {}
on String catch (e, s) { return 1; }
finally {}''');
  }

  test_tryStatement_return_try_twoCatchesMixed_noFinally() async {
    _assertFalse('''
try { return 1; }
on int catch (e, s) {}
on String catch (e, s) { return 1; }''');
  }

  test_variableDeclarationStatement_noInitializer() async {
    _assertFalse("int i;");
  }

  test_variableDeclarationStatement_noThrow() async {
    _assertFalse("int i = 0;");
  }

  test_variableDeclarationStatement_throw() async {
    _assertTrue("int i = throw new Object();");
  }

  test_whileStatement_false_nonReturn() async {
    _assertFalse("{ while (false) {} }");
  }

  test_whileStatement_throwCondition() async {
    _assertTrue("{ while (throw '') {} }");
  }

  test_whileStatement_true_break() async {
    _assertFalse("{ while (true) { break; } }");
  }

  test_whileStatement_true_break_and_throw() async {
    _assertFalse("{ while (true) { if (1==1) break; throw 'T'; } }");
  }

  test_whileStatement_true_continue() async {
    _assertTrue("{ while (true) { continue; } }");
  }

  test_whileStatement_true_continueWithLabel() async {
    _assertTrue("{ x: while (true) { continue x; } }");
  }

  test_whileStatement_true_doStatement_scopeRequired() async {
    _assertTrue("{ while (true) { x: do { continue x; } while (true); } }");
  }

  test_whileStatement_true_if_return() async {
    _assertTrue("{ while (true) { if (true) {return null;} } }");
  }

  test_whileStatement_true_noBreak() async {
    _assertTrue("{ while (true) {} }");
  }

  test_whileStatement_true_return() async {
    _assertTrue("{ while (true) { return null; } }");
  }

  test_whileStatement_true_throw() async {
    _assertTrue("{ while (true) { throw ''; } }");
  }

  void _assertFalse(String source) {
    _assertHasReturn(false, source);
  }

  void _assertHasReturn(bool expectedResult, String source) {
    Statement statement = parseStatement(source, enableLazyAssignmentOperators);
    expect(ExitDetector.exits(statement), expectedResult);
  }

  void _assertTrue(String source) {
    _assertHasReturn(true, source);
  }
}

/**
 * Tests for the [ExitDetector] that require that the AST be resolved.
 *
 * See [ExitDetectorTest] for tests that do not require the AST to be resolved.
 */
@reflectiveTest
class ExitDetectorTest2 extends ResolverTestCase {
  test_forStatement_implicitTrue_breakWithLabel() async {
    Source source = addSource(r'''
void f() {
  x: for (;;) {
    if (1 < 2) {
      break x;
    }
    return;
  }
}
''');
    _assertNthStatementDoesNotExit(source, 0);
  }

  test_switch_withEnum_false_noDefault() async {
    Source source = addSource(r'''
enum E { A, B }
String f(E e) {
  var x;
  switch (e) {
    case A:
      x = 'A';
    case B:
      x = 'B';
  }
  return x;
}
''');
    _assertNthStatementDoesNotExit(source, 1);
  }

  test_switch_withEnum_false_withDefault() async {
    Source source = addSource(r'''
enum E { A, B }
String f(E e) {
  var x;
  switch (e) {
    case A:
      x = 'A';
    default:
      x = '?';
  }
  return x;
}
''');
    _assertNthStatementDoesNotExit(source, 1);
  }

  test_switch_withEnum_true_noDefault() async {
    Source source = addSource(r'''
enum E { A, B }
String f(E e) {
  switch (e) {
    case A:
      return 'A';
    case B:
      return 'B';
  }
}
''');
    _assertNthStatementDoesNotExit(source, 0);
  }

  test_switch_withEnum_true_withExitingDefault() async {
    Source source = addSource(r'''
enum E { A, B }
String f(E e) {
  switch (e) {
    case A:
      return 'A';
    default:
      return '?';
  }
}
''');
    _assertNthStatementExits(source, 0);
  }

  test_switch_withEnum_true_withNonExitingDefault() async {
    Source source = addSource(r'''
enum E { A, B }
String f(E e) {
  var x;
  switch (e) {
    case A:
      return 'A';
    default:
      x = '?';
  }
}
''');
    _assertNthStatementDoesNotExit(source, 1);
  }

  test_whileStatement_breakWithLabel() async {
    Source source = addSource(r'''
void f() {
  x: while (true) {
    if (1 < 2) {
      break x;
    }
    return;
  }
}
''');
    _assertNthStatementDoesNotExit(source, 0);
  }

  test_whileStatement_breakWithLabel_afterExiting() async {
    Source source = addSource(r'''
void f() {
  x: while (true) {
    return;
    if (1 < 2) {
      break x;
    }
  }
}
''');
    _assertNthStatementExits(source, 0);
  }

  test_whileStatement_switchWithBreakWithLabel() async {
    Source source = addSource(r'''
void f() {
  x: while (true) {
    switch (true) {
      case false: break;
      case true: break x;
    }
  }
}
''');
    _assertNthStatementDoesNotExit(source, 0);
  }

  test_yieldStatement_plain() async {
    Source source = addSource(r'''
void f() sync* {
  yield 1;
}
''');
    _assertNthStatementDoesNotExit(source, 0);
  }

  test_yieldStatement_star_plain() async {
    Source source = addSource(r'''
void f() sync* {
  yield* 1;
}
''');
    _assertNthStatementDoesNotExit(source, 0);
  }

  test_yieldStatement_star_throw() async {
    Source source = addSource(r'''
void f() sync* {
  yield* throw '';
}
''');
    _assertNthStatementExits(source, 0);
  }

  test_yieldStatement_throw() async {
    Source source = addSource(r'''
void f() sync* {
  yield throw '';
}
''');
    _assertNthStatementExits(source, 0);
  }

  void _assertHasReturn(bool expectedResult, Source source, int n) {
    LibraryElement element = resolve2(source);
    CompilationUnit unit = resolveCompilationUnit(source, element);
    FunctionDeclaration function = unit.declarations.last;
    BlockFunctionBody body = function.functionExpression.body;
    Statement statement = body.block.statements[n];
    expect(ExitDetector.exits(statement), expectedResult);
  }

  // Assert that the [n]th statement in the last function declaration of
  // [source] exits.
  void _assertNthStatementDoesNotExit(Source source, int n) {
    _assertHasReturn(false, source, n);
  }

  // Assert that the [n]th statement in the last function declaration of
  // [source] does not exit.
  void _assertNthStatementExits(Source source, int n) {
    _assertHasReturn(true, source, n);
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
    LibraryMap libraryMap = new SdkLibrariesReader(true).readFromFile(
        FileUtilities2.createFile("/libs.dart"),
        r'''
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
    LibraryMap libraryMap = new SdkLibrariesReader(false).readFromFile(
        FileUtilities2.createFile("/libs.dart"),
        r'''
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

class _SimpleDartSdkTest {
  MemoryResourceProvider resourceProvider = new MemoryResourceProvider();
  String coreCorePath;
  String coreIntPath;
  DartSdk sdk;

  void setUp() {
    Folder sdkFolder =
        resourceProvider.newFolder(resourceProvider.convertPath('/sdk'));
    resourceProvider.newFile(
        resourceProvider.convertPath(
            '/sdk/lib/_internal/sdk_library_metadata/lib/libraries.dart'),
        '''
const Map<String, LibraryInfo> libraries = const {
  "core": const LibraryInfo("core/core.dart")
};
''');
    coreCorePath = resourceProvider.convertPath('/sdk/lib/core/core.dart');
    resourceProvider.newFile(
        coreCorePath,
        '''
library dart.core;
part 'int.dart';
''');
    coreIntPath = resourceProvider.convertPath('/sdk/lib/core/int.dart');
    resourceProvider.newFile(
        coreIntPath,
        '''
part of dart.core;
''');
    sdk = new FolderBasedDartSdk(resourceProvider, sdkFolder);
  }
}

class _SourceMock extends TypedMock implements Source {}
