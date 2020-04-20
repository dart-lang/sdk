// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.bytecode.nullability_detector;

import 'package:kernel/ast.dart';
import 'dbc.dart';
import 'recognized_methods.dart' show RecognizedMethods;

class NullabilityDetector {
  final _IsNullableVisitor _isNullableVisitor;

  NullabilityDetector(RecognizedMethods recognizedMethods)
      : _isNullableVisitor = new _IsNullableVisitor(recognizedMethods);

  bool isNullable(Expression expr) => expr.accept(_isNullableVisitor);
}

class _IsNullableVisitor extends ExpressionVisitor<bool> {
  final RecognizedMethods recognizedMethods;

  _IsNullableVisitor(this.recognizedMethods);

  @override
  bool defaultExpression(Expression node) => true;

  @override
  bool visitNullLiteral(NullLiteral node) => true;

  // All basic literals except NullLiteral are non-nullable.
  @override
  bool defaultBasicLiteral(BasicLiteral node) => false;

  @override
  bool visitVariableGet(VariableGet node) {
    final v = node.variable;
    if ((v.isConst || v.isFinal) && v.initializer != null) {
      return v.initializer.accept(this);
    }
    return true;
  }

  @override
  bool visitVariableSet(VariableSet node) => node.value.accept(this);

  @override
  bool visitMethodInvocation(MethodInvocation node) {
    final Opcode opcode = recognizedMethods.specializedBytecodeFor(node);
    if (opcode != null) {
      return !_nonNullableBytecodeInstructions.contains(opcode);
    }
    return true;
  }

  @override
  bool visitConstructorInvocation(ConstructorInvocation node) => false;

  @override
  bool visitNot(Not node) => false;

  @override
  bool visitLogicalExpression(LogicalExpression node) => false;

  @override
  bool visitConditionalExpression(ConditionalExpression node) =>
      node.then.accept(this) || node.otherwise.accept(this);

  @override
  bool visitStringConcatenation(StringConcatenation node) => false;

  @override
  bool visitIsExpression(IsExpression node) => false;

  @override
  bool visitAsExpression(AsExpression node) => node.operand.accept(this);

  @override
  bool visitSymbolLiteral(SymbolLiteral node) => false;

  @override
  bool visitTypeLiteral(TypeLiteral node) => false;

  @override
  bool visitThisExpression(ThisExpression node) => false;

  @override
  bool visitRethrow(Rethrow node) => false;

  @override
  bool visitThrow(Throw node) => false;

  @override
  bool visitListLiteral(ListLiteral node) => false;

  @override
  bool visitMapLiteral(MapLiteral node) => false;

  @override
  bool visitFunctionExpression(FunctionExpression node) => false;

  @override
  bool visitConstantExpression(ConstantExpression node) =>
      node.constant is NullConstant;

  @override
  bool visitLet(Let node) => node.body.accept(this);

  @override
  bool visitInstantiation(Instantiation node) => false;
}

final _nonNullableBytecodeInstructions = new Set<Opcode>.from([
  Opcode.kBooleanNegateTOS,
  Opcode.kEqualsNull,
  Opcode.kNegateInt,
  Opcode.kAddInt,
  Opcode.kSubInt,
  Opcode.kMulInt,
  Opcode.kTruncDivInt,
  Opcode.kModInt,
  Opcode.kBitAndInt,
  Opcode.kBitOrInt,
  Opcode.kBitXorInt,
  Opcode.kShlInt,
  Opcode.kShrInt,
  Opcode.kCompareIntEq,
  Opcode.kCompareIntGt,
  Opcode.kCompareIntLt,
  Opcode.kCompareIntGe,
  Opcode.kCompareIntLe,
  Opcode.kNegateDouble,
  Opcode.kAddDouble,
  Opcode.kSubDouble,
  Opcode.kMulDouble,
  Opcode.kDivDouble,
  Opcode.kCompareDoubleEq,
  Opcode.kCompareDoubleGt,
  Opcode.kCompareDoubleLt,
  Opcode.kCompareDoubleGe,
  Opcode.kCompareDoubleLe,
]);
