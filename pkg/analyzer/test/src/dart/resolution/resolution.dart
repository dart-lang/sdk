// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/results.dart';
import 'package:analyzer/src/dart/constant/value.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/test_utilities/find_element2.dart';
import 'package:analyzer/src/test_utilities/find_node.dart';
import 'package:analyzer_testing/resource_provider_mixin.dart';
import 'package:analyzer_utilities/testing/tree_string_sink.dart';
import 'package:test/test.dart';

import '../../../generated/test_support.dart';
import '../../../util/diff.dart';
import '../../../util/element_printer.dart';
import '../../summary/resolved_ast_printer.dart';
import '../analysis/result_printer.dart';
import 'dart_object_printer.dart';
import 'node_text_expectations.dart';

final isDynamicType = TypeMatcher<DynamicTypeImpl>();

final isNeverType = TypeMatcher<NeverTypeImpl>();

final isVoidType = TypeMatcher<VoidTypeImpl>();

/// Base for resolution tests.
mixin ResolutionTest implements ResourceProviderMixin {
  final ResolvedNodeTextConfiguration nodeTextConfiguration =
      ResolvedNodeTextConfiguration();

  late ResolvedUnitResultImpl result;
  late FindNode findNode;
  late FindElement2 findElement2;

  final DartObjectPrinterConfiguration dartObjectPrinterConfiguration =
      DartObjectPrinterConfiguration();

  ClassElement get boolElement => typeProvider.boolElement;

  ClassElement get doubleElement => typeProvider.doubleElement;

  InterfaceType get doubleType => typeProvider.doubleType;

  Element get dynamicElement =>
      (typeProvider.dynamicType as DynamicTypeImpl).element;

  FeatureSet get featureSet => result.libraryElement.featureSet;

  ClassElement get futureElement => typeProvider.futureElement;

  InheritanceManager3 get inheritanceManager {
    var library = result.libraryElement;
    return library.session.inheritanceManager;
  }

  ClassElement get intElement => typeProvider.intElement;

  InterfaceType get intType => typeProvider.intType;

  ClassElement get listElement => typeProvider.listElement;

  ClassElement get mapElement => typeProvider.mapElement;

  NeverElementImpl get neverElement => NeverElementImpl.instance;

  ClassElement get numElement => typeProvider.numElement;

  ClassElement get objectElement => typeProvider.objectElement;

  bool get strictCasts {
    var analysisOptions = result.session.analysisContext
        .getAnalysisOptionsForFile(result.file);
    return analysisOptions.strictCasts;
  }

  ClassElement get stringElement => typeProvider.stringElement;

  InterfaceType get stringType => typeProvider.stringType;

  File get testFile;

  TypeProviderImpl get typeProvider => result.typeProvider;

  TypeSystemImpl get typeSystem => result.typeSystem;

  void addTestFile(String content) {
    newFile(testFile.path, content);
  }

  void assertDartObjectText(DartObject? object, String expected) {
    var buffer = StringBuffer();
    var sink = TreeStringSink(sink: buffer, indent: '');
    var elementPrinter = ElementPrinter(
      sink: sink,
      configuration: ElementPrinterConfiguration(),
    );
    DartObjectPrinter(
      configuration: dartObjectPrinterConfiguration,
      sink: sink,
      elementPrinter: elementPrinter,
    ).write(object as DartObjectImpl?);
    var actual = buffer.toString();
    if (actual != expected) {
      NodeTextExpectationsCollector.add(actual);
      printPrettyDiff(expected, actual);
      fail('See the difference above.');
    }
  }

  void assertElement(
    Object? nodeOrElement, {
    required Element declaration,
    Map<String, String> substitution = const {},
  }) {
    Element? element;
    if (nodeOrElement is AstNode) {
      element = getNodeElement2(nodeOrElement);
    } else {
      element = nodeOrElement as Element?;
    }

    var actualDeclaration = element?.baseElement;
    expect(actualDeclaration, same(declaration));

    if (element is SubstitutedElementImpl) {
      assertSubstitution(element.substitution, substitution);
    } else if (substitution.isNotEmpty) {
      fail('Expected to be a Member: (${element.runtimeType}) $element');
    }
  }

  void assertElementNull(Element? element) {
    expect(element, isNull);
  }

  void assertElementTypes(
    List<DartType>? types,
    List<String> expected, {
    bool ordered = false,
  }) {
    if (types == null) {
      fail('Expected types, actually null.');
    }

    var typeStrList = types.map(typeString).toList();
    if (ordered) {
      expect(typeStrList, expected);
    } else {
      expect(typeStrList, unorderedEquals(expected));
    }
  }

  Future<void> assertErrorsInCode(
    String code,
    List<ExpectedError> expectedErrors,
  ) async {
    addTestFile(code);
    await resolveTestFile();

    assertErrorsInResolvedUnit(result, expectedErrors);
  }

  Future<ResolvedUnitResult> assertErrorsInFile(
    String path,
    String content,
    List<ExpectedError> expectedErrors,
  ) async {
    var file = newFile(path, content);
    var result = await resolveFile(file);
    assertErrorsInResolvedUnit(result, expectedErrors);

    return result;
  }

  Future<void> assertErrorsInFile2(
    File file,
    List<ExpectedError> expectedErrors,
  ) async {
    var result = await resolveFile(file);
    assertErrorsInResolvedUnit(result, expectedErrors);
  }

  void assertErrorsInList(
    List<Diagnostic> diagnostics,
    List<ExpectedError> expectedErrors,
  ) {
    GatheringDiagnosticListener diagnosticListener =
        GatheringDiagnosticListener();
    diagnosticListener.addAll(diagnostics);
    diagnosticListener.assertErrors(expectedErrors);
  }

  void assertErrorsInResolvedUnit(
    ResolvedUnitResult result,
    List<ExpectedError> expectedErrors,
  ) {
    assertErrorsInList(result.diagnostics, expectedErrors);
  }

  void assertErrorsInResult(List<ExpectedError> expectedErrors) {
    assertErrorsInResolvedUnit(result, expectedErrors);
  }

  void assertHasTestErrors() {
    expect(result.diagnostics, isNotEmpty);
  }

  /// Resolve the [code], and ensure that it can be resolved without a crash,
  /// and is invalid, i.e. produces a diagnostic.
  Future<void> assertInvalidTestCode(String code) async {
    await resolveTestCode(code);
    assertHasTestErrors();
  }

  Future<void> assertNoErrorsInCode(String code) async {
    addTestFile(code);
    await resolveTestFile();

    assertErrorsInResolvedUnit(result, const []);
  }

  void assertNoErrorsInResult() {
    assertErrorsInResult(const []);
  }

  void assertParsedNodeText(AstNode node, String expected) {
    var buffer = StringBuffer();
    var sink = TreeStringSink(sink: buffer, indent: '');

    var elementPrinter = ElementPrinter(
      sink: sink,
      configuration: ElementPrinterConfiguration(),
    );

    node.accept(
      ResolvedAstPrinter(
        sink: sink,
        elementPrinter: elementPrinter,
        configuration: ResolvedNodeTextConfiguration(),
        withResolution: false,
      ),
    );

    var actual = buffer.toString();
    if (actual != expected) {
      print('-------- Actual --------');
      print('$actual------------------------');
      NodeTextExpectationsCollector.add(actual);
    }
    expect(actual, expected);
  }

  void assertResolvedLibraryResultText(
    SomeResolvedLibraryResult result,
    String expected, {
    void Function(ResolvedLibraryResultPrinterConfiguration)? configure,
  }) {
    var configuration = ResolvedLibraryResultPrinterConfiguration();
    configure?.call(configuration);

    var buffer = StringBuffer();
    var sink = TreeStringSink(sink: buffer, indent: '');
    var idProvider = IdProvider();
    ResolvedLibraryResultPrinter(
      configuration: configuration,
      sink: sink,
      idProvider: idProvider,
      elementPrinter: ElementPrinter(
        sink: sink,
        configuration: ElementPrinterConfiguration(),
      ),
    ).write(result);

    var actual = buffer.toString();
    if (actual != expected) {
      print('-------- Actual --------');
      print('$actual------------------------');
      NodeTextExpectationsCollector.add(actual);
    }
    expect(actual, expected);
  }

  void assertResolvedNodeText(AstNode node, String expected) {
    var actual = _resolvedNodeText(node);
    if (actual != expected) {
      NodeTextExpectationsCollector.add(actual);
      printPrettyDiff(expected, actual);
      fail('See the difference above.');
    }
  }

  void assertSubstitution(
    MapSubstitution substitution,
    Map<String, String> expected,
  ) {
    var actualMapString = Map.fromEntries(
      substitution.map.entries
          .where((entry) {
            return entry.key.enclosingElement is! ExecutableElement;
          })
          .map((entry) {
            return MapEntry(entry.key.name, typeString(entry.value));
          }),
    );
    expect(actualMapString, expected);
  }

  void assertType(Object? typeOrNode, String? expected) {
    DartType? actual;
    if (typeOrNode is DartType) {
      actual = typeOrNode;
    } else if (typeOrNode is Expression) {
      actual = typeOrNode.staticType;
    } else if (typeOrNode is GenericFunctionType) {
      actual = typeOrNode.type;
    } else if (typeOrNode is NamedType) {
      actual = typeOrNode.type;
    } else {
      fail('Unsupported node: (${typeOrNode.runtimeType}) $typeOrNode');
    }

    if (expected == null) {
      expect(actual, isNull);
    } else if (actual == null) {
      fail('Null, expected: $expected');
    } else {
      expect(typeString(actual), expected);
    }
  }

  void assertTypeDynamic(Object? typeOrExpression) {
    DartType? actual;
    if (typeOrExpression is DartType?) {
      actual = typeOrExpression;
      var type = typeOrExpression;
      expect(type, isDynamicType);
    } else {
      actual = (typeOrExpression as Expression).staticType;
    }
    expect(actual, isDynamicType);
  }

  void assertTypeNull(Expression node) {
    expect(node.staticType, isNull);
  }

  ExpectedError error(
    DiagnosticCode code,
    int offset,
    int length, {
    Pattern? correctionContains,
    String? text,
    List<Pattern> messageContains = const [],
    List<ExpectedContextMessage> contextMessages =
        const <ExpectedContextMessage>[],
  }) => ExpectedError(
    code,
    offset,
    length,
    correctionContains: correctionContains,
    message: text,
    messageContains: messageContains,
    expectedContextMessages: contextMessages,
  );

  Element? getNodeElement2(AstNode node) {
    if (node is Annotation) {
      return node.element;
    } else if (node is AssignmentExpression) {
      return node.element;
    } else if (node is BinaryExpression) {
      return node.element;
    } else if (node is ConstructorReference) {
      return node.constructorName.element;
    } else if (node is Declaration) {
      return node.declaredFragment?.element;
    } else if (node is ExtensionOverride) {
      return node.element;
    } else if (node is FormalParameter) {
      return node.declaredFragment?.element;
    } else if (node is FunctionExpressionInvocation) {
      return node.element;
    } else if (node is FunctionReference) {
      var function = node.function.unParenthesized;
      if (function is Identifier) {
        return function.element;
      } else if (function is PropertyAccess) {
        return function.propertyName.element;
      } else if (function is ConstructorReference) {
        return function.constructorName.element;
      } else {
        fail('Unsupported node: (${function.runtimeType}) $function');
      }
    } else if (node is Identifier) {
      return node.element;
    } else if (node is ImplicitCallReference) {
      return node.element;
    } else if (node is IndexExpression) {
      return node.element;
    } else if (node is InstanceCreationExpression) {
      return node.constructorName.element;
    } else if (node is MethodInvocation) {
      return node.methodName.element;
    } else if (node is PostfixExpression) {
      return node.element;
    } else if (node is PrefixExpression) {
      return node.element;
    } else if (node is PropertyAccess) {
      return node.propertyName.element;
    } else if (node is NamedType) {
      return node.element;
    } else {
      fail('Unsupported node: (${node.runtimeType}) $node');
    }
  }

  ExpectedContextMessage message(File file, int offset, int length) =>
      ExpectedContextMessage(file, offset, length);

  Future<ResolvedUnitResultImpl> resolveFile(File file);

  /// Resolve [file] into [result].
  Future<void> resolveFile2(File file) async {
    result = await resolveFile(file);

    findNode = FindNode(result.content, result.unit);
    findElement2 = FindElement2(result.unit);
  }

  /// Create a new file with the [path] and [content], resolve it into [result].
  Future<void> resolveFileCode(String path, String content) {
    var file = newFile(path, content);
    return resolveFile2(file);
  }

  /// Put the [code] into the test file, and resolve it.
  Future<void> resolveTestCode(String code) {
    addTestFile(code);
    return resolveTestFile();
  }

  Future<void> resolveTestFile() {
    return resolveFile2(testFile);
  }

  /// Return a textual representation of the [type] that is appropriate for
  /// tests.
  String typeString(DartType type) => type.getDisplayString();

  String _resolvedNodeText(AstNode node) {
    var buffer = StringBuffer();
    var sink = TreeStringSink(sink: buffer, indent: '');
    var elementPrinter = ElementPrinter(
      sink: sink,
      configuration: ElementPrinterConfiguration()
        ..withInterfaceTypeElements =
            nodeTextConfiguration.withInterfaceTypeElements
        ..withRedirectedConstructors =
            nodeTextConfiguration.withRedirectedConstructors
        ..withSuperConstructors = nodeTextConfiguration.withSuperConstructors,
    );
    node.accept(
      ResolvedAstPrinter(
        sink: sink,
        elementPrinter: elementPrinter,
        configuration: nodeTextConfiguration,
      ),
    );
    return buffer.toString();
  }
}

extension ResolvedUnitResultExtension on ResolvedUnitResult {
  FindElement2 get findElement2 {
    return FindElement2(unit);
  }

  FindNode get findNode {
    return FindNode(content, unit);
  }

  String get uriStr => '$uri';
}
