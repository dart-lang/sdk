// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidRuntimeCheckWithJSInteropTypesTest);
  });
}

@reflectiveTest
class InvalidRuntimeCheckWithJSInteropTypesTest extends LintRuleTest {
  @override
  bool get addJsPackageDep => true;

  @override
  String get lintRule => 'invalid_runtime_check_with_js_interop_types';

  test_baseTypesAs_dart_type_as_js_type() async {
    await _testCasts([_AsCast('int', 'JSNumber')]);
  }

  test_baseTypesAs_js_type_as_dart_type() async {
    await _testCasts([_AsCast('JSString', 'String')]);
  }

  test_baseTypesAs_js_type_as_same_js_type() async {
    await _testCasts(
        [_AsCast('JSBoolean', 'JSBoolean', lint: false, unnecessary: true)]);
  }

  test_baseTypesAs_js_type_as_subtype() async {
    await _testCasts([_AsCast('JSAny', 'JSObject', lint: false)]);
  }

  test_baseTypesAs_js_type_as_supertype() async {
    await _testCasts([_AsCast('JSArray', 'JSObject', lint: false)]);
  }

  test_baseTypesAs_js_type_as_top_type() async {
    await _testCasts([
      _AsCast('JSAny', 'Object', lint: false),
      _AsCast('JSObject', 'dynamic', lint: false),
      _AsCast('List<JSAny>', 'Object', lint: false),
      _AsCast('List<JSObject>', 'dynamic', lint: false)
    ]);
  }

  test_baseTypesAs_js_type_as_unrelated_js_type() async {
    await _testCasts([_AsCast('JSBoolean', 'JSUint8List')]);
  }

  test_baseTypesAs_top_type_as_js_type() async {
    await _testCasts([
      _AsCast('Object', 'JSAny', lint: false),
      _AsCast('dynamic', 'JSObject', lint: false),
      _AsCast('List<JSAny>', 'Object', lint: false),
      _AsCast('List<JSObject>', 'dynamic', lint: false)
    ]);
  }

  test_baseTypesIs_dart_type_is_js_type() async {
    await _testChecks([_IsCheck('int', 'JSNumber')]);
  }

  test_baseTypesIs_js_type_is_dart_type() async {
    await _testChecks([_IsCheck('JSString', 'String')]);
  }

  test_baseTypesIs_js_type_is_same_js_type() async {
    await _testChecks(
        [_IsCheck('JSBoolean', 'JSBoolean', lint: false, unnecessary: true)]);
  }

  test_baseTypesIs_js_type_is_subtype() async {
    await _testChecks([_IsCheck('JSAny', 'JSObject')]);
  }

  test_baseTypesIs_js_type_is_supertype() async {
    await _testChecks(
        [_IsCheck('JSArray', 'JSObject', lint: false, unnecessary: true)]);
  }

  test_baseTypesIs_js_type_is_top_type() async {
    await _testChecks([
      _IsCheck('JSAny', 'Object', lint: false, unnecessary: true),
      _IsCheck('JSObject', 'dynamic', lint: false, unnecessary: true),
      _IsCheck('List<JSAny>', 'Object', lint: false, unnecessary: true),
      _IsCheck('List<JSObject>', 'dynamic', lint: false, unnecessary: true)
    ]);
  }

  test_baseTypesIs_js_type_is_unrelated_js_type() async {
    await _testChecks([_IsCheck('JSBoolean', 'JSUint8List')]);
  }

  test_baseTypesIs_top_type_is_js_type() async {
    await _testChecks([
      _IsCheck('Object', 'JSAny'),
      _IsCheck('dynamic', 'JSObject'),
      // TODO(srujzs): These two checks should lint, but `canBeSubtypeOf`
      // determines subtyping via a pairwise comparison. So, we never actually
      // check the JS interop type against anything, since the left type is not
      // generic.
      _IsCheck('Object', 'List<JSAny>', lint: false),
      _IsCheck('dynamic', 'List<JSObject>', lint: false)
    ]);
  }

  // TODO(srujzs): Some of the following type tests should result in an error,
  // but `canBeSubtypeOf` doesn't nest for function types.
  test_functionTypesAs_function_type_with_js_types_as() async {
    await _testCasts([
      _AsCast('JSAny Function()', 'JSAny Function()',
          lint: false, unnecessary: true),
      _AsCast('JSAny Function()', 'JSBoolean Function()', lint: false),
      _AsCast('JSBoolean Function()', 'JSAny Function()', lint: false),
      _AsCast('JSString Function()', 'JSBoolean Function()', lint: false),
      _AsCast('void Function(JSAny)', 'void Function(JSAny)',
          lint: false, unnecessary: true),
      _AsCast('void Function(JSAny)', 'void Function(JSBoolean)', lint: false),
      _AsCast('void Function(JSBoolean)', 'void Function(JSAny)', lint: false),
      _AsCast('void Function(JSString)', 'void Function(JSBoolean)',
          lint: false)
    ]);
  }

  // TODO(srujzs): Some of the following type tests should result in an error,
  // but `canBeSubtypeOf` doesn't nest for function types.
  test_functionTypesIs_function_type_with_js_types_is() async {
    await _testChecks([
      _IsCheck('JSAny Function()', 'JSAny Function()',
          lint: false, unnecessary: true),
      _IsCheck('JSAny Function()', 'JSBoolean Function()', lint: false),
      _IsCheck('JSBoolean Function()', 'JSAny Function()',
          lint: false, unnecessary: true),
      _IsCheck('JSString Function()', 'JSBoolean Function()', lint: false),
      _IsCheck('void Function(JSAny)', 'void Function(JSAny)',
          lint: false, unnecessary: true),
      _IsCheck('void Function(JSAny)', 'void Function(JSBoolean)',
          lint: false, unnecessary: true),
      _IsCheck('void Function(JSBoolean)', 'void Function(JSAny)', lint: false),
      _IsCheck('void Function(JSString)', 'void Function(JSBoolean)',
          lint: false)
    ]);
  }

  test_genericTypesAs_dart_type_generic_as_js_type_generic() async {
    await _testCasts([_AsCast('List<int>', 'List<JSNumber>')]);
  }

  // For the purpose of this lint, generics on `dart:js_interop` types are
  // ignored.
  test_genericTypesAs_generic_js_type_as_generic_js_type() async {
    await _testCasts([
      _AsCast('JSArray<JSString>', 'JSArray<JSAny>', lint: false),
      _AsCast('JSArray<JSAny>', 'JSArray<JSString>', lint: false),
      _AsCast('JSArray<JSString>', 'JSArray<JSBoolean>', lint: false)
    ]);
  }

  test_genericTypesAs_generic_type_with_multiple_type_parameter_as() async {
    await _testCasts([
      _AsCast('Map<JSBoolean, JSBoolean>', 'Map<JSBoolean, JSBoolean>',
          lint: false, unnecessary: true),
      _AsCast('Map<JSObject, JSString>', 'Map<JSAny, JSAny>', lint: false),
      _AsCast('Map<JSObject, JSString>', 'Map<JSAny, JSBoolean>'),
      _AsCast('Map<JSAny, JSString>', 'Map<JSObject, JSString>', lint: false),
      _AsCast('Map<JSAny, JSString>', 'Map<JSObject, JSBoolean>')
    ]);
  }

  test_genericTypesAs_js_type_generic_as_dart_type_generic() async {
    await _testCasts([_AsCast('List<JSString>', 'List<String>')]);
  }

  test_genericTypesAs_js_type_generic_as_same_js_type_generic() async {
    await _testCasts([
      _AsCast('Set<JSString>', 'Set<JSString>', lint: false, unnecessary: true)
    ]);
  }

  test_genericTypesAs_js_type_generic_as_subtype_generic() async {
    await _testCasts([_AsCast('List<JSAny>', 'List<JSObject>', lint: false)]);
  }

  test_genericTypesAs_js_type_generic_as_supertype_generic() async {
    await _testCasts(
        [_AsCast('Future<JSArray>', 'Future<JSObject>', lint: false)]);
  }

  test_genericTypesAs_js_type_generic_as_top_type_generic() async {
    await _testCasts([
      _AsCast('List<JSAny>', 'List<Object>', lint: false),
      _AsCast('List<JSAny>', 'List<dynamic>', lint: false)
    ]);
  }

  test_genericTypesAs_js_type_generic_as_unrelated_js_type_generic() async {
    await _testCasts([_AsCast('List<JSBoolean>', 'List<JSUint8List>')]);
  }

  test_genericTypesAs_js_type_generic_as_unrelated_js_type_generic_with_unrelated_container() async {
    await _testCasts(
        [_AsCast('List<JSBoolean>', 'Set<JSUint8List>', lint: false)]);
  }

  test_genericTypesAs_js_type_generic_with_container_inheritance_as() async {
    await _testCasts([
      _AsCast('List<JSBoolean>', 'Iterable<JSBoolean>', lint: false),
      _AsCast('Iterable<JSObject>', 'List<JSObject>', lint: false),
      _AsCast('List<JSBoolean>', 'Iterable<JSAny>', lint: false),
      _AsCast('Iterable<JSArray>', 'List<JSObject>', lint: false),
      _AsCast('List<JSAny>', 'Iterable<JSBoolean>', lint: false),
      _AsCast('Iterable<JSObject>', 'List<JSArray>', lint: false),
      // TODO(srujzs): These should be errors as there is a side cast within the
      // generics, and you can't declare a class that subtypes both the left
      // and right type, but `canBeSubtypeOf` doesn't nest in this case.
      _AsCast('List<JSString>', 'Iterable<JSBoolean>', lint: false),
      _AsCast('Iterable<JSBoolean>', 'List<JSString>', lint: false)
    ]);
  }

  test_genericTypesAs_top_type_generic_as_js_type_generic() async {
    await _testCasts([
      _AsCast('List<Object>', 'List<JSAny>', lint: false),
      _AsCast('List<dynamic>', 'List<JSArray>', lint: false)
    ]);
  }

  test_genericTypesIs_dart_type_generic_is_js_type_generic() async {
    await _testChecks([_IsCheck('List<int>', 'List<JSNumber>')]);
  }

  // For the purpose of this lint, generics on `dart:js_interop` types are
  // ignored.
  test_genericTypesIs_generic_js_type_is_generic_js_type() async {
    await _testChecks([
      _IsCheck('JSArray<JSString>', 'JSArray<JSAny>',
          lint: false, unnecessary: true),
      _IsCheck('JSArray<JSAny>', 'JSArray<JSString>', lint: false),
      _IsCheck('JSArray<JSString>', 'JSArray<JSBoolean>', lint: false)
    ]);
  }

  test_genericTypesIs_generic_type_with_multiple_type_parameter_is() async {
    await _testChecks([
      _IsCheck('Map<JSBoolean, JSBoolean>', 'Map<JSBoolean, JSBoolean>',
          lint: false, unnecessary: true),
      _IsCheck('Map<JSObject, JSString>', 'Map<JSAny, JSAny>',
          lint: false, unnecessary: true),
      _IsCheck('Map<JSObject, JSString>', 'Map<JSAny, JSBoolean>'),
      _IsCheck('Map<JSAny, JSString>', 'Map<JSObject, JSString>'),
      _IsCheck('Map<JSAny, JSString>', 'Map<JSObject, JSBoolean>')
    ]);
  }

  test_genericTypesIs_js_type_generic_is_dart_type_generic() async {
    await _testChecks([_IsCheck('List<JSString>', 'List<String>')]);
  }

  test_genericTypesIs_js_type_generic_is_same_js_type_generic() async {
    await _testChecks([
      _IsCheck('Set<JSString>', 'Set<JSString>', lint: false, unnecessary: true)
    ]);
  }

  test_genericTypesIs_js_type_generic_is_subtype_generic() async {
    await _testChecks([_IsCheck('List<JSAny>', 'List<JSObject>')]);
  }

  test_genericTypesIs_js_type_generic_is_supertype_generic() async {
    await _testChecks([
      _IsCheck('Future<JSArray>', 'Future<JSObject>',
          lint: false, unnecessary: true)
    ]);
  }

  test_genericTypesIs_js_type_generic_is_top_type_generic() async {
    await _testChecks([
      _IsCheck('List<JSAny>', 'List<Object>', lint: false, unnecessary: true),
      _IsCheck('List<JSAny>', 'List<dynamic>', lint: false, unnecessary: true)
    ]);
  }

  test_genericTypesIs_js_type_generic_is_unrelated_js_type_generic() async {
    await _testChecks([_IsCheck('List<JSBoolean>', 'List<JSUint8List>')]);
  }

  test_genericTypesIs_js_type_generic_is_unrelated_js_type_generic_with_unrelated_container() async {
    await _testChecks(
        [_IsCheck('List<JSBoolean>', 'Set<JSUint8List>', lint: false)]);
  }

  test_genericTypesIs_js_type_generic_with_container_inheritance_is() async {
    await _testChecks([
      _IsCheck('List<JSBoolean>', 'Iterable<JSBoolean>',
          lint: false, unnecessary: true),
      _IsCheck('Iterable<JSObject>', 'List<JSObject>', lint: false),
      _IsCheck('List<JSBoolean>', 'Iterable<JSAny>',
          lint: false, unnecessary: true),
      _IsCheck('Iterable<JSArray>', 'List<JSObject>', lint: false),
      // TODO(srujzs): These should be errors as there is a subtype or unrelated
      // check within the generics, and you can't declare a class that subtypes
      // both the left and right type, but `canBeSubtypeOf` doesn't nest in this
      // case.
      _IsCheck('List<JSAny>', 'Iterable<JSBoolean>', lint: false),
      _IsCheck('Iterable<JSObject>', 'List<JSArray>', lint: false),
      _IsCheck('List<JSString>', 'Iterable<JSBoolean>', lint: false),
      _IsCheck('Iterable<JSBoolean>', 'List<JSString>', lint: false)
    ]);
  }

  test_genericTypesIs_top_type_generic_is_js_type_generic() async {
    await _testChecks([
      _IsCheck('List<Object>', 'List<JSAny>'),
      _IsCheck('List<dynamic>', 'List<JSArray>')
    ]);
  }

  test_nullabilityAs_js_type_as_js_type() async {
    await _testCasts([
      _AsCast('JSAny?', 'JSAny', lint: false),
      _AsCast('JSAny', 'JSAny?', lint: false),
      _AsCast('JSAny?', 'JSAny?', lint: false, unnecessary: true),
      _AsCast('JSAny?', 'JSArray', lint: false),
      _AsCast('JSAny', 'JSArray?', lint: false),
      _AsCast('JSAny?', 'JSArray?', lint: false),
      _AsCast('JSArray', 'JSAny?', lint: false),
      _AsCast('JSArray?', 'JSAny', lint: false),
      _AsCast('JSArray?', 'JSAny?', lint: false),
      _AsCast('JSString?', 'JSArray'),
      _AsCast('JSString', 'JSArray?'),
      _AsCast('JSString?', 'JSArray?')
    ]);
  }

  test_nullabilityAs_null_as_js_type() async {
    await assertDiagnostics('''
    import 'dart:js_interop';

    void foo() {
      null as JSAny;
      null as JSArray?;
    }
    ''', [error(WarningCode.CAST_FROM_NULL_ALWAYS_FAILS, 54, 13)]);
  }

  test_nullabilityAs_user_interop_type_as_user_interop_type() async {
    await _testCasts([
      _AsCast('A', 'A?', lint: false),
      _AsCast('A?', 'A', lint: false),
      _AsCast('A?', 'A?', lint: false, unnecessary: true),
      _AsCast('A?', 'B', lint: false),
      _AsCast('A', 'B?', lint: false),
      _AsCast('A?', 'B?', lint: false),
      _AsCast('B?', 'A', lint: false),
      _AsCast('B', 'A?', lint: false),
      _AsCast('B?', 'A?', lint: false)
    ], typeDeclarations: [
      r'''
      extension type A(JSObject _) {}
      ''',
      r'''
      extension type B(JSObject _) implements A {}
      '''
    ]);
  }

  test_nullabilityIs_js_type_is_js_type() async {
    await _testChecks([
      _IsCheck('JSAny?', 'JSAny', lint: false),
      _IsCheck('JSAny', 'JSAny?', lint: false, unnecessary: true),
      _IsCheck('JSAny?', 'JSAny?', lint: false, unnecessary: true),
      _IsCheck('JSAny?', 'JSArray'),
      _IsCheck('JSAny', 'JSArray?'),
      _IsCheck('JSAny?', 'JSArray?'),
      _IsCheck('JSArray', 'JSAny?', lint: false, unnecessary: true),
      _IsCheck('JSArray?', 'JSAny', lint: false),
      _IsCheck('JSArray?', 'JSAny?', lint: false, unnecessary: true),
      _IsCheck('JSString?', 'JSArray'),
      _IsCheck('JSString', 'JSArray?'),
      _IsCheck('JSString?', 'JSArray?')
    ]);
  }

  test_nullabilityIs_null_is_js_type() async {
    await assertDiagnostics('''
    import 'dart:js_interop';

    void foo() {
      null is JSAny;
      null is JSArray?;
    }
    ''', [error(WarningCode.UNNECESSARY_TYPE_CHECK_TRUE, 75, 16)]);
  }

  test_nullabilityIs_user_interop_type_is_user_interop_type() async {
    await _testChecks([
      _IsCheck('A', 'A?', lint: false, unnecessary: true),
      _IsCheck('A?', 'A', lint: false),
      _IsCheck('A?', 'A?', lint: false, unnecessary: true),
      _IsCheck('A?', 'B'),
      _IsCheck('A', 'B?'),
      _IsCheck('A?', 'B?'),
      _IsCheck('B?', 'A', lint: false),
      _IsCheck('B', 'A?', lint: false, unnecessary: true),
      _IsCheck('B?', 'A?', lint: false, unnecessary: true)
    ], typeDeclarations: [
      r'''
      extension type A(JSObject _) {}
      ''',
      r'''
      extension type B(JSObject _) implements A {}
      '''
    ]);
  }

  test_staticInteropAs_js_type_as_static_interop_type() async {
    await _testCasts([
      _AsCast('JSAny', 'A', lint: false),
      _AsCast('JSObject', 'A', lint: false),
      _AsCast('JSArray', 'A', lint: false),
      _AsCast('JSBoolean', 'A')
    ], typeDeclarations: [
      r'''
      @JS()
      @staticInterop
      class A {}
      '''
    ]);
  }

  test_staticInteropAs_static_interop_type_as_js_type() async {
    await _testCasts([
      _AsCast('A', 'JSAny', lint: false),
      _AsCast('A', 'JSObject', lint: false),
      _AsCast('A', 'JSArray', lint: false),
      _AsCast('A', 'JSBoolean')
    ], typeDeclarations: [
      r'''
      @JS()
      @staticInterop
      class A {}
      '''
    ]);
  }

  test_staticInteropAs_static_interop_type_as_unrelated_type() async {
    await _testCasts([
      _AsCast('A', 'String')
    ], typeDeclarations: [
      r'''
      @JS()
      @staticInterop
      class A {}
      '''
    ]);
  }

  test_staticInteropAs_unrelated_type_as_static_interop_type() async {
    await _testCasts([
      _AsCast('String', 'A')
    ], typeDeclarations: [
      r'''
      @JS()
      @staticInterop
      class A {}
      '''
    ]);
  }

  // Since A is an unrelated type, we warn users so they don't think a runtime
  // check is done to ensure the value actually is an A.
  test_staticInteropIs_js_type_is_static_interop_type() async {
    await _testChecks([
      _IsCheck('JSAny', 'A'),
      _IsCheck('JSObject', 'A'),
      _IsCheck('JSArray', 'A'),
      _IsCheck('JSBoolean', 'A')
    ], typeDeclarations: [
      r'''
      @JS()
      @staticInterop
      class A {}
      '''
    ]);
  }

  test_staticInteropIs_static_interop_type_is_js_type() async {
    await _testChecks([
      _IsCheck('A', 'JSAny', lint: false),
      _IsCheck('A', 'JSObject', lint: false),
      _IsCheck('A', 'JSArray'),
      _IsCheck('A', 'JSBoolean')
    ], typeDeclarations: [
      r'''
      @JS()
      @staticInterop
      class A {}
      '''
    ]);
  }

  test_staticInteropIs_static_interop_type_is_unrelated_type() async {
    await _testChecks([
      _IsCheck('A', 'String')
    ], typeDeclarations: [
      r'''
      @JS()
      @staticInterop
      class A {}
      '''
    ]);
  }

  test_staticInteropIs_unrelated_type_is_static_interop_type() async {
    await _testChecks([
      _IsCheck('String', 'A')
    ], typeDeclarations: [
      r'''
      @JS()
      @staticInterop
      class A {}
      '''
    ]);
  }

  test_typeParametersAs_js_type_as_js_type_parameter() async {
    await _testCasts([
      _AsCast('JSAny', 'T', lint: false),
      _AsCast('JSObject', 'T', lint: false),
      _AsCast('JSBoolean', 'T'),
      // This may or may not be a side cast, so warn.
      _AsCast('JSArray', 'T')
    ], typeParameters: [
      'T extends JSObject'
    ]);
  }

  test_typeParametersAs_js_type_parameter_as_js_type() async {
    await _testCasts([
      _AsCast('T', 'JSAny', lint: false),
      _AsCast('T', 'JSObject', lint: false),
      _AsCast('T', 'JSBoolean'),
      // This may or may not be a side cast, so warn.
      _AsCast('T', 'JSUint8List')
    ], typeParameters: [
      'T extends JSObject'
    ]);
  }

  test_typeParametersAs_js_type_parameter_as_js_type_parameter() async {
    await _testCasts([
      _AsCast('T', 'T', lint: false, unnecessary: true),
      _AsCast('U', 'U', lint: false, unnecessary: true),
      _AsCast('V', 'V', lint: false, unnecessary: true),
      _AsCast('T', 'U'),
      _AsCast('U', 'T'),
      _AsCast('T', 'V'),
      _AsCast('V', 'T'),
      _AsCast('U', 'V'),
      _AsCast('V', 'U')
    ], typeParameters: [
      'T extends JSAny',
      'U extends JSArray',
      'V extends JSBoolean'
    ]);
  }

  test_typeParametersAs_nested_user_interop_type_parameter_as_user_interop_type() async {
    await _testCasts([
      _AsCast('T', 'A?', lint: false),
      _AsCast('U?', 'A', lint: false),
      _AsCast('V', 'A?', lint: false),
      _AsCast('W?', 'A', lint: false),
      _AsCast('X', 'A', lint: false),
      _AsCast('Y?', 'A', lint: false)
    ], typeParameters: [
      'T extends A',
      'U extends B?',
      'V extends T',
      'W extends U',
      'X extends T?',
      'Y extends U?'
    ], typeDeclarations: [
      r'''
      extension type A(JSObject _) {}
      ''',
      r'''
      extension type B(JSObject _) {}
      '''
    ]);
  }

  test_typeParametersAs_unrelated_type_as_js_type_parameter() async {
    await _testCasts([_AsCast('String', 'T')],
        typeParameters: ['T extends JSAny']);
  }

  test_typeParametersAs_unrelated_type_parameter_as_js_type() async {
    await _testCasts([_AsCast('T', 'JSAny'), _AsCast('U', 'JSNumber')],
        typeParameters: ['T', 'U extends int']);
  }

  test_typeParametersAs_user_interop_type_parameter_as() async {
    await _testCasts([
      _AsCast('T', 'JSAny', lint: false),
      _AsCast('U', 'JSObject', lint: false),
      _AsCast('T', 'JSUint8List'),
      _AsCast('U', 'JSArray'),
      _AsCast('JSAny', 'T', lint: false),
      _AsCast('JSObject', 'U', lint: false),
      _AsCast('JSUint8List', 'T'),
      _AsCast('JSArray', 'U'),
      _AsCast('T', 'A', lint: false),
      _AsCast('T', 'B', lint: false),
      _AsCast('U', 'A'),
      _AsCast('U', 'B', lint: false),
      _AsCast('A', 'T', lint: false),
      _AsCast('A', 'U'),
      _AsCast('B', 'T', lint: false),
      _AsCast('B', 'U', lint: false),
      _AsCast('T', 'U'),
      _AsCast('U', 'T')
    ], typeParameters: [
      'T extends A',
      'U extends B'
    ], typeDeclarations: [
      r'''
      extension type A(JSTypedArray _) {}
      ''',
      r'''
      @JS()
      @staticInterop
      class B {}
      '''
    ]);
  }

  test_typeParametersIs_js_type_is_js_type_parameter() async {
    await _testChecks([
      _IsCheck('JSAny', 'T'),
      _IsCheck('JSObject', 'T'),
      _IsCheck('JSBoolean', 'T'),
      // This may or may not be an `is` check between unrelated types, so warn.
      _IsCheck('JSArray', 'T')
    ], typeParameters: [
      'T extends JSObject'
    ]);
  }

  test_typeParametersIs_js_type_parameter_is_js_type() async {
    await _testChecks([
      _IsCheck('T', 'JSAny', lint: false, unnecessary: true),
      _IsCheck('T', 'JSObject', lint: false, unnecessary: true),
      _IsCheck('T', 'JSBoolean'),
      // This may or may not be an `is` check between unrelated types, so warn.
      _IsCheck('T', 'JSUint8List')
    ], typeParameters: [
      'T extends JSObject'
    ]);
  }

  test_typeParametersIs_js_type_parameter_is_js_type_parameter() async {
    await _testChecks([
      _IsCheck('T', 'T', lint: false, unnecessary: true),
      _IsCheck('U', 'U', lint: false, unnecessary: true),
      _IsCheck('V', 'V', lint: false, unnecessary: true),
      _IsCheck('T', 'U'),
      _IsCheck('U', 'T'),
      _IsCheck('T', 'V'),
      _IsCheck('V', 'T'),
      _IsCheck('U', 'V'),
      _IsCheck('V', 'U')
    ], typeParameters: [
      'T extends JSAny',
      'U extends JSArray',
      'V extends JSBoolean'
    ]);
  }

  test_typeParametersIs_nested_user_interop_type_parameter_is_user_interop_type() async {
    await _testChecks([
      _IsCheck('T', 'A?', lint: false, unnecessary: true),
      _IsCheck('U?', 'A'),
      _IsCheck('V', 'A?', lint: false, unnecessary: true),
      _IsCheck('W?', 'A'),
      _IsCheck('X', 'A', lint: false),
      _IsCheck('Y?', 'A')
    ], typeParameters: [
      'T extends A',
      'U extends B?',
      'V extends T',
      'W extends U',
      'X extends T?',
      'Y extends U?'
    ], typeDeclarations: [
      r'''
      extension type A(JSObject _) {}
      ''',
      r'''
      extension type B(JSObject _) {}
      '''
    ]);
  }

  test_typeParametersIs_unrelated_type_is_js_type_parameter() async {
    await _testChecks([_IsCheck('String', 'T')],
        typeParameters: ['T extends JSAny']);
  }

  test_typeParametersIs_unrelated_type_parameter_is_js_type() async {
    await _testChecks([_IsCheck('T', 'JSAny'), _IsCheck('U', 'JSNumber')],
        typeParameters: ['T', 'U extends int']);
  }

  test_typeParametersIs_user_interop_type_parameter_is() async {
    await _testChecks([
      _IsCheck('T', 'JSAny', lint: false),
      _IsCheck('U', 'JSObject', lint: false),
      _IsCheck('T', 'JSUint8List'),
      _IsCheck('U', 'JSArray'),
      _IsCheck('JSAny', 'T'),
      _IsCheck('JSObject', 'U'),
      _IsCheck('JSUint8List', 'T'),
      _IsCheck('JSArray', 'U'),
      _IsCheck('T', 'A', lint: false, unnecessary: true),
      _IsCheck('T', 'B'),
      _IsCheck('U', 'A'),
      _IsCheck('U', 'B', lint: false, unnecessary: true),
      _IsCheck('A', 'T'),
      _IsCheck('A', 'U'),
      _IsCheck('B', 'T'),
      _IsCheck('B', 'U'),
      _IsCheck('T', 'U'),
      _IsCheck('U', 'T')
    ], typeParameters: [
      'T extends A',
      'U extends B'
    ], typeDeclarations: [
      r'''
      extension type A(JSTypedArray _) {}
      ''',
      r'''
      @JS()
      @staticInterop
      class B {}
      '''
    ]);
  }

  test_userInteropAs_js_type_as_user_interop_type() async {
    await _testCasts([
      _AsCast('JSAny', 'A', lint: false),
      _AsCast('JSObject', 'A', lint: false),
      _AsCast('JSArray', 'A', lint: false),
      _AsCast('JSBoolean', 'A')
    ], typeDeclarations: [
      r'''
      extension type A(JSObject _) {}
      '''
    ]);
  }

  test_userInteropAs_nested_user_interop_type_as_js_type() async {
    await _testCasts([
      _AsCast('B', 'JSAny', lint: false),
      _AsCast('B', 'JSObject', lint: false),
      _AsCast('B', 'JSArray', lint: false),
      _AsCast('B', 'JSBoolean')
    ], typeDeclarations: [
      r'''
      extension type A(JSObject _) implements JSObject {}
      ''',
      r'''
      extension type B(A _) implements A {}
      '''
    ]);
  }

  test_userInteropAs_user_interop_type_as_js_type() async {
    await _testCasts([
      _AsCast('A', 'JSAny', lint: false),
      _AsCast('A', 'JSObject', lint: false),
      _AsCast('A', 'JSArray', lint: false),
      _AsCast('A', 'JSBoolean')
    ], typeDeclarations: [
      r'''
      extension type A(JSObject _) {}
      '''
    ]);
  }

  test_userInteropAs_user_interop_type_as_user_interop_type() async {
    await _testCasts([
      _AsCast('A', 'A', lint: false, unnecessary: true),
      _AsCast('A', 'B', lint: false),
      _AsCast('A', 'C'),
      _AsCast('B', 'A', lint: false),
      _AsCast('B', 'B', lint: false, unnecessary: true),
      _AsCast('B', 'C'),
      _AsCast('C', 'A'),
      _AsCast('C', 'B'),
      _AsCast('C', 'C', lint: false, unnecessary: true)
    ], typeDeclarations: [
      r'''
      extension type A(JSObject _) {}
      ''',
      r'''
      extension type B(JSObject _) implements A {}
      ''',
      r'''
      extension type C(JSBoolean _) {}
      '''
    ]);
  }

  // Since A is an unrelated type, we warn users so they don't think a runtime
  // check is done to ensure the value actually is an A.
  test_userInteropIs_js_type_is_user_interop_type() async {
    await _testChecks([
      _IsCheck('JSAny', 'A'),
      _IsCheck('JSObject', 'A'),
      _IsCheck('JSArray', 'A'),
      _IsCheck('JSBoolean', 'A')
    ], typeDeclarations: [
      r'''
      extension type A(JSObject _) {}
      '''
    ]);
  }

  test_userInteropIs_nested_user_interop_type_is_js_type() async {
    await _testChecks([
      _IsCheck('B', 'JSAny', lint: false, unnecessary: true),
      _IsCheck('B', 'JSObject', lint: false, unnecessary: true),
      _IsCheck('B', 'JSArray'),
      _IsCheck('B', 'JSBoolean')
    ], typeDeclarations: [
      r'''
      extension type A(JSObject _) implements JSObject {}
      ''',
      r'''
      extension type B(A _) implements A {}
      '''
    ]);
  }

  test_userInteropIs_user_interop_type_is_js_type() async {
    await _testChecks([
      _IsCheck('A', 'JSAny', lint: false),
      _IsCheck('A', 'JSObject', lint: false),
      _IsCheck('A', 'JSArray'),
      _IsCheck('A', 'JSBoolean')
    ], typeDeclarations: [
      r'''
      extension type A(JSObject _) {}
      '''
    ]);
  }

  test_userInteropIs_user_interop_type_is_user_interop_type() async {
    await _testChecks([
      _IsCheck('A', 'A', lint: false, unnecessary: true),
      _IsCheck('A', 'B'),
      _IsCheck('A', 'C'),
      _IsCheck('B', 'A', lint: false, unnecessary: true),
      _IsCheck('B', 'B', lint: false, unnecessary: true),
      _IsCheck('B', 'C'),
      _IsCheck('C', 'A'),
      _IsCheck('C', 'B'),
      _IsCheck('C', 'C', lint: false, unnecessary: true)
    ], typeDeclarations: [
      r'''
      extension type A(JSObject _) {}
      ''',
      r'''
      extension type B(JSObject _) implements A {}
      ''',
      r'''
      extension type C(JSBoolean _) {}
      '''
    ]);
  }

  test_wasmIncompatibleTypesAs_dart_html_type_as_js_type() async {
    await _testCasts([
      _AsCast('Event', 'JSAny', lint: false),
      _AsCast('Event', 'JSString', lint: false),
      _AsCast('Event', 'JSObject', lint: false)
    ]);
  }

  test_wasmIncompatibleTypesAs_dart_js_type_as_js_type() async {
    await _testCasts([_AsCast('JsObject', 'JSAny', lint: false)]);
  }

  test_wasmIncompatibleTypesAs_js_type_as_dart_html_type() async {
    await _testCasts([
      _AsCast('JSString', 'Event', lint: false),
      _AsCast('JSString', 'Window', lint: false)
    ]);
  }

  test_wasmIncompatibleTypesAs_js_type_as_dart_js_type() async {
    await _testCasts([_AsCast('JSAny', 'JsObject', lint: false)]);
  }

  test_wasmIncompatibleTypesAs_js_type_as_package_js_type() async {
    await _testCasts([
      _AsCast('JSAny', 'A', lint: false),
      _AsCast('JSString', 'B', lint: false)
    ], typeDeclarations: [
      r'''
      @js.JS()
      class A {}
      ''',
      r'''
      @js.JS()
      @js.staticInterop
      class B {}'''
    ]);
  }

  test_wasmIncompatibleTypesAs_js_type_parameter_as() async {
    await _testCasts([
      _AsCast('T', 'JSAny', lint: false),
      _AsCast('U', 'JSObject', lint: false),
      _AsCast('V', 'JSArray', lint: false),
      _AsCast('JSString', 'T', lint: false),
      _AsCast('JSString', 'U', lint: false),
      _AsCast('JSString', 'V', lint: false)
    ], typeParameters: [
      'T extends A',
      'U extends Event',
      'V extends JsObject'
    ], typeDeclarations: [
      r'''
      @js.JS()
      class A {}
      '''
    ]);
  }

  test_wasmIncompatibleTypesAs_package_js_type_as_js_type() async {
    await _testCasts([
      _AsCast('A', 'JSBoolean', lint: false),
      _AsCast('B', 'JSString', lint: false)
    ], typeDeclarations: [
      r'''
      @js.JS()
      class A {}
      ''',
      r'''
      @js.JS()
      @js.staticInterop
      class B {}'''
    ]);
  }

  test_wasmIncompatibleTypesIs_dart_html_type_is_js_type() async {
    await _testChecks([
      _IsCheck('Event', 'JSAny', lint: false),
      _IsCheck('Event', 'JSString', lint: false),
      _IsCheck('Event', 'JSObject', lint: false)
    ]);
  }

  test_wasmIncompatibleTypesIs_dart_js_type_is_js_type() async {
    await _testChecks([_IsCheck('JsObject', 'JSAny', lint: false)]);
  }

  test_wasmIncompatibleTypesIs_js_type_is_dart_html_type() async {
    await _testChecks([
      _IsCheck('JSString', 'Event', lint: false),
      _IsCheck('JSString', 'Window', lint: false)
    ]);
  }

  test_wasmIncompatibleTypesIs_js_type_is_dart_js_type() async {
    await _testChecks([_IsCheck('JSAny', 'JsObject', lint: false)]);
  }

  test_wasmIncompatibleTypesIs_js_type_is_package_js_type() async {
    await _testChecks([
      _IsCheck('JSAny', 'A', lint: false),
      _IsCheck('JSString', 'B', lint: false)
    ], typeDeclarations: [
      r'''
      @js.JS()
      class A {}
      ''',
      r'''
      @js.JS()
      @js.staticInterop
      class B {}'''
    ]);
  }

  test_wasmIncompatibleTypesIs_js_type_parameter_is() async {
    await _testChecks([
      _IsCheck('T', 'JSAny', lint: false),
      _IsCheck('U', 'JSObject', lint: false),
      _IsCheck('V', 'JSArray', lint: false),
      _IsCheck('JSString', 'T', lint: false),
      _IsCheck('JSString', 'U', lint: false),
      _IsCheck('JSString', 'V', lint: false)
    ], typeParameters: [
      'T extends A',
      'U extends Event',
      'V extends JsObject'
    ], typeDeclarations: [
      r'''
      @js.JS()
      class A {}
      '''
    ]);
  }

  test_wasmIncompatibleTypesIs_package_js_type_is_js_type() async {
    await _testChecks([
      _IsCheck('A', 'JSBoolean', lint: false),
      _IsCheck('B', 'JSString', lint: false)
    ], typeDeclarations: [
      r'''
      @js.JS()
      class A {}
      ''',
      r'''
      @js.JS()
      @js.staticInterop
      class B {}'''
    ]);
  }

  /// Given a list of JS interop [typeTests], constructs code to execute a type
  /// test for each entry and then asserts that the lint and warning
  /// expectations were correct for each type test.
  ///
  /// If [typeParameters] is not empty, declares the type parameters in the
  /// function executing the tests.
  ///
  /// If [typeDeclarations] is not empty, declares the types before the function
  /// executing the tests.
  ///
  /// If [cast] is true, uses `as` for the type test. Otherwise, uses `is`.
  Future<void> _assertDiagnosticsWithTypeTests(List<_TypeTest> typeTests,
      {required List<String> typeParameters,
      required List<String> typeDeclarations,
      required bool cast}) {
    var lints = <ExpectedDiagnostic>[];
    var code =
        StringBuffer("// ignore: unused_import\nimport 'dart:html' hide JS;\n"
            "// ignore: unused_import\nimport 'dart:js';\n"
            "import 'dart:js_interop';\n"
            "// ignore: unused_import\nimport 'package:js/js.dart' as js;\n");
    for (var typeDeclaration in typeDeclarations) {
      code.write('$typeDeclaration\n');
    }
    code.write('void foo');
    if (typeParameters.isNotEmpty) code.write('<${typeParameters.join(',')}>');
    code.write('(');
    var tempVarCount = 1;
    for (var typeTest in typeTests) {
      code.write('${typeTest.valueType} t${tempVarCount++}, ');
    }
    code.write(') {\n');
    tempVarCount = 1;
    for (var typeTest in typeTests) {
      var test = 't${tempVarCount++} ${cast ? 'as' : 'is'} ${typeTest.type}';
      if (typeTest.lint) lints.add(lint(code.length, test.length));
      if (typeTest.unnecessary) {
        if (cast) {
          lints.add(
              error(WarningCode.UNNECESSARY_CAST, code.length, test.length));
        } else {
          lints.add(error(WarningCode.UNNECESSARY_TYPE_CHECK_TRUE, code.length,
              test.length));
        }
      }
      code.write('$test;\n');
    }
    code.write('}\n');
    return assertDiagnostics(code.toString(), lints);
  }

  Future<void> _testCasts(List<_AsCast> typeTests,
          {List<String> typeParameters = const [],
          List<String> typeDeclarations = const []}) =>
      _assertDiagnosticsWithTypeTests(typeTests,
          typeParameters: typeParameters,
          typeDeclarations: typeDeclarations,
          cast: true);

  Future<void> _testChecks(List<_IsCheck> typeTests,
          {List<String> typeParameters = const [],
          List<String> typeDeclarations = const []}) =>
      _assertDiagnosticsWithTypeTests(typeTests,
          typeDeclarations: typeDeclarations,
          typeParameters: typeParameters,
          cast: false);
}

/// Represents an `as` cast from a value of type [valueType] to [type].
final class _AsCast extends _TypeTest {
  _AsCast(super.valueType, super.type, {super.lint, super.unnecessary});
}

/// Represents an `is` check against [type] where the value is of type
/// [valueType].
final class _IsCheck extends _TypeTest {
  _IsCheck(super.valueType, super.type, {super.lint, super.unnecessary});
}

/// Represents a type test using a runtime check.
abstract class _TypeTest {
  String valueType;
  String type;

  /// Whether this type test should emit a lint.
  bool lint;

  /// Whether this type test was trivially true, which determines whether the
  /// test should ignore the related warning.
  bool unnecessary;

  _TypeTest(this.valueType, this.type,
      {this.lint = true, this.unnecessary = false});
}
