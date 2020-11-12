// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart" show Expect;

import 'package:kernel/ast.dart' hide MapEntry;
import 'package:kernel/src/future_value_type.dart';
import 'package:kernel/testing/type_parser_environment.dart';

const Map<String, String> data = {
  'Null': 'Object?',
  'Never': 'Object?',
  'Never?': 'Object?',
  'void': 'void',
  'dynamic': 'dynamic',
  'bool': 'Object?',
  'bool?': 'Object?',
  'bool*': 'Object?',
  'List<bool>': 'Object?',
  '() -> void': 'Object?',
  '<T>(T) -> void': 'Object?',
  'X': 'Object?',
  'X_extends_FutureInt': 'Object?',
  'X_extends_FutureOrInt': 'Object?',
  'Future<dynamic>': 'dynamic',
  'Future<dynamic>?': 'dynamic',
  'Future<dynamic>*': 'dynamic',
  'Future<Object>': 'Object',
  'Future<Object>?': 'Object',
  'Future<Object>*': 'Object',
  'Future<int?>': 'int?',
  'Future<int?>?': 'int?',
  'Future<int?>*': 'int?',
  'Future<Future<int>?>': 'Future<int>?',
  'Future<Future<int>?>?': 'Future<int>?',
  'Future<Future<int>?>*': 'Future<int>?',
  'Future<FutureOr<int>?>': 'FutureOr<int>?',
  'Future<FutureOr<int>?>?': 'FutureOr<int>?',
  'Future<FutureOr<int>?>*': 'FutureOr<int>?',
  'Future<Null>': 'Null',
  'Future<Null>?': 'Null',
  'Future<Null>*': 'Null',
  'Future<void>': 'void',
  'Future<void>?': 'void',
  'Future<void>*': 'void',
  'FutureOr<dynamic>': 'dynamic',
  'FutureOr<dynamic>?': 'dynamic',
  'FutureOr<dynamic>*': 'dynamic',
  'FutureOr<Object>': 'Object',
  'FutureOr<Object>?': 'Object',
  'FutureOr<Object>*': 'Object',
  'FutureOr<int?>': 'int?',
  'FutureOr<int?>?': 'int?',
  'FutureOr<int?>*': 'int?',
  'FutureOr<Future<int>?>': 'Future<int>?',
  'FutureOr<Future<int>?>?': 'Future<int>?',
  'FutureOr<Future<int>?>*': 'Future<int>?',
  'FutureOr<FutureOr<int>?>': 'FutureOr<int>?',
  'FutureOr<FutureOr<int>?>?': 'FutureOr<int>?',
  'FutureOr<FutureOr<int>?>*': 'FutureOr<int>?',
  'FutureOr<Null>': 'Null',
  'FutureOr<Null>?': 'Null',
  'FutureOr<Null>*': 'Null',
  'FutureOr<void>': 'void',
  'FutureOr<void>?': 'void',
  'FutureOr<void>*': 'void',
};

main() {
  Env env = new Env('', isNonNullableByDefault: true)
    ..extendWithTypeParameters('X,'
        'X_extends_FutureInt extends Future<int>,'
        'X_extends_FutureOrInt extends FutureOr<int>');
  data.forEach((String input, String output) {
    DartType inputType = env.parseType(input);
    DartType expectedOutputType = env.parseType(output);
    DartType actualOutputType =
        computeFutureValueType(env.coreTypes, inputType);
    print(
        'futureValueType($inputType) = $actualOutputType: $expectedOutputType');
    Expect.equals(
        expectedOutputType,
        actualOutputType,
        "Unexpected future value type of $inputType ('$input'):\n"
        "Expected: ${expectedOutputType} ('$output')\n"
        "Actual: ${actualOutputType}");
  });
}
