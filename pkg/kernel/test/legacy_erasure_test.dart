// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart" show Expect;

import 'package:kernel/ast.dart' hide MapEntry;
import 'package:kernel/src/legacy_erasure.dart';
import 'package:kernel/testing/type_parser_environment.dart';

const Map<String, String> data = {
  'Null': 'Null',
  'Never': 'Null',
  'Never?': 'Null',
  'void': 'void',
  'dynamic': 'dynamic',
  'bool': 'bool*',
  'bool?': 'bool*',
  'bool*': 'bool*',
  'List<bool>': 'List<bool*>*',
  'List<bool?>': 'List<bool*>*',
  'List<bool*>': 'List<bool*>*',
  'List<bool>?': 'List<bool*>*',
  'List<bool?>?': 'List<bool*>*',
  'List<bool*>?': 'List<bool*>*',
  'List<bool>*': 'List<bool*>*',
  'List<bool?>*': 'List<bool*>*',
  'List<bool*>*': 'List<bool*>*',
  '() ->* bool*': '() ->* bool*',
  '() ->? bool*': '() ->* bool*',
  '() -> bool*': '() ->* bool*',
  '() ->* bool?': '() ->* bool*',
  '() ->? bool?': '() ->* bool*',
  '() -> bool?': '() ->* bool*',
  '() ->* bool': '() ->* bool*',
  '() ->? bool': '() ->* bool*',
  '() -> bool': '() ->* bool*',
  '(int*) -> void': '(int*) ->* void',
  '(int?) -> void': '(int*) ->* void',
  '(int) -> void': '(int*) ->* void',
  '([int*]) -> void': '([int*]) ->* void',
  '([int?]) -> void': '([int*]) ->* void',
  '([int]) -> void': '([int*]) ->* void',
  '({int* a}) -> void': '({int* a}) ->* void',
  '({int? a}) -> void': '({int* a}) ->* void',
  '({int a}) -> void': '({int* a}) ->* void',
  '({required int* a}) -> void': '({int* a}) ->* void',
  '({required int? a}) -> void': '({int* a}) ->* void',
  '({required int a}) -> void': '({int* a}) ->* void',
  '<T>(T) -> void': '<T extends Object*>(T) ->* void',
  '<T>(T?) -> void': '<T extends Object*>(T*) ->* void',
  '<T extends bool>(T) -> void': '<T extends bool*>(T) ->* void',
  '<T extends List<T>>(T) -> void': '<T extends List<T*>*>(T) ->* void',
};

main() {
  Env env = new Env('', isNonNullableByDefault: true);
  data.forEach((String input, String output) {
    DartType inputType = env.parseType(input);
    DartType expectedOutputType = env.parseType(output);
    DartType actualOutputType = legacyErasure(inputType);
    print('legacyErasure($inputType) = $actualOutputType: $expectedOutputType');
    Expect.equals(
        expectedOutputType,
        actualOutputType,
        "Unexpected legacy erasure of $inputType ('$input'):\n"
        "Expected: ${expectedOutputType} ('$output')\n"
        "Actual: ${actualOutputType}");
  });
}
