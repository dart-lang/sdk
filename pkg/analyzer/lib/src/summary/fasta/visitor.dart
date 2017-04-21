// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Visitor of the simplified expression syntax tree.
library summary.src.visitor;

import 'expressions.dart';

/// Post-order recursive visitor.
///
/// Will invoke `handle*` methods in post order (children first, parents
/// afterwards).
class RecursiveVisitor extends Visitor {
  visitAs(As n) {
    n.exp.accept(this);
    handleAs(n);
  }

  visitBinary(Binary n) {
    n.left.accept(this);
    n.right.accept(this);
    handleBinary(n);
  }

  visitConditional(Conditional n) {
    n.test.accept(this);
    n.trueBranch.accept(this);
    n.falseBranch.accept(this);
    handleConditional(n);
  }

  visitConstCreation(ConstCreation n) {
    for (var arg in n.positionalArgs) {
      arg.accept(this);
    }
    for (var arg in n.namedArgs) {
      arg.value.accept(this);
    }
    handleConstCreation(n);
  }

  visitIdentical(Identical n) {
    n.left.accept(this);
    n.right.accept(this);
    handleIdentical(n);
  }

  visitIs(Is n) {
    n.exp.accept(this);
    handleIs(n);
  }

  visitList(ListLiteral n) {
    for (var v in n.values) {
      v.accept(this);
    }
    handleList(n);
  }

  visitLoad(Load n) {
    n.left.accept(this);
    handleLoad(n);
  }

  visitMap(MapLiteral n) {
    for (var v in n.values) {
      v.key.accept(this);
      v.value.accept(this);
    }
    handleMap(n);
  }

  visitOpaqueOp(OpaqueOp n) {
    n.exp.accept(this);
    handleOpaqueOp(n);
  }

  visitUnary(Unary n) {
    n.exp.accept(this);
    handleUnary(n);
  }
}

/// Plain non-recursive visitor.
class Visitor {
  // References

  handleAs(As n) {}
  handleBinary(Binary n) {}

  // Literals

  handleBool(BoolLiteral n) {}
  handleConditional(Conditional n) {}
  handleConstCreation(ConstCreation n) {}
  handleDouble(DoubleLiteral n) {}
  handleIdentical(Identical n) {}
  handleInt(IntLiteral n) {}
  handleInvalid(Invalid n) {}
  handleIs(Is n) {}

  handleList(ListLiteral n) {}
  handleLoad(Load n) {}
  handleMap(MapLiteral n) {}
  handleNull(NullLiteral n) {}
  handleOpaque(Opaque n) {}
  handleOpaqueOp(OpaqueOp n) {}
  handleRef(Ref n) {}
  handleString(StringLiteral n) {}

  // Compound expressions

  handleSymbol(SymbolLiteral n) {}
  handleUnary(Unary n) {}
  visitAs(As n) => handleAs(n);
  visitBinary(Binary n) => handleBinary(n);
  visitBool(BoolLiteral n) => handleBool(n);
  visitConditional(Conditional n) => handleConditional(n);
  visitConstCreation(ConstCreation n) => handleConstCreation(n);
  visitDouble(DoubleLiteral n) => handleDouble(n);

  visitIdentical(Identical n) => handleIdentical(n);
  visitInt(IntLiteral n) => handleInt(n);
  visitInvalid(Invalid n) => handleInvalid(n);
  visitIs(Is n) => handleIs(n);
  visitList(ListLiteral n) => handleList(n);
  visitLoad(Load n) => handleLoad(n);
  visitMap(MapLiteral n) => handleMap(n);
  visitNull(NullLiteral n) => handleNull(n);

  // Non-traditional expressions.

  visitOpaque(Opaque n) => handleOpaque(n);
  visitOpaqueOp(OpaqueOp n) => handleOpaqueOp(n);
  visitRef(Ref n) => handleRef(n);

  visitString(StringLiteral n) => handleString(n);
  visitSymbol(SymbolLiteral n) => handleSymbol(n);
  visitUnary(Unary n) => handleUnary(n);
}
