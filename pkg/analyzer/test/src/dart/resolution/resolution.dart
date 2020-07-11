// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/analysis/feature_set_provider.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_algebra.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/test_utilities/find_element.dart';
import 'package:analyzer/src/test_utilities/find_node.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

import '../../../generated/test_support.dart';

final isDynamicType = TypeMatcher<DynamicTypeImpl>();

final isNeverType = TypeMatcher<NeverTypeImpl>();

final isVoidType = TypeMatcher<VoidTypeImpl>();

/// Base for resolution tests.
mixin ResolutionTest implements ResourceProviderMixin {
  ResolvedUnitResult result;
  FindNode findNode;
  FindElement findElement;

  ClassElement get boolElement => typeProvider.boolElement;

  ClassElement get doubleElement => typeProvider.doubleType.element;

  InterfaceType get doubleType => typeProvider.doubleType;

  Element get dynamicElement => typeProvider.dynamicType.element;

  bool get enableUnusedElement => false;

  bool get enableUnusedLocalVariable => false;

  ClassElement get futureElement => typeProvider.futureElement;

  ClassElement get intElement => typeProvider.intType.element;

  InterfaceType get intType => typeProvider.intType;

  bool get isNullSafetySdkAndLegacyLibrary {
    if (FeatureSetProvider.isNullSafetySdk) {
      return !result.libraryElement.isNonNullableByDefault;
    }
    return false;
  }

  ClassElement get listElement => typeProvider.listElement;

  ClassElement get mapElement => typeProvider.mapElement;

  NeverElementImpl get neverElement => NeverElementImpl.instance;

  ClassElement get numElement => typeProvider.numType.element;

  ClassElement get objectElement => typeProvider.objectType.element;

  InterfaceType get objectType => typeProvider.objectType;

  ClassElement get stringElement => typeProvider.stringType.element;

  InterfaceType get stringType => typeProvider.stringType;

  TypeProvider get typeProvider => result.typeProvider;

  TypeSystemImpl get typeSystem => result.typeSystem;

  /// Whether `DartType.toString()` with nullability should be asked.
  bool get typeToStringWithNullability => false;

  VoidType get voidType => VoidTypeImpl.instance;

  void addTestFile(String content) {
    newFile('/test/lib/test.dart', content: content);
  }

  void assertAssignment(
    AssignmentExpression node, {
    @required Object operatorElement,
    @required String type,
  }) {
    assertElement(node.staticElement, operatorElement);
    assertType(node, type);
  }

  void assertAuxElement(AstNode node, Element expected) {
    var auxElements = getNodeAuxElements(node);
    expect(auxElements?.staticElement, same(expected));
  }

  void assertAuxMember(
    Expression node,
    Element expectedBase,
    Map<String, String> expectedSubstitution,
  ) {
    var actual = getNodeAuxElements(node)?.staticElement as ExecutableMember;

    expect(actual.declaration, same(expectedBase));

    assertSubstitution(actual.substitution, expectedSubstitution);
  }

  void assertBinaryExpression(
    BinaryExpression node, {
    @required Object element,
    @required String type,
  }) {
    assertElement(node.staticElement, element);
    assertType(node, type);
  }

  /// Assert that the given [identifier] is a reference to a class, in the
  /// form that is not a separate expression, e.g. in a static method
  /// invocation like `C.staticMethod()`, or a type annotation `C c = null`.
  void assertClassRef(
      SimpleIdentifier identifier, ClassElement expectedElement) {
    assertElement(identifier, expectedElement);
    assertTypeNull(identifier);
  }

  void assertConstructorElement(
      ConstructorElement expected, ConstructorElement actual) {
    if (expected is ConstructorMember && actual is ConstructorMember) {
      expect(expected.declaration, same(actual.declaration));
      // TODO(brianwilkerson) Compare the type arguments of the two members.
    } else {
      expect(expected, same(actual));
    }
  }

  void assertConstructors(ClassElement class_, List<String> expected) {
    expect(
      class_.constructors.map((c) {
        return c.getDisplayString(withNullability: false);
      }).toList(),
      unorderedEquals(expected),
    );
  }

  void assertElement(Object nodeOrElement, Object elementOrMatcher) {
    Element element;
    if (nodeOrElement is AstNode) {
      element = getNodeElement(nodeOrElement);
    } else {
      element = nodeOrElement as Element;
    }

    expect(element, _elementMatcher(elementOrMatcher));
  }

  void assertElement2(
    Object nodeOrElement, {
    @required Element declaration,
    bool isLegacy = false,
    Map<String, String> substitution = const {},
  }) {
    Element element;
    if (nodeOrElement is AstNode) {
      element = getNodeElement(nodeOrElement);
    } else {
      element = nodeOrElement as Element;
    }

    var actualDeclaration = element?.declaration;
    expect(actualDeclaration, same(declaration));

    if (element is Member) {
      expect(element.isLegacy, isLegacy);
      assertSubstitution(element.substitution, substitution);
    } else {
      if (isLegacy || substitution.isNotEmpty) {
        fail('Expected to be a Member: (${element.runtimeType}) $element');
      }
    }
  }

  void assertElementLibraryUri(Element element, String expected) {
    var uri = element.library.source.uri;
    expect('$uri', expected);
  }

  void assertElementName(Element element, String name,
      {bool isSynthetic = false, int offset}) {
    expect(element.name, name);
    expect(element.isSynthetic, isSynthetic);
    if (offset != null) {
      expect(element.nameOffset, offset);
    }
  }

  void assertElementNull(Object nodeOrElement) {
    Element element;
    if (nodeOrElement is AstNode) {
      element = getNodeElement(nodeOrElement);
    } else {
      element = nodeOrElement as Element;
    }

    expect(element, isNull);
  }

  void assertElementString(Element element, String expected) {
    var str = element.getDisplayString(
      withNullability: typeToStringWithNullability,
    );
    expect(str, expected);
  }

  void assertElementTypes(List<DartType> types, List<DartType> expected,
      {bool ordered = false}) {
    if (ordered) {
      expect(types, expected);
    } else {
      expect(types, unorderedEquals(expected));
    }
  }

  void assertElementTypeStrings(List<DartType> types, List<String> expected) {
    expect(types.map(typeString).toList(), expected);
  }

  void assertEnclosingElement(Element element, Element expectedEnclosing) {
    expect(element.enclosingElement, expectedEnclosing);
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
    path = convertPath(path);
    newFile(path, content: content);

    var result = await resolveFile(path);
    assertErrorsInResolvedUnit(result, expectedErrors);

    return result;
  }

  Future<void> assertErrorsInFile2(
    String path,
    List<ExpectedError> expectedErrors,
  ) async {
    path = convertPath(path);

    var result = await resolveFile(path);
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

  void assertFunctionExpressionInvocation(
    FunctionExpressionInvocation node, {
    @required ExecutableElement element,
    @required List<String> typeArgumentTypes,
    @required String invokeType,
    @required String type,
  }) {
    assertElement(node, element);
    assertTypeArgumentTypes(node, typeArgumentTypes);
    assertInvokeType(node, invokeType);
    assertType(node, type);
  }

  void assertHasTestErrors() {
    expect(result.errors, isNotEmpty);
  }

  void assertIdentifierTopGetRef(SimpleIdentifier ref, String name) {
    var getter = findElement.topGet(name);
    assertElement(ref, getter);

    var type = typeString(getter.returnType);
    assertType(ref, type);
  }

  void assertIdentifierTopSetRef(SimpleIdentifier ref, String name) {
    var setter = findElement.topSet(name);
    assertElement(ref, setter);

    var type = typeString(setter.parameters[0].type);
    assertType(ref, type);
  }

  void assertImportPrefix(SimpleIdentifier identifier, PrefixElement element) {
    assertElement(identifier, element);
    assertTypeNull(identifier);
  }

  void assertIndexExpression(
    IndexExpression node, {
    @required Object readElement,
    @required Object writeElement,
    @required String type,
  }) {
    var isRead = node.inGetterContext();
    var isWrite = node.inSetterContext();
    if (isRead && isWrite) {
      assertElement(node.auxiliaryElements?.staticElement, readElement);
      assertElement(node.staticElement, writeElement);
    } else if (isRead) {
      assertElement(node.staticElement, readElement);
    } else {
      expect(isWrite, isTrue);
      assertElement(node.staticElement, writeElement);
    }

    if (isRead) {
      assertType(node, type);
    } else {
      // TODO(scheglov) enforce this
//      expect(type, isNull);
//      assertTypeNull(node);
    }
  }

  void assertInstanceCreation(InstanceCreationExpression creation,
      ClassElement expectedClassElement, String expectedType,
      {String constructorName,
      bool expectedConstructorMember = false,
      Map<String, String> expectedSubstitution,
      PrefixElement expectedPrefix}) {
    String expectedClassName = expectedClassElement.name;

    ConstructorElement expectedConstructorElement;
    if (constructorName != null) {
      expectedConstructorElement =
          expectedClassElement.getNamedConstructor(constructorName);
      if (expectedConstructorElement == null) {
        fail("No constructor '$constructorName' in class"
            " '$expectedClassName'.");
      }
    } else {
      expectedConstructorElement = expectedClassElement.unnamedConstructor;
      if (expectedConstructorElement == null) {
        fail("No unnamed constructor in class '$expectedClassName'.");
      }
    }

    var actualConstructorElement = getNodeElement(creation);
    if (creation.constructorName.name != null) {
      // TODO(brianwilkerson) This used to enforce that the two elements were
      // the same object, but the changes to the AstRewriteVisitor broke that.
      // We should explore re-establishing this restriction for performance.
      assertConstructorElement(
        creation.constructorName.name.staticElement,
        actualConstructorElement,
      );
    }

    if (expectedConstructorMember) {
      expect(actualConstructorElement, const TypeMatcher<Member>());
      assertMember(creation, expectedConstructorElement, expectedSubstitution);
    } else {
      assertElement(creation, expectedConstructorElement);
    }

    assertType(creation, expectedType);

    var typeName = creation.constructorName.type;
    assertTypeName(typeName, expectedClassElement, expectedType,
        expectedPrefix: expectedPrefix);
  }

  void assertInvokeType(Expression node, String expected) {
    DartType actual;
    if (node is BinaryExpression) {
      actual = node.staticInvokeType;
    } else if (node is InvocationExpression) {
      actual = node.staticInvokeType;
    } else {
      fail('Unsupported node: (${node.runtimeType}) $node');
    }
    expect(typeString(actual), expected);
  }

  void assertInvokeTypeDynamic(InvocationExpression node) {
    DartType actual = node.staticInvokeType;
    expect(actual, isDynamicType);
  }

  void assertInvokeTypeNull(BinaryExpression node) {
    DartType actual = node.staticInvokeType;
    expect(actual, isNull);
  }

  void assertMember(
    Object elementOrNode,
    Element expectedBase,
    Map<String, String> expectedSubstitution,
  ) {
    Member actual;
    if (elementOrNode is Member) {
      actual = elementOrNode;
    } else {
      actual = getNodeElement(elementOrNode as AstNode);
    }

    expect(actual.declaration, same(expectedBase));

    assertSubstitution(actual.substitution, expectedSubstitution);
  }

  void assertMethodInvocation(
    MethodInvocation invocation,
    Element expectedElement,
    String expectedInvokeType, {
    String expectedMethodNameType,
    String expectedNameType,
    String expectedType,
    List<String> expectedTypeArguments = const <String>[],
  }) {
    MethodInvocationImpl invocationImpl = invocation;

    // TODO(scheglov) Check for Member.
    var element = invocation.methodName.staticElement;
    expect(element?.declaration, same(expectedElement));

    // TODO(scheglov) Should we enforce this?
//    if (expectedNameType == null) {
//      if (expectedElement is ExecutableElement) {
//        expectedNameType = expectedElement.type.displayName;
//      } else if (expectedElement is VariableElement) {
//        expectedNameType = expectedElement.type.displayName;
//      }
//    }
//    assertType(invocation.methodName, expectedNameType);

    assertTypeArgumentTypes(invocation, expectedTypeArguments);

    assertInvokeType(invocation, expectedInvokeType);

    expectedType ??= _extractReturnType(expectedInvokeType);
    assertType(invocation, expectedType);

    expectedMethodNameType ??= expectedInvokeType;
    assertType(invocationImpl.methodNameType, expectedMethodNameType);
  }

  void assertMethodInvocation2(
    MethodInvocation node, {
    @required Object element,
    @required List<String> typeArgumentTypes,
    @required String invokeType,
    @required String type,
  }) {
    assertElement(node.methodName, element);
    assertTypeArgumentTypes(node, typeArgumentTypes);
    assertType(node.staticInvokeType, invokeType);
    assertType(node.staticType, type);
  }

  void assertNamedParameterRef(String search, String name) {
    var ref = findNode.simple(search);
    assertElement(ref, findElement.parameter(name));
    assertTypeNull(ref);
  }

  void assertNamespaceDirectiveSelected(
    NamespaceDirective directive, {
    @required String expectedRelativeUri,
    @required String expectedUri,
  }) {
    expect(directive.selectedUriContent, expectedRelativeUri);
    expect('${directive.selectedSource.uri}', expectedUri);
  }

  Future<void> assertNoErrorsInCode(String code) async {
    addTestFile(code);
    await resolveTestFile();

    assertErrorsInResolvedUnit(result, const []);
  }

  void assertParameterElement(
    Expression expression,
    ParameterElement expected,
  ) {
    expect(expression.staticParameterElement, expected);
  }

  void assertParameterElementType(FormalParameter node, String expected) {
    var parameterElement = node.declaredElement;
    assertType(parameterElement.type, expected);
  }

  void assertPostfixExpression(
    PostfixExpression node, {
    @required Object element,
    @required String type,
  }) {
    assertElement(node.staticElement, element);
    assertType(node, type);
  }

  void assertPrefixedIdentifier(
    PrefixedIdentifier node, {
    @required Object element,
    @required String type,
  }) {
    assertElement(node.staticElement, element);
    assertType(node, type);
  }

  void assertPrefixExpression(
    PrefixExpression node, {
    @required Object element,
    @required String type,
  }) {
    assertElement(node.staticElement, element);
    assertType(node, type);
  }

  void assertPropertyAccess(
    PropertyAccess access,
    Element expectedElement,
    String expectedType,
  ) {
    assertElement(access.propertyName, expectedElement);
    assertType(access, expectedType);
  }

  void assertPropertyAccess2(
    PropertyAccess node, {
    @required Object element,
    @required String type,
  }) {
    assertElement(node.propertyName.staticElement, element);
    assertType(node.staticType, type);
  }

  void assertSimpleIdentifier(
    SimpleIdentifier node, {
    @required Object element,
    @required String type,
  }) {
    assertElement(node.staticElement, element);
    assertType(node, type);
  }

  void assertSubstitution(
    MapSubstitution substitution,
    Map<String, String> expected,
  ) {
    var actualMapString = Map.fromEntries(
      substitution.map.entries.where((entry) {
        return entry.key.enclosingElement is! ExecutableElement;
      }).map((entry) {
        return MapEntry(
          entry.key.name,
          typeString(entry.value),
        );
      }),
    );
    expect(actualMapString, expected);
  }

  void assertSuperExpression(SuperExpression superExpression) {
    // TODO(scheglov) I think `super` does not have type itself.
    // It is just a signal to look for implemented method in the supertype.
    // With mixins there isn't a type anyway.
//    assertTypeNull(superExpression);
  }

  void assertTopGetRef(String search, String name) {
    var ref = findNode.simple(search);
    assertIdentifierTopGetRef(ref, name);
  }

  void assertType(Object typeOrNode, String expected) {
    DartType actual;
    if (typeOrNode is DartType) {
      actual = typeOrNode;
    } else if (typeOrNode is Expression) {
      actual = typeOrNode.staticType;
    } else if (typeOrNode is GenericFunctionType) {
      actual = typeOrNode.type;
    } else if (typeOrNode is TypeName) {
      actual = typeOrNode.type;
    } else {
      fail('Unsupported node: (${typeOrNode.runtimeType}) $typeOrNode');
    }

    if (expected == null) {
      expect(actual, isNull);
    } else {
      expect(typeString(actual), expected);
    }
  }

  void assertTypeArgumentTypes(
    InvocationExpression node,
    List<String> expected,
  ) {
    var actual = node.typeArgumentTypes.map((t) => typeString(t)).toList();
    expect(actual, expected);
  }

  void assertTypeDynamic(Object typeOrExpression) {
    DartType actual;
    if (typeOrExpression is DartType) {
      actual = typeOrExpression;
      var type = typeOrExpression;
      expect(type, isDynamicType);
    } else {
      actual = (typeOrExpression as Expression).staticType;
    }
    expect(actual, isDynamicType);
  }

  void assertTypeLegacy(Expression expression) {
    NullabilitySuffix actual = expression.staticType.nullabilitySuffix;
    expect(actual, NullabilitySuffix.star);
  }

  void assertTypeName(
      TypeName node, Element expectedElement, String expectedType,
      {PrefixElement expectedPrefix}) {
    assertType(node, expectedType);

    if (expectedPrefix == null) {
      var name = node.name as SimpleIdentifier;
      assertElement(name, expectedElement);
      // TODO(scheglov) Should this be null?
//      assertType(name, expectedType);
    } else {
      var name = node.name as PrefixedIdentifier;
      assertImportPrefix(name.prefix, expectedPrefix);
      assertElement(name.identifier, expectedElement);

      // TODO(scheglov) This should be null, but it is not.
      // ResolverVisitor sets the tpe for `Bar` in `new foo.Bar()`. This is
      // probably wrong. It is fine for the TypeName `foo.Bar` to have a type,
      // and for `foo.Bar()` to have a type. But not a name of a type? No.
//      expect(name.identifier.staticType, isNull);
    }
  }

  void assertTypeNull(Expression node) {
    expect(node.staticType, isNull);
  }

  Matcher elementMatcher(
    Element declaration, {
    bool isLegacy = false,
    Map<String, String> substitution = const {},
  }) {
    return _ElementMatcher(
      this,
      declaration: declaration,
      isLegacy: isLegacy,
      substitution: substitution,
    );
  }

  ExpectedError error(ErrorCode code, int offset, int length,
          {String text,
          Pattern messageContains,
          List<ExpectedContextMessage> contextMessages =
              const <ExpectedContextMessage>[]}) =>
      ExpectedError(code, offset, length,
          message: text,
          messageContains: messageContains,
          expectedContextMessages: contextMessages);

  List<ExpectedError> expectedErrorsByNullability({
    @required List<ExpectedError> nullable,
    @required List<ExpectedError> legacy,
  }) {
    if (typeToStringWithNullability) {
      return nullable;
    } else {
      return legacy;
    }
  }

  AuxiliaryElements getNodeAuxElements(AstNode node) {
    if (node is IndexExpression) {
      return node.auxiliaryElements;
    } else {
      fail('Unsupported node: (${node.runtimeType}) $node');
    }
  }

  Element getNodeElement(AstNode node) {
    if (node is Annotation) {
      return node.element;
    } else if (node is AssignmentExpression) {
      return node.staticElement;
    } else if (node is BinaryExpression) {
      return node.staticElement;
    } else if (node is Declaration) {
      return node.declaredElement;
    } else if (node is ExtensionOverride) {
      return node.staticElement;
    } else if (node is FormalParameter) {
      return node.declaredElement;
    } else if (node is FunctionExpressionInvocation) {
      return node.staticElement;
    } else if (node is Identifier) {
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
    } else if (node is TypeName) {
      return node.name.staticElement;
    } else {
      fail('Unsupported node: (${node.runtimeType}) $node');
    }
  }

  ExpectedContextMessage message(String filePath, int offset, int length) =>
      ExpectedContextMessage(convertPath(filePath), offset, length);

  Future<ResolvedUnitResult> resolveFile(String path);

  /// Put the [code] into the test file, and resolve it.
  Future<void> resolveTestCode(String code) async {
    addTestFile(code);
    await resolveTestFile();
  }

  Future<void> resolveTestFile() async {
    var path = convertPath('/test/lib/test.dart');
    result = await resolveFile(path);
    findNode = FindNode(result.content, result.unit);
    findElement = FindElement(result.unit);
  }

  /// Choose the type display string, depending on whether the [result] is
  /// non-nullable or legacy.
  String typeStr(String nonNullable, String legacy) {
    if (result.libraryElement.isNonNullableByDefault) {
      return nonNullable;
    } else {
      return legacy;
    }
  }

  /// Return a textual representation of the [type] that is appropriate for
  /// tests.
  String typeString(DartType type) =>
      type.getDisplayString(withNullability: typeToStringWithNullability);

  String typeStringByNullability({
    @required String nullable,
    @required String legacy,
  }) {
    if (typeToStringWithNullability) {
      return nullable;
    } else {
      return legacy;
    }
  }

  _ElementMatcher _elementMatcher(Object elementOrMatcher) {
    if (elementOrMatcher is Element) {
      return _ElementMatcher(this, declaration: elementOrMatcher);
    } else {
      return elementOrMatcher;
    }
  }

  static String _extractReturnType(String invokeType) {
    int functionIndex = invokeType.indexOf(' Function');
    expect(functionIndex, isNonNegative);
    return invokeType.substring(0, functionIndex);
  }
}

class _ElementMatcher extends Matcher {
  final ResolutionTest test;
  final Element declaration;
  final bool isLegacy;
  final Map<String, String> substitution;

  _ElementMatcher(
    this.test, {
    this.declaration,
    this.isLegacy = false,
    this.substitution = const {},
  });

  @override
  Description describe(Description description) {
    return description
        .add('declaration: $declaration\n')
        .add('isLegacy: $isLegacy\n')
        .add('substitution: $substitution\n');
  }

  @override
  bool matches(element, Map matchState) {
    if (element is Element) {
      if (!identical(element.declaration, declaration)) {
        return false;
      }

      if (element is Member) {
        if (element.isLegacy != isLegacy) {
          return false;
        }

        test.assertSubstitution(element.substitution, substitution);
        return true;
      } else {
        return !isLegacy && substitution.isEmpty;
      }
    }
    return false;
  }
}
