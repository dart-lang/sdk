// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import '../base/compiler_context.dart';
import '../base/messages.dart';
import '../kernel/internal_ast.dart';
import '../source/check_helper.dart';
import 'external_ast_helper.dart';
import 'inference_visitor_base.dart';
import 'type_schema.dart';

/// The result of a statement inference.
class StatementInferenceResult {
  const StatementInferenceResult();

  factory StatementInferenceResult.single(Statement statement) =
      SingleStatementInferenceResult;

  factory StatementInferenceResult.multiple(
    int fileOffset,
    List<Statement> statements,
  ) {
    if (statements.length == 0) {
      return const StatementInferenceResult();
    } else if (statements.length == 1) {
      // Coverage-ignore-block(suite): Not run.
      return new SingleStatementInferenceResult(statements.single);
    } else {
      return new MultipleStatementInferenceResult(fileOffset, statements);
    }
  }

  bool get hasChanged => false;

  // Coverage-ignore(suite): Not run.
  Statement get statement =>
      throw new UnsupportedError('StatementInferenceResult.statement');

  // Coverage-ignore(suite): Not run.
  int get statementCount =>
      throw new UnsupportedError('StatementInferenceResult.statementCount');

  // Coverage-ignore(suite): Not run.
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
  // Coverage-ignore(suite): Not run.
  List<Statement> get statements =>
      throw new UnsupportedError('SingleStatementInferenceResult.statements');
}

class MultipleStatementInferenceResult implements StatementInferenceResult {
  final int fileOffset;
  @override
  final List<Statement> statements;

  MultipleStatementInferenceResult(this.fileOffset, this.statements)
    : assert(
        statements.isNotEmpty,
        "The multi-statement result shouldn't be empty.",
      ),
      assert(
        statements.length != 1,
        "For the results containing a single statement,"
        "use SingleStatementInferenceResult.",
      );

  @override
  bool get hasChanged => true;

  @override
  // Coverage-ignore(suite): Not run.
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

  /// The explicit or inferred type arguments.
  List<DartType> get typeArguments;

  /// The positional arguments.
  List<Expression> get positional;

  /// The named arguments.
  List<NamedExpression> get named;

  /// Applies the result of the inference to the expression being inferred.
  ///
  /// A successful result leaves [expression] intact, and an error detected
  /// during inference would wrap the expression into an [InvalidExpression].
  ///
  /// If the [expression] is an invocation of an extension instance method or
  /// an extension type instance method, then [extensionReceiverType] must be
  /// provided to support hoisting the receiver, if necessary.
  Expression applyResult(
    Expression expression, {
    DartType? extensionReceiverType,
  });

  /// Returns `true` if the arguments of the call where not applicable to the
  /// target.
  bool get isInapplicable;

  static Expression _insertHoistedExpressions(
    Expression expression,
    List<VariableDeclaration> hoistedExpressions,
  ) {
    if (hoistedExpressions.isNotEmpty) {
      for (int index = hoistedExpressions.length - 1; index >= 0; index--) {
        expression = createLet(hoistedExpressions[index], expression);
      }
    }
    return expression;
  }

  /// Creates the [InitializerResult] corresponding to this
  /// [InvocationInferenceResult] for the given [initializer].
  InitializerInferenceResult toInitializerResult(Initializer initializer);
}

class SuccessfulInferenceResult implements InvocationInferenceResult {
  @override
  final DartType inferredType;

  @override
  final FunctionType functionType;

  @override
  final List<DartType> typeArguments;

  final List<VariableDeclaration>? hoistedArguments;

  @override
  final List<Expression> positional;

  @override
  final List<NamedExpression> named;

  final DartType? inferredReceiverType;

  SuccessfulInferenceResult({
    required this.inferredType,
    required this.functionType,
    required this.typeArguments,
    required this.positional,
    required this.named,
    required this.hoistedArguments,
    this.inferredReceiverType,
  });

  @override
  Expression applyResult(
    Expression expression, {
    DartType? extensionReceiverType,
  }) {
    List<VariableDeclaration>? hoistedArguments = this.hoistedArguments;
    if (hoistedArguments == null || hoistedArguments.isEmpty) {
      return expression;
    } else if (expression is RedirectingFactoryInvocation) {
      return InvocationInferenceResult._insertHoistedExpressions(
        expression,
        hoistedArguments,
      );
    } else {
      assert(
        expression is InvocationExpression || expression is InvalidExpression,
      );
      if (expression is ConstructorInvocation) {
        return InvocationInferenceResult._insertHoistedExpressions(
          expression,
          hoistedArguments,
        );
      } else if (expression is DynamicInvocation) {
        return InvocationInferenceResult._insertHoistedExpressions(
          expression,
          hoistedArguments,
        );
      } else if (expression is FunctionInvocation) {
        return InvocationInferenceResult._insertHoistedExpressions(
          expression,
          hoistedArguments,
        );
      } else if (expression is InstanceGetterInvocation) {
        // The hoisting of InstanceGetterInvocation is performed elsewhere.
        return expression;
      } else if (expression is InstanceInvocation) {
        if (!isPureExpression(expression.receiver)) {
          VariableDeclaration receiver = createVariable(
            expression.receiver,
            inferredReceiverType ?? const DynamicType(),
          );
          expression.receiver = createVariableGet(receiver)
            ..parent = expression;
          return createLet(
            receiver,
            InvocationInferenceResult._insertHoistedExpressions(
              expression,
              hoistedArguments,
            ),
          );
        } else {
          return InvocationInferenceResult._insertHoistedExpressions(
            expression,
            hoistedArguments,
          );
        }
      } else if (expression is LocalFunctionInvocation) {
        return InvocationInferenceResult._insertHoistedExpressions(
          expression,
          hoistedArguments,
        );
      } else if (expression is StaticInvocation) {
        if (extensionReceiverType != null) {
          Expression receiver = expression.arguments.positional.first;
          if (!isPureExpression(receiver)) {
            VariableDeclaration receiverVariable = createVariable(
              receiver,
              extensionReceiverType,
            );
            expression.arguments.positional.first = createVariableGet(
              receiverVariable,
            )..parent = expression;
            return createLet(
              receiverVariable,
              InvocationInferenceResult._insertHoistedExpressions(
                expression,
                hoistedArguments,
              ),
            );
          }
        }
        return InvocationInferenceResult._insertHoistedExpressions(
          expression,
          hoistedArguments,
        );
      } else if (expression is SuperMethodInvocation) {
        return InvocationInferenceResult._insertHoistedExpressions(
          expression,
          hoistedArguments,
        );
      } else if (expression is InvalidExpression) {
        return InvocationInferenceResult._insertHoistedExpressions(
          expression,
          hoistedArguments,
        );
      } else {
        throw new StateError(
          "Unhandled invocation kind '${expression.runtimeType}'.",
        );
      }
    }
  }

  @override
  bool get isInapplicable => false;

  @override
  InitializerInferenceResult toInitializerResult(Initializer initializer) {
    return new // force line break
    SuccessfulInitializerInvocationInferenceResult // force line break
    .fromSuccessfulInferenceResult(initializer, this);
  }
}

class WrapInProblemInferenceResult implements InvocationInferenceResult {
  final LocatedMessage message;

  final ProblemReporting problemReporting;

  final CompilerContext compilerContext;

  @override
  final bool isInapplicable;

  final List<VariableDeclaration>? hoistedArguments;

  @override
  final List<Expression> positional;

  @override
  final List<NamedExpression> named;

  WrapInProblemInferenceResult({
    required this.message,
    required this.problemReporting,
    required this.compilerContext,
    required this.isInapplicable,
    required this.hoistedArguments,
    required this.positional,
    required this.named,
  });

  @override
  DartType get inferredType => const InvalidType();

  @override
  DartType get functionType => const InvalidType();

  @override
  List<DartType> get typeArguments => [];

  @override
  Expression applyResult(
    Expression expression, {
    DartType? extensionReceiverType,
  }) {
    expression = problemReporting.wrapInLocatedProblem(
      compilerContext: compilerContext,
      expression: expression,
      message: message,
    );
    List<VariableDeclaration>? hoistedArguments = this.hoistedArguments;
    if (hoistedArguments == null || hoistedArguments.isEmpty) {
      return expression;
    } else {
      return InvocationInferenceResult._insertHoistedExpressions(
        expression,
        hoistedArguments,
      );
    }
  }

  @override
  InitializerInferenceResult toInitializerResult(Initializer initializer) {
    return new // force line break
    WrapInProblemInitializerInferenceResult.fromWrapInProblemInferenceResult(
      initializer,
      this,
    );
  }
}

abstract class InitializerInferenceResult {
  /// The inferred initializer.
  Initializer get initializer;

  /// Adds any hoisted arguments for [initializer] to [initializers] as
  /// [LocalInitializer]s.
  void addHoistedArguments(List<Initializer> initializers);

  factory InitializerInferenceResult.fromInvocationInferenceResult(
    Initializer initializer,
    InvocationInferenceResult invocationInferenceResult,
  ) {
    return invocationInferenceResult.toInitializerResult(initializer);
  }
}

class SuccessfulInitializerInferenceResult
    implements InitializerInferenceResult {
  @override
  final Initializer initializer;

  SuccessfulInitializerInferenceResult(this.initializer);

  @override
  void addHoistedArguments(List<Initializer> initializers) {}
}

class SuccessfulInitializerInvocationInferenceResult
    implements InitializerInferenceResult {
  @override
  final Initializer initializer;

  final List<VariableDeclaration>? hoistedArguments;

  SuccessfulInitializerInvocationInferenceResult({
    required this.initializer,
    required this.hoistedArguments,
  });

  SuccessfulInitializerInvocationInferenceResult.fromSuccessfulInferenceResult(
    Initializer initializer,
    SuccessfulInferenceResult successfulInferenceResult,
  ) : this(
        initializer: initializer,
        hoistedArguments: successfulInferenceResult.hoistedArguments,
      );

  @override
  void addHoistedArguments(List<Initializer> initializers) {
    List<VariableDeclaration>? hoistedArguments = this.hoistedArguments;
    if (hoistedArguments != null && hoistedArguments.isNotEmpty) {
      for (VariableDeclaration hoistedArgument in hoistedArguments) {
        initializers.add(
          new LocalInitializer(hoistedArgument)
            ..fileOffset = hoistedArgument.fileOffset,
        );
      }
    }
  }
}

class WrapInProblemInitializerInferenceResult
    implements InitializerInferenceResult {
  @override
  final Initializer initializer;
  final WrapInProblemInferenceResult wrapInProblemInferenceResult;

  WrapInProblemInitializerInferenceResult.fromWrapInProblemInferenceResult(
    this.initializer,
    this.wrapInProblemInferenceResult,
  );

  @override
  void addHoistedArguments(List<Initializer> initializers) {}
}

/// The result of inference of a property get expression.
class PropertyGetInferenceResult {
  /// The main inference result.
  final ExpressionInferenceResult expressionInferenceResult;

  /// The property that was looked up, or `null` if no property was found.
  // TODO(johnniwinther): This doesn't seem to be used anymore. Remove this
  // class in favor of using [ExpressionInferenceResult]?
  final Member? member;

  PropertyGetInferenceResult(this.expressionInferenceResult, this.member);

  @override
  String toString() {
    return "PropertyGetInferenceResult("
        "expressionInferenceResult=${expressionInferenceResult}, "
        "member=${member})";
  }
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

  ExpressionInferenceResult(
    this.inferredType,
    this.expression, {
    this.postCoercionType = null,
  }) : assert(isKnown(inferredType), "$inferredType is not known.");

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
    this._nullAwareVariable,
    this._nullAwareFileOffset,
    this._inferrer,
  );

  /// Creates the null-guarded application of [nullAwareAction] with the
  /// [inferredType].
  ///
  /// For an null-aware action `v.e` on the [_nullAwareVariable] `v` the created
  /// expression is
  ///
  ///     let v in v == null ? null : v.e
  ///
  Expression createExpression(
    DartType inferredType,
    Expression nullAwareAction,
  ) {
    Expression equalsNull = _inferrer.createEqualsNull(
      _nullAwareFileOffset,
      createVariableGet(_nullAwareVariable),
    );

    // In case null guards are applied to non-nullable receivers, we still
    // generate a null-testing conditional expression; although, it is
    // unnecessary. Moreover, those expressions appear to be not null safe,
    // since their static type is not nullable, and one of their branches is the
    // `null` literal. The following is an example of such lowering for the
    // expression `s?..length`, where `s` is of static type `String`.
    //
    //     let final core::String #t1 = s in #t1 == null ?{core::String}
    //         null :
    //         block { #t1.{core::String::length}{core::int}; } =>#t1
    //
    // Note the static type of the condition expression being the non-nullable
    // `core::String`, and the then-branch being `null`. In such cases, we
    // implement the following workaround: replace the `null` literal with the
    // expression tested for being `null`. With the workaround in place, the
    // expression `s?..length` is lowered as follows:
    //
    //     let final core::String #t1 = s in #t1 == null ?{core::String}
    //         #t1 :
    //         block { #t1.{core::String::length}{core::int}; } =>#t1
    //
    // This achieves the following:
    //
    //   * The conditional expression becomes type-safe.
    //   * Semantically the tested expression and the null literal evaluate to
    //     the same result, to the `null` value, so the runtime properties of
    //     the code don't change.
    //   * In practice, the `null` literal is dead code for non-nullable
    //     receivers anyway, so the altered part of the expression won't ever be
    //     executed.
    //
    // TODO(johnniwinther,cstefantsova): Don't generate null-testing expressions
    // for non-nullable receivers in cascades.
    Expression typeSafeIfNullBranch =
        inferredType.nullability == Nullability.nullable
        ? new NullLiteral()
        : createVariableGet(_nullAwareVariable);
    typeSafeIfNullBranch.fileOffset = _nullAwareFileOffset;

    ConditionalExpression condition = new ConditionalExpression(
      equalsNull,
      typeSafeIfNullBranch,
      nullAwareAction,
      inferredType,
    )..fileOffset = _nullAwareFileOffset;
    return new Let(_nullAwareVariable, condition)
      ..fileOffset = _nullAwareFileOffset;
  }

  @override
  String toString() =>
      'NullAwareGuard($_nullAwareVariable,$_nullAwareFileOffset)';
}
