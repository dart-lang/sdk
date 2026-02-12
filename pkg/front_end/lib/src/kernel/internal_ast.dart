// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This file declares a "shadow hierarchy" of concrete classes which extend
/// the kernel class hierarchy, adding methods and fields needed by the
/// BodyBuilder.
///
/// Instances of these classes may be created using the factory methods in
/// `ast_factory.dart`.
///
/// Note that these classes represent the Dart language prior to desugaring.
/// When a single Dart construct desugars to a tree containing multiple kernel
/// AST nodes, the shadow class extends the kernel object at the top of the
/// desugared tree.
///
/// This means that in some cases multiple shadow classes may extend the same
/// kernel class, because multiple constructs in Dart may desugar to a tree
/// with the same kind of root node.
library;

import 'package:_fe_analyzer_shared/src/type_inference/type_analysis_result.dart'
    as shared;
import 'package:kernel/ast.dart';
import 'package:kernel/names.dart';
import 'package:kernel/src/printer.dart';
import 'package:kernel/text/ast_to_text.dart' show Precedence;
import 'package:kernel/type_environment.dart';

import '../base/problems.dart' show unsupported;
import '../builder/declaration_builders.dart';
import '../type_inference/inference_results.dart';
import '../type_inference/inference_visitor.dart';

typedef SharedMatchContext =
    shared.MatchContext<TreeNode, Expression, Pattern, ExpressionVariable>;

mixin InternalTreeNode implements TreeNode {
  @override
  // Coverage-ignore(suite): Not run.
  void replaceChild(TreeNode child, TreeNode replacement) {
    // Do nothing. The node should not be part of the resulting AST, anyway.
  }

  @override
  // Coverage-ignore(suite): Not run.
  void transformChildren(Transformer v) {
    unsupported(
      "${runtimeType}.transformChildren on ${v.runtimeType}",
      -1,
      null,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  void transformOrRemoveChildren(RemovingTransformer v) {
    unsupported(
      "${runtimeType}.transformOrRemoveChildren on ${v.runtimeType}",
      -1,
      null,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  void visitChildren(Visitor v) {
    unsupported("${runtimeType}.visitChildren on ${v.runtimeType}", -1, null);
  }
}

// Coverage-ignore(suite): Not run.
/// Common base class for internal statements.
abstract class InternalStatement extends AuxiliaryStatement {
  @override
  void replaceChild(TreeNode child, TreeNode replacement) {
    // Do nothing. The node should not be part of the resulting AST, anyway.
  }

  @override
  void transformChildren(Transformer v) => unsupported(
    "${runtimeType}.transformChildren on ${v.runtimeType}",
    -1,
    null,
  );

  @override
  void transformOrRemoveChildren(RemovingTransformer v) => unsupported(
    "${runtimeType}.transformOrRemoveChildren on ${v.runtimeType}",
    -1,
    null,
  );

  @override
  void visitChildren(Visitor v) =>
      unsupported("${runtimeType}.visitChildren on ${v.runtimeType}", -1, null);

  StatementInferenceResult acceptInference(InferenceVisitorImpl visitor);
}

class ForInStatementWithSynthesizedVariable extends InternalStatement {
  ExpressionVariable? variable;
  Expression iterable;
  Expression? syntheticAssignment;
  Statement? expressionEffects;
  Statement body;
  final bool isAsync;
  final bool hasProblem;
  int bodyOffset = TreeNode.noOffset;

  ForInStatementWithSynthesizedVariable(
    this.variable,
    this.iterable,
    this.syntheticAssignment,
    this.expressionEffects,
    this.body, {
    required this.isAsync,
    required this.hasProblem,
  }) {
    variable?.parent = this;
    iterable.parent = this;
    syntheticAssignment?.parent = this;
    expressionEffects?.parent = this;
    body.parent = this;
  }

  @override
  StatementInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitForInStatementWithSynthesizedVariable(this);
  }

  @override
  String toString() {
    return "ForInStatementWithSynthesizedVariable(${toStringInternal()})";
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter state) {
    // TODO(johnniwinther): Implement this.
  }
}

class TryStatement extends InternalStatement {
  Statement tryBlock;
  List<Catch> catchBlocks;
  Statement? finallyBlock;

  TryStatement(this.tryBlock, this.catchBlocks, this.finallyBlock) {
    tryBlock.parent = this;
    setParents(catchBlocks, this);
    finallyBlock?.parent = this;
  }

  @override
  StatementInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitTryStatement(this);
  }

  @override
  String toString() {
    return "TryStatement(${toStringInternal()})";
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('try ');
    printer.writeStatement(tryBlock);
    for (Catch catchBlock in catchBlocks) {
      printer.write(' ');
      printer.writeCatch(catchBlock);
    }
    if (finallyBlock != null) {
      printer.write(' finally ');
      printer.writeStatement(finallyBlock!);
    }
  }
}

class SwitchCaseImpl extends SwitchCase {
  final List<int> caseOffsets;
  final bool hasLabel;

  SwitchCaseImpl(
    this.caseOffsets,
    List<Expression> expressions,
    List<int> expressionOffsets,
    Statement body, {
    bool isDefault = false,
    required this.hasLabel,
  }) : super(expressions, expressionOffsets, body, isDefault: isDefault);

  @override
  String toString() {
    return "SwitchCaseImpl(${toStringInternal()})";
  }
}

class BreakStatementImpl extends BreakStatement {
  Statement? targetStatement;
  final bool isContinue;

  BreakStatementImpl({required this.isContinue}) : super(dummyLabeledStatement);

  @override
  String toString() {
    return "BreakStatementImpl(${toStringInternal()})";
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (isContinue) {
      printer.write('continue ');
    } else {
      printer.write('break ');
    }
    printer.write(printer.getLabelName(target));
    printer.write(';');
  }
}

// Coverage-ignore(suite): Not run.
/// Common base class for internal expressions.
abstract class InternalExpression extends AuxiliaryExpression {
  @override
  void replaceChild(TreeNode child, TreeNode replacement) {
    // Do nothing. The node should not be part of the resulting AST, anyway.
  }

  @override
  DartType getStaticType(StaticTypeContext context) =>
      unsupported("${runtimeType}.getStaticType", -1, null);

  @override
  DartType getStaticTypeInternal(StaticTypeContext context) =>
      unsupported("${runtimeType}.getStaticType", -1, null);

  @override
  void visitChildren(Visitor<dynamic> v) =>
      unsupported("${runtimeType}.visitChildren", -1, null);

  @override
  void transformChildren(Transformer v) =>
      unsupported("${runtimeType}.transformChildren", -1, null);

  @override
  void transformOrRemoveChildren(RemovingTransformer v) =>
      unsupported("${runtimeType}.transformOrRemoveChildren", -1, null);

  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  );
}

// Coverage-ignore(suite): Not run.
/// Common base class for internal initializers.
sealed class InternalInitializer extends AuxiliaryInitializer {
  @override
  void visitChildren(Visitor<dynamic> v) =>
      unsupported("${runtimeType}.visitChildren", -1, null);

  @override
  void transformChildren(Transformer v) =>
      unsupported("${runtimeType}.transformChildren", -1, null);

  @override
  void transformOrRemoveChildren(RemovingTransformer v) =>
      unsupported("${runtimeType}.transformOrRemoveChildren", -1, null);

  InitializerInferenceResult acceptInference(InferenceVisitorImpl visitor);
}

// TODO(johnniwinther): Add offsets. Maybe add `isExplicit` property, since this
// is currently used to pass converted/computed type arguments for type alias
// constructor invocation.
class TypeArguments {
  final List<DartType> types;

  TypeArguments(this.types);

  // Coverage-ignore(suite): Not run.
  void toText(AstPrinter printer) {
    printer.writeTypeArguments(types);
  }
}

sealed class Argument {
  TreeNode get node;

  abstract Expression expression;

  bool get isSuperParameter => false;

  void toTextInternal(AstPrinter printer);
}

class PositionalArgument extends Argument {
  @override
  Expression expression;

  PositionalArgument(this.expression);

  @override
  // Coverage-ignore(suite): Not run.
  TreeNode get node => expression;

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    expression.toTextInternal(printer);
  }

  @override
  String toString() => 'PositionalArgument($expression)';
}

class SuperPositionalArgument extends PositionalArgument {
  SuperPositionalArgument(super.expression);

  @override
  bool get isSuperParameter => true;
}

class NamedArgument extends Argument {
  NamedExpression namedExpression;

  NamedArgument(this.namedExpression);

  @override
  // Coverage-ignore(suite): Not run.
  TreeNode get node => namedExpression;

  String get name => namedExpression.name;

  @override
  Expression get expression => namedExpression.value;

  @override
  void set expression(Expression value) {
    namedExpression.value = value..parent = namedExpression;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    namedExpression.toTextInternal(printer);
  }

  @override
  String toString() => 'NamedArgument($namedExpression)';
}

class SuperNamedArgument extends NamedArgument {
  SuperNamedArgument(super.expression);

  @override
  bool get isSuperParameter => true;
}

/// Front end specific implementation of [Argument].
class ActualArguments extends TreeNode with InternalTreeNode {
  final List<Argument> argumentList;

  bool _hasNamedBeforePositional;
  int _positionalCount;

  ActualArguments({
    required this.argumentList,
    required bool hasNamedBeforePositional,
    required int positionalCount,
  }) : _hasNamedBeforePositional = hasNamedBeforePositional,
       _positionalCount = positionalCount;

  // Coverage-ignore(suite): Not run.
  ActualArguments.empty()
    : this.argumentList = [],
      this._hasNamedBeforePositional = false,
      this._positionalCount = 0;

  int get positionalCount => _positionalCount;

  int get namedCount => argumentList.length - positionalCount;

  bool get hasNamedBeforePositional => _hasNamedBeforePositional;

  void prependArguments(List<Argument> list, {required int positionalCount}) {
    assert(list.whereType<PositionalArgument>().length == positionalCount);
    argumentList.insertAll(0, list);
    if (!_hasNamedBeforePositional &&
        _positionalCount > 0 &&
        positionalCount < list.length) {
      _hasNamedBeforePositional = true;
    }
    _positionalCount += positionalCount;
  }

  Arguments toArguments(
    List<DartType> typeArguments,
    List<Expression> positionalArguments,
    List<NamedExpression> namedArguments,
  ) {
    return new Arguments(
      positionalArguments,
      types: typeArguments,
      named: namedArguments,
    )..fileOffset = fileOffset;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('(');
    for (int index = 0; index < argumentList.length; index++) {
      if (index > 0) {
        printer.write(', ');
      }
      argumentList[index].toTextInternal(printer);
    }
    printer.write(')');
  }

  @override
  String toString() {
    return "ArgumentsImpl(${toStringInternal()})";
  }

  @override
  R accept<R>(TreeVisitor<R> v) {
    throw new UnimplementedError('${runtimeType}.accept');
  }

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) {
    throw new UnimplementedError('${runtimeType}.accept1');
  }
}

/// Internal expression representing a cascade expression.
///
/// A cascade expression of the form `a..b()..c()` is represented as the kernel
/// expression:
///
///     let v = a in
///         let _ = v.b() in
///             let _ = v.c() in
///                 v
///
/// In the documentation that follows, `v` is referred to as the "cascade
/// variable"--this is the variable that remembers the value of the expression
/// preceding the first `..` while the cascades are being evaluated.
class Cascade extends InternalExpression {
  /// The temporary variable holding the cascade receiver expression in its
  /// initializer;
  VariableDeclaration variable;

  /// `true` if the access is null-aware, i.e. of the form `a?..b()`.
  final bool isNullAware;

  /// The expressions performed on [variable].
  final List<Expression> expressions = <Expression>[];

  /// Creates a [Cascade] using [variable] as the cascade
  /// variable.  Caller is responsible for ensuring that [variable]'s
  /// initializer is the expression preceding the first `..` of the cascade
  /// expression.
  Cascade(this.variable, {required this.isNullAware}) {
    variable.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitCascade(this, typeContext);
  }

  /// Adds [expression] to the list of [expressions] performed on [variable].
  void addCascadeExpression(Expression expression) {
    expressions.add(expression);
    expression.parent = this;
  }

  @override
  String toString() {
    return "Cascade(${toStringInternal()})";
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('let ');
    printer.writeVariableInitialization(variable);
    printer.write(' in cascade {');
    printer.incIndentation();
    for (Expression expression in expressions) {
      printer.newLine();
      printer.writeExpression(expression);
      printer.write(';');
    }
    printer.decIndentation();
    if (expressions.isNotEmpty) {
      printer.newLine();
    }
    printer.write('} => ');
    printer.write(printer.getVariableName(variable));
  }
}

/// Internal expression representing a deferred check.
// TODO(johnniwinther): Change the representation to be direct and perform
// the [Let] encoding in the replacement.
class DeferredCheck extends InternalExpression {
  VariableDeclaration variable;
  Expression expression;

  DeferredCheck(this.variable, this.expression) {
    variable.parent = this;
    expression.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitDeferredCheck(this, typeContext);
  }

  @override
  String toString() {
    return "DeferredCheck(${toStringInternal()})";
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('let ');
    printer.writeVariableInitialization(variable);
    printer.write(' in ');
    printer.writeExpression(expression);
  }
}

/// Common base class for shadow objects representing expressions in kernel
/// form.
abstract class ExpressionJudgment extends AuxiliaryExpression {
  /// Calls back to [inferrer] to perform type inference for whatever concrete
  /// type of [Expression] this is.
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  );
}

/// Internal expression for an invocation of a factory constructor.
class FactoryConstructorInvocation extends InternalExpression {
  bool hasBeenInferred = false;
  final Procedure target;
  final TypeArguments? typeArguments;
  ActualArguments arguments;

  /// If `true`, this invocation is constant, either explicit or inferred.
  final bool isConst;

  FactoryConstructorInvocation(
    this.target,
    this.typeArguments,
    this.arguments, {
    required this.isConst,
  }) {
    arguments.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitFactoryConstructorInvocation(this, typeContext);
  }

  @override
  String toString() {
    return "FactoryConstructorInvocation(${toStringInternal()})";
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (isConst) {
      printer.write('const ');
    } else {
      printer.write('new ');
    }
    printer.writeClassName(target.enclosingClass?.reference);
    typeArguments?.toText(printer);
    if (target.name.text.isNotEmpty) {
      printer.write('.');
      printer.write(target.name.text);
    }
    arguments.toTextInternal(printer);
  }
}

/// Internal expression for an invocation of a type aliased constructor.
class TypeAliasedConstructorInvocation extends InternalExpression {
  bool hasBeenInferred = false;
  final TypeAliasBuilder typeAliasBuilder;
  final Constructor target;
  final TypeArguments? typeArguments;
  ActualArguments arguments;
  final bool isConst;

  TypeAliasedConstructorInvocation(
    this.typeAliasBuilder,
    this.target,
    this.typeArguments,
    this.arguments, {
    this.isConst = false,
  }) {
    arguments.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitTypeAliasedConstructorInvocation(this, typeContext);
  }

  @override
  String toString() {
    return "TypeAliasedConstructorInvocation(${toStringInternal()})";
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (isConst) {
      printer.write('const ');
    } else {
      printer.write('new ');
    }
    printer.writeTypedefName(typeAliasBuilder.typedef.reference);
    typeArguments?.toText(printer);
    if (target.name.text.isNotEmpty) {
      printer.write('.');
      printer.write(target.name.text);
    }
    arguments.toTextInternal(printer);
  }
}

/// Internal expression for an invocation of a type aliased factory constructor.
class TypeAliasedFactoryInvocation extends InternalExpression {
  bool hasBeenInferred = false;
  final TypeAliasBuilder typeAliasBuilder;
  final Procedure target;
  final TypeArguments? typeArguments;
  ActualArguments arguments;

  /// If `true`, this invocation is constant, either explicit or inferred.
  final bool isConst;

  TypeAliasedFactoryInvocation(
    this.typeAliasBuilder,
    this.target,
    this.typeArguments,
    this.arguments, {
    required this.isConst,
  }) {
    arguments.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitTypeAliasedFactoryInvocation(this, typeContext);
  }

  @override
  String toString() {
    return "TypeAliasedFactoryInvocation(${toStringInternal()})";
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (isConst) {
      printer.write('const ');
    } else {
      printer.write('new ');
    }
    printer.writeTypedefName(typeAliasBuilder.typedef.reference);
    typeArguments?.toText(printer);
    if (target.name.text.isNotEmpty) {
      printer.write('.');
      printer.write(target.name.text);
    }
    arguments.toTextInternal(printer);
  }
}

/// Front end specific implementation of [FunctionDeclaration].
class FunctionDeclarationImpl extends FunctionDeclaration {
  bool hasImplicitReturnType = false;

  FunctionDeclarationImpl(VariableDeclaration variable, FunctionNode function)
    : super(variable, function);

  static void setHasImplicitReturnType(
    FunctionDeclarationImpl declaration,
    bool hasImplicitReturnType,
  ) {
    declaration.hasImplicitReturnType = hasImplicitReturnType;
  }

  @override
  String toString() {
    return "FunctionDeclarationImpl(${toStringInternal()})";
  }
}

/// Internal expression representing an if-null expression.
///
/// An if-null expression of the form `a ?? b` is encoded as:
///
///     let v = a in v == null ? b : v
///
class IfNullExpression extends InternalExpression {
  Expression left;
  Expression right;

  IfNullExpression(this.left, this.right) {
    left.parent = this;
    right.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitIfNullExpression(this, typeContext);
  }

  @override
  String toString() {
    return "IfNullExpression(${toStringInternal()})";
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(left, minimumPrecedence: Precedence.CONDITIONAL);
    printer.write(' ?? ');
    printer.writeExpression(
      right,
      minimumPrecedence: Precedence.CONDITIONAL + 1,
    );
  }
}

/// Concrete shadow object representing an integer literal in kernel form.
class IntJudgment extends IntLiteral implements ExpressionJudgment {
  /// The literal text of the number, as it appears in the source, which may
  /// include digit separators (and may not be safe for parsing with
  /// `int.parse`).
  final String? literal;

  IntJudgment(int value, this.literal) : super(value);

  double? asDouble({bool negated = false}) {
    if (value == 0 && negated) {
      return -0.0;
    }
    BigInt intValue = new BigInt.from(negated ? -value : value);
    double doubleValue = intValue.toDouble();
    return intValue == new BigInt.from(doubleValue) ? doubleValue : null;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitIntJudgment(this, typeContext);
  }

  @override
  String toString() {
    return "IntJudgment(${toStringInternal()})";
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (literal == null) {
      printer.write('$value');
    } else {
      printer.write(literal!);
    }
  }
}

class ShadowLargeIntLiteral extends IntLiteral implements ExpressionJudgment {
  /// The parsable String source, stripped of any digit separators.
  final String _strippedLiteral;

  /// The original textual source, possibly with digit separators.
  final String literal;
  @override
  final int fileOffset;
  bool isParenthesized = false;

  ShadowLargeIntLiteral(this._strippedLiteral, this.literal, this.fileOffset)
    : super(0);

  double? asDouble({bool negated = false}) {
    BigInt? intValue = BigInt.tryParse(
      negated ? '-${_strippedLiteral}' : _strippedLiteral,
    );
    if (intValue == null) {
      return null;
    }
    double doubleValue = intValue.toDouble();
    return !doubleValue.isNaN &&
            !doubleValue.isInfinite &&
            intValue == new BigInt.from(doubleValue)
        ? doubleValue
        : null;
  }

  int? asInt64({bool negated = false}) {
    return int.tryParse(negated ? '-${_strippedLiteral}' : _strippedLiteral);
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitShadowLargeIntLiteral(this, typeContext);
  }

  @override
  String toString() {
    return "ShadowLargeIntLiteral(${toStringInternal()})";
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write(literal);
  }
}

class ExpressionInvocation extends InternalExpression {
  Expression expression;
  final TypeArguments? typeArguments;
  ActualArguments arguments;

  ExpressionInvocation(this.expression, this.typeArguments, this.arguments) {
    expression.parent = this;
    arguments.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitExpressionInvocation(this, typeContext);
  }

  @override
  String toString() {
    return "ExpressionInvocation(${toStringInternal()})";
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(expression);
    typeArguments?.toText(printer);
    arguments.toTextInternal(printer);
  }
}

/// Front end specific implementation of [ReturnStatement].
class ReturnStatementImpl extends ReturnStatement {
  final bool isArrow;

  ReturnStatementImpl(this.isArrow, [Expression? expression])
    : super(expression);

  @override
  String toString() {
    return "ReturnStatementImpl(${toStringInternal()})";
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (isArrow) {
      printer.write('=>');
    } else {
      printer.write('return');
    }
    if (expression != null) {
      printer.write(' ');
      printer.writeExpression(expression!);
    }
    printer.write(';');
  }
}

/// Front end specific implementation of [VariableDeclaration].
class VariableDeclarationImpl extends VariableStatement
    with InternalExpressionVariableMixin
    implements InternalExpressionVariable {
  @override
  ExpressionVariable get astVariable => this;

  @override
  final bool forSyntheticToken;

  @override
  final bool isImplicitlyTyped;

  @override
  final bool isLocalFunction;

  VariableDeclarationImpl(
    String? name, {
    this.forSyntheticToken = false,
    bool hasDeclaredInitializer = false,
    Expression? initializer,
    DartType? type,
    bool isFinal = false,
    bool isConst = false,
    bool isInitializingFormal = false,
    bool isSuperInitializingFormal = false,
    bool isCovariantByDeclaration = false,
    bool isLocalFunction = false,
    bool isLate = false,
    bool isRequired = false,
    bool isLowered = false,
    bool isSynthesized = false,
    bool isStaticLate = false,
    bool isWildcard = false,
    bool isLateFinalWithoutInitializer = false,
  }) : isImplicitlyTyped = type == null,
       isLocalFunction = isLocalFunction,
       super(
         name,
         initializer: initializer,
         type: type ?? const DynamicType(),
         isFinal: isFinal,
         isConst: isConst,
         isInitializingFormal: isInitializingFormal,
         isSuperInitializingFormal: isSuperInitializingFormal,
         isCovariantByDeclaration: isCovariantByDeclaration,
         isLate: isLate,
         isRequired: isRequired,
         isLowered: isLowered,
         isSynthesized: isSynthesized,
         hasDeclaredInitializer: hasDeclaredInitializer,
         isWildcard: isWildcard,
       ) {
    this.isStaticLate = isStaticLate;
    this.isLateFinalWithoutInitializer = isLateFinalWithoutInitializer;
  }

  VariableDeclarationImpl.forEffect(Expression initializer)
    : forSyntheticToken = false,
      isImplicitlyTyped = false,
      isLocalFunction = false,
      super.forValue(initializer) {
    isStaticLate = false;
  }

  VariableDeclarationImpl.forValue(Expression initializer)
    : forSyntheticToken = false,
      isImplicitlyTyped = true,
      isLocalFunction = false,
      super.forValue(initializer) {
    isStaticLate = false;
  }

  @override
  bool get isAssignable {
    if (isStaticLate) return true;
    return super.isAssignable;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeVariableInitialization(
      this,
      isLate: isLate || lateGetter != null,
      type: lateType ?? type,
    );
    printer.write(';');
  }

  @override
  String toString() {
    return "VariableDeclarationImpl(${toStringInternal()})";
  }
}

class InternalLocalVariable extends TreeNode
    with InternalExpressionVariableMixin, DelegatingVariableMixin
    implements LocalVariable, InternalExpressionVariable {
  @override
  LocalVariable astVariable;

  @override
  final bool forSyntheticToken;

  @override
  final bool isImplicitlyTyped;

  @override
  final bool isLocalFunction;

  InternalLocalVariable({
    required this.astVariable,
    required this.isImplicitlyTyped,
    this.forSyntheticToken = false,
    this.isLocalFunction = false,
  });

  @override
  String toString() {
    return "InternalLocalVariable(${toStringInternal()})";
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeExpressionVariable(astVariable);
    List<String> modifiers = [
      if (forSyntheticToken) "forSyntheticToken",
      if (isImplicitlyTyped) "isImplicitlyTyped",
      if (isLocalFunction) "isLocalFunction",
    ];
    if (modifiers.isNotEmpty) {
      printer.write("[${modifiers.join(",")}]");
    }
  }
}

class InternalPositionalParameter extends TreeNode
    with InternalExpressionVariableMixin, DelegatingVariableMixin
    implements PositionalParameter, InternalExpressionVariable {
  @override
  PositionalParameter astVariable;

  @override
  final bool forSyntheticToken;

  @override
  final bool isImplicitlyTyped;

  @override
  final bool isLocalFunction;

  @override
  // TODO(62620): Conforming to [VariableDeclaration] interface. Remove this.
  List<VariableContext>? contexts;

  InternalPositionalParameter({
    required this.astVariable,
    required this.isImplicitlyTyped,
    this.forSyntheticToken = false,
    this.isLocalFunction = false,
  });

  @override
  R accept<R>(StatementVisitor<R> v) => v.visitPositionalParameter(astVariable);

  @override
  // Coverage-ignore(suite): Not run.
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitPositionalParameter(astVariable, arg);

  @override
  String toString() {
    return "InternalPositionalParameter(${toStringInternal()})";
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeExpressionVariable(astVariable);
    List<String> modifiers = [
      if (forSyntheticToken) "forSyntheticToken",
      if (isImplicitlyTyped) "isImplicitlyTyped",
      if (isLocalFunction) "isLocalFunction",
    ];
    if (modifiers.isNotEmpty) {
      printer.write("[${modifiers.join(",")}]");
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression? get defaultValue => astVariable.defaultValue;

  @override
  // Coverage-ignore(suite): Not run.
  void set defaultValue(Expression? value) {
    astVariable.defaultValue = value;
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool get hasDeclaredDefaultType => astVariable.hasDeclaredDefaultType;

  @override
  // Coverage-ignore(suite): Not run.
  void set hasDeclaredDefaultType(bool value) {
    astVariable.hasDeclaredDefaultType = value;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void clearAnnotations() {
    astVariable.clearAnnotations();
  }

  @override
  int binaryOffsetNoTag = -1;

  @override
  int fileEqualsOffset = TreeNode.noOffset;

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionVariable get variable => this;

  @override
  void set variable(ExpressionVariable value) {
    throw new UnsupportedError("${this.runtimeType}");
  }
}

class InternalNamedParameter extends TreeNode
    with InternalExpressionVariableMixin, DelegatingVariableMixin
    implements NamedParameter, InternalExpressionVariable {
  @override
  NamedParameter astVariable;

  @override
  final bool forSyntheticToken;

  @override
  final bool isImplicitlyTyped;

  @override
  final bool isLocalFunction;

  @override
  // TODO(62620): Conforming to [VariableDeclaration] interface. Remove this.
  List<VariableContext>? contexts;

  InternalNamedParameter({
    required this.astVariable,
    required this.isImplicitlyTyped,
    this.forSyntheticToken = false,
    this.isLocalFunction = false,
  });

  @override
  R accept<R>(StatementVisitor<R> v) => v.visitNamedParameter(astVariable);

  @override
  // Coverage-ignore(suite): Not run.
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitNamedParameter(astVariable, arg);

  @override
  String toString() {
    return "InternalNamedParameter(${toStringInternal()})";
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeExpressionVariable(astVariable);
    List<String> modifiers = [
      if (forSyntheticToken) "forSyntheticToken",
      if (isImplicitlyTyped) "isImplicitlyTyped",
      if (isLocalFunction) "isLocalFunction",
    ];
    if (modifiers.isNotEmpty) {
      printer.write("[${modifiers.join(",")}]");
    }
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression? get defaultValue => astVariable.defaultValue;

  @override
  // Coverage-ignore(suite): Not run.
  void set defaultValue(Expression? value) {
    astVariable.defaultValue = value;
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool get hasDeclaredDefaultType => astVariable.hasDeclaredDefaultType;

  @override
  // Coverage-ignore(suite): Not run.
  void set hasDeclaredDefaultType(bool value) {
    astVariable.hasDeclaredDefaultType = value;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void clearAnnotations() {
    astVariable.clearAnnotations();
  }

  @override
  // Coverage-ignore(suite): Not run.
  String get parameterName => astVariable.parameterName;

  @override
  // Coverage-ignore(suite): Not run.
  void set parameterName(String value) {
    astVariable.parameterName = value;
  }

  @override
  int binaryOffsetNoTag = -1;

  @override
  int fileEqualsOffset = TreeNode.noOffset;

  @override
  // Coverage-ignore(suite): Not run.
  ExpressionVariable get variable => this;

  @override
  void set variable(ExpressionVariable value) {
    throw new UnsupportedError("${this.runtimeType}");
  }
}

mixin DelegatingVariableMixin on InternalExpressionVariableMixin
    implements InternalExpressionVariable {
  @override
  String? get cosmeticName => astVariable.cosmeticName;

  @override
  TreeNode? get parent => astVariable.parent;

  @override
  void set parent(TreeNode? value) {
    astVariable.parent = value;
  }

  @override
  List<Expression> get annotations => astVariable.annotations;

  @override
  // Coverage-ignore(suite): Not run.
  void set annotations(List<Expression> value) {
    astVariable.annotations = value;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void addAnnotation(Expression node) {
    astVariable.addAnnotation(node);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void set cosmeticName(String? value) {
    astVariable.cosmeticName = value;
  }

  @override
  bool get hasDeclaredInitializer => astVariable.hasDeclaredInitializer;

  @override
  // Coverage-ignore(suite): Not run.
  void set hasDeclaredInitializer(bool value) {
    astVariable.hasDeclaredInitializer = value;
  }

  @override
  Expression? get initializer => astVariable.initializer;

  @override
  // Coverage-ignore(suite): Not run.
  void set initializer(Expression? value) {
    astVariable.initializer = value;
  }

  @override
  bool get isConst => astVariable.isConst;

  @override
  // Coverage-ignore(suite): Not run.
  void set isConst(bool value) {
    astVariable.isConst = value;
  }

  @override
  bool get isCovariantByClass => astVariable.isCovariantByClass;

  @override
  // Coverage-ignore(suite): Not run.
  void set isCovariantByClass(bool value) {
    astVariable.isCovariantByClass = value;
  }

  @override
  bool get isCovariantByDeclaration => astVariable.isCovariantByDeclaration;

  @override
  // Coverage-ignore(suite): Not run.
  void set isCovariantByDeclaration(bool value) {
    astVariable.isCovariantByDeclaration = value;
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool get isErroneouslyInitialized => astVariable.isErroneouslyInitialized;

  @override
  // Coverage-ignore(suite): Not run.
  void set isErroneouslyInitialized(bool value) {
    astVariable.isErroneouslyInitialized = value;
  }

  @override
  bool get isFinal => astVariable.isFinal;

  @override
  // Coverage-ignore(suite): Not run.
  void set isFinal(bool value) {
    astVariable.isFinal = value;
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool get isHoisted => astVariable.isHoisted;

  @override
  // Coverage-ignore(suite): Not run.
  void set isHoisted(bool value) {
    astVariable.isHoisted = value;
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool get isInitializingFormal => astVariable.isInitializingFormal;

  @override
  // Coverage-ignore(suite): Not run.
  void set isInitializingFormal(bool value) {
    astVariable.isInitializingFormal = value;
  }

  @override
  bool get isLate => astVariable.isLate;

  @override
  void set isLate(bool value) {
    astVariable.isLate = value;
  }

  @override
  bool get isLowered => astVariable.isLowered;

  @override
  // Coverage-ignore(suite): Not run.
  void set isLowered(bool value) {
    astVariable.isLowered = value;
  }

  @override
  bool get isRequired => astVariable.isRequired;

  @override
  // Coverage-ignore(suite): Not run.
  void set isRequired(bool value) {
    astVariable.isRequired = value;
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool get isSuperInitializingFormal => astVariable.isSuperInitializingFormal;

  @override
  // Coverage-ignore(suite): Not run.
  void set isSuperInitializingFormal(bool value) {
    astVariable.isSuperInitializingFormal = value;
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool get isSynthesized => astVariable.isSynthesized;

  @override
  // Coverage-ignore(suite): Not run.
  void set isSynthesized(bool value) {
    astVariable.isSynthesized = value;
  }

  @override
  bool get isWildcard => astVariable.isWildcard;

  @override
  // Coverage-ignore(suite): Not run.
  void set isWildcard(bool value) {
    astVariable.isWildcard = value;
  }

  @override
  DartType get type => astVariable.type;

  @override
  // Coverage-ignore(suite): Not run.
  void set type(DartType value) {
    astVariable.type = type;
  }

  @override
  // Coverage-ignore(suite): Not run.
  VariableInitialization? get variableInitialization =>
      astVariable.variableInitialization;

  @override
  void set variableInitialization(VariableInitialization? value) {
    astVariable.variableInitialization = value;
  }

  @override
  bool get isAssignable => astVariable.isAssignable;

  @override
  bool get hasIsFinal => astVariable.hasIsFinal;

  @override
  bool get hasIsConst => astVariable.hasIsConst;

  @override
  bool get hasIsLate => astVariable.hasIsLate;

  @override
  // Coverage-ignore(suite): Not run.
  bool get hasIsInitializingFormal => astVariable.hasIsInitializingFormal;

  @override
  bool get hasIsSynthesized => astVariable.hasIsSynthesized;

  @override
  bool get hasIsHoisted => astVariable.hasIsHoisted;

  @override
  // Coverage-ignore(suite): Not run.
  bool get hasHasDeclaredInitializer => astVariable.hasHasDeclaredInitializer;

  @override
  bool get hasIsCovariantByClass => astVariable.hasIsCovariantByClass;

  @override
  bool get hasIsRequired => astVariable.hasIsRequired;

  @override
  bool get hasIsCovariantByDeclaration =>
      astVariable.hasIsCovariantByDeclaration;

  @override
  bool get hasIsLowered => astVariable.hasIsLowered;

  @override
  bool get hasIsWildcard => astVariable.hasIsWildcard;

  @override
  // Coverage-ignore(suite): Not run.
  bool get hasIsSuperInitializingFormal =>
      astVariable.hasIsSuperInitializingFormal;

  @override
  bool get hasIsErroneouslyInitialized =>
      astVariable.hasIsErroneouslyInitialized;

  @override
  int get fileOffset => astVariable.fileOffset;

  @override
  void set fileOffset(int value) {
    astVariable.fileOffset = value;
  }

  int get flags => astVariable.flags;

  // Coverage-ignore(suite): Not run.
  void set flags(int value) {
    astVariable.flags = value;
  }

  @override
  // Coverage-ignore(suite): Not run.
  R accept<R>(TreeVisitor<R> v) {
    return astVariable.accept(v);
  }

  @override
  // Coverage-ignore(suite): Not run.
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) {
    return astVariable.accept1(v, arg);
  }

  String? get name => astVariable.cosmeticName;

  // Coverage-ignore(suite): Not run.
  void set name(String? value) {
    astVariable.cosmeticName = value;
  }

  VariableContext get context {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  Component? get enclosingComponent {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  List<int>? get fileOffsetsIfMultiple {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  String leakingDebugToString() {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  Location? get location {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void replaceChild(TreeNode child, TreeNode replacement) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void replaceWith(TreeNode replacement) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  // Coverage-ignore(suite): Not run.
  String toStringInternal() {
    return super.toStringInternal();
  }

  @override
  // Coverage-ignore(suite): Not run.
  String toText(AstTextStrategy strategy) {
    return super.toText(strategy);
  }

  @override
  void toTextInternal(AstPrinter printer) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void transformChildren(Transformer v) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    throw new UnsupportedError("${this.runtimeType}");
  }

  @override
  void visitChildren(Visitor<dynamic> v) {
    throw new UnsupportedError("${this.runtimeType}");
  }
}

abstract interface class InternalExpressionVariable
    implements IExpressionVariable, Annotatable {
  /// This is the output variable that the clients receive.
  ///
  /// Most of the calls to variable properties are delegated to [astVariable],
  /// but some operations must be performed directly on [astVariable], as
  /// follows:
  ///
  /// * passing [astVariable] into the flow analysis engine,
  /// * using [astVariable] as a part of the generated AST,
  /// * checking semantic properties of an AST node, such as [isExtensionThis]
  ///   in `lowering_predicates.dart`.
  ExpressionVariable get astVariable;

  bool get forSyntheticToken;

  /// Determine whether the given [InternalExpressionVariable] had an implicit
  /// type.
  bool get isImplicitlyTyped;

  /// Determines whether the given [InternalExpressionVariable] represents a
  /// local function.
  bool get isLocalFunction;

  /// Whether the variable is final with no initializer.
  ///
  /// Such variables behave similar to those declared with the `late` keyword,
  /// except that the don't have lazy evaluation semantics, and it is statically
  /// verified by the front end that they are always assigned before they are
  /// used.
  abstract bool isStaticLate;

  /// The synthesized local getter function for a lowered late variable.
  ///
  /// This is set in `InferenceVisitor.visitVariableDeclaration` when late
  /// lowering is enabled.
  abstract VariableDeclaration? lateGetter;

  /// The synthesized local setter function for an assignable lowered late
  /// variable.
  ///
  /// This is set in `InferenceVisitor.visitVariableDeclaration` when late
  /// lowering is enabled.
  abstract VariableDeclaration? lateSetter;

  /// Is `true` if this a lowered late final variable without an initializer.
  ///
  /// This is set in `InferenceVisitor.visitVariableDeclaration` when late
  /// lowering is enabled.
  abstract bool isLateFinalWithoutInitializer;

  /// The original type (declared or inferred) of a lowered late variable.
  ///
  /// This is set in `InferenceVisitor.visitVariableDeclaration` when late
  /// lowering is enabled.
  abstract DartType? lateType;

  /// The original name of a lowered late variable.
  ///
  /// This is set in `InferenceVisitor.visitVariableDeclaration` when late
  /// lowering is enabled.
  abstract String? lateName;

  @override
  abstract List<Expression> annotations;
}

mixin InternalExpressionVariableMixin on TreeNode
    implements InternalExpressionVariable {
  @override
  bool get forSyntheticToken;

  @override
  bool get isImplicitlyTyped;

  @override
  bool get isLocalFunction;

  @override
  bool isStaticLate = false;

  @override
  VariableDeclaration? lateGetter;

  @override
  VariableDeclaration? lateSetter;

  @override
  bool isLateFinalWithoutInitializer = false;

  @override
  DartType? lateType;

  @override
  String? lateName;

  @override
  ExpressionVariable get asExpressionVariable => this as ExpressionVariable;
}

/// Front end specific implementation of [LoadLibrary].
class LoadLibraryImpl extends LoadLibrary {
  final ActualArguments? arguments;

  LoadLibraryImpl(LibraryDependency import, this.arguments) : super(import);

  @override
  String toString() {
    return "LoadLibraryImpl(${toStringInternal()})";
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write(import.name!);
    printer.write('.loadLibrary');
    if (arguments != null) {
      arguments!.toTextInternal(printer);
    } else {
      printer.write('()');
    }
  }
}

/// Internal expression representing a tear-off of a `loadLibrary` function.
class LoadLibraryTearOff extends InternalExpression {
  LibraryDependency import;
  Procedure target;

  LoadLibraryTearOff(this.import, this.target);

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitLoadLibraryTearOff(this, typeContext);
  }

  @override
  String toString() {
    return "LoadLibraryTearOff(${toStringInternal()})";
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write(import.name!);
    printer.write('.loadLibrary');
  }
}

/// Internal expression representing an if-null property set.
///
/// An if-null property set of the form `o.a ??= b` is, if used for value,
/// encoded as the expression:
///
///     let v1 = o in let v2 = v1.a in v2 == null ? v1.a = b : v2
///
/// and, if used for effect, encoded as the expression:
///
///     let v1 = o in v1.a == null ? v1.a = b : null
///
class IfNullPropertySet extends InternalExpression {
  /// The receiver used for the read/write operations.
  Expression receiver;

  /// Name of the property.
  Name propertyName;

  /// The right-hand side of the binary operation.
  Expression rhs;

  /// If `true`, the expression is only need for effect and not for its value.
  final bool forEffect;

  /// The file offset for the read operation.
  final int readOffset;

  /// The file offset for the write operation.
  final int writeOffset;

  /// `true` if the access is null-aware, i.e. of the form `o?.a ??= b`.
  final bool isNullAware;

  IfNullPropertySet(
    this.receiver,
    this.propertyName,
    this.rhs, {
    required this.forEffect,
    required this.readOffset,
    required this.writeOffset,
    required this.isNullAware,
  }) {
    receiver.parent = this;
    rhs.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitIfNullPropertySet(this, typeContext);
  }

  @override
  String toString() {
    return "IfNullPropertySet(${toStringInternal()})";
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver);
    if (isNullAware) {
      printer.write('?');
    }
    printer.write('.');
    printer.writeName(propertyName);
    printer.write(' ??= ');
    printer.writeExpression(rhs);
  }
}

/// Internal expression representing an if-null assignment.
///
/// An if-null assignment of the form `a ??= b` is, if used for value,
/// encoded as the expression:
///
///     let v1 = a in v1 == null ? a = b : v1
///
/// and, if used for effect, encoded as the expression:
///
///     a == null ? a = b : null
///
class IfNullSet extends InternalExpression {
  /// The expression that reads the property from [variable].
  Expression read;

  /// The expression that writes the value to the property on [variable].
  Expression write;

  /// If `true`, the expression is only need for effect and not for its value.
  final bool forEffect;

  IfNullSet(this.read, this.write, {required this.forEffect}) {
    read.parent = this;
    write.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitIfNullSet(this, typeContext);
  }

  @override
  String toString() {
    return "IfNullSet(${toStringInternal()})";
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(read);
    printer.write(' ?? ');
    printer.writeExpression(write);
  }
}

/// Internal expression representing an compound extension assignment.
///
/// An compound extension assignment of the form
///
///     Extension(receiver).propertyName ??= rhs
///
/// is, if used for value, encoded as the expression:
///
///     let receiverVariable = receiver in
///       let valueVariable =
///           Extension|get#propertyName(receiverVariable) in
///         valueVariable == null
///           ? let rhsVariable = rhs in
///             let writeVariable in
///                 Extension|set#propertyName(receiverVariable, rhsVariable) in
///               rhsVariable
///           : valueVariable
///
/// and if used for effect as:
///
///     let receiverVariable = receiver in
///       Extension|get#propertyName(receiverVariable) == null
///         ? Extension|set#propertyName(receiverVariable, rhs)
///         : null
///
class ExtensionIfNullSet extends InternalExpression {
  /// The extension in which the [getter] and [setter] are declared.
  final Extension extension;

  /// The known type arguments for the type parameters declared in
  /// [extension], either explicitly provided like `E<int>(o).a ??= b` or
  /// implied as in `a ??= b` from within the extension `E`.
  final List<DartType>? knownTypeArguments;

  /// The receiver used for the read/write operations.
  Expression receiver;

  /// The name of property.
  ///
  /// This is the name of the access and _not_ the name of the lowered method.
  final Name propertyName;

  /// The member used for the read operation.
  final Member getter;

  /// The right-hand side of the binary operation.
  Expression rhs;

  /// The member used for the write operation.
  final Member setter;

  /// If `true`, the expression is only need for effect and not for its value.
  final bool forEffect;

  /// The file offset for the read operation.
  final int readOffset;

  /// The file offset for the binary operation.
  final int binaryOffset;

  /// The file offset for the write operation.
  final int writeOffset;

  /// `true` if the access is null-aware, i.e. of the form
  /// `Extension(o)?.a ??= b`.
  final bool isNullAware;

  /// `true` if the extension access is explicit, i.e. `E(o).a ??= b` and
  /// not implicit like `a ??= b` inside the extension `E`.
  final bool _isExplicit;

  /// File offset of the explicit extension type arguments, if provided.
  final int? extensionTypeArgumentOffset;

  ExtensionIfNullSet.explicit({
    required Extension extension,
    required List<DartType>? explicitTypeArguments,
    required Expression receiver,
    required Name propertyName,
    required Procedure getter,
    required Expression rhs,
    required Procedure setter,
    required bool forEffect,
    required int readOffset,
    required int binaryOffset,
    required int writeOffset,
    required bool isNullAware,
    required int? extensionTypeArgumentOffset,
  }) : this._(
         extension,
         explicitTypeArguments,
         receiver,
         propertyName,
         getter,
         rhs,
         setter,
         forEffect: forEffect,
         readOffset: readOffset,
         binaryOffset: binaryOffset,
         writeOffset: writeOffset,
         isNullAware: isNullAware,
         isExplicit: true,
         extensionTypeArgumentOffset: extensionTypeArgumentOffset,
       );

  ExtensionIfNullSet.implicit({
    required Extension extension,
    required List<DartType>? thisTypeArguments,
    required Expression thisAccess,
    required Name propertyName,
    required Procedure getter,
    required Expression rhs,
    required Procedure setter,
    required bool forEffect,
    required int readOffset,
    required int binaryOffset,
    required int writeOffset,
  }) : this._(
         extension,
         thisTypeArguments,
         thisAccess,
         propertyName,
         getter,
         rhs,
         setter,
         forEffect: forEffect,
         readOffset: readOffset,
         binaryOffset: binaryOffset,
         writeOffset: writeOffset,
         isNullAware: false,
         isExplicit: false,
         extensionTypeArgumentOffset: null,
       );

  ExtensionIfNullSet._(
    this.extension,
    this.knownTypeArguments,
    this.receiver,
    this.propertyName,
    this.getter,
    this.rhs,
    this.setter, {
    required this.forEffect,
    required this.readOffset,
    required this.binaryOffset,
    required this.writeOffset,
    required this.isNullAware,
    required bool isExplicit,
    required this.extensionTypeArgumentOffset,
  }) : _isExplicit = isExplicit,
       assert(
         knownTypeArguments == null ||
             extension.typeParameters.isNotEmpty &&
                 knownTypeArguments.length == extension.typeParameters.length,
       ) {
    receiver.parent = this;
    rhs.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitExtensionIfNullSet(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (_isExplicit) {
      printer.write(extension.name);
      if (knownTypeArguments != null) {
        printer.writeTypeArguments(knownTypeArguments!);
      }
      printer.write('(');
      printer.writeExpression(receiver);
      printer.write(')');
    } else {
      printer.writeExpression(receiver);
    }
    if (isNullAware) {
      printer.write('?');
    }
    printer.write('.');
    printer.writeName(propertyName);
    printer.write(' ??= ');
    printer.writeExpression(rhs);
  }

  @override
  String toString() {
    return "ExtensionIfNullSet(${toStringInternal()})";
  }
}

/// Internal expression representing an compound extension assignment.
///
/// An compound extension assignment of the form
///
///     Extension(receiver).propertyName += rhs
///
/// is, if used for value, encoded as the expression:
///
///     let receiverVariable = receiver in
///       let valueVariable =
///           Extension|get#propertyName(receiverVariable) + rhs) in
///         let writeVariable =
///             Extension|set#propertyName(receiverVariable, valueVariable) in
///           valueVariable
///
/// and if used for effect as:
///
///     let receiverVariable = receiver in
///         Extension|set#propertyName(receiverVariable,
///           Extension|get#propertyName(receiverVariable) + rhs)
///
class ExtensionCompoundSet extends InternalExpression {
  /// The extension in which the [getter] and [setter] are declared.
  final Extension extension;

  /// The known type arguments for the type parameters declared in
  /// [extension], either explicitly provided like `E<int>(o).a += b` or
  /// implied as in `a += b` from within the extension `E`.
  final List<DartType>? knownTypeArguments;

  /// The receiver used for the read/write operations.
  Expression receiver;

  /// The name of property.
  ///
  /// This is the name of the access and _not_ the name of the lowered method.
  final Name propertyName;

  /// The member used for the read operation.
  final Member getter;

  /// The binary operation performed on the getter result and [rhs].
  final Name binaryName;

  /// The right-hand side of the binary operation.
  Expression rhs;

  /// The member used for the write operation.
  final Member setter;

  /// If `true`, the expression is only need for effect and not for its value.
  final bool forEffect;

  /// The file offset for the read operation.
  final int readOffset;

  /// The file offset for the binary operation.
  final int binaryOffset;

  /// The file offset for the write operation.
  final int writeOffset;

  /// `true` if the access is null-aware, i.e. of the form
  /// `Extension(o)?.a += b`.
  final bool isNullAware;

  /// `true` if the extension access is explicit, i.e. `E(o).a += b` and
  /// not implicit like `a += b` inside the extension `E`.
  final bool _isExplicit;

  /// File offset of the explicit extension type arguments, if provided.
  final int? extensionTypeArgumentOffset;

  ExtensionCompoundSet.explicit({
    required Extension extension,
    required List<DartType>? explicitTypeArguments,
    required Expression receiver,
    required Name propertyName,
    required Procedure getter,
    required Name binaryName,
    required Expression rhs,
    required Procedure setter,
    required bool forEffect,
    required int readOffset,
    required int binaryOffset,
    required int writeOffset,
    required bool isNullAware,
    required int? extensionTypeArgumentOffset,
  }) : this._(
         extension,
         explicitTypeArguments,
         receiver,
         propertyName,
         getter,
         binaryName,
         rhs,
         setter,
         forEffect: forEffect,
         readOffset: readOffset,
         binaryOffset: binaryOffset,
         writeOffset: writeOffset,
         isNullAware: isNullAware,
         isExplicit: true,
         extensionTypeArgumentOffset: extensionTypeArgumentOffset,
       );

  ExtensionCompoundSet.implicit({
    required Extension extension,
    required List<DartType>? thisTypeArguments,
    required Expression thisAccess,
    required Name propertyName,
    required Procedure getter,
    required Name binaryName,
    required Expression rhs,
    required Procedure setter,
    required bool forEffect,
    required int readOffset,
    required int binaryOffset,
    required int writeOffset,
  }) : this._(
         extension,
         thisTypeArguments,
         thisAccess,
         propertyName,
         getter,
         binaryName,
         rhs,
         setter,
         forEffect: forEffect,
         readOffset: readOffset,
         binaryOffset: binaryOffset,
         writeOffset: writeOffset,
         isNullAware: false,
         isExplicit: false,
         extensionTypeArgumentOffset: null,
       );

  ExtensionCompoundSet._(
    this.extension,
    this.knownTypeArguments,
    this.receiver,
    this.propertyName,
    this.getter,
    this.binaryName,
    this.rhs,
    this.setter, {
    required this.forEffect,
    required this.readOffset,
    required this.binaryOffset,
    required this.writeOffset,
    required this.isNullAware,
    required bool isExplicit,
    required this.extensionTypeArgumentOffset,
  }) : _isExplicit = isExplicit,
       assert(
         knownTypeArguments == null ||
             extension.typeParameters.isNotEmpty &&
                 knownTypeArguments.length == extension.typeParameters.length,
       ) {
    receiver.parent = this;
    rhs.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitExtensionCompoundSet(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (_isExplicit) {
      printer.write(extension.name);
      if (knownTypeArguments != null) {
        printer.writeTypeArguments(knownTypeArguments!);
      }
      printer.write('(');
      printer.writeExpression(receiver);
      printer.write(')');
    } else {
      printer.writeExpression(receiver);
    }
    if (isNullAware) {
      printer.write('?');
    }
    printer.write('.');
    printer.writeName(propertyName);
    printer.write(' ');
    printer.writeName(binaryName);
    printer.write('= ');
    printer.writeExpression(rhs);
  }

  @override
  String toString() {
    return "ExtensionCompoundSet(${toStringInternal()})";
  }
}

/// Internal expression representing an compound property assignment.
///
/// An compound property assignment of the form
///
///     receiver.propertyName += rhs
///
/// is encoded as the expression:
///
///     let receiverVariable = receiver in
///       receiverVariable.propertyName = receiverVariable.propertyName + rhs
///
class CompoundPropertySet extends InternalExpression {
  /// The receiver used for the read/write operations.
  Expression receiver;

  /// The name of the property accessed by the read/write operations.
  final Name propertyName;

  /// The binary operation performed on the getter result and [value].
  final Name binaryName;

  /// The right-hand side of the binary operation.
  Expression value;

  /// If `true`, the expression is only need for effect and not for its value.
  final bool forEffect;

  /// The file offset for the read operation.
  final int readOffset;

  /// The file offset for the binary operation.
  final int binaryOffset;

  /// The file offset for the write operation.
  final int writeOffset;

  /// `true` if the access is null-aware, i.e. of the form `o?.a += b`.
  final bool isNullAware;

  CompoundPropertySet({
    required this.receiver,
    required this.propertyName,
    required this.binaryName,
    required this.value,
    required this.forEffect,
    required this.readOffset,
    required this.binaryOffset,
    required this.writeOffset,
    required this.isNullAware,
  }) {
    receiver.parent = this;
    value.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitCompoundPropertySet(this, typeContext);
  }

  @override
  String toString() {
    return "CompoundPropertySet(${toStringInternal()})";
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver);
    if (isNullAware) {
      printer.write('?');
    }
    printer.write('.');
    printer.writeName(propertyName);
    printer.write(' ');
    printer.writeName(binaryName);
    printer.write('= ');
    printer.writeExpression(value);
  }
}

/// Internal expression representing an property inc/dec, for instance
/// `o.a++` and `--o.a`.
///
/// An property postfix increment of the form `o.a++` is encoded as the
/// expression:
///
///     let v1 = o in let v2 = v1.a in let v3 = v1.a = v2 + 1 in v2
///
/// and a property prefix increment of the form `--o.a` or a postfix decrement
/// of the form `o.a--` for effect is encoded as the expression:
///
///     let v1 = o in let v2 = v1.a in v1.a = v2 - 1
///
class PropertyIncDec extends InternalExpression {
  /// The receiver of the assigned property.
  Expression receiver;

  /// The name of the assigned property.
  Name name;

  /// `true` if the inc/dec is a postfix expression, i.e. of the form `o.a++` as
  /// opposed the prefix expression `++o.a`.
  final bool isPost;

  /// If `true` the assignment is need for its effect and not for its value.
  final bool forEffect;

  /// `true` if this is an post increment, i.e. `o.a++` as opposed to `o.a--`.
  final bool isInc;

  /// `true` if the access is null-aware, i.e. of the form `o?.a++`.
  final bool isNullAware;

  /// The file offset of the [name].
  final int nameOffset;

  /// The file offset of the `++` or `--` operator.
  final int operatorOffset;

  PropertyIncDec(
    this.receiver,
    this.name, {
    required this.forEffect,
    required this.isPost,
    required this.isInc,
    required this.isNullAware,
    required this.nameOffset,
    required this.operatorOffset,
  }) {
    receiver.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitPropertyIncDec(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (!isPost) {
      if (isInc) {
        printer.write('++');
      } else {
        printer.write('--');
      }
    }
    printer.writeExpression(receiver);
    if (isNullAware) {
      printer.write('?');
    }
    printer.write('.');
    printer.writeName(name);
    if (isPost) {
      if (isInc) {
        printer.write('++');
      } else {
        printer.write('--');
      }
    }
  }

  @override
  String toString() {
    return "PropertyIncDec(${toStringInternal()})";
  }
}

/// Internal expression representing an post-inc/dec expression on an explicit
/// extension member access.
///
/// An post-inc/dec expression of the form `E(o).a++` is encoded as the
/// expression:
///
///     let v1 = o in let v2 = E|a(v1) in let v3 = E|a(v1, v2 + 1) in v2
///
class ExtensionIncDec extends InternalExpression {
  /// The extension in which the [getter] and [setter] are declared.
  final Extension extension;

  /// The known type arguments for the type parameters declared in
  /// [extension], either explicitly provided like `E<int>(o).a++` or
  /// implied as in `a++` from within the extension `E`.
  final List<DartType>? knownTypeArguments;

  /// The receiver used for the read/write operations.
  final Expression receiver;

  /// The name of property.
  ///
  /// This is the name of the access and _not_ the name of the lowered methods.
  final Name name;

  /// The [Procedure] used for the read of the property.
  final Procedure getter;

  /// The [Procedure] used for the write of the property.
  final Procedure setter;

  /// `true` if the inc/dec is a postfix expression, i.e. of the form `E(o).a++`
  /// as opposed the prefix expression `++E(o).a`.
  final bool isPost;

  /// `true` if this is a post increment expression, i.e. `E(o).a++` as opposed
  /// to `E(o).a--`.
  final bool isInc;

  /// `true` if the expression is for effect only, i.e. that the resulting value
  /// is not used.
  final bool forEffect;

  /// `true` if the access is null-aware, i.e. of the form `E(o)?.b++`.
  final bool isNullAware;

  /// `true` if this an explicit extension access, i.e. `E(o).a++` as opposed
  /// to the implicit access of `a++` occurring within the extension `E`.
  final bool _isExplicit;

  /// File offset of the explicit extension type arguments, if provided.
  final int? extensionTypeArgumentOffset;

  ExtensionIncDec.explicit({
    required Extension extension,
    required List<DartType>? explicitTypeArguments,
    required Expression receiver,
    required Name name,
    required Procedure getter,
    required Procedure setter,
    required bool isPost,
    required bool isInc,
    required bool forEffect,
    required bool isNullAware,
    required int? extensionTypeArgumentOffset,
  }) : this._(
         extension,
         explicitTypeArguments,
         receiver,
         name,
         getter,
         setter,
         isPost: isPost,
         isInc: isInc,
         forEffect: forEffect,
         isNullAware: isNullAware,
         isExplicit: true,
         extensionTypeArgumentOffset: extensionTypeArgumentOffset,
       );

  ExtensionIncDec.implicit({
    required Extension extension,
    required List<DartType>? thisTypeArguments,
    required Expression thisAccess,
    required Name name,
    required Procedure getter,
    required Procedure setter,
    required bool isPost,
    required bool isInc,
    required bool forEffect,
  }) : this._(
         extension,
         thisTypeArguments,
         thisAccess,
         name,
         getter,
         setter,
         isPost: isPost,
         isInc: isInc,
         forEffect: forEffect,
         isNullAware: false,
         isExplicit: false,
         extensionTypeArgumentOffset: null,
       );

  ExtensionIncDec._(
    this.extension,
    this.knownTypeArguments,
    this.receiver,
    this.name,
    this.getter,
    this.setter, {
    required this.isPost,
    required this.isInc,
    required this.forEffect,
    required this.isNullAware,
    required bool isExplicit,
    required this.extensionTypeArgumentOffset,
  }) : _isExplicit = isExplicit,
       assert(
         knownTypeArguments == null ||
             extension.typeParameters.isNotEmpty &&
                 knownTypeArguments.length == extension.typeParameters.length,
       ) {
    receiver.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitExtensionPostIncDec(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (!isPost) {
      printer.write(isInc ? '++' : '--');
    }
    if (_isExplicit) {
      printer.write(extension.name);
      if (knownTypeArguments != null) {
        printer.writeTypeArguments(knownTypeArguments!);
      }
      printer.write('(');
      printer.writeExpression(receiver);
      printer.write(')');
    } else {
      printer.writeExpression(receiver);
    }
    if (isNullAware) {
      printer.write('?');
    }
    printer.write('.');
    printer.writeName(name);
    if (isPost) {
      printer.write(isInc ? '++' : '--');
    }
  }

  @override
  String toString() {
    return "ExtensionPostIncDec(${toStringInternal()})";
  }
}

/// Internal expression representing an local variable post inc/dec expression.
///
/// An local variable post inc/dec expression of the form `a++` is encoded as
/// the expression:
///
///     let v1 = a in let v2 = a = v1 + 1 in v1
///
class LocalIncDec extends InternalExpression {
  /// The accessed variable.
  final InternalExpressionVariable variable;

  /// `true` if the inc/dec is a postfix expression, i.e. of the form `a++` as
  /// opposed the prefix expression `++a`.
  final bool isPost;

  /// If `true` the assignment is need for its effect and not for its value.
  final bool forEffect;

  /// `true` if this is an post increment, i.e. `a++` as opposed to `a--`.
  final bool isInc;

  /// The file offset of the name of the getter/setter, i.e. `a` in `a++`.
  final int nameOffset;

  /// The file offset of the `++` or `--` operator.
  final int operatorOffset;

  LocalIncDec({
    required this.variable,
    required this.forEffect,
    required this.isPost,
    required this.isInc,
    required this.nameOffset,
    required this.operatorOffset,
  });

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitLocalIncDec(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (!isPost) {
      if (isInc) {
        printer.write('++');
      } else {
        printer.write('--');
      }
    }
    printer.write(variable.cosmeticName!);
    if (isPost) {
      if (isInc) {
        printer.write('++');
      } else {
        printer.write('--');
      }
    }
  }

  @override
  String toString() {
    return "LocalIncDec(${toStringInternal()})";
  }
}

/// Internal expression representing a static member inc/dec expression.
///
/// A static postfix inc/dec expression of the form `a++` is encoded as
/// the expression:
///
///     let v1 = a in let v2 = a = v1 + 1 in v1
///
/// A static prefix inc/dec expression of the form `++a` or a postfix inc/dec
/// expression for effect is encoded as the expression:
///
///     a = a + 1
///
class StaticIncDec extends InternalExpression {
  /// The getter used to read the original value.
  final Member getter;

  /// The setter to which to updated value is assigned.
  final Member setter;

  /// The name of the accessed property.
  final Name name;

  /// `true` if the inc/dec is a postfix expression, i.e. of the form `a++` as
  /// opposed the prefix expression `++a`.
  final bool isPost;

  /// If `true` the assignment is need for its effect and not for its value.
  final bool forEffect;

  /// `true` if this is an post increment, i.e. `a++` as opposed to `a--`.
  final bool isInc;

  /// The file offset of the name of the getter/setter, i.e. `a` in `a++`.
  final int nameOffset;

  /// The file offset of the `++` or `--` operator.
  final int operatorOffset;

  StaticIncDec({
    required this.getter,
    required this.setter,
    required this.name,
    required this.forEffect,
    required this.isPost,
    required this.isInc,
    required this.nameOffset,
    required this.operatorOffset,
  });

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitStaticIncDec(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (!isPost) {
      if (isInc) {
        printer.write('++');
      } else {
        printer.write('--');
      }
    }
    printer.writeName(name);
    if (isPost) {
      if (isInc) {
        printer.write('++');
      } else {
        printer.write('--');
      }
    }
  }

  @override
  String toString() {
    return "StaticIncDec(${toStringInternal()})";
  }
}

/// Internal expression representing a super member inc/dec expression.
///
/// A super postfix inc/dec expression of the form `super.a++` is encoded as
/// the expression:
///
///     let v1 = super.a in let v2 = super.a = v1 + 1 in v1
///
/// A super prefix inc/dec expression of the form `++super.a` or a postfix
/// inc/dec expression for effect is encoded as the expression:
///
///     super.a = super.a + 1
///
class SuperIncDec extends InternalExpression {
  /// The getter used to read the original value.
  final Member getter;

  /// The setter to which to updated value is assigned.
  final Member setter;

  /// The name of the accessed property.
  final Name name;

  /// `true` if the inc/dec is a postfix expression, i.e. of the form
  /// `super.a++` as opposed the prefix expression `++super.a`.
  final bool isPost;

  /// If `true` the assignment is need for its effect and not for its value.
  final bool forEffect;

  /// `true` if this is an post increment, i.e. `super.a++` as opposed to
  /// `super.a--`.
  final bool isInc;

  /// The file offset of the name of the getter/setter, i.e. `a` in `super.a++`.
  final int nameOffset;

  /// The file offset of the `++` or `--` operator.
  final int operatorOffset;

  SuperIncDec({
    required this.getter,
    required this.setter,
    required this.name,
    required this.forEffect,
    required this.isPost,
    required this.isInc,
    required this.nameOffset,
    required this.operatorOffset,
  });

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitSuperIncDec(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (!isPost) {
      if (isInc) {
        printer.write('++');
      } else {
        printer.write('--');
      }
    }
    printer.write('super.');
    printer.writeName(getter.name);
    if (isPost) {
      if (isInc) {
        printer.write('++');
      } else {
        printer.write('--');
      }
    }
  }

  @override
  String toString() {
    return "SuperIncDec(${toStringInternal()})";
  }
}

/// Internal expression representing an index get expression, `o[a]`.
class IndexGet extends InternalExpression {
  /// The receiver on which the index set operation is performed.
  Expression receiver;

  /// The index expression of the operation.
  Expression index;

  /// `true` if the access is null-aware, i.e. of the form `o?[a]`.
  final bool isNullAware;

  IndexGet(this.receiver, this.index, {required this.isNullAware}) {
    receiver.parent = this;
    index.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitIndexGet(this, typeContext);
  }

  @override
  String toString() {
    return "IndexGet(${toStringInternal()})";
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver);
    if (isNullAware) {
      printer.write('?');
    }
    printer.write('[');
    printer.writeExpression(index);
    printer.write(']');
  }
}

/// Internal expression representing an index set expression, `o[a] = b`.
///
/// An index set expression of the form `o[a] = b` used for value is encoded as
/// the expression:
///
///     let v1 = o in let v2 = a in let v3 = b in let _ = o.[]=(v2, v3) in v3
///
/// An index set expression used for effect is encoded as
///
///    o.[]=(a, b)
///
/// using [InstanceInvocation] or [DynamicInvocation].
///
class IndexSet extends InternalExpression {
  /// The receiver on which the index set operation is performed.
  Expression receiver;

  /// The index expression of the operation.
  Expression index;

  /// The value expression of the operation.
  Expression value;

  /// `true` if the assignment is for effect only, i.e the result value of the
  /// assignment is _not_ used.
  final bool forEffect;

  /// `true` if the access is null-aware, i.e. of the form `o?[a] = b`.
  final bool isNullAware;

  IndexSet(
    this.receiver,
    this.index,
    this.value, {
    required this.forEffect,
    required this.isNullAware,
  }) {
    receiver.parent = this;
    index.parent = this;
    value.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitIndexSet(this, typeContext);
  }

  @override
  String toString() {
    return "IndexSet(${toStringInternal()})";
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver);
    if (isNullAware) {
      printer.write('?');
    }
    printer.write('[');
    printer.writeExpression(index);
    printer.write('] = ');
    printer.writeExpression(value);
  }
}

/// Internal expression representing a  super index set expression.
///
/// A super index set expression of the form `super[a] = b` used for value is
/// encoded as the expression:
///
///     let v1 = a in let v2 = b in let _ = super.[]=(v1, v2) in v2
///
/// An index set expression used for effect is encoded as
///
///    super.[]=(a, b)
///
/// using [SuperMethodInvocation].
///
class SuperIndexSet extends InternalExpression {
  /// The []= member.
  Member setter;

  /// The index expression of the operation.
  Expression index;

  /// The value expression of the operation.
  Expression value;

  SuperIndexSet(this.setter, this.index, this.value) {
    index.parent = this;
    value.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitSuperIndexSet(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('super[');
    index.toTextInternal(printer);
    printer.write('] = ');
    value.toTextInternal(printer);
  }

  @override
  String toString() {
    return "SuperIndexSet(${toStringInternal()})";
  }
}

/// Internal expression representing an extension index get expression.
///
/// An extension index set expression of the form `Extension(o)[a]` used
/// for value is encoded as the expression:
///
///     Extension|[](o, a)
///
/// using [StaticInvocation].
///
class ExtensionIndexGet extends InternalExpression {
  /// The extension in which the [getter] is declared.
  final Extension extension;

  /// The explicit type arguments for the type parameters declared in
  /// [extension].
  final TypeArguments? explicitTypeArguments;

  /// The receiver of the extension access.
  Expression receiver;

  /// The [] procedure.
  Procedure getter;

  /// The index expression of the operation.
  Expression index;

  /// `true` if the access is null-aware, i.e. of the form
  /// `Extension(o)?[a]`.
  final bool isNullAware;

  /// File offset of the explicit extension type arguments, if provided.
  final int? extensionTypeArgumentOffset;

  ExtensionIndexGet(
    this.extension,
    this.explicitTypeArguments,
    this.receiver,
    this.getter,
    this.index, {
    required this.isNullAware,
    required this.extensionTypeArgumentOffset,
  }) : assert(
         explicitTypeArguments == null ||
             explicitTypeArguments.types.length ==
                 extension.typeParameters.length,
       ) {
    receiver.parent = this;
    index.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitExtensionIndexGet(this, typeContext);
  }

  @override
  String toString() {
    return "ExtensionIndexGet(${toStringInternal()})";
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write(extension.name);
    if (explicitTypeArguments != null) {
      printer.writeTypeArguments(explicitTypeArguments!.types);
    }
    printer.write('(');
    printer.writeExpression(receiver);
    printer.write(')');
    if (isNullAware) {
      printer.write('?');
    }
    printer.write('[');
    printer.writeExpression(index);
    printer.write(']');
  }
}

/// Internal expression representing an extension index set expression.
///
/// An extension index set expression of the form `Extension(o)[a] = b` used
/// for value is encoded as the expression:
///
///     let valueVariable = b in '
///     let writeVariable =
///         Extension|[]=(o, a, valueVariable) in
///           valueVariable
///
/// An extension index set expression used for effect is encoded as
///
///    Extension|[]=(o, a, b)
///
/// using [StaticInvocation].
///
class ExtensionIndexSet extends InternalExpression {
  /// The extension in which the [setter] is declared.
  final Extension extension;

  /// The explicit type arguments for the type parameters declared in
  /// [extension].
  final TypeArguments? explicitTypeArguments;

  /// The receiver of the extension access.
  Expression receiver;

  /// The []= procedure.
  Procedure setter;

  /// The index expression of the operation.
  Expression index;

  /// The value expression of the operation.
  Expression value;

  /// `true` if the access is null-aware, i.e. of the form
  /// `Extension(o)?[a] = b`.
  final bool isNullAware;

  /// If `true`, the expression is only need for effect and not for its value.
  final bool forEffect;

  /// File offset of the explicit extension type arguments, if provided.
  final int? extensionTypeArgumentOffset;

  ExtensionIndexSet(
    this.extension,
    this.explicitTypeArguments,
    this.receiver,
    this.setter,
    this.index,
    this.value, {
    required this.isNullAware,
    required this.forEffect,
    required this.extensionTypeArgumentOffset,
  }) : assert(
         explicitTypeArguments == null ||
             explicitTypeArguments.types.length ==
                 extension.typeParameters.length,
       ) {
    receiver.parent = this;
    index.parent = this;
    value.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitExtensionIndexSet(this, typeContext);
  }

  @override
  String toString() {
    return "ExtensionIndexSet(${toStringInternal()})";
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write(extension.name);
    if (explicitTypeArguments != null) {
      printer.writeTypeArguments(explicitTypeArguments!.types);
    }
    printer.write('(');
    printer.writeExpression(receiver);
    printer.write(')');
    if (isNullAware) {
      printer.write('?');
    }
    printer.write('[');
    printer.writeExpression(index);
    printer.write('] = ');
    printer.writeExpression(value);
  }
}

/// Internal expression representing an if-null index assignment.
///
/// An if-null index assignment of the form `o[a] ??= b` is, if used for value,
/// encoded as the expression:
///
///     let v1 = o in
///     let v2 = a in
///     let v3 = v1[v2] in
///       v3 == null
///        ? (let v4 = b in
///           let _ = v1.[]=(v2, v4) in
///           v4)
///        : v3
///
/// and, if used for effect, encoded as the expression:
///
///     let v1 = o in
///     let v2 = a in
///     let v3 = v1[v2] in
///        v3 == null ? v1.[]=(v2, b) : null
///
/// If the [readOnlyReceiver] is true, no temporary variable is created for the
/// receiver and its use is inlined.
class IfNullIndexSet extends InternalExpression {
  /// The receiver on which the index set operation is performed.
  Expression receiver;

  /// The index expression of the operation.
  Expression index;

  /// The value expression of the operation.
  Expression value;

  /// The file offset for the [] operation.
  final int readOffset;

  /// The file offset for the == operation.
  final int testOffset;

  /// The file offset for the []= operation.
  final int writeOffset;

  /// If `true`, the expression is only need for effect and not for its value.
  final bool forEffect;

  /// `true` if the access is null-aware, i.e. of the form `o?[a] ??= b`.
  final bool isNullAware;

  IfNullIndexSet({
    required this.receiver,
    required this.index,
    required this.value,
    required this.readOffset,
    required this.testOffset,
    required this.writeOffset,
    required this.forEffect,
    required this.isNullAware,
  }) {
    receiver.parent = this;
    index.parent = this;
    value.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitIfNullIndexSet(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    receiver.toTextInternal(printer);
    if (isNullAware) {
      printer.write('?');
    }
    printer.write('[');
    index.toTextInternal(printer);
    printer.write('] ??= ');
    value.toTextInternal(printer);
  }

  @override
  String toString() {
    return "IfNullIndexSet(${toStringInternal()})";
  }
}

/// Internal expression representing an if-null super index set expression.
///
/// An if-null super index set expression of the form `super[a] ??= b` is, if
/// used for value, encoded as the expression:
///
///     let v1 = a in
///     let v2 = super.[](v1) in
///       v2 == null
///        ? (let v3 = b in
///           let _ = super.[]=(v1, v3) in
///           v3)
///        : v2
///
/// and, if used for effect, encoded as the expression:
///
///     let v1 = a in
///     let v2 = super.[](v1) in
///        v2 == null ? super.[]=(v1, b) : null
///
class IfNullSuperIndexSet extends InternalExpression {
  /// The [] member;
  Member? getter;

  /// The []= member;
  Member? setter;

  /// The index expression of the operation.
  Expression index;

  /// The value expression of the operation.
  Expression value;

  /// The file offset for the [] operation.
  final int readOffset;

  /// The file offset for the == operation.
  final int testOffset;

  /// The file offset for the []= operation.
  final int writeOffset;

  /// If `true`, the expression is only need for effect and not for its value.
  final bool forEffect;

  IfNullSuperIndexSet({
    required this.getter,
    required this.setter,
    required this.index,
    required this.value,
    required this.readOffset,
    required this.testOffset,
    required this.writeOffset,
    required this.forEffect,
  }) {
    index.parent = this;
    value.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitIfNullSuperIndexSet(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('super[');
    index.toTextInternal(printer);
    printer.write('] ??= ');
    value.toTextInternal(printer);
  }

  @override
  String toString() {
    return "IfNullSuperIndexSet(${toStringInternal()})";
  }
}

/// Internal expression representing an if-null extension index set expression.
///
/// An if-null super index set expression of the form `E(o)[a] ??= b` is, if
/// used for value, encoded as the expression:
///
///     let v1 = a in
///     let v2 = super.[](v1) in
///       v2 == null
///        ? (let v3 = b in
///           let _ = super.[]=(v1, v3) in
///           v3)
///        : v2
///
/// and, if used for effect, encoded as the expression:
///
///     let v1 = a in
///     let v2 = super.[](v1) in
///        v2 == null ? super.[]=(v1, b) : null
///
class ExtensionIfNullIndexSet extends InternalExpression {
  /// The extension in which the [getter] and [setter] are declared.
  final Extension extension;

  /// The known type arguments for the type parameters declared in
  /// [extension], either explicitly provided like `E<int>(o).a()` or
  /// implied as in `a()` from within the extension `E`.
  final List<DartType>? knownTypeArguments;

  /// The extension receiver;
  Expression receiver;

  /// The [] member;
  Member getter;

  /// The []= member;
  Member setter;

  /// The index expression of the operation.
  Expression index;

  /// The value expression of the operation.
  Expression value;

  /// The file offset for the [] operation.
  final int readOffset;

  /// The file offset for the == operation.
  final int testOffset;

  /// The file offset for the []= operation.
  final int writeOffset;

  /// If `true`, the expression is only need for effect and not for its value.
  final bool forEffect;

  /// `true` if the invocation is null-aware, i.e. of the form
  /// `E(o)?[a] ??= b`.
  final bool isNullAware;

  /// File offset of the explicit extension type arguments, if provided.
  final int? extensionTypeArgumentOffset;

  ExtensionIfNullIndexSet({
    required this.extension,
    required this.knownTypeArguments,
    required this.receiver,
    required this.getter,
    required this.setter,
    required this.index,
    required this.value,
    required this.readOffset,
    required this.testOffset,
    required this.writeOffset,
    required this.forEffect,
    required this.isNullAware,
    required this.extensionTypeArgumentOffset,
  }) : assert(
         knownTypeArguments == null ||
             knownTypeArguments.length == extension.typeParameters.length,
       ) {
    receiver.parent = this;
    index.parent = this;
    value.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitExtensionIfNullIndexSet(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write(extension.name);
    if (knownTypeArguments != null) {
      printer.writeTypeArguments(knownTypeArguments!);
    }
    printer.write('(');
    printer.writeExpression(receiver);
    printer.write(')');
    if (isNullAware) {
      printer.write('?');
    }
    printer.write('[');
    printer.writeExpression(index);
    printer.write(']');
    printer.write(' ??= ');
    printer.writeExpression(value);
  }

  @override
  String toString() {
    return "ExtensionIfNullIndexSet(${toStringInternal()})";
  }
}

/// Internal expression representing a compound index assignment.
///
/// An if-null index assignment of the form `o[a] += b` is, if used for value,
/// encoded as the expression:
///
///     let v1 = o in
///     let v2 = a in
///     let v3 = v1.[](v2) + b
///     let v4 = v1.[]=(v2, c3) in v3
///
/// and, if used for effect, encoded as the expression:
///
///     let v1 = o in let v2 = a in v1.[]=(v2, v1.[](v2) + b)
///
class CompoundIndexSet extends InternalExpression {
  /// The receiver on which the index set operation is performed.
  Expression receiver;

  /// The index expression of the operation.
  Expression index;

  /// The name of the binary operation.
  Name binaryName;

  /// The right-hand side of the binary expression.
  Expression value;

  /// The file offset for the [] operation.
  final int readOffset;

  /// The file offset for the []= operation.
  final int writeOffset;

  /// The file offset for the binary operation.
  final int binaryOffset;

  /// If `true`, the expression is only need for effect and not for its value.
  final bool forEffect;

  /// If `true`, the expression is a post-fix inc/dec expression.
  final bool forPostIncDec;

  /// `true` if the access is null-aware, i.e. of the form `o?[a] += b`.
  final bool isNullAware;

  CompoundIndexSet({
    required this.receiver,
    required this.index,
    required this.binaryName,
    required this.value,
    required this.readOffset,
    required this.binaryOffset,
    required this.writeOffset,
    required this.forEffect,
    required this.forPostIncDec,
    required this.isNullAware,
  }) {
    receiver.parent = this;
    index.parent = this;
    value.parent = this;
    fileOffset = binaryOffset;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitCompoundIndexSet(this, typeContext);
  }

  @override
  String toString() {
    return "CompoundIndexSet(${toStringInternal()})";
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver);
    if (isNullAware) {
      printer.write('?');
    }
    printer.write('[');
    printer.writeExpression(index);
    printer.write(']');
    if (forPostIncDec &&
        (binaryName.text == '+' || binaryName.text == '-') &&
        value is IntLiteral &&
        (value as IntLiteral).value == 1) {
      if (binaryName.text == '+') {
        printer.write('++');
      } else {
        printer.write('--');
      }
    } else {
      printer.write(' ');
      printer.write(binaryName.text);
      printer.write('= ');
      printer.writeExpression(value);
    }
  }
}

/// Internal expression representing a compound super index assignment.
///
/// An if-null index assignment of the form `super[a] += b` is, if used for
/// value, encoded as the expression:
///
///     let v1 = a in
///     let v2 = super.[](v1) + b
///     let v3 = super.[]=(v1, v2) in v2
///
/// and, if used for effect, encoded as the expression:
///
///     let v1 = a in super.[]=(v2, super.[](v2) + b)
///
class CompoundSuperIndexSet extends InternalExpression {
  /// The [] member.
  Member getter;

  /// The []= member.
  Member setter;

  /// The index expression of the operation.
  Expression index;

  /// The name of the binary operation.
  Name binaryName;

  /// The right-hand side of the binary expression.
  Expression value;

  /// The file offset for the [] operation.
  final int readOffset;

  /// The file offset for the []= operation.
  final int writeOffset;

  /// The file offset for the binary operation.
  final int binaryOffset;

  /// If `true`, the expression is only need for effect and not for its value.
  final bool forEffect;

  /// If `true`, the expression is a post-fix inc/dec expression.
  final bool forPostIncDec;

  CompoundSuperIndexSet({
    required this.getter,
    required this.setter,
    required this.index,
    required this.binaryName,
    required this.value,
    required this.readOffset,
    required this.binaryOffset,
    required this.writeOffset,
    required this.forEffect,
    required this.forPostIncDec,
  }) {
    index.parent = this;
    value.parent = this;
    fileOffset = binaryOffset;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitCompoundSuperIndexSet(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('super[');
    printer.writeExpression(index);
    printer.write(']');
    if (forPostIncDec &&
        (binaryName.text == '+' || binaryName.text == '-') &&
        value is IntLiteral &&
        (value as IntLiteral).value == 1) {
      if (binaryName.text == '+') {
        printer.write('++');
      } else {
        printer.write('--');
      }
    } else {
      printer.write(' ');
      printer.write(binaryName.text);
      printer.write('= ');
      printer.writeExpression(value);
    }
  }

  @override
  String toString() {
    return "CompoundSuperIndexSet(${toStringInternal()})";
  }
}

/// Internal expression representing a compound extension index assignment.
///
/// An compound extension index assignment of the form `Extension(o)[a] += b`
/// is, if used for value, encoded as the expression:
///
///     let receiverVariable = o;
///     let indexVariable = a in
///     let valueVariable = receiverVariable.[](indexVariable) + b
///     let writeVariable =
///       receiverVariable.[]=(indexVariable, valueVariable) in
///         valueVariable
///
/// and, if used for effect, encoded as the expression:
///
///     let receiverVariable = o;
///     let indexVariable = a in
///         receiverVariable.[]=(indexVariable,
///             receiverVariable.[](indexVariable) + b)
///
class ExtensionCompoundIndexSet extends InternalExpression {
  /// The extension in which the [getter] and [setter] are declared.
  final Extension extension;

  /// The explicit type arguments for the type parameters declared in
  /// [extension], if provided.
  final TypeArguments? explicitTypeArguments;

  /// The receiver used for the read/write operations.
  Expression receiver;

  /// The [] member.
  Member getter;

  /// The []= member.
  Member setter;

  /// The index expression of the operation.
  Expression index;

  /// The name of the binary operation.
  Name binaryName;

  /// The right-hand side of the binary expression.
  Expression rhs;

  /// The file offset for the [] operation.
  final int readOffset;

  /// The file offset for the []= operation.
  final int writeOffset;

  /// The file offset for the binary operation.
  final int binaryOffset;

  /// If `true`, the expression is only need for effect and not for its value.
  final bool forEffect;

  /// If `true`, the expression is a post-fix inc/dec expression.
  final bool forPostIncDec;

  /// `true` if the access is null-aware, i.e. of the form
  /// `Extension(o)?[a] += b`.
  final bool isNullAware;

  /// File offset of the explicit extension type arguments, if provided.
  final int? extensionTypeArgumentOffset;

  ExtensionCompoundIndexSet({
    required this.extension,
    required this.explicitTypeArguments,
    required this.receiver,
    required this.getter,
    required this.setter,
    required this.index,
    required this.binaryName,
    required this.rhs,
    required this.readOffset,
    required this.binaryOffset,
    required this.writeOffset,
    required this.forEffect,
    required this.forPostIncDec,
    required this.isNullAware,
    required this.extensionTypeArgumentOffset,
  }) : assert(
         explicitTypeArguments == null ||
             explicitTypeArguments.types.length ==
                 extension.typeParameters.length,
       ) {
    receiver.parent = this;
    index.parent = this;
    rhs.parent = this;
    fileOffset = binaryOffset;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitExtensionCompoundIndexSet(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write(extension.name);
    if (explicitTypeArguments != null) {
      printer.writeTypeArguments(explicitTypeArguments!.types);
    }
    printer.write('(');
    printer.writeExpression(receiver);
    printer.write(')');
    if (isNullAware) {
      printer.write('?');
    }
    printer.write('[');
    printer.writeExpression(index);
    printer.write(']');
    if (forPostIncDec) {
      printer.write(binaryName == plusName ? '++' : '--');
    } else {
      printer.write(' ');
      printer.writeName(binaryName);
      printer.write('= ');
      printer.writeExpression(rhs);
    }
  }

  @override
  String toString() {
    return "ExtensionCompoundIndexSet(${toStringInternal()})";
  }
}

/// Internal expression representing a read of an explicit extension getter,
/// for instance `E(o).a` or `a` from within the extension `E`.
///
/// An extension get of the form `E(o).a` is encoded as the static
/// invocation:
///
///     E|a(o)
///
class ExtensionGet extends InternalExpression {
  /// The extension in which the [getter] is declared.
  final Extension extension;

  /// The known type arguments for the type parameters declared in
  /// [extension], either explicitly provided like `E<int>(o).a` or
  /// implied as in `a` from within the extension `E`.
  final List<DartType>? knownTypeArguments;

  /// The receiver for the read.
  Expression receiver;

  /// The name of getter.
  ///
  /// This is the name of the access and _not_ the name of the lowered method.
  final Name name;

  /// The extension member called for the assignment.
  Procedure getter;

  /// `true` if the access is null-aware, i.e. of the form
  /// `Extension(o)?.a`.
  final bool isNullAware;

  /// `true` if the extension access is explicit, i.e. `E(o).a` and
  /// not implicit like `a` inside the extension `E`.
  final bool _isExplicit;

  /// File offset of the explicit extension type arguments, if provided.
  final int? extensionTypeArgumentOffset;

  ExtensionGet.implicit({
    required Extension extension,
    required List<DartType>? thisTypeArguments,
    required Expression thisAccess,
    required Name name,
    required Procedure getter,
  }) : this._(
         extension,
         thisTypeArguments,
         thisAccess,
         name,
         getter,
         isNullAware: false,
         isExplicit: false,
         extensionTypeArgumentOffset: null,
       );

  ExtensionGet.explicit({
    required Extension extension,
    required List<DartType>? explicitTypeArguments,
    required Expression receiver,
    required Name name,
    required Procedure getter,
    required bool isNullAware,
    required int? extensionTypeArgumentOffset,
  }) : this._(
         extension,
         explicitTypeArguments,
         receiver,
         name,
         getter,
         isNullAware: isNullAware,
         isExplicit: true,
         extensionTypeArgumentOffset: extensionTypeArgumentOffset,
       );

  ExtensionGet._(
    this.extension,
    this.knownTypeArguments,
    this.receiver,
    this.name,
    this.getter, {
    required this.isNullAware,
    required bool isExplicit,
    required this.extensionTypeArgumentOffset,
  }) : _isExplicit = isExplicit,
       assert(
         knownTypeArguments == null ||
             extension.typeParameters.isNotEmpty &&
                 knownTypeArguments.length == extension.typeParameters.length,
       ) {
    receiver.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitExtensionGet(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (_isExplicit) {
      printer.write(extension.name);
      if (knownTypeArguments != null) {
        printer.writeTypeArguments(knownTypeArguments!);
      }
      printer.write('(');
      printer.writeExpression(receiver);
      printer.write(')');
    } else {
      printer.writeExpression(receiver);
    }
    if (isNullAware) {
      printer.write('?');
    }
    printer.write('.');
    printer.writeName(name);
  }

  @override
  String toString() {
    return "ExtensionGet(${toStringInternal()})";
  }
}

/// Internal expression representing an assignment to an extension setter.
///
/// An extension set of the form `receiver.target = value` is, if used for
/// value, encoded as the expression:
///
///     let receiverVariable = receiver in
///     let valueVariable = value in
///     let writeVariable = target(receiverVariable, valueVariable) in
///        valueVariable
///
/// or if the receiver is read-only, like `this` or a final variable,
///
///     let valueVariable = value in
///     let writeVariable = target(receiver, valueVariable) in
///        valueVariable
///
/// and, if used for effect, encoded as a [StaticInvocation]:
///
///     target(receiver, value)
///
// TODO(johnniwinther): Rename read-only to side-effect-free.
class ExtensionSet extends InternalExpression {
  /// The extension in which the [setter] is declared.
  final Extension extension;

  /// The known type arguments for the type parameters declared in
  /// [extension], either explicitly provided like `E<int>(o).a = b` or
  /// implied as in `a = b` from within the extension `E`.
  final List<DartType>? knownTypeArguments;

  /// The receiver for the assignment.
  Expression receiver;

  /// The name of setter.
  ///
  /// This is the name of the access and _not_ the name of the lowered method.
  final Name name;

  /// The extension member called for the assignment.
  Procedure setter;

  /// The right-hand side value of the assignment.
  Expression value;

  /// If `true` the assignment is only needed for effect and not its result
  /// value.
  final bool forEffect;

  /// `true` if the access is null-aware, i.e. of the form
  /// `Extension(o)?.a = b`.
  final bool isNullAware;

  /// `true` if the extension access is explicit, i.e. `E(o).a = b` and
  /// not implicit like `a = b` inside the extension `E`.
  final bool _isExplicit;

  /// File offset of the explicit extension type arguments, if provided.
  final int? extensionTypeArgumentOffset;

  ExtensionSet.implicit({
    required Extension extension,
    required List<DartType>? thisTypeArguments,
    required Expression thisAccess,
    required Name name,
    required Procedure setter,
    required Expression value,
    required bool forEffect,
  }) : this._(
         extension,
         thisTypeArguments,
         thisAccess,
         name,
         setter,
         value,
         forEffect: forEffect,
         isNullAware: false,
         isExplicit: false,
         extensionTypeArgumentOffset: null,
       );

  ExtensionSet.explicit({
    required Extension extension,
    required List<DartType>? explicitTypeArguments,
    required Expression receiver,
    required Name name,
    required Procedure setter,
    required Expression value,
    required bool forEffect,
    required bool isNullAware,
    required int? extensionTypeArgumentOffset,
  }) : this._(
         extension,
         explicitTypeArguments,
         receiver,
         name,
         setter,
         value,
         forEffect: forEffect,
         isNullAware: isNullAware,
         isExplicit: true,
         extensionTypeArgumentOffset: extensionTypeArgumentOffset,
       );

  ExtensionSet._(
    this.extension,
    this.knownTypeArguments,
    this.receiver,
    this.name,
    this.setter,
    this.value, {
    required this.forEffect,
    required this.isNullAware,
    required bool isExplicit,
    required this.extensionTypeArgumentOffset,
  }) : _isExplicit = isExplicit,
       assert(
         knownTypeArguments == null ||
             extension.typeParameters.isNotEmpty &&
                 knownTypeArguments.length == extension.typeParameters.length,
       ) {
    receiver.parent = this;
    value.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitExtensionSet(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (_isExplicit) {
      printer.write(extension.name);
      if (knownTypeArguments != null) {
        printer.writeTypeArguments(knownTypeArguments!);
      }
      printer.write('(');
      printer.writeExpression(receiver);
      printer.write(')');
    } else {
      printer.writeExpression(receiver);
    }
    if (isNullAware) {
      printer.write('?');
    }
    printer.write('.');
    printer.writeName(name);
    printer.write(' = ');
    printer.writeExpression(value);
  }

  @override
  String toString() {
    return "ExtensionSet(${toStringInternal()})";
  }
}

/// Internal expression representing an invocation of an extension method.
///
/// An extension get of the form `receiver.target(arguments)` is encoded as the
/// static invocation:
///
///     target(receiver, arguments)
///
class ExtensionMethodInvocation extends InternalExpression {
  /// The extension in which the [method] is declared.
  final Extension extension;

  /// The known type arguments for the type parameters declared in
  /// [extension], either explicitly provided like `E<int>(o).a()` or
  /// implied as in `a()` from within the extension `E`.
  final List<DartType>? knownTypeArguments;

  /// The receiver for the invocation.
  Expression receiver;

  /// The name of method.
  ///
  /// This is the name of the access and _not_ the name of the lowered method.
  final Name name;

  /// The extension method called for the assignment.
  Procedure method;

  /// The type arguments provided to the method, if any.
  final TypeArguments? typeArguments;

  /// The arguments provided to the method.
  ActualArguments arguments;

  /// `true` if the extension access is explicit, i.e. `E(o).a()` and
  /// not implicit like `a()` inside the extension `E`.
  final bool _isExplicit;

  /// `true` if the invocation is null-aware, i.e. of the form
  /// `Extension(o)?.a()`.
  final bool isNullAware;

  /// File offset of the explicit extension type arguments, if provided.
  final int? extensionTypeArgumentOffset;

  ExtensionMethodInvocation.implicit({
    required Extension extension,
    required List<DartType>? thisTypeArguments,
    required Expression thisAccess,
    required Name name,
    required Procedure target,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
  }) : this._(
         extension,
         thisAccess,
         name,
         target,
         typeArguments,
         arguments,
         isExplicit: false,
         knownTypeArguments: thisTypeArguments,
         extensionTypeArgumentOffset: null,
         isNullAware: false,
       );

  ExtensionMethodInvocation.explicit({
    required Extension extension,
    required Expression receiver,
    required Name name,
    required Procedure target,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    required List<DartType>? explicitTypeArguments,
    required int? extensionTypeArgumentOffset,
    required bool isNullAware,
  }) : this._(
         extension,
         receiver,
         name,
         target,
         typeArguments,
         arguments,
         isExplicit: true,
         knownTypeArguments: explicitTypeArguments,
         extensionTypeArgumentOffset: extensionTypeArgumentOffset,
         isNullAware: isNullAware,
       );

  ExtensionMethodInvocation._(
    this.extension,
    this.receiver,
    this.name,
    this.method,
    this.typeArguments,
    this.arguments, {
    required this.knownTypeArguments,
    required bool isExplicit,
    required this.isNullAware,
    required this.extensionTypeArgumentOffset,
  }) : _isExplicit = isExplicit,
       assert(
         knownTypeArguments == null ||
             extension.typeParameters.isNotEmpty &&
                 knownTypeArguments.length == extension.typeParameters.length,
       ) {
    receiver.parent = this;
    arguments.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitExtensionMethodInvocation(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (_isExplicit) {
      printer.write(extension.name);
      if (knownTypeArguments != null) {
        printer.writeTypeArguments(knownTypeArguments!);
      }
      printer.write('(');
      printer.writeExpression(receiver);
      printer.write(')');
    } else {
      printer.writeExpression(receiver);
    }
    if (isNullAware) {
      printer.write('?');
    }
    printer.write('.');
    printer.writeName(name);
    typeArguments?.toText(printer);
    arguments.toTextInternal(printer);
  }

  @override
  String toString() {
    return "ExtensionMethodInvocation(${toStringInternal()})";
  }
}

/// Internal expression representing an invocation of an explicit extension
/// method, for instance `E(o).a()` or `a()` from within the extension `E`.
///
/// An extension get of the form `E(o).a(b)` is encoded as the static
/// invocation:
///
///     E|a(o, b)
///
class ExtensionGetterInvocation extends InternalExpression {
  /// The extension in which the [getter] is declared.
  final Extension extension;

  /// The known type arguments for the type parameters declared in
  /// [extension], either explicitly provided like `E<int>(o).a()` or
  /// implied as in `a()` from within the extension `E`.
  final List<DartType>? knownTypeArguments;

  /// The receiver for the invocation.
  Expression receiver;

  /// The name of getter.
  ///
  /// This is the name of the access and _not_ the name of the lowered method.
  final Name name;

  /// The extension getter called for the assignment.
  Procedure getter;

  /// The type arguments provided to the getter, if any.
  final TypeArguments? typeArguments;

  /// The arguments provided to the getter.
  ActualArguments arguments;

  /// `true` if the extension access is explicit, i.e. `E(o).a()` and
  /// not implicit like `a()` inside the extension `E`.
  final bool _isExplicit;

  /// `true` if the invocation is null-aware, i.e. of the form
  /// `Extension(o)?.a()`.
  final bool isNullAware;

  /// File offset of the explicit extension type arguments, if provided.
  final int? extensionTypeArgumentOffset;

  ExtensionGetterInvocation.implicit({
    required Extension extension,
    required List<DartType>? thisTypeArguments,
    required Expression thisAccess,
    required Name name,
    required Procedure target,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
  }) : this._(
         extension,
         thisAccess,
         name,
         target,
         typeArguments,
         arguments,
         isExplicit: false,
         knownTypeArguments: thisTypeArguments,
         extensionTypeArgumentOffset: null,
         isNullAware: false,
       );

  ExtensionGetterInvocation.explicit({
    required Extension extension,
    required Expression receiver,
    required Name name,
    required Procedure target,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    required List<DartType>? explicitTypeArguments,
    required int? extensionTypeArgumentOffset,
    required bool isNullAware,
  }) : this._(
         extension,
         receiver,
         name,
         target,
         typeArguments,
         arguments,
         isExplicit: true,
         knownTypeArguments: explicitTypeArguments,
         extensionTypeArgumentOffset: extensionTypeArgumentOffset,
         isNullAware: isNullAware,
       );

  ExtensionGetterInvocation._(
    this.extension,
    this.receiver,
    this.name,
    this.getter,
    this.typeArguments,
    this.arguments, {
    required this.knownTypeArguments,
    required bool isExplicit,
    required this.isNullAware,
    required this.extensionTypeArgumentOffset,
  }) : _isExplicit = isExplicit,
       assert(
         knownTypeArguments == null ||
             extension.typeParameters.isNotEmpty &&
                 knownTypeArguments.length == extension.typeParameters.length,
       ) {
    receiver.parent = this;
    arguments.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitExtensionGetterInvocation(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (_isExplicit) {
      printer.write(extension.name);
      if (knownTypeArguments != null) {
        printer.writeTypeArguments(knownTypeArguments!);
      }
      printer.write('(');
      printer.writeExpression(receiver);
      printer.write(')');
    } else {
      printer.writeExpression(receiver);
    }
    if (isNullAware) {
      printer.write('?');
    }
    printer.write('.');
    printer.writeName(name);
    typeArguments?.toText(printer);
    arguments.toTextInternal(printer);
  }

  @override
  String toString() {
    return "ExtensionGetterInvocation(${toStringInternal()})";
  }
}

/// Internal representation of a tear-foo of an extension instance method.
///
/// A tear-off of an extension instance member `o.foo()` is encoded as the
/// [StaticInvocation]
///
///     extension|get#foo(o)
///
/// where `extension|get#foo` is the top level method created for tearing off
/// the `foo` method.
class ExtensionTearOff extends InternalExpression {
  /// The extension in which the [method] is declared.
  final Extension extension;

  /// The known type arguments for the type parameters declared in
  /// [extension], either explicitly provided like `E<int>(o).a` or
  /// implied as in `a` from within the extension `E`.
  final List<DartType>? knownTypeArguments;

  /// The receiver for the tear-off.
  Expression receiver;

  /// The name of method.
  ///
  /// This is the name of the access and _not_ the name of the lowered method.
  final Name name;

  /// The top-level method that is that target for the read operation.
  Procedure tearOff;

  /// `true` if the access is null-aware, i.e. of the form `Extension(o)?.a`.
  final bool isNullAware;

  /// `true` if the extension access is explicit, i.e. `E(o).a` and
  /// not implicit like `a` inside the extension `E`.
  final bool _isExplicit;

  /// File offset of the explicit extension type arguments, if provided.
  final int? extensionTypeArgumentOffset;

  ExtensionTearOff.implicit({
    required Extension extension,
    required List<DartType>? thisTypeArguments,
    required Expression thisAccess,
    required Name name,
    required Procedure tearOff,
  }) : this._(
         extension,
         thisTypeArguments,
         thisAccess,
         name,
         tearOff,
         isNullAware: false,
         isExplicit: false,
         extensionTypeArgumentOffset: null,
       );

  ExtensionTearOff.explicit({
    required Extension extension,
    required List<DartType>? explicitTypeArguments,
    required Expression receiver,
    required Name name,
    required Procedure tearOff,
    required bool isNullAware,
    required int? extensionTypeArgumentOffset,
  }) : this._(
         extension,
         explicitTypeArguments,
         receiver,
         name,
         tearOff,
         isNullAware: isNullAware,
         isExplicit: true,
         extensionTypeArgumentOffset: extensionTypeArgumentOffset,
       );

  ExtensionTearOff._(
    this.extension,
    this.knownTypeArguments,
    this.receiver,
    this.name,
    this.tearOff, {
    required this.isNullAware,
    required bool isExplicit,
    required this.extensionTypeArgumentOffset,
  }) : _isExplicit = isExplicit,
       assert(
         knownTypeArguments == null ||
             extension.typeParameters.isNotEmpty &&
                 knownTypeArguments.length == extension.typeParameters.length,
       ) {
    receiver.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitExtensionTearOff(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (_isExplicit) {
      printer.write(extension.name);
      if (knownTypeArguments != null) {
        printer.writeTypeArguments(knownTypeArguments!);
      }
      printer.write('(');
      printer.writeExpression(receiver);
      printer.write(')');
    } else {
      printer.writeExpression(receiver);
    }
    if (isNullAware) {
      printer.write('?');
    }
    printer.write('.');
    printer.writeName(name);
  }

  @override
  String toString() {
    return "ExtensionTearOff(${toStringInternal()})";
  }
}

/// Internal expression for an equals or not-equals expression.
class EqualsExpression extends InternalExpression {
  Expression left;
  Expression right;
  bool isNot;

  EqualsExpression(this.left, this.right, {required this.isNot}) {
    left.parent = this;
    right.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitEquals(this, typeContext);
  }

  @override
  String toString() {
    return "EqualsExpression(${toStringInternal()})";
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(left, minimumPrecedence: Precedence.EQUALITY);
    if (isNot) {
      printer.write(' != ');
    } else {
      printer.write(' == ');
    }
    printer.writeExpression(right, minimumPrecedence: Precedence.EQUALITY + 1);
  }
}

/// Internal expression for a binary expression.
class BinaryExpression extends InternalExpression {
  Expression left;
  Name binaryName;
  Expression right;

  BinaryExpression(this.left, this.binaryName, this.right) {
    left.parent = this;
    right.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitBinary(this, typeContext);
  }

  @override
  String toString() {
    return "BinaryExpression(${toStringInternal()})";
  }

  @override
  // Coverage-ignore(suite): Not run.
  int get precedence => Precedence.binaryPrecedence[binaryName.text]!;

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(left, minimumPrecedence: precedence);
    printer.write(' ${binaryName.text} ');
    printer.writeExpression(right, minimumPrecedence: precedence);
  }
}

/// Internal expression for a unary expression.
class UnaryExpression extends InternalExpression {
  Name unaryName;
  Expression expression;

  UnaryExpression(this.unaryName, this.expression) {
    expression.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitUnary(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  int get precedence => Precedence.PREFIX;

  @override
  String toString() {
    return "UnaryExpression(${toStringInternal()})";
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (unaryName == unaryMinusName) {
      printer.write('-');
    } else {
      printer.write('${unaryName.text}');
    }
    printer.writeExpression(expression, minimumPrecedence: precedence);
  }
}

/// Internal expression for a parenthesized expression.
class ParenthesizedExpression extends InternalExpression {
  Expression expression;

  ParenthesizedExpression(this.expression) {
    expression.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitParenthesized(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  int get precedence => Precedence.CALLEE;

  @override
  String toString() {
    return "ParenthesizedExpression(${toStringInternal()})";
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('(');
    printer.writeExpression(expression);
    printer.write(')');
  }
}

/// Returns `true` if [node] is a pure expression.
///
/// A pure expression is an expression that is deterministic and side effect
/// free, such as `this` or a variable get of a final variable.
bool isPureExpression(Expression node) {
  if (node is ThisExpression) {
    return true;
  } else if (node is VariableGet) {
    return node.expressionVariable.isFinal && !node.expressionVariable.isLate;
  }
  return false;
}

/// Returns a clone of [node].
///
/// This assumes that `isPureExpression(node)` is `true`.
Expression clonePureExpression(Expression node) {
  if (node is ThisExpression) {
    return new ThisExpression()..fileOffset = node.fileOffset;
  } else if (node is VariableGet) {
    assert(
      node.variable.isFinal && !node.variable.isLate,
      "Trying to clone VariableGet of non-final variable"
      " ${node.variable}.",
    );
    return new VariableGet(node.variable, node.promotedType)
      ..fileOffset = node.fileOffset;
  }
  // Coverage-ignore-block(suite): Not run.
  throw new UnsupportedError("Clone not supported for ${node.runtimeType}.");
}

/// A dynamically bound method invocation of the form `o.a()`.
///
/// This will be transformed into an [InstanceInvocation], [DynamicInvocation],
/// [FunctionInvocation] or [StaticInvocation] (for implicit extension method
/// invocation) after type inference.
class MethodInvocation extends InternalExpression {
  /// The receiver of the invocation.
  Expression receiver;

  /// The name of the invoked method or property.
  Name name;

  /// The type arguments applied at the invocation, if any.
  final TypeArguments? typeArguments;

  /// The arguments applied at the invocation.
  ActualArguments arguments;

  /// `true` if the access is null-aware, i.e. of the form `o?.a()`.
  final bool isNullAware;

  MethodInvocation(
    this.receiver,
    this.name,
    this.typeArguments,
    this.arguments, {
    required this.isNullAware,
  }) {
    receiver.parent = this;
    arguments.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitMethodInvocation(this, typeContext);
  }

  @override
  String toString() {
    return "MethodInvocation(${toStringInternal()})";
  }

  @override
  // Coverage-ignore(suite): Not run.
  int get precedence => Precedence.PRIMARY;

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver, minimumPrecedence: Precedence.PRIMARY);
    if (isNullAware) {
      printer.write('?');
    }
    printer.write('.');
    printer.writeName(name);
    typeArguments?.toText(printer);
    arguments.toTextInternal(printer);
  }
}

/// A dynamically bound property read of the form `o.a`.
///
/// This will be transformed into an [InstanceGet], [InstanceTearOff],
/// [DynamicGet], [FunctionTearOff] or [StaticInvocation] (for implicit
/// extension member access) after type inference.
class PropertyGet extends InternalExpression {
  /// The receiver of the property access.
  Expression receiver;

  /// The name of the accessed property.
  final Name name;

  /// `true` if the access is null-aware, i.e. of the form `o?.a`.
  final bool isNullAware;

  PropertyGet(this.receiver, this.name, {required this.isNullAware}) {
    receiver.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitPropertyGet(this, typeContext);
  }

  @override
  String toString() {
    return "PropertyGet(${toStringInternal()})";
  }

  @override
  // Coverage-ignore(suite): Not run.
  int get precedence => Precedence.PRIMARY;

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver, minimumPrecedence: Precedence.PRIMARY);
    if (isNullAware) {
      printer.write('?');
    }
    printer.write('.');
    printer.writeName(name);
  }
}

/// A dynamically bound property write of the form `o.a = b`.
///
/// This will be transformed into an [InstanceSet], [DynamicSet], or
/// [StaticInvocation] (for implicit extension member access) after type
/// inference.
class PropertySet extends InternalExpression {
  /// The receiver of the assigned property.
  Expression receiver;

  /// The name of the assigned property.
  Name name;

  /// The value assigned to the property.
  Expression value;

  /// If `true` the assignment is need for its effect and not for its value.
  final bool forEffect;

  /// If `true` the receiver can be cloned and doesn't need a temporary variable
  /// for multiple reads.
  final bool readOnlyReceiver;

  /// `true` if the access is null-aware, i.e. of the form `o?.a = b`.
  final bool isNullAware;

  PropertySet(
    this.receiver,
    this.name,
    this.value, {
    required this.forEffect,
    required this.readOnlyReceiver,
    required this.isNullAware,
  }) {
    receiver.parent = this;
    value.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitPropertySet(this, typeContext);
  }

  @override
  String toString() {
    return "PropertySet(${toStringInternal()})";
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver, minimumPrecedence: Precedence.PRIMARY);
    if (isNullAware) {
      printer.write('?');
    }
    printer.write('.');
    printer.writeName(name);
    printer.write(' = ');
    printer.writeExpression(value);
  }
}

// Coverage-ignore(suite): Not run.
/// An augment super invocation of the form `augment super()`.
///
/// This will be transformed into an [InstanceInvocation], [InstanceGet] plus
/// [FunctionInvocation], or [StaticInvocation] after type inference.
class AugmentSuperInvocation extends InternalExpression {
  final Member target;

  final TypeArguments? typeArguments;

  ActualArguments arguments;

  AugmentSuperInvocation(
    this.target,
    this.typeArguments,
    this.arguments, {
    required int fileOffset,
  }) {
    arguments.parent = this;
    this.fileOffset = fileOffset;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitAugmentSuperInvocation(this, typeContext);
  }

  @override
  String toString() {
    return "AugmentSuperInvocation(${toStringInternal()})";
  }

  @override
  int get precedence => Precedence.PRIMARY;

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('augment super');
    typeArguments?.toText(printer);
    arguments.toTextInternal(printer);
  }
}

// Coverage-ignore(suite): Not run.
/// An augment super read of the form `augment super`.
///
/// This will be transformed into an [InstanceGet], [InstanceTearOff],
/// [DynamicGet], [FunctionTearOff] or [StaticInvocation] (for implicit
/// extension member access) after type inference.
class AugmentSuperGet extends InternalExpression {
  final Member target;

  AugmentSuperGet(this.target, {required int fileOffset}) {
    this.fileOffset = fileOffset;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitAugmentSuperGet(this, typeContext);
  }

  @override
  String toString() {
    return "AugmentSuperGet(${toStringInternal()})";
  }

  @override
  int get precedence => Precedence.PRIMARY;

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('augment super');
  }
}

// Coverage-ignore(suite): Not run.
/// An augment super write of the form `augment super = e`.
///
/// This will be transformed into an [InstanceSet], or [StaticSet] after type
/// inference.
class AugmentSuperSet extends InternalExpression {
  final Member target;

  Expression value;

  /// If `true` the assignment is need for its effect and not for its value.
  final bool forEffect;

  AugmentSuperSet(
    this.target,
    this.value, {
    required this.forEffect,
    required int fileOffset,
  }) {
    value.parent = this;
    this.fileOffset = fileOffset;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitAugmentSuperSet(this, typeContext);
  }

  @override
  String toString() {
    return "AugmentSuperSet(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('augment super = ');
    printer.writeExpression(value);
  }
}

class InternalRecordLiteral extends InternalExpression {
  final List<Expression> positional;
  final List<NamedExpression> named;
  final Map<String, NamedExpression>? namedElements;
  final List<Object /*Expression|NamedExpression*/> originalElementOrder;
  final bool isConst;

  InternalRecordLiteral(
    this.positional,
    this.named,
    this.namedElements,
    this.originalElementOrder, {
    required this.isConst,
    required int offset,
  }) {
    fileOffset = offset;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalRecordLiteral(this, typeContext);
  }

  @override
  String toString() {
    return "InternalRecordLiteral(${toStringInternal()})";
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (isConst) {
      printer.write('const ');
    }
    printer.write('(');
    String comma = '';
    for (Object element in originalElementOrder) {
      printer.write(comma);
      if (element is NamedExpression) {
        printer.write(element.name);
        printer.write(': ');
        printer.writeExpression(element.value);
      } else {
        printer.writeExpression(element as Expression);
      }
      comma = ', ';
    }
    printer.write(')');
  }
}

/// Data structure used by the body builder in place of [ObjectPattern], to
/// allow additional information to be captured that is needed during type
/// inference.
class ObjectPatternInternal extends ObjectPattern {
  /// If the type name in the object pattern refers to a typedef, the typedef in
  /// question; otherwise `null`.
  final Typedef? typedef;

  /// Indicates whether the object pattern included explicit type arguments; if
  /// `true` this means that no further type inference needs to be performed.
  final bool hasExplicitTypeArguments;

  ObjectPatternInternal(
    super.requiredType,
    super.fields,
    this.typedef, {
    required this.hasExplicitTypeArguments,
  });
}

class ExtensionTypeRedirectingInitializer extends InternalInitializer {
  Reference targetReference;
  ActualArguments arguments;

  /// Redirecting initializers are encoded as calls to top-level functions.
  /// The type arguments for this call are inferred.
  List<DartType> inferredTypeArguments = [];

  List<Expression> positional = [];
  List<NamedExpression> named = [];

  ExtensionTypeRedirectingInitializer(
    Procedure target,
    ActualArguments arguments,
  ) : this.byReference(
        // Getter vs setter doesn't matter for procedures.
        getNonNullableMemberReferenceGetter(target),
        arguments,
      );

  ExtensionTypeRedirectingInitializer.byReference(
    this.targetReference,
    this.arguments,
  ) {
    arguments.parent = this;
  }

  Procedure get target => targetReference.asProcedure;

  // Coverage-ignore(suite): Not run.
  void set target(Procedure target) {
    // Getter vs setter doesn't matter for procedures.
    targetReference = getNonNullableMemberReferenceGetter(target);
  }

  @override
  InitializerInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitExtensionTypeRedirectingInitializer(this);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('this');
    if (target.name.text.isNotEmpty) {
      printer.write('.');
      printer.write(target.name.text);
    }
    arguments.toTextInternal(printer);
  }

  @override
  String toString() =>
      'ExtensionTypeRedirectingInitializer(${toStringInternal()})';
}

/// Internal expression for an explicit initialization of an extension type
/// declaration representation field.
class ExtensionTypeRepresentationFieldInitializer extends InternalInitializer {
  Reference fieldReference;
  Expression value;

  ExtensionTypeRepresentationFieldInitializer(Procedure field, this.value)
    : assert(field.stubKind == ProcedureStubKind.RepresentationField),
      this.fieldReference = field.reference {
    value.parent = this;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void transformChildren(Transformer v) {
    value = v.transform(value)..parent = this;
  }

  /// [Procedure] that represents the representation field.
  Procedure get field => fieldReference.asProcedure;

  @override
  InitializerInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitExtensionTypeRepresentationFieldInitializer(this);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeMemberName(fieldReference);
    printer.write(" = ");
    printer.writeExpression(value);
  }

  @override
  String toString() =>
      'ExtensionTypeRepresentationFieldInitializer(${toStringInternal()})';
}

/// Internal expression for a dot shorthand.
///
/// This node wraps around the [innerExpression] and indicates to the
/// [InferenceVisitor] that we need to save the context type of the expression.
class DotShorthand extends InternalExpression {
  /// The entire dot shorthand expression (e.g. `.zero` or `.parse(input)`).
  Expression innerExpression;

  DotShorthand(this.innerExpression);

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitDotShorthand(this, typeContext);
  }

  @override
  String toString() {
    return "DotShorthand(${toStringInternal()})";
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(innerExpression);
  }
}

/// Internal expression for a dot shorthand head with arguments.
/// (e.g. `.parse(42)`).
///
/// This node could represent a shorthand of a static method or a named
/// constructor.
class DotShorthandInvocation extends InternalExpression {
  final Name name;
  final int nameOffset;
  final TypeArguments? typeArguments;
  final ActualArguments arguments;

  /// If `true`, this invocation is constant, either explicit or inferred.
  final bool isConst;

  DotShorthandInvocation(
    this.name,
    this.typeArguments,
    this.arguments, {
    required this.nameOffset,
    required this.isConst,
  });

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitDotShorthandInvocation(this, typeContext);
  }

  @override
  String toString() {
    return "DotShorthandInvocation(${toStringInternal()})";
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (isConst) {
      printer.write('const ');
    }
    printer.write('.');
    printer.writeName(name);
    typeArguments?.toText(printer);
    arguments.toTextInternal(printer);
  }
}

/// Internal expression for a dot shorthand head with no arguments.
/// (e.g. `.zero`).
///
/// This node could represent a shorthand of a static get or a tearoff.
class DotShorthandPropertyGet extends InternalExpression {
  final Name name;
  final int nameOffset;

  /// Whether this dot shorthand has type parameters.
  ///
  /// Used for error checking for constructors with type parameters in the
  /// [InferenceVisitor].
  bool hasTypeParameters;

  DotShorthandPropertyGet(
    this.name, {
    required this.nameOffset,
    this.hasTypeParameters = false,
  });

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitDotShorthandPropertyGet(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('.');
    printer.writeName(name);
  }

  @override
  String toString() {
    return "DotShorthandPropertyGet(${toStringInternal()})";
  }
}

class InternalConstructorInvocation extends InternalExpression {
  final Constructor target;
  final TypeArguments? typeArguments;
  final ActualArguments arguments;
  final bool isConst;

  InternalConstructorInvocation(
    this.target,
    this.typeArguments,
    this.arguments, {
    required this.isConst,
  }) {
    arguments.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalConstructorInvocation(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (isConst) {
      printer.write('const ');
    } else {
      printer.write('new ');
    }
    printer.writeClassName(target.enclosingClass.reference);
    typeArguments?.toText(printer);
    if (target.name.text.isNotEmpty) {
      printer.write('.');
      printer.write(target.name.text);
    }
    arguments.toTextInternal(printer);
  }

  @override
  String toString() {
    return "InternalConstructorInvocation(${toStringInternal()})";
  }
}

class InternalStaticInvocation extends InternalExpression {
  final Name name;
  final Procedure target;
  final TypeArguments? typeArguments;
  final ActualArguments arguments;

  InternalStaticInvocation(
    this.name,
    this.target,
    this.typeArguments,
    this.arguments,
  ) {
    arguments.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalStaticInvocation(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeName(name);
    typeArguments?.toText(printer);
    arguments.toTextInternal(printer);
  }

  @override
  String toString() {
    return "InternalStaticInvocation(${toStringInternal()})";
  }
}

class InternalSuperMethodInvocation extends InternalExpression {
  final Name name;
  final Procedure target;
  final TypeArguments? typeArguments;
  final ActualArguments arguments;

  InternalSuperMethodInvocation(
    this.name,
    this.typeArguments,
    this.arguments,
    this.target,
  ) {
    arguments.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalSuperMethodInvocation(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('super.');
    printer.writeName(name);
    typeArguments?.toText(printer);
    arguments.toTextInternal(printer);
  }

  @override
  String toString() {
    return "InternalSuperMethodInvocation(${toStringInternal()})";
  }
}

class InternalRedirectingInitializer extends InternalInitializer {
  final Constructor target;
  ActualArguments arguments;

  InternalRedirectingInitializer(this.target, this.arguments) {
    arguments.parent = this;
  }

  @override
  InitializerInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitInternalRedirectingInitializer(this);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('this');
    if (target.name.text.isNotEmpty) {
      printer.write('.');
      printer.write(target.name.text);
    }
    arguments.toTextInternal(printer);
  }

  @override
  String toString() {
    return "InternalRedirectingInitializer(${toStringInternal()})";
  }
}

class InternalSuperInitializer extends InternalInitializer {
  final Constructor target;
  ActualArguments arguments;

  @override
  final bool isSynthetic;

  InternalSuperInitializer(
    this.target,
    this.arguments, {
    required this.isSynthetic,
  }) {
    arguments.parent = this;
  }

  @override
  InitializerInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitInternalSuperInitializer(this);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('super');
    if (target.name.text.isNotEmpty) {
      printer.write('.');
      printer.write(target.name.text);
    }
    arguments.toTextInternal(printer);
  }

  @override
  String toString() {
    return "InternalSuperInitializer(${toStringInternal()})";
  }
}
