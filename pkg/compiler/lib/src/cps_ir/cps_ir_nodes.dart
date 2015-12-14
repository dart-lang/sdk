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

  Node() {
    setParentPointers();
  }

  accept(Visitor visitor);

  /// Updates the [parent] of the immediate children to refer to this node.
  ///
  /// All constructors call this method to initialize parent pointers.
  void setParentPointers();
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

  void replaceUsesWith(Definition<T> newDefinition) {
    if (newDefinition == this) return;
    if (hasNoUses) return;
    Reference<T> previous, current = firstRef;
    do {
      current.definition = newDefinition;
      previous = current;
      current = current.next;
    } while (current != null);
    previous.next = newDefinition.firstRef;
    if (newDefinition.firstRef != null) {
      newDefinition.firstRef.previous = previous;
    }
    newDefinition.firstRef = firstRef;
    firstRef = null;
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

  /// True if this primitive has a value that can be used by other expressions.
  bool get hasValue;

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

  /// If this is a [Refinement], [BoundsCheck] or [NullCheck] node, returns the
  /// value being refined, the indexable object being checked, or the value
  /// that was checked to be non-null, respectively.
  ///
  /// Those instructions all return the corresponding operand directly, and
  /// this getter can be used to get (closer to) where the value came from.
  //
  // TODO(asgerf): Also do this for [TypeCast]?
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

  /// Replaces this definition, both at the binding site and at all uses sites.
  ///
  /// This can be thought of as changing the definition of a `let` while
  /// preserving the variable name:
  ///
  ///     let x = OLD in BODY
  ///       ==>
  ///     let x = NEW in BODY
  ///
  void replaceWith(Primitive newDefinition) {
    assert(this is! Parameter);
    assert(newDefinition is! Parameter);
    assert(newDefinition.parent == null);
    replaceUsesWith(newDefinition);
    destroy();
    LetPrim let = parent;
    let.primitive = newDefinition;
    newDefinition.parent = let;
    newDefinition.useElementAsHint(hint);
  }
}

/// A primitive that is generally not safe for elimination, but may be marked
/// as safe by type propagation
//
// TODO(asgerf): Store the flag in a bitmask in [Primitive] and get rid of this
//               class.
abstract class UnsafePrimitive extends Primitive {
  bool isSafeForElimination = false;
  bool isSafeForReordering = false;
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

  void setParentPointers() {
    primitive.parent = this;
    if (body != null) body.parent = this;
  }
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

  void setParentPointers() {
    _setParentsOnNodes(continuations, this);
    if (body != null) body.parent = this;
  }
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

  void setParentPointers() {
    handler.parent = this;
    if (body != null) body.parent = this;
  }
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

  void setParentPointers() {
    variable.parent = this;
    value.parent = this;
    if (body != null) body.parent = this;
  }
}

/// Invoke a static function.
///
/// All optional arguments declared by [target] are passed in explicitly, and
/// occur at the end of [arguments] list, in normalized order.
///
/// Discussion:
/// All information in the [selector] is technically redundant; it will likely
/// be removed.
class InvokeStatic extends UnsafePrimitive {
  final FunctionElement target;
  final Selector selector;
  final List<Reference<Primitive>> arguments;
  final SourceInformation sourceInformation;

  InvokeStatic(this.target,
               this.selector,
               List<Primitive> args,
               [this.sourceInformation])
      : arguments = _referenceList(args);

  InvokeStatic.byReference(this.target,
                           this.selector,
                           this.arguments,
                           [this.sourceInformation]);

  accept(Visitor visitor) => visitor.visitInvokeStatic(this);

  bool get hasValue => true;

  void setParentPointers() {
    _setParentsOnList(arguments, this);
  }
}

enum CallingConvention {
  /// JS receiver is the Dart receiver, there are no extra arguments.
  ///
  /// For example: `foo.bar$1(x)`
  Normal,

  /// JS receiver is an interceptor, the first argument is the Dart receiver.
  ///
  /// For example: `getInterceptor(foo).bar$1(foo, x)`
  Intercepted,

  /// JS receiver is the Dart receiver, the first argument is a dummy value.
  ///
  /// For example: `foo.bar$1(0, x)`
  DummyIntercepted,
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
class InvokeMethod extends UnsafePrimitive {
  Reference<Primitive> receiver;
  Selector selector;
  TypeMask mask;
  final List<Reference<Primitive>> arguments;
  final SourceInformation sourceInformation;

  CallingConvention callingConvention = CallingConvention.Normal;

  Reference<Primitive> get dartReceiverReference {
    return callingConvention == CallingConvention.Intercepted
        ? arguments[0]
        : receiver;
  }

  Primitive get dartReceiver => dartReceiverReference.definition;

  Reference<Primitive> dartArgumentReference(int n) {
    return callingConvention == CallingConvention.Normal
        ? arguments[n]
        : arguments[n + 1];
  }

  Primitive dartArgument(int n) => dartArgumentReference(n).definition;

  /// If true, it is known that the receiver cannot be `null`.
  bool receiverIsNotNull = false;

  InvokeMethod(Primitive receiver,
               this.selector,
               this.mask,
               List<Primitive> arguments,
               [this.sourceInformation])
      : this.receiver = new Reference<Primitive>(receiver),
        this.arguments = _referenceList(arguments);

  InvokeMethod.byReference(this.receiver,
                           this.selector,
                           this.mask,
                           this.arguments,
                           this.sourceInformation);

  accept(Visitor visitor) => visitor.visitInvokeMethod(this);

  bool get hasValue => true;

  void setParentPointers() {
    receiver.parent = this;
    _setParentsOnList(arguments, this);
  }
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
class InvokeMethodDirectly extends UnsafePrimitive {
  Reference<Primitive> receiver;
  final FunctionElement target;
  final Selector selector;
  final List<Reference<Primitive>> arguments;
  final SourceInformation sourceInformation;

  CallingConvention callingConvention = CallingConvention.Normal;

  Reference<Primitive> get dartReceiverReference {
    return callingConvention == CallingConvention.Intercepted
        ? arguments[0]
        : receiver;
  }

  Primitive get dartReceiver => dartReceiverReference.definition;

  Reference<Primitive> dartArgumentReference(int n) {
    return callingConvention == CallingConvention.Normal
        ? arguments[n]
        : arguments[n + 1];
  }

  Primitive dartArgument(int n) => dartArgumentReference(n).definition;

  InvokeMethodDirectly(Primitive receiver,
                       this.target,
                       this.selector,
                       List<Primitive> arguments,
                       this.sourceInformation)
      : this.receiver = new Reference<Primitive>(receiver),
        this.arguments = _referenceList(arguments);

  accept(Visitor visitor) => visitor.visitInvokeMethodDirectly(this);

  bool get hasValue => true;

  void setParentPointers() {
    receiver.parent = this;
    _setParentsOnList(arguments, this);
  }
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
class InvokeConstructor extends UnsafePrimitive {
  final DartType dartType;
  final ConstructorElement target;
  final List<Reference<Primitive>> arguments;
  final Selector selector;
  final SourceInformation sourceInformation;

  /// If non-null, this is an allocation site-specific type that is potentially
  /// better than the inferred return type of [target].
  ///
  /// In particular, container type masks depend on the allocation site and
  /// can therefore not be inferred solely based on the call target.
  TypeMask allocationSiteType;

  InvokeConstructor(this.dartType,
                    this.target,
                    this.selector,
                    List<Primitive> args,
                    this.sourceInformation,
                    {this.allocationSiteType})
      : arguments = _referenceList(args);

  accept(Visitor visitor) => visitor.visitInvokeConstructor(this);

  bool get hasValue => true;

  void setParentPointers() {
    _setParentsOnList(arguments, this);
  }
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

  bool get hasValue => true;
  bool get isSafeForElimination => true;
  bool get isSafeForReordering => false;

  accept(Visitor visitor) => visitor.visitRefinement(this);

  Primitive get effectiveDefinition => value.definition.effectiveDefinition;

  void setParentPointers() {
    value.parent = this;
  }
}

/// Checks that [index] is a valid index on a given indexable [object].
///
/// Compiles to the following, with a subset of the conditions in the `if`:
///
///     if (index < 0 || index >= object.length || object.length === 0)
///         ThrowIndexOutOfRangeException(object, index);
///
/// [index] must be an integer, and [object] must refer to null or an indexable
/// object, and [length] must be the length of [object] at the time of the
/// check.
///
/// Returns [object] so the bounds check can be used to restrict code motion.
/// It is possible to have a bounds check node that performs no checks but
/// is retained to restrict code motion.
///
/// The [index] reference may be null if there are no checks to perform,
/// and the [length] reference may be null if there is no upper bound or
/// emptiness check.
///
/// If a separate code motion guard for the index is required, e.g. because it
/// must be known to be non-negative in an operator that does not involve
/// [object], a [Refinement] can be created for it with the non-negative integer
/// type.
class BoundsCheck extends Primitive {
  final Reference<Primitive> object;
  Reference<Primitive> index;
  Reference<Primitive> length; // FIXME write docs for length
  int checks;
  final SourceInformation sourceInformation;

  /// If true, check that `index >= 0`.
  bool get hasLowerBoundCheck => checks & LOWER_BOUND != 0;

  /// If true, check that `index < object.length`.
  bool get hasUpperBoundCheck => checks & UPPER_BOUND != 0;

  /// If true, check that `object.length !== 0`.
  ///
  /// Equivalent to a lower bound check with `object.length - 1` as the index,
  /// but this check is faster.
  ///
  /// Although [index] is not used in the condition, it is used to generate
  /// the thrown error.  Currently it is always `-1` for emptiness checks,
  /// because that corresponds to `object.length - 1` in the error case.
  bool get hasEmptinessCheck => checks & EMPTINESS != 0;

  /// True if the [length] is needed to perform the check.
  bool get lengthUsedInCheck => checks & (UPPER_BOUND | EMPTINESS) != 0;

  bool get hasNoChecks => checks == NONE;

  static const int UPPER_BOUND = 1 << 0;
  static const int LOWER_BOUND = 1 << 1;
  static const int EMPTINESS = 1 << 2; // See [hasEmptinessCheck].
  static const int BOTH_BOUNDS = UPPER_BOUND | LOWER_BOUND;
  static const int NONE = 0;

  BoundsCheck(Primitive object, Primitive index, Primitive length,
      [this.checks = BOTH_BOUNDS, this.sourceInformation])
      : this.object = new Reference<Primitive>(object),
        this.index = new Reference<Primitive>(index),
        this.length = new Reference<Primitive>(length);

  BoundsCheck.noCheck(Primitive object, [this.sourceInformation])
      : this.object = new Reference<Primitive>(object),
        this.checks = NONE;

  accept(Visitor visitor) => visitor.visitBoundsCheck(this);

  void setParentPointers() {
    object.parent = this;
    if (index != null) {
      index.parent = this;
    }
    if (length != null) {
      length.parent = this;
    }
  }

  String get checkString {
    if (hasUpperBoundCheck && hasLowerBoundCheck) {
      return 'upper-lower-checks';
    } else if (hasUpperBoundCheck) {
      return 'upper-check';
    } else if (hasLowerBoundCheck) {
      return 'lower-check';
    } else if (hasEmptinessCheck) {
      return 'emptiness-check';
    } else {
      return 'no-check';
    }
  }

  bool get isSafeForElimination => checks == NONE;
  bool get isSafeForReordering => false;
  bool get hasValue => true; // Can be referenced to restrict code motion.

  Primitive get effectiveDefinition => object.definition.effectiveDefinition;
}

/// Throw an exception if [value] is `null`.
///
/// Returns [value] so this can be used to restrict code motion.
///
/// In the simplest form this compiles to `value.toString;`.
///
/// If [selector] is set, `toString` is replaced with the (possibly minified)
/// invocation name of the selector.  This can be shorter and generate a more
/// meaningful error message, but is expensive if [value] is non-null and does
/// not have that property at runtime.
///
/// If [condition] is set, it is assumed that [condition] is true if and only
/// if [value] is null.  The check then compiles to:
///
///     if (condition) value.toString;  (or .selector if non-null)
///
/// The latter form is useful when [condition] is a form understood by the JS
/// runtime, such as a `typeof` test.
class NullCheck extends Primitive {
  final Reference<Primitive> value;
  Selector selector;
  Reference<Primitive> condition;
  final SourceInformation sourceInformation;

  NullCheck(Primitive value, this.sourceInformation)
      : this.value = new Reference<Primitive>(value);

  NullCheck.guarded(Primitive condition, Primitive value, this.selector,
        this.sourceInformation)
      : this.condition = new Reference<Primitive>(condition),
        this.value = new Reference<Primitive>(value);

  bool get isSafeForElimination => false;
  bool get isSafeForReordering => false;
  bool get hasValue => true;

  accept(Visitor visitor) => visitor.visitNullCheck(this);

  void setParentPointers() {
    value.parent = this;
    if (condition != null) {
      condition.parent = this;
    }
  }

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

  /// If [dartType] is an [InterfaceType], this holds the internal
  /// representation of the type arguments to [dartType]. Since these may
  /// reference type variables from the enclosing class, they are not constant.
  ///
  /// If [dartType] is a [TypeVariableType], this is a singleton list with the
  /// internal representation of the type held in that type variable.
  ///
  /// If [dartType] is a [FunctionType], this is a singleton list with the
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

  bool get hasValue => true;
  bool get isSafeForElimination => true;
  bool get isSafeForReordering => true;

  void setParentPointers() {
    value.parent = this;
    _setParentsOnList(typeArguments, this);
  }
}

/// An "is" type test for a raw type, performed by testing a flag property.
///
/// Returns `true` if [interceptor] is for [dartType].
class TypeTestViaFlag extends Primitive {
  Reference<Primitive> interceptor;
  final DartType dartType;

  TypeTestViaFlag(Primitive interceptor, this.dartType)
      : this.interceptor = new Reference<Primitive>(interceptor);

  accept(Visitor visitor) => visitor.visitTypeTestViaFlag(this);

  bool get hasValue => true;
  bool get isSafeForElimination => true;
  bool get isSafeForReordering => true;

  void setParentPointers() {
    interceptor.parent = this;
  }
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
class TypeCast extends UnsafePrimitive {
  Reference<Primitive> value;
  final DartType dartType;

  /// See the corresponding field on [TypeTest].
  final List<Reference<Primitive>> typeArguments;

  TypeCast(Primitive value,
           this.dartType,
           List<Primitive> typeArguments)
      : this.value = new Reference<Primitive>(value),
        this.typeArguments = _referenceList(typeArguments);

  accept(Visitor visitor) => visitor.visitTypeCast(this);

  bool get hasValue => true;

  void setParentPointers() {
    value.parent = this;
    _setParentsOnList(typeArguments, this);
  }
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

  bool get hasValue => true;
  bool get isSafeForElimination => true;
  bool get isSafeForReordering => true;

  void setParentPointers() {
    _setParentsOnList(arguments, this);
  }
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

  bool get hasValue => true;
  bool get isSafeForElimination => false;
  bool get isSafeForReordering => false;

  void setParentPointers() {
    receiver.parent = this;
    _setParentsOnList(arguments, this);
  }
}

/// Throw a value.
///
/// Throw is an expression, i.e., it always occurs in tail position with
/// respect to a body or expression.
class Throw extends TailExpression {
  Reference<Primitive> value;

  Throw(Primitive value) : value = new Reference<Primitive>(value);

  accept(Visitor visitor) => visitor.visitThrow(this);

  void setParentPointers() {
    value.parent = this;
  }
}

/// Rethrow
///
/// Rethrow can only occur inside a continuation bound by [LetHandler].  It
/// implicitly throws the exception parameter of the enclosing handler with
/// the same stack trace as the enclosing handler.
class Rethrow extends TailExpression {
  accept(Visitor visitor) => visitor.visitRethrow(this);
  void setParentPointers() {}
}

/// An expression that is known to be unreachable.
///
/// This can be placed as the body of a call continuation, when the caller is
/// known never to invoke it, e.g. because the calling expression always throws.
class Unreachable extends TailExpression {
  accept(Visitor visitor) => visitor.visitUnreachable(this);
  void setParentPointers() {}
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

  bool get hasValue => true;
  bool get isSafeForElimination => true;
  bool get isSafeForReordering => false;

  void setParentPointers() {
    variable.parent = this;
  }
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

  bool get hasValue => false;
  bool get isSafeForElimination => false;
  bool get isSafeForReordering => false;

  void setParentPointers() {
    variable.parent = this;
    value.parent = this;
  }
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

  void setParentPointers() {
    if (continuation != null) continuation.parent = this;
    if (arguments != null) _setParentsOnList(arguments, this);
  }
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

  void setParentPointers() {
    condition.parent = this;
    trueContinuation.parent = this;
    falseContinuation.parent = this;
  }
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

  bool get hasValue => false;
  bool get isSafeForElimination => false;
  bool get isSafeForReordering => false;

  void setParentPointers() {
    object.parent = this;
    value.parent = this;
  }
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

  bool get hasValue => true;
  bool get isSafeForElimination => objectIsNotNull;
  bool get isSafeForReordering => false;

  toString() => 'GetField($field)';

  void setParentPointers() {
    object.parent = this;
  }
}

/// Get the length of a string or native list.
class GetLength extends Primitive {
  final Reference<Primitive> object;

  /// True if the object is known not to be null.
  bool objectIsNotNull = false;

  GetLength(Primitive object) : this.object = new Reference<Primitive>(object);

  bool get hasValue => true;
  bool get isSafeForElimination => objectIsNotNull;
  bool get isSafeForReordering => false;

  accept(Visitor v) => v.visitGetLength(this);

  void setParentPointers() {
    object.parent = this;
  }
}

/// Read an entry from an indexable object.
///
/// [object] must be null or an indexable object, and [index] must be
/// an integer where `0 <= index < object.length`.
class GetIndex extends Primitive {
  final Reference<Primitive> object;
  final Reference<Primitive> index;

  /// True if the object is known not to be null.
  bool objectIsNotNull = false;

  GetIndex(Primitive object, Primitive index)
      : this.object = new Reference<Primitive>(object),
        this.index = new Reference<Primitive>(index);

  bool get hasValue => true;
  bool get isSafeForElimination => objectIsNotNull;
  bool get isSafeForReordering => false;

  accept(Visitor v) => v.visitGetIndex(this);

  void setParentPointers() {
    object.parent = this;
    index.parent = this;
  }
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

  bool get hasValue => false;
  bool get isSafeForElimination => false;
  bool get isSafeForReordering => false;

  accept(Visitor v) => v.visitSetIndex(this);

  void setParentPointers() {
    object.parent = this;
    index.parent = this;
    value.parent = this;
  }
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

  bool get hasValue => true;
  bool get isSafeForElimination => true;
  bool get isSafeForReordering {
    return element is FunctionElement || element.isFinal;
  }

  void setParentPointers() {}
}

/// Sets the value of a static field.
class SetStatic extends Primitive {
  final FieldElement element;
  final Reference<Primitive> value;
  final SourceInformation sourceInformation;

  SetStatic(this.element, Primitive value, [this.sourceInformation])
      : this.value = new Reference<Primitive>(value);

  accept(Visitor visitor) => visitor.visitSetStatic(this);

  bool get hasValue => false;
  bool get isSafeForElimination => false;
  bool get isSafeForReordering => false;

  void setParentPointers() {
    value.parent = this;
  }
}

/// Reads the value of a lazily initialized static field.
///
/// If the field has not yet been initialized, its initializer is evaluated
/// and assigned to the field.
class GetLazyStatic extends UnsafePrimitive {
  final FieldElement element;
  final SourceInformation sourceInformation;

  GetLazyStatic(this.element, [this.sourceInformation]);

  accept(Visitor visitor) => visitor.visitGetLazyStatic(this);

  bool get hasValue => true;

  void setParentPointers() {}
}

/// Creates an object for holding boxed variables captured by a closure.
class CreateBox extends Primitive {
  accept(Visitor visitor) => visitor.visitCreateBox(this);

  bool get hasValue => true;
  bool get isSafeForElimination => true;
  bool get isSafeForReordering => true;

  void setParentPointers() {}
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

  bool get hasValue => true;
  bool get isSafeForElimination => true;
  bool get isSafeForReordering => true;

  toString() => 'CreateInstance($classElement)';

  void setParentPointers() {
    _setParentsOnList(arguments, this);
    if (typeInformation != null) _setParentsOnList(typeInformation, this);
  }
}

/// Obtains the interceptor for the given value.  This is a method table
/// corresponding to the Dart class of the value.
///
/// All values are either intercepted or self-intercepted.  The interceptor for
/// an "intercepted value" is one of the subclasses of Interceptor.
/// The interceptor for a "self-intercepted value" is the value itself.
///
/// If the input is an intercepted value, and any of its superclasses is in
/// [interceptedClasses], the method table for the input is returned.
/// Otherwise, the input itself is returned.
///
/// There are thus three significant cases:
/// - the input is a self-interceptor
/// - the input is an intercepted value and is caught by [interceptedClasses]
/// - the input is an intercepted value but is bypassed by [interceptedClasses]
///
/// The [flags] field indicates which of the above cases may happen, with
/// additional special cases for null (which can either by intercepted or
/// bypassed).
class Interceptor extends Primitive {
  final Reference<Primitive> input;
  final Set<ClassElement> interceptedClasses = new Set<ClassElement>();
  final SourceInformation sourceInformation;

  /// The input was a self-interceptor.
  static const int SELF_INTERCEPT = 1 << 0;

  /// A non-null value was mapped to an interceptor that was mentioned in
  /// [interceptedClasses].
  static const int NON_NULL_INTERCEPT_EXACT = 1 << 1;

  /// A non-null value was mapped to an interceptor that is a subclass of
  /// one mentioned in [interceptedClasses].
  static const int NON_NULL_INTERCEPT_SUBCLASS = 1 << 2;

  /// A non-null intercepted value was bypassed because none of its supertypes
  /// were mentioned in [interceptedClasses].
  static const int NON_NULL_BYPASS = 1 << 3;

  /// Null was returned as-is.
  static const int NULL_BYPASS = 1 << 4;

  /// Null was mapped to JSNull, which was mentioned in [interceptedClasses].
  static const int NULL_INTERCEPT_EXACT = 1 << 5;

  /// Null was mapped to JSNull, because a superclass thereof (the interceptor
  /// root class) was mentioned in [interceptedClasses].
  static const int NULL_INTERCEPT_SUBCLASS = 1 << 6;

  static const int NON_NULL_INTERCEPT = NON_NULL_INTERCEPT_EXACT |
                                        NON_NULL_INTERCEPT_SUBCLASS;
  static const int NULL_INTERCEPT = NULL_INTERCEPT_EXACT |
                                    NULL_INTERCEPT_SUBCLASS;
  static const int NULL = NULL_BYPASS |
                          NULL_INTERCEPT;
  static const int INTERCEPT_EXACT = NON_NULL_INTERCEPT_EXACT |
                                     NULL_INTERCEPT_EXACT;
  static const int INTERCEPT_SUBCLASS = NON_NULL_INTERCEPT_SUBCLASS |
                                        NULL_INTERCEPT_SUBCLASS;
  static const int INTERCEPT = NULL_INTERCEPT | NON_NULL_INTERCEPT;
  static const int BYPASS = NULL_BYPASS | NON_NULL_BYPASS;

  static const int ALL_FLAGS = SELF_INTERCEPT | BYPASS | INTERCEPT;

  /// Which of the above cases may happen at runtime. Set by type propagation.
  int flags = ALL_FLAGS;

  void clearFlag(int flag) {
    flags &= ~flag;
  }

  bool get isAlwaysIntercepted => flags & ~INTERCEPT == 0;
  bool get isAlwaysNullOrIntercepted => flags & ~(NULL | INTERCEPT) == 0;

  /// If the value is intercepted, it always matches exactly a class in
  /// [interceptedClasses].
  bool get isInterceptedClassAlwaysExact {
    return flags & (INTERCEPT & ~INTERCEPT_EXACT) == 0;
  }

  Interceptor(Primitive input, this.sourceInformation)
      : this.input = new Reference<Primitive>(input);

  accept(Visitor visitor) => visitor.visitInterceptor(this);

  bool get hasValue => true;
  bool get isSafeForElimination => true;
  bool get isSafeForReordering => true;

  void setParentPointers() {
    input.parent = this;
  }
}

/// Create an instance of [Invocation] for use in a call to `noSuchMethod`.
class CreateInvocationMirror extends Primitive {
  final Selector selector;
  final List<Reference<Primitive>> arguments;

  CreateInvocationMirror(this.selector, List<Primitive> arguments)
      : this.arguments = _referenceList(arguments);

  accept(Visitor visitor) => visitor.visitCreateInvocationMirror(this);

  bool get hasValue => true;
  bool get isSafeForElimination => true;
  bool get isSafeForReordering => true;

  void setParentPointers() {
    _setParentsOnList(arguments, this);
  }
}

class ForeignCode extends UnsafePrimitive {
  final js.Template codeTemplate;
  final TypeMask type;
  final List<Reference<Primitive>> arguments;
  final native.NativeBehavior nativeBehavior;
  final FunctionElement dependency;

  ForeignCode(this.codeTemplate, this.type, List<Primitive> arguments,
      this.nativeBehavior, {this.dependency})
      : this.arguments = _referenceList(arguments);

  accept(Visitor visitor) => visitor.visitForeignCode(this);

  bool get hasValue => true;

  void setParentPointers() {
    _setParentsOnList(arguments, this);
  }
}

class Constant extends Primitive {
  final values.ConstantValue value;
  final SourceInformation sourceInformation;

  Constant(this.value, {this.sourceInformation}) {
    assert(value != null);
  }

  accept(Visitor visitor) => visitor.visitConstant(this);

  bool get hasValue => true;
  bool get isSafeForElimination => true;
  bool get isSafeForReordering => true;

  void setParentPointers() {}
}

class LiteralList extends Primitive {
  /// The List type being created; this is not the type argument.
  final InterfaceType dartType;
  final List<Reference<Primitive>> values;

  /// If non-null, this is an allocation site-specific type for the list
  /// created here.
  TypeMask allocationSiteType;

  LiteralList(this.dartType, List<Primitive> values, {this.allocationSiteType})
      : this.values = _referenceList(values);

  accept(Visitor visitor) => visitor.visitLiteralList(this);

  bool get hasValue => true;
  bool get isSafeForElimination => true;
  bool get isSafeForReordering => true;

  void setParentPointers() {
    _setParentsOnList(values, this);
  }
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

  bool get hasValue => true;
  bool get isSafeForElimination => true;
  bool get isSafeForReordering => true;

  void setParentPointers() {
    for (LiteralMapEntry entry in entries) {
      entry.key.parent = this;
      entry.value.parent = this;
    }
  }
}

class Parameter extends Primitive {
  Parameter(Entity hint) {
    super.hint = hint;
  }

  accept(Visitor visitor) => visitor.visitParameter(this);

  String toString() => 'Parameter(${hint == null ? null : hint.name})';

  bool get hasValue => true;
  bool get isSafeForElimination => true;
  bool get isSafeForReordering => true;

  void setParentPointers() {}
}

/// Continuations are normally bound by 'let cont'.  A continuation with one
/// parameter and no body is used to represent a function's return continuation.
/// The return continuation is bound by the function, not by 'let cont'.
class Continuation extends Definition<Continuation> implements InteriorNode {
  final List<Parameter> parameters;
  Expression body = null;

  // A continuation is recursive if it has any recursive invocations.
  bool isRecursive;

  bool get isReturnContinuation => body == null;

  Continuation(this.parameters, {this.isRecursive: false});

  Continuation.retrn()
    : parameters = <Parameter>[new Parameter(null)],
      isRecursive = false;

  accept(Visitor visitor) => visitor.visitContinuation(this);

  void setParentPointers() {
    _setParentsOnNodes(parameters, this);
    if (body != null) body.parent = this;
  }
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

  void setParentPointers() {}
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

  void setParentPointers() {
    if (thisParameter != null) thisParameter.parent = this;
    _setParentsOnNodes(parameters, this);
    returnContinuation.parent = this;
    if (body != null) body.parent = this;
  }
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

  bool get hasValue => true;
  bool get isSafeForElimination => true;
  bool get isSafeForReordering => true;

  void setParentPointers() {
    value.parent = this;
  }
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

  bool get hasValue => true;
  bool get isSafeForElimination => true;
  bool get isSafeForReordering => true;

  void setParentPointers() {
    target.parent = this;
  }
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

  bool get hasValue => true;
  bool get isSafeForElimination => true;
  bool get isSafeForReordering => true;

  void setParentPointers() {
    _setParentsOnList(arguments, this);
  }
}

class Await extends UnsafePrimitive {
  final Reference<Primitive> input;

  Await(Primitive input)
    : this.input = new Reference<Primitive>(input);

  @override
  accept(Visitor visitor) {
    return visitor.visitAwait(this);
  }

  bool get hasValue => true;

  void setParentPointers() {
    input.parent = this;
  }
}

class Yield extends UnsafePrimitive {
  final Reference<Primitive> input;
  final bool hasStar;

  Yield(Primitive input, this.hasStar)
    : this.input = new Reference<Primitive>(input);

  @override
  accept(Visitor visitor) {
    return visitor.visitYield(this);
  }

  bool get hasValue => true;

  void setParentPointers() {
    input.parent = this;
  }
}

List<Reference<Primitive>> _referenceList(Iterable<Primitive> definitions) {
  return definitions.map((e) => new Reference<Primitive>(e)).toList();
}

void _setParentsOnNodes(List<Node> nodes, Node parent) {
  for (Node node in nodes) {
    node.parent = parent;
  }
}

void _setParentsOnList(List<Reference> nodes, Node parent) {
  for (Reference node in nodes) {
    node.parent = parent;
  }
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
  T visitTypeTestViaFlag(TypeTestViaFlag node);
  T visitApplyBuiltinOperator(ApplyBuiltinOperator node);
  T visitApplyBuiltinMethod(ApplyBuiltinMethod node);
  T visitGetLength(GetLength node);
  T visitGetIndex(GetIndex node);
  T visitSetIndex(SetIndex node);
  T visitRefinement(Refinement node);
  T visitBoundsCheck(BoundsCheck node);
  T visitNullCheck(NullCheck node);

  // Support for literal foreign code.
  T visitForeignCode(ForeignCode node);
}

/// Recursively visits all children of a CPS term.
///
/// The user of the class is responsible for avoiding stack overflows from
/// deep recursion, e.g. by overriding methods to cut off recursion at certain
/// points.
///
/// All recursive invocations occur through the [visit] method, which the
/// subclass may override as a generic way to control the visitor without
/// overriding all visitor methods.
///
/// The `process*` methods are called in pre-order for every node visited.
/// These can be overridden without disrupting the visitor traversal.
class DeepRecursiveVisitor implements Visitor {
  const DeepRecursiveVisitor();

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

  processContinuation(Continuation node) {}
  visitContinuation(Continuation node) {
    processContinuation(node);
    node.parameters.forEach(visit);
    if (node.body != null) visit(node.body);
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
    node.arguments.forEach(processReference);
  }

  processInvokeMethodDirectly(InvokeMethodDirectly node) {}
  visitInvokeMethodDirectly(InvokeMethodDirectly node) {
    processInvokeMethodDirectly(node);
    processReference(node.receiver);
    node.arguments.forEach(processReference);
  }

  processInvokeConstructor(InvokeConstructor node) {}
  visitInvokeConstructor(InvokeConstructor node) {
    processInvokeConstructor(node);
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
    processReference(node.value);
    node.typeArguments.forEach(processReference);
  }

  processTypeTest(TypeTest node) {}
  visitTypeTest(TypeTest node) {
    processTypeTest(node);
    processReference(node.value);
    node.typeArguments.forEach(processReference);
  }

  processTypeTestViaFlag(TypeTestViaFlag node) {}
  visitTypeTestViaFlag(TypeTestViaFlag node) {
    processTypeTestViaFlag(node);
    processReference(node.interceptor);
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
  }

  processYield(Yield node) {}
  visitYield(Yield node) {
    processYield(node);
    processReference(node.input);
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

  processBoundsCheck(BoundsCheck node) {}
  visitBoundsCheck(BoundsCheck node) {
    processBoundsCheck(node);
    processReference(node.object);
    if (node.index != null) {
      processReference(node.index);
    }
    if (node.length != null) {
      processReference(node.length);
    }
  }

  processNullCheck(NullCheck node) {}
  visitNullCheck(NullCheck node) {
    processNullCheck(node);
    processReference(node.value);
    if (node.condition != null) {
      processReference(node.condition);
    }
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
class TrampolineRecursiveVisitor extends DeepRecursiveVisitor {
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
      int initialHeight = _stack.length;
      Expression body = traverseContinuation(cont);
      _trampoline(body, initialHeight: initialHeight);
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

  void _trampoline(Expression node, {int initialHeight}) {
    initialHeight = initialHeight ?? _stack.length;
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
class RemovalVisitor extends TrampolineRecursiveVisitor {
  processReference(Reference reference) {
    reference.unlink();
  }

  static void remove(Node node) {
    (new RemovalVisitor()).visit(node);
  }
}
