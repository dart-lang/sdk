// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.generated.all_the_rest_test;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/utilities.dart' hide ConstantEvaluator;
import 'package:analyzer/src/dart/element/builder.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/java_engine_io.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/sdk_io.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/testing/ast_factory.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:analyzer/src/generated/testing/test_type_provider.dart';
import 'package:analyzer/src/generated/testing/token_factory.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:path/path.dart';
import 'package:source_span/source_span.dart';
import 'package:unittest/unittest.dart';

import '../reflective_tests.dart';
import '../utils.dart';
import 'parser_test.dart';
import 'resolver_test_case.dart';
import 'test_support.dart';

main() {
  initializeTestEnvironment();
  runReflectiveTests(ContentCacheTest);
  runReflectiveTests(CustomUriResolverTest);
  runReflectiveTests(DartUriResolverTest);
  runReflectiveTests(DirectoryBasedDartSdkTest);
  runReflectiveTests(DirectoryBasedSourceContainerTest);
  runReflectiveTests(ElementBuilderTest);
  runReflectiveTests(ElementLocatorTest);
  runReflectiveTests(EnumMemberBuilderTest);
  runReflectiveTests(ErrorReporterTest);
  runReflectiveTests(ErrorSeverityTest);
  runReflectiveTests(ExitDetectorTest);
  runReflectiveTests(ExitDetectorTest2);
  runReflectiveTests(FileBasedSourceTest);
  runReflectiveTests(ResolveRelativeUriTest);
  runReflectiveTests(SDKLibrariesReaderTest);
  runReflectiveTests(UriKindTest);
}

@reflectiveTest
class ContentCacheTest {
  void test_setContents() {
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

@reflectiveTest
class CustomUriResolverTest {
  void test_creation() {
    expect(new CustomUriResolver({}), isNotNull);
  }

  void test_resolve_unknown_uri() {
    UriResolver resolver =
        new CustomUriResolver({'custom:library': '/path/to/library.dart',});
    Source result =
        resolver.resolveAbsolute(parseUriWithException("custom:non_library"));
    expect(result, isNull);
  }

  void test_resolve_uri() {
    String path =
        FileUtilities2.createFile("/path/to/library.dart").getAbsolutePath();
    UriResolver resolver = new CustomUriResolver({'custom:library': path,});
    Source result =
        resolver.resolveAbsolute(parseUriWithException("custom:library"));
    expect(result, isNotNull);
    expect(result.fullName, path);
  }
}

@reflectiveTest
class DartUriResolverTest {
  void test_creation() {
    JavaFile sdkDirectory = DirectoryBasedDartSdk.defaultSdkDirectory;
    expect(sdkDirectory, isNotNull);
    DartSdk sdk = new DirectoryBasedDartSdk(sdkDirectory);
    expect(new DartUriResolver(sdk), isNotNull);
  }

  void test_isDartUri_null_scheme() {
    Uri uri = parseUriWithException("foo.dart");
    expect('', uri.scheme);
    expect(DartUriResolver.isDartUri(uri), isFalse);
  }

  void test_resolve_dart() {
    JavaFile sdkDirectory = DirectoryBasedDartSdk.defaultSdkDirectory;
    expect(sdkDirectory, isNotNull);
    DartSdk sdk = new DirectoryBasedDartSdk(sdkDirectory);
    UriResolver resolver = new DartUriResolver(sdk);
    Source result =
        resolver.resolveAbsolute(parseUriWithException("dart:core"));
    expect(result, isNotNull);
  }

  void test_resolve_dart_nonExistingLibrary() {
    JavaFile sdkDirectory = DirectoryBasedDartSdk.defaultSdkDirectory;
    expect(sdkDirectory, isNotNull);
    DartSdk sdk = new DirectoryBasedDartSdk(sdkDirectory);
    UriResolver resolver = new DartUriResolver(sdk);
    Source result = resolver.resolveAbsolute(parseUriWithException("dart:cor"));
    expect(result, isNull);
  }

  void test_resolve_nonDart() {
    JavaFile sdkDirectory = DirectoryBasedDartSdk.defaultSdkDirectory;
    expect(sdkDirectory, isNotNull);
    DartSdk sdk = new DirectoryBasedDartSdk(sdkDirectory);
    UriResolver resolver = new DartUriResolver(sdk);
    Source result = resolver
        .resolveAbsolute(parseUriWithException("package:some/file.dart"));
    expect(result, isNull);
  }
}

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

@reflectiveTest
class DirectoryBasedSourceContainerTest {
  void test_contains() {
    JavaFile dir = FileUtilities2.createFile("/does/not/exist");
    JavaFile file1 = FileUtilities2.createFile("/does/not/exist/some.dart");
    JavaFile file2 =
        FileUtilities2.createFile("/does/not/exist/folder/some2.dart");
    JavaFile file3 = FileUtilities2.createFile("/does/not/exist3/some3.dart");
    FileBasedSource source1 = new FileBasedSource(file1);
    FileBasedSource source2 = new FileBasedSource(file2);
    FileBasedSource source3 = new FileBasedSource(file3);
    DirectoryBasedSourceContainer container =
        new DirectoryBasedSourceContainer.con1(dir);
    expect(container.contains(source1), isTrue);
    expect(container.contains(source2), isTrue);
    expect(container.contains(source3), isFalse);
  }
}

@reflectiveTest
class ElementBuilderTest extends ParserTestCase {
  CompilationUnitElement compilationUnitElement;
  CompilationUnit compilationUnit;

  /**
   * Parse the given [code], pass it through [ElementBuilder], and return the
   * resulting [ElementHolder].
   */
  ElementHolder buildElementsForText(String code) {
    TestLogger logger = new TestLogger();
    AnalysisEngine.instance.logger = logger;
    try {
      compilationUnit = ParserTestCase.parseCompilationUnit(code);
      ElementHolder holder = new ElementHolder();
      ElementBuilder builder =
          new ElementBuilder(holder, compilationUnitElement);
      compilationUnit.accept(builder);
      return holder;
    } finally {
      expect(logger.log, hasLength(0));
      AnalysisEngine.instance.logger = Logger.NULL;
    }
  }

  /**
   * Verify that the given [metadata] has exactly one annotation, and that its
   * [ElementAnnotationImpl] is unresolved.
   */
  void checkAnnotation(NodeList<Annotation> metadata) {
    expect(metadata, hasLength(1));
    expect(metadata[0], new isInstanceOf<AnnotationImpl>());
    AnnotationImpl annotation = metadata[0];
    expect(annotation.elementAnnotation,
        new isInstanceOf<ElementAnnotationImpl>());
    ElementAnnotationImpl elementAnnotation = annotation.elementAnnotation;
    expect(elementAnnotation.element, isNull); // Not yet resolved
    expect(elementAnnotation.compilationUnit, isNotNull);
    expect(elementAnnotation.compilationUnit, compilationUnitElement);
  }

  /**
   * Verify that the given [element] has exactly one annotation, and that its
   * [ElementAnnotationImpl] is unresolved.
   */
  void checkMetadata(Element element) {
    expect(element.metadata, hasLength(1));
    expect(element.metadata[0], new isInstanceOf<ElementAnnotationImpl>());
    ElementAnnotationImpl elementAnnotation = element.metadata[0];
    expect(elementAnnotation.element, isNull); // Not yet resolved
    expect(elementAnnotation.compilationUnit, isNotNull);
    expect(elementAnnotation.compilationUnit, compilationUnitElement);
  }

  void fail_visitMethodDeclaration_setter_duplicate() {
    // https://github.com/dart-lang/sdk/issues/25601
    String code = r'''
class C {
  set zzz(x) {}
  set zzz(y) {}
}
''';
    ClassElement classElement = buildElementsForText(code).types[0];
    for (PropertyAccessorElement accessor in classElement.accessors) {
      expect(accessor.variable.setter, same(accessor));
    }
  }

  @override
  void setUp() {
    super.setUp();
    compilationUnitElement = new CompilationUnitElementImpl('test.dart');
  }

  void test_metadata_fieldDeclaration() {
    List<FieldElement> fields =
        buildElementsForText('class C { @a int x, y; }').types[0].fields;
    checkMetadata(fields[0]);
    checkMetadata(fields[1]);
    expect(fields[0].metadata, same(fields[1].metadata));
  }

  void test_metadata_localVariableDeclaration() {
    List<LocalVariableElement> localVariables =
        buildElementsForText('f() { @a int x, y; }')
            .functions[0]
            .localVariables;
    checkMetadata(localVariables[0]);
    checkMetadata(localVariables[1]);
    expect(localVariables[0].metadata, same(localVariables[1].metadata));
  }

  void test_metadata_topLevelVariableDeclaration() {
    List<TopLevelVariableElement> topLevelVariables =
        buildElementsForText('@a int x, y;').topLevelVariables;
    checkMetadata(topLevelVariables[0]);
    checkMetadata(topLevelVariables[1]);
    expect(topLevelVariables[0].metadata, same(topLevelVariables[1].metadata));
  }

  void test_metadata_visitClassDeclaration() {
    ClassElement classElement = buildElementsForText('@a class C {}').types[0];
    checkMetadata(classElement);
  }

  void test_metadata_visitClassTypeAlias() {
    ClassElement classElement =
        buildElementsForText('@a class C = D with E;').types[0];
    checkMetadata(classElement);
  }

  void test_metadata_visitConstructorDeclaration() {
    ConstructorElement constructorElement =
        buildElementsForText('class C { @a C(); }').types[0].constructors[0];
    checkMetadata(constructorElement);
  }

  void test_metadata_visitDeclaredIdentifier() {
    LocalVariableElement localVariableElement =
        buildElementsForText('f() { for (@a var x in y) {} }')
            .functions[0]
            .localVariables[0];
    checkMetadata(localVariableElement);
  }

  void test_metadata_visitDefaultFormalParameter_fieldFormalParameter() {
    ParameterElement parameterElement =
        buildElementsForText('class C { var x; C([@a this.x = null]); }')
            .types[0]
            .constructors[0]
            .parameters[0];
    checkMetadata(parameterElement);
  }

  void
      test_metadata_visitDefaultFormalParameter_functionTypedFormalParameter() {
    ParameterElement parameterElement =
        buildElementsForText('f([@a g() = null]) {}').functions[0].parameters[
            0];
    checkMetadata(parameterElement);
  }

  void test_metadata_visitDefaultFormalParameter_simpleFormalParameter() {
    ParameterElement parameterElement =
        buildElementsForText('f([@a gx = null]) {}').functions[0].parameters[0];
    checkMetadata(parameterElement);
  }

  void test_metadata_visitEnumDeclaration() {
    ClassElement classElement =
        buildElementsForText('@a enum E { v }').enums[0];
    checkMetadata(classElement);
  }

  void test_metadata_visitExportDirective() {
    buildElementsForText('@a export "foo.dart";');
    expect(compilationUnit.directives[0], new isInstanceOf<ExportDirective>());
    ExportDirective exportDirective = compilationUnit.directives[0];
    checkAnnotation(exportDirective.metadata);
  }

  void test_metadata_visitFieldFormalParameter() {
    ParameterElement parameterElement =
        buildElementsForText('class C { var x; C(@a this.x); }')
            .types[0]
            .constructors[0]
            .parameters[0];
    checkMetadata(parameterElement);
  }

  void test_metadata_visitFunctionDeclaration_function() {
    FunctionElement functionElement =
        buildElementsForText('@a f() {}').functions[0];
    checkMetadata(functionElement);
  }

  void test_metadata_visitFunctionDeclaration_getter() {
    PropertyAccessorElement propertyAccessorElement =
        buildElementsForText('@a get f => null;').accessors[0];
    checkMetadata(propertyAccessorElement);
  }

  void test_metadata_visitFunctionDeclaration_setter() {
    PropertyAccessorElement propertyAccessorElement =
        buildElementsForText('@a set f(value) {}').accessors[0];
    checkMetadata(propertyAccessorElement);
  }

  void test_metadata_visitFunctionTypeAlias() {
    FunctionTypeAliasElement functionTypeAliasElement =
        buildElementsForText('@a typedef F();').typeAliases[0];
    checkMetadata(functionTypeAliasElement);
  }

  void test_metadata_visitFunctionTypedFormalParameter() {
    ParameterElement parameterElement =
        buildElementsForText('f(@a g()) {}').functions[0].parameters[0];
    checkMetadata(parameterElement);
  }

  void test_metadata_visitImportDirective() {
    buildElementsForText('@a import "foo.dart";');
    expect(compilationUnit.directives[0], new isInstanceOf<ImportDirective>());
    ImportDirective importDirective = compilationUnit.directives[0];
    checkAnnotation(importDirective.metadata);
  }

  void test_metadata_visitLibraryDirective() {
    buildElementsForText('@a library L;');
    expect(compilationUnit.directives[0], new isInstanceOf<LibraryDirective>());
    LibraryDirective libraryDirective = compilationUnit.directives[0];
    checkAnnotation(libraryDirective.metadata);
  }

  void test_metadata_visitMethodDeclaration_getter() {
    PropertyAccessorElement propertyAccessorElement =
        buildElementsForText('class C { @a get m => null; }')
            .types[0]
            .accessors[0];
    checkMetadata(propertyAccessorElement);
  }

  void test_metadata_visitMethodDeclaration_method() {
    MethodElement methodElement =
        buildElementsForText('class C { @a m() {} }').types[0].methods[0];
    checkMetadata(methodElement);
  }

  void test_metadata_visitMethodDeclaration_setter() {
    PropertyAccessorElement propertyAccessorElement =
        buildElementsForText('class C { @a set f(value) {} }')
            .types[0]
            .accessors[0];
    checkMetadata(propertyAccessorElement);
  }

  void test_metadata_visitPartDirective() {
    buildElementsForText('@a part "foo.dart";');
    expect(compilationUnit.directives[0], new isInstanceOf<PartDirective>());
    PartDirective partDirective = compilationUnit.directives[0];
    checkAnnotation(partDirective.metadata);
  }

  void test_metadata_visitPartOfDirective() {
    // We don't build ElementAnnotation objects for `part of` directives, since
    // analyzer ignores them in favor of annotations on the library directive.
    buildElementsForText('@a part of L;');
    expect(compilationUnit.directives[0], new isInstanceOf<PartOfDirective>());
    PartOfDirective partOfDirective = compilationUnit.directives[0];
    expect(partOfDirective.metadata, hasLength(1));
    expect(partOfDirective.metadata[0].elementAnnotation, isNull);
  }

  void test_metadata_visitSimpleFormalParameter() {
    ParameterElement parameterElement =
        buildElementsForText('f(@a x) {}').functions[0].parameters[0];
    checkMetadata(parameterElement);
  }

  void test_metadata_visitTypeParameter() {
    TypeParameterElement typeParameterElement =
        buildElementsForText('class C<@a T> {}').types[0].typeParameters[0];
    checkMetadata(typeParameterElement);
  }

  void test_visitCatchClause() {
    // } catch (e, s) {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String exceptionParameterName = "e";
    String stackParameterName = "s";
    CatchClause clause =
        AstFactory.catchClause2(exceptionParameterName, stackParameterName);
    _setNodeSourceRange(clause, 100, 110);
    clause.accept(builder);

    List<LocalVariableElement> variables = holder.localVariables;
    expect(variables, hasLength(2));

    LocalVariableElement exceptionVariable = variables[0];
    expect(exceptionVariable, isNotNull);
    expect(exceptionVariable.name, exceptionParameterName);
    expect(exceptionVariable.hasImplicitType, isTrue);
    expect(exceptionVariable.isSynthetic, isFalse);
    expect(exceptionVariable.isConst, isFalse);
    expect(exceptionVariable.isFinal, isFalse);
    expect(exceptionVariable.initializer, isNull);
    _assertVisibleRange(exceptionVariable, 100, 110);

    LocalVariableElement stackVariable = variables[1];
    expect(stackVariable, isNotNull);
    expect(stackVariable.name, stackParameterName);
    expect(stackVariable.isSynthetic, isFalse);
    expect(stackVariable.isConst, isFalse);
    expect(stackVariable.isFinal, isFalse);
    expect(stackVariable.initializer, isNull);
    _assertVisibleRange(stackVariable, 100, 110);
  }

  void test_visitCatchClause_withType() {
    // } on E catch (e) {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String exceptionParameterName = "e";
    CatchClause clause = AstFactory.catchClause4(
        AstFactory.typeName4('E'), exceptionParameterName);
    clause.accept(builder);

    List<LocalVariableElement> variables = holder.localVariables;
    expect(variables, hasLength(1));
    VariableElement exceptionVariable = variables[0];
    expect(exceptionVariable, isNotNull);
    expect(exceptionVariable.name, exceptionParameterName);
    expect(exceptionVariable.hasImplicitType, isFalse);
  }

  void test_visitClassDeclaration_abstract() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String className = "C";
    ClassDeclaration classDeclaration = AstFactory.classDeclaration(
        Keyword.ABSTRACT, className, null, null, null, null);
    classDeclaration.accept(builder);
    List<ClassElement> types = holder.types;
    expect(types, hasLength(1));
    ClassElement type = types[0];
    expect(type, isNotNull);
    expect(type.name, className);
    List<TypeParameterElement> typeParameters = type.typeParameters;
    expect(typeParameters, hasLength(0));
    expect(type.isAbstract, isTrue);
    expect(type.isMixinApplication, isFalse);
    expect(type.isSynthetic, isFalse);
  }

  void test_visitClassDeclaration_invalidFunctionInAnnotation_class() {
    // https://github.com/dart-lang/sdk/issues/25696
    String code = r'''
class A {
  const A({f});
}

@A(f: () {})
class C {}
''';
    buildElementsForText(code);
  }

  void test_visitClassDeclaration_invalidFunctionInAnnotation_method() {
    String code = r'''
class A {
  const A({f});
}

class C {
  @A(f: () {})
  void m() {}
}
''';
    ElementHolder holder = buildElementsForText(code);
    ClassElement elementC = holder.types[1];
    expect(elementC, isNotNull);
    MethodElement methodM = elementC.methods[0];
    expect(methodM, isNotNull);
    expect(methodM.functions, isEmpty);
  }

  void test_visitClassDeclaration_minimal() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String className = "C";
    ClassDeclaration classDeclaration =
        AstFactory.classDeclaration(null, className, null, null, null, null);
    classDeclaration.documentationComment = AstFactory.documentationComment(
        [TokenFactory.tokenFromString('/// aaa')..offset = 50], []);
    classDeclaration.endToken.offset = 80;
    classDeclaration.accept(builder);
    List<ClassElement> types = holder.types;
    expect(types, hasLength(1));
    ClassElement type = types[0];
    expect(type, isNotNull);
    expect(type.name, className);
    List<TypeParameterElement> typeParameters = type.typeParameters;
    expect(typeParameters, hasLength(0));
    expect(type.isAbstract, isFalse);
    expect(type.isMixinApplication, isFalse);
    expect(type.isSynthetic, isFalse);
    expect(type.documentationComment, '/// aaa');
    _assertHasDocRange(type, 50, 7);
    _assertHasCodeRange(type, 50, 31);
  }

  void test_visitClassDeclaration_parameterized() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String className = "C";
    String firstVariableName = "E";
    String secondVariableName = "F";
    ClassDeclaration classDeclaration = AstFactory.classDeclaration(
        null,
        className,
        AstFactory.typeParameterList([firstVariableName, secondVariableName]),
        null,
        null,
        null);
    classDeclaration.accept(builder);
    List<ClassElement> types = holder.types;
    expect(types, hasLength(1));
    ClassElement type = types[0];
    expect(type, isNotNull);
    expect(type.name, className);
    List<TypeParameterElement> typeParameters = type.typeParameters;
    expect(typeParameters, hasLength(2));
    expect(typeParameters[0].name, firstVariableName);
    expect(typeParameters[1].name, secondVariableName);
    expect(type.isAbstract, isFalse);
    expect(type.isMixinApplication, isFalse);
    expect(type.isSynthetic, isFalse);
  }

  void test_visitClassDeclaration_withMembers() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String className = "C";
    String typeParameterName = "E";
    String fieldName = "f";
    String methodName = "m";
    ClassDeclaration classDeclaration = AstFactory.classDeclaration(
        null,
        className,
        AstFactory.typeParameterList([typeParameterName]),
        null,
        null,
        null, [
      AstFactory.fieldDeclaration2(
          false, null, [AstFactory.variableDeclaration(fieldName)]),
      AstFactory.methodDeclaration2(
          null,
          null,
          null,
          null,
          AstFactory.identifier3(methodName),
          AstFactory.formalParameterList(),
          AstFactory.blockFunctionBody2())
    ]);
    classDeclaration.accept(builder);
    List<ClassElement> types = holder.types;
    expect(types, hasLength(1));
    ClassElement type = types[0];
    expect(type, isNotNull);
    expect(type.name, className);
    expect(type.isAbstract, isFalse);
    expect(type.isMixinApplication, isFalse);
    expect(type.isSynthetic, isFalse);
    List<TypeParameterElement> typeParameters = type.typeParameters;
    expect(typeParameters, hasLength(1));
    TypeParameterElement typeParameter = typeParameters[0];
    expect(typeParameter, isNotNull);
    expect(typeParameter.name, typeParameterName);
    List<FieldElement> fields = type.fields;
    expect(fields, hasLength(1));
    FieldElement field = fields[0];
    expect(field, isNotNull);
    expect(field.name, fieldName);
    List<MethodElement> methods = type.methods;
    expect(methods, hasLength(1));
    MethodElement method = methods[0];
    expect(method, isNotNull);
    expect(method.name, methodName);
  }

  void test_visitClassTypeAlias() {
    // class B {}
    // class M {}
    // class C = B with M
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    ClassElementImpl classB = ElementFactory.classElement2('B', []);
    ConstructorElementImpl constructorB =
        ElementFactory.constructorElement2(classB, '', []);
    constructorB.setModifier(Modifier.SYNTHETIC, true);
    classB.constructors = [constructorB];
    ClassElement classM = ElementFactory.classElement2('M', []);
    WithClause withClause =
        AstFactory.withClause([AstFactory.typeName(classM, [])]);
    ClassTypeAlias alias = AstFactory.classTypeAlias(
        'C', null, null, AstFactory.typeName(classB, []), withClause, null);
    alias.accept(builder);
    List<ClassElement> types = holder.types;
    expect(types, hasLength(1));
    ClassElement type = types[0];
    expect(alias.element, same(type));
    expect(type.name, equals('C'));
    expect(type.isAbstract, isFalse);
    expect(type.isMixinApplication, isTrue);
    expect(type.isSynthetic, isFalse);
    expect(type.typeParameters, isEmpty);
    expect(type.fields, isEmpty);
    expect(type.methods, isEmpty);
  }

  void test_visitClassTypeAlias_abstract() {
    // class B {}
    // class M {}
    // abstract class C = B with M
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    ClassElementImpl classB = ElementFactory.classElement2('B', []);
    ConstructorElementImpl constructorB =
        ElementFactory.constructorElement2(classB, '', []);
    constructorB.setModifier(Modifier.SYNTHETIC, true);
    classB.constructors = [constructorB];
    ClassElement classM = ElementFactory.classElement2('M', []);
    WithClause withClause =
        AstFactory.withClause([AstFactory.typeName(classM, [])]);
    ClassTypeAlias classCAst = AstFactory.classTypeAlias('C', null,
        Keyword.ABSTRACT, AstFactory.typeName(classB, []), withClause, null);
    classCAst.accept(builder);
    List<ClassElement> types = holder.types;
    expect(types, hasLength(1));
    ClassElement type = types[0];
    expect(type.isAbstract, isTrue);
    expect(type.isMixinApplication, isTrue);
  }

  void test_visitClassTypeAlias_typeParams() {
    // class B {}
    // class M {}
    // class C<T> = B with M
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    ClassElementImpl classB = ElementFactory.classElement2('B', []);
    ConstructorElementImpl constructorB =
        ElementFactory.constructorElement2(classB, '', []);
    constructorB.setModifier(Modifier.SYNTHETIC, true);
    classB.constructors = [constructorB];
    ClassElementImpl classM = ElementFactory.classElement2('M', []);
    WithClause withClause =
        AstFactory.withClause([AstFactory.typeName(classM, [])]);
    ClassTypeAlias classCAst = AstFactory.classTypeAlias(
        'C',
        AstFactory.typeParameterList(['T']),
        null,
        AstFactory.typeName(classB, []),
        withClause,
        null);
    classCAst.accept(builder);
    List<ClassElement> types = holder.types;
    expect(types, hasLength(1));
    ClassElement type = types[0];
    expect(type.typeParameters, hasLength(1));
    expect(type.typeParameters[0].name, equals('T'));
  }

  void test_visitCompilationUnit_codeRange() {
    TopLevelVariableDeclaration topLevelVariableDeclaration = AstFactory
        .topLevelVariableDeclaration(null, AstFactory.typeName4('int'),
            [AstFactory.variableDeclaration('V')]);
    CompilationUnit unit = new CompilationUnit(
        topLevelVariableDeclaration.beginToken,
        null,
        [],
        [topLevelVariableDeclaration],
        topLevelVariableDeclaration.endToken);
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    unit.beginToken.offset = 10;
    unit.endToken.offset = 40;
    unit.accept(builder);

    CompilationUnitElement element = builder.compilationUnitElement;
    _assertHasCodeRange(element, 0, 41);
  }

  void test_visitConstructorDeclaration_external() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String className = "A";
    ConstructorDeclaration constructorDeclaration =
        AstFactory.constructorDeclaration2(
            null,
            null,
            AstFactory.identifier3(className),
            null,
            AstFactory.formalParameterList(),
            null,
            AstFactory.blockFunctionBody2());
    constructorDeclaration.externalKeyword =
        TokenFactory.tokenFromKeyword(Keyword.EXTERNAL);
    constructorDeclaration.accept(builder);
    List<ConstructorElement> constructors = holder.constructors;
    expect(constructors, hasLength(1));
    ConstructorElement constructor = constructors[0];
    expect(constructor, isNotNull);
    expect(constructor.isExternal, isTrue);
    expect(constructor.isFactory, isFalse);
    expect(constructor.name, "");
    expect(constructor.functions, hasLength(0));
    expect(constructor.labels, hasLength(0));
    expect(constructor.localVariables, hasLength(0));
    expect(constructor.parameters, hasLength(0));
  }

  void test_visitConstructorDeclaration_factory() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String className = "A";
    ConstructorDeclaration constructorDeclaration =
        AstFactory.constructorDeclaration2(
            null,
            Keyword.FACTORY,
            AstFactory.identifier3(className),
            null,
            AstFactory.formalParameterList(),
            null,
            AstFactory.blockFunctionBody2());
    constructorDeclaration.accept(builder);
    List<ConstructorElement> constructors = holder.constructors;
    expect(constructors, hasLength(1));
    ConstructorElement constructor = constructors[0];
    expect(constructor, isNotNull);
    expect(constructor.isExternal, isFalse);
    expect(constructor.isFactory, isTrue);
    expect(constructor.name, "");
    expect(constructor.functions, hasLength(0));
    expect(constructor.labels, hasLength(0));
    expect(constructor.localVariables, hasLength(0));
    expect(constructor.parameters, hasLength(0));
  }

  void test_visitConstructorDeclaration_minimal() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String className = "A";
    ConstructorDeclaration constructorDeclaration =
        AstFactory.constructorDeclaration2(
            null,
            null,
            AstFactory.identifier3(className),
            null,
            AstFactory.formalParameterList(),
            null,
            AstFactory.blockFunctionBody2());
    constructorDeclaration.documentationComment = AstFactory
        .documentationComment(
            [TokenFactory.tokenFromString('/// aaa')..offset = 50], []);
    constructorDeclaration.endToken.offset = 80;
    constructorDeclaration.accept(builder);

    List<ConstructorElement> constructors = holder.constructors;
    expect(constructors, hasLength(1));
    ConstructorElement constructor = constructors[0];
    expect(constructor, isNotNull);
    _assertHasCodeRange(constructor, 50, 31);
    expect(constructor.documentationComment, '/// aaa');
    _assertHasDocRange(constructor, 50, 7);
    expect(constructor.isExternal, isFalse);
    expect(constructor.isFactory, isFalse);
    expect(constructor.name, "");
    expect(constructor.functions, hasLength(0));
    expect(constructor.labels, hasLength(0));
    expect(constructor.localVariables, hasLength(0));
    expect(constructor.parameters, hasLength(0));
  }

  void test_visitConstructorDeclaration_named() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String className = "A";
    String constructorName = "c";
    ConstructorDeclaration constructorDeclaration =
        AstFactory.constructorDeclaration2(
            null,
            null,
            AstFactory.identifier3(className),
            constructorName,
            AstFactory.formalParameterList(),
            null,
            AstFactory.blockFunctionBody2());
    constructorDeclaration.accept(builder);
    List<ConstructorElement> constructors = holder.constructors;
    expect(constructors, hasLength(1));
    ConstructorElement constructor = constructors[0];
    expect(constructor, isNotNull);
    expect(constructor.isExternal, isFalse);
    expect(constructor.isFactory, isFalse);
    expect(constructor.name, constructorName);
    expect(constructor.functions, hasLength(0));
    expect(constructor.labels, hasLength(0));
    expect(constructor.localVariables, hasLength(0));
    expect(constructor.parameters, hasLength(0));
    expect(constructorDeclaration.name.staticElement, same(constructor));
    expect(constructorDeclaration.element, same(constructor));
  }

  void test_visitConstructorDeclaration_unnamed() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String className = "A";
    ConstructorDeclaration constructorDeclaration =
        AstFactory.constructorDeclaration2(
            null,
            null,
            AstFactory.identifier3(className),
            null,
            AstFactory.formalParameterList(),
            null,
            AstFactory.blockFunctionBody2());
    constructorDeclaration.accept(builder);
    List<ConstructorElement> constructors = holder.constructors;
    expect(constructors, hasLength(1));
    ConstructorElement constructor = constructors[0];
    expect(constructor, isNotNull);
    expect(constructor.isExternal, isFalse);
    expect(constructor.isFactory, isFalse);
    expect(constructor.name, "");
    expect(constructor.functions, hasLength(0));
    expect(constructor.labels, hasLength(0));
    expect(constructor.localVariables, hasLength(0));
    expect(constructor.parameters, hasLength(0));
    expect(constructorDeclaration.element, same(constructor));
  }

  void test_visitDeclaredIdentifier_noType() {
    // var i
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    var variableName = 'i';
    DeclaredIdentifier identifier =
        AstFactory.declaredIdentifier3(variableName);
    AstFactory.forEachStatement(
        identifier, AstFactory.nullLiteral(), AstFactory.emptyStatement());
    identifier.beginToken.offset = 50;
    identifier.endToken.offset = 80;
    identifier.accept(builder);

    List<LocalVariableElement> variables = holder.localVariables;
    expect(variables, hasLength(1));
    LocalVariableElement variable = variables[0];
    _assertHasCodeRange(variable, 50, 31);
    expect(variable, isNotNull);
    expect(variable.hasImplicitType, isTrue);
    expect(variable.isConst, isFalse);
    expect(variable.isDeprecated, isFalse);
    expect(variable.isFinal, isFalse);
    expect(variable.isOverride, isFalse);
    expect(variable.isPrivate, isFalse);
    expect(variable.isPublic, isTrue);
    expect(variable.isSynthetic, isFalse);
    expect(variable.name, variableName);
  }

  void test_visitDeclaredIdentifier_type() {
    // E i
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    var variableName = 'i';
    DeclaredIdentifier identifier =
        AstFactory.declaredIdentifier4(AstFactory.typeName4('E'), variableName);
    AstFactory.forEachStatement(
        identifier, AstFactory.nullLiteral(), AstFactory.emptyStatement());
    identifier.beginToken.offset = 50;
    identifier.endToken.offset = 80;
    identifier.accept(builder);

    List<LocalVariableElement> variables = holder.localVariables;
    expect(variables, hasLength(1));
    LocalVariableElement variable = variables[0];
    expect(variable, isNotNull);
    _assertHasCodeRange(variable, 50, 31);
    expect(variable.hasImplicitType, isFalse);
    expect(variable.isConst, isFalse);
    expect(variable.isDeprecated, isFalse);
    expect(variable.isFinal, isFalse);
    expect(variable.isOverride, isFalse);
    expect(variable.isPrivate, isFalse);
    expect(variable.isPublic, isTrue);
    expect(variable.isSynthetic, isFalse);
    expect(variable.name, variableName);
  }

  void test_visitDefaultFormalParameter_noType() {
    // p = 0
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String parameterName = 'p';
    DefaultFormalParameter formalParameter =
        AstFactory.positionalFormalParameter(
            AstFactory.simpleFormalParameter3(parameterName),
            AstFactory.integer(0));
    formalParameter.beginToken.offset = 50;
    formalParameter.endToken.offset = 80;
    formalParameter.accept(builder);

    List<ParameterElement> parameters = holder.parameters;
    expect(parameters, hasLength(1));
    ParameterElement parameter = parameters[0];
    _assertHasCodeRange(parameter, 50, 31);
    expect(parameter.hasImplicitType, isTrue);
    expect(parameter.initializer, isNotNull);
    expect(parameter.initializer.type, isNotNull);
    expect(parameter.initializer.hasImplicitReturnType, isTrue);
    expect(parameter.isConst, isFalse);
    expect(parameter.isDeprecated, isFalse);
    expect(parameter.isFinal, isFalse);
    expect(parameter.isInitializingFormal, isFalse);
    expect(parameter.isOverride, isFalse);
    expect(parameter.isPrivate, isFalse);
    expect(parameter.isPublic, isTrue);
    expect(parameter.isSynthetic, isFalse);
    expect(parameter.name, parameterName);
  }

  void test_visitDefaultFormalParameter_type() {
    // E p = 0
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String parameterName = 'p';
    DefaultFormalParameter formalParameter = AstFactory.namedFormalParameter(
        AstFactory.simpleFormalParameter4(
            AstFactory.typeName4('E'), parameterName),
        AstFactory.integer(0));
    formalParameter.accept(builder);

    List<ParameterElement> parameters = holder.parameters;
    expect(parameters, hasLength(1));
    ParameterElement parameter = parameters[0];
    expect(parameter.hasImplicitType, isFalse);
    expect(parameter.initializer, isNotNull);
    expect(parameter.initializer.type, isNotNull);
    expect(parameter.initializer.hasImplicitReturnType, isTrue);
    expect(parameter.isConst, isFalse);
    expect(parameter.isDeprecated, isFalse);
    expect(parameter.isFinal, isFalse);
    expect(parameter.isInitializingFormal, isFalse);
    expect(parameter.isOverride, isFalse);
    expect(parameter.isPrivate, isFalse);
    expect(parameter.isPublic, isTrue);
    expect(parameter.isSynthetic, isFalse);
    expect(parameter.name, parameterName);
  }

  void test_visitEnumDeclaration() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String enumName = "E";
    EnumDeclaration enumDeclaration =
        AstFactory.enumDeclaration2(enumName, ["ONE"]);
    enumDeclaration.documentationComment = AstFactory.documentationComment(
        [TokenFactory.tokenFromString('/// aaa')..offset = 50], []);
    enumDeclaration.endToken.offset = 80;
    enumDeclaration.accept(builder);
    List<ClassElement> enums = holder.enums;
    expect(enums, hasLength(1));
    ClassElement enumElement = enums[0];
    expect(enumElement, isNotNull);
    _assertHasCodeRange(enumElement, 50, 31);
    expect(enumElement.documentationComment, '/// aaa');
    _assertHasDocRange(enumElement, 50, 7);
    expect(enumElement.name, enumName);
  }

  void test_visitFieldDeclaration() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String firstFieldName = "x";
    String secondFieldName = "y";
    FieldDeclaration fieldDeclaration =
        AstFactory.fieldDeclaration2(false, null, [
      AstFactory.variableDeclaration(firstFieldName),
      AstFactory.variableDeclaration(secondFieldName)
    ]);
    fieldDeclaration.documentationComment = AstFactory.documentationComment(
        [TokenFactory.tokenFromString('/// aaa')..offset = 50], []);
    fieldDeclaration.endToken.offset = 110;
    fieldDeclaration.accept(builder);

    List<FieldElement> fields = holder.fields;
    expect(fields, hasLength(2));

    FieldElement firstField = fields[0];
    expect(firstField, isNotNull);
    _assertHasCodeRange(firstField, 50, 61);
    expect(firstField.documentationComment, '/// aaa');
    _assertHasDocRange(firstField, 50, 7);
    expect(firstField.name, firstFieldName);
    expect(firstField.initializer, isNull);
    expect(firstField.isConst, isFalse);
    expect(firstField.isFinal, isFalse);
    expect(firstField.isSynthetic, isFalse);

    FieldElement secondField = fields[1];
    expect(secondField, isNotNull);
    _assertHasCodeRange(secondField, 50, 61);
    expect(secondField.documentationComment, '/// aaa');
    _assertHasDocRange(secondField, 50, 7);
    expect(secondField.name, secondFieldName);
    expect(secondField.initializer, isNull);
    expect(secondField.isConst, isFalse);
    expect(secondField.isFinal, isFalse);
    expect(secondField.isSynthetic, isFalse);
  }

  void test_visitFieldFormalParameter() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String parameterName = "p";
    FieldFormalParameter formalParameter =
        AstFactory.fieldFormalParameter(null, null, parameterName);
    formalParameter.beginToken.offset = 50;
    formalParameter.endToken.offset = 80;
    formalParameter.accept(builder);
    List<ParameterElement> parameters = holder.parameters;
    expect(parameters, hasLength(1));
    ParameterElement parameter = parameters[0];
    expect(parameter, isNotNull);
    _assertHasCodeRange(parameter, 50, 31);
    expect(parameter.name, parameterName);
    expect(parameter.initializer, isNull);
    expect(parameter.isConst, isFalse);
    expect(parameter.isFinal, isFalse);
    expect(parameter.isSynthetic, isFalse);
    expect(parameter.parameterKind, ParameterKind.REQUIRED);
    expect(parameter.parameters, hasLength(0));
  }

  void test_visitFieldFormalParameter_functionTyped() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String parameterName = "p";
    FieldFormalParameter formalParameter = AstFactory.fieldFormalParameter(
        null,
        null,
        parameterName,
        AstFactory
            .formalParameterList([AstFactory.simpleFormalParameter3("a")]));
    formalParameter.accept(builder);
    List<ParameterElement> parameters = holder.parameters;
    expect(parameters, hasLength(1));
    ParameterElement parameter = parameters[0];
    expect(parameter, isNotNull);
    expect(parameter.name, parameterName);
    expect(parameter.initializer, isNull);
    expect(parameter.isConst, isFalse);
    expect(parameter.isFinal, isFalse);
    expect(parameter.isSynthetic, isFalse);
    expect(parameter.parameterKind, ParameterKind.REQUIRED);
    expect(parameter.parameters, hasLength(1));
  }

  void test_visitFormalParameterList() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String firstParameterName = "a";
    String secondParameterName = "b";
    FormalParameterList parameterList = AstFactory.formalParameterList([
      AstFactory.simpleFormalParameter3(firstParameterName),
      AstFactory.simpleFormalParameter3(secondParameterName)
    ]);
    parameterList.accept(builder);
    List<ParameterElement> parameters = holder.parameters;
    expect(parameters, hasLength(2));
    expect(parameters[0].name, firstParameterName);
    expect(parameters[1].name, secondParameterName);
  }

  void test_visitFunctionDeclaration_external() {
    // external f();
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String functionName = "f";
    FunctionDeclaration declaration = AstFactory.functionDeclaration(
        null,
        null,
        functionName,
        AstFactory.functionExpression2(
            AstFactory.formalParameterList(), AstFactory.emptyFunctionBody()));
    declaration.externalKeyword =
        TokenFactory.tokenFromKeyword(Keyword.EXTERNAL);
    declaration.accept(builder);

    List<FunctionElement> functions = holder.functions;
    expect(functions, hasLength(1));
    FunctionElement function = functions[0];
    expect(function, isNotNull);
    expect(function.name, functionName);
    expect(declaration.element, same(function));
    expect(declaration.functionExpression.element, same(function));
    expect(function.hasImplicitReturnType, isTrue);
    expect(function.isExternal, isTrue);
    expect(function.isSynthetic, isFalse);
    expect(function.typeParameters, hasLength(0));
  }

  void test_visitFunctionDeclaration_getter() {
    // get f() {}
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String functionName = "f";
    FunctionDeclaration declaration = AstFactory.functionDeclaration(
        null,
        Keyword.GET,
        functionName,
        AstFactory.functionExpression2(
            AstFactory.formalParameterList(), AstFactory.blockFunctionBody2()));
    declaration.documentationComment = AstFactory.documentationComment(
        [TokenFactory.tokenFromString('/// aaa')..offset = 50], []);
    declaration.endToken.offset = 80;
    declaration.accept(builder);

    List<PropertyAccessorElement> accessors = holder.accessors;
    expect(accessors, hasLength(1));
    PropertyAccessorElement accessor = accessors[0];
    expect(accessor, isNotNull);
    _assertHasCodeRange(accessor, 50, 31);
    expect(accessor.documentationComment, '/// aaa');
    _assertHasDocRange(accessor, 50, 7);
    expect(accessor.name, functionName);
    expect(declaration.element, same(accessor));
    expect(declaration.functionExpression.element, same(accessor));
    expect(accessor.hasImplicitReturnType, isTrue);
    expect(accessor.isGetter, isTrue);
    expect(accessor.isExternal, isFalse);
    expect(accessor.isSetter, isFalse);
    expect(accessor.isSynthetic, isFalse);
    expect(accessor.typeParameters, hasLength(0));
    PropertyInducingElement variable = accessor.variable;
    EngineTestCase.assertInstanceOf((obj) => obj is TopLevelVariableElement,
        TopLevelVariableElement, variable);
    expect(variable.isSynthetic, isTrue);
  }

  void test_visitFunctionDeclaration_plain() {
    // T f() {}
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String functionName = "f";
    FunctionDeclaration declaration = AstFactory.functionDeclaration(
        AstFactory.typeName4('T'),
        null,
        functionName,
        AstFactory.functionExpression2(
            AstFactory.formalParameterList(), AstFactory.blockFunctionBody2()));
    declaration.documentationComment = AstFactory.documentationComment(
        [TokenFactory.tokenFromString('/// aaa')..offset = 50], []);
    declaration.endToken.offset = 80;
    declaration.accept(builder);

    List<FunctionElement> functions = holder.functions;
    expect(functions, hasLength(1));
    FunctionElement function = functions[0];
    expect(function, isNotNull);
    _assertHasCodeRange(function, 50, 31);
    expect(function.documentationComment, '/// aaa');
    _assertHasDocRange(function, 50, 7);
    expect(function.hasImplicitReturnType, isFalse);
    expect(function.name, functionName);
    expect(declaration.element, same(function));
    expect(declaration.functionExpression.element, same(function));
    expect(function.isExternal, isFalse);
    expect(function.isSynthetic, isFalse);
    expect(function.typeParameters, hasLength(0));
  }

  void test_visitFunctionDeclaration_setter() {
    // set f() {}
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String functionName = "f";
    FunctionDeclaration declaration = AstFactory.functionDeclaration(
        null,
        Keyword.SET,
        functionName,
        AstFactory.functionExpression2(
            AstFactory.formalParameterList(), AstFactory.blockFunctionBody2()));
    declaration.documentationComment = AstFactory.documentationComment(
        [TokenFactory.tokenFromString('/// aaa')..offset = 50], []);
    declaration.endToken.offset = 80;
    declaration.accept(builder);

    List<PropertyAccessorElement> accessors = holder.accessors;
    expect(accessors, hasLength(1));
    PropertyAccessorElement accessor = accessors[0];
    expect(accessor, isNotNull);
    _assertHasCodeRange(accessor, 50, 31);
    expect(accessor.documentationComment, '/// aaa');
    _assertHasDocRange(accessor, 50, 7);
    expect(accessor.hasImplicitReturnType, isTrue);
    expect(accessor.name, "$functionName=");
    expect(declaration.element, same(accessor));
    expect(declaration.functionExpression.element, same(accessor));
    expect(accessor.isGetter, isFalse);
    expect(accessor.isExternal, isFalse);
    expect(accessor.isSetter, isTrue);
    expect(accessor.isSynthetic, isFalse);
    expect(accessor.typeParameters, hasLength(0));
    PropertyInducingElement variable = accessor.variable;
    EngineTestCase.assertInstanceOf((obj) => obj is TopLevelVariableElement,
        TopLevelVariableElement, variable);
    expect(variable.isSynthetic, isTrue);
  }

  void test_visitFunctionDeclaration_typeParameters() {
    // f<E>() {}
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String functionName = 'f';
    String typeParameterName = 'E';
    FunctionExpression expression = AstFactory.functionExpression3(
        AstFactory.typeParameterList([typeParameterName]),
        AstFactory.formalParameterList(),
        AstFactory.blockFunctionBody2());
    FunctionDeclaration declaration =
        AstFactory.functionDeclaration(null, null, functionName, expression);
    declaration.accept(builder);

    List<FunctionElement> functions = holder.functions;
    expect(functions, hasLength(1));
    FunctionElement function = functions[0];
    expect(function, isNotNull);
    expect(function.hasImplicitReturnType, isTrue);
    expect(function.name, functionName);
    expect(function.isExternal, isFalse);
    expect(function.isSynthetic, isFalse);
    expect(declaration.element, same(function));
    expect(expression.element, same(function));
    List<TypeParameterElement> typeParameters = function.typeParameters;
    expect(typeParameters, hasLength(1));
    TypeParameterElement typeParameter = typeParameters[0];
    expect(typeParameter, isNotNull);
    expect(typeParameter.name, typeParameterName);
  }

  void test_visitFunctionExpression() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    FunctionExpression expression = AstFactory.functionExpression2(
        AstFactory.formalParameterList(), AstFactory.blockFunctionBody2());
    expression.accept(builder);
    List<FunctionElement> functions = holder.functions;
    expect(functions, hasLength(1));
    FunctionElement function = functions[0];
    expect(function, isNotNull);
    expect(expression.element, same(function));
    expect(function.hasImplicitReturnType, isTrue);
    expect(function.isSynthetic, isFalse);
    expect(function.typeParameters, hasLength(0));
  }

  void test_visitFunctionTypeAlias() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String aliasName = "F";
    String parameterName = "E";
    FunctionTypeAlias aliasNode = AstFactory.typeAlias(
        null, aliasName, AstFactory.typeParameterList([parameterName]), null);
    aliasNode.documentationComment = AstFactory.documentationComment(
        [TokenFactory.tokenFromString('/// aaa')..offset = 50], []);
    aliasNode.endToken.offset = 80;
    aliasNode.accept(builder);

    List<FunctionTypeAliasElement> aliases = holder.typeAliases;
    expect(aliases, hasLength(1));
    FunctionTypeAliasElement alias = aliases[0];
    expect(alias, isNotNull);
    _assertHasCodeRange(alias, 50, 31);
    expect(alias.documentationComment, '/// aaa');
    _assertHasDocRange(alias, 50, 7);
    expect(alias.name, aliasName);
    expect(alias.parameters, hasLength(0));
    List<TypeParameterElement> typeParameters = alias.typeParameters;
    expect(typeParameters, hasLength(1));
    TypeParameterElement typeParameter = typeParameters[0];
    expect(typeParameter, isNotNull);
    expect(typeParameter.name, parameterName);
  }

  void test_visitFunctionTypedFormalParameter() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String parameterName = "p";
    FunctionTypedFormalParameter formalParameter =
        AstFactory.functionTypedFormalParameter(null, parameterName);
    _useParameterInMethod(formalParameter, 100, 110);
    formalParameter.accept(builder);
    List<ParameterElement> parameters = holder.parameters;
    expect(parameters, hasLength(1));
    ParameterElement parameter = parameters[0];
    expect(parameter, isNotNull);
    expect(parameter.name, parameterName);
    expect(parameter.initializer, isNull);
    expect(parameter.isConst, isFalse);
    expect(parameter.isFinal, isFalse);
    expect(parameter.isSynthetic, isFalse);
    expect(parameter.parameterKind, ParameterKind.REQUIRED);
    _assertVisibleRange(parameter, 100, 110);
  }

  void test_visitFunctionTypedFormalParameter_withTypeParameters() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String parameterName = "p";
    FunctionTypedFormalParameter formalParameter =
        AstFactory.functionTypedFormalParameter(null, parameterName);
    formalParameter.typeParameters = AstFactory.typeParameterList(['F']);
    _useParameterInMethod(formalParameter, 100, 110);
    formalParameter.accept(builder);
    List<ParameterElement> parameters = holder.parameters;
    expect(parameters, hasLength(1));
    ParameterElement parameter = parameters[0];
    expect(parameter, isNotNull);
    expect(parameter.name, parameterName);
    expect(parameter.initializer, isNull);
    expect(parameter.isConst, isFalse);
    expect(parameter.isFinal, isFalse);
    expect(parameter.isSynthetic, isFalse);
    expect(parameter.parameterKind, ParameterKind.REQUIRED);
    expect(parameter.typeParameters, hasLength(1));
    _assertVisibleRange(parameter, 100, 110);
  }

  void test_visitLabeledStatement() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String labelName = "l";
    LabeledStatement statement = AstFactory.labeledStatement(
        [AstFactory.label2(labelName)], AstFactory.breakStatement());
    statement.accept(builder);
    List<LabelElement> labels = holder.labels;
    expect(labels, hasLength(1));
    LabelElement label = labels[0];
    expect(label, isNotNull);
    expect(label.name, labelName);
    expect(label.isSynthetic, isFalse);
  }

  void test_visitMethodDeclaration_abstract() {
    // m();
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(
        null,
        null,
        null,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList(),
        AstFactory.emptyFunctionBody());
    methodDeclaration.accept(builder);

    List<MethodElement> methods = holder.methods;
    expect(methods, hasLength(1));
    MethodElement method = methods[0];
    expect(method, isNotNull);
    expect(method.hasImplicitReturnType, isTrue);
    expect(method.name, methodName);
    expect(method.functions, hasLength(0));
    expect(method.labels, hasLength(0));
    expect(method.localVariables, hasLength(0));
    expect(method.parameters, hasLength(0));
    expect(method.typeParameters, hasLength(0));
    expect(method.isAbstract, isTrue);
    expect(method.isExternal, isFalse);
    expect(method.isStatic, isFalse);
    expect(method.isSynthetic, isFalse);
  }

  void test_visitMethodDeclaration_external() {
    // external m();
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(
        null,
        null,
        null,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList(),
        AstFactory.emptyFunctionBody());
    methodDeclaration.externalKeyword =
        TokenFactory.tokenFromKeyword(Keyword.EXTERNAL);
    methodDeclaration.accept(builder);

    List<MethodElement> methods = holder.methods;
    expect(methods, hasLength(1));
    MethodElement method = methods[0];
    expect(method, isNotNull);
    expect(method.hasImplicitReturnType, isTrue);
    expect(method.name, methodName);
    expect(method.functions, hasLength(0));
    expect(method.labels, hasLength(0));
    expect(method.localVariables, hasLength(0));
    expect(method.parameters, hasLength(0));
    expect(method.typeParameters, hasLength(0));
    expect(method.isAbstract, isFalse);
    expect(method.isExternal, isTrue);
    expect(method.isStatic, isFalse);
    expect(method.isSynthetic, isFalse);
  }

  void test_visitMethodDeclaration_getter() {
    // get m() {}
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(
        null,
        null,
        Keyword.GET,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList(),
        AstFactory.blockFunctionBody2());
    methodDeclaration.documentationComment = AstFactory.documentationComment(
        [TokenFactory.tokenFromString('/// aaa')..offset = 50], []);
    methodDeclaration.endToken.offset = 80;
    methodDeclaration.accept(builder);

    List<FieldElement> fields = holder.fields;
    expect(fields, hasLength(1));
    FieldElement field = fields[0];
    expect(field, isNotNull);
    expect(field.name, methodName);
    expect(field.isSynthetic, isTrue);
    expect(field.setter, isNull);
    PropertyAccessorElement getter = field.getter;
    expect(getter, isNotNull);
    _assertHasCodeRange(getter, 50, 31);
    expect(getter.documentationComment, '/// aaa');
    _assertHasDocRange(getter, 50, 7);
    expect(getter.hasImplicitReturnType, isTrue);
    expect(getter.isAbstract, isFalse);
    expect(getter.isExternal, isFalse);
    expect(getter.isGetter, isTrue);
    expect(getter.isSynthetic, isFalse);
    expect(getter.name, methodName);
    expect(getter.variable, field);
    expect(getter.functions, hasLength(0));
    expect(getter.labels, hasLength(0));
    expect(getter.localVariables, hasLength(0));
    expect(getter.parameters, hasLength(0));
  }

  void test_visitMethodDeclaration_getter_abstract() {
    // get m();
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(
        null,
        null,
        Keyword.GET,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList(),
        AstFactory.emptyFunctionBody());
    methodDeclaration.accept(builder);

    List<FieldElement> fields = holder.fields;
    expect(fields, hasLength(1));
    FieldElement field = fields[0];
    expect(field, isNotNull);
    expect(field.name, methodName);
    expect(field.isSynthetic, isTrue);
    expect(field.setter, isNull);
    PropertyAccessorElement getter = field.getter;
    expect(getter, isNotNull);
    expect(getter.hasImplicitReturnType, isTrue);
    expect(getter.isAbstract, isTrue);
    expect(getter.isExternal, isFalse);
    expect(getter.isGetter, isTrue);
    expect(getter.isSynthetic, isFalse);
    expect(getter.name, methodName);
    expect(getter.variable, field);
    expect(getter.functions, hasLength(0));
    expect(getter.labels, hasLength(0));
    expect(getter.localVariables, hasLength(0));
    expect(getter.parameters, hasLength(0));
  }

  void test_visitMethodDeclaration_getter_external() {
    // external get m();
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration(
        null,
        null,
        Keyword.GET,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList());
    methodDeclaration.externalKeyword =
        TokenFactory.tokenFromKeyword(Keyword.EXTERNAL);
    methodDeclaration.accept(builder);

    List<FieldElement> fields = holder.fields;
    expect(fields, hasLength(1));
    FieldElement field = fields[0];
    expect(field, isNotNull);
    expect(field.name, methodName);
    expect(field.isSynthetic, isTrue);
    expect(field.setter, isNull);
    PropertyAccessorElement getter = field.getter;
    expect(getter, isNotNull);
    expect(getter.hasImplicitReturnType, isTrue);
    expect(getter.isAbstract, isFalse);
    expect(getter.isExternal, isTrue);
    expect(getter.isGetter, isTrue);
    expect(getter.isSynthetic, isFalse);
    expect(getter.name, methodName);
    expect(getter.variable, field);
    expect(getter.functions, hasLength(0));
    expect(getter.labels, hasLength(0));
    expect(getter.localVariables, hasLength(0));
    expect(getter.parameters, hasLength(0));
  }

  void test_visitMethodDeclaration_minimal() {
    // T m() {}
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(
        null,
        AstFactory.typeName4('T'),
        null,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList(),
        AstFactory.blockFunctionBody2());
    methodDeclaration.documentationComment = AstFactory.documentationComment(
        [TokenFactory.tokenFromString('/// aaa')..offset = 50], []);
    methodDeclaration.endToken.offset = 80;
    methodDeclaration.accept(builder);

    List<MethodElement> methods = holder.methods;
    expect(methods, hasLength(1));
    MethodElement method = methods[0];
    expect(method, isNotNull);
    _assertHasCodeRange(method, 50, 31);
    expect(method.documentationComment, '/// aaa');
    _assertHasDocRange(method, 50, 7);
    expect(method.hasImplicitReturnType, isFalse);
    expect(method.name, methodName);
    expect(method.functions, hasLength(0));
    expect(method.labels, hasLength(0));
    expect(method.localVariables, hasLength(0));
    expect(method.parameters, hasLength(0));
    expect(method.typeParameters, hasLength(0));
    expect(method.isAbstract, isFalse);
    expect(method.isExternal, isFalse);
    expect(method.isStatic, isFalse);
    expect(method.isSynthetic, isFalse);
  }

  void test_visitMethodDeclaration_operator() {
    // operator +(addend) {}
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String methodName = "+";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(
        null,
        null,
        null,
        Keyword.OPERATOR,
        AstFactory.identifier3(methodName),
        AstFactory
            .formalParameterList([AstFactory.simpleFormalParameter3("addend")]),
        AstFactory.blockFunctionBody2());
    methodDeclaration.accept(builder);

    List<MethodElement> methods = holder.methods;
    expect(methods, hasLength(1));
    MethodElement method = methods[0];
    expect(method, isNotNull);
    expect(method.hasImplicitReturnType, isTrue);
    expect(method.name, methodName);
    expect(method.functions, hasLength(0));
    expect(method.labels, hasLength(0));
    expect(method.localVariables, hasLength(0));
    expect(method.parameters, hasLength(1));
    expect(method.typeParameters, hasLength(0));
    expect(method.isAbstract, isFalse);
    expect(method.isExternal, isFalse);
    expect(method.isStatic, isFalse);
    expect(method.isSynthetic, isFalse);
  }

  void test_visitMethodDeclaration_setter() {
    // set m() {}
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(
        null,
        null,
        Keyword.SET,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList(),
        AstFactory.blockFunctionBody2());
    methodDeclaration.documentationComment = AstFactory.documentationComment(
        [TokenFactory.tokenFromString('/// aaa')..offset = 50], []);
    methodDeclaration.endToken.offset = 80;
    methodDeclaration.accept(builder);

    List<FieldElement> fields = holder.fields;
    expect(fields, hasLength(1));
    FieldElement field = fields[0];
    expect(field, isNotNull);
    expect(field.name, methodName);
    expect(field.isSynthetic, isTrue);
    expect(field.getter, isNull);

    PropertyAccessorElement setter = field.setter;
    expect(setter, isNotNull);
    _assertHasCodeRange(setter, 50, 31);
    expect(setter.documentationComment, '/// aaa');
    _assertHasDocRange(setter, 50, 7);
    expect(setter.hasImplicitReturnType, isTrue);
    expect(setter.isAbstract, isFalse);
    expect(setter.isExternal, isFalse);
    expect(setter.isSetter, isTrue);
    expect(setter.isSynthetic, isFalse);
    expect(setter.name, "$methodName=");
    expect(setter.displayName, methodName);
    expect(setter.variable, field);
    expect(setter.functions, hasLength(0));
    expect(setter.labels, hasLength(0));
    expect(setter.localVariables, hasLength(0));
    expect(setter.parameters, hasLength(0));
  }

  void test_visitMethodDeclaration_setter_abstract() {
    // set m();
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(
        null,
        null,
        Keyword.SET,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList(),
        AstFactory.emptyFunctionBody());
    methodDeclaration.accept(builder);

    List<FieldElement> fields = holder.fields;
    expect(fields, hasLength(1));
    FieldElement field = fields[0];
    expect(field, isNotNull);
    expect(field.name, methodName);
    expect(field.isSynthetic, isTrue);
    expect(field.getter, isNull);
    PropertyAccessorElement setter = field.setter;
    expect(setter, isNotNull);
    expect(setter.hasImplicitReturnType, isTrue);
    expect(setter.isAbstract, isTrue);
    expect(setter.isExternal, isFalse);
    expect(setter.isSetter, isTrue);
    expect(setter.isSynthetic, isFalse);
    expect(setter.name, "$methodName=");
    expect(setter.displayName, methodName);
    expect(setter.variable, field);
    expect(setter.functions, hasLength(0));
    expect(setter.labels, hasLength(0));
    expect(setter.localVariables, hasLength(0));
    expect(setter.parameters, hasLength(0));
  }

  void test_visitMethodDeclaration_setter_external() {
    // external m();
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration(
        null,
        null,
        Keyword.SET,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList());
    methodDeclaration.externalKeyword =
        TokenFactory.tokenFromKeyword(Keyword.EXTERNAL);
    methodDeclaration.accept(builder);

    List<FieldElement> fields = holder.fields;
    expect(fields, hasLength(1));
    FieldElement field = fields[0];
    expect(field, isNotNull);
    expect(field.name, methodName);
    expect(field.isSynthetic, isTrue);
    expect(field.getter, isNull);
    PropertyAccessorElement setter = field.setter;
    expect(setter, isNotNull);
    expect(setter.hasImplicitReturnType, isTrue);
    expect(setter.isAbstract, isFalse);
    expect(setter.isExternal, isTrue);
    expect(setter.isSetter, isTrue);
    expect(setter.isSynthetic, isFalse);
    expect(setter.name, "$methodName=");
    expect(setter.displayName, methodName);
    expect(setter.variable, field);
    expect(setter.functions, hasLength(0));
    expect(setter.labels, hasLength(0));
    expect(setter.localVariables, hasLength(0));
    expect(setter.parameters, hasLength(0));
  }

  void test_visitMethodDeclaration_static() {
    // static m() {}
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(
        Keyword.STATIC,
        null,
        null,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList(),
        AstFactory.blockFunctionBody2());
    methodDeclaration.accept(builder);
    List<MethodElement> methods = holder.methods;
    expect(methods, hasLength(1));
    MethodElement method = methods[0];
    expect(method, isNotNull);
    expect(method.hasImplicitReturnType, isTrue);
    expect(method.name, methodName);
    expect(method.functions, hasLength(0));
    expect(method.labels, hasLength(0));
    expect(method.localVariables, hasLength(0));
    expect(method.parameters, hasLength(0));
    expect(method.typeParameters, hasLength(0));
    expect(method.isAbstract, isFalse);
    expect(method.isExternal, isFalse);
    expect(method.isStatic, isTrue);
    expect(method.isSynthetic, isFalse);
  }

  void test_visitMethodDeclaration_typeParameters() {
    // m<E>() {}
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String methodName = "m";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(
        null,
        null,
        null,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList(),
        AstFactory.blockFunctionBody2());
    methodDeclaration.typeParameters = AstFactory.typeParameterList(['E']);
    methodDeclaration.accept(builder);

    List<MethodElement> methods = holder.methods;
    expect(methods, hasLength(1));
    MethodElement method = methods[0];
    expect(method, isNotNull);
    expect(method.hasImplicitReturnType, isTrue);
    expect(method.name, methodName);
    expect(method.functions, hasLength(0));
    expect(method.labels, hasLength(0));
    expect(method.localVariables, hasLength(0));
    expect(method.parameters, hasLength(0));
    expect(method.typeParameters, hasLength(1));
    expect(method.isAbstract, isFalse);
    expect(method.isExternal, isFalse);
    expect(method.isStatic, isFalse);
    expect(method.isSynthetic, isFalse);
  }

  void test_visitMethodDeclaration_withMembers() {
    // m(p) { var v; try { l: return; } catch (e) {} }
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String methodName = "m";
    String parameterName = "p";
    String localVariableName = "v";
    String labelName = "l";
    String exceptionParameterName = "e";
    MethodDeclaration methodDeclaration = AstFactory.methodDeclaration2(
        null,
        null,
        null,
        null,
        AstFactory.identifier3(methodName),
        AstFactory.formalParameterList(
            [AstFactory.simpleFormalParameter3(parameterName)]),
        AstFactory.blockFunctionBody2([
          AstFactory.variableDeclarationStatement2(
              Keyword.VAR, [AstFactory.variableDeclaration(localVariableName)]),
          AstFactory.tryStatement2(
              AstFactory.block([
                AstFactory.labeledStatement([AstFactory.label2(labelName)],
                    AstFactory.returnStatement())
              ]),
              [AstFactory.catchClause(exceptionParameterName)])
        ]));
    methodDeclaration.accept(builder);

    List<MethodElement> methods = holder.methods;
    expect(methods, hasLength(1));
    MethodElement method = methods[0];
    expect(method, isNotNull);
    expect(method.hasImplicitReturnType, isTrue);
    expect(method.name, methodName);
    expect(method.typeParameters, hasLength(0));
    expect(method.isAbstract, isFalse);
    expect(method.isExternal, isFalse);
    expect(method.isStatic, isFalse);
    expect(method.isSynthetic, isFalse);
    List<VariableElement> parameters = method.parameters;
    expect(parameters, hasLength(1));
    VariableElement parameter = parameters[0];
    expect(parameter, isNotNull);
    expect(parameter.name, parameterName);
    List<VariableElement> localVariables = method.localVariables;
    expect(localVariables, hasLength(2));
    VariableElement firstVariable = localVariables[0];
    VariableElement secondVariable = localVariables[1];
    expect(firstVariable, isNotNull);
    expect(secondVariable, isNotNull);
    expect(
        (firstVariable.name == localVariableName &&
                secondVariable.name == exceptionParameterName) ||
            (firstVariable.name == exceptionParameterName &&
                secondVariable.name == localVariableName),
        isTrue);
    List<LabelElement> labels = method.labels;
    expect(labels, hasLength(1));
    LabelElement label = labels[0];
    expect(label, isNotNull);
    expect(label.name, labelName);
  }

  void test_visitNamedFormalParameter() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String parameterName = "p";
    DefaultFormalParameter formalParameter = AstFactory.namedFormalParameter(
        AstFactory.simpleFormalParameter3(parameterName),
        AstFactory.identifier3("42"));
    _useParameterInMethod(formalParameter, 100, 110);
    formalParameter.beginToken.offset = 50;
    formalParameter.endToken.offset = 80;
    formalParameter.accept(builder);
    List<ParameterElement> parameters = holder.parameters;
    expect(parameters, hasLength(1));
    ParameterElement parameter = parameters[0];
    expect(parameter, isNotNull);
    _assertHasCodeRange(parameter, 50, 32);
    expect(parameter.name, parameterName);
    expect(parameter.isConst, isFalse);
    expect(parameter.isFinal, isFalse);
    expect(parameter.isSynthetic, isFalse);
    expect(parameter.parameterKind, ParameterKind.NAMED);
    _assertVisibleRange(parameter, 100, 110);
    expect(parameter.defaultValueCode, "42");
    FunctionElement initializer = parameter.initializer;
    expect(initializer, isNotNull);
    expect(initializer.isSynthetic, isTrue);
    expect(initializer.hasImplicitReturnType, isTrue);
  }

  void test_visitSimpleFormalParameter_noType() {
    // p
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String parameterName = "p";
    SimpleFormalParameter formalParameter =
        AstFactory.simpleFormalParameter3(parameterName);
    _useParameterInMethod(formalParameter, 100, 110);
    formalParameter.accept(builder);
    List<ParameterElement> parameters = holder.parameters;
    expect(parameters, hasLength(1));
    ParameterElement parameter = parameters[0];
    expect(parameter, isNotNull);
    expect(parameter.hasImplicitType, isTrue);
    expect(parameter.initializer, isNull);
    expect(parameter.isConst, isFalse);
    expect(parameter.isFinal, isFalse);
    expect(parameter.isSynthetic, isFalse);
    expect(parameter.name, parameterName);
    expect(parameter.parameterKind, ParameterKind.REQUIRED);
    _assertVisibleRange(parameter, 100, 110);
  }

  void test_visitSimpleFormalParameter_type() {
    // T p
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String parameterName = "p";
    SimpleFormalParameter formalParameter = AstFactory.simpleFormalParameter4(
        AstFactory.typeName4('T'), parameterName);
    _useParameterInMethod(formalParameter, 100, 110);
    formalParameter.accept(builder);
    List<ParameterElement> parameters = holder.parameters;
    expect(parameters, hasLength(1));
    ParameterElement parameter = parameters[0];
    expect(parameter, isNotNull);
    expect(parameter.hasImplicitType, isFalse);
    expect(parameter.initializer, isNull);
    expect(parameter.isConst, isFalse);
    expect(parameter.isFinal, isFalse);
    expect(parameter.isSynthetic, isFalse);
    expect(parameter.name, parameterName);
    expect(parameter.parameterKind, ParameterKind.REQUIRED);
    _assertVisibleRange(parameter, 100, 110);
  }

  void test_visitTypeAlias_minimal() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String aliasName = "F";
    TypeAlias typeAlias = AstFactory.typeAlias(null, aliasName, null, null);
    typeAlias.accept(builder);
    List<FunctionTypeAliasElement> aliases = holder.typeAliases;
    expect(aliases, hasLength(1));
    FunctionTypeAliasElement alias = aliases[0];
    expect(alias, isNotNull);
    expect(alias.name, aliasName);
    expect(alias.type, isNotNull);
    expect(alias.isSynthetic, isFalse);
  }

  void test_visitTypeAlias_withFormalParameters() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String aliasName = "F";
    String firstParameterName = "x";
    String secondParameterName = "y";
    TypeAlias typeAlias = AstFactory.typeAlias(
        null,
        aliasName,
        AstFactory.typeParameterList(),
        AstFactory.formalParameterList([
          AstFactory.simpleFormalParameter3(firstParameterName),
          AstFactory.simpleFormalParameter3(secondParameterName)
        ]));
    typeAlias.beginToken.offset = 50;
    typeAlias.endToken.offset = 80;
    typeAlias.accept(builder);
    List<FunctionTypeAliasElement> aliases = holder.typeAliases;
    expect(aliases, hasLength(1));
    FunctionTypeAliasElement alias = aliases[0];
    expect(alias, isNotNull);
    _assertHasCodeRange(alias, 50, 31);
    expect(alias.name, aliasName);
    expect(alias.type, isNotNull);
    expect(alias.isSynthetic, isFalse);
    List<VariableElement> parameters = alias.parameters;
    expect(parameters, hasLength(2));
    expect(parameters[0].name, firstParameterName);
    expect(parameters[1].name, secondParameterName);
    List<TypeParameterElement> typeParameters = alias.typeParameters;
    expect(typeParameters, isNotNull);
    expect(typeParameters, hasLength(0));
  }

  void test_visitTypeAlias_withTypeParameters() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String aliasName = "F";
    String firstTypeParameterName = "A";
    String secondTypeParameterName = "B";
    TypeAlias typeAlias = AstFactory.typeAlias(
        null,
        aliasName,
        AstFactory.typeParameterList(
            [firstTypeParameterName, secondTypeParameterName]),
        AstFactory.formalParameterList());
    typeAlias.accept(builder);
    List<FunctionTypeAliasElement> aliases = holder.typeAliases;
    expect(aliases, hasLength(1));
    FunctionTypeAliasElement alias = aliases[0];
    expect(alias, isNotNull);
    expect(alias.name, aliasName);
    expect(alias.type, isNotNull);
    expect(alias.isSynthetic, isFalse);
    List<VariableElement> parameters = alias.parameters;
    expect(parameters, isNotNull);
    expect(parameters, hasLength(0));
    List<TypeParameterElement> typeParameters = alias.typeParameters;
    expect(typeParameters, hasLength(2));
    expect(typeParameters[0].name, firstTypeParameterName);
    expect(typeParameters[1].name, secondTypeParameterName);
  }

  void test_visitTypeParameter() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String parameterName = "E";
    TypeParameter typeParameter = AstFactory.typeParameter(parameterName);
    typeParameter.beginToken.offset = 50;
    typeParameter.accept(builder);
    List<TypeParameterElement> typeParameters = holder.typeParameters;
    expect(typeParameters, hasLength(1));
    TypeParameterElement typeParameterElement = typeParameters[0];
    expect(typeParameterElement, isNotNull);
    _assertHasCodeRange(typeParameterElement, 50, 1);
    expect(typeParameterElement.name, parameterName);
    expect(typeParameterElement.bound, isNull);
    expect(typeParameterElement.isSynthetic, isFalse);
  }

  void test_visitVariableDeclaration_inConstructor() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    //
    // C() {var v;}
    //
    String variableName = "v";
    VariableDeclaration variable =
        AstFactory.variableDeclaration2(variableName, null);
    VariableDeclarationStatement statement =
        AstFactory.variableDeclarationStatement2(Keyword.VAR, [variable]);
    ConstructorDeclaration constructor = AstFactory.constructorDeclaration2(
        null,
        null,
        AstFactory.identifier3("C"),
        "C",
        AstFactory.formalParameterList(),
        null,
        AstFactory.blockFunctionBody2([statement]));
    statement.beginToken.offset = 50;
    statement.endToken.offset = 80;
    _setBlockBodySourceRange(constructor.body, 100, 110);
    constructor.accept(builder);

    List<ConstructorElement> constructors = holder.constructors;
    expect(constructors, hasLength(1));
    List<LocalVariableElement> variableElements =
        constructors[0].localVariables;
    expect(variableElements, hasLength(1));
    LocalVariableElement variableElement = variableElements[0];
    _assertHasCodeRange(variableElement, 50, 31);
    expect(variableElement.hasImplicitType, isTrue);
    expect(variableElement.name, variableName);
    _assertVisibleRange(variableElement, 100, 110);
  }

  void test_visitVariableDeclaration_inForEachStatement() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    //
    // m() { for (var v in []) }
    //
    String variableName = "v";
    Statement statement = AstFactory.forEachStatement(
        AstFactory.declaredIdentifier3('v'),
        AstFactory.listLiteral(),
        AstFactory.block());
    _setNodeSourceRange(statement, 100, 110);
    MethodDeclaration method = AstFactory.methodDeclaration2(
        null,
        null,
        null,
        null,
        AstFactory.identifier3("m"),
        AstFactory.formalParameterList(),
        AstFactory.blockFunctionBody2([statement]));
    _setBlockBodySourceRange(method.body, 200, 220);
    method.accept(builder);

    List<MethodElement> methods = holder.methods;
    expect(methods, hasLength(1));
    List<LocalVariableElement> variableElements = methods[0].localVariables;
    expect(variableElements, hasLength(1));
    LocalVariableElement variableElement = variableElements[0];
    expect(variableElement.name, variableName);
    _assertVisibleRange(variableElement, 100, 110);
  }

  void test_visitVariableDeclaration_inForStatement() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    //
    // m() { for (T v;;) }
    //
    String variableName = "v";
    ForStatement statement = AstFactory.forStatement2(
        AstFactory.variableDeclarationList(null, AstFactory.typeName4('T'),
            [AstFactory.variableDeclaration('v')]),
        null,
        null,
        AstFactory.block());
    _setNodeSourceRange(statement, 100, 110);
    MethodDeclaration method = AstFactory.methodDeclaration2(
        null,
        null,
        null,
        null,
        AstFactory.identifier3("m"),
        AstFactory.formalParameterList(),
        AstFactory.blockFunctionBody2([statement]));
    _setBlockBodySourceRange(method.body, 200, 220);
    method.accept(builder);

    List<MethodElement> methods = holder.methods;
    expect(methods, hasLength(1));
    List<LocalVariableElement> variableElements = methods[0].localVariables;
    expect(variableElements, hasLength(1));
    LocalVariableElement variableElement = variableElements[0];
    expect(variableElement.name, variableName);
    _assertVisibleRange(variableElement, 100, 110);
  }

  void test_visitVariableDeclaration_inMethod() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    //
    // m() {T v;}
    //
    String variableName = "v";
    VariableDeclaration variable =
        AstFactory.variableDeclaration2(variableName, null);
    Statement statement = AstFactory.variableDeclarationStatement(
        null, AstFactory.typeName4('T'), [variable]);
    MethodDeclaration method = AstFactory.methodDeclaration2(
        null,
        null,
        null,
        null,
        AstFactory.identifier3("m"),
        AstFactory.formalParameterList(),
        AstFactory.blockFunctionBody2([statement]));
    _setBlockBodySourceRange(method.body, 100, 110);
    method.accept(builder);

    List<MethodElement> methods = holder.methods;
    expect(methods, hasLength(1));
    List<LocalVariableElement> variableElements = methods[0].localVariables;
    expect(variableElements, hasLength(1));
    LocalVariableElement variableElement = variableElements[0];
    expect(variableElement.hasImplicitType, isFalse);
    expect(variableElement.name, variableName);
    _assertVisibleRange(variableElement, 100, 110);
  }

  void test_visitVariableDeclaration_localNestedInFunction() {
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    //
    // var f = () {var v;};
    //
    String variableName = "v";
    VariableDeclaration variable =
        AstFactory.variableDeclaration2(variableName, null);
    Statement statement =
        AstFactory.variableDeclarationStatement2(null, [variable]);
    Expression initializer = AstFactory.functionExpression2(
        AstFactory.formalParameterList(),
        AstFactory.blockFunctionBody2([statement]));
    String fieldName = "f";
    VariableDeclaration field =
        AstFactory.variableDeclaration2(fieldName, initializer);
    FieldDeclaration fieldDeclaration =
        AstFactory.fieldDeclaration2(false, null, [field]);
    fieldDeclaration.accept(builder);

    List<FieldElement> variables = holder.fields;
    expect(variables, hasLength(1));
    FieldElement fieldElement = variables[0];
    expect(fieldElement, isNotNull);
    FunctionElement initializerElement = fieldElement.initializer;
    expect(initializerElement, isNotNull);
    expect(initializerElement.hasImplicitReturnType, isTrue);
    List<FunctionElement> functionElements = initializerElement.functions;
    expect(functionElements, hasLength(1));
    List<LocalVariableElement> variableElements =
        functionElements[0].localVariables;
    expect(variableElements, hasLength(1));
    LocalVariableElement variableElement = variableElements[0];
    expect(variableElement.hasImplicitType, isTrue);
    expect(variableElement.isConst, isFalse);
    expect(variableElement.isFinal, isFalse);
    expect(variableElement.isSynthetic, isFalse);
    expect(variableElement.name, variableName);
  }

  void test_visitVariableDeclaration_noInitializer() {
    // var v;
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String variableName = "v";
    VariableDeclaration variableDeclaration =
        AstFactory.variableDeclaration2(variableName, null);
    AstFactory.variableDeclarationList2(null, [variableDeclaration]);
    variableDeclaration.accept(builder);

    List<TopLevelVariableElement> variables = holder.topLevelVariables;
    expect(variables, hasLength(1));
    TopLevelVariableElement variable = variables[0];
    expect(variable, isNotNull);
    expect(variable.hasImplicitType, isTrue);
    expect(variable.initializer, isNull);
    expect(variable.name, variableName);
    expect(variable.isConst, isFalse);
    expect(variable.isFinal, isFalse);
    expect(variable.isSynthetic, isFalse);
    expect(variable.getter, isNotNull);
    expect(variable.setter, isNotNull);
  }

  void test_visitVariableDeclaration_top_const_hasInitializer() {
    // const v = 42;
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String variableName = "v";
    VariableDeclaration variableDeclaration =
        AstFactory.variableDeclaration2(variableName, AstFactory.integer(42));
    AstFactory.variableDeclarationList2(Keyword.CONST, [variableDeclaration]);
    variableDeclaration.accept(builder);

    List<TopLevelVariableElement> variables = holder.topLevelVariables;
    expect(variables, hasLength(1));
    TopLevelVariableElement variable = variables[0];
    expect(variable, new isInstanceOf<ConstTopLevelVariableElementImpl>());
    expect(variable.initializer, isNotNull);
    expect(variable.initializer.type, isNotNull);
    expect(variable.initializer.hasImplicitReturnType, isTrue);
    expect(variable.name, variableName);
    expect(variable.hasImplicitType, isTrue);
    expect(variable.isConst, isTrue);
    expect(variable.isFinal, isFalse);
    expect(variable.isSynthetic, isFalse);
    expect(variable.getter, isNotNull);
    expect(variable.setter, isNull);
  }

  void test_visitVariableDeclaration_top_docRange() {
    // final a, b;
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    VariableDeclaration variableDeclaration1 =
        AstFactory.variableDeclaration('a');
    VariableDeclaration variableDeclaration2 =
        AstFactory.variableDeclaration('b');
    TopLevelVariableDeclaration topLevelVariableDeclaration = AstFactory
        .topLevelVariableDeclaration(
            Keyword.FINAL, null, [variableDeclaration1, variableDeclaration2]);
    topLevelVariableDeclaration.documentationComment = AstFactory
        .documentationComment(
            [TokenFactory.tokenFromString('/// aaa')..offset = 50], []);

    topLevelVariableDeclaration.accept(builder);
    List<TopLevelVariableElement> variables = holder.topLevelVariables;
    expect(variables, hasLength(2));

    TopLevelVariableElement variable1 = variables[0];
    expect(variable1, isNotNull);
    expect(variable1.documentationComment, '/// aaa');
    _assertHasDocRange(variable1, 50, 7);

    TopLevelVariableElement variable2 = variables[1];
    expect(variable2, isNotNull);
    expect(variable2.documentationComment, '/// aaa');
    _assertHasDocRange(variable2, 50, 7);
  }

  void test_visitVariableDeclaration_top_final() {
    // final v;
    ElementHolder holder = new ElementHolder();
    ElementBuilder builder = _makeBuilder(holder);
    String variableName = "v";
    VariableDeclaration variableDeclaration =
        AstFactory.variableDeclaration2(variableName, null);
    AstFactory.variableDeclarationList2(Keyword.FINAL, [variableDeclaration]);
    variableDeclaration.accept(builder);
    List<TopLevelVariableElement> variables = holder.topLevelVariables;
    expect(variables, hasLength(1));
    TopLevelVariableElement variable = variables[0];
    expect(variable, isNotNull);
    expect(variable.hasImplicitType, isTrue);
    expect(variable.initializer, isNull);
    expect(variable.name, variableName);
    expect(variable.isConst, isFalse);
    expect(variable.isFinal, isTrue);
    expect(variable.isSynthetic, isFalse);
    expect(variable.getter, isNotNull);
    expect(variable.setter, isNull);
  }

  void _assertHasCodeRange(Element element, int offset, int length) {
    ElementImpl elementImpl = element;
    expect(elementImpl.codeOffset, offset);
    expect(elementImpl.codeLength, length);
  }

  void _assertHasDocRange(
      Element element, int expectedOffset, int expectedLength) {
    // Cast to dynamic here to avoid a hint about @deprecated docRange.
    SourceRange docRange = (element as dynamic).docRange;
    expect(docRange, isNotNull);
    expect(docRange.offset, expectedOffset);
    expect(docRange.length, expectedLength);
  }

  void _assertVisibleRange(LocalElement element, int offset, int end) {
    SourceRange visibleRange = element.visibleRange;
    expect(visibleRange.offset, offset);
    expect(visibleRange.end, end);
  }

  ElementBuilder _makeBuilder(ElementHolder holder) =>
      new ElementBuilder(holder, new CompilationUnitElementImpl('test.dart'));

  void _setBlockBodySourceRange(BlockFunctionBody body, int offset, int end) {
    _setNodeSourceRange(body.block, offset, end);
  }

  void _setNodeSourceRange(AstNode node, int offset, int end) {
    node.beginToken.offset = offset;
    Token endToken = node.endToken;
    endToken.offset = end - endToken.length;
  }

  void _useParameterInMethod(
      FormalParameter formalParameter, int blockOffset, int blockEnd) {
    Block block = AstFactory.block();
    block.leftBracket.offset = blockOffset;
    block.rightBracket.offset = blockEnd - 1;
    BlockFunctionBody body = AstFactory.blockFunctionBody(block);
    AstFactory.methodDeclaration2(
        null,
        null,
        null,
        null,
        AstFactory.identifier3("main"),
        AstFactory.formalParameterList([formalParameter]),
        body);
  }
}

@reflectiveTest
class ElementLocatorTest extends ResolverTestCase {
  void test_locate_ExportDirective() {
    AstNode id = _findNodeIn("export", "export 'dart:core';");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ExportElement, ExportElement, element);
  }

  void test_locate_Identifier_libraryDirective() {
    AstNode id = _findNodeIn("foo", "library foo.bar;");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is LibraryElement, LibraryElement, element);
  }

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
    resetWithOptions(analysisOptions);
  }

  void test_locate_AssignmentExpression() {
    AstNode id = _findNodeIn(
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

  void test_locate_BinaryExpression() {
    AstNode id = _findNodeIn("+", "var x = 3 + 4;");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is MethodElement, MethodElement, element);
  }

  void test_locate_ClassDeclaration() {
    AstNode id = _findNodeIn("class", "class A { }");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ClassElement, ClassElement, element);
  }

  void test_locate_CompilationUnit() {
    CompilationUnit cu = _resolveContents("// only comment");
    expect(cu.element, isNotNull);
    Element element = ElementLocator.locate(cu);
    expect(element, same(cu.element));
  }

  void test_locate_ConstructorDeclaration() {
    AstNode id = _findNodeIndexedIn(
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

  void test_locate_FunctionDeclaration() {
    AstNode id = _findNodeIn("f", "int f() => 3;");
    FunctionDeclaration declaration =
        id.getAncestor((node) => node is FunctionDeclaration);
    Element element = ElementLocator.locate(declaration);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is FunctionElement, FunctionElement, element);
  }

  void
      test_locate_Identifier_annotationClass_namedConstructor_forSimpleFormalParameter() {
    AstNode id = _findNodeIndexedIn(
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

  void
      test_locate_Identifier_annotationClass_unnamedConstructor_forSimpleFormalParameter() {
    AstNode id = _findNodeIndexedIn(
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

  void test_locate_Identifier_className() {
    AstNode id = _findNodeIn("A", "class A { }");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ClassElement, ClassElement, element);
  }

  void test_locate_Identifier_constructor_named() {
    AstNode id = _findNodeIndexedIn(
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

  void test_locate_Identifier_constructor_unnamed() {
    AstNode id = _findNodeIndexedIn(
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

  void test_locate_Identifier_fieldName() {
    AstNode id = _findNodeIn("x", "class A { var x; }");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is FieldElement, FieldElement, element);
  }

  void test_locate_Identifier_propertyAccess() {
    AstNode id = _findNodeIn(
        "length",
        r'''
void main() {
 int x = 'foo'.length;
}''');
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf((obj) => obj is PropertyAccessorElement,
        PropertyAccessorElement, element);
  }

  void test_locate_ImportDirective() {
    AstNode id = _findNodeIn("import", "import 'dart:core';");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ImportElement, ImportElement, element);
  }

  void test_locate_IndexExpression() {
    AstNode id = _findNodeIndexedIn(
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

  void test_locate_InstanceCreationExpression() {
    AstNode node = _findNodeIndexedIn(
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

  void test_locate_InstanceCreationExpression_type_prefixedIdentifier() {
    // prepare: new pref.A()
    SimpleIdentifier identifier = AstFactory.identifier3("A");
    PrefixedIdentifier prefixedIdentifier =
        AstFactory.identifier4("pref", identifier);
    InstanceCreationExpression creation =
        AstFactory.instanceCreationExpression2(
            Keyword.NEW, AstFactory.typeName3(prefixedIdentifier));
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

  void test_locate_InstanceCreationExpression_type_simpleIdentifier() {
    // prepare: new A()
    SimpleIdentifier identifier = AstFactory.identifier3("A");
    InstanceCreationExpression creation =
        AstFactory.instanceCreationExpression2(
            Keyword.NEW, AstFactory.typeName3(identifier));
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

  void test_locate_LibraryDirective() {
    AstNode id = _findNodeIn("library", "library foo;");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is LibraryElement, LibraryElement, element);
  }

  void test_locate_MethodDeclaration() {
    AstNode id = _findNodeIn(
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

  void test_locate_MethodInvocation_method() {
    AstNode id = _findNodeIndexedIn(
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

  void test_locate_MethodInvocation_topLevel() {
    String code = r'''
foo(x) {}
void main() {
 foo(0);
}''';
    CompilationUnit cu = _resolveContents(code);
    int offset = code.indexOf('foo(0)');
    AstNode node = new NodeLocator(offset).searchWithin(cu);
    MethodInvocation invocation =
        node.getAncestor((n) => n is MethodInvocation);
    Element element = ElementLocator.locate(invocation);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is FunctionElement, FunctionElement, element);
  }

  void test_locate_PartOfDirective() {
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

  void test_locate_PostfixExpression() {
    AstNode id = _findNodeIn("++", "int addOne(int x) => x++;");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is MethodElement, MethodElement, element);
  }

  void test_locate_PrefixedIdentifier() {
    AstNode id = _findNodeIn(
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

  void test_locate_PrefixExpression() {
    AstNode id = _findNodeIn("++", "int addOne(int x) => ++x;");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is MethodElement, MethodElement, element);
  }

  void test_locate_StringLiteral_exportUri() {
    addNamedSource("/foo.dart", "library foo;");
    AstNode id = _findNodeIn("'foo.dart'", "export 'foo.dart';");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is LibraryElement, LibraryElement, element);
  }

  void test_locate_StringLiteral_expression() {
    AstNode id = _findNodeIn("abc", "var x = 'abc';");
    Element element = ElementLocator.locate(id);
    expect(element, isNull);
  }

  void test_locate_StringLiteral_importUri() {
    addNamedSource("/foo.dart", "library foo; class A {}");
    AstNode id =
        _findNodeIn("'foo.dart'", "import 'foo.dart'; class B extends A {}");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is LibraryElement, LibraryElement, element);
  }

  void test_locate_StringLiteral_partUri() {
    addNamedSource("/foo.dart", "part of app;");
    AstNode id = _findNodeIn("'foo.dart'", "library app; part 'foo.dart';");
    Element element = ElementLocator.locate(id);
    EngineTestCase.assertInstanceOf((obj) => obj is CompilationUnitElement,
        CompilationUnitElement, element);
  }

  void test_locate_VariableDeclaration() {
    AstNode id = _findNodeIn("x", "var x = 'abc';");
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
  AstNode _findNodeIn(String nodePattern, String code) {
    return _findNodeIndexedIn(nodePattern, 0, code);
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
  AstNode _findNodeIndexedIn(String nodePattern, int index, String code) {
    CompilationUnit cu = _resolveContents(code);
    int start = _getOffsetOfMatch(code, nodePattern, index);
    int end = start + nodePattern.length;
    return new NodeLocator(start, end).searchWithin(cu);
  }

  int _getOffsetOfMatch(String contents, String pattern, int matchIndex) {
    if (matchIndex == 0) {
      return contents.indexOf(pattern);
    }
    JavaPatternMatcher matcher =
        new JavaPatternMatcher(new RegExp(pattern), contents);
    int count = 0;
    while (matcher.find()) {
      if (count == matchIndex) {
        return matcher.start();
      }
      ++count;
    }
    return -1;
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
  CompilationUnit _resolveContents(String code) {
    Source source = addSource(code);
    LibraryElement library = resolve2(source);
    assertNoErrors(source);
    verify([source]);
    return analysisContext.resolveCompilationUnit(source, library);
  }
}

@reflectiveTest
class EnumMemberBuilderTest extends EngineTestCase {
  void test_visitEnumDeclaration_multiple() {
    String firstName = "ONE";
    String secondName = "TWO";
    String thirdName = "THREE";
    EnumDeclaration enumDeclaration =
        AstFactory.enumDeclaration2("E", [firstName, secondName, thirdName]);

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

  void test_visitEnumDeclaration_single() {
    String firstName = "ONE";
    EnumDeclaration enumDeclaration =
        AstFactory.enumDeclaration2("E", [firstName]);
    enumDeclaration.constants[0].documentationComment = AstFactory
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
    expect(constant.docRange.offset, 50);
    expect(constant.docRange.length, 7);
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

  void test_creation() {
    GatheringErrorListener listener = new GatheringErrorListener();
    TestSource source = new TestSource();
    expect(new ErrorReporter(listener, source), isNotNull);
  }

  void test_reportErrorForElement_named() {
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

  void test_reportErrorForElement_unnamed() {
    ImportElementImpl element =
        ElementFactory.importFor(ElementFactory.library(null, ''), null);
    GatheringErrorListener listener = new GatheringErrorListener();
    ErrorReporter reporter = new ErrorReporter(
        listener,
        new NonExistingSource(
            '/test.dart', toUri('/test.dart'), UriKind.FILE_URI));
    reporter.reportErrorForElement(
        StaticWarningCode.CONFLICTING_INSTANCE_GETTER_AND_SUPERCLASS_MEMBER,
        element,
        ['A']);
    AnalysisError error = listener.errors[0];
    expect(error.offset, element.nameOffset);
  }

  void test_reportErrorForSpan() {
    GatheringErrorListener listener = new GatheringErrorListener();
    ErrorReporter reporter = new ErrorReporter(listener, new TestSource());

    var src = '''
foo: bar
zap: baz
''';

    int offset = src.indexOf('baz');
    int length = 'baz'.length;

    SourceSpan span = new SourceFile(src).span(offset, offset + length);

    reporter.reportErrorForSpan(
        AnalysisOptionsWarningCode.UNSUPPORTED_OPTION_WITH_LEGAL_VALUE,
        span,
        ['test', 'zip', 'zap']);
    expect(listener.errors, hasLength(1));
    expect(listener.errors.first.offset, offset);
    expect(listener.errors.first.length, length);
  }

  void test_reportTypeErrorForNode_differentNames() {
    DartType firstType = createType("/test1.dart", "A");
    DartType secondType = createType("/test2.dart", "B");
    GatheringErrorListener listener = new GatheringErrorListener();
    ErrorReporter reporter =
        new ErrorReporter(listener, firstType.element.source);
    reporter.reportTypeErrorForNode(
        StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE,
        AstFactory.identifier3("x"),
        [firstType, secondType]);
    AnalysisError error = listener.errors[0];
    expect(error.message.indexOf("(") < 0, isTrue);
  }

  void test_reportTypeErrorForNode_sameName() {
    String typeName = "A";
    DartType firstType = createType("/test1.dart", typeName);
    DartType secondType = createType("/test2.dart", typeName);
    GatheringErrorListener listener = new GatheringErrorListener();
    ErrorReporter reporter =
        new ErrorReporter(listener, firstType.element.source);
    reporter.reportTypeErrorForNode(
        StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE,
        AstFactory.identifier3("x"),
        [firstType, secondType]);
    AnalysisError error = listener.errors[0];
    expect(error.message.indexOf("(") >= 0, isTrue);
  }
}

@reflectiveTest
class ErrorSeverityTest extends EngineTestCase {
  void test_max_error_error() {
    expect(ErrorSeverity.ERROR.max(ErrorSeverity.ERROR),
        same(ErrorSeverity.ERROR));
  }

  void test_max_error_none() {
    expect(
        ErrorSeverity.ERROR.max(ErrorSeverity.NONE), same(ErrorSeverity.ERROR));
  }

  void test_max_error_warning() {
    expect(ErrorSeverity.ERROR.max(ErrorSeverity.WARNING),
        same(ErrorSeverity.ERROR));
  }

  void test_max_none_error() {
    expect(
        ErrorSeverity.NONE.max(ErrorSeverity.ERROR), same(ErrorSeverity.ERROR));
  }

  void test_max_none_none() {
    expect(
        ErrorSeverity.NONE.max(ErrorSeverity.NONE), same(ErrorSeverity.NONE));
  }

  void test_max_none_warning() {
    expect(ErrorSeverity.NONE.max(ErrorSeverity.WARNING),
        same(ErrorSeverity.WARNING));
  }

  void test_max_warning_error() {
    expect(ErrorSeverity.WARNING.max(ErrorSeverity.ERROR),
        same(ErrorSeverity.ERROR));
  }

  void test_max_warning_none() {
    expect(ErrorSeverity.WARNING.max(ErrorSeverity.NONE),
        same(ErrorSeverity.WARNING));
  }

  void test_max_warning_warning() {
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
  void test_asExpression() {
    _assertFalse("a as Object;");
  }

  void test_asExpression_throw() {
    _assertTrue("throw '' as Object;");
  }

  void test_assertStatement() {
    _assertFalse("assert(a);");
  }

  void test_assertStatement_throw() {
    _assertFalse("assert((throw 0));");
  }

  void test_assignmentExpression() {
    _assertFalse("v = 1;");
  }

  void test_assignmentExpression_lhs_throw() {
    _assertTrue("a[throw ''] = 0;");
  }

  void test_assignmentExpression_rhs_throw() {
    _assertTrue("v = throw '';");
  }

  void test_await_false() {
    _assertFalse("await x;");
  }

  void test_await_throw_true() {
    _assertTrue("bool b = await (throw '' || true);");
  }

  void test_binaryExpression_and() {
    _assertFalse("a && b;");
  }

  void test_binaryExpression_and_lhs() {
    _assertTrue("throw '' && b;");
  }

  void test_binaryExpression_and_rhs() {
    _assertFalse("a && (throw '');");
  }

  void test_binaryExpression_and_rhs2() {
    _assertFalse("false && (throw '');");
  }

  void test_binaryExpression_and_rhs3() {
    _assertTrue("true && (throw '');");
  }

  void test_binaryExpression_ifNull() {
    _assertFalse("a ?? b;");
  }

  void test_binaryExpression_ifNull_lhs() {
    _assertTrue("throw '' ?? b;");
  }

  void test_binaryExpression_ifNull_rhs() {
    _assertFalse("a ?? (throw '');");
  }

  void test_binaryExpression_ifNull_rhs2() {
    _assertFalse("null ?? (throw '');");
  }

  void test_binaryExpression_or() {
    _assertFalse("a || b;");
  }

  void test_binaryExpression_or_lhs() {
    _assertTrue("throw '' || b;");
  }

  void test_binaryExpression_or_rhs() {
    _assertFalse("a || (throw '');");
  }

  void test_binaryExpression_or_rhs2() {
    _assertFalse("true || (throw '');");
  }

  void test_binaryExpression_or_rhs3() {
    _assertTrue("false || (throw '');");
  }

  void test_block_empty() {
    _assertFalse("{}");
  }

  void test_block_noReturn() {
    _assertFalse("{ int i = 0; }");
  }

  void test_block_return() {
    _assertTrue("{ return 0; }");
  }

  void test_block_returnNotLast() {
    _assertTrue("{ return 0; throw 'a'; }");
  }

  void test_block_throwNotLast() {
    _assertTrue("{ throw 0; x = null; }");
  }

  void test_cascadeExpression_argument() {
    _assertTrue("a..b(throw '');");
  }

  void test_cascadeExpression_index() {
    _assertTrue("a..[throw ''];");
  }

  void test_cascadeExpression_target() {
    _assertTrue("throw ''..b();");
  }

  void test_conditional_ifElse_bothThrows() {
    _assertTrue("c ? throw '' : throw '';");
  }

  void test_conditional_ifElse_elseThrows() {
    _assertFalse("c ? i : throw '';");
  }

  void test_conditional_ifElse_noThrow() {
    _assertFalse("c ? i : j;");
  }

  void test_conditional_ifElse_thenThrow() {
    _assertFalse("c ? throw '' : j;");
  }

  void test_conditionalAccess() {
    _assertFalse("a?.b;");
  }

  void test_conditionalAccess_lhs() {
    _assertTrue("(throw '')?.b;");
  }

  void test_conditionalAccessAssign() {
    _assertFalse("a?.b = c;");
  }

  void test_conditionalAccessAssign_lhs() {
    _assertTrue("(throw '')?.b = c;");
  }

  void test_conditionalAccessAssign_rhs() {
    _assertFalse("a?.b = throw '';");
  }

  void test_conditionalAccessAssign_rhs2() {
    _assertFalse("null?.b = throw '';");
  }

  void test_conditionalAccessIfNullAssign() {
    _assertFalse("a?.b ??= c;");
  }

  void test_conditionalAccessIfNullAssign_lhs() {
    _assertTrue("(throw '')?.b ??= c;");
  }

  void test_conditionalAccessIfNullAssign_rhs() {
    _assertFalse("a?.b ??= throw '';");
  }

  void test_conditionalAccessIfNullAssign_rhs2() {
    _assertFalse("null?.b ??= throw '';");
  }

  void test_conditionalCall() {
    _assertFalse("a?.b(c);");
  }

  void test_conditionalCall_lhs() {
    _assertTrue("(throw '')?.b(c);");
  }

  void test_conditionalCall_rhs() {
    _assertFalse("a?.b(throw '');");
  }

  void test_conditionalCall_rhs2() {
    _assertFalse("null?.b(throw '');");
  }

  void test_creation() {
    expect(new ExitDetector(), isNotNull);
  }

  void test_doStatement_return() {
    _assertTrue("{ do { return null; } while (1 == 2); }");
  }

  void test_doStatement_throwCondition() {
    _assertTrue("{ do {} while (throw ''); }");
  }

  void test_doStatement_break_and_throw() {
    _assertFalse("{ do { if (1==1) break; throw 'T'; } while (0==1); }");
  }

  void test_doStatement_continue_and_throw() {
    _assertFalse("{ do { if (1==1) continue; throw 'T'; } while (0==1); }");
  }

  void test_doStatement_continueInSwitch_and_throw() {
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

  void test_doStatement_continueDoInSwitch_and_throw() {
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

  void test_doStatement_true_break() {
    _assertFalse("{ do { break; } while (true); }");
  }

  void test_doStatement_true_continue() {
    _assertTrue("{ do { continue; } while (true); }");
  }

  void test_doStatement_true_continueWithLabel() {
    _assertTrue("{ x: do { continue x; } while (true); }");
  }


  void test_doStatement_true_if_return() {
    _assertTrue("{ do { if (true) {return null;} } while (true); }");
  }

  void test_doStatement_true_noBreak() {
    _assertTrue("{ do {} while (true); }");
  }

  void test_doStatement_true_return() {
    _assertTrue("{ do { return null; } while (true);  }");
  }

  void test_emptyStatement() {
    _assertFalse(";");
  }

  void test_forEachStatement() {
    _assertFalse("for (element in list) {}");
  }

  void test_forEachStatement_throw() {
    _assertTrue("for (element in throw '') {}");
  }

  void test_forStatement_condition() {
    _assertTrue("for (; throw 0;) {}");
  }

  void test_forStatement_implicitTrue() {
    _assertTrue("for (;;) {}");
  }

  void test_forStatement_implicitTrue_break() {
    _assertFalse("for (;;) { break; }");
  }

  void test_forStatement_implicitTrue_if_break() {
    _assertFalse("{ for (;;) { if (1==2) { var a = 1; } else { break; } } }");
  }

  void test_forStatement_initialization() {
    _assertTrue("for (i = throw 0;;) {}");
  }

  void test_forStatement_true() {
    _assertTrue("for (; true; ) {}");
  }

  void test_forStatement_true_break() {
    _assertFalse("{ for (; true; ) { break; } }");
  }

  void test_forStatement_true_continue() {
    _assertTrue("{ for (; true; ) { continue; } }");
  }

  void test_forStatement_true_if_return() {
    _assertTrue("{ for (; true; ) { if (true) {return null;} } }");
  }

  void test_forStatement_true_noBreak() {
    _assertTrue("{ for (; true; ) {} }");
  }

  void test_forStatement_updaters() {
    _assertTrue("for (;; i++, throw 0) {}");
  }

  void test_forStatement_variableDeclaration() {
    _assertTrue("for (int i = throw 0;;) {}");
  }

  void test_functionExpression() {
    _assertFalse("(){};");
  }

  void test_functionExpression_bodyThrows() {
    _assertFalse("(int i) => throw '';");
  }

  void test_functionExpressionInvocation() {
    _assertFalse("f(g);");
  }

  void test_functionExpressionInvocation_argumentThrows() {
    _assertTrue("f(throw '');");
  }

  void test_functionExpressionInvocation_targetThrows() {
    _assertTrue("throw ''(g);");
  }

  void test_identifier_prefixedIdentifier() {
    _assertFalse("a.b;");
  }

  void test_identifier_simpleIdentifier() {
    _assertFalse("a;");
  }

  void test_if_false_else_return() {
    _assertTrue("if (false) {} else { return 0; }");
  }

  void test_if_false_noReturn() {
    _assertFalse("if (false) {}");
  }

  void test_if_false_return() {
    _assertFalse("if (false) { return 0; }");
  }

  void test_if_noReturn() {
    _assertFalse("if (c) i++;");
  }

  void test_if_return() {
    _assertFalse("if (c) return 0;");
  }

  void test_if_true_noReturn() {
    _assertFalse("if (true) {}");
  }

  void test_if_true_return() {
    _assertTrue("if (true) { return 0; }");
  }

  void test_ifElse_bothReturn() {
    _assertTrue("if (c) return 0; else return 1;");
  }

  void test_ifElse_elseReturn() {
    _assertFalse("if (c) i++; else return 1;");
  }

  void test_ifElse_noReturn() {
    _assertFalse("if (c) i++; else j++;");
  }

  void test_ifElse_thenReturn() {
    _assertFalse("if (c) return 0; else j++;");
  }

  void test_ifNullAssign() {
    _assertFalse("a ??= b;");
  }

  void test_ifNullAssign_rhs() {
    _assertFalse("a ??= throw '';");
  }

  void test_indexExpression() {
    _assertFalse("a[b];");
  }

  void test_indexExpression_index() {
    _assertTrue("a[throw ''];");
  }

  void test_indexExpression_target() {
    _assertTrue("throw ''[b];");
  }

  void test_instanceCreationExpression() {
    _assertFalse("new A(b);");
  }

  void test_instanceCreationExpression_argumentThrows() {
    _assertTrue("new A(throw '');");
  }

  void test_isExpression() {
    _assertFalse("A is B;");
  }

  void test_isExpression_throws() {
    _assertTrue("throw '' is B;");
  }

  void test_labeledStatement() {
    _assertFalse("label: a;");
  }

  void test_labeledStatement_throws() {
    _assertTrue("label: throw '';");
  }

  void test_literal_boolean() {
    _assertFalse("true;");
  }

  void test_literal_double() {
    _assertFalse("1.1;");
  }

  void test_literal_integer() {
    _assertFalse("1;");
  }

  void test_literal_null() {
    _assertFalse("null;");
  }

  void test_literal_String() {
    _assertFalse("'str';");
  }

  void test_methodInvocation() {
    _assertFalse("a.b(c);");
  }

  void test_methodInvocation_argument() {
    _assertTrue("a.b(throw '');");
  }

  void test_methodInvocation_target() {
    _assertTrue("throw ''.b(c);");
  }

  void test_parenthesizedExpression() {
    _assertFalse("(a);");
  }

  void test_parenthesizedExpression_throw() {
    _assertTrue("(throw '');");
  }

  void test_propertyAccess() {
    _assertFalse("new Object().a;");
  }

  void test_propertyAccess_throws() {
    _assertTrue("(throw '').a;");
  }

  void test_rethrow() {
    _assertTrue("rethrow;");
  }

  void test_return() {
    _assertTrue("return 0;");
  }

  void test_superExpression() {
    _assertFalse("super.a;");
  }

  void test_switch_allReturn() {
    _assertTrue("switch (i) { case 0: return 0; default: return 1; }");
  }

  void test_switch_defaultWithNoStatements() {
    _assertFalse("switch (i) { case 0: return 0; default: }");
  }

  void test_switch_fallThroughToNotReturn() {
    _assertFalse("switch (i) { case 0: case 1: break; default: return 1; }");
  }

  void test_switch_fallThroughToReturn() {
    _assertTrue("switch (i) { case 0: case 1: return 0; default: return 1; }");
  }

  // The ExitDetector could conceivably follow switch continue labels and
  // determine that `case 0` exits, `case 1` continues to an exiting case, and
  // `default` exits, so the switch exits.
  @failingTest
  void test_switch_includesContinue() {
    _assertTrue('''
switch (i) {
  zero: case 0: return 0;
  case 1: continue zero;
  default: return 1;
}''');
  }

  void test_switch_noDefault() {
    _assertFalse("switch (i) { case 0: return 0; }");
  }

  void test_switch_nonReturn() {
    _assertFalse("switch (i) { case 0: i++; default: return 1; }");
  }

  void test_thisExpression() {
    _assertFalse("this.a;");
  }

  void test_throwExpression() {
    _assertTrue("throw new Object();");
  }

  void test_tryStatement_noReturn() {
    _assertFalse("try {} catch (e, s) {} finally {}");
  }

  void test_tryStatement_noReturn_noFinally() {
    _assertFalse("try {} catch (e, s) {}");
  }

  void test_tryStatement_return_catch() {
    _assertFalse("try {} catch (e, s) { return 1; } finally {}");
  }

  void test_tryStatement_return_catch_noFinally() {
    _assertFalse("try {} catch (e, s) { return 1; }");
  }

  void test_tryStatement_return_finally() {
    _assertTrue("try {} catch (e, s) {} finally { return 1; }");
  }

  void test_tryStatement_return_try_noCatch() {
    _assertTrue("try { return 1; } finally {}");
  }

  void test_tryStatement_return_try_oneCatchDoesNotExit() {
    _assertFalse("try { return 1; } catch (e, s) {} finally {}");
  }

  void test_tryStatement_return_try_oneCatchDoesNotExit_noFinally() {
    _assertFalse("try { return 1; } catch (e, s) {}");
  }

  void test_tryStatement_return_try_oneCatchExits() {
    _assertTrue("try { return 1; } catch (e, s) { return 1; } finally {}");
  }

  void test_tryStatement_return_try_oneCatchExits_noFinally() {
    _assertTrue("try { return 1; } catch (e, s) { return 1; }");
  }

  void test_tryStatement_return_try_twoCatchesDoExit() {
    _assertTrue('''
try { return 1; }
on int catch (e, s) { return 1; }
on String catch (e, s) { return 1; }
finally {}''');
  }

  void test_tryStatement_return_try_twoCatchesDoExit_noFinally() {
    _assertTrue('''
try { return 1; }
on int catch (e, s) { return 1; }
on String catch (e, s) { return 1; }''');
  }

  void test_tryStatement_return_try_twoCatchesDoNotExit() {
    _assertFalse('''
try { return 1; }
on int catch (e, s) {}
on String catch (e, s) {}
finally {}''');
  }

  void test_tryStatement_return_try_twoCatchesDoNotExit_noFinally() {
    _assertFalse('''
try { return 1; }
on int catch (e, s) {}
on String catch (e, s) {}''');
  }

  void test_tryStatement_return_try_twoCatchesMixed() {
    _assertFalse('''
try { return 1; }
on int catch (e, s) {}
on String catch (e, s) { return 1; }
finally {}''');
  }

  void test_tryStatement_return_try_twoCatchesMixed_noFinally() {
    _assertFalse('''
try { return 1; }
on int catch (e, s) {}
on String catch (e, s) { return 1; }''');
  }

  void test_variableDeclarationStatement_noInitializer() {
    _assertFalse("int i;");
  }

  void test_variableDeclarationStatement_noThrow() {
    _assertFalse("int i = 0;");
  }

  void test_variableDeclarationStatement_throw() {
    _assertTrue("int i = throw new Object();");
  }

  void test_whileStatement_false_nonReturn() {
    _assertFalse("{ while (false) {} }");
  }

  void test_whileStatement_throwCondition() {
    _assertTrue("{ while (throw '') {} }");
  }

  void test_whileStatement_true_break() {
    _assertFalse("{ while (true) { break; } }");
  }

  void test_whileStatement_true_continue() {
    _assertTrue("{ while (true) { continue; } }");
  }

  void test_whileStatement_true_continueWithLabel() {
    _assertTrue("{ x: while (true) { continue x; } }");
  }

  void test_whileStatement_true_doStatement_scopeRequired() {
    _assertTrue("{ while (true) { x: do { continue x; } while (true); } }");
  }

  void test_whileStatement_true_if_return() {
    _assertTrue("{ while (true) { if (true) {return null;} } }");
  }

  void test_whileStatement_true_noBreak() {
    _assertTrue("{ while (true) {} }");
  }

  void test_whileStatement_true_return() {
    _assertTrue("{ while (true) { return null; } }");
  }

  void test_whileStatement_true_throw() {
    _assertTrue("{ while (true) { throw ''; } }");
  }

  void test_whileStatement_true_break_and_throw() {
    _assertFalse("{ while (true) { if (1==1) break; throw 'T'; } }");
  }

  void _assertFalse(String source) {
    _assertHasReturn(false, source);
  }

  void _assertHasReturn(bool expectedResult, String source) {
    Statement statement = ParserTestCase.parseStatement(source);
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
  void test_forStatement_implicitTrue_breakWithLabel() {
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

  void test_switch_withEnum_false_noDefault() {
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

  void test_switch_withEnum_false_withDefault() {
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

  void test_switch_withEnum_true_noDefault() {
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

  void test_switch_withEnum_true_withExitingDefault() {
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

  void test_switch_withEnum_true_withNonExitingDefault() {
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

  void test_whileStatement_breakWithLabel() {
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

  void test_whileStatement_switchWithBreakWithLabel() {
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

  void test_whileStatement_breakWithLabel_afterExting() {
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

  void test_yieldStatement_plain() {
    Source source = addSource(r'''
void f() sync* {
  yield 1;
}
''');
    _assertNthStatementDoesNotExit(source, 0);
  }

  void test_yieldStatement_star_plain() {
    Source source = addSource(r'''
void f() sync* {
  yield* 1;
}
''');
    _assertNthStatementDoesNotExit(source, 0);
  }

  void test_yieldStatement_star_throw() {
    Source source = addSource(r'''
void f() sync* {
  yield* throw '';
}
''');
    _assertNthStatementExits(source, 0);
  }

  void test_yieldStatement_throw() {
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
  void test_equals_false_differentFiles() {
    JavaFile file1 = FileUtilities2.createFile("/does/not/exist1.dart");
    JavaFile file2 = FileUtilities2.createFile("/does/not/exist2.dart");
    FileBasedSource source1 = new FileBasedSource(file1);
    FileBasedSource source2 = new FileBasedSource(file2);
    expect(source1 == source2, isFalse);
  }

  void test_equals_false_null() {
    JavaFile file = FileUtilities2.createFile("/does/not/exist1.dart");
    FileBasedSource source1 = new FileBasedSource(file);
    expect(source1 == null, isFalse);
  }

  void test_equals_true() {
    JavaFile file1 = FileUtilities2.createFile("/does/not/exist.dart");
    JavaFile file2 = FileUtilities2.createFile("/does/not/exist.dart");
    FileBasedSource source1 = new FileBasedSource(file1);
    FileBasedSource source2 = new FileBasedSource(file2);
    expect(source1 == source2, isTrue);
  }

  void test_fileReadMode() {
    expect(FileBasedSource.fileReadMode('a'), 'a');
    expect(FileBasedSource.fileReadMode('a\n'), 'a\n');
    expect(FileBasedSource.fileReadMode('ab'), 'ab');
    expect(FileBasedSource.fileReadMode('abc'), 'abc');
    expect(FileBasedSource.fileReadMode('a\nb'), 'a\nb');
    expect(FileBasedSource.fileReadMode('a\rb'), 'a\rb');
    expect(FileBasedSource.fileReadMode('a\r\nb'), 'a\r\nb');
  }

  void test_fileReadMode_changed() {
    FileBasedSource.fileReadMode = (String s) => s + 'xyz';
    expect(FileBasedSource.fileReadMode('a'), 'axyz');
    expect(FileBasedSource.fileReadMode('a\n'), 'a\nxyz');
    expect(FileBasedSource.fileReadMode('ab'), 'abxyz');
    expect(FileBasedSource.fileReadMode('abc'), 'abcxyz');
    FileBasedSource.fileReadMode = (String s) => s;
  }

  void test_fileReadMode_normalize_eol_always() {
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

  void test_getEncoding() {
    SourceFactory factory = new SourceFactory(
        [new ResourceUriResolver(PhysicalResourceProvider.INSTANCE)]);
    String fullPath = "/does/not/exist.dart";
    JavaFile file = FileUtilities2.createFile(fullPath);
    FileBasedSource source = new FileBasedSource(file);
    expect(factory.fromEncoding(source.encoding), source);
  }

  void test_getFullName() {
    String fullPath = "/does/not/exist.dart";
    JavaFile file = FileUtilities2.createFile(fullPath);
    FileBasedSource source = new FileBasedSource(file);
    expect(source.fullName, file.getAbsolutePath());
  }

  void test_getShortName() {
    JavaFile file = FileUtilities2.createFile("/does/not/exist.dart");
    FileBasedSource source = new FileBasedSource(file);
    expect(source.shortName, "exist.dart");
  }

  void test_hashCode() {
    JavaFile file1 = FileUtilities2.createFile("/does/not/exist.dart");
    JavaFile file2 = FileUtilities2.createFile("/does/not/exist.dart");
    FileBasedSource source1 = new FileBasedSource(file1);
    FileBasedSource source2 = new FileBasedSource(file2);
    expect(source2.hashCode, source1.hashCode);
  }

  void test_isInSystemLibrary_contagious() {
    JavaFile sdkDirectory = DirectoryBasedDartSdk.defaultSdkDirectory;
    expect(sdkDirectory, isNotNull);
    DartSdk sdk = new DirectoryBasedDartSdk(sdkDirectory);
    UriResolver resolver = new DartUriResolver(sdk);
    SourceFactory factory = new SourceFactory([resolver]);
    // resolve dart:core
    Source result =
        resolver.resolveAbsolute(parseUriWithException("dart:core"));
    expect(result, isNotNull);
    expect(result.isInSystemLibrary, isTrue);
    // system libraries reference only other system libraries
    Source partSource = factory.resolveUri(result, "num.dart");
    expect(partSource, isNotNull);
    expect(partSource.isInSystemLibrary, isTrue);
  }

  void test_isInSystemLibrary_false() {
    JavaFile file = FileUtilities2.createFile("/does/not/exist.dart");
    FileBasedSource source = new FileBasedSource(file);
    expect(source, isNotNull);
    expect(source.fullName, file.getAbsolutePath());
    expect(source.isInSystemLibrary, isFalse);
  }

  void test_issue14500() {
    // see https://code.google.com/p/dart/issues/detail?id=14500
    FileBasedSource source = new FileBasedSource(
        FileUtilities2.createFile("/some/packages/foo:bar.dart"));
    expect(source, isNotNull);
    expect(source.exists(), isFalse);
  }

  void test_resolveRelative_file_fileName() {
    if (OSUtilities.isWindows()) {
      // On Windows, the URI that is produced includes a drive letter,
      // which I believe is not consistent across all machines that might run
      // this test.
      return;
    }
    JavaFile file = FileUtilities2.createFile("/a/b/test.dart");
    FileBasedSource source = new FileBasedSource(file);
    expect(source, isNotNull);
    Uri relative =
        resolveRelativeUri(source.uri, parseUriWithException("lib.dart"));
    expect(relative, isNotNull);
    expect(relative.toString(), "file:///a/b/lib.dart");
  }

  void test_resolveRelative_file_filePath() {
    if (OSUtilities.isWindows()) {
      // On Windows, the URI that is produced includes a drive letter,
      // which I believe is not consistent across all machines that might run
      // this test.
      return;
    }
    JavaFile file = FileUtilities2.createFile("/a/b/test.dart");
    FileBasedSource source = new FileBasedSource(file);
    expect(source, isNotNull);
    Uri relative =
        resolveRelativeUri(source.uri, parseUriWithException("c/lib.dart"));
    expect(relative, isNotNull);
    expect(relative.toString(), "file:///a/b/c/lib.dart");
  }

  void test_resolveRelative_file_filePathWithParent() {
    if (OSUtilities.isWindows()) {
      // On Windows, the URI that is produced includes a drive letter, which I
      // believe is not consistent across all machines that might run this test.
      return;
    }
    JavaFile file = FileUtilities2.createFile("/a/b/test.dart");
    FileBasedSource source = new FileBasedSource(file);
    expect(source, isNotNull);
    Uri relative =
        resolveRelativeUri(source.uri, parseUriWithException("../c/lib.dart"));
    expect(relative, isNotNull);
    expect(relative.toString(), "file:///a/c/lib.dart");
  }

  void test_system() {
    JavaFile file = FileUtilities2.createFile("/does/not/exist.dart");
    FileBasedSource source =
        new FileBasedSource(file, parseUriWithException("dart:core"));
    expect(source, isNotNull);
    expect(source.fullName, file.getAbsolutePath());
    expect(source.isInSystemLibrary, isTrue);
  }
}

@reflectiveTest
class ResolveRelativeUriTest {
  void test_resolveRelative_dart_dartUri() {
    Uri uri = parseUriWithException('dart:foo');
    Uri relative = resolveRelativeUri(uri, parseUriWithException('dart:bar'));
    expect(relative, isNotNull);
    expect(relative.toString(), 'dart:bar');
  }

  void test_resolveRelative_dart_fileName() {
    Uri uri = parseUriWithException("dart:test");
    Uri relative = resolveRelativeUri(uri, parseUriWithException("lib.dart"));
    expect(relative, isNotNull);
    expect(relative.toString(), "dart:test/lib.dart");
  }

  void test_resolveRelative_dart_filePath() {
    Uri uri = parseUriWithException("dart:test");
    Uri relative = resolveRelativeUri(uri, parseUriWithException("c/lib.dart"));
    expect(relative, isNotNull);
    expect(relative.toString(), "dart:test/c/lib.dart");
  }

  void test_resolveRelative_dart_filePathWithParent() {
    Uri uri = parseUriWithException("dart:test/b/test.dart");
    Uri relative =
        resolveRelativeUri(uri, parseUriWithException("../c/lib.dart"));
    expect(relative, isNotNull);
    expect(relative.toString(), "dart:test/c/lib.dart");
  }

  void test_resolveRelative_package_dartUri() {
    Uri uri = parseUriWithException('package:foo/bar.dart');
    Uri relative = resolveRelativeUri(uri, parseUriWithException('dart:test'));
    expect(relative, isNotNull);
    expect(relative.toString(), 'dart:test');
  }

  void test_resolveRelative_package_fileName() {
    Uri uri = parseUriWithException("package:b/test.dart");
    Uri relative = resolveRelativeUri(uri, parseUriWithException("lib.dart"));
    expect(relative, isNotNull);
    expect(relative.toString(), "package:b/lib.dart");
  }

  void test_resolveRelative_package_fileNameWithoutPackageName() {
    Uri uri = parseUriWithException("package:test.dart");
    Uri relative = resolveRelativeUri(uri, parseUriWithException("lib.dart"));
    expect(relative, isNotNull);
    expect(relative.toString(), "package:lib.dart");
  }

  void test_resolveRelative_package_filePath() {
    Uri uri = parseUriWithException("package:b/test.dart");
    Uri relative = resolveRelativeUri(uri, parseUriWithException("c/lib.dart"));
    expect(relative, isNotNull);
    expect(relative.toString(), "package:b/c/lib.dart");
  }

  void test_resolveRelative_package_filePathWithParent() {
    Uri uri = parseUriWithException("package:a/b/test.dart");
    Uri relative =
        resolveRelativeUri(uri, parseUriWithException("../c/lib.dart"));
    expect(relative, isNotNull);
    expect(relative.toString(), "package:a/c/lib.dart");
  }
}

@reflectiveTest
class SDKLibrariesReaderTest extends EngineTestCase {
  void test_readFrom_dart2js() {
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

  void test_readFrom_empty() {
    LibraryMap libraryMap = new SdkLibrariesReader(false)
        .readFromFile(FileUtilities2.createFile("/libs.dart"), "");
    expect(libraryMap, isNotNull);
    expect(libraryMap.size(), 0);
  }

  void test_readFrom_normal() {
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
  void test_fromEncoding() {
    expect(UriKind.fromEncoding(0x64), same(UriKind.DART_URI));
    expect(UriKind.fromEncoding(0x66), same(UriKind.FILE_URI));
    expect(UriKind.fromEncoding(0x70), same(UriKind.PACKAGE_URI));
    expect(UriKind.fromEncoding(0x58), same(null));
  }

  void test_getEncoding() {
    expect(UriKind.DART_URI.encoding, 0x64);
    expect(UriKind.FILE_URI.encoding, 0x66);
    expect(UriKind.PACKAGE_URI.encoding, 0x70);
  }
}
