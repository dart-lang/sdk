// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/constant/value.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/test_utilities/find_element.dart';
import 'package:analyzer/src/test_utilities/find_node.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer_utilities/testing/tree_string_sink.dart';
import 'package:test/test.dart';

import '../../../generated/test_support.dart';
import '../../../util/element_printer.dart';
import '../../summary/macros_environment.dart';
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

  late ResolvedUnitResult result;
  late FindNode findNode;
  late FindElement findElement;

  final DartObjectPrinterConfiguration dartObjectPrinterConfiguration =
      DartObjectPrinterConfiguration();

  ClassElement get boolElement => typeProvider.boolElement;

  ClassElement get doubleElement => typeProvider.doubleElement;

  InterfaceType get doubleType => typeProvider.doubleType;

  Element get dynamicElement =>
      (typeProvider.dynamicType as DynamicTypeImpl).element;

  FeatureSet get featureSet => result.libraryElement.featureSet;

  ClassElement get futureElement => typeProvider.futureElement;

  ClassElement get intElement => typeProvider.intElement;

  InterfaceType get intType => typeProvider.intType;

  ClassElement get listElement => typeProvider.listElement;

  ClassElement get mapElement => typeProvider.mapElement;

  NeverElementImpl get neverElement => NeverElementImpl.instance;

  ClassElement get numElement => typeProvider.numElement;

  ClassElement get objectElement =>
      typeProvider.objectType.element as ClassElement;

  bool get strictCasts {
    var analysisOptions = result.session.analysisContext
        .getAnalysisOptionsForFile(result.file) as AnalysisOptionsImpl;
    return analysisOptions.strictCasts;
  }

  ClassElement get stringElement => typeProvider.stringElement;

  InterfaceType get stringType => typeProvider.stringType;

  File get testFile;

  TypeProvider get typeProvider => result.typeProvider;

  TypeSystemImpl get typeSystem => result.typeSystem as TypeSystemImpl;

  void addTestFile(String content) {
    newFile(testFile.path, content);
  }

  void assertDartObjectText(
    DartObject? object,
    String expected, {
    LibraryElement? libraryElement,
  }) {
    libraryElement ??= result.libraryElement;

    var buffer = StringBuffer();
    var sink = TreeStringSink(
      sink: buffer,
      indent: '',
    );
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
      print(actual);
      NodeTextExpectationsCollector.add(actual);
    }
    expect(actual, expected);
  }

  void assertElement(Object? nodeOrElement, Object? elementOrMatcher) {
    Element? element;
    if (nodeOrElement is AstNode) {
      element = getNodeElement(nodeOrElement);
    } else {
      element = nodeOrElement as Element?;
    }

    expect(element, _elementMatcher(elementOrMatcher));
  }

  void assertElement2(
    Object? nodeOrElement, {
    required Element declaration,
    Map<String, String> substitution = const {},
  }) {
    Element? element;
    if (nodeOrElement is AstNode) {
      element = getNodeElement(nodeOrElement);
    } else {
      element = nodeOrElement as Element?;
    }

    var actualDeclaration = element?.declaration;
    expect(actualDeclaration, same(declaration));

    if (element is Member) {
      assertSubstitution(element.substitution, substitution);
    } else if (substitution.isNotEmpty) {
      fail('Expected to be a Member: (${element.runtimeType}) $element');
    }
  }

  void assertElementNull(Object? nodeOrElement) {
    Element? element;
    if (nodeOrElement is AstNode) {
      element = getNodeElement(nodeOrElement);
    } else {
      element = nodeOrElement as Element?;
    }

    expect(element, isNull);
  }

  void assertElementString(Element element, String expected) {
    var str = element.getDisplayString();
    expect(str, expected);
  }

  void assertElementTypes(List<DartType>? types, List<String> expected,
      {bool ordered = false}) {
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

  void assertEnclosingElement(Element element, Element expectedEnclosing) {
    expect(element.enclosingElement3, expectedEnclosing);
  }

  Future<void> assertErrorsInCode(
      String code, List<ExpectedError> expectedErrors) async {
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
    List<AnalysisError> errors,
    List<ExpectedError> expectedErrors,
  ) {
    GatheringErrorListener errorListener = GatheringErrorListener();
    errorListener.addAll(errors);
    errorListener.assertErrors(expectedErrors);
  }

  void assertErrorsInResolvedUnit(
    ResolvedUnitResult result,
    List<ExpectedError> expectedErrors,
  ) {
    assertErrorsInList(result.errors, expectedErrors);
  }

  void assertErrorsInResult(List<ExpectedError> expectedErrors) {
    assertErrorsInResolvedUnit(result, expectedErrors);
  }

  void assertHasTestErrors() {
    expect(result.errors, isNotEmpty);
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
    var sink = TreeStringSink(
      sink: buffer,
      indent: '',
    );

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
      print(actual);
      NodeTextExpectationsCollector.add(actual);
    }
    expect(actual, expected);
  }

  void assertSubstitution(
    MapSubstitution substitution,
    Map<String, String> expected,
  ) {
    var actualMapString = Map.fromEntries(
      substitution.map.entries.where((entry) {
        return entry.key.enclosingElement3 is! ExecutableElement;
      }).map((entry) {
        return MapEntry(
          entry.key.name,
          typeString(entry.value),
        );
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

  ExpectedError error(ErrorCode code, int offset, int length,
          {Pattern? correctionContains,
          String? text,
          List<Pattern> messageContains = const [],
          List<ExpectedContextMessage> contextMessages =
              const <ExpectedContextMessage>[]}) =>
      ExpectedError(code, offset, length,
          correctionContains: correctionContains,
          message: text,
          messageContains: messageContains,
          expectedContextMessages: contextMessages);

  String getMacroCode(String relativePath) {
    var code = MacrosEnvironment.instance.packageAnalyzerFolder
        .getChildAssumingFile('test/src/summary/macro/$relativePath')
        .readAsStringSync();
    return code.replaceAll('/*macro*/', 'macro');
  }

  Element? getNodeElement(AstNode node) {
    if (node is Annotation) {
      return node.element;
    } else if (node is AssignmentExpression) {
      return node.staticElement;
    } else if (node is BinaryExpression) {
      return node.staticElement;
    } else if (node is ConstructorReference) {
      return node.constructorName.staticElement;
    } else if (node is Declaration) {
      return node.declaredElement;
    } else if (node is ExtensionOverride) {
      return node.element;
    } else if (node is FormalParameter) {
      return node.declaredElement;
    } else if (node is FunctionExpressionInvocation) {
      return node.staticElement;
    } else if (node is FunctionReference) {
      var function = node.function.unParenthesized;
      if (function is Identifier) {
        return function.staticElement;
      } else if (function is PropertyAccess) {
        return function.propertyName.staticElement;
      } else if (function is ConstructorReference) {
        return function.constructorName.staticElement;
      } else {
        fail('Unsupported node: (${function.runtimeType}) $function');
      }
    } else if (node is Identifier) {
      return node.staticElement;
    } else if (node is ImplicitCallReference) {
      return node.staticElement;
    } else if (node is IndexExpression) {
      return node.staticElement;
    } else if (node is InstanceCreationExpression) {
      return node.constructorName.staticElement;
    } else if (node is MethodInvocation) {
      return node.methodName.staticElement;
    } else if (node is PostfixExpression) {
      return node.staticElement;
    } else if (node is PrefixExpression) {
      return node.staticElement;
    } else if (node is PropertyAccess) {
      return node.propertyName.staticElement;
    } else if (node is NamedType) {
      return node.element;
    } else {
      fail('Unsupported node: (${node.runtimeType}) $node');
    }
  }

  ExpectedContextMessage message(File file, int offset, int length) =>
      ExpectedContextMessage(file, offset, length);

  Matcher multiplyDefinedElementMatcher(List<Element> elements) {
    return _MultiplyDefinedElementMatcher(elements);
  }

  Future<ResolvedUnitResult> resolveFile(File file);

  /// Resolve [file] into [result].
  Future<void> resolveFile2(File file) async {
    result = await resolveFile(file);

    findNode = FindNode(result.content, result.unit);
    findElement = FindElement(result.unit);
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

  Matcher _elementMatcher(Object? elementOrMatcher) {
    if (elementOrMatcher is Element) {
      return _ElementMatcher(this, declaration: elementOrMatcher);
    } else {
      return wrapMatcher(elementOrMatcher);
    }
  }

  String _resolvedNodeText(AstNode node) {
    var buffer = StringBuffer();
    var sink = TreeStringSink(
      sink: buffer,
      indent: '',
    );
    var elementPrinter = ElementPrinter(
      sink: sink,
      configuration: ElementPrinterConfiguration()
        ..withInterfaceTypeElements =
            nodeTextConfiguration.withInterfaceTypeElements
        ..withRedirectedConstructors =
            nodeTextConfiguration.withRedirectedConstructors,
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

class _ElementMatcher extends Matcher {
  final ResolutionTest test;
  final Element declaration;

  _ElementMatcher(
    this.test, {
    required this.declaration,
  });

  @override
  Description describe(Description description) {
    return description.add('declaration: $declaration\n');
  }

  @override
  bool matches(element, Map matchState) {
    if (element is Element) {
      if (!identical(element.declaration, declaration)) {
        return false;
      }

      if (element is Member) {
        test.assertSubstitution(element.substitution, const {});
        return true;
      } else {
        return true;
      }
    }
    return false;
  }
}

class _MultiplyDefinedElementMatcher extends Matcher {
  final Iterable<Element> elements;

  _MultiplyDefinedElementMatcher(this.elements);

  @override
  Description describe(Description description) {
    return description.add('elements: $elements\n');
  }

  @override
  bool matches(element, Map matchState) {
    if (element is MultiplyDefinedElementImpl) {
      var actualSet = element.conflictingElements.toSet();
      actualSet.removeAll(elements);
      return actualSet.isEmpty;
    }
    return false;
  }
}

extension ResolvedUnitResultExtension on ResolvedUnitResult {
  FindElement get findElement {
    return FindElement(unit);
  }

  FindNode get findNode {
    return FindNode(content, unit);
  }

  String get uriStr => '$uri';
}
