// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/parser_test.dart';
import 'body_builder_test_helper.dart';

main() async {
  defineReflectiveSuite(() {
    defineReflectiveTests(ResolutionTest);
  });
}

/**
 * Tests of the fasta parser based on [ExpressionParserTestMixin].
 */
@reflectiveTest
class ResolutionTest extends FastaBodyBuilderTestCase {
  ResolutionTest() : super(true);

  test_booleanLiteral_false() {
    Expression result = parseExpression('false');
    expect(result, new isInstanceOf<BooleanLiteral>());
    expect((result as BooleanLiteral).staticType, typeProvider.boolType);
  }

  test_booleanLiteral_true() {
    Expression result = parseExpression('true');
    expect(result, new isInstanceOf<BooleanLiteral>());
    expect((result as BooleanLiteral).staticType, typeProvider.boolType);
  }

  test_doubleLiteral() {
    Expression result = parseExpression('4.2');
    expect(result, new isInstanceOf<DoubleLiteral>());
    expect((result as DoubleLiteral).staticType, typeProvider.doubleType);
  }

  test_integerLiteral() {
    Expression result = parseExpression('3');
    expect(result, new isInstanceOf<IntegerLiteral>());
    expect((result as IntegerLiteral).staticType, typeProvider.intType);
  }

  @failingTest
  test_listLiteral_explicitType() {
    Expression result = parseExpression('<int>[]');
    expect(result, new isInstanceOf<ListLiteral>());
    InterfaceType listType = typeProvider.listType;
    expect((result as ListLiteral).staticType,
        listType.instantiate([typeProvider.intType]));
  }

  @failingTest
  test_listLiteral_noType() {
    Expression result = parseExpression('[]');
    expect(result, new isInstanceOf<ListLiteral>());
    InterfaceType listType = typeProvider.listType;
    expect((result as ListLiteral).staticType,
        listType.instantiate([typeProvider.dynamicType]));
  }

  @failingTest
  test_mapLiteral_explicitType() {
    Expression result = parseExpression('<String, int>{}');
    expect(result, new isInstanceOf<MapLiteral>());
    InterfaceType mapType = typeProvider.mapType;
    expect((result as MapLiteral).staticType,
        mapType.instantiate([typeProvider.stringType, typeProvider.intType]));
  }

  @failingTest
  test_mapLiteral_noType() {
    Expression result = parseExpression('{}');
    expect(result, new isInstanceOf<MapLiteral>());
    InterfaceType mapType = typeProvider.mapType;
    expect(
        (result as MapLiteral).staticType,
        mapType
            .instantiate([typeProvider.dynamicType, typeProvider.dynamicType]));
  }

  test_nullLiteral() {
    Expression result = parseExpression('null');
    expect(result, new isInstanceOf<NullLiteral>());
    expect((result as NullLiteral).staticType, typeProvider.nullType);
  }

  test_simpleStringLiteral() {
    Expression result = parseExpression('"abc"');
    expect(result, new isInstanceOf<SimpleStringLiteral>());
    expect((result as SimpleStringLiteral).staticType, typeProvider.stringType);
  }
}
