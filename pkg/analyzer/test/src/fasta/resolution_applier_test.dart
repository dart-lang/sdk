// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/fasta/resolution_applier.dart';
import 'package:analyzer/src/generated/testing/test_type_provider.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:kernel/kernel.dart' as kernel;
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
  void applyTypes(
      String content,
      List<Element> declaredElements,
      List<int> declareElementOffsets,
      List<Element> referencedElements,
      List<int> referencedElementOffsets,
      List<DartType> types,
      List<int> typeOffsets) {
    CompilationUnit unit = parseCompilationUnit(content);
    expect(unit, isNotNull);
    expect(unit.declarations, hasLength(1));
    FunctionDeclaration function = unit.declarations[0];
    FunctionBody body = function.functionExpression.body;
    ResolutionApplier applier = new ResolutionApplier(
        new _TestTypeContext(),
        declaredElements,
        declareElementOffsets,
        referencedElements,
        referencedElementOffsets,
        types.map((type) => new _KernelWrapperOfType(type)).toList(),
        typeOffsets);

    body.accept(applier);
    applier.checkDone();

    ResolutionVerifier verifier = new ResolutionVerifier();
    // TODO(brianwilkerson) Uncomment the line below when the tests no longer
    // fail.
//    body.accept(verifier);
    verifier.assertResolved();
  }

  void setUp() {
    typeProvider = new TestTypeProvider();
  }

  void test_binaryExpression() {
    applyTypes(r'''
f(String s, int i) {
  return s + i;
}
''', [], [], [
      _createFunctionParameter('s', 9),
      new MethodElementImpl('+', -1),
      _createFunctionParameter('i', 16),
    ], [
      30,
      32,
      34
    ], <DartType>[
      typeProvider.stringType,
      new FunctionTypeImpl(new FunctionElementImpl('+', -1)),
      typeProvider.intType,
      typeProvider.stringType,
    ], [
      30,
      32,
      32,
      34
    ]);
  }

  void test_functionExpressionInvocation() {
    applyTypes(r'''
f(Object a) {
  return a.b().c();
}
''', [], [], [
      _createFunctionParameter('a', 9),
      new MethodElementImpl('b', -1),
      new MethodElementImpl('c', -1)
    ], [
      23,
      25,
      29
    ], <DartType>[
      typeProvider.objectType,
      typeProvider.objectType,
      typeProvider.objectType,
      typeProvider.objectType,
      typeProvider.objectType
    ], [
      23,
      25,
      26,
      29,
      30
    ]);
  }

  void test_genericFunctionType() {
    GenericFunctionTypeElementImpl element =
        new GenericFunctionTypeElementImpl.forOffset(8);
    element.enclosingElement = new FunctionElementImpl('f', 0);
    element.typeParameters = <TypeParameterElement>[];
    element.returnType = typeProvider.intType;
    element.parameters = [
      _createFunctionParameter('', -1, type: typeProvider.stringType),
      _createFunctionParameter('x', 34, type: typeProvider.boolType),
    ];
    FunctionTypeImpl functionType = new FunctionTypeImpl(element);
    element.type = functionType;
    applyTypes(r'''
f() {
  int Function(String, bool x) foo;
}
''', [new LocalVariableElementImpl('foo', 37)], [37], [], [],
        <DartType>[functionType], [37]);
  }

  void test_listLiteral_const_noAnnotation() {
    applyTypes(r'''
get f => const ['a', 'b', 'c'];
''', [], [], [], [], <DartType>[
      typeProvider.stringType,
      typeProvider.stringType,
      typeProvider.stringType,
      typeProvider.listType.instantiate([typeProvider.stringType])
    ], [
      16,
      21,
      26,
      9
    ]);
  }

  void test_listLiteral_const_typeAnnotation() {
    applyTypes(r'''
get f => const <String>['a', 'b', 'c'];
''', [], [], [], [], <DartType>[
      typeProvider.stringType,
      typeProvider.stringType,
      typeProvider.stringType,
      typeProvider.listType.instantiate([typeProvider.stringType])
    ], [
      24,
      29,
      34,
      9
    ]);
  }

  void test_listLiteral_noAnnotation() {
    applyTypes(r'''
get f => ['a', 'b', 'c'];
''', [], [], [], [], <DartType>[
      typeProvider.stringType,
      typeProvider.stringType,
      typeProvider.stringType,
      typeProvider.listType.instantiate([typeProvider.stringType])
    ], [
      10,
      15,
      20,
      9
    ]);
  }

  void test_listLiteral_typeAnnotation() {
    applyTypes(r'''
get f => <String>['a', 'b', 'c'];
''', [], [], [], [], <DartType>[
      typeProvider.stringType,
      typeProvider.stringType,
      typeProvider.stringType,
      typeProvider.listType.instantiate([typeProvider.stringType])
    ], [
      18,
      23,
      28,
      17
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
''', [new LocalVariableElementImpl('m', 34)], [34], [], [],
        <DartType>[mapType, mapType], [34, 38]);
  }

  void test_mapLiteral_const_noAnnotation() {
    applyTypes(r'''
get f => const {'a' : 1, 'b' : 2, 'c' : 3};
''', [], [], [], [], <DartType>[
      typeProvider.stringType,
      typeProvider.intType,
      typeProvider.stringType,
      typeProvider.intType,
      typeProvider.stringType,
      typeProvider.intType,
      typeProvider.mapType
          .instantiate([typeProvider.stringType, typeProvider.intType])
    ], [
      16,
      22,
      25,
      31,
      34,
      40,
      9
    ]);
  }

  void test_mapLiteral_const_typeAnnotation() {
    applyTypes(r'''
get f => const <String, int>{'a' : 1, 'b' : 2, 'c' : 3};
''', [], [], [], [], <DartType>[
      typeProvider.stringType,
      typeProvider.intType,
      typeProvider.stringType,
      typeProvider.intType,
      typeProvider.stringType,
      typeProvider.intType,
      typeProvider.mapType
          .instantiate([typeProvider.stringType, typeProvider.intType])
    ], [
      29,
      35,
      38,
      44,
      47,
      53,
      9
    ]);
  }

  void test_mapLiteral_noAnnotation() {
    applyTypes(r'''
get f => {'a' : 1, 'b' : 2, 'c' : 3};
''', [], [], [], [], <DartType>[
      typeProvider.stringType,
      typeProvider.intType,
      typeProvider.stringType,
      typeProvider.intType,
      typeProvider.stringType,
      typeProvider.intType,
      typeProvider.mapType
          .instantiate([typeProvider.stringType, typeProvider.intType])
    ], [
      10,
      16,
      19,
      25,
      28,
      34,
      9
    ]);
  }

  void test_mapLiteral_typeAnnotation() {
    applyTypes(r'''
get f => <String, int>{'a' : 1, 'b' : 2, 'c' : 3};
''', [], [], [], [], <DartType>[
      typeProvider.stringType,
      typeProvider.intType,
      typeProvider.stringType,
      typeProvider.intType,
      typeProvider.stringType,
      typeProvider.intType,
      typeProvider.mapType
          .instantiate([typeProvider.stringType, typeProvider.intType])
    ], [
      23,
      29,
      32,
      38,
      41,
      47,
      22
    ]);
  }

  void test_methodInvocation_getter() {
    applyTypes(r'''
f(String s) {
  return s.length;
}
''', [], [], [
      _createFunctionParameter('s', 9),
      new MethodElementImpl('length', -1)
    ], [
      23,
      25
    ], <DartType>[
      typeProvider.stringType,
      typeProvider.intType,
    ], [
      23,
      25
    ]);
  }

  void test_methodInvocation_method() {
    applyTypes(r'''
f(String s) {
  return s.substring(3, 7);
}
''', [], [], [
      _createFunctionParameter('s', 9),
      new MethodElementImpl('length', -1)
    ], [
      23,
      25
    ], <DartType>[
      typeProvider.stringType,
      typeProvider.intType,
      typeProvider.intType,
      typeProvider.stringType,
      typeProvider.stringType
    ], [
      23,
      25,
      34,
      35,
      38
    ]);
  }

  @failingTest
  void test_typeAlias() {
    TypeParameterElement B = _createTypeParameter('B', 42);
    TypeParameterElement C = _createTypeParameter('C', 45);
    GenericTypeAliasElementImpl element =
        new GenericTypeAliasElementImpl('A', 40);
    element.typeParameters = <TypeParameterElement>[B, C];
    GenericFunctionTypeElementImpl functionElement =
        element.function = new GenericFunctionTypeElementImpl.forOffset(-1);
    functionElement.typeParameters = <TypeParameterElement>[];
    functionElement.returnType = B.type;
    functionElement.parameters = [
      _createFunctionParameter('x', 48, type: C.type),
    ];
    FunctionTypeImpl functionType = new FunctionTypeImpl.forTypedef(element);
    applyTypes(r'''
f() {
  A<int, String> foo;
}
//typedef B A<B, C>(C x);
''', [new LocalVariableElementImpl('foo', 23)], [], [], [],
        <DartType>[functionType], []);
  }

  /// Return a newly created parameter element with the given [name] and
  /// [offset].
  ParameterElement _createFunctionParameter(String name, int offset,
      {DartType type}) {
    ParameterElementImpl parameter = new ParameterElementImpl(name, offset);
    parameter.type = type;
    parameter.parameterKind = ParameterKind.REQUIRED;
    return parameter;
  }

  /// Return a newly created type parameter element with the given [name] and
  /// [offset].
  TypeParameterElement _createTypeParameter(String name, int offset) {
    TypeParameterElementImpl typeParameter =
        new TypeParameterElementImpl(name, offset);
    TypeParameterTypeImpl typeParameterType =
        new TypeParameterTypeImpl(typeParameter);
    typeParameter.type = typeParameterType;
    return typeParameter;
  }
}

/// Kernel wrapper around the Analyzer [type].
class _KernelWrapperOfType implements kernel.DartType {
  final DartType type;

  _KernelWrapperOfType(this.type);

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Test implementation of [TypeContext].
class _TestTypeContext implements TypeContext {
  @override
  ClassElement get enclosingClassElement => null;

  @override
  DartType get stringType => null;

  @override
  DartType get typeType => null;

  @override
  void encloseVariable(ElementImpl element) {}

  @override
  void enterLocalFunction(FunctionElementImpl element) {}

  @override
  void exitLocalFunction(FunctionElementImpl element) {}

  @override
  DartType translateType(kernel.DartType kernelType) {
    return (kernelType as _KernelWrapperOfType).type;
  }
}
