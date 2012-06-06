// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Visitor to gather conservative estimate of functions which
 * can be invoked and classes which can be instantiated.
 */
class ReachabilityVisitor implements Visitor {
  final Compiler compiler;
  final TreeElements elements;

  ResolverTask get resolver() => compiler.resolver;
  Enqueuer get world() => compiler.enqueuer.codegen;

  ReachabilityVisitor(this.compiler, this.elements);

  visitBlock(Block node) {}
  visitBreakStatement(BreakStatement node) {}
  visitCascade(Cascade node) {}
  visitCascadeReceiver(CascadeReceiver node) {}
  visitCaseMatch(CaseMatch node) {}
  visitCatchBlock(CatchBlock node) {}
  visitClassNode(ClassNode node) {
    internalError('should not reach ClassNode');
  }
  visitConditional(Conditional node) {}
  visitContinueStatement(ContinueStatement node) {}
  visitDoWhile(DoWhile node) {}
  visitEmptyStatement(EmptyStatement node) {}
  visitExpressionStatement(ExpressionStatement node) {}
  visitFor(For node) {}
  visitForIn(ForIn node) {}
  visitFunctionDeclaration(FunctionDeclaration node) {}
  visitFunctionExpression(FunctionExpression node) {
    // TODO(antonm): add a closure to working queue.
    unimplemented('FunctionExpression is not supported');
  }
  visitIdentifier(Identifier node) {}
  visitIf(If node) {}
  visitLabel(Label node) {}
  visitLabeledStatement(LabeledStatement node) {}
  visitLiteralBool(LiteralBool node) {}
  visitLiteralDouble(LiteralDouble node) {}
  visitLiteralInt(LiteralInt node) {}
  visitLiteralList(LiteralList node) {}
  visitLiteralMap(LiteralMap node) {}
  visitLiteralMapEntry(LiteralMapEntry node) {}
  visitLiteralNull(LiteralNull node) {}
  visitLiteralString(LiteralString node) {}
  visitModifiers(Modifiers node) {}
  visitNamedArgument(NamedArgument node) {}
  visitNodeList(NodeList node) {}
  visitOperator(Operator node) {}
  visitParenthesizedExpression(ParenthesizedExpression node) {}
  visitReturn(Return node) {}
  visitScriptTag(ScriptTag node) {}
  visitSend(Send node) {
    // TODO(antonm): update working queue.
    unimplemented('Send is not supported');
  }
  visitSendSet(SendSet node) {
    // TODO(antonm): update working queue.
    unimplemented('SendSet is not supported');
  }
  visitStringInterpolation(StringInterpolation node) {}
  visitStringInterpolationPart(StringInterpolationPart node) {}
  visitStringJuxtaposition(StringJuxtaposition node) {}
  visitSwitchCase(SwitchCase node) {}
  visitSwitchStatement(SwitchStatement node) {}
  visitThrow(Throw node) {}
  visitTryStatement(TryStatement node) {}
  visitTypeAnnotation(TypeAnnotation node) {}
  visitTypedef(Typedef node) {}
  visitTypeVariable(TypeVariable node) {}
  visitVariableDefinitions(VariableDefinitions node) {}
  visitWhile(While node) {}

  visitNewExpression(NewExpression node) {
    FunctionElement constructor = elements[node.send];
    resolver.resolveMethodElement(constructor);
    world.registerStaticUse(constructor.defaultImplementation);
  }

  unimplemented(String reason) {
    throw new CompilerCancelledException('not implemented: $reason');
  }

  internalError(String reason) {
    throw new CompilerCancelledException('internal error: $reason');
  }
}

class DartBackend extends Backend {
  final List<CompilerTask> tasks = const <CompilerTask>[];

  DartBackend(Compiler compiler) : super(compiler);

  String codegen(WorkItem work) {
    // Traverse AST to populate sets of reachable classes and functions.
    log('codegen(${work.element})');
    FunctionExpression function = work.element.parseNode(compiler);
    function.body.accept(new TraversingVisitor(
        new ReachabilityVisitor(compiler, work.resolutionTree)));
  }

  void processNativeClasses(world, libraries) {}
  void assembleProgram() {
    compiler.assembledCode = '';
  }

  log(String message) => compiler.log('[DartBackend] $message');
}
