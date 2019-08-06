// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:nnbd_migration/src/decorated_class_hierarchy.dart';
import 'package:nnbd_migration/src/decorated_type.dart';
import 'package:nnbd_migration/src/nullability_node.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'migration_visitor_test_base.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DecoratedClassHierarchyTest);
  });
}

@reflectiveTest
class DecoratedClassHierarchyTest extends MigrationVisitorTestBase {
  DecoratedClassHierarchy _hierarchy;

  @override
  Future<CompilationUnit> analyze(String code) async {
    var unit = await super.analyze(code);
    _hierarchy = DecoratedClassHierarchy(variables, graph);
    return unit;
  }

  test_asInstanceOf_complex() async {
    await analyze('''
class Base<T> {}
class Derived<U> extends Base<List<U>> {}
Derived<int> x;
''');
    var decoratedType = decoratedTypeAnnotation('Derived<int>');
    var asInstanceOfBase =
        _hierarchy.asInstanceOf(decoratedType, findElement.class_('Base'));
    expect(asInstanceOfBase.type.toString(), 'Base<List<int>>');
    expect(asInstanceOfBase.node, same(decoratedType.node));
    var listOfUType = decoratedTypeAnnotation('List<U>');
    expect(asInstanceOfBase.typeArguments[0].node, same(listOfUType.node));
    var substitution = asInstanceOfBase.typeArguments[0].typeArguments[0].node
        as NullabilityNodeForSubstitution;
    expect(substitution.innerNode, same(decoratedType.typeArguments[0].node));
    expect(substitution.outerNode, same(listOfUType.typeArguments[0].node));
  }

  test_getDecoratedSupertype_complex() async {
    await analyze('''
class Base<T> {}
class Intermediate<U> extends Base<List<U>> {}
class Derived<V> extends Intermediate<Map<int, V>> {}
''');
    var decoratedSupertype = _hierarchy.getDecoratedSupertype(
        findElement.class_('Derived'), findElement.class_('Base'));
    var listRef = decoratedTypeAnnotation('List');
    var uRef = decoratedTypeAnnotation('U>>');
    var mapRef = decoratedTypeAnnotation('Map');
    var intRef = decoratedTypeAnnotation('int');
    var vRef = decoratedTypeAnnotation('V>>');
    expect(decoratedSupertype.type.toString(), 'Base<List<Map<int, V>>>');
    expect(decoratedSupertype.node, same(never));
    var baseArgs = decoratedSupertype.typeArguments;
    expect(baseArgs, hasLength(1));
    expect(baseArgs[0].type.toString(), 'List<Map<int, V>>');
    expect(baseArgs[0].node, same(listRef.node));
    var listArgs = baseArgs[0].typeArguments;
    expect(listArgs, hasLength(1));
    expect(listArgs[0].type.toString(), 'Map<int, V>');
    var mapNode = listArgs[0].node as NullabilityNodeForSubstitution;
    expect(mapNode.innerNode, same(mapRef.node));
    expect(mapNode.outerNode, same(uRef.node));
    var mapArgs = listArgs[0].typeArguments;
    expect(mapArgs, hasLength(2));
    expect(mapArgs[0].type.toString(), 'int');
    expect(mapArgs[0].node, same(intRef.node));
    expect(mapArgs[1].type.toString(), 'V');
    expect(mapArgs[1].node, same(vRef.node));
  }

  test_getDecoratedSupertype_extends_simple() async {
    await analyze('''
class Base<T, U> {}
class Derived<V, W> extends Base<V, W> {}
''');
    var decoratedSupertype = _hierarchy.getDecoratedSupertype(
        findElement.class_('Derived'), findElement.class_('Base'));
    var vRef = decoratedTypeAnnotation('V, W> {');
    var wRef = decoratedTypeAnnotation('W> {');
    expect(decoratedSupertype.type.toString(), 'Base<V, W>');
    expect(decoratedSupertype.node, same(never));
    expect(decoratedSupertype.typeArguments, hasLength(2));
    expect(decoratedSupertype.typeArguments[0].type.toString(), 'V');
    expect(decoratedSupertype.typeArguments[0].node, same(vRef.node));
    expect(decoratedSupertype.typeArguments[1].type.toString(), 'W');
    expect(decoratedSupertype.typeArguments[1].node, same(wRef.node));
  }

  test_getDecoratedSupertype_implements_simple() async {
    await analyze('''
class Base<T, U> {}
class Derived<V, W> implements Base<V, W> {}
''');
    var decoratedSupertype = _hierarchy.getDecoratedSupertype(
        findElement.class_('Derived'), findElement.class_('Base'));
    var vRef = decoratedTypeAnnotation('V, W> {');
    var wRef = decoratedTypeAnnotation('W> {');
    expect(decoratedSupertype.type.toString(), 'Base<V, W>');
    expect(decoratedSupertype.node, same(never));
    expect(decoratedSupertype.typeArguments, hasLength(2));
    expect(decoratedSupertype.typeArguments[0].type.toString(), 'V');
    expect(decoratedSupertype.typeArguments[0].node, same(vRef.node));
    expect(decoratedSupertype.typeArguments[1].type.toString(), 'W');
    expect(decoratedSupertype.typeArguments[1].node, same(wRef.node));
  }

  test_getDecoratedSupertype_not_generic() async {
    await analyze('''
class Base {}
class Derived<T> extends Base {}
''');
    var decoratedSupertype = _hierarchy.getDecoratedSupertype(
        findElement.class_('Derived'), findElement.class_('Base'));
    expect(decoratedSupertype.type.toString(), 'Base');
    expect(decoratedSupertype.node, same(never));
    expect(decoratedSupertype.typeArguments, isEmpty);
  }

  test_getDecoratedSupertype_on_simple() async {
    await analyze('''
class Base<T, U> {}
mixin Derived<V, W> on Base<V, W> {}
''');
    var decoratedSupertype = _hierarchy.getDecoratedSupertype(
        findElement.mixin('Derived'), findElement.class_('Base'));
    var vRef = decoratedTypeAnnotation('V, W> {');
    var wRef = decoratedTypeAnnotation('W> {');
    expect(decoratedSupertype.type.toString(), 'Base<V, W>');
    expect(decoratedSupertype.node, same(never));
    expect(decoratedSupertype.typeArguments, hasLength(2));
    expect(decoratedSupertype.typeArguments[0].type.toString(), 'V');
    expect(decoratedSupertype.typeArguments[0].node, same(vRef.node));
    expect(decoratedSupertype.typeArguments[1].type.toString(), 'W');
    expect(decoratedSupertype.typeArguments[1].node, same(wRef.node));
  }

  test_getDecoratedSupertype_unrelated_type() async {
    await analyze('''
class A<T> {}
class B<T> {}
''');
    expect(
        () => _hierarchy.getDecoratedSupertype(
            findElement.class_('A'), findElement.class_('B')),
        throwsA(TypeMatcher<StateError>()));
  }

  test_getDecoratedSupertype_with_simple() async {
    await analyze('''
class Base<T, U> {}
class Derived<V, W> extends Object with Base<V, W> {}
''');
    var decoratedSupertype = _hierarchy.getDecoratedSupertype(
        findElement.class_('Derived'), findElement.class_('Base'));
    var vRef = decoratedTypeAnnotation('V, W> {');
    var wRef = decoratedTypeAnnotation('W> {');
    expect(decoratedSupertype.type.toString(), 'Base<V, W>');
    expect(decoratedSupertype.node, same(never));
    expect(decoratedSupertype.typeArguments, hasLength(2));
    expect(decoratedSupertype.typeArguments[0].type.toString(), 'V');
    expect(decoratedSupertype.typeArguments[0].node, same(vRef.node));
    expect(decoratedSupertype.typeArguments[1].type.toString(), 'W');
    expect(decoratedSupertype.typeArguments[1].node, same(wRef.node));
  }
}
