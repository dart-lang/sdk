import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/resolver.dart' show TypeProvider;
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test/test.dart';

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

  ClassElement get intElement => typeProvider.intType.element;

  InterfaceType get intType => typeProvider.intType;

  ClassElement get listElement => typeProvider.listType.element;

  ClassElement get mapElement => typeProvider.mapType.element;

  ClassElement get numElement => typeProvider.numType.element;

  TypeProvider get typeProvider =>
      result.unit.declaredElement.context.typeProvider;

  void addTestFile(String content) {
    newFile('/test/lib/test.dart', content: content);
  }

  void assertElement(AstNode node, Element expected) {
    Element actual = getNodeElement(node);
    expect(actual, same(expected));
  }

  void assertElementNull(Expression node) {
    Element actual = getNodeElement(node);
    expect(actual, isNull);
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

  void assertMember(
      Expression node, String expectedDefiningType, Element expectedBase) {
    Member actual = getNodeElement(node);
    expect(actual.definingType.toString(), expectedDefiningType);
    expect(actual.baseElement, same(expectedBase));
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

  Element getNodeElement(Expression node) {
    if (node is AssignmentExpression) {
      return node.staticElement;
    } else if (node is Identifier) {
      return node.staticElement;
    } else if (node is IndexExpression) {
      return node.staticElement;
    } else if (node is InstanceCreationExpression) {
      return node.staticElement;
    } else if (node is PostfixExpression) {
      return node.staticElement;
    } else if (node is PrefixExpression) {
      return node.staticElement;
    } else {
      fail('Unsupported node: (${node.runtimeType}) $node');
    }
  }

  Future<TestAnalysisResult> resolveFile(String path);

  Future resolveTestFile() async {
    var path = convertPath('/test/lib/test.dart');
    result = await resolveFile(path);
    findNode = new FindNode(result.content, result.unit);
    findElement = new FindElement(result.unit);
  }
}

class TestAnalysisResult {
  final String path;
  final String content;
  final CompilationUnit unit;
  final List<AnalysisError> errors;

  TestAnalysisResult(this.path, this.content, this.unit, this.errors);
}
