// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/src/wolf/ir/call_descriptor.dart';
import 'package:analyzer/src/wolf/ir/coded_ir.dart';
import 'package:analyzer/src/wolf/ir/ir.dart';

/// Converts [functionBody] to a sequence of IR instructions.
///
/// Caller should pass in the [executableElement] for the method or function to
/// be converted (this is used as a source of type information).
///
/// During conversion, progress information will be reported to [eventListener]
/// (if provided). This should provide enough information to allow the caller to
/// map individual instructions to the AST nodes that spawned them.
CodedIRContainer astToIR(
    ExecutableElement executableElement, FunctionBody functionBody,
    {required TypeProvider typeProvider,
    required TypeSystem typeSystem,
    AstToIREventListener? eventListener}) {
  eventListener ??= AstToIREventListener();
  var visitor = _AstToIRVisitor(
      typeSystem: typeSystem,
      typeProvider: typeProvider,
      eventListener: eventListener);
  eventListener._visitor = visitor;
  visitor.visitFunctionBody(executableElement, functionBody,
      isInstanceMember: !executableElement.isStatic);
  var result = visitor.finish();
  eventListener._visitor = null;
  return result;
}

/// Event listener used by [astToIR] to report progress information.
///
/// By itself this class does nothing; the caller of [astToIR] should make a
/// derived class that overrides one or more of the `on...` methods.
base class AstToIREventListener {
  late _AstToIRVisitor? _visitor;

  /// The address of the next instruction that [astToIR] will generate.
  int get nextInstructionAddress => _visitor!.ir.nextInstructionAddress;

  /// Called when [astToIR] is about to visit an AST node.
  void onEnterNode(AstNode node) {}

  /// Called after [astToIR] has finished vising an AST node.
  void onExitNode() {}

  /// Called when [astToIR] has completely finished IR generation.
  void onFinished(CodedIRContainer ir) {}
}

/// Visitor that converts AST nodes to IR instructions.
///
/// Visit methods that handle L-values (expressions that may appear on the left
/// hand side of an assignment) visit subexpressions of the L-value and then
/// return an instance of [_LValueTemplates] so that the caller can decide what
/// to do next.
///
/// The remaining visit methods simply return `null`.
class _AstToIRVisitor extends ThrowingAstVisitor<_LValueTemplates> {
  final TypeSystem typeSystem;
  final TypeProvider typeProvider;
  final LibraryElement coreLibrary;
  final AstToIREventListener eventListener;

  /// For each enclosing flow control construct that may be the target of a
  /// `break` statement, the value returned by [RawIRWriter.nestingLevel] after
  /// emitting the `block` instruction that should be targeted by the `break`
  /// statement.
  final breakStack = <int>[];

  /// For each enclosing flow control construct that may be the target of a
  /// `continue` statement, the value returned by [RawIRWriter.nestingLevel]
  /// after emitting the `block` or `loop` instruction that should be targeted
  /// by the `continue` statement.
  final continueStack = <int>[];

  /// For each unmatched `function` instruction that has been output, the value
  /// returned by [RawIRWriter.nestingLevel] after emitting that `function`
  /// instruction.
  ///
  /// This is used to compute the appropriate parameter to the `br` instruction
  /// when generating IR for a `return` statement.
  final functionNestingStack = <int>[];

  final ir = CodedIRWriter();
  final Map<VariableElement, int> locals = {};
  late final oneArgument = ir.encodeArgumentNames([null]);
  late final twoArguments = ir.encodeArgumentNames([null, null]);
  late final null_ = ir.encodeLiteral(null);
  late final one = ir.encodeLiteral(1);
  late final stackIndices101 = ir.encodeStackIndices(const [1, 0, 1]);

  _AstToIRVisitor(
      {required this.typeSystem,
      required this.typeProvider,
      required this.eventListener})
      : coreLibrary = typeProvider.objectElement.library;

  /// If [node] is used as the target of a [CompoundAssignmentExpression],
  /// returns the [CompoundAssignmentExpression].
  CompoundAssignmentExpression? assignmentTargeting(AstNode node) {
    while (true) {
      var parent = node.parent!;
      switch (parent) {
        case PrefixedIdentifier() when identical(node, parent.identifier):
        case PropertyAccess() when identical(node, parent.propertyName):
          node = parent;
        case AssignmentExpression() when identical(node, parent.leftHandSide):
          return parent;
        case PostfixExpression(operator: Token(:var type))
            when type == TokenType.PLUS_PLUS || type == TokenType.MINUS_MINUS:
          return parent;
        case PrefixExpression(operator: Token(:var type))
            when type == TokenType.PLUS_PLUS || type == TokenType.MINUS_MINUS:
          return parent;
        case dynamic(:var runtimeType):
          throw UnimplementedError('TODO(paulberry): $runtimeType');
      }
    }
  }

  /// Visits L-value [node] and returns the templates for reading/writing it.
  _LValueTemplates dispatchLValue(Expression node) => node.accept(this)!;

  /// Visits [node], reporting progress to [eventListener].
  ///
  /// If [node] has null shorting behavior, then [terminateNullShorting]
  /// determines how the null shorting behavior is handled. If
  /// [terminateNullShorting] is `true` (the default), then null shorting will
  /// be terminated after visiting [node], by emitting an `end` instruction;
  /// this means that in the case where the null short occurs, the expression
  /// will evaluate to `null`. If [terminateNullShorting] is `false`, then null
  /// shorting won't be terminated; this means that in the case where the null
  /// short occurs, execution of the parent node will be skipped too.
  void dispatchNode(AstNode node, {bool terminateNullShorting = true}) {
    eventListener.onEnterNode(node);
    var previousNestingLevel = ir.nestingLevel;
    var lValueTemplates = node.accept(this);
    // If the node was an L-value, then its visitor didn't actually perform the
    // read, so do that now.
    lValueTemplates?.simpleRead(this);
    if (terminateNullShorting) ir.endTo(previousNestingLevel);
    eventListener.onExitNode();
  }

  /// Called by [astToIR] after visiting the code to be analyzed.
  CodedIRContainer finish() {
    assert(breakStack.isEmpty);
    assert(continueStack.isEmpty);
    assert(functionNestingStack.isEmpty);
    var result = CodedIRContainer(ir);
    eventListener.onFinished(result);
    return result;
  }

  void instanceCall(MethodElement? staticElement, String name,
      List<DartType> typeArguments, ArgumentNamesRef argumentNames) {
    if (staticElement == null) throw UnimplementedError('TODO(paulberry)');
    ir.call(
        ir.encodeCallDescriptor(
            ElementCallDescriptor(staticElement, typeArguments: typeArguments)),
        argumentNames);
  }

  void instanceGet(PropertyAccessorElement? staticElement, String name) {
    if (staticElement == null) {
      throw UnimplementedError('TODO(paulberry): dynamic instance get');
    }
    ir.call(ir.encodeCallDescriptor(ElementCallDescriptor(staticElement)),
        oneArgument);
  }

  void instanceSet(PropertyAccessorElement? staticElement, String name) {
    if (staticElement == null) {
      throw UnimplementedError('TODO(paulberry): dynamic instance set');
    }
    ir.call(ir.encodeCallDescriptor(ElementCallDescriptor(staticElement)),
        twoArguments);
  }

  MethodElement lookupToString(DartType? type) {
    var class_ =
        type is InterfaceType ? type.element : typeProvider.objectElement;
    return class_.augmented
        .lookUpMethod(name: 'toString', library: coreLibrary)!;
  }

  /// Performs a null check that is part of a null shorting expression.
  ///
  /// If [nonNull] is `false` (the default), and the value at the top of the
  /// stack is `null`, execution will branch to the end of the null shorting
  /// expression, and the null shorting expression will evaluate to `null`.
  /// Otherwise, execution will proceed normally.
  ///
  /// If [nonNull] is `true`, and the value at the top of the stack is not
  /// `null`, execution will branch to the end of the null shorting expression,
  /// and the null shorting expression will evaluate to the value at the top of
  /// the stack. Otherwise, execution will proceed normally.
  ///
  /// [additionalDiscardDepth] specifies the number of additional stack values
  /// (beyond the value that is null checked) which should be discarded if the
  /// expression is null shorted.
  ///
  /// [previousNestingLevel] is the value returned by [RawIRWriter.nestingLevel]
  /// at the beginning of the null shorting expression. It is used to detect
  /// whether null shorting has already been begun, and therefore whether a
  /// `block` instruction needs to be output.
  void nullShortingCheck(
      {required int previousNestingLevel,
      bool nonNull = false,
      int additionalDiscardDepth = 0}) {
    assert(previousNestingLevel <= ir.nestingLevel);
    // Stack: value
    ir.dup();
    // Stack: value value
    ir.literal(null_);
    // Stack: value value null
    ir.eq();
    // Stack: value (value == null)
    if (nonNull) {
      ir.not();
      // Stack: value (value != null)
    }
    if (previousNestingLevel == ir.nestingLevel) {
      // Null shorting hasn't begun yet for the containing expression, so start
      // it now by opening a block; the block will be ended at the end of the
      // null shorting expression, so it will be the branch target for null
      // shorts.
      ir.block(2 + additionalDiscardDepth, 1);
      // Stack: BLOCK(1) value (value == null)
    }
    ir.brIf(0);
    // Stack: BLOCK(1)? value
  }

  Null this_() {
    ir.readLocal(0); // Stack: this
  }

  @override
  Null visitAdjacentStrings(AdjacentStrings node) {
    for (var string in node.strings) {
      dispatchNode(string);
      // Stack: string
    }
    // Stack: strings
    ir.concat(node.strings.length);
    // Stack: result
  }

  @override
  Null visitAssignmentExpression(AssignmentExpression node) {
    var previousNestingLevel = ir.nestingLevel;
    var lValueTemplates = dispatchLValue(node.leftHandSide);
    // Stack: lValue
    switch (node.operator.type) {
      case TokenType.EQ:
        dispatchNode(node.rightHandSide);
        // Stack: lValue rhs
        eventListener.onEnterNode(node.leftHandSide);
        lValueTemplates.write(this);
        // Stack: rhs
        eventListener.onExitNode();
      // Stack: result
      case TokenType.QUESTION_QUESTION_EQ:
        lValueTemplates.readForCompoundAssignment(this);
        // Stack: lValue oldValue
        nullShortingCheck(
            previousNestingLevel: previousNestingLevel,
            nonNull: true,
            additionalDiscardDepth: lValueTemplates.subexpressionCount);
        // Stack: BLOCK(1)? lvalue oldValue
        ir.drop();
        // Stack: BLOCK(1)? lvalue
        dispatchNode(node.rightHandSide);
        // Stack: lValue rhs
        eventListener.onEnterNode(node.leftHandSide);
        lValueTemplates.write(this);
        // Stack: rhs
        eventListener.onExitNode();
      case TokenType.AMPERSAND_EQ:
      case TokenType.BAR_EQ:
      case TokenType.CARET_EQ:
      case TokenType.GT_GT_EQ:
      case TokenType.GT_GT_GT_EQ:
      case TokenType.LT_LT_EQ:
      case TokenType.MINUS_EQ:
      case TokenType.PERCENT_EQ:
      case TokenType.PLUS_EQ:
      case TokenType.SLASH_EQ:
      case TokenType.STAR_EQ:
      case TokenType.TILDE_SLASH_EQ:
        lValueTemplates.readForCompoundAssignment(this);
        // Stack: lValue oldValue
        dispatchNode(node.rightHandSide);
        // Stack: lValue oldValue rhs
        var lexeme = node.operator.lexeme;
        assert(lexeme.endsWith('='));
        instanceCall(node.staticElement, lexeme.substring(0, lexeme.length - 1),
            const [], twoArguments);
        // Stack: lValue newValue
        eventListener.onEnterNode(node.leftHandSide);
        lValueTemplates.write(this);
        // Stack: newValue
        eventListener.onExitNode();
      // Stack: result
      case var tokenType:
        throw UnimplementedError('TODO(paulberry): $tokenType');
    }
  }

  @override
  Null visitAwaitExpression(AwaitExpression node) {
    dispatchNode(node.expression);
    // Stack: expression
    if (!typeSystem.isSubtypeOf(
        node.expression.staticType!, typeProvider.futureDynamicType)) {
      throw UnimplementedError('TODO(paulberry): handle await of non-future');
    }
    ir.await_();
    // Stack: result
  }

  @override
  Null visitBinaryExpression(BinaryExpression node) {
    var tokenType = node.operator.type;
    switch (tokenType) {
      case TokenType.EQ_EQ:
        dispatchNode(node.leftOperand);
        // Stack: lhs
        dispatchNode(node.rightOperand);
        // Stack: lhs rhs
        ir.eq();
      // Stack: (lhs == rhs)
      case TokenType.BANG_EQ:
        dispatchNode(node.leftOperand);
        // Stack: lhs
        dispatchNode(node.rightOperand);
        // Stack: lhs rhs
        ir.eq();
        // Stack: (lhs == rhs)
        ir.not();
      // Stack: (lhs != rhs)
      case TokenType.AMPERSAND_AMPERSAND:
        ir.block(0, 1);
        // Stack: BLOCK(1)
        dispatchNode(node.leftOperand);
        // Stack: BLOCK(1) lhs
        ir.dup();
        // Stack: BLOCK(1) lhs lhs
        ir.not();
        // Stack: BLOCK(1) lhs !lhs
        ir.brIf(0);
        // Stack: BLOCK(1) lhs
        ir.drop();
        // Stack: BLOCK(1)
        dispatchNode(node.rightOperand);
        // Stack: BLOCK(1) rhs
        ir.end();
      // Stack: result
      case TokenType.BAR_BAR:
        ir.block(0, 1);
        // Stack: BLOCK(1)
        dispatchNode(node.leftOperand);
        // Stack: BLOCK(1) lhs
        ir.dup();
        // Stack: BLOCK(1) lhs lhs
        ir.brIf(0);
        // Stack: BLOCK(1) lhs
        ir.drop();
        // Stack: BLOCK(1)
        dispatchNode(node.rightOperand);
        // Stack: BLOCK(1) rhs
        ir.end();
      // Stack: result
      case TokenType.QUESTION_QUESTION:
        ir.block(0, 1);
        // Stack: BLOCK(1)
        dispatchNode(node.leftOperand);
        // Stack: BLOCK(1) lhs
        ir.dup();
        // Stack: BLOCK(1) lhs lhs
        ir.literal(null_);
        // Stack: BLOCK(1) lhs lhs null
        ir.eq();
        // Stack: BLOCK(1) lhs (lhs == null)
        ir.not();
        // Stack: BLOCK(1) lhs (lhs != null)
        ir.brIf(0);
        // Stack: BLOCK(1) lhs
        ir.drop();
        // Stack: BLOCK(1)
        dispatchNode(node.rightOperand);
        // Stack: BLOCK(1) rhs
        ir.end();
      // Stack: result
      case TokenType.AMPERSAND:
      case TokenType.BAR:
      case TokenType.CARET:
      case TokenType.GT:
      case TokenType.GT_EQ:
      case TokenType.GT_GT:
      case TokenType.GT_GT_GT:
      case TokenType.LT:
      case TokenType.LT_EQ:
      case TokenType.LT_LT:
      case TokenType.MINUS:
      case TokenType.PERCENT:
      case TokenType.PLUS:
      case TokenType.SLASH:
      case TokenType.STAR:
      case TokenType.TILDE_SLASH:
        dispatchNode(node.leftOperand);
        // Stack: lhs
        dispatchNode(node.rightOperand);
        // Stack: lhs rhs
        instanceCall(node.staticElement, tokenType.lexeme, [], twoArguments);
      // Stack: result
      default:
        throw UnimplementedError('TODO(paulberry): $node');
    }
  }

  @override
  Null visitBlock(Block node) {
    var previousLocalVariableCount = ir.localVariableCount;
    for (var statement in node.statements) {
      dispatchNode(statement);
    }
    ir.releaseTo(previousLocalVariableCount);
  }

  @override
  Null visitBlockFunctionBody(BlockFunctionBody node) {
    dispatchNode(node.block);
    ir.literal(null_);
    // Stack: null
  }

  @override
  Null visitBooleanLiteral(BooleanLiteral node) {
    ir.literal(ir.encodeLiteral(node.value));
    // Stack: value
  }

  @override
  Null visitBreakStatement(BreakStatement node) {
    if (node.label != null) {
      throw UnimplementedError('TODO(paulberry)');
    }
    ir.br(ir.nestingLevel - breakStack.last);
  }

  @override
  Null visitConditionalExpression(ConditionalExpression node) {
    ir.block(0, 1);
    // Stack: BLOCK(1)
    ir.block(0, 0);
    // Stack: BLOCK(1) BLOCK(0)
    dispatchNode(node.condition);
    // Stack: BLOCK(1) BLOCK(0) condition
    ir.not();
    // Stack: BLOCK(1) BLOCK(0) !condition
    ir.brIf(0);
    // Stack: BLOCK(1) BLOCK(0)
    dispatchNode(node.thenExpression);
    // Stack: BLOCK(1) BLOCK(0) thenExpression
    ir.br(1);
    // Stack: BLOCK(1) BLOCK(0) indeterminate
    ir.end();
    // Stack: BLOCK(1)
    dispatchNode(node.elseExpression);
    // Stack: BLOCK(1) elseExpression
    ir.end();
    // Stack: result
  }

  @override
  Null visitContinueStatement(ContinueStatement node) {
    if (node.label != null) {
      throw UnimplementedError('TODO(paulberry)');
    }
    ir.br(ir.nestingLevel - continueStack.last);
  }

  @override
  Null visitDoStatement(DoStatement node) {
    ir.block(0, 0);
    // Stack: BLOCK(0)
    breakStack.add(ir.nestingLevel);
    ir.loop(0);
    // Stack: BLOCK(0) LOOP(0)
    ir.block(0, 0);
    // Stack: BLOCK(0) LOOP(0) BLOCK(0)
    continueStack.add(ir.nestingLevel);
    dispatchNode(node.body);
    // Stack: BLOCK(0) LOOP(0) BLOCK(0)
    continueStack.removeLast();
    ir.end();
    // Stack: BLOCK(0) LOOP(0)
    dispatchNode(node.condition);
    // Stack: BLOCK(0) LOOP(0) condition
    ir.not();
    // Stack: BLOCK(0) LOOP(0) !condition
    ir.brIf(1);
    // Stack: BLOCK(0) LOOP(0)
    ir.end();
    // Stack: BLOCK(0) indeterminate
    breakStack.removeLast();
    ir.end();
    // Stack: (empty)
  }

  @override
  Null visitDoubleLiteral(DoubleLiteral node) {
    ir.literal(ir.encodeLiteral(node.value));
    // Stack: value
  }

  @override
  Null visitExpressionFunctionBody(ExpressionFunctionBody node) {
    dispatchNode(node.expression);
    // Stack: expression
  }

  @override
  Null visitExpressionStatement(ExpressionStatement node) {
    dispatchNode(node.expression);
    // Stack: expression
    ir.drop();
    // Stack: (empty)
  }

  @override
  Null visitForStatement(ForStatement node) {
    switch (node.forLoopParts) {
      case ForParts(:var condition, :var updaters) && var forParts:
        switch (forParts) {
          case ForPartsWithDeclarations(:var variables):
            dispatchNode(variables);
          case dynamic(:var runtimeType):
            throw UnimplementedError('TODO(paulberry): handle $runtimeType');
        }
        // Stack: (empty)
        ir.block(0, 0);
        // Stack: BLOCK(0)
        breakStack.add(ir.nestingLevel);
        ir.loop(0);
        // Stack: BLOCK(0) LOOP(0)
        if (condition != null) {
          dispatchNode(condition);
          // Stack: BLOCK(0) LOOP(0) condition
          ir.not();
          // Stack: BLOCK(0) LOOP(0) !condition
          ir.brIf(1);
          // Stack: BLOCK(0) LOOP(0)
        }
        ir.block(0, 0);
        // Stack: BLOCK(0) LOOP(0) BLOCK(0)
        continueStack.add(ir.nestingLevel);
        dispatchNode(node.body);
        // Stack: BLOCK(0) LOOP(0) BLOCK(0)
        continueStack.removeLast();
        ir.end();
        // Stack: BLOCK(0) LOOP(0)
        for (var updater in updaters) {
          dispatchNode(updater);
          // Stack: BLOCK(0) LOOP(0) updater
          ir.drop();
          // Stack: BLOCK(0) LOOP(0)
        }
        ir.end();
        // Stack: BLOCK(0) indeterminate
        breakStack.removeLast();
        ir.end();
      // Stack: (empty)
      case dynamic(:var runtimeType):
        throw UnimplementedError('TODO(paulberry): handle $runtimeType');
    }
  }

  void visitFunctionBody(ExecutableElement element, FunctionBody body,
      {required bool isInstanceMember}) {
    int count = 0;
    if (isInstanceMember) {
      count++;
    }
    for (var element in element.parameters) {
      assert(!locals.containsKey(element));
      var localIndex = ir.localVariableCount + count;
      locals[element] = localIndex;
      count++;
    }
    var flags = FunctionFlags(
        async: body.isAsynchronous,
        generator: body.isGenerator,
        instance: isInstanceMember);
    ir.function(ir.encodeType(element.type), flags);
    // Stack: FUNCTION(flags) parameters
    functionNestingStack.add(ir.nestingLevel);
    if (count > 0) {
      ir.alloc(count);
      // Stack: FUNCTION(flags) parameters
      for (var i = 0; i++ < count;) {
        ir.writeLocal(ir.localVariableCount - i);
      }
      // Stack: FUNCTION(flags)
    }
    dispatchNode(body);
    // Stack: FUNCTION(flags) returnValue
    if (count > 0) {
      ir.release(count);
    }
    ir.end();
    // Stack: (empty)
    functionNestingStack.removeLast();
  }

  @override
  Null visitIfStatement(IfStatement node) {
    if (node.caseClause != null) throw UnimplementedError('TODO(paulberry)');
    var elseStatement = node.elseStatement;
    if (elseStatement == null) {
      dispatchNode(node.expression);
      // Stack: expression
      ir.not();
      // Stack: !expression
      ir.block(1, 0);
      // Stack: BLOCK(0) !expression
      ir.brIf(0);
      // Stack: BLOCK(0)
      dispatchNode(node.thenStatement);
      ir.end();
      // Stack: (empty)
    } else {
      dispatchNode(node.expression);
      // Stack: expression
      ir.not();
      // Stack: !expression
      ir.block(1, 0);
      // Stack: BLOCK(0) !expression
      ir.block(1, 0);
      // Stack: BLOCK(0) BLOCK(0) !expression
      ir.brIf(0);
      // Stack: BLOCK(0) BLOCK(0)
      dispatchNode(node.thenStatement);
      ir.br(1);
      // Stack: BLOCK(0) BLOCK(0) indeterminate
      ir.end();
      // Stack: BLOCK(0)
      dispatchNode(elseStatement);
      ir.end();
      // Stack: (empty)
    }
  }

  @override
  Null visitIntegerLiteral(IntegerLiteral node) {
    // TODO(paulberry): do we need to handle out of range integers?
    ir.literal(ir.encodeLiteral(node.value!));
    // Stack: value
  }

  @override
  Null visitInterpolationExpression(InterpolationExpression node) {
    dispatchNode(node.expression);
    // Stack: expression
    instanceCall(lookupToString(node.expression.staticType), 'toString', [],
        oneArgument);
    // Stack: expression.toString()
  }

  @override
  Null visitInterpolationString(InterpolationString node) {
    ir.literal(ir.encodeLiteral(node.value));
    // Stack: value
  }

  @override
  Null visitIsExpression(IsExpression node) {
    dispatchNode(node.expression);
    // Stack: expression
    ir.is_(ir.encodeType(node.type.type!));
    // Stack: (expression is type)
    if (node.notOperator != null) {
      ir.not();
      // Stack: (expression is! type)
    }
  }

  @override
  Null visitMethodInvocation(MethodInvocation node) {
    var previousNestingLevel = ir.nestingLevel;
    var argumentNames = <String?>[];
    var target = node.target;
    var methodElement = node.methodName.staticElement;
    switch (methodElement) {
      case FunctionElement(enclosingElement3: CompilationUnitElement()):
        assert(!node.isNullAware);
        _handleInvocationArgs(
            argumentList: node.argumentList,
            argumentNames: argumentNames,
            isNullAware: false,
            previousNestingLevel: previousNestingLevel);
        // Stack: arguments
        if (methodElement.library.isDartCore &&
            methodElement.name == 'identical') {
          ir.identical();
        } else {
          ir.call(
              ir.encodeCallDescriptor(ElementCallDescriptor(methodElement,
                  typeArguments: node.typeArgumentTypes!)),
              ir.encodeArgumentNames(argumentNames));
        }
      // Stack: result
      case MethodElement(isStatic: false):
        if (target == null) {
          assert(!node.isNullAware);
          this_();
          // Stack: this
        } else {
          dispatchNode(target, terminateNullShorting: false);
          // Stack: target
        }
        argumentNames.add(null);
        _handleInvocationArgs(
            argumentList: node.argumentList,
            argumentNames: argumentNames,
            isNullAware: node.isNullAware,
            previousNestingLevel: previousNestingLevel);
        // Stack: BLOCK(1)? target arguments
        instanceCall(methodElement, node.methodName.name,
            node.typeArgumentTypes!, ir.encodeArgumentNames(argumentNames));
      // Stack: BLOCK(1)? result
      case MethodElement(isStatic: true):
        assert(!node.isNullAware);
        _handleInvocationArgs(
            argumentList: node.argumentList,
            argumentNames: argumentNames,
            isNullAware: false,
            previousNestingLevel: previousNestingLevel);
        // Stack: arguments
        ir.call(
            ir.encodeCallDescriptor(ElementCallDescriptor(methodElement,
                typeArguments: node.typeArgumentTypes!)),
            ir.encodeArgumentNames(argumentNames));
      // Stack: result

      case dynamic(:var runtimeType):
        throw UnimplementedError(
            'TODO(paulberry): $runtimeType: $methodElement');
    }
  }

  @override
  Null visitNullLiteral(NullLiteral node) {
    ir.literal(null_);
    // Stack: null
  }

  @override
  Null visitParenthesizedExpression(ParenthesizedExpression node) {
    dispatchNode(node.expression);
    // Stack: expression
  }

  @override
  Null visitPostfixExpression(PostfixExpression node) {
    switch (node.operator.type) {
      case TokenType.PLUS_PLUS:
      case TokenType.MINUS_MINUS:
        var lValueTemplates = dispatchLValue(node.operand);
        // Stack: lValue
        eventListener.onEnterNode(node.operand);
        lValueTemplates.readForPostfixIncDec(this);
        // Stack: oldValue lValue oldValue
        eventListener.onExitNode();
        ir.literal(one);
        // Stack: oldValue lValue oldValue 1
        instanceCall(
            node.staticElement, node.operator.lexeme[0], [], twoArguments);
        // Stack: oldValue lValue newValue
        lValueTemplates.write(this);
        // Stack: oldValue newValue
        ir.drop();
      // Stack: oldValue
      default:
        throw UnimplementedError('TODO(paulberry): ${node.operator.type}');
    }
  }

  @override
  _LValueTemplates? visitPrefixedIdentifier(PrefixedIdentifier node) {
    var prefix = node.prefix;
    var prefixElement = prefix.staticElement;
    switch (prefixElement) {
      case ParameterElement():
      case LocalVariableElement():
        dispatchNode(prefix);
        // Stack: prefix
        return _PropertyAccessTemplates(node.identifier);
      case dynamic(:var runtimeType):
        throw UnimplementedError(
            'TODO(paulberry): $runtimeType: $prefixElement');
    }
  }

  @override
  Null visitPrefixExpression(PrefixExpression node) {
    switch (node.operator.type) {
      case TokenType.BANG:
        dispatchNode(node.operand);
        // Stack: operand
        ir.not();
      // Stack: !operand
      case TokenType.PLUS_PLUS:
      case TokenType.MINUS_MINUS:
        var lValueTemplates = dispatchLValue(node.operand);
        // Stack: lValue
        lValueTemplates.readForCompoundAssignment(this);
        // Stack: lValue oldValue
        ir.literal(one);
        // Stack: lValue oldValue 1
        instanceCall(
            node.staticElement, node.operator.lexeme[0], [], twoArguments);
        // Stack: lValue newValue
        eventListener.onEnterNode(node.operand);
        lValueTemplates.write(this);
        // Stack: newValue
        eventListener.onExitNode();
      default:
        throw UnimplementedError('TODO(paulberry): ${node.operator.type}');
    }
  }

  @override
  _LValueTemplates visitPropertyAccess(PropertyAccess node) {
    var previousNestingLevel = ir.nestingLevel;
    // TODO(paulberry): handle cascades
    dispatchNode(node.target!, terminateNullShorting: false);
    // Stack: target
    if (node.isNullAware) {
      nullShortingCheck(previousNestingLevel: previousNestingLevel);
    }
    // Stack: BLOCK(1)? target
    return _PropertyAccessTemplates(node.propertyName);
  }

  @override
  Null visitReturnStatement(ReturnStatement node) {
    switch (node.expression) {
      case null:
        ir.literal(null_);
      case var expression:
        dispatchNode(expression);
    }
    // Stack: returnValue
    ir.br(ir.nestingLevel - functionNestingStack.last);
    // Stack: indeterminate
  }

  @override
  _LValueTemplates visitSimpleIdentifier(SimpleIdentifier node) {
    var staticElement = node.staticElement;
    if (staticElement == null) {
      if (assignmentTargeting(node) case var assignment?) {
        staticElement = assignment.readElement ?? assignment.writeElement;
      }
    }
    switch (staticElement) {
      case ParameterElement():
      case LocalVariableElement():
        return _LocalTemplates(locals[staticElement]!);
      case PropertyAccessorElement(isStatic: false):
        this_();
        // Stack: this
        return _PropertyAccessTemplates(node);
      // Stack: value
      case dynamic(:var runtimeType):
        throw UnimplementedError(
            'TODO(paulberry): $runtimeType: $staticElement');
    }
  }

  @override
  Null visitSimpleStringLiteral(SimpleStringLiteral node) {
    ir.literal(ir.encodeLiteral(node.value));
    // Stack: value
  }

  @override
  Null visitStringInterpolation(StringInterpolation node) {
    for (var element in node.elements) {
      dispatchNode(element);
    }
    // Stack: strings
    ir.concat(node.elements.length);
    // Stack: result
  }

  @override
  Null visitThisExpression(ThisExpression node) => this_();

  @override
  Null visitVariableDeclarationList(VariableDeclarationList variables) {
    for (var VariableDeclaration(:initializer, :declaredElement!)
        in variables.variables) {
      assert(!locals.containsKey(declaredElement));
      var localIndex = ir.localVariableCount;
      locals[declaredElement] = localIndex;
      ir.alloc(1);
      if (initializer != null) {
        dispatchNode(initializer);
        // Stack: initializer
        ir.writeLocal(localIndex);
        // Stack: (empty)
      } else if (typeSystem.isNullable(declaredElement.type)) {
        ir.literal(null_);
        // Stack: null
        ir.writeLocal(localIndex);
        // Stack: (empty)
      }
    }
  }

  @override
  Null visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    if (node.variables.isLate) {
      throw UnimplementedError(
          'TODO(paulberry): handle late variable declarations');
    }
    dispatchNode(node.variables);
  }

  @override
  Null visitWhileStatement(WhileStatement node) {
    ir.block(0, 0);
    // Stack: BLOCK(0)
    breakStack.add(ir.nestingLevel);
    ir.loop(0);
    // Stack: BLOCK(0) LOOP(0)
    continueStack.add(ir.nestingLevel);
    dispatchNode(node.condition);
    // Stack: BLOCK(0) LOOP(0) condition
    ir.not();
    // Stack: BLOCK(0) LOOP(0) !condition
    ir.brIf(1);
    // Stack: BLOCK(0) LOOP(0)
    dispatchNode(node.body);
    // Stack: BLOCK(0) LOOP(0)
    continueStack.removeLast();
    ir.end();
    // Stack: BLOCK(0) indeterminate
    breakStack.removeLast();
    ir.end();
    // Stack: (empty)
  }

  @override
  Null visitYieldStatement(YieldStatement node) {
    dispatchNode(node.expression);
    // Stack: expression
    ir.yield_();
    // Stack: (empty)
  }

  void _handleInvocationArgs(
      {required ArgumentList argumentList,
      required List<String?> argumentNames,
      required bool isNullAware,
      required int previousNestingLevel}) {
    if (isNullAware) {
      nullShortingCheck(previousNestingLevel: previousNestingLevel);
    }
    // Stack: BLOCK(1)? target
    for (var argument in argumentList.arguments) {
      if (argument is NamedExpression) {
        dispatchNode(argument.expression);
        argumentNames.add(argument.name.label.name);
      } else {
        dispatchNode(argument);
        argumentNames.add(null);
      }
    }
  }
}

/// Instruction templates for converting a local variable reference to IR.
class _LocalTemplates extends _LValueTemplates {
  final int localIndex;

  _LocalTemplates(this.localIndex) : super(subexpressionCount: 0);

  void read(_AstToIRVisitor visitor) {
    visitor.ir.readLocal(localIndex);
    // Stack: value
  }

  @override
  void readForCompoundAssignment(_AstToIRVisitor visitor) {
    read(visitor);
    // Stack: value
  }

  @override
  void readForPostfixIncDec(_AstToIRVisitor visitor) {
    read(visitor);
    // Stack: value
    visitor.ir.dup();
    // Stack: value value
  }

  @override
  void simpleRead(_AstToIRVisitor visitor) {
    read(visitor);
    // Stack: value
  }

  @override
  void write(_AstToIRVisitor visitor) {
    // Stack: value
    visitor.ir.dup();
    // Stack: value value
    visitor.ir.writeLocal(localIndex);
    // Stack: value
  }
}

/// Instruction templates for converting an L-value to IR.
///
/// If the L-value has subexpressions, then at the time [_LValueTemplates] is
/// constructed, instructions should be emitted that place the values of these
/// subexpressions on the stack.
///
/// The methods in this class will emit instructions manipulate those
/// subexpression values in order to read or write the L-value.  These methods
/// are abstract, and are defined in a derived class for each specific kind of
/// L-value supported by Dart.
sealed class _LValueTemplates {
  final int subexpressionCount;

  _LValueTemplates({required this.subexpressionCount});

  /// Outputs the IR instructions for reading from the L-value in a way that
  /// remains prepared for a compound assignment.
  ///
  /// On entry, the stack contents should be the subexpression values.
  ///
  /// On exit, the stack contents will be the subexpression values, followed by
  /// the result of the read operation. (This allows the caller to implement a
  /// compound assignment by modifying the value at the top of the stack and
  /// then making a follow-up call to [write]).
  void readForCompoundAssignment(_AstToIRVisitor visitor);

  /// Outputs the IR instructions for reading from the L-value in a way that
  /// remains prepared for a postfix increment or decrement.
  ///
  /// On entry, the stack contents should be the subexpression values.
  ///
  /// On exit, the stack contents will be the result of the read operation,
  /// followed by the subexpression values, followed by the result of the read
  /// operation again. (This allows the caller to implement a postfix increment
  /// or decrement by modifying the value at the top of the stack, then making a
  /// follow-up call to [write], then dropping the result of the write so that
  /// the result of the read operation remains).
  void readForPostfixIncDec(_AstToIRVisitor visitor);

  /// Outputs the IR instructions for a simple read of the L-value.
  ///
  /// On entry, the stack contents should be the subexpression values.
  ///
  /// On exit, the stack contents will be the result of the read operation.
  void simpleRead(_AstToIRVisitor visitor);

  /// Outputs the IR instructions for writing to the L-value.
  ///
  /// On entry, the stack contents should be the subexpression values.
  ///
  /// On exit, the stack contents will be the value that was written.
  void write(_AstToIRVisitor visitor);
}

/// Instruction templates for converting a property access to IR.
class _PropertyAccessTemplates extends _LValueTemplates {
  final SimpleIdentifier property;

  /// Creates a property access template.
  ///
  /// Caller is responsible for ensuring that the target of the property access
  /// is pushed to the stack.
  _PropertyAccessTemplates(this.property) : super(subexpressionCount: 1);

  void read(_AstToIRVisitor visitor) {
    // Stack: target
    visitor.instanceGet(
        (property.staticElement ??
                visitor.assignmentTargeting(property)?.readElement)
            as PropertyAccessorElement?,
        property.name);
    // Stack: value
  }

  @override
  void readForCompoundAssignment(_AstToIRVisitor visitor) {
    // Stack: target
    visitor.ir.dup();
    // Stack: target target
    read(visitor);
    // Stack: target value
  }

  @override
  void readForPostfixIncDec(_AstToIRVisitor visitor) {
    // Stack: target
    visitor.ir.dup();
    // Stack: target target
    read(visitor);
    // Stack: target value
    visitor.ir.shuffle(2, visitor.stackIndices101);
    // Stack: value target value
  }

  @override
  void simpleRead(_AstToIRVisitor visitor) {
    // Stack: target
    read(visitor);
    // Stack: value
  }

  @override
  void write(_AstToIRVisitor visitor) {
    // Stack: target value
    visitor.ir.shuffle(2, visitor.stackIndices101);
    // Stack: value target value
    visitor.instanceSet(
        visitor.assignmentTargeting(property)!.writeElement
            as PropertyAccessorElement?,
        property.name);
    // Stack: value returnValue
    visitor.ir.drop();
    // Stack: value
  }
}
