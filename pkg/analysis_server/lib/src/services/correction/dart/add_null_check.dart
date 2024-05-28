// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/precedence.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class AddNullCheck extends ResolvedCorrectionProducer {
  @override
  final CorrectionApplicability applicability;

  final bool skipAssignabilityCheck;

  @override
  // This is a mutable field so it can be changed in `_replaceWithNullCheck`.
  // TODO(srawlins): This seems to violate a few assert statements around the
  // package that read:
  //
  // > Producers used in bulk fixes must not modify the FixKind during
  // > computation.
  FixKind fixKind = DartFixKind.ADD_NULL_CHECK;

  @override
  List<String>? fixArguments;

  AddNullCheck()
      : skipAssignabilityCheck = false,
        applicability = CorrectionApplicability.singleLocation;

  AddNullCheck.withoutAssignabilityCheck()
      : skipAssignabilityCheck = true,
        applicability = CorrectionApplicability.automaticallyButOncePerFile;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    Expression? target;
    var coveringNode = this.coveringNode;
    var coveringNodeParent = coveringNode?.parent;

    if (await _isNullAware(builder, coveringNode)) {
      return;
    }

    if (coveringNode is SimpleIdentifier) {
      if (coveringNodeParent is MethodInvocation) {
        target = coveringNodeParent.realTarget;
      } else if (coveringNodeParent is PrefixedIdentifier) {
        target = coveringNodeParent.prefix;
      } else if (coveringNodeParent is PropertyAccess) {
        target = coveringNodeParent.realTarget;
      } else if (coveringNodeParent is CascadeExpression &&
          await _isNullAware(
              builder, coveringNodeParent.cascadeSections.first)) {
        return;
      } else {
        target = coveringNode;
      }
    } else if (coveringNode is IndexExpression) {
      target = coveringNode.realTarget;
      if (target.staticType?.nullabilitySuffix != NullabilitySuffix.question) {
        target = coveringNode;
      }
    } else if (coveringNode is Expression &&
        coveringNodeParent is FunctionExpressionInvocation) {
      target = coveringNode;
    } else if (coveringNodeParent is AssignmentExpression) {
      target = coveringNodeParent.rightHandSide;
    } else if (coveringNode is PostfixExpression) {
      target = coveringNode.operand;
    } else if (coveringNode is PrefixExpression) {
      target = coveringNode.operand;
    } else if (coveringNode is BinaryExpression) {
      if (coveringNode.operator.type != TokenType.QUESTION_QUESTION) {
        target = coveringNode.leftOperand;
      } else {
        var expectedType = coveringNode.staticParameterElement?.type;
        if (expectedType == null) return;

        var leftType = coveringNode.leftOperand.staticType;
        var leftAssignable = leftType != null &&
            typeSystem.isAssignableTo(
                typeSystem.promoteToNonNull(leftType), expectedType,
                strictCasts: analysisOptions.strictCasts);
        if (leftAssignable) {
          target = coveringNode.rightOperand;
        }
      }
    } else if (coveringNode is AsExpression) {
      target = coveringNode.expression;
    }

    if (target == null) {
      return;
    }

    var fromType = target.staticType;
    if (fromType == null) {
      return;
    }

    if (fromType == typeProvider.nullType) {
      // Adding a null check after an explicit `null` is pointless.
      return;
    }

    if (await _isNullAware(builder, target)) {
      return;
    }
    DartType? toType;
    var parent = target.parent;
    if (parent is AssignmentExpression && target == parent.rightHandSide) {
      toType = parent.writeType;
    } else if (parent is AsExpression) {
      toType = parent.staticType;
    } else if (parent is VariableDeclaration && target == parent.initializer) {
      toType = parent.declaredElement?.type;
    } else if (parent is ArgumentList) {
      toType = target.staticParameterElement?.type;
    } else if (parent is IndexExpression) {
      toType = parent.realTarget.typeOrThrow;
    } else if (parent is ForEachPartsWithDeclaration) {
      toType =
          typeProvider.iterableType(parent.loopVariable.declaredElement!.type);
    } else if (parent is ForEachPartsWithIdentifier) {
      toType = typeProvider.iterableType(parent.identifier.typeOrThrow);
    } else if (parent is SpreadElement) {
      var literal = parent.thisOrAncestorOfType<TypedLiteral>();
      if (literal is ListLiteral) {
        toType = literal.typeOrThrow.asInstanceOf(typeProvider.iterableElement);
      } else if (literal is SetOrMapLiteral) {
        toType = literal.typeOrThrow.isDartCoreSet
            ? literal.typeOrThrow.asInstanceOf(typeProvider.iterableElement)
            : literal.typeOrThrow.asInstanceOf(typeProvider.mapElement);
      }
    } else if (parent is YieldStatement) {
      var enclosingExecutable =
          parent.thisOrAncestorOfType<FunctionBody>()?.parent;
      if (enclosingExecutable is FunctionDeclaration) {
        toType = enclosingExecutable.returnType?.type;
      } else if (enclosingExecutable is MethodDeclaration) {
        toType = enclosingExecutable.returnType?.type;
      } else if (enclosingExecutable is FunctionExpression) {
        toType = enclosingExecutable.declaredElement!.returnType;
      }
    } else if (parent is BinaryExpression) {
      if (typeSystem.isNonNullable(fromType)) {
        return;
      }
      var expectedType = parent.staticParameterElement?.type;
      if (expectedType != null &&
          !typeSystem.isAssignableTo(
              typeSystem.promoteToNonNull(fromType), expectedType,
              strictCasts: analysisOptions.strictCasts)) {
        return;
      }
    } else if ((parent is PrefixedIdentifier && target == parent.prefix) ||
        parent is PostfixExpression ||
        parent is PrefixExpression ||
        (parent is PropertyAccess && target == parent.target) ||
        (parent is CascadeExpression && target == parent.target) ||
        (parent is MethodInvocation && target == parent.target) ||
        (parent is FunctionExpressionInvocation && target == parent.function)) {
      // No need to set the `toType` because there isn't any need for a type
      // check.
    } else {
      return;
    }
    if (toType != null &&
        !skipAssignabilityCheck &&
        !typeSystem.isAssignableTo(
            typeSystem.promoteToNonNull(fromType), toType,
            strictCasts: analysisOptions.strictCasts)) {
      // The reason that `fromType` can't be assigned to `toType` is more than
      // just because it's nullable, in which case a null check won't fix the
      // problem.
      return;
    }

    var target_final = target;
    var needsParentheses = target.precedence < Precedence.postfix;
    await builder.addDartFileEdit(file, (builder) {
      if (needsParentheses) {
        builder.addSimpleInsertion(target_final.offset, '(');
      }
      builder.addInsertion(target_final.end, (builder) {
        if (needsParentheses) {
          builder.write(')');
        }
        builder.write('!');
      });
    });
  }

  /// Return `true` if the specified [node] or one of its parents `isNullAware`,
  /// in which case [_replaceWithNullCheck] would also be called.
  Future<bool> _isNullAware(ChangeBuilder builder, AstNode? node) async {
    if (node is PropertyAccess) {
      if (node.isNullAware) {
        await _replaceWithNullCheck(builder, node.operator);
        return true;
      }
      return await _isNullAware(builder, node.target);
    } else if (node is MethodInvocation) {
      var operator = node.operator;
      if (operator != null && node.isNullAware) {
        await _replaceWithNullCheck(builder, operator);
        return true;
      }
      return await _isNullAware(builder, node.target);
    } else if (node is IndexExpression) {
      var question = node.question;
      if (question != null) {
        await _replaceWithNullCheck(builder, question);
        return true;
      }
      return await _isNullAware(builder, node.target);
    }
    return false;
  }

  /// Replaces the null aware [token] with the null check operator.
  Future<void> _replaceWithNullCheck(ChangeBuilder builder, Token token) async {
    fixKind = DartFixKind.REPLACE_WITH_NULL_AWARE;
    var lexeme = token.lexeme;
    var replacement = '!${lexeme.substring(1)}';
    fixArguments = [lexeme, replacement];
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.token(token), replacement);
    });
  }
}
