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

  ExecutableElement currentFunction;

  /// Maps variables to their name.
  Map<tree_ir.Variable, String> variableNames = <tree_ir.Variable, String>{};

  /// Maps local constants to their name.
  Maplet<VariableElement, String> constantNames =
      new Maplet<VariableElement, String>();

  /// Variable names that have already been used. Used to avoid name clashes.
  Set<String> usedVariableNames = new Set<String>();

  List<js.Parameter> parameters = new List<js.Parameter>();
  List<js.Statement> accumulator = new List<js.Statement>();

  js.Block body;

  /// Generates JavaScript code for the body of [function].
  /// The code will be in [body] and the parameters will be in [parameters].
  CodeGenerator(this.glue, this.registry);

  void buildFunction(tree_ir.FunctionDefinition function) {
    currentFunction = function.element;
    visitStatement(function.body);

    Set<tree_ir.Variable> parameterSet = new Set<tree_ir.Variable>();

    for (tree_ir.Variable parameter in function.parameters) {
      String name = getVariableName(parameter);
      parameters.add(new js.Parameter(name));
      parameterSet.add(parameter);
    }

    List<js.VariableInitialization> jsVariables = <js.VariableInitialization>[];

    for (tree_ir.Variable variable in variableNames.keys) {
      if (parameterSet.contains(variable)) continue;
      String name = getVariableName(variable);
      js.VariableInitialization jsVariable = new js.VariableInitialization(
        new js.VariableDeclaration(name),
        null);
      jsVariables.add(jsVariable);
    }

    if (jsVariables.length > 0) {
      // Would be nice to avoid inserting at the beginning of list.
      accumulator.insert(0, new js.ExpressionStatement(
          new js.VariableDeclarationList(jsVariables)));
    }
    body = new js.Block(accumulator);
  }

  /// Generates a name for the given variable. First trying with the name of
  /// the [Variable.element] if it is non-null.
  String getVariableName(tree_ir.Variable variable) {
    // TODO(sigurdm): Handle case where the variable belongs to an enclosing
    // function.
    if (variable.host.element != currentFunction) giveup(variable);

    // Get the name if we already have one.
    String name = variableNames[variable];
    if (name != null) {
      return name;
    }

    // Synthesize a variable name that isn't used elsewhere.
    // The [usedVariableNames] set is shared between nested emitters,
    // so this also prevents clash with variables in an enclosing/inner scope.
    // The renaming phase after codegen will further prefix local variables
    // so they cannot clash with top-level variables or fields.
    String prefix = variable.element == null ? 'v' : variable.element.name;
    int counter = 0;
    name = glue.safeVariableName(variable.element == null
        ? '$prefix$counter'
        : variable.element.name);
    while (!usedVariableNames.add(name)) {
      ++counter;
      name = '$prefix$counter';
    }
    variableNames[variable] = name;

    return name;
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
    // TODO(sigurdm): Inside a js closure this will not work.
    return new js.This();
  }

  @override
  js.Expression visitTypeOperator(tree_ir.TypeOperator node) {
    return giveup(node);
    // TODO: implement visitTypeOperator
  }

  @override
  js.Expression visitVariable(tree_ir.Variable node) {
    return new js.VariableUse(getVariableName(node));
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
    tree_ir.Expression value = node.definition;
    js.Expression definition = visitExpression(value);

    accumulator.add(new js.ExpressionStatement(new js.Assignment(
        visitVariable(node.variable),
        definition)));
    visitStatement(node.next);
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
    accumulator.add(new js.Return(visitExpression(node.value)));
  }

  bool isNullLiteral(js.Expression exp) => exp is js.LiteralNull;

}
