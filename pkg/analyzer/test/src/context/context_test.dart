// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.src.context.context_test;

import 'dart:async';
import 'dart:collection';

import 'package:analyzer/src/cancelable_future.dart';
import 'package:analyzer/src/context/cache.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart'
    show
        AnalysisContext,
        AnalysisContextStatistics,
        AnalysisDelta,
        AnalysisEngine,
        AnalysisErrorInfo,
        AnalysisLevel,
        AnalysisNotScheduledError,
        AnalysisOptions,
        AnalysisOptionsImpl,
        AnalysisResult,
        ChangeNotice,
        ChangeSet,
        IncrementalAnalysisCache,
        TimestampedData;
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/html.dart' as ht;
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/java_engine_io.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/sdk_io.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/testing/ast_factory.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:analyzer/src/generated/testing/test_type_provider.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/plugin/engine_plugin.dart';
import 'package:plugin/manager.dart';
import 'package:unittest/unittest.dart';
import 'package:watcher/src/utils.dart';

import '../../generated/engine_test.dart';
import '../../generated/test_support.dart';
import '../../reflective_tests.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(AnalysisContextImplTest);
}

contextWithCore() {
  return new AnalysisContextForTests();
}

/**
 * An analysis context that has a fake SDK that is much smaller and faster for
 * testing purposes.
 */
class AnalysisContextForTests extends AnalysisContextImpl {
  AnalysisContextForTests() {
    initWithCore();
  }

  @override
  void set analysisOptions(AnalysisOptions options) {
    AnalysisOptions currentOptions = analysisOptions;
    bool needsRecompute = currentOptions.analyzeFunctionBodiesPredicate !=
            options.analyzeFunctionBodiesPredicate ||
        currentOptions.generateImplicitErrors !=
            options.generateImplicitErrors ||
        currentOptions.generateSdkErrors != options.generateSdkErrors ||
        currentOptions.dart2jsHint != options.dart2jsHint ||
        (currentOptions.hint && !options.hint) ||
        currentOptions.preserveComments != options.preserveComments ||
        currentOptions.enableNullAwareOperators !=
            options.enableNullAwareOperators ||
        currentOptions.enableStrictCallChecks != options.enableStrictCallChecks;
    if (needsRecompute) {
      fail(
          "Cannot set options that cause the sources to be reanalyzed in a test context");
    }
    super.analysisOptions = options;
  }

  @override
  LibraryResolverFactory get libraryResolverFactory => null;

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
   * Initialize the given analysis context with a fake core library already resolved.
   *
   * @param context the context to be initialized (not `null`)
   * @return the analysis context that was created
   */
  void initWithCore() {
    DirectoryBasedDartSdk sdk = new FakeSdk(new JavaFile("/fake/sdk"));
    SourceFactory sourceFactory =
        new SourceFactory([new DartUriResolver(sdk), new FileUriResolver()]);
    this.sourceFactory = sourceFactory;
    AnalysisContext coreContext = sdk.context;
    //
    // dart:core
    //
    TestTypeProvider provider = new TestTypeProvider();
    typeProvider = provider;
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
      provider.iterableType.element,
      provider.iteratorType.element,
      provider.listType.element,
      provider.mapType.element,
      provider.nullType.element,
      provider.numType.element,
      provider.objectType.element,
      proxyClassElement,
      provider.stackTraceType.element,
      provider.stringType.element,
      provider.symbolType.element,
      provider.typeType.element
    ];
    coreUnit.functions = <FunctionElement>[
      ElementFactory.functionElement3("identical", provider.boolType.element,
          <ClassElement>[
        provider.objectType.element,
        provider.objectType.element
      ], null),
      ElementFactory.functionElement3("print", VoidTypeImpl.instance.element,
          <ClassElement>[provider.objectType.element], null)
    ];
    TopLevelVariableElement proxyTopLevelVariableElt = ElementFactory
        .topLevelVariableElement3("proxy", true, false, proxyClassElement.type);
    TopLevelVariableElement deprecatedTopLevelVariableElt = ElementFactory
        .topLevelVariableElement3(
            "deprecated", true, false, provider.deprecatedType);
    coreUnit.accessors = <PropertyAccessorElement>[
      proxyTopLevelVariableElt.getter,
      deprecatedTopLevelVariableElt.getter
    ];
    coreUnit.topLevelVariables = <TopLevelVariableElement>[
      proxyTopLevelVariableElt,
      deprecatedTopLevelVariableElt
    ];
    LibraryElementImpl coreLibrary = new LibraryElementImpl.forNode(
        coreContext, AstFactory.libraryIdentifier2(["dart", "core"]));
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
      ElementFactory.positionalParameter2("value", provider.dynamicType)
    ];
    futureConstructor.factory = true;
    (futureConstructor.type as FunctionTypeImpl).typeArguments =
        futureElement.type.typeArguments;
    futureElement.constructors = <ConstructorElement>[futureConstructor];
    //   Future then(onValue(T value), { Function onError });
    List<ParameterElement> parameters = <ParameterElement>[
      ElementFactory.requiredParameter2(
          "value", futureElement.typeParameters[0].type)
    ];
    FunctionTypeAliasElementImpl aliasElement =
        new FunctionTypeAliasElementImpl.forNode(null);
    aliasElement.synthetic = true;
    aliasElement.parameters = parameters;
    aliasElement.returnType = provider.dynamicType;
    aliasElement.enclosingElement = asyncUnit;
    FunctionTypeImpl aliasType = new FunctionTypeImpl.con2(aliasElement);
    aliasElement.shareTypeParameters(futureElement.typeParameters);
    aliasType.typeArguments = futureElement.type.typeArguments;
    MethodElement thenMethod = ElementFactory.methodElementWithParameters(
        "then", futureElement.type.typeArguments, futureType, [
      ElementFactory.requiredParameter2("onValue", aliasType),
      ElementFactory.namedParameter2("onError", provider.functionType)
    ]);
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
      ElementFactory.classElement2("Stream", ["T"])
    ];
    LibraryElementImpl asyncLibrary = new LibraryElementImpl.forNode(
        coreContext, AstFactory.libraryIdentifier2(["dart", "async"]));
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
    ClassElementImpl context2dElement = ElementFactory.classElement(
        "CanvasRenderingContext2D", contextElementType);
    canvasElement.methods = <MethodElement>[
      ElementFactory.methodElement(
          "getContext", contextElementType, [provider.stringType])
    ];
    canvasElement.accessors = <PropertyAccessorElement>[
      ElementFactory.getterElement("context2D", false, context2dElement.type)
    ];
    canvasElement.fields = canvasElement.accessors
        .map((PropertyAccessorElement accessor) => accessor.variable)
        .toList();
    ClassElementImpl documentElement =
        ElementFactory.classElement("Document", elementType);
    ClassElementImpl htmlDocumentElement =
        ElementFactory.classElement("HtmlDocument", documentElement.type);
    htmlDocumentElement.methods = <MethodElement>[
      ElementFactory.methodElement(
          "query", elementType, <DartType>[provider.stringType])
    ];
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
      ElementFactory.classElement("SelectElement", elementType)
    ];
    htmlUnit.functions = <FunctionElement>[
      ElementFactory.functionElement3("query", elementElement,
          <ClassElement>[provider.stringType.element], ClassElement.EMPTY_LIST)
    ];
    TopLevelVariableElementImpl document = ElementFactory
        .topLevelVariableElement3(
            "document", false, true, htmlDocumentElement.type);
    htmlUnit.topLevelVariables = <TopLevelVariableElement>[document];
    htmlUnit.accessors = <PropertyAccessorElement>[document.getter];
    LibraryElementImpl htmlLibrary = new LibraryElementImpl.forNode(
        coreContext, AstFactory.libraryIdentifier2(["dart", "dom", "html"]));
    htmlLibrary.definingCompilationUnit = htmlUnit;
    //
    // dart:math
    //
    CompilationUnitElementImpl mathUnit =
        new CompilationUnitElementImpl("math.dart");
    Source mathSource = sourceFactory.forUri("dart:math");
    coreContext.setContents(mathSource, "");
    mathUnit.source = mathSource;
    FunctionElement cosElement = ElementFactory.functionElement3("cos",
        provider.doubleType.element, <ClassElement>[provider.numType.element],
        ClassElement.EMPTY_LIST);
    TopLevelVariableElement ln10Element = ElementFactory
        .topLevelVariableElement3("LN10", true, false, provider.doubleType);
    TopLevelVariableElement piElement = ElementFactory.topLevelVariableElement3(
        "PI", true, false, provider.doubleType);
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
    FunctionElement sinElement = ElementFactory.functionElement3("sin",
        provider.doubleType.element, <ClassElement>[provider.numType.element],
        ClassElement.EMPTY_LIST);
    FunctionElement sqrtElement = ElementFactory.functionElement3("sqrt",
        provider.doubleType.element, <ClassElement>[provider.numType.element],
        ClassElement.EMPTY_LIST);
    mathUnit.accessors = <PropertyAccessorElement>[
      ln10Element.getter,
      piElement.getter
    ];
    mathUnit.functions = <FunctionElement>[cosElement, sinElement, sqrtElement];
    mathUnit.topLevelVariables = <TopLevelVariableElement>[
      ln10Element,
      piElement
    ];
    mathUnit.types = <ClassElement>[randomElement];
    LibraryElementImpl mathLibrary = new LibraryElementImpl.forNode(
        coreContext, AstFactory.libraryIdentifier2(["dart", "math"]));
    mathLibrary.definingCompilationUnit = mathUnit;
    //
    // Set empty sources for the rest of the libraries.
    //
    Source source = sourceFactory.forUri("dart:_interceptors");
    coreContext.setContents(source, "");
    source = sourceFactory.forUri("dart:_js_helper");
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
    recordLibraryElements(elementMap);
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

@reflectiveTest
class AnalysisContextImplTest extends EngineTestCase {
  /**
   * An analysis context whose source factory is [sourceFactory].
   */
  AnalysisContextImpl _context;

  /**
   * The source factory associated with the analysis [context].
   */
  SourceFactory _sourceFactory;

  void fail_applyChanges_change_flush_element() {
    _context = contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source librarySource = _addSource("/lib.dart", r'''
library lib;
int a = 0;''');
    expect(_context.computeLibraryElement(librarySource), isNotNull);
    _context.setContents(librarySource, r'''
library lib;
int aa = 0;''');
    expect(_context.getLibraryElement(librarySource), isNull);
  }

  Future fail_applyChanges_change_multiple() {
    _context = contextWithCore();
    SourcesChangedListener listener = new SourcesChangedListener();
    _context.onSourcesChanged.listen(listener.onData);
    _sourceFactory = _context.sourceFactory;
    String libraryContents1 = r'''
library lib;
part 'part.dart';
int a = 0;''';
    Source librarySource = _addSource("/lib.dart", libraryContents1);
    String partContents1 = r'''
part of lib;
int b = a;''';
    Source partSource = _addSource("/part.dart", partContents1);
    _context.computeLibraryElement(librarySource);
    String libraryContents2 = r'''
library lib;
part 'part.dart';
int aa = 0;''';
    _context.setContents(librarySource, libraryContents2);
    String partContents2 = r'''
part of lib;
int b = aa;''';
    _context.setContents(partSource, partContents2);
    _context.computeLibraryElement(librarySource);
    CompilationUnit libraryUnit =
        _context.resolveCompilationUnit2(librarySource, librarySource);
    expect(libraryUnit, isNotNull);
    CompilationUnit partUnit =
        _context.resolveCompilationUnit2(partSource, librarySource);
    expect(partUnit, isNotNull);
    TopLevelVariableDeclaration declaration =
        libraryUnit.declarations[0] as TopLevelVariableDeclaration;
    Element declarationElement = declaration.variables.variables[0].element;
    TopLevelVariableDeclaration use =
        partUnit.declarations[0] as TopLevelVariableDeclaration;
    Element useElement = (use.variables.variables[
        0].initializer as SimpleIdentifier).staticElement;
    expect((useElement as PropertyAccessorElement).variable,
        same(declarationElement));
    return pumpEventQueue().then((_) {
      listener.assertEvent(wereSourcesAdded: true);
      listener.assertEvent(changedSources: [librarySource]);
      listener.assertEvent(wereSourcesAdded: true);
      listener.assertEvent(changedSources: [partSource]);
      listener.assertEvent(changedSources: [librarySource]);
      listener.assertEvent(changedSources: [partSource]);
      listener.assertNoMoreEvents();
    });
  }

  void fail_applyChanges_empty() {
    _context.applyChanges(new ChangeSet());
    expect(_context.performAnalysisTask().changeNotices, isNull);
    // This test appears to be flaky. If it is named "test_" it fails, if it's
    // named "fail_" it doesn't fail. I'm guessing that it's dependent on some
    // other test being run (or not).
    fail('Should have failed');
  }

  void fail_applyChanges_overriddenSource() {
    // Note: addSource adds the source to the contentCache.
    Source source = _addSource("/test.dart", "library test;");
    _context.computeErrors(source);
    while (!_context.sourcesNeedingProcessing.isEmpty) {
      _context.performAnalysisTask();
    }
    // Adding the source as a changedSource should have no effect since
    // it is already overridden in the content cache.
    ChangeSet changeSet = new ChangeSet();
    changeSet.changedSource(source);
    _context.applyChanges(changeSet);
    expect(_context.sourcesNeedingProcessing, hasLength(0));
  }

  Future fail_applyChanges_remove() {
    _context = contextWithCore();
    SourcesChangedListener listener = new SourcesChangedListener();
    _context.onSourcesChanged.listen(listener.onData);
    _sourceFactory = _context.sourceFactory;
    String libAContents = r'''
library libA;
import 'libB.dart';''';
    Source libA = _addSource("/libA.dart", libAContents);
    String libBContents = "library libB;";
    Source libB = _addSource("/libB.dart", libBContents);
    LibraryElement libAElement = _context.computeLibraryElement(libA);
    expect(libAElement, isNotNull);
    List<LibraryElement> importedLibraries = libAElement.importedLibraries;
    expect(importedLibraries, hasLength(2));
    _context.computeErrors(libA);
    _context.computeErrors(libB);
    expect(_context.sourcesNeedingProcessing, hasLength(0));
    _context.setContents(libB, null);
    _removeSource(libB);
    List<Source> sources = _context.sourcesNeedingProcessing;
    expect(sources, hasLength(1));
    expect(sources[0], same(libA));
    libAElement = _context.computeLibraryElement(libA);
    importedLibraries = libAElement.importedLibraries;
    expect(importedLibraries, hasLength(1));
    return pumpEventQueue().then((_) {
      listener.assertEvent(wereSourcesAdded: true);
      listener.assertEvent(changedSources: [libA]);
      listener.assertEvent(wereSourcesAdded: true);
      listener.assertEvent(changedSources: [libB]);
      listener.assertEvent(changedSources: [libB]);
      listener.assertEvent(wereSourcesRemovedOrDeleted: true);
      listener.assertNoMoreEvents();
    });
  }

  Future fail_applyChanges_removeContainer() {
    _context = contextWithCore();
    SourcesChangedListener listener = new SourcesChangedListener();
    _context.onSourcesChanged.listen(listener.onData);
    _sourceFactory = _context.sourceFactory;
    String libAContents = r'''
library libA;
import 'libB.dart';''';
    Source libA = _addSource("/libA.dart", libAContents);
    String libBContents = "library libB;";
    Source libB = _addSource("/libB.dart", libBContents);
    _context.computeLibraryElement(libA);
    _context.computeErrors(libA);
    _context.computeErrors(libB);
    expect(_context.sourcesNeedingProcessing, hasLength(0));
    ChangeSet changeSet = new ChangeSet();
    SourceContainer removedContainer =
        new _AnalysisContextImplTest_test_applyChanges_removeContainer(libB);
    changeSet.removedContainer(removedContainer);
    _context.applyChanges(changeSet);
    List<Source> sources = _context.sourcesNeedingProcessing;
    expect(sources, hasLength(1));
    expect(sources[0], same(libA));
    return pumpEventQueue().then((_) {
      listener.assertEvent(wereSourcesAdded: true);
      listener.assertEvent(changedSources: [libA]);
      listener.assertEvent(wereSourcesAdded: true);
      listener.assertEvent(changedSources: [libB]);
      listener.assertEvent(wereSourcesRemovedOrDeleted: true);
      listener.assertNoMoreEvents();
    });
  }

  void fail_computeDocumentationComment_block() {
    _context = contextWithCore();
    _sourceFactory = _context.sourceFactory;
    String comment = "/** Comment */";
    Source source = _addSource("/test.dart", """
$comment
class A {}""");
    LibraryElement libraryElement = _context.computeLibraryElement(source);
    expect(libraryElement, isNotNull);
    ClassElement classElement = libraryElement.definingCompilationUnit.types[0];
    expect(libraryElement, isNotNull);
    expect(_context.computeDocumentationComment(classElement), comment);
  }

  void fail_computeDocumentationComment_none() {
    _context = contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source source = _addSource("/test.dart", "class A {}");
    LibraryElement libraryElement = _context.computeLibraryElement(source);
    expect(libraryElement, isNotNull);
    ClassElement classElement = libraryElement.definingCompilationUnit.types[0];
    expect(libraryElement, isNotNull);
    expect(_context.computeDocumentationComment(classElement), isNull);
  }

  void fail_computeDocumentationComment_singleLine_multiple_EOL_n() {
    _context = contextWithCore();
    _sourceFactory = _context.sourceFactory;
    String comment = "/// line 1\n/// line 2\n/// line 3\n";
    Source source = _addSource("/test.dart", "${comment}class A {}");
    LibraryElement libraryElement = _context.computeLibraryElement(source);
    expect(libraryElement, isNotNull);
    ClassElement classElement = libraryElement.definingCompilationUnit.types[0];
    expect(libraryElement, isNotNull);
    String actual = _context.computeDocumentationComment(classElement);
    expect(actual, "/// line 1\n/// line 2\n/// line 3");
  }

  void fail_computeDocumentationComment_singleLine_multiple_EOL_rn() {
    _context = contextWithCore();
    _sourceFactory = _context.sourceFactory;
    String comment = "/// line 1\r\n/// line 2\r\n/// line 3\r\n";
    Source source = _addSource("/test.dart", "${comment}class A {}");
    LibraryElement libraryElement = _context.computeLibraryElement(source);
    expect(libraryElement, isNotNull);
    ClassElement classElement = libraryElement.definingCompilationUnit.types[0];
    expect(libraryElement, isNotNull);
    String actual = _context.computeDocumentationComment(classElement);
    expect(actual, "/// line 1\n/// line 2\n/// line 3");
  }

  void fail_computeErrors_dart_none() {
    Source source = _addSource("/lib.dart", "library lib;");
    List<AnalysisError> errors = _context.computeErrors(source);
    expect(errors, hasLength(0));
  }

  void fail_computeErrors_dart_part() {
    Source librarySource =
        _addSource("/lib.dart", "library lib; part 'part.dart';");
    Source partSource = _addSource("/part.dart", "part of 'lib';");
    _context.parseCompilationUnit(librarySource);
    List<AnalysisError> errors = _context.computeErrors(partSource);
    expect(errors, isNotNull);
    expect(errors.length > 0, isTrue);
  }

  void fail_computeErrors_dart_some() {
    Source source = _addSource("/lib.dart", "library 'lib';");
    List<AnalysisError> errors = _context.computeErrors(source);
    expect(errors, isNotNull);
    expect(errors.length > 0, isTrue);
  }

  void fail_computeErrors_html_none() {
    Source source = _addSource("/test.html", "<html></html>");
    List<AnalysisError> errors = _context.computeErrors(source);
    expect(errors, hasLength(0));
  }

  void fail_computeHtmlElement_valid() {
    Source source = _addSource("/test.html", "<html></html>");
    HtmlElement element = _context.computeHtmlElement(source);
    expect(element, isNotNull);
    expect(_context.computeHtmlElement(source), same(element));
  }

  void fail_computeImportedLibraries_none() {
    Source source = _addSource("/test.dart", "library test;");
    expect(_context.computeImportedLibraries(source), hasLength(0));
  }

  void fail_computeImportedLibraries_some() {
    //    addSource("/lib1.dart", "library lib1;");
    //    addSource("/lib2.dart", "library lib2;");
    Source source = _addSource(
        "/test.dart", "library test; import 'lib1.dart'; import 'lib2.dart';");
    expect(_context.computeImportedLibraries(source), hasLength(2));
  }

  void fail_computeKindOf_html() {
    Source source = _addSource("/test.html", "");
    expect(_context.computeKindOf(source), same(SourceKind.HTML));
  }

  void fail_computeLibraryElement() {
    _context = contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source source = _addSource("/test.dart", "library lib;");
    LibraryElement element = _context.computeLibraryElement(source);
    expect(element, isNotNull);
  }

  void fail_computeResolvableCompilationUnit_dart_exception() {
    TestSource source = _addSourceWithException("/test.dart");
    try {
      _context.computeResolvableCompilationUnit(source);
      fail("Expected AnalysisException");
    } on AnalysisException {
      // Expected
    }
  }

  void fail_computeResolvableCompilationUnit_html_exception() {
    Source source = _addSource("/lib.html", "<html></html>");
    try {
      _context.computeResolvableCompilationUnit(source);
      fail("Expected AnalysisException");
    } on AnalysisException {
      // Expected
    }
  }

  void fail_computeResolvableCompilationUnit_valid() {
    Source source = _addSource("/lib.dart", "library lib;");
    CompilationUnit parsedUnit = _context.parseCompilationUnit(source);
    expect(parsedUnit, isNotNull);
    CompilationUnit resolvedUnit =
        _context.computeResolvableCompilationUnit(source);
    expect(resolvedUnit, isNotNull);
    expect(resolvedUnit, same(parsedUnit));
  }

  Future fail_computeResolvedCompilationUnitAsync() {
    _context = contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source source = _addSource("/lib.dart", "library lib;");
    // Complete all pending analysis tasks and flush the AST so that it won't
    // be available immediately.
    _performPendingAnalysisTasks();
    CacheEntry entry = _context.getReadableSourceEntryOrNull(source);
    entry.flushAstStructures();
    bool completed = false;
    _context
        .computeResolvedCompilationUnitAsync(source, source)
        .then((CompilationUnit unit) {
      expect(unit, isNotNull);
      completed = true;
    });
    return pumpEventQueue().then((_) {
      expect(completed, isFalse);
      _performPendingAnalysisTasks();
    }).then((_) => pumpEventQueue()).then((_) {
      expect(completed, isTrue);
    });
  }

  Future fail_computeResolvedCompilationUnitAsync_afterDispose() {
    _context = contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source source = _addSource("/lib.dart", "library lib;");
    // Complete all pending analysis tasks and flush the AST so that it won't
    // be available immediately.
    _performPendingAnalysisTasks();
    CacheEntry entry = _context.getReadableSourceEntryOrNull(source);
    entry.flushAstStructures();
    // Dispose of the context.
    _context.dispose();
    // Any attempt to start an asynchronous computation should return a future
    // which completes with error.
    CancelableFuture<CompilationUnit> future =
        _context.computeResolvedCompilationUnitAsync(source, source);
    bool completed = false;
    future.then((CompilationUnit unit) {
      fail('Future should have completed with error');
    }, onError: (error) {
      expect(error, new isInstanceOf<AnalysisNotScheduledError>());
      completed = true;
    });
    return pumpEventQueue().then((_) {
      expect(completed, isTrue);
    });
  }

  Future fail_computeResolvedCompilationUnitAsync_cancel() {
    _context = contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source source = _addSource("/lib.dart", "library lib;");
    // Complete all pending analysis tasks and flush the AST so that it won't
    // be available immediately.
    _performPendingAnalysisTasks();
    CacheEntry entry = _context.getReadableSourceEntryOrNull(source);
    entry.flushAstStructures();
    CancelableFuture<CompilationUnit> future =
        _context.computeResolvedCompilationUnitAsync(source, source);
    bool completed = false;
    future.then((CompilationUnit unit) {
      fail('Future should have been canceled');
    }, onError: (error) {
      expect(error, new isInstanceOf<FutureCanceledError>());
      completed = true;
    });
    expect(completed, isFalse);
    expect(_context.pendingFutureSources_forTesting, isNotEmpty);
    future.cancel();
    expect(_context.pendingFutureSources_forTesting, isEmpty);
    return pumpEventQueue().then((_) {
      expect(completed, isTrue);
      expect(_context.pendingFutureSources_forTesting, isEmpty);
    });
  }

  Future fail_computeResolvedCompilationUnitAsync_dispose() {
    _context = contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source source = _addSource("/lib.dart", "library lib;");
    // Complete all pending analysis tasks and flush the AST so that it won't
    // be available immediately.
    _performPendingAnalysisTasks();
    CacheEntry entry = _context.getReadableSourceEntryOrNull(source);
    entry.flushAstStructures();
    CancelableFuture<CompilationUnit> future =
        _context.computeResolvedCompilationUnitAsync(source, source);
    bool completed = false;
    future.then((CompilationUnit unit) {
      fail('Future should have completed with error');
    }, onError: (error) {
      expect(error, new isInstanceOf<AnalysisNotScheduledError>());
      completed = true;
    });
    expect(completed, isFalse);
    expect(_context.pendingFutureSources_forTesting, isNotEmpty);
    // Disposing of the context should cause all pending futures to complete
    // with AnalysisNotScheduled, so that no clients are left hanging.
    _context.dispose();
    expect(_context.pendingFutureSources_forTesting, isEmpty);
    return pumpEventQueue().then((_) {
      expect(completed, isTrue);
      expect(_context.pendingFutureSources_forTesting, isEmpty);
    });
  }

  Future fail_computeResolvedCompilationUnitAsync_unrelatedLibrary() {
    _context = contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source librarySource = _addSource("/lib.dart", "library lib;");
    Source partSource = _addSource("/part.dart", "part of foo;");
    bool completed = false;
    _context
        .computeResolvedCompilationUnitAsync(partSource, librarySource)
        .then((_) {
      // TODO(brianwilkerson) Uncomment the line below (and figure out why
      // invoking 'fail' directly causes a failing test to fail.
      //fail('Expected resolution to fail');
    }, onError: (e) {
      expect(e, new isInstanceOf<AnalysisNotScheduledError>());
      completed = true;
    });
    return pumpEventQueue().then((_) {
      expect(completed, isFalse);
      _performPendingAnalysisTasks();
    }).then((_) => pumpEventQueue()).then((_) {
      expect(completed, isTrue);
    });
  }

  void fail_extractContext() {
    fail("Implement this");
  }

  void fail_getElement_constructor_named() {
    Source source = _addSource("/lib.dart", r'''
class A {
  A.named() {}
}''');
    _analyzeAll_assertFinished();
    LibraryElement library = _context.computeLibraryElement(source);
    ClassElement classA = _findClass(library.definingCompilationUnit, "A");
    ConstructorElement constructor = classA.constructors[0];
    ElementLocation location = constructor.location;
    Element element = _context.getElement(location);
    expect(element, same(constructor));
  }

  void fail_getElement_constructor_unnamed() {
    Source source = _addSource("/lib.dart", r'''
class A {
  A() {}
}''');
    _analyzeAll_assertFinished();
    LibraryElement library = _context.computeLibraryElement(source);
    ClassElement classA = _findClass(library.definingCompilationUnit, "A");
    ConstructorElement constructor = classA.constructors[0];
    ElementLocation location = constructor.location;
    Element element = _context.getElement(location);
    expect(element, same(constructor));
  }

  void fail_getElement_enum() {
    Source source = _addSource('/test.dart', 'enum MyEnum {A, B, C}');
    _analyzeAll_assertFinished();
    LibraryElement library = _context.computeLibraryElement(source);
    ClassElement myEnum = library.definingCompilationUnit.getEnum('MyEnum');
    ElementLocation location = myEnum.location;
    Element element = _context.getElement(location);
    expect(element, same(myEnum));
  }

  void fail_getErrors_dart_none() {
    Source source = _addSource("/lib.dart", "library lib;");
    var errorInfo = _context.getErrors(source);
    expect(errorInfo, isNotNull);
    List<AnalysisError> errors = errorInfo.errors;
    expect(errors, hasLength(0));
    _context.computeErrors(source);
    errors = errorInfo.errors;
    expect(errors, hasLength(0));
  }

  void fail_getErrors_dart_some() {
    Source source = _addSource("/lib.dart", "library 'lib';");
    var errorInfo = _context.getErrors(source);
    expect(errorInfo, isNotNull);
    List<AnalysisError> errors = errorInfo.errors;
    expect(errors, hasLength(0));
    _context.computeErrors(source);
    errors = errorInfo.errors;
    expect(errors, hasLength(1));
  }

  void fail_getErrors_html_none() {
    Source source = _addSource("/test.html", "<html></html>");
    AnalysisErrorInfo errorInfo = _context.getErrors(source);
    expect(errorInfo, isNotNull);
    List<AnalysisError> errors = errorInfo.errors;
    expect(errors, hasLength(0));
    _context.computeErrors(source);
    errors = errorInfo.errors;
    expect(errors, hasLength(0));
  }

  void fail_getErrors_html_some() {
    Source source = _addSource("/test.html", r'''
<html><head>
<script type='application/dart' src='test.dart'/>
</head></html>''');
    AnalysisErrorInfo errorInfo = _context.getErrors(source);
    expect(errorInfo, isNotNull);
    List<AnalysisError> errors = errorInfo.errors;
    expect(errors, hasLength(0));
    _context.computeErrors(source);
    errors = errorInfo.errors;
    expect(errors, hasLength(1));
  }

  void fail_getHtmlElement_html() {
    Source source = _addSource("/test.html", "<html></html>");
    HtmlElement element = _context.getHtmlElement(source);
    expect(element, isNull);
    _context.computeHtmlElement(source);
    element = _context.getHtmlElement(source);
    expect(element, isNotNull);
  }

  void fail_getHtmlFilesReferencing_library() {
    Source htmlSource = _addSource("/test.html", r'''
<html><head>
<script type='application/dart' src='test.dart'/>
<script type='application/dart' src='test.js'/>
</head></html>''');
    Source librarySource = _addSource("/test.dart", "library lib;");
    List<Source> result = _context.getHtmlFilesReferencing(librarySource);
    expect(result, hasLength(0));
    _context.parseHtmlUnit(htmlSource);
    result = _context.getHtmlFilesReferencing(librarySource);
    expect(result, hasLength(1));
    expect(result[0], htmlSource);
  }

  void fail_getHtmlFilesReferencing_part() {
    _context = contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source htmlSource = _addSource("/test.html", r'''
<html><head>
<script type='application/dart' src='test.dart'/>
<script type='application/dart' src='test.js'/>
</head></html>''');
    Source librarySource =
        _addSource("/test.dart", "library lib; part 'part.dart';");
    Source partSource = _addSource("/part.dart", "part of lib;");
    _context.computeLibraryElement(librarySource);
    List<Source> result = _context.getHtmlFilesReferencing(partSource);
    expect(result, hasLength(0));
    _context.parseHtmlUnit(htmlSource);
    result = _context.getHtmlFilesReferencing(partSource);
    expect(result, hasLength(1));
    expect(result[0], htmlSource);
  }

  void fail_getHtmlSources() {
    List<Source> sources = _context.htmlSources;
    expect(sources, hasLength(0));
    Source source = _addSource("/test.html", "");
    _context.computeKindOf(source);
    sources = _context.htmlSources;
    expect(sources, hasLength(1));
    expect(sources[0], source);
  }

  void fail_getKindOf_html() {
    Source source = _addSource("/test.html", "");
    expect(_context.getKindOf(source), same(SourceKind.HTML));
  }

  void fail_getLibrariesContaining() {
    _context = contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source librarySource = _addSource("/lib.dart", r'''
library lib;
part 'part.dart';''');
    Source partSource = _addSource("/part.dart", "part of lib;");
    _context.computeLibraryElement(librarySource);
    List<Source> result = _context.getLibrariesContaining(librarySource);
    expect(result, hasLength(1));
    expect(result[0], librarySource);
    result = _context.getLibrariesContaining(partSource);
    expect(result, hasLength(1));
    expect(result[0], librarySource);
  }

  void fail_getLibrariesReferencedFromHtml() {
    _context = contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source htmlSource = _addSource("/test.html", r'''
<html><head>
<script type='application/dart' src='test.dart'/>
<script type='application/dart' src='test.js'/>
</head></html>''');
    Source librarySource = _addSource("/test.dart", "library lib;");
    _context.computeLibraryElement(librarySource);
    _context.parseHtmlUnit(htmlSource);
    List<Source> result = _context.getLibrariesReferencedFromHtml(htmlSource);
    expect(result, hasLength(1));
    expect(result[0], librarySource);
  }

  void fail_getLibraryElement() {
    _context = contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source source = _addSource("/test.dart", "library lib;");
    LibraryElement element = _context.getLibraryElement(source);
    expect(element, isNull);
    _context.computeLibraryElement(source);
    element = _context.getLibraryElement(source);
    expect(element, isNotNull);
  }

  void fail_getPublicNamespace_element() {
    _context = contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source source = _addSource("/test.dart", "class A {}");
    LibraryElement library = _context.computeLibraryElement(source);
    expect(library, isNotNull);
    Namespace namespace = _context.getPublicNamespace(library);
    expect(namespace, isNotNull);
    EngineTestCase.assertInstanceOf(
        (obj) => obj is ClassElement, ClassElement, namespace.get("A"));
  }

  void fail_getRefactoringUnsafeSources() {
    // not sources initially
    List<Source> sources = _context.refactoringUnsafeSources;
    expect(sources, hasLength(0));
    // add new source, unresolved
    Source source = _addSource("/test.dart", "library lib;");
    sources = _context.refactoringUnsafeSources;
    expect(sources, hasLength(1));
    expect(sources[0], source);
    // resolve source
    _context.computeLibraryElement(source);
    sources = _context.refactoringUnsafeSources;
    expect(sources, hasLength(0));
  }

  void fail_getResolvedCompilationUnit_library() {
    _context = contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source source = _addSource("/lib.dart", "library libb;");
    LibraryElement library = _context.computeLibraryElement(source);
    expect(_context.getResolvedCompilationUnit(source, library), isNotNull);
    _context.setContents(source, "library lib;");
    expect(_context.getResolvedCompilationUnit(source, library), isNull);
  }

  void fail_getResolvedCompilationUnit_source_dart() {
    _context = contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source source = _addSource("/lib.dart", "library lib;");
    expect(_context.getResolvedCompilationUnit2(source, source), isNull);
    _context.resolveCompilationUnit2(source, source);
    expect(_context.getResolvedCompilationUnit2(source, source), isNotNull);
  }

  void fail_getResolvedHtmlUnit() {
    _context = contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source source = _addSource("/test.html", "<html></html>");
    expect(_context.getResolvedHtmlUnit(source), isNull);
    _context.resolveHtmlUnit(source);
    expect(_context.getResolvedHtmlUnit(source), isNotNull);
  }

  void fail_mergeContext() {
    fail("Implement this");
  }

  void fail_parseCompilationUnit_errors() {
    Source source = _addSource("/lib.dart", "library {");
    CompilationUnit compilationUnit = _context.parseCompilationUnit(source);
    expect(compilationUnit, isNotNull);
    var errorInfo = _context.getErrors(source);
    expect(errorInfo, isNotNull);
    List<AnalysisError> errors = errorInfo.errors;
    expect(errors, isNotNull);
    expect(errors.length > 0, isTrue);
  }

  void fail_parseCompilationUnit_exception() {
    Source source = _addSourceWithException("/test.dart");
    try {
      _context.parseCompilationUnit(source);
      fail("Expected AnalysisException");
    } on AnalysisException {
      // Expected
    }
  }

  void fail_parseCompilationUnit_noErrors() {
    Source source = _addSource("/lib.dart", "library lib;");
    CompilationUnit compilationUnit = _context.parseCompilationUnit(source);
    expect(compilationUnit, isNotNull);
    AnalysisErrorInfo errorInfo = _context.getErrors(source);
    expect(errorInfo, isNotNull);
    expect(errorInfo.errors, hasLength(0));
  }

  void fail_parseCompilationUnit_nonExistentSource() {
    Source source =
        new FileBasedSource.con1(FileUtilities2.createFile("/test.dart"));
    try {
      _context.parseCompilationUnit(source);
      fail("Expected AnalysisException because file does not exist");
    } on AnalysisException {
      // Expected result
    }
  }

  void fail_parseHtmlUnit_noErrors() {
    Source source = _addSource("/lib.html", "<html></html>");
    ht.HtmlUnit unit = _context.parseHtmlUnit(source);
    expect(unit, isNotNull);
  }

  void fail_parseHtmlUnit_resolveDirectives() {
    Source libSource = _addSource("/lib.dart", r'''
library lib;
class ClassA {}''');
    Source source = _addSource("/lib.html", r'''
<html>
<head>
  <script type='application/dart'>
    import 'lib.dart';
    ClassA v = null;
  </script>
</head>
<body>
</body>
</html>''');
    ht.HtmlUnit unit = _context.parseHtmlUnit(source);
    expect(unit, isNotNull);
    // import directive should be resolved
    ht.XmlTagNode htmlNode = unit.tagNodes[0];
    ht.XmlTagNode headNode = htmlNode.tagNodes[0];
    ht.HtmlScriptTagNode scriptNode = headNode.tagNodes[0];
    CompilationUnit script = scriptNode.script;
    ImportDirective importNode = script.directives[0] as ImportDirective;
    expect(importNode.uriContent, isNotNull);
    expect(importNode.source, libSource);
  }

  void fail_performAnalysisTask_addPart() {
    Source libSource = _addSource("/lib.dart", r'''
library lib;
part 'part.dart';''');
    // run all tasks without part
    _analyzeAll_assertFinished();
    // add part and run all tasks
    Source partSource = _addSource("/part.dart", r'''
part of lib;
''');
    _analyzeAll_assertFinished();
    // "libSource" should be here
    List<Source> librariesWithPart =
        _context.getLibrariesContaining(partSource);
    expect(librariesWithPart, unorderedEquals([libSource]));
  }

  void fail_performAnalysisTask_changeLibraryContents() {
    Source libSource =
        _addSource("/test.dart", "library lib; part 'test-part.dart';");
    Source partSource = _addSource("/test-part.dart", "part of lib;");
    _analyzeAll_assertFinished();
    expect(
        _context.getResolvedCompilationUnit2(libSource, libSource), isNotNull,
        reason: "library resolved 1");
    expect(
        _context.getResolvedCompilationUnit2(partSource, libSource), isNotNull,
        reason: "part resolved 1");
    // update and analyze #1
    _context.setContents(libSource, "library lib;");
    expect(_context.getResolvedCompilationUnit2(libSource, libSource), isNull,
        reason: "library changed 2");
    expect(_context.getResolvedCompilationUnit2(partSource, libSource), isNull,
        reason: "part changed 2");
    _analyzeAll_assertFinished();
    expect(
        _context.getResolvedCompilationUnit2(libSource, libSource), isNotNull,
        reason: "library resolved 2");
    expect(_context.getResolvedCompilationUnit2(partSource, libSource), isNull,
        reason: "part resolved 2");
    // update and analyze #2
    _context.setContents(libSource, "library lib; part 'test-part.dart';");
    expect(_context.getResolvedCompilationUnit2(libSource, libSource), isNull,
        reason: "library changed 3");
    expect(_context.getResolvedCompilationUnit2(partSource, libSource), isNull,
        reason: "part changed 3");
    _analyzeAll_assertFinished();
    expect(
        _context.getResolvedCompilationUnit2(libSource, libSource), isNotNull,
        reason: "library resolved 2");
    expect(
        _context.getResolvedCompilationUnit2(partSource, libSource), isNotNull,
        reason: "part resolved 3");
  }

  void fail_performAnalysisTask_changeLibraryThenPartContents() {
    Source libSource =
        _addSource("/test.dart", "library lib; part 'test-part.dart';");
    Source partSource = _addSource("/test-part.dart", "part of lib;");
    _analyzeAll_assertFinished();
    expect(
        _context.getResolvedCompilationUnit2(libSource, libSource), isNotNull,
        reason: "library resolved 1");
    expect(
        _context.getResolvedCompilationUnit2(partSource, libSource), isNotNull,
        reason: "part resolved 1");
    // update and analyze #1
    _context.setContents(libSource, "library lib;");
    expect(_context.getResolvedCompilationUnit2(libSource, libSource), isNull,
        reason: "library changed 2");
    expect(_context.getResolvedCompilationUnit2(partSource, libSource), isNull,
        reason: "part changed 2");
    _analyzeAll_assertFinished();
    expect(
        _context.getResolvedCompilationUnit2(libSource, libSource), isNotNull,
        reason: "library resolved 2");
    expect(_context.getResolvedCompilationUnit2(partSource, libSource), isNull,
        reason: "part resolved 2");
    // update and analyze #2
    _context.setContents(partSource, "part of lib; // 1");
    // Assert that changing the part's content does not effect the library
    // now that it is no longer part of that library
    expect(
        _context.getResolvedCompilationUnit2(libSource, libSource), isNotNull,
        reason: "library changed 3");
    expect(_context.getResolvedCompilationUnit2(partSource, libSource), isNull,
        reason: "part changed 3");
    _analyzeAll_assertFinished();
    expect(
        _context.getResolvedCompilationUnit2(libSource, libSource), isNotNull,
        reason: "library resolved 3");
    expect(_context.getResolvedCompilationUnit2(partSource, libSource), isNull,
        reason: "part resolved 3");
  }

  void fail_performAnalysisTask_changePartContents_makeItAPart() {
    Source libSource = _addSource("/lib.dart", r'''
library lib;
part 'part.dart';
void f(x) {}''');
    Source partSource = _addSource("/part.dart", "void g() { f(null); }");
    _analyzeAll_assertFinished();
    expect(
        _context.getResolvedCompilationUnit2(libSource, libSource), isNotNull,
        reason: "library resolved 1");
    expect(
        _context.getResolvedCompilationUnit2(partSource, libSource), isNotNull,
        reason: "part resolved 1");
    // update and analyze
    _context.setContents(partSource, r'''
part of lib;
void g() { f(null); }''');
    expect(_context.getResolvedCompilationUnit2(libSource, libSource), isNull,
        reason: "library changed 2");
    expect(_context.getResolvedCompilationUnit2(partSource, libSource), isNull,
        reason: "part changed 2");
    _analyzeAll_assertFinished();
    expect(
        _context.getResolvedCompilationUnit2(libSource, libSource), isNotNull,
        reason: "library resolved 2");
    expect(
        _context.getResolvedCompilationUnit2(partSource, libSource), isNotNull,
        reason: "part resolved 2");
    expect(_context.getErrors(libSource).errors, hasLength(0));
    expect(_context.getErrors(partSource).errors, hasLength(0));
  }

  /**
   * https://code.google.com/p/dart/issues/detail?id=12424
   */
  void fail_performAnalysisTask_changePartContents_makeItNotPart() {
    Source libSource = _addSource("/lib.dart", r'''
library lib;
part 'part.dart';
void f(x) {}''');
    Source partSource = _addSource("/part.dart", r'''
part of lib;
void g() { f(null); }''');
    _analyzeAll_assertFinished();
    expect(_context.getErrors(libSource).errors, hasLength(0));
    expect(_context.getErrors(partSource).errors, hasLength(0));
    // Remove 'part' directive, which should make "f(null)" an error.
    _context.setContents(partSource, r'''
//part of lib;
void g() { f(null); }''');
    _analyzeAll_assertFinished();
    expect(_context.getErrors(libSource).errors.length != 0, isTrue);
  }

  void fail_performAnalysisTask_changePartContents_noSemanticChanges() {
    Source libSource =
        _addSource("/test.dart", "library lib; part 'test-part.dart';");
    Source partSource = _addSource("/test-part.dart", "part of lib;");
    _analyzeAll_assertFinished();
    expect(
        _context.getResolvedCompilationUnit2(libSource, libSource), isNotNull,
        reason: "library resolved 1");
    expect(
        _context.getResolvedCompilationUnit2(partSource, libSource), isNotNull,
        reason: "part resolved 1");
    // update and analyze #1
    _context.setContents(partSource, "part of lib; // 1");
    expect(_context.getResolvedCompilationUnit2(libSource, libSource), isNull,
        reason: "library changed 2");
    expect(_context.getResolvedCompilationUnit2(partSource, libSource), isNull,
        reason: "part changed 2");
    _analyzeAll_assertFinished();
    expect(
        _context.getResolvedCompilationUnit2(libSource, libSource), isNotNull,
        reason: "library resolved 2");
    expect(
        _context.getResolvedCompilationUnit2(partSource, libSource), isNotNull,
        reason: "part resolved 2");
    // update and analyze #2
    _context.setContents(partSource, "part of lib; // 12");
    expect(_context.getResolvedCompilationUnit2(libSource, libSource), isNull,
        reason: "library changed 3");
    expect(_context.getResolvedCompilationUnit2(partSource, libSource), isNull,
        reason: "part changed 3");
    _analyzeAll_assertFinished();
    expect(
        _context.getResolvedCompilationUnit2(libSource, libSource), isNotNull,
        reason: "library resolved 3");
    expect(
        _context.getResolvedCompilationUnit2(partSource, libSource), isNotNull,
        reason: "part resolved 3");
  }

  void fail_performAnalysisTask_getContentException_dart() {
    // add source that throw an exception on "get content"
    Source source = new _Source_getContent_throwException('test.dart');
    {
      ChangeSet changeSet = new ChangeSet();
      changeSet.addedSource(source);
      _context.applyChanges(changeSet);
    }
    // prepare errors
    _analyzeAll_assertFinished();
    List<AnalysisError> errors = _context.getErrors(source).errors;
    // validate errors
    expect(errors, hasLength(1));
    AnalysisError error = errors[0];
    expect(error.source, same(source));
    expect(error.errorCode, ScannerErrorCode.UNABLE_GET_CONTENT);
  }

  void fail_performAnalysisTask_getContentException_html() {
    // add source that throw an exception on "get content"
    Source source = new _Source_getContent_throwException('test.html');
    {
      ChangeSet changeSet = new ChangeSet();
      changeSet.addedSource(source);
      _context.applyChanges(changeSet);
    }
    // prepare errors
    _analyzeAll_assertFinished();
    List<AnalysisError> errors = _context.getErrors(source).errors;
    // validate errors
    expect(errors, hasLength(1));
    AnalysisError error = errors[0];
    expect(error.source, same(source));
    expect(error.errorCode, ScannerErrorCode.UNABLE_GET_CONTENT);
  }

  void fail_performAnalysisTask_importedLibraryAdd() {
    Source libASource =
        _addSource("/libA.dart", "library libA; import 'libB.dart';");
    _analyzeAll_assertFinished();
    expect(
        _context.getResolvedCompilationUnit2(libASource, libASource), isNotNull,
        reason: "libA resolved 1");
    expect(_hasAnalysisErrorWithErrorSeverity(_context.getErrors(libASource)),
        isTrue, reason: "libA has an error");
    // add libB.dart and analyze
    Source libBSource = _addSource("/libB.dart", "library libB;");
    _analyzeAll_assertFinished();
    expect(
        _context.getResolvedCompilationUnit2(libASource, libASource), isNotNull,
        reason: "libA resolved 2");
    expect(
        _context.getResolvedCompilationUnit2(libBSource, libBSource), isNotNull,
        reason: "libB resolved 2");
    expect(!_hasAnalysisErrorWithErrorSeverity(_context.getErrors(libASource)),
        isTrue, reason: "libA doesn't have errors");
  }

  void fail_performAnalysisTask_importedLibraryAdd_html() {
    Source htmlSource = _addSource("/page.html", r'''
<html><body><script type="application/dart">
  import '/libB.dart';
  main() {print('hello dart');}
</script></body></html>''');
    _analyzeAll_assertFinished();
    expect(_context.getResolvedHtmlUnit(htmlSource), isNotNull,
        reason: "htmlUnit resolved 1");
    expect(_hasAnalysisErrorWithErrorSeverity(_context.getErrors(htmlSource)),
        isTrue, reason: "htmlSource has an error");
    // add libB.dart and analyze
    Source libBSource = _addSource("/libB.dart", "library libB;");
    _analyzeAll_assertFinished();
    expect(_context.getResolvedHtmlUnit(htmlSource), isNotNull,
        reason: "htmlUnit resolved 1");
    expect(
        _context.getResolvedCompilationUnit2(libBSource, libBSource), isNotNull,
        reason: "libB resolved 2");
    // TODO (danrubel) commented out to fix red bots
//    AnalysisErrorInfo errors = _context.getErrors(htmlSource);
//    expect(
//        !_hasAnalysisErrorWithErrorSeverity(errors),
//        isTrue,
//        reason: "htmlSource doesn't have errors");
  }

  void fail_performAnalysisTask_importedLibraryDelete() {
    Source libASource =
        _addSource("/libA.dart", "library libA; import 'libB.dart';");
    Source libBSource = _addSource("/libB.dart", "library libB;");
    _analyzeAll_assertFinished();
    expect(
        _context.getResolvedCompilationUnit2(libASource, libASource), isNotNull,
        reason: "libA resolved 1");
    expect(
        _context.getResolvedCompilationUnit2(libBSource, libBSource), isNotNull,
        reason: "libB resolved 1");
    expect(!_hasAnalysisErrorWithErrorSeverity(_context.getErrors(libASource)),
        isTrue, reason: "libA doesn't have errors");
    // remove libB.dart content and analyze
    _context.setContents(libBSource, null);
    _analyzeAll_assertFinished();
    expect(
        _context.getResolvedCompilationUnit2(libASource, libASource), isNotNull,
        reason: "libA resolved 2");
    expect(_hasAnalysisErrorWithErrorSeverity(_context.getErrors(libASource)),
        isTrue, reason: "libA has an error");
  }

  void fail_performAnalysisTask_importedLibraryDelete_html() {
    // NOTE: This was failing before converting to the new task model.
    Source htmlSource = _addSource("/page.html", r'''
<html><body><script type="application/dart">
  import 'libB.dart';
  main() {print('hello dart');}
</script></body></html>''');
    Source libBSource = _addSource("/libB.dart", "library libB;");
    _analyzeAll_assertFinished();
    expect(_context.getResolvedHtmlUnit(htmlSource), isNotNull,
        reason: "htmlUnit resolved 1");
    expect(
        _context.getResolvedCompilationUnit2(libBSource, libBSource), isNotNull,
        reason: "libB resolved 1");
    expect(!_hasAnalysisErrorWithErrorSeverity(_context.getErrors(htmlSource)),
        isTrue, reason: "htmlSource doesn't have errors");
    // remove libB.dart content and analyze
    _context.setContents(libBSource, null);
    _analyzeAll_assertFinished();
    expect(_context.getResolvedHtmlUnit(htmlSource), isNotNull,
        reason: "htmlUnit resolved 1");
    AnalysisErrorInfo errors = _context.getErrors(htmlSource);
    expect(_hasAnalysisErrorWithErrorSeverity(errors), isTrue,
        reason: "htmlSource has an error");
  }

  void fail_performAnalysisTask_IOException() {
    TestSource source = _addSourceWithException2("/test.dart", "library test;");
    int oldTimestamp = _context.getModificationStamp(source);
    source.generateExceptionOnRead = false;
    _analyzeAll_assertFinished();
    expect(source.readCount, 1);
    source.generateExceptionOnRead = true;
    do {
      _changeSource(source, "");
      // Ensure that the timestamp differs,
      // so that analysis engine notices the change
    } while (oldTimestamp == _context.getModificationStamp(source));
    _analyzeAll_assertFinished();
    expect(source.readCount, 2);
  }

  void fail_performAnalysisTask_missingPart() {
    Source source =
        _addSource("/test.dart", "library lib; part 'no-such-file.dart';");
    _analyzeAll_assertFinished();
    expect(_context.getLibraryElement(source), isNotNull,
        reason: "performAnalysisTask failed to compute an element model");
  }

  void fail_recordLibraryElements() {
    fail("Implement this");
  }

  void fail_resolveCompilationUnit_import_relative() {
    _context = contextWithCore();
    Source sourceA =
        _addSource("/libA.dart", "library libA; import 'libB.dart'; class A{}");
    _addSource("/libB.dart", "library libB; class B{}");
    CompilationUnit compilationUnit =
        _context.resolveCompilationUnit2(sourceA, sourceA);
    expect(compilationUnit, isNotNull);
    LibraryElement library = compilationUnit.element.library;
    List<LibraryElement> importedLibraries = library.importedLibraries;
    assertNamedElements(importedLibraries, ["dart.core", "libB"]);
    List<LibraryElement> visibleLibraries = library.visibleLibraries;
    assertNamedElements(visibleLibraries, ["dart.core", "libA", "libB"]);
  }

  void fail_resolveCompilationUnit_import_relative_cyclic() {
    _context = contextWithCore();
    Source sourceA =
        _addSource("/libA.dart", "library libA; import 'libB.dart'; class A{}");
    _addSource("/libB.dart", "library libB; import 'libA.dart'; class B{}");
    CompilationUnit compilationUnit =
        _context.resolveCompilationUnit2(sourceA, sourceA);
    expect(compilationUnit, isNotNull);
    LibraryElement library = compilationUnit.element.library;
    List<LibraryElement> importedLibraries = library.importedLibraries;
    assertNamedElements(importedLibraries, ["dart.core", "libB"]);
    List<LibraryElement> visibleLibraries = library.visibleLibraries;
    assertNamedElements(visibleLibraries, ["dart.core", "libA", "libB"]);
  }

  void fail_resolveCompilationUnit_library() {
    _context = contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source source = _addSource("/lib.dart", "library lib;");
    LibraryElement library = _context.computeLibraryElement(source);
    CompilationUnit compilationUnit =
        _context.resolveCompilationUnit(source, library);
    expect(compilationUnit, isNotNull);
    expect(compilationUnit.element, isNotNull);
  }

  void fail_resolveCompilationUnit_source() {
    _context = contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source source = _addSource("/lib.dart", "library lib;");
    CompilationUnit compilationUnit =
        _context.resolveCompilationUnit2(source, source);
    expect(compilationUnit, isNotNull);
  }

  void fail_resolveHtmlUnit() {
    Source source = _addSource("/lib.html", "<html></html>");
    ht.HtmlUnit unit = _context.resolveHtmlUnit(source);
    expect(unit, isNotNull);
  }

  void fail_setAnalysisOptions_reduceAnalysisPriorityOrder() {
    AnalysisOptionsImpl options =
        new AnalysisOptionsImpl.con1(_context.analysisOptions);
    List<Source> sources = new List<Source>();
    for (int index = 0; index < options.cacheSize; index++) {
      sources.add(_addSource("/lib.dart$index", ""));
    }
    _context.analysisPriorityOrder = sources;
    int oldPriorityOrderSize = _getPriorityOrder(_context).length;
    options.cacheSize = options.cacheSize - 10;
    _context.analysisOptions = options;
    expect(oldPriorityOrderSize > _getPriorityOrder(_context).length, isTrue);
  }

  void fail_setAnalysisPriorityOrder_lessThanCacheSize() {
    AnalysisOptions options = _context.analysisOptions;
    List<Source> sources = new List<Source>();
    for (int index = 0; index < options.cacheSize; index++) {
      sources.add(_addSource("/lib.dart$index", ""));
    }
    _context.analysisPriorityOrder = sources;
    expect(options.cacheSize > _getPriorityOrder(_context).length, isTrue);
  }

  Future fail_setChangedContents_libraryWithPart() {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.incremental = true;
    _context = new AnalysisContextForTests();
    _context.analysisOptions = options;
    SourcesChangedListener listener = new SourcesChangedListener();
    _context.onSourcesChanged.listen(listener.onData);
    _sourceFactory = _context.sourceFactory;
    String oldCode = r'''
library lib;
part 'part.dart';
int a = 0;''';
    Source librarySource = _addSource("/lib.dart", oldCode);
    String partContents = r'''
part of lib;
int b = a;''';
    Source partSource = _addSource("/part.dart", partContents);
    LibraryElement element = _context.computeLibraryElement(librarySource);
    CompilationUnit unit =
        _context.getResolvedCompilationUnit(librarySource, element);
    expect(unit, isNotNull);
    int offset = oldCode.indexOf("int a") + 4;
    String newCode = r'''
library lib;
part 'part.dart';
int ya = 0;''';
    expect(_getIncrementalAnalysisCache(_context), isNull);
    _context.setChangedContents(librarySource, newCode, offset, 0, 1);
    expect(_context.getContents(librarySource).data, newCode);
    IncrementalAnalysisCache incrementalCache =
        _getIncrementalAnalysisCache(_context);
    expect(incrementalCache.librarySource, librarySource);
    expect(incrementalCache.resolvedUnit, same(unit));
    expect(_context.getResolvedCompilationUnit2(partSource, librarySource),
        isNull);
    expect(incrementalCache.newContents, newCode);
    return pumpEventQueue().then((_) {
      listener.assertEvent(wereSourcesAdded: true);
      listener.assertEvent(changedSources: [librarySource]);
      listener.assertEvent(wereSourcesAdded: true);
      listener.assertEvent(changedSources: [partSource]);
      listener.assertEvent(changedSources: [librarySource]);
      listener.assertNoMoreEvents();
    });
  }

  void fail_setContents_unchanged_consistentModificationTime() {
    String contents = "// foo";
    Source source = _addSource("/test.dart", contents);
    // do all, no tasks
    _analyzeAll_assertFinished();
    {
      AnalysisResult result = _context.performAnalysisTask();
      expect(result.changeNotices, isNull);
    }
    // set the same contents, still no tasks
    _context.setContents(source, contents);
    {
      AnalysisResult result = _context.performAnalysisTask();
      expect(result.changeNotices, isNull);
    }
  }

  void fail_unreadableSource() {
    _context = contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source test1 = _addSource("/test1.dart", r'''
import 'test2.dart';
library test1;''');
    Source test2 = _addSource("/test2.dart", r'''
import 'test1.dart';
import 'test3.dart';
library test2;''');
    Source test3 = _addSourceWithException("/test3.dart");
    _analyzeAll_assertFinished();
    // test1 and test2 should have been successfully analyzed
    // despite the fact that test3 couldn't be read.
    expect(_context.computeLibraryElement(test1), isNotNull);
    expect(_context.computeLibraryElement(test2), isNotNull);
    expect(_context.computeLibraryElement(test3), isNull);
  }

  @override
  void setUp() {
    EnginePlugin enginePlugin = AnalysisEngine.instance.enginePlugin;
    if (enginePlugin.taskExtensionPoint == null) {
      ExtensionManager manager = new ExtensionManager();
      manager.processPlugins([enginePlugin]);
    }

    _context = new AnalysisContextImpl();
    _sourceFactory = new SourceFactory([
      new DartUriResolver(DirectoryBasedDartSdk.defaultSdk),
      new FileUriResolver()
    ]);
    _context.sourceFactory = _sourceFactory;
    AnalysisOptionsImpl options =
        new AnalysisOptionsImpl.con1(_context.analysisOptions);
    options.cacheSize = 256;
    _context.analysisOptions = options;
  }

  @override
  void tearDown() {
    _context = null;
    _sourceFactory = null;
    super.tearDown();
  }

  Future test_applyChanges_add() {
    SourcesChangedListener listener = new SourcesChangedListener();
    _context.onSourcesChanged.listen(listener.onData);
    expect(_context.sourcesNeedingProcessing.isEmpty, isTrue);
    Source source =
        new FileBasedSource.con1(FileUtilities2.createFile("/test.dart"));
    ChangeSet changeSet = new ChangeSet();
    changeSet.addedSource(source);
    _context.applyChanges(changeSet);
    expect(_context.sourcesNeedingProcessing.contains(source), isTrue);
    return pumpEventQueue().then((_) {
      listener.assertEvent(wereSourcesAdded: true);
      listener.assertNoMoreEvents();
    });
  }

  Future test_applyChanges_change() {
    SourcesChangedListener listener = new SourcesChangedListener();
    _context.onSourcesChanged.listen(listener.onData);
    expect(_context.sourcesNeedingProcessing.isEmpty, isTrue);
    Source source =
        new FileBasedSource.con1(FileUtilities2.createFile("/test.dart"));
    ChangeSet changeSet1 = new ChangeSet();
    changeSet1.addedSource(source);
    _context.applyChanges(changeSet1);
    expect(_context.sourcesNeedingProcessing.contains(source), isTrue);
    Source source2 =
        new FileBasedSource.con1(FileUtilities2.createFile("/test2.dart"));
    ChangeSet changeSet2 = new ChangeSet();
    changeSet2.addedSource(source2);
    changeSet2.changedSource(source);
    _context.applyChanges(changeSet2);
    return pumpEventQueue().then((_) {
      listener.assertEvent(wereSourcesAdded: true);
      listener.assertEvent(wereSourcesAdded: true, changedSources: [source]);
      listener.assertNoMoreEvents();
    });
  }

  Future test_applyChanges_change_content() {
    SourcesChangedListener listener = new SourcesChangedListener();
    _context.onSourcesChanged.listen(listener.onData);
    expect(_context.sourcesNeedingProcessing.isEmpty, isTrue);
    Source source =
        new FileBasedSource.con1(FileUtilities2.createFile("/test.dart"));
    ChangeSet changeSet1 = new ChangeSet();
    changeSet1.addedSource(source);
    _context.applyChanges(changeSet1);
    expect(_context.sourcesNeedingProcessing.contains(source), isTrue);
    Source source2 =
        new FileBasedSource.con1(FileUtilities2.createFile("/test2.dart"));
    ChangeSet changeSet2 = new ChangeSet();
    changeSet2.addedSource(source2);
    changeSet2.changedContent(source, 'library test;');
    _context.applyChanges(changeSet2);
    return pumpEventQueue().then((_) {
      listener.assertEvent(wereSourcesAdded: true);
      listener.assertEvent(wereSourcesAdded: true, changedSources: [source]);
      listener.assertNoMoreEvents();
    });
  }

  Future test_applyChanges_change_range() {
    SourcesChangedListener listener = new SourcesChangedListener();
    _context.onSourcesChanged.listen(listener.onData);
    expect(_context.sourcesNeedingProcessing.isEmpty, isTrue);
    Source source =
        new FileBasedSource.con1(FileUtilities2.createFile("/test.dart"));
    ChangeSet changeSet1 = new ChangeSet();
    changeSet1.addedSource(source);
    _context.applyChanges(changeSet1);
    expect(_context.sourcesNeedingProcessing.contains(source), isTrue);
    Source source2 =
        new FileBasedSource.con1(FileUtilities2.createFile("/test2.dart"));
    ChangeSet changeSet2 = new ChangeSet();
    changeSet2.addedSource(source2);
    changeSet2.changedRange(source, 'library test;', 0, 0, 13);
    _context.applyChanges(changeSet2);
    return pumpEventQueue().then((_) {
      listener.assertEvent(wereSourcesAdded: true);
      listener.assertEvent(wereSourcesAdded: true, changedSources: [source]);
      listener.assertNoMoreEvents();
    });
  }

  void test_computeDocumentationComment_null() {
    expect(_context.computeDocumentationComment(null), isNull);
  }

  void test_computeExportedLibraries_none() {
    Source source = _addSource("/test.dart", "library test;");
    expect(_context.computeExportedLibraries(source), hasLength(0));
  }

  void test_computeExportedLibraries_some() {
    //    addSource("/lib1.dart", "library lib1;");
    //    addSource("/lib2.dart", "library lib2;");
    Source source = _addSource(
        "/test.dart", "library test; export 'lib1.dart'; export 'lib2.dart';");
    expect(_context.computeExportedLibraries(source), hasLength(2));
  }

  void test_computeHtmlElement_nonHtml() {
    Source source = _addSource("/test.dart", "library test;");
    expect(_context.computeHtmlElement(source), isNull);
  }

  void test_computeKindOf_library() {
    Source source = _addSource("/test.dart", "library lib;");
    expect(_context.computeKindOf(source), same(SourceKind.LIBRARY));
  }

  void test_computeKindOf_libraryAndPart() {
    Source source = _addSource("/test.dart", "library lib; part of lib;");
    expect(_context.computeKindOf(source), same(SourceKind.LIBRARY));
  }

  void test_computeKindOf_part() {
    Source source = _addSource("/test.dart", "part of lib;");
    expect(_context.computeKindOf(source), same(SourceKind.PART));
  }

  void test_computeLineInfo_dart() {
    Source source = _addSource("/test.dart", r'''
library lib;

main() {}''');
    LineInfo info = _context.computeLineInfo(source);
    expect(info, isNotNull);
  }

  void test_computeLineInfo_html() {
    Source source = _addSource("/test.html", r'''
<html>
  <body>
    <h1>A</h1>
  </body>
</html>''');
    LineInfo info = _context.computeLineInfo(source);
    expect(info, isNotNull);
  }

  void test_dispose() {
    expect(_context.isDisposed, isFalse);
    _context.dispose();
    expect(_context.isDisposed, isTrue);
  }

  void test_exists_false() {
    TestSource source = new TestSource();
    source.exists2 = false;
    expect(_context.exists(source), isFalse);
  }

  void test_exists_null() {
    expect(_context.exists(null), isFalse);
  }

  void test_exists_overridden() {
    Source source = new TestSource();
    _context.setContents(source, "");
    expect(_context.exists(source), isTrue);
  }

  void test_exists_true() {
    expect(_context.exists(new AnalysisContextImplTest_Source_exists_true()),
        isTrue);
  }

  void test_getAnalysisOptions() {
    expect(_context.analysisOptions, isNotNull);
  }

  void test_getContents_fromSource() {
    String content = "library lib;";
    TimestampedData<String> contents =
        _context.getContents(new TestSource('/test.dart', content));
    expect(contents.data.toString(), content);
  }

  void test_getContents_overridden() {
    String content = "library lib;";
    Source source = new TestSource();
    _context.setContents(source, content);
    TimestampedData<String> contents = _context.getContents(source);
    expect(contents.data.toString(), content);
  }

  void test_getContents_unoverridden() {
    String content = "library lib;";
    Source source = new TestSource('/test.dart', content);
    _context.setContents(source, "part of lib;");
    _context.setContents(source, null);
    TimestampedData<String> contents = _context.getContents(source);
    expect(contents.data.toString(), content);
  }

  void test_getDeclaredVariables() {
    _context = contextWithCore();
    expect(_context.declaredVariables, isNotNull);
  }

  void test_getElement() {
    _context = contextWithCore();
    _sourceFactory = _context.sourceFactory;
    LibraryElement core =
        _context.computeLibraryElement(_sourceFactory.forUri("dart:core"));
    expect(core, isNotNull);
    ClassElement classObject =
        _findClass(core.definingCompilationUnit, "Object");
    expect(classObject, isNotNull);
    ElementLocation location = classObject.location;
    Element element = _context.getElement(location);
    expect(element, same(classObject));
  }

  void test_getHtmlElement_dart() {
    Source source = _addSource("/test.dart", "");
    expect(_context.getHtmlElement(source), isNull);
    expect(_context.computeHtmlElement(source), isNull);
    expect(_context.getHtmlElement(source), isNull);
  }

  void test_getHtmlFilesReferencing_html() {
    _context = contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source htmlSource = _addSource("/test.html", r'''
<html><head>
<script type='application/dart' src='test.dart'/>
<script type='application/dart' src='test.js'/>
</head></html>''');
    Source librarySource = _addSource("/test.dart", "library lib;");
    Source secondHtmlSource = _addSource("/test.html", "<html></html>");
    _context.computeLibraryElement(librarySource);
    List<Source> result = _context.getHtmlFilesReferencing(secondHtmlSource);
    expect(result, hasLength(0));
    _context.parseHtmlUnit(htmlSource);
    result = _context.getHtmlFilesReferencing(secondHtmlSource);
    expect(result, hasLength(0));
  }

  void test_getKindOf_library() {
    Source source = _addSource("/test.dart", "library lib;");
    expect(_context.getKindOf(source), same(SourceKind.UNKNOWN));
    _context.computeKindOf(source);
    expect(_context.getKindOf(source), same(SourceKind.LIBRARY));
  }

  void test_getKindOf_part() {
    Source source = _addSource("/test.dart", "part of lib;");
    expect(_context.getKindOf(source), same(SourceKind.UNKNOWN));
    _context.computeKindOf(source);
    expect(_context.getKindOf(source), same(SourceKind.PART));
  }

  void test_getKindOf_unknown() {
    Source source = _addSource("/test.css", "");
    expect(_context.getKindOf(source), same(SourceKind.UNKNOWN));
  }

  void test_getLaunchableClientLibrarySources_doesNotImportHtml() {
    _context = contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source source = _addSource("/test.dart", r'''
main() {}''');
    _context.computeLibraryElement(source);
    List<Source> sources = _context.launchableClientLibrarySources;
    expect(sources, isEmpty);
  }

  void test_getLaunchableClientLibrarySources_importsHtml_explicitly() {
    _context = contextWithCore();
    _sourceFactory = _context.sourceFactory;
    List<Source> sources = _context.launchableClientLibrarySources;
    expect(sources, isEmpty);
    Source source = _addSource("/test.dart", r'''
import 'dart:html';
main() {}''');
    _context.computeLibraryElement(source);
    sources = _context.launchableClientLibrarySources;
    expect(sources, unorderedEquals([source]));
  }

  void test_getLaunchableClientLibrarySources_importsHtml_implicitly() {
    _context = contextWithCore();
    _sourceFactory = _context.sourceFactory;
    List<Source> sources = _context.launchableClientLibrarySources;
    expect(sources, isEmpty);
    _addSource("/a.dart", r'''
import 'dart:html';
''');
    Source source = _addSource("/test.dart", r'''
import 'a.dart';
main() {}''');
    _context.computeLibraryElement(source);
    sources = _context.launchableClientLibrarySources;
    expect(sources, unorderedEquals([source]));
  }

  void test_getLaunchableClientLibrarySources_importsHtml_implicitly2() {
    _context = contextWithCore();
    _sourceFactory = _context.sourceFactory;
    List<Source> sources = _context.launchableClientLibrarySources;
    expect(sources, isEmpty);
    _addSource("/a.dart", r'''
export 'dart:html';
''');
    Source source = _addSource("/test.dart", r'''
import 'a.dart';
main() {}''');
    _context.computeLibraryElement(source);
    sources = _context.launchableClientLibrarySources;
    expect(sources, unorderedEquals([source]));
  }

  void test_getLaunchableServerLibrarySources() {
    _context = contextWithCore();
    _sourceFactory = _context.sourceFactory;
    List<Source> sources = _context.launchableServerLibrarySources;
    expect(sources, hasLength(0));
    Source source = _addSource("/test.dart", "main() {}");
    _context.computeLibraryElement(source);
    sources = _context.launchableServerLibrarySources;
    expect(sources, hasLength(1));
  }

  void test_getLibrariesDependingOn() {
    _context = contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source libASource = _addSource("/libA.dart", "library libA;");
    _addSource("/libB.dart", "library libB;");
    Source lib1Source = _addSource("/lib1.dart", r'''
library lib1;
import 'libA.dart';
export 'libB.dart';''');
    Source lib2Source = _addSource("/lib2.dart", r'''
library lib2;
import 'libB.dart';
export 'libA.dart';''');
    _context.computeLibraryElement(lib1Source);
    _context.computeLibraryElement(lib2Source);
    List<Source> result = _context.getLibrariesDependingOn(libASource);
    expect(result, unorderedEquals([lib1Source, lib2Source]));
  }

  void test_getLibrariesReferencedFromHtml_no() {
    _context = contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source htmlSource = _addSource("/test.html", r'''
<html><head>
<script type='application/dart' src='test.js'/>
</head></html>''');
    _addSource("/test.dart", "library lib;");
    _context.parseHtmlUnit(htmlSource);
    List<Source> result = _context.getLibrariesReferencedFromHtml(htmlSource);
    expect(result, hasLength(0));
  }

  void test_getLibrarySources() {
    List<Source> sources = _context.librarySources;
    int originalLength = sources.length;
    Source source = _addSource("/test.dart", "library lib;");
    _context.computeKindOf(source);
    sources = _context.librarySources;
    expect(sources, hasLength(originalLength + 1));
    for (Source returnedSource in sources) {
      if (returnedSource == source) {
        return;
      }
    }
    fail("The added source was not in the list of library sources");
  }

  void test_getLineInfo() {
    Source source = _addSource("/test.dart", r'''
library lib;

main() {}''');
    LineInfo info = _context.getLineInfo(source);
    expect(info, isNull);
    _context.parseCompilationUnit(source);
    info = _context.getLineInfo(source);
    expect(info, isNotNull);
  }

  void test_getModificationStamp_fromSource() {
    int stamp = 42;
    expect(_context.getModificationStamp(
        new AnalysisContextImplTest_Source_getModificationStamp_fromSource(
            stamp)), stamp);
  }

  void test_getModificationStamp_overridden() {
    int stamp = 42;
    Source source =
        new AnalysisContextImplTest_Source_getModificationStamp_overridden(
            stamp);
    _context.setContents(source, "");
    expect(stamp != _context.getModificationStamp(source), isTrue);
  }

  void test_getResolvedCompilationUnit_library_null() {
    _context = contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source source = _addSource("/lib.dart", "library lib;");
    expect(_context.getResolvedCompilationUnit(source, null), isNull);
  }

  void test_getResolvedCompilationUnit_source_html() {
    _context = contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source source = _addSource("/test.html", "<html></html>");
    expect(_context.getResolvedCompilationUnit2(source, source), isNull);
    expect(_context.resolveCompilationUnit2(source, source), isNull);
    expect(_context.getResolvedCompilationUnit2(source, source), isNull);
  }

  void test_getSourceFactory() {
    expect(_context.sourceFactory, same(_sourceFactory));
  }

  void test_getSourcesWithFullName() {
    String filePath = '/foo/lib/file.dart';
    List<Source> expected = <Source>[];
    ChangeSet changeSet = new ChangeSet();

    TestSourceWithUri source1 =
        new TestSourceWithUri(filePath, Uri.parse('file://$filePath'));
    expected.add(source1);
    changeSet.addedSource(source1);

    TestSourceWithUri source2 =
        new TestSourceWithUri(filePath, Uri.parse('package:foo/file.dart'));
    expected.add(source2);
    changeSet.addedSource(source2);

    _context.applyChanges(changeSet);
    expect(
        _context.getSourcesWithFullName(filePath), unorderedEquals(expected));
  }

  void test_getStatistics() {
    AnalysisContextStatistics statistics = _context.statistics;
    expect(statistics, isNotNull);
    // The following lines are fragile.
    // The values depend on the number of libraries in the SDK.
//    assertLength(0, statistics.getCacheRows());
//    assertLength(0, statistics.getExceptions());
//    assertLength(0, statistics.getSources());
  }

//  void test_resolveCompilationUnit_sourceChangeDuringResolution() {
//    _context = new _AnalysisContext_sourceChangeDuringResolution();
//    AnalysisContextFactory.initContextWithCore(_context);
//    _sourceFactory = _context.sourceFactory;
//    Source source = _addSource("/lib.dart", "library lib;");
//    CompilationUnit compilationUnit =
//        _context.resolveCompilationUnit2(source, source);
//    expect(compilationUnit, isNotNull);
//    expect(_context.getLineInfo(source), isNotNull);
//  }

  void test_isClientLibrary_dart() {
    _context = contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source source = _addSource("/test.dart", r'''
import 'dart:html';

main() {}''');
    expect(_context.isClientLibrary(source), isFalse);
    expect(_context.isServerLibrary(source), isFalse);
    _context.computeLibraryElement(source);
    expect(_context.isClientLibrary(source), isTrue);
    expect(_context.isServerLibrary(source), isFalse);
  }

  void test_isClientLibrary_html() {
    Source source = _addSource("/test.html", "<html></html>");
    expect(_context.isClientLibrary(source), isFalse);
  }

  void test_isServerLibrary_dart() {
    _context = contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source source = _addSource("/test.dart", r'''
library lib;

main() {}''');
    expect(_context.isClientLibrary(source), isFalse);
    expect(_context.isServerLibrary(source), isFalse);
    _context.computeLibraryElement(source);
    expect(_context.isClientLibrary(source), isFalse);
    expect(_context.isServerLibrary(source), isTrue);
  }

  void test_isServerLibrary_html() {
    Source source = _addSource("/test.html", "<html></html>");
    expect(_context.isServerLibrary(source), isFalse);
  }

  void test_parseCompilationUnit_html() {
    Source source = _addSource("/test.html", "<html></html>");
    expect(_context.parseCompilationUnit(source), isNull);
  }

  void test_performAnalysisTask_modifiedAfterParse() {
    // TODO(scheglov) no threads in Dart
//    Source source = _addSource("/test.dart", "library lib;");
//    int initialTime = _context.getModificationStamp(source);
//    List<Source> sources = new List<Source>();
//    sources.add(source);
//    _context.analysisPriorityOrder = sources;
//    _context.parseCompilationUnit(source);
//    while (initialTime == JavaSystem.currentTimeMillis()) {
//      Thread.sleep(1);
//      // Force the modification time to be different.
//    }
//    _context.setContents(source, "library test;");
//    JUnitTestCase.assertTrue(initialTime != _context.getModificationStamp(source));
//    _analyzeAll_assertFinished();
//    JUnitTestCase.assertNotNullMsg("performAnalysisTask failed to compute an element model", _context.getLibraryElement(source));
  }

  void test_setAnalysisOptions() {
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
    options.cacheSize = 42;
    options.dart2jsHint = false;
    options.hint = false;
    _context.analysisOptions = options;
    AnalysisOptions result = _context.analysisOptions;
    expect(result.cacheSize, options.cacheSize);
    expect(result.dart2jsHint, options.dart2jsHint);
    expect(result.hint, options.hint);
  }

  void test_setAnalysisPriorityOrder_empty() {
    _context.analysisPriorityOrder = new List<Source>();
  }

  void test_setAnalysisPriorityOrder_nonEmpty() {
    List<Source> sources = new List<Source>();
    sources.add(_addSource("/lib.dart", "library lib;"));
    _context.analysisPriorityOrder = sources;
  }

  void test_setChangedContents_notResolved() {
    _context = contextWithCore();
    AnalysisOptionsImpl options =
        new AnalysisOptionsImpl.con1(_context.analysisOptions);
    options.incremental = true;
    _context.analysisOptions = options;
    _sourceFactory = _context.sourceFactory;
    String oldCode = r'''
library lib;
int a = 0;''';
    Source librarySource = _addSource("/lib.dart", oldCode);
    int offset = oldCode.indexOf("int a") + 4;
    String newCode = r'''
library lib;
int ya = 0;''';
    _context.setChangedContents(librarySource, newCode, offset, 0, 1);
    expect(_context.getContents(librarySource).data, newCode);
    expect(_getIncrementalAnalysisCache(_context), isNull);
  }

  Future test_setContents_libraryWithPart() {
    _context = contextWithCore();
    SourcesChangedListener listener = new SourcesChangedListener();
    _context.onSourcesChanged.listen(listener.onData);
    _sourceFactory = _context.sourceFactory;
    String libraryContents1 = r'''
library lib;
part 'part.dart';
int a = 0;''';
    Source librarySource = _addSource("/lib.dart", libraryContents1);
    String partContents1 = r'''
part of lib;
int b = a;''';
    Source partSource = _addSource("/part.dart", partContents1);
    _context.computeLibraryElement(librarySource);
    IncrementalAnalysisCache incrementalCache = new IncrementalAnalysisCache(
        librarySource, librarySource, null, null, null, 0, 0, 0);
    _setIncrementalAnalysisCache(_context, incrementalCache);
    expect(_getIncrementalAnalysisCache(_context), same(incrementalCache));
    String libraryContents2 = r'''
library lib;
part 'part.dart';
int aa = 0;''';
    _context.setContents(librarySource, libraryContents2);
    expect(_context.getResolvedCompilationUnit2(partSource, librarySource),
        isNull);
    expect(_getIncrementalAnalysisCache(_context), isNull);
    return pumpEventQueue().then((_) {
      listener.assertEvent(wereSourcesAdded: true);
      listener.assertEvent(changedSources: [librarySource]);
      listener.assertEvent(wereSourcesAdded: true);
      listener.assertEvent(changedSources: [partSource]);
      listener.assertEvent(changedSources: [librarySource]);
      listener.assertNoMoreEvents();
    });
  }

  void test_setContents_null() {
    _context = contextWithCore();
    _sourceFactory = _context.sourceFactory;
    Source librarySource = _addSource("/lib.dart", r'''
library lib;
int a = 0;''');
    _context.computeLibraryElement(librarySource);
    IncrementalAnalysisCache incrementalCache = new IncrementalAnalysisCache(
        librarySource, librarySource, null, null, null, 0, 0, 0);
    _setIncrementalAnalysisCache(_context, incrementalCache);
    expect(_getIncrementalAnalysisCache(_context), same(incrementalCache));
    _context.setContents(librarySource, null);
    expect(_context.getResolvedCompilationUnit2(librarySource, librarySource),
        isNull);
    expect(_getIncrementalAnalysisCache(_context), isNull);
  }

  void test_setSourceFactory() {
    expect(_context.sourceFactory, _sourceFactory);
    SourceFactory factory = new SourceFactory([]);
    _context.sourceFactory = factory;
    expect(_context.sourceFactory, factory);
  }

  void test_updateAnalysis() {
    expect(_context.sourcesNeedingProcessing.isEmpty, isTrue);
    Source source =
        new FileBasedSource.con1(FileUtilities2.createFile("/test.dart"));
    AnalysisDelta delta = new AnalysisDelta();
    delta.setAnalysisLevel(source, AnalysisLevel.ALL);
    _context.applyAnalysisDelta(delta);
    expect(_context.sourcesNeedingProcessing.contains(source), isTrue);
    delta = new AnalysisDelta();
    delta.setAnalysisLevel(source, AnalysisLevel.NONE);
    _context.applyAnalysisDelta(delta);
    expect(_context.sourcesNeedingProcessing.contains(source), isFalse);
  }

  void xtest_performAnalysisTask_stress() {
    int maxCacheSize = 4;
    AnalysisOptionsImpl options =
        new AnalysisOptionsImpl.con1(_context.analysisOptions);
    options.cacheSize = maxCacheSize;
    _context.analysisOptions = options;
    int sourceCount = maxCacheSize + 2;
    List<Source> sources = new List<Source>();
    ChangeSet changeSet = new ChangeSet();
    for (int i = 0; i < sourceCount; i++) {
      Source source = _addSource("/lib$i.dart", "library lib$i;");
      sources.add(source);
      changeSet.addedSource(source);
    }
    _context.applyChanges(changeSet);
    _context.analysisPriorityOrder = sources;
    for (int i = 0; i < 1000; i++) {
      List<ChangeNotice> notice = _context.performAnalysisTask().changeNotices;
      if (notice == null) {
        //System.out.println("test_performAnalysisTask_stress: " + i);
        break;
      }
    }
    List<ChangeNotice> notice = _context.performAnalysisTask().changeNotices;
    if (notice != null) {
      fail(
          "performAnalysisTask failed to terminate after analyzing all sources");
    }
  }

  Source _addSource(String fileName, String contents) {
    Source source =
        new FileBasedSource.con1(FileUtilities2.createFile(fileName));
    ChangeSet changeSet = new ChangeSet();
    changeSet.addedSource(source);
    _context.applyChanges(changeSet);
    _context.setContents(source, contents);
    return source;
  }

  TestSource _addSourceWithException(String fileName) {
    return _addSourceWithException2(fileName, "");
  }

  TestSource _addSourceWithException2(String fileName, String contents) {
    TestSource source = new TestSource(fileName, contents);
    source.generateExceptionOnRead = true;
    ChangeSet changeSet = new ChangeSet();
    changeSet.addedSource(source);
    _context.applyChanges(changeSet);
    return source;
  }

  /**
   * Perform analysis tasks up to 512 times and asserts that that was enough.
   */
  void _analyzeAll_assertFinished() {
    _analyzeAll_assertFinished2(512);
  }

  /**
   * Perform analysis tasks up to the given number of times and asserts that that was enough.
   *
   * @param maxIterations the maximum number of tasks to perform
   */
  void _analyzeAll_assertFinished2(int maxIterations) {
    for (int i = 0; i < maxIterations; i++) {
      List<ChangeNotice> notice = _context.performAnalysisTask().changeNotices;
      if (notice == null) {
        return;
      }
    }
    fail("performAnalysisTask failed to terminate after analyzing all sources");
  }

  void _changeSource(TestSource source, String contents) {
    source.setContents(contents);
    ChangeSet changeSet = new ChangeSet();
    changeSet.changedSource(source);
    _context.applyChanges(changeSet);
  }

  /**
   * Search the given compilation unit for a class with the given name. Return the class with the
   * given name, or `null` if the class cannot be found.
   *
   * @param unit the compilation unit being searched
   * @param className the name of the class being searched for
   * @return the class with the given name
   */
  ClassElement _findClass(CompilationUnitElement unit, String className) {
    for (ClassElement classElement in unit.types) {
      if (classElement.displayName == className) {
        return classElement;
      }
    }
    return null;
  }

  IncrementalAnalysisCache _getIncrementalAnalysisCache(
      AnalysisContextImpl context2) {
    return context2.test_incrementalAnalysisCache;
  }

  List<Source> _getPriorityOrder(AnalysisContextImpl context2) {
    return context2.test_priorityOrder;
  }

  void _performPendingAnalysisTasks([int maxTasks = 20]) {
    for (int i = 0; _context.performAnalysisTask().hasMoreWork; i++) {
      if (i > maxTasks) {
        fail('Analysis did not terminate.');
      }
    }
  }

  void _removeSource(Source source) {
    ChangeSet changeSet = new ChangeSet();
    changeSet.removedSource(source);
    _context.applyChanges(changeSet);
  }

  void _setIncrementalAnalysisCache(
      AnalysisContextImpl context, IncrementalAnalysisCache incrementalCache) {
    context.test_incrementalAnalysisCache = incrementalCache;
  }

  /**
   * Returns `true` if there is an [AnalysisError] with [ErrorSeverity.ERROR] in
   * the given [AnalysisErrorInfo].
   */
  static bool _hasAnalysisErrorWithErrorSeverity(AnalysisErrorInfo errorInfo) {
    List<AnalysisError> errors = errorInfo.errors;
    for (AnalysisError analysisError in errors) {
      if (analysisError.errorCode.errorSeverity == ErrorSeverity.ERROR) {
        return true;
      }
    }
    return false;
  }
}

class FakeSdk extends DirectoryBasedDartSdk {
  FakeSdk(JavaFile arg0) : super(arg0);

  @override
  LibraryMap initialLibraryMap(bool useDart2jsPaths) {
    LibraryMap map = new LibraryMap();
    _addLibrary(map, DartSdk.DART_ASYNC, false, "async.dart");
    _addLibrary(map, DartSdk.DART_CORE, false, "core.dart");
    _addLibrary(map, DartSdk.DART_HTML, false, "html_dartium.dart");
    _addLibrary(map, "dart:math", false, "math.dart");
    _addLibrary(map, "dart:_interceptors", true, "_interceptors.dart");
    _addLibrary(map, "dart:_js_helper", true, "_js_helper.dart");
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

class _AnalysisContextImplTest_test_applyChanges_removeContainer
    implements SourceContainer {
  Source libB;
  _AnalysisContextImplTest_test_applyChanges_removeContainer(this.libB);
  @override
  bool contains(Source source) => source == libB;
}

class _Source_getContent_throwException extends NonExistingSource {
  _Source_getContent_throwException(String name)
      : super(name, UriKind.FILE_URI);

  @override
  TimestampedData<String> get contents {
    throw 'Read error';
  }

  @override
  bool exists() => true;
}
