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

ast.TypeReference _simple(String name) => ast.TypeReference(name);

ast.UnionType _union(List<String> names) =>
    ast.UnionType(names.map(_simple).toList());

@reflectiveTest
class DartTest {
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
