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

  /// Input to [visitStatement]. Denotes the statement that will execute next
  /// if the statements produced by [visitStatement] complete normally.
  /// Set to null if control will fall over the end of the method.
  tree_ir.Statement fallthrough = null;

  Set<tree_ir.Label> usedLabels = new Set<tree_ir.Label>();

  List<js.Statement> accumulator = new List<js.Statement>();

  CodeGenerator(this.glue, this.registry);

  /// Generates JavaScript code for the body of [function].
  js.Fun buildFunction(tree_ir.FunctionDefinition function) {
    currentFunction = function.element;
    visitStatement(function.body);

    List<js.Parameter> parameters = new List<js.Parameter>();
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
    return new js.Fun(parameters, new js.Block(accumulator));
  }

  js.Expression visit(tree_ir.Expression node) {
    js.Expression result = node.accept(this);
    if (result == null) {
      glue.reportInternalError('$node did not produce code.');
    }
    return result;
  }

  /// Generates a name for the given variable. First trying with the name of
  /// the [Variable.element] if it is non-null.
  String getVariableName(tree_ir.Variable variable) {
    // TODO(sigurdm): Handle case where the variable belongs to an enclosing
    // function.
    if (variable.host != currentFunction) giveup(variable);

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
    return new js.Conditional(
        visit(node.condition),
        visit(node.thenExpression),
        visit(node.elseExpression));
  }

  js.Expression buildConstant(ConstantValue constant) {
    registry.registerCompileTimeConstant(constant);
    return glue.constantReference(constant);
  }

  @override
  js.Expression visitConstant(tree_ir.Constant node) {
    return buildConstant(node.expression.value);
  }

  @override
  js.Expression visitFunctionExpression(tree_ir.FunctionExpression node) {
    return giveup(node);
    // TODO: implement visitFunctionExpression
  }

  js.Expression compileConstant(ParameterElement parameter) {
    return buildConstant(glue.getConstantForVariable(parameter).value);
  }

  js.Expression buildStaticInvoke(Selector selector,
                                  Element target,
                                  List<tree_ir.Expression> arguments) {
    registry.registerStaticInvocation(target.declaration);

    js.Expression elementAccess = glue.elementAccess(target);
    List<js.Expression> compiledArguments =
        selector.makeArgumentsList(arguments, target.implementation,
            visitExpression,
            compileConstant);
    return new js.Call(elementAccess, compiledArguments);
  }

  @override
  js.Expression visitInvokeConstructor(tree_ir.InvokeConstructor node) {
    if (node.constant != null) return giveup(node);
    return buildStaticInvoke(node.selector, node.target, node.arguments);
  }

  void registerMethodInvoke(tree_ir.InvokeMethod node) {
    Selector selector = node.selector;
    // TODO(sigurdm): We should find a better place to register the call.
    Selector call = new Selector.callClosureFrom(selector);
    registry.registerDynamicInvocation(call);
    registry.registerDynamicInvocation(selector);
  }

  @override
  js.Expression visitInvokeMethod(tree_ir.InvokeMethod node) {
    // TODO(sigurdm): Handle intercepted invocations.
    if (glue.isIntercepted(node.selector)) giveup(node);
    js.Expression receiver = visitExpression(node.receiver);

    List<js.Expression> arguments = visitArguments(node.arguments);

    String methodName = glue.invocationName(node.selector);
    registerMethodInvoke(node);

    return js.propertyCall(receiver, methodName, arguments);
  }

  @override
  js.Expression visitInvokeStatic(tree_ir.InvokeStatic node) {
    return buildStaticInvoke(node.selector, node.target, node.arguments);
  }

  @override
  js.Expression visitInvokeSuperMethod(tree_ir.InvokeSuperMethod node) {
    return giveup(node);
    // TODO: implement visitInvokeSuperMethod
  }

  @override
  js.Expression visitLiteralList(tree_ir.LiteralList node) {
    registry.registerInstantiatedClass(glue.listClass);
    int length = node.values.length;
    List<js.ArrayElement> entries = new List<js.ArrayElement>.generate(length,
        (int i) => new js.ArrayElement(i, visitExpression(node.values[i])));
    return new js.ArrayInitializer(length, entries);
  }

  @override
  js.Expression visitLiteralMap(tree_ir.LiteralMap node) {
    return giveup(node);
    // TODO: implement visitLiteralMap
  }

  @override
  js.Expression visitLogicalOperator(tree_ir.LogicalOperator node) {
    return new js.Binary(node.operator, visit(node.left), visit(node.right));
  }

  @override
  js.Expression visitNot(tree_ir.Not node) {
    return new js.Prefix("!", visitExpression(node.operand));
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
    tree_ir.Statement fallthrough = this.fallthrough;
    if (node.target.binding == fallthrough) {
      // Fall through to continue target
    } else if (fallthrough is tree_ir.Continue &&
               fallthrough.target == node.target) {
      // Fall through to equivalent continue
    } else {
      usedLabels.add(node.target);
      accumulator.add(new js.Continue(node.target.name));
    }
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
    accumulator.add(new js.If(visitExpression(node.condition),
                              buildBody(node.thenStatement),
                              buildBody(node.elseStatement)));
  }

  @override
  void visitLabeledStatement(tree_ir.LabeledStatement node) {
    accumulator.add(buildLabeled(() => buildBody(node.body),
                                 node.label,
                                 node.next));
    visitStatement(node.next);
  }

  js.Statement buildLabeled(js.Statement buildBody(),
                tree_ir.Label label,
                tree_ir.Statement fallthroughStatement) {
    tree_ir.Statement savedFallthrough = fallthrough;
    fallthrough = fallthroughStatement;
    js.Statement result = buildBody();
    if (usedLabels.remove(label)) {
      result = new js.LabeledStatement(label.name, result);
    }
    fallthrough = savedFallthrough;
    return result;
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
    tree_ir.Statement fallthrough = this.fallthrough;
    if (node.target.binding.next == fallthrough) {
      // Fall through to break target
    } else if (fallthrough is tree_ir.Break &&
               fallthrough.target == node.target) {
      // Fall through to equivalent break
    } else {
      usedLabels.add(node.target);
      accumulator.add(new js.Break(node.target.name));
    }
  }

  /// Returns the current [accumulator] wrapped in a block if neccessary.
  js.Statement _bodyAsStatement() {
    if (accumulator.length == 0) {
      return new js.EmptyStatement();
    }
    if (accumulator.length == 1) {
      return accumulator.single;
    }
    return new js.Block(accumulator);
  }

  /// Builds a nested statement.
  js.Statement buildBody(tree_ir.Statement statement) {
    List<js.Statement> savedAccumulator = accumulator;
    accumulator = new List<js.Statement>();
    visitStatement(statement);
    js.Statement result = _bodyAsStatement();
    accumulator = savedAccumulator;
    return result;
  }

  js.Statement buildWhile(js.Expression condition,
                          tree_ir.Statement body,
                          tree_ir.Label label,
                          tree_ir.Statement fallthroughStatement) {
    return buildLabeled(() => new js.While(condition, buildBody(body)),
                        label,
                        fallthroughStatement);
  }

  @override
  void visitWhileCondition(tree_ir.WhileCondition node) {
    accumulator.add(
        buildWhile(visitExpression(node.condition),
                   node.body,
                   node.label,
                   node));
    visitStatement(node.next);
  }

  @override
  void visitWhileTrue(tree_ir.WhileTrue node) {
    accumulator.add(
        buildWhile(new js.LiteralBool(true), node.body, node.label, node));
  }

  @override
  void visitReturn(tree_ir.Return node) {
    accumulator.add(new js.Return(visitExpression(node.value)));
  }

}
