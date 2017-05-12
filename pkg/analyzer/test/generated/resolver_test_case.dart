// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.generated.resolver_test_case;

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/source/package_map_resolver.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart' hide AnalysisResult;
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/testing/ast_test_factory.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:front_end/src/base/performace_logger.dart';
import 'package:front_end/src/incremental/byte_store.dart';
import 'package:test/test.dart';

import '../src/context/mock_sdk.dart';
import 'analysis_context_factory.dart';
import 'test_support.dart';

/**
 * An AST visitor used to verify that all of the nodes in an AST structure that
 * should have been resolved were resolved.
 */
class ResolutionVerifier extends RecursiveAstVisitor<Object> {
  /**
   * A set containing nodes that are known to not be resolvable and should
   * therefore not cause the test to fail.
   */
  final Set<AstNode> _knownExceptions;

  /**
   * A list containing all of the AST nodes that were not resolved.
   */
  List<AstNode> _unresolvedNodes = new List<AstNode>();

  /**
   * A list containing all of the AST nodes that were resolved to an element of
   * the wrong type.
   */
  List<AstNode> _wrongTypedNodes = new List<AstNode>();

  /**
   * Initialize a newly created verifier to verify that all of the identifiers
   * in the visited AST structures that are expected to have been resolved have
   * an element associated with them. Nodes in the set of [_knownExceptions] are
   * not expected to have been resolved, even if they normally would have been
   * expected to have been resolved.
   */
  ResolutionVerifier([this._knownExceptions]);

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
        node, node.staticElement, (node) => node is MethodElement);
  }

  @override
  Object visitCommentReference(CommentReference node) => null;

  @override
  Object visitCompilationUnit(CompilationUnit node) {
    node.visitChildren(this);
    return _checkResolved(
        node, node.element, (node) => node is CompilationUnitElement);
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
        prefix, prefix.staticElement, (node) => node is PrefixElement);
  }

  @override
  Object visitIndexExpression(IndexExpression node) {
    node.visitChildren(this);
    DartType targetType = node.realTarget.staticType;
    if (targetType == null || targetType.isDynamic) {
      return null;
    }
    return _checkResolved(
        node, node.staticElement, (node) => node is MethodElement);
  }

  @override
  Object visitLibraryDirective(LibraryDirective node) =>
      _checkResolved(node, node.element, (node) => node is LibraryElement);

  @override
  Object visitNamedExpression(NamedExpression node) =>
      node.expression.accept(this);

  @override
  Object visitPartDirective(PartDirective node) => _checkResolved(
      node, node.element, (node) => node is CompilationUnitElement);

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
        node, node.staticElement, (node) => node is MethodElement);
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
        node, node.staticElement, (node) => node is MethodElement);
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
    if (resolutionMap.staticTypeForExpression(node) != null &&
        resolutionMap.staticTypeForExpression(node).isDynamic &&
        node.staticElement == null) {
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

  Object _checkResolved(
      AstNode node, Element element, Predicate<Element> predicate) {
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
          return resolutionMap
              .elementDeclaredByCompilationUnit(rootCU)
              .source
              .fullName;
        } else {
          return "<unknown file- CompilationUnit.getElement() returned null>";
        }
      } else {
        return "<unknown file- CompilationUnit.getRoot() is not a CompilationUnit>";
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
   * The resource provider used by the test case.
   */
  MemoryResourceProvider resourceProvider = new MemoryResourceProvider();

  /**
   * The analysis context used to parse the compilation units being resolved.
   */
  InternalAnalysisContext analysisContext2;

  /**
   * Specifies if [assertErrors] should check for [HintCode.UNUSED_ELEMENT] and
   * [HintCode.UNUSED_FIELD].
   */
  bool enableUnusedElement = false;

  /**
   * Specifies if [assertErrors] should check for [HintCode.UNUSED_LOCAL_VARIABLE].
   */
  bool enableUnusedLocalVariable = false;

  final Map<Source, TestAnalysisResult> analysisResults = {};

  StringBuffer _logBuffer = new StringBuffer();
  FileContentOverlay fileContentOverlay = new FileContentOverlay();
  AnalysisDriver driver;

  AnalysisContext get analysisContext => analysisContext2;

  bool get enableNewAnalysisDriver => false;

  /**
   * Return a type provider that can be used to test the results of resolution.
   *
   * @return a type provider
   * @throws AnalysisException if dart:core cannot be resolved
   */
  TypeProvider get typeProvider {
    if (enableNewAnalysisDriver) {
      if (analysisResults.isEmpty) {
        fail('typeProvider can be called after computing an analysis result.');
      }
      return analysisResults.values.first.unit.element.context.typeProvider;
    } else {
      return analysisContext2.typeProvider;
    }
  }

  /**
   * Return a type system that can be used to test the results of resolution.
   *
   * @return a type system
   */
  TypeSystem get typeSystem => analysisContext2.typeSystem;

  /**
   * Add a source file with the given [filePath] in the root of the file system.
   * The file path should be absolute. The file will have the given [contents]
   * set in the content provider. Return the source representing the added file.
   */
  Source addNamedSource(String filePath, String contents) {
    filePath = resourceProvider.convertPath(filePath);
    File file = resourceProvider.newFile(filePath, contents);
    Source source = file.createSource();
    if (enableNewAnalysisDriver) {
      driver.addFile(filePath);
    } else {
      analysisContext2.setContents(source, contents);
      ChangeSet changeSet = new ChangeSet();
      changeSet.addedSource(source);
      analysisContext2.applyChanges(changeSet);
    }
    return source;
  }

  /**
   * Add a source file named 'test.dart' in the root of the file system. The
   * file will have the given [contents] set in the content provider. Return the
   * source representing the added file.
   */
  Source addSource(String contents) => addNamedSource("/test.dart", contents);

  /**
   * Assert that the number of errors reported against the given
   * [source] matches the number of errors that are given and that they have
   * the expected error codes. The order in which the errors were gathered is
   * ignored.
   */
  void assertErrors(Source source,
      [List<ErrorCode> expectedErrorCodes = const <ErrorCode>[]]) {
    TestAnalysisResult result = analysisResults[source];
    expect(result, isNotNull);

    GatheringErrorListener errorListener = new GatheringErrorListener();
    for (AnalysisError error in result.errors) {
      expect(error.source, source);
      ErrorCode errorCode = error.errorCode;
      if (!enableUnusedElement &&
          (errorCode == HintCode.UNUSED_ELEMENT ||
              errorCode == HintCode.UNUSED_FIELD)) {
        continue;
      }
      if (!enableUnusedLocalVariable &&
          (errorCode == HintCode.UNUSED_CATCH_CLAUSE ||
              errorCode == HintCode.UNUSED_CATCH_STACK ||
              errorCode == HintCode.UNUSED_LOCAL_VARIABLE)) {
        continue;
      }
      errorListener.onError(error);
    }
    errorListener.assertErrorsWithCodes(expectedErrorCodes);
  }

  /**
   * Asserts that [code] verifies, but has errors with the given error codes.
   *
   * Like [assertErrors], but takes a string of source code.
   */
  // TODO(rnystrom): Use this in more tests that have the same structure.
  Future<Null> assertErrorsInCode(String code, List<ErrorCode> errors) async {
    Source source = addSource(code);
    await computeAnalysisResult(source);
    assertErrors(source, errors);
    verify([source]);
  }

  /**
   * Asserts that [code] has errors with the given error codes.
   *
   * Like [assertErrors], but takes a string of source code.
   */
  Future<Null> assertErrorsInUnverifiedCode(
      String code, List<ErrorCode> errors) async {
    Source source = addSource(code);
    await computeAnalysisResult(source);
    assertErrors(source, errors);
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
   * Asserts that [code] has no errors or warnings.
   */
  // TODO(rnystrom): Use this in more tests that have the same structure.
  Future<Null> assertNoErrorsInCode(String code) async {
    Source source = addSource(code);
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  /**
   * @param code the code that assigns the value to the variable "v", no matter how. We check that
   *          "v" has expected static and propagated type.
   */
  void assertPropagatedAssignedType(String code, CompilationUnit unit,
      DartType expectedStaticType, DartType expectedPropagatedType) {
    SimpleIdentifier identifier = findMarkedIdentifier(code, unit, "v = ");
    expect(identifier.staticType, expectedStaticType);
    expect(identifier.propagatedType, expectedPropagatedType);
  }

  /**
   * @param code the code that iterates using variable "v". We check that
   *          "v" has expected static and propagated type.
   */
  void assertPropagatedIterationType(String code, CompilationUnit unit,
      DartType expectedStaticType, DartType expectedPropagatedType) {
    SimpleIdentifier identifier = findMarkedIdentifier(code, unit, "v in ");
    expect(identifier.staticType, expectedStaticType);
    expect(identifier.propagatedType, expectedPropagatedType);
  }

  /**
   * Check the static and propagated types of the expression marked with "; // marker" comment.
   *
   * @param code source code to analyze, with the expression to check marked with "// marker".
   * @param expectedStaticType if non-null, check actual static type is equal to this.
   * @param expectedPropagatedType if non-null, check actual static type is equal to this.
   * @throws Exception
   */
  void assertTypeOfMarkedExpression(String code, CompilationUnit unit,
      DartType expectedStaticType, DartType expectedPropagatedType) {
    SimpleIdentifier identifier =
        findMarkedIdentifier(code, unit, "; // marker");
    if (expectedStaticType != null) {
      expect(identifier.staticType, expectedStaticType);
    }
    expect(identifier.propagatedType, expectedPropagatedType);
  }

  /**
   * Change the contents of the given [source] to the given [contents].
   */
  void changeSource(Source source, String contents) {
    analysisContext2.setContents(source, contents);
    ChangeSet changeSet = new ChangeSet();
    changeSet.changedSource(source);
    analysisContext2.applyChanges(changeSet);
  }

  Future<TestAnalysisResult> computeAnalysisResult(Source source) async {
    TestAnalysisResult analysisResult;
    if (enableNewAnalysisDriver) {
      AnalysisResult result = await driver.getResult(source.fullName);
      analysisResult =
          new TestAnalysisResult(source, result.unit, result.errors);
    } else {
      analysisContext2.computeKindOf(source);
      List<Source> libraries = analysisContext2.getLibrariesContaining(source);
      if (libraries.length > 0) {
        CompilationUnit unit =
            analysisContext.resolveCompilationUnit2(source, libraries.first);
        List<AnalysisError> errors = analysisContext.computeErrors(source);
        analysisResult = new TestAnalysisResult(source, unit, errors);
      }
    }
    analysisResults[source] = analysisResult;
    return analysisResult;
  }

  /**
   * Compute the analysis result to the given [code] in '/test.dart'.
   */
  Future<TestAnalysisResult> computeTestAnalysisResult(String code) async {
    Source source = addSource(code);
    return await computeAnalysisResult(source);
  }

  /**
   * Create a library element that represents a library named `"test"` containing a single
   * empty compilation unit.
   *
   * @return the library element that was created
   */
  LibraryElementImpl createDefaultTestLibrary() =>
      createTestLibrary(AnalysisContextFactory.contextWithCore(), "test");

  /**
   * Create a source object representing a file with the given [fileName] and
   * give it an empty content. Return the source that was created.
   */
  Source createNamedSource(String fileName) {
    Source source = resourceProvider.getFile(fileName).createSource();
    analysisContext2.setContents(source, '');
    return source;
  }

  /**
   * Create a library element that represents a library with the given name containing a single
   * empty compilation unit.
   *
   * @param libraryName the name of the library to be created
   * @return the library element that was created
   */
  LibraryElementImpl createTestLibrary(
      AnalysisContext context, String libraryName,
      [List<String> typeNames]) {
    String fileName = "/test/$libraryName.dart";
    Source definingCompilationUnitSource = createNamedSource(fileName);
    List<CompilationUnitElement> sourcedCompilationUnits;
    if (typeNames == null) {
      sourcedCompilationUnits = CompilationUnitElement.EMPTY_LIST;
    } else {
      int count = typeNames.length;
      sourcedCompilationUnits = new List<CompilationUnitElement>(count);
      for (int i = 0; i < count; i++) {
        String typeName = typeNames[i];
        ClassElementImpl type =
            new ClassElementImpl.forNode(AstTestFactory.identifier3(typeName));
        String fileName = "$typeName.dart";
        CompilationUnitElementImpl compilationUnit =
            new CompilationUnitElementImpl(fileName);
        compilationUnit.source = createNamedSource(fileName);
        compilationUnit.librarySource = definingCompilationUnitSource;
        compilationUnit.types = <ClassElement>[type];
        sourcedCompilationUnits[i] = compilationUnit;
      }
    }
    CompilationUnitElementImpl compilationUnit =
        new CompilationUnitElementImpl(fileName);
    compilationUnit.librarySource =
        compilationUnit.source = definingCompilationUnitSource;
    LibraryElementImpl library = new LibraryElementImpl.forNode(
        context, AstTestFactory.libraryIdentifier2([libraryName]));
    library.definingCompilationUnit = compilationUnit;
    library.parts = sourcedCompilationUnits;
    return library;
  }

  /**
   * Return the [SimpleIdentifier] from [unit] marked by [marker] in [code].
   * The source code must have no errors and be verifiable.
   */
  SimpleIdentifier findMarkedIdentifier(
      String code, CompilationUnit unit, String marker) {
    return EngineTestCase.findNode(
        unit, code, marker, (node) => node is SimpleIdentifier);
  }

  Expression findTopLevelConstantExpression(
          CompilationUnit compilationUnit, String name) =>
      findTopLevelDeclaration(compilationUnit, name).initializer;
  VariableDeclaration findTopLevelDeclaration(
      CompilationUnit compilationUnit, String name) {
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
   * Re-create the analysis context being used by the test case.
   */
  void reset() {
    resetWith();
  }

  /**
   * Re-create the analysis context being used by the test with the either given
   * [options] or [packages].
   */
  void resetWith({AnalysisOptions options, List<List<String>> packages}) {
    if (options != null && packages != null) {
      fail('Only packages or options can be specified.');
    }
    if (enableNewAnalysisDriver) {
      options ??= new AnalysisOptionsImpl();
      DartSdk sdk = new MockSdk(resourceProvider: resourceProvider)
        ..context.analysisOptions = options;

      List<UriResolver> resolvers = <UriResolver>[
        new DartUriResolver(sdk),
        new ResourceUriResolver(resourceProvider)
      ];
      if (packages != null) {
        var packageMap = <String, List<Folder>>{};
        packages.forEach((args) {
          String name = args[0];
          String path =
              resourceProvider.convertPath('/packages/$name/$name.dart');
          String content = args[1];
          File file = resourceProvider.newFile(path, content);
          packageMap[name] = <Folder>[file.parent];
        });
        resolvers.add(new PackageMapUriResolver(resourceProvider, packageMap));
      }
      SourceFactory sourceFactory = new SourceFactory(resolvers);

      PerformanceLog log = new PerformanceLog(_logBuffer);
      AnalysisDriverScheduler scheduler = new AnalysisDriverScheduler(log);
      driver = new AnalysisDriver(
          scheduler,
          log,
          resourceProvider,
          new MemoryByteStore(),
          fileContentOverlay,
          null,
          sourceFactory,
          options);
      scheduler.start();
    } else {
      if (packages != null) {
        var packageMap = <String, String>{};
        packages.forEach((args) {
          String name = args[0];
          String content = args[1];
          packageMap['package:$name/$name.dart'] = content;
        });
        analysisContext2 = AnalysisContextFactory.contextWithCoreAndPackages(
            packageMap,
            resourceProvider: resourceProvider);
      } else if (options != null) {
        analysisContext2 = AnalysisContextFactory.contextWithCoreAndOptions(
            options,
            resourceProvider: resourceProvider);
      } else {
        analysisContext2 = AnalysisContextFactory.contextWithCore(
            resourceProvider: resourceProvider);
      }
    }
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
  LibraryElement resolve2(Source librarySource) =>
      analysisContext2.computeLibraryElement(librarySource);

  /**
   * Return the resolved compilation unit corresponding to the given source in the given library.
   *
   * @param source the source of the compilation unit to be returned
   * @param library the library in which the compilation unit is to be resolved
   * @return the resolved compilation unit
   * @throws Exception if the compilation unit could not be resolved
   */
  CompilationUnit resolveCompilationUnit(
          Source source, LibraryElement library) =>
      analysisContext2.resolveCompilationUnit(source, library);

  Future<CompilationUnit> resolveSource(String sourceText) =>
      resolveSource2('/test.dart', sourceText);

  Future<CompilationUnit> resolveSource2(
      String fileName, String sourceText) async {
    Source source = addNamedSource(fileName, sourceText);
    TestAnalysisResult analysisResult = await computeAnalysisResult(source);
    return analysisResult.unit;
  }

  Future<Source> resolveSources(List<String> sourceTexts) async {
    for (int i = 0; i < sourceTexts.length; i++) {
      Source source = addNamedSource('/lib${i + 1}.dart', sourceTexts[i]);
      await computeAnalysisResult(source);
      // reference the source if this is the last source
      if (i + 1 == sourceTexts.length) {
        return source;
      }
    }
    return null;
  }

  Future<Null> resolveWithAndWithoutExperimental(
      List<String> strSources,
      List<ErrorCode> codesWithoutExperimental,
      List<ErrorCode> codesWithExperimental) async {
    // Setup analysis context as non-experimental
    AnalysisOptionsImpl options = new AnalysisOptionsImpl();
//    options.enableDeferredLoading = false;
    resetWith(options: options);
    // Analysis and assertions
    Source source = await resolveSources(strSources);
    await computeAnalysisResult(source);
    assertErrors(source, codesWithoutExperimental);
    verify([source]);
    // Setup analysis context as experimental
    reset();
    // Analysis and assertions
    source = await resolveSources(strSources);
    await computeAnalysisResult(source);
    assertErrors(source, codesWithExperimental);
    verify([source]);
  }

  Future<Null> resolveWithErrors(
      List<String> strSources, List<ErrorCode> codes) async {
    Source source = await resolveSources(strSources);
    assertErrors(source, codes);
    verify([source]);
  }

  @override
  void setUp() {
    ElementFactory.flushStaticState();
    super.setUp();
    reset();
  }

  @override
  void tearDown() {
    analysisContext2 = null;
    AnalysisEngine.instance.clearCaches();
    super.tearDown();
  }

  /**
   * Verify that all of the identifiers in the compilation units associated with
   * the given [sources] have been resolved.
   */
  void verify(List<Source> sources) {
    ResolutionVerifier verifier = new ResolutionVerifier();
    for (Source source in sources) {
      TestAnalysisResult result = analysisResults[source];
      expect(result, isNotNull);
      result.unit.accept(verifier);
    }
    verifier.assertResolved();
  }
}

/**
 * Shared infrastructure for [StaticTypeAnalyzer2Test] and
 * [StrongModeStaticTypeAnalyzer2Test].
 */
class StaticTypeAnalyzer2TestShared extends ResolverTestCase {
  String testCode;
  Source testSource;
  CompilationUnit testUnit;

  /**
   * Looks up the identifier with [name] and validates that its type type
   * stringifies to [type] and that its generics match the given stringified
   * output.
   */
  FunctionTypeImpl expectFunctionType(String name, String type,
      {String elementTypeParams: '[]',
      String typeParams: '[]',
      String typeArgs: '[]',
      String typeFormals: '[]',
      String identifierType}) {
    identifierType ??= type;

    typeParameters(Element element) {
      if (element is ExecutableElement) {
        return element.typeParameters;
      } else if (element is ParameterElement) {
        return element.typeParameters;
      }
      fail('Wrong element type: ${element.runtimeType}');
    }

    SimpleIdentifier identifier = findIdentifier(name);
    // Element is either ExecutableElement or ParameterElement.
    var element = identifier.staticElement;
    FunctionTypeImpl functionType = (element as dynamic).type;
    expect(functionType.toString(), type);
    expect(identifier.staticType.toString(), identifierType);
    expect(typeParameters(element).toString(), elementTypeParams);
    expect(functionType.typeParameters.toString(), typeParams);
    expect(functionType.typeArguments.toString(), typeArgs);
    expect(functionType.typeFormals.toString(), typeFormals);
    return functionType;
  }

  /**
   * Looks up the identifier with [name] and validates its static [type].
   *
   * If [type] is a string, validates that the identifier's static type
   * stringifies to that text. Otherwise, [type] is used directly a [Matcher]
   * to match the type.
   *
   * If [propagatedType] is given, also validate's the identifier's propagated
   * type.
   */
  void expectIdentifierType(String name, type, [propagatedType]) {
    SimpleIdentifier identifier = findIdentifier(name);
    _expectType(identifier.staticType, type);
    if (propagatedType != null) {
      _expectType(identifier.propagatedType, propagatedType);
    }
  }

  /**
   * Looks up the initializer for the declaration containing [identifier] and
   * validates its static [type].
   *
   * If [type] is a string, validates that the identifier's static type
   * stringifies to that text. Otherwise, [type] is used directly a [Matcher]
   * to match the type.
   *
   * If [propagatedType] is given, also validate's the identifier's propagated
   * type.
   */
  void expectInitializerType(String name, type, [propagatedType]) {
    SimpleIdentifier identifier = findIdentifier(name);
    VariableDeclaration declaration =
        identifier.getAncestor((node) => node is VariableDeclaration);
    Expression initializer = declaration.initializer;
    _expectType(initializer.staticType, type);
    if (propagatedType != null) {
      _expectType(initializer.propagatedType, propagatedType);
    }
  }

  SimpleIdentifier findIdentifier(String search) {
    SimpleIdentifier identifier = EngineTestCase.findNode(
        testUnit, testCode, search, (node) => node is SimpleIdentifier);
    return identifier;
  }

  Future<Null> resolveTestUnit(String code, {bool noErrors: true}) async {
    testCode = code;
    testSource = addSource(testCode);
    TestAnalysisResult analysisResult = await computeAnalysisResult(testSource);
    if (noErrors) {
      assertNoErrors(testSource);
    }
    verify([testSource]);
    testUnit = analysisResult.unit;
  }

  /**
   * Validates that [type] matches [expected].
   *
   * If [expected] is a string, validates that the type stringifies to that
   * text. Otherwise, [expected] is used directly a [Matcher] to match the type.
   */
  _expectType(DartType type, expected) {
    if (expected is String) {
      expect(type.toString(), expected);
    } else {
      expect(type, expected);
    }
  }
}

class TestAnalysisResult {
  final Source source;
  final CompilationUnit unit;
  final List<AnalysisError> errors;
  TestAnalysisResult(this.source, this.unit, this.errors);
}
