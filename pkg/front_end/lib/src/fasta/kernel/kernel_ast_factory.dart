// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' show DartType;

import '../builder/ast_factory.dart' as builder;
import '../builder/shadow_ast.dart' as builder;
import 'kernel_shadow_ast.dart';

/// Concrete implementation of [builder.AstFactory] for building a kernel AST.
class KernelAstFactory implements builder.AstFactory {
  @override
  KernelBlock block(List<builder.ShadowStatement> statements, int charOffset) {
    return new KernelBlock(statements)..fileOffset = charOffset;
  }

  @override
  KernelIntLiteral intLiteral(value, int charOffset) {
    return new KernelIntLiteral(value)..fileOffset = charOffset;
  }

  @override
  KernelListLiteral listLiteral(List<builder.ShadowExpression> expressions,
      DartType typeArgument, bool isConst, int charOffset) {
    return new KernelListLiteral(expressions,
        typeArgument: typeArgument, isConst: isConst)..fileOffset = charOffset;
  }

  @override
  KernelNullLiteral nullLiteral(int charOffset) {
    return new KernelNullLiteral()..fileOffset = charOffset;
  }

  @override
  KernelReturnStatement returnStatement(
      builder.ShadowExpression expression, int charOffset) {
    return new KernelReturnStatement(expression)..fileOffset = charOffset;
  }

  @override
  KernelVariableDeclaration variableDeclaration(String name,
      {DartType type,
      builder.ShadowExpression initializer,
      int charOffset,
      bool isFinal: false,
      bool isConst: false}) {
    return new KernelVariableDeclaration(name,
        type: type,
        initializer: initializer,
        isFinal: isFinal,
        isConst: isConst)..fileEqualsOffset = charOffset;
  }
}
