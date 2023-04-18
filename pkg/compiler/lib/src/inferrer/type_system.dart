// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;
import '../common.dart';
import '../constants/values.dart' show BoolConstantValue;
import '../elements/entities.dart';
import '../elements/types.dart';
import '../js_model/js_world.dart';
import 'abstract_value_domain.dart';
import 'type_graph_nodes.dart';

/// Strategy for creating type information from members and parameters and type
/// information for nodes.
abstract class TypeSystemStrategy {
  /// Creates [MemberTypeInformation] for [member].
  MemberTypeInformation createMemberTypeInformation(
      AbstractValueDomain abstractValueDomain, MemberEntity member);

  /// Creates [ParameterTypeInformation] for [parameter].
  ParameterTypeInformation createParameterTypeInformation(
      AbstractValueDomain abstractValueDomain,
      Local parameter,
      TypeSystem types);

  /// Calls [f] for each parameter in [function].
  void forEachParameter(FunctionEntity function, void f(Local parameter));

  /// Returns whether [node] is valid as a general phi node.
  bool checkPhiNode(ir.Node? node);

  /// Returns whether [node] is valid as a loop phi node.
  bool checkLoopPhiNode(ir.Node node);

  /// Returns whether [node] is valid as a list allocation node.
  bool checkListNode(ir.Node node);

  /// Returns whether [node] is valid as a set allocation node.
  bool checkSetNode(ir.Node node);

  /// Returns whether [node] is valid as a map allocation node.
  bool checkMapNode(ir.Node node);

  /// Returns whether [cls] is valid as a type mask base class.
  bool checkClassEntity(ClassEntity cls);
}

/// The class [SimpleInferrerVisitor] will use when working on types.
class TypeSystem {
  final JClosedWorld _closedWorld;
  final TypeSystemStrategy strategy;

  /// [parameterTypeInformations] and [memberTypeInformations] ordered by
  /// creation time. This is used as the inference enqueueing order.
  final List<TypeInformation> _orderedTypeInformations = <TypeInformation>[];

  /// [ParameterTypeInformation]s for parameters.
  final Map<Local, ParameterTypeInformation> parameterTypeInformations = {};

  /// [MemberTypeInformation]s for members.
  final Map<MemberEntity, MemberTypeInformation> memberTypeInformations = {};

  final Map<Local, ParameterTypeInformation> virtualParameterTypeInformations =
      {};
  final Map<MemberEntity, MemberTypeInformation> virtualCallTypeInformations =
      {};

  /// [ListTypeInformation] for allocated lists.
  final Map<ir.TreeNode, ListTypeInformation> allocatedLists = {};

  /// [SetTypeInformation] for allocated Sets.
  final Map<ir.TreeNode, SetTypeInformation> allocatedSets = {};

  /// [MapTypeInformation] for allocated Maps.
  final Map<ir.TreeNode, MapTypeInformation> allocatedMaps = {};

  /// [RecordTypeInformation] for allocated Records.
  final Map<ir.TreeNode, RecordTypeInformation> allocatedRecords = {};

  /// Closures found during the analysis.
  final Set<TypeInformation> allocatedClosures = Set<TypeInformation>();

  /// Cache of [ConcreteTypeInformation].
  final Map<AbstractValue, ConcreteTypeInformation> concreteTypes = {};

  /// Cache of some primitive constant types.
  final Map<Object, TypeInformation> primitiveConstantTypes = {};

  /// List of [TypeInformation]s for calls inside method bodies.
  final List<CallSiteTypeInformation> allocatedCalls =
      <CallSiteTypeInformation>[];

  /// List of [TypeInformation]s allocated inside method bodies (narrowing,
  /// phis, and containers).
  final List<TypeInformation> allocatedTypes = <TypeInformation>[];

  /// [parameterTypeInformations] and [memberTypeInformations] ordered by
  /// creation time. This is used as the inference enqueueing order.
  Iterable<TypeInformation> get orderedTypeInformations =>
      _orderedTypeInformations;

  Iterable<TypeInformation> get allTypes => [
        parameterTypeInformations.values,
        memberTypeInformations.values,
        allocatedLists.values,
        allocatedSets.values,
        allocatedMaps.values,
        allocatedClosures,
        concreteTypes.values,
        primitiveConstantTypes.values,
        allocatedCalls,
        allocatedTypes,
      ].expand((x) => x);

  TypeSystem(this._closedWorld, this.strategy);

  AbstractValueDomain get _abstractValueDomain =>
      _closedWorld.abstractValueDomain;

  /// Used to group [TypeInformation] nodes by the element that triggered their
  /// creation.
  MemberTypeInformation? _currentMember = null;
  MemberTypeInformation? get currentMember => _currentMember;

  void withMember(MemberEntity element, void action()) {
    assert(_currentMember == null,
        failedAt(element, "Already constructing graph for $_currentMember."));
    _currentMember = getInferredTypeOfMember(element);
    action();
    _currentMember = null;
  }

  late final ConcreteTypeInformation nullType =
      getConcreteTypeFor(_abstractValueDomain.nullType);

  late final ConcreteTypeInformation intType =
      getConcreteTypeFor(_abstractValueDomain.intType);

  late final ConcreteTypeInformation uint32Type =
      getConcreteTypeFor(_abstractValueDomain.uint32Type);

  late final ConcreteTypeInformation uint31Type =
      getConcreteTypeFor(_abstractValueDomain.uint31Type);

  late final ConcreteTypeInformation positiveIntType =
      getConcreteTypeFor(_abstractValueDomain.positiveIntType);

  late final ConcreteTypeInformation numType =
      getConcreteTypeFor(_abstractValueDomain.numType);

  late final ConcreteTypeInformation boolType =
      getConcreteTypeFor(_abstractValueDomain.boolType);

  late final ConcreteTypeInformation functionType =
      getConcreteTypeFor(_abstractValueDomain.functionType);

  late final ConcreteTypeInformation recordType =
      getConcreteTypeFor(_abstractValueDomain.recordType);

  late final ConcreteTypeInformation listType =
      getConcreteTypeFor(_abstractValueDomain.listType);

  late final ConcreteTypeInformation constListType =
      getConcreteTypeFor(_abstractValueDomain.constListType);

  late final ConcreteTypeInformation fixedListType =
      getConcreteTypeFor(_abstractValueDomain.fixedListType);

  late final ConcreteTypeInformation growableListType =
      getConcreteTypeFor(_abstractValueDomain.growableListType);

  late final ConcreteTypeInformation mutableArrayType =
      getConcreteTypeFor(_abstractValueDomain.mutableArrayType);

  late final ConcreteTypeInformation setType =
      getConcreteTypeFor(_abstractValueDomain.setType);

  late final ConcreteTypeInformation constSetType =
      getConcreteTypeFor(_abstractValueDomain.constSetType);

  late final ConcreteTypeInformation mapType =
      getConcreteTypeFor(_abstractValueDomain.mapType);

  late final ConcreteTypeInformation constMapType =
      getConcreteTypeFor(_abstractValueDomain.constMapType);

  late final ConcreteTypeInformation stringType =
      getConcreteTypeFor(_abstractValueDomain.stringType);

  late final ConcreteTypeInformation typeType =
      getConcreteTypeFor(_abstractValueDomain.typeType);

  late final ConcreteTypeInformation dynamicType =
      getConcreteTypeFor(_abstractValueDomain.dynamicType);

  // Subtype of Future returned by async methods.
  late final ConcreteTypeInformation asyncFutureType =
      getConcreteTypeFor(_abstractValueDomain.asyncFutureType);

  late final ConcreteTypeInformation syncStarIterableType =
      getConcreteTypeFor(_abstractValueDomain.syncStarIterableType);

  late final ConcreteTypeInformation asyncStarStreamType =
      getConcreteTypeFor(_abstractValueDomain.asyncStarStreamType);

  late final ConcreteTypeInformation lateSentinelType =
      getConcreteTypeFor(_abstractValueDomain.lateSentinelType);

  late final ConcreteTypeInformation nonNullEmptyType =
      getConcreteTypeFor(_abstractValueDomain.emptyType);

  TypeInformation stringLiteralType(String value) {
    return StringLiteralTypeInformation(
        _abstractValueDomain, value, _abstractValueDomain.stringType);
  }

  TypeInformation boolLiteralType(bool value) {
    return primitiveConstantTypes[value] ??= _boolLiteralType(value);
  }

  TypeInformation _boolLiteralType(bool value) {
    AbstractValue abstractValue = _abstractValueDomain
        .computeAbstractValueForConstant(BoolConstantValue(value));
    return BoolLiteralTypeInformation(
        _abstractValueDomain, value, abstractValue);
  }

  bool isLiteralTrue(TypeInformation info) {
    return info is BoolLiteralTypeInformation && info.value == true;
  }

  bool isLiteralFalse(TypeInformation info) {
    return info is BoolLiteralTypeInformation && info.value == false;
  }

  /// Returns the least upper bound between [firstType] and
  /// [secondType].
  TypeInformation computeLUB(
      TypeInformation? firstType, TypeInformation secondType) {
    if (firstType == null) return secondType;
    if (firstType == secondType) return firstType;
    if (firstType == nonNullEmptyType) return secondType;
    if (secondType == nonNullEmptyType) return firstType;
    if (firstType == dynamicType || secondType == dynamicType) {
      return dynamicType;
    }
    return getConcreteTypeFor(
        _abstractValueDomain.union(firstType.type, secondType.type));
  }

  /// Returns `true` if `selector` should be updated to reflect the new
  /// `receiverType`.
  bool selectorNeedsUpdate(TypeInformation info, AbstractValue? mask) {
    return info.type != mask;
  }

  bool _isNonNullNarrow(TypeInformation type) =>
      type is NarrowTypeInformation &&
      _abstractValueDomain.isNull(type.typeAnnotation).isDefinitelyFalse;

  /// Returns the intersection between [type] and [annotation].
  ///
  /// [isCast] indicates whether narrowing comes from a cast or parameter check
  /// rather than an 'is' test. (In legacy semantics these differ on whether
  /// `null` is accepted).
  ///
  /// If [excludeNull] is true, the intersection excludes `null` even if the
  /// Dart type implies `null`.
  ///
  /// [narrowType] will not exclude the late sentinel value by default, only if
  /// [excludeLateSentinel] is `true`.
  TypeInformation narrowType(TypeInformation type, DartType annotation,
      {bool isCast = true,
      bool excludeNull = false,
      bool excludeLateSentinel = false}) {
    AbstractValue inferredType = type.type;

    TypeInformation _excludeLateSentinel() {
      if (!excludeLateSentinel) return type;
      final newType = NarrowTypeInformation(
          _abstractValueDomain, type, _abstractValueDomain.dynamicType);
      allocatedTypes.add(newType);
      return newType;
    }

    // Avoid refining an input with an exact type, since we are almost always
    // adding a narrowing to a subtype of the same class or a superclass.
    if (_abstractValueDomain.isExact(inferredType).isDefinitelyTrue) {
      return _excludeLateSentinel();
    }

    AbstractValue narrowing = _abstractValueDomain
        .createFromStaticType(annotation, nullable: isCast)
        .abstractValue;

    if (excludeNull) {
      narrowing = _abstractValueDomain.excludeNull(narrowing);
    }

    if (!excludeLateSentinel) {
      // Narrowing is an intersection of [AbstractValue]s. Unless
      // [excludeLateSentinel] is `true`, we include the late sentinel here so
      // that it is preserved by the intersection.
      narrowing = _abstractValueDomain.includeLateSentinel(narrowing);
    }

    if (_abstractValueDomain.containsAll(narrowing).isPotentiallyTrue) {
      // Top, or non-nullable Top.
      if (_abstractValueDomain.isNull(narrowing).isPotentiallyTrue) {
        return _excludeLateSentinel();
      }
      // If the input is already narrowed to be non-null, there is no value in
      // adding another non-null narrowing node.
      if (_isNonNullNarrow(type)) return _excludeLateSentinel();
    }

    TypeInformation newType =
        NarrowTypeInformation(_abstractValueDomain, type, narrowing);
    allocatedTypes.add(newType);
    return newType;
  }

  ParameterTypeInformation getInferredTypeOfParameter(Local parameter,
      {bool virtual = false}) {
    final typeInformations =
        virtual ? virtualParameterTypeInformations : parameterTypeInformations;
    return typeInformations.putIfAbsent(parameter, () {
      ParameterTypeInformation typeInformation =
          strategy.createParameterTypeInformation(
              _abstractValueDomain, parameter, this);
      _orderedTypeInformations.add(typeInformation);
      return typeInformation;
    });
  }

  void forEachParameterType(
      void f(Local parameter, ParameterTypeInformation typeInformation)) {
    parameterTypeInformations.forEach(f);
  }

  MemberTypeInformation getInferredTypeOfMember(MemberEntity member,
      {bool virtual = false}) {
    if (virtual) {
      return virtualCallTypeInformations[member] ??=
          strategy.createMemberTypeInformation(_abstractValueDomain, member);
    } else {
      return memberTypeInformations[member] ??=
          _getInferredTypeOfMember(member);
    }
  }

  void forEachMemberType(
      void f(MemberEntity member, MemberTypeInformation typeInformation)) {
    memberTypeInformations.forEach(f);
  }

  MemberTypeInformation _getInferredTypeOfMember(MemberEntity member) {
    MemberTypeInformation typeInformation =
        strategy.createMemberTypeInformation(_abstractValueDomain, member);
    _orderedTypeInformations.add(typeInformation);
    return typeInformation;
  }

  /// Returns the internal inferrer representation for [mask].
  ConcreteTypeInformation getConcreteTypeFor(AbstractValue mask) {
    return concreteTypes.putIfAbsent(mask, () {
      return ConcreteTypeInformation(mask);
    });
  }

  String getInferredSignatureOfMethod(FunctionEntity function) {
    ElementTypeInformation info = getInferredTypeOfMember(function);
    var res = "";
    strategy.forEachParameter(function, (Local parameter) {
      TypeInformation type = getInferredTypeOfParameter(parameter);
      res += "${res.isEmpty ? '(' : ', '}${type.type} ${parameter.name}";
    });
    res += ") -> ${info.type}";
    return res;
  }

  TypeInformation nonNullSubtype(ClassEntity cls) {
    assert(strategy.checkClassEntity(cls));
    return getConcreteTypeFor(_abstractValueDomain.createNonNullSubtype(cls));
  }

  TypeInformation nonNullSubclass(ClassEntity cls) {
    assert(strategy.checkClassEntity(cls));
    return getConcreteTypeFor(_abstractValueDomain.createNonNullSubclass(cls));
  }

  TypeInformation nonNullExact(ClassEntity cls) {
    assert(strategy.checkClassEntity(cls));
    return getConcreteTypeFor(_abstractValueDomain.createNonNullExact(cls));
  }

  TypeInformation nonNullEmpty() {
    return nonNullEmptyType;
  }

  bool isNull(TypeInformation type) {
    return type == nullType;
  }

  TypeInformation allocateList(TypeInformation type, ir.TreeNode node,
      MemberEntity enclosing, TypeInformation elementType,
      [int? length]) {
    assert(strategy.checkListNode(node));
    final typedDataClass = _closedWorld.commonElements.typedDataClass;
    bool isTypedArray =
        _closedWorld.classHierarchy.isInstantiated(typedDataClass) &&
            _abstractValueDomain
                .isInstanceOfOrNull(type.type, typedDataClass)
                .isDefinitelyTrue;
    bool isConst = (type.type == _abstractValueDomain.constListType);
    bool isFixed = (type.type == _abstractValueDomain.fixedListType) ||
        isConst ||
        isTypedArray;
    bool isElementInferred = isConst || isTypedArray;

    final inferredLength = isFixed ? length : null;
    final elementTypeMask =
        isElementInferred ? elementType.type : dynamicType.type;
    AbstractValue mask = _abstractValueDomain.createContainerValue(
        type.type, node, enclosing, elementTypeMask, inferredLength);
    ElementInContainerTypeInformation element =
        ElementInContainerTypeInformation(
            _abstractValueDomain, currentMember, elementType);
    element.inferred = isElementInferred;

    allocatedTypes.add(element);
    return allocatedLists[node] = ListTypeInformation(
        _abstractValueDomain, currentMember, mask, element, length);
  }

  /// Creates a [TypeInformation] object either for the closurization of a
  /// static or top-level method [element] used as a function constant or for
  /// the synthesized 'call' method [element] created for a local function.
  TypeInformation allocateClosure(FunctionEntity element) {
    TypeInformation result =
        ClosureTypeInformation(_abstractValueDomain, currentMember, element);
    allocatedClosures.add(result);
    return result;
  }

  TypeInformation allocateSet(TypeInformation type, ir.TreeNode node,
      MemberEntity enclosing, TypeInformation elementType) {
    assert(strategy.checkSetNode(node));
    bool isConst = type.type == _abstractValueDomain.constSetType;

    AbstractValue elementTypeMask =
        isConst ? elementType.type : dynamicType.type;
    AbstractValue mask = _abstractValueDomain.createSetValue(
        type.type, node, enclosing, elementTypeMask);
    ElementInSetTypeInformation element = ElementInSetTypeInformation(
        _abstractValueDomain, currentMember, elementType);
    element.inferred = isConst;

    allocatedTypes.add(element);
    return allocatedSets[node] =
        SetTypeInformation(currentMember, mask, element);
  }

  TypeInformation allocateMap(
      ConcreteTypeInformation type,
      ir.TreeNode node,
      MemberEntity element,
      List<TypeInformation> keyTypes,
      List<TypeInformation> valueTypes) {
    assert(strategy.checkMapNode(node));
    assert(keyTypes.length == valueTypes.length);
    bool isFixed = (type.type == _abstractValueDomain.constMapType);

    PhiElementTypeInformation? keyType, valueType;
    for (int i = 0; i < keyTypes.length; ++i) {
      final typeForKey = keyTypes[i];
      keyType = keyType == null
          ? allocatePhi(null, null, typeForKey, isTry: false)
          : addPhiInput(null, keyType, typeForKey);

      final typeForValue = valueTypes[i];
      valueType = valueType == null
          ? allocatePhi(null, null, typeForValue, isTry: false)
          : addPhiInput(null, valueType, typeForValue);
    }

    final simplifiedKeyType =
        keyType == null ? nonNullEmpty() : simplifyPhi(null, null, keyType);
    final simplifiedValueType =
        valueType == null ? nonNullEmpty() : simplifyPhi(null, null, valueType);

    AbstractValue keyTypeMask, valueTypeMask;
    if (isFixed) {
      keyTypeMask = simplifiedKeyType.type;
      valueTypeMask = simplifiedValueType.type;
    } else {
      keyTypeMask = valueTypeMask = dynamicType.type;
    }
    AbstractValue mask = _abstractValueDomain.createMapValue(
        type.type, node, element, keyTypeMask, valueTypeMask);

    final keyTypeInfo = KeyInMapTypeInformation(
        _abstractValueDomain, currentMember, simplifiedKeyType);
    final valueTypeInfo = ValueInMapTypeInformation(
        _abstractValueDomain, currentMember, simplifiedValueType);
    allocatedTypes.add(keyTypeInfo);
    allocatedTypes.add(valueTypeInfo);

    MapTypeInformation map =
        MapTypeInformation(currentMember, mask, keyTypeInfo, valueTypeInfo);

    for (int i = 0; i < keyTypes.length; ++i) {
      final newType = map.addEntryInput(
          _abstractValueDomain, keyTypes[i], valueTypes[i], true);
      if (newType != null) allocatedTypes.add(newType);
    }

    // Shortcut: If we already have a first approximation of the key/value type,
    // start propagating it early.
    if (isFixed) map.markAsInferred();

    allocatedMaps[node] = map;
    return map;
  }

  TypeInformation allocateRecord(ir.TreeNode node, RecordType recordType,
      List<TypeInformation> fieldTypes, bool isConst) {
    assert(fieldTypes.length == recordType.shape.fieldCount);
    final shape = recordType.shape;
    final getters = _closedWorld.recordData.gettersForShape(shape);

    for (var i = 0; i < fieldTypes.length; i++) {
      final getter = getters[i] as FunctionEntity;
      final getterType = _getGetterTypeForRecordField(getter);
      getterType.addInput(fieldTypes[i]);
      allocatedTypes.add(getterType);
    }

    final record = RecordTypeInformation(currentMember,
        _abstractValueDomain.recordType, recordType.shape, fieldTypes);
    allocatedRecords[node] = record;
    return record;
  }

  MemberTypeInformation _getGetterTypeForRecordField(FunctionEntity getter) {
    return memberTypeInformations[getter] ??= GetterTypeInformation(
        _abstractValueDomain,
        getter,
        _closedWorld.dartTypes.functionType(
            _closedWorld.commonElements.dynamicType,
            const [],
            const [],
            const [],
            const {},
            const [],
            const []));
  }

  TypeInformation allocateRecordFieldGet(
      ir.TreeNode node, String fieldName, TypeInformation receiverType) {
    final accessType = RecordFieldAccessTypeInformation(
        _closedWorld.abstractValueDomain,
        fieldName,
        node,
        receiverType,
        currentMember);
    allocatedTypes.add(accessType);
    receiverType.addUser(accessType);
    return accessType;
  }

  AbstractValue? newTypedSelector(TypeInformation info, AbstractValue? mask) {
    // Only type the selector if [info] is concrete, because the other
    // kinds of [TypeInformation] have the empty type at this point of
    // analysis.
    return info.isConcrete ? info.type : mask;
  }

  /// Returns a new type that unions [firstInput] and [secondInput].
  TypeInformation allocateDiamondPhi(
      TypeInformation firstInput, TypeInformation secondInput) {
    PhiElementTypeInformation result = PhiElementTypeInformation(
        _abstractValueDomain, currentMember, null, null,
        isTry: false);
    result.addInput(firstInput);
    result.addInput(secondInput);
    allocatedTypes.add(result);
    return result;
  }

  PhiElementTypeInformation _addPhi(
      ir.Node? node, Local? variable, TypeInformation inputType, bool isTry) {
    PhiElementTypeInformation result = PhiElementTypeInformation(
        _abstractValueDomain, currentMember, node, variable,
        isTry: isTry);
    allocatedTypes.add(result);
    result.addInput(inputType);
    return result;
  }

  /// Returns a new type for holding the potential types of [element].
  /// [inputType] is the first incoming type of the phi.
  PhiElementTypeInformation allocatePhi(
      ir.Node? node, Local? variable, TypeInformation inputType,
      {required bool isTry}) {
    assert(strategy.checkPhiNode(node));
    // Check if [inputType] is a phi for a local updated in
    // the try/catch block [node]. If it is, no need to allocate a new
    // phi.
    if (inputType is PhiElementTypeInformation &&
        inputType.branchNode == node &&
        inputType.isTry) {
      return inputType;
    }
    return _addPhi(node, variable, inputType, isTry);
  }

  /// Returns a new type for holding the potential types of [element].
  /// [inputType] is the first incoming type of the phi. [allocateLoopPhi]
  /// only differs from [allocatePhi] in that it allows the underlying
  /// implementation of [TypeSystem] to differentiate Phi nodes due to loops
  /// from other merging uses.
  PhiElementTypeInformation allocateLoopPhi(
      ir.Node node, Local variable, TypeInformation inputType,
      {required bool isTry}) {
    assert(strategy.checkLoopPhiNode(node));
    return _addPhi(node, variable, inputType, isTry);
  }

  /// Simplifies the phi representing [element] and of the type
  /// [phiType]. For example, if this phi has one incoming input, an
  /// implementation of this method could just return that incoming
  /// input type.
  TypeInformation simplifyPhi(
      ir.Node? node, Local? variable, PhiElementTypeInformation phiType) {
    assert(phiType.branchNode == node);
    if (phiType.inputs.length == 1) return phiType.inputs.first;
    return phiType;
  }

  /// Adds [newType] as an input of [phiType].
  PhiElementTypeInformation addPhiInput(Local? variable,
      PhiElementTypeInformation phiType, TypeInformation newType) {
    phiType.addInput(newType);
    return phiType;
  }

  AbstractValue computeTypeMask(Iterable<TypeInformation> assignments) {
    return joinTypeMasks(assignments.map((e) => e.type));
  }

  AbstractValue joinTypeMasks(Iterable<AbstractValue> masks) {
    var topType = _abstractValueDomain.internalTopType;
    // Optimization: we are iterating over masks twice, but because `masks` is a
    // mapped iterable, we save the intermediate results to avoid computing them
    // again.
    var list = [];
    bool isTopIgnoringFlags = false;
    bool mayBeNull = false;
    bool mayBeLateSentinel = false;
    for (AbstractValue mask in masks) {
      // Don't do any work on computing unions if we know that after all that
      // work the result will be `dynamic`.
      // TODO(sigmund): change to `mask == internalTopType` so we can continue
      // to track the non-nullable and late sentinel bits.
      if (_abstractValueDomain.containsAll(mask).isPotentiallyTrue) {
        isTopIgnoringFlags = true;
      }
      if (_abstractValueDomain.isNull(mask).isPotentiallyTrue) {
        mayBeNull = true;
      }
      if (_abstractValueDomain.isLateSentinel(mask).isPotentiallyTrue) {
        mayBeLateSentinel = true;
      }
      if (isTopIgnoringFlags && mayBeNull && mayBeLateSentinel) return topType;
      list.add(mask);
    }

    AbstractValue? newType;
    for (AbstractValue mask in list) {
      newType =
          newType == null ? mask : _abstractValueDomain.union(newType, mask);
      // Likewise - stop early if we already reach dynamic.
      if (_abstractValueDomain.containsAll(newType).isPotentiallyTrue) {
        isTopIgnoringFlags = true;
      }
      if (_abstractValueDomain.isNull(newType).isPotentiallyTrue) {
        mayBeNull = true;
      }
      if (_abstractValueDomain.isLateSentinel(newType).isPotentiallyTrue) {
        mayBeLateSentinel = true;
      }
      if (isTopIgnoringFlags && mayBeNull && mayBeLateSentinel) return topType;
    }

    return newType ?? _abstractValueDomain.emptyType;
  }
}
