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
class Builder implements cps_ir.Visitor<Node> {
  final dart2js.InternalErrorFunction internalError;

  final Map<cps_ir.Primitive, Variable> primitive2variable =
      <cps_ir.Primitive, Variable>{};
  final Map<cps_ir.MutableVariable, Variable> mutable2variable =
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
  /// The 'this' Parameter for currentElement or the enclosing method.
  cps_ir.Parameter thisParameter;
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
    assert(!mutable2variable.containsKey(irVariable));
    Variable variable = new Variable(currentElement, irVariable.hint);
    mutable2variable[irVariable] = variable;
    return variable;
  }

  Variable getMutableVariable(cps_ir.MutableVariable mutableVariable) {
    if (!mutable2variable.containsKey(mutableVariable)) {
      return parent.getMutableVariable(mutableVariable)..isCaptured = true;
    }
    return mutable2variable[mutableVariable];
  }

  VariableUse getMutableVariableUse(
        cps_ir.Reference<cps_ir.MutableVariable> reference) {
    Variable variable = getMutableVariable(reference.definition);
    return new VariableUse(variable);
  }

  /// Obtains the variable representing the given primitive. Returns null for
  /// primitives that have no reference and do not need a variable.
  Variable getVariable(cps_ir.Primitive primitive) {
    return primitive2variable.putIfAbsent(primitive,
        () => new Variable(currentElement, primitive.hint));
  }

  /// Obtains a reference to the tree Variable corresponding to the IR primitive
  /// referred to by [reference].
  /// This increments the reference count for the given variable, so the
  /// returned expression must be used in the tree.
  Expression getVariableUse(cps_ir.Reference<cps_ir.Primitive> reference) {
    if (thisParameter != null && reference.definition == thisParameter) {
      return new This();
    }
    return new VariableUse(getVariable(reference.definition));
  }

  Variable addFunctionParameter(cps_ir.Definition variable) {
    if (variable is cps_ir.Parameter) {
      return getVariable(variable);
    } else {
      return addMutableVariable(variable as cps_ir.MutableVariable)
              ..isCaptured = true;
    }
  }

  FunctionDefinition buildFunction(cps_ir.FunctionDefinition node) {
    currentElement = node.element;
    if (parent != null) {
      // Local function's 'this' refers to enclosing method's 'this'
      thisParameter = parent.thisParameter;
    } else {
      thisParameter = node.thisParameter;
    }
    List<Variable> parameters =
        node.parameters.map(addFunctionParameter).toList();
    returnContinuation = node.returnContinuation;
    phiTempVar = new Variable(node.element, null);
    Statement body = visit(node.body);
    return new FunctionDefinition(node.element, parameters, body);
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

  Statement buildContinuationAssignment(
      cps_ir.Parameter parameter,
      Expression argument,
      Statement buildRest()) {
    Expression expr;
    if (parameter.hasAtLeastOneUse) {
      expr = new Assign(getVariable(parameter), argument);
    } else {
      expr = argument;
    }
    return new ExpressionStatement(expr, buildRest());
  }

  /// Simultaneously assigns each argument to the corresponding parameter,
  /// then continues at the statement created by [buildRest].
  Statement buildPhiAssignments(
      List<cps_ir.Parameter> parameters,
      List<Expression> arguments,
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
      Expression arg = arguments[i];
      if (arg is VariableUse) {
        if (param == null || param == arg.variable) {
          // No assignment necessary.
          --arg.variable.readCount;
          continue;
        }
        // v1 = v0
        List<int> list = rightHand[arg.variable];
        if (list == null) {
          rightHand[arg.variable] = list = <int>[];
        }
        list.add(i);
      } else {
        // v1 = this;
      }
    }

    Statement first, current;
    void addAssignment(Variable dst, Expression src) {
      if (first == null) {
        first = current = Assign.makeStatement(dst, src);
      } else {
        current = current.next = Assign.makeStatement(dst, src);
      }
    }

    List<Expression> assignmentSrc = new List<Expression>(parameters.length);
    List<bool> done = new List<bool>.filled(parameters.length, false);
    void visitAssignment(int i) {
      if (done[i]) {
        return;
      }
      Variable param = getVariable(parameters[i]);
      Expression arg = arguments[i];
      if (param == null || (arg is VariableUse && param == arg.variable)) {
        return; // No assignment necessary.
      }
      if (assignmentSrc[i] != null) {
        // Cycle found; store argument in a temporary variable.
        // The temporary will then be used as right-hand side when the
        // assignment gets added.
        VariableUse source = assignmentSrc[i];
        if (source.variable != phiTempVar) { // Only move to temporary once.
          assignmentSrc[i] = new VariableUse(phiTempVar);
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
      if (!done[i]) {
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

  visit(cps_ir.Node node) => node.accept(this);

  unexpectedNode(cps_ir.Node node) {
    internalError(CURRENT_ELEMENT_SPANNABLE, 'Unexpected IR node: $node');
  }

  // JS-specific nodes are handled by a subclass.
  visitSetField(cps_ir.SetField node) => unexpectedNode(node);
  visitIdentical(cps_ir.Identical node) => unexpectedNode(node);
  visitInterceptor(cps_ir.Interceptor node) => unexpectedNode(node);
  visitCreateInstance(cps_ir.CreateInstance node) => unexpectedNode(node);
  visitGetField(cps_ir.GetField node) => unexpectedNode(node);
  visitCreateBox(cps_ir.CreateBox node) => unexpectedNode(node);
  visitCreateInvocationMirror(cps_ir.CreateInvocationMirror node) {
    return unexpectedNode(node);
  }

  // Executable definitions are not visited directly.  They have 'build'
  // functions as entry points.
  visitFunctionDefinition(cps_ir.FunctionDefinition node) {
    return unexpectedNode(node);
  }

  Statement visitLetPrim(cps_ir.LetPrim node) {
    Variable variable = getVariable(node.primitive);

    // Don't translate unused primitives.
    if (variable == null) return visit(node.body);

    Expression value = visit(node.primitive);
    return Assign.makeStatement(variable, value, visit(node.body));
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
    InvokeMethod invoke = new InvokeMethod(getVariableUse(node.receiver),
                                           node.selector,
                                           translateArguments(node.arguments));
    invoke.receiverIsNotNull = node.receiverIsNotNull;
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

  Statement visitThrow(cps_ir.Throw node) {
    Expression value = getVariableUse(node.value);
    return new Throw(value);
  }

  Statement visitRethrow(cps_ir.Rethrow node) {
    return new Rethrow();
  }

  Expression visitNonTailThrow(cps_ir.NonTailThrow node) {
    unexpectedNode(node);
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
    Statement body = visit(node.body);
    return Assign.makeStatement(variable, value, body);
  }

  Expression visitGetMutableVariable(cps_ir.GetMutableVariable node) {
    return getMutableVariableUse(node.variable);
  }

  Statement visitSetMutableVariable(cps_ir.SetMutableVariable node) {
    Variable variable = getMutableVariable(node.variable.definition);
    Expression value = getVariableUse(node.value);
    return Assign.makeStatement(variable, value, visit(node.body));
  }

  Statement visitTypeOperator(cps_ir.TypeOperator node) {
    Expression value = getVariableUse(node.value);
    List<Expression> typeArgs = translateArguments(node.typeArguments);
    Expression concat =
        new TypeOperator(value, node.type, typeArgs,
                         isTypeTest: node.isTypeTest);
    return continueWithExpression(node.continuation, concat);
  }

  Statement visitInvokeConstructor(cps_ir.InvokeConstructor node) {
    List<Expression> arguments = translateArguments(node.arguments);
    Expression invoke = new InvokeConstructor(
        node.type,
        node.target,
        node.selector,
        arguments);
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
      List<Expression> arguments = translateArguments(node.arguments);
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
    return new Constant(node.expression, node.value);
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

  Expression visitCreateFunction(cps_ir.CreateFunction node) {
    FunctionDefinition def = makeSubFunction(node.definition);
    FunctionType type = node.definition.element.type;
    bool hasReturnType = !type.returnType.treatAsDynamic;
    return new FunctionExpression(def);
  }

  visitParameter(cps_ir.Parameter node) {
    // Continuation parameters are not visited (continuations themselves are
    // not visited yet).
    unexpectedNode(node);
  }

  visitContinuation(cps_ir.Continuation node) {
    // Until continuations with multiple uses are supported, they are not
    // visited.
    unexpectedNode(node);
  }

  visitMutableVariable(cps_ir.MutableVariable node) {
    // These occur as parameters or bound by LetMutable.  They are not visited
    // directly.
    unexpectedNode(node);
  }

  Expression visitIsTrue(cps_ir.IsTrue node) {
    return getVariableUse(node.value);
  }

  Expression visitReifyRuntimeType(cps_ir.ReifyRuntimeType node) {
    return new ReifyRuntimeType(getVariableUse(node.value));
  }

  Expression visitReadTypeVariable(cps_ir.ReadTypeVariable node) {
    return new ReadTypeVariable(node.variable, getVariableUse(node.target));
  }

  @override
  Node visitTypeExpression(cps_ir.TypeExpression node) {
    return new TypeExpression(
        node.dartType,
        node.arguments.map(getVariableUse).toList());
  }

  Expression visitGetStatic(cps_ir.GetStatic node) {
    return new GetStatic(node.element, node.sourceInformation);
  }

  Statement visitGetLazyStatic(cps_ir.GetLazyStatic node) {
    // In the tree IR, GetStatic handles lazy fields because tree
    // expressions are allowed to have side effects.
    GetStatic value = new GetStatic(node.element, node.sourceInformation);
    return continueWithExpression(node.continuation, value);
  }

  Statement visitSetStatic(cps_ir.SetStatic node) {
    SetStatic setStatic = new SetStatic(
        node.element,
        getVariableUse(node.value),
        node.sourceInformation);
    return new ExpressionStatement(setStatic, visit(node.body));
  }
}

