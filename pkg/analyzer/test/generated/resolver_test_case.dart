// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/context/packages.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/performance_logger.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_engine.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:analyzer/src/generated/testing/element_factory.dart';
import 'package:analyzer/src/source/package_map_resolver.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test/test.dart';

import '../src/dart/resolution/driver_resolution.dart';
import 'test_analysis_context.dart';
import 'test_support.dart';

const String _defaultSourceName = "/test.dart";

/// An AST visitor used to verify that all of the nodes in an AST structure that
/// should have been resolved were resolved.
class ResolutionVerifier extends RecursiveAstVisitor<void> {
  /// A set containing nodes that are known to not be resolvable and should
  /// therefore not cause the test to fail.
  final Set<AstNode> _knownExceptions;

  /// A list containing all of the AST nodes that were not resolved.
  final List<AstNode> _unresolvedNodes = <AstNode>[];

  /// A list containing all of the AST nodes that were resolved to an element of
  /// the wrong type.
  final List<AstNode> _wrongTypedNodes = <AstNode>[];

  /// Initialize a newly created verifier to verify that all of the identifiers
  /// in the visited AST structures that are expected to have been resolved have
  /// an element associated with them. Nodes in the set of [_knownExceptions]
  /// are not expected to have been resolved, even if they normally would have
  /// been expected to have been resolved.
  ResolutionVerifier([this._knownExceptions]);

  /// Assert that all of the visited identifiers were resolved.
  void assertResolved() {
    if (_unresolvedNodes.isNotEmpty || _wrongTypedNodes.isNotEmpty) {
      StringBuffer buffer = StringBuffer();
      if (_unresolvedNodes.isNotEmpty) {
        buffer.write("Failed to resolve ");
        buffer.write(_unresolvedNodes.length);
        buffer.writeln(" nodes:");
        _printNodes(buffer, _unresolvedNodes);
      }
      if (_wrongTypedNodes.isNotEmpty) {
        buffer.write("Resolved ");
        buffer.write(_wrongTypedNodes.length);
        buffer.writeln(" to the wrong type of element:");
        _printNodes(buffer, _wrongTypedNodes);
      }
      fail(buffer.toString());
    }
  }

  @override
  void visitAnnotation(Annotation node) {
    node.visitChildren(this);
    ElementAnnotation elementAnnotation = node.elementAnnotation;
    if (elementAnnotation == null) {
      if (_knownExceptions == null || !_knownExceptions.contains(node)) {
        _unresolvedNodes.add(node);
      }
    } else if (elementAnnotation is! ElementAnnotation) {
      _wrongTypedNodes.add(node);
    }
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    node.visitChildren(this);
    if (!node.operator.isUserDefinableOperator) {
      return;
    }
    DartType operandType = node.leftOperand.staticType;
    if (operandType == null || operandType.isDynamic) {
      return;
    }
    _checkResolved(node, node.staticElement, (node) => node is MethodElement);
  }

  @override
  void visitCommentReference(CommentReference node) {}

  @override
  void visitCompilationUnit(CompilationUnit node) {
    node.visitChildren(this);
    _checkResolved(
        node, node.declaredElement, (node) => node is CompilationUnitElement);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    _checkResolved(node, node.element, (node) => node is ExportElement);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    node.visitChildren(this);
    if (node.declaredElement is LibraryElement) {
      _wrongTypedNodes.add(node);
    }
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    node.visitChildren(this);
    // TODO(brianwilkerson) If we start resolving function expressions, then
    // conditionally check to see whether the node was resolved correctly.
    //checkResolved(node, node.getElement(), FunctionElement.class);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    // Not sure how to test the combinators given that it isn't an error if the
    // names are not defined.
    _checkResolved(node, node.element, (node) => node is ImportElement);
    SimpleIdentifier prefix = node.prefix;
    if (prefix == null) {
      return;
    }
    _checkResolved(
        prefix, prefix.staticElement, (node) => node is PrefixElement);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    node.visitChildren(this);
    DartType targetType = node.realTarget.staticType;
    if (targetType == null || targetType.isDynamic) {
      return;
    }
    _checkResolved(node, node.staticElement, (node) => node is MethodElement);
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {
    _checkResolved(node, node.element, (node) => node is LibraryElement);
  }

  @override
  void visitNamedExpression(NamedExpression node) {
    node.expression.accept(this);
  }

  @override
  void visitPartDirective(PartDirective node) {
    _checkResolved(
        node, node.element, (node) => node is CompilationUnitElement);
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    _checkResolved(node, node.element, (node) => node is LibraryElement);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    node.visitChildren(this);
    if (!node.operator.isUserDefinableOperator) {
      return;
    }
    DartType operandType = node.operand.staticType;
    if (operandType == null || operandType.isDynamic) {
      return;
    }
    _checkResolved(node, node.staticElement, (node) => node is MethodElement);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    SimpleIdentifier prefix = node.prefix;
    prefix.accept(this);
    DartType prefixType = prefix.staticType;
    if (prefixType == null || prefixType.isDynamic) {
      return;
    }
    _checkResolved(node, node.staticElement, null);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    node.visitChildren(this);
    if (!node.operator.isUserDefinableOperator) {
      return;
    }
    DartType operandType = node.operand.staticType;
    if (operandType == null || operandType.isDynamic) {
      return;
    }
    _checkResolved(node, node.staticElement, (node) => node is MethodElement);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    Expression target = node.realTarget;
    target.accept(this);
    DartType targetType = target.staticType;
    if (targetType == null || targetType.isDynamic) {
      return;
    }
    node.propertyName.accept(this);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name == "void") {
      return;
    }
    if (node.staticType != null &&
        node.staticType.isDynamic &&
        node.staticElement == null) {
      return;
    }
    AstNode parent = node.parent;
    if (parent is MethodInvocation) {
      MethodInvocation invocation = parent;
      if (identical(invocation.methodName, node)) {
        Expression target = invocation.realTarget;
        DartType targetType = target == null ? null : target.staticType;
        if (targetType == null || targetType.isDynamic) {
          return;
        }
      }
    }
    _checkResolved(node, node.staticElement, null);
  }

  void _checkResolved(
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
  }

  String _getFileName(AstNode node) {
    // TODO (jwren) there are two copies of this method, one here and one in
    // StaticTypeVerifier, they should be resolved into a single method
    if (node != null) {
      AstNode root = node.root;
      if (root is CompilationUnit) {
        CompilationUnit rootCU = root;
        if (rootCU.declaredElement != null) {
          return rootCU.declaredElement.source.fullName;
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

class ResolverTestCase with ResourceProviderMixin {
  /// Specifies if [assertErrors] should check for [HintCode.UNUSED_ELEMENT] and
  /// [HintCode.UNUSED_FIELD].
  bool enableUnusedElement = false;

  /// Specifies if [assertErrors] should check for
  /// [HintCode.UNUSED_LOCAL_VARIABLE].
  bool enableUnusedLocalVariable = false;

  final Map<Source, TestAnalysisResult> analysisResults = {};

  final StringBuffer _logBuffer = StringBuffer();
  FileContentOverlay fileContentOverlay = FileContentOverlay();
  AnalysisDriver driver;

  AnalysisOptions get analysisOptions => driver?.analysisOptions;

  /// The default [AnalysisOptions] that should be used by [reset].
  AnalysisOptions get defaultAnalysisOptions => AnalysisOptionsImpl();

  /// Return the list of experiments that are to be enabled for tests in this
  /// class.
  List<String> get enabledExperiments => null;

  /// Return a type provider that can be used to test the results of resolution.
  ///
  /// Throws an [AnalysisException] if `dart:core` cannot be resolved.
  TypeProvider get typeProvider {
    if (analysisResults.isEmpty) {
      fail('typeProvider called before computing an analysis result.');
    }
    return analysisResults.values.first.typeProvider;
  }

  /// Return a type system that can be used to test the results of resolution.
  TypeSystemImpl get typeSystem {
    if (analysisResults.isEmpty) {
      fail('typeSystem called before computing an analysis result.');
    }
    return analysisResults.values.first.typeSystem;
  }

  /// Add a source file with the given [filePath] in the root of the file
  /// system. The file path should be absolute. The file will have the given
  /// [contents] set in the content provider. Return the source representing the
  /// added file.
  Source addNamedSource(String filePath, String contents) {
    filePath = convertPath(filePath);
    File file = newFile(filePath, content: contents);
    Source source = file.createSource();
    driver.addFile(filePath);
    return source;
  }

  /// Add a source file named 'test.dart' in the root of the file system. The
  /// file will have the given [contents] set in the content provider. Return
  /// the source representing the added file.
  Source addSource(String contents) =>
      addNamedSource(_defaultSourceName, contents);

  /// Assert that the number of errors reported against the given
  /// [source] matches the number of errors that are given and that they have
  /// the expected error codes. The order in which the errors were gathered is
  /// ignored.
  void assertErrors(Source source,
      [List<ErrorCode> expectedErrorCodes = const <ErrorCode>[]]) {
    TestAnalysisResult result = analysisResults[source];
    expect(result, isNotNull);

    GatheringErrorListener errorListener = GatheringErrorListener();
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

  /// Asserts that [code] verifies, but has errors with the given error codes.
  ///
  /// Like [assertErrors], but takes a string of source code.
  // TODO(rnystrom): Use this in more tests that have the same structure.
  Future<void> assertErrorsInCode(String code, List<ErrorCode> errors,
      {bool verify = true, String sourceName = _defaultSourceName}) async {
    Source source = addNamedSource(sourceName, code);
    await computeAnalysisResult(source);
    assertErrors(source, errors);
    if (verify) {
      this.verify([source]);
    }
  }

  /// Asserts that [code] has errors with the given error codes.
  ///
  /// Like [assertErrors], but takes a string of source code.
  Future<void> assertErrorsInUnverifiedCode(
      String code, List<ErrorCode> errors) async {
    Source source = addSource(code);
    await computeAnalysisResult(source);
    assertErrors(source, errors);
  }

  /// Assert that no errors have been reported against the given source.
  ///
  /// @param source the source against which no errors should have been reported
  /// @throws AnalysisException if the reported errors could not be computed
  /// @throws AssertionFailedError if any errors have been reported
  void assertNoErrors(Source source) {
    assertErrors(source);
  }

  /// Asserts that [code] has no errors or warnings.
  // TODO(rnystrom): Use this in more tests that have the same structure.
  Future<void> assertNoErrorsInCode(String code) async {
    Source source = addSource(code);
    await computeAnalysisResult(source);
    assertNoErrors(source);
    verify([source]);
  }

  Future<TestAnalysisResult> computeAnalysisResult(Source source) async {
    TestAnalysisResult analysisResult;
    ResolvedUnitResult result = await driver.getResult(source.fullName);
    analysisResult = TestAnalysisResult(source, result.unit, result.errors);
    analysisResults[source] = analysisResult;
    return analysisResult;
  }

  /// Compute the analysis result to the given [code] in '/test.dart'.
  Future<TestAnalysisResult> computeTestAnalysisResult(String code) async {
    Source source = addSource(code);
    return await computeAnalysisResult(source);
  }

  /// Create a library element that represents a library named `"test"`
  /// containing a single empty compilation unit.
  ///
  /// @return the library element that was created
  LibraryElementImpl createDefaultTestLibrary() =>
      createTestLibrary(TestAnalysisContext(), "test");

  /// Return a source object representing a file with the given [fileName].
  Source createNamedSource(String fileName) {
    return getFile(fileName).createSource();
  }

  /// Create a library element that represents a library with the given name
  /// containing a single empty compilation unit.
  ///
  /// @param libraryName the name of the library to be created
  /// @return the library element that was created
  LibraryElementImpl createTestLibrary(
      AnalysisContext context, String libraryName,
      [List<String> typeNames]) {
    String fileName = convertPath("/test/$libraryName.dart");
    Source definingCompilationUnitSource = createNamedSource(fileName);
    List<CompilationUnitElement> sourcedCompilationUnits;
    if (typeNames == null) {
      sourcedCompilationUnits = const <CompilationUnitElement>[];
    } else {
      int count = typeNames.length;
      sourcedCompilationUnits = List<CompilationUnitElement>(count);
      for (int i = 0; i < count; i++) {
        String typeName = typeNames[i];
        ClassElementImpl type = ClassElementImpl(typeName, -1);
        String fileName = "$typeName.dart";
        CompilationUnitElementImpl compilationUnit =
            CompilationUnitElementImpl();
        compilationUnit.source = createNamedSource(fileName);
        compilationUnit.librarySource = definingCompilationUnitSource;
        compilationUnit.types = <ClassElement>[type];
        sourcedCompilationUnits[i] = compilationUnit;
      }
    }
    CompilationUnitElementImpl compilationUnit = CompilationUnitElementImpl();
    compilationUnit.librarySource =
        compilationUnit.source = definingCompilationUnitSource;
    var featureSet = context.analysisOptions.contextFeatures;
    LibraryElementImpl library = LibraryElementImpl(
        context,
        driver?.currentSession,
        libraryName,
        -1,
        0,
        featureSet.isEnabled(Feature.non_nullable));
    library.definingCompilationUnit = compilationUnit;
    library.parts = sourcedCompilationUnits;
    return library;
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

  /// Re-create the analysis context being used by the test case.
  void reset() {
    resetWith();
  }

  /// Re-create the analysis context being used by the test with the either
  /// given [options] or [packages].
  void resetWith({AnalysisOptions options, List<List<String>> packages}) {
    if (options != null && packages != null) {
      fail('Only packages or options can be specified.');
    }
    options ??= defaultAnalysisOptions;
    List<String> experiments = enabledExperiments;
    if (experiments != null) {
      (options as AnalysisOptionsImpl).contextFeatures =
          FeatureSet.fromEnableFlags(experiments);
    }
    DartSdk sdk = MockSdk(
      resourceProvider: resourceProvider,
      analysisOptions: options,
    );

    List<UriResolver> resolvers = <UriResolver>[
      DartUriResolver(sdk),
      ResourceUriResolver(resourceProvider)
    ];
    if (packages != null) {
      var packageMap = <String, List<Folder>>{};
      packages.forEach((args) {
        String name = args[0];
        String content = args[1];
        File file = newFile('/packages/$name/$name.dart', content: content);
        packageMap[name] = <Folder>[file.parent];
      });
      resolvers.add(PackageMapUriResolver(resourceProvider, packageMap));
    }
    SourceFactory sourceFactory = SourceFactory(resolvers);

    PerformanceLog log = PerformanceLog(_logBuffer);
    AnalysisDriverScheduler scheduler = AnalysisDriverScheduler(log);
    driver = AnalysisDriver(scheduler, log, resourceProvider, MemoryByteStore(),
        fileContentOverlay, null, sourceFactory, options,
        packages: Packages.empty);
    scheduler.start();
  }

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

  Future<void> resolveWithAndWithoutExperimental(
      List<String> strSources,
      List<ErrorCode> codesWithoutExperimental,
      List<ErrorCode> codesWithExperimental) async {
    // Setup analysis context as non-experimental
    AnalysisOptionsImpl options = AnalysisOptionsImpl();
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

  Future<void> resolveWithErrors(
      List<String> strSources, List<ErrorCode> codes) async {
    Source source = await resolveSources(strSources);
    assertErrors(source, codes);
    verify([source]);
  }

  void setUp() {
    ElementFactory.flushStaticState();
    reset();
  }

  void tearDown() {
    AnalysisEngine.instance.clearCaches();
  }

  /// Verify that all of the identifiers in the compilation units associated
  /// with the given [sources] have been resolved.
  void verify(List<Source> sources) {
    ResolutionVerifier verifier = ResolutionVerifier();
    for (Source source in sources) {
      TestAnalysisResult result = analysisResults[source];
      expect(result, isNotNull);
      result.unit.accept(verifier);
    }
    verifier.assertResolved();
  }
}

/// Shared infrastructure for [StaticTypeAnalyzer2Test] and
/// [StrongModeStaticTypeAnalyzer2Test].
class StaticTypeAnalyzer2TestShared extends DriverResolutionTest {
  /// Find the expression that starts at the offset of [search] and validate its
  /// that its static type matches the given [type].
  ///
  /// If [type] is a string, validates that the expression's static type
  /// stringifies to that text. Otherwise, [type] is used directly a [Matcher]
  /// to match the type.
  void expectExpressionType(String search, type) {
    Expression expression = findNode.expression(search);
    _expectType(expression.staticType, type);
  }

  /// Looks up the identifier with [name] and validates that its type type
  /// stringifies to [type] and that its generics match the given stringified
  /// output.
  FunctionTypeImpl expectFunctionType(String name, String type,
      {String typeParams = '[]',
      String typeArgs = '[]',
      String typeFormals = '[]',
      String identifierType}) {
    identifierType ??= type;

    String typeParametersStr(List<TypeParameterElement> elements) {
      var elementsStr = elements.map((e) {
        return e.getDisplayString(withNullability: false);
      }).join(', ');
      return '[$elementsStr]';
    }

    SimpleIdentifier identifier = findNode.simple(name);
    var functionType = _getFunctionTypedElementType(identifier);
    assertType(functionType, type);
    expect(identifier.staticType, isNull);
    expect(functionType.typeArguments.toString(), typeArgs);
    expect(typeParametersStr(functionType.typeFormals), typeFormals);
    return functionType;
  }

  /// Looks up the identifier with [name] and validates that its element type
  /// stringifies to [type] and that its generics match the given stringified
  /// output.
  FunctionTypeImpl expectFunctionType2(String name, String type) {
    var identifier = findNode.simple(name);
    var functionType = _getFunctionTypedElementType(identifier);
    assertType(functionType, type);
    return functionType;
  }

  /// Looks up the identifier with [name] and validates its static [type].
  ///
  /// If [type] is a string, validates that the identifier's static type
  /// stringifies to that text. Otherwise, [type] is used directly a [Matcher]
  /// to match the type.
  void expectIdentifierType(String name, type) {
    SimpleIdentifier identifier = findNode.simple(name);
    _expectType(identifier.staticType, type);
  }

  /// Looks up the initializer for the declaration containing [identifier] and
  /// validates its static [type].
  ///
  /// If [type] is a string, validates that the identifier's static type
  /// stringifies to that text. Otherwise, [type] is used directly a [Matcher]
  /// to match the type.
  void expectInitializerType(String name, type) {
    SimpleIdentifier identifier = findNode.simple(name);
    VariableDeclaration declaration =
        identifier.thisOrAncestorOfType<VariableDeclaration>();
    Expression initializer = declaration.initializer;
    _expectType(initializer.staticType, type);
  }

  /// Validates that [type] matches [expected].
  ///
  /// If [expected] is a string, validates that the type stringifies to that
  /// text. Otherwise, [expected] is used directly a [Matcher] to match the
  /// type.
  _expectType(DartType type, expected) {
    if (expected is String) {
      assertType(type, expected);
    } else {
      expect(type, expected);
    }
  }

  FunctionTypeImpl _getFunctionTypedElementType(SimpleIdentifier identifier) {
    var element = identifier.staticElement;
    if (element is ExecutableElement) {
      return element.type;
    } else if (element is VariableElement) {
      return element.type;
    } else {
      fail('Unexpected element: (${element.runtimeType}) $element');
    }
  }
}

class TestAnalysisResult {
  final Source source;
  final CompilationUnit unit;
  final List<AnalysisError> errors;

  TestAnalysisResult(this.source, this.unit, this.errors);

  LibraryElement get libraryElement => unit.declaredElement.library;

  TypeProvider get typeProvider => libraryElement.typeProvider;

  TypeSystemImpl get typeSystem => libraryElement.typeSystem;
}
