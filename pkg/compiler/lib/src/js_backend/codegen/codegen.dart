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
    BuiltinOperator,
    isCompoundableOperator;
import '../../types/types.dart' show
    TypeMask;
import '../../universe/call_structure.dart' show
    CallStructure;
import '../../universe/selector.dart' show
    Selector;
import '../../universe/use.dart' show
    DynamicUse,
    StaticUse,
    TypeUse;
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

  /// When the top element is true, [Unreachable] statements will be emitted
  /// as [Return]s, otherwise they are emitted as empty because they are
  /// followed by the end of the method.
  ///
  /// Note on why the [fallthrough] stack should not be used for this:
  /// Ordinary statements may choose whether to use the [fallthrough] target,
  /// and the choice to do so may disable an optimization in [visitIf].
  /// But omitting an unreachable 'return' should have lower priority than
  /// the optimizations in [visitIf], so [visitIf] will instead tell the
  /// [Unreachable] statements whether they may use fallthrough or not.
  List<bool> emitUnreachableAsReturn = <bool>[false];

  final Map<tree_ir.Label, String> labelNames = <tree_ir.Label, String>{};

  List<js.Statement> accumulator = new List<js.Statement>();

  CodeGenerator(this.glue, this.registry);

  /// Generates JavaScript code for the body of [function].
  js.Fun buildFunction(tree_ir.FunctionDefinition function) {
    registerDefaultParameterValues(function.element);
    currentFunction = function.element;
    tree_ir.Statement statement = function.body;
    while (statement != null) {
      statement = visitStatement(statement);
    }

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

      // Do not touch non-local variables.
      if (!usedVariableNames.contains(use.name)) break;

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

      // Do not touch non-local variables.
      if (!usedVariableNames.contains(use.name)) break pullFromForLoop;

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
    List<js.Expression> result = new List<js.Expression>(expressions.length);
    for (int i = 0; i < expressions.length; ++i) {
      result[i] = visitExpression(expressions[i]);
    }
    return result;
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
    if (target.isConstructor) {
      // TODO(johnniwinther): Avoid dependency on [isGenerativeConstructor] by
      // using backend-specific [StatisUse] classes.
      registry.registerStaticUse(
          new StaticUse.constructorInvoke(target.declaration,
              new CallStructure.unnamed(arguments.length)));
    } else {
      registry.registerStaticUse(
          new StaticUse.staticInvoke(target.declaration,
              new CallStructure.unnamed(arguments.length)));
    }
    js.Expression elementAccess = glue.staticFunctionAccess(target);
    return new js.Call(elementAccess, arguments,
        sourceInformation: sourceInformation);
  }

  @override
  js.Expression visitInvokeConstructor(tree_ir.InvokeConstructor node) {
    if (node.constant != null) return giveup(node);

    registry.registerInstantiation(node.type);
    FunctionElement target = node.target;
    List<js.Expression> arguments = visitExpressionList(node.arguments);
    return buildStaticInvoke(
        target,
        arguments,
        sourceInformation: node.sourceInformation);
  }

  void registerMethodInvoke(Selector selector, TypeMask receiverType) {
    registry.registerDynamicUse(new DynamicUse(selector, receiverType));
    if (!selector.isGetter && !selector.isSetter) {
      // TODO(sigurdm): We should find a better place to register the call.
      Selector call = new Selector.callClosureFrom(selector);
      registry.registerDynamicUse(new DynamicUse(call, null));
    }
  }

  @override
  js.Expression visitInvokeMethod(tree_ir.InvokeMethod node) {
    TypeMask mask = glue.extendMaskIfReachesAll(node.selector, node.mask);
    registerMethodInvoke(node.selector, mask);
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
    if (node.isTearOff) {
      // If this is a tear-off, register the fact that a tear-off closure
      // will be created, and that this tear-off must bypass ordinary
      // dispatch to ensure the super method is invoked.
      registry.registerStaticUse(new StaticUse.staticInvoke(
          glue.closureFromTearOff, new CallStructure.unnamed(
            glue.closureFromTearOff.parameters.length)));
      registry.registerStaticUse(new StaticUse.superTearOff(node.target));
    }
    if (node.target is ConstructorBodyElement) {
      registry.registerStaticUse(
          new StaticUse.constructorBodyInvoke(
              node.target.declaration,
              new CallStructure.unnamed(node.arguments.length)));
      // A constructor body cannot be overriden or intercepted, so we can
      // use the short form for this invocation.
      return js.js('#.#(#)',
          [visitExpression(node.receiver),
           glue.instanceMethodName(node.target),
           visitExpressionList(node.arguments)])
          .withSourceInformation(node.sourceInformation);
    }
    registry.registerStaticUse(
        new StaticUse.superInvoke(
            node.target.declaration,
            new CallStructure.unnamed(node.arguments.length)));
    return js.js('#.#.call(#, #)',
        [glue.prototypeAccess(node.target.enclosingClass),
         glue.invocationName(node.selector),
         visitExpression(node.receiver),
         visitExpressionList(node.arguments)])
        .withSourceInformation(node.sourceInformation);
  }

  @override
  js.Expression visitOneShotInterceptor(tree_ir.OneShotInterceptor node) {
    registerMethodInvoke(node.selector, node.mask);
    registry.registerUseInterceptor();
    return js.js('#.#(#)',
        [glue.getInterceptorLibrary(),
         glue.registerOneShotInterceptor(node.selector),
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

  /// Ensure that 'instanceof' checks may be performed against [class_].
  ///
  /// Even if the class is never instantiated, a JS constructor must be emitted
  /// so the 'instanceof' expression does not throw an exception at runtime.
  bool tryRegisterInstanceofCheck(ClassElement class_) {
    if (glue.classWorld.isInstantiated(class_)) {
      // Ensure the class remains instantiated during backend tree-shaking.
      // TODO(asgerf): We could have a more precise hook to inform the emitter
      // that the JS constructor function is needed, without the class being
      // instantiated.
      registry.registerInstantiatedClass(class_);
      return true;
    }
    // Will throw if the JS constructor is not emitted, so do not allow the
    // instanceof check.  This should only happen when certain optimization
    // passes are disabled, as the type check itself is trivial.
    return false;
  }

  @override
  js.Expression visitTypeOperator(tree_ir.TypeOperator node) {
    js.Expression value = visitExpression(node.value);
    List<js.Expression> typeArguments = visitExpressionList(node.typeArguments);
    DartType type = node.type;
    if (type is InterfaceType) {
      registry.registerTypeUse(new TypeUse.isCheck(type));
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
      } else if (node.isTypeTest &&
                 node.typeArguments.isEmpty &&
                 glue.mayGenerateInstanceofCheck(type) &&
                 tryRegisterInstanceofCheck(clazz)) {
        return js.js('# instanceof #', [value, glue.constructorAccess(clazz)]);
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
      registry.registerTypeUse(new TypeUse.isCheck(type));

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
    registry.registerTypeUse(new TypeUse.isCheck(dartType));
    //glue.registerIsCheck(dartType, registry);
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

  /// Returns the JS operator for the given built-in operator for use in a
  /// compound assignment (not including the '=' sign).
  String getAsCompoundOperator(BuiltinOperator operator) {
    switch (operator) {
      case BuiltinOperator.NumAdd:
      case BuiltinOperator.StringConcatenate:
        return '+';
      case BuiltinOperator.NumSubtract:
        return '-';
      case BuiltinOperator.NumMultiply:
        return '*';
      case BuiltinOperator.NumDivide:
        return '/';
      case BuiltinOperator.NumRemainder:
        return '%';
      default:
        throw 'Not a compoundable operator: $operator';
    }
  }

  bool isCompoundableBuiltin(tree_ir.Expression exp) {
    return exp is tree_ir.ApplyBuiltinOperator &&
           exp.arguments.length == 2 &&
           isCompoundableOperator(exp.operator);
  }

  bool isOneConstant(tree_ir.Expression exp) {
    return exp is tree_ir.Constant && exp.value.isOne;
  }

  js.Expression makeAssignment(
      js.Expression leftHand,
      tree_ir.Expression value,
      {BuiltinOperator compound}) {
    if (isOneConstant(value)) {
      if (compound == BuiltinOperator.NumAdd) {
        return new js.Prefix('++', leftHand);
      }
      if (compound == BuiltinOperator.NumSubtract) {
        return new js.Prefix('--', leftHand);
      }
    }
    if (compound != null) {
      return new js.Assignment.compound(leftHand,
          getAsCompoundOperator(compound), visitExpression(value));
    }
    return new js.Assignment(leftHand, visitExpression(value));
  }

  @override
  js.Expression visitAssign(tree_ir.Assign node) {
    js.Expression variable = buildVariableAccess(node.variable);
    if (isCompoundableBuiltin(node.value)) {
      tree_ir.ApplyBuiltinOperator rhs = node.value;
      tree_ir.Expression left = rhs.arguments[0];
      tree_ir.Expression right = rhs.arguments[1];
      if (left is tree_ir.VariableUse && left.variable == node.variable) {
        return makeAssignment(variable, right, compound: rhs.operator);
      }
    }
    return makeAssignment(variable, node.value);
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
      accumulator.add(new js.Continue(makeLabel(node.target)));
    }
  }

  /// True if [other] is the target of [node] or is a [Break] with the same
  /// target. This means jumping to [other] is equivalent to executing [node].
  bool isEffectiveBreakTarget(tree_ir.Break node, tree_ir.Statement other) {
    return node.target.binding.next == other ||
           other is tree_ir.Break && node.target == other.target;
  }

  /// True if the given break is equivalent to an unlabeled continue.
  bool isShortContinue(tree_ir.Break node) {
    tree_ir.Statement next = node.target.binding.next;
    return next is tree_ir.Continue &&
           next.target.binding == shortContinue.target;
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
    } else if (isShortContinue(node)) {
      // An unlabeled continue is better than a labeled break.
      shortContinue.use();
      accumulator.add(new js.Continue(null));
    } else {
      accumulator.add(new js.Break(makeLabel(node.target)));
    }
  }

  @override
  visitExpressionStatement(tree_ir.ExpressionStatement node) {
    js.Expression exp = visitExpression(node.expression);
    if (node.next is tree_ir.Unreachable && emitUnreachableAsReturn.last) {
      // Emit as 'return exp' to assist local analysis in the VM.
      accumulator.add(new js.Return(exp));
      return null;
    } else {
      accumulator.add(new js.ExpressionStatement(exp));
      return node.next;
    }
  }

  bool isNullReturn(tree_ir.Statement node) {
    return node is tree_ir.Return && isNull(node.value);
  }

  bool isEndOfMethod(tree_ir.Statement node) {
    return isNullReturn(node) ||
           node is tree_ir.Break && isNullReturn(node.target.binding.next);
  }

  @override
  visitIf(tree_ir.If node) {
    js.Expression condition = visitExpression(node.condition);
    int usesBefore = fallthrough.useCount;
    // Unless the 'else' part ends the method. make sure to terminate any
    // uncompletable code paths in the 'then' part.
    emitUnreachableAsReturn.add(!isEndOfMethod(node.elseStatement));
    js.Statement thenBody = buildBodyStatement(node.thenStatement);
    emitUnreachableAsReturn.removeLast();
    bool thenHasFallthrough = (fallthrough.useCount > usesBefore);
    if (thenHasFallthrough) {
      js.Statement elseBody = buildBodyStatement(node.elseStatement);
      accumulator.add(new js.If(condition, thenBody, elseBody));
      return null;
    } else {
      // The 'then' body cannot complete normally, so emit a short 'if'
      // and put the 'else' body after it.
      accumulator.add(new js.If.noElse(condition, thenBody));
      return node.elseStatement;
    }
  }

  @override
  visitLabeledStatement(tree_ir.LabeledStatement node) {
    fallthrough.push(node.next);
    js.Statement body = buildBodyStatement(node.body);
    fallthrough.pop();
    accumulator.add(insertLabel(node.label, body));
    return node.next;
  }

  /// Creates a name for [label] if it does not already have one.
  ///
  /// This also marks the label as being used.
  String makeLabel(tree_ir.Label label) {
    return labelNames.putIfAbsent(label, () => 'L${labelNames.length}');
  }

  /// Wraps a node in a labeled statement unless the label is unused.
  js.Statement insertLabel(tree_ir.Label label, js.Statement node) {
    String name = labelNames[label];
    if (name == null) return node; // Label is unused.
    return new js.LabeledStatement(name, node);
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
    while (statement != null) {
      statement = visitStatement(statement);
    }
    js.Statement result = _bodyAsStatement();
    accumulator = savedAccumulator;
    return result;
  }

  js.Block buildBodyBlock(tree_ir.Statement statement) {
    List<js.Statement> savedAccumulator = accumulator;
    accumulator = <js.Statement>[];
    while (statement != null) {
      statement = visitStatement(statement);
    }
    js.Statement result = new js.Block(accumulator);
    accumulator = savedAccumulator;
    return result;
  }

  js.Expression makeSequence(List<tree_ir.Expression> list) {
    return list.map(visitExpression).reduce((x,y) => new js.Binary(',', x, y));
  }

  @override
  visitFor(tree_ir.For node) {
    js.Expression condition = visitExpression(node.condition);
    shortBreak.push(node.next);
    shortContinue.push(node);
    fallthrough.push(node);
    emitUnreachableAsReturn.add(true);
    js.Statement body = buildBodyStatement(node.body);
    emitUnreachableAsReturn.removeLast();
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
    return node.next;
  }

  @override
  void visitWhileTrue(tree_ir.WhileTrue node) {
    // A short break in the while will jump to the current fallthrough target.
    shortBreak.push(fallthrough.target);
    shortContinue.push(node);
    fallthrough.push(node);
    emitUnreachableAsReturn.add(true);
    js.Statement jsBody = buildBodyStatement(node.body);
    emitUnreachableAsReturn.removeLast();
    fallthrough.pop();
    shortContinue.pop();
    if (shortBreak.useCount > 0) {
      // Short breaks use the current fallthrough target.
      fallthrough.use();
    }
    shortBreak.pop();
    accumulator.add(
        insertLabel(node.label, new js.For(null, null, null, jsBody)));
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
  void visitUnreachable(tree_ir.Unreachable node) {
    if (emitUnreachableAsReturn.last) {
      // Emit a return to assist local analysis in the VM.
      accumulator.add(new js.Return());
    }
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
    registry.registerInstantiation(classElement.rawType);
    if (classElement is ClosureClassElement) {
      registry.registerInstantiatedClosure(classElement.methodElement);
    }
    js.Expression instance = new js.New(
            glue.constructorAccess(classElement),
            visitExpressionList(node.arguments))
        .withSourceInformation(node.sourceInformation);

    tree_ir.Expression typeInformation = node.typeInformation;
    if (typeInformation != null) {
      FunctionElement helper = glue.getAddRuntimeTypeInformation();
      js.Expression typeArguments = visitExpression(typeInformation);
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
    registry.registerUseInterceptor();
    // Default to all intercepted classes if they have not been computed.
    // This is to ensure we can run codegen without prior optimization passes.
    Set<ClassElement> interceptedClasses = node.interceptedClasses.isEmpty
        ? glue.interceptedClasses
        : node.interceptedClasses;
    registry.registerSpecializedGetInterceptor(interceptedClasses);
    js.Name helperName = glue.getInterceptorName(interceptedClasses);
    js.Expression globalHolder = glue.getInterceptorLibrary();
    return js.js('#.#(#)',
        [globalHolder, helperName, visitExpression(node.input)])
            .withSourceInformation(node.sourceInformation);
  }

  @override
  js.Expression visitGetField(tree_ir.GetField node) {
    registry.registerStaticUse(new StaticUse.fieldGet(node.field));
    return new js.PropertyAccess(
        visitExpression(node.object),
        glue.instanceFieldPropertyName(node.field));
  }

  @override
  js.Expression visitSetField(tree_ir.SetField node) {
    registry.registerStaticUse(new StaticUse.fieldSet(node.field));
    js.PropertyAccess field =
        new js.PropertyAccess(
            visitExpression(node.object),
            glue.instanceFieldPropertyName(node.field));
    return makeAssignment(field, node.value, compound: node.compound);
  }

  @override
  js.Expression visitGetStatic(tree_ir.GetStatic node) {
    assert(node.element is FieldElement || node.element is FunctionElement);
    if (node.element is FunctionElement) {
      // Tear off a method.
      registry.registerStaticUse(
          new StaticUse.staticTearOff(node.element.declaration));
      return glue.isolateStaticClosureAccess(node.element);
    }
    if (node.useLazyGetter) {
      // Read a lazily initialized field.
      registry.registerStaticUse(
          new StaticUse.staticInit(node.element.declaration));
      js.Expression getter = glue.isolateLazyInitializerAccess(node.element);
      return new js.Call(getter, <js.Expression>[],
          sourceInformation: node.sourceInformation);
    }
    // Read an eagerly initialized field.
    registry.registerStaticUse(
        new StaticUse.staticGet(node.element.declaration));
    return glue.staticFieldAccess(node.element);
  }

  @override
  js.Expression visitSetStatic(tree_ir.SetStatic node) {
    assert(node.element is FieldElement);
    registry.registerStaticUse(
        new StaticUse.staticSet(node.element.declaration));
    js.Expression field = glue.staticFieldAccess(node.element);
    return makeAssignment(field, node.value, compound: node.compound);
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
    js.Expression index = new js.PropertyAccess(
        visitExpression(node.object), visitExpression(node.index));
    return makeAssignment(index, node.value, compound: node.compound);
  }

  js.Expression buildStaticHelperInvocation(
      FunctionElement helper,
      List<js.Expression> arguments,
      {SourceInformation sourceInformation}) {
    registry.registerStaticUse(new StaticUse.staticInvoke(
        helper, new CallStructure.unnamed(arguments.length)));
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
    switch (node.kind) {
      case tree_ir.TypeExpressionKind.COMPLETE:
        return glue.generateTypeRepresentation(
            node.dartType, arguments, registry);
      case tree_ir.TypeExpressionKind.INSTANCE:
        // We expect only flat types for the INSTANCE representation.
        assert(node.dartType ==
               (node.dartType.element as ClassElement).thisType);
        registry.registerInstantiatedClass(glue.listClass);
        return new js.ArrayInitializer(arguments);
    }
  }

  js.Node handleForeignCode(tree_ir.ForeignCode node) {
    if (node.dependency != null) {
      // Dependency is only used if [node] calls a Dart function. Currently only
      // through foreign function `RAW_DART_FUNCTION_REF`.
      registry.registerStaticUse(
          new StaticUse.staticInvoke(
              node.dependency,
              new CallStructure.unnamed(node.arguments.length)));
    }
    // TODO(sra,johnniwinther): Should this be in CodegenRegistry?
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
  visitYield(tree_ir.Yield node) {
    js.Expression value = visitExpression(node.input);
    accumulator.add(new js.DartYield(value, node.hasStar));
    return node.next;
  }

  @override
  visitReceiverCheck(tree_ir.ReceiverCheck node) {
    js.Expression value = visitExpression(node.value);
    // TODO(sra): Try to use the selector even when [useSelector] is false. The
    // reason we use 'toString' is that it is always defined so avoids a slow
    // lookup (in V8) of an absent property. We could use the property for the
    // selector if we knew it was present. The property is present if the
    // associated method was not inlined away, or if there is a noSuchMethod
    // hook for that selector. We don't know these things here, but the decision
    // could be deferred by creating a deferred property that was resolved after
    // codegen.
    js.Expression access = node.useSelector
        ? js.js('#.#', [value, glue.invocationName(node.selector)])
        : js.js('#.toString', [value]);
    if (node.useInvoke) {
      access = new js.Call(access, []);
    }
    if (node.condition != null) {
      js.Expression condition = visitExpression(node.condition);
      js.Statement body = isNullReturn(node.next)
          ? new js.ExpressionStatement(access)
          : new js.Return(access);
      accumulator.add(new js.If.noElse(condition, body));
    } else {
      accumulator.add(new js.ExpressionStatement(access));
    }
    return node.next;
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
      case BuiltinOperator.NumBitNot:
        return js.js('(~#) >>> 0', args);
      case BuiltinOperator.NumNegate:
        return js.js('-#', args);
      case BuiltinOperator.StringConcatenate:
        if (args.isEmpty) return js.string('');
        return args.reduce((e1,e2) => new js.Binary('+', e1, e2));
      case BuiltinOperator.CharCodeAt:
        return js.js('#.charCodeAt(#)', args);
      case BuiltinOperator.Identical:
        registry.registerStaticUse(new StaticUse.staticInvoke(
            glue.identicalFunction, new CallStructure.unnamed(args.length)));
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
      case BuiltinOperator.IsInteger:
        return js.js('typeof # === "number" && Math.floor(#) === #', args);
      case BuiltinOperator.IsNotInteger:
        return js.js('typeof # !== "number" || Math.floor(#) !== #', args);
      case BuiltinOperator.IsUnsigned32BitInteger:
        return js.js('# >>> 0 === #', args);
      case BuiltinOperator.IsNotUnsigned32BitInteger:
        return js.js('# >>> 0 !== #', args);
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

  @override
  js.Expression visitApplyBuiltinMethod(tree_ir.ApplyBuiltinMethod node) {
    js.Expression receiver = visitExpression(node.receiver);
    List<js.Expression> args = visitExpressionList(node.arguments);
    switch (node.method) {
      case BuiltinMethod.Push:
        return js.js('#.push(#)', [receiver, args]);

      case BuiltinMethod.Pop:
        return js.js('#.pop()', [receiver]);

      case BuiltinMethod.SetLength:
        return js.js('#.length = #', [receiver, args[0]]);
    }
  }

  @override
  js.Expression visitAwait(tree_ir.Await node) {
    return new js.Await(visitExpression(node.input));
  }

  /// Ensures that parameter defaults will be emitted.
  ///
  /// Ideally, this should be done when generating the relevant stub methods,
  /// since those are the ones that actually reference the constants, but those
  /// are created by the emitter when it is too late to register new constants.
  ///
  /// For non-static methods, we have no way of knowing if the defaults are
  /// actually used, so we conservatively register them all.
  void registerDefaultParameterValues(ExecutableElement element) {
    if (element is! FunctionElement) return;
    FunctionElement function = element;
    if (function.isStatic) return; // Defaults are inlined at call sites.
    function.functionSignature.forEachOptionalParameter((param) {
      ConstantValue constant = glue.getDefaultParameterValue(param);
      registry.registerCompileTimeConstant(constant);
    });
  }
}
