// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/fasta/resolution_applier.dart';
import 'package:analyzer/src/generated/testing/test_type_provider.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/parser_fasta_test.dart';
import '../../generated/resolver_test_case.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ResolutionApplierTest);
  });
}

@reflectiveTest
class ResolutionApplierTest extends FastaParserTestCase {
  /// The type provider used to access the types passed to the resolution
  /// applier.
  TestTypeProvider typeProvider;

  /// 1. Generate an AST structure from the given [content]. The AST is expected
  ///    to have a top-level function declaration as the first element.
  /// 2. Use a [ResolutionApplier] to apply the [declaredElements],
  ///    [referencedElements], and [types] to the body of the function.
  /// 3. Verify that everything in the function body that should be resolved
  ///    _is_ resolved.
  void applyTypes(String content, List<Element> declaredElements,
      List<Element> referencedElements, List<DartType> types) {
    CompilationUnit unit = parseCompilationUnit(content);
    ResolutionApplier applier =
        new ResolutionApplier(declaredElements, referencedElements, types);
    expect(unit, isNotNull);
    expect(unit.declarations, hasLength(1));
    FunctionDeclaration function = unit.declarations[0];
    FunctionBody body = function.functionExpression.body;
    body.accept(applier);
    body.accept(new ResolutionVerifier());
  }

  void setUp() {
    typeProvider = new TestTypeProvider();
  }

  void test_binaryExpression() {
    applyTypes(r'''
f(String s, int i) {
  return s + i;
}
''', [], [
      new ParameterElementImpl('s', 9),
      new ParameterElementImpl('i', 16)
    ], <DartType>[
      typeProvider.stringType,
      typeProvider.intType,
      typeProvider.stringType
    ]);
  }

  void test_listLiteral_const_noAnnotation() {
    applyTypes(r'''
get f => const ['a', 'b', 'c'];
''', [], [], <DartType>[
      typeProvider.stringType,
      typeProvider.stringType,
      typeProvider.stringType,
      typeProvider.listType.instantiate([typeProvider.stringType])
    ]);
  }

  void test_listLiteral_const_typeAnnotation() {
    applyTypes(r'''
get f => const <String>['a', 'b', 'c'];
''', [], [], <DartType>[
      typeProvider.stringType,
      typeProvider.stringType,
      typeProvider.stringType,
      typeProvider.listType.instantiate([typeProvider.stringType])
    ]);
  }

  void test_listLiteral_noAnnotation() {
    applyTypes(r'''
get f => ['a', 'b', 'c'];
''', [], [], <DartType>[
      typeProvider.stringType,
      typeProvider.stringType,
      typeProvider.stringType,
      typeProvider.listType.instantiate([typeProvider.stringType])
    ]);
  }

  void test_listLiteral_typeAnnotation() {
    applyTypes(r'''
get f => <String>['a', 'b', 'c'];
''', [], [], <DartType>[
      typeProvider.stringType,
      typeProvider.stringType,
      typeProvider.stringType,
      typeProvider.listType.instantiate([typeProvider.stringType])
    ]);
  }

  void test_localVariable() {
    InterfaceType mapType = typeProvider.mapType.instantiate([
      typeProvider.stringType,
      typeProvider.listType.instantiate([typeProvider.stringType])
    ]);
    applyTypes(r'''
f() {
  Map<String, List<String>> m = {};
}
''', [new LocalVariableElementImpl('m', 34)], [], <DartType>[mapType, mapType]);
  }

  void test_mapLiteral_const_noAnnotation() {
    applyTypes(r'''
get f => const {'a' : 1, 'b' : 2, 'c' : 3};
''', [], [], <DartType>[
      typeProvider.stringType,
      typeProvider.intType,
      typeProvider.stringType,
      typeProvider.intType,
      typeProvider.stringType,
      typeProvider.intType,
      typeProvider.mapType
          .instantiate([typeProvider.stringType, typeProvider.intType])
    ]);
  }

  void test_mapLiteral_const_typeAnnotation() {
    applyTypes(r'''
get f => const <String, int>{'a' : 1, 'b' : 2, 'c' : 3};
''', [], [], <DartType>[
      typeProvider.stringType,
      typeProvider.intType,
      typeProvider.stringType,
      typeProvider.intType,
      typeProvider.stringType,
      typeProvider.intType,
      typeProvider.mapType
          .instantiate([typeProvider.stringType, typeProvider.intType])
    ]);
  }

  void test_mapLiteral_noAnnotation() {
    applyTypes(r'''
get f => {'a' : 1, 'b' : 2, 'c' : 3};
''', [], [], <DartType>[
      typeProvider.stringType,
      typeProvider.intType,
      typeProvider.stringType,
      typeProvider.intType,
      typeProvider.stringType,
      typeProvider.intType,
      typeProvider.mapType
          .instantiate([typeProvider.stringType, typeProvider.intType])
    ]);
  }

  void test_mapLiteral_typeAnnotation() {
    applyTypes(r'''
get f => <String, int>{'a' : 1, 'b' : 2, 'c' : 3};
''', [], [], <DartType>[
      typeProvider.stringType,
      typeProvider.intType,
      typeProvider.stringType,
      typeProvider.intType,
      typeProvider.stringType,
      typeProvider.intType,
      typeProvider.mapType
          .instantiate([typeProvider.stringType, typeProvider.intType])
    ]);
  }
}
