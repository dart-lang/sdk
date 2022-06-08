// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../../../tool/lsp_spec/meta_model.dart' as ast;

void main() {
  group('dartType mapping', () {
    test('handles basic types', () {
      expect(_simple('string').dartType, equals('String'));
      expect(_simple('boolean').dartType, equals('bool'));
      expect(_simple('any').dartType, equals('Object?'));
      expect(_simple('object').dartType, equals('Object?'));
      expect(_simple('int').dartType, equals('int'));
      expect(_simple('num').dartType, equals('num'));
    });

    test('handles union types', () {
      expect(_union(['string', 'int']).dartTypeWithTypeArgs,
          equals('Either2<int, String>'));
    });

    test('handles arrays', () {
      expect(_array('string').dartTypeWithTypeArgs, equals('List<String>'));
    });
  });
}

ast.ArrayType _array(String name) => ast.ArrayType(_simple(name));

ast.TypeReference _simple(String name) => ast.TypeReference(name);

ast.UnionType _union(List<String> names) =>
    ast.UnionType(names.map(_simple).toList());
