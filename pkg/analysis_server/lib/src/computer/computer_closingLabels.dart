// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * A computer for [CompilationUnit] closing labels.
 */
class DartUnitClosingLabelsComputer {
  final LineInfo _lineInfo;
  final CompilationUnit _unit;
  final List<ClosingLabel> _closingLabels = <ClosingLabel>[];

  DartUnitClosingLabelsComputer(this._lineInfo, this._unit);

  /**
   * Returns a list of closing labels, not `null`.
   */
  List<ClosingLabel> compute() {
    _unit.accept(new _DartUnitClosingLabelsComputerVisitor(this));
    return _closingLabels;
  }
}

/**
 * An AST visitor for [DartUnitClosingLabelsComputer].
 */
class _DartUnitClosingLabelsComputerVisitor
    extends RecursiveAstVisitor<Object> {
  final DartUnitClosingLabelsComputer computer;

  _DartUnitClosingLabelsComputerVisitor(this.computer);

  @override
  Object visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (_spansManyLines(node)) {
      // TODO(dantup) confirm whether calling toString on constructorName is a reasonable
      // thing to do here.
      _addLabel(node, node.constructorName.toString());
    }

    return super.visitInstanceCreationExpression(node);
  }

  @override
  Object visitMethodInvocation(MethodInvocation node) {
    if (node.argumentList != null && _spansManyLines(node)) {
      _addLabel(node, node.methodName.name);
    }

    return super.visitMethodInvocation(node);
  }

  @override
  visitListLiteral(ListLiteral node) {
    if (_spansManyLines(node)) {
      final args = node.typeArguments?.arguments;
      final typeName = args != null ? args[0]?.toString() : null;

      if (typeName != null) {
        _addLabel(node, "List<$typeName>");
      }
    }

    return super.visitListLiteral(node);
  }

  bool _spansManyLines(AstNode node) {
    final start = computer._lineInfo.getLocation(node.offset);
    final end = computer._lineInfo.getLocation(node.end - 1);

    return end.lineNumber - start.lineNumber > 1;
  }

  void _addLabel(AstNode node, String label) {
    computer._closingLabels
        .add(new ClosingLabel(node.offset, node.length, label));
  }
}
