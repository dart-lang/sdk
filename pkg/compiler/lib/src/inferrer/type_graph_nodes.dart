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
import '../js_model/js_world.dart' show JClosedWorld;
import '../universe/member_hierarchy.dart';
import '../universe/record_shape.dart' show RecordShape;
import '../universe/selector.dart' show Selector;
import '../util/compact_flags.dart';
import '../util/util.dart' show Setlet;
import 'abstract_value_domain.dart';
import 'debug.dart' as debug;
import 'engine.dart';
import 'locals_handler.dart' show ArgumentsTypes;
import 'type_system.dart';

/// Flags tracked through various subclasses of [TypeInformation]. All are
/// encoded on a single bitmask on each instance of [TypeInformation].
///
/// Note: The encoding also includes the `refineCount` for a node in the same
/// bitmask. If adding another flag here one must make sure `_MAX_CHANGE_COUNT`
/// on the [InferrerEngine] is less than 2^(64-N) where N is the number of
/// flags defined here.
enum _Flag {
  // ---Flags for [TypeInformation]---
  inQueue, // 0

  abandonInferencing, // 1

  doNotEnqueue, // 2

  isStable, // 3

  // ---Flags for [ElementTypeInformation]---
  enableInferenceForClosures, // 4

  // ---Flags for [ParameterTypeInformation]---
  isInstanceMemberParameter, // 5
  isClosureParameter, // 6
  isInitializingFormal, // 7
  isVirtual, // 8

  // ---Flags for [CallSiteTypeInformation]---
  inLoop, // 9

  // ---Flags for [DynamicCallSiteTypeInformation]---
  isConditional, // 10
  hasClosureCallTargets, // 11
  targetsIncludeComplexNoSuchMethod, // 12
  hasTargetsIncludeComplexNoSuchMethod, // 13

  // ---Flags for [PhiElementTypeInformation]---
  isTry, // 14

  // ---Flags for [ValueInMapTypeInformation]---
  valueInMapNonNull, // 15

  // ---Flags for [MemberTypeInformation]---
  isCalled, // 16
  isCalledMoreThanOnce, // 17

  // ---Flags for [ApplyableTypeInformation]---
  mightBePassedToFunctionApply, // 18

  // ---Flags for [InferredTypeInformation]---
  inferred, // 19

  // ---Flags for [TracedTypeInformation]---
  notBailedOut, // 20
  analyzed, // 21
}

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
/// A node has a set of inputs and users. Inputs are used to
/// compute the type of the node ([TypeInformation.computeType]). Users are
/// added to the inferrer's work queue when the type of the node
/// changes.
abstract class TypeInformation {
  // This will be treated as effectively constant by the VM.
  static final int NUM_TYPE_INFO_FLAGS = _Flag.values.length;

  Set<TypeInformation> users;
  ParameterInputs _inputs;

  /// The type the inferrer has found for this [TypeInformation].
  /// Initially empty.
  AbstractValue type;

  /// The graph node of the member this [TypeInformation] node belongs to.
  final MemberTypeInformation? context;

  /// The element this [TypeInformation] node belongs to.
  MemberEntity? get contextMember => context?.member;

  ParameterInputs get inputs => _inputs;

  /// We abandon inference in certain cases (complex cyclic flow, native
  /// behaviours, etc.). In some case, we might resume inference in the
  /// closure tracer, which is handled by checking whether [inputs] has
  /// been set to [STOP_TRACKING_INPUTS_MARKER].
  bool get abandonInferencing => _flags.hasFlag(_Flag.abandonInferencing);
  bool get mightResume => !identical(inputs, STOP_TRACKING_INPUTS_MARKER);

  /// Whether this [TypeInformation] is currently in the inferrer's
  /// work queue.
  bool get inQueue => _flags.hasFlag(_Flag.inQueue);
  set inQueue(bool value) => _flags = _flags.updateFlag(_Flag.inQueue, value);

  /// Used to disable enqueueing of type informations where we know that their
  /// type will not change for other reasons than being stable. For example,
  /// if inference is disabled for a type and it is hardwired to dynamic, this
  /// is set to true to spare recomputing dynamic again and again. Changing this
  /// to false should never change inference outcome, just make is slower.
  bool get doNotEnqueue => _flags.hasFlag(_Flag.doNotEnqueue);
  set doNotEnqueue(bool value) =>
      _flags = _flags.updateFlag(_Flag.doNotEnqueue, value);

  /// Whether this [TypeInformation] has a stable [type] that will not
  /// change.
  bool get isStable => _flags.hasFlag(_Flag.isStable);

  bool get isConcrete => false;

  TypeInformation(this.type, this.context)
      : _inputs = _BasicParameterInputs([]),
        users = Setlet<TypeInformation>();

  TypeInformation.noInputs(this.type, this.context)
      : _inputs = const _BasicParameterInputs([]),
        users = Setlet<TypeInformation>();

  TypeInformation.untracked(this.type)
      : _inputs = const _BasicParameterInputs([]),
        users = const {},
        context = null;

  TypeInformation.withInputs(this.type, this.context, this._inputs)
      : users = Setlet<TypeInformation>();

  CompactFlags _flags = emptyCompactFlags;

  /// Number of times this [TypeInformation] has changed type.
  int get refineCount => _flags >> NUM_TYPE_INFO_FLAGS;

  void incrementRefineCount() => _flags += (1 << NUM_TYPE_INFO_FLAGS);
  void clearRefineCount() => _flags &= ((1 << NUM_TYPE_INFO_FLAGS) - 1);

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
  static final STOP_TRACKING_INPUTS_MARKER =
      _BasicParameterInputs(List.empty());

  bool areInputsTracked() {
    return inputs != STOP_TRACKING_INPUTS_MARKER;
  }

  void addInput(TypeInformation input) {
    // Cheap one-level cycle detection.
    if (input == this) return;
    if (areInputsTracked()) {
      _inputs.add(input);
    }
    // Even if we abandon inferencing on this [TypeInformation] we
    // need to collect the users, so that phases that track where
    // elements flow in still work.
    input.addUser(this);
  }

  void removeInput(TypeInformation input) {
    if (!abandonInferencing || mightResume) {
      _inputs.remove(input);
    }
    // We can have multiple inputs of the same [TypeInformation].
    if (!inputs.contains(input)) {
      input.removeUser(this);
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

  void giveUp(InferrerEngine inferrer, {bool clearInputs = true}) {
    _flags = _flags.setFlag(_Flag.abandonInferencing);
    // Do not remove [this] as a user of nodes in [inputs],
    // because our tracing analysis could be interested in tracing
    // this node.
    if (clearInputs) _inputs = STOP_TRACKING_INPUTS_MARKER;
    // Do not remove users because our tracing analysis could be
    // interested in tracing the users of this node.
  }

  void clear() {
    _inputs = STOP_TRACKING_INPUTS_MARKER;
    users = const {};
  }

  /// Reset the analysis of this node by making its type empty.

  bool reset(InferrerEngine inferrer) {
    if (abandonInferencing) return false;
    type = inferrer.abstractValueDomain.uncomputedType;
    clearRefineCount();
    return true;
  }

  accept(TypeInformationVisitor visitor);

  /// The [Element] where this [TypeInformation] was created. May be `null`
  /// for some [TypeInformation] nodes, where we do not need to store
  /// the information.
  MemberEntity? get owner => (context != null) ? context?.member : null;

  /// Returns whether the type cannot change after it has been
  /// inferred.
  bool hasStableType(InferrerEngine inferrer) {
    return !mightResume && inputs.every((e) => e.isStable);
  }

  void removeAndClearReferences(InferrerEngine inferrer) {
    inputs.forEach((info) {
      info.removeUser(this);
    });
  }

  void stabilize(InferrerEngine inferrer) {
    removeAndClearReferences(inferrer);
    // Do not remove users because the tracing analysis could be interested
    // in tracing the users of this node.
    _inputs = STOP_TRACKING_INPUTS_MARKER;
    _flags = _flags.setFlag(_Flag.abandonInferencing);
    _flags = _flags.setFlag(_Flag.isStable);
  }

  void maybeResume() {
    if (!mightResume) return;
    _flags = _flags.clearFlag(_Flag.abandonInferencing);
    _flags = _flags.clearFlag(_Flag.doNotEnqueue);
  }

  /// Destroys information not needed after type inference.
  void cleanup() {
    users = const {};
    _inputs = const _BasicParameterInputs([]);
  }

  String toStructuredText(String indent) {
    StringBuffer sb = StringBuffer();
    _toStructuredText(sb, indent, Set<TypeInformation>());
    return sb.toString();
  }

  void _toStructuredText(
      StringBuffer sb, String indent, Set<TypeInformation> seen) {
    sb.write(toString());
  }
}

mixin ApplyableTypeInformation implements TypeInformation {
  bool get mightBePassedToFunctionApply =>
      _flags.hasFlag(_Flag.mightBePassedToFunctionApply);
  set mightBePassedToFunctionApply(bool value) =>
      _flags = _flags.updateFlag(_Flag.mightBePassedToFunctionApply, value);
}

/// Marker node used only during tree construction but not during actual type
/// refinement.
///
/// Currently, this is used to give a type to an optional parameter even before
/// the corresponding default expression has been analyzed. See
/// [getDefaultTypeOfParameter] and [setDefaultTypeOfParameter] for details.
class PlaceholderTypeInformation extends TypeInformation {
  PlaceholderTypeInformation(
      AbstractValueDomain abstractValueDomain, MemberTypeInformation? context)
      : super(abstractValueDomain.uncomputedType, context);

  @override
  void accept(TypeInformationVisitor visitor) {
    throw UnsupportedError("Cannot visit placeholder");
  }

  @override
  AbstractValue computeType(InferrerEngine inferrer) {
    throw UnsupportedError("Cannot refine placeholder");
  }

  @override
  toString() => "Placeholder [$hashCode]";
}

abstract class ParameterInputs implements Iterable<TypeInformation> {
  factory ParameterInputs.instanceMember() => _InstanceMemberParameterInputs();
  void add(TypeInformation input);
  void remove(TypeInformation input);
  void replace(TypeInformation old, TypeInformation replacement);
}

class _BasicParameterInputs extends IterableBase<TypeInformation>
    implements ParameterInputs {
  final List<TypeInformation> _baseList;

  const _BasicParameterInputs(this._baseList);

  @override
  void replace(TypeInformation old, TypeInformation replacement) {
    for (int i = 0; i < length; i++) {
      if (_baseList[i] == old) {
        _baseList[i] = replacement;
      }
    }
  }

  @override
  void add(TypeInformation input) => _baseList.add(input);

  @override
  Iterator<TypeInformation> get iterator => _baseList.iterator;

  @override
  void remove(TypeInformation input) => _baseList.remove(input);
}

/// Parameters of instance functions behave differently than other
/// elements because the inferrer may remove inputs. This happens
/// when the receiver of a dynamic call site can be refined
/// to a type where we know more about which instance method is being
/// called.
class _InstanceMemberParameterInputs extends IterableBase<TypeInformation>
    implements ParameterInputs {
  final Map<TypeInformation, int> _inputs = Map<TypeInformation, int>();

  @override
  void remove(TypeInformation info) {
    final existing = _inputs[info];
    if (existing == null) return;
    if (existing == 1) {
      _inputs.remove(info);
    } else {
      _inputs[info] = existing - 1;
    }
  }

  @override
  void add(TypeInformation info) {
    final existing = _inputs[info];
    if (existing == null) {
      _inputs[info] = 1;
    } else {
      _inputs[info] = existing + 1;
    }
  }

  @override
  void replace(TypeInformation old, TypeInformation replacement) {
    var existing = _inputs[old];
    if (existing != null) {
      final other = _inputs[replacement];
      if (other != null) existing += other;
      _inputs[replacement] = existing;
      _inputs.remove(old);
    }
  }

  @override
  Iterator<TypeInformation> get iterator => _inputs.keys.iterator;
  @override
  Iterable<TypeInformation> where(bool Function(TypeInformation) f) =>
      _inputs.keys.where(f);

  @override
  bool contains(Object? info) => _inputs.containsKey(info);

  @override
  String toString() => _inputs.keys.toList().toString();
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
  /// Since the default is enabled, encode this flag as the inverse.
  bool get disableInferenceForClosures =>
      !_flags.hasFlag(_Flag.enableInferenceForClosures);
  set disableInferenceForClosures(bool value) =>
      _flags = _flags.updateFlag(_Flag.enableInferenceForClosures, !value);

  ElementTypeInformation._internal(
      AbstractValueDomain abstractValueDomain, MemberTypeInformation? context)
      : super(abstractValueDomain.uncomputedType, context);

  ElementTypeInformation._withInputs(AbstractValueDomain abstractValueDomain,
      MemberTypeInformation? context, ParameterInputs inputs)
      : super.withInputs(abstractValueDomain.uncomputedType, context, inputs);

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

  // Updated during cleanup.
  bool get isCalledExactlyOnce =>
      _flags.hasFlag(_Flag.isCalled) &&
      !_flags.hasFlag(_Flag.isCalledMoreThanOnce);

  MemberTypeInformation._internal(
      AbstractValueDomain abstractValueDomain, this._member)
      : super._internal(abstractValueDomain, null);

  MemberEntity get member => _member;

  @override
  String get debugName => '$member';

  void markCalled() {
    if (_flags.hasFlag(_Flag.isCalled)) {
      if (!_flags.hasFlag(_Flag.isCalledMoreThanOnce)) {
        _flags = _flags.setFlag(_Flag.isCalledMoreThanOnce);
      }
    } else {
      _flags = _flags.setFlag(_Flag.isCalled);
    }
  }

  bool get isClosurized => closurizedCount > 0;

  // Closurized methods never become stable to ensure that the information in
  // [users] is accurate. The inference stops tracking users for stable types.
  // Note that we only override the getter, the setter will still modify the
  // state of the [isStable] field inherited from [TypeInformation].
  @override
  bool get isStable => super.isStable && !isClosurized;

  AbstractValue? handleSpecialCases(InferrerEngine inferrer);

  AbstractValue? _handleFunctionCase(
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

    if (inferrer.commonElements.isIsJsSentinel(function)) {
      giveUp(inferrer);
      return inferrer.abstractValueDomain.boolType;
    }

    if (inferrer.commonElements.isCreateSentinel(function) ||
        inferrer.commonElements.isCreateJsSentinel(function)) {
      giveUp(inferrer);
      return inferrer.abstractValueDomain.lateSentinelType;
    }

    return null;
  }

  AbstractValue potentiallyNarrowType(
      AbstractValue mask, InferrerEngine inferrer) {
    return _potentiallyNarrowType(mask, inferrer);
  }

  AbstractValue _potentiallyNarrowType(
      AbstractValue mask, InferrerEngine inferrer);

  @override
  AbstractValue computeType(InferrerEngine inferrer) {
    final special = handleSpecialCases(inferrer);
    if (special != null) return potentiallyNarrowType(special, inferrer);
    return potentiallyNarrowType(
        inferrer.types.computeTypeMask(inputs), inferrer);
  }

  @override
  AbstractValue safeType(InferrerEngine inferrer) {
    return potentiallyNarrowType(super.safeType(inferrer), inferrer);
  }

  @override
  String toString() => 'Member $_member $type';

  @override
  accept(TypeInformationVisitor visitor) {
    return visitor.visitMemberTypeInformation(this);
  }

  @override
  String getInferredSignature(TypeSystem types) {
    return types.getInferredSignatureOfMethod(_member as FunctionEntity);
  }
}

class FieldTypeInformation extends MemberTypeInformation {
  @override
  final FieldEntity _member;
  final AbstractValue _type;

  FieldTypeInformation(
      AbstractValueDomain abstractValueDomain, this._member, DartType type)
      : _type = abstractValueDomain
            .createFromStaticType(type, nullable: true)
            .abstractValue,
        super._internal(abstractValueDomain, _member);

  @override
  AbstractValue? handleSpecialCases(InferrerEngine inferrer) {
    if (!inferrer.canFieldBeUsedForGlobalOptimizations(_member) ||
        inferrer.assumeDynamic(_member)) {
      // Do not infer types for fields that have a corresponding annotation or
      // are assigned by synthesized calls

      giveUp(inferrer);
      return safeType(inferrer);
    }
    if (inferrer.closedWorld.nativeData.isNativeMember(_member)) {
      // Use the type annotation as the type for native elements. We
      // also give up on inferring to make sure this element never
      // goes in the work queue.
      giveUp(inferrer);
      return inferrer
          .typeOfNativeBehavior(inferrer.closedWorld.nativeData
              .getNativeFieldLoadBehavior(_member))
          .type;
    }
    return null;
  }

  @override
  AbstractValue _potentiallyNarrowType(
      AbstractValue mask, InferrerEngine inferrer) {
    return _narrowType(inferrer.abstractValueDomain, mask, _type);
  }

  @override
  bool hasStableType(InferrerEngine inferrer) {
    // The number of inputs of non-final fields is
    // not stable. Therefore such a field cannot be stable.
    if (!_member.isAssignable) {
      return false;
    }
    return super.hasStableType(inferrer);
  }
}

class GetterTypeInformation extends MemberTypeInformation {
  @override
  final FunctionEntity _member;
  final AbstractValue _type;

  GetterTypeInformation(
      AbstractValueDomain abstractValueDomain, this._member, FunctionType type)
      : _type = abstractValueDomain
            .createFromStaticType(type.returnType, nullable: true)
            .abstractValue,
        super._internal(abstractValueDomain, _member);

  @override
  AbstractValue? handleSpecialCases(InferrerEngine inferrer) {
    return _handleFunctionCase(_member, inferrer);
  }

  @override
  AbstractValue _potentiallyNarrowType(
      AbstractValue mask, InferrerEngine inferrer) {
    return _narrowType(inferrer.abstractValueDomain, mask, _type);
  }
}

class SetterTypeInformation extends MemberTypeInformation {
  @override
  final FunctionEntity _member;

  SetterTypeInformation(AbstractValueDomain abstractValueDomain, this._member)
      : super._internal(abstractValueDomain, _member);

  @override
  AbstractValue? handleSpecialCases(InferrerEngine inferrer) {
    return _handleFunctionCase(_member, inferrer);
  }

  @override
  AbstractValue _potentiallyNarrowType(
      AbstractValue mask, InferrerEngine inferrer) {
    return mask;
  }
}

class MethodTypeInformation extends MemberTypeInformation {
  @override
  final FunctionEntity _member;
  final AbstractValue _type;

  MethodTypeInformation(
      AbstractValueDomain abstractValueDomain, this._member, FunctionType type)
      : _type = abstractValueDomain
            .createFromStaticType(type.returnType, nullable: true)
            .abstractValue,
        super._internal(abstractValueDomain, _member);

  @override
  AbstractValue? handleSpecialCases(InferrerEngine inferrer) {
    return _handleFunctionCase(_member, inferrer);
  }

  @override
  AbstractValue _potentiallyNarrowType(
      AbstractValue mask, InferrerEngine inferrer) {
    if (inferrer.commonElements.isLateReadCheck(_member)) {
      mask = inferrer.abstractValueDomain.excludeLateSentinel(mask);
    }
    return _narrowType(inferrer.abstractValueDomain, mask, _type);
  }

  @override
  bool hasStableType(InferrerEngine inferrer) => false;
}

class FactoryConstructorTypeInformation extends MemberTypeInformation {
  @override
  final ConstructorEntity _member;
  final AbstractValue _type;

  FactoryConstructorTypeInformation(
      AbstractValueDomain abstractValueDomain, this._member, FunctionType type)
      : _type = abstractValueDomain
            .createFromStaticType(type.returnType, nullable: true)
            .abstractValue,
        super._internal(abstractValueDomain, _member);

  @override
  AbstractValue? handleSpecialCases(InferrerEngine inferrer) {
    AbstractValueDomain abstractValueDomain = inferrer.abstractValueDomain;
    if (_member.isFromEnvironmentConstructor) {
      if (_member.enclosingClass == inferrer.commonElements.intClass) {
        giveUp(inferrer);
        return abstractValueDomain.includeNull(abstractValueDomain.intType);
      } else if (_member.enclosingClass == inferrer.commonElements.boolClass) {
        giveUp(inferrer);
        return abstractValueDomain.includeNull(abstractValueDomain.boolType);
      } else if (_member.enclosingClass ==
          inferrer.commonElements.stringClass) {
        giveUp(inferrer);
        return abstractValueDomain.includeNull(abstractValueDomain.stringType);
      }
    }
    return _handleFunctionCase(_member, inferrer);
  }

  @override
  AbstractValue _potentiallyNarrowType(
      AbstractValue mask, InferrerEngine inferrer) {
    return _narrowType(inferrer.abstractValueDomain, mask, _type);
  }

  @override
  bool hasStableType(InferrerEngine inferrer) {
    return super.hasStableType(inferrer);
  }
}

class GenerativeConstructorTypeInformation extends MemberTypeInformation {
  @override
  final FunctionEntity _member;

  GenerativeConstructorTypeInformation(
      AbstractValueDomain abstractValueDomain, this._member)
      : super._internal(abstractValueDomain, _member);

  @override
  AbstractValue? handleSpecialCases(InferrerEngine inferrer) {
    return _handleFunctionCase(_member, inferrer);
  }

  @override
  AbstractValue _potentiallyNarrowType(
      AbstractValue mask, InferrerEngine inferrer) {
    return mask;
  }

  @override
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
  final AbstractValue _type;
  final FunctionEntity _method;

  /// The input type is calculated directly from the union of this node's
  /// inputs (i.e. the actual arguments for this parameter). When this
  /// parameter's static type is not trusted, an implicit check will be added
  /// based on this type. [type] on the other hand is the type of this parameter
  /// within the function body so it is narrowed using the static type.
  AbstractValue _inputType;
  bool get _isInstanceMemberParameter =>
      _flags.hasFlag(_Flag.isInstanceMemberParameter);
  bool get _isClosureParameter => _flags.hasFlag(_Flag.isClosureParameter);
  bool get _isInitializingFormal => _flags.hasFlag(_Flag.isInitializingFormal);
  bool _isTearOffClosureParameter = false;
  bool get _isVirtual => _flags.hasFlag(_Flag.isVirtual);

  ParameterTypeInformation.localFunction(super.abstractValueDomain,
      super.context, this._parameter, DartType type, this._method)
      : _type = abstractValueDomain
            .createFromStaticType(type, nullable: true)
            .abstractValue,
        _inputType = abstractValueDomain.uncomputedType,
        super._internal() {
    _flags = _flags.setFlag(_Flag.isClosureParameter);
  }

  ParameterTypeInformation.static(
      super.abstractValueDomain,
      MemberTypeInformation super.context,
      this._parameter,
      DartType type,
      this._method,
      {bool isInitializingFormal = false})
      : _type = abstractValueDomain
            .createFromStaticType(type, nullable: true)
            .abstractValue,
        _inputType = abstractValueDomain.uncomputedType,
        super._internal() {
    _flags =
        _flags.updateFlag(_Flag.isInitializingFormal, isInitializingFormal);
  }

  ParameterTypeInformation.instanceMember(super.abstractValueDomain,
      super.context, this._parameter, DartType type, this._method, super.inputs,
      {required bool isVirtual})
      : _type =
            _createInstanceMemberStaticType(abstractValueDomain, type, _method),
        _inputType = abstractValueDomain.uncomputedType,
        super._withInputs() {
    _flags = _flags.setFlag(_Flag.isInstanceMemberParameter);
    _flags = _flags.updateFlag(_Flag.isVirtual, isVirtual);
  }

  static AbstractValue _createInstanceMemberStaticType(
      AbstractValueDomain domain, DartType type, FunctionEntity method) {
    final staticType =
        domain.createFromStaticType(type, nullable: true).abstractValue;
    // We include null in the type of `==` because it usually does not already
    // include null. When we narrow the inferred type using this static type
    // we want to allow for null so that downstream we can know if null flows
    // into this parameter and add the appropriate checks.
    return method.name == '==' ? domain.includeNull(staticType) : staticType;
  }

  FunctionEntity get method => _method;

  Local get parameter => _parameter;

  bool get isRegularParameter => !_isInitializingFormal;

  @override
  String get debugName => '$parameter';

  void tagAsTearOffClosureParameter(InferrerEngine inferrer) {
    assert(!_isInitializingFormal);
    _isTearOffClosureParameter = true;
    // We have to add a flow-edge for the default value (if it exists), as we
    // might not see all call-sites and thus miss the use of it.
    final defaultType = inferrer.getDefaultTypeOfParameter(_parameter);
    defaultType.addUser(this);
  }

  // TODO(herhut): Cleanup into one conditional.
  AbstractValue? handleSpecialCases(InferrerEngine inferrer) {
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
      // clear the inputs in case the closure is successfully
      // traced.
      giveUp(inferrer, clearInputs: false);
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
    return _narrowType(inferrer.abstractValueDomain, mask, _type);
  }

  AbstractValue checkedType(InferrerEngine inferrer) {
    // By default we don't trust the types of the arguments passed to a
    // parameter. This means that the checking of a parameter is based on the
    // actual arguments.
    //
    // With --omit-implicit-checks we _do_ trust the arguments passed to a
    // parameter - and we never check them.
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
    // `int`. By default we infer the parameter of `method` to be either
    // `int` or `String` and therefore insert a check at the entry of 'method'.
    // With --omit-implicit-checks we (unsoundly) infer the parameter to be
    // `int` and leave the parameter unchecked, and `method` will at runtime
    // actually return a `String` from the second invocation.
    //
    // The trusting of the parameter types within the body of the method is
    // handled by `potentiallyNarrowType` on each call to `computeType`.
    return inferrer.closedWorld.annotationsData
            .getParameterCheckPolicy(method)
            .isTrusted
        ? type
        : _inputType;
  }

  @override
  AbstractValue computeType(InferrerEngine inferrer) {
    final special = handleSpecialCases(inferrer);
    if (special != null) return special;
    final inputType = _inputType = inferrer.types.computeTypeMask(inputs);
    // Virtual parameters are only inputs to other parameters (virtual or
    // concrete) and not function bodies. The user parameters need to know the
    // full set of inputs passed to the virtual parameter.
    return _isVirtual ? inputType : potentiallyNarrowType(inputType, inferrer);
  }

  @override
  AbstractValue safeType(InferrerEngine inferrer) {
    final inputType = _inputType = super.safeType(inferrer);
    // Virtual parameters are only inputs to other parameters (virtual or
    // concrete) and not function bodies. The user parameters need to know the
    // full set of inputs passed to the virtual parameter.
    return _isVirtual ? inputType : potentiallyNarrowType(inputType, inferrer);
  }

  @override
  bool hasStableType(InferrerEngine inferrer) {
    // The number of inputs of parameters of instance methods is
    // not stable. Therefore such a parameter cannot be stable.
    if (_isInstanceMemberParameter) {
      return false;
    }
    return super.hasStableType(inferrer);
  }

  @override
  accept(TypeInformationVisitor visitor) {
    return visitor.visitParameterTypeInformation(this);
  }

  @override
  String toString() => 'Parameter $_parameter $type';

  @override
  String getInferredSignature(TypeSystem types) {
    throw UnsupportedError('ParameterTypeInformation.getInferredSignature');
  }
}

enum CallType {
  access,
  forIn,
}

bool validCallType(CallType callType, ir.Node? call) {
  switch (callType) {
    case CallType.access:
      return call is ir.Node;
    case CallType.forIn:
      return call is ir.ForInStatement;
  }
}

/// A [CallSiteTypeInformation] is a call found in the AST, or a
/// synthesized call for implicit calls in Dart (such as forwarding
/// factories). The [callNode] field is a [ast.Node] for the former, and an
/// [Element] for the latter.
///
/// In the inferrer graph, [CallSiteTypeInformation] nodes do not have
/// any assignment. They rely on the [caller] field for static calls,
/// and [selector] and [receiver] fields for dynamic calls.
abstract class CallSiteTypeInformation extends TypeInformation
    with ApplyableTypeInformation {
  final ir.Node callNode;
  final MemberEntity caller;
  final Selector? selector;
  final ArgumentsTypes? arguments;
  bool get inLoop => _flags.hasFlag(_Flag.inLoop);

  CallSiteTypeInformation(
      AbstractValueDomain abstractValueDomain,
      MemberTypeInformation? context,
      this.callNode,
      this.caller,
      this.selector,
      this.arguments,
      bool inLoop)
      : super.noInputs(abstractValueDomain.uncomputedType, context) {
    _flags = _flags.updateFlag(_Flag.inLoop, inLoop);
  }

  @override
  String toString() => 'Call site $debugName $type';

  /// Add [this] to the graph being computed by [engine].
  void addToGraph(InferrerEngine engine);

  String get debugName => '$callNode';
}

class StaticCallSiteTypeInformation extends CallSiteTypeInformation {
  final MemberEntity calledElement;

  StaticCallSiteTypeInformation(
      super.abstractValueDomain,
      super.context,
      super.callNode,
      super.enclosing,
      this.calledElement,
      super.selector,
      super.arguments,
      super.inLoop);

  ir.StaticInvocation get invocationNode => callNode as ir.StaticInvocation;

  MemberTypeInformation _getCalledTypeInfo(InferrerEngine inferrer) {
    return inferrer.types.getInferredTypeOfMember(calledElement);
  }

  @override
  void addToGraph(InferrerEngine inferrer) {
    MemberTypeInformation callee = _getCalledTypeInfo(inferrer);
    callee.addUser(this);
    if (arguments != null) {
      arguments!.forEach((info) => info.addUser(this));
    }
    inferrer.updateParameterInputs(this, calledElement, arguments, selector,
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
    return inferrer.typeOfMemberWithSelector(calledElement, selector,
        isVirtual: false);
  }

  @override
  AbstractValue computeType(InferrerEngine inferrer) {
    if (isSynthesized) {
      assert(arguments != null);
      return _getCalledTypeInfo(inferrer).type;
    } else {
      return _getCalledTypeInfoWithSelector(inferrer).type;
    }
  }

  @override
  accept(TypeInformationVisitor visitor) {
    return visitor.visitStaticCallSiteTypeInformation(this);
  }

  @override
  bool hasStableType(InferrerEngine inferrer) {
    bool isStable = _getCalledTypeInfo(inferrer).isStable;
    return isStable &&
        (arguments == null || arguments!.every((info) => info.isStable)) &&
        super.hasStableType(inferrer);
  }

  @override
  void removeAndClearReferences(InferrerEngine inferrer) {
    ElementTypeInformation callee = _getCalledTypeInfo(inferrer);
    callee.removeUser(this);
    if (arguments != null) {
      arguments!.forEach((info) => info.removeUser(this));
    }
    super.removeAndClearReferences(inferrer);
  }
}

class DynamicCallSiteTypeInformation<T extends ir.Node>
    extends CallSiteTypeInformation {
  final CallType _callType;
  final TypeInformation receiver;
  final AbstractValue? mask;
  bool get isConditional => _flags.hasFlag(_Flag.isConditional);

  /// Cached concrete targets of this call.
  Iterable<DynamicCallTarget>? _targets;

  /// Recomputed when [_targets] changes.
  /// [_hasTargetsIncludeComplexNoSuchMethod] indicates whether this value
  /// is stale and needs to be recomputed.
  bool get _targetsIncludeComplexNoSuchMethod =>
      _flags.hasFlag(_Flag.targetsIncludeComplexNoSuchMethod);
  bool get _hasTargetsIncludeComplexNoSuchMethod =>
      _flags.hasFlag(_Flag.hasTargetsIncludeComplexNoSuchMethod);

  DynamicCallSiteTypeInformation(
      super.abstractValueDomain,
      super.context,
      this._callType,
      super.callNode,
      super.enclosing,
      super.selector,
      this.mask,
      this.receiver,
      super.arguments,
      super.inLoop,
      bool isConditional) {
    _flags = _flags.updateFlag(_Flag.isConditional, isConditional);
    assert(validCallType(_callType, callNode));
  }

  void _handleCalledTarget(DynamicCallTarget target, InferrerEngine inferrer,
      {required bool addToQueue, required bool remove}) {
    MemberTypeInformation targetType = inferrer.inferredTypeOfTarget(target);
    if (remove) {
      targetType.removeUser(this);
    } else {
      targetType.addUser(this);
    }
    final member = target.member;
    inferrer.updateParameterInputs(this, member, arguments, selector,
        addToQueue: addToQueue, remove: remove, virtualCall: target.isVirtual);
  }

  @override
  void addToGraph(InferrerEngine inferrer) {
    final typeMask = computeTypedSelector(inferrer);
    _hasClosureCallTargets =
        inferrer.closedWorld.includesClosureCall(selector!, typeMask);
    final targets = _targets =
        inferrer.memberHierarchyBuilder.rootsForCall(typeMask, selector!);
    invalidateTargetsIncludeComplexNoSuchMethod();
    receiver.addUser(this);
    if (arguments != null) {
      arguments!.forEach((info) => info.addUser(this));
    }
    for (final target in targets) {
      _handleCalledTarget(target, inferrer, addToQueue: false, remove: false);
    }
  }

  /// `true` if this invocation can hit a 'call' method on a closure.
  bool get hasClosureCallTargets => _flags.hasFlag(_Flag.hasClosureCallTargets);

  set _hasClosureCallTargets(bool value) =>
      _flags = _flags.updateFlag(_Flag.hasClosureCallTargets, value);

  /// All concrete targets of this invocation. If [hasClosureCallTargets] is
  /// `true` the invocation can additional target an unknown set of 'call'
  /// methods on closures.
  Iterable<DynamicCallTarget> get targets => _targets!;

  void forEachConcreteTarget(
      MemberHierarchyBuilder builder, bool Function(MemberEntity member) f) {
    for (final target in targets) {
      builder.forEachTargetMember(target, f);
    }
  }

  AbstractValue? computeTypedSelector(InferrerEngine inferrer) {
    AbstractValue receiverType = receiver.type;
    if (mask != receiverType) {
      return receiverType == inferrer.abstractValueDomain.dynamicType
          ? null
          : receiverType;
    } else {
      return mask;
    }
  }

  void invalidateTargetsIncludeComplexNoSuchMethod() {
    _flags = _flags.clearFlag(_Flag.hasTargetsIncludeComplexNoSuchMethod);
  }

  bool targetsIncludeComplexNoSuchMethod(InferrerEngine inferrer) {
    if (!_hasTargetsIncludeComplexNoSuchMethod) {
      _flags = _flags.setFlag(_Flag.hasTargetsIncludeComplexNoSuchMethod);
      final value = targets.any((target) => inferrer.memberHierarchyBuilder
              .anyTargetMember(target, (MemberEntity e) {
            return e.isFunction &&
                e.isInstanceMember &&
                e.name == Identifiers.noSuchMethod_ &&
                inferrer.noSuchMethodData.isComplex(e as FunctionEntity);
          }));
      _flags =
          _flags.updateFlag(_Flag.targetsIncludeComplexNoSuchMethod, value);
      return value;
    }
    return _targetsIncludeComplexNoSuchMethod;
  }

  /// We optimize certain operations on the [int] class because we know more
  /// about their return type than the actual Dart code. For example, we know
  /// int + int returns an int. The Dart library code for [int.operator+] only
  /// says it returns a [num].
  ///
  /// Returns the more precise TypeInformation, or `null` to defer to the
  /// library code.
  TypeInformation? handleIntrinsifiedSelector(
      Selector selector, AbstractValue? mask, InferrerEngine inferrer) {
    AbstractValueDomain abstractValueDomain = inferrer.abstractValueDomain;
    if (mask == null) return null;
    if (abstractValueDomain.isIntegerOrNull(mask).isPotentiallyFalse) {
      return null;
    }
    if (!selector.isCall && !selector.isOperator) return null;
    final args = arguments!;
    if (!args.named.isEmpty) return null;
    if (args.positional.length > 1) return null;

    bool isInt(TypeInformation info) =>
        abstractValueDomain.isIntegerOrNull(info.type).isDefinitelyTrue;
    bool isEmpty(TypeInformation info) =>
        abstractValueDomain.isEmpty(info.type).isDefinitelyTrue;
    bool isUInt31(TypeInformation info) => abstractValueDomain
        .isUInt31(abstractValueDomain.excludeNull(info.type))
        .isDefinitelyTrue;
    bool isPositiveInt(TypeInformation info) =>
        abstractValueDomain.isPositiveIntegerOrNull(info.type).isDefinitelyTrue;

    TypeInformation tryLater() => inferrer.types.nonNullEmptyType;

    final argument = args.isEmpty ? null : args.positional.first;

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
        if (isEmpty(argument!)) return tryLater();
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
        if (isEmpty(argument!)) return tryLater();
        if (isUInt31(receiver) && isUInt31(argument)) {
          return inferrer.types.uint31Type;
        }
        return null;

      case '>>':
        if (isEmpty(argument!)) return tryLater();
        if (isUInt31(receiver)) {
          return inferrer.types.uint31Type;
        }
        return null;

      case '>>>':
        if (isEmpty(argument!)) return tryLater();
        if (isUInt31(receiver)) {
          return inferrer.types.uint31Type;
        }
        return null;

      case '&':
        if (isEmpty(argument!)) return tryLater();
        if (isUInt31(receiver) || isUInt31(argument)) {
          return inferrer.types.uint31Type;
        }
        return null;

      case '-':
        if (isEmpty(argument!)) return tryLater();
        if (isInt(argument)) {
          return inferrer.types.intType;
        }
        return null;

      case 'unary-':
        // The receiver being an int, the return value will also be an int.
        return inferrer.types.intType;

      case 'abs':
        return args.hasNoArguments() ? inferrer.types.positiveIntType : null;

      default:
        return null;
    }
  }

  @override
  AbstractValue computeType(InferrerEngine inferrer) {
    JClosedWorld closedWorld = inferrer.closedWorld;
    AbstractValueDomain abstractValueDomain = closedWorld.abstractValueDomain;
    final oldTargets = _targets!;
    final typeMask = computeTypedSelector(inferrer);
    final localSelector = selector!;
    inferrer.updateSelectorInMember(
        caller, _callType, callNode as ir.TreeNode, localSelector, typeMask);

    final includesClosureCall = _hasClosureCallTargets =
        closedWorld.includesClosureCall(localSelector, typeMask);
    final targets = _targets =
        inferrer.memberHierarchyBuilder.rootsForCall(typeMask, localSelector);

    // Update the call graph if the targets could have changed.
    if (!identical(targets, oldTargets)) {
      invalidateTargetsIncludeComplexNoSuchMethod();
      // Add calls to new targets to the graph.
      targets
          .where((target) => !oldTargets.contains(target))
          .forEach((DynamicCallTarget target) {
        _handleCalledTarget(target, inferrer, addToQueue: true, remove: false);
      });

      // Walk over the old targets, and remove calls that cannot happen anymore.
      oldTargets
          .where((target) => !targets.contains(target))
          .forEach((DynamicCallTarget target) {
        _handleCalledTarget(target, inferrer, addToQueue: true, remove: true);
      });
    }

    // Walk over the found targets, and compute the joined union type mask
    // for all these targets.
    AbstractValue result;
    if (includesClosureCall) {
      result = abstractValueDomain.dynamicType;
    } else {
      result =
          inferrer.types.joinTypeMasks(targets.map((DynamicCallTarget target) {
        final element = target.member;
        if (typeMask != null &&
            inferrer.returnsListElementType(localSelector, typeMask)) {
          return abstractValueDomain.getContainerElementType(receiver.type);
        } else if (typeMask != null &&
            inferrer.returnsMapValueType(localSelector, typeMask)) {
          if (abstractValueDomain.isDictionary(typeMask)) {
            AbstractValue arg = arguments!.positional[0].type;
            final value = abstractValueDomain.getPrimitiveValue(arg);
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
        } else if (typeMask != null &&
            localSelector.isGetter &&
            abstractValueDomain.recordHasGetter(typeMask, localSelector.name)) {
          return abstractValueDomain.getGetterTypeInRecord(
              typeMask, localSelector.name);
        } else {
          final info =
              handleIntrinsifiedSelector(localSelector, typeMask, inferrer);
          if (info != null) return info.type;
          return inferrer
              .typeOfMemberWithSelector(element, selector,
                  isVirtual: target.isVirtual)
              .type;
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

  @override
  void giveUp(InferrerEngine inferrer, {bool clearInputs = true}) {
    if (!abandonInferencing) {
      inferrer.updateSelectorInMember(
          caller, _callType, callNode as ir.TreeNode, selector, mask);
      final oldTargets = targets;
      final localSelector = selector!;
      _hasClosureCallTargets =
          inferrer.closedWorld.includesClosureCall(localSelector, mask);
      final newTargets = _targets =
          inferrer.memberHierarchyBuilder.rootsForCall(mask, localSelector);
      invalidateTargetsIncludeComplexNoSuchMethod();
      for (final target in newTargets) {
        if (!oldTargets.contains(target)) {
          _handleCalledTarget(target, inferrer,
              addToQueue: true, remove: false);
        }
      }
    }
    super.giveUp(inferrer, clearInputs: clearInputs);
  }

  @override
  void removeAndClearReferences(InferrerEngine inferrer) {
    forEachConcreteTarget(inferrer.memberHierarchyBuilder, (element) {
      MemberTypeInformation callee =
          inferrer.types.getInferredTypeOfMember(element);
      callee.removeUser(this);
      return true;
    });
    if (arguments != null) {
      arguments!.forEach((info) => info.removeUser(this));
    }
    super.removeAndClearReferences(inferrer);
  }

  @override
  String toString() => 'Call site $debugName on ${receiver.type} $type';

  @override
  accept(TypeInformationVisitor visitor) {
    return visitor.visitDynamicCallSiteTypeInformation(this);
  }

  @override
  bool hasStableType(InferrerEngine inferrer) {
    return receiver.isStable &&
        targets.every((target) => inferrer.memberHierarchyBuilder
            .anyTargetMember(
                target,
                (MemberEntity element) => inferrer.types
                    .getInferredTypeOfMember(element)
                    .isStable)) &&
        (arguments == null || arguments!.every((info) => info.isStable)) &&
        super.hasStableType(inferrer);
  }
}

class ClosureCallSiteTypeInformation extends CallSiteTypeInformation {
  final TypeInformation closure;

  ClosureCallSiteTypeInformation(
      super.abstractValueDomain,
      super.context,
      super.callNode,
      super.enclosing,
      super.selector,
      this.closure,
      super.arguments,
      super.inLoop);

  @override
  void addToGraph(InferrerEngine inferrer) {
    arguments!.forEach((info) => info.addUser(this));
    closure.addUser(this);
  }

  @override
  AbstractValue computeType(InferrerEngine inferrer) {
    AbstractValueDomain abstractValueDomain = inferrer.abstractValueDomain;
    AbstractValue closureType = closure.type;
    // We are not tracking closure calls, but if the receiver is not callable,
    // the call will fail. The abstract value domain does not have a convenient
    // method for detecting callable types, but we know `null` and unreachable
    // code have no result type.  This is helpful for propagating
    // unreachability, i.e. tree-shaking.
    if (abstractValueDomain.isEmpty(closureType).isDefinitelyTrue ||
        abstractValueDomain.isNull(closureType).isDefinitelyTrue) {
      return abstractValueDomain.emptyType;
    }
    return safeType(inferrer);
  }

  @override
  String toString() => 'Closure call $debugName on $closure';

  @override
  accept(TypeInformationVisitor visitor) {
    return visitor.visitClosureCallSiteTypeInformation(this);
  }

  @override
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
  ConcreteTypeInformation(super.type) : super.untracked() {
    _flags = _flags.setFlag(_Flag.isStable);
  }

  @override
  bool get isConcrete => true;

  @override
  void addUser(TypeInformation user) {
    // Nothing to do, a concrete type does not get updated so never
    // needs to notify its users.
  }

  @override
  void addUsersOf(TypeInformation other) {
    // Nothing to do, a concrete type does not get updated so never
    // needs to notify its users.
  }

  @override
  void removeUser(TypeInformation user) {}

  @override
  void addInput(TypeInformation assignment) {
    throw "Not supported";
  }

  @override
  void removeInput(TypeInformation assignment) {
    throw "Not supported";
  }

  @override
  AbstractValue computeType(InferrerEngine inferrer) => type;

  @override
  bool reset(InferrerEngine inferrer) {
    throw "Not supported";
  }

  @override
  String toString() => 'Type $type';

  @override
  accept(TypeInformationVisitor visitor) {
    return visitor.visitConcreteTypeInformation(this);
  }

  @override
  bool hasStableType(InferrerEngine inferrer) => true;
}

class StringLiteralTypeInformation extends ConcreteTypeInformation {
  final String value;

  StringLiteralTypeInformation(
      AbstractValueDomain abstractValueDomain, this.value, AbstractValue mask)
      : super(abstractValueDomain.createPrimitiveValue(
            mask, StringConstantValue(value)));

  String asString() => value;
  @override
  String toString() => 'Type $type value ${value}';

  @override
  accept(TypeInformationVisitor visitor) {
    return visitor.visitStringLiteralTypeInformation(this);
  }
}

class BoolLiteralTypeInformation extends ConcreteTypeInformation {
  final bool value;

  BoolLiteralTypeInformation(
      AbstractValueDomain abstractValueDomain, this.value, AbstractValue mask)
      : super(abstractValueDomain.createPrimitiveValue(
            mask, value ? TrueConstantValue() : FalseConstantValue()));

  @override
  String toString() => 'Type $type value ${value}';

  @override
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
      : super(abstractValueDomain.uncomputedType, narrowedType.context) {
    addInput(narrowedType);
  }

  @override
  addInput(TypeInformation info) {
    super.addInput(info);
    assert(inputs.length == 1);
  }

  @override
  AbstractValue computeType(InferrerEngine inferrer) {
    AbstractValueDomain abstractValueDomain = inferrer.abstractValueDomain;
    AbstractValue input = inputs.first.type;
    AbstractValue intersection =
        abstractValueDomain.intersection(input, typeAnnotation);
    return intersection;
  }

  @override
  String toString() {
    return 'Narrow to $typeAnnotation $type';
  }

  @override
  accept(TypeInformationVisitor visitor) {
    return visitor.visitNarrowTypeInformation(this);
  }
}

/// An [InferredTypeInformation] is a [TypeInformation] that
/// defaults to the dynamic type until it is marked as being
/// inferred, at which point it computes its type based on
/// its inputs.
abstract class InferredTypeInformation extends TypeInformation {
  /// Whether the element type in that container has been inferred.
  bool get inferred => _flags.hasFlag(_Flag.inferred);
  set inferred(bool value) => _flags = _flags.updateFlag(_Flag.inferred, value);

  InferredTypeInformation(AbstractValueDomain abstractValueDomain,
      MemberTypeInformation? context, TypeInformation? parentType)
      : super(abstractValueDomain.uncomputedType, context) {
    if (parentType != null) addInput(parentType);
  }

  @override
  AbstractValue computeType(InferrerEngine inferrer) {
    if (!inferred) return safeType(inferrer);
    return inferrer.types.computeTypeMask(inputs);
  }

  @override
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
  final int? originalLength;

  /// The length after the container has been traced.
  int? inferredLength;

  ListTypeInformation(
      AbstractValueDomain abstractValueDomain,
      MemberTypeInformation? context,
      this.originalType,
      this.elementType,
      this.originalLength)
      : super(originalType, context) {
    inferredLength = abstractValueDomain.getContainerLength(originalType);
    elementType.addUser(this);
  }

  @override
  String toString() => 'List type $type';

  @override
  accept(TypeInformationVisitor visitor) {
    return visitor.visitListTypeInformation(this);
  }

  @override
  bool hasStableType(InferrerEngine inferrer) {
    return elementType.isStable && super.hasStableType(inferrer);
  }

  @override
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

  @override
  AbstractValue safeType(InferrerEngine inferrer) => originalType;

  @override
  void cleanup() {
    super.cleanup();
    elementType.cleanup();
    _flowsInto = null;
  }
}

/// An [ElementInContainerTypeInformation] holds the common type of the
/// elements in a [ListTypeInformation].
class ElementInContainerTypeInformation extends InferredTypeInformation {
  ElementInContainerTypeInformation(
      super.abstractValueDomain, super.context, super.elementType);

  @override
  String toString() => 'Element in container $type';

  @override
  accept(TypeInformationVisitor visitor) {
    return visitor.visitElementInContainerTypeInformation(this);
  }
}

/// A [SetTypeInformation] is a [TypeInformation] created for sets.
class SetTypeInformation extends TypeInformation with TracedTypeInformation {
  final ElementInSetTypeInformation elementType;

  final AbstractValue originalType;

  SetTypeInformation(
      MemberTypeInformation? context, this.originalType, this.elementType)
      : super(originalType, context) {
    elementType.addUser(this);
  }

  @override
  String toString() => 'Set type $type';

  @override
  accept(TypeInformationVisitor visitor) {
    return visitor.visitSetTypeInformation(this);
  }

  @override
  AbstractValue computeType(InferrerEngine inferrer) {
    AbstractValueDomain abstractValueDomain = inferrer.abstractValueDomain;
    AbstractValue mask = type;
    if (!abstractValueDomain.isSet(type) ||
        abstractValueDomain.getSetElementType(type) != elementType.type) {
      return abstractValueDomain.createSetValue(
          abstractValueDomain.getGeneralization(originalType),
          abstractValueDomain.getAllocationNode(originalType),
          abstractValueDomain.getAllocationElement(originalType),
          elementType.type);
    }
    return mask;
  }

  @override
  AbstractValue safeType(InferrerEngine inferrer) => originalType;

  @override
  bool hasStableType(InferrerEngine inferrer) {
    return elementType.isStable && super.hasStableType(inferrer);
  }

  @override
  void cleanup() {
    super.cleanup();
    elementType.cleanup();
    _flowsInto = null;
  }
}

/// An [ElementInSetTypeInformation] holds the common type of the elements in a
/// [SetTypeInformation].
class ElementInSetTypeInformation extends InferredTypeInformation {
  ElementInSetTypeInformation(
      super.abstractValueDomain, super.context, super.elementType);

  @override
  String toString() => 'Element in set $type';

  @override
  accept(TypeInformationVisitor visitor) {
    return visitor.visitElementInSetTypeInformation(this);
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

  MapTypeInformation(MemberTypeInformation? context, this.originalType,
      this.keyType, this.valueType)
      : super(originalType, context) {
    keyType.addUser(this);
    valueType.addUser(this);
  }

  TypeInformation? addEntryInput(AbstractValueDomain abstractValueDomain,
      TypeInformation key, TypeInformation value,
      [bool nonNull = false]) {
    ValueInMapTypeInformation? newInfo = null;
    if (_allKeysAreStrings && key is StringLiteralTypeInformation) {
      String keyString = key.asString();
      typeInfoMap.putIfAbsent(keyString, () {
        newInfo = ValueInMapTypeInformation(
            abstractValueDomain, context, null, nonNull);
        return newInfo!;
      });
      typeInfoMap[keyString]!.addInput(value);
    } else {
      _allKeysAreStrings = false;
      typeInfoMap.clear();
    }
    keyType.addInput(key);
    valueType.addInput(value);
    newInfo?.addUser(this);

    return newInfo;
  }

  List<TypeInformation> addMapInput(
      AbstractValueDomain abstractValueDomain, MapTypeInformation other) {
    List<TypeInformation> newInfos = <TypeInformation>[];
    if (_allKeysAreStrings && other.inDictionaryMode) {
      other.typeInfoMap.forEach((keyString, value) {
        typeInfoMap.putIfAbsent(keyString, () {
          final newInfo = ValueInMapTypeInformation(
              abstractValueDomain, context, null, false);
          newInfos.add(newInfo);
          return newInfo;
        });
        typeInfoMap[keyString]!.addInput(value);
      });
    } else {
      _allKeysAreStrings = false;
      typeInfoMap.clear();
    }
    keyType.addInput(other.keyType);
    valueType.addInput(other.valueType);

    return newInfos;
  }

  markAsInferred() {
    keyType.inferred = valueType.inferred = true;
    typeInfoMap.values.forEach((v) => v.inferred = true);
  }

  @override
  addInput(TypeInformation other) {
    throw "not supported";
  }

  @override
  accept(TypeInformationVisitor visitor) {
    return visitor.visitMapTypeInformation(this);
  }

  AbstractValue toTypeMask(InferrerEngine inferrer) {
    AbstractValueDomain abstractValueDomain = inferrer.abstractValueDomain;
    if (inDictionaryMode) {
      Map<String, AbstractValue> mappings = Map<String, AbstractValue>();
      for (var key in typeInfoMap.keys) {
        mappings[key] = typeInfoMap[key]!.type;
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

  @override
  AbstractValue computeType(InferrerEngine inferrer) {
    AbstractValueDomain abstractValueDomain = inferrer.abstractValueDomain;
    if (abstractValueDomain.isDictionary(type) != inDictionaryMode) {
      return toTypeMask(inferrer);
    } else if (abstractValueDomain.isDictionary(type)) {
      assert(inDictionaryMode);
      for (String key in typeInfoMap.keys) {
        final value = typeInfoMap[key]!;
        if (!abstractValueDomain.containsDictionaryKey(type, key) &&
            abstractValueDomain.containsAll(value.type).isDefinitelyFalse &&
            abstractValueDomain.isNull(value.type).isDefinitelyFalse) {
          return toTypeMask(inferrer);
        }
        if (abstractValueDomain.getDictionaryValueForKey(type, key) !=
            typeInfoMap[key]!.type) {
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

  @override
  AbstractValue safeType(InferrerEngine inferrer) => originalType;

  @override
  bool hasStableType(InferrerEngine inferrer) {
    return keyType.isStable &&
        valueType.isStable &&
        super.hasStableType(inferrer);
  }

  @override
  void cleanup() {
    super.cleanup();
    keyType.cleanup();
    valueType.cleanup();
    for (TypeInformation info in typeInfoMap.values) {
      info.cleanup();
    }
    _flowsInto = null;
  }

  @override
  String toString() {
    return 'Map $type (K:$keyType, V:$valueType) contents $typeInfoMap';
  }
}

/// A [KeyInMapTypeInformation] holds the common type
/// for the keys in a [MapTypeInformation]
class KeyInMapTypeInformation extends InferredTypeInformation {
  KeyInMapTypeInformation(
      super.abstractValueDomain, super.context, TypeInformation super.keyType);

  @override
  accept(TypeInformationVisitor visitor) {
    return visitor.visitKeyInMapTypeInformation(this);
  }

  @override
  String toString() => 'Key in Map $type';
}

/// A [ValueInMapTypeInformation] holds the common type
/// for the values in a [MapTypeInformation]
class ValueInMapTypeInformation extends InferredTypeInformation {
  // [nonNull] is set to true if this value is known to be part of the map.
  // Note that only values assigned to a specific key value in dictionary
  // mode can ever be marked as [nonNull].
  bool get nonNull => _flags.hasFlag(_Flag.valueInMapNonNull);

  ValueInMapTypeInformation(
      super.abstractValueDomain, super.context, super.valueType,
      [bool nonNull = false]) {
    _flags = _flags.updateFlag(_Flag.valueInMapNonNull, nonNull);
  }

  @override
  accept(TypeInformationVisitor visitor) {
    return visitor.visitValueInMapTypeInformation(this);
  }

  @override
  AbstractValue computeType(InferrerEngine inferrer) {
    return nonNull
        ? super.computeType(inferrer)
        : inferrer.abstractValueDomain.includeNull(super.computeType(inferrer));
  }

  @override
  String toString() => 'Value in Map $type';
}

/// A [RecordTypeInformation] is the constructor for a record, used for Record
/// constants and literals.
class RecordTypeInformation extends TypeInformation with TracedTypeInformation {
  final RecordShape recordShape;
  final List<TypeInformation> fieldTypes;

  RecordTypeInformation(
      super.type, super.context, this.recordShape, this.fieldTypes)
      : super.noInputs() {
    for (final fieldType in fieldTypes) {
      fieldType.addUser(this);
    }
  }

  @override
  void addInput(TypeInformation other) {
    throw UnsupportedError('addInput');
  }

  @override
  void accept(TypeInformationVisitor visitor) {
    return visitor.visitRecordTypeInformation(this);
  }

  AbstractValue toTypeMask(InferrerEngine inferrer) {
    return inferrer.abstractValueDomain.createRecordValue(
        recordShape, fieldTypes.map((e) => e.type).toList(growable: false));
  }

  @override
  AbstractValue computeType(InferrerEngine inferrer) {
    return toTypeMask(inferrer);
  }

  @override
  AbstractValue safeType(InferrerEngine inferrer) {
    final shapeClass = inferrer.closedWorld.recordData
        .representationForShape(recordShape)
        ?.cls;
    return shapeClass != null
        ? inferrer.abstractValueDomain.createNonNullSubtype(shapeClass)
        : inferrer.abstractValueDomain.recordType;
  }

  @override
  bool hasStableType(InferrerEngine inferrer) {
    return fieldTypes.every((type) => type.hasStableType(inferrer)) &&
        super.hasStableType(inferrer);
  }

  @override
  void cleanup() {
    super.cleanup();
    for (final fieldType in fieldTypes) {
      fieldType.cleanup();
    }
  }

  @override
  String toString() {
    return 'Record $type';
  }
}

/// A [RecordFieldAccessTypeInformation] is a lookup of a specific field in a
/// record when we know the receiver is itself a record. If the receiver cannot
/// statically be typed as a record then lookups will be dynamic calls handled
/// via [DynamicCallSiteTypeInformation].
class RecordFieldAccessTypeInformation extends TypeInformation {
  final String getterName;
  final TypeInformation receiver;
  final ir.TreeNode node;

  RecordFieldAccessTypeInformation(AbstractValueDomain domain, this.getterName,
      this.node, this.receiver, MemberTypeInformation? context)
      : super(domain.uncomputedType, context) {
    receiver.addUser(this);
  }

  @override
  accept(TypeInformationVisitor visitor) {
    return visitor.visitRecordFieldAccessTypeInformation(this);
  }

  @override
  String toString() {
    return 'RecordFieldAccess($type, $getterName)';
  }

  @override
  AbstractValue computeType(InferrerEngine inferrer) {
    final recordType = receiver.type;
    if (inferrer.abstractValueDomain.isEmpty(recordType).isDefinitelyTrue) {
      // These field accesses should begin at empty until we have a type for the
      // receiver.
      return inferrer.abstractValueDomain.emptyType;
    } else if (!inferrer.abstractValueDomain.isRecord(recordType)) {
      return safeType(inferrer);
    }
    final getterType = inferrer.abstractValueDomain
        .getGetterTypeInRecord(recordType, getterName);
    inferrer.dataOfMember(contextMember!).setReceiverTypeMask(node, recordType);
    return getterType;
  }
}

/// A [PhiElementTypeInformation] is an union of
/// [ElementTypeInformation], that is local to a method.
class PhiElementTypeInformation extends TypeInformation {
  final ir.Node? branchNode;
  final Local? variable;
  bool get isTry => _flags.hasFlag(_Flag.isTry);

  PhiElementTypeInformation(AbstractValueDomain abstractValueDomain,
      MemberTypeInformation? context, this.branchNode, this.variable,
      {required bool isTry})
      : super(abstractValueDomain.uncomputedType, context) {
    _flags = _flags.updateFlag(_Flag.isTry, isTry);
  }

  @override
  AbstractValue computeType(InferrerEngine inferrer) {
    return inferrer.types.computeTypeMask(inputs);
  }

  @override
  String toString() => 'Phi($hashCode) $variable $type';

  @override
  void _toStructuredText(
      StringBuffer sb, String indent, Set<TypeInformation> seen) {
    if (seen.add(this)) {
      sb.write('${toString()} [');
      for (TypeInformation assignment in inputs) {
        sb.write('\n$indent  ');
        assignment._toStructuredText(sb, '$indent  ', seen);
      }
      sb.write(' ]');
    } else {
      sb.write('${toString()} [ ... ]');
    }
  }

  @override
  accept(TypeInformationVisitor visitor) {
    return visitor.visitPhiElementTypeInformation(this);
  }
}

class ClosureTypeInformation extends TypeInformation
    with ApplyableTypeInformation {
  final FunctionEntity _element;

  ClosureTypeInformation(AbstractValueDomain abstractValueDomain,
      MemberTypeInformation? context, this._element)
      : super(abstractValueDomain.uncomputedType, context);

  FunctionEntity get closure => _element;

  @override
  AbstractValue computeType(InferrerEngine inferrer) => safeType(inferrer);

  @override
  AbstractValue safeType(InferrerEngine inferrer) {
    return inferrer.types.functionType.type;
  }

  String get debugName => '$closure';

  @override
  String toString() => 'Closure $_element';

  @override
  accept(TypeInformationVisitor visitor) {
    return visitor.visitClosureTypeInformation(this);
  }

  @override
  bool hasStableType(InferrerEngine inferrer) {
    return false;
  }

  String getInferredSignature(TypeSystem types) {
    return types.getInferredSignatureOfMethod(_element);
  }
}

/// Mixin for [TypeInformation] nodes that can bail out during tracing.
mixin TracedTypeInformation implements TypeInformation {
  /// Set to false once analysis has succeeded.
  bool get bailedOut => !_flags.hasFlag(_Flag.notBailedOut);
  set bailedOut(bool value) =>
      _flags = _flags.updateFlag(_Flag.notBailedOut, !value);

  /// Set to true once analysis is completed.
  bool get analyzed => _flags.hasFlag(_Flag.analyzed);
  set analyzed(bool value) => _flags = _flags.updateFlag(_Flag.analyzed, value);

  Set<TypeInformation>? _flowsInto;

  /// The set of [TypeInformation] nodes where values from the traced node could
  /// flow in.
  Set<TypeInformation> get flowsInto {
    return _flowsInto ?? const {};
  }

  /// Adds [nodes] to the sets of values this [TracedTypeInformation] flows
  /// into.
  void addFlowsIntoTargets(Iterable<TypeInformation> nodes) {
    if (_flowsInto == null) {
      _flowsInto = nodes.toSet();
    } else {
      _flowsInto!.addAll(nodes);
    }
  }
}

class AwaitTypeInformation extends TypeInformation {
  final ir.AwaitExpression _node;

  AwaitTypeInformation(AbstractValueDomain abstractValueDomain,
      MemberTypeInformation? context, this._node)
      : super(abstractValueDomain.uncomputedType, context);

  @override
  AbstractValue computeType(InferrerEngine inferrer) {
    final elementMap = inferrer.closedWorld.elementMap;
    final staticTypeProvider =
        elementMap.getStaticTypeProvider(context!.member);
    final staticType =
        elementMap.getDartType(staticTypeProvider.getStaticType(_node));
    return inferrer.abstractValueDomain
        .createFromStaticType(staticType, nullable: true)
        .abstractValue;
  }

  String get debugName => '$_node';

  @override
  String toString() => 'Await';

  @override
  accept(TypeInformationVisitor visitor) {
    return visitor.visitAwaitTypeInformation(this);
  }
}

class YieldTypeInformation extends TypeInformation {
  final ir.Node _node;

  YieldTypeInformation(AbstractValueDomain abstractValueDomain,
      MemberTypeInformation? context, this._node)
      : super(abstractValueDomain.uncomputedType, context);

  @override
  AbstractValue computeType(InferrerEngine inferrer) => safeType(inferrer);

  String get debugName => '$_node';

  @override
  String toString() => 'Yield';

  @override
  accept(TypeInformationVisitor visitor) {
    return visitor.visitYieldTypeInformation(this);
  }
}

abstract class TypeInformationVisitor<T> {
  T visitNarrowTypeInformation(NarrowTypeInformation info);
  T visitPhiElementTypeInformation(PhiElementTypeInformation info);
  T visitElementInContainerTypeInformation(
      ElementInContainerTypeInformation info);
  T visitElementInSetTypeInformation(ElementInSetTypeInformation info);
  T visitKeyInMapTypeInformation(KeyInMapTypeInformation info);
  T visitValueInMapTypeInformation(ValueInMapTypeInformation info);
  T visitRecordFieldAccessTypeInformation(
      RecordFieldAccessTypeInformation info);
  T visitListTypeInformation(ListTypeInformation info);
  T visitSetTypeInformation(SetTypeInformation info);
  T visitMapTypeInformation(MapTypeInformation info);
  T visitRecordTypeInformation(RecordTypeInformation info);
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

AbstractValue _narrowType(AbstractValueDomain abstractValueDomain,
    AbstractValue type, AbstractValue annotation) {
  final narrowType = abstractValueDomain.intersection(type, annotation);
  return abstractValueDomain.isLateSentinel(type).isPotentiallyTrue
      ? abstractValueDomain.includeLateSentinel(narrowType)
      : narrowType;
}
