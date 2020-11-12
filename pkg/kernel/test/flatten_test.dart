// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart" show Expect;

import 'package:kernel/ast.dart' hide MapEntry;
import 'package:kernel/class_hierarchy.dart';
import 'package:kernel/testing/type_parser_environment.dart';
import 'package:kernel/type_environment.dart';

const Set<Test> data = {
  const Test('Null', 'Null'),
  const Test('Never?', 'Never?'),
  const Test('void', 'void'),
  const Test('dynamic', 'dynamic'),
  const Test('bool', 'bool'),
  const Test('bool?', 'bool?'),
  const Test('bool*', 'bool*'),
  const Test('List<bool>', 'List<bool>'),
  const Test('List<bool>?', 'List<bool>?'),
  const Test('List<bool>*', 'List<bool>*'),
  const Test('FutureOr<bool>', 'bool'),
  const Test('FutureOr<bool>?', 'bool?'),
  const Test('FutureOr<bool>*', 'bool*'),
  const Test('FutureOr<bool?>*', 'bool?'),
  const Test('FutureOr<bool?>?', 'bool?'),
  const Test('FutureOr<bool*>?', 'bool?'),
  const Test('FutureOr<Null>', 'Null'),
  const Test('FutureOr<Null>?', 'Null'),
  const Test('FutureOr<Null>*', 'Null'),
  const Test('Future<bool>', 'bool'),
  const Test('Future<bool>?', 'bool?'),
  const Test('Future<bool>*', 'bool*'),
  const Test('Future<bool?>', 'bool?'),
  const Test('Future<bool*>', 'bool*'),
  const Test('() ->* bool*', '() ->* bool*'),
  const Test('() -> bool*', '() -> bool*'),
  const Test('() ->? bool*', '() ->? bool*'),
  const Test('() ->* bool', '() ->* bool'),
  const Test('() ->? bool', '() ->? bool'),
  const Test('() -> bool', '() -> bool'),
  const Test('T', 'T', 'T'),
  const Test('T?', 'T?', 'T'),
  const Test('T*', 'T*', 'T'),
  const Test('T', 'T', 'T extends bool'),
  const Test('T?', 'T?', 'T extends bool'),
  const Test('T*', 'T*', 'T extends bool'),
  const Test('T', 'T', 'T extends FutureOr<bool>'),
  const Test('T?', 'T?', 'T extends FutureOr<bool>'),
  const Test('T*', 'T*', 'T extends FutureOr<bool>'),
  const Test('T', 'bool', 'T extends Future<bool>'),
  const Test('T?', 'bool?', 'T extends Future<bool>'),
  const Test('T*', 'bool*', 'T extends Future<bool>'),
  const Test('T & bool', 'T & bool', 'T'),
  const Test('T & bool?', 'T & bool?', 'T'),
  const Test('T & bool*', 'T & bool*', 'T'),
};

class Test {
  final String input;
  final String output;
  final String typeParameters;

  const Test(this.input, this.output, [this.typeParameters]);
}

main() {
  Env env = new Env('', isNonNullableByDefault: true);
  ClassHierarchy classHierarchy =
      new ClassHierarchy(env.component, env.coreTypes);
  TypeEnvironment typeEnvironment =
      new TypeEnvironment(env.coreTypes, classHierarchy);
  data.forEach((Test test) {
    env.withTypeParameters(test.typeParameters,
        (List<TypeParameter> typeParameterNodes) {
      String input = test.input;
      String output = test.output;
      DartType inputType = env.parseType(input);
      DartType expectedOutputType = env.parseType(output);
      DartType actualOutputType = typeEnvironment.flatten(inputType);
      print('flatten($inputType) '
          '${test.typeParameters != null ? 'with ${test.typeParameters} ' : ''}'
          '= $actualOutputType, expected $expectedOutputType');
      Expect.equals(
          expectedOutputType,
          actualOutputType,
          "Unexpected flatten of $inputType ('$input'):\n"
          "Expected: ${expectedOutputType} ('$output')\n"
          "Actual: ${actualOutputType}");
    });
  });
}
