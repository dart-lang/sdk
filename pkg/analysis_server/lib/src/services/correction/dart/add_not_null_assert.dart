// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

class AddNotNullAssert extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.ADD_NOT_NULL_ASSERT;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final identifier = node;
    if (identifier is! SimpleIdentifier) {
      return;
    }

    var formalParameter = identifier.parent;
    if (formalParameter is! FormalParameter) {
      return;
    }

    final executable = formalParameter.thisOrAncestorMatching(
        (node) => node is FunctionExpression || node is MethodDeclaration);
    if (executable == null) {
      return;
    }

    FunctionBody? body;
    if (executable is FunctionExpression) {
      body = executable.body;
    } else if (executable is MethodDeclaration) {
      body = executable.body;
    }

    if (body is BlockFunctionBody) {
      // Check for an obvious pre-existing assertion.
      for (var statement in body.block.statements) {
        if (statement is AssertStatement) {
          final condition = statement.condition;
          if (condition is BinaryExpression) {
            final leftOperand = condition.leftOperand;
            if (leftOperand is SimpleIdentifier) {
              if (leftOperand.staticElement == identifier.staticElement &&
                  condition.operator.type == TokenType.BANG_EQ &&
                  condition.rightOperand is NullLiteral) {
                return;
              }
            }
          }
        }
      }

      final body_final = body;
      await builder.addDartFileEdit(file, (builder) {
        final id = identifier.name;
        final prefix = utils.getNodePrefix(executable);
        final indent = utils.getIndent(1);
        // todo (pq): follow-ups:
        // 1. if the end token is on the same line as the body
        // we should add an `eol` before the assert as well.
        // 2. also, consider asking the block for the list of statements and
        // adding the statement to the beginning of the list, special casing
        // when there are no statements (or when there's a single statement
        // and the whole block is on the same line).
        var offset = min(utils.getLineNext(body_final.beginToken.offset),
            body_final.endToken.offset);
        builder.addSimpleInsertion(
            offset, '$prefix${indent}assert($id != null);$eol');
      });
    }
  }

  /// Return an instance of this class. Used as a tear-off in `AssistProcessor`.
  static AddNotNullAssert newInstance() => AddNotNullAssert();
}
