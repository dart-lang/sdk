// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IrNodes are kept in a separate library to have precise control over their
// dependencies on other parts of the system.
library dart2js.ir_nodes;

import '../dart2jslib.dart' as dart2js show Constant;
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

abstract class Node implements Spannable {
  static int hashCount = 0;
  final int hashCode = hashCount = (hashCount + 1) & 0x3fffffff;

  final /* int | PositionWithIdentifierName */ position;

  const Node(this.position);

  int get offset => (position is int) ? position : position.offset;

  String get sourceName => (position is int) ? null : position.sourceName;

  List<int> pickle(IrConstantPool constantPool) {
    return new Pickler(constantPool).pickle(this);
  }

  accept(NodesVisitor visitor);
}

abstract class Expression extends Node {
  Expression(position) : super(position);
}

class Function extends Expression {
  final List<Node> statements;

  final int endOffset;
  final int namePosition;

  Function(position, this.endOffset, this.namePosition, this.statements)
    : super(position);

  accept(NodesVisitor visitor) => visitor.visitFunction(this);
}

class Return extends Node {
  final Expression value;

  Return(position, this.value) : super(position);

  accept(NodesVisitor visitor) => visitor.visitReturn(this);
}

class Constant extends Expression {
  final dart2js.Constant value;

  Constant(position, this.value) : super(position);

  accept(NodesVisitor visitor) => visitor.visitConstant(this);
}

class InvokeStatic extends Expression {
  final FunctionElement target;

  final List<Expression> arguments;

  /**
   * The selector encodes how the function is invoked: number of positional
   * arguments, names used in named arguments. This information is required
   * to build the [StaticCallSiteTypeInformation] for the inference graph.
   */
  final Selector selector;

  InvokeStatic(position, this.target, this.selector, this.arguments)
    : super(position) {
    assert(selector.kind == SelectorKind.CALL);
    assert(selector.name == target.name);
  }

  accept(NodesVisitor visitor) => visitor.visitInvokeStatic(this);
}

/**
 * This class is only used during SSA generation, its instances never appear in
 * the representation of a function.
 */
class InlinedInvocationDummy extends Expression {
  InlinedInvocationDummy() : super(0);
  accept(NodesVisitor visitor) => throw "IrInlinedInvocationDummy.accept";
}


abstract class NodesVisitor<T> {
  T visit(Node node) => node.accept(this);

  void visitAll(List<Node> nodes) {
    for (Node n in nodes) visit(n);
  }

  T visitNode(Node node);

  T visitExpression(Expression node) => visitNode(node);
  T visitFunction(Function node) => visitExpression(node);
  T visitReturn(Return node) => visitNode(node);
  T visitConstant(Constant node) => visitExpression(node);
  T visitInvokeStatic(InvokeStatic node) => visitExpression(node);
}
