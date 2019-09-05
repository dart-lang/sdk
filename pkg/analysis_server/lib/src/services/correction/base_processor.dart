// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer_plugin/src/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_workspace.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:meta/meta.dart';

/// Base class for common processor functionality.
abstract class BaseProcessor {
  final int selectionOffset;
  final int selectionLength;
  final int selectionEnd;

  final CorrectionUtils utils;
  final String file;

  final ResolvedUnitResult resolvedResult;
  final ChangeWorkspace workspace;

  AstNode node;

  BaseProcessor({
    this.selectionOffset = -1,
    this.selectionLength = 0,
    @required this.resolvedResult,
    @required this.workspace,
  })  : file = resolvedResult.path,
        selectionEnd = (selectionOffset ?? 0) + (selectionLength ?? 0),
        utils = CorrectionUtils(resolvedResult);

  /// Returns the EOL to use for this [CompilationUnit].
  String get eol => utils.endOfLine;

  @protected
  Future<ChangeBuilder> createBuilder_useCurlyBraces() async {
    Future<ChangeBuilder> doStatement(DoStatement node) async {
      var body = node.body;
      if (body is Block) return null;

      var prefix = utils.getLinePrefix(node.offset);
      var indent = prefix + utils.getIndent(1);

      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (builder) {
        builder.addSimpleReplacement(
          range.endStart(node.doKeyword, body),
          ' {$eol$indent',
        );
        builder.addSimpleReplacement(
          range.endStart(body, node.whileKeyword),
          '$eol$prefix} ',
        );
      });
      return changeBuilder;
    }

    Future<ChangeBuilder> forStatement(ForStatement node) async {
      var body = node.body;
      if (body is Block) return null;

      var prefix = utils.getLinePrefix(node.offset);
      var indent = prefix + utils.getIndent(1);

      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (builder) {
        builder.addSimpleReplacement(
          range.endStart(node.rightParenthesis, body),
          ' {$eol$indent',
        );
        builder.addSimpleInsertion(body.end, '$eol$prefix}');
      });

      return changeBuilder;
    }

    Future<ChangeBuilder> ifStatement(
        IfStatement node, Statement thenOrElse) async {
      var prefix = utils.getLinePrefix(node.offset);
      var indent = prefix + utils.getIndent(1);

      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (builder) {
        var thenStatement = node.thenStatement;
        if (thenStatement is! Block &&
            (thenOrElse == null || thenOrElse == thenStatement)) {
          builder.addSimpleReplacement(
            range.endStart(node.rightParenthesis, thenStatement),
            ' {$eol$indent',
          );
          if (node.elseKeyword != null) {
            builder.addSimpleReplacement(
              range.endStart(thenStatement, node.elseKeyword),
              '$eol$prefix} ',
            );
          } else {
            builder.addSimpleInsertion(thenStatement.end, '$eol$prefix}');
          }
        }

        var elseStatement = node.elseStatement;
        if (elseStatement != null &&
            elseStatement is! Block &&
            (thenOrElse == null || thenOrElse == elseStatement)) {
          builder.addSimpleReplacement(
            range.endStart(node.elseKeyword, elseStatement),
            ' {$eol$indent',
          );
          builder.addSimpleInsertion(elseStatement.end, '$eol$prefix}');
        }
      });

      return changeBuilder;
    }

    Future<ChangeBuilder> whileStatement(WhileStatement node) async {
      var body = node.body;
      if (body is Block) return null;

      var prefix = utils.getLinePrefix(node.offset);
      var indent = prefix + utils.getIndent(1);

      var changeBuilder = _newDartChangeBuilder();
      await changeBuilder.addFileEdit(file, (builder) {
        builder.addSimpleReplacement(
          range.endStart(node.rightParenthesis, body),
          ' {$eol$indent',
        );
        builder.addSimpleInsertion(body.end, '$eol$prefix}');
      });
      return changeBuilder;
    }

    var statement = this.node.thisOrAncestorOfType<Statement>();
    var parent = statement?.parent;

    if (statement is DoStatement) {
      return doStatement(statement);
    } else if (parent is DoStatement) {
      return doStatement(parent);
    } else if (statement is ForStatement) {
      return forStatement(statement);
    } else if (parent is ForStatement) {
      return forStatement(parent);
    } else if (statement is IfStatement) {
      if (statement.elseKeyword != null &&
          range.token(statement.elseKeyword).contains(selectionOffset)) {
        return ifStatement(statement, statement.elseStatement);
      } else {
        return ifStatement(statement, null);
      }
    } else if (parent is IfStatement) {
      return ifStatement(parent, statement);
    } else if (statement is WhileStatement) {
      return whileStatement(statement);
    } else if (parent is WhileStatement) {
      return whileStatement(parent);
    }
    return null;
  }

  @protected
  bool setupCompute() {
    final locator = new NodeLocator(selectionOffset, selectionEnd);
    node = locator.searchWithin(resolvedResult.unit);
    return node != null;
  }

  DartChangeBuilder _newDartChangeBuilder() =>
      DartChangeBuilderImpl.forWorkspace(workspace);
}
