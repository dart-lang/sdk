// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../tool/lsp_spec/meta_model.dart' as ast;

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DartTest);
  });
}

ast.ArrayType _array(String name) => ast.ArrayType(_simple(name));

/// Helper to create a constant with defaults.
ast.Constant _constant(Object value, {String name = 'x', String? type}) {
  return ast.Constant(
    name: name,
    type: type != null ? ast.TypeReference(type) : ast.TypeReference.lspAny,
    value: value.toString(),
  );
}

/// Helper to create a enum with defaults.
ast.LspEnum _enum({
  String name = 'x',
  String type = 'int',
  bool flags = false,
  required List<ast.Constant> constants,
}) {
  return ast.LspEnum(
    name: name,
    typeOfValues: ast.TypeReference(type),
    flags: flags,
    constants: constants,
  );
}

ast.TypeReference _simple(String name) => ast.TypeReference(name);

ast.UnionType _union(List<String> names) =>
    ast.UnionType(names.map(_simple).toList());

@reflectiveTest
class DartTest {
  void test_flags_requiresPowerOfTwo_double() {
    expect(
      () => _enum(flags: true, constants: [_constant(1.2)]),
      throwsArgumentError,
    );
  }

  void test_flags_requiresPowerOfTwo_nonPowerOfTwo() {
    expect(
      () => _enum(flags: true, constants: [_constant(3)]),
      throwsArgumentError,
    );
  }

  void test_flags_requiresPowerOfTwo_string() {
    expect(
      () => _enum(flags: true, constants: [_constant('test')]),
      throwsArgumentError,
    );
  }

  void test_flags_requiresUniqueValues() {
    expect(
      () => _enum(
        flags: true,
        constants: [
          _constant(1, name: 'a'),
          _constant(1, name: 'b'),
        ],
      ),
      throwsArgumentError,
    );
  }

  void test_mapping_arrays() {
    expect(_array('string').dartTypeWithTypeArgs, equals('List<String>'));
  }

  void test_mapping_basicTypes() {
    expect(_simple('string').dartType, equals('String'));
    expect(_simple('boolean').dartType, equals('bool'));
    expect(_simple('object').dartType, equals('Object?'));
    expect(_simple('int').dartType, equals('int'));
    expect(_simple('num').dartType, equals('num'));
  }

  void test_mapping_unionTypes() {
    expect(
      _union(['string', 'int']).dartTypeWithTypeArgs,
      equals('Either2<int, String>'),
    );
  }
}
