// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/precedence.dart';
import 'package:analyzer/dart/element/type.dart';
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
    Expression target;
    if (coveredNode is Expression) {
      target = coveredNode;
    } else {
      return;
    }

    var fromType = target.staticType;
    if (fromType == typeProvider.nullType) {
      // Adding a null check after an explicit `null` is pointless.
      return;
    }
    DartType toType;
    var parent = target.parent;
    if (parent is AssignmentExpression && target == parent.rightHandSide) {
      toType = parent.writeType;
    } else if (parent is VariableDeclaration && target == parent.initializer) {
      toType = parent.declaredElement.type;
    } else if (parent is ArgumentList) {
      toType = target.staticParameterElement.type;
    } else if (parent is IndexExpression) {
      toType = parent.realTarget.staticType;
    } else if (parent is ForEachPartsWithDeclaration) {
      toType =
          typeProvider.iterableType(parent.loopVariable.declaredElement.type);
    } else if (parent is ForEachPartsWithIdentifier) {
      toType = typeProvider.iterableType(parent.identifier.staticType);
    } else if (parent is SpreadElement) {
      var literal = parent.thisOrAncestorOfType<TypedLiteral>();
      if (literal is ListLiteral) {
        toType = literal.staticType.asInstanceOf(typeProvider.iterableElement);
      } else if (literal is SetOrMapLiteral) {
        toType = literal.staticType.isDartCoreSet
            ? literal.staticType.asInstanceOf(typeProvider.iterableElement)
            : literal.staticType.asInstanceOf(typeProvider.mapElement);
      }
    } else if (parent is YieldStatement) {
      var enclosingExecutable =
          parent.thisOrAncestorOfType<FunctionBody>().parent;
      if (enclosingExecutable is FunctionDeclaration) {
        toType = enclosingExecutable.returnType?.type;
      } else if (enclosingExecutable is MethodDeclaration) {
        toType = enclosingExecutable.returnType?.type;
      } else if (enclosingExecutable is FunctionExpression) {
        toType = enclosingExecutable.declaredElement.returnType;
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
    var needsParentheses = target.precedence < Precedence.postfix;
    await builder.addDartFileEdit(file, (builder) {
      if (needsParentheses) {
        builder.addSimpleInsertion(target.offset, '(');
      }
      builder.addInsertion(target.end, (builder) {
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
