// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ReplaceWithDecoratedBox extends CorrectionProducer {
  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.REPLACE_WITH_DECORATED_BOX;

  @override
  FixKind get multiFixKind => DartFixKind.REPLACE_WITH_DECORATED_BOX_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var instanceCreation =
        node.thisOrAncestorOfType<InstanceCreationExpression>();
    if (instanceCreation is! InstanceCreationExpression) return;

    if (applyingBulkFixes) {
      var parent = instanceCreation.parent
          ?.thisOrAncestorOfType<InstanceCreationExpression>();

      while (parent != null) {
        if (_hasLint(parent)) return;
        parent =
            parent.parent?.thisOrAncestorOfType<InstanceCreationExpression>();
      }
    }

    var deletions = <Token>[];
    var replacements = <AstNode, String>{};
    var linterContext = getLinterContext();

    void replace(Expression expression, {required bool addConst}) {
      if (expression is InstanceCreationExpression && _hasLint(expression)) {
        replacements[expression.constructorName] =
            '${addConst ? 'const ' : ''}DecoratedBox';
      }
    }

    /// Replace the expression if [isReplace] is `true` and it [_hasLint]
    /// and return whether it can be a `const` or not.
    bool canExpressionBeConst(Expression expression,
        {required bool isReplace}) {
      var canBeConst = linterContext.canBeConst(expression);
      if (!canBeConst &&
          isReplace &&
          expression is InstanceCreationExpression &&
          _hasLint(expression)) {
        canBeConst = true;
        var childrenConstMap = <InstanceCreationExpression, bool>{};
        for (var argument in expression.argumentList.arguments) {
          if (argument is NamedExpression) {
            var child = argument.expression;
            var canChildBeConst =
                canExpressionBeConst(child, isReplace: applyingBulkFixes);
            canBeConst &= canChildBeConst;
            if (child is InstanceCreationExpression) {
              childrenConstMap[child] = canChildBeConst;
            }
          } else {
            canBeConst &= canExpressionBeConst(argument, isReplace: isReplace);
          }
        }

        replace(expression, addConst: canBeConst);

        for (var entry in childrenConstMap.entries) {
          var child = entry.key;
          var canChildBeConst = entry.value;
          if (applyingBulkFixes) {
            replace(child, addConst: canChildBeConst && !canBeConst);
          }
          if (canBeConst) {
            var keyword = child.keyword;
            if (keyword != null && keyword.type == Keyword.CONST) {
              deletions.add(keyword);
            }
          }
        }
      }
      return canBeConst;
    }

    canExpressionBeConst(instanceCreation, isReplace: true);

    await builder.addDartFileEdit(file, (builder) {
      for (var entry in replacements.entries) {
        builder.addSimpleReplacement(range.node(entry.key), entry.value);
      }
      for (var token in deletions) {
        builder.addDeletion(range.startStart(token, token.next!));
      }
    });
  }

  /// Return `true` if the specified [expression] has the lint fixed by this
  /// producer.
  bool _hasLint(InstanceCreationExpression expression) {
    var constructorName = expression.constructorName;
    return unitResult.errors.any((error) {
      var errorCode = error.errorCode;
      return errorCode.type == ErrorType.LINT &&
          errorCode.name == LintNames.use_decorated_box &&
          error.offset == constructorName.offset &&
          error.length == constructorName.length;
    });
  }
}
