// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../../ast.dart';

// ------------------------------------------------------------------------
//                              STATEMENTS
// ------------------------------------------------------------------------

sealed class Statement extends TreeNode {
  @override
  R accept<R>(StatementVisitor<R> v);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg);

  @override
  String toText(AstTextStrategy strategy) {
    AstPrinter printer = new AstPrinter(strategy);
    printer.writeStatement(this);
    return printer.getText();
  }
}

abstract class AuxiliaryStatement extends Statement {
  @override
  R accept<R>(StatementVisitor<R> v) => v.visitAuxiliaryStatement(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitAuxiliaryStatement(this, arg);
}

class ExpressionStatement extends Statement {
  Expression expression;

  // TODO(johnniwinther): Fix this so set value is not lost. We include this
  //   getter so offset is consistent before and after serialization.
  //   ExpressionStatements are common so serializing the offset could
  //   increase serialized size.
  @override
  int get fileOffset => expression.fileOffset;

  ExpressionStatement(this.expression) {
    expression.parent = this;
  }

  @override
  R accept<R>(StatementVisitor<R> v) => v.visitExpressionStatement(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitExpressionStatement(this, arg);

  @override
  void visitChildren(Visitor v) {
    expression.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    expression = v.transform(expression);
    expression.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    expression = v.transform(expression);
    expression.parent = this;
  }

  @override
  String toString() {
    return "ExpressionStatement(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeExpression(expression);
    printer.write(';');
  }
}

class Block extends Statement {
  final List<Statement> statements;

  /// End offset in the source file it comes from. Valid values are from 0 and
  /// up, or -1 ([TreeNode.noOffset]) if the file end offset is not available
  /// (this is the default if none is specifically set).
  int fileEndOffset = TreeNode.noOffset;

  @override
  List<int>? get fileOffsetsIfMultiple => [fileOffset, fileEndOffset];

  Block(this.statements) {
    // Ensure statements is mutable.
    assert(checkListIsMutable(statements, dummyStatement));
    setParents(statements, this);
  }

  @override
  R accept<R>(StatementVisitor<R> v) => v.visitBlock(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) => v.visitBlock(this, arg);

  @override
  void visitChildren(Visitor v) {
    visitList(statements, v);
  }

  @override
  void transformChildren(Transformer v) {
    v.transformList(statements, this);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformStatementList(statements, this);
  }

  void addStatement(Statement node) {
    statements.add(node);
    node.parent = this;
  }

  @override
  String toString() {
    return "Block(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeBlock(statements);
  }
}

/// A block that is only executed when asserts are enabled.
///
/// Sometimes arbitrary statements must be guarded by whether asserts are
/// enabled.  For example, when a subexpression of an assert in async code is
/// linearized and named, it can produce such a block of statements.
class AssertBlock extends Statement {
  final List<Statement> statements;

  AssertBlock(this.statements) {
    // Ensure statements is mutable.
    assert(checkListIsMutable(statements, dummyStatement));
    setParents(statements, this);
  }

  @override
  R accept<R>(StatementVisitor<R> v) => v.visitAssertBlock(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitAssertBlock(this, arg);

  @override
  void transformChildren(Transformer v) {
    v.transformList(statements, this);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformStatementList(statements, this);
  }

  @override
  void visitChildren(Visitor v) {
    visitList(statements, v);
  }

  @override
  String toString() {
    return "AssertBlock(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('assert ');
    printer.writeBlock(statements);
  }
}

class EmptyStatement extends Statement {
  @override
  R accept<R>(StatementVisitor<R> v) => v.visitEmptyStatement(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitEmptyStatement(this, arg);

  @override
  void visitChildren(Visitor v) {}

  @override
  void transformChildren(Transformer v) {}

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {}

  @override
  String toString() {
    return "EmptyStatement(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write(';');
  }
}

class AssertStatement extends Statement {
  Expression condition;
  Expression? message; // May be null.

  /// Character offset in the source where the assertion condition begins.
  ///
  /// This is an index into [Source.text].
  int conditionStartOffset;

  /// Character offset in the source where the assertion condition ends.
  ///
  /// This is an index into [Source.text].
  int conditionEndOffset;

  @override
  List<int>? get fileOffsetsIfMultiple =>
      [fileOffset, conditionStartOffset, conditionEndOffset];

  AssertStatement(this.condition,
      {this.message,
      required this.conditionStartOffset,
      required this.conditionEndOffset}) {
    condition.parent = this;
    message?.parent = this;
  }

  @override
  R accept<R>(StatementVisitor<R> v) => v.visitAssertStatement(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitAssertStatement(this, arg);

  @override
  void visitChildren(Visitor v) {
    condition.accept(v);
    message?.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    condition = v.transform(condition);
    condition.parent = this;
    if (message != null) {
      message = v.transform(message!);
      message?.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    condition = v.transform(condition);
    condition.parent = this;
    if (message != null) {
      message = v.transformOrRemoveExpression(message!);
      message?.parent = this;
    }
  }

  @override
  String toString() {
    return "AssertStatement(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('assert(');
    printer.writeExpression(condition);
    if (message != null) {
      printer.write(', ');
      printer.writeExpression(message!);
    }
    printer.write(');');
  }
}

/// A target of a [Break] statement.
///
/// The label itself has no name; breaks reference the statement directly.
///
/// The frontend does not generate labeled statements without uses.
class LabeledStatement extends Statement {
  late Statement body;

  LabeledStatement(Statement? body) {
    if (body != null) {
      this.body = body..parent = this;
    }
  }

  @override
  R accept<R>(StatementVisitor<R> v) => v.visitLabeledStatement(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitLabeledStatement(this, arg);

  @override
  void visitChildren(Visitor v) {
    body.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    body = v.transform(body);
    body.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    body = v.transform(body);
    body.parent = this;
  }

  @override
  String toString() {
    return "LabeledStatement(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write(printer.getLabelName(this));
    printer.write(':');
    printer.newLine();
    printer.writeStatement(body);
  }
}

/// Breaks out of an enclosing [LabeledStatement].
///
/// Both `break` and `continue` statements are translated into this node.
///
/// Example `break` desugaring:
///
///     while (x) {
///       if (y) break;
///       BODY
///     }
///
///     ==>
///
///     L: while (x) {
///       if (y) break L;
///       BODY
///     }
///
/// Example `continue` desugaring:
///
///     while (x) {
///       if (y) continue;
///       BODY
///     }
///
///     ==>
///
///     while (x) {
///       L: {
///         if (y) break L;
///         BODY
///       }
///     }
///
/// Note: Compiler-generated [LabeledStatement]s for [WhileStatement]s and
/// [ForStatement]s are only generated when needed. If there isn't a `break` or
/// `continue` in a loop, the kernel for the loop won't have a generated
/// [LabeledStatement].
class BreakStatement extends Statement {
  LabeledStatement target;

  BreakStatement(this.target);

  @override
  R accept<R>(StatementVisitor<R> v) => v.visitBreakStatement(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitBreakStatement(this, arg);

  @override
  void visitChildren(Visitor v) {}

  @override
  void transformChildren(Transformer v) {}

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {}

  @override
  String toString() {
    return "BreakStatement(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('break ');
    printer.write(printer.getLabelName(target));
    printer.write(';');
  }
}

/// Common interface for loop statements.
abstract interface class LoopStatement implements Statement {
  abstract Statement body;
}

class WhileStatement extends Statement implements LoopStatement {
  Expression condition;

  @override
  Statement body;

  WhileStatement(this.condition, this.body) {
    condition.parent = this;
    body.parent = this;
  }

  @override
  R accept<R>(StatementVisitor<R> v) => v.visitWhileStatement(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitWhileStatement(this, arg);

  @override
  void visitChildren(Visitor v) {
    condition.accept(v);
    body.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    condition = v.transform(condition);
    condition.parent = this;
    body = v.transform(body);
    body.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    condition = v.transform(condition);
    condition.parent = this;
    body = v.transform(body);
    body.parent = this;
  }

  @override
  String toString() {
    return "WhileStatement(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('while (');
    printer.writeExpression(condition);
    printer.write(') ');
    printer.writeStatement(body);
  }
}

class DoStatement extends Statement implements LoopStatement {
  @override
  Statement body;

  Expression condition;

  DoStatement(this.body, this.condition) {
    body.parent = this;
    condition.parent = this;
  }

  @override
  R accept<R>(StatementVisitor<R> v) => v.visitDoStatement(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitDoStatement(this, arg);

  @override
  void visitChildren(Visitor v) {
    body.accept(v);
    condition.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    body = v.transform(body);
    body.parent = this;
    condition = v.transform(condition);
    condition.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    body = v.transform(body);
    body.parent = this;
    condition = v.transform(condition);
    condition.parent = this;
  }

  @override
  String toString() {
    return "DoStatement(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('do ');
    printer.writeStatement(body);
    printer.write(' while (');
    printer.writeExpression(condition);
    printer.write(');');
  }
}

class ForStatement extends Statement implements LoopStatement {
  final List<VariableDeclaration> variables; // May be empty, but not null.
  Expression? condition; // May be null.
  final List<Expression> updates; // May be empty, but not null.

  @override
  Statement body;

  ForStatement(this.variables, this.condition, this.updates, this.body) {
    setParents(variables, this);
    condition?.parent = this;
    setParents(updates, this);
    body.parent = this;
  }

  @override
  R accept<R>(StatementVisitor<R> v) => v.visitForStatement(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitForStatement(this, arg);

  @override
  void visitChildren(Visitor v) {
    visitList(variables, v);
    condition?.accept(v);
    visitList(updates, v);
    body.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    v.transformList(variables, this);
    if (condition != null) {
      condition = v.transform(condition!);
      condition?.parent = this;
    }
    v.transformList(updates, this);
    body = v.transform(body);
    body.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformVariableDeclarationList(variables, this);
    if (condition != null) {
      condition = v.transformOrRemoveExpression(condition!);
      condition?.parent = this;
    }
    v.transformExpressionList(updates, this);
    body = v.transform(body);
    body.parent = this;
  }

  @override
  String toString() {
    return "ForStatement(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
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
    printer.writeStatement(body);
  }
}

class ForInStatement extends Statement implements LoopStatement {
  /// Offset in the source file it comes from.
  ///
  /// Valid values are from 0 and up, or -1 ([TreeNode.noOffset]) if the file
  /// offset is not available (this is the default if none is specifically set).
  int bodyOffset = TreeNode.noOffset;

  @override
  List<int>? get fileOffsetsIfMultiple => [fileOffset, bodyOffset];

  VariableDeclaration variable; // Has no initializer.
  Expression iterable;

  @override
  Statement body;

  bool isAsync; // True if this is an 'await for' loop.

  ForInStatement(this.variable, this.iterable, this.body,
      {this.isAsync = false}) {
    variable.parent = this;
    iterable.parent = this;
    body.parent = this;
  }

  @override
  R accept<R>(StatementVisitor<R> v) => v.visitForInStatement(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitForInStatement(this, arg);

  @override
  void visitChildren(Visitor v) {
    variable.accept(v);
    iterable.accept(v);
    body.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    variable = v.transform(variable);
    variable.parent = this;
    iterable = v.transform(iterable);
    iterable.parent = this;
    body = v.transform(body);
    body.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    variable = v.transform(variable);
    variable.parent = this;
    iterable = v.transform(iterable);
    iterable.parent = this;
    body = v.transform(body);
    body.parent = this;
  }

  /// Returns the type of the iterator in this for-in statement.
  ///
  /// This calls `StaticTypeContext.getForInIteratorType` which calls
  /// [getStaticTypeInternal] to compute the type of not already cached in
  /// [context].
  DartType getIteratorType(StaticTypeContext context) =>
      context.getForInIteratorType(this);

  /// Computes the type of the iterator in this for-in statement.
  ///
  /// This is called by `StaticTypeContext.getForInIteratorType` if the iterator
  /// type of this for-in statement is not already cached in [context].
  DartType getIteratorTypeInternal(StaticTypeContext context) {
    DartType? iteratorType;
    if (isAsync) {
      InterfaceType streamType = iterable.getStaticTypeAsInstanceOf(
          context.typeEnvironment.coreTypes.streamClass, context);
      iteratorType = new InterfaceType(
          context.typeEnvironment.coreTypes.streamIteratorClass,
          context.nonNullable,
          streamType.typeArguments);
    } else {
      InterfaceType iterableType = iterable.getStaticTypeAsInstanceOf(
          context.typeEnvironment.coreTypes.iterableClass, context);
      Member? member = context.typeEnvironment.hierarchy
          .getInterfaceMember(iterableType.classNode, new Name('iterator'));
      if (member != null) {
        iteratorType = Substitution.fromInterfaceType(iterableType)
            .substituteType(member.getterType);
      }
    }
    return iteratorType ?? const DynamicType();
  }

  /// Returns the type of the element in this for-in statement.
  ///
  /// This calls `StaticTypeContext.getForInElementType` which calls
  /// [getStaticTypeInternal] to compute the type of not already cached in
  /// [context].
  DartType getElementType(StaticTypeContext context) =>
      context.getForInElementType(this);

  /// Computes the type of the element in this for-in statement.
  ///
  /// This is called by `StaticTypeContext.getForInElementType` if the element
  /// type of this for-in statement is not already cached in [context].
  DartType getElementTypeInternal(StaticTypeContext context) {
    DartType iterableType =
        iterable.getStaticType(context).nonTypeVariableBound;
    // TODO(johnniwinther): Update this to use the type of
    //  `iterable.iterator.current` if inference is updated accordingly.
    while (iterableType is TypeParameterType) {
      TypeParameterType typeParameterType = iterableType;
      iterableType = typeParameterType.bound;
    }
    if (iterableType is NeverType) {
      return iterableType;
    }
    if (iterableType is InvalidType) {
      return iterableType;
    }
    if (iterableType is! TypeDeclarationType) {
      // TODO(johnniwinther): Change this to an assert once the CFE correctly
      // inserts casts for all invalid iterable types.
      return const InvalidType();
    }
    if (isAsync) {
      List<DartType> typeArguments = context.typeEnvironment
          .getTypeArgumentsAsInstanceOf(
              iterableType, context.typeEnvironment.coreTypes.streamClass)!;
      return typeArguments.single;
    } else {
      List<DartType> typeArguments = context.typeEnvironment
          .getTypeArgumentsAsInstanceOf(
              iterableType, context.typeEnvironment.coreTypes.iterableClass)!;
      return typeArguments.single;
    }
  }

  @override
  String toString() {
    return "ForInStatement(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('for (');
    printer.writeVariableDeclaration(variable);

    printer.write(' in ');
    printer.writeExpression(iterable);
    printer.write(') ');
    printer.writeStatement(body);
  }
}

/// Statement of form `switch (e) { case x: ... }`.
///
/// Adjacent case clauses have been merged into a single [SwitchCase]. A runtime
/// exception must be thrown if one [SwitchCase] falls through to another case.
class SwitchStatement extends Statement {
  Expression expression;
  final List<SwitchCase> cases;

  /// For switches without a default clause, whether all possible values are
  /// covered by a switch case.  For switches with a default clause, always
  /// `false`.
  /// Initialized during type inference.
  bool isExplicitlyExhaustive;

  /// The static type of the [expression]
  ///
  /// This is set during inference.
  DartType? expressionTypeInternal;

  SwitchStatement(this.expression, this.cases,
      {this.isExplicitlyExhaustive = false}) {
    expression.parent = this;
    setParents(cases, this);
  }

  /// The static type of the [expression]
  ///
  /// This is set during inference.
  DartType get expressionType {
    assert(expressionTypeInternal != null,
        "Expression type hasn't been computed for $this.");
    return expressionTypeInternal!;
  }

  void set expressionType(DartType value) {
    expressionTypeInternal = value;
  }

  /// Whether the switch has a `default` case.
  bool get hasDefault {
    assert(cases.every((c) => c == cases.last || !c.isDefault));
    return cases.isNotEmpty && cases.last.isDefault;
  }

  /// Whether the switch is guaranteed to hit one of the cases (including the
  /// default case, if present).
  bool get isExhaustive => isExplicitlyExhaustive || hasDefault;

  @override
  R accept<R>(StatementVisitor<R> v) => v.visitSwitchStatement(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitSwitchStatement(this, arg);

  @override
  void visitChildren(Visitor v) {
    expression.accept(v);
    visitList(cases, v);
    expressionTypeInternal?.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    expression = v.transform(expression);
    expression.parent = this;
    v.transformList(cases, this);
    if (expressionTypeInternal != null) {
      expressionTypeInternal = v.visitDartType(expressionTypeInternal!);
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    expression = v.transform(expression);
    expression.parent = this;
    v.transformSwitchCaseList(cases, this);
    if (expressionTypeInternal != null) {
      expressionTypeInternal =
          v.visitDartType(expressionTypeInternal!, cannotRemoveSentinel);
    }
  }

  @override
  String toString() {
    return "SwitchStatement(${toStringInternal()})";
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
}

/// A group of `case` clauses and/or a `default` clause.
///
/// This is a potential target of [ContinueSwitchStatement].
class SwitchCase extends TreeNode {
  final List<Expression> expressions;
  final List<int> expressionOffsets;
  late Statement body;
  bool isDefault;

  SwitchCase(this.expressions, this.expressionOffsets, Statement? body,
      {this.isDefault = false}) {
    setParents(expressions, this);
    if (body != null) {
      this.body = body..parent = this;
    }
  }

  SwitchCase.defaultCase(Statement? body)
      : isDefault = true,
        expressions = <Expression>[],
        expressionOffsets = <int>[] {
    if (body != null) {
      this.body = body..parent = this;
    }
  }

  @override
  List<int>? get fileOffsetsIfMultiple => [fileOffset, ...expressionOffsets];

  @override
  R accept<R>(TreeVisitor<R> v) => v.visitSwitchCase(this);

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) => v.visitSwitchCase(this, arg);

  @override
  void visitChildren(Visitor v) {
    visitList(expressions, v);
    body.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    v.transformList(expressions, this);
    body = v.transform(body);
    body.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformExpressionList(expressions, this);
    body = v.transform(body);
    body.parent = this;
  }

  @override
  String toString() {
    return "SwitchCase(${toStringInternal()})";
  }

  @override
  String toText(AstTextStrategy strategy) {
    AstPrinter printer = new AstPrinter(strategy);
    toTextInternal(printer);
    return printer.getText();
  }

  @override
  void toTextInternal(AstPrinter printer) {
    for (int index = 0; index < expressions.length; index++) {
      if (index > 0) {
        printer.newLine();
      }
      printer.write('case ');
      printer.writeExpression(expressions[index]);
      printer.write(':');
    }
    if (isDefault) {
      if (expressions.isNotEmpty) {
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
}

/// Jump to a case in an enclosing switch.
class ContinueSwitchStatement extends Statement {
  SwitchCase target;

  ContinueSwitchStatement(this.target);

  @override
  R accept<R>(StatementVisitor<R> v) => v.visitContinueSwitchStatement(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitContinueSwitchStatement(this, arg);

  @override
  void visitChildren(Visitor v) {}

  @override
  void transformChildren(Transformer v) {}

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {}

  @override
  String toString() {
    return "ContinueSwitchStatement(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('continue ');
    printer.write(printer.getSwitchCaseName(target));
    printer.write(';');
  }
}

class IfStatement extends Statement {
  Expression condition;
  Statement then;
  Statement? otherwise;

  IfStatement(this.condition, this.then, this.otherwise) {
    condition.parent = this;
    then.parent = this;
    otherwise?.parent = this;
  }

  @override
  R accept<R>(StatementVisitor<R> v) => v.visitIfStatement(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitIfStatement(this, arg);

  @override
  void visitChildren(Visitor v) {
    condition.accept(v);
    then.accept(v);
    otherwise?.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    condition = v.transform(condition);
    condition.parent = this;
    then = v.transform(then);
    then.parent = this;
    if (otherwise != null) {
      otherwise = v.transform(otherwise!);
      otherwise?.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    condition = v.transform(condition);
    condition.parent = this;
    then = v.transform(then);
    then.parent = this;
    if (otherwise != null) {
      otherwise = v.transformOrRemoveStatement(otherwise!);
      otherwise?.parent = this;
    }
  }

  @override
  String toString() {
    return "IfStatement(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('if (');
    printer.writeExpression(condition);
    printer.write(') ');
    printer.writeStatement(then);
    if (otherwise != null) {
      printer.write(' else ');
      printer.writeStatement(otherwise!);
    }
  }
}

class ReturnStatement extends Statement {
  Expression? expression; // May be null.

  ReturnStatement([this.expression]) {
    expression?.parent = this;
  }

  @override
  R accept<R>(StatementVisitor<R> v) => v.visitReturnStatement(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitReturnStatement(this, arg);

  @override
  void visitChildren(Visitor v) {
    expression?.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    if (expression != null) {
      expression = v.transform(expression!);
      expression?.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    if (expression != null) {
      expression = v.transformOrRemoveExpression(expression!);
      expression?.parent = this;
    }
  }

  @override
  String toString() {
    return "ReturnStatement(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('return');
    if (expression != null) {
      printer.write(' ');
      printer.writeExpression(expression!);
    }
    printer.write(';');
  }
}

class TryCatch extends Statement {
  Statement body;
  List<Catch> catches;
  bool isSynthetic;

  TryCatch(this.body, this.catches, {this.isSynthetic = false}) {
    body.parent = this;
    setParents(catches, this);
  }

  @override
  R accept<R>(StatementVisitor<R> v) => v.visitTryCatch(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitTryCatch(this, arg);

  @override
  void visitChildren(Visitor v) {
    body.accept(v);
    visitList(catches, v);
  }

  @override
  void transformChildren(Transformer v) {
    body = v.transform(body);
    body.parent = this;
    v.transformList(catches, this);
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    body = v.transform(body);
    body.parent = this;
    v.transformCatchList(catches, this);
  }

  @override
  String toString() {
    return "TryCatch(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('try ');
    printer.writeStatement(body);
    for (Catch catchClause in catches) {
      printer.write(' ');
      printer.writeCatch(catchClause);
    }
  }
}

class Catch extends TreeNode {
  DartType guard; // Not null, defaults to dynamic.
  VariableDeclaration? exception;
  VariableDeclaration? stackTrace;
  Statement body;

  Catch(this.exception, this.body,
      {this.guard = const DynamicType(), this.stackTrace}) {
    exception?.parent = this;
    stackTrace?.parent = this;
    body.parent = this;
  }

  @override
  R accept<R>(TreeVisitor<R> v) => v.visitCatch(this);

  @override
  R accept1<R, A>(TreeVisitor1<R, A> v, A arg) => v.visitCatch(this, arg);

  @override
  void visitChildren(Visitor v) {
    guard.accept(v);
    exception?.accept(v);
    stackTrace?.accept(v);
    body.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    guard = v.visitDartType(guard);
    if (exception != null) {
      exception = v.transform(exception!);
      exception?.parent = this;
    }
    if (stackTrace != null) {
      stackTrace = v.transform(stackTrace!);
      stackTrace?.parent = this;
    }
    body = v.transform(body);
    body.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    guard = v.visitDartType(guard, cannotRemoveSentinel);
    if (exception != null) {
      exception = v.transformOrRemoveVariableDeclaration(exception!);
      exception?.parent = this;
    }
    if (stackTrace != null) {
      stackTrace = v.transformOrRemoveVariableDeclaration(stackTrace!);
      stackTrace?.parent = this;
    }
    body = v.transform(body);
    body.parent = this;
  }

  @override
  String toString() {
    return "Catch(${toStringInternal()})";
  }

  @override
  String toText(AstTextStrategy strategy) {
    AstPrinter printer = new AstPrinter(strategy);
    toTextInternal(printer);
    return printer.getText();
  }

  @override
  void toTextInternal(AstPrinter printer) {
    bool isImplicitType(DartType type) {
      if (type is DynamicType) {
        return true;
      }
      if (type is InterfaceType &&
          type.classReference.node != null &&
          type.classNode.name == 'Object') {
        Uri uri = type.classNode.enclosingLibrary.importUri;
        return uri.isScheme('dart') &&
            uri.path == 'core' &&
            type.nullability == Nullability.nonNullable;
      }
      return false;
    }

    if (exception != null) {
      if (!isImplicitType(guard)) {
        printer.write('on ');
        printer.writeType(guard);
        printer.write(' ');
      }
      printer.write('catch (');
      printer.writeVariableDeclaration(exception!,
          includeModifiersAndType: false);
      if (stackTrace != null) {
        printer.write(', ');
        printer.writeVariableDeclaration(stackTrace!,
            includeModifiersAndType: false);
      }
      printer.write(') ');
    } else {
      printer.write('on ');
      printer.writeType(guard);
      printer.write(' ');
    }
    printer.writeStatement(body);
  }
}

class TryFinally extends Statement {
  Statement body;
  Statement finalizer;

  TryFinally(this.body, this.finalizer) {
    body.parent = this;
    finalizer.parent = this;
  }

  @override
  R accept<R>(StatementVisitor<R> v) => v.visitTryFinally(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitTryFinally(this, arg);

  @override
  void visitChildren(Visitor v) {
    body.accept(v);
    finalizer.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    body = v.transform(body);
    body.parent = this;
    finalizer = v.transform(finalizer);
    finalizer.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    body = v.transform(body);
    body.parent = this;
    finalizer = v.transform(finalizer);
    finalizer.parent = this;
  }

  @override
  String toString() {
    return "TryFinally(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    if (body is! TryCatch) {
      // This is a `try {} catch (e) {} finally {}`. Avoid repeating `try`.
      printer.write('try ');
    }
    printer.writeStatement(body);
    printer.write(' finally ');
    printer.writeStatement(finalizer);
  }
}

/// Statement of form `yield x` or `yield* x`.
class YieldStatement extends Statement {
  Expression expression;
  int flags = 0;

  YieldStatement(this.expression, {bool isYieldStar = false}) {
    expression.parent = this;
    this.isYieldStar = isYieldStar;
  }

  static const int FlagYieldStar = 1 << 0;

  bool get isYieldStar => flags & FlagYieldStar != 0;

  void set isYieldStar(bool value) {
    flags = value ? (flags | FlagYieldStar) : (flags & ~FlagYieldStar);
  }

  @override
  R accept<R>(StatementVisitor<R> v) => v.visitYieldStatement(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitYieldStatement(this, arg);

  @override
  void visitChildren(Visitor v) {
    expression.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    expression = v.transform(expression);
    expression.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    expression = v.transform(expression);
    expression.parent = this;
  }

  @override
  String toString() {
    return "YieldStatement(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.write('yield');
    if (isYieldStar) {
      printer.write('*');
    }
    printer.write(' ');
    printer.writeExpression(expression);
    printer.write(';');
  }
}

/// Declaration of a local variable.
///
/// This may occur as a statement, but is also used in several non-statement
/// contexts, such as in [ForStatement], [Catch], and [FunctionNode].
///
/// When this occurs as a statement, it must be a direct child of a [Block].
//
// DESIGN TODO: Should we remove the 'final' modifier from variables?
class VariableDeclaration extends Statement implements Annotatable {
  /// Offset of the equals sign in the source file it comes from.
  ///
  /// Valid values are from 0 and up, or -1 ([TreeNode.noOffset])
  /// if the equals sign offset is not available (e.g. if not initialized)
  /// (this is the default if none is specifically set).
  int fileEqualsOffset = TreeNode.noOffset;

  @override
  List<int>? get fileOffsetsIfMultiple => [fileOffset, fileEqualsOffset];

  /// List of metadata annotations on the variable declaration.
  ///
  /// This defaults to an immutable empty list. Use [addAnnotation] to add
  /// annotations if needed.
  @override
  List<Expression> annotations = const <Expression>[];

  /// The name of the variable or parameter as provided in the source code.
  ///
  /// If this variable is synthesized, for instance the variable of a [Let]
  /// expression, the name can be `null`.
  String? _name;
  int flags = 0;
  DartType type; // Not null, defaults to dynamic.

  /// Offset of the declaration, set and used when writing the binary.
  int binaryOffsetNoTag = -1;

  /// For locals, this is the initial value.
  /// For parameters, this is the default value.
  ///
  /// Should be null in other cases.
  Expression? initializer; // May be null.

  VariableDeclaration(this._name,
      {this.initializer,
      this.type = const DynamicType(),
      int flags = -1,
      bool isFinal = false,
      bool isConst = false,
      bool isInitializingFormal = false,
      bool isCovariantByDeclaration = false,
      bool isLate = false,
      bool isRequired = false,
      bool isLowered = false,
      bool isSynthesized = false,
      bool isHoisted = false,
      bool hasDeclaredInitializer = false,
      bool isWildcard = false}) {
    initializer?.parent = this;
    if (flags != -1) {
      this.flags = flags;
    } else {
      this.isFinal = isFinal;
      this.isConst = isConst;
      this.isInitializingFormal = isInitializingFormal;
      this.isCovariantByDeclaration = isCovariantByDeclaration;
      this.isLate = isLate;
      this.isRequired = isRequired;
      this.isLowered = isLowered;
      this.hasDeclaredInitializer = hasDeclaredInitializer;
      this.isSynthesized = isSynthesized;
      this.isHoisted = isHoisted;
      this.isWildcard = isWildcard;
    }
    assert(_name != null || this.isSynthesized,
        "Only synthesized variables can have no name.");
  }

  /// Creates a synthetic variable with the given expression as initializer.
  VariableDeclaration.forValue(this.initializer,
      {bool isFinal = true,
      bool isConst = false,
      bool isInitializingFormal = false,
      bool isLate = false,
      bool isRequired = false,
      bool isLowered = false,
      this.type = const DynamicType()}) {
    initializer?.parent = this;
    this.isFinal = isFinal;
    this.isConst = isConst;
    this.isInitializingFormal = isInitializingFormal;
    this.isLate = isLate;
    this.isRequired = isRequired;
    this.isLowered = isLowered;
    this.hasDeclaredInitializer = true;
    this.isSynthesized = true;
  }

  /// The name of the variable as provided in the source code.
  ///
  /// The name of a variable can only be omitted if the variable is synthesized.
  /// Otherwise, its name is as provided in the source code.
  String? get name => _name;

  void set name(String? value) {
    assert(value != null || isSynthesized,
        "Only synthesized variables can have no name.");
    _name = value;
  }

  static const int FlagFinal = 1 << 0; // Must match serialized bit positions.
  static const int FlagConst = 1 << 1;
  static const int FlagHasDeclaredInitializer = 1 << 2;
  static const int FlagInitializingFormal = 1 << 3;
  static const int FlagCovariantByClass = 1 << 4;
  static const int FlagLate = 1 << 5;
  static const int FlagRequired = 1 << 6;
  static const int FlagCovariantByDeclaration = 1 << 7;
  static const int FlagLowered = 1 << 8;
  static const int FlagSynthesized = 1 << 9;
  static const int FlagHoisted = 1 << 10;
  static const int FlagWildcard = 1 << 11;

  bool get isFinal => flags & FlagFinal != 0;
  bool get isConst => flags & FlagConst != 0;

  /// Whether the parameter is declared with the `covariant` keyword.
  bool get isCovariantByDeclaration => flags & FlagCovariantByDeclaration != 0;

  /// Whether the variable is declared as an initializing formal parameter of
  /// a constructor.
  @informative
  bool get isInitializingFormal => flags & FlagInitializingFormal != 0;

  /// If this [VariableDeclaration] is a parameter of a method, indicates
  /// whether the method implementation needs to contain a runtime type check to
  /// deal with generic covariance.
  ///
  /// When `true`, runtime checks may need to be performed.
  bool get isCovariantByClass => flags & FlagCovariantByClass != 0;

  /// Whether the variable is declared with the `late` keyword.
  ///
  /// The `late` modifier is only supported on local variables and not on
  /// parameters.
  bool get isLate => flags & FlagLate != 0;

  /// Whether the parameter is declared with the `required` keyword.
  ///
  /// The `required` modifier is only supported on named parameters and not on
  /// positional parameters and local variables.
  bool get isRequired => flags & FlagRequired != 0;

  /// Whether the variable is part of a lowering.
  ///
  /// If a variable is part of a lowering its name may be synthesized so that it
  /// doesn't reflect the name used in the source code and might not have a
  /// one-to-one correspondence with the variable in the source.
  ///
  /// Lowering is used for instance of encoding of 'this' in extension instance
  /// members and encoding of late locals.
  bool get isLowered => flags & FlagLowered != 0;

  /// Whether this variable is synthesized, that is, it is _not_ declared in
  /// the source code.
  ///
  /// The name of a variable can only be omitted if the variable is synthesized.
  /// Otherwise, its name is as provided in the source code.
  bool get isSynthesized => flags & FlagSynthesized != 0;

  /// Whether the declaration of this variable is has been moved to an earlier
  /// source location.
  ///
  /// This is for instance the case for variables declared in a pattern, where
  /// the lowering requires the variable to be declared before the expression
  /// that performs that matching in which its initialization occurs.
  bool get isHoisted => flags & FlagHoisted != 0;

  /// Whether the variable has an initializer, either by declaration or copied
  /// from an original declaration.
  ///
  /// Note that the variable might have a synthesized initializer expression,
  /// so `hasDeclaredInitializer == false` doesn't imply `initializer == null`.
  /// For instance, for duplicate variable names, an invalid expression is set
  /// as the initializer of the second variable.
  bool get hasDeclaredInitializer => flags & FlagHasDeclaredInitializer != 0;

  /// Whether this variable is a wildcard variable.
  ///
  /// Wildcard variables have the name `_`.
  bool get isWildcard => flags & FlagWildcard != 0;

  /// Whether the variable is assignable.
  ///
  /// This is `true` if the variable is neither constant nor final, or if it
  /// is late final without an initializer.
  bool get isAssignable {
    if (isConst) return false;
    if (isFinal) {
      if (isLate) return initializer == null;
      return false;
    }
    return true;
  }

  void set isFinal(bool value) {
    flags = value ? (flags | FlagFinal) : (flags & ~FlagFinal);
  }

  void set isConst(bool value) {
    flags = value ? (flags | FlagConst) : (flags & ~FlagConst);
  }

  void set isCovariantByDeclaration(bool value) {
    flags = value
        ? (flags | FlagCovariantByDeclaration)
        : (flags & ~FlagCovariantByDeclaration);
  }

  @informative
  void set isInitializingFormal(bool value) {
    flags = value
        ? (flags | FlagInitializingFormal)
        : (flags & ~FlagInitializingFormal);
  }

  void set isCovariantByClass(bool value) {
    flags = value
        ? (flags | FlagCovariantByClass)
        : (flags & ~FlagCovariantByClass);
  }

  void set isLate(bool value) {
    flags = value ? (flags | FlagLate) : (flags & ~FlagLate);
  }

  void set isRequired(bool value) {
    flags = value ? (flags | FlagRequired) : (flags & ~FlagRequired);
  }

  void set isLowered(bool value) {
    flags = value ? (flags | FlagLowered) : (flags & ~FlagLowered);
  }

  void set isSynthesized(bool value) {
    assert(
        value || _name != null, "Only synthesized variables can have no name.");
    flags = value ? (flags | FlagSynthesized) : (flags & ~FlagSynthesized);
  }

  void set isHoisted(bool value) {
    flags = value ? (flags | FlagHoisted) : (flags & ~FlagHoisted);
  }

  void set hasDeclaredInitializer(bool value) {
    flags = value
        ? (flags | FlagHasDeclaredInitializer)
        : (flags & ~FlagHasDeclaredInitializer);
  }

  void set isWildcard(bool value) {
    // TODO(kallentu): Change the name to be unique with other wildcard
    // variables.
    flags = value ? (flags | FlagWildcard) : (flags & ~FlagWildcard);
  }

  void clearAnnotations() {
    annotations = const <Expression>[];
  }

  @override
  void addAnnotation(Expression annotation) {
    if (annotations.isEmpty) {
      annotations = <Expression>[];
    }
    annotations.add(annotation..parent = this);
  }

  @override
  R accept<R>(StatementVisitor<R> v) => v.visitVariableDeclaration(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitVariableDeclaration(this, arg);

  @override
  void visitChildren(Visitor v) {
    visitList(annotations, v);
    type.accept(v);
    initializer?.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    v.transformList(annotations, this);
    type = v.visitDartType(type);
    if (initializer != null) {
      initializer = v.transform(initializer!);
      initializer?.parent = this;
    }
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    v.transformExpressionList(annotations, this);
    type = v.visitDartType(type, cannotRemoveSentinel);
    if (initializer != null) {
      initializer = v.transformOrRemoveExpression(initializer!);
      initializer?.parent = this;
    }
  }

  /// Returns a possibly synthesized name for this variable, consistent with
  /// the names used across all [toString] calls.
  @override
  String toString() {
    return "VariableDeclaration(${toStringInternal()})";
  }

  @override
  String toStringInternal() {
    AstPrinter printer = new AstPrinter(defaultAstTextStrategy);
    printer.writeVariableDeclaration(this, includeInitializer: false);
    return printer.getText();
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeVariableDeclaration(this);
    printer.write(';');
  }
}

/// Declaration a local function.
///
/// The body of the function may use [variable] as its self-reference.
class FunctionDeclaration extends Statement implements LocalFunction {
  VariableDeclaration variable; // Is final and has no initializer.

  @override
  FunctionNode function;

  FunctionDeclaration(this.variable, this.function) {
    variable.parent = this;
    function.parent = this;
  }

  @override
  List<TypeParameter> get typeParameters => function.typeParameters;

  @override
  R accept<R>(StatementVisitor<R> v) => v.visitFunctionDeclaration(this);

  @override
  R accept1<R, A>(StatementVisitor1<R, A> v, A arg) =>
      v.visitFunctionDeclaration(this, arg);

  @override
  void visitChildren(Visitor v) {
    variable.accept(v);
    function.accept(v);
  }

  @override
  void transformChildren(Transformer v) {
    variable = v.transform(variable);
    variable.parent = this;
    function = v.transform(function);
    function.parent = this;
  }

  @override
  void transformOrRemoveChildren(RemovingTransformer v) {
    variable = v.transform(variable);
    variable.parent = this;
    function = v.transform(function);
    function.parent = this;
  }

  @override
  String toString() {
    return "FunctionDeclaration(${toStringInternal()})";
  }

  @override
  void toTextInternal(AstPrinter printer) {
    printer.writeFunctionNode(function, printer.getVariableName(variable));
    if (function.body is ReturnStatement) {
      printer.write(';');
    }
  }
}
