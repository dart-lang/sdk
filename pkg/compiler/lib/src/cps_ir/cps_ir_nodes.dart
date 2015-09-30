// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library dart2js.ir_nodes;

import 'dart:collection';
import '../constants/values.dart' as values;
import '../dart_types.dart' show DartType, InterfaceType, TypeVariableType;
import '../elements/elements.dart';
import '../io/source_information.dart' show SourceInformation;
import '../types/types.dart' show TypeMask;
import '../universe/selector.dart' show Selector;

import 'builtin_operator.dart';
export 'builtin_operator.dart';

// These imports are only used for the JavaScript specific nodes.  If we want to
// support more than one native backend, we should probably create better
// abstractions for native code and its type and effect system.
import '../js/js.dart' as js show Template;
import '../native/native.dart' as native show NativeBehavior;

abstract class Node {
  /// A pointer to the parent node. Is null until set by optimization passes.
  Node parent;

  /// Workaround for a slow Object.hashCode in the VM.
  static int _usedHashCodes = 0;
  final int hashCode = ++_usedHashCodes;

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
///
/// All subclasses implement exactly one of [CallExpression],
/// [InteriorExpression], or [TailExpression].
abstract class Expression extends Node {
  InteriorNode get parent; // Only InteriorNodes may contain expressions.

  Expression plug(Expression expr) => throw 'impossible';

  /// The next expression in the basic block.
  ///
  /// For [InteriorExpression]s this is the body, for [CallExpressions] it is
  /// the body of the continuation, and for [TailExpressions] it is `null`.
  Expression get next;
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

/// An expression that creates new bindings and continues evaluation in
/// a subexpression.
///
/// The interior expressions are [LetPrim], [LetCont], [LetHandler], and
/// [LetMutable].
abstract class InteriorExpression extends Expression implements InteriorNode {
  Expression get next => body;

  /// Removes this expression from its current position in the IR.
  ///
  /// The node can be re-inserted elsewhere or remain orphaned.
  ///
  /// If orphaned, the caller is responsible for unlinking all references in
  /// the orphaned node. Use [Reference.unlink] or [Primitive.destroy] for this.
  void remove() {
    assert(parent != null);
    assert(parent.body == this);
    assert(body.parent == this);
    parent.body = body;
    body.parent = parent;
    parent = null;
    body = null;
  }

  /// Inserts this above [node].
  ///
  /// This node must be orphaned first.
  void insertAbove(Expression node) {
    insertBelow(node.parent);
  }

  /// Inserts this below [node].
  ///
  /// This node must be orphaned first.
  void insertBelow(InteriorNode newParent) {
    assert(parent == null);
    assert(body == null);
    Expression child = newParent.body;
    newParent.body = this;
    this.body = child;
    child.parent = this;
    this.parent = newParent;
  }
}

/// An expression that passes a continuation to a call.
abstract class CallExpression extends Expression {
  Reference<Continuation> get continuation;
  Expression get next => continuation.definition.body;
}

/// An expression without a continuation or a subexpression body.
///
/// These break straight-line control flow and can be thought of as ending a
/// basic block.
abstract class TailExpression extends Expression {
  Expression get next => null;
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

class EffectiveUseIterator extends Iterator<Reference<Primitive>> {
  Reference<Primitive> current;
  Reference<Primitive> next;
  final List<Refinement> stack = <Refinement>[];

  EffectiveUseIterator(Primitive prim) : next = prim.firstRef;

  bool moveNext() {
    Reference<Primitive> ref = next;
    while (true) {
      if (ref == null) {
        if (stack.isNotEmpty) {
          ref = stack.removeLast().firstRef;
        } else {
          current = null;
          return false;
        }
      } else if (ref.parent is Refinement) {
        stack.add(ref.parent);
        ref = ref.next;
      } else {
        current = ref;
        next = current.next;
        return true;
      }
    }
  }
}

class EffectiveUseIterable extends IterableBase<Reference<Primitive>> {
  Primitive primitive;
  EffectiveUseIterable(this.primitive);
  EffectiveUseIterator get iterator => new EffectiveUseIterator(primitive);
}

/// A named value.
///
/// The identity of the [Primitive] object is the name of the value.
/// The subclass describes how to compute the value.
///
/// All primitives except [Parameter] must be bound by a [LetPrim].
abstract class Primitive extends Variable<Primitive> {
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

  /// True if the primitive can be removed, assuming it has no uses
  /// (this getter does not check if there are any uses).
  ///
  /// False must be returned for primitives that may throw, diverge, or have
  /// observable side-effects.
  bool get isSafeForElimination;

  /// True if time-of-evaluation is irrelevant for the given primitive,
  /// assuming its inputs are the same values.
  bool get isSafeForReordering;

  /// The source information associated with this primitive.
  // TODO(johnniwinther): Require source information for all primitives.
  SourceInformation get sourceInformation => null;

  /// If this is a [Refinement] node, returns the value being refined.
  Primitive get effectiveDefinition => this;

  /// True if the two primitives are (refinements of) the same value.
  bool sameValue(Primitive other) {
    return effectiveDefinition == other.effectiveDefinition;
  }

  /// Iterates all non-refinement uses of the primitive and all uses of
  /// a [Refinement] of this primitive (transitively).
  ///
  /// Notes regarding concurrent modification:
  /// - The current reference may safely be unlinked.
  /// - Yet unvisited references may not be unlinked.
  /// - References to this primitive created during iteration will not be seen.
  /// - References to a refinement of this primitive may not be created during
  ///   iteration.
  EffectiveUseIterable get effectiveUses => new EffectiveUseIterable(this);

  bool get hasMultipleEffectiveUses {
    Iterator it = effectiveUses.iterator;
    return it.moveNext() && it.moveNext();
  }

  bool get hasNoEffectiveUses {
    return effectiveUses.isEmpty;
  }

  /// Unlinks all references contained in this node.
  void destroy() {
    assert(hasNoUses);
    RemovalVisitor.remove(this);
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

  /// Changes the definition referenced by this object and updates
  /// the reference chains accordingly.
  void changeTo(Definition<T> newDefinition) {
    unlink();
    previous = null;
    definition = newDefinition;
    next = definition.firstRef;
    if (next != null) next.previous = this;
    definition.firstRef = this;
  }
}

/// Evaluates a primitive and binds it to variable: `let val x = V in E`.
///
/// The bound value is in scope in the body.
///
/// During one-pass construction a LetPrim with an empty body is used to
/// represent the one-hole context `let val x = V in []`.
class LetPrim extends InteriorExpression {
  Primitive primitive;
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
class LetCont extends InteriorExpression {
  List<Continuation> continuations;
  Expression body;

  LetCont(Continuation continuation, this.body)
      : continuations = <Continuation>[continuation];

  LetCont.two(Continuation first, Continuation second, this.body)
      : continuations = <Continuation>[first, second];

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
class LetHandler extends InteriorExpression {
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
class LetMutable extends InteriorExpression {
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

/// Invoke a static function.
///
/// All optional arguments declared by [target] are passed in explicitly, and
/// occur at the end of [arguments] list, in normalized order.
///
/// Discussion:
/// All information in the [selector] is technically redundant; it will likely
/// be removed.
class InvokeStatic extends CallExpression {
  final FunctionElement target;
  final Selector selector;
  final List<Reference<Primitive>> arguments;
  final Reference<Continuation> continuation;
  final SourceInformation sourceInformation;

  InvokeStatic(this.target,
               this.selector,
               List<Primitive> args,
               Continuation cont,
               [this.sourceInformation])
      : arguments = _referenceList(args),
        continuation = new Reference<Continuation>(cont);

  InvokeStatic.byReference(this.target,
                           this.selector,
                           this.arguments,
                           this.continuation,
                           [this.sourceInformation]);

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
class InvokeMethod extends CallExpression {
  Reference<Primitive> receiver;
  Selector selector;
  TypeMask mask;
  final List<Reference<Primitive>> arguments;
  final Reference<Continuation> continuation;
  final SourceInformation sourceInformation;

  /// If true, the [receiver] is intercepted and the actual receiver is in
  /// the first argument. Otherwise, the [receiver] is the actual receiver.
  ///
  /// This flag is always false for non-intercepted selectors, but it may also
  /// be false for intercepted selectors after dummy receiver optimization
  /// (in this case the first argument is a dummy value).
  ///
  /// It is always false before the unsugaring pass, where interceptors have
  /// not yet been introduced.
  bool receiverIsIntercepted = false;

  /// If true, it is known that the receiver cannot be `null`.
  bool receiverIsNotNull = false;

  InvokeMethod(Primitive receiver,
               this.selector,
               this.mask,
               List<Primitive> arguments,
               Continuation continuation,
               [this.sourceInformation])
      : this.receiver = new Reference<Primitive>(receiver),
        this.arguments = _referenceList(arguments),
        this.continuation = new Reference<Continuation>(continuation);

  InvokeMethod.byReference(this.receiver,
                           this.selector,
                           this.mask,
                           this.arguments,
                           this.continuation,
                           this.sourceInformation);

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
class InvokeMethodDirectly extends CallExpression {
  Reference<Primitive> receiver;
  final FunctionElement target;
  final Selector selector;
  final List<Reference<Primitive>> arguments;
  final Reference<Continuation> continuation;
  final SourceInformation sourceInformation;

  InvokeMethodDirectly(Primitive receiver,
                       this.target,
                       this.selector,
                       List<Primitive> arguments,
                       Continuation continuation,
                       this.sourceInformation)
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
class InvokeConstructor extends CallExpression {
  final DartType dartType;
  final ConstructorElement target;
  final List<Reference<Primitive>> arguments;
  final Reference<Continuation> continuation;
  final Selector selector;
  final SourceInformation sourceInformation;

  InvokeConstructor(this.dartType,
                    this.target,
                    this.selector,
                    List<Primitive> args,
                    Continuation cont,
                    this.sourceInformation)
      : arguments = _referenceList(args),
        continuation = new Reference<Continuation>(cont);

  accept(Visitor visitor) => visitor.visitInvokeConstructor(this);
}

/// An alias for [value] in a context where the value is known to satisfy
/// [type].
///
/// Refinement nodes are inserted before the type propagator pass and removed
/// afterwards, so as not to complicate passes that don't reason about types,
/// but need to reason about value references being identical (i.e. referring
/// to the same primitive).
class Refinement extends Primitive {
  Reference<Primitive> value;
  final TypeMask refineType;

  Refinement(Primitive value, this.refineType)
    : value = new Reference<Primitive>(value);

  bool get isSafeForElimination => true;
  bool get isSafeForReordering => false;

  accept(Visitor visitor) => visitor.visitRefinement(this);

  Primitive get effectiveDefinition => value.definition.effectiveDefinition;
}

/// An "is" type test.
///
/// Returns `true` if [value] is an instance of [type].
///
/// [type] must not be the [Object], `dynamic` or [Null] types (though it might
/// be a type variable containing one of these types). This design is chosen
/// to simplify code generation for type tests.
class TypeTest extends Primitive {
  Reference<Primitive> value;
  final DartType dartType;

  /// If [type] is an [InterfaceType], this holds the internal representation of
  /// the type arguments to [type]. Since these may reference type variables
  /// from the enclosing class, they are not constant.
  ///
  /// If [type] is a [TypeVariableType], this is a singleton list with
  /// the internal representation of the type held in that type variable.
  ///
  /// If [type] is a [FunctionType], this is a singleton list with the
  /// internal representation of that type,
  ///
  /// Otherwise the list is empty.
  final List<Reference<Primitive>> typeArguments;

  TypeTest(Primitive value,
           this.dartType,
           List<Primitive> typeArguments)
  : this.value = new Reference<Primitive>(value),
    this.typeArguments = _referenceList(typeArguments);

  accept(Visitor visitor) => visitor.visitTypeTest(this);

  bool get isSafeForElimination => true;
  bool get isSafeForReordering => true;
}

/// An "as" type cast.
///
/// If [value] is `null` or is an instance of [type], [continuation] is invoked
/// with [value] as argument. Otherwise, a [CastError] is thrown.
///
/// Discussion:
/// The parameter to [continuation] is redundant since it will always equal
/// [value], which is typically in scope in the continuation. However, it might
/// simplify type propagation, since a better type can be computed for the
/// continuation parameter without needing flow-sensitive analysis.
class TypeCast extends CallExpression {
  Reference<Primitive> value;
  final DartType dartType;

  /// See the corresponding field on [TypeTest].
  final List<Reference<Primitive>> typeArguments;
  final Reference<Continuation> continuation;

  TypeCast(Primitive value,
           this.dartType,
           List<Primitive> typeArguments,
           Continuation cont)
      : this.value = new Reference<Primitive>(value),
        this.typeArguments = _referenceList(typeArguments),
        this.continuation = new Reference<Continuation>(cont);

  accept(Visitor visitor) => visitor.visitTypeCast(this);
}

/// Apply a built-in operator.
///
/// It must be known that the arguments have the proper types.
class ApplyBuiltinOperator extends Primitive {
  BuiltinOperator operator;
  List<Reference<Primitive>> arguments;
  final SourceInformation sourceInformation;

  ApplyBuiltinOperator(this.operator,
                       List<Primitive> arguments,
                       this.sourceInformation)
      : this.arguments = _referenceList(arguments);

  accept(Visitor visitor) => visitor.visitApplyBuiltinOperator(this);

  bool get isSafeForElimination => true;
  bool get isSafeForReordering => true;
}

/// Apply a built-in method.
///
/// It must be known that the arguments have the proper types.
class ApplyBuiltinMethod extends Primitive {
  BuiltinMethod method;
  Reference<Primitive> receiver;
  List<Reference<Primitive>> arguments;
  final SourceInformation sourceInformation;

  bool receiverIsNotNull;

  ApplyBuiltinMethod(this.method,
                     Primitive receiver,
                     List<Primitive> arguments,
                     this.sourceInformation,
                     {this.receiverIsNotNull: false})
      : this.receiver = new Reference<Primitive>(receiver),
        this.arguments = _referenceList(arguments);

  accept(Visitor visitor) => visitor.visitApplyBuiltinMethod(this);

  bool get isSafeForElimination => false;
  bool get isSafeForReordering => false;
}

/// Throw a value.
///
/// Throw is an expression, i.e., it always occurs in tail position with
/// respect to a body or expression.
class Throw extends TailExpression {
  Reference<Primitive> value;

  Throw(Primitive value) : value = new Reference<Primitive>(value);

  accept(Visitor visitor) => visitor.visitThrow(this);
}

/// Rethrow
///
/// Rethrow can only occur inside a continuation bound by [LetHandler].  It
/// implicitly throws the exception parameter of the enclosing handler with
/// the same stack trace as the enclosing handler.
class Rethrow extends TailExpression {
  accept(Visitor visitor) => visitor.visitRethrow(this);
}

/// An expression that is known to be unreachable.
///
/// This can be placed as the body of a call continuation, when the caller is
/// known never to invoke it, e.g. because the calling expression always throws.
class Unreachable extends TailExpression {
  accept(Visitor visitor) => visitor.visitUnreachable(this);
}

/// Gets the value from a [MutableVariable].
///
/// [MutableVariable]s can be seen as ref cells that are not first-class
/// values.  A [LetPrim] with a [GetMutable] can then be seen as:
///
///   let prim p = ![variable] in [body]
///
class GetMutable extends Primitive {
  final Reference<MutableVariable> variable;

  GetMutable(MutableVariable variable)
      : this.variable = new Reference<MutableVariable>(variable);

  accept(Visitor visitor) => visitor.visitGetMutable(this);

  bool get isSafeForElimination => true;
  bool get isSafeForReordering => false;
}

/// Assign a [MutableVariable].
///
/// [MutableVariable]s can be seen as ref cells that are not first-class
/// values.  This can be seen as a dereferencing assignment:
///
///   { [variable] := [value]; [body] }
class SetMutable extends Primitive {
  final Reference<MutableVariable> variable;
  final Reference<Primitive> value;

  SetMutable(MutableVariable variable, Primitive value)
      : this.variable = new Reference<MutableVariable>(variable),
        this.value = new Reference<Primitive>(value);

  accept(Visitor visitor) => visitor.visitSetMutable(this);

  bool get isSafeForElimination => false;
  bool get isSafeForReordering => false;
}

/// Invoke a continuation in tail position.
class InvokeContinuation extends TailExpression {
  Reference<Continuation> continuation;
  List<Reference<Primitive>> arguments;
  SourceInformation sourceInformation;

  // An invocation of a continuation is recursive if it occurs in the body of
  // the continuation itself.
  bool isRecursive;

  /// True if this invocation escapes from the body of a [LetHandler]
  /// (i.e. a try block). Notably, such an invocation cannot be inlined.
  bool isEscapingTry;

  InvokeContinuation(Continuation cont, List<Primitive> args,
                     {this.isRecursive: false,
                      this.isEscapingTry: false,
                      this.sourceInformation})
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
  InvokeContinuation.uninitialized({this.isRecursive: false,
                                    this.isEscapingTry: false})
      : continuation = null,
        arguments = null,
        sourceInformation = null;

  accept(Visitor visitor) => visitor.visitInvokeContinuation(this);
}

/// Choose between a pair of continuations based on a condition value.
///
/// The two continuations must not declare any parameters.
class Branch extends TailExpression {
  final Reference<Primitive> condition;
  final Reference<Continuation> trueContinuation;
  final Reference<Continuation> falseContinuation;

  /// If true, only the value `true` satisfies the condition. Otherwise, any
  /// truthy value satisfies the check.
  ///
  /// Non-strict checks are preferable when the condition is known to be a
  /// boolean.
  bool isStrictCheck;

  Branch.strict(Primitive condition,
                Continuation trueCont,
                Continuation falseCont)
      : this.condition = new Reference<Primitive>(condition),
        trueContinuation = new Reference<Continuation>(trueCont),
        falseContinuation = new Reference<Continuation>(falseCont),
        isStrictCheck = true;

  Branch.loose(Primitive condition,
               Continuation trueCont,
               Continuation falseCont)
      : this.condition = new Reference<Primitive>(condition),
        trueContinuation = new Reference<Continuation>(trueCont),
        falseContinuation = new Reference<Continuation>(falseCont),
        this.isStrictCheck = false;

  accept(Visitor visitor) => visitor.visitBranch(this);
}

/// Directly assigns to a field on a given object.
class SetField extends Primitive {
  final Reference<Primitive> object;
  FieldElement field;
  final Reference<Primitive> value;

  SetField(Primitive object, this.field, Primitive value)
      : this.object = new Reference<Primitive>(object),
        this.value = new Reference<Primitive>(value);

  accept(Visitor visitor) => visitor.visitSetField(this);

  bool get isSafeForElimination => false;
  bool get isSafeForReordering => false;
}

/// Directly reads from a field on a given object.
///
/// The [object] must either be `null` or an object that has [field].
class GetField extends Primitive {
  final Reference<Primitive> object;
  FieldElement field;

  /// True if the object is known not to be null.
  // TODO(asgerf): This is a placeholder until we agree on how to track
  //               side effects.
  bool objectIsNotNull = false;

  GetField(Primitive object, this.field)
      : this.object = new Reference<Primitive>(object);

  accept(Visitor visitor) => visitor.visitGetField(this);

  bool get isSafeForElimination => objectIsNotNull;
  bool get isSafeForReordering => false;

  toString() => 'GetField($field)';
}

/// Get the length of a string or native list.
class GetLength extends Primitive {
  final Reference<Primitive> object;

  /// True if the object is known not to be null.
  bool objectIsNotNull = false;

  GetLength(Primitive object) : this.object = new Reference<Primitive>(object);

  bool get isSafeForElimination => objectIsNotNull;
  bool get isSafeForReordering => false;

  accept(Visitor v) => v.visitGetLength(this);
}

/// Read an entry from a string or native list.
///
/// [object] must be null or a native list or a string, and [index] must be
/// an integer.
class GetIndex extends Primitive {
  final Reference<Primitive> object;
  final Reference<Primitive> index;

  /// True if the object is known not to be null.
  bool objectIsNotNull = false;

  GetIndex(Primitive object, Primitive index)
      : this.object = new Reference<Primitive>(object),
        this.index = new Reference<Primitive>(index);

  bool get isSafeForElimination => objectIsNotNull;
  bool get isSafeForReordering => false;

  accept(Visitor v) => v.visitGetIndex(this);
}

/// Set an entry on a native list.
///
/// [object] must be null or a native list, and [index] must be an integer.
///
/// The primitive itself has no value and may not be referenced.
class SetIndex extends Primitive {
  final Reference<Primitive> object;
  final Reference<Primitive> index;
  final Reference<Primitive> value;

  SetIndex(Primitive object, Primitive index, Primitive value)
      : this.object = new Reference<Primitive>(object),
        this.index = new Reference<Primitive>(index),
        this.value = new Reference<Primitive>(value);

  bool get isSafeForElimination => false;
  bool get isSafeForReordering => false;

  accept(Visitor v) => v.visitSetIndex(this);
}

/// Reads the value of a static field or tears off a static method.
///
/// Note that lazily initialized fields should be read using GetLazyStatic.
class GetStatic extends Primitive {
  /// Can be [FieldElement] or [FunctionElement].
  final Element element;
  final SourceInformation sourceInformation;

  GetStatic(this.element, [this.sourceInformation]);

  accept(Visitor visitor) => visitor.visitGetStatic(this);

  bool get isSafeForElimination {
    return true;
  }
  bool get isSafeForReordering {
    return element is FunctionElement || element.isFinal;
  }
}

/// Sets the value of a static field.
class SetStatic extends Primitive {
  final FieldElement element;
  final Reference<Primitive> value;
  final SourceInformation sourceInformation;

  SetStatic(this.element, Primitive value, [this.sourceInformation])
      : this.value = new Reference<Primitive>(value);

  accept(Visitor visitor) => visitor.visitSetStatic(this);

  bool get isSafeForElimination => false;
  bool get isSafeForReordering => false;
}

/// Reads the value of a lazily initialized static field.
///
/// If the field has not yet been initialized, its initializer is evaluated
/// and assigned to the field.
///
/// [continuation] is then invoked with the value of the field as argument.
class GetLazyStatic extends CallExpression {
  final FieldElement element;
  final Reference<Continuation> continuation;
  final SourceInformation sourceInformation;

  GetLazyStatic(this.element,
                Continuation continuation,
                [this.sourceInformation])
      : continuation = new Reference<Continuation>(continuation);

  accept(Visitor visitor) => visitor.visitGetLazyStatic(this);
}

/// Creates an object for holding boxed variables captured by a closure.
class CreateBox extends Primitive {
  accept(Visitor visitor) => visitor.visitCreateBox(this);

  bool get isSafeForElimination => true;
  bool get isSafeForReordering => true;
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

  final SourceInformation sourceInformation;

  CreateInstance(this.classElement, List<Primitive> arguments,
      List<Primitive> typeInformation,
      this.sourceInformation)
      : this.arguments = _referenceList(arguments),
        this.typeInformation = _referenceList(typeInformation);

  accept(Visitor visitor) => visitor.visitCreateInstance(this);

  bool get isSafeForElimination => true;
  bool get isSafeForReordering => true;

  toString() => 'CreateInstance($classElement)';
}

class Interceptor extends Primitive {
  final Reference<Primitive> input;
  final Set<ClassElement> interceptedClasses = new Set<ClassElement>();
  final SourceInformation sourceInformation;

  /// If non-null, all uses of this the interceptor call are guaranteed to
  /// see this value.
  ///
  /// The interceptor call is not immediately replaced by the constant, because
  /// that might prevent the interceptor from being shared.
  ///
  /// The precise input type is not known when sharing interceptors, because
  /// refinement nodes have been removed by then. So this field carries the
  /// known constant until we know if it should be shared or replaced by
  /// the constant.
  values.InterceptorConstantValue constantValue;

  Interceptor(Primitive input, this.sourceInformation)
      : this.input = new Reference<Primitive>(input);

  accept(Visitor visitor) => visitor.visitInterceptor(this);

  bool get isSafeForElimination => true;
  bool get isSafeForReordering => true;
}

/// Create an instance of [Invocation] for use in a call to `noSuchMethod`.
class CreateInvocationMirror extends Primitive {
  final Selector selector;
  final List<Reference<Primitive>> arguments;

  CreateInvocationMirror(this.selector, List<Primitive> arguments)
      : this.arguments = _referenceList(arguments);

  accept(Visitor visitor) => visitor.visitCreateInvocationMirror(this);

  bool get isSafeForElimination => true;
  bool get isSafeForReordering => true;
}

class ForeignCode extends CallExpression {
  final js.Template codeTemplate;
  final TypeMask type;
  final List<Reference<Primitive>> arguments;
  final native.NativeBehavior nativeBehavior;
  final FunctionElement dependency;
  final Reference<Continuation> continuation;

  ForeignCode(this.codeTemplate, this.type, List<Primitive> arguments,
      this.nativeBehavior, Continuation continuation, {this.dependency})
      : this.arguments = _referenceList(arguments),
        this.continuation = new Reference<Continuation>(continuation);

  accept(Visitor visitor) => visitor.visitForeignCode(this);
}

class Constant extends Primitive {
  final values.ConstantValue value;
  final SourceInformation sourceInformation;

  Constant(this.value, {this.sourceInformation}) {
    assert(value != null);
  }

  accept(Visitor visitor) => visitor.visitConstant(this);

  bool get isSafeForElimination => true;
  bool get isSafeForReordering => true;
}

class LiteralList extends Primitive {
  /// The List type being created; this is not the type argument.
  final InterfaceType dartType;
  final List<Reference<Primitive>> values;

  LiteralList(this.dartType, List<Primitive> values)
      : this.values = _referenceList(values);

  accept(Visitor visitor) => visitor.visitLiteralList(this);

  bool get isSafeForElimination => true;
  bool get isSafeForReordering => true;
}

class LiteralMapEntry {
  final Reference<Primitive> key;
  final Reference<Primitive> value;

  LiteralMapEntry(Primitive key, Primitive value)
      : this.key = new Reference<Primitive>(key),
        this.value = new Reference<Primitive>(value);
}

class LiteralMap extends Primitive {
  final InterfaceType dartType;
  final List<LiteralMapEntry> entries;

  LiteralMap(this.dartType, this.entries);

  accept(Visitor visitor) => visitor.visitLiteralMap(this);

  bool get isSafeForElimination => true;
  bool get isSafeForReordering => true;
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

  bool get isSafeForElimination => true;
  bool get isSafeForReordering => true;
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

  bool get isSafeForElimination => true;
  bool get isSafeForReordering => true;
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

  Continuation.retrn()
    : parameters = <Parameter>[new Parameter(null)],
      isRecursive = false;

  accept(Visitor visitor) => visitor.visitContinuation(this);
}

/// Common interface for [Primitive] and [MutableVariable].
abstract class Variable<T extends Variable<T>> extends Definition<T> {
  /// Type of value held in the variable.
  ///
  /// Is `null` until initialized by type propagation.
  TypeMask type;
}

/// Identifies a mutable variable.
class MutableVariable extends Variable<MutableVariable> {
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

  final SourceInformation sourceInformation;

  ReifyRuntimeType(Primitive value, this.sourceInformation)
    : this.value = new Reference<Primitive>(value);

  @override
  accept(Visitor visitor) => visitor.visitReifyRuntimeType(this);

  bool get isSafeForElimination => true;
  bool get isSafeForReordering => true;
}

/// Read the value the type variable [variable] from the target object.
///
/// The resulting value is an internal representation (and not neccessarily a
/// Dart object), and must be reified by [ReifyRuntimeType], if it should be
/// used as a Dart value.
class ReadTypeVariable extends Primitive {
  final TypeVariableType variable;
  final Reference<Primitive> target;
  final SourceInformation sourceInformation;

  ReadTypeVariable(this.variable, Primitive target, this.sourceInformation)
      : this.target = new Reference<Primitive>(target);

  @override
  accept(Visitor visitor) => visitor.visitReadTypeVariable(this);

  bool get isSafeForElimination => true;
  bool get isSafeForReordering => true;
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

  bool get isSafeForElimination => true;
  bool get isSafeForReordering => true;
}

class Await extends CallExpression {
  final Reference<Primitive> input;
  final Reference<Continuation> continuation;

  Await(Primitive input, Continuation continuation)
    : this.input = new Reference<Primitive>(input),
      this.continuation = new Reference<Continuation>(continuation);

  @override
  accept(Visitor visitor) {
    return visitor.visitAwait(this);
  }
}

class Yield extends CallExpression {
  final Reference<Primitive> input;
  final Reference<Continuation> continuation;
  final bool hasStar;

  Yield(Primitive input, this.hasStar, Continuation continuation)
    : this.input = new Reference<Primitive>(input),
      this.continuation = new Reference<Continuation>(continuation);

  @override
  accept(Visitor visitor) {
    return visitor.visitYield(this);
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
  T visitThrow(Throw node);
  T visitRethrow(Rethrow node);
  T visitBranch(Branch node);
  T visitTypeCast(TypeCast node);
  T visitSetMutable(SetMutable node);
  T visitSetStatic(SetStatic node);
  T visitGetLazyStatic(GetLazyStatic node);
  T visitSetField(SetField node);
  T visitUnreachable(Unreachable node);
  T visitAwait(Await node);
  T visitYield(Yield node);

  // Definitions.
  T visitLiteralList(LiteralList node);
  T visitLiteralMap(LiteralMap node);
  T visitConstant(Constant node);
  T visitCreateFunction(CreateFunction node);
  T visitGetMutable(GetMutable node);
  T visitParameter(Parameter node);
  T visitContinuation(Continuation node);
  T visitMutableVariable(MutableVariable node);
  T visitGetStatic(GetStatic node);
  T visitInterceptor(Interceptor node);
  T visitCreateInstance(CreateInstance node);
  T visitGetField(GetField node);
  T visitCreateBox(CreateBox node);
  T visitReifyRuntimeType(ReifyRuntimeType node);
  T visitReadTypeVariable(ReadTypeVariable node);
  T visitTypeExpression(TypeExpression node);
  T visitCreateInvocationMirror(CreateInvocationMirror node);
  T visitTypeTest(TypeTest node);
  T visitApplyBuiltinOperator(ApplyBuiltinOperator node);
  T visitApplyBuiltinMethod(ApplyBuiltinMethod node);
  T visitGetLength(GetLength node);
  T visitGetIndex(GetIndex node);
  T visitSetIndex(SetIndex node);
  T visitRefinement(Refinement node);

  // Support for literal foreign code.
  T visitForeignCode(ForeignCode node);
}

/// Visits all non-recursive children of a CPS term, i.e. anything
/// not of type [Expression] or [Continuation].
///
/// The `process*` methods are called in pre-order for every node visited.
/// These can be overridden without disrupting the visitor traversal.
class LeafVisitor implements Visitor {
  const LeafVisitor();

  visit(Node node) => node.accept(this);

  processReference(Reference ref) {}

  processFunctionDefinition(FunctionDefinition node) {}
  visitFunctionDefinition(FunctionDefinition node) {
    processFunctionDefinition(node);
    if (node.thisParameter != null) visit(node.thisParameter);
    node.parameters.forEach(visit);
    visit(node.returnContinuation);
  }

  // Expressions.

  processLetPrim(LetPrim node) {}
  visitLetPrim(LetPrim node) {
    processLetPrim(node);
    visit(node.primitive);
  }

  processLetCont(LetCont node) {}
  visitLetCont(LetCont node) {
    processLetCont(node);
    node.continuations.forEach(visit);
  }

  processLetHandler(LetHandler node) {}
  visitLetHandler(LetHandler node) {
    processLetHandler(node);
  }

  processLetMutable(LetMutable node) {}
  visitLetMutable(LetMutable node) {
    processLetMutable(node);
    visit(node.variable);
    processReference(node.value);
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
    processReference(node.condition);
  }

  processTypeCast(TypeCast node) {}
  visitTypeCast(TypeCast node) {
    processTypeCast(node);
    processReference(node.continuation);
    processReference(node.value);
    node.typeArguments.forEach(processReference);
  }

  processTypeTest(TypeTest node) {}
  visitTypeTest(TypeTest node) {
    processTypeTest(node);
    processReference(node.value);
    node.typeArguments.forEach(processReference);
  }

  processSetMutable(SetMutable node) {}
  visitSetMutable(SetMutable node) {
    processSetMutable(node);
    processReference(node.variable);
    processReference(node.value);
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

  processGetMutable(GetMutable node) {}
  visitGetMutable(GetMutable node) {
    processGetMutable(node);
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

  processCreateInvocationMirror(CreateInvocationMirror node) {}
  visitCreateInvocationMirror(CreateInvocationMirror node) {
    processCreateInvocationMirror(node);
    node.arguments.forEach(processReference);
  }

  processApplyBuiltinOperator(ApplyBuiltinOperator node) {}
  visitApplyBuiltinOperator(ApplyBuiltinOperator node) {
    processApplyBuiltinOperator(node);
    node.arguments.forEach(processReference);
  }

  processApplyBuiltinMethod(ApplyBuiltinMethod node) {}
  visitApplyBuiltinMethod(ApplyBuiltinMethod node) {
    processApplyBuiltinMethod(node);
    processReference(node.receiver);
    node.arguments.forEach(processReference);
  }

  processForeignCode(ForeignCode node) {}
  visitForeignCode(ForeignCode node) {
    processForeignCode(node);
    if (node.continuation != null) {
      processReference(node.continuation);
    }
    node.arguments.forEach(processReference);
  }

  processUnreachable(Unreachable node) {}
  visitUnreachable(Unreachable node) {
    processUnreachable(node);
  }

  processAwait(Await node) {}
  visitAwait(Await node) {
    processAwait(node);
    processReference(node.input);
    processReference(node.continuation);
  }

  processYield(Yield node) {}
  visitYield(Yield node) {
    processYield(node);
    processReference(node.input);
    processReference(node.continuation);
  }

  processGetLength(GetLength node) {}
  visitGetLength(GetLength node) {
    processGetLength(node);
    processReference(node.object);
  }

  processGetIndex(GetIndex node) {}
  visitGetIndex(GetIndex node) {
    processGetIndex(node);
    processReference(node.object);
    processReference(node.index);
  }

  processSetIndex(SetIndex node) {}
  visitSetIndex(SetIndex node) {
    processSetIndex(node);
    processReference(node.object);
    processReference(node.index);
    processReference(node.value);
  }

  processRefinement(Refinement node) {}
  visitRefinement(Refinement node) {
    processRefinement(node);
    processReference(node.value);
  }
}

typedef void StackAction();

/// Calls `process*` for all nodes in a tree.
/// For simple usage, only override the `process*` methods.
///
/// To avoid deep recursion, this class uses an "action stack" containing
/// callbacks to be invoked after the processing of some term has finished.
///
/// To avoid excessive overhead from the action stack, basic blocks of
/// interior nodes are iterated in a loop without using the action stack.
///
/// The iteration order can be controlled by overriding the `traverse*`
/// methods for [LetCont], [LetPrim], [LetMutable], [LetHandler] and
/// [Continuation].
///
/// The `traverse*` methods return the expression to visit next, and may
/// push other subterms onto the stack using [push] or [pushAction] to visit
/// them later. Actions pushed onto the stack will be executed after the body
/// has been processed (and the stack actions it pushed have been executed).
///
/// By default, the `traverse` methods visit all non-recursive subterms,
/// push all bound continuations on the stack, and return the body of the term.
///
/// Subclasses should not override the `visit` methods for the nodes that have
/// a `traverse` method.
class RecursiveVisitor extends LeafVisitor {
  List<StackAction> _stack = <StackAction>[];

  void pushAction(StackAction callback) {
    _stack.add(callback);
  }

  void push(Continuation cont) {
    _stack.add(() {
      if (cont.isReturnContinuation) {
        traverseContinuation(cont);
      } else {
        _processBlock(traverseContinuation(cont));
      }
    });
  }

  visitFunctionDefinition(FunctionDefinition node) {
    processFunctionDefinition(node);
    if (node.thisParameter != null) visit(node.thisParameter);
    node.parameters.forEach(visit);
    visit(node.returnContinuation);
    visit(node.body);
  }

  visitContinuation(Continuation cont) {
    if (cont.isReturnContinuation) {
      traverseContinuation(cont);
    } else {
      _trampoline(traverseContinuation(cont));
    }
  }

  visitLetPrim(LetPrim node) => _trampoline(node);
  visitLetCont(LetCont node) => _trampoline(node);
  visitLetHandler(LetHandler node) => _trampoline(node);
  visitLetMutable(LetMutable node) => _trampoline(node);

  Expression traverseContinuation(Continuation cont) {
    processContinuation(cont);
    cont.parameters.forEach(visitParameter);
    return cont.body;
  }

  Expression traverseLetCont(LetCont node) {
    processLetCont(node);
    node.continuations.forEach(push);
    return node.body;
  }

  Expression traverseLetHandler(LetHandler node) {
    processLetHandler(node);
    push(node.handler);
    return node.body;
  }

  Expression traverseLetPrim(LetPrim node) {
    processLetPrim(node);
    visit(node.primitive);
    return node.body;
  }

  Expression traverseLetMutable(LetMutable node) {
    processLetMutable(node);
    visit(node.variable);
    processReference(node.value);
    return node.body;
  }

  void _trampoline(Expression node) {
    int initialHeight = _stack.length;
    _processBlock(node);
    while (_stack.length > initialHeight) {
      StackAction callback = _stack.removeLast();
      callback();
    }
  }

  _processBlock(Expression node) {
    while (node is InteriorExpression) {
      if (node is LetCont) {
        node = traverseLetCont(node);
      } else if (node is LetHandler) {
        node = traverseLetHandler(node);
      } else if (node is LetPrim) {
        node = traverseLetPrim(node);
      } else {
        node = traverseLetMutable(node);
      }
    }
    visit(node);
  }
}

/// Visit a just-deleted subterm and unlink all [Reference]s in it.
class RemovalVisitor extends RecursiveVisitor {
  processReference(Reference reference) {
    reference.unlink();
  }

  static void remove(Node node) {
    (new RemovalVisitor()).visit(node);
  }
}
