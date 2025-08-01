// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart" show Expect;

import 'package:kernel/ast.dart';
import 'package:kernel/src/norm.dart';
import 'package:kernel/testing/type_parser_environment.dart';

void run() {
  checkNormToSame('Null');
  checkNormToSame('Never');
  check('Never?', 'Null');
  checkNormToSame('void');
  checkNormToSame('dynamic');
  checkNormToSame('Object?');
  check('FutureOr<dynamic>', 'dynamic');
  check('FutureOr<void>', 'void');
  check('FutureOr<Object>', 'Object');
  check('FutureOr<Object?>', 'Object?');
  check('FutureOr<Never>', 'Future<Never>');
  check('FutureOr<Never?>', 'Future<Null>?');

  check('FutureOr<Null>', 'Future<Null>?');
  check('FutureOr<FutureOr<dynamic>>', 'dynamic');
  check('FutureOr<FutureOr<void>>', 'void');
  check('FutureOr<FutureOr<Object>>', 'Object');
  check('FutureOr<FutureOr<Object?>>', 'Object?');
  check('FutureOr<FutureOr<Never>>', 'FutureOr<Future<Never>>');

  // TODO(cstefantsova): Use the following test case instead when FutureOr can
  // distinguish between the declared nullability and the nullability as a
  // property.
  //
  //check('FutureOr<FutureOr<Never?>>', 'FutureOr<Future<Null>?>');
  check('FutureOr<FutureOr<Never?>>', 'FutureOr<Future<Null>?>?');

  // TODO(cstefantsova): Use the following test case instead when FutureOr can
  // distinguish between the declared nullability and the nullability as a
  // property.
  //
  //check('FutureOr<FutureOr<Null>>', 'FutureOr<Future<Null>?>');
  check('FutureOr<FutureOr<Null>>', 'FutureOr<Future<Null>?>?');

  checkNormToSame('bool');
  checkNormToSame('bool?');

  checkNormToSame('List<bool>');
  checkNormToSame('List<bool?>');
  checkNormToSame('List<bool>?');
  checkNormToSame('List<bool?>?');
  check('List<FutureOr<Object?>>', 'List<Object?>');
  check('List<T>', 'List<Never>', 'T extends Never');
  check('List<T?>', 'List<Null>', 'T extends Never');

  checkNormToSame('() ->? bool?');
  checkNormToSame('() -> bool?');
  checkNormToSame('() ->? bool');
  checkNormToSame('() -> bool');
  check('() ->? List<FutureOr<Object?>>', '() ->? List<Object?>');
  check('() ->? List<T>', '() ->? List<Never>', 'T extends Never');
  check('() ->? List<T?>', '() ->? List<Null>',
      'T extends S, S extends U, U extends Never');

  checkNormToSame('(int?) -> void');
  checkNormToSame('(int) -> void');
  checkNormToSame('([int?]) -> void');
  checkNormToSame('([int]) -> void');
  checkNormToSame('({int? a}) -> void');
  checkNormToSame('({int a}) -> void');
  checkNormToSame('({required int? a}) -> void');
  checkNormToSame('({required int a}) -> void');
  check('(List<FutureOr<Object?>>) -> void', '(List<Object?>) -> void');
  check('([List<FutureOr<Object?>>]) -> void', '([List<Object?>]) -> void');
  check('({List<FutureOr<Object?>> x}) -> void', '({List<Object?> x}) -> void');
  check('({required List<FutureOr<Object?>> x}) -> void',
      '({required List<Object?> x}) -> void');

  checkNormToSame('<T>(T) -> void');
  checkNormToSame('<T>(T?) -> void');
  checkNormToSame('<T extends bool>(T) -> void');
  checkNormToSame('<T extends List<T>>(T) -> void');
  check('<T extends List<FutureOr<Object?>>>(T) -> void',
      '<T extends List<Object?>>(T) -> void');

  checkNormToSame('T', 'T extends Object?');
  checkNormToSame('T?', 'T extends Object?');
  checkNormToSame('T', 'T extends FutureOr<Never>');
  check('T', 'Never', 'T extends Never');
  check('T & Never', 'Never', 'T extends Object?');
  check('T', 'Never', 'T extends S, S extends Never');
  check('List<T?>', 'List<Null>', 'T extends S, S extends Never');
  check('FutureOr<T?>', 'Future<Null>?', 'T extends S, S extends Never');

  check('FutureOr<FutureOr<dynamic>>', 'dynamic');
  check('FutureOr<FutureOr<void>>', 'void');
  check('FutureOr<FutureOr<Object?>>', 'Object?');
  check('FutureOr<FutureOr<dynamic>?>?', 'dynamic');
  check('FutureOr<FutureOr<void>?>?', 'void');
  check('FutureOr<FutureOr<Object?>?>?', 'Object?');

  // TODO(cstefantsova): The following test cases should be removed when
  // FutureOr can distinguish between the declared nullability and the
  // nullability as a property.
  check('FutureOr<int?>', 'FutureOr<int?>?');
  check('FutureOr<FutureOr<int?>>', 'FutureOr<FutureOr<int?>?>?');
  check('FutureOr<FutureOr<int>?>', 'FutureOr<FutureOr<int>?>?');
  check('FutureOr<FutureOr<FutureOr<int>>?>',
      'FutureOr<FutureOr<FutureOr<int>>?>?');

  check('(T, S & Never, {R foo})', '(Never, Never, {Never foo})',
      'T extends Never, S extends Object?, R extends T');
  check('(T, bool?, {FutureOr<Null> foo, FutureOr<dynamic> bar})',
      '(Never, bool?, {Future<Null>? foo, dynamic bar})', 'T extends Never');
  check('() -> List<({FutureOr<dynamic> foo})>', '() -> List<({dynamic foo})>');
  check('<T extends Never>((T, T)) -> void',
      '<T extends Never>((Never, Never)) -> void');

  checkNormToSame('(int, {String? foo})');
  checkNormToSame('(int, String?, {List<int> foo, T bar})', 'T extends num');
  checkNormToSame('()');
  checkNormToSame('(int?)');
  checkNormToSame('List<(int, {String foo})>');
}

void check(String input, String output, [String typeParameters = '']) {
  Env env = new Env('')..extendWithTypeParameters(typeParameters);
  DartType inputType = env.parseType(input);
  DartType expectedOutputType = env.parseType(output);
  DartType actualOutputType = norm(env.coreTypes, inputType);
  print('norm($inputType) = $actualOutputType, expected $expectedOutputType');
  Expect.equals(
      expectedOutputType,
      actualOutputType,
      "Unexpected norm of $inputType ('$input'):\n"
      "Expected: ${expectedOutputType} ('$output')\n"
      "Actual: ${actualOutputType}");
}

void checkNormToSame(String type, [String typeParameters = '']) {
  return check(type, type, typeParameters);
}

void main() => run();
