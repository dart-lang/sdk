// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library code_generator;

import 'glue.dart';

import '../../tree_ir/tree_ir_nodes.dart' as tree_ir;
import '../../tree_ir/tree_ir_nodes.dart' show BuiltinOperator;
import '../../js/js.dart' as js;
import '../../elements/elements.dart';
import '../../io/source_information.dart' show SourceInformation;
import '../../util/maplet.dart';
import '../../constants/values.dart';
import '../../dart2jslib.dart';
import '../../dart_types.dart';
import '../../types/types.dart' show TypeMask;
import '../../universe/universe.dart' show UniverseSelector;
import '../../closure.dart' show ClosureClassElement;

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
    return buildStaticInvoke(target, arguments);
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
                           visitExpressionList(node.arguments));
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

      // Handle some special checks against classes that exist only in
      // the compile-time class hierarchy, not at runtime.
      if (clazz == glue.jsExtendableArrayClass) {
        return js.js(r'!#.fixed$length', <js.Expression>[value]);
      } else if (clazz == glue.jsMutableArrayClass) {
        return js.js(r'!#.immutable$list', <js.Expression>[value]);
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
    if (node.target.binding == next) {
      // Fall through to continue target
      fallthrough.use();
    } else if (next is tree_ir.Continue && next.target == node.target) {
      // Fall through to equivalent continue
      fallthrough.use();
    } else {
      usedLabels.add(node.target);
      accumulator.add(new js.Continue(node.target.name));
    }
  }

  @override
  void visitBreak(tree_ir.Break node) {
    tree_ir.Statement next = fallthrough.target;
    if (node.target.binding.next == next) {
      // Fall through to break target
      fallthrough.use();
    } else if (next is tree_ir.Break && next.target == node.target) {
      // Fall through to equivalent break
      fallthrough.use();
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
    accumulator.add(buildLabeled(() => buildBodyStatement(node.body),
                                 node.label,
                                 node.next));
    visitStatement(node.next);
  }

  js.Statement buildLabeled(js.Statement buildBody(),
                            tree_ir.Label label,
                            tree_ir.Statement fallthroughStatement) {
    fallthrough.push(fallthroughStatement);
    js.Statement result = buildBody();
    if (usedLabels.remove(label)) {
      result = new js.LabeledStatement(label.name, result);
    }
    fallthrough.pop();
    return result;
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
      accumulator.add(new js.Return(visitExpression(node.value)));
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
        visitExpressionList(node.arguments));

    List<tree_ir.Expression> typeInformation = node.typeInformation;
    assert(typeInformation.isEmpty ||
        typeInformation.length == classElement.typeVariables.length);
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
        [globalHolder, helperName, visitExpression(node.input)]);
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

  js.Expression buildStaticHelperInvocation(FunctionElement helper,
                                            List<js.Expression> arguments) {
    registry.registerStaticUse(helper);
    return buildStaticInvoke(helper, arguments);
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

  js.Node handleForeignCode(tree_ir.ForeignCode node) {
    registry.registerStaticUse(node.dependency);
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
  js.Expression visitApplyBuiltinOperator(tree_ir.ApplyBuiltinOperator node) {
    List<js.Expression> args = visitExpressionList(node.arguments);
    switch (node.operator) {
      case BuiltinOperator.NumAdd:
        return new js.Binary('+', args[0], args[1]);
      case BuiltinOperator.NumSubtract:
        return new js.Binary('-', args[0], args[1]);
      case BuiltinOperator.NumMultiply:
        return new js.Binary('*', args[0], args[1]);
      case BuiltinOperator.NumAnd:
        return js.js('(# & #) >>> 0', args);
      case BuiltinOperator.NumOr:
        return js.js('(# | #) >>> 0', args);
      case BuiltinOperator.NumXor:
        return js.js('(# ^ #) >>> 0', args);
      case BuiltinOperator.NumLt:
        return new js.Binary('<', args[0], args[1]);
      case BuiltinOperator.NumLe:
        return new js.Binary('<=', args[0], args[1]);
      case BuiltinOperator.NumGt:
        return new js.Binary('>', args[0], args[1]);
      case BuiltinOperator.NumGe:
        return new js.Binary('>=', args[0], args[1]);
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
        return js.js("typeof # === 'number'", args);
      case BuiltinOperator.IsNotNumber:
        return js.js("typeof # !== 'number'", args);
      case BuiltinOperator.IsFloor:
        return js.js("Math.floor(#) === #", args);
      case BuiltinOperator.IsNumberAndFloor:
        return js.js("typeof # === 'number' && Math.floor(#) === #", args);
    }
  }

  visitFunctionExpression(tree_ir.FunctionExpression node) {
    // FunctionExpressions are currently unused.
    // We might need them if we want to emit raw JS nested functions.
    throw 'FunctionExpressions should not be used';
  }
}
