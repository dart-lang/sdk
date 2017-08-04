// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library compiler.src.inferrer.type_graph_nodes;

import 'dart:collection' show IterableBase;

import '../common.dart';
import '../common/names.dart' show Identifiers;
import '../compiler.dart' show Compiler;
import '../constants/values.dart';
import '../elements/elements.dart'
    show ConstructorElement, LocalElement, MemberElement;
import '../elements/entities.dart';
import '../elements/types.dart';
import '../tree/tree.dart' as ast show ForIn, Node, Send, SendSet;
import '../types/masks.dart'
    show
        CommonMasks,
        ContainerTypeMask,
        DictionaryTypeMask,
        MapTypeMask,
        TypeMask,
        ValueTypeMask;
import '../universe/selector.dart' show Selector;
import '../util/util.dart' show ImmutableEmptySet, Setlet;
import '../world.dart' show ClosedWorld;
import 'debug.dart' as debug;
import 'locals_handler.dart' show ArgumentsTypes;
import 'inferrer_engine.dart';
import 'type_system.dart';

/**
 * Common class for all nodes in the graph. The current nodes are:
 *
 * - Concrete types
 * - Elements
 * - Call sites
 * - Narrowing instructions
 * - Phi instructions
 * - Containers (for lists)
 * - Type of the element in a container
 *
 * A node has a set of assignments and users. Assignments are used to
 * compute the type of the node ([TypeInformation.computeType]). Users are
 * added to the inferrer's work queue when the type of the node
 * changes.
 */
abstract class TypeInformation {
  Set<TypeInformation> users;
  var /* List|ParameterAssignments */ _assignments;

  /// The type the inferrer has found for this [TypeInformation].
  /// Initially empty.
  TypeMask type = const TypeMask.nonNullEmpty();

  /// The graph node of the member this [TypeInformation] node belongs to.
  final MemberTypeInformation context;

  /// The element this [TypeInformation] node belongs to.
  MemberEntity get contextMember => context == null ? null : context.member;

  Iterable<TypeInformation> get assignments => _assignments;

  /// We abandon inference in certain cases (complex cyclic flow, native
  /// behaviours, etc.). In some case, we might resume inference in the
  /// closure tracer, which is handled by checking whether [assignments] has
  /// been set to [STOP_TRACKING_ASSIGNMENTS_MARKER].
  bool abandonInferencing = false;
  bool get mightResume =>
      !identical(assignments, STOP_TRACKING_ASSIGNMENTS_MARKER);

  /// Number of times this [TypeInformation] has changed type.
  int refineCount = 0;

  /// Whether this [TypeInformation] is currently in the inferrer's
  /// work queue.
  bool inQueue = false;

  /// Used to disable enqueueing of type informations where we know that their
  /// type will not change for other reasons than being stable. For example,
  /// if inference is disabled for a type and it is hardwired to dynamic, this
  /// is set to true to spare recomputing dynamic again and again. Changing this
  /// to false should never change inference outcome, just make is slower.
  bool doNotEnqueue = false;

  /// Whether this [TypeInformation] has a stable [type] that will not
  /// change.
  bool isStable = false;

  // TypeInformations are unique. Store an arbitrary identity hash code.
  static int _staticHashCode = 0;
  final int hashCode = _staticHashCode = (_staticHashCode + 1).toUnsigned(30);

  bool get isConcrete => false;

  TypeInformation(this.context)
      : _assignments = <TypeInformation>[],
        users = new Setlet<TypeInformation>();

  TypeInformation.noAssignments(this.context)
      : _assignments = const <TypeInformation>[],
        users = new Setlet<TypeInformation>();

  TypeInformation.untracked()
      : _assignments = const <TypeInformation>[],
        users = const ImmutableEmptySet(),
        context = null;

  TypeInformation.withAssignments(this.context, this._assignments)
      : users = new Setlet<TypeInformation>();

  void addUser(TypeInformation user) {
    assert(!user.isConcrete);
    users.add(user);
  }

  void addUsersOf(TypeInformation other) {
    users.addAll(other.users);
  }

  void removeUser(TypeInformation user) {
    assert(!user.isConcrete);
    users.remove(user);
  }

  // The below is not a compile time constant to make it differentiable
  // from other empty lists of [TypeInformation].
  static final STOP_TRACKING_ASSIGNMENTS_MARKER = new List<TypeInformation>(0);

  bool areAssignmentsTracked() {
    return assignments != STOP_TRACKING_ASSIGNMENTS_MARKER;
  }

  void addAssignment(TypeInformation assignment) {
    // Cheap one-level cycle detection.
    if (assignment == this) return;
    if (areAssignmentsTracked()) {
      _assignments.add(assignment);
    }
    // Even if we abandon inferencing on this [TypeInformation] we
    // need to collect the users, so that phases that track where
    // elements flow in still work.
    assignment.addUser(this);
  }

  void removeAssignment(TypeInformation assignment) {
    if (!abandonInferencing || mightResume) {
      _assignments.remove(assignment);
    }
    // We can have multiple assignments of the same [TypeInformation].
    if (!assignments.contains(assignment)) {
      assignment.removeUser(this);
    }
  }

  TypeMask refine(InferrerEngine inferrer) {
    return abandonInferencing ? safeType(inferrer) : computeType(inferrer);
  }

  /**
   * Computes a new type for this [TypeInformation] node depending on its
   * potentially updated inputs.
   */
  TypeMask computeType(InferrerEngine inferrer);

  /**
   * Returns an approximation for this [TypeInformation] node that is always
   * safe to use. Used when abandoning inference on a node.
   */
  TypeMask safeType(InferrerEngine inferrer) {
    return inferrer.types.dynamicType.type;
  }

  void giveUp(InferrerEngine inferrer, {bool clearAssignments: true}) {
    abandonInferencing = true;
    // Do not remove [this] as a user of nodes in [assignments],
    // because our tracing analysis could be interested in tracing
    // this node.
    if (clearAssignments) _assignments = STOP_TRACKING_ASSIGNMENTS_MARKER;
    // Do not remove users because our tracing analysis could be
    // interested in tracing the users of this node.
  }

  void clear() {
    _assignments = STOP_TRACKING_ASSIGNMENTS_MARKER;
    users = const ImmutableEmptySet();
  }

  /// Reset the analysis of this node by making its type empty.

  bool reset(InferrerEngine inferrer) {
    if (abandonInferencing) return false;
    type = const TypeMask.nonNullEmpty();
    refineCount = 0;
    return true;
  }

  accept(TypeInformationVisitor visitor);

  /// The [Element] where this [TypeInformation] was created. May be `null`
  /// for some [TypeInformation] nodes, where we do not need to store
  /// the information.
  MemberEntity get owner => (context != null) ? context.member : null;

  /// Returns whether the type cannot change after it has been
  /// inferred.
  bool hasStableType(InferrerEngine inferrer) {
    return !mightResume && assignments.every((e) => e.isStable);
  }

  void removeAndClearReferences(InferrerEngine inferrer) {
    assignments.forEach((info) {
      info.removeUser(this);
    });
  }

  void stabilize(InferrerEngine inferrer) {
    removeAndClearReferences(inferrer);
    // Do not remove users because the tracing analysis could be interested
    // in tracing the users of this node.
    _assignments = STOP_TRACKING_ASSIGNMENTS_MARKER;
    abandonInferencing = true;
    isStable = true;
  }

  void maybeResume() {
    if (!mightResume) return;
    abandonInferencing = false;
    doNotEnqueue = false;
  }

  /// Destroys information not needed after type inference.
  void cleanup() {
    users = null;
    _assignments = null;
  }
}

abstract class ApplyableTypeInformation implements TypeInformation {
  bool mightBePassedToFunctionApply = false;
}

/**
 * Marker node used only during tree construction but not during actual type
 * refinement.
 *
 * Currently, this is used to give a type to an optional parameter even before
 * the corresponding default expression has been analyzed. See
 * [getDefaultTypeOfParameter] and [setDefaultTypeOfParameter] for details.
 */
class PlaceholderTypeInformation extends TypeInformation {
  PlaceholderTypeInformation(MemberTypeInformation context) : super(context);

  void accept(TypeInformationVisitor visitor) {
    throw new UnsupportedError("Cannot visit placeholder");
  }

  TypeMask computeType(InferrerEngine inferrer) {
    throw new UnsupportedError("Cannot refine placeholder");
  }

  toString() => "Placeholder [$hashCode]";
}

/**
 * Parameters of instance functions behave differently than other
 * elements because the inferrer may remove assignments. This happens
 * when the receiver of a dynamic call site can be refined
 * to a type where we know more about which instance method is being
 * called.
 */
class ParameterAssignments extends IterableBase<TypeInformation> {
  final Map<TypeInformation, int> assignments = new Map<TypeInformation, int>();

  void remove(TypeInformation info) {
    int existing = assignments[info];
    if (existing == null) return;
    if (existing == 1) {
      assignments.remove(info);
    } else {
      assignments[info] = existing - 1;
    }
  }

  void add(TypeInformation info) {
    int existing = assignments[info];
    if (existing == null) {
      assignments[info] = 1;
    } else {
      assignments[info] = existing + 1;
    }
  }

  void replace(TypeInformation old, TypeInformation replacement) {
    int existing = assignments[old];
    if (existing != null) {
      int other = assignments[replacement];
      if (other != null) existing += other;
      assignments[replacement] = existing;
      assignments.remove(old);
    }
  }

  Iterator<TypeInformation> get iterator => assignments.keys.iterator;
  Iterable<TypeInformation> where(Function f) => assignments.keys.where(f);

  bool contains(Object info) => assignments.containsKey(info);

  String toString() => assignments.keys.toList().toString();
}

/**
 * A node representing a resolved element of the program. The kind of
 * elements that need an [ElementTypeInformation] are:
 *
 * - Functions (including getters and setters)
 * - Constructors (factory or generative)
 * - Fields
 * - Parameters
 * - Local variables mutated in closures
 *
 * The [ElementTypeInformation] of a function and a constructor is its
 * return type.
 *
 * Note that a few elements of these kinds must be treated specially,
 * and they are dealt in [ElementTypeInformation.handleSpecialCases]:
 *
 * - Parameters of closures, `noSuchMethod` and `call` instance
 *   methods: we currently do not infer types for those.
 *
 * - Fields and parameters being assigned by synthesized calls done by
 *   the backend: we do not know what types the backend will use.
 *
 * - Native functions and fields: because native methods contain no Dart
 *   code, and native fields do not have Dart assignments, we just
 *   trust their type annotation.
 *
 */
abstract class ElementTypeInformation extends TypeInformation {
  /// Marker to disable inference for closures in [handleSpecialCases].
  bool disableInferenceForClosures = true;

  ElementTypeInformation._internal(MemberTypeInformation context)
      : super(context);
  ElementTypeInformation._withAssignments(
      MemberTypeInformation context, ParameterAssignments assignments)
      : super.withAssignments(context, assignments);

  String getInferredSignature(TypeSystem types);

  String get debugName;
}

/**
 * A node representing members in the broadest sense:
 *
 * - Functions
 * - Constructors
 * - Fields (also synthetic ones due to closures)
 * - Local functions (closures)
 *
 * These should never be created directly but instead are constructed by
 * the [ElementTypeInformation] factory.
 */
abstract class MemberTypeInformation extends ElementTypeInformation
    with ApplyableTypeInformation {
  final MemberEntity _member;

  /**
   * If [element] is a function, [closurizedCount] is the number of
   * times it is closurized. The value gets updated while inferring.
   */
  int closurizedCount = 0;

  // Strict `bool` value is computed in cleanup(). Also used as a flag to see if
  // cleanup has been called.
  bool _isCalledOnce = null;

  /**
   * This map contains the callers of [element]. It stores all unique call sites
   * to enable counting the global number of call sites of [element].
   *
   * A call site is either an AST [ast.Node], an [Element] (see uses of
   * [synthesizeForwardingCall] in [SimpleTypeInferrerVisitor]).
   *
   * The global information is summarized in [cleanup], after which [_callers]
   * is set to `null`.
   */
  Map<MemberEntity, Setlet<Spannable>> _callers;

  MemberTypeInformation._internal(this._member) : super._internal(null) {
    assert(_checkMember(_member));
  }

  bool _checkMember(MemberEntity member) {
    return !(member is MemberElement && !member.isDeclaration);
  }

  MemberEntity get member => _member;

  String get debugName => '$member';

  void addCall(MemberEntity caller, Spannable node) {
    _callers ??= <MemberEntity, Setlet<Spannable>>{};
    _callers.putIfAbsent(caller, () => new Setlet()).add(node);
  }

  void removeCall(MemberEntity caller, node) {
    if (_callers == null) return;
    Setlet calls = _callers[caller];
    if (calls == null) return;
    calls.remove(node);
    if (calls.isEmpty) {
      _callers.remove(caller);
    }
  }

  Iterable<MemberEntity> get callers {
    // TODO(sra): This is called only from an unused API and a test. If it
    // becomes used, [cleanup] will need to copy `_caller.keys`.

    // `simple_inferrer_callers_test.dart` ensures that cleanup has not
    // happened.
    return _callers.keys;
  }

  bool isCalledOnce() {
    // If this assert fires it means that this MemberTypeInformation for the
    // element was not part of type inference. This happens for
    // ConstructorBodyElements, so guard the call with a test for
    // ConstructorBodyElement. For other elements, investigate why the element
    // was not present for type inference.
    assert(_isCalledOnce != null);
    return _isCalledOnce ?? false;
  }

  bool _computeIsCalledOnce() {
    if (_callers == null) return false;
    int count = 0;
    for (var set in _callers.values) {
      count += set.length;
      if (count > 1) return false;
    }
    return count == 1;
  }

  bool get isClosurized => closurizedCount > 0;

  // Closurized methods never become stable to ensure that the information in
  // [users] is accurate. The inference stops tracking users for stable types.
  // Note that we only override the getter, the setter will still modify the
  // state of the [isStable] field inherited from [TypeInformation].
  bool get isStable => super.isStable && !isClosurized;

  TypeMask handleSpecialCases(InferrerEngine inferrer);

  TypeMask _handleFunctionCase(
      FunctionEntity function, InferrerEngine inferrer) {
    if (inferrer.closedWorld.nativeData.isNativeMember(function)) {
      // Use the type annotation as the type for native elements. We
      // also give up on inferring to make sure this element never
      // goes in the work queue.
      giveUp(inferrer);
      return inferrer
          .typeOfNativeBehavior(
              inferrer.closedWorld.nativeData.getNativeMethodBehavior(function))
          .type;
    }
    return null;
  }

  TypeMask potentiallyNarrowType(TypeMask mask, InferrerEngine inferrer) {
    Compiler compiler = inferrer.compiler;
    if (!compiler.options.trustTypeAnnotations &&
        !compiler.options.enableTypeAssertions &&
        !inferrer.optimizerHints.trustTypeAnnotations(_member)) {
      return mask;
    }
    return _potentiallyNarrowType(mask, inferrer);
  }

  TypeMask _potentiallyNarrowType(TypeMask mask, InferrerEngine inferrer);

  TypeMask computeType(InferrerEngine inferrer) {
    TypeMask special = handleSpecialCases(inferrer);
    if (special != null) return potentiallyNarrowType(special, inferrer);
    return potentiallyNarrowType(
        inferrer.types.computeTypeMask(assignments), inferrer);
  }

  TypeMask safeType(InferrerEngine inferrer) {
    return potentiallyNarrowType(super.safeType(inferrer), inferrer);
  }

  String toString() => 'Member $_member $type';

  accept(TypeInformationVisitor visitor) {
    return visitor.visitMemberTypeInformation(this);
  }

  void cleanup() {
    // This node is on multiple lists so cleanup() can be called twice.
    if (_isCalledOnce != null) return;
    _isCalledOnce = _computeIsCalledOnce();
    _callers = null;
    super.cleanup();
  }

  @override
  String getInferredSignature(TypeSystem types) {
    return types.getInferredSignatureOfMethod(_member);
  }
}

class FieldTypeInformation extends MemberTypeInformation {
  FieldEntity get _field => _member;
  final DartType _type;

  FieldTypeInformation(FieldEntity element, this._type)
      : super._internal(element);

  TypeMask handleSpecialCases(InferrerEngine inferrer) {
    if (!inferrer.backend.canFieldBeUsedForGlobalOptimizations(
            _field, inferrer.closedWorld) ||
        inferrer.optimizerHints.assumeDynamic(_field)) {
      // Do not infer types for fields that have a corresponding annotation or
      // are assigned by synthesized calls

      giveUp(inferrer);
      return safeType(inferrer);
    }
    if (inferrer.closedWorld.nativeData.isNativeMember(_field)) {
      // Use the type annotation as the type for native elements. We
      // also give up on inferring to make sure this element never
      // goes in the work queue.
      giveUp(inferrer);
      return inferrer
          .typeOfNativeBehavior(inferrer.closedWorld.nativeData
              .getNativeFieldLoadBehavior(_field))
          .type;
    }
    return null;
  }

  TypeMask _potentiallyNarrowType(TypeMask mask, InferrerEngine inferrer) {
    return _narrowType(inferrer.closedWorld, mask, _type);
  }

  bool hasStableType(InferrerEngine inferrer) {
    // The number of assignments of non-final fields is
    // not stable. Therefore such a field cannot be stable.
    if (!_field.isAssignable) {
      return false;
    }
    return super.hasStableType(inferrer);
  }
}

class GetterTypeInformation extends MemberTypeInformation {
  FunctionEntity get _getter => _member;
  final FunctionType _type;

  GetterTypeInformation(FunctionEntity element, this._type)
      : super._internal(element);

  TypeMask handleSpecialCases(InferrerEngine inferrer) {
    return _handleFunctionCase(_getter, inferrer);
  }

  TypeMask _potentiallyNarrowType(TypeMask mask, InferrerEngine inferrer) {
    return _narrowType(inferrer.closedWorld, mask, _type.returnType);
  }
}

class SetterTypeInformation extends MemberTypeInformation {
  FunctionEntity get _setter => _member;

  SetterTypeInformation(FunctionEntity element) : super._internal(element);

  TypeMask handleSpecialCases(InferrerEngine inferrer) {
    return _handleFunctionCase(_setter, inferrer);
  }

  TypeMask _potentiallyNarrowType(TypeMask mask, InferrerEngine inferrer) {
    return mask;
  }
}

class MethodTypeInformation extends MemberTypeInformation {
  FunctionEntity get _method => _member;
  final FunctionType _type;

  MethodTypeInformation(FunctionEntity element, this._type)
      : super._internal(element);

  TypeMask handleSpecialCases(InferrerEngine inferrer) {
    return _handleFunctionCase(_method, inferrer);
  }

  TypeMask _potentiallyNarrowType(TypeMask mask, InferrerEngine inferrer) {
    return _narrowType(inferrer.closedWorld, mask, _type.returnType);
  }

  bool hasStableType(InferrerEngine inferrer) => false;
}

class FactoryConstructorTypeInformation extends MemberTypeInformation {
  ConstructorEntity get _constructor => _member;
  final FunctionType _type;

  FactoryConstructorTypeInformation(ConstructorEntity element, this._type)
      : super._internal(element);

  TypeMask handleSpecialCases(InferrerEngine inferrer) {
    CommonMasks commonMasks = inferrer.commonMasks;
    if (_constructor.isFromEnvironmentConstructor) {
      if (_constructor.enclosingClass == inferrer.commonElements.intClass) {
        giveUp(inferrer);
        return commonMasks.intType.nullable();
      } else if (_constructor.enclosingClass ==
          inferrer.commonElements.boolClass) {
        giveUp(inferrer);
        return commonMasks.boolType.nullable();
      } else if (_constructor.enclosingClass ==
          inferrer.commonElements.stringClass) {
        giveUp(inferrer);
        return commonMasks.stringType.nullable();
      }
    }
    return _handleFunctionCase(_constructor, inferrer);
  }

  TypeMask _potentiallyNarrowType(TypeMask mask, InferrerEngine inferrer) {
    return _narrowType(inferrer.closedWorld, mask, _type.returnType);
  }

  bool hasStableType(InferrerEngine inferrer) {
    return super.hasStableType(inferrer);
  }
}

class GenerativeConstructorTypeInformation extends MemberTypeInformation {
  ConstructorEntity get _constructor => _member;

  GenerativeConstructorTypeInformation(ConstructorEntity element)
      : super._internal(element);

  TypeMask handleSpecialCases(InferrerEngine inferrer) {
    return _handleFunctionCase(_constructor, inferrer);
  }

  TypeMask _potentiallyNarrowType(TypeMask mask, InferrerEngine inferrer) {
    return mask;
  }

  bool hasStableType(InferrerEngine inferrer) {
    return super.hasStableType(inferrer);
  }
}

/**
 * A node representing parameters:
 *
 * - Parameters
 * - Initializing formals
 *
 * These should never be created directly but instead are constructed by
 * the [ElementTypeInformation] factory.
 */
class ParameterTypeInformation extends ElementTypeInformation {
  final Local _parameter;
  final DartType _type;
  final FunctionEntity _method;
  final bool _isInstanceMemberParameter;
  final bool _isClosureParameter;
  final bool _isInitializingFormal;
  bool _isTearOffClosureParameter = false;

  ParameterTypeInformation.localFunction(
      MemberTypeInformation context, this._parameter, this._type, this._method)
      : _isInstanceMemberParameter = false,
        _isClosureParameter = true,
        _isInitializingFormal = false,
        super._internal(context) {
    assert(_checkParameter(_parameter));
  }

  ParameterTypeInformation.static(
      MemberTypeInformation context, this._parameter, this._type, this._method,
      {bool isInitializingFormal: false})
      : _isInstanceMemberParameter = false,
        _isClosureParameter = false,
        _isInitializingFormal = isInitializingFormal,
        super._internal(context) {
    assert(_checkParameter(_parameter));
  }

  ParameterTypeInformation.instanceMember(
      MemberTypeInformation context,
      this._parameter,
      this._type,
      this._method,
      ParameterAssignments assignments)
      : _isInstanceMemberParameter = true,
        _isClosureParameter = false,
        _isInitializingFormal = false,
        super._withAssignments(context, assignments) {
    assert(_checkParameter(_parameter));
  }

  bool _checkParameter(Local parameter) {
    return !(parameter is LocalElement && !parameter.isImplementation);
  }

  FunctionEntity get method => _method;

  Local get parameter => _parameter;

  String get debugName => '$parameter';

  void tagAsTearOffClosureParameter(InferrerEngine inferrer) {
    assert(!_isInitializingFormal);
    _isTearOffClosureParameter = true;
    // We have to add a flow-edge for the default value (if it exists), as we
    // might not see all call-sites and thus miss the use of it.
    TypeInformation defaultType =
        inferrer.getDefaultTypeOfParameter(_parameter);
    if (defaultType != null) defaultType.addUser(this);
  }

  // TODO(herhut): Cleanup into one conditional.
  TypeMask handleSpecialCases(InferrerEngine inferrer) {
    if (!inferrer.backend.canFunctionParametersBeUsedForGlobalOptimizations(
            _method, inferrer.closedWorld) ||
        inferrer.optimizerHints.assumeDynamic(_method)) {
      // Do not infer types for parameters that have a corresponding annotation
      // or that are assigned by synthesized calls.
      giveUp(inferrer);
      return safeType(inferrer);
    }

    // The below do not apply to parameters of constructors, so skip
    // initializing formals.
    if (_isInitializingFormal) return null;

    if ((_isTearOffClosureParameter || _isClosureParameter) &&
        disableInferenceForClosures) {
      // Do not infer types for parameters of closures. We do not
      // clear the assignments in case the closure is successfully
      // traced.
      giveUp(inferrer, clearAssignments: false);
      return safeType(inferrer);
    }
    if (_isInstanceMemberParameter &&
        (_method.name == Identifiers.noSuchMethod_ ||
            (_method.name == Identifiers.call &&
                disableInferenceForClosures))) {
      // Do not infer types for parameters of [noSuchMethod] and [call] instance
      // methods.
      giveUp(inferrer);
      return safeType(inferrer);
    }
    if (inferrer.closedWorldRefiner
        .getCurrentlyKnownMightBePassedToApply(_method)) {
      giveUp(inferrer);
      return safeType(inferrer);
    }
    if (_method == inferrer.mainElement) {
      // The implicit call to main is not seen by the inferrer,
      // therefore we explicitly set the type of its parameters as
      // dynamic.
      // TODO(14566): synthesize a call instead to get the exact
      // types.
      giveUp(inferrer);
      return safeType(inferrer);
    }

    return null;
  }

  TypeMask potentiallyNarrowType(TypeMask mask, InferrerEngine inferrer) {
    Compiler compiler = inferrer.compiler;
    if (!compiler.options.trustTypeAnnotations &&
        !inferrer.optimizerHints.trustTypeAnnotations(_method)) {
      return mask;
    }
    // When type assertions are enabled (aka checked mode), we have to always
    // ignore type annotations to ensure that the checks are actually inserted
    // into the function body and retained until runtime.
    assert(!compiler.options.enableTypeAssertions);
    return _narrowType(inferrer.closedWorld, mask, _type);
  }

  TypeMask computeType(InferrerEngine inferrer) {
    TypeMask special = handleSpecialCases(inferrer);
    if (special != null) return special;
    return potentiallyNarrowType(
        inferrer.types.computeTypeMask(assignments), inferrer);
  }

  TypeMask safeType(InferrerEngine inferrer) {
    return potentiallyNarrowType(super.safeType(inferrer), inferrer);
  }

  bool hasStableType(InferrerEngine inferrer) {
    // The number of assignments of parameters of instance methods is
    // not stable. Therefore such a parameter cannot be stable.
    if (_isInstanceMemberParameter) {
      return false;
    }
    return super.hasStableType(inferrer);
  }

  accept(TypeInformationVisitor visitor) {
    return visitor.visitParameterTypeInformation(this);
  }

  String toString() => 'Parameter $_parameter $type';

  @override
  String getInferredSignature(TypeSystem types) {
    throw new UnsupportedError('ParameterTypeInformation.getInferredSignature');
  }
}

enum CallType {
  access,
  complex,
  forIn,
}

bool validCallType(CallType callType, Object call) {
  switch (callType) {
    case CallType.complex:
      return call is ast.SendSet;
    case CallType.access:
      return call is ast.Send;
    case CallType.forIn:
      return call is ast.ForIn;
  }
  throw new StateError('Unexpected call type $callType.');
}

/**
 * A [CallSiteTypeInformation] is a call found in the AST, or a
 * synthesized call for implicit calls in Dart (such as forwarding
 * factories). The [_call] field is a [ast.Node] for the former, and an
 * [Element] for the latter.
 *
 * In the inferrer graph, [CallSiteTypeInformation] nodes do not have
 * any assignment. They rely on the [caller] field for static calls,
 * and [selector] and [receiver] fields for dynamic calls.
 */
abstract class CallSiteTypeInformation extends TypeInformation
    with ApplyableTypeInformation {
  final Object _call;
  final MemberEntity caller;
  final Selector selector;
  final TypeMask mask;
  final ArgumentsTypes arguments;
  final bool inLoop;

  CallSiteTypeInformation(MemberTypeInformation context, this._call,
      this.caller, this.selector, this.mask, this.arguments, this.inLoop)
      : super.noAssignments(context) {
    assert(_checkCaller(caller));
    // [_call] is either an AST node or a constructor element in case of a
    // a forwarding constructor _call.
    assert(_call is ast.Node || _call is ConstructorElement);
  }

  bool _checkCaller(MemberEntity caller) {
    return !(caller is MemberElement && !caller.isDeclaration);
  }

  String toString() => 'Call site $debugName $type';

  /// Add [this] to the graph being computed by [engine].
  void addToGraph(InferrerEngine engine);

  /// Return an iterable over the targets of this call.
  Iterable<MemberEntity> get callees;

  String get debugName => '$_call';
}

class StaticCallSiteTypeInformation extends CallSiteTypeInformation {
  final MemberEntity calledElement;

  StaticCallSiteTypeInformation(
      MemberTypeInformation context,
      Spannable call,
      MemberEntity enclosing,
      this.calledElement,
      Selector selector,
      TypeMask mask,
      ArgumentsTypes arguments,
      bool inLoop)
      : super(context, call, enclosing, selector, mask, arguments, inLoop) {
    assert(_checkCalledElement(calledElement));
  }

  bool _checkCalledElement(MemberEntity calledElement) {
    return !(calledElement is MemberElement && !calledElement.isDeclaration);
  }

  MemberTypeInformation _getCalledTypeInfo(InferrerEngine inferrer) {
    return inferrer.types.getInferredTypeOfMember(calledElement);
  }

  void addToGraph(InferrerEngine inferrer) {
    MemberTypeInformation callee = _getCalledTypeInfo(inferrer);
    callee.addCall(caller, _call);
    callee.addUser(this);
    if (arguments != null) {
      arguments.forEach((info) => info.addUser(this));
    }
    inferrer.updateParameterAssignments(
        this, calledElement, arguments, selector, mask,
        remove: false, addToQueue: false);
  }

  bool get isSynthesized {
    // Some calls do not have a corresponding selector, for example
    // forwarding factory constructors, or synthesized super
    // constructor calls. We synthesize these calls but do
    // not create a selector for them.
    return selector == null;
  }

  TypeInformation _getCalledTypeInfoWithSelector(InferrerEngine inferrer) {
    return inferrer.typeOfMemberWithSelector(calledElement, selector);
  }

  TypeMask computeType(InferrerEngine inferrer) {
    if (isSynthesized) {
      assert(arguments != null);
      return _getCalledTypeInfo(inferrer).type;
    } else {
      return _getCalledTypeInfoWithSelector(inferrer).type;
    }
  }

  Iterable<MemberEntity> get callees => [calledElement];

  accept(TypeInformationVisitor visitor) {
    return visitor.visitStaticCallSiteTypeInformation(this);
  }

  bool hasStableType(InferrerEngine inferrer) {
    bool isStable = _getCalledTypeInfo(inferrer).isStable;
    return isStable &&
        (arguments == null || arguments.every((info) => info.isStable)) &&
        super.hasStableType(inferrer);
  }

  void removeAndClearReferences(InferrerEngine inferrer) {
    ElementTypeInformation callee = _getCalledTypeInfo(inferrer);
    callee.removeUser(this);
    if (arguments != null) {
      arguments.forEach((info) => info.removeUser(this));
    }
    super.removeAndClearReferences(inferrer);
  }
}

class DynamicCallSiteTypeInformation<T> extends CallSiteTypeInformation {
  final CallType _callType;
  final TypeInformation receiver;
  final bool isConditional;

  /// Cached targets of this call.
  Iterable<MemberEntity> targets;

  DynamicCallSiteTypeInformation(
      MemberTypeInformation context,
      this._callType,
      T call,
      MemberEntity enclosing,
      Selector selector,
      TypeMask mask,
      this.receiver,
      ArgumentsTypes arguments,
      bool inLoop,
      this.isConditional)
      : super(context, call, enclosing, selector, mask, arguments, inLoop) {
    assert(validCallType(_callType, _call));
  }

  void addToGraph(InferrerEngine inferrer) {
    assert(receiver != null);
    TypeMask typeMask = computeTypedSelector(inferrer);
    targets = inferrer.closedWorld.locateMembers(selector, typeMask);
    receiver.addUser(this);
    if (arguments != null) {
      arguments.forEach((info) => info.addUser(this));
    }
    for (MemberEntity element in targets) {
      MemberTypeInformation callee =
          inferrer.types.getInferredTypeOfMember(element);
      callee.addCall(caller, _call);
      callee.addUser(this);
      inferrer.updateParameterAssignments(
          this, element, arguments, selector, typeMask,
          remove: false, addToQueue: false);
    }
  }

  Iterable<MemberEntity> get callees => targets;

  TypeMask computeTypedSelector(InferrerEngine inferrer) {
    TypeMask receiverType = receiver.type;

    if (mask != receiverType) {
      return receiverType == inferrer.commonMasks.dynamicType
          ? null
          : receiverType;
    } else {
      return mask;
    }
  }

  bool targetsIncludeComplexNoSuchMethod(InferrerEngine inferrer) {
    return targets.any((MemberEntity e) {
      return e.isFunction &&
          e.isInstanceMember &&
          e.name == Identifiers.noSuchMethod_ &&
          inferrer.backend.noSuchMethodRegistry.isComplex(e);
    });
  }

  /**
   * We optimize certain operations on the [int] class because we know more
   * about their return type than the actual Dart code. For example, we know int
   * + int returns an int. The Dart library code for [int.operator+] only says
   * it returns a [num].
   *
   * Returns the more precise TypeInformation, or `null` to defer to the library
   * code.
   */
  TypeInformation handleIntrisifiedSelector(
      Selector selector, TypeMask mask, InferrerEngine inferrer) {
    ClosedWorld closedWorld = inferrer.closedWorld;
    if (mask == null) return null;
    if (!mask.containsOnlyInt(closedWorld)) {
      return null;
    }
    if (!selector.isCall && !selector.isOperator) return null;
    if (!arguments.named.isEmpty) return null;
    if (arguments.positional.length > 1) return null;

    ClassEntity uint31Implementation = closedWorld.commonElements.jsUInt31Class;
    bool isInt(info) => info.type.containsOnlyInt(closedWorld);
    bool isEmpty(info) => info.type.isEmpty;
    bool isUInt31(info) {
      return info.type.satisfies(uint31Implementation, closedWorld);
    }

    bool isPositiveInt(info) {
      return info.type.satisfies(
          closedWorld.commonElements.jsPositiveIntClass, closedWorld);
    }

    TypeInformation tryLater() => inferrer.types.nonNullEmptyType;

    TypeInformation argument =
        arguments.isEmpty ? null : arguments.positional.first;

    String name = selector.name;
    // These are type inference rules only for useful cases that are not
    // expressed in the library code, for example:
    //
    //     int + int        ->  int
    //     uint31 | uint31  ->  uint31
    //
    switch (name) {
      case '*':
      case '+':
      case '%':
      case 'remainder':
      case '~/':
        if (isEmpty(argument)) return tryLater();
        if (isPositiveInt(receiver) && isPositiveInt(argument)) {
          // uint31 + uint31 -> uint32
          if (name == '+' && isUInt31(receiver) && isUInt31(argument)) {
            return inferrer.types.uint32Type;
          }
          return inferrer.types.positiveIntType;
        }
        if (isInt(argument)) {
          return inferrer.types.intType;
        }
        return null;

      case '|':
      case '^':
        if (isEmpty(argument)) return tryLater();
        if (isUInt31(receiver) && isUInt31(argument)) {
          return inferrer.types.uint31Type;
        }
        return null;

      case '>>':
        if (isEmpty(argument)) return tryLater();
        if (isUInt31(receiver)) {
          return inferrer.types.uint31Type;
        }
        return null;

      case '&':
        if (isEmpty(argument)) return tryLater();
        if (isUInt31(receiver) || isUInt31(argument)) {
          return inferrer.types.uint31Type;
        }
        return null;

      case '-':
        if (isEmpty(argument)) return tryLater();
        if (isInt(argument)) {
          return inferrer.types.intType;
        }
        return null;

      case 'unary-':
        // The receiver being an int, the return value will also be an int.
        return inferrer.types.intType;

      case 'abs':
        return arguments.hasNoArguments()
            ? inferrer.types.positiveIntType
            : null;

      default:
        return null;
    }
  }

  TypeMask computeType(InferrerEngine inferrer) {
    Iterable<MemberEntity> oldTargets = targets;
    TypeMask typeMask = computeTypedSelector(inferrer);
    inferrer.updateSelectorInMember(
        caller, _callType, _call, selector, typeMask);

    TypeMask maskToUse =
        inferrer.closedWorld.extendMaskIfReachesAll(selector, typeMask);
    bool canReachAll = inferrer.closedWorld.backendUsage.isInvokeOnUsed &&
        (maskToUse != typeMask);

    // If this call could potentially reach all methods that satisfy
    // the untyped selector (through noSuchMethod's `Invocation`
    // and a call to `delegate`), we iterate over all these methods to
    // update their parameter types.
    targets = inferrer.closedWorld.locateMembers(selector, maskToUse);
    Iterable<MemberEntity> typedTargets = canReachAll
        ? inferrer.closedWorld.locateMembers(selector, typeMask)
        : targets;

    // Update the call graph if the targets could have changed.
    if (!identical(targets, oldTargets)) {
      // Add calls to new targets to the graph.
      targets
          .where((target) => !oldTargets.contains(target))
          .forEach((MemberEntity element) {
        MemberTypeInformation callee =
            inferrer.types.getInferredTypeOfMember(element);
        callee.addCall(caller, _call);
        callee.addUser(this);
        inferrer.updateParameterAssignments(
            this, element, arguments, selector, typeMask,
            remove: false, addToQueue: true);
      });

      // Walk over the old targets, and remove calls that cannot happen anymore.
      oldTargets
          .where((target) => !targets.contains(target))
          .forEach((MemberEntity element) {
        MemberTypeInformation callee =
            inferrer.types.getInferredTypeOfMember(element);
        callee.removeCall(caller, _call);
        callee.removeUser(this);
        inferrer.updateParameterAssignments(
            this, element, arguments, selector, typeMask,
            remove: true, addToQueue: true);
      });
    }

    // Walk over the found targets, and compute the joined union type mask
    // for all these targets.
    TypeMask result =
        inferrer.types.joinTypeMasks(targets.map((MemberEntity element) {
      // If [canReachAll] is true, then we are iterating over all
      // targets that satisfy the untyped selector. We skip the return
      // type of the targets that can only be reached through
      // `Invocation.delegate`. Note that the `noSuchMethod` targets
      // are included in [typedTargets].
      if (canReachAll && !typedTargets.contains(element)) {
        return const TypeMask.nonNullEmpty();
      }
      if (inferrer.returnsListElementType(selector, typeMask)) {
        ContainerTypeMask containerTypeMask = receiver.type;
        return containerTypeMask.elementType;
      } else if (inferrer.returnsMapValueType(selector, typeMask)) {
        if (typeMask.isDictionary) {
          TypeMask arg = arguments.positional[0].type;
          if (arg is ValueTypeMask && arg.value.isString) {
            DictionaryTypeMask dictionaryTypeMask = typeMask;
            String key = arg.value.primitiveValue;
            if (dictionaryTypeMask.typeMap.containsKey(key)) {
              if (debug.VERBOSE) {
                print("Dictionary lookup for $key yields "
                    "${dictionaryTypeMask.typeMap[key]}.");
              }
              return dictionaryTypeMask.typeMap[key];
            } else {
              // The typeMap is precise, so if we do not find the key, the lookup
              // will be [null] at runtime.
              if (debug.VERBOSE) {
                print("Dictionary lookup for $key yields [null].");
              }
              return inferrer.types.nullType.type;
            }
          }
        }
        MapTypeMask mapTypeMask = typeMask;
        if (debug.VERBOSE) {
          print("Map lookup for $selector yields ${mapTypeMask.valueType}.");
        }
        return mapTypeMask.valueType;
      } else {
        TypeInformation info =
            handleIntrisifiedSelector(selector, typeMask, inferrer);
        if (info != null) return info.type;
        return inferrer.typeOfMemberWithSelector(element, selector).type;
      }
    }));

    if (isConditional && receiver.type.isNullable) {
      // Conditional call sites (e.g. `a?.b`) may be null if the receiver is
      // null.
      result = result.nullable();
    }
    return result;
  }

  void giveUp(InferrerEngine inferrer, {bool clearAssignments: true}) {
    if (!abandonInferencing) {
      inferrer.updateSelectorInMember(caller, _callType, _call, selector, mask);
      Iterable<MemberEntity> oldTargets = targets;
      targets = inferrer.closedWorld.locateMembers(selector, mask);
      for (MemberEntity element in targets) {
        if (!oldTargets.contains(element)) {
          MemberTypeInformation callee =
              inferrer.types.getInferredTypeOfMember(element);
          callee.addCall(caller, _call);
          inferrer.updateParameterAssignments(
              this, element, arguments, selector, mask,
              remove: false, addToQueue: true);
        }
      }
    }
    super.giveUp(inferrer, clearAssignments: clearAssignments);
  }

  void removeAndClearReferences(InferrerEngine inferrer) {
    for (MemberEntity element in targets) {
      MemberTypeInformation callee =
          inferrer.types.getInferredTypeOfMember(element);
      callee.removeUser(this);
    }
    if (arguments != null) {
      arguments.forEach((info) => info.removeUser(this));
    }
    super.removeAndClearReferences(inferrer);
  }

  String toString() => 'Call site $debugName on ${receiver.type} $type';

  accept(TypeInformationVisitor visitor) {
    return visitor.visitDynamicCallSiteTypeInformation(this);
  }

  bool hasStableType(InferrerEngine inferrer) {
    return receiver.isStable &&
        targets.every((MemberEntity element) {
          return inferrer.types.getInferredTypeOfMember(element).isStable;
        }) &&
        (arguments == null || arguments.every((info) => info.isStable)) &&
        super.hasStableType(inferrer);
  }
}

class ClosureCallSiteTypeInformation extends CallSiteTypeInformation {
  final TypeInformation closure;

  ClosureCallSiteTypeInformation(
      MemberTypeInformation context,
      Object call,
      MemberEntity enclosing,
      Selector selector,
      TypeMask mask,
      this.closure,
      ArgumentsTypes arguments,
      bool inLoop)
      : super(context, call, enclosing, selector, mask, arguments, inLoop);

  void addToGraph(InferrerEngine inferrer) {
    arguments.forEach((info) => info.addUser(this));
    closure.addUser(this);
  }

  TypeMask computeType(InferrerEngine inferrer) => safeType(inferrer);

  Iterable<MemberEntity> get callees {
    throw new UnsupportedError("Cannot compute callees of a closure call.");
  }

  String toString() => 'Closure call $debugName on $closure';

  accept(TypeInformationVisitor visitor) {
    return visitor.visitClosureCallSiteTypeInformation(this);
  }

  void removeAndClearReferences(InferrerEngine inferrer) {
    // This method is a placeholder for the following comment:
    // We should maintain the information that the closure is a user
    // of its arguments because we do not check that the arguments
    // have a stable type for a closure call to be stable; our tracing
    // analysis want to know whether an (non-stable) argument is
    // passed to a closure.
    return super.removeAndClearReferences(inferrer);
  }
}

/**
 * A [ConcreteTypeInformation] represents a type that needed
 * to be materialized during the creation of the graph. For example,
 * literals, [:this:] or [:super:] need a [ConcreteTypeInformation].
 *
 * [ConcreteTypeInformation] nodes have no assignment. Also, to save
 * on memory, we do not add users to [ConcreteTypeInformation] nodes,
 * because we know such node will never be refined to a different
 * type.
 */
class ConcreteTypeInformation extends TypeInformation {
  ConcreteTypeInformation(TypeMask type) : super.untracked() {
    this.type = type;
    this.isStable = true;
  }

  bool get isConcrete => true;

  void addUser(TypeInformation user) {
    // Nothing to do, a concrete type does not get updated so never
    // needs to notify its users.
  }

  void addUsersOf(TypeInformation other) {
    // Nothing to do, a concrete type does not get updated so never
    // needs to notify its users.
  }

  void removeUser(TypeInformation user) {}

  void addAssignment(TypeInformation assignment) {
    throw "Not supported";
  }

  void removeAssignment(TypeInformation assignment) {
    throw "Not supported";
  }

  TypeMask computeType(InferrerEngine inferrer) => type;

  bool reset(InferrerEngine inferrer) {
    throw "Not supported";
  }

  String toString() => 'Type $type';

  accept(TypeInformationVisitor visitor) {
    return visitor.visitConcreteTypeInformation(this);
  }

  bool hasStableType(InferrerEngine inferrer) => true;
}

class StringLiteralTypeInformation extends ConcreteTypeInformation {
  final String value;

  StringLiteralTypeInformation(this.value, TypeMask mask)
      : super(new ValueTypeMask(mask, new StringConstantValue(value)));

  String asString() => value;
  String toString() => 'Type $type value ${value}';

  accept(TypeInformationVisitor visitor) {
    return visitor.visitStringLiteralTypeInformation(this);
  }
}

class BoolLiteralTypeInformation extends ConcreteTypeInformation {
  final bool value;

  BoolLiteralTypeInformation(this.value, TypeMask mask)
      : super(new ValueTypeMask(
            mask, value ? new TrueConstantValue() : new FalseConstantValue()));

  String toString() => 'Type $type value ${value}';

  accept(TypeInformationVisitor visitor) {
    return visitor.visitBoolLiteralTypeInformation(this);
  }
}

/**
 * A [NarrowTypeInformation] narrows a [TypeInformation] to a type,
 * represented in [typeAnnotation].
 *
 * A [NarrowTypeInformation] node has only one assignment: the
 * [TypeInformation] it narrows.
 *
 * [NarrowTypeInformation] nodes are created for:
 *
 * - Code after `is` and `as` checks, where we have more information
 *   on the type of the right hand side of the expression.
 *
 * - Code after a dynamic call, where we have more information on the
 *   type of the receiver: it can only be of a class that holds a
 *   potential target of this dynamic call.
 *
 * - In checked mode, after a type annotation, we have more
 *   information on the type of a local.
 */
class NarrowTypeInformation extends TypeInformation {
  final TypeMask typeAnnotation;

  NarrowTypeInformation(TypeInformation narrowedType, this.typeAnnotation)
      : super(narrowedType.context) {
    addAssignment(narrowedType);
  }

  addAssignment(TypeInformation info) {
    super.addAssignment(info);
    assert(assignments.length == 1);
  }

  TypeMask computeType(InferrerEngine inferrer) {
    TypeMask input = assignments.first.type;
    TypeMask intersection =
        input.intersection(typeAnnotation, inferrer.closedWorld);
    if (debug.ANOMALY_WARN) {
      if (!input.containsMask(intersection, inferrer.closedWorld) ||
          !typeAnnotation.containsMask(intersection, inferrer.closedWorld)) {
        print("ANOMALY WARNING: narrowed $input to $intersection via "
            "$typeAnnotation");
      }
    }
    return intersection;
  }

  String toString() {
    return 'Narrow to $typeAnnotation $type';
  }

  accept(TypeInformationVisitor visitor) {
    return visitor.visitNarrowTypeInformation(this);
  }
}

/**
 * An [InferredTypeInformation] is a [TypeInformation] that
 * defaults to the dynamic type until it is marked as being
 * inferred, at which point it computes its type based on
 * its assignments.
 */
abstract class InferredTypeInformation extends TypeInformation {
  /** Whether the element type in that container has been inferred. */
  bool inferred = false;

  InferredTypeInformation(
      MemberTypeInformation context, TypeInformation parentType)
      : super(context) {
    if (parentType != null) addAssignment(parentType);
  }

  TypeMask computeType(InferrerEngine inferrer) {
    if (!inferred) return safeType(inferrer);
    return inferrer.types.computeTypeMask(assignments);
  }

  bool hasStableType(InferrerEngine inferrer) {
    return inferred && super.hasStableType(inferrer);
  }
}

/**
 * A [ListTypeInformation] is a [TypeInformation] created
 * for each `List` instantiations.
 */
class ListTypeInformation extends TypeInformation with TracedTypeInformation {
  final ElementInContainerTypeInformation elementType;

  /** The container type before it is inferred. */
  final ContainerTypeMask originalType;

  /** The length at the allocation site. */
  final int originalLength;

  /** The length after the container has been traced. */
  int inferredLength;

  /**
   * Whether this list goes through a growable check.
   * We conservatively assume it does.
   */
  bool checksGrowable = true;

  ListTypeInformation(MemberTypeInformation context, this.originalType,
      this.elementType, this.originalLength)
      : super(context) {
    type = originalType;
    inferredLength = originalType.length;
    elementType.addUser(this);
  }

  String toString() => 'List type $type';

  accept(TypeInformationVisitor visitor) {
    return visitor.visitListTypeInformation(this);
  }

  bool hasStableType(InferrerEngine inferrer) {
    return elementType.isStable && super.hasStableType(inferrer);
  }

  TypeMask computeType(InferrerEngine inferrer) {
    dynamic mask = type;
    if (!mask.isContainer ||
        mask.elementType != elementType.type ||
        mask.length != inferredLength) {
      return new ContainerTypeMask(
          originalType.forwardTo,
          originalType.allocationNode,
          originalType.allocationElement,
          elementType.type,
          inferredLength);
    }
    return mask;
  }

  TypeMask safeType(InferrerEngine inferrer) => originalType;

  void cleanup() {
    super.cleanup();
    elementType.cleanup();
    _flowsInto = null;
  }
}

/**
 * An [ElementInContainerTypeInformation] holds the common type of the
 * elements in a [ListTypeInformation].
 */
class ElementInContainerTypeInformation extends InferredTypeInformation {
  ElementInContainerTypeInformation(MemberTypeInformation context, elementType)
      : super(context, elementType);

  String toString() => 'Element in container $type';

  accept(TypeInformationVisitor visitor) {
    return visitor.visitElementInContainerTypeInformation(this);
  }
}

/**
 * A [MapTypeInformation] is a [TypeInformation] created
 * for maps.
 */
class MapTypeInformation extends TypeInformation with TracedTypeInformation {
  // When in Dictionary mode, this map tracks the type of the values that
  // have been assigned to a specific [String] key.
  final Map<String, ValueInMapTypeInformation> typeInfoMap = {};
  // These fields track the overall type of the keys/values in the map.
  final KeyInMapTypeInformation keyType;
  final ValueInMapTypeInformation valueType;
  final MapTypeMask originalType;

  // Set to false if a statically unknown key flows into this map.
  bool _allKeysAreStrings = true;

  bool get inDictionaryMode => !bailedOut && _allKeysAreStrings;

  MapTypeInformation(MemberTypeInformation context, this.originalType,
      this.keyType, this.valueType)
      : super(context) {
    keyType.addUser(this);
    valueType.addUser(this);
    type = originalType;
  }

  TypeInformation addEntryAssignment(TypeInformation key, TypeInformation value,
      [bool nonNull = false]) {
    TypeInformation newInfo = null;
    if (_allKeysAreStrings && key is StringLiteralTypeInformation) {
      String keyString = key.asString();
      typeInfoMap.putIfAbsent(keyString, () {
        newInfo = new ValueInMapTypeInformation(context, null, nonNull);
        return newInfo;
      });
      typeInfoMap[keyString].addAssignment(value);
    } else {
      _allKeysAreStrings = false;
      typeInfoMap.clear();
    }
    keyType.addAssignment(key);
    valueType.addAssignment(value);
    if (newInfo != null) newInfo.addUser(this);

    return newInfo;
  }

  List<TypeInformation> addMapAssignment(MapTypeInformation other) {
    List<TypeInformation> newInfos = <TypeInformation>[];
    if (_allKeysAreStrings && other.inDictionaryMode) {
      other.typeInfoMap.forEach((keyString, value) {
        typeInfoMap.putIfAbsent(keyString, () {
          TypeInformation newInfo =
              new ValueInMapTypeInformation(context, null, false);
          newInfos.add(newInfo);
          return newInfo;
        });
        typeInfoMap[keyString].addAssignment(value);
      });
    } else {
      _allKeysAreStrings = false;
      typeInfoMap.clear();
    }
    keyType.addAssignment(other.keyType);
    valueType.addAssignment(other.valueType);

    return newInfos;
  }

  markAsInferred() {
    keyType.inferred = valueType.inferred = true;
    typeInfoMap.values.forEach((v) => v.inferred = true);
  }

  addAssignment(TypeInformation other) {
    throw "not supported";
  }

  accept(TypeInformationVisitor visitor) {
    return visitor.visitMapTypeInformation(this);
  }

  TypeMask toTypeMask(InferrerEngine inferrer) {
    if (inDictionaryMode) {
      Map<String, TypeMask> mappings = new Map<String, TypeMask>();
      for (var key in typeInfoMap.keys) {
        mappings[key] = typeInfoMap[key].type;
      }
      return new DictionaryTypeMask(
          originalType.forwardTo,
          originalType.allocationNode,
          originalType.allocationElement,
          keyType.type,
          valueType.type,
          mappings);
    } else {
      return new MapTypeMask(
          originalType.forwardTo,
          originalType.allocationNode,
          originalType.allocationElement,
          keyType.type,
          valueType.type);
    }
  }

  TypeMask computeType(InferrerEngine inferrer) {
    if (type.isDictionary != inDictionaryMode) {
      return toTypeMask(inferrer);
    } else if (type.isDictionary) {
      assert(inDictionaryMode);
      DictionaryTypeMask mask = type;
      for (var key in typeInfoMap.keys) {
        TypeInformation value = typeInfoMap[key];
        if (!mask.typeMap.containsKey(key) &&
            !value.type.containsAll(inferrer.closedWorld) &&
            !value.type.isNullable) {
          return toTypeMask(inferrer);
        }
        if (mask.typeMap[key] != typeInfoMap[key].type) {
          return toTypeMask(inferrer);
        }
      }
    } else if (type.isMap) {
      MapTypeMask mask = type;
      if (mask.keyType != keyType.type || mask.valueType != valueType.type) {
        return toTypeMask(inferrer);
      }
    } else {
      return toTypeMask(inferrer);
    }

    return type;
  }

  TypeMask safeType(InferrerEngine inferrer) => originalType;

  bool hasStableType(InferrerEngine inferrer) {
    return keyType.isStable &&
        valueType.isStable &&
        super.hasStableType(inferrer);
  }

  void cleanup() {
    super.cleanup();
    keyType.cleanup();
    valueType.cleanup();
    for (TypeInformation info in typeInfoMap.values) {
      info.cleanup();
    }
    _flowsInto = null;
  }

  String toString() {
    return 'Map $type (K:$keyType, V:$valueType) contents $typeInfoMap';
  }
}

/**
 * A [KeyInMapTypeInformation] holds the common type
 * for the keys in a [MapTypeInformation]
 */
class KeyInMapTypeInformation extends InferredTypeInformation {
  KeyInMapTypeInformation(
      MemberTypeInformation context, TypeInformation keyType)
      : super(context, keyType);

  accept(TypeInformationVisitor visitor) {
    return visitor.visitKeyInMapTypeInformation(this);
  }

  String toString() => 'Key in Map $type';
}

/**
 * A [ValueInMapTypeInformation] holds the common type
 * for the values in a [MapTypeInformation]
 */
class ValueInMapTypeInformation extends InferredTypeInformation {
  // [nonNull] is set to true if this value is known to be part of the map.
  // Note that only values assigned to a specific key value in dictionary
  // mode can ever be marked as [nonNull].
  final bool nonNull;

  ValueInMapTypeInformation(
      MemberTypeInformation context, TypeInformation valueType,
      [this.nonNull = false])
      : super(context, valueType);

  accept(TypeInformationVisitor visitor) {
    return visitor.visitValueInMapTypeInformation(this);
  }

  TypeMask computeType(InferrerEngine inferrer) {
    return nonNull
        ? super.computeType(inferrer)
        : super.computeType(inferrer).nullable();
  }

  String toString() => 'Value in Map $type';
}

/**
 * A [PhiElementTypeInformation] is an union of
 * [ElementTypeInformation], that is local to a method.
 */
class PhiElementTypeInformation<T> extends TypeInformation {
  final T branchNode;
  final Local variable;
  final bool isTry;

  PhiElementTypeInformation(
      MemberTypeInformation context, this.branchNode, this.variable,
      {this.isTry})
      : super(context);

  TypeMask computeType(InferrerEngine inferrer) {
    return inferrer.types.computeTypeMask(assignments);
  }

  String toString() => 'Phi $variable $type';

  accept(TypeInformationVisitor visitor) {
    return visitor.visitPhiElementTypeInformation(this);
  }
}

class ClosureTypeInformation extends TypeInformation
    with ApplyableTypeInformation {
  final FunctionEntity _element;

  ClosureTypeInformation(MemberTypeInformation context, this._element)
      : super(context);

  FunctionEntity get closure => _element;

  TypeMask computeType(InferrerEngine inferrer) => safeType(inferrer);

  TypeMask safeType(InferrerEngine inferrer) {
    return inferrer.types.functionType.type;
  }

  String get debugName => '$closure';

  String toString() => 'Closure $_element';

  accept(TypeInformationVisitor visitor) {
    return visitor.visitClosureTypeInformation(this);
  }

  bool hasStableType(InferrerEngine inferrer) {
    return false;
  }

  String getInferredSignature(TypeSystem types) {
    return types.getInferredSignatureOfMethod(_element);
  }
}

/**
 * Mixin for [TypeInformation] nodes that can bail out during tracing.
 */
abstract class TracedTypeInformation implements TypeInformation {
  /// Set to false once analysis has succeeded.
  bool bailedOut = true;

  /// Set to true once analysis is completed.
  bool analyzed = false;

  Set<TypeInformation> _flowsInto;

  /**
   * The set of [TypeInformation] nodes where values from the traced node could
   * flow in.
   */
  Set<TypeInformation> get flowsInto {
    return (_flowsInto == null)
        ? const ImmutableEmptySet<TypeInformation>()
        : _flowsInto;
  }

  /**
   * Adds [nodes] to the sets of values this [TracedTypeInformation] flows into.
   */
  void addFlowsIntoTargets(Iterable<TypeInformation> nodes) {
    if (_flowsInto == null) {
      _flowsInto = nodes.toSet();
    } else {
      _flowsInto.addAll(nodes);
    }
  }
}

class AwaitTypeInformation<T> extends TypeInformation {
  final T _node;

  AwaitTypeInformation(MemberTypeInformation context, this._node)
      : super(context);

  // TODO(22894): Compute a better type here.
  TypeMask computeType(InferrerEngine inferrer) => safeType(inferrer);

  String get debugName => '$_node';

  String toString() => 'Await';

  accept(TypeInformationVisitor visitor) {
    return visitor.visitAwaitTypeInformation(this);
  }
}

class YieldTypeInformation<T> extends TypeInformation {
  final T _node;

  YieldTypeInformation(MemberTypeInformation context, this._node)
      : super(context);

  TypeMask computeType(InferrerEngine inferrer) => safeType(inferrer);

  String get debugName => '$_node';

  String toString() => 'Yield';

  accept(TypeInformationVisitor visitor) {
    return visitor.visitYieldTypeInformation(this);
  }
}

abstract class TypeInformationVisitor<T> {
  T visitNarrowTypeInformation(NarrowTypeInformation info);
  T visitPhiElementTypeInformation(PhiElementTypeInformation info);
  T visitElementInContainerTypeInformation(
      ElementInContainerTypeInformation info);
  T visitKeyInMapTypeInformation(KeyInMapTypeInformation info);
  T visitValueInMapTypeInformation(ValueInMapTypeInformation info);
  T visitListTypeInformation(ListTypeInformation info);
  T visitMapTypeInformation(MapTypeInformation info);
  T visitConcreteTypeInformation(ConcreteTypeInformation info);
  T visitStringLiteralTypeInformation(StringLiteralTypeInformation info);
  T visitBoolLiteralTypeInformation(BoolLiteralTypeInformation info);
  T visitClosureCallSiteTypeInformation(ClosureCallSiteTypeInformation info);
  T visitStaticCallSiteTypeInformation(StaticCallSiteTypeInformation info);
  T visitDynamicCallSiteTypeInformation(DynamicCallSiteTypeInformation info);
  T visitMemberTypeInformation(MemberTypeInformation info);
  T visitParameterTypeInformation(ParameterTypeInformation info);
  T visitClosureTypeInformation(ClosureTypeInformation info);
  T visitAwaitTypeInformation(AwaitTypeInformation info);
  T visitYieldTypeInformation(YieldTypeInformation info);
}

TypeMask _narrowType(
    ClosedWorld closedWorld, TypeMask type, DartType annotation,
    {bool isNullable: true}) {
  TypeMask otherType;
  if (annotation.treatAsDynamic) {
    return type;
  } else if (annotation.isInterfaceType) {
    InterfaceType interfaceType = annotation;
    if (interfaceType.element == closedWorld.commonElements.objectClass) {
      return type;
    }
    otherType = new TypeMask.nonNullSubtype(interfaceType.element, closedWorld);
  } else if (annotation.isVoid) {
    return type;
  } else if (annotation.isTypedef || annotation.isFunctionType) {
    otherType = closedWorld.commonMasks.functionType;
  } else {
    assert(annotation.isTypeVariable);
    // TODO(ngeoffray): Narrow to bound.
    return type;
  }
  if (isNullable) otherType = otherType.nullable();
  if (type == null) return otherType;
  return type.intersection(otherType, closedWorld);
}
