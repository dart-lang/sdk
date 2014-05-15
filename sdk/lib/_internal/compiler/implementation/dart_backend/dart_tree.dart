// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart_tree;

import '../dart2jslib.dart' as dart2js;
import '../elements/elements.dart'
    show Element, FunctionElement, FunctionSignature, ParameterElement,
         ClassElement;
import '../universe/universe.dart';
import '../ir/ir_nodes.dart' as ir;
import '../tree/tree.dart' as ast;
import '../scanner/scannerlib.dart';
import '../dart_types.dart' show DartType, GenericType;
import '../helpers/helpers.dart';
import '../universe/universe.dart' show Selector;

// The Tree language is the target of translation out of the CPS-based IR.
//
// The translation from CPS to Dart consists of several stages.  Among the
// stages are translation to direct style, translation out of SSA, eliminating
// unnecessary names, recognizing high-level control constructs.  Combining
// these separate concerns is complicated and the constraints of the CPS-based
// language do not permit a multi-stage translation.
//
// For that reason, CPS is translated to the direct-style language Tree.
// Translation out of SSA, unnaming, and control-flow, as well as 'instruction
// selection' are performed on the Tree language.
//
// In contrast to the CPS-based IR, non-primitive expressions can be named and
// arguments (to calls, primitives, and blocks) can be arbitrary expressions.

/**
 * The base class of all Tree nodes.
 */
abstract class Node {
}

/**
 * The base class of [Expression]s.
 */
abstract class Expression extends Node {
  bool get isPure;
  accept(Visitor v);

  /// Temporary variable used by [TreeRewriter].
  /// If set to true, this expression has already had enclosing assignments
  /// propagated into its variables, and should not be processed again.
  /// It is only set for expressions that are known to be in risk of redundant
  /// processing.
  bool processed = false;
}

abstract class Statement extends Node {
  Statement get next;
  void set next(Statement s);
  accept(Visitor v);
}

/**
 * Labels name [LabeledStatement]s.
 */
class Label {
  // A counter used to generate names.  The counter is reset to 0 for each
  // function emitted.
  static int counter = 0;
  static String _newName() => 'L${counter++}';

  String cachedName;

  String get name {
    if (cachedName == null) cachedName = _newName();
    return cachedName;
  }

  /// Number of [Break] statements that target this label.
  /// The [Break] constructor will increment this automatically, but the
  /// counter must be decremented by hand when a [Break] becomes orphaned.
  int breakCount = 0;

  /// The [LabeledStatement] binding this label.
  LabeledStatement binding;
}

/**
 * Variables are [Expression]s.
 */
class Variable extends Expression {
  // A counter used to generate names.  The counter is reset to 0 for each
  // function emitted.
  static int counter = 0;
  static String _newName() => 'v${counter++}';

  Element element;
  String cachedName;

  String get name {
    if (cachedName != null) return cachedName;
    return cachedName = ((element == null) ? _newName() : element.name);
  }

  Variable(this.element);

  final bool isPure = true;

  accept(Visitor visitor) => visitor.visitVariable(this);
}

/**
 * Common interface for invocations with arguments.
 */
abstract class Invoke {
  List<Expression> get arguments;
  Selector get selector;
}

/**
 * A call to a static target.
 *
 * In contrast to the CPS-based IR, the arguments can be arbitrary expressions.
 */
class InvokeStatic extends Expression implements Invoke {
  final FunctionElement target;
  final List<Expression> arguments;
  final Selector selector;

  InvokeStatic(this.target, this.selector, this.arguments);

  final bool isPure = false;

  accept(Visitor visitor) => visitor.visitInvokeStatic(this);
}

/**
 * A call to a method, operator, getter, setter or index getter/setter.
 *
 * In contrast to the CPS-based IR, the receiver and arguments can be
 * arbitrary expressions.
 */
class InvokeMethod extends Expression implements Invoke {
  Expression receiver;
  final Selector selector;
  final List<Expression> arguments;

  InvokeMethod(this.receiver, this.selector, this.arguments) {
    assert(receiver != null);
  }

  final bool isPure = false;

  accept(Visitor visitor) => visitor.visitInvokeMethod(this);
}

/**
 * Non-const call to a factory or generative constructor.
 */
class InvokeConstructor extends Expression implements Invoke {
  final GenericType type;
  final FunctionElement target;
  final List<Expression> arguments;
  final Selector selector;

  InvokeConstructor(this.type, this.target, this.selector, this.arguments);

  ClassElement get targetClass => target.enclosingElement;

  final bool isPure = false;

  accept(Visitor visitor) => visitor.visitInvokeConstructor(this);
}

/// Calls [toString] on each argument and concatenates the results.
class ConcatenateStrings extends Expression {
  final List<Expression> arguments;

  ConcatenateStrings(this.arguments);

  final bool isPure = false; // invokes toString

  accept(Visitor visitor) => visitor.visitConcatenateStrings(this);
}

/**
 * A constant.
 */
class Constant extends Expression {
  final dart2js.Constant value;

  Constant(this.value);

  final bool isPure = true;

  accept(Visitor visitor) => visitor.visitConstant(this);
}

/// A conditional expression.
class Conditional extends Expression {
  Expression condition;
  Expression thenExpression;
  Expression elseExpression;

  Conditional(this.condition, this.thenExpression, this.elseExpression);

  // TODO(asgerf): Repeatedly computing isPure is potentially expensive,
  // but caching isPure in a field is dangerous because a subexpression could
  // become impure during a transformation (e.g. assignment propagation).
  // Improve the situation somehow.
  bool get isPure => condition.isPure &&
                     thenExpression.isPure &&
                     elseExpression.isPure;

  accept(Visitor visitor) => visitor.visitConditional(this);
}

/**
 * A labeled statement.  Breaks to the label within the labeled statement
 * target the successor statement.
 */
class LabeledStatement extends Statement {
  Statement next;
  final Label label;
  Statement body;

  LabeledStatement(this.label, this.body, this.next) {
    assert(label.binding == null);
    label.binding = this;
  }

  accept(Visitor visitor) => visitor.visitLabeledStatement(this);
}

/**
 * An assignments of an [Expression] to a [Variable].
 *
 * In contrast to the CPS-based IR, non-primitive expressions can be assigned
 * to variables.
 */
class Assign extends Statement {
  Statement next;
  final Variable variable;
  Expression definition;
  final bool hasExactlyOneUse;

  Assign(this.variable, this.definition, this.next, this.hasExactlyOneUse);

  accept(Visitor visitor) => visitor.visitAssign(this);
}

/**
 * A return exit from the function.
 *
 * In contrast to the CPS-based IR, the return value is an arbitrary
 * expression.
 */
class Return extends Statement {
  /// Should not be null. Use [Constant] with [NullConstant] for void returns.
  Expression value;

  Statement get next => null;
  void set next(Statement s) => throw 'UNREACHABLE';

  Return(this.value);

  accept(Visitor visitor) => visitor.visitReturn(this);
}

/**
 * A break from an enclosing [LabeledStatement].  The break targets the
 * labeled statement's successor statement.
 */
class Break extends Statement {
  Label _target;

  Label get target => _target;
  void set target(Label newTarget) {
    ++newTarget.breakCount;
    --_target.breakCount;
    _target = newTarget;
  }

  Statement get next => null;
  void set next(Statement s) => throw 'UNREACHABLE';

  Break(this._target) {
    ++target.breakCount;
  }

  accept(Visitor visitor) => visitor.visitBreak(this);
}

/**
 * A conditional branch based on the true value of an [Expression].
 */
class If extends Statement {
  Expression condition;
  Statement thenStatement;
  Statement elseStatement;

  Statement get next => null;
  void set next(Statement s) => throw 'UNREACHABLE';

  If(this.condition, this.thenStatement, this.elseStatement);

  accept(Visitor visitor) => visitor.visitIf(this);
}

class ExpressionStatement extends Statement {
  Statement next;
  Expression expression;

  ExpressionStatement(this.expression, this.next);

  accept(Visitor visitor) => visitor.visitExpressionStatement(this);
}

class FunctionDefinition extends Node {
  final List<Variable> parameters;
  Statement body;

  FunctionDefinition(this.parameters, this.body);
}

abstract class Visitor<S, E> {
  E visitExpression(Expression e) => e.accept(this);
  E visitVariable(Variable node);
  E visitInvokeStatic(InvokeStatic node);
  E visitInvokeMethod(InvokeMethod node);
  E visitInvokeConstructor(InvokeConstructor node);
  E visitConcatenateStrings(ConcatenateStrings node);
  E visitConstant(Constant node);
  E visitConditional(Conditional node);

  S visitStatement(Statement s) => s.accept(this);
  S visitLabeledStatement(LabeledStatement node);
  S visitAssign(Assign node);
  S visitReturn(Return node);
  S visitBreak(Break node);
  S visitIf(If node);
  S visitExpressionStatement(ExpressionStatement node);
}

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
class Builder extends ir.Visitor<Node> {
  final dart2js.Compiler compiler;

  // Uses of IR primitives are replaced with Tree variables.  This is the
  // mapping from primitives to variables.
  final Map<ir.Primitive, Variable> variables = <ir.Primitive, Variable>{};

  // Continuations with more than one use are replaced with Tree labels.  This
  // is the mapping from continuations to labels.
  final Map<ir.Continuation, Label> labels = <ir.Continuation, Label>{};

  FunctionDefinition function;
  ir.Continuation returnContinuation;

  Builder(this.compiler);

  FunctionDefinition build(ir.FunctionDefinition node) {
    visit(node);
    return function;
  }

  List<Expression> translateArguments(List<ir.Reference> args) {
    return new List<Expression>.generate(args.length,
         (int index) => variables[args[index].definition]);
  }

  Statement buildParameterAssignments(
      List<ir.Parameter> parameters,
      List<Expression> arguments,
      Statement buildRest()) {
    assert(parameters.length == arguments.length);
    Statement first, current;
    for (int i = 0; i < parameters.length; ++i) {
      ir.Parameter parameter = parameters[i];
      Statement assignment;
      if (parameter.hasAtLeastOneUse) {
        assignment = new Assign(variables[parameter], arguments[i], null,
            parameter.hasExactlyOneUse);
      } else {
        assignment = new ExpressionStatement(arguments[i], null);
      }

      if (first == null) {
        current = first = assignment;
      } else {
        current = current.next = assignment;
      }
    }

    if (first == null) {
      first = buildRest();
    } else {
      current.next = buildRest();
    }
    return first;
  }

  Expression visitFunctionDefinition(ir.FunctionDefinition node) {
    returnContinuation = node.returnContinuation;
    List<Variable> parameters = <Variable>[];
    for (ir.Parameter p in node.parameters) {
      Variable parameter = new Variable(p.element);
      parameters.add(parameter);
      variables[p] = parameter;
    }
    function = new FunctionDefinition(parameters, visit(node.body));
    return null;
  }

  Statement visitLetPrim(ir.LetPrim node) {
    // LetPrim is translated to LetVal.
    Expression definition = visit(node.primitive);
    if (node.primitive.hasAtLeastOneUse) {
      Variable variable = new Variable(null);
      variables[node.primitive] = variable;
      return new Assign(variable, definition, node.body.accept(this),
          node.primitive.hasExactlyOneUse);
    } else if (node.primitive is ir.Constant) {
      // TODO(kmillikin): Implement more systematic treatment of pure CPS
      // values (e.g., as part of a shrinking reductions pass).
      return visit(node.body);
    } else {
      return new ExpressionStatement(definition, visit(node.body));
    }
  }

  Statement visitLetCont(ir.LetCont node) {
    Label label;
    if (!node.continuation.hasAtMostOneUse) {
      label = new Label();
      labels[node.continuation] = label;
    }
    node.continuation.parameters.forEach((p) {
        if (p.hasAtLeastOneUse) variables[p] = new Variable(null);
    });
    Statement body = visit(node.body);
    if (label == null) return body;
    return new LabeledStatement(label, body, visit(node.continuation.body));
  }

  Statement visitInvokeStatic(ir.InvokeStatic node) {
    // Calls are translated to direct style.
    List<Expression> arguments = translateArguments(node.arguments);
    Expression invoke = new InvokeStatic(node.target, node.selector, arguments);
    ir.Continuation cont = node.continuation.definition;
    if (cont == returnContinuation) {
      return new Return(invoke);
    } else {
      assert(cont.hasExactlyOneUse);
      assert(cont.parameters.length == 1);
      return buildParameterAssignments(cont.parameters, [invoke],
          () => visit(cont.body));
    }
  }

  Statement visitInvokeMethod(ir.InvokeMethod node) {
    Variable receiver = variables[node.receiver.definition];
    List<Expression> arguments = translateArguments(node.arguments);
    Expression invoke = new InvokeMethod(receiver, node.selector, arguments);
    ir.Continuation cont = node.continuation.definition;
    if (cont == returnContinuation) {
      return new Return(invoke);
    } else {
      assert(cont.hasExactlyOneUse);
      assert(cont.parameters.length == 1);
      return buildParameterAssignments(cont.parameters, [invoke],
          () => visit(cont.body));
    }
  }

  Statement visitConcatenateStrings(ir.ConcatenateStrings node) {
    List<Expression> arguments = translateArguments(node.arguments);
    Expression concat = new ConcatenateStrings(arguments);
    ir.Continuation cont = node.continuation.definition;
    if (cont == returnContinuation) {
      return new Return(concat);
    } else {
      assert(cont.hasExactlyOneUse);
      assert(cont.parameters.length == 1);
      return buildParameterAssignments(cont.parameters, [concat],
          () => visit(cont.body));
    }
  }

  Statement visitInvokeConstructor(ir.InvokeConstructor node) {
    List<Expression> arguments = translateArguments(node.arguments);
    Expression invoke =
        new InvokeConstructor(node.type, node.target, node.selector, arguments);
    ir.Continuation cont = node.continuation.definition;
    if (cont == returnContinuation) {
      return new Return(invoke);
    } else {
      assert(cont.hasExactlyOneUse);
      assert(cont.parameters.length == 1);
      return buildParameterAssignments(cont.parameters, [invoke],
          () => visit(cont.body));
    }
  }

  Statement visitInvokeContinuation(ir.InvokeContinuation node) {
    // Invocations of the return continuation are translated to returns.
    // Other continuation invocations are replaced with assignments of the
    // arguments to formal parameter variables, followed by the body if
    // the continuation is singly reference or a break if it is multiply
    // referenced.
    ir.Continuation cont = node.continuation.definition;
    if (cont == returnContinuation) {
      assert(node.arguments.length == 1);
      return new Return(variables[node.arguments[0].definition]);
    } else {
      List<Expression> arguments = translateArguments(node.arguments);
      return buildParameterAssignments(cont.parameters, arguments,
          () => cont.hasExactlyOneUse
                    ? visit(cont.body)
                    : new Break(labels[cont]));
    }
  }

  Statement visitBranch(ir.Branch node) {
    Expression condition = visit(node.condition);
    Statement thenStatement, elseStatement;
    ir.Continuation cont = node.trueContinuation.definition;
    assert(cont.parameters.isEmpty);
    thenStatement =
        cont.hasExactlyOneUse ? visit(cont.body) : new Break(labels[cont]);
    cont = node.falseContinuation.definition;
    assert(cont.parameters.isEmpty);
    elseStatement =
        cont.hasExactlyOneUse ? visit(cont.body) : new Break(labels[cont]);
    return new If(condition, thenStatement, elseStatement);
  }

  Expression visitConstant(ir.Constant node) {
    return new Constant(node.value);
  }

  Expression visitParameter(ir.Parameter node) {
    // Continuation parameters are not visited (continuations themselves are
    // not visited yet).
    compiler.internalError(compiler.currentElement, 'Unexpected IR node.');
    return null;
  }

  Expression visitContinuation(ir.Continuation node) {
    // Until continuations with multiple uses are supported, they are not
    // visited.
    compiler.internalError(compiler.currentElement, 'Unexpected IR node.');
    return null;
  }

  Expression visitIsTrue(ir.IsTrue node) {
    return variables[node.value.definition];
  }
}

/**
 * Performs the following three transformations on the tree:
 * - Assignment propagation
 * - If-to-conditional conversion
 * - Break inlining
 *
 * The above transformations are performed in the same phase because each
 * transformation can introduce redexes of one of the others.
 *
 *
 * ASSIGNMENT PROPAGATION:
 * Single-use definitions are propagated to their use site when possible.
 * For example:
 *
 *   { v0 = foo(); return v0; }
 *     ==>
 *   return foo()
 *
 * After translating out of CPS, all intermediate values are bound by [Assign].
 * This transformation propagates such definitions to their uses when it is
 * safe and profitable.  Bindings are processed "on demand" when their uses are
 * seen, but are only processed once to keep this transformation linear in
 * the size of the tree.
 *
 * The transformation builds an environment containing [Assign] bindings that
 * are in scope.  These bindings have yet-untranslated definitions.  When a use
 * is encountered the transformation determines if it is safe and profitable
 * to propagate the definition to its use.  If so, it is removed from the
 * environment and the definition is recursively processed (in the
 * new environment at the use site) before being propagated.
 *
 * See [visitVariable] for the implementation of the heuristic for propagating
 * a definition.
 *
 *
 * IF-TO-CONDITIONAL CONVERSION:
 * If-statement are converted to conditional expressions when possible.
 * For example:
 *
 *   if (v0) { v1 = foo(); break L } else { v1 = bar(); break L }
 *     ==>
 *   { v1 = v0 ? foo() : bar(); break L }
 *
 * This can lead to inlining of L, which in turn can lead to further propagation
 * of the variable v1.
 *
 * See [visitIf].
 *
 *
 * BREAK INLINING:
 * Single-use labels are inlined at [Break] statements.
 * For example:
 *
 *   L0: { v0 = foo(); break L0 }; return v0;
 *     ==>
 *   v0 = foo(); return v0;
 *
 * This can lead to propagation of v0.
 *
 * See [visitBreak] and [visitLabeledStatement].
 */
class TreeRewriter extends Visitor<Statement, Expression> {
  // The binding environment.  The rightmost element of the list is the nearest
  // enclosing binding.
  // We use null to mark an impure expressions that does not bind a variable.
  List<Assign> environment;

  void apply(FunctionDefinition definition) {
    environment = <Assign>[];
    definition.body = visitStatement(definition.body);

    // TODO(kmillikin):  Allow definitions that are not propagated.  Here,
    // this means rebuilding the binding with a recursively unnamed definition,
    // or else introducing a variable definition and an assignment.
    assert(environment.isEmpty);
  }

  Expression visitExpression(Expression e) => e.processed ? e : e.accept(this);

  Expression visitVariable(Variable node) {
    // Propagate a variable's definition to its use site if:
    // 1.  It has a single use, to avoid code growth and potential duplication
    //     of side effects, AND
    // 2a. It is pure (i.e., does not have side effects that prevent it from
    //     being moved), OR
    // 2b. There are only pure expressions between the definition and use.

    // TODO(kmillikin): It's not always beneficial to propagate pure
    // definitions---it can prevent propagation of their inputs.  Implement
    // a heuristic to avoid this.

    // TODO(kmillikin): Replace linear search with something faster in
    // practice.
    bool seenImpure = false;
    for (int i = environment.length - 1; i >= 0; --i) {
      if (environment[i] == null) {
        seenImpure = true;
        continue;
      }
      if (environment[i].variable == node) {
        if ((!seenImpure || environment[i].definition.isPure)
            && environment[i].hasExactlyOneUse) {
          // Use the definition if it is pure or if it is the first impure
          // definition (i.e., propagating past only pure expressions).
          return visitExpression(environment.removeAt(i).definition);
        }
        break;
      } else if (!environment[i].definition.isPure) {
        // Once the first impure definition is seen, impure definitions should
        // no longer be propagated.  Continue searching for a pure definition.
        seenImpure = true;
      }
    }
    // If the definition could not be propagated, leave the variable use.
    return node;
  }

  Statement visitLabeledStatement(LabeledStatement node) {
    node.body = visitStatement(node.body);
    if (node.label.breakCount == 0) {
      // If the break was inlined, eliminate the label.
      return node.body;
    }
    node.next = visitStatement(node.next);
    return node;
  }

  Statement visitAssign(Assign node) {
    environment.add(node);
    Statement next = visitStatement(node.next);

    if (!environment.isEmpty && environment.last == node) {
      // The definition could not be propagated.  Residualize the let binding.
      node.next = next;
      environment.removeLast();
      node.definition = visitExpression(node.definition);
      return node;
    }
    assert(!environment.contains(node));
    return next;
  }

  Expression visitInvokeStatic(InvokeStatic node) {
    // Process arguments right-to-left, the opposite of evaluation order.
    for (int i = node.arguments.length - 1; i >= 0; --i) {
      node.arguments[i] = visitExpression(node.arguments[i]);
    }
    return node;
  }

  Expression visitInvokeMethod(InvokeMethod node) {
    for (int i = node.arguments.length - 1; i >= 0; --i) {
      node.arguments[i] = visitExpression(node.arguments[i]);
    }
    node.receiver = visitExpression(node.receiver);
    return node;
  }

  Expression visitInvokeConstructor(InvokeConstructor node) {
    for (int i = node.arguments.length - 1; i >= 0; --i) {
      node.arguments[i] = visitExpression(node.arguments[i]);
    }
    return node;
  }

  Expression visitConcatenateStrings(ConcatenateStrings node) {
    for (int i = node.arguments.length - 1; i >= 0; --i) {
      node.arguments[i] = visitExpression(node.arguments[i]);
    }
    return node;
  }

  Expression visitConditional(Conditional node) {
    node.condition = visitExpression(node.condition);

    environment.add(null); // impure expressions may not propagate across branch
    node.thenExpression = visitExpression(node.thenExpression);
    node.elseExpression = visitExpression(node.elseExpression);
    environment.removeLast();

    return node;
  }

  Statement visitReturn(Return node) {
    node.value = visitExpression(node.value);
    return node;
  }


  Statement visitBreak(Break node) {
    if (node.target.breakCount == 1) {
      --node.target.breakCount;
      return visitStatement(node.target.binding.next);
    }
    return node;
  }

  Statement visitIf(If node) {
    node.condition = visitExpression(node.condition);

    environment.add(null); // impure expressions may not propagate across branch
    node.thenStatement = visitStatement(node.thenStatement);
    node.elseStatement = visitStatement(node.elseStatement);
    environment.removeLast();

    Statement reduced = combineStatementsWithSubexpressions(
        node.thenStatement,
        node.elseStatement,
        (t,f) => new Conditional(node.condition, t, f)..processed = true);
    if (reduced != null) {
      if (reduced.next is Break) {
        // In case the break can now be inlined.
        reduced = visitStatement(reduced);
      }
      return reduced;
    }

    return node;
  }

  Expression visitConstant(Constant node) {
    return node;
  }

  Statement visitExpressionStatement(ExpressionStatement node) {
    node.expression = visitExpression(node.expression);
    if (!node.expression.isPure) {
      environment.add(null); // insert impurity marker (TODO: refactor)
    }
    node.next = visitStatement(node.next);
    if (!node.expression.isPure) {
      environment.removeLast();
    }
    return node;
  }


  /// If [s] and [t] are similar statements we extract their subexpressions
  /// and returns a new statement of the same type using expressions combined
  /// with the [combine] callback. For example:
  ///
  ///   combineStatements(Return E1, Return E2) = Return combine(E1, E2)
  ///
  /// If [combine] returns E1 then the unified statement is equivalent to [s],
  /// and if [combine] returns E2 the unified statement is equivalence to [t].
  ///
  /// It is guaranteed that no side effects occur between the beginning of the
  /// statement and the position of the combined expression.
  ///
  /// Returns null if the statements are too different.
  ///
  /// If non-null is returned, the caller MUST discard [s] and [t] and use
  /// the returned statement instead.
  static Statement combineStatementsWithSubexpressions(
      Statement s,
      Statement t,
      Expression combine(Expression s, Expression t)) {
    if (s is Return && t is Return) {
      return new Return(combine(s.value, t.value));
    }
    if (s is Assign && t is Assign && s.variable == t.variable) {
      Statement next = combineStatements(s.next, t.next);
      if (next != null) {
        return new Assign(s.variable,
                          combine(s.definition, t.definition),
                          next,
                          s.hasExactlyOneUse);
      }
    }
    if (s is ExpressionStatement && t is ExpressionStatement) {
      Statement next = combineStatements(s.next, t.next);
      if (next != null) {
        return new ExpressionStatement(combine(s.expression, t.expression),
                                       next);
      }
    }
    return null;
  }

  /// Returns a statement equivalent to both [s] and [t], or null if [s] and
  /// [t] are incompatible.
  /// If non-null is returned, the caller MUST discard [s] and [t] and use
  /// the returned statement instead.
  /// If two breaks are combined, the label's break counter will be decremented.
  static Statement combineStatements(Statement s, Statement t) {
    if (s is Break && t is Break && s.target == t.target) {
      --t.target.breakCount; // Two breaks become one.
      return s;
    }
    if (s is Return && t is Return && equivalentExpressions(s.value, t.value)) {
      return s;
    }
    return null;
  }

  /// True if the two expressions both syntactically and semantically
  /// equivalent.
  static bool equivalentExpressions(Expression e1, Expression e2) {
    if (e1 == e2) { // Detect same variable reference
      // TODO(asgerf): This might turn the variable into a single-use,
      // but we currently don't discover this.
      return true;
    }
    if (e1 is Constant && e2 is Constant) {
      return e1.value == e2.value;
    }
    return false;
  }
}

