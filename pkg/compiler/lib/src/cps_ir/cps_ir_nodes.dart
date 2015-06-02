// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library dart2js.ir_nodes;

import '../constants/expressions.dart';
import '../constants/values.dart' as values show ConstantValue;
import '../dart_types.dart' show DartType, InterfaceType, TypeVariableType;
import '../elements/elements.dart';
import '../io/source_information.dart' show SourceInformation;
import '../universe/universe.dart' show Selector, SelectorKind;

abstract class Node {
  /// A pointer to the parent node. Is null until set by optimization passes.
  Node parent;

  accept(Visitor visitor);
}

/// Expressions can be evaluated, and may diverge, throw, and/or have
/// side-effects.
///
/// Evaluation continues by stepping into a sub-expression, invoking a
/// continuation, or throwing an exception.
///
/// Expressions do not a return value. Expressions that produce values should
/// invoke a [Continuation] with the result as argument. Alternatively, values
/// that can be obtained without side-effects, divergence, or throwing
/// exceptions can be built using a [LetPrim].
abstract class Expression extends Node {
  Expression plug(Expression expr) => throw 'impossible';
}

/// The base class of things that variables can refer to: primitives,
/// continuations, function and continuation parameters, etc.
abstract class Definition<T extends Definition<T>> extends Node {
  // The head of a linked-list of occurrences, in no particular order.
  Reference<T> firstRef;

  bool get hasAtMostOneUse  => firstRef == null || firstRef.next == null;
  bool get hasExactlyOneUse => firstRef != null && firstRef.next == null;
  bool get hasNoUses => firstRef == null;
  bool get hasAtLeastOneUse => firstRef != null;
  bool get hasMultipleUses  => !hasAtMostOneUse;

  void substituteFor(Definition<T> other) {
    if (other == this) return;
    if (other.hasNoUses) return;
    Reference<T> previous, current = other.firstRef;
    do {
      current.definition = this;
      previous = current;
      current = current.next;
    } while (current != null);
    previous.next = firstRef;
    if (firstRef != null) firstRef.previous = previous;
    firstRef = other.firstRef;
    other.firstRef = null;
  }
}

/// An expression that cannot throw or diverge and has no side-effects.
/// All primitives are named using the identity of the [Primitive] object.
///
/// Primitives may allocate objects; this is not considered side-effect here.
///
/// Although primitives may not mutate state, they may depend on state.
///
/// All primitives except [Parameter] must be bound by a [LetPrim].
abstract class Primitive extends Definition<Primitive> {
  /// The [VariableElement] or [ParameterElement] from which the primitive
  /// binding originated.
  Entity hint;

  /// Use the given element as a hint for naming this primitive.
  ///
  /// Has no effect if this primitive already has a non-null [element].
  void useElementAsHint(Entity hint) {
    if (this.hint == null) {
      this.hint = hint;
    }
  }
}

/// Operands to invocations and primitives are always variables.  They point to
/// their definition and are doubly-linked into a list of occurrences.
class Reference<T extends Definition<T>> {
  T definition;
  Reference<T> previous;
  Reference<T> next;

  /// A pointer to the parent node. Is null until set by optimization passes.
  Node parent;

  Reference(this.definition) {
    next = definition.firstRef;
    if (next != null) next.previous = this;
    definition.firstRef = this;
  }

  /// Unlinks this reference from the list of occurrences.
  void unlink() {
    if (previous == null) {
      assert(definition.firstRef == this);
      definition.firstRef = next;
    } else {
      previous.next = next;
    }
    if (next != null) next.previous = previous;
  }
}

/// Evaluates a primitive and binds it to variable: `let val x = V in E`.
///
/// The bound value is in scope in the body.
///
/// During one-pass construction a LetPrim with an empty body is used to
/// represent the one-hole context `let val x = V in []`.
class LetPrim extends Expression implements InteriorNode {
  final Primitive primitive;
  Expression body;

  LetPrim(this.primitive, [this.body = null]);

  Expression plug(Expression expr) {
    assert(body == null);
    return body = expr;
  }

  accept(Visitor visitor) => visitor.visitLetPrim(this);
}


/// Binding continuations.
///
/// let cont k0(v0 ...) = E0
///          k1(v1 ...) = E1
///          ...
///   in E
///
/// The bound continuations are in scope in the body and the continuation
/// parameters are in scope in the respective continuation bodies.
///
/// During one-pass construction a LetCont whose first continuation has an empty
/// body is used to represent the one-hole context
/// `let cont ... k(v) = [] ... in E`.
class LetCont extends Expression implements InteriorNode {
  List<Continuation> continuations;
  Expression body;

  LetCont(Continuation continuation, this.body)
      : continuations = <Continuation>[continuation];

  LetCont.many(this.continuations, this.body);

  Expression plug(Expression expr) {
    assert(continuations != null &&
           continuations.isNotEmpty &&
           continuations.first.body == null);
    return continuations.first.body = expr;
  }

  accept(Visitor visitor) => visitor.visitLetCont(this);
}

// Binding an exception handler.
//
// let handler h(v0, v1) = E0 in E1
//
// The handler is a two-argument (exception, stack trace) continuation which
// is implicitly the error continuation of all the code in its body E1.
// [LetHandler] differs from a [LetCont] binding in that it (1) has the
// runtime semantics of pushing/popping a handler from the dynamic exception
// handler stack and (2) it does not have any explicit invocations.
class LetHandler extends Expression implements InteriorNode {
  Continuation handler;
  Expression body;

  LetHandler(this.handler, this.body);

  accept(Visitor visitor) => visitor.visitLetHandler(this);
}

/// Binding mutable variables.
///
/// let mutable v = P in E
///
/// [MutableVariable]s can be seen as ref cells that are not first-class
/// values.  They are therefore not [Primitive]s and not bound by [LetPrim]
/// to prevent unrestricted use of references to them.  During one-pass
/// construction, a [LetMutable] with an empty body is use to represent the
/// one-hole context 'let mutable v = P in []'.
class LetMutable extends Expression implements InteriorNode {
  final MutableVariable variable;
  final Reference<Primitive> value;
  Expression body;

  LetMutable(this.variable, Primitive value)
      : this.value = new Reference<Primitive>(value);

  Expression plug(Expression expr) {
    return body = expr;
  }

  accept(Visitor visitor) => visitor.visitLetMutable(this);
}

abstract class Invoke {
  Selector get selector;
  List<Reference<Primitive>> get arguments;
}

/// Represents a node with a child node, which can be accessed through the
/// `body` member. A typical usage is when removing a node from the CPS graph:
///
///     Node child          = node.body;
///     InteriorNode parent = node.parent;
///
///     child.parent = parent;
///     parent.body  = child;
abstract class InteriorNode extends Node {
  Expression get body;
  void set body(Expression body);
}

/// Invoke a static function.
///
/// All optional arguments declared by [target] are passed in explicitly, and
/// occur at the end of [arguments] list, in normalized order.
///
/// Discussion:
/// All information in the [selector] is technically redundant; it will likely
/// be removed.
class InvokeStatic extends Expression implements Invoke {
  final FunctionElement target;
  final Selector selector;
  final List<Reference<Primitive>> arguments;
  final Reference<Continuation> continuation;
  final SourceInformation sourceInformation;

  InvokeStatic(this.target,
               this.selector,
               List<Primitive> args,
               Continuation cont,
               this.sourceInformation)
      : arguments = _referenceList(args),
        continuation = new Reference<Continuation>(cont);

  accept(Visitor visitor) => visitor.visitInvokeStatic(this);
}

/// Invoke a method on an object.
///
/// This includes getters, setters, operators, and index getter/setters.
///
/// Tearing off a method is treated like a getter invocation (getters and
/// tear-offs cannot be distinguished at compile-time).
///
/// The [selector] records the names of named arguments. The value of named
/// arguments occur at the end of the [arguments] list, in normalized order.
///
/// Discussion:
/// If the [selector] is a [TypedSelector], the type information contained
/// there is used by optimization passes. This is likely to change.
class InvokeMethod extends Expression implements Invoke {
  Reference<Primitive> receiver;
  Selector selector;
  final List<Reference<Primitive>> arguments;
  final Reference<Continuation> continuation;
  final SourceInformation sourceInformation;

  /// If true, it is known that the receiver cannot be `null`.
  ///
  /// This field is `null` until initialized by optimization phases.
  bool receiverIsNotNull;

  InvokeMethod(Primitive receiver,
               this.selector,
               List<Primitive> arguments,
               Continuation continuation,
               {this.sourceInformation})
      : this.receiver = new Reference<Primitive>(receiver),
        this.arguments = _referenceList(arguments),
        this.continuation = new Reference<Continuation>(continuation);

  accept(Visitor visitor) => visitor.visitInvokeMethod(this);
}

/// Invoke [target] on [receiver], bypassing dispatch and override semantics.
///
/// That is, if [receiver] is an instance of a class that overrides [target]
/// with a different implementation, the overriding implementation is bypassed
/// and [target]'s implementation is invoked.
///
/// As with [InvokeMethod], this can be used to invoke a method, operator,
/// getter, setter, or index getter/setter.
///
/// If it is known that [target] does not use its receiver argument, then
/// [receiver] may refer to a null constant primitive. This happens for direct
/// invocations to intercepted methods, where the effective receiver is instead
/// passed as a formal parameter.
///
/// TODO(sra): Review. A direct call to a method that is mixed into a native
/// class will still require an explicit argument.
///
/// All optional arguments declared by [target] are passed in explicitly, and
/// occur at the end of [arguments] list, in normalized order.
class InvokeMethodDirectly extends Expression implements Invoke {
  Reference<Primitive> receiver;
  final FunctionElement target;
  final Selector selector;
  final List<Reference<Primitive>> arguments;
  final Reference<Continuation> continuation;

  InvokeMethodDirectly(Primitive receiver,
                       this.target,
                       this.selector,
                       List<Primitive> arguments,
                       Continuation continuation)
      : this.receiver = new Reference<Primitive>(receiver),
        this.arguments = _referenceList(arguments),
        this.continuation = new Reference<Continuation>(continuation);

  accept(Visitor visitor) => visitor.visitInvokeMethodDirectly(this);
}

/// Non-const call to a constructor.
///
/// The [target] may be a generative constructor (forwarding or normal)
/// or a non-redirecting factory.
///
/// All optional arguments declared by [target] are passed in explicitly, and
/// occur in the [arguments] list, in normalized order.
///
/// Last in the [arguments] list, after the mandatory and optional arguments,
/// the internal representation of each type argument occurs, unless it could
/// be determined at build-time that the constructed class has no need for its
/// runtime type information.
///
/// Note that [InvokeConstructor] does it itself allocate an object.
/// The invoked constructor will do that using [CreateInstance].
class InvokeConstructor extends Expression implements Invoke {
  final DartType type;
  final ConstructorElement target;
  final List<Reference<Primitive>> arguments;
  final Reference<Continuation> continuation;
  final Selector selector;

  InvokeConstructor(this.type,
                    this.target,
                    this.selector,
                    List<Primitive> args,
                    Continuation cont)
      : arguments = _referenceList(args),
        continuation = new Reference<Continuation>(cont);

  accept(Visitor visitor) => visitor.visitInvokeConstructor(this);
}

// TODO(asgerf): Make a Primitive for "is" and an Expression for "as".

/// An "as" cast or an "is" check.
class TypeOperator extends Expression {
  Reference<Primitive> value;
  final DartType type;

  /// If [type] is an [InterfaceType], this holds the internal representation of
  /// the type arguments to [type]. Since these may reference type variables
  /// from the enclosing class, they are not constant.
  ///
  /// If [type] is a [TypeVariableType], this is a singleton list with
  /// the internal representation of the type held in that type variable.
  ///
  /// Otherwise the list is empty.
  final List<Reference<Primitive>> typeArguments;
  final Reference<Continuation> continuation;
  final bool isTypeTest;

  TypeOperator(Primitive value,
               this.type,
               List<Primitive> typeArguments,
               Continuation cont,
               {bool this.isTypeTest})
      : this.value = new Reference<Primitive>(value),
        this.typeArguments = _referenceList(typeArguments),
        this.continuation = new Reference<Continuation>(cont) {
    assert(isTypeTest != null);
  }

  bool get isTypeCast => !isTypeTest;

  accept(Visitor visitor) => visitor.visitTypeOperator(this);
}

/// Invoke [toString] on each argument and concatenate the results.
class ConcatenateStrings extends Expression {
  final List<Reference<Primitive>> arguments;
  final Reference<Continuation> continuation;

  ConcatenateStrings(List<Primitive> args, Continuation cont)
      : arguments = _referenceList(args),
        continuation = new Reference<Continuation>(cont);

  accept(Visitor visitor) => visitor.visitConcatenateStrings(this);
}

/// Throw a value.
///
/// Throw is an expression, i.e., it always occurs in tail position with
/// respect to a body or expression.
class Throw extends Expression {
  Reference<Primitive> value;

  Throw(Primitive value) : value = new Reference<Primitive>(value);

  accept(Visitor visitor) => visitor.visitThrow(this);
}

/// Rethrow
///
/// Rethrow can only occur inside a continuation bound by [LetHandler].  It
/// implicitly throws the exception parameter of the enclosing handler with
/// the same stack trace as the enclosing handler.
class Rethrow extends Expression {
  accept(Visitor visitor) => visitor.visitRethrow(this);
}

/// A throw occurring in non-tail position.
///
/// The CPS translation of an expression produces a primitive as the value
/// of the expression.  For convenience in the implementation of the
/// translation, a [NonTailThrow] is used as that value.  A cleanup pass
/// removes these and replaces them with [Throw] expressions.
class NonTailThrow extends Primitive {
  final Reference<Primitive> value;

  NonTailThrow(Primitive value) : value = new Reference<Primitive>(value);

  accept(Visitor visitor) => visitor.visitNonTailThrow(this);
}

/// Gets the value from a [MutableVariable].
///
/// [MutableVariable]s can be seen as ref cells that are not first-class
/// values.  A [LetPrim] with a [GetMutableVariable] can then be seen as:
///
///   let prim p = ![variable] in [body]
///
class GetMutableVariable extends Primitive {
  final Reference<MutableVariable> variable;

  GetMutableVariable(MutableVariable variable)
      : this.variable = new Reference<MutableVariable>(variable);

  accept(Visitor visitor) => visitor.visitGetMutableVariable(this);
}

/// Assign a [MutableVariable].
///
/// [MutableVariable]s can be seen as ref cells that are not first-class
/// values.  This can be seen as a dereferencing assignment:
///
///   { [variable] := [value]; [body] }
class SetMutableVariable extends Expression implements InteriorNode {
  final Reference<MutableVariable> variable;
  final Reference<Primitive> value;
  Expression body;

  SetMutableVariable(MutableVariable variable, Primitive value)
      : this.variable = new Reference<MutableVariable>(variable),
        this.value = new Reference<Primitive>(value);

  accept(Visitor visitor) => visitor.visitSetMutableVariable(this);

  Expression plug(Expression expr) {
    assert(body == null);
    return body = expr;
  }
}

/// Invoke a continuation in tail position.
class InvokeContinuation extends Expression {
  Reference<Continuation> continuation;
  List<Reference<Primitive>> arguments;

  // An invocation of a continuation is recursive if it occurs in the body of
  // the continuation itself.
  bool isRecursive;

  InvokeContinuation(Continuation cont, List<Primitive> args,
                     {this.isRecursive: false})
      : continuation = new Reference<Continuation>(cont),
        arguments = _referenceList(args) {
    assert(cont.parameters == null || cont.parameters.length == args.length);
    if (isRecursive) cont.isRecursive = true;
  }

  /// A continuation invocation whose target and arguments will be filled
  /// in later.
  ///
  /// Used as a placeholder for a jump whose target is not yet created
  /// (e.g., in the translation of break and continue).
  InvokeContinuation.uninitialized({this.isRecursive: false})
      : continuation = null,
        arguments = null;

  accept(Visitor visitor) => visitor.visitInvokeContinuation(this);
}

/// The base class of things which can be tested and branched on.
abstract class Condition extends Node {
}

class IsTrue extends Condition {
  final Reference<Primitive> value;

  IsTrue(Primitive val) : value = new Reference<Primitive>(val);

  accept(Visitor visitor) => visitor.visitIsTrue(this);
}

/// Choose between a pair of continuations based on a condition value.
///
/// The two continuations must not declare any parameters.
class Branch extends Expression {
  final Condition condition;
  final Reference<Continuation> trueContinuation;
  final Reference<Continuation> falseContinuation;

  Branch(this.condition, Continuation trueCont, Continuation falseCont)
      : trueContinuation = new Reference<Continuation>(trueCont),
        falseContinuation = new Reference<Continuation>(falseCont);

  accept(Visitor visitor) => visitor.visitBranch(this);
}

/// Directly assigns to a field on a given object.
class SetField extends Expression implements InteriorNode {
  final Reference<Primitive> object;
  FieldElement field;
  final Reference<Primitive> value;
  Expression body;

  SetField(Primitive object, this.field, Primitive value)
      : this.object = new Reference<Primitive>(object),
        this.value = new Reference<Primitive>(value);

  Expression plug(Expression expr) {
    assert(body == null);
    return body = expr;
  }

  accept(Visitor visitor) => visitor.visitSetField(this);
}

/// Directly reads from a field on a given object.
class GetField extends Primitive {
  final Reference<Primitive> object;
  FieldElement field;

  GetField(Primitive object, this.field)
      : this.object = new Reference<Primitive>(object);

  accept(Visitor visitor) => visitor.visitGetField(this);
}

/// Reads the value of a static field or tears off a static method.
class GetStatic extends Primitive {
  /// Can be [FieldElement] or [FunctionElement].
  final Element element;
  final SourceInformation sourceInformation;

  GetStatic(this.element, this.sourceInformation);

  accept(Visitor visitor) => visitor.visitGetStatic(this);
}

/// Sets the value of a static field.
class SetStatic extends Expression implements InteriorNode {
  final FieldElement element;
  final Reference<Primitive> value;
  Expression body;
  final SourceInformation sourceInformation;

  SetStatic(this.element, Primitive value, this.sourceInformation)
      : this.value = new Reference<Primitive>(value);

  Expression plug(Expression expr) {
    assert(body == null);
    return body = expr;
  }

  accept(Visitor visitor) => visitor.visitSetStatic(this);
}

/// Reads the value of a lazily initialized static field.
///
/// If the field has not yet been initialized, its initializer is evaluated
/// and assigned to the field.
///
/// [continuation] is then invoked with the value of the field as argument.
class GetLazyStatic extends Expression {
  final FieldElement element;
  final Reference<Continuation> continuation;
  final SourceInformation sourceInformation;

  GetLazyStatic(this.element,
                Continuation continuation,
                this.sourceInformation)
      : continuation = new Reference<Continuation>(continuation);

  accept(Visitor visitor) => visitor.visitGetLazyStatic(this);
}

/// Creates an object for holding boxed variables captured by a closure.
class CreateBox extends Primitive {
  accept(Visitor visitor) => visitor.visitCreateBox(this);
}

/// Creates an instance of a class and initializes its fields and runtime type
/// information.
class CreateInstance extends Primitive {
  final ClassElement classElement;

  /// Initial values for the fields on the class.
  /// The order corresponds to the order of fields on the class.
  final List<Reference<Primitive>> arguments;

  /// The runtime type information structure which contains the type arguments.
  ///
  /// May be `null` to indicate that no type information is needed because the
  /// compiler determined that the type information for instances of this class
  /// is not needed at runtime.
  final List<Reference<Primitive>> typeInformation;

  CreateInstance(this.classElement, List<Primitive> arguments,
      List<Primitive> typeInformation)
      : this.arguments = _referenceList(arguments),
        this.typeInformation = _referenceList(typeInformation);

  accept(Visitor visitor) => visitor.visitCreateInstance(this);
}

/// Compare objects for identity.
///
/// It is an error pass in a value that does not correspond to a Dart value,
/// such as an interceptor or a box.
class Identical extends Primitive {
  final Reference<Primitive> left;
  final Reference<Primitive> right;
  Identical(Primitive left, Primitive right)
      : left = new Reference<Primitive>(left),
        right = new Reference<Primitive>(right);
  accept(Visitor visitor) => visitor.visitIdentical(this);
}

class Interceptor extends Primitive {
  final Reference<Primitive> input;
  final Set<ClassElement> interceptedClasses;
  Interceptor(Primitive input, this.interceptedClasses)
      : this.input = new Reference<Primitive>(input);
  accept(Visitor visitor) => visitor.visitInterceptor(this);
}

/// Create an instance of [Invocation] for use in a call to `noSuchMethod`.
class CreateInvocationMirror extends Primitive {
  final Selector selector;
  final List<Reference<Primitive>> arguments;

  CreateInvocationMirror(this.selector, List<Primitive> arguments)
      : this.arguments = _referenceList(arguments);

  accept(Visitor visitor) => visitor.visitCreateInvocationMirror(this);
}

class Constant extends Primitive {
  final ConstantExpression expression;
  final values.ConstantValue value;

  Constant(this.expression, this.value);

  accept(Visitor visitor) => visitor.visitConstant(this);
}

class LiteralList extends Primitive {
  /// The List type being created; this is not the type argument.
  final InterfaceType type;
  final List<Reference<Primitive>> values;

  LiteralList(this.type, List<Primitive> values)
      : this.values = _referenceList(values);

  accept(Visitor visitor) => visitor.visitLiteralList(this);
}

class LiteralMapEntry {
  final Reference<Primitive> key;
  final Reference<Primitive> value;

  LiteralMapEntry(Primitive key, Primitive value)
      : this.key = new Reference<Primitive>(key),
        this.value = new Reference<Primitive>(value);
}

class LiteralMap extends Primitive {
  final InterfaceType type;
  final List<LiteralMapEntry> entries;

  LiteralMap(this.type, this.entries);

  accept(Visitor visitor) => visitor.visitLiteralMap(this);
}

/// Currently unused.
///
/// Nested functions (from Dart code) are translated to classes by closure
/// conversion, hence they are instantiated with [CreateInstance].
///
/// We keep this around for now because it might come in handy when we
/// handle async/await in the CPS IR.
///
/// Instantiates a nested function. [MutableVariable]s are in scope in the
/// inner function, but primitives are not shared across function boundaries.
class CreateFunction extends Primitive {
  final FunctionDefinition definition;

  CreateFunction(this.definition);

  accept(Visitor visitor) => visitor.visitCreateFunction(this);
}

class Parameter extends Primitive {
  Parameter(Entity hint) {
    super.hint = hint;
  }

  // In addition to a parent pointer to the containing Continuation or
  // FunctionDefinition, parameters have an index into the list of parameters
  // bound by the parent.  This gives constant-time access to the continuation
  // from the parent.
  int parentIndex;

  accept(Visitor visitor) => visitor.visitParameter(this);

  String toString() => 'Parameter(${hint == null ? null : hint.name})';
}

/// Continuations are normally bound by 'let cont'.  A continuation with one
/// parameter and no body is used to represent a function's return continuation.
/// The return continuation is bound by the function, not by 'let cont'.
class Continuation extends Definition<Continuation> implements InteriorNode {
  final List<Parameter> parameters;
  Expression body = null;

  // In addition to a parent pointer to the containing LetCont, continuations
  // have an index into the list of continuations bound by the LetCont.  This
  // gives constant-time access to the continuation from the parent.
  int parent_index;

  // A continuation is recursive if it has any recursive invocations.
  bool isRecursive;

  bool get isReturnContinuation => body == null;

  Continuation(this.parameters, {this.isRecursive: false});

  Continuation.retrn() : parameters = <Parameter>[new Parameter(null)];

  accept(Visitor visitor) => visitor.visitContinuation(this);
}

/// Identifies a mutable variable.
class MutableVariable extends Definition {
  Entity hint;

  MutableVariable(this.hint);

  accept(Visitor v) => v.visitMutableVariable(this);
}

/// A function definition, consisting of parameters and a body.
///
/// There is an explicit parameter for the `this` argument, and a return
/// continuation to invoke when returning from the function.
class FunctionDefinition extends InteriorNode {
  final ExecutableElement element;
  final Parameter thisParameter;
  final List<Parameter> parameters;
  final Continuation returnContinuation;
  Expression body;

  FunctionDefinition(this.element,
      this.thisParameter,
      this.parameters,
      this.returnContinuation,
      this.body);

  accept(Visitor visitor) => visitor.visitFunctionDefinition(this);
}

/// Converts the internal representation of a type to a Dart object of type
/// [Type].
class ReifyRuntimeType extends Primitive {
  /// Reference to the internal representation of a type (as produced, for
  /// example, by [ReadTypeVariable]).
  final Reference<Primitive> value;
  ReifyRuntimeType(Primitive value)
    : this.value = new Reference<Primitive>(value);

  @override
  accept(Visitor visitor) => visitor.visitReifyRuntimeType(this);
}

/// Read the value the type variable [variable] from the target object.
///
/// The resulting value is an internal representation (and not neccessarily a
/// Dart object), and must be reified by [ReifyRuntimeType], if it should be
/// used as a Dart value.
class ReadTypeVariable extends Primitive {
  final TypeVariableType variable;
  final Reference<Primitive> target;

  ReadTypeVariable(this.variable, Primitive target)
      : this.target = new Reference<Primitive>(target);

  @override
  accept(Visitor visitor) => visitor.visitReadTypeVariable(this);
}

/// Representation of a closed type (that is, a type without type variables).
///
/// The resulting value is constructed from [dartType] by replacing the type
/// variables with consecutive values from [arguments], in the order generated
/// by [DartType.forEachTypeVariable].  The type variables in [dartType] are
/// treated as 'holes' in the term, which means that it must be ensured at
/// construction, that duplicate occurences of a type variable in [dartType]
/// are assigned the same value.
class TypeExpression extends Primitive {
  final DartType dartType;
  final List<Reference<Primitive>> arguments;

  TypeExpression(this.dartType,
                 [List<Primitive> arguments = const <Primitive>[]])
      : this.arguments = _referenceList(arguments);

  @override
  accept(Visitor visitor) {
    return visitor.visitTypeExpression(this);
  }
}

List<Reference<Primitive>> _referenceList(Iterable<Primitive> definitions) {
  return definitions.map((e) => new Reference<Primitive>(e)).toList();
}

abstract class Visitor<T> {
  const Visitor();

  T visit(Node node);

  // Concrete classes.
  T visitFunctionDefinition(FunctionDefinition node);

  // Expressions.
  T visitLetPrim(LetPrim node);
  T visitLetCont(LetCont node);
  T visitLetHandler(LetHandler node);
  T visitLetMutable(LetMutable node);
  T visitInvokeContinuation(InvokeContinuation node);
  T visitInvokeStatic(InvokeStatic node);
  T visitInvokeMethod(InvokeMethod node);
  T visitInvokeMethodDirectly(InvokeMethodDirectly node);
  T visitInvokeConstructor(InvokeConstructor node);
  T visitConcatenateStrings(ConcatenateStrings node);
  T visitThrow(Throw node);
  T visitRethrow(Rethrow node);
  T visitBranch(Branch node);
  T visitTypeOperator(TypeOperator node);
  T visitSetMutableVariable(SetMutableVariable node);
  T visitSetStatic(SetStatic node);
  T visitGetLazyStatic(GetLazyStatic node);
  T visitSetField(SetField node);

  // Definitions.
  T visitLiteralList(LiteralList node);
  T visitLiteralMap(LiteralMap node);
  T visitConstant(Constant node);
  T visitCreateFunction(CreateFunction node);
  T visitGetMutableVariable(GetMutableVariable node);
  T visitParameter(Parameter node);
  T visitContinuation(Continuation node);
  T visitMutableVariable(MutableVariable node);
  T visitNonTailThrow(NonTailThrow node);
  T visitGetStatic(GetStatic node);
  T visitIdentical(Identical node);
  T visitInterceptor(Interceptor node);
  T visitCreateInstance(CreateInstance node);
  T visitGetField(GetField node);
  T visitCreateBox(CreateBox node);
  T visitReifyRuntimeType(ReifyRuntimeType node);
  T visitReadTypeVariable(ReadTypeVariable node);
  T visitTypeExpression(TypeExpression node);
  T visitCreateInvocationMirror(CreateInvocationMirror node);

  // Conditions.
  T visitIsTrue(IsTrue node);
}

/// Recursively visits the entire CPS term, and calls abstract `process*`
/// (i.e. `processLetPrim`) functions in pre-order.
class RecursiveVisitor implements Visitor {
  const RecursiveVisitor();

  visit(Node node) => node.accept(this);

  processReference(Reference ref) {}

  processFunctionDefinition(FunctionDefinition node) {}
  visitFunctionDefinition(FunctionDefinition node) {
    processFunctionDefinition(node);
    if (node.thisParameter != null) visit(node.thisParameter);
    node.parameters.forEach(visit);
    visit(node.returnContinuation);
    visit(node.body);
  }

  // Expressions.

  processLetPrim(LetPrim node) {}
  visitLetPrim(LetPrim node) {
    processLetPrim(node);
    visit(node.primitive);
    visit(node.body);
  }

  processLetCont(LetCont node) {}
  visitLetCont(LetCont node) {
    processLetCont(node);
    node.continuations.forEach(visit);
    visit(node.body);
  }

  processLetHandler(LetHandler node) {}
  visitLetHandler(LetHandler node) {
    processLetHandler(node);
    visit(node.handler);
    visit(node.body);
  }

  processLetMutable(LetMutable node) {}
  visitLetMutable(LetMutable node) {
    processLetMutable(node);
    visit(node.variable);
    processReference(node.value);
    visit(node.body);
  }

  processInvokeStatic(InvokeStatic node) {}
  visitInvokeStatic(InvokeStatic node) {
    processInvokeStatic(node);
    processReference(node.continuation);
    node.arguments.forEach(processReference);
  }

  processInvokeContinuation(InvokeContinuation node) {}
  visitInvokeContinuation(InvokeContinuation node) {
    processInvokeContinuation(node);
    processReference(node.continuation);
    node.arguments.forEach(processReference);
  }

  processInvokeMethod(InvokeMethod node) {}
  visitInvokeMethod(InvokeMethod node) {
    processInvokeMethod(node);
    processReference(node.receiver);
    processReference(node.continuation);
    node.arguments.forEach(processReference);
  }

  processInvokeMethodDirectly(InvokeMethodDirectly node) {}
  visitInvokeMethodDirectly(InvokeMethodDirectly node) {
    processInvokeMethodDirectly(node);
    processReference(node.receiver);
    processReference(node.continuation);
    node.arguments.forEach(processReference);
  }

  processInvokeConstructor(InvokeConstructor node) {}
  visitInvokeConstructor(InvokeConstructor node) {
    processInvokeConstructor(node);
    processReference(node.continuation);
    node.arguments.forEach(processReference);
  }

  processConcatenateStrings(ConcatenateStrings node) {}
  visitConcatenateStrings(ConcatenateStrings node) {
    processConcatenateStrings(node);
    processReference(node.continuation);
    node.arguments.forEach(processReference);
  }

  processThrow(Throw node) {}
  visitThrow(Throw node) {
    processThrow(node);
    processReference(node.value);
  }

  processRethrow(Rethrow node) {}
  visitRethrow(Rethrow node) {
    processRethrow(node);
  }

  processBranch(Branch node) {}
  visitBranch(Branch node) {
    processBranch(node);
    processReference(node.trueContinuation);
    processReference(node.falseContinuation);
    visit(node.condition);
  }

  processTypeOperator(TypeOperator node) {}
  visitTypeOperator(TypeOperator node) {
    processTypeOperator(node);
    processReference(node.continuation);
    processReference(node.value);
    node.typeArguments.forEach(processReference);
  }

  processSetMutableVariable(SetMutableVariable node) {}
  visitSetMutableVariable(SetMutableVariable node) {
    processSetMutableVariable(node);
    processReference(node.variable);
    processReference(node.value);
    visit(node.body);
  }

  processGetLazyStatic(GetLazyStatic node) {}
  visitGetLazyStatic(GetLazyStatic node) {
    processGetLazyStatic(node);
    processReference(node.continuation);
  }

  processLiteralList(LiteralList node) {}
  visitLiteralList(LiteralList node) {
    processLiteralList(node);
    node.values.forEach(processReference);
  }

  processLiteralMap(LiteralMap node) {}
  visitLiteralMap(LiteralMap node) {
    processLiteralMap(node);
    for (LiteralMapEntry entry in node.entries) {
      processReference(entry.key);
      processReference(entry.value);
    }
  }

  processConstant(Constant node) {}
  visitConstant(Constant node)  {
    processConstant(node);
  }

  processCreateFunction(CreateFunction node) {}
  visitCreateFunction(CreateFunction node) {
    processCreateFunction(node);
    visit(node.definition);
  }

  processMutableVariable(node) {}
  visitMutableVariable(MutableVariable node) {
    processMutableVariable(node);
  }

  processGetMutableVariable(GetMutableVariable node) {}
  visitGetMutableVariable(GetMutableVariable node) {
    processGetMutableVariable(node);
    processReference(node.variable);
  }

  processParameter(Parameter node) {}
  visitParameter(Parameter node) {
    processParameter(node);
  }

  processContinuation(Continuation node) {}
  visitContinuation(Continuation node) {
    processContinuation(node);
    node.parameters.forEach(visitParameter);
    if (node.body != null) visit(node.body);
  }

  processIsTrue(IsTrue node) {}
  visitIsTrue(IsTrue node) {
    processIsTrue(node);
    processReference(node.value);
  }

  processIdentical(Identical node) {}
  visitIdentical(Identical node) {
    processIdentical(node);
    processReference(node.left);
    processReference(node.right);
  }

  processInterceptor(Interceptor node) {}
  visitInterceptor(Interceptor node) {
    processInterceptor(node);
    processReference(node.input);
  }

  processCreateInstance(CreateInstance node) {}
  visitCreateInstance(CreateInstance node) {
    processCreateInstance(node);
    node.arguments.forEach(processReference);
    node.typeInformation.forEach(processReference);
  }

  processSetField(SetField node) {}
  visitSetField(SetField node) {
    processSetField(node);
    processReference(node.object);
    processReference(node.value);
    visit(node.body);
  }

  processGetField(GetField node) {}
  visitGetField(GetField node) {
    processGetField(node);
    processReference(node.object);
  }

  processGetStatic(GetStatic node) {}
  visitGetStatic(GetStatic node) {
    processGetStatic(node);
  }

  processSetStatic(SetStatic node) {}
  visitSetStatic(SetStatic node) {
    processSetStatic(node);
    processReference(node.value);
    visit(node.body);
  }

  processCreateBox(CreateBox node) {}
  visitCreateBox(CreateBox node) {
    processCreateBox(node);
  }

  processReifyRuntimeType(ReifyRuntimeType node) {}
  visitReifyRuntimeType(ReifyRuntimeType node) {
    processReifyRuntimeType(node);
    processReference(node.value);
  }

  processReadTypeVariable(ReadTypeVariable node) {}
  visitReadTypeVariable(ReadTypeVariable node) {
    processReadTypeVariable(node);
    processReference(node.target);
  }

  processTypeExpression(TypeExpression node) {}
  visitTypeExpression(TypeExpression node) {
    processTypeExpression(node);
    node.arguments.forEach(processReference);
  }

  processNonTailThrow(NonTailThrow node) {}
  visitNonTailThrow(NonTailThrow node) {
    processNonTailThrow(node);
    processReference(node.value);
  }

  processCreateInvocationMirror(CreateInvocationMirror node) {}
  visitCreateInvocationMirror(CreateInvocationMirror node) {
    processCreateInvocationMirror(node);
    node.arguments.forEach(processReference);
  }
}
