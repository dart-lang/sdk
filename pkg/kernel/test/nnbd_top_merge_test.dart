// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart" show Expect;

import 'package:kernel/ast.dart' hide MapEntry;
import 'package:kernel/src/nnbd_top_merge.dart';
import 'package:kernel/testing/type_parser_environment.dart';

const Map<String, dynamic> data = {
  'Object? vs Object?': 'Object?',
  'Object* vs Object?': 'Object?',
  'Object vs Object?': null,
  'Object* vs Object': 'Object',
  'Object* vs Object*': 'Object*',
  'Object vs Object': 'Object',
  'dynamic vs dynamic': 'dynamic',
  'void vs void': 'void',
  'Object? vs void': 'Object?',
  'Object* vs void': 'Object?',
  'Object vs void': null,
  'dynamic vs void': 'Object?',
  'Object? vs dynamic': 'Object?',
  'Object* vs dynamic': 'Object?',
  'Object vs dynamic': null,
  'Never? vs Null': null,
  'Never* vs Null': 'Null',
  'Never vs Null': null,
  'int? vs int?': 'int?',
  'int? vs int*': 'int?',
  'int* vs int*': 'int*',
  'int* vs int': 'int',
  'int vs int': 'int',
  'int? vs int': null,
  'List<Object?> vs List<Object?>': 'List<Object?>',
  'List<Object*> vs List<Object?>': 'List<Object?>',
  'List<Object*> vs List<Object*>': 'List<Object*>',
  'List<Object> vs List<Object?>': null,
  'List<Object*> vs List<Object>': 'List<Object>',
  'List<Object> vs List<Object>': 'List<Object>',
  'List<dynamic> vs List<dynamic>': 'List<dynamic>',
  'List<void> vs List<void>': 'List<void>',
  'List<Object?> vs List<void>': 'List<Object?>',
  'List<Object*> vs List<void>': 'List<Object?>',
  'List<Object> vs List<void>': null,
  'List<dynamic> vs List<void>': 'List<Object?>',
  'List<Object?> vs List<dynamic>': 'List<Object?>',
  'List<Object*> vs List<dynamic>': 'List<Object?>',
  'List<Object> vs List<dynamic>': null,
  'List<Never?> vs List<Null>': null,
  'List<Never*> vs List<Null>': 'List<Null>',
  'List<Never> vs List<Null>': null,
  'List<int?> vs List<int?>': 'List<int?>',
  'List<int?> vs List<int*>': 'List<int?>',
  'List<int*> vs List<int*>': 'List<int*>',
  'List<int*> vs List<int>': 'List<int>',
  'List<int> vs List<int>': 'List<int>',
  'List<int?> vs List<int>': null,
  '() ->? void vs () ->? void': '() ->? void',
  '() ->? void vs () ->* void': '() ->? void',
  '() ->* void vs () ->* void': '() ->* void',
  '() ->* void vs () -> void': '() -> void',
  '() -> void vs () -> void': '() -> void',
  '() ->? void vs () -> void': null,
  '(int?) -> void vs (int?) -> void': '(int?) -> void',
  '(int?) -> void vs (int*) -> void': '(int?) -> void',
  '(int*) -> void vs (int*) -> void': '(int*) -> void',
  '(int*) -> void vs (int) -> void': '(int) -> void',
  '(int) -> void vs (int) -> void': '(int) -> void',
  '(int?) -> void vs (int) -> void': null,
  '([int?]) -> void vs ([int?]) -> void': '([int?]) -> void',
  '([int?]) -> void vs ([int*]) -> void': '([int?]) -> void',
  '([int*]) -> void vs ([int*]) -> void': '([int*]) -> void',
  '([int*]) -> void vs ([int]) -> void': '([int]) -> void',
  '([int]) -> void vs ([int]) -> void': '([int]) -> void',
  '([int?]) -> void vs ([int]) -> void': null,
  '({int? a}) -> void vs ({int? a}) -> void': '({int? a}) -> void',
  '({int? a}) -> void vs ({int* a}) -> void': '({int? a}) -> void',
  '({int* a}) -> void vs ({int* a}) -> void': '({int* a}) -> void',
  '({int* a}) -> void vs ({int a}) -> void': '({int a}) -> void',
  '({int a}) -> void vs ({int a}) -> void': '({int a}) -> void',
  '({int? a}) -> void vs ({int a}) -> void': null,
  '({required int? a}) -> void vs ({required int? a}) -> void':
      '({required int? a}) -> void',
  '({required int? a}) -> void vs ({required int* a}) -> void':
      '({required int? a}) -> void',
  '({required int* a}) -> void vs ({required int* a}) -> void':
      '({required int* a}) -> void',
  '({required int* a}) -> void vs ({required int a}) -> void':
      '({required int a}) -> void',
  '({required int? a}) -> void vs ({required int a}) -> void': null,
  '({int a, bool b}) -> void vs ({int a, bool b}) -> void':
      '({int a, bool b}) -> void',
  '({int a, bool b}) -> void vs ({bool b, int a}) -> void':
      '({int a, bool b}) -> void',
  '({int a, bool b}) ->* void vs ({bool b, int a}) ->? void':
      '({int a, bool b}) ->? void',
  '({int a, bool b}) -> void vs ({int a, required bool b}) -> void': null,
  '<E>(E) -> void vs <F>(F) -> void': '<E>(E) -> void',
  '<E extends int>(E) -> void vs <F extends int*>(F) -> void': [
    '<E extends int>(E) -> void',
    '<F extends int>(F) -> void'
  ],
  '<E extends List<E>>(E) -> void vs <F extends List<F>>(F) -> void':
      '<E extends List<E>>(E) -> void',
  '<E extends List<E>>(E) -> void vs <F extends List<F>*>(F) -> void': [
    '<E extends List<E>>(E) -> void',
    '<F extends List<F>>(F) -> void'
  ],
};

main() {
  Env env = new Env('', isNonNullableByDefault: true);
  data.forEach((String input, dynamic output) {
    List<String> parts = input.split(' vs ');
    DartType aType = env.parseType(parts[0]);
    DartType bType = env.parseType(parts[1]);
    DartType expectedOutputType1;
    DartType expectedOutputType2;
    if (output is List) {
      expectedOutputType1 = env.parseType(output[0]);
      expectedOutputType2 = env.parseType(output[1]);
    } else if (output is String) {
      expectedOutputType1 = expectedOutputType2 = env.parseType(output);
    }

    void test(DartType a, DartType b, DartType expectedOutputType) {
      DartType actualOutputType = nnbdTopMerge(env.coreTypes, a, b);
      print('nnbdTopMerge($a,$b) = '
          '$actualOutputType (expected=$expectedOutputType)');
      Expect.equals(
          expectedOutputType,
          actualOutputType,
          "Unexpected nnbd top merge of $a vs $b ('$input'):\n"
          "Expected: ${expectedOutputType} ('$output')\n"
          "Actual: ${actualOutputType}");
    }

    test(aType, bType, expectedOutputType1);
    test(bType, aType, expectedOutputType2);
  });
}
