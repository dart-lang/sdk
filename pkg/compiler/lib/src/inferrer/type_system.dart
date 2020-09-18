// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;
import '../common.dart';
import '../constants/values.dart' show BoolConstantValue;
import '../elements/entities.dart';
import '../elements/types.dart';
import '../ir/static_type.dart' show ClassRelation;
import '../world.dart';
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
  bool checkPhiNode(ir.Node node);

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
  final Map<Local, ParameterTypeInformation> parameterTypeInformations =
      new Map<Local, ParameterTypeInformation>();

  /// [MemberTypeInformation]s for members.
  final Map<MemberEntity, MemberTypeInformation> memberTypeInformations =
      new Map<MemberEntity, MemberTypeInformation>();

  /// [ListTypeInformation] for allocated lists.
  final Map<ir.TreeNode, ListTypeInformation> allocatedLists =
      new Map<ir.TreeNode, ListTypeInformation>();

  /// [SetTypeInformation] for allocated Sets.
  final Map<ir.TreeNode, SetTypeInformation> allocatedSets =
      new Map<ir.TreeNode, SetTypeInformation>();

  /// [MapTypeInformation] for allocated Maps.
  final Map<ir.TreeNode, TypeInformation> allocatedMaps =
      new Map<ir.TreeNode, TypeInformation>();

  /// Closures found during the analysis.
  final Set<TypeInformation> allocatedClosures = new Set<TypeInformation>();

  /// Cache of [ConcreteTypeInformation].
  final Map<AbstractValue, TypeInformation> concreteTypes =
      new Map<AbstractValue, TypeInformation>();

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

  TypeSystem(this._closedWorld, this.strategy) {
    nonNullEmptyType = getConcreteTypeFor(_abstractValueDomain.emptyType);
  }

  AbstractValueDomain get _abstractValueDomain =>
      _closedWorld.abstractValueDomain;

  /// Used to group [TypeInformation] nodes by the element that triggered their
  /// creation.
  MemberTypeInformation _currentMember = null;
  MemberTypeInformation get currentMember => _currentMember;

  void withMember(MemberEntity element, void action()) {
    assert(_currentMember == null,
        failedAt(element, "Already constructing graph for $_currentMember."));
    _currentMember = getInferredTypeOfMember(element);
    action();
    _currentMember = null;
  }

  TypeInformation nullTypeCache;
  TypeInformation get nullType {
    if (nullTypeCache != null) return nullTypeCache;
    return nullTypeCache = getConcreteTypeFor(_abstractValueDomain.nullType);
  }

  TypeInformation intTypeCache;
  TypeInformation get intType {
    if (intTypeCache != null) return intTypeCache;
    return intTypeCache = getConcreteTypeFor(_abstractValueDomain.intType);
  }

  TypeInformation uint32TypeCache;
  TypeInformation get uint32Type {
    if (uint32TypeCache != null) return uint32TypeCache;
    return uint32TypeCache =
        getConcreteTypeFor(_abstractValueDomain.uint32Type);
  }

  TypeInformation uint31TypeCache;
  TypeInformation get uint31Type {
    if (uint31TypeCache != null) return uint31TypeCache;
    return uint31TypeCache =
        getConcreteTypeFor(_abstractValueDomain.uint31Type);
  }

  TypeInformation positiveIntTypeCache;
  TypeInformation get positiveIntType {
    if (positiveIntTypeCache != null) return positiveIntTypeCache;
    return positiveIntTypeCache =
        getConcreteTypeFor(_abstractValueDomain.positiveIntType);
  }

  TypeInformation doubleTypeCache;
  TypeInformation get doubleType {
    if (doubleTypeCache != null) return doubleTypeCache;
    return doubleTypeCache =
        getConcreteTypeFor(_abstractValueDomain.doubleType);
  }

  TypeInformation numTypeCache;
  TypeInformation get numType {
    if (numTypeCache != null) return numTypeCache;
    return numTypeCache = getConcreteTypeFor(_abstractValueDomain.numType);
  }

  TypeInformation boolTypeCache;
  TypeInformation get boolType {
    if (boolTypeCache != null) return boolTypeCache;
    return boolTypeCache = getConcreteTypeFor(_abstractValueDomain.boolType);
  }

  TypeInformation functionTypeCache;
  TypeInformation get functionType {
    if (functionTypeCache != null) return functionTypeCache;
    return functionTypeCache =
        getConcreteTypeFor(_abstractValueDomain.functionType);
  }

  TypeInformation listTypeCache;
  TypeInformation get listType {
    if (listTypeCache != null) return listTypeCache;
    return listTypeCache = getConcreteTypeFor(_abstractValueDomain.listType);
  }

  TypeInformation constListTypeCache;
  TypeInformation get constListType {
    if (constListTypeCache != null) return constListTypeCache;
    return constListTypeCache =
        getConcreteTypeFor(_abstractValueDomain.constListType);
  }

  TypeInformation fixedListTypeCache;
  TypeInformation get fixedListType {
    if (fixedListTypeCache != null) return fixedListTypeCache;
    return fixedListTypeCache =
        getConcreteTypeFor(_abstractValueDomain.fixedListType);
  }

  TypeInformation growableListTypeCache;
  TypeInformation get growableListType {
    if (growableListTypeCache != null) return growableListTypeCache;
    return growableListTypeCache =
        getConcreteTypeFor(_abstractValueDomain.growableListType);
  }

  TypeInformation _mutableArrayType;
  TypeInformation get mutableArrayType => _mutableArrayType ??=
      getConcreteTypeFor(_abstractValueDomain.mutableArrayType);

  TypeInformation setTypeCache;
  TypeInformation get setType =>
      setTypeCache ??= getConcreteTypeFor(_abstractValueDomain.setType);

  TypeInformation constSetTypeCache;
  TypeInformation get constSetType => constSetTypeCache ??=
      getConcreteTypeFor(_abstractValueDomain.constSetType);

  TypeInformation mapTypeCache;
  TypeInformation get mapType {
    if (mapTypeCache != null) return mapTypeCache;
    return mapTypeCache = getConcreteTypeFor(_abstractValueDomain.mapType);
  }

  TypeInformation constMapTypeCache;
  TypeInformation get constMapType {
    if (constMapTypeCache != null) return constMapTypeCache;
    return constMapTypeCache =
        getConcreteTypeFor(_abstractValueDomain.constMapType);
  }

  TypeInformation stringTypeCache;
  TypeInformation get stringType {
    if (stringTypeCache != null) return stringTypeCache;
    return stringTypeCache =
        getConcreteTypeFor(_abstractValueDomain.stringType);
  }

  TypeInformation typeTypeCache;
  TypeInformation get typeType {
    if (typeTypeCache != null) return typeTypeCache;
    return typeTypeCache = getConcreteTypeFor(_abstractValueDomain.typeType);
  }

  TypeInformation dynamicTypeCache;
  TypeInformation get dynamicType {
    if (dynamicTypeCache != null) return dynamicTypeCache;
    return dynamicTypeCache =
        getConcreteTypeFor(_abstractValueDomain.dynamicType);
  }

  TypeInformation asyncFutureTypeCache;
  // Subtype of Future returned by async methods.
  TypeInformation get asyncFutureType {
    if (asyncFutureTypeCache != null) return asyncFutureTypeCache;
    return asyncFutureTypeCache =
        getConcreteTypeFor(_abstractValueDomain.asyncFutureType);
  }

  TypeInformation syncStarIterableTypeCache;
  TypeInformation get syncStarIterableType {
    if (syncStarIterableTypeCache != null) return syncStarIterableTypeCache;
    return syncStarIterableTypeCache =
        getConcreteTypeFor(_abstractValueDomain.syncStarIterableType);
  }

  TypeInformation asyncStarStreamTypeCache;
  TypeInformation get asyncStarStreamType {
    if (asyncStarStreamTypeCache != null) return asyncStarStreamTypeCache;
    return asyncStarStreamTypeCache =
        getConcreteTypeFor(_abstractValueDomain.asyncStarStreamType);
  }

  TypeInformation nonNullEmptyType;

  TypeInformation stringLiteralType(String value) {
    return new StringLiteralTypeInformation(
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
      TypeInformation firstType, TypeInformation secondType) {
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
  bool selectorNeedsUpdate(TypeInformation info, AbstractValue mask) {
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
  TypeInformation narrowType(TypeInformation type, DartType annotation,
      {bool isCast: true, bool excludeNull: false}) {
    // Avoid refining an input with an exact type. It we are almost always
    // adding a narrowing to a subtype of the same class or a superclass.
    if (_abstractValueDomain.isExact(type.type).isDefinitelyTrue) return type;

    AbstractValueWithPrecision narrowing =
        _abstractValueDomain.createFromStaticType(annotation,
            classRelation: ClassRelation.subtype, nullable: isCast);

    AbstractValue abstractValue = narrowing.abstractValue;
    if (excludeNull) {
      abstractValue = _abstractValueDomain.excludeNull(abstractValue);
    }

    if (_abstractValueDomain.containsAll(abstractValue).isPotentiallyTrue) {
      // Top, or non-nullable Top.
      if (_abstractValueDomain.isNull(abstractValue).isPotentiallyTrue) {
        return type;
      }
      // If the input is already narrowed to be not-null, there is no value
      // in adding another narrowing node.
      if (_isNonNullNarrow(type)) return type;
    }

    TypeInformation newType =
        NarrowTypeInformation(_abstractValueDomain, type, abstractValue);
    allocatedTypes.add(newType);
    return newType;
  }

  ParameterTypeInformation getInferredTypeOfParameter(Local parameter) {
    return parameterTypeInformations.putIfAbsent(parameter, () {
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

  MemberTypeInformation getInferredTypeOfMember(MemberEntity member) {
    assert(!member.isAbstract,
        failedAt(member, "Unexpected abstract member $member."));
    return memberTypeInformations[member] ??= _getInferredTypeOfMember(member);
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
    assert(mask != null);
    return concreteTypes.putIfAbsent(mask, () {
      return new ConcreteTypeInformation(mask);
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

  TypeInformation allocateList(
      TypeInformation type, ir.TreeNode node, MemberEntity enclosing,
      [TypeInformation elementType, int length]) {
    assert(strategy.checkListNode(node));
    ClassEntity typedDataClass = _closedWorld.commonElements.typedDataClass;
    bool isTypedArray = typedDataClass != null &&
        _closedWorld.classHierarchy.isInstantiated(typedDataClass) &&
        _abstractValueDomain
            .isInstanceOfOrNull(type.type, typedDataClass)
            .isDefinitelyTrue;
    bool isConst = (type.type == _abstractValueDomain.constListType);
    bool isFixed = (type.type == _abstractValueDomain.fixedListType) ||
        isConst ||
        isTypedArray;
    bool isElementInferred = isConst || isTypedArray;

    int inferredLength = isFixed ? length : null;
    AbstractValue elementTypeMask =
        isElementInferred ? elementType.type : dynamicType.type;
    AbstractValue mask = _abstractValueDomain.createContainerValue(
        type.type, node, enclosing, elementTypeMask, inferredLength);
    ElementInContainerTypeInformation element =
        new ElementInContainerTypeInformation(
            _abstractValueDomain, currentMember, elementType);
    element.inferred = isElementInferred;

    allocatedTypes.add(element);
    return allocatedLists[node] = new ListTypeInformation(
        _abstractValueDomain, currentMember, mask, element, length);
  }

  /// Creates a [TypeInformation] object either for the closurization of a
  /// static or top-level method [element] used as a function constant or for
  /// the synthesized 'call' method [element] created for a local function.
  TypeInformation allocateClosure(FunctionEntity element) {
    TypeInformation result = new ClosureTypeInformation(
        _abstractValueDomain, currentMember, element);
    allocatedClosures.add(result);
    return result;
  }

  TypeInformation allocateSet(
      TypeInformation type, ir.TreeNode node, MemberEntity enclosing,
      [TypeInformation elementType]) {
    assert(strategy.checkSetNode(node));
    bool isConst = type.type == _abstractValueDomain.constSetType;

    AbstractValue elementTypeMask =
        isConst ? elementType.type : dynamicType.type;
    AbstractValue mask = _abstractValueDomain.createSetValue(
        type.type, node, enclosing, elementTypeMask);
    ElementInSetTypeInformation element = new ElementInSetTypeInformation(
        _abstractValueDomain, currentMember, elementType);
    element.inferred = isConst;

    allocatedTypes.add(element);
    return allocatedSets[node] =
        new SetTypeInformation(currentMember, mask, element);
  }

  TypeInformation allocateMap(
      ConcreteTypeInformation type, ir.TreeNode node, MemberEntity element,
      [List<TypeInformation> keyTypes, List<TypeInformation> valueTypes]) {
    assert(strategy.checkMapNode(node));
    assert(keyTypes.length == valueTypes.length);
    bool isFixed = (type.type == _abstractValueDomain.constMapType);

    TypeInformation keyType, valueType;
    for (int i = 0; i < keyTypes.length; ++i) {
      TypeInformation type = keyTypes[i];
      keyType = keyType == null
          ? allocatePhi(null, null, type, isTry: false)
          : addPhiInput(null, keyType, type);

      type = valueTypes[i];
      valueType = valueType == null
          ? allocatePhi(null, null, type, isTry: false)
          : addPhiInput(null, valueType, type);
    }

    keyType =
        keyType == null ? nonNullEmpty() : simplifyPhi(null, null, keyType);
    valueType =
        valueType == null ? nonNullEmpty() : simplifyPhi(null, null, valueType);

    AbstractValue keyTypeMask, valueTypeMask;
    if (isFixed) {
      keyTypeMask = keyType.type;
      valueTypeMask = valueType.type;
    } else {
      keyTypeMask = valueTypeMask = dynamicType.type;
    }
    AbstractValue mask = _abstractValueDomain.createMapValue(
        type.type, node, element, keyTypeMask, valueTypeMask);

    TypeInformation keyTypeInfo = new KeyInMapTypeInformation(
        _abstractValueDomain, currentMember, keyType);
    TypeInformation valueTypeInfo = new ValueInMapTypeInformation(
        _abstractValueDomain, currentMember, valueType);
    allocatedTypes.add(keyTypeInfo);
    allocatedTypes.add(valueTypeInfo);

    MapTypeInformation map =
        new MapTypeInformation(currentMember, mask, keyTypeInfo, valueTypeInfo);

    for (int i = 0; i < keyTypes.length; ++i) {
      TypeInformation newType = map.addEntryInput(
          _abstractValueDomain, keyTypes[i], valueTypes[i], true);
      if (newType != null) allocatedTypes.add(newType);
    }

    // Shortcut: If we already have a first approximation of the key/value type,
    // start propagating it early.
    if (isFixed) map.markAsInferred();

    allocatedMaps[node] = map;
    return map;
  }

  AbstractValue newTypedSelector(TypeInformation info, AbstractValue mask) {
    // Only type the selector if [info] is concrete, because the other
    // kinds of [TypeInformation] have the empty type at this point of
    // analysis.
    return info.isConcrete ? info.type : mask;
  }

  /// Returns a new type that unions [firstInput] and [secondInput].
  TypeInformation allocateDiamondPhi(
      TypeInformation firstInput, TypeInformation secondInput) {
    PhiElementTypeInformation result = new PhiElementTypeInformation(
        _abstractValueDomain, currentMember, null, null,
        isTry: false);
    result.addInput(firstInput);
    result.addInput(secondInput);
    allocatedTypes.add(result);
    return result;
  }

  PhiElementTypeInformation _addPhi(
      ir.Node node, Local variable, TypeInformation inputType, bool isTry) {
    PhiElementTypeInformation result = new PhiElementTypeInformation(
        _abstractValueDomain, currentMember, node, variable,
        isTry: isTry);
    allocatedTypes.add(result);
    result.addInput(inputType);
    return result;
  }

  /// Returns a new type for holding the potential types of [element].
  /// [inputType] is the first incoming type of the phi.
  PhiElementTypeInformation allocatePhi(
      ir.Node node, Local variable, TypeInformation inputType,
      {bool isTry}) {
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
      {bool isTry}) {
    assert(strategy.checkLoopPhiNode(node));
    return _addPhi(node, variable, inputType, isTry);
  }

  /// Simplies the phi representing [element] and of the type
  /// [phiType]. For example, if this phi has one incoming input, an
  /// implementation of this method could just return that incoming
  /// input type.
  TypeInformation simplifyPhi(
      ir.Node node, Local variable, PhiElementTypeInformation phiType) {
    assert(phiType.branchNode == node);
    if (phiType.inputs.length == 1) return phiType.inputs.first;
    return phiType;
  }

  /// Adds [newType] as an input of [phiType].
  PhiElementTypeInformation addPhiInput(Local variable,
      PhiElementTypeInformation phiType, TypeInformation newType) {
    phiType.addInput(newType);
    return phiType;
  }

  AbstractValue computeTypeMask(Iterable<TypeInformation> assignments) {
    return joinTypeMasks(assignments.map((e) => e.type));
  }

  AbstractValue joinTypeMasks(Iterable<AbstractValue> masks) {
    var dynamicType = _abstractValueDomain.dynamicType;
    // Optimization: we are iterating over masks twice, but because `masks` is a
    // mapped iterable, we save the intermediate results to avoid computing them
    // again.
    var list = [];
    bool isDynamicIngoringNull = false;
    bool mayBeNull = false;
    for (AbstractValue mask in masks) {
      // Don't do any work on computing unions if we know that after all that
      // work the result will be `dynamic`.
      // TODO(sigmund): change to `mask == dynamicType` so we can continue to
      // track the non-nullable bit.
      if (_abstractValueDomain.containsAll(mask).isPotentiallyTrue) {
        isDynamicIngoringNull = true;
      }
      if (_abstractValueDomain.isNull(mask).isPotentiallyTrue) {
        mayBeNull = true;
      }
      if (isDynamicIngoringNull && mayBeNull) return dynamicType;
      list.add(mask);
    }

    AbstractValue newType = null;
    for (AbstractValue mask in list) {
      newType =
          newType == null ? mask : _abstractValueDomain.union(newType, mask);
      // Likewise - stop early if we already reach dynamic.
      if (_abstractValueDomain.containsAll(newType).isPotentiallyTrue) {
        isDynamicIngoringNull = true;
      }
      if (_abstractValueDomain.isNull(newType).isPotentiallyTrue) {
        mayBeNull = true;
      }
      if (isDynamicIngoringNull && mayBeNull) return dynamicType;
    }

    return newType ?? _abstractValueDomain.emptyType;
  }
}
