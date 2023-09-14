// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helper for debug Kernel nodes.

library kernel.debug;

import 'package:kernel/ast.dart';

import 'indentation.dart' show Indentation, Tagging;

class DebugPrinter extends VisitorDefault<void>
    with Indentation, Tagging<Node>, VisitorVoidMixin {
  @override
  StringBuffer sb = new StringBuffer();

  void visitNodeWithChildren(Node node, String type, [Map? params]) {
    openNode(node, type, params);
    node.visitChildren(this);
    closeNode();
  }

  @override
  void defaultNode(Node node) {
    visitNodeWithChildren(node, '${node.runtimeType}');
  }

  @override
  void visitName(Name node) {
    openAndCloseNode(node, '${node.runtimeType}',
        {'name': node.text, 'library': node.library?.name});
  }

  @override
  void visitIntLiteral(IntLiteral node) {
    openAndCloseNode(node, '${node.runtimeType}', {'value': '${node.value}'});
  }

  @override
  void visitVariableGet(VariableGet node) {
    openAndCloseNode(
        node, '${node.runtimeType}', {'variable': '${node.variable}'});
  }

  @override
  void visitStaticGet(StaticGet node) {
    openAndCloseNode(node, '${node.runtimeType}', {'target': '${node.target}'});
  }

  @override
  void visitStaticInvocation(StaticInvocation node) {
    openNode(node, '${node.runtimeType}', {'target': '${node.target}'});
    node.visitChildren(this);
    closeNode();
  }

  @override
  void visitArguments(Arguments node) {
    openNode(node, '${node.runtimeType}', {
      'typeArgs': '${node.types}',
      'positionalArgs': '${node.positional}',
      'namedArgs': '${node.named}'
    });
    node.visitChildren(this);
    closeNode();
  }

  @override
  void visitAsExpression(AsExpression node) {
    openNode(node, '${node.runtimeType}',
        {'operand': '${node.operand}', 'DartType': '${node.type}'});
    node.visitChildren(this);
    closeNode();
  }

  @override
  void visitStringLiteral(StringLiteral node) {
    openAndCloseNode(node, '${node.runtimeType}', {'value': '${node.value}'});
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    openNode(node, '${node.runtimeType}', {
      'name': '${node.name ?? '--unnamed--'}',
      'isFinal': '${node.isFinal}',
      'isConst': '${node.isConst}',
      'isInitializingFormal': '${node.isInitializingFormal}'
    });
    node.visitChildren(this);
    closeNode();
  }

  @override
  void visitInterfaceType(InterfaceType node) {
    openNode(node, '${node.runtimeType}', {
      'name': '${node.classNode.name}',
    });
    node.visitChildren(this);
    closeNode();
  }

  /// Pretty-prints given node tree into string.
  static String prettyPrint(Node node) {
    DebugPrinter p = new DebugPrinter();
    node.accept(p);
    return p.sb.toString();
  }
}
