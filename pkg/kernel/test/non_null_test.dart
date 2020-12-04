// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart" show Expect;

import 'package:kernel/ast.dart' hide MapEntry;
import 'package:kernel/src/non_null.dart';
import 'package:kernel/testing/type_parser_environment.dart';

const Map<String, String> data = {
  'dynamic': 'dynamic',
  'void': 'void',
  'Null': 'Never',
  'Never': 'Never',
  'Never?': 'Never',
  'Never*': 'Never',
  'Object': 'Object',
  'Object?': 'Object',
  'Object*': 'Object',
  'List<Object>': 'List<Object>',
  'List<Object>?': 'List<Object>',
  'List<Object>*': 'List<Object>',
  'List<Object?>': 'List<Object?>',
  'List<Object?>?': 'List<Object?>',
  'List<Object?>*': 'List<Object?>',
  'List<Object*>': 'List<Object*>',
  'List<Object*>?': 'List<Object*>',
  'List<Object*>*': 'List<Object*>',
  'FutureOr<Null>': 'FutureOr<Never>',
  'FutureOr<dynamic>': 'FutureOr<dynamic>',
  'FutureOr<Object>': 'FutureOr<Object>',
  'FutureOr<Object>?': 'FutureOr<Object>',
  'FutureOr<Object>*': 'FutureOr<Object>',
  'FutureOr<Object?>': 'FutureOr<Object>',
  'FutureOr<Object?>?': 'FutureOr<Object>',
  'FutureOr<Object?>*': 'FutureOr<Object>',
  'FutureOr<Object*>': 'FutureOr<Object>',
  'FutureOr<Object*>?': 'FutureOr<Object>',
  'FutureOr<Object*>*': 'FutureOr<Object>',
  'FutureOr<FutureOr<Object?>>': 'FutureOr<FutureOr<Object>>',
  '(List<Object>, {required List<Object> a, List<Object> b}) -> List<Object>':
      '(List<Object>, {required List<Object> a, List<Object> b})'
          ' -> List<Object>',
  '(List<Object>, {required List<Object> a, List<Object> b}) ->? List<Object>':
      '(List<Object>, {required List<Object> a, List<Object> b})'
          ' -> List<Object>',
  '(List<Object>, {required List<Object> a, List<Object> b}) ->* List<Object>':
      '(List<Object>, {required List<Object> a, List<Object> b})'
          ' -> List<Object>',
  '(List<Object>?, {required List<Object?> a, List<Object?>? b})'
          ' ->? List<Object?>':
      '(List<Object>?, {required List<Object?> a, List<Object?>? b})'
          ' -> List<Object?>',
  'X': 'X & Object',
  'X?': 'X & Object',
  'X*': 'X & Object',
  'X_extends_Object': 'X_extends_Object',
  'X_extends_Object?': 'X_extends_Object',
  'X_extends_Object*': 'X_extends_Object',
  'X_extends_dynamic': 'X_extends_dynamic',
  'X_extends_dynamic?': 'X_extends_dynamic',
  'X_extends_dynamic*': 'X_extends_dynamic',
  'X & Object?': 'X & Object',
  'X & dynamic': 'X & dynamic',
  'X & Object': 'X & Object',
  'X? & Object?': 'X & Object',
  'X? & dynamic': 'X & dynamic',
  'X? & Object': 'X & Object',
  'Y': 'Y & X & Object',
  'Y?': 'Y & X & Object',
  'Y_extends_dynamic': 'Y_extends_dynamic',
  'Y_extends_dynamic?': 'Y_extends_dynamic',
  'Y_extends_dynamic*': 'Y_extends_dynamic',
  'Y_extends_dynamic & X': 'Y_extends_dynamic & X & Object',
  'Y_extends_dynamic & X_extends_dynamic?':
      'Y_extends_dynamic & X_extends_dynamic',
};

main() {
  Env env = new Env('', isNonNullableByDefault: true)
    ..extendWithTypeParameters('X,'
        'X_extends_Object extends Object,'
        'X_extends_dynamic extends dynamic,'
        'Y extends X,'
        'Y_extends_dynamic extends X_extends_dynamic');
  data.forEach((String input, String output) {
    DartType inputType = env.parseType(input);
    DartType expectedOutputType = env.parseType(output);
    DartType actualOutputType = computeNonNull(inputType);
    print('legacyErasure($inputType) = $actualOutputType: $expectedOutputType');
    Expect.equals(
        expectedOutputType,
        actualOutputType,
        "Unexpected NonNull of $inputType ('$input'):\n"
        "Expected: ${expectedOutputType} ('$output')\n"
        "Actual: ${actualOutputType}");
  });
}
