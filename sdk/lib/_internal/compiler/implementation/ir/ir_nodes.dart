// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// IrNodes are kept in a separate library to have precise control over their
// dependencies on other parts of the system.
library dart2js.ir_nodes;

import '../dart2jslib.dart' show Constant;
import 'ir_pickler.dart' show Pickler;

/**
 * A pair of source offset and an identifier name. Identifier names are used in
 * the Javascript backend to generate source maps.
 */
class PositionWithIdentifierName {
  final int offset;
  final String sourceName;
  PositionWithIdentifierName(this.offset, this.sourceName);
}

abstract class IrNode {
  final /* int | PositionWithIdentifierName */ position;

  const IrNode(this.position);

  int get offset => (position is int) ? position : position.offset;

  String get sourceName => (position is int) ? null : position.sourceName;

  List<int> pickle() => new Pickler().pickle(this);

  accept(IrNodesVisitor visitor);
}

class IrFunction extends IrNode {
  final List<IrNode> statements;

  final int endOffset;
  final int namePosition;

  IrFunction(position, this.endOffset, this.namePosition, this.statements)
    : super(position);

  accept(IrNodesVisitor visitor) => visitor.visitIrFunction(this);
}

class IrReturn extends IrNode {
  final IrNode value;

  IrReturn(position, this.value) : super(position);

  accept(IrNodesVisitor visitor) => visitor.visitIrReturn(this);
}

class IrConstant extends IrNode {
  final Constant value;

  IrConstant(position, this.value) : super(position);

  accept(IrNodesVisitor visitor) => visitor.visitIrConstant(this);
}


abstract class IrNodesVisitor<T> {
  T visit(IrNode node) => node.accept(this);

  void visitAll(List<IrNode> nodes) {
    for (IrNode n in nodes) visit(n);
  }

  T visitNode(IrNode node);

  T visitIrFunction(IrFunction node) => visitNode(node);
  T visitIrReturn(IrReturn node) => visitNode(node);
  T visitIrConstant(IrConstant node) => visitNode(node);
}
