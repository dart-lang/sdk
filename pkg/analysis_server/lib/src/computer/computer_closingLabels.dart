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
      final name = node.constructorName.type.name;
      final label = name is PrefixedIdentifier ? name.prefix.name : name.name;
      _addLabel(node, label);
    }

    return super.visitInstanceCreationExpression(node);
  }

  @override
  Object visitMethodInvocation(MethodInvocation node) {
    if (node.argumentList != null && _spansManyLines(node.argumentList)) {
      _addLabel(node, node.methodName.name);
    }

    return super.visitMethodInvocation(node);
  }

  @override
  visitListLiteral(ListLiteral node) {
    if (_spansManyLines(node)) {
      final typeName = node.typeArguments?.arguments[0]?.toString();

      if (typeName != null) {
        _addLabel(node, "List<$typeName>");
      }
    }

    return super.visitListLiteral(node);
  }

  bool _spansManyLines(AstNode node) {
    final start = computer._lineInfo.getLocation(node.offset);
    // TODO(dantup) Is this valid? We want the last character of the node, not the start of the next?
    final end = computer._lineInfo.getLocation(node.end - 1);

    return (start.lineNumber - end.lineNumber).abs() > 1;
  }

  void _addLabel(AstNode node, String label) {
    computer._closingLabels
        .add(new ClosingLabel(node.offset, node.length, label));
  }
}
