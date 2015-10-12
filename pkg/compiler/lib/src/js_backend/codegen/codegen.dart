// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library code_generator;

import 'glue.dart';

import '../../closure.dart' show
    ClosureClassElement;
import '../../common.dart';
import '../../common/codegen.dart' show
    CodegenRegistry;
import '../../constants/values.dart';
import '../../dart_types.dart';
import '../../elements/elements.dart';
import '../../io/source_information.dart' show
    SourceInformation;
import '../../js/js.dart' as js;
import '../../tree_ir/tree_ir_nodes.dart' as tree_ir;
import '../../tree_ir/tree_ir_nodes.dart' show
    BuiltinMethod,
    BuiltinOperator;
import '../../types/types.dart' show
    TypeMask;
import '../../universe/selector.dart' show
    Selector;
import '../../universe/universe.dart' show
    UniverseSelector;
import '../../util/maplet.dart';

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

  final tree_ir.FallthroughStack fallthrough = new tree_ir.FallthroughStack();

  /// Stacks whose top element is the current target of an unlabeled break
  /// or continue. For continues, this is the loop node itself.
  final tree_ir.FallthroughStack shortBreak = new tree_ir.FallthroughStack();
  final tree_ir.FallthroughStack shortContinue =
      new tree_ir.FallthroughStack();

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

    // If the last statement is a for loop with an initializer expression, try
    // to pull that expression into an initializer as well.
    pullFromForLoop:
    if (accumulatorIndex < accumulator.length &&
        accumulator[accumulatorIndex] is js.For) {
      js.For forLoop = accumulator[accumulatorIndex];
      if (forLoop.init is! js.Assignment) break pullFromForLoop;
      js.Assignment assign = forLoop.init;
      if (assign.leftHandSide is! js.VariableUse) break pullFromForLoop;
      if (assign.op != null) break pullFromForLoop; // Compound assignment.
      js.VariableUse use = assign.leftHandSide;

      // We cannot declare a variable more than once.
      if (!declaredVariables.add(use.name)) break pullFromForLoop;

      js.VariableInitialization jsVariable = new js.VariableInitialization(
        new js.VariableDeclaration(use.name),
        assign.value);
      jsVariables.add(jsVariable);

      // Remove the initializer from the for loop.
      accumulator[accumulatorIndex] =
          new js.For(null, forLoop.condition, forLoop.update, forLoop.body);
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
  js.Expression visitConditional(tree_ir.Conditional node) {
    return new js.Conditional(
        visitExpression(node.condition),
        visitExpression(node.thenExpression),
        visitExpression(node.elseExpression));
  }

  js.Expression buildConstant(ConstantValue constant,
                              {SourceInformation sourceInformation}) {
    registry.registerCompileTimeConstant(constant);
    return glue.constantReference(constant)
        .withSourceInformation(sourceInformation);
  }

  @override
  js.Expression visitConstant(tree_ir.Constant node) {
    return buildConstant(
        node.value,
        sourceInformation: node.sourceInformation);
  }

  js.Expression buildStaticInvoke(Element target,
                                  List<js.Expression> arguments,
                                  {SourceInformation sourceInformation}) {
    registry.registerStaticInvocation(target.declaration);
    js.Expression elementAccess = glue.staticFunctionAccess(target);
    return new js.Call(elementAccess, arguments,
        sourceInformation: sourceInformation);
  }

  @override
  js.Expression visitInvokeConstructor(tree_ir.InvokeConstructor node) {
    if (node.constant != null) return giveup(node);

    registry.registerInstantiatedType(node.type);
    FunctionElement target = node.target;
    List<js.Expression> arguments = visitExpressionList(node.arguments);
    return buildStaticInvoke(
        target, arguments, sourceInformation: node.sourceInformation);
  }

  void registerMethodInvoke(tree_ir.InvokeMethod node) {
    Selector selector = node.selector;
    TypeMask mask = node.mask;
    if (selector.isGetter) {
      registry.registerDynamicGetter(new UniverseSelector(selector, mask));
    } else if (selector.isSetter) {
      registry.registerDynamicSetter(new UniverseSelector(selector, mask));
    } else {
      assert(invariant(CURRENT_ELEMENT_SPANNABLE,
          selector.isCall || selector.isOperator ||
          selector.isIndex || selector.isIndexSet,
          message: 'unexpected kind ${selector.kind}'));
      // TODO(sigurdm): We should find a better place to register the call.
      Selector call = new Selector.callClosureFrom(selector);
      registry.registerDynamicInvocation(new UniverseSelector(call, null));
      registry.registerDynamicInvocation(new UniverseSelector(selector, mask));
    }
  }

  @override
  js.Expression visitInvokeMethod(tree_ir.InvokeMethod node) {
    registerMethodInvoke(node);
    return js.propertyCall(visitExpression(node.receiver),
                           glue.invocationName(node.selector),
                           visitExpressionList(node.arguments))
        .withSourceInformation(node.sourceInformation);
  }

  @override
  js.Expression visitInvokeStatic(tree_ir.InvokeStatic node) {
    FunctionElement target = node.target;
    List<js.Expression> arguments = visitExpressionList(node.arguments);
    return buildStaticInvoke(target, arguments,
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
           visitExpressionList(node.arguments)])
          .withSourceInformation(node.sourceInformation);
    }
    return js.js('#.#.call(#, #)',
        [glue.prototypeAccess(node.target.enclosingClass),
         glue.invocationName(node.selector),
         visitExpression(node.receiver),
         visitExpressionList(node.arguments)])
        .withSourceInformation(node.sourceInformation);
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
    return buildStaticInvoke(constructor, args);
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
    DartType type = node.type;
    if (type is InterfaceType) {
      glue.registerIsCheck(type, registry);
      ClassElement clazz = type.element;

      if (glue.isStringClass(clazz)) {
        if (node.isTypeTest) {
          return js.js(r'typeof # === "string"', <js.Expression>[value]);
        }
        // TODO(sra): Implement fast cast via calling 'stringTypeCast'.
      } else if (glue.isBoolClass(clazz)) {
        if (node.isTypeTest) {
          return js.js(r'typeof # === "boolean"', <js.Expression>[value]);
        }
        // TODO(sra): Implement fast cast via calling 'boolTypeCast'.
      }

      // The helper we use needs the JSArray class to exist, but for some
      // reason the helper does not cause this dependency to be registered.
      // TODO(asgerf): Most programs need List anyway, but we should fix this.
      registry.registerInstantiatedClass(glue.listClass);

      // We use one of the two helpers:
      //
      //     checkSubtype(value, $isT, typeArgs, $asT)
      //     subtypeCast(value, $isT, typeArgs, $asT)
      //
      // Any of the last two arguments may be null if there are no type
      // arguments, and/or if no substitution is required.
      Element function = node.isTypeTest
          ? glue.getCheckSubtype()
          : glue.getSubtypeCast();

      js.Expression isT = js.quoteName(glue.getTypeTestTag(type));

      js.Expression typeArgumentArray = typeArguments.isNotEmpty
          ? new js.ArrayInitializer(typeArguments)
          : new js.LiteralNull();

      js.Expression asT = glue.hasStrictSubtype(clazz)
          ? js.quoteName(glue.getTypeSubstitutionTag(clazz))
          : new js.LiteralNull();

      return buildStaticHelperInvocation(
          function,
          <js.Expression>[value, isT, typeArgumentArray, asT]);
    } else if (type is TypeVariableType || type is FunctionType) {
      glue.registerIsCheck(type, registry);

      Element function = node.isTypeTest
          ? glue.getCheckSubtypeOfRuntimeType()
          : glue.getSubtypeOfRuntimeTypeCast();

      // The only type argument is the type held in the type variable.
      js.Expression typeValue = typeArguments.single;

      return buildStaticHelperInvocation(
          function,
          <js.Expression>[value, typeValue]);
    }
    return giveup(node, 'type check unimplemented for $type.');
  }

  @override
  js.Expression visitGetTypeTestProperty(tree_ir.GetTypeTestProperty node) {
    js.Expression object = visitExpression(node.object);
    DartType dartType = node.dartType;
    assert(dartType.isInterfaceType);
    glue.registerIsCheck(dartType, registry);
    js.Expression property = glue.getTypeTestTag(dartType);
    return js.js(r'#.#', [object, property]);
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
    tree_ir.Statement next = fallthrough.target;
    if (node.target.binding == next ||
        next is tree_ir.Continue && node.target == next.target) {
      // Fall through to continue target or to equivalent continue.
      fallthrough.use();
    } else if (node.target.binding == shortContinue.target) {
      // The target is the immediately enclosing loop.
      shortContinue.use();
      accumulator.add(new js.Continue(null));
    } else {
      usedLabels.add(node.target);
      accumulator.add(new js.Continue(node.target.name));
    }
  }

  /// True if [other] is the target of [node] or is a [Break] with the same
  /// target. This means jumping to [other] is equivalent to executing [node].
  bool isEffectiveBreakTarget(tree_ir.Break node, tree_ir.Statement other) {
    return node.target.binding.next == other ||
           other is tree_ir.Break && node.target == other.target;
  }

  @override
  void visitBreak(tree_ir.Break node) {
    if (isEffectiveBreakTarget(node, fallthrough.target)) {
      // Fall through to break target or to equivalent break.
      fallthrough.use();
    } else if (isEffectiveBreakTarget(node, shortBreak.target)) {
      // Unlabeled break to the break target or to an equivalent break.
      shortBreak.use();
      accumulator.add(new js.Break(null));
    } else {
      usedLabels.add(node.target);
      accumulator.add(new js.Break(node.target.name));
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
    js.Expression condition = visitExpression(node.condition);
    int usesBefore = fallthrough.useCount;
    js.Statement thenBody = buildBodyStatement(node.thenStatement);
    bool thenHasFallthrough = (fallthrough.useCount > usesBefore);
    if (thenHasFallthrough) {
      js.Statement elseBody = buildBodyStatement(node.elseStatement);
      accumulator.add(new js.If(condition, thenBody, elseBody));
    } else {
      // The 'then' body cannot complete normally, so emit a short 'if'
      // and put the 'else' body after it.
      accumulator.add(new js.If.noElse(condition, thenBody));
      visitStatement(node.elseStatement);
    }
  }

  @override
  void visitLabeledStatement(tree_ir.LabeledStatement node) {
    fallthrough.push(node.next);
    js.Statement body = buildBodyStatement(node.body);
    fallthrough.pop();
    accumulator.add(insertLabel(node.label, body));
    visitStatement(node.next);
  }

  /// Wraps a node in a labeled statement unless the label is unused.
  js.Statement insertLabel(tree_ir.Label label, js.Statement node) {
    if (usedLabels.remove(label)) {
      return new js.LabeledStatement(label.name, node);
    } else {
      return node;
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

  js.Expression makeSequence(List<tree_ir.Expression> list) {
    return list.map(visitExpression).reduce((x,y) => new js.Binary(',', x, y));
  }

  @override
  void visitFor(tree_ir.For node) {
    js.Expression condition = visitExpression(node.condition);
    shortBreak.push(node.next);
    shortContinue.push(node);
    fallthrough.push(node);
    js.Statement body = buildBodyStatement(node.body);
    fallthrough.pop();
    shortContinue.pop();
    shortBreak.pop();
    js.Statement loopNode;
    if (node.updates.isEmpty) {
      loopNode = new js.While(condition, body);
    } else { // Compile as a for loop.
      js.Expression init;
      if (accumulator.isNotEmpty &&
          accumulator.last is js.ExpressionStatement) {
        // Take the preceding expression from the accumulator and use
        // it as the initializer expression.
        js.ExpressionStatement initStmt = accumulator.removeLast();
        init = initStmt.expression;
      }
      js.Expression update = makeSequence(node.updates);
      loopNode = new js.For(init, condition, update, body);
    }
    accumulator.add(insertLabel(node.label, loopNode));
    visitStatement(node.next);
  }

  @override
  void visitWhileTrue(tree_ir.WhileTrue node) {
    js.Expression condition = new js.LiteralBool(true);
    // A short break in the while will jump to the current fallthrough target.
    shortBreak.push(fallthrough.target);
    shortContinue.push(node);
    fallthrough.push(node);
    js.Statement jsBody = buildBodyStatement(node.body);
    fallthrough.pop();
    shortContinue.pop();
    if (shortBreak.useCount > 0) {
      // Short breaks use the current fallthrough target.
      fallthrough.use();
    }
    shortBreak.pop();
    accumulator.add(insertLabel(node.label, new js.While(condition, jsBody)));
  }

  bool isNull(tree_ir.Expression node) {
    return node is tree_ir.Constant && node.value.isNull;
  }

  @override
  void visitReturn(tree_ir.Return node) {
    if (isNull(node.value) && fallthrough.target == null) {
      // Do nothing. Implicitly return JS undefined by falling over the end.
      registry.registerCompileTimeConstant(new NullConstantValue());
      fallthrough.use();
    } else {
      accumulator.add(new js.Return(visitExpression(node.value))
            .withSourceInformation(node.sourceInformation));
    }
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
  void visitUnreachable(tree_ir.Unreachable node) {
    // Output nothing.
    // TODO(asgerf): Emit a throw/return to assist local analysis in the VM?
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
    ClassElement classElement = node.classElement;
    // TODO(asgerf): To allow inlining of InvokeConstructor, CreateInstance must
    //               carry a DartType so we can register the instantiated type
    //               with its type arguments. Otherwise dataflow analysis is
    //               needed to reconstruct the instantiated type.
    registry.registerInstantiatedClass(classElement);
    if (classElement is ClosureClassElement) {
      registry.registerInstantiatedClosure(classElement.methodElement);
    }
    js.Expression instance = new js.New(
        glue.constructorAccess(classElement),
        visitExpressionList(node.arguments))
        .withSourceInformation(node.sourceInformation);

    List<tree_ir.Expression> typeInformation = node.typeInformation;
    assert(typeInformation.isEmpty ||
        typeInformation.length == classElement.typeVariables.length);
    if (typeInformation.isNotEmpty) {
      FunctionElement helper = glue.getAddRuntimeTypeInformation();
      js.Expression typeArguments = new js.ArrayInitializer(
          visitExpressionList(typeInformation));
      return buildStaticHelperInvocation(helper,
          <js.Expression>[instance, typeArguments],
          sourceInformation: node.sourceInformation);
    } else {
      return instance;
    }
  }

  @override
  js.Expression visitCreateInvocationMirror(
      tree_ir.CreateInvocationMirror node) {
    js.Expression name = js.string(node.selector.name);
    js.Expression internalName =
        js.quoteName(glue.invocationName(node.selector));
    js.Expression kind = js.number(node.selector.invocationMirrorKind);
    js.Expression arguments = new js.ArrayInitializer(
        visitExpressionList(node.arguments));
    js.Expression argumentNames = new js.ArrayInitializer(
        node.selector.namedArguments.map(js.string).toList(growable: false));
    return buildStaticHelperInvocation(glue.createInvocationMirrorMethod,
        <js.Expression>[name, internalName, kind, arguments, argumentNames]);
  }

  @override
  js.Expression visitInterceptor(tree_ir.Interceptor node) {
    glue.registerUseInterceptorInCodegen();
    registry.registerSpecializedGetInterceptor(node.interceptedClasses);
    js.Name helperName = glue.getInterceptorName(node.interceptedClasses);
    js.Expression globalHolder = glue.getInterceptorLibrary();
    return js.js('#.#(#)',
        [globalHolder, helperName, visitExpression(node.input)])
            .withSourceInformation(node.sourceInformation);
  }

  @override
  js.Expression visitGetField(tree_ir.GetField node) {
    registry.registerFieldGetter(node.field);
    return new js.PropertyAccess(
        visitExpression(node.object),
        glue.instanceFieldPropertyName(node.field));
  }

  @override
  js.Assignment visitSetField(tree_ir.SetField node) {
    registry.registerFieldSetter(node.field);
    js.PropertyAccess field =
        new js.PropertyAccess(
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

  @override
  js.Expression visitGetLength(tree_ir.GetLength node) {
    return new js.PropertyAccess.field(visitExpression(node.object), 'length');
  }

  @override
  js.Expression visitGetIndex(tree_ir.GetIndex node) {
    return new js.PropertyAccess(
        visitExpression(node.object),
        visitExpression(node.index));
  }

  @override
  js.Expression visitSetIndex(tree_ir.SetIndex node) {
    return js.js('#[#] = #',
        [visitExpression(node.object),
         visitExpression(node.index),
         visitExpression(node.value)]);
  }

  js.Expression buildStaticHelperInvocation(
      FunctionElement helper,
      List<js.Expression> arguments,
      {SourceInformation sourceInformation}) {
    registry.registerStaticUse(helper);
    return buildStaticInvoke(
        helper, arguments, sourceInformation: sourceInformation);
  }

  @override
  js.Expression visitReifyRuntimeType(tree_ir.ReifyRuntimeType node) {
    js.Expression typeToString = buildStaticHelperInvocation(
        glue.getRuntimeTypeToString(),
        [visitExpression(node.value)],
        sourceInformation: node.sourceInformation);
    return buildStaticHelperInvocation(
        glue.getCreateRuntimeType(),
        [typeToString],
        sourceInformation: node.sourceInformation);
  }

  @override
  js.Expression visitReadTypeVariable(tree_ir.ReadTypeVariable node) {
    ClassElement context = node.variable.element.enclosingClass;
    js.Expression index = js.number(glue.getTypeVariableIndex(node.variable));
    if (glue.needsSubstitutionForTypeVariableAccess(context)) {
      js.Expression typeName = glue.getRuntimeTypeName(context);
      return buildStaticHelperInvocation(
          glue.getRuntimeTypeArgument(),
          [visitExpression(node.target), typeName, index],
          sourceInformation: node.sourceInformation);
    } else {
      return buildStaticHelperInvocation(
          glue.getTypeArgumentByIndex(),
          [visitExpression(node.target), index],
          sourceInformation: node.sourceInformation);
    }
  }

  @override
  js.Expression visitTypeExpression(tree_ir.TypeExpression node) {
    List<js.Expression> arguments = visitExpressionList(node.arguments);
    return glue.generateTypeRepresentation(node.dartType, arguments, registry);
  }

  js.Node handleForeignCode(tree_ir.ForeignCode node) {
    registry.registerStaticUse(node.dependency);
    // TODO(sra): Should this be in CodegenRegistry?
    glue.registerNativeBehavior(node.nativeBehavior, node);
    return node.codeTemplate.instantiate(visitExpressionList(node.arguments));
  }

  @override
  js.Expression visitForeignExpression(tree_ir.ForeignExpression node) {
    return handleForeignCode(node);
  }

  @override
  void visitForeignStatement(tree_ir.ForeignStatement node) {
    accumulator.add(handleForeignCode(node));
  }

  @override
  void visitYield(tree_ir.Yield node) {
    js.Expression value = visitExpression(node.input);
    accumulator.add(new js.DartYield(value, node.hasStar));
  }

  @override
  js.Expression visitApplyBuiltinOperator(tree_ir.ApplyBuiltinOperator node) {
    List<js.Expression> args = visitExpressionList(node.arguments);
    switch (node.operator) {
      case BuiltinOperator.NumAdd:
        return new js.Binary('+', args[0], args[1]);
      case BuiltinOperator.NumSubtract:
        return new js.Binary('-', args[0], args[1]);
      case BuiltinOperator.NumMultiply:
        return new js.Binary('*', args[0], args[1]);
      case BuiltinOperator.NumDivide:
        return new js.Binary('/', args[0], args[1]);
      case BuiltinOperator.NumRemainder:
        return new js.Binary('%', args[0], args[1]);
      case BuiltinOperator.NumTruncatingDivideToSigned32:
        return js.js('(# / #) | 0', args);
      case BuiltinOperator.NumAnd:
        return normalizeBitOp(js.js('# & #', args), node);
      case BuiltinOperator.NumOr:
        return normalizeBitOp(js.js('# | #', args), node);
      case BuiltinOperator.NumXor:
        return normalizeBitOp(js.js('# ^ #', args), node);
      case BuiltinOperator.NumLt:
        return new js.Binary('<', args[0], args[1]);
      case BuiltinOperator.NumLe:
        return new js.Binary('<=', args[0], args[1]);
      case BuiltinOperator.NumGt:
        return new js.Binary('>', args[0], args[1]);
      case BuiltinOperator.NumGe:
        return new js.Binary('>=', args[0], args[1]);
      case BuiltinOperator.NumShl:
        return normalizeBitOp(js.js('# << #', args), node);
      case BuiltinOperator.NumShr:
        // No normalization required since output is always uint32.
        return js.js('# >>> #', args);
      case BuiltinOperator.StringConcatenate:
        if (args.isEmpty) return js.string('');
        return args.reduce((e1,e2) => new js.Binary('+', e1, e2));
      case BuiltinOperator.Identical:
        registry.registerStaticInvocation(glue.identicalFunction);
        return buildStaticHelperInvocation(glue.identicalFunction, args);
      case BuiltinOperator.StrictEq:
        return new js.Binary('===', args[0], args[1]);
      case BuiltinOperator.StrictNeq:
        return new js.Binary('!==', args[0], args[1]);
      case BuiltinOperator.LooseEq:
        return new js.Binary('==', args[0], args[1]);
      case BuiltinOperator.LooseNeq:
        return new js.Binary('!=', args[0], args[1]);
      case BuiltinOperator.IsFalsy:
        return new js.Prefix('!', args[0]);
      case BuiltinOperator.IsNumber:
        return js.js('typeof # === "number"', args);
      case BuiltinOperator.IsNotNumber:
        return js.js('typeof # !== "number"', args);
      case BuiltinOperator.IsFloor:
        return js.js('Math.floor(#) === #', args);
      case BuiltinOperator.IsNumberAndFloor:
        return js.js('typeof # === "number" && Math.floor(#) === #', args);
      case BuiltinOperator.IsFixedLengthJSArray:
        // TODO(sra): Remove boolify (i.e. !!).
        return js.js(r'!!#.fixed$length', args);
      case BuiltinOperator.IsExtendableJSArray:
        return js.js(r'!#.fixed$length', args);
      case BuiltinOperator.IsModifiableJSArray:
        return js.js(r'!#.immutable$list', args);
      case BuiltinOperator.IsUnmodifiableJSArray:
        // TODO(sra): Remove boolify (i.e. !!).
        return js.js(r'!!#.immutable$list', args);
    }
  }

  /// Add a uint32 normalization `op >>> 0` to [op] if it is not in 31-bit
  /// range.
  js.Expression normalizeBitOp(js.Expression op,
                               tree_ir.ApplyBuiltinOperator node) {
    const MAX_UINT31 = 0x7fffffff;
    const MAX_UINT32 = 0xffffffff;

    int constantValue(tree_ir.Expression e) {
      if (e is tree_ir.Constant) {
        ConstantValue value = e.value;
        if (!value.isInt) return null;
        IntConstantValue intConstant = value;
        if (intConstant.primitiveValue < 0) return null;
        if (intConstant.primitiveValue > MAX_UINT32) return null;
        return intConstant.primitiveValue;
      }
      return null;
    }

    /// Returns a value of the form 0b0001xxxx to represent the highest bit set
    /// in the result.  This represents the range [0, 0b00011111], up to 32
    /// bits.  `null` represents a result possibly outside the uint32 range.
    int maxBitOf(tree_ir.Expression e) {
      if (e is tree_ir.Constant) {
        return constantValue(e);
      }
      if (e is tree_ir.ApplyBuiltinOperator) {
        if (e.operator == BuiltinOperator.NumAnd) {
          int left = maxBitOf(e.arguments[0]);
          int right = maxBitOf(e.arguments[1]);
          if (left == null && right == null) return MAX_UINT32;
          if (left == null) return right;
          if (right == null) return left;
          return (left < right) ? left : right;
        }
        if (e.operator == BuiltinOperator.NumOr ||
            e.operator == BuiltinOperator.NumXor) {
          int left = maxBitOf(e.arguments[0]);
          int right = maxBitOf(e.arguments[1]);
          if (left == null || right == null) return MAX_UINT32;
          return left | right;
        }
        if (e.operator == BuiltinOperator.NumShr) {
          int right = constantValue(e.arguments[1]);
          // NumShr is JavaScript '>>>' so always generates a uint32 result.
          if (right == null || right <= 0 || right > 31) return MAX_UINT32;
          int left = maxBitOf(e.arguments[0]);
          if (left == null) return MAX_UINT32;
          return left >> right;
        }
        if (e.operator == BuiltinOperator.NumShl) {
          int right = constantValue(e.arguments[1]);
          if (right == null || right <= 0 || right > 31) return MAX_UINT32;
          int left = maxBitOf(e.arguments[0]);
          if (left == null) return MAX_UINT32;
          if (left.bitLength + right > 31) return MAX_UINT32;
          return left << right;
        }
      }
      return null;
    }

    int maxBit = maxBitOf(node);
    if (maxBit != null && maxBit <= MAX_UINT31) return op;
    return js.js('# >>> 0', [op]);
  }


  /// The JS name of a built-in method.
  static final Map<BuiltinMethod, String> builtinMethodName =
    const <BuiltinMethod, String>{
      BuiltinMethod.Push: 'push',
      BuiltinMethod.Pop: 'pop',
  };

  @override
  js.Expression visitApplyBuiltinMethod(tree_ir.ApplyBuiltinMethod node) {
    String name = builtinMethodName[node.method];
    js.Expression receiver = visitExpression(node.receiver);
    List<js.Expression> args = visitExpressionList(node.arguments);
    return js.js('#.#(#)', [receiver, name, args]);
  }

  @override
  js.Expression visitAwait(tree_ir.Await node) {
    return new js.Await(visitExpression(node.input));
  }

  visitFunctionExpression(tree_ir.FunctionExpression node) {
    // FunctionExpressions are currently unused.
    // We might need them if we want to emit raw JS nested functions.
    throw 'FunctionExpressions should not be used';
  }
}
