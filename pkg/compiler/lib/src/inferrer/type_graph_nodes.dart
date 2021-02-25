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
/// A node has a set of inputs and users. Inputs are used to
/// compute the type of the node ([TypeInformation.computeType]). Users are
/// added to the inferrer's work queue when the type of the node
/// changes.
abstract class TypeInformation {
  Set<TypeInformation> users;
  var /* List|ParameterInputs */ _inputs;

  /// The type the inferrer has found for this [TypeInformation].
  /// Initially empty.
  AbstractValue type;

  /// The graph node of the member this [TypeInformation] node belongs to.
  final MemberTypeInformation context;

  /// The element this [TypeInformation] node belongs to.
  MemberEntity get contextMember => context == null ? null : context.member;

  Iterable<TypeInformation> get inputs => _inputs;

  /// We abandon inference in certain cases (complex cyclic flow, native
  /// behaviours, etc.). In some case, we might resume inference in the
  /// closure tracer, which is handled by checking whether [inputs] has
  /// been set to [STOP_TRACKING_INPUTS_MARKER].
  bool abandonInferencing = false;
  bool get mightResume => !identical(inputs, STOP_TRACKING_INPUTS_MARKER);

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
  @override
  final int hashCode = _staticHashCode = (_staticHashCode + 1).toUnsigned(30);

  bool get isConcrete => false;

  TypeInformation(this.type, this.context)
      : _inputs = <TypeInformation>[],
        users = new Setlet<TypeInformation>();

  TypeInformation.noInputs(this.type, this.context)
      : _inputs = const <TypeInformation>[],
        users = new Setlet<TypeInformation>();

  TypeInformation.untracked(this.type)
      : _inputs = const <TypeInformation>[],
        users = const ImmutableEmptySet(),
        context = null;

  TypeInformation.withInputs(this.type, this.context, this._inputs)
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
  static final STOP_TRACKING_INPUTS_MARKER =
      new List<TypeInformation>.filled(0, null);

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

  void giveUp(InferrerEngine inferrer, {bool clearInputs: true}) {
    abandonInferencing = true;
    // Do not remove [this] as a user of nodes in [inputs],
    // because our tracing analysis could be interested in tracing
    // this node.
    if (clearInputs) _inputs = STOP_TRACKING_INPUTS_MARKER;
    // Do not remove users because our tracing analysis could be
    // interested in tracing the users of this node.
  }

  void clear() {
    _inputs = STOP_TRACKING_INPUTS_MARKER;
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
    _inputs = null;
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

  @override
  void accept(TypeInformationVisitor visitor) {
    throw new UnsupportedError("Cannot visit placeholder");
  }

  @override
  AbstractValue computeType(InferrerEngine inferrer) {
    throw new UnsupportedError("Cannot refine placeholder");
  }

  @override
  toString() => "Placeholder [$hashCode]";
}

/// Parameters of instance functions behave differently than other
/// elements because the inferrer may remove inputs. This happens
/// when the receiver of a dynamic call site can be refined
/// to a type where we know more about which instance method is being
/// called.
class ParameterInputs extends IterableBase<TypeInformation> {
  final Map<TypeInformation, int> _inputs = new Map<TypeInformation, int>();

  void remove(TypeInformation info) {
    int existing = _inputs[info];
    if (existing == null) return;
    if (existing == 1) {
      _inputs.remove(info);
    } else {
      _inputs[info] = existing - 1;
    }
  }

  void add(TypeInformation info) {
    int existing = _inputs[info];
    if (existing == null) {
      _inputs[info] = 1;
    } else {
      _inputs[info] = existing + 1;
    }
  }

  void replace(TypeInformation old, TypeInformation replacement) {
    int existing = _inputs[old];
    if (existing != null) {
      int other = _inputs[replacement];
      if (other != null) existing += other;
      _inputs[replacement] = existing;
      _inputs.remove(old);
    }
  }

  @override
  Iterator<TypeInformation> get iterator => _inputs.keys.iterator;
  @override
  Iterable<TypeInformation> where(Function f) => _inputs.keys.where(f);

  @override
  bool contains(Object info) => _inputs.containsKey(info);

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
  bool disableInferenceForClosures = true;

  ElementTypeInformation._internal(
      AbstractValueDomain abstractValueDomain, MemberTypeInformation context)
      : super(abstractValueDomain.emptyType, context);
  ElementTypeInformation._withInputs(AbstractValueDomain abstractValueDomain,
      MemberTypeInformation context, ParameterInputs inputs)
      : super.withInputs(abstractValueDomain.emptyType, context, inputs);

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

  /// Whether this member is invoked via indirect dynamic calls. In that case
  /// the exact number of call sites cannot be computed precisely.
  bool _calledIndirectly = false;

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

  @override
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
    if (_calledIndirectly) return false;
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
  @override
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
    return _potentiallyNarrowType(mask, inferrer);
  }

  AbstractValue _potentiallyNarrowType(
      AbstractValue mask, InferrerEngine inferrer);

  @override
  AbstractValue computeType(InferrerEngine inferrer) {
    AbstractValue special = handleSpecialCases(inferrer);
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

  @override
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

  @override
  AbstractValue _potentiallyNarrowType(
      AbstractValue mask, InferrerEngine inferrer) {
    return _narrowType(inferrer.closedWorld, mask, _type);
  }

  @override
  bool hasStableType(InferrerEngine inferrer) {
    // The number of inputs of non-final fields is
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

  @override
  AbstractValue handleSpecialCases(InferrerEngine inferrer) {
    return _handleFunctionCase(_getter, inferrer);
  }

  @override
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

  @override
  AbstractValue handleSpecialCases(InferrerEngine inferrer) {
    return _handleFunctionCase(_setter, inferrer);
  }

  @override
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

  @override
  AbstractValue handleSpecialCases(InferrerEngine inferrer) {
    return _handleFunctionCase(_method, inferrer);
  }

  @override
  AbstractValue _potentiallyNarrowType(
      AbstractValue mask, InferrerEngine inferrer) {
    return _narrowType(inferrer.closedWorld, mask, _type.returnType);
  }

  @override
  bool hasStableType(InferrerEngine inferrer) => false;
}

class FactoryConstructorTypeInformation extends MemberTypeInformation {
  ConstructorEntity get _constructor => _member;
  final FunctionType _type;

  FactoryConstructorTypeInformation(AbstractValueDomain abstractValueDomain,
      ConstructorEntity element, this._type)
      : super._internal(abstractValueDomain, element);

  @override
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

  @override
  AbstractValue _potentiallyNarrowType(
      AbstractValue mask, InferrerEngine inferrer) {
    return _narrowType(inferrer.closedWorld, mask, _type.returnType);
  }

  @override
  bool hasStableType(InferrerEngine inferrer) {
    return super.hasStableType(inferrer);
  }
}

class GenerativeConstructorTypeInformation extends MemberTypeInformation {
  ConstructorEntity get _constructor => _member;

  GenerativeConstructorTypeInformation(
      AbstractValueDomain abstractValueDomain, ConstructorEntity element)
      : super._internal(abstractValueDomain, element);

  @override
  AbstractValue handleSpecialCases(InferrerEngine inferrer) {
    return _handleFunctionCase(_constructor, inferrer);
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
      ParameterInputs inputs)
      : _isInstanceMemberParameter = true,
        _isClosureParameter = false,
        _isInitializingFormal = false,
        super._withInputs(abstractValueDomain, context, inputs);

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
    if (inferrer.closedWorld.annotationsData
        .getParameterCheckPolicy(method)
        .isTrusted) {
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

  @override
  AbstractValue computeType(InferrerEngine inferrer) {
    AbstractValue special = handleSpecialCases(inferrer);
    if (special != null) return special;
    return potentiallyNarrowType(
        inferrer.types.computeTypeMask(inputs), inferrer);
  }

  @override
  AbstractValue safeType(InferrerEngine inferrer) {
    return potentiallyNarrowType(super.safeType(inferrer), inferrer);
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
    throw new UnsupportedError('ParameterTypeInformation.getInferredSignature');
  }
}

/// A synthetic parameter used to model the entry points to a
/// [IndirectDynamicCallSiteTypeInformation].
class IndirectParameterTypeInformation extends TypeInformation {
  final String debugName;

  IndirectParameterTypeInformation(
      AbstractValueDomain abstractValueDomain, this.debugName)
      : super(abstractValueDomain.emptyType, null);

  @override
  AbstractValue computeType(InferrerEngine inferrer) =>
      inferrer.types.computeTypeMask(inputs);

  @override
  accept(TypeInformationVisitor visitor) {
    return visitor.visitIndirectParameterTypeInformation(this);
  }

  @override
  String toString() => 'IndirectParameter $debugName $type';
}

enum CallType {
  access,
  indirectAccess,
  forIn,
}

bool validCallType(CallType callType, Object call, Selector selector) {
  switch (callType) {
    case CallType.access:
      return call is ir.Node;
    case CallType.indirectAccess:
      return call == null && selector.name == '==';
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
  final ArgumentsTypes arguments;
  final bool inLoop;

  CallSiteTypeInformation(
      AbstractValueDomain abstractValueDomain,
      MemberTypeInformation context,
      this._call,
      this.caller,
      this.selector,
      this.arguments,
      this.inLoop)
      : super.noInputs(abstractValueDomain.emptyType, context) {
    assert(_call is ir.Node || (_call == null && selector.name == '=='));
  }

  @override
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
      ArgumentsTypes arguments,
      bool inLoop)
      : super(abstractValueDomain, context, call, enclosing, selector,
            arguments, inLoop);

  ir.StaticInvocation get invocationNode => _call as ir.StaticInvocation;

  MemberTypeInformation _getCalledTypeInfo(InferrerEngine inferrer) {
    return inferrer.types.getInferredTypeOfMember(calledElement);
  }

  @override
  void addToGraph(InferrerEngine inferrer) {
    MemberTypeInformation callee = _getCalledTypeInfo(inferrer);
    callee.addCall(caller, _call);
    callee.addUser(this);
    if (arguments != null) {
      arguments.forEach((info) => info.addUser(this));
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
    return inferrer.typeOfMemberWithSelector(calledElement, selector);
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
  Iterable<MemberEntity> get callees => [calledElement];

  @override
  accept(TypeInformationVisitor visitor) {
    return visitor.visitStaticCallSiteTypeInformation(this);
  }

  @override
  bool hasStableType(InferrerEngine inferrer) {
    bool isStable = _getCalledTypeInfo(inferrer).isStable;
    return isStable &&
        (arguments == null || arguments.every((info) => info.isStable)) &&
        super.hasStableType(inferrer);
  }

  @override
  void removeAndClearReferences(InferrerEngine inferrer) {
    ElementTypeInformation callee = _getCalledTypeInfo(inferrer);
    callee.removeUser(this);
    if (arguments != null) {
      arguments.forEach((info) => info.removeUser(this));
    }
    super.removeAndClearReferences(inferrer);
  }
}

/// A call modeled with a level of indirection.
///
/// This kind of call is artificial and only exists to address scalability
/// limitations of the inference algorithm. Any virtual, interface, or dynamic
/// call is normally modeled via [DynamicCallSiteTypeInformation]. The main
/// scalability concern of those calls is that we may get a quadratic number of
/// edges to model all the argument and return values (an edge per dynamic call
/// and target pair). Adding a level of indirection helps in that all these
/// calls are funneled through a single [DynamicCallSiteTypeInformation] node,
/// this in turn reduces the edges to be linear (an edge per indiret call to the
/// dynamic call node, and an edge from the call to each target).
class IndirectDynamicCallSiteTypeInformation extends CallSiteTypeInformation {
  final DynamicCallSiteTypeInformation dynamicCall;
  final bool isConditional;
  final TypeInformation receiver;
  final AbstractValue mask;

  IndirectDynamicCallSiteTypeInformation(
      AbstractValueDomain abstractValueDomain,
      MemberTypeInformation context,
      Object call,
      this.dynamicCall,
      MemberEntity enclosing,
      Selector selector,
      this.mask,
      this.receiver,
      ArgumentsTypes arguments,
      bool inLoop,
      this.isConditional)
      : super(abstractValueDomain, context, call, enclosing, selector,
            arguments, inLoop);

  @override
  void addToGraph(InferrerEngine inferrer) {
    receiver.addUser(this);
    dynamicCall.receiver.addInput(receiver);
    List<TypeInformation> positional = arguments.positional;
    for (int i = 0; i < positional.length; i++) {
      positional[i].addUser(this);
      dynamicCall.arguments.positional[i].addInput(positional[i]);
    }
    arguments.named.forEach((name, namedInfo) {
      dynamicCall.arguments.named[name].addInput(namedInfo);
    });
    dynamicCall.addUser(this);
  }

  @override
  AbstractValue computeType(InferrerEngine inferrer) {
    AbstractValue typeMask = _computeTypedSelector(inferrer);
    inferrer.updateSelectorInMember(
        caller, CallType.access, _call, selector, typeMask);

    AbstractValue result = dynamicCall.computeType(inferrer);
    AbstractValueDomain abstractValueDomain =
        inferrer.closedWorld.abstractValueDomain;
    if (isConditional &&
        abstractValueDomain.isNull(receiver.type).isPotentiallyTrue) {
      // Conditional calls like `a?.b` may be null if the receiver is null.
      result = abstractValueDomain.includeNull(result);
    }
    return result;
  }

  AbstractValue _computeTypedSelector(InferrerEngine inferrer) {
    AbstractValue receiverType = receiver.type;
    if (mask == receiverType) return mask;
    return receiverType == inferrer.abstractValueDomain.dynamicType
        ? null
        : receiverType;
  }

  @override
  void giveUp(InferrerEngine inferrer, {bool clearInputs: true}) {
    if (!abandonInferencing) {
      inferrer.updateSelectorInMember(
          caller, CallType.access, _call, selector, mask);
    }
    super.giveUp(inferrer, clearInputs: clearInputs);
  }

  @override
  Iterable<MemberEntity> get callees => dynamicCall.callees;

  @override
  accept(TypeInformationVisitor visitor) {
    return visitor.visitIndirectDynamicCallSiteTypeInformation(this);
  }

  @override
  bool hasStableType(InferrerEngine inferrer) =>
      dynamicCall.hasStableType(inferrer);

  @override
  void removeAndClearReferences(InferrerEngine inferrer) {
    dynamicCall.removeUser(this);
    receiver.removeUser(this);
    if (arguments != null) {
      arguments.forEach((info) => info.removeUser(this));
    }
    super.removeAndClearReferences(inferrer);
  }
}

class DynamicCallSiteTypeInformation<T> extends CallSiteTypeInformation {
  final CallType _callType;
  final TypeInformation receiver;
  final AbstractValue mask;
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
      this.mask,
      this.receiver,
      ArgumentsTypes arguments,
      bool inLoop,
      this.isConditional)
      : super(abstractValueDomain, context, call, enclosing, selector,
            arguments, inLoop) {
    assert(validCallType(_callType, _call, selector));
  }

  void _addCall(MemberTypeInformation callee) {
    if (_callType == CallType.indirectAccess) {
      callee._calledIndirectly = true;
    } else {
      callee.addCall(caller, _call);
    }
  }

  void _removeCall(MemberTypeInformation callee) {
    if (_callType != CallType.indirectAccess) {
      callee.removeCall(caller, _call);
    }
  }

  @override
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
      _addCall(callee);
      callee.addUser(this);
      inferrer.updateParameterInputs(this, element, arguments, selector,
          remove: false, addToQueue: false);
    }
  }

  /// `true` if this invocation can hit a 'call' method on a closure.
  bool get hasClosureCallTargets => _hasClosureCallTargets;

  /// All concrete targets of this invocation. If [hasClosureCallTargets] is
  /// `true` the invocation can additional target an unknown set of 'call'
  /// methods on closures.
  Iterable<MemberEntity> get concreteTargets => _concreteTargets;

  @override
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
    AbstractValueDomain abstractValueDomain = inferrer.abstractValueDomain;
    if (mask == null) return null;
    if (abstractValueDomain.isIntegerOrNull(mask).isPotentiallyFalse) {
      return null;
    }
    if (!selector.isCall && !selector.isOperator) return null;
    if (!arguments.named.isEmpty) return null;
    if (arguments.positional.length > 1) return null;

    bool isInt(info) =>
        abstractValueDomain.isIntegerOrNull(info.type).isDefinitelyTrue;
    bool isEmpty(info) =>
        abstractValueDomain.isEmpty(info.type).isDefinitelyTrue;
    bool isUInt31(info) => abstractValueDomain
        .isUInt31(abstractValueDomain.excludeNull(info.type))
        .isDefinitelyTrue;
    bool isPositiveInt(info) =>
        abstractValueDomain.isPositiveIntegerOrNull(info.type).isDefinitelyTrue;

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

  @override
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
        _addCall(callee);
        callee.addUser(this);
        inferrer.updateParameterInputs(this, element, arguments, selector,
            remove: false, addToQueue: true);
      });

      // Walk over the old targets, and remove calls that cannot happen anymore.
      oldTargets
          .where((target) => !_concreteTargets.contains(target))
          .forEach((MemberEntity element) {
        MemberTypeInformation callee =
            inferrer.types.getInferredTypeOfMember(element);
        _removeCall(callee);
        callee.removeUser(this);
        inferrer.updateParameterInputs(this, element, arguments, selector,
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

  @override
  void giveUp(InferrerEngine inferrer, {bool clearInputs: true}) {
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
          inferrer.updateParameterInputs(this, element, arguments, selector,
              remove: false, addToQueue: true);
        }
      }
    }
    super.giveUp(inferrer, clearInputs: clearInputs);
  }

  @override
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

  @override
  String toString() => 'Call site $debugName on ${receiver.type} $type';

  @override
  accept(TypeInformationVisitor visitor) {
    return visitor.visitDynamicCallSiteTypeInformation(this);
  }

  @override
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
      this.closure,
      ArgumentsTypes arguments,
      bool inLoop)
      : super(abstractValueDomain, context, call, enclosing, selector,
            arguments, inLoop);

  @override
  void addToGraph(InferrerEngine inferrer) {
    arguments.forEach((info) => info.addUser(this));
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
  Iterable<MemberEntity> get callees {
    throw new UnsupportedError("Cannot compute callees of a closure call.");
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
  ConcreteTypeInformation(AbstractValue type) : super.untracked(type) {
    this.isStable = true;
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
            mask, new StringConstantValue(value)));

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
            mask, value ? new TrueConstantValue() : new FalseConstantValue()));

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
      : super(abstractValueDomain.emptyType, narrowedType.context) {
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
  bool inferred = false;

  InferredTypeInformation(AbstractValueDomain abstractValueDomain,
      MemberTypeInformation context, TypeInformation parentType)
      : super(abstractValueDomain.emptyType, context) {
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
  ElementInContainerTypeInformation(AbstractValueDomain abstractValueDomain,
      MemberTypeInformation context, elementType)
      : super(abstractValueDomain, context, elementType);

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
      MemberTypeInformation context, this.originalType, this.elementType)
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
  ElementInSetTypeInformation(AbstractValueDomain abstractValueDomain,
      MemberTypeInformation context, elementType)
      : super(abstractValueDomain, context, elementType);

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

  MapTypeInformation(MemberTypeInformation context, this.originalType,
      this.keyType, this.valueType)
      : super(originalType, context) {
    keyType.addUser(this);
    valueType.addUser(this);
  }

  TypeInformation addEntryInput(AbstractValueDomain abstractValueDomain,
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
      typeInfoMap[keyString].addInput(value);
    } else {
      _allKeysAreStrings = false;
      typeInfoMap.clear();
    }
    keyType.addInput(key);
    valueType.addInput(value);
    if (newInfo != null) newInfo.addUser(this);

    return newInfo;
  }

  List<TypeInformation> addMapInput(
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
        typeInfoMap[keyString].addInput(value);
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

  @override
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
  KeyInMapTypeInformation(AbstractValueDomain abstractValueDomain,
      MemberTypeInformation context, TypeInformation keyType)
      : super(abstractValueDomain, context, keyType);

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
  final bool nonNull;

  ValueInMapTypeInformation(AbstractValueDomain abstractValueDomain,
      MemberTypeInformation context, TypeInformation valueType,
      [this.nonNull = false])
      : super(abstractValueDomain, context, valueType);

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
      MemberTypeInformation context, this._element)
      : super(abstractValueDomain.emptyType, context);

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
  @override
  AbstractValue computeType(InferrerEngine inferrer) => safeType(inferrer);

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
      MemberTypeInformation context, this._node)
      : super(abstractValueDomain.emptyType, context);

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
  T visitListTypeInformation(ListTypeInformation info);
  T visitSetTypeInformation(SetTypeInformation info);
  T visitMapTypeInformation(MapTypeInformation info);
  T visitConcreteTypeInformation(ConcreteTypeInformation info);
  T visitStringLiteralTypeInformation(StringLiteralTypeInformation info);
  T visitBoolLiteralTypeInformation(BoolLiteralTypeInformation info);
  T visitClosureCallSiteTypeInformation(ClosureCallSiteTypeInformation info);
  T visitStaticCallSiteTypeInformation(StaticCallSiteTypeInformation info);
  T visitDynamicCallSiteTypeInformation(DynamicCallSiteTypeInformation info);
  T visitIndirectDynamicCallSiteTypeInformation(
      IndirectDynamicCallSiteTypeInformation info);
  T visitMemberTypeInformation(MemberTypeInformation info);
  T visitParameterTypeInformation(ParameterTypeInformation info);
  T visitIndirectParameterTypeInformation(
      IndirectParameterTypeInformation info);
  T visitClosureTypeInformation(ClosureTypeInformation info);
  T visitAwaitTypeInformation(AwaitTypeInformation info);
  T visitYieldTypeInformation(YieldTypeInformation info);
}

AbstractValue _narrowType(
    JClosedWorld closedWorld, AbstractValue type, DartType annotation,
    {bool isNullable: true}) {
  AbstractValueDomain abstractValueDomain = closedWorld.abstractValueDomain;

  AbstractValue _intersectionWith(AbstractValue otherType) {
    if (isNullable) {
      otherType = abstractValueDomain.includeNull(otherType);
    }
    return type == null
        ? otherType
        : abstractValueDomain.intersection(type, otherType);
  }

  // TODO(joshualitt): FutureOrType, TypeVariableType, and FunctionTypeVariable
  // can be narrowed.
  // TODO(fishythefish): Use nullability.
  annotation = annotation.withoutNullability;
  if (closedWorld.dartTypes.isTopType(annotation) ||
      annotation is FutureOrType ||
      annotation is TypeVariableType ||
      annotation is FunctionTypeVariable) {
    return type;
  } else if (annotation is NeverType) {
    return _intersectionWith(abstractValueDomain.emptyType);
  } else if (annotation is InterfaceType) {
    return _intersectionWith(
        abstractValueDomain.createNonNullSubtype(annotation.element));
  } else if (annotation is FunctionType) {
    return _intersectionWith(abstractValueDomain.functionType);
  } else {
    throw 'Unexpected annotation type $annotation';
  }
}
