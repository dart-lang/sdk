// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

ReturnStatement createRedirectingFactoryBody(
  Member target,
  DartTypeList typeArguments,
  FunctionNode function,
) {
  return new ReturnStatement(
    _makeForwardingCall(target, typeArguments, function),
  );
}

ReturnStatement createRedirectingFactoryErrorBody(String errorMessage) {
  return new ReturnStatement(new InvalidExpression(errorMessage));
}

Expression _makeForwardingCall(
  Member target,
  DartTypeList typeArguments,
  FunctionNode function,
) {
  final ExpressionList positional = new ExpressionList.generate(
    function.positionalParameters.length,
    (int i) {
      PositionalParameter v = function.positionalParameters[i];
      return new VariableGet(v)..fileOffset = v.fileOffset;
    },
  );
  final NamedExpressionList named = new NamedExpressionList.generate(
    function.namedParameters.length,
    (int i) {
      NamedParameter v = function.namedParameters[i];
      return new NamedExpression(
        v.parameterName,
        new VariableGet(v)..fileOffset = v.fileOffset,
      )..fileOffset = v.fileOffset;
    },
  );
  final Arguments args = new Arguments(
    positional,
    named: named,
    types: typeArguments,
  );
  if (target is Procedure) {
    return new StaticInvocation(target, args)..fileOffset = function.fileOffset;
  } else if (target is Constructor) {
    return new ConstructorInvocation(target, args)
      ..fileOffset = function.fileOffset;
  } else {
    // Coverage-ignore-block(suite): Not run.
    throw 'Unexpected target for redirecting factory:'
        ' ${target.runtimeType} $target';
  }
}
