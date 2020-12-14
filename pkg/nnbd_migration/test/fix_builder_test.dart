// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:analyzer/src/generated/element_type_provider.dart';
import 'package:nnbd_migration/fix_reason_target.dart';
import 'package:nnbd_migration/nnbd_migration.dart';
import 'package:nnbd_migration/src/edit_plan.dart';
import 'package:nnbd_migration/src/fix_aggregator.dart';
import 'package:nnbd_migration/src/fix_builder.dart';
import 'package:nnbd_migration/src/nullability_node.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'migration_visitor_test_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FixBuilderTest);
  });
}

/// Information about the target of an assignment expression analyzed by
/// [FixBuilder].
class AssignmentTargetInfo {
  /// The type that the assignment target has when read.  This is only relevant
  /// for compound assignments (since they both read and write the assignment
  /// target)
  final DartType readType;

  /// The type that the assignment target has when written to.
  final DartType writeType;

  AssignmentTargetInfo(this.readType, this.writeType);
}

@reflectiveTest
class FixBuilderTest extends EdgeBuilderTestBase {
  static final isAddRequiredKeyword =
      TypeMatcher<NodeChangeForDefaultFormalParameter>()
          .having((c) => c.addRequiredKeyword, 'addRequiredKeyword', true);

  static final isMakeNullable = TypeMatcher<NodeChangeForTypeAnnotation>()
      .having((c) => c.makeNullable, 'makeNullable', true)
      .having((c) => c.nullabilityHint, 'nullabilityHint', isNull);

  static final isMakeNullableDueToHint =
      TypeMatcher<NodeChangeForTypeAnnotation>()
          .having((c) => c.makeNullable, 'makeNullable', true)
          .having((c) => c.nullabilityHint, 'nullabilityHint', isNotNull);

  static const isEdge = TypeMatcher<NullabilityEdge>();

  static final isExplainNonNullable = TypeMatcher<NodeChangeForTypeAnnotation>()
      .having((c) => c.makeNullable, 'makeNullable', false);

  static final isBadCombinedType = TypeMatcher<NodeChangeForAssignmentLike>()
      .having((c) => c.hasBadCombinedType, 'hasBadCombinedType', true);

  static final isNullableSource = TypeMatcher<NodeChangeForAssignmentLike>()
      .having((c) => c.hasNullableSource, 'hasNullableSource', true);

  static final isNodeChangeForExpression =
      TypeMatcher<NodeChangeForExpression>();

  static final isNoValidMigration =
      isNodeChangeForExpression.havingNoValidMigrationWithInfo(anything);

  static final isNullCheck =
      isNodeChangeForExpression.havingNullCheckWithInfo(anything);

  static final isRemoveLanguageVersion =
      TypeMatcher<NodeChangeForCompilationUnit>().having(
          (c) => c.removeLanguageVersionComment,
          'removeLanguageVersionComment',
          true);

  static final isAddImportOfIterableExtension =
      TypeMatcher<NodeChangeForCompilationUnit>()
          .having((c) => c.addImports, 'addImports', {
    'package:collection/collection.dart': {'IterableExtension'}
  });

  static final isAddShowOfIterableExtension =
      TypeMatcher<NodeChangeForShowCombinator>().having((c) => c.addNames,
          'addNames', unorderedEquals(['IterableExtension']));

  static final isRemoveNullAwareness =
      TypeMatcher<NodeChangeForPropertyAccess>()
          .having((c) => c.removeNullAwareness, 'removeNullAwareness', true);

  static final isRemoveAs = TypeMatcher<NodeChangeForAsExpression>()
      .having((c) => c.removeAs, 'removeAs', true);

  static final isRequiredAnnotationToRequiredKeyword =
      TypeMatcher<NodeChangeForAnnotation>().having(
          (c) => c.changeToRequiredKeyword, 'changeToRequiredKeyword', true);

  static final isWeakNullAwareAssignment =
      TypeMatcher<NodeChangeForAssignment>()
          .having((c) => c.isWeakNullAware, 'isWeakNullAware', true);

  DartType get dynamicType => postMigrationTypeProvider.dynamicType;

  DartType get objectType => postMigrationTypeProvider.objectType;

  TypeProvider get postMigrationTypeProvider =>
      (typeProvider as TypeProviderImpl).asNonNullableByDefault;

  @override
  Future<CompilationUnit> analyze(String code) async {
    var unit = await super.analyze(code);
    graph.propagate(null);
    return unit;
  }

  TypeMatcher<NodeChangeForArgumentList> isDropArgument(
          dynamic argumentsToDrop) =>
      TypeMatcher<NodeChangeForArgumentList>()
          .having((c) => c.argumentsToDrop, 'argumentsToDrop', argumentsToDrop);

  TypeMatcher<AtomicEditInfo> isInfo(description, fixReasons) =>
      TypeMatcher<AtomicEditInfo>()
          .having((i) => i.description, 'description', description)
          .having((i) => i.fixReasons, 'fixReasons', fixReasons);

  TypeMatcher<NodeChangeForMethodName> isMethodNameChange(
          dynamic replacement) =>
      TypeMatcher<NodeChangeForMethodName>()
          .having((c) => c.replacement, 'replacement', replacement);

  Map<AstNode, NodeChange> scopedChanges(
          FixBuilder fixBuilder, AstNode scope) =>
      {
        for (var entry in fixBuilder.changes.entries)
          if (_isInScope(entry.key, scope) && !entry.value.isInformative)
            entry.key: entry.value
      };

  Map<AstNode, NodeChange> scopedInformative(
          FixBuilder fixBuilder, AstNode scope) =>
      {
        for (var entry in fixBuilder.changes.entries)
          if (_isInScope(entry.key, scope) && entry.value.isInformative)
            entry.key: entry.value
      };

  Map<AstNode, Set<Problem>> scopedProblems(
          FixBuilder fixBuilder, AstNode scope) =>
      {
        for (var entry in fixBuilder.problems.entries)
          if (_isInScope(entry.key, scope)) entry.key: entry.value
      };

  Future<void> test_asExpression_keep() async {
    await analyze('''
_f(Object x) {
  print((x as int) + 1);
}
''');
    var asExpression = findNode.simple('x as').parent as Expression;
    visitSubexpression(asExpression, 'int');
  }

  Future<void> test_asExpression_keep_previously_unnecessary() async {
    verifyNoTestUnitErrors = false;
    await analyze('''
f(int i) {
  print((i as int) + 1);
}
''');
    expect(
        testAnalysisResult.errors.single.errorCode, HintCode.UNNECESSARY_CAST);
    var asExpression = findNode.simple('i as').parent as Expression;
    visitSubexpression(asExpression, 'int');
  }

  Future<void> test_asExpression_remove() async {
    await analyze('''
_f(Object x) {
  if (x is! int) return;
  print((x as int) + 1);
}
''');
    var asExpression = findNode.simple('x as').parent as Expression;
    visitSubexpression(asExpression, 'int',
        changes: {asExpression: isRemoveAs});
  }

  Future<void>
      test_assignmentExpression_compound_combined_nullable_noProblem() async {
    await analyze('''
abstract class _C {
  _D/*?*/ operator+(int/*!*/ value);
}
abstract class _D extends _C {}
abstract class _E {
  _C/*!*/ get x;
  void set x(_C/*?*/ value);
  f(int/*!*/ y) => x += y;
}
''');
    visitSubexpression(findNode.assignment('+='), '_D?');
  }

  Future<void>
      test_assignmentExpression_compound_combined_nullable_noProblem_dynamic() async {
    await analyze('''
abstract class _E {
  dynamic get x;
  void set x(Object/*!*/ value);
  f(int/*!*/ y) => x += y;
}
''');
    var assignment = findNode.assignment('+=');
    visitSubexpression(assignment, 'dynamic');
  }

  @FailingTest(reason: 'TODO(paulberry)')
  Future<void>
      test_assignmentExpression_compound_combined_nullable_problem() async {
    await analyze('''
abstract class _C {
  _D/*?*/ operator+(int/*!*/ value);
}
abstract class _D extends _C {}
abstract class _E {
  _C/*!*/ get x;
  void set x(_C/*!*/ value);
  f(int/*!*/ y) => x += y;
}
''');
    var assignment = findNode.assignment('+=');
    visitSubexpression(assignment, '_D', problems: {
      assignment: {const CompoundAssignmentCombinedNullable()}
    });
  }

  Future<void> test_assignmentExpression_compound_dynamic() async {
    // To confirm that the RHS is visited, we check that a null check was
    // properly inserted into a subexpression of the RHS.
    await analyze('''
_f(dynamic x, int/*?*/ y) => x += y + 1;
''');
    visitSubexpression(findNode.assignment('+='), 'dynamic',
        changes: {findNode.simple('y +'): isNullCheck});
  }

  Future<void> test_assignmentExpression_compound_intRules() async {
    await analyze('''
_f(int x, int y) => x += y;
''');
    visitSubexpression(findNode.assignment('+='), 'int');
  }

  @FailingTest(reason: 'TODO(paulberry)')
  Future<void> test_assignmentExpression_compound_lhs_nullable_problem() async {
    await analyze('''
abstract class _C {
  _D/*!*/ operator+(int/*!*/ value);
}
abstract class _D extends _C {}
abstract class _E {
  _C/*?*/ get x;
  void set x(_C/*?*/ value);
  f(int/*!*/ y) => x += y;
}
''');
    var assignment = findNode.assignment('+=');
    visitSubexpression(assignment, '_D', problems: {
      assignment: {const CompoundAssignmentReadNullable()}
    });
  }

  @FailingTest(issue: 'https://github.com/dart-lang/sdk/issues/39641')
  Future<void> test_assignmentExpression_compound_promoted() async {
    await analyze('''
f(bool/*?*/ x, bool/*?*/ y) => x != null && (x = y);
''');
    // It is ok to assign a nullable value to `x` even though it is promoted to
    // non-nullable, so `y` should not be null-checked.  However, the whole
    // assignment `x = y` should be null checked because the RHS of `&&` cannot
    // be nullable.
    visitSubexpression(findNode.binary('&&'), 'bool',
        changes: {findNode.parenthesized('x = y'): isNullCheck});
  }

  Future<void> test_assignmentExpression_compound_rhs_nonNullable() async {
    await analyze('''
abstract class _C {
  _D/*!*/ operator+(int/*!*/ value);
}
abstract class _D extends _C {}
_f(_C/*!*/ x, int/*!*/ y) => x += y;
''');
    visitSubexpression(findNode.assignment('+='), '_D');
  }

  Future<void> test_assignmentExpression_compound_rhs_nullable_check() async {
    await analyze('''
abstract class _C {
  _D/*!*/ operator+(int/*!*/ value);
}
abstract class _D extends _C {}
_f(_C/*!*/ x, int/*?*/ y) => x += y;
''');
    visitSubexpression(findNode.assignment('+='), '_D',
        changes: {findNode.simple('y;'): isNullCheck});
  }

  Future<void> test_assignmentExpression_compound_rhs_nullable_noCheck() async {
    await analyze('''
abstract class _C {
  _D/*!*/ operator+(int/*?*/ value);
}
abstract class _D extends _C {}
_f(_C/*!*/ x, int/*?*/ y) => x += y;
''');
    visitSubexpression(findNode.assignment('+='), '_D');
  }

  Future<void>
      test_assignmentExpression_null_aware_rhs_does_not_promote() async {
    await analyze('''
_f(bool/*?*/ b, int/*?*/ i) {
  b ??= i.isEven; // 1
  b = i.isEven; // 2
  b = i.isEven; // 3
}
''');
    // The null check inserted at 1 fails to promote i because it's inside the
    // `??=`, so a null check is inserted at 2.  This does promote i, so no null
    // check is inserted at 3.
    visitStatement(findNode.block('{'), changes: {
      findNode.simple('i.isEven; // 1'): isNullCheck,
      findNode.simple('i.isEven; // 2'): isNullCheck
    });
  }

  Future<void> test_assignmentExpression_null_aware_rhs_nonNullable() async {
    await analyze('''
abstract class _B {}
abstract class _C extends _B {}
abstract class _D extends _C {}
abstract class _E extends _C {}
abstract class _F {
  _D/*?*/ get x;
  void set x(_B/*?*/ value);
  f(_E/*!*/ y) => x ??= y;
}
''');
    visitSubexpression(findNode.assignment('??='), '_C');
  }

  Future<void> test_assignmentExpression_null_aware_rhs_nullable() async {
    await analyze('''
abstract class _B {}
abstract class _C extends _B {}
abstract class _D extends _C {}
abstract class _E extends _C {}
abstract class _F {
  _D/*?*/ get x;
  void set x(_B/*?*/ value);
  f(_E/*?*/ y) => x ??= y;
}
''');
    visitSubexpression(findNode.assignment('??='), '_C?');
  }

  Future<void> test_assignmentExpression_null_aware_simple_promoted() async {
    await analyze('''
_f(bool/*?*/ x, bool/*?*/ y) => x != null && (x ??= y) != null;
''');
    // On the RHS of the `&&`, `x` is promoted to non-nullable, but it is still
    // considered to be a nullable assignment target, so no null check is
    // generated for `y`.
    visitSubexpression(findNode.binary('&&'), 'bool',
        changes: {findNode.assignment('??='): isWeakNullAwareAssignment});
  }

  Future<void>
      test_assignmentExpression_simple_nonNullable_to_nonNullable() async {
    await analyze('''
_f(int/*!*/ x, int/*!*/ y) => x = y;
''');
    visitSubexpression(findNode.assignment('= '), 'int');
  }

  Future<void>
      test_assignmentExpression_simple_nonNullable_to_nullable() async {
    await analyze('''
_f(int/*?*/ x, int/*!*/ y) => x = y;
''');
    visitSubexpression(findNode.assignment('= '), 'int');
  }

  Future<void>
      test_assignmentExpression_simple_nullable_to_nonNullable() async {
    await analyze('''
_f(int/*!*/ x, int/*?*/ y) => x = y;
''');
    visitSubexpression(findNode.assignment('= '), 'int',
        changes: {findNode.simple('y;'): isNullCheck});
  }

  Future<void> test_assignmentExpression_simple_nullable_to_nullable() async {
    await analyze('''
_f(int/*?*/ x, int/*?*/ y) => x = y;
''');
    visitSubexpression(findNode.assignment('= '), 'int?');
  }

  Future<void> test_assignmentExpression_simple_promoted() async {
    await analyze('''
_f(bool/*?*/ x, bool/*?*/ y) => x != null && (x = y) != null;
''');
    // On the RHS of the `&&`, `x` is promoted to non-nullable, but it is still
    // considered to be a nullable assignment target, so no null check is
    // generated for `y`.
    visitSubexpression(findNode.binary('&&'), 'bool');
  }

  Future<void> test_assignmentTarget_indexExpression_compound_dynamic() async {
    await analyze('''
_f(dynamic d, int/*?*/ i) => d[i] += 0;
''');
    visitAssignmentTarget(findNode.index('d[i]'), 'dynamic', 'dynamic');
  }

  Future<void> test_assignmentTarget_indexExpression_compound_simple() async {
    await analyze('''
class _C {
  int operator[](String s) => 1;
  void operator[]=(String s, num n) {}
}
_f(_C c) => c['foo'] += 0;
''');
    visitAssignmentTarget(findNode.index('c['), 'int', 'num');
  }

  Future<void>
      test_assignmentTarget_indexExpression_compound_simple_check_lhs() async {
    await analyze('''
class _C {
  int operator[](String s) => 1;
  void operator[]=(String s, num n) {}
}
_f(_C/*?*/ c) => c['foo'] += 0;
''');
    visitAssignmentTarget(findNode.index('c['), 'int', 'num',
        changes: {findNode.simple('c['): isNullCheck});
  }

  @FailingTest(reason: 'TODO(paulberry): decide if this is worth caring about')
  Future<void>
      test_assignmentTarget_indexExpression_compound_simple_check_rhs() async {
    await analyze('''
class _C {
  int operator[](String/*!*/ s) => 1;
  void operator[]=(String/*?*/ s, num n) {}
}
_f(_C c, String/*?*/ s) => c[s] += 0;
''');
    visitAssignmentTarget(findNode.index('c['), 'int', 'num',
        changes: {findNode.simple('s]'): isNullCheck});
  }

  Future<void>
      test_assignmentTarget_indexExpression_compound_substituted() async {
    await analyze('''
class _C<T, U> {
  T operator[](U u) => throw 'foo';
  void operator[]=(U u, T t) {}
}
_f(_C<int, String> c) => c['foo'] += 1;
''');
    visitAssignmentTarget(findNode.index('c['), 'int', 'int');
  }

  @FailingTest(reason: 'TODO(paulberry): decide if this is worth caring about')
  Future<void>
      test_assignmentTarget_indexExpression_compound_substituted_check_rhs() async {
    await analyze('''
class _C<T, U> {
  T operator[](U u) => throw 'foo';
  void operator[]=(U/*?*/ u, T t) {}
}
_f(_C<int, String/*!*/> c, String/*?*/ s) => c[s] += 1;
''');
    visitAssignmentTarget(findNode.index('c['), 'int', 'int',
        changes: {findNode.simple('s]'): isNullCheck});
  }

  Future<void>
      test_assignmentTarget_indexExpression_compound_substituted_no_check_rhs() async {
    await analyze('''
class _C<T, U> {
  T operator[](U u) => throw 'foo';
  void operator[]=(U u, T t) {}
}
_f(_C<int, String/*?*/> c, String/*?*/ s) => c[s] += 0;
''');
    visitAssignmentTarget(findNode.index('c['), 'int', 'int');
  }

  Future<void> test_assignmentTarget_indexExpression_dynamic() async {
    await analyze('''
_f(dynamic d, int/*?*/ i) => d[i] = 0;
''');
    visitAssignmentTarget(findNode.index('d[i]'), null, 'dynamic');
  }

  Future<void> test_assignmentTarget_indexExpression_simple() async {
    await analyze('''
class _C {
  int operator[](String s) => 1;
  void operator[]=(String s, num n) {}
}
_f(_C c) => c['foo'] = 0;
''');
    visitAssignmentTarget(findNode.index('c['), null, 'num');
  }

  Future<void> test_assignmentTarget_indexExpression_simple_check_lhs() async {
    await analyze('''
class _C {
  int operator[](String s) => 1;
  void operator[]=(String s, num n) {}
}
_f(_C/*?*/ c) => c['foo'] = 0;
''');
    visitAssignmentTarget(findNode.index('c['), null, 'num',
        changes: {findNode.simple('c['): isNullCheck});
  }

  Future<void> test_assignmentTarget_indexExpression_simple_check_rhs() async {
    await analyze('''
class _C {
  int operator[](String/*?*/ s) => 1;
  void operator[]=(String/*!*/ s, num n) {}
}
_f(_C c, String/*?*/ s) => c[s] = 0;
''');
    visitAssignmentTarget(findNode.index('c['), null, 'num',
        changes: {findNode.simple('s]'): isNullCheck});
  }

  Future<void> test_assignmentTarget_indexExpression_substituted() async {
    await analyze('''
class _C<T, U> {
  T operator[](U u) => throw 'foo';
  void operator[]=(U u, T t) {}
}
_f(_C<int, String> c) => c['foo'] = 1;
''');
    visitAssignmentTarget(findNode.index('c['), null, 'int');
  }

  Future<void>
      test_assignmentTarget_indexExpression_substituted_check_rhs() async {
    await analyze('''
class _C<T, U> {
  T operator[](U u) => throw 'foo';
  void operator[]=(U/*!*/ u, T t) {}
}
_f(_C<int, String/*!*/> c, String/*?*/ s) => c[s] = 1;
''');
    visitAssignmentTarget(findNode.index('c['), null, 'int',
        changes: {findNode.simple('s]'): isNullCheck});
  }

  Future<void>
      test_assignmentTarget_indexExpression_substituted_no_check_rhs() async {
    await analyze('''
class _C<T, U> {
  T operator[](U u) => throw 'foo';
  void operator[]=(U u, T t) {}
}
_f(_C<int, String/*?*/> c, String/*?*/ s) => c[s] = 0;
''');
    visitAssignmentTarget(findNode.index('c['), null, 'int');
  }

  Future<void> test_assignmentTarget_prefixedIdentifier_dynamic() async {
    await analyze('''
Object/*!*/ _f(dynamic d) => d.x += 1;
''');
    visitAssignmentTarget(findNode.prefixed('d.x'), 'dynamic', 'dynamic');
  }

  Future<void> test_assignmentTarget_propertyAccess_dynamic() async {
    await analyze('''
_f(dynamic d) => (d).x += 1;
''');
    visitAssignmentTarget(
        findNode.propertyAccess('(d).x'), 'dynamic', 'dynamic');
  }

  Future<void>
      test_assignmentTarget_propertyAccess_dynamic_notCompound() async {
    await analyze('''
_f(dynamic d) => (d).x = 1;
''');
    visitAssignmentTarget(findNode.propertyAccess('(d).x'), null, 'dynamic');
  }

  Future<void> test_assignmentTarget_propertyAccess_field_nonNullable() async {
    await analyze('''
class _C {
  int/*!*/ x = 0;
}
_f(_C c) => (c).x += 1;
''');
    visitAssignmentTarget(findNode.propertyAccess('(c).x'), 'int', 'int');
  }

  Future<void>
      test_assignmentTarget_propertyAccess_field_nonNullable_notCompound() async {
    await analyze('''
class _C {
  int/*!*/ x = 0;
}
_f(_C c) => (c).x = 1;
''');
    visitAssignmentTarget(findNode.propertyAccess('(c).x'), null, 'int');
  }

  Future<void> test_assignmentTarget_propertyAccess_field_nullable() async {
    await analyze('''
class _C {
  int/*?*/ x = 0;
}
_f(_C c) => (c).x += 1;
''');
    visitAssignmentTarget(findNode.propertyAccess('(c).x'), 'int?', 'int?');
  }

  Future<void> test_assignmentTarget_propertyAccess_getter_nullable() async {
    await analyze('''
abstract class _C {
  int/*?*/ get x;
  void set x(num/*?*/ value);
}
_f(_C c) => (c).x += 1;
''');
    visitAssignmentTarget(findNode.propertyAccess('(c).x'), 'int?', 'num?');
  }

  Future<void>
      test_assignmentTarget_propertyAccess_getter_setter_check_lhs() async {
    await analyze('''
abstract class _C {
  int get x;
  void set x(num value);
}
_f(_C/*?*/ c) => (c).x += 1;
''');
    visitAssignmentTarget(findNode.propertyAccess('(c).x'), 'int', 'num',
        changes: {findNode.parenthesized('(c).x'): isNullCheck});
  }

  Future<void>
      test_assignmentTarget_propertyAccess_getter_setter_nonNullable() async {
    await analyze('''
abstract class _C {
  int/*!*/ get x;
  void set x(num/*!*/ value);
}
_f(_C c) => (c).x += 1;
''');
    visitAssignmentTarget(findNode.propertyAccess('(c).x'), 'int', 'num');
  }

  Future<void> test_assignmentTarget_propertyAccess_nullAware_dynamic() async {
    await analyze('''
_f(dynamic d) => d?.x += 1;
''');
    visitAssignmentTarget(
        findNode.propertyAccess('d?.x'), 'dynamic', 'dynamic');
  }

  Future<void>
      test_assignmentTarget_propertyAccess_nullAware_field_nonNullable() async {
    await analyze('''
class _C {
  int/*!*/ x = 0;
}
_f(_C/*?*/ c) => c?.x += 1;
''');
    visitAssignmentTarget(findNode.propertyAccess('c?.x'), 'int', 'int');
  }

  Future<void>
      test_assignmentTarget_propertyAccess_nullAware_field_nullable() async {
    await analyze('''
class _C {
  int/*?*/ x = 0;
}
_f(_C/*?*/ c) => c?.x += 1;
''');
    visitAssignmentTarget(findNode.propertyAccess('c?.x'), 'int?', 'int?');
  }

  Future<void>
      test_assignmentTarget_propertyAccess_nullAware_getter_setter_nonNullable() async {
    await analyze('''
abstract class _C {
  int/*!*/ get x;
  void set x(num/*!*/ value);
}
_f(_C/*?*/ c) => c?.x += 1;
''');
    visitAssignmentTarget(findNode.propertyAccess('c?.x'), 'int', 'num');
  }

  Future<void>
      test_assignmentTarget_propertyAccess_nullAware_getter_setter_nullable() async {
    await analyze('''
abstract class _C {
  int/*?*/ get x;
  void set x(num/*?*/ value);
}
_f(_C/*?*/ c) => c?.x += 1;
''');
    visitAssignmentTarget(findNode.propertyAccess('c?.x'), 'int?', 'num?');
  }

  Future<void>
      test_assignmentTarget_propertyAccess_nullAware_substituted() async {
    await analyze('''
abstract class _C<T> {
  _E<T> get x;
  void set x(_D<T> value);
}
class _D<T> implements Iterable<T> {
  noSuchMethod(invocation) => super.noSuchMethod(invocation);
  _D<T> operator+(int i) => this;
}
class _E<T> extends _D<T> {}
_f(_C<int>/*?*/ c) => c?.x += 1;
''');
    visitAssignmentTarget(
        findNode.propertyAccess('c?.x'), '_E<int>', '_D<int>');
  }

  Future<void> test_assignmentTarget_propertyAccess_substituted() async {
    await analyze('''
abstract class _C<T> {
  _E<T> get x;
  void set x(_D<T> value);
}
class _D<T> implements Iterable<T> {
  noSuchMethod(invocation) => super.noSuchMethod(invocation);
  _D<T> operator+(int i) => this;
}
class _E<T> extends _D<T> {}
_f(_C<int> c) => (c).x += 1;
''');
    visitAssignmentTarget(
        findNode.propertyAccess('(c).x'), '_E<int>', '_D<int>');
  }

  Future<void> test_assignmentTarget_simpleIdentifier_field_generic() async {
    await analyze('''
abstract class _C<T> {
  _C<T> operator+(int i);
}
class _D<T> {
  _D(this.x);
  _C<T/*!*/>/*!*/ x;
  _f() => x += 0;
}
''');
    visitAssignmentTarget(findNode.simple('x +='), '_C<T>', '_C<T>');
  }

  Future<void>
      test_assignmentTarget_simpleIdentifier_field_nonNullable() async {
    await analyze('''
class _C {
  int/*!*/ x;
  _f() => x += 0;
}
''');
    visitAssignmentTarget(findNode.simple('x '), 'int', 'int');
  }

  Future<void> test_assignmentTarget_simpleIdentifier_field_nullable() async {
    await analyze('''
class _C {
  int/*?*/ x;
  _f() => x += 0;
}
''');
    visitAssignmentTarget(findNode.simple('x '), 'int?', 'int?');
  }

  Future<void> test_assignmentTarget_simpleIdentifier_getset_generic() async {
    await analyze('''
abstract class _C<T> {
  _C<T> operator+(int i);
}
abstract class _D<T> extends _C<T> {}
abstract class _E<T> {
  _D<T/*!*/>/*!*/ get x;
  void set x(_C<T/*!*/>/*!*/ value);
  _f() => x += 0;
}
''');
    visitAssignmentTarget(findNode.simple('x +='), '_D<T>', '_C<T>');
  }

  Future<void>
      test_assignmentTarget_simpleIdentifier_getset_getterNullable() async {
    await analyze('''
class _C {
  int/*?*/ get x => 1;
  void set x(int/*!*/ value) {}
  _f() => x += 0;
}
''');
    visitAssignmentTarget(findNode.simple('x +='), 'int?', 'int');
  }

  Future<void>
      test_assignmentTarget_simpleIdentifier_getset_setterNullable() async {
    await analyze('''
class _C {
  int/*!*/ get x => 1;
  void set x(int/*?*/ value) {}
  _f() => x += 0;
}
''');
    visitAssignmentTarget(findNode.simple('x +='), 'int', 'int?');
  }

  Future<void>
      test_assignmentTarget_simpleIdentifier_localVariable_nonNullable() async {
    await analyze('''
_f(int/*!*/ x) => x += 0;
''');
    visitAssignmentTarget(findNode.simple('x '), 'int', 'int');
  }

  Future<void>
      test_assignmentTarget_simpleIdentifier_localVariable_nullable() async {
    await analyze('''
_f(int/*?*/ x) => x += 0;
''');
    visitAssignmentTarget(findNode.simple('x '), 'int?', 'int?');
  }

  Future<void>
      test_assignmentTarget_simpleIdentifier_setter_nonNullable() async {
    await analyze('''
class _C {
  void set x(int/*!*/ value) {}
  _f() => x = 0;
}
''');
    visitAssignmentTarget(findNode.simple('x '), null, 'int');
  }

  Future<void> test_assignmentTarget_simpleIdentifier_setter_nullable() async {
    await analyze('''
class _C {
  void set x(int/*?*/ value) {}
  _f() => x = 0;
}
''');
    visitAssignmentTarget(findNode.simple('x '), null, 'int?');
  }

  Future<void> test_binaryExpression_ampersand_ampersand() async {
    await analyze('''
_f(bool x, bool y) => x && y;
''');
    visitSubexpression(findNode.binary('&&'), 'bool');
  }

  Future<void> test_binaryExpression_ampersand_ampersand_flow() async {
    await analyze('''
_f(bool/*?*/ x) => x != null && x;
''');
    visitSubexpression(findNode.binary('&&'), 'bool');
  }

  Future<void> test_binaryExpression_ampersand_ampersand_nullChecked() async {
    await analyze('''
_f(bool/*?*/ x, bool/*?*/ y) => x && y;
''');
    var xRef = findNode.simple('x &&');
    var yRef = findNode.simple('y;');
    visitSubexpression(findNode.binary('&&'), 'bool',
        changes: {xRef: isNullCheck, yRef: isNullCheck});
  }

  Future<void> test_binaryExpression_bang_eq() async {
    await analyze('''
_f(Object/*?*/ x, Object/*?*/ y) => x != y;
''');
    visitSubexpression(findNode.binary('!='), 'bool');
  }

  Future<void> test_binaryExpression_bar_bar() async {
    await analyze('''
_f(bool x, bool y) {
  return x || y;
}
''');
    visitSubexpression(findNode.binary('||'), 'bool');
  }

  Future<void> test_binaryExpression_bar_bar_flow() async {
    await analyze('''
_f(bool/*?*/ x) {
  return x == null || x;
}
''');
    visitSubexpression(findNode.binary('||'), 'bool');
  }

  Future<void> test_binaryExpression_bar_bar_nullChecked() async {
    await analyze('''
_f(bool/*?*/ x, bool/*?*/ y) {
  return x || y;
}
''');
    var xRef = findNode.simple('x ||');
    var yRef = findNode.simple('y;');
    visitSubexpression(findNode.binary('||'), 'bool',
        changes: {xRef: isNullCheck, yRef: isNullCheck});
  }

  Future<void> test_binaryExpression_eq_eq() async {
    await analyze('''
_f(Object/*?*/ x, Object/*?*/ y) {
  return x == y;
}
''');
    visitSubexpression(findNode.binary('=='), 'bool');
  }

  Future<void> test_binaryExpression_question_question() async {
    await analyze('''
_f(int/*?*/ x, double/*?*/ y) {
  return x ?? y;
}
''');
    visitSubexpression(findNode.binary('??'), 'num?');
  }

  Future<void> test_binaryExpression_question_question_flow() async {
    await analyze('''
_f(int/*?*/ x, int/*?*/ y) =>
    <dynamic>[x ?? (y != null ? 1 : throw 'foo'), y + 1];
''');
    // The null check on the RHS of the `??` doesn't promote, because it is not
    // guaranteed to execute.
    visitSubexpression(findNode.listLiteral('['), 'List<dynamic>',
        changes: {findNode.simple('y +'): isNullCheck});
  }

  Future<void> test_binaryExpression_question_question_nullChecked() async {
    await analyze('''
Object/*!*/ _f(int/*?*/ x, double/*?*/ y) {
  return x ?? y;
}
''');
    var yRef = findNode.simple('y;');
    visitSubexpression(findNode.binary('??'), 'num',
        changes: {yRef: isNullCheck});
  }

  Future<void> test_binaryExpression_userDefinable_dynamic() async {
    await analyze('''
Object/*!*/ _f(dynamic d, int/*?*/ i) => d + i;
''');
    visitSubexpression(findNode.binary('+'), 'dynamic');
  }

  Future<void> test_binaryExpression_userDefinable_intRules() async {
    await analyze('''
_f(int i, int j) => i + j;
''');
    visitSubexpression(findNode.binary('+'), 'int');
  }

  Future<void> test_binaryExpression_userDefinable_simple() async {
    await analyze('''
class _C {
  int operator+(String s) => 1;
}
_f(_C c) => c + 'foo';
''');
    visitSubexpression(findNode.binary('c +'), 'int');
  }

  Future<void> test_binaryExpression_userDefinable_simple_check_lhs() async {
    await analyze('''
class _C {
  int operator+(String s) => 1;
}
_f(_C/*?*/ c) => c + 'foo';
''');
    visitSubexpression(findNode.binary('c +'), 'int',
        changes: {findNode.simple('c +'): isNullCheck});
  }

  Future<void> test_binaryExpression_userDefinable_simple_check_rhs() async {
    await analyze('''
class _C {
  int operator+(String/*!*/ s) => 1;
}
_f(_C c, String/*?*/ s) => c + s;
''');
    visitSubexpression(findNode.binary('c +'), 'int',
        changes: {findNode.simple('s;'): isNullCheck});
  }

  Future<void> test_binaryExpression_userDefinable_substituted() async {
    await analyze('''
class _C<T, U> {
  T operator+(U u) => throw 'foo';
}
_f(_C<int, String> c) => c + 'foo';
''');
    visitSubexpression(findNode.binary('c +'), 'int');
  }

  Future<void>
      test_binaryExpression_userDefinable_substituted_check_rhs() async {
    await analyze('''
class _C<T, U> {
  T operator+(U/*!*/ u) => throw 'foo';
}
_f(_C<int, String/*!*/> c, String/*?*/ s) => c + s;
''');
    visitSubexpression(findNode.binary('c +'), 'int',
        changes: {findNode.simple('s;'): isNullCheck});
  }

  Future<void>
      test_binaryExpression_userDefinable_substituted_no_check_rhs() async {
    await analyze('''
class _C<T, U> {
  T operator+(U u) => throw 'foo';
}
_f(_C<int, String/*?*/> c, String/*?*/ s) => c + s;
''');
    visitSubexpression(findNode.binary('c +'), 'int');
  }

  Future<void> test_block() async {
    await analyze('''
_f(int/*?*/ x, int/*?*/ y) {
  { // block
    x + 1;
    y + 1;
  }
}
''');
    visitStatement(findNode.statement('{ // block'), changes: {
      findNode.simple('x + 1'): isNullCheck,
      findNode.simple('y + 1'): isNullCheck
    });
  }

  Future<void> test_booleanLiteral() async {
    await analyze('''
f() => true;
''');
    visitSubexpression(findNode.booleanLiteral('true'), 'bool');
  }

  Future<void> test_compound_assignment_null_shorted_ok() async {
    await analyze('''
class C {
  int/*!*/ x;
}
_f(C/*?*/ c) {
  c?.x += 1;
}
''');
    // Even though c?.x is nullable, it should not be a problem to use it as the
    // LHS of a compound assignment, because null shorting will ensure that the
    // assignment only happens if c is non-null.
    var assignment = findNode.assignment('+=');
    visitSubexpression(assignment, 'int?');
  }

  Future<void> test_compound_assignment_nullable_result_bad() async {
    await analyze('''
abstract class C {
  C/*?*/ operator+(int i);
}
f(C c) {
  c += 1;
}
''');
    var assignment = findNode.assignment('+=');
    visitSubexpression(assignment, 'C?',
        changes: {assignment: isBadCombinedType});
  }

  Future<void> test_compound_assignment_nullable_result_ok() async {
    await analyze('''
abstract class C {
  C/*?*/ operator+(int i);
}
abstract class D {
  void set x(C/*?*/ value);
  C/*!*/ get x;
  f() {
    x += 1;
  }
}
''');
    var assignment = findNode.assignment('+=');
    visitSubexpression(assignment, 'C?');
  }

  Future<void> test_compound_assignment_nullable_source() async {
    await analyze('''
_f(int/*?*/ x) {
  x += 1;
}
''');
    var assignment = findNode.assignment('+=');
    visitSubexpression(assignment, 'int',
        changes: {assignment: isNullableSource});
  }

  Future<void> test_compound_assignment_potentially_nullable_source() async {
    await analyze('''
class C<T extends num/*?*/> {
  _f(T/*!*/ x) {
    x += 1;
  }
}
''');
    var assignment = findNode.assignment('+=');
    visitSubexpression(assignment, 'num',
        changes: {assignment: isNullableSource});
  }

  Future<void> test_compound_assignment_promoted_ok() async {
    await analyze('''
abstract class C {
  C/*?*/ operator+(int i);
}
f(C/*?*/ x) {
  if (x != null) {
    x += 1;
  }
}
''');
    // The compound assignment is ok, because:
    // - prior to the assignment, x's value is promoted to non-nullable
    // - the nullable return value of operator+ is ok to assign to x, because it
    //   un-does the promotion.
    visitSubexpression(findNode.assignment('+='), 'C?');
  }

  Future<void> test_conditionalExpression_dead_else_remove() async {
    await analyze('_f(int x, int/*?*/ y) => x != null ? x + 1 : y + 1.0;');
    var expression = findNode.conditionalExpression('x != null');
    visitSubexpression(expression, 'int',
        changes: {expression: isConditionalWithKnownValue(true)});
  }

  Future<void> test_conditionalExpression_dead_else_warn() async {
    await analyze('_f(int x, int/*?*/ y) => x != null ? x + 1 : y + 1.0;');
    var expression = findNode.conditionalExpression('x != null');
    visitSubexpression(expression, 'num', warnOnWeakCode: true, changes: {
      expression: isConditionalWithKnownValue(true),
      findNode.simple('y +'): isNullCheck
    });
  }

  Future<void> test_conditionalExpression_dead_then_remove() async {
    await analyze('_f(int x, int/*?*/ y) => x == null ? y + 1.0 : x + 1;');
    var expression = findNode.conditionalExpression('x == null');
    visitSubexpression(expression, 'int',
        changes: {expression: isConditionalWithKnownValue(false)});
  }

  Future<void> test_conditionalExpression_dead_then_warn() async {
    await analyze('_f(int x, int/*?*/ y) => x == null ? y + 1.0 : x + 1;');
    var expression = findNode.conditionalExpression('x == null');
    visitSubexpression(expression, 'num', warnOnWeakCode: true, changes: {
      expression: isConditionalWithKnownValue(false),
      findNode.simple('y +'): isNullCheck
    });
  }

  Future<void> test_conditionalExpression_flow_as_condition() async {
    await analyze('''
_f(bool x, int/*?*/ y) => (x ? y != null : y != null) ? y + 1 : 0;
''');
    // No explicit check needs to be added to `y + 1`, because both arms of the
    // conditional can only be true if `y != null`.
    visitSubexpression(findNode.conditionalExpression('y + 1'), 'int');
  }

  Future<void> test_conditionalExpression_flow_condition() async {
    await analyze('''
_f(bool/*?*/ x) => x ? (x && true) : (x && true);
''');
    // No explicit check needs to be added to either `x && true`, because there
    // is already an explicit null check inserted for the condition.
    visitSubexpression(findNode.conditionalExpression('x ?'), 'bool',
        changes: {findNode.simple('x ?'): isNullCheck});
  }

  Future<void> test_conditionalExpression_flow_then_else() async {
    await analyze('''
_f(bool x, bool/*?*/ y) => (x ? (y && true) : (y && true)) && y;
''');
    // No explicit check needs to be added to the final reference to `y`,
    // because null checks are added to the "then" and "else" branches promoting
    // y.
    visitSubexpression(findNode.binary('&& y'), 'bool', changes: {
      findNode.simple('y && true) '): isNullCheck,
      findNode.simple('y && true))'): isNullCheck
    });
  }

  Future<void> test_conditionalExpression_lub() async {
    await analyze('''
_f(bool b) => b ? 1 : 1.0;
''');
    visitSubexpression(findNode.conditionalExpression('1.0'), 'num');
  }

  Future<void> test_conditionalExpression_throw_promotes() async {
    await analyze('''
_f(int/*?*/ x) =>
    <dynamic>[(x != null ? 1 : throw 'foo'), x + 1];
''');
    // No null check needs to be added to `x + 1`, because there is already an
    // explicit null check.
    visitSubexpression(findNode.listLiteral('['), 'List<dynamic>');
  }

  Future<void>
      test_defaultFormalParameter_add_required_ignore_decoy_annotation() async {
    await analyze('''
const foo = Object();
int _f({@foo int x}) => x + 1;
''');
    visitAll(
        changes: {findNode.defaultParameter('int x'): isAddRequiredKeyword});
  }

  Future<void>
      test_defaultFormalParameter_add_required_no_because_default() async {
    await analyze('''
int _f({int x = 0}) => x + 1;
''');
    visitAll();
  }

  Future<void>
      test_defaultFormalParameter_add_required_no_because_nullable() async {
    await analyze('''
int _f({int/*?*/ x}) => 1;
''');
    visitAll(
        changes: {findNode.typeName('int/*?*/ x'): isMakeNullableDueToHint});
  }

  Future<void>
      test_defaultFormalParameter_add_required_no_because_positional() async {
    await analyze('''
int _f([int/*!*/ x]) => x + 1;
''');
    visitAll(problems: {
      findNode.defaultParameter('int/*!*/ x'): {
        const NonNullableUnnamedOptionalParameter()
      }
    });
  }

  Future<void>
      test_defaultFormalParameter_add_required_replace_annotation() async {
    // TODO(paulberry): it would be nice to remove the import of `meta` if it's
    // no longer needed after the change.
    addMetaPackage();
    await analyze('''
import 'package:meta/meta.dart';
int _f({@required int x}) => x + 1;
''');
    visitAll(changes: {
      findNode.annotation('required'): isRequiredAnnotationToRequiredKeyword
    });
  }

  Future<void>
      test_defaultFormalParameter_add_required_replace_annotation_nullable() async {
    // TODO(paulberry): it would be nice to remove the import of `meta` if it's
    // no longer needed after the change.
    addMetaPackage();
    await analyze('''
import 'package:meta/meta.dart';
void _f({@required int/*?*/ x}) {}
''');
    visitAll(changes: {
      findNode.annotation('required'): isRequiredAnnotationToRequiredKeyword,
      findNode.typeName('int'): isMakeNullableDueToHint,
    });
  }

  Future<void> test_defaultFormalParameter_add_required_yes() async {
    await analyze('''
int _f({int x}) => x + 1;
''');
    visitAll(
        changes: {findNode.defaultParameter('int x'): isAddRequiredKeyword});
  }

  Future<void> test_doubleLiteral() async {
    await analyze('''
f() => 1.0;
''');
    visitSubexpression(findNode.doubleLiteral('1.0'), 'double');
  }

  Future<void> test_enum_ref_index() async {
    await analyze('''
enum E { V }
_f(E e) => e.index;
''');
    visitSubexpression(findNode.prefixed('e.index'), 'int');
  }

  Future<void> test_enum_ref_value() async {
    await analyze('''
enum E { V }
_f() => E.V;
''');
    visitSubexpression(findNode.prefixed('E.V'), 'E');
  }

  Future<void> test_enum_ref_values() async {
    await analyze('''
enum E { V }
_f() => E.values;
''');
    visitSubexpression(findNode.prefixed('E.values'), 'List<E>');
  }

  Future<void> test_expressionStatement() async {
    await analyze('''
_f(int/*!*/ x, int/*?*/ y) {
  x = y;
}
''');
    visitStatement(findNode.statement('x = y'),
        changes: {findNode.simple('y;'): isNullCheck});
  }

  Future<void> test_firstWhere_transform() async {
    await analyze('''
_f(Iterable<int> x) => x.firstWhere((n) => n.isEven, orElse: () => null);
''');
    var methodInvocation = findNode.methodInvocation('firstWhere');
    var functionExpression = findNode.functionExpression('() => null');
    var fixBuilder = visitSubexpression(methodInvocation, 'int?', changes: {
      methodInvocation.methodName: isMethodNameChange('firstWhereOrNull'),
      methodInvocation.argumentList:
          isDropArgument({functionExpression.parent: anything}),
      // Behavior of the function expression and its subexpression don't matter
      // because they're being dropped.
      functionExpression.parent: anything,
      findNode.nullLiteral('null'): anything
    });
    expect(fixBuilder.needsIterableExtension, true);
  }

  Future<void> test_functionExpressionInvocation_dynamic() async {
    await analyze('''
_f(dynamic d) => d();
''');
    visitSubexpression(findNode.functionExpressionInvocation('d('), 'dynamic');
  }

  Future<void> test_functionExpressionInvocation_function_checked() async {
    await analyze('''
_f(Function/*?*/ func) => func();
''');
    visitSubexpression(
        findNode.functionExpressionInvocation('func('), 'dynamic',
        changes: {findNode.simple('func()'): isNullCheck});
  }

  Future<void> test_functionExpressionInvocation_getter() async {
    await analyze('''
abstract class _C {
  int Function() get f;
}
_f(_C c) => (c.f)();
''');
    visitSubexpression(findNode.functionExpressionInvocation('c.f'), 'int');
  }

  Future<void>
      test_functionExpressionInvocation_getter_looksLikeMethodCall() async {
    await analyze('''
abstract class _C {
  int Function() get f;
}
_f(_C c) => c.f();
''');
    visitSubexpression(findNode.functionExpressionInvocation('c.f'), 'int');
  }

  Future<void> test_functionExpressionInvocation_getter_nullChecked() async {
    await analyze('''
abstract class _C {
  int Function()/*?*/ get f;
}
_f(_C c) => (c.f)();
''');
    visitSubexpression(findNode.functionExpressionInvocation('c.f'), 'int',
        changes: {findNode.parenthesized('c.f'): isNullCheck});
  }

  Future<void>
      test_functionExpressionInvocation_getter_nullChecked_looksLikeMethodCall() async {
    await analyze('''
abstract class _C {
  int Function()/*?*/ get f;
}
_f(_C c) => c.f();
''');
    visitSubexpression(findNode.functionExpressionInvocation('c.f'), 'int',
        changes: {findNode.propertyAccess('c.f'): isNullCheck});
  }

  Future<void> test_genericFunctionType_nonNullable() async {
    await analyze('''
void _f() {
  void Function() x = _f;
}
''');
    var genericFunctionType = findNode.genericFunctionType('Function');
    visitTypeAnnotation(genericFunctionType, 'void Function()',
        informative: {genericFunctionType: isExplainNonNullable});
  }

  Future<void> test_genericFunctionType_nonNullable_by_context() async {
    await analyze('''
typedef F = void Function();
''');
    var genericFunctionType = findNode.genericFunctionType('Function');
    visitTypeAnnotation(genericFunctionType, 'void Function()',
        informative: isEmpty);
  }

  Future<void> test_genericFunctionType_nullable() async {
    await analyze('''
void _f() {
  void Function() x = null;
}
''');
    var genericFunctionTypeAnnotation =
        findNode.genericFunctionType('Function');
    visitTypeAnnotation(genericFunctionTypeAnnotation, 'void Function()?',
        changes: {genericFunctionTypeAnnotation: isMakeNullable});
  }

  Future<void> test_genericFunctionType_nullable_arg() async {
    await analyze('''
void Function(int/*?*/) _f() {
  void Function(int) x = _g;
  return x;
}
void _g(int/*?*/ x) {}
''');
    var intTypeAnnotation = findNode.typeName('int)');
    var genericFunctionTypeAnnotation =
        findNode.genericFunctionType('Function(int)');
    visitTypeAnnotation(genericFunctionTypeAnnotation, 'void Function(int?)',
        changes: {intTypeAnnotation: isMakeNullable});
  }

  Future<void> test_genericFunctionType_nullable_return() async {
    await analyze('''
void _f() {
  int Function() x = _g;
}
int/*?*/ _g() => null;
''');
    var intTypeAnnotation = findNode.typeName('int Function');
    var genericFunctionTypeAnnotation =
        findNode.genericFunctionType('Function');
    visitTypeAnnotation(genericFunctionTypeAnnotation, 'int? Function()',
        changes: {intTypeAnnotation: isMakeNullable});
  }

  Future<void> test_ifStatement_dead_else() async {
    await analyze('''
_f(int x, int/*?*/ y) {
  if (x != null) {
    print(x + 1);
  } else {
    print(y + 1);
  }
}
''');
    var ifStatement = findNode.statement('if');
    visitStatement(ifStatement,
        changes: {ifStatement: isConditionalWithKnownValue(true)});
  }

  Future<void> test_ifStatement_dead_then() async {
    await analyze('''
_f(int x, int/*?*/ y) {
  if (x == null) {
    print(y + 1);
  } else {
    print(x + 1);
  }
}
''');
    var ifStatement = findNode.statement('if');
    visitStatement(ifStatement,
        changes: {ifStatement: isConditionalWithKnownValue(false)});
  }

  Future<void> test_ifStatement_flow_promote_in_else() async {
    await analyze('''
_f(int/*?*/ x) {
  if (x == null) {
    x + 1;
  } else {
    x + 2;
  }
}
''');
    visitStatement(findNode.statement('if'),
        changes: {findNode.simple('x + 1'): isNullCheck});
  }

  Future<void> test_ifStatement_flow_promote_in_then() async {
    await analyze('''
_f(int/*?*/ x) {
  if (x != null) {
    x + 1;
  } else {
    x + 2;
  }
}
''');
    visitStatement(findNode.statement('if'),
        changes: {findNode.simple('x + 2'): isNullCheck});
  }

  Future<void> test_ifStatement_flow_promote_in_then_no_else() async {
    await analyze('''
_f(int/*?*/ x) {
  if (x != null) {
    x + 1;
  }
}
''');
    visitStatement(findNode.statement('if'));
  }

  Future<void> test_implicit_downcast() async {
    await analyze('int f(num x) => x;');
    var xRef = findNode.simple('x;');
    visitSubexpression(xRef, 'int', changes: {
      xRef: isNodeChangeForExpression.havingIndroduceAsWithInfo(
          'int',
          isInfo(NullabilityFixDescription.downcastExpression,
              {FixReasonTarget.root: isEdge}))
    });
  }

  Future<void> test_import_IterableExtension_already_imported_add_show() async {
    addPackageFile('collection', 'collection.dart', 'class PriorityQueue {}');
    await analyze('''
import 'package:collection/collection.dart' show PriorityQueue;

main() {}
''');
    visitAll(injectNeedsIterableExtension: true, changes: {
      findNode.import('package:collection').combinators[0]:
          isAddShowOfIterableExtension
    });
  }

  Future<void> test_import_IterableExtension_already_imported_all() async {
    addPackageFile('collection', 'collection.dart', '');
    await analyze('''
import 'package:collection/collection.dart';

main() {}
''');
    visitAll(injectNeedsIterableExtension: true, changes: {});
  }

  Future<void>
      test_import_IterableExtension_already_imported_and_shown() async {
    addPackageFile('collection', 'collection.dart',
        'extension IterableExtension<T> on Iterable<T> {}');
    await analyze('''
import 'package:collection/collection.dart' show IterableExtension;

main() {}
''');
    visitAll(injectNeedsIterableExtension: true, changes: {});
  }

  Future<void> test_import_IterableExtension_already_imported_prefixed() async {
    addPackageFile('collection', 'collection.dart', '');
    await analyze('''
import 'package:collection/collection.dart' as c;

main() {}
''');
    visitAll(
        injectNeedsIterableExtension: true,
        changes: {findNode.unit: isAddImportOfIterableExtension});
  }

  Future<void> test_import_IterableExtension_other_import() async {
    addPackageFile(
        'foo', 'foo.dart', 'extension IterableExtension<T> on Iterable<T> {}');
    await analyze('''
import 'package:foo/foo.dart' show IterableExtension;

main() {}
''');
    visitAll(
        injectNeedsIterableExtension: true,
        changes: {findNode.unit: isAddImportOfIterableExtension});
  }

  Future<void> test_import_IterableExtension_simple() async {
    await analyze('''
main() {}
''');
    visitAll(
        injectNeedsIterableExtension: true,
        changes: {findNode.unit: isAddImportOfIterableExtension});
  }

  Future<void> test_indexExpression_dynamic() async {
    await analyze('''
Object/*!*/ _f(dynamic d, int/*?*/ i) => d[i];
''');
    visitSubexpression(findNode.index('d[i]'), 'dynamic');
  }

  Future<void> test_indexExpression_simple() async {
    await analyze('''
class _C {
  int operator[](String s) => 1;
}
_f(_C c) => c['foo'];
''');
    visitSubexpression(findNode.index('c['), 'int');
  }

  Future<void> test_indexExpression_simple_check_lhs() async {
    await analyze('''
class _C {
  int operator[](String s) => 1;
}
_f(_C/*?*/ c) => c['foo'];
''');
    visitSubexpression(findNode.index('c['), 'int',
        changes: {findNode.simple('c['): isNullCheck});
  }

  Future<void> test_indexExpression_simple_check_rhs() async {
    await analyze('''
class _C {
  int operator[](String/*!*/ s) => 1;
}
_f(_C c, String/*?*/ s) => c[s];
''');
    visitSubexpression(findNode.index('c['), 'int',
        changes: {findNode.simple('s]'): isNullCheck});
  }

  Future<void> test_indexExpression_substituted() async {
    await analyze('''
class _C<T, U> {
  T operator[](U u) => throw 'foo';
}
_f(_C<int, String> c) => c['foo'];
''');
    visitSubexpression(findNode.index('c['), 'int');
  }

  Future<void> test_indexExpression_substituted_check_rhs() async {
    await analyze('''
class _C<T, U> {
  T operator[](U/*!*/ u) => throw 'foo';
}
_f(_C<int, String/*!*/> c, String/*?*/ s) => c[s];
''');
    visitSubexpression(findNode.index('c['), 'int',
        changes: {findNode.simple('s]'): isNullCheck});
  }

  Future<void> test_indexExpression_substituted_no_check_rhs() async {
    await analyze('''
class _C<T, U> {
  T operator[](U u) => throw 'foo';
}
_f(_C<int, String/*?*/> c, String/*?*/ s) => c[s];
''');
    visitSubexpression(findNode.index('c['), 'int');
  }

  Future<void> test_integerLiteral() async {
    await analyze('''
f() => 1;
''');
    visitSubexpression(findNode.integerLiteral('1'), 'int');
  }

  Future<void> test_list_ifElement_alive() async {
    await analyze('''
_f(int x, bool b, int/*?*/ y) => [if (b) h(y) else g(y)];
int/*!*/ g(int/*!*/ y) => y;
double/*!*/ h(int/*!*/ y) => y.toDouble();
''');
    visitSubexpression(findNode.listLiteral('['), 'List<num>', changes: {
      findNode.simple('y) else'): isNullCheck,
      findNode.simple('y)]'): isNullCheck
    });
  }

  Future<void> test_list_ifElement_alive_with_null_check() async {
    await analyze('''
_f(int x, bool/*?*/ b, int/*?*/ y) => [if (b == null) h(y) else g(y)];
int/*!*/ g(int/*!*/ y) => y;
double/*!*/ h(int/*!*/ y) => y.toDouble();
''');
    visitSubexpression(findNode.listLiteral('['), 'List<num>', changes: {
      findNode.simple('y) else'): isNullCheck,
      findNode.simple('y)]'): isNullCheck
    });
  }

  Future<void> test_list_ifElement_dead_else() async {
    await analyze('''
_f(int x, int/*?*/ y) => [if (x != null) g(y) else h(y)];
int/*!*/ g(int/*!*/ y) => y;
double/*!*/ h(int/*!*/ y) => y.toDouble();
''');
    visitSubexpression(findNode.listLiteral('['), 'List<int>', changes: {
      findNode.ifElement('null'): isConditionalWithKnownValue(true),
      findNode.simple('y) else'): isNullCheck
    });
  }

  Future<void> test_list_ifElement_dead_else_no_else() async {
    await analyze('''
_f(int x, int/*?*/ y) => [if (x != null) g(y)];
int/*!*/ g(int/*!*/ y) => y;
''');
    visitSubexpression(findNode.listLiteral('['), 'List<int>', changes: {
      findNode.ifElement('null'): isConditionalWithKnownValue(true),
      findNode.simple('y)]'): isNullCheck
    });
  }

  Future<void> test_list_ifElement_dead_then() async {
    await analyze('''
_f(int x, int/*?*/ y) => [if (x == null) h(y) else g(y)];
int/*!*/ g(int/*!*/ y) => y;
double/*!*/ h(int/*!*/ y) => y.toDouble();
''');
    visitSubexpression(findNode.listLiteral('['), 'List<int>', changes: {
      findNode.ifElement('null'): isConditionalWithKnownValue(false),
      findNode.simple('y)]'): isNullCheck
    });
  }

  Future<void> test_list_ifElement_dead_then_no_else() async {
    // TODO(paulberry): rather than infer the type to be List<dynamic>,
    // FixBuilder should add an explicit type argument to ensure that it is
    // still List<int>.
    await analyze('''
_f(int x, int/*?*/ y) => [if (x == null) h(y)];
double/*!*/ h(int/*!*/ y) => y.toDouble();
''');
    visitSubexpression(findNode.listLiteral('['), 'List<dynamic>', changes: {
      findNode.ifElement('null'): isConditionalWithKnownValue(false)
    });
  }

  Future<void> test_list_make_explicit_type_nullable() async {
    await analyze('_f() => <int>[null];');
    // The `null` should be analyzed with a context type of `int?`, so it should
    // not be null-checked.
    visitSubexpression(findNode.listLiteral('['), 'List<int?>',
        changes: {findNode.typeAnnotation('int'): isMakeNullable});
  }

  Future<void> test_list_unchanged() async {
    await analyze('_f(int x) => [x];');
    visitSubexpression(findNode.listLiteral('['), 'List<int>');
  }

  Future<void> test_listLiteral_typed() async {
    await analyze('''
_f() => <int>[];
''');
    visitSubexpression(findNode.listLiteral('['), 'List<int>');
  }

  Future<void> test_listLiteral_typed_visit_contents() async {
    await analyze('''
_f(int/*?*/ x) => <int/*!*/>[x];
''');
    visitSubexpression(findNode.listLiteral('['), 'List<int>',
        changes: {findNode.simple('x]'): isNullCheck});
  }

  Future<void> test_map_ifElement_alive() async {
    await analyze('''
_f(int x, bool b, int/*?*/ y) => {if (b) 0: h(y) else 0: g(y)};
int/*!*/ g(int/*!*/ y) => y;
double/*!*/ h(int/*!*/ y) => y.toDouble();
''');
    visitSubexpression(findNode.setOrMapLiteral('{'), 'Map<int, num>',
        changes: {
          findNode.simple('y) else'): isNullCheck,
          findNode.simple('y)}'): isNullCheck
        });
  }

  Future<void> test_map_ifElement_alive_with_null_check() async {
    await analyze('''
_f(int x, bool/*?*/ b, int/*?*/ y) => {if (b == null) 0: h(y) else 0: g(y)};
int/*!*/ g(int/*!*/ y) => y;
double/*!*/ h(int/*!*/ y) => y.toDouble();
''');
    visitSubexpression(findNode.setOrMapLiteral('{'), 'Map<int, num>',
        changes: {
          findNode.simple('y) else'): isNullCheck,
          findNode.simple('y)}'): isNullCheck
        });
  }

  Future<void> test_map_ifElement_dead_else() async {
    await analyze('''
_f(int x, int/*?*/ y) => {if (x != null) 0: g(y) else 0: h(y)};
int/*!*/ g(int/*!*/ y) => y;
double/*!*/ h(int/*!*/ y) => y.toDouble();
''');
    visitSubexpression(findNode.setOrMapLiteral('{'), 'Map<int, int>',
        changes: {
          findNode.ifElement('null'): isConditionalWithKnownValue(true),
          findNode.simple('y) else'): isNullCheck
        });
  }

  Future<void> test_map_ifElement_dead_else_no_else() async {
    await analyze('''
_f(int x, int/*?*/ y) => {if (x != null) 0: g(y)};
int/*!*/ g(int/*!*/ y) => y;
''');
    visitSubexpression(findNode.setOrMapLiteral('{'), 'Map<int, int>',
        changes: {
          findNode.ifElement('null'): isConditionalWithKnownValue(true),
          findNode.simple('y)}'): isNullCheck
        });
  }

  Future<void> test_map_ifElement_dead_then() async {
    await analyze('''
_f(int x, int/*?*/ y) => {if (x == null) 0: h(y) else 0: g(y)};
int/*!*/ g(int/*!*/ y) => y;
double/*!*/ h(int/*!*/ y) => y.toDouble();
''');
    visitSubexpression(findNode.setOrMapLiteral('{'), 'Map<int, int>',
        changes: {
          findNode.ifElement('null'): isConditionalWithKnownValue(false),
          findNode.simple('y)}'): isNullCheck
        });
  }

  Future<void> test_map_ifElement_dead_then_no_else() async {
    // TODO(paulberry): rather than infer the type to be Map<dynamic, dynamic>,
    // FixBuilder should add an explicit type argument to ensure that it is
    // still Map<int, int>.
    await analyze('''
_f(int x, int/*?*/ y) => {if (x == null) 0: h(y)};
double/*!*/ h(int/*!*/ y) => y.toDouble();
''');
    visitSubexpression(findNode.setOrMapLiteral('{'), 'Map<dynamic, dynamic>',
        changes: {
          findNode.ifElement('null'): isConditionalWithKnownValue(false)
        });
  }

  Future<void> test_map_make_explicit_key_type_nullable() async {
    await analyze('_f() => <int, double>{null: 0.0};');
    // The `null` should be analyzed with a context type of `int?`, so it should
    // not be null-checked.
    visitSubexpression(findNode.setOrMapLiteral('{'), 'Map<int?, double>',
        changes: {findNode.typeAnnotation('int'): isMakeNullable});
  }

  Future<void> test_map_make_explicit_value_type_nullable() async {
    await analyze('_f() => <double, int>{0.0: null};');
    // The `null` should be analyzed with a context type of `int?`, so it should
    // not be null-checked.
    visitSubexpression(findNode.setOrMapLiteral('{'), 'Map<double, int?>',
        changes: {findNode.typeAnnotation('int'): isMakeNullable});
  }

  Future<void> test_methodInvocation_dynamic() async {
    await analyze('''
Object/*!*/ _f(dynamic d) => d.f();
''');
    visitSubexpression(findNode.methodInvocation('d.f'), 'dynamic');
  }

  Future<void> test_methodInvocation_namedParameter() async {
    await analyze('''
abstract class _C {
  int f({int/*!*/ x});
}
_f(_C c, int/*?*/ y) => c.f(x: y);
''');
    visitSubexpression(findNode.methodInvocation('c.f'), 'int',
        changes: {findNode.simple('y);'): isNullCheck});
  }

  Future<void> test_methodInvocation_ordinaryParameter() async {
    await analyze('''
abstract class _C {
  int f(int/*!*/ x);
}
_f(_C c, int/*?*/ y) => c.f(y);
''');
    visitSubexpression(findNode.methodInvocation('c.f'), 'int',
        changes: {findNode.simple('y);'): isNullCheck});
  }

  Future<void> test_methodInvocation_return_nonNullable() async {
    await analyze('''
abstract class _C {
  int f();
}
_f(_C c) => c.f();
''');
    visitSubexpression(findNode.methodInvocation('c.f'), 'int');
  }

  Future<void> test_methodInvocation_return_nonNullable_check_target() async {
    await analyze('''
abstract class _C {
  int f();
}
_f(_C/*?*/ c) => c.f();
''');
    visitSubexpression(findNode.methodInvocation('c.f'), 'int',
        changes: {findNode.simple('c.f'): isNullCheck});
  }

  Future<void> test_methodInvocation_return_nonNullable_nullAware() async {
    await analyze('''
abstract class _C {
  int f();
}
_f(_C/*?*/ c) => c?.f();
''');
    visitSubexpression(findNode.methodInvocation('c?.f'), 'int?');
  }

  Future<void> test_methodInvocation_return_nullable() async {
    await analyze('''
abstract class _C {
  int/*?*/ f();
}
_f(_C c) => c.f();
''');
    visitSubexpression(findNode.methodInvocation('c.f'), 'int?');
  }

  Future<void> test_methodInvocation_static() async {
    await analyze('''
_f() => _C.g();
class _C {
  static int g() => 1;
}
''');
    visitSubexpression(findNode.methodInvocation('_C.g();'), 'int');
  }

  Future<void> test_methodInvocation_topLevel() async {
    await analyze('''
_f() => _g();
int _g() => 1;
''');
    visitSubexpression(findNode.methodInvocation('_g();'), 'int');
  }

  Future<void> test_methodInvocation_toString() async {
    await analyze('''
abstract class _C {}
_f(_C/*?*/ c) => c.toString();
''');
    visitSubexpression(findNode.methodInvocation('c.toString'), 'String');
  }

  Future<void> test_null_aware_assignment_non_nullable_source() async {
    await analyze('''
abstract class C {
  int/*!*/ f();
  g(int/*!*/ x) {
    x ??= f();
  }
}
''');
    var assignment = findNode.assignment('??=');
    visitSubexpression(assignment, 'int',
        changes: {assignment: isWeakNullAwareAssignment});
  }

  Future<void> test_null_aware_assignment_nullable_rhs_needs_check() async {
    await analyze('''
abstract class C {
  void set x(int/*!*/ value);
  int/*?*/ get x;
  int/*?*/ f();
  g() {
    x ??= f();
  }
}
''');
    var assignment = findNode.assignment('??=');
    visitSubexpression(assignment, 'int',
        changes: {assignment.rightHandSide: isNullCheck});
  }

  Future<void> test_null_aware_assignment_nullable_rhs_ok() async {
    await analyze('''
abstract class C {
  int/*?*/ f();
  g(int/*?*/ x) {
    x ??= f();
  }
}
''');
    var assignment = findNode.assignment('??=');
    visitSubexpression(assignment, 'int?');
  }

  Future<void> test_nullable_value_in_null_context() async {
    await analyze('int/*!*/ f(int/*?*/ i) => i;');
    var iRef = findNode.simple('i;');
    visitSubexpression(iRef, 'int', changes: {
      iRef: isNodeChangeForExpression.havingNullCheckWithInfo(isInfo(
          NullabilityFixDescription.checkExpression,
          {FixReasonTarget.root: TypeMatcher<NullabilityEdge>()}))
    });
  }

  Future<void> test_nullAssertion_promotes() async {
    await analyze('''
_f(bool/*?*/ x) => x && x;
''');
    // Only the first `x` is null-checked because thereafter, the type of `x` is
    // promoted to `bool`.
    visitSubexpression(findNode.binary('&&'), 'bool',
        changes: {findNode.simple('x &&'): isNullCheck});
  }

  Future<void> test_nullLiteral() async {
    await analyze('''
f() => null;
''');
    visitSubexpression(findNode.nullLiteral('null'), 'Null');
  }

  Future<void> test_nullLiteral_hinted() async {
    await analyze('''
int/*!*/ f() => null/*!*/;
''');
    var literal = findNode.nullLiteral('null');
    // Normally we would leave the null literal alone and add an informative
    // comment saying there's no valid migration for it.  But since the user
    // specifically hinted that `!` should be added, we respect that.
    visitSubexpression(literal, 'Never', changes: {
      literal: isNodeChangeForExpression.havingNullCheckWithInfo(isInfo(
          NullabilityFixDescription.checkExpressionDueToHint,
          {FixReasonTarget.root: TypeMatcher<FixReason_NullCheckHint>()}))
    });
  }

  Future<void> test_nullLiteral_noValidMigration() async {
    await analyze('''
int/*!*/ f() => null;
''');
    var literal = findNode.nullLiteral('null');
    // Note: in spite of the fact that we leave the literal as `null`, we
    // analyze it as though it has type `Never`, because it's in a context where
    // `null` doesn't work.
    visitSubexpression(literal, 'Never', changes: {
      literal: isNodeChangeForExpression.havingNoValidMigrationWithInfo(isInfo(
          NullabilityFixDescription.noValidMigrationForNull,
          {FixReasonTarget.root: TypeMatcher<NullabilityEdge>()}))
    });
  }

  Future<void> test_parenthesizedExpression() async {
    await analyze('''
f() => (1);
''');
    visitSubexpression(findNode.integerLiteral('1'), 'int');
  }

  Future<void> test_parenthesizedExpression_flow() async {
    await analyze('''
_f(bool/*?*/ x) => ((x) != (null)) && x;
''');
    visitSubexpression(findNode.binary('&&'), 'bool');
  }

  Future<void> test_post_decrement_int_behavior() async {
    await analyze('''
_f(int x) => x--;
''');
    // It's not a problem that int.operator- returns `num` (which is not
    // assignable to `int`) because the value implicitly passed to operator- has
    // type `int`, so the static type of the result is `int`.
    visitSubexpression(findNode.postfix('--'), 'int');
  }

  Future<void> test_post_increment_int_behavior() async {
    await analyze('''
_f(int x) => x++;
''');
    // It's not a problem that int.operator+ returns `num` (which is not
    // assignable to `int`) because the value implicitly passed to operator- has
    // type `int`, so the static type of the result is `int`.
    visitSubexpression(findNode.postfix('++'), 'int');
  }

  Future<void> test_post_increment_null_shorted_ok() async {
    await analyze('''
class C {
  int/*!*/ x;
}
_f(C/*?*/ c) {
  c?.x++;
}
''');
    // Even though c?.x is nullable, it should not be a problem to use it as the
    // target of a post-increment, because null shorting will ensure that the
    // increment only happens if c is non-null.
    var increment = findNode.postfix('++');
    visitSubexpression(increment, 'int?');
  }

  Future<void> test_post_increment_nullable_result_bad() async {
    await analyze('''
abstract class C {
  C/*?*/ operator+(int i);
}
f(C c) {
  c++;
}
''');
    var increment = findNode.postfix('++');
    visitSubexpression(increment, 'C', changes: {increment: isBadCombinedType});
  }

  Future<void> test_post_increment_nullable_result_ok() async {
    await analyze('''
abstract class C {
  C/*?*/ operator+(int i);
}
abstract class D {
  void set x(C/*?*/ value);
  C/*!*/ get x;
  f() {
    x++;
  }
}
''');
    var increment = findNode.postfix('++');
    visitSubexpression(increment, 'C');
  }

  Future<void> test_post_increment_nullable_source() async {
    await analyze('''
_f(int/*?*/ x) {
  x++;
}
''');
    var increment = findNode.postfix('++');
    visitSubexpression(increment, 'int?',
        changes: {increment: isNullableSource});
  }

  Future<void> test_post_increment_potentially_nullable_source() async {
    await analyze('''
class C<T extends num/*?*/> {
  _f(T/*!*/ x) {
    x++;
  }
}
''');
    var increment = findNode.postfix('++');
    visitSubexpression(increment, 'T', changes: {increment: isNullableSource});
  }

  Future<void> test_post_increment_promoted_ok() async {
    await analyze('''
abstract class C {
  C/*?*/ operator+(int i);
}
f(C/*?*/ x) {
  if (x != null) {
    x++;
  }
}
''');
    // The increment is ok, because:
    // - prior to the increment, x's value is promoted to non-nullable
    // - the nullable return value of operator+ is ok to assign to x, because it
    //   un-does the promotion.
    visitSubexpression(findNode.postfix('++'), 'C');
  }

  Future<void> test_postfixExpression_combined_nullable_noProblem() async {
    await analyze('''
abstract class _C {
  _D/*?*/ operator+(int/*!*/ value);
}
abstract class _D extends _C {}
abstract class _E {
  _C/*!*/ get x;
  void set x(_C/*?*/ value);
  f() => x++;
}
''');
    visitSubexpression(findNode.postfix('++'), '_C');
  }

  Future<void>
      test_postfixExpression_combined_nullable_noProblem_dynamic() async {
    await analyze('''
abstract class _E {
  dynamic get x;
  void set x(Object/*!*/ value);
  f() => x++;
}
''');
    visitSubexpression(findNode.postfix('++'), 'dynamic');
  }

  @FailingTest(reason: 'TODO(paulberry)')
  Future<void> test_postfixExpression_combined_nullable_problem() async {
    await analyze('''
abstract class _C {
  _D/*?*/ operator+(int/*!*/ value);
}
abstract class _D extends _C {}
abstract class _E {
  _C/*!*/ get x;
  void set x(_C/*!*/ value);
  f() => x++;
}
''');
    var postfix = findNode.postfix('++');
    visitSubexpression(postfix, '_C', problems: {
      postfix: {const CompoundAssignmentCombinedNullable()}
    });
  }

  Future<void> test_postfixExpression_decrement_undoes_promotion() async {
    await analyze('''
abstract class _C {
  _C/*?*/ operator-(int value);
}
_f(_C/*?*/ c) { // method
  if (c != null) {
    c--;
    _g(c);
  }
}
_g(_C/*!*/ c) {}
''');
    visitStatement(findNode.block('{ // method'),
        changes: {findNode.simple('c);'): isNullCheck});
  }

  Future<void> test_postfixExpression_dynamic() async {
    await analyze('''
_f(dynamic x) => x++;
''');
    visitSubexpression(findNode.postfix('++'), 'dynamic');
  }

  Future<void> test_postfixExpression_increment_undoes_promotion() async {
    await analyze('''
abstract class _C {
  _C/*?*/ operator+(int value);
}
_f(_C/*?*/ c) { // method
  if (c != null) {
    c++;
    _g(c);
  }
}
_g(_C/*!*/ c) {}
''');
    visitStatement(findNode.block('{ // method'),
        changes: {findNode.simple('c);'): isNullCheck});
  }

  @FailingTest(reason: 'TODO(paulberry)')
  Future<void> test_postfixExpression_lhs_nullable_problem() async {
    await analyze('''
abstract class _C {
  _D/*!*/ operator+(int/*!*/ value);
}
abstract class _D extends _C {}
abstract class _E {
  _C/*?*/ get x;
  void set x(_C/*?*/ value);
  f() => x++;
}
''');
    var postfix = findNode.postfix('++');
    visitSubexpression(postfix, '_C?', problems: {
      postfix: {const CompoundAssignmentReadNullable()}
    });
  }

  Future<void> test_postfixExpression_rhs_nonNullable() async {
    await analyze('''
abstract class _C {
  _D/*!*/ operator+(int/*!*/ value);
}
abstract class _D extends _C {}
_f(_C/*!*/ x) => x++;
''');
    visitSubexpression(findNode.postfix('++'), '_C');
  }

  Future<void> test_pre_decrement_int_behavior() async {
    await analyze('''
_f(int x) => --x;
''');
    // It's not a problem that int.operator- returns `num` (which is not
    // assignable to `int`) because the value implicitly passed to operator- has
    // type `int`, so the static type of the result is `int`.
    visitSubexpression(findNode.prefix('--'), 'int');
  }

  Future<void> test_pre_increment_int_behavior() async {
    await analyze('''
_f(int x) => ++x;
''');
    // It's not a problem that int.operator+ returns `num` (which is not
    // assignable to `int`) because the value implicitly passed to operator- has
    // type `int`, so the static type of the result is `int`.
    visitSubexpression(findNode.prefix('++'), 'int');
  }

  Future<void> test_pre_increment_null_shorted_ok() async {
    await analyze('''
class C {
  int/*!*/ x;
}
_f(C/*?*/ c) {
  ++c?.x;
}
''');
    // Even though c?.x is nullable, it should not be a problem to use it as the
    // target of a pre-increment, because null shorting will ensure that the
    // increment only happens if c is non-null.
    var increment = findNode.prefix('++');
    visitSubexpression(increment, 'int?');
  }

  Future<void> test_pre_increment_nullable_result_bad() async {
    await analyze('''
abstract class C {
  C/*?*/ operator+(int i);
}
f(C c) {
  ++c;
}
''');
    var increment = findNode.prefix('++');
    visitSubexpression(increment, 'C?',
        changes: {increment: isBadCombinedType});
  }

  Future<void> test_pre_increment_nullable_result_ok() async {
    await analyze('''
abstract class C {
  C/*?*/ operator+(int i);
}
abstract class D {
  void set x(C/*?*/ value);
  C/*!*/ get x;
  f() {
    ++x;
  }
}
''');
    var increment = findNode.prefix('++');
    visitSubexpression(increment, 'C?');
  }

  Future<void> test_pre_increment_nullable_source() async {
    await analyze('''
_f(int/*?*/ x) {
  ++x;
}
''');
    var increment = findNode.prefix('++');
    visitSubexpression(increment, 'int',
        changes: {increment: isNullableSource});
  }

  Future<void> test_pre_increment_potentially_nullable_source() async {
    await analyze('''
class C<T extends num/*?*/> {
  _f(T/*!*/ x) {
    ++x;
  }
}
''');
    var increment = findNode.prefix('++');
    visitSubexpression(increment, 'num',
        changes: {increment: isNullableSource});
  }

  Future<void> test_pre_increment_promoted_ok() async {
    await analyze('''
abstract class C {
  C/*?*/ operator+(int i);
}
f(C/*?*/ x) {
  if (x != null) {
    ++x;
  }
}
''');
    // The increment is ok, because:
    // - prior to the increment, x's value is promoted to non-nullable
    // - the nullable return value of operator+ is ok to assign to x, because it
    //   un-does the promotion.
    visitSubexpression(findNode.prefix('++'), 'C?');
  }

  Future<void> test_prefixedIdentifier_dynamic() async {
    await analyze('''
Object/*!*/ _f(dynamic d) => d.x;
''');
    visitSubexpression(findNode.prefixed('d.x'), 'dynamic');
  }

  Future<void> test_prefixedIdentifier_field_nonNullable() async {
    await analyze('''
class _C {
  int/*!*/ x = 0;
}
_f(_C c) => c.x;
''');
    visitSubexpression(findNode.prefixed('c.x'), 'int');
  }

  Future<void> test_prefixedIdentifier_field_nullable() async {
    await analyze('''
class _C {
  int/*?*/ x = 0;
}
_f(_C c) => c.x;
''');
    visitSubexpression(findNode.prefixed('c.x'), 'int?');
  }

  Future<void> test_prefixedIdentifier_getter_check_lhs() async {
    await analyze('''
abstract class _C {
  int get x;
}
_f(_C/*?*/ c) => c.x;
''');
    visitSubexpression(findNode.prefixed('c.x'), 'int',
        changes: {findNode.simple('c.x'): isNullCheck});
  }

  Future<void> test_prefixedIdentifier_getter_nonNullable() async {
    await analyze('''
abstract class _C {
  int/*!*/ get x;
}
_f(_C c) => c.x;
''');
    visitSubexpression(findNode.prefixed('c.x'), 'int');
  }

  Future<void> test_prefixedIdentifier_getter_nullable() async {
    await analyze('''
abstract class _C {
  int/*?*/ get x;
}
_f(_C c) => c.x;
''');
    visitSubexpression(findNode.prefixed('c.x'), 'int?');
  }

  Future<void> test_prefixedIdentifier_object_getter() async {
    await analyze('''
class _C {}
_f(_C/*?*/ c) => c.hashCode;
''');
    visitSubexpression(findNode.prefixed('c.hashCode'), 'int');
  }

  Future<void> test_prefixedIdentifier_object_tearoff() async {
    await analyze('''
class _C {}
_f(_C/*?*/ c) => c.toString;
''');
    visitSubexpression(findNode.prefixed('c.toString'), 'String Function()');
  }

  Future<void> test_prefixedIdentifier_substituted() async {
    await analyze('''
abstract class _C<T> {
  List<T> get x;
}
_f(_C<int> c) => c.x;
''');
    visitSubexpression(findNode.prefixed('c.x'), 'List<int>');
  }

  Future<void> test_prefixExpression_bang_flow() async {
    await analyze('''
_f(int/*?*/ x) {
  if (!(x == null)) {
    x + 1;
  }
}
''');
    // No null check should be needed on `x + 1` because `!(x == null)` promotes
    // x's type to `int`.
    visitStatement(findNode.statement('if'));
  }

  Future<void> test_prefixExpression_bang_nonNullable() async {
    await analyze('''
_f(bool/*!*/ x) => !x;
''');
    visitSubexpression(findNode.prefix('!x'), 'bool');
  }

  Future<void> test_prefixExpression_bang_nullable() async {
    await analyze('''
_f(bool/*?*/ x) => !x;
''');
    visitSubexpression(findNode.prefix('!x'), 'bool',
        changes: {findNode.simple('x;'): isNullCheck});
  }

  Future<void> test_prefixExpression_combined_nullable_noProblem() async {
    await analyze('''
abstract class _C {
  _D/*?*/ operator+(int/*!*/ value);
}
abstract class _D extends _C {}
abstract class _E {
  _C/*!*/ get x;
  void set x(_C/*?*/ value);
  f() => ++x;
}
''');
    visitSubexpression(findNode.prefix('++'), '_D?');
  }

  Future<void>
      test_prefixExpression_combined_nullable_noProblem_dynamic() async {
    await analyze('''
abstract class _E {
  dynamic get x;
  void set x(Object/*!*/ value);
  f() => ++x;
}
''');
    var prefix = findNode.prefix('++');
    visitSubexpression(prefix, 'dynamic');
  }

  @FailingTest(reason: 'TODO(paulberry)')
  Future<void> test_prefixExpression_combined_nullable_problem() async {
    await analyze('''
abstract class _C {
  _D/*?*/ operator+(int/*!*/ value);
}
abstract class _D extends _C {}
abstract class _E {
  _C/*!*/ get x;
  void set x(_C/*!*/ value);
  f() => ++x;
}
''');
    var prefix = findNode.prefix('++');
    visitSubexpression(prefix, '_D', problems: {
      prefix: {const CompoundAssignmentCombinedNullable()}
    });
  }

  Future<void> test_prefixExpression_decrement_undoes_promotion() async {
    await analyze('''
abstract class _C {
  _C/*?*/ operator-(int value);
}
_f(_C/*?*/ c) { // method
  if (c != null) {
    --c;
    _g(c);
  }
}
_g(_C/*!*/ c) {}
''');
    visitStatement(findNode.block('{ // method'),
        changes: {findNode.simple('c);'): isNullCheck});
  }

  Future<void> test_prefixExpression_increment_undoes_promotion() async {
    await analyze('''
abstract class _C {
  _C/*?*/ operator+(int value);
}
_f(_C/*?*/ c) { // method
  if (c != null) {
    ++c;
    _g(c);
  }
}
_g(_C/*!*/ c) {}
''');
    visitStatement(findNode.block('{ // method'),
        changes: {findNode.simple('c);'): isNullCheck});
  }

  Future<void> test_prefixExpression_intRules() async {
    await analyze('''
_f(int x) => ++x;
''');
    visitSubexpression(findNode.prefix('++'), 'int');
  }

  @FailingTest(reason: 'TODO(paulberry)')
  Future<void> test_prefixExpression_lhs_nullable_problem() async {
    await analyze('''
abstract class _C {
  _D/*!*/ operator+(int/*!*/ value);
}
abstract class _D extends _C {}
abstract class _E {
  _C/*?*/ get x;
  void set x(_C/*?*/ value);
  f() => ++x;
}
''');
    var prefix = findNode.prefix('++');
    visitSubexpression(prefix, '_D', problems: {
      prefix: {const CompoundAssignmentReadNullable()}
    });
  }

  Future<void> test_prefixExpression_minus_dynamic() async {
    await analyze('''
_f(dynamic x) => -x;
''');
    visitSubexpression(findNode.prefix('-x'), 'dynamic');
  }

  Future<void> test_prefixExpression_minus_nonNullable() async {
    await analyze('''
_f(int/*!*/ x) => -x;
''');
    visitSubexpression(findNode.prefix('-x'), 'int');
  }

  Future<void> test_prefixExpression_minus_nullable() async {
    await analyze('''
_f(int/*?*/ x) => -x;
''');
    visitSubexpression(findNode.prefix('-x'), 'int',
        changes: {findNode.simple('x;'): isNullCheck});
  }

  Future<void> test_prefixExpression_minus_substitution() async {
    await analyze('''
abstract class _C<T> {
  List<T> operator-();
}
_f(_C<int> x) => -x;
''');
    visitSubexpression(findNode.prefix('-x'), 'List<int>');
  }

  Future<void> test_prefixExpression_rhs_nonNullable() async {
    await analyze('''
abstract class _C {
  _D/*!*/ operator+(int/*!*/ value);
}
abstract class _D extends _C {}
_f(_C/*!*/ x) => ++x;
''');
    visitSubexpression(findNode.prefix('++'), '_D');
  }

  Future<void> test_prefixExpression_tilde_dynamic() async {
    await analyze('''
_f(dynamic x) => ~x;
''');
    visitSubexpression(findNode.prefix('~x'), 'dynamic');
  }

  Future<void> test_prefixExpression_tilde_nonNullable() async {
    await analyze('''
_f(int/*!*/ x) => ~x;
''');
    visitSubexpression(findNode.prefix('~x'), 'int');
  }

  Future<void> test_prefixExpression_tilde_nullable() async {
    await analyze('''
_f(int/*?*/ x) => ~x;
''');
    visitSubexpression(findNode.prefix('~x'), 'int',
        changes: {findNode.simple('x;'): isNullCheck});
  }

  Future<void> test_prefixExpression_tilde_substitution() async {
    await analyze('''
abstract class _C<T> {
  List<T> operator~();
}
_f(_C<int> x) => ~x;
''');
    visitSubexpression(findNode.prefix('~x'), 'List<int>');
  }

  Future<void> test_propertyAccess_dynamic() async {
    await analyze('''
Object/*!*/ _f(dynamic d) => (d).x;
''');
    visitSubexpression(findNode.propertyAccess('(d).x'), 'dynamic');
  }

  Future<void> test_propertyAccess_field_nonNullable() async {
    await analyze('''
class _C {
  int/*!*/ x = 0;
}
_f(_C c) => (c).x;
''');
    visitSubexpression(findNode.propertyAccess('(c).x'), 'int');
  }

  Future<void> test_propertyAccess_field_nullable() async {
    await analyze('''
class _C {
  int/*?*/ x = 0;
}
_f(_C c) => (c).x;
''');
    visitSubexpression(findNode.propertyAccess('(c).x'), 'int?');
  }

  Future<void> test_propertyAccess_getter_check_lhs() async {
    await analyze('''
abstract class _C {
  int get x;
}
_f(_C/*?*/ c) => (c).x;
''');
    visitSubexpression(findNode.propertyAccess('(c).x'), 'int',
        changes: {findNode.parenthesized('(c).x'): isNullCheck});
  }

  Future<void> test_propertyAccess_getter_nonNullable() async {
    await analyze('''
abstract class _C {
  int/*!*/ get x;
}
_f(_C c) => (c).x;
''');
    visitSubexpression(findNode.propertyAccess('(c).x'), 'int');
  }

  Future<void> test_propertyAccess_getter_nullable() async {
    await analyze('''
abstract class _C {
  int/*?*/ get x;
}
_f(_C c) => (c).x;
''');
    visitSubexpression(findNode.propertyAccess('(c).x'), 'int?');
  }

  Future<void> test_propertyAccess_nullAware_dynamic() async {
    await analyze('''
Object/*!*/ _f(dynamic d) => d?.x;
''');
    visitSubexpression(findNode.propertyAccess('d?.x'), 'dynamic');
  }

  Future<void> test_propertyAccess_nullAware_field_nonNullable() async {
    await analyze('''
class _C {
  int/*!*/ x = 0;
}
_f(_C/*?*/ c) => c?.x;
''');
    visitSubexpression(findNode.propertyAccess('c?.x'), 'int?');
  }

  Future<void> test_propertyAccess_nullAware_field_nullable() async {
    await analyze('''
class _C {
  int/*?*/ x = 0;
}
_f(_C/*?*/ c) => c?.x;
''');
    visitSubexpression(findNode.propertyAccess('c?.x'), 'int?');
  }

  Future<void> test_propertyAccess_nullAware_getter_nonNullable() async {
    await analyze('''
abstract class _C {
  int/*!*/ get x;
}
_f(_C/*?*/ c) => c?.x;
''');
    visitSubexpression(findNode.propertyAccess('c?.x'), 'int?');
  }

  Future<void> test_propertyAccess_nullAware_getter_nullable() async {
    await analyze('''
abstract class _C {
  int/*?*/ get x;
}
_f(_C/*?*/ c) => c?.x;
''');
    visitSubexpression(findNode.propertyAccess('c?.x'), 'int?');
  }

  Future<void> test_propertyAccess_nullAware_object_getter() async {
    await analyze('''
class _C {}
_f(_C/*?*/ c) => c?.hashCode;
''');
    visitSubexpression(findNode.propertyAccess('c?.hashCode'), 'int?');
  }

  Future<void> test_propertyAccess_nullAware_object_tearoff() async {
    await analyze('''
class _C {}
_f(_C/*?*/ c) => c?.toString;
''');
    visitSubexpression(
        findNode.propertyAccess('c?.toString'), 'String Function()?');
  }

  Future<void> test_propertyAccess_nullAware_potentiallyNullable() async {
    // In the code example below, the `?.` is not changed to `.` because `T`
    // might be instantiated to `int?`, in which case the null check is still
    // needed.
    await analyze('''
class C<T extends int/*?*/> {
  f(T t) => t?.isEven;
}
''');
    visitSubexpression(findNode.propertyAccess('?.'), 'bool?');
  }

  Future<void> test_propertyAccess_nullAware_removeNullAwareness() async {
    await analyze('_f(int/*!*/ i) => i?.isEven;');
    var propertyAccess = findNode.propertyAccess('?.');
    visitSubexpression(propertyAccess, 'bool',
        changes: {propertyAccess: isRemoveNullAwareness});
  }

  Future<void>
      test_propertyAccess_nullAware_removeNullAwareness_nullCheck() async {
    await analyze('''
class C {
  int/*?*/ i;
}
int/*!*/ f(C/*!*/ c) => c?.i;
''');
    var propertyAccess = findNode.propertyAccess('?.');
    visitSubexpression(propertyAccess, 'int', changes: {
      propertyAccess: TypeMatcher<NodeChangeForPropertyAccess>()
          .having((c) => c.addsNullCheck, 'addsNullCheck', true)
          .having((c) => c.removeNullAwareness, 'removeNullAwareness', true)
    });
  }

  Future<void> test_propertyAccess_nullAware_substituted() async {
    await analyze('''
abstract class _C<T> {
  List<T> get x;
}
_f(_C<int>/*?*/ c) => c?.x;
''');
    visitSubexpression(findNode.propertyAccess('c?.x'), 'List<int>?');
  }

  Future<void> test_propertyAccess_object_getter() async {
    await analyze('''
class _C {}
_f(_C/*?*/ c) => (c).hashCode;
''');
    visitSubexpression(findNode.propertyAccess('(c).hashCode'), 'int');
  }

  Future<void> test_propertyAccess_object_tearoff() async {
    await analyze('''
class _C {}
_f(_C/*?*/ c) => (c).toString;
''');
    visitSubexpression(
        findNode.propertyAccess('(c).toString'), 'String Function()');
  }

  Future<void> test_propertyAccess_substituted() async {
    await analyze('''
abstract class _C<T> {
  List<T> get x;
}
_f(_C<int> c) => (c).x;
''');
    visitSubexpression(findNode.propertyAccess('(c).x'), 'List<int>');
  }

  Future<void> test_removeLanguageVersionComment() async {
    await analyze('''
// @dart = 2.6
void main() {}
''');
    visitAll(changes: {findNode.unit: isRemoveLanguageVersion});
  }

  Future<void> test_removeLanguageVersionComment_withCopyright() async {
    await analyze('''
// Some copyright notice here...
// @dart = 2.6
void main() {}
''');
    visitAll(changes: {findNode.unit: isRemoveLanguageVersion});
  }

  Future<void> test_set_ifElement_alive() async {
    await analyze('''
_f(int x, bool b, int/*?*/ y) => {if (b) h(y) else g(y)};
int/*!*/ g(int/*!*/ y) => y;
double/*!*/ h(int/*!*/ y) => y.toDouble();
''');
    visitSubexpression(findNode.setOrMapLiteral('{'), 'Set<num>', changes: {
      findNode.simple('y) else'): isNullCheck,
      findNode.simple('y)}'): isNullCheck
    });
  }

  Future<void> test_set_ifElement_alive_with_null_check() async {
    await analyze('''
_f(int x, bool/*?*/ b, int/*?*/ y) => {if (b == null) h(y) else g(y)};
int/*!*/ g(int/*!*/ y) => y;
double/*!*/ h(int/*!*/ y) => y.toDouble();
''');
    visitSubexpression(findNode.setOrMapLiteral('{'), 'Set<num>', changes: {
      findNode.simple('y) else'): isNullCheck,
      findNode.simple('y)}'): isNullCheck
    });
  }

  Future<void> test_set_ifElement_dead_else() async {
    await analyze('''
_f(int x, int/*?*/ y) => {if (x != null) g(y) else h(y)};
int/*!*/ g(int/*!*/ y) => y;
double/*!*/ h(int/*!*/ y) => y.toDouble();
''');
    visitSubexpression(findNode.setOrMapLiteral('{'), 'Set<int>', changes: {
      findNode.ifElement('null'): isConditionalWithKnownValue(true),
      findNode.simple('y) else'): isNullCheck
    });
  }

  Future<void> test_set_ifElement_dead_else_no_else() async {
    await analyze('''
_f(int x, int/*?*/ y) => {if (x != null) g(y)};
int/*!*/ g(int/*!*/ y) => y;
''');
    visitSubexpression(findNode.setOrMapLiteral('{'), 'Set<int>', changes: {
      findNode.ifElement('null'): isConditionalWithKnownValue(true),
      findNode.simple('y)}'): isNullCheck
    });
  }

  Future<void> test_set_ifElement_dead_then() async {
    await analyze('''
_f(int x, int/*?*/ y) => {if (x == null) h(y) else g(y)};
int/*!*/ g(int/*!*/ y) => y;
double/*!*/ h(int/*!*/ y) => y.toDouble();
''');
    visitSubexpression(findNode.setOrMapLiteral('{'), 'Set<int>', changes: {
      findNode.ifElement('null'): isConditionalWithKnownValue(false),
      findNode.simple('y)}'): isNullCheck
    });
  }

  Future<void> test_set_ifElement_dead_then_no_else() async {
    // TODO(paulberry): rather than infer the type to be Map<dynamic, dynamic>,
    // FixBuilder should add an explicit type argument to ensure that it is
    // still Set<int>.
    await analyze('''
_f(int x, int/*?*/ y) => {if (x == null) h(y)};
double/*!*/ h(int/*!*/ y) => y.toDouble();
''');
    visitSubexpression(findNode.setOrMapLiteral('{'), 'Map<dynamic, dynamic>',
        changes: {
          findNode.ifElement('null'): isConditionalWithKnownValue(false)
        });
  }

  Future<void> test_set_make_explicit_type_nullable() async {
    await analyze('_f() => <int>{null};');
    // The `null` should be analyzed with a context type of `int?`, so it should
    // not be null-checked.
    visitSubexpression(findNode.setOrMapLiteral('{'), 'Set<int?>',
        changes: {findNode.typeAnnotation('int'): isMakeNullable});
  }

  Future<void> test_simpleIdentifier_className() async {
    await analyze('''
_f() => int;
''');
    visitSubexpression(findNode.simple('int'), 'Type');
  }

  Future<void> test_simpleIdentifier_field() async {
    await analyze('''
class _C {
  int i = 1;
  f() => i;
}
''');
    visitSubexpression(findNode.simple('i;'), 'int');
  }

  Future<void> test_simpleIdentifier_field_generic() async {
    await analyze('''
class _C<T> {
  List<T> x = null;
  f() => x;
}
''');
    visitSubexpression(findNode.simple('x;'), 'List<T>?');
  }

  Future<void> test_simpleIdentifier_field_nullable() async {
    await analyze('''
class _C {
  int/*?*/ i = 1;
  f() => i;
}
''');
    visitSubexpression(findNode.simple('i;'), 'int?');
  }

  Future<void> test_simpleIdentifier_getter() async {
    await analyze('''
class _C {
  int get i => 1;
  f() => i;
}
''');
    visitSubexpression(findNode.simple('i;'), 'int');
  }

  Future<void> test_simpleIdentifier_getter_nullable() async {
    await analyze('''
class _C {
  int/*?*/ get i => 1;
  f() => i;
}
''');
    visitSubexpression(findNode.simple('i;'), 'int?');
  }

  Future<void> test_simpleIdentifier_localVariable_nonNullable() async {
    await analyze('''
_f(int x) {
  return x;
}
''');
    visitSubexpression(findNode.simple('x;'), 'int');
  }

  Future<void> test_simpleIdentifier_localVariable_nullable() async {
    await analyze('''
_f(int/*?*/ x) {
  return x;
}
''');
    visitSubexpression(findNode.simple('x;'), 'int?');
  }

  Future<void> test_simpleIdentifier_null_check_hint() async {
    await analyze('int/*?*/ _f(int/*?*/ x) => x/*!*/;');
    var xRef = findNode.simple('x/*!*/');
    visitSubexpression(xRef, 'int', changes: {
      xRef: isNodeChangeForExpression.havingNullCheckWithInfo(isInfo(
          NullabilityFixDescription.checkExpressionDueToHint,
          {FixReasonTarget.root: TypeMatcher<FixReason_NullCheckHint>()}))
    });
  }

  Future<void> test_stringLiteral() async {
    await analyze('''
f() => 'foo';
''');
    visitSubexpression(findNode.stringLiteral("'foo'"), 'String');
  }

  Future<void> test_suspicious_cast() async {
    await analyze('''
int f(Object o) {
  if (o is! String) return 0;
  return o;
}
''');
    var xRef = findNode.simple('o;');
    visitSubexpression(xRef, 'int', changes: {
      xRef: isNodeChangeForExpression.havingIndroduceAsWithInfo(
          'int',
          isInfo(NullabilityFixDescription.otherCastExpression,
              {FixReasonTarget.root: isEdge}))
    });
  }

  Future<void> test_symbolLiteral() async {
    await analyze('''
f() => #foo;
''');
    visitSubexpression(findNode.symbolLiteral('#foo'), 'Symbol');
  }

  Future<void> test_throw_flow() async {
    await analyze('''
_f(int/*?*/ i) {
  if (i == null) throw 'foo';
  i + 1;
}
''');
    visitStatement(findNode.block('{'));
  }

  Future<void> test_throw_nullable() async {
    await analyze('''
_f(int/*?*/ i) => throw i;
''');
    visitSubexpression(findNode.throw_('throw'), 'Never',
        changes: {findNode.simple('i;'): isNullCheck});
  }

  Future<void> test_throw_simple() async {
    await analyze('''
_f() => throw 'foo';
''');
    visitSubexpression(findNode.throw_('throw'), 'Never');
  }

  Future<void> test_typeName_dynamic() async {
    await analyze('''
void _f() {
  dynamic d = null;
}
''');
    visitTypeAnnotation(findNode.typeAnnotation('dynamic'), 'dynamic');
  }

  Future<void> test_typeName_futureOr_dynamic_nullable() async {
    await analyze('''
import 'dart:async';
void _f() {
  FutureOr<dynamic> x = null;
}
''');
    // The type of `x` should be `FutureOr<dynamic>?`, but this is equivalent to
    // `FutureOr<dynamic>`, so we don't add a `?`.  Note: expected type is
    // still `FutureOr<dynamic>?`; we don't go to extra effort to remove the
    // redundant `?` from the internal type representation, just from the source
    // code we generate.
    visitTypeAnnotation(
        findNode.typeAnnotation('FutureOr<dynamic> x'), 'FutureOr<dynamic>?',
        changes: {});
  }

  Future<void> test_typeName_futureOr_inner() async {
    await analyze('''
import 'dart:async';
void _f(FutureOr<int/*?*/> x) {
  FutureOr<int> y = x;
}
''');
    visitTypeAnnotation(
        findNode.typeAnnotation('FutureOr<int> y'), 'FutureOr<int?>',
        changes: {findNode.typeAnnotation('int> y'): isMakeNullable});
  }

  Future<void> test_typeName_futureOr_null_nullable() async {
    await analyze('''
import 'dart:async';
void _f() {
  FutureOr<Null> x = null;
}
''');
    // The type of `x` should be `FutureOr<Null>?`, but this is equivalent to
    // `FutureOr<Null>`, so we don't add a `?`.  Note: expected type is
    // still `FutureOr<Null>?`; we don't go to extra effort to remove the
    // redundant `?` from the internal type representation, just from the source
    // code we generate.
    visitTypeAnnotation(
        findNode.typeAnnotation('FutureOr<Null> x'), 'FutureOr<Null>?',
        changes: {});
  }

  Future<void> test_typeName_futureOr_outer() async {
    await analyze('''
import 'dart:async';
void _f(FutureOr<int>/*?*/ x) {
  FutureOr<int> y = x;
}
''');
    var typeAnnotation = findNode.typeAnnotation('FutureOr<int> y');
    visitTypeAnnotation(typeAnnotation, 'FutureOr<int>?',
        changes: {typeAnnotation: isMakeNullable});
  }

  Future<void> test_typeName_futureOr_redundant() async {
    await analyze('''
import 'dart:async';
void _f(bool b, FutureOr<int>/*?*/ x, FutureOr<int/*?*/> y) {
  FutureOr<int> z = b ? x : y;
}
''');
    // The type of `z` should be `FutureOr<int?>?`, but this is equivalent to
    // `FutureOr<int?>`, so we only add the first `?`.  Note: expected type is
    // still `FutureOr<int?>?`; we don't go to extra effort to remove the
    // redundant `?` from the internal type representation, just from the source
    // code we generate.
    visitTypeAnnotation(
        findNode.typeAnnotation('FutureOr<int> z'), 'FutureOr<int?>?',
        changes: {findNode.typeAnnotation('int> z'): isMakeNullable});
  }

  Future<void> test_typeName_futureOr_void_nullable() async {
    await analyze('''
import 'dart:async';
void _f() {
  FutureOr<void> x = null;
}
''');
    // The type of `x` should be `FutureOr<void>?`, but this is equivalent to
    // `FutureOr<void>`, so we don't add a `?`.  Note: expected type is
    // still `FutureOr<void>?`; we don't go to extra effort to remove the
    // redundant `?` from the internal type representation, just from the source
    // code we generate.
    visitTypeAnnotation(
        findNode.typeAnnotation('FutureOr<void> x'), 'FutureOr<void>?',
        changes: {});
  }

  Future<void> test_typeName_generic_nonNullable() async {
    await analyze('''
void _f() {
  List<int> i = [0];
}
''');
    visitTypeAnnotation(findNode.typeAnnotation('List<int>'), 'List<int>');
  }

  Future<void> test_typeName_generic_nullable() async {
    await analyze('''
void _f() {
  List<int> i = null;
}
''');
    var listIntAnnotation = findNode.typeAnnotation('List<int>');
    visitTypeAnnotation(listIntAnnotation, 'List<int>?',
        changes: {listIntAnnotation: isMakeNullable});
  }

  Future<void> test_typeName_generic_nullable_arg() async {
    await analyze('''
void _f() {
  List<int> i = [null];
}
''');
    visitTypeAnnotation(findNode.typeAnnotation('List<int>'), 'List<int?>',
        changes: {findNode.typeAnnotation('int'): isMakeNullable});
  }

  Future<void> test_typeName_generic_nullable_arg_and_outer() async {
    await analyze('''
void _f(bool b) {
  List<int> i = b ? [null] : null;
}
''');
    var listInt = findNode.typeAnnotation('List<int>');
    visitTypeAnnotation(listInt, 'List<int?>?', changes: {
      findNode.typeAnnotation('int'): isMakeNullable,
      listInt: isMakeNullable
    });
  }

  Future<void> test_typeName_simple_nonNullable() async {
    await analyze('''
void _f() {
  int i = 0;
}
''');
    var typeAnnotation = findNode.typeAnnotation('int');
    visitTypeAnnotation(typeAnnotation, 'int',
        informative: {typeAnnotation: isExplainNonNullable});
  }

  Future<void> test_typeName_simple_nonNullable_by_context() async {
    await analyze('''
class C extends Object {}
''');
    visitTypeAnnotation(findNode.typeAnnotation('Object'), 'Object',
        informative: isEmpty);
  }

  Future<void> test_typeName_simple_nullable() async {
    await analyze('''
void _f() {
  int i = null;
}
''');
    var intAnnotation = findNode.typeAnnotation('int');
    visitTypeAnnotation((intAnnotation), 'int?',
        changes: {intAnnotation: isMakeNullable});
  }

  Future<void> test_typeName_void() async {
    await analyze('''
void _f() {
  return;
}
''');
    visitTypeAnnotation(findNode.typeAnnotation('void'), 'void');
  }

  Future<void> test_use_of_dynamic() async {
    // Use of `dynamic` in a context requiring non-null is not explicitly null
    // checked.
    await analyze('''
bool _f(dynamic d, bool b) => d && b;
''');
    visitSubexpression(findNode.binary('&&'), 'bool');
  }

  Future<void> test_variableDeclaration_typed_initialized_nonNullable() async {
    await analyze('''
void _f() {
  int x = 0;
}
''');
    visitStatement(findNode.statement('int x'));
  }

  Future<void> test_variableDeclaration_typed_initialized_nullable() async {
    await analyze('''
void _f() {
  int x = null;
}
''');
    visitStatement(findNode.statement('int x'),
        changes: {findNode.typeAnnotation('int'): isMakeNullable});
  }

  Future<void> test_variableDeclaration_typed_uninitialized() async {
    await analyze('''
void _f() {
  int x;
}
''');
    visitStatement(findNode.statement('int x'));
  }

  Future<void> test_variableDeclaration_untyped_initialized() async {
    await analyze('''
void _f() {
  var x = 0;
}
''');
    visitStatement(findNode.statement('var x'));
  }

  Future<void> test_variableDeclaration_untyped_uninitialized() async {
    await analyze('''
void _f() {
  var x;
}
''');
    visitStatement(findNode.statement('var x'));
  }

  Future<void> test_variableDeclaration_visit_initializer() async {
    await analyze('''
void _f(bool/*?*/ x, bool/*?*/ y) {
  bool z = x && y;
}
''');
    visitStatement(findNode.statement('bool z'), changes: {
      findNode.simple('x &&'): isNullCheck,
      findNode.simple('y;'): isNullCheck
    });
  }

  void visitAll(
      {Map<AstNode, Matcher> changes = const <Expression, Matcher>{},
      Map<AstNode, Set<Problem>> problems = const <AstNode, Set<Problem>>{},
      bool injectNeedsIterableExtension = false}) {
    var fixBuilder = _createFixBuilder(testUnit);
    if (injectNeedsIterableExtension) {
      fixBuilder.needsIterableExtension = true;
    }
    fixBuilder.visitAll();
    expect(scopedChanges(fixBuilder, testUnit), changes);
    expect(scopedProblems(fixBuilder, testUnit), problems);
  }

  void visitAssignmentTarget(
      Expression node, String expectedReadType, String expectedWriteType,
      {Map<AstNode, Matcher> changes = const <Expression, Matcher>{},
      Map<AstNode, Set<Problem>> problems = const <AstNode, Set<Problem>>{}}) {
    var fixBuilder = _createFixBuilder(node);
    fixBuilder.visitAll();
    var targetInfo = _computeAssignmentTargetInfo(node, fixBuilder);
    if (expectedReadType == null) {
      expect(targetInfo.readType, null);
    } else {
      expect(targetInfo.readType.getDisplayString(withNullability: true),
          expectedReadType);
    }
    expect(targetInfo.writeType.getDisplayString(withNullability: true),
        expectedWriteType);
    expect(scopedChanges(fixBuilder, node), changes);
    expect(scopedProblems(fixBuilder, node), problems);
  }

  void visitStatement(Statement node,
      {Map<AstNode, Matcher> changes = const <Expression, Matcher>{},
      Map<AstNode, Set<Problem>> problems = const <AstNode, Set<Problem>>{}}) {
    var fixBuilder = _createFixBuilder(node);
    fixBuilder.visitAll();
    expect(scopedChanges(fixBuilder, node), changes);
    expect(scopedProblems(fixBuilder, node), problems);
  }

  FixBuilder visitSubexpression(Expression node, String expectedType,
      {Map<AstNode, Matcher> changes = const <Expression, Matcher>{},
      Map<AstNode, Set<Problem>> problems = const <AstNode, Set<Problem>>{},
      bool warnOnWeakCode = false}) {
    var fixBuilder = _createFixBuilder(node, warnOnWeakCode: warnOnWeakCode);
    fixBuilder.visitAll();
    var type = node.staticType;
    expect(type.getDisplayString(withNullability: true), expectedType);
    expect(scopedChanges(fixBuilder, node), changes);
    expect(scopedProblems(fixBuilder, node), problems);
    return fixBuilder;
  }

  void visitTypeAnnotation(TypeAnnotation node, String expectedType,
      {Map<AstNode, Matcher> changes = const <AstNode, Matcher>{},
      Map<AstNode, Set<Problem>> problems = const <AstNode, Set<Problem>>{},
      dynamic informative = anything}) {
    var fixBuilder = _createFixBuilder(node);
    fixBuilder.visitAll();
    var type = node.type;
    expect(type.getDisplayString(withNullability: true), expectedType);
    expect(scopedChanges(fixBuilder, node), changes);
    expect(scopedProblems(fixBuilder, node), problems);
    expect(scopedInformative(fixBuilder, node), informative);
  }

  AssignmentTargetInfo _computeAssignmentTargetInfo(
      Expression node, FixBuilder fixBuilder) {
    try {
      assert(
          identical(ElementTypeProvider.current, const ElementTypeProvider()));
      ElementTypeProvider.current = fixBuilder.migrationResolutionHooks;
      var assignment = node.thisOrAncestorOfType<AssignmentExpression>();
      var readType = assignment.readType;
      var writeType = assignment.writeType;
      return AssignmentTargetInfo(readType, writeType);
    } finally {
      ElementTypeProvider.current = const ElementTypeProvider();
    }
  }

  FixBuilder _createFixBuilder(AstNode scope, {bool warnOnWeakCode = false}) {
    var unit = scope.thisOrAncestorOfType<CompilationUnit>();
    var definingLibrary = unit.declaredElement.library;
    return FixBuilder(
        testSource,
        decoratedClassHierarchy,
        typeProvider,
        typeSystem,
        variables,
        definingLibrary,
        null,
        scope.thisOrAncestorOfType<CompilationUnit>(),
        warnOnWeakCode,
        graph, {});
  }

  bool _isInScope(AstNode node, AstNode scope) {
    return node
            .thisOrAncestorMatching((ancestor) => identical(ancestor, scope)) !=
        null;
  }

  static Matcher isConditionalWithKnownValue(bool knownValue) =>
      TypeMatcher<NodeChangeForConditional>()
          .having((c) => c.conditionValue, 'conditionValue', knownValue);
}

extension on TypeMatcher<NodeChangeForExpression> {
  TypeMatcher<NodeChangeForExpression> havingNullCheckWithInfo(
          dynamic matcher) =>
      having((c) => c.addsNullCheck, 'addsNullCheck', true)
          .having((c) => c.addNullCheckInfo, 'addNullCheckInfo', matcher);

  TypeMatcher<NodeChangeForExpression> havingNoValidMigrationWithInfo(
          dynamic matcher) =>
      having((c) => c.addsNoValidMigration, 'addsNoValidMigration', true)
          .having((c) => c.addNoValidMigrationInfo, 'addNoValidMigrationInfo',
              matcher);

  TypeMatcher<NodeChangeForExpression> havingIndroduceAsWithInfo(
          dynamic typeStringMatcher, dynamic infoMatcher) =>
      having((c) => c.introducesAsType.toString(), 'introducesAsType (string)',
              typeStringMatcher)
          .having((c) => c.introducesAsInfo, 'introducesAsInfo', infoMatcher);
}
