// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/precedence.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/extensions.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class AddNullCheck extends ResolvedCorrectionProducer {
  @override
  final CorrectionApplicability applicability;

  final bool skipAssignabilityCheck;

  @override
  final FixKind fixKind;

  @override
  List<String>? fixArguments;

  /// The real target on which we might produce a correction, derived from
  /// [node].
  final Expression? _target;

  /// A [Token] that, if non-`null`, will be transformed into a null-aware
  /// operator token.
  final Token? _nullAwareToken;

  factory AddNullCheck({required CorrectionProducerContext context}) {
    var (:target, :nullAwareToken) =
        context is StubCorrectionProducerContext
            ? (target: null, nullAwareToken: null)
            : _computeTargetAndNullAwareToken(context.node);

    return AddNullCheck._(
      context: context,
      skipAssignabilityCheck: false,
      applicability: CorrectionApplicability.singleLocation,
      target: target,
      nullAwareToken: nullAwareToken,
    );
  }

  factory AddNullCheck.withoutAssignabilityCheck({
    required CorrectionProducerContext context,
  }) {
    var (:target, :nullAwareToken) =
        context is StubCorrectionProducerContext
            ? (target: null, nullAwareToken: null)
            : _computeTargetAndNullAwareToken(context.node);

    return AddNullCheck._(
      context: context,
      skipAssignabilityCheck: true,
      applicability: CorrectionApplicability.automaticallyButOncePerFile,
      target: target,
      nullAwareToken: nullAwareToken,
    );
  }

  AddNullCheck._({
    required super.context,
    required this.skipAssignabilityCheck,
    required this.applicability,
    required Expression? target,
    required Token? nullAwareToken,
  }) : _target = target,
       _nullAwareToken = nullAwareToken,
       fixKind =
           nullAwareToken == null
               ? DartFixKind.ADD_NULL_CHECK
               : DartFixKind.REPLACE_WITH_NULL_AWARE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (_nullAwareToken != null) {
      return _replaceWithNullCheck(builder, _nullAwareToken);
    }

    if (_target == null) {
      return;
    }
    var fromType = _target.staticType;
    if (fromType == null) {
      return;
    }

    if (fromType == typeProvider.nullType) {
      // Adding a null check after an explicit `null` is pointless.
      return;
    }

    if (coveringNode case BinaryExpression binaryExpression) {
      if (binaryExpression.operator.type == TokenType.QUESTION_QUESTION &&
          _target == binaryExpression.rightOperand &&
          !_couldBeAssignableInNullAwareExpression(binaryExpression)) {
        // Do not offer to add a null-check in the right side of `??` if that
        // would not fix the issue.
        return;
      }
    }

    DartType? toType;
    var parent = _target.parent;
    if (parent is AssignmentExpression && _target == parent.rightHandSide) {
      toType = parent.writeType;
    } else if (parent is AsExpression) {
      toType = parent.staticType;
    } else if (parent is VariableDeclaration && _target == parent.initializer) {
      toType = parent.declaredFragment!.element.type;
    } else if (parent is ArgumentList) {
      toType = _target.correspondingParameter?.type;
    } else if (parent is IndexExpression) {
      toType = parent.realTarget.typeOrThrow;
    } else if (parent is ForEachPartsWithDeclaration) {
      toType = typeProvider.iterableType(
        parent.loopVariable.declaredElement2!.type,
      );
    } else if (parent is ForEachPartsWithIdentifier) {
      toType = typeProvider.iterableType(parent.identifier.typeOrThrow);
    } else if (parent is SpreadElement) {
      var literal = parent.thisOrAncestorOfType<TypedLiteral>();
      if (literal is ListLiteral) {
        toType = literal.typeOrThrow.asInstanceOf2(
          typeProvider.iterableElement,
        );
      } else if (literal is SetOrMapLiteral) {
        toType =
            literal.typeOrThrow.isDartCoreSet
                ? literal.typeOrThrow.asInstanceOf2(
                  typeProvider.iterableElement,
                )
                : literal.typeOrThrow.asInstanceOf2(typeProvider.mapElement);
      }
    } else if (parent is YieldStatement) {
      var enclosingExecutable =
          parent.thisOrAncestorOfType<FunctionBody>()?.parent;
      if (enclosingExecutable is MethodDeclaration) {
        toType = enclosingExecutable.returnType?.type;
      } else if (enclosingExecutable is FunctionExpressionImpl) {
        toType = enclosingExecutable.declaredFragment!.element.returnType;
      }
    } else if (parent is BinaryExpression) {
      if (typeSystem.isNonNullable(fromType)) {
        return;
      }
      var expectedType = parent.correspondingParameter?.type;
      if (expectedType != null &&
          !typeSystem.isAssignableTo(
            typeSystem.promoteToNonNull(fromType),
            expectedType,
            strictCasts: analysisOptions.strictCasts,
          )) {
        return;
      }
    } else if ((parent is PrefixedIdentifier && _target == parent.prefix) ||
        parent is PostfixExpression ||
        parent is PrefixExpression ||
        (parent is PropertyAccess && _target == parent.target) ||
        (parent is CascadeExpression && _target == parent.target) ||
        (parent is MethodInvocation && _target == parent.target) ||
        (parent is FunctionExpressionInvocation &&
            _target == parent.function)) {
      // No need to set the `toType` because there isn't any need for a type
      // check.
    } else {
      return;
    }
    if (toType != null &&
        !skipAssignabilityCheck &&
        !typeSystem.isAssignableTo(
          typeSystem.promoteToNonNull(fromType),
          toType,
          strictCasts: analysisOptions.strictCasts,
        )) {
      // The reason that `fromType` can't be assigned to `toType` is more than
      // just because it's nullable, in which case a null check won't fix the
      // problem.
      return;
    }

    var needsParentheses = _target.precedence < Precedence.postfix;
    await builder.addDartFileEdit(file, (builder) {
      if (needsParentheses) {
        builder.addSimpleInsertion(_target.offset, '(');
      }
      builder.addInsertion(_target.end, (builder) {
        if (needsParentheses) {
          builder.write(')');
        }
        builder.write('!');
      });
    });
  }

  /// Given that [_target] is the right operand in [binaryExpression], returns
  /// whether [_target], if promoted to be non-`null`, could be assignable to
  /// [binaryExpression]'s associated parameter.
  bool _couldBeAssignableInNullAwareExpression(
    BinaryExpression binaryExpression,
  ) {
    var expectedType = binaryExpression.correspondingParameter?.type;
    if (expectedType == null) {
      return true;
    }
    var leftType = binaryExpression.leftOperand.staticType;
    return leftType != null &&
        typeSystem.isAssignableTo(
          typeSystem.promoteToNonNull(leftType),
          expectedType,
          strictCasts: analysisOptions.strictCasts,
        );
  }

  /// Replaces the null-aware [token] with the null check operator.
  Future<void> _replaceWithNullCheck(ChangeBuilder builder, Token token) {
    var lexeme = token.lexeme;
    var replacement = '!${lexeme.substring(1)}';
    fixArguments = [lexeme, replacement];
    return builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range.token(token), replacement);
    });
  }

  /// Computes both the target in which we might make a correction, and a
  /// null-aware [Token] that we might instead convert into a null-aware
  /// operator token.
  static ({Expression? target, Token? nullAwareToken})
  _computeTargetAndNullAwareToken(AstNode? coveringNode) {
    var nullAwareToken = _hasNullAware(coveringNode);
    if (coveringNode is Expression && nullAwareToken != null) {
      return (target: coveringNode, nullAwareToken: nullAwareToken);
    }

    var parent = coveringNode?.parent;
    Expression? target;
    if (coveringNode is SimpleIdentifier) {
      if (parent is MethodInvocation) {
        target = parent.realTarget;
      } else if (parent is PrefixedIdentifier) {
        target = parent.prefix;
      } else if (parent is PropertyAccess) {
        target = parent.realTarget;
      } else {
        target = coveringNode;
      }
    } else if (coveringNode is IndexExpression) {
      target = coveringNode.realTarget;
      if (target.staticType?.nullabilitySuffix != NullabilitySuffix.question) {
        target = coveringNode;
      }
    } else if (coveringNode is Expression &&
        parent is FunctionExpressionInvocation) {
      target = coveringNode;
    } else if (parent is AssignmentExpression) {
      target = parent.rightHandSide;
    } else if (coveringNode is PostfixExpression) {
      target = coveringNode.operand;
    } else if (coveringNode is PrefixExpression) {
      target = coveringNode.operand;
    } else if (coveringNode is BinaryExpression) {
      if (coveringNode.operator.type != TokenType.QUESTION_QUESTION) {
        target = coveringNode.leftOperand;
      } else {
        var expectedType = coveringNode.correspondingParameter?.type;
        if (expectedType != null) {
          target = coveringNode.rightOperand;
        }
      }
    } else if (coveringNode is AsExpression) {
      target = coveringNode.expression;
    }

    if (target == null) {
      return (target: null, nullAwareToken: null);
    }

    nullAwareToken = _hasNullAware(target);
    return (target: target, nullAwareToken: nullAwareToken);
  }

  /// Adds an edit to a null-aware operation, replacing the `?` with a `!`
  /// character, if applicable.
  ///
  /// Returns whether this edit was made.
  static Token? _hasNullAware(AstNode? node) {
    if (node is PropertyAccess) {
      if (node.isNullAware) {
        return node.operator;
      }
      return _hasNullAware(node.target);
    } else if (node case MethodInvocation(:var operator)) {
      if (operator != null && node.isNullAware) {
        return operator;
      }
      return _hasNullAware(node.target);
    } else if (node case IndexExpression(:var question)) {
      if (question != null) {
        return question;
      }
      return _hasNullAware(node.target);
    } else if (node case SimpleIdentifier(:CascadeExpression parent)) {
      return _hasNullAware(parent.cascadeSections.first);
    }

    return null;
  }
}
