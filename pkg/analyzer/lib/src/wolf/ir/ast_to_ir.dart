// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
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

class _AstToIRVisitor extends ThrowingAstVisitor<void> {
  final TypeSystem typeSystem;
  final TypeProvider typeProvider;
  final AstToIREventListener eventListener;
  final ir = CodedIRWriter();
  late final null_ = ir.encodeLiteral(null);

  _AstToIRVisitor(
      {required this.typeSystem,
      required this.typeProvider,
      required this.eventListener});

  /// Visits [node], reporting progress to [eventListener].
  void dispatchNode(AstNode node) {
    eventListener.onEnterNode(node);
    node.accept(this);
    eventListener.onExitNode();
  }

  /// Called by [astToIR] after visiting the code to be analyzed.
  CodedIRContainer finish() {
    var result = CodedIRContainer(ir);
    eventListener.onFinished(result);
    return result;
  }

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    ir.literal(ir.encodeLiteral(node.value));
    // Stack: value
  }

  @override
  void visitDoubleLiteral(DoubleLiteral node) {
    ir.literal(ir.encodeLiteral(node.value));
    // Stack: value
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    dispatchNode(node.expression);
    // Stack: expression
  }

  void visitFunctionBody(ExecutableElement element, FunctionBody body,
      {required bool isInstanceMember}) {
    if (isInstanceMember) {
      throw UnimplementedError('TODO(paulberry): handle instance members');
    }
    if (element.parameters.isNotEmpty) {
      throw UnimplementedError('TODO(paulberry): handle parameters');
    }
    var flags = FunctionFlags(
        async: body.isAsynchronous,
        generator: body.isGenerator,
        instance: isInstanceMember);
    ir.function(ir.encodeType(element.type), flags);
    // Stack: FUNCTION(flags)
    dispatchNode(body);
    // Stack: FUNCTION(flags) returnValue
    ir.end();
    // Stack: (empty)
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    // TODO(paulberry): do we need to handle out of range integers?
    ir.literal(ir.encodeLiteral(node.value!));
    // Stack: value
  }

  @override
  void visitNullLiteral(NullLiteral node) {
    ir.literal(null_);
    // Stack: null
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    ir.literal(ir.encodeLiteral(node.value));
    // Stack: value
  }
}
