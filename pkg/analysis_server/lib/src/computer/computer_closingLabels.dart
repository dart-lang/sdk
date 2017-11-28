// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/generated/source.dart';

// TODO(devoncarew): We should look into not creating any labels until there's
// at least 2 levels of nesting.

/**
 * A computer for [CompilationUnit] closing labels.
 */
class DartUnitClosingLabelsComputer {
  final LineInfo _lineInfo;
  final CompilationUnit _unit;
  final List<ClosingLabel> _closingLabels = [];

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

  int interpolatedStringsEntered = 0;

  _DartUnitClosingLabelsComputerVisitor(this.computer);

  @override
  Object visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.argumentList != null) {
      var label = node.constructorName.type.name.name;
      if (node.constructorName.name != null) {
        label += ".${node.constructorName.name.name}";
      }
      // We override the node used for doing line calculations because otherwise
      // constructors that split over multiple lines (but have parens on same
      // line) would incorrectly get labels, because node.start on an instance
      // creation expression starts at the start of the expression.
      _addLabel(node, label, checkLinesUsing: node.argumentList);
    }

    return super.visitInstanceCreationExpression(node);
  }

  @override
  Object visitListLiteral(ListLiteral node) {
    final NodeList<TypeAnnotation> args = node.typeArguments?.arguments;
    final String typeName = args != null ? args[0]?.toString() : null;

    if (typeName != null) {
      _addLabel(node, "<$typeName>[]");
    }

    return super.visitListLiteral(node);
  }

  @override
  Object visitStringInterpolation(StringInterpolation node) {
    interpolatedStringsEntered++;
    try {
      return super.visitStringInterpolation(node);
    } finally {
      interpolatedStringsEntered--;
    }
  }

  void _addLabel(AstNode node, String label, {AstNode checkLinesUsing}) {
    // Never add labels if we're inside strings.
    if (interpolatedStringsEntered > 0) {
      return;
    }

    checkLinesUsing = checkLinesUsing ?? node;

    final LineInfo_Location start =
        computer._lineInfo.getLocation(checkLinesUsing.offset);
    final LineInfo_Location end =
        computer._lineInfo.getLocation(checkLinesUsing.end - 1);

    int spannedLines = end.lineNumber - start.lineNumber;
    if (spannedLines < 1) {
      return;
    }

    final ClosingLabel closingLabel =
        new ClosingLabel(node.offset, node.length, label);

    computer._closingLabels.add(closingLabel);
  }
}
