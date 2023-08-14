// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'package:_fe_analyzer_shared/src/util/link.dart';
import 'package:kernel/ast.dart';
import '../fasta_codes.dart';
import '../kernel/internal_ast.dart';
import 'external_ast_helper.dart';
import 'inference_helper.dart';
import 'inference_visitor_base.dart';
import 'type_schema.dart';

/// The result of a statement inference.
class StatementInferenceResult {
  const StatementInferenceResult();

  factory StatementInferenceResult.single(Statement statement) =
      SingleStatementInferenceResult;

  factory StatementInferenceResult.multiple(
      int fileOffset, List<Statement> statements) {
    if (statements.length == 0) {
      return const StatementInferenceResult();
    } else if (statements.length == 1) {
      return new SingleStatementInferenceResult(statements.single);
    } else {
      return new MultipleStatementInferenceResult(fileOffset, statements);
    }
  }

  bool get hasChanged => false;

  Statement get statement =>
      throw new UnsupportedError('StatementInferenceResult.statement');

  int get statementCount =>
      throw new UnsupportedError('StatementInferenceResult.statementCount');

  List<Statement> get statements =>
      throw new UnsupportedError('StatementInferenceResult.statements');
}

class SingleStatementInferenceResult implements StatementInferenceResult {
  @override
  final Statement statement;

  SingleStatementInferenceResult(this.statement);

  @override
  bool get hasChanged => true;

  @override
  int get statementCount => 1;

  @override
  List<Statement> get statements =>
      throw new UnsupportedError('SingleStatementInferenceResult.statements');
}

class MultipleStatementInferenceResult implements StatementInferenceResult {
  final int fileOffset;
  @override
  final List<Statement> statements;

  MultipleStatementInferenceResult(this.fileOffset, this.statements)
      : assert(statements.isNotEmpty,
            "The multi-statement result shouldn't be empty."),
        assert(
            statements.length != 1,
            "For the results containing a single statement,"
            "use SingleStatementInferenceResult.");

  @override
  bool get hasChanged => true;

  @override
  Statement get statement {
    if (statements.length == 1) {
      return statements.single;
    } else {
      return new Block(statements)..fileOffset = fileOffset;
    }
  }

  @override
  int get statementCount => statements.length;
}

/// Tells the inferred type and how the code should be transformed.
///
/// It is intended for use by generalized inference methods, such as
/// [InferenceVisitorBase.inferInvocation], where the input [Expression] isn't
/// available for rewriting.  So, instead of transforming the code, the result
/// of the inference provides a way to transform the code at the point of
/// invocation.
abstract class InvocationInferenceResult {
  DartType get inferredType;

  DartType get functionType;

  /// Applies the result of the inference to the expression being inferred.
  ///
  /// A successful result leaves [expression] intact, and an error detected
  /// during inference would wrap the expression into an [InvalidExpression].
  Expression applyResult(Expression expression);

  /// Returns `true` if the arguments of the call where not applicable to the
  /// target.
  bool get isInapplicable;

  static Expression _insertHoistedExpressions(
      Expression expression, List<VariableDeclaration> hoistedExpressions) {
    if (hoistedExpressions.isNotEmpty) {
      for (int index = hoistedExpressions.length - 1; index >= 0; index--) {
        expression = createLet(hoistedExpressions[index], expression);
      }
    }
    return expression;
  }
}

class SuccessfulInferenceResult implements InvocationInferenceResult {
  @override
  final DartType inferredType;

  @override
  final FunctionType functionType;

  final List<VariableDeclaration>? hoistedArguments;

  final DartType? inferredReceiverType;

  SuccessfulInferenceResult(this.inferredType, this.functionType,
      {required this.hoistedArguments, this.inferredReceiverType});

  @override
  Expression applyResult(Expression expression) {
    List<VariableDeclaration>? hoistedArguments = this.hoistedArguments;
    if (hoistedArguments == null || hoistedArguments.isEmpty) {
      return expression;
    } else {
      assert(expression is InvocationExpression ||
          expression is InvalidExpression);
      if (expression is FactoryConstructorInvocation) {
        return InvocationInferenceResult._insertHoistedExpressions(
            expression, hoistedArguments);
      } else if (expression is TypeAliasedConstructorInvocation) {
        return InvocationInferenceResult._insertHoistedExpressions(
            expression, hoistedArguments);
      } else if (expression is TypeAliasedFactoryInvocation) {
        return InvocationInferenceResult._insertHoistedExpressions(
            expression, hoistedArguments);
      } else if (expression is ConstructorInvocation) {
        return InvocationInferenceResult._insertHoistedExpressions(
            expression, hoistedArguments);
      } else if (expression is DynamicInvocation) {
        return InvocationInferenceResult._insertHoistedExpressions(
            expression, hoistedArguments);
      } else if (expression is FunctionInvocation) {
        return InvocationInferenceResult._insertHoistedExpressions(
            expression, hoistedArguments);
      } else if (expression is InstanceGetterInvocation) {
        // The hoisting of InstanceGetterInvocation is performed elsewhere.
        return expression;
      } else if (expression is InstanceInvocation) {
        if (!isPureExpression(expression.receiver)) {
          VariableDeclaration receiver = createVariable(
              expression.receiver, inferredReceiverType ?? const DynamicType());
          expression.receiver = createVariableGet(receiver)
            ..parent = expression;
          return createLet(
              receiver,
              InvocationInferenceResult._insertHoistedExpressions(
                  expression, hoistedArguments));
        } else {
          return InvocationInferenceResult._insertHoistedExpressions(
              expression, hoistedArguments);
        }
      } else if (expression is LocalFunctionInvocation) {
        return InvocationInferenceResult._insertHoistedExpressions(
            expression, hoistedArguments);
      } else if (expression is StaticInvocation) {
        return InvocationInferenceResult._insertHoistedExpressions(
            expression, hoistedArguments);
      } else if (expression is SuperMethodInvocation) {
        return InvocationInferenceResult._insertHoistedExpressions(
            expression, hoistedArguments);
      } else if (expression is InvalidExpression) {
        return InvocationInferenceResult._insertHoistedExpressions(
            expression, hoistedArguments);
      } else {
        throw new StateError(
            "Unhandled invocation kind '${expression.runtimeType}'.");
      }
    }
  }

  @override
  bool get isInapplicable => false;
}

class WrapInProblemInferenceResult implements InvocationInferenceResult {
  @override
  final DartType inferredType;

  @override
  final DartType functionType;

  final Message message;

  final int fileOffset;

  final int length;

  final InferenceHelper helper;

  @override
  final bool isInapplicable;

  final List<VariableDeclaration>? hoistedArguments;

  WrapInProblemInferenceResult(this.inferredType, this.functionType,
      this.message, this.fileOffset, this.length, this.helper,
      {required this.isInapplicable, required this.hoistedArguments});

  @override
  Expression applyResult(Expression expression) {
    expression = helper.wrapInProblem(expression, message, fileOffset, length);
    List<VariableDeclaration>? hoistedArguments = this.hoistedArguments;
    if (hoistedArguments == null || hoistedArguments.isEmpty) {
      return expression;
    } else {
      return InvocationInferenceResult._insertHoistedExpressions(
          expression, hoistedArguments);
    }
  }
}

abstract class InitializerInferenceResult {
  /// Modifies list of initializers in-place to apply the inference result.
  void applyResult(List<Initializer> initializers, TreeNode? parent);

  factory InitializerInferenceResult.fromInvocationInferenceResult(
      InvocationInferenceResult invocationInferenceResult) {
    if (invocationInferenceResult is SuccessfulInferenceResult) {
      return new SuccessfulInitializerInvocationInferenceResult
          .fromSuccessfulInferenceResult(invocationInferenceResult);
    } else {
      return new WrapInProblemInitializerInferenceResult
              .fromWrapInProblemInferenceResult(
          invocationInferenceResult as WrapInProblemInferenceResult);
    }
  }
}

class SuccessfulInitializerInferenceResult
    implements InitializerInferenceResult {
  const SuccessfulInitializerInferenceResult();

  @override
  void applyResult(List<Initializer> initializers, TreeNode? parent) {}
}

class SuccessfulInitializerInvocationInferenceResult
    implements InitializerInferenceResult {
  final DartType inferredType;

  final FunctionType functionType;

  final List<VariableDeclaration>? hoistedArguments;

  final DartType? inferredReceiverType;

  SuccessfulInitializerInvocationInferenceResult(
      {required this.inferredType,
      required this.functionType,
      required this.hoistedArguments,
      required this.inferredReceiverType});

  SuccessfulInitializerInvocationInferenceResult.fromSuccessfulInferenceResult(
      SuccessfulInferenceResult successfulInferenceResult)
      : this(
            inferredType: successfulInferenceResult.inferredType,
            functionType: successfulInferenceResult.functionType,
            hoistedArguments: successfulInferenceResult.hoistedArguments,
            inferredReceiverType:
                successfulInferenceResult.inferredReceiverType);

  @override
  void applyResult(List<Initializer> initializers, TreeNode? parent) {
    List<VariableDeclaration>? hoistedArguments = this.hoistedArguments;
    if (hoistedArguments != null && hoistedArguments.isNotEmpty) {
      for (VariableDeclaration hoistedArgument in hoistedArguments) {
        initializers.add(new LocalInitializer(hoistedArgument)
          ..parent = parent
          ..fileOffset = hoistedArgument.fileOffset);
      }
    }
  }
}

class WrapInProblemInitializerInferenceResult
    implements InitializerInferenceResult {
  WrapInProblemInitializerInferenceResult.fromWrapInProblemInferenceResult(
      WrapInProblemInferenceResult wrapInProblemInferenceResult);

  @override
  void applyResult(List<Initializer> initializers, TreeNode? parent) {}
}

/// The result of inference of a property get expression.
class PropertyGetInferenceResult {
  /// The main inference result.
  final ExpressionInferenceResult expressionInferenceResult;

  /// The property that was looked up, or `null` if no property was found.
  final Member? member;

  PropertyGetInferenceResult(this.expressionInferenceResult, this.member);
}

/// The result of an expression inference.
class ExpressionInferenceResult {
  /// The inferred type of the expression.
  final DartType inferredType;

  /// The inferred expression.
  final Expression expression;

  /// More precise type of the expression after coercion.
  ///
  /// Consider the following code:
  ///
  ///   dynamic foo = 3;
  ///   int bar = foo;
  ///
  /// In the example above `foo` is coerced to `foo as int`, but
  /// [inferredType]` of `foo` stays `dynamic`.  In some situations, like
  /// coercing elements of record literals, we want to know the more precise
  /// type of the expression after coercion, `int` in the example above.
  final DartType? postCoercionType;

  ExpressionInferenceResult(this.inferredType, this.expression,
      {this.postCoercionType = null})
      : assert(isKnown(inferredType));

  /// The guards used for null-aware access if the expression is part of a
  /// null-shorting.
  Link<NullAwareGuard> get nullAwareGuards => const Link<NullAwareGuard>();

  /// If the expression is part of a null-shorting, this is the action performed
  /// on the guarded variable, found as the first guard in [nullAwareGuards].
  /// Otherwise, this is the same as [expression].
  Expression get nullAwareAction => expression;

  DartType get nullAwareActionType => inferredType;

  ExpressionInferenceResult stopShorting() => this;

  @override
  String toString() => 'ExpressionInferenceResult($inferredType,$expression)';
}

/// A guard used for creating null-shorting null-aware actions.
class NullAwareGuard {
  /// The variable used to guard the null-aware action.
  final VariableDeclaration _nullAwareVariable;

  /// The file offset used for the null-test.
  int _nullAwareFileOffset;

  final InferenceVisitorBase _inferrer;

  NullAwareGuard(
      this._nullAwareVariable, this._nullAwareFileOffset, this._inferrer) {
    // Ensure the initializer of [_nullAwareVariable] is promoted to
    // non-nullable.
    _inferrer.flowAnalysis.nullAwareAccess_rightBegin(
        _nullAwareVariable.initializer, _nullAwareVariable.type);
    // Ensure [_nullAwareVariable] is promoted to non-nullable.
    // TODO(johnniwinther): Avoid creating a [VariableGet] to promote the
    // variable.
    VariableGet read = new VariableGet(_nullAwareVariable);
    _inferrer.flowAnalysis.variableRead(read, _nullAwareVariable);
    _inferrer.flowAnalysis
        .nullAwareAccess_rightBegin(read, _nullAwareVariable.type);
  }

  /// Creates the null-guarded application of [nullAwareAction] with the
  /// [inferredType].
  ///
  /// For an null-aware action `v.e` on the [_nullAwareVariable] `v` the created
  /// expression is
  ///
  ///     let v in v == null ? null : v.e
  ///
  Expression createExpression(
      DartType inferredType, Expression nullAwareAction) {
    // End non-nullable promotion of [_nullAwareVariable].
    _inferrer.flowAnalysis.nullAwareAccess_end();
    // End non-nullable promotion of the initializer of [_nullAwareVariable].
    _inferrer.flowAnalysis.nullAwareAccess_end();
    Expression equalsNull = _inferrer.createEqualsNull(
        _nullAwareFileOffset, createVariableGet(_nullAwareVariable));
    ConditionalExpression condition = new ConditionalExpression(
        equalsNull,
        new NullLiteral()..fileOffset = _nullAwareFileOffset,
        nullAwareAction,
        inferredType)
      ..fileOffset = _nullAwareFileOffset;
    return new Let(_nullAwareVariable, condition)
      ..fileOffset = _nullAwareFileOffset;
  }

  @override
  String toString() =>
      'NullAwareGuard($_nullAwareVariable,$_nullAwareFileOffset)';
}

/// The result of an expression inference that is guarded with a null aware
/// variable.
class NullAwareExpressionInferenceResult implements ExpressionInferenceResult {
  /// The inferred type of the expression.
  @override
  final DartType inferredType;

  /// The inferred type of the [nullAwareAction].
  @override
  final DartType nullAwareActionType;

  @override
  final Link<NullAwareGuard> nullAwareGuards;

  @override
  final Expression nullAwareAction;

  NullAwareExpressionInferenceResult(this.inferredType,
      this.nullAwareActionType, this.nullAwareGuards, this.nullAwareAction)
      : assert(nullAwareGuards.isNotEmpty);

  @override
  Expression get expression {
    throw new UnsupportedError('Shorting must be explicitly stopped before'
        'accessing the expression result of a '
        'NullAwareExpressionInferenceResult');
  }

  @override
  DartType? get postCoercionType => null;

  @override
  ExpressionInferenceResult stopShorting() {
    Expression expression = nullAwareAction;
    Link<NullAwareGuard> nullAwareGuard = nullAwareGuards;
    while (nullAwareGuard.isNotEmpty) {
      expression =
          nullAwareGuard.head.createExpression(inferredType, expression);
      nullAwareGuard = nullAwareGuard.tail!;
    }
    return new ExpressionInferenceResult(inferredType, expression);
  }

  @override
  String toString() =>
      'NullAwareExpressionInferenceResult($inferredType,$nullAwareGuards,'
      '$nullAwareAction)';
}
