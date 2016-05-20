// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.generated.analysis_context_factory;

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/context/context.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_engine_io.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/sdk_io.dart' show DirectoryBasedDartSdk;
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/testing/ast_factory.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:analyzer/src/generated/testing/test_type_provider.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/string_source.dart';
import 'package:unittest/unittest.dart';

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
   * Return the context that was created.
   */
  static InternalAnalysisContext contextWithCore() {
    AnalysisContextForTests context = new AnalysisContextForTests();
    return initContextWithCore(context);
  }

  /**
   * Create an analysis context that uses the given [options] and has a fake
   * core library already resolved. Return the context that was created.
   */
  static InternalAnalysisContext contextWithCoreAndOptions(
      AnalysisOptions options) {
    AnalysisContextForTests context = new AnalysisContextForTests();
    context._internalSetAnalysisOptions(options);
    return initContextWithCore(context);
  }

  static InternalAnalysisContext contextWithCoreAndPackages(
      Map<String, String> packages) {
    AnalysisContextForTests context = new AnalysisContextForTests();
    return initContextWithCore(context, new TestPackageUriResolver(packages));
  }

  /**
   * Initialize the given analysis context with a fake core library already resolved.
   *
   * @param context the context to be initialized (not `null`)
   * @return the analysis context that was created
   */
  static InternalAnalysisContext initContextWithCore(
      InternalAnalysisContext context,
      [UriResolver contributedResolver]) {
    DirectoryBasedDartSdk sdk = new _AnalysisContextFactory_initContextWithCore(
        new JavaFile("/fake/sdk"),
        enableAsync: context.analysisOptions.enableAsync);
    List<UriResolver> resolvers = <UriResolver>[
      new DartUriResolver(sdk),
      new FileUriResolver()
    ];
    if (contributedResolver != null) {
      resolvers.add(contributedResolver);
    }
    SourceFactory sourceFactory = new SourceFactory(resolvers);
    context.sourceFactory = sourceFactory;
    AnalysisContext coreContext = sdk.context;
    (coreContext.analysisOptions as AnalysisOptionsImpl).strongMode =
        context.analysisOptions.strongMode;
    //
    // dart:core
    //
    TestTypeProvider provider = new TestTypeProvider();
    CompilationUnitElementImpl coreUnit =
        new CompilationUnitElementImpl("core.dart");
    Source coreSource = sourceFactory.forUri(DartSdk.DART_CORE);
    coreContext.setContents(coreSource, "");
    coreUnit.librarySource = coreUnit.source = coreSource;
    ClassElementImpl proxyClassElement = ElementFactory.classElement2("_Proxy");
    proxyClassElement.constructors = <ConstructorElement>[
      ElementFactory.constructorElement(proxyClassElement, '', true)
        ..isCycleFree = true
        ..constantInitializers = <ConstructorInitializer>[]
    ];
    ClassElement objectClassElement = provider.objectType.element;
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
      objectClassElement,
      proxyClassElement,
      provider.stackTraceType.element,
      provider.stringType.element,
      provider.symbolType.element,
      provider.typeType.element
    ];
    coreUnit.functions = <FunctionElement>[
      ElementFactory.functionElement3("identical", provider.boolType.element,
          <ClassElement>[objectClassElement, objectClassElement], null),
      ElementFactory.functionElement3("print", VoidTypeImpl.instance.element,
          <ClassElement>[objectClassElement], null)
    ];
    TopLevelVariableElement proxyTopLevelVariableElt = ElementFactory
        .topLevelVariableElement3("proxy", true, false, proxyClassElement.type);
    ConstTopLevelVariableElementImpl deprecatedTopLevelVariableElt =
        ElementFactory.topLevelVariableElement3(
            "deprecated", true, false, provider.deprecatedType);
    {
      ClassElement deprecatedElement = provider.deprecatedType.element;
      InstanceCreationExpression initializer = AstFactory
          .instanceCreationExpression2(
              Keyword.CONST,
              AstFactory.typeName(deprecatedElement),
              [AstFactory.string2('next release')]);
      ConstructorElement constructor = deprecatedElement.constructors.single;
      initializer.staticElement = constructor;
      initializer.constructorName.staticElement = constructor;
      deprecatedTopLevelVariableElt.constantInitializer = initializer;
    }
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
    Source asyncSource;
    LibraryElementImpl asyncLibrary;
    if (context.analysisOptions.enableAsync) {
      asyncLibrary = new LibraryElementImpl.forNode(
          coreContext, AstFactory.libraryIdentifier2(["dart", "async"]));
      CompilationUnitElementImpl asyncUnit =
          new CompilationUnitElementImpl("async.dart");
      asyncSource = sourceFactory.forUri(DartSdk.DART_ASYNC);
      coreContext.setContents(asyncSource, "");
      asyncUnit.librarySource = asyncUnit.source = asyncSource;
      asyncLibrary.definingCompilationUnit = asyncUnit;
      // Future
      ClassElementImpl futureElement =
          ElementFactory.classElement2("Future", ["T"]);
      futureElement.enclosingElement = asyncUnit;
      //   factory Future.value([value])
      ConstructorElementImpl futureConstructor =
          ElementFactory.constructorElement2(futureElement, "value");
      futureConstructor.parameters = <ParameterElement>[
        ElementFactory.positionalParameter2("value", provider.dynamicType)
      ];
      futureConstructor.factory = true;
      futureElement.constructors = <ConstructorElement>[futureConstructor];
      //   Future then(onValue(T value), { Function onError });
      TypeDefiningElement futureThenR = DynamicElementImpl.instance;
      if (context.analysisOptions.strongMode) {
        futureThenR = ElementFactory.typeParameterWithType('R');
      }
      FunctionElementImpl thenOnValue = ElementFactory.functionElement3(
          'onValue', futureThenR, [futureElement.typeParameters[0]], null);
      thenOnValue.synthetic = true;

      DartType futureRType = futureElement.type.instantiate([futureThenR.type]);
      MethodElementImpl thenMethod = ElementFactory
          .methodElementWithParameters(futureElement, "then", futureRType, [
        ElementFactory.requiredParameter2("onValue", thenOnValue.type),
        ElementFactory.namedParameter2("onError", provider.functionType)
      ]);
      if (!futureThenR.type.isDynamic) {
        thenMethod.typeParameters = [futureThenR];
      }
      thenOnValue.enclosingElement = thenMethod;
      thenOnValue.type = new FunctionTypeImpl(thenOnValue);
      (thenMethod.parameters[0] as ParameterElementImpl).type =
          thenOnValue.type;
      thenMethod.type = new FunctionTypeImpl(thenMethod);

      futureElement.methods = <MethodElement>[thenMethod];
      // Completer
      ClassElementImpl completerElement =
          ElementFactory.classElement2("Completer", ["T"]);
      ConstructorElementImpl completerConstructor =
          ElementFactory.constructorElement2(completerElement, null);
      completerElement.constructors = <ConstructorElement>[
        completerConstructor
      ];
      // StreamSubscription
      ClassElementImpl streamSubscriptionElement =
          ElementFactory.classElement2("StreamSubscription", ["T"]);
      // Stream
      ClassElementImpl streamElement =
          ElementFactory.classElement2("Stream", ["T"]);
      streamElement.constructors = <ConstructorElement>[
        ElementFactory.constructorElement2(streamElement, null)
      ];
      DartType returnType = streamSubscriptionElement.type
          .instantiate(streamElement.type.typeArguments);
      FunctionElementImpl listenOnData = ElementFactory.functionElement3(
          'onData',
          VoidTypeImpl.instance.element,
          <TypeDefiningElement>[streamElement.typeParameters[0]],
          null);
      listenOnData.synthetic = true;
      List<DartType> parameterTypes = <DartType>[listenOnData.type,];
      // TODO(brianwilkerson) This is missing the optional parameters.
      MethodElementImpl listenMethod =
          ElementFactory.methodElement('listen', returnType, parameterTypes);
      streamElement.methods = <MethodElement>[listenMethod];
      listenMethod.type = new FunctionTypeImpl(listenMethod);

      FunctionElementImpl listenParamFunction = parameterTypes[0].element;
      listenParamFunction.enclosingElement = listenMethod;
      listenParamFunction.type = new FunctionTypeImpl(listenParamFunction);
      ParameterElementImpl listenParam = listenMethod.parameters[0];
      listenParam.type = listenParamFunction.type;

      asyncUnit.types = <ClassElement>[
        completerElement,
        futureElement,
        streamElement,
        streamSubscriptionElement
      ];
    }
    //
    // dart:html
    //
    CompilationUnitElementImpl htmlUnit =
        new CompilationUnitElementImpl("html_dartium.dart");
    Source htmlSource = sourceFactory.forUri(DartSdk.DART_HTML);
    coreContext.setContents(htmlSource, "");
    htmlUnit.librarySource = htmlUnit.source = htmlSource;
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
      ElementFactory
          .methodElement("query", elementType, <DartType>[provider.stringType])
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
    TopLevelVariableElementImpl document =
        ElementFactory.topLevelVariableElement3(
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
    Source mathSource = sourceFactory.forUri(_DART_MATH);
    coreContext.setContents(mathSource, "");
    mathUnit.librarySource = mathUnit.source = mathSource;
    FunctionElement cosElement = ElementFactory.functionElement3(
        "cos",
        provider.doubleType.element,
        <ClassElement>[provider.numType.element],
        ClassElement.EMPTY_LIST);
    TopLevelVariableElement ln10Element = ElementFactory
        .topLevelVariableElement3("LN10", true, false, provider.doubleType);
    TypeParameterElement maxT =
        ElementFactory.typeParameterWithType('T', provider.numType);
    FunctionElementImpl maxElement = ElementFactory.functionElement3(
        "max", maxT, [maxT, maxT], ClassElement.EMPTY_LIST);
    maxElement.typeParameters = [maxT];
    maxElement.type = new FunctionTypeImpl(maxElement);
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
    FunctionElement sinElement = ElementFactory.functionElement3(
        "sin",
        provider.doubleType.element,
        <ClassElement>[provider.numType.element],
        ClassElement.EMPTY_LIST);
    FunctionElement sqrtElement = ElementFactory.functionElement3(
        "sqrt",
        provider.doubleType.element,
        <ClassElement>[provider.numType.element],
        ClassElement.EMPTY_LIST);
    mathUnit.accessors = <PropertyAccessorElement>[
      ln10Element.getter,
      piElement.getter
    ];
    mathUnit.functions = <FunctionElement>[
      cosElement,
      maxElement,
      sinElement,
      sqrtElement
    ];
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
    if (asyncSource != null) {
      elementMap[asyncSource] = asyncLibrary;
    }
    elementMap[htmlSource] = htmlLibrary;
    elementMap[mathSource] = mathLibrary;
    //
    // Set the public and export namespaces.  We don't use exports in the fake
    // core library so public and export namespaces are the same.
    //
    for (LibraryElementImpl library in elementMap.values) {
      Namespace namespace =
          new NamespaceBuilder().createPublicNamespaceForLibrary(library);
      library.exportNamespace = namespace;
      library.publicNamespace = namespace;
    }
    context.recordLibraryElements(elementMap);
    // Create the synthetic element for `loadLibrary`.
    for (LibraryElementImpl library in elementMap.values) {
      library.createLoadLibraryFunction(context.typeProvider);
    }
    return context;
  }
}

/**
 * An analysis context that has a fake SDK that is much smaller and faster for
 * testing purposes.
 */
class AnalysisContextForTests extends AnalysisContextImpl {
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
        currentOptions.enableStrictCallChecks != options.enableStrictCallChecks;
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
   * Creates new [AnalysisContext] using [AnalysisContextFactory].
   */
  AnalysisContextHelper([AnalysisOptionsImpl options]) {
    if (options == null) {
      options = new AnalysisOptionsImpl();
    }
    options.cacheSize = 256;
    context = AnalysisContextFactory.contextWithCoreAndOptions(options);
  }

  Source addSource(String path, String code) {
    Source source = new FileBasedSource(FileUtilities2.createFile(path));
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

class TestPackageUriResolver extends UriResolver {
  Map<String, Source> sourceMap = new HashMap<String, Source>();

  TestPackageUriResolver(Map<String, String> map) {
    map.forEach((String uri, String contents) {
      sourceMap[uri] = new StringSource(contents, '/test_pkg_source.dart');
    });
  }

  @override
  Source resolveAbsolute(Uri uri, [Uri actualUri]) {
    String uriString = uri.toString();
    return sourceMap[uriString];
  }

  @override
  Uri restoreAbsolute(Source source) => throw new UnimplementedError();
}

class _AnalysisContextFactory_initContextWithCore
    extends DirectoryBasedDartSdk {
  final bool enableAsync;
  _AnalysisContextFactory_initContextWithCore(JavaFile arg0,
      {this.enableAsync: true})
      : super(arg0);

  @override
  LibraryMap initialLibraryMap(bool useDart2jsPaths) {
    LibraryMap map = new LibraryMap();
    if (enableAsync) {
      _addLibrary(map, DartSdk.DART_ASYNC, false, "async.dart");
    }
    _addLibrary(map, DartSdk.DART_CORE, false, "core.dart");
    _addLibrary(map, DartSdk.DART_HTML, false, "html_dartium.dart");
    _addLibrary(map, AnalysisContextFactory._DART_MATH, false, "math.dart");
    _addLibrary(map, AnalysisContextFactory._DART_INTERCEPTORS, true,
        "_interceptors.dart");
    _addLibrary(
        map, AnalysisContextFactory._DART_JS_HELPER, true, "_js_helper.dart");
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
