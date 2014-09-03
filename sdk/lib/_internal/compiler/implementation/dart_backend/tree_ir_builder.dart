// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library tree_ir_builder;

import '../dart2jslib.dart' as dart2js;
import '../elements/elements.dart';
import '../cps_ir/cps_ir_nodes.dart' as cps_ir;
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
  final dart2js.Compiler compiler;

  /// Maps variable/parameter elements to the Tree variables that represent it.
  final Map<Element, List<Variable>> element2variables =
      <Element,List<Variable>>{};

  /// Like [element2variables], except for closure variables. Closure variables
  /// are not subject to SSA, so at most one variable is used per local.
  final Map<Local, Variable> local2closure = <Local, Variable>{};

  // Continuations with more than one use are replaced with Tree labels.  This
  // is the mapping from continuations to labels.
  final Map<cps_ir.Continuation, Label> labels = <cps_ir.Continuation, Label>{};

  FunctionDefinition function;
  cps_ir.Continuation returnContinuation;

  Builder parent;

  Builder(this.compiler);

  Builder.inner(Builder parent)
      : this.parent = parent,
        compiler = parent.compiler;

  /// Variable used in [buildPhiAssignments] as a temporary when swapping
  /// variables.
  Variable phiTempVar;

  Variable getClosureVariable(Local local) {
    if (local.executableContext != function.element) {
      return parent.getClosureVariable(local);
    }
    Variable variable = local2closure[local];
    if (variable == null) {
      variable = new Variable(function, local);
      local2closure[local] = variable;
    }
    return variable;
  }

  /// Obtains the variable representing the given primitive. Returns null for
  /// primitives that have no reference and do not need a variable.
  Variable getVariable(cps_ir.Primitive primitive) {
    if (primitive.registerIndex == null) {
      return null; // variable is unused
    }
    List<Variable> variables = element2variables[primitive.hint];
    if (variables == null) {
      variables = <Variable>[];
      element2variables[primitive.hint] = variables;
    }
    while (variables.length <= primitive.registerIndex) {
      variables.add(new Variable(function, primitive.hint));
    }
    return variables[primitive.registerIndex];
  }

  /// Obtains a reference to the tree Variable corresponding to the IR primitive
  /// referred to by [reference].
  /// This increments the reference count for the given variable, so the
  /// returned expression must be used in the tree.
  Expression getVariableReference(cps_ir.Reference reference) {
    Variable variable = getVariable(reference.definition);
    if (variable == null) {
      compiler.internalError(
          compiler.currentElement,
          "Reference to ${reference.definition} has no register");
    }
    ++variable.readCount;
    return variable;
  }

  FunctionDefinition build(cps_ir.FunctionDefinition node) {
    visit(node);
    return function;
  }

  List<Expression> translateArguments(List<cps_ir.Reference> args) {
    return new List<Expression>.generate(args.length,
         (int index) => getVariableReference(args[index]));
  }

  List<Variable> translatePhiArguments(List<cps_ir.Reference> args) {
    return new List<Variable>.generate(args.length,
         (int index) => getVariableReference(args[index]));
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
        first = current = new Assign(dst, src, null);
      } else {
        current = current.next = new Assign(dst, src, null);
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

  visitNode(cps_ir.Node node) => throw "Unhandled node: $node";

  Expression visitFunctionDefinition(cps_ir.FunctionDefinition node) {
    List<Variable> parameters = <Variable>[];
    function = new FunctionDefinition(node.element, parameters,
        null, node.localConstants, node.defaultParameterValues);
    returnContinuation = node.returnContinuation;
    for (cps_ir.Parameter p in node.parameters) {
      Variable parameter = getVariable(p);
      assert(parameter != null);
      ++parameter.writeCount; // Being a parameter counts as a write.
      parameters.add(parameter);
    }
    if (!node.isAbstract) {
      phiTempVar = new Variable(function, null);
      function.body = visit(node.body);
    }
    return null;
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

  Statement visitLetCont(cps_ir.LetCont node) {
    Label label;
    if (node.continuation.hasMultipleUses) {
      label = new Label();
      labels[node.continuation] = label;
    }
    Statement body = visit(node.body);
    // The continuation's body is not always translated directly here because
    // it may have been already translated:
    //   * For singly-used continuations, the continuation's body is
    //     translated at the site of the continuation invocation.
    //   * For recursive continuations, there is a single non-recursive
    //     invocation.  The continuation's body is translated at the site
    //     of the non-recursive continuation invocation.
    // See visitInvokeContinuation for the implementation.
    if (label == null || node.continuation.isRecursive) return body;
    return new LabeledStatement(label, body, visit(node.continuation.body));
  }

  Statement visitInvokeStatic(cps_ir.InvokeStatic node) {
    // Calls are translated to direct style.
    List<Expression> arguments = translateArguments(node.arguments);
    Expression invoke = new InvokeStatic(node.target, node.selector, arguments);
    return continueWithExpression(node.continuation, invoke);
  }

  Statement visitInvokeMethod(cps_ir.InvokeMethod node) {
    Expression receiver = getVariableReference(node.receiver);
    List<Expression> arguments = translateArguments(node.arguments);
    Expression invoke = new InvokeMethod(receiver, node.selector, arguments);
    return continueWithExpression(node.continuation, invoke);
  }

  Statement visitInvokeSuperMethod(cps_ir.InvokeSuperMethod node) {
    List<Expression> arguments = translateArguments(node.arguments);
    Expression invoke = new InvokeSuperMethod(node.selector, arguments);
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

  Expression visitGetClosureVariable(cps_ir.GetClosureVariable node) {
    return getClosureVariable(node.variable);
  }

  Statement visitSetClosureVariable(cps_ir.SetClosureVariable node) {
    Variable variable = getClosureVariable(node.variable);
    Expression value = getVariableReference(node.value);
    return new Assign(variable, value, visit(node.body),
                      isDeclaration: node.isDeclaration);
  }

  Statement visitDeclareFunction(cps_ir.DeclareFunction node) {
    Variable variable = getClosureVariable(node.variable);
    FunctionDefinition function = makeSubFunction(node.definition);
    return new FunctionDeclaration(variable, function, visit(node.body));
  }

  Statement visitTypeOperator(cps_ir.TypeOperator node) {
    Expression receiver = getVariableReference(node.receiver);
    Expression concat = new TypeOperator(receiver, node.type, node.operator);
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
      return new Return(getVariableReference(node.arguments.single));
    } else {
      List<Expression> arguments = translatePhiArguments(node.arguments);
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
              return cont.hasExactlyOneUse
                  ? visit(cont.body)
                  : new Break(labels[cont]);
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
        translateArguments(node.keys),
        translateArguments(node.values));
  }

  FunctionDefinition makeSubFunction(cps_ir.FunctionDefinition function) {
    return new Builder.inner(this).build(function);
  }

  Node visitCreateFunction(cps_ir.CreateFunction node) {
    FunctionDefinition def = makeSubFunction(node.definition);
    FunctionSignature signature = node.definition.element.functionSignature;
    bool hasReturnType = !signature.type.returnType.treatAsDynamic;
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
    compiler.internalError(compiler.currentElement, 'Unexpected IR node.');
    return null;
  }

  Expression visitContinuation(cps_ir.Continuation node) {
    // Until continuations with multiple uses are supported, they are not
    // visited.
    compiler.internalError(compiler.currentElement, 'Unexpected IR node.');
    return null;
  }

  Expression visitIsTrue(cps_ir.IsTrue node) {
    return getVariableReference(node.value);
  }
}

