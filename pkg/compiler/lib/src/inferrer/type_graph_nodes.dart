// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library compiler.src.inferrer.type_graph_nodes;

import 'dart:collection' show IterableBase;

import 'package:kernel/ast.dart' as ir;

import '../common/names.dart' show Identifiers;
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../universe/selector.dart' show Selector;
import '../util/util.dart' show ImmutableEmptySet, Setlet;
import '../world.dart' show JClosedWorld;
import 'abstract_value_domain.dart';
import 'debug.dart' as debug;
import 'locals_handler.dart' show ArgumentsTypes;
import 'inferrer_engine.dart';
import 'type_system.dart';

/// Common class for all nodes in the graph. The current nodes are:
///
/// - Concrete types
/// - Elements
/// - Call sites
/// - Narrowing instructions
/// - Phi instructions
/// - Containers (for lists)
/// - Type of the element in a container
///
/// A node has a set of assignments and users. Assignments are used to
/// compute the type of the node ([TypeInformation.computeType]). Users are
/// added to the inferrer's work queue when the type of the node
/// changes.
abstract class TypeInformation {
  Set<TypeInformation> users;
  var /* List|ParameterAssignments */ _assignments;

  /// The type the inferrer has found for this [TypeInformation].
  /// Initially empty.
  AbstractValue type;

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

  TypeInformation(this.type, this.context)
      : _assignments = <TypeInformation>[],
        users = new Setlet<TypeInformation>();

  TypeInformation.noAssignments(this.type, this.context)
      : _assignments = const <TypeInformation>[],
        users = new Setlet<TypeInformation>();

  TypeInformation.untracked(this.type)
      : _assignments = const <TypeInformation>[],
        users = const ImmutableEmptySet(),
        context = null;

  TypeInformation.withAssignments(this.type, this.context, this._assignments)
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

  AbstractValue refine(InferrerEngine inferrer) {
    return abandonInferencing ? safeType(inferrer) : computeType(inferrer);
  }

  /// Computes a new type for this [TypeInformation] node depending on its
  /// potentially updated inputs.
  AbstractValue computeType(InferrerEngine inferrer);

  /// Returns an approximation for this [TypeInformation] node that is always
  /// safe to use. Used when abandoning inference on a node.
  AbstractValue safeType(InferrerEngine inferrer) {
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
    type = inferrer.abstractValueDomain.emptyType;
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

  String toStructuredText(String indent) {
    StringBuffer sb = new StringBuffer();
    _toStructuredText(sb, indent, new Set<TypeInformation>());
    return sb.toString();
  }

  void _toStructuredText(
      StringBuffer sb, String indent, Set<TypeInformation> seen) {
    sb.write(toString());
  }
}

abstract class ApplyableTypeInformation implements TypeInformation {
  bool mightBePassedToFunctionApply = false;
}

/// Marker node used only during tree construction but not during actual type
/// refinement.
///
/// Currently, this is used to give a type to an optional parameter even before
/// the corresponding default expression has been analyzed. See
/// [getDefaultTypeOfParameter] and [setDefaultTypeOfParameter] for details.
class PlaceholderTypeInformation extends TypeInformation {
  PlaceholderTypeInformation(
      AbstractValueDomain abstractValueDomain, MemberTypeInformation context)
      : super(abstractValueDomain.emptyType, context);

  void accept(TypeInformationVisitor visitor) {
    throw new UnsupportedError("Cannot visit placeholder");
  }

  AbstractValue computeType(InferrerEngine inferrer) {
    throw new UnsupportedError("Cannot refine placeholder");
  }

  toString() => "Placeholder [$hashCode]";
}

/// Parameters of instance functions behave differently than other
/// elements because the inferrer may remove assignments. This happens
/// when the receiver of a dynamic call site can be refined
/// to a type where we know more about which instance method is being
/// called.
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

/// A node representing a resolved element of the component. The kind of
/// elements that need an [ElementTypeInformation] are:
///
/// - Functions (including getters and setters)
/// - Constructors (factory or generative)
/// - Fields
/// - Parameters
/// - Local variables mutated in closures
///
/// The [ElementTypeInformation] of a function and a constructor is its
/// return type.
///
/// Note that a few elements of these kinds must be treated specially,
/// and they are dealt in [ElementTypeInformation.handleSpecialCases]:
///
/// - Parameters of closures, `noSuchMethod` and `call` instance
///   methods: we currently do not infer types for those.
///
/// - Fields and parameters being assigned by synthesized calls done by
///   the backend: we do not know what types the backend will use.
///
/// - Native functions and fields: because native methods contain no Dart
///   code, and native fields do not have Dart assignments, we just
///   trust their type annotation.
///
abstract class ElementTypeInformation extends TypeInformation {
  /// Marker to disable inference for closures in [handleSpecialCases].
  bool disableInferenceForClosures = true;

  ElementTypeInformation._internal(
      AbstractValueDomain abstractValueDomain, MemberTypeInformation context)
      : super(abstractValueDomain.emptyType, context);
  ElementTypeInformation._withAssignments(
      AbstractValueDomain abstractValueDomain,
      MemberTypeInformation context,
      ParameterAssignments assignments)
      : super.withAssignments(
            abstractValueDomain.emptyType, context, assignments);

  String getInferredSignature(TypeSystem types);

  String get debugName;
}

/// A node representing members in the broadest sense:
///
/// - Functions
/// - Constructors
/// - Fields (also synthetic ones due to closures)
/// - Local functions (closures)
///
/// These should never be created directly but instead are constructed by
/// the [ElementTypeInformation] factory.
abstract class MemberTypeInformation extends ElementTypeInformation
    with ApplyableTypeInformation {
  final MemberEntity _member;

  /// If [element] is a function, [closurizedCount] is the number of
  /// times it is closurized. The value gets updated while inferring.
  int closurizedCount = 0;

  // Strict `bool` value is computed in cleanup(). Also used as a flag to see if
  // cleanup has been called.
  bool _isCalledOnce = null;

  /// This map contains the callers of [element]. It stores all unique call
  /// sites to enable counting the global number of call sites of [element].
  ///
  /// A call site is either an AST [ast.Node], an [Element] (see uses of
  /// [synthesizeForwardingCall] in [SimpleTypeInferrerVisitor]) or an IR
  /// [ir.Node].
  ///
  /// The global information is summarized in [cleanup], after which [_callers]
  /// is set to `null`.
  Map<MemberEntity, Setlet<Object>> _callers;

  MemberTypeInformation._internal(
      AbstractValueDomain abstractValueDomain, this._member)
      : super._internal(abstractValueDomain, null);

  MemberEntity get member => _member;

  String get debugName => '$member';

  void addCall(MemberEntity caller, Object node) {
    _callers ??= <MemberEntity, Setlet<Object>>{};
    _callers.putIfAbsent(caller, () => new Setlet()).add(node);
  }

  void removeCall(MemberEntity caller, Object node) {
    if (_callers == null) return;
    Setlet calls = _callers[caller];
    if (calls == null) return;
    calls.remove(node);
    if (calls.isEmpty) {
      _callers.remove(caller);
    }
  }

  Iterable<MemberEntity> get callersForTesting {
    return _callers?.keys;
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

  void computeIsCalledOnce() {
    assert(_isCalledOnce == null, "isCalledOnce has already been computed.");
    _isCalledOnce = _computeIsCalledOnce();
  }

  bool get isClosurized => closurizedCount > 0;

  // Closurized methods never become stable to ensure that the information in
  // [users] is accurate. The inference stops tracking users for stable types.
  // Note that we only override the getter, the setter will still modify the
  // state of the [isStable] field inherited from [TypeInformation].
  bool get isStable => super.isStable && !isClosurized;

  AbstractValue handleSpecialCases(InferrerEngine inferrer);

  AbstractValue _handleFunctionCase(
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

  AbstractValue potentiallyNarrowType(
      AbstractValue mask, InferrerEngine inferrer) {
    if (inferrer.options.assignmentCheckPolicy.isTrusted ||
        inferrer.options.assignmentCheckPolicy.isEmitted) {
      return _potentiallyNarrowType(mask, inferrer);
    }
    return mask;
  }

  AbstractValue _potentiallyNarrowType(
      AbstractValue mask, InferrerEngine inferrer);

  AbstractValue computeType(InferrerEngine inferrer) {
    AbstractValue special = handleSpecialCases(inferrer);
    if (special != null) return potentiallyNarrowType(special, inferrer);
    return potentiallyNarrowType(
        inferrer.types.computeTypeMask(assignments), inferrer);
  }

  AbstractValue safeType(InferrerEngine inferrer) {
    return potentiallyNarrowType(super.safeType(inferrer), inferrer);
  }

  String toString() => 'Member $_member $type';

  accept(TypeInformationVisitor visitor) {
    return visitor.visitMemberTypeInformation(this);
  }

  void cleanup() {
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

  FieldTypeInformation(
      AbstractValueDomain abstractValueDomain, FieldEntity element, this._type)
      : super._internal(abstractValueDomain, element);

  AbstractValue handleSpecialCases(InferrerEngine inferrer) {
    if (!inferrer.canFieldBeUsedForGlobalOptimizations(_field) ||
        inferrer.assumeDynamic(_field)) {
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

  AbstractValue _potentiallyNarrowType(
      AbstractValue mask, InferrerEngine inferrer) {
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

  GetterTypeInformation(AbstractValueDomain abstractValueDomain,
      FunctionEntity element, this._type)
      : super._internal(abstractValueDomain, element);

  AbstractValue handleSpecialCases(InferrerEngine inferrer) {
    return _handleFunctionCase(_getter, inferrer);
  }

  AbstractValue _potentiallyNarrowType(
      AbstractValue mask, InferrerEngine inferrer) {
    return _narrowType(inferrer.closedWorld, mask, _type.returnType);
  }
}

class SetterTypeInformation extends MemberTypeInformation {
  FunctionEntity get _setter => _member;

  SetterTypeInformation(
      AbstractValueDomain abstractValueDomain, FunctionEntity element)
      : super._internal(abstractValueDomain, element);

  AbstractValue handleSpecialCases(InferrerEngine inferrer) {
    return _handleFunctionCase(_setter, inferrer);
  }

  AbstractValue _potentiallyNarrowType(
      AbstractValue mask, InferrerEngine inferrer) {
    return mask;
  }
}

class MethodTypeInformation extends MemberTypeInformation {
  FunctionEntity get _method => _member;
  final FunctionType _type;

  MethodTypeInformation(AbstractValueDomain abstractValueDomain,
      FunctionEntity element, this._type)
      : super._internal(abstractValueDomain, element);

  AbstractValue handleSpecialCases(InferrerEngine inferrer) {
    return _handleFunctionCase(_method, inferrer);
  }

  AbstractValue _potentiallyNarrowType(
      AbstractValue mask, InferrerEngine inferrer) {
    return _narrowType(inferrer.closedWorld, mask, _type.returnType);
  }

  bool hasStableType(InferrerEngine inferrer) => false;
}

class FactoryConstructorTypeInformation extends MemberTypeInformation {
  ConstructorEntity get _constructor => _member;
  final FunctionType _type;

  FactoryConstructorTypeInformation(AbstractValueDomain abstractValueDomain,
      ConstructorEntity element, this._type)
      : super._internal(abstractValueDomain, element);

  AbstractValue handleSpecialCases(InferrerEngine inferrer) {
    AbstractValueDomain abstractValueDomain = inferrer.abstractValueDomain;
    if (_constructor.isFromEnvironmentConstructor) {
      if (_constructor.enclosingClass == inferrer.commonElements.intClass) {
        giveUp(inferrer);
        return abstractValueDomain.includeNull(abstractValueDomain.intType);
      } else if (_constructor.enclosingClass ==
          inferrer.commonElements.boolClass) {
        giveUp(inferrer);
        return abstractValueDomain.includeNull(abstractValueDomain.boolType);
      } else if (_constructor.enclosingClass ==
          inferrer.commonElements.stringClass) {
        giveUp(inferrer);
        return abstractValueDomain.includeNull(abstractValueDomain.stringType);
      }
    }
    return _handleFunctionCase(_constructor, inferrer);
  }

  AbstractValue _potentiallyNarrowType(
      AbstractValue mask, InferrerEngine inferrer) {
    return _narrowType(inferrer.closedWorld, mask, _type.returnType);
  }

  bool hasStableType(InferrerEngine inferrer) {
    return super.hasStableType(inferrer);
  }
}

class GenerativeConstructorTypeInformation extends MemberTypeInformation {
  ConstructorEntity get _constructor => _member;

  GenerativeConstructorTypeInformation(
      AbstractValueDomain abstractValueDomain, ConstructorEntity element)
      : super._internal(abstractValueDomain, element);

  AbstractValue handleSpecialCases(InferrerEngine inferrer) {
    return _handleFunctionCase(_constructor, inferrer);
  }

  AbstractValue _potentiallyNarrowType(
      AbstractValue mask, InferrerEngine inferrer) {
    return mask;
  }

  bool hasStableType(InferrerEngine inferrer) {
    return super.hasStableType(inferrer);
  }
}

/// A node representing parameters:
///
/// - Parameters
/// - Initializing formals
///
/// These should never be created directly but instead are constructed by
/// the [ElementTypeInformation] factory.
class ParameterTypeInformation extends ElementTypeInformation {
  final Local _parameter;
  final DartType _type;
  final FunctionEntity _method;
  final bool _isInstanceMemberParameter;
  final bool _isClosureParameter;
  final bool _isInitializingFormal;
  bool _isTearOffClosureParameter = false;

  ParameterTypeInformation.localFunction(
      AbstractValueDomain abstractValueDomain,
      MemberTypeInformation context,
      this._parameter,
      this._type,
      this._method)
      : _isInstanceMemberParameter = false,
        _isClosureParameter = true,
        _isInitializingFormal = false,
        super._internal(abstractValueDomain, context);

  ParameterTypeInformation.static(AbstractValueDomain abstractValueDomain,
      MemberTypeInformation context, this._parameter, this._type, this._method,
      {bool isInitializingFormal: false})
      : _isInstanceMemberParameter = false,
        _isClosureParameter = false,
        _isInitializingFormal = isInitializingFormal,
        super._internal(abstractValueDomain, context);

  ParameterTypeInformation.instanceMember(
      AbstractValueDomain abstractValueDomain,
      MemberTypeInformation context,
      this._parameter,
      this._type,
      this._method,
      ParameterAssignments assignments)
      : _isInstanceMemberParameter = true,
        _isClosureParameter = false,
        _isInitializingFormal = false,
        super._withAssignments(abstractValueDomain, context, assignments);

  FunctionEntity get method => _method;

  Local get parameter => _parameter;

  bool get isRegularParameter => !_isInitializingFormal;

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
  AbstractValue handleSpecialCases(InferrerEngine inferrer) {
    if (!inferrer.canFunctionParametersBeUsedForGlobalOptimizations(_method) ||
        inferrer.assumeDynamic(_method)) {
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
    if (inferrer.inferredDataBuilder
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

  AbstractValue potentiallyNarrowType(
      AbstractValue mask, InferrerEngine inferrer) {
    if (inferrer.options.parameterCheckPolicy.isTrusted) {
      // In checked or strong mode we don't trust the types of the arguments
      // passed to a parameter. The means that the checking of a parameter is
      // based on the actual arguments.
      //
      // With --trust-type-annotations or --omit-implicit-checks we _do_ trust
      // the arguments passed to a parameter - and we never check them.
      //
      // In all these cases we _do_ trust the static type of a parameter within
      // the method itself. For instance:
      //
      //     method(int i) => i;
      //     main() {
      //       dynamic f = method;
      //       f(0); // valid call
      //       f(''); // invalid call
      //     }
      //
      // Here, in all cases, we infer the returned value of `method` to be an
      // `int`. In checked and strong mode we infer the parameter of `method` to
      // be either `int` or `String` and therefore insert a check at the entry
      // of 'method'. With --trust-type-annotations or --omit-implicit-checks we
      // (unsoundly) infer the parameter to be `int` and leave the parameter
      // unchecked, and `method` will at runtime actually return a `String` from
      // the second invocation.
      //
      // The trusting of the parameter types within the body of the method is
      // is done through `LocalsHandler.update` called in
      // `KernelTypeGraphBuilder.handleParameter`.
      return _narrowType(inferrer.closedWorld, mask, _type);
    }
    return mask;
  }

  AbstractValue computeType(InferrerEngine inferrer) {
    AbstractValue special = handleSpecialCases(inferrer);
    if (special != null) return special;
    return potentiallyNarrowType(
        inferrer.types.computeTypeMask(assignments), inferrer);
  }

  AbstractValue safeType(InferrerEngine inferrer) {
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
  forIn,
}

bool validCallType(CallType callType, Object call) {
  switch (callType) {
    case CallType.access:
      return call is ir.Node;
    case CallType.forIn:
      return call is ir.ForInStatement;
  }
  throw new StateError('Unexpected call type $callType.');
}

/// A [CallSiteTypeInformation] is a call found in the AST, or a
/// synthesized call for implicit calls in Dart (such as forwarding
/// factories). The [_call] field is a [ast.Node] for the former, and an
/// [Element] for the latter.
///
/// In the inferrer graph, [CallSiteTypeInformation] nodes do not have
/// any assignment. They rely on the [caller] field for static calls,
/// and [selector] and [receiver] fields for dynamic calls.
abstract class CallSiteTypeInformation extends TypeInformation
    with ApplyableTypeInformation {
  final Object _call;
  final MemberEntity caller;
  final Selector selector;
  final AbstractValue mask;
  final ArgumentsTypes arguments;
  final bool inLoop;

  CallSiteTypeInformation(
      AbstractValueDomain abstractValueDomain,
      MemberTypeInformation context,
      this._call,
      this.caller,
      this.selector,
      this.mask,
      this.arguments,
      this.inLoop)
      : super.noAssignments(abstractValueDomain.emptyType, context) {
    assert(_call is ir.Node);
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
      AbstractValueDomain abstractValueDomain,
      MemberTypeInformation context,
      Object call,
      MemberEntity enclosing,
      this.calledElement,
      Selector selector,
      AbstractValue mask,
      ArgumentsTypes arguments,
      bool inLoop)
      : super(abstractValueDomain, context, call, enclosing, selector, mask,
            arguments, inLoop);

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

  AbstractValue computeType(InferrerEngine inferrer) {
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
  bool _hasClosureCallTargets;

  /// Cached concrete targets of this call.
  Iterable<MemberEntity> _concreteTargets;

  DynamicCallSiteTypeInformation(
      AbstractValueDomain abstractValueDomain,
      MemberTypeInformation context,
      this._callType,
      T call,
      MemberEntity enclosing,
      Selector selector,
      AbstractValue mask,
      this.receiver,
      ArgumentsTypes arguments,
      bool inLoop,
      this.isConditional)
      : super(abstractValueDomain, context, call, enclosing, selector, mask,
            arguments, inLoop) {
    assert(validCallType(_callType, _call));
  }

  void addToGraph(InferrerEngine inferrer) {
    assert(receiver != null);
    AbstractValue typeMask = computeTypedSelector(inferrer);
    _hasClosureCallTargets =
        inferrer.closedWorld.includesClosureCall(selector, typeMask);
    _concreteTargets = inferrer.closedWorld.locateMembers(selector, typeMask);
    receiver.addUser(this);
    if (arguments != null) {
      arguments.forEach((info) => info.addUser(this));
    }
    for (MemberEntity element in _concreteTargets) {
      MemberTypeInformation callee =
          inferrer.types.getInferredTypeOfMember(element);
      callee.addCall(caller, _call);
      callee.addUser(this);
      inferrer.updateParameterAssignments(
          this, element, arguments, selector, typeMask,
          remove: false, addToQueue: false);
    }
  }

  /// `true` if this invocation can hit a 'call' method on a closure.
  bool get hasClosureCallTargets => _hasClosureCallTargets;

  /// All concrete targets of this invocation. If [hasClosureCallTargets] is
  /// `true` the invocation can additional target an unknown set of 'call'
  /// methods on closures.
  Iterable<MemberEntity> get concreteTargets => _concreteTargets;

  Iterable<MemberEntity> get callees => _concreteTargets;

  AbstractValue computeTypedSelector(InferrerEngine inferrer) {
    AbstractValue receiverType = receiver.type;

    if (mask != receiverType) {
      return receiverType == inferrer.abstractValueDomain.dynamicType
          ? null
          : receiverType;
    } else {
      return mask;
    }
  }

  bool targetsIncludeComplexNoSuchMethod(InferrerEngine inferrer) {
    return _concreteTargets.any((MemberEntity e) {
      return e.isFunction &&
          e.isInstanceMember &&
          e.name == Identifiers.noSuchMethod_ &&
          inferrer.noSuchMethodData.isComplex(e);
    });
  }

  /// We optimize certain operations on the [int] class because we know more
  /// about their return type than the actual Dart code. For example, we know
  /// int + int returns an int. The Dart library code for [int.operator+] only
  /// says it returns a [num].
  ///
  /// Returns the more precise TypeInformation, or `null` to defer to the
  /// library code.
  TypeInformation handleIntrisifiedSelector(
      Selector selector, AbstractValue mask, InferrerEngine inferrer) {
    JClosedWorld closedWorld = inferrer.closedWorld;
    if (mask == null) return null;
    if (inferrer.abstractValueDomain.isIntegerOrNull(mask).isPotentiallyFalse) {
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

  AbstractValue computeType(InferrerEngine inferrer) {
    JClosedWorld closedWorld = inferrer.closedWorld;
    AbstractValueDomain abstractValueDomain = closedWorld.abstractValueDomain;
    Iterable<MemberEntity> oldTargets = _concreteTargets;
    AbstractValue typeMask = computeTypedSelector(inferrer);
    inferrer.updateSelectorInMember(
        caller, _callType, _call, selector, typeMask);

    _hasClosureCallTargets =
        closedWorld.includesClosureCall(selector, typeMask);
    _concreteTargets = closedWorld.locateMembers(selector, typeMask);

    // Update the call graph if the targets could have changed.
    if (!identical(_concreteTargets, oldTargets)) {
      // Add calls to new targets to the graph.
      _concreteTargets
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
          .where((target) => !_concreteTargets.contains(target))
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
    AbstractValue result;
    if (_hasClosureCallTargets) {
      result = abstractValueDomain.dynamicType;
    } else {
      result = inferrer.types
          .joinTypeMasks(_concreteTargets.map((MemberEntity element) {
        if (inferrer.returnsListElementType(selector, typeMask)) {
          return abstractValueDomain.getContainerElementType(receiver.type);
        } else if (inferrer.returnsMapValueType(selector, typeMask)) {
          if (abstractValueDomain.isDictionary(typeMask)) {
            AbstractValue arg = arguments.positional[0].type;
            ConstantValue value = abstractValueDomain.getPrimitiveValue(arg);
            if (value is StringConstantValue) {
              String key = value.stringValue;
              if (abstractValueDomain.containsDictionaryKey(typeMask, key)) {
                if (debug.VERBOSE) {
                  print("Dictionary lookup for $key yields "
                      "${abstractValueDomain.getDictionaryValueForKey(typeMask, key)}.");
                }
                return abstractValueDomain.getDictionaryValueForKey(
                    typeMask, key);
              } else {
                // The typeMap is precise, so if we do not find the key, the
                // lookup will be [null] at runtime.
                if (debug.VERBOSE) {
                  print("Dictionary lookup for $key yields [null].");
                }
                return inferrer.types.nullType.type;
              }
            }
          }
          assert(abstractValueDomain.isMap(typeMask));
          if (debug.VERBOSE) {
            print("Map lookup for $selector yields "
                "${abstractValueDomain.getMapValueType(typeMask)}.");
          }
          return abstractValueDomain.getMapValueType(typeMask);
        } else {
          TypeInformation info =
              handleIntrisifiedSelector(selector, typeMask, inferrer);
          if (info != null) return info.type;
          return inferrer.typeOfMemberWithSelector(element, selector).type;
        }
      }));
    }
    if (isConditional &&
        abstractValueDomain.isNull(receiver.type).isPotentiallyTrue) {
      // Conditional call sites (e.g. `a?.b`) may be null if the receiver is
      // null.
      result = abstractValueDomain.includeNull(result);
    }
    return result;
  }

  void giveUp(InferrerEngine inferrer, {bool clearAssignments: true}) {
    if (!abandonInferencing) {
      inferrer.updateSelectorInMember(caller, _callType, _call, selector, mask);
      Iterable<MemberEntity> oldTargets = _concreteTargets;
      _hasClosureCallTargets =
          inferrer.closedWorld.includesClosureCall(selector, mask);
      _concreteTargets = inferrer.closedWorld.locateMembers(selector, mask);
      for (MemberEntity element in _concreteTargets) {
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
    for (MemberEntity element in _concreteTargets) {
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
        _concreteTargets.every((MemberEntity element) =>
            inferrer.types.getInferredTypeOfMember(element).isStable) &&
        (arguments == null || arguments.every((info) => info.isStable)) &&
        super.hasStableType(inferrer);
  }
}

class ClosureCallSiteTypeInformation extends CallSiteTypeInformation {
  final TypeInformation closure;

  ClosureCallSiteTypeInformation(
      AbstractValueDomain abstractValueDomain,
      MemberTypeInformation context,
      Object call,
      MemberEntity enclosing,
      Selector selector,
      AbstractValue mask,
      this.closure,
      ArgumentsTypes arguments,
      bool inLoop)
      : super(abstractValueDomain, context, call, enclosing, selector, mask,
            arguments, inLoop);

  void addToGraph(InferrerEngine inferrer) {
    arguments.forEach((info) => info.addUser(this));
    closure.addUser(this);
  }

  AbstractValue computeType(InferrerEngine inferrer) => safeType(inferrer);

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

/// A [ConcreteTypeInformation] represents a type that needed
/// to be materialized during the creation of the graph. For example,
/// literals, [:this:] or [:super:] need a [ConcreteTypeInformation].
///
/// [ConcreteTypeInformation] nodes have no assignment. Also, to save
/// on memory, we do not add users to [ConcreteTypeInformation] nodes,
/// because we know such node will never be refined to a different
/// type.
class ConcreteTypeInformation extends TypeInformation {
  ConcreteTypeInformation(AbstractValue type) : super.untracked(type) {
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

  AbstractValue computeType(InferrerEngine inferrer) => type;

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

  StringLiteralTypeInformation(
      AbstractValueDomain abstractValueDomain, this.value, AbstractValue mask)
      : super(abstractValueDomain.createPrimitiveValue(
            mask, new StringConstantValue(value)));

  String asString() => value;
  String toString() => 'Type $type value ${value}';

  accept(TypeInformationVisitor visitor) {
    return visitor.visitStringLiteralTypeInformation(this);
  }
}

class BoolLiteralTypeInformation extends ConcreteTypeInformation {
  final bool value;

  BoolLiteralTypeInformation(
      AbstractValueDomain abstractValueDomain, this.value, AbstractValue mask)
      : super(abstractValueDomain.createPrimitiveValue(
            mask, value ? new TrueConstantValue() : new FalseConstantValue()));

  String toString() => 'Type $type value ${value}';

  accept(TypeInformationVisitor visitor) {
    return visitor.visitBoolLiteralTypeInformation(this);
  }
}

/// A [NarrowTypeInformation] narrows a [TypeInformation] to a type,
/// represented in [typeAnnotation].
///
/// A [NarrowTypeInformation] node has only one assignment: the
/// [TypeInformation] it narrows.
///
/// [NarrowTypeInformation] nodes are created for:
///
/// - Code after `is` and `as` checks, where we have more information
///   on the type of the right hand side of the expression.
///
/// - Code after a dynamic call, where we have more information on the
///   type of the receiver: it can only be of a class that holds a
///   potential target of this dynamic call.
///
/// - In checked mode, after a type annotation, we have more
///   information on the type of a local.
class NarrowTypeInformation extends TypeInformation {
  final AbstractValue typeAnnotation;

  NarrowTypeInformation(AbstractValueDomain abstractValueDomain,
      TypeInformation narrowedType, this.typeAnnotation)
      : super(abstractValueDomain.emptyType, narrowedType.context) {
    addAssignment(narrowedType);
  }

  addAssignment(TypeInformation info) {
    super.addAssignment(info);
    assert(assignments.length == 1);
  }

  AbstractValue computeType(InferrerEngine inferrer) {
    AbstractValueDomain abstractValueDomain = inferrer.abstractValueDomain;
    AbstractValue input = assignments.first.type;
    AbstractValue intersection =
        abstractValueDomain.intersection(input, typeAnnotation);
    if (debug.ANOMALY_WARN) {
      if (abstractValueDomain.contains(input, intersection).isDefinitelyFalse ||
          abstractValueDomain
              .contains(typeAnnotation, intersection)
              .isDefinitelyFalse) {
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

/// An [InferredTypeInformation] is a [TypeInformation] that
/// defaults to the dynamic type until it is marked as being
/// inferred, at which point it computes its type based on
/// its assignments.
abstract class InferredTypeInformation extends TypeInformation {
  /// Whether the element type in that container has been inferred.
  bool inferred = false;

  InferredTypeInformation(AbstractValueDomain abstractValueDomain,
      MemberTypeInformation context, TypeInformation parentType)
      : super(abstractValueDomain.emptyType, context) {
    if (parentType != null) addAssignment(parentType);
  }

  AbstractValue computeType(InferrerEngine inferrer) {
    if (!inferred) return safeType(inferrer);
    return inferrer.types.computeTypeMask(assignments);
  }

  bool hasStableType(InferrerEngine inferrer) {
    return inferred && super.hasStableType(inferrer);
  }
}

/// A [ListTypeInformation] is a [TypeInformation] created
/// for each `List` instantiations.
class ListTypeInformation extends TypeInformation with TracedTypeInformation {
  final ElementInContainerTypeInformation elementType;

  /// The container type before it is inferred.
  final AbstractValue originalType;

  /// The length at the allocation site.
  final int originalLength;

  /// The length after the container has been traced.
  int inferredLength;

  /// Whether this list goes through a growable check.
  /// We conservatively assume it does.
  bool checksGrowable = true;

  ListTypeInformation(
      AbstractValueDomain abstractValueDomain,
      MemberTypeInformation context,
      this.originalType,
      this.elementType,
      this.originalLength)
      : super(originalType, context) {
    inferredLength = abstractValueDomain.getContainerLength(originalType);
    elementType.addUser(this);
  }

  String toString() => 'List type $type';

  accept(TypeInformationVisitor visitor) {
    return visitor.visitListTypeInformation(this);
  }

  bool hasStableType(InferrerEngine inferrer) {
    return elementType.isStable && super.hasStableType(inferrer);
  }

  AbstractValue computeType(InferrerEngine inferrer) {
    AbstractValueDomain abstractValueDomain = inferrer.abstractValueDomain;
    AbstractValue mask = type;
    if (!abstractValueDomain.isContainer(type) ||
        abstractValueDomain.getContainerElementType(type) != elementType.type ||
        abstractValueDomain.getContainerLength(type) != inferredLength) {
      return abstractValueDomain.createContainerValue(
          abstractValueDomain.getGeneralization(originalType),
          abstractValueDomain.getAllocationNode(originalType),
          abstractValueDomain.getAllocationElement(originalType),
          elementType.type,
          inferredLength);
    }
    return mask;
  }

  AbstractValue safeType(InferrerEngine inferrer) => originalType;

  void cleanup() {
    super.cleanup();
    elementType.cleanup();
    _flowsInto = null;
  }
}

/// An [ElementInContainerTypeInformation] holds the common type of the
/// elements in a [ListTypeInformation].
class ElementInContainerTypeInformation extends InferredTypeInformation {
  ElementInContainerTypeInformation(AbstractValueDomain abstractValueDomain,
      MemberTypeInformation context, elementType)
      : super(abstractValueDomain, context, elementType);

  String toString() => 'Element in container $type';

  accept(TypeInformationVisitor visitor) {
    return visitor.visitElementInContainerTypeInformation(this);
  }
}

/// A [MapTypeInformation] is a [TypeInformation] created
/// for maps.
class MapTypeInformation extends TypeInformation with TracedTypeInformation {
  // When in Dictionary mode, this map tracks the type of the values that
  // have been assigned to a specific [String] key.
  final Map<String, ValueInMapTypeInformation> typeInfoMap = {};
  // These fields track the overall type of the keys/values in the map.
  final KeyInMapTypeInformation keyType;
  final ValueInMapTypeInformation valueType;
  final AbstractValue originalType;

  // Set to false if a statically unknown key flows into this map.
  bool _allKeysAreStrings = true;

  bool get inDictionaryMode => !bailedOut && _allKeysAreStrings;

  MapTypeInformation(MemberTypeInformation context, this.originalType,
      this.keyType, this.valueType)
      : super(originalType, context) {
    keyType.addUser(this);
    valueType.addUser(this);
  }

  TypeInformation addEntryAssignment(AbstractValueDomain abstractValueDomain,
      TypeInformation key, TypeInformation value,
      [bool nonNull = false]) {
    TypeInformation newInfo = null;
    if (_allKeysAreStrings && key is StringLiteralTypeInformation) {
      String keyString = key.asString();
      typeInfoMap.putIfAbsent(keyString, () {
        newInfo = new ValueInMapTypeInformation(
            abstractValueDomain, context, null, nonNull);
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

  List<TypeInformation> addMapAssignment(
      AbstractValueDomain abstractValueDomain, MapTypeInformation other) {
    List<TypeInformation> newInfos = <TypeInformation>[];
    if (_allKeysAreStrings && other.inDictionaryMode) {
      other.typeInfoMap.forEach((keyString, value) {
        typeInfoMap.putIfAbsent(keyString, () {
          TypeInformation newInfo = new ValueInMapTypeInformation(
              abstractValueDomain, context, null, false);
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

  AbstractValue toTypeMask(InferrerEngine inferrer) {
    AbstractValueDomain abstractValueDomain = inferrer.abstractValueDomain;
    if (inDictionaryMode) {
      Map<String, AbstractValue> mappings = new Map<String, AbstractValue>();
      for (var key in typeInfoMap.keys) {
        mappings[key] = typeInfoMap[key].type;
      }
      return inferrer.abstractValueDomain.createDictionaryValue(
          abstractValueDomain.getGeneralization(originalType),
          abstractValueDomain.getAllocationNode(originalType),
          abstractValueDomain.getAllocationElement(originalType),
          keyType.type,
          valueType.type,
          mappings);
    } else {
      return inferrer.abstractValueDomain.createMapValue(
          abstractValueDomain.getGeneralization(originalType),
          abstractValueDomain.getAllocationNode(originalType),
          abstractValueDomain.getAllocationElement(originalType),
          keyType.type,
          valueType.type);
    }
  }

  AbstractValue computeType(InferrerEngine inferrer) {
    AbstractValueDomain abstractValueDomain = inferrer.abstractValueDomain;
    if (abstractValueDomain.isDictionary(type) != inDictionaryMode) {
      return toTypeMask(inferrer);
    } else if (abstractValueDomain.isDictionary(type)) {
      assert(inDictionaryMode);
      for (String key in typeInfoMap.keys) {
        TypeInformation value = typeInfoMap[key];
        if (!abstractValueDomain.containsDictionaryKey(type, key) &&
            abstractValueDomain.containsAll(value.type).isDefinitelyFalse &&
            abstractValueDomain.isNull(value.type).isDefinitelyFalse) {
          return toTypeMask(inferrer);
        }
        if (abstractValueDomain.getDictionaryValueForKey(type, key) !=
            typeInfoMap[key].type) {
          return toTypeMask(inferrer);
        }
      }
    } else if (abstractValueDomain.isMap(type)) {
      if (abstractValueDomain.getMapKeyType(type) != keyType.type ||
          abstractValueDomain.getMapValueType(type) != valueType.type) {
        return toTypeMask(inferrer);
      }
    } else {
      return toTypeMask(inferrer);
    }

    return type;
  }

  AbstractValue safeType(InferrerEngine inferrer) => originalType;

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

/// A [KeyInMapTypeInformation] holds the common type
/// for the keys in a [MapTypeInformation]
class KeyInMapTypeInformation extends InferredTypeInformation {
  KeyInMapTypeInformation(AbstractValueDomain abstractValueDomain,
      MemberTypeInformation context, TypeInformation keyType)
      : super(abstractValueDomain, context, keyType);

  accept(TypeInformationVisitor visitor) {
    return visitor.visitKeyInMapTypeInformation(this);
  }

  String toString() => 'Key in Map $type';
}

/// A [ValueInMapTypeInformation] holds the common type
/// for the values in a [MapTypeInformation]
class ValueInMapTypeInformation extends InferredTypeInformation {
  // [nonNull] is set to true if this value is known to be part of the map.
  // Note that only values assigned to a specific key value in dictionary
  // mode can ever be marked as [nonNull].
  final bool nonNull;

  ValueInMapTypeInformation(AbstractValueDomain abstractValueDomain,
      MemberTypeInformation context, TypeInformation valueType,
      [this.nonNull = false])
      : super(abstractValueDomain, context, valueType);

  accept(TypeInformationVisitor visitor) {
    return visitor.visitValueInMapTypeInformation(this);
  }

  AbstractValue computeType(InferrerEngine inferrer) {
    return nonNull
        ? super.computeType(inferrer)
        : inferrer.abstractValueDomain.includeNull(super.computeType(inferrer));
  }

  String toString() => 'Value in Map $type';
}

/// A [PhiElementTypeInformation] is an union of
/// [ElementTypeInformation], that is local to a method.
class PhiElementTypeInformation extends TypeInformation {
  final ir.Node branchNode;
  final Local variable;
  final bool isTry;

  PhiElementTypeInformation(AbstractValueDomain abstractValueDomain,
      MemberTypeInformation context, this.branchNode, this.variable,
      {this.isTry})
      : super(abstractValueDomain.emptyType, context);

  AbstractValue computeType(InferrerEngine inferrer) {
    return inferrer.types.computeTypeMask(assignments);
  }

  String toString() => 'Phi($hashCode) $variable $type';

  void _toStructuredText(
      StringBuffer sb, String indent, Set<TypeInformation> seen) {
    if (seen.add(this)) {
      sb.write('${toString()} [');
      for (TypeInformation assignment in assignments) {
        sb.write('\n$indent  ');
        assignment._toStructuredText(sb, '$indent  ', seen);
      }
      sb.write(' ]');
    } else {
      sb.write('${toString()} [ ... ]');
    }
  }

  accept(TypeInformationVisitor visitor) {
    return visitor.visitPhiElementTypeInformation(this);
  }
}

class ClosureTypeInformation extends TypeInformation
    with ApplyableTypeInformation {
  final FunctionEntity _element;

  ClosureTypeInformation(AbstractValueDomain abstractValueDomain,
      MemberTypeInformation context, this._element)
      : super(abstractValueDomain.emptyType, context);

  FunctionEntity get closure => _element;

  AbstractValue computeType(InferrerEngine inferrer) => safeType(inferrer);

  AbstractValue safeType(InferrerEngine inferrer) {
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

/// Mixin for [TypeInformation] nodes that can bail out during tracing.
abstract class TracedTypeInformation implements TypeInformation {
  /// Set to false once analysis has succeeded.
  bool bailedOut = true;

  /// Set to true once analysis is completed.
  bool analyzed = false;

  Set<TypeInformation> _flowsInto;

  /// The set of [TypeInformation] nodes where values from the traced node could
  /// flow in.
  Set<TypeInformation> get flowsInto {
    return (_flowsInto == null)
        ? const ImmutableEmptySet<TypeInformation>()
        : _flowsInto;
  }

  /// Adds [nodes] to the sets of values this [TracedTypeInformation] flows
  /// into.
  void addFlowsIntoTargets(Iterable<TypeInformation> nodes) {
    if (_flowsInto == null) {
      _flowsInto = nodes.toSet();
    } else {
      _flowsInto.addAll(nodes);
    }
  }
}

class AwaitTypeInformation extends TypeInformation {
  final ir.Node _node;

  AwaitTypeInformation(AbstractValueDomain abstractValueDomain,
      MemberTypeInformation context, this._node)
      : super(abstractValueDomain.emptyType, context);

  // TODO(22894): Compute a better type here.
  AbstractValue computeType(InferrerEngine inferrer) => safeType(inferrer);

  String get debugName => '$_node';

  String toString() => 'Await';

  accept(TypeInformationVisitor visitor) {
    return visitor.visitAwaitTypeInformation(this);
  }
}

class YieldTypeInformation extends TypeInformation {
  final ir.Node _node;

  YieldTypeInformation(AbstractValueDomain abstractValueDomain,
      MemberTypeInformation context, this._node)
      : super(abstractValueDomain.emptyType, context);

  AbstractValue computeType(InferrerEngine inferrer) => safeType(inferrer);

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

AbstractValue _narrowType(
    JClosedWorld closedWorld, AbstractValue type, DartType annotation,
    {bool isNullable: true}) {
  AbstractValueDomain abstractValueDomain = closedWorld.abstractValueDomain;
  AbstractValue otherType;
  if (annotation.treatAsDynamic) {
    return type;
  } else if (annotation.isInterfaceType) {
    InterfaceType interfaceType = annotation;
    if (interfaceType.element == closedWorld.commonElements.objectClass) {
      return type;
    }
    otherType = abstractValueDomain.createNonNullSubtype(interfaceType.element);
  } else if (annotation.isVoid) {
    return type;
  } else if (annotation.isTypedef || annotation.isFunctionType) {
    otherType = closedWorld.abstractValueDomain.functionType;
  } else if (annotation.isFutureOr) {
    // TODO(johnniwinther): Narrow FutureOr types.
    return type;
  } else {
    assert(annotation.isTypeVariable || annotation.isFunctionTypeVariable);
    // TODO(ngeoffray): Narrow to bound.
    return type;
  }
  if (isNullable) {
    otherType = abstractValueDomain.includeNull(otherType);
  }
  if (type == null) {
    return otherType;
  }
  return abstractValueDomain.intersection(type, otherType);
}
