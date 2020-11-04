// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:nnbd_migration/src/utilities/where_or_null_transformer.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../abstract_single_unit.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(WhereOrNullTransformerTest);
  });
}

@reflectiveTest
class WhereOrNullTransformerTest extends AbstractSingleUnitTest {
  WhereOrNullTransformer transformer;

  TypeProvider get typeProvider => testAnalysisResult.typeProvider;

  TypeSystem get typeSystem => testAnalysisResult.typeSystem;

  Future<void> analyze(String code) async {
    await resolveTestUnit(code);
    transformer = WhereOrNullTransformer(typeProvider, typeSystem);
  }

  Future<void> test_match() async {
    await analyze('''
f(List<int> x) => x.firstWhere((i) => i.isEven, orElse: () => null);
''');
    var orElseExpression = findNode.functionExpression('() => null');
    var transformationInfo =
        transformer.tryTransformOrElseArgument(orElseExpression);
    expect(transformationInfo, isNotNull);
    expect(transformationInfo.methodInvocation,
        same(findNode.methodInvocation('firstWhere')));
    expect(transformationInfo.orElseArgument, same(orElseExpression.parent));
    expect(transformationInfo.originalName, 'firstWhere');
    expect(transformationInfo.replacementName, 'firstWhereOrNull');
  }

  Future<void> test_match_extended() async {
    await analyze('''
abstract class C implements Iterable<int> {
  int firstWhere(bool test(int element), {int orElse()}) => null;
}
f(C c) => c.firstWhere((i) => i.isEven, orElse: () => null);
''');
    var orElseExpression = findNode.functionExpression('() => null');
    var transformationInfo =
        transformer.tryTransformOrElseArgument(orElseExpression);
    expect(transformationInfo, isNotNull);
    expect(transformationInfo.methodInvocation,
        same(findNode.methodInvocation('firstWhere((')));
    expect(transformationInfo.orElseArgument, same(orElseExpression.parent));
    expect(transformationInfo.originalName, 'firstWhere');
    expect(transformationInfo.replacementName, 'firstWhereOrNull');
  }

  Future<void> test_mismatch_misnamed_method() async {
    await analyze('''
abstract class C extends Iterable<int> {
  int fooBar(bool test(int element), {int orElse()});
}
f(C c) => c.fooBar((i) => i.isEven, orElse: () => null);
''');
    expect(
        transformer.tryTransformOrElseArgument(
            findNode.functionExpression('() => null')),
        isNull);
  }

  Future<void> test_mismatch_orElse_expression() async {
    await analyze('''
f(List<int> x) => x.firstWhere((i) => i.isEven, orElse: () => 0);
''');
    expect(
        transformer
            .tryTransformOrElseArgument(findNode.functionExpression('() => 0')),
        isNull);
  }

  Future<void> test_mismatch_orElse_name() async {
    await analyze('''
abstract class C extends Iterable<int> {
  @override
  int firstWhere(bool test(int element), {int orElse(), int ifSo()});
}
f(C c) => c.firstWhere((i) => i.isEven, ifSo: () => null);
''');
    expect(
        transformer.tryTransformOrElseArgument(
            findNode.functionExpression('() => null')),
        isNull);
  }

  Future<void> test_mismatch_orElse_named_parameter() async {
    await analyze('''
f(List<int> x) => x.firstWhere((i) => i.isEven, orElse: ({int x}) => null);
''');
    expect(
        transformer.tryTransformOrElseArgument(
            findNode.functionExpression(') => null')),
        isNull);
  }

  Future<void> test_mismatch_orElse_optional_parameter() async {
    await analyze('''
f(List<int> x) => x.firstWhere((i) => i.isEven, orElse: ([int x]) => null);
''');
    expect(
        transformer.tryTransformOrElseArgument(
            findNode.functionExpression(') => null')),
        isNull);
  }

  Future<void> test_mismatch_orElse_presence_of_other_arg() async {
    await analyze('''
abstract class C extends Iterable<int> {
  @override
  int firstWhere(bool test(int element), {int orElse(), int ifSo()});
}
f(C c) => c.firstWhere((i) => i.isEven, orElse: () => null, ifSo: () => null);
''');
    expect(
        transformer.tryTransformOrElseArgument(
            findNode.functionExpression('() => null,')),
        isNull);
  }

  Future<void> test_mismatch_other_subexpression() async {
    await analyze('''
List<int> f(List<int> x) => x;
g(List<int> x) => f(x).firstWhere((i) => i.isEven, orElse: () => null);
''');
    var xExpression = findNode.simple('x).firstWhere');
    expect(transformer.tryTransformOrElseArgument(xExpression), isNull);
  }

  Future<void> test_mismatch_unrelated_type() async {
    await analyze('''
abstract class C {
  int firstWhere(bool test(int element), {int orElse()});
}
f(C c) => c.firstWhere((i) => i.isEven, orElse: () => null);
''');
    expect(
        transformer.tryTransformOrElseArgument(
            findNode.functionExpression('() => null')),
        isNull);
  }
}
