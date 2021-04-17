// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../../../tool/lsp_spec/typescript_parser.dart' as ast;

void main() {
  group('dartType mapping', () {
    test('handles basic types', () {
      expect(_simple('string').dartType, equals('String'));
      expect(_simple('boolean').dartType, equals('bool'));
      expect(_simple('any').dartType, equals('dynamic'));
      expect(_simple('object').dartType, equals('dynamic'));
      expect(_simple('int').dartType, equals('int'));
      expect(_simple('num').dartType, equals('num'));
    });

    test('handles union types', () {
      expect(_union(['string', 'int']).dartTypeWithTypeArgs,
          equals('Either2<String, int>'));
    });

    test('handles arrays', () {
      expect(_array('string').dartTypeWithTypeArgs, equals('List<String>'));
    });
  });
}

ast.ArrayType _array(String name) => ast.ArrayType(_simple(name));

ast.Type _simple(String name) =>
    ast.Type(ast.Token(ast.TokenType.IDENTIFIER, name), []);

ast.UnionType _union(List<String> names) =>
    ast.UnionType(names.map(_simple).toList());
