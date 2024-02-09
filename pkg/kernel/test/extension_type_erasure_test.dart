// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart" show Expect;

import 'package:kernel/ast.dart';
import 'package:kernel/testing/type_parser_environment.dart';

const Map<String, String> data = {
  'int': 'int',
  'ET1': 'int',
  'ET1?': 'int?',
  'ET2': 'int',
  'ET2?': 'int?',
  'ET3<int>': 'List<int>',
  'ET3<int?>': 'List<int?>',
  'ET3<int>?': 'List<int>?',
  'ET3<int?>?': 'List<int?>?',
  'ET3<ET1>': 'List<int>',
  'ET3<ET1>?': 'List<int>?',
  'ET3<ET1?>': 'List<int?>',
  'ET3<ET1?>?': 'List<int?>?',
  'ET4<int>': 'int',
  'ET4<int>?': 'int?',
  'ET4<int?>': 'int?',
  'ET4<int?>?': 'int?',
  'ET4<ET1>': 'int',
  'ET4<ET1>?': 'int?',
  'ET4<ET1?>': 'int?',
  'ET4<ET1?>?': 'int?',
  'ET4<ET2>': 'int',
  'ET4<ET2>?': 'int?',
  'ET4<ET2?>': 'int?',
  'ET4<ET2?>?': 'int?',
  'ET4<ET3<ET1>>': 'List<int>',
  'ET4<ET3<ET1>>?': 'List<int>?',
  'ET4<ET3<ET1>?>': 'List<int>?',
  'ET4<ET3<ET1?>>': 'List<int?>',
  'ET5': 'int?',
  'ET5?': 'int?',
  'ET6<int>': 'int?',
  'ET6<int>?': 'int?',
  'ET6<int?>?': 'int?',
  'List<ET1>': 'List<int>',
  'List<ET1?>': 'List<int?>',
  '(ET1, [ET2]) -> ET3<ET2>': '(int, [int]) -> List<int>',
  '(ET1, {ET2 a}) -> ET3<ET2>': '(int, {int a}) -> List<int>',
  '<T extends ET1>(T) -> void': '<T extends int>(T) -> void',
  '(ET1, {ET2 a, ET3<ET2> b})': '(int, {int a, List<int> b})',
};

void main() {
  Env env = new Env('''
extension type ET1(int it);
extension type ET2(ET1 it);
extension type ET3<T>(List<T> it);
extension type ET4<T>(T it);
extension type ET5(int? it);
extension type ET6<T>(T? it);
''', isNonNullableByDefault: true);
  data.forEach((String input, String output) {
    DartType inputType = env.parseType(input);
    DartType expectedOutputType = env.parseType(output);
    DartType actualOutputType = inputType.extensionTypeErasure;
    print('extensionTypeErasure($inputType) = '
        '$actualOutputType: $expectedOutputType');
    Expect.equals(
        expectedOutputType,
        actualOutputType,
        "Unexpected extension type erasure of $inputType ('$input'):\n"
        "Expected: ${expectedOutputType} ('$output')\n"
        "Actual: ${actualOutputType}");
  });
}
