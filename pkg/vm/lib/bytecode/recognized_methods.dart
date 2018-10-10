// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.bytecode.recognized_methods;

import 'package:kernel/ast.dart';
import 'package:kernel/type_environment.dart' show TypeEnvironment;

import 'dbc.dart';

class RecognizedMethods {
  static const binaryIntOps = <String, Opcode>{
    '+': Opcode.kAddInt,
    '-': Opcode.kSubInt,
    '*': Opcode.kMulInt,
    '~/': Opcode.kTruncDivInt,
    '%': Opcode.kModInt,
    '&': Opcode.kBitAndInt,
    '|': Opcode.kBitOrInt,
    '^': Opcode.kBitXorInt,
    '<<': Opcode.kShlInt,
    '>>': Opcode.kShrInt,
    '==': Opcode.kCompareIntEq,
    '>': Opcode.kCompareIntGt,
    '<': Opcode.kCompareIntLt,
    '>=': Opcode.kCompareIntGe,
    '<=': Opcode.kCompareIntLe,
  };

  final TypeEnvironment typeEnv;

  RecognizedMethods(this.typeEnv);

  DartType staticType(Expression expr) {
    // TODO(dartbug.com/34496): Remove this ugly try/catch once
    // getStaticType() is reliable.
    try {
      return expr.getStaticType(typeEnv);
    } catch (e) {
      return const DynamicType();
    }
  }

  bool isInt(Expression expr) => staticType(expr) == typeEnv.intType;

  Opcode specializedBytecodeFor(MethodInvocation node) {
    final args = node.arguments;
    if (!args.named.isEmpty) {
      return null;
    }

    final Expression receiver = node.receiver;
    final String selector = node.name.name;

    switch (args.positional.length) {
      case 0:
        return specializedBytecodeForUnaryOp(selector, receiver);
      case 1:
        return specializedBytecodeForBinaryOp(
            selector, receiver, args.positional.single);
      default:
        return null;
    }
  }

  Opcode specializedBytecodeForUnaryOp(String selector, Expression arg) {
    if (selector == 'unary-' && isInt(arg)) {
      return Opcode.kNegateInt;
    }

    return null;
  }

  Opcode specializedBytecodeForBinaryOp(
      String selector, Expression a, Expression b) {
    if (selector == '==' && (a is NullLiteral || b is NullLiteral)) {
      return Opcode.kEqualsNull;
    }

    if (isInt(a) && isInt(b)) {
      return binaryIntOps[selector];
    }

    return null;
  }
}
