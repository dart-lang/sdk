// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library dart2js.ir_nodes;

import 'dart:collection';
import 'cps_fragment.dart' show CpsFragment;
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
import '../js/js.dart' as js show Template, isNullGuardOnFirstArgument;
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

  accept(BlockVisitor visitor);
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

  accept(BlockVisitor visitor);
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
  Primitive() : super(null);

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

  /// Replaces this definition with a CPS fragment (a term with a hole in it),
  /// given the value to replace the uses of the definition with.
  ///
  /// This can be thought of as substituting:
  ///
  ///     let x = OLD in BODY
  ///       ==>
  ///     FRAGMENT[BODY{newPrimitive/x}]
  void replaceWithFragment(CpsFragment fragment, Primitive newPrimitive) {
    assert(this is! Parameter);
    replaceUsesWith(newPrimitive);
    destroy();
    LetPrim let = parent;
    fragment.insertBelow(let);
    let.remove();
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

  accept(BlockVisitor visitor) => visitor.visitLetPrim(this);

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

  accept(BlockVisitor visitor) => visitor.visitLetCont(this);

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

  accept(BlockVisitor visitor) => visitor.visitLetHandler(this);

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

  accept(BlockVisitor visitor) => visitor.visitLetMutable(this);

  void setParentPointers() {
    variable.parent = this;
    value.parent = this;
    if (body != null) body.parent = this;
  }
}

enum CallingConvention {
  /// JS receiver is the Dart receiver, there are no extra arguments.
  ///
  /// This includes cases (e.g., static functions, constructors) where there
  /// is no receiver.
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

  /// JS receiver is the Dart receiver, there are no extra arguments.
  ///
  /// Compiles to a one-shot interceptor, e.g: `J.bar$1(foo, x)`
  OneShotIntercepted,
}

/// Base class of function invocations.
///
/// This class defines the common interface of function invocations.
abstract class InvocationPrimitive extends UnsafePrimitive {
  Reference<Primitive> get receiver => null;
  List<Reference<Primitive>> get arguments;
  SourceInformation get sourceInformation;

  Reference<Primitive> get dartReceiverReference => null;
  Primitive get dartReceiver => dartReceiverReference.definition;

  CallingConvention get callingConvention => CallingConvention.Normal;

  Reference<Primitive> dartArgumentReference(int n) {
    switch (callingConvention) {
      case CallingConvention.Normal:
      case CallingConvention.OneShotIntercepted:
        return arguments[n];

      case CallingConvention.Intercepted:
      case CallingConvention.DummyIntercepted:
        return arguments[n + 1];
    }
  }

  Primitive dartArgument(int n) => dartArgumentReference(n).definition;

  int get dartArgumentsLength =>
      arguments.length -
      (callingConvention == CallingConvention.Intercepted ||
          callingConvention == CallingConvention.DummyIntercepted ? 1 : 0);
}

/// Invoke a static function.
///
/// All optional arguments declared by [target] are passed in explicitly, and
/// occur at the end of [arguments] list, in normalized order.
///
/// Discussion:
/// All information in the [selector] is technically redundant; it will likely
/// be removed.
class InvokeStatic extends InvocationPrimitive {
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

/// Invoke a method on an object.
///
/// This includes getters, setters, operators, and index getter/setters.
///
/// Tearing off a method is treated like a getter invocation (getters and
/// tear-offs cannot be distinguished at compile-time).
///
/// The [selector] records the names of named arguments. The value of named
/// arguments occur at the end of the [arguments] list, in normalized order.
class InvokeMethod extends InvocationPrimitive {
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

  /// If true, it is known that the receiver cannot be `null`.
  bool receiverIsNotNull = false;

  InvokeMethod(Primitive receiver,
               this.selector,
               this.mask,
               List<Primitive> arguments,
               {this.sourceInformation,
                this.callingConvention: CallingConvention.Normal})
      : this.receiver = new Reference<Primitive>(receiver),
        this.arguments = _referenceList(arguments);

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
class InvokeMethodDirectly extends InvocationPrimitive {
  Reference<Primitive> receiver;
  final FunctionElement target;
  final Selector selector;
  final List<Reference<Primitive>> arguments;
  final SourceInformation sourceInformation;

  CallingConvention callingConvention;

  Reference<Primitive> get dartReceiverReference {
    return callingConvention == CallingConvention.Intercepted
        ? arguments[0]
        : receiver;
  }

  InvokeMethodDirectly(Primitive receiver,
                       this.target,
                       this.selector,
                       List<Primitive> arguments,
                       this.sourceInformation,
                       {this.callingConvention: CallingConvention.Normal})
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
class InvokeConstructor extends InvocationPrimitive {
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
  bool get isSafeForElimination => false;
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
        this.length = length == null ? null : new Reference<Primitive>(length);

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
/// [selector] holds the selector that is the cause of the null check. This is
/// usually a method that was inlined where [value] the receiver.
///
/// If [selector] is set and [useSelector] is true, `toString` is replaced with
/// the (possibly minified) invocation name of the selector.  This can be
/// shorter and generate a more meaningful error message, but is expensive if
/// [value] is non-null and does not have that property at runtime.
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
  final Selector selector;
  final bool useSelector;
  final Reference<Primitive> condition;
  final SourceInformation sourceInformation;

  NullCheck(Primitive value, this.sourceInformation,
            {Primitive condition,
             this.selector,
             this.useSelector: false})
      : this.value = new Reference<Primitive>(value),
        this.condition =
            condition == null ? null : new Reference<Primitive>(condition);

  NullCheck.guarded(Primitive condition, Primitive value, this.selector,
        this.sourceInformation)
      : this.condition = new Reference<Primitive>(condition),
        this.value = new Reference<Primitive>(value),
        this.useSelector = true;

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
/// Returns `true` if [value] is an instance of [dartType].
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

  accept(BlockVisitor visitor) => visitor.visitThrow(this);

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
  accept(BlockVisitor visitor) => visitor.visitRethrow(this);
  void setParentPointers() {}
}

/// An expression that is known to be unreachable.
///
/// This can be placed as the body of a call continuation, when the caller is
/// known never to invoke it, e.g. because the calling expression always throws.
class Unreachable extends TailExpression {
  accept(BlockVisitor visitor) => visitor.visitUnreachable(this);
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

  accept(BlockVisitor visitor) => visitor.visitInvokeContinuation(this);

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

  Branch(Primitive condition,
         Continuation trueCont,
         Continuation falseCont,
         {bool strict})
      : this.condition = new Reference<Primitive>(condition),
        trueContinuation = new Reference<Continuation>(trueCont),
        falseContinuation = new Reference<Continuation>(falseCont),
        isStrictCheck = strict {
    assert(strict != null);
  }

  Branch.strict(Primitive condition,
                Continuation trueCont,
                Continuation falseCont)
        : this(condition, trueCont, falseCont, strict: true);

  Branch.loose(Primitive condition,
               Continuation trueCont,
               Continuation falseCont)
      : this(condition, trueCont, falseCont, strict: false);

  accept(BlockVisitor visitor) => visitor.visitBranch(this);

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
/// If [GetStatic] is used to load a lazily initialized static field, it must
/// have been initialized beforehand, and a [witness] must be set to restrict
/// code motion.
class GetStatic extends Primitive {
  /// Can be [FieldElement] or [FunctionElement].
  final Element element;
  final SourceInformation sourceInformation;

  /// If reading a lazily initialized field, [witness] must refer to a node
  /// that initializes the field or always occurs after the field initializer.
  ///
  /// The value of the witness is not used.
  Reference<Primitive> witness;

  GetStatic(this.element, [this.sourceInformation]);

  /// Read a lazily initialized static field that is known to have been
  /// initialized by [witness] or earlier.
  GetStatic.witnessed(this.element, Primitive witness, [this.sourceInformation])
      : witness = witness == null ? null : new Reference<Primitive>(witness);

  accept(Visitor visitor) => visitor.visitGetStatic(this);

  bool get hasValue => true;
  bool get isSafeForElimination => true;
  bool get isSafeForReordering {
    return element is FunctionElement || element.isFinal;
  }

  void setParentPointers() {
    if (witness != null) {
      witness.parent = this;
    }
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

  bool isNullGuardOnNullFirstArgument() {
    if (arguments.length < 1) return false;
    // TODO(sra): Fix NativeThrowBehavior to distinguish MAY from
    // throws-nsm-on-null-followed-by-MAY and remove
    // [isNullGuardForFirstArgument].
    if (nativeBehavior.throwBehavior.isNullNSMGuard) return true;
    return js.isNullGuardOnFirstArgument(codeTemplate);
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

  accept(BlockVisitor visitor) => visitor.visitContinuation(this);

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

  /// The [VariableElement] or [ParameterElement] from which the variable
  /// binding originated.
  Entity hint;

  Variable(this.hint);

  /// Use the given element as a hint for naming this primitive.
  ///
  /// Has no effect if this primitive already has a non-null [element].
  void useElementAsHint(Entity hint) {
    this.hint ??= hint;
  }
}

/// Identifies a mutable variable.
class MutableVariable extends Variable<MutableVariable> {
  MutableVariable(Entity hint) : super(hint);

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

  accept(BlockVisitor visitor) => visitor.visitFunctionDefinition(this);

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

/// Visitor for block-level traversals that do not need to dispatch on
/// primitives.
abstract class BlockVisitor<T> {
  const BlockVisitor();

  T visit(Node node) => node.accept(this);

  // Block headers.
  T visitFunctionDefinition(FunctionDefinition node) => null;
  T visitContinuation(Continuation node) => null;

  // Interior expressions.
  T visitLetPrim(LetPrim node) => null;
  T visitLetCont(LetCont node) => null;
  T visitLetHandler(LetHandler node) => null;
  T visitLetMutable(LetMutable node) => null;

  // Tail expressions.
  T visitInvokeContinuation(InvokeContinuation node) => null;
  T visitThrow(Throw node) => null;
  T visitRethrow(Rethrow node) => null;
  T visitBranch(Branch node) => null;
  T visitUnreachable(Unreachable node) => null;

  /// Visits block-level nodes in lexical post-order (not post-dominator order).
  ///
  /// Continuations and function definitions are considered "block headers".
  /// The block itself is the sequence of interior expressions in the body,
  /// terminated by a tail expression.
  ///
  /// Each block is visited starting with its tail expression, then every
  /// interior expression from bottom to top, and finally the block header
  /// is visited.
  ///
  /// Blocks are visited in post-order, so the body of a continuation is always
  /// processed before its non-recursive invocation sites.
  ///
  /// The IR may be transformed during the traversal, but only the original
  /// nodes will be visited.
  static void traverseInPostOrder(FunctionDefinition root, BlockVisitor v) {
    List<Continuation> stack = <Continuation>[];
    List<Node> nodes = <Node>[];
    void walkBlock(InteriorNode block) {
      nodes.add(block);
      Expression node = block.body;
      nodes.add(node);
      while (node.next != null) {
        if (node is LetCont) {
          stack.addAll(node.continuations);
        } else if (node is LetHandler) {
          stack.add(node.handler);
        }
        node = node.next;
        nodes.add(node);
      }
    }
    walkBlock(root);
    while (stack.isNotEmpty) {
      walkBlock(stack.removeLast());
    }
    nodes.reversed.forEach(v.visit);
  }

  /// Visits block-level nodes in lexical pre-order.
  ///
  /// The IR may be transformed during the traversal, but the currently
  /// visited node should not be removed, as its 'body' pointer is needed
  /// for the traversal.
  static void traverseInPreOrder(FunctionDefinition root, BlockVisitor v) {
    List<Continuation> stack = <Continuation>[];
    void walkBlock(InteriorNode block) {
      v.visit(block);
      Expression node = block.body;
      v.visit(node);
      while (node.next != null) {
        if (node is LetCont) {
          stack.addAll(node.continuations);
        } else if (node is LetHandler) {
          stack.add(node.handler);
        }
        node = node.next;
        v.visit(node);
      }
    }
    walkBlock(root);
    while (stack.isNotEmpty) {
      walkBlock(stack.removeLast());
    }
  }
}

abstract class Visitor<T> implements BlockVisitor<T> {
  const Visitor();

  T visit(Node node);

  // Definitions.
  T visitInvokeStatic(InvokeStatic node);
  T visitInvokeMethod(InvokeMethod node);
  T visitInvokeMethodDirectly(InvokeMethodDirectly node);
  T visitInvokeConstructor(InvokeConstructor node);
  T visitTypeCast(TypeCast node);
  T visitSetMutable(SetMutable node);
  T visitSetStatic(SetStatic node);
  T visitSetField(SetField node);
  T visitGetLazyStatic(GetLazyStatic node);
  T visitAwait(Await node);
  T visitYield(Yield node);
  T visitLiteralList(LiteralList node);
  T visitLiteralMap(LiteralMap node);
  T visitConstant(Constant node);
  T visitGetMutable(GetMutable node);
  T visitParameter(Parameter node);
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
    if (node.witness != null) {
      processReference(node.witness);
    }
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

/// A visitor to copy instances of [Definition] or its subclasses, except for
/// instances of [Continuation].
///
/// The visitor maintains a map from original definitions to their copies.
/// When the [copy] method is called for a non-Continuation definition,
/// a copy is created, added to the map and returned as the result. Copying a
/// definition assumes that the definitions of all references have already
/// been copied by the same visitor.
class DefinitionCopyingVisitor extends Visitor<Definition> {
  Map<Definition, Definition> _copies = <Definition, Definition>{};

  /// Put a copy into the map.
  ///
  /// This method should be used instead of directly adding copies to the map.
  Definition putCopy(Definition original, Definition copy) {
    if (copy is Variable) {
      Variable originalVariable = original;
      copy.type = originalVariable.type;
      copy.hint = originalVariable.hint;
    }
    return _copies[original] = copy;
  }

  /// Get the copy of a [Reference]'s definition from the map.
  Definition getCopy(Reference reference) => _copies[reference.definition];

  /// Map a list of [Reference]s to the list of their definition's copies.
  List<Definition> getList(List<Reference> list) => list.map(getCopy).toList();

  /// Copy a non-[Continuation] [Definition].
  Definition copy(Definition node) {
    assert (node is! Continuation);
    return putCopy(node, visit(node));
  }

  Definition visit(Node node) => node.accept(this);

  visitFunctionDefinition(FunctionDefinition node) {}
  visitLetPrim(LetPrim node) {}
  visitLetCont(LetCont node) {}
  visitLetHandler(LetHandler node) {}
  visitLetMutable(LetMutable node) {}
  visitInvokeContinuation(InvokeContinuation node) {}
  visitThrow(Throw node) {}
  visitRethrow(Rethrow node) {}
  visitBranch(Branch node) {}
  visitUnreachable(Unreachable node) {}
  visitContinuation(Continuation node) {}

  Definition visitInvokeStatic(InvokeStatic node) {
    return new InvokeStatic(node.target, node.selector, getList(node.arguments),
        node.sourceInformation);
  }

  Definition visitInvokeMethod(InvokeMethod node) {
    return new InvokeMethod(getCopy(node.receiver), node.selector, node.mask,
        getList(node.arguments),
        sourceInformation: node.sourceInformation,
        callingConvention: node.callingConvention);
  }

  Definition visitInvokeMethodDirectly(InvokeMethodDirectly node) {
    return new InvokeMethodDirectly(getCopy(node.receiver), node.target,
        node.selector,
        getList(node.arguments),
        node.sourceInformation,
        callingConvention: node.callingConvention);
  }

  Definition visitInvokeConstructor(InvokeConstructor node) {
    return new InvokeConstructor(node.dartType, node.target, node.selector,
        getList(node.arguments),
        node.sourceInformation)
        ..allocationSiteType = node.allocationSiteType;
  }

  Definition visitTypeCast(TypeCast node) {
    return new TypeCast(getCopy(node.value), node.dartType,
        getList(node.typeArguments));
  }

  Definition visitSetMutable(SetMutable node) {
    return new SetMutable(getCopy(node.variable), getCopy(node.value));
  }

  Definition visitSetStatic(SetStatic node) {
    return new SetStatic(node.element, getCopy(node.value),
        node.sourceInformation);
  }

  Definition visitSetField(SetField node) {
    return new SetField(getCopy(node.object), node.field, getCopy(node.value));
  }

  Definition visitGetLazyStatic(GetLazyStatic node) {
    return new GetLazyStatic(node.element, node.sourceInformation);
  }

  Definition visitAwait(Await node) {
    return new Await(getCopy(node.input));
  }

  Definition visitYield(Yield node) {
    return new Yield(getCopy(node.input), node.hasStar);
  }

  Definition visitLiteralList(LiteralList node) {
    return new LiteralList(node.dartType, getList(node.values))
        ..allocationSiteType = node.allocationSiteType;
  }

  Definition visitLiteralMap(LiteralMap node) {
    List<LiteralMapEntry> entries = node.entries.map((LiteralMapEntry entry) {
      return new LiteralMapEntry(getCopy(entry.key), getCopy(entry.value));
    }).toList();
    return new LiteralMap(node.dartType, entries);
  }

  Definition visitConstant(Constant node) {
    return new Constant(node.value, sourceInformation: node.sourceInformation);
  }

  Definition visitGetMutable(GetMutable node) {
    return new GetMutable(getCopy(node.variable));
  }

  Definition visitParameter(Parameter node) {
    return new Parameter(node.hint);
  }

  Definition visitMutableVariable(MutableVariable node) {
    return new MutableVariable(node.hint);
  }

  Definition visitGetStatic(GetStatic node) {
    return new GetStatic(node.element, node.sourceInformation);
  }

  Definition visitInterceptor(Interceptor node) {
    return new Interceptor(getCopy(node.input), node.sourceInformation)
        ..interceptedClasses.addAll(node.interceptedClasses);
  }

  Definition visitCreateInstance(CreateInstance node) {
    return new CreateInstance(node.classElement, getList(node.arguments),
        getList(node.typeInformation),
        node.sourceInformation);
  }

  Definition visitGetField(GetField node) {
    return new GetField(getCopy(node.object), node.field);
  }

  Definition visitCreateBox(CreateBox node) {
    return new CreateBox();
  }

  Definition visitReifyRuntimeType(ReifyRuntimeType node) {
    return new ReifyRuntimeType(getCopy(node.value), node.sourceInformation);
  }

  Definition visitReadTypeVariable(ReadTypeVariable node) {
    return new ReadTypeVariable(node.variable, getCopy(node.target),
        node.sourceInformation);
  }

  Definition visitTypeExpression(TypeExpression node) {
    return new TypeExpression(node.dartType, getList(node.arguments));
  }

  Definition visitCreateInvocationMirror(CreateInvocationMirror node) {
    return new CreateInvocationMirror(node.selector, getList(node.arguments));
  }

  Definition visitTypeTest(TypeTest node) {
    return new TypeTest(getCopy(node.value), node.dartType,
        getList(node.typeArguments));
  }

  Definition visitTypeTestViaFlag(TypeTestViaFlag node) {
    return new TypeTestViaFlag(getCopy(node.interceptor), node.dartType);
  }

  Definition visitApplyBuiltinOperator(ApplyBuiltinOperator node) {
    return new ApplyBuiltinOperator(node.operator, getList(node.arguments),
        node.sourceInformation);
  }

  Definition visitApplyBuiltinMethod(ApplyBuiltinMethod node) {
    return new ApplyBuiltinMethod(node.method, getCopy(node.receiver),
        getList(node.arguments),
        node.sourceInformation,
        receiverIsNotNull: node.receiverIsNotNull);
  }

  Definition visitGetLength(GetLength node) {
    return new GetLength(getCopy(node.object));
  }

  Definition visitGetIndex(GetIndex node) {
    return new GetIndex(getCopy(node.object), getCopy(node.index));
  }

  Definition visitSetIndex(SetIndex node) {
    return new SetIndex(getCopy(node.object), getCopy(node.index),
        getCopy(node.value));
  }

  Definition visitRefinement(Refinement node) {
    return new Refinement(getCopy(node.value), node.refineType);
  }

  Definition visitBoundsCheck(BoundsCheck node) {
    if (node.hasNoChecks) {
      return new BoundsCheck.noCheck(getCopy(node.object),
          node.sourceInformation);
    } else {
      return new BoundsCheck(getCopy(node.object), getCopy(node.index),
          node.length == null ? null : getCopy(node.length),
          node.checks,
          node.sourceInformation);
    }
  }

  Definition visitNullCheck(NullCheck node) {
    return new NullCheck(getCopy(node.value), node.sourceInformation,
        condition: node.condition == null ? null : getCopy(node.condition),
        selector: node.selector,
        useSelector: node.useSelector);
  }

  Definition visitForeignCode(ForeignCode node) {
    return new ForeignCode(node.codeTemplate, node.type,
        getList(node.arguments),
        node.nativeBehavior,
        dependency: node.dependency);
  }
}

/// A trampolining visitor to copy [FunctionDefinition]s.
class CopyingVisitor extends TrampolineRecursiveVisitor {
  // The visitor maintains a map from original continuations to their copies.
  Map<Continuation, Continuation> _copies = <Continuation, Continuation>{};

  // The visitor uses an auxiliary visitor to copy definitions.
  DefinitionCopyingVisitor _definitions = new DefinitionCopyingVisitor();

  // While copying a block, the state of the visitor is a 'linked list' of
  // the expressions in the block's body, with a pointer to the last element
  // of the list.
  Expression _first = null;
  Expression _current = null;

  void plug(Expression body) {
    if (_first == null) {
      _first = body;
    } else {
      assert(_current != null);
      InteriorExpression interior = _current;
      interior.body = body;
    }
    _current = body;
  }

  // Continuations are added to the visitor's stack to be visited after copying
  // the current block is finished.  The stack action saves the current block,
  // copies the continuation's body, sets the body on the copy of the
  // continuation, and restores the current block.
  //
  // Note that continuations are added to the copy map before the stack action
  // to visit them is performed.
  void push(Continuation cont) {
    assert(!cont.isReturnContinuation);
    _stack.add(() {
      Expression savedFirst = _first;
      _first = _current = null;
      _processBlock(cont.body);
      _copies[cont].body = _first;
      _first = savedFirst;
      _current = null;
    });
  }

  FunctionDefinition copy(FunctionDefinition node) {
    assert(_first == null && _current == null);
    _first = _current = null;
    // Definitions are copied where they are bound, before processing
    // expressions in the scope of their binding.
    Parameter thisParameter = node.thisParameter == null
        ? null
        : _definitions.copy(node.thisParameter);
    List<Parameter> parameters =
        node.parameters.map(_definitions.copy).toList();
    // Though the return continuation's parameter does not have any uses,
    // we still make a proper copy to ensure that hints, type, etc. are
    // copied.
    Parameter returnParameter =
        _definitions.copy(node.returnContinuation.parameters.first);
    Continuation returnContinuation = _copies[node.returnContinuation] =
        new Continuation([returnParameter]);

    visit(node.body);
    FunctionDefinition copy = new FunctionDefinition(node.element,
        thisParameter,
        parameters,
        returnContinuation,
        _first);
    _first = _current = null;
    return copy;
  }

  Node visit(Node node) => node.accept(this);

  Expression traverseLetCont(LetCont node) {
    // Continuations are copied where they are bound, before processing
    // expressions in the scope of their binding.
    List<Continuation> continuations = node.continuations.map((Continuation c) {
      push(c);
      return _copies[c] =
          new Continuation(c.parameters.map(_definitions.copy).toList());
    }).toList();
    plug(new LetCont.many(continuations, null));
    return node.body;
  }

  Expression traverseLetHandler(LetHandler node) {
    // Continuations are copied where they are bound, before processing
    // expressions in the scope of their binding.
    push(node.handler);
    Continuation handler = _copies[node.handler] =
        new Continuation(node.handler.parameters.map(_definitions.copy)
            .toList());
    plug(new LetHandler(handler, null));
    return node.body;
  }

  Expression traverseLetPrim(LetPrim node) {
    plug(new LetPrim(_definitions.copy(node.primitive)));
    return node.body;
  }

  Expression traverseLetMutable(LetMutable node) {
    plug(new LetMutable(_definitions.copy(node.variable),
        _definitions.getCopy(node.value)));
    return node.body;
  }

  // Tail expressions do not have references, so we do not need to map them
  // to their copies.
  visitInvokeContinuation(InvokeContinuation node) {
    plug(new InvokeContinuation(_copies[node.continuation.definition],
        _definitions.getList(node.arguments),
        isRecursive: node.isRecursive,
        isEscapingTry: node.isEscapingTry,
        sourceInformation: node.sourceInformation));
  }

  visitThrow(Throw node) {
    plug(new Throw(_definitions.getCopy(node.value)));
  }

  visitRethrow(Rethrow node) {
    plug(new Rethrow());
  }

  visitBranch(Branch node) {
    plug(new Branch.loose(_definitions.getCopy(node.condition),
        _copies[node.trueContinuation.definition],
        _copies[node.falseContinuation.definition])
      ..isStrictCheck = node.isStrictCheck);
  }

  visitUnreachable(Unreachable node) {
    plug(new Unreachable());
  }
}
