// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library code_generator;

import 'glue.dart';

import '../../tree_ir/tree_ir_nodes.dart' as tree_ir;
import '../../js/js.dart' as js;
import '../../elements/elements.dart';
import '../../io/source_information.dart' show SourceInformation;
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

  @override
  js.Expression visitExpression(tree_ir.Expression node) {
    js.Expression result = node.accept(this);
    if (result == null) {
      glue.reportInternalError('$node did not produce code.');
    }
    return result;
  }

  /// Generates a name for the given variable. First trying with the name of
  /// the [Variable.element] if it is non-null.
  String getVariableName(tree_ir.Variable variable) {
    // Functions are not nested in the JS backend.
    assert(variable.host == currentFunction);

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
    js.Expression addStrings(js.Expression left, js.Expression right) {
      return new js.Binary('+', left, right);
    }

    js.Expression toString(tree_ir.Expression input) {
      bool useDirectly = input is tree_ir.Constant &&
          (input.expression.value.isString ||
           input.expression.value.isInt ||
           input.expression.value.isBool);
      js.Expression value = visitExpression(input);
      if (useDirectly) {
        return value;
      } else {
        Element convertToString = glue.getStringConversion();
        registry.registerStaticUse(convertToString);
        js.Expression access = glue.staticFunctionAccess(convertToString);
        return (new js.Call(access, <js.Expression>[value]));
      }
    }

    return node.arguments.map(toString).reduce(addStrings);
  }

  @override
  js.Expression visitConditional(tree_ir.Conditional node) {
    return new js.Conditional(
        visitExpression(node.condition),
        visitExpression(node.thenExpression),
        visitExpression(node.elseExpression));
  }

  js.Expression buildConstant(ConstantValue constant) {
    registry.registerCompileTimeConstant(constant);
    return glue.constantReference(constant);
  }

  @override
  js.Expression visitConstant(tree_ir.Constant node) {
    return buildConstant(node.expression.value);
  }

  js.Expression compileConstant(ParameterElement parameter) {
    return buildConstant(glue.getConstantForVariable(parameter).value);
  }

  // TODO(karlklose): get rid of the selector argument.
  js.Expression buildStaticInvoke(Selector selector,
                                  Element target,
                                  List<js.Expression> arguments,
                                  {SourceInformation sourceInformation}) {
    registry.registerStaticInvocation(target.declaration);
    if (target == glue.getInterceptorMethod) {
      // This generates a call to the specialized interceptor function, which
      // does not have a specialized element yet, but is emitted as a stub from
      // the emitter in [InterceptorStubGenerator].
      // TODO(karlklose): Either change [InvokeStatic] to take an [Entity]
      //   instead of an [Element] and model the getInterceptor functions as
      //   [Entity]s or add a specialized Tree-IR node for interceptor calls.
      registry.registerUseInterceptor();
      js.VariableUse interceptorLibrary = glue.getInterceptorLibrary();
      return js.propertyCall(interceptorLibrary, selector.name, arguments);
    } else {
      js.Expression elementAccess = glue.staticFunctionAccess(target);
      return new js.Call(elementAccess, arguments,
          sourceInformation: sourceInformation);
    }
  }

  @override
  js.Expression visitInvokeConstructor(tree_ir.InvokeConstructor node) {
    checkStaticTargetIsValid(node, node.target);

    if (node.constant != null) return giveup(node);
    registry.registerInstantiatedClass(node.target.enclosingClass);
    Selector selector = node.selector;
    FunctionElement target = node.target;
    List<js.Expression> arguments = visitArguments(node.arguments);
    return buildStaticInvoke(selector, target, arguments);
  }

  void registerMethodInvoke(tree_ir.InvokeMethod node) {
    Selector selector = node.selector;
    if (selector.isGetter) {
      registry.registerDynamicGetter(selector);
    } else if (selector.isSetter) {
      registry.registerDynamicSetter(selector);
    } else {
      assert(invariant(CURRENT_ELEMENT_SPANNABLE,
          selector.isCall || selector.isOperator || selector.isIndex,
          message: 'unexpected kind ${selector.kind}'));
      // TODO(sigurdm): We should find a better place to register the call.
      Selector call = new Selector.callClosureFrom(selector);
      registry.registerDynamicInvocation(call);
      registry.registerDynamicInvocation(selector);
    }
  }

  @override
  js.Expression visitInvokeMethod(tree_ir.InvokeMethod node) {
    registerMethodInvoke(node);
    return js.propertyCall(visitExpression(node.receiver),
                           glue.invocationName(node.selector),
                           visitArguments(node.arguments));
  }

  /// Checks that the target of the static call is not an [ErroneousElement].
  ///
  /// This helper should be removed and the code to generate the CPS IR for
  /// the dart2js backend should construct a call to a helper that throw an
  /// appropriate error message instead of the static call.
  ///
  /// See [SsaBuilder.visitStaticSend] as an example how to do this.
  void checkStaticTargetIsValid(tree_ir.Node node, Element target) {
    if (target.isErroneous) {
      giveup(node, 'cannot generate error handling code'
                   ' for call to unresolved target');
    }
  }

  @override
  js.Expression visitInvokeStatic(tree_ir.InvokeStatic node) {
    checkStaticTargetIsValid(node, node.target);

    if (node.target is! FunctionElement) {
      giveup(node, 'static getters and setters are not supported.');
    }
    Selector selector = node.selector;
    FunctionElement target = node.target;
    List<js.Expression> arguments = visitArguments(node.arguments);
    return buildStaticInvoke(selector, target, arguments,
        sourceInformation: node.sourceInformation);
  }

  @override
  js.Expression visitInvokeMethodDirectly(tree_ir.InvokeMethodDirectly node) {
    registry.registerDirectInvocation(node.target.declaration);
    if (node.target is ConstructorBodyElement) {
      // A constructor body cannot be overriden or intercepted, so we can
      // use the short form for this invocation.
      return js.js('#.#(#)',
          [visitExpression(node.receiver),
           glue.instanceMethodName(node.target),
           visitArguments(node.arguments)]);
    }
    return js.js('#.#.call(#, #)',
        [glue.prototypeAccess(node.target.enclosingClass),
         glue.invocationName(node.selector),
         visitExpression(node.receiver),
         visitArguments(node.arguments)]);
  }

  @override
  js.Expression visitLiteralList(tree_ir.LiteralList node) {
    registry.registerInstantiatedClass(glue.listClass);
    int length = node.values.length;
    List<js.Expression> entries = node.values.map(visitExpression).toList();
    return new js.ArrayInitializer(entries);
  }

  @override
  js.Expression visitLiteralMap(tree_ir.LiteralMap node) {
    ConstructorElement constructor;
    if (node.entries.isEmpty) {
      constructor = glue.mapLiteralConstructorEmpty;
    } else {
      constructor = glue.mapLiteralConstructor;
    }
    List<js.Expression> entries =
        new List<js.Expression>(2 * node.entries.length);
    for (int i = 0; i < node.entries.length; i++) {
      entries[2 * i] = visitExpression(node.entries[i].key);
      entries[2 * i + 1] = visitExpression(node.entries[i].value);
    }
    List<js.Expression> args = entries.isEmpty
         ? <js.Expression>[]
         : <js.Expression>[new js.ArrayInitializer(entries)];
    return buildStaticInvoke(
        new Selector.call(constructor.name, constructor.library, 2),
        constructor,
        args);
  }

  @override
  js.Expression visitLogicalOperator(tree_ir.LogicalOperator node) {
    return new js.Binary(
        node.operator,
        visitExpression(node.left),
        visitExpression(node.right));
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
    return new js.This();
  }

  @override
  js.Expression visitTypeOperator(tree_ir.TypeOperator node) {
    return giveup(node);
    // TODO: implement visitTypeOperator
  }

  @override
  js.Expression visitVariableUse(tree_ir.VariableUse node) {
    return buildVariableAccess(node.variable);
  }

  js.Expression buildVariableAccess(tree_ir.Variable variable) {
    return new js.VariableUse(getVariableName(variable));
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
        buildVariableAccess(node.variable),
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

  @override
  void visitTry(tree_ir.Try node) {
    // TODO(kmillikin): implement TryStatement.
    return giveup(node);
  }

  @override
  js.Expression visitCreateBox(tree_ir.CreateBox node) {
    return new js.ObjectInitializer([]);
  }

  @override
  js.Expression visitCreateInstance(tree_ir.CreateInstance node) {
    registry.registerInstantiatedClass(node.classElement);
    return new js.New(glue.constructorAccess(node.classElement),
                      node.arguments.map(visitExpression).toList());
  }

  @override
  js.Expression visitGetField(tree_ir.GetField node) {
    return new js.PropertyAccess.field(
        visitExpression(node.object),
        glue.instanceFieldPropertyName(node.field));
  }

  @override
  void visitSetField(tree_ir.SetField node) {
    js.PropertyAccess field =
        new js.PropertyAccess.field(
            visitExpression(node.object),
            glue.instanceFieldPropertyName(node.field));
    js.Assignment asn = new js.Assignment(field, visitExpression(node.value));
    accumulator.add(new js.ExpressionStatement(asn));
    visitStatement(node.next);
  }

  // Dart-specific IR nodes

  @override
  visitFunctionExpression(tree_ir.FunctionExpression node) {
    return errorUnsupportedNode(node);
  }

  @override
  visitFunctionDeclaration(tree_ir.FunctionDeclaration node) {
    return errorUnsupportedNode(node);
  }

  @override
  visitFieldInitializer(tree_ir.FieldInitializer node) {
    return errorUnsupportedNode(node);
  }

  @override
  visitSuperInitializer(tree_ir.SuperInitializer node) {
    return errorUnsupportedNode(node);
  }

  dynamic errorUnsupportedNode(tree_ir.DartSpecificNode node) {
    throw "Unsupported node in JS backend: $node";
  }
}
