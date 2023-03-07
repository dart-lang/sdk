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
import 'package:kernel/src/printer.dart';
import 'package:kernel/text/ast_to_text.dart' show Precedence, Printer;
import 'package:kernel/type_environment.dart';

import 'package:_fe_analyzer_shared/src/type_inference/type_analysis_result.dart'
    as shared;

import '../builder/type_alias_builder.dart';
import '../names.dart';
import '../problems.dart' show unsupported;
import '../type_inference/inference_visitor.dart';
import '../type_inference/inference_results.dart';
import '../type_inference/type_schema.dart' show UnknownType;

import 'collections.dart';

typedef SharedMatchContext = shared
    .MatchContext<TreeNode, Expression, Pattern, DartType, VariableDeclaration>;

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
  final List<Statement> labelUsers = [];

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
  Expression? error;

  Pattern(int fileOffset) {
    this.fileOffset = fileOffset;
  }

  /// Variable declarations induced by nested variable patterns.
  ///
  /// These variables are initialized to the values captured by the variable
  /// patterns nested in the pattern.
  List<VariableDeclaration> get declaredVariables;

  // TODO(johnniwinther): Merge this with [accept1] when [Pattern]s are moved
  // to package:kernel.
  R acceptPattern1<R, A>(PatternVisitor1<R, A> visitor, A arg);

  /// Returns the variable name that this pattern defines, if any.
  ///
  /// This is used to derive an implicit variable name from a pattern to use
  /// on object patterns. For instance
  ///
  ///    if (o case Foo(:var bar, :var baz!)) { ... }
  ///
  /// the getter names 'bar' and 'baz' are implicitly defined by the patterns.
  String? get variableName => null;
}

/// A [Pattern] based on a constant [Expression].
class ConstantPattern extends Pattern {
  Expression expression;

  /// Static type of the expression as computed during inference.
  // TODO(johnniwinther): Use UnknownType instead to flag when this type has
  // not been computed.
  DartType expressionType = const DynamicType();

  /// The `operator ==` procedure on [expression].
  ///
  /// This is set during inference.
  late Procedure equalsTarget;

  /// The type of the `operator ==` procedure on [expression].
  ///
  /// This is set during inference.
  late FunctionType equalsType;

  ConstantPattern(this.expression) : super(expression.fileOffset) {
    expression.parent = this;
  }

  @override
  List<VariableDeclaration> get declaredVariables => const [];

  @override
  R acceptPattern1<R, A>(PatternVisitor1<R, A> visitor, A arg) =>
      visitor.visitConstantPattern(this, arg);

  @override
  void toTextInternal(AstPrinter printer) {
    expression.toTextInternal(printer);
  }

  @override
  String toString() {
    return "ConstantPattern(${toStringInternal()})";
  }
}

/// A [Pattern] for `pattern && pattern`.
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
  R acceptPattern1<R, A>(PatternVisitor1<R, A> visitor, A arg) =>
      visitor.visitAndPattern(this, arg);

  @override
  void toTextInternal(AstPrinter printer) {
    left.toTextInternal(printer);
    printer.write(' && ');
    right.toTextInternal(printer);
  }

  @override
  String toString() {
    return "BinaryPattern(${toStringInternal()})";
  }
}

/// A [Pattern] for `pattern || pattern`.
class OrPattern extends Pattern {
  Pattern left;
  Pattern right;

  final List<VariableDeclaration> orPatternJointVariables;

  @override
  List<VariableDeclaration> get declaredVariables => orPatternJointVariables;

  OrPattern(this.left, this.right, int fileOffset,
      {required List<VariableDeclaration> orPatternJointVariables})
      : orPatternJointVariables = orPatternJointVariables,
        super(fileOffset) {
    left.parent = this;
    right.parent = this;
  }

  @override
  R acceptPattern1<R, A>(PatternVisitor1<R, A> visitor, A arg) =>
      visitor.visitOrPattern(this, arg);

  @override
  void toTextInternal(AstPrinter printer) {
    left.toTextInternal(printer);
    printer.write(' || ');
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
  final DartType type;

  CastPattern(this.pattern, this.type, int fileOffset) : super(fileOffset) {
    pattern.parent = this;
  }

  @override
  String? get variableName => pattern.variableName;

  @override
  List<VariableDeclaration> get declaredVariables => pattern.declaredVariables;

  @override
  R acceptPattern1<R, A>(PatternVisitor1<R, A> visitor, A arg) =>
      visitor.visitCastPattern(this, arg);

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
  String? get variableName => pattern.variableName;

  @override
  List<VariableDeclaration> get declaredVariables => pattern.declaredVariables;

  @override
  R acceptPattern1<R, A>(PatternVisitor1<R, A> visitor, A arg) =>
      visitor.visitNullAssertPattern(this, arg);

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
  String? get variableName => pattern.variableName;

  @override
  List<VariableDeclaration> get declaredVariables => pattern.declaredVariables;

  @override
  R acceptPattern1<R, A>(PatternVisitor1<R, A> visitor, A arg) =>
      visitor.visitNullCheckPattern(this, arg);

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

  /// The type of the expression against which this pattern is matched.
  ///
  /// This is set during inference.
  late final DartType matchedType;

  /// If `true`, the matched expression must be checked to be a `List`.
  ///
  /// This is set during inference.
  late bool needsCheck;

  /// The type of the matched expression.
  ///
  /// If [needsCheck] is `true`, this is the list type it was checked against.
  /// Otherwise it is the type of the matched expression itself, which was,
  /// in this case, already known to be a list type.
  ///
  /// This is set during inference.
  late DartType listType;

  /// If `true`, this list pattern contains a rest pattern.
  ///
  /// This is set during inference.
  bool hasRestPattern = false;

  /// The target of the `length` property of the list.
  ///
  /// This is set during inference.
  late Member lengthTarget;

  /// The type of the `length` property of the list.
  ///
  /// This is set during inference.
  late DartType lengthType;

  /// The method used to check the `length` of the list.
  ///
  /// If this pattern has a rest pattern, this is an `operator >=` method.
  /// Otherwise this is an `operator ==` method.
  ///
  /// This is set during inference.
  late Procedure lengthCheckTarget;

  /// The type of the method used to check the `length` of the list.
  ///
  /// If this pattern has a rest pattern, this is an `operator >=` method.
  /// Otherwise this is an `operator ==` method.
  ///
  /// This is set during inference.
  late FunctionType lengthCheckType;

  /// The target of the `sublist` method of the list.
  ///
  /// This is used if this pattern has a rest pattern with a subpattern.
  ///
  /// This is set during inference.
  late Procedure sublistTarget;

  /// The type of the `sublist` method of the list.
  ///
  /// This is used if this pattern has a rest pattern with a subpattern.
  ///
  /// This is set during inference.
  late FunctionType sublistType;

  /// The target of the `minus` method of the `length` of this list.
  ///
  /// This is used to compute tail indices if this pattern has a rest pattern.
  ///
  /// This is set during inference.
  late Procedure minusTarget;

  /// The type of the `minus` method of the `length` of this list.
  ///
  /// This is used to compute tail indices if this pattern has a rest pattern.
  ///
  /// This is set during inference.
  late FunctionType minusType;

  /// The target of the `operator []` method of the list.
  ///
  /// This is set during inference.
  late Procedure indexGetTarget;

  /// The type of the `operator []` method of the list.
  ///
  /// This is set during inference.
  late FunctionType indexGetType;

  @override
  List<VariableDeclaration> get declaredVariables =>
      [for (Pattern pattern in patterns) ...pattern.declaredVariables];

  ListPattern(this.typeArgument, this.patterns, int fileOffset)
      : super(fileOffset) {
    setParents(patterns, this);
  }

  @override
  R acceptPattern1<R, A>(PatternVisitor1<R, A> visitor, A arg) =>
      visitor.visitListPattern(this, arg);

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
  final DartType type;
  final List<NamedPattern> fields;

  /// The type of the expression against which this pattern is matched.
  ///
  /// This is set during inference.
  late final DartType matchedType;

  /// If `true`, the matched expression must be checked to be of type [type].
  ///
  /// This is set during inference.
  late bool needsCheck;

  /// The type of the matched expression.
  ///
  /// If [needsCheck] is `true`, this is the type it was checked against.
  /// Otherwise it is the type of the matched expression itself, which was,
  /// in this case, already known to be of the required type.
  ///
  /// This is set during inference.
  late DartType objectType;

  ObjectPattern(this.type, this.fields, int fileOffset) : super(fileOffset) {
    setParents(fields, this);
  }

  @override
  R acceptPattern1<R, A>(PatternVisitor1<R, A> visitor, A arg) =>
      visitor.visitObjectPattern(this, arg);

  @override
  List<VariableDeclaration> get declaredVariables {
    return [for (NamedPattern field in fields) ...field.declaredVariables];
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeType(type);
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
  DartType expressionType = const UnknownType();

  /// The type of the expression against which this pattern is matched.
  ///
  /// This is set during inference.
  late final DartType matchedType;

  /// The access kind for performing the relational operation of this pattern.
  ///
  /// This is set during inference.
  late RelationAccessKind accessKind;

  /// The name of the relational operation called by this pattern.
  ///
  /// This is set during inference.
  late Name name;

  /// The target [Procedure] called by this pattern.
  ///
  /// This is used for [RelationAccessKind.Instance] and
  /// [RelationAccessKind.Static].
  ///
  /// This is set during inference.
  late Procedure? target;

  /// The type arguments passed to [target].
  ///
  /// This is used for [RelationAccessKind.Static].
  ///
  /// This is set during inference.
  late List<DartType>? typeArguments;

  /// The type of [target].
  ///
  /// This is used for [RelationAccessKind.Instance] and
  /// [RelationAccessKind.Static].
  ///
  /// This is set during inference.
  late FunctionType? functionType;

  RelationalPattern(this.kind, this.expression, int fileOffset)
      : super(fileOffset) {
    expression.parent = this;
  }

  @override
  List<VariableDeclaration> get declaredVariables => const [];

  @override
  R acceptPattern1<R, A>(PatternVisitor1<R, A> visitor, A arg) =>
      visitor.visitRelationalPattern(this, arg);

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
  R acceptPattern1<R, A>(PatternVisitor1<R, A> visitor, A arg) =>
      visitor.visitWildcardPattern(this, arg);

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
    return "WildcardPattern(${toStringInternal()})";
  }
}

class PatternVariableDeclaration extends InternalStatement {
  Pattern pattern;
  Expression initializer;
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
  void toTextInternal(AstPrinter printer) {
    pattern.toTextInternal(printer);
    printer.write(' = ');
    printer.writeExpression(expression);
  }

  @override
  String toString() {
    return "PatternAssignment(${toStringInternal()})";
  }
}

class AssignedVariablePattern extends Pattern {
  final VariableDeclaration variable;

  /// The type of the expression against which this pattern is matched.
  ///
  /// This is set during inference.
  late final DartType matchedType;

  /// If `true`, the matched expression must be checked to be of the type
  /// of [variable].
  ///
  /// This is set during inference.
  late bool needsCheck;

  AssignedVariablePattern(this.variable, {required int offset}) : super(offset);

  @override
  R acceptPattern1<R, A>(PatternVisitor1<R, A> visitor, A arg) =>
      visitor.visitAssignedVariablePattern(this, arg);

  @override
  List<VariableDeclaration> get declaredVariables => const [];

  @override
  String? get variableName => variable.name!;

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write(variable.name!);
  }

  @override
  String toString() {
    return "AssignedVariablePattern(${toStringInternal()})";
  }
}

final Pattern dummyPattern = new ConstantPattern(dummyExpression);

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

class MapPatternEntry extends TreeNode with InternalTreeNode {
  Pattern key;
  Pattern value;

  MapPatternEntry(this.key, this.value, int fileOffset) {
    key.parent = this;
    value.parent = this;
    this.fileOffset = fileOffset;
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

class MapPatternRestEntry extends TreeNode
    with InternalTreeNode
    implements MapPatternEntry {
  MapPatternRestEntry(int fileOffset) {
    this.fileOffset = fileOffset;
  }

  @override
  Pattern get key => throw new UnsupportedError('MapPatternRestEntry.key');

  @override
  void set key(Pattern value) =>
      throw new UnsupportedError('MapPatternRestEntry.key=');

  @override
  Pattern get value => throw new UnsupportedError('MapPatternRestEntry.value');

  @override
  void set value(Pattern value) =>
      throw new UnsupportedError('MapPatternRestEntry.value=');

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('...');
  }

  @override
  String toString() {
    return 'MapPatternRestEntry(${toStringInternal()})';
  }
}

class MapPattern extends Pattern {
  DartType? keyType;
  DartType? valueType;
  final List<MapPatternEntry> entries;

  /// The type of the expression against which this pattern is matched.
  ///
  /// This is set during inference.
  late final DartType matchedType;

  /// If `true`, the matched expression must be checked to be a `Map`.
  ///
  /// This is set during inference.
  late bool needsCheck;

  /// The type of the matched expression.
  ///
  /// If [needsCheck] is `true`, this is the map type it was checked against.
  /// Otherwise it is the type of the matched expression itself, which was,
  /// in this case, already known to be a map type.
  ///
  /// This is set during inference.
  late DartType mapType;

  /// If `true`, this map pattern contains a rest pattern.
  ///
  /// This is set during inference.
  bool hasRestPattern = false;

  /// The target of the `length` property of the map.
  ///
  /// This is set during inference.
  late Member lengthTarget;

  /// The type of the `length` property of the map.
  ///
  /// This is set during inference.
  late DartType lengthType;

  /// The method used to check the `length` of the map.
  ///
  /// If this pattern has a rest pattern, this is an `operator >=` method.
  /// Otherwise this is an `operator ==` method.
  ///
  /// This is set during inference.
  late Procedure lengthCheckTarget;

  /// The type of the method used to check the `length` of the map.
  ///
  /// If this pattern has a rest pattern, this is an `operator >=` method.
  /// Otherwise this is an `operator ==` method.
  ///
  /// This is set during inference.
  late FunctionType lengthCheckType;

  /// The target of the `containsKey` method of the map.
  ///
  /// This is set during inference.
  late Procedure containsKeyTarget;

  /// The type of the `containsKey` method of the map.
  ///
  /// This is set during inference.
  late FunctionType containsKeyType;

  /// The target of the `operator []` method of the map.
  ///
  /// This is set during inference.
  late Procedure indexGetTarget;

  /// The type of the `operator []` method of the map.
  ///
  /// This is set during inference.
  late FunctionType indexGetType;

  @override
  List<VariableDeclaration> get declaredVariables => [
        for (MapPatternEntry entry in entries)
          if (entry is! MapPatternRestEntry) ...entry.value.declaredVariables
      ];

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
  R acceptPattern1<R, A>(PatternVisitor1<R, A> visitor, A arg) =>
      visitor.visitMapPattern(this, arg);
}

class NamedPattern extends Pattern {
  final String name;
  Pattern pattern;

  /// When used in an object pattern, this holds the named of the property
  /// accessed by this pattern.
  ///
  /// This is set during inference.
  late Name fieldName;

  /// When used in an object pattern, this holds the access kind of used for
  /// reading the property value for this pattern.
  ///
  /// This is set during inference.
  late ObjectAccessKind accessKind;

  /// When used in an object pattern, this holds the target [Member] used to
  /// read the property for this pattern.
  ///
  /// This is used for [ObjectAccessKind.Object], [ObjectAccessKind.Instance],
  /// and [ObjectAccessKind.Static].
  ///
  /// This is set during inference.
  Member? target;

  /// When used in an object pattern, this holds the static property type for
  /// this pattern.
  ///
  /// This is used for [ObjectAccessKind.Object] and
  /// [ObjectAccessKind.Instance].
  ///
  /// This is set during inference.
  DartType? resultType;

  /// When used in an object pattern, this holds the record on which the
  /// property for this pattern is read.
  ///
  /// This is used for [ObjectAccessKind.RecordNamed] and
  /// [ObjectAccessKind.RecordIndexed].
  ///
  /// This is set during inference.
  RecordType? recordType;

  /// When used in an object pattern, this holds the record field index from
  /// which the property for this pattern is read.
  ///
  /// This is used for [ObjectAccessKind.RecordIndexed].
  ///
  /// This is set during inference.
  int? recordFieldIndex;

  /// When used in an object pattern, this holds the function type of [target]
  /// called to read the property for this pattern.
  ///
  /// This is used for [ObjectAccessKind.Static].
  ///
  /// This is set during inference.
  FunctionType? functionType;

  /// When used in an object pattern, this holds the type arguments used when
  /// called the [target] to read the property for this pattern.
  ///
  /// This is used for [ObjectAccessKind.Static].
  ///
  /// This is set during inference.
  List<DartType>? typeArguments;

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
  R acceptPattern1<R, A>(PatternVisitor1<R, A> visitor, A arg) =>
      visitor.visitNamedPattern(this, arg);
}

class RecordPattern extends Pattern {
  final List<Pattern> patterns;
  late final RecordType type;

  /// The type of the expression against which this pattern is matched.
  ///
  /// This is set during inference.
  late final DartType matchedType;

  /// If `true`, the matched expression must be checked to be of type [type].
  ///
  /// This is set during inference.
  late bool needsCheck;

  /// The type of the matched expression.
  ///
  /// If [needsCheck] is `true`, this is the record type it was checked against.
  /// Otherwise it is the type of the matched expression itself, which was,
  /// in this case, already known to be a record type.
  ///
  /// This is set during inference.
  late RecordType recordType;

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
  R acceptPattern1<R, A>(PatternVisitor1<R, A> visitor, A arg) =>
      visitor.visitRecordPattern(this, arg);
}

class VariablePattern extends Pattern {
  final DartType? type;
  String name;
  VariableDeclaration variable;

  /// The type of the expression against which this pattern is matched.
  ///
  /// This is set during inference.
  late final DartType matchedType;

  @override
  List<VariableDeclaration> get declaredVariables => [variable];

  VariablePattern(this.type, this.name, this.variable, int fileOffset)
      : super(fileOffset);

  @override
  String? get variableName => variable.name;

  @override
  R acceptPattern1<R, A>(PatternVisitor1<R, A> visitor, A arg) =>
      visitor.visitVariablePattern(this, arg);

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
  R acceptPattern1<R, A>(PatternVisitor1<R, A> visitor, A arg) =>
      visitor.visitRestPattern(this, arg);

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
}

class InvalidPattern extends Pattern {
  final Expression invalidExpression;

  InvalidPattern(this.invalidExpression) : super(invalidExpression.fileOffset) {
    invalidExpression.parent = this;
  }

  @override
  R acceptPattern1<R, A>(PatternVisitor1<R, A> visitor, A arg) =>
      visitor.visitInvalidPattern(this, arg);

  @override
  List<VariableDeclaration> get declaredVariables => const [];

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(invalidExpression);
  }

  @override
  String toString() {
    return "InvalidPattern(${toStringInternal()})";
  }
}

abstract class PatternVisitor1<R, A> {
  R defaultPattern(Pattern node, A arg);
  R visitAndPattern(AndPattern node, A arg) => defaultPattern(node, arg);
  R visitAssignedVariablePattern(AssignedVariablePattern node, A arg) =>
      defaultPattern(node, arg);
  R visitCastPattern(CastPattern node, A arg) => defaultPattern(node, arg);
  R visitConstantPattern(ConstantPattern node, A arg) =>
      defaultPattern(node, arg);
  R visitInvalidPattern(InvalidPattern node, A arg) =>
      defaultPattern(node, arg);
  R visitListPattern(ListPattern node, A arg) => defaultPattern(node, arg);
  R visitMapPattern(MapPattern node, A arg) => defaultPattern(node, arg);
  R visitNamedPattern(NamedPattern node, A arg) => defaultPattern(node, arg);
  R visitNullAssertPattern(NullAssertPattern node, A arg) =>
      defaultPattern(node, arg);
  R visitNullCheckPattern(NullCheckPattern node, A arg) =>
      defaultPattern(node, arg);
  R visitObjectPattern(ObjectPattern node, A arg) => defaultPattern(node, arg);
  R visitOrPattern(OrPattern node, A arg) => defaultPattern(node, arg);
  R visitRecordPattern(RecordPattern node, A arg) => defaultPattern(node, arg);
  R visitRelationalPattern(RelationalPattern node, A arg) =>
      defaultPattern(node, arg);
  R visitRestPattern(RestPattern node, A arg) => defaultPattern(node, arg);
  R visitVariablePattern(VariablePattern node, A arg) =>
      defaultPattern(node, arg);
  R visitWildcardPattern(WildcardPattern node, A arg) =>
      defaultPattern(node, arg);
}

/// Kinds of lowerings of relational pattern operations.
enum RelationAccessKind {
  /// Operator defined by an interface member.
  Instance,

  /// Operator defined by an extension or inline class member.
  Static,

  /// Operator accessed on a receiver of type `dynamic`.
  Dynamic,

  /// Operator accessed on a receiver of type `Never`.
  Never,

  /// Operator accessed on a receiver of an invalid type.
  Invalid,

  /// Erroneous operator access.
  Error,
}

/// Kinds of lowerings of objects pattern property access.
enum ObjectAccessKind {
  /// Property defined by an `Object` member.
  Object,

  /// Property defined by an interface member.
  Instance,

  /// Property defined by an extension or inline class member.
  Static,

  /// Named record field property.
  RecordNamed,

  /// Positional record field property.
  RecordIndexed,

  /// Property accessed on a receiver of type `dynamic`.
  Dynamic,

  /// Property accessed on a receiver of type `Never`.
  Never,

  /// Property accessed on a receiver of an invalid type.
  Invalid,

  /// Access of `call` on a function.
  FunctionTearOff,

  /// Erroneous property access.
  Error,
}

class IfCaseElement extends InternalExpression with ControlFlowElement {
  Expression expression;
  PatternGuard patternGuard;
  Expression then;
  Expression? otherwise;
  List<Statement> prelude;

  IfCaseElement(
      {required this.prelude,
      required this.expression,
      required this.patternGuard,
      required this.then,
      this.otherwise}) {
    setParents(prelude, this);
    expression.parent = this;
    patternGuard.parent = this;
    then.parent = this;
    otherwise?.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    throw new UnsupportedError("IfCaseElement.acceptInference");
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('if (');
    printer.writeExpression(expression);
    printer.write(' case ');
    patternGuard.toTextInternal(printer);
    printer.write(') ');
    printer.writeExpression(then);
    if (otherwise != null) {
      printer.write(' else ');
      printer.writeExpression(otherwise!);
    }
  }

  @override
  MapLiteralEntry? toMapLiteralEntry(
      void Function(TreeNode from, TreeNode to) onConvertElement) {
    MapLiteralEntry? thenEntry;
    Expression then = this.then;
    if (then is ControlFlowElement) {
      ControlFlowElement thenElement = then;
      thenEntry = thenElement.toMapLiteralEntry(onConvertElement);
    }
    if (thenEntry == null) return null;
    MapLiteralEntry? otherwiseEntry;
    Expression? otherwise = this.otherwise;
    if (otherwise != null) {
      if (otherwise is ControlFlowElement) {
        ControlFlowElement otherwiseElement = otherwise;
        otherwiseEntry = otherwiseElement.toMapLiteralEntry(onConvertElement);
      }
      if (otherwiseEntry == null) return null;
    }
    IfCaseMapEntry result = new IfCaseMapEntry(
        prelude: prelude,
        expression: expression,
        patternGuard: patternGuard,
        then: thenEntry,
        otherwise: otherwiseEntry)
      ..fileOffset = fileOffset;
    onConvertElement(this, result);
    return result;
  }

  @override
  String toString() {
    return "IfCaseElement(${toStringInternal()})";
  }
}

class IfCaseMapEntry extends TreeNode
    with InternalTreeNode, ControlFlowMapEntry {
  Expression expression;
  PatternGuard patternGuard;
  MapLiteralEntry then;
  MapLiteralEntry? otherwise;
  List<Statement> prelude;

  IfCaseMapEntry(
      {required this.prelude,
      required this.expression,
      required this.patternGuard,
      required this.then,
      this.otherwise}) {
    expression.parent = this;
    patternGuard.parent = this;
    then.parent = this;
    otherwise?.parent = this;
  }

  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    throw new UnsupportedError("IfCaseMapEntry.acceptInference");
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('if (');
    expression.toTextInternal(printer);
    printer.write(' case ');
    patternGuard.toTextInternal(printer);
    printer.write(') ');
    then.toTextInternal(printer);
    if (otherwise != null) {
      printer.write(' else ');
      otherwise!.toTextInternal(printer);
    }
  }

  @override
  String toString() {
    return "IfCaseMapEntry(${toStringInternal()})";
  }
}

class PatternForElement extends InternalExpression
    with ControlFlowElement
    implements ForElement {
  PatternVariableDeclaration patternVariableDeclaration;
  List<Statement> prelude;

  @override
  final List<VariableDeclaration> variables; // May be empty, but not null.

  @override
  Expression? condition; // May be null.

  @override
  final List<Expression> updates; // May be empty, but not null.

  @override
  Expression body;

  PatternForElement(
      {required this.patternVariableDeclaration,
      required this.prelude,
      required this.variables,
      required this.condition,
      required this.updates,
      required this.body});

  @override
  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    throw new UnsupportedError("PatternForElement.acceptInference");
  }

  @override
  void toTextInternal(AstPrinter printer) {
    patternVariableDeclaration.toTextInternal(printer);
    printer.write('for (');
    for (int index = 0; index < variables.length; index++) {
      if (index > 0) {
        printer.write(', ');
      }
      printer.writeVariableDeclaration(variables[index],
          includeModifiersAndType: index == 0);
    }
    printer.write('; ');
    if (condition != null) {
      printer.writeExpression(condition!);
    }
    printer.write('; ');
    printer.writeExpressions(updates);
    printer.write(') ');
    printer.writeExpression(body);
  }

  @override
  MapLiteralEntry? toMapLiteralEntry(
      void Function(TreeNode from, TreeNode to) onConvertElement) {
    throw new UnimplementedError("toMapLiteralEntry");
  }

  @override
  String toString() {
    return "PatternForElement(${toStringInternal()})";
  }
}

class PatternForMapEntry extends TreeNode
    with InternalTreeNode, ControlFlowMapEntry
    implements ForMapEntry {
  PatternVariableDeclaration patternVariableDeclaration;
  List<Statement> prelude;

  @override
  final List<VariableDeclaration> variables;

  @override
  Expression? condition;

  @override
  final List<Expression> updates;

  @override
  MapLiteralEntry body;

  PatternForMapEntry(
      {required this.patternVariableDeclaration,
      required this.prelude,
      required this.variables,
      required this.condition,
      required this.updates,
      required this.body});

  ExpressionInferenceResult acceptInference(
      InferenceVisitorImpl visitor, DartType typeContext) {
    throw new UnsupportedError("PatternForElement.acceptInference");
  }

  @override
  void toTextInternal(AstPrinter printer) {
    patternVariableDeclaration.toTextInternal(printer);
    printer.write('for (');
    for (int index = 0; index < variables.length; index++) {
      if (index > 0) {
        printer.write(', ');
      }
      printer.writeVariableDeclaration(variables[index],
          includeModifiersAndType: index == 0);
    }
    printer.write('; ');
    if (condition != null) {
      printer.writeExpression(condition!);
    }
    printer.write('; ');
    printer.writeExpressions(updates);
    printer.write(') ');
    body.toTextInternal(printer);
  }

  @override
  String toString() {
    return "PatternForMapEntry(${toStringInternal()})";
  }
}
