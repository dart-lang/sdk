// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IrNodes are kept in a separate library to have precise control over their
// dependencies on other parts of the system.
library dart2js.ir_nodes;

import '../dart2jslib.dart' show Constant;
import '../elements/elements.dart' show FunctionElement, LibraryElement;
import 'ir_pickler.dart' show Pickler, IrConstantPool;
import '../universe/universe.dart' show Selector, SelectorKind;
import '../util/util.dart' show Spannable;

/**
 * A pair of source offset and an identifier name. Identifier names are used in
 * the Javascript backend to generate source maps.
 */
class PositionWithIdentifierName {
  final int offset;
  final String sourceName;
  PositionWithIdentifierName(this.offset, this.sourceName);
}

abstract class IrNode implements Spannable {
  static int hashCount = 0;
  final int hashCode = hashCount = (hashCount + 1) & 0x3fffffff;

  final /* int | PositionWithIdentifierName */ position;

  const IrNode(this.position);

  int get offset => (position is int) ? position : position.offset;

  String get sourceName => (position is int) ? null : position.sourceName;

  List<int> pickle(IrConstantPool constantPool) {
    return new Pickler(constantPool).pickle(this);
  }

  accept(IrNodesVisitor visitor);
}

abstract class IrExpression extends IrNode {
  IrExpression(position) : super(position);
}

class IrFunction extends IrExpression {
  final List<IrNode> statements;

  final int endOffset;
  final int namePosition;

  IrFunction(position, this.endOffset, this.namePosition, this.statements)
    : super(position);

  accept(IrNodesVisitor visitor) => visitor.visitIrFunction(this);
}

class IrReturn extends IrNode {
  final IrExpression value;

  IrReturn(position, this.value) : super(position);

  accept(IrNodesVisitor visitor) => visitor.visitIrReturn(this);
}

class IrConstant extends IrExpression {
  final Constant value;

  IrConstant(position, this.value) : super(position);

  accept(IrNodesVisitor visitor) => visitor.visitIrConstant(this);
}

class IrInvokeStatic extends IrExpression {
  final FunctionElement target;

  final List<IrExpression> arguments;

  /**
   * The selector encodes how the function is invoked: number of positional
   * arguments, names used in named arguments. This information is required
   * to build the [StaticCallSiteTypeInformation] for the inference graph.
   */
  final Selector selector;

  IrInvokeStatic(position, this.target, this.selector, this.arguments)
    : super(position) {
    assert(selector.kind == SelectorKind.CALL);
    assert(selector.name == target.name);
  }

  accept(IrNodesVisitor visitor) => visitor.visitIrInvokeStatic(this);
}

/**
 * This class is only used during SSA generation, its instances never appear in
 * the representation of a function. See [SsaFromAstInliner.enterInlinedMethod].
 */
class IrInlinedInvocationDummy extends IrExpression {
  IrInlinedInvocationDummy() : super(0);
  accept(IrNodesVisitor visitor) => throw "IrInlinedInvocationDummy.accept";
}


abstract class IrNodesVisitor<T> {
  T visit(IrNode node) => node.accept(this);

  void visitAll(List<IrNode> nodes) {
    for (IrNode n in nodes) visit(n);
  }

  T visitIrNode(IrNode node);

  T visitIrExpression(IrExpression node) => visitIrNode(node);
  T visitIrFunction(IrFunction node) => visitIrExpression(node);
  T visitIrReturn(IrReturn node) => visitIrNode(node);
  T visitIrConstant(IrConstant node) => visitIrExpression(node);
  T visitIrInvokeStatic(IrInvokeStatic node) => visitIrExpression(node);
}
