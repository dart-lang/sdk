// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';
import 'package:kernel/ast.dart';

import '../base/compiler_context.dart';
import '../base/messages.dart';
import '../kernel/external_ast_helper.dart' as extern;
import '../kernel/inferred_collections.dart';
import '../source/check_helper.dart';
import 'element_inference.dart';
import 'inference_visitor_base.dart';
import 'type_schema.dart';

/// The result of a statement inference.
abstract class StatementInferenceResult {
  factory single(Statement statement) = SingleStatementInferenceResult;

  factory multiple(int fileOffset, List<Statement> statements) {
    if (statements.length == 1) {
      // Coverage-ignore-block(suite): Not run.
      return new SingleStatementInferenceResult(statements.single);
    } else {
      return new MultipleStatementInferenceResult(fileOffset, statements);
    }
  }

  Statement get statement;

  int get statementCount;

  List<Statement> get statements;
}

class SingleStatementInferenceResult implements StatementInferenceResult {
  @override
  final Statement statement;

  new(this.statement);

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

  new(this.fileOffset, this.statements)
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
  // Coverage-ignore(suite): Not run.
  Statement get statement {
    if (statements.length == 1) {
      return statements.single;
    } else {
      return extern.createBlock(statements, fileOffset: fileOffset);
    }
  }

  @override
  int get statementCount => statements.length;
}

sealed class VariableDeclarationInferenceResult {
  factory direct(VariableDeclaration declaration) =
      DirectVariableDeclarationInferenceResult;

  factory effect([Expression? expression]) =
      EffectVariableDeclarationInferenceResult;

  factory late(
    List<VariableDeclaration> variableDeclarations,
    List<FunctionDeclaration> functionDeclarations, {
    required int fileOffset,
  }) = LateVariableDeclarationInferenceResult;

  StatementInferenceResult toStatementInferenceResult({
    required int fileOffset,
  });
}

class DirectVariableDeclarationInferenceResult
    implements VariableDeclarationInferenceResult {
  final VariableDeclaration declaration;

  new(this.declaration);

  @override
  StatementInferenceResult toStatementInferenceResult({
    required int fileOffset,
  }) => new StatementInferenceResult.single(
    extern.createVariableStatement(declaration, fileOffset: fileOffset),
  );
}

class EffectVariableDeclarationInferenceResult
    implements VariableDeclarationInferenceResult {
  final Expression? expression;

  new([this.expression]);

  @override
  StatementInferenceResult toStatementInferenceResult({
    required int fileOffset,
  }) => new StatementInferenceResult.single(
    expression != null
        ? extern.createExpressionStatement(expression!, fileOffset: fileOffset)
        : extern.createEmptyStatement(fileOffset: fileOffset),
  );
}

class LateVariableDeclarationInferenceResult
    implements VariableDeclarationInferenceResult {
  final int fileOffset;
  final List<VariableDeclaration> variableDeclarations;
  final List<FunctionDeclaration> functionDeclarations;

  new(
    this.variableDeclarations,
    this.functionDeclarations, {
    required this.fileOffset,
  });

  @override
  StatementInferenceResult toStatementInferenceResult({
    required int fileOffset,
  }) => new StatementInferenceResult.multiple(fileOffset, [
    for (VariableDeclaration variableDeclaration in variableDeclarations)
      extern.createVariableStatement(variableDeclaration),
    ...functionDeclarations,
  ]);
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

  /// The flow analysis expression info for the invocation expression.
  ExpressionInfo? get expressionInfo;

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
    List<SyntheticVariable> hoistedExpressions,
  ) {
    if (hoistedExpressions.isNotEmpty) {
      for (int index = hoistedExpressions.length - 1; index >= 0; index--) {
        expression = extern.createLet(
          variable: hoistedExpressions[index],
          body: expression,
        );
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

  final List<SyntheticVariable>? hoistedArguments;

  @override
  final List<Expression> positional;

  @override
  final List<NamedExpression> named;

  @override
  final ExpressionInfo? expressionInfo;

  final DartType? inferredReceiverType;

  new({
    required this.inferredType,
    required this.functionType,
    required this.typeArguments,
    required this.positional,
    required this.named,
    required this.expressionInfo,
    required this.hoistedArguments,
    this.inferredReceiverType,
  });

  @override
  Expression applyResult(
    Expression expression, {
    DartType? extensionReceiverType,
  }) {
    List<SyntheticVariable>? hoistedArguments = this.hoistedArguments;
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
        if (!extern.isPureExpression(expression.receiver)) {
          SyntheticVariable receiver = extern.createVariable(
            expression.receiver,
            inferredReceiverType ?? const DynamicType(),
          );
          expression.receiver = extern.createVariableGet(receiver)
            ..parent = expression;
          return extern.createLet(
            variable: receiver,
            body: InvocationInferenceResult._insertHoistedExpressions(
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
          if (!extern.isPureExpression(receiver)) {
            SyntheticVariable receiverVariable = extern.createVariable(
              receiver,
              extensionReceiverType,
            );
            expression.arguments.positional.first = extern.createVariableGet(
              receiverVariable,
            )..parent = expression;
            return extern.createLet(
              variable: receiverVariable,
              body: InvocationInferenceResult._insertHoistedExpressions(
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

  final List<SyntheticVariable>? hoistedArguments;

  @override
  final List<Expression> positional;

  @override
  final List<NamedExpression> named;

  new({
    required this.message,
    required this.problemReporting,
    required this.compilerContext,
    required this.isInapplicable,
    required this.hoistedArguments,
    required this.positional,
    required this.named,
  });

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionInfo? get expressionInfo => null;

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
    expression = extern.createInvalidExpressionFromErrorText(
      problemReporting.buildProblemFromLocatedMessage(
        compilerContext: compilerContext,
        message: message,
      ),
      expression: expression,
    );
    List<SyntheticVariable>? hoistedArguments = this.hoistedArguments;
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

  factory fromInvocationInferenceResult(
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

  new(this.initializer);

  @override
  void addHoistedArguments(List<Initializer> initializers) {}
}

class SuccessfulInitializerInvocationInferenceResult
    implements InitializerInferenceResult {
  @override
  final Initializer initializer;

  final List<SyntheticVariable>? hoistedArguments;

  new({required this.initializer, required this.hoistedArguments});

  new fromSuccessfulInferenceResult(
    Initializer initializer,
    SuccessfulInferenceResult successfulInferenceResult,
  ) : this(
        initializer: initializer,
        hoistedArguments: successfulInferenceResult.hoistedArguments,
      );

  @override
  void addHoistedArguments(List<Initializer> initializers) {
    List<SyntheticVariable>? hoistedArguments = this.hoistedArguments;
    if (hoistedArguments != null && hoistedArguments.isNotEmpty) {
      for (SyntheticVariable hoistedArgument in hoistedArguments) {
        initializers.add(
          extern.createLocalInitializer(
            variable: hoistedArgument,
            fileOffset: hoistedArgument.fileOffset,
          ),
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

  new fromWrapInProblemInferenceResult(
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

  new(this.expressionInferenceResult, this.member);

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

  new(this.inferredType, this.expression, {this.postCoercionType = null})
    : assert(isKnown(inferredType), "$inferredType is not known.");

  @override
  String toString() => 'ExpressionInferenceResult($inferredType,$expression)';
}

/// The result of inference of an [InternalElement].
class ElementInferenceResult({
  /// The inferred type of the element.
  required final ElementType inferredType,

  /// The inferred expression.
  required final InferredElement element,
});

/// A guard used for creating null-shorting null-aware actions.
class NullAwareGuard {
  /// The variable used to guard the null-aware action.
  final SyntheticVariable _nullAwareVariable;

  final Expression? _nullableExpression;

  /// The file offset used for the null-test.
  int _nullAwareFileOffset;

  new(
    this._nullAwareVariable,
    this._nullAwareFileOffset, {
    this._nullableExpression,
  });

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
    Expression equalsNull = extern.createEqualsNull(
      extern.createVariableGet(_nullAwareVariable),
      fileOffset: _nullAwareFileOffset,
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
        ? extern.createNullLiteral(fileOffset: TreeNode.noOffset)
        : extern.createVariableGet(_nullAwareVariable);
    typeSafeIfNullBranch.fileOffset = _nullAwareFileOffset;

    ConditionalExpression condition = extern.createConditionalExpression(
      equalsNull,
      typeSafeIfNullBranch,
      nullAwareAction,
      staticType: inferredType,
      fileOffset: _nullAwareFileOffset,
    );
    return extern.createLet(
      variable: _nullAwareVariable,
      value: _nullableExpression,
      body: condition,
      fileOffset: _nullAwareFileOffset,
    );
  }

  @override
  String toString() =>
      'NullAwareGuard($_nullAwareVariable,$_nullAwareFileOffset)';
}
