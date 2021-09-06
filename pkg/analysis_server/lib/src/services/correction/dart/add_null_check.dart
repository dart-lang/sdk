// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/precedence.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class AddNullCheck extends CorrectionProducer {
  @override
  FixKind get fixKind => DartFixKind.ADD_NULL_CHECK;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (!unit.featureSet.isEnabled(Feature.non_nullable)) {
      // Don't suggest a feature that isn't supported.
      return;
    }
    Expression? target;
    final coveredNode = this.coveredNode;
    var coveredNodeParent = coveredNode?.parent;
    if (coveredNode is SimpleIdentifier) {
      if (coveredNodeParent is MethodInvocation) {
        target = coveredNodeParent.realTarget;
      } else if (coveredNodeParent is PrefixedIdentifier) {
        target = coveredNodeParent.prefix;
      } else if (coveredNodeParent is PropertyAccess) {
        target = coveredNodeParent.realTarget;
      } else if (coveredNodeParent is BinaryExpression) {
        target = coveredNodeParent.rightOperand;
      } else {
        target = coveredNode;
      }
    } else if (coveredNode is IndexExpression) {
      target = coveredNode.realTarget;
    } else if (coveredNode is Expression &&
        coveredNodeParent is FunctionExpressionInvocation) {
      target = coveredNode;
    } else if (coveredNodeParent is AssignmentExpression) {
      target = coveredNodeParent.rightHandSide;
    } else if (coveredNode is PostfixExpression) {
      target = coveredNode.operand;
    } else if (coveredNode is PrefixExpression) {
      target = coveredNode.operand;
    } else if (coveredNode is BinaryExpression) {
      target = coveredNode.leftOperand;
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
    DartType? toType;
    var parent = target.parent;
    if (parent is AssignmentExpression && target == parent.rightHandSide) {
      toType = parent.writeType;
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
    } else if ((parent is PrefixedIdentifier && target == parent.prefix) ||
        parent is PostfixExpression ||
        parent is PrefixExpression ||
        parent is BinaryExpression ||
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
        !typeSystem.isAssignableTo(
            typeSystem.promoteToNonNull(fromType), toType)) {
      // The reason that `fromType` can't be assigned to `toType` is more than
      // just because it's nullable, in which case a null check won't fix the
      // problem.
      return;
    }

    final target_final = target;
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

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static AddNullCheck newInstance() => AddNullCheck();
}
