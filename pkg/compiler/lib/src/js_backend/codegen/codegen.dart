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
import '../../dart_types.dart';

class CodegenBailout {
  final tree_ir.Node node;
  final String reason;
  CodegenBailout(this.node, this.reason);
  String get message {
    return 'bailout${node != null ? " on $node" : ""}: $reason';
  }
}

class CodeGenerator extends tree_ir.StatementVisitor
                    with tree_ir.ExpressionVisitor<js.Expression> {
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
    Set<String> declaredVariables = new Set<String>();

    for (tree_ir.Variable parameter in function.parameters) {
      String name = getVariableName(parameter);
      parameters.add(new js.Parameter(name));
      parameterSet.add(parameter);
      declaredVariables.add(name);
    }

    List<js.VariableInitialization> jsVariables = <js.VariableInitialization>[];

    // Declare variables with an initializer. Pull statements into the
    // initializer until we find a statement that cannot be pulled in.
    int accumulatorIndex = 0;
    while (accumulatorIndex < accumulator.length) {
      js.Node node = accumulator[accumulatorIndex];

      // Check that node is an assignment to a local variable.
      if (node is! js.ExpressionStatement) break;
      js.ExpressionStatement stmt = node;
      if (stmt.expression is! js.Assignment) break;
      js.Assignment assign = stmt.expression;
      if (assign.leftHandSide is! js.VariableUse) break;
      if (assign.op != null) break; // Compound assignment.
      js.VariableUse use = assign.leftHandSide;

      // We cannot declare a variable more than once.
      if (!declaredVariables.add(use.name)) break;

      js.VariableInitialization jsVariable = new js.VariableInitialization(
        new js.VariableDeclaration(use.name),
        assign.value);
      jsVariables.add(jsVariable);

      ++accumulatorIndex;
    }

    // Discard the statements that were pulled in the initializer.
    if (accumulatorIndex > 0) {
      accumulator = accumulator.sublist(accumulatorIndex);
    }

    // Declare remaining variables.
    for (tree_ir.Variable variable in variableNames.keys) {
      String name = getVariableName(variable);
      if (declaredVariables.contains(name)) continue;
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

  List<js.Expression> visitExpressionList(
      List<tree_ir.Expression> expressions) {
    return new List<js.Expression>.generate(expressions.length,
        (int index) => visitExpression(expressions[index]),
        growable: false);
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
          (input.value.isString ||
           input.value.isInt ||
           input.value.isBool);
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
    return buildConstant(node.value);
  }

  js.Expression compileConstant(ParameterElement parameter) {
    return buildConstant(glue.getConstantValueForVariable(parameter));
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
    if (node.constant != null) return giveup(node);

    registry.registerInstantiatedType(node.type);
    Selector selector = node.selector;
    FunctionElement target = node.target;
    List<js.Expression> arguments = visitExpressionList(node.arguments);
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
          selector.isCall || selector.isOperator ||
          selector.isIndex || selector.isIndexSet,
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
                           visitExpressionList(node.arguments));
  }

  @override
  js.Expression visitInvokeStatic(tree_ir.InvokeStatic node) {
    Selector selector = node.selector;
    assert(selector.isGetter || selector.isSetter || selector.isCall);
    FunctionElement target = node.target;
    List<js.Expression> arguments = visitExpressionList(node.arguments);
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
           visitExpressionList(node.arguments)]);
    }
    return js.js('#.#.call(#, #)',
        [glue.prototypeAccess(node.target.enclosingClass),
         glue.invocationName(node.selector),
         visitExpression(node.receiver),
         visitExpressionList(node.arguments)]);
  }

  @override
  js.Expression visitLiteralList(tree_ir.LiteralList node) {
    registry.registerInstantiatedClass(glue.listClass);
    List<js.Expression> entries = visitExpressionList(node.values);
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
  js.Expression visitThis(tree_ir.This node) {
    return new js.This();
  }

  @override
  js.Expression visitTypeOperator(tree_ir.TypeOperator node) {
    js.Expression value = visitExpression(node.value);
    List<js.Expression> typeArguments = visitExpressionList(node.typeArguments);
    if (!node.isTypeTest) {
      giveup(node, 'type casts not implemented.');
    }
    DartType type = node.type;
    // Note that the trivial (but special) cases of Object, dynamic, and Null
    // are handled at build-time and must not occur in a TypeOperator.
    assert(!type.isObject && !type.isDynamic);
    if (type is InterfaceType) {
      glue.registerIsCheck(type, registry);
      ClassElement clazz = type.element;

      // We use the helper:
      //
      //     checkSubtype(value, $isT, typeArgs, $asT)
      //
      // Any of the last two arguments may be null if there are no type
      // arguments, and/or if no substitution is required.

      js.Expression isT = js.string(glue.getTypeTestTag(type));

      js.Expression typeArgumentArray = typeArguments.isNotEmpty
          ? new js.ArrayInitializer(typeArguments)
          : new js.LiteralNull();

      js.Expression asT = glue.hasStrictSubtype(clazz)
          ? js.string(glue.getTypeSubstitutionTag(clazz))
          : new js.LiteralNull();

      return buildStaticHelperInvocation(
          glue.getCheckSubtype(),
          <js.Expression>[value, isT, typeArgumentArray, asT]);
    } else if (type is TypeVariableType) {
      glue.registerIsCheck(type, registry);
      // The only type argument is the type held in the type variable.
      js.Expression typeValue = typeArguments.single;
      return buildStaticHelperInvocation(
          glue.getCheckSubtypeOfRuntime(),
          <js.Expression>[value, typeValue]);
    }
    return giveup(node, 'type check unimplemented for $type.');
  }

  @override
  js.Expression visitVariableUse(tree_ir.VariableUse node) {
    return buildVariableAccess(node.variable);
  }

  js.Expression buildVariableAccess(tree_ir.Variable variable) {
    return new js.VariableUse(getVariableName(variable));
  }

  @override
  js.Expression visitAssign(tree_ir.Assign node) {
    return new js.Assignment(
        buildVariableAccess(node.variable),
        visitExpression(node.value));
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
                              buildBodyStatement(node.thenStatement),
                              buildBodyStatement(node.elseStatement)));
  }

  @override
  void visitLabeledStatement(tree_ir.LabeledStatement node) {
    accumulator.add(buildLabeled(() => buildBodyStatement(node.body),
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
  js.Statement buildBodyStatement(tree_ir.Statement statement) {
    List<js.Statement> savedAccumulator = accumulator;
    accumulator = <js.Statement>[];
    visitStatement(statement);
    js.Statement result = _bodyAsStatement();
    accumulator = savedAccumulator;
    return result;
  }

  js.Block buildBodyBlock(tree_ir.Statement statement) {
    List<js.Statement> savedAccumulator = accumulator;
    accumulator = <js.Statement>[];
    visitStatement(statement);
    js.Statement result = new js.Block(accumulator);
    accumulator = savedAccumulator;
    return result;
  }

  js.Statement buildWhile(js.Expression condition,
                          tree_ir.Statement body,
                          tree_ir.Label label,
                          tree_ir.Statement fallthroughStatement) {
    return buildLabeled(() => new js.While(condition, buildBodyStatement(body)),
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
  void visitThrow(tree_ir.Throw node) {
    accumulator.add(new js.Throw(visitExpression(node.value)));
  }

  @override
  void visitRethrow(tree_ir.Rethrow node) {
    glue.reportInternalError('rethrow seen in JavaScript output');
  }

  @override
  void visitTry(tree_ir.Try node) {
    js.Block tryBlock = buildBodyBlock(node.tryBody);
    tree_ir.Variable exceptionVariable = node.catchParameters.first;
    js.VariableDeclaration exceptionParameter =
        new js.VariableDeclaration(getVariableName(exceptionVariable));
    js.Block catchBlock = buildBodyBlock(node.catchBody);
    js.Catch catchPart = new js.Catch(exceptionParameter, catchBlock);
    accumulator.add(new js.Try(tryBlock, catchPart, null));
  }

  @override
  js.Expression visitCreateBox(tree_ir.CreateBox node) {
    return new js.ObjectInitializer(const <js.Property>[]);
  }

  @override
  js.Expression visitCreateInstance(tree_ir.CreateInstance node) {
    ClassElement cls = node.classElement;
    // TODO(asgerf): To allow inlining of InvokeConstructor, CreateInstance must
    //               carry a DartType so we can register the instantiated type
    //               with its type arguments. Otherwise dataflow analysis is
    //               needed to reconstruct the instantiated type.
    registry.registerInstantiatedClass(cls);
    js.Expression instance = new js.New(
        glue.constructorAccess(cls),
        visitExpressionList(node.arguments));

    List<tree_ir.Expression> typeInformation = node.typeInformation;
    assert(typeInformation.isEmpty ||
        typeInformation.length == cls.typeVariables.length);
    if (typeInformation.isNotEmpty) {
      FunctionElement helper = glue.getAddRuntimeTypeInformation();
      js.Expression typeArguments = new js.ArrayInitializer(
          visitExpressionList(typeInformation));
      return buildStaticHelperInvocation(helper,
          <js.Expression>[instance, typeArguments]);
    } else {
      return instance;
    }
  }

  @override
  js.Expression visitCreateInvocationMirror(
      tree_ir.CreateInvocationMirror node) {
    js.Expression name = js.string(node.selector.name);
    js.Expression internalName = js.string(glue.invocationName(node.selector));
    js.Expression kind = js.number(node.selector.invocationMirrorKind);
    js.Expression arguments = new js.ArrayInitializer(
        visitExpressionList(node.arguments));
    js.Expression argumentNames = new js.ArrayInitializer(
        node.selector.namedArguments.map(js.string).toList(growable: false));
    return buildStaticHelperInvocation(glue.createInvocationMirrorMethod,
        [name, internalName, kind, arguments, argumentNames]);
  }

  @override
  js.Expression visitGetField(tree_ir.GetField node) {
    return new js.PropertyAccess.field(
        visitExpression(node.object),
        glue.instanceFieldPropertyName(node.field));
  }

  @override
  js.Assignment visitSetField(tree_ir.SetField node) {
    js.PropertyAccess field =
        new js.PropertyAccess.field(
            visitExpression(node.object),
            glue.instanceFieldPropertyName(node.field));
    return new js.Assignment(field, visitExpression(node.value));
  }

  @override
  js.Expression visitGetStatic(tree_ir.GetStatic node) {
    assert(node.element is FieldElement || node.element is FunctionElement);
    if (node.element is FunctionElement) {
      // Tear off a method.
      registry.registerGetOfStaticFunction(node.element.declaration);
      return glue.isolateStaticClosureAccess(node.element);
    }
    if (glue.isLazilyInitialized(node.element)) {
      // Read a lazily initialized field.
      registry.registerStaticUse(node.element.declaration);
      js.Expression getter = glue.isolateLazyInitializerAccess(node.element);
      return new js.Call(getter, <js.Expression>[],
          sourceInformation: node.sourceInformation);
    }
    // Read an eagerly initialized field.
    registry.registerStaticUse(node.element.declaration);
    return glue.staticFieldAccess(node.element);
  }

  @override
  js.Expression visitSetStatic(tree_ir.SetStatic node) {
    assert(node.element is FieldElement);
    registry.registerStaticUse(node.element.declaration);
    js.Expression field = glue.staticFieldAccess(node.element);
    js.Expression value = visitExpression(node.value);
    return new js.Assignment(field, value);
  }

  js.Expression buildStaticHelperInvocation(FunctionElement helper,
                                            List<js.Expression> arguments) {
    registry.registerStaticUse(helper);
    return buildStaticInvoke(new Selector.fromElement(helper), helper,
        arguments);
  }

  @override
  js.Expression visitReifyRuntimeType(tree_ir.ReifyRuntimeType node) {
    FunctionElement createType = glue.getCreateRuntimeType();
    FunctionElement typeToString = glue.getRuntimeTypeToString();
    return buildStaticHelperInvocation(createType,
        [buildStaticHelperInvocation(typeToString,
            [visitExpression(node.value)])]);
  }

  @override
  js.Expression visitReadTypeVariable(tree_ir.ReadTypeVariable node) {
    ClassElement context = node.variable.element.enclosingClass;
    js.Expression index = js.number(glue.getTypeVariableIndex(node.variable));
    if (glue.needsSubstitutionForTypeVariableAccess(context)) {
      js.Expression typeName = glue.getRuntimeTypeName(context);
      return buildStaticHelperInvocation(
          glue.getRuntimeTypeArgument(),
          [visitExpression(node.target), typeName, index]);
    } else {
      return buildStaticHelperInvocation(
          glue.getTypeArgumentByIndex(),
          [visitExpression(node.target), index]);
    }
  }

  @override
  js.Expression visitTypeExpression(tree_ir.TypeExpression node) {
    List<js.Expression> arguments = visitExpressionList(node.arguments);
    return glue.generateTypeRepresentation(node.dartType, arguments);
  }

  visitFunctionExpression(tree_ir.FunctionExpression node) {
    // FunctionExpressions are currently unused.
    // We might need them if we want to emit raw JS nested functions.
    throw 'FunctionExpressions should not be used';
  }
}
