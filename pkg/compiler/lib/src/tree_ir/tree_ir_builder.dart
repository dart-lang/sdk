// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library tree_ir_builder;

import '../dart2jslib.dart' as dart2js;
import '../dart_types.dart';
import '../elements/elements.dart';
import '../cps_ir/cps_ir_nodes.dart' as cps_ir;
import '../util/util.dart' show CURRENT_ELEMENT_SPANNABLE;
import 'tree_ir_nodes.dart';

/**
 * Builder translates from CPS-based IR to direct-style Tree.
 *
 * A call `Invoke(fun, cont, args)`, where cont is a singly-referenced
 * non-exit continuation `Cont(v, body)` is translated into a direct-style call
 * whose value is bound in the continuation body:
 *
 * `LetVal(v, Invoke(fun, args), body)`
 *
 * and the continuation definition is eliminated.  A similar translation is
 * applied to continuation invocations where the continuation is
 * singly-referenced, though such invocations should not appear in optimized
 * IR.
 *
 * A call `Invoke(fun, cont, args)`, where cont is multiply referenced, is
 * translated into a call followed by a jump with an argument:
 *
 * `Jump L(Invoke(fun, args))`
 *
 * and the continuation is translated into a named block that takes an
 * argument:
 *
 * `LetLabel(L, v, body)`
 *
 * Block arguments are later replaced with data flow during the Tree-to-Tree
 * translation out of SSA.  Jumps are eliminated during the Tree-to-Tree
 * control-flow recognition.
 *
 * Otherwise, the output of Builder looks very much like the input.  In
 * particular, intermediate values and blocks used for local control flow are
 * still all named.
 */
class Builder extends cps_ir.Visitor<Node> {
  final dart2js.InternalErrorFunction internalError;

  /// Maps variable/parameter elements to the Tree variables that represent it.
  final Map<Local, List<Variable>> local2variables = <Local, List<Variable>>{};

  /// Like [local2variables], except for mutable variables.
  final Map<cps_ir.MutableVariable, Variable> local2mutable =
      <cps_ir.MutableVariable, Variable>{};

  // Continuations with more than one use are replaced with Tree labels.  This
  // is the mapping from continuations to labels.
  final Map<cps_ir.Continuation, Label> labels = <cps_ir.Continuation, Label>{};

  /// A stack of singly-used labels that can be safely inlined at their use
  /// site.
  ///
  /// Code for continuations with exactly one use is inlined at the use site.
  /// This is not safe if the code is moved inside the scope of an exception
  /// handler (i.e., into a try block).  We keep a stack of singly-referenced
  /// continuations that are in scope without crossing a binding for a handler.
  List<cps_ir.Continuation> safeForInlining = <cps_ir.Continuation>[];

  ExecutableElement currentElement;
  cps_ir.Continuation returnContinuation;

  Builder parent;

  Builder(this.internalError, [this.parent]);

  Builder createInnerBuilder() {
    return new Builder(internalError, this);
  }

  /// Variable used in [buildPhiAssignments] as a temporary when swapping
  /// variables.
  Variable phiTempVar;

  Variable addMutableVariable(cps_ir.MutableVariable irVariable) {
    if (irVariable.host != currentElement) {
      return parent.addMutableVariable(irVariable);
    }
    assert(!local2mutable.containsKey(irVariable));
    Variable variable = new Variable(currentElement, irVariable.hint);
    local2mutable[irVariable] = variable;
    return variable;
  }

  Variable getMutableVariable(cps_ir.MutableVariable mutableVariable) {
    if (mutableVariable.host != currentElement) {
      return parent.getMutableVariable(mutableVariable);
    }
    return local2mutable[mutableVariable];
  }

  VariableUse getMutableVariableUse(
        cps_ir.Reference<cps_ir.MutableVariable> reference) {
    Variable variable = getMutableVariable(reference.definition);
    return new VariableUse(variable);
  }

  /// Obtains the variable representing the given primitive. Returns null for
  /// primitives that have no reference and do not need a variable.
  Variable getVariable(cps_ir.Primitive primitive) {
    if (primitive.registerIndex == null) {
      return null; // variable is unused
    }
    List<Variable> variables = local2variables.putIfAbsent(primitive.hint,
        () => <Variable>[]);
    while (variables.length <= primitive.registerIndex) {
      variables.add(new Variable(currentElement, primitive.hint));
    }
    return variables[primitive.registerIndex];
  }

  /// Obtains a reference to the tree Variable corresponding to the IR primitive
  /// referred to by [reference].
  /// This increments the reference count for the given variable, so the
  /// returned expression must be used in the tree.
  VariableUse getVariableUse(cps_ir.Reference<cps_ir.Primitive> reference) {
    Variable variable = getVariable(reference.definition);
    if (variable == null) {
      internalError(
          CURRENT_ELEMENT_SPANNABLE,
          "Reference to ${reference.definition} has no register");
    }
    return new VariableUse(variable);
  }

  ExecutableDefinition build(cps_ir.ExecutableDefinition node) {
    if (node is cps_ir.FieldDefinition) {
      return buildField(node);
    } else if (node is cps_ir.ConstructorDefinition) {
      return buildConstructor(node);
    } else {
      assert(dart2js.invariant(
          CURRENT_ELEMENT_SPANNABLE,
          node is cps_ir.FunctionDefinition,
          message: 'expected FunctionDefinition or FieldDefinition, '
            ' found $node'));
      return buildFunction(node);
    }
  }

  FieldDefinition buildField(cps_ir.FieldDefinition node) {
    Statement body;
    if (node.hasInitializer) {
      currentElement = node.element;
      returnContinuation = node.body.returnContinuation;

      phiTempVar = new Variable(node.element, null);

      body = visit(node.body);
    }
    return new FieldDefinition(node.element, body);
  }

  Variable addFunctionParameter(cps_ir.Definition variable) {
    if (variable is cps_ir.Parameter) {
      return getVariable(variable);
    } else {
      return addMutableVariable(variable as cps_ir.MutableVariable);
    }
  }

  FunctionDefinition buildFunction(cps_ir.FunctionDefinition node) {
    currentElement = node.element;
    List<Variable> parameters =
        node.parameters.map(addFunctionParameter).toList();
    Statement body;
    if (!node.isAbstract) {
      returnContinuation = node.body.returnContinuation;
      phiTempVar = new Variable(node.element, null);
      body = visit(node.body);
    }

    return new FunctionDefinition(node.element, parameters,
        body, node.localConstants, node.defaultParameterValues);
  }

  ConstructorDefinition buildConstructor(cps_ir.ConstructorDefinition node) {
    currentElement = node.element;
    List<Variable> parameters =
        node.parameters.map(addFunctionParameter).toList();
    List<Initializer> initializers;
    Statement body;
    if (!node.isAbstract) {
      initializers = node.initializers.map(visit).toList();
      returnContinuation = node.body.returnContinuation;

      phiTempVar = new Variable(node.element, null);
      body = visit(node.body);
    }

    return new ConstructorDefinition(node.element, parameters,
        body, initializers, node.localConstants, node.defaultParameterValues);
  }

  /// Returns a list of variables corresponding to the arguments to a method
  /// call or similar construct.
  ///
  /// The `readCount` for these variables will be incremented.
  ///
  /// The list will be typed as a list of [Expression] to allow inplace updates
  /// on the list during the rewrite phases.
  List<Expression> translateArguments(List<cps_ir.Reference> args) {
    return new List<Expression>.generate(args.length,
         (int index) => getVariableUse(args[index]),
         growable: false);
  }

  /// Returns the list of variables corresponding to the arguments to a join
  /// continuation.
  ///
  /// The `readCount` of these variables will not be incremented. Instead,
  /// [buildPhiAssignments] will handle the increment, if necessary.
  List<Variable> translatePhiArguments(List<cps_ir.Reference> args) {
    return new List<Variable>.generate(args.length,
         (int index) => getVariable(args[index].definition),
         growable: false);
  }

  Statement buildContinuationAssignment(
      cps_ir.Parameter parameter,
      Expression argument,
      Statement buildRest()) {
    Variable variable = getVariable(parameter);
    Statement assignment;
    if (variable == null) {
      assignment = new ExpressionStatement(argument, null);
    } else {
      assignment = new Assign(variable, argument, null);
    }
    assignment.next = buildRest();
    return assignment;
  }

  /// Simultaneously assigns each argument to the corresponding parameter,
  /// then continues at the statement created by [buildRest].
  Statement buildPhiAssignments(
      List<cps_ir.Parameter> parameters,
      List<Variable> arguments,
      Statement buildRest()) {
    assert(parameters.length == arguments.length);
    // We want a parallel assignment to all parameters simultaneously.
    // Since we do not have parallel assignments in dart_tree, we must linearize
    // the assignments without attempting to read a previously-overwritten
    // value. For example {x,y = y,x} cannot be linearized to {x = y; y = x},
    // for this we must introduce a temporary variable: {t = x; x = y; y = t}.

    // [rightHand] is the inverse of [arguments], that is, it maps variables
    // to the assignments on which is occurs as the right-hand side.
    Map<Variable, List<int>> rightHand = <Variable, List<int>>{};
    for (int i = 0; i < parameters.length; i++) {
      Variable param = getVariable(parameters[i]);
      Variable arg = arguments[i];
      if (param == null || param == arg) {
        continue; // No assignment necessary.
      }
      List<int> list = rightHand[arg];
      if (list == null) {
        rightHand[arg] = list = <int>[];
      }
      list.add(i);
    }

    Statement first, current;
    void addAssignment(Variable dst, Variable src) {
      if (first == null) {
        first = current = new Assign(dst, new VariableUse(src), null);
      } else {
        current = current.next = new Assign(dst, new VariableUse(src), null);
      }
    }

    List<Variable> assignmentSrc = new List<Variable>(parameters.length);
    List<bool> done = new List<bool>(parameters.length);
    void visitAssignment(int i) {
      if (done[i] == true) {
        return;
      }
      Variable param = getVariable(parameters[i]);
      Variable arg = arguments[i];
      if (param == null || param == arg) {
        return; // No assignment necessary.
      }
      if (assignmentSrc[i] != null) {
        // Cycle found; store argument in a temporary variable.
        // The temporary will then be used as right-hand side when the
        // assignment gets added.
        if (assignmentSrc[i] != phiTempVar) { // Only move to temporary once.
          assignmentSrc[i] = phiTempVar;
          addAssignment(phiTempVar, arg);
        }
        return;
      }
      assignmentSrc[i] = arg;
      List<int> paramUses = rightHand[param];
      if (paramUses != null) {
        for (int useIndex in paramUses) {
          visitAssignment(useIndex);
        }
      }
      addAssignment(param, assignmentSrc[i]);
      done[i] = true;
    }

    for (int i = 0; i < parameters.length; i++) {
      if (done[i] == null) {
        visitAssignment(i);
      }
    }

    if (first == null) {
      first = buildRest();
    } else {
      current.next = buildRest();
    }
    return first;
  }

  visitNode(cps_ir.Node node) {
    if (node is cps_ir.JsSpecificNode) {
      throw "Cannot handle JS specific IR nodes in this visitor";
    } else {
      throw "Unhandled node: $node";
    }
  }

  Initializer visitFieldInitializer(cps_ir.FieldInitializer node) {
    returnContinuation = node.body.returnContinuation;
    return new FieldInitializer(node.element, visit(node.body.body));
  }

  Initializer visitSuperInitializer(cps_ir.SuperInitializer node) {
    List<Statement> arguments =
        node.arguments.map((cps_ir.RunnableBody argument) {
      returnContinuation = argument.returnContinuation;
      return visit(argument.body);
    }).toList();
    return new SuperInitializer(node.target, node.selector, arguments);
  }

  Statement visitLetPrim(cps_ir.LetPrim node) {
    Variable variable = getVariable(node.primitive);

    // Don't translate unused primitives.
    if (variable == null) return visit(node.body);

    Node definition = visit(node.primitive);

    // visitPrimitive returns a Statement without successor if it cannot occur
    // in expression context (currently only the case for FunctionDeclarations).
    if (definition is Statement) {
      definition.next = visit(node.body);
      return definition;
    } else {
      return new Assign(variable, definition, visit(node.body));
    }
  }

  Statement visitRunnableBody(cps_ir.RunnableBody node) {
    return visit(node.body);
  }

  Statement visitLetCont(cps_ir.LetCont node) {
    // Introduce labels for continuations that need them.
    int safeForInliningLengthOnEntry = safeForInlining.length;
    for (cps_ir.Continuation continuation in node.continuations) {
      if (continuation.hasMultipleUses) {
        labels[continuation] = new Label();
      } else {
        safeForInlining.add(continuation);
      }
    }
    Statement body = visit(node.body);
    safeForInlining.length = safeForInliningLengthOnEntry;
    // Continuations are bound at the same level, but they have to be
    // translated as if nested.  This is because the body can invoke any
    // of them from anywhere, so it must be nested inside all of them.
    //
    // The continuation bodies are not always translated directly here because
    // they may have been already translated:
    //   * For singly-used continuations, the continuation's body is
    //     translated at the site of the continuation invocation.
    //   * For recursive continuations, there is a single non-recursive
    //     invocation.  The continuation's body is translated at the site
    //     of the non-recursive continuation invocation.
    // See visitInvokeContinuation for the implementation.
    Statement current = body;
    for (cps_ir.Continuation continuation in node.continuations.reversed) {
      Label label = labels[continuation];
      if (label != null && !continuation.isRecursive) {
        current =
            new LabeledStatement(label, current, visit(continuation.body));
      }
    }
    return current;
  }

  Statement visitLetHandler(cps_ir.LetHandler node) {
    List<cps_ir.Continuation> saved = safeForInlining;
    safeForInlining = <cps_ir.Continuation>[];
    Statement tryBody = visit(node.body);
    safeForInlining = saved;
    List<Variable> catchParameters =
        node.handler.parameters.map(getVariable).toList();
    Statement catchBody = visit(node.handler.body);
    return new Try(tryBody, catchParameters, catchBody);
  }

  Statement visitInvokeStatic(cps_ir.InvokeStatic node) {
    // Calls are translated to direct style.
    List<Expression> arguments = translateArguments(node.arguments);
    Expression invoke = new InvokeStatic(node.target, node.selector, arguments,
        sourceInformation: node.sourceInformation);
    return continueWithExpression(node.continuation, invoke);
  }

  Statement visitInvokeMethod(cps_ir.InvokeMethod node) {
    Expression invoke = new InvokeMethod(getVariableUse(node.receiver),
                                         node.selector,
                                         translateArguments(node.arguments));
    return continueWithExpression(node.continuation, invoke);
  }

  Statement visitInvokeMethodDirectly(cps_ir.InvokeMethodDirectly node) {
    Expression receiver = getVariableUse(node.receiver);
    List<Expression> arguments = translateArguments(node.arguments);
    Expression invoke = new InvokeMethodDirectly(receiver, node.target,
        node.selector, arguments);
    return continueWithExpression(node.continuation, invoke);
  }

  Statement visitConcatenateStrings(cps_ir.ConcatenateStrings node) {
    List<Expression> arguments = translateArguments(node.arguments);
    Expression concat = new ConcatenateStrings(arguments);
    return continueWithExpression(node.continuation, concat);
  }

  Statement continueWithExpression(cps_ir.Reference continuation,
                                   Expression expression) {
    cps_ir.Continuation cont = continuation.definition;
    if (cont == returnContinuation) {
      return new Return(expression);
    } else {
      assert(cont.parameters.length == 1);
      Function nextBuilder = cont.hasExactlyOneUse ?
          () => visit(cont.body) : () => new Break(labels[cont]);
      return buildContinuationAssignment(cont.parameters.single, expression,
          nextBuilder);
    }
  }

  Statement visitLetMutable(cps_ir.LetMutable node) {
    Variable variable = addMutableVariable(node.variable);
    Expression value = getVariableUse(node.value);
    return new Assign(variable, value, visit(node.body), isDeclaration: true);
  }

  Expression visitGetMutableVariable(cps_ir.GetMutableVariable node) {
    return getMutableVariableUse(node.variable);
  }

  Statement visitSetMutableVariable(cps_ir.SetMutableVariable node) {
    Variable variable = getMutableVariable(node.variable.definition);
    Expression value = getVariableUse(node.value);
    return new Assign(variable, value, visit(node.body));
  }

  Statement visitDeclareFunction(cps_ir.DeclareFunction node) {
    Variable variable = addMutableVariable(node.variable);
    FunctionDefinition function = makeSubFunction(node.definition);
    return new FunctionDeclaration(variable, function, visit(node.body));
  }

  Statement visitTypeOperator(cps_ir.TypeOperator node) {
    Expression receiver = getVariableUse(node.receiver);
    Expression concat =
        new TypeOperator(receiver, node.type, isTypeTest: node.isTypeTest);
    return continueWithExpression(node.continuation, concat);
  }

  Statement visitInvokeConstructor(cps_ir.InvokeConstructor node) {
    List<Expression> arguments = translateArguments(node.arguments);
    Expression invoke =
        new InvokeConstructor(node.type, node.target, node.selector, arguments);
    return continueWithExpression(node.continuation, invoke);
  }

  Statement visitInvokeContinuation(cps_ir.InvokeContinuation node) {
    // Invocations of the return continuation are translated to returns.
    // Other continuation invocations are replaced with assignments of the
    // arguments to formal parameter variables, followed by the body if
    // the continuation is singly reference or a break if it is multiply
    // referenced.
    cps_ir.Continuation cont = node.continuation.definition;
    if (cont == returnContinuation) {
      assert(node.arguments.length == 1);
      return new Return(getVariableUse(node.arguments.single));
    } else {
      List<Variable> arguments = translatePhiArguments(node.arguments);
      return buildPhiAssignments(cont.parameters, arguments,
          () {
            // Translate invocations of recursive and non-recursive
            // continuations differently.
            //   * Non-recursive continuations
            //     - If there is one use, translate the continuation body
            //       inline at the invocation site.
            //     - If there are multiple uses, translate to Break.
            //   * Recursive continuations
            //     - There is a single non-recursive invocation.  Translate
            //       the continuation body inline as a labeled loop at the
            //       invocation site.
            //     - Translate the recursive invocations to Continue.
            if (cont.isRecursive) {
              return node.isRecursive
                  ? new Continue(labels[cont])
                  : new WhileTrue(labels[cont], visit(cont.body));
            } else {
              if (cont.hasExactlyOneUse) {
                if (safeForInlining.contains(cont)) {
                  return visit(cont.body);
                }
                labels[cont] = new Label();
              }
              return new Break(labels[cont]);
            }
          });
    }
  }

  Statement visitBranch(cps_ir.Branch node) {
    Expression condition = visit(node.condition);
    Statement thenStatement, elseStatement;
    cps_ir.Continuation cont = node.trueContinuation.definition;
    assert(cont.parameters.isEmpty);
    thenStatement =
        cont.hasExactlyOneUse ? visit(cont.body) : new Break(labels[cont]);
    cont = node.falseContinuation.definition;
    assert(cont.parameters.isEmpty);
    elseStatement =
        cont.hasExactlyOneUse ? visit(cont.body) : new Break(labels[cont]);
    return new If(condition, thenStatement, elseStatement);
  }

  Expression visitConstant(cps_ir.Constant node) {
    return new Constant(node.expression);
  }

  Expression visitThis(cps_ir.This node) {
    return new This();
  }

  Expression visitReifyTypeVar(cps_ir.ReifyTypeVar node) {
    return new ReifyTypeVar(node.typeVariable);
  }

  Expression visitLiteralList(cps_ir.LiteralList node) {
    return new LiteralList(
            node.type,
            translateArguments(node.values));
  }

  Expression visitLiteralMap(cps_ir.LiteralMap node) {
    return new LiteralMap(
        node.type,
        new List<LiteralMapEntry>.generate(node.entries.length, (int index) {
          return new LiteralMapEntry(
              getVariableUse(node.entries[index].key),
              getVariableUse(node.entries[index].value));
        })
    );
  }

  FunctionDefinition makeSubFunction(cps_ir.FunctionDefinition function) {
    return createInnerBuilder().buildFunction(function);
  }

  Node visitCreateFunction(cps_ir.CreateFunction node) {
    FunctionDefinition def = makeSubFunction(node.definition);
    FunctionType type = node.definition.element.type;
    bool hasReturnType = !type.returnType.treatAsDynamic;
    if (hasReturnType) {
      // This function cannot occur in expression context.
      // The successor will be filled in by visitLetPrim.
      return new FunctionDeclaration(getVariable(node), def, null);
    } else {
      return new FunctionExpression(def);
    }
  }

  Expression visitParameter(cps_ir.Parameter node) {
    // Continuation parameters are not visited (continuations themselves are
    // not visited yet).
    internalError(CURRENT_ELEMENT_SPANNABLE, 'Unexpected IR node: $node');
    return null;
  }

  Expression visitContinuation(cps_ir.Continuation node) {
    // Until continuations with multiple uses are supported, they are not
    // visited.
    internalError(CURRENT_ELEMENT_SPANNABLE, 'Unexpected IR node: $node.');
    return null;
  }

  Expression visitIsTrue(cps_ir.IsTrue node) {
    return getVariableUse(node.value);
  }
}

