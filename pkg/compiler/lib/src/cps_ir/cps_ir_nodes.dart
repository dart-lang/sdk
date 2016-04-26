// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library dart2js.ir_nodes;

import 'dart:collection';
import 'cps_fragment.dart' show CpsFragment;
import 'cps_ir_nodes_sexpr.dart';
import '../constants/values.dart' as values;
import '../dart_types.dart' show DartType, InterfaceType, TypeVariableType;
import '../elements/elements.dart';
import '../io/source_information.dart' show SourceInformation;
import '../types/types.dart' show TypeMask;
import '../universe/selector.dart' show Selector;

import 'builtin_operator.dart';
export 'builtin_operator.dart';

import 'effects.dart';

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

  /// Returns the SExpression for the subtree rooted at this node.
  ///
  /// [annotations] maps strings to nodes and/or nodes to values that will be
  /// converted to strings. Each binding causes the annotation to appear on the
  /// given node.
  ///
  /// For example, the following could be used to diagnose a problem with nodes
  /// not appearing in an environment map:
  ///
  ///     if (environment[node] == null)
  ///       root.debugPrint({
  ///         'currentNode': node,
  ///         'caller': someContinuation
  ///       });
  ///       throw 'Node was not in environment';
  ///     }
  ///
  /// If two strings map to the same node, it will be given both annotations.
  ///
  /// Avoid using nodes as keys if there is a chance that two keys are the
  /// same node.
  String debugString([Map annotations = const {}]) {
    return new SExpressionStringifier()
        .withAnnotations(annotations)
        .withTypes()
        .visit(this);
  }

  /// Prints the result of [debugString].
  void debugPrint([Map annotations = const {}]) {
    print(debugString(annotations));
  }
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

/// The base class of things that variables can refer to: primitives,
/// continuations, function and continuation parameters, etc.
abstract class Definition<T extends Definition<T>> extends Node {
  // The head of a linked-list of occurrences, in no particular order.
  Reference<T> firstRef;

  bool get hasAtMostOneUse => firstRef == null || firstRef.next == null;
  bool get hasExactlyOneUse => firstRef != null && firstRef.next == null;
  bool get hasNoUses => firstRef == null;
  bool get hasAtLeastOneUse => firstRef != null;
  bool get hasMultipleUses => !hasAtMostOneUse;

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

class RefinedUseIterable extends IterableBase<Reference<Primitive>> {
  Primitive primitive;
  RefinedUseIterable(this.primitive);
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

  /// Returns a bitmask with the non-local side effects and dependencies of
  /// this primitive, as defined by [Effects].
  int get effects => Effects.none;

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

  /// If this is a [Refinement], [BoundsCheck] or [ReceiverCheck] node, returns
  /// the value being refined, the indexable object being checked, or the value
  /// that was checked to be non-null, respectively.
  ///
  /// Those instructions all return the corresponding operand directly, and
  /// this getter can be used to get (closer to) where the value came from.
  //
  // TODO(asgerf): Also do this for [TypeCast]?
  Primitive get effectiveDefinition => this;

  /// Like [effectiveDefinition] but only unfolds [Refinement] nodes.
  Primitive get unrefined => this;

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
  RefinedUseIterable get refinedUses => new RefinedUseIterable(this);

  bool get hasMultipleRefinedUses {
    Iterator it = refinedUses.iterator;
    return it.moveNext() && it.moveNext();
  }

  bool get hasNoRefinedUses {
    return refinedUses.isEmpty;
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

/// Continuations are normally bound by 'let cont'.  A continuation with one
/// parameter and no body is used to represent a function's return continuation.
/// The return continuation is bound by the function, not by 'let cont'.
class Continuation extends Definition<Continuation> implements InteriorNode {
  final List<Parameter> parameters;
  Expression body = null;

  // A continuation is recursive if it has any recursive invocations.
  bool isRecursive;

  /// True if this is the return continuation.  The return continuation is bound
  /// by [FunctionDefinition].
  bool get isReturnContinuation => body == null;

  /// True if this is a branch continuation.  Branch continuations are bound
  /// by [LetCont] and can only have one use.
  bool get isBranchContinuation => firstRef?.parent is Branch;

  /// True if this is the exception handler bound by a [LetHandler].
  bool get isHandlerContinuation => parent is LetHandler;

  /// True if this is a non-return continuation that can be targeted by
  /// [InvokeContinuation].
  bool get isJoinContinuation {
    return body != null &&
        parent is! LetHandler &&
        (firstRef == null || firstRef.parent is InvokeContinuation);
  }

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
  Parameter interceptorParameter;
  final Parameter receiverParameter;
  final List<Parameter> parameters;
  final Continuation returnContinuation;
  final SourceInformation sourceInformation;
  Expression body;

  FunctionDefinition(this.element, this.receiverParameter, this.parameters,
      this.returnContinuation, this.body,
      {this.interceptorParameter, this.sourceInformation});

  accept(BlockVisitor visitor) => visitor.visitFunctionDefinition(this);

  void setParentPointers() {
    if (interceptorParameter != null) interceptorParameter.parent = this;
    if (receiverParameter != null) receiverParameter.parent = this;
    _setParentsOnNodes(parameters, this);
    returnContinuation.parent = this;
    if (body != null) body.parent = this;
  }
}

// ----------------------------------------------------------------------------
//                            PRIMITIVES
// ----------------------------------------------------------------------------

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

/// A primitive that is generally not safe for elimination, but may be marked
/// as safe by type propagation
abstract class UnsafePrimitive extends Primitive {
  int effects = Effects.all;
  bool isSafeForElimination = false;
  bool isSafeForReordering = false;
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
  Reference<Primitive> get interceptorRef => null;
  Primitive get interceptor => interceptorRef?.definition;

  Reference<Primitive> get receiverRef => null;
  Primitive get receiver => receiverRef?.definition;

  List<Reference<Primitive>> get argumentRefs;
  Primitive argument(int n) => argumentRefs[n].definition;
  Iterable<Primitive> get arguments => _dereferenceList(argumentRefs);

  CallingConvention get callingConvention => CallingConvention.Normal;

  SourceInformation get sourceInformation;
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
  final List<Reference<Primitive>> argumentRefs;
  final SourceInformation sourceInformation;

  InvokeStatic(this.target, this.selector, List<Primitive> args,
      [this.sourceInformation])
      : argumentRefs = _referenceList(args);

  InvokeStatic.byReference(this.target, this.selector, this.argumentRefs,
      [this.sourceInformation]);

  accept(Visitor visitor) => visitor.visitInvokeStatic(this);

  bool get hasValue => true;

  void setParentPointers() {
    _setParentsOnList(argumentRefs, this);
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
  Reference<Primitive> interceptorRef;
  Reference<Primitive> receiverRef;
  Selector selector;
  TypeMask mask;
  final List<Reference<Primitive>> argumentRefs;
  final SourceInformation sourceInformation;
  CallingConvention _callingConvention;

  CallingConvention get callingConvention => _callingConvention;

  InvokeMethod(
      Primitive receiver, this.selector, this.mask, List<Primitive> arguments,
      {this.sourceInformation,
      CallingConvention callingConvention,
      Primitive interceptor})
      : this.receiverRef = new Reference<Primitive>(receiver),
        this.argumentRefs = _referenceList(arguments),
        this.interceptorRef = _optionalReference(interceptor),
        this._callingConvention = callingConvention ??
            (interceptor != null
                ? CallingConvention.Intercepted
                : CallingConvention.Normal);

  accept(Visitor visitor) => visitor.visitInvokeMethod(this);

  bool get hasValue => true;

  void setParentPointers() {
    interceptorRef?.parent = this;
    receiverRef.parent = this;
    _setParentsOnList(argumentRefs, this);
  }

  void makeIntercepted(Primitive interceptor) {
    interceptorRef?.unlink();
    interceptorRef = new Reference<Primitive>(interceptor)..parent = this;
    _callingConvention = CallingConvention.Intercepted;
  }

  void makeOneShotIntercepted() {
    interceptorRef?.unlink();
    interceptorRef = null;
    _callingConvention = CallingConvention.OneShotIntercepted;
  }

  void makeDummyIntercepted() {
    interceptorRef?.unlink();
    interceptorRef = null;
    _callingConvention = CallingConvention.DummyIntercepted;
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
  Reference<Primitive> interceptorRef;
  Reference<Primitive> receiverRef;
  final FunctionElement target;
  final Selector selector;
  final List<Reference<Primitive>> argumentRefs;
  final SourceInformation sourceInformation;

  InvokeMethodDirectly(Primitive receiver, this.target, this.selector,
      List<Primitive> arguments, this.sourceInformation,
      {Primitive interceptor})
      : this.receiverRef = new Reference<Primitive>(receiver),
        this.argumentRefs = _referenceList(arguments),
        this.interceptorRef = _optionalReference(interceptor);

  accept(Visitor visitor) => visitor.visitInvokeMethodDirectly(this);

  bool get hasValue => true;

  void setParentPointers() {
    interceptorRef?.parent = this;
    receiverRef.parent = this;
    _setParentsOnList(argumentRefs, this);
  }

  bool get isConstructorBodyCall => target is ConstructorBodyElement;
  bool get isTearOff => selector.isGetter && !target.isGetter;

  void makeIntercepted(Primitive interceptor) {
    interceptorRef?.unlink();
    interceptorRef = new Reference<Primitive>(interceptor)..parent = this;
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
  final List<Reference<Primitive>> argumentRefs;
  final Selector selector;
  final SourceInformation sourceInformation;

  /// If non-null, this is an allocation site-specific type that is potentially
  /// better than the inferred return type of [target].
  ///
  /// In particular, container type masks depend on the allocation site and
  /// can therefore not be inferred solely based on the call target.
  TypeMask allocationSiteType;

  InvokeConstructor(this.dartType, this.target, this.selector,
      List<Primitive> args, this.sourceInformation,
      {this.allocationSiteType})
      : argumentRefs = _referenceList(args);

  accept(Visitor visitor) => visitor.visitInvokeConstructor(this);

  bool get hasValue => true;

  void setParentPointers() {
    _setParentsOnList(argumentRefs, this);
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

  Primitive get unrefined => value.definition.unrefined;

  void setParentPointers() {
    value.parent = this;
  }
}

/// Checks that [index] is a valid index on a given indexable [object].
///
/// In the simplest form, compiles to the following:
///
///     if (index < 0 || index >= object.length)
///         ThrowIndexOutOfRangeException(object, index);
///
/// In the general form, any of the following conditions can be checked:
///
///  Lower bound: `index >= 0`
///  Upper bound: `index < object.length`
///  Emptiness:   `object.length !== 0`
///  Integerness: `index >>> 0 === index`
///
/// [index] must be an integer unless integerness is checked, and [object] must
/// refer to null or an indexable object, and [length] must be the length of
/// [object] at the time of the check.
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
  final Reference<Primitive> objectRef;
  Reference<Primitive> indexRef;
  Reference<Primitive> lengthRef;
  int checks;
  final SourceInformation sourceInformation;

  Primitive get object => objectRef.definition;
  Primitive get index => indexRef?.definition;
  Primitive get length => lengthRef?.definition;

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

  /// If true, check that `index` is an integer.
  bool get hasIntegerCheck => checks & INTEGER != 0;

  /// True if the [length] is needed to perform the check.
  bool get lengthUsedInCheck => checks & (UPPER_BOUND | EMPTINESS) != 0;

  bool get hasNoChecks => checks == NONE;

  static const int UPPER_BOUND = 1 << 0;
  static const int LOWER_BOUND = 1 << 1;
  static const int EMPTINESS = 1 << 2; // See [hasEmptinessCheck].
  static const int INTEGER = 1 << 3; // Check if index is an int.
  static const int BOTH_BOUNDS = UPPER_BOUND | LOWER_BOUND;
  static const int NONE = 0;

  BoundsCheck(Primitive object, Primitive index, Primitive length,
      [this.checks = BOTH_BOUNDS, this.sourceInformation])
      : this.objectRef = new Reference<Primitive>(object),
        this.indexRef = new Reference<Primitive>(index),
        this.lengthRef = _optionalReference(length);

  BoundsCheck.noCheck(Primitive object, [this.sourceInformation])
      : this.objectRef = new Reference<Primitive>(object),
        this.checks = NONE;

  accept(Visitor visitor) => visitor.visitBoundsCheck(this);

  void setParentPointers() {
    objectRef.parent = this;
    if (indexRef != null) {
      indexRef.parent = this;
    }
    if (lengthRef != null) {
      lengthRef.parent = this;
    }
  }

  String get checkString {
    if (hasNoChecks) return 'no-check';
    return [
      hasUpperBoundCheck ? 'upper' : null,
      hasLowerBoundCheck ? 'lower' : null,
      hasEmptinessCheck ? 'emptiness' : null,
      hasIntegerCheck ? 'integer' : null,
      'check'
    ].where((x) => x != null).join('-');
  }

  bool get isSafeForElimination => checks == NONE;
  bool get isSafeForReordering => false;
  bool get hasValue => true; // Can be referenced to restrict code motion.

  Primitive get effectiveDefinition => object.effectiveDefinition;
}

/// Throw a [NoSuchMethodError] if [value] cannot respond to [selector].
///
/// Returns [value] so this can be used to restrict code motion.
///
/// The check can take one of three forms:
///
///     value.toString;
///     value.selectorName;
///     value.selectorName();    (should only be used if check always fails)
///
/// The first two forms are used when it is known that only null fails the
/// check.  Additionally, the check may be guarded by a [condition], allowing
/// for three more forms:
///
///     if (condition) value.toString;          (this form is valid but unused)
///     if (condition) value.selectorName;
///     if (condition) value.selectorName();
///
/// The condition must be true if and only if the check should fail. It should
/// ideally be of a form understood by JS engines, e.g. a `typeof` test.
///
/// If [useSelector] is false, the first form instead becomes `value.toString;`.
/// This form is faster when the value is non-null and the accessed property has
/// been removed by tree shaking.
///
/// [selector] may not be one of the selectors implemented by the null object.
class ReceiverCheck extends Primitive {
  final Reference<Primitive> valueRef;
  final Selector selector;
  final SourceInformation sourceInformation;
  final Reference<Primitive> conditionRef;
  final int _flags;

  Primitive get value => valueRef.definition;
  Primitive get condition => conditionRef?.definition;

  static const int _USE_SELECTOR = 1 << 0;
  static const int _NULL_CHECK = 1 << 1;

  /// True if the selector name should be used in the check; otherwise
  /// `toString` will be used.
  bool get useSelector => _flags & _USE_SELECTOR != 0;

  /// True if null is the only possible input that cannot respond to [selector].
  bool get isNullCheck => _flags & _NULL_CHECK != 0;

  /// Constructor for creating checks in arbitrary configurations.
  ///
  /// Consider using one of the named constructors instead.
  ///
  /// [useSelector] and [isNullCheck] are mandatory named arguments.
  ReceiverCheck(Primitive value, this.selector, this.sourceInformation,
      {Primitive condition, bool useSelector, bool isNullCheck})
      : valueRef = new Reference<Primitive>(value),
        conditionRef = _optionalReference(condition),
        _flags =
            (useSelector ? _USE_SELECTOR : 0) | (isNullCheck ? _NULL_CHECK : 0);

  /// Simplified constructor for building null checks.
  ///
  /// Null must be the only possible input value that does not respond to
  /// [selector].
  ReceiverCheck.nullCheck(
      Primitive value, Selector selector, SourceInformation sourceInformation,
      {Primitive condition})
      : this(value, selector, sourceInformation,
            condition: condition,
            useSelector: condition != null,
            isNullCheck: true);

  /// Simplified constructor for building the general check of form:
  ///
  ///     if (condition) value.selectorName();
  ///
  ReceiverCheck.generalCheck(Primitive value, Selector selector,
      SourceInformation sourceInformation, Primitive condition)
      : this(value, selector, sourceInformation,
            condition: condition, useSelector: true, isNullCheck: false);

  bool get isSafeForElimination => false;
  bool get isSafeForReordering => false;
  bool get hasValue => true;

  accept(Visitor visitor) => visitor.visitReceiverCheck(this);

  void setParentPointers() {
    valueRef.parent = this;
    if (conditionRef != null) {
      conditionRef.parent = this;
    }
  }

  Primitive get effectiveDefinition => value.effectiveDefinition;

  String get nullCheckString => isNullCheck ? 'null-check' : 'general-check';
  String get useSelectorString => useSelector ? 'use-selector' : 'no-selector';
  String get flagString => '$nullCheckString $useSelectorString';
}

/// An "is" type test.
///
/// Returns `true` if [value] is an instance of [dartType].
///
/// [type] must not be the [Object], `dynamic` or [Null] types (though it might
/// be a type variable containing one of these types). This design is chosen
/// to simplify code generation for type tests.
class TypeTest extends Primitive {
  Reference<Primitive> valueRef;
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
  final List<Reference<Primitive>> typeArgumentRefs;

  Primitive get value => valueRef.definition;
  Primitive typeArgument(int n) => typeArgumentRefs[n].definition;
  Iterable<Primitive> get typeArguments => _dereferenceList(typeArgumentRefs);

  TypeTest(Primitive value, this.dartType, List<Primitive> typeArguments)
      : this.valueRef = new Reference<Primitive>(value),
        this.typeArgumentRefs = _referenceList(typeArguments);

  accept(Visitor visitor) => visitor.visitTypeTest(this);

  bool get hasValue => true;
  bool get isSafeForElimination => true;
  bool get isSafeForReordering => true;

  void setParentPointers() {
    valueRef.parent = this;
    _setParentsOnList(typeArgumentRefs, this);
  }
}

/// An "is" type test for a raw type, performed by testing a flag property.
///
/// Returns `true` if [interceptor] is for [dartType].
class TypeTestViaFlag extends Primitive {
  Reference<Primitive> interceptorRef;
  final DartType dartType;

  Primitive get interceptor => interceptorRef.definition;

  TypeTestViaFlag(Primitive interceptor, this.dartType)
      : this.interceptorRef = new Reference<Primitive>(interceptor);

  accept(Visitor visitor) => visitor.visitTypeTestViaFlag(this);

  bool get hasValue => true;
  bool get isSafeForElimination => true;
  bool get isSafeForReordering => true;

  void setParentPointers() {
    interceptorRef.parent = this;
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
  Reference<Primitive> valueRef;
  final DartType dartType;

  /// See the corresponding field on [TypeTest].
  final List<Reference<Primitive>> typeArgumentRefs;

  Primitive get value => valueRef.definition;
  Primitive typeArgument(int n) => typeArgumentRefs[n].definition;
  Iterable<Primitive> get typeArguments => _dereferenceList(typeArgumentRefs);

  TypeCast(Primitive value, this.dartType, List<Primitive> typeArguments)
      : this.valueRef = new Reference<Primitive>(value),
        this.typeArgumentRefs = _referenceList(typeArguments);

  accept(Visitor visitor) => visitor.visitTypeCast(this);

  bool get hasValue => true;

  void setParentPointers() {
    valueRef.parent = this;
    _setParentsOnList(typeArgumentRefs, this);
  }
}

/// Apply a built-in operator.
///
/// It must be known that the arguments have the proper types.
class ApplyBuiltinOperator extends Primitive {
  BuiltinOperator operator;
  List<Reference<Primitive>> argumentRefs;
  final SourceInformation sourceInformation;

  Primitive argument(int n) => argumentRefs[n].definition;
  Iterable<Primitive> get arguments => _dereferenceList(argumentRefs);

  ApplyBuiltinOperator(
      this.operator, List<Primitive> arguments, this.sourceInformation)
      : this.argumentRefs = _referenceList(arguments);

  accept(Visitor visitor) => visitor.visitApplyBuiltinOperator(this);

  bool get hasValue => true;
  bool get isSafeForElimination => true;
  bool get isSafeForReordering => true;

  void setParentPointers() {
    _setParentsOnList(argumentRefs, this);
  }
}

/// Apply a built-in method.
///
/// It must be known that the arguments have the proper types.
class ApplyBuiltinMethod extends Primitive {
  BuiltinMethod method;
  Reference<Primitive> receiverRef;
  List<Reference<Primitive>> argumentRefs;
  final SourceInformation sourceInformation;

  Primitive get receiver => receiverRef.definition;
  Primitive argument(int n) => argumentRefs[n].definition;
  Iterable<Primitive> get arguments => _dereferenceList(argumentRefs);

  ApplyBuiltinMethod(this.method, Primitive receiver, List<Primitive> arguments,
      this.sourceInformation)
      : this.receiverRef = new Reference<Primitive>(receiver),
        this.argumentRefs = _referenceList(arguments);

  accept(Visitor visitor) => visitor.visitApplyBuiltinMethod(this);

  bool get hasValue => true;
  bool get isSafeForElimination => false;
  bool get isSafeForReordering => false;

  void setParentPointers() {
    receiverRef.parent = this;
    _setParentsOnList(argumentRefs, this);
  }

  int get effects => getEffectsOfBuiltinMethod(method);
}

/// Gets the value from a [MutableVariable].
///
/// [MutableVariable]s can be seen as ref cells that are not first-class
/// values.  A [LetPrim] with a [GetMutable] can then be seen as:
///
///   let prim p = ![variable] in [body]
///
class GetMutable extends Primitive {
  final Reference<MutableVariable> variableRef;
  final SourceInformation sourceInformation;

  MutableVariable get variable => variableRef.definition;

  GetMutable(MutableVariable variable, {this.sourceInformation})
      : this.variableRef = new Reference<MutableVariable>(variable);

  accept(Visitor visitor) => visitor.visitGetMutable(this);

  bool get hasValue => true;
  bool get isSafeForElimination => true;
  bool get isSafeForReordering => false;

  void setParentPointers() {
    variableRef.parent = this;
  }
}

/// Assign a [MutableVariable].
///
/// [MutableVariable]s can be seen as ref cells that are not first-class
/// values.  This can be seen as a dereferencing assignment:
///
///   { [variable] := [value]; [body] }
class SetMutable extends Primitive {
  final Reference<MutableVariable> variableRef;
  final Reference<Primitive> valueRef;
  final SourceInformation sourceInformation;

  MutableVariable get variable => variableRef.definition;
  Primitive get value => valueRef.definition;

  SetMutable(MutableVariable variable, Primitive value,
      {this.sourceInformation})
      : this.variableRef = new Reference<MutableVariable>(variable),
        this.valueRef = new Reference<Primitive>(value);

  accept(Visitor visitor) => visitor.visitSetMutable(this);

  bool get hasValue => false;
  bool get isSafeForElimination => false;
  bool get isSafeForReordering => false;

  void setParentPointers() {
    variableRef.parent = this;
    valueRef.parent = this;
  }
}

/// Directly reads from a field on a given object.
///
/// The [object] must either be `null` or an object that has [field].
class GetField extends Primitive {
  final Reference<Primitive> objectRef;
  FieldElement field;
  final SourceInformation sourceInformation;

  /// True if the field never changes value.
  final bool isFinal;

  /// True if the object is known not to be null.
  // TODO(asgerf): This is a placeholder until we agree on how to track
  //               side effects.
  bool objectIsNotNull = false;

  Primitive get object => objectRef.definition;

  GetField(Primitive object, this.field,
      {this.sourceInformation, this.isFinal: false})
      : this.objectRef = new Reference<Primitive>(object);

  accept(Visitor visitor) => visitor.visitGetField(this);

  bool get hasValue => true;
  bool get isSafeForElimination => objectIsNotNull;
  bool get isSafeForReordering => false;

  toString() => 'GetField($field)';

  void setParentPointers() {
    objectRef.parent = this;
  }

  int get effects => isFinal ? 0 : Effects.dependsOnInstanceField;
}

/// Directly assigns to a field on a given object.
class SetField extends Primitive {
  final Reference<Primitive> objectRef;
  FieldElement field;
  final Reference<Primitive> valueRef;
  final SourceInformation sourceInformation;

  Primitive get object => objectRef.definition;
  Primitive get value => valueRef.definition;

  SetField(Primitive object, this.field, Primitive value,
      {this.sourceInformation})
      : this.objectRef = new Reference<Primitive>(object),
        this.valueRef = new Reference<Primitive>(value);

  accept(Visitor visitor) => visitor.visitSetField(this);

  bool get hasValue => false;
  bool get isSafeForElimination => false;
  bool get isSafeForReordering => false;

  void setParentPointers() {
    objectRef.parent = this;
    valueRef.parent = this;
  }

  int get effects => Effects.changesInstanceField;
}

/// Get the length of a string or native list.
class GetLength extends Primitive {
  final Reference<Primitive> objectRef;

  /// True if the length of the given object can never change.
  bool isFinal;

  /// True if the object is known not to be null.
  bool objectIsNotNull = false;

  Primitive get object => objectRef.definition;

  GetLength(Primitive object, {this.isFinal: false})
      : this.objectRef = new Reference<Primitive>(object);

  bool get hasValue => true;
  bool get isSafeForElimination => objectIsNotNull;
  bool get isSafeForReordering => false;

  accept(Visitor v) => v.visitGetLength(this);

  void setParentPointers() {
    objectRef.parent = this;
  }

  int get effects => isFinal ? 0 : Effects.dependsOnIndexableLength;
}

/// Read an entry from an indexable object.
///
/// [object] must be null or an indexable object, and [index] must be
/// an integer where `0 <= index < object.length`.
class GetIndex extends Primitive {
  final Reference<Primitive> objectRef;
  final Reference<Primitive> indexRef;

  /// True if the object is known not to be null.
  bool objectIsNotNull = false;

  Primitive get object => objectRef.definition;
  Primitive get index => indexRef.definition;

  GetIndex(Primitive object, Primitive index)
      : this.objectRef = new Reference<Primitive>(object),
        this.indexRef = new Reference<Primitive>(index);

  bool get hasValue => true;
  bool get isSafeForElimination => objectIsNotNull;
  bool get isSafeForReordering => false;

  accept(Visitor v) => v.visitGetIndex(this);

  void setParentPointers() {
    objectRef.parent = this;
    indexRef.parent = this;
  }

  int get effects => Effects.dependsOnIndexableContent;
}

/// Set an entry on a native list.
///
/// [object] must be null or a native list, and [index] must be an integer
/// within the bounds of the indexable object.
///
/// [SetIndex] may not be used to alter the length of a JS array.
///
/// The primitive itself has no value and may not be referenced.
class SetIndex extends Primitive {
  final Reference<Primitive> objectRef;
  final Reference<Primitive> indexRef;
  final Reference<Primitive> valueRef;

  Primitive get object => objectRef.definition;
  Primitive get index => indexRef.definition;
  Primitive get value => valueRef.definition;

  SetIndex(Primitive object, Primitive index, Primitive value)
      : this.objectRef = new Reference<Primitive>(object),
        this.indexRef = new Reference<Primitive>(index),
        this.valueRef = new Reference<Primitive>(value);

  bool get hasValue => false;
  bool get isSafeForElimination => false;
  bool get isSafeForReordering => false;

  accept(Visitor v) => v.visitSetIndex(this);

  void setParentPointers() {
    objectRef.parent = this;
    indexRef.parent = this;
    valueRef.parent = this;
  }

  int get effects => Effects.changesIndexableContent;
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

  /// True if the field never changes value.
  final bool isFinal;

  /// If reading a lazily initialized field, [witness] must refer to a node
  /// that initializes the field or always occurs after the field initializer.
  ///
  /// The value of the witness is not used.
  Reference<Primitive> witnessRef;

  Primitive get witness => witnessRef.definition;

  GetStatic(this.element, {this.isFinal: false, this.sourceInformation});

  /// Read a lazily initialized static field that is known to have been
  /// initialized by [witness] or earlier.
  GetStatic.witnessed(this.element, Primitive witness, {this.sourceInformation})
      : witnessRef = _optionalReference(witness),
        isFinal = false;

  accept(Visitor visitor) => visitor.visitGetStatic(this);

  bool get hasValue => true;
  bool get isSafeForElimination => true;
  bool get isSafeForReordering => isFinal;

  void setParentPointers() {
    if (witnessRef != null) {
      witnessRef.parent = this;
    }
  }

  int get effects => isFinal ? 0 : Effects.dependsOnStaticField;
}

/// Sets the value of a static field.
class SetStatic extends Primitive {
  final FieldElement element;
  final Reference<Primitive> valueRef;
  final SourceInformation sourceInformation;

  Primitive get value => valueRef.definition;

  SetStatic(this.element, Primitive value, [this.sourceInformation])
      : this.valueRef = new Reference<Primitive>(value);

  accept(Visitor visitor) => visitor.visitSetStatic(this);

  bool get hasValue => false;
  bool get isSafeForElimination => false;
  bool get isSafeForReordering => false;

  void setParentPointers() {
    valueRef.parent = this;
  }

  int get effects => Effects.changesStaticField;
}

/// Reads the value of a lazily initialized static field.
///
/// If the field has not yet been initialized, its initializer is evaluated
/// and assigned to the field.
class GetLazyStatic extends UnsafePrimitive {
  final FieldElement element;
  final SourceInformation sourceInformation;

  /// True if the field never changes value.
  final bool isFinal;

  GetLazyStatic(this.element, {this.isFinal: false, this.sourceInformation});

  accept(Visitor visitor) => visitor.visitGetLazyStatic(this);

  bool get hasValue => true;

  void setParentPointers() {}

  // TODO(asgerf): Track side effects of lazy field initializers.
  int get effects => Effects.all;
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
  final List<Reference<Primitive>> argumentRefs;

  /// The runtime type information structure which contains the type arguments.
  ///
  /// May be `null` to indicate that no type information is needed because the
  /// compiler determined that the type information for instances of this class
  /// is not needed at runtime.
  Reference<Primitive> typeInformationRef;

  final SourceInformation sourceInformation;

  Primitive argument(int n) => argumentRefs[n].definition;
  Iterable<Primitive> get arguments => _dereferenceList(argumentRefs);
  Primitive get typeInformation => typeInformationRef?.definition;

  CreateInstance(this.classElement, List<Primitive> arguments,
      Primitive typeInformation, this.sourceInformation)
      : this.argumentRefs = _referenceList(arguments),
        this.typeInformationRef = _optionalReference(typeInformation);

  accept(Visitor visitor) => visitor.visitCreateInstance(this);

  bool get hasValue => true;
  bool get isSafeForElimination => true;
  bool get isSafeForReordering => true;

  toString() => 'CreateInstance($classElement)';

  void setParentPointers() {
    _setParentsOnList(argumentRefs, this);
    if (typeInformationRef != null) typeInformationRef.parent = this;
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
  final Reference<Primitive> inputRef;
  final Set<ClassElement> interceptedClasses = new Set<ClassElement>();
  final SourceInformation sourceInformation;

  Primitive get input => inputRef.definition;

  Interceptor(Primitive input, this.sourceInformation)
      : this.inputRef = new Reference<Primitive>(input);

  accept(Visitor visitor) => visitor.visitInterceptor(this);

  bool get hasValue => true;
  bool get isSafeForElimination => true;
  bool get isSafeForReordering => true;

  void setParentPointers() {
    inputRef.parent = this;
  }
}

/// Create an instance of [Invocation] for use in a call to `noSuchMethod`.
class CreateInvocationMirror extends Primitive {
  final Selector selector;
  final List<Reference<Primitive>> argumentRefs;

  Primitive argument(int n) => argumentRefs[n].definition;
  Iterable<Primitive> get arguments => _dereferenceList(argumentRefs);

  CreateInvocationMirror(this.selector, List<Primitive> arguments)
      : this.argumentRefs = _referenceList(arguments);

  accept(Visitor visitor) => visitor.visitCreateInvocationMirror(this);

  bool get hasValue => true;
  bool get isSafeForElimination => true;
  bool get isSafeForReordering => true;

  void setParentPointers() {
    _setParentsOnList(argumentRefs, this);
  }
}

class ForeignCode extends UnsafePrimitive {
  final js.Template codeTemplate;
  final TypeMask storedType;
  final List<Reference<Primitive>> argumentRefs;
  final native.NativeBehavior nativeBehavior;
  final SourceInformation sourceInformation;
  final FunctionElement dependency;

  Primitive argument(int n) => argumentRefs[n].definition;
  Iterable<Primitive> get arguments => _dereferenceList(argumentRefs);

  ForeignCode(this.codeTemplate, this.storedType, List<Primitive> arguments,
      this.nativeBehavior, this.sourceInformation,
      {this.dependency})
      : this.argumentRefs = _referenceList(arguments) {
    effects = Effects.from(nativeBehavior.sideEffects);
  }

  accept(Visitor visitor) => visitor.visitForeignCode(this);

  bool get hasValue => true;

  void setParentPointers() {
    _setParentsOnList(argumentRefs, this);
  }

  bool isNullGuardOnNullFirstArgument() {
    if (argumentRefs.length < 1) return false;
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
  final List<Reference<Primitive>> valueRefs;

  /// If non-null, this is an allocation site-specific type for the list
  /// created here.
  TypeMask allocationSiteType;

  Primitive value(int n) => valueRefs[n].definition;
  Iterable<Primitive> get values => _dereferenceList(valueRefs);

  LiteralList(this.dartType, List<Primitive> values, {this.allocationSiteType})
      : this.valueRefs = _referenceList(values);

  accept(Visitor visitor) => visitor.visitLiteralList(this);

  bool get hasValue => true;
  bool get isSafeForElimination => true;
  bool get isSafeForReordering => true;

  void setParentPointers() {
    _setParentsOnList(valueRefs, this);
  }
}

/// Converts the internal representation of a type to a Dart object of type
/// [Type].
class ReifyRuntimeType extends Primitive {
  /// Reference to the internal representation of a type (as produced, for
  /// example, by [ReadTypeVariable]).
  final Reference<Primitive> valueRef;

  final SourceInformation sourceInformation;

  Primitive get value => valueRef.definition;

  ReifyRuntimeType(Primitive value, this.sourceInformation)
      : this.valueRef = new Reference<Primitive>(value);

  @override
  accept(Visitor visitor) => visitor.visitReifyRuntimeType(this);

  bool get hasValue => true;
  bool get isSafeForElimination => true;
  bool get isSafeForReordering => true;

  void setParentPointers() {
    valueRef.parent = this;
  }
}

/// Read the value the type variable [variable] from the target object.
///
/// The resulting value is an internal representation (and not neccessarily a
/// Dart object), and must be reified by [ReifyRuntimeType], if it should be
/// used as a Dart value.
class ReadTypeVariable extends Primitive {
  final TypeVariableType variable;
  final Reference<Primitive> targetRef;
  final SourceInformation sourceInformation;

  Primitive get target => targetRef.definition;

  ReadTypeVariable(this.variable, Primitive target, this.sourceInformation)
      : this.targetRef = new Reference<Primitive>(target);

  @override
  accept(Visitor visitor) => visitor.visitReadTypeVariable(this);

  bool get hasValue => true;
  bool get isSafeForElimination => true;
  bool get isSafeForReordering => true;

  void setParentPointers() {
    targetRef.parent = this;
  }
}

enum TypeExpressionKind { COMPLETE, INSTANCE }

/// Constructs a representation of a closed or ground-term type (that is, a type
/// without type variables).
///
/// There are two forms:
///
/// - COMPLETE: A complete form that is self contained, used for the values of
///   type parameters and non-raw is-checks.
///
/// - INSTANCE: A headless flat form for representing the sequence of values of
///   the type parameters of an instance of a generic type.
///
/// The COMPLETE form value is constructed from [dartType] by replacing the type
/// variables with consecutive values from [arguments], in the order generated
/// by [DartType.forEachTypeVariable].  The type variables in [dartType] are
/// treated as 'holes' in the term, which means that it must be ensured at
/// construction, that duplicate occurences of a type variable in [dartType]
/// are assigned the same value.
///
/// The INSTANCE form is constructed as a list of [arguments]. This is the same
/// as the COMPLETE form for the 'thisType', except the root term's type is
/// missing; this is implicit as the raw type of instance.  The [dartType] of
/// the INSTANCE form must be the thisType of some class.
///
/// While we would like to remove the constrains on the INSTANCE form, we can
/// get by with a tree of TypeExpressions.  Consider:
///
///     class Foo<T> {
///       ... new Set<List<T>>()
///     }
///     class Set<E1> {
///       factory Set() => new _LinkedHashSet<E1>();
///     }
///     class List<E2> { ... }
///     class _LinkedHashSet<E3> { ... }
///
/// After inlining the factory constructor for `Set<E1>`, the CreateInstance
/// should have type `_LinkedHashSet<List<T>>` and the TypeExpression should be
/// a tree:
///
///    CreateInstance(dartType: _LinkedHashSet<List<T>>,
///        [], // No arguments
///        TypeExpression(INSTANCE,
///            dartType: _LinkedHashSet<E3>, // _LinkedHashSet's thisType
///            TypeExpression(COMPLETE,  // E3 = List<T>
///                dartType: List<E2>,
///                ReadTypeVariable(this, T)))) // E2 = T
//
// TODO(sra): The INSTANCE form requires the actual instance for full
// interpretation. I want to move to a representation where the INSTANCE form is
// also a complete form (possibly the same).
class TypeExpression extends Primitive {
  final TypeExpressionKind kind;
  final DartType dartType;
  final List<Reference<Primitive>> argumentRefs;

  Primitive argument(int n) => argumentRefs[n].definition;
  Iterable<Primitive> get arguments => _dereferenceList(argumentRefs);

  TypeExpression(this.kind, this.dartType, List<Primitive> arguments)
      : this.argumentRefs = _referenceList(arguments) {
    assert(kind == TypeExpressionKind.INSTANCE
        ? dartType == (dartType.element as ClassElement).thisType
        : true);
  }

  @override
  accept(Visitor visitor) {
    return visitor.visitTypeExpression(this);
  }

  bool get hasValue => true;
  bool get isSafeForElimination => true;
  bool get isSafeForReordering => true;

  void setParentPointers() {
    _setParentsOnList(argumentRefs, this);
  }

  String get kindAsString {
    switch (kind) {
      case TypeExpressionKind.COMPLETE:
        return 'COMPLETE';
      case TypeExpressionKind.INSTANCE:
        return 'INSTANCE';
    }
  }
}

class Await extends UnsafePrimitive {
  final Reference<Primitive> inputRef;

  Primitive get input => inputRef.definition;

  Await(Primitive input) : this.inputRef = new Reference<Primitive>(input);

  @override
  accept(Visitor visitor) {
    return visitor.visitAwait(this);
  }

  bool get hasValue => true;

  void setParentPointers() {
    inputRef.parent = this;
  }
}

class Yield extends UnsafePrimitive {
  final Reference<Primitive> inputRef;
  final bool hasStar;

  Primitive get input => inputRef.definition;

  Yield(Primitive input, this.hasStar)
      : this.inputRef = new Reference<Primitive>(input);

  @override
  accept(Visitor visitor) {
    return visitor.visitYield(this);
  }

  bool get hasValue => true;

  void setParentPointers() {
    inputRef.parent = this;
  }
}

// ---------------------------------------------------------------------------
//                            EXPRESSIONS
// ---------------------------------------------------------------------------

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
  final Reference<Primitive> valueRef;
  Expression body;

  Primitive get value => valueRef.definition;

  LetMutable(this.variable, Primitive value)
      : this.valueRef = new Reference<Primitive>(value);

  Expression plug(Expression expr) {
    return body = expr;
  }

  accept(BlockVisitor visitor) => visitor.visitLetMutable(this);

  void setParentPointers() {
    variable.parent = this;
    valueRef.parent = this;
    if (body != null) body.parent = this;
  }
}

/// Throw a value.
///
/// Throw is an expression, i.e., it always occurs in tail position with
/// respect to a body or expression.
class Throw extends TailExpression {
  Reference<Primitive> valueRef;

  Primitive get value => valueRef.definition;

  Throw(Primitive value) : valueRef = new Reference<Primitive>(value);

  accept(BlockVisitor visitor) => visitor.visitThrow(this);

  void setParentPointers() {
    valueRef.parent = this;
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

/// Invoke a continuation in tail position.
class InvokeContinuation extends TailExpression {
  Reference<Continuation> continuationRef;
  List<Reference<Primitive>> argumentRefs;
  SourceInformation sourceInformation;

  Continuation get continuation => continuationRef.definition;
  Primitive argument(int n) => argumentRefs[n].definition;
  Iterable<Primitive> get arguments => _dereferenceList(argumentRefs);

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
      : continuationRef = new Reference<Continuation>(cont),
        argumentRefs = _referenceList(args) {
    assert(cont.parameters == null || cont.parameters.length == args.length);
    if (isRecursive) cont.isRecursive = true;
  }

  /// A continuation invocation whose target and arguments will be filled
  /// in later.
  ///
  /// Used as a placeholder for a jump whose target is not yet created
  /// (e.g., in the translation of break and continue).
  InvokeContinuation.uninitialized(
      {this.isRecursive: false, this.isEscapingTry: false})
      : continuationRef = null,
        argumentRefs = null,
        sourceInformation = null;

  accept(BlockVisitor visitor) => visitor.visitInvokeContinuation(this);

  void setParentPointers() {
    if (continuationRef != null) continuationRef.parent = this;
    if (argumentRefs != null) _setParentsOnList(argumentRefs, this);
  }
}

/// Choose between a pair of continuations based on a condition value.
///
/// The two continuations must not declare any parameters.
class Branch extends TailExpression {
  final Reference<Primitive> conditionRef;
  final Reference<Continuation> trueContinuationRef;
  final Reference<Continuation> falseContinuationRef;
  final SourceInformation sourceInformation;

  Primitive get condition => conditionRef.definition;
  Continuation get trueContinuation => trueContinuationRef.definition;
  Continuation get falseContinuation => falseContinuationRef.definition;

  /// If true, only the value `true` satisfies the condition. Otherwise, any
  /// truthy value satisfies the check.
  ///
  /// Non-strict checks are preferable when the condition is known to be a
  /// boolean.
  bool isStrictCheck;

  Branch(Primitive condition, Continuation trueCont, Continuation falseCont,
      this.sourceInformation,
      {bool strict})
      : this.conditionRef = new Reference<Primitive>(condition),
        trueContinuationRef = new Reference<Continuation>(trueCont),
        falseContinuationRef = new Reference<Continuation>(falseCont),
        isStrictCheck = strict {
    assert(strict != null);
  }

  Branch.strict(Primitive condition, Continuation trueCont,
      Continuation falseCont, SourceInformation sourceInformation)
      : this(condition, trueCont, falseCont, sourceInformation, strict: true);

  Branch.loose(Primitive condition, Continuation trueCont,
      Continuation falseCont, SourceInformation sourceInformation)
      : this(condition, trueCont, falseCont, sourceInformation, strict: false);

  accept(BlockVisitor visitor) => visitor.visitBranch(this);

  void setParentPointers() {
    conditionRef.parent = this;
    trueContinuationRef.parent = this;
    falseContinuationRef.parent = this;
  }
}

// ----------------------------------------------------------------------------
//                            UTILITY STUFF
// ----------------------------------------------------------------------------

Reference<Primitive> _reference(Primitive definition) {
  return new Reference<Primitive>(definition);
}

Reference<Primitive> _optionalReference(Primitive definition) {
  return definition == null ? null : new Reference<Primitive>(definition);
}

List<Reference<Primitive>> _referenceList(Iterable<Primitive> definitions) {
  return definitions.map((e) => new Reference<Primitive>(e)).toList();
}

Iterable<Primitive> _dereferenceList(List<Reference<Primitive>> references) {
  return references.map((ref) => ref.definition);
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

// ----------------------------------------------------------------------------
//                                 VISITORS
// ----------------------------------------------------------------------------

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
  /// Traversal continues at the original success for the current node, so:
  /// - The current node can safely be removed.
  /// - Nodes inserted immediately below the current node will not be seen.
  /// - The body of the current node should not be moved/removed, as traversal
  ///   would otherwise continue into an orphaned or relocated node.
  static void traverseInPreOrder(FunctionDefinition root, BlockVisitor v) {
    List<Continuation> stack = <Continuation>[];
    void walkBlock(InteriorNode block) {
      v.visit(block);
      Expression node = block.body;
      while (node != null) {
        if (node is LetCont) {
          stack.addAll(node.continuations);
        } else if (node is LetHandler) {
          stack.add(node.handler);
        }
        Expression next = node.next;
        v.visit(node);
        node = next;
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
  T visitReceiverCheck(ReceiverCheck node);
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
    if (node.interceptorParameter != null) visit(node.interceptorParameter);
    if (node.receiverParameter != null) visit(node.receiverParameter);
    node.parameters.forEach(visit);
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
    processReference(node.valueRef);
    visit(node.body);
  }

  processInvokeStatic(InvokeStatic node) {}
  visitInvokeStatic(InvokeStatic node) {
    processInvokeStatic(node);
    node.argumentRefs.forEach(processReference);
  }

  processInvokeContinuation(InvokeContinuation node) {}
  visitInvokeContinuation(InvokeContinuation node) {
    processInvokeContinuation(node);
    processReference(node.continuationRef);
    node.argumentRefs.forEach(processReference);
  }

  processInvokeMethod(InvokeMethod node) {}
  visitInvokeMethod(InvokeMethod node) {
    processInvokeMethod(node);
    if (node.interceptorRef != null) {
      processReference(node.interceptorRef);
    }
    processReference(node.receiverRef);
    node.argumentRefs.forEach(processReference);
  }

  processInvokeMethodDirectly(InvokeMethodDirectly node) {}
  visitInvokeMethodDirectly(InvokeMethodDirectly node) {
    processInvokeMethodDirectly(node);
    if (node.interceptorRef != null) {
      processReference(node.interceptorRef);
    }
    processReference(node.receiverRef);
    node.argumentRefs.forEach(processReference);
  }

  processInvokeConstructor(InvokeConstructor node) {}
  visitInvokeConstructor(InvokeConstructor node) {
    processInvokeConstructor(node);
    node.argumentRefs.forEach(processReference);
  }

  processThrow(Throw node) {}
  visitThrow(Throw node) {
    processThrow(node);
    processReference(node.valueRef);
  }

  processRethrow(Rethrow node) {}
  visitRethrow(Rethrow node) {
    processRethrow(node);
  }

  processBranch(Branch node) {}
  visitBranch(Branch node) {
    processBranch(node);
    processReference(node.trueContinuationRef);
    processReference(node.falseContinuationRef);
    processReference(node.conditionRef);
  }

  processTypeCast(TypeCast node) {}
  visitTypeCast(TypeCast node) {
    processTypeCast(node);
    processReference(node.valueRef);
    node.typeArgumentRefs.forEach(processReference);
  }

  processTypeTest(TypeTest node) {}
  visitTypeTest(TypeTest node) {
    processTypeTest(node);
    processReference(node.valueRef);
    node.typeArgumentRefs.forEach(processReference);
  }

  processTypeTestViaFlag(TypeTestViaFlag node) {}
  visitTypeTestViaFlag(TypeTestViaFlag node) {
    processTypeTestViaFlag(node);
    processReference(node.interceptorRef);
  }

  processSetMutable(SetMutable node) {}
  visitSetMutable(SetMutable node) {
    processSetMutable(node);
    processReference(node.variableRef);
    processReference(node.valueRef);
  }

  processGetLazyStatic(GetLazyStatic node) {}
  visitGetLazyStatic(GetLazyStatic node) {
    processGetLazyStatic(node);
  }

  processLiteralList(LiteralList node) {}
  visitLiteralList(LiteralList node) {
    processLiteralList(node);
    node.valueRefs.forEach(processReference);
  }

  processConstant(Constant node) {}
  visitConstant(Constant node) {
    processConstant(node);
  }

  processMutableVariable(node) {}
  visitMutableVariable(MutableVariable node) {
    processMutableVariable(node);
  }

  processGetMutable(GetMutable node) {}
  visitGetMutable(GetMutable node) {
    processGetMutable(node);
    processReference(node.variableRef);
  }

  processParameter(Parameter node) {}
  visitParameter(Parameter node) {
    processParameter(node);
  }

  processInterceptor(Interceptor node) {}
  visitInterceptor(Interceptor node) {
    processInterceptor(node);
    processReference(node.inputRef);
  }

  processCreateInstance(CreateInstance node) {}
  visitCreateInstance(CreateInstance node) {
    processCreateInstance(node);
    node.argumentRefs.forEach(processReference);
    if (node.typeInformationRef != null) {
      processReference(node.typeInformationRef);
    }
  }

  processSetField(SetField node) {}
  visitSetField(SetField node) {
    processSetField(node);
    processReference(node.objectRef);
    processReference(node.valueRef);
  }

  processGetField(GetField node) {}
  visitGetField(GetField node) {
    processGetField(node);
    processReference(node.objectRef);
  }

  processGetStatic(GetStatic node) {}
  visitGetStatic(GetStatic node) {
    processGetStatic(node);
    if (node.witnessRef != null) {
      processReference(node.witnessRef);
    }
  }

  processSetStatic(SetStatic node) {}
  visitSetStatic(SetStatic node) {
    processSetStatic(node);
    processReference(node.valueRef);
  }

  processCreateBox(CreateBox node) {}
  visitCreateBox(CreateBox node) {
    processCreateBox(node);
  }

  processReifyRuntimeType(ReifyRuntimeType node) {}
  visitReifyRuntimeType(ReifyRuntimeType node) {
    processReifyRuntimeType(node);
    processReference(node.valueRef);
  }

  processReadTypeVariable(ReadTypeVariable node) {}
  visitReadTypeVariable(ReadTypeVariable node) {
    processReadTypeVariable(node);
    processReference(node.targetRef);
  }

  processTypeExpression(TypeExpression node) {}
  visitTypeExpression(TypeExpression node) {
    processTypeExpression(node);
    node.argumentRefs.forEach(processReference);
  }

  processCreateInvocationMirror(CreateInvocationMirror node) {}
  visitCreateInvocationMirror(CreateInvocationMirror node) {
    processCreateInvocationMirror(node);
    node.argumentRefs.forEach(processReference);
  }

  processApplyBuiltinOperator(ApplyBuiltinOperator node) {}
  visitApplyBuiltinOperator(ApplyBuiltinOperator node) {
    processApplyBuiltinOperator(node);
    node.argumentRefs.forEach(processReference);
  }

  processApplyBuiltinMethod(ApplyBuiltinMethod node) {}
  visitApplyBuiltinMethod(ApplyBuiltinMethod node) {
    processApplyBuiltinMethod(node);
    processReference(node.receiverRef);
    node.argumentRefs.forEach(processReference);
  }

  processForeignCode(ForeignCode node) {}
  visitForeignCode(ForeignCode node) {
    processForeignCode(node);
    node.argumentRefs.forEach(processReference);
  }

  processUnreachable(Unreachable node) {}
  visitUnreachable(Unreachable node) {
    processUnreachable(node);
  }

  processAwait(Await node) {}
  visitAwait(Await node) {
    processAwait(node);
    processReference(node.inputRef);
  }

  processYield(Yield node) {}
  visitYield(Yield node) {
    processYield(node);
    processReference(node.inputRef);
  }

  processGetLength(GetLength node) {}
  visitGetLength(GetLength node) {
    processGetLength(node);
    processReference(node.objectRef);
  }

  processGetIndex(GetIndex node) {}
  visitGetIndex(GetIndex node) {
    processGetIndex(node);
    processReference(node.objectRef);
    processReference(node.indexRef);
  }

  processSetIndex(SetIndex node) {}
  visitSetIndex(SetIndex node) {
    processSetIndex(node);
    processReference(node.objectRef);
    processReference(node.indexRef);
    processReference(node.valueRef);
  }

  processRefinement(Refinement node) {}
  visitRefinement(Refinement node) {
    processRefinement(node);
    processReference(node.value);
  }

  processBoundsCheck(BoundsCheck node) {}
  visitBoundsCheck(BoundsCheck node) {
    processBoundsCheck(node);
    processReference(node.objectRef);
    if (node.indexRef != null) {
      processReference(node.indexRef);
    }
    if (node.lengthRef != null) {
      processReference(node.lengthRef);
    }
  }

  processNullCheck(ReceiverCheck node) {}
  visitReceiverCheck(ReceiverCheck node) {
    processNullCheck(node);
    processReference(node.valueRef);
    if (node.conditionRef != null) {
      processReference(node.conditionRef);
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
    if (node.interceptorParameter != null) visit(node.interceptorParameter);
    if (node.receiverParameter != null) visit(node.receiverParameter);
    node.parameters.forEach(visit);
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
    processReference(node.valueRef);
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

  /// Get the copy of a [Reference]'s definition from the map.
  Definition getCopyOrNull(Reference reference) =>
      reference == null ? null : getCopy(reference);

  /// Map a list of [Reference]s to the list of their definition's copies.
  List<Definition> getList(List<Reference> list) => list.map(getCopy).toList();

  /// Copy a non-[Continuation] [Definition].
  Definition copy(Definition node) {
    assert(node is! Continuation);
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
    return new InvokeStatic(node.target, node.selector,
        getList(node.argumentRefs), node.sourceInformation);
  }

  Definition visitInvokeMethod(InvokeMethod node) {
    return new InvokeMethod(getCopy(node.receiverRef), node.selector, node.mask,
        getList(node.argumentRefs),
        sourceInformation: node.sourceInformation,
        callingConvention: node.callingConvention,
        interceptor: getCopyOrNull(node.interceptorRef));
  }

  Definition visitInvokeMethodDirectly(InvokeMethodDirectly node) {
    return new InvokeMethodDirectly(getCopy(node.receiverRef), node.target,
        node.selector, getList(node.argumentRefs), node.sourceInformation,
        interceptor: getCopyOrNull(node.interceptorRef));
  }

  Definition visitInvokeConstructor(InvokeConstructor node) {
    return new InvokeConstructor(
        node.dartType,
        node.target,
        node.selector,
        getList(node.argumentRefs),
        node.sourceInformation)..allocationSiteType = node.allocationSiteType;
  }

  Definition visitTypeCast(TypeCast node) {
    return new TypeCast(
        getCopy(node.valueRef), node.dartType, getList(node.typeArgumentRefs));
  }

  Definition visitSetMutable(SetMutable node) {
    return new SetMutable(getCopy(node.variableRef), getCopy(node.valueRef),
        sourceInformation: node.sourceInformation);
  }

  Definition visitSetStatic(SetStatic node) {
    return new SetStatic(
        node.element, getCopy(node.valueRef), node.sourceInformation);
  }

  Definition visitSetField(SetField node) {
    return new SetField(
        getCopy(node.objectRef), node.field, getCopy(node.valueRef),
        sourceInformation: node.sourceInformation);
  }

  Definition visitGetLazyStatic(GetLazyStatic node) {
    return new GetLazyStatic(node.element,
        isFinal: node.isFinal, sourceInformation: node.sourceInformation);
  }

  Definition visitAwait(Await node) {
    return new Await(getCopy(node.inputRef));
  }

  Definition visitYield(Yield node) {
    return new Yield(getCopy(node.inputRef), node.hasStar);
  }

  Definition visitLiteralList(LiteralList node) {
    return new LiteralList(node.dartType, getList(node.valueRefs))
      ..allocationSiteType = node.allocationSiteType;
  }

  Definition visitConstant(Constant node) {
    return new Constant(node.value, sourceInformation: node.sourceInformation);
  }

  Definition visitGetMutable(GetMutable node) {
    return new GetMutable(getCopy(node.variableRef),
        sourceInformation: node.sourceInformation);
  }

  Definition visitParameter(Parameter node) {
    return new Parameter(node.hint);
  }

  Definition visitMutableVariable(MutableVariable node) {
    return new MutableVariable(node.hint);
  }

  Definition visitGetStatic(GetStatic node) {
    if (node.witnessRef != null) {
      return new GetStatic.witnessed(node.element, getCopy(node.witnessRef),
          sourceInformation: node.sourceInformation);
    } else {
      return new GetStatic(node.element,
          isFinal: node.isFinal, sourceInformation: node.sourceInformation);
    }
  }

  Definition visitInterceptor(Interceptor node) {
    return new Interceptor(getCopy(node.inputRef), node.sourceInformation)
      ..interceptedClasses.addAll(node.interceptedClasses);
  }

  Definition visitCreateInstance(CreateInstance node) {
    return new CreateInstance(node.classElement, getList(node.argumentRefs),
        getCopyOrNull(node.typeInformationRef), node.sourceInformation);
  }

  Definition visitGetField(GetField node) {
    return new GetField(getCopy(node.objectRef), node.field,
        isFinal: node.isFinal);
  }

  Definition visitCreateBox(CreateBox node) {
    return new CreateBox();
  }

  Definition visitReifyRuntimeType(ReifyRuntimeType node) {
    return new ReifyRuntimeType(getCopy(node.valueRef), node.sourceInformation);
  }

  Definition visitReadTypeVariable(ReadTypeVariable node) {
    return new ReadTypeVariable(
        node.variable, getCopy(node.targetRef), node.sourceInformation);
  }

  Definition visitTypeExpression(TypeExpression node) {
    return new TypeExpression(
        node.kind, node.dartType, getList(node.argumentRefs));
  }

  Definition visitCreateInvocationMirror(CreateInvocationMirror node) {
    return new CreateInvocationMirror(
        node.selector, getList(node.argumentRefs));
  }

  Definition visitTypeTest(TypeTest node) {
    return new TypeTest(
        getCopy(node.valueRef), node.dartType, getList(node.typeArgumentRefs));
  }

  Definition visitTypeTestViaFlag(TypeTestViaFlag node) {
    return new TypeTestViaFlag(getCopy(node.interceptorRef), node.dartType);
  }

  Definition visitApplyBuiltinOperator(ApplyBuiltinOperator node) {
    return new ApplyBuiltinOperator(
        node.operator, getList(node.argumentRefs), node.sourceInformation);
  }

  Definition visitApplyBuiltinMethod(ApplyBuiltinMethod node) {
    return new ApplyBuiltinMethod(node.method, getCopy(node.receiverRef),
        getList(node.argumentRefs), node.sourceInformation);
  }

  Definition visitGetLength(GetLength node) {
    return new GetLength(getCopy(node.objectRef), isFinal: node.isFinal);
  }

  Definition visitGetIndex(GetIndex node) {
    return new GetIndex(getCopy(node.objectRef), getCopy(node.indexRef));
  }

  Definition visitSetIndex(SetIndex node) {
    return new SetIndex(getCopy(node.objectRef), getCopy(node.indexRef),
        getCopy(node.valueRef));
  }

  Definition visitRefinement(Refinement node) {
    return new Refinement(getCopy(node.value), node.refineType);
  }

  Definition visitBoundsCheck(BoundsCheck node) {
    if (node.hasNoChecks) {
      return new BoundsCheck.noCheck(
          getCopy(node.objectRef), node.sourceInformation);
    } else {
      return new BoundsCheck(getCopy(node.objectRef), getCopy(node.indexRef),
          getCopyOrNull(node.lengthRef), node.checks, node.sourceInformation);
    }
  }

  Definition visitReceiverCheck(ReceiverCheck node) {
    return new ReceiverCheck(
        getCopy(node.valueRef), node.selector, node.sourceInformation,
        condition: getCopyOrNull(node.conditionRef),
        useSelector: node.useSelector,
        isNullCheck: node.isNullCheck);
  }

  Definition visitForeignCode(ForeignCode node) {
    return new ForeignCode(node.codeTemplate, node.storedType,
        getList(node.argumentRefs), node.nativeBehavior, node.sourceInformation,
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
      body.parent = interior;
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
      Continuation contCopy = _copies[cont];
      contCopy.body = _first;
      _first.parent = contCopy;
      _first = savedFirst;
      _current = null;
    });
  }

  FunctionDefinition copy(FunctionDefinition node) {
    assert(_first == null && _current == null);
    _first = _current = null;
    // Definitions are copied where they are bound, before processing
    // expressions in the scope of their binding.
    Parameter thisParameter = node.receiverParameter == null
        ? null
        : _definitions.copy(node.receiverParameter);
    Parameter interceptorParameter = node.interceptorParameter == null
        ? null
        : _definitions.copy(node.interceptorParameter);
    List<Parameter> parameters =
        node.parameters.map(_definitions.copy).toList();
    // Though the return continuation's parameter does not have any uses,
    // we still make a proper copy to ensure that hints, type, etc. are
    // copied.
    Parameter returnParameter =
        _definitions.copy(node.returnContinuation.parameters.first);
    Continuation returnContinuation =
        _copies[node.returnContinuation] = new Continuation([returnParameter]);

    visit(node.body);
    FunctionDefinition copy = new FunctionDefinition(
        node.element, thisParameter, parameters, returnContinuation, _first,
        interceptorParameter: interceptorParameter,
        sourceInformation: node.sourceInformation);
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
    Continuation handler = _copies[node.handler] = new Continuation(
        node.handler.parameters.map(_definitions.copy).toList());
    plug(new LetHandler(handler, null));
    return node.body;
  }

  Expression traverseLetPrim(LetPrim node) {
    plug(new LetPrim(_definitions.copy(node.primitive)));
    return node.body;
  }

  Expression traverseLetMutable(LetMutable node) {
    plug(new LetMutable(
        _definitions.copy(node.variable), _definitions.getCopy(node.valueRef)));
    return node.body;
  }

  // Tail expressions do not have references, so we do not need to map them
  // to their copies.
  visitInvokeContinuation(InvokeContinuation node) {
    plug(new InvokeContinuation(
        _copies[node.continuation], _definitions.getList(node.argumentRefs),
        isRecursive: node.isRecursive,
        isEscapingTry: node.isEscapingTry,
        sourceInformation: node.sourceInformation));
  }

  visitThrow(Throw node) {
    plug(new Throw(_definitions.getCopy(node.valueRef)));
  }

  visitRethrow(Rethrow node) {
    plug(new Rethrow());
  }

  visitBranch(Branch node) {
    plug(new Branch.loose(
        _definitions.getCopy(node.conditionRef),
        _copies[node.trueContinuation],
        _copies[node.falseContinuation],
        node.sourceInformation)..isStrictCheck = node.isStrictCheck);
  }

  visitUnreachable(Unreachable node) {
    plug(new Unreachable());
  }
}
