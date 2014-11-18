// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library code_generator;

import 'glue.dart';

import '../../tree_ir/tree_ir_nodes.dart' as tree_ir;
import '../../js/js.dart' as js;
import '../../elements/elements.dart';
import '../../util/maplet.dart';
import '../../constants/values.dart';
import '../../dart2jslib.dart';

class CodegenBailout {
  final tree_ir.Node node;
  final String reason;
  CodegenBailout(this.node, this.reason);
  String get message {
    return 'bailout${node != null ? " on $node" : ""}: $reason';
  }
}

class CodeGenerator extends tree_ir.Visitor<dynamic, js.Expression> {
  final CodegenRegistry registry;

  final Glue glue;

  /// Variables to be hoisted at the top of the current function.
  List<js.VariableDeclaration> variables = <js.VariableDeclaration>[];

  /// Maps variables to their name.
  Map<tree_ir.Variable, String> variableNames = <tree_ir.Variable, String>{};

  /// Maps local constants to their name.
  Maplet<VariableElement, String> constantNames =
      new Maplet<VariableElement, String>();

  /// Variables that have had their declaration created.
  Set<tree_ir.Variable> declaredVariables = new Set<tree_ir.Variable>();

  /// Variable names that have already been used. Used to avoid name clashes.
  Set<String> usedVariableNames;

  List<js.Parameter> parameters = new List<js.Parameter>();
  List<js.Statement> accumulator = new List<js.Statement>();

  js.Block body;

  /// Generates JavaScript code for the body of [function].
  /// The code will be in [body] and the parameters will be in [parameters].
  CodeGenerator(this.glue, this.registry);

  void buildFunction(tree_ir.FunctionDefinition function) {
    visitStatement(function.body);
    for (tree_ir.Variable parameter in function.parameters) {
      parameters.add(new js.Parameter(variableNames[parameter]));
    }
    body = new js.Block(accumulator);
  }

  List<js.Expression> visitArguments(List<tree_ir.Expression> arguments) {
    return arguments.map(visitExpression).toList();
  }

  giveup(tree_ir.Node node,
         [String reason = 'unimplemented in CodeGenerator']) {
    throw new CodegenBailout(node, reason);
  }

  @override
  js.Expression visitConcatenateStrings(tree_ir.ConcatenateStrings node) {
    return giveup(node);
    // TODO: implement visitConcatenateStrings
  }

  @override
  js.Expression visitConditional(tree_ir.Conditional node) {
    return giveup(node);
    // TODO: implement visitConditional
  }

  @override
  js.Expression visitConstant(tree_ir.Constant node) {
    ConstantValue constant = node.expression.value;
    registry.registerCompileTimeConstant(constant);
    return glue.constantReference(constant);
  }

  @override
  js.Expression visitFunctionExpression(tree_ir.FunctionExpression node) {
    return giveup(node);
    // TODO: implement visitFunctionExpression
  }

  @override
  js.Expression visitInvokeConstructor(tree_ir.InvokeConstructor node) {
    return giveup(node);
    // TODO: implement visitInvokeConstructor
  }

  @override
  js.Expression visitInvokeMethod(tree_ir.InvokeMethod node) {
    return giveup(node);
    // TODO: implement visitInvokeMethod
  }

  @override
  js.Expression visitInvokeStatic(tree_ir.InvokeStatic node) {
    Element element = node.target;

    registry.registerStaticInvocation(element);

    js.Expression elementAccess = glue.elementAccess(node.target);
    return new js.Call(elementAccess, visitArguments(node.arguments));
  }

  @override
  js.Expression visitInvokeSuperMethod(tree_ir.InvokeSuperMethod node) {
    return giveup(node);
    // TODO: implement visitInvokeSuperMethod
  }

  @override
  js.Expression visitLiteralList(tree_ir.LiteralList node) {
    return giveup(node);
    // TODO: implement visitLiteralList
  }

  @override
  js.Expression visitLiteralMap(tree_ir.LiteralMap node) {
    return giveup(node);
    // TODO: implement visitLiteralMap
  }

  @override
  js.Expression visitLogicalOperator(tree_ir.LogicalOperator node) {
    return giveup(node);
    // TODO: implement visitLogicalOperator
  }

  @override
  js.Expression visitNot(tree_ir.Not node) {
    return giveup(node);
    // TODO: implement visitNot
  }

  @override
  js.Expression visitReifyTypeVar(tree_ir.ReifyTypeVar node) {
    return giveup(node);
    // TODO: implement visitReifyTypeVar
  }

  @override
  js.Expression visitThis(tree_ir.This node) {
    return giveup(node);
    // TODO: implement visitThis
  }

  @override
  js.Expression visitTypeOperator(tree_ir.TypeOperator node) {
    return giveup(node);
    // TODO: implement visitTypeOperator
  }

  @override
  js.Expression visitVariable(tree_ir.Variable node) {
    return giveup(node);
    // TODO: implement visitVariable
  }

  @override
  void visitContinue(tree_ir.Continue node) {
    return giveup(node);
    // TODO: implement visitContinue
  }

  @override
  void visitExpressionStatement(tree_ir.ExpressionStatement node) {
    accumulator.add(new js.ExpressionStatement(
        visitExpression(node.expression)));
    visitStatement(node.next);
  }

  @override
  void visitFunctionDeclaration(tree_ir.FunctionDeclaration node) {
    giveup(node);
    // TODO: implement visitFunctionDeclaration
  }

  @override
  void visitIf(tree_ir.If node) {
    giveup(node);
    // TODO: implement visitIf
  }

  @override
  void visitLabeledStatement(tree_ir.LabeledStatement node) {
    giveup(node);
    // TODO: implement visitLabeledStatement
  }

  @override
  void visitAssign(tree_ir.Assign node) {
    giveup(node);
    // TODO: implement visitAssign
  }

  @override
  void visitBreak(tree_ir.Break node) {
    giveup(node);
    // TODO: implement visitBreak
  }

  @override
  void visitWhileCondition(tree_ir.WhileCondition node) {
    giveup(node);
    // TODO: implement visitWhileCondition
  }

  @override
  void visitWhileTrue(tree_ir.WhileTrue node) {
    giveup(node);
    // TODO: implement visitWhileTrue
  }

  @override
  void visitReturn(tree_ir.Return node) {
    if (node.value != null) {
      accumulator.add(new js.Return(visitExpression(node.value)));
    }
  }
}
