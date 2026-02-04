// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:linter/src/diagnostic.dart' as diag;

class RemoveComparison extends ResolvedCorrectionProducer {
  @override
  final FixKind fixKind;

  @override
  final FixKind multiFixKind;

  /// Initialize a newly created instance with [DartFixKind.removeComparison].
  RemoveComparison({required super.context})
    : fixKind = DartFixKind.removeComparison,
      multiFixKind = DartFixKind.removeComparisonMulti;

  /// Initialize a newly created instance with [DartFixKind.removeTypeCheck].
  RemoveComparison.typeCheck({required super.context})
    : fixKind = DartFixKind.removeTypeCheck,
      multiFixKind = DartFixKind.removeTypeCheckMulti;

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  /// Whether the condition will always return `false`.
  bool get _conditionIsFalse {
    var diagnosticCode = (diagnostic as Diagnostic).diagnosticCode;
    return diagnosticCode == diag.unnecessaryNanComparisonFalse ||
        diagnosticCode == diag.unnecessaryNullComparisonAlwaysNullFalse ||
        diagnosticCode == diag.unnecessaryNullComparisonNeverNullFalse ||
        diagnosticCode == diag.unnecessaryTypeCheckFalse;
  }

  /// Whether the condition will always return `true`.
  bool get _conditionIsTrue {
    var errorCode = (diagnostic as Diagnostic).diagnosticCode;
    return errorCode == diag.unnecessaryNanComparisonTrue ||
        errorCode == diag.unnecessaryNullComparisonAlwaysNullTrue ||
        errorCode == diag.unnecessaryNullComparisonNeverNullTrue ||
        errorCode == diag.unnecessaryTypeCheckTrue ||
        errorCode == diag.avoidNullChecksInEqualityOperators;
  }

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var parent = node.parent;
    if (parent is AssertInitializer && _conditionIsTrue) {
      var constructor = parent.parent as ConstructorDeclaration;
      var list = constructor.initializers;
      if (list.length == 1) {
        await builder.addDartFileEdit(file, (builder) {
          builder.addDeletion(range.endEnd(constructor.parameters, parent));
        });
      } else {
        await builder.addDartFileEdit(file, (builder) {
          builder.addDeletion(range.nodeInList(list, parent));
        });
      }
    } else if (parent is AssertStatement && _conditionIsTrue) {
      await builder.addDartFileEdit(file, (builder) {
        builder.addDeletion(utils.getLinesRange(range.node(parent)));
      });
    } else if (parent is BinaryExpression) {
      var type = parent.operator.type;
      if ((type == TokenType.AMPERSAND_AMPERSAND && _conditionIsTrue) ||
          (type == TokenType.BAR_BAR && _conditionIsFalse)) {
        await _removeOperatorAndOperand(builder, parent);
      }
    } else if (parent is IfElement) {
      await _ifElement(parent, builder);
    } else if (parent is IfStatement) {
      await _ifStatement(parent, builder);
    } else if (parent is ConditionalExpression) {
      await _conditionalExpression(parent, builder);
    }
  }

  /// Splits [text] into lines, and removes one level of indent from each line.
  ///
  /// Lines that don't start with indentation are left as is.
  String indentLeft(String text) {
    var buffer = StringBuffer();
    var indent = utils.oneIndent;
    var eol = utils.endOfLine;
    var lines = text.split(eol);
    for (var line in lines) {
      if (buffer.isNotEmpty) {
        buffer.write(eol);
      }
      String updatedLine;
      if (line.startsWith(indent)) {
        updatedLine = line.substring(indent.length);
      } else {
        updatedLine = line;
      }
      buffer.write(updatedLine);
    }
    return buffer.toString();
  }

  String _blockContents(Block block) {
    // Extract the text inside the braces so we keep comments and blank lines.
    var text = utils.getRangeText(
      range.endStart(block.leftBracket, block.rightBracket),
    );

    // Drop the leading EOL so the first line doesn't turn into a blank line.
    var eol = utils.endOfLine;
    if (text.startsWith(eol)) {
      text = text.substring(eol.length);
    }

    // Remove the trailing indent-only line that comes from the closing brace.
    var lastEol = text.lastIndexOf(eol);
    if (lastEol != -1) {
      var lastLine = text.substring(lastEol + eol.length);
      if (lastLine.trim().isEmpty) {
        text = text.substring(0, lastEol + eol.length);
      }
    }

    return text;
  }

  Future<void> _conditionalExpression(
    ConditionalExpression node,
    ChangeBuilder builder,
  ) async {
    Future<void> replaceWithExpression(Expression expression) async {
      var text = utils.getNodeText(expression);
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(range.node(node), text);
      });
    }

    if (_conditionIsTrue) {
      await replaceWithExpression(node.thenExpression);
    } else if (_conditionIsFalse) {
      await replaceWithExpression(node.elseExpression);
    }
  }

  Future<void> _ifElement(IfElement node, ChangeBuilder builder) async {
    Future<void> replaceWithElement(CollectionElement element) async {
      var text = _textWithLeadingComments(element);
      var unIndented = indentLeft(text);
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(range.node(node), unIndented);
      });
    }

    if (_conditionIsTrue) {
      await replaceWithElement(node.thenElement);
    } else if (_conditionIsFalse) {
      var elseElement = node.elseElement;
      if (elseElement != null) {
        await replaceWithElement(elseElement);
      } else {
        var elements = node.parent.containerElements;
        if (elements != null) {
          await builder.addDartFileEdit(file, (builder) {
            var nodeRange = range.nodeInList(elements, node);
            builder.addDeletion(nodeRange);
          });
        }
      }
    }
  }

  Future<void> _ifStatement(IfStatement node, ChangeBuilder builder) async {
    Future<void> replaceWithBlock(Block replacement) async {
      var text = _blockContents(replacement);
      var unIndented = indentLeft(text);
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(
          utils.getLinesRangeStatements([node]),
          unIndented,
        );
      });
    }

    Future<void> replaceWithStatement(Statement replacement) async {
      var text = _textWithLeadingComments(replacement);
      var unIndented = indentLeft(text);
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleReplacement(range.node(node), unIndented);
      });
    }

    var thenStatement = node.thenStatement;
    var elseStatement = node.elseStatement;
    if (_conditionIsTrue) {
      if (thenStatement case Block thenBlock) {
        await replaceWithBlock(thenBlock);
      } else {
        await replaceWithStatement(thenStatement);
      }
    } else if (_conditionIsFalse) {
      if (elseStatement != null) {
        if (elseStatement case Block elseBlock) {
          await replaceWithBlock(elseBlock);
        } else {
          await replaceWithStatement(elseStatement);
        }
      } else {
        if (node.parent case Block block) {
          var statement = block.statements;
          var nodeRange = range.nodeInList(statement, node);
          await builder.addDartFileEdit(file, (builder) {
            builder.addDeletion(nodeRange);
          });
        }
      }
    }
  }

  /// Adds an edit with [builder] to delete the operator and [node] from the
  /// [binary] expression (where [node] is assumed to be one of the operands).
  Future<void> _removeOperatorAndOperand(
    ChangeBuilder builder,
    BinaryExpression binary,
  ) async {
    SourceRange operatorAndOperand;
    if (binary.leftOperand == node) {
      operatorAndOperand = range.startStart(node, binary.rightOperand);
    } else {
      operatorAndOperand = range.endEnd(binary.leftOperand, node);
    }
    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(operatorAndOperand);
    });
  }

  String _textWithLeadingComments(AstNode node) {
    return utils.getNodeText(node, withLeadingComments: true);
  }
}

extension on AstNode? {
  NodeList<AstNode>? get containerElements {
    var self = this;
    if (self is ListLiteral) {
      return self.elements;
    } else if (self is SetOrMapLiteral) {
      return self.elements;
    }
    return null;
  }
}
