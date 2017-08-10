// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/generated/source.dart';

class _ClosingLabelWithLineCount {
  ClosingLabel label;
  int spannedLines;
}

/**
 * A computer for [CompilationUnit] closing labels.
 */
class DartUnitClosingLabelsComputer {
  final LineInfo _lineInfo;
  final CompilationUnit _unit;
  final Map<int, List<_ClosingLabelWithLineCount>> _closingLabelsByEndLine = {};

  DartUnitClosingLabelsComputer(this._lineInfo, this._unit);

  /**
   * Returns a list of closing labels, not `null`.
   */
  List<ClosingLabel> compute() {
    _unit.accept(new _DartUnitClosingLabelsComputerVisitor(this));
    return _closingLabelsByEndLine.values
        .where((l) => l.any((cl) => cl.spannedLines >= 2))
        .expand((cls) => cls)
        .map((clwlc) => clwlc.label)
        .toList();
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
    if (node.argumentList != null) {
      var label = node.constructorName.type.name.name;
      if (node.constructorName.name != null)
        label += ".${node.constructorName.name.name}";
      // We override the node used for doing line calculations because otherwise constructors
      // that split over multiple lines (but have parens on same line) would incorrectly
      // get labels, because node.start on an instance creation expression starts at the start
      // of the expression.
      _addLabel(node, label, checkLinesUsing: node.argumentList);
    }

    return super.visitInstanceCreationExpression(node);
  }

  @override
  Object visitMethodInvocation(MethodInvocation node) {
    if (node.argumentList != null) {
      final target = node.target;
      final label = target is Identifier
          ? "${target.name}.${node.methodName.name}"
          : node.methodName.name;
      // We override the node used for doing line calculations because otherwise methods
      // that chain over multiple lines (but have parens on same line) would incorrectly
      // get labels, because node.start on a methodInvocation starts at the start of the expression.
      _addLabel(node, label, checkLinesUsing: node.argumentList);
    }

    return super.visitMethodInvocation(node);
  }

  @override
  visitListLiteral(ListLiteral node) {
    final args = node.typeArguments?.arguments;
    final typeName = args != null ? args[0]?.toString() : null;

    if (typeName != null) {
      _addLabel(node, "List<$typeName>");
    }

    return super.visitListLiteral(node);
  }

  void _addLabel(AstNode node, String label, {AstNode checkLinesUsing}) {
    checkLinesUsing = checkLinesUsing ?? node;
    final start = computer._lineInfo.getLocation(checkLinesUsing.offset);
    final end = computer._lineInfo.getLocation(checkLinesUsing.end - 1);
    final closingLabel = new ClosingLabel(node.offset, node.length, label);
    final labelWithSpan = new _ClosingLabelWithLineCount()
      ..label = closingLabel
      ..spannedLines = end.lineNumber - start.lineNumber;

    if (!computer._closingLabelsByEndLine.containsKey(end.lineNumber)) {
      computer._closingLabelsByEndLine[end.lineNumber] = [];
    }
    computer._closingLabelsByEndLine[end.lineNumber].add(labelWithSpan);
  }
}
