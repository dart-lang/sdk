// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

ReturnStatement createRedirectingFactoryBody(
    Member target, List<DartType> typeArguments, FunctionNode function) {
  return new ReturnStatement(
      _makeForwardingCall(target, typeArguments, function));
}

ReturnStatement createRedirectingFactoryErrorBody(String errorMessage) {
  return new ReturnStatement(new InvalidExpression(errorMessage));
}

Expression _makeForwardingCall(
    Member target, List<DartType> typeArguments, FunctionNode function) {
  final List<Expression> positional = function.positionalParameters
      .map<Expression>((v) => new VariableGet(v)..fileOffset = v.fileOffset)
      .toList();
  final List<NamedExpression> named = function.namedParameters
      .map((v) => new NamedExpression(
          v.name!, new VariableGet(v)..fileOffset = v.fileOffset)
        ..fileOffset = v.fileOffset)
      .toList();
  final Arguments args =
      new Arguments(positional, named: named, types: typeArguments);
  if (target is Procedure) {
    return new StaticInvocation(target, args)..fileOffset = function.fileOffset;
  } else if (target is Constructor) {
    return new ConstructorInvocation(target, args)
      ..fileOffset = function.fileOffset;
  } else {
    throw 'Unexpected target for redirecting factory:'
        ' ${target.runtimeType} $target';
  }
}
