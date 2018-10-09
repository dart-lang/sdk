// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/element/handle.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:analyzer/src/generated/resolver.dart' show TypeProvider;
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test/test.dart';

import '../../../generated/test_support.dart';
import 'find_element.dart';
import 'find_node.dart';

final isBottomType = new TypeMatcher<BottomTypeImpl>();

final isDynamicType = new TypeMatcher<DynamicTypeImpl>();

final isUndefinedType = new TypeMatcher<UndefinedTypeImpl>();

final isVoidType = new TypeMatcher<VoidTypeImpl>();

/// Base for resolution tests.
abstract class ResolutionTest implements ResourceProviderMixin {
  TestAnalysisResult result;
  FindNode findNode;
  FindElement findElement;

  ClassElement get doubleElement => typeProvider.doubleType.element;

  InterfaceType get doubleType => typeProvider.doubleType;

  Element get dynamicElement => typeProvider.dynamicType.element;

  ClassElement get intElement => typeProvider.intType.element;

  InterfaceType get intType => typeProvider.intType;

  ClassElement get listElement => typeProvider.listType.element;

  ClassElement get mapElement => typeProvider.mapType.element;

  ClassElement get numElement => typeProvider.numType.element;

  InterfaceType get objectType => typeProvider.objectType;

  InterfaceType get stringType => typeProvider.stringType;

  TypeProvider get typeProvider =>
      result.unit.declaredElement.context.typeProvider;

  void addTestFile(String content) {
    newFile('/test/lib/test.dart', content: content);
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
    expect(type.toString(), expected);
  }

  void assertElementTypeStrings(List<DartType> types, List<String> expected) {
    expect(types.map((t) => t.displayName).toList(), expected);
  }

  void assertEnclosingElement(Element element, Element expectedEnclosing) {
    expect(element.enclosingElement, expectedEnclosing);
  }

  /**
   * Assert that the number of error codes in reported [errors] matches the
   * number of [expected] error codes. The order of errors is ignored.
   */
  void assertErrors(List<AnalysisError> errors,
      [List<ErrorCode> expected = const <ErrorCode>[]]) {
    var errorListener = new GatheringErrorListener();
    for (AnalysisError error in result.errors) {
      ErrorCode errorCode = error.errorCode;
      if (errorCode == HintCode.UNUSED_CATCH_CLAUSE ||
          errorCode == HintCode.UNUSED_CATCH_STACK ||
          errorCode == HintCode.UNUSED_ELEMENT ||
          errorCode == HintCode.UNUSED_FIELD ||
          errorCode == HintCode.UNUSED_LOCAL_VARIABLE) {
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

    var type = getter.returnType.toString();
    assertType(ref, type);
  }

  void assertIdentifierTopSetRef(SimpleIdentifier ref, String name) {
    var setter = findElement.topSet(name);
    assertElement(ref, setter);

    var type = setter.parameters[0].type.toString();
    assertType(ref, type);
  }

  void assertInstanceCreation(InstanceCreationExpression creation,
      ClassElement expectedClassElement, String expectedType,
      {String constructorName,
      bool expectedConstructorMember: false,
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
      assertMember(creation, expectedType, expectedConstructorElement);
    } else {
      assertElement(creation, expectedConstructorElement);
    }

    assertType(creation, expectedType);

    var typeName = creation.constructorName.type;
    assertTypeName(typeName, expectedClassElement, expectedType,
        expectedPrefix: expectedPrefix);
  }

  void assertInvokeType(InvocationExpression node, String expected) {
    DartType actual = node.staticInvokeType;
    expect(actual?.toString(), expected);
  }

  void assertInvokeTypeDynamic(InvocationExpression node) {
    DartType actual = node.staticInvokeType;
    expect(actual, isDynamicType);
  }

  void assertMember(
      Expression node, String expectedDefiningType, Element expectedBase) {
    Member actual = getNodeElement(node);
    expect(actual.definingType.toString(), expectedDefiningType);
    expect(actual.baseElement, same(expectedBase));
  }

  void assertNoTestErrors() {
    assertTestErrors(const <ErrorCode>[]);
  }

  void assertTestErrors(List<ErrorCode> expected) {
    assertErrors(result.errors, expected);
  }

  void assertTopGetRef(String search, String name) {
    var ref = findNode.simple(search);
    assertIdentifierTopGetRef(ref, name);
  }

  void assertType(AstNode node, String expected) {
    DartType actual;
    if (node is Expression) {
      actual = node.staticType;
    } else if (node is GenericFunctionType) {
      actual = node.type;
    } else if (node is TypeName) {
      actual = node.type;
    } else {
      fail('Unsupported node: (${node.runtimeType}) $node');
    }
    expect(actual?.toString(), expected);
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
      assertType(name, expectedType);
    } else {
      var name = node.name as PrefixedIdentifier;

      assertElement(name.prefix, expectedPrefix);
      expect(name.prefix.staticType, isNull);

      assertElement(name.identifier, expectedElement);
      expect(name.identifier.staticType, isNull);
    }
  }

  void assertTypeNull(Expression node) {
    expect(node.staticType, isNull);
  }

  Element getNodeElement(AstNode node) {
    if (node is Annotation) {
      return node.element;
    } else if (node is AssignmentExpression) {
      return node.staticElement;
    } else if (node is Declaration) {
      return node.declaredElement;
    } else if (node is FormalParameter) {
      return node.declaredElement;
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
    } else {
      fail('Unsupported node: (${node.runtimeType}) $node');
    }
  }

  Future<TestAnalysisResult> resolveFile(String path);

  Future<void> resolveTestFile() async {
    var path = convertPath('/test/lib/test.dart');
    result = await resolveFile(path);
    findNode = new FindNode(result.content, result.unit);
    findElement = new FindElement(result.unit);
  }

  void setAnalysisOptions({bool enableSuperMixins});

  Element _unwrapHandle(Element element) {
    if (element is ElementHandle && element is! Member) {
      return element.actualElement;
    }
    return element;
  }
}

class TestAnalysisResult {
  final String path;
  final String content;
  final CompilationUnit unit;
  final List<AnalysisError> errors;

  TestAnalysisResult(this.path, this.content, this.unit, this.errors);
}
