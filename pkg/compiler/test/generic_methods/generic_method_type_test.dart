// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/elements/types.dart';
import 'package:compiler/src/universe/call_structure.dart';
import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';
import '../helpers/type_test_helper.dart';

List<FunctionTypeData> signatures = const <FunctionTypeData>[
  const FunctionTypeData("void", "0", "()"),
  const FunctionTypeData("void", "1", "<T>(T t)"),
  const FunctionTypeData("void", "2", "<T, S>(T t, S s)"),
  const FunctionTypeData("void", "3", "<T, S>(T t, [S s])"),
  const FunctionTypeData("void", "4", "<T, S>(T t, {S s})"),
  const FunctionTypeData("void", "5", "<T extends num>(T t)"),
  const FunctionTypeData("void", "6", "<T extends int>(T t)"),
];

main() {
  asyncTest(() async {
    TypeEnvironment env = await TypeEnvironment.create("""
      ${createTypedefs(signatures, prefix: 't')}
      ${createMethods(signatures, prefix: 'm')}

    main() {
      ${createUses(signatures, prefix: 't')}
      ${createUses(signatures, prefix: 'm')}
    }
    """);

    for (FunctionTypeData data in signatures) {
      DartType functionType = env.getElementType('t${data.name}');
      Expect.isTrue(
          functionType is! LegacyType || env.options.useLegacySubtyping);
      functionType = functionType.withoutNullability;
      final method = env.getElement('m${data.name}') as FunctionEntity;
      final methodType = env.getElementType('m${data.name}') as FunctionType;
      ParameterStructure parameterStructure = method.parameterStructure;
      Expect.equals(functionType, methodType, "Type mismatch on $data");
      Expect.equals(
          parameterStructure.typeParameters,
          methodType.typeVariables.length,
          "Type parameter mismatch on $data with $parameterStructure.");
      CallStructure callStructure = parameterStructure.callStructure;
      Expect.isTrue(callStructure.signatureApplies(parameterStructure));
      CallStructure noTypeArguments = CallStructure(
          callStructure.argumentCount, callStructure.namedArguments, 0);
      Expect.isTrue(noTypeArguments.signatureApplies(parameterStructure));
      CallStructure tooManyTypeArguments = CallStructure(
          callStructure.argumentCount,
          callStructure.namedArguments,
          callStructure.typeArgumentCount + 1);
      Expect.isFalse(tooManyTypeArguments.signatureApplies(parameterStructure));
    }
  });
}
