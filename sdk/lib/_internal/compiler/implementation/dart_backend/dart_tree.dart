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
import '../dart_types.dart' show DartType, GenericType;
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
  accept(Visitor v);

  /// Temporary variable used by [StatementRewriter].
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

  accept(Visitor visitor) => visitor.visitInvokeConstructor(this);
}

/// Calls [toString] on each argument and concatenates the results.
class ConcatenateStrings extends Expression {
  final List<Expression> arguments;

  ConcatenateStrings(this.arguments);

  accept(Visitor visitor) => visitor.visitConcatenateStrings(this);
}

/**
 * A constant.
 */
class Constant extends Expression {
  dart2js.Constant value;

  Constant(this.value);

  accept(Visitor visitor) => visitor.visitConstant(this);
}

class LiteralList extends Expression {
  final List<Expression> values;

  LiteralList(this.values) ;

  accept(Visitor visitor) => visitor.visitLiteralList(this);
}

class LiteralMap extends Expression {
  final List<Expression> keys;
  final List<Expression> values;

  LiteralMap(this.keys, this.values) ;

  accept(Visitor visitor) => visitor.visitLiteralMap(this);
}

class InvokeConstConstructor extends Expression implements Invoke {
  final GenericType type;
  final FunctionElement target;
  final List<Expression> arguments;
  final Selector selector;

  ClassElement get targetClass => target.enclosingElement;

  InvokeConstConstructor(this.type, this.target, this.selector, this.arguments);

  accept(Visitor visitor) => visitor.visitInvokeConstConstructor(this);
}

/// A conditional expression.
class Conditional extends Expression {
  Expression condition;
  Expression thenExpression;
  Expression elseExpression;

  Conditional(this.condition, this.thenExpression, this.elseExpression);

  accept(Visitor visitor) => visitor.visitConditional(this);
}

/// An && or || expression. The operator is internally represented as a boolean
/// [isAnd] to simplify rewriting of logical operators.
class LogicalOperator extends Expression {
  Expression left;
  bool isAnd;
  Expression right;

  LogicalOperator(this.left, this.right, this.isAnd);
  LogicalOperator.and(this.left, this.right) : isAnd = true;
  LogicalOperator.or(this.left, this.right) : isAnd = false;

  String get operator => isAnd ? '&&' : '||';

  accept(Visitor visitor) => visitor.visitLogicalOperator(this);
}

/// Logical negation.
class Not extends Expression {
  Expression operand;

  Not(this.operand);

  accept(Visitor visitor) => visitor.visitNot(this);
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
 * A continue to an enclosing [While] loop.  The continue targets the
 * loop's body.
 */
class Continue extends Statement {
  Label target;

  Statement get next => null;
  void set next(Statement s) => throw 'UNREACHABLE';

  Continue(this.target);

  accept(Visitor visitor) => visitor.visitContinue(this);
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

/**
 * A labeled while(true) loop.
 */
class While extends Statement {
  final Label label;
  Statement body;

  While(this.label, this.body);

  Statement get next => null;
  void set next(Statement s) => throw 'UNREACHABLE';

  accept(Visitor visitor) => visitor.visitWhile(this);
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
  E visitLogicalOperator(LogicalOperator node);
  E visitNot(Not node);
  E visitLiteralList(LiteralList node);
  E visitLiteralMap(LiteralMap node);
  E visitInvokeConstConstructor(InvokeConstConstructor node);

  S visitStatement(Statement s) => s.accept(this);
  S visitLabeledStatement(LabeledStatement node);
  S visitAssign(Assign node);
  S visitReturn(Return node);
  S visitBreak(Break node);
  S visitContinue(Continue node);
  S visitIf(If node);
  S visitWhile(While node);
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
      return new Assign(variable, definition, visit(node.body),
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
    if (node.continuation.hasMultipleUses) {
      label = new Label();
      labels[node.continuation] = label;
    }
    node.continuation.parameters.forEach((p) {
        if (p.hasAtLeastOneUse) variables[p] = new Variable(null);
    });
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
                  : new While(labels[cont], visit(cont.body));
            } else {
              return cont.hasExactlyOneUse
                  ? visit(cont.body)
                  : new Break(labels[cont]);
            }
          });
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

  Expression visitInvokeConstConstructor(ir.InvokeConstConstructor node) {
    return new InvokeConstConstructor(node.type, node.constructor, node.selector,
        translateArguments(node.arguments));
  }

  Expression visitConstant(ir.Constant node) {
    return new Constant(node.value);
  }

  Expression visitLiteralList(ir.LiteralList node) {
    return new LiteralList(translateArguments(node.values));
  }

  Expression visitLiteralMap(ir.LiteralMap node) {
    return new LiteralMap(
        translateArguments(node.keys),
        translateArguments(node.values));
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
 * Performs the following transformations on the tree:
 * - Assignment propagation
 * - If-to-conditional conversion
 * - Flatten nested ifs
 * - Break inlining
 * - Redirect breaks
 *
 * The above transformations all eliminate statements from the tree, and may
 * introduce redexes of each other.
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
 * FLATTEN NESTED IFS:
 * An if inside an if is converted to an if with a logical operator.
 * For example:
 *
 *   if (E1) { if (E2) {S} else break L } else break L
 *     ==>
 *   if (E1 && E2) {S} else break L
 *
 * This may lead to inlining of L.
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
 *
 *
 * REDIRECT BREAKS:
 * Labeled statements whose next is a break become flattened and all breaks
 * to their label are redirected.
 * For example:
 *
 *   L0: {... break L0 ...}; break L1
 *     ==>
 *   {... break L1 ...}
 *
 * This may trigger a flattening of nested ifs in case the eliminated label
 * separated two ifs.
 */
class StatementRewriter extends Visitor<Statement, Expression> {
  // The binding environment.  The rightmost element of the list is the nearest
  // available enclosing binding.
  List<Assign> environment;

  /// Substitution map for labels. Any break to a label L should be substituted
  /// for a break to L' if L maps to L'.
  Map<Label, Label> labelRedirects = <Label, Label>{};

  /// Returns the redirect target of [label] or [label] itself if it should not
  /// be redirected.
  Label redirect(Label label) {
    Label newTarget = labelRedirects[label];
    return newTarget != null ? newTarget : label;
  }

  void rewrite(FunctionDefinition definition) {
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
    // 2.  It was the most recent expression evaluated so that we do not
    //     reorder expressions with side effects.
    if (!environment.isEmpty &&
        environment.last.variable == node &&
        environment.last.hasExactlyOneUse) {
      return visitExpression(environment.removeLast().definition);
    }
    // If the definition could not be propagated, leave the variable use.
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

  Expression visitInvokeConstConstructor(InvokeConstConstructor node) {
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

    List<Assign> savedEnvironment = environment;
    environment = <Assign>[];
    node.thenExpression = visitExpression(node.thenExpression);
    assert(environment.isEmpty);
    node.elseExpression = visitExpression(node.elseExpression);
    assert(environment.isEmpty);
    environment = savedEnvironment;

    return node;
  }

  Expression visitLogicalOperator(LogicalOperator node) {
    node.left = visitExpression(node.left);

    environment.add(null); // impure expressions may not propagate across branch
    node.right = visitExpression(node.right);
    environment.removeLast();

    return node;
  }

  Expression visitNot(Not node) {
    node.operand = visitExpression(node.operand);
    return node;
  }

  Statement visitReturn(Return node) {
    node.value = visitExpression(node.value);
    return node;
  }


  Statement visitBreak(Break node) {
    // Redirect through chain of breaks.
    // Note that breakCount was accounted for at visitLabeledStatement.
    node.target = redirect(node.target);
    if (node.target.breakCount == 1) {
      --node.target.breakCount;
      return visitStatement(node.target.binding.next);
    }
    return node;
  }

  Statement visitContinue(Continue node) {
    return node;
  }

  Statement visitLabeledStatement(LabeledStatement node) {
    if (node.next is Break) {
      // Eliminate label if next is just a break statement
      // Breaks to this label are redirected to the outer label.
      // Note that breakCount for the two labels is updated proactively here
      // so breaks can reliably tell if they should inline their target.
      Break next = node.next;
      Label newTarget = redirect(next.target);
      labelRedirects[node.label] = newTarget;
      newTarget.breakCount += node.label.breakCount;
      node.label.breakCount = 0;
      Statement result = visitStatement(node.body);
      labelRedirects.remove(node.label); // Save some space.
      return result;
    }

    node.body = visitStatement(node.body);

    if (node.label.breakCount == 0) {
      // Eliminate the label if next was inlined at a break
      return node.body;
    }

    node.next = visitStatement(node.next);
    return node;
  }

  Statement visitIf(If node) {
    node.condition = visitExpression(node.condition);

    // Do not propagate assignments into branches.  Doing so will lead to code
    // duplication.
    // TODO(kmillikin): Rethink this.  Propagating some assignments (e.g.,
    // constants or variables) is benign.  If they can occur here, they should
    // be handled well.
    List<Assign> savedEnvironment = environment;
    environment = <Assign>[];
    node.thenStatement = visitStatement(node.thenStatement);
    assert(environment.isEmpty);
    node.elseStatement = visitStatement(node.elseStatement);
    assert(environment.isEmpty);
    environment = savedEnvironment;

    tryCollapseIf(node);

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

  Statement visitWhile(While node) {
    // Do not propagate assignments into loops.  Doing so is not safe for
    // variables modified in the loop (the initial value will be propagated).
    List<Assign> savedEnvironment = environment;
    environment = <Assign>[];
    node.body = visitStatement(node.body);
    assert(environment.isEmpty);
    environment = savedEnvironment;
    return node;
  }

  Expression visitConstant(Constant node) {
    return node;
  }

  Expression visitLiteralList(LiteralList node) {
    // Process values right-to-left, the opposite of evaluation order.
    for (int i = node.values.length - 1; i >= 0; --i) {
      node.values[i] = visitExpression(node.values[i]);
    }
    return node;
  }

  Expression visitLiteralMap(LiteralMap node) {
    // Process arguments right-to-left, the opposite of evaluation order.
    for (int i = node.values.length - 1; i >= 0; --i) {
      node.values[i] = visitExpression(node.values[i]);
      node.keys[i] = visitExpression(node.keys[i]);
    }
    return node;
  }

  Statement visitExpressionStatement(ExpressionStatement node) {
    node.expression = visitExpression(node.expression);
    // Do not allow propagation of assignments past an expression evaluated
    // for its side effects because it risks reordering side effects.
    // TODO(kmillikin): Rethink this.  Some propagation is benign, e.g.,
    // constants, variables, or other pure values that are not destroyed by
    // the expression statement.  If they can occur here they should be
    // handled well.
    List<Assign> savedEnvironment = environment;
    environment = <Assign>[];
    node.next = visitStatement(node.next);
    assert(environment.isEmpty);
    environment = savedEnvironment;
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

  /// Try to collapse nested ifs using && and || expressions.
  /// For example:
  ///
  ///   if (E1) { if (E2) S else break L } else break L
  ///     ==>
  ///   if (E1 && E2) S else break L
  ///
  /// [branch1] and [branch2] control the position of the S statement.
  ///
  /// Returns true if another collapse redex might have been introduced.
  void tryCollapseIf(If node) {
    // Repeatedly try to collapse nested ifs.
    // The transformation is shrinking (destroys an if) so it remains linear.
    // Here is an example where more than one iteration is required:
    //
    //   if (E1)
    //     if (E2) break L2 else break L1
    //   else
    //     break L1
    //
    // L1.target ::=
    //   if (E3) S else break L2
    //
    // After first collapse:
    //
    //   if (E1 && E2)
    //     break L2
    //   else
    //     {if (E3) S else break L2}  (inlined from break L1)
    //
    // We can then do another collapse using the inlined nested if.
    bool changed = true;
    while (changed) {
      changed = false;
      if (tryCollapseIfAux(node, true, true)) {
        changed = true;
      }
      if (tryCollapseIfAux(node, true, false)) {
        changed = true;
      }
      if (tryCollapseIfAux(node, false, true)) {
        changed = true;
      }
      if (tryCollapseIfAux(node, false, false)) {
        changed = true;
      }
    }
  }

  bool tryCollapseIfAux(If outerIf, bool branch1, bool branch2) {
    // NOTE: We name variables here as if S is in the then-then position.
    Statement outerThen = getBranch(outerIf, branch1);
    Statement outerElse = getBranch(outerIf, !branch1);
    if (outerThen is If && outerElse is Break) {
      If innerIf = outerThen;
      Statement innerThen = getBranch(innerIf, branch2);
      Statement innerElse = getBranch(innerIf, !branch2);
      if (innerElse is Break && innerElse.target == outerElse.target) {
        // We always put S in the then branch of the result, and adjust the
        // condition expression if S was actually found in the else branch(es).
        outerIf.condition = new LogicalOperator.and(
            makeCondition(outerIf.condition, branch1),
            makeCondition(innerIf.condition, branch2));
        outerIf.thenStatement = innerThen;
        --innerElse.target.breakCount;

        // Try to inline the remaining break.  Do not propagate assignments.
        List<Assign> savedEnvironment = environment;
        environment = <Assign>[];
        outerIf.elseStatement = visitStatement(outerElse);
        assert(environment.isEmpty);
        environment = savedEnvironment;

        return outerIf.elseStatement is If && innerThen is Break;
      }
    }
    return false;
  }

  Expression makeCondition(Expression e, bool polarity) {
    return polarity ? e : new Not(e);
  }

  Statement getBranch(If node, bool polarity) {
    return polarity ? node.thenStatement : node.elseStatement;
  }
}



/// Rewrites logical expressions to be more compact.
///
/// In this class an expression is said to occur in "boolean context" if
/// its result is immediately applied to boolean conversion.
///
/// IF STATEMENTS:
///
/// We apply the following two rules to [If] statements (see [visitIf]).
///
///   if (E) {} else S  ==>  if (!E) S else {}    (else can be omitted)
///   if (!E) S1 else S2  ==>  if (E) S2 else S1  (unless previous rule applied)
///
/// NEGATION:
///
/// De Morgan's Laws are used to rewrite negations of logical operators so
/// negations are closer to the root:
///
///   !x && !y  -->  !(x || y)
///
/// This is to enable other rewrites, such as branch swapping in an if. In some
/// contexts, the rule is reversed because we do not expect to apply a rewrite
/// rule to the result. For example:
///
///   z = !(x || y)  ==>  z = !x && !y;
///
/// CONDITIONALS:
///
/// Conditionals with boolean constant operands occur frequently in the input.
/// They can often the re-written to logical operators, for instance:
///
///   if (x ? y : false) S1 else S2
///     ==>
///   if (x && y) S1 else S2
///
/// Conditionals are tricky to rewrite when they occur out of boolean context.
/// Here we must apply more conservative rules, such as:
///
///   x ? true : false  ==>  !!x
///
/// If an operand is known to be a boolean, we can introduce a logical operator:
///
///   x ? y : false  ==>  x && y   (if y is known to be a boolean)
///
/// The following sequence of rewrites demonstrates the merit of these rules:
///
///   x ? (y ? true : false) : false
///   x ? !!y : false   (double negation introduced by [toBoolean])
///   x && !!y          (!!y validated by [isBooleanValued])
///   x && y            (double negation removed by [putInBooleanContext])
///
class LogicalRewriter extends Visitor<Statement, Expression> {

  /// Statement to be executed next by natural fallthrough. Although fallthrough
  /// is not introduced in this phase, we need to reason about fallthrough when
  /// evaluating the benefit of swapping the branches of an [If].
  Statement fallthrough;

  void rewrite(FunctionDefinition definition) {
    definition.body = visitStatement(definition.body);
  }

  Statement visitLabeledStatement(LabeledStatement node) {
    Statement savedFallthrough = fallthrough;
    fallthrough = node.next;
    node.body = visitStatement(node.body);
    fallthrough = savedFallthrough;
    node.next = visitStatement(node.next);
    return node;
  }

  Statement visitAssign(Assign node) {
    node.definition = visitExpression(node.definition);
    node.next = visitStatement(node.next);
    return node;
  }

  Statement visitReturn(Return node) {
    node.value = visitExpression(node.value);
    return node;
  }

  Statement visitBreak(Break node) {
    return node;
  }

  Statement visitContinue(Continue node) {
    return node;
  }

  bool isFallthroughBreak(Statement node) {
    return node is Break && node.target.binding.next == fallthrough;
  }

  Statement visitIf(If node) {
    // If one of the branches is empty (i.e. just a fallthrough), then that
    // branch should preferrably be the 'else' so we won't have to print it.
    // In other words, we wish to perform this rewrite:
    //   if (E) {} else {S}
    //     ==>
    //   if (!E) {S}
    // In the tree language, empty statements do not exist yet, so we must check
    // if one branch contains a break that can be eliminated by fallthrough.

    // Swap branches if then is a fallthrough break.
    if (isFallthroughBreak(node.thenStatement)) {
      node.condition = new Not(node.condition);
      Statement tmp = node.thenStatement;
      node.thenStatement = node.elseStatement;
      node.elseStatement = tmp;
    }

    // Can the else part be eliminated?
    // (Either due to the above swap or if the break was already there).
    bool emptyElse = isFallthroughBreak(node.elseStatement);

    node.condition = makeCondition(node.condition, true, liftNots: !emptyElse);
    node.thenStatement = visitStatement(node.thenStatement);
    node.elseStatement = visitStatement(node.elseStatement);

    // If neither branch is empty, eliminate a negation in the condition
    // if (!E) S1 else S2
    //   ==>
    // if (E) S2 else S1
    if (!emptyElse && node.condition is Not) {
      node.condition = (node.condition as Not).operand;
      Statement tmp = node.thenStatement;
      node.thenStatement = node.elseStatement;
      node.elseStatement = tmp;
    }

    return node;
  }

  Statement visitWhile(While node) {
    node.body = visitStatement(node.body);
    return node;
  }

  Statement visitExpressionStatement(ExpressionStatement node) {
    // TODO(asgerf): in non-checked mode we can remove Not from the expression.
    node.expression = visitExpression(node.expression);
    node.next = visitStatement(node.next);
    return node;
  }


  Expression visitVariable(Variable node) {
    return node;
  }

  Expression visitInvokeStatic(InvokeStatic node) {
    _rewriteList(node.arguments);
    return node;
  }

  Expression visitInvokeMethod(InvokeMethod node) {
    node.receiver = visitExpression(node.receiver);
    _rewriteList(node.arguments);
    return node;
  }

  Expression visitInvokeConstructor(InvokeConstructor node) {
    _rewriteList(node.arguments);
    return node;
  }

  Expression visitConcatenateStrings(ConcatenateStrings node) {
    _rewriteList(node.arguments);
    return node;
  }

  Expression visitLiteralList(LiteralList node) {
    _rewriteList(node.values);
    return node;
  }

  Expression visitLiteralMap(LiteralMap node) {
    _rewriteList(node.keys);
    _rewriteList(node.values);
    return node;
  }

  Expression visitConstant(Constant node) {
    return node;
  }

  Expression visitNot(Not node) {
    return toBoolean(makeCondition(node.operand, false, liftNots: false));
  }

  Expression visitConditional(Conditional node) {
    // node.condition will be visited after the then and else parts, because its
    // polarity depends on what rewrite we use.
    node.thenExpression = visitExpression(node.thenExpression);
    node.elseExpression = visitExpression(node.elseExpression);

    // In the following, we must take care not to eliminate or introduce a
    // boolean conversion.

    // x ? true : false --> !!x
    if (isTrue(node.thenExpression) && isFalse(node.elseExpression)) {
      return toBoolean(makeCondition(node.condition, true, liftNots: false));
    }
    // x ? false : true --> !x
    if (isFalse(node.thenExpression) && isTrue(node.elseExpression)) {
      return toBoolean(makeCondition(node.condition, false, liftNots: false));
    }

    // x ? y : false ==> x && y  (if y is known to be a boolean)
    if (isBooleanValued(node.thenExpression) && isFalse(node.elseExpression)) {
      return new LogicalOperator.and(
          makeCondition(node.condition, true, liftNots:false),
          putInBooleanContext(node.thenExpression));
    }
    // x ? y : true ==> !x || y  (if y is known to be a boolean)
    if (isBooleanValued(node.thenExpression) && isTrue(node.elseExpression)) {
      return new LogicalOperator.or(
          makeCondition(node.condition, false, liftNots: false),
          putInBooleanContext(node.thenExpression));
    }
    // x ? true : y ==> x || y  (if y if known to be boolean)
    if (isBooleanValued(node.elseExpression) && isTrue(node.thenExpression)) {
      return new LogicalOperator.or(
          makeCondition(node.condition, true, liftNots: false),
          putInBooleanContext(node.elseExpression));
    }
    // x ? false : y ==> !x && y  (if y is known to be a boolean)
    if (isBooleanValued(node.elseExpression) && isFalse(node.thenExpression)) {
      return new LogicalOperator.and(
          makeCondition(node.condition, false, liftNots: false),
          putInBooleanContext(node.elseExpression));
    }

    node.condition = makeCondition(node.condition, true);

    // !x ? y : z ==> x ? z : y
    if (node.condition is Not) {
      node.condition = (node.condition as Not).operand;
      Expression tmp = node.thenExpression;
      node.thenExpression = node.elseExpression;
      node.elseExpression = tmp;
    }

    return node;
  }

  Expression visitInvokeConstConstructor(InvokeConstConstructor node) {
    _rewriteList(node.arguments);
    return node;
  }

  Expression visitLogicalOperator(LogicalOperator node) {
    node.left = makeCondition(node.left, true);
    node.right = makeCondition(node.right, true);
    return node;
  }

  /// True if the given expression is known to evaluate to a boolean.
  /// This will not recursively traverse [Conditional] expressions, but if
  /// applied to the result of [visitExpression] conditionals will have been
  /// rewritten anyway.
  bool isBooleanValued(Expression e) {
    return isTrue(e) || isFalse(e) || e is Not || e is LogicalOperator;
  }

  /// Rewrite an expression that was originally processed in a non-boolean
  /// context.
  Expression putInBooleanContext(Expression e) {
    if (e is Not && e.operand is Not) {
      return (e.operand as Not).operand;
    } else {
      return e;
    }
  }

  /// Forces a boolean conversion of the given expression.
  Expression toBoolean(Expression e) {
    if (isBooleanValued(e))
      return e;
    else
      return new Not(new Not(e));
  }

  /// Creates an equivalent boolean expression. The expression must occur in a
  /// context where its result is immediately subject to boolean conversion.
  /// If [polarity] if false, the negated condition will be created instead.
  /// If [liftNots] is true (default) then Not expressions will be lifted toward
  /// the root the condition so they can be eliminated by the caller.
  Expression makeCondition(Expression e, bool polarity, {bool liftNots:true}) {
    if (e is Not) {
      // !!E ==> E
      return makeCondition(e.operand, !polarity, liftNots: liftNots);
    }
    if (e is LogicalOperator) {
      // If polarity=false, then apply the rewrite !(x && y) ==> !x || !y
      e.left = makeCondition(e.left, polarity);
      e.right = makeCondition(e.right, polarity);
      if (!polarity) {
        e.isAnd = !e.isAnd;
      }
      // !x && !y ==> !(x || y)  (only if lifting nots)
      if (e.left is Not && e.right is Not && liftNots) {
        e.left = (e.left as Not).operand;
        e.right = (e.right as Not).operand;
        e.isAnd = !e.isAnd;
        return new Not(e);
      }
      return e;
    }
    if (e is Conditional) {
      // Handle polarity by: !(x ? y : z) ==> x ? !y : !z
      // Rewrite individual branches now. The condition will be rewritten
      // when we know what polarity to use (depends on which rewrite is used).
      e.thenExpression = makeCondition(e.thenExpression, polarity);
      e.elseExpression = makeCondition(e.elseExpression, polarity);

      // x ? true : false ==> x
      if (isTrue(e.thenExpression) && isFalse(e.elseExpression)) {
        return makeCondition(e.condition, true, liftNots: liftNots);
      }
      // x ? false : true ==> !x
      if (isFalse(e.thenExpression) && isTrue(e.elseExpression)) {
        return makeCondition(e.condition, false, liftNots: liftNots);
      }
      // x ? true : y  ==> x || y
      if (isTrue(e.thenExpression)) {
        return makeOr(makeCondition(e.condition, true),
                      e.elseExpression,
                      liftNots: liftNots);
      }
      // x ? false : y  ==> !x && y
      if (isFalse(e.thenExpression)) {
        return makeAnd(makeCondition(e.condition, false),
                       e.elseExpression,
                       liftNots: liftNots);
      }
      // x ? y : true  ==> !x || y
      if (isTrue(e.elseExpression)) {
        return makeOr(makeCondition(e.condition, false),
                      e.thenExpression,
                      liftNots: liftNots);
      }
      // x ? y : false  ==> x && y
      if (isFalse(e.elseExpression)) {
        return makeAnd(makeCondition(e.condition, true),
                       e.thenExpression,
                       liftNots: liftNots);
      }

      e.condition = makeCondition(e.condition, true);

      // !x ? y : z ==> x ? z : y
      if (e.condition is Not) {
        e.condition = (e.condition as Not).operand;
        Expression tmp = e.thenExpression;
        e.thenExpression = e.elseExpression;
        e.elseExpression = tmp;
      }
      // x ? !y : !z ==> !(x ? y : z)  (only if lifting nots)
      if (e.thenExpression is Not && e.elseExpression is Not && liftNots) {
        e.thenExpression = (e.thenExpression as Not).operand;
        e.elseExpression = (e.elseExpression as Not).operand;
        return new Not(e);
      }
      return e;
    }
    if (e is Constant && e.value is dart2js.BoolConstant) {
      // !true ==> false
      if (!polarity) {
        e.value = (e.value as dart2js.BoolConstant).negate();
      }
      return e;
    }
    e = visitExpression(e);
    return polarity ? e : new Not(e);
  }

  bool isTrue(Expression e) {
    return e is Constant && e.value is dart2js.TrueConstant;
  }

  bool isFalse(Expression e) {
    return e is Constant && e.value is dart2js.FalseConstant;
  }

  Expression makeAnd(Expression e1, Expression e2, {bool liftNots: true}) {
    if (e1 is Not && e2 is Not && liftNots) {
      return new Not(new LogicalOperator.or(e1.operand, e2.operand));
    } else {
      return new LogicalOperator.and(e1, e2);
    }
  }

  Expression makeOr(Expression e1, Expression e2, {bool liftNots: true}) {
    if (e1 is Not && e2 is Not && liftNots) {
      return new Not(new LogicalOperator.and(e1.operand, e2.operand));
    } else {
      return new LogicalOperator.or(e1, e2);
    }
  }

  /// Destructively updates each entry of [l] with the result of visiting it.
  void _rewriteList(List<Expression> l) {
    for (int i = 0; i < l.length; i++) {
      l[i] = visitExpression(l[i]);
    }
  }
}
