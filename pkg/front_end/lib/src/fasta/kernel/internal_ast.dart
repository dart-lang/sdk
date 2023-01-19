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
import 'package:kernel/ast.dart';
import 'package:kernel/clone.dart';
import 'package:kernel/src/bounds_checks.dart';
import 'package:kernel/src/printer.dart';
import 'package:kernel/text/ast_to_text.dart' show Precedence, Printer;
import 'package:kernel/type_environment.dart';

import 'package:_fe_analyzer_shared/src/type_inference/type_analysis_result.dart'
    as shared;

import '../builder/type_alias_builder.dart';
import '../fasta_codes.dart';
import '../names.dart';
import '../problems.dart' show unsupported;
import '../type_inference/external_ast_helper.dart';
import '../type_inference/inference_visitor.dart';
import '../type_inference/inference_visitor_base.dart';
import '../type_inference/inference_results.dart';
import '../type_inference/object_access_target.dart';
import '../type_inference/type_schema.dart' show UnknownType;

typedef SharedMatchContext = shared
    .MatchContext<Node, Expression, Pattern, DartType, VariableDeclaration>;

int getExtensionTypeParameterCount(Arguments arguments) {
  if (arguments is ArgumentsImpl) {
    return arguments._extensionTypeParameterCount;
  } else {
    // TODO(johnniwinther): Remove this path or assert why it is accepted.
    return 0;
  }
}

int getExtensionTypeArgumentCount(Arguments arguments) {
  if (arguments is ArgumentsImpl) {
    return arguments._explicitExtensionTypeArgumentCount;
  } else {
    // TODO(johnniwinther): Remove this path or assert why it is accepted.
    return 0;
  }
}

List<DartType>? getExplicitExtensionTypeArguments(Arguments arguments) {
  if (arguments is ArgumentsImpl) {
    if (arguments._explicitExtensionTypeArgumentCount == 0) {
      return null;
    } else {
      return arguments.types
          .take(arguments._explicitExtensionTypeArgumentCount)
          .toList();
    }
  } else {
    // TODO(johnniwinther): Remove this path or assert why it is accepted.
    return null;
  }
}

/// Information about explicit/implicit type arguments used for error
/// reporting.
abstract class TypeArgumentsInfo {
  const TypeArgumentsInfo();

  /// Returns `true` if the [index]th type argument was inferred.
  bool isInferred(int index);

  /// Returns the offset to use when reporting an error on the [index]th type
  /// arguments, using [offset] as the default offset.
  int getOffsetForIndex(int index, int offset) => offset;
}

class AllInferredTypeArgumentsInfo extends TypeArgumentsInfo {
  const AllInferredTypeArgumentsInfo();

  @override
  bool isInferred(int index) => true;
}

class NoneInferredTypeArgumentsInfo extends TypeArgumentsInfo {
  const NoneInferredTypeArgumentsInfo();

  @override
  bool isInferred(int index) => false;
}

class ExtensionMethodTypeArgumentsInfo implements TypeArgumentsInfo {
  final ArgumentsImpl arguments;

  ExtensionMethodTypeArgumentsInfo(this.arguments);

  @override
  bool isInferred(int index) {
    if (index < arguments._extensionTypeParameterCount) {
      // The index refers to a type argument for a type parameter declared on
      // the extension. Check whether we have enough explicit extension type
      // arguments.
      return index >= arguments._explicitExtensionTypeArgumentCount;
    }
    // The index refers to a type argument for a type parameter declared on
    // the method. Check whether we have enough explicit regular type arguments.
    return index - arguments._extensionTypeParameterCount >=
        arguments._explicitTypeArgumentCount;
  }

  @override
  int getOffsetForIndex(int index, int offset) {
    if (index < arguments._extensionTypeParameterCount) {
      return arguments._extensionTypeArgumentOffset ?? offset;
    }
    return offset;
  }
}

TypeArgumentsInfo getTypeArgumentsInfo(Arguments arguments) {
  if (arguments is ArgumentsImpl) {
    if (arguments._extensionTypeParameterCount == 0) {
      return arguments._explicitTypeArgumentCount == 0
          ? const AllInferredTypeArgumentsInfo()
          : const NoneInferredTypeArgumentsInfo();
    } else {
      return new ExtensionMethodTypeArgumentsInfo(arguments);
    }
  } else {
    // This code path should only be taken in situations where there are no
    // type arguments at all, e.g. calling a user-definable operator.
    assert(arguments.types.isEmpty);
    return const NoneInferredTypeArgumentsInfo();
  }
}

List<DartType>? getExplicitTypeArguments(Arguments arguments) {
  if (arguments is ArgumentsImpl) {
    if (arguments._explicitTypeArgumentCount == 0) {
      return null;
    } else if (arguments._extensionTypeParameterCount == 0) {
      return arguments.types;
    } else {
      return arguments.types
          .skip(arguments._extensionTypeParameterCount)
          .toList();
    }
  } else {
    // This code path should only be taken in situations where there are no
    // type arguments at all, e.g. calling a user-definable operator.
    assert(arguments.types.isEmpty);
    return null;
  }
}

bool hasExplicitTypeArguments(Arguments arguments) {
  return getExplicitTypeArguments(arguments) != null;
}

mixin InternalTreeNode implements TreeNode {
  @override
  void replaceChild(TreeNode child, TreeNode replacement) {
    // Do nothing. The node should not be part of the resulting AST, anyway.
  }

  @override
  R accept<R>(TreeVisitor<R> visitor) {
    if (visitor is Printer || visitor is Precedence || visitor is Transformer) {
      // Allow visitors needed for toString and replaceWith.
      return visitor.defaultTreeNode(this);
    }
    return unsupported(
        "${runtimeType}.accept on ${visitor.runtimeType}", -1, null);
  }

  @override
  R accept1<R, A>(TreeVisitor1<R, A> visitor, A arg) {
    return unsupported(
        "${runtimeType}.accept1 on ${visitor.runtimeType}", -1, null);
  }

  @override
  void transformChildren(Transformer v) {
    unsupported(
        "${runtimeType}.transformChildren on ${v.runtimeType}", -1, null);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    unsupported("${runtimeType}.transformOrRemoveChildren on ${v.runtimeType}",
        -1, null);
  }

  @override
  void visitChildren(Visitor v) {
    unsupported("${runtimeType}.visitChildren on ${v.runtimeType}", -1, null);
  }
}

/// Common base class for internal statements.
abstract class InternalStatement extends Statement {
  @override
  void replaceChild(TreeNode child, TreeNode replacement) {
    // Do nothing. The node should not be part of the resulting AST, anyway.
  }

  @override
  R accept<R>(StatementVisitor<R> visitor) {
    if (visitor is Printer || visitor is Precedence) {
      // Allow visitors needed for toString.
      return visitor.defaultStatement(this);
    }
    return unsupported("${runtimeType}.accept", -1, null);
  }

  @override
  R accept1<R, A>(StatementVisitor1<R, A> visitor, A arg) =>
      unsupported("${runtimeType}.accept1", -1, null);

  @override
  void transformChildren(Transformer v) => unsupported(
      "${runtimeType}.transformChildren on ${v.runtimeType}", -1, null);

  @override
  void transformOrRemoveChildren(RemovingTransformer v) => unsupported(
      "${runtimeType}.transformOrRemoveChildren on ${v.runtimeType}", -1, null);

  @override
  void visitChildren(Visitor v) =>
      unsupported("${runtimeType}.visitChildren on ${v.runtimeType}", -1, null);

  StatementInferenceResult acceptInference(InferenceVisitorImpl visitor);
}

class ForInStatementWithSynthesizedVariable extends InternalStatement {
  VariableDeclaration? variable;
  Expression iterable;
  Expression? syntheticAssignment;
  Statement? expressionEffects;
  Statement body;
  final bool isAsync;
  final bool hasProblem;
  int bodyOffset = TreeNode.noOffset;

  ForInStatementWithSynthesizedVariable(this.variable, this.iterable,
      this.syntheticAssignment, this.expressionEffects, this.body,
      {required this.isAsync, required this.hasProblem})
      // ignore: unnecessary_null_comparison
      : assert(isAsync != null),
        // ignore: unnecessary_null_comparison
        assert(hasProblem != null) {
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
  void toTextInternal(AstPrinter state) {
    // TODO(johnniwinther): Implement this.
  }
}

class TryStatement extends InternalStatement {
  Statement tryBlock;
  List<Catch> catchBlocks;
  Statement? finallyBlock;

  TryStatement(this.tryBlock, this.catchBlocks, this.finallyBlock)
      // ignore: unnecessary_null_comparison
      : assert(tryBlock != null),
        // ignore: unnecessary_null_comparison
        assert(catchBlocks != null) {
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

  SwitchCaseImpl(this.caseOffsets, List<Expression> expressions,
      List<int> expressionOffsets, Statement body,
      {bool isDefault = false, required this.hasLabel})
      // ignore: unnecessary_null_comparison
      : assert(hasLabel != null),
        super(expressions, expressionOffsets, body, isDefault: isDefault);

  @override
  String toString() {
    return "SwitchCaseImpl(${toStringInternal()})";
  }
}

final PatternGuard dummyPatternGuard = new PatternGuard(dummyPattern);

/// A [Pattern] with an optional guard [Expression].
class PatternGuard extends TreeNode with InternalTreeNode {
  Pattern pattern;
  Expression? guard;

  PatternGuard(this.pattern, [this.guard]) {
    pattern.parent = this;
    guard?.parent = this;
  }

  @override
  void toTextInternal(AstPrinter printer) {
    pattern.toTextInternal(printer);
    if (guard != null) {
      printer.write(' when ');
      printer.writeExpression(guard!);
    }
  }

  @override
  String toString() => 'PatternGuard(${toStringInternal()})';
}

class PatternSwitchCase extends TreeNode
    with InternalTreeNode
    implements SwitchCase {
  final List<int> caseOffsets;
  final List<PatternGuard> patternGuards;

  @override
  Statement body;

  @override
  bool isDefault;

  final bool hasLabel;

  final List<VariableDeclaration> jointVariables;

  PatternSwitchCase(
      int fileOffset, this.caseOffsets, this.patternGuards, this.body,
      {required this.isDefault,
      required this.hasLabel,
      required this.jointVariables}) {
    setParents(jointVariables, this);
    this.fileOffset = fileOffset;
  }

  @override
  void toTextInternal(AstPrinter printer) {
    for (int index = 0; index < patternGuards.length; index++) {
      if (index > 0) {
        printer.newLine();
      }
      printer.write('case ');
      patternGuards[index].toTextInternal(printer);
      printer.write(':');
    }
    if (isDefault) {
      if (patternGuards.isNotEmpty) {
        printer.newLine();
      }
      printer.write('default:');
    }
    printer.incIndentation();
    Statement? block = body;
    if (block is Block) {
      for (Statement statement in block.statements) {
        printer.newLine();
        printer.writeStatement(statement);
      }
    } else {
      printer.write(' ');
      printer.writeStatement(body);
    }
    printer.decIndentation();
  }

  @override
  String toString() {
    return "PatternSwitchCase(${toStringInternal()})";
  }

  @override
  List<Expression> get expressions =>
      throw new UnimplementedError('PatternSwitchCase.expressions');

  @override
  List<int> get expressionOffsets =>
      throw new UnimplementedError('PatternSwitchCase.expressionOffsets');
}

class PatternSwitchStatement extends InternalStatement
    implements SwitchStatement {
  @override
  Expression expression;

  @override
  final List<PatternSwitchCase> cases;

  @override
  bool isExplicitlyExhaustive = false;

  /// Whether the switch has a `default` case.
  @override
  bool get hasDefault {
    assert(cases.every((c) => c == cases.last || !c.isDefault));
    return cases.isNotEmpty && cases.last.isDefault;
  }

  @override
  bool get isExhaustive => throw new UnimplementedError();

  PatternSwitchStatement(int fileOffset, this.expression, this.cases) {
    this.fileOffset = fileOffset;
    expression.parent = this;
    setParents(cases, this);
  }

  @override
  StatementInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitPatternSwitchStatement(this);
  }

  @override
  String toString() {
    return "PatternSwitchStatement(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('switch (');
    printer.writeExpression(expression);
    printer.write(') {');
    printer.incIndentation();
    for (SwitchCase switchCase in cases) {
      printer.newLine();
      printer.writeSwitchCase(switchCase);
    }
    printer.decIndentation();
    printer.newLine();
    printer.write('}');
  }

  @override
  void transformChildren(Transformer v) {
    throw new UnsupportedError('PatternSwitchStatement.transformChildren');
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    throw new UnsupportedError(
        'PatternSwitchStatement.transformOrRemoveChildren');
  }

  @override
  void visitChildren(Visitor v) {
    throw new UnsupportedError('PatternSwitchStatement.visitChildren');
  }
}

final SwitchExpressionCase dummySwitchExpressionCase = new SwitchExpressionCase(
    TreeNode.noOffset, dummyPatternGuard, dummyExpression);

class SwitchExpressionCase extends TreeNode with InternalTreeNode {
  PatternGuard patternGuard;
  Expression expression;

  SwitchExpressionCase(int fileOffset, this.patternGuard, this.expression) {
    this.fileOffset = fileOffset;
    patternGuard.parent = this;
    expression.parent = this;
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('case ');
    patternGuard.toTextInternal(printer);
    printer.write(' => ');
    printer.writeExpression(expression);
  }

  @override
  String toString() {
    return 'SwitchExpressionCase(${toStringInternal()})';
  }
}

class SwitchExpression extends InternalExpression {
  Expression expression;
  final List<SwitchExpressionCase> cases;

  SwitchExpression(int fileOffset, this.expression, this.cases) {
    this.fileOffset = fileOffset;
    expression.parent = this;
    setParents(cases, this);
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    return visitor.visitSwitchExpression(this, typeContext);
  }

  @override
  void transformChildren(Transformer v) {
    throw new UnsupportedError('SwitchExpression.transformChildren');
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    throw new UnsupportedError('SwitchExpression.transformOrRemoveChildren');
  }

  @override
  void visitChildren(Visitor v) {
    throw new UnsupportedError('SwitchExpression.visitChildren');
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('switch (');
    printer.writeExpression(expression);
    printer.write(') {');
    String comma = ' ';
    for (SwitchExpressionCase switchCase in cases) {
      printer.write(comma);
      switchCase.toTextInternal(printer);
      comma = ', ';
    }
    printer.write(' }');
  }

  @override
  String toString() => 'SwitchExpression(${toStringInternal()})';
}

class BreakStatementImpl extends BreakStatement {
  Statement? targetStatement;
  final bool isContinue;

  BreakStatementImpl({required this.isContinue})
      // ignore: unnecessary_null_comparison
      : assert(isContinue != null),
        super(dummyLabeledStatement);

  @override
  String toString() {
    return "BreakStatementImpl(${toStringInternal()})";
  }

  @override
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

/// Common base class for internal expressions.
abstract class InternalExpression extends Expression {
  @override
  void replaceChild(TreeNode child, TreeNode replacement) {
    // Do nothing. The node should not be part of the resulting AST, anyway.
  }

  @override
  R accept<R>(ExpressionVisitor<R> visitor) {
    if (visitor is Printer ||
        visitor is Precedence /* || visitor is Transformer*/) {
      // Allow visitors needed for toString and replaceWith.
      return visitor.defaultExpression(this);
    }
    return unsupported(
        "${runtimeType}.accept on ${visitor.runtimeType}", -1, null);
  }

  @override
  R accept1<R, A>(ExpressionVisitor1<R, A> visitor, A arg) {
    return unsupported(
        "${runtimeType}.accept1 on ${visitor.runtimeType}", -1, null);
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
      InferenceVisitorImpl visitor, DartType typeContext);

  @override
  void toTextInternal(AstPrinter printer) {
    // TODO(johnniwinther): Implement this.
  }
}

/// Front end specific implementation of [Argument].
class ArgumentsImpl extends Arguments {
  // TODO(johnniwinther): Move this to the static invocation instead.
  final int _extensionTypeParameterCount;

  final int _explicitExtensionTypeArgumentCount;

  final int? _extensionTypeArgumentOffset;

  int _explicitTypeArgumentCount;

  List<Object?>? argumentsOriginalOrder;

  /// True if the arguments are passed to the super-constructor in a
  /// super-initializer, and the positional parameters are super-initializer
  /// parameters. It is true that either all of the positional parameters are
  /// super-initializer parameters or none of them, so a simple boolean
  /// accurately reflects the state.
  bool positionalAreSuperParameters = false;

  /// Names of the named positional parameters. If none of the parameters are
  /// super-positional, the field is null.
  Set<String>? namedSuperParameterNames;

  ArgumentsImpl.internal(
      {required List<Expression> positional,
      required List<DartType>? types,
      required List<NamedExpression>? named,
      required int extensionTypeParameterCount,
      required int explicitExtensionTypeArgumentCount,
      required int? extensionTypeArgumentOffset,
      required int explicitTypeArgumentCount})
      : this._extensionTypeParameterCount = extensionTypeParameterCount,
        this._explicitExtensionTypeArgumentCount =
            explicitExtensionTypeArgumentCount,
        this._extensionTypeArgumentOffset = extensionTypeArgumentOffset,
        this._explicitTypeArgumentCount = explicitTypeArgumentCount,
        this.argumentsOriginalOrder = null,
        super(positional, types: types, named: named);

  ArgumentsImpl(List<Expression> positional,
      {List<DartType>? types,
      List<NamedExpression>? named,
      this.argumentsOriginalOrder})
      : _explicitTypeArgumentCount = types?.length ?? 0,
        _extensionTypeParameterCount = 0,
        _explicitExtensionTypeArgumentCount = 0,
        // The offset is unused in this case.
        _extensionTypeArgumentOffset = null,
        super(positional, types: types, named: named);

  ArgumentsImpl.forExtensionMethod(int extensionTypeParameterCount,
      int typeParameterCount, Expression receiver,
      {List<DartType> extensionTypeArguments = const <DartType>[],
      int? extensionTypeArgumentOffset,
      List<DartType> typeArguments = const <DartType>[],
      List<Expression> positionalArguments = const <Expression>[],
      List<NamedExpression> namedArguments = const <NamedExpression>[],
      this.argumentsOriginalOrder})
      : _extensionTypeParameterCount = extensionTypeParameterCount,
        _explicitExtensionTypeArgumentCount = extensionTypeArguments.length,
        _explicitTypeArgumentCount = typeArguments.length,
        _extensionTypeArgumentOffset = extensionTypeArgumentOffset,
        assert(
            extensionTypeArguments.isEmpty ||
                extensionTypeArguments.length == extensionTypeParameterCount,
            "Extension type arguments must be empty or complete."),
        super(<Expression>[receiver]..addAll(positionalArguments),
            named: namedArguments,
            types: <DartType>[]
              ..addAll(_normalizeTypeArguments(
                  extensionTypeParameterCount, extensionTypeArguments))
              ..addAll(
                  _normalizeTypeArguments(typeParameterCount, typeArguments)));

  static ArgumentsImpl clone(ArgumentsImpl node, List<Expression> positional,
      List<NamedExpression> named, List<DartType> types) {
    return new ArgumentsImpl.internal(
        positional: positional,
        named: named,
        types: types,
        extensionTypeParameterCount: node._extensionTypeParameterCount,
        explicitExtensionTypeArgumentCount:
            node._explicitExtensionTypeArgumentCount,
        explicitTypeArgumentCount: node._explicitTypeArgumentCount,
        extensionTypeArgumentOffset: node._extensionTypeArgumentOffset);
  }

  static List<DartType> _normalizeTypeArguments(
      int length, List<DartType> arguments) {
    if (arguments.isEmpty && length > 0) {
      return new List<DartType>.filled(length, const UnknownType());
    }
    return arguments;
  }

  static void setNonInferrableArgumentTypes(
      ArgumentsImpl arguments, List<DartType> types) {
    arguments.types.clear();
    arguments.types.addAll(types);
    arguments._explicitTypeArgumentCount = types.length;
  }

  static void removeNonInferrableArgumentTypes(ArgumentsImpl arguments) {
    arguments.types.clear();
    arguments._explicitTypeArgumentCount = 0;
  }

  @override
  String toString() {
    return "ArgumentsImpl(${toStringInternal()})";
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

  final bool isNullAware;

  /// The expressions performed on [variable].
  final List<Expression> expressions = <Expression>[];

  /// Creates a [Cascade] using [variable] as the cascade
  /// variable.  Caller is responsible for ensuring that [variable]'s
  /// initializer is the expression preceding the first `..` of the cascade
  /// expression.
  Cascade(this.variable, {required this.isNullAware})
      // ignore: unnecessary_null_comparison
      : assert(variable != null),
        // ignore: unnecessary_null_comparison
        assert(isNullAware != null) {
    variable.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
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
  void toTextInternal(AstPrinter printer) {
    printer.write('let ');
    printer.writeVariableDeclaration(variable);
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

  DeferredCheck(this.variable, this.expression)
      // ignore: unnecessary_null_comparison
      : assert(variable != null),
        // ignore: unnecessary_null_comparison
        assert(expression != null) {
    variable.parent = this;
    expression.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    return visitor.visitDeferredCheck(this, typeContext);
  }

  @override
  String toString() {
    return "DeferredCheck(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('let ');
    printer.writeVariableDeclaration(variable);
    printer.write(' in ');
    printer.writeExpression(expression);
  }
}

/// Common base class for shadow objects representing expressions in kernel
/// form.
abstract class ExpressionJudgment extends Expression {
  /// Calls back to [inferrer] to perform type inference for whatever concrete
  /// type of [Expression] this is.
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext);
}

/// Shadow object for [StaticInvocation] when the procedure being invoked is a
/// factory constructor.
class FactoryConstructorInvocation extends StaticInvocation
    implements ExpressionJudgment {
  bool hasBeenInferred = false;

  FactoryConstructorInvocation(Procedure target, Arguments arguments,
      {bool isConst = false})
      : super(target, arguments, isConst: isConst);

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    return visitor.visitFactoryConstructorInvocation(this, typeContext);
  }

  @override
  String toString() {
    return "FactoryConstructorInvocation(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    if (isConst) {
      printer.write('const ');
    } else {
      printer.write('new ');
    }
    printer.writeClassName(target.enclosingClass!.reference);
    printer.writeTypeArguments(arguments.types);
    if (target.name.text.isNotEmpty) {
      printer.write('.');
      printer.write(target.name.text);
    }
    printer.writeArguments(arguments, includeTypeArguments: false);
  }
}

/// Shadow object for [ConstructorInvocation] when the procedure being invoked
/// is a type aliased constructor.
class TypeAliasedConstructorInvocation extends ConstructorInvocation
    implements ExpressionJudgment {
  bool hasBeenInferred = false;
  final TypeAliasBuilder typeAliasBuilder;

  TypeAliasedConstructorInvocation(
      this.typeAliasBuilder, Constructor target, Arguments arguments,
      {bool isConst = false})
      : super(target, arguments, isConst: isConst);

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    return visitor.visitTypeAliasedConstructorInvocation(this, typeContext);
  }

  @override
  String toString() {
    return "TypeAliasedConstructorInvocation(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    if (isConst) {
      printer.write('const ');
    } else {
      printer.write('new ');
    }
    printer.writeTypedefName(typeAliasBuilder.typedef.reference);
    printer.writeTypeArguments(arguments.types);
    if (target.name.text.isNotEmpty) {
      printer.write('.');
      printer.write(target.name.text);
    }
    printer.writeArguments(arguments, includeTypeArguments: false);
  }
}

/// Shadow object for [StaticInvocation] when the procedure being invoked is a
/// type aliased factory constructor.
class TypeAliasedFactoryInvocation extends StaticInvocation
    implements ExpressionJudgment {
  bool hasBeenInferred = false;
  final TypeAliasBuilder typeAliasBuilder;

  TypeAliasedFactoryInvocation(
      this.typeAliasBuilder, Procedure target, Arguments arguments,
      {bool isConst = false})
      : super(target, arguments, isConst: isConst);

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    return visitor.visitTypeAliasedFactoryInvocation(this, typeContext);
  }

  @override
  String toString() {
    return "TypeAliasedConstructorInvocation(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    if (isConst) {
      printer.write('const ');
    } else {
      printer.write('new ');
    }
    printer.writeTypedefName(typeAliasBuilder.typedef.reference);
    printer.writeTypeArguments(arguments.types);
    if (target.name.text.isNotEmpty) {
      printer.write('.');
      printer.write(target.name.text);
    }
    printer.writeArguments(arguments, includeTypeArguments: false);
  }
}

/// Front end specific implementation of [FunctionDeclaration].
class FunctionDeclarationImpl extends FunctionDeclaration {
  bool hasImplicitReturnType = false;

  FunctionDeclarationImpl(VariableDeclaration variable, FunctionNode function)
      : super(variable, function);

  static void setHasImplicitReturnType(
      FunctionDeclarationImpl declaration, bool hasImplicitReturnType) {
    declaration.hasImplicitReturnType = hasImplicitReturnType;
  }

  @override
  String toString() {
    return "FunctionDeclarationImpl(${toStringInternal()})";
  }
}

/// Concrete shadow object representing a super initializer in kernel form.
class InvalidSuperInitializerJudgment extends LocalInitializer
    implements InitializerJudgment {
  final Constructor target;
  final ArgumentsImpl argumentsJudgment;

  InvalidSuperInitializerJudgment(
      this.target, this.argumentsJudgment, VariableDeclaration variable)
      : super(variable);

  @override
  InitializerInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitInvalidSuperInitializerJudgment(this);
  }

  @override
  String toString() {
    return "InvalidSuperInitializerJudgment(${toStringInternal()})";
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

  IfNullExpression(this.left, this.right)
      // ignore: unnecessary_null_comparison
      : assert(left != null),
        // ignore: unnecessary_null_comparison
        assert(right != null) {
    left.parent = this;
    right.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    return visitor.visitIfNullExpression(this, typeContext);
  }

  @override
  String toString() {
    return "IfNullExpression(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(left, minimumPrecedence: Precedence.CONDITIONAL);
    printer.write(' ?? ');
    printer.writeExpression(right,
        minimumPrecedence: Precedence.CONDITIONAL + 1);
  }
}

/// Common base class for shadow objects representing initializers in kernel
/// form.
abstract class InitializerJudgment implements Initializer {
  /// Performs type inference for whatever concrete type of
  /// [InitializerJudgment] this is.
  InitializerInferenceResult acceptInference(InferenceVisitorImpl visitor);
}

/// Concrete shadow object representing an integer literal in kernel form.
class IntJudgment extends IntLiteral implements ExpressionJudgment {
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
      InferenceVisitorImpl visitor, DartType typeContext) {
    return visitor.visitIntJudgment(this, typeContext);
  }

  @override
  String toString() {
    return "IntJudgment(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    if (literal == null) {
      printer.write('$value');
    } else {
      printer.write(literal!);
    }
  }
}

class ShadowLargeIntLiteral extends IntLiteral implements ExpressionJudgment {
  final String literal;
  @override
  final int fileOffset;
  bool isParenthesized = false;

  ShadowLargeIntLiteral(this.literal, this.fileOffset) : super(0);

  double? asDouble({bool negated = false}) {
    BigInt? intValue = BigInt.tryParse(negated ? '-${literal}' : literal);
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
    return int.tryParse(negated ? '-${literal}' : literal);
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    return visitor.visitShadowLargeIntLiteral(this, typeContext);
  }

  @override
  String toString() {
    return "ShadowLargeIntLiteral(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write(literal);
  }
}

/// Concrete shadow object representing an invalid initializer in kernel form.
class ShadowInvalidInitializer extends LocalInitializer
    implements InitializerJudgment {
  ShadowInvalidInitializer(VariableDeclaration variable) : super(variable);

  @override
  InitializerInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitShadowInvalidInitializer(this);
  }

  @override
  String toString() {
    return "ShadowInvalidInitializer(${toStringInternal()})";
  }
}

/// Concrete shadow object representing an invalid initializer in kernel form.
class ShadowInvalidFieldInitializer extends LocalInitializer
    implements InitializerJudgment {
  Field field;
  Expression value;

  ShadowInvalidFieldInitializer(
      this.field, this.value, VariableDeclaration variable)
      // ignore: unnecessary_null_comparison
      : assert(value != null),
        super(variable) {
    value.parent = this;
  }

  @override
  InitializerInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitShadowInvalidFieldInitializer(this);
  }

  @override
  String toString() {
    return "ShadowInvalidFieldInitializer(${toStringInternal()})";
  }
}

class ExpressionInvocation extends InternalExpression {
  Expression expression;
  Arguments arguments;

  ExpressionInvocation(this.expression, this.arguments)
      // ignore: unnecessary_null_comparison
      : assert(expression != null),
        // ignore: unnecessary_null_comparison
        assert(arguments != null) {
    expression.parent = this;
    arguments.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    return visitor.visitExpressionInvocation(this, typeContext);
  }

  @override
  String toString() {
    return "ExpressionInvocation(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(expression);
    printer.writeArguments(arguments);
  }
}

/// Internal expression representing a null-aware method invocation.
///
/// A null-aware method invocation of the form `a?.b(...)` is encoded as:
///
///     let v = a in v == null ? null : v.b(...)
///
class NullAwareMethodInvocation extends InternalExpression {
  /// The synthetic variable whose initializer hold the receiver.
  VariableDeclarationImpl variable;

  /// The expression that invokes the method on [variable].
  Expression invocation;

  NullAwareMethodInvocation(this.variable, this.invocation)
      // ignore: unnecessary_null_comparison
      : assert(variable != null),
        // ignore: unnecessary_null_comparison
        assert(invocation != null) {
    variable.parent = this;
    invocation.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    return visitor.visitNullAwareMethodInvocation(this, typeContext);
  }

  @override
  String toString() {
    return "NullAwareMethodInvocation(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    Expression methodInvocation = invocation;
    if (methodInvocation is InstanceInvocation) {
      Expression receiver = methodInvocation.receiver;
      if (receiver is VariableGet && receiver.variable == variable) {
        // Special-case the usual use of this node.
        printer.writeExpression(variable.initializer!);
        printer.write('?.');
        printer.writeInterfaceMemberName(
            methodInvocation.interfaceTargetReference, methodInvocation.name);
        printer.writeArguments(methodInvocation.arguments);
        return;
      }
    } else if (methodInvocation is DynamicInvocation) {
      Expression receiver = methodInvocation.receiver;
      if (receiver is VariableGet && receiver.variable == variable) {
        // Special-case the usual use of this node.
        printer.writeExpression(variable.initializer!);
        printer.write('?.');
        printer.writeName(methodInvocation.name);
        printer.writeArguments(methodInvocation.arguments);
        return;
      }
    }
    printer.write('let ');
    printer.writeVariableDeclaration(variable);
    printer.write(' in null-aware ');
    printer.writeExpression(methodInvocation);
  }
}

/// Internal expression representing a null-aware read from a property.
///
/// A null-aware property get of the form `a?.b` is encoded as:
///
///     let v = a in v == null ? null : v.b
///
class NullAwarePropertyGet extends InternalExpression {
  /// The synthetic variable whose initializer hold the receiver.
  VariableDeclarationImpl variable;

  /// The expression that reads the property from [variable].
  Expression read;

  NullAwarePropertyGet(this.variable, this.read)
      // ignore: unnecessary_null_comparison
      : assert(variable != null),
        // ignore: unnecessary_null_comparison
        assert(read != null) {
    variable.parent = this;
    read.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    return visitor.visitNullAwarePropertyGet(this, typeContext);
  }

  @override
  String toString() {
    return "NullAwarePropertyGet(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    Expression propertyGet = read;
    if (propertyGet is PropertyGet) {
      Expression receiver = propertyGet.receiver;
      if (receiver is VariableGet && receiver.variable == variable) {
        // Special-case the usual use of this node.
        printer.writeExpression(variable.initializer!);
        printer.write('?.');
        printer.writeName(propertyGet.name);
        return;
      }
    }
    printer.write('let ');
    printer.writeVariableDeclaration(variable);
    printer.write(' in null-aware ');
    printer.writeExpression(propertyGet);
  }
}

/// Internal expression representing a null-aware read from a property.
///
/// A null-aware property get of the form `a?.b = c` is encoded as:
///
///     let v = a in v == null ? null : v.b = c
///
class NullAwarePropertySet extends InternalExpression {
  /// The synthetic variable whose initializer hold the receiver.
  VariableDeclarationImpl variable;

  /// The expression that writes the value to the property in [variable].
  Expression write;

  NullAwarePropertySet(this.variable, this.write)
      // ignore: unnecessary_null_comparison
      : assert(variable != null),
        // ignore: unnecessary_null_comparison
        assert(write != null) {
    variable.parent = this;
    write.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    return visitor.visitNullAwarePropertySet(this, typeContext);
  }

  @override
  String toString() {
    return "NullAwarePropertySet(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    Expression propertySet = write;
    if (propertySet is InstanceSet) {
      Expression receiver = propertySet.receiver;
      if (receiver is VariableGet && receiver.variable == variable) {
        // Special-case the usual use of this node.
        printer.writeExpression(variable.initializer!);
        printer.write('?.');
        printer.writeInterfaceMemberName(
            propertySet.interfaceTargetReference, propertySet.name);
        printer.write(' = ');
        printer.writeExpression(propertySet.value);
        return;
      }
    } else if (propertySet is DynamicSet) {
      Expression receiver = propertySet.receiver;
      if (receiver is VariableGet && receiver.variable == variable) {
        // Special-case the usual use of this node.
        printer.writeExpression(variable.initializer!);
        printer.write('?.');
        printer.writeName(propertySet.name);
        printer.write(' = ');
        printer.writeExpression(propertySet.value);
        return;
      }
    }
    printer.write('let ');
    printer.writeVariableDeclaration(variable);
    printer.write(' in null-aware ');
    printer.writeExpression(propertySet);
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
class VariableDeclarationImpl extends VariableDeclaration {
  final bool forSyntheticToken;

  /// Determine whether the given [VariableDeclarationImpl] had an implicit
  /// type.
  ///
  /// This is static to avoid introducing a method that would be visible to
  /// the kernel.
  final bool isImplicitlyTyped;

  // TODO(ahe): Remove this field. It's only used locally when compiling a
  // method, and this can thus be tracked in a [Set] (actually, tracking this
  // information in a [List] is probably even faster as the average size will
  // be close to zero).
  bool mutatedInClosure = false;

  /// Determines whether the given [VariableDeclarationImpl] represents a
  /// local function.
  ///
  /// This is static to avoid introducing a method that would be visible to the
  /// kernel.
  // TODO(ahe): Investigate if this can be removed.
  final bool isLocalFunction;

  /// Whether the variable is final with no initializer in a null safe library.
  ///
  /// Such variables behave similar to those declared with the `late` keyword,
  /// except that the don't have lazy evaluation semantics, and it is statically
  /// verified by the front end that they are always assigned before they are
  /// used.
  bool isStaticLate;

  VariableDeclarationImpl(String? name,
      {this.forSyntheticToken = false,
      bool hasDeclaredInitializer = false,
      Expression? initializer,
      DartType? type,
      bool isFinal = false,
      bool isConst = false,
      bool isInitializingFormal = false,
      bool isCovariantByDeclaration = false,
      bool isLocalFunction = false,
      bool isLate = false,
      bool isRequired = false,
      bool isLowered = false,
      this.isStaticLate = false})
      : isImplicitlyTyped = type == null,
        isLocalFunction = isLocalFunction,
        super(name,
            initializer: initializer,
            type: type ?? const DynamicType(),
            isFinal: isFinal,
            isConst: isConst,
            isInitializingFormal: isInitializingFormal,
            isCovariantByDeclaration: isCovariantByDeclaration,
            isLate: isLate,
            isRequired: isRequired,
            isLowered: isLowered,
            hasDeclaredInitializer: hasDeclaredInitializer);

  VariableDeclarationImpl.forEffect(Expression initializer)
      : forSyntheticToken = false,
        isImplicitlyTyped = false,
        isLocalFunction = false,
        isStaticLate = false,
        super.forValue(initializer);

  VariableDeclarationImpl.forValue(Expression initializer)
      : forSyntheticToken = false,
        isImplicitlyTyped = true,
        isLocalFunction = false,
        isStaticLate = false,
        super.forValue(initializer);

  // The synthesized local getter function for a lowered late variable.
  //
  // This is set in `InferenceVisitor.visitVariableDeclaration` when late
  // lowering is enabled.
  VariableDeclaration? lateGetter;

  // The synthesized local setter function for an assignable lowered late
  // variable.
  //
  // This is set in `InferenceVisitor.visitVariableDeclaration` when late
  // lowering is enabled.
  VariableDeclaration? lateSetter;

  // Is `true` if this a lowered late final variable without an initializer.
  //
  // This is set in `InferenceVisitor.visitVariableDeclaration` when late
  // lowering is enabled.
  bool isLateFinalWithoutInitializer = false;

  // The original type (declared or inferred) of a lowered late variable.
  //
  // This is set in `InferenceVisitor.visitVariableDeclaration` when late
  // lowering is enabled.
  DartType? lateType;

  // The original name of a lowered late variable.
  //
  // This is set in `InferenceVisitor.visitVariableDeclaration` when late
  // lowering is enabled.
  String? lateName;

  @override
  bool get isAssignable {
    if (isStaticLate) return true;
    return super.isAssignable;
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeVariableDeclaration(this,
        isLate: isLate || lateGetter != null, type: lateType ?? type);
    printer.write(';');
  }

  @override
  String toString() {
    return "VariableDeclarationImpl(${toStringInternal()})";
  }
}

/// Front end specific implementation of [VariableGet].
class VariableGetImpl extends VariableGet {
  // TODO(johnniwinther): Remove the need for this by encoding all null aware
  // expressions explicitly.
  final bool forNullGuardedAccess;

  VariableGetImpl(VariableDeclaration variable,
      {required this.forNullGuardedAccess})
      // ignore: unnecessary_null_comparison
      : assert(forNullGuardedAccess != null),
        super(variable);

  @override
  String toString() {
    return "VariableGetImpl(${toStringInternal()})";
  }
}

/// Front end specific implementation of [LoadLibrary].
class LoadLibraryImpl extends LoadLibrary {
  final Arguments? arguments;

  LoadLibraryImpl(LibraryDependency import, this.arguments) : super(import);

  @override
  String toString() {
    return "LoadLibraryImpl(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write(import.name!);
    printer.write('.loadLibrary');
    if (arguments != null) {
      printer.writeArguments(arguments!);
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
      InferenceVisitorImpl visitor, DartType typeContext) {
    return visitor.visitLoadLibraryTearOff(this, typeContext);
  }

  @override
  String toString() {
    return "LoadLibraryTearOff(${toStringInternal()})";
  }

  @override
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

  IfNullPropertySet(this.receiver, this.propertyName, this.rhs,
      {required this.forEffect,
      required this.readOffset,
      required this.writeOffset})
      // ignore: unnecessary_null_comparison
      : assert(receiver != null),
        // ignore: unnecessary_null_comparison
        assert(rhs != null),
        // ignore: unnecessary_null_comparison
        assert(forEffect != null),
        // ignore: unnecessary_null_comparison
        assert(readOffset != null),
        // ignore: unnecessary_null_comparison
        assert(writeOffset != null) {
    receiver.parent = this;
    rhs.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    return visitor.visitIfNullPropertySet(this, typeContext);
  }

  @override
  String toString() {
    return "IfNullPropertySet(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver);
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

  IfNullSet(this.read, this.write, {required this.forEffect})
      // ignore: unnecessary_null_comparison
      : assert(read != null),
        // ignore: unnecessary_null_comparison
        assert(write != null),
        // ignore: unnecessary_null_comparison
        assert(forEffect != null) {
    read.parent = this;
    write.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    return visitor.visitIfNullSet(this, typeContext);
  }

  @override
  String toString() {
    return "IfNullSet(${toStringInternal()})";
  }

  @override
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
/// If [readOnlyReceiver] is `true` the [receiverVariable] is not created
/// and the [receiver] is used directly.
class CompoundExtensionSet extends InternalExpression {
  /// The extension in which the [setter] is declared.
  final Extension extension;

  /// The explicit type arguments for the type parameters declared in
  /// [extension].
  final List<DartType>? explicitTypeArguments;

  /// The receiver used for the read/write operations.
  Expression receiver;

  /// The name of the property accessed by the read/write operations.
  final Name propertyName;

  /// The member used for the read operation.
  final Member? getter;

  /// The binary operation performed on the getter result and [rhs].
  final Name binaryName;

  /// The right-hand side of the binary operation.
  Expression rhs;

  /// The member used for the write operation.
  final Member? setter;

  /// If `true`, the expression is only need for effect and not for its value.
  final bool forEffect;

  /// The file offset for the read operation.
  final int readOffset;

  /// The file offset for the binary operation.
  final int binaryOffset;

  /// The file offset for the write operation.
  final int writeOffset;

  CompoundExtensionSet(
      this.extension,
      this.explicitTypeArguments,
      this.receiver,
      this.propertyName,
      this.getter,
      this.binaryName,
      this.rhs,
      this.setter,
      {required this.forEffect,
      required this.readOffset,
      required this.binaryOffset,
      required this.writeOffset})
      // ignore: unnecessary_null_comparison
      : assert(receiver != null),
        // ignore: unnecessary_null_comparison
        assert(rhs != null),
        // ignore: unnecessary_null_comparison
        assert(forEffect != null),
        // ignore: unnecessary_null_comparison
        assert(readOffset != null),
        // ignore: unnecessary_null_comparison
        assert(binaryOffset != null),
        // ignore: unnecessary_null_comparison
        assert(writeOffset != null) {
    receiver.parent = this;
    rhs.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    return visitor.visitCompoundExtensionSet(this, typeContext);
  }

  @override
  String toString() {
    return "CompoundExtensionSet(${toStringInternal()})";
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

  /// The binary operation performed on the getter result and [rhs].
  final Name binaryName;

  /// The right-hand side of the binary operation.
  Expression rhs;

  /// If `true`, the expression is only need for effect and not for its value.
  final bool forEffect;

  /// The file offset for the read operation.
  final int readOffset;

  /// The file offset for the binary operation.
  final int binaryOffset;

  /// The file offset for the write operation.
  final int writeOffset;

  CompoundPropertySet(
      this.receiver, this.propertyName, this.binaryName, this.rhs,
      {required this.forEffect,
      required this.readOffset,
      required this.binaryOffset,
      required this.writeOffset})
      // ignore: unnecessary_null_comparison
      : assert(receiver != null),
        // ignore: unnecessary_null_comparison
        assert(rhs != null),
        // ignore: unnecessary_null_comparison
        assert(forEffect != null),
        // ignore: unnecessary_null_comparison
        assert(readOffset != null),
        // ignore: unnecessary_null_comparison
        assert(binaryOffset != null),
        // ignore: unnecessary_null_comparison
        assert(writeOffset != null) {
    receiver.parent = this;
    rhs.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    return visitor.visitCompoundPropertySet(this, typeContext);
  }

  @override
  String toString() {
    return "CompoundPropertySet(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver);
    printer.write('.');
    printer.writeName(propertyName);
    printer.write(' ');
    printer.writeName(binaryName);
    printer.write('= ');
    printer.writeExpression(rhs);
  }
}

/// Internal expression representing an compound property assignment.
///
/// An compound property assignment of the form `o.a++` is encoded as the
/// expression:
///
///     let v1 = o in let v2 = v1.a in let v3 = v1.a = v2 + 1 in v2
///
class PropertyPostIncDec extends InternalExpression {
  /// The synthetic variable whose initializer hold the receiver.
  ///
  /// This is `null` if the receiver is read-only and therefore does not need to
  /// be stored in a temporary variable.
  VariableDeclarationImpl? variable;

  /// The expression that reads the property on [variable].
  VariableDeclarationImpl read;

  /// The expression that writes the result of the binary operation to the
  /// property on [variable].
  VariableDeclarationImpl write;

  PropertyPostIncDec(this.variable, this.read, this.write)
      // ignore: unnecessary_null_comparison
      : assert(read != null),
        // ignore: unnecessary_null_comparison
        assert(write != null) {
    variable?.parent = this;
    read.parent = this;
    write.parent = this;
  }

  PropertyPostIncDec.onReadOnly(
      VariableDeclarationImpl read, VariableDeclarationImpl write)
      : this(null, read, write);

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    return visitor.visitPropertyPostIncDec(this, typeContext);
  }

  @override
  String toString() {
    return "PropertyPostIncDec(${toStringInternal()})";
  }
}

/// Internal expression representing an local variable post inc/dec expression.
///
/// An local variable post inc/dec expression of the form `a++` is encoded as
/// the expression:
///
///     let v1 = a in let v2 = a = v1 + 1 in v1
///
class LocalPostIncDec extends InternalExpression {
  /// The expression that reads the local variable.
  VariableDeclarationImpl read;

  /// The expression that writes the result of the binary operation to the
  /// local variable.
  VariableDeclarationImpl write;

  LocalPostIncDec(this.read, this.write)
      // ignore: unnecessary_null_comparison
      : assert(read != null),
        // ignore: unnecessary_null_comparison
        assert(write != null) {
    read.parent = this;
    write.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    return visitor.visitLocalPostIncDec(this, typeContext);
  }

  @override
  String toString() {
    return "LocalPostIncDec(${toStringInternal()})";
  }
}

/// Internal expression representing an static member post inc/dec expression.
///
/// An local variable post inc/dec expression of the form `a++` is encoded as
/// the expression:
///
///     let v1 = a in let v2 = a = v1 + 1 in v1
///
class StaticPostIncDec extends InternalExpression {
  /// The expression that reads the static member.
  VariableDeclarationImpl read;

  /// The expression that writes the result of the binary operation to the
  /// static member.
  VariableDeclarationImpl write;

  StaticPostIncDec(this.read, this.write)
      // ignore: unnecessary_null_comparison
      : assert(read != null),
        // ignore: unnecessary_null_comparison
        assert(write != null) {
    read.parent = this;
    write.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    return visitor.visitStaticPostIncDec(this, typeContext);
  }

  @override
  String toString() {
    return "StaticPostIncDec(${toStringInternal()})";
  }
}

/// Internal expression representing an static member post inc/dec expression.
///
/// An local variable post inc/dec expression of the form `super.a++` is encoded
/// as the expression:
///
///     let v1 = super.a in let v2 = super.a = v1 + 1 in v1
///
class SuperPostIncDec extends InternalExpression {
  /// The expression that reads the static member.
  VariableDeclarationImpl read;

  /// The expression that writes the result of the binary operation to the
  /// static member.
  VariableDeclarationImpl write;

  SuperPostIncDec(this.read, this.write)
      // ignore: unnecessary_null_comparison
      : assert(read != null),
        // ignore: unnecessary_null_comparison
        assert(write != null) {
    read.parent = this;
    write.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    return visitor.visitSuperPostIncDec(this, typeContext);
  }

  @override
  String toString() {
    return "SuperPostIncDec(${toStringInternal()})";
  }
}

/// Internal expression representing an index get expression.
class IndexGet extends InternalExpression {
  /// The receiver on which the index set operation is performed.
  Expression receiver;

  /// The index expression of the operation.
  Expression index;

  IndexGet(this.receiver, this.index)
      // ignore: unnecessary_null_comparison
      : assert(receiver != null),
        // ignore: unnecessary_null_comparison
        assert(index != null) {
    receiver.parent = this;
    index.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    return visitor.visitIndexGet(this, typeContext);
  }

  @override
  String toString() {
    return "IndexGet(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver);
    printer.write('[');
    printer.writeExpression(index);
    printer.write(']');
  }
}

/// Internal expression representing an index set expression.
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
/// using [MethodInvocationImpl].
///
class IndexSet extends InternalExpression {
  /// The receiver on which the index set operation is performed.
  Expression receiver;

  /// The index expression of the operation.
  Expression index;

  /// The value expression of the operation.
  Expression value;

  final bool forEffect;

  IndexSet(this.receiver, this.index, this.value, {required this.forEffect})
      // ignore: unnecessary_null_comparison
      : assert(receiver != null),
        // ignore: unnecessary_null_comparison
        assert(index != null),
        // ignore: unnecessary_null_comparison
        assert(value != null),
        // ignore: unnecessary_null_comparison
        assert(forEffect != null) {
    receiver.parent = this;
    index.parent = this;
    value.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    return visitor.visitIndexSet(this, typeContext);
  }

  @override
  String toString() {
    return "IndexSet(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver);
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

  SuperIndexSet(this.setter, this.index, this.value)
      // ignore: unnecessary_null_comparison
      : assert(index != null),
        // ignore: unnecessary_null_comparison
        assert(value != null) {
    index.parent = this;
    value.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    return visitor.visitSuperIndexSet(this, typeContext);
  }

  @override
  String toString() {
    return "SuperIndexSet(${toStringInternal()})";
  }
}

/// Internal expression representing an extension index set expression.
///
/// An extension index set expression of the form `Extension(o)[a] = b` used
/// for value is encoded as the expression:
///
///     let receiverVariable = o
///     let indexVariable = a in
///     let valueVariable = b in '
///     let writeVariable =
///         receiverVariable.[]=(indexVariable, valueVariable) in
///           valueVariable
///
/// An extension index set expression used for effect is encoded as
///
///    o.[]=(a, b)
///
/// using [StaticInvocation].
///
class ExtensionIndexSet extends InternalExpression {
  /// The extension in which the [setter] is declared.
  final Extension extension;

  /// The explicit type arguments for the type parameters declared in
  /// [extension].
  final List<DartType>? explicitTypeArguments;

  /// The receiver of the extension access.
  Expression receiver;

  /// The []= member.
  Member setter;

  /// The index expression of the operation.
  Expression index;

  /// The value expression of the operation.
  Expression value;

  ExtensionIndexSet(this.extension, this.explicitTypeArguments, this.receiver,
      this.setter, this.index, this.value)
      : assert(explicitTypeArguments == null ||
            explicitTypeArguments.length == extension.typeParameters.length),
        // ignore: unnecessary_null_comparison
        assert(receiver != null),
        // ignore: unnecessary_null_comparison
        assert(index != null),
        // ignore: unnecessary_null_comparison
        assert(value != null) {
    receiver.parent = this;
    index.parent = this;
    value.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    return visitor.visitExtensionIndexSet(this, typeContext);
  }

  @override
  String toString() {
    return "ExtensionIndexSet(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write(extension.name);
    if (explicitTypeArguments != null) {
      printer.writeTypeArguments(explicitTypeArguments!);
    }
    printer.write('(');
    printer.writeExpression(receiver);
    printer.write(')[');
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

  IfNullIndexSet(this.receiver, this.index, this.value,
      {required this.readOffset,
      required this.testOffset,
      required this.writeOffset,
      required this.forEffect})
      // ignore: unnecessary_null_comparison
      : assert(receiver != null),
        // ignore: unnecessary_null_comparison
        assert(index != null),
        // ignore: unnecessary_null_comparison
        assert(value != null),
        // ignore: unnecessary_null_comparison
        assert(readOffset != null),
        // ignore: unnecessary_null_comparison
        assert(testOffset != null),
        // ignore: unnecessary_null_comparison
        assert(writeOffset != null),
        // ignore: unnecessary_null_comparison
        assert(forEffect != null) {
    receiver.parent = this;
    index.parent = this;
    value.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    return visitor.visitIfNullIndexSet(this, typeContext);
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

  IfNullSuperIndexSet(this.getter, this.setter, this.index, this.value,
      {required this.readOffset,
      required this.testOffset,
      required this.writeOffset,
      required this.forEffect})
      // ignore: unnecessary_null_comparison
      : assert(index != null),
        // ignore: unnecessary_null_comparison
        assert(value != null),
        // ignore: unnecessary_null_comparison
        assert(readOffset != null),
        // ignore: unnecessary_null_comparison
        assert(testOffset != null),
        // ignore: unnecessary_null_comparison
        assert(writeOffset != null),
        // ignore: unnecessary_null_comparison
        assert(forEffect != null) {
    index.parent = this;
    value.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    return visitor.visitIfNullSuperIndexSet(this, typeContext);
  }

  @override
  String toString() {
    return "IfNullSuperIndexSet(${toStringInternal()})";
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
class IfNullExtensionIndexSet extends InternalExpression {
  final Extension extension;

  final List<DartType>? explicitTypeArguments;

  /// The extension receiver;
  Expression receiver;

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

  IfNullExtensionIndexSet(this.extension, this.explicitTypeArguments,
      this.receiver, this.getter, this.setter, this.index, this.value,
      {required this.readOffset,
      required this.testOffset,
      required this.writeOffset,
      required this.forEffect})
      : assert(explicitTypeArguments == null ||
            explicitTypeArguments.length == extension.typeParameters.length),
        // ignore: unnecessary_null_comparison
        assert(receiver != null),
        // ignore: unnecessary_null_comparison
        assert(index != null),
        // ignore: unnecessary_null_comparison
        assert(value != null),
        // ignore: unnecessary_null_comparison
        assert(readOffset != null),
        // ignore: unnecessary_null_comparison
        assert(testOffset != null),
        // ignore: unnecessary_null_comparison
        assert(writeOffset != null),
        // ignore: unnecessary_null_comparison
        assert(forEffect != null) {
    receiver.parent = this;
    index.parent = this;
    value.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    return visitor.visitIfNullExtensionIndexSet(this, typeContext);
  }

  @override
  String toString() {
    return "IfNullExtensionIndexSet(${toStringInternal()})";
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

  CompoundIndexSet(this.receiver, this.index, this.binaryName, this.rhs,
      {required this.readOffset,
      required this.binaryOffset,
      required this.writeOffset,
      required this.forEffect,
      required this.forPostIncDec})
      // ignore: unnecessary_null_comparison
      : assert(receiver != null),
        // ignore: unnecessary_null_comparison
        assert(index != null),
        // ignore: unnecessary_null_comparison
        assert(rhs != null),
        // ignore: unnecessary_null_comparison
        assert(readOffset != null),
        // ignore: unnecessary_null_comparison
        assert(binaryOffset != null),
        // ignore: unnecessary_null_comparison
        assert(writeOffset != null),
        // ignore: unnecessary_null_comparison
        assert(forEffect != null),
        // ignore: unnecessary_null_comparison
        assert(forPostIncDec != null) {
    receiver.parent = this;
    index.parent = this;
    rhs.parent = this;
    fileOffset = binaryOffset;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    return visitor.visitCompoundIndexSet(this, typeContext);
  }

  @override
  String toString() {
    return "CompoundIndexSet(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver);
    printer.write('[');
    printer.writeExpression(index);
    printer.write(']');
    if (forPostIncDec &&
        (binaryName.text == '+' || binaryName.text == '-') &&
        rhs is IntLiteral &&
        (rhs as IntLiteral).value == 1) {
      if (binaryName.text == '+') {
        printer.write('++');
      } else {
        printer.write('--');
      }
    } else {
      printer.write(' ');
      printer.write(binaryName.text);
      printer.write('= ');
      printer.writeExpression(rhs);
    }
  }
}

/// Internal expression representing a null-aware compound assignment.
///
/// A null-aware compound assignment of the form
///
///     receiver?.property binaryName= rhs
///
/// is, if used for value as a normal compound or prefix operation, encoded as
/// the expression:
///
///     let receiverVariable = receiver in
///       receiverVariable == null ? null :
///         let leftVariable = receiverVariable.propertyName in
///           let valueVariable = leftVariable binaryName rhs in
///             let writeVariable =
///                 receiverVariable.propertyName = valueVariable in
///               valueVariable
///
/// and, if used for value as a postfix operation, encoded as
///
///     let receiverVariable = receiver in
///       receiverVariable == null ? null :
///         let leftVariable = receiverVariable.propertyName in
///           let writeVariable =
///               receiverVariable.propertyName =
///                   leftVariable binaryName rhs in
///             leftVariable
///
/// and, if used for effect, encoded as:
///
///     let receiverVariable = receiver in
///       receiverVariable == null ? null :
///         receiverVariable.propertyName = receiverVariable.propertyName + rhs
///
class NullAwareCompoundSet extends InternalExpression {
  /// The receiver on which the null aware operation is performed.
  Expression receiver;

  /// The name of the null-aware property.
  Name propertyName;

  /// The name of the binary operation.
  Name binaryName;

  /// The right-hand side of the binary expression.
  Expression rhs;

  /// The file offset for the read operation.
  final int readOffset;

  /// The file offset for the write operation.
  final int writeOffset;

  /// The file offset for the binary operation.
  final int binaryOffset;

  /// If `true`, the expression is only need for effect and not for its value.
  final bool forEffect;

  /// If `true`, the expression is a postfix inc/dec expression.
  final bool forPostIncDec;

  NullAwareCompoundSet(
      this.receiver, this.propertyName, this.binaryName, this.rhs,
      {required this.readOffset,
      required this.binaryOffset,
      required this.writeOffset,
      required this.forEffect,
      required this.forPostIncDec})
      // ignore: unnecessary_null_comparison
      : assert(receiver != null),
        // ignore: unnecessary_null_comparison
        assert(rhs != null),
        // ignore: unnecessary_null_comparison
        assert(readOffset != null),
        // ignore: unnecessary_null_comparison
        assert(binaryOffset != null),
        // ignore: unnecessary_null_comparison
        assert(writeOffset != null),
        // ignore: unnecessary_null_comparison
        assert(forEffect != null),
        // ignore: unnecessary_null_comparison
        assert(forPostIncDec != null) {
    receiver.parent = this;
    rhs.parent = this;
    fileOffset = binaryOffset;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    return visitor.visitNullAwareCompoundSet(this, typeContext);
  }

  @override
  String toString() {
    return "NullAwareCompoundSet(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver);
    printer.write('?.');
    printer.writeName(propertyName);
    if (forPostIncDec &&
        rhs is IntLiteral &&
        (rhs as IntLiteral).value == 1 &&
        (binaryName == plusName || binaryName == minusName)) {
      if (binaryName == plusName) {
        printer.write('++');
      } else {
        printer.write('--');
      }
    } else {
      printer.write(' ');
      printer.writeName(binaryName);
      printer.write('= ');
      printer.writeExpression(rhs);
    }
  }
}

/// Internal expression representing an null-aware if-null property set.
///
/// A null-aware if-null property set of the form
///
///    receiver?.name ??= value
///
/// is, if used for value, encoded as the expression:
///
///     let receiverVariable = receiver in
///       receiverVariable == null ? null :
///         (let readVariable = receiverVariable.name in
///           readVariable == null ?
///             receiverVariable.name = value : readVariable)
///
/// and, if used for effect, encoded as the expression:
///
///     let receiverVariable = receiver in
///       receiverVariable == null ? null :
///         (receiverVariable.name == null ?
///           receiverVariable.name = value : null)
///
///
class NullAwareIfNullSet extends InternalExpression {
  /// The synthetic variable whose initializer hold the receiver.
  Expression receiver;

  /// The expression that reads the property from [variable].
  Name name;

  /// The expression that writes the value to the property on [variable].
  Expression value;

  /// The file offset for the read operation.
  final int readOffset;

  /// The file offset for the write operation.
  final int writeOffset;

  /// The file offset for the == operation.
  final int testOffset;

  /// If `true`, the expression is only need for effect and not for its value.
  final bool forEffect;

  NullAwareIfNullSet(this.receiver, this.name, this.value,
      {required this.readOffset,
      required this.writeOffset,
      required this.testOffset,
      required this.forEffect})
      // ignore: unnecessary_null_comparison
      : assert(receiver != null),
        // ignore: unnecessary_null_comparison
        assert(value != null),
        // ignore: unnecessary_null_comparison
        assert(readOffset != null),
        // ignore: unnecessary_null_comparison
        assert(writeOffset != null),
        // ignore: unnecessary_null_comparison
        assert(testOffset != null),
        // ignore: unnecessary_null_comparison
        assert(forEffect != null) {
    receiver.parent = this;
    value.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    return visitor.visitNullAwareIfNullSet(this, typeContext);
  }

  @override
  String toString() {
    return "NullAwareIfNullSet(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver);
    printer.write('?.');
    printer.writeName(name);
    printer.write(' ??= ');
    printer.writeExpression(value);
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

  CompoundSuperIndexSet(
      this.getter, this.setter, this.index, this.binaryName, this.rhs,
      {required this.readOffset,
      required this.binaryOffset,
      required this.writeOffset,
      required this.forEffect,
      required this.forPostIncDec})
      // ignore: unnecessary_null_comparison
      : assert(index != null),
        // ignore: unnecessary_null_comparison
        assert(rhs != null),
        // ignore: unnecessary_null_comparison
        assert(readOffset != null),
        // ignore: unnecessary_null_comparison
        assert(binaryOffset != null),
        // ignore: unnecessary_null_comparison
        assert(writeOffset != null),
        // ignore: unnecessary_null_comparison
        assert(forEffect != null),
        // ignore: unnecessary_null_comparison
        assert(forPostIncDec != null) {
    index.parent = this;
    rhs.parent = this;
    fileOffset = binaryOffset;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    return visitor.visitCompoundSuperIndexSet(this, typeContext);
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
class CompoundExtensionIndexSet extends InternalExpression {
  final Extension extension;

  final List<DartType>? explicitTypeArguments;

  Expression receiver;

  /// The [] member.
  Member? getter;

  /// The []= member.
  Member? setter;

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

  CompoundExtensionIndexSet(
      this.extension,
      this.explicitTypeArguments,
      this.receiver,
      this.getter,
      this.setter,
      this.index,
      this.binaryName,
      this.rhs,
      {required this.readOffset,
      required this.binaryOffset,
      required this.writeOffset,
      required this.forEffect,
      required this.forPostIncDec})
      : assert(explicitTypeArguments == null ||
            explicitTypeArguments.length == extension.typeParameters.length),
        // ignore: unnecessary_null_comparison
        assert(receiver != null),
        // ignore: unnecessary_null_comparison
        assert(index != null),
        // ignore: unnecessary_null_comparison
        assert(rhs != null),
        // ignore: unnecessary_null_comparison
        assert(readOffset != null),
        // ignore: unnecessary_null_comparison
        assert(binaryOffset != null),
        // ignore: unnecessary_null_comparison
        assert(writeOffset != null),
        // ignore: unnecessary_null_comparison
        assert(forEffect != null),
        // ignore: unnecessary_null_comparison
        assert(forPostIncDec != null) {
    receiver.parent = this;
    index.parent = this;
    rhs.parent = this;
    fileOffset = binaryOffset;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    return visitor.visitCompoundExtensionIndexSet(this, typeContext);
  }

  @override
  String toString() {
    return "CompoundExtensionIndexSet(${toStringInternal()})";
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
  final Extension extension;

  final List<DartType>? explicitTypeArguments;

  /// The receiver for the assignment.
  Expression receiver;

  /// The extension member called for the assignment.
  Procedure target;

  /// The right-hand side value of the assignment.
  Expression value;

  /// If `true` the assignment is only needed for effect and not its result
  /// value.
  final bool forEffect;

  ExtensionSet(this.extension, this.explicitTypeArguments, this.receiver,
      this.target, this.value,
      {required this.forEffect})
      : assert(explicitTypeArguments == null ||
            explicitTypeArguments.length == extension.typeParameters.length),
        // ignore: unnecessary_null_comparison
        assert(receiver != null),
        // ignore: unnecessary_null_comparison
        assert(value != null),
        // ignore: unnecessary_null_comparison
        assert(forEffect != null) {
    receiver.parent = this;
    value.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    return visitor.visitExtensionSet(this, typeContext);
  }

  @override
  String toString() {
    return "ExtensionSet(${toStringInternal()})";
  }
}

/// Internal expression representing an null-aware extension expression.
///
/// An null-aware extension expression of the form `Extension(receiver)?.target`
/// is encoded as the expression:
///
///     let variable = receiver in
///       variable == null ? null : expression
///
/// where `expression` is an encoding of `receiverVariable.target`.
class NullAwareExtension extends InternalExpression {
  VariableDeclarationImpl variable;
  Expression expression;

  NullAwareExtension(this.variable, this.expression)
      // ignore: unnecessary_null_comparison
      : assert(variable != null),
        // ignore: unnecessary_null_comparison
        assert(expression != null) {
    variable.parent = this;
    expression.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    return visitor.visitNullAwareExtension(this, typeContext);
  }

  @override
  String toString() {
    return "NullAwareExtension(${toStringInternal()})";
  }
}

/// Internal representation of a read of an extension instance member.
///
/// A read of an extension instance member `o.foo` is encoded as the
/// [StaticInvocation]
///
///     extension|foo(o)
///
/// where `extension|foo` is the top level method created for reading the
/// `foo` member. If `foo` is an extension instance method, then `extension|foo`
/// the special tear-off function created for extension instance methods.
/// Otherwise `extension|foo` is the top level method corresponding to the
/// extension instance getter being read.
class ExtensionTearOff extends InternalExpression {
  /// The top-level method that is that target for the read operation.
  Procedure target;

  /// The arguments provided to the top-level method.
  Arguments arguments;

  ExtensionTearOff(this.target, this.arguments)
      // ignore: unnecessary_null_comparison
      : assert(arguments != null) {
    arguments.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    return visitor.visitExtensionTearOff(this, typeContext);
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

  EqualsExpression(this.left, this.right, {required this.isNot})
      // ignore: unnecessary_null_comparison
      : assert(left != null),
        // ignore: unnecessary_null_comparison
        assert(right != null),
        // ignore: unnecessary_null_comparison
        assert(isNot != null) {
    left.parent = this;
    right.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    return visitor.visitEquals(this, typeContext);
  }

  @override
  String toString() {
    return "EqualsExpression(${toStringInternal()})";
  }

  @override
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

  BinaryExpression(this.left, this.binaryName, this.right)
      // ignore: unnecessary_null_comparison
      : assert(left != null),
        // ignore: unnecessary_null_comparison
        assert(right != null) {
    left.parent = this;
    right.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    return visitor.visitBinary(this, typeContext);
  }

  @override
  String toString() {
    return "BinaryExpression(${toStringInternal()})";
  }

  @override
  int get precedence => Precedence.binaryPrecedence[binaryName.text]!;

  @override
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

  UnaryExpression(this.unaryName, this.expression)
      // ignore: unnecessary_null_comparison
      : assert(expression != null) {
    expression.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    return visitor.visitUnary(this, typeContext);
  }

  @override
  int get precedence => Precedence.PREFIX;

  @override
  String toString() {
    return "UnaryExpression(${toStringInternal()})";
  }

  @override
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

  ParenthesizedExpression(this.expression)
      // ignore: unnecessary_null_comparison
      : assert(expression != null) {
    expression.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    return visitor.visitParenthesized(this, typeContext);
  }

  @override
  int get precedence => Precedence.CALLEE;

  @override
  String toString() {
    return "ParenthesizedExpression(${toStringInternal()})";
  }

  @override
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
    return node.variable.isFinal && !node.variable.isLate;
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
        " ${node.variable}.");
    return new VariableGet(node.variable, node.promotedType)
      ..fileOffset = node.fileOffset;
  }
  throw new UnsupportedError("Clone not supported for ${node.runtimeType}.");
}

/// A dynamically bound method invocation of the form `o.foo()`.
///
/// This will be transformed into an [InstanceInvocation], [DynamicInvocation],
/// [FunctionInvocation] or [StaticInvocation] (for implicit extension method
/// invocation) after type inference.
class MethodInvocation extends InternalExpression {
  Expression receiver;

  Name name;

  Arguments arguments;

  MethodInvocation(this.receiver, this.name, this.arguments)
      // ignore: unnecessary_null_comparison
      : assert(receiver != null),
        // ignore: unnecessary_null_comparison
        assert(arguments != null) {
    receiver.parent = this;
    arguments.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    return visitor.visitMethodInvocation(this, typeContext);
  }

  @override
  String toString() {
    return "MethodInvocation(${toStringInternal()})";
  }

  @override
  int get precedence => Precedence.PRIMARY;

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver, minimumPrecedence: Precedence.PRIMARY);
    printer.write('.');
    printer.writeName(name);
    printer.writeArguments(arguments);
  }
}

/// A dynamically bound property read of the form `o.foo`.
///
/// This will be transformed into an [InstanceGet], [InstanceTearOff],
/// [DynamicGet], [FunctionTearOff] or [StaticInvocation] (for implicit
/// extension member access) after type inference.
class PropertyGet extends InternalExpression {
  Expression receiver;

  Name name;

  PropertyGet(this.receiver, this.name)
      // ignore: unnecessary_null_comparison
      : assert(receiver != null) {
    receiver.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    return visitor.visitPropertyGet(this, typeContext);
  }

  @override
  String toString() {
    return "PropertyGet(${toStringInternal()})";
  }

  @override
  int get precedence => Precedence.PRIMARY;

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver, minimumPrecedence: Precedence.PRIMARY);
    printer.write('.');
    printer.writeName(name);
  }
}

/// A dynamically bound property write of the form `o.foo = e`.
///
/// This will be transformed into an [InstanceSet], [DynamicSet], or
/// [StaticInvocation] (for implicit extension member access) after type
/// inference.
class PropertySet extends InternalExpression {
  Expression receiver;
  Name name;
  Expression value;

  /// If `true` the assignment is need for its effect and not for its value.
  final bool forEffect;

  /// If `true` the receiver can be cloned and doesn't need a temporary variable
  /// for multiple reads.
  final bool readOnlyReceiver;

  PropertySet(this.receiver, this.name, this.value,
      {required this.forEffect, required this.readOnlyReceiver})
      // ignore: unnecessary_null_comparison
      : assert(receiver != null),
        // ignore: unnecessary_null_comparison
        assert(value != null),
        // ignore: unnecessary_null_comparison
        assert(forEffect != null),
        // ignore: unnecessary_null_comparison
        assert(readOnlyReceiver != null) {
    receiver.parent = this;
    value.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    return visitor.visitPropertySet(this, typeContext);
  }

  @override
  String toString() {
    return "PropertySet(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(receiver, minimumPrecedence: Precedence.PRIMARY);
    printer.write('.');
    printer.writeName(name);
    printer.write(' = ');
    printer.writeExpression(value);
  }
}

/// An augment super invocation of the form `augment super()`.
///
/// This will be transformed into an [InstanceInvocation], [InstanceGet] plus
/// [FunctionInvocation], or [StaticInvocation] after type inference.
class AugmentSuperInvocation extends InternalExpression {
  final Member target;

  Arguments arguments;

  AugmentSuperInvocation(this.target, this.arguments,
      {required int fileOffset}) {
    arguments.parent = this;
    this.fileOffset = fileOffset;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
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
    printer.writeArguments(arguments);
  }
}

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
      InferenceVisitorImpl visitor, DartType typeContext) {
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

/// An augment super write of the form `augment super = e`.
///
/// This will be transformed into an [InstanceSet], or [StaticSet] after type
/// inference.
class AugmentSuperSet extends InternalExpression {
  final Member target;

  Expression value;

  /// If `true` the assignment is need for its effect and not for its value.
  final bool forEffect;

  AugmentSuperSet(this.target, this.value,
      {required this.forEffect, required int fileOffset}) {
    value.parent = this;
    this.fileOffset = fileOffset;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
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
  final List<Object /*Expression|NamedExpression*/ > originalElementOrder;
  final bool isConst;

  InternalRecordLiteral(this.positional, this.named, this.namedElements,
      this.originalElementOrder,
      {required this.isConst, required int offset}) {
    fileOffset = offset;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    return visitor.visitInternalRecordLiteral(this, typeContext);
  }

  @override
  String toString() {
    return "InternalRecordLiteral(${toStringInternal()})";
  }

  @override
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

abstract class Pattern extends TreeNode with InternalTreeNode {
  Pattern(int fileOffset) {
    this.fileOffset = fileOffset;
  }

  /// Variable declarations induced by nested variable patterns.
  ///
  /// These variables are initialized to the values captured by the variable
  /// patterns nested in the pattern.
  List<VariableDeclaration> get declaredVariables;

  void acceptInference(
    InferenceVisitorImpl visitor, {
    required SharedMatchContext context,
  });

  /// Transforms a pattern into a series of if-statements and local variables
  ///
  /// [matchedExpression] is the expression that evaluates to the object being
  /// matched against the pattern at runtime. [matchedType] is the static type
  /// of [matchedExpression]. [variableInitializingContext] evaluates to the
  /// same runtime objects as [matchedExpression], but can be accessed without
  /// causing additional side effects. It is the responsibility of the caller to
  /// ensure the absence of those side effects, which can be done, for example,
  /// via caching of the value to match in a local variable.
  PatternTransformationResult transform(InferenceVisitorBase base,
      {required Expression matchedExpression,
      required DartType matchedType,
      required Expression variableInitializingContext});
}

class DummyPattern extends Pattern {
  DummyPattern(int fileOffset) : super(fileOffset);

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('<dummy-pattern>');
  }

  @override
  List<VariableDeclaration> get declaredVariables => const [];

  @override
  void acceptInference(
    InferenceVisitorImpl visitor, {
    required SharedMatchContext context,
  }) {
    visitor.visitDummyPattern(this, context: context);
  }

  @override
  PatternTransformationResult transform(InferenceVisitorBase base,
      {required Expression matchedExpression,
      required DartType matchedType,
      required Expression variableInitializingContext}) {
    return new PatternTransformationResult([
      new PatternTransformationElement(
          kind: PatternTransformationElementKind.regular,
          condition: null,
          variableInitializers: <Statement>[])
    ]);
  }

  @override
  String toString() {
    return "DummyPattern(${toStringInternal()})";
  }
}

/// A [Pattern] based on an [Expression]. This corresponds to a constant
/// pattern in the specification.
class ExpressionPattern extends Pattern {
  Expression expression;

  /// Static type of the expression as computed during inference.
  // TODO(johnniwinther): Use UnknownType instead to flag when this type has
  // not been computed.
  DartType expressionType = const DynamicType();

  ExpressionPattern(this.expression) : super(expression.fileOffset) {
    expression.parent = this;
  }

  @override
  List<VariableDeclaration> get declaredVariables => const [];

  @override
  void acceptInference(
    InferenceVisitorImpl visitor, {
    required SharedMatchContext context,
  }) {
    visitor.visitExpressionPattern(this, context: context);
  }

  @override
  PatternTransformationResult transform(InferenceVisitorBase base,
      {required Expression matchedExpression,
      required DartType matchedType,
      required Expression variableInitializingContext}) {
    VariableDeclaration constVariable =
        createVariableCache(expression, expressionType)..isConst = true;
    Expression result = createEqualsCall(
        base, matchedType, matchedExpression, createVariableGet(constVariable),
        fileOffset: fileOffset);
    return new PatternTransformationResult([
      new PatternTransformationElement(
          kind: PatternTransformationElementKind.regular,
          condition: result,
          variableInitializers: [constVariable])
    ]);
  }

  @override
  void toTextInternal(AstPrinter printer) {
    expression.toTextInternal(printer);
  }

  @override
  String toString() {
    return "ExpressionPattern(${toStringInternal()})";
  }
}

/// A [Pattern] for `pattern & pattern`.
class AndPattern extends Pattern {
  Pattern left;
  Pattern right;

  @override
  List<VariableDeclaration> get declaredVariables =>
      [...left.declaredVariables, ...right.declaredVariables];

  AndPattern(this.left, this.right, int fileOffset) : super(fileOffset) {
    left.parent = this;
    right.parent = this;
  }

  @override
  void acceptInference(
    InferenceVisitorImpl visitor, {
    required SharedMatchContext context,
  }) {
    visitor.visitAndPattern(this, context: context);
  }

  @override
  PatternTransformationResult transform(InferenceVisitorBase base,
      {required Expression matchedExpression,
      required DartType matchedType,
      required Expression variableInitializingContext}) {
    // intermediateVariable: `matchedType` VAR = `matchedExpression`
    VariableDeclaration intermediateVariable =
        createVariableCache(matchedExpression, matchedType);

    PatternTransformationResult transformationResult = left.transform(base,
        matchedExpression: createVariableGet(intermediateVariable),
        matchedType: matchedType,
        variableInitializingContext: createVariableGet(intermediateVariable));

    transformationResult = transformationResult.combine(
        right.transform(base,
            matchedExpression: createVariableGet(intermediateVariable),
            matchedType: matchedType,
            variableInitializingContext:
                createVariableGet(intermediateVariable)),
        base);

    transformationResult = transformationResult.prependElement(
        new PatternTransformationElement(
            kind: PatternTransformationElementKind.regular,
            condition: null,
            variableInitializers: [intermediateVariable]),
        base);

    return transformationResult;
  }

  @override
  void toTextInternal(AstPrinter printer) {
    left.toTextInternal(printer);
    printer.write(' & ');
    right.toTextInternal(printer);
  }

  @override
  String toString() {
    return "BinaryPattern(${toStringInternal()})";
  }
}

/// A [Pattern] for `pattern | pattern`.
class OrPattern extends Pattern {
  Pattern left;
  Pattern right;
  List<VariableDeclaration> _orPatternJointVariables;

  @override
  List<VariableDeclaration> get declaredVariables => _orPatternJointVariables;

  OrPattern(this.left, this.right, int fileOffset,
      {required List<VariableDeclaration> orPatternJointVariables})
      : _orPatternJointVariables = orPatternJointVariables,
        super(fileOffset) {
    left.parent = this;
    right.parent = this;
  }

  @override
  void acceptInference(
    InferenceVisitorImpl visitor, {
    required SharedMatchContext context,
  }) {
    visitor.visitOrPattern(this, context: context);
  }

  @override
  PatternTransformationResult transform(InferenceVisitorBase base,
      {required Expression matchedExpression,
      required DartType matchedType,
      required Expression variableInitializingContext}) {
    // intermediateVariable: `matchedType` VAR = `matchedExpression`
    VariableDeclaration intermediateVariable =
        createVariableCache(matchedExpression, matchedType);

    // leftConditionIsTrue: bool LVAR = false;
    VariableDeclaration leftConditionIsTrue = createInitializedVariable(
        createBoolLiteral(false, fileOffset: fileOffset),
        base.coreTypes.boolNonNullableRawType,
        fileOffset: fileOffset);

    Map<String, VariableDeclaration> leftVariablesByName = {
      for (VariableDeclaration variable in left.declaredVariables)
        variable.name!: variable
    };
    Map<String, VariableDeclaration> rightVariablesByName = {
      for (VariableDeclaration variable in right.declaredVariables)
        variable.name!: variable
    };
    List<VariableDeclaration> declaredVariables = this.declaredVariables;
    for (VariableDeclaration variable in declaredVariables) {
      VariableDeclaration? leftVariable = leftVariablesByName[variable.name!];
      VariableDeclaration? rightVariable = rightVariablesByName[variable.name!];

      if (leftVariable == null || rightVariable == null) {
        // TODO(cstefantsova): Make sure an error is reported.
        continue;
      }

      variable.initializer = createConditionalExpression(
          createVariableGet(leftConditionIsTrue),
          createVariableGet(leftVariable, promotedType: leftVariable.type),
          createVariableGet(rightVariable, promotedType: rightVariable.type),
          staticType: base.typeSchemaEnvironment.getStandardUpperBound(
              leftVariable.type, rightVariable.type,
              isNonNullableByDefault: true),
          fileOffset: fileOffset)
        ..parent = variable;
    }

    // setLeftConditionIsTrue: `leftConditionIsTrue` = true;
    //   ==> VAR = true;
    Statement setLeftConditionIsTrue = createExpressionStatement(
        createVariableSet(leftConditionIsTrue,
            createBoolLiteral(true, fileOffset: fileOffset),
            fileOffset: fileOffset));

    PatternTransformationResult leftTransformationResult = left.transform(base,
        matchedExpression: createVariableGet(intermediateVariable),
        matchedType: matchedType,
        variableInitializingContext: createVariableGet(intermediateVariable));
    leftTransformationResult = leftTransformationResult.prependElement(
        new PatternTransformationElement(
            kind: PatternTransformationElementKind.logicalOrPatternLeftBegin,
            condition: null,
            variableInitializers: []),
        base);

    // Initialize variables to values captured by [left].
    List<Statement> leftVariableInitializers = [setLeftConditionIsTrue];
    for (VariableDeclaration variable in left.declaredVariables) {
      // TODO(johnniwinther): Can the variable be const?
      variable.isFinal = false;
      leftVariableInitializers.add(createExpressionStatement(createVariableSet(
          variable, variable.initializer!,
          fileOffset: fileOffset)));
      variable.name = null;
      variable.initializer = null;
      variable.type = const DynamicType();
    }
    leftTransformationResult = leftTransformationResult.combine(
        new PatternTransformationResult([
          new PatternTransformationElement(
              kind: PatternTransformationElementKind.regular,
              condition: null,
              variableInitializers: leftVariableInitializers)
        ]),
        base);

    // rightConditionIsTrue: bool RVAR = false;
    VariableDeclaration rightConditionIsTrue = createInitializedVariable(
        createBoolLiteral(false, fileOffset: fileOffset),
        base.coreTypes.boolNonNullableRawType,
        fileOffset: fileOffset);

    // setRightConditionIsTrue: `rightConditionIsTrue` = true;
    //   ==> VAR = true;
    Statement setRightConditionIsTrue = createExpressionStatement(
        createVariableSet(rightConditionIsTrue,
            createBoolLiteral(true, fileOffset: fileOffset),
            fileOffset: fileOffset));

    PatternTransformationResult rightTransformationResult = right.transform(
        base,
        matchedExpression: createVariableGet(intermediateVariable),
        matchedType: matchedType,
        variableInitializingContext: createVariableGet(intermediateVariable));
    rightTransformationResult = rightTransformationResult.prependElement(
        new PatternTransformationElement(
            kind: PatternTransformationElementKind.regular,
            // condition: !`leftConditionIsTrue`
            condition: createNot(createVariableGet(leftConditionIsTrue)),
            variableInitializers: []),
        base);
    rightTransformationResult = rightTransformationResult.prependElement(
        new PatternTransformationElement(
            kind: PatternTransformationElementKind.logicalOrPatternRightBegin,
            condition: null,
            variableInitializers: []),
        base);

    // Initialize variables to values captured by [right].
    List<Statement> rightVariableInitializers = [setRightConditionIsTrue];
    for (VariableDeclaration variable in right.declaredVariables) {
      // TODO(johnniwinther): Can the variable be const?
      variable.isFinal = false;
      rightVariableInitializers.add(createExpressionStatement(createVariableSet(
          variable, variable.initializer!,
          fileOffset: fileOffset)));
      variable.name = null;
      variable.initializer = null;
      variable.type = const DynamicType();
    }
    rightTransformationResult = rightTransformationResult.combine(
        new PatternTransformationResult([
          new PatternTransformationElement(
              kind: PatternTransformationElementKind.regular,
              condition: null,
              variableInitializers: rightVariableInitializers)
        ]),
        base);

    PatternTransformationResult transformationResult = leftTransformationResult
        .combine(rightTransformationResult, base)
        .combine(
            new PatternTransformationResult([
              new PatternTransformationElement(
                  kind: PatternTransformationElementKind.logicalOrPatternEnd,
                  condition: null,
                  variableInitializers: []),
              new PatternTransformationElement(
                  kind: PatternTransformationElementKind.regular,
                  // condition:
                  //     `leftConditionIsTrue` || `rightConditionIsTrue`
                  condition: createOrExpression(
                      createVariableGet(leftConditionIsTrue),
                      createVariableGet(rightConditionIsTrue),
                      fileOffset: fileOffset),
                  variableInitializers: [])
            ]),
            base);

    transformationResult = transformationResult.prependElement(
        new PatternTransformationElement(
            kind: PatternTransformationElementKind.regular,
            condition: null,
            variableInitializers: [
              intermediateVariable,
              leftConditionIsTrue,
              rightConditionIsTrue,
              ...left.declaredVariables,
              ...right.declaredVariables
            ]),
        base);

    return transformationResult;
  }

  @override
  void toTextInternal(AstPrinter printer) {
    left.toTextInternal(printer);
    printer.write(' | ');
    right.toTextInternal(printer);
  }

  @override
  String toString() {
    return "BinaryPattern(${toStringInternal()})";
  }
}

/// A [Pattern] for `pattern as type`.
class CastPattern extends Pattern {
  Pattern pattern;
  DartType type;

  CastPattern(this.pattern, this.type, int fileOffset) : super(fileOffset) {
    pattern.parent = this;
  }

  @override
  List<VariableDeclaration> get declaredVariables => pattern.declaredVariables;

  @override
  void acceptInference(
    InferenceVisitorImpl visitor, {
    required SharedMatchContext context,
  }) {
    visitor.visitCastPattern(this, context: context);
  }

  @override
  PatternTransformationResult transform(InferenceVisitorBase base,
      {required Expression matchedExpression,
      required DartType matchedType,
      required Expression variableInitializingContext}) {
    // castExpression: `matchedExpression` as `type`
    Expression castExpression = createAsExpression(matchedExpression, type,
        forNonNullableByDefault: base.isNonNullableByDefault,
        fileOffset: fileOffset);

    // intermediateVariable: `type` VAR = `castExpression`;
    //   ==> `type` VAR = `matchedExpression` as `type`;
    VariableDeclaration intermediateVariable =
        createVariableCache(castExpression, type);

    PatternTransformationResult transformationResult = pattern.transform(base,
        matchedExpression: createVariableGet(intermediateVariable),
        matchedType: type,
        variableInitializingContext: createVariableGet(intermediateVariable));

    transformationResult = transformationResult.prependElement(
        new PatternTransformationElement(
            kind: PatternTransformationElementKind.regular,
            condition: null,
            variableInitializers: [intermediateVariable]),
        base);

    return transformationResult;
  }

  @override
  void toTextInternal(AstPrinter printer) {
    pattern.toTextInternal(printer);
    printer.write(' as ');
    printer.writeType(type);
  }

  @override
  String toString() {
    return "CastPattern(${toStringInternal()})";
  }
}

/// A [Pattern] for `pattern!`.
class NullAssertPattern extends Pattern {
  Pattern pattern;

  NullAssertPattern(this.pattern, int fileOffset) : super(fileOffset) {
    pattern.parent = this;
  }

  @override
  List<VariableDeclaration> get declaredVariables => pattern.declaredVariables;

  @override
  void acceptInference(
    InferenceVisitorImpl visitor, {
    required SharedMatchContext context,
  }) {
    visitor.visitNullAssertPattern(this, context: context);
  }

  @override
  PatternTransformationResult transform(InferenceVisitorBase base,
      {required Expression matchedExpression,
      required DartType matchedType,
      required Expression variableInitializingContext}) {
    // nullCheckCondition: `matchedExpression`!
    Expression nullCheckExpression =
        createNullCheck(matchedExpression, fileOffset: fileOffset);

    DartType typeWithoutNullabilityMarkers = matchedType.toNonNull();

    // intermediateVariable: `typeWithoutNullabilityMarkers` VAR =
    //     `nullCheckExpression`;
    //   ==> `typeWithoutNullabilityMarkers` VAR = `matchedExpression`!;
    VariableDeclaration intermediateVariable =
        createVariableCache(nullCheckExpression, typeWithoutNullabilityMarkers);

    PatternTransformationResult transformationResult = pattern.transform(base,
        matchedExpression: createVariableGet(intermediateVariable),
        matchedType: typeWithoutNullabilityMarkers,
        variableInitializingContext: createVariableGet(intermediateVariable));

    transformationResult = transformationResult.prependElement(
        new PatternTransformationElement(
            kind: PatternTransformationElementKind.regular,
            condition: null,
            variableInitializers: [intermediateVariable]),
        base);

    return transformationResult;
  }

  @override
  void toTextInternal(AstPrinter printer) {
    pattern.toTextInternal(printer);
    printer.write('!');
  }

  @override
  String toString() {
    return "NullAssertPattern(${toStringInternal()})";
  }
}

/// A [Pattern] for `pattern?`.
class NullCheckPattern extends Pattern {
  Pattern pattern;

  NullCheckPattern(this.pattern, int fileOffset) : super(fileOffset) {
    pattern.parent = this;
  }

  @override
  List<VariableDeclaration> get declaredVariables => pattern.declaredVariables;

  @override
  void acceptInference(
    InferenceVisitorImpl visitor, {
    required SharedMatchContext context,
  }) {
    visitor.visitNullCheckPattern(this, context: context);
  }

  @override
  PatternTransformationResult transform(InferenceVisitorBase base,
      {required Expression matchedExpression,
      required DartType matchedType,
      required Expression variableInitializingContext}) {
    // intermediateVariable: `matchedType` VAR = `matchedExpression`
    VariableDeclaration intermediateVariable =
        createVariableCache(matchedExpression, matchedType);

    // nullCheckCondition: !(`intermediateVariable` == null)
    Expression nullCheckCondition = createNot(
        createEqualsNull(fileOffset, createVariableGet(intermediateVariable)));

    DartType promotedType = matchedType.toNonNull();
    PatternTransformationResult transformationResult = pattern.transform(base,
        matchedExpression: createVariableGet(intermediateVariable,
            promotedType: matchedType != promotedType ? promotedType : null),
        matchedType: promotedType,
        variableInitializingContext: createVariableGet(intermediateVariable));

    // This needs to be added to the transformation elements since we need to
    // create the [intermediateVariable] unconditionally before applying the
    // [nullCheckCondition], as opposed to passing [nullCheckCondition] as the
    // condition in the last transformation element.
    transformationResult = transformationResult.prependElement(
        new PatternTransformationElement(
            kind: PatternTransformationElementKind.regular,
            condition: nullCheckCondition,
            variableInitializers: []),
        base);
    transformationResult = transformationResult.prependElement(
        new PatternTransformationElement(
            kind: PatternTransformationElementKind.regular,
            condition: null,
            variableInitializers: [intermediateVariable]),
        base);

    return transformationResult;
  }

  @override
  void toTextInternal(AstPrinter printer) {
    pattern.toTextInternal(printer);
    printer.write('?');
  }

  @override
  String toString() {
    return "NullCheckPattern(${toStringInternal()})";
  }
}

/// A [Pattern] for `<typeArgument>[pattern0, ... patternN]`.
class ListPattern extends Pattern {
  DartType? typeArgument;
  List<Pattern> patterns;

  @override
  List<VariableDeclaration> get declaredVariables =>
      [for (Pattern pattern in patterns) ...pattern.declaredVariables];

  ListPattern(this.typeArgument, this.patterns, int fileOffset)
      : super(fileOffset) {
    setParents(patterns, this);
  }

  @override
  void acceptInference(
    InferenceVisitorImpl visitor, {
    required SharedMatchContext context,
  }) {
    visitor.visitListPattern(this, context: context);
  }

  @override
  PatternTransformationResult transform(InferenceVisitorBase base,
      {required Expression matchedExpression,
      required DartType matchedType,
      required Expression variableInitializingContext}) {
    // targetListType: List<`typeArgument`>
    DartType typeArgument = this.typeArgument ?? const DynamicType();
    DartType targetListType = new InterfaceType(base.coreTypes.listClass,
        Nullability.nonNullable, <DartType>[typeArgument]);

    bool typeCheckForTargetListNeeded =
        !base.isAssignable(targetListType, matchedType) ||
            matchedType is DynamicType;

    // listVariable: `matchedType` LVAR = `matchedExpression`
    VariableDeclaration listVariable =
        createVariableCache(matchedExpression, matchedType);
    DartType? listVariablePromotedType =
        typeCheckForTargetListNeeded ? targetListType : null;

    // lengthGet: `listVariable`.length
    //   ==> LVAR.length
    Expression lengthGet = createInstanceGet(
        base,
        targetListType,
        createVariableGet(listVariable, promotedType: listVariablePromotedType),
        lengthName,
        fileOffset: fileOffset);

    Expression lengthCheck;
    bool hasRestPattern = false;
    for (Pattern pattern in patterns) {
      if (pattern is RestPattern) {
        hasRestPattern = true;
        break;
      }
    }
    if (hasRestPattern) {
      // lengthCheck: `lengthGet` >= `patterns.length - 1`
      //   ==> LVAR.length >= `patterns.length - 1`
      lengthCheck = createOperatorInvocation(
          base,
          base.coreTypes.intNonNullableRawType,
          lengthGet,
          greaterThanOrEqualsName,
          createIntLiteral(patterns.length - 1, fileOffset: fileOffset),
          fileOffset: fileOffset);
    } else {
      // lengthCheck: `lengthGet` == `patterns.length`
      lengthCheck = createEqualsCall(base, base.coreTypes.intNonNullableRawType,
          lengthGet, createIntLiteral(patterns.length, fileOffset: fileOffset),
          fileOffset: fileOffset);
    }

    // typeAndLengthCheck: `listVariable` is `targetListType`
    //     && `greaterThanOrEqualsInvocation`
    //   ==> [LVAR is List<`typeArgument`> &&]?
    //       LVAR.length >= `patterns.length`
    Expression typeAndLengthCheck;
    if (typeCheckForTargetListNeeded) {
      typeAndLengthCheck = createAndExpression(
          createIsExpression(createVariableGet(listVariable), targetListType,
              forNonNullableByDefault: false, fileOffset: fileOffset),
          lengthCheck,
          fileOffset: fileOffset);
    } else {
      typeAndLengthCheck = lengthCheck;
    }

    PatternTransformationResult transformationResult =
        new PatternTransformationResult([]);
    List<VariableDeclaration> elementAccessVariables = [];
    bool hasSeenRestPattern = false;
    for (int i = 0; i < patterns.length; i++) {
      Expression listElement;
      DartType listElementType;
      if (patterns[i] is RestPattern) {
        hasSeenRestPattern = true;
        Pattern? subPattern = (patterns[i] as RestPattern).subPattern;
        if (subPattern == null) {
          continue;
        }
        // startIndex: `i`
        Expression startIndex = createIntLiteral(i, fileOffset: fileOffset);

        // endIndex: `listVariable`.length - `patterns.length - i`
        //   ==> LVAR.length - `patterns.length - i`

        // lengthGet: `listVariable`.length ==> LVAR.length
        Expression lengthGet = createInstanceGet(
            base,
            targetListType,
            createVariableGet(listVariable,
                promotedType: listVariablePromotedType),
            lengthName,
            fileOffset: fileOffset);

        int nextIndex = i + 1;
        Expression? endIndex;
        if (nextIndex != patterns.length) {
          // endIndex: `lengthGet` - `patterns.length - nextIndex`
          //   ==> LVAR.length - `patterns.length - nextIndex`
          endIndex = createOperatorInvocation(
              base,
              base.coreTypes.intNonNullableRawType,
              lengthGet,
              minusName,
              createIntLiteral(patterns.length - nextIndex,
                  fileOffset: fileOffset),
              fileOffset: fileOffset);
        }

        // listElement: `listVariable`.subList(`startIndex`,`endIndex`)
        //   ==> LVAR.subList(`startIndex`,`endIndex`)
        InstanceInvocation sublist = listElement = createInstanceInvocation(
            base,
            targetListType,
            createVariableGet(listVariable,
                promotedType: listVariablePromotedType),
            sublistName,
            [startIndex, if (endIndex != null) endIndex],
            fileOffset: fileOffset);
        listElementType = sublist.functionType.returnType;
      } else {
        Expression elementIndex;
        if (!hasSeenRestPattern) {
          // elementIndex: `i`
          elementIndex = createIntLiteral(i, fileOffset: fileOffset);
        } else {
          // elementIndex: `listVariable`.length - `patterns.length - i`
          //   ==> LVAR.length - `patterns.length - i`

          // lengthGet: `listVariable`.length ==> LVAR.length
          Expression lengthGet = createInstanceGet(
              base,
              targetListType,
              createVariableGet(listVariable,
                  promotedType: listVariablePromotedType),
              lengthName,
              fileOffset: fileOffset);

          // elementIndex: `lengthGet` - `patterns.length - i`
          //   ==> LVAR.length - `patterns.length - i`
          elementIndex = createOperatorInvocation(
              base,
              base.coreTypes.intNonNullableRawType,
              lengthGet,
              minusName,
              createIntLiteral(patterns.length - i, fileOffset: fileOffset),
              fileOffset: fileOffset);
        }

        // listElement: `listVariable`[`elementIndex`]
        //   ==> LVAR[`elementIndex`]
        listElement = createOperatorInvocation(
            base,
            targetListType,
            createVariableGet(listVariable,
                promotedType: listVariablePromotedType),
            indexGetName,
            elementIndex,
            fileOffset: fileOffset);
        listElementType = typeArgument;
      }

      // listElementVariable: `typeArgument` EVAR = `listElement`
      //   ==> `typeArgument` EVAR = LVAR[`i`]
      VariableDeclaration listElementVariable =
          createVariableCache(listElement, listElementType);

      PatternTransformationResult subpatternTransformationResult = patterns[i]
          .transform(base,
              matchedExpression: createVariableGet(listElementVariable),
              matchedType: typeArgument,
              variableInitializingContext:
                  createVariableGet(listElementVariable));

      // If the sub-pattern transformation doesn't declare captured variables
      // and consists of a single empty element, it means that it simply
      // doesn't have a place where it could refer to the element expression.
      // In that case we can avoid creating the intermediary variable for the
      // element expression.
      //
      // An example of such sub-pattern is in the following:
      //
      // if (x case [var _]) { /* ... */ }
      if (patterns[i].declaredVariables.isNotEmpty ||
          !(subpatternTransformationResult.elements.length == 1 &&
              subpatternTransformationResult.elements.single.isEmpty)) {
        elementAccessVariables.add(listElementVariable);
        transformationResult =
            transformationResult.combine(subpatternTransformationResult, base);
      }
    }

    transformationResult = transformationResult.prependElement(
        new PatternTransformationElement(
            kind: PatternTransformationElementKind.regular,
            condition: typeAndLengthCheck,
            variableInitializers: elementAccessVariables),
        base);

    transformationResult = transformationResult.prependElement(
        new PatternTransformationElement(
            kind: PatternTransformationElementKind.regular,
            condition: null,
            variableInitializers: [listVariable]),
        base);

    return transformationResult;
  }

  @override
  void toTextInternal(AstPrinter printer) {
    if (typeArgument != null) {
      printer.write('<');
      printer.writeType(typeArgument!);
      printer.write('>');
    }
    printer.write('[');
    String comma = '';
    for (Pattern pattern in patterns) {
      printer.write(comma);
      pattern.toTextInternal(printer);
      comma = ', ';
    }
    printer.write(']');
  }

  @override
  String toString() {
    return "ListPattern(${toStringInternal()})";
  }
}

class ObjectPattern extends Pattern {
  final Reference classReference;
  final List<NamedPattern> fields;
  final List<DartType>? typeArguments;

  Class get classNode => classReference.asClass;

  ObjectPattern(
      this.classReference, this.fields, this.typeArguments, int fileOffset)
      : super(fileOffset) {
    setParents(fields, this);
  }

  @override
  void acceptInference(InferenceVisitorImpl visitor,
      {required SharedMatchContext context}) {
    visitor.visitObjectPattern(this, context: context);
  }

  @override
  List<VariableDeclaration> get declaredVariables {
    return [for (NamedPattern field in fields) ...field.declaredVariables];
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('${classNode.name}');
    if (typeArguments != null) {
      printer.write('<');
      printer.writeTypes(typeArguments!);
      printer.write('>');
    }
    printer.write('(');
    String comma = '';
    for (Pattern field in fields) {
      printer.write(comma);
      field.toTextInternal(printer);
      comma = ', ';
    }
    printer.write(')');
  }

  @override
  String toString() {
    return "ObjectPattern(${toStringInternal()})";
  }

  @override
  PatternTransformationResult transform(InferenceVisitorBase base,
      {required Expression matchedExpression,
      required DartType matchedType,
      required Expression variableInitializingContext}) {
    // targetObjectType: `classNode`<`typeArguments`>
    DartType targetObjectType;
    if (typeArguments != null &&
        typeArguments!.length == classNode.typeParameters.length) {
      targetObjectType =
          new InterfaceType(classNode, Nullability.nonNullable, typeArguments);
    } else {
      if (typeArguments != null) {
        // TODO(cstefantsova): Report an error.
      }
      targetObjectType = new InterfaceType(
          classNode,
          Nullability.nonNullable,
          calculateBounds(classNode.typeParameters, base.coreTypes.objectClass,
              base.libraryBuilder.library));
    }

    bool typeCheckForTargetNeeded =
        !base.isAssignable(targetObjectType, matchedType) ||
            matchedType is DynamicType;

    // objectVariable: `matchedType` OVAR = `matchedExpression`
    VariableDeclaration objectVariable =
        createVariableCache(matchedExpression, matchedType);

    // typeCheck: `objectVariable` is `targetObjectType`
    //   ==> OVAR is `classNode`<`typeArguments`>
    Expression? typeCheck;
    if (typeCheckForTargetNeeded) {
      typeCheck = createIsExpression(
          createVariableGet(objectVariable), targetObjectType,
          forNonNullableByDefault: false, fileOffset: fileOffset);
    }

    List<VariableDeclaration> elementAccessVariables = [];
    PatternTransformationResult transformationResult =
        new PatternTransformationResult([]);
    for (NamedPattern field in fields) {
      String? fieldNameString;
      if (field.name.isNotEmpty) {
        fieldNameString = field.name;
      } else {
        // The name is defined by the nested variable pattern.
        Pattern nestedPattern = field.pattern;
        if (nestedPattern is VariablePattern) {
          fieldNameString = nestedPattern.name;
        }
      }

      Expression objectElement;
      DartType fieldType;
      if (fieldNameString != null) {
        Name fieldName = new Name(fieldNameString);

        ObjectAccessTarget fieldAccessTarget = base.findInterfaceMember(
            targetObjectType, fieldName, fileOffset,
            callSiteAccessKind: CallSiteAccessKind.getterInvocation);

        if (fieldAccessTarget.member != null) {
          fieldType = fieldAccessTarget.getGetterType(base);

          // objectElement: `objectVariable`.`fieldName`
          //   ==> OVAR.`fieldName`
          objectElement = createInstanceGet(
              base,
              targetObjectType,
              createVariableGet(objectVariable, promotedType: targetObjectType),
              fieldName,
              fileOffset: fileOffset);
        } else {
          objectElement = base.helper.buildProblem(
              templateUndefinedGetter.withArguments(fieldNameString,
                  targetObjectType, base.isNonNullableByDefault),
              fileOffset,
              noLength);
          fieldType = const InvalidType();
        }
      } else {
        objectElement = base.helper.buildProblem(
            messageUnspecifiedGetterNameInObjectPattern, fileOffset, noLength);
        fieldType = const InvalidType();
      }

      // objectElementVariable: `fieldType` EVAR = `objectElement`
      //   ==> `fieldType` EVAR = OVAR.`fieldName`
      VariableDeclaration objectElementVariable =
          createVariableCache(objectElement, fieldType);

      PatternTransformationResult subpatternTransformationResult = field.pattern
          .transform(base,
              matchedExpression: createVariableGet(objectElementVariable),
              matchedType: fieldType,
              variableInitializingContext:
                  createVariableGet(objectElementVariable));

      // If the sub-pattern transformation doesn't declare captured variables
      // and consists of a single empty element, it means that it simply
      // doesn't have a place where it could refer to the element expression.
      // In that case we can avoid creating the intermediary variable for the
      // element expression.
      //
      // An example of such sub-pattern is in the following:
      //
      // if (x case A(foo: var _) { /* ... */ }
      if (field.declaredVariables.isNotEmpty ||
          !(subpatternTransformationResult.elements.length == 1 &&
              subpatternTransformationResult.elements.single.isEmpty)) {
        elementAccessVariables.add(objectElementVariable);
        transformationResult =
            transformationResult.combine(subpatternTransformationResult, base);
      }
    }

    transformationResult = transformationResult.prependElement(
        new PatternTransformationElement(
            kind: PatternTransformationElementKind.regular,
            condition: null,
            variableInitializers: elementAccessVariables),
        base);

    if (typeCheck != null) {
      transformationResult = transformationResult.prependElement(
          new PatternTransformationElement(
              kind: PatternTransformationElementKind.regular,
              condition: typeCheck,
              variableInitializers: []),
          base);
    }

    transformationResult = transformationResult.prependElement(
        new PatternTransformationElement(
            kind: PatternTransformationElementKind.regular,
            condition: null,
            variableInitializers: [objectVariable]),
        base);

    return transformationResult;
  }
}

enum RelationalPatternKind {
  equals,
  notEquals,
  lessThan,
  lessThanEqual,
  greaterThan,
  greaterThanEqual,
}

/// A [Pattern] for `operator expression` where `operator  is either ==, !=,
/// <, <=, >, or >=.
class RelationalPattern extends Pattern {
  final RelationalPatternKind kind;
  Expression expression;

  RelationalPattern(this.kind, this.expression, int fileOffset)
      : super(fileOffset) {
    expression.parent = this;
  }

  @override
  List<VariableDeclaration> get declaredVariables => const [];

  @override
  void acceptInference(
    InferenceVisitorImpl visitor, {
    required SharedMatchContext context,
  }) {
    visitor.visitRelationalPattern(this, context: context);
  }

  @override
  PatternTransformationResult transform(InferenceVisitorBase base,
      {required Expression matchedExpression,
      required DartType matchedType,
      required Expression variableInitializingContext}) {
    Expression? condition;
    Name? name;
    switch (kind) {
      case RelationalPatternKind.equals:
      case RelationalPatternKind.notEquals:
        if (expression is NullLiteral) {
          condition = createEqualsNull(fileOffset, matchedExpression);
        } else {
          condition = createEqualsCall(
              base, matchedType, matchedExpression, expression,
              fileOffset: fileOffset);
        }
        if (kind == RelationalPatternKind.notEquals) {
          condition = createNot(condition);
        }
        break;
      case RelationalPatternKind.lessThan:
        name = lessThanName;
        break;
      case RelationalPatternKind.lessThanEqual:
        name = lessThanOrEqualsName;
        break;
      case RelationalPatternKind.greaterThan:
        name = greaterThanName;
        break;
      case RelationalPatternKind.greaterThanEqual:
        name = greaterThanOrEqualsName;
        break;
    }
    if (condition == null) {
      ObjectAccessTarget target = base.findInterfaceMember(
          matchedType, name!, fileOffset,
          callSiteAccessKind: CallSiteAccessKind.operatorInvocation);
      if (target.kind == ObjectAccessTargetKind.dynamic) {
        condition = new DynamicInvocation(
            DynamicAccessKind.Dynamic,
            matchedExpression,
            name,
            createArguments([expression], fileOffset: fileOffset));
      } else if (target.member is! Procedure) {
        base.helper.addProblem(
            templateUndefinedOperator.withArguments(
                name.text, matchedType, base.isNonNullableByDefault),
            fileOffset,
            noLength);
        condition = null;
      } else {
        condition = new InstanceInvocation(
            InstanceAccessKind.Instance,
            matchedExpression,
            name,
            createArguments([expression], fileOffset: fileOffset),
            functionType: target.getFunctionType(base),
            interfaceTarget: target.member as Procedure)
          ..fileOffset = fileOffset;
      }
    }
    return new PatternTransformationResult([
      new PatternTransformationElement(
          kind: PatternTransformationElementKind.regular,
          condition: condition,
          variableInitializers: [])
    ]);
  }

  @override
  void toTextInternal(AstPrinter printer) {
    switch (kind) {
      case RelationalPatternKind.equals:
        printer.write('== ');
        break;
      case RelationalPatternKind.notEquals:
        printer.write('!= ');
        break;
      case RelationalPatternKind.lessThan:
        printer.write('< ');
        break;
      case RelationalPatternKind.lessThanEqual:
        printer.write('<= ');
        break;
      case RelationalPatternKind.greaterThan:
        printer.write('> ');
        break;
      case RelationalPatternKind.greaterThanEqual:
        printer.write('>= ');
        break;
    }
    printer.writeExpression(expression);
  }

  @override
  String toString() {
    return "RelationalPattern(${toStringInternal()})";
  }
}

class WildcardPattern extends Pattern {
  final DartType? type;

  WildcardPattern(this.type, int fileOffset) : super(fileOffset);

  @override
  List<VariableDeclaration> get declaredVariables => const [];

  @override
  void acceptInference(
    InferenceVisitorImpl visitor, {
    required SharedMatchContext context,
  }) {
    visitor.visitWildcardBinder(this, context: context);
  }

  @override
  PatternTransformationResult transform(InferenceVisitorBase base,
      {required Expression matchedExpression,
      required DartType matchedType,
      required Expression variableInitializingContext}) {
    Expression? condition;
    if (type != null) {
      condition = createIsExpression(matchedExpression, type!,
          forNonNullableByDefault: false, fileOffset: fileOffset);
    } else {
      condition = null;
    }
    return new PatternTransformationResult([
      new PatternTransformationElement(
          kind: PatternTransformationElementKind.regular,
          condition: condition,
          variableInitializers: [])
    ]);
  }

  @override
  void toTextInternal(AstPrinter printer) {
    if (type != null) {
      type!.toTextInternal(printer);
      printer.write(" ");
    }
    printer.write("_");
  }

  @override
  String toString() {
    return "WildcardBinder(${toStringInternal()})";
  }
}

class PatternVariableDeclaration extends InternalStatement {
  final Pattern pattern;
  final Expression initializer;
  final bool isFinal;

  PatternVariableDeclaration(this.pattern, this.initializer,
      {required int fileOffset, required this.isFinal}) {
    super.fileOffset = fileOffset;
  }

  @override
  StatementInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitPatternVariableDeclaration(this);
  }

  @override
  void toTextInternal(AstPrinter printer) {
    if (isFinal) {
      printer.write('final ');
    } else {
      printer.write('var ');
    }
    pattern.toTextInternal(printer);
    printer.write(" = ");
    printer.writeExpression(initializer);
    printer.write(';');
  }

  @override
  String toString() {
    return "PatternVariableDeclaration(${toStringInternal()})";
  }
}

class PatternAssignment extends InternalExpression {
  final Pattern pattern;
  final Expression expression;

  PatternAssignment(this.pattern, this.expression, {required int fileOffset}) {
    super.fileOffset = fileOffset;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    return visitor.visitPatternAssignment(this, typeContext);
  }

  @override
  String toString() {
    return "PatternAssignment(${toStringInternal()})";
  }
}

class AssignedVariablePattern extends Pattern {
  final VariableDeclaration variable;

  AssignedVariablePattern(this.variable, {required int offset}) : super(offset);

  @override
  void acceptInference(InferenceVisitorImpl visitor,
      {required SharedMatchContext context}) {
    visitor.visitAssignedVariablePattern(this, context: context);
  }

  @override
  List<VariableDeclaration> get declaredVariables => [variable];

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write(variable.name!);
  }

  @override
  String toString() {
    return "AssignedVariablePattern(${toStringInternal()})";
  }

  @override
  PatternTransformationResult transform(InferenceVisitorBase base,
      {required Expression matchedExpression,
      required DartType matchedType,
      required Expression variableInitializingContext}) {
    // condition: let _ = `variable` = `matchedExpression` in true
    return new PatternTransformationResult([
      new PatternTransformationElement(
          kind: PatternTransformationElementKind.regular,
          condition: createLet(
              createVariableCache(
                  createVariableSet(variable, matchedExpression,
                      fileOffset: fileOffset),
                  const DynamicType()),
              createBoolLiteral(true, fileOffset: fileOffset))
            ..fileOffset = fileOffset,
          variableInitializers: [])
    ]);
  }
}

final Pattern dummyPattern = new ExpressionPattern(dummyExpression);

/// Internal statement for a if-case statements:
///
///     if (expression case pattern) then
///     if (expression case pattern) then else otherwise
///     if (expression case pattern when guard) then
///     if (expression case pattern when guard) then else otherwise
///
class IfCaseStatement extends InternalStatement {
  Expression expression;
  PatternGuard patternGuard;
  Statement then;
  Statement? otherwise;

  IfCaseStatement(this.expression, this.patternGuard, this.then, this.otherwise,
      int fileOffset) {
    this.fileOffset = fileOffset;
    expression.parent = this;
    patternGuard.parent = this;
    then.parent = this;
    otherwise?.parent = this;
  }

  @override
  StatementInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitIfCaseStatement(this);
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('if (');
    printer.writeExpression(expression);
    printer.write(' case ');
    patternGuard.toTextInternal(printer);
    printer.write(') ');
    printer.writeStatement(then);
    if (otherwise != null) {
      printer.write(' else ');
      printer.writeStatement(otherwise!);
    }
  }

  @override
  String toString() {
    return "IfCaseStatement(${toStringInternal()})";
  }
}

final MapPatternEntry dummyMapPatternEntry =
    new MapPatternEntry(dummyPattern, dummyPattern, TreeNode.noOffset);

/// This is used as a sentinel value to mark the occurrence of the rest pattern
final MapPatternEntry restMapPatternEntry = new MapPatternEntry(
    new ExpressionPattern(new NullLiteral()),
    new ExpressionPattern(new NullLiteral()),
    TreeNode.noOffset);

class MapPatternEntry extends TreeNode with InternalTreeNode {
  final Pattern key;
  final Pattern value;

  @override
  final int fileOffset;

  MapPatternEntry(this.key, this.value, this.fileOffset) {
    key.parent = this;
    value.parent = this;
  }

  @override
  void toTextInternal(AstPrinter printer) {
    key.toTextInternal(printer);
    printer.write(': ');
    value.toTextInternal(printer);
  }

  @override
  String toString() {
    return 'MapMatcherEntry(${toStringInternal()})';
  }
}

class MapPattern extends Pattern {
  DartType? keyType;
  DartType? valueType;
  final List<MapPatternEntry> entries;

  @override
  List<VariableDeclaration> get declaredVariables =>
      [for (MapPatternEntry entry in entries) ...entry.value.declaredVariables];

  MapPattern(this.keyType, this.valueType, this.entries, int fileOffset)
      : assert((keyType == null) == (valueType == null)),
        super(fileOffset);

  @override
  void toTextInternal(AstPrinter printer) {
    if (keyType != null && valueType != null) {
      printer.writeTypeArguments([keyType!, valueType!]);
    }
    printer.write('{');
    String comma = '';
    for (MapPatternEntry entry in entries) {
      printer.write(comma);
      entry.toTextInternal(printer);
      comma = ', ';
    }
    printer.write('}');
  }

  @override
  String toString() {
    return 'MapPattern(${toStringInternal()})';
  }

  @override
  void acceptInference(
    InferenceVisitorImpl visitor, {
    required SharedMatchContext context,
  }) {
    visitor.visitMapPattern(this, context: context);
  }

  @override
  PatternTransformationResult transform(InferenceVisitorBase base,
      {required Expression matchedExpression,
      required DartType matchedType,
      required Expression variableInitializingContext}) {
    DartType keyType = this.keyType ?? const DynamicType();
    DartType valueType = this.valueType ?? const DynamicType();
    DartType targetMapType = new InterfaceType(
        base.coreTypes.mapClass, Nullability.nonNullable, [keyType, valueType]);

    bool typeCheckForTargetMapNeeded =
        !base.isAssignable(targetMapType, matchedType) ||
            matchedType is DynamicType;

    // mapVariable: `matchedType` MVAR = `matchedExpression`
    VariableDeclaration mapVariable =
        createVariableCache(matchedExpression, matchedType);

    Expression? keysCheck;
    for (int i = entries.length - 1; i >= 0; i--) {
      MapPatternEntry entry = entries[i];
      if (identical(entry, restMapPatternEntry)) continue;
      ExpressionPattern keyPattern = entry.key as ExpressionPattern;

      // containsKeyCheck: `mapVariable`.containsKey(`keyPattern.expression`)
      //   ==> MVAR.containsKey(`keyPattern.expression`)
      Expression containsKeyCheck = createInstanceInvocation(
          base,
          targetMapType,
          createVariableGet(mapVariable,
              promotedType: typeCheckForTargetMapNeeded ? targetMapType : null),
          containsKeyName,
          [keyPattern.expression],
          fileOffset: fileOffset);

      if (keysCheck == null) {
        // keyCheck: `containsKeyCheck`
        keysCheck = containsKeyCheck;
      } else {
        // keyCheck: `containsKeyCheck` && `keyCheck`
        keysCheck = createAndExpression(containsKeyCheck, keysCheck,
            fileOffset: fileOffset);
      }
    }

    Expression? typeCheck;
    if (typeCheckForTargetMapNeeded) {
      // typeCheck: `mapVariable` is `targetMapType`
      //   ==> MVAR is Map<`keyType`, `valueType`>
      typeCheck = createIsExpression(
          createVariableGet(mapVariable), targetMapType,
          forNonNullableByDefault: base.isNonNullableByDefault,
          fileOffset: fileOffset);
    }

    Expression? typeAndKeysCheck;
    if (typeCheck != null && keysCheck != null) {
      // typeAndKeysCheck: `typeCheck` && `keysCheck`
      typeAndKeysCheck =
          createAndExpression(typeCheck, keysCheck, fileOffset: fileOffset);
    } else if (typeCheck != null && keysCheck == null) {
      typeAndKeysCheck = typeCheck;
    } else if (typeCheck == null && keysCheck != null) {
      typeAndKeysCheck = keysCheck;
    } else {
      typeAndKeysCheck = null;
    }

    // lengthGet: `mapVariable`.length
    //   ==> MVAR.length
    Expression lengthGet = createInstanceGet(
        base,
        targetMapType,
        createVariableGet(mapVariable,
            promotedType: typeCheckForTargetMapNeeded ? targetMapType : null),
        lengthName,
        fileOffset: fileOffset);

    Expression lengthCheck;
    // In map patterns the rest pattern can appear only in the end.
    bool hasRestPattern =
        entries.isNotEmpty && identical(entries.last, restMapPatternEntry);
    if (hasRestPattern) {
      // lengthCheck: `lengthGet` >= `entries.length - 1`
      //   ==> MVAR.length >= `entries.length - 1`
      lengthCheck = createOperatorInvocation(
          base,
          base.coreTypes.intNonNullableRawType,
          lengthGet,
          greaterThanOrEqualsName,
          createIntLiteral(entries.length - 1, fileOffset: fileOffset),
          fileOffset: fileOffset);
    } else {
      // lengthCheck: `lengthGet` == `entries.length`
      lengthCheck = createEqualsCall(base, base.coreTypes.intNonNullableRawType,
          lengthGet, createIntLiteral(entries.length, fileOffset: fileOffset),
          fileOffset: fileOffset);
    }

    Expression typeAndKeysAndLengthCheck;
    if (typeAndKeysCheck != null) {
      // typeAndKeysAndLengthCheck: `typeAndKeysCheck` && `lengthCheck`
      typeAndKeysAndLengthCheck = createAndExpression(
          typeAndKeysCheck, lengthCheck,
          fileOffset: fileOffset);
    } else {
      typeAndKeysAndLengthCheck = lengthCheck;
    }

    PatternTransformationResult transformationResult =
        new PatternTransformationResult([]);
    List<VariableDeclaration> valueAccessVariables = [];
    CloneVisitorNotMembers cloner = new CloneVisitorNotMembers();
    for (MapPatternEntry entry in entries) {
      if (identical(entry, restMapPatternEntry)) continue;
      ExpressionPattern keyPattern = entry.key as ExpressionPattern;

      // [keyPattern.expression] can be cloned without caching because it's a
      // const expression according to the spec, and the constant
      // canonicalization will eliminate the duplicated code.
      //
      // mapValue: `mapVariable`[`keyPattern.expression`]
      //   ==> MVAR[`keyPattern.expression`]
      Expression mapValue = createOperatorInvocation(
          base,
          targetMapType,
          createVariableGet(mapVariable,
              promotedType: typeCheckForTargetMapNeeded ? targetMapType : null),
          indexGetName,
          cloner.clone(keyPattern.expression),
          fileOffset: fileOffset);

      // mapValueVariable: `valueType` VVAR = `mapValue`
      //   ==> `valueType` VVAR = MVAR[`keyPattern.expression`]
      VariableDeclaration mapValueVariable =
          createVariableCache(mapValue, valueType);

      PatternTransformationResult subpatternTransformationResult = entry.value
          .transform(base,
              matchedExpression: createVariableGet(mapValueVariable),
              matchedType: valueType,
              variableInitializingContext: createVariableGet(mapValueVariable));

      // If the sub-pattern transformation doesn't declare captured variables
      // and consists of a single empty element, it means that it simply
      // doesn't have a place where it could refer to the element expression.
      // In that case we can avoid creating the intermediary variable for the
      // element expression.
      //
      // An example of such sub-pattern is in the following:
      //
      // if (x case {"key": var _}) { /* ... */ }
      if (entry.value.declaredVariables.isNotEmpty ||
          !(subpatternTransformationResult.elements.length == 1 &&
              subpatternTransformationResult.elements.single.isEmpty)) {
        valueAccessVariables.add(mapValueVariable);
        transformationResult =
            transformationResult.combine(subpatternTransformationResult, base);
      }
    }

    transformationResult = transformationResult.prependElement(
        new PatternTransformationElement(
            kind: PatternTransformationElementKind.regular,
            condition: typeAndKeysAndLengthCheck,
            variableInitializers: valueAccessVariables),
        base);

    transformationResult = transformationResult.prependElement(
        new PatternTransformationElement(
            kind: PatternTransformationElementKind.regular,
            condition: null,
            variableInitializers: [mapVariable]),
        base);

    return transformationResult;
  }
}

class NamedPattern extends Pattern {
  final String name;
  Pattern pattern;

  @override
  List<VariableDeclaration> get declaredVariables => pattern.declaredVariables;

  NamedPattern(this.name, this.pattern, int fileOffset) : super(fileOffset) {
    pattern.parent = this;
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write(name);
    printer.write(': ');
    pattern.toTextInternal(printer);
  }

  @override
  String toString() {
    return 'NamedPattern(${toStringInternal()})';
  }

  @override
  void acceptInference(
    InferenceVisitorImpl visitor, {
    required SharedMatchContext context,
  }) {
    visitor.visitNamedPattern(this, context: context);
  }

  @override
  PatternTransformationResult transform(InferenceVisitorBase base,
      {required Expression matchedExpression,
      required DartType matchedType,
      required Expression variableInitializingContext}) {
    return new PatternTransformationResult([
      new PatternTransformationElement(
          kind: PatternTransformationElementKind.regular,
          condition:
              new InvalidExpression("Unimplemented NamedPattern.transform"),
          variableInitializers: [])
    ]);
  }
}

class RecordPattern extends Pattern {
  final List<Pattern> patterns;
  late final RecordType type;

  @override
  List<VariableDeclaration> get declaredVariables =>
      [for (Pattern pattern in patterns) ...pattern.declaredVariables];

  RecordPattern(this.patterns, int fileOffset) : super(fileOffset) {
    setParents(patterns, this);
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('(');
    String comma = '';
    for (Pattern pattern in patterns) {
      printer.write(comma);
      pattern.toTextInternal(printer);
      comma = ', ';
    }
    printer.write(')');
  }

  @override
  String toString() {
    return 'RecordPattern(${toStringInternal()})';
  }

  @override
  void acceptInference(
    InferenceVisitorImpl visitor, {
    required SharedMatchContext context,
  }) {
    visitor.visitRecordPattern(this, context: context);
  }

  @override
  PatternTransformationResult transform(InferenceVisitorBase base,
      {required Expression matchedExpression,
      required DartType matchedType,
      required Expression variableInitializingContext}) {
    bool typeCheckNeeded =
        !base.isAssignable(type, matchedType) || matchedType is DynamicType;

    // recordVariable: `matchedType` RVAR = `matchedExpression`
    VariableDeclaration recordVariable =
        createVariableCache(matchedExpression, matchedType);

    PatternTransformationResult transformationResult =
        new PatternTransformationResult([]);
    int recordFieldIndex = 0;
    List<VariableDeclaration> fieldAccessVariables = [];
    for (Pattern fieldPattern in patterns) {
      Expression recordField;
      DartType fieldType;
      Pattern subpattern;
      if (fieldPattern is NamedPattern) {
        // recordField: `recordVariable`[`fieldPattern.name`]
        //   ==> RVAR[`fieldPattern.name`]
        recordField = createRecordNameGet(
            type,
            createVariableGet(recordVariable,
                promotedType: typeCheckNeeded ? type : null),
            fieldPattern.name,
            fileOffset: fieldPattern.fileOffset);

        // [type] is computed by the CFE, so the absence of the named field is
        // an internal error, and we check the condition with an assert rather
        // than reporting a compile-time error.
        assert(type.named.any((named) => named.name == fieldPattern.name));
        fieldType = type.named
            .firstWhere((named) => named.name == fieldPattern.name)
            .type;

        subpattern = fieldPattern.pattern;
      } else {
        // recordField: `recordVariable`[`recordFieldIndex`]
        //   ==> RVAR[`recordFieldIndex`]
        recordField = createRecordIndexGet(
            type,
            createVariableGet(recordVariable,
                promotedType: typeCheckNeeded ? type : null),
            recordFieldIndex,
            fileOffset: fieldPattern.fileOffset);

        // [type] is computed by the CFE, so the field index out of range is an
        // internal error, and we check the condition with an assert rather than
        // reporting a compile-time error.
        assert(recordFieldIndex < type.positional.length);
        fieldType = type.positional[recordFieldIndex];

        subpattern = fieldPattern;
        recordFieldIndex++;
      }

      // recordFieldIndex: `fieldType` FVAR = `recordField`
      VariableDeclaration recordFieldVariable =
          createVariableCache(recordField, fieldType);

      PatternTransformationResult subpatternTransformationResult =
          subpattern.transform(base,
              matchedExpression: createVariableGet(recordFieldVariable),
              matchedType: fieldType,
              variableInitializingContext:
                  createVariableGet(recordFieldVariable));

      // If the sub-pattern transformation doesn't declare captured variables
      // and consists of a single empty element, it means that it simply
      // doesn't have a place where it could refer to the element expression.
      // In that case we can avoid creating the intermediary variable for the
      // element expression.
      //
      // An example of such sub-pattern is in the following:
      //
      // if (x case (var _,)) { /* ... */ }
      if (subpattern.declaredVariables.isNotEmpty ||
          !(subpatternTransformationResult.elements.length == 1 &&
              subpatternTransformationResult.elements.single.isEmpty)) {
        fieldAccessVariables.add(recordFieldVariable);
        transformationResult =
            transformationResult.combine(subpatternTransformationResult, base);
      }
    }

    // condition: [`recordVariable` is `type`]?
    //   ==> [RVAR is `type`]?
    transformationResult = transformationResult.prependElement(
        new PatternTransformationElement(
            kind: PatternTransformationElementKind.regular,
            condition: !typeCheckNeeded
                ? null
                : createIsExpression(createVariableGet(recordVariable), type,
                    forNonNullableByDefault: base.isNonNullableByDefault,
                    fileOffset: fileOffset),
            variableInitializers: fieldAccessVariables),
        base);

    transformationResult = transformationResult.prependElement(
        new PatternTransformationElement(
            kind: PatternTransformationElementKind.regular,
            condition: null,
            variableInitializers: [recordVariable]),
        base);

    return transformationResult;
  }
}

class VariablePattern extends Pattern {
  final DartType? type;
  String name;
  VariableDeclaration variable;

  @override
  List<VariableDeclaration> get declaredVariables => [variable];

  VariablePattern(this.type, this.name, this.variable, int fileOffset)
      : super(fileOffset);

  @override
  void acceptInference(
    InferenceVisitorImpl visitor, {
    required SharedMatchContext context,
  }) {
    visitor.visitVariablePattern(this, context: context);
  }

  @override
  PatternTransformationResult transform(InferenceVisitorBase base,
      {required Expression matchedExpression,
      required DartType matchedType,
      required Expression variableInitializingContext}) {
    PatternTransformationResult transformationResult;

    if (type != null) {
      VariableDeclaration? matchedExpressionVariable;
      matchedExpressionVariable =
          createVariableCache(matchedExpression, matchedType);
      Expression condition = createIsExpression(
          createVariableGet(matchedExpressionVariable), type!,
          forNonNullableByDefault: false, fileOffset: variable.fileOffset);
      transformationResult = new PatternTransformationResult([
        new PatternTransformationElement(
            kind: PatternTransformationElementKind.regular,
            condition: null,
            variableInitializers: [matchedExpressionVariable]),
        new PatternTransformationElement(
            kind: PatternTransformationElementKind.regular,
            condition: condition,
            variableInitializers: [])
      ]);
      variable.initializer =
          createVariableGet(matchedExpressionVariable, promotedType: type!)
            ..parent = variable;
    } else {
      transformationResult = new PatternTransformationResult([]);
      variable.initializer = matchedExpression..parent = variable;
    }

    return transformationResult;
  }

  @override
  R accept<R>(TreeVisitor<R> visitor) {
    if (visitor is Printer || visitor is Precedence || visitor is Transformer) {
      // Allow visitors needed for toString and replaceWith.
      return visitor.defaultTreeNode(this);
    }
    return unsupported(
        "${runtimeType}.accept on ${visitor.runtimeType}", -1, null);
  }

  @override
  R accept1<R, A>(TreeVisitor1<R, A> visitor, A arg) {
    return unsupported(
        "${runtimeType}.accept1 on ${visitor.runtimeType}", -1, null);
  }

  @override
  void toTextInternal(AstPrinter printer) {
    if (type != null) {
      type!.toTextInternal(printer);
      printer.write(" ");
    } else {
      printer.write("var ");
    }
    printer.write(name);
  }

  @override
  String toString() {
    return "VariablePattern(${toStringInternal()})";
  }
}

class RestPattern extends Pattern {
  Pattern? subPattern;

  RestPattern(int fileOffset, this.subPattern) : super(fileOffset);

  @override
  void acceptInference(InferenceVisitorImpl visitor,
      {required SharedMatchContext context}) {
    visitor.visitRestPattern(this, context: context);
  }

  @override
  List<VariableDeclaration> get declaredVariables =>
      subPattern?.declaredVariables ?? const [];

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('...');
    if (subPattern != null) {
      subPattern!.toTextInternal(printer);
    }
  }

  @override
  String toString() {
    return "RestPattern(${toStringInternal()})";
  }

  @override
  PatternTransformationResult transform(InferenceVisitorBase base,
      {required Expression matchedExpression,
      required DartType matchedType,
      required Expression variableInitializingContext}) {
    if (subPattern != null) {
      return subPattern!.transform(base,
          matchedExpression: matchedExpression,
          matchedType: matchedType,
          variableInitializingContext: variableInitializingContext);
    }
    return unsupported("RestPattern.transform", fileOffset, base.helper.uri);
  }
}

enum PatternTransformationElementKind {
  regular,
  logicalOrPatternLeftBegin,
  logicalOrPatternRightBegin,
  logicalOrPatternEnd
}

class PatternTransformationElement {
  /// Part of a matching condition of a pattern
  ///
  /// The desugared condition for matching a pattern is broken into several
  /// elements. This is needed in order to declare the intermediate variables
  /// for storing values that should be computed only once.
  final Expression? condition;

  /// Declaration and initialization of captured and intermediate variables
  ///
  /// These are the statements that needs to present in the desugared code in
  /// order to properly initialize [declaredVariables] and any intermediate
  /// variables.
  final List<Statement> variableInitializers;

  final PatternTransformationResult? otherwise;

  final PatternTransformationElementKind kind;

  PatternTransformationElement(
      {required this.condition,
      required this.variableInitializers,
      required this.kind,
      this.otherwise});

  bool get isEmpty => condition == null && variableInitializers.isEmpty;
}

class PatternTransformationResult {
  final List<PatternTransformationElement> elements;

  PatternTransformationResult(this.elements);

  /// Combines the results of two pattern transformations into a single result
  ///
  /// The typical use case of [combine] is to combine the results of
  /// transforming two sub-patterns of the same pattern into a single result
  /// that can later be combined with the results of transforming of other
  /// sub-patterns as well. So the overall result of transforming a pattern is
  /// a combination of the results of transforming of all of the sub-patterns.
  ///
  /// [combine] uses [prependElement] on [other] for the purpose of optimization
  /// and simplification.
  PatternTransformationResult combine(
      PatternTransformationResult other, InferenceVisitorBase base) {
    if (elements.isEmpty) {
      return other;
    } else if (other.elements.isEmpty) {
      return this;
    } else {
      // TODO(cstefantsova): Does it make sense to use [prependElement] on each
      // element from [elements], last to the first, prepending them to the
      // accumulated result?
      return new PatternTransformationResult([
        ...elements.sublist(0, elements.length - 1),
        ...other.prependElement(elements.last, base).elements
      ]);
    }
  }

  /// Adds [element] to the beginning of the transformation result
  ///
  /// The condition and the intermediate variables declared by the [element] are
  /// assumed to affect the scope of the transformation result they are
  /// prepended to. Some optimizations are performed to minimize the count of
  /// the elements in the overall result. The optimizations include combining
  /// conditions via logical `&&` operation and concatenating lists of variable
  /// declarations.
  PatternTransformationResult prependElement(
      PatternTransformationElement element, InferenceVisitorBase base) {
    if (elements.isEmpty) {
      return new PatternTransformationResult([element]);
    }
    if (element.kind != PatternTransformationElementKind.regular ||
        elements.first.kind != PatternTransformationElementKind.regular) {
      return new PatternTransformationResult([element, ...elements]);
    }
    PatternTransformationElement outermost = elements.first;
    Expression? elementCondition = element.condition;
    Expression? outermostCondition = outermost.condition;
    if (outermostCondition == null) {
      elements[0] = new PatternTransformationElement(
          kind: PatternTransformationElementKind.regular,
          condition: elementCondition,
          variableInitializers: [
            ...element.variableInitializers,
            ...outermost.variableInitializers
          ]);
      return this;
    } else if (element.variableInitializers.isEmpty) {
      if (elementCondition == null) {
        // Trivial case: [element] has empty components.
        return this;
      } else {
        elements[0] = new PatternTransformationElement(
            kind: PatternTransformationElementKind.regular,
            condition: createAndExpression(elementCondition, outermostCondition,
                fileOffset: elementCondition.fileOffset),
            variableInitializers: outermost.variableInitializers);
        return this;
      }
    } else {
      return new PatternTransformationResult([element, ...elements]);
    }
  }
}

class ContinuationStackElement {
  List<Statement> statements;

  ContinuationStackElement(this.statements);
}
