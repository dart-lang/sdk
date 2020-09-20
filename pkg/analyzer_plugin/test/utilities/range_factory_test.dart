// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/abstract_single_unit.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RangeFactoryTest);
  });
}

@reflectiveTest
class RangeFactoryTest extends AbstractSingleUnitTest {
  /// Assuming that the test code starts with a function whose block body starts
  /// with a method invocation, return the list of arguments in that invocation.
  NodeList<Expression> get _argumentList {
    var f = testUnit.declarations[0] as FunctionDeclaration;
    var body = f.functionExpression.body as BlockFunctionBody;
    var statement = body.block.statements[0] as ExpressionStatement;
    var invocation = statement.expression as MethodInvocation;
    return invocation.argumentList.arguments;
  }

  Future<void> test_argumentRange_all_mixed_noTrailingComma() async {
    await resolveTestUnit('''
void f() {
  g(0, 1, c: 2);
}
void g(int a, int b, {int c}) {}
''');
    _assertArgumentRange(0, 2, SourceRange(15, 10), SourceRange(15, 10));
  }

  Future<void> test_argumentRange_all_mixed_trailingComma() async {
    await resolveTestUnit('''
void f() {
  g(0, 1, c: 2, );
}
void g(int a, int b, {int c}) {}
''');
    _assertArgumentRange(0, 2, SourceRange(15, 12), SourceRange(15, 10));
  }

  Future<void> test_argumentRange_all_named_noTrailingComma() async {
    await resolveTestUnit('''
void f() {
  g(a: 0, b: 1, c: 2);
}
void g({int a, int b, int c}) {}
''');
    _assertArgumentRange(0, 2, SourceRange(15, 16), SourceRange(15, 16));
  }

  Future<void> test_argumentRange_all_named_trailingComma() async {
    await resolveTestUnit('''
void f() {
  g(a: 0, b: 1, c: 2, );
}
void g({int a, int b, int c}) {}
''');
    _assertArgumentRange(0, 2, SourceRange(15, 18), SourceRange(15, 16));
  }

  Future<void> test_argumentRange_all_positional_noTrailingComma() async {
    await resolveTestUnit('''
void f() {
  g(0, 1, 2);
}
void g(int a, int b, int c) {}
''');
    _assertArgumentRange(0, 2, SourceRange(15, 7), SourceRange(15, 7));
  }

  Future<void> test_argumentRange_all_positional_trailingComma() async {
    await resolveTestUnit('''
void f() {
  g(0, 1, 2, );
}
void g(int a, int b, int c) {}
''');
    _assertArgumentRange(0, 2, SourceRange(15, 9), SourceRange(15, 7));
  }

  Future<void> test_argumentRange_first_noTrailingComma() async {
    await resolveTestUnit('''
void f() {
  g(0, 1);
}
void g(int a, int b) {}
''');
    _assertArgumentRange(0, 0, SourceRange(15, 3), SourceRange(15, 1));
  }

  Future<void> test_argumentRange_first_trailingComma() async {
    await resolveTestUnit('''
void f() {
  g(0, 1, );
}
void g(int a, int b) {}
''');
    _assertArgumentRange(0, 0, SourceRange(15, 3), SourceRange(15, 1));
  }

  Future<void> test_argumentRange_last_noTrailingComma() async {
    await resolveTestUnit('''
void f() {
  g(0, 1);
}
void g(int a, int b) {}
''');
    _assertArgumentRange(1, 1, SourceRange(16, 3), SourceRange(18, 1));
  }

  Future<void> test_argumentRange_last_trailingComma() async {
    await resolveTestUnit('''
void f() {
  g(0, 1, );
}
void g(int a, int b) {}
''');
    _assertArgumentRange(1, 1, SourceRange(16, 3), SourceRange(18, 1));
  }

  Future<void> test_argumentRange_middle_noTrailingComma() async {
    await resolveTestUnit('''
void f() {
  g(0, 1, 2, 3);
}
void g(int a, int b, int c, int d) {}
''');
    _assertArgumentRange(1, 2, SourceRange(16, 6), SourceRange(18, 4));
  }

  Future<void> test_argumentRange_middle_trailingComma() async {
    await resolveTestUnit('''
void f() {
  g(0, 1, 2, 3, );
}
void g(int a, int b, int c, int d) {}
''');
    _assertArgumentRange(1, 2, SourceRange(16, 6), SourceRange(18, 4));
  }

  Future<void> test_argumentRange_only_named() async {
    await resolveTestUnit('''
void f() {
  g(a: 0);
}
void g({int a}) {}
''');
    _assertArgumentRange(0, 0, SourceRange(15, 4), SourceRange(15, 4));
  }

  Future<void> test_argumentRange_only_positional() async {
    await resolveTestUnit('''
void f() {
  g(0);
}
void g(int a) {}
''');
    _assertArgumentRange(0, 0, SourceRange(15, 1), SourceRange(15, 1));
  }

  Future<void> test_elementName() async {
    await resolveTestUnit('class ABC {}');
    var element = findElement('ABC');
    expect(range.elementName(element), SourceRange(6, 3));
  }

  Future<void> test_endEnd() async {
    await resolveTestUnit('main() {}');
    var mainFunction = testUnit.declarations[0] as FunctionDeclaration;
    var mainName = mainFunction.name;
    var mainBody = mainFunction.functionExpression.body;
    expect(range.endEnd(mainName, mainBody), SourceRange(4, 5));
  }

  Future<void> test_endLength() async {
    await resolveTestUnit('main() {}');
    var mainFunction = testUnit.declarations[0] as FunctionDeclaration;
    var mainName = mainFunction.name;
    expect(range.endLength(mainName, 3), SourceRange(4, 3));
  }

  Future<void> test_endStart() async {
    await resolveTestUnit('main() {}');
    var mainFunction = testUnit.declarations[0] as FunctionDeclaration;
    var mainName = mainFunction.name;
    var mainBody = mainFunction.functionExpression.body;
    expect(range.endStart(mainName, mainBody), SourceRange(4, 3));
  }

  void test_error() {
    var error = AnalysisError(null, 10, 5, ParserErrorCode.CONST_CLASS, []);
    expect(range.error(error), SourceRange(10, 5));
  }

  Future<void> test_node() async {
    await resolveTestUnit('main() {}');
    var mainFunction = testUnit.declarations[0] as FunctionDeclaration;
    var mainName = mainFunction.name;
    expect(range.node(mainName), SourceRange(0, 4));
  }

  Future<void> test_nodeInList_argumentList_first_named() async {
    await resolveTestUnit('''
void f() {
  g(a: 1, b: 2);
}
void g({int a, int b}) {}
''');
    var list = _argumentList;
    expect(range.nodeInList(list, list[0]), SourceRange(15, 6));
  }

  Future<void> test_nodeInList_argumentList_first_positional() async {
    await resolveTestUnit('''
void f() {
  g(1, 2);
}
void g(int a, int b) {}
''');
    var list = _argumentList;
    expect(range.nodeInList(list, list[0]), SourceRange(15, 3));
  }

  Future<void> test_nodeInList_argumentList_last_named() async {
    await resolveTestUnit('''
void f() {
  g(a: 1, b: 2);
}
void g({int a, int b}) {}
''');
    var list = _argumentList;
    expect(range.nodeInList(list, list[1]), SourceRange(19, 6));
  }

  Future<void> test_nodeInList_argumentList_last_positional() async {
    await resolveTestUnit('''
void f() {
  g(1, 2);
}
void g(int a, int b) {}
''');
    var list = _argumentList;
    expect(range.nodeInList(list, list[1]), SourceRange(16, 3));
  }

  Future<void> test_nodeInList_argumentList_middle_named() async {
    await resolveTestUnit('''
void f() {
  g(a: 1, b: 2, c: 3);
}
void g({int a, int b, int c}) {}
''');
    var list = _argumentList;
    expect(range.nodeInList(list, list[1]), SourceRange(19, 6));
  }

  Future<void> test_nodeInList_argumentList_middle_positional() async {
    await resolveTestUnit('''
void f() {
  g(1, 2, 3);
}
void g(int a, int b, int c) {}
''');
    var list = _argumentList;
    expect(range.nodeInList(list, list[1]), SourceRange(16, 3));
  }

  Future<void> test_nodeInList_argumentList_only_named() async {
    await resolveTestUnit('''
void f() {
  g(a: 1);
}
void g({int a}) {}
''');
    var list = _argumentList;
    expect(range.nodeInList(list, list[0]), SourceRange(15, 4));
  }

  Future<void> test_nodeInList_argumentList_only_named_trailingComma() async {
    await resolveTestUnit('''
void f() {
  g(a: 1,);
}
void g({int a}) {}
''');
    var list = _argumentList;
    expect(range.nodeInList(list, list[0]), SourceRange(15, 5));
  }

  Future<void> test_nodeInList_argumentList_only_positional() async {
    await resolveTestUnit('''
void f() {
  g(1);
}
void g(int a) {}
''');
    var list = _argumentList;
    expect(range.nodeInList(list, list[0]), SourceRange(15, 1));
  }

  Future<void>
      test_nodeInList_argumentList_only_positional_trailingComma() async {
    await resolveTestUnit('''
void f() {
  g(1,);
}
void g(int a) {}
''');
    var list = _argumentList;
    expect(range.nodeInList(list, list[0]), SourceRange(15, 2));
  }

  Future<void> test_nodes() async {
    await resolveTestUnit(' main() {}');
    var mainFunction = testUnit.declarations[0] as FunctionDeclaration;
    var mainName = mainFunction.name;
    var mainBody = mainFunction.functionExpression.body;
    expect(range.nodes([mainName, mainBody]), SourceRange(1, 9));
  }

  Future<void> test_nodes_empty() async {
    await resolveTestUnit('main() {}');
    expect(range.nodes([]), SourceRange(0, 0));
  }

  void test_offsetBy() {
    expect(range.offsetBy(SourceRange(7, 3), 2), SourceRange(9, 3));
  }

  Future<void> test_startEnd_nodeNode() async {
    await resolveTestUnit(' main() {}');
    var mainFunction = testUnit.declarations[0] as FunctionDeclaration;
    var mainName = mainFunction.name;
    var mainBody = mainFunction.functionExpression.body;
    expect(range.startEnd(mainName, mainBody), SourceRange(1, 9));
  }

  Future<void> test_startLength_node() async {
    await resolveTestUnit(' main() {}');
    var mainFunction = testUnit.declarations[0] as FunctionDeclaration;
    var mainName = mainFunction.name;
    expect(range.startLength(mainName, 10), SourceRange(1, 10));
  }

  void test_startOffsetEndOffset() {
    expect(range.startOffsetEndOffset(6, 11), SourceRange(6, 5));
  }

  Future<void> test_startStart_nodeNode() async {
    await resolveTestUnit('main() {}');
    var mainFunction = testUnit.declarations[0] as FunctionDeclaration;
    var mainName = mainFunction.name;
    var mainBody = mainFunction.functionExpression.body;
    expect(range.startStart(mainName, mainBody), SourceRange(0, 7));
  }

  Future<void> test_token() async {
    await resolveTestUnit(' main() {}');
    var mainFunction = testUnit.declarations[0] as FunctionDeclaration;
    var mainName = mainFunction.name;
    expect(range.token(mainName.beginToken), SourceRange(1, 4));
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
