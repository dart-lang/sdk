// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/handle.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:analyzer/src/generated/resolver.dart' show TypeProvider;
import 'package:analyzer/src/test_utilities/find_element.dart';
import 'package:analyzer/src/test_utilities/find_node.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test/test.dart';

import '../../../generated/test_support.dart';

final isBottomType = new TypeMatcher<BottomTypeImpl>();

final isDynamicType = new TypeMatcher<DynamicTypeImpl>();

final isVoidType = new TypeMatcher<VoidTypeImpl>();

/// Base for resolution tests.
mixin ResolutionTest implements ResourceProviderMixin {
  ResolvedUnitResult result;
  FindNode findNode;
  FindElement findElement;

  ClassElement get doubleElement => typeProvider.doubleType.element;

  InterfaceType get doubleType => typeProvider.doubleType;

  Element get dynamicElement => typeProvider.dynamicType.element;

  bool get enableUnusedElement => false;

  bool get enableUnusedLocalVariable => false;

  ClassElement get intElement => typeProvider.intType.element;

  InterfaceType get intType => typeProvider.intType;

  ClassElement get listElement => typeProvider.listElement;

  ClassElement get mapElement => typeProvider.mapElement;

  ClassElement get numElement => typeProvider.numType.element;

  InterfaceType get objectType => typeProvider.objectType;

  InterfaceType get stringType => typeProvider.stringType;

  TypeProvider get typeProvider =>
      result.unit.declaredElement.context.typeProvider;

  /// Whether `DartType.toString()` with nullability should be asked.
  bool get typeToStringWithNullability => false;

  VoidType get voidType => VoidTypeImpl.instance;

  void addTestFile(String content) {
    newFile('/test/lib/test.dart', content: content);
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

    expect(actual.baseElement, same(expectedBase));

    var actualMapString = actual.substitution.map.map(
      (k, v) => MapEntry(k.name, '$v'),
    );
    expect(actualMapString, expectedSubstitution);
  }

  /// Assert that the given [identifier] is a reference to a class, in the
  /// form that is not a separate expression, e.g. in a static method
  /// invocation like `C.staticMethod()`, or a type annotation `C c = null`.
  void assertClassRef(
      SimpleIdentifier identifier, ClassElement expectedElement) {
    assertElement(identifier, expectedElement);
    // TODO(scheglov) Enforce this.
//    assertTypeNull(identifier);
  }

  void assertConstructorElement(
      ConstructorElement expected, ConstructorElement actual) {
    if (expected is ConstructorMember && actual is ConstructorMember) {
      expect(expected.baseElement, same(actual.baseElement));
      // TODO(brianwilkerson) Compare the type arguments of the two members.
    } else {
      expect(expected, same(actual));
    }
  }

  void assertConstructors(ClassElement class_, List<String> expected) {
    expect(
      class_.constructors.map((c) => c.toString()).toList(),
      unorderedEquals(expected),
    );
  }

  void assertElement(AstNode node, Element expected) {
    Element actual = getNodeElement(node);
    actual = _unwrapHandle(actual);
    expect(actual, same(expected));
  }

  void assertElementName(Element element, String name,
      {bool isSynthetic = false, int offset}) {
    expect(element.name, name);
    expect(element.isSynthetic, isSynthetic);
    if (offset != null) {
      expect(element.nameOffset, offset);
    }
  }

  void assertElementNull(Expression node) {
    Element actual = getNodeElement(node);
    expect(actual, isNull);
  }

  void assertElementType(DartType type, DartType expected) {
    expect(type, expected);
  }

  void assertElementTypeDynamic(DartType type) {
    expect(type, isDynamicType);
  }

  void assertElementTypes(List<DartType> types, List<DartType> expected,
      {bool ordered = false}) {
    if (ordered) {
      expect(types, expected);
    } else {
      expect(types, unorderedEquals(expected));
    }
  }

  void assertElementTypeString(DartType type, String expected) {
    TypeImpl typeImpl = type;
    expect(typeImpl.toString(withNullability: typeToStringWithNullability),
        expected);
  }

  void assertElementTypeStrings(List<DartType> types, List<String> expected) {
    expect(types.map((t) => t.displayName).toList(), expected);
  }

  void assertEnclosingElement(Element element, Element expectedEnclosing) {
    expect(element.enclosingElement, expectedEnclosing);
  }

  Future<void> assertErrorsInCode(
      String code, List<ExpectedError> expectedErrors) async {
    addTestFile(code);
    await resolveTestFile();

    GatheringErrorListener errorListener = new GatheringErrorListener();
    errorListener.addAll(result.errors);
    errorListener.assertErrors(expectedErrors);
  }

  /**
   * Assert that the number of error codes in reported [errors] matches the
   * number of [expected] error codes. The order of errors is ignored.
   */
  void assertErrorsWithCodes(List<AnalysisError> errors,
      [List<ErrorCode> expected = const <ErrorCode>[]]) {
    var errorListener = new GatheringErrorListener();
    for (AnalysisError error in result.errors) {
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
    errorListener.assertErrorsWithCodes(expected);
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

  void assertInstanceCreation(InstanceCreationExpression creation,
      ClassElement expectedClassElement, String expectedType,
      {String constructorName,
      bool expectedConstructorMember: false,
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

  void assertInvokeType(InvocationExpression node, String expected) {
    TypeImpl actual = node.staticInvokeType;
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
    Expression node,
    Element expectedBase,
    Map<String, String> expectedSubstitution,
  ) {
    Member actual = getNodeElement(node);

    expect(actual.baseElement, same(expectedBase));

    var actualMapString = actual.substitution.map.map(
      (k, v) => MapEntry(k.name, '$v'),
    );
    expect(actualMapString, expectedSubstitution);
  }

  void assertMethodInvocation(
    MethodInvocation invocation,
    Element expectedElement,
    String expectedInvokeType, {
    String expectedMethodNameType,
    String expectedNameType,
    String expectedType,
    List<String> expectedTypeArguments: const <String>[],
  }) {
    MethodInvocationImpl invocationImpl = invocation;

    // TODO(scheglov) Check for Member.
    var element = invocation.methodName.staticElement;
    if (element is Member) {
      element = (element as Member).baseElement;
      expect(element, same(expectedElement));
    } else {
      assertElement(invocation.methodName, expectedElement);
    }

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
    assertElementTypeString(
        invocationImpl.methodNameType, expectedMethodNameType);
  }

  void assertNamedParameterRef(String search, String name) {
    var ref = findNode.simple(search);
    assertElement(ref, findElement.parameter(name));
    assertTypeNull(ref);
  }

  Future<void> assertNoErrorsInCode(String code) async {
    addTestFile(code);
    await resolveTestFile();
    assertNoTestErrors();
  }

  void assertNoTestErrors() {
    assertTestErrorsWithCodes(const <ErrorCode>[]);
  }

  void assertParameterElement(
    Expression expression,
    ParameterElement expected,
  ) {
    expect(expression.staticParameterElement, expected);
  }

  void assertPropertyAccess(
    PropertyAccess access,
    Element expectedElement,
    String expectedType,
  ) {
    assertElement(access.propertyName, expectedElement);
    assertType(access, expectedType);
  }

  void assertSuperExpression(SuperExpression superExpression) {
    // TODO(scheglov) I think `super` does not have type itself.
    // It is just a signal to look for implemented method in the supertype.
    // With mixins there isn't a type anyway.
//    assertTypeNull(superExpression);
  }

  void assertTestErrorsWithCodes(List<ErrorCode> expected) {
    assertErrorsWithCodes(result.errors, expected);
  }

  void assertTopGetRef(String search, String name) {
    var ref = findNode.simple(search);
    assertIdentifierTopGetRef(ref, name);
  }

  void assertType(AstNode node, String expected) {
    TypeImpl actual;
    if (node is Expression) {
      actual = node.staticType;
    } else if (node is GenericFunctionType) {
      actual = node.type;
    } else if (node is TypeName) {
      actual = node.type;
    } else {
      fail('Unsupported node: (${node.runtimeType}) $node');
    }
    expect(typeString(actual), expected);
  }

  void assertTypeArgumentTypes(
    InvocationExpression node,
    List<String> expected,
  ) {
    var actual = node.typeArgumentTypes.map((t) => typeString(t)).toList();
    expect(actual, expected);
  }

  void assertTypeDynamic(Expression expression) {
    DartType actual = expression.staticType;
    expect(actual, isDynamicType);
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

  ExpectedError error(ErrorCode code, int offset, int length,
          {List<ExpectedMessage> expectedMessages =
              const <ExpectedMessage>[]}) =>
      ExpectedError(code, offset, length, expectedMessages: expectedMessages);

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
      return node.staticElement;
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

  ExpectedMessage message(String filePath, int offset, int length) =>
      ExpectedMessage(convertPath(filePath), offset, length);

  Future<ResolvedUnitResult> resolveFile(String path);

  /// Put the [code] into the test file, and resolve it.
  Future<void> resolveTestCode(String code) async {
    addTestFile(code);
    await resolveTestFile();
  }

  Future<void> resolveTestFile() async {
    var path = convertPath('/test/lib/test.dart');
    result = await resolveFile(path);
    findNode = new FindNode(result.content, result.unit);
    findElement = new FindElement(result.unit);
  }

  /// Return a textual representation of the [type] that is appropriate for
  /// tests.
  String typeString(DartType type) => (type as TypeImpl)
      ?.toString(withNullability: typeToStringWithNullability);

  Element _unwrapHandle(Element element) {
    if (element is ElementHandle && element is! Member) {
      return element.actualElement;
    }
    return element;
  }

  static String _extractReturnType(String invokeType) {
    int functionIndex = invokeType.indexOf(' Function');
    expect(functionIndex, isNonNegative);
    return invokeType.substring(0, functionIndex);
  }
}
