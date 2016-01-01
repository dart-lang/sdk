// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library tree_ir_builder;

import '../common.dart';
import '../constants/values.dart';
import '../cps_ir/cps_ir_nodes.dart' as cps_ir;
import '../elements/elements.dart';
import 'package:js_ast/js_ast.dart' as js;

import 'tree_ir_nodes.dart';

typedef Statement NodeCallback(Statement next);

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
class Builder implements cps_ir.Visitor/*<NodeCallback|Node>*/ {
  final InternalErrorFunction internalError;

  final Map<cps_ir.Primitive, Variable> primitive2variable =
      <cps_ir.Primitive, Variable>{};
  final Map<cps_ir.MutableVariable, Variable> mutable2variable =
      <cps_ir.MutableVariable, Variable>{};
  final Set<cps_ir.Constant> inlinedConstants = new Set<cps_ir.Constant>();

  // Continuations with more than one use are replaced with Tree labels.  This
  // is the mapping from continuations to labels.
  final Map<cps_ir.Continuation, Label> labels = <cps_ir.Continuation, Label>{};

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
    primitive = primitive.effectiveDefinition;
    return primitive2variable.putIfAbsent(primitive,
        () => new Variable(currentElement, primitive.hint));
  }

  /// Obtains a reference to the tree Variable corresponding to the IR primitive
  /// referred to by [reference].
  /// This increments the reference count for the given variable, so the
  /// returned expression must be used in the tree.
  Expression getVariableUse(cps_ir.Reference<cps_ir.Primitive> reference) {
    cps_ir.Primitive prim = reference.definition.effectiveDefinition;
    if (prim is cps_ir.Constant && inlinedConstants.contains(prim)) {
      return new Constant(prim.value);
    }
    if (thisParameter != null && prim == thisParameter) {
      return new This();
    }
    return new VariableUse(getVariable(prim));
  }

  Expression getVariableUseOrNull(
        cps_ir.Reference<cps_ir.Primitive> reference) {
    return reference == null ? null : getVariableUse(reference);
  }

  Label getLabel(cps_ir.Continuation cont) {
    return labels.putIfAbsent(cont, () => new Label());
  }

  Variable addFunctionParameter(cps_ir.Parameter parameter) {
    return getVariable(parameter);
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
    Statement body = translateExpression(node.body);
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

  visit(cps_ir.Node node) => throw 'Use translateXXX instead of visit';

  /// Translates a CPS expression into a tree statement.
  ///
  /// To avoid deep recursion, we traverse each basic blocks without
  /// recursion.
  ///
  /// Non-tail expressions evaluate to a callback to be invoked once the
  /// successor statement has been constructed. These callbacks are stored
  /// in a stack until the block's tail expression has been translated.
  Statement translateExpression(cps_ir.Expression node) {
    List<NodeCallback> stack = <NodeCallback>[];
    while (node is! cps_ir.TailExpression) {
      stack.add(node.accept(this));
      node = node.next;
    }
    Statement result = node.accept(this); // Translate the tail expression.
    for (NodeCallback fun in stack.reversed) {
      result = fun(result);
    }
    return result;
  }

  /// Translates a CPS primitive to a tree expression.
  ///
  /// This simply calls the visit method for the primitive.
  translatePrimitive(cps_ir.Primitive prim) {
    return prim.accept(this);
  }

  /************************ CONSTANT COPYING *****************************/

  /// Estimate of the number of characters needed to emit a use of the given
  /// constant.
  int constantSize(PrimitiveConstantValue value) {
    // TODO(asgerf): We could interface with the emitter to get the exact size.
    if (value is StringConstantValue) {
      // Account for the quotes, but ignore the cost of encoding non-ASCII
      // characters to avoid traversing the string and depending on encoding.
      return value.length + 2;
    } else if (value is BoolConstantValue) {
      return 2; // Printed as !0 and !1 when minified
    } else {
      // TODO(asgerf): Get the exact length of numbers using '1e10' notation.
      return '${value.primitiveValue}'.length;
    }
  }

  /// The number of uses [prim] has, or `-1` if it is used in a phi assignment.
  int countNonPhiUses(cps_ir.Primitive prim) {
    int count = 0;
    for (cps_ir.Reference ref = prim.firstRef; ref != null; ref = ref.next) {
      cps_ir.Node use = ref.parent;
      if (use is cps_ir.InvokeContinuation) {
        return -1;
      }
      count++;
    }
    return count;
  }

  /// True if the given [constant] should be copied to every use site.
  bool shouldCopyToUses(cps_ir.Constant constant) {
    if (!constant.value.isPrimitive) return false;
    if (constant.hasAtMostOneUse) return true;
    int uses = countNonPhiUses(constant);
    if (uses == -1) return false; // Copying might prevent elimination of a phi.
    int size = constantSize(constant.value);
    // Compare the expected code size output of copying vs sharing.
    const int USE = 2; // Minified locals usually have length 2.
    const int ASSIGN = USE + 2; // Variable and '=' and ';'
    const int BIAS = 2; // Artificial bias to slightly favor copying.
    int costOfSharing = USE * uses + size + ASSIGN + BIAS;
    int costOfCopying = size * uses;
    return costOfCopying <= costOfSharing;
  }

  /************************ INTERIOR EXPRESSIONS  ************************/
  //
  // Visit methods for interior expressions must return a function:
  //
  //    (Statement next) => <result statement>
  //

  NodeCallback visitLetPrim(cps_ir.LetPrim node) {
    if (node.primitive is cps_ir.Constant && shouldCopyToUses(node.primitive)) {
      inlinedConstants.add(node.primitive);
      return (Statement next) => next;
    }
    Variable variable = getVariable(node.primitive);
    var value = translatePrimitive(node.primitive);
    if (value is Expression) {
      if (node.primitive.hasAtLeastOneUse) {
        return (Statement next) => Assign.makeStatement(variable, value, next);
      } else {
        return (Statement next) => new ExpressionStatement(value, next);
      }
    } else {
      assert(value is NodeCallback);
      return value;
    }
  }

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
  // See [visitInvokeContinuation] for the implementation.
  NodeCallback visitLetCont(cps_ir.LetCont node) => (Statement next) {
    for (cps_ir.Continuation continuation in node.continuations) {
      // This happens after the body of the LetCont has been translated.
      // Labels are created on-demand if the continuation could not be inlined,
      // so the existence of the label indicates if a labeled statement should
      // be emitted.
      Label label = labels[continuation];
      if (label != null && !continuation.isRecursive) {
        // Recursively build the body. We only do this for join continuations,
        // so we should not risk overly deep recursion.
        next = new LabeledStatement(
            label,
            next,
            translateExpression(continuation.body));
      }
    }
    return next;
  };

  NodeCallback visitLetHandler(cps_ir.LetHandler node) => (Statement next) {
    List<Variable> catchParameters =
        node.handler.parameters.map(getVariable).toList();
    Statement catchBody = translateExpression(node.handler.body);
    return new Try(next, catchParameters, catchBody);
  };

  NodeCallback visitLetMutable(cps_ir.LetMutable node) {
    Variable variable = addMutableVariable(node.variable);
    Expression value = getVariableUse(node.value);
    return (Statement next) => Assign.makeStatement(variable, value, next);
  }

  /************************** TAIL EXPRESSIONS  **************************/
  //
  // Visit methods for tail expressions must return a statement directly
  // (not a function like interior and call expressions).

  Statement visitThrow(cps_ir.Throw node) {
    Expression value = getVariableUse(node.value);
    return new Throw(value);
  }

  Statement visitRethrow(cps_ir.Rethrow node) {
    return new Rethrow();
  }

  Statement visitUnreachable(cps_ir.Unreachable node) {
    return new Unreachable();
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
      return new Return(getVariableUse(node.arguments.single),
                        sourceInformation: node.sourceInformation);
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
                  ? new Continue(getLabel(cont))
                  : new WhileTrue(getLabel(cont),
                                  translateExpression(cont.body));
            } else {
              return cont.hasExactlyOneUse && !node.isEscapingTry
                  ? translateExpression(cont.body)
                  : new Break(getLabel(cont));
            }
          });
    }
  }

  /// Translates a branch condition to a tree expression.
  Expression translateCondition(cps_ir.Branch branch) {
    Expression value = getVariableUse(branch.condition);
    if (branch.isStrictCheck) {
      return new ApplyBuiltinOperator(
          BuiltinOperator.StrictEq,
          <Expression>[value, new Constant(new TrueConstantValue())]);
    } else {
      return value;
    }
  }

  Statement visitBranch(cps_ir.Branch node) {
    Expression condition = translateCondition(node);
    Statement thenStatement, elseStatement;
    cps_ir.Continuation cont = node.trueContinuation.definition;
    assert(cont.parameters.isEmpty);
    thenStatement = cont.hasExactlyOneUse
        ? translateExpression(cont.body)
        : new Break(labels[cont]);
    cont = node.falseContinuation.definition;
    assert(cont.parameters.isEmpty);
    elseStatement = cont.hasExactlyOneUse
        ? translateExpression(cont.body)
        : new Break(labels[cont]);
    return new If(condition, thenStatement, elseStatement);
  }


  /************************** PRIMITIVES  **************************/
  //
  // Visit methods for primitives must return an expression.
  //

  Expression visitSetField(cps_ir.SetField node) {
    return new SetField(getVariableUse(node.object),
                        node.field,
                        getVariableUse(node.value));
  }

  Expression visitInterceptor(cps_ir.Interceptor node) {
    return new Interceptor(getVariableUse(node.input),
                           node.interceptedClasses,
                           node.sourceInformation);
  }

  Expression visitCreateInstance(cps_ir.CreateInstance node) {
    return new CreateInstance(
        node.classElement,
        translateArguments(node.arguments),
        translateArguments(node.typeInformation),
        node.sourceInformation);
  }

  Expression visitGetField(cps_ir.GetField node) {
    return new GetField(getVariableUse(node.object), node.field,
        objectIsNotNull: !node.object.definition.type.isNullable);
  }

  Expression visitCreateBox(cps_ir.CreateBox node) {
    return new CreateBox();
  }

  Expression visitCreateInvocationMirror(cps_ir.CreateInvocationMirror node) {
    return new CreateInvocationMirror(
        node.selector,
        translateArguments(node.arguments));
  }

  Expression visitGetMutable(cps_ir.GetMutable node) {
    return getMutableVariableUse(node.variable);
  }

  Expression visitSetMutable(cps_ir.SetMutable node) {
    Variable variable = getMutableVariable(node.variable.definition);
    Expression value = getVariableUse(node.value);
    return new Assign(variable, value);
  }

  Expression visitConstant(cps_ir.Constant node) {
    return new Constant(node.value, sourceInformation: node.sourceInformation);
  }

  Expression visitLiteralList(cps_ir.LiteralList node) {
    return new LiteralList(
            node.dartType,
            translateArguments(node.values));
  }

  Expression visitLiteralMap(cps_ir.LiteralMap node) {
    return new LiteralMap(
        node.dartType,
        new List<LiteralMapEntry>.generate(node.entries.length, (int index) {
          return new LiteralMapEntry(
              getVariableUse(node.entries[index].key),
              getVariableUse(node.entries[index].value));
        })
    );
  }

  Expression visitReifyRuntimeType(cps_ir.ReifyRuntimeType node) {
    return new ReifyRuntimeType(
        getVariableUse(node.value), node.sourceInformation);
  }

  Expression visitReadTypeVariable(cps_ir.ReadTypeVariable node) {
    return new ReadTypeVariable(
        node.variable,
        getVariableUse(node.target),
        node.sourceInformation);
  }

  Expression visitTypeExpression(cps_ir.TypeExpression node) {
    return new TypeExpression(
        node.dartType,
        node.arguments.map(getVariableUse).toList());
  }

  Expression visitTypeTest(cps_ir.TypeTest node) {
    Expression value = getVariableUse(node.value);
    List<Expression> typeArgs = translateArguments(node.typeArguments);
    return new TypeOperator(value, node.dartType, typeArgs, isTypeTest: true);
  }

  Expression visitTypeTestViaFlag(cps_ir.TypeTestViaFlag node) {
    Expression value = getVariableUse(node.interceptor);
    // TODO(sra): Move !! to cps_ir level.
    return new Not(new Not(new GetTypeTestProperty(value, node.dartType)));
  }

  Expression visitGetStatic(cps_ir.GetStatic node) {
    return new GetStatic(node.element, node.sourceInformation);
  }

  Expression visitSetStatic(cps_ir.SetStatic node) {
    return new SetStatic(
        node.element,
        getVariableUse(node.value),
        node.sourceInformation);
  }

  Expression visitApplyBuiltinOperator(cps_ir.ApplyBuiltinOperator node) {
    if (node.operator == BuiltinOperator.IsFalsy) {
      return new Not(getVariableUse(node.arguments.single));
    }
    return new ApplyBuiltinOperator(node.operator,
                                    translateArguments(node.arguments));
  }

  Expression visitApplyBuiltinMethod(cps_ir.ApplyBuiltinMethod node) {
    return new ApplyBuiltinMethod(node.method,
        getVariableUse(node.receiver),
        translateArguments(node.arguments),
        receiverIsNotNull: !node.receiver.definition.type.isNullable);
  }

  Expression visitGetLength(cps_ir.GetLength node) {
    return new GetLength(getVariableUse(node.object));
  }

  Expression visitGetIndex(cps_ir.GetIndex node) {
    return new GetIndex(getVariableUse(node.object),
                        getVariableUse(node.index));
  }

  Expression visitSetIndex(cps_ir.SetIndex node) {
    return new SetIndex(getVariableUse(node.object),
                        getVariableUse(node.index),
                        getVariableUse(node.value));
  }

  Expression visitInvokeStatic(cps_ir.InvokeStatic node) {
    List<Expression> arguments = translateArguments(node.arguments);
    return new InvokeStatic(node.target, node.selector, arguments,
                                         node.sourceInformation);
  }

  Expression visitInvokeMethod(cps_ir.InvokeMethod node) {
    if (node.callingConvention == cps_ir.CallingConvention.OneShotIntercepted) {
      List<Expression> arguments = new List.generate(
          1 + node.arguments.length,
          (n) => getVariableUse(n == 0 ? node.receiver : node.arguments[n - 1]),
          growable: false);
      return new OneShotInterceptor(node.selector, node.mask, arguments,
          node.sourceInformation);
    }
    InvokeMethod invoke = new InvokeMethod(
        getVariableUse(node.receiver),
        node.selector,
        node.mask,
        translateArguments(node.arguments),
        node.sourceInformation);
    // Sometimes we know the Dart receiver is non-null because it has been
    // refined, which implies that the JS receiver also can not be null at the
    // use-site.  Interceptors are not refined, so this information is not
    // always available on the JS receiver.
    // Also check the JS receiver's type, however, because sometimes we know an
    // interceptor is non-null because it intercepts JSNull.
    invoke.receiverIsNotNull =
        !node.dartReceiver.type.isNullable ||
        !node.receiver.definition.type.isNullable;
    return invoke;
  }

  Expression visitInvokeMethodDirectly(cps_ir.InvokeMethodDirectly node) {
    Expression receiver = getVariableUse(node.receiver);
    List<Expression> arguments = translateArguments(node.arguments);
    return new InvokeMethodDirectly(receiver, node.target,
        node.selector, arguments, node.sourceInformation);
  }

  Expression visitTypeCast(cps_ir.TypeCast node) {
    Expression value = getVariableUse(node.value);
    List<Expression> typeArgs = translateArguments(node.typeArguments);
    return new TypeOperator(value, node.dartType, typeArgs, isTypeTest: false);
  }

  Expression visitInvokeConstructor(cps_ir.InvokeConstructor node) {
    List<Expression> arguments = translateArguments(node.arguments);
    return new InvokeConstructor(
        node.dartType,
        node.target,
        node.selector,
        arguments,
        node.sourceInformation);
  }

  visitForeignCode(cps_ir.ForeignCode node) {
    List<Expression> arguments =
        node.arguments.map(getVariableUse).toList(growable: false);
    List<bool> nullableArguments = node.arguments
        .map((argument) => argument.definition.type.isNullable)
        .toList(growable: false);
    if (node.codeTemplate.isExpression) {
      return new ForeignExpression(
          node.codeTemplate,
          node.type,
          arguments,
          node.nativeBehavior,
          nullableArguments,
          node.dependency);
    } else {
      return (Statement next) {
        assert(next is Unreachable); // We are not using the `next` statement.
        return new ForeignStatement(
            node.codeTemplate,
            node.type,
            arguments,
            node.nativeBehavior,
            nullableArguments,
            node.dependency);
      };
    }
  }

  visitNullCheck(cps_ir.NullCheck node) => (Statement next) {
    return new NullCheck(
        condition: getVariableUseOrNull(node.condition),
        value: getVariableUse(node.value),
        selector: node.selector,
        next: next,
        sourceInformation: node.sourceInformation);
  };

  Expression visitGetLazyStatic(cps_ir.GetLazyStatic node) {
    return new GetStatic.lazy(node.element, node.sourceInformation);
  }

  @override
  NodeCallback visitYield(cps_ir.Yield node) {
    return (Statement next) {
      return new Yield(getVariableUse(node.input), node.hasStar, next);
    };
  }

  @override
  Expression visitAwait(cps_ir.Await node) {
    return new Await(getVariableUse(node.input));
  }

  @override
  visitRefinement(cps_ir.Refinement node) {
    return (Statement next) => next; // Compile to nothing.
  }

  @override
  Expression visitBoundsCheck(cps_ir.BoundsCheck node) {
    throw 'Unexpected BoundsCheck node in tree builder';
  }

  /********** UNUSED VISIT METHODS *************/

  unexpectedNode(cps_ir.Node node) {
    internalError(CURRENT_ELEMENT_SPANNABLE, 'Unexpected IR node: $node');
  }

  visitFunctionDefinition(cps_ir.FunctionDefinition node) {
    unexpectedNode(node);
  }
  visitParameter(cps_ir.Parameter node) => unexpectedNode(node);
  visitContinuation(cps_ir.Continuation node) => unexpectedNode(node);
  visitMutableVariable(cps_ir.MutableVariable node) => unexpectedNode(node);
}
