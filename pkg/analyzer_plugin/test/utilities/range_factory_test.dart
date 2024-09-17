// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: camel_case_types

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/abstract_single_unit.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RangeFactory_ArgumentRangeTest);
    defineReflectiveTests(RangeFactory_NodeInListTest);
    defineReflectiveTests(RangeFactoryTest);
  });
}

@reflectiveTest
class RangeFactory_ArgumentRangeTest extends AbstractSingleUnitTest {
  Future<void> test_all_mixed_noTrailingComma() async {
    await resolveTestCode('''
void f() {
  g(0, 1, c: 2);
}
void g(int a, int b, {int? c}) {}
''');
    _assertArgumentRange(0, 2, SourceRange(15, 10), SourceRange(15, 10));
  }

  Future<void> test_all_mixed_trailingComma() async {
    await resolveTestCode('''
void f() {
  g(0, 1, c: 2, );
}
void g(int a, int b, {int? c}) {}
''');
    _assertArgumentRange(0, 2, SourceRange(15, 12), SourceRange(15, 10));
  }

  Future<void> test_all_named_noTrailingComma() async {
    await resolveTestCode('''
void f() {
  g(a: 0, b: 1, c: 2);
}
void g({int? a, int? b, int? c}) {}
''');
    _assertArgumentRange(0, 2, SourceRange(15, 16), SourceRange(15, 16));
  }

  Future<void> test_all_named_trailingComma() async {
    await resolveTestCode('''
void f() {
  g(a: 0, b: 1, c: 2, );
}
void g({int? a, int? b, int? c}) {}
''');
    _assertArgumentRange(0, 2, SourceRange(15, 18), SourceRange(15, 16));
  }

  Future<void> test_all_positional_noTrailingComma() async {
    await resolveTestCode('''
void f() {
  g(0, 1, 2);
}
void g(int a, int b, int c) {}
''');
    _assertArgumentRange(0, 2, SourceRange(15, 7), SourceRange(15, 7));
  }

  Future<void> test_all_positional_trailingComma() async {
    await resolveTestCode('''
void f() {
  g(0, 1, 2, );
}
void g(int a, int b, int c) {}
''');
    _assertArgumentRange(0, 2, SourceRange(15, 9), SourceRange(15, 7));
  }

  Future<void> test_first_noTrailingComma() async {
    await resolveTestCode('''
void f() {
  g(0, 1);
}
void g(int a, int b) {}
''');
    _assertArgumentRange(0, 0, SourceRange(15, 3), SourceRange(15, 1));
  }

  Future<void> test_first_trailingComma() async {
    await resolveTestCode('''
void f() {
  g(0, 1, );
}
void g(int a, int b) {}
''');
    _assertArgumentRange(0, 0, SourceRange(15, 3), SourceRange(15, 1));
  }

  Future<void> test_last_noTrailingComma() async {
    await resolveTestCode('''
void f() {
  g(0, 1);
}
void g(int a, int b) {}
''');
    _assertArgumentRange(1, 1, SourceRange(16, 3), SourceRange(18, 1));
  }

  Future<void> test_last_trailingComma() async {
    await resolveTestCode('''
void f() {
  g(0, 1, );
}
void g(int a, int b) {}
''');
    _assertArgumentRange(1, 1, SourceRange(16, 3), SourceRange(18, 1));
  }

  Future<void> test_middle_noTrailingComma() async {
    await resolveTestCode('''
void f() {
  g(0, 1, 2, 3);
}
void g(int a, int b, int c, int d) {}
''');
    _assertArgumentRange(1, 2, SourceRange(16, 6), SourceRange(18, 4));
  }

  Future<void> test_middle_trailingComma() async {
    await resolveTestCode('''
void f() {
  g(0, 1, 2, 3, );
}
void g(int a, int b, int c, int d) {}
''');
    _assertArgumentRange(1, 2, SourceRange(16, 6), SourceRange(18, 4));
  }

  Future<void> test_only_named() async {
    await resolveTestCode('''
void f() {
  g(a: 0);
}
void g({int? a}) {}
''');
    _assertArgumentRange(0, 0, SourceRange(15, 4), SourceRange(15, 4));
  }

  Future<void> test_only_positional() async {
    await resolveTestCode('''
void f() {
  g(0);
}
void g(int a) {}
''');
    _assertArgumentRange(0, 0, SourceRange(15, 1), SourceRange(15, 1));
  }

  /// Assuming that the test code starts with a function whose block body starts
  /// with a method invocation, compute the range for the arguments in the
  /// invocation's argument list between [lower] and [upper]. Validate that the
  /// range for deletion matches [expectedForDeletion] and that the range not
  /// for deletion matches [expectedNoDeletion].
  void _assertArgumentRange(int lower, int upper,
      SourceRange expectedForDeletion, SourceRange expectedNoDeletion) {
    var f = testUnit.declarations[0] as FunctionDeclaration;
    var body = f.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as ExpressionStatement;
    var invocation = statement.expression as MethodInvocation;
    var argumentList = invocation.argumentList;
    expect(range.argumentRange(argumentList, lower, upper, true),
        expectedForDeletion);
    expect(range.argumentRange(argumentList, lower, upper, false),
        expectedNoDeletion);
  }
}

@reflectiveTest
class RangeFactory_NodeInListTest extends AbstractSingleUnitTest {
  /// Assuming that the test code starts with a function whose block body starts
  /// with a method invocation, return the list of arguments in that invocation.
  NodeList<Expression> get _argumentList {
    var f = testUnit.declarations[0] as FunctionDeclaration;
    var body = f.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as ExpressionStatement;
    var invocation = statement.expression as MethodInvocation;
    return invocation.argumentList.arguments;
  }

  /// Assuming that the test code starts with a class whose default constructor,
  /// return the list of initializers in that constructor.
  NodeList<ConstructorInitializer> get _constructorInitializers {
    var c = testUnit.declarations[0] as ClassDeclaration;
    var constructor = c.members.whereType<ConstructorDeclaration>().single;
    return constructor.initializers;
  }

  Future<void> test_argumentList_first_named() async {
    await resolveTestCode('''
void f() {
  g(a: 1, b: 2);
}
void g({int? a, int? b}) {}
''');
    var list = _argumentList;
    expect(range.nodeInList(list, list[0]), SourceRange(15, 6));
  }

  Future<void> test_argumentList_first_positional() async {
    await resolveTestCode('''
void f() {
  g(1, 2);
}
void g(int a, int b) {}
''');
    var list = _argumentList;
    expect(range.nodeInList(list, list[0]), SourceRange(15, 3));
  }

  Future<void> test_argumentList_last_named() async {
    await resolveTestCode('''
void f() {
  g(a: 1, b: 2);
}
void g({int? a, int? b}) {}
''');
    var list = _argumentList;
    expect(range.nodeInList(list, list[1]), SourceRange(19, 6));
  }

  Future<void> test_argumentList_last_positional() async {
    await resolveTestCode('''
void f() {
  g(1, 2);
}
void g(int a, int b) {}
''');
    var list = _argumentList;
    expect(range.nodeInList(list, list[1]), SourceRange(16, 3));
  }

  Future<void> test_argumentList_middle_named() async {
    await resolveTestCode('''
void f() {
  g(a: 1, b: 2, c: 3);
}
void g({int? a, int? b, int? c}) {}
''');
    var list = _argumentList;
    expect(range.nodeInList(list, list[1]), SourceRange(19, 6));
  }

  Future<void> test_argumentList_middle_positional() async {
    await resolveTestCode('''
void f() {
  g(1, 2, 3);
}
void g(int a, int b, int c) {}
''');
    var list = _argumentList;
    expect(range.nodeInList(list, list[1]), SourceRange(16, 3));
  }

  Future<void> test_argumentList_only_named() async {
    await resolveTestCode('''
void f() {
  g(a: 1);
}
void g({int? a}) {}
''');
    var list = _argumentList;
    expect(range.nodeInList(list, list[0]), SourceRange(15, 4));
  }

  Future<void> test_argumentList_only_named_trailingComma() async {
    await resolveTestCode('''
void f() {
  g(a: 1,);
}
void g({int? a}) {}
''');
    var list = _argumentList;
    expect(range.nodeInList(list, list[0]), SourceRange(15, 5));
  }

  Future<void> test_argumentList_only_positional() async {
    await resolveTestCode('''
void f() {
  g(1);
}
void g(int a) {}
''');
    var list = _argumentList;
    expect(range.nodeInList(list, list[0]), SourceRange(15, 1));
  }

  Future<void> test_argumentList_only_positional_trailingComma() async {
    await resolveTestCode('''
void f() {
  g(1,);
}
void g(int a) {}
''');
    var list = _argumentList;
    expect(range.nodeInList(list, list[0]), SourceRange(15, 2));
  }

  Future<void> test_constructorDeclaration_first() async {
    await resolveTestCode('''
class A {
  int x;
  A() : x = 0;
}
''');
    var list = _constructorInitializers;
    expect(range.nodeInList(list, list[0]), SourceRange(24, 8));
  }

  Future<void> test_constructorDeclaration_last() async {
    await resolveTestCode('''
class A {
  int x, y;
  A() : x = 0, y = 1;
}
''');
    var list = _constructorInitializers;
    expect(range.nodeInList(list, list[1]), SourceRange(35, 7));
  }
}

@reflectiveTest
class RangeFactoryTest extends AbstractSingleUnitTest {
  Future<void> test_deletionRange_first() async {
    await _deletionRange(declarationIndex: 0, '''
class A {}

class B {}
''', expected: '''
class B {}
''');
  }

  Future<void> test_deletionRange_first_comment() async {
    await _deletionRange(declarationIndex: 0, '''
/// for a
class A {}

/// for b
class B {}
''', expected: '''
/// for b
class B {}
''');
  }

  Future<void> test_deletionRange_first_directive() async {
    await _deletionRange(declarationIndex: 0, '''
import 'dart:collection';

class A {}

class B {}
''', expected: '''
import 'dart:collection';

class B {}
''');
  }

  Future<void> test_deletionRange_first_directive_comment() async {
    await _deletionRange(declarationIndex: 0, '''
import 'dart:collection';

/// for a
class A {}

/// for b
class B {}
''', expected: '''
import 'dart:collection';

/// for b
class B {}
''');
  }

  Future<void> test_deletionRange_last() async {
    await _deletionRange(declarationIndex: 1, '''
/// for a
class A {}

class B {}
''', expected: '''
/// for a
class A {}
''');
  }

  Future<void> test_deletionRange_last_before_comment() async {
    await _deletionRange(declarationIndex: 1, '''
/// for a
class A {}

class B {}

// another
''', expected: '''
/// for a
class A {}

// another
''');
  }

  Future<void> test_deletionRange_last_multiLineComment() async {
    await _deletionRange(declarationIndex: 1, '''
/// for a
class A {}

/**
 * for b
 */
class B {}
''', expected: '''
/// for a
class A {}
''');
  }

  Future<void> test_deletionRange_last_singeLineComment() async {
    await _deletionRange(declarationIndex: 1, '''
/// for a
class A {}

/// for b
class B {}
''', expected: '''
/// for a
class A {}
''');
  }

  Future<void> test_deletionRange_middle() async {
    await _deletionRange(declarationIndex: 1, '''
class A {}

class B {}

class C {}
''', expected: '''
class A {}

class C {}
''');
  }

  Future<void> test_deletionRange_middle_comment() async {
    await _deletionRange(declarationIndex: 1, '''
/// for a
class A {}

/// for b
class B {}

/// for c
class C {}
''', expected: '''
/// for a
class A {}

/// for c
class C {}
''');
  }

  Future<void> test_deletionRange_only() async {
    await _deletionRange(declarationIndex: 0, '''
class A {}
''', expected: '''

''');
  }

  Future<void> test_deletionRange_variableDeclaration() async {
    await _deletionRange(declarationIndex: 0, '''
var x = 1;

class B {}
''', expected: '''
class B {}
''');
  }

  Future<void> test_deletionRange_variableDeclaration_comment() async {
    await _deletionRange(declarationIndex: 0, '''
// something
var x = 1;

class B {}
''', expected: '''
class B {}
''');
  }

  Future<void> test_elementName() async {
    await resolveTestCode('class ABC {}');
    var element = findElement.class_('ABC');
    expect(range.elementName(element), SourceRange(6, 3));
  }

  Future<void> test_endEnd() async {
    await resolveTestCode('main() {}');
    var mainFunction = testUnit.declarations[0] as FunctionDeclaration;
    var mainName = mainFunction.name;
    var mainBody = mainFunction.functionExpression.body;
    expect(range.endEnd(mainName, mainBody), SourceRange(4, 5));
  }

  Future<void> test_endLength() async {
    await resolveTestCode('main() {}');
    var mainFunction = testUnit.declarations[0] as FunctionDeclaration;
    var mainName = mainFunction.name;
    expect(range.endLength(mainName, 3), SourceRange(4, 3));
  }

  Future<void> test_endStart() async {
    await resolveTestCode('main() {}');
    var mainFunction = testUnit.declarations[0] as FunctionDeclaration;
    var mainName = mainFunction.name;
    var mainBody = mainFunction.functionExpression.body;
    expect(range.endStart(mainName, mainBody), SourceRange(4, 3));
  }

  Future<void> test_error() async {
    addTestSource('''
class A {}
const class B {}
''');
    var result = await resolveFile(testFile);
    var error = result.errors.single;
    expect(range.error(error), SourceRange(11, 5));
  }

  Future<void> test_node() async {
    await resolveTestCode('main() {}');
    var main = testUnit.declarations[0] as FunctionDeclaration;
    expect(range.node(main), SourceRange(0, 9));
  }

  Future<void> test_nodes() async {
    await resolveTestCode(' main() {}');
    var mainFunction = testUnit.declarations[0] as FunctionDeclaration;
    var mainParameters = mainFunction.functionExpression.parameters!;
    var mainBody = mainFunction.functionExpression.body;
    expect(range.nodes([mainParameters, mainBody]), SourceRange(5, 5));
  }

  Future<void> test_nodes_empty() async {
    await resolveTestCode('main() {}');
    expect(range.nodes([]), SourceRange(0, 0));
  }

  void test_offsetBy() {
    expect(range.offsetBy(SourceRange(7, 3), 2), SourceRange(9, 3));
  }

  Future<void> test_startEnd_nodeNode() async {
    await resolveTestCode(' main() {}');
    var mainFunction = testUnit.declarations[0] as FunctionDeclaration;
    var mainName = mainFunction.name;
    var mainBody = mainFunction.functionExpression.body;
    expect(range.startEnd(mainName, mainBody), SourceRange(1, 9));
  }

  Future<void> test_startLength_node() async {
    await resolveTestCode(' main() {}');
    var mainFunction = testUnit.declarations[0] as FunctionDeclaration;
    var parameters = mainFunction.functionExpression.parameters!;
    expect(range.startLength(parameters, 10), SourceRange(5, 10));
  }

  void test_startOffsetEndOffset() {
    expect(range.startOffsetEndOffset(6, 11), SourceRange(6, 5));
  }

  Future<void> test_startStart_nodeNode() async {
    await resolveTestCode('main() {}');
    var mainFunction = testUnit.declarations[0] as FunctionDeclaration;
    var parameters = mainFunction.functionExpression.parameters!;
    var mainBody = mainFunction.functionExpression.body;
    expect(range.startStart(parameters, mainBody), SourceRange(4, 3));
  }

  Future<void> test_token() async {
    await resolveTestCode(' main() {}');
    var mainFunction = testUnit.declarations[0] as FunctionDeclaration;
    var mainName = mainFunction.name;
    expect(range.token(mainName), SourceRange(1, 4));
  }

  Future<void> _deletionRange(String code,
      {required String expected, required int declarationIndex}) async {
    await resolveTestCode(code);
    var member = testUnit.declarations[declarationIndex];
    var deletionRange = range.deletionRange(member);
    var codeAfterDeletion = code.substring(0, deletionRange.offset) +
        code.substring(deletionRange.end);
    expect(codeAfterDeletion, expected);
  }
}
