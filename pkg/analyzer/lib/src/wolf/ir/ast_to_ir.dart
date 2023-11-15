// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type_provider.dart';
import 'package:analyzer/dart/element/type_system.dart';
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
  final AstToIREventListener eventListener;
  final ir = CodedIRWriter();
  final Map<VariableElement, int> locals = {};
  late final null_ = ir.encodeLiteral(null);

  _AstToIRVisitor(
      {required this.typeSystem,
      required this.typeProvider,
      required this.eventListener});

  /// Visits L-value [node] and returns the templates for reading/writing it.
  _LValueTemplates dispatchLValue(Expression node) => node.accept(this)!;

  /// Visits [node], reporting progress to [eventListener].
  void dispatchNode(AstNode node) {
    eventListener.onEnterNode(node);
    var lValueTemplates = node.accept(this);
    // If the node was an L-value, then its visitor didn't actually perform the
    // read, so do that now.
    lValueTemplates?.simpleRead(this);
    eventListener.onExitNode();
  }

  /// Called by [astToIR] after visiting the code to be analyzed.
  CodedIRContainer finish() {
    var result = CodedIRContainer(ir);
    eventListener.onFinished(result);
    return result;
  }

  Null this_() {
    ir.readLocal(0); // Stack: this
  }

  @override
  Null visitAssignmentExpression(AssignmentExpression node) {
    switch (node.operator.type) {
      case TokenType.EQ:
        var lValueTemplates = dispatchLValue(node.leftHandSide);
        // Stack: lValue
        dispatchNode(node.rightHandSide);
        // Stack: lValue rhs
        eventListener.onEnterNode(node.leftHandSide);
        lValueTemplates.write(this);
        // Stack: rhs
        eventListener.onExitNode();
      // Stack: result
      case var tokenType:
        throw UnimplementedError('TODO(paulberry): $tokenType');
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
  }

  @override
  Null visitIntegerLiteral(IntegerLiteral node) {
    // TODO(paulberry): do we need to handle out of range integers?
    ir.literal(ir.encodeLiteral(node.value!));
    // Stack: value
  }

  @override
  Null visitNullLiteral(NullLiteral node) {
    ir.literal(null_);
    // Stack: null
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
    // TODO(paulberry): once some other control flow constructs are implemented,
    // the argument to `ir.br` will need to be chosen based on how deeply nested
    // the control flow constructs are.
    ir.br(0);
    // Stack: indeterminate
  }

  @override
  _LValueTemplates visitSimpleIdentifier(SimpleIdentifier node) {
    var staticElement = node.staticElement;
    switch (staticElement) {
      case ParameterElement():
      case LocalVariableElement():
        return _LocalTemplates(locals[staticElement]!);
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
}

/// Instruction templates for converting a local variable reference to IR.
class _LocalTemplates extends _LValueTemplates {
  final int localIndex;

  _LocalTemplates(this.localIndex);

  void read(_AstToIRVisitor visitor) {
    visitor.ir.readLocal(localIndex);
    // Stack: value
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
///
// TODO(paulberry): add null shorting support.
sealed class _LValueTemplates {
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
