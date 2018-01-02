// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/status.dart';
import 'package:analyzer/src/dart/analysis/top_level_declaration.dart';
import 'package:analyzer/src/dart/constant/evaluation.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisOptionsImpl;
import 'package:analyzer/src/generated/resolver.dart' show ResolverErrorCode;
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/package_bundle_reader.dart';
import 'package:front_end/src/api_prototype/byte_store.dart';
import 'package:front_end/src/base/performance_logger.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../utils.dart';
import '../../context/mock_sdk.dart';
import 'base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisDriverSchedulerTest);
    defineReflectiveTests(AnalysisDriverTest);
    defineReflectiveTests(AnalysisDriverResolutionTest);
    defineReflectiveTests(CacheAllAnalysisDriverTest);
  });
}

Matcher isUndefinedType = new isInstanceOf<UndefinedTypeImpl>();

/**
 * Returns a [Future] that completes after pumping the event queue [times]
 * times. By default, this should pump the event queue enough times to allow
 * any code to run, as long as it's not waiting on some external event.
 */
Future pumpEventQueue([int times = 5000]) {
  if (times == 0) return new Future.value();
  // We use a delayed future to allow microtask events to finish. The
  // Future.value or Future() constructors use scheduleMicrotask themselves and
  // would therefore not wait for microtask callbacks that are scheduled after
  // invoking this method.
  return new Future.delayed(Duration.ZERO, () => pumpEventQueue(times - 1));
}

/**
 * Integration tests for resolution.
 */
@reflectiveTest
class AnalysisDriverResolutionTest extends BaseAnalysisDriverTest {
  test_adjacentStrings() async {
    String content = r'''
void main() {
  'aaa' 'bbb' 'ccc';
}
''';
    addTestFile(content);
    AnalysisResult result = await driver.getResult(testFile);
    var typeProvider = result.unit.element.context.typeProvider;

    List<Statement> statements = _getMainStatements(result);

    ExpressionStatement statement = statements[0];
    AdjacentStrings expression = statement.expression;
    expect(expression.staticType, typeProvider.stringType);
    expect(expression.strings, hasLength(3));

    StringLiteral literal_1 = expression.strings[0];
    expect(literal_1.staticType, typeProvider.stringType);

    StringLiteral literal_2 = expression.strings[1];
    expect(literal_2.staticType, typeProvider.stringType);

    StringLiteral literal_3 = expression.strings[2];
    expect(literal_3.staticType, typeProvider.stringType);
  }

  test_annotation() async {
    String content = r'''
const myAnnotation = 1;

@myAnnotation
class C {
  @myAnnotation
  int field1 = 2, field2 = 3;

  @myAnnotation
  C() {}

  @myAnnotation
  void method() {}
}

@myAnnotation
int topLevelVariable1 = 4, topLevelVariable2 = 5;

@myAnnotation
void topLevelFunction() {}
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    var typeProvider = result.unit.element.context.typeProvider;

    TopLevelVariableDeclaration myDeclaration = result.unit.declarations[0];
    VariableDeclaration myVariable = myDeclaration.variables.variables[0];
    TopLevelVariableElement myElement = myVariable.element;

    void assertMyAnnotation(AnnotatedNode node) {
      Annotation annotation = node.metadata[0];
      expect(annotation.element, same(myElement.getter));

      SimpleIdentifier identifier_1 = annotation.name;
      expect(identifier_1.staticElement, same(myElement.getter));
      expect(identifier_1.staticType, typeProvider.intType);
    }

    {
      ClassDeclaration classNode = result.unit.declarations[1];
      assertMyAnnotation(classNode);

      {
        FieldDeclaration node = classNode.members[0];
        assertMyAnnotation(node);
      }

      {
        ConstructorDeclaration node = classNode.members[1];
        assertMyAnnotation(node);
      }

      {
        MethodDeclaration node = classNode.members[2];
        assertMyAnnotation(node);
      }
    }

    {
      TopLevelVariableDeclaration node = result.unit.declarations[2];
      assertMyAnnotation(node);
    }

    {
      FunctionDeclaration node = result.unit.declarations[3];
      assertMyAnnotation(node);
    }
  }

  test_annotation_constructor_withNestedConstructorInvocation() async {
    addTestFile('''
class C {
  const C();
}
class D {
  final C c;
  const D(this.c);
}
@D(const C())
f() {}
''');
    var result = await driver.getResult(testFile);
    var elementC = AstFinder.getClass(result.unit, 'C').element;
    var constructorC = elementC.constructors[0];
    var elementD = AstFinder.getClass(result.unit, 'D').element;
    var constructorD = elementD.constructors[0];
    var atD = AstFinder.getTopLevelFunction(result.unit, 'f').metadata[0];
    InstanceCreationExpression constC = atD.arguments.arguments[0];

    if (previewDart2) {
      expect(atD.name.staticElement, constructorD);
      expect(atD.element, constructorD);
    } else {
      expect(atD.name.staticElement, elementD);
      expect(atD.element, constructorD);
    }

    expect(constC.staticElement, constructorC);
    expect(constC.staticType, elementC.type);

    expect(constC.constructorName.staticElement, constructorC);
    expect(constC.constructorName.type.type, elementC.type);
  }

  test_annotation_kind_reference() async {
    String content = r'''
const annotation_1 = 1;
const annotation_2 = 1;
@annotation_1
@annotation_2
void main() {
  print(42);
}
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    var typeProvider = result.unit.element.context.typeProvider;

    TopLevelVariableDeclaration declaration_1 = result.unit.declarations[0];
    VariableDeclaration variable_1 = declaration_1.variables.variables[0];
    TopLevelVariableElement element_1 = variable_1.element;

    TopLevelVariableDeclaration declaration_2 = result.unit.declarations[1];
    VariableDeclaration variable_2 = declaration_2.variables.variables[0];
    TopLevelVariableElement element_2 = variable_2.element;

    FunctionDeclaration main = result.unit.declarations[2];

    Annotation annotation_1 = main.metadata[0];
    expect(annotation_1.element, same(element_1.getter));

    SimpleIdentifier identifier_1 = annotation_1.name;
    expect(identifier_1.staticElement, same(element_1.getter));
    expect(identifier_1.staticType, typeProvider.intType);

    Annotation annotation_2 = main.metadata[1];
    expect(annotation_2.element, same(element_2.getter));

    SimpleIdentifier identifier_2 = annotation_2.name;
    expect(identifier_2.staticElement, same(element_2.getter));
    expect(identifier_2.staticType, typeProvider.intType);
  }

  test_asExpression() async {
    String content = r'''
void main() {
  num v = 42;
  v as int;
}
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    expect(result.path, testFile);
    expect(result.errors, isEmpty);

    var typeProvider = result.unit.element.context.typeProvider;
    NodeList<Statement> statements = _getMainStatements(result);

    // num v = 42;
    VariableElement vElement;
    {
      VariableDeclarationStatement statement = statements[0];
      vElement = statement.variables.variables[0].name.staticElement;
      expect(vElement.type, typeProvider.numType);
    }

    // v as int;
    {
      ExpressionStatement statement = statements[1];
      AsExpression asExpression = statement.expression;
      expect(asExpression.staticType, typeProvider.intType);

      SimpleIdentifier target = asExpression.expression;
      expect(target.staticElement, vElement);
      expect(target.staticType, typeProvider.numType);

      TypeName intName = asExpression.type;
      expect(intName.name.staticElement, typeProvider.intType.element);
      expect(intName.name.staticType, typeProvider.intType);
    }
  }

  test_assignmentExpression_compound_indexExpression() async {
    String content = r'''
main() {
  var items = <num>[1, 2, 3];
  items[0] += 4;
}
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;

    var typeProvider = unit.element.context.typeProvider;
    InterfaceType numType = typeProvider.numType;
    InterfaceType intType = typeProvider.intType;
    InterfaceType listType = typeProvider.listType;
    InterfaceType listNumType = listType.instantiate([numType]);

    List<Statement> mainStatements = _getMainStatements(result);

    VariableElement itemsElement;
    {
      VariableDeclarationStatement statement = mainStatements[0];
      VariableDeclaration itemsNode = statement.variables.variables[0];
      itemsElement = itemsNode.element;
      expect(itemsElement.type, listNumType);
    }

    {
      ExpressionStatement statement = mainStatements[1];

      AssignmentExpression assignment = statement.expression;
      expect(assignment.operator.type, TokenType.PLUS_EQ);
      expect(assignment.staticElement, isNotNull);
      expect(assignment.staticElement.name, '+');
      expect(assignment.staticType, typeProvider.numType); // num + int = num

      IndexExpression indexExpression = assignment.leftHandSide;
      expect(indexExpression.staticType, numType);
      expect(indexExpression.index.staticType, intType);

      MethodMember actualElement = indexExpression.staticElement;
      MethodMember expectedElement = listNumType.getMethod('[]=');
      expect(actualElement.name, '[]=');
      expect(actualElement.baseElement, same(expectedElement.baseElement));
      expect(actualElement.returnType, VoidTypeImpl.instance);
      expect(actualElement.parameters[0].type, intType);

      Expression right = assignment.rightHandSide;
      expect(right.staticType, typeProvider.intType);
    }
  }

  test_assignmentExpression_compound_local() async {
    String content = r'''
main() {
  num v = 0;
  v += 3;
}
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;
    var typeProvider = unit.element.context.typeProvider;

    List<Statement> mainStatements = _getMainStatements(result);

    VariableElement v;
    {
      VariableDeclarationStatement statement = mainStatements[0];
      v = statement.variables.variables[0].element;
      expect(v.type, typeProvider.numType);
    }

    {
      ExpressionStatement statement = mainStatements[1];

      AssignmentExpression assignment = statement.expression;
      expect(assignment.operator.type, TokenType.PLUS_EQ);
      expect(assignment.staticElement, isNotNull);
      expect(assignment.staticElement.name, '+');
      expect(assignment.staticType, typeProvider.numType); // num + int = num

      SimpleIdentifier left = assignment.leftHandSide;
      expect(left.staticElement, same(v));
      expect(left.staticType, typeProvider.numType);

      Expression right = assignment.rightHandSide;
      expect(right.staticType, typeProvider.intType);
    }
  }

  test_assignmentExpression_compound_prefixedIdentifier() async {
    String content = r'''
main() {
  var c = new C();
  c.f += 2;
}
class C {
  num f;
}
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;
    var typeProvider = unit.element.context.typeProvider;

    ClassDeclaration cClassDeclaration = unit.declarations[1];
    ClassElement cClassElement = cClassDeclaration.element;
    FieldElement fElement = cClassElement.getField('f');

    List<Statement> mainStatements = _getMainStatements(result);

    VariableElement c;
    {
      VariableDeclarationStatement statement = mainStatements[0];
      c = statement.variables.variables[0].element;
      expect(c.type, cClassElement.type);
    }

    {
      ExpressionStatement statement = mainStatements[1];

      AssignmentExpression assignment = statement.expression;
      expect(assignment.operator.type, TokenType.PLUS_EQ);
      expect(assignment.staticElement, isNotNull);
      expect(assignment.staticElement.name, '+');
      expect(assignment.staticType, typeProvider.numType); // num + int = num

      PrefixedIdentifier left = assignment.leftHandSide;
      expect(left.staticElement, same(fElement.setter));
      expect(left.staticType, typeProvider.numType);

      expect(left.prefix.staticElement, c);
      expect(left.prefix.staticType, cClassElement.type);

      expect(left.identifier.staticElement, same(fElement.setter));
      expect(left.identifier.staticType, typeProvider.numType);

      Expression right = assignment.rightHandSide;
      expect(right.staticType, typeProvider.intType);
    }
  }

  test_assignmentExpression_compound_propertyAccess() async {
    String content = r'''
main() {
  new C().f += 2;
}
class C {
  num f;
}
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;
    var typeProvider = unit.element.context.typeProvider;

    ClassDeclaration cClassDeclaration = unit.declarations[1];
    ClassElement cClassElement = cClassDeclaration.element;
    FieldElement fElement = cClassElement.getField('f');

    List<Statement> mainStatements = _getMainStatements(result);

    {
      ExpressionStatement statement = mainStatements[0];

      AssignmentExpression assignment = statement.expression;
      expect(assignment.operator.type, TokenType.PLUS_EQ);
      expect(assignment.staticElement, isNotNull);
      expect(assignment.staticElement.name, '+');
      expect(assignment.staticType, typeProvider.numType); // num + int = num

      PropertyAccess left = assignment.leftHandSide;
      expect(left.staticType, typeProvider.numType);

      InstanceCreationExpression newC = left.target;
      expect(newC.staticElement, cClassElement.unnamedConstructor);

      expect(left.propertyName.staticElement, same(fElement.setter));
      expect(left.propertyName.staticType, typeProvider.numType);

      Expression right = assignment.rightHandSide;
      expect(right.staticType, typeProvider.intType);
    }
  }

  test_assignmentExpression_nullAware_local() async {
    String content = r'''
main() {
  String v;
  v ??= 'test';
}
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;
    var typeProvider = unit.element.context.typeProvider;

    List<Statement> mainStatements = _getMainStatements(result);

    VariableElement v;
    {
      VariableDeclarationStatement statement = mainStatements[0];
      v = statement.variables.variables[0].element;
    }

    {
      ExpressionStatement statement = mainStatements[1];

      AssignmentExpression assignment = statement.expression;
      expect(assignment.operator.type, TokenType.QUESTION_QUESTION_EQ);
      expect(assignment.staticElement, isNull);
      expect(assignment.staticType, typeProvider.stringType);

      SimpleIdentifier left = assignment.leftHandSide;
      expect(left.staticElement, same(v));
      expect(left.staticType, typeProvider.stringType);

      Expression right = assignment.rightHandSide;
      expect(right.staticType, typeProvider.stringType);
    }
  }

  test_assignmentExpression_propertyAccess_forwardingStub() async {
    String content = r'''
class A {
  int f;
}
abstract class I<T> {
  T f;
}
class B extends A implements I<int> {}
main() {
  new B().f = 1;
}
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;
    var typeProvider = unit.element.context.typeProvider;

    ClassDeclaration aNode = unit.declarations[0];
    ClassElement aElement = aNode.element;
    FieldElement fElement = aElement.getField('f');

    ClassDeclaration bNode = unit.declarations[2];
    ClassElement bElement = bNode.element;

    List<Statement> mainStatements = _getMainStatements(result);
    ExpressionStatement statement = mainStatements[0];

    AssignmentExpression assignment = statement.expression;
    expect(assignment.staticType, typeProvider.intType);

    PropertyAccess left = assignment.leftHandSide;
    expect(left.staticType, typeProvider.intType);

    InstanceCreationExpression newB = left.target;
    expect(newB.staticElement, bElement.unnamedConstructor);

    expect(left.propertyName.staticElement, same(fElement.setter));
    expect(left.propertyName.staticType, typeProvider.intType);

    Expression right = assignment.rightHandSide;
    expect(right.staticType, typeProvider.intType);
  }

  test_assignmentExpression_simple_indexExpression() async {
    String content = r'''
main() {
  var items = <int>[1, 2, 3];
  items[0] = 4;
}
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;

    var typeProvider = unit.element.context.typeProvider;
    InterfaceType intType = typeProvider.intType;
    InterfaceType listType = typeProvider.listType;
    InterfaceType listIntType = listType.instantiate([intType]);

    List<Statement> mainStatements = _getMainStatements(result);

    VariableElement itemsElement;
    {
      VariableDeclarationStatement statement = mainStatements[0];
      VariableDeclaration itemsNode = statement.variables.variables[0];
      itemsElement = itemsNode.element;
      expect(itemsElement.type, listIntType);
    }

    {
      ExpressionStatement statement = mainStatements[1];

      AssignmentExpression assignment = statement.expression;
      expect(assignment.operator.type, TokenType.EQ);
      expect(assignment.staticElement, isNull);
      expect(assignment.staticType, typeProvider.intType);

      IndexExpression indexExpression = assignment.leftHandSide;
      expect(indexExpression.staticType, intType);
      expect(indexExpression.index.staticType, intType);

      MethodMember actualElement = indexExpression.staticElement;
      MethodMember expectedElement = listIntType.getMethod('[]=');
      expect(actualElement.name, '[]=');
      expect(actualElement.baseElement, same(expectedElement.baseElement));
      expect(actualElement.returnType, VoidTypeImpl.instance);
      expect(actualElement.parameters[0].type, intType);

      Expression right = assignment.rightHandSide;
      expect(right.staticType, typeProvider.intType);
    }
  }

  test_assignmentExpression_simple_instanceField_unqualified() async {
    String content = r'''
class C {
  num f = 0;
  foo() {
    f = 2;
  }
}
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;
    var typeProvider = unit.element.context.typeProvider;

    ClassDeclaration cDeclaration = unit.declarations[0];
    FieldElement fElement = cDeclaration.element.fields[0];

    MethodDeclaration fooDeclaration = cDeclaration.members[1];
    BlockFunctionBody fooBody = fooDeclaration.body;

    {
      ExpressionStatement statement = fooBody.block.statements[0];

      AssignmentExpression assignment = statement.expression;
      expect(assignment.operator.type, TokenType.EQ);
      expect(assignment.staticElement, isNull);
      expect(assignment.staticType, typeProvider.intType);

      SimpleIdentifier left = assignment.leftHandSide;
      expect(left.staticElement, same(fElement.setter));
      expect(left.staticType, typeProvider.numType);

      Expression right = assignment.rightHandSide;
      expect(right.staticType, typeProvider.intType);
    }
  }

  test_assignmentExpression_simple_local() async {
    String content = r'''
main() {
  num v = 0;
  v = 2;
}
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;
    var typeProvider = unit.element.context.typeProvider;

    List<Statement> mainStatements = _getMainStatements(result);

    VariableElement v;
    {
      VariableDeclarationStatement statement = mainStatements[0];
      v = statement.variables.variables[0].element;
      expect(v.type, typeProvider.numType);
    }

    {
      ExpressionStatement statement = mainStatements[1];

      AssignmentExpression assignment = statement.expression;
      expect(assignment.operator.type, TokenType.EQ);
      expect(assignment.staticElement, isNull);
      expect(assignment.staticType, typeProvider.intType);

      SimpleIdentifier left = assignment.leftHandSide;
      expect(left.staticElement, same(v));
      expect(left.staticType, typeProvider.numType);

      Expression right = assignment.rightHandSide;
      expect(right.staticType, typeProvider.intType);
    }
  }

  test_assignmentExpression_simple_prefixedIdentifier() async {
    String content = r'''
main() {
  var c = new C();
  c.f = 2;
}
class C {
  num f;
}
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;
    var typeProvider = unit.element.context.typeProvider;

    ClassDeclaration cClassDeclaration = unit.declarations[1];
    ClassElement cClassElement = cClassDeclaration.element;
    FieldElement fElement = cClassElement.getField('f');

    List<Statement> mainStatements = _getMainStatements(result);

    VariableElement c;
    {
      VariableDeclarationStatement statement = mainStatements[0];
      c = statement.variables.variables[0].element;
      expect(c.type, cClassElement.type);
    }

    {
      ExpressionStatement statement = mainStatements[1];

      AssignmentExpression assignment = statement.expression;
      expect(assignment.staticType, typeProvider.intType);

      PrefixedIdentifier left = assignment.leftHandSide;
      expect(left.staticElement, same(fElement.setter));
      expect(left.staticType, typeProvider.numType);

      expect(left.prefix.staticElement, c);
      expect(left.prefix.staticType, cClassElement.type);

      expect(left.identifier.staticElement, same(fElement.setter));
      expect(left.identifier.staticType, typeProvider.numType);

      Expression right = assignment.rightHandSide;
      expect(right.staticType, typeProvider.intType);
    }
  }

  test_assignmentExpression_simple_prefixedIdentifier_staticField() async {
    String content = r'''
main() {
  C.f = 2;
}
class C {
  static num f;
}
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;
    var typeProvider = unit.element.context.typeProvider;

    ClassDeclaration cClassDeclaration = unit.declarations[1];
    ClassElement cClassElement = cClassDeclaration.element;
    FieldElement fElement = cClassElement.getField('f');

    List<Statement> mainStatements = _getMainStatements(result);

    {
      ExpressionStatement statement = mainStatements[0];

      AssignmentExpression assignment = statement.expression;
      expect(assignment.staticType, typeProvider.intType);

      PrefixedIdentifier left = assignment.leftHandSide;
      expect(left.staticElement, same(fElement.setter));
      expect(left.staticType, typeProvider.numType);

      expect(left.prefix.staticElement, cClassElement);
      expect(left.prefix.staticType, cClassElement.type);

      expect(left.identifier.staticElement, same(fElement.setter));
      expect(left.identifier.staticType, typeProvider.numType);

      Expression right = assignment.rightHandSide;
      expect(right.staticType, typeProvider.intType);
    }
  }

  test_assignmentExpression_simple_propertyAccess() async {
    String content = r'''
main() {
  new C().f = 2;
}
class C {
  num f;
}
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;
    var typeProvider = unit.element.context.typeProvider;

    ClassDeclaration cClassDeclaration = unit.declarations[1];
    ClassElement cClassElement = cClassDeclaration.element;
    FieldElement fElement = cClassElement.getField('f');

    List<Statement> mainStatements = _getMainStatements(result);

    {
      ExpressionStatement statement = mainStatements[0];

      AssignmentExpression assignment = statement.expression;
      expect(assignment.staticType, typeProvider.intType);

      PropertyAccess left = assignment.leftHandSide;
      expect(left.staticType, typeProvider.numType);

      InstanceCreationExpression newC = left.target;
      expect(newC.staticElement, cClassElement.unnamedConstructor);

      expect(left.propertyName.staticElement, same(fElement.setter));
      expect(left.propertyName.staticType, typeProvider.numType);

      Expression right = assignment.rightHandSide;
      expect(right.staticType, typeProvider.intType);
    }
  }

  test_assignmentExpression_simple_propertyAccess_chained() async {
    String content = r'''
main() {
  var a = new A();
  a.b.f = 2;
}
class A {
  B b;
}
class B {
  num f;
}
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;
    var typeProvider = unit.element.context.typeProvider;

    ClassDeclaration aClassDeclaration = unit.declarations[1];
    ClassElement aClassElement = aClassDeclaration.element;
    FieldElement bElement = aClassElement.getField('b');

    ClassDeclaration bClassDeclaration = unit.declarations[2];
    ClassElement bClassElement = bClassDeclaration.element;
    FieldElement fElement = bClassElement.getField('f');

    List<Statement> mainStatements = _getMainStatements(result);

    VariableElement a;
    {
      VariableDeclarationStatement statement = mainStatements[0];
      a = statement.variables.variables[0].element;
      expect(a.type, aClassElement.type);
    }

    {
      ExpressionStatement statement = mainStatements[1];

      AssignmentExpression assignment = statement.expression;
      expect(assignment.staticType, typeProvider.intType);

      PropertyAccess fAccess = assignment.leftHandSide;
      expect(fAccess.propertyName.name, 'f');
      expect(fAccess.propertyName.staticElement, same(fElement.setter));
      expect(fAccess.propertyName.staticType, typeProvider.numType);

      PrefixedIdentifier bAccess = fAccess.target;
      expect(bAccess.identifier.name, 'b');
      expect(bAccess.identifier.staticElement, same(bElement.getter));
      expect(bAccess.identifier.staticType, bClassElement.type);

      SimpleIdentifier aIdentifier = bAccess.prefix;
      expect(aIdentifier.name, 'a');
      expect(aIdentifier.staticElement, a);
      expect(aIdentifier.staticType, aClassElement.type);

      Expression right = assignment.rightHandSide;
      expect(right.staticType, typeProvider.intType);
    }
  }

  test_assignmentExpression_simple_propertyAccess_setter() async {
    String content = r'''
main() {
  new C().f = 2;
}
class C {
  void set f(num _) {}
}
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;
    var typeProvider = unit.element.context.typeProvider;

    ClassDeclaration cClassDeclaration = unit.declarations[1];
    ClassElement cClassElement = cClassDeclaration.element;
    FieldElement fElement = cClassElement.getField('f');

    List<Statement> mainStatements = _getMainStatements(result);

    {
      ExpressionStatement statement = mainStatements[0];

      AssignmentExpression assignment = statement.expression;
      expect(assignment.staticType, typeProvider.intType);

      PropertyAccess left = assignment.leftHandSide;
      expect(left.staticType, typeProvider.numType);

      InstanceCreationExpression newC = left.target;
      expect(newC.staticElement, cClassElement.unnamedConstructor);

      expect(left.propertyName.staticElement, same(fElement.setter));
      expect(left.propertyName.staticType, typeProvider.numType);

      Expression right = assignment.rightHandSide;
      expect(right.staticType, typeProvider.intType);
    }
  }

  test_assignmentExpression_simple_staticField_unqualified() async {
    String content = r'''
class C {
  static num f = 0;
  foo() {
    f = 2;
  }
}
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;
    var typeProvider = unit.element.context.typeProvider;

    ClassDeclaration cDeclaration = unit.declarations[0];
    FieldElement fElement = cDeclaration.element.fields[0];

    MethodDeclaration fooDeclaration = cDeclaration.members[1];
    BlockFunctionBody fooBody = fooDeclaration.body;

    {
      ExpressionStatement statement = fooBody.block.statements[0];

      AssignmentExpression assignment = statement.expression;
      expect(assignment.operator.type, TokenType.EQ);
      expect(assignment.staticElement, isNull);
      expect(assignment.staticType, typeProvider.intType);

      SimpleIdentifier left = assignment.leftHandSide;
      expect(left.staticElement, same(fElement.setter));
      expect(left.staticType, typeProvider.numType);

      Expression right = assignment.rightHandSide;
      expect(right.staticType, typeProvider.intType);
    }
  }

  test_assignmentExpression_simple_topLevelVariable() async {
    String content = r'''
main() {
  v = 2;
}
num v = 0;
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;
    var typeProvider = unit.element.context.typeProvider;

    TopLevelVariableElement v;
    {
      TopLevelVariableDeclaration declaration = unit.declarations[1];
      v = declaration.variables.variables[0].element;
      expect(v.type, typeProvider.numType);
    }

    List<Statement> mainStatements = _getMainStatements(result);
    {
      ExpressionStatement statement = mainStatements[0];

      AssignmentExpression assignment = statement.expression;
      expect(assignment.operator.type, TokenType.EQ);
      expect(assignment.staticElement, isNull);
      expect(assignment.staticType, typeProvider.intType);

      SimpleIdentifier left = assignment.leftHandSide;
      expect(left.staticElement, same(v.setter));
      expect(left.staticType, typeProvider.numType);

      Expression right = assignment.rightHandSide;
      expect(right.staticType, typeProvider.intType);
    }
  }

  test_binaryExpression() async {
    String content = r'''
main() {
  var v = 1 + 2;
}
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;
    var typeProvider = unit.element.context.typeProvider;

    List<Statement> mainStatements = _getMainStatements(result);

    VariableDeclarationStatement statement = mainStatements[0];
    VariableDeclaration vNode = statement.variables.variables[0];
    VariableElement vElement = vNode.element;
    expect(vElement.type, typeProvider.intType);

    BinaryExpression value = vNode.initializer;
    expect(value.leftOperand.staticType, typeProvider.intType);
    expect(value.rightOperand.staticType, typeProvider.intType);
    expect(value.staticElement.name, '+');
    expect(value.staticType, typeProvider.intType);
  }

  test_binaryExpression_ifNull() async {
    String content = r'''
main() {
  1.2 ?? 3;
}
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;
    var typeProvider = unit.element.context.typeProvider;

    List<Statement> mainStatements = _getMainStatements(result);

    ExpressionStatement statement = mainStatements[0];
    BinaryExpression binary = statement.expression;
    expect(binary.operator.type, TokenType.QUESTION_QUESTION);
    expect(binary.staticElement, isNull);
    expect(binary.staticType, typeProvider.numType);

    expect(binary.leftOperand.staticType, typeProvider.doubleType);
    expect(binary.rightOperand.staticType, typeProvider.intType);
  }

  test_binaryExpression_logical() async {
    addTestFile(r'''
main() {
  true && true;
  true || true;
}
''');
    AnalysisResult result = await driver.getResult(testFile);
    var typeProvider = result.unit.element.context.typeProvider;

    List<Statement> statements = _getMainStatements(result);

    {
      ExpressionStatement statement = statements[0];
      BinaryExpression binaryExpression = statement.expression;
      expect(binaryExpression.staticElement, isNull);
      expect(binaryExpression.staticType, typeProvider.boolType);
    }

    {
      ExpressionStatement statement = statements[1];
      BinaryExpression binaryExpression = statement.expression;
      expect(binaryExpression.staticElement, isNull);
      expect(binaryExpression.staticType, typeProvider.boolType);
    }
  }

  test_binaryExpression_notEqual() async {
    String content = r'''
main() {
  1 != 2;
}
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;
    var typeProvider = unit.element.context.typeProvider;

    List<Statement> statements = _getMainStatements(result);
    ExpressionStatement statement = statements[0];
    BinaryExpression expression = statement.expression;
    expect(expression.operator.type, TokenType.BANG_EQ);
    expect(expression.leftOperand.staticType, typeProvider.intType);
    expect(expression.rightOperand.staticType, typeProvider.intType);
    expect(expression.staticElement.name, '==');
    expect(expression.staticType, typeProvider.boolType);
  }

  test_cascadeExpression() async {
    String content = r'''
void main() {
  new A()..a()..b();
}
class A {
  void a() {}
  void b() {}
}
''';
    addTestFile(content);
    AnalysisResult result = await driver.getResult(testFile);

    List<Statement> statements = _getMainStatements(result);

    ExpressionStatement statement = statements[0];
    CascadeExpression expression = statement.expression;
    expect(expression.target.staticType, isNotNull);
    NodeList<Expression> sections = expression.cascadeSections;

    MethodInvocation a = sections[0];
    expect(a.methodName.staticElement, isNotNull);
    expect(a.staticType, isNotNull);

    MethodInvocation b = sections[1];
    expect(b.methodName.staticElement, isNotNull);
    expect(b.staticType, isNotNull);
  }

  test_closure() async {
    addTestFile(r'''
main() {
  var items = <int>[1, 2, 3];
  items.forEach((item) {
    item;
  });
  items.forEach((item) {
    item;
  });
}
''');
    AnalysisResult result = await driver.getResult(testFile);
    var typeProvider = result.unit.element.context.typeProvider;

    FunctionDeclaration mainDeclaration = result.unit.declarations[0];
    FunctionElement mainElement = mainDeclaration.element;
    BlockFunctionBody mainBody = mainDeclaration.functionExpression.body;
    List<Statement> mainStatements = mainBody.block.statements;

    VariableDeclarationStatement itemsStatement = mainStatements[0];
    var itemsElement = itemsStatement.variables.variables[0].element;

    // First closure.
    ParameterElement itemElement1;
    {
      ExpressionStatement forStatement = mainStatements[1];
      MethodInvocation forInvocation = forStatement.expression;

      SimpleIdentifier forTarget = forInvocation.target;
      expect(forTarget.staticElement, itemsElement);

      var closureTypeStr = '(int) → Null';
      FunctionExpression closure = forInvocation.argumentList.arguments[0];

      FunctionElementImpl closureElement = closure.element;
      expect(closureElement.enclosingElement, same(mainElement));

      ParameterElement itemElement = closureElement.parameters[0];
      itemElement1 = itemElement;

      expect(closureElement.returnType, typeProvider.nullType);
      expect(closureElement.type.element, same(closureElement));
      expect(closureElement.type.toString(), closureTypeStr);
      expect(closure.staticType, same(closureElement.type));

      List<FormalParameter> closureParameters = closure.parameters.parameters;
      expect(closureParameters, hasLength(1));

      SimpleFormalParameter itemNode = closureParameters[0];
      _assertSimpleParameter(itemNode, itemElement,
          name: 'item',
          offset: 56,
          kind: ParameterKind.REQUIRED,
          type: typeProvider.intType);

      BlockFunctionBody closureBody = closure.body;
      List<Statement> closureStatements = closureBody.block.statements;

      ExpressionStatement itemStatement = closureStatements[0];
      SimpleIdentifier itemIdentifier = itemStatement.expression;
      expect(itemIdentifier.staticElement, itemElement);
      expect(itemIdentifier.staticType, typeProvider.intType);
    }

    // Second closure, same names, different elements.
    {
      ExpressionStatement forStatement = mainStatements[2];
      MethodInvocation forInvocation = forStatement.expression;

      SimpleIdentifier forTarget = forInvocation.target;
      expect(forTarget.staticElement, itemsElement);

      var closureTypeStr = '(int) → Null';
      FunctionExpression closure = forInvocation.argumentList.arguments[0];

      FunctionElementImpl closureElement = closure.element;
      expect(closureElement.enclosingElement, same(mainElement));

      ParameterElement itemElement = closureElement.parameters[0];
      expect(itemElement, isNot(same(itemElement1)));

      expect(closureElement.returnType, typeProvider.nullType);
      expect(closureElement.type.element, same(closureElement));
      expect(closureElement.type.toString(), closureTypeStr);
      expect(closure.staticType, same(closureElement.type));

      List<FormalParameter> closureParameters = closure.parameters.parameters;
      expect(closureParameters, hasLength(1));

      SimpleFormalParameter itemNode = closureParameters[0];
      _assertSimpleParameter(itemNode, itemElement,
          name: 'item',
          offset: 97,
          kind: ParameterKind.REQUIRED,
          type: typeProvider.intType);

      BlockFunctionBody closureBody = closure.body;
      List<Statement> closureStatements = closureBody.block.statements;

      ExpressionStatement itemStatement = closureStatements[0];
      SimpleIdentifier itemIdentifier = itemStatement.expression;
      expect(itemIdentifier.staticElement, itemElement);
      expect(itemIdentifier.staticType, typeProvider.intType);
    }
  }

  test_conditionalExpression() async {
    String content = r'''
void main() {
  true ? 1 : 2.3;
}
''';
    addTestFile(content);
    AnalysisResult result = await driver.getResult(testFile);
    var typeProvider = result.unit.element.context.typeProvider;

    List<Statement> statements = _getMainStatements(result);

    ExpressionStatement statement = statements[0];
    ConditionalExpression expression = statement.expression;
    expect(expression.staticType, typeProvider.numType);
    expect(expression.condition.staticType, typeProvider.boolType);
    expect(expression.thenExpression.staticType, typeProvider.intType);
    expect(expression.elseExpression.staticType, typeProvider.doubleType);
  }

  test_constructor_context() async {
    addTestFile(r'''
class C {
  C(int p) {
    p;
  }
}
''');
    AnalysisResult result = await driver.getResult(testFile);
    var typeProvider = result.unit.element.context.typeProvider;

    ClassDeclaration cNode = result.unit.declarations[0];

    ConstructorDeclaration constructorNode = cNode.members[0];
    ParameterElement pElement = constructorNode.element.parameters[0];

    BlockFunctionBody constructorBody = constructorNode.body;
    ExpressionStatement pStatement = constructorBody.block.statements[0];

    SimpleIdentifier pIdentifier = pStatement.expression;
    expect(pIdentifier.staticElement, same(pElement));
    expect(pIdentifier.staticType, typeProvider.intType);
  }

  test_constructor_initializer_field() async {
    addTestFile(r'''
class C {
  int f;
  C(int p) : f = p {
    f;
  }
}
''');
    AnalysisResult result = await driver.getResult(testFile);

    ClassDeclaration cNode = result.unit.declarations[0];
    ClassElement cElement = cNode.element;
    FieldElement fElement = cElement.getField('f');

    ConstructorDeclaration constructorNode = cNode.members[1];
    ParameterElement pParameterElement = constructorNode.element.parameters[0];

    {
      ConstructorFieldInitializer initializer = constructorNode.initializers[0];
      expect(initializer.fieldName.staticElement, same(fElement));

      SimpleIdentifier expression = initializer.expression;
      expect(expression.staticElement, same(pParameterElement));
    }
  }

  test_constructor_initializer_super() async {
    addTestFile(r'''
class A {
  A(int a);
  A.named(int a);
}
class B extends A {
  B.one(int b) : super(b + 1);
  B.two(int b) : super.named(b + 1);
}
''');
    AnalysisResult result = await driver.getResult(testFile);

    ClassDeclaration aNode = result.unit.declarations[0];
    ClassElement aElement = aNode.element;

    ClassDeclaration bNode = result.unit.declarations[1];

    {
      ConstructorDeclaration constructor = bNode.members[0];
      SuperConstructorInvocation initializer = constructor.initializers[0];
      expect(initializer.staticElement, same(aElement.unnamedConstructor));
      expect(initializer.constructorName, isNull);
    }

    {
      var namedConstructor = aElement.getNamedConstructor('named');

      ConstructorDeclaration constructor = bNode.members[1];
      SuperConstructorInvocation initializer = constructor.initializers[0];
      expect(initializer.staticElement, same(namedConstructor));

      var constructorName = initializer.constructorName;
      expect(constructorName.staticElement, same(namedConstructor));
      expect(constructorName.staticType, isNull);
    }
  }

  test_constructor_initializer_this() async {
    addTestFile(r'''
class C {
  C(int a, [int b]);
  C.named(int a, {int b});
  C.one(int p) : this(1, 2);
  C.two(int p) : this.named(3, b: 4);
}
''');
    AnalysisResult result = await driver.getResult(testFile);

    ClassDeclaration cNode = result.unit.declarations[0];
    ClassElement cElement = cNode.element;

    {
      var unnamedConstructor = cElement.constructors[0];

      ConstructorDeclaration constructor = cNode.members[2];
      RedirectingConstructorInvocation initializer =
          constructor.initializers[0];
      expect(initializer.staticElement, same(unnamedConstructor));
      expect(initializer.constructorName, isNull);

      List<Expression> arguments = initializer.argumentList.arguments;
      _assertArgumentToParameter(
          arguments[0], unnamedConstructor.parameters[0]);
      _assertArgumentToParameter(
          arguments[1], unnamedConstructor.parameters[1]);
    }

    {
      var namedConstructor = cElement.constructors[1];

      ConstructorDeclaration constructor = cNode.members[3];
      RedirectingConstructorInvocation initializer =
          constructor.initializers[0];
      expect(initializer.staticElement, same(namedConstructor));

      var constructorName = initializer.constructorName;
      expect(constructorName.staticElement, same(namedConstructor));
      expect(constructorName.staticType, isNull);

      List<Expression> arguments = initializer.argumentList.arguments;
      _assertArgumentToParameter(arguments[0], namedConstructor.parameters[0]);
      _assertArgumentToParameter(arguments[1], namedConstructor.parameters[1]);
    }
  }

  test_constructor_redirected() async {
    addTestFile(r'''
class A implements B {
  A(int a);
  A.named(double a);
}
class B {
  factory B.one(int b) = A;
  factory B.two(double b) = A.named;
}
''');
    AnalysisResult result = await driver.getResult(testFile);
    expect(result.errors, isEmpty);

    ClassDeclaration aNode = result.unit.declarations[0];
    ClassElement aElement = aNode.element;

    ClassDeclaration bNode = result.unit.declarations[1];

    {
      ConstructorElement aUnnamed = aElement.constructors[0];

      ConstructorDeclaration constructor = bNode.members[0];
      ConstructorElement element = constructor.element;
      expect(element.redirectedConstructor, same(aUnnamed));

      var constructorName = constructor.redirectedConstructor;
      expect(constructorName.staticElement, same(aUnnamed));

      TypeName typeName = constructorName.type;
      expect(typeName.type, aElement.type);

      SimpleIdentifier identifier = typeName.name;
      expect(identifier.staticElement, same(aElement));
      expect(identifier.staticType, aElement.type);

      expect(constructorName.name, isNull);
    }

    {
      ConstructorElement aNamed = aElement.constructors[1];

      ConstructorDeclaration constructor = bNode.members[1];
      ConstructorElement element = constructor.element;
      expect(element.redirectedConstructor, same(aNamed));

      var constructorName = constructor.redirectedConstructor;
      expect(constructorName.staticElement, same(aNamed));

      TypeName typeName = constructorName.type;
      expect(typeName.type, aElement.type);

      SimpleIdentifier identifier = typeName.name;
      expect(identifier.staticElement, same(aElement));
      expect(identifier.staticType, aElement.type);

      expect(constructorName.name.staticElement, aNamed);
      expect(constructorName.name.staticType, isNull);
    }
  }

  test_constructor_redirected_generic() async {
    addTestFile(r'''
class A<T> implements B<T> {
  A(int a);
  A.named(double a);
}
class B<U> {
  factory B.one(int b) = A<U>;
  factory B.two(double b) = A<U>.named;
}
''');
    AnalysisResult result = await driver.getResult(testFile);
    expect(result.errors, isEmpty);

    ClassDeclaration aNode = result.unit.declarations[0];
    ClassElement aElement = aNode.element;

    ClassDeclaration bNode = result.unit.declarations[1];
    TypeParameterType uType = bNode.element.typeParameters[0].type;
    InterfaceType auType = aElement.type.instantiate([uType]);

    {
      ConstructorElement expectedElement = aElement.constructors[0];

      ConstructorDeclaration constructor = bNode.members[0];
      ConstructorElement element = constructor.element;

      ConstructorMember actualMember = element.redirectedConstructor;
      expect(actualMember.baseElement, same(expectedElement));
      expect(actualMember.definingType, auType);

      var constructorName = constructor.redirectedConstructor;
      expect(constructorName.staticElement, same(actualMember));

      TypeName typeName = constructorName.type;
      expect(typeName.type, auType);

      SimpleIdentifier identifier = typeName.name;
      expect(identifier.staticElement, same(aElement));
      expect(identifier.staticType, auType);

      expect(constructorName.name, isNull);
    }

    {
      ConstructorElement expectedElement = aElement.constructors[1];

      ConstructorDeclaration constructor = bNode.members[1];
      ConstructorElement element = constructor.element;

      ConstructorMember actualMember = element.redirectedConstructor;
      expect(actualMember.baseElement, same(expectedElement));
      expect(actualMember.definingType, auType);

      var constructorName = constructor.redirectedConstructor;
      expect(constructorName.staticElement, same(actualMember));

      TypeName typeName = constructorName.type;
      expect(typeName.type, auType);

      SimpleIdentifier identifier = typeName.name;
      expect(identifier.staticElement, same(aElement));
      expect(identifier.staticType, auType);

      expect(constructorName.name.staticElement, same(actualMember));
      expect(constructorName.name.staticType, isNull);
    }
  }

  test_error_unresolvedTypeAnnotation() async {
    String content = r'''
main() {
  Foo<int> v = null;
}
''';
    addTestFile(content);
    AnalysisResult result = await driver.getResult(testFile);
    var typeProvider = result.unit.element.context.typeProvider;

    var statements = _getMainStatements(result);

    VariableDeclarationStatement statement = statements[0];

    TypeName typeName = statement.variables.type;
    expect(typeName.type, isUndefinedType);
    if (previewDart2) {
      expect(typeName.typeArguments.arguments[0].type, isUndefinedType);
    } else {
      expect(typeName.typeArguments.arguments[0].type, typeProvider.intType);
    }

    VariableDeclaration vNode = statement.variables.variables[0];
    expect(vNode.name.staticType, isUndefinedType);
    expect(vNode.element.type, isUndefinedType);
  }

  test_field_context() async {
    addTestFile(r'''
class C<T> {
  var f = <T>[];
}
''');
    AnalysisResult result = await driver.getResult(testFile);
    var typeProvider = result.unit.element.context.typeProvider;

    ClassDeclaration cNode = result.unit.declarations[0];
    var tElement = cNode.element.typeParameters[0];

    FieldDeclaration fDeclaration = cNode.members[0];
    VariableDeclaration fNode = fDeclaration.fields.variables[0];
    FieldElement fElement = fNode.element;
    expect(fElement.type, typeProvider.listType.instantiate([tElement.type]));
  }

  test_formalParameter_functionTyped() async {
    addTestFile(r'''
class A {
  A(String p(int a));
}
''');
    AnalysisResult result = await driver.getResult(testFile);
    var typeProvider = result.unit.element.context.typeProvider;

    ClassDeclaration clazz = result.unit.declarations[0];
    ConstructorDeclaration constructor = clazz.members[0];
    List<FormalParameter> parameters = constructor.parameters.parameters;

    FunctionTypedFormalParameter p = parameters[0];
    expect(p.element, same(constructor.element.parameters[0]));

    {
      FunctionType type = p.identifier.staticType;
      expect(type.returnType, typeProvider.stringType);

      expect(type.parameters, hasLength(1));
      expect(type.parameters[0].type, typeProvider.intType);
    }

    _assertTypeNameSimple(p.returnType, typeProvider.stringType);

    {
      SimpleFormalParameter a = p.parameters.parameters[0];
      _assertTypeNameSimple(a.type, typeProvider.intType);
      expect(a.identifier.staticType, typeProvider.intType);
    }
  }

  test_formalParameter_functionTyped_fieldFormal_typed() async {
    // TODO(scheglov) Add "untyped" version with precise type in field.
    addTestFile(r'''
class A {
  Function f;
  A(String this.f(int a));
}
''');
    AnalysisResult result = await driver.getResult(testFile);
    var typeProvider = result.unit.element.context.typeProvider;

    ClassDeclaration clazz = result.unit.declarations[0];

    FieldDeclaration fDeclaration = clazz.members[0];
    VariableDeclaration fNode = fDeclaration.fields.variables[0];
    FieldElement fElement = fNode.element;

    ConstructorDeclaration constructor = clazz.members[1];

    FieldFormalParameterElement pElement = constructor.element.parameters[0];
    expect(pElement.field, same(fElement));

    List<FormalParameter> parameters = constructor.parameters.parameters;
    FieldFormalParameter p = parameters[0];
    expect(p.element, same(pElement));

    expect(p.identifier.staticElement, same(pElement));
    expect(p.identifier.staticType.toString(), '(int) → String');

    {
      FunctionType type = p.identifier.staticType;
      expect(type.returnType, typeProvider.stringType);

      expect(type.parameters, hasLength(1));
      expect(type.parameters[0].type, typeProvider.intType);
    }

    _assertTypeNameSimple(p.type, typeProvider.stringType);

    {
      SimpleFormalParameter a = p.parameters.parameters[0];
      _assertTypeNameSimple(a.type, typeProvider.intType);
      expect(a.identifier.staticType, typeProvider.intType);
    }
  }

  test_formalParameter_simple_fieldFormal() async {
    addTestFile(r'''
class A {
  int f;
  A(this.f);
}
''');
    AnalysisResult result = await driver.getResult(testFile);
    var typeProvider = result.unit.element.context.typeProvider;

    ClassDeclaration clazz = result.unit.declarations[0];

    FieldDeclaration fDeclaration = clazz.members[0];
    VariableDeclaration fNode = fDeclaration.fields.variables[0];
    FieldElement fElement = fNode.element;

    ConstructorDeclaration constructor = clazz.members[1];
    List<FormalParameter> parameters = constructor.parameters.parameters;

    FieldFormalParameterElement parameterElement =
        constructor.element.parameters[0];
    expect(parameterElement.field, same(fElement));

    FieldFormalParameter parameterNode = parameters[0];
    expect(parameterNode.type, isNull);
    expect(parameterNode.element, same(parameterElement));

    expect(parameterNode.identifier.staticElement, same(parameterElement));
    expect(parameterNode.identifier.staticType, typeProvider.intType);
  }

  test_formalParameter_simple_fieldFormal_typed() async {
    addTestFile(r'''
class A {
  int f;
  A(int this.f);
}
''');
    AnalysisResult result = await driver.getResult(testFile);
    var typeProvider = result.unit.element.context.typeProvider;

    ClassDeclaration clazz = result.unit.declarations[0];

    FieldDeclaration fDeclaration = clazz.members[0];
    VariableDeclaration fNode = fDeclaration.fields.variables[0];
    FieldElement fElement = fNode.element;

    ConstructorDeclaration constructor = clazz.members[1];
    List<FormalParameter> parameters = constructor.parameters.parameters;

    FieldFormalParameterElement parameterElement =
        constructor.element.parameters[0];
    expect(parameterElement.field, same(fElement));

    FieldFormalParameter parameterNode = parameters[0];
    _assertTypeNameSimple(parameterNode.type, typeProvider.intType);
    expect(parameterNode.element, same(parameterElement));

    expect(parameterNode.identifier.staticElement, same(parameterElement));
    expect(parameterNode.identifier.staticType, typeProvider.intType);
  }

  test_functionExpressionInvocation() async {
    addTestFile(r'''
typedef Foo<S> = S Function<T>(T x);
void main(f) {
  (f as Foo<int>)<String>('hello');
}
''');
    AnalysisResult result = await driver.getResult(testFile);
    var typeProvider = result.unit.element.context.typeProvider;

    List<Statement> statements = _getMainStatements(result);

    ExpressionStatement statement = statements[0];
    FunctionExpressionInvocation invocation = statement.expression;

    expect(invocation.staticElement, isNull);
    expect(invocation.staticInvokeType.toString(), '(String) → int');
    expect(invocation.staticType, typeProvider.intType);

    List<TypeAnnotation> typeArguments = invocation.typeArguments.arguments;
    expect(typeArguments, hasLength(1));
    _assertTypeNameSimple(typeArguments[0], typeProvider.stringType);
  }

  test_indexExpression() async {
    String content = r'''
main() {
  var items = <int>[1, 2, 3];
  items[0];
}
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;

    var typeProvider = unit.element.context.typeProvider;
    InterfaceType intType = typeProvider.intType;
    InterfaceType listType = typeProvider.listType;
    InterfaceType listIntType = listType.instantiate([intType]);

    List<Statement> mainStatements = _getMainStatements(result);

    VariableElement itemsElement;
    {
      VariableDeclarationStatement statement = mainStatements[0];
      VariableDeclaration itemsNode = statement.variables.variables[0];
      itemsElement = itemsNode.element;
      expect(itemsElement.type, listIntType);
    }

    ExpressionStatement statement = mainStatements[1];
    IndexExpression indexExpression = statement.expression;
    expect(indexExpression.staticType, intType);

    MethodMember actualElement = indexExpression.staticElement;
    MethodMember expectedElement = listIntType.getMethod('[]');
    expect(actualElement.name, '[]');
    expect(actualElement.baseElement, same(expectedElement.baseElement));
    expect(actualElement.returnType, intType);
    expect(actualElement.parameters[0].type, intType);
  }

  test_instanceCreation_factory() async {
    String content = r'''
class C {
  factory C() => null;
  factory C.named() => null;
}
var a = new C();
var b = new C.named();
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;

    ClassDeclaration cNode = unit.declarations[0];
    ClassElement cElement = cNode.element;
    ConstructorElement defaultConstructor = cElement.constructors[0];
    ConstructorElement namedConstructor = cElement.constructors[1];

    {
      TopLevelVariableDeclaration aDeclaration = unit.declarations[1];
      VariableDeclaration aNode = aDeclaration.variables.variables[0];
      InstanceCreationExpression value = aNode.initializer;
      expect(value.staticElement, defaultConstructor);
      expect(value.staticType, cElement.type);

      TypeName typeName = value.constructorName.type;
      expect(typeName.typeArguments, isNull);

      Identifier typeIdentifier = typeName.name;
      expect(typeIdentifier.staticElement, cElement);
      expect(typeIdentifier.staticType, cElement.type);

      expect(value.constructorName.name, isNull);
    }

    {
      TopLevelVariableDeclaration bDeclaration = unit.declarations[2];
      VariableDeclaration bNode = bDeclaration.variables.variables[0];
      InstanceCreationExpression value = bNode.initializer;
      expect(value.staticElement, namedConstructor);
      expect(value.staticType, cElement.type);

      TypeName typeName = value.constructorName.type;
      expect(typeName.typeArguments, isNull);

      SimpleIdentifier typeIdentifier = typeName.name;
      expect(typeIdentifier.staticElement, cElement);
      expect(typeIdentifier.staticType, cElement.type);

      SimpleIdentifier constructorName = value.constructorName.name;
      expect(constructorName.staticElement, namedConstructor);
      expect(constructorName.staticType, isNull);
    }
  }

  test_instanceCreation_namedArgument() async {
    addTestFile(r'''
class X {
  X(int a, {bool b, double c});
}
var v = new X(1, b: true, c: 3.0);
''');

    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;

    ClassDeclaration xNode = unit.declarations[0];
    ClassElement xElement = xNode.element;
    ConstructorElement constructorElement = xElement.constructors[0];

    TopLevelVariableDeclaration vDeclaration = unit.declarations[1];
    VariableDeclaration vNode = vDeclaration.variables.variables[0];

    InstanceCreationExpression creation = vNode.initializer;
    List<Expression> arguments = creation.argumentList.arguments;
    expect(creation.staticElement, constructorElement);
    expect(creation.staticType, xElement.type);

    TypeName typeName = creation.constructorName.type;
    expect(typeName.typeArguments, isNull);

    Identifier typeIdentifier = typeName.name;
    expect(typeIdentifier.staticElement, xElement);
    expect(typeIdentifier.staticType, xElement.type);

    expect(creation.constructorName.name, isNull);

    _assertArgumentToParameter(arguments[0], constructorElement.parameters[0]);
    _assertArgumentToParameter(arguments[1], constructorElement.parameters[1]);
    _assertArgumentToParameter(arguments[2], constructorElement.parameters[2]);
  }

  test_instanceCreation_noTypeArguments() async {
    String content = r'''
class C {
  C(int p);
  C.named(int p);
}
var a = new C(1);
var b = new C.named(2);
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;

    ClassDeclaration cNode = unit.declarations[0];
    ClassElement cElement = cNode.element;
    ConstructorElement defaultConstructor = cElement.constructors[0];
    ConstructorElement namedConstructor = cElement.constructors[1];

    {
      TopLevelVariableDeclaration aDeclaration = unit.declarations[1];
      VariableDeclaration aNode = aDeclaration.variables.variables[0];
      InstanceCreationExpression value = aNode.initializer;
      expect(value.staticElement, defaultConstructor);
      expect(value.staticType, cElement.type);

      TypeName typeName = value.constructorName.type;
      expect(typeName.typeArguments, isNull);

      Identifier typeIdentifier = typeName.name;
      expect(typeIdentifier.staticElement, cElement);
      expect(typeIdentifier.staticType, cElement.type);

      expect(value.constructorName.name, isNull);

      Expression argument = value.argumentList.arguments[0];
      _assertArgumentToParameter(argument, defaultConstructor.parameters[0]);
    }

    {
      TopLevelVariableDeclaration bDeclaration = unit.declarations[2];
      VariableDeclaration bNode = bDeclaration.variables.variables[0];
      InstanceCreationExpression value = bNode.initializer;
      expect(value.staticElement, namedConstructor);
      expect(value.staticType, cElement.type);

      TypeName typeName = value.constructorName.type;
      expect(typeName.typeArguments, isNull);

      SimpleIdentifier typeIdentifier = typeName.name;
      expect(typeIdentifier.staticElement, cElement);
      expect(typeIdentifier.staticType, cElement.type);

      SimpleIdentifier constructorName = value.constructorName.name;
      expect(constructorName.staticElement, namedConstructor);
      expect(constructorName.staticType, isNull);

      Expression argument = value.argumentList.arguments[0];
      _assertArgumentToParameter(argument, namedConstructor.parameters[0]);
    }
  }

  test_instanceCreation_prefixed() async {
    var a = _p('/test/lib/a.dart');
    provider.newFile(a, r'''
class C<T> {
  C(T p);
  C.named(T p);
}
''');
    addTestFile(r'''
import 'a.dart' as p;
main() {
  new p.C(0);
  new p.C.named(1.2);
  new p.C<bool>.named(false);
}
''');
    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;
    var typeProvider = unit.element.context.typeProvider;

    ImportElement aImport = unit.element.library.imports[0];
    LibraryElement aLibrary = aImport.importedLibrary;

    ClassElement cElement = aLibrary.getType('C');
    ConstructorElement defaultConstructor = cElement.constructors[0];
    ConstructorElement namedConstructor = cElement.constructors[1];
    InterfaceType cType = cElement.type;
    var cTypeDynamic = cType.instantiate([DynamicTypeImpl.instance]);

    var statements = _getMainStatements(result);
    {
      var cTypeInt = cType.instantiate([typeProvider.intType]);

      ExpressionStatement statement = statements[0];
      InstanceCreationExpression creation = statement.expression;
      expect(creation.staticElement, defaultConstructor);
      expect(creation.staticType, cTypeInt);

      TypeName typeName = creation.constructorName.type;
      expect(typeName.typeArguments, isNull);

      PrefixedIdentifier typeIdentifier = typeName.name;
      expect(typeIdentifier.staticElement, same(cElement));
      if (previewDart2) {
        expect(typeIdentifier.staticType, cTypeInt);
      } else {
        expect(typeIdentifier.staticType, cTypeDynamic);
      }

      SimpleIdentifier typePrefix = typeIdentifier.prefix;
      expect(typePrefix.name, 'p');
      expect(typePrefix.staticElement, same(aImport.prefix));
      expect(typePrefix.staticType, isNull);

      expect(typeIdentifier.identifier.staticElement, same(cElement));

      expect(creation.constructorName.name, isNull);
    }

    {
      var cTypeDouble = cType.instantiate([typeProvider.doubleType]);

      ExpressionStatement statement = statements[1];
      InstanceCreationExpression creation = statement.expression;
      expect(creation.staticElement, namedConstructor);
      expect(creation.staticType, cTypeDouble);

      TypeName typeName = creation.constructorName.type;
      expect(typeName.typeArguments, isNull);

      PrefixedIdentifier typeIdentifier = typeName.name;
      expect(typeIdentifier.staticElement, cElement);
      if (previewDart2) {
        expect(typeIdentifier.staticType, cTypeDouble);
      } else {
        expect(typeIdentifier.staticType, cTypeDynamic);
      }

      SimpleIdentifier typePrefix = typeIdentifier.prefix;
      expect(typePrefix.name, 'p');
      expect(typePrefix.staticElement, same(aImport.prefix));
      expect(typePrefix.staticType, isNull);

      expect(typeIdentifier.identifier.staticElement, same(cElement));

      SimpleIdentifier constructorName = creation.constructorName.name;
      expect(constructorName.staticElement, namedConstructor);
      expect(constructorName.staticType, isNull);
    }

    {
      var cTypeBool = cType.instantiate([typeProvider.boolType]);

      ExpressionStatement statement = statements[2];
      InstanceCreationExpression creation = statement.expression;
      expect(creation.staticElement, namedConstructor);
      expect(creation.staticType, cTypeBool);

      TypeName typeName = creation.constructorName.type;
      expect(typeName.typeArguments.arguments, hasLength(1));
      _assertTypeNameSimple(
          typeName.typeArguments.arguments[0], typeProvider.boolType);

      PrefixedIdentifier typeIdentifier = typeName.name;
      expect(typeIdentifier.staticElement, cElement);
      expect(typeIdentifier.staticType, cTypeBool);

      SimpleIdentifier typePrefix = typeIdentifier.prefix;
      expect(typePrefix.name, 'p');
      expect(typePrefix.staticElement, same(aImport.prefix));
      expect(typePrefix.staticType, isNull);

      expect(typeIdentifier.identifier.staticElement, same(cElement));

      SimpleIdentifier constructorName = creation.constructorName.name;
      expect(constructorName.staticElement, namedConstructor);
      expect(constructorName.staticType, isNull);
    }
  }

  test_instanceCreation_withTypeArguments() async {
    String content = r'''
class C<K, V> {
  C(K k, V v);
  C.named(K k, V v);
}
var a = new C<int, double>(1, 2.3);
var b = new C<num, String>.named(4, 'five');
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;
    var typeProvider = unit.element.context.typeProvider;

    ClassDeclaration cNode = unit.declarations[0];
    ClassElement cElement = cNode.element;
    ConstructorElement defaultConstructor = cElement.constructors[0];
    ConstructorElement namedConstructor = cElement.constructors[1];

    {
      TopLevelVariableDeclaration aDeclaration = unit.declarations[1];
      VariableDeclaration aNode = aDeclaration.variables.variables[0];

      InstanceCreationExpression value = aNode.initializer;
      InterfaceType instantiatedType = cElement.type
          .instantiate([typeProvider.intType, typeProvider.doubleType]);

      expect(value.staticElement, defaultConstructor);
      expect(value.staticType, instantiatedType);

      TypeName typeName = value.constructorName.type;

      Identifier typeIdentifier = typeName.name;
      expect(typeIdentifier.staticElement, cElement);
      expect(typeIdentifier.staticType, instantiatedType);

      TypeName typeArgument1 = typeName.typeArguments.arguments[0];
      expect(typeArgument1.type, typeProvider.intType);
      expect(typeArgument1.name.staticType, typeProvider.intType);
      expect(typeArgument1.name.staticElement, typeProvider.intType.element);

      TypeName typeArgument2 = typeName.typeArguments.arguments[1];
      expect(typeArgument2.type, typeProvider.doubleType);
      expect(typeArgument2.name.staticType, typeProvider.doubleType);
      expect(typeArgument2.name.staticElement, typeProvider.doubleType.element);

      expect(value.constructorName.name, isNull);

      Expression argument = value.argumentList.arguments[0];
      _assertArgumentToParameter(argument, defaultConstructor.parameters[0]);
    }

    {
      TopLevelVariableDeclaration bDeclaration = unit.declarations[2];
      VariableDeclaration bNode = bDeclaration.variables.variables[0];

      InstanceCreationExpression value = bNode.initializer;
      InterfaceType instantiatedType = cElement.type
          .instantiate([typeProvider.numType, typeProvider.stringType]);

      expect(value.staticElement, namedConstructor);
      expect(value.staticType, instantiatedType);

      TypeName typeName = value.constructorName.type;

      SimpleIdentifier typeIdentifier = typeName.name;
      expect(typeIdentifier.staticElement, cElement);
      expect(typeIdentifier.staticType, instantiatedType);

      TypeName typeArgument1 = typeName.typeArguments.arguments[0];
      expect(typeArgument1.type, typeProvider.numType);
      expect(typeArgument1.name.staticType, typeProvider.numType);
      expect(typeArgument1.name.staticElement, typeProvider.numType.element);

      TypeName typeArgument2 = typeName.typeArguments.arguments[1];
      expect(typeArgument2.type, typeProvider.stringType);
      expect(typeArgument2.name.staticType, typeProvider.stringType);
      expect(typeArgument2.name.staticElement, typeProvider.stringType.element);

      SimpleIdentifier constructorName = value.constructorName.name;
      expect(constructorName.staticElement, namedConstructor);
      expect(constructorName.staticType, isNull);

      Expression argument = value.argumentList.arguments[0];
      _assertArgumentToParameter(argument, namedConstructor.parameters[0]);
    }
  }

  test_isExpression() async {
    String content = r'''
void main() {
  var v = 42;
  v is num;
}
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    expect(result.path, testFile);
    expect(result.errors, isEmpty);

    var typeProvider = result.unit.element.context.typeProvider;
    NodeList<Statement> statements = _getMainStatements(result);

    // var v = 42;
    VariableElement vElement;
    {
      VariableDeclarationStatement statement = statements[0];
      vElement = statement.variables.variables[0].name.staticElement;
    }

    // v is num;
    {
      ExpressionStatement statement = statements[1];
      IsExpression isExpression = statement.expression;
      expect(isExpression.notOperator, isNull);
      expect(isExpression.staticType, typeProvider.boolType);

      SimpleIdentifier target = isExpression.expression;
      expect(target.staticElement, vElement);
      expect(target.staticType, typeProvider.intType);

      TypeName numName = isExpression.type;
      expect(numName.name.staticElement, typeProvider.numType.element);
      expect(numName.name.staticType, typeProvider.numType);
    }
  }

  test_isExpression_not() async {
    String content = r'''
void main() {
  var v = 42;
  v is! num;
}
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    expect(result.path, testFile);
    expect(result.errors, isEmpty);

    var typeProvider = result.unit.element.context.typeProvider;
    NodeList<Statement> statements = _getMainStatements(result);

    // var v = 42;
    VariableElement vElement;
    {
      VariableDeclarationStatement statement = statements[0];
      vElement = statement.variables.variables[0].name.staticElement;
    }

    // v is! num;
    {
      ExpressionStatement statement = statements[1];
      IsExpression isExpression = statement.expression;
      expect(isExpression.notOperator, isNotNull);
      expect(isExpression.staticType, typeProvider.boolType);

      SimpleIdentifier target = isExpression.expression;
      expect(target.staticElement, vElement);
      expect(target.staticType, typeProvider.intType);

      TypeName numName = isExpression.type;
      expect(numName.name.staticElement, typeProvider.numType.element);
      expect(numName.name.staticType, typeProvider.numType);
    }
  }

  test_local_function() async {
    addTestFile(r'''
void main() {
  double f(int a, String b) {}
  var v = f(1, '2');
}
''');
    String fTypeString = '(int, String) → double';

    AnalysisResult result = await driver.getResult(testFile);
    List<Statement> mainStatements = _getMainStatements(result);

    var typeProvider = result.unit.element.context.typeProvider;
    InterfaceType doubleType = typeProvider.doubleType;

    FunctionDeclarationStatement fStatement = mainStatements[0];
    FunctionDeclaration fNode = fStatement.functionDeclaration;
    FunctionExpression fExpression = fNode.functionExpression;
    FunctionElement fElement = fNode.element;
    expect(fElement, isNotNull);
    expect(fElement.type.toString(), fTypeString);

    expect(fNode.name.staticElement, same(fElement));
    expect(fNode.name.staticType, fElement.type);

    TypeName fReturnTypeNode = fNode.returnType;
    expect(fReturnTypeNode.name.staticElement, same(doubleType.element));
    expect(fReturnTypeNode.type, doubleType);

    expect(fExpression.element, same(fElement));

    {
      List<ParameterElement> elements = fElement.parameters;
      expect(elements, hasLength(2));

      List<FormalParameter> nodes = fExpression.parameters.parameters;
      expect(nodes, hasLength(2));

      _assertSimpleParameter(nodes[0], elements[0],
          name: 'a',
          offset: 29,
          kind: ParameterKind.REQUIRED,
          type: typeProvider.intType);

      _assertSimpleParameter(nodes[1], elements[1],
          name: 'b',
          offset: 39,
          kind: ParameterKind.REQUIRED,
          type: typeProvider.stringType);
    }

    VariableDeclarationStatement vStatement = mainStatements[1];
    VariableDeclaration vDeclaration = vStatement.variables.variables[0];
    expect(vDeclaration.element.type, same(doubleType));

    MethodInvocation fInvocation = vDeclaration.initializer;
    expect(fInvocation.methodName.staticElement, same(fElement));
    expect(fInvocation.methodName.staticType.toString(), fTypeString);
    expect(fInvocation.staticType, same(doubleType));
    expect(fInvocation.staticInvokeType.toString(), fTypeString);
  }

  test_local_function_generic() async {
    addTestFile(r'''
void main() {
  T f<T, U>(T a, U b) {}
  var v = f(1, '2');
}
''');
    AnalysisResult result = await driver.getResult(testFile);
    var typeProvider = result.unit.element.context.typeProvider;
    List<Statement> mainStatements = _getMainStatements(result);

    FunctionDeclarationStatement fStatement = mainStatements[0];
    FunctionDeclaration fNode = fStatement.functionDeclaration;
    FunctionExpression fExpression = fNode.functionExpression;
    FunctionElement fElement = fNode.element;

    TypeParameterElement tElement = fElement.typeParameters[0];
    TypeParameterElement uElement = fElement.typeParameters[1];

    {
      var fTypeParameters = fExpression.typeParameters.typeParameters;
      expect(fTypeParameters, hasLength(2));

      TypeParameter tNode = fTypeParameters[0];
      expect(tNode.element, same(tElement));
      expect(tNode.name.staticElement, same(tElement));
      expect(tNode.name.staticType, typeProvider.typeType);

      TypeParameter uNode = fTypeParameters[1];
      expect(uNode.element, same(uElement));
      expect(uNode.name.staticElement, same(uElement));
      expect(uNode.name.staticType, typeProvider.typeType);
    }

    expect(fElement, isNotNull);
    expect(fElement.type.toString(), '<T,U>(T, U) → T');

    expect(fNode.name.staticElement, same(fElement));
    expect(fNode.name.staticType, fElement.type);

    TypeName fReturnTypeNode = fNode.returnType;
    expect(fReturnTypeNode.name.staticElement, same(tElement));
    expect(fReturnTypeNode.type, tElement.type);

    expect(fExpression.element, same(fElement));

    {
      List<ParameterElement> elements = fElement.parameters;
      expect(elements, hasLength(2));

      List<FormalParameter> nodes = fExpression.parameters.parameters;
      expect(nodes, hasLength(2));

      _assertSimpleParameter(nodes[0], elements[0],
          name: 'a',
          offset: 28,
          kind: ParameterKind.REQUIRED,
          type: tElement.type);

      _assertSimpleParameter(nodes[1], elements[1],
          name: 'b',
          offset: 33,
          kind: ParameterKind.REQUIRED,
          type: uElement.type);
    }

    VariableDeclarationStatement vStatement = mainStatements[1];
    VariableDeclaration vDeclaration = vStatement.variables.variables[0];
    expect(vDeclaration.element.type, typeProvider.intType);

    MethodInvocation fInvocation = vDeclaration.initializer;
    expect(fInvocation.methodName.staticElement, same(fElement));
    expect(fInvocation.staticType, typeProvider.intType);
    // TODO(scheglov) We don't support invoke types well.
//    if (previewDart2) {
//      String fInstantiatedType = '(int, String) → int';
//      expect(fInvocation.methodName.staticType.toString(), fInstantiatedType);
//      expect(fInvocation.staticInvokeType.toString(), fInstantiatedType);
//    }
  }

  test_local_function_namedParameters() async {
    addTestFile(r'''
void main() {
  double f(int a, {String b, bool c: false}) {}
  f(1, b: '2', c: true);
}
''');
    String fTypeString = '(int, {b: String, c: bool}) → double';

    AnalysisResult result = await driver.getResult(testFile);
    List<Statement> mainStatements = _getMainStatements(result);

    var typeProvider = result.unit.element.context.typeProvider;
    InterfaceType doubleType = typeProvider.doubleType;

    FunctionDeclarationStatement fStatement = mainStatements[0];
    FunctionDeclaration fNode = fStatement.functionDeclaration;
    FunctionExpression fExpression = fNode.functionExpression;
    FunctionElement fElement = fNode.element;
    expect(fElement, isNotNull);
    expect(fElement.type.toString(), fTypeString);

    expect(fNode.name.staticElement, same(fElement));
    expect(fNode.name.staticType, fElement.type);

    TypeName fReturnTypeNode = fNode.returnType;
    expect(fReturnTypeNode.name.staticElement, same(doubleType.element));
    expect(fReturnTypeNode.type, doubleType);

    expect(fExpression.element, same(fElement));

    {
      List<ParameterElement> elements = fElement.parameters;
      expect(elements, hasLength(3));

      List<FormalParameter> nodes = fExpression.parameters.parameters;
      expect(nodes, hasLength(3));

      _assertSimpleParameter(nodes[0], elements[0],
          name: 'a',
          offset: 29,
          kind: ParameterKind.REQUIRED,
          type: typeProvider.intType);

      _assertDefaultParameter(nodes[1], elements[1],
          name: 'b',
          offset: 40,
          kind: ParameterKind.NAMED,
          type: typeProvider.stringType);

      _assertDefaultParameter(nodes[2], elements[2],
          name: 'c',
          offset: 48,
          kind: ParameterKind.NAMED,
          type: typeProvider.boolType);
    }

    {
      ExpressionStatement statement = mainStatements[1];
      MethodInvocation invocation = statement.expression;
      List<Expression> arguments = invocation.argumentList.arguments;

      _assertArgumentToParameter(arguments[0], fElement.parameters[0]);
      _assertArgumentToParameter(arguments[1], fElement.parameters[1]);
      _assertArgumentToParameter(arguments[2], fElement.parameters[2]);
    }
  }

  test_local_function_noReturnType() async {
    addTestFile(r'''
void main() {
  f() {}
}
''');

    AnalysisResult result = await driver.getResult(testFile);
    List<Statement> mainStatements = _getMainStatements(result);

    FunctionDeclarationStatement fStatement = mainStatements[0];
    FunctionDeclaration fNode = fStatement.functionDeclaration;
    FunctionExpression fExpression = fNode.functionExpression;
    FunctionElement fElement = fNode.element;

    expect(fNode.returnType, isNull);
    expect(fElement, isNotNull);
    expect(fElement.type.toString(), '() → Null');

    expect(fNode.name.staticElement, same(fElement));
    expect(fNode.name.staticType, fElement.type);

    expect(fExpression.element, same(fElement));
  }

  test_local_function_optionalParameters() async {
    addTestFile(r'''
void main() {
  double f(int a, [String b, bool c]) {}
  var v = f(1, '2', true);
}
''');
    String fTypeString = '(int, [String, bool]) → double';

    AnalysisResult result = await driver.getResult(testFile);
    List<Statement> mainStatements = _getMainStatements(result);

    var typeProvider = result.unit.element.context.typeProvider;
    InterfaceType doubleType = typeProvider.doubleType;

    FunctionDeclarationStatement fStatement = mainStatements[0];
    FunctionDeclaration fNode = fStatement.functionDeclaration;
    FunctionExpression fExpression = fNode.functionExpression;
    FunctionElement fElement = fNode.element;
    expect(fElement, isNotNull);
    expect(fElement.type.toString(), fTypeString);

    expect(fNode.name.staticElement, same(fElement));
    expect(fNode.name.staticType, fElement.type);

    TypeName fReturnTypeNode = fNode.returnType;
    expect(fReturnTypeNode.name.staticElement, same(doubleType.element));
    expect(fReturnTypeNode.type, doubleType);

    expect(fExpression.element, same(fElement));

    {
      List<ParameterElement> elements = fElement.parameters;
      expect(elements, hasLength(3));

      List<FormalParameter> nodes = fExpression.parameters.parameters;
      expect(nodes, hasLength(3));

      _assertSimpleParameter(nodes[0], elements[0],
          name: 'a',
          offset: 29,
          kind: ParameterKind.REQUIRED,
          type: typeProvider.intType);

      _assertDefaultParameter(nodes[1], elements[1],
          name: 'b',
          offset: 40,
          kind: ParameterKind.POSITIONAL,
          type: typeProvider.stringType);

      _assertDefaultParameter(nodes[2], elements[2],
          name: 'c',
          offset: 48,
          kind: ParameterKind.POSITIONAL,
          type: typeProvider.boolType);
    }

    {
      VariableDeclarationStatement statement = mainStatements[1];
      VariableDeclaration declaration = statement.variables.variables[0];
      expect(declaration.element.type, same(doubleType));

      MethodInvocation invocation = declaration.initializer;
      expect(invocation.methodName.staticElement, same(fElement));
      expect(invocation.methodName.staticType.toString(), fTypeString);
      expect(invocation.staticType, same(doubleType));
      expect(invocation.staticInvokeType.toString(), fTypeString);

      List<Expression> arguments = invocation.argumentList.arguments;
      _assertArgumentToParameter(arguments[0], fElement.parameters[0]);
      _assertArgumentToParameter(arguments[1], fElement.parameters[1]);
      _assertArgumentToParameter(arguments[2], fElement.parameters[2]);
    }
  }

  test_local_parameter() async {
    String content = r'''
void main(int p) {
  p;
}
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    expect(result.path, testFile);
    expect(result.errors, isEmpty);

    var typeProvider = result.unit.element.context.typeProvider;
    InterfaceType intType = typeProvider.intType;

    FunctionDeclaration main = result.unit.declarations[0];
    List<Statement> statements = _getMainStatements(result);

    // (int p)
    VariableElement pElement = main.element.parameters[0];
    expect(pElement.type, intType);

    // p;
    {
      ExpressionStatement statement = statements[0];
      SimpleIdentifier identifier = statement.expression;
      expect(identifier.staticElement, pElement);
      expect(identifier.staticType, intType);
    }
  }

  test_local_parameter_ofLocalFunction() async {
    addTestFile(r'''
void main() {
  void f(int a) {
    a;
    void g(double b) {
      b;
    }
  }
}
''');
    AnalysisResult result = await driver.getResult(testFile);

    var typeProvider = result.unit.element.context.typeProvider;

    List<Statement> mainStatements = _getMainStatements(result);

    // f(int a) {}
    FunctionDeclarationStatement fStatement = mainStatements[0];
    FunctionDeclaration fNode = fStatement.functionDeclaration;
    FunctionExpression fExpression = fNode.functionExpression;
    FunctionElement fElement = fNode.element;
    ParameterElement aElement = fElement.parameters[0];
    _assertSimpleParameter(fExpression.parameters.parameters[0], aElement,
        name: 'a',
        offset: 27,
        kind: ParameterKind.REQUIRED,
        type: typeProvider.intType);

    BlockFunctionBody fBody = fExpression.body;
    List<Statement> fStatements = fBody.block.statements;

    // a;
    ExpressionStatement aStatement = fStatements[0];
    SimpleIdentifier aNode = aStatement.expression;
    expect(aNode.staticElement, same(aElement));
    expect(aNode.staticType, typeProvider.intType);

    // g(double b) {}
    FunctionDeclarationStatement gStatement = fStatements[1];
    FunctionDeclaration gNode = gStatement.functionDeclaration;
    FunctionExpression gExpression = gNode.functionExpression;
    FunctionElement gElement = gNode.element;
    ParameterElement bElement = gElement.parameters[0];
    _assertSimpleParameter(gExpression.parameters.parameters[0], bElement,
        name: 'b',
        offset: 57,
        kind: ParameterKind.REQUIRED,
        type: typeProvider.doubleType);

    BlockFunctionBody gBody = gExpression.body;
    List<Statement> gStatements = gBody.block.statements;

    // b;
    ExpressionStatement bStatement = gStatements[0];
    SimpleIdentifier bNode = bStatement.expression;
    expect(bNode.staticElement, same(bElement));
    expect(bNode.staticType, typeProvider.doubleType);
  }

  test_local_variable() async {
    addTestFile(r'''
void main() {
  var v = 42;
  v;
}
''');
    AnalysisResult result = await driver.getResult(testFile);
    expect(result.path, testFile);
    expect(result.errors, isEmpty);

    var typeProvider = result.unit.element.context.typeProvider;
    InterfaceType intType = typeProvider.intType;

    FunctionDeclaration main = result.unit.declarations[0];
    expect(main.element, isNotNull);
    expect(main.name.staticElement, isNotNull);
    expect(main.name.staticType.toString(), '() → void');

    BlockFunctionBody body = main.functionExpression.body;
    NodeList<Statement> statements = body.block.statements;

    // var v = 42;
    VariableElement vElement;
    {
      VariableDeclarationStatement statement = statements[0];
      VariableDeclaration vNode = statement.variables.variables[0];
      expect(vNode.name.staticType, intType);
      expect(vNode.initializer.staticType, intType);

      vElement = vNode.name.staticElement;
      expect(vElement, isNotNull);
      expect(vElement.type, isNotNull);
      expect(vElement.type, intType);
    }

    // v;
    {
      ExpressionStatement statement = statements[1];
      SimpleIdentifier identifier = statement.expression;
      expect(identifier.staticElement, same(vElement));
      expect(identifier.staticType, intType);
    }
  }

  test_local_variable_forIn_identifier_field() async {
    addTestFile(r'''
class C {
  num v;
  void foo() {
    for (v in <int>[]) {
      v;
    }
  }
}
''');
    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;
    var typeProvider = unit.element.context.typeProvider;

    ClassDeclaration cDeclaration = unit.declarations[0];

    FieldDeclaration vDeclaration = cDeclaration.members[0];
    VariableDeclaration vNode = vDeclaration.fields.variables[0];
    FieldElement vElement = vNode.element;
    expect(vElement.type, typeProvider.numType);

    MethodDeclaration fooDeclaration = cDeclaration.members[1];
    BlockFunctionBody fooBody = fooDeclaration.body;
    List<Statement> statements = fooBody.block.statements;

    ForEachStatement forEachStatement = statements[0];
    Block forBlock = forEachStatement.body;

    expect(forEachStatement.loopVariable, isNull);

    SimpleIdentifier vInFor = forEachStatement.identifier;
    expect(vInFor.staticElement, same(vElement.setter));
    expect(vInFor.staticType, typeProvider.numType);

    ExpressionStatement statement = forBlock.statements[0];
    SimpleIdentifier identifier = statement.expression;
    expect(identifier.staticElement, same(vElement.getter));
    expect(identifier.staticType, typeProvider.numType);
  }

  test_local_variable_forIn_identifier_localVariable() async {
    addTestFile(r'''
void main() {
  num v;
  for (v in <int>[]) {
    v;
  }
}
''');
    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;
    var typeProvider = unit.element.context.typeProvider;

    List<Statement> statements = _getMainStatements(result);

    VariableDeclarationStatement vStatement = statements[0];
    VariableDeclaration vNode = vStatement.variables.variables[0];
    LocalVariableElement vElement = vNode.element;
    expect(vElement.type, typeProvider.numType);

    ForEachStatement forEachStatement = statements[1];
    Block forBlock = forEachStatement.body;

    expect(forEachStatement.loopVariable, isNull);

    SimpleIdentifier vInFor = forEachStatement.identifier;
    expect(vInFor.staticElement, vElement);
    expect(vInFor.staticType, typeProvider.numType);

    ExpressionStatement statement = forBlock.statements[0];
    SimpleIdentifier identifier = statement.expression;
    expect(identifier.staticElement, same(vElement));
    expect(identifier.staticType, typeProvider.numType);
  }

  test_local_variable_forIn_identifier_topLevelVariable() async {
    addTestFile(r'''
void main() {
  for (v in <int>[]) {
    v;
  }
}
num v;
''');
    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;
    var typeProvider = unit.element.context.typeProvider;

    List<Statement> statements = _getMainStatements(result);

    TopLevelVariableDeclaration vDeclaration = unit.declarations[1];
    VariableDeclaration vNode = vDeclaration.variables.variables[0];
    TopLevelVariableElement vElement = vNode.element;
    expect(vElement.type, typeProvider.numType);

    ForEachStatement forEachStatement = statements[0];
    Block forBlock = forEachStatement.body;

    expect(forEachStatement.loopVariable, isNull);

    SimpleIdentifier vInFor = forEachStatement.identifier;
    expect(vInFor.staticElement, same(vElement.setter));
    expect(vInFor.staticType, typeProvider.numType);

    ExpressionStatement statement = forBlock.statements[0];
    SimpleIdentifier identifier = statement.expression;
    expect(identifier.staticElement, same(vElement.getter));
    expect(identifier.staticType, typeProvider.numType);
  }

  test_local_variable_forIn_loopVariable() async {
    addTestFile(r'''
void main() {
  for (var v in <int>[]) {
    v;
  }
}
''');
    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;
    var typeProvider = unit.element.context.typeProvider;

    List<Statement> statements = _getMainStatements(result);

    ForEachStatement forEachStatement = statements[0];
    Block forBlock = forEachStatement.body;

    DeclaredIdentifier vNode = forEachStatement.loopVariable;
    LocalVariableElement vElement = vNode.element;
    expect(vElement.type, typeProvider.intType);

    expect(vNode.identifier.staticElement, vElement);
    expect(vNode.identifier.staticType, typeProvider.intType);

    ExpressionStatement statement = forBlock.statements[0];
    SimpleIdentifier identifier = statement.expression;
    expect(identifier.staticElement, vElement);
    expect(identifier.staticType, typeProvider.intType);
  }

  test_local_variable_forIn_loopVariable_explicitType() async {
    addTestFile(r'''
void main() {
  for (num v in <int>[]) {
    v;
  }
}
''');
    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;
    var typeProvider = unit.element.context.typeProvider;

    List<Statement> statements = _getMainStatements(result);

    ForEachStatement forEachStatement = statements[0];
    Block forBlock = forEachStatement.body;

    DeclaredIdentifier vNode = forEachStatement.loopVariable;
    LocalVariableElement vElement = vNode.element;
    expect(vElement.type, typeProvider.numType);

    TypeName vTypeName = vNode.type;
    expect(vTypeName.type, typeProvider.numType);

    SimpleIdentifier vTypeIdentifier = vTypeName.name;
    expect(vTypeIdentifier.staticElement, typeProvider.numType.element);
    expect(vTypeIdentifier.staticType, typeProvider.numType);

    expect(vNode.identifier.staticElement, vElement);
    expect(vNode.identifier.staticType, typeProvider.numType);

    ExpressionStatement statement = forBlock.statements[0];
    SimpleIdentifier identifier = statement.expression;
    expect(identifier.staticElement, vElement);
    expect(identifier.staticType, typeProvider.numType);
  }

  test_local_variable_multiple() async {
    addTestFile(r'''
void main() {
  var a = 1, b = 2.3;
}
''');
    AnalysisResult result = await driver.getResult(testFile);
    var typeProvider = result.unit.element.context.typeProvider;

    List<Statement> statements = _getMainStatements(result);

    VariableDeclarationStatement declarationStatement = statements[0];

    VariableDeclaration aNode = declarationStatement.variables.variables[0];
    LocalVariableElement aElement = aNode.element;
    expect(aElement.type, typeProvider.intType);

    VariableDeclaration bNode = declarationStatement.variables.variables[1];
    LocalVariableElement bElement = bNode.element;
    expect(bElement.type, typeProvider.doubleType);
  }

  test_local_variable_ofLocalFunction() async {
    addTestFile(r'''
void main() {
  void f() {
    int a;
    a;
    void g() {
      double b;
      a;
      b;
    }
  }
}
''');
    AnalysisResult result = await driver.getResult(testFile);

    var typeProvider = result.unit.element.context.typeProvider;

    List<Statement> mainStatements = _getMainStatements(result);

    // f() {}
    FunctionDeclarationStatement fStatement = mainStatements[0];
    FunctionDeclaration fNode = fStatement.functionDeclaration;
    BlockFunctionBody fBody = fNode.functionExpression.body;
    List<Statement> fStatements = fBody.block.statements;

    // int a;
    VariableDeclarationStatement aDeclaration = fStatements[0];
    VariableElement aElement = aDeclaration.variables.variables[0].element;

    // a;
    {
      ExpressionStatement aStatement = fStatements[1];
      SimpleIdentifier aNode = aStatement.expression;
      expect(aNode.staticElement, same(aElement));
      expect(aNode.staticType, typeProvider.intType);
    }

    // g(double b) {}
    FunctionDeclarationStatement gStatement = fStatements[2];
    FunctionDeclaration gNode = gStatement.functionDeclaration;
    BlockFunctionBody gBody = gNode.functionExpression.body;
    List<Statement> gStatements = gBody.block.statements;

    // double b;
    VariableDeclarationStatement bDeclaration = gStatements[0];
    VariableElement bElement = bDeclaration.variables.variables[0].element;

    // a;
    {
      ExpressionStatement aStatement = gStatements[1];
      SimpleIdentifier aNode = aStatement.expression;
      expect(aNode.staticElement, same(aElement));
      expect(aNode.staticType, typeProvider.intType);
    }

    // b;
    {
      ExpressionStatement bStatement = gStatements[2];
      SimpleIdentifier bNode = bStatement.expression;
      expect(bNode.staticElement, same(bElement));
      expect(bNode.staticType, typeProvider.doubleType);
    }
  }

  test_mapLiteral() async {
    addTestFile(r'''
void main() {
  <int, double>{};
  const <bool, String>{};
}
''');
    AnalysisResult result = await driver.getResult(testFile);
    var typeProvider = result.unit.element.context.typeProvider;

    var statements = _getMainStatements(result);

    {
      ExpressionStatement statement = statements[0];
      MapLiteral mapLiteral = statement.expression;
      expect(
          mapLiteral.staticType,
          typeProvider.mapType
              .instantiate([typeProvider.intType, typeProvider.doubleType]));
    }

    {
      ExpressionStatement statement = statements[1];
      MapLiteral mapLiteral = statement.expression;
      expect(
          mapLiteral.staticType,
          typeProvider.mapType
              .instantiate([typeProvider.boolType, typeProvider.stringType]));
    }
  }

  test_method_namedParameters() async {
    addTestFile(r'''
class C {
  double f(int a, {String b, bool c: false}) {}
}
void g(C c) {
  c.f(1, b: '2', c: true);
}
''');
    String fTypeString = '(int, {b: String, c: bool}) → double';

    AnalysisResult result = await driver.getResult(testFile);
    ClassDeclaration classDeclaration = result.unit.declarations[0];
    MethodDeclaration methodDeclaration = classDeclaration.members[0];
    MethodElement methodElement = methodDeclaration.element;

    var typeProvider = result.unit.element.context.typeProvider;
    InterfaceType doubleType = typeProvider.doubleType;

    expect(methodElement, isNotNull);
    expect(methodElement.type.toString(), fTypeString);

    expect(methodDeclaration.name.staticElement, same(methodElement));
    expect(methodDeclaration.name.staticType, methodElement.type);

    TypeName fReturnTypeNode = methodDeclaration.returnType;
    expect(fReturnTypeNode.name.staticElement, same(doubleType.element));
    expect(fReturnTypeNode.type, doubleType);
    //
    // Validate the parameters at the declaration site.
    //
    List<ParameterElement> elements = methodElement.parameters;
    expect(elements, hasLength(3));

    List<FormalParameter> nodes = methodDeclaration.parameters.parameters;
    expect(nodes, hasLength(3));

    _assertSimpleParameter(nodes[0], elements[0],
        name: 'a',
        offset: 25,
        kind: ParameterKind.REQUIRED,
        type: typeProvider.intType);

    _assertDefaultParameter(nodes[1], elements[1],
        name: 'b',
        offset: 36,
        kind: ParameterKind.NAMED,
        type: typeProvider.stringType);

    _assertDefaultParameter(nodes[2], elements[2],
        name: 'c',
        offset: 44,
        kind: ParameterKind.NAMED,
        type: typeProvider.boolType);
    //
    // Validate the arguments at the call site.
    //
    FunctionDeclaration functionDeclaration = result.unit.declarations[1];
    BlockFunctionBody body = functionDeclaration.functionExpression.body;
    ExpressionStatement statement = body.block.statements[0];
    MethodInvocation invocation = statement.expression;

    List<Expression> arguments = invocation.argumentList.arguments;
    _assertArgumentToParameter(arguments[0], methodElement.parameters[0]);
    _assertArgumentToParameter(arguments[1], methodElement.parameters[1]);
    _assertArgumentToParameter(arguments[2], methodElement.parameters[2]);
  }

  test_methodInvocation_instanceMethod_forwardingStub() async {
    addTestFile(r'''
class A {
  void foo(int x) {}
}
abstract class I<T> {
  void foo(T x);
}
class B extends A implements I<int> {}
main(B b) {
  b.foo(1);
}
''');
    AnalysisResult result = await driver.getResult(testFile);

    ClassDeclaration aNode = result.unit.declarations[0];
    MethodDeclaration fooNode = aNode.members[0];
    MethodElement fooElement = fooNode.element;

    List<Statement> mainStatements = _getMainStatements(result);
    ExpressionStatement statement = mainStatements[0];
    MethodInvocation invocation = statement.expression;
    expect(invocation.methodName.staticElement, same(fooElement));

    var invokeTypeStr = '(int) → void';
    expect(invocation.staticType.toString(), 'void');
    expect(invocation.staticInvokeType.toString(), invokeTypeStr);
  }

  test_methodInvocation_instanceMethod_genericClass() async {
    addTestFile(r'''
main() {
  new C<int, double>().m(1);
}
class C<T, U> {
  void m(T p) {}
}
''');
    AnalysisResult result = await driver.getResult(testFile);
    List<Statement> mainStatements = _getMainStatements(result);

    ClassDeclaration cNode = result.unit.declarations[1];
    MethodDeclaration mNode = cNode.members[0];
    MethodElement mElement = mNode.element;

    {
      ExpressionStatement statement = mainStatements[0];
      MethodInvocation invocation = statement.expression;
      List<Expression> arguments = invocation.argumentList.arguments;

      var invokeTypeStr = '(int) → void';
      expect(invocation.staticType.toString(), 'void');
      expect(invocation.staticInvokeType.toString(), invokeTypeStr);
      if (previewDart2) {
        expect(invocation.methodName.staticElement, same(mElement));
        expect(invocation.methodName.staticType.toString(), invokeTypeStr);
      } else {
        expect(invocation.staticInvokeType.element, same(mElement));
      }

      _assertArgumentToParameter(arguments[0], mElement.parameters[0]);
    }
  }

  test_methodInvocation_instanceMethod_genericClass_genericMethod() async {
    addTestFile(r'''
main() {
  new C<int>().m(1, 2.3);
}
class C<T> {
  Map<T, U> m<U>(T a, U b) => null;
}
''');
    AnalysisResult result = await driver.getResult(testFile);
    var typeProvider = result.unit.element.context.typeProvider;
    List<Statement> mainStatements = _getMainStatements(result);

    ClassDeclaration cNode = result.unit.declarations[1];
    MethodDeclaration mNode = cNode.members[0];
    MethodElement mElement = mNode.element;

    {
      ExpressionStatement statement = mainStatements[0];
      MethodInvocation invocation = statement.expression;
      List<Expression> arguments = invocation.argumentList.arguments;

      var invokeTypeStr = '(int, double) → Map<int, double>';
      expect(invocation.staticType.toString(), 'Map<int, double>');
      expect(invocation.staticInvokeType.toString(), invokeTypeStr);
      if (previewDart2) {
        expect(invocation.methodName.staticElement, same(mElement));
        expect(invocation.methodName.staticType.toString(), invokeTypeStr);
      }

      if (previewDart2) {
        expect(arguments[0].staticParameterElement, isNull);
        expect(arguments[1].staticParameterElement, isNull);
      } else {
        Expression aArgument = arguments[0];
        ParameterMember aArgumentParameter = aArgument.staticParameterElement;
        ParameterElement aElement = mElement.parameters[0];
        expect(aArgumentParameter.type, typeProvider.intType);
        expect(aArgumentParameter.baseElement, same(aElement));

        Expression bArgument = arguments[1];
        ParameterMember bArgumentParameter = bArgument.staticParameterElement;
        expect(bArgumentParameter.type, typeProvider.doubleType);
      }
    }
  }

  test_methodInvocation_namedArgument() async {
    addTestFile(r'''
void main() {
  foo(1, b: true, c: 3.0);
}
void foo(int a, {bool b, double c}) {}
''');
    AnalysisResult result = await driver.getResult(testFile);
    List<Statement> mainStatements = _getMainStatements(result);

    FunctionDeclaration foo = result.unit.declarations[1];
    ExecutableElement fooElement = foo.element;

    ExpressionStatement statement = mainStatements[0];
    MethodInvocation invocation = statement.expression;
    List<Expression> arguments = invocation.argumentList.arguments;

    _assertArgumentToParameter(arguments[0], fooElement.parameters[0]);
    _assertArgumentToParameter(arguments[1], fooElement.parameters[1]);
    _assertArgumentToParameter(arguments[2], fooElement.parameters[2]);
  }

  test_methodInvocation_notFunction_field_dynamic() async {
    addTestFile(r'''
class C {
  dynamic f;
  foo() {
    f(1);
  }
}
''');
    AnalysisResult result = await driver.getResult(testFile);

    ClassDeclaration cDeclaration = result.unit.declarations[0];

    FieldDeclaration fDeclaration = cDeclaration.members[0];
    VariableDeclaration fNode = fDeclaration.fields.variables[0];
    FieldElement fElement = fNode.element;

    MethodDeclaration fooDeclaration = cDeclaration.members[1];
    BlockFunctionBody fooBody = fooDeclaration.body;
    List<Statement> fooStatements = fooBody.block.statements;

    ExpressionStatement statement = fooStatements[0];
    MethodInvocation invocation = statement.expression;
    expect(invocation.methodName.staticElement, same(fElement.getter));
    if (previewDart2) {
      _assertDynamicFunctionType(invocation.staticInvokeType);
    } else {
      expect(invocation.staticInvokeType, DynamicTypeImpl.instance);
    }
    expect(invocation.staticType, DynamicTypeImpl.instance);

    List<Expression> arguments = invocation.argumentList.arguments;
    expect(arguments[0].staticParameterElement, isNull);
  }

  test_methodInvocation_notFunction_getter_dynamic() async {
    addTestFile(r'''
class C {
  get f => null;
  foo() {
    f(1);
  }
}
''');
    AnalysisResult result = await driver.getResult(testFile);

    ClassDeclaration cDeclaration = result.unit.declarations[0];

    MethodDeclaration fDeclaration = cDeclaration.members[0];
    PropertyAccessorElement fElement = fDeclaration.element;

    MethodDeclaration fooDeclaration = cDeclaration.members[1];
    BlockFunctionBody fooBody = fooDeclaration.body;
    List<Statement> fooStatements = fooBody.block.statements;

    ExpressionStatement statement = fooStatements[0];
    MethodInvocation invocation = statement.expression;
    expect(invocation.methodName.staticElement, same(fElement));
    if (previewDart2) {
      _assertDynamicFunctionType(invocation.staticInvokeType);
    } else {
      expect(invocation.staticInvokeType, DynamicTypeImpl.instance);
    }
    expect(invocation.staticType, DynamicTypeImpl.instance);

    List<Expression> arguments = invocation.argumentList.arguments;

    Expression argument = arguments[0];
    expect(argument.staticParameterElement, isNull);
  }

  test_methodInvocation_notFunction_local_dynamic() async {
    addTestFile(r'''
main(f) {
  f(1);
}
''');
    AnalysisResult result = await driver.getResult(testFile);

    FunctionDeclaration mainDeclaration = result.unit.declarations[0];
    FunctionExpression mainFunction = mainDeclaration.functionExpression;
    ParameterElement fElement = mainFunction.parameters.parameters[0].element;

    BlockFunctionBody mainBody = mainFunction.body;
    List<Statement> mainStatements = mainBody.block.statements;

    ExpressionStatement statement = mainStatements[0];
    MethodInvocation invocation = statement.expression;
    expect(invocation.methodName.staticElement, same(fElement));
    _assertDynamicFunctionType(invocation.staticInvokeType);
    expect(invocation.staticType, DynamicTypeImpl.instance);

    List<Expression> arguments = invocation.argumentList.arguments;

    Expression argument = arguments[0];
    expect(argument.staticParameterElement, isNull);
  }

  test_methodInvocation_notFunction_local_functionTyped() async {
    addTestFile(r'''
main(String f(int a)) {
  f(1);
}
''');
    AnalysisResult result = await driver.getResult(testFile);
    var typeProvider = result.unit.element.context.typeProvider;

    FunctionDeclaration mainDeclaration = result.unit.declarations[0];
    FunctionExpression mainFunction = mainDeclaration.functionExpression;
    ParameterElement fElement = mainFunction.parameters.parameters[0].element;

    BlockFunctionBody mainBody = mainFunction.body;
    List<Statement> mainStatements = mainBody.block.statements;

    ExpressionStatement statement = mainStatements[0];
    MethodInvocation invocation = statement.expression;
    expect(invocation.methodName.staticElement, same(fElement));
    expect(invocation.staticInvokeType.toString(), '(int) → String');
    expect(invocation.staticType, typeProvider.stringType);

    List<Expression> arguments = invocation.argumentList.arguments;
    _assertArgumentToParameter(
        arguments[0], (fElement.type as FunctionType).parameters[0]);
  }

  test_methodInvocation_notFunction_topLevelVariable_dynamic() async {
    addTestFile(r'''
dynamic f;
main() {
  f(1);
}
''');
    AnalysisResult result = await driver.getResult(testFile);

    TopLevelVariableDeclaration fDeclaration = result.unit.declarations[0];
    VariableDeclaration fNode = fDeclaration.variables.variables[0];
    TopLevelVariableElement fElement = fNode.element;

    List<Statement> mainStatements = _getMainStatements(result);

    ExpressionStatement statement = mainStatements[0];
    MethodInvocation invocation = statement.expression;
    expect(invocation.methodName.staticElement, same(fElement.getter));
    _assertDynamicFunctionType(invocation.staticInvokeType);
    expect(invocation.staticType, DynamicTypeImpl.instance);

    List<Expression> arguments = invocation.argumentList.arguments;

    Expression argument = arguments[0];
    expect(argument.staticParameterElement, isNull);
  }

  test_methodInvocation_staticMethod() async {
    addTestFile(r'''
main() {
  C.m(1);
}
class C {
  static void m(int p) {}
  void foo() {
    m(2);
  }
}
''');
    AnalysisResult result = await driver.getResult(testFile);
    List<Statement> mainStatements = _getMainStatements(result);

    ClassDeclaration cNode = result.unit.declarations[1];
    ClassElement cElement = cNode.element;
    MethodDeclaration mNode = cNode.members[0];
    MethodElement mElement = mNode.element;

    {
      ExpressionStatement statement = mainStatements[0];
      MethodInvocation invocation = statement.expression;
      List<Expression> arguments = invocation.argumentList.arguments;

      SimpleIdentifier target = invocation.target;
      expect(target.staticElement, same(cElement));
      expect(target.staticType, same(cElement.type));

      var invokeTypeStr = '(int) → void';
      expect(invocation.staticType.toString(), 'void');
      expect(invocation.staticInvokeType.toString(), invokeTypeStr);
      if (!previewDart2) {
        expect(invocation.staticInvokeType.element, same(mElement));
      }
      expect(invocation.methodName.staticElement, same(mElement));
      expect(invocation.methodName.staticType.toString(), invokeTypeStr);

      Expression argument = arguments[0];
      _assertArgumentToParameter(argument, mElement.parameters[0]);
    }

    {
      MethodDeclaration fooNode = cNode.members[1];
      BlockFunctionBody fooBody = fooNode.body;
      List<Statement> statements = fooBody.block.statements;

      ExpressionStatement statement = statements[0];
      MethodInvocation invocation = statement.expression;
      List<Expression> arguments = invocation.argumentList.arguments;

      expect(invocation.target, isNull);

      var invokeTypeStr = '(int) → void';
      expect(invocation.staticType.toString(), 'void');
      expect(invocation.staticInvokeType.toString(), invokeTypeStr);
      if (!previewDart2) {
        expect(invocation.staticInvokeType.element, same(mElement));
      }
      expect(invocation.methodName.staticElement, same(mElement));
      expect(invocation.methodName.staticType.toString(), invokeTypeStr);

      Expression argument = arguments[0];
      _assertArgumentToParameter(argument, mElement.parameters[0]);
    }
  }

  test_methodInvocation_staticMethod_contextTypeParameter() async {
    addTestFile(r'''
class C<T> {
  static E foo<E>(C<E> c) => null;
  void bar() {
    foo(this);
  }
}
''');
    AnalysisResult result = await driver.getResult(testFile);

    ClassDeclaration cNode = result.unit.declarations[0];
    TypeParameterElement tElement = cNode.element.typeParameters[0];

    MethodDeclaration barNode = cNode.members[1];
    BlockFunctionBody barBody = barNode.body;
    ExpressionStatement fooStatement = barBody.block.statements[0];
    MethodInvocation fooInvocation = fooStatement.expression;
    expect(fooInvocation.staticInvokeType.toString(), '(C<T>) → T');
    expect(fooInvocation.staticType.toString(), 'T');
    expect(fooInvocation.staticType.element, same(tElement));
  }

  test_methodInvocation_topLevelFunction() async {
    addTestFile(r'''
void main() {
  f(1, '2');
}
double f(int a, String b) {}
''');
    String fTypeString = '(int, String) → double';

    AnalysisResult result = await driver.getResult(testFile);
    List<Statement> mainStatements = _getMainStatements(result);

    var typeProvider = result.unit.element.context.typeProvider;
    InterfaceType doubleType = typeProvider.doubleType;

    FunctionDeclaration fNode = result.unit.declarations[1];
    FunctionElement fElement = fNode.element;

    ExpressionStatement statement = mainStatements[0];
    MethodInvocation invocation = statement.expression;
    List<Expression> arguments = invocation.argumentList.arguments;

    expect(invocation.methodName.staticElement, same(fElement));
    expect(invocation.methodName.staticType.toString(), fTypeString);
    expect(invocation.staticType, same(doubleType));
    expect(invocation.staticInvokeType.toString(), fTypeString);

    _assertArgumentToParameter(arguments[0], fElement.parameters[0]);
    _assertArgumentToParameter(arguments[1], fElement.parameters[1]);
  }

  test_methodInvocation_topLevelFunction_generic() async {
    addTestFile(r'''
void main() {
  f<bool, String>(true, 'str');
  f(1, 2.3);
}
void f<T, U>(T a, U b) {}
''');
    AnalysisResult result = await driver.getResult(testFile);
    var typeProvider = result.unit.element.context.typeProvider;
    List<Statement> mainStatements = _getMainStatements(result);

    FunctionDeclaration fNode = result.unit.declarations[1];
    FunctionElement fElement = fNode.element;

    // f<bool, String>(true, 'str');
    {
      String fTypeString = '(bool, String) → void';
      ExpressionStatement statement = mainStatements[0];
      MethodInvocation invocation = statement.expression;

      List<TypeAnnotation> typeArguments = invocation.typeArguments.arguments;
      expect(typeArguments, hasLength(2));
      {
        TypeName typeArgument = typeArguments[0];
        InterfaceType boolType = typeProvider.boolType;
        expect(typeArgument.type, boolType);
        expect(typeArgument.name.staticElement, boolType.element);
        expect(typeArgument.name.staticType, boolType);
      }
      {
        TypeName typeArgument = typeArguments[1];
        InterfaceType stringType = typeProvider.stringType;
        expect(typeArgument.type, stringType);
        expect(typeArgument.name.staticElement, stringType.element);
        expect(typeArgument.name.staticType, stringType);
      }

      List<Expression> arguments = invocation.argumentList.arguments;

      expect(invocation.methodName.staticElement, same(fElement));
      if (previewDart2) {
        expect(invocation.methodName.staticType.toString(), fTypeString);
      }
      expect(invocation.staticType, VoidTypeImpl.instance);
      expect(invocation.staticInvokeType.toString(), fTypeString);

      _assertArgumentToParameter(arguments[0], fElement.parameters[0],
          parameterMemberType: typeProvider.boolType);
      _assertArgumentToParameter(arguments[1], fElement.parameters[1],
          parameterMemberType: typeProvider.stringType);
    }

    // f(1, 2.3);
    {
      String fTypeString = '(int, double) → void';
      ExpressionStatement statement = mainStatements[1];
      MethodInvocation invocation = statement.expression;
      List<Expression> arguments = invocation.argumentList.arguments;

      expect(invocation.methodName.staticElement, same(fElement));
      if (previewDart2) {
        expect(invocation.methodName.staticType.toString(), fTypeString);
      }
      expect(invocation.staticType, VoidTypeImpl.instance);
      expect(invocation.staticInvokeType.toString(), fTypeString);

      _assertArgumentToParameter(arguments[0], fElement.parameters[0],
          parameterMemberType: typeProvider.intType);
      _assertArgumentToParameter(arguments[1], fElement.parameters[1],
          parameterMemberType: typeProvider.doubleType);
    }
  }

  test_postfixExpression_local() async {
    String content = r'''
main() {
  int v = 0;
  v++;
}
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;
    var typeProvider = unit.element.context.typeProvider;

    List<Statement> mainStatements = _getMainStatements(result);

    VariableElement v;
    {
      VariableDeclarationStatement statement = mainStatements[0];
      v = statement.variables.variables[0].element;
      expect(v.type, typeProvider.intType);
    }

    {
      ExpressionStatement statement = mainStatements[1];

      PostfixExpression postfix = statement.expression;
      expect(postfix.operator.type, TokenType.PLUS_PLUS);
      expect(postfix.staticElement.name, '+');
      expect(postfix.staticType, typeProvider.intType);

      SimpleIdentifier operand = postfix.operand;
      expect(operand.staticElement, same(v));
      expect(operand.staticType, typeProvider.intType);
    }
  }

  test_postfixExpression_propertyAccess() async {
    String content = r'''
main() {
  new C().f++;
}
class C {
  int f;
}
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;
    var typeProvider = unit.element.context.typeProvider;

    ClassDeclaration cClassDeclaration = unit.declarations[1];
    ClassElement cClassElement = cClassDeclaration.element;
    FieldElement fElement = cClassElement.getField('f');

    List<Statement> mainStatements = _getMainStatements(result);

    {
      ExpressionStatement statement = mainStatements[0];

      PostfixExpression postfix = statement.expression;
      expect(postfix.operator.type, TokenType.PLUS_PLUS);
      expect(postfix.staticElement.name, '+');
      expect(postfix.staticType, typeProvider.intType);

      PropertyAccess propertyAccess = postfix.operand;
      expect(propertyAccess.staticType, typeProvider.intType);

      SimpleIdentifier propertyName = propertyAccess.propertyName;
      expect(propertyName.staticElement, same(fElement.setter));
      expect(propertyName.staticType, typeProvider.intType);
    }
  }

  test_prefixedIdentifier_classInstance_instanceField() async {
    String content = r'''
main() {
  var c = new C();
  c.f;
}
class C {
  int f;
}
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    var typeProvider = result.unit.element.context.typeProvider;

    List<Statement> statements = _getMainStatements(result);

    ClassDeclaration cDeclaration = result.unit.declarations[1];
    ClassElement cElement = cDeclaration.element;
    FieldElement fElement = cElement.fields[0];

    VariableDeclarationStatement cStatement = statements[0];
    VariableElement vElement = cStatement.variables.variables[0].element;

    ExpressionStatement statement = statements[1];
    PrefixedIdentifier prefixed = statement.expression;

    SimpleIdentifier prefix = prefixed.prefix;
    expect(prefix.staticElement, same(vElement));
    expect(prefix.staticType, cElement.type);

    SimpleIdentifier identifier = prefixed.identifier;
    expect(identifier.staticElement, same(fElement.getter));
    expect(identifier.staticType, typeProvider.intType);
  }

  test_prefixedIdentifier_className_staticField() async {
    String content = r'''
main() {
  C.f;
}
class C {
  static f = 0;
}
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    var typeProvider = result.unit.element.context.typeProvider;

    List<Statement> statements = _getMainStatements(result);

    ClassDeclaration cDeclaration = result.unit.declarations[1];
    ClassElement cElement = cDeclaration.element;
    FieldElement fElement = cElement.fields[0];

    ExpressionStatement statement = statements[0];
    PrefixedIdentifier prefixed = statement.expression;

    SimpleIdentifier prefix = prefixed.prefix;
    expect(prefix.staticElement, same(cElement));
    expect(prefix.staticType, cElement.type);

    SimpleIdentifier identifier = prefixed.identifier;
    expect(identifier.staticElement, same(fElement.getter));
    expect(identifier.staticType, typeProvider.intType);
  }

  test_prefixedIdentifier_importPrefix_className() async {
    var libPath = _p('/test/lib/lib.dart');
    provider.newFile(libPath, '''
class MyClass {}
typedef void MyFunctionTypeAlias();
int myTopVariable;
int myTopFunction() => 0;
int get myGetter => 0;
void set mySetter(int _) {}
''');
    addTestFile(r'''
import 'lib.dart' as my;
main() {
  my.MyClass;
  my.MyFunctionTypeAlias;
  my.myTopVariable;
  my.myTopFunction;
  my.myTopFunction();
  my.myGetter;
  my.mySetter = 0;
}
''');
    AnalysisResult result = await driver.getResult(testFile);
    // TODO(scheglov) Uncomment and fix "unused imports" hint.
//    expect(result.errors, isEmpty);

    var unitElement = result.unit.element;
    ImportElement myImport = unitElement.library.imports[0];
    PrefixElement myPrefix = myImport.prefix;
    var typeProvider = unitElement.context.typeProvider;

    var myLibrary = myImport.importedLibrary;
    var myUnit = myLibrary.definingCompilationUnit;
    var myClass = myUnit.types.single;
    var myFunctionTypeAlias = myUnit.functionTypeAliases.single;
    var myTopVariable = myUnit.topLevelVariables[0];
    var myTopFunction = myUnit.functions.single;
    var myGetter = myUnit.topLevelVariables[1].getter;
    var mySetter = myUnit.topLevelVariables[2].setter;
    expect(myTopVariable.name, 'myTopVariable');
    expect(myGetter.displayName, 'myGetter');
    expect(mySetter.displayName, 'mySetter');

    List<Statement> statements = _getMainStatements(result);

    void assertPrefix(SimpleIdentifier identifier) {
      expect(identifier.staticElement, same(myPrefix));
      expect(identifier.staticType, isNull);
    }

    void assertPrefixedIdentifier(
        int statementIndex, Element expectedElement, DartType expectedType) {
      ExpressionStatement statement = statements[statementIndex];
      PrefixedIdentifier prefixed = statement.expression;
      assertPrefix(prefixed.prefix);

      expect(prefixed.identifier.staticElement, same(expectedElement));
      expect(prefixed.identifier.staticType, expectedType);
    }

    assertPrefixedIdentifier(0, myClass, typeProvider.typeType);
    assertPrefixedIdentifier(1, myFunctionTypeAlias, typeProvider.typeType);
    assertPrefixedIdentifier(2, myTopVariable.getter, typeProvider.intType);

    {
      ExpressionStatement statement = statements[3];
      PrefixedIdentifier prefixed = statement.expression;
      assertPrefix(prefixed.prefix);

      expect(prefixed.identifier.staticElement, same(myTopFunction));
      expect(prefixed.identifier.staticType, isNotNull);
    }

    {
      ExpressionStatement statement = statements[4];
      MethodInvocation invocation = statement.expression;
      assertPrefix(invocation.target);

      expect(invocation.methodName.staticElement, same(myTopFunction));
      expect(invocation.methodName.staticType, isNotNull);
    }

    assertPrefixedIdentifier(5, myGetter, typeProvider.intType);

    {
      ExpressionStatement statement = statements[6];
      AssignmentExpression assignment = statement.expression;
      PrefixedIdentifier left = assignment.leftHandSide;
      assertPrefix(left.prefix);

      expect(left.identifier.staticElement, same(mySetter));
      expect(left.identifier.staticType, typeProvider.intType);
    }
  }

  test_prefixExpression_local() async {
    String content = r'''
main() {
  int v = 0;
  ++v;
  ~v;
}
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;
    var typeProvider = unit.element.context.typeProvider;

    List<Statement> mainStatements = _getMainStatements(result);

    VariableElement v;
    {
      VariableDeclarationStatement statement = mainStatements[0];
      v = statement.variables.variables[0].element;
      expect(v.type, typeProvider.intType);
    }

    {
      ExpressionStatement statement = mainStatements[1];

      PrefixExpression prefix = statement.expression;
      expect(prefix.operator.type, TokenType.PLUS_PLUS);
      expect(prefix.staticElement.name, '+');
      expect(prefix.staticType, typeProvider.intType);

      SimpleIdentifier operand = prefix.operand;
      expect(operand.staticElement, same(v));
      expect(operand.staticType, typeProvider.intType);
    }

    {
      ExpressionStatement statement = mainStatements[2];

      PrefixExpression prefix = statement.expression;
      expect(prefix.operator.type, TokenType.TILDE);
      expect(prefix.staticElement.name, '~');
      expect(prefix.staticType, typeProvider.intType);

      SimpleIdentifier operand = prefix.operand;
      expect(operand.staticElement, same(v));
      expect(operand.staticType, typeProvider.intType);
    }
  }

  test_prefixExpression_local_not() async {
    String content = r'''
main() {
  bool v = true;
  !v;
}
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;
    var typeProvider = unit.element.context.typeProvider;

    List<Statement> mainStatements = _getMainStatements(result);

    VariableElement v;
    {
      VariableDeclarationStatement statement = mainStatements[0];
      v = statement.variables.variables[0].element;
      expect(v.type, typeProvider.boolType);
    }

    {
      ExpressionStatement statement = mainStatements[1];

      PrefixExpression prefix = statement.expression;
      expect(prefix.operator.type, TokenType.BANG);
      expect(prefix.staticElement, isNull);
      expect(prefix.staticType, typeProvider.boolType);

      SimpleIdentifier operand = prefix.operand;
      expect(operand.staticElement, same(v));
      expect(operand.staticType, typeProvider.boolType);
    }
  }

  test_prefixExpression_propertyAccess() async {
    String content = r'''
main() {
  ++new C().f;
  ~new C().f;
}
class C {
  int f;
}
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;
    var typeProvider = unit.element.context.typeProvider;

    ClassDeclaration cClassDeclaration = unit.declarations[1];
    ClassElement cClassElement = cClassDeclaration.element;
    FieldElement fElement = cClassElement.getField('f');

    List<Statement> mainStatements = _getMainStatements(result);

    {
      ExpressionStatement statement = mainStatements[0];

      PrefixExpression prefix = statement.expression;
      expect(prefix.operator.type, TokenType.PLUS_PLUS);
      expect(prefix.staticElement.name, '+');
      expect(prefix.staticType, typeProvider.intType);

      PropertyAccess propertyAccess = prefix.operand;
      expect(propertyAccess.staticType, typeProvider.intType);

      SimpleIdentifier propertyName = propertyAccess.propertyName;
      expect(propertyName.staticElement, same(fElement.setter));
      expect(propertyName.staticType, typeProvider.intType);
    }

    {
      ExpressionStatement statement = mainStatements[1];

      PrefixExpression prefix = statement.expression;
      expect(prefix.operator.type, TokenType.TILDE);
      expect(prefix.staticElement.name, '~');
      expect(prefix.staticType, typeProvider.intType);

      PropertyAccess propertyAccess = prefix.operand;
      expect(propertyAccess.staticType, typeProvider.intType);

      SimpleIdentifier propertyName = propertyAccess.propertyName;
      expect(propertyName.staticElement, same(fElement.getter));
      expect(propertyName.staticType, typeProvider.intType);
    }
  }

  test_propertyAccess_field() async {
    String content = r'''
main() {
  new C().f;
}
class C {
  int f;
}
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;
    var typeProvider = unit.element.context.typeProvider;

    ClassDeclaration cClassDeclaration = unit.declarations[1];
    ClassElement cClassElement = cClassDeclaration.element;
    FieldElement fElement = cClassElement.getField('f');

    List<Statement> mainStatements = _getMainStatements(result);

    {
      ExpressionStatement statement = mainStatements[0];
      PropertyAccess access = statement.expression;
      expect(access.staticType, typeProvider.intType);

      InstanceCreationExpression newC = access.target;
      expect(newC.staticElement, cClassElement.unnamedConstructor);
      expect(newC.staticType, cClassElement.type);

      expect(access.propertyName.staticElement, same(fElement.getter));
      expect(access.propertyName.staticType, typeProvider.intType);
    }
  }

  test_propertyAccess_getter() async {
    String content = r'''
main() {
  new C().f;
}
class C {
  int get f => 0;
}
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;
    var typeProvider = unit.element.context.typeProvider;

    ClassDeclaration cClassDeclaration = unit.declarations[1];
    ClassElement cClassElement = cClassDeclaration.element;
    FieldElement fElement = cClassElement.getField('f');

    List<Statement> mainStatements = _getMainStatements(result);

    {
      ExpressionStatement statement = mainStatements[0];
      PropertyAccess access = statement.expression;
      expect(access.staticType, typeProvider.intType);

      InstanceCreationExpression newC = access.target;
      expect(newC.staticElement, cClassElement.unnamedConstructor);
      expect(newC.staticType, cClassElement.type);

      expect(access.propertyName.staticElement, same(fElement.getter));
      expect(access.propertyName.staticType, typeProvider.intType);
    }
  }

  test_stringInterpolation() async {
    String content = r'''
void main() {
  var v = 42;
  '$v$v $v';
  ' ${v + 1} ';
}
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    expect(result.path, testFile);
    expect(result.errors, isEmpty);

    var typeProvider = result.unit.element.context.typeProvider;

    FunctionDeclaration main = result.unit.declarations[0];
    expect(main.element, isNotNull);
    expect(main.name.staticElement, isNotNull);
    expect(main.name.staticType.toString(), '() → void');

    BlockFunctionBody body = main.functionExpression.body;
    NodeList<Statement> statements = body.block.statements;

    // var v = 42;
    VariableElement vElement;
    {
      VariableDeclarationStatement statement = statements[0];
      vElement = statement.variables.variables[0].name.staticElement;
    }

    {
      ExpressionStatement statement = statements[1];
      StringInterpolation interpolation = statement.expression;

      InterpolationExpression element_1 = interpolation.elements[1];
      SimpleIdentifier expression_1 = element_1.expression;
      expect(expression_1.staticElement, same(vElement));
      expect(expression_1.staticType, typeProvider.intType);

      InterpolationExpression element_3 = interpolation.elements[3];
      SimpleIdentifier expression_3 = element_3.expression;
      expect(expression_3.staticElement, same(vElement));
      expect(expression_3.staticType, typeProvider.intType);

      InterpolationExpression element_5 = interpolation.elements[5];
      SimpleIdentifier expression_5 = element_5.expression;
      expect(expression_5.staticElement, same(vElement));
      expect(expression_5.staticType, typeProvider.intType);
    }

    {
      ExpressionStatement statement = statements[2];
      StringInterpolation interpolation = statement.expression;

      InterpolationExpression element_1 = interpolation.elements[1];
      BinaryExpression expression = element_1.expression;
      expect(expression.staticType, typeProvider.intType);

      SimpleIdentifier left = expression.leftOperand;
      expect(left.staticElement, same(vElement));
      expect(left.staticType, typeProvider.intType);
    }
  }

  test_super() async {
    String content = r'''
class A {
  void method(int p) {}
  int get getter => 0;
  void set setter(int p) {}
  int operator+(int p) => 0;
}
class B extends A {
  void test() {
    method(1);
    super.method(2);
    getter;
    super.getter;
    setter = 3;
    super.setter = 4;
    this + 5;
  }
}
''';
    addTestFile(content);
    AnalysisResult result = await driver.getResult(testFile);
    var typeProvider = result.unit.element.context.typeProvider;

    ClassDeclaration aNode = result.unit.declarations[0];
    ClassDeclaration bNode = result.unit.declarations[1];

    MethodElement methodElement = aNode.members[0].element;
    PropertyAccessorElement getterElement = aNode.members[1].element;
    PropertyAccessorElement setterElement = aNode.members[2].element;
    MethodElement operatorElement = aNode.members[3].element;

    MethodDeclaration testNode = bNode.members[0];
    BlockFunctionBody testBody = testNode.body;
    List<Statement> testStatements = testBody.block.statements;

    // method(1);
    {
      ExpressionStatement statement = testStatements[0];
      MethodInvocation invocation = statement.expression;

      expect(invocation.target, isNull);

      expect(invocation.methodName.staticElement, same(methodElement));
    }

    // super.method(2);
    {
      ExpressionStatement statement = testStatements[1];
      MethodInvocation invocation = statement.expression;

      SuperExpression target = invocation.target;
      expect(target.staticType, bNode.element.type); // raw

      expect(invocation.methodName.staticElement, same(methodElement));
    }

    // getter;
    {
      ExpressionStatement statement = testStatements[2];
      SimpleIdentifier identifier = statement.expression;

      expect(identifier.staticElement, same(getterElement));
      expect(identifier.staticType, same(typeProvider.intType));
    }

    // super.getter;
    {
      ExpressionStatement statement = testStatements[3];
      PropertyAccess propertyAccess = statement.expression;
      expect(propertyAccess.staticType, same(typeProvider.intType));

      SuperExpression target = propertyAccess.target;
      expect(target.staticType, bNode.element.type); // raw

      expect(propertyAccess.propertyName.staticElement, same(getterElement));
      expect(
          propertyAccess.propertyName.staticType, same(typeProvider.intType));
    }

    // setter = 3;
    {
      ExpressionStatement statement = testStatements[4];
      AssignmentExpression assignment = statement.expression;

      SimpleIdentifier identifier = assignment.leftHandSide;
      expect(identifier.staticElement, same(setterElement));
      expect(identifier.staticType, same(typeProvider.intType));
    }

    // this.setter = 4;
    {
      ExpressionStatement statement = testStatements[5];
      AssignmentExpression assignment = statement.expression;

      PropertyAccess propertyAccess = assignment.leftHandSide;

      SuperExpression target = propertyAccess.target;
      expect(target.staticType, bNode.element.type); // raw

      expect(propertyAccess.propertyName.staticElement, same(setterElement));
      expect(
          propertyAccess.propertyName.staticType, same(typeProvider.intType));
    }

    // super + 5;
    {
      ExpressionStatement statement = testStatements[6];
      BinaryExpression binary = statement.expression;

      ThisExpression target = binary.leftOperand;
      expect(target.staticType, bNode.element.type); // raw

      expect(binary.staticElement, same(operatorElement));
      expect(binary.staticType, typeProvider.intType);
    }
  }

  test_this() async {
    String content = r'''
class A {
  void method(int p) {}
  int get getter => 0;
  void set setter(int p) {}
  int operator+(int p) => 0;
  void test() {
    method(1);
    this.method(2);
    getter;
    this.getter;
    setter = 3;
    this.setter = 4;
    this + 5;
  }
}
''';
    addTestFile(content);
    AnalysisResult result = await driver.getResult(testFile);
    var typeProvider = result.unit.element.context.typeProvider;

    ClassDeclaration aNode = result.unit.declarations[0];

    MethodElement methodElement = aNode.members[0].element;
    PropertyAccessorElement getterElement = aNode.members[1].element;
    PropertyAccessorElement setterElement = aNode.members[2].element;
    MethodElement operatorElement = aNode.members[3].element;

    MethodDeclaration testNode = aNode.members[4];
    BlockFunctionBody testBody = testNode.body;
    List<Statement> testStatements = testBody.block.statements;

    // method(1);
    {
      ExpressionStatement statement = testStatements[0];
      MethodInvocation invocation = statement.expression;

      expect(invocation.target, isNull);

      expect(invocation.methodName.staticElement, same(methodElement));
    }

    // this.method(2);
    {
      ExpressionStatement statement = testStatements[1];
      MethodInvocation invocation = statement.expression;

      ThisExpression target = invocation.target;
      expect(target.staticType, aNode.element.type); // raw

      expect(invocation.methodName.staticElement, same(methodElement));
    }

    // getter;
    {
      ExpressionStatement statement = testStatements[2];
      SimpleIdentifier identifier = statement.expression;

      expect(identifier.staticElement, same(getterElement));
      expect(identifier.staticType, typeProvider.intType);
    }

    // this.getter;
    {
      ExpressionStatement statement = testStatements[3];
      PropertyAccess propertyAccess = statement.expression;
      expect(propertyAccess.staticType, typeProvider.intType);

      ThisExpression target = propertyAccess.target;
      expect(target.staticType, aNode.element.type); // raw

      expect(propertyAccess.propertyName.staticElement, same(getterElement));
      expect(propertyAccess.propertyName.staticType, typeProvider.intType);
    }

    // setter = 3;
    {
      ExpressionStatement statement = testStatements[4];
      AssignmentExpression assignment = statement.expression;

      SimpleIdentifier identifier = assignment.leftHandSide;
      expect(identifier.staticElement, same(setterElement));
      expect(identifier.staticType, typeProvider.intType);
    }

    // this.setter = 4;
    {
      ExpressionStatement statement = testStatements[5];
      AssignmentExpression assignment = statement.expression;

      PropertyAccess propertyAccess = assignment.leftHandSide;

      ThisExpression target = propertyAccess.target;
      expect(target.staticType, aNode.element.type); // raw

      expect(propertyAccess.propertyName.staticElement, same(setterElement));
      expect(propertyAccess.propertyName.staticType, typeProvider.intType);
    }

    // this + 5;
    {
      ExpressionStatement statement = testStatements[6];
      BinaryExpression binary = statement.expression;

      ThisExpression target = binary.leftOperand;
      expect(target.staticType, aNode.element.type); // raw

      expect(binary.staticElement, same(operatorElement));
      expect(binary.staticType, typeProvider.intType);
    }
  }

  test_top_class() async {
    String content = r'''
class A<T> {}
class B<T> {}
class C<T> {}
class D extends A<bool> with B<int> implements C<double> {}
''';
    addTestFile(content);
    AnalysisResult result = await driver.getResult(testFile);
    var typeProvider = result.unit.element.context.typeProvider;

    ClassDeclaration aNode = result.unit.declarations[0];
    ClassElement aElement = aNode.element;

    ClassDeclaration bNode = result.unit.declarations[1];
    ClassElement bElement = bNode.element;

    ClassDeclaration cNode = result.unit.declarations[2];
    ClassElement cElement = cNode.element;

    ClassDeclaration dNode = result.unit.declarations[3];
    Element dElement = dNode.element;

    SimpleIdentifier dName = dNode.name;
    expect(dName.staticElement, same(dElement));
    expect(dName.staticType, typeProvider.typeType);

    {
      var aRawType = aElement.type;
      var expectedType = aRawType.instantiate([typeProvider.boolType]);

      TypeName superClass = dNode.extendsClause.superclass;
      expect(superClass.type, expectedType);

      SimpleIdentifier identifier = superClass.name;
      expect(identifier.staticElement, aElement);
      expect(identifier.staticType, expectedType);
    }

    {
      var bRawType = bElement.type;
      var expectedType = bRawType.instantiate([typeProvider.intType]);

      TypeName mixinType = dNode.withClause.mixinTypes[0];
      expect(mixinType.type, expectedType);

      SimpleIdentifier identifier = mixinType.name;
      expect(identifier.staticElement, bElement);
      expect(identifier.staticType, expectedType);
    }

    {
      var cRawType = cElement.type;
      var expectedType = cRawType.instantiate([typeProvider.doubleType]);

      TypeName implementedType = dNode.implementsClause.interfaces[0];
      expect(implementedType.type, expectedType);

      SimpleIdentifier identifier = implementedType.name;
      expect(identifier.staticElement, cElement);
      expect(identifier.staticType, expectedType);
    }
  }

  test_top_class_constructor_parameter_defaultValue() async {
    String content = r'''
class C {
  double f;
  C([int a: 1 + 2]) : f = 3.4;
}
''';
    addTestFile(content);
    AnalysisResult result = await driver.getResult(testFile);
    var typeProvider = result.unit.element.context.typeProvider;

    ClassDeclaration cNode = result.unit.declarations[0];
    ClassElement cElement = cNode.element;

    ConstructorDeclaration constructorNode = cNode.members[1];

    DefaultFormalParameter aNode = constructorNode.parameters.parameters[0];
    _assertDefaultParameter(aNode, cElement.unnamedConstructor.parameters[0],
        name: 'a',
        offset: 31,
        kind: ParameterKind.POSITIONAL,
        type: typeProvider.intType);

    BinaryExpression binary = aNode.defaultValue;
    expect(binary.staticElement, isNotNull);
    expect(binary.staticType, typeProvider.intType);
    expect(binary.leftOperand.staticType, typeProvider.intType);
    expect(binary.rightOperand.staticType, typeProvider.intType);
  }

  test_top_classTypeAlias() async {
    String content = r'''
class A<T> {}
class B<T> {}
class C<T> {}
class D = A<bool> with B<int> implements C<double>;
''';
    addTestFile(content);
    AnalysisResult result = await driver.getResult(testFile);
    var typeProvider = result.unit.element.context.typeProvider;

    ClassDeclaration aNode = result.unit.declarations[0];
    ClassElement aElement = aNode.element;

    ClassDeclaration bNode = result.unit.declarations[1];
    ClassElement bElement = bNode.element;

    ClassDeclaration cNode = result.unit.declarations[2];
    ClassElement cElement = cNode.element;

    ClassTypeAlias dNode = result.unit.declarations[3];
    Element dElement = dNode.element;

    SimpleIdentifier dName = dNode.name;
    expect(dName.staticElement, same(dElement));
    expect(dName.staticType, typeProvider.typeType);

    {
      var aRawType = aElement.type;
      var expectedType = aRawType.instantiate([typeProvider.boolType]);

      TypeName superClass = dNode.superclass;
      expect(superClass.type, expectedType);

      SimpleIdentifier identifier = superClass.name;
      expect(identifier.staticElement, same(aElement));
      expect(identifier.staticType, expectedType);
    }

    {
      var bRawType = bElement.type;
      var expectedType = bRawType.instantiate([typeProvider.intType]);

      TypeName mixinType = dNode.withClause.mixinTypes[0];
      expect(mixinType.type, expectedType);

      SimpleIdentifier identifier = mixinType.name;
      expect(identifier.staticElement, same(bElement));
      expect(identifier.staticType, expectedType);
    }

    {
      var cRawType = cElement.type;
      var expectedType = cRawType.instantiate([typeProvider.doubleType]);

      TypeName interfaceType = dNode.implementsClause.interfaces[0];
      expect(interfaceType.type, expectedType);

      SimpleIdentifier identifier = interfaceType.name;
      expect(identifier.staticElement, same(cElement));
      expect(identifier.staticType, expectedType);
    }
  }

  test_top_enum() async {
    String content = r'''
enum MyEnum {
  A, B
}
''';
    addTestFile(content);
    AnalysisResult result = await driver.getResult(testFile);
    var typeProvider = result.unit.element.context.typeProvider;

    EnumDeclaration enumNode = result.unit.declarations[0];
    ClassElement enumElement = enumNode.element;

    SimpleIdentifier dName = enumNode.name;
    expect(dName.staticElement, same(enumElement));
    if (previewDart2) {
      expect(dName.staticType, typeProvider.typeType);
    }

    {
      var aElement = enumElement.getField('A');
      var aNode = enumNode.constants[0];
      expect(aNode.element, same(aElement));
      expect(aNode.name.staticElement, same(aElement));
      expect(aNode.name.staticType, same(enumElement.type));
    }

    {
      var bElement = enumElement.getField('B');
      var bNode = enumNode.constants[1];
      expect(bNode.element, same(bElement));
      expect(bNode.name.staticElement, same(bElement));
      expect(bNode.name.staticType, same(enumElement.type));
    }
  }

  test_top_executables_class() async {
    String content = r'''
class C {
  C(int p);
  C.named(int p);

  int publicMethod(double p) => 0;
  int get publicGetter => 0;
  void set publicSetter(double p) {}
}
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    expect(result.path, testFile);

    var typeProvider = result.unit.element.context.typeProvider;
    InterfaceType typeType = typeProvider.typeType;
    InterfaceType doubleType = typeProvider.doubleType;
    InterfaceType intType = typeProvider.intType;
    ClassElement doubleElement = doubleType.element;
    ClassElement intElement = intType.element;

    ClassDeclaration cNode = result.unit.declarations[0];
    ClassElement cElement = cNode.element;

    // The class name identifier.
    expect(cNode.name.staticElement, same(cElement));
    expect(cNode.name.staticType, typeType);

    // unnamed constructor
    {
      ConstructorDeclaration node = cNode.members[0];
      expect(node.element, isNotNull);
      expect(node.element.type.toString(), '(int) → C');
      expect(node.returnType.staticElement, same(cElement));
      expect(node.returnType.staticType, typeType);
      expect(node.name, isNull);
    }

    // named constructor
    {
      ConstructorDeclaration node = cNode.members[1];
      expect(node.element, isNotNull);
      expect(node.element.type.toString(), '(int) → C');
      expect(node.returnType.staticElement, same(cElement));
      expect(node.returnType.staticType, typeType);
      expect(node.name.staticElement, same(node.element));
      expect(node.name.staticType.toString(), '(int) → C');
    }

    // publicMethod()
    {
      MethodDeclaration node = cNode.members[2];
      expect(node.element, isNotNull);
      expect(node.element.type.toString(), '(double) → int');

      // method return type
      TypeName returnType = node.returnType;
      SimpleIdentifier returnTypeName = returnType.name;
      expect(returnType.type, intType);
      expect(returnTypeName.staticElement, intElement);
      expect(returnTypeName.staticType, intType);

      // method name
      expect(node.name.staticElement, same(node.element));
      expect(node.name.staticType, same(node.element.type));

      // method parameter
      {
        SimpleFormalParameter pNode = node.parameters.parameters[0];
        expect(pNode.element, isNotNull);
        expect(pNode.element.type, doubleType);

        TypeName pType = pNode.type;
        expect(pType.name.staticElement, doubleElement);
        expect(pType.name.staticType, doubleType);

        expect(pNode.identifier.staticElement, pNode.element);
        expect(pNode.identifier.staticType, doubleType);
      }
    }

    // publicGetter()
    {
      MethodDeclaration node = cNode.members[3];
      expect(node.element, isNotNull);
      expect(node.element.type.toString(), '() → int');

      // getter return type
      TypeName returnType = node.returnType;
      SimpleIdentifier returnTypeName = returnType.name;
      expect(returnType.type, intType);
      expect(returnTypeName.staticElement, intElement);
      expect(returnTypeName.staticType, intType);

      // getter name
      expect(node.name.staticElement, same(node.element));
      expect(node.name.staticType, intType);
    }

    // publicSetter()
    {
      MethodDeclaration node = cNode.members[4];
      expect(node.element, isNotNull);
      expect(node.element.type.toString(), '(double) → void');

      // setter return type
      TypeName returnType = node.returnType;
      SimpleIdentifier returnTypeName = returnType.name;
      expect(returnType.type, VoidTypeImpl.instance);
      expect(returnTypeName.staticElement, isNull);
      expect(returnTypeName.staticType, VoidTypeImpl.instance);

      // setter name
      expect(node.name.staticElement, same(node.element));
      expect(node.name.staticType, doubleType);

      // setter parameter
      {
        SimpleFormalParameter pNode = node.parameters.parameters[0];
        expect(pNode.element, isNotNull);
        expect(pNode.element.type, doubleType);

        TypeName pType = pNode.type;
        expect(pType.name.staticElement, doubleElement);
        expect(pType.name.staticType, doubleType);

        expect(pNode.identifier.staticElement, pNode.element);
        expect(pNode.identifier.staticType, doubleType);
      }
    }
  }

  test_top_executables_top() async {
    String content = r'''
int topFunction(double p) => 0;
int get topGetter => 0;
void set topSetter(double p) {}
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    expect(result.path, testFile);

    var typeProvider = result.unit.element.context.typeProvider;
    InterfaceType doubleType = typeProvider.doubleType;
    InterfaceType intType = typeProvider.intType;
    ClassElement doubleElement = doubleType.element;
    ClassElement intElement = intType.element;

    // topFunction()
    {
      FunctionDeclaration node = result.unit.declarations[0];
      expect(node.element, isNotNull);
      expect(node.element.type.toString(), '(double) → int');

      // function return type
      TypeName returnType = node.returnType;
      SimpleIdentifier returnTypeName = returnType.name;
      expect(returnType.type, intType);
      expect(returnTypeName.staticElement, intElement);
      expect(returnTypeName.staticType, intType);

      // function name
      expect(node.name.staticElement, same(node.element));
      expect(node.name.staticType, same(node.element.type));

      // function parameter
      {
        SimpleFormalParameter pNode =
            node.functionExpression.parameters.parameters[0];
        expect(pNode.element, isNotNull);
        expect(pNode.element.type, doubleType);

        TypeName pType = pNode.type;
        expect(pType.name.staticElement, doubleElement);
        expect(pType.name.staticType, doubleType);

        expect(pNode.identifier.staticElement, pNode.element);
        expect(pNode.identifier.staticType, doubleType);
      }
    }

    // topGetter()
    {
      FunctionDeclaration node = result.unit.declarations[1];
      expect(node.element, isNotNull);
      expect(node.element.type.toString(), '() → int');

      // getter return type
      TypeName returnType = node.returnType;
      SimpleIdentifier returnTypeName = returnType.name;
      expect(returnType.type, intType);
      expect(returnTypeName.staticElement, intElement);
      expect(returnTypeName.staticType, intType);

      // getter name
      expect(node.name.staticElement, same(node.element));
      expect(node.name.staticType, intType);
    }

    // topSetter()
    {
      FunctionDeclaration node = result.unit.declarations[2];
      expect(node.element, isNotNull);
      expect(node.element.type.toString(), '(double) → void');

      // setter return type
      TypeName returnType = node.returnType;
      SimpleIdentifier returnTypeName = returnType.name;
      expect(returnType.type, VoidTypeImpl.instance);
      expect(returnTypeName.staticElement, isNull);
      expect(returnTypeName.staticType, VoidTypeImpl.instance);

      // setter name
      expect(node.name.staticElement, same(node.element));
      expect(node.name.staticType, doubleType);

      // setter parameter
      {
        SimpleFormalParameter pNode =
            node.functionExpression.parameters.parameters[0];
        expect(pNode.element, isNotNull);
        expect(pNode.element.type, doubleType);

        TypeName pType = pNode.type;
        expect(pType.name.staticElement, doubleElement);
        expect(pType.name.staticType, doubleType);

        expect(pNode.identifier.staticElement, pNode.element);
        expect(pNode.identifier.staticType, doubleType);
      }
    }
  }

  test_top_field_class() async {
    String content = r'''
class C<T> {
  var a = 1;
  T b;
}
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;
    CompilationUnitElement unitElement = unit.element;
    var typeProvider = unitElement.context.typeProvider;

    ClassDeclaration cNode = unit.declarations[0];
    ClassElement cElement = cNode.element;
    TypeParameterElement tElement = cElement.typeParameters[0];
    expect(cElement, same(unitElement.types[0]));

    {
      FieldElement aElement = cElement.getField('a');
      FieldDeclaration aDeclaration = cNode.members[0];
      VariableDeclaration aNode = aDeclaration.fields.variables[0];
      expect(aNode.element, same(aElement));
      expect(aElement.type, typeProvider.intType);
      expect(aNode.name.staticElement, same(aElement));
      expect(aNode.name.staticType, same(aElement.type));

      Expression aValue = aNode.initializer;
      expect(aValue.staticType, typeProvider.intType);
    }

    {
      FieldElement bElement = cElement.getField('b');
      FieldDeclaration bDeclaration = cNode.members[1];

      TypeName typeName = bDeclaration.fields.type;
      SimpleIdentifier typeIdentifier = typeName.name;
      expect(typeIdentifier.staticElement, same(tElement));
      expect(typeIdentifier.staticType, same(tElement.type));

      VariableDeclaration bNode = bDeclaration.fields.variables[0];
      expect(bNode.element, same(bElement));
      expect(bElement.type, tElement.type);
      expect(bNode.name.staticElement, same(bElement));
      expect(bNode.name.staticType, same(bElement.type));
    }
  }

  test_top_field_class_multiple() async {
    String content = r'''
class C {
  var a = 1, b = 2.3;
}
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;
    CompilationUnitElement unitElement = unit.element;
    var typeProvider = unitElement.context.typeProvider;

    ClassDeclaration cNode = unit.declarations[0];
    ClassElement cElement = cNode.element;

    FieldDeclaration fieldDeclaration = cNode.members[0];

    {
      FieldElement aElement = cElement.getField('a');

      VariableDeclaration aNode = fieldDeclaration.fields.variables[0];
      expect(aNode.element, same(aElement));
      expect(aElement.type, typeProvider.intType);

      expect(aNode.name.staticElement, same(aElement));
      expect(aNode.name.staticType, same(aElement.type));

      Expression aValue = aNode.initializer;
      expect(aValue.staticType, typeProvider.intType);
    }

    {
      FieldElement bElement = cElement.getField('b');

      VariableDeclaration bNode = fieldDeclaration.fields.variables[1];
      expect(bNode.element, same(bElement));
      expect(bElement.type, typeProvider.doubleType);

      expect(bNode.name.staticElement, same(bElement));
      expect(bNode.name.staticType, same(bElement.type));

      Expression aValue = bNode.initializer;
      expect(aValue.staticType, typeProvider.doubleType);
    }
  }

  test_top_field_top() async {
    String content = r'''
var a = 1;
double b = 2.3;
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;
    CompilationUnitElement unitElement = unit.element;
    var typeProvider = unitElement.context.typeProvider;

    {
      TopLevelVariableDeclaration aDeclaration = unit.declarations[0];
      VariableDeclaration aNode = aDeclaration.variables.variables[0];
      TopLevelVariableElement aElement = aNode.element;
      expect(aElement, same(unitElement.topLevelVariables[0]));
      expect(aElement.type, typeProvider.intType);
      expect(aNode.name.staticElement, same(aElement));
      expect(aNode.name.staticType, same(aElement.type));

      Expression aValue = aNode.initializer;
      expect(aValue.staticType, typeProvider.intType);
    }

    {
      TopLevelVariableDeclaration bDeclaration = unit.declarations[1];

      VariableDeclaration bNode = bDeclaration.variables.variables[0];
      TopLevelVariableElement bElement = bNode.element;
      expect(bElement, same(unitElement.topLevelVariables[1]));
      expect(bElement.type, typeProvider.doubleType);

      TypeName typeName = bDeclaration.variables.type;
      _assertTypeNameSimple(typeName, typeProvider.doubleType);

      expect(bNode.name.staticElement, same(bElement));
      expect(bNode.name.staticType, same(bElement.type));

      Expression aValue = bNode.initializer;
      expect(aValue.staticType, typeProvider.doubleType);
    }
  }

  test_top_field_top_multiple() async {
    String content = r'''
var a = 1, b = 2.3;
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;
    CompilationUnitElement unitElement = unit.element;
    var typeProvider = unitElement.context.typeProvider;

    TopLevelVariableDeclaration variableDeclaration = unit.declarations[0];
    expect(variableDeclaration.variables.type, isNull);

    {
      VariableDeclaration aNode = variableDeclaration.variables.variables[0];
      TopLevelVariableElement aElement = aNode.element;
      expect(aElement, same(unitElement.topLevelVariables[0]));
      expect(aElement.type, typeProvider.intType);

      expect(aNode.name.staticElement, same(aElement));
      expect(aNode.name.staticType, aElement.type);

      Expression aValue = aNode.initializer;
      expect(aValue.staticType, typeProvider.intType);
    }

    {
      VariableDeclaration bNode = variableDeclaration.variables.variables[1];
      TopLevelVariableElement bElement = bNode.element;
      expect(bElement, same(unitElement.topLevelVariables[1]));
      expect(bElement.type, typeProvider.doubleType);

      expect(bNode.name.staticElement, same(bElement));
      expect(bNode.name.staticType, bElement.type);

      Expression aValue = bNode.initializer;
      expect(aValue.staticType, typeProvider.doubleType);
    }
  }

  test_top_function_namedParameters() async {
    addTestFile(r'''
double f(int a, {String b, bool c: 1 == 2}) {}
void main() {
  f(1, b: '2', c: true);
}
''');
    String fTypeString = '(int, {b: String, c: bool}) → double';

    AnalysisResult result = await driver.getResult(testFile);
    FunctionDeclaration fDeclaration = result.unit.declarations[0];
    FunctionElement fElement = fDeclaration.element;

    var typeProvider = result.unit.element.context.typeProvider;
    InterfaceType doubleType = typeProvider.doubleType;

    expect(fElement, isNotNull);
    expect(fElement.type.toString(), fTypeString);

    expect(fDeclaration.name.staticElement, same(fElement));
    expect(fDeclaration.name.staticType, fElement.type);

    TypeName fReturnTypeNode = fDeclaration.returnType;
    expect(fReturnTypeNode.name.staticElement, same(doubleType.element));
    expect(fReturnTypeNode.type, doubleType);
    //
    // Validate the parameters at the declaration site.
    //
    List<ParameterElement> elements = fElement.parameters;
    expect(elements, hasLength(3));

    List<FormalParameter> nodes =
        fDeclaration.functionExpression.parameters.parameters;
    expect(nodes, hasLength(3));

    _assertSimpleParameter(nodes[0], elements[0],
        name: 'a',
        offset: 13,
        kind: ParameterKind.REQUIRED,
        type: typeProvider.intType);

    DefaultFormalParameter bNode = nodes[1];
    _assertDefaultParameter(bNode, elements[1],
        name: 'b',
        offset: 24,
        kind: ParameterKind.NAMED,
        type: typeProvider.stringType);
    expect(bNode.defaultValue, isNull);

    DefaultFormalParameter cNode = nodes[2];
    _assertDefaultParameter(cNode, elements[2],
        name: 'c',
        offset: 32,
        kind: ParameterKind.NAMED,
        type: typeProvider.boolType);
    {
      BinaryExpression defaultValue = cNode.defaultValue;
      expect(defaultValue.staticElement, isNotNull);
      expect(defaultValue.staticType, typeProvider.boolType);
    }

    //
    // Validate the arguments at the call site.
    //
    FunctionDeclaration mainDeclaration = result.unit.declarations[1];
    BlockFunctionBody body = mainDeclaration.functionExpression.body;
    ExpressionStatement statement = body.block.statements[0];
    MethodInvocation invocation = statement.expression;
    List<Expression> arguments = invocation.argumentList.arguments;

    _assertArgumentToParameter(arguments[0], fElement.parameters[0]);
    _assertArgumentToParameter(arguments[1], fElement.parameters[1]);
    _assertArgumentToParameter(arguments[2], fElement.parameters[2]);
  }

  test_top_functionTypeAlias() async {
    String content = r'''
typedef int F<T>(bool a, T b);
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;
    CompilationUnitElement unitElement = unit.element;
    var typeProvider = unitElement.context.typeProvider;

    FunctionTypeAlias alias = unit.declarations[0];
    FunctionTypeAliasElement aliasElement = alias.element;
    expect(aliasElement, same(unitElement.functionTypeAliases[0]));
    expect(aliasElement.returnType, typeProvider.intType);

    _assertTypeNameSimple(alias.returnType, typeProvider.intType);

    _assertSimpleParameter(
        alias.parameters.parameters[0], aliasElement.parameters[0],
        name: 'a',
        offset: 22,
        kind: ParameterKind.REQUIRED,
        type: typeProvider.boolType);

    _assertSimpleParameter(
        alias.parameters.parameters[1], aliasElement.parameters[1],
        name: 'b',
        offset: 27,
        kind: ParameterKind.REQUIRED,
        type: aliasElement.typeParameters[0].type);
  }

  test_top_typeParameter() async {
    String content = r'''
class A {}
class C<T extends A, U extends List<A>, V> {}
''';
    addTestFile(content);
    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;
    CompilationUnitElement unitElement = unit.element;
    var typeProvider = unitElement.context.typeProvider;

    ClassDeclaration aNode = unit.declarations[0];
    ClassElement aElement = aNode.element;
    expect(aElement, same(unitElement.types[0]));

    ClassDeclaration cNode = unit.declarations[1];
    ClassElement cElement = cNode.element;
    expect(cElement, same(unitElement.types[1]));

    {
      TypeParameter tNode = cNode.typeParameters.typeParameters[0];
      expect(tNode.element, same(cElement.typeParameters[0]));

      TypeName bound = tNode.bound;
      expect(bound.type, aElement.type);

      SimpleIdentifier boundIdentifier = bound.name;
      expect(boundIdentifier.staticElement, same(aElement));
      expect(boundIdentifier.staticType, aElement.type);
    }

    {
      var listElement = typeProvider.listType.element;
      var listOfA = typeProvider.listType.instantiate([aElement.type]);

      TypeParameter uNode = cNode.typeParameters.typeParameters[1];
      expect(uNode.element, same(cElement.typeParameters[1]));

      TypeName bound = uNode.bound;
      expect(bound.type, listOfA);

      SimpleIdentifier listIdentifier = bound.name;
      expect(listIdentifier.staticElement, same(listElement));
      expect(listIdentifier.staticType, listOfA);

      TypeName aTypeName = bound.typeArguments.arguments[0];
      expect(aTypeName.type, aElement.type);

      SimpleIdentifier aIdentifier = aTypeName.name;
      expect(aIdentifier.staticElement, same(aElement));
      expect(aIdentifier.staticType, aElement.type);
    }

    {
      TypeParameter vNode = cNode.typeParameters.typeParameters[2];
      expect(vNode.element, same(cElement.typeParameters[2]));
      expect(vNode.bound, isNull);
    }
  }

  test_tryCatch() async {
    addTestFile(r'''
void main() {
  try {} catch (e, st) {
    e;
    st;
  }
  try {} on int catch (e, st) {
    e;
    st;
  }
  try {} catch (e) {
    e;
  }
  try {} on int catch (e) {
    e;
  }
  try {} on int {}
}
''');
    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;
    var typeProvider = unit.element.context.typeProvider;

    List<Statement> statements = _getMainStatements(result);

    // catch (e, st)
    {
      TryStatement statement = statements[0];
      CatchClause catchClause = statement.catchClauses[0];
      expect(catchClause.exceptionType, isNull);

      SimpleIdentifier exceptionNode = catchClause.exceptionParameter;
      LocalVariableElement exceptionElement = exceptionNode.staticElement;
      expect(exceptionElement.type, DynamicTypeImpl.instance);

      SimpleIdentifier stackNode = catchClause.stackTraceParameter;
      LocalVariableElement stackElement = stackNode.staticElement;
      expect(stackElement.type, typeProvider.stackTraceType);

      List<Statement> catchStatements = catchClause.body.statements;

      ExpressionStatement exceptionStatement = catchStatements[0];
      SimpleIdentifier exceptionIdentifier = exceptionStatement.expression;
      expect(exceptionIdentifier.staticElement, same(exceptionElement));
      expect(exceptionIdentifier.staticType, DynamicTypeImpl.instance);

      ExpressionStatement stackStatement = catchStatements[1];
      SimpleIdentifier stackIdentifier = stackStatement.expression;
      expect(stackIdentifier.staticElement, same(stackElement));
      expect(stackIdentifier.staticType, typeProvider.stackTraceType);
    }

    // on int catch (e, st)
    {
      TryStatement statement = statements[1];
      CatchClause catchClause = statement.catchClauses[0];
      _assertTypeNameSimple(catchClause.exceptionType, typeProvider.intType);

      SimpleIdentifier exceptionNode = catchClause.exceptionParameter;
      LocalVariableElement exceptionElement = exceptionNode.staticElement;
      expect(exceptionElement.type, typeProvider.intType);

      SimpleIdentifier stackNode = catchClause.stackTraceParameter;
      LocalVariableElement stackElement = stackNode.staticElement;
      expect(stackElement.type, typeProvider.stackTraceType);

      List<Statement> catchStatements = catchClause.body.statements;

      ExpressionStatement exceptionStatement = catchStatements[0];
      SimpleIdentifier exceptionIdentifier = exceptionStatement.expression;
      expect(exceptionIdentifier.staticElement, same(exceptionElement));
      expect(exceptionIdentifier.staticType, typeProvider.intType);

      ExpressionStatement stackStatement = catchStatements[1];
      SimpleIdentifier stackIdentifier = stackStatement.expression;
      expect(stackIdentifier.staticElement, same(stackElement));
      expect(stackIdentifier.staticType, typeProvider.stackTraceType);
    }

    // catch (e)
    {
      TryStatement statement = statements[2];
      CatchClause catchClause = statement.catchClauses[0];
      expect(catchClause.exceptionType, isNull);
      expect(catchClause.stackTraceParameter, isNull);

      SimpleIdentifier exceptionNode = catchClause.exceptionParameter;
      LocalVariableElement exceptionElement = exceptionNode.staticElement;
      expect(exceptionElement.type, DynamicTypeImpl.instance);
    }

    // on int catch (e)
    {
      TryStatement statement = statements[3];
      CatchClause catchClause = statement.catchClauses[0];
      _assertTypeNameSimple(catchClause.exceptionType, typeProvider.intType);
      expect(catchClause.stackTraceParameter, isNull);

      SimpleIdentifier exceptionNode = catchClause.exceptionParameter;
      LocalVariableElement exceptionElement = exceptionNode.staticElement;
      expect(exceptionElement.type, typeProvider.intType);
    }

    // on int catch (e)
    {
      TryStatement statement = statements[4];
      CatchClause catchClause = statement.catchClauses[0];
      _assertTypeNameSimple(catchClause.exceptionType, typeProvider.intType);
      expect(catchClause.exceptionParameter, isNull);
      expect(catchClause.stackTraceParameter, isNull);
    }
  }

  test_type_functionTypeAlias() async {
    addTestFile(r'''
typedef T F<T>(bool a);
class C {
  F<int> f;
}
''');

    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;
    CompilationUnitElement unitElement = unit.element;
    var typeProvider = unitElement.context.typeProvider;

    FunctionTypeAlias alias = unit.declarations[0];
    GenericTypeAliasElement aliasElement = alias.element;
    FunctionType aliasType = aliasElement.type;

    ClassDeclaration cNode = unit.declarations[1];

    FieldDeclaration fDeclaration = cNode.members[0];
    FunctionType instantiatedAliasType =
        aliasType.instantiate([typeProvider.intType]);

    TypeName typeName = fDeclaration.fields.type;
    expect(typeName.type, instantiatedAliasType);

    SimpleIdentifier typeIdentifier = typeName.name;
    expect(typeIdentifier.staticElement, same(aliasElement));
    expect(typeIdentifier.staticType, instantiatedAliasType);

    List<TypeAnnotation> typeArguments = typeName.typeArguments.arguments;
    expect(typeArguments, hasLength(1));
    _assertTypeNameSimple(typeArguments[0], typeProvider.intType);
  }

  test_typeAnnotation_prefixed() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    var c = _p('/test/lib/c.dart');
    provider.newFile(a, 'class A {}');
    provider.newFile(b, "export 'a.dart';");
    provider.newFile(c, "export 'a.dart';");
    addTestFile(r'''
import 'b.dart' as b;
import 'c.dart' as c;
b.A a1;
c.A a2;
''');
    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;

    ImportElement bImport = unit.element.library.imports[0];
    ImportElement cImport = unit.element.library.imports[1];

    LibraryElement bLibrary = bImport.importedLibrary;
    LibraryElement aLibrary = bLibrary.exports[0].exportedLibrary;
    ClassElement aClass = aLibrary.getType('A');

    {
      TopLevelVariableDeclaration declaration = unit.declarations[0];
      TypeName typeName = declaration.variables.type;

      PrefixedIdentifier typeIdentifier = typeName.name;
      expect(typeIdentifier.staticElement, aClass);

      expect(typeIdentifier.prefix.name, 'b');
      expect(typeIdentifier.prefix.staticElement, same(bImport.prefix));

      expect(typeIdentifier.identifier.staticElement, aClass);
    }

    {
      TopLevelVariableDeclaration declaration = unit.declarations[1];
      TypeName typeName = declaration.variables.type;

      PrefixedIdentifier typeIdentifier = typeName.name;
      expect(typeIdentifier.staticElement, aClass);

      expect(typeIdentifier.prefix.name, 'c');
      expect(typeIdentifier.prefix.staticElement, same(cImport.prefix));

      expect(typeIdentifier.identifier.staticElement, aClass);
    }
  }

  test_typeLiteral() async {
    addTestFile(r'''
void main() {
  int;
  F;
}
typedef void F(int p);
''');
    AnalysisResult result = await driver.getResult(testFile);
    CompilationUnit unit = result.unit;
    var typeProvider = unit.element.context.typeProvider;

    FunctionTypeAlias fNode = unit.declarations[1];
    FunctionTypeAliasElement fElement = fNode.element;

    var statements = _getMainStatements(result);

    {
      ExpressionStatement statement = statements[0];
      SimpleIdentifier identifier = statement.expression;
      expect(identifier.staticElement, same(typeProvider.intType.element));
      expect(identifier.staticType, typeProvider.typeType);
    }

    {
      ExpressionStatement statement = statements[1];
      SimpleIdentifier identifier = statement.expression;
      expect(identifier.staticElement, same(fElement));
      expect(identifier.staticType, typeProvider.typeType);
    }
  }

  /// Assert that the [argument] is associated with the [expectedParameter],
  /// if [previewDart2] is `null`. If the [argument] is a [NamedExpression],
  /// the name must be resolved to the parameter in both cases.
  void _assertArgumentToParameter(
      Expression argument, ParameterElement expectedParameter,
      {DartType parameterMemberType}) {
    ParameterElement actualParameter = argument.staticParameterElement;
    if (previewDart2) {
      expect(actualParameter, isNull);
    } else {
      ParameterElement baseActualParameter;
      if (actualParameter is ParameterMember) {
        if (parameterMemberType != null) {
          expect(actualParameter.type, parameterMemberType);
        }
        baseActualParameter = actualParameter.baseElement;
        // Unwrap ParameterMember one more time.
        // By some reason we wrap in twice.
        if (baseActualParameter is ParameterMember) {
          ParameterMember member = baseActualParameter;
          baseActualParameter = member.baseElement;
        }
      } else {
        baseActualParameter = actualParameter;
      }
      expect(baseActualParameter, same(expectedParameter));
      // TODO(scheglov) Make this work for previewDart2 too.
      if (argument is NamedExpression) {
        expect(argument.name.label.staticElement, same(expectedParameter));
      }
    }
  }

  void _assertDefaultParameter(
      DefaultFormalParameter node, ParameterElement element,
      {String name, int offset, ParameterKind kind, DartType type}) {
    expect(node, isNotNull);
    NormalFormalParameter normalNode = node.parameter;
    _assertSimpleParameter(normalNode, element,
        name: name, offset: offset, kind: kind, type: type);
  }

  /// Assert that the [type] is a function type `() -> dynamic`.
  void _assertDynamicFunctionType(DartType type) {
    if (previewDart2) {
      expect(type.toString(), '() → dynamic');
    } else {
      expect(type, DynamicTypeImpl.instance);
    }
  }

  void _assertParameterElement(ParameterElement element,
      {String name, int offset, ParameterKind kind, DartType type}) {
    expect(element, isNotNull);
    expect(name, isNotNull);
    expect(offset, isNotNull);
    expect(kind, isNotNull);
    expect(type, isNotNull);
    expect(element.name, name);
    expect(element.nameOffset, offset);
    expect(element.parameterKind, kind);
    expect(element.type, type);
  }

  void _assertSimpleParameter(
      SimpleFormalParameter node, ParameterElement element,
      {String name, int offset, ParameterKind kind, DartType type}) {
    _assertParameterElement(element,
        name: name, offset: offset, kind: kind, type: type);

    expect(node, isNotNull);
    expect(node.element, same(element));
    expect(node.identifier.staticElement, same(element));

    TypeName typeName = node.type;
    if (typeName != null) {
      expect(typeName.type, same(type));
      expect(typeName.name.staticElement, same(type.element));
    }
  }

  void _assertTypeNameSimple(TypeName typeName, DartType type) {
    expect(typeName.type, type);

    SimpleIdentifier identifier = typeName.name;
    expect(identifier.staticElement, same(type.element));
    expect(identifier.staticType, type);
  }

  List<Statement> _getMainStatements(AnalysisResult result) {
    for (var declaration in result.unit.declarations) {
      if (declaration is FunctionDeclaration &&
          declaration.name.name == 'main') {
        BlockFunctionBody body = declaration.functionExpression.body;
        return body.block.statements;
      }
    }
    fail('Not found main() in ${result.unit}');
    return null;
  }

  /**
   * Return the [provider] specific path for the given Posix [path].
   */
  String _p(String path) => provider.convertPath(path);
}

@reflectiveTest
class AnalysisDriverSchedulerTest {
  final MemoryResourceProvider provider = new MemoryResourceProvider();
  DartSdk sdk;
  final ByteStore byteStore = new MemoryByteStore();
  final FileContentOverlay contentOverlay = new FileContentOverlay();

  final StringBuffer logBuffer = new StringBuffer();
  PerformanceLog logger;

  AnalysisDriverScheduler scheduler;

  List<AnalysisResult> allResults = [];

  AnalysisDriver newDriver() {
    sdk = new MockSdk(resourceProvider: provider);
    AnalysisDriver driver = new AnalysisDriver(
        scheduler,
        logger,
        provider,
        byteStore,
        contentOverlay,
        null,
        new SourceFactory(
            [new DartUriResolver(sdk), new ResourceUriResolver(provider)],
            null,
            provider),
        new AnalysisOptionsImpl()..strongMode = true);
    driver.results.forEach(allResults.add);
    return driver;
  }

  void setUp() {
    sdk = new MockSdk(resourceProvider: provider);
    logger = new PerformanceLog(logBuffer);
    scheduler = new AnalysisDriverScheduler(logger);
    scheduler.start();
  }

  test_priorities_allChangedFirst() async {
    AnalysisDriver driver1 = newDriver();
    AnalysisDriver driver2 = newDriver();

    String a = _p('/a.dart');
    String b = _p('/b.dart');
    String c = _p('/c.dart');
    String d = _p('/d.dart');
    provider.newFile(a, 'class A {}');
    provider.newFile(b, "import 'a.dart';");
    provider.newFile(c, 'class C {}');
    provider.newFile(d, "import 'c.dart';");
    driver1.addFile(a);
    driver1.addFile(b);
    driver2.addFile(c);
    driver2.addFile(d);

    await scheduler.waitForIdle();
    allResults.clear();

    provider.updateFile(a, 'class A2 {}');
    provider.updateFile(c, 'class C2 {}');
    driver1.changeFile(a);
    driver1.changeFile(c);
    driver2.changeFile(a);
    driver2.changeFile(c);

    await scheduler.waitForIdle();
    expect(allResults, hasLength(greaterThanOrEqualTo(2)));
    expect(allResults[0].path, a);
    expect(allResults[1].path, c);
  }

  test_priorities_firstChanged_thenImporting() async {
    AnalysisDriver driver1 = newDriver();
    AnalysisDriver driver2 = newDriver();

    String a = _p('/a.dart');
    String b = _p('/b.dart');
    String c = _p('/c.dart');
    provider.newFile(a, "import 'c.dart';");
    provider.newFile(b, 'class B {}');
    provider.newFile(c, "import 'b.dart';");
    driver1.addFile(a);
    driver1.addFile(b);
    driver2.addFile(c);

    await scheduler.waitForIdle();
    allResults.clear();

    provider.updateFile(b, 'class B2 {}');
    driver1.changeFile(b);
    driver2.changeFile(b);

    await scheduler.waitForIdle();
    expect(allResults, hasLength(greaterThanOrEqualTo(2)));
    expect(allResults[0].path, b);
    expect(allResults[1].path, c);
  }

  test_priorities_firstChanged_thenWithErrors() async {
    AnalysisDriver driver1 = newDriver();
    AnalysisDriver driver2 = newDriver();

    String a = _p('/a.dart');
    String b = _p('/b.dart');
    String c = _p('/c.dart');
    String d = _p('/d.dart');
    provider.newFile(a, 'class A {}');
    provider.newFile(b, "export 'a.dart';");
    provider.newFile(c, "import 'b.dart';");
    provider.newFile(d, "import 'b.dart'; class D extends X {}");
    driver1.addFile(a);
    driver1.addFile(b);
    driver2.addFile(c);
    driver2.addFile(d);

    await scheduler.waitForIdle();
    allResults.clear();

    provider.updateFile(a, 'class A2 {}');
    driver1.changeFile(a);
    driver2.changeFile(a);

    await scheduler.waitForIdle();
    expect(allResults, hasLength(greaterThanOrEqualTo(2)));
    expect(allResults[0].path, a);
    expect(allResults[1].path, d);
  }

  test_priorities_getResult_beforePriority() async {
    AnalysisDriver driver1 = newDriver();
    AnalysisDriver driver2 = newDriver();

    String a = _p('/a.dart');
    String b = _p('/b.dart');
    String c = _p('/c.dart');
    provider.newFile(a, 'class A {}');
    provider.newFile(b, 'class B {}');
    provider.newFile(c, 'class C {}');
    driver1.addFile(a);
    driver2.addFile(b);
    driver2.addFile(c);
    driver1.priorityFiles = [a];
    driver2.priorityFiles = [a];

    AnalysisResult result = await driver2.getResult(b);
    expect(result.path, b);

    await scheduler.status.firstWhere((status) => status.isIdle);

    expect(allResults, hasLength(3));
    expect(allResults[0].path, b);
    expect(allResults[1].path, a);
    expect(allResults[2].path, c);
  }

  test_priorities_priorityBeforeGeneral1() async {
    AnalysisDriver driver1 = newDriver();
    AnalysisDriver driver2 = newDriver();

    String a = _p('/a.dart');
    String b = _p('/b.dart');
    provider.newFile(a, 'class A {}');
    provider.newFile(b, 'class B {}');
    driver1.addFile(a);
    driver2.addFile(b);
    driver1.priorityFiles = [a];
    driver2.priorityFiles = [a];

    await scheduler.status.firstWhere((status) => status.isIdle);

    expect(allResults, hasLength(2));
    expect(allResults[0].path, a);
    expect(allResults[1].path, b);
  }

  test_priorities_priorityBeforeGeneral2() async {
    AnalysisDriver driver1 = newDriver();
    AnalysisDriver driver2 = newDriver();

    String a = _p('/a.dart');
    String b = _p('/b.dart');
    provider.newFile(a, 'class A {}');
    provider.newFile(b, 'class B {}');
    driver1.addFile(a);
    driver2.addFile(b);
    driver1.priorityFiles = [b];
    driver2.priorityFiles = [b];

    await scheduler.status.firstWhere((status) => status.isIdle);

    expect(allResults, hasLength(2));
    expect(allResults[0].path, b);
    expect(allResults[1].path, a);
  }

  test_priorities_priorityBeforeGeneral3() async {
    AnalysisDriver driver1 = newDriver();
    AnalysisDriver driver2 = newDriver();

    String a = _p('/a.dart');
    String b = _p('/b.dart');
    String c = _p('/c.dart');
    provider.newFile(a, 'class A {}');
    provider.newFile(b, 'class B {}');
    provider.newFile(c, 'class C {}');
    driver1.addFile(a);
    driver1.addFile(b);
    driver2.addFile(c);
    driver1.priorityFiles = [a, c];
    driver2.priorityFiles = [a, c];

    await scheduler.status.firstWhere((status) => status.isIdle);

    expect(allResults, hasLength(3));
    expect(allResults[0].path, a);
    expect(allResults[1].path, c);
    expect(allResults[2].path, b);
  }

  test_status() async {
    AnalysisDriver driver1 = newDriver();
    AnalysisDriver driver2 = newDriver();

    String a = _p('/a.dart');
    String b = _p('/b.dart');
    String c = _p('/c.dart');
    provider.newFile(a, 'class A {}');
    provider.newFile(b, 'class B {}');
    provider.newFile(c, 'class C {}');
    driver1.addFile(a);
    driver2.addFile(b);
    driver2.addFile(c);

    Monitor idleStatusMonitor = new Monitor();
    List<AnalysisStatus> allStatuses = [];
    scheduler.status.forEach((status) {
      allStatuses.add(status);
      if (status.isIdle) {
        idleStatusMonitor.notify();
      }
    });

    await idleStatusMonitor.signal;

    expect(allStatuses, hasLength(2));
    expect(allStatuses[0].isAnalyzing, isTrue);
    expect(allStatuses[1].isAnalyzing, isFalse);

    expect(allResults, hasLength(3));
  }

  test_status_analyzingOnlyWhenHasFilesToAnalyze() async {
    AnalysisDriver driver1 = newDriver();
    AnalysisDriver driver2 = newDriver();

    String a = _p('/a.dart');
    String b = _p('/b.dart');
    provider.newFile(a, 'class A {}');
    provider.newFile(b, 'class B {}');
    driver1.addFile(a);
    driver2.addFile(b);

    Monitor idleStatusMonitor = new Monitor();
    List<AnalysisStatus> allStatuses = [];
    scheduler.status.forEach((status) {
      allStatuses.add(status);
      if (status.isIdle) {
        idleStatusMonitor.notify();
      }
    });

    // The two added files were analyzed, and the schedule is idle.
    await idleStatusMonitor.signal;
    expect(allStatuses, hasLength(2));
    expect(allStatuses[0].isAnalyzing, isTrue);
    expect(allStatuses[1].isAnalyzing, isFalse);
    allStatuses.clear();

    // We don't transition to analysis and back to idle.
    await driver1.getFilesReferencingName('X');
    expect(allStatuses, isEmpty);
  }

  String _p(String path) => provider.convertPath(path);
}

@reflectiveTest
class AnalysisDriverTest extends BaseAnalysisDriverTest {
  test_addedFiles() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');

    driver.addFile(a);
    expect(driver.addedFiles, contains(a));
    expect(driver.addedFiles, isNot(contains(b)));

    driver.removeFile(a);
    expect(driver.addedFiles, isNot(contains(a)));
    expect(driver.addedFiles, isNot(contains(b)));
  }

  test_addFile_notAbsolutePath() async {
    try {
      driver.addFile('not_absolute.dart');
      fail('ArgumentError expected.');
    } on ArgumentError {}
  }

  test_addFile_shouldRefresh() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');

    provider.newFile(a, 'class A {}');
    provider.newFile(b, r'''
import 'a.dart';
''');

    driver.addFile(a);
    driver.addFile(b);

    void assertNumberOfErrorsInB(int n) {
      var bResult = allResults.singleWhere((r) => r.path == b);
      expect(bResult.errors, hasLength(n));
      allResults.clear();
    }

    // Initial analysis, 'b' does not use 'a', so there is a hint.
    await waitForIdleWithoutExceptions();
    assertNumberOfErrorsInB(1);

    // Update 'b' to use 'a', no more hints.
    provider.newFile(b, r'''
import 'a.dart';
main() {
  print(A);
}
''');
    driver.changeFile(b);
    await waitForIdleWithoutExceptions();
    assertNumberOfErrorsInB(0);

    // Change 'b' content so that it has a hint.
    // Remove 'b' and add it again.
    // The file 'b' must be refreshed, and the hint must be reported.
    provider.newFile(b, r'''
import 'a.dart';
''');
    driver.removeFile(b);
    driver.addFile(b);
    await waitForIdleWithoutExceptions();
    assertNumberOfErrorsInB(1);
  }

  test_addFile_thenRemove() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    provider.newFile(a, 'class A {}');
    provider.newFile(b, 'class B {}');
    driver.addFile(a);
    driver.addFile(b);

    // Now remove 'a'.
    driver.removeFile(a);

    await waitForIdleWithoutExceptions();

    // Only 'b' has been analyzed, because 'a' was removed before we started.
    expect(allResults, hasLength(1));
    expect(allResults[0].path, b);
  }

  test_analyze_resolveDirectives() async {
    var lib = _p('/test/lib.dart');
    var part1 = _p('/test/part1.dart');
    var part2 = _p('/test/part2.dart');
    provider.newFile(lib, '''
library lib;
part 'part1.dart';
part 'part2.dart';
''');
    provider.newFile(part1, '''
part of lib;
''');
    provider.newFile(part2, '''
part of 'lib.dart';
''');

    AnalysisResult libResult = await driver.getResult(lib);
    AnalysisResult partResult1 = await driver.getResult(part1);
    AnalysisResult partResult2 = await driver.getResult(part2);

    CompilationUnit libUnit = libResult.unit;
    CompilationUnit partUnit1 = partResult1.unit;
    CompilationUnit partUnit2 = partResult2.unit;

    CompilationUnitElement unitElement = libUnit.element;
    CompilationUnitElement partElement1 = partUnit1.element;
    CompilationUnitElement partElement2 = partUnit2.element;

    LibraryElement libraryElement = unitElement.library;
    {
      expect(libraryElement.entryPoint, isNull);
      expect(libraryElement.source, unitElement.source);
      expect(libraryElement.definingCompilationUnit, unitElement);
      expect(libraryElement.parts, hasLength(2));
    }

    expect((libUnit.directives[0] as LibraryDirective).element, libraryElement);
    expect((libUnit.directives[1] as PartDirective).element, partElement1);
    expect((libUnit.directives[2] as PartDirective).element, partElement2);

    {
      var partOf = partUnit1.directives.single as PartOfDirective;
      expect(partOf.element, libraryElement);
    }

    {
      var partOf = partUnit2.directives.single as PartOfDirective;
      expect(partOf.element, libraryElement);
    }
  }

  test_analyze_resolveDirectives_error_missingLibraryDirective() async {
    var lib = _p('/test/lib.dart');
    var part = _p('/test/part.dart');
    provider.newFile(lib, '''
part 'part.dart';
''');
    provider.newFile(part, '''
part of lib;
''');

    driver.addFile(lib);

    AnalysisResult libResult = await driver.getResult(lib);
    List<AnalysisError> errors = libResult.errors;
    if (libResult.unit.element.context.analysisOptions.enableUriInPartOf) {
      expect(errors, hasLength(1));
      expect(errors[0].errorCode, ResolverErrorCode.PART_OF_UNNAMED_LIBRARY);
    } else {
      expect(errors, hasLength(1));
      expect(errors[0].errorCode,
          ResolverErrorCode.MISSING_LIBRARY_DIRECTIVE_WITH_PART);
    }
  }

  test_analyze_resolveDirectives_error_partOfDifferentLibrary_byName() async {
    var lib = _p('/test/lib.dart');
    var part = _p('/test/part.dart');
    provider.newFile(lib, '''
library lib;
part 'part.dart';
''');
    provider.newFile(part, '''
part of someOtherLib;
''');

    driver.addFile(lib);

    AnalysisResult libResult = await driver.getResult(lib);
    List<AnalysisError> errors = libResult.errors;
    expect(errors, hasLength(1));
    expect(errors[0].errorCode, StaticWarningCode.PART_OF_DIFFERENT_LIBRARY);
  }

  test_analyze_resolveDirectives_error_partOfDifferentLibrary_byUri() async {
    var lib = _p('/test/lib.dart');
    var part = _p('/test/part.dart');
    provider.newFile(lib, '''
library lib;
part 'part.dart';
''');
    provider.newFile(part, '''
part of 'other_lib.dart';
''');

    driver.addFile(lib);

    AnalysisResult libResult = await driver.getResult(lib);
    List<AnalysisError> errors = libResult.errors;
    expect(errors, hasLength(1));
    expect(errors[0].errorCode, StaticWarningCode.PART_OF_DIFFERENT_LIBRARY);
  }

  test_analyze_resolveDirectives_error_partOfNonPart() async {
    var lib = _p('/test/lib.dart');
    var part = _p('/test/part.dart');
    provider.newFile(lib, '''
library lib;
part 'part.dart';
''');
    provider.newFile(part, '''
// no part of directive
''');

    driver.addFile(lib);

    AnalysisResult libResult = await driver.getResult(lib);
    List<AnalysisError> errors = libResult.errors;
    expect(errors, hasLength(1));
    expect(errors[0].errorCode, CompileTimeErrorCode.PART_OF_NON_PART);
  }

  test_asyncChangesDuringAnalysis_getErrors() async {
    var path = _p('/test/lib/test.dart');
    provider.newFile(path, 'class A {}');
    driver.addFile(path);

    // Compute and cache errors.
    await driver.getErrors(path);
    await waitForIdleWithoutExceptions();

    // Simulate a change that happens during reading the cached errors.
    bool asyncWorkExecuted = false;
    driver.test.workToWaitAfterComputingResult = (path) {
      provider.updateFile(path, 'class B');
      driver.changeFile(path);
      asyncWorkExecuted = true;
    };

    ErrorsResult result = await driver.getErrors(testFile);
    expect(asyncWorkExecuted, isTrue);
    expect(result.errors, isNotEmpty);
  }

  test_asyncChangesDuringAnalysis_getResult() async {
    var path = _p('/test/lib/test.dart');
    provider.newFile(path, 'class A {}');
    driver.addFile(path);

    // Schedule the result to be computed.
    Future<AnalysisResult> future1 = driver.getResult(testFile);

    // Simulate a change that happens during computing the result.
    // We also request a new result, which must include the change.
    Future<AnalysisResult> future2;
    bool asyncWorkExecuted = false;
    driver.test.workToWaitAfterComputingResult = (path) {
      provider.updateFile(path, 'class B {}');
      driver.changeFile(path);
      future2 = driver.getResult(testFile);
      asyncWorkExecuted = true;
    };

    // Both futures complete, with the same result.
    // The result must be with the new changes.
    //
    // It would not be wrong to have "class A {}" in result1, and "class B {}"
    // in result2, but we test here the actual implementation behaviour.
    AnalysisResult result1 = await future1;
    AnalysisResult result2 = await future2;
    expect(asyncWorkExecuted, isTrue);
    expect(result2, same(result1));
    expect(result1.path, testFile);
    expect(result1.unit, isNotNull);
    expect((result1.unit.declarations[0] as ClassDeclaration).name.name, 'B');
  }

  test_asyncChangesDuringAnalysis_resultsStream() async {
    var path = _p('/test/lib/test.dart');
    provider.newFile(path, 'class A {}');
    driver.addFile(path);

    // Simulate a change that happens during computing the result.
    bool asyncWorkExecuted = false;
    driver.test.workToWaitAfterComputingResult = (p) {
      if (p == path && !asyncWorkExecuted) {
        provider.updateFile(path, 'class B');
        driver.changeFile(path);
        asyncWorkExecuted = true;
      }
    };

    await waitForIdleWithoutExceptions();
    expect(asyncWorkExecuted, isTrue);

    // The last result must have an error.
    expect(allResults.last.errors, isNotEmpty);
  }

  test_asyncChangesDuringAnalysis_resultsStream_priority() async {
    var path = _p('/test/lib/test.dart');
    provider.newFile(path, 'class A {}');
    driver.addFile(path);
    driver.priorityFiles = [path];

    // Simulate a change that happens during computing the result.
    bool asyncWorkExecuted = false;
    driver.test.workToWaitAfterComputingResult = (p) {
      if (p == path && !asyncWorkExecuted) {
        provider.updateFile(path, 'class B {}');
        driver.changeFile(path);
        asyncWorkExecuted = true;
      }
    };

    await waitForIdleWithoutExceptions();
    expect(asyncWorkExecuted, isTrue);

    // The last unit must have "class B {}".
    var lastUnit = allResults.last.unit;
    expect((lastUnit.declarations[0] as ClassDeclaration).name.name, 'B');
  }

  test_cachedPriorityResults() async {
    var a = _p('/test/bin/a.dart');
    provider.newFile(a, 'var a = 1;');

    driver.priorityFiles = [a];

    AnalysisResult result1 = await driver.getResult(a);
    expect(driver.test.priorityResults, containsPair(a, result1));

    await waitForIdleWithoutExceptions();
    allResults.clear();

    // Get the (cached) result, not reported to the stream.
    {
      AnalysisResult result2 = await driver.getResult(a);
      expect(result2, same(result1));
      expect(allResults, isEmpty);
    }

    // Get the (cached) result, reported to the stream.
    {
      AnalysisResult result2 =
          await driver.getResult(a, sendCachedToStream: true);
      expect(result2, same(result1));

      expect(allResults, hasLength(1));
      expect(allResults.single, same(result1));
    }
  }

  test_cachedPriorityResults_flush_onAnyFileChange() async {
    var a = _p('/test/bin/a.dart');
    var b = _p('/test/bin/b.dart');
    provider.newFile(a, 'var a = 1;');
    provider.newFile(a, 'var b = 2;');

    driver.priorityFiles = [a];

    AnalysisResult result1 = await driver.getResult(a);
    expect(driver.test.priorityResults, containsPair(a, result1));

    // Change a file.
    // The cache is flushed.
    driver.changeFile(a);
    expect(driver.test.priorityResults, isEmpty);
    AnalysisResult result2 = await driver.getResult(a);
    expect(driver.test.priorityResults, containsPair(a, result2));

    // Add a file.
    // The cache is flushed.
    driver.addFile(b);
    expect(driver.test.priorityResults, isEmpty);
    AnalysisResult result3 = await driver.getResult(a);
    expect(driver.test.priorityResults, containsPair(a, result3));

    // Remove a file.
    // The cache is flushed.
    driver.removeFile(b);
    expect(driver.test.priorityResults, isEmpty);
  }

  test_cachedPriorityResults_flush_onPrioritySetChange() async {
    var a = _p('/test/bin/a.dart');
    var b = _p('/test/bin/b.dart');
    provider.newFile(a, 'var a = 1;');
    provider.newFile(b, 'var b = 2;');

    driver.priorityFiles = [a];

    AnalysisResult result1 = await driver.getResult(a);
    expect(driver.test.priorityResults, hasLength(1));
    expect(driver.test.priorityResults, containsPair(a, result1));

    // Make "a" and "b" priority.
    // We still have the result for "a" cached.
    driver.priorityFiles = [a, b];
    expect(driver.test.priorityResults, hasLength(1));
    expect(driver.test.priorityResults, containsPair(a, result1));

    // Get the result for "b".
    AnalysisResult result2 = await driver.getResult(b);
    expect(driver.test.priorityResults, hasLength(2));
    expect(driver.test.priorityResults, containsPair(a, result1));
    expect(driver.test.priorityResults, containsPair(b, result2));

    // Only "b" is priority.
    // The result for "a" is flushed.
    driver.priorityFiles = [b];
    expect(driver.test.priorityResults, hasLength(1));
    expect(driver.test.priorityResults, containsPair(b, result2));
  }

  test_cachedPriorityResults_notPriority() async {
    var a = _p('/test/bin/a.dart');
    provider.newFile(a, 'var a = 1;');

    AnalysisResult result1 = await driver.getResult(a);
    expect(driver.test.priorityResults, isEmpty);

    // The file is not priority, so its result is not cached.
    AnalysisResult result2 = await driver.getResult(a);
    expect(result2, isNot(same(result1)));
  }

  test_changeFile_implicitlyAnalyzed() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    provider.newFile(a, r'''
import 'b.dart';
var A = B;
''');
    provider.newFile(b, 'var B = 1;');

    driver.priorityFiles = [a];
    driver.addFile(a);

    // We have a result only for "a".
    await waitForIdleWithoutExceptions();
    expect(allResults, hasLength(1));
    {
      AnalysisResult ar = allResults.firstWhere((r) => r.path == a);
      expect(_getTopLevelVarType(ar.unit, 'A'), 'int');
    }
    allResults.clear();

    // Change "b" and notify.
    provider.updateFile(b, 'var B = 1.2;');
    driver.changeFile(b);

    // "b" is not an added file, so it is not scheduled for analysis.
    expect(driver.test.fileTracker.hasPendingFiles, isFalse);

    // While "b" is not analyzed explicitly, it is analyzed implicitly.
    // The change causes "a" to be reanalyzed.
    await waitForIdleWithoutExceptions();
    expect(allResults, hasLength(1));
    {
      AnalysisResult ar = allResults.firstWhere((r) => r.path == a);
      expect(_getTopLevelVarType(ar.unit, 'A'), 'double');
    }
  }

  test_changeFile_notAbsolutePath() async {
    try {
      driver.changeFile('not_absolute.dart');
      fail('ArgumentError expected.');
    } on ArgumentError {}
  }

  test_changeFile_notUsed() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/other/b.dart');
    provider.newFile(a, '');
    provider.newFile(b, 'class B1 {}');

    driver.addFile(a);

    await waitForIdleWithoutExceptions();
    allResults.clear();

    // Change "b" and notify.
    // Nothing depends on "b", so nothing is analyzed.
    provider.updateFile(b, 'class B2 {}');
    driver.changeFile(b);
    await waitForIdleWithoutExceptions();
    expect(allResults, isEmpty);

    // This should not add "b" to the file state.
    expect(driver.fsState.knownFilePaths, isNot(contains(b)));
  }

  test_changeFile_selfConsistent() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    provider.newFile(a, r'''
import 'b.dart';
var A1 = 1;
var A2 = B1;
''');
    provider.newFile(b, r'''
import 'a.dart';
var B1 = A1;
''');

    driver.priorityFiles = [a, b];
    driver.addFile(a);
    driver.addFile(b);
    await waitForIdleWithoutExceptions();

    // We have results for both "a" and "b".
    expect(allResults, hasLength(2));
    {
      AnalysisResult ar = allResults.firstWhere((r) => r.path == a);
      expect(_getTopLevelVarType(ar.unit, 'A1'), 'int');
      expect(_getTopLevelVarType(ar.unit, 'A2'), 'int');
    }
    {
      AnalysisResult br = allResults.firstWhere((r) => r.path == b);
      expect(_getTopLevelVarType(br.unit, 'B1'), 'int');
    }

    // Clear the results and update "a".
    allResults.clear();
    provider.updateFile(a, r'''
import 'b.dart';
var A1 = 1.2;
var A2 = B1;
''');
    driver.changeFile(a);

    // We again get results for both "a" and "b".
    // The results are consistent.
    await waitForIdleWithoutExceptions();
    expect(allResults, hasLength(2));
    {
      AnalysisResult ar = allResults.firstWhere((r) => r.path == a);
      expect(_getTopLevelVarType(ar.unit, 'A1'), 'double');
      expect(_getTopLevelVarType(ar.unit, 'A2'), 'double');
    }
    {
      AnalysisResult br = allResults.firstWhere((r) => r.path == b);
      expect(_getTopLevelVarType(br.unit, 'B1'), 'double');
    }
  }

  test_changeFile_single() async {
    addTestFile('var V = 1;', priority: true);

    // Initial analysis.
    {
      await waitForIdleWithoutExceptions();
      expect(allResults, hasLength(1));
      AnalysisResult result = allResults[0];
      expect(result.path, testFile);
      expect(_getTopLevelVarType(result.unit, 'V'), 'int');
    }

    // Update the file, but don't notify the driver.
    allResults.clear();
    provider.updateFile(testFile, 'var V = 1.2;');

    // No new results.
    await pumpEventQueue();
    expect(allResults, isEmpty);

    // Notify the driver about the change.
    driver.changeFile(testFile);

    // The file was added, so it is scheduled for analysis.
    expect(driver.test.fileTracker.isFilePending(testFile), isTrue);

    // We get a new result.
    {
      await waitForIdleWithoutExceptions();
      expect(allResults, hasLength(1));
      AnalysisResult result = allResults[0];
      expect(result.path, testFile);
      expect(_getTopLevelVarType(result.unit, 'V'), 'double');
    }
  }

  test_const_annotation_notConstConstructor() async {
    addTestFile('''
class A {
  final int i;
  A(this.i);
}

@A(5)
class C {}
''');
    var result = await driver.getResult(testFile);
    var atD = AstFinder.getClass(result.unit, 'C').metadata[0];
    var atDI = atD.elementAnnotation as ElementAnnotationImpl;
    var value = atDI.evaluationResult.value;
    // That is illegal.
    expect(value, isNull);
  }

  test_const_annotation_withArgs() async {
    addTestFile('''
const x = 1;
@D(x) class C {}
class D {
  const D(this.value);
  final value;
}
''');
    var result = await driver.getResult(testFile);
    var atD = AstFinder.getClass(result.unit, 'C').metadata[0];
    var atDI = atD.elementAnnotation as ElementAnnotationImpl;
    var value = atDI.evaluationResult.value;
    expect(value, isNotNull);
    expect(value.type, isNotNull);
    expect(value.type.name, 'D');
    expect(value.fields.keys, ['value']);
    expect(value.getField('value').toIntValue(), 1);
    expect(atDI.evaluationResult.errors, isEmpty);
  }

  test_const_annotation_withoutArgs() async {
    addTestFile('''
const x = 1;
@x class C {}
''');
    var result = await driver.getResult(testFile);
    Annotation at_x = AstFinder.getClass(result.unit, 'C').metadata[0];
    expect(at_x.elementAnnotation.constantValue.toIntValue(), 1);
  }

  test_const_circular_reference() async {
    addTestFile('''
const x = y + 1;
const y = x + 1;
''');
    var result = await driver.getResult(testFile);
    var x = AstFinder.getTopLevelVariableElement(result.unit, 'x')
        as TopLevelVariableElementImpl;
    _expectCircularityError(x.evaluationResult);
  }

  test_const_dependency_sameUnit() async {
    addTestFile('''
const x = y + 1;
const y = 1;
''');
    var result = await driver.getResult(testFile);
    var x = AstFinder.getTopLevelVariableElement(result.unit, 'x');
    var y = AstFinder.getTopLevelVariableElement(result.unit, 'y');
    expect(x.constantValue.toIntValue(), 2);
    expect(y.constantValue.toIntValue(), 1);
  }

  test_const_externalConstFactory() async {
    addTestFile('''
const x = const C.foo();

class C extends B {
  external const factory C.foo();
}

class B {}
''');
    var result = await driver.getResult(testFile);
    var x = AstFinder.getTopLevelVariableElement(result.unit, 'x');
    expect(x.constantValue, isNotNull);
  }

  test_const_implicitSuperConstructorInvocation() async {
    addTestFile('''
class Base {}
class Derived extends Base {
  const Derived();
}
const x = const Derived();
''');
    var result = await driver.getResult(testFile);
    var x = AstFinder.getTopLevelVariableElement(result.unit, 'x');
    expect(x.constantValue, isNotNull);
  }

  test_const_simple_topLevelVariable() async {
    addTestFile('''
const x = 1;
''');
    var result = await driver.getResult(testFile);
    var x = AstFinder.getTopLevelVariableElement(result.unit, 'x');
    expect(x.constantValue.toIntValue(), 1);
  }

  test_errors_uriDoesNotExist_export() async {
    addTestFile(r'''
export 'foo.dart';
''');

    AnalysisResult result = await driver.getResult(testFile);
    List<AnalysisError> errors = result.errors;
    expect(errors, hasLength(1));
    expect(errors[0].errorCode, CompileTimeErrorCode.URI_DOES_NOT_EXIST);
  }

  test_errors_uriDoesNotExist_import() async {
    addTestFile(r'''
import 'foo.dart';
''');

    AnalysisResult result = await driver.getResult(testFile);
    List<AnalysisError> errors = result.errors;
    expect(errors, hasLength(1));
    expect(errors[0].errorCode, CompileTimeErrorCode.URI_DOES_NOT_EXIST);
  }

  test_errors_uriDoesNotExist_import_deferred() async {
    addTestFile(r'''
import 'foo.dart' deferred as foo;
main() {
  foo.loadLibrary();
}
''', priority: true);

    AnalysisResult result = await driver.getResult(testFile);
    List<AnalysisError> errors = result.errors;
    expect(errors, hasLength(1));
    expect(errors[0].errorCode, CompileTimeErrorCode.URI_DOES_NOT_EXIST);
  }

  test_errors_uriDoesNotExist_part() async {
    addTestFile(r'''
library lib;
part 'foo.dart';
''');

    AnalysisResult result = await driver.getResult(testFile);
    List<AnalysisError> errors = result.errors;
    expect(errors, hasLength(1));
    expect(errors[0].errorCode, CompileTimeErrorCode.URI_DOES_NOT_EXIST);
  }

  test_externalSummaries() async {
    var a = _p('/a.dart');
    var b = _p('/b.dart');
    provider.newFile(a, r'''
class A {}
''');
    provider.newFile(b, r'''
import 'a.dart';
var a = new A();
''');

    // Prepare the store with a.dart and everything it needs.
    SummaryDataStore summaryStore =
        await createAnalysisDriver().test.getSummaryStore(a);

    // There are at least a.dart and dart:core libraries.
    String aUri = provider.pathContext.toUri(a).toString();
    expect(summaryStore.unlinkedMap.keys, contains(aUri));
    expect(summaryStore.linkedMap.keys, contains(aUri));
    expect(summaryStore.unlinkedMap.keys, contains('dart:core'));
    expect(summaryStore.linkedMap.keys, contains('dart:core'));

    // Remove a.dart from the file system.
    provider.deleteFile(a);

    // We don't need a.dart file when we analyze with the summary store.
    // Still no analysis errors.
    AnalysisDriver driver =
        createAnalysisDriver(externalSummaries: summaryStore);
    AnalysisResult result = await driver.getResult(b);
    expect(result.errors, isEmpty);
  }

  test_generatedFile() async {
    Uri uri = Uri.parse('package:aaa/foo.dart');
    String templatePath = _p('/aaa/lib/foo.dart');
    String generatedPath = _p('/generated/aaa/lib/foo.dart');

    provider.newFile(templatePath, r'''
a() {}
b() {}
''');

    provider.newFile(generatedPath, r'''
aaa() {}
bbb() {}
''');

    Source generatedSource = new _SourceMock();
    when(generatedSource.uri).thenReturn(uri);
    when(generatedSource.fullName).thenReturn(generatedPath);

    when(generatedUriResolver.resolveAbsolute(uri, uri))
        .thenReturn(generatedSource);
    when(generatedUriResolver.restoreAbsolute(any))
        .thenAnswer((Invocation invocation) {
      Source source = invocation.positionalArguments[0];
      String path = source.fullName;
      if (path == templatePath || path == generatedPath) {
        return uri;
      } else {
        return null;
      }
    });

    driver.addFile(templatePath);

    await waitForIdleWithoutExceptions();
    expect(allExceptions, isEmpty);
    expect(allResults, isEmpty);

    var result = await driver.getResult(templatePath);
    expect(result, isNull);
    expect(allExceptions, isEmpty);
    expect(allResults, isEmpty);

    var element = await driver.getUnitElement(templatePath);
    expect(element, isNull);
    expect(allExceptions, isEmpty);
    expect(allResults, isEmpty);

    driver.priorityFiles = [templatePath];
    driver.changeFile(templatePath);
    await waitForIdleWithoutExceptions();
    expect(allExceptions, isEmpty);
    expect(allResults, isEmpty);

    expect(driver.knownFiles, isNot(contains(templatePath)));
  }

  test_getCachedResult() async {
    var a = _p('/test/bin/a.dart');
    provider.newFile(a, 'var a = 1;');

    expect(driver.getCachedResult(a), isNull);

    driver.priorityFiles = [a];
    AnalysisResult result = await driver.getResult(a);

    expect(driver.getCachedResult(a), same(result));
  }

  test_getErrors() async {
    String content = 'int f() => 42 + bar();';
    addTestFile(content, priority: true);

    ErrorsResult result = await driver.getErrors(testFile);
    expect(result.path, testFile);
    expect(result.uri.toString(), 'package:test/test.dart');
    expect(result.errors, hasLength(1));
  }

  test_getErrors_notAbsolutePath() async {
    try {
      await driver.getErrors('not_absolute.dart');
      fail('ArgumentError expected.');
    } on ArgumentError {}
  }

  test_getFilesDefiningClassMemberName() async {
    var a = _p('/test/bin/a.dart');
    var b = _p('/test/bin/b.dart');
    var c = _p('/test/bin/c.dart');
    var d = _p('/test/bin/d.dart');

    provider.newFile(a, 'class A { m1() {} }');
    provider.newFile(b, 'class B { m2() {} }');
    provider.newFile(c, 'class C { m2() {} }');
    provider.newFile(d, 'class D { m3() {} }');

    driver.addFile(a);
    driver.addFile(b);
    driver.addFile(c);
    driver.addFile(d);

    expect(await driver.getFilesDefiningClassMemberName('m1'),
        unorderedEquals([a]));

    expect(await driver.getFilesDefiningClassMemberName('m2'),
        unorderedEquals([b, c]));

    expect(await driver.getFilesDefiningClassMemberName('m3'),
        unorderedEquals([d]));
  }

  test_getFilesReferencingName() async {
    var a = _p('/test/bin/a.dart');
    var b = _p('/test/bin/b.dart');
    var c = _p('/test/bin/c.dart');
    var d = _p('/test/bin/d.dart');
    var e = _p('/test/bin/e.dart');

    provider.newFile(a, 'class A {}');
    provider.newFile(b, "import 'a.dart'; A a;");
    provider.newFile(c, "import 'a.dart'; var a = new A();");
    provider.newFile(d, "class A{} A a;");
    provider.newFile(e, "import 'a.dart'; main() {}");

    driver.addFile(a);
    driver.addFile(b);
    driver.addFile(c);
    driver.addFile(d);
    driver.addFile(e);

    // 'b.dart' references an external 'A'.
    // 'c.dart' references an external 'A'.
    // 'd.dart' references the local 'A'.
    // 'e.dart' does not reference 'A' at all.
    List<String> files = await driver.getFilesReferencingName('A');
    expect(files, unorderedEquals([b, c]));

    // We get the same results second time.
    List<String> files2 = await driver.getFilesReferencingName('A');
    expect(files2, unorderedEquals([b, c]));
  }

  test_getIndex() async {
    String content = r'''
foo(int p) {}
main() {
  foo(42);
}
''';
    addTestFile(content);

    AnalysisDriverUnitIndex index = await driver.getIndex(testFile);

    int unitId = index.strings.indexOf('package:test/test.dart');
    int fooId = index.strings.indexOf('foo');
    expect(unitId, isNonNegative);
    expect(fooId, isNonNegative);
  }

  test_getIndex_notAbsolutePath() async {
    try {
      await driver.getIndex('not_absolute.dart');
      fail('ArgumentError expected.');
    } on ArgumentError {}
  }

  test_getLibraryByUri_external_resynthesize() async {
    provider.newFile(testFile, r'''
class Test {}
''');

    // Prepare the store with package:test/test.dart URI.
    SummaryDataStore summaryStore =
        await createAnalysisDriver().test.getSummaryStore(testFile);

    // package:test/test.dart is in the store.
    String uri = 'package:test/test.dart';
    expect(summaryStore.unlinkedMap.keys, contains(uri));
    expect(summaryStore.linkedMap.keys, contains(uri));

    // Remove the file from the file system.
    provider.deleteFile(testFile);

    // We can resynthesize the library from the store without reading the file.
    AnalysisDriver driver =
        createAnalysisDriver(externalSummaries: summaryStore);
    expect(driver.test.numOfCreatedLibraryContexts, 0);
    LibraryElement library = await driver.getLibraryByUri(uri);
    expect(library.getType('Test'), isNotNull);
  }

  test_getLibraryByUri_sdk_analyze() async {
    LibraryElement coreLibrary = await driver.getLibraryByUri('dart:core');
    expect(coreLibrary, isNotNull);
    expect(coreLibrary.getType('Object'), isNotNull);
    expect(coreLibrary.getType('int'), isNotNull);
  }

  test_getLibraryByUri_sdk_resynthesize() async {
    SummaryDataStore sdkStore;
    {
      String corePath = sdk.mapDartUri('dart:core').fullName;
      sdkStore = await createAnalysisDriver().test.getSummaryStore(corePath);
    }

    // There are dart:core and dart:async in the store.
    expect(sdkStore.unlinkedMap.keys, contains('dart:core'));
    expect(sdkStore.unlinkedMap.keys, contains('dart:async'));
    expect(sdkStore.linkedMap.keys, contains('dart:core'));
    expect(sdkStore.linkedMap.keys, contains('dart:async'));

    // We don't create new library context (so, don't parse, summarize and
    // link) for dart:core. The library is resynthesized from the provided
    // external store.
    AnalysisDriver driver = createAnalysisDriver(externalSummaries: sdkStore);
    LibraryElement coreLibrary = await driver.getLibraryByUri('dart:core');
    expect(driver.test.numOfCreatedLibraryContexts, 0);
    expect(coreLibrary, isNotNull);
    expect(coreLibrary.getType('Object'), isNotNull);
  }

  test_getResult() async {
    String content = 'int f() => 42;';
    addTestFile(content, priority: true);

    AnalysisResult result = await driver.getResult(testFile);
    expect(result.path, testFile);
    expect(result.uri.toString(), 'package:test/test.dart');
    expect(result.exists, isTrue);
    expect(result.content, content);
    expect(result.unit, isNotNull);
    expect(result.errors, hasLength(0));

    var f = result.unit.declarations[0] as FunctionDeclaration;
    expect(f.name.staticType.toString(), '() → int');
    expect(f.returnType.type.toString(), 'int');

    // The same result is also received through the stream.
    await waitForIdleWithoutExceptions();
    expect(allResults, [result]);
  }

  test_getResult_constants_defaultParameterValue_localFunction() async {
    var a = _p('/test/bin/a.dart');
    var b = _p('/test/bin/b.dart');
    provider.newFile(a, 'const C = 42;');
    provider.newFile(b, r'''
import 'a.dart';
main() {
  foo({int p: C}) {}
  foo();
}
''');
    driver.addFile(a);
    driver.addFile(b);
    await waitForIdleWithoutExceptions();

    AnalysisResult result = await driver.getResult(b);
    expect(result.errors, isEmpty);
  }

  test_getResult_doesNotExist() async {
    var a = _p('/test/lib/a.dart');

    AnalysisResult result = await driver.getResult(a);
    expect(result.path, a);
    expect(result.uri.toString(), 'package:test/a.dart');
    expect(result.exists, isFalse);
    expect(result.content, '');
  }

  test_getResult_errors() async {
    String content = 'main() { int vv; }';
    addTestFile(content, priority: true);

    AnalysisResult result = await driver.getResult(testFile);
    expect(result.path, testFile);
    expect(result.errors, hasLength(1));
    {
      AnalysisError error = result.errors[0];
      expect(error.offset, 13);
      expect(error.length, 2);
      expect(error.errorCode, HintCode.UNUSED_LOCAL_VARIABLE);
      expect(error.message, "The value of the local variable 'vv' isn't used.");
      expect(error.correction, "Try removing the variable, or using it.");
    }
  }

  test_getResult_fileContentOverlay_throughAnalysisContext() async {
    var a = _p('/test/bin/a.dart');
    var b = _p('/test/bin/b.dart');

    provider.newFile(a, 'import "b.dart";');
    provider.newFile(b, 'var v = 1;');
    contentOverlay[b] = 'var v = 2;';

    var result = await driver.getResult(a);

    // The content that was set into the overlay for "b" should be visible
    // through the AnalysisContext that was used to analyze "a".
    CompilationUnitElement unitA = result.unit.element;
    Source sourceB = unitA.library.imports[0].importedLibrary.source;
    expect(unitA.context.getContents(sourceB).data, 'var v = 2;');
  }

  test_getResult_functionTypeFormalParameter_withTypeParameter() async {
    // This was code crashing because of incomplete implementation.
    // Consider (re)moving after fixing dartbug.com/28515
    addTestFile(r'''
class A {
  int foo( bar<T extends B>() ) {}
}
class B {}
''');

    AnalysisResult result = await driver.getResult(testFile);
    expect(result.path, testFile);
  }

  test_getResult_genericFunctionType_parameter_named() async {
    String content = '''
class C {
  test({bool Function(String) p}) {}
}
''';
    addTestFile(content, priority: true);

    var result = await driver.getResult(testFile);
    expect(result.errors, isEmpty);
  }

  test_getResult_importLibrary_thenRemoveIt() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    provider.newFile(a, 'class A {}');
    provider.newFile(b, r'''
import 'a.dart';
class B extends A {}
''');

    driver.addFile(a);
    driver.addFile(b);
    await waitForIdleWithoutExceptions();

    // No errors in b.dart
    {
      AnalysisResult result = await driver.getResult(b);
      expect(result.errors, isEmpty);
    }

    // Remove a.dart and reanalyze.
    provider.deleteFile(a);
    driver.removeFile(a);

    // The unresolved URI error must be reported.
    {
      AnalysisResult result = await driver.getResult(b);
      expect(
          result.errors,
          contains(predicate((AnalysisError e) =>
              e.errorCode == CompileTimeErrorCode.URI_DOES_NOT_EXIST)));
    }

    // Restore a.dart and reanalyze.
    provider.newFile(a, 'class A {}');
    driver.addFile(a);

    // No errors in b.dart again.
    {
      AnalysisResult result = await driver.getResult(b);
      expect(result.errors, isEmpty);
    }
  }

  test_getResult_inferTypes_finalField() async {
    addTestFile(r'''
class C {
  final f = 42;
}
''', priority: true);
    await waitForIdleWithoutExceptions();

    AnalysisResult result = await driver.getResult(testFile);
    expect(_getClassFieldType(result.unit, 'C', 'f'), 'int');
  }

  test_getResult_inferTypes_instanceMethod() async {
    addTestFile(r'''
class A {
  int m(double p) => 1;
}
class B extends A {
  m(double p) => 2;
}
''', priority: true);
    await waitForIdleWithoutExceptions();

    AnalysisResult result = await driver.getResult(testFile);
    expect(_getClassMethodReturnType(result.unit, 'A', 'm'), 'int');
    expect(_getClassMethodReturnType(result.unit, 'B', 'm'), 'int');
  }

  test_getResult_invalid_annotation_functionAsConstructor() async {
    addTestFile(r'''
fff() {}

@fff()
class C {}
''', priority: true);

    AnalysisResult result = await driver.getResult(testFile);
    ClassDeclaration c = result.unit.declarations[1] as ClassDeclaration;
    Annotation a = c.metadata[0];
    expect(a.name.name, 'fff');
    expect(a.name.staticElement, new isInstanceOf<FunctionElement>());
  }

  test_getResult_invalidUri() async {
    String content = r'''
import '[invalid uri]';
import '[invalid uri]:foo.dart';
import 'package:aaa/a1.dart';
import '[invalid uri]';
import '[invalid uri]:foo.dart';

export '[invalid uri]';
export '[invalid uri]:foo.dart';
export 'package:aaa/a2.dart';
export '[invalid uri]';
export '[invalid uri]:foo.dart';

part '[invalid uri]';
part 'a3.dart';
part '[invalid uri]';
''';
    addTestFile(content);

    AnalysisResult result = await driver.getResult(testFile);
    expect(result.path, testFile);
  }

  test_getResult_invalidUri_exports_dart() async {
    String content = r'''
export 'dart:async';
export 'dart:noSuchLib';
export 'dart:math';
''';
    addTestFile(content, priority: true);

    AnalysisResult result = await driver.getResult(testFile);
    expect(result.path, testFile);
    // Has only exports for valid URIs.
    List<ExportElement> imports = resolutionMap
        .elementDeclaredByCompilationUnit(result.unit)
        .library
        .exports;
    expect(imports.map((import) {
      return import.exportedLibrary?.source?.uri?.toString();
    }), ['dart:async', null, 'dart:math']);
  }

  test_getResult_invalidUri_imports_dart() async {
    String content = r'''
import 'dart:async';
import 'dart:noSuchLib';
import 'dart:math';
''';
    addTestFile(content, priority: true);

    AnalysisResult result = await driver.getResult(testFile);
    expect(result.path, testFile);
    // Has only imports for valid URIs.
    List<ImportElement> imports = resolutionMap
        .elementDeclaredByCompilationUnit(result.unit)
        .library
        .imports;
    expect(imports.map((import) {
      return import.importedLibrary?.source?.uri?.toString();
    }), ['dart:async', null, 'dart:math', 'dart:core']);
  }

  test_getResult_invalidUri_metadata() async {
    String content = r'''
@foo
import '';

@foo
export '';

@foo
part '';
''';
    addTestFile(content);
    await driver.getResult(testFile);
  }

  test_getResult_mix_fileAndPackageUris() async {
    var a = _p('/test/bin/a.dart');
    var b = _p('/test/bin/b.dart');
    var c = _p('/test/lib/c.dart');
    var d = _p('/test/test/d.dart');
    provider.newFile(a, r'''
import 'package:test/c.dart';
int x = y;
''');
    provider.newFile(b, r'''
import '../lib/c.dart';
int x = y;
''');
    provider.newFile(c, r'''
import '../test/d.dart';
var y = z;
''');
    provider.newFile(d, r'''
String z = "string";
''');

    driver.addFile(a);
    driver.addFile(b);
    driver.addFile(c);
    driver.addFile(d);

    // Analysis of my_pkg/bin/a.dart produces no error because
    // file:///my_pkg/bin/a.dart imports package:my_pkg/c.dart, and
    // package:my_pkg/c.dart's import is erroneous, causing y's reference to z
    // to be unresolved (and therefore have type dynamic).
    {
      AnalysisResult result = await driver.getResult(a);
      expect(result.errors, isEmpty);
    }

    // Analysis of my_pkg/bin/b.dart produces the error "A value of type
    // 'String' can't be assigned to a variable of type 'int'", because
    // file:///my_pkg/bin/b.dart imports file:///my_pkg/lib/c.dart, which
    // successfully imports file:///my_pkg/test/d.dart, causing y to have an
    // inferred type of String.
    {
      AnalysisResult result = await driver.getResult(b);
      List<AnalysisError> errors = result.errors;
      expect(errors, hasLength(1));
      expect(errors[0].errorCode, StaticTypeWarningCode.INVALID_ASSIGNMENT);
    }
  }

  test_getResult_nameConflict_local() async {
    String content = r'''
foo([p = V]) {}
V();
var V;
''';
    addTestFile(content);
    await driver.getResult(testFile);
  }

  test_getResult_nameConflict_local_typeInference() async {
    String content = r'''
typedef F();
var F;
F _ff() => null;
var f = _ff(); // the inference must fail
main() {
  f();
}
''';
    addTestFile(content);
    await driver.getResult(testFile);
  }

  test_getResult_notAbsolutePath() async {
    try {
      await driver.getResult('not_absolute.dart');
      fail('ArgumentError expected.');
    } on ArgumentError {}
  }

  test_getResult_notDartFile() async {
    var path = _p('/test/lib/test.txt');
    provider.newFile(path, 'class A {}');

    AnalysisResult result = await driver.getResult(path);
    expect(result, isNotNull);
    expect(result.unit.element.types.map((e) => e.name), ['A']);
  }

  test_getResult_recursiveFlatten() async {
    String content = r'''
import 'dart:async';
class C<T> implements Future<C<T>> {}
''';
    addTestFile(content);
    // Should not throw exceptions.
    await driver.getResult(testFile);
  }

  test_getResult_sameFile_twoUris() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    var c = _p('/test/test/c.dart');
    provider.newFile(a, 'class A<T> {}');
    provider.newFile(b, r'''
import 'a.dart';
var VB = new A<int>();
''');
    provider.newFile(c, r'''
import '../lib/a.dart';
var VC = new A<double>();
''');

    driver.addFile(a);
    driver.addFile(b);
    await waitForIdleWithoutExceptions();

    {
      AnalysisResult result = await driver.getResult(b);
      expect(_getImportSource(result.unit, 0).uri.toString(),
          'package:test/a.dart');
      expect(_getTopLevelVarType(result.unit, 'VB'), 'A<int>');
    }

    {
      AnalysisResult result = await driver.getResult(c);
      expect(_getImportSource(result.unit, 0).uri,
          provider.pathContext.toUri(_p('/test/lib/a.dart')));
      expect(_getTopLevelVarType(result.unit, 'VC'), 'A<double>');
    }
  }

  test_getResult_selfConsistent() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    provider.newFile(a, r'''
import 'b.dart';
var A1 = 1;
var A2 = B1;
''');
    provider.newFile(b, r'''
import 'a.dart';
var B1 = A1;
''');

    driver.addFile(a);
    driver.addFile(b);
    await waitForIdleWithoutExceptions();

    {
      AnalysisResult result = await driver.getResult(a);
      expect(_getTopLevelVarType(result.unit, 'A1'), 'int');
      expect(_getTopLevelVarType(result.unit, 'A2'), 'int');
    }

    // Update "a" so that "A1" is now "double".
    // Get result for "a".
    //
    // We get "double" for "A2", even though "A2" has the type from "b".
    // That's because we check for "a" API signature consistency, and because
    // it has changed, we invalidated the dependency cache, relinked libraries
    // and recomputed types.
    provider.updateFile(a, r'''
import 'b.dart';
var A1 = 1.2;
var A2 = B1;
''');
    driver.changeFile(a);

    {
      AnalysisResult result = await driver.getResult(a);
      expect(_getTopLevelVarType(result.unit, 'A1'), 'double');
      expect(_getTopLevelVarType(result.unit, 'A2'), 'double');
    }
  }

  test_getResult_thenRemove() async {
    addTestFile('main() {}', priority: true);

    Future<AnalysisResult> resultFuture = driver.getResult(testFile);
    driver.removeFile(testFile);

    AnalysisResult result = await resultFuture;
    expect(result, isNotNull);
    expect(result.path, testFile);
    expect(result.unit, isNotNull);
  }

  test_getResult_twoPendingFutures() async {
    String content = 'main() {}';
    addTestFile(content, priority: true);

    Future<AnalysisResult> future1 = driver.getResult(testFile);
    Future<AnalysisResult> future2 = driver.getResult(testFile);

    // Both futures complete, with the same result.
    AnalysisResult result1 = await future1;
    AnalysisResult result2 = await future2;
    expect(result2, same(result1));
    expect(result1.path, testFile);
    expect(result1.unit, isNotNull);
  }

  test_getSourceKind_library() async {
    var path = _p('/test/lib/test.dart');
    provider.newFile(path, 'class A {}');
    expect(await driver.getSourceKind(path), SourceKind.LIBRARY);
  }

  test_getSourceKind_notAbsolutePath() async {
    try {
      await driver.getSourceKind('not_absolute.dart');
      fail('ArgumentError expected.');
    } on ArgumentError {}
  }

  test_getSourceKind_notDartFile() async {
    var path = _p('/test/lib/test.txt');
    provider.newFile(path, 'class A {}');
    expect(await driver.getSourceKind(path), isNull);
  }

  test_getSourceKind_part() async {
    var path = _p('/test/lib/test.dart');
    provider.newFile(path, 'part of lib; class A {}');
    expect(await driver.getSourceKind(path), SourceKind.PART);
  }

  test_getTopLevelNameDeclarations() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    var c = _p('/test/lib/c.dart');
    var d = _p('/test/lib/d.dart');

    provider.newFile(a, 'class A {}');
    provider.newFile(b, 'export "a.dart"; class B {}');
    provider.newFile(c, 'import "d.dart"; class C {}');
    provider.newFile(d, 'class D {}');

    driver.addFile(a);
    driver.addFile(b);
    driver.addFile(c);
    // Don't add d.dart, it is referenced implicitly.

    _assertTopLevelDeclarations(
        await driver.getTopLevelNameDeclarations('A'), [a, b], [false, true]);

    _assertTopLevelDeclarations(
        await driver.getTopLevelNameDeclarations('B'), [b], [false]);

    _assertTopLevelDeclarations(
        await driver.getTopLevelNameDeclarations('C'), [c], [false]);

    _assertTopLevelDeclarations(
        await driver.getTopLevelNameDeclarations('D'), [d], [false]);

    _assertTopLevelDeclarations(
        await driver.getTopLevelNameDeclarations('X'), [], []);
  }

  test_getTopLevelNameDeclarations_parts() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    var c = _p('/test/lib/c.dart');

    provider.newFile(a, r'''
library lib;
part 'b.dart';
part 'c.dart';
class A {}
''');
    provider.newFile(b, 'part of lib; class B {}');
    provider.newFile(c, 'part of lib; class C {}');

    driver.addFile(a);
    driver.addFile(b);
    driver.addFile(c);

    _assertTopLevelDeclarations(
        await driver.getTopLevelNameDeclarations('A'), [a], [false]);

    _assertTopLevelDeclarations(
        await driver.getTopLevelNameDeclarations('B'), [a], [false]);

    _assertTopLevelDeclarations(
        await driver.getTopLevelNameDeclarations('C'), [a], [false]);

    _assertTopLevelDeclarations(
        await driver.getTopLevelNameDeclarations('X'), [], []);
  }

  test_getUnitElement() async {
    String content = r'''
foo(int p) {}
main() {
  foo(42);
}
''';
    addTestFile(content);

    UnitElementResult unitResult = await driver.getUnitElement(testFile);
    expect(unitResult, isNotNull);
    CompilationUnitElement unitElement = unitResult.element;
    expect(unitElement.source.fullName, testFile);
    expect(unitElement.functions.map((c) => c.name),
        unorderedEquals(['foo', 'main']));
  }

  test_getUnitElement_notAbsolutePath() async {
    try {
      await driver.getUnitElement('not_absolute.dart');
      fail('ArgumentError expected.');
    } on ArgumentError {}
  }

  test_getUnitElement_notDart() async {
    var path = _p('/test.txt');
    provider.newFile(path, 'class A {}');
    UnitElementResult unitResult = await driver.getUnitElement(path);
    expect(unitResult, isNotNull);
    expect(unitResult.element.types.map((e) => e.name), ['A']);
  }

  test_getUnitElementSignature() async {
    var a = _p('/test/lib/a.dart');

    provider.newFile(a, 'foo() {}');

    String signature = await driver.getUnitElementSignature(a);
    expect(signature, isNotNull);

    UnitElementResult unitResult = await driver.getUnitElement(a);
    expect(unitResult.path, a);
    expect(unitResult.signature, signature);

    provider.updateFile(a, 'bar() {}');
    driver.changeFile(a);

    String signature2 = await driver.getUnitElementSignature(a);
    expect(signature2, isNotNull);
    expect(signature2, isNot(signature));
  }

  test_hasFilesToAnalyze() async {
    // No files yet, nothing to analyze.
    expect(driver.hasFilesToAnalyze, isFalse);

    // Add a new file, it should be analyzed.
    addTestFile('main() {}', priority: false);
    expect(driver.hasFilesToAnalyze, isTrue);

    // Wait for idle, nothing to do.
    await waitForIdleWithoutExceptions();
    expect(driver.hasFilesToAnalyze, isFalse);

    // Ask to analyze the file, so there is a file to analyze.
    Future<AnalysisResult> future = driver.getResult(testFile);
    expect(driver.hasFilesToAnalyze, isTrue);

    // Once analysis is done, there is nothing to analyze.
    await future;
    expect(driver.hasFilesToAnalyze, isFalse);

    // Change a file, even if not added, it still might affect analysis.
    driver.changeFile(_p('/not/added.dart'));
    expect(driver.hasFilesToAnalyze, isTrue);
    await waitForIdleWithoutExceptions();
    expect(driver.hasFilesToAnalyze, isFalse);

    // Request of referenced names is not analysis of a file.
    driver.getFilesReferencingName('X');
    expect(driver.hasFilesToAnalyze, isFalse);
  }

  test_hermetic_modifyLibraryFile_resolvePart() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');

    provider.newFile(a, r'''
library a;
part 'b.dart';
class C {
  int foo;
}
''');
    provider.newFile(b, r'''
part of a;
var c = new C();
''');

    driver.addFile(a);
    driver.addFile(b);

    await driver.getResult(b);

    // Modify the library, but don't notify the driver.
    // The driver should use the previous library content and elements.
    provider.newFile(a, r'''
library a;
part 'b.dart';
class C {
  int bar;
}
''');

    var result = await driver.getResult(b);
    var c = _getTopLevelVar(result.unit, 'c');
    var typeC = c.element.type as InterfaceType;
    // The class C has an old field 'foo', not the new 'bar'.
    expect(typeC.element.getField('foo'), isNotNull);
    expect(typeC.element.getField('bar'), isNull);
  }

  test_hermetic_overlayOnly_part() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    contentOverlay[a] = r'''
library a;
part 'b.dart';
class A {}
var b = new B();
''';
    contentOverlay[b] = 'part of a; class B {}';

    driver.addFile(a);
    driver.addFile(b);

    AnalysisResult result = await driver.getResult(a);
    expect(result.errors, isEmpty);
    expect(_getTopLevelVarType(result.unit, 'b'), 'B');
  }

  test_knownFiles() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    var c = _p('/test/lib/c.dart');

    provider.newFile(a, r'''
import 'b.dart';
''');
    provider.newFile(b, '');
    provider.newFile(c, '');

    driver.addFile(a);
    driver.addFile(c);
    await waitForIdleWithoutExceptions();

    expect(driver.knownFiles, contains(a));
    expect(driver.knownFiles, contains(b));
    expect(driver.knownFiles, contains(c));

    // Remove a.dart and analyze.
    // Both a.dart and b.dart are not known now.
    driver.removeFile(a);
    await waitForIdleWithoutExceptions();
    expect(driver.knownFiles, isNot(contains(a)));
    expect(driver.knownFiles, isNot(contains(b)));
    expect(driver.knownFiles, contains(c));
  }

  test_knownFiles_beforeAnalysis() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');

    provider.newFile(a, '');

    // 'a.dart' is added, but not processed yet.
    // So, the set of known files is empty yet.
    driver.addFile(a);
    expect(driver.knownFiles, isEmpty);

    // Remove 'a.dart'.
    // It has been no analysis yet, so 'a.dart' is not in the file state, only
    // in 'added' files. So, it disappears when removed.
    driver.removeFile(a);
    expect(driver.knownFiles, isNot(contains(a)));
    expect(driver.knownFiles, isNot(contains(b)));
  }

  test_parseFile_notAbsolutePath() async {
    try {
      await driver.parseFile('not_absolute.dart');
      fail('ArgumentError expected.');
    } on ArgumentError {}
  }

  test_parseFile_notDart() async {
    var p = _p('/test/bin/a.txt');
    provider.newFile(p, 'class A {}');

    ParseResult parseResult = await driver.parseFile(p);
    expect(parseResult, isNotNull);
    expect(driver.knownFiles, contains(p));
  }

  test_parseFile_shouldRefresh() async {
    var p = _p('/test/bin/a.dart');

    provider.newFile(p, 'class A {}');
    driver.addFile(p);

    // Get the result, so force the file reading.
    await driver.getResult(p);

    // Update the file.
    provider.newFile(p, 'class A2 {}');

    ParseResult parseResult = await driver.parseFile(p);
    var clazz = parseResult.unit.declarations[0] as ClassDeclaration;
    expect(clazz.name.name, 'A2');
  }

  test_part_getErrors_afterLibrary() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    var c = _p('/test/lib/c.dart');
    provider.newFile(a, r'''
library a;
import 'b.dart';
part 'c.dart';
class A {}
var c = new C();
''');
    provider.newFile(b, 'class B {}');
    provider.newFile(c, r'''
part of a;
class C {}
var a = new A();
var b = new B();
''');

    driver.addFile(a);
    driver.addFile(b);
    driver.addFile(c);

    // Process a.dart so that we know that it's a library for c.dart later.
    {
      ErrorsResult result = await driver.getErrors(a);
      expect(result.errors, isEmpty);
    }

    // c.dart does not have errors in the context of a.dart
    {
      ErrorsResult result = await driver.getErrors(c);
      expect(result.errors, isEmpty);
    }
  }

  test_part_getErrors_beforeLibrary() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    var c = _p('/test/lib/c.dart');
    provider.newFile(a, r'''
library a;
import 'b.dart';
part 'c.dart';
class A {}
var c = new C();
''');
    provider.newFile(b, 'class B {}');
    provider.newFile(c, r'''
part of a;
class C {}
var a = new A();
var b = new B();
''');

    driver.addFile(a);
    driver.addFile(b);
    driver.addFile(c);

    // c.dart is resolve in the context of a.dart, so have no errors
    {
      ErrorsResult result = await driver.getErrors(c);
      expect(result.errors, isEmpty);
    }
  }

  test_part_getResult_afterLibrary() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    var c = _p('/test/lib/c.dart');
    provider.newFile(a, r'''
library a;
import 'b.dart';
part 'c.dart';
class A {}
var c = new C();
''');
    provider.newFile(b, 'class B {}');
    provider.newFile(c, r'''
part of a;
class C {}
var a = new A();
var b = new B();
''');

    driver.addFile(a);
    driver.addFile(b);
    driver.addFile(c);

    // Process a.dart so that we know that it's a library for c.dart later.
    {
      AnalysisResult result = await driver.getResult(a);
      expect(result.errors, isEmpty);
      expect(_getTopLevelVarType(result.unit, 'c'), 'C');
    }

    // Now c.dart can be resolved without errors in the context of a.dart
    {
      AnalysisResult result = await driver.getResult(c);
      expect(result.errors, isEmpty);
      expect(_getTopLevelVarType(result.unit, 'a'), 'A');
      expect(_getTopLevelVarType(result.unit, 'b'), 'B');
    }
  }

  test_part_getResult_beforeLibrary() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    var c = _p('/test/lib/c.dart');
    provider.newFile(a, r'''
library a;
import 'b.dart';
part 'c.dart';
class A {}
var c = new C();
''');
    provider.newFile(b, 'class B {}');
    provider.newFile(c, r'''
part of a;
class C {}
var a = new A();
var b = new B();
''');

    driver.addFile(a);
    driver.addFile(b);
    driver.addFile(c);

    // b.dart will be analyzed after a.dart is analyzed.
    // So, A and B references are resolved.
    AnalysisResult result = await driver.getResult(c);
    expect(result.errors, isEmpty);
    expect(_getTopLevelVarType(result.unit, 'a'), 'A');
    expect(_getTopLevelVarType(result.unit, 'b'), 'B');
  }

  test_part_getResult_noLibrary() async {
    var c = _p('/test/lib/c.dart');
    provider.newFile(c, r'''
part of a;
class C {}
var a = new A();
var b = new B();
''');

    driver.addFile(c);

    // There is no library which c.dart is a part of, so it has unresolved
    // A and B references.
    AnalysisResult result = await driver.getResult(c);
    expect(result.errors, isNotEmpty);
    expect(result.unit, isNotNull);
  }

  test_part_getUnitElement_afterLibrary() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    var c = _p('/test/lib/c.dart');
    provider.newFile(a, r'''
library a;
import 'b.dart';
part 'c.dart';
class A {}
var c = new C();
''');
    provider.newFile(b, 'class B {}');
    provider.newFile(c, r'''
part of a;
class C {}
var a = new A();
var b = new B();
''');

    driver.addFile(a);
    driver.addFile(b);
    driver.addFile(c);

    // Process a.dart so that we know that it's a library for c.dart later.
    await driver.getResult(a);

    // c.dart is resolve in the context of a.dart, knows 'A' and 'B'.
    {
      UnitElementResult result = await driver.getUnitElement(c);
      var partUnit = result.element;

      expect(partUnit.topLevelVariables[0].type.name, 'A');
      expect(partUnit.topLevelVariables[1].type.name, 'B');

      var libraryUnit = partUnit.library.definingCompilationUnit;
      expect(libraryUnit.topLevelVariables[0].type.name, 'C');
    }
  }

  test_part_getUnitElement_beforeLibrary() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    var c = _p('/test/lib/c.dart');
    provider.newFile(a, r'''
library a;
import 'b.dart';
part 'c.dart';
class A {}
var c = new C();
''');
    provider.newFile(b, 'class B {}');
    provider.newFile(c, r'''
part of a;
class C {}
var a = new A();
var b = new B();
''');

    driver.addFile(a);
    driver.addFile(b);
    driver.addFile(c);

    // c.dart is resolve in the context of a.dart, knows 'A' and 'B'.
    {
      UnitElementResult result = await driver.getUnitElement(c);
      var partUnit = result.element;

      expect(partUnit.topLevelVariables[0].type.name, 'A');
      expect(partUnit.topLevelVariables[1].type.name, 'B');

      var libraryUnit = partUnit.library.definingCompilationUnit;
      expect(libraryUnit.topLevelVariables[0].type.name, 'C');
    }
  }

  test_part_getUnitElement_noLibrary() async {
    var c = _p('/test/lib/c.dart');
    provider.newFile(c, r'''
part of a;
var a = new A();
var b = new B();
''');

    driver.addFile(c);

    // We don't know the library of c.dart, but we should get a result.
    // The types "A" and "B" are unresolved.
    {
      UnitElementResult result = await driver.getUnitElement(c);
      var partUnit = result.element;

      expect(partUnit.topLevelVariables[0].name, 'a');
      expect(partUnit.topLevelVariables[0].type.name, 'dynamic');

      expect(partUnit.topLevelVariables[1].name, 'b');
      expect(partUnit.topLevelVariables[1].type.name, 'dynamic');
    }
  }

  test_part_getUnitElementSignature() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    var c = _p('/test/lib/c.dart');
    provider.newFile(a, r'''
library a;
import 'b.dart';
part 'c.dart';
class A {}
var c = new C();
''');
    provider.newFile(b, 'class B {}');
    provider.newFile(c, r'''
part of a;
class C {}
var a = new A();
var b = new B();
''');

    driver.addFile(a);
    driver.addFile(b);
    driver.addFile(c);

    // Compute the signature before analyzing the library.
    String signatureBefore = await driver.getUnitElementSignature(c);

    // Process a.dart so that we know that it's a library for c.dart later.
    await driver.getResult(a);

    // The before and after signatures must be the same.
    String signatureAfter = await driver.getUnitElementSignature(c);
    expect(signatureBefore, signatureAfter);
  }

  test_part_results_afterLibrary() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    var c = _p('/test/lib/c.dart');
    provider.newFile(a, r'''
library a;
import 'b.dart';
part 'c.dart';
class A {}
var c = new C();
''');
    provider.newFile(b, 'class B {}');
    provider.newFile(c, r'''
part of a;
class C {}
var a = new A();
var b = new B();
''');

    // The order is important for creating the test case.
    driver.addFile(a);
    driver.addFile(b);
    driver.addFile(c);

    {
      await waitForIdleWithoutExceptions();

      // c.dart was added after a.dart, so it is analyzed after a.dart,
      // so we know that a.dart is the library of c.dart, so no errors.
      AnalysisResult result = allResults.lastWhere((r) => r.path == c);
      expect(result.errors, isEmpty);
      expect(result.unit, isNull);
    }

    // Update a.dart so that c.dart is not a part.
    {
      provider.updateFile(a, '// does not use c.dart anymore');
      driver.changeFile(a);
      await waitForIdleWithoutExceptions();

      // Now c.dart does not have a library context, so A and B cannot be
      // resolved, so there are errors.
      AnalysisResult result = allResults.lastWhere((r) => r.path == c);
      expect(result.errors, isNotEmpty);
      expect(result.unit, isNull);
    }
  }

  test_part_results_beforeLibrary() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    var c = _p('/test/lib/c.dart');
    provider.newFile(a, r'''
library a;
import 'b.dart';
part 'c.dart';
class A {}
var c = new C();
''');
    provider.newFile(b, 'class B {}');
    provider.newFile(c, r'''
part of a;
class C {}
var a = new A();
var b = new B();
''');

    // The order is important for creating the test case.
    driver.addFile(c);
    driver.addFile(a);
    driver.addFile(b);

    await waitForIdleWithoutExceptions();

    // c.dart was added before a.dart, so we attempt to analyze it before
    // a.dart, but we cannot find the library for it, so we delay analysis
    // until all other files are analyzed, including a.dart, after which we
    // analyze the delayed parts.
    AnalysisResult result = allResults.lastWhere((r) => r.path == c);
    expect(result.errors, isEmpty);
    expect(result.unit, isNull);
  }

  test_part_results_noLibrary() async {
    var c = _p('/test/lib/c.dart');
    provider.newFile(c, r'''
part of a;
class C {}
var a = new A();
var b = new B();
''');

    driver.addFile(c);

    await waitForIdleWithoutExceptions();

    // There is no library which c.dart is a part of, so it has unresolved
    // A and B references.
    AnalysisResult result = allResults.lastWhere((r) => r.path == c);
    expect(result.errors, isNotEmpty);
    expect(result.unit, isNull);
  }

  test_part_results_priority_beforeLibrary() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    var c = _p('/test/lib/c.dart');
    provider.newFile(a, r'''
library a;
import 'b.dart';
part 'c.dart';
class A {}
var c = new C();
''');
    provider.newFile(b, 'class B {}');
    provider.newFile(c, r'''
part of a;
class C {}
var a = new A();
var b = new B();
''');

    // The order is important for creating the test case.
    driver.priorityFiles = [c];
    driver.addFile(c);
    driver.addFile(a);
    driver.addFile(b);

    await waitForIdleWithoutExceptions();

    // c.dart was added before a.dart, so we attempt to analyze it before
    // a.dart, but we cannot find the library for it, so we delay analysis
    // until all other files are analyzed, including a.dart, after which we
    // analyze the delayed parts.
    AnalysisResult result = allResults.lastWhere((r) => r.path == c);
    expect(result.errors, isEmpty);
    expect(result.unit, isNotNull);
  }

  test_removeFile_changeFile_implicitlyAnalyzed() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    provider.newFile(a, r'''
import 'b.dart';
var A = B;
''');
    provider.newFile(b, 'var B = 1;');

    driver.priorityFiles = [a, b];
    driver.addFile(a);
    driver.addFile(b);

    // We have results for both "a" and "b".
    await waitForIdleWithoutExceptions();
    expect(allResults, hasLength(2));
    {
      AnalysisResult ar = allResults.firstWhere((r) => r.path == a);
      expect(_getTopLevelVarType(ar.unit, 'A'), 'int');
    }
    {
      AnalysisResult br = allResults.firstWhere((r) => r.path == b);
      expect(_getTopLevelVarType(br.unit, 'B'), 'int');
    }
    allResults.clear();

    // Remove "b" and send the change notification.
    provider.updateFile(b, 'var B = 1.2;');
    driver.removeFile(b);
    driver.changeFile(b);

    // While "b" is not analyzed explicitly, it is analyzed implicitly.
    // We don't get a result for "b".
    // But the change causes "a" to be reanalyzed.
    await waitForIdleWithoutExceptions();
    expect(allResults, hasLength(1));
    {
      AnalysisResult ar = allResults.firstWhere((r) => r.path == a);
      expect(_getTopLevelVarType(ar.unit, 'A'), 'double');
    }
  }

  test_removeFile_changeFile_notAnalyzed() async {
    addTestFile('main() {}');

    // We have a result.
    await waitForIdleWithoutExceptions();
    expect(allResults, hasLength(1));
    expect(allResults[0].path, testFile);
    allResults.clear();

    // Remove the file and send the change notification.
    // The change notification does nothing, because the file is explicitly
    // or implicitly analyzed.
    driver.removeFile(testFile);
    driver.changeFile(testFile);

    await waitForIdleWithoutExceptions();
    expect(allResults, isEmpty);
  }

  test_removeFile_invalidate_importers() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');

    provider.newFile(a, 'class A {}');
    provider.newFile(b, "import 'a.dart';  var a = new A();");

    driver.addFile(a);
    driver.addFile(b);
    await waitForIdleWithoutExceptions();

    // b.dart s clean.
    expect(allResults.singleWhere((r) => r.path == b).errors, isEmpty);
    allResults.clear();

    // Remove a.dart, now b.dart should be reanalyzed and has an error.
    provider.deleteFile(a);
    driver.removeFile(a);
    await waitForIdleWithoutExceptions();
    expect(allResults.singleWhere((r) => r.path == b).errors, hasLength(2));
    allResults.clear();
  }

  test_removeFile_notAbsolutePath() async {
    try {
      driver.removeFile('not_absolute.dart');
      fail('ArgumentError expected.');
    } on ArgumentError {}
  }

  test_results_order() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    var c = _p('/test/lib/c.dart');
    var d = _p('/test/lib/d.dart');
    var e = _p('/test/lib/e.dart');
    var f = _p('/test/lib/f.dart');
    provider.newFile(a, r'''
import 'd.dart';
''');
    provider.newFile(b, '');
    provider.newFile(c, r'''
import 'd.dart';
''');
    provider.newFile(d, r'''
import 'b.dart';
''');
    provider.newFile(e, r'''
export 'b.dart';
''');
    provider.newFile(f, r'''
import 'e.dart';
class F extends X {}
''');

    driver.addFile(a);
    driver.addFile(b);
    driver.addFile(c);
    driver.addFile(d);
    driver.addFile(e);
    driver.addFile(f);
    await waitForIdleWithoutExceptions();

    // The file f.dart has an error or warning.
    // So, its analysis will have higher priority.
    expect(driver.fsState.getFileForPath(f).hasErrorOrWarning, isTrue);

    allResults.clear();

    // Update a.dart with changing its API signature.
    provider.updateFile(b, 'class A {}');
    driver.changeFile(b);
    await waitForIdleWithoutExceptions();

    List<String> analyzedPaths = allResults.map((r) => r.path).toList();

    // The changed file must be the first.
    expect(analyzedPaths[0], b);

    // Then the file that imports the changed file.
    expect(analyzedPaths[1], d);

    // Then the file that has an error (even if it is unrelated).
    expect(analyzedPaths[2], f);
  }

  test_results_order_allChangedFirst_thenImports() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    var c = _p('/test/lib/c.dart');
    var d = _p('/test/lib/d.dart');
    var e = _p('/test/lib/e.dart');
    provider.newFile(a, 'class A {}');
    provider.newFile(b, 'class B {}');
    provider.newFile(c, '');
    provider.newFile(d, "import 'a.dart';");
    provider.newFile(e, "import 'b.dart';");

    driver.addFile(a);
    driver.addFile(b);
    driver.addFile(c);
    driver.addFile(d);
    driver.addFile(e);
    await waitForIdleWithoutExceptions();

    allResults.clear();

    // Change b.dart and then a.dart files.
    // So, a.dart and b.dart should be analyzed first.
    // Then d.dart and e.dart because they import a.dart and b.dart files.
    provider.updateFile(a, 'class A2 {}');
    provider.updateFile(b, 'class B2 {}');
    driver.changeFile(b);
    driver.changeFile(a);
    await waitForIdleWithoutExceptions();

    List<String> analyzedPaths = allResults.map((r) => r.path).toList();

    // The changed files must be the first.
    expect(analyzedPaths[0], a);
    expect(analyzedPaths[1], b);

    // Then the file that imports the changed file.
    expect(analyzedPaths[2], d);
    expect(analyzedPaths[3], e);
  }

  test_results_priority() async {
    String content = 'int f() => 42;';
    addTestFile(content, priority: true);

    await waitForIdleWithoutExceptions();

    expect(allResults, hasLength(1));
    AnalysisResult result = allResults.single;
    expect(result.path, testFile);
    expect(result.uri.toString(), 'package:test/test.dart');
    expect(result.content, content);
    expect(result.unit, isNotNull);
    expect(result.errors, hasLength(0));

    var f = result.unit.declarations[0] as FunctionDeclaration;
    expect(f.name.staticType.toString(), '() → int');
    expect(f.returnType.type.toString(), 'int');
  }

  test_results_priorityFirst() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    var c = _p('/test/lib/c.dart');
    provider.newFile(a, 'class A {}');
    provider.newFile(b, 'class B {}');
    provider.newFile(c, 'class C {}');

    driver.addFile(a);
    driver.addFile(b);
    driver.addFile(c);
    driver.priorityFiles = [b];
    await waitForIdleWithoutExceptions();

    expect(allResults, hasLength(3));
    AnalysisResult result = allResults[0];
    expect(result.path, b);
    expect(result.unit, isNotNull);
    expect(result.errors, hasLength(0));
  }

  test_results_regular() async {
    String content = 'int f() => 42;';
    addTestFile(content);
    await waitForIdleWithoutExceptions();

    expect(allResults, hasLength(1));
    AnalysisResult result = allResults.single;
    expect(result.path, testFile);
    expect(result.uri.toString(), 'package:test/test.dart');
    expect(result.content, isNull);
    expect(result.unit, isNull);
    expect(result.errors, hasLength(0));
  }

  test_results_skipNotAffected() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    provider.newFile(a, 'class A {}');
    provider.newFile(b, 'class B {}');

    driver.addFile(a);
    driver.addFile(b);
    await waitForIdleWithoutExceptions();

    expect(allResults, hasLength(2));
    allResults.clear();

    // Update a.dart and notify.
    provider.updateFile(a, 'class A2 {}');
    driver.changeFile(a);

    // Only result for a.dart should be produced, b.dart is not affected.
    await waitForIdleWithoutExceptions();
    expect(allResults, hasLength(1));
  }

  test_results_status() async {
    addTestFile('int f() => 42;');
    await waitForIdleWithoutExceptions();

    expect(allStatuses, hasLength(2));
    expect(allStatuses[0].isAnalyzing, isTrue);
    expect(allStatuses[0].isIdle, isFalse);
    expect(allStatuses[1].isAnalyzing, isFalse);
    expect(allStatuses[1].isIdle, isTrue);
  }

  test_waitForIdle() async {
    // With no analysis to do, scheduler.waitForIdle should complete immediately.
    await waitForIdleWithoutExceptions();
    // Now schedule some analysis.
    addTestFile('int f() => 42;');
    expect(allResults, isEmpty);
    // scheduler.waitForIdle should wait for the analysis.
    await waitForIdleWithoutExceptions();
    expect(allResults, hasLength(1));
    // Make sure there is no more analysis pending.
    await waitForIdleWithoutExceptions();
    expect(allResults, hasLength(1));
  }

  Future waitForIdleWithoutExceptions() async {
    await scheduler.waitForIdle();

    if (allExceptions.isNotEmpty) {
      var buffer = new StringBuffer();
      for (var exception in allExceptions) {
        buffer.writeln('Path: ${exception.path}');
        buffer.writeln('Exception: ${exception.exception}');
      }
      fail('Unexpected exceptions:\n$buffer');
    }
  }

  void _assertTopLevelDeclarations(
      List<TopLevelDeclarationInSource> declarations,
      List<String> expectedFiles,
      List<bool> expectedIsExported) {
    expect(expectedFiles, hasLength(expectedIsExported.length));
    for (int i = 0; i < expectedFiles.length; i++) {
      expect(declarations,
          contains(predicate((TopLevelDeclarationInSource declaration) {
        return declaration.source.fullName == expectedFiles[i] &&
            declaration.isExported == expectedIsExported[i];
      })));
    }
  }

  void _expectCircularityError(EvaluationResultImpl evaluationResult) {
    expect(evaluationResult, isNotNull);
    expect(evaluationResult.value, isNull);
    expect(evaluationResult.errors, hasLength(1));
    expect(evaluationResult.errors[0].errorCode,
        CompileTimeErrorCode.RECURSIVE_COMPILE_TIME_CONSTANT);
  }

  ClassDeclaration _getClass(CompilationUnit unit, String name) {
    for (CompilationUnitMember declaration in unit.declarations) {
      if (declaration is ClassDeclaration) {
        if (declaration.name.name == name) {
          return declaration;
        }
      }
    }
    fail('Cannot find the class $name in\n$unit');
    return null;
  }

  VariableDeclaration _getClassField(
      CompilationUnit unit, String className, String fieldName) {
    ClassDeclaration classDeclaration = _getClass(unit, className);
    for (ClassMember declaration in classDeclaration.members) {
      if (declaration is FieldDeclaration) {
        for (var field in declaration.fields.variables) {
          if (field.name.name == fieldName) {
            return field;
          }
        }
      }
    }
    fail('Cannot find the field $fieldName in the class $className in\n$unit');
    return null;
  }

  String _getClassFieldType(
      CompilationUnit unit, String className, String fieldName) {
    return resolutionMap
        .elementDeclaredByVariableDeclaration(
            _getClassField(unit, className, fieldName))
        .type
        .toString();
  }

  MethodDeclaration _getClassMethod(
      CompilationUnit unit, String className, String methodName) {
    ClassDeclaration classDeclaration = _getClass(unit, className);
    for (ClassMember declaration in classDeclaration.members) {
      if (declaration is MethodDeclaration &&
          declaration.name.name == methodName) {
        return declaration;
      }
    }
    fail('Cannot find the method $methodName in the class $className in\n'
        '$unit');
    return null;
  }

  String _getClassMethodReturnType(
      CompilationUnit unit, String className, String fieldName) {
    return resolutionMap
        .elementDeclaredByMethodDeclaration(
            _getClassMethod(unit, className, fieldName))
        .type
        .returnType
        .toString();
  }

  ImportElement _getImportElement(CompilationUnit unit, int directiveIndex) {
    var import = unit.directives[directiveIndex] as ImportDirective;
    return import.element as ImportElement;
  }

  Source _getImportSource(CompilationUnit unit, int directiveIndex) {
    return _getImportElement(unit, directiveIndex).importedLibrary.source;
  }

  VariableDeclaration _getTopLevelVar(CompilationUnit unit, String name) {
    for (CompilationUnitMember declaration in unit.declarations) {
      if (declaration is TopLevelVariableDeclaration) {
        for (VariableDeclaration variable in declaration.variables.variables) {
          if (variable.name.name == name) {
            return variable;
          }
        }
      }
    }
    fail('Cannot find the top-level variable $name in\n$unit');
    return null;
  }

  String _getTopLevelVarType(CompilationUnit unit, String name) {
    VariableDeclaration variable = _getTopLevelVar(unit, name);
    return resolutionMap
        .elementDeclaredByVariableDeclaration(variable)
        .type
        .toString();
  }

  /**
   * Return the [provider] specific path for the given Posix [path].
   */
  String _p(String path) => provider.convertPath(path);
}

@reflectiveTest
class CacheAllAnalysisDriverTest extends BaseAnalysisDriverTest {
  bool get disableChangesAndCacheAllResults => true;

  test_addFile() async {
    var a = _p('/test/lib/a.dart');
    var b = _p('/test/lib/b.dart');
    driver.addFile(a);
    driver.addFile(b);
  }

  test_changeFile() async {
    var path = _p('/test.dart');
    expect(() {
      driver.changeFile(path);
    }, throwsStateError);
  }

  test_getResult_libraryUnits() async {
    var lib = _p('/lib.dart');
    var part1 = _p('/part1.dart');
    var part2 = _p('/part2.dart');

    provider.newFile(lib, r'''
library test;
part 'part1.dart';
part 'part2.dart';
''');
    provider.newFile(part1, 'part of test; class A {}');
    provider.newFile(part2, 'part of test; class B {}');

    driver.addFile(lib);
    driver.addFile(part1);
    driver.addFile(part2);

    // No analyzed libraries initially.
    expect(driver.test.numOfAnalyzedLibraries, 0);

    AnalysisResult libResult = await driver.getResult(lib);
    AnalysisResult partResult1 = await driver.getResult(part1);
    AnalysisResult partResult2 = await driver.getResult(part2);

    // Just one library was analyzed, results for parts are cached.
    expect(driver.test.numOfAnalyzedLibraries, 1);

    expect(libResult.path, lib);
    expect(partResult1.path, part1);
    expect(partResult2.path, part2);

    expect(libResult.unit, isNotNull);
    expect(partResult1.unit, isNotNull);
    expect(partResult2.unit, isNotNull);

    // The parts uses the same resynthesized library element.
    var libLibrary = libResult.unit.element.library;
    var partLibrary1 = partResult1.unit.element.library;
    var partLibrary2 = partResult2.unit.element.library;
    expect(partLibrary1, same(libLibrary));
    expect(partLibrary2, same(libLibrary));
  }

  test_getResult_singleFile() async {
    var path = _p('/test.dart');
    provider.newFile(path, 'main() {}');
    driver.addFile(path);

    AnalysisResult result1 = await driver.getResult(path);
    expect(driver.test.numOfAnalyzedLibraries, 1);
    var unit1 = result1.unit;
    var unitElement1 = unit1.element;
    expect(result1.path, path);
    expect(unit1, isNotNull);
    expect(unitElement1, isNotNull);

    AnalysisResult result2 = await driver.getResult(path);
    expect(driver.test.numOfAnalyzedLibraries, 1);
    expect(result2.path, path);
    expect(result2.unit, same(unit1));
    expect(result2.unit.element, same(unitElement1));
  }

  test_removeFile() async {
    var path = _p('/test.dart');
    expect(() {
      driver.removeFile(path);
    }, throwsStateError);
  }

  String _p(String path) => provider.convertPath(path);
}

class _SourceMock extends Mock implements Source {}
