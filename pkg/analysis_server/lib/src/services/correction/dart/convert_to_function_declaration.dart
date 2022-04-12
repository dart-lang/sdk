// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToFunctionDeclaration extends CorrectionProducer {
  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_TO_FUNCTION_DECLARATION;

  @override
  FixKind get multiFixKind => DartFixKind.CONVERT_TO_FUNCTION_DECLARATION_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var node = this.node;
    if (node is! VariableDeclaration) return;
    var equals = node.equals;
    if (equals == null) return;
    var initializer = node.initializer;

    var parent = node.parent;
    if (parent is! VariableDeclarationList) return;
    var keyword = parent.keyword;
    var type = parent.type;

    var variables = parent.variables;

    var grandParent = parent.parent;
    if (grandParent is! VariableDeclarationStatement) return;

    var previous = _previous(variables, node);
    var next = _next(variables, node);

    await builder.addDartFileEdit(file, (builder) {
      void replaceWithNewLine(SourceRange range,
          {String? before, String? after}) {
        builder.addReplacement(range, (builder) {
          if (before != null) {
            builder.write(before);
          }
          builder.write(utils.endOfLine);
          builder.write(utils.getLinePrefix(range.offset));
          if (after != null) {
            builder.write(after);
          }
        });
      }

      if (previous == null) {
        if (keyword != null) {
          builder.addDeletion(range.startStart(keyword, keyword.next!));
        }
        if (type != null) {
          builder.addDeletion(range.startStart(type, type.endToken.next!));
        }
      } else if (previous.initializer is! FunctionExpression) {
        var r =
            range.endStart(previous.endToken, previous.endToken.next!.next!);
        replaceWithNewLine(r, before: ';');
      }

      builder.addDeletion(range.endStart(equals.previous!, equals.next!));

      if (next != null) {
        var r = range.endStart(node.endToken, node.endToken.next!.next!);
        if (next.initializer is FunctionExpression) {
          replaceWithNewLine(r);
        } else {
          var replacement = '';
          if (keyword != null) {
            replacement += '$keyword ';
          }
          if (type != null) {
            replacement += '${utils.getNodeText(type)} ';
          }
          replaceWithNewLine(r, after: replacement);
        }
      } else if (initializer is FunctionExpression &&
          initializer.body is BlockFunctionBody) {
        builder.addDeletion(range.token(grandParent.semicolon));
      }
    });
  }

  VariableDeclaration? _next(
      NodeList<VariableDeclaration> variables, VariableDeclaration variable) {
    var i = variables.indexOf(variable);
    return i < variables.length - 1 ? variables[i + 1] : null;
  }

  VariableDeclaration? _previous(
      NodeList<VariableDeclaration> variables, VariableDeclaration variable) {
    var i = variables.indexOf(variable);
    return i > 0 ? variables[i - 1] : null;
  }
}
