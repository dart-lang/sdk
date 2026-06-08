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
import 'package:_fe_analyzer_shared/src/types/shared_type.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/names.dart';
import 'package:kernel/src/printer.dart';
import 'package:kernel/text/ast_to_text.dart' show Precedence;
import 'package:kernel/type_environment.dart';

import '../base/problems.dart' show unsupported;
import '../builder/declaration_builders.dart';
import '../codes/diagnostic.dart' as diag;
import '../type_inference/inference_results.dart';
import '../type_inference/inference_visitor.dart';
import '../type_inference/inference_visitor_base.dart';
import '../type_inference/type_schema.dart';
import 'body_builder.dart';
import 'external_ast_helper.dart' as extern;

/// @docImport 'package:_fe_analyzer_shared/src/flow_analysis/flow_analysis.dart';

typedef SharedMatchContext =
    shared.MatchContext<TreeNode, Expression, Pattern, Variable>;

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

class TryStatement extends InternalStatement {
  Statement tryBlock;
  List<Catch> catchBlocks;
  Statement? finallyBlock;

  new(this.tryBlock, this.catchBlocks, this.finallyBlock) {
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

sealed class InternalSwitchCase extends TreeNode with InternalTreeNode {
  List<Label>? get labels;
  Statement get body;

  bool get hasLabel => labels != null;

  List<ContinueSwitchStatement>? _continueStatements;
  SwitchCase? _node;

  void _connectContinueToCase(
    ContinueSwitchStatement continueStatement,
    SwitchCase switchCase,
  ) {
    continueStatement.target = switchCase;
    if (switchCase is PatternSwitchCase) {
      switchCase.labelUsers.add(continueStatement);
    }
  }

  /// Registers that [statement] targets this switch case.
  ///
  /// The ensures that continue statements and switch cases are connected
  /// correctly in the external AST.
  void registerContinueSwitchStatement(ContinueSwitchStatement statement) {
    (_continueStatements ??= [])..add(statement);
    SwitchCase? node = _node;
    if (node != null) {
      _connectContinueToCase(statement, node);
    }
  }

  /// Registers that [node] corresponds to this switch case.
  ///
  /// The ensures that continue statements and switch cases are connected
  /// correctly in the external AST.
  void registerSwitchCase(SwitchCase node) {
    assert(_node == null, "SwitchCase already created for $this.");
    _node = node;

    List<ContinueSwitchStatement>? continueStatements = _continueStatements;
    if (continueStatements != null) {
      for (ContinueSwitchStatement continueStatement in continueStatements) {
        _connectContinueToCase(continueStatement, node);
      }
    }
  }
}

class InternalSwitchStatementCase extends InternalSwitchCase {
  final List<Expression> expressions;
  final List<int> expressionOffsets;
  @override
  final Statement body;
  final bool isDefault;
  final List<int> caseOffsets;
  @override
  final List<Label>? labels;

  new({
    required this.caseOffsets,
    required this.expressions,
    required this.expressionOffsets,
    required this.body,
    required this.isDefault,
    required this.labels,
    required int fileOffset,
  }) {
    setParents(expressions, this);
    body.parent = this;
    this.fileOffset = fileOffset;
  }

  int get caseHeadCount => expressions.length;

  @override
  // Coverage-ignore(suite): Not run.
  R accept<R>(TreeVisitor<R> v) {
    unsupported("${runtimeType}.accept on ${v.runtimeType}", -1, null);
  }

  @override
  // Coverage-ignore(suite): Not run.
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) {
    unsupported("${runtimeType}.accept1 on ${v.runtimeType}", -1, null);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    bool needsNewLine = false;
    if (labels != null) {
      for (Label label in labels!) {
        if (needsNewLine) {
          printer.newLine();
        }
        printer.write(label.name);
        printer.write(':');
        needsNewLine = true;
      }
    }
    for (Expression expression in expressions) {
      if (needsNewLine) {
        printer.newLine();
      }
      printer.write('case ');
      printer.writeExpression(expression);
      printer.write(':');
      needsNewLine = true;
    }
    if (isDefault) {
      if (needsNewLine) {
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
    return "$runtimeType(${toStringInternal()})";
  }
}

class InternalRegularSwitchStatement extends InternalStatement
    implements InternalSwitchStatement {
  final Expression expression;

  @override
  final List<InternalSwitchStatementCase> cases;

  new({
    required this.expression,
    required this.cases,
    required int fileOffset,
  }) {
    expression.parent = this;
    setParents(cases, this);
    this.fileOffset = fileOffset;
  }

  @override
  StatementInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitInternalRegularSwitchStatement(this);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('switch (');
    printer.writeExpression(expression);
    printer.write(') {');
    printer.incIndentation();
    for (InternalSwitchStatementCase switchCase in cases) {
      printer.newLine();
      switchCase.toTextInternal(printer);
    }
    printer.decIndentation();
    printer.newLine();
    printer.write('}');
  }

  @override
  String toString() {
    return "$runtimeType(${toStringInternal()})";
  }
}

class BreakStatementImpl extends BreakStatement {
  Statement? targetStatement;
  final bool isContinue;

  new({required this.isContinue}) : super(dummyLabeledStatement);

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
  void transformOrRemoveChildren(RemovingTransformer v) {
    unsupported("${runtimeType}.transformOrRemoveChildren", -1, null);
  }

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

  new(this.types);

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

  new(this.expression);

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
  new(super.expression);

  @override
  bool get isSuperParameter => true;
}

class NamedArgument extends Argument {
  NamedExpression namedExpression;

  new(this.namedExpression);

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
  new(super.expression);

  @override
  bool get isSuperParameter => true;
}

/// Front end specific implementation of [Argument].
class ActualArguments extends TreeNode with InternalTreeNode {
  final List<Argument> argumentList;

  bool _hasNamedBeforePositional;
  int _positionalCount;

  new({
    required this.argumentList,
    required bool hasNamedBeforePositional,
    required int positionalCount,
  }) : _hasNamedBeforePositional = hasNamedBeforePositional,
       _positionalCount = positionalCount;

  // Coverage-ignore(suite): Not run.
  new empty()
    : this.argumentList = [],
      this._hasNamedBeforePositional = false,
      this._positionalCount = 0;

  int get positionalCount => _positionalCount;

  int get namedCount => argumentList.length - positionalCount;

  bool get hasNamedBeforePositional => _hasNamedBeforePositional;

  /// Determines how many argument expressions should be hoisted when
  /// implementing the "named arguments anywhere" feature.
  ///
  /// The reason argument expressions need to be hoisted when implementing this
  /// feature is that in kernel semantics, positional arguments are evaluated
  /// before named arguments, so if any named argument appears before a
  /// positional argument, it needs to be hoisted to ensure that it is evaluated
  /// before the positional arguments that follow it.
  int computeHoistingEndIndexForNamedArgumentsAnywhere() {
    // The computation is based on the following observation: the largest suffix
    // of the argument vector, such that every positional argument in that
    // suffix comes before any named argument, retains the evaluation order
    // after the rest of the arguments are hoisted, and therefore doesn't need
    // to be hoisted itself. The loop below finds the starting position of such
    // suffix and returns it. In case all positional arguments come before all
    // named arguments, the suffix coincides with the entire argument vector,
    // and none of the arguments is hoisted. That way the legacy behavior is
    // preserved.
    if (hasNamedBeforePositional) {
      int hoistingEndIndex = argumentList.length - 1;
      for (
        int i = argumentList.length - 2;
        i >= 0 && hoistingEndIndex == i + 1;
        i--
      ) {
        int previousWeight = argumentList[i + 1] is NamedArgument ? 1 : 0;
        int currentWeight = argumentList[i] is NamedArgument ? 1 : 0;
        if (currentWeight <= previousWeight) {
          --hoistingEndIndex;
        }
      }
      return hoistingEndIndex;
    } else {
      return 0;
    }
  }

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
    return extern.createArguments(
      positionalArguments,
      types: typeArguments,
      named: namedArguments,
      fileOffset: fileOffset,
    );
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
  InternalVariable variable;

  /// `true` if the access is null-aware, i.e. of the form `a?..b()`.
  final bool isNullAware;

  /// The expressions performed on [variable].
  final List<Expression> expressions = <Expression>[];

  /// Creates a [Cascade] using [variable] as the cascade
  /// variable.  Caller is responsible for ensuring that [variable]'s
  /// initializer is the expression preceding the first `..` of the cascade
  /// expression.
  new(this.variable, {required this.isNullAware}) {
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
    printer.writeVariableInitialization(variable.asVariableDeclaration);
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
    printer.write(printer.getVariableName(variable.asVariableDeclaration));
  }
}

/// Internal expression representing an anonymous method invocation.
class AnonymousMethodExpression extends InternalExpression {
  InternalVariable variable;
  Expression body;
  final bool isCascade;
  final bool isImplicitlyTyped;
  final bool isNullAware;
  final bool isParameterless;
  final int typeOffset;

  new(
    this.variable,
    this.body, {
    required this.isImplicitlyTyped,
    required this.isNullAware,
    required this.isCascade,
    required this.typeOffset,
  }) : isParameterless = variable.isSynthesized {
    variable.parent = this;
    body.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitAnonymousMethodExpression(this, typeContext);
  }

  @override
  String toString() {
    return "AnonymousMethodExpression(${toStringInternal()})";
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('let ');
    printer.writeVariableInitialization(variable.asVariableDeclaration);
    printer.write(' in ');
    printer.writeExpression(body);
  }
}

/// Internal expression representing an anonymous block method invocation.
class AnonymousMethodBlock extends InternalExpression {
  InternalVariable variable;
  Statement body;
  final bool isCascade;
  final bool isImplicitlyTyped;
  final bool isNullAware;
  final bool isParameterless;
  final int typeOffset;

  new(
    this.variable,
    this.body, {
    required this.isImplicitlyTyped,
    required this.isNullAware,
    required this.isCascade,
    required this.typeOffset,
  }) : isParameterless = variable.isSynthesized {
    variable.parent = this;
    body.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitAnonymousMethodBlock(this, typeContext);
  }

  @override
  String toString() {
    return "AnonymousMethodBlock(${toStringInternal()})";
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('let ');
    printer.writeVariableInitialization(variable.asVariableDeclaration);
    printer.write(' in ');
    printer.writeStatement(body);
  }
}

/// Internal expression representing a deferred check.
// TODO(johnniwinther): Change the representation to be direct and perform
// the [Let] encoding in the replacement.
class DeferredCheck extends InternalExpression {
  InternalVariable variable;
  Expression expression;

  new(this.variable, this.expression, {required int fileOffset}) {
    variable.parent = this;
    expression.parent = this;
    this.fileOffset = fileOffset;
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
    printer.writeVariableInitialization(variable.asVariableDeclaration);
    printer.write(' in ');
    printer.writeExpression(expression);
  }
}

/// Internal expression for an invocation of a factory constructor.
class FactoryConstructorInvocation extends InternalExpression {
  bool hasBeenInferred = false;
  final Procedure target;
  final TypeArguments? typeArguments;
  ActualArguments arguments;

  /// If `true`, this invocation is constant, either explicit or inferred.
  final bool isConst;

  new(
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

  new(
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

  new(
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

/// Internal expression representing an if-null expression.
///
/// An if-null expression of the form `a ?? b` is encoded as:
///
///     let v = a in v == null ? b : v
///
class IfNullExpression extends InternalExpression {
  Expression left;
  Expression right;

  new(this.left, this.right) {
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
class InternalIntLiteral extends InternalExpression {
  final int value;

  /// The literal text of the number, as it appears in the source, which may
  /// include digit separators (and may not be safe for parsing with
  /// `int.parse`).
  final String? literal;

  new(this.value, this.literal, {required int fileOffset}) {
    this.fileOffset = fileOffset;
  }

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
    return visitor.visitInternalIntLiteral(this, typeContext);
  }

  @override
  String toString() {
    return "InternalIntLiteral(${toStringInternal()})";
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

class LargeIntLiteral extends InternalExpression {
  /// The parsable String source, stripped of any digit separators.
  final String _strippedLiteral;

  /// The original textual source, possibly with digit separators.
  final String literal;

  bool isParenthesized = false;

  new(this._strippedLiteral, this.literal, {required int fileOffset}) {
    this.fileOffset = fileOffset;
  }

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
    return visitor.visitLargeIntLiteral(this, typeContext);
  }

  @override
  String toString() {
    return "LargeIntLiteral(${toStringInternal()})";
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

  new(this.expression, this.typeArguments, this.arguments) {
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

  new(this.isArrow, [Expression? expression]) : super(expression);

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

/// Front end specific implementation of [Variable].
class VariableDeclarationImpl extends LegacyVariable
    with InternalVariableMixin
    implements InternalVariable {
  @override
  Variable get astVariable => this;

  @override
  final bool forSyntheticToken;

  @override
  final bool isImplicitlyTyped;

  @override
  final bool isLocalFunction;

  new(
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
    required int fileOffset,
    int fileEqualsOffset = TreeNode.noOffset,
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
    this.fileOffset = fileOffset;
    this.fileEqualsOffset = fileEqualsOffset;
  }

  // Coverage-ignore(suite): Not run.
  new forEffect(Expression initializer)
    : forSyntheticToken = false,
      isImplicitlyTyped = false,
      isLocalFunction = false,
      super.forValue(initializer) {
    isStaticLate = false;
  }

  // Coverage-ignore(suite): Not run.
  new forValue(Expression initializer)
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
  }

  @override
  String toString() {
    return "VariableDeclarationImpl(${toStringInternal()})";
  }
}

class InternalLocalVariable extends TreeNode
    with InternalVariableMixin, DelegatingVariableMixin
    implements LocalVariable, InternalVariable {
  @override
  LocalVariable astVariable;

  @override
  final bool forSyntheticToken;

  @override
  final bool isImplicitlyTyped;

  @override
  final bool isLocalFunction;

  new({
    required this.astVariable,
    required this.isImplicitlyTyped,
    this.forSyntheticToken = false,
    this.isLocalFunction = false,
    bool isStaticLate = false,
    required int fileOffset,
    int fileEqualsOffset = TreeNode.noOffset,
  }) {
    this.fileOffset = fileOffset;
    this.isStaticLate = isStaticLate;
    this.fileEqualsOffset = fileEqualsOffset;
  }

  @override
  bool get isAssignable {
    if (isStaticLate) return true;
    return super.isAssignable;
  }

  @override
  // Coverage-ignore(suite): Not run.
  R accept<R>(VariableVisitor<R> v) => v.visitLocalVariable(astVariable);

  @override
  // Coverage-ignore(suite): Not run.
  R accept1<R, A>(VariableVisitor1<R, A> v, A arg) =>
      v.visitLocalVariable(astVariable, arg);

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

  @override
  int binaryOffsetNoTag = -1;

  @override
  // Coverage-ignore(suite): Not run.
  List<VariableContext>? get capturedContexts =>
      variableDeclaration?.capturedContexts;

  @override
  // Coverage-ignore(suite): Not run.
  void set capturedContexts(List<VariableContext>? value) {
    variableDeclaration!.capturedContexts = value;
  }

  @override
  int fileEqualsOffset = TreeNode.noOffset;

  @override
  // Coverage-ignore(suite): Not run.
  Variable get variable => this;

  @override
  void set variable(Variable variable) {
    throw new UnsupportedError("${this.runtimeType}.variable=");
  }

  @override
  // Coverage-ignore(suite): Not run.
  void clearAnnotations() {
    annotations.clear();
  }
}

class InternalLateVariable extends TreeNode
    with InternalVariableMixin, DelegatingVariableMixin
    implements LateVariable, InternalVariable {
  @override
  LateVariable astVariable;

  @override
  final bool forSyntheticToken;

  @override
  final bool isImplicitlyTyped;

  @override
  final bool isLocalFunction;

  new({
    required this.astVariable,
    required this.isImplicitlyTyped,
    this.forSyntheticToken = false,
    this.isLocalFunction = false,
    bool isStaticLate = false,
    required int fileOffset,
    int fileEqualsOffset = TreeNode.noOffset,
  }) {
    this.fileOffset = fileOffset;
    this.isStaticLate = isStaticLate;
    this.fileEqualsOffset = fileEqualsOffset;
  }

  @override
  bool get isAssignable {
    if (isStaticLate) return true;
    return super.isAssignable;
  }

  @override
  // Coverage-ignore(suite): Not run.
  R accept<R>(VariableVisitor<R> v) => v.visitLateVariable(astVariable);

  @override
  // Coverage-ignore(suite): Not run.
  R accept1<R, A>(VariableVisitor1<R, A> v, A arg) =>
      v.visitLateVariable(astVariable, arg);

  @override
  String toString() {
    return "$runtimeType(${toStringInternal()})";
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
  int binaryOffsetNoTag = -1;

  @override
  // Coverage-ignore(suite): Not run.
  List<VariableContext>? get capturedContexts =>
      variableDeclaration?.capturedContexts;

  @override
  void set capturedContexts(List<VariableContext>? value) {
    variableDeclaration!.capturedContexts = value;
  }

  @override
  int fileEqualsOffset = TreeNode.noOffset;

  @override
  Variable get variable => this;

  @override
  void set variable(Variable variable) {
    throw new UnsupportedError("${this.runtimeType}.variable=");
  }

  @override
  // Coverage-ignore(suite): Not run.
  void clearAnnotations() {
    annotations.clear();
  }
}

class InternalPositionalParameter extends TreeNode
    with InternalVariableMixin, DelegatingVariableMixin
    implements PositionalParameter, InternalVariable {
  @override
  PositionalParameter astVariable;

  @override
  final bool forSyntheticToken;

  @override
  final bool isImplicitlyTyped;

  @override
  final bool isLocalFunction;

  new({
    required this.astVariable,
    required this.isImplicitlyTyped,
    this.forSyntheticToken = false,
    this.isLocalFunction = false,
    required int fileOffset,
  }) {
    this.fileOffset = fileOffset;
  }

  @override
  // TODO(62620): Conforming to [Variable] interface. Remove this.
  List<VariableContext>? get capturedContexts {
    throw new UnsupportedError("${this.runtimeType}.capturedContexts");
  }

  @override
  // TODO(62620): Conforming to [Variable] interface. Remove this.
  void set capturedContexts(List<VariableContext>? value) {
    throw new UnsupportedError("${this.runtimeType}.capturedContexts=");
  }

  @override
  // Coverage-ignore(suite): Not run.
  R accept<R>(VariableVisitor<R> v) => v.visitPositionalParameter(astVariable);

  @override
  // Coverage-ignore(suite): Not run.
  R accept1<R, A>(VariableVisitor1<R, A> v, A arg) =>
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
  bool get hasDeclaredDefaultValue => astVariable.hasDeclaredDefaultValue;

  @override
  // Coverage-ignore(suite): Not run.
  void set hasDeclaredDefaultValue(bool value) {
    astVariable.hasDeclaredDefaultValue = value;
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
  Variable get variable => this;

  @override
  void set variable(Variable value) {
    throw new UnsupportedError("${this.runtimeType}");
  }
}

class InternalNamedParameter extends TreeNode
    with InternalVariableMixin, DelegatingVariableMixin
    implements NamedParameter, InternalVariable {
  @override
  NamedParameter astVariable;

  @override
  final bool forSyntheticToken;

  @override
  final bool isImplicitlyTyped;

  @override
  final bool isLocalFunction;

  new({
    required this.astVariable,
    required this.isImplicitlyTyped,
    this.forSyntheticToken = false,
    this.isLocalFunction = false,
    required int fileOffset,
  }) {
    this.fileOffset = fileOffset;
  }

  @override
  // TODO(62620): Conforming to [Variable] interface. Remove this.
  List<VariableContext>? get capturedContexts {
    throw new UnsupportedError("${this.runtimeType}.capturedContexts");
  }

  @override
  // TODO(62620): Conforming to [Variable] interface. Remove this.
  void set capturedContexts(List<VariableContext>? value) {
    throw new UnsupportedError("${this.runtimeType}.capturedContexts=");
  }

  @override
  // Coverage-ignore(suite): Not run.
  R accept<R>(VariableVisitor<R> v) => v.visitNamedParameter(astVariable);

  @override
  // Coverage-ignore(suite): Not run.
  R accept1<R, A>(VariableVisitor1<R, A> v, A arg) =>
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
  bool get hasDeclaredDefaultValue => astVariable.hasDeclaredDefaultValue;

  @override
  // Coverage-ignore(suite): Not run.
  void set hasDeclaredDefaultValue(bool value) {
    astVariable.hasDeclaredDefaultValue = value;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void clearAnnotations() {
    astVariable.clearAnnotations();
  }

  @override
  List<Expression> get annotations => astVariable.annotations;

  @override
  // Coverage-ignore(suite): Not run.
  void addAnnotation(Expression node) {
    astVariable.addAnnotation(node);
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
  Variable get variable => this;

  @override
  void set variable(Variable value) {
    throw new UnsupportedError("${this.runtimeType}");
  }
}

class InternalCatchVariable extends TreeNode
    with InternalVariableMixin, DelegatingVariableMixin
    implements CatchVariable, InternalVariable {
  @override
  CatchVariable astVariable;

  @override
  final bool forSyntheticToken;

  @override
  final bool isImplicitlyTyped;

  @override
  final bool isLocalFunction;

  new({
    required this.astVariable,
    required this.isImplicitlyTyped,
    this.forSyntheticToken = false,
    this.isLocalFunction = false,
    required int fileOffset,
  }) {
    this.fileOffset = fileOffset;
  }

  @override
  String toString() {
    return "InternalCatchVariable(${toStringInternal()})";
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
  String get catchVariableName => astVariable.catchVariableName;
}

// Coverage-ignore(suite): Not run.
class InternalSyntheticVariable extends TreeNode
    with InternalVariableMixin, DelegatingVariableMixin
    implements SyntheticVariable, InternalVariable {
  @override
  SyntheticVariable astVariable;

  @override
  final bool forSyntheticToken;

  @override
  final bool isImplicitlyTyped;

  @override
  final bool isLocalFunction;

  new({
    required this.astVariable,
    required this.isImplicitlyTyped,
    this.forSyntheticToken = false,
    this.isLocalFunction = false,
    required int fileOffset,
  }) {
    this.fileOffset = fileOffset;
  }

  @override
  String toString() {
    return "InternalSyntheticVariable(${toStringInternal()})";
  }

  @override
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

mixin DelegatingVariableMixin on InternalVariableMixin
    implements InternalVariable {
  @override
  String? get cosmeticName => astVariable.cosmeticName;

  @override
  // Coverage-ignore(suite): Not run.
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
  void set hasDeclaredInitializer(bool value) {
    astVariable.hasDeclaredInitializer = value;
  }

  @override
  Expression? get initializer => astVariable.initializer;

  @override
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
  // Coverage-ignore(suite): Not run.
  bool get isCovariantByClass => astVariable.isCovariantByClass;

  @override
  // Coverage-ignore(suite): Not run.
  void set isCovariantByClass(bool value) {
    astVariable.isCovariantByClass = value;
  }

  @override
  // Coverage-ignore(suite): Not run.
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
  // Coverage-ignore(suite): Not run.
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
  void set type(DartType value) {
    astVariable.type = value;
  }

  @override
  VariableDeclaration? get variableDeclaration =>
      astVariable.variableDeclaration;

  @override
  void set variableDeclaration(VariableDeclaration? value) {
    astVariable.variableDeclaration = value;
  }

  @override
  bool get isAssignable => astVariable.isAssignable;

  @override
  // Coverage-ignore(suite): Not run.
  bool get hasIsFinal => astVariable.hasIsFinal;

  @override
  // Coverage-ignore(suite): Not run.
  bool get hasIsConst => astVariable.hasIsConst;

  @override
  // Coverage-ignore(suite): Not run.
  bool get hasIsLate => astVariable.hasIsLate;

  @override
  // Coverage-ignore(suite): Not run.
  bool get hasIsInitializingFormal => astVariable.hasIsInitializingFormal;

  @override
  // Coverage-ignore(suite): Not run.
  bool get hasIsSynthesized => astVariable.hasIsSynthesized;

  @override
  // Coverage-ignore(suite): Not run.
  bool get hasIsHoisted => astVariable.hasIsHoisted;

  @override
  // Coverage-ignore(suite): Not run.
  bool get hasHasDeclaredInitializer => astVariable.hasHasDeclaredInitializer;

  @override
  // Coverage-ignore(suite): Not run.
  bool get hasIsCovariantByClass => astVariable.hasIsCovariantByClass;

  @override
  // Coverage-ignore(suite): Not run.
  bool get hasIsRequired => astVariable.hasIsRequired;

  @override
  // Coverage-ignore(suite): Not run.
  bool get hasIsCovariantByDeclaration =>
      astVariable.hasIsCovariantByDeclaration;

  @override
  // Coverage-ignore(suite): Not run.
  bool get hasIsLowered => astVariable.hasIsLowered;

  @override
  // Coverage-ignore(suite): Not run.
  bool get hasIsWildcard => astVariable.hasIsWildcard;

  @override
  // Coverage-ignore(suite): Not run.
  bool get hasIsSuperInitializingFormal =>
      astVariable.hasIsSuperInitializingFormal;

  @override
  // Coverage-ignore(suite): Not run.
  bool get hasIsErroneouslyInitialized =>
      astVariable.hasIsErroneouslyInitialized;

  @override
  int get fileOffset => astVariable.fileOffset;

  @override
  void set fileOffset(int value) {
    astVariable.fileOffset = value;
  }

  // Coverage-ignore(suite): Not run.
  int get flags => astVariable.flags;

  // Coverage-ignore(suite): Not run.
  void set flags(int value) {
    astVariable.flags = value;
  }

  @override
  // Coverage-ignore(suite): Not run.
  R accept<R>(VariableVisitor<R> v) {
    return astVariable.accept(v);
  }

  @override
  // Coverage-ignore(suite): Not run.
  R accept1<R, A>(VariableVisitor1<R, A> v, A arg) {
    return astVariable.accept1(v, arg);
  }

  String? get name => astVariable.cosmeticName;

  // Coverage-ignore(suite): Not run.
  void set name(String? value) {
    astVariable.cosmeticName = value;
  }

  @override
  // Coverage-ignore(suite): Not run.
  VariableContext get context => astVariable.context;

  @override
  // Coverage-ignore(suite): Not run.
  void set context(VariableContext value) {
    astVariable.context = value;
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

  @override
  // Coverage-ignore(suite): Not run.
  int get binaryOffsetNoTag => astVariable.binaryOffsetNoTag;

  @override
  // Coverage-ignore(suite): Not run.
  void set binaryOffsetNoTag(int value) {
    astVariable.binaryOffsetNoTag = value;
  }

  @override
  // Coverage-ignore(suite): Not run.
  List<VariableContext>? get capturedContexts => astVariable.capturedContexts;

  @override
  // Coverage-ignore(suite): Not run.
  void set capturedContexts(List<VariableContext>? value) {
    astVariable.capturedContexts = value;
  }

  @override
  // Coverage-ignore(suite): Not run.
  int get fileEqualsOffset => astVariable.fileEqualsOffset;

  @override
  // Coverage-ignore(suite): Not run.
  void set fileEqualsOffset(int value) {
    astVariable.fileEqualsOffset = value;
  }

  @override
  // Coverage-ignore(suite): Not run.
  Variable get variable => astVariable.variable;

  @override
  // Coverage-ignore(suite): Not run.
  void set variable(Variable value) {
    astVariable.variable = value;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void clearAnnotations() {
    astVariable.clearAnnotations();
  }
}

abstract interface class InternalVariable implements IVariable, Annotatable {
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
  Variable get astVariable;

  bool get forSyntheticToken;

  /// Determine whether the given [InternalVariable] had an implicit
  /// type.
  bool get isImplicitlyTyped;

  /// Determines whether the given [InternalVariable] represents a
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
  abstract Variable? lateGetter;

  /// The synthesized local setter function for an assignable lowered late
  /// variable.
  ///
  /// This is set in `InferenceVisitor.visitVariableDeclaration` when late
  /// lowering is enabled.
  abstract Variable? lateSetter;

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

mixin InternalVariableMixin on TreeNode implements InternalVariable {
  @override
  bool get forSyntheticToken;

  @override
  bool get isImplicitlyTyped;

  @override
  bool get isLocalFunction;

  @override
  bool isStaticLate = false;

  @override
  Variable? lateGetter;

  @override
  Variable? lateSetter;

  @override
  bool isLateFinalWithoutInitializer = false;

  @override
  DartType? lateType;

  @override
  String? lateName;

  @override
  Variable get asVariableDeclaration => this as Variable;
}

/// Front end specific implementation of [LoadLibrary].
class LoadLibraryImpl extends LoadLibrary {
  final ActualArguments? arguments;

  new(LibraryDependency import, this.arguments) : super(import);

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

  new(this.import, this.target);

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

  new(
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

  new(this.read, this.write, {required this.forEffect}) {
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

  new explicit({
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

  new implicit({
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

  new _(
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

  new explicit({
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

  new implicit({
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

  new _(
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

  new({
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

  new(
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

  new explicit({
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

  new implicit({
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

  new _(
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
  final InternalVariable variable;

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

  new({
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

  new({
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

  new({
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

  new(this.receiver, this.index, {required this.isNullAware}) {
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

  new(
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

  new(this.setter, this.index, this.value) {
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

  new(
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

  new(
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

  new({
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

  new({
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

  new({
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

  new({
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

  new({
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

  new({
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

  new implicit({
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

  new explicit({
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

  new _(
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

  new implicit({
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

  new explicit({
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

  new _(
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

  new implicit({
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

  new explicit({
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

  new _(
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

  new implicit({
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

  new explicit({
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

  new _(
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

  new implicit({
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

  new explicit({
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

  new _(
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

  new(this.left, this.right, {required this.isNot}) {
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

  new(this.left, this.binaryName, this.right) {
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

  new(this.unaryName, this.expression) {
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

  new(this.expression) {
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
    return node.variable.isFinal && !node.variable.isLate;
  }
  return false;
}

/// Returns a clone of [node].
///
/// This assumes that `isPureExpression(node)` is `true`.
Expression clonePureExpression(Expression node) {
  if (node is ThisExpression) {
    return extern.createThisExpression(fileOffset: node.fileOffset);
  } else if (node is VariableGet) {
    assert(
      node.variable.isFinal && !node.variable.isLate,
      "Trying to clone VariableGet of non-final variable"
      " ${node.variable}.",
    );
    return extern.createVariableGet(
      node.variable,
      promotedType: node.promotedType,
      fileOffset: node.fileOffset,
    );
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

  new(
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

  new(this.receiver, this.name, {required this.isNullAware}) {
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

  new(
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

class InternalRecordLiteral extends InternalExpression {
  final List<Expression> positional;
  final List<NamedExpression> named;
  final Map<String, NamedExpression>? namedElements;
  final List<Object /*Expression|NamedExpression*/> originalElementOrder;
  final bool isConst;

  new(
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

class ExtensionTypeRedirectingInitializer extends InternalInitializer {
  Reference targetReference;
  ActualArguments arguments;

  /// Redirecting initializers are encoded as calls to top-level functions.
  /// The type arguments for this call are inferred.
  List<DartType> inferredTypeArguments = [];

  List<Expression> positional = [];
  List<NamedExpression> named = [];

  new(Procedure target, ActualArguments arguments)
    : this.byReference(
        // Getter vs setter doesn't matter for procedures.
        getNonNullableMemberReferenceGetter(target),
        arguments,
      );

  new byReference(this.targetReference, this.arguments) {
    arguments.parent = this;
  }

  @override
  bool get isRedirectingInitializer => true;

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

  new(Procedure field, this.value, {required int fileOffset})
    : assert(field.stubKind == ProcedureStubKind.RepresentationField),
      this.fieldReference = field.reference {
    value.parent = this;
    this.fileOffset = fileOffset;
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

  new(this.innerExpression);

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

  new(
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

  new(this.name, {required this.nameOffset, this.hasTypeParameters = false});

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

  new(
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

  new(this.name, this.target, this.typeArguments, this.arguments) {
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

  new(this.name, this.typeArguments, this.arguments, this.target) {
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

  new(this.target, this.arguments) {
    arguments.parent = this;
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool get isRedirectingInitializer => true;

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

  new(this.target, this.arguments, {required this.isSynthetic}) {
    arguments.parent = this;
  }

  @override
  // Coverage-ignore(suite): Not run.
  bool get isSuperInitializer => true;

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

// Coverage-ignore(suite): Not run.
/// Internal node for encoding the "element" of a for-in loop.
///
/// The element is the part before "in" which can either an identifier or
/// a single variable declaration.
sealed class InternalForInElement {
  /// Infers the for-in element and the [iterable].
  ForInHeaderResult inferForInHeader(
    InferenceVisitorBase visitor, {
    required TreeNode node,
    required Expression iterable,
    required bool isAsync,
    required int forOffset,
    required bool isClosureContextLoweringEnabled,
  });

  void toTextInternal(AstPrinter printer);

  String toText(AstTextStrategy strategy) {
    AstPrinter printer = new AstPrinter(strategy);
    toTextInternal(printer);
    return printer.getText();
  }

  @override
  String toString() {
    return '$runtimeType(${toText(defaultAstTextStrategy)})';
  }
}

/// Base implementation for non-pattern for-in elements.
sealed class _BaseForInElement extends InternalForInElement {
  /// Computes the type context from the element. This is type context used for
  /// inferring the for-in iterable.
  DartType _computeElementTypeContext(InferenceVisitorBase visitor);

  /// Computes the [Variable] that will be used in the emitted
  /// [ForInStatement].
  ///
  /// This can be the variable declared as the for-in element or a synthetic
  /// variable, when there is no declared variable or it doesn't suffice for
  /// the correct runtime behavior.
  Variable _computeLoopVariable(
    InferenceVisitorBase visitor,
    DartType type, {
    required int forOffset,
    required bool isClosureContextLoweringEnabled,
  });

  /// Computes the [ForInEncoding] for the additional nodes needed for the
  /// assignment to the for-in element.
  ForInEncoding _computeEncoding(
    InferenceVisitorBase visitor, {
    required Variable loopVariable,
  });

  /// Helper for creating a synthetic variable declaration for the emitted
  /// [ForInStatement].
  Variable _createSyntheticVariableDeclaration(
    DartType type, {
    required int forOffset,
    required bool isClosureContextLoweringEnabled,
  }) {
    if (isClosureContextLoweringEnabled) {
      return new SyntheticVariable(type: type)..fileOffset = forOffset;
    }
    return extern.createUninitializedVariable(
      type: type,
      fileOffset: forOffset,
      isFinal: true,
    );
  }

  @override
  ForInHeaderResult inferForInHeader(
    InferenceVisitorBase visitor, {
    required TreeNode node,
    required Expression iterable,
    required bool isAsync,
    required int forOffset,
    required bool isClosureContextLoweringEnabled,
  }) {
    DartType elementTypeContext = _computeElementTypeContext(visitor);

    ExpressionInferenceResult iterableResult = visitor.inferForInIterable(
      iterable,
      elementTypeContext,
      isAsync: isAsync,
    );
    DartType inferredType = iterableResult.inferredType;
    Variable variable = _computeLoopVariable(
      visitor,
      inferredType,
      forOffset: forOffset,
      isClosureContextLoweringEnabled: isClosureContextLoweringEnabled,
    );

    return new ForInHeaderResult(
      loopVariable: variable,
      iterable: iterableResult.expression,
      computeEncoding: () => _computeEncoding(visitor, loopVariable: variable),
    );
  }
}

/// For-in element for a single declared variable.
class SingleVariableDeclarationForInElement extends _BaseForInElement {
  /// Error that must be emitted prior to the generated for-in statement.
  ///
  /// This is used for instance for constant loop variables.
  final InvalidExpression? error;

  /// If the assignment to [_variable] needs additional steps, like
  /// a type coercion, this holds a synthetic variable declaration used as an
  /// intermediate step.
  VariableDeclaration? _variableForSideEffect;

  /// The declared variable.
  final VariableDeclaration variableDeclaration;

  new({required this.variableDeclaration, required this.error});

  @override
  Variable _computeLoopVariable(
    InferenceVisitorBase visitor,
    DartType type, {
    required int forOffset,
    required bool isClosureContextLoweringEnabled,
  }) {
    Variable loopVariable;
    DartType loopVariableType;
    bool checkAssignment = true;
    if (variableDeclaration.variable case InternalVariable variable) {
      loopVariable = variable.astVariable;
      if (variable.isImplicitlyTyped) {
        loopVariableType = variable.type = type;
        checkAssignment = false;
      } else {
        loopVariableType = variable.type;
      }
    } else {
      // Coverage-ignore-block(suite): Not run.
      loopVariable = variableDeclaration.variable;
      loopVariableType = variableDeclaration.variable.type;
    }
    if (checkAssignment) {
      Variable tempVariable = _createSyntheticVariableDeclaration(
        type,
        forOffset: forOffset,
        isClosureContextLoweringEnabled: isClosureContextLoweringEnabled,
      );
      ExpressionInferenceResult canary = new ExpressionInferenceResult(
        type,
        extern.createVariableGet(
          tempVariable,
          fileOffset: loopVariable.fileOffset,
        ),
      );
      ExpressionInferenceResult assignmentResult = visitor
          .ensureAssignableResult(
            loopVariableType,
            canary,
            isVoidAllowed: true,
            errorTemplate: diag.forInLoopElementTypeNotAssignable,
          );
      if (!identical(assignmentResult, canary)) {
        // Something happened during assignment, like an error or a type
        // coercion, so we need to use the temp variable as the loop variable
        // and assign to the declared variable in the loop.
        loopVariable.initializer = assignmentResult.expression
          ..parent = loopVariable;
        visitor.flowAnalysis.declare(
          loopVariable,
          new SharedTypeView(loopVariableType),
          initialized: true,
        );
        _variableForSideEffect = extern.createVariableDeclaration(loopVariable);
        loopVariable = tempVariable;
      }
    }
    return loopVariable;
  }

  @override
  ForInEncoding _computeEncoding(
    InferenceVisitorBase visitor, {
    required Variable loopVariable,
  }) {
    return new ForInEncoding(
      preLoopError: error,
      bodyPrologue: _variableForSideEffect != null
          ? extern.createVariableStatement(_variableForSideEffect!)
          : null,
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeVariableInitialization(
      variableDeclaration.variable,
      includeInitializer: false,
      isImplicitlyTyped:
          variableDeclaration.variable is InternalVariable &&
          (variableDeclaration.variable as InternalVariable).isImplicitlyTyped,
    );
  }

  @override
  DartType _computeElementTypeContext(InferenceVisitorBase visitor) {
    if (variableDeclaration.variable case InternalVariable variable) {
      if (variable.isImplicitlyTyped) {
        return const UnknownType();
      }
    }
    return variableDeclaration.variable.type;
  }
}

/// For-in element for a multi-variable declaration, like
/// `for (var a, b in [])`. This is an error case.
class MultiVariableDeclarationForInElement extends _BaseForInElement {
  /// The declared variables.
  final List<VariableDeclaration> variableDeclarations;

  /// The error that should be emitted prior to the for-in statement.
  final InvalidExpression error;

  new({required this.variableDeclarations, required this.error});

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    for (int i = 0; i < variableDeclarations.length; i++) {
      VariableDeclaration variableDeclaration = variableDeclarations[i];
      if (i == 0) {
        printer.writeVariableInitialization(
          variableDeclaration.variable,
          includeModifiersAndType: true,
          includeInitializer: false,
          isImplicitlyTyped:
              variableDeclaration.variable is InternalVariable &&
              (variableDeclaration.variable as InternalVariable)
                  .isImplicitlyTyped,
        );
      } else {
        printer.write(', ');
        printer.writeVariableInitialization(
          variableDeclaration.variable,
          includeModifiersAndType: false,
          includeInitializer: false,
        );
      }
    }
  }

  @override
  DartType _computeElementTypeContext(InferenceVisitorBase visitor) =>
      const UnknownType();

  @override
  ForInEncoding _computeEncoding(
    InferenceVisitorBase visitor, {
    required Variable loopVariable,
  }) {
    return new ForInEncoding(
      preLoopError: error,
      bodyPrologue: extern.createBlock([
        for (VariableDeclaration variableDeclaration in variableDeclarations)
          extern.createVariableStatement(variableDeclaration),
      ], fileOffset: TreeNode.noOffset),
    );
  }

  @override
  Variable _computeLoopVariable(
    InferenceVisitorBase visitor,
    DartType type, {
    required int forOffset,
    required bool isClosureContextLoweringEnabled,
  }) {
    return _createSyntheticVariableDeclaration(
      type,
      forOffset: forOffset,
      isClosureContextLoweringEnabled: isClosureContextLoweringEnabled,
    );
  }
}

/// For-in element for an unassignable expression, like `for (1 in [])`. This is
/// an error case.
class UnassignableForInElement extends _BaseForInElement {
  /// The unassignable expression.
  final Expression expression;

  /// The error that should be emitted prior to the for-in statement.
  final InvalidExpression error;

  new({required this.expression, required this.error});

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(expression);
  }

  @override
  DartType _computeElementTypeContext(InferenceVisitorBase visitor) =>
      const UnknownType();

  @override
  ForInEncoding _computeEncoding(
    InferenceVisitorBase visitor, {
    required Variable loopVariable,
  }) {
    return new ForInEncoding(
      preLoopError: error,
      bodyPrologue: extern.createBlock([
        extern.createExpressionStatement(
          visitor.inferExpression(expression, const UnknownType()).expression,
        ),
      ], fileOffset: TreeNode.noOffset),
    );
  }

  @override
  Variable _computeLoopVariable(
    InferenceVisitorBase visitor,
    DartType type, {
    required int forOffset,
    required bool isClosureContextLoweringEnabled,
  }) {
    return _createSyntheticVariableDeclaration(
      type,
      forOffset: forOffset,
      isClosureContextLoweringEnabled: isClosureContextLoweringEnabled,
    );
  }
}

/// For-in element for a pattern variable declaration.
class PatternForInElement extends InternalForInElement {
  /// The pattern used in the variable declaration.
  final Pattern pattern;

  /// The file offset of the `in` keyword.
  final int inOffset;

  new({required this.pattern, required this.inOffset});

  @override
  ForInHeaderResult inferForInHeader(
    InferenceVisitorBase visitor, {
    required TreeNode node,
    required Expression iterable,
    required bool isAsync,
    required int forOffset,
    required bool isClosureContextLoweringEnabled,
  }) {
    PatternForInData data = visitor.inferPatternForInHeader(
      node: node,
      pattern: pattern,
      iterable: iterable,
      isAsync: isAsync,
      inOffset: inOffset,
    );
    return new ForInHeaderResult(
      loopVariable: data.loopVariable,
      iterable: data.iterable,
      computeEncoding: () => new ForInEncoding(
        bodyPrologue: data.computePatternVariableDeclaration(),
      ),
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('var ');
    pattern.toTextInternal(printer);
  }
}

/// For-in element for an erroneous expression.
class InvalidForInElement extends _BaseForInElement {
  /// The error for the erroneous expression.
  final InvalidExpression error;

  /// The file offset of the `in` keyword.
  final int inOffset;

  new({required this.error, required this.inOffset});

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(error);
  }

  @override
  DartType _computeElementTypeContext(InferenceVisitorBase visitor) =>
      const UnknownType();

  @override
  ForInEncoding _computeEncoding(
    InferenceVisitorBase visitor, {
    required Variable loopVariable,
  }) {
    return new ForInEncoding(
      bodyPrologue: extern.createBlock([
        extern.createExpressionStatement(error),
      ], fileOffset: TreeNode.noOffset),
    );
  }

  @override
  Variable _computeLoopVariable(
    InferenceVisitorBase visitor,
    DartType type, {
    required int forOffset,
    required bool isClosureContextLoweringEnabled,
  }) {
    return _createSyntheticVariableDeclaration(
      type,
      forOffset: forOffset,
      isClosureContextLoweringEnabled: isClosureContextLoweringEnabled,
    );
  }
}

/// For-in element for an existing variable, like `for (a in [])` where `a` is
/// an already defined local variable.
class ExistingVariableForInElement extends _BaseForInElement {
  /// The variable used as the for-in element.
  final InternalVariable variable;

  /// The file offset of the variable name.
  final int nameOffset;

  /// The file offset of the `in` keyword.
  final int inOffset;

  /// Error that must be emitted prior to the generated for-in statement.
  ///
  /// This is used for instance for a final local variable.
  final InvalidExpression? error;

  new({
    required this.variable,
    required this.nameOffset,
    required this.inOffset,
    this.error,
  });
  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write(variable.cosmeticName!);
  }

  @override
  DartType _computeElementTypeContext(InferenceVisitorBase visitor) {
    DartType? promotedType = visitor.flowAnalysis
        .promotedType(variable.astVariable)
        ?.unwrapTypeView();
    return promotedType ?? variable.type;
  }

  @override
  ForInEncoding _computeEncoding(
    InferenceVisitorBase visitor, {
    required Variable loopVariable,
  }) {
    ExpressionInferenceResult result = visitor.inferVariableSet(
      variable: variable,
      variableType: variable.type,
      rhsResult: new ExpressionInferenceResult(
        loopVariable.type,
        error ?? extern.createVariableGet(loopVariable),
      ),
      assignOffset: inOffset,
      nameOffset: nameOffset,
    );
    return new ForInEncoding(
      bodyPrologue: extern.createExpressionStatement(result.expression),
    );
  }

  @override
  Variable _computeLoopVariable(
    InferenceVisitorBase visitor,
    DartType type, {
    required int forOffset,
    required bool isClosureContextLoweringEnabled,
  }) {
    return _createSyntheticVariableDeclaration(
      type,
      forOffset: inOffset,
      isClosureContextLoweringEnabled: isClosureContextLoweringEnabled,
    );
  }
}

/// For-in element for a property access, like `for (a in [])` where `a` is an
/// instance field in the enclosing class.
class PropertyForInElement extends _BaseForInElement {
  /// The implicit `this` expression on which the property write is performed.
  final Expression receiver;

  /// The name of the accessed instance member.
  final Name name;

  /// The file offset of the property name.
  final int nameOffset;

  /// The file offset of the `in` keyword.
  final int inOffset;

  /// Data computed during [_computeElementTypeContext] for use in
  /// [_computeEncoding].
  late final PropertySetData _data;

  new({
    required this.receiver,
    required this.name,
    required this.nameOffset,
    required this.inOffset,
  });

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeName(name);
  }

  @override
  DartType _computeElementTypeContext(InferenceVisitorBase visitor) {
    _data = visitor.computePropertySetData(
      receiver: receiver,
      name: name,
      fileOffset: nameOffset,
      isNullAware: false,
    );
    return _data.writeContext;
  }

  @override
  ForInEncoding _computeEncoding(
    InferenceVisitorBase visitor, {
    required Variable loopVariable,
  }) {
    ExpressionInferenceResult result = visitor.inferPropertySet(
      fileOffset: nameOffset,
      receiver: _data.receiver,
      receiverType: _data.receiverType,
      propertyName: name,
      writeTarget: _data.target,
      writeContext: _data.writeContext,
      valueResult: new ExpressionInferenceResult(
        loopVariable.type,
        extern.createVariableGet(loopVariable),
      ),
      forEffect: true,
    );
    return new ForInEncoding(
      bodyPrologue: extern.createExpressionStatement(result.expression),
    );
  }

  @override
  Variable _computeLoopVariable(
    InferenceVisitorBase visitor,
    DartType type, {
    required int forOffset,
    required bool isClosureContextLoweringEnabled,
  }) {
    return _createSyntheticVariableDeclaration(
      type,
      forOffset: inOffset,
      isClosureContextLoweringEnabled: isClosureContextLoweringEnabled,
    );
  }
}

/// For-in element for a property access, like `for (a in [])` where `a` is a
/// top-level field.
class StaticForInElement extends _BaseForInElement {
  /// The accessed property.
  final Member target;

  /// The file offset of the property name.
  final int nameOffset;

  /// The file offset of the `in` keyword.
  final int inOffset;

  /// The property type computed during [_computeElementTypeContext] for use in
  /// [_computeEncoding].
  late final DartType _writeContext;

  new({required this.target, required this.nameOffset, required this.inOffset});

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeName(target.name);
  }

  @override
  DartType _computeElementTypeContext(InferenceVisitorBase visitor) {
    return _writeContext = visitor.computeStaticSetWriteContext(target);
  }

  @override
  ForInEncoding _computeEncoding(
    InferenceVisitorBase visitor, {
    required Variable loopVariable,
  }) {
    ExpressionInferenceResult result = visitor.inferStaticSet(
      member: target,
      rhsResult: new ExpressionInferenceResult(
        loopVariable.type,
        extern.createVariableGet(loopVariable),
      ),
      writeContext: _writeContext,
      assignOffset: inOffset,
      nameOffset: nameOffset,
    );
    return new ForInEncoding(
      bodyPrologue: extern.createExpressionStatement(result.expression),
    );
  }

  @override
  Variable _computeLoopVariable(
    InferenceVisitorBase visitor,
    DartType type, {
    required int forOffset,
    required bool isClosureContextLoweringEnabled,
  }) {
    return _createSyntheticVariableDeclaration(
      type,
      forOffset: inOffset,
      isClosureContextLoweringEnabled: isClosureContextLoweringEnabled,
    );
  }
}

/// For-in element for a property access, like `for (a in [])` where `a` is an
/// instance getter in the enclosing extension.
class ExtensionForInElement extends _BaseForInElement {
  /// The extension in which the [setter] is declared.
  final Extension extension;

  /// The known type arguments for the type parameters declared in
  /// [extension], either explicitly provided like `E<int>(o).a = b` or
  /// implied as in `a = b` from within the extension `E`.
  final List<DartType>? thisTypeArguments;

  /// The receiver for the assignment.
  Expression thisAccess;

  /// The name of setter.
  ///
  /// This is the name of the access and _not_ the name of the lowered method.
  final Name name;

  /// The extension member called for the assignment.
  Procedure setter;

  /// The file offset of the property name.
  final int nameOffset;

  /// The file offset of the `in` keyword.
  final int inOffset;

  /// Data computed during [_computeElementTypeContext] for use in
  /// [_computeEncoding].
  late final ExtensionSetData _data;

  new({
    required this.extension,
    required this.thisTypeArguments,
    required this.thisAccess,
    required this.name,
    required this.setter,
    required this.nameOffset,
    required this.inOffset,
  }) : assert(
         thisTypeArguments == null ||
             // Coverage-ignore(suite): Not run.
             extension.typeParameters.isNotEmpty &&
                 thisTypeArguments.length == extension.typeParameters.length,
       );

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeName(name);
  }

  @override
  DartType _computeElementTypeContext(InferenceVisitorBase visitor) {
    _data = visitor.computeExtensionSetData(
      extension: extension,
      knownTypeArguments: thisTypeArguments,
      receiver: thisAccess,
      extensionTypeArgumentOffset: null,
      setter: setter,
      isNullAware: false,
      fileOffset: nameOffset,
    );
    return _data.valueType;
  }

  @override
  ForInEncoding _computeEncoding(
    InferenceVisitorBase visitor, {
    required Variable loopVariable,
  }) {
    ExpressionInferenceResult result = visitor.inferExtensionSet(
      data: _data,
      valueResult: new ExpressionInferenceResult(
        loopVariable.type,
        extern.createVariableGet(loopVariable),
      ),
      forEffect: true,
      fileOffset: nameOffset,
    );
    return new ForInEncoding(
      bodyPrologue: extern.createExpressionStatement(result.expression),
    );
  }

  @override
  Variable _computeLoopVariable(
    InferenceVisitorBase visitor,
    DartType type, {
    required int forOffset,
    required bool isClosureContextLoweringEnabled,
  }) {
    return _createSyntheticVariableDeclaration(
      type,
      forOffset: inOffset,
      isClosureContextLoweringEnabled: isClosureContextLoweringEnabled,
    );
  }
}

/// Encoding of additional nodes need for correct runtime behavior of a for-in
/// loop.
class ForInEncoding {
  /// Error that needs to be thrown before trying to execute the loop.
  final InvalidExpression? preLoopError;

  /// Statement that needs to be executed before the loop body.
  ///
  /// This can contain variable declarations for variables used in the loop and
  /// must therefore be emitted in the same block as the body content.
  final Statement? bodyPrologue;

  new({this.preLoopError, this.bodyPrologue});

  @override
  String toString() => 'ForInStatementResult($preLoopError,$bodyPrologue)';
}

/// The result of inferring a for-in loop element and iterable.
class ForInHeaderResult {
  /// The [Variable] that should be used as the variable in the
  /// emitted [ForInStatement].
  final Variable loopVariable;

  /// The [Expression] that should be used as the iterable in the emitted
  /// [ForInStatement].
  final Expression iterable;

  /// Function that computes the [ForInEncoding] need for the for-in element.
  ///
  /// This must be called between [FlowAnalysis.forEach_bodyBegin] and
  /// [FlowAnalysis.forEach_end] to ensure the effect of the encoding is seen
  /// as being part of the loop body.
  final ForInEncoding Function() computeEncoding;

  new({
    required this.loopVariable,
    required this.iterable,
    required this.computeEncoding,
  });

  @override
  String toString() =>
      'ForInHeaderResult($loopVariable,$iterable,$computeEncoding)';
}

/// Internal node for a for-in loop statement.
class InternalForInStatement extends InternalStatement
    implements LoopStatement {
  /// The element of the for-in loop.
  ///
  /// For instance 'x' and 'var x' in
  ///
  ///     for (x in list) {}
  ///     for (var x in list) {}
  ///
  final InternalForInElement element;

  /// The iterable of the for-in loop.
  ///
  /// For instance 'x' in
  ///
  ///     for (var e in x) {}
  ///     await for (var e in x) {}
  ///
  final Expression iterable;

  /// The for-in loop body.
  @override
  Statement body;

  /// Whether the for-in loop is asynchronous.
  final bool isAsync;

  /// The file offset for the for-in body.
  final int bodyOffset;

  new(
    this.element,
    this.iterable,
    this.body, {
    required this.isAsync,
    required int fileOffset,
    required this.bodyOffset,
  }) {
    this.fileOffset = fileOffset;
  }

  @override
  StatementInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitInternalForInStatement(this);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (isAsync) {
      printer.write('async ');
    }
    printer.write('for (');
    element.toTextInternal(printer);
    printer.write(' in ');
    printer.writeExpression(iterable);
    printer.write(') ');
    printer.writeStatement(body);
  }

  @override
  String toString() {
    return "$runtimeType(${toStringInternal()})";
  }
}

class InternalVariableGet extends InternalExpression {
  /// The target variable.
  final InternalVariable variable;

  new(this.variable);

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalVariableGet(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write(variable.cosmeticName ?? '<unnamed-variable>');
  }

  @override
  String toString() {
    return "InternalVariableGet(${toStringInternal()})";
  }
}

class InternalVariableSet extends InternalExpression {
  /// The target variable.
  final InternalVariable variable;

  Expression value;

  new(this.variable, this.value) {
    value.parent = this;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalVariableSet(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write(variable.cosmeticName ?? '<unnamed-variable>');
    printer.write(' = ');
    printer.writeExpression(value);
  }

  @override
  String toString() {
    return "InternalVariableSet(${toStringInternal()})";
  }
}

class InternalFunctionNode {
  final DartType? returnType;
  final List<TypeParameter> typeParameters;
  final List<InternalVariable> positionalParameters;
  final List<InternalVariable> namedParameters;
  final int requiredParameterCount;
  final AsyncMarker asyncMarker;
  final Statement? body;
  final int fileOffset;
  final int fileEndOffset;

  new({
    required this.returnType,
    required this.typeParameters,
    required this.positionalParameters,
    required this.namedParameters,
    required this.requiredParameterCount,
    required this.asyncMarker,
    required this.body,
    required this.fileOffset,
    required this.fileEndOffset,
  });

  FunctionType computeFunctionType() {
    return FunctionNode.computeFunctionTypeFromData(
      returnType: returnType ?? const DynamicType(),
      typeParameters: typeParameters,
      // TODO(johnniwinther): Can we avoid creating a list of ast variables?
      positionalParameters: [
        for (InternalVariable parameter in positionalParameters)
          parameter.astVariable,
      ],
      namedParameters: [
        for (InternalVariable parameter in namedParameters)
          parameter.astVariable,
      ],
      nullability: Nullability.nonNullable,
      requiredParameterCount: requiredParameterCount,
    );
  }

  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer, {String name = ''}) {
    if (returnType != null) {
      printer.writeType(returnType!);
      printer.write(' ');
    }
    printer.write(name);
    if (typeParameters.isNotEmpty) {
      printer.write('<');
      for (int index = 0; index < typeParameters.length; index++) {
        if (index > 0) {
          printer.write(', ');
        }
        printer.write(typeParameters[index].name ?? '');
        printer.write(' extends ');
        printer.writeType(typeParameters[index].bound);
      }
      printer.write('>');
    }
    printer.write('(');
    for (int index = 0; index < positionalParameters.length; index++) {
      if (index > 0) {
        printer.write(', ');
      }
      if (index == requiredParameterCount) {
        printer.write('[');
      }
      positionalParameters[index].toTextInternal(printer);
    }
    if (requiredParameterCount < positionalParameters.length) {
      printer.write(']');
    }
    if (namedParameters.isNotEmpty) {
      if (positionalParameters.isNotEmpty) {
        printer.write(', ');
      }
      printer.write('{');
      for (int index = 0; index < namedParameters.length; index++) {
        if (index > 0) {
          printer.write(', ');
        }
        namedParameters[index].toTextInternal(printer);
      }
      printer.write('}');
    }
    printer.write(')');
    Statement? body = this.body;
    if (body != null) {
      if (body is ReturnStatement) {
        printer.write(' => ');
        printer.writeExpression(body.expression!);
      } else {
        printer.write(' ');
        printer.writeStatement(body);
      }
    } else {
      printer.write(';');
    }
  }
}

class InternalFunctionExpression extends InternalExpression {
  final InternalFunctionNode function;

  new({required this.function, required int fileOffset}) {
    this.fileOffset = fileOffset;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalFunctionExpression(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    function.toTextInternal(printer);
  }

  @override
  String toString() {
    return "$runtimeType(${toStringInternal()}";
  }
}

class InternalFunctionDeclaration extends InternalStatement {
  final InternalVariable variable;
  late final InternalFunctionNode function;
  late final bool hasImplicitReturnType;

  new({required this.variable, required int fileOffset}) {
    this.fileOffset = fileOffset;
  }

  @override
  StatementInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitInternalFunctionDeclaration(this);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    function.toTextInternal(printer, name: variable.cosmeticName ?? '');
    if (function.body is ReturnStatement) {
      printer.write(';');
    }
  }

  @override
  String toString() {
    return "$runtimeType(${toStringInternal()}";
  }
}

// Coverage-ignore(suite): Not run.
sealed class InternalPattern extends AuxiliaryPattern {
  List<InternalVariable> get internalDeclaredVariables;

  @override
  @Deprecated('Use internalDeclaredVariables instead')
  List<Variable> get declaredVariables =>
      unsupported("${runtimeType}.declaredVariables", -1, null);

  @override
  void replaceChild(TreeNode child, TreeNode replacement) {
    // Do nothing. The node should not be part of the resulting AST, anyway.
  }

  @override
  void visitChildren(Visitor<dynamic> v) =>
      unsupported("${runtimeType}.visitChildren", -1, null);

  @override
  void transformChildren(Transformer v) =>
      unsupported("${runtimeType}.transformChildren", -1, null);

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    unsupported("${runtimeType}.transformOrRemoveChildren", -1, null);
  }

  shared.PatternResult acceptInference(
    InferenceVisitorImpl visitor,
    SharedMatchContext context,
  );
}

/// An [InternalPattern] for `pattern || pattern`.
class InternalOrPattern extends InternalPattern {
  final InternalPattern left;
  final InternalPattern right;

  final List<InternalVariable> orPatternJointVariables;

  @override
  List<InternalVariable> get internalDeclaredVariables =>
      orPatternJointVariables;

  new(
    this.left,
    this.right, {
    required this.orPatternJointVariables,
    required int fileOffset,
  }) {
    left.parent = this;
    right.parent = this;
    this.fileOffset = fileOffset;
  }

  @override
  shared.PatternResult acceptInference(
    InferenceVisitorImpl visitor,
    SharedMatchContext context,
  ) {
    return visitor.visitInternalOrPattern(this, context);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    left.toTextInternal(printer);
    printer.write(' || ');
    right.toTextInternal(printer);
  }

  @override
  String toString() {
    return "$runtimeType(${toStringInternal()})";
  }
}

/// An [InternalPattern] for `pattern && pattern`.
class InternalAndPattern extends InternalPattern {
  final InternalPattern left;
  final InternalPattern right;

  @override
  List<InternalVariable> get internalDeclaredVariables => [
    ...left.internalDeclaredVariables,
    ...right.internalDeclaredVariables,
  ];

  new(this.left, this.right, {required int fileOffset}) {
    left.parent = this;
    right.parent = this;
    this.fileOffset = fileOffset;
  }

  @override
  shared.PatternResult acceptInference(
    InferenceVisitorImpl visitor,
    SharedMatchContext context,
  ) {
    return visitor.visitInternalAndPattern(this, context);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    left.toTextInternal(printer);
    printer.write(' && ');
    right.toTextInternal(printer);
  }

  @override
  String toString() {
    return "$runtimeType(${toStringInternal()})";
  }
}

/// An [InternalPattern] based on a constant [Expression].
class InternalConstantPattern extends InternalPattern {
  final Expression expression;

  new({required this.expression, required int fileOffset}) {
    expression.parent = this;
    this.fileOffset = fileOffset;
  }

  @override
  List<InternalVariable> get internalDeclaredVariables => const [];

  @override
  shared.PatternResult acceptInference(
    InferenceVisitorImpl visitor,
    SharedMatchContext context,
  ) {
    return visitor.visitInternalConstantPattern(this, context);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    expression.toTextInternal(printer);
  }

  @override
  String toString() {
    return "ConstantPattern(${toStringInternal()})";
  }
}

class InternalAssignedVariablePattern extends InternalPattern {
  final InternalVariable variable;

  new(this.variable, {required int fileOffset}) {
    this.fileOffset = fileOffset;
  }

  @override
  List<InternalVariable> get internalDeclaredVariables => const [];

  @override
  String get variableName => variable.cosmeticName!;

  @override
  shared.PatternResult acceptInference(
    InferenceVisitorImpl visitor,
    SharedMatchContext context,
  ) {
    return visitor.visitInternalAssignedVariablePattern(this, context);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write(variable.cosmeticName!);
  }

  @override
  String toString() {
    return "$runtimeType(${toStringInternal()})";
  }
}

/// An [InternalPattern] for `pattern as type`.
class InternalCastPattern extends InternalPattern {
  final InternalPattern pattern;
  final DartType type;

  new(this.pattern, this.type, {required int fileOffset}) {
    pattern.parent = this;
    this.fileOffset = fileOffset;
  }

  @override
  String? get variableName => pattern.variableName;

  @override
  List<InternalVariable> get internalDeclaredVariables =>
      pattern.internalDeclaredVariables;

  @override
  shared.PatternResult acceptInference(
    InferenceVisitorImpl visitor,
    SharedMatchContext context,
  ) {
    return visitor.visitInternalCastPattern(this, context);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    pattern.toTextInternal(printer);
    printer.write(' as ');
    printer.writeType(type);
  }

  @override
  String toString() {
    return "$runtimeType(${toStringInternal()})";
  }
}

class InternalInvalidPattern extends InternalPattern {
  final Expression invalidExpression;

  @override
  final List<InternalVariable> internalDeclaredVariables;

  new({
    required this.invalidExpression,
    required this.internalDeclaredVariables,
    required int fileOffset,
  }) {
    invalidExpression.parent = this;
    this.fileOffset = fileOffset;
  }

  @override
  shared.PatternResult acceptInference(
    InferenceVisitorImpl visitor,
    SharedMatchContext context,
  ) {
    return visitor.visitInternalInvalidPattern(this, context);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(invalidExpression);
  }

  @override
  String toString() {
    return "$runtimeType(${toStringInternal()})";
  }
}

/// An [InternalPattern] for `<typeArgument>[pattern0, ... patternN]`.
class InternalListPattern extends InternalPattern {
  /// The element type argument as specified by the list pattern syntax.
  DartType? typeArgument;

  List<InternalPattern> patterns;

  @override
  List<InternalVariable> get internalDeclaredVariables => [
    for (InternalPattern pattern in patterns)
      ...pattern.internalDeclaredVariables,
  ];

  new({
    required this.typeArgument,
    required this.patterns,
    required int fileOffset,
  }) {
    setParents(patterns, this);
    this.fileOffset = fileOffset;
  }

  @override
  shared.PatternResult acceptInference(
    InferenceVisitorImpl visitor,
    SharedMatchContext context,
  ) {
    return visitor.visitInternalListPattern(this, context);
  }

  @override
  // Coverage-ignore(suite): Not run.
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
    return "$runtimeType(${toStringInternal()})";
  }
}

class InternalMapPattern extends InternalPattern {
  /// The key type arguments as specific in the map pattern syntax.
  DartType? keyType;

  /// The value type arguments as specific in the map pattern syntax.
  DartType? valueType;

  final List<InternalMapPatternEntry> entries;

  @override
  List<InternalVariable> get internalDeclaredVariables => [
    for (InternalMapPatternEntry entry in entries)
      if (entry is! InternalMapPatternRestEntry)
        ...entry.value.internalDeclaredVariables,
  ];

  new({
    required this.keyType,
    required this.valueType,
    required this.entries,
    required int fileOffset,
  }) : assert((keyType == null) == (valueType == null)) {
    setParents(entries, this);
    this.fileOffset = fileOffset;
  }

  @override
  shared.PatternResult acceptInference(
    InferenceVisitorImpl visitor,
    SharedMatchContext context,
  ) {
    return visitor.visitInternalMapPattern(this, context);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (keyType != null && valueType != null) {
      printer.writeTypeArguments([keyType!, valueType!]);
    }
    printer.write('{');
    String comma = '';
    for (InternalMapPatternEntry entry in entries) {
      printer.write(comma);
      entry.toTextInternal(printer);
      comma = ', ';
    }
    printer.write('}');
  }

  @override
  String toString() {
    return '$runtimeType(${toStringInternal()})';
  }
}

class InternalMapPatternEntry extends TreeNode with InternalTreeNode {
  final Expression key;
  final InternalPattern value;

  new({required this.key, required this.value, required int fileOffset}) {
    value.parent = this;
    this.fileOffset = fileOffset;
  }

  @override
  R accept<R>(TreeVisitor<R> v) {
    throw new UnimplementedError('${runtimeType}.accept');
  }

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) {
    throw new UnimplementedError('${runtimeType}.accept1');
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    key.toTextInternal(printer);
    printer.write(': ');
    value.toTextInternal(printer);
  }

  @override
  String toString() {
    return 'MapPatternEntry(${toStringInternal()})';
  }
}

class InternalMapPatternRestEntry extends TreeNode
    with InternalTreeNode
    implements InternalMapPatternEntry {
  new({required int fileOffset}) {
    this.fileOffset = fileOffset;
  }

  @override
  // Coverage-ignore(suite): Not run.
  Expression get key => throw new UnsupportedError('$runtimeType.key');

  @override
  // Coverage-ignore(suite): Not run.
  InternalPattern get value => throw new UnsupportedError('$runtimeType.value');

  @override
  R accept<R>(TreeVisitor<R> v) {
    throw new UnimplementedError('${runtimeType}.accept');
  }

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) {
    throw new UnimplementedError('${runtimeType}.accept1');
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('...');
  }

  @override
  String toString() {
    return '$runtimeType(${toStringInternal()})';
  }
}

class InternalNamedPattern extends InternalPattern {
  final String name;
  final InternalPattern pattern;

  @override
  List<InternalVariable> get internalDeclaredVariables =>
      pattern.internalDeclaredVariables;

  new({required this.name, required this.pattern, required int fileOffset}) {
    pattern.parent = this;
    this.fileOffset = fileOffset;
  }

  @override
  shared.PatternResult acceptInference(
    InferenceVisitorImpl visitor,
    SharedMatchContext context,
  ) {
    // InternalNamedPattern isn't a real pattern; this code should never be
    // reached.
    throw new StateError(
      '$runtimeType.acceptInference should never be reached',
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write(name);
    printer.write(': ');
    pattern.toTextInternal(printer);
  }

  @override
  String toString() {
    return '$runtimeType(${toStringInternal()})';
  }
}

/// An [InternalPattern] for `pattern!`.
class InternalNullAssertPattern extends InternalPattern {
  final InternalPattern pattern;

  new({required this.pattern, required int fileOffset}) {
    pattern.parent = this;
    this.fileOffset = fileOffset;
  }

  @override
  String? get variableName => pattern.variableName;

  @override
  List<InternalVariable> get internalDeclaredVariables =>
      pattern.internalDeclaredVariables;

  @override
  shared.PatternResult acceptInference(
    InferenceVisitorImpl visitor,
    SharedMatchContext context,
  ) {
    return visitor.visitInternalNullAssertPattern(this, context);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    pattern.toTextInternal(printer);
    printer.write('!');
  }

  @override
  String toString() {
    return "$runtimeType(${toStringInternal()})";
  }
}

/// An [InternalPattern] for `pattern?`.
class InternalNullCheckPattern extends InternalPattern {
  final InternalPattern pattern;

  new({required this.pattern, required int fileOffset}) {
    pattern.parent = this;
    this.fileOffset = fileOffset;
  }

  @override
  String? get variableName => pattern.variableName;

  @override
  List<InternalVariable> get internalDeclaredVariables =>
      pattern.internalDeclaredVariables;

  @override
  shared.PatternResult acceptInference(
    InferenceVisitorImpl visitor,
    SharedMatchContext context,
  ) {
    return visitor.visitInternalNullCheckPattern(this, context);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    pattern.toTextInternal(printer);
    printer.write('?');
  }

  @override
  String toString() {
    return "$runtimeType(${toStringInternal()})";
  }
}

class InternalObjectPattern extends InternalPattern {
  /// The type specified as part of the object pattern syntax.
  DartType requiredType;

  final List<InternalNamedPattern> fields;

  /// If the type name in the object pattern refers to a typedef, the typedef in
  /// question; otherwise `null`.
  final Typedef? typedef;

  /// Indicates whether the object pattern included explicit type arguments; if
  /// `true` this means that no further type inference needs to be performed.
  final bool hasExplicitTypeArguments;

  new({
    required this.requiredType,
    required this.fields,
    required this.typedef,
    required this.hasExplicitTypeArguments,
    required int fileOffset,
  }) {
    setParents(fields, this);
    this.fileOffset = fileOffset;
  }

  @override
  List<InternalVariable> get internalDeclaredVariables {
    return [
      for (InternalNamedPattern field in fields)
        ...field.internalDeclaredVariables,
    ];
  }

  @override
  shared.PatternResult acceptInference(
    InferenceVisitorImpl visitor,
    SharedMatchContext context,
  ) {
    return visitor.visitInternalObjectPattern(this, context);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.writeType(requiredType);
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
    return "$runtimeType(${toStringInternal()})";
  }
}

class InternalRecordPattern extends InternalPattern {
  final List<InternalPattern> patterns;

  @override
  List<InternalVariable> get internalDeclaredVariables => [
    for (InternalPattern pattern in patterns)
      ...pattern.internalDeclaredVariables,
  ];

  new({required this.patterns, required int fileOffset}) {
    setParents(patterns, this);
    this.fileOffset = fileOffset;
  }

  @override
  shared.PatternResult acceptInference(
    InferenceVisitorImpl visitor,
    SharedMatchContext context,
  ) {
    return visitor.visitInternalRecordPattern(this, context);
  }

  @override
  // Coverage-ignore(suite): Not run.
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
    return '$runtimeType(${toStringInternal()})';
  }
}

/// An [InternalPattern] for `operator expression` where `operator  is either
/// ==, !=, <, <=, >, or >=.
class InternalRelationalPattern extends InternalPattern {
  final RelationalPatternKind kind;
  final Expression expression;

  new({required this.kind, required this.expression, required int fileOffset}) {
    expression.parent = this;
    this.fileOffset = fileOffset;
  }

  @override
  List<InternalVariable> get internalDeclaredVariables => const [];

  @override
  shared.PatternResult acceptInference(
    InferenceVisitorImpl visitor,
    SharedMatchContext context,
  ) {
    return visitor.visitInternalRelationalPattern(this, context);
  }

  @override
  // Coverage-ignore(suite): Not run.
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
    return "$runtimeType(${toStringInternal()})";
  }
}

class InternalRestPattern extends InternalPattern {
  InternalPattern? subPattern;

  new({required this.subPattern, required int fileOffset}) {
    subPattern?.parent = this;
    this.fileOffset = fileOffset;
  }

  @override
  List<InternalVariable> get internalDeclaredVariables =>
      subPattern?.internalDeclaredVariables ?? const [];

  @override
  shared.PatternResult acceptInference(
    InferenceVisitorImpl visitor,
    SharedMatchContext context,
  ) {
    // InternalRestPattern isn't a real pattern; this code should never be
    // reached.
    throw new StateError(
      '$runtimeType.acceptInference should never be reached',
    );
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('...');
    if (subPattern != null) {
      subPattern!.toTextInternal(printer);
    }
  }

  @override
  String toString() {
    return "$runtimeType(${toStringInternal()})";
  }
}

class InternalVariablePattern extends InternalPattern {
  // TODO(johnniwinther): Should this be accessed through [variable] instead?
  final DartType? type;
  final InternalVariable variable;

  @override
  List<InternalVariable> get internalDeclaredVariables => [variable];

  new({required this.type, required this.variable, required int fileOffset}) {
    variable.parent = this;
    this.fileOffset = fileOffset;
  }

  @override
  String get variableName => variable.cosmeticName!;

  @override
  shared.PatternResult acceptInference(
    InferenceVisitorImpl visitor,
    SharedMatchContext context,
  ) {
    return visitor.visitInternalVariablePattern(this, context);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (type != null) {
      type!.toTextInternal(printer);
      printer.write(" ");
    } else {
      printer.write("var ");
    }
    printer.write(variable.cosmeticName!);
  }

  @override
  String toString() {
    return "$runtimeType(${toStringInternal()})";
  }
}

class InternalWildcardPattern extends InternalPattern {
  final DartType? type;

  new({required this.type, required int fileOffset}) {
    this.fileOffset = fileOffset;
  }
  @override
  List<InternalVariable> get internalDeclaredVariables => const [];

  @override
  shared.PatternResult acceptInference(
    InferenceVisitorImpl visitor,
    SharedMatchContext context,
  ) {
    return visitor.visitInternalWildcardPattern(this, context);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    if (type != null) {
      type!.toTextInternal(printer);
      printer.write(" ");
    }
    printer.write("_");
  }

  @override
  String toString() {
    return "$runtimeType(${toStringInternal()})";
  }
}

/// A [InternalPattern] with an optional guard [Expression].
class InternalPatternGuard extends TreeNode with InternalTreeNode {
  final InternalPattern pattern;
  final Expression? guard;

  new({required this.pattern, required this.guard, required int fileOffset}) {
    pattern.parent = this;
    guard?.parent = this;
    this.fileOffset = fileOffset;
  }

  @override
  // Coverage-ignore(suite): Not run.
  R accept<R>(TreeVisitor<R> v) {
    unsupported("${runtimeType}.accept on ${v.runtimeType}", -1, null);
  }

  @override
  // Coverage-ignore(suite): Not run.
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) {
    unsupported("${runtimeType}.accept on ${v.runtimeType}", -1, null);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    pattern.toTextInternal(printer);
    if (guard != null) {
      printer.write(' when ');
      printer.writeExpression(guard!);
    }
  }

  @override
  String toString() => '$runtimeType(${toStringInternal()})';
}

class InternalPatternSwitchCase extends InternalSwitchCase {
  final List<int> caseOffsets;
  final List<InternalPatternGuard> patternGuards;

  @override
  final Statement body;

  final bool isDefault;

  @override
  final List<Label>? labels;

  final List<InternalVariable> jointVariables;

  final List<int>? jointVariableFirstUseOffsets;

  new({
    required this.caseOffsets,
    required this.patternGuards,
    required this.body,
    required this.isDefault,
    required this.labels,
    required this.jointVariables,
    required this.jointVariableFirstUseOffsets,
    required int fileOffset,
  }) {
    setParents(patternGuards, this);
    setParents(jointVariables, this);
    body.parent = this;
    this.fileOffset = fileOffset;
  }

  int get caseHeadCount => patternGuards.length;

  @override
  // Coverage-ignore(suite): Not run.
  R accept<R>(TreeVisitor<R> v) {
    unsupported("${runtimeType}.accept on ${v.runtimeType}", -1, null);
  }

  @override
  // Coverage-ignore(suite): Not run.
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) {
    unsupported("${runtimeType}.accept on ${v.runtimeType}", -1, null);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    bool needsNewLine = false;
    if (labels != null) {
      for (Label label in labels!) {
        if (needsNewLine) {
          printer.newLine();
        }
        printer.write(label.name);
        printer.write(':');
        needsNewLine = true;
      }
    }
    for (InternalPatternGuard patternGuard in patternGuards) {
      if (needsNewLine) {
        printer.newLine();
      }
      printer.write('case ');
      patternGuard.toTextInternal(printer);
      printer.write(':');
      needsNewLine = true;
    }
    if (isDefault) {
      if (needsNewLine) {
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
    return "$runtimeType(${toStringInternal()})";
  }
}

class InternalPatternSwitchStatement extends InternalStatement
    implements InternalSwitchStatement {
  final Expression expression;

  @override
  final List<InternalPatternSwitchCase> cases;

  new({
    required this.expression,
    required this.cases,
    required int fileOffset,
  }) {
    expression.parent = this;
    setParents(cases, this);
    this.fileOffset = fileOffset;
  }

  @override
  StatementInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitInternalPatternSwitchStatement(this);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('switch (');
    printer.writeExpression(expression);
    printer.write(') {');
    printer.incIndentation();
    for (InternalPatternSwitchCase switchCase in cases) {
      printer.newLine();
      switchCase.toTextInternal(printer);
    }
    printer.decIndentation();
    printer.newLine();
    printer.write('}');
  }

  @override
  String toString() {
    return "$runtimeType(${toStringInternal()})";
  }
}

sealed class InternalSwitch implements TreeNode {}

sealed class InternalSwitchStatement
    implements InternalSwitch, InternalStatement {
  List<InternalSwitchCase> get cases;
}

class InternalSwitchExpressionCase extends TreeNode with InternalTreeNode {
  final InternalPatternGuard patternGuard;
  final Expression expression;

  new({
    required this.patternGuard,
    required this.expression,
    required int fileOffset,
  }) {
    patternGuard.parent = this;
    expression.parent = this;
    this.fileOffset = fileOffset;
  }

  @override
  // Coverage-ignore(suite): Not run.
  R accept<R>(TreeVisitor<R> v) {
    unsupported("${runtimeType}.accept on ${v.runtimeType}", -1, null);
  }

  @override
  // Coverage-ignore(suite): Not run.
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) {
    unsupported("${runtimeType}.accept on ${v.runtimeType}", -1, null);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('case ');
    patternGuard.toTextInternal(printer);
    printer.write(' => ');
    printer.writeExpression(expression);
  }

  @override
  String toString() {
    return '$runtimeType(${toStringInternal()})';
  }
}

class InternalSwitchExpression extends InternalExpression
    implements InternalSwitch {
  final Expression expression;
  final List<InternalSwitchExpressionCase> cases;

  new({
    required this.expression,
    required this.cases,
    required int fileOffset,
  }) {
    expression.parent = this;
    setParents(cases, this);
    this.fileOffset = fileOffset;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalSwitchExpression(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('switch (');
    printer.writeExpression(expression);
    printer.write(') {');
    String comma = ' ';
    for (InternalSwitchExpressionCase switchCase in cases) {
      printer.write(comma);
      switchCase.toTextInternal(printer);
      comma = ', ';
    }
    printer.write(' }');
  }

  @override
  String toString() => '$runtimeType(${toStringInternal()})';
}

class InternalPatternVariableDeclaration extends InternalStatement {
  final InternalPattern pattern;
  final Expression initializer;
  final bool isFinal;

  new({
    required this.pattern,
    required this.initializer,
    required this.isFinal,
    required int fileOffset,
  }) {
    pattern.parent = this;
    initializer.parent = this;
    this.fileOffset = fileOffset;
  }

  @override
  StatementInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitInternalPatternVariableDeclaration(this);
  }

  @override
  // Coverage-ignore(suite): Not run.
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
    return "$runtimeType(${toStringInternal()})";
  }
}

class InternalPatternAssignment extends InternalExpression {
  final InternalPattern pattern;
  final Expression expression;

  new({
    required this.pattern,
    required this.expression,
    required int fileOffset,
  }) {
    pattern.parent = this;
    expression.parent = this;
    this.fileOffset = fileOffset;
  }

  @override
  ExpressionInferenceResult acceptInference(
    InferenceVisitorImpl visitor,
    DartType typeContext,
  ) {
    return visitor.visitInternalPatternAssignment(this, typeContext);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    pattern.toTextInternal(printer);
    printer.write(' = ');
    printer.writeExpression(expression);
  }

  @override
  String toString() {
    return "$runtimeType(${toStringInternal()})";
  }
}

/// Statement for a if-case statements:
///
///     if (expression case pattern) then
///     if (expression case pattern) then else otherwise
///     if (expression case pattern when guard) then
///     if (expression case pattern when guard) then else otherwise
///
class InternalIfCaseStatement extends InternalStatement {
  final Expression expression;
  final InternalPatternGuard patternGuard;
  final Statement then;
  final Statement? otherwise;

  new({
    required this.expression,
    required this.patternGuard,
    required this.then,
    required this.otherwise,
    required int fileOffset,
  }) {
    expression.parent = this;
    patternGuard.parent = this;
    then.parent = this;
    otherwise?.parent = this;
    this.fileOffset = fileOffset;
  }

  @override
  StatementInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitInternalIfCaseStatement(this);
  }

  @override
  // Coverage-ignore(suite): Not run.
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
    return "$runtimeType(${toStringInternal()})";
  }
}

class InternalContinueSwitchStatement extends InternalStatement {
  late InternalSwitchCase target;

  new({required int fileOffset}) {
    this.fileOffset = fileOffset;
  }

  @override
  // Coverage-ignore(suite): Not run.
  void toTextInternal(AstPrinter printer) {
    printer.write('continue');
    if (target.labels != null) {
      printer.write(' ');
      printer.write(target.labels!.first.name);
    }
    printer.write(';');
  }

  @override
  String toString() {
    return "$runtimeType(${toStringInternal()})";
  }

  @override
  StatementInferenceResult acceptInference(InferenceVisitorImpl visitor) {
    return visitor.visitInternalContinueSwitchStatement(this);
  }
}

final InternalPattern dummyInternalPattern = new InternalConstantPattern(
  expression: dummyExpression,
  fileOffset: TreeNode.noOffset,
);

final InternalPatternGuard dummyInternalPatternGuard = new InternalPatternGuard(
  pattern: dummyInternalPattern,
  guard: null,
  fileOffset: TreeNode.noOffset,
);

final InternalSwitchExpressionCase dummyInternalSwitchExpressionCase =
    new InternalSwitchExpressionCase(
      patternGuard: dummyInternalPatternGuard,
      expression: dummyExpression,
      fileOffset: TreeNode.noOffset,
    );

final InternalSwitchCase dummyInternalSwitchCase =
    new InternalSwitchStatementCase(
      caseOffsets: [],
      expressions: [],
      expressionOffsets: [],
      body: dummyStatement,
      isDefault: false,
      labels: null,
      fileOffset: TreeNode.noOffset,
    );
