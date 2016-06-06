// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library tree_ir_nodes;

import '../constants/values.dart' as values;
import '../dart_types.dart' show DartType, InterfaceType, TypeVariableType;
import '../elements/elements.dart';
import '../io/source_information.dart' show SourceInformation;
import '../types/types.dart' show TypeMask;
import '../universe/selector.dart' show Selector;

import '../cps_ir/builtin_operator.dart';
export '../cps_ir/builtin_operator.dart';
import '../cps_ir/cps_ir_nodes.dart' show TypeExpressionKind;
export '../cps_ir/cps_ir_nodes.dart' show TypeExpressionKind;

// These imports are only used for the JavaScript specific nodes.  If we want to
// support more than one native backend, we should probably create better
// abstractions for native code and its type and effect system.
import '../js/js.dart' as js show Template;
import '../native/native.dart' as native show NativeBehavior;
import '../types/types.dart' as types show TypeMask;

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
//
// Additionally, variables are considered in scope within inner functions;
// closure variables are thus handled directly instead of using ref cells.

/**
 * The base class of all Tree nodes.
 */
abstract class Node {
  /// Workaround for a slow Object.hashCode in the VM.
  static int _usedHashCodes = 0;
  final int hashCode = ++_usedHashCodes;
}

/**
 * The base class of [Expression]s.
 */
abstract class Expression extends Node {
  accept(ExpressionVisitor v);
  accept1(ExpressionVisitor1 v, arg);

  SourceInformation get sourceInformation => null;
}

abstract class Statement extends Node {
  Statement get next;
  void set next(Statement s);
  accept(StatementVisitor v);
  accept1(StatementVisitor1 v, arg);
}

/**
 * Labels name [LabeledStatement]s.
 */
class Label {
  /// Number of [Break] or [Continue] statements that target this label.
  /// The [Break] constructor will increment this automatically, but the
  /// counter must be decremented by hand when a [Break] becomes orphaned.
  int useCount = 0;

  /// The [LabeledStatement] or [WhileTrue] binding this label.
  JumpTarget binding;
}

/**
 * A local variable in the tree IR.
 *
 * All tree IR variables are mutable.
 *
 * To use a variable as an expression, reference it from a [VariableUse], with
 * one [VariableUse] per expression.
 *
 * [Variable]s are reference counted. The node constructors [VariableUse],
 * [Assign], [FunctionDefinition], and [Try] automatically update the reference
 * count for their variables, but when transforming the tree, the transformer
 * is responsible for updating reference counts.
 */
class Variable extends Node {
  /// Function that declares this variable.
  ExecutableElement host;

  /// [Entity] used for synthesizing a name for the variable.
  /// Different variables may have the same entity. May be null.
  Entity element;

  /// Number of places where this variable occurs in a [VariableUse].
  int readCount = 0;

  /// Number of places where this variable occurs as:
  /// - left-hand of an [Assign]
  /// - parameter in a [FunctionDefinition]
  /// - catch parameter in a [Try]
  int writeCount = 0;

  /// True if an inner JS function might access this variable through a
  /// [ForeignCode] node.
  bool isCaptured = false;

  Variable(this.host, this.element) {
    assert(host != null);
  }

  String toString() =>
      element == null ? 'Variable.${hashCode}' : element.toString();
}

/// Read the value of a variable.
class VariableUse extends Expression {
  Variable variable;
  SourceInformation sourceInformation;

  /// Creates a use of [variable] and updates its `readCount`.
  VariableUse(this.variable, {this.sourceInformation}) {
    variable.readCount++;
  }

  accept(ExpressionVisitor visitor) => visitor.visitVariableUse(this);
  accept1(ExpressionVisitor1 visitor, arg) {
    return visitor.visitVariableUse(this, arg);
  }
}

class Assign extends Expression {
  Variable variable;
  Expression value;
  SourceInformation sourceInformation;

  Assign(this.variable, this.value, {this.sourceInformation}) {
    variable.writeCount++;
  }

  accept(ExpressionVisitor v) => v.visitAssign(this);
  accept1(ExpressionVisitor1 v, arg) => v.visitAssign(this, arg);

  static ExpressionStatement makeStatement(Variable variable, Expression value,
      [Statement next]) {
    return new ExpressionStatement(new Assign(variable, value), next);
  }
}

/**
 * Common interface for invocations with arguments.
 */
abstract class Invoke {
  List<Expression> get arguments;
}

/**
 * A call to a static function or getter/setter to a static field.
 *
 * In contrast to the CPS-based IR, the arguments can be arbitrary expressions.
 */
class InvokeStatic extends Expression implements Invoke {
  final Entity target;
  final List<Expression> arguments;
  final Selector selector;
  final SourceInformation sourceInformation;

  InvokeStatic(this.target, this.selector, this.arguments,
      [this.sourceInformation]);

  accept(ExpressionVisitor visitor) => visitor.visitInvokeStatic(this);
  accept1(ExpressionVisitor1 visitor, arg) {
    return visitor.visitInvokeStatic(this, arg);
  }
}

/**
 * A call to a method, operator, getter, setter or index getter/setter.
 *
 * If [receiver] is `null`, an error is thrown before the arguments are
 * evaluated. This corresponds to the JS evaluation order.
 */
class InvokeMethod extends Expression implements Invoke {
  Expression receiver;
  final Selector selector;
  final TypeMask mask;
  final List<Expression> arguments;
  final SourceInformation sourceInformation;

  /// If true, it is known that the receiver cannot be `null`.
  bool receiverIsNotNull = false;

  InvokeMethod(this.receiver, this.selector, this.mask, this.arguments,
      this.sourceInformation) {
    assert(receiver != null);
  }

  accept(ExpressionVisitor visitor) => visitor.visitInvokeMethod(this);
  accept1(ExpressionVisitor1 visitor, arg) {
    return visitor.visitInvokeMethod(this, arg);
  }
}

/// Invoke [target] on [receiver], bypassing ordinary dispatch semantics.
///
/// Since the [receiver] is not used for method lookup, it may be `null`
/// without an error being thrown.
class InvokeMethodDirectly extends Expression implements Invoke {
  Expression receiver;
  final Element target;
  final Selector selector;
  final List<Expression> arguments;
  final SourceInformation sourceInformation;

  InvokeMethodDirectly(this.receiver, this.target, this.selector,
      this.arguments, this.sourceInformation);

  bool get isTearOff => selector.isGetter && !target.isGetter;

  accept(ExpressionVisitor visitor) => visitor.visitInvokeMethodDirectly(this);
  accept1(ExpressionVisitor1 visitor, arg) {
    return visitor.visitInvokeMethodDirectly(this, arg);
  }
}

/**
 * Call to a factory or generative constructor.
 */
class InvokeConstructor extends Expression implements Invoke {
  final DartType type;
  final FunctionElement target;
  final List<Expression> arguments;
  final Selector selector;
  final SourceInformation sourceInformation;

  /// TODO(karlklose): get rid of this field.  Instead use the constant's
  /// expression to find the constructor to be called in dart2dart.
  final values.ConstantValue constant;

  InvokeConstructor(this.type, this.target, this.selector, this.arguments,
      this.sourceInformation,
      [this.constant]);

  ClassElement get targetClass => target.enclosingElement;

  accept(ExpressionVisitor visitor) {
    return visitor.visitInvokeConstructor(this);
  }

  accept1(ExpressionVisitor1 visitor, arg) {
    return visitor.visitInvokeConstructor(this, arg);
  }
}

/// Call a method using a one-shot interceptor.
///
/// There is no explicit receiver, the first argument serves that purpose.
class OneShotInterceptor extends Expression implements Invoke {
  final Selector selector;
  final TypeMask mask;
  final List<Expression> arguments;
  final SourceInformation sourceInformation;

  OneShotInterceptor(
      this.selector, this.mask, this.arguments, this.sourceInformation);

  accept(ExpressionVisitor visitor) => visitor.visitOneShotInterceptor(this);
  accept1(ExpressionVisitor1 visitor, arg) {
    return visitor.visitOneShotInterceptor(this, arg);
  }
}

/**
 * A constant.
 */
class Constant extends Expression {
  final values.ConstantValue value;
  final SourceInformation sourceInformation;

  Constant(this.value, {this.sourceInformation});

  Constant.bool(values.BoolConstantValue constantValue)
      : value = constantValue,
        sourceInformation = null;

  accept(ExpressionVisitor visitor) => visitor.visitConstant(this);
  accept1(ExpressionVisitor1 visitor, arg) => visitor.visitConstant(this, arg);

  String toString() => 'Constant(value=${value.toStructuredText()})';
}

class This extends Expression {
  accept(ExpressionVisitor visitor) => visitor.visitThis(this);
  accept1(ExpressionVisitor1 visitor, arg) => visitor.visitThis(this, arg);
}

class LiteralList extends Expression {
  final InterfaceType type;
  final List<Expression> values;

  LiteralList(this.type, this.values);

  accept(ExpressionVisitor visitor) => visitor.visitLiteralList(this);
  accept1(ExpressionVisitor1 visitor, arg) {
    return visitor.visitLiteralList(this, arg);
  }
}

/// Type test or type cast.
///
/// Note that if this is a type test, then [type] cannot be `Object`, `dynamic`,
/// or the `Null` type. These cases are compiled to other node types.
class TypeOperator extends Expression {
  Expression value;
  final DartType type;
  final List<Expression> typeArguments;
  final bool isTypeTest;

  TypeOperator(this.value, this.type, this.typeArguments,
      {bool this.isTypeTest});

  accept(ExpressionVisitor visitor) => visitor.visitTypeOperator(this);
  accept1(ExpressionVisitor1 visitor, arg) {
    return visitor.visitTypeOperator(this, arg);
  }

  String get operator => isTypeTest ? 'is' : 'as';
}

/**
 * Apply a built-in operator.
 *
 * It must be known that the arguments have the proper types.
 * Null is not a valid argument to any of the built-in operators.
 */
class ApplyBuiltinOperator extends Expression {
  BuiltinOperator operator;
  List<Expression> arguments;
  SourceInformation sourceInformation;

  ApplyBuiltinOperator(this.operator, this.arguments, this.sourceInformation);

  accept(ExpressionVisitor visitor) {
    return visitor.visitApplyBuiltinOperator(this);
  }

  accept1(ExpressionVisitor1 visitor, arg) {
    return visitor.visitApplyBuiltinOperator(this, arg);
  }
}

class ApplyBuiltinMethod extends Expression {
  BuiltinMethod method;
  Expression receiver;
  List<Expression> arguments;

  bool receiverIsNotNull;

  ApplyBuiltinMethod(this.method, this.receiver, this.arguments,
      {this.receiverIsNotNull: false});

  accept(ExpressionVisitor visitor) {
    return visitor.visitApplyBuiltinMethod(this);
  }

  accept1(ExpressionVisitor1 visitor, arg) {
    return visitor.visitApplyBuiltinMethod(this, arg);
  }
}

/// A conditional expression.
class Conditional extends Expression {
  Expression condition;
  Expression thenExpression;
  Expression elseExpression;

  Conditional(this.condition, this.thenExpression, this.elseExpression);

  accept(ExpressionVisitor visitor) => visitor.visitConditional(this);
  accept1(ExpressionVisitor1 visitor, arg) {
    return visitor.visitConditional(this, arg);
  }

  String toString() => 'Conditional(condition=$condition,thenExpression='
      '$thenExpression,elseExpression=$elseExpression)';
}

/// An && or || expression. The operator is internally represented as a boolean
/// [isAnd] to simplify rewriting of logical operators.
/// Note the result of && and || is one of the arguments, which might not be
/// boolean. 'ShortCircuitOperator' might have been a better name.
class LogicalOperator extends Expression {
  Expression left;
  bool isAnd;
  Expression right;

  LogicalOperator(this.left, this.right, this.isAnd);
  LogicalOperator.and(this.left, this.right) : isAnd = true;
  LogicalOperator.or(this.left, this.right) : isAnd = false;

  String get operator => isAnd ? '&&' : '||';

  accept(ExpressionVisitor visitor) => visitor.visitLogicalOperator(this);
  accept1(ExpressionVisitor1 visitor, arg) {
    return visitor.visitLogicalOperator(this, arg);
  }

  String toString() => 'LogicalOperator(left=$left,right=$right,isAnd=$isAnd)';
}

/// Logical negation.
// TODO(asgerf): Replace this class with the IsFalsy builtin operator?
//               Right now the tree builder compiles IsFalsy to Not.
class Not extends Expression {
  Expression operand;

  Not(this.operand);

  accept(ExpressionVisitor visitor) => visitor.visitNot(this);
  accept1(ExpressionVisitor1 visitor, arg) => visitor.visitNot(this, arg);
}

/// A [LabeledStatement] or [WhileTrue] or [For].
abstract class JumpTarget extends Statement {
  Label get label;
  Statement get body;
}

/**
 * A labeled statement.  Breaks to the label within the labeled statement
 * target the successor statement.
 */
class LabeledStatement extends JumpTarget {
  Statement next;
  final Label label;
  Statement body;

  LabeledStatement(this.label, this.body, this.next) {
    assert(label.binding == null);
    label.binding = this;
  }

  accept(StatementVisitor visitor) => visitor.visitLabeledStatement(this);
  accept1(StatementVisitor1 visitor, arg) {
    return visitor.visitLabeledStatement(this, arg);
  }
}

/// A [WhileTrue] or [For] loop.
abstract class Loop extends JumpTarget {}

/**
 * A labeled while(true) loop.
 */
class WhileTrue extends Loop {
  final Label label;
  Statement body;

  WhileTrue(this.label, this.body) {
    assert(label.binding == null);
    label.binding = this;
  }

  Statement get next => null;
  void set next(Statement s) => throw 'UNREACHABLE';

  accept(StatementVisitor visitor) => visitor.visitWhileTrue(this);
  accept1(StatementVisitor1 visitor, arg) => visitor.visitWhileTrue(this, arg);
}

/**
 * A loop with a condition and update expressions. If there are any update
 * expressions, this generates a for loop, otherwise a while loop.
 *
 * When the condition is false, control resumes at the [next] statement.
 *
 * It is NOT valid to target this statement with a [Break].
 * The only way to reach [next] is for the condition to evaluate to false.
 *
 * [For] statements are introduced in the [LoopRewriter] and are
 * assumed not to occur before then.
 */
class For extends Loop {
  final Label label;
  Expression condition;
  List<Expression> updates;
  Statement body;
  Statement next;

  For(this.label, this.condition, this.updates, this.body, this.next) {
    assert(label.binding == null);
    label.binding = this;
  }

  accept(StatementVisitor visitor) => visitor.visitFor(this);
  accept1(StatementVisitor1 visitor, arg) {
    return visitor.visitFor(this, arg);
  }
}

/// A [Break] or [Continue] statement.
abstract class Jump extends Statement {
  Label get target;
}

/**
 * A break from an enclosing [LabeledStatement].  The break targets the
 * labeled statement's successor statement.
 */
class Break extends Jump {
  final Label target;

  Statement get next => null;
  void set next(Statement s) => throw 'UNREACHABLE';

  Break(this.target) {
    ++target.useCount;
  }

  accept(StatementVisitor visitor) => visitor.visitBreak(this);
  accept1(StatementVisitor1 visitor, arg) => visitor.visitBreak(this, arg);
}

/**
 * A continue to an enclosing [WhileTrue] or [For] loop.
 * The continue targets the loop's body.
 */
class Continue extends Jump {
  final Label target;

  Statement get next => null;
  void set next(Statement s) => throw 'UNREACHABLE';

  Continue(this.target) {
    ++target.useCount;
  }

  accept(StatementVisitor visitor) => visitor.visitContinue(this);
  accept1(StatementVisitor1 visitor, arg) => visitor.visitContinue(this, arg);
}

/**
 * A return exit from the function.
 *
 * In contrast to the CPS-based IR, the return value is an arbitrary
 * expression.
 */
class Return extends Statement {
  /// Should not be null. Use [Constant] with [NullConstantValue] for void
  /// returns.
  /// Even in constructors this holds true. Take special care when translating
  /// back to dart, where `return null;` in a constructor is an error.
  Expression value;
  SourceInformation sourceInformation;

  Statement get next => null;
  void set next(Statement s) => throw 'UNREACHABLE';

  Return(this.value, {this.sourceInformation});

  accept(StatementVisitor visitor) => visitor.visitReturn(this);
  accept1(StatementVisitor1 visitor, arg) => visitor.visitReturn(this, arg);
}

/// A throw statement.
///
/// In the Tree IR, throw is a statement (like JavaScript and unlike Dart).
/// It does not have a successor statement.
class Throw extends Statement {
  Expression value;

  Statement get next => null;
  void set next(Statement s) => throw 'UNREACHABLE';

  Throw(this.value);

  accept(StatementVisitor visitor) => visitor.visitThrow(this);
  accept1(StatementVisitor1 visitor, arg) => visitor.visitThrow(this, arg);
}

/**
 * A conditional branch based on the true value of an [Expression].
 */
class If extends Statement {
  Expression condition;
  Statement thenStatement;
  Statement elseStatement;
  SourceInformation sourceInformation;

  Statement get next => null;
  void set next(Statement s) => throw 'UNREACHABLE';

  If(this.condition, this.thenStatement, this.elseStatement,
      this.sourceInformation);

  accept(StatementVisitor visitor) => visitor.visitIf(this);
  accept1(StatementVisitor1 visitor, arg) => visitor.visitIf(this, arg);
}

class ExpressionStatement extends Statement {
  Statement next;
  Expression expression;

  ExpressionStatement(this.expression, this.next);

  accept(StatementVisitor visitor) => visitor.visitExpressionStatement(this);
  accept1(StatementVisitor1 visitor, arg) {
    return visitor.visitExpressionStatement(this, arg);
  }
}

class Try extends Statement {
  Statement tryBody;
  List<Variable> catchParameters;
  Statement catchBody;

  Statement get next => null;
  void set next(Statement s) => throw 'UNREACHABLE';

  Try(this.tryBody, this.catchParameters, this.catchBody) {
    for (Variable variable in catchParameters) {
      variable.writeCount++; // Being a catch parameter counts as a write.
    }
  }

  accept(StatementVisitor visitor) => visitor.visitTry(this);
  accept1(StatementVisitor1 visitor, arg) {
    return visitor.visitTry(this, arg);
  }
}

/// A statement that is known to be unreachable.
class Unreachable extends Statement {
  Statement get next => null;
  void set next(Statement value) => throw 'UNREACHABLE';

  accept(StatementVisitor visitor) => visitor.visitUnreachable(this);
  accept1(StatementVisitor1 visitor, arg) {
    return visitor.visitUnreachable(this, arg);
  }
}

class FunctionDefinition extends Node {
  final ExecutableElement element;
  final List<Variable> parameters;
  final SourceInformation sourceInformation;
  Statement body;

  /// Creates a function definition and updates `writeCount` for [parameters].
  FunctionDefinition(this.element, this.parameters, this.body,
      {this.sourceInformation}) {
    for (Variable param in parameters) {
      param.writeCount++; // Being a parameter counts as a write.
    }
  }
}

class CreateBox extends Expression {
  accept(ExpressionVisitor visitor) => visitor.visitCreateBox(this);
  accept1(ExpressionVisitor1 visitor, arg) => visitor.visitCreateBox(this, arg);
}

class CreateInstance extends Expression {
  ClassElement classElement;
  List<Expression> arguments;
  Expression typeInformation;
  SourceInformation sourceInformation;

  CreateInstance(this.classElement, this.arguments, this.typeInformation,
      this.sourceInformation);

  accept(ExpressionVisitor visitor) => visitor.visitCreateInstance(this);
  accept1(ExpressionVisitor1 visitor, arg) {
    return visitor.visitCreateInstance(this, arg);
  }
}

class GetField extends Expression {
  Expression object;
  Element field;
  bool objectIsNotNull;
  SourceInformation sourceInformation;

  GetField(this.object, this.field, this.sourceInformation,
      {this.objectIsNotNull: false});

  accept(ExpressionVisitor visitor) => visitor.visitGetField(this);
  accept1(ExpressionVisitor1 visitor, arg) => visitor.visitGetField(this, arg);
}

class SetField extends Expression {
  Expression object;
  Element field;
  Expression value;
  SourceInformation sourceInformation;

  /// If non-null, this is a compound assignment to the field, using the given
  /// operator.  The operator must be a compoundable operator.
  BuiltinOperator compound;

  SetField(this.object, this.field, this.value, this.sourceInformation,
      {this.compound});

  accept(ExpressionVisitor visitor) => visitor.visitSetField(this);
  accept1(ExpressionVisitor1 visitor, arg) => visitor.visitSetField(this, arg);
}

/// Read the type test property from [object]. The value is truthy/fasly rather
/// than bool. [object] must not be `null`.
class GetTypeTestProperty extends Expression {
  Expression object;
  DartType dartType;

  GetTypeTestProperty(this.object, this.dartType);

  accept(ExpressionVisitor visitor) => visitor.visitGetTypeTestProperty(this);
  accept1(ExpressionVisitor1 visitor, arg) =>
      visitor.visitGetTypeTestProperty(this, arg);
}

/// Read the value of a field, possibly provoking its initializer to evaluate,
/// or tear off a static method.
class GetStatic extends Expression {
  Element element;
  SourceInformation sourceInformation;
  bool useLazyGetter = false;

  GetStatic(this.element, this.sourceInformation);

  GetStatic.lazy(this.element, this.sourceInformation) : useLazyGetter = true;

  accept(ExpressionVisitor visitor) => visitor.visitGetStatic(this);
  accept1(ExpressionVisitor1 visitor, arg) => visitor.visitGetStatic(this, arg);
}

class SetStatic extends Expression {
  Element element;
  Expression value;
  SourceInformation sourceInformation;
  BuiltinOperator compound;

  SetStatic(this.element, this.value, this.sourceInformation, {this.compound});

  accept(ExpressionVisitor visitor) => visitor.visitSetStatic(this);
  accept1(ExpressionVisitor1 visitor, arg) => visitor.visitSetStatic(this, arg);
}

class GetLength extends Expression {
  Expression object;

  GetLength(this.object);

  accept(ExpressionVisitor v) => v.visitGetLength(this);
  accept1(ExpressionVisitor1 v, arg) => v.visitGetLength(this, arg);
}

class GetIndex extends Expression {
  Expression object;
  Expression index;

  GetIndex(this.object, this.index);

  accept(ExpressionVisitor v) => v.visitGetIndex(this);
  accept1(ExpressionVisitor1 v, arg) => v.visitGetIndex(this, arg);
}

class SetIndex extends Expression {
  Expression object;
  Expression index;
  Expression value;
  BuiltinOperator compound;

  SetIndex(this.object, this.index, this.value, {this.compound});

  accept(ExpressionVisitor v) => v.visitSetIndex(this);
  accept1(ExpressionVisitor1 v, arg) => v.visitSetIndex(this, arg);
}

class ReifyRuntimeType extends Expression {
  Expression value;
  SourceInformation sourceInformation;

  ReifyRuntimeType(this.value, this.sourceInformation);

  accept(ExpressionVisitor visitor) {
    return visitor.visitReifyRuntimeType(this);
  }

  accept1(ExpressionVisitor1 visitor, arg) {
    return visitor.visitReifyRuntimeType(this, arg);
  }
}

class ReadTypeVariable extends Expression {
  final TypeVariableType variable;
  Expression target;
  final SourceInformation sourceInformation;

  ReadTypeVariable(this.variable, this.target, this.sourceInformation);

  accept(ExpressionVisitor visitor) {
    return visitor.visitReadTypeVariable(this);
  }

  accept1(ExpressionVisitor1 visitor, arg) {
    return visitor.visitReadTypeVariable(this, arg);
  }
}

class CreateInvocationMirror extends Expression {
  final Selector selector;
  final List<Expression> arguments;

  CreateInvocationMirror(this.selector, this.arguments);

  accept(ExpressionVisitor visitor) {
    return visitor.visitCreateInvocationMirror(this);
  }

  accept1(ExpressionVisitor1 visitor, arg) {
    return visitor.visitCreateInvocationMirror(this, arg);
  }
}

class Interceptor extends Expression {
  Expression input;
  Set<ClassElement> interceptedClasses;
  final SourceInformation sourceInformation;

  Interceptor(this.input, this.interceptedClasses, this.sourceInformation);

  accept(ExpressionVisitor visitor) {
    return visitor.visitInterceptor(this);
  }

  accept1(ExpressionVisitor1 visitor, arg) {
    return visitor.visitInterceptor(this, arg);
  }
}

class ForeignCode extends Node {
  final js.Template codeTemplate;
  final types.TypeMask type;
  final List<Expression> arguments;
  final native.NativeBehavior nativeBehavior;
  final List<bool> nullableArguments; // One 'bit' per argument.
  final Element dependency;
  final SourceInformation sourceInformation;

  ForeignCode(this.codeTemplate, this.type, this.arguments, this.nativeBehavior,
      this.nullableArguments, this.dependency, this.sourceInformation) {
    assert(arguments.length == nullableArguments.length);
  }
}

class ForeignExpression extends ForeignCode implements Expression {
  ForeignExpression(
      js.Template codeTemplate,
      types.TypeMask type,
      List<Expression> arguments,
      native.NativeBehavior nativeBehavior,
      List<bool> nullableArguments,
      Element dependency,
      SourceInformation sourceInformation)
      : super(codeTemplate, type, arguments, nativeBehavior, nullableArguments,
            dependency, sourceInformation);

  accept(ExpressionVisitor visitor) {
    return visitor.visitForeignExpression(this);
  }

  accept1(ExpressionVisitor1 visitor, arg) {
    return visitor.visitForeignExpression(this, arg);
  }
}

class ForeignStatement extends ForeignCode implements Statement {
  ForeignStatement(
      js.Template codeTemplate,
      types.TypeMask type,
      List<Expression> arguments,
      native.NativeBehavior nativeBehavior,
      List<bool> nullableArguments,
      Element dependency,
      SourceInformation sourceInformation)
      : super(codeTemplate, type, arguments, nativeBehavior, nullableArguments,
            dependency, sourceInformation);

  accept(StatementVisitor visitor) {
    return visitor.visitForeignStatement(this);
  }

  accept1(StatementVisitor1 visitor, arg) {
    return visitor.visitForeignStatement(this, arg);
  }

  @override
  Statement get next => null;

  @override
  void set next(Statement s) => throw 'UNREACHABLE';
}

/// Denotes the internal representation of [dartType], where all type variables
/// are replaced by the values in [arguments].
/// (See documentation on the TypeExpression CPS node for more details.)
class TypeExpression extends Expression {
  final TypeExpressionKind kind;
  final DartType dartType;
  final List<Expression> arguments;

  TypeExpression(this.kind, this.dartType, this.arguments);

  accept(ExpressionVisitor visitor) {
    return visitor.visitTypeExpression(this);
  }

  accept1(ExpressionVisitor1 visitor, arg) {
    return visitor.visitTypeExpression(this, arg);
  }
}

class Await extends Expression {
  Expression input;

  Await(this.input);

  accept(ExpressionVisitor visitor) {
    return visitor.visitAwait(this);
  }

  accept1(ExpressionVisitor1 visitor, arg) {
    return visitor.visitAwait(this, arg);
  }
}

class Yield extends Statement {
  Statement next;
  Expression input;
  final bool hasStar;

  Yield(this.input, this.hasStar, this.next);

  accept(StatementVisitor visitor) {
    return visitor.visitYield(this);
  }

  accept1(StatementVisitor1 visitor, arg) {
    return visitor.visitYield(this, arg);
  }
}

class ReceiverCheck extends Statement {
  Expression condition;
  Expression value;
  Selector selector;
  bool useSelector;
  bool useInvoke;
  Statement next;
  SourceInformation sourceInformation;

  ReceiverCheck(
      {this.condition,
      this.value,
      this.selector,
      this.useSelector,
      this.useInvoke,
      this.next,
      this.sourceInformation});

  accept(StatementVisitor visitor) {
    return visitor.visitReceiverCheck(this);
  }

  accept1(StatementVisitor1 visitor, arg) {
    return visitor.visitReceiverCheck(this, arg);
  }
}

abstract class ExpressionVisitor<E> {
  E visitExpression(Expression node) => node.accept(this);
  E visitVariableUse(VariableUse node);
  E visitAssign(Assign node);
  E visitInvokeStatic(InvokeStatic node);
  E visitInvokeMethod(InvokeMethod node);
  E visitInvokeMethodDirectly(InvokeMethodDirectly node);
  E visitInvokeConstructor(InvokeConstructor node);
  E visitOneShotInterceptor(OneShotInterceptor node);
  E visitConstant(Constant node);
  E visitThis(This node);
  E visitConditional(Conditional node);
  E visitLogicalOperator(LogicalOperator node);
  E visitNot(Not node);
  E visitLiteralList(LiteralList node);
  E visitTypeOperator(TypeOperator node);
  E visitGetField(GetField node);
  E visitSetField(SetField node);
  E visitGetStatic(GetStatic node);
  E visitSetStatic(SetStatic node);
  E visitGetTypeTestProperty(GetTypeTestProperty node);
  E visitCreateBox(CreateBox node);
  E visitCreateInstance(CreateInstance node);
  E visitReifyRuntimeType(ReifyRuntimeType node);
  E visitReadTypeVariable(ReadTypeVariable node);
  E visitTypeExpression(TypeExpression node);
  E visitCreateInvocationMirror(CreateInvocationMirror node);
  E visitInterceptor(Interceptor node);
  E visitApplyBuiltinOperator(ApplyBuiltinOperator node);
  E visitApplyBuiltinMethod(ApplyBuiltinMethod node);
  E visitForeignExpression(ForeignExpression node);
  E visitGetLength(GetLength node);
  E visitGetIndex(GetIndex node);
  E visitSetIndex(SetIndex node);
  E visitAwait(Await node);
}

abstract class ExpressionVisitor1<E, A> {
  E visitExpression(Expression node, A arg) => node.accept1(this, arg);
  E visitVariableUse(VariableUse node, A arg);
  E visitAssign(Assign node, A arg);
  E visitInvokeStatic(InvokeStatic node, A arg);
  E visitInvokeMethod(InvokeMethod node, A arg);
  E visitInvokeMethodDirectly(InvokeMethodDirectly node, A arg);
  E visitInvokeConstructor(InvokeConstructor node, A arg);
  E visitOneShotInterceptor(OneShotInterceptor node, A arg);
  E visitConstant(Constant node, A arg);
  E visitThis(This node, A arg);
  E visitConditional(Conditional node, A arg);
  E visitLogicalOperator(LogicalOperator node, A arg);
  E visitNot(Not node, A arg);
  E visitLiteralList(LiteralList node, A arg);
  E visitTypeOperator(TypeOperator node, A arg);
  E visitGetField(GetField node, A arg);
  E visitSetField(SetField node, A arg);
  E visitGetStatic(GetStatic node, A arg);
  E visitSetStatic(SetStatic node, A arg);
  E visitGetTypeTestProperty(GetTypeTestProperty node, A arg);
  E visitCreateBox(CreateBox node, A arg);
  E visitCreateInstance(CreateInstance node, A arg);
  E visitReifyRuntimeType(ReifyRuntimeType node, A arg);
  E visitReadTypeVariable(ReadTypeVariable node, A arg);
  E visitTypeExpression(TypeExpression node, A arg);
  E visitCreateInvocationMirror(CreateInvocationMirror node, A arg);
  E visitInterceptor(Interceptor node, A arg);
  E visitApplyBuiltinOperator(ApplyBuiltinOperator node, A arg);
  E visitApplyBuiltinMethod(ApplyBuiltinMethod node, A arg);
  E visitForeignExpression(ForeignExpression node, A arg);
  E visitGetLength(GetLength node, A arg);
  E visitGetIndex(GetIndex node, A arg);
  E visitSetIndex(SetIndex node, A arg);
  E visitAwait(Await node, A arg);
}

abstract class StatementVisitor<S> {
  S visitStatement(Statement node) => node.accept(this);
  S visitLabeledStatement(LabeledStatement node);
  S visitReturn(Return node);
  S visitThrow(Throw node);
  S visitBreak(Break node);
  S visitContinue(Continue node);
  S visitIf(If node);
  S visitWhileTrue(WhileTrue node);
  S visitFor(For node);
  S visitExpressionStatement(ExpressionStatement node);
  S visitTry(Try node);
  S visitUnreachable(Unreachable node);
  S visitForeignStatement(ForeignStatement node);
  S visitYield(Yield node);
  S visitReceiverCheck(ReceiverCheck node);
}

abstract class StatementVisitor1<S, A> {
  S visitStatement(Statement node, A arg) => node.accept1(this, arg);
  S visitLabeledStatement(LabeledStatement node, A arg);
  S visitReturn(Return node, A arg);
  S visitThrow(Throw node, A arg);
  S visitBreak(Break node, A arg);
  S visitContinue(Continue node, A arg);
  S visitIf(If node, A arg);
  S visitWhileTrue(WhileTrue node, A arg);
  S visitFor(For node, A arg);
  S visitExpressionStatement(ExpressionStatement node, A arg);
  S visitTry(Try node, A arg);
  S visitUnreachable(Unreachable node, A arg);
  S visitForeignStatement(ForeignStatement node, A arg);
  S visitYield(Yield node, A arg);
  S visitReceiverCheck(ReceiverCheck node, A arg);
}

abstract class RecursiveVisitor implements StatementVisitor, ExpressionVisitor {
  visitExpression(Expression e) => e.accept(this);
  visitStatement(Statement s) => s.accept(this);

  visitVariable(Variable variable) {}

  visitVariableUse(VariableUse node) {
    visitVariable(node.variable);
  }

  visitAssign(Assign node) {
    visitVariable(node.variable);
    visitExpression(node.value);
  }

  visitInvokeStatic(InvokeStatic node) {
    node.arguments.forEach(visitExpression);
  }

  visitInvokeMethod(InvokeMethod node) {
    visitExpression(node.receiver);
    node.arguments.forEach(visitExpression);
  }

  visitInvokeMethodDirectly(InvokeMethodDirectly node) {
    visitExpression(node.receiver);
    node.arguments.forEach(visitExpression);
  }

  visitInvokeConstructor(InvokeConstructor node) {
    node.arguments.forEach(visitExpression);
  }

  visitOneShotInterceptor(OneShotInterceptor node) {
    node.arguments.forEach(visitExpression);
  }

  visitConstant(Constant node) {}

  visitThis(This node) {}

  visitConditional(Conditional node) {
    visitExpression(node.condition);
    visitExpression(node.thenExpression);
    visitExpression(node.elseExpression);
  }

  visitLogicalOperator(LogicalOperator node) {
    visitExpression(node.left);
    visitExpression(node.right);
  }

  visitNot(Not node) {
    visitExpression(node.operand);
  }

  visitLiteralList(LiteralList node) {
    node.values.forEach(visitExpression);
  }

  visitTypeOperator(TypeOperator node) {
    visitExpression(node.value);
    node.typeArguments.forEach(visitExpression);
  }

  visitLabeledStatement(LabeledStatement node) {
    visitStatement(node.body);
    visitStatement(node.next);
  }

  visitReturn(Return node) {
    visitExpression(node.value);
  }

  visitThrow(Throw node) {
    visitExpression(node.value);
  }

  visitBreak(Break node) {}

  visitContinue(Continue node) {}

  visitIf(If node) {
    visitExpression(node.condition);
    visitStatement(node.thenStatement);
    visitStatement(node.elseStatement);
  }

  visitWhileTrue(WhileTrue node) {
    visitStatement(node.body);
  }

  visitFor(For node) {
    visitExpression(node.condition);
    node.updates.forEach(visitExpression);
    visitStatement(node.body);
    visitStatement(node.next);
  }

  visitExpressionStatement(ExpressionStatement inputNode) {
    // Iterate over chains of expression statements to avoid deep recursion.
    Statement node = inputNode;
    while (node is ExpressionStatement) {
      ExpressionStatement stmt = node;
      visitExpression(stmt.expression);
      node = stmt.next;
    }
    visitStatement(node);
  }

  visitTry(Try node) {
    visitStatement(node.tryBody);
    visitStatement(node.catchBody);
  }

  visitGetField(GetField node) {
    visitExpression(node.object);
  }

  visitSetField(SetField node) {
    visitExpression(node.object);
    visitExpression(node.value);
  }

  visitGetStatic(GetStatic node) {}

  visitSetStatic(SetStatic node) {
    visitExpression(node.value);
  }

  visitGetTypeTestProperty(GetTypeTestProperty node) {
    visitExpression(node.object);
  }

  visitCreateBox(CreateBox node) {}

  visitCreateInstance(CreateInstance node) {
    node.arguments.forEach(visitExpression);
    if (node.typeInformation != null) visitExpression(node.typeInformation);
  }

  visitReifyRuntimeType(ReifyRuntimeType node) {
    visitExpression(node.value);
  }

  visitReadTypeVariable(ReadTypeVariable node) {
    visitExpression(node.target);
  }

  visitTypeExpression(TypeExpression node) {
    node.arguments.forEach(visitExpression);
  }

  visitCreateInvocationMirror(CreateInvocationMirror node) {
    node.arguments.forEach(visitExpression);
  }

  visitUnreachable(Unreachable node) {}

  visitApplyBuiltinOperator(ApplyBuiltinOperator node) {
    node.arguments.forEach(visitExpression);
  }

  visitApplyBuiltinMethod(ApplyBuiltinMethod node) {
    visitExpression(node.receiver);
    node.arguments.forEach(visitExpression);
  }

  visitInterceptor(Interceptor node) {
    visitExpression(node.input);
  }

  visitForeignCode(ForeignCode node) {
    node.arguments.forEach(visitExpression);
  }

  visitForeignExpression(ForeignExpression node) => visitForeignCode(node);
  visitForeignStatement(ForeignStatement node) => visitForeignCode(node);

  visitGetLength(GetLength node) {
    visitExpression(node.object);
  }

  visitGetIndex(GetIndex node) {
    visitExpression(node.object);
    visitExpression(node.index);
  }

  visitSetIndex(SetIndex node) {
    visitExpression(node.object);
    visitExpression(node.index);
    visitExpression(node.value);
  }

  visitAwait(Await node) {
    visitExpression(node.input);
  }

  visitYield(Yield node) {
    visitExpression(node.input);
    visitStatement(node.next);
  }

  visitReceiverCheck(ReceiverCheck node) {
    if (node.condition != null) visitExpression(node.condition);
    visitExpression(node.value);
    visitStatement(node.next);
  }
}

abstract class Transformer
    implements ExpressionVisitor<Expression>, StatementVisitor<Statement> {
  Expression visitExpression(Expression e) => e.accept(this);
  Statement visitStatement(Statement s) => s.accept(this);
}

class RecursiveTransformer extends Transformer {
  void _replaceExpressions(List<Expression> list) {
    for (int i = 0; i < list.length; i++) {
      list[i] = visitExpression(list[i]);
    }
  }

  visitVariableUse(VariableUse node) => node;

  visitAssign(Assign node) {
    node.value = visitExpression(node.value);
    return node;
  }

  visitInvokeStatic(InvokeStatic node) {
    _replaceExpressions(node.arguments);
    return node;
  }

  visitInvokeMethod(InvokeMethod node) {
    node.receiver = visitExpression(node.receiver);
    _replaceExpressions(node.arguments);
    return node;
  }

  visitInvokeMethodDirectly(InvokeMethodDirectly node) {
    node.receiver = visitExpression(node.receiver);
    _replaceExpressions(node.arguments);
    return node;
  }

  visitInvokeConstructor(InvokeConstructor node) {
    _replaceExpressions(node.arguments);
    return node;
  }

  visitOneShotInterceptor(OneShotInterceptor node) {
    _replaceExpressions(node.arguments);
    return node;
  }

  visitConstant(Constant node) => node;

  visitThis(This node) => node;

  visitConditional(Conditional node) {
    node.condition = visitExpression(node.condition);
    node.thenExpression = visitExpression(node.thenExpression);
    node.elseExpression = visitExpression(node.elseExpression);
    return node;
  }

  visitLogicalOperator(LogicalOperator node) {
    node.left = visitExpression(node.left);
    node.right = visitExpression(node.right);
    return node;
  }

  visitNot(Not node) {
    node.operand = visitExpression(node.operand);
    return node;
  }

  visitLiteralList(LiteralList node) {
    _replaceExpressions(node.values);
    return node;
  }

  visitTypeOperator(TypeOperator node) {
    node.value = visitExpression(node.value);
    _replaceExpressions(node.typeArguments);
    return node;
  }

  visitLabeledStatement(LabeledStatement node) {
    node.body = visitStatement(node.body);
    node.next = visitStatement(node.next);
    return node;
  }

  visitReturn(Return node) {
    node.value = visitExpression(node.value);
    return node;
  }

  visitThrow(Throw node) {
    node.value = visitExpression(node.value);
    return node;
  }

  visitBreak(Break node) => node;

  visitContinue(Continue node) => node;

  visitIf(If node) {
    node.condition = visitExpression(node.condition);
    node.thenStatement = visitStatement(node.thenStatement);
    node.elseStatement = visitStatement(node.elseStatement);
    return node;
  }

  visitWhileTrue(WhileTrue node) {
    node.body = visitStatement(node.body);
    return node;
  }

  visitFor(For node) {
    node.condition = visitExpression(node.condition);
    _replaceExpressions(node.updates);
    node.body = visitStatement(node.body);
    node.next = visitStatement(node.next);
    return node;
  }

  visitExpressionStatement(ExpressionStatement node) {
    // Iterate over chains of expression statements to avoid deep recursion.
    Statement first = node;
    while (true) {
      node.expression = visitExpression(node.expression);
      if (node.next is ExpressionStatement) {
        node = node.next;
      } else {
        break;
      }
    }
    node.next = visitStatement(node.next);
    return first;
  }

  visitTry(Try node) {
    node.tryBody = visitStatement(node.tryBody);
    node.catchBody = visitStatement(node.catchBody);
    return node;
  }

  visitGetField(GetField node) {
    node.object = visitExpression(node.object);
    return node;
  }

  visitSetField(SetField node) {
    node.object = visitExpression(node.object);
    node.value = visitExpression(node.value);
    return node;
  }

  visitGetStatic(GetStatic node) => node;

  visitSetStatic(SetStatic node) {
    node.value = visitExpression(node.value);
    return node;
  }

  visitGetTypeTestProperty(GetTypeTestProperty node) {
    node.object = visitExpression(node.object);
    return node;
  }

  visitCreateBox(CreateBox node) => node;

  visitCreateInstance(CreateInstance node) {
    _replaceExpressions(node.arguments);
    if (node.typeInformation != null) {
      node.typeInformation = visitExpression(node.typeInformation);
    }
    return node;
  }

  visitReifyRuntimeType(ReifyRuntimeType node) {
    node.value = visitExpression(node.value);
    return node;
  }

  visitReadTypeVariable(ReadTypeVariable node) {
    node.target = visitExpression(node.target);
    return node;
  }

  visitTypeExpression(TypeExpression node) {
    _replaceExpressions(node.arguments);
    return node;
  }

  visitCreateInvocationMirror(CreateInvocationMirror node) {
    _replaceExpressions(node.arguments);
    return node;
  }

  visitForeignExpression(ForeignExpression node) {
    _replaceExpressions(node.arguments);
    return node;
  }

  visitForeignStatement(ForeignStatement node) {
    _replaceExpressions(node.arguments);
    return node;
  }

  visitUnreachable(Unreachable node) {
    return node;
  }

  visitApplyBuiltinOperator(ApplyBuiltinOperator node) {
    _replaceExpressions(node.arguments);
    return node;
  }

  visitApplyBuiltinMethod(ApplyBuiltinMethod node) {
    node.receiver = visitExpression(node.receiver);
    _replaceExpressions(node.arguments);
    return node;
  }

  visitInterceptor(Interceptor node) {
    node.input = visitExpression(node.input);
    return node;
  }

  visitGetLength(GetLength node) {
    node.object = visitExpression(node.object);
    return node;
  }

  visitGetIndex(GetIndex node) {
    node.object = visitExpression(node.object);
    node.index = visitExpression(node.index);
    return node;
  }

  visitSetIndex(SetIndex node) {
    node.object = visitExpression(node.object);
    node.index = visitExpression(node.index);
    node.value = visitExpression(node.value);
    return node;
  }

  visitAwait(Await node) {
    node.input = visitExpression(node.input);
    return node;
  }

  visitYield(Yield node) {
    node.input = visitExpression(node.input);
    node.next = visitStatement(node.next);
    return node;
  }

  visitReceiverCheck(ReceiverCheck node) {
    if (node.condition != null) {
      node.condition = visitExpression(node.condition);
    }
    node.value = visitExpression(node.value);
    node.next = visitStatement(node.next);
    return node;
  }
}

class FallthroughTarget {
  final Statement target;
  int useCount = 0;

  FallthroughTarget(this.target);
}

/// A stack machine for tracking fallthrough while traversing the Tree IR.
class FallthroughStack {
  final List<FallthroughTarget> _stack = <FallthroughTarget>[
    new FallthroughTarget(null)
  ];

  /// Set a new fallthrough target.
  void push(Statement newFallthrough) {
    _stack.add(new FallthroughTarget(newFallthrough));
  }

  /// Remove the current fallthrough target.
  void pop() {
    _stack.removeLast();
  }

  /// The current fallthrough target, or `null` if control will fall over
  /// the end of the method.
  Statement get target => _stack.last.target;

  /// Number of uses of the current fallthrough target.
  int get useCount => _stack.last.useCount;

  /// Indicate that a statement will fall through to the current fallthrough
  /// target.
  void use() {
    ++_stack.last.useCount;
  }
}
