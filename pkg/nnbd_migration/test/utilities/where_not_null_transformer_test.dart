// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:nnbd_migration/src/utilities/where_not_null_transformer.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../abstract_single_unit.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(WhereNotNullTransformerTest);
  });
}

@reflectiveTest
class WhereNotNullTransformerTest extends AbstractSingleUnitTest {
  late WhereNotNullTransformer transformer;

  TypeProvider get typeProvider => testAnalysisResult.typeProvider;

  TypeSystem get typeSystem => testAnalysisResult.typeSystem;

  Future<void> analyze(String code) async {
    await resolveTestUnit(code);
    transformer = WhereNotNullTransformer(typeProvider, typeSystem);
  }

  Future<void> test_match() async {
    await analyze('''
f(List<int> x) => x.where((i) => i != null);
''');
    var methodInvocation = findNode.methodInvocation('.where');
    var transformationInfo =
        transformer.tryTransformMethodInvocation(methodInvocation)!;
    expect(transformationInfo, isNotNull);
    expect(transformationInfo.methodInvocation, same(methodInvocation));
    expect(transformationInfo.argument,
        same(findNode.functionExpression('(i) => i != null')));
    expect(transformationInfo.originalName, 'where');
    expect(transformationInfo.replacementName, 'whereNotNull');
  }

  Future<void> test_match_extended() async {
    await analyze('''
abstract class C implements Iterable<int> {
  Iterable<int> where(bool test(int element)) => null;
}
f(C c) => c.where((i) => i != null);
''');
    var methodInvocation = findNode.methodInvocation('.where');
    var transformationInfo =
        transformer.tryTransformMethodInvocation(methodInvocation)!;
    expect(transformationInfo, isNotNull);
    expect(transformationInfo.methodInvocation, same(methodInvocation));
    expect(transformationInfo.argument,
        same(findNode.functionExpression('(i) => i != null')));
    expect(transformationInfo.originalName, 'where');
    expect(transformationInfo.replacementName, 'whereNotNull');
  }

  Future<void> test_match_returns_subtype() async {
    await analyze('''
abstract class C implements Iterable<int> {
  List<int> where(bool test(int element)) => null;
}
f(C c) => c.where((i) => i != null);
''');
    var methodInvocation = findNode.methodInvocation('.where');
    var transformationInfo =
        transformer.tryTransformMethodInvocation(methodInvocation)!;
    expect(transformationInfo, isNotNull);
    expect(transformationInfo.methodInvocation, same(methodInvocation));
    expect(transformationInfo.argument,
        same(findNode.functionExpression('(i) => i != null')));
    expect(transformationInfo.originalName, 'where');
    expect(transformationInfo.replacementName, 'whereNotNull');
  }

  Future<void> test_mismatch_closure_block_typed() async {
    await analyze('''
abstract class C implements Iterable<int> {
  Iterable<int> where(bool test(int element)) => null;
}
f(C c) => c.where((i) { return i != null; });
''');
    expect(
        transformer
            .tryTransformMethodInvocation(findNode.methodInvocation('.where')),
        isNull);
  }

  Future<void> test_mismatch_closure_lhs_not_identifier() async {
    await analyze('''
abstract class C implements Iterable<int> {
  Iterable<int> where(bool test(int element)) => null;
}
f(C c) => c.where((i) => 2*i != null);
''');
    expect(
        transformer
            .tryTransformMethodInvocation(findNode.methodInvocation('.where')),
        isNull);
  }

  Future<void> test_mismatch_closure_lhs_wrong_element() async {
    await analyze('''
abstract class C implements Iterable<int> {
  Iterable<int> where(bool test(int element)) => null;
}
f(C c) => c.where((i) => c != null);
''');
    expect(
        transformer
            .tryTransformMethodInvocation(findNode.methodInvocation('.where')),
        isNull);
  }

  Future<void> test_mismatch_closure_non_binary_expression() async {
    await analyze('''
abstract class C implements Iterable<int> {
  Iterable<int> where(bool test(int element)) => null;
}
f(C c) => c.where((i) => true);
''');
    expect(
        transformer
            .tryTransformMethodInvocation(findNode.methodInvocation('.where')),
        isNull);
  }

  Future<void> test_mismatch_closure_wrong_operator() async {
    await analyze('''
abstract class C implements Iterable<int> {
  Iterable<int> where(bool test(int element)) => null;
}
f(C c) => c.where((i) => i == null);
''');
    expect(
        transformer
            .tryTransformMethodInvocation(findNode.methodInvocation('.where')),
        isNull);
  }

  Future<void> test_mismatch_extension_method() async {
    await analyze('''
extension on String {
  Iterable<int> where(bool test(int element)) => null;
}
f(String s) => s.where((i) => i != null);
''');
    expect(
        transformer
            .tryTransformMethodInvocation(findNode.methodInvocation('.where')),
        isNull);
  }

  Future<void> test_mismatch_misnamed_method() async {
    await analyze('''
abstract class C implements Iterable<int> {
  Iterable<int> fooBar(bool test(int element)) => null;
}
f(C c) => c.fooBar((i) => i != null);
''');
    expect(
        transformer
            .tryTransformMethodInvocation(findNode.methodInvocation('.fooBar')),
        isNull);
  }

  Future<void> test_mismatch_not_a_subtype_of_iterable() async {
    await analyze('''
abstract class C {
  Iterable<int> where(bool test(int element)) => null;
}
f(C c) => c.where((i) => i != null);
''');
    expect(
        transformer
            .tryTransformMethodInvocation(findNode.methodInvocation('.where')),
        isNull);
  }

  Future<void> test_mismatch_rhs_not_null() async {
    await analyze('''
abstract class C implements Iterable<int> {
  Iterable<int> where(bool test(int element)) => null;
}
f(C c) => c.where((i) => i != 0);
''');
    expect(
        transformer
            .tryTransformMethodInvocation(findNode.methodInvocation('.where')),
        isNull);
  }

  Future<void> test_mismatch_too_many_arguments() async {
    await analyze('''
abstract class C implements Iterable<int> {
  Iterable<int> where(bool test(int element), {int x}) => null;
}
f(C c) => c.where((i) => i != null, x: 0);
''');
    expect(
        transformer
            .tryTransformMethodInvocation(findNode.methodInvocation('.where')),
        isNull);
  }
}
