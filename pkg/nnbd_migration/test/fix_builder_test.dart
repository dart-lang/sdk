// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/type_system.dart';
import 'package:nnbd_migration/src/decorated_class_hierarchy.dart';
import 'package:nnbd_migration/src/fix_builder.dart';
import 'package:nnbd_migration/src/variables.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'migration_visitor_test_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FixBuilderTest);
  });
}

@reflectiveTest
class FixBuilderTest extends EdgeBuilderTestBase {
  DartType get dynamicType => postMigrationTypeProvider.dynamicType;

  DartType get objectType => postMigrationTypeProvider.objectType;

  TypeProvider get postMigrationTypeProvider =>
      (typeProvider as TypeProviderImpl)
          .withNullability(NullabilitySuffix.none);

  @override
  Future<CompilationUnit> analyze(String code) async {
    var unit = await super.analyze(code);
    graph.propagate();
    return unit;
  }

  test_binaryExpression_ampersand_ampersand() async {
    await analyze('''
_f(bool x, bool y) => x && y;
''');
    visitSubexpression(findNode.binary('&&'), 'bool');
  }

  test_binaryExpression_ampersand_ampersand_flow() async {
    await analyze('''
_f(bool/*?*/ x) => x != null && x;
''');
    visitSubexpression(findNode.binary('&&'), 'bool');
  }

  test_binaryExpression_ampersand_ampersand_nullChecked() async {
    await analyze('''
_f(bool/*?*/ x, bool/*?*/ y) => x && y;
''');
    var xRef = findNode.simple('x &&');
    var yRef = findNode.simple('y;');
    visitSubexpression(findNode.binary('&&'), 'bool',
        nullChecked: {xRef, yRef});
  }

  test_binaryExpression_bang_eq() async {
    await analyze('''
_f(Object/*?*/ x, Object/*?*/ y) => x != y;
''');
    visitSubexpression(findNode.binary('!='), 'bool');
  }

  test_binaryExpression_bar_bar() async {
    await analyze('''
_f(bool x, bool y) {
  return x || y;
}
''');
    visitSubexpression(findNode.binary('||'), 'bool');
  }

  test_binaryExpression_bar_bar_flow() async {
    await analyze('''
_f(bool/*?*/ x) {
  return x == null || x;
}
''');
    visitSubexpression(findNode.binary('||'), 'bool');
  }

  test_binaryExpression_bar_bar_nullChecked() async {
    await analyze('''
_f(Object/*?*/ x, Object/*?*/ y) {
  return x || y;
}
''');
    var xRef = findNode.simple('x ||');
    var yRef = findNode.simple('y;');
    visitSubexpression(findNode.binary('||'), 'bool',
        nullChecked: {xRef, yRef});
  }

  test_binaryExpression_eq_eq() async {
    await analyze('''
_f(Object/*?*/ x, Object/*?*/ y) {
  return x == y;
}
''');
    visitSubexpression(findNode.binary('=='), 'bool');
  }

  test_binaryExpression_question_question() async {
    await analyze('''
_f(int/*?*/ x, double/*?*/ y) {
  return x ?? y;
}
''');
    visitSubexpression(findNode.binary('??'), 'num?');
  }

  test_binaryExpression_question_question_nullChecked() async {
    await analyze('''
Object/*!*/ _f(int/*?*/ x, double/*?*/ y) {
  return x ?? y;
}
''');
    var yRef = findNode.simple('y;');
    visitSubexpression(findNode.binary('??'), 'num',
        contextType: objectType, nullChecked: {yRef});
  }

  test_binaryExpression_userDefinable_dynamic() async {
    await analyze('''
Object/*!*/ _f(dynamic d, int/*?*/ i) => d + i;
''');
    visitSubexpression(findNode.binary('+'), 'dynamic',
        contextType: objectType);
  }

  test_binaryExpression_userDefinable_intRules() async {
    await analyze('''
_f(int i, int j) => i + j;
''');
    visitSubexpression(findNode.binary('+'), 'int');
  }

  test_binaryExpression_userDefinable_simple() async {
    await analyze('''
class _C {
  int operator+(String s) => 1;
}
_f(_C c) => c + 'foo';
''');
    visitSubexpression(findNode.binary('c +'), 'int');
  }

  test_binaryExpression_userDefinable_simple_check_lhs() async {
    await analyze('''
class _C {
  int operator+(String s) => 1;
}
_f(_C/*?*/ c) => c + 'foo';
''');
    visitSubexpression(findNode.binary('c +'), 'int',
        nullChecked: {findNode.simple('c +')});
  }

  test_binaryExpression_userDefinable_simple_check_rhs() async {
    await analyze('''
class _C {
  int operator+(String/*!*/ s) => 1;
}
_f(_C c, String/*?*/ s) => c + s;
''');
    visitSubexpression(findNode.binary('c +'), 'int',
        nullChecked: {findNode.simple('s;')});
  }

  test_binaryExpression_userDefinable_substituted() async {
    await analyze('''
class _C<T, U> {
  T operator+(U u) => throw 'foo';
}
_f(_C<int, String> c) => c + 'foo';
''');
    visitSubexpression(findNode.binary('c +'), 'int');
  }

  test_binaryExpression_userDefinable_substituted_check_rhs() async {
    await analyze('''
class _C<T, U> {
  T operator+(U u) => throw 'foo';
}
_f(_C<int, String/*!*/> c, String/*?*/ s) => c + s;
''');
    visitSubexpression(findNode.binary('c +'), 'int',
        nullChecked: {findNode.simple('s;')});
  }

  test_binaryExpression_userDefinable_substituted_no_check_rhs() async {
    await analyze('''
class _C<T, U> {
  T operator+(U u) => throw 'foo';
}
_f(_C<int, String/*?*/> c, String/*?*/ s) => c + s;
''');
    visitSubexpression(findNode.binary('c +'), 'int');
  }

  test_booleanLiteral() async {
    await analyze('''
f() => true;
''');
    visitSubexpression(findNode.booleanLiteral('true'), 'bool');
  }

  test_doubleLiteral() async {
    await analyze('''
f() => 1.0;
''');
    visitSubexpression(findNode.doubleLiteral('1.0'), 'double');
  }

  test_integerLiteral() async {
    await analyze('''
f() => 1;
''');
    visitSubexpression(findNode.integerLiteral('1'), 'int');
  }

  test_nullLiteral() async {
    await analyze('''
f() => null;
''');
    visitSubexpression(findNode.nullLiteral('null'), 'Null');
  }

  test_parenthesizedExpression() async {
    await analyze('''
f() => (1);
''');
    visitSubexpression(findNode.integerLiteral('1'), 'int');
  }

  test_simpleIdentifier_className() async {
    await analyze('''
_f() => int;
''');
    visitSubexpression(findNode.simple('int'), 'Type');
  }

  test_simpleIdentifier_field() async {
    await analyze('''
class _C {
  int i = 1;
  f() => i;
}
''');
    visitSubexpression(findNode.simple('i;'), 'int');
  }

  test_simpleIdentifier_field_generic() async {
    await analyze('''
class _C<T> {
  List<T> x = null;
  f() => x;
}
''');
    visitSubexpression(findNode.simple('x;'), 'List<T>?');
  }

  test_simpleIdentifier_field_nullable() async {
    await analyze('''
class _C {
  int/*?*/ i = 1;
  f() => i;
}
''');
    visitSubexpression(findNode.simple('i;'), 'int?');
  }

  test_simpleIdentifier_getter() async {
    await analyze('''
class _C {
  int get i => 1;
  f() => i;
}
''');
    visitSubexpression(findNode.simple('i;'), 'int');
  }

  test_simpleIdentifier_getter_nullable() async {
    await analyze('''
class _C {
  int/*?*/ get i => 1;
  f() => i;
}
''');
    visitSubexpression(findNode.simple('i;'), 'int?');
  }

  test_simpleIdentifier_localVariable_nonNullable() async {
    await analyze('''
_f(int x) {
  return x;
}
''');
    visitSubexpression(findNode.simple('x;'), 'int');
  }

  test_simpleIdentifier_localVariable_nullable() async {
    await analyze('''
_f(int/*?*/ x) {
  return x;
}
''');
    visitSubexpression(findNode.simple('x;'), 'int?');
  }

  test_stringLiteral() async {
    await analyze('''
f() => 'foo';
''');
    visitSubexpression(findNode.stringLiteral("'foo'"), 'String');
  }

  test_symbolLiteral() async {
    await analyze('''
f() => #foo;
''');
    visitSubexpression(findNode.symbolLiteral('#foo'), 'Symbol');
  }

  test_use_of_dynamic() async {
    // Use of `dynamic` in a context requiring non-null is not explicitly null
    // checked.
    await analyze('''
bool _f(dynamic d, bool b) => d && b;
''');
    visitSubexpression(findNode.binary('&&'), 'bool');
  }

  void visitSubexpression(Expression node, String expectedType,
      {DartType contextType,
      Set<Expression> nullChecked = const <Expression>{}}) {
    contextType ??= dynamicType;
    var fixBuilder = _FixBuilder(
        decoratedClassHierarchy, typeProvider, typeSystem, variables);
    fixBuilder.createFlowAnalysis(node.thisOrAncestorOfType<FunctionBody>());
    var type = fixBuilder.visitSubexpression(node, contextType);
    expect((type as TypeImpl).toString(withNullability: true), expectedType);
    expect(fixBuilder.nullCheckedExpressions, nullChecked);
  }
}

class _FixBuilder extends FixBuilder {
  final Set<Expression> nullCheckedExpressions = {};

  _FixBuilder(DecoratedClassHierarchy decoratedClassHierarchy,
      TypeProvider typeProvider, TypeSystem typeSystem, Variables variables)
      : super(decoratedClassHierarchy, typeProvider, typeSystem, variables);

  @override
  void addNullCheck(Expression subexpression) {
    var newlyAdded = nullCheckedExpressions.add(subexpression);
    expect(newlyAdded, true);
  }
}
