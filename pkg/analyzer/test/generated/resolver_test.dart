// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library engine.resolver_test;

import 'dart:collection';

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/element_resolver.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/java_engine_io.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/parser.dart' show ParserErrorCode;
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/sdk_io.dart' show DirectoryBasedDartSdk;
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/static_type_analyzer.dart';
import 'package:analyzer/src/generated/testing/ast_factory.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:unittest/unittest.dart';

import '../reflective_tests.dart';
import 'test_support.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(AnalysisDeltaTest);
  runReflectiveTests(ChangeSetTest);
  runReflectiveTests(EnclosedScopeTest);
  runReflectiveTests(LibraryImportScopeTest);
  runReflectiveTests(LibraryScopeTest);
  runReflectiveTests(ScopeTest);
  runReflectiveTests(ElementResolverTest);
  runReflectiveTests(InheritanceManagerTest);
  runReflectiveTests(LibraryElementBuilderTest);
  runReflectiveTests(LibraryResolver2Test);
  runReflectiveTests(LibraryResolverTest);
  runReflectiveTests(LibraryTest);
  runReflectiveTests(StaticTypeAnalyzerTest);
  runReflectiveTests(StaticTypeAnalyzer2Test);
  runReflectiveTests(SubtypeManagerTest);
  runReflectiveTests(TypeOverrideManagerTest);
  runReflectiveTests(TypeProviderImplTest);
  runReflectiveTests(TypeResolverVisitorTest);
  runReflectiveTests(CheckedModeCompileTimeErrorCodeTest);
  runReflectiveTests(ErrorResolverTest);
  runReflectiveTests(HintCodeTest);
  runReflectiveTests(MemberMapTest);
  runReflectiveTests(NonHintCodeTest);
  runReflectiveTests(SimpleResolverTest);
  runReflectiveTests(StrictModeTest);
  runReflectiveTests(TypePropagationTest);
}

/**
 * The class `AnalysisContextFactory` defines utility methods used to create analysis contexts
 * for testing purposes.
 */
class AnalysisContextFactory {
  static String _DART_MATH = "dart:math";

  static String _DART_INTERCEPTORS = "dart:_interceptors";

  static String _DART_JS_HELPER = "dart:_js_helper";

  /**
   * Create an analysis context that has a fake core library already resolved.
   *
   * @return the analysis context that was created
   */
  static AnalysisContextImpl contextWithCore() {
    AnalysisContextForTests context = new AnalysisContextForTests();
    return initContextWithCore(context);
  }

  /**
   * Create an analysis context that uses the given options and has a fake core library already
   * resolved.
   *
   * @param options the options to be applied to the context
   * @return the analysis context that was created
   */
  static AnalysisContextImpl
      contextWithCoreAndOptions(AnalysisOptions options) {
    AnalysisContextForTests context = new AnalysisContextForTests();
    context._internalSetAnalysisOptions(options);
    return initContextWithCore(context);
  }

  /**
   * Initialize the given analysis context with a fake core library already resolved.
   *
   * @param context the context to be initialized (not `null`)
   * @return the analysis context that was created
   */
  static AnalysisContextImpl initContextWithCore(AnalysisContextImpl context) {
    DirectoryBasedDartSdk sdk =
        new _AnalysisContextFactory_initContextWithCore(new JavaFile("/fake/sdk"));
    SourceFactory sourceFactory =
        new SourceFactory([new DartUriResolver(sdk), new FileUriResolver()]);
    context.sourceFactory = sourceFactory;
    AnalysisContext coreContext = sdk.context;
    //
    // dart:core
    //
    TestTypeProvider provider = new TestTypeProvider();
    CompilationUnitElementImpl coreUnit =
        new CompilationUnitElementImpl("core.dart");
    Source coreSource = sourceFactory.forUri(DartSdk.DART_CORE);
    coreContext.setContents(coreSource, "");
    coreUnit.source = coreSource;
    ClassElementImpl proxyClassElement = ElementFactory.classElement2("_Proxy");
    coreUnit.types = <ClassElement>[
        provider.boolType.element,
        provider.deprecatedType.element,
        provider.doubleType.element,
        provider.functionType.element,
        provider.intType.element,
        provider.listType.element,
        provider.mapType.element,
        provider.nullType.element,
        provider.numType.element,
        provider.objectType.element,
        proxyClassElement,
        provider.stackTraceType.element,
        provider.stringType.element,
        provider.symbolType.element,
        provider.typeType.element];
    coreUnit.functions = <FunctionElement>[
        ElementFactory.functionElement3(
            "identical",
            provider.boolType.element,
            <ClassElement>[provider.objectType.element, provider.objectType.element],
            null),
        ElementFactory.functionElement3(
            "print",
            VoidTypeImpl.instance.element,
            <ClassElement>[provider.objectType.element],
            null)];
    TopLevelVariableElement proxyTopLevelVariableElt =
        ElementFactory.topLevelVariableElement3(
            "proxy",
            true,
            false,
            proxyClassElement.type);
    TopLevelVariableElement deprecatedTopLevelVariableElt =
        ElementFactory.topLevelVariableElement3(
            "deprecated",
            true,
            false,
            provider.deprecatedType);
    coreUnit.accessors = <PropertyAccessorElement>[
        proxyTopLevelVariableElt.getter,
        proxyTopLevelVariableElt.setter,
        deprecatedTopLevelVariableElt.getter,
        deprecatedTopLevelVariableElt.setter];
    coreUnit.topLevelVariables = <TopLevelVariableElement>[
        proxyTopLevelVariableElt,
        deprecatedTopLevelVariableElt];
    LibraryElementImpl coreLibrary = new LibraryElementImpl.forNode(
        coreContext,
        AstFactory.libraryIdentifier2(["dart", "core"]));
    coreLibrary.definingCompilationUnit = coreUnit;
    //
    // dart:async
    //
    CompilationUnitElementImpl asyncUnit =
        new CompilationUnitElementImpl("async.dart");
    Source asyncSource = sourceFactory.forUri(DartSdk.DART_ASYNC);
    coreContext.setContents(asyncSource, "");
    asyncUnit.source = asyncSource;
    // Future
    ClassElementImpl futureElement =
        ElementFactory.classElement2("Future", ["T"]);
    InterfaceType futureType = futureElement.type;
    //   factory Future.value([value])
    ConstructorElementImpl futureConstructor =
        ElementFactory.constructorElement2(futureElement, "value");
    futureConstructor.parameters = <ParameterElement>[
        ElementFactory.positionalParameter2("value", provider.dynamicType)];
    futureConstructor.factory = true;
    (futureConstructor.type as FunctionTypeImpl).typeArguments =
        futureElement.type.typeArguments;
    futureElement.constructors = <ConstructorElement>[futureConstructor];
    //   Future then(onValue(T value), { Function onError });
    List<ParameterElement> parameters = <ParameterElement>[
        ElementFactory.requiredParameter2(
            "value",
            futureElement.typeParameters[0].type)];
    FunctionTypeAliasElementImpl aliasElement =
        new FunctionTypeAliasElementImpl.forNode(null);
    aliasElement.synthetic = true;
    aliasElement.shareParameters(parameters);
    aliasElement.returnType = provider.dynamicType;
    FunctionTypeImpl aliasType = new FunctionTypeImpl.con2(aliasElement);
    aliasElement.shareTypeParameters(futureElement.typeParameters);
    aliasType.typeArguments = futureElement.type.typeArguments;
    MethodElement thenMethod = ElementFactory.methodElementWithParameters(
        "then",
        futureElement.type.typeArguments,
        futureType,
        [
            ElementFactory.requiredParameter2("onValue", aliasType),
            ElementFactory.namedParameter2("onError", provider.functionType)]);
    futureElement.methods = <MethodElement>[thenMethod];
    // Completer
    ClassElementImpl completerElement =
        ElementFactory.classElement2("Completer", ["T"]);
    ConstructorElementImpl completerConstructor =
        ElementFactory.constructorElement2(completerElement, null);
    (completerConstructor.type as FunctionTypeImpl).typeArguments =
        completerElement.type.typeArguments;
    completerElement.constructors = <ConstructorElement>[completerConstructor];
    asyncUnit.types = <ClassElement>[
        completerElement,
        futureElement,
        ElementFactory.classElement2("Stream", ["T"])];
    LibraryElementImpl asyncLibrary = new LibraryElementImpl.forNode(
        coreContext,
        AstFactory.libraryIdentifier2(["dart", "async"]));
    asyncLibrary.definingCompilationUnit = asyncUnit;
    //
    // dart:html
    //
    CompilationUnitElementImpl htmlUnit =
        new CompilationUnitElementImpl("html_dartium.dart");
    Source htmlSource = sourceFactory.forUri(DartSdk.DART_HTML);
    coreContext.setContents(htmlSource, "");
    htmlUnit.source = htmlSource;
    ClassElementImpl elementElement = ElementFactory.classElement2("Element");
    InterfaceType elementType = elementElement.type;
    ClassElementImpl canvasElement =
        ElementFactory.classElement("CanvasElement", elementType);
    ClassElementImpl contextElement =
        ElementFactory.classElement2("CanvasRenderingContext");
    InterfaceType contextElementType = contextElement.type;
    ClassElementImpl context2dElement =
        ElementFactory.classElement("CanvasRenderingContext2D", contextElementType);
    canvasElement.methods = <MethodElement>[
        ElementFactory.methodElement(
            "getContext",
            contextElementType,
            [provider.stringType])];
    canvasElement.accessors = <PropertyAccessorElement>[
        ElementFactory.getterElement("context2D", false, context2dElement.type)];
    ClassElementImpl documentElement =
        ElementFactory.classElement("Document", elementType);
    ClassElementImpl htmlDocumentElement =
        ElementFactory.classElement("HtmlDocument", documentElement.type);
    htmlDocumentElement.methods = <MethodElement>[
        ElementFactory.methodElement(
            "query",
            elementType,
            <DartType>[provider.stringType])];
    htmlUnit.types = <ClassElement>[
        ElementFactory.classElement("AnchorElement", elementType),
        ElementFactory.classElement("BodyElement", elementType),
        ElementFactory.classElement("ButtonElement", elementType),
        canvasElement,
        contextElement,
        context2dElement,
        ElementFactory.classElement("DivElement", elementType),
        documentElement,
        elementElement,
        htmlDocumentElement,
        ElementFactory.classElement("InputElement", elementType),
        ElementFactory.classElement("SelectElement", elementType)];
    htmlUnit.functions = <FunctionElement>[
        ElementFactory.functionElement3(
            "query",
            elementElement,
            <ClassElement>[provider.stringType.element],
            ClassElementImpl.EMPTY_ARRAY)];
    TopLevelVariableElementImpl document =
        ElementFactory.topLevelVariableElement3(
            "document",
            false,
            true,
            htmlDocumentElement.type);
    htmlUnit.topLevelVariables = <TopLevelVariableElement>[document];
    htmlUnit.accessors = <PropertyAccessorElement>[document.getter];
    LibraryElementImpl htmlLibrary = new LibraryElementImpl.forNode(
        coreContext,
        AstFactory.libraryIdentifier2(["dart", "dom", "html"]));
    htmlLibrary.definingCompilationUnit = htmlUnit;
    //
    // dart:math
    //
    CompilationUnitElementImpl mathUnit =
        new CompilationUnitElementImpl("math.dart");
    Source mathSource = sourceFactory.forUri(_DART_MATH);
    coreContext.setContents(mathSource, "");
    mathUnit.source = mathSource;
    FunctionElement cosElement = ElementFactory.functionElement3(
        "cos",
        provider.doubleType.element,
        <ClassElement>[provider.numType.element],
        ClassElementImpl.EMPTY_ARRAY);
    TopLevelVariableElement ln10Element =
        ElementFactory.topLevelVariableElement3(
            "LN10",
            true,
            false,
            provider.doubleType);
    TopLevelVariableElement piElement = ElementFactory.topLevelVariableElement3(
        "PI",
        true,
        false,
        provider.doubleType);
    ClassElementImpl randomElement = ElementFactory.classElement2("Random");
    randomElement.abstract = true;
    ConstructorElementImpl randomConstructor =
        ElementFactory.constructorElement2(randomElement, null);
    randomConstructor.factory = true;
    ParameterElementImpl seedParam = new ParameterElementImpl("seed", 0);
    seedParam.parameterKind = ParameterKind.POSITIONAL;
    seedParam.type = provider.intType;
    randomConstructor.parameters = <ParameterElement>[seedParam];
    randomElement.constructors = <ConstructorElement>[randomConstructor];
    FunctionElement sinElement = ElementFactory.functionElement3(
        "sin",
        provider.doubleType.element,
        <ClassElement>[provider.numType.element],
        ClassElementImpl.EMPTY_ARRAY);
    FunctionElement sqrtElement = ElementFactory.functionElement3(
        "sqrt",
        provider.doubleType.element,
        <ClassElement>[provider.numType.element],
        ClassElementImpl.EMPTY_ARRAY);
    mathUnit.accessors =
        <PropertyAccessorElement>[ln10Element.getter, piElement.getter];
    mathUnit.functions = <FunctionElement>[cosElement, sinElement, sqrtElement];
    mathUnit.topLevelVariables =
        <TopLevelVariableElement>[ln10Element, piElement];
    mathUnit.types = <ClassElement>[randomElement];
    LibraryElementImpl mathLibrary = new LibraryElementImpl.forNode(
        coreContext,
        AstFactory.libraryIdentifier2(["dart", "math"]));
    mathLibrary.definingCompilationUnit = mathUnit;
    //
    // Set empty sources for the rest of the libraries.
    //
    Source source = sourceFactory.forUri(_DART_INTERCEPTORS);
    coreContext.setContents(source, "");
    source = sourceFactory.forUri(_DART_JS_HELPER);
    coreContext.setContents(source, "");
    //
    // Record the elements.
    //
    HashMap<Source, LibraryElement> elementMap =
        new HashMap<Source, LibraryElement>();
    elementMap[coreSource] = coreLibrary;
    elementMap[asyncSource] = asyncLibrary;
    elementMap[htmlSource] = htmlLibrary;
    elementMap[mathSource] = mathLibrary;
    context.recordLibraryElements(elementMap);
    return context;
  }
}

/**
 * Instances of the class `AnalysisContextForTests` implement an analysis context that has a
 * fake SDK that is much smaller and faster for testing purposes.
 */
class AnalysisContextForTests extends AnalysisContextImpl {
  @override
  void set analysisOptions(AnalysisOptions options) {
    AnalysisOptions currentOptions = analysisOptions;
    bool needsRecompute =
        currentOptions.analyzeFunctionBodies != options.analyzeFunctionBodies ||
        currentOptions.generateSdkErrors != options.generateSdkErrors ||
        currentOptions.enableAsync != options.enableAsync ||
        currentOptions.enableDeferredLoading != options.enableDeferredLoading ||
        currentOptions.enableEnum != options.enableEnum ||
        currentOptions.dart2jsHint != options.dart2jsHint ||
        (currentOptions.hint && !options.hint) ||
        currentOptions.preserveComments != options.preserveComments;
    if (needsRecompute) {
      fail(
          "Cannot set options that cause the sources to be reanalyzed in a test context");
    }
    super.analysisOptions = options;
  }

  @override
  bool exists(Source source) =>
      super.exists(source) || sourceFactory.dartSdk.context.exists(source);

  @override
  TimestampedData<String> getContents(Source source) {
    if (source.isInSystemLibrary) {
      return sourceFactory.dartSdk.context.getContents(source);
    }
    return super.getContents(source);
  }

  @override
  int getModificationStamp(Source source) {
    if (source.isInSystemLibrary) {
      return sourceFactory.dartSdk.context.getModificationStamp(source);
    }
    return super.getModificationStamp(source);
  }

  /**
   * Set the analysis options, even if they would force re-analysis. This method should only be
   * invoked before the fake SDK is initialized.
   *
   * @param options the analysis options to be set
   */
  void _internalSetAnalysisOptions(AnalysisOptions options) {
    super.analysisOptions = options;
  }
}

/**
 * Helper for creating and managing single [AnalysisContext].
 */
class AnalysisContextHelper {
  AnalysisContext context;

  /**
   * Creates new [AnalysisContext] using [AnalysisContextFactory.contextWithCore].
   */
  AnalysisContextHelper() {
    context = AnalysisContextFactory.contextWithCore();
    AnalysisOptionsImpl options =
        new AnalysisOptionsImpl.con1(context.analysisOptions);
    options.cacheSize = 256;
    context.analysisOptions = options;
  }

  Source addSource(String path, String code) {
    Source source = new FileBasedSource.con1(FileUtilities2.createFile(path));
    if (path.endsWith(".dart") || path.endsWith(".html")) {
      ChangeSet changeSet = new ChangeSet();
      changeSet.addedSource(source);
      context.applyChanges(changeSet);
    }
    context.setContents(source, code);
    return source;
  }

  CompilationUnitElement getDefiningUnitElement(Source source) =>
      context.getCompilationUnitElement(source, source);

  CompilationUnit resolveDefiningUnit(Source source) {
    LibraryElement libraryElement = context.computeLibraryElement(source);
    return context.resolveCompilationUnit(source, libraryElement);
  }

  void runTasks() {
    AnalysisResult result = context.performAnalysisTask();
    while (result.changeNotices != null) {
      result = context.performAnalysisTask();
    }
  }
}

class AnalysisDeltaTest extends EngineTestCase {
  TestSource source1 = new TestSource('/1.dart');
  TestSource source2 = new TestSource('/2.dart');
  TestSource source3 = new TestSource('/3.dart');

  void test_getAddedSources() {
    AnalysisDelta delta = new AnalysisDelta();
    delta.setAnalysisLevel(source1, AnalysisLevel.ALL);
    delta.setAnalysisLevel(source2, AnalysisLevel.ERRORS);
    delta.setAnalysisLevel(source3, AnalysisLevel.NONE);
    List<Source> addedSources = delta.addedSources;
    expect(addedSources, hasLength(2));
    expect(addedSources, unorderedEquals([source1, source2]));
  }

  void test_getAnalysisLevels() {
    AnalysisDelta delta = new AnalysisDelta();
    expect(delta.analysisLevels.length, 0);
  }

  void test_setAnalysisLevel() {
    AnalysisDelta delta = new AnalysisDelta();
    delta.setAnalysisLevel(source1, AnalysisLevel.ALL);
    delta.setAnalysisLevel(source2, AnalysisLevel.ERRORS);
    Map<Source, AnalysisLevel> levels = delta.analysisLevels;
    expect(levels.length, 2);
    expect(levels[source1], AnalysisLevel.ALL);
    expect(levels[source2], AnalysisLevel.ERRORS);
  }

  void test_toString() {
    AnalysisDelta delta = new AnalysisDelta();
    delta.setAnalysisLevel(new TestSource(), AnalysisLevel.ALL);
    String result = delta.toString();
    expect(result, isNotNull);
    expect(result.length > 0, isTrue);
  }
}

class ChangeSetTest extends EngineTestCase {
  void test_changedContent() {
    TestSource source = new TestSource();
    String content = "";
    ChangeSet changeSet = new ChangeSet();
    changeSet.changedContent(source, content);
    expect(changeSet.addedSources, hasLength(0));
    expect(changeSet.changedSources, hasLength(0));
    Map<Source, String> map = changeSet.changedContents;
    expect(map, hasLength(1));
    expect(map[source], same(content));
    expect(changeSet.changedRanges, hasLength(0));
    expect(changeSet.deletedSources, hasLength(0));
    expect(changeSet.removedSources, hasLength(0));
    expect(changeSet.removedContainers, hasLength(0));
  }

  void test_changedRange() {
    TestSource source = new TestSource();
    String content = "";
    ChangeSet changeSet = new ChangeSet();
    changeSet.changedRange(source, content, 1, 2, 3);
    expect(changeSet.addedSources, hasLength(0));
    expect(changeSet.changedSources, hasLength(0));
    expect(changeSet.changedContents, hasLength(0));
    Map<Source, ChangeSet_ContentChange> map = changeSet.changedRanges;
    expect(map, hasLength(1));
    ChangeSet_ContentChange change = map[source];
    expect(change, isNotNull);
    expect(change.contents, content);
    expect(change.offset, 1);
    expect(change.oldLength, 2);
    expect(change.newLength, 3);
    expect(changeSet.deletedSources, hasLength(0));
    expect(changeSet.removedSources, hasLength(0));
    expect(changeSet.removedContainers, hasLength(0));
  }

  void test_toString() {
    ChangeSet changeSet = new ChangeSet();
    changeSet.addedSource(new TestSource());
    changeSet.changedSource(new TestSource());
    changeSet.changedContent(new TestSource(), "");
    changeSet.changedRange(new TestSource(), "", 0, 0, 0);
    changeSet.deletedSource(new TestSource());
    changeSet.removedSource(new TestSource());
    changeSet.removedContainer(
        new SourceContainer_ChangeSetTest_test_toString());
    expect(changeSet.toString(), isNotNull);
  }
}

class CheckedModeCompileTimeErrorCodeTest extends ResolverTestCase {
  void test_fieldFormalParameterAssignableToField_extends() {
    // According to checked-mode type checking rules, a value of type B is
    // assignable to a field of type A, because B extends A (and hence is a
    // subtype of A).
    Source source = addSource(r'''
class A {
  const A();
}
class B extends A {
  const B();
}
class C {
  final A a;
  const C(this.a);
}
var v = const C(const B());''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_fieldFormalParameterAssignableToField_fieldType_unresolved_null() {
    // Null always passes runtime type checks, even when the type is
    // unresolved.
    Source source = addSource(r'''
class A {
  final Unresolved x;
  const A(String this.x);
}
var v = const A(null);''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.UNDEFINED_CLASS]);
    verify([source]);
  }

  void test_fieldFormalParameterAssignableToField_implements() {
    // According to checked-mode type checking rules, a value of type B is
    // assignable to a field of type A, because B implements A (and hence is a
    // subtype of A).
    Source source = addSource(r'''
class A {}
class B implements A {
  const B();
}
class C {
  final A a;
  const C(this.a);
}
var v = const C(const B());''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_fieldFormalParameterAssignableToField_list_dynamic() {
    // [1, 2, 3] has type List<dynamic>, which is a subtype of List<int>.
    Source source = addSource(r'''
class A {
  const A(List<int> x);
}
var x = const A(const [1, 2, 3]);''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_fieldFormalParameterAssignableToField_list_nonDynamic() {
    // <int>[1, 2, 3] has type List<int>, which is a subtype of List<num>.
    Source source = addSource(r'''
class A {
  const A(List<num> x);
}
var x = const A(const <int>[1, 2, 3]);''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_fieldFormalParameterAssignableToField_map_dynamic() {
    // {1: 2} has type Map<dynamic, dynamic>, which is a subtype of
    // Map<int, int>.
    Source source = addSource(r'''
class A {
  const A(Map<int, int> x);
}
var x = const A(const {1: 2});''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_fieldFormalParameterAssignableToField_map_keyDifferent() {
    // <int, int>{1: 2} has type Map<int, int>, which is a subtype of
    // Map<num, int>.
    Source source = addSource(r'''
class A {
  const A(Map<num, int> x);
}
var x = const A(const <int, int>{1: 2});''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_fieldFormalParameterAssignableToField_map_valueDifferent() {
    // <int, int>{1: 2} has type Map<int, int>, which is a subtype of
    // Map<int, num>.
    Source source = addSource(r'''
class A {
  const A(Map<int, num> x);
}
var x = const A(const <int, int>{1: 2});''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_fieldFormalParameterAssignableToField_notype() {
    // If a field is declared without a type, then any value may be assigned to
    // it.
    Source source = addSource(r'''
class A {
  final x;
  const A(this.x);
}
var v = const A(5);''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_fieldFormalParameterAssignableToField_null() {
    // Null is assignable to anything.
    Source source = addSource(r'''
class A {
  final int x;
  const A(this.x);
}
var v = const A(null);''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_fieldFormalParameterAssignableToField_typedef() {
    // foo has the runtime type dynamic -> dynamic, so it should be assignable
    // to A.f.
    Source source = addSource(r'''
typedef String Int2String(int x);
class A {
  final Int2String f;
  const A(this.f);
}
foo(x) => 1;
var v = const A(foo);''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_fieldFormalParameterAssignableToField_typeSubstitution() {
    // foo has the runtime type dynamic -> dynamic, so it should be assignable
    // to A.f.
    Source source = addSource(r'''
class A<T> {
  final T x;
  const A(this.x);
}
var v = const A<int>(3);''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_fieldFormalParameterNotAssignableToField() {
    Source source = addSource(r'''
class A {
  final int x;
  const A(this.x);
}
var v = const A('foo');''');
    resolve(source);
    assertErrors(
        source,
        [
            CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH,
            StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  void test_fieldFormalParameterNotAssignableToField_extends() {
    // According to checked-mode type checking rules, a value of type A is not
    // assignable to a field of type B, because B extends A (the subtyping
    // relationship is in the wrong direction).
    Source source = addSource(r'''
class A {
  const A();
}
class B extends A {
  const B();
}
class C {
  final B b;
  const C(this.b);
}
var v = const C(const A());''');
    resolve(source);
    assertErrors(
        source,
        [CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH]);
    verify([source]);
  }

  void test_fieldFormalParameterNotAssignableToField_fieldType() {
    Source source = addSource(r'''
class A {
  final int x;
  const A(String this.x);
}
var v = const A('foo');''');
    resolve(source);
    assertErrors(
        source,
        [
            CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH,
            StaticWarningCode.FIELD_INITIALIZING_FORMAL_NOT_ASSIGNABLE]);
    verify([source]);
  }

  void test_fieldFormalParameterNotAssignableToField_fieldType_unresolved() {
    Source source = addSource(r'''
class A {
  final Unresolved x;
  const A(String this.x);
}
var v = const A('foo');''');
    resolve(source);
    assertErrors(
        source,
        [
            CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH,
            StaticWarningCode.UNDEFINED_CLASS]);
    verify([source]);
  }

  void test_fieldFormalParameterNotAssignableToField_implements() {
    // According to checked-mode type checking rules, a value of type A is not
    // assignable to a field of type B, because B implements A (the subtyping
    // relationship is in the wrong direction).
    Source source = addSource(r'''
class A {
  const A();
}
class B implements A {}
class C {
  final B b;
  const C(this.b);
}
var v = const C(const A());''');
    resolve(source);
    assertErrors(
        source,
        [CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH]);
    verify([source]);
  }

  void test_fieldFormalParameterNotAssignableToField_list() {
    // <num>[1, 2, 3] has type List<num>, which is not a subtype of List<int>.
    Source source = addSource(r'''
class A {
  const A(List<int> x);
}
var x = const A(const <num>[1, 2, 3]);''');
    resolve(source);
    assertErrors(
        source,
        [CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH]);
    verify([source]);
  }

  void test_fieldFormalParameterNotAssignableToField_map_keyMismatch() {
    // <num, int>{1: 2} has type Map<num, int>, which is not a subtype of
    // Map<int, int>.
    Source source = addSource(r'''
class A {
  const A(Map<int, int> x);
}
var x = const A(const <num, int>{1: 2});''');
    resolve(source);
    assertErrors(
        source,
        [CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH]);
    verify([source]);
  }

  void test_fieldFormalParameterNotAssignableToField_map_valueMismatch() {
    // <int, num>{1: 2} has type Map<int, num>, which is not a subtype of
    // Map<int, int>.
    Source source = addSource(r'''
class A {
  const A(Map<int, int> x);
}
var x = const A(const <int, num>{1: 2});''');
    resolve(source);
    assertErrors(
        source,
        [CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH]);
    verify([source]);
  }

  void test_fieldFormalParameterNotAssignableToField_optional() {
    Source source = addSource(r'''
class A {
  final int x;
  const A([this.x = 'foo']);
}
var v = const A();''');
    resolve(source);
    assertErrors(
        source,
        [
            CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH,
            StaticTypeWarningCode.INVALID_ASSIGNMENT]);
    verify([source]);
  }

  void test_fieldFormalParameterNotAssignableToField_typedef() {
    // foo has the runtime type String -> int, so it should not be assignable
    // to A.f (A.f requires it to be int -> String).
    Source source = addSource(r'''
typedef String Int2String(int x);
class A {
  final Int2String f;
  const A(this.f);
}
int foo(String x) => 1;
var v = const A(foo);''');
    resolve(source);
    assertErrors(
        source,
        [
            CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH,
            StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  void test_fieldInitializerNotAssignable() {
    Source source = addSource(r'''
class A {
  final int x;
  const A() : x = '';
}''');
    resolve(source);
    assertErrors(
        source,
        [
            CheckedModeCompileTimeErrorCode.CONST_FIELD_INITIALIZER_NOT_ASSIGNABLE,
            StaticWarningCode.FIELD_INITIALIZER_NOT_ASSIGNABLE]);
    verify([source]);
  }

  void test_fieldTypeMismatch() {
    Source source = addSource(r'''
class A {
  const A(x) : y = x;
  final int y;
}
var v = const A('foo');''');
    resolve(source);
    assertErrors(
        source,
        [CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_FIELD_TYPE_MISMATCH]);
    verify([source]);
  }

  void test_fieldTypeMismatch_unresolved() {
    Source source = addSource(r'''
class A {
  const A(x) : y = x;
  final Unresolved y;
}
var v = const A('foo');''');
    resolve(source);
    assertErrors(
        source,
        [
            CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_FIELD_TYPE_MISMATCH,
            StaticWarningCode.UNDEFINED_CLASS]);
    verify([source]);
  }

  void test_fieldTypeOk_null() {
    Source source = addSource(r'''
class A {
  const A(x) : y = x;
  final int y;
}
var v = const A(null);''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_fieldTypeOk_unresolved_null() {
    // Null always passes runtime type checks, even when the type is
    // unresolved.
    Source source = addSource(r'''
class A {
  const A(x) : y = x;
  final Unresolved y;
}
var v = const A(null);''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.UNDEFINED_CLASS]);
    verify([source]);
  }

  void test_listElementTypeNotAssignable() {
    Source source = addSource("var v = const <String> [42];");
    resolve(source);
    assertErrors(
        source,
        [
            CheckedModeCompileTimeErrorCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE,
            StaticWarningCode.LIST_ELEMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  void test_mapKeyTypeNotAssignable() {
    Source source = addSource("var v = const <String, int > {1 : 2};");
    resolve(source);
    assertErrors(
        source,
        [
            CheckedModeCompileTimeErrorCode.MAP_KEY_TYPE_NOT_ASSIGNABLE,
            StaticWarningCode.MAP_KEY_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  void test_mapValueTypeNotAssignable() {
    Source source = addSource("var v = const <String, String> {'a' : 2};");
    resolve(source);
    assertErrors(
        source,
        [
            CheckedModeCompileTimeErrorCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE,
            StaticWarningCode.MAP_VALUE_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  void test_parameterAssignable_null() {
    // Null is assignable to anything.
    Source source = addSource(r'''
class A {
  const A(int x);
}
var v = const A(null);''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_parameterAssignable_typeSubstitution() {
    Source source = addSource(r'''
class A<T> {
  const A(T x);
}
var v = const A<int>(3);''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_parameterAssignable_undefined_null() {
    // Null always passes runtime type checks, even when the type is
    // unresolved.
    Source source = addSource(r'''
class A {
  const A(Unresolved x);
}
var v = const A(null);''');
    resolve(source);
    assertErrors(source, [StaticWarningCode.UNDEFINED_CLASS]);
    verify([source]);
  }

  void test_parameterNotAssignable() {
    Source source = addSource(r'''
class A {
  const A(int x);
}
var v = const A('foo');''');
    resolve(source);
    assertErrors(
        source,
        [
            CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH,
            StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  void test_parameterNotAssignable_typeSubstitution() {
    Source source = addSource(r'''
class A<T> {
  const A(T x);
}
var v = const A<int>('foo');''');
    resolve(source);
    assertErrors(
        source,
        [
            CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH,
            StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  void test_parameterNotAssignable_undefined() {
    Source source = addSource(r'''
class A {
  const A(Unresolved x);
}
var v = const A('foo');''');
    resolve(source);
    assertErrors(
        source,
        [
            CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH,
            StaticWarningCode.UNDEFINED_CLASS]);
    verify([source]);
  }

  void test_redirectingConstructor_paramTypeMismatch() {
    Source source = addSource(r'''
class A {
  const A.a1(x) : this.a2(x);
  const A.a2(String x);
}
var v = const A.a1(0);''');
    resolve(source);
    assertErrors(
        source,
        [CheckedModeCompileTimeErrorCode.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH]);
    verify([source]);
  }

  void test_topLevelVarAssignable_null() {
    Source source = addSource("const int x = null;");
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_topLevelVarAssignable_undefined_null() {
    // Null always passes runtime type checks, even when the type is
    // unresolved.
    Source source = addSource("const Unresolved x = null;");
    resolve(source);
    assertErrors(source, [StaticWarningCode.UNDEFINED_CLASS]);
    verify([source]);
  }

  void test_topLevelVarNotAssignable() {
    Source source = addSource("const int x = 'foo';");
    resolve(source);
    assertErrors(
        source,
        [
            CheckedModeCompileTimeErrorCode.VARIABLE_TYPE_MISMATCH,
            StaticTypeWarningCode.INVALID_ASSIGNMENT]);
    verify([source]);
  }

  void test_topLevelVarNotAssignable_undefined() {
    Source source = addSource("const Unresolved x = 'foo';");
    resolve(source);
    assertErrors(
        source,
        [
            CheckedModeCompileTimeErrorCode.VARIABLE_TYPE_MISMATCH,
            StaticWarningCode.UNDEFINED_CLASS]);
    verify([source]);
  }
}

class ElementResolverTest extends EngineTestCase {
  /**
   * The error listener to which errors will be reported.
   */
  GatheringErrorListener _listener;

  /**
   * The type provider used to access the types.
   */
  TestTypeProvider _typeProvider;

  /**
   * The library containing the code being resolved.
   */
  LibraryElementImpl _definingLibrary;

  /**
   * The resolver visitor that maintains the state for the resolver.
   */
  ResolverVisitor _visitor;

  /**
   * The resolver being used to resolve the test cases.
   */
  ElementResolver _resolver;

  void fail_visitExportDirective_combinators() {
    fail("Not yet tested");
    // Need to set up the exported library so that the identifier can be
    // resolved.
    ExportDirective directive =
        AstFactory.exportDirective2(null, [AstFactory.hideCombinator2(["A"])]);
    _resolveNode(directive);
    _listener.assertNoErrors();
  }

  void fail_visitFunctionExpressionInvocation() {
    fail("Not yet tested");
    _listener.assertNoErrors();
  }

  void fail_visitImportDirective_combinators_noPrefix() {
    fail("Not yet tested");
    // Need to set up the imported library so that the identifier can be
    // resolved.
    ImportDirective directive =
        AstFactory.importDirective3(null, null, [AstFactory.showCombinator2(["A"])]);
    _resolveNode(directive);
    _listener.assertNoErrors();
  }

  void fail_visitImportDirective_combinators_prefix() {
    fail("Not yet tested");
    // Need to set up the imported library so that the identifiers can be
    // resolved.
    String prefixName = "p";
    _definingLibrary.imports = <ImportElement>[
        ElementFactory.importFor(null, ElementFactory.prefix(prefixName))];
    ImportDirective directive = AstFactory.importDirective3(
        null,
        prefixName,
        [AstFactory.showCombinator2(["A"]), AstFactory.hideCombinator2(["B"])]);
    _resolveNode(directive);
    _listener.assertNoErrors();
  }

  void fail_visitRedirectingConstructorInvocation() {
    fail("Not yet tested");
    _listener.assertNoErrors();
  }

  @override
  void setUp() {
    _listener = new GatheringErrorListener();
    _typeProvider = new TestTypeProvider();
    _resolver = _createResolver();
  }

  void test_lookUpMethodInInterfaces() {
    InterfaceType intType = _typeProvider.intType;
    //
    // abstract class A { int operator[](int index); }
    //
    ClassElementImpl classA = ElementFactory.classElement2("A");
    MethodElement operator =
        ElementFactory.methodElement("[]", intType, [intType]);
    classA.methods = <MethodElement>[operator];
    //
    // class B implements A {}
    //
    ClassElementImpl classB = ElementFactory.classElement2("B");
    classB.interfaces = <InterfaceType>[classA.type];
    //
    // class C extends Object with B {}
    //
    ClassElementImpl classC = ElementFactory.classElement2("C");
    classC.mixins = <InterfaceType>[classB.type];
    //
    // class D extends C {}
    //
    ClassElementImpl classD = ElementFactory.classElement("D", classC.type);
    //
    // D a;
    // a[i];
    //
    SimpleIdentifier array = AstFactory.identifier3("a");
    array.staticType = classD.type;
    IndexExpression expression =
        AstFactory.indexExpression(array, AstFactory.identifier3("i"));
    expect(_resolveIndexExpression(expression), same(operator));
    _listener.assertNoErrors();
  }

  void test_visitAssignmentExpression_compound() {
    InterfaceType intType = _typeProvider.intType;
    SimpleIdentifier leftHandSide = AstFactory.identifier3("a");
    leftHandSide.staticType = intType;
    AssignmentExpression assignment = AstFactory.assignmentExpression(
        leftHandSide,
        TokenType.PLUS_EQ,
        AstFactory.integer(1));
    _resolveNode(assignment);
    expect(
        assignment.staticElement,
        same(getMethod(_typeProvider.numType, "+")));
    _listener.assertNoErrors();
  }

  void test_visitAssignmentExpression_simple() {
    AssignmentExpression expression = AstFactory.assignmentExpression(
        AstFactory.identifier3("x"),
        TokenType.EQ,
        AstFactory.integer(0));
    _resolveNode(expression);
    expect(expression.staticElement, isNull);
    _listener.assertNoErrors();
  }

  void test_visitBinaryExpression_bangEq() {
    // String i;
    // var j;
    // i == j
    InterfaceType stringType = _typeProvider.stringType;
    SimpleIdentifier left = AstFactory.identifier3("i");
    left.staticType = stringType;
    BinaryExpression expression = AstFactory.binaryExpression(
        left,
        TokenType.BANG_EQ,
        AstFactory.identifier3("j"));
    _resolveNode(expression);
    var stringElement = stringType.element;
    expect(expression.staticElement, isNotNull);
    expect(
        expression.staticElement,
        stringElement.lookUpMethod(TokenType.EQ_EQ.lexeme, stringElement.library));
    expect(expression.propagatedElement, isNull);
    _listener.assertNoErrors();
  }

  void test_visitBinaryExpression_eq() {
    // String i;
    // var j;
    // i == j
    InterfaceType stringType = _typeProvider.stringType;
    SimpleIdentifier left = AstFactory.identifier3("i");
    left.staticType = stringType;
    BinaryExpression expression = AstFactory.binaryExpression(
        left,
        TokenType.EQ_EQ,
        AstFactory.identifier3("j"));
    _resolveNode(expression);
    var stringElement = stringType.element;
    expect(
        expression.staticElement,
        stringElement.lookUpMethod(TokenType.EQ_EQ.lexeme, stringElement.library));
    expect(expression.propagatedElement, isNull);
    _listener.assertNoErrors();
  }

  void test_visitBinaryExpression_plus() {
    // num i;
    // var j;
    // i + j
    InterfaceType numType = _typeProvider.numType;
    SimpleIdentifier left = AstFactory.identifier3("i");
    left.staticType = numType;
    BinaryExpression expression =
        AstFactory.binaryExpression(left, TokenType.PLUS, AstFactory.identifier3("j"));
    _resolveNode(expression);
    expect(expression.staticElement, getMethod(numType, "+"));
    expect(expression.propagatedElement, isNull);
    _listener.assertNoErrors();
  }

  void test_visitBinaryExpression_plus_propagatedElement() {
    // var i = 1;
    // var j;
    // i + j
    InterfaceType numType = _typeProvider.numType;
    SimpleIdentifier left = AstFactory.identifier3("i");
    left.propagatedType = numType;
    BinaryExpression expression =
        AstFactory.binaryExpression(left, TokenType.PLUS, AstFactory.identifier3("j"));
    _resolveNode(expression);
    expect(expression.staticElement, isNull);
    expect(expression.propagatedElement, getMethod(numType, "+"));
    _listener.assertNoErrors();
  }

  void test_visitBreakStatement_withLabel() {
    // loop: while (true) {
    //   break loop;
    // }
    String label = "loop";
    LabelElementImpl labelElement =
        new LabelElementImpl(AstFactory.identifier3(label), false, false);
    BreakStatement breakStatement = AstFactory.breakStatement2(label);
    Expression condition = AstFactory.booleanLiteral(true);
    WhileStatement whileStatement =
        AstFactory.whileStatement(condition, breakStatement);
    expect(
        _resolveBreak(breakStatement, labelElement, whileStatement),
        same(labelElement));
    expect(breakStatement.target, same(whileStatement));
    _listener.assertNoErrors();
  }

  void test_visitBreakStatement_withoutLabel() {
    BreakStatement statement = AstFactory.breakStatement();
    _resolveStatement(statement, null, null);
    _listener.assertNoErrors();
  }

  void test_visitConstructorName_named() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String constructorName = "a";
    ConstructorElement constructor =
        ElementFactory.constructorElement2(classA, constructorName);
    classA.constructors = <ConstructorElement>[constructor];
    ConstructorName name =
        AstFactory.constructorName(AstFactory.typeName(classA), constructorName);
    _resolveNode(name);
    expect(name.staticElement, same(constructor));
    _listener.assertNoErrors();
  }

  void test_visitConstructorName_unnamed() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String constructorName = null;
    ConstructorElement constructor =
        ElementFactory.constructorElement2(classA, constructorName);
    classA.constructors = <ConstructorElement>[constructor];
    ConstructorName name =
        AstFactory.constructorName(AstFactory.typeName(classA), constructorName);
    _resolveNode(name);
    expect(name.staticElement, same(constructor));
    _listener.assertNoErrors();
  }

  void test_visitContinueStatement_withLabel() {
    // loop: while (true) {
    //   continue loop;
    // }
    String label = "loop";
    LabelElementImpl labelElement =
        new LabelElementImpl(AstFactory.identifier3(label), false, false);
    ContinueStatement continueStatement = AstFactory.continueStatement(label);
    Expression condition = AstFactory.booleanLiteral(true);
    WhileStatement whileStatement =
        AstFactory.whileStatement(condition, continueStatement);
    expect(
        _resolveContinue(continueStatement, labelElement, whileStatement),
        same(labelElement));
    expect(continueStatement.target, same(whileStatement));
    _listener.assertNoErrors();
  }

  void test_visitContinueStatement_withoutLabel() {
    ContinueStatement statement = AstFactory.continueStatement();
    _resolveStatement(statement, null, null);
    _listener.assertNoErrors();
  }

  void test_visitExportDirective_noCombinators() {
    ExportDirective directive = AstFactory.exportDirective2(null);
    directive.element = ElementFactory.exportFor(
        ElementFactory.library(_definingLibrary.context, "lib"));
    _resolveNode(directive);
    _listener.assertNoErrors();
  }

  void test_visitFieldFormalParameter() {
    String fieldName = "f";
    InterfaceType intType = _typeProvider.intType;
    FieldElementImpl fieldElement =
        ElementFactory.fieldElement(fieldName, false, false, false, intType);
    ClassElementImpl classA = ElementFactory.classElement2("A");
    classA.fields = <FieldElement>[fieldElement];
    FieldFormalParameter parameter =
        AstFactory.fieldFormalParameter2(fieldName);
    FieldFormalParameterElementImpl parameterElement =
        ElementFactory.fieldFormalParameter(parameter.identifier);
    parameterElement.field = fieldElement;
    parameterElement.type = intType;
    parameter.identifier.staticElement = parameterElement;
    _resolveInClass(parameter, classA);
    expect(parameter.element.type, same(intType));
  }

  void test_visitImportDirective_noCombinators_noPrefix() {
    ImportDirective directive = AstFactory.importDirective3(null, null);
    directive.element = ElementFactory.importFor(
        ElementFactory.library(_definingLibrary.context, "lib"),
        null);
    _resolveNode(directive);
    _listener.assertNoErrors();
  }

  void test_visitImportDirective_noCombinators_prefix() {
    String prefixName = "p";
    ImportElement importElement = ElementFactory.importFor(
        ElementFactory.library(_definingLibrary.context, "lib"),
        ElementFactory.prefix(prefixName));
    _definingLibrary.imports = <ImportElement>[importElement];
    ImportDirective directive = AstFactory.importDirective3(null, prefixName);
    directive.element = importElement;
    _resolveNode(directive);
    _listener.assertNoErrors();
  }

  void test_visitImportDirective_withCombinators() {
    ShowCombinator combinator = AstFactory.showCombinator2(["A", "B", "C"]);
    ImportDirective directive =
        AstFactory.importDirective3(null, null, [combinator]);
    LibraryElementImpl library =
        ElementFactory.library(_definingLibrary.context, "lib");
    TopLevelVariableElementImpl varA =
        ElementFactory.topLevelVariableElement2("A");
    TopLevelVariableElementImpl varB =
        ElementFactory.topLevelVariableElement2("B");
    TopLevelVariableElementImpl varC =
        ElementFactory.topLevelVariableElement2("C");
    CompilationUnitElementImpl unit =
        library.definingCompilationUnit as CompilationUnitElementImpl;
    unit.accessors =
        <PropertyAccessorElement>[varA.getter, varA.setter, varB.getter, varC.setter];
    unit.topLevelVariables = <TopLevelVariableElement>[varA, varB, varC];
    directive.element = ElementFactory.importFor(library, null);
    _resolveNode(directive);
    expect(combinator.shownNames[0].staticElement, same(varA));
    expect(combinator.shownNames[1].staticElement, same(varB));
    expect(combinator.shownNames[2].staticElement, same(varC));
    _listener.assertNoErrors();
  }

  void test_visitIndexExpression_get() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    InterfaceType intType = _typeProvider.intType;
    MethodElement getter =
        ElementFactory.methodElement("[]", intType, [intType]);
    classA.methods = <MethodElement>[getter];
    SimpleIdentifier array = AstFactory.identifier3("a");
    array.staticType = classA.type;
    IndexExpression expression =
        AstFactory.indexExpression(array, AstFactory.identifier3("i"));
    expect(_resolveIndexExpression(expression), same(getter));
    _listener.assertNoErrors();
  }

  void test_visitIndexExpression_set() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    InterfaceType intType = _typeProvider.intType;
    MethodElement setter =
        ElementFactory.methodElement("[]=", intType, [intType]);
    classA.methods = <MethodElement>[setter];
    SimpleIdentifier array = AstFactory.identifier3("a");
    array.staticType = classA.type;
    IndexExpression expression =
        AstFactory.indexExpression(array, AstFactory.identifier3("i"));
    AstFactory.assignmentExpression(
        expression,
        TokenType.EQ,
        AstFactory.integer(0));
    expect(_resolveIndexExpression(expression), same(setter));
    _listener.assertNoErrors();
  }

  void test_visitInstanceCreationExpression_named() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String constructorName = "a";
    ConstructorElement constructor =
        ElementFactory.constructorElement2(classA, constructorName);
    classA.constructors = <ConstructorElement>[constructor];
    ConstructorName name =
        AstFactory.constructorName(AstFactory.typeName(classA), constructorName);
    name.staticElement = constructor;
    InstanceCreationExpression creation =
        AstFactory.instanceCreationExpression(Keyword.NEW, name);
    _resolveNode(creation);
    expect(creation.staticElement, same(constructor));
    _listener.assertNoErrors();
  }

  void test_visitInstanceCreationExpression_unnamed() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String constructorName = null;
    ConstructorElement constructor =
        ElementFactory.constructorElement2(classA, constructorName);
    classA.constructors = <ConstructorElement>[constructor];
    ConstructorName name =
        AstFactory.constructorName(AstFactory.typeName(classA), constructorName);
    name.staticElement = constructor;
    InstanceCreationExpression creation =
        AstFactory.instanceCreationExpression(Keyword.NEW, name);
    _resolveNode(creation);
    expect(creation.staticElement, same(constructor));
    _listener.assertNoErrors();
  }

  void test_visitInstanceCreationExpression_unnamed_namedParameter() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String constructorName = null;
    ConstructorElementImpl constructor =
        ElementFactory.constructorElement2(classA, constructorName);
    String parameterName = "a";
    ParameterElement parameter = ElementFactory.namedParameter(parameterName);
    constructor.parameters = <ParameterElement>[parameter];
    classA.constructors = <ConstructorElement>[constructor];
    ConstructorName name =
        AstFactory.constructorName(AstFactory.typeName(classA), constructorName);
    name.staticElement = constructor;
    InstanceCreationExpression creation = AstFactory.instanceCreationExpression(
        Keyword.NEW,
        name,
        [AstFactory.namedExpression2(parameterName, AstFactory.integer(0))]);
    _resolveNode(creation);
    expect(creation.staticElement, same(constructor));
    expect(
        (creation.argumentList.arguments[0] as
            NamedExpression).name.label.staticElement,
        same(parameter));
    _listener.assertNoErrors();
  }

  void test_visitMethodInvocation() {
    InterfaceType numType = _typeProvider.numType;
    SimpleIdentifier left = AstFactory.identifier3("i");
    left.staticType = numType;
    String methodName = "abs";
    MethodInvocation invocation = AstFactory.methodInvocation(left, methodName);
    _resolveNode(invocation);
    expect(
        invocation.methodName.staticElement,
        same(getMethod(numType, methodName)));
    _listener.assertNoErrors();
  }

  void test_visitMethodInvocation_namedParameter() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    String parameterName = "p";
    MethodElementImpl method = ElementFactory.methodElement(methodName, null);
    ParameterElement parameter = ElementFactory.namedParameter(parameterName);
    method.parameters = <ParameterElement>[parameter];
    classA.methods = <MethodElement>[method];
    SimpleIdentifier left = AstFactory.identifier3("i");
    left.staticType = classA.type;
    MethodInvocation invocation = AstFactory.methodInvocation(
        left,
        methodName,
        [AstFactory.namedExpression2(parameterName, AstFactory.integer(0))]);
    _resolveNode(invocation);
    expect(invocation.methodName.staticElement, same(method));
    expect(
        (invocation.argumentList.arguments[0] as
            NamedExpression).name.label.staticElement,
        same(parameter));
    _listener.assertNoErrors();
  }

  void test_visitPostfixExpression() {
    InterfaceType numType = _typeProvider.numType;
    SimpleIdentifier operand = AstFactory.identifier3("i");
    operand.staticType = numType;
    PostfixExpression expression =
        AstFactory.postfixExpression(operand, TokenType.PLUS_PLUS);
    _resolveNode(expression);
    expect(expression.staticElement, getMethod(numType, "+"));
    _listener.assertNoErrors();
  }

  void test_visitPrefixedIdentifier_dynamic() {
    DartType dynamicType = _typeProvider.dynamicType;
    SimpleIdentifier target = AstFactory.identifier3("a");
    VariableElementImpl variable = ElementFactory.localVariableElement(target);
    variable.type = dynamicType;
    target.staticElement = variable;
    target.staticType = dynamicType;
    PrefixedIdentifier identifier =
        AstFactory.identifier(target, AstFactory.identifier3("b"));
    _resolveNode(identifier);
    expect(identifier.staticElement, isNull);
    expect(identifier.identifier.staticElement, isNull);
    _listener.assertNoErrors();
  }

  void test_visitPrefixedIdentifier_nonDynamic() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String getterName = "b";
    PropertyAccessorElement getter =
        ElementFactory.getterElement(getterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[getter];
    SimpleIdentifier target = AstFactory.identifier3("a");
    VariableElementImpl variable = ElementFactory.localVariableElement(target);
    variable.type = classA.type;
    target.staticElement = variable;
    target.staticType = classA.type;
    PrefixedIdentifier identifier =
        AstFactory.identifier(target, AstFactory.identifier3(getterName));
    _resolveNode(identifier);
    expect(identifier.staticElement, same(getter));
    expect(identifier.identifier.staticElement, same(getter));
    _listener.assertNoErrors();
  }

  void test_visitPrefixedIdentifier_staticClassMember_getter() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    // set accessors
    String propName = "b";
    PropertyAccessorElement getter =
        ElementFactory.getterElement(propName, false, _typeProvider.intType);
    PropertyAccessorElement setter =
        ElementFactory.setterElement(propName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[getter, setter];
    // prepare "A.m"
    SimpleIdentifier target = AstFactory.identifier3("A");
    target.staticElement = classA;
    target.staticType = classA.type;
    PrefixedIdentifier identifier =
        AstFactory.identifier(target, AstFactory.identifier3(propName));
    // resolve
    _resolveNode(identifier);
    expect(identifier.staticElement, same(getter));
    expect(identifier.identifier.staticElement, same(getter));
    _listener.assertNoErrors();
  }

  void test_visitPrefixedIdentifier_staticClassMember_method() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    // set accessors
    String propName = "m";
    PropertyAccessorElement setter =
        ElementFactory.setterElement(propName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[setter];
    // set methods
    MethodElement method =
        ElementFactory.methodElement("m", _typeProvider.intType);
    classA.methods = <MethodElement>[method];
    // prepare "A.m"
    SimpleIdentifier target = AstFactory.identifier3("A");
    target.staticElement = classA;
    target.staticType = classA.type;
    PrefixedIdentifier identifier =
        AstFactory.identifier(target, AstFactory.identifier3(propName));
    AstFactory.assignmentExpression(
        identifier,
        TokenType.EQ,
        AstFactory.nullLiteral());
    // resolve
    _resolveNode(identifier);
    expect(identifier.staticElement, same(method));
    expect(identifier.identifier.staticElement, same(method));
    _listener.assertNoErrors();
  }

  void test_visitPrefixedIdentifier_staticClassMember_setter() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    // set accessors
    String propName = "b";
    PropertyAccessorElement getter =
        ElementFactory.getterElement(propName, false, _typeProvider.intType);
    PropertyAccessorElement setter =
        ElementFactory.setterElement(propName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[getter, setter];
    // prepare "A.b = null"
    SimpleIdentifier target = AstFactory.identifier3("A");
    target.staticElement = classA;
    target.staticType = classA.type;
    PrefixedIdentifier identifier =
        AstFactory.identifier(target, AstFactory.identifier3(propName));
    AstFactory.assignmentExpression(
        identifier,
        TokenType.EQ,
        AstFactory.nullLiteral());
    // resolve
    _resolveNode(identifier);
    expect(identifier.staticElement, same(setter));
    expect(identifier.identifier.staticElement, same(setter));
    _listener.assertNoErrors();
  }

  void test_visitPrefixExpression() {
    InterfaceType numType = _typeProvider.numType;
    SimpleIdentifier operand = AstFactory.identifier3("i");
    operand.staticType = numType;
    PrefixExpression expression =
        AstFactory.prefixExpression(TokenType.PLUS_PLUS, operand);
    _resolveNode(expression);
    expect(expression.staticElement, getMethod(numType, "+"));
    _listener.assertNoErrors();
  }

  void test_visitPropertyAccess_getter_identifier() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String getterName = "b";
    PropertyAccessorElement getter =
        ElementFactory.getterElement(getterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[getter];
    SimpleIdentifier target = AstFactory.identifier3("a");
    target.staticType = classA.type;
    PropertyAccess access = AstFactory.propertyAccess2(target, getterName);
    _resolveNode(access);
    expect(access.propertyName.staticElement, same(getter));
    _listener.assertNoErrors();
  }

  void test_visitPropertyAccess_getter_super() {
    //
    // class A {
    //  int get b;
    // }
    // class B {
    //   ... super.m ...
    // }
    //
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String getterName = "b";
    PropertyAccessorElement getter =
        ElementFactory.getterElement(getterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[getter];
    SuperExpression target = AstFactory.superExpression();
    target.staticType = ElementFactory.classElement("B", classA.type).type;
    PropertyAccess access = AstFactory.propertyAccess2(target, getterName);
    AstFactory.methodDeclaration2(
        null,
        null,
        null,
        null,
        AstFactory.identifier3("m"),
        AstFactory.formalParameterList(),
        AstFactory.expressionFunctionBody(access));
    _resolveNode(access);
    expect(access.propertyName.staticElement, same(getter));
    _listener.assertNoErrors();
  }

  void test_visitPropertyAccess_setter_this() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String setterName = "b";
    PropertyAccessorElement setter =
        ElementFactory.setterElement(setterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[setter];
    ThisExpression target = AstFactory.thisExpression();
    target.staticType = classA.type;
    PropertyAccess access = AstFactory.propertyAccess2(target, setterName);
    AstFactory.assignmentExpression(
        access,
        TokenType.EQ,
        AstFactory.integer(0));
    _resolveNode(access);
    expect(access.propertyName.staticElement, same(setter));
    _listener.assertNoErrors();
  }

  void test_visitSimpleIdentifier_classScope() {
    InterfaceType doubleType = _typeProvider.doubleType;
    String fieldName = "NAN";
    SimpleIdentifier node = AstFactory.identifier3(fieldName);
    _resolveInClass(node, doubleType.element);
    expect(node.staticElement, getGetter(doubleType, fieldName));
    _listener.assertNoErrors();
  }

  void test_visitSimpleIdentifier_dynamic() {
    SimpleIdentifier node = AstFactory.identifier3("dynamic");
    _resolveIdentifier(node);
    expect(node.staticElement, same(_typeProvider.dynamicType.element));
    expect(node.staticType, same(_typeProvider.typeType));
    _listener.assertNoErrors();
  }

  void test_visitSimpleIdentifier_lexicalScope() {
    SimpleIdentifier node = AstFactory.identifier3("i");
    VariableElementImpl element = ElementFactory.localVariableElement(node);
    expect(_resolveIdentifier(node, [element]), same(element));
    _listener.assertNoErrors();
  }

  void test_visitSimpleIdentifier_lexicalScope_field_setter() {
    InterfaceType intType = _typeProvider.intType;
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String fieldName = "a";
    FieldElement field =
        ElementFactory.fieldElement(fieldName, false, false, false, intType);
    classA.fields = <FieldElement>[field];
    classA.accessors = <PropertyAccessorElement>[field.getter, field.setter];
    SimpleIdentifier node = AstFactory.identifier3(fieldName);
    AstFactory.assignmentExpression(node, TokenType.EQ, AstFactory.integer(0));
    _resolveInClass(node, classA);
    Element element = node.staticElement;
    EngineTestCase.assertInstanceOf(
        (obj) => obj is PropertyAccessorElement,
        PropertyAccessorElement,
        element);
    expect((element as PropertyAccessorElement).isSetter, isTrue);
    _listener.assertNoErrors();
  }

  void test_visitSuperConstructorInvocation() {
    ClassElementImpl superclass = ElementFactory.classElement2("A");
    ConstructorElementImpl superConstructor =
        ElementFactory.constructorElement2(superclass, null);
    superclass.constructors = <ConstructorElement>[superConstructor];
    ClassElementImpl subclass =
        ElementFactory.classElement("B", superclass.type);
    ConstructorElementImpl subConstructor =
        ElementFactory.constructorElement2(subclass, null);
    subclass.constructors = <ConstructorElement>[subConstructor];
    SuperConstructorInvocation invocation =
        AstFactory.superConstructorInvocation();
    _resolveInClass(invocation, subclass);
    expect(invocation.staticElement, superConstructor);
    _listener.assertNoErrors();
  }

  void test_visitSuperConstructorInvocation_namedParameter() {
    ClassElementImpl superclass = ElementFactory.classElement2("A");
    ConstructorElementImpl superConstructor =
        ElementFactory.constructorElement2(superclass, null);
    String parameterName = "p";
    ParameterElement parameter = ElementFactory.namedParameter(parameterName);
    superConstructor.parameters = <ParameterElement>[parameter];
    superclass.constructors = <ConstructorElement>[superConstructor];
    ClassElementImpl subclass =
        ElementFactory.classElement("B", superclass.type);
    ConstructorElementImpl subConstructor =
        ElementFactory.constructorElement2(subclass, null);
    subclass.constructors = <ConstructorElement>[subConstructor];
    SuperConstructorInvocation invocation =
        AstFactory.superConstructorInvocation(
            [AstFactory.namedExpression2(parameterName, AstFactory.integer(0))]);
    _resolveInClass(invocation, subclass);
    expect(invocation.staticElement, superConstructor);
    expect(
        (invocation.argumentList.arguments[0] as
            NamedExpression).name.label.staticElement,
        same(parameter));
    _listener.assertNoErrors();
  }

  /**
   * Create the resolver used by the tests.
   *
   * @return the resolver that was created
   */
  ElementResolver _createResolver() {
    AnalysisContextImpl context = new AnalysisContextImpl();
    SourceFactory sourceFactory =
        new SourceFactory([new DartUriResolver(DirectoryBasedDartSdk.defaultSdk)]);
    context.sourceFactory = sourceFactory;
    FileBasedSource source =
        new FileBasedSource.con1(FileUtilities2.createFile("/test.dart"));
    CompilationUnitElementImpl definingCompilationUnit =
        new CompilationUnitElementImpl("test.dart");
    definingCompilationUnit.source = source;
    _definingLibrary = ElementFactory.library(context, "test");
    _definingLibrary.definingCompilationUnit = definingCompilationUnit;
    Library library = new Library(context, _listener, source);
    library.libraryElement = _definingLibrary;
    _visitor = new ResolverVisitor.con1(library, source, _typeProvider);
    try {
      return _visitor.elementResolver_J2DAccessor as ElementResolver;
    } catch (exception) {
      throw new IllegalArgumentException(
          "Could not create resolver",
          exception);
    }
  }

  /**
   * Return the element associated with the label of [statement] after the
   * resolver has resolved it.  [labelElement] is the label element to be
   * defined in the statement's label scope, and [labelTarget] is the statement
   * the label resolves to.
   */
  Element _resolveBreak(BreakStatement statement, LabelElementImpl labelElement,
      Statement labelTarget) {
    _resolveStatement(statement, labelElement, labelTarget);
    return statement.label.staticElement;
  }

  /**
   * Return the element associated with the label [statement] after the
   * resolver has resolved it.  [labelElement] is the label element to be
   * defined in the statement's label scope, and [labelTarget] is the AST node
   * the label resolves to.
   *
   * @param statement the statement to be resolved
   * @param labelElement the label element to be defined in the statement's label scope
   * @return the element to which the statement's label was resolved
   */
  Element _resolveContinue(ContinueStatement statement,
      LabelElementImpl labelElement, AstNode labelTarget) {
    _resolveStatement(statement, labelElement, labelTarget);
    return statement.label.staticElement;
  }

  /**
   * Return the element associated with the given identifier after the resolver has resolved the
   * identifier.
   *
   * @param node the expression to be resolved
   * @param definedElements the elements that are to be defined in the scope in which the element is
   *          being resolved
   * @return the element to which the expression was resolved
   */
  Element _resolveIdentifier(Identifier node, [List<Element> definedElements]) {
    _resolveNode(node, definedElements);
    return node.staticElement;
  }

  /**
   * Return the element associated with the given identifier after the resolver has resolved the
   * identifier.
   *
   * @param node the expression to be resolved
   * @param enclosingClass the element representing the class enclosing the identifier
   * @return the element to which the expression was resolved
   */
  void _resolveInClass(AstNode node, ClassElement enclosingClass) {
    try {
      Scope outerScope = _visitor.nameScope_J2DAccessor as Scope;
      try {
        _visitor.enclosingClass = enclosingClass;
        EnclosedScope innerScope = new ClassScope(
            new TypeParameterScope(outerScope, enclosingClass),
            enclosingClass);
        _visitor.nameScope_J2DAccessor = innerScope;
        node.accept(_resolver);
      } finally {
        _visitor.enclosingClass = null;
        _visitor.nameScope_J2DAccessor = outerScope;
      }
    } catch (exception) {
      throw new IllegalArgumentException("Could not resolve node", exception);
    }
  }

  /**
   * Return the element associated with the given expression after the resolver has resolved the
   * expression.
   *
   * @param node the expression to be resolved
   * @param definedElements the elements that are to be defined in the scope in which the element is
   *          being resolved
   * @return the element to which the expression was resolved
   */
  Element _resolveIndexExpression(IndexExpression node,
      [List<Element> definedElements]) {
    _resolveNode(node, definedElements);
    return node.staticElement;
  }

  /**
   * Return the element associated with the given identifier after the resolver has resolved the
   * identifier.
   *
   * @param node the expression to be resolved
   * @param definedElements the elements that are to be defined in the scope in which the element is
   *          being resolved
   * @return the element to which the expression was resolved
   */
  void _resolveNode(AstNode node, [List<Element> definedElements]) {
    try {
      Scope outerScope = _visitor.nameScope_J2DAccessor as Scope;
      try {
        EnclosedScope innerScope = new EnclosedScope(outerScope);
        if (definedElements != null) {
          for (Element element in definedElements) {
            innerScope.define(element);
          }
        }
        _visitor.nameScope_J2DAccessor = innerScope;
        node.accept(_resolver);
      } finally {
        _visitor.nameScope_J2DAccessor = outerScope;
      }
    } catch (exception) {
      throw new IllegalArgumentException("Could not resolve node", exception);
    }
  }

  /**
   * Return the element associated with the label of the given statement after the resolver has
   * resolved the statement.
   *
   * @param statement the statement to be resolved
   * @param labelElement the label element to be defined in the statement's label scope
   * @return the element to which the statement's label was resolved
   */
  void _resolveStatement(Statement statement, LabelElementImpl labelElement,
      AstNode labelTarget) {
    try {
      LabelScope outerScope = _visitor.labelScope_J2DAccessor as LabelScope;
      try {
        LabelScope innerScope;
        if (labelElement == null) {
          innerScope = outerScope;
        } else {
          innerScope =
              new LabelScope(outerScope, labelElement.name, labelTarget, labelElement);
        }
        _visitor.labelScope_J2DAccessor = innerScope;
        statement.accept(_resolver);
      } finally {
        _visitor.labelScope_J2DAccessor = outerScope;
      }
    } catch (exception) {
      throw new IllegalArgumentException("Could not resolve node", exception);
    }
  }
}

class EnclosedScopeTest extends ResolverTestCase {
  void test_define_duplicate() {
    GatheringErrorListener listener = new GatheringErrorListener();
    Scope rootScope =
        new Scope_EnclosedScopeTest_test_define_duplicate(listener);
    EnclosedScope scope = new EnclosedScope(rootScope);
    VariableElement element1 =
        ElementFactory.localVariableElement(AstFactory.identifier3("v1"));
    VariableElement element2 =
        ElementFactory.localVariableElement(AstFactory.identifier3("v1"));
    scope.define(element1);
    scope.define(element2);
    listener.assertErrorsWithSeverities([ErrorSeverity.ERROR]);
  }

  void test_define_normal() {
    GatheringErrorListener listener = new GatheringErrorListener();
    Scope rootScope = new Scope_EnclosedScopeTest_test_define_normal(listener);
    EnclosedScope outerScope = new EnclosedScope(rootScope);
    EnclosedScope innerScope = new EnclosedScope(outerScope);
    VariableElement element1 =
        ElementFactory.localVariableElement(AstFactory.identifier3("v1"));
    VariableElement element2 =
        ElementFactory.localVariableElement(AstFactory.identifier3("v2"));
    outerScope.define(element1);
    innerScope.define(element2);
    listener.assertNoErrors();
  }
}

class ErrorResolverTest extends ResolverTestCase {
  void test_breakLabelOnSwitchMember() {
    Source source = addSource(r'''
class A {
  void m(int i) {
    switch (i) {
      l: case 0:
        break;
      case 1:
        break l;
    }
  }
}''');
    resolve(source);
    assertErrors(source, [ResolverErrorCode.BREAK_LABEL_ON_SWITCH_MEMBER]);
    verify([source]);
  }

  void test_continueLabelOnSwitch() {
    Source source = addSource(r'''
class A {
  void m(int i) {
    l: switch (i) {
      case 0:
        continue l;
    }
  }
}''');
    resolve(source);
    assertErrors(source, [ResolverErrorCode.CONTINUE_LABEL_ON_SWITCH]);
    verify([source]);
  }

  void test_enclosingElement_invalidLocalFunction() {
    Source source = addSource(r'''
class C {
  C() {
    int get x => 0;
  }
}''');
    LibraryElement library = resolve(source);
    expect(library, isNotNull);
    var unit = library.definingCompilationUnit;
    expect(unit, isNotNull);
    var types = unit.types;
    expect(types, isNotNull);
    expect(types, hasLength(1));
    var type = types[0];
    expect(type, isNotNull);
    var constructors = type.constructors;
    expect(constructors, isNotNull);
    expect(constructors, hasLength(1));
    ConstructorElement constructor = constructors[0];
    expect(constructor, isNotNull);
    List<FunctionElement> functions = constructor.functions;
    expect(functions, isNotNull);
    expect(functions, hasLength(1));
    expect(functions[0].enclosingElement, constructor);
    assertErrors(source, [ParserErrorCode.GETTER_IN_FUNCTION]);
  }
}

class HintCodeTest extends ResolverTestCase {
  void fail_deadCode_statementAfterRehrow() {
    Source source = addSource(r'''
f() {
  try {
    var one = 1;
  } catch (e) {
    rethrow;
    var two = 2;
  }
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void fail_deadCode_statementAfterThrow() {
    Source source = addSource(r'''
f() {
  var one = 1;
  throw 'Stop here';
  var two = 2;
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void fail_isInt() {
    Source source = addSource("var v = 1 is int;");
    resolve(source);
    assertErrors(source, [HintCode.IS_INT]);
    verify([source]);
  }

  void fail_isNotInt() {
    Source source = addSource("var v = 1 is! int;");
    resolve(source);
    assertErrors(source, [HintCode.IS_NOT_INT]);
    verify([source]);
  }

  void fail_overrideEqualsButNotHashCode() {
    Source source = addSource(r'''
class A {
  bool operator ==(x) {}
}''');
    resolve(source);
    assertErrors(source, [HintCode.OVERRIDE_EQUALS_BUT_NOT_HASH_CODE]);
    verify([source]);
  }

  void fail_unusedImport_as_equalPrefixes() {
    // See todo at ImportsVerifier.prefixElementMap.
    Source source = addSource(r'''
library L;
import 'lib1.dart' as one;
import 'lib2.dart' as one;
one.A a;''');
    Source source2 = addNamedSource("/lib1.dart", r'''
library lib1;
class A {}''');
    Source source3 = addNamedSource("/lib2.dart", r'''
library lib2;
class B {}''');
    resolve(source);
    assertErrors(source, [HintCode.UNUSED_IMPORT]);
    assertNoErrors(source2);
    assertNoErrors(source3);
    verify([source, source2, source3]);
  }

  void test_argumentTypeNotAssignable_functionType() {
    Source source = addSource(r'''
m() {
  var a = new A();
  a.n(() => 0);
}
class A {
  n(void f(int i)) {}
}''');
    resolve(source);
    assertErrors(source, [HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  void test_argumentTypeNotAssignable_message() {
    // The implementation of HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE assumes that
    // StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE has the same message.
    expect(
        StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE.message,
        HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE.message);
  }

  void test_argumentTypeNotAssignable_type() {
    Source source = addSource(r'''
m() {
  var i = '';
  n(i);
}
n(int i) {}''');
    resolve(source);
    assertErrors(source, [HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  void test_argumentTypeNotAssignable_unionTypeMethodMerge() {
    enableUnionTypes(false);
    Source source = addSource(r'''
class A {
  int m(int x) => 0;
}
class B {
  String m(String x) => '0';
}
f(A a, B b) {
  var ab;
  if (0 < 1) {
    ab = a;
  } else {
    ab = b;
  }
  ab.m(0.5);
}''');
    resolve(source);
    assertErrors(source, [HintCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
  }

  void test_deadCode_deadBlock_conditionalElse() {
    Source source = addSource(r'''
f() {
  true ? 1 : 2;
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_deadBlock_conditionalElse_nested() {
    // test that a dead else-statement can't generate additional violations
    Source source = addSource(r'''
f() {
  true ? true : false && false;
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_deadBlock_conditionalIf() {
    Source source = addSource(r'''
f() {
  false ? 1 : 2;
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_deadBlock_conditionalIf_nested() {
    // test that a dead then-statement can't generate additional violations
    Source source = addSource(r'''
f() {
  false ? false && false : true;
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_deadBlock_else() {
    Source source = addSource(r'''
f() {
  if(true) {} else {}
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_deadBlock_else_nested() {
    // test that a dead else-statement can't generate additional violations
    Source source = addSource(r'''
f() {
  if(true) {} else {if (false) {}}
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_deadBlock_if() {
    Source source = addSource(r'''
f() {
  if(false) {}
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_deadBlock_if_nested() {
    // test that a dead then-statement can't generate additional violations
    Source source = addSource(r'''
f() {
  if(false) {if(false) {}}
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_deadBlock_while() {
    Source source = addSource(r'''
f() {
  while(false) {}
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_deadBlock_while_nested() {
    // test that a dead while body can't generate additional violations
    Source source = addSource(r'''
f() {
  while(false) {if(false) {}}
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_deadCatch_catchFollowingCatch() {
    Source source = addSource(r'''
class A {}
f() {
  try {} catch (e) {} catch (e) {}
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEAD_CODE_CATCH_FOLLOWING_CATCH]);
    verify([source]);
  }

  void test_deadCode_deadCatch_catchFollowingCatch_nested() {
    // test that a dead catch clause can't generate additional violations
    Source source = addSource(r'''
class A {}
f() {
  try {} catch (e) {} catch (e) {if(false) {}}
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEAD_CODE_CATCH_FOLLOWING_CATCH]);
    verify([source]);
  }

  void test_deadCode_deadCatch_catchFollowingCatch_object() {
    Source source = addSource(r'''
f() {
  try {} on Object catch (e) {} catch (e) {}
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEAD_CODE_CATCH_FOLLOWING_CATCH]);
    verify([source]);
  }

  void test_deadCode_deadCatch_catchFollowingCatch_object_nested() {
    // test that a dead catch clause can't generate additional violations
    Source source = addSource(r'''
f() {
  try {} on Object catch (e) {} catch (e) {if(false) {}}
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEAD_CODE_CATCH_FOLLOWING_CATCH]);
    verify([source]);
  }

  void test_deadCode_deadCatch_onCatchSubtype() {
    Source source = addSource(r'''
class A {}
class B extends A {}
f() {
  try {} on A catch (e) {} on B catch (e) {}
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEAD_CODE_ON_CATCH_SUBTYPE]);
    verify([source]);
  }

  void test_deadCode_deadCatch_onCatchSubtype_nested() {
    // test that a dead catch clause can't generate additional violations
    Source source = addSource(r'''
class A {}
class B extends A {}
f() {
  try {} on A catch (e) {} on B catch (e) {if(false) {}}
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEAD_CODE_ON_CATCH_SUBTYPE]);
    verify([source]);
  }

  void test_deadCode_deadOperandLHS_and() {
    Source source = addSource(r'''
f() {
  bool b = false && false;
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_deadOperandLHS_and_nested() {
    Source source = addSource(r'''
f() {
  bool b = false && (false && false);
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_deadOperandLHS_or() {
    Source source = addSource(r'''
f() {
  bool b = true || true;
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_deadOperandLHS_or_nested() {
    Source source = addSource(r'''
f() {
  bool b = true || (false && false);
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_statementAfterBreak_inDefaultCase() {
    Source source = addSource(r'''
f(v) {
  switch(v) {
    case 1:
    default:
      break;
      var a;
  }
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_statementAfterBreak_inForEachStatement() {
    Source source = addSource(r'''
f() {
  var list;
  for(var l in list) {
    break;
    var a;
  }
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_statementAfterBreak_inForStatement() {
    Source source = addSource(r'''
f() {
  for(;;) {
    break;
    var a;
  }
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_statementAfterBreak_inSwitchCase() {
    Source source = addSource(r'''
f(v) {
  switch(v) {
    case 1:
      break;
      var a;
  }
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_statementAfterBreak_inWhileStatement() {
    Source source = addSource(r'''
f(v) {
  while(v) {
    break;
    var a;
  }
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_statementAfterContinue_inForEachStatement() {
    Source source = addSource(r'''
f() {
  var list;
  for(var l in list) {
    continue;
    var a;
  }
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_statementAfterContinue_inForStatement() {
    Source source = addSource(r'''
f() {
  for(;;) {
    continue;
    var a;
  }
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_statementAfterContinue_inWhileStatement() {
    Source source = addSource(r'''
f(v) {
  while(v) {
    continue;
    var a;
  }
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_statementAfterReturn_function() {
    Source source = addSource(r'''
f() {
  var one = 1;
  return;
  var two = 2;
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_statementAfterReturn_ifStatement() {
    Source source = addSource(r'''
f(bool b) {
  if(b) {
    var one = 1;
    return;
    var two = 2;
  }
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_statementAfterReturn_method() {
    Source source = addSource(r'''
class A {
  m() {
    var one = 1;
    return;
    var two = 2;
  }
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_statementAfterReturn_nested() {
    Source source = addSource(r'''
f() {
  var one = 1;
  return;
  if(false) {}
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deadCode_statementAfterReturn_twoReturns() {
    Source source = addSource(r'''
f() {
  var one = 1;
  return;
  var two = 2;
  return;
  var three = 3;
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEAD_CODE]);
    verify([source]);
  }

  void test_deprecatedAnnotationUse_assignment() {
    Source source = addSource(r'''
class A {
  @deprecated
  A operator+(A a) { return a; }
}
f(A a) {
  A b;
  a += b;
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEPRECATED_MEMBER_USE]);
    verify([source]);
  }

  void test_deprecatedAnnotationUse_Deprecated() {
    Source source = addSource(r'''
class A {
  @Deprecated('0.9')
  m() {}
  n() {m();}
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEPRECATED_MEMBER_USE]);
    verify([source]);
  }

  void test_deprecatedAnnotationUse_deprecated() {
    Source source = addSource(r'''
class A {
  @deprecated
  m() {}
  n() {m();}
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEPRECATED_MEMBER_USE]);
    verify([source]);
  }

  void test_deprecatedAnnotationUse_deprecatedMethodCalledOnUnionType() {
    enableUnionTypes(false);
    Source source = addSource(r'''
class A {
  @deprecated f() => 0;
}
class B extends A {}
main(A a, B b) {
  var x;
  if (0 < 1) {
    x = a;
  } else {
    x = b;
  }
  x.f(); // Here [x] has type [{A,B}] but we still want the deprecation warning.
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEPRECATED_MEMBER_USE]);
    verify([source]);
  }

  void test_deprecatedAnnotationUse_export() {
    Source source = addSource("export 'deprecated_library.dart';");
    addNamedSource("/deprecated_library.dart", r'''
@deprecated
library deprecated_library;
class A {}''');
    resolve(source);
    assertErrors(source, [HintCode.DEPRECATED_MEMBER_USE]);
    verify([source]);
  }

  void test_deprecatedAnnotationUse_getter() {
    Source source = addSource(r'''
class A {
  @deprecated
  get m => 1;
}
f(A a) {
  return a.m;
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEPRECATED_MEMBER_USE]);
    verify([source]);
  }

  void test_deprecatedAnnotationUse_import() {
    Source source = addSource(r'''
import 'deprecated_library.dart';
f(A a) {}''');
    addNamedSource("/deprecated_library.dart", r'''
@deprecated
library deprecated_library;
class A {}''');
    resolve(source);
    assertErrors(source, [HintCode.DEPRECATED_MEMBER_USE]);
    verify([source]);
  }

  void test_deprecatedAnnotationUse_indexExpression() {
    Source source = addSource(r'''
class A {
  @deprecated
  operator[](int i) {}
}
f(A a) {
  return a[1];
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEPRECATED_MEMBER_USE]);
    verify([source]);
  }

  void test_deprecatedAnnotationUse_instanceCreation() {
    Source source = addSource(r'''
class A {
  @deprecated
  A(int i) {}
}
f() {
  A a = new A(1);
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEPRECATED_MEMBER_USE]);
    verify([source]);
  }

  void test_deprecatedAnnotationUse_instanceCreation_namedConstructor() {
    Source source = addSource(r'''
class A {
  @deprecated
  A.named(int i) {}
}
f() {
  A a = new A.named(1);
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEPRECATED_MEMBER_USE]);
    verify([source]);
  }

  void test_deprecatedAnnotationUse_operator() {
    Source source = addSource(r'''
class A {
  @deprecated
  operator+(A a) {}
}
f(A a) {
  A b;
  return a + b;
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEPRECATED_MEMBER_USE]);
    verify([source]);
  }

  void test_deprecatedAnnotationUse_setter() {
    Source source = addSource(r'''
class A {
  @deprecated
  set s(v) {}
}
f(A a) {
  return a.s = 1;
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEPRECATED_MEMBER_USE]);
    verify([source]);
  }

  void test_deprecatedAnnotationUse_superConstructor() {
    Source source = addSource(r'''
class A {
  @deprecated
  A() {}
}
class B extends A {
  B() : super() {}
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEPRECATED_MEMBER_USE]);
    verify([source]);
  }

  void test_deprecatedAnnotationUse_superConstructor_namedConstructor() {
    Source source = addSource(r'''
class A {
  @deprecated
  A.named() {}
}
class B extends A {
  B() : super.named() {}
}''');
    resolve(source);
    assertErrors(source, [HintCode.DEPRECATED_MEMBER_USE]);
    verify([source]);
  }

  void test_divisionOptimization_double() {
    Source source = addSource(r'''
f(double x, double y) {
  var v = (x / y).toInt();
}''');
    resolve(source);
    assertErrors(source, [HintCode.DIVISION_OPTIMIZATION]);
    verify([source]);
  }

  void test_divisionOptimization_int() {
    Source source = addSource(r'''
f(int x, int y) {
  var v = (x / y).toInt();
}''');
    resolve(source);
    assertErrors(source, [HintCode.DIVISION_OPTIMIZATION]);
    verify([source]);
  }

  void test_divisionOptimization_propagatedType() {
    // Tests the propagated type information of the '/' method
    Source source = addSource(r'''
f(x, y) {
  x = 1;
  y = 1;
  var v = (x / y).toInt();
}''');
    resolve(source);
    assertErrors(source, [HintCode.DIVISION_OPTIMIZATION]);
    verify([source]);
  }

  void test_divisionOptimization_wrappedBinaryExpression() {
    Source source = addSource(r'''
f(int x, int y) {
  var v = (((x / y))).toInt();
}''');
    resolve(source);
    assertErrors(source, [HintCode.DIVISION_OPTIMIZATION]);
    verify([source]);
  }

  void test_duplicateImport() {
    Source source = addSource(r'''
library L;
import 'lib1.dart';
import 'lib1.dart';
A a;''');
    addNamedSource("/lib1.dart", r'''
library lib1;
class A {}''');
    resolve(source);
    assertErrors(source, [HintCode.DUPLICATE_IMPORT]);
    verify([source]);
  }

  void test_duplicateImport2() {
    Source source = addSource(r'''
library L;
import 'lib1.dart';
import 'lib1.dart';
import 'lib1.dart';
A a;''');
    addNamedSource("/lib1.dart", r'''
library lib1;
class A {}''');
    resolve(source);
    assertErrors(
        source,
        [HintCode.DUPLICATE_IMPORT, HintCode.DUPLICATE_IMPORT]);
    verify([source]);
  }

  void test_duplicateImport3() {
    Source source = addSource(r'''
library L;
import 'lib1.dart' as M show A hide B;
import 'lib1.dart' as M show A hide B;
M.A a;''');
    addNamedSource("/lib1.dart", r'''
library lib1;
class A {}
class B {}''');
    resolve(source);
    assertErrors(source, [HintCode.DUPLICATE_IMPORT]);
    verify([source]);
  }

  void test_importDeferredLibraryWithLoadFunction() {
    resolveWithAndWithoutExperimental(<String>[r'''
library lib1;
loadLibrary() {}
f() {}''', r'''
library root;
import 'lib1.dart' deferred as lib1;
main() { lib1.f(); }'''],
          <ErrorCode>[ParserErrorCode.DEFERRED_IMPORTS_NOT_SUPPORTED],
          <ErrorCode>[HintCode.IMPORT_DEFERRED_LIBRARY_WITH_LOAD_FUNCTION]);
  }

  void test_invalidAssignment_instanceVariable() {
    Source source = addSource(r'''
class A {
  int x;
}
f(var y) {
  A a;
  if(y is String) {
    a.x = y;
  }
}''');
    resolve(source);
    assertErrors(source, [HintCode.INVALID_ASSIGNMENT]);
    verify([source]);
  }

  void test_invalidAssignment_localVariable() {
    Source source = addSource(r'''
f(var y) {
  if(y is String) {
    int x = y;
  }
}''');
    resolve(source);
    assertErrors(source, [HintCode.INVALID_ASSIGNMENT]);
    verify([source]);
  }

  void test_invalidAssignment_message() {
    // The implementation of HintCode.INVALID_ASSIGNMENT assumes that
    // StaticTypeWarningCode.INVALID_ASSIGNMENT has the same message.
    expect(
        StaticTypeWarningCode.INVALID_ASSIGNMENT.message,
        HintCode.INVALID_ASSIGNMENT.message);
  }

  void test_invalidAssignment_staticVariable() {
    Source source = addSource(r'''
class A {
  static int x;
}
f(var y) {
  if(y is String) {
    A.x = y;
  }
}''');
    resolve(source);
    assertErrors(source, [HintCode.INVALID_ASSIGNMENT]);
    verify([source]);
  }

  void test_invalidAssignment_variableDeclaration() {
    // 17971
    Source source = addSource(r'''
class Point {
  final num x, y;
  Point(this.x, this.y);
  Point operator +(Point other) {
    return new Point(x+other.x, y+other.y);
  }
}
main() {
  var p1 = new Point(0, 0);
  var p2 = new Point(10, 10);
  int n = p1 + p2;
}''');
    resolve(source);
    assertErrors(source, [HintCode.INVALID_ASSIGNMENT]);
    verify([source]);
  }

  void test_isDouble() {
    Source source = addSource("var v = 1 is double;");
    resolve(source);
    assertErrors(source, [HintCode.IS_DOUBLE]);
    verify([source]);
  }

  void test_isNotDouble() {
    Source source = addSource("var v = 1 is! double;");
    resolve(source);
    assertErrors(source, [HintCode.IS_NOT_DOUBLE]);
    verify([source]);
  }

  void test_missingReturn_function() {
    Source source = addSource("int f() {}");
    resolve(source);
    assertErrors(source, [HintCode.MISSING_RETURN]);
    verify([source]);
  }

  void test_missingReturn_method() {
    Source source = addSource(r'''
class A {
  int m() {}
}''');
    resolve(source);
    assertErrors(source, [HintCode.MISSING_RETURN]);
    verify([source]);
  }

  void test_overrideOnNonOverridingGetter_invalid() {
    Source source = addSource(r'''
library dart.core;
const override = null;
class A {
}
class B extends A {
  @override
  int get m => 1;
}''');
    resolve(source);
    assertErrors(source, [HintCode.OVERRIDE_ON_NON_OVERRIDING_GETTER]);
    verify([source]);
  }

  void test_overrideOnNonOverridingMethod_invalid() {
    Source source = addSource(r'''
library dart.core;
const override = null;
class A {
}
class B extends A {
  @override
  int m() => 1;
}''');
    resolve(source);
    assertErrors(source, [HintCode.OVERRIDE_ON_NON_OVERRIDING_METHOD]);
    verify([source]);
  }

  void test_overrideOnNonOverridingSetter_invalid() {
    Source source = addSource(r'''
library dart.core;
const override = null;
class A {
}
class B extends A {
  @override
  set m(int x) {}
}''');
    resolve(source);
    assertErrors(source, [HintCode.OVERRIDE_ON_NON_OVERRIDING_SETTER]);
    verify([source]);
  }

  void test_typeCheck_type_is_Null() {
    Source source = addSource(r'''
m(i) {
  bool b = i is Null;
}''');
    resolve(source);
    assertErrors(source, [HintCode.TYPE_CHECK_IS_NULL]);
    verify([source]);
  }

  void test_typeCheck_type_not_Null() {
    Source source = addSource(r'''
m(i) {
  bool b = i is! Null;
}''');
    resolve(source);
    assertErrors(source, [HintCode.TYPE_CHECK_IS_NOT_NULL]);
    verify([source]);
  }

  void test_undefinedGetter() {
    Source source = addSource(r'''
class A {}
f(var a) {
  if(a is A) {
    return a.m;
  }
}''');
    resolve(source);
    assertErrors(source, [HintCode.UNDEFINED_GETTER]);
  }

  void test_undefinedGetter_message() {
    // The implementation of HintCode.UNDEFINED_SETTER assumes that
    // UNDEFINED_SETTER in StaticTypeWarningCode and StaticWarningCode are the
    // same, this verifies that assumption.
    expect(
        StaticWarningCode.UNDEFINED_GETTER.message,
        StaticTypeWarningCode.UNDEFINED_GETTER.message);
  }

  void test_undefinedMethod() {
    Source source = addSource(r'''
f() {
  var a = 'str';
  a.notAMethodOnString();
}''');
    resolve(source);
    assertErrors(source, [HintCode.UNDEFINED_METHOD]);
  }

  void test_undefinedMethod_assignmentExpression() {
    Source source = addSource(r'''
class A {}
class B {
  f(var a, var a2) {
    a = new A();
    a2 = new A();
    a += a2;
  }
}''');
    resolve(source);
    assertErrors(source, [HintCode.UNDEFINED_METHOD]);
  }

  void test_undefinedMethod_unionType_noSuchMethod() {
    enableUnionTypes(false);
    Source source = addSource(r'''
class A {
  int m(int x) => 0;
}
class B {
  String m() => '0';
}
f(A a, B b) {
  var ab;
  if (0 < 1) {
    ab = a;
  } else {
    ab = b;
  }
  ab.n();
}''');
    resolve(source);
    assertErrors(source, [HintCode.UNDEFINED_METHOD]);
  }

  void test_undefinedOperator_binaryExpression() {
    Source source = addSource(r'''
class A {}
f(var a) {
  if(a is A) {
    a + 1;
  }
}''');
    resolve(source);
    assertErrors(source, [HintCode.UNDEFINED_OPERATOR]);
  }

  void test_undefinedOperator_indexBoth() {
    Source source = addSource(r'''
class A {}
f(var a) {
  if(a is A) {
    a[0]++;
  }
}''');
    resolve(source);
    assertErrors(source, [HintCode.UNDEFINED_OPERATOR]);
  }

  void test_undefinedOperator_indexGetter() {
    Source source = addSource(r'''
class A {}
f(var a) {
  if(a is A) {
    a[0];
  }
}''');
    resolve(source);
    assertErrors(source, [HintCode.UNDEFINED_OPERATOR]);
  }

  void test_undefinedOperator_indexSetter() {
    Source source = addSource(r'''
class A {}
f(var a) {
  if(a is A) {
    a[0] = 1;
  }
}''');
    resolve(source);
    assertErrors(source, [HintCode.UNDEFINED_OPERATOR]);
  }

  void test_undefinedOperator_postfixExpression() {
    Source source = addSource(r'''
class A {}
f(var a) {
  if(a is A) {
    a++;
  }
}''');
    resolve(source);
    assertErrors(source, [HintCode.UNDEFINED_OPERATOR]);
  }

  void test_undefinedOperator_prefixExpression() {
    Source source = addSource(r'''
class A {}
f(var a) {
  if(a is A) {
    ++a;
  }
}''');
    resolve(source);
    assertErrors(source, [HintCode.UNDEFINED_OPERATOR]);
  }

  void test_undefinedSetter() {
    Source source = addSource(r'''
class A {}
f(var a) {
  if(a is A) {
    a.m = 0;
  }
}''');
    resolve(source);
    assertErrors(source, [HintCode.UNDEFINED_SETTER]);
  }

  void test_undefinedSetter_message() {
    // The implementation of HintCode.UNDEFINED_SETTER assumes that
    // UNDEFINED_SETTER in StaticTypeWarningCode and StaticWarningCode are the
    // same, this verifies that assumption.
    expect(
        StaticWarningCode.UNDEFINED_SETTER.message,
        StaticTypeWarningCode.UNDEFINED_SETTER.message);
  }

  void test_unnecessaryCast_type_supertype() {
    Source source = addSource(r'''
m(int i) {
  var b = i as Object;
}''');
    resolve(source);
    assertErrors(source, [HintCode.UNNECESSARY_CAST]);
    verify([source]);
  }

  void test_unnecessaryCast_type_type() {
    Source source = addSource(r'''
m(num i) {
  var b = i as num;
}''');
    resolve(source);
    assertErrors(source, [HintCode.UNNECESSARY_CAST]);
    verify([source]);
  }

  void test_unnecessaryTypeCheck_null_is_Null() {
    Source source = addSource("bool b = null is Null;");
    resolve(source);
    assertErrors(source, [HintCode.UNNECESSARY_TYPE_CHECK_TRUE]);
    verify([source]);
  }

  void test_unnecessaryTypeCheck_null_not_Null() {
    Source source = addSource("bool b = null is! Null;");
    resolve(source);
    assertErrors(source, [HintCode.UNNECESSARY_TYPE_CHECK_FALSE]);
    verify([source]);
  }

  void test_unnecessaryTypeCheck_type_is_dynamic() {
    Source source = addSource(r'''
m(i) {
  bool b = i is dynamic;
}''');
    resolve(source);
    assertErrors(source, [HintCode.UNNECESSARY_TYPE_CHECK_TRUE]);
    verify([source]);
  }

  void test_unnecessaryTypeCheck_type_is_object() {
    Source source = addSource(r'''
m(i) {
  bool b = i is Object;
}''');
    resolve(source);
    assertErrors(source, [HintCode.UNNECESSARY_TYPE_CHECK_TRUE]);
    verify([source]);
  }

  void test_unnecessaryTypeCheck_type_not_dynamic() {
    Source source = addSource(r'''
m(i) {
  bool b = i is! dynamic;
}''');
    resolve(source);
    assertErrors(source, [HintCode.UNNECESSARY_TYPE_CHECK_FALSE]);
    verify([source]);
  }

  void test_unnecessaryTypeCheck_type_not_object() {
    Source source = addSource(r'''
m(i) {
  bool b = i is! Object;
}''');
    resolve(source);
    assertErrors(source, [HintCode.UNNECESSARY_TYPE_CHECK_FALSE]);
    verify([source]);
  }

  void test_unusedElement_class_inClassMember() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class _A {
  static staticMethod() {
    new _A();
  }
  instanceMethod() {
    new _A();
  }
}
''');
    resolve(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  void test_unusedElement_class_inConstructorName() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class _A {
  _A() {}
  _A.named() {}
}
''');
    resolve(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  void test_unusedElement_class_isExpression() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class _A {}
main(p) {
  if (p is _A) {
  }
}
''');
    resolve(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  void test_unusedElement_class_isUsed_extends() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class _A {}
class B extends _A {}
''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_class_isUsed_implements() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class _A {}
class B implements _A {}
''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_class_isUsed_instanceCreation() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class _A {}
main() {
  new _A();
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_class_isUsed_staticFieldAccess() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class _A {
  static const F = 42;
}
main() {
  _A.F;
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_class_isUsed_staticMethodInvocation() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class _A {
  static m() {}
}
main() {
  _A.m();
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_class_noReference() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class _A {}
main() {
}''');
    resolve(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  void test_unusedElement_class_variableDeclaration() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class _A {}
main() {
  _A v;
  print(v);
}
print(x) {}
''');
    resolve(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  void test_unusedElement_functionLocal_isUsed_closure() {
    enableUnusedElement = true;
    Source source = addSource(r'''
main() {
  print(() {});
}
print(x) {}
''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_functionLocal_isUsed_invocation() {
    enableUnusedElement = true;
    Source source = addSource(r'''
main() {
  f() {}
  f();
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_functionLocal_isUsed_reference() {
    enableUnusedElement = true;
    Source source = addSource(r'''
main() {
  f() {}
  print(f);
}
print(x) {}
''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_functionLocal_notUsed_noReference() {
    enableUnusedElement = true;
    Source source = addSource(r'''
main() {
  f() {}
}''');
    resolve(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  void test_unusedElement_functionLocal_notUsed_referenceFromItself() {
    enableUnusedElement = true;
    Source source = addSource(r'''
main() {
  _f(int p) {
    _f(p - 1);
  }
}''');
    resolve(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  void test_unusedElement_functionTop_isUsed_invocation() {
    enableUnusedElement = true;
    Source source = addSource(r'''
_f() {}
main() {
  _f();
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_functionTop_isUsed_reference() {
    enableUnusedElement = true;
    Source source = addSource(r'''
_f() {}
main() {
  print(_f);
}
print(x) {}
''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_functionTop_notUsed_noReference() {
    enableUnusedElement = true;
    Source source = addSource(r'''
_f() {}
main() {
}''');
    resolve(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  void test_unusedElement_functionTop_notUsed_referenceFromItself() {
    enableUnusedElement = true;
    Source source = addSource(r'''
_f(int p) {
  _f(p - 1);
}
main() {
}''');
    resolve(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  void test_unusedElement_getter_isUsed_invocation_implicitThis() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  get _g => null;
  useGetter() {
    var v = _g;
  }
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_getter_isUsed_invocation_PrefixedIdentifier() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  get _g => null;
}
main(A a) {
  var v = a._g;
}
''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_getter_isUsed_invocation_PropertyAccess() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  get _g => null;
}
main() {
  var v = new A()._g;
}
''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_getter_notUsed_noReference() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  get _g => null;
}''');
    resolve(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  void test_unusedElement_getter_notUsed_referenceFromItself() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  get _g {
    return _g;
  }
}''');
    resolve(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  void test_unusedElement_method_isUsed_hasReference_implicitThis() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  _m() {}
  useMethod() {
    print(_m);
  }
}
print(x) {}
''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_method_isUsed_hasReference_implicitThis_subclass() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  _m() {}
  useMethod() {
    print(_m);
  }
}
class B extends A {
  _m() {}
}
print(x) {}
''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_method_isUsed_hasReference_PrefixedIdentifier() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  _m() {}
}
main(A a) {
  a._m;
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_method_isUsed_hasReference_PropertyAccess() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  _m() {}
}
main() {
  new A()._m;
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_method_isUsed_invocation_implicitThis() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  _m() {}
  useMethod() {
    _m();
  }
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_method_isUsed_invocation_implicitThis_subclass() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  _m() {}
  useMethod() {
    _m();
  }
}
class B extends A {
  _m() {}
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_method_isUsed_invocation_MemberElement() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A<T> {
  _m(T t) {}
}
main(A<int> a) {
  a._m(0);
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_method_isUsed_invocation_propagated() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  _m() {}
}
main() {
  var a = new A();
  a._m();
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_method_isUsed_invocation_static() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  _m() {}
}
main() {
  A a = new A();
  a._m();
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_method_isUsed_invocation_subclass() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  _m() {}
}
class B extends A {
  _m() {}
}
main(A a) {
  a._m();
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_method_isUsed_notPrivate() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  m() {}
}
main() {
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_method_isUsed_staticInvocation() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  static _m() {}
}
main() {
  A._m();
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_method_notUsed_noReference() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  static _m() {}
}''');
    resolve(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  void test_unusedElement_method_notUsed_referenceFromItself() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  static _m(int p) {
    _m(p - 1);
  }
}''');
    resolve(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  void test_unusedElement_setter_isUsed_invocation_implicitThis() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  set _s(x) {}
  useSetter() {
    _s = 42;
  }
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_setter_isUsed_invocation_PrefixedIdentifier() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  set _s(x) {}
}
main(A a) {
  a._s = 42;
}
''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_setter_isUsed_invocation_PropertyAccess() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  set _s(x) {}
}
main() {
  new A()._s = 42;
}
''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedElement_setter_notUsed_noReference() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  set _s(x) {}
}''');
    resolve(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  void test_unusedElement_setter_notUsed_referenceFromItself() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  set _s(int x) {
    if (x > 5) {
      _s = x - 1;
    }
  }
}''');
    resolve(source);
    assertErrors(source, [HintCode.UNUSED_ELEMENT]);
    verify([source]);
  }

  void test_unusedField_isUsed_argument() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  int _f = 0;
  main() {
    print(++_f);
  }
}
print(x) {}''');
    resolve(source);
    assertErrors(source);
    verify([source]);
  }

  void test_unusedField_isUsed_reference_implicitThis() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  int _f;
  main() {
    print(_f);
  }
}
print(x) {}''');
    resolve(source);
    assertErrors(source);
    verify([source]);
  }

  void test_unusedField_isUsed_reference_implicitThis_expressionFunctionBody() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  int _f;
  m() => _f;
}''');
    resolve(source);
    assertErrors(source);
    verify([source]);
  }

  void test_unusedField_isUsed_reference_implicitThis_subclass() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  int _f;
  main() {
    print(_f);
  }
}
class B extends A {
  int _f;
}
print(x) {}''');
    resolve(source);
    assertErrors(source);
    verify([source]);
  }

  void test_unusedField_isUsed_reference_qualified_propagatedElement() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  int _f;
}
main() {
  var a = new A();
  print(a._f);
}
print(x) {}''');
    resolve(source);
    assertErrors(source);
    verify([source]);
  }

  void test_unusedField_isUsed_reference_qualified_staticElement() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  int _f;
}
main() {
  A a = new A();
  print(a._f);
}
print(x) {}''');
    resolve(source);
    assertErrors(source);
    verify([source]);
  }

  void test_unusedField_isUsed_reference_qualified_unresolved() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  int _f;
}
main(a) {
  print(a._f);
}
print(x) {}''');
    resolve(source);
    assertErrors(source);
    verify([source]);
  }

  void test_unusedField_notUsed_compoundAssign() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  int _f;
  main() {
    _f += 2;
  }
}''');
    resolve(source);
    assertErrors(source, [HintCode.UNUSED_FIELD]);
    verify([source]);
  }

  void test_unusedField_notUsed_noReference() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  int _f;
}
''');
    resolve(source);
    assertErrors(source, [HintCode.UNUSED_FIELD]);
    verify([source]);
  }

  void test_unusedField_notUsed_postfixExpr() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  int _f = 0;
  main() {
    _f++;
  }
}''');
    resolve(source);
    assertErrors(source, [HintCode.UNUSED_FIELD]);
    verify([source]);
  }

  void test_unusedField_notUsed_prefixExpr() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  int _f = 0;
  main() {
    ++_f;
  }
}''');
    resolve(source);
    assertErrors(source, [HintCode.UNUSED_FIELD]);
    verify([source]);
  }

  void test_unusedField_notUsed_simpleAssignment() {
    enableUnusedElement = true;
    Source source = addSource(r'''
class A {
  int _f;
  m() {
    _f = 1;
  }
}
main(A a) {
  a._f = 2;
}
''');
    resolve(source);
    assertErrors(source, [HintCode.UNUSED_FIELD]);
    verify([source]);
  }

  void test_unusedImport() {
    Source source = addSource(r'''
library L;
import 'lib1.dart';''');
    Source source2 = addNamedSource("/lib1.dart", "library lib1;");
    resolve(source);
    assertErrors(source, [HintCode.UNUSED_IMPORT]);
    assertNoErrors(source2);
    verify([source, source2]);
  }

  void test_unusedImport_as() {
    Source source = addSource(r'''
library L;
import 'lib1.dart';
import 'lib1.dart' as one;
one.A a;''');
    Source source2 = addNamedSource("/lib1.dart", r'''
library lib1;
class A {}''');
    resolve(source);
    assertErrors(source, [HintCode.UNUSED_IMPORT]);
    assertNoErrors(source2);
    verify([source, source2]);
  }

  void test_unusedImport_hide() {
    Source source = addSource(r'''
library L;
import 'lib1.dart';
import 'lib1.dart' hide A;
A a;''');
    Source source2 = addNamedSource("/lib1.dart", r'''
library lib1;
class A {}''');
    resolve(source);
    assertErrors(source, [HintCode.UNUSED_IMPORT]);
    assertNoErrors(source2);
    verify([source, source2]);
  }

  void test_unusedImport_show() {
    Source source = addSource(r'''
library L;
import 'lib1.dart' show A;
import 'lib1.dart' show B;
A a;''');
    Source source2 = addNamedSource("/lib1.dart", r'''
library lib1;
class A {}
class B {}''');
    resolve(source);
    assertErrors(source, [HintCode.UNUSED_IMPORT]);
    assertNoErrors(source2);
    verify([source, source2]);
  }

  void test_unusedLocalVariable_inCatch_exception() {
    enableUnusedLocalVariable = true;
    Source source = addSource(r'''
main() {
  try {
  } catch (exception) {
  }
}''');
    resolve(source);
    assertErrors(source);
    verify([source]);
  }

  void test_unusedLocalVariable_inCatch_stackTrace() {
    enableUnusedLocalVariable = true;
    Source source = addSource(r'''
main() {
  try {
  } catch (exception, stackTrace) {
  }
}''');
    resolve(source);
    assertErrors(source, [HintCode.UNUSED_LOCAL_VARIABLE]);
    verify([source]);
  }

  void test_unusedLocalVariable_inCatch_stackTrace_used() {
    enableUnusedLocalVariable = true;
    Source source = addSource(r'''
main() {
  try {
  } catch (exception, stackTrace) {
    print('exception at $stackTrace');
  }
}
print(x) {}''');
    resolve(source);
    assertErrors(source);
    verify([source]);
  }

  void test_unusedLocalVariable_inFunction() {
    enableUnusedLocalVariable = true;
    Source source = addSource(r'''
main() {
  var v = 1;
  v = 2;
}''');
    resolve(source);
    assertErrors(source, [HintCode.UNUSED_LOCAL_VARIABLE]);
    verify([source]);
  }

  void test_unusedLocalVariable_inMethod() {
    enableUnusedLocalVariable = true;
    Source source = addSource(r'''
class A {
  foo() {
    var v = 1;
    v = 2;
  }
}''');
    resolve(source);
    assertErrors(source, [HintCode.UNUSED_LOCAL_VARIABLE]);
    verify([source]);
  }

  void test_unusedLocalVariable_isInvoked() {
    enableUnusedLocalVariable = true;
    Source source = addSource(r'''
typedef Foo();
main() {
  Foo foo;
  foo();
}''');
    resolve(source);
    assertErrors(source);
    verify([source]);
  }

  void test_unusedLocalVariable_isRead_notUsed_compoundAssign() {
    enableUnusedLocalVariable = true;
    Source source = addSource(r'''
main() {
  var v = 1;
  v += 2;
}''');
    resolve(source);
    assertErrors(source, [HintCode.UNUSED_LOCAL_VARIABLE]);
    verify([source]);
  }

  void test_unusedLocalVariable_isRead_notUsed_postfixExpr() {
    enableUnusedLocalVariable = true;
    Source source = addSource(r'''
main() {
  var v = 1;
  v++;
}''');
    resolve(source);
    assertErrors(source, [HintCode.UNUSED_LOCAL_VARIABLE]);
    verify([source]);
  }

  void test_unusedLocalVariable_isRead_notUsed_prefixExpr() {
    enableUnusedLocalVariable = true;
    Source source = addSource(r'''
main() {
  var v = 1;
  ++v;
}''');
    resolve(source);
    assertErrors(source, [HintCode.UNUSED_LOCAL_VARIABLE]);
    verify([source]);
  }

  void test_unusedLocalVariable_isRead_usedArgument() {
    enableUnusedLocalVariable = true;
    Source source = addSource(r'''
main() {
  var v = 1;
  print(++v);
}
print(x) {}''');
    resolve(source);
    assertErrors(source);
    verify([source]);
  }

  void test_unusedLocalVariable_isRead_usedInvocationTarget() {
    enableUnusedLocalVariable = true;
    Source source = addSource(r'''
class A {
  foo() {}
}
main() {
  var a = new A();
  a.foo();
}
''');
    resolve(source);
    assertErrors(source);
    verify([source]);
  }

  void test_useOfVoidResult_assignmentExpression_function() {
    Source source = addSource(r'''
void f() {}
class A {
  n() {
    var a;
    a = f();
  }
}''');
    resolve(source);
    assertErrors(source, [HintCode.USE_OF_VOID_RESULT]);
    verify([source]);
  }

  void test_useOfVoidResult_assignmentExpression_method() {
    Source source = addSource(r'''
class A {
  void m() {}
  n() {
    var a;
    a = m();
  }
}''');
    resolve(source);
    assertErrors(source, [HintCode.USE_OF_VOID_RESULT]);
    verify([source]);
  }

  void test_useOfVoidResult_inForLoop() {
    Source source = addSource(r'''
class A {
  void m() {}
  n() {
    for(var a = m();;) {}
  }
}''');
    resolve(source);
    assertErrors(source, [HintCode.USE_OF_VOID_RESULT]);
    verify([source]);
  }

  void test_useOfVoidResult_variableDeclaration_function() {
    Source source = addSource(r'''
void f() {}
class A {
  n() {
    var a = f();
  }
}''');
    resolve(source);
    assertErrors(source, [HintCode.USE_OF_VOID_RESULT]);
    verify([source]);
  }

  void test_useOfVoidResult_variableDeclaration_method() {
    Source source = addSource(r'''
class A {
  void m() {}
  n() {
    var a = m();
  }
}''');
    resolve(source);
    assertErrors(source, [HintCode.USE_OF_VOID_RESULT]);
    verify([source]);
  }

  void test_useOfVoidResult_variableDeclaration_method2() {
    Source source = addSource(r'''
class A {
  void m() {}
  n() {
    var a = m(), b = m();
  }
}''');
    resolve(source);
    assertErrors(
        source,
        [HintCode.USE_OF_VOID_RESULT, HintCode.USE_OF_VOID_RESULT]);
    verify([source]);
  }
}

class InheritanceManagerTest extends EngineTestCase {
  /**
   * The type provider used to access the types.
   */
  TestTypeProvider _typeProvider;

  /**
   * The library containing the code being resolved.
   */
  LibraryElementImpl _definingLibrary;

  /**
   * The inheritance manager being tested.
   */
  InheritanceManager _inheritanceManager;

  /**
   * The number of members that Object implements (as determined by [TestTypeProvider]).
   */
  int _numOfMembersInObject = 0;

  @override
  void setUp() {
    _typeProvider = new TestTypeProvider();
    _inheritanceManager = _createInheritanceManager();
    InterfaceType objectType = _typeProvider.objectType;
    _numOfMembersInObject =
        objectType.methods.length + objectType.accessors.length;
  }

  void test_getMapOfMembersInheritedFromClasses_accessor_extends() {
    // class A { int get g; }
    // class B extends A {}
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String getterName = "g";
    PropertyAccessorElement getterG =
        ElementFactory.getterElement(getterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[getterG];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    MemberMap mapB =
        _inheritanceManager.getMapOfMembersInheritedFromClasses(classB);
    MemberMap mapA =
        _inheritanceManager.getMapOfMembersInheritedFromClasses(classA);
    expect(mapA.size, _numOfMembersInObject);
    expect(mapB.size, _numOfMembersInObject + 1);
    expect(mapB.get(getterName), same(getterG));
    _assertNoErrors(classA);
    _assertNoErrors(classB);
  }

  void test_getMapOfMembersInheritedFromClasses_accessor_implements() {
    // class A { int get g; }
    // class B implements A {}
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String getterName = "g";
    PropertyAccessorElement getterG =
        ElementFactory.getterElement(getterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[getterG];
    ClassElementImpl classB = ElementFactory.classElement2("B");
    classB.interfaces = <InterfaceType>[classA.type];
    MemberMap mapB =
        _inheritanceManager.getMapOfMembersInheritedFromClasses(classB);
    MemberMap mapA =
        _inheritanceManager.getMapOfMembersInheritedFromClasses(classA);
    expect(mapA.size, _numOfMembersInObject);
    expect(mapB.size, _numOfMembersInObject);
    expect(mapB.get(getterName), isNull);
    _assertNoErrors(classA);
    _assertNoErrors(classB);
  }

  void test_getMapOfMembersInheritedFromClasses_accessor_with() {
    // class A { int get g; }
    // class B extends Object with A {}
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String getterName = "g";
    PropertyAccessorElement getterG =
        ElementFactory.getterElement(getterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[getterG];
    ClassElementImpl classB = ElementFactory.classElement2("B");
    classB.mixins = <InterfaceType>[classA.type];
    MemberMap mapB =
        _inheritanceManager.getMapOfMembersInheritedFromClasses(classB);
    MemberMap mapA =
        _inheritanceManager.getMapOfMembersInheritedFromClasses(classA);
    expect(mapA.size, _numOfMembersInObject);
    expect(mapB.size, _numOfMembersInObject + 1);
    expect(mapB.get(getterName), same(getterG));
    _assertNoErrors(classA);
    _assertNoErrors(classB);
  }

  void test_getMapOfMembersInheritedFromClasses_implicitExtends() {
    // class A {}
    ClassElementImpl classA = ElementFactory.classElement2("A");
    MemberMap mapA =
        _inheritanceManager.getMapOfMembersInheritedFromClasses(classA);
    expect(mapA.size, _numOfMembersInObject);
    _assertNoErrors(classA);
  }

  void test_getMapOfMembersInheritedFromClasses_method_extends() {
    // class A { int g(); }
    // class B extends A {}
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElement methodM =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    classA.methods = <MethodElement>[methodM];
    ClassElementImpl classB = ElementFactory.classElement2("B");
    classB.supertype = classA.type;
    MemberMap mapB =
        _inheritanceManager.getMapOfMembersInheritedFromClasses(classB);
    MemberMap mapA =
        _inheritanceManager.getMapOfMembersInheritedFromClasses(classA);
    expect(mapA.size, _numOfMembersInObject);
    expect(mapB.size, _numOfMembersInObject + 1);
    expect(mapB.get(methodName), same(methodM));
    _assertNoErrors(classA);
    _assertNoErrors(classB);
  }

  void test_getMapOfMembersInheritedFromClasses_method_implements() {
    // class A { int g(); }
    // class B implements A {}
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElement methodM =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    classA.methods = <MethodElement>[methodM];
    ClassElementImpl classB = ElementFactory.classElement2("B");
    classB.interfaces = <InterfaceType>[classA.type];
    MemberMap mapB =
        _inheritanceManager.getMapOfMembersInheritedFromClasses(classB);
    MemberMap mapA =
        _inheritanceManager.getMapOfMembersInheritedFromClasses(classA);
    expect(mapA.size, _numOfMembersInObject);
    expect(mapB.size, _numOfMembersInObject);
    expect(mapB.get(methodName), isNull);
    _assertNoErrors(classA);
    _assertNoErrors(classB);
  }

  void test_getMapOfMembersInheritedFromClasses_method_with() {
    // class A { int g(); }
    // class B extends Object with A {}
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElement methodM =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    classA.methods = <MethodElement>[methodM];
    ClassElementImpl classB = ElementFactory.classElement2("B");
    classB.mixins = <InterfaceType>[classA.type];
    MemberMap mapB =
        _inheritanceManager.getMapOfMembersInheritedFromClasses(classB);
    MemberMap mapA =
        _inheritanceManager.getMapOfMembersInheritedFromClasses(classA);
    expect(mapA.size, _numOfMembersInObject);
    expect(mapB.size, _numOfMembersInObject + 1);
    expect(mapB.get(methodName), same(methodM));
    _assertNoErrors(classA);
    _assertNoErrors(classB);
  }

  void test_getMapOfMembersInheritedFromInterfaces_accessor_extends() {
    // class A { int get g; }
    // class B extends A {}
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String getterName = "g";
    PropertyAccessorElement getterG =
        ElementFactory.getterElement(getterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[getterG];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    MemberMap mapB =
        _inheritanceManager.getMapOfMembersInheritedFromInterfaces(classB);
    MemberMap mapA =
        _inheritanceManager.getMapOfMembersInheritedFromInterfaces(classA);
    expect(mapA.size, _numOfMembersInObject);
    expect(mapB.size, _numOfMembersInObject + 1);
    expect(mapB.get(getterName), same(getterG));
    _assertNoErrors(classA);
    _assertNoErrors(classB);
  }

  void test_getMapOfMembersInheritedFromInterfaces_accessor_implements() {
    // class A { int get g; }
    // class B implements A {}
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String getterName = "g";
    PropertyAccessorElement getterG =
        ElementFactory.getterElement(getterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[getterG];
    ClassElementImpl classB = ElementFactory.classElement2("B");
    classB.interfaces = <InterfaceType>[classA.type];
    MemberMap mapB =
        _inheritanceManager.getMapOfMembersInheritedFromInterfaces(classB);
    MemberMap mapA =
        _inheritanceManager.getMapOfMembersInheritedFromInterfaces(classA);
    expect(mapA.size, _numOfMembersInObject);
    expect(mapB.size, _numOfMembersInObject + 1);
    expect(mapB.get(getterName), same(getterG));
    _assertNoErrors(classA);
    _assertNoErrors(classB);
  }

  void test_getMapOfMembersInheritedFromInterfaces_accessor_with() {
    // class A { int get g; }
    // class B extends Object with A {}
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String getterName = "g";
    PropertyAccessorElement getterG =
        ElementFactory.getterElement(getterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[getterG];
    ClassElementImpl classB = ElementFactory.classElement2("B");
    classB.mixins = <InterfaceType>[classA.type];
    MemberMap mapB =
        _inheritanceManager.getMapOfMembersInheritedFromInterfaces(classB);
    MemberMap mapA =
        _inheritanceManager.getMapOfMembersInheritedFromInterfaces(classA);
    expect(mapA.size, _numOfMembersInObject);
    expect(mapB.size, _numOfMembersInObject + 1);
    expect(mapB.get(getterName), same(getterG));
    _assertNoErrors(classA);
    _assertNoErrors(classB);
  }

  void test_getMapOfMembersInheritedFromInterfaces_implicitExtends() {
    // class A {}
    ClassElementImpl classA = ElementFactory.classElement2("A");
    MemberMap mapA =
        _inheritanceManager.getMapOfMembersInheritedFromInterfaces(classA);
    expect(mapA.size, _numOfMembersInObject);
    _assertNoErrors(classA);
  }

  void
      test_getMapOfMembersInheritedFromInterfaces_inconsistentMethodInheritance_getter_method() {
    // class I1 { int m(); }
    // class I2 { int get m; }
    // class A implements I2, I1 {}
    ClassElementImpl classI1 = ElementFactory.classElement2("I1");
    String methodName = "m";
    MethodElement methodM =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    classI1.methods = <MethodElement>[methodM];
    ClassElementImpl classI2 = ElementFactory.classElement2("I2");
    PropertyAccessorElement getter =
        ElementFactory.getterElement(methodName, false, _typeProvider.intType);
    classI2.accessors = <PropertyAccessorElement>[getter];
    ClassElementImpl classA = ElementFactory.classElement2("A");
    classA.interfaces = <InterfaceType>[classI2.type, classI1.type];
    MemberMap mapA =
        _inheritanceManager.getMapOfMembersInheritedFromInterfaces(classA);
    expect(mapA.size, _numOfMembersInObject);
    expect(mapA.get(methodName), isNull);
    _assertErrors(
        classA,
        [StaticWarningCode.INCONSISTENT_METHOD_INHERITANCE_GETTER_AND_METHOD]);
  }

  void
      test_getMapOfMembersInheritedFromInterfaces_inconsistentMethodInheritance_int_str() {
    // class I1 { int m(); }
    // class I2 { String m(); }
    // class A implements I1, I2 {}
    ClassElementImpl classI1 = ElementFactory.classElement2("I1");
    String methodName = "m";
    MethodElement methodM1 =
        ElementFactory.methodElement(methodName, null, [_typeProvider.intType]);
    classI1.methods = <MethodElement>[methodM1];
    ClassElementImpl classI2 = ElementFactory.classElement2("I2");
    MethodElement methodM2 =
        ElementFactory.methodElement(methodName, null, [_typeProvider.stringType]);
    classI2.methods = <MethodElement>[methodM2];
    ClassElementImpl classA = ElementFactory.classElement2("A");
    classA.interfaces = <InterfaceType>[classI1.type, classI2.type];
    MemberMap mapA =
        _inheritanceManager.getMapOfMembersInheritedFromInterfaces(classA);
    expect(mapA.size, _numOfMembersInObject);
    expect(mapA.get(methodName), isNull);
    _assertErrors(
        classA,
        [StaticTypeWarningCode.INCONSISTENT_METHOD_INHERITANCE]);
  }

  void
      test_getMapOfMembersInheritedFromInterfaces_inconsistentMethodInheritance_method_getter() {
    // class I1 { int m(); }
    // class I2 { int get m; }
    // class A implements I1, I2 {}
    ClassElementImpl classI1 = ElementFactory.classElement2("I1");
    String methodName = "m";
    MethodElement methodM =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    classI1.methods = <MethodElement>[methodM];
    ClassElementImpl classI2 = ElementFactory.classElement2("I2");
    PropertyAccessorElement getter =
        ElementFactory.getterElement(methodName, false, _typeProvider.intType);
    classI2.accessors = <PropertyAccessorElement>[getter];
    ClassElementImpl classA = ElementFactory.classElement2("A");
    classA.interfaces = <InterfaceType>[classI1.type, classI2.type];
    MemberMap mapA =
        _inheritanceManager.getMapOfMembersInheritedFromInterfaces(classA);
    expect(mapA.size, _numOfMembersInObject);
    expect(mapA.get(methodName), isNull);
    _assertErrors(
        classA,
        [StaticWarningCode.INCONSISTENT_METHOD_INHERITANCE_GETTER_AND_METHOD]);
  }

  void
      test_getMapOfMembersInheritedFromInterfaces_inconsistentMethodInheritance_numOfRequiredParams() {
    // class I1 { dynamic m(int, [int]); }
    // class I2 { dynamic m(int, int, int); }
    // class A implements I1, I2 {}
    ClassElementImpl classI1 = ElementFactory.classElement2("I1");
    String methodName = "m";
    MethodElementImpl methodM1 =
        ElementFactory.methodElement(methodName, _typeProvider.dynamicType);
    ParameterElementImpl parameter1 =
        new ParameterElementImpl.forNode(AstFactory.identifier3("a1"));
    parameter1.type = _typeProvider.intType;
    parameter1.parameterKind = ParameterKind.REQUIRED;
    ParameterElementImpl parameter2 =
        new ParameterElementImpl.forNode(AstFactory.identifier3("a2"));
    parameter2.type = _typeProvider.intType;
    parameter2.parameterKind = ParameterKind.POSITIONAL;
    methodM1.parameters = <ParameterElement>[parameter1, parameter2];
    classI1.methods = <MethodElement>[methodM1];
    ClassElementImpl classI2 = ElementFactory.classElement2("I2");
    MethodElementImpl methodM2 =
        ElementFactory.methodElement(methodName, _typeProvider.dynamicType);
    ParameterElementImpl parameter3 =
        new ParameterElementImpl.forNode(AstFactory.identifier3("a3"));
    parameter3.type = _typeProvider.intType;
    parameter3.parameterKind = ParameterKind.REQUIRED;
    ParameterElementImpl parameter4 =
        new ParameterElementImpl.forNode(AstFactory.identifier3("a4"));
    parameter4.type = _typeProvider.intType;
    parameter4.parameterKind = ParameterKind.REQUIRED;
    ParameterElementImpl parameter5 =
        new ParameterElementImpl.forNode(AstFactory.identifier3("a5"));
    parameter5.type = _typeProvider.intType;
    parameter5.parameterKind = ParameterKind.REQUIRED;
    methodM2.parameters =
        <ParameterElement>[parameter3, parameter4, parameter5];
    classI2.methods = <MethodElement>[methodM2];
    ClassElementImpl classA = ElementFactory.classElement2("A");
    classA.interfaces = <InterfaceType>[classI1.type, classI2.type];
    MemberMap mapA =
        _inheritanceManager.getMapOfMembersInheritedFromInterfaces(classA);
    expect(mapA.size, _numOfMembersInObject);
    expect(mapA.get(methodName), isNull);
    _assertErrors(
        classA,
        [StaticTypeWarningCode.INCONSISTENT_METHOD_INHERITANCE]);
  }

  void
      test_getMapOfMembersInheritedFromInterfaces_inconsistentMethodInheritance_str_int() {
    // class I1 { int m(); }
    // class I2 { String m(); }
    // class A implements I2, I1 {}
    ClassElementImpl classI1 = ElementFactory.classElement2("I1");
    String methodName = "m";
    MethodElement methodM1 =
        ElementFactory.methodElement(methodName, null, [_typeProvider.stringType]);
    classI1.methods = <MethodElement>[methodM1];
    ClassElementImpl classI2 = ElementFactory.classElement2("I2");
    MethodElement methodM2 =
        ElementFactory.methodElement(methodName, null, [_typeProvider.intType]);
    classI2.methods = <MethodElement>[methodM2];
    ClassElementImpl classA = ElementFactory.classElement2("A");
    classA.interfaces = <InterfaceType>[classI2.type, classI1.type];
    MemberMap mapA =
        _inheritanceManager.getMapOfMembersInheritedFromInterfaces(classA);
    expect(mapA.size, _numOfMembersInObject);
    expect(mapA.get(methodName), isNull);
    _assertErrors(
        classA,
        [StaticTypeWarningCode.INCONSISTENT_METHOD_INHERITANCE]);
  }

  void test_getMapOfMembersInheritedFromInterfaces_method_extends() {
    // class A { int g(); }
    // class B extends A {}
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElement methodM =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    classA.methods = <MethodElement>[methodM];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    MemberMap mapB =
        _inheritanceManager.getMapOfMembersInheritedFromInterfaces(classB);
    MemberMap mapA =
        _inheritanceManager.getMapOfMembersInheritedFromInterfaces(classA);
    expect(mapA.size, _numOfMembersInObject);
    expect(mapB.size, _numOfMembersInObject + 1);
    expect(mapB.get(methodName), same(methodM));
    _assertNoErrors(classA);
    _assertNoErrors(classB);
  }

  void test_getMapOfMembersInheritedFromInterfaces_method_implements() {
    // class A { int g(); }
    // class B implements A {}
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElement methodM =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    classA.methods = <MethodElement>[methodM];
    ClassElementImpl classB = ElementFactory.classElement2("B");
    classB.interfaces = <InterfaceType>[classA.type];
    MemberMap mapB =
        _inheritanceManager.getMapOfMembersInheritedFromInterfaces(classB);
    MemberMap mapA =
        _inheritanceManager.getMapOfMembersInheritedFromInterfaces(classA);
    expect(mapA.size, _numOfMembersInObject);
    expect(mapB.size, _numOfMembersInObject + 1);
    expect(mapB.get(methodName), same(methodM));
    _assertNoErrors(classA);
    _assertNoErrors(classB);
  }

  void test_getMapOfMembersInheritedFromInterfaces_method_with() {
    // class A { int g(); }
    // class B extends Object with A {}
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElement methodM =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    classA.methods = <MethodElement>[methodM];
    ClassElementImpl classB = ElementFactory.classElement2("B");
    classB.mixins = <InterfaceType>[classA.type];
    MemberMap mapB =
        _inheritanceManager.getMapOfMembersInheritedFromInterfaces(classB);
    MemberMap mapA =
        _inheritanceManager.getMapOfMembersInheritedFromInterfaces(classA);
    expect(mapA.size, _numOfMembersInObject);
    expect(mapB.size, _numOfMembersInObject + 1);
    expect(mapB.get(methodName), same(methodM));
    _assertNoErrors(classA);
    _assertNoErrors(classB);
  }

  void test_getMapOfMembersInheritedFromInterfaces_union_differentNames() {
    // class I1 { int m1(); }
    // class I2 { int m2(); }
    // class A implements I1, I2 {}
    ClassElementImpl classI1 = ElementFactory.classElement2("I1");
    String methodName1 = "m1";
    MethodElement methodM1 =
        ElementFactory.methodElement(methodName1, _typeProvider.intType);
    classI1.methods = <MethodElement>[methodM1];
    ClassElementImpl classI2 = ElementFactory.classElement2("I2");
    String methodName2 = "m2";
    MethodElement methodM2 =
        ElementFactory.methodElement(methodName2, _typeProvider.intType);
    classI2.methods = <MethodElement>[methodM2];
    ClassElementImpl classA = ElementFactory.classElement2("A");
    classA.interfaces = <InterfaceType>[classI1.type, classI2.type];
    MemberMap mapA =
        _inheritanceManager.getMapOfMembersInheritedFromInterfaces(classA);
    expect(mapA.size, _numOfMembersInObject + 2);
    expect(mapA.get(methodName1), same(methodM1));
    expect(mapA.get(methodName2), same(methodM2));
    _assertNoErrors(classA);
  }

  void
      test_getMapOfMembersInheritedFromInterfaces_union_multipleSubtypes_2_getters() {
    // class I1 { int get g; }
    // class I2 { num get g; }
    // class A implements I1, I2 {}
    ClassElementImpl classI1 = ElementFactory.classElement2("I1");
    String accessorName = "g";
    PropertyAccessorElement getter1 =
        ElementFactory.getterElement(accessorName, false, _typeProvider.intType);
    classI1.accessors = <PropertyAccessorElement>[getter1];
    ClassElementImpl classI2 = ElementFactory.classElement2("I2");
    PropertyAccessorElement getter2 =
        ElementFactory.getterElement(accessorName, false, _typeProvider.numType);
    classI2.accessors = <PropertyAccessorElement>[getter2];
    ClassElementImpl classA = ElementFactory.classElement2("A");
    classA.interfaces = <InterfaceType>[classI1.type, classI2.type];
    MemberMap mapA =
        _inheritanceManager.getMapOfMembersInheritedFromInterfaces(classA);
    expect(mapA.size, _numOfMembersInObject + 1);
    PropertyAccessorElement syntheticAccessor =
        ElementFactory.getterElement(accessorName, false, _typeProvider.dynamicType);
    expect(mapA.get(accessorName).type, syntheticAccessor.type);
    _assertNoErrors(classA);
  }

  void
      test_getMapOfMembersInheritedFromInterfaces_union_multipleSubtypes_2_methods() {
    // class I1 { dynamic m(int); }
    // class I2 { dynamic m(num); }
    // class A implements I1, I2 {}
    ClassElementImpl classI1 = ElementFactory.classElement2("I1");
    String methodName = "m";
    MethodElementImpl methodM1 =
        ElementFactory.methodElement(methodName, _typeProvider.dynamicType);
    ParameterElementImpl parameter1 =
        new ParameterElementImpl.forNode(AstFactory.identifier3("a0"));
    parameter1.type = _typeProvider.intType;
    parameter1.parameterKind = ParameterKind.REQUIRED;
    methodM1.parameters = <ParameterElement>[parameter1];
    classI1.methods = <MethodElement>[methodM1];
    ClassElementImpl classI2 = ElementFactory.classElement2("I2");
    MethodElementImpl methodM2 =
        ElementFactory.methodElement(methodName, _typeProvider.dynamicType);
    ParameterElementImpl parameter2 =
        new ParameterElementImpl.forNode(AstFactory.identifier3("a0"));
    parameter2.type = _typeProvider.numType;
    parameter2.parameterKind = ParameterKind.REQUIRED;
    methodM2.parameters = <ParameterElement>[parameter2];
    classI2.methods = <MethodElement>[methodM2];
    ClassElementImpl classA = ElementFactory.classElement2("A");
    classA.interfaces = <InterfaceType>[classI1.type, classI2.type];
    MemberMap mapA =
        _inheritanceManager.getMapOfMembersInheritedFromInterfaces(classA);
    expect(mapA.size, _numOfMembersInObject + 1);
    MethodElement syntheticMethod = ElementFactory.methodElement(
        methodName,
        _typeProvider.dynamicType,
        [_typeProvider.dynamicType]);
    expect(mapA.get(methodName).type, syntheticMethod.type);
    _assertNoErrors(classA);
  }

  void
      test_getMapOfMembersInheritedFromInterfaces_union_multipleSubtypes_2_setters() {
    // class I1 { set s(int); }
    // class I2 { set s(num); }
    // class A implements I1, I2 {}
    ClassElementImpl classI1 = ElementFactory.classElement2("I1");
    String accessorName = "s";
    PropertyAccessorElement setter1 =
        ElementFactory.setterElement(accessorName, false, _typeProvider.intType);
    classI1.accessors = <PropertyAccessorElement>[setter1];
    ClassElementImpl classI2 = ElementFactory.classElement2("I2");
    PropertyAccessorElement setter2 =
        ElementFactory.setterElement(accessorName, false, _typeProvider.numType);
    classI2.accessors = <PropertyAccessorElement>[setter2];
    ClassElementImpl classA = ElementFactory.classElement2("A");
    classA.interfaces = <InterfaceType>[classI1.type, classI2.type];
    MemberMap mapA =
        _inheritanceManager.getMapOfMembersInheritedFromInterfaces(classA);
    expect(mapA.size, _numOfMembersInObject + 1);
    PropertyAccessorElementImpl syntheticAccessor =
        ElementFactory.setterElement(accessorName, false, _typeProvider.dynamicType);
    syntheticAccessor.returnType = _typeProvider.dynamicType;
    expect(mapA.get("$accessorName=").type, syntheticAccessor.type);
    _assertNoErrors(classA);
  }

  void
      test_getMapOfMembersInheritedFromInterfaces_union_multipleSubtypes_3_getters() {
    // class A {}
    // class B extends A {}
    // class C extends B {}
    // class I1 { A get g; }
    // class I2 { B get g; }
    // class I3 { C get g; }
    // class D implements I1, I2, I3 {}
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    ClassElementImpl classC = ElementFactory.classElement("C", classB.type);
    ClassElementImpl classI1 = ElementFactory.classElement2("I1");
    String accessorName = "g";
    PropertyAccessorElement getter1 =
        ElementFactory.getterElement(accessorName, false, classA.type);
    classI1.accessors = <PropertyAccessorElement>[getter1];
    ClassElementImpl classI2 = ElementFactory.classElement2("I2");
    PropertyAccessorElement getter2 =
        ElementFactory.getterElement(accessorName, false, classB.type);
    classI2.accessors = <PropertyAccessorElement>[getter2];
    ClassElementImpl classI3 = ElementFactory.classElement2("I3");
    PropertyAccessorElement getter3 =
        ElementFactory.getterElement(accessorName, false, classC.type);
    classI3.accessors = <PropertyAccessorElement>[getter3];
    ClassElementImpl classD = ElementFactory.classElement2("D");
    classD.interfaces =
        <InterfaceType>[classI1.type, classI2.type, classI3.type];
    MemberMap mapD =
        _inheritanceManager.getMapOfMembersInheritedFromInterfaces(classD);
    expect(mapD.size, _numOfMembersInObject + 1);
    PropertyAccessorElement syntheticAccessor =
        ElementFactory.getterElement(accessorName, false, _typeProvider.dynamicType);
    expect(mapD.get(accessorName).type, syntheticAccessor.type);
    _assertNoErrors(classD);
  }

  void
      test_getMapOfMembersInheritedFromInterfaces_union_multipleSubtypes_3_methods() {
    // class A {}
    // class B extends A {}
    // class C extends B {}
    // class I1 { dynamic m(A a); }
    // class I2 { dynamic m(B b); }
    // class I3 { dynamic m(C c); }
    // class D implements I1, I2, I3 {}
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    ClassElementImpl classC = ElementFactory.classElement("C", classB.type);
    ClassElementImpl classI1 = ElementFactory.classElement2("I1");
    String methodName = "m";
    MethodElementImpl methodM1 =
        ElementFactory.methodElement(methodName, _typeProvider.dynamicType);
    ParameterElementImpl parameter1 =
        new ParameterElementImpl.forNode(AstFactory.identifier3("a0"));
    parameter1.type = classA.type;
    parameter1.parameterKind = ParameterKind.REQUIRED;
    methodM1.parameters = <ParameterElement>[parameter1];
    classI1.methods = <MethodElement>[methodM1];
    ClassElementImpl classI2 = ElementFactory.classElement2("I2");
    MethodElementImpl methodM2 =
        ElementFactory.methodElement(methodName, _typeProvider.dynamicType);
    ParameterElementImpl parameter2 =
        new ParameterElementImpl.forNode(AstFactory.identifier3("a0"));
    parameter2.type = classB.type;
    parameter2.parameterKind = ParameterKind.REQUIRED;
    methodM2.parameters = <ParameterElement>[parameter2];
    classI2.methods = <MethodElement>[methodM2];
    ClassElementImpl classI3 = ElementFactory.classElement2("I3");
    MethodElementImpl methodM3 =
        ElementFactory.methodElement(methodName, _typeProvider.dynamicType);
    ParameterElementImpl parameter3 =
        new ParameterElementImpl.forNode(AstFactory.identifier3("a0"));
    parameter3.type = classC.type;
    parameter3.parameterKind = ParameterKind.REQUIRED;
    methodM3.parameters = <ParameterElement>[parameter3];
    classI3.methods = <MethodElement>[methodM3];
    ClassElementImpl classD = ElementFactory.classElement2("D");
    classD.interfaces =
        <InterfaceType>[classI1.type, classI2.type, classI3.type];
    MemberMap mapD =
        _inheritanceManager.getMapOfMembersInheritedFromInterfaces(classD);
    expect(mapD.size, _numOfMembersInObject + 1);
    MethodElement syntheticMethod = ElementFactory.methodElement(
        methodName,
        _typeProvider.dynamicType,
        [_typeProvider.dynamicType]);
    expect(mapD.get(methodName).type, syntheticMethod.type);
    _assertNoErrors(classD);
  }

  void
      test_getMapOfMembersInheritedFromInterfaces_union_multipleSubtypes_3_setters() {
    // class A {}
    // class B extends A {}
    // class C extends B {}
    // class I1 { set s(A); }
    // class I2 { set s(B); }
    // class I3 { set s(C); }
    // class D implements I1, I2, I3 {}
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    ClassElementImpl classC = ElementFactory.classElement("C", classB.type);
    ClassElementImpl classI1 = ElementFactory.classElement2("I1");
    String accessorName = "s";
    PropertyAccessorElement setter1 =
        ElementFactory.setterElement(accessorName, false, classA.type);
    classI1.accessors = <PropertyAccessorElement>[setter1];
    ClassElementImpl classI2 = ElementFactory.classElement2("I2");
    PropertyAccessorElement setter2 =
        ElementFactory.setterElement(accessorName, false, classB.type);
    classI2.accessors = <PropertyAccessorElement>[setter2];
    ClassElementImpl classI3 = ElementFactory.classElement2("I3");
    PropertyAccessorElement setter3 =
        ElementFactory.setterElement(accessorName, false, classC.type);
    classI3.accessors = <PropertyAccessorElement>[setter3];
    ClassElementImpl classD = ElementFactory.classElement2("D");
    classD.interfaces =
        <InterfaceType>[classI1.type, classI2.type, classI3.type];
    MemberMap mapD =
        _inheritanceManager.getMapOfMembersInheritedFromInterfaces(classD);
    expect(mapD.size, _numOfMembersInObject + 1);
    PropertyAccessorElementImpl syntheticAccessor =
        ElementFactory.setterElement(accessorName, false, _typeProvider.dynamicType);
    syntheticAccessor.returnType = _typeProvider.dynamicType;
    expect(mapD.get("$accessorName=").type, syntheticAccessor.type);
    _assertNoErrors(classD);
  }

  void
      test_getMapOfMembersInheritedFromInterfaces_union_oneSubtype_2_methods() {
    // class I1 { int m(); }
    // class I2 { int m([int]); }
    // class A implements I1, I2 {}
    ClassElementImpl classI1 = ElementFactory.classElement2("I1");
    String methodName = "m";
    MethodElement methodM1 =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    classI1.methods = <MethodElement>[methodM1];
    ClassElementImpl classI2 = ElementFactory.classElement2("I2");
    MethodElementImpl methodM2 =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    ParameterElementImpl parameter1 =
        new ParameterElementImpl.forNode(AstFactory.identifier3("a1"));
    parameter1.type = _typeProvider.intType;
    parameter1.parameterKind = ParameterKind.POSITIONAL;
    methodM2.parameters = <ParameterElement>[parameter1];
    classI2.methods = <MethodElement>[methodM2];
    ClassElementImpl classA = ElementFactory.classElement2("A");
    classA.interfaces = <InterfaceType>[classI1.type, classI2.type];
    MemberMap mapA =
        _inheritanceManager.getMapOfMembersInheritedFromInterfaces(classA);
    expect(mapA.size, _numOfMembersInObject + 1);
    expect(mapA.get(methodName), same(methodM2));
    _assertNoErrors(classA);
  }

  void
      test_getMapOfMembersInheritedFromInterfaces_union_oneSubtype_3_methods() {
    // class I1 { int m(); }
    // class I2 { int m([int]); }
    // class I3 { int m([int, int]); }
    // class A implements I1, I2, I3 {}
    ClassElementImpl classI1 = ElementFactory.classElement2("I1");
    String methodName = "m";
    MethodElementImpl methodM1 =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    classI1.methods = <MethodElement>[methodM1];
    ClassElementImpl classI2 = ElementFactory.classElement2("I2");
    MethodElementImpl methodM2 =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    ParameterElementImpl parameter1 =
        new ParameterElementImpl.forNode(AstFactory.identifier3("a1"));
    parameter1.type = _typeProvider.intType;
    parameter1.parameterKind = ParameterKind.POSITIONAL;
    methodM1.parameters = <ParameterElement>[parameter1];
    classI2.methods = <MethodElement>[methodM2];
    ClassElementImpl classI3 = ElementFactory.classElement2("I3");
    MethodElementImpl methodM3 =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    ParameterElementImpl parameter2 =
        new ParameterElementImpl.forNode(AstFactory.identifier3("a2"));
    parameter2.type = _typeProvider.intType;
    parameter2.parameterKind = ParameterKind.POSITIONAL;
    ParameterElementImpl parameter3 =
        new ParameterElementImpl.forNode(AstFactory.identifier3("a3"));
    parameter3.type = _typeProvider.intType;
    parameter3.parameterKind = ParameterKind.POSITIONAL;
    methodM3.parameters = <ParameterElement>[parameter2, parameter3];
    classI3.methods = <MethodElement>[methodM3];
    ClassElementImpl classA = ElementFactory.classElement2("A");
    classA.interfaces =
        <InterfaceType>[classI1.type, classI2.type, classI3.type];
    MemberMap mapA =
        _inheritanceManager.getMapOfMembersInheritedFromInterfaces(classA);
    expect(mapA.size, _numOfMembersInObject + 1);
    expect(mapA.get(methodName), same(methodM3));
    _assertNoErrors(classA);
  }

  void
      test_getMapOfMembersInheritedFromInterfaces_union_oneSubtype_4_methods() {
    // class I1 { int m(); }
    // class I2 { int m(); }
    // class I3 { int m([int]); }
    // class I4 { int m([int, int]); }
    // class A implements I1, I2, I3, I4 {}
    ClassElementImpl classI1 = ElementFactory.classElement2("I1");
    String methodName = "m";
    MethodElement methodM1 =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    classI1.methods = <MethodElement>[methodM1];
    ClassElementImpl classI2 = ElementFactory.classElement2("I2");
    MethodElement methodM2 =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    classI2.methods = <MethodElement>[methodM2];
    ClassElementImpl classI3 = ElementFactory.classElement2("I3");
    MethodElementImpl methodM3 =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    ParameterElementImpl parameter1 =
        new ParameterElementImpl.forNode(AstFactory.identifier3("a1"));
    parameter1.type = _typeProvider.intType;
    parameter1.parameterKind = ParameterKind.POSITIONAL;
    methodM3.parameters = <ParameterElement>[parameter1];
    classI3.methods = <MethodElement>[methodM3];
    ClassElementImpl classI4 = ElementFactory.classElement2("I4");
    MethodElementImpl methodM4 =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    ParameterElementImpl parameter2 =
        new ParameterElementImpl.forNode(AstFactory.identifier3("a2"));
    parameter2.type = _typeProvider.intType;
    parameter2.parameterKind = ParameterKind.POSITIONAL;
    ParameterElementImpl parameter3 =
        new ParameterElementImpl.forNode(AstFactory.identifier3("a3"));
    parameter3.type = _typeProvider.intType;
    parameter3.parameterKind = ParameterKind.POSITIONAL;
    methodM4.parameters = <ParameterElement>[parameter2, parameter3];
    classI4.methods = <MethodElement>[methodM4];
    ClassElementImpl classA = ElementFactory.classElement2("A");
    classA.interfaces =
        <InterfaceType>[classI1.type, classI2.type, classI3.type, classI4.type];
    MemberMap mapA =
        _inheritanceManager.getMapOfMembersInheritedFromInterfaces(classA);
    expect(mapA.size, _numOfMembersInObject + 1);
    expect(mapA.get(methodName), same(methodM4));
    _assertNoErrors(classA);
  }

  void test_lookupInheritance_interface_getter() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String getterName = "g";
    PropertyAccessorElement getterG =
        ElementFactory.getterElement(getterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[getterG];
    ClassElementImpl classB = ElementFactory.classElement2("B");
    classB.interfaces = <InterfaceType>[classA.type];
    expect(
        _inheritanceManager.lookupInheritance(classB, getterName),
        same(getterG));
    _assertNoErrors(classA);
    _assertNoErrors(classB);
  }

  void test_lookupInheritance_interface_method() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElement methodM =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    classA.methods = <MethodElement>[methodM];
    ClassElementImpl classB = ElementFactory.classElement2("B");
    classB.interfaces = <InterfaceType>[classA.type];
    expect(
        _inheritanceManager.lookupInheritance(classB, methodName),
        same(methodM));
    _assertNoErrors(classA);
    _assertNoErrors(classB);
  }

  void test_lookupInheritance_interface_setter() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String setterName = "s";
    PropertyAccessorElement setterS =
        ElementFactory.setterElement(setterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[setterS];
    ClassElementImpl classB = ElementFactory.classElement2("B");
    classB.interfaces = <InterfaceType>[classA.type];
    expect(
        _inheritanceManager.lookupInheritance(classB, "$setterName="),
        same(setterS));
    _assertNoErrors(classA);
    _assertNoErrors(classB);
  }

  void test_lookupInheritance_interface_staticMember() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElement methodM =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    (methodM as MethodElementImpl).static = true;
    classA.methods = <MethodElement>[methodM];
    ClassElementImpl classB = ElementFactory.classElement2("B");
    classB.interfaces = <InterfaceType>[classA.type];
    expect(_inheritanceManager.lookupInheritance(classB, methodName), isNull);
    _assertNoErrors(classA);
    _assertNoErrors(classB);
  }

  void test_lookupInheritance_interfaces_infiniteLoop() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    classA.interfaces = <InterfaceType>[classA.type];
    expect(_inheritanceManager.lookupInheritance(classA, "name"), isNull);
    _assertNoErrors(classA);
  }

  void test_lookupInheritance_interfaces_infiniteLoop2() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement2("B");
    classA.interfaces = <InterfaceType>[classB.type];
    classB.interfaces = <InterfaceType>[classA.type];
    expect(_inheritanceManager.lookupInheritance(classA, "name"), isNull);
    _assertNoErrors(classA);
    _assertNoErrors(classB);
  }

  void test_lookupInheritance_interfaces_union2() {
    ClassElementImpl classI1 = ElementFactory.classElement2("I1");
    String methodName1 = "m1";
    MethodElement methodM1 =
        ElementFactory.methodElement(methodName1, _typeProvider.intType);
    classI1.methods = <MethodElement>[methodM1];
    ClassElementImpl classI2 = ElementFactory.classElement2("I2");
    String methodName2 = "m2";
    MethodElement methodM2 =
        ElementFactory.methodElement(methodName2, _typeProvider.intType);
    classI2.methods = <MethodElement>[methodM2];
    classI2.interfaces = <InterfaceType>[classI1.type];
    ClassElementImpl classA = ElementFactory.classElement2("A");
    classA.interfaces = <InterfaceType>[classI2.type];
    expect(
        _inheritanceManager.lookupInheritance(classA, methodName1),
        same(methodM1));
    expect(
        _inheritanceManager.lookupInheritance(classA, methodName2),
        same(methodM2));
    _assertNoErrors(classI1);
    _assertNoErrors(classI2);
    _assertNoErrors(classA);
  }

  void test_lookupInheritance_mixin_getter() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String getterName = "g";
    PropertyAccessorElement getterG =
        ElementFactory.getterElement(getterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[getterG];
    ClassElementImpl classB = ElementFactory.classElement2("B");
    classB.mixins = <InterfaceType>[classA.type];
    expect(
        _inheritanceManager.lookupInheritance(classB, getterName),
        same(getterG));
    _assertNoErrors(classA);
    _assertNoErrors(classB);
  }

  void test_lookupInheritance_mixin_method() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElement methodM =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    classA.methods = <MethodElement>[methodM];
    ClassElementImpl classB = ElementFactory.classElement2("B");
    classB.mixins = <InterfaceType>[classA.type];
    expect(
        _inheritanceManager.lookupInheritance(classB, methodName),
        same(methodM));
    _assertNoErrors(classA);
    _assertNoErrors(classB);
  }

  void test_lookupInheritance_mixin_setter() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String setterName = "s";
    PropertyAccessorElement setterS =
        ElementFactory.setterElement(setterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[setterS];
    ClassElementImpl classB = ElementFactory.classElement2("B");
    classB.mixins = <InterfaceType>[classA.type];
    expect(
        _inheritanceManager.lookupInheritance(classB, "$setterName="),
        same(setterS));
    _assertNoErrors(classA);
    _assertNoErrors(classB);
  }

  void test_lookupInheritance_mixin_staticMember() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElement methodM =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    (methodM as MethodElementImpl).static = true;
    classA.methods = <MethodElement>[methodM];
    ClassElementImpl classB = ElementFactory.classElement2("B");
    classB.mixins = <InterfaceType>[classA.type];
    expect(_inheritanceManager.lookupInheritance(classB, methodName), isNull);
    _assertNoErrors(classA);
    _assertNoErrors(classB);
  }

  void test_lookupInheritance_noMember() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    expect(_inheritanceManager.lookupInheritance(classA, "a"), isNull);
    _assertNoErrors(classA);
  }

  void test_lookupInheritance_superclass_getter() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String getterName = "g";
    PropertyAccessorElement getterG =
        ElementFactory.getterElement(getterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[getterG];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    expect(
        _inheritanceManager.lookupInheritance(classB, getterName),
        same(getterG));
    _assertNoErrors(classA);
    _assertNoErrors(classB);
  }

  void test_lookupInheritance_superclass_infiniteLoop() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    classA.supertype = classA.type;
    expect(_inheritanceManager.lookupInheritance(classA, "name"), isNull);
    _assertNoErrors(classA);
  }

  void test_lookupInheritance_superclass_infiniteLoop2() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement2("B");
    classA.supertype = classB.type;
    classB.supertype = classA.type;
    expect(_inheritanceManager.lookupInheritance(classA, "name"), isNull);
    _assertNoErrors(classA);
    _assertNoErrors(classB);
  }

  void test_lookupInheritance_superclass_method() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElement methodM =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    classA.methods = <MethodElement>[methodM];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    expect(
        _inheritanceManager.lookupInheritance(classB, methodName),
        same(methodM));
    _assertNoErrors(classA);
    _assertNoErrors(classB);
  }

  void test_lookupInheritance_superclass_setter() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String setterName = "s";
    PropertyAccessorElement setterS =
        ElementFactory.setterElement(setterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[setterS];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    expect(
        _inheritanceManager.lookupInheritance(classB, "$setterName="),
        same(setterS));
    _assertNoErrors(classA);
    _assertNoErrors(classB);
  }

  void test_lookupInheritance_superclass_staticMember() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElement methodM =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    (methodM as MethodElementImpl).static = true;
    classA.methods = <MethodElement>[methodM];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    expect(_inheritanceManager.lookupInheritance(classB, methodName), isNull);
    _assertNoErrors(classA);
    _assertNoErrors(classB);
  }

  void test_lookupMember_getter() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String getterName = "g";
    PropertyAccessorElement getterG =
        ElementFactory.getterElement(getterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[getterG];
    expect(_inheritanceManager.lookupMember(classA, getterName), same(getterG));
    _assertNoErrors(classA);
  }

  void test_lookupMember_getter_static() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String getterName = "g";
    PropertyAccessorElement getterG =
        ElementFactory.getterElement(getterName, true, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[getterG];
    expect(_inheritanceManager.lookupMember(classA, getterName), isNull);
    _assertNoErrors(classA);
  }

  void test_lookupMember_method() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElement methodM =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    classA.methods = <MethodElement>[methodM];
    expect(_inheritanceManager.lookupMember(classA, methodName), same(methodM));
    _assertNoErrors(classA);
  }

  void test_lookupMember_method_static() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElement methodM =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    (methodM as MethodElementImpl).static = true;
    classA.methods = <MethodElement>[methodM];
    expect(_inheritanceManager.lookupMember(classA, methodName), isNull);
    _assertNoErrors(classA);
  }

  void test_lookupMember_noMember() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    expect(_inheritanceManager.lookupMember(classA, "a"), isNull);
    _assertNoErrors(classA);
  }

  void test_lookupMember_setter() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String setterName = "s";
    PropertyAccessorElement setterS =
        ElementFactory.setterElement(setterName, false, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[setterS];
    expect(
        _inheritanceManager.lookupMember(classA, "$setterName="),
        same(setterS));
    _assertNoErrors(classA);
  }

  void test_lookupMember_setter_static() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String setterName = "s";
    PropertyAccessorElement setterS =
        ElementFactory.setterElement(setterName, true, _typeProvider.intType);
    classA.accessors = <PropertyAccessorElement>[setterS];
    expect(_inheritanceManager.lookupMember(classA, setterName), isNull);
    _assertNoErrors(classA);
  }

  void test_lookupOverrides_noParentClasses() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElementImpl methodM =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    classA.methods = <MethodElement>[methodM];
    expect(
        _inheritanceManager.lookupOverrides(classA, methodName),
        hasLength(0));
    _assertNoErrors(classA);
  }

  void test_lookupOverrides_overrideBaseClass() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElementImpl methodMinA =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    classA.methods = <MethodElement>[methodMinA];
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    MethodElementImpl methodMinB =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    classB.methods = <MethodElement>[methodMinB];
    List<ExecutableElement> overrides =
        _inheritanceManager.lookupOverrides(classB, methodName);
    expect(overrides, unorderedEquals([methodMinA]));
    _assertNoErrors(classA);
    _assertNoErrors(classB);
  }

  void test_lookupOverrides_overrideInterface() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElementImpl methodMinA =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    classA.methods = <MethodElement>[methodMinA];
    ClassElementImpl classB = ElementFactory.classElement2("B");
    classB.interfaces = <InterfaceType>[classA.type];
    MethodElementImpl methodMinB =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    classB.methods = <MethodElement>[methodMinB];
    List<ExecutableElement> overrides =
        _inheritanceManager.lookupOverrides(classB, methodName);
    expect(overrides, unorderedEquals([methodMinA]));
    _assertNoErrors(classA);
    _assertNoErrors(classB);
  }

  void test_lookupOverrides_overrideTwoInterfaces() {
    ClassElementImpl classA = ElementFactory.classElement2("A");
    String methodName = "m";
    MethodElementImpl methodMinA =
        ElementFactory.methodElement(methodName, _typeProvider.intType);
    classA.methods = <MethodElement>[methodMinA];
    ClassElementImpl classB = ElementFactory.classElement2("B");
    MethodElementImpl methodMinB =
        ElementFactory.methodElement(methodName, _typeProvider.doubleType);
    classB.methods = <MethodElement>[methodMinB];
    ClassElementImpl classC = ElementFactory.classElement2("C");
    classC.interfaces = <InterfaceType>[classA.type, classB.type];
    MethodElementImpl methodMinC =
        ElementFactory.methodElement(methodName, _typeProvider.numType);
    classC.methods = <MethodElement>[methodMinC];
    List<ExecutableElement> overrides =
        _inheritanceManager.lookupOverrides(classC, methodName);
    expect(overrides, unorderedEquals([methodMinA, methodMinB]));
    _assertNoErrors(classA);
    _assertNoErrors(classB);
    _assertNoErrors(classC);
  }

  void _assertErrors(ClassElement classElt, [List<ErrorCode> expectedErrorCodes
      = ErrorCode.EMPTY_LIST]) {
    GatheringErrorListener errorListener = new GatheringErrorListener();
    HashSet<AnalysisError> actualErrors =
        _inheritanceManager.getErrors(classElt);
    if (actualErrors != null) {
      for (AnalysisError error in actualErrors) {
        errorListener.onError(error);
      }
    }
    errorListener.assertErrorsWithCodes(expectedErrorCodes);
  }

  void _assertNoErrors(ClassElement classElt) {
    _assertErrors(classElt);
  }

  /**
   * Create the inheritance manager used by the tests.
   *
   * @return the inheritance manager that was created
   */
  InheritanceManager _createInheritanceManager() {
    AnalysisContextImpl context = AnalysisContextFactory.contextWithCore();
    FileBasedSource source =
        new FileBasedSource.con1(FileUtilities2.createFile("/test.dart"));
    CompilationUnitElementImpl definingCompilationUnit =
        new CompilationUnitElementImpl("test.dart");
    definingCompilationUnit.source = source;
    _definingLibrary = ElementFactory.library(context, "test");
    _definingLibrary.definingCompilationUnit = definingCompilationUnit;
    return new InheritanceManager(_definingLibrary);
  }
}

class LibraryElementBuilderTest extends EngineTestCase {
  /**
   * The analysis context used to analyze sources.
   */
  AnalysisContextImpl _context;

  /**
   * Add a source file to the content provider. The file path should be absolute.
   *
   * @param filePath the path of the file being added
   * @param contents the contents to be returned by the content provider for the specified file
   * @return the source object representing the added file
   */
  Source addSource(String filePath, String contents) {
    Source source =
        new FileBasedSource.con1(FileUtilities2.createFile(filePath));
    _context.setContents(source, contents);
    return source;
  }

  @override
  void setUp() {
    SourceFactory sourceFactory = new SourceFactory(
        [new DartUriResolver(DirectoryBasedDartSdk.defaultSdk), new FileUriResolver()]);
    _context = new AnalysisContextImpl();
    _context.sourceFactory = sourceFactory;
  }

  @override
  void tearDown() {
    _context = null;
    super.tearDown();
  }

  void test_accessorsAcrossFiles() {
    Source librarySource = addSource("/lib.dart", r'''
library lib;
part 'first.dart';
part 'second.dart';''');
    addSource("/first.dart", r'''
part of lib;
int get V => 0;''');
    addSource("/second.dart", r'''
part of lib;
void set V(int v) {}''');
    LibraryElement element = _buildLibrary(librarySource);
    expect(element, isNotNull);
    List<CompilationUnitElement> sourcedUnits = element.parts;
    expect(sourcedUnits, hasLength(2));
    List<PropertyAccessorElement> firstAccessors = sourcedUnits[0].accessors;
    expect(firstAccessors, hasLength(1));
    List<PropertyAccessorElement> secondAccessors = sourcedUnits[1].accessors;
    expect(secondAccessors, hasLength(1));
    expect(secondAccessors[0].variable, same(firstAccessors[0].variable));
  }

  void test_empty() {
    Source librarySource = addSource("/lib.dart", "library lib;");
    LibraryElement element = _buildLibrary(librarySource);
    expect(element, isNotNull);
    expect(element.name, "lib");
    expect(element.entryPoint, isNull);
    expect(element.importedLibraries, hasLength(0));
    expect(element.imports, hasLength(0));
    expect(element.library, same(element));
    expect(element.prefixes, hasLength(0));
    expect(element.parts, hasLength(0));
    CompilationUnitElement unit = element.definingCompilationUnit;
    expect(unit, isNotNull);
    expect(unit.name, "lib.dart");
    expect(unit.library, element);
    expect(unit.accessors, hasLength(0));
    expect(unit.functions, hasLength(0));
    expect(unit.functionTypeAliases, hasLength(0));
    expect(unit.types, hasLength(0));
    expect(unit.topLevelVariables, hasLength(0));
  }

  void test_missingLibraryDirectiveWithPart() {
    addSource("/a.dart", "part of lib;");
    Source librarySource = addSource("/lib.dart", "part 'a.dart';");
    LibraryElement element = _buildLibrary(
        librarySource,
        [ResolverErrorCode.MISSING_LIBRARY_DIRECTIVE_WITH_PART]);
    expect(element, isNotNull);
  }

  void test_missingPartOfDirective() {
    addSource("/a.dart", "class A {}");
    Source librarySource = addSource("/lib.dart", r'''
library lib;

part 'a.dart';''');
    LibraryElement element =
        _buildLibrary(librarySource, [CompileTimeErrorCode.PART_OF_NON_PART]);
    expect(element, isNotNull);
  }

  void test_multipleFiles() {
    Source librarySource = addSource("/lib.dart", r'''
library lib;
part 'first.dart';
part 'second.dart';

class A {}''');
    addSource("/first.dart", r'''
part of lib;
class B {}''');
    addSource("/second.dart", r'''
part of lib;
class C {}''');
    LibraryElement element = _buildLibrary(librarySource);
    expect(element, isNotNull);
    List<CompilationUnitElement> sourcedUnits = element.parts;
    expect(sourcedUnits, hasLength(2));
    _assertTypes(element.definingCompilationUnit, ["A"]);
    if (sourcedUnits[0].name == "first.dart") {
      _assertTypes(sourcedUnits[0], ["B"]);
      _assertTypes(sourcedUnits[1], ["C"]);
    } else {
      _assertTypes(sourcedUnits[0], ["C"]);
      _assertTypes(sourcedUnits[1], ["B"]);
    }
  }

  void test_singleFile() {
    Source librarySource = addSource("/lib.dart", r'''
library lib;

class A {}''');
    LibraryElement element = _buildLibrary(librarySource);
    expect(element, isNotNull);
    _assertTypes(element.definingCompilationUnit, ["A"]);
  }

  /**
   * Ensure that there are elements representing all of the types in the given array of type names.
   *
   * @param unit the compilation unit containing the types
   * @param typeNames the names of the types that should be found
   */
  void _assertTypes(CompilationUnitElement unit, List<String> typeNames) {
    expect(unit, isNotNull);
    List<ClassElement> types = unit.types;
    expect(types, hasLength(typeNames.length));
    for (ClassElement type in types) {
      expect(type, isNotNull);
      String actualTypeName = type.displayName;
      bool wasExpected = false;
      for (String expectedTypeName in typeNames) {
        if (expectedTypeName == actualTypeName) {
          wasExpected = true;
        }
      }
      if (!wasExpected) {
        fail("Found unexpected type $actualTypeName");
      }
    }
  }

  /**
   * Build the element model for the library whose defining compilation unit has the given source.
   *
   * @param librarySource the source of the defining compilation unit for the library
   * @param expectedErrorCodes the errors that are expected to be found while building the element
   *          model
   * @return the element model that was built for the library
   * @throws Exception if the element model could not be built
   */
  LibraryElement _buildLibrary(Source librarySource,
      [List<ErrorCode> expectedErrorCodes = ErrorCode.EMPTY_LIST]) {
    LibraryResolver resolver = new LibraryResolver(_context);
    LibraryElementBuilder builder =
        new LibraryElementBuilder(resolver.analysisContext, resolver.errorListener);
    Library library = resolver.createLibrary(librarySource);
    LibraryElement element = builder.buildLibrary(library);
    GatheringErrorListener listener = new GatheringErrorListener();
    listener.addAll2(resolver.errorListener);
    listener.assertErrorsWithCodes(expectedErrorCodes);
    return element;
  }
}

class LibraryImportScopeTest extends ResolverTestCase {
  void test_conflictingImports() {
    AnalysisContext context = new AnalysisContextImpl();
    context.sourceFactory = new SourceFactory([]);
    String typeNameA = "A";
    String typeNameB = "B";
    String typeNameC = "C";
    ClassElement typeA = ElementFactory.classElement2(typeNameA);
    ClassElement typeB1 = ElementFactory.classElement2(typeNameB);
    ClassElement typeB2 = ElementFactory.classElement2(typeNameB);
    ClassElement typeC = ElementFactory.classElement2(typeNameC);
    LibraryElement importedLibrary1 = createTestLibrary(context, "imported1");
    (importedLibrary1.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[typeA, typeB1];
    ImportElementImpl import1 =
        ElementFactory.importFor(importedLibrary1, null);
    LibraryElement importedLibrary2 = createTestLibrary(context, "imported2");
    (importedLibrary2.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[typeB2, typeC];
    ImportElementImpl import2 =
        ElementFactory.importFor(importedLibrary2, null);
    LibraryElementImpl importingLibrary =
        createTestLibrary(context, "importing");
    importingLibrary.imports = <ImportElement>[import1, import2];
    {
      GatheringErrorListener errorListener = new GatheringErrorListener();
      Scope scope = new LibraryImportScope(importingLibrary, errorListener);
      expect(
          scope.lookup(AstFactory.identifier3(typeNameA), importingLibrary),
          typeA);
      errorListener.assertNoErrors();
      expect(
          scope.lookup(AstFactory.identifier3(typeNameC), importingLibrary),
          typeC);
      errorListener.assertNoErrors();
      Element element =
          scope.lookup(AstFactory.identifier3(typeNameB), importingLibrary);
      errorListener.assertErrorsWithCodes([StaticWarningCode.AMBIGUOUS_IMPORT]);
      EngineTestCase.assertInstanceOf(
          (obj) => obj is MultiplyDefinedElement,
          MultiplyDefinedElement,
          element);
      List<Element> conflictingElements =
          (element as MultiplyDefinedElement).conflictingElements;
      expect(conflictingElements, hasLength(2));
      if (identical(conflictingElements[0], typeB1)) {
        expect(conflictingElements[1], same(typeB2));
      } else if (identical(conflictingElements[0], typeB2)) {
        expect(conflictingElements[1], same(typeB1));
      } else {
        expect(conflictingElements[0], same(typeB1));
      }
    }
    {
      GatheringErrorListener errorListener = new GatheringErrorListener();
      Scope scope = new LibraryImportScope(importingLibrary, errorListener);
      Identifier identifier = AstFactory.identifier3(typeNameB);
      AstFactory.methodDeclaration(
          null,
          AstFactory.typeName3(identifier),
          null,
          null,
          AstFactory.identifier3("foo"),
          null);
      Element element = scope.lookup(identifier, importingLibrary);
      errorListener.assertErrorsWithCodes([StaticWarningCode.AMBIGUOUS_IMPORT]);
      EngineTestCase.assertInstanceOf(
          (obj) => obj is MultiplyDefinedElement,
          MultiplyDefinedElement,
          element);
    }
  }

  void test_creation_empty() {
    LibraryElement definingLibrary = createDefaultTestLibrary();
    GatheringErrorListener errorListener = new GatheringErrorListener();
    new LibraryImportScope(definingLibrary, errorListener);
  }

  void test_creation_nonEmpty() {
    AnalysisContext context = new AnalysisContextImpl();
    context.sourceFactory = new SourceFactory([]);
    String importedTypeName = "A";
    ClassElement importedType =
        new ClassElementImpl.forNode(AstFactory.identifier3(importedTypeName));
    LibraryElement importedLibrary = createTestLibrary(context, "imported");
    (importedLibrary.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[importedType];
    LibraryElementImpl definingLibrary =
        createTestLibrary(context, "importing");
    ImportElementImpl importElement = new ImportElementImpl(0);
    importElement.importedLibrary = importedLibrary;
    definingLibrary.imports = <ImportElement>[importElement];
    GatheringErrorListener errorListener = new GatheringErrorListener();
    Scope scope = new LibraryImportScope(definingLibrary, errorListener);
    expect(
        scope.lookup(AstFactory.identifier3(importedTypeName), definingLibrary),
        importedType);
  }

  void test_getErrorListener() {
    LibraryElement definingLibrary = createDefaultTestLibrary();
    GatheringErrorListener errorListener = new GatheringErrorListener();
    LibraryImportScope scope =
        new LibraryImportScope(definingLibrary, errorListener);
    expect(scope.errorListener, errorListener);
  }

  void test_nonConflictingImports_fromSdk() {
    AnalysisContext context = AnalysisContextFactory.contextWithCore();
    String typeName = "List";
    ClassElement type = ElementFactory.classElement2(typeName);
    LibraryElement importedLibrary = createTestLibrary(context, "lib");
    (importedLibrary.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[type];
    ImportElementImpl importCore = ElementFactory.importFor(
        context.getLibraryElement(context.sourceFactory.forUri("dart:core")),
        null);
    ImportElementImpl importLib =
        ElementFactory.importFor(importedLibrary, null);
    LibraryElementImpl importingLibrary =
        createTestLibrary(context, "importing");
    importingLibrary.imports = <ImportElement>[importCore, importLib];
    GatheringErrorListener errorListener = new GatheringErrorListener();
    Scope scope = new LibraryImportScope(importingLibrary, errorListener);
    expect(
        scope.lookup(AstFactory.identifier3(typeName), importingLibrary),
        type);
    errorListener.assertErrorsWithCodes(
        [StaticWarningCode.CONFLICTING_DART_IMPORT]);
  }

  void test_nonConflictingImports_sameElement() {
    AnalysisContext context = new AnalysisContextImpl();
    context.sourceFactory = new SourceFactory([]);
    String typeNameA = "A";
    String typeNameB = "B";
    ClassElement typeA = ElementFactory.classElement2(typeNameA);
    ClassElement typeB = ElementFactory.classElement2(typeNameB);
    LibraryElement importedLibrary = createTestLibrary(context, "imported");
    (importedLibrary.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[typeA, typeB];
    ImportElementImpl import1 = ElementFactory.importFor(importedLibrary, null);
    ImportElementImpl import2 = ElementFactory.importFor(importedLibrary, null);
    LibraryElementImpl importingLibrary =
        createTestLibrary(context, "importing");
    importingLibrary.imports = <ImportElement>[import1, import2];
    GatheringErrorListener errorListener = new GatheringErrorListener();
    Scope scope = new LibraryImportScope(importingLibrary, errorListener);
    expect(
        scope.lookup(AstFactory.identifier3(typeNameA), importingLibrary),
        typeA);
    errorListener.assertNoErrors();
    expect(
        scope.lookup(AstFactory.identifier3(typeNameB), importingLibrary),
        typeB);
    errorListener.assertNoErrors();
  }

  void test_prefixedAndNonPrefixed() {
    AnalysisContext context = new AnalysisContextImpl();
    context.sourceFactory = new SourceFactory([]);
    String typeName = "C";
    String prefixName = "p";
    ClassElement prefixedType = ElementFactory.classElement2(typeName);
    ClassElement nonPrefixedType = ElementFactory.classElement2(typeName);
    LibraryElement prefixedLibrary =
        createTestLibrary(context, "import.prefixed");
    (prefixedLibrary.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[prefixedType];
    ImportElementImpl prefixedImport =
        ElementFactory.importFor(prefixedLibrary, ElementFactory.prefix(prefixName));
    LibraryElement nonPrefixedLibrary =
        createTestLibrary(context, "import.nonPrefixed");
    (nonPrefixedLibrary.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[nonPrefixedType];
    ImportElementImpl nonPrefixedImport =
        ElementFactory.importFor(nonPrefixedLibrary, null);
    LibraryElementImpl importingLibrary =
        createTestLibrary(context, "importing");
    importingLibrary.imports =
        <ImportElement>[prefixedImport, nonPrefixedImport];
    GatheringErrorListener errorListener = new GatheringErrorListener();
    Scope scope = new LibraryImportScope(importingLibrary, errorListener);
    Element prefixedElement =
        scope.lookup(AstFactory.identifier5(prefixName, typeName), importingLibrary);
    errorListener.assertNoErrors();
    expect(prefixedElement, same(prefixedType));
    Element nonPrefixedElement =
        scope.lookup(AstFactory.identifier3(typeName), importingLibrary);
    errorListener.assertNoErrors();
    expect(nonPrefixedElement, same(nonPrefixedType));
  }
}

class LibraryResolver2Test extends ResolverTestCase {
  LibraryResolver2 _resolver;

  Source _coreLibrarySource;

  @override
  void setUp() {
    super.setUp();
    _resolver = new LibraryResolver2(analysisContext2);
    _coreLibrarySource =
        analysisContext2.sourceFactory.forUri(DartSdk.DART_CORE);
  }

  void test_imports_relative() {
    Source sourceA = addSource(r'''
library libA;
import 'libB.dart';
class A {}''');
    Source sourceB = addNamedSource("/libB.dart", r'''
library libB;
import 'test.dart
class B {}''');
    List<ResolvableLibrary> cycle = new List<ResolvableLibrary>();
    ResolvableLibrary coreLib = _createResolvableLibrary(_coreLibrarySource);
    coreLib.libraryElement = analysisContext2.computeLibraryElement(
        _coreLibrarySource) as LibraryElementImpl;
    ResolvableLibrary libA = _createResolvableLibrary(sourceA);
    ResolvableLibrary libB = _createResolvableLibrary(sourceB);
    libA.importedLibraries = <ResolvableLibrary>[coreLib, libB];
    libB.importedLibraries = <ResolvableLibrary>[coreLib, libA];
    cycle.add(libA);
    cycle.add(libB);
    LibraryElement library = _resolver.resolveLibrary(sourceA, cycle);
    List<LibraryElement> importedLibraries = library.importedLibraries;
    assertNamedElements(importedLibraries, ["dart.core", "libB"]);
  }

  ResolvableLibrary _createResolvableLibrary(Source source) {
    CompilationUnit unit = analysisContext2.parseCompilationUnit(source);
    ResolvableLibrary resolvableLibrary = new ResolvableLibrary(source);
    resolvableLibrary.resolvableCompilationUnits =
        <ResolvableCompilationUnit>[new ResolvableCompilationUnit(source, unit)];
    return resolvableLibrary;
  }
}

class LibraryResolverTest extends ResolverTestCase {
  LibraryResolver _resolver;

  @override
  void setUp() {
    super.setUp();
    _resolver = new LibraryResolver(analysisContext2);
  }

  void test_imports_dart_html() {
    Source source = addSource(r'''
library libA;
import 'dart:html';
class A {}''');
    LibraryElement library = _resolver.resolveLibrary(source, true);
    List<LibraryElement> importedLibraries = library.importedLibraries;
    assertNamedElements(importedLibraries, ["dart.core", "dart.dom.html"]);
  }

  void test_imports_none() {
    Source source = addSource(r'''
library libA;
class A {}''');
    LibraryElement library = _resolver.resolveLibrary(source, true);
    List<LibraryElement> importedLibraries = library.importedLibraries;
    assertNamedElements(importedLibraries, ["dart.core"]);
  }

  void test_imports_relative() {
    addNamedSource("/libB.dart", "library libB;");
    Source source = addSource(r'''
library libA;
import 'libB.dart';
class A {}''');
    LibraryElement library = _resolver.resolveLibrary(source, true);
    List<LibraryElement> importedLibraries = library.importedLibraries;
    assertNamedElements(importedLibraries, ["dart.core", "libB"]);
  }
}

class LibraryScopeTest extends ResolverTestCase {
  void test_creation_empty() {
    LibraryElement definingLibrary = createDefaultTestLibrary();
    GatheringErrorListener errorListener = new GatheringErrorListener();
    new LibraryScope(definingLibrary, errorListener);
  }

  void test_creation_nonEmpty() {
    AnalysisContext context = new AnalysisContextImpl();
    context.sourceFactory = new SourceFactory([]);
    String importedTypeName = "A";
    ClassElement importedType =
        new ClassElementImpl.forNode(AstFactory.identifier3(importedTypeName));
    LibraryElement importedLibrary = createTestLibrary(context, "imported");
    (importedLibrary.definingCompilationUnit as CompilationUnitElementImpl).types =
        <ClassElement>[importedType];
    LibraryElementImpl definingLibrary =
        createTestLibrary(context, "importing");
    ImportElementImpl importElement = new ImportElementImpl(0);
    importElement.importedLibrary = importedLibrary;
    definingLibrary.imports = <ImportElement>[importElement];
    GatheringErrorListener errorListener = new GatheringErrorListener();
    Scope scope = new LibraryScope(definingLibrary, errorListener);
    expect(
        scope.lookup(AstFactory.identifier3(importedTypeName), definingLibrary),
        importedType);
  }

  void test_getErrorListener() {
    LibraryElement definingLibrary = createDefaultTestLibrary();
    GatheringErrorListener errorListener = new GatheringErrorListener();
    LibraryScope scope = new LibraryScope(definingLibrary, errorListener);
    expect(scope.errorListener, errorListener);
  }
}

class LibraryTest extends EngineTestCase {
  /**
   * The error listener to which all errors will be reported.
   */
  GatheringErrorListener _errorListener;

  /**
   * The source factory used to create libraries.
   */
  SourceFactory _sourceFactory;

  /**
   * The analysis context to pass in to all libraries created by the tests.
   */
  AnalysisContextImpl _analysisContext;

  /**
   * The library used by the tests.
   */
  Library _library;

  @override
  void setUp() {
    _sourceFactory = new SourceFactory([new FileUriResolver()]);
    _analysisContext = new AnalysisContextImpl();
    _analysisContext.sourceFactory = _sourceFactory;
    _errorListener = new GatheringErrorListener();
    _library = _createLibrary("/lib.dart");
  }

  @override
  void tearDown() {
    _errorListener = null;
    _sourceFactory = null;
    _analysisContext = null;
    _library = null;
    super.tearDown();
  }

  void test_getExplicitlyImportsCore() {
    expect(_library.explicitlyImportsCore, isFalse);
    _errorListener.assertNoErrors();
  }

  void test_getExports() {
    expect(_library.exports, hasLength(0));
    _errorListener.assertNoErrors();
  }

  void test_getImports() {
    expect(_library.imports, hasLength(0));
    _errorListener.assertNoErrors();
  }

  void test_getImportsAndExports() {
    _library.importedLibraries = <Library>[_createLibrary("/imported.dart")];
    _library.exportedLibraries = <Library>[_createLibrary("/exported.dart")];
    expect(_library.importsAndExports, hasLength(2));
    _errorListener.assertNoErrors();
  }

  void test_getLibraryScope() {
    LibraryElementImpl element = new LibraryElementImpl.forNode(
        _analysisContext,
        AstFactory.libraryIdentifier2(["lib"]));
    element.definingCompilationUnit =
        new CompilationUnitElementImpl("lib.dart");
    _library.libraryElement = element;
    expect(_library.libraryScope, isNotNull);
    _errorListener.assertNoErrors();
  }

  void test_getLibrarySource() {
    expect(_library.librarySource, isNotNull);
  }

  void test_setExplicitlyImportsCore() {
    _library.explicitlyImportsCore = true;
    expect(_library.explicitlyImportsCore, isTrue);
    _errorListener.assertNoErrors();
  }

  void test_setExportedLibraries() {
    Library exportLibrary = _createLibrary("/exported.dart");
    _library.exportedLibraries = <Library>[exportLibrary];
    List<Library> exports = _library.exports;
    expect(exports, hasLength(1));
    expect(exports[0], same(exportLibrary));
    _errorListener.assertNoErrors();
  }

  void test_setImportedLibraries() {
    Library importLibrary = _createLibrary("/imported.dart");
    _library.importedLibraries = <Library>[importLibrary];
    List<Library> imports = _library.imports;
    expect(imports, hasLength(1));
    expect(imports[0], same(importLibrary));
    _errorListener.assertNoErrors();
  }

  void test_setLibraryElement() {
    LibraryElementImpl element = new LibraryElementImpl.forNode(
        _analysisContext,
        AstFactory.libraryIdentifier2(["lib"]));
    _library.libraryElement = element;
    expect(_library.libraryElement, same(element));
  }

  Library _createLibrary(String definingCompilationUnitPath) =>
      new Library(
          _analysisContext,
          _errorListener,
          new FileBasedSource.con1(
              FileUtilities2.createFile(definingCompilationUnitPath)));
}

class MemberMapTest {
  /**
   * The null type.
   */
  InterfaceType _nullType;

  void setUp() {
    _nullType = new TestTypeProvider().nullType;
  }

  void test_MemberMap_copyConstructor() {
    MethodElement m1 = ElementFactory.methodElement("m1", _nullType);
    MethodElement m2 = ElementFactory.methodElement("m2", _nullType);
    MethodElement m3 = ElementFactory.methodElement("m3", _nullType);
    MemberMap map = new MemberMap();
    map.put(m1.name, m1);
    map.put(m2.name, m2);
    map.put(m3.name, m3);
    MemberMap copy = new MemberMap.con2(map);
    expect(copy.size, map.size);
    expect(copy.get(m1.name), m1);
    expect(copy.get(m2.name), m2);
    expect(copy.get(m3.name), m3);
  }

  void test_MemberMap_override() {
    MethodElement m1 = ElementFactory.methodElement("m", _nullType);
    MethodElement m2 = ElementFactory.methodElement("m", _nullType);
    MemberMap map = new MemberMap();
    map.put(m1.name, m1);
    map.put(m2.name, m2);
    expect(map.size, 1);
    expect(map.get("m"), m2);
  }

  void test_MemberMap_put() {
    MethodElement m1 = ElementFactory.methodElement("m1", _nullType);
    MemberMap map = new MemberMap();
    expect(map.size, 0);
    map.put(m1.name, m1);
    expect(map.size, 1);
    expect(map.get("m1"), m1);
  }
}

class NonHintCodeTest extends ResolverTestCase {
  void test_deadCode_deadBlock_conditionalElse_debugConst() {
    Source source = addSource(r'''
const bool DEBUG = true;
f() {
  DEBUG ? 1 : 2;
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_deadCode_deadBlock_conditionalIf_debugConst() {
    Source source = addSource(r'''
const bool DEBUG = false;
f() {
  DEBUG ? 1 : 2;
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_deadCode_deadBlock_else() {
    Source source = addSource(r'''
const bool DEBUG = true;
f() {
  if(DEBUG) {} else {}
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_deadCode_deadBlock_if_debugConst_prefixedIdentifier() {
    Source source = addSource(r'''
class A {
  static const bool DEBUG = false;
}
f() {
  if(A.DEBUG) {}
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_deadCode_deadBlock_if_debugConst_prefixedIdentifier2() {
    Source source = addSource(r'''
library L;
import 'lib2.dart';
f() {
  if(A.DEBUG) {}
}''');
    addNamedSource("/lib2.dart", r'''
library lib2;
class A {
  static const bool DEBUG = false;
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_deadCode_deadBlock_if_debugConst_propertyAccessor() {
    Source source = addSource(r'''
library L;
import 'lib2.dart' as LIB;
f() {
  if(LIB.A.DEBUG) {}
}''');
    addNamedSource("/lib2.dart", r'''
library lib2;
class A {
  static const bool DEBUG = false;
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_deadCode_deadBlock_if_debugConst_simpleIdentifier() {
    Source source = addSource(r'''
const bool DEBUG = false;
f() {
  if(DEBUG) {}
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_deadCode_deadBlock_while_debugConst() {
    Source source = addSource(r'''
const bool DEBUG = false;
f() {
  while(DEBUG) {}
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_deadCode_deadCatch_onCatchSubtype() {
    Source source = addSource(r'''
class A {}
class B extends A {}
f() {
  try {} on B catch (e) {} on A catch (e) {} catch (e) {}
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_deadCode_deadOperandLHS_and_debugConst() {
    Source source = addSource(r'''
const bool DEBUG = false;
f() {
  bool b = DEBUG && false;
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_deadCode_deadOperandLHS_or_debugConst() {
    Source source = addSource(r'''
const bool DEBUG = true;
f() {
  bool b = DEBUG || true;
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_divisionOptimization() {
    Source source = addSource(r'''
f(int x, int y) {
  var v = x / y.toInt();
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_divisionOptimization_supressIfDivisionNotDefinedInCore() {
    Source source = addSource(r'''
f(x, y) {
  var v = (x / y).toInt();
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_divisionOptimization_supressIfDivisionOverridden() {
    Source source = addSource(r'''
class A {
  num operator /(x) { return x; }
}
f(A x, A y) {
  var v = (x / y).toInt();
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_duplicateImport_as() {
    Source source = addSource(r'''
library L;
import 'lib1.dart';
import 'lib1.dart' as one;
A a;
one.A a2;''');
    addNamedSource("/lib1.dart", r'''
library lib1;
class A {}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_duplicateImport_hide() {
    Source source = addSource(r'''
library L;
import 'lib1.dart';
import 'lib1.dart' hide A;
A a;
B b;''');
    addNamedSource("/lib1.dart", r'''
library lib1;
class A {}
class B {}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_duplicateImport_show() {
    Source source = addSource(r'''
library L;
import 'lib1.dart';
import 'lib1.dart' show A;
A a;
B b;''');
    addNamedSource("/lib1.dart", r'''
library lib1;
class A {}
class B {}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_importDeferredLibraryWithLoadFunction() {
    resolveWithAndWithoutExperimental(<String>[r'''
library lib1;
f() {}''', r'''
library root;
import 'lib1.dart' deferred as lib1;
main() { lib1.f(); }'''],
          <ErrorCode>[ParserErrorCode.DEFERRED_IMPORTS_NOT_SUPPORTED],
          ErrorCode.EMPTY_LIST);
  }

  void test_issue20904BuggyTypePromotionAtIfJoin_1() {
    // https://code.google.com/p/dart/issues/detail?id=20904
    Source source = addSource(r'''
f(var message, var dynamic_) {
  if (message is Function) {
    message = dynamic_;
  }
  int s = message;
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_issue20904BuggyTypePromotionAtIfJoin_2() {
    // https://code.google.com/p/dart/issues/detail?id=20904
    enableUnionTypes(false);
    Source source = addSource(r'''
f(var message) {
  if (message is Function) {
    message = '';
  }
  int s = message;
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_issue20904BuggyTypePromotionAtIfJoin_3() {
    // https://code.google.com/p/dart/issues/detail?id=20904
    Source source = addSource(r'''
f(var message) {
  var dynamic_;
  if (message is Function) {
    message = dynamic_;
  } else {
    return;
  }
  int s = message;
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_issue20904BuggyTypePromotionAtIfJoin_4() {
    // https://code.google.com/p/dart/issues/detail?id=20904
    Source source = addSource(r'''
f(var message) {
  if (message is Function) {
    message = '';
  } else {
    return;
  }
  String s = message;
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_missingReturn_emptyFunctionBody() {
    Source source = addSource(r'''
abstract class A {
  int m();
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_missingReturn_expressionFunctionBody() {
    Source source = addSource("int f() => 0;");
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_missingReturn_noReturnType() {
    Source source = addSource("f() {}");
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_missingReturn_voidReturnType() {
    Source source = addSource("void f() {}");
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_overrideEqualsButNotHashCode() {
    Source source = addSource(r'''
class A {
  bool operator ==(x) { return x; }
  get hashCode => 0;
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_overrideOnNonOverridingGetter_inInterface() {
    Source source = addSource(r'''
library dart.core;
const override = null;
class A {
  int get m => 0;
}
class B implements A {
  @override
  int get m => 1;
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_overrideOnNonOverridingGetter_inSuperclass() {
    Source source = addSource(r'''
library dart.core;
const override = null;
class A {
  int get m => 0;
}
class B extends A {
  @override
  int get m => 1;
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_overrideOnNonOverridingMethod_inInterface() {
    Source source = addSource(r'''
library dart.core;
const override = null;
class A {
  int m() => 0;
}
class B implements A {
  @override
  int m() => 1;
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_overrideOnNonOverridingMethod_inSuperclass() {
    Source source = addSource(r'''
library dart.core;
const override = null;
class A {
  int m() => 0;
}
class B extends A {
  @override
  int m() => 1;
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_overrideOnNonOverridingSetter_inInterface() {
    Source source = addSource(r'''
library dart.core;
const override = null;
class A {
  set m(int x) {}
}
class B implements A {
  @override
  set m(int x) {}
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_overrideOnNonOverridingSetter_inSuperclass() {
    Source source = addSource(r'''
library dart.core;
const override = null;
class A {
  set m(int x) {}
}
class B extends A {
  @override
  set m(int x) {}
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_propagatedFieldType() {
    // From dartbug.com/20019
    Source source = addSource(r'''
class A { }
class X<T> {
  final x = new List<T>();
}
class Z {
  final X<A> y = new X<A>();
  foo() {
    y.x.add(new A());
  }
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_proxy_annotation_prefixed() {
    Source source = addSource(r'''
library L;
@proxy
class A {}
f(var a) {
  a = new A();
  a.m();
  var x = a.g;
  a.s = 1;
  var y = a + a;
  a++;
  ++a;
}''');
    resolve(source);
    assertNoErrors(source);
  }

  void test_proxy_annotation_prefixed2() {
    Source source = addSource(r'''
library L;
@proxy
class A {}
class B {
  f(var a) {
    a = new A();
    a.m();
    var x = a.g;
    a.s = 1;
    var y = a + a;
    a++;
    ++a;
  }
}''');
    resolve(source);
    assertNoErrors(source);
  }

  void test_proxy_annotation_prefixed3() {
    Source source = addSource(r'''
library L;
class B {
  f(var a) {
    a = new A();
    a.m();
    var x = a.g;
    a.s = 1;
    var y = a + a;
    a++;
    ++a;
  }
}
@proxy
class A {}''');
    resolve(source);
    assertNoErrors(source);
  }

  void test_undefinedGetter_inSubtype() {
    Source source = addSource(r'''
class A {}
class B extends A {
  get b => 0;
}
f(var a) {
  if(a is A) {
    return a.b;
  }
}''');
    resolve(source);
    assertNoErrors(source);
  }

  void test_undefinedMethod_assignmentExpression_inSubtype() {
    Source source = addSource(r'''
class A {}
class B extends A {
  operator +(B b) {return new B();}
}
f(var a, var a2) {
  a = new A();
  a2 = new A();
  a += a2;
}''');
    resolve(source);
    assertNoErrors(source);
  }

  void test_undefinedMethod_inSubtype() {
    Source source = addSource(r'''
class A {}
class B extends A {
  b() {}
}
f() {
  var a = new A();
  a.b();
}''');
    resolve(source);
    assertNoErrors(source);
  }

  void test_undefinedMethod_unionType_all() {
    Source source = addSource(r'''
class A {
  int m(int x) => 0;
}
class B {
  String m() => '0';
}
f(A a, B b) {
  var ab;
  if (0 < 1) {
    ab = a;
  } else {
    ab = b;
  }
  ab.m();
}''');
    resolve(source);
    assertNoErrors(source);
  }

  void test_undefinedMethod_unionType_some() {
    Source source = addSource(r'''
class A {
  int m(int x) => 0;
}
class B {}
f(A a, B b) {
  var ab;
  if (0 < 1) {
    ab = a;
  } else {
    ab = b;
  }
  ab.m(0);
}''');
    resolve(source);
    assertNoErrors(source);
  }

  void test_undefinedOperator_binaryExpression_inSubtype() {
    Source source = addSource(r'''
class A {}
class B extends A {
  operator +(B b) {}
}
f(var a) {
  if(a is A) {
    a + 1;
  }
}''');
    resolve(source);
    assertNoErrors(source);
  }

  void test_undefinedOperator_indexBoth_inSubtype() {
    Source source = addSource(r'''
class A {}
class B extends A {
  operator [](int index) {}
}
f(var a) {
  if(a is A) {
    a[0]++;
  }
}''');
    resolve(source);
    assertNoErrors(source);
  }

  void test_undefinedOperator_indexGetter_inSubtype() {
    Source source = addSource(r'''
class A {}
class B extends A {
  operator [](int index) {}
}
f(var a) {
  if(a is A) {
    a[0];
  }
}''');
    resolve(source);
    assertNoErrors(source);
  }

  void test_undefinedOperator_indexSetter_inSubtype() {
    Source source = addSource(r'''
class A {}
class B extends A {
  operator []=(i, v) {}
}
f(var a) {
  if(a is A) {
    a[0] = 1;
  }
}''');
    resolve(source);
    assertNoErrors(source);
  }

  void test_undefinedOperator_postfixExpression() {
    Source source = addSource(r'''
class A {}
class B extends A {
  operator +(B b) {return new B();}
}
f(var a) {
  if(a is A) {
    a++;
  }
}''');
    resolve(source);
    assertNoErrors(source);
  }

  void test_undefinedOperator_prefixExpression() {
    Source source = addSource(r'''
class A {}
class B extends A {
  operator +(B b) {return new B();}
}
f(var a) {
  if(a is A) {
    ++a;
  }
}''');
    resolve(source);
    assertNoErrors(source);
  }

  void test_undefinedSetter_inSubtype() {
    Source source = addSource(r'''
class A {}
class B extends A {
  set b(x) {}
}
f(var a) {
  if(a is A) {
    a.b = 0;
  }
}''');
    resolve(source);
    assertNoErrors(source);
  }

  void test_unnecessaryCast_13855_parameter_A() {
    // dartbug.com/13855, dartbug.com/13732
    Source source = addSource(r'''
class A{
  a() {}
}
class B<E> {
  E e;
  m() {
    (e as A).a();
  }
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unnecessaryCast_dynamic_type() {
    Source source = addSource(r'''
m(v) {
  var b = v as Object;
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unnecessaryCast_generics() {
    // dartbug.com/18953
    Source source = addSource(r'''
import 'dart:async';
Future<int> f() => new Future.value(0);
void g(bool c) {
  (c ? f(): new Future.value(0) as Future<int>).then((int value) {});
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unnecessaryCast_type_dynamic() {
    Source source = addSource(r'''
m(v) {
  var b = Object as dynamic;
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedImport_annotationOnDirective() {
    Source source = addSource(r'''
library L;
@A()
import 'lib1.dart';''');
    Source source2 = addNamedSource("/lib1.dart", r'''
library lib1;
class A {
  const A() {}
}''');
    resolve(source);
    assertErrors(source);
    verify([source, source2]);
  }

  void test_unusedImport_as_equalPrefixes() {
    // 18818
    Source source = addSource(r'''
library L;
import 'lib1.dart' as one;
import 'lib2.dart' as one;
one.A a;
one.B b;''');
    Source source2 = addNamedSource("/lib1.dart", r'''
library lib1;
class A {}''');
    Source source3 = addNamedSource("/lib2.dart", r'''
library lib2;
class B {}''');
    resolve(source);
    assertErrors(source);
    assertNoErrors(source2);
    assertNoErrors(source3);
    verify([source, source2, source3]);
  }

  void test_unusedImport_core_library() {
    Source source = addSource(r'''
library L;
import 'dart:core';''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedImport_export() {
    Source source = addSource(r'''
library L;
import 'lib1.dart';
Two two;''');
    addNamedSource("/lib1.dart", r'''
library lib1;
export 'lib2.dart';
class One {}''');
    addNamedSource("/lib2.dart", r'''
library lib2;
class Two {}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedImport_export2() {
    Source source = addSource(r'''
library L;
import 'lib1.dart';
Three three;''');
    addNamedSource("/lib1.dart", r'''
library lib1;
export 'lib2.dart';
class One {}''');
    addNamedSource("/lib2.dart", r'''
library lib2;
export 'lib3.dart';
class Two {}''');
    addNamedSource("/lib3.dart", r'''
library lib3;
class Three {}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedImport_export_infiniteLoop() {
    Source source = addSource(r'''
library L;
import 'lib1.dart';
Two two;''');
    addNamedSource("/lib1.dart", r'''
library lib1;
export 'lib2.dart';
class One {}''');
    addNamedSource("/lib2.dart", r'''
library lib2;
export 'lib3.dart';
class Two {}''');
    addNamedSource("/lib3.dart", r'''
library lib3;
export 'lib2.dart';
class Three {}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedImport_metadata() {
    Source source = addSource(r'''
library L;
@A(x)
import 'lib1.dart';
class A {
  final int value;
  const A(this.value);
}''');
    addNamedSource("/lib1.dart", r'''
library lib1;
const x = 0;''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_unusedImport_prefix_topLevelFunction() {
    Source source = addSource(r'''
library L;
import 'lib1.dart' hide topLevelFunction;
import 'lib1.dart' as one show topLevelFunction;
class A {
  static void x() {
    One o;
    one.topLevelFunction();
  }
}''');
    addNamedSource("/lib1.dart", r'''
library lib1;
class One {}
topLevelFunction() {}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_useOfVoidResult_implicitReturnValue() {
    Source source = addSource(r'''
f() {}
class A {
  n() {
    var a = f();
  }
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_useOfVoidResult_nonVoidReturnValue() {
    Source source = addSource(r'''
int f() => 1;
g() {
  var a = f();
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }
}

class PubSuggestionCodeTest extends ResolverTestCase {
  void test_import_package() {
    Source source = addSource("import 'package:somepackage/other.dart';");
    resolve(source);
    assertErrors(source, [CompileTimeErrorCode.URI_DOES_NOT_EXIST]);
  }

  void test_import_packageWithDotDot() {
    Source source = addSource("import 'package:somepackage/../other.dart';");
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.URI_DOES_NOT_EXIST,
            HintCode.PACKAGE_IMPORT_CONTAINS_DOT_DOT]);
  }

  void test_import_packageWithLeadingDotDot() {
    Source source = addSource("import 'package:../other.dart';");
    resolve(source);
    assertErrors(
        source,
        [
            CompileTimeErrorCode.URI_DOES_NOT_EXIST,
            HintCode.PACKAGE_IMPORT_CONTAINS_DOT_DOT]);
  }

  void test_import_referenceIntoLibDirectory() {
    cacheSource("/myproj/pubspec.yaml", "");
    cacheSource("/myproj/lib/other.dart", "");
    Source source =
        addNamedSource("/myproj/web/test.dart", "import '../lib/other.dart';");
    resolve(source);
    assertErrors(
        source,
        [HintCode.FILE_IMPORT_OUTSIDE_LIB_REFERENCES_FILE_INSIDE]);
  }

  void test_import_referenceIntoLibDirectory_no_pubspec() {
    cacheSource("/myproj/lib/other.dart", "");
    Source source =
        addNamedSource("/myproj/web/test.dart", "import '../lib/other.dart';");
    resolve(source);
    assertNoErrors(source);
  }

  void test_import_referenceOutOfLibDirectory() {
    cacheSource("/myproj/pubspec.yaml", "");
    cacheSource("/myproj/web/other.dart", "");
    Source source =
        addNamedSource("/myproj/lib/test.dart", "import '../web/other.dart';");
    resolve(source);
    assertErrors(
        source,
        [HintCode.FILE_IMPORT_INSIDE_LIB_REFERENCES_FILE_OUTSIDE]);
  }

  void test_import_referenceOutOfLibDirectory_no_pubspec() {
    cacheSource("/myproj/web/other.dart", "");
    Source source =
        addNamedSource("/myproj/lib/test.dart", "import '../web/other.dart';");
    resolve(source);
    assertNoErrors(source);
  }

  void test_import_valid_inside_lib1() {
    cacheSource("/myproj/pubspec.yaml", "");
    cacheSource("/myproj/lib/other.dart", "");
    Source source =
        addNamedSource("/myproj/lib/test.dart", "import 'other.dart';");
    resolve(source);
    assertNoErrors(source);
  }

  void test_import_valid_inside_lib2() {
    cacheSource("/myproj/pubspec.yaml", "");
    cacheSource("/myproj/lib/bar/other.dart", "");
    Source source =
        addNamedSource("/myproj/lib/foo/test.dart", "import '../bar/other.dart';");
    resolve(source);
    assertNoErrors(source);
  }

  void test_import_valid_outside_lib() {
    cacheSource("/myproj/pubspec.yaml", "");
    cacheSource("/myproj/web/other.dart", "");
    Source source =
        addNamedSource("/myproj/lib2/test.dart", "import '../web/other.dart';");
    resolve(source);
    assertNoErrors(source);
  }
}

/**
 * Instances of the class `ResolutionVerifier` verify that all of the nodes in an AST
 * structure that should have been resolved were resolved.
 */
class ResolutionVerifier extends RecursiveAstVisitor<Object> {
  /**
   * A set containing nodes that are known to not be resolvable and should therefore not cause the
   * test to fail.
   */
  final Set<AstNode> _knownExceptions;

  /**
   * A list containing all of the AST nodes that were not resolved.
   */
  List<AstNode> _unresolvedNodes = new List<AstNode>();

  /**
   * A list containing all of the AST nodes that were resolved to an element of the wrong type.
   */
  List<AstNode> _wrongTypedNodes = new List<AstNode>();

  /**
   * Initialize a newly created verifier to verify that all of the nodes in the visited AST
   * structures that are expected to have been resolved have an element associated with them.
   */
  ResolutionVerifier() : this.con1(null);

  /**
   * Initialize a newly created verifier to verify that all of the identifiers in the visited AST
   * structures that are expected to have been resolved have an element associated with them. Nodes
   * in the set of known exceptions are not expected to have been resolved, even if they normally
   * would have been expected to have been resolved.
   *
   * @param knownExceptions a set containing nodes that are known to not be resolvable and should
   *          therefore not cause the test to fail
   **/
  ResolutionVerifier.con1(this._knownExceptions);

  /**
   * Assert that all of the visited identifiers were resolved.
   */
  void assertResolved() {
    if (!_unresolvedNodes.isEmpty || !_wrongTypedNodes.isEmpty) {
      StringBuffer buffer = new StringBuffer();
      if (!_unresolvedNodes.isEmpty) {
        buffer.write("Failed to resolve ");
        buffer.write(_unresolvedNodes.length);
        buffer.writeln(" nodes:");
        _printNodes(buffer, _unresolvedNodes);
      }
      if (!_wrongTypedNodes.isEmpty) {
        buffer.write("Resolved ");
        buffer.write(_wrongTypedNodes.length);
        buffer.writeln(" to the wrong type of element:");
        _printNodes(buffer, _wrongTypedNodes);
      }
      fail(buffer.toString());
    }
  }

  @override
  Object visitAnnotation(Annotation node) {
    node.visitChildren(this);
    ElementAnnotation elementAnnotation = node.elementAnnotation;
    if (elementAnnotation == null) {
      if (_knownExceptions == null || !_knownExceptions.contains(node)) {
        _unresolvedNodes.add(node);
      }
    } else if (elementAnnotation is! ElementAnnotation) {
      _wrongTypedNodes.add(node);
    }
    return null;
  }

  @override
  Object visitBinaryExpression(BinaryExpression node) {
    node.visitChildren(this);
    if (!node.operator.isUserDefinableOperator) {
      return null;
    }
    DartType operandType = node.leftOperand.staticType;
    if (operandType == null || operandType.isDynamic) {
      return null;
    }
    return _checkResolved(
        node,
        node.staticElement,
        (node) => node is MethodElement);
  }

  @override
  Object visitCommentReference(CommentReference node) => null;

  @override
  Object visitCompilationUnit(CompilationUnit node) {
    node.visitChildren(this);
    return _checkResolved(
        node,
        node.element,
        (node) => node is CompilationUnitElement);
  }

  @override
  Object visitExportDirective(ExportDirective node) =>
      _checkResolved(node, node.element, (node) => node is ExportElement);

  @override
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    node.visitChildren(this);
    if (node.element is LibraryElement) {
      _wrongTypedNodes.add(node);
    }
    return null;
  }

  @override
  Object visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    node.visitChildren(this);
    // TODO(brianwilkerson) If we start resolving function expressions, then
    // conditionally check to see whether the node was resolved correctly.
    return null;
    //checkResolved(node, node.getElement(), FunctionElement.class);
  }

  @override
  Object visitImportDirective(ImportDirective node) {
    // Not sure how to test the combinators given that it isn't an error if the
    // names are not defined.
    _checkResolved(node, node.element, (node) => node is ImportElement);
    SimpleIdentifier prefix = node.prefix;
    if (prefix == null) {
      return null;
    }
    return _checkResolved(
        prefix,
        prefix.staticElement,
        (node) => node is PrefixElement);
  }

  @override
  Object visitIndexExpression(IndexExpression node) {
    node.visitChildren(this);
    DartType targetType = node.realTarget.staticType;
    if (targetType == null || targetType.isDynamic) {
      return null;
    }
    return _checkResolved(
        node,
        node.staticElement,
        (node) => node is MethodElement);
  }

  @override
  Object visitLibraryDirective(LibraryDirective node) =>
      _checkResolved(node, node.element, (node) => node is LibraryElement);

  @override
  Object visitNamedExpression(NamedExpression node) =>
      node.expression.accept(this);

  @override
  Object visitPartDirective(PartDirective node) =>
      _checkResolved(node, node.element, (node) => node is CompilationUnitElement);

  @override
  Object visitPartOfDirective(PartOfDirective node) =>
      _checkResolved(node, node.element, (node) => node is LibraryElement);

  @override
  Object visitPostfixExpression(PostfixExpression node) {
    node.visitChildren(this);
    if (!node.operator.isUserDefinableOperator) {
      return null;
    }
    DartType operandType = node.operand.staticType;
    if (operandType == null || operandType.isDynamic) {
      return null;
    }
    return _checkResolved(
        node,
        node.staticElement,
        (node) => node is MethodElement);
  }

  @override
  Object visitPrefixedIdentifier(PrefixedIdentifier node) {
    SimpleIdentifier prefix = node.prefix;
    prefix.accept(this);
    DartType prefixType = prefix.staticType;
    if (prefixType == null || prefixType.isDynamic) {
      return null;
    }
    return _checkResolved(node, node.staticElement, null);
  }

  @override
  Object visitPrefixExpression(PrefixExpression node) {
    node.visitChildren(this);
    if (!node.operator.isUserDefinableOperator) {
      return null;
    }
    DartType operandType = node.operand.staticType;
    if (operandType == null || operandType.isDynamic) {
      return null;
    }
    return _checkResolved(
        node,
        node.staticElement,
        (node) => node is MethodElement);
  }

  @override
  Object visitPropertyAccess(PropertyAccess node) {
    Expression target = node.realTarget;
    target.accept(this);
    DartType targetType = target.staticType;
    if (targetType == null || targetType.isDynamic) {
      return null;
    }
    return node.propertyName.accept(this);
  }

  @override
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name == "void") {
      return null;
    }
    AstNode parent = node.parent;
    if (parent is MethodInvocation) {
      MethodInvocation invocation = parent;
      if (identical(invocation.methodName, node)) {
        Expression target = invocation.realTarget;
        DartType targetType = target == null ? null : target.staticType;
        if (targetType == null || targetType.isDynamic) {
          return null;
        }
      }
    }
    return _checkResolved(node, node.staticElement, null);
  }

  Object _checkResolved(AstNode node, Element element,
      Predicate<Element> predicate) {
    if (element == null) {
      if (_knownExceptions == null || !_knownExceptions.contains(node)) {
        _unresolvedNodes.add(node);
      }
    } else if (predicate != null) {
      if (!predicate(element)) {
        _wrongTypedNodes.add(node);
      }
    }
    return null;
  }

  String _getFileName(AstNode node) {
    // TODO (jwren) there are two copies of this method, one here and one in
    // StaticTypeVerifier, they should be resolved into a single method
    if (node != null) {
      AstNode root = node.root;
      if (root is CompilationUnit) {
        CompilationUnit rootCU = root;
        if (rootCU.element != null) {
          return rootCU.element.source.fullName;
        } else {
          return "<unknown file- CompilationUnit.getElement() returned null>";
        }
      } else {
        return
            "<unknown file- CompilationUnit.getRoot() is not a CompilationUnit>";
      }
    }
    return "<unknown file- ASTNode is null>";
  }

  void _printNodes(StringBuffer buffer, List<AstNode> nodes) {
    for (AstNode identifier in nodes) {
      buffer.write("  ");
      buffer.write(identifier.toString());
      buffer.write(" (");
      buffer.write(_getFileName(identifier));
      buffer.write(" : ");
      buffer.write(identifier.offset);
      buffer.writeln(")");
    }
  }
}

class ResolverTestCase extends EngineTestCase {
  /**
   * The analysis context used to parse the compilation units being resolved.
   */
  AnalysisContextImpl analysisContext2;

  /**
   * Specifies if [assertErrors] should check for [HintCode.UNUSED_ELEMENT] and
   * [HintCode.UNUSED_FIELD].
   */
  bool enableUnusedElement = false;

  /**
   * Specifies if [assertErrors] should check for [HintCode.UNUSED_LOCAL_VARIABLE].
   */
  bool enableUnusedLocalVariable = false;

  AnalysisContext get analysisContext => analysisContext2;

  /**
   * Return a type provider that can be used to test the results of resolution.
   *
   * @return a type provider
   * @throws AnalysisException if dart:core cannot be resolved
   */
  TypeProvider get typeProvider => analysisContext2.typeProvider;

  /**
   * Add a source file to the content provider. The file path should be absolute.
   *
   * @param filePath the path of the file being added
   * @param contents the contents to be returned by the content provider for the specified file
   * @return the source object representing the added file
   */
  Source addNamedSource(String filePath, String contents) {
    Source source = cacheSource(filePath, contents);
    ChangeSet changeSet = new ChangeSet();
    changeSet.addedSource(source);
    analysisContext2.applyChanges(changeSet);
    return source;
  }

  /**
   * Add a source file to the content provider.
   *
   * @param contents the contents to be returned by the content provider for the specified file
   * @return the source object representing the added file
   */
  Source addSource(String contents) => addNamedSource("/test.dart", contents);

  /**
   * Assert that the number of errors reported against the given source matches the number of errors
   * that are given and that they have the expected error codes. The order in which the errors were
   * gathered is ignored.
   *
   * @param source the source against which the errors should have been reported
   * @param expectedErrorCodes the error codes of the errors that should have been reported
   * @throws AnalysisException if the reported errors could not be computed
   * @throws AssertionFailedError if a different number of errors have been reported than were
   *           expected
   */
  void assertErrors(Source source, [List<ErrorCode> expectedErrorCodes =
      ErrorCode.EMPTY_LIST]) {
    GatheringErrorListener errorListener = new GatheringErrorListener();
    for (AnalysisError error in analysisContext2.computeErrors(source)) {
      ErrorCode errorCode = error.errorCode;
      if (!enableUnusedElement &&
          (errorCode == HintCode.UNUSED_ELEMENT || errorCode == HintCode.UNUSED_FIELD)) {
        continue;
      }
      if (!enableUnusedLocalVariable &&
          errorCode == HintCode.UNUSED_LOCAL_VARIABLE) {
        continue;
      }
      errorListener.onError(error);
    }
    errorListener.assertErrorsWithCodes(expectedErrorCodes);
  }

  /**
   * Assert that no errors have been reported against the given source.
   *
   * @param source the source against which no errors should have been reported
   * @throws AnalysisException if the reported errors could not be computed
   * @throws AssertionFailedError if any errors have been reported
   */
  void assertNoErrors(Source source) {
    assertErrors(source);
  }

  /**
   * Cache the source file content in the source factory but don't add the source to the analysis
   * context. The file path should be absolute.
   *
   * @param filePath the path of the file being cached
   * @param contents the contents to be returned by the content provider for the specified file
   * @return the source object representing the cached file
   */
  Source cacheSource(String filePath, String contents) {
    Source source =
        new FileBasedSource.con1(FileUtilities2.createFile(filePath));
    analysisContext2.setContents(source, contents);
    return source;
  }

  /**
   * Create a library element that represents a library named `"test"` containing a single
   * empty compilation unit.
   *
   * @return the library element that was created
   */
  LibraryElementImpl createDefaultTestLibrary() =>
      createTestLibrary(new AnalysisContextImpl(), "test");

  /**
   * Create a library element that represents a library with the given name containing a single
   * empty compilation unit.
   *
   * @param libraryName the name of the library to be created
   * @return the library element that was created
   */
  LibraryElementImpl createTestLibrary(AnalysisContext context,
      String libraryName, [List<String> typeNames]) {
    List<CompilationUnitElement> sourcedCompilationUnits;
    if (typeNames == null) {
      sourcedCompilationUnits = CompilationUnitElementImpl.EMPTY_ARRAY;
    } else {
      int count = typeNames.length;
      sourcedCompilationUnits = new List<CompilationUnitElement>(count);
      for (int i = 0; i < count; i++) {
        String typeName = typeNames[i];
        ClassElementImpl type =
            new ClassElementImpl.forNode(AstFactory.identifier3(typeName));
        String fileName = "$typeName.dart";
        CompilationUnitElementImpl compilationUnit =
            new CompilationUnitElementImpl(fileName);
        compilationUnit.source = _createNamedSource(fileName);
        compilationUnit.types = <ClassElement>[type];
        sourcedCompilationUnits[i] = compilationUnit;
      }
    }
    String fileName = "$libraryName.dart";
    CompilationUnitElementImpl compilationUnit =
        new CompilationUnitElementImpl(fileName);
    compilationUnit.source = _createNamedSource(fileName);
    LibraryElementImpl library = new LibraryElementImpl.forNode(
        context,
        AstFactory.libraryIdentifier2([libraryName]));
    library.definingCompilationUnit = compilationUnit;
    library.parts = sourcedCompilationUnits;
    return library;
  }

  /**
   * Enable optionally strict union types for the current test.
   *
   * @param strictUnionTypes `true` if union types should be strict.
   */
  void enableUnionTypes(bool strictUnionTypes) {
    AnalysisEngine.instance.enableUnionTypes = true;
    AnalysisEngine.instance.strictUnionTypes = strictUnionTypes;
  }

  Expression findTopLevelConstantExpression(CompilationUnit compilationUnit,
      String name) =>
      findTopLevelDeclaration(compilationUnit, name).initializer;

  VariableDeclaration findTopLevelDeclaration(CompilationUnit compilationUnit,
      String name) {
    for (CompilationUnitMember member in compilationUnit.declarations) {
      if (member is TopLevelVariableDeclaration) {
        for (VariableDeclaration variable in member.variables.variables) {
          if (variable.name.name == name) {
            return variable;
          }
        }
      }
    }
    return null;
    // Not found
  }

  /**
   * In the rare cases we want to group several tests into single "test_" method, so need a way to
   * reset test instance to reuse it.
   */
  void reset() {
    analysisContext2 = AnalysisContextFactory.contextWithCore();
    // These defaults are duplicated for the editor in
    // editor/tools/plugins/com.google.dart.tools.core/.options .
    AnalysisEngine.instance.enableUnionTypes = false;
    AnalysisEngine.instance.strictUnionTypes = false;
  }

  /**
   * Reset the analysis context to have the 'enableAsync' option set to true.
   */
  void resetWithAsync() {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.enableAsync = true;
    analysisContext2 =
        AnalysisContextFactory.contextWithCoreAndOptions(options);
  }

  /**
   * Reset the analysis context to have the 'enableEnum' option set to true.
   */
  void resetWithEnum() {
    AnalysisOptionsImpl analysisOptions = new AnalysisOptionsImpl();
    analysisOptions.enableEnum = true;
    resetWithOptions(analysisOptions);
  }

  /**
   * Reset the analysis context to have the given options applied.
   *
   * @param options the analysis options to be applied to the context
   */
  void resetWithOptions(AnalysisOptions options) {
    analysisContext2 =
        AnalysisContextFactory.contextWithCoreAndOptions(options);
  }

  /**
   * Given a library and all of its parts, resolve the contents of the library and the contents of
   * the parts. This assumes that the sources for the library and its parts have already been added
   * to the content provider using the method [addNamedSource].
   *
   * @param librarySource the source for the compilation unit that defines the library
   * @return the element representing the resolved library
   * @throws AnalysisException if the analysis could not be performed
   */
  LibraryElement resolve(Source librarySource) =>
      analysisContext2.computeLibraryElement(librarySource);

  /**
   * Return the resolved compilation unit corresponding to the given source in the given library.
   *
   * @param source the source of the compilation unit to be returned
   * @param library the library in which the compilation unit is to be resolved
   * @return the resolved compilation unit
   * @throws Exception if the compilation unit could not be resolved
   */
  CompilationUnit resolveCompilationUnit(Source source,
      LibraryElement library) =>
      analysisContext2.resolveCompilationUnit(source, library);

  CompilationUnit resolveSource(String sourceText) =>
      resolveSource2("/test.dart", sourceText);

  CompilationUnit resolveSource2(String fileName, String sourceText) {
    Source source = addNamedSource(fileName, sourceText);
    LibraryElement library = analysisContext.computeLibraryElement(source);
    return analysisContext.resolveCompilationUnit(source, library);
  }

  Source resolveSources(List<String> sourceTexts) {
    for (int i = 0; i < sourceTexts.length; i++) {
      CompilationUnit unit =
          resolveSource2("/lib${i + 1}.dart", sourceTexts[i]);
      // reference the source if this is the last source
      if (i + 1 == sourceTexts.length) {
        return unit.element.source;
      }
    }
    return null;
  }

  void resolveWithAndWithoutExperimental(List<String> strSources,
      List<ErrorCode> codesWithoutExperimental,
      List<ErrorCode> codesWithExperimental) {
    // Setup analysis context as non-experimental
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.enableDeferredLoading = false;
    resetWithOptions(options);
    // Analysis and assertions
    Source source = resolveSources(strSources);
    assertErrors(source, codesWithoutExperimental);
    verify([source]);
    // Setup analysis context as experimental
    reset();
    // Analysis and assertions
    source = resolveSources(strSources);
    assertErrors(source, codesWithExperimental);
    verify([source]);
  }

  @override
  void setUp() {
    reset();
  }

  @override
  void tearDown() {
    analysisContext2 = null;
    super.tearDown();
  }

  /**
   * Verify that all of the identifiers in the compilation units associated with the given sources
   * have been resolved.
   *
   * @param resolvedElementMap a table mapping the AST nodes that have been resolved to the element
   *          to which they were resolved
   * @param sources the sources identifying the compilation units to be verified
   * @throws Exception if the contents of the compilation unit cannot be accessed
   */
  void verify(List<Source> sources) {
    ResolutionVerifier verifier = new ResolutionVerifier();
    for (Source source in sources) {
      analysisContext2.parseCompilationUnit(source).accept(verifier);
    }
    verifier.assertResolved();
  }

  /**
   * Create a source object representing a file with the given name and give it an empty content.
   *
   * @param fileName the name of the file for which a source is to be created
   * @return the source that was created
   */
  FileBasedSource _createNamedSource(String fileName) {
    FileBasedSource source =
        new FileBasedSource.con1(FileUtilities2.createFile(fileName));
    analysisContext2.setContents(source, "");
    return source;
  }
}

class Scope_EnclosedScopeTest_test_define_duplicate extends Scope {
  GatheringErrorListener listener;

  Scope_EnclosedScopeTest_test_define_duplicate(this.listener) : super();

  @override
  AnalysisErrorListener get errorListener => listener;

  @override
  Element internalLookup(Identifier identifier, String name,
      LibraryElement referencingLibrary) =>
      null;
}

class Scope_EnclosedScopeTest_test_define_normal extends Scope {
  GatheringErrorListener listener;

  Scope_EnclosedScopeTest_test_define_normal(this.listener) : super();

  @override
  AnalysisErrorListener get errorListener => listener;

  @override
  Element internalLookup(Identifier identifier, String name,
      LibraryElement referencingLibrary) =>
      null;
}

class ScopeTest extends ResolverTestCase {
  void test_define_duplicate() {
    GatheringErrorListener errorListener = new GatheringErrorListener();
    ScopeTest_TestScope scope = new ScopeTest_TestScope(errorListener);
    VariableElement element1 =
        ElementFactory.localVariableElement(AstFactory.identifier3("v1"));
    VariableElement element2 =
        ElementFactory.localVariableElement(AstFactory.identifier3("v1"));
    scope.define(element1);
    scope.define(element2);
    errorListener.assertErrorsWithSeverities([ErrorSeverity.ERROR]);
  }

  void test_define_normal() {
    GatheringErrorListener errorListener = new GatheringErrorListener();
    ScopeTest_TestScope scope = new ScopeTest_TestScope(errorListener);
    VariableElement element1 =
        ElementFactory.localVariableElement(AstFactory.identifier3("v1"));
    VariableElement element2 =
        ElementFactory.localVariableElement(AstFactory.identifier3("v2"));
    scope.define(element1);
    scope.define(element2);
    errorListener.assertNoErrors();
  }

  void test_getErrorListener() {
    GatheringErrorListener errorListener = new GatheringErrorListener();
    ScopeTest_TestScope scope = new ScopeTest_TestScope(errorListener);
    expect(scope.errorListener, errorListener);
  }

  void test_isPrivateName_nonPrivate() {
    expect(Scope.isPrivateName("Public"), isFalse);
  }

  void test_isPrivateName_private() {
    expect(Scope.isPrivateName("_Private"), isTrue);
  }
}

/**
 * A non-abstract subclass that can be used for testing purposes.
 */
class ScopeTest_TestScope extends Scope {
  /**
   * The listener that is to be informed when an error is encountered.
   */
  final AnalysisErrorListener errorListener;

  ScopeTest_TestScope(this.errorListener);

  @override
  Element internalLookup(Identifier identifier, String name,
      LibraryElement referencingLibrary) =>
      localLookup(name, referencingLibrary);
}

class SimpleResolverTest extends ResolverTestCase {
  void fail_staticInvocation() {
    Source source = addSource(r'''
class A {
  static int get g => (a,b) => 0;
}
class B {
  f() {
    A.g(1,0);
  }
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_argumentResolution_required_matching() {
    Source source = addSource(r'''
class A {
  void f() {
    g(1, 2, 3);
  }
  void g(a, b, c) {}
}''');
    _validateArgumentResolution(source, [0, 1, 2]);
  }

  void test_argumentResolution_required_tooFew() {
    Source source = addSource(r'''
class A {
  void f() {
    g(1, 2);
  }
  void g(a, b, c) {}
}''');
    _validateArgumentResolution(source, [0, 1]);
  }

  void test_argumentResolution_required_tooMany() {
    Source source = addSource(r'''
class A {
  void f() {
    g(1, 2, 3);
  }
  void g(a, b) {}
}''');
    _validateArgumentResolution(source, [0, 1, -1]);
  }

  void test_argumentResolution_requiredAndNamed_extra() {
    Source source = addSource(r'''
class A {
  void f() {
    g(1, 2, c: 3, d: 4);
  }
  void g(a, b, {c}) {}
}''');
    _validateArgumentResolution(source, [0, 1, 2, -1]);
  }

  void test_argumentResolution_requiredAndNamed_matching() {
    Source source = addSource(r'''
class A {
  void f() {
    g(1, 2, c: 3);
  }
  void g(a, b, {c}) {}
}''');
    _validateArgumentResolution(source, [0, 1, 2]);
  }

  void test_argumentResolution_requiredAndNamed_missing() {
    Source source = addSource(r'''
class A {
  void f() {
    g(1, 2, d: 3);
  }
  void g(a, b, {c, d}) {}
}''');
    _validateArgumentResolution(source, [0, 1, 3]);
  }

  void test_argumentResolution_requiredAndPositional_fewer() {
    Source source = addSource(r'''
class A {
  void f() {
    g(1, 2, 3);
  }
  void g(a, b, [c, d]) {}
}''');
    _validateArgumentResolution(source, [0, 1, 2]);
  }

  void test_argumentResolution_requiredAndPositional_matching() {
    Source source = addSource(r'''
class A {
  void f() {
    g(1, 2, 3, 4);
  }
  void g(a, b, [c, d]) {}
}''');
    _validateArgumentResolution(source, [0, 1, 2, 3]);
  }

  void test_argumentResolution_requiredAndPositional_more() {
    Source source = addSource(r'''
class A {
  void f() {
    g(1, 2, 3, 4);
  }
  void g(a, b, [c]) {}
}''');
    _validateArgumentResolution(source, [0, 1, 2, -1]);
  }

  void test_argumentResolution_setter_propagated() {
    Source source = addSource(r'''
main() {
  var a = new A();
  a.sss = 0;
}
class A {
  set sss(x) {}
}''');
    LibraryElement library = resolve(source);
    CompilationUnitElement unit = library.definingCompilationUnit;
    // find "a.sss = 0"
    AssignmentExpression assignment;
    {
      FunctionElement mainElement = unit.functions[0];
      FunctionBody mainBody = mainElement.node.functionExpression.body;
      Statement statement = (mainBody as BlockFunctionBody).block.statements[1];
      ExpressionStatement expressionStatement =
          statement as ExpressionStatement;
      assignment = expressionStatement.expression as AssignmentExpression;
    }
    // get parameter
    Expression rhs = assignment.rightHandSide;
    expect(rhs.staticParameterElement, isNull);
    ParameterElement parameter = rhs.propagatedParameterElement;
    expect(parameter, isNotNull);
    expect(parameter.displayName, "x");
    // validate
    ClassElement classA = unit.types[0];
    PropertyAccessorElement setter = classA.accessors[0];
    expect(setter.parameters[0], same(parameter));
  }

  void test_argumentResolution_setter_propagated_propertyAccess() {
    Source source = addSource(r'''
main() {
  var a = new A();
  a.b.sss = 0;
}
class A {
  B b = new B();
}
class B {
  set sss(x) {}
}''');
    LibraryElement library = resolve(source);
    CompilationUnitElement unit = library.definingCompilationUnit;
    // find "a.b.sss = 0"
    AssignmentExpression assignment;
    {
      FunctionElement mainElement = unit.functions[0];
      FunctionBody mainBody = mainElement.node.functionExpression.body;
      Statement statement = (mainBody as BlockFunctionBody).block.statements[1];
      ExpressionStatement expressionStatement =
          statement as ExpressionStatement;
      assignment = expressionStatement.expression as AssignmentExpression;
    }
    // get parameter
    Expression rhs = assignment.rightHandSide;
    expect(rhs.staticParameterElement, isNull);
    ParameterElement parameter = rhs.propagatedParameterElement;
    expect(parameter, isNotNull);
    expect(parameter.displayName, "x");
    // validate
    ClassElement classB = unit.types[1];
    PropertyAccessorElement setter = classB.accessors[0];
    expect(setter.parameters[0], same(parameter));
  }

  void test_argumentResolution_setter_static() {
    Source source = addSource(r'''
main() {
  A a = new A();
  a.sss = 0;
}
class A {
  set sss(x) {}
}''');
    LibraryElement library = resolve(source);
    CompilationUnitElement unit = library.definingCompilationUnit;
    // find "a.sss = 0"
    AssignmentExpression assignment;
    {
      FunctionElement mainElement = unit.functions[0];
      FunctionBody mainBody = mainElement.node.functionExpression.body;
      Statement statement = (mainBody as BlockFunctionBody).block.statements[1];
      ExpressionStatement expressionStatement =
          statement as ExpressionStatement;
      assignment = expressionStatement.expression as AssignmentExpression;
    }
    // get parameter
    Expression rhs = assignment.rightHandSide;
    ParameterElement parameter = rhs.staticParameterElement;
    expect(parameter, isNotNull);
    expect(parameter.displayName, "x");
    // validate
    ClassElement classA = unit.types[0];
    PropertyAccessorElement setter = classA.accessors[0];
    expect(setter.parameters[0], same(parameter));
  }

  void test_argumentResolution_setter_static_propertyAccess() {
    Source source = addSource(r'''
main() {
  A a = new A();
  a.b.sss = 0;
}
class A {
  B b = new B();
}
class B {
  set sss(x) {}
}''');
    LibraryElement library = resolve(source);
    CompilationUnitElement unit = library.definingCompilationUnit;
    // find "a.b.sss = 0"
    AssignmentExpression assignment;
    {
      FunctionElement mainElement = unit.functions[0];
      FunctionBody mainBody = mainElement.node.functionExpression.body;
      Statement statement = (mainBody as BlockFunctionBody).block.statements[1];
      ExpressionStatement expressionStatement =
          statement as ExpressionStatement;
      assignment = expressionStatement.expression as AssignmentExpression;
    }
    // get parameter
    Expression rhs = assignment.rightHandSide;
    ParameterElement parameter = rhs.staticParameterElement;
    expect(parameter, isNotNull);
    expect(parameter.displayName, "x");
    // validate
    ClassElement classB = unit.types[1];
    PropertyAccessorElement setter = classB.accessors[0];
    expect(setter.parameters[0], same(parameter));
  }

  void test_breakTarget_labeled() {
    // Verify that the target of the label is correctly found and is recorded
    // as the unlabeled portion of the statement.
    String text = r'''
void f() {
  loop1: while (true) {
    loop2: for (int i = 0; i < 10; i++) {
      break loop1;
      break loop2;
    }
  }
}
''';
    CompilationUnit unit = resolveSource(text);
    WhileStatement whileStatement = EngineTestCase.findNode(
        unit,
        text,
        'while (true)',
        (n) => n is WhileStatement);
    ForStatement forStatement =
        EngineTestCase.findNode(unit, text, 'for', (n) => n is ForStatement);
    BreakStatement break1 =
        EngineTestCase.findNode(unit, text, 'break loop1', (n) => n is BreakStatement);
    BreakStatement break2 =
        EngineTestCase.findNode(unit, text, 'break loop2', (n) => n is BreakStatement);
    expect(break1.target, same(whileStatement));
    expect(break2.target, same(forStatement));
  }

  void test_breakTarget_unlabeledBreakFromDo() {
    String text = r'''
void f() {
  do {
    break;
  } while (true);
}
''';
    CompilationUnit unit = resolveSource(text);
    DoStatement doStatement =
        EngineTestCase.findNode(unit, text, 'do', (n) => n is DoStatement);
    BreakStatement breakStatement =
        EngineTestCase.findNode(unit, text, 'break', (n) => n is BreakStatement);
    expect(breakStatement.target, same(doStatement));
  }

  void test_breakTarget_unlabeledBreakFromFor() {
    String text = r'''
void f() {
  for (int i = 0; i < 10; i++) {
    break;
  }
}
''';
    CompilationUnit unit = resolveSource(text);
    ForStatement forStatement =
        EngineTestCase.findNode(unit, text, 'for', (n) => n is ForStatement);
    BreakStatement breakStatement =
        EngineTestCase.findNode(unit, text, 'break', (n) => n is BreakStatement);
    expect(breakStatement.target, same(forStatement));
  }

  void test_breakTarget_unlabeledBreakFromForEach() {
    String text = r'''
void f() {
  for (x in []) {
    break;
  }
}
''';
    CompilationUnit unit = resolveSource(text);
    ForEachStatement forStatement =
        EngineTestCase.findNode(unit, text, 'for', (n) => n is ForEachStatement);
    BreakStatement breakStatement =
        EngineTestCase.findNode(unit, text, 'break', (n) => n is BreakStatement);
    expect(breakStatement.target, same(forStatement));
  }

  void test_breakTarget_unlabeledBreakFromSwitch() {
    String text = r'''
void f() {
  while (true) {
    switch (0) {
      case 0:
        break;
    }
  }
}
''';
    CompilationUnit unit = resolveSource(text);
    SwitchStatement switchStatement =
        EngineTestCase.findNode(unit, text, 'switch', (n) => n is SwitchStatement);
    BreakStatement breakStatement =
        EngineTestCase.findNode(unit, text, 'break', (n) => n is BreakStatement);
    expect(breakStatement.target, same(switchStatement));
  }

  void test_breakTarget_unlabeledBreakFromWhile() {
    String text = r'''
void f() {
  while (true) {
    break;
  }
}
''';
    CompilationUnit unit = resolveSource(text);
    WhileStatement whileStatement =
        EngineTestCase.findNode(unit, text, 'while', (n) => n is WhileStatement);
    BreakStatement breakStatement =
        EngineTestCase.findNode(unit, text, 'break', (n) => n is BreakStatement);
    expect(breakStatement.target, same(whileStatement));
  }

  void test_breakTarget_unlabeledBreakToOuterFunction() {
    // Verify that unlabeled break statements can't resolve to loops in an
    // outer function.
    String text = r'''
void f() {
  while (true) {
    void g() {
      break;
    }
  }
}
''';
    CompilationUnit unit = resolveSource(text);
    BreakStatement breakStatement =
        EngineTestCase.findNode(unit, text, 'break', (n) => n is BreakStatement);
    expect(breakStatement.target, isNull);
  }

  void test_class_definesCall() {
    Source source = addSource(r'''
class A {
  int call(int x) { return x; }
}
int f(A a) {
  return a(0);
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_class_extends_implements() {
    Source source = addSource(r'''
class A extends B implements C {}
class B {}
class C {}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_commentReference_class() {
    Source source = addSource(r'''
f() {}
/** [A] [new A] [A.n] [new A.n] [m] [f] */
class A {
  A() {}
  A.n() {}
  m() {}
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_commentReference_parameter() {
    Source source = addSource(r'''
class A {
  A() {}
  A.n() {}
  /** [e] [f] */
  m(e, f()) {}
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_commentReference_singleLine() {
    Source source = addSource(r'''
/// [A]
class A {}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_continueTarget_labeled() {
    // Verify that the target of the label is correctly found and is recorded
    // as the unlabeled portion of the statement.
    String text = r'''
void f() {
  loop1: while (true) {
    loop2: for (int i = 0; i < 10; i++) {
      continue loop1;
      continue loop2;
    }
  }
}
''';
    CompilationUnit unit = resolveSource(text);
    WhileStatement whileStatement = EngineTestCase.findNode(
        unit,
        text,
        'while (true)',
        (n) => n is WhileStatement);
    ForStatement forStatement =
        EngineTestCase.findNode(unit, text, 'for', (n) => n is ForStatement);
    ContinueStatement continue1 = EngineTestCase.findNode(
        unit,
        text,
        'continue loop1',
        (n) => n is ContinueStatement);
    ContinueStatement continue2 = EngineTestCase.findNode(
        unit,
        text,
        'continue loop2',
        (n) => n is ContinueStatement);
    expect(continue1.target, same(whileStatement));
    expect(continue2.target, same(forStatement));
  }

  void test_continueTarget_unlabeledContinueFromDo() {
    String text = r'''
void f() {
  do {
    continue;
  } while (true);
}
''';
    CompilationUnit unit = resolveSource(text);
    DoStatement doStatement =
        EngineTestCase.findNode(unit, text, 'do', (n) => n is DoStatement);
    ContinueStatement continueStatement =
        EngineTestCase.findNode(unit, text, 'continue', (n) => n is ContinueStatement);
    expect(continueStatement.target, same(doStatement));
  }

  void test_continueTarget_unlabeledContinueFromFor() {
    String text = r'''
void f() {
  for (int i = 0; i < 10; i++) {
    continue;
  }
}
''';
    CompilationUnit unit = resolveSource(text);
    ForStatement forStatement =
        EngineTestCase.findNode(unit, text, 'for', (n) => n is ForStatement);
    ContinueStatement continueStatement =
        EngineTestCase.findNode(unit, text, 'continue', (n) => n is ContinueStatement);
    expect(continueStatement.target, same(forStatement));
  }

  void test_continueTarget_unlabeledContinueFromForEach() {
    String text = r'''
void f() {
  for (x in []) {
    continue;
  }
}
''';
    CompilationUnit unit = resolveSource(text);
    ForEachStatement forStatement =
        EngineTestCase.findNode(unit, text, 'for', (n) => n is ForEachStatement);
    ContinueStatement continueStatement =
        EngineTestCase.findNode(unit, text, 'continue', (n) => n is ContinueStatement);
    expect(continueStatement.target, same(forStatement));
  }

  void test_continueTarget_unlabeledContinueFromWhile() {
    String text = r'''
void f() {
  while (true) {
    continue;
  }
}
''';
    CompilationUnit unit = resolveSource(text);
    WhileStatement whileStatement =
        EngineTestCase.findNode(unit, text, 'while', (n) => n is WhileStatement);
    ContinueStatement continueStatement =
        EngineTestCase.findNode(unit, text, 'continue', (n) => n is ContinueStatement);
    expect(continueStatement.target, same(whileStatement));
  }

  void test_continueTarget_unlabeledContinueSkipsSwitch() {
    String text = r'''
void f() {
  while (true) {
    switch (0) {
      case 0:
        continue;
    }
  }
}
''';
    CompilationUnit unit = resolveSource(text);
    WhileStatement whileStatement =
        EngineTestCase.findNode(unit, text, 'while', (n) => n is WhileStatement);
    ContinueStatement continueStatement =
        EngineTestCase.findNode(unit, text, 'continue', (n) => n is ContinueStatement);
    expect(continueStatement.target, same(whileStatement));
  }

  void test_continueTarget_unlabeledContinueToOuterFunction() {
    // Verify that unlabeled continue statements can't resolve to loops in an
    // outer function.
    String text = r'''
void f() {
  while (true) {
    void g() {
      continue;
    }
  }
}
''';
    CompilationUnit unit = resolveSource(text);
    ContinueStatement continueStatement =
        EngineTestCase.findNode(unit, text, 'continue', (n) => n is ContinueStatement);
    expect(continueStatement.target, isNull);
  }

  void test_empty() {
    Source source = addSource("");
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_entryPoint_exported() {
    addNamedSource("/two.dart", r'''
library two;
main() {}''');
    Source source = addNamedSource("/one.dart", r'''
library one;
export 'two.dart';''');
    LibraryElement library = resolve(source);
    expect(library, isNotNull);
    FunctionElement main = library.entryPoint;
    expect(main, isNotNull);
    expect(main.library, isNot(same(library)));
    assertNoErrors(source);
    verify([source]);
  }

  void test_entryPoint_local() {
    Source source = addNamedSource("/one.dart", r'''
library one;
main() {}''');
    LibraryElement library = resolve(source);
    expect(library, isNotNull);
    FunctionElement main = library.entryPoint;
    expect(main, isNotNull);
    expect(main.library, same(library));
    assertNoErrors(source);
    verify([source]);
  }

  void test_entryPoint_none() {
    Source source = addNamedSource("/one.dart", "library one;");
    LibraryElement library = resolve(source);
    expect(library, isNotNull);
    expect(library.entryPoint, isNull);
    assertNoErrors(source);
    verify([source]);
  }

  void test_extractedMethodAsConstant() {
    Source source = addSource(r'''
abstract class Comparable<T> {
  int compareTo(T other);
  static int compare(Comparable a, Comparable b) => a.compareTo(b);
}
class A {
  void sort([compare = Comparable.compare]) {}
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_fieldFormalParameter() {
    Source source = addSource(r'''
class A {
  int x;
  A(this.x) {}
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_forEachLoops_nonConflicting() {
    Source source = addSource(r'''
f() {
  List list = [1,2,3];
  for (int x in list) {}
  for (int x in list) {}
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_forLoops_nonConflicting() {
    Source source = addSource(r'''
f() {
  for (int i = 0; i < 3; i++) {
  }
  for (int i = 0; i < 3; i++) {
  }
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_functionTypeAlias() {
    Source source = addSource(r'''
typedef bool P(e);
class A {
  P p;
  m(e) {
    if (p(e)) {}
  }
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_getterAndSetterWithDifferentTypes() {
    Source source = addSource(r'''
class A {
  int get f => 0;
  void set f(String s) {}
}
g (A a) {
  a.f = a.f.toString();
}''');
    resolve(source);
    assertErrors(
        source,
        [StaticWarningCode.MISMATCHED_GETTER_AND_SETTER_TYPES]);
    verify([source]);
  }

  void test_hasReferenceToSuper() {
    Source source = addSource(r'''
class A {}
class B {toString() => super.toString();}''');
    LibraryElement library = resolve(source);
    expect(library, isNotNull);
    CompilationUnitElement unit = library.definingCompilationUnit;
    expect(unit, isNotNull);
    List<ClassElement> classes = unit.types;
    expect(classes, hasLength(2));
    expect(classes[0].hasReferenceToSuper, isFalse);
    expect(classes[1].hasReferenceToSuper, isTrue);
    assertNoErrors(source);
    verify([source]);
  }

  void test_import_hide() {
    addNamedSource("lib1.dart", r'''
library lib1;
set foo(value) {}
class A {}''');
    addNamedSource("lib2.dart", r'''
library lib2;
set foo(value) {}''');
    Source source = addNamedSource("lib3.dart", r'''
import 'lib1.dart' hide foo;
import 'lib2.dart';

main() {
  foo = 0;
}
A a;''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_import_prefix() {
    addNamedSource("/two.dart", r'''
library two;
f(int x) {
  return x * x;
}''');
    Source source = addNamedSource("/one.dart", r'''
library one;
import 'two.dart' as _two;
main() {
  _two.f(0);
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_import_spaceInUri() {
    addNamedSource("sub folder/lib.dart", r'''
library lib;
foo() {}''');
    Source source = addNamedSource("app.dart", r'''
import 'sub folder/lib.dart';

main() {
  foo();
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_indexExpression_typeParameters() {
    Source source = addSource(r'''
f() {
  List<int> a;
  a[0];
  List<List<int>> b;
  b[0][0];
  List<List<List<int>>> c;
  c[0][0][0];
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_indexExpression_typeParameters_invalidAssignmentWarning() {
    Source source = addSource(r'''
f() {
  List<List<int>> b;
  b[0][0] = 'hi';
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.INVALID_ASSIGNMENT]);
    verify([source]);
  }

  void test_indirectOperatorThroughCall() {
    Source source = addSource(r'''
class A {
  B call() { return new B(); }
}

class B {
  int operator [](int i) { return i; }
}

A f = new A();

g(int x) {}

main() {
  g(f()[0]);
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_invoke_dynamicThroughGetter() {
    Source source = addSource(r'''
class A {
  List get X => [() => 0];
  m(A a) {
    X.last;
  }
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_isValidMixin_badSuperclass() {
    Source source = addSource(r'''
class A extends B {}
class B {}''');
    LibraryElement library = resolve(source);
    expect(library, isNotNull);
    CompilationUnitElement unit = library.definingCompilationUnit;
    expect(unit, isNotNull);
    List<ClassElement> classes = unit.types;
    expect(classes, hasLength(2));
    expect(classes[0].isValidMixin, isFalse);
    assertNoErrors(source);
    verify([source]);
  }

  void test_isValidMixin_constructor() {
    Source source = addSource(r'''
class A {
  A() {}
}''');
    LibraryElement library = resolve(source);
    expect(library, isNotNull);
    CompilationUnitElement unit = library.definingCompilationUnit;
    expect(unit, isNotNull);
    List<ClassElement> classes = unit.types;
    expect(classes, hasLength(1));
    expect(classes[0].isValidMixin, isFalse);
    assertNoErrors(source);
    verify([source]);
  }

  void test_isValidMixin_super() {
    Source source = addSource(r'''
class A {
  toString() {
    return super.toString();
  }
}''');
    LibraryElement library = resolve(source);
    expect(library, isNotNull);
    CompilationUnitElement unit = library.definingCompilationUnit;
    expect(unit, isNotNull);
    List<ClassElement> classes = unit.types;
    expect(classes, hasLength(1));
    expect(classes[0].isValidMixin, isFalse);
    assertNoErrors(source);
    verify([source]);
  }

  void test_isValidMixin_valid() {
    Source source = addSource("class A {}");
    LibraryElement library = resolve(source);
    expect(library, isNotNull);
    CompilationUnitElement unit = library.definingCompilationUnit;
    expect(unit, isNotNull);
    List<ClassElement> classes = unit.types;
    expect(classes, hasLength(1));
    expect(classes[0].isValidMixin, isTrue);
    assertNoErrors(source);
    verify([source]);
  }

  void test_labels_switch() {
    Source source = addSource(r'''
void doSwitch(int target) {
  switch (target) {
    l0: case 0:
      continue l1;
    l1: case 1:
      continue l0;
    default:
      continue l1;
  }
}''');
    LibraryElement library = resolve(source);
    expect(library, isNotNull);
    assertNoErrors(source);
    verify([source]);
  }

  void test_localVariable_types_invoked() {
    Source source = addSource(r'''
const A = null;
main() {
  var myVar = (int p) => 'foo';
  myVar(42);
}''');
    LibraryElement library = resolve(source);
    expect(library, isNotNull);
    CompilationUnit unit =
        analysisContext.getResolvedCompilationUnit(source, library);
    expect(unit, isNotNull);
    List<bool> found = [false];
    List<CaughtException> thrownException = new List<CaughtException>(1);
    unit.accept(
        new _SimpleResolverTest_localVariable_types_invoked(
            this,
            found,
            thrownException));
    if (thrownException[0] != null) {
      throw new AnalysisException(
          "Exception",
          new CaughtException(thrownException[0], null));
    }
    expect(found[0], isTrue);
  }

  void test_metadata_class() {
    Source source = addSource(r'''
const A = null;
@A class C<A> {}''');
    LibraryElement library = resolve(source);
    expect(library, isNotNull);
    CompilationUnitElement unitElement = library.definingCompilationUnit;
    expect(unitElement, isNotNull);
    List<ClassElement> classes = unitElement.types;
    expect(classes, hasLength(1));
    List<ElementAnnotation> annotations = classes[0].metadata;
    expect(annotations, hasLength(1));
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(2));
    Element expectedElement =
        (declarations[0] as
            TopLevelVariableDeclaration).variables.variables[0].name.staticElement;
    EngineTestCase.assertInstanceOf(
        (obj) => obj is PropertyInducingElement,
        PropertyInducingElement,
        expectedElement);
    expectedElement = (expectedElement as PropertyInducingElement).getter;
    Element actualElement =
        (declarations[1] as ClassDeclaration).metadata[0].name.staticElement;
    expect(actualElement, same(expectedElement));
  }

  void test_metadata_field() {
    Source source = addSource(r'''
const A = null;
class C {
  @A int f;
}''');
    LibraryElement library = resolve(source);
    expect(library, isNotNull);
    CompilationUnitElement unit = library.definingCompilationUnit;
    expect(unit, isNotNull);
    List<ClassElement> classes = unit.types;
    expect(classes, hasLength(1));
    FieldElement field = classes[0].fields[0];
    List<ElementAnnotation> annotations = field.metadata;
    expect(annotations, hasLength(1));
    assertNoErrors(source);
    verify([source]);
  }

  void test_metadata_fieldFormalParameter() {
    Source source = addSource(r'''
const A = null;
class C {
  int f;
  C(@A this.f);
}''');
    LibraryElement library = resolve(source);
    expect(library, isNotNull);
    CompilationUnitElement unit = library.definingCompilationUnit;
    expect(unit, isNotNull);
    List<ClassElement> classes = unit.types;
    expect(classes, hasLength(1));
    List<ConstructorElement> constructors = classes[0].constructors;
    expect(constructors, hasLength(1));
    List<ParameterElement> parameters = constructors[0].parameters;
    expect(parameters, hasLength(1));
    List<ElementAnnotation> annotations = parameters[0].metadata;
    expect(annotations, hasLength(1));
    assertNoErrors(source);
    verify([source]);
  }

  void test_metadata_function() {
    Source source = addSource(r'''
const A = null;
@A f() {}''');
    LibraryElement library = resolve(source);
    expect(library, isNotNull);
    CompilationUnitElement unit = library.definingCompilationUnit;
    expect(unit, isNotNull);
    List<FunctionElement> functions = unit.functions;
    expect(functions, hasLength(1));
    List<ElementAnnotation> annotations = functions[0].metadata;
    expect(annotations, hasLength(1));
    assertNoErrors(source);
    verify([source]);
  }

  void test_metadata_functionTypedParameter() {
    Source source = addSource(r'''
const A = null;
f(@A int p(int x)) {}''');
    LibraryElement library = resolve(source);
    expect(library, isNotNull);
    CompilationUnitElement unit = library.definingCompilationUnit;
    expect(unit, isNotNull);
    List<FunctionElement> functions = unit.functions;
    expect(functions, hasLength(1));
    List<ParameterElement> parameters = functions[0].parameters;
    expect(parameters, hasLength(1));
    List<ElementAnnotation> annotations1 = parameters[0].metadata;
    expect(annotations1, hasLength(1));
    assertNoErrors(source);
    verify([source]);
  }

  void test_metadata_libraryDirective() {
    Source source = addSource(r'''
@A library lib;
const A = null;''');
    LibraryElement library = resolve(source);
    expect(library, isNotNull);
    List<ElementAnnotation> annotations = library.metadata;
    expect(annotations, hasLength(1));
    assertNoErrors(source);
    verify([source]);
  }

  void test_metadata_method() {
    Source source = addSource(r'''
const A = null;
class C {
  @A void m() {}
}''');
    LibraryElement library = resolve(source);
    expect(library, isNotNull);
    CompilationUnitElement unit = library.definingCompilationUnit;
    expect(unit, isNotNull);
    List<ClassElement> classes = unit.types;
    expect(classes, hasLength(1));
    MethodElement method = classes[0].methods[0];
    List<ElementAnnotation> annotations = method.metadata;
    expect(annotations, hasLength(1));
    assertNoErrors(source);
    verify([source]);
  }

  void test_metadata_namedParameter() {
    Source source = addSource(r'''
const A = null;
f({@A int p : 0}) {}''');
    LibraryElement library = resolve(source);
    expect(library, isNotNull);
    CompilationUnitElement unit = library.definingCompilationUnit;
    expect(unit, isNotNull);
    List<FunctionElement> functions = unit.functions;
    expect(functions, hasLength(1));
    List<ParameterElement> parameters = functions[0].parameters;
    expect(parameters, hasLength(1));
    List<ElementAnnotation> annotations1 = parameters[0].metadata;
    expect(annotations1, hasLength(1));
    assertNoErrors(source);
    verify([source]);
  }

  void test_metadata_positionalParameter() {
    Source source = addSource(r'''
const A = null;
f([@A int p = 0]) {}''');
    LibraryElement library = resolve(source);
    expect(library, isNotNull);
    CompilationUnitElement unit = library.definingCompilationUnit;
    expect(unit, isNotNull);
    List<FunctionElement> functions = unit.functions;
    expect(functions, hasLength(1));
    List<ParameterElement> parameters = functions[0].parameters;
    expect(parameters, hasLength(1));
    List<ElementAnnotation> annotations1 = parameters[0].metadata;
    expect(annotations1, hasLength(1));
    assertNoErrors(source);
    verify([source]);
  }

  void test_metadata_simpleParameter() {
    Source source = addSource(r'''
const A = null;
f(@A p1, @A int p2) {}''');
    LibraryElement library = resolve(source);
    expect(library, isNotNull);
    CompilationUnitElement unit = library.definingCompilationUnit;
    expect(unit, isNotNull);
    List<FunctionElement> functions = unit.functions;
    expect(functions, hasLength(1));
    List<ParameterElement> parameters = functions[0].parameters;
    expect(parameters, hasLength(2));
    List<ElementAnnotation> annotations1 = parameters[0].metadata;
    expect(annotations1, hasLength(1));
    List<ElementAnnotation> annotations2 = parameters[1].metadata;
    expect(annotations2, hasLength(1));
    assertNoErrors(source);
    verify([source]);
  }

  void test_metadata_typedef() {
    Source source = addSource(r'''
const A = null;
@A typedef F<A>();''');
    LibraryElement library = resolve(source);
    expect(library, isNotNull);
    CompilationUnitElement unitElement = library.definingCompilationUnit;
    expect(unitElement, isNotNull);
    List<FunctionTypeAliasElement> aliases = unitElement.functionTypeAliases;
    expect(aliases, hasLength(1));
    List<ElementAnnotation> annotations = aliases[0].metadata;
    expect(annotations, hasLength(1));
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    NodeList<CompilationUnitMember> declarations = unit.declarations;
    expect(declarations, hasLength(2));
    Element expectedElement =
        (declarations[0] as
            TopLevelVariableDeclaration).variables.variables[0].name.staticElement;
    EngineTestCase.assertInstanceOf(
        (obj) => obj is PropertyInducingElement,
        PropertyInducingElement,
        expectedElement);
    expectedElement = (expectedElement as PropertyInducingElement).getter;
    Element actualElement =
        (declarations[1] as FunctionTypeAlias).metadata[0].name.staticElement;
    expect(actualElement, same(expectedElement));
  }

  void test_method_fromMixin() {
    Source source = addSource(r'''
class B {
  bar() => 1;
}
class A {
  foo() => 2;
}

class C extends B with A {
  bar() => super.bar();
  foo() => super.foo();
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_method_fromSuperclassMixin() {
    Source source = addSource(r'''
class A {
  void m1() {}
}
class B extends Object with A {
}
class C extends B {
}
f(C c) {
  c.m1();
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_methodCascades() {
    Source source = addSource(r'''
class A {
  void m1() {}
  void m2() {}
  void m() {
    A a = new A();
    a..m1()
     ..m2();
  }
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_methodCascades_withSetter() {
    Source source = addSource(r'''
class A {
  String name;
  void m1() {}
  void m2() {}
  void m() {
    A a = new A();
    a..m1()
     ..name = 'name'
     ..m2();
  }
}''');
    resolve(source);
    // failing with error code: INVOCATION_OF_NON_FUNCTION
    assertNoErrors(source);
    verify([source]);
  }

  void test_resolveAgainstNull() {
    Source source = addSource(r'''
f(var p) {
  return null == p;
}''');
    resolve(source);
    assertNoErrors(source);
  }

  void test_setter_inherited() {
    Source source = addSource(r'''
class A {
  int get x => 0;
  set x(int p) {}
}
class B extends A {
  int get x => super.x == null ? 0 : super.x;
  int f() => x = 1;
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  void test_setter_static() {
    Source source = addSource(r'''
set s(x) {
}

main() {
  s = 123;
}''');
    resolve(source);
    assertNoErrors(source);
    verify([source]);
  }

  /**
   * Resolve the given source and verify that the arguments in a specific method invocation were
   * correctly resolved.
   *
   * The source is expected to be source for a compilation unit, the first declaration is expected
   * to be a class, the first member of which is expected to be a method with a block body, and the
   * first statement in the body is expected to be an expression statement whose expression is a
   * method invocation. It is the arguments to that method invocation that are tested. The method
   * invocation can contain errors.
   *
   * The arguments were resolved correctly if the number of expressions in the list matches the
   * length of the array of indices and if, for each index in the array of indices, the parameter to
   * which the argument expression was resolved is the parameter in the invoked method's list of
   * parameters at that index. Arguments that should not be resolved to a parameter because of an
   * error can be denoted by including a negative index in the array of indices.
   *
   * @param source the source to be resolved
   * @param indices the array of indices used to associate arguments with parameters
   * @throws Exception if the source could not be resolved or if the structure of the source is not
   *           valid
   */
  void _validateArgumentResolution(Source source, List<int> indices) {
    LibraryElement library = resolve(source);
    expect(library, isNotNull);
    ClassElement classElement = library.definingCompilationUnit.types[0];
    List<ParameterElement> parameters = classElement.methods[1].parameters;
    CompilationUnit unit = resolveCompilationUnit(source, library);
    expect(unit, isNotNull);
    ClassDeclaration classDeclaration =
        unit.declarations[0] as ClassDeclaration;
    MethodDeclaration methodDeclaration =
        classDeclaration.members[0] as MethodDeclaration;
    Block block = (methodDeclaration.body as BlockFunctionBody).block;
    ExpressionStatement statement = block.statements[0] as ExpressionStatement;
    MethodInvocation invocation = statement.expression as MethodInvocation;
    NodeList<Expression> arguments = invocation.argumentList.arguments;
    int argumentCount = arguments.length;
    expect(argumentCount, indices.length);
    for (int i = 0; i < argumentCount; i++) {
      Expression argument = arguments[i];
      ParameterElement element = argument.staticParameterElement;
      int index = indices[i];
      if (index < 0) {
        expect(element, isNull);
      } else {
        expect(element, same(parameters[index]));
      }
    }
  }
}

class SourceContainer_ChangeSetTest_test_toString implements SourceContainer {
  @override
  bool contains(Source source) => false;
}

/**
 * Like [StaticTypeAnalyzerTest], but as end-to-end tests.
 */
class StaticTypeAnalyzer2Test extends ResolverTestCase {
  String testCode;
  Source testSource;
  CompilationUnit testUnit;

  void test_MethodInvocation_nameType_localVariable() {
    String code = r"""
typedef Foo();
main() {
  Foo foo;
  foo();
}
""";
    _resolveTestUnit(code);
    // "foo" should be resolved to the "Foo" type
    SimpleIdentifier identifier = _findIdentifier("foo();");
    DartType type = identifier.staticType;
    expect(type, new isInstanceOf<FunctionType>());
  }

  void test_MethodInvocation_nameType_parameter_FunctionTypeAlias() {
    String code = r"""
typedef Foo();
main(Foo foo) {
  foo();
}
""";
    _resolveTestUnit(code);
    // "foo" should be resolved to the "Foo" type
    SimpleIdentifier identifier = _findIdentifier("foo();");
    DartType type = identifier.staticType;
    expect(type, new isInstanceOf<FunctionType>());
  }

  void test_MethodInvocation_nameType_parameter_propagatedType() {
    String code = r"""
typedef Foo();
main(p) {
  if (p is Foo) {
    p();
  }
}
""";
    _resolveTestUnit(code);
    SimpleIdentifier identifier = _findIdentifier("p()");
    expect(identifier.staticType, DynamicTypeImpl.instance);
    {
      FunctionType type = identifier.propagatedType;
      expect(type, isNotNull);
      expect(type.name, 'Foo');
    }
  }

  SimpleIdentifier _findIdentifier(String search) {
    SimpleIdentifier identifier = EngineTestCase.findNode(
        testUnit,
        testCode,
        search,
        (node) => node is SimpleIdentifier);
    return identifier;
  }

  void _resolveTestUnit(String code) {
    testCode = code;
    testSource = addSource(testCode);
    LibraryElement library = resolve(testSource);
    assertNoErrors(testSource);
    verify([testSource]);
    testUnit = resolveCompilationUnit(testSource, library);
  }
}

class StaticTypeAnalyzerTest extends EngineTestCase {
  /**
   * The error listener to which errors will be reported.
   */
  GatheringErrorListener _listener;

  /**
   * The resolver visitor used to create the analyzer.
   */
  ResolverVisitor _visitor;

  /**
   * The analyzer being used to analyze the test cases.
   */
  StaticTypeAnalyzer _analyzer;

  /**
   * The type provider used to access the types.
   */
  TestTypeProvider _typeProvider;

  void fail_visitFunctionExpressionInvocation() {
    fail("Not yet tested");
    _listener.assertNoErrors();
  }

  void fail_visitMethodInvocation() {
    fail("Not yet tested");
    _listener.assertNoErrors();
  }

  void fail_visitSimpleIdentifier() {
    fail("Not yet tested");
    _listener.assertNoErrors();
  }

  @override
  void setUp() {
    _listener = new GatheringErrorListener();
    _typeProvider = new TestTypeProvider();
    _analyzer = _createAnalyzer();
  }

  void test_visitAdjacentStrings() {
    // "a" "b"
    Expression node =
        AstFactory.adjacentStrings([_resolvedString("a"), _resolvedString("b")]);
    expect(_analyze(node), same(_typeProvider.stringType));
    _listener.assertNoErrors();
  }

  void test_visitAsExpression() {
    // class A { ... this as B ... }
    // class B extends A {}
    ClassElement superclass = ElementFactory.classElement2("A");
    InterfaceType superclassType = superclass.type;
    ClassElement subclass = ElementFactory.classElement("B", superclassType);
    Expression node = AstFactory.asExpression(
        AstFactory.thisExpression(),
        AstFactory.typeName(subclass));
    expect(_analyze3(node, superclassType), same(subclass.type));
    _listener.assertNoErrors();
  }

  void test_visitAssignmentExpression_compound() {
    // i += 1
    InterfaceType numType = _typeProvider.numType;
    SimpleIdentifier identifier = _resolvedVariable(_typeProvider.intType, "i");
    AssignmentExpression node = AstFactory.assignmentExpression(
        identifier,
        TokenType.PLUS_EQ,
        _resolvedInteger(1));
    MethodElement plusMethod = getMethod(numType, "+");
    node.staticElement = plusMethod;
    expect(_analyze(node), same(numType));
    _listener.assertNoErrors();
  }

  void test_visitAssignmentExpression_simple() {
    // i = 0
    InterfaceType intType = _typeProvider.intType;
    Expression node = AstFactory.assignmentExpression(
        _resolvedVariable(intType, "i"),
        TokenType.EQ,
        _resolvedInteger(0));
    expect(_analyze(node), same(intType));
    _listener.assertNoErrors();
  }

  void test_visitBinaryExpression_equals() {
    // 2 == 3
    Expression node = AstFactory.binaryExpression(
        _resolvedInteger(2),
        TokenType.EQ_EQ,
        _resolvedInteger(3));
    expect(_analyze(node), same(_typeProvider.boolType));
    _listener.assertNoErrors();
  }

  void test_visitBinaryExpression_logicalAnd() {
    // false && true
    Expression node = AstFactory.binaryExpression(
        AstFactory.booleanLiteral(false),
        TokenType.AMPERSAND_AMPERSAND,
        AstFactory.booleanLiteral(true));
    expect(_analyze(node), same(_typeProvider.boolType));
    _listener.assertNoErrors();
  }

  void test_visitBinaryExpression_logicalOr() {
    // false || true
    Expression node = AstFactory.binaryExpression(
        AstFactory.booleanLiteral(false),
        TokenType.BAR_BAR,
        AstFactory.booleanLiteral(true));
    expect(_analyze(node), same(_typeProvider.boolType));
    _listener.assertNoErrors();
  }

  void test_visitBinaryExpression_notEquals() {
    // 2 != 3
    Expression node = AstFactory.binaryExpression(
        _resolvedInteger(2),
        TokenType.BANG_EQ,
        _resolvedInteger(3));
    expect(_analyze(node), same(_typeProvider.boolType));
    _listener.assertNoErrors();
  }

  void test_visitBinaryExpression_plusID() {
    // 1 + 2.0
    BinaryExpression node = AstFactory.binaryExpression(
        _resolvedInteger(1),
        TokenType.PLUS,
        _resolvedDouble(2.0));
    node.staticElement = getMethod(_typeProvider.numType, "+");
    expect(_analyze(node), same(_typeProvider.doubleType));
    _listener.assertNoErrors();
  }

  void test_visitBinaryExpression_plusII() {
    // 1 + 2
    BinaryExpression node = AstFactory.binaryExpression(
        _resolvedInteger(1),
        TokenType.PLUS,
        _resolvedInteger(2));
    node.staticElement = getMethod(_typeProvider.numType, "+");
    expect(_analyze(node), same(_typeProvider.intType));
    _listener.assertNoErrors();
  }

  void test_visitBinaryExpression_slash() {
    // 2 / 2
    BinaryExpression node = AstFactory.binaryExpression(
        _resolvedInteger(2),
        TokenType.SLASH,
        _resolvedInteger(2));
    node.staticElement = getMethod(_typeProvider.numType, "/");
    expect(_analyze(node), same(_typeProvider.doubleType));
    _listener.assertNoErrors();
  }

  void test_visitBinaryExpression_star_notSpecial() {
    // class A {
    //   A operator *(double value);
    // }
    // (a as A) * 2.0
    ClassElementImpl classA = ElementFactory.classElement2("A");
    InterfaceType typeA = classA.type;
    MethodElement operator =
        ElementFactory.methodElement("*", typeA, [_typeProvider.doubleType]);
    classA.methods = <MethodElement>[operator];
    BinaryExpression node = AstFactory.binaryExpression(
        AstFactory.asExpression(
            AstFactory.identifier3("a"),
            AstFactory.typeName(classA)),
        TokenType.PLUS,
        _resolvedDouble(2.0));
    node.staticElement = operator;
    expect(_analyze(node), same(typeA));
    _listener.assertNoErrors();
  }

  void test_visitBinaryExpression_starID() {
    // 1 * 2.0
    BinaryExpression node = AstFactory.binaryExpression(
        _resolvedInteger(1),
        TokenType.PLUS,
        _resolvedDouble(2.0));
    node.staticElement = getMethod(_typeProvider.numType, "*");
    expect(_analyze(node), same(_typeProvider.doubleType));
    _listener.assertNoErrors();
  }

  void test_visitBooleanLiteral_false() {
    // false
    Expression node = AstFactory.booleanLiteral(false);
    expect(_analyze(node), same(_typeProvider.boolType));
    _listener.assertNoErrors();
  }

  void test_visitBooleanLiteral_true() {
    // true
    Expression node = AstFactory.booleanLiteral(true);
    expect(_analyze(node), same(_typeProvider.boolType));
    _listener.assertNoErrors();
  }

  void test_visitCascadeExpression() {
    // a..length
    Expression node = AstFactory.cascadeExpression(
        _resolvedString("a"),
        [AstFactory.propertyAccess2(null, "length")]);
    expect(_analyze(node), same(_typeProvider.stringType));
    _listener.assertNoErrors();
  }

  void test_visitConditionalExpression_differentTypes() {
    // true ? 1.0 : 0
    Expression node = AstFactory.conditionalExpression(
        AstFactory.booleanLiteral(true),
        _resolvedDouble(1.0),
        _resolvedInteger(0));
    expect(_analyze(node), same(_typeProvider.numType));
    _listener.assertNoErrors();
  }

  void test_visitConditionalExpression_sameTypes() {
    // true ? 1 : 0
    Expression node = AstFactory.conditionalExpression(
        AstFactory.booleanLiteral(true),
        _resolvedInteger(1),
        _resolvedInteger(0));
    expect(_analyze(node), same(_typeProvider.intType));
    _listener.assertNoErrors();
  }

  void test_visitDoubleLiteral() {
    // 4.33
    Expression node = AstFactory.doubleLiteral(4.33);
    expect(_analyze(node), same(_typeProvider.doubleType));
    _listener.assertNoErrors();
  }

  void test_visitFunctionExpression_named_block() {
    // ({p1 : 0, p2 : 0}) {}
    DartType dynamicType = _typeProvider.dynamicType;
    FormalParameter p1 = AstFactory.namedFormalParameter(
        AstFactory.simpleFormalParameter3("p1"),
        _resolvedInteger(0));
    _setType(p1, dynamicType);
    FormalParameter p2 = AstFactory.namedFormalParameter(
        AstFactory.simpleFormalParameter3("p2"),
        _resolvedInteger(0));
    _setType(p2, dynamicType);
    FunctionExpression node = _resolvedFunctionExpression(
        AstFactory.formalParameterList([p1, p2]),
        AstFactory.blockFunctionBody2());
    _analyze5(p1);
    _analyze5(p2);
    DartType resultType = _analyze(node);
    Map<String, DartType> expectedNamedTypes = new HashMap<String, DartType>();
    expectedNamedTypes["p1"] = dynamicType;
    expectedNamedTypes["p2"] = dynamicType;
    _assertFunctionType(
        dynamicType,
        null,
        null,
        expectedNamedTypes,
        resultType);
    _listener.assertNoErrors();
  }

  void test_visitFunctionExpression_named_expression() {
    // ({p : 0}) -> 0;
    DartType dynamicType = _typeProvider.dynamicType;
    FormalParameter p = AstFactory.namedFormalParameter(
        AstFactory.simpleFormalParameter3("p"),
        _resolvedInteger(0));
    _setType(p, dynamicType);
    FunctionExpression node = _resolvedFunctionExpression(
        AstFactory.formalParameterList([p]),
        AstFactory.expressionFunctionBody(_resolvedInteger(0)));
    _analyze5(p);
    DartType resultType = _analyze(node);
    Map<String, DartType> expectedNamedTypes = new HashMap<String, DartType>();
    expectedNamedTypes["p"] = dynamicType;
    _assertFunctionType(
        _typeProvider.intType,
        null,
        null,
        expectedNamedTypes,
        resultType);
    _listener.assertNoErrors();
  }

  void test_visitFunctionExpression_normal_block() {
    // (p1, p2) {}
    DartType dynamicType = _typeProvider.dynamicType;
    FormalParameter p1 = AstFactory.simpleFormalParameter3("p1");
    _setType(p1, dynamicType);
    FormalParameter p2 = AstFactory.simpleFormalParameter3("p2");
    _setType(p2, dynamicType);
    FunctionExpression node = _resolvedFunctionExpression(
        AstFactory.formalParameterList([p1, p2]),
        AstFactory.blockFunctionBody2());
    _analyze5(p1);
    _analyze5(p2);
    DartType resultType = _analyze(node);
    _assertFunctionType(
        dynamicType,
        <DartType>[dynamicType, dynamicType],
        null,
        null,
        resultType);
    _listener.assertNoErrors();
  }

  void test_visitFunctionExpression_normal_expression() {
    // (p1, p2) -> 0
    DartType dynamicType = _typeProvider.dynamicType;
    FormalParameter p = AstFactory.simpleFormalParameter3("p");
    _setType(p, dynamicType);
    FunctionExpression node = _resolvedFunctionExpression(
        AstFactory.formalParameterList([p]),
        AstFactory.expressionFunctionBody(_resolvedInteger(0)));
    _analyze5(p);
    DartType resultType = _analyze(node);
    _assertFunctionType(
        _typeProvider.intType,
        <DartType>[dynamicType],
        null,
        null,
        resultType);
    _listener.assertNoErrors();
  }

  void test_visitFunctionExpression_normalAndNamed_block() {
    // (p1, {p2 : 0}) {}
    DartType dynamicType = _typeProvider.dynamicType;
    FormalParameter p1 = AstFactory.simpleFormalParameter3("p1");
    _setType(p1, dynamicType);
    FormalParameter p2 = AstFactory.namedFormalParameter(
        AstFactory.simpleFormalParameter3("p2"),
        _resolvedInteger(0));
    _setType(p2, dynamicType);
    FunctionExpression node = _resolvedFunctionExpression(
        AstFactory.formalParameterList([p1, p2]),
        AstFactory.blockFunctionBody2());
    _analyze5(p2);
    DartType resultType = _analyze(node);
    Map<String, DartType> expectedNamedTypes = new HashMap<String, DartType>();
    expectedNamedTypes["p2"] = dynamicType;
    _assertFunctionType(
        dynamicType,
        <DartType>[dynamicType],
        null,
        expectedNamedTypes,
        resultType);
    _listener.assertNoErrors();
  }

  void test_visitFunctionExpression_normalAndNamed_expression() {
    // (p1, {p2 : 0}) -> 0
    DartType dynamicType = _typeProvider.dynamicType;
    FormalParameter p1 = AstFactory.simpleFormalParameter3("p1");
    _setType(p1, dynamicType);
    FormalParameter p2 = AstFactory.namedFormalParameter(
        AstFactory.simpleFormalParameter3("p2"),
        _resolvedInteger(0));
    _setType(p2, dynamicType);
    FunctionExpression node = _resolvedFunctionExpression(
        AstFactory.formalParameterList([p1, p2]),
        AstFactory.expressionFunctionBody(_resolvedInteger(0)));
    _analyze5(p2);
    DartType resultType = _analyze(node);
    Map<String, DartType> expectedNamedTypes = new HashMap<String, DartType>();
    expectedNamedTypes["p2"] = dynamicType;
    _assertFunctionType(
        _typeProvider.intType,
        <DartType>[dynamicType],
        null,
        expectedNamedTypes,
        resultType);
    _listener.assertNoErrors();
  }

  void test_visitFunctionExpression_normalAndPositional_block() {
    // (p1, [p2 = 0]) {}
    DartType dynamicType = _typeProvider.dynamicType;
    FormalParameter p1 = AstFactory.simpleFormalParameter3("p1");
    _setType(p1, dynamicType);
    FormalParameter p2 = AstFactory.positionalFormalParameter(
        AstFactory.simpleFormalParameter3("p2"),
        _resolvedInteger(0));
    _setType(p2, dynamicType);
    FunctionExpression node = _resolvedFunctionExpression(
        AstFactory.formalParameterList([p1, p2]),
        AstFactory.blockFunctionBody2());
    _analyze5(p1);
    _analyze5(p2);
    DartType resultType = _analyze(node);
    _assertFunctionType(
        dynamicType,
        <DartType>[dynamicType],
        <DartType>[dynamicType],
        null,
        resultType);
    _listener.assertNoErrors();
  }

  void test_visitFunctionExpression_normalAndPositional_expression() {
    // (p1, [p2 = 0]) -> 0
    DartType dynamicType = _typeProvider.dynamicType;
    FormalParameter p1 = AstFactory.simpleFormalParameter3("p1");
    _setType(p1, dynamicType);
    FormalParameter p2 = AstFactory.positionalFormalParameter(
        AstFactory.simpleFormalParameter3("p2"),
        _resolvedInteger(0));
    _setType(p2, dynamicType);
    FunctionExpression node = _resolvedFunctionExpression(
        AstFactory.formalParameterList([p1, p2]),
        AstFactory.expressionFunctionBody(_resolvedInteger(0)));
    _analyze5(p1);
    _analyze5(p2);
    DartType resultType = _analyze(node);
    _assertFunctionType(
        _typeProvider.intType,
        <DartType>[dynamicType],
        <DartType>[dynamicType],
        null,
        resultType);
    _listener.assertNoErrors();
  }

  void test_visitFunctionExpression_positional_block() {
    // ([p1 = 0, p2 = 0]) {}
    DartType dynamicType = _typeProvider.dynamicType;
    FormalParameter p1 = AstFactory.positionalFormalParameter(
        AstFactory.simpleFormalParameter3("p1"),
        _resolvedInteger(0));
    _setType(p1, dynamicType);
    FormalParameter p2 = AstFactory.positionalFormalParameter(
        AstFactory.simpleFormalParameter3("p2"),
        _resolvedInteger(0));
    _setType(p2, dynamicType);
    FunctionExpression node = _resolvedFunctionExpression(
        AstFactory.formalParameterList([p1, p2]),
        AstFactory.blockFunctionBody2());
    _analyze5(p1);
    _analyze5(p2);
    DartType resultType = _analyze(node);
    _assertFunctionType(
        dynamicType,
        null,
        <DartType>[dynamicType, dynamicType],
        null,
        resultType);
    _listener.assertNoErrors();
  }

  void test_visitFunctionExpression_positional_expression() {
    // ([p1 = 0, p2 = 0]) -> 0
    DartType dynamicType = _typeProvider.dynamicType;
    FormalParameter p = AstFactory.positionalFormalParameter(
        AstFactory.simpleFormalParameter3("p"),
        _resolvedInteger(0));
    _setType(p, dynamicType);
    FunctionExpression node = _resolvedFunctionExpression(
        AstFactory.formalParameterList([p]),
        AstFactory.expressionFunctionBody(_resolvedInteger(0)));
    _analyze5(p);
    DartType resultType = _analyze(node);
    _assertFunctionType(
        _typeProvider.intType,
        null,
        <DartType>[dynamicType],
        null,
        resultType);
    _listener.assertNoErrors();
  }

  void test_visitIndexExpression_getter() {
    // List a;
    // a[2]
    InterfaceType listType = _typeProvider.listType;
    SimpleIdentifier identifier = _resolvedVariable(listType, "a");
    IndexExpression node =
        AstFactory.indexExpression(identifier, _resolvedInteger(2));
    MethodElement indexMethod = listType.element.methods[0];
    node.staticElement = indexMethod;
    expect(_analyze(node), same(listType.typeArguments[0]));
    _listener.assertNoErrors();
  }

  void test_visitIndexExpression_setter() {
    // List a;
    // a[2] = 0
    InterfaceType listType = _typeProvider.listType;
    SimpleIdentifier identifier = _resolvedVariable(listType, "a");
    IndexExpression node =
        AstFactory.indexExpression(identifier, _resolvedInteger(2));
    MethodElement indexMethod = listType.element.methods[1];
    node.staticElement = indexMethod;
    AstFactory.assignmentExpression(node, TokenType.EQ, AstFactory.integer(0));
    expect(_analyze(node), same(listType.typeArguments[0]));
    _listener.assertNoErrors();
  }

  void test_visitIndexExpression_typeParameters() {
    // List<int> list = ...
    // list[0]
    InterfaceType intType = _typeProvider.intType;
    InterfaceType listType = _typeProvider.listType;
    // (int) -> E
    MethodElement methodElement = getMethod(listType, "[]");
    // "list" has type List<int>
    SimpleIdentifier identifier = AstFactory.identifier3("list");
    InterfaceType listOfIntType = listType.substitute4(<DartType>[intType]);
    identifier.staticType = listOfIntType;
    // list[0] has MethodElement element (int) -> E
    IndexExpression indexExpression =
        AstFactory.indexExpression(identifier, AstFactory.integer(0));
    MethodElement indexMethod = MethodMember.from(methodElement, listOfIntType);
    indexExpression.staticElement = indexMethod;
    // analyze and assert result of the index expression
    expect(_analyze(indexExpression), same(intType));
    _listener.assertNoErrors();
  }

  void test_visitIndexExpression_typeParameters_inSetterContext() {
    // List<int> list = ...
    // list[0] = 0;
    InterfaceType intType = _typeProvider.intType;
    InterfaceType listType = _typeProvider.listType;
    // (int, E) -> void
    MethodElement methodElement = getMethod(listType, "[]=");
    // "list" has type List<int>
    SimpleIdentifier identifier = AstFactory.identifier3("list");
    InterfaceType listOfIntType = listType.substitute4(<DartType>[intType]);
    identifier.staticType = listOfIntType;
    // list[0] has MethodElement element (int) -> E
    IndexExpression indexExpression =
        AstFactory.indexExpression(identifier, AstFactory.integer(0));
    MethodElement indexMethod = MethodMember.from(methodElement, listOfIntType);
    indexExpression.staticElement = indexMethod;
    // list[0] should be in a setter context
    AstFactory.assignmentExpression(
        indexExpression,
        TokenType.EQ,
        AstFactory.integer(0));
    // analyze and assert result of the index expression
    expect(_analyze(indexExpression), same(intType));
    _listener.assertNoErrors();
  }

  void test_visitInstanceCreationExpression_named() {
    // new C.m()
    ClassElementImpl classElement = ElementFactory.classElement2("C");
    String constructorName = "m";
    ConstructorElementImpl constructor =
        ElementFactory.constructorElement2(classElement, constructorName);
    constructor.returnType = classElement.type;
    FunctionTypeImpl constructorType = new FunctionTypeImpl.con1(constructor);
    constructor.type = constructorType;
    classElement.constructors = <ConstructorElement>[constructor];
    InstanceCreationExpression node = AstFactory.instanceCreationExpression2(
        null,
        AstFactory.typeName(classElement),
        [AstFactory.identifier3(constructorName)]);
    node.staticElement = constructor;
    expect(_analyze(node), same(classElement.type));
    _listener.assertNoErrors();
  }

  void test_visitInstanceCreationExpression_typeParameters() {
    // new C<I>()
    ClassElementImpl elementC = ElementFactory.classElement2("C", ["E"]);
    ClassElementImpl elementI = ElementFactory.classElement2("I");
    ConstructorElementImpl constructor =
        ElementFactory.constructorElement2(elementC, null);
    elementC.constructors = <ConstructorElement>[constructor];
    constructor.returnType = elementC.type;
    FunctionTypeImpl constructorType = new FunctionTypeImpl.con1(constructor);
    constructor.type = constructorType;
    TypeName typeName =
        AstFactory.typeName(elementC, [AstFactory.typeName(elementI)]);
    typeName.type = elementC.type.substitute4(<DartType>[elementI.type]);
    InstanceCreationExpression node =
        AstFactory.instanceCreationExpression2(null, typeName);
    node.staticElement = constructor;
    InterfaceType interfaceType = _analyze(node) as InterfaceType;
    List<DartType> typeArgs = interfaceType.typeArguments;
    expect(typeArgs.length, 1);
    expect(typeArgs[0], elementI.type);
    _listener.assertNoErrors();
  }

  void test_visitInstanceCreationExpression_unnamed() {
    // new C()
    ClassElementImpl classElement = ElementFactory.classElement2("C");
    ConstructorElementImpl constructor =
        ElementFactory.constructorElement2(classElement, null);
    constructor.returnType = classElement.type;
    FunctionTypeImpl constructorType = new FunctionTypeImpl.con1(constructor);
    constructor.type = constructorType;
    classElement.constructors = <ConstructorElement>[constructor];
    InstanceCreationExpression node = AstFactory.instanceCreationExpression2(
        null,
        AstFactory.typeName(classElement));
    node.staticElement = constructor;
    expect(_analyze(node), same(classElement.type));
    _listener.assertNoErrors();
  }

  void test_visitIntegerLiteral() {
    // 42
    Expression node = _resolvedInteger(42);
    expect(_analyze(node), same(_typeProvider.intType));
    _listener.assertNoErrors();
  }

  void test_visitIsExpression_negated() {
    // a is! String
    Expression node = AstFactory.isExpression(
        _resolvedString("a"),
        true,
        AstFactory.typeName4("String"));
    expect(_analyze(node), same(_typeProvider.boolType));
    _listener.assertNoErrors();
  }

  void test_visitIsExpression_notNegated() {
    // a is String
    Expression node = AstFactory.isExpression(
        _resolvedString("a"),
        false,
        AstFactory.typeName4("String"));
    expect(_analyze(node), same(_typeProvider.boolType));
    _listener.assertNoErrors();
  }

  void test_visitListLiteral_empty() {
    // []
    Expression node = AstFactory.listLiteral();
    DartType resultType = _analyze(node);
    _assertType2(
        _typeProvider.listType.substitute4(<DartType>[_typeProvider.dynamicType]),
        resultType);
    _listener.assertNoErrors();
  }

  void test_visitListLiteral_nonEmpty() {
    // [0]
    Expression node = AstFactory.listLiteral([_resolvedInteger(0)]);
    DartType resultType = _analyze(node);
    _assertType2(
        _typeProvider.listType.substitute4(<DartType>[_typeProvider.dynamicType]),
        resultType);
    _listener.assertNoErrors();
  }

  void test_visitMapLiteral_empty() {
    // {}
    Expression node = AstFactory.mapLiteral2();
    DartType resultType = _analyze(node);
    _assertType2(
        _typeProvider.mapType.substitute4(
            <DartType>[_typeProvider.dynamicType, _typeProvider.dynamicType]),
        resultType);
    _listener.assertNoErrors();
  }

  void test_visitMapLiteral_nonEmpty() {
    // {"k" : 0}
    Expression node =
        AstFactory.mapLiteral2([AstFactory.mapLiteralEntry("k", _resolvedInteger(0))]);
    DartType resultType = _analyze(node);
    _assertType2(
        _typeProvider.mapType.substitute4(
            <DartType>[_typeProvider.dynamicType, _typeProvider.dynamicType]),
        resultType);
    _listener.assertNoErrors();
  }

  void test_visitMethodInvocation_then() {
    // then()
    Expression node = AstFactory.methodInvocation(null, "then");
    _analyze(node);
    _listener.assertNoErrors();
  }

  void test_visitNamedExpression() {
    // n: a
    Expression node = AstFactory.namedExpression2("n", _resolvedString("a"));
    expect(_analyze(node), same(_typeProvider.stringType));
    _listener.assertNoErrors();
  }

  void test_visitNullLiteral() {
    // null
    Expression node = AstFactory.nullLiteral();
    expect(_analyze(node), same(_typeProvider.bottomType));
    _listener.assertNoErrors();
  }

  void test_visitParenthesizedExpression() {
    // (0)
    Expression node = AstFactory.parenthesizedExpression(_resolvedInteger(0));
    expect(_analyze(node), same(_typeProvider.intType));
    _listener.assertNoErrors();
  }

  void test_visitPostfixExpression_minusMinus() {
    // 0--
    PostfixExpression node =
        AstFactory.postfixExpression(_resolvedInteger(0), TokenType.MINUS_MINUS);
    expect(_analyze(node), same(_typeProvider.intType));
    _listener.assertNoErrors();
  }

  void test_visitPostfixExpression_plusPlus() {
    // 0++
    PostfixExpression node =
        AstFactory.postfixExpression(_resolvedInteger(0), TokenType.PLUS_PLUS);
    expect(_analyze(node), same(_typeProvider.intType));
    _listener.assertNoErrors();
  }

  void test_visitPrefixedIdentifier_getter() {
    DartType boolType = _typeProvider.boolType;
    PropertyAccessorElementImpl getter =
        ElementFactory.getterElement("b", false, boolType);
    PrefixedIdentifier node = AstFactory.identifier5("a", "b");
    node.identifier.staticElement = getter;
    expect(_analyze(node), same(boolType));
    _listener.assertNoErrors();
  }

  void test_visitPrefixedIdentifier_setter() {
    DartType boolType = _typeProvider.boolType;
    FieldElementImpl field =
        ElementFactory.fieldElement("b", false, false, false, boolType);
    PropertyAccessorElement setter = field.setter;
    PrefixedIdentifier node = AstFactory.identifier5("a", "b");
    node.identifier.staticElement = setter;
    expect(_analyze(node), same(boolType));
    _listener.assertNoErrors();
  }

  void test_visitPrefixedIdentifier_variable() {
    VariableElementImpl variable = ElementFactory.localVariableElement2("b");
    variable.type = _typeProvider.boolType;
    PrefixedIdentifier node = AstFactory.identifier5("a", "b");
    node.identifier.staticElement = variable;
    expect(_analyze(node), same(_typeProvider.boolType));
    _listener.assertNoErrors();
  }

  void test_visitPrefixExpression_bang() {
    // !0
    PrefixExpression node =
        AstFactory.prefixExpression(TokenType.BANG, _resolvedInteger(0));
    expect(_analyze(node), same(_typeProvider.boolType));
    _listener.assertNoErrors();
  }

  void test_visitPrefixExpression_minus() {
    // -0
    PrefixExpression node =
        AstFactory.prefixExpression(TokenType.MINUS, _resolvedInteger(0));
    MethodElement minusMethod = getMethod(_typeProvider.numType, "-");
    node.staticElement = minusMethod;
    expect(_analyze(node), same(_typeProvider.numType));
    _listener.assertNoErrors();
  }

  void test_visitPrefixExpression_minusMinus() {
    // --0
    PrefixExpression node =
        AstFactory.prefixExpression(TokenType.MINUS_MINUS, _resolvedInteger(0));
    MethodElement minusMethod = getMethod(_typeProvider.numType, "-");
    node.staticElement = minusMethod;
    expect(_analyze(node), same(_typeProvider.intType));
    _listener.assertNoErrors();
  }

  void test_visitPrefixExpression_not() {
    // !true
    Expression node =
        AstFactory.prefixExpression(TokenType.BANG, AstFactory.booleanLiteral(true));
    expect(_analyze(node), same(_typeProvider.boolType));
    _listener.assertNoErrors();
  }

  void test_visitPrefixExpression_plusPlus() {
    // ++0
    PrefixExpression node =
        AstFactory.prefixExpression(TokenType.PLUS_PLUS, _resolvedInteger(0));
    MethodElement plusMethod = getMethod(_typeProvider.numType, "+");
    node.staticElement = plusMethod;
    expect(_analyze(node), same(_typeProvider.intType));
    _listener.assertNoErrors();
  }

  void test_visitPrefixExpression_tilde() {
    // ~0
    PrefixExpression node =
        AstFactory.prefixExpression(TokenType.TILDE, _resolvedInteger(0));
    MethodElement tildeMethod = getMethod(_typeProvider.intType, "~");
    node.staticElement = tildeMethod;
    expect(_analyze(node), same(_typeProvider.intType));
    _listener.assertNoErrors();
  }

  void test_visitPropertyAccess_propagated_getter() {
    DartType boolType = _typeProvider.boolType;
    PropertyAccessorElementImpl getter =
        ElementFactory.getterElement("b", false, boolType);
    PropertyAccess node =
        AstFactory.propertyAccess2(AstFactory.identifier3("a"), "b");
    node.propertyName.propagatedElement = getter;
    expect(_analyze2(node, false), same(boolType));
    _listener.assertNoErrors();
  }

  void test_visitPropertyAccess_propagated_setter() {
    DartType boolType = _typeProvider.boolType;
    FieldElementImpl field =
        ElementFactory.fieldElement("b", false, false, false, boolType);
    PropertyAccessorElement setter = field.setter;
    PropertyAccess node =
        AstFactory.propertyAccess2(AstFactory.identifier3("a"), "b");
    node.propertyName.propagatedElement = setter;
    expect(_analyze2(node, false), same(boolType));
    _listener.assertNoErrors();
  }

  void test_visitPropertyAccess_static_getter() {
    DartType boolType = _typeProvider.boolType;
    PropertyAccessorElementImpl getter =
        ElementFactory.getterElement("b", false, boolType);
    PropertyAccess node =
        AstFactory.propertyAccess2(AstFactory.identifier3("a"), "b");
    node.propertyName.staticElement = getter;
    expect(_analyze(node), same(boolType));
    _listener.assertNoErrors();
  }

  void test_visitPropertyAccess_static_setter() {
    DartType boolType = _typeProvider.boolType;
    FieldElementImpl field =
        ElementFactory.fieldElement("b", false, false, false, boolType);
    PropertyAccessorElement setter = field.setter;
    PropertyAccess node =
        AstFactory.propertyAccess2(AstFactory.identifier3("a"), "b");
    node.propertyName.staticElement = setter;
    expect(_analyze(node), same(boolType));
    _listener.assertNoErrors();
  }

  void test_visitSimpleIdentifier_dynamic() {
    // "dynamic"
    SimpleIdentifier identifier = AstFactory.identifier3('dynamic');
    DynamicElementImpl element = DynamicElementImpl.instance;
    identifier.staticElement = element;
    identifier.staticType = _typeProvider.typeType;
    expect(_analyze(identifier), same(_typeProvider.typeType));
    _listener.assertNoErrors();
  }

  void test_visitSimpleStringLiteral() {
    // "a"
    Expression node = _resolvedString("a");
    expect(_analyze(node), same(_typeProvider.stringType));
    _listener.assertNoErrors();
  }

  void test_visitStringInterpolation() {
    // "a${'b'}c"
    Expression node = AstFactory.string(
        [
            AstFactory.interpolationString("a", "a"),
            AstFactory.interpolationExpression(_resolvedString("b")),
            AstFactory.interpolationString("c", "c")]);
    expect(_analyze(node), same(_typeProvider.stringType));
    _listener.assertNoErrors();
  }

  void test_visitSuperExpression() {
    // super
    InterfaceType superType = ElementFactory.classElement2("A").type;
    InterfaceType thisType = ElementFactory.classElement("B", superType).type;
    Expression node = AstFactory.superExpression();
    expect(_analyze3(node, thisType), same(thisType));
    _listener.assertNoErrors();
  }

  void test_visitSymbolLiteral() {
    expect(
        _analyze(AstFactory.symbolLiteral(["a"])),
        same(_typeProvider.symbolType));
  }

  void test_visitThisExpression() {
    // this
    InterfaceType thisType =
        ElementFactory.classElement("B", ElementFactory.classElement2("A").type).type;
    Expression node = AstFactory.thisExpression();
    expect(_analyze3(node, thisType), same(thisType));
    _listener.assertNoErrors();
  }

  void test_visitThrowExpression_withoutValue() {
    // throw
    Expression node = AstFactory.throwExpression();
    expect(_analyze(node), same(_typeProvider.bottomType));
    _listener.assertNoErrors();
  }

  void test_visitThrowExpression_withValue() {
    // throw 0
    Expression node = AstFactory.throwExpression2(_resolvedInteger(0));
    expect(_analyze(node), same(_typeProvider.bottomType));
    _listener.assertNoErrors();
  }

  /**
   * Return the type associated with the given expression after the static type analyzer has
   * computed a type for it.
   *
   * @param node the expression with which the type is associated
   * @return the type associated with the expression
   */
  DartType _analyze(Expression node) => _analyze4(node, null, true);

  /**
   * Return the type associated with the given expression after the static or propagated type
   * analyzer has computed a type for it.
   *
   * @param node the expression with which the type is associated
   * @param useStaticType `true` if the static type is being requested, and `false` if
   *          the propagated type is being requested
   * @return the type associated with the expression
   */
  DartType _analyze2(Expression node, bool useStaticType) =>
      _analyze4(node, null, useStaticType);

  /**
   * Return the type associated with the given expression after the static type analyzer has
   * computed a type for it.
   *
   * @param node the expression with which the type is associated
   * @param thisType the type of 'this'
   * @return the type associated with the expression
   */
  DartType _analyze3(Expression node, InterfaceType thisType) =>
      _analyze4(node, thisType, true);

  /**
   * Return the type associated with the given expression after the static type analyzer has
   * computed a type for it.
   *
   * @param node the expression with which the type is associated
   * @param thisType the type of 'this'
   * @param useStaticType `true` if the static type is being requested, and `false` if
   *          the propagated type is being requested
   * @return the type associated with the expression
   */
  DartType _analyze4(Expression node, InterfaceType thisType,
      bool useStaticType) {
    try {
      _analyzer.thisType = thisType;
    } catch (exception) {
      throw new IllegalArgumentException(
          "Could not set type of 'this'",
          exception);
    }
    node.accept(_analyzer);
    if (useStaticType) {
      return node.staticType;
    } else {
      return node.propagatedType;
    }
  }

  /**
   * Return the type associated with the given parameter after the static type analyzer has computed
   * a type for it.
   *
   * @param node the parameter with which the type is associated
   * @return the type associated with the parameter
   */
  DartType _analyze5(FormalParameter node) {
    node.accept(_analyzer);
    return (node.identifier.staticElement as ParameterElement).type;
  }

  /**
   * Assert that the actual type is a function type with the expected characteristics.
   *
   * @param expectedReturnType the expected return type of the function
   * @param expectedNormalTypes the expected types of the normal parameters
   * @param expectedOptionalTypes the expected types of the optional parameters
   * @param expectedNamedTypes the expected types of the named parameters
   * @param actualType the type being tested
   */
  void _assertFunctionType(DartType expectedReturnType,
      List<DartType> expectedNormalTypes, List<DartType> expectedOptionalTypes,
      Map<String, DartType> expectedNamedTypes, DartType actualType) {
    EngineTestCase.assertInstanceOf(
        (obj) => obj is FunctionType,
        FunctionType,
        actualType);
    FunctionType functionType = actualType as FunctionType;
    List<DartType> normalTypes = functionType.normalParameterTypes;
    if (expectedNormalTypes == null) {
      expect(normalTypes, hasLength(0));
    } else {
      int expectedCount = expectedNormalTypes.length;
      expect(normalTypes, hasLength(expectedCount));
      for (int i = 0; i < expectedCount; i++) {
        expect(normalTypes[i], same(expectedNormalTypes[i]));
      }
    }
    List<DartType> optionalTypes = functionType.optionalParameterTypes;
    if (expectedOptionalTypes == null) {
      expect(optionalTypes, hasLength(0));
    } else {
      int expectedCount = expectedOptionalTypes.length;
      expect(optionalTypes, hasLength(expectedCount));
      for (int i = 0; i < expectedCount; i++) {
        expect(optionalTypes[i], same(expectedOptionalTypes[i]));
      }
    }
    Map<String, DartType> namedTypes = functionType.namedParameterTypes;
    if (expectedNamedTypes == null) {
      expect(namedTypes, hasLength(0));
    } else {
      expect(namedTypes, hasLength(expectedNamedTypes.length));
      expectedNamedTypes.forEach((String name, DartType type) {
        expect(namedTypes[name], same(type));
      });
    }
    expect(functionType.returnType, same(expectedReturnType));
  }

  void _assertType(InterfaceTypeImpl expectedType,
      InterfaceTypeImpl actualType) {
    expect(actualType.displayName, expectedType.displayName);
    expect(actualType.element, expectedType.element);
    List<DartType> expectedArguments = expectedType.typeArguments;
    int length = expectedArguments.length;
    List<DartType> actualArguments = actualType.typeArguments;
    expect(actualArguments, hasLength(length));
    for (int i = 0; i < length; i++) {
      _assertType2(expectedArguments[i], actualArguments[i]);
    }
  }

  void _assertType2(DartType expectedType, DartType actualType) {
    if (expectedType is InterfaceTypeImpl) {
      EngineTestCase.assertInstanceOf(
          (obj) => obj is InterfaceTypeImpl,
          InterfaceTypeImpl,
          actualType);
      _assertType(expectedType, actualType as InterfaceTypeImpl);
    }
    // TODO(brianwilkerson) Compare other kinds of types then make this a shared
    // utility method.
  }

  /**
   * Create the analyzer used by the tests.
   *
   * @return the analyzer to be used by the tests
   */
  StaticTypeAnalyzer _createAnalyzer() {
    AnalysisContextImpl context = new AnalysisContextImpl();
    SourceFactory sourceFactory =
        new SourceFactory([new DartUriResolver(DirectoryBasedDartSdk.defaultSdk)]);
    context.sourceFactory = sourceFactory;
    FileBasedSource source =
        new FileBasedSource.con1(FileUtilities2.createFile("/lib.dart"));
    CompilationUnitElementImpl definingCompilationUnit =
        new CompilationUnitElementImpl("lib.dart");
    definingCompilationUnit.source = source;
    LibraryElementImpl definingLibrary =
        new LibraryElementImpl.forNode(context, null);
    definingLibrary.definingCompilationUnit = definingCompilationUnit;
    Library library = new Library(context, _listener, source);
    library.libraryElement = definingLibrary;
    _visitor = new ResolverVisitor.con1(library, source, _typeProvider);
    _visitor.overrideManager.enterScope();
    try {
      return _visitor.typeAnalyzer_J2DAccessor as StaticTypeAnalyzer;
    } catch (exception) {
      throw new IllegalArgumentException(
          "Could not create analyzer",
          exception);
    }
  }

  /**
   * Return an integer literal that has been resolved to the correct type.
   *
   * @param value the value of the literal
   * @return an integer literal that has been resolved to the correct type
   */
  DoubleLiteral _resolvedDouble(double value) {
    DoubleLiteral literal = AstFactory.doubleLiteral(value);
    literal.staticType = _typeProvider.doubleType;
    return literal;
  }

  /**
   * Create a function expression that has an element associated with it, where the element has an
   * incomplete type associated with it (just like the one
   * [ElementBuilder.visitFunctionExpression] would have built if we had
   * run it).
   *
   * @param parameters the parameters to the function
   * @param body the body of the function
   * @return a resolved function expression
   */
  FunctionExpression _resolvedFunctionExpression(FormalParameterList parameters,
      FunctionBody body) {
    List<ParameterElement> parameterElements = new List<ParameterElement>();
    for (FormalParameter parameter in parameters.parameters) {
      ParameterElementImpl element =
          new ParameterElementImpl.forNode(parameter.identifier);
      element.parameterKind = parameter.kind;
      element.type = _typeProvider.dynamicType;
      parameter.identifier.staticElement = element;
      parameterElements.add(element);
    }
    FunctionExpression node = AstFactory.functionExpression2(parameters, body);
    FunctionElementImpl element = new FunctionElementImpl.forNode(null);
    element.parameters = parameterElements;
    element.type = new FunctionTypeImpl.con1(element);
    node.element = element;
    return node;
  }

  /**
   * Return an integer literal that has been resolved to the correct type.
   *
   * @param value the value of the literal
   * @return an integer literal that has been resolved to the correct type
   */
  IntegerLiteral _resolvedInteger(int value) {
    IntegerLiteral literal = AstFactory.integer(value);
    literal.staticType = _typeProvider.intType;
    return literal;
  }

  /**
   * Return a string literal that has been resolved to the correct type.
   *
   * @param value the value of the literal
   * @return a string literal that has been resolved to the correct type
   */
  SimpleStringLiteral _resolvedString(String value) {
    SimpleStringLiteral string = AstFactory.string2(value);
    string.staticType = _typeProvider.stringType;
    return string;
  }

  /**
   * Return a simple identifier that has been resolved to a variable element with the given type.
   *
   * @param type the type of the variable being represented
   * @param variableName the name of the variable
   * @return a simple identifier that has been resolved to a variable element with the given type
   */
  SimpleIdentifier _resolvedVariable(InterfaceType type, String variableName) {
    SimpleIdentifier identifier = AstFactory.identifier3(variableName);
    VariableElementImpl element =
        ElementFactory.localVariableElement(identifier);
    element.type = type;
    identifier.staticElement = element;
    identifier.staticType = type;
    return identifier;
  }

  /**
   * Set the type of the given parameter to the given type.
   *
   * @param parameter the parameter whose type is to be set
   * @param type the new type of the given parameter
   */
  void _setType(FormalParameter parameter, DartType type) {
    SimpleIdentifier identifier = parameter.identifier;
    Element element = identifier.staticElement;
    if (element is! ParameterElement) {
      element = new ParameterElementImpl.forNode(identifier);
      identifier.staticElement = element;
    }
    (element as ParameterElementImpl).type = type;
  }
}


/**
 * Instances of the class `StaticTypeVerifier` verify that all of the nodes in an AST
 * structure that should have a static type associated with them do have a static type.
 */
class StaticTypeVerifier extends GeneralizingAstVisitor<Object> {
  /**
   * A list containing all of the AST Expression nodes that were not resolved.
   */
  List<Expression> _unresolvedExpressions = new List<Expression>();

  /**
   * A list containing all of the AST Expression nodes for which a propagated type was computed but
   * where that type was not more specific than the static type.
   */
  List<Expression> _invalidlyPropagatedExpressions = new List<Expression>();

  /**
   * A list containing all of the AST TypeName nodes that were not resolved.
   */
  List<TypeName> _unresolvedTypes = new List<TypeName>();

  /**
   * Counter for the number of Expression nodes visited that are resolved.
   */
  int _resolvedExpressionCount = 0;

  /**
   * Counter for the number of Expression nodes visited that have propagated type information.
   */
  int _propagatedExpressionCount = 0;

  /**
   * Counter for the number of TypeName nodes visited that are resolved.
   */
  int _resolvedTypeCount = 0;

  /**
   * Assert that all of the visited nodes have a static type associated with them.
   */
  void assertResolved() {
    if (!_unresolvedExpressions.isEmpty || !_unresolvedTypes.isEmpty) {
      StringBuffer buffer = new StringBuffer();
      int unresolvedTypeCount = _unresolvedTypes.length;
      if (unresolvedTypeCount > 0) {
        buffer.write("Failed to resolve ");
        buffer.write(unresolvedTypeCount);
        buffer.write(" of ");
        buffer.write(_resolvedTypeCount + unresolvedTypeCount);
        buffer.writeln(" type names:");
        for (TypeName identifier in _unresolvedTypes) {
          buffer.write("  ");
          buffer.write(identifier.toString());
          buffer.write(" (");
          buffer.write(_getFileName(identifier));
          buffer.write(" : ");
          buffer.write(identifier.offset);
          buffer.writeln(")");
        }
      }
      int unresolvedExpressionCount = _unresolvedExpressions.length;
      if (unresolvedExpressionCount > 0) {
        buffer.writeln("Failed to resolve ");
        buffer.write(unresolvedExpressionCount);
        buffer.write(" of ");
        buffer.write(_resolvedExpressionCount + unresolvedExpressionCount);
        buffer.writeln(" expressions:");
        for (Expression expression in _unresolvedExpressions) {
          buffer.write("  ");
          buffer.write(expression.toString());
          buffer.write(" (");
          buffer.write(_getFileName(expression));
          buffer.write(" : ");
          buffer.write(expression.offset);
          buffer.writeln(")");
        }
      }
      int invalidlyPropagatedExpressionCount =
          _invalidlyPropagatedExpressions.length;
      if (invalidlyPropagatedExpressionCount > 0) {
        buffer.writeln("Incorrectly propagated ");
        buffer.write(invalidlyPropagatedExpressionCount);
        buffer.write(" of ");
        buffer.write(_propagatedExpressionCount);
        buffer.writeln(" expressions:");
        for (Expression expression in _invalidlyPropagatedExpressions) {
          buffer.write("  ");
          buffer.write(expression.toString());
          buffer.write(" [");
          buffer.write(expression.staticType.displayName);
          buffer.write(", ");
          buffer.write(expression.propagatedType.displayName);
          buffer.writeln("]");
          buffer.write("    ");
          buffer.write(_getFileName(expression));
          buffer.write(" : ");
          buffer.write(expression.offset);
          buffer.writeln(")");
        }
      }
      fail(buffer.toString());
    }
  }

  @override
  Object visitBreakStatement(BreakStatement node) => null;

  @override
  Object visitCommentReference(CommentReference node) => null;

  @override
  Object visitContinueStatement(ContinueStatement node) => null;

  @override
  Object visitExportDirective(ExportDirective node) => null;

  @override
  Object visitExpression(Expression node) {
    node.visitChildren(this);
    DartType staticType = node.staticType;
    if (staticType == null) {
      _unresolvedExpressions.add(node);
    } else {
      _resolvedExpressionCount++;
      DartType propagatedType = node.propagatedType;
      if (propagatedType != null) {
        _propagatedExpressionCount++;
        if (!propagatedType.isMoreSpecificThan(staticType)) {
          _invalidlyPropagatedExpressions.add(node);
        }
      }
    }
    return null;
  }

  @override
  Object visitImportDirective(ImportDirective node) => null;

  @override
  Object visitLabel(Label node) => null;

  @override
  Object visitLibraryIdentifier(LibraryIdentifier node) => null;

  @override
  Object visitPrefixedIdentifier(PrefixedIdentifier node) {
    // In cases where we have a prefixed identifier where the prefix is dynamic,
    // we don't want to assert that the node will have a type.
    if (node.staticType == null && node.prefix.staticType.isDynamic) {
      return null;
    }
    return super.visitPrefixedIdentifier(node);
  }

  @override
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    // In cases where identifiers are being used for something other than an
    // expressions, then they can be ignored.
    AstNode parent = node.parent;
    if (parent is MethodInvocation && identical(node, parent.methodName)) {
      return null;
    } else if (parent is RedirectingConstructorInvocation &&
        identical(node, parent.constructorName)) {
      return null;
    } else if (parent is SuperConstructorInvocation &&
        identical(node, parent.constructorName)) {
      return null;
    } else if (parent is ConstructorName && identical(node, parent.name)) {
      return null;
    } else if (parent is ConstructorFieldInitializer &&
        identical(node, parent.fieldName)) {
      return null;
    } else if (node.staticElement is PrefixElement) {
      // Prefixes don't have a type.
      return null;
    }
    return super.visitSimpleIdentifier(node);
  }

  @override
  Object visitTypeName(TypeName node) {
    // Note: do not visit children from this node, the child SimpleIdentifier in
    // TypeName (i.e. "String") does not have a static type defined.
    if (node.type == null) {
      _unresolvedTypes.add(node);
    } else {
      _resolvedTypeCount++;
    }
    return null;
  }

  String _getFileName(AstNode node) {
    // TODO (jwren) there are two copies of this method, one here and one in
    // ResolutionVerifier, they should be resolved into a single method
    if (node != null) {
      AstNode root = node.root;
      if (root is CompilationUnit) {
        CompilationUnit rootCU = root;
        if (rootCU.element != null) {
          return rootCU.element.source.fullName;
        } else {
          return "<unknown file- CompilationUnit.getElement() returned null>";
        }
      } else {
        return
            "<unknown file- CompilationUnit.getRoot() is not a CompilationUnit>";
      }
    }
    return "<unknown file- ASTNode is null>";
  }
}

/**
 * The class `StrictModeTest` contains tests to ensure that the correct errors and warnings
 * are reported when the analysis engine is run in strict mode.
 */
class StrictModeTest extends ResolverTestCase {
  void fail_for() {
    Source source = addSource(r'''
int f(List<int> list) {
  num sum = 0;
  for (num i = 0; i < list.length; i++) {
    sum += list[i];
  }
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  @override
  void setUp() {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.hint = false;
    resetWithOptions(options);
  }

  void test_assert_is() {
    Source source = addSource(r'''
int f(num n) {
  assert (n is int);
  return n & 0x0F;
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  void test_conditional_and_is() {
    Source source = addSource(r'''
int f(num n) {
  return (n is int && n > 0) ? n & 0x0F : 0;
}''');
    resolve(source);
    assertNoErrors(source);
  }

  void test_conditional_is() {
    Source source = addSource(r'''
int f(num n) {
  return (n is int) ? n & 0x0F : 0;
}''');
    resolve(source);
    assertNoErrors(source);
  }

  void test_conditional_isNot() {
    Source source = addSource(r'''
int f(num n) {
  return (n is! int) ? 0 : n & 0x0F;
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  void test_conditional_or_is() {
    Source source = addSource(r'''
int f(num n) {
  return (n is! int || n < 0) ? 0 : n & 0x0F;
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  void test_forEach() {
    Source source = addSource(r'''
int f(List<int> list) {
  num sum = 0;
  for (num n in list) {
    sum += n & 0x0F;
  }
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  void test_if_and_is() {
    Source source = addSource(r'''
int f(num n) {
  if (n is int && n > 0) {
    return n & 0x0F;
  }
  return 0;
}''');
    resolve(source);
    assertNoErrors(source);
  }

  void test_if_is() {
    Source source = addSource(r'''
int f(num n) {
  if (n is int) {
    return n & 0x0F;
  }
  return 0;
}''');
    resolve(source);
    assertNoErrors(source);
  }

  void test_if_isNot() {
    Source source = addSource(r'''
int f(num n) {
  if (n is! int) {
    return 0;
  } else {
    return n & 0x0F;
  }
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  void test_if_isNot_abrupt() {
    Source source = addSource(r'''
int f(num n) {
  if (n is! int) {
    return 0;
  }
  return n & 0x0F;
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  void test_if_or_is() {
    Source source = addSource(r'''
int f(num n) {
  if (n is! int || n < 0) {
    return 0;
  } else {
    return n & 0x0F;
  }
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  void test_localVar() {
    Source source = addSource(r'''
int f() {
  num n = 1234;
  return n & 0x0F;
}''');
    resolve(source);
    assertErrors(source, [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }
}

class SubtypeManagerTest extends EngineTestCase {
  /**
   * The inheritance manager being tested.
   */
  SubtypeManager _subtypeManager;

  /**
   * The compilation unit element containing all of the types setup in each test.
   */
  CompilationUnitElementImpl _definingCompilationUnit;

  @override
  void setUp() {
    super.setUp();
    AnalysisContextImpl context = AnalysisContextFactory.contextWithCore();
    FileBasedSource source =
        new FileBasedSource.con1(FileUtilities2.createFile("/test.dart"));
    _definingCompilationUnit = new CompilationUnitElementImpl("test.dart");
    _definingCompilationUnit.source = source;
    LibraryElementImpl definingLibrary =
        ElementFactory.library(context, "test");
    definingLibrary.definingCompilationUnit = _definingCompilationUnit;
    _subtypeManager = new SubtypeManager();
  }

  void test_computeAllSubtypes_infiniteLoop() {
    //
    // class A extends B
    // class B extends A
    //
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    classA.supertype = classB.type;
    _definingCompilationUnit.types = <ClassElement>[classA, classB];
    HashSet<ClassElement> subtypesOfA =
        _subtypeManager.computeAllSubtypes(classA);
    List<ClassElement> arraySubtypesOfA = new List.from(subtypesOfA);
    expect(subtypesOfA, hasLength(2));
    expect(arraySubtypesOfA, unorderedEquals([classA, classB]));
  }

  void test_computeAllSubtypes_manyRecursiveSubtypes() {
    //
    // class A
    // class B extends A
    // class C extends B
    // class D extends B
    // class E extends B
    //
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    ClassElementImpl classC = ElementFactory.classElement("C", classB.type);
    ClassElementImpl classD = ElementFactory.classElement("D", classB.type);
    ClassElementImpl classE = ElementFactory.classElement("E", classB.type);
    _definingCompilationUnit.types =
        <ClassElement>[classA, classB, classC, classD, classE];
    HashSet<ClassElement> subtypesOfA =
        _subtypeManager.computeAllSubtypes(classA);
    List<ClassElement> arraySubtypesOfA = new List.from(subtypesOfA);
    HashSet<ClassElement> subtypesOfB =
        _subtypeManager.computeAllSubtypes(classB);
    List<ClassElement> arraySubtypesOfB = new List.from(subtypesOfB);
    expect(subtypesOfA, hasLength(4));
    expect(arraySubtypesOfA, unorderedEquals([classB, classC, classD, classE]));
    expect(subtypesOfB, hasLength(3));
    expect(arraySubtypesOfB, unorderedEquals([classC, classD, classE]));
  }

  void test_computeAllSubtypes_noSubtypes() {
    //
    // class A
    //
    ClassElementImpl classA = ElementFactory.classElement2("A");
    _definingCompilationUnit.types = <ClassElement>[classA];
    HashSet<ClassElement> subtypesOfA =
        _subtypeManager.computeAllSubtypes(classA);
    expect(subtypesOfA, hasLength(0));
  }

  void test_computeAllSubtypes_oneSubtype() {
    //
    // class A
    // class B extends A
    //
    ClassElementImpl classA = ElementFactory.classElement2("A");
    ClassElementImpl classB = ElementFactory.classElement("B", classA.type);
    _definingCompilationUnit.types = <ClassElement>[classA, classB];
    HashSet<ClassElement> subtypesOfA =
        _subtypeManager.computeAllSubtypes(classA);
    List<ClassElement> arraySubtypesOfA = new List.from(subtypesOfA);
    expect(subtypesOfA, hasLength(1));
    expect(arraySubtypesOfA, unorderedEquals([classB]));
  }
}

/**
 * Instances of the class `TestTypeProvider` implement a type provider that can be used by
 * tests without creating the element model for the core library.
 */
class TestTypeProvider implements TypeProvider {
  /**
   * The type representing the built-in type 'bool'.
   */
  InterfaceType _boolType;

  /**
   * The type representing the type 'bottom'.
   */
  DartType _bottomType;

  /**
   * The type representing the built-in type 'double'.
   */
  InterfaceType _doubleType;

  /**
   * The type representing the built-in type 'deprecated'.
   */
  InterfaceType _deprecatedType;

  /**
   * The type representing the built-in type 'dynamic'.
   */
  DartType _dynamicType;

  /**
   * The type representing the built-in type 'Function'.
   */
  InterfaceType _functionType;

  /**
   * The type representing the built-in type 'int'.
   */
  InterfaceType _intType;

  /**
   * The type representing the built-in type 'Iterable'.
   */
  InterfaceType _iterableType;

  /**
   * The type representing the built-in type 'Iterator'.
   */
  InterfaceType _iteratorType;

  /**
   * The type representing the built-in type 'List'.
   */
  InterfaceType _listType;

  /**
   * The type representing the built-in type 'Map'.
   */
  InterfaceType _mapType;

  /**
   * The type representing the built-in type 'Null'.
   */
  InterfaceType _nullType;

  /**
   * The type representing the built-in type 'num'.
   */
  InterfaceType _numType;

  /**
   * The type representing the built-in type 'Object'.
   */
  InterfaceType _objectType;

  /**
   * The type representing the built-in type 'StackTrace'.
   */
  InterfaceType _stackTraceType;

  /**
   * The type representing the built-in type 'String'.
   */
  InterfaceType _stringType;

  /**
   * The type representing the built-in type 'Symbol'.
   */
  InterfaceType _symbolType;

  /**
   * The type representing the built-in type 'Type'.
   */
  InterfaceType _typeType;

  /**
   * The type representing typenames that can't be resolved.
   */
  DartType _undefinedType;

  @override
  InterfaceType get boolType {
    if (_boolType == null) {
      ClassElementImpl boolElement = ElementFactory.classElement2("bool");
      _boolType = boolElement.type;
      ConstructorElementImpl fromEnvironment =
          ElementFactory.constructorElement(boolElement, "fromEnvironment", true);
      fromEnvironment.parameters = <ParameterElement>[
          ElementFactory.requiredParameter2("name", stringType),
          ElementFactory.namedParameter2("defaultValue", _boolType)];
      fromEnvironment.factory = true;
      boolElement.constructors = <ConstructorElement>[fromEnvironment];
    }
    return _boolType;
  }

  @override
  DartType get bottomType {
    if (_bottomType == null) {
      _bottomType = BottomTypeImpl.instance;
    }
    return _bottomType;
  }

  @override
  InterfaceType get deprecatedType {
    if (_deprecatedType == null) {
      ClassElementImpl deprecatedElement =
          ElementFactory.classElement2("Deprecated");
      deprecatedElement.constructors = <ConstructorElement>[
          ElementFactory.constructorElement(deprecatedElement, null, true, [stringType])];
      _deprecatedType = deprecatedElement.type;
    }
    return _deprecatedType;
  }

  @override
  InterfaceType get doubleType {
    if (_doubleType == null) {
      _initializeNumericTypes();
    }
    return _doubleType;
  }

  @override
  DartType get dynamicType {
    if (_dynamicType == null) {
      _dynamicType = DynamicTypeImpl.instance;
    }
    return _dynamicType;
  }

  @override
  InterfaceType get functionType {
    if (_functionType == null) {
      _functionType = ElementFactory.classElement2("Function").type;
    }
    return _functionType;
  }

  @override
  InterfaceType get intType {
    if (_intType == null) {
      _initializeNumericTypes();
    }
    return _intType;
  }

  InterfaceType get iterableType {
    if (_iterableType == null) {
      ClassElementImpl iterableElement =
          ElementFactory.classElement2("Iterable", ["E"]);
      _iterableType = iterableElement.type;
      DartType eType = iterableElement.typeParameters[0].type;
      iterableElement.accessors = <PropertyAccessorElement>[
          ElementFactory.getterElement(
              "iterator",
              false,
              iteratorType.substitute4(<DartType>[eType])),
          ElementFactory.getterElement("last", false, eType)];
      _propagateTypeArguments(iterableElement);
    }
    return _iterableType;
  }

  InterfaceType get iteratorType {
    if (_iteratorType == null) {
      ClassElementImpl iteratorElement =
          ElementFactory.classElement2("Iterator", ["E"]);
      _iteratorType = iteratorElement.type;
      DartType eType = iteratorElement.typeParameters[0].type;
      iteratorElement.accessors = <PropertyAccessorElement>[
          ElementFactory.getterElement("current", false, eType)];
      _propagateTypeArguments(iteratorElement);
    }
    return _iteratorType;
  }

  @override
  InterfaceType get listType {
    if (_listType == null) {
      ClassElementImpl listElement =
          ElementFactory.classElement2("List", ["E"]);
      listElement.constructors =
          <ConstructorElement>[ElementFactory.constructorElement2(listElement, null)];
      _listType = listElement.type;
      DartType eType = listElement.typeParameters[0].type;
      InterfaceType iterableType =
          this.iterableType.substitute4(<DartType>[eType]);
      listElement.interfaces = <InterfaceType>[iterableType];
      listElement.accessors = <PropertyAccessorElement>[
          ElementFactory.getterElement("length", false, intType)];
      listElement.methods = <MethodElement>[
          ElementFactory.methodElement("[]", eType, [intType]),
          ElementFactory.methodElement("[]=", VoidTypeImpl.instance, [intType, eType]),
          ElementFactory.methodElement("add", VoidTypeImpl.instance, [eType])];
      _propagateTypeArguments(listElement);
    }
    return _listType;
  }

  @override
  InterfaceType get mapType {
    if (_mapType == null) {
      ClassElementImpl mapElement =
          ElementFactory.classElement2("Map", ["K", "V"]);
      _mapType = mapElement.type;
      DartType kType = mapElement.typeParameters[0].type;
      DartType vType = mapElement.typeParameters[1].type;
      mapElement.accessors = <PropertyAccessorElement>[
          ElementFactory.getterElement("length", false, intType)];
      mapElement.methods = <MethodElement>[
          ElementFactory.methodElement("[]", vType, [objectType]),
          ElementFactory.methodElement("[]=", VoidTypeImpl.instance, [kType, vType])];
      _propagateTypeArguments(mapElement);
    }
    return _mapType;
  }

  @override
  InterfaceType get nullType {
    if (_nullType == null) {
      _nullType = ElementFactory.classElement2("Null").type;
    }
    return _nullType;
  }

  @override
  InterfaceType get numType {
    if (_numType == null) {
      _initializeNumericTypes();
    }
    return _numType;
  }

  @override
  InterfaceType get objectType {
    if (_objectType == null) {
      ClassElementImpl objectElement = ElementFactory.object;
      _objectType = objectElement.type;
      objectElement.constructors =
          <ConstructorElement>[ElementFactory.constructorElement2(objectElement, null)];
      objectElement.methods = <MethodElement>[
          ElementFactory.methodElement("toString", stringType),
          ElementFactory.methodElement("==", boolType, [_objectType]),
          ElementFactory.methodElement("noSuchMethod", dynamicType, [dynamicType])];
      objectElement.accessors = <PropertyAccessorElement>[
          ElementFactory.getterElement("hashCode", false, intType),
          ElementFactory.getterElement("runtimeType", false, typeType)];
    }
    return _objectType;
  }

  @override
  InterfaceType get stackTraceType {
    if (_stackTraceType == null) {
      _stackTraceType = ElementFactory.classElement2("StackTrace").type;
    }
    return _stackTraceType;
  }

  @override
  InterfaceType get stringType {
    if (_stringType == null) {
      _stringType = ElementFactory.classElement2("String").type;
      ClassElementImpl stringElement = _stringType.element as ClassElementImpl;
      stringElement.accessors = <PropertyAccessorElement>[
          ElementFactory.getterElement("isEmpty", false, boolType),
          ElementFactory.getterElement("length", false, intType),
          ElementFactory.getterElement(
              "codeUnits",
              false,
              listType.substitute4(<DartType>[intType]))];
      stringElement.methods = <MethodElement>[
          ElementFactory.methodElement("+", _stringType, [_stringType]),
          ElementFactory.methodElement("toLowerCase", _stringType),
          ElementFactory.methodElement("toUpperCase", _stringType)];
      ConstructorElementImpl fromEnvironment =
          ElementFactory.constructorElement(stringElement, "fromEnvironment", true);
      fromEnvironment.parameters = <ParameterElement>[
          ElementFactory.requiredParameter2("name", stringType),
          ElementFactory.namedParameter2("defaultValue", _stringType)];
      fromEnvironment.factory = true;
      stringElement.constructors = <ConstructorElement>[fromEnvironment];
    }
    return _stringType;
  }

  @override
  InterfaceType get symbolType {
    if (_symbolType == null) {
      ClassElementImpl symbolClass = ElementFactory.classElement2("Symbol");
      ConstructorElementImpl constructor =
          ElementFactory.constructorElement(symbolClass, null, true, [stringType]);
      constructor.factory = true;
      symbolClass.constructors = <ConstructorElement>[constructor];
      _symbolType = symbolClass.type;
    }
    return _symbolType;
  }

  @override
  InterfaceType get typeType {
    if (_typeType == null) {
      _typeType = ElementFactory.classElement2("Type").type;
    }
    return _typeType;
  }

  @override
  DartType get undefinedType {
    if (_undefinedType == null) {
      _undefinedType = UndefinedTypeImpl.instance;
    }
    return _undefinedType;
  }

  /**
   * Initialize the numeric types. They are created as a group so that we can (a) create the right
   * hierarchy and (b) add members to them.
   */
  void _initializeNumericTypes() {
    //
    // Create the type hierarchy.
    //
    ClassElementImpl numElement = ElementFactory.classElement2("num");
    _numType = numElement.type;
    ClassElementImpl intElement = ElementFactory.classElement("int", _numType);
    _intType = intElement.type;
    ClassElementImpl doubleElement =
        ElementFactory.classElement("double", _numType);
    _doubleType = doubleElement.type;
    //
    // Force the referenced types to be cached.
    //
    objectType;
    boolType;
    stringType;
    //
    // Add the methods.
    //
    numElement.methods = <MethodElement>[
        ElementFactory.methodElement("+", _numType, [_numType]),
        ElementFactory.methodElement("-", _numType, [_numType]),
        ElementFactory.methodElement("*", _numType, [_numType]),
        ElementFactory.methodElement("%", _numType, [_numType]),
        ElementFactory.methodElement("/", _doubleType, [_numType]),
        ElementFactory.methodElement("~/", _numType, [_numType]),
        ElementFactory.methodElement("-", _numType),
        ElementFactory.methodElement("remainder", _numType, [_numType]),
        ElementFactory.methodElement("<", _boolType, [_numType]),
        ElementFactory.methodElement("<=", _boolType, [_numType]),
        ElementFactory.methodElement(">", _boolType, [_numType]),
        ElementFactory.methodElement(">=", _boolType, [_numType]),
        ElementFactory.methodElement("==", _boolType, [_objectType]),
        ElementFactory.methodElement("isNaN", _boolType),
        ElementFactory.methodElement("isNegative", _boolType),
        ElementFactory.methodElement("isInfinite", _boolType),
        ElementFactory.methodElement("abs", _numType),
        ElementFactory.methodElement("floor", _numType),
        ElementFactory.methodElement("ceil", _numType),
        ElementFactory.methodElement("round", _numType),
        ElementFactory.methodElement("truncate", _numType),
        ElementFactory.methodElement("toInt", _intType),
        ElementFactory.methodElement("toDouble", _doubleType),
        ElementFactory.methodElement("toStringAsFixed", _stringType, [_intType]),
        ElementFactory.methodElement("toStringAsExponential", _stringType, [_intType]),
        ElementFactory.methodElement("toStringAsPrecision", _stringType, [_intType]),
        ElementFactory.methodElement("toRadixString", _stringType, [_intType])];
    intElement.methods = <MethodElement>[
        ElementFactory.methodElement("&", _intType, [_intType]),
        ElementFactory.methodElement("|", _intType, [_intType]),
        ElementFactory.methodElement("^", _intType, [_intType]),
        ElementFactory.methodElement("~", _intType),
        ElementFactory.methodElement("<<", _intType, [_intType]),
        ElementFactory.methodElement(">>", _intType, [_intType]),
        ElementFactory.methodElement("-", _intType),
        ElementFactory.methodElement("abs", _intType),
        ElementFactory.methodElement("round", _intType),
        ElementFactory.methodElement("floor", _intType),
        ElementFactory.methodElement("ceil", _intType),
        ElementFactory.methodElement("truncate", _intType),
        ElementFactory.methodElement("toString", _stringType)];
    ConstructorElementImpl fromEnvironment =
        ElementFactory.constructorElement(intElement, "fromEnvironment", true);
    fromEnvironment.parameters = <ParameterElement>[
        ElementFactory.requiredParameter2("name", stringType),
        ElementFactory.namedParameter2("defaultValue", _intType)];
    fromEnvironment.factory = true;
    intElement.constructors = <ConstructorElement>[fromEnvironment];
    List<FieldElement> fields = <FieldElement>[
        ElementFactory.fieldElement("NAN", true, false, true, _doubleType),
        ElementFactory.fieldElement("INFINITY", true, false, true, _doubleType),
        ElementFactory.fieldElement(
            "NEGATIVE_INFINITY",
            true,
            false,
            true,
            _doubleType),
        ElementFactory.fieldElement("MIN_POSITIVE", true, false, true, _doubleType),
        ElementFactory.fieldElement("MAX_FINITE", true, false, true, _doubleType)];
    doubleElement.fields = fields;
    int fieldCount = fields.length;
    List<PropertyAccessorElement> accessors =
        new List<PropertyAccessorElement>(fieldCount);
    for (int i = 0; i < fieldCount; i++) {
      accessors[i] = fields[i].getter;
    }
    doubleElement.accessors = accessors;
    doubleElement.methods = <MethodElement>[
        ElementFactory.methodElement("remainder", _doubleType, [_numType]),
        ElementFactory.methodElement("+", _doubleType, [_numType]),
        ElementFactory.methodElement("-", _doubleType, [_numType]),
        ElementFactory.methodElement("*", _doubleType, [_numType]),
        ElementFactory.methodElement("%", _doubleType, [_numType]),
        ElementFactory.methodElement("/", _doubleType, [_numType]),
        ElementFactory.methodElement("~/", _doubleType, [_numType]),
        ElementFactory.methodElement("-", _doubleType),
        ElementFactory.methodElement("abs", _doubleType),
        ElementFactory.methodElement("round", _doubleType),
        ElementFactory.methodElement("floor", _doubleType),
        ElementFactory.methodElement("ceil", _doubleType),
        ElementFactory.methodElement("truncate", _doubleType),
        ElementFactory.methodElement("toString", _stringType)];
  }

  /**
   * Given a class element representing a class with type parameters, propagate those type
   * parameters to all of the accessors, methods and constructors defined for the class.
   *
   * @param classElement the element representing the class with type parameters
   */
  void _propagateTypeArguments(ClassElementImpl classElement) {
    List<DartType> typeArguments =
        TypeParameterTypeImpl.getTypes(classElement.typeParameters);
    for (PropertyAccessorElement accessor in classElement.accessors) {
      FunctionTypeImpl functionType = accessor.type as FunctionTypeImpl;
      functionType.typeArguments = typeArguments;
    }
    for (MethodElement method in classElement.methods) {
      FunctionTypeImpl functionType = method.type as FunctionTypeImpl;
      functionType.typeArguments = typeArguments;
    }
    for (ConstructorElement constructor in classElement.constructors) {
      FunctionTypeImpl functionType = constructor.type as FunctionTypeImpl;
      functionType.typeArguments = typeArguments;
    }
  }
}

class TypeOverrideManagerTest extends EngineTestCase {
  void test_exitScope_noScopes() {
    TypeOverrideManager manager = new TypeOverrideManager();
    try {
      manager.exitScope();
      fail("Expected IllegalStateException");
    } on IllegalStateException catch (exception) {
      // Expected
    }
  }

  void test_exitScope_oneScope() {
    TypeOverrideManager manager = new TypeOverrideManager();
    manager.enterScope();
    manager.exitScope();
    try {
      manager.exitScope();
      fail("Expected IllegalStateException");
    } on IllegalStateException catch (exception) {
      // Expected
    }
  }

  void test_exitScope_twoScopes() {
    TypeOverrideManager manager = new TypeOverrideManager();
    manager.enterScope();
    manager.exitScope();
    manager.enterScope();
    manager.exitScope();
    try {
      manager.exitScope();
      fail("Expected IllegalStateException");
    } on IllegalStateException catch (exception) {
      // Expected
    }
  }

  void test_getType_enclosedOverride() {
    TypeOverrideManager manager = new TypeOverrideManager();
    LocalVariableElementImpl element =
        ElementFactory.localVariableElement2("v");
    InterfaceType type = ElementFactory.classElement2("C").type;
    manager.enterScope();
    manager.setType(element, type);
    manager.enterScope();
    expect(manager.getType(element), same(type));
  }

  void test_getType_immediateOverride() {
    TypeOverrideManager manager = new TypeOverrideManager();
    LocalVariableElementImpl element =
        ElementFactory.localVariableElement2("v");
    InterfaceType type = ElementFactory.classElement2("C").type;
    manager.enterScope();
    manager.setType(element, type);
    expect(manager.getType(element), same(type));
  }

  void test_getType_noOverride() {
    TypeOverrideManager manager = new TypeOverrideManager();
    manager.enterScope();
    expect(manager.getType(ElementFactory.localVariableElement2("v")), isNull);
  }

  void test_getType_noScope() {
    TypeOverrideManager manager = new TypeOverrideManager();
    expect(manager.getType(ElementFactory.localVariableElement2("v")), isNull);
  }
}

class TypePropagationTest extends ResolverTestCase {
  void fail_mergePropagatedTypesAtJoinPoint_1() {
    // https://code.google.com/p/dart/issues/detail?id=19929
    _assertTypeOfMarkedExpression(r'''
f1(x) {
  var y = [];
  if (x) {
    y = 0;
  } else {
    y = '';
  }
  // Propagated type is [List] here: incorrect.
  // Best we can do is [Object]?
  return y; // marker
}''', null, typeProvider.dynamicType);
  }

  void fail_mergePropagatedTypesAtJoinPoint_2() {
    // https://code.google.com/p/dart/issues/detail?id=19929
    _assertTypeOfMarkedExpression(r'''
f2(x) {
  var y = [];
  if (x) {
    y = 0;
  } else {
  }
  // Propagated type is [List] here: incorrect.
  // Best we can do is [Object]?
  return y; // marker
}''', null, typeProvider.dynamicType);
  }

  void fail_mergePropagatedTypesAtJoinPoint_3() {
    // https://code.google.com/p/dart/issues/detail?id=19929
    _assertTypeOfMarkedExpression(r'''
f4(x) {
  var y = [];
  if (x) {
    y = 0;
  } else {
    y = 1.5;
  }
  // Propagated type is [List] here: incorrect.
  // A correct answer is the least upper bound of [int] and [double],
  // i.e. [num].
  return y; // marker
}''', null, typeProvider.numType);
  }

  void fail_mergePropagatedTypesAtJoinPoint_5() {
    // https://code.google.com/p/dart/issues/detail?id=19929
    _assertTypeOfMarkedExpression(r'''
f6(x,y) {
  var z = [];
  if (x || (z = y) < 0) {
  } else {
    z = 0;
  }
  // Propagated type is [List] here: incorrect.
  // Best we can do is [Object]?
  return z; // marker
}''', null, typeProvider.dynamicType);
  }

  void fail_mergePropagatedTypesAtJoinPoint_7() {
    // https://code.google.com/p/dart/issues/detail?id=19929
    //
    // In general [continue]s are unsafe for the purposes of
    // [isAbruptTerminationStatement].
    //
    // This is like example 6, but less tricky: the code in the branch that
    // [continue]s is in effect after the [if].
    String code = r'''
f() {
  var x = 0;
  var c = false;
  var d = true;
  while (d) {
    if (c) {
      d = false;
    } else {
      x = '';
      c = true;
      continue;
    }
    x; // marker
  }
}''';
    DartType t = _findMarkedIdentifier(code, "; // marker").propagatedType;
    expect(typeProvider.intType.isSubtypeOf(t), isTrue);
    expect(typeProvider.stringType.isSubtypeOf(t), isTrue);
  }

  void fail_mergePropagatedTypesAtJoinPoint_8() {
    // https://code.google.com/p/dart/issues/detail?id=19929
    //
    // In nested loops [breaks]s are unsafe for the purposes of
    // [isAbruptTerminationStatement].
    //
    // This is a combination of 6 and 7: we use an unlabeled [break]
    // like a continue for the outer loop / like a labeled [break] to
    // jump just above the [if].
    String code = r'''
f() {
  var x = 0;
  var c = false;
  var d = true;
  while (d) {
    while (d) {
      if (c) {
        d = false;
      } else {
        x = '';
        c = true;
        break;
      }
      x; // marker
    }
  }
}''';
    DartType t = _findMarkedIdentifier(code, "; // marker").propagatedType;
    expect(typeProvider.intType.isSubtypeOf(t), isTrue);
    expect(typeProvider.stringType.isSubtypeOf(t), isTrue);
  }

  void fail_propagatedReturnType_functionExpression() {
    // TODO(scheglov) disabled because we don't resolve function expression
    String code = r'''
main() {
  var v = (() {return 42;})();
}''';
    _assertPropagatedReturnType(
        code,
        typeProvider.dynamicType,
        typeProvider.intType);
  }

  void test_as() {
    Source source = addSource(r'''
class A {
  bool get g => true;
}
A f(var p) {
  if ((p as A).g) {
    return p;
  } else {
    return null;
  }
}''');
    LibraryElement library = resolve(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    IfStatement ifStatement = body.block.statements[0] as IfStatement;
    ReturnStatement statement =
        (ifStatement.thenStatement as Block).statements[0] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    expect(variableName.propagatedType, same(typeA));
  }

  void test_assert() {
    Source source = addSource(r'''
class A {}
A f(var p) {
  assert (p is A);
  return p;
}''');
    LibraryElement library = resolve(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body.block.statements[1] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    expect(variableName.propagatedType, same(typeA));
  }

  void test_assignment() {
    Source source = addSource(r'''
f() {
  var v;
  v = 0;
  return v;
}''');
    LibraryElement library = resolve(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    FunctionDeclaration function = unit.declarations[0] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body.block.statements[2] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    expect(variableName.propagatedType, same(typeProvider.intType));
  }

  void test_assignment_afterInitializer() {
    Source source = addSource(r'''
f() {
  var v = 0;
  v = 1.0;
  return v;
}''');
    LibraryElement library = resolve(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    FunctionDeclaration function = unit.declarations[0] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body.block.statements[2] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    expect(variableName.propagatedType, same(typeProvider.doubleType));
  }

  void test_assignment_null() {
    String code = r'''
main() {
  int v; // declare
  v = null;
  return v; // return
}''';
    CompilationUnit unit;
    {
      Source source = addSource(code);
      LibraryElement library = resolve(source);
      assertNoErrors(source);
      verify([source]);
      unit = resolveCompilationUnit(source, library);
    }
    {
      SimpleIdentifier identifier = EngineTestCase.findNode(
          unit,
          code,
          "v; // declare",
          (node) => node is SimpleIdentifier);
      expect(identifier.staticType, same(typeProvider.intType));
      expect(identifier.propagatedType, same(null));
    }
    {
      SimpleIdentifier identifier = EngineTestCase.findNode(
          unit,
          code,
          "v = null;",
          (node) => node is SimpleIdentifier);
      expect(identifier.staticType, same(typeProvider.intType));
      expect(identifier.propagatedType, same(null));
    }
    {
      SimpleIdentifier identifier = EngineTestCase.findNode(
          unit,
          code,
          "v; // return",
          (node) => node is SimpleIdentifier);
      expect(identifier.staticType, same(typeProvider.intType));
      expect(identifier.propagatedType, same(null));
    }
  }

  void test_CanvasElement_getContext() {
    String code = r'''
import 'dart:html';
main(CanvasElement canvas) {
  var context = canvas.getContext('2d');
}''';
    Source source = addSource(code);
    LibraryElement library = resolve(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    SimpleIdentifier identifier = EngineTestCase.findNode(
        unit,
        code,
        "context",
        (node) => node is SimpleIdentifier);
    expect(identifier.propagatedType.name, "CanvasRenderingContext2D");
  }

  void test_finalPropertyInducingVariable_classMember_instance() {
    addNamedSource("/lib.dart", r'''
class A {
  final v = 0;
}''');
    String code = r'''
import 'lib.dart';
f(A a) {
  return a.v; // marker
}''';
    _assertTypeOfMarkedExpression(
        code,
        typeProvider.dynamicType,
        typeProvider.intType);
  }

  void test_finalPropertyInducingVariable_classMember_instance_inherited() {
    addNamedSource("/lib.dart", r'''
class A {
  final v = 0;
}''');
    String code = r'''
import 'lib.dart';
class B extends A {
  m() {
    return v; // marker
  }
}''';
    _assertTypeOfMarkedExpression(
        code,
        typeProvider.dynamicType,
        typeProvider.intType);
  }

  void
      test_finalPropertyInducingVariable_classMember_instance_propagatedTarget() {
    addNamedSource("/lib.dart", r'''
class A {
  final v = 0;
}''');
    String code = r'''
import 'lib.dart';
f(p) {
  if (p is A) {
    return p.v; // marker
  }
}''';
    _assertTypeOfMarkedExpression(
        code,
        typeProvider.dynamicType,
        typeProvider.intType);
  }

  void test_finalPropertyInducingVariable_classMember_static() {
    addNamedSource("/lib.dart", r'''
class A {
  static final V = 0;
}''');
    String code = r'''
import 'lib.dart';
f() {
  return A.V; // marker
}''';
    _assertTypeOfMarkedExpression(
        code,
        typeProvider.dynamicType,
        typeProvider.intType);
  }

  void test_finalPropertyInducingVariable_topLevelVaraible_prefixed() {
    addNamedSource("/lib.dart", "final V = 0;");
    String code = r'''
import 'lib.dart' as p;
f() {
  var v2 = p.V; // marker prefixed
}''';
    _assertTypeOfMarkedExpression(
        code,
        typeProvider.dynamicType,
        typeProvider.intType);
  }

  void test_finalPropertyInducingVariable_topLevelVaraible_simple() {
    addNamedSource("/lib.dart", "final V = 0;");
    String code = r'''
import 'lib.dart';
f() {
  return V; // marker simple
}''';
    _assertTypeOfMarkedExpression(
        code,
        typeProvider.dynamicType,
        typeProvider.intType);
  }

  void test_forEach() {
    String code = r'''
main() {
  var list = <String> [];
  for (var e in list) {
    e;
  }
}''';
    Source source = addSource(code);
    LibraryElement library = resolve(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    InterfaceType stringType = typeProvider.stringType;
    // in the declaration
    {
      SimpleIdentifier identifier = EngineTestCase.findNode(
          unit,
          code,
          "e in",
          (node) => node is SimpleIdentifier);
      expect(identifier.propagatedType, same(stringType));
    }
    // in the loop body
    {
      SimpleIdentifier identifier =
          EngineTestCase.findNode(unit, code, "e;", (node) => node is SimpleIdentifier);
      expect(identifier.propagatedType, same(stringType));
    }
  }

  void test_functionExpression_asInvocationArgument() {
    String code = r'''
class MyMap<K, V> {
  forEach(f(K key, V value)) {}
}
f(MyMap<int, String> m) {
  m.forEach((k, v) {
    k;
    v;
  });
}''';
    Source source = addSource(code);
    LibraryElement library = resolve(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    // k
    DartType intType = typeProvider.intType;
    FormalParameter kParameter = EngineTestCase.findNode(
        unit,
        code,
        "k, ",
        (node) => node is SimpleFormalParameter);
    expect(kParameter.identifier.propagatedType, same(intType));
    SimpleIdentifier kIdentifier =
        EngineTestCase.findNode(unit, code, "k;", (node) => node is SimpleIdentifier);
    expect(kIdentifier.propagatedType, same(intType));
    expect(kIdentifier.staticType, same(typeProvider.dynamicType));
    // v
    DartType stringType = typeProvider.stringType;
    FormalParameter vParameter = EngineTestCase.findNode(
        unit,
        code,
        "v)",
        (node) => node is SimpleFormalParameter);
    expect(vParameter.identifier.propagatedType, same(stringType));
    SimpleIdentifier vIdentifier =
        EngineTestCase.findNode(unit, code, "v;", (node) => node is SimpleIdentifier);
    expect(vIdentifier.propagatedType, same(stringType));
    expect(vIdentifier.staticType, same(typeProvider.dynamicType));
  }

  void test_functionExpression_asInvocationArgument_fromInferredInvocation() {
    String code = r'''
class MyMap<K, V> {
  forEach(f(K key, V value)) {}
}
f(MyMap<int, String> m) {
  var m2 = m;
  m2.forEach((k, v) {});
}''';
    Source source = addSource(code);
    LibraryElement library = resolve(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    // k
    DartType intType = typeProvider.intType;
    FormalParameter kParameter = EngineTestCase.findNode(
        unit,
        code,
        "k, ",
        (node) => node is SimpleFormalParameter);
    expect(kParameter.identifier.propagatedType, same(intType));
    // v
    DartType stringType = typeProvider.stringType;
    FormalParameter vParameter = EngineTestCase.findNode(
        unit,
        code,
        "v)",
        (node) => node is SimpleFormalParameter);
    expect(vParameter.identifier.propagatedType, same(stringType));
  }

  void
      test_functionExpression_asInvocationArgument_functionExpressionInvocation() {
    String code = r'''
main() {
  (f(String value)) {} ((v) {
    v;
  });
}''';
    Source source = addSource(code);
    LibraryElement library = resolve(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    // v
    DartType dynamicType = typeProvider.dynamicType;
    DartType stringType = typeProvider.stringType;
    FormalParameter vParameter =
        EngineTestCase.findNode(unit, code, "v)", (node) => node is FormalParameter);
    expect(vParameter.identifier.propagatedType, same(stringType));
    expect(vParameter.identifier.staticType, same(dynamicType));
    SimpleIdentifier vIdentifier =
        EngineTestCase.findNode(unit, code, "v;", (node) => node is SimpleIdentifier);
    expect(vIdentifier.propagatedType, same(stringType));
    expect(vIdentifier.staticType, same(dynamicType));
  }

  void test_functionExpression_asInvocationArgument_keepIfLessSpecific() {
    String code = r'''
class MyList {
  forEach(f(Object value)) {}
}
f(MyList list) {
  list.forEach((int v) {
    v;
  });
}''';
    Source source = addSource(code);
    LibraryElement library = resolve(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    // v
    DartType intType = typeProvider.intType;
    FormalParameter vParameter = EngineTestCase.findNode(
        unit,
        code,
        "v)",
        (node) => node is SimpleFormalParameter);
    expect(vParameter.identifier.propagatedType, same(null));
    expect(vParameter.identifier.staticType, same(intType));
    SimpleIdentifier vIdentifier =
        EngineTestCase.findNode(unit, code, "v;", (node) => node is SimpleIdentifier);
    expect(vIdentifier.staticType, same(intType));
    expect(vIdentifier.propagatedType, same(null));
  }

  void test_functionExpression_asInvocationArgument_notSubtypeOfStaticType() {
    String code = r'''
class A {
  m(void f(int i)) {}
}
x() {
  A a = new A();
  a.m(() => 0);
}''';
    Source source = addSource(code);
    LibraryElement library = resolve(source);
    assertErrors(source, [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    // () => 0
    FunctionExpression functionExpression = EngineTestCase.findNode(
        unit,
        code,
        "() => 0)",
        (node) => node is FunctionExpression);
    expect(
        (functionExpression.staticType as FunctionType).parameters.length,
        same(0));
    expect(functionExpression.propagatedType, same(null));
  }

  void test_functionExpression_asInvocationArgument_replaceIfMoreSpecific() {
    String code = r'''
class MyList<E> {
  forEach(f(E value)) {}
}
f(MyList<String> list) {
  list.forEach((Object v) {
    v;
  });
}''';
    Source source = addSource(code);
    LibraryElement library = resolve(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    // v
    DartType stringType = typeProvider.stringType;
    FormalParameter vParameter = EngineTestCase.findNode(
        unit,
        code,
        "v)",
        (node) => node is SimpleFormalParameter);
    expect(vParameter.identifier.propagatedType, same(stringType));
    expect(vParameter.identifier.staticType, same(typeProvider.objectType));
    SimpleIdentifier vIdentifier =
        EngineTestCase.findNode(unit, code, "v;", (node) => node is SimpleIdentifier);
    expect(vIdentifier.propagatedType, same(stringType));
  }

  void test_Future_then() {
    String code = r'''
import 'dart:async';
main(Future<int> firstFuture) {
  firstFuture.then((p1) {
    return 1.0;
  }).then((p2) {
    return new Future<String>.value('str');
  }).then((p3) {
  });
}''';
    Source source = addSource(code);
    LibraryElement library = resolve(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    // p1
    FormalParameter p1 = EngineTestCase.findNode(
        unit,
        code,
        "p1) {",
        (node) => node is SimpleFormalParameter);
    expect(p1.identifier.propagatedType, same(typeProvider.intType));
    // p2
    FormalParameter p2 = EngineTestCase.findNode(
        unit,
        code,
        "p2) {",
        (node) => node is SimpleFormalParameter);
    expect(p2.identifier.propagatedType, same(typeProvider.doubleType));
    // p3
    FormalParameter p3 = EngineTestCase.findNode(
        unit,
        code,
        "p3) {",
        (node) => node is SimpleFormalParameter);
    expect(p3.identifier.propagatedType, same(typeProvider.stringType));
  }

  void test_initializer() {
    Source source = addSource(r'''
f() {
  var v = 0;
  return v;
}''');
    LibraryElement library = resolve(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    FunctionDeclaration function = unit.declarations[0] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    NodeList<Statement> statements = body.block.statements;
    // Type of 'v' in declaration.
    {
      VariableDeclarationStatement statement =
          statements[0] as VariableDeclarationStatement;
      SimpleIdentifier variableName = statement.variables.variables[0].name;
      expect(variableName.staticType, same(typeProvider.dynamicType));
      expect(variableName.propagatedType, same(typeProvider.intType));
    }
    // Type of 'v' in reference.
    {
      ReturnStatement statement = statements[1] as ReturnStatement;
      SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
      expect(variableName.propagatedType, same(typeProvider.intType));
    }
  }

  void test_initializer_dereference() {
    Source source = addSource(r'''
f() {
  var v = 'String';
  v.
}''');
    LibraryElement library = resolve(source);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    FunctionDeclaration function = unit.declarations[0] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    ExpressionStatement statement =
        body.block.statements[1] as ExpressionStatement;
    PrefixedIdentifier invocation = statement.expression as PrefixedIdentifier;
    SimpleIdentifier variableName = invocation.prefix;
    expect(variableName.propagatedType, same(typeProvider.stringType));
  }

  void test_initializer_null() {
    String code = r'''
main() {
  int v = null;
  return v; // marker
}''';
    CompilationUnit unit;
    {
      Source source = addSource(code);
      LibraryElement library = resolve(source);
      assertNoErrors(source);
      verify([source]);
      unit = resolveCompilationUnit(source, library);
    }
    {
      SimpleIdentifier identifier = EngineTestCase.findNode(
          unit,
          code,
          "v = null;",
          (node) => node is SimpleIdentifier);
      expect(identifier.staticType, same(typeProvider.intType));
      expect(identifier.propagatedType, same(null));
    }
    {
      SimpleIdentifier identifier = EngineTestCase.findNode(
          unit,
          code,
          "v; // marker",
          (node) => node is SimpleIdentifier);
      expect(identifier.staticType, same(typeProvider.intType));
      expect(identifier.propagatedType, same(null));
    }
  }

  void test_is_conditional() {
    Source source = addSource(r'''
class A {}
A f(var p) {
  return (p is A) ? p : null;
}''');
    LibraryElement library = resolve(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body.block.statements[0] as ReturnStatement;
    ConditionalExpression conditional =
        statement.expression as ConditionalExpression;
    SimpleIdentifier variableName =
        conditional.thenExpression as SimpleIdentifier;
    expect(variableName.propagatedType, same(typeA));
  }

  void test_is_if() {
    Source source = addSource(r'''
class A {}
A f(var p) {
  if (p is A) {
    return p;
  } else {
    return null;
  }
}''');
    LibraryElement library = resolve(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    IfStatement ifStatement = body.block.statements[0] as IfStatement;
    ReturnStatement statement =
        (ifStatement.thenStatement as Block).statements[0] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    expect(variableName.propagatedType, same(typeA));
  }

  void test_is_if_lessSpecific() {
    Source source = addSource(r'''
class A {}
A f(A p) {
  if (p is String) {
    return p;
  } else {
    return null;
  }
}''');
    LibraryElement library = resolve(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
//    ClassDeclaration classA = (ClassDeclaration) unit.getDeclarations().get(0);
//    InterfaceType typeA = classA.getElement().getType();
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    IfStatement ifStatement = body.block.statements[0] as IfStatement;
    ReturnStatement statement =
        (ifStatement.thenStatement as Block).statements[0] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    expect(variableName.propagatedType, same(null));
  }

  void test_is_if_logicalAnd() {
    Source source = addSource(r'''
class A {}
A f(var p) {
  if (p is A && p != null) {
    return p;
  } else {
    return null;
  }
}''');
    LibraryElement library = resolve(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    IfStatement ifStatement = body.block.statements[0] as IfStatement;
    ReturnStatement statement =
        (ifStatement.thenStatement as Block).statements[0] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    expect(variableName.propagatedType, same(typeA));
  }

  void test_is_postConditional() {
    Source source = addSource(r'''
class A {}
A f(var p) {
  A a = (p is A) ? p : throw null;
  return p;
}''');
    LibraryElement library = resolve(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body.block.statements[1] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    expect(variableName.propagatedType, same(typeA));
  }

  void test_is_postIf() {
    Source source = addSource(r'''
class A {}
A f(var p) {
  if (p is A) {
    A a = p;
  } else {
    return null;
  }
  return p;
}''');
    LibraryElement library = resolve(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body.block.statements[1] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    expect(variableName.propagatedType, same(typeA));
  }

  void test_is_subclass() {
    Source source = addSource(r'''
class A {}
class B extends A {
  B m() => this;
}
A f(A p) {
  if (p is B) {
    return p.m();
  }
  return p;
}''');
    LibraryElement library = resolve(source);
    assertNoErrors(source);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    FunctionDeclaration function = unit.declarations[2] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    IfStatement ifStatement = body.block.statements[0] as IfStatement;
    ReturnStatement statement =
        (ifStatement.thenStatement as Block).statements[0] as ReturnStatement;
    MethodInvocation invocation = statement.expression as MethodInvocation;
    expect(invocation.methodName.propagatedElement, isNotNull);
  }

  void test_is_while() {
    Source source = addSource(r'''
class A {}
A f(var p) {
  while (p is A) {
    return p;
  }
  return p;
}''');
    LibraryElement library = resolve(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    WhileStatement whileStatement = body.block.statements[0] as WhileStatement;
    ReturnStatement statement =
        (whileStatement.body as Block).statements[0] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    expect(variableName.propagatedType, same(typeA));
  }

  void test_isNot_conditional() {
    Source source = addSource(r'''
class A {}
A f(var p) {
  return (p is! A) ? null : p;
}''');
    LibraryElement library = resolve(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body.block.statements[0] as ReturnStatement;
    ConditionalExpression conditional =
        statement.expression as ConditionalExpression;
    SimpleIdentifier variableName =
        conditional.elseExpression as SimpleIdentifier;
    expect(variableName.propagatedType, same(typeA));
  }

  void test_isNot_if() {
    Source source = addSource(r'''
class A {}
A f(var p) {
  if (p is! A) {
    return null;
  } else {
    return p;
  }
}''');
    LibraryElement library = resolve(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    IfStatement ifStatement = body.block.statements[0] as IfStatement;
    ReturnStatement statement =
        (ifStatement.elseStatement as Block).statements[0] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    expect(variableName.propagatedType, same(typeA));
  }

  void test_isNot_if_logicalOr() {
    Source source = addSource(r'''
class A {}
A f(var p) {
  if (p is! A || null == p) {
    return null;
  } else {
    return p;
  }
}''');
    LibraryElement library = resolve(source);
    assertNoErrors(source);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    IfStatement ifStatement = body.block.statements[0] as IfStatement;
    ReturnStatement statement =
        (ifStatement.elseStatement as Block).statements[0] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    expect(variableName.propagatedType, same(typeA));
  }

  void test_isNot_postConditional() {
    Source source = addSource(r'''
class A {}
A f(var p) {
  A a = (p is! A) ? throw null : p;
  return p;
}''');
    LibraryElement library = resolve(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body.block.statements[1] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    expect(variableName.propagatedType, same(typeA));
  }

  void test_isNot_postIf() {
    Source source = addSource(r'''
class A {}
A f(var p) {
  if (p is! A) {
    return null;
  }
  return p;
}''');
    LibraryElement library = resolve(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    ClassDeclaration classA = unit.declarations[0] as ClassDeclaration;
    InterfaceType typeA = classA.element.type;
    FunctionDeclaration function = unit.declarations[1] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body.block.statements[1] as ReturnStatement;
    SimpleIdentifier variableName = statement.expression as SimpleIdentifier;
    expect(variableName.propagatedType, same(typeA));
  }

  void test_issue20904BuggyTypePromotionAtIfJoin_2() {
    // https://code.google.com/p/dart/issues/detail?id=20904
    enableUnionTypes(false);
    String code = r'''
f(var message) {
  if (message is Function) {
    message = '';
  }
  message; // marker
}''';
    DartType t = _findMarkedIdentifier(code, "; // marker").propagatedType;
    expect(typeProvider.stringType == t, isFalse);
    expect(typeProvider.functionType == t, isFalse);
  }

  void test_issue20904BuggyTypePromotionAtIfJoin_5() {
    // https://code.google.com/p/dart/issues/detail?id=20904
    //
    // This is not an example of the 20904 bug, but rather,
    // an example of something that one obvious fix changes inadvertently: we
    // want to avoid using type information from is-checks when it
    // loses precision. I can't see how to get a bad hint this way, since
    // it seems the propagated type is not used to generate hints when a
    // more precise type would cause no hint. For example, for code like the
    // following, when the propagated type of [x] is [A] -- as happens for the
    // fix these tests aim to warn against -- there is no warning for


    // calling a method defined on [B] but not [A] (there aren't any, but
    // pretend), but there is for calling a method not defined on either.
    // By not overriding the propagated type via an is-check that loses
    // precision, we get more precise completion under an is-check. However,
    // I can only imagine strange code would make use of this feature.
    //
    // Here the is-check improves precision, so we use it.
    String code = r'''
class A {}
class B extends A {}
f() {
  var a = new A();
  var b = new B();
  b; // B
  if (a is B) {
    return a; // marker
  }
}''';
    DartType tB = _findMarkedIdentifier(code, "; // B").propagatedType;
    _assertTypeOfMarkedExpression(code, null, tB);
  }

  void test_issue20904BuggyTypePromotionAtIfJoin_6() {
    // https://code.google.com/p/dart/issues/detail?id=20904
    //
    // The other half of the *_5() test.
    //
    // Here the is-check loses precision, so we don't use it.
    String code = r'''
class A {}
class B extends A {}
f() {
  var b = new B();
  b; // B
  if (b is A) {
    return b; // marker
  }
}''';
    DartType tB = _findMarkedIdentifier(code, "; // B").propagatedType;
    _assertTypeOfMarkedExpression(code, null, tB);
  }

  void test_listLiteral_different() {
    Source source = addSource(r'''
f() {
  var v = [0, '1', 2];
  return v[2];
}''');
    LibraryElement library = resolve(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    FunctionDeclaration function = unit.declarations[0] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body.block.statements[1] as ReturnStatement;
    IndexExpression indexExpression = statement.expression as IndexExpression;
    expect(indexExpression.propagatedType, isNull);
  }

  void test_listLiteral_same() {
    Source source = addSource(r'''
f() {
  var v = [0, 1, 2];
  return v[2];
}''');
    LibraryElement library = resolve(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    FunctionDeclaration function = unit.declarations[0] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body.block.statements[1] as ReturnStatement;
    IndexExpression indexExpression = statement.expression as IndexExpression;
    expect(indexExpression.propagatedType, isNull);
    Expression v = indexExpression.target;
    InterfaceType propagatedType = v.propagatedType as InterfaceType;
    expect(propagatedType.element, same(typeProvider.listType.element));
    List<DartType> typeArguments = propagatedType.typeArguments;
    expect(typeArguments, hasLength(1));
    expect(typeArguments[0], same(typeProvider.dynamicType));
  }

  void test_mapLiteral_different() {
    Source source = addSource(r'''
f() {
  var v = {'0' : 0, 1 : '1', '2' : 2};
  return v;
}''');
    LibraryElement library = resolve(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    FunctionDeclaration function = unit.declarations[0] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body.block.statements[1] as ReturnStatement;
    SimpleIdentifier identifier = statement.expression as SimpleIdentifier;
    InterfaceType propagatedType = identifier.propagatedType as InterfaceType;
    expect(propagatedType.element, same(typeProvider.mapType.element));
    List<DartType> typeArguments = propagatedType.typeArguments;
    expect(typeArguments, hasLength(2));
    expect(typeArguments[0], same(typeProvider.dynamicType));
    expect(typeArguments[1], same(typeProvider.dynamicType));
  }

  void test_mapLiteral_same() {
    Source source = addSource(r'''
f() {
  var v = {'a' : 0, 'b' : 1, 'c' : 2};
  return v;
}''');
    LibraryElement library = resolve(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    FunctionDeclaration function = unit.declarations[0] as FunctionDeclaration;
    BlockFunctionBody body =
        function.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body.block.statements[1] as ReturnStatement;
    SimpleIdentifier identifier = statement.expression as SimpleIdentifier;
    InterfaceType propagatedType = identifier.propagatedType as InterfaceType;
    expect(propagatedType.element, same(typeProvider.mapType.element));
    List<DartType> typeArguments = propagatedType.typeArguments;
    expect(typeArguments, hasLength(2));
    expect(typeArguments[0], same(typeProvider.dynamicType));
    expect(typeArguments[1], same(typeProvider.dynamicType));
  }

  void test_mergePropagatedTypesAtJoinPoint_4() {
    // https://code.google.com/p/dart/issues/detail?id=19929
    _assertTypeOfMarkedExpression(r'''
f5(x) {
  var y = [];
  if (x) {
    y = 0;
  } else {
    return y;
  }
  // Propagated type is [int] here: correct.
  return y; // marker
}''', null, typeProvider.intType);
  }

  void test_mergePropagatedTypesAtJoinPoint_6() {
    // https://code.google.com/p/dart/issues/detail?id=19929
    //
    // Labeled [break]s are unsafe for the purposes of
    // [isAbruptTerminationStatement].
    //
    // This is tricky: the [break] jumps back above the [if], making
    // it into a loop of sorts. The [if] type-propagation code assumes
    // that [break] does not introduce a loop.
    enableUnionTypes(false);
    String code = r'''
f() {
  var x = 0;
  var c = false;
  L: 
  if (c) {
  } else {
    x = '';
    c = true;
    break L;
  }
  x; // marker
}''';
    DartType t = _findMarkedIdentifier(code, "; // marker").propagatedType;
    expect(typeProvider.intType.isSubtypeOf(t), isTrue);
    expect(typeProvider.stringType.isSubtypeOf(t), isTrue);
  }

  void test_objectMethodOnDynamicExpression_doubleEquals() {
    // https://code.google.com/p/dart/issues/detail?id=20342
    //
    // This was not actually part of Issue 20342, since the spec specifies a
    // static type of [bool] for [==] comparison and the implementation
    // was already consistent with the spec there. But, it's another
    // [Object] method, so it's included here.
    _assertTypeOfMarkedExpression(r'''
f1(x) {
  var v = (x == x);
  return v; // marker
}''', null, typeProvider.boolType);
  }

  void test_objectMethodOnDynamicExpression_hashCode() {
    // https://code.google.com/p/dart/issues/detail?id=20342
    _assertTypeOfMarkedExpression(r'''
f1(x) {
  var v = x.hashCode;
  return v; // marker
}''', null, typeProvider.intType);
  }

  void test_objectMethodOnDynamicExpression_runtimeType() {
    // https://code.google.com/p/dart/issues/detail?id=20342
    _assertTypeOfMarkedExpression(r'''
f1(x) {
  var v = x.runtimeType;
  return v; // marker
}''', null, typeProvider.typeType);
  }

  void test_objectMethodOnDynamicExpression_toString() {
    // https://code.google.com/p/dart/issues/detail?id=20342
    _assertTypeOfMarkedExpression(r'''
f1(x) {
  var v = x.toString();
  return v; // marker
}''', null, typeProvider.stringType);
  }

  void test_propagatedReturnType_function_hasReturnType_returnsNull() {
    String code = r'''
String f() => null;
main() {
  var v = f();
}''';
    _assertPropagatedReturnType(
        code,
        typeProvider.dynamicType,
        typeProvider.stringType);
  }

  void test_propagatedReturnType_function_lessSpecificStaticReturnType() {
    String code = r'''
Object f() => 42;
main() {
  var v = f();
}''';
    _assertPropagatedReturnType(
        code,
        typeProvider.dynamicType,
        typeProvider.intType);
  }

  void test_propagatedReturnType_function_moreSpecificStaticReturnType() {
    String code = r'''
int f(v) => (v as num);
main() {
  var v = f(3);
}''';
    _assertPropagatedReturnType(
        code,
        typeProvider.dynamicType,
        typeProvider.intType);
  }

  void
      test_propagatedReturnType_function_noReturnTypeName_blockBody_multipleReturns() {
    String code = r'''
f() {
  if (true) return 0;
  return 1.0;
}
main() {
  var v = f();
}''';
    _assertPropagatedReturnType(
        code,
        typeProvider.dynamicType,
        typeProvider.numType);
  }

  void
      test_propagatedReturnType_function_noReturnTypeName_blockBody_oneReturn() {
    String code = r'''
f() {
  var z = 42;
  return z;
}
main() {
  var v = f();
}''';
    _assertPropagatedReturnType(
        code,
        typeProvider.dynamicType,
        typeProvider.intType);
  }

  void test_propagatedReturnType_function_noReturnTypeName_expressionBody() {
    String code = r'''
f() => 42;
main() {
  var v = f();
}''';
    _assertPropagatedReturnType(
        code,
        typeProvider.dynamicType,
        typeProvider.intType);
  }

  void test_propagatedReturnType_localFunction() {
    String code = r'''
main() {
  f() => 42;
  var v = f();
}''';
    _assertPropagatedReturnType(
        code,
        typeProvider.dynamicType,
        typeProvider.intType);
  }

  void test_query() {
    Source source = addSource(r'''
import 'dart:html';

main() {
  var v1 = query('a');
  var v2 = query('A');
  var v3 = query('body:active');
  var v4 = query('button[foo="bar"]');
  var v5 = query('div.class');
  var v6 = query('input#id');
  var v7 = query('select#id');
  // invocation of method
  var m1 = document.query('div');
 // unsupported currently
  var b1 = query('noSuchTag');
  var b2 = query('DART_EDITOR_NO_SUCH_TYPE');
  var b3 = query('body div');
  return [v1, v2, v3, v4, v5, v6, v7, m1, b1, b2, b3];
}''');
    LibraryElement library = resolve(source);
    assertNoErrors(source);
    verify([source]);
    CompilationUnit unit = resolveCompilationUnit(source, library);
    FunctionDeclaration main = unit.declarations[0] as FunctionDeclaration;
    BlockFunctionBody body = main.functionExpression.body as BlockFunctionBody;
    ReturnStatement statement = body.block.statements[11] as ReturnStatement;
    NodeList<Expression> elements =
        (statement.expression as ListLiteral).elements;
    expect(elements[0].propagatedType.name, "AnchorElement");
    expect(elements[1].propagatedType.name, "AnchorElement");
    expect(elements[2].propagatedType.name, "BodyElement");
    expect(elements[3].propagatedType.name, "ButtonElement");
    expect(elements[4].propagatedType.name, "DivElement");
    expect(elements[5].propagatedType.name, "InputElement");
    expect(elements[6].propagatedType.name, "SelectElement");
    expect(elements[7].propagatedType.name, "DivElement");
    expect(elements[8].propagatedType.name, "Element");
    expect(elements[9].propagatedType.name, "Element");
    expect(elements[10].propagatedType.name, "Element");
  }

  /**
   * @param code the code that assigns the value to the variable "v", no matter how. We check that
   *          "v" has expected static and propagated type.
   */
  void _assertPropagatedReturnType(String code, DartType expectedStaticType,
      DartType expectedPropagatedType) {
    SimpleIdentifier identifier = _findMarkedIdentifier(code, "v = ");
    expect(identifier.staticType, same(expectedStaticType));
    expect(identifier.propagatedType, same(expectedPropagatedType));
  }

  /**
   * Check the static and propagated types of the expression marked with "; // marker" comment.
   *
   * @param code source code to analyze, with the expression to check marked with "// marker".
   * @param expectedStaticType if non-null, check actual static type is equal to this.
   * @param expectedPropagatedType if non-null, check actual static type is equal to this.
   * @throws Exception
   */
  void _assertTypeOfMarkedExpression(String code, DartType expectedStaticType,
      DartType expectedPropagatedType) {
    SimpleIdentifier identifier = _findMarkedIdentifier(code, "; // marker");
    if (expectedStaticType != null) {
      expect(identifier.staticType, expectedStaticType);
    }
    if (expectedPropagatedType != null) {
      expect(identifier.propagatedType, expectedPropagatedType);
    }
  }

  /**
   * Return the `SimpleIdentifier` marked by `marker`. The source code must have no
   * errors and be verifiable.
   *
   * @param code source code to analyze.
   * @param marker marker identifying sought after expression in source code.
   * @return expression marked by the marker.
   * @throws Exception
   */
  SimpleIdentifier _findMarkedIdentifier(String code, String marker) {
    try {
      Source source = addSource(code);
      LibraryElement library = resolve(source);
      assertNoErrors(source);
      verify([source]);
      CompilationUnit unit = resolveCompilationUnit(source, library);
      // Could generalize this further by making [SimpleIdentifier.class] a
      // parameter.
      return EngineTestCase.findNode(
          unit,
          code,
          marker,
          (node) => node is SimpleIdentifier);
    } catch (exception) {
      // Is there a better exception to throw here? The point is that an
      // assertion failure here should be a failure, in both "test_*" and
      // "fail_*" tests. However, an assertion failure is success for the
      // purpose of "fail_*" tests, so without catching them here "fail_*" tests
      // can succeed by failing for the wrong reason.
      throw new JavaException("Unexexpected assertion failure: $exception");
    }
  }
}


class TypeProviderImplTest extends EngineTestCase {
  void test_creation() {
    //
    // Create a mock library element with the types expected to be in dart:core.
    // We cannot use either ElementFactory or TestTypeProvider (which uses
    // ElementFactory) because we side-effect the elements in ways that would
    // break other tests.
    //
    InterfaceType objectType = _classElement("Object", null).type;
    InterfaceType boolType = _classElement("bool", objectType).type;
    InterfaceType numType = _classElement("num", objectType).type;
    InterfaceType doubleType = _classElement("double", numType).type;
    InterfaceType functionType = _classElement("Function", objectType).type;
    InterfaceType intType = _classElement("int", numType).type;
    InterfaceType listType = _classElement("List", objectType, ["E"]).type;
    InterfaceType mapType = _classElement("Map", objectType, ["K", "V"]).type;
    InterfaceType stackTraceType = _classElement("StackTrace", objectType).type;
    InterfaceType stringType = _classElement("String", objectType).type;
    InterfaceType symbolType = _classElement("Symbol", objectType).type;
    InterfaceType typeType = _classElement("Type", objectType).type;
    CompilationUnitElementImpl coreUnit =
        new CompilationUnitElementImpl("core.dart");
    coreUnit.types = <ClassElement>[
        boolType.element,
        doubleType.element,
        functionType.element,
        intType.element,
        listType.element,
        mapType.element,
        objectType.element,
        stackTraceType.element,
        stringType.element,
        symbolType.element,
        typeType.element];
    LibraryElementImpl coreLibrary = new LibraryElementImpl.forNode(
        new AnalysisContextImpl(),
        AstFactory.libraryIdentifier2(["dart.core"]));
    coreLibrary.definingCompilationUnit = coreUnit;
    //
    // Create a type provider and ensure that it can return the expected types.
    //
    TypeProviderImpl provider = new TypeProviderImpl(coreLibrary);
    expect(provider.boolType, same(boolType));
    expect(provider.bottomType, isNotNull);
    expect(provider.doubleType, same(doubleType));
    expect(provider.dynamicType, isNotNull);
    expect(provider.functionType, same(functionType));
    expect(provider.intType, same(intType));
    expect(provider.listType, same(listType));
    expect(provider.mapType, same(mapType));
    expect(provider.objectType, same(objectType));
    expect(provider.stackTraceType, same(stackTraceType));
    expect(provider.stringType, same(stringType));
    expect(provider.symbolType, same(symbolType));
    expect(provider.typeType, same(typeType));
  }

  ClassElement _classElement(String typeName, InterfaceType superclassType,
      [List<String> parameterNames]) {
    ClassElementImpl element =
        new ClassElementImpl.forNode(AstFactory.identifier3(typeName));
    element.supertype = superclassType;
    InterfaceTypeImpl type = new InterfaceTypeImpl.con1(element);
    element.type = type;
    if (parameterNames != null) {
      int count = parameterNames.length;
      if (count > 0) {
        List<TypeParameterElementImpl> typeParameters =
            new List<TypeParameterElementImpl>(count);
        List<TypeParameterTypeImpl> typeArguments =
            new List<TypeParameterTypeImpl>(count);
        for (int i = 0; i < count; i++) {
          TypeParameterElementImpl typeParameter =
              new TypeParameterElementImpl.forNode(AstFactory.identifier3(parameterNames[i]));
          typeParameters[i] = typeParameter;
          typeArguments[i] = new TypeParameterTypeImpl(typeParameter);
          typeParameter.type = typeArguments[i];
        }
        element.typeParameters = typeParameters;
        type.typeArguments = typeArguments;
      }
    }
    return element;
  }
}

class TypeResolverVisitorTest extends EngineTestCase {
  /**
   * The error listener to which errors will be reported.
   */
  GatheringErrorListener _listener;

  /**
   * The object representing the information about the library in which the types are being
   * resolved.
   */
  Library _library;

  /**
   * The type provider used to access the types.
   */
  TestTypeProvider _typeProvider;

  /**
   * The visitor used to resolve types needed to form the type hierarchy.
   */
  TypeResolverVisitor _visitor;

  /**
   * The visitor used to resolve types needed to form the type hierarchy.
   */
  ImplicitConstructorBuilder _implicitConstructorBuilder;

  void fail_visitConstructorDeclaration() {
    fail("Not yet tested");
    _listener.assertNoErrors();
  }

  void fail_visitFunctionDeclaration() {
    fail("Not yet tested");
    _listener.assertNoErrors();
  }

  void fail_visitFunctionTypeAlias() {
    fail("Not yet tested");
    _listener.assertNoErrors();
  }

  void fail_visitFunctionTypedFormalParameter() {
    fail("Not yet tested");
    _listener.assertNoErrors();
  }

  void fail_visitMethodDeclaration() {
    fail("Not yet tested");
    _listener.assertNoErrors();
  }

  void fail_visitVariableDeclaration() {
    fail("Not yet tested");
    ClassElement type = ElementFactory.classElement2("A");
    VariableDeclaration node = AstFactory.variableDeclaration("a");
    AstFactory.variableDeclarationList(null, AstFactory.typeName(type), [node]);
    //resolve(node);
    expect(node.name.staticType, same(type.type));
    _listener.assertNoErrors();
  }

  @override
  void setUp() {
    _listener = new GatheringErrorListener();
    SourceFactory factory = new SourceFactory([new FileUriResolver()]);
    AnalysisContextImpl context = new AnalysisContextImpl();
    context.sourceFactory = factory;
    Source librarySource =
        new FileBasedSource.con1(FileUtilities2.createFile("/lib.dart"));
    _library = new Library(context, _listener, librarySource);
    LibraryElementImpl element = new LibraryElementImpl.forNode(
        context,
        AstFactory.libraryIdentifier2(["lib"]));
    element.definingCompilationUnit =
        new CompilationUnitElementImpl("lib.dart");
    _library.libraryElement = element;
    _typeProvider = new TestTypeProvider();
    _visitor =
        new TypeResolverVisitor.con1(_library, librarySource, _typeProvider);
    _implicitConstructorBuilder = new ImplicitConstructorBuilder(
        librarySource,
        _library.libraryElement,
        _library.libraryScope,
        _typeProvider,
        (ClassElement classElement, ClassElement superclassElement, void computation())
            {
      // For these tests, we assume the classes for which implicit
      // constructors need to be built are visited in proper dependency order,
      // so we just invoke the computation immediately.
      computation();
    });
  }

  void test_visitCatchClause_exception() {
    // catch (e)
    CatchClause clause = AstFactory.catchClause("e");
    SimpleIdentifier exceptionParameter = clause.exceptionParameter;
    exceptionParameter.staticElement =
        new LocalVariableElementImpl.forNode(exceptionParameter);
    _resolveCatchClause(clause, _typeProvider.dynamicType, null);
    _listener.assertNoErrors();
  }

  void test_visitCatchClause_exception_stackTrace() {
    // catch (e, s)
    CatchClause clause = AstFactory.catchClause2("e", "s");
    SimpleIdentifier exceptionParameter = clause.exceptionParameter;
    exceptionParameter.staticElement =
        new LocalVariableElementImpl.forNode(exceptionParameter);
    SimpleIdentifier stackTraceParameter = clause.stackTraceParameter;
    stackTraceParameter.staticElement =
        new LocalVariableElementImpl.forNode(stackTraceParameter);
    _resolveCatchClause(
        clause,
        _typeProvider.dynamicType,
        _typeProvider.stackTraceType);
    _listener.assertNoErrors();
  }

  void test_visitCatchClause_on_exception() {
    // on E catch (e)
    ClassElement exceptionElement = ElementFactory.classElement2("E");
    TypeName exceptionType = AstFactory.typeName(exceptionElement);
    CatchClause clause = AstFactory.catchClause4(exceptionType, "e");
    SimpleIdentifier exceptionParameter = clause.exceptionParameter;
    exceptionParameter.staticElement =
        new LocalVariableElementImpl.forNode(exceptionParameter);
    _resolveCatchClause(
        clause,
        exceptionElement.type,
        null,
        [exceptionElement]);
    _listener.assertNoErrors();
  }

  void test_visitCatchClause_on_exception_stackTrace() {
    // on E catch (e, s)
    ClassElement exceptionElement = ElementFactory.classElement2("E");
    TypeName exceptionType = AstFactory.typeName(exceptionElement);
    (exceptionType.name as SimpleIdentifier).staticElement = exceptionElement;
    CatchClause clause = AstFactory.catchClause5(exceptionType, "e", "s");
    SimpleIdentifier exceptionParameter = clause.exceptionParameter;
    exceptionParameter.staticElement =
        new LocalVariableElementImpl.forNode(exceptionParameter);
    SimpleIdentifier stackTraceParameter = clause.stackTraceParameter;
    stackTraceParameter.staticElement =
        new LocalVariableElementImpl.forNode(stackTraceParameter);
    _resolveCatchClause(
        clause,
        exceptionElement.type,
        _typeProvider.stackTraceType,
        [exceptionElement]);
    _listener.assertNoErrors();
  }

  void test_visitClassDeclaration() {
    // class A extends B with C implements D {}
    // class B {}
    // class C {}
    // class D {}
    ClassElement elementA = ElementFactory.classElement2("A");
    ClassElement elementB = ElementFactory.classElement2("B");
    ClassElement elementC = ElementFactory.classElement2("C");
    ClassElement elementD = ElementFactory.classElement2("D");
    ExtendsClause extendsClause =
        AstFactory.extendsClause(AstFactory.typeName(elementB));
    WithClause withClause =
        AstFactory.withClause([AstFactory.typeName(elementC)]);
    ImplementsClause implementsClause =
        AstFactory.implementsClause([AstFactory.typeName(elementD)]);
    ClassDeclaration declaration = AstFactory.classDeclaration(
        null,
        "A",
        null,
        extendsClause,
        withClause,
        implementsClause);
    declaration.name.staticElement = elementA;
    _resolveNode(declaration, [elementA, elementB, elementC, elementD]);
    expect(elementA.supertype, same(elementB.type));
    List<InterfaceType> mixins = elementA.mixins;
    expect(mixins, hasLength(1));
    expect(mixins[0], same(elementC.type));
    List<InterfaceType> interfaces = elementA.interfaces;
    expect(interfaces, hasLength(1));
    expect(interfaces[0], same(elementD.type));
    _listener.assertNoErrors();
  }

  void test_visitClassDeclaration_instanceMemberCollidesWithClass() {
    // class A {}
    // class B extends A {
    //   void A() {}
    // }
    ClassElementImpl elementA = ElementFactory.classElement2("A");
    ClassElementImpl elementB = ElementFactory.classElement2("B");
    elementB.methods =
        <MethodElement>[ElementFactory.methodElement("A", VoidTypeImpl.instance)];
    ExtendsClause extendsClause =
        AstFactory.extendsClause(AstFactory.typeName(elementA));
    ClassDeclaration declaration =
        AstFactory.classDeclaration(null, "B", null, extendsClause, null, null);
    declaration.name.staticElement = elementB;
    _resolveNode(declaration, [elementA, elementB]);
    expect(elementB.supertype, same(elementA.type));
    _listener.assertNoErrors();
  }

  void test_visitClassTypeAlias() {
    // class A = B with C implements D;
    ClassElement elementA = ElementFactory.classElement2("A");
    ClassElement elementB = ElementFactory.classElement2("B");
    ClassElement elementC = ElementFactory.classElement2("C");
    ClassElement elementD = ElementFactory.classElement2("D");
    WithClause withClause =
        AstFactory.withClause([AstFactory.typeName(elementC)]);
    ImplementsClause implementsClause =
        AstFactory.implementsClause([AstFactory.typeName(elementD)]);
    ClassTypeAlias alias = AstFactory.classTypeAlias(
        "A",
        null,
        null,
        AstFactory.typeName(elementB),
        withClause,
        implementsClause);
    alias.name.staticElement = elementA;
    _resolveNode(alias, [elementA, elementB, elementC, elementD]);
    expect(elementA.supertype, same(elementB.type));
    List<InterfaceType> mixins = elementA.mixins;
    expect(mixins, hasLength(1));
    expect(mixins[0], same(elementC.type));
    List<InterfaceType> interfaces = elementA.interfaces;
    expect(interfaces, hasLength(1));
    expect(interfaces[0], same(elementD.type));
    _listener.assertNoErrors();
  }

  void test_visitClassTypeAlias_constructorWithOptionalParams_ignored() {
    // class T {}
    // class B {
    //   B.c1();
    //   B.c2([T a0]);
    //   B.c3({T a0});
    // }
    // class M {}
    // class C = B with M
    ClassElement classT = ElementFactory.classElement2('T', []);
    ClassElementImpl classB = ElementFactory.classElement2('B', []);
    ConstructorElementImpl constructorBc1 =
        ElementFactory.constructorElement2(classB, 'c1', []);
    ConstructorElementImpl constructorBc2 =
        ElementFactory.constructorElement2(classB, 'c2', [classT.type]);
    (constructorBc2.parameters[0] as ParameterElementImpl).parameterKind =
        ParameterKind.POSITIONAL;
    ConstructorElementImpl constructorBc3 =
        ElementFactory.constructorElement2(classB, 'c3', [classT.type]);
    (constructorBc3.parameters[0] as ParameterElementImpl).parameterKind =
        ParameterKind.NAMED;
    classB.constructors = [constructorBc1, constructorBc2, constructorBc3];
    ClassElement classM = ElementFactory.classElement2('M', []);
    WithClause withClause =
        AstFactory.withClause([AstFactory.typeName(classM, [])]);
    ClassElement classC = ElementFactory.classElement2('C', []);
    ClassTypeAlias alias = AstFactory.classTypeAlias(
        'C',
        null,
        null,
        AstFactory.typeName(classB, []),
        withClause,
        null);
    alias.name.staticElement = classC;
    _resolveNode(alias, [classT, classB, classM, classC]);
    expect(classC.constructors, hasLength(1));
    ConstructorElement constructor = classC.constructors[0];
    expect(constructor.isFactory, isFalse);
    expect(constructor.isSynthetic, isTrue);
    expect(constructor.name, 'c1');
    expect(constructor.functions, hasLength(0));
    expect(constructor.labels, hasLength(0));
    expect(constructor.localVariables, hasLength(0));
    expect(constructor.parameters, isEmpty);
  }

  void test_visitClassTypeAlias_constructorWithParams() {
    // class T {}
    // class B {
    //   B(T a0);
    // }
    // class M {}
    // class C = B with M
    ClassElement classT = ElementFactory.classElement2('T', []);
    ClassElementImpl classB = ElementFactory.classElement2('B', []);
    ConstructorElementImpl constructorB =
        ElementFactory.constructorElement2(classB, '', [classT.type]);
    classB.constructors = [constructorB];
    ClassElement classM = ElementFactory.classElement2('M', []);
    WithClause withClause =
        AstFactory.withClause([AstFactory.typeName(classM, [])]);
    ClassElement classC = ElementFactory.classElement2('C', []);
    ClassTypeAlias alias = AstFactory.classTypeAlias(
        'C',
        null,
        null,
        AstFactory.typeName(classB, []),
        withClause,
        null);
    alias.name.staticElement = classC;
    _resolveNode(alias, [classT, classB, classM, classC]);
    expect(classC.constructors, hasLength(1));
    ConstructorElement constructor = classC.constructors[0];
    expect(constructor.isFactory, isFalse);
    expect(constructor.isSynthetic, isTrue);
    expect(constructor.name, '');
    expect(constructor.functions, hasLength(0));
    expect(constructor.labels, hasLength(0));
    expect(constructor.localVariables, hasLength(0));
    expect(constructor.parameters, hasLength(1));
    expect(constructor.parameters[0].type, equals(classT.type));
    expect(
        constructor.parameters[0].name,
        equals(constructorB.parameters[0].name));
  }

  void test_visitClassTypeAlias_defaultConstructor() {
    // class B {}
    // class M {}
    // class C = B with M
    ClassElementImpl classB = ElementFactory.classElement2('B', []);
    ConstructorElementImpl constructorB =
        ElementFactory.constructorElement2(classB, '', []);
    constructorB.setModifier(Modifier.SYNTHETIC, true);
    classB.constructors = [constructorB];
    ClassElement classM = ElementFactory.classElement2('M', []);
    WithClause withClause =
        AstFactory.withClause([AstFactory.typeName(classM, [])]);
    ClassElement classC = ElementFactory.classElement2('C', []);
    ClassTypeAlias alias = AstFactory.classTypeAlias(
        'C',
        null,
        null,
        AstFactory.typeName(classB, []),
        withClause,
        null);
    alias.name.staticElement = classC;
    _resolveNode(alias, [classB, classM, classC]);
    expect(classC.constructors, hasLength(1));
    ConstructorElement constructor = classC.constructors[0];
    expect(constructor.isFactory, isFalse);
    expect(constructor.isSynthetic, isTrue);
    expect(constructor.name, '');
    expect(constructor.functions, hasLength(0));
    expect(constructor.labels, hasLength(0));
    expect(constructor.localVariables, hasLength(0));
    expect(constructor.parameters, isEmpty);
  }

  void test_visitFieldFormalParameter_functionType() {
    InterfaceType intType = _typeProvider.intType;
    TypeName intTypeName = AstFactory.typeName4("int");
    String innerParameterName = "a";
    SimpleFormalParameter parameter =
        AstFactory.simpleFormalParameter3(innerParameterName);
    parameter.identifier.staticElement =
        ElementFactory.requiredParameter(innerParameterName);
    String outerParameterName = "p";
    FormalParameter node = AstFactory.fieldFormalParameter(
        null,
        intTypeName,
        outerParameterName,
        AstFactory.formalParameterList([parameter]));
    node.identifier.staticElement =
        ElementFactory.requiredParameter(outerParameterName);
    DartType parameterType = _resolveFormalParameter(node, [intType.element]);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is FunctionType,
        FunctionType,
        parameterType);
    FunctionType functionType = parameterType as FunctionType;
    expect(functionType.returnType, same(intType));
    expect(functionType.parameters, hasLength(1));
    _listener.assertNoErrors();
  }

  void test_visitFieldFormalParameter_noType() {
    String parameterName = "p";
    FormalParameter node =
        AstFactory.fieldFormalParameter(Keyword.VAR, null, parameterName);
    node.identifier.staticElement =
        ElementFactory.requiredParameter(parameterName);
    expect(_resolveFormalParameter(node), same(_typeProvider.dynamicType));
    _listener.assertNoErrors();
  }

  void test_visitFieldFormalParameter_type() {
    InterfaceType intType = _typeProvider.intType;
    TypeName intTypeName = AstFactory.typeName4("int");
    String parameterName = "p";
    FormalParameter node =
        AstFactory.fieldFormalParameter(null, intTypeName, parameterName);
    node.identifier.staticElement =
        ElementFactory.requiredParameter(parameterName);
    expect(_resolveFormalParameter(node, [intType.element]), same(intType));
    _listener.assertNoErrors();
  }

  void test_visitSimpleFormalParameter_noType() {
    // p
    FormalParameter node = AstFactory.simpleFormalParameter3("p");
    node.identifier.staticElement =
        new ParameterElementImpl.forNode(AstFactory.identifier3("p"));
    expect(_resolveFormalParameter(node), same(_typeProvider.dynamicType));
    _listener.assertNoErrors();
  }

  void test_visitSimpleFormalParameter_type() {
    // int p
    InterfaceType intType = _typeProvider.intType;
    ClassElement intElement = intType.element;
    FormalParameter node =
        AstFactory.simpleFormalParameter4(AstFactory.typeName(intElement), "p");
    SimpleIdentifier identifier = node.identifier;
    ParameterElementImpl element = new ParameterElementImpl.forNode(identifier);
    identifier.staticElement = element;
    expect(_resolveFormalParameter(node, [intElement]), same(intType));
    _listener.assertNoErrors();
  }

  void test_visitTypeName_noParameters_noArguments() {
    ClassElement classA = ElementFactory.classElement2("A");
    TypeName typeName = AstFactory.typeName(classA);
    typeName.type = null;
    _resolveNode(typeName, [classA]);
    expect(typeName.type, same(classA.type));
    _listener.assertNoErrors();
  }

  void test_visitTypeName_parameters_arguments() {
    ClassElement classA = ElementFactory.classElement2("A", ["E"]);
    ClassElement classB = ElementFactory.classElement2("B");
    TypeName typeName =
        AstFactory.typeName(classA, [AstFactory.typeName(classB)]);
    typeName.type = null;
    _resolveNode(typeName, [classA, classB]);
    InterfaceType resultType = typeName.type as InterfaceType;
    expect(resultType.element, same(classA));
    List<DartType> resultArguments = resultType.typeArguments;
    expect(resultArguments, hasLength(1));
    expect(resultArguments[0], same(classB.type));
    _listener.assertNoErrors();
  }

  void test_visitTypeName_parameters_noArguments() {
    ClassElement classA = ElementFactory.classElement2("A", ["E"]);
    TypeName typeName = AstFactory.typeName(classA);
    typeName.type = null;
    _resolveNode(typeName, [classA]);
    InterfaceType resultType = typeName.type as InterfaceType;
    expect(resultType.element, same(classA));
    List<DartType> resultArguments = resultType.typeArguments;
    expect(resultArguments, hasLength(1));
    expect(resultArguments[0], same(DynamicTypeImpl.instance));
    _listener.assertNoErrors();
  }

  void test_visitTypeName_void() {
    ClassElement classA = ElementFactory.classElement2("A");
    TypeName typeName = AstFactory.typeName4("void");
    _resolveNode(typeName, [classA]);
    expect(typeName.type, same(VoidTypeImpl.instance));
    _listener.assertNoErrors();
  }

  /**
   * Analyze the given catch clause and assert that the types of the parameters have been set to the
   * given types. The types can be null if the catch clause does not have the corresponding
   * parameter.
   *
   * @param node the catch clause to be analyzed
   * @param exceptionType the expected type of the exception parameter
   * @param stackTraceType the expected type of the stack trace parameter
   * @param definedElements the elements that are to be defined in the scope in which the element is
   *          being resolved
   */
  void _resolveCatchClause(CatchClause node, DartType exceptionType,
      InterfaceType stackTraceType, [List<Element> definedElements]) {
    _resolveNode(node, definedElements);
    SimpleIdentifier exceptionParameter = node.exceptionParameter;
    if (exceptionParameter != null) {
      expect(exceptionParameter.staticType, same(exceptionType));
    }
    SimpleIdentifier stackTraceParameter = node.stackTraceParameter;
    if (stackTraceParameter != null) {
      expect(stackTraceParameter.staticType, same(stackTraceType));
    }
  }

  /**
   * Return the type associated with the given parameter after the static type analyzer has computed
   * a type for it.
   *
   * @param node the parameter with which the type is associated
   * @param definedElements the elements that are to be defined in the scope in which the element is
   *          being resolved
   * @return the type associated with the parameter
   */
  DartType _resolveFormalParameter(FormalParameter node,
      [List<Element> definedElements]) {
    _resolveNode(node, definedElements);
    return (node.identifier.staticElement as ParameterElement).type;
  }

  /**
   * Return the element associated with the given identifier after the resolver has resolved the
   * identifier.
   *
   * @param node the expression to be resolved
   * @param definedElements the elements that are to be defined in the scope in which the element is
   *          being resolved
   * @return the element to which the expression was resolved
   */
  void _resolveNode(AstNode node, [List<Element> definedElements]) {
    if (definedElements != null) {
      for (Element element in definedElements) {
        _library.libraryScope.define(element);
      }
    }
    node.accept(_visitor);
    node.accept(_implicitConstructorBuilder);
  }
}

class _AnalysisContextFactory_initContextWithCore extends DirectoryBasedDartSdk
    {

  _AnalysisContextFactory_initContextWithCore(JavaFile arg0)
      : super(arg0);

  @override
  LibraryMap initialLibraryMap(bool useDart2jsPaths) {
    LibraryMap map = new LibraryMap();
    _addLibrary(map, DartSdk.DART_ASYNC, false, "async.dart");
    _addLibrary(map, DartSdk.DART_CORE, false, "core.dart");
    _addLibrary(map, DartSdk.DART_HTML, false, "html_dartium.dart");
    _addLibrary(map, AnalysisContextFactory._DART_MATH, false, "math.dart");
    _addLibrary(
        map,
        AnalysisContextFactory._DART_INTERCEPTORS,
        true,
        "_interceptors.dart");
    _addLibrary(
        map,
        AnalysisContextFactory._DART_JS_HELPER,
        true,
        "_js_helper.dart");
    return map;
  }

  void _addLibrary(LibraryMap map, String uri, bool isInternal, String path) {
    SdkLibraryImpl library = new SdkLibraryImpl(uri);
    if (isInternal) {
      library.category = "Internal";
    }
    library.path = path;
    map.setLibrary(uri, library);
  }
}

class _SimpleResolverTest_localVariable_types_invoked extends
    RecursiveAstVisitor<Object> {
  final SimpleResolverTest test;

  List<bool> found;

  List<CaughtException> thrownException;

  _SimpleResolverTest_localVariable_types_invoked(this.test, this.found,
      this.thrownException)
      : super();

  @override
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name == "myVar" && node.parent is MethodInvocation) {
      try {
        found[0] = true;
        // check static type
        DartType staticType = node.staticType;
        expect(staticType, same(test.typeProvider.dynamicType));
        // check propagated type
        FunctionType propagatedType = node.propagatedType as FunctionType;
        expect(propagatedType.returnType, test.typeProvider.stringType);
      } on AnalysisException catch (e, stackTrace) {
        thrownException[0] = new CaughtException(e, stackTrace);
      }
    }
    return null;
  }
}
