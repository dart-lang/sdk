// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../common.dart';
import '../elements/elements.dart';
import '../elements/entities.dart';
import '../elements/resolution_types.dart'
    show ResolutionDartType, ResolutionInterfaceType;
import '../tree/nodes.dart' as ast;
import '../types/masks.dart';
import '../universe/selector.dart';
import '../world.dart';
import 'type_graph_nodes.dart';

/**
 * The class [SimpleInferrerVisitor] will use when working on types.
 */
class TypeSystem {
  final ClosedWorld closedWorld;

  /// [ElementTypeInformation]s for elements.
  final Map<Element, TypeInformation> typeInformations =
      new Map<Element, TypeInformation>();

  /// [ListTypeInformation] for allocated lists.
  final Map<ast.Node, TypeInformation> allocatedLists =
      new Map<ast.Node, TypeInformation>();

  /// [MapTypeInformation] for allocated Maps.
  final Map<ast.Node, TypeInformation> allocatedMaps =
      new Map<ast.Node, TypeInformation>();

  /// Closures found during the analysis.
  final Set<TypeInformation> allocatedClosures = new Set<TypeInformation>();

  /// Cache of [ConcreteTypeInformation].
  final Map<TypeMask, TypeInformation> concreteTypes =
      new Map<TypeMask, TypeInformation>();

  /// List of [TypeInformation]s for calls inside method bodies.
  final List<CallSiteTypeInformation> allocatedCalls =
      <CallSiteTypeInformation>[];

  /// List of [TypeInformation]s allocated inside method bodies (narrowing,
  /// phis, and containers).
  final List<TypeInformation> allocatedTypes = <TypeInformation>[];

  Iterable<TypeInformation> get allTypes => [
        typeInformations.values,
        allocatedLists.values,
        allocatedMaps.values,
        allocatedClosures,
        concreteTypes.values,
        allocatedCalls,
        allocatedTypes
      ].expand((x) => x);

  TypeSystem(this.closedWorld) {
    nonNullEmptyType = getConcreteTypeFor(commonMasks.emptyType);
  }

  CommonMasks get commonMasks => closedWorld.commonMasks;

  /// Used to group [TypeInformation] nodes by the element that triggered their
  /// creation.
  MemberTypeInformation _currentMember = null;
  MemberTypeInformation get currentMember => _currentMember;

  void withMember(MemberElement element, action) {
    assert(_currentMember == null,
        failedAt(element, "Already constructing graph for $_currentMember."));
    _currentMember = getInferredTypeOfMember(element);
    action();
    _currentMember = null;
  }

  TypeInformation nullTypeCache;
  TypeInformation get nullType {
    if (nullTypeCache != null) return nullTypeCache;
    return nullTypeCache = getConcreteTypeFor(commonMasks.nullType);
  }

  TypeInformation intTypeCache;
  TypeInformation get intType {
    if (intTypeCache != null) return intTypeCache;
    return intTypeCache = getConcreteTypeFor(commonMasks.intType);
  }

  TypeInformation uint32TypeCache;
  TypeInformation get uint32Type {
    if (uint32TypeCache != null) return uint32TypeCache;
    return uint32TypeCache = getConcreteTypeFor(commonMasks.uint32Type);
  }

  TypeInformation uint31TypeCache;
  TypeInformation get uint31Type {
    if (uint31TypeCache != null) return uint31TypeCache;
    return uint31TypeCache = getConcreteTypeFor(commonMasks.uint31Type);
  }

  TypeInformation positiveIntTypeCache;
  TypeInformation get positiveIntType {
    if (positiveIntTypeCache != null) return positiveIntTypeCache;
    return positiveIntTypeCache =
        getConcreteTypeFor(commonMasks.positiveIntType);
  }

  TypeInformation doubleTypeCache;
  TypeInformation get doubleType {
    if (doubleTypeCache != null) return doubleTypeCache;
    return doubleTypeCache = getConcreteTypeFor(commonMasks.doubleType);
  }

  TypeInformation numTypeCache;
  TypeInformation get numType {
    if (numTypeCache != null) return numTypeCache;
    return numTypeCache = getConcreteTypeFor(commonMasks.numType);
  }

  TypeInformation boolTypeCache;
  TypeInformation get boolType {
    if (boolTypeCache != null) return boolTypeCache;
    return boolTypeCache = getConcreteTypeFor(commonMasks.boolType);
  }

  TypeInformation functionTypeCache;
  TypeInformation get functionType {
    if (functionTypeCache != null) return functionTypeCache;
    return functionTypeCache = getConcreteTypeFor(commonMasks.functionType);
  }

  TypeInformation listTypeCache;
  TypeInformation get listType {
    if (listTypeCache != null) return listTypeCache;
    return listTypeCache = getConcreteTypeFor(commonMasks.listType);
  }

  TypeInformation constListTypeCache;
  TypeInformation get constListType {
    if (constListTypeCache != null) return constListTypeCache;
    return constListTypeCache = getConcreteTypeFor(commonMasks.constListType);
  }

  TypeInformation fixedListTypeCache;
  TypeInformation get fixedListType {
    if (fixedListTypeCache != null) return fixedListTypeCache;
    return fixedListTypeCache = getConcreteTypeFor(commonMasks.fixedListType);
  }

  TypeInformation growableListTypeCache;
  TypeInformation get growableListType {
    if (growableListTypeCache != null) return growableListTypeCache;
    return growableListTypeCache =
        getConcreteTypeFor(commonMasks.growableListType);
  }

  TypeInformation mapTypeCache;
  TypeInformation get mapType {
    if (mapTypeCache != null) return mapTypeCache;
    return mapTypeCache = getConcreteTypeFor(commonMasks.mapType);
  }

  TypeInformation constMapTypeCache;
  TypeInformation get constMapType {
    if (constMapTypeCache != null) return constMapTypeCache;
    return constMapTypeCache = getConcreteTypeFor(commonMasks.constMapType);
  }

  TypeInformation stringTypeCache;
  TypeInformation get stringType {
    if (stringTypeCache != null) return stringTypeCache;
    return stringTypeCache = getConcreteTypeFor(commonMasks.stringType);
  }

  TypeInformation typeTypeCache;
  TypeInformation get typeType {
    if (typeTypeCache != null) return typeTypeCache;
    return typeTypeCache = getConcreteTypeFor(commonMasks.typeType);
  }

  TypeInformation dynamicTypeCache;
  TypeInformation get dynamicType {
    if (dynamicTypeCache != null) return dynamicTypeCache;
    return dynamicTypeCache = getConcreteTypeFor(commonMasks.dynamicType);
  }

  TypeInformation asyncFutureTypeCache;
  // Subtype of Future returned by async methods.
  TypeInformation get asyncFutureType {
    if (asyncFutureTypeCache != null) return asyncFutureTypeCache;
    return asyncFutureTypeCache =
        getConcreteTypeFor(commonMasks.asyncFutureType);
  }

  TypeInformation syncStarIterableTypeCache;
  TypeInformation get syncStarIterableType {
    if (syncStarIterableTypeCache != null) return syncStarIterableTypeCache;
    return syncStarIterableTypeCache =
        getConcreteTypeFor(commonMasks.syncStarIterableType);
  }

  TypeInformation asyncStarStreamTypeCache;
  TypeInformation get asyncStarStreamType {
    if (asyncStarStreamTypeCache != null) return asyncStarStreamTypeCache;
    return asyncStarStreamTypeCache =
        getConcreteTypeFor(commonMasks.asyncStarStreamType);
  }

  TypeInformation nonNullEmptyType;

  TypeInformation stringLiteralType(String value) {
    return new StringLiteralTypeInformation(value, commonMasks.stringType);
  }

  TypeInformation boolLiteralType(bool value) {
    return new BoolLiteralTypeInformation(value, commonMasks.boolType);
  }

  /**
   * Returns the least upper bound between [firstType] and
   * [secondType].
   */
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
        firstType.type.union(secondType.type, closedWorld));
  }

  /**
   * Returns `true` if `selector` should be updated to reflect the new
   * `receiverType`.
   */
  bool selectorNeedsUpdate(TypeInformation info, TypeMask mask) {
    return info.type != mask;
  }

  /**
   * Returns a new receiver type for this [selector] applied to
   * [receiverType].
   *
   * The option [isConditional] is true when [selector] was seen in a
   * conditional send (e.g.  `a?.selector`), in which case the returned type may
   * be null.
   */
  TypeInformation refineReceiver(Selector selector, TypeMask mask,
      TypeInformation receiver, bool isConditional) {
    if (receiver.type.isExact) return receiver;
    TypeMask otherType = closedWorld.computeReceiverType(selector, mask);
    // Conditional sends (a?.b) can still narrow the possible types of `a`,
    // however, we still need to consider that `a` may be null.
    if (isConditional) {
      // Note: we don't check that receiver.type.isNullable here because this is
      // called during the graph construction.
      otherType = otherType.nullable();
    }
    // If this is refining to nullable subtype of `Object` just return
    // the receiver. We know the narrowing is useless.
    if (otherType.isNullable && otherType.containsAll(closedWorld)) {
      return receiver;
    }
    assert(TypeMask.assertIsNormalized(otherType, closedWorld));
    TypeInformation newType = new NarrowTypeInformation(receiver, otherType);
    allocatedTypes.add(newType);
    return newType;
  }

  /**
   * Returns the intersection between [type] and [annotation].
   * [isNullable] indicates whether the annotation implies a null
   * type.
   */
  TypeInformation narrowType(
      TypeInformation type, ResolutionDartType annotation,
      {bool isNullable: true}) {
    if (annotation.treatAsDynamic) return type;
    if (annotation.isVoid) return type;
    if (annotation.element == closedWorld.commonElements.objectClass &&
        isNullable) {
      return type;
    }
    TypeMask otherType;
    if (annotation.isTypedef || annotation.isFunctionType) {
      otherType = functionType.type;
    } else if (annotation.isTypeVariable) {
      // TODO(ngeoffray): Narrow to bound.
      return type;
    } else {
      ResolutionInterfaceType interface = annotation;
      otherType = annotation.element == closedWorld.commonElements.objectClass
          ? dynamicType.type.nonNullable()
          : new TypeMask.nonNullSubtype(interface.element, closedWorld);
    }
    if (isNullable) otherType = otherType.nullable();
    if (type.type.isExact) {
      return type;
    } else {
      assert(TypeMask.assertIsNormalized(otherType, closedWorld));
      TypeInformation newType = new NarrowTypeInformation(type, otherType);
      allocatedTypes.add(newType);
      return newType;
    }
  }

  /**
   * Returns the non-nullable type of [type].
   */
  TypeInformation narrowNotNull(TypeInformation type) {
    if (type.type.isExact && !type.type.isNullable) {
      return type;
    }
    TypeInformation newType =
        new NarrowTypeInformation(type, dynamicType.type.nonNullable());
    allocatedTypes.add(newType);
    return newType;
  }

  ElementTypeInformation getInferredTypeOfParameter(ParameterElement element) {
    return _getInferredTypeOf(element);
  }

  ElementTypeInformation getInferredTypeOfMember(MemberElement element) {
    return _getInferredTypeOf(element);
  }

  @deprecated
  ElementTypeInformation _getInferredTypeOf(Element element) {
    element = element.implementation;
    assert(element.isParameter || element is MemberElement);
    return typeInformations[element] ??=
        new ElementTypeInformation(element, this);
  }

  /**
   * Returns the internal inferrer representation for [mask].
   */
  ConcreteTypeInformation getConcreteTypeFor(TypeMask mask) {
    assert(mask != null);
    return concreteTypes.putIfAbsent(mask, () {
      return new ConcreteTypeInformation(mask);
    });
  }

  String getInferredSignatureOfMethod(MethodElement function) {
    ElementTypeInformation info = getInferredTypeOfMember(function);
    MethodElement impl = function.implementation;
    FunctionSignature signature = impl.functionSignature;
    var res = "";
    signature.forEachParameter((Element parameter) {
      TypeInformation type = getInferredTypeOfParameter(parameter);
      res += "${res.isEmpty ? '(' : ', '}${type.type} ${parameter.name}";
    });
    res += ") -> ${info.type}";
    return res;
  }

  TypeInformation nonNullSubtype(ClassElement type) {
    return getConcreteTypeFor(
        new TypeMask.nonNullSubtype(type.declaration, closedWorld));
  }

  TypeInformation nonNullSubclass(ClassElement type) {
    return getConcreteTypeFor(
        new TypeMask.nonNullSubclass(type.declaration, closedWorld));
  }

  TypeInformation nonNullExact(ClassElement type) {
    return getConcreteTypeFor(
        new TypeMask.nonNullExact(type.declaration, closedWorld));
  }

  TypeInformation nonNullEmpty() {
    return nonNullEmptyType;
  }

  bool isNull(TypeInformation type) {
    return type == nullType;
  }

  TypeInformation allocateList(
      TypeInformation type, ast.Node node, Element enclosing,
      [TypeInformation elementType, int length]) {
    ClassElement typedDataClass = closedWorld.commonElements.typedDataClass;
    bool isTypedArray = typedDataClass != null &&
        closedWorld.isInstantiated(typedDataClass) &&
        type.type.satisfies(typedDataClass, closedWorld);
    bool isConst = (type.type == commonMasks.constListType);
    bool isFixed =
        (type.type == commonMasks.fixedListType) || isConst || isTypedArray;
    bool isElementInferred = isConst || isTypedArray;

    int inferredLength = isFixed ? length : null;
    TypeMask elementTypeMask =
        isElementInferred ? elementType.type : dynamicType.type;
    ContainerTypeMask mask = new ContainerTypeMask(
        type.type, node, enclosing, elementTypeMask, inferredLength);
    ElementInContainerTypeInformation element =
        new ElementInContainerTypeInformation(currentMember, elementType);
    element.inferred = isElementInferred;

    allocatedTypes.add(element);
    return allocatedLists[node] =
        new ListTypeInformation(currentMember, mask, element, length);
  }

  /// Creates a [TypeInformation] object either for the closurization of a
  /// static or top-level method [element] used as a function constant or for
  /// the synthesized 'call' method [element] created for a local function.
  TypeInformation allocateClosure(ast.Node node, MethodElement element) {
    TypeInformation result =
        new ClosureTypeInformation(currentMember, node, element);
    allocatedClosures.add(result);
    return result;
  }

  TypeInformation allocateMap(
      ConcreteTypeInformation type, ast.Node node, Element element,
      [List<TypeInformation> keyTypes, List<TypeInformation> valueTypes]) {
    assert(keyTypes.length == valueTypes.length);
    bool isFixed = (type.type == commonMasks.constMapType);

    TypeMask keyType, valueType;
    if (isFixed) {
      keyType = keyTypes.fold(nonNullEmptyType.type,
          (type, info) => type.union(info.type, closedWorld));
      valueType = valueTypes.fold(nonNullEmptyType.type,
          (type, info) => type.union(info.type, closedWorld));
    } else {
      keyType = valueType = dynamicType.type;
    }
    MapTypeMask mask =
        new MapTypeMask(type.type, node, element, keyType, valueType);

    TypeInformation keyTypeInfo =
        new KeyInMapTypeInformation(currentMember, null);
    TypeInformation valueTypeInfo =
        new ValueInMapTypeInformation(currentMember, null);
    allocatedTypes.add(keyTypeInfo);
    allocatedTypes.add(valueTypeInfo);

    MapTypeInformation map =
        new MapTypeInformation(currentMember, mask, keyTypeInfo, valueTypeInfo);

    for (int i = 0; i < keyTypes.length; ++i) {
      TypeInformation newType =
          map.addEntryAssignment(keyTypes[i], valueTypes[i], true);
      if (newType != null) allocatedTypes.add(newType);
    }

    // Shortcut: If we already have a first approximation of the key/value type,
    // start propagating it early.
    if (isFixed) map.markAsInferred();

    allocatedMaps[node] = map;
    return map;
  }

  TypeMask newTypedSelector(TypeInformation info, TypeMask mask) {
    // Only type the selector if [info] is concrete, because the other
    // kinds of [TypeInformation] have the empty type at this point of
    // analysis.
    return info.isConcrete ? info.type : mask;
  }

  /**
   * Returns a new type that unions [firstInput] and [secondInput].
   */
  TypeInformation allocateDiamondPhi(
      TypeInformation firstInput, TypeInformation secondInput) {
    PhiElementTypeInformation result =
        new PhiElementTypeInformation(currentMember, null, false, null);
    result.addAssignment(firstInput);
    result.addAssignment(secondInput);
    allocatedTypes.add(result);
    return result;
  }

  PhiElementTypeInformation _addPhi(
      ast.Node node, Local variable, inputType, bool isLoop) {
    PhiElementTypeInformation result =
        new PhiElementTypeInformation(currentMember, node, isLoop, variable);
    allocatedTypes.add(result);
    result.addAssignment(inputType);
    return result;
  }

  /**
   * Returns a new type for holding the potential types of [element].
   * [inputType] is the first incoming type of the phi.
   */
  PhiElementTypeInformation allocatePhi(
      ast.Node node, Local variable, inputType) {
    // Check if [inputType] is a phi for a local updated in
    // the try/catch block [node]. If it is, no need to allocate a new
    // phi.
    if (inputType is PhiElementTypeInformation &&
        inputType.branchNode == node &&
        inputType.branchNode is ast.TryStatement) {
      return inputType;
    }
    return _addPhi(node, variable, inputType, false);
  }

  /**
   * Returns a new type for holding the potential types of [element].
   * [inputType] is the first incoming type of the phi. [allocateLoopPhi]
   * only differs from [allocatePhi] in that it allows the underlying
   * implementation of [TypeSystem] to differentiate Phi nodes due to loops
   * from other merging uses.
   */
  PhiElementTypeInformation allocateLoopPhi(
      ast.Node node, Local variable, inputType) {
    return _addPhi(node, variable, inputType, true);
  }

  /**
   * Simplies the phi representing [element] and of the type
   * [phiType]. For example, if this phi has one incoming input, an
   * implementation of this method could just return that incoming
   * input type.
   */
  TypeInformation simplifyPhi(
      ast.Node node, Local variable, PhiElementTypeInformation phiType) {
    assert(phiType.branchNode == node);
    if (phiType.assignments.length == 1) return phiType.assignments.first;
    return phiType;
  }

  /**
   * Adds [newType] as an input of [phiType].
   */
  PhiElementTypeInformation addPhiInput(Local variable,
      PhiElementTypeInformation phiType, TypeInformation newType) {
    phiType.addAssignment(newType);
    return phiType;
  }

  TypeMask computeTypeMask(Iterable<TypeInformation> assignments) {
    return joinTypeMasks(assignments.map((e) => e.type));
  }

  TypeMask joinTypeMasks(Iterable<TypeMask> masks) {
    var dynamicType = commonMasks.dynamicType;
    // Optimization: we are iterating over masks twice, but because `masks` is a
    // mapped iterable, we save the intermediate results to avoid computing them
    // again.
    var list = [];
    for (TypeMask mask in masks) {
      // Don't do any work on computing unions if we know that after all that
      // work the result will be `dynamic`.
      // TODO(sigmund): change to `mask == dynamicType` so we can continue to
      // track the non-nullable bit.
      if (mask.containsAll(closedWorld)) return dynamicType;
      list.add(mask);
    }

    TypeMask newType = null;
    for (TypeMask mask in list) {
      newType = newType == null ? mask : newType.union(mask, closedWorld);
      // Likewise - stop early if we already reach dynamic.
      if (newType.containsAll(closedWorld)) return dynamicType;
    }

    return newType ?? const TypeMask.nonNullEmpty();
  }
}
