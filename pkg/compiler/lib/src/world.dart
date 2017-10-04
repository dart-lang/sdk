// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.world;

import 'common.dart';
import 'constants/constant_system.dart';
import 'common_elements.dart' show CommonElements, ElementEnvironment;
import 'elements/entities.dart';
import 'elements/elements.dart'
    show
        ClassElement,
        Element,
        MemberElement,
        MethodElement,
        MixinApplicationElement;
import 'elements/resolution_types.dart';
import 'elements/types.dart';
import 'js_backend/backend_usage.dart' show BackendUsage;
import 'js_backend/interceptor_data.dart' show InterceptorData;
import 'js_backend/native_data.dart' show NativeData;
import 'js_backend/runtime_types.dart'
    show RuntimeTypesNeed, RuntimeTypesNeedBuilder;
import 'ordered_typeset.dart';
import 'options.dart';
import 'types/masks.dart' show CommonMasks, FlatTypeMask, TypeMask;
import 'universe/class_set.dart';
import 'universe/function_set.dart' show FunctionSet;
import 'universe/selector.dart' show Selector;
import 'universe/side_effects.dart' show SideEffects;
import 'universe/world_builder.dart';
import 'util/util.dart' show Link;

/// Common superinterface for [OpenWorld] and [ClosedWorld].
abstract class World {}

/// The [ClosedWorld] represents the information known about a program when
/// compiling with closed-world semantics.
///
/// Given the entrypoint of an application, we can track what's reachable from
/// it, what functions are called, what classes are allocated, which native
/// JavaScript types are touched, what language features are used, and so on.
/// This precise knowledge about what's live in the program is later used in
/// optimizations and other compiler decisions during code generation.
abstract class ClosedWorld implements World {
  BackendUsage get backendUsage;

  NativeData get nativeData;

  InterceptorData get interceptorData;

  ElementEnvironment get elementEnvironment;

  DartTypes get dartTypes;

  CommonElements get commonElements;

  CommonMasks get commonMasks;

  ConstantSystem get constantSystem;

  RuntimeTypesNeed get rtiNeed;

  Iterable<ClassEntity> get liveNativeClasses;

  Iterable<MemberEntity> get processedMembers;

  /// Returns `true` if [cls] is either directly or indirectly instantiated.
  bool isInstantiated(ClassEntity cls);

  /// Returns `true` if [cls] is directly instantiated. This means that at
  /// runtime instances of exactly [cls] are assumed to exist.
  bool isDirectlyInstantiated(ClassEntity cls);

  /// Returns `true` if [cls] is abstractly instantiated. This means that at
  /// runtime instances of [cls] or unknown subclasses of [cls] are assumed to
  /// exist.
  ///
  /// This is used to mark native and/or reflectable classes as instantiated.
  /// For native classes we do not know the exact class that instantiates [cls]
  /// so [cls] here represents the root of the subclasses. For reflectable
  /// classes we need event abstract classes to be 'live' even though they
  /// cannot themselves be instantiated.
  bool isAbstractlyInstantiated(ClassEntity cls);

  /// Returns `true` if [cls] is either directly or abstractly instantiated.
  ///
  /// See [isDirectlyInstantiated] and [isAbstractlyInstantiated].
  bool isExplicitlyInstantiated(ClassEntity cls);

  /// Returns `true` if [cls] is indirectly instantiated, that is through a
  /// subclass.
  bool isIndirectlyInstantiated(ClassEntity cls);

  /// Returns `true` if [cls] is abstract and thus can only be instantiated
  /// through subclasses.
  bool isAbstract(ClassEntity cls);

  /// Returns `true` if [cls] is implemented by an instantiated class.
  bool isImplemented(ClassEntity cls);

  /// Return `true` if [x] is a subclass of [y].
  bool isSubclassOf(ClassEntity x, ClassEntity y);

  /// Returns `true` if [x] is a subtype of [y], that is, if [x] implements an
  /// instance of [y].
  bool isSubtypeOf(ClassEntity x, ClassEntity y);

  /// Returns an iterable over the live classes that extend [cls] including
  /// [cls] itself.
  Iterable<ClassEntity> subclassesOf(ClassEntity cls);

  /// Returns an iterable over the live classes that extend [cls] _not_
  /// including [cls] itself.
  Iterable<ClassEntity> strictSubclassesOf(ClassEntity cls);

  /// Returns the number of live classes that extend [cls] _not_
  /// including [cls] itself.
  int strictSubclassCount(ClassEntity cls);

  /// Applies [f] to each live class that extend [cls] _not_ including [cls]
  /// itself.
  void forEachStrictSubclassOf(
      ClassEntity cls, IterationStep f(ClassEntity cls));

  /// Returns `true` if [predicate] applies to any live class that extend [cls]
  /// _not_ including [cls] itself.
  bool anyStrictSubclassOf(ClassEntity cls, bool predicate(ClassEntity cls));

  /// Returns an iterable over the directly instantiated that implement [cls]
  /// possibly including [cls] itself, if it is live.
  Iterable<ClassEntity> subtypesOf(ClassEntity cls);

  /// Returns an iterable over the live classes that implement [cls] _not_
  /// including [cls] if it is live.
  Iterable<ClassEntity> strictSubtypesOf(ClassEntity cls);

  /// Returns the number of live classes that implement [cls] _not_
  /// including [cls] itself.
  int strictSubtypeCount(ClassEntity cls);

  /// Applies [f] to each live class that implements [cls] _not_ including [cls]
  /// itself.
  void forEachStrictSubtypeOf(
      ClassEntity cls, IterationStep f(ClassEntity cls));

  /// Returns `true` if [predicate] applies to any live class that implements
  /// [cls] _not_ including [cls] itself.
  bool anyStrictSubtypeOf(ClassEntity cls, bool predicate(ClassEntity cls));

  /// Returns `true` if [a] and [b] have any known common subtypes.
  bool haveAnyCommonSubtypes(ClassEntity a, ClassEntity b);

  /// Returns `true` if any live class other than [cls] extends [cls].
  bool hasAnyStrictSubclass(ClassEntity cls);

  /// Returns `true` if any live class other than [cls] implements [cls].
  bool hasAnyStrictSubtype(ClassEntity cls);

  /// Returns `true` if all live classes that implement [cls] extend it.
  bool hasOnlySubclasses(ClassEntity cls);

  /// Returns the most specific subclass of [cls] (including [cls]) that is
  /// directly instantiated or a superclass of all directly instantiated
  /// subclasses. If [cls] is not instantiated, `null` is returned.
  ClassEntity getLubOfInstantiatedSubclasses(ClassEntity cls);

  /// Returns the most specific subtype of [cls] (including [cls]) that is
  /// directly instantiated or a superclass of all directly instantiated
  /// subtypes. If no subtypes of [cls] are instantiated, `null` is returned.
  ClassEntity getLubOfInstantiatedSubtypes(ClassEntity cls);

  /// Returns an iterable over the common supertypes of the [classes].
  Iterable<ClassEntity> commonSupertypesOf(Iterable<ClassEntity> classes);

  /// Returns an iterable of the classes that are contained in the
  /// strict subclass/subtype sets of both [cls1] and [cls2].
  ///
  /// Classes that are implied by included superclasses/supertypes are not
  /// returned.
  ///
  /// For instance for this hierarchy
  ///
  ///     class A {}
  ///     class B {}
  ///     class C implements A, B {}
  ///     class D extends C {}
  ///
  /// the query
  ///
  ///     commonSubclasses(A, ClassQuery.SUBTYPE, B, ClassQuery.SUBTYPE)
  ///
  /// return the set {C} because [D] is implied by [C].
  Iterable<ClassEntity> commonSubclasses(
      ClassEntity cls1, ClassQuery query1, ClassEntity cls2, ClassQuery query2);

  /// Returns an iterable over the live mixin applications that mixin [cls].
  Iterable<ClassEntity> mixinUsesOf(ClassEntity cls);

  /// Returns `true` if [cls] is mixed into a live class.
  bool isUsedAsMixin(ClassEntity cls);

  /// Returns `true` if any live class that mixes in [cls] implements [type].
  bool hasAnySubclassOfMixinUseThatImplements(
      ClassEntity cls, ClassEntity type);

  /// Returns `true` if any live class that mixes in [mixin] is also a subclass
  /// of [superclass].
  bool hasAnySubclassThatMixes(ClassEntity superclass, ClassEntity mixin);

  /// Returns `true` if [cls] or any superclass mixes in [mixin].
  bool isSubclassOfMixinUseOf(ClassEntity cls, ClassEntity mixin);

  /// Returns `true` if every subtype of [x] is a subclass of [y] or a subclass
  /// of a mixin application of [y].
  bool everySubtypeIsSubclassOfOrMixinUseOf(ClassEntity x, ClassEntity y);

  /// Returns `true` if any subclass of [superclass] implements [type].
  bool hasAnySubclassThatImplements(ClassEntity superclass, ClassEntity type);

  /// Returns `true` if a call of [selector] on [cls] and/or subclasses/subtypes
  /// need noSuchMethod handling.
  ///
  /// If the receiver is guaranteed to have a member that matches what we're
  /// looking for, there's no need to introduce a noSuchMethod handler. It will
  /// never be called.
  ///
  /// As an example, consider this class hierarchy:
  ///
  ///                   A    <-- noSuchMethod
  ///                  / \
  ///                 C   B  <-- foo
  ///
  /// If we know we're calling foo on an object of type B we don't have to worry
  /// about the noSuchMethod method in A because objects of type B implement
  /// foo. On the other hand, if we end up calling foo on something of type C we
  /// have to add a handler for it.
  ///
  /// If the holders of all user-defined noSuchMethod implementations that might
  /// be applicable to the receiver type have a matching member for the current
  /// name and selector, we avoid introducing a noSuchMethod handler.
  ///
  /// As an example, consider this class hierarchy:
  ///
  ///                        A    <-- foo
  ///                       / \
  ///    noSuchMethod -->  B   C  <-- bar
  ///                      |   |
  ///                      C   D  <-- noSuchMethod
  ///
  /// When calling foo on an object of type A, we know that the implementations
  /// of noSuchMethod are in the classes B and D that also (indirectly)
  /// implement foo, so we do not need a handler for it.
  ///
  /// If we're calling bar on an object of type D, we don't need the handler
  /// either because all objects of type D implement bar through inheritance.
  ///
  /// If we're calling bar on an object of type A we do need the handler because
  /// we may have to call B.noSuchMethod since B does not implement bar.
  bool needsNoSuchMethod(ClassEntity cls, Selector selector, ClassQuery query);

  /// Returns whether [element] will be the one used at runtime when being
  /// invoked on an instance of [cls]. [selector] is used to ensure library
  /// privacy is taken into account.
  bool hasElementIn(
      covariant ClassEntity cls, Selector selector, covariant Entity element);

  /// Returns [ClassHierarchyNode] for [cls] used to model the class hierarchies
  /// of known classes.
  ///
  /// This method is only provided for testing. For queries on classes, use the
  /// methods defined in [ClosedWorld].
  ClassHierarchyNode getClassHierarchyNode(ClassEntity cls);

  /// Returns [ClassSet] for [cls] used to model the extends and implements
  /// relations of known classes.
  ///
  /// This method is only provided for testing. For queries on classes, use the
  /// methods defined in [ClosedWorld].
  ClassSet getClassSet(ClassEntity cls);

  /// Return the cached mask for [base] with the given flags, or
  /// calls [createMask] to create the mask and cache it.
  // TODO(johnniwinther): Find a better strategy for caching these?
  TypeMask getCachedMask(ClassEntity base, int flags, TypeMask createMask());

  /// Returns `true` if the field [element] is known to be effectively final.
  bool fieldNeverChanges(MemberEntity element);

  /// Extends the receiver type [mask] for calling [selector] to take live
  /// `noSuchMethod` handlers into account.
  TypeMask extendMaskIfReachesAll(Selector selector, TypeMask mask);

  /// Returns all resolved typedefs.
  Iterable<TypedefEntity> get allTypedefs;

  /// Returns the mask for the potential receivers of a dynamic call to
  /// [selector] on [mask].
  ///
  /// This will narrow the constraints of [mask] to a [TypeMask] of the
  /// set of classes that actually implement the selected member or implement
  /// the handling 'noSuchMethod' where the selected member is unimplemented.
  TypeMask computeReceiverType(Selector selector, TypeMask mask);

  /// Returns all the instance members that may be invoked with the
  /// [selector] on a receiver with the given [mask]. The returned elements may
  /// include noSuchMethod handlers that are potential targets indirectly
  /// through the noSuchMethod mechanism.
  Iterable<MemberEntity> locateMembers(Selector selector, TypeMask mask);

  /// Returns the single [MemberEntity] that matches a call to [selector] on a
  /// receiver of type [mask]. If multiple targets exist, `null` is returned.
  MemberEntity locateSingleElement(Selector selector, TypeMask mask);

  /// Returns the single field that matches a call to [selector] on a
  /// receiver of type [mask]. If multiple targets exist or the single target
  /// is not a field, `null` is returned.
  FieldEntity locateSingleField(Selector selector, TypeMask mask);

  /// Returns the side effects of executing [element].
  SideEffects getSideEffectsOfElement(FunctionEntity element);

  /// Returns the side effects of calling [selector] on a receiver of type
  /// [mask].
  SideEffects getSideEffectsOfSelector(Selector selector, TypeMask mask);

  /// Returns `true` if [element] is guaranteed not to throw an exception.
  bool getCannotThrow(FunctionEntity element);

  /// Returns `true` if [element] is called in a loop.
  // TODO(johnniwinther): Is this 'potentially called' or 'known to be called'?
  // TODO(johnniwinther): Change [MemberEntity] to [FunctionEntity].
  bool isCalledInLoop(MemberEntity element);

  /// Returns `true` if [element] might be passed to `Function.apply`.
  // TODO(johnniwinther): Is this 'passed invocation target` or
  // `passed as argument`?
  bool getMightBePassedToApply(FunctionEntity element);

  /// Returns a string representation of the closed world.
  ///
  /// If [cls] is provided, the dump will contain only classes related to [cls].
  String dump([ClassEntity cls]);
}

/// Interface for computing side effects and uses of elements. This is used
/// during type inference to compute the [ClosedWorld] for code generation.
abstract class ClosedWorldRefiner {
  /// The closed world being refined.
  ClosedWorld get closedWorld;

  /// Registers the side [effects] of executing [element].
  void registerSideEffects(FunctionEntity element, SideEffects effects);

  /// Registers the executing of [element] as without side effects.
  void registerSideEffectsFree(FunctionEntity element);

  /// Returns the currently known side effects of executing [element].
  SideEffects getCurrentlyKnownSideEffects(FunctionEntity element);

  /// Registers that [element] might be passed to `Function.apply`.
  // TODO(johnniwinther): Is this 'passed invocation target` or
  // `passed as argument`?
  void registerMightBePassedToApply(FunctionEntity element);

  /// Returns `true` if [element] might be passed to `Function.apply` given the
  /// currently inferred information.
  bool getCurrentlyKnownMightBePassedToApply(FunctionEntity element);

  /// Registers that [element] is called in a loop.
  // TODO(johnniwinther): Is this 'potentially called' or 'known to be called'?
  void addFunctionCalledInLoop(MemberEntity element);

  /// Registers that [element] is guaranteed not to throw an exception.
  void registerCannotThrow(FunctionEntity element);

  /// Adds the closure class [cls] to the inference world. The class is
  /// considered directly instantiated. If [fromInstanceMember] is true, this
  /// closure class represents a closure that is inside an instance member, thus
  /// has access to `this`.
  void registerClosureClass(ClassEntity cls);
}

abstract class OpenWorld implements World {
  void registerUsedElement(MemberEntity element);
  void registerTypedef(TypedefEntity typedef);

  ClosedWorld closeWorld();

  /// Returns an iterable over all mixin applications that mixin [cls].
  Iterable<ClassEntity> allMixinUsesOf(ClassEntity cls);
}

/// Enum values defining subset of classes included in queries.
enum ClassQuery {
  /// Only the class itself is included.
  EXACT,

  /// The class and all subclasses (transitively) are included.
  SUBCLASS,

  /// The class and all classes that implement or subclass it (transitively)
  /// are included.
  SUBTYPE,
}

abstract class ClosedWorldBase implements ClosedWorld, ClosedWorldRefiner {
  final ConstantSystem constantSystem;
  final NativeData nativeData;
  final InterceptorData interceptorData;
  final BackendUsage backendUsage;

  FunctionSet _allFunctions;

  final Set<TypedefEntity> _allTypedefs;

  final Map<ClassEntity, Set<ClassEntity>> mixinUses;
  Map<ClassEntity, List<ClassEntity>> _liveMixinUses;

  final Map<ClassEntity, Set<ClassEntity>> typesImplementedBySubclasses;

  // We keep track of subtype and subclass relationships in four
  // distinct sets to make class hierarchy analysis faster.
  final Map<ClassEntity, ClassHierarchyNode> _classHierarchyNodes;
  final Map<ClassEntity, ClassSet> _classSets;

  final Map<ClassEntity, Map<ClassEntity, bool>> _subtypeCoveredByCache =
      <ClassEntity, Map<ClassEntity, bool>>{};

  final Set<MemberEntity> _functionsCalledInLoop = new Set<MemberEntity>();
  final Map<FunctionEntity, SideEffects> _sideEffects =
      new Map<FunctionEntity, SideEffects>();

  final Set<FunctionEntity> _sideEffectsFreeElements =
      new Set<FunctionEntity>();

  final Set<FunctionEntity> _elementsThatCannotThrow =
      new Set<FunctionEntity>();

  final Set<FunctionEntity> _functionsThatMightBePassedToApply =
      new Set<FunctionEntity>();

  CommonMasks _commonMasks;

  final ElementEnvironment elementEnvironment;
  final DartTypes dartTypes;
  final CommonElements commonElements;

  // TODO(johnniwinther): Can this be derived from [ClassSet]s?
  final Set<ClassEntity> _implementedClasses;

  final Iterable<MemberEntity> liveInstanceMembers;

  /// Members that are written either directly or through a setter selector.
  final Iterable<MemberEntity> assignedInstanceMembers;

  final Iterable<ClassEntity> liveNativeClasses;

  final Iterable<MemberEntity> processedMembers;

  ClosedWorldBase(
      this.elementEnvironment,
      this.dartTypes,
      this.commonElements,
      this.constantSystem,
      this.nativeData,
      this.interceptorData,
      this.backendUsage,
      Set<ClassEntity> implementedClasses,
      this.liveNativeClasses,
      this.liveInstanceMembers,
      this.assignedInstanceMembers,
      this.processedMembers,
      Set<TypedefEntity> allTypedefs,
      this.mixinUses,
      this.typesImplementedBySubclasses,
      Map<ClassEntity, ClassHierarchyNode> classHierarchyNodes,
      Map<ClassEntity, ClassSet> classSets)
      : this._implementedClasses = implementedClasses,
        this._allTypedefs = allTypedefs,
        this._classHierarchyNodes = classHierarchyNodes,
        this._classSets = classSets {
    _commonMasks = new CommonMasks(this);
  }

  @override
  ClosedWorld get closedWorld => this;

  /// Cache of [FlatTypeMask]s grouped by the 8 possible values of the
  /// `FlatTypeMask.flags` property.
  final List<Map<ClassEntity, TypeMask>> _canonicalizedTypeMasks =
      new List<Map<ClassEntity, TypeMask>>.filled(8, null);

  CommonMasks get commonMasks {
    return _commonMasks;
  }

  TypeMask getCachedMask(ClassEntity base, int flags, TypeMask createMask()) {
    Map<ClassEntity, TypeMask> cachedMasks =
        _canonicalizedTypeMasks[flags] ??= <ClassEntity, TypeMask>{};
    return cachedMasks.putIfAbsent(base, createMask);
  }

  bool checkEntity(covariant Entity element);

  bool checkClass(covariant ClassEntity cls);

  bool checkInvariants(covariant ClassEntity cls,
      {bool mustBeInstantiated: true});

  OrderedTypeSet getOrderedTypeSet(covariant ClassEntity cls);

  int getHierarchyDepth(covariant ClassEntity cls);

  ClassEntity getSuperClass(covariant ClassEntity cls);

  Iterable<ClassEntity> getInterfaces(covariant ClassEntity cls);

  ClassEntity getAppliedMixin(covariant ClassEntity cls);

  bool isNamedMixinApplication(covariant ClassEntity cls);

  @override
  bool isInstantiated(ClassEntity cls) {
    assert(checkClass(cls));
    ClassHierarchyNode node = _classHierarchyNodes[cls];
    return node != null && node.isInstantiated;
  }

  @override
  bool isDirectlyInstantiated(ClassEntity cls) {
    assert(checkClass(cls));
    ClassHierarchyNode node = _classHierarchyNodes[cls];
    return node != null && node.isDirectlyInstantiated;
  }

  @override
  bool isAbstractlyInstantiated(ClassEntity cls) {
    assert(checkClass(cls));
    ClassHierarchyNode node = _classHierarchyNodes[cls];
    return node != null && node.isAbstractlyInstantiated;
  }

  @override
  bool isExplicitlyInstantiated(ClassEntity cls) {
    assert(checkClass(cls));
    ClassHierarchyNode node = _classHierarchyNodes[cls];
    return node != null && node.isExplicitlyInstantiated;
  }

  @override
  bool isIndirectlyInstantiated(ClassEntity cls) {
    assert(checkClass(cls));
    ClassHierarchyNode node = _classHierarchyNodes[cls];
    return node != null && node.isIndirectlyInstantiated;
  }

  @override
  bool isAbstract(ClassEntity cls) => cls.isAbstract;

  /// Returns `true` if [cls] is implemented by an instantiated class.
  bool isImplemented(ClassEntity cls) {
    return _implementedClasses.contains(cls);
  }

  /// Returns `true` if [x] is a subtype of [y], that is, if [x] implements an
  /// instance of [y].
  bool isSubtypeOf(ClassEntity x, ClassEntity y) {
    assert(checkInvariants(x));
    assert(checkInvariants(y, mustBeInstantiated: false));
    ClassSet classSet = _classSets[y];
    assert(
        classSet != null,
        failedAt(
            y,
            "No ClassSet for $y (${y.runtimeType}): "
            "${dump(y)} : ${_classSets}"));
    ClassHierarchyNode classHierarchyNode = _classHierarchyNodes[x];
    assert(classHierarchyNode != null,
        failedAt(x, "No ClassHierarchyNode for $x: ${dump(x)}"));
    return classSet.hasSubtype(classHierarchyNode);
  }

  /// Return `true` if [x] is a (non-strict) subclass of [y].
  bool isSubclassOf(ClassEntity x, ClassEntity y) {
    assert(checkInvariants(x));
    assert(checkInvariants(y));
    return _classHierarchyNodes[y].hasSubclass(_classHierarchyNodes[x]);
  }

  /// Returns an iterable over the directly instantiated classes that extend
  /// [cls] possibly including [cls] itself, if it is live.
  Iterable<ClassEntity> subclassesOf(ClassEntity cls) {
    assert(checkClass(cls));
    ClassHierarchyNode hierarchy = _classHierarchyNodes[cls];
    if (hierarchy == null) return const <ClassEntity>[];
    return hierarchy
        .subclassesByMask(ClassHierarchyNode.EXPLICITLY_INSTANTIATED);
  }

  /// Returns an iterable over the directly instantiated classes that extend
  /// [cls] _not_ including [cls] itself.
  Iterable<ClassEntity> strictSubclassesOf(ClassEntity cls) {
    assert(checkClass(cls));
    ClassHierarchyNode subclasses = _classHierarchyNodes[cls];
    if (subclasses == null) return const <ClassEntity>[];
    return subclasses.subclassesByMask(
        ClassHierarchyNode.EXPLICITLY_INSTANTIATED,
        strict: true);
  }

  /// Returns the number of live classes that extend [cls] _not_
  /// including [cls] itself.
  int strictSubclassCount(ClassEntity cls) {
    assert(checkClass(cls));
    ClassHierarchyNode subclasses = _classHierarchyNodes[cls];
    if (subclasses == null) return 0;
    return subclasses.instantiatedSubclassCount;
  }

  /// Applies [f] to each live class that extend [cls] _not_ including [cls]
  /// itself.
  void forEachStrictSubclassOf(
      ClassEntity cls, IterationStep f(ClassEntity cls)) {
    assert(checkClass(cls));
    ClassHierarchyNode subclasses = _classHierarchyNodes[cls];
    if (subclasses == null) return;
    subclasses.forEachSubclass(f, ClassHierarchyNode.EXPLICITLY_INSTANTIATED,
        strict: true);
  }

  /// Returns `true` if [predicate] applies to any live class that extend [cls]
  /// _not_ including [cls] itself.
  bool anyStrictSubclassOf(ClassEntity cls, bool predicate(ClassEntity cls)) {
    assert(checkClass(cls));
    ClassHierarchyNode subclasses = _classHierarchyNodes[cls];
    if (subclasses == null) return false;
    return subclasses.anySubclass(
        predicate, ClassHierarchyNode.EXPLICITLY_INSTANTIATED,
        strict: true);
  }

  /// Returns an iterable over the directly instantiated that implement [cls]
  /// possibly including [cls] itself, if it is live.
  Iterable<ClassEntity> subtypesOf(ClassEntity cls) {
    assert(checkClass(cls));
    ClassSet classSet = _classSets[cls];
    if (classSet == null) {
      return const <ClassEntity>[];
    } else {
      return classSet
          .subtypesByMask(ClassHierarchyNode.EXPLICITLY_INSTANTIATED);
    }
  }

  /// Returns an iterable over the directly instantiated that implement [cls]
  /// _not_ including [cls].
  Iterable<ClassEntity> strictSubtypesOf(ClassEntity cls) {
    assert(checkClass(cls));
    ClassSet classSet = _classSets[cls];
    if (classSet == null) {
      return const <ClassEntity>[];
    } else {
      return classSet.subtypesByMask(ClassHierarchyNode.EXPLICITLY_INSTANTIATED,
          strict: true);
    }
  }

  /// Returns the number of live classes that implement [cls] _not_
  /// including [cls] itself.
  int strictSubtypeCount(ClassEntity cls) {
    assert(checkClass(cls));
    ClassSet classSet = _classSets[cls];
    if (classSet == null) return 0;
    return classSet.instantiatedSubtypeCount;
  }

  /// Applies [f] to each live class that implements [cls] _not_ including [cls]
  /// itself.
  void forEachStrictSubtypeOf(
      ClassEntity cls, IterationStep f(ClassEntity cls)) {
    assert(checkClass(cls));
    ClassSet classSet = _classSets[cls];
    if (classSet == null) return;
    classSet.forEachSubtype(f, ClassHierarchyNode.EXPLICITLY_INSTANTIATED,
        strict: true);
  }

  /// Returns `true` if [predicate] applies to any live class that extend [cls]
  /// _not_ including [cls] itself.
  bool anyStrictSubtypeOf(ClassEntity cls, bool predicate(ClassEntity cls)) {
    assert(checkClass(cls));
    ClassSet classSet = _classSets[cls];
    if (classSet == null) return false;
    return classSet.anySubtype(
        predicate, ClassHierarchyNode.EXPLICITLY_INSTANTIATED,
        strict: true);
  }

  /// Returns `true` if [a] and [b] have any known common subtypes.
  bool haveAnyCommonSubtypes(ClassEntity a, ClassEntity b) {
    assert(checkClass(a));
    assert(checkClass(b));
    ClassSet classSetA = _classSets[a];
    ClassSet classSetB = _classSets[b];
    if (classSetA == null || classSetB == null) return false;
    // TODO(johnniwinther): Implement an optimized query on [ClassSet].
    Set<ClassEntity> subtypesOfB = classSetB.subtypes().toSet();
    for (ClassEntity subtypeOfA in classSetA.subtypes()) {
      if (subtypesOfB.contains(subtypeOfA)) {
        return true;
      }
    }
    return false;
  }

  /// Returns `true` if any directly instantiated class other than [cls] extends
  /// [cls].
  bool hasAnyStrictSubclass(ClassEntity cls) {
    assert(checkClass(cls));
    ClassHierarchyNode subclasses = _classHierarchyNodes[cls];
    if (subclasses == null) return false;
    return subclasses.isIndirectlyInstantiated;
  }

  /// Returns `true` if any directly instantiated class other than [cls]
  /// implements [cls].
  bool hasAnyStrictSubtype(ClassEntity cls) {
    return strictSubtypeCount(cls) > 0;
  }

  /// Returns `true` if all directly instantiated classes that implement [cls]
  /// extend it.
  bool hasOnlySubclasses(ClassEntity cls) {
    assert(checkClass(cls));
    // TODO(johnniwinther): move this to ClassSet?
    if (cls == commonElements.objectClass) return true;
    ClassSet classSet = _classSets[cls];
    if (classSet == null) {
      // Vacuously true.
      return true;
    }
    return classSet.hasOnlyInstantiatedSubclasses;
  }

  @override
  ClassEntity getLubOfInstantiatedSubclasses(ClassEntity cls) {
    assert(checkClass(cls));
    if (nativeData.isJsInteropClass(cls)) {
      return commonElements.jsJavaScriptObjectClass;
    }
    ClassHierarchyNode hierarchy = _classHierarchyNodes[cls];
    return hierarchy != null
        ? hierarchy.getLubOfInstantiatedSubclasses()
        : null;
  }

  @override
  ClassEntity getLubOfInstantiatedSubtypes(ClassEntity cls) {
    assert(checkClass(cls));
    if (nativeData.isJsInteropClass(cls)) {
      return commonElements.jsJavaScriptObjectClass;
    }
    ClassSet classSet = _classSets[cls];
    return classSet != null ? classSet.getLubOfInstantiatedSubtypes() : null;
  }

  Set<ClassEntity> _commonContainedClasses(ClassEntity cls1, ClassQuery query1,
      ClassEntity cls2, ClassQuery query2) {
    Iterable<ClassEntity> xSubset = _containedSubset(cls1, query1);
    if (xSubset == null) return null;
    Iterable<ClassEntity> ySubset = _containedSubset(cls2, query2);
    if (ySubset == null) return null;
    return xSubset.toSet().intersection(ySubset.toSet());
  }

  Iterable<ClassEntity> _containedSubset(ClassEntity cls, ClassQuery query) {
    switch (query) {
      case ClassQuery.EXACT:
        return null;
      case ClassQuery.SUBCLASS:
        return strictSubclassesOf(cls);
      case ClassQuery.SUBTYPE:
        return strictSubtypesOf(cls);
    }
    throw new ArgumentError('Unexpected query: $query.');
  }

  /// Returns `true` if [cls] is mixed into a live class.
  bool isUsedAsMixin(ClassEntity cls) {
    return !mixinUsesOf(cls).isEmpty;
  }

  /// Returns `true` if any live class that mixes in [cls] implements [type].
  bool hasAnySubclassOfMixinUseThatImplements(
      ClassEntity cls, ClassEntity type) {
    return mixinUsesOf(cls)
        .any((use) => hasAnySubclassThatImplements(use, type));
  }

  /// Returns `true` if every subtype of [x] is a subclass of [y] or a subclass
  /// of a mixin application of [y].
  bool everySubtypeIsSubclassOfOrMixinUseOf(ClassEntity x, ClassEntity y) {
    assert(checkClass(x));
    assert(checkClass(y));
    Map<ClassEntity, bool> secondMap =
        _subtypeCoveredByCache[x] ??= <ClassEntity, bool>{};
    return secondMap[y] ??= subtypesOf(x).every((ClassEntity cls) =>
        isSubclassOf(cls, y) || isSubclassOfMixinUseOf(cls, y));
  }

  /// Returns `true` if any subclass of [superclass] implements [type].
  bool hasAnySubclassThatImplements(ClassEntity superclass, ClassEntity type) {
    assert(checkClass(superclass));
    Set<ClassEntity> subclasses = typesImplementedBySubclasses[superclass];
    if (subclasses == null) return false;
    return subclasses.contains(type);
  }

  /// Returns whether a [selector] call on an instance of [cls]
  /// will hit a method at runtime, and not go through [noSuchMethod].
  bool hasConcreteMatch(covariant ClassEntity cls, Selector selector,
      {covariant ClassEntity stopAtSuperclass});

  @override
  bool needsNoSuchMethod(
      ClassEntity base, Selector selector, ClassQuery query) {
    /// Returns `true` if subclasses in the [rootNode] tree needs noSuchMethod
    /// handling.
    bool subclassesNeedNoSuchMethod(ClassHierarchyNode rootNode) {
      if (!rootNode.isInstantiated) {
        // No subclass needs noSuchMethod handling since they are all
        // uninstantiated.
        return false;
      }
      ClassEntity rootClass = rootNode.cls;
      if (hasConcreteMatch(rootClass, selector)) {
        // The root subclass has a concrete implementation so no subclass needs
        // noSuchMethod handling.
        return false;
      } else if (rootNode.isExplicitlyInstantiated) {
        // The root class need noSuchMethod handling.
        return true;
      }
      IterationStep result = rootNode.forEachSubclass((ClassEntity subclass) {
        if (hasConcreteMatch(subclass, selector, stopAtSuperclass: rootClass)) {
          // Found a match - skip all subclasses.
          return IterationStep.SKIP_SUBCLASSES;
        } else {
          // Stop fast - we found a need for noSuchMethod handling.
          return IterationStep.STOP;
        }
      }, ClassHierarchyNode.EXPLICITLY_INSTANTIATED, strict: true);
      // We stopped fast so we need noSuchMethod handling.
      return result == IterationStep.STOP;
    }

    ClassSet classSet = getClassSet(base);
    ClassHierarchyNode node = classSet.node;
    if (query == ClassQuery.EXACT) {
      return node.isExplicitlyInstantiated && !hasConcreteMatch(base, selector);
    } else if (query == ClassQuery.SUBCLASS) {
      return subclassesNeedNoSuchMethod(node);
    } else {
      if (subclassesNeedNoSuchMethod(node)) return true;
      for (ClassHierarchyNode subtypeNode in classSet.subtypeNodes) {
        if (subclassesNeedNoSuchMethod(subtypeNode)) return true;
      }
      return false;
    }
  }

  /// Returns an iterable over the common supertypes of the [classes].
  Iterable<ClassEntity> commonSupertypesOf(Iterable<ClassEntity> classes) {
    Iterator<ClassEntity> iterator = classes.iterator;
    if (!iterator.moveNext()) return const <ClassEntity>[];

    ClassEntity cls = iterator.current;
    assert(checkInvariants(cls));
    OrderedTypeSet typeSet = getOrderedTypeSet(cls);
    if (!iterator.moveNext()) return typeSet.types.map((type) => type.element);

    int depth = typeSet.maxDepth;
    Link<OrderedTypeSet> otherTypeSets = const Link<OrderedTypeSet>();
    do {
      ClassEntity otherClass = iterator.current;
      assert(checkInvariants(otherClass));
      OrderedTypeSet otherTypeSet = getOrderedTypeSet(otherClass);
      otherTypeSets = otherTypeSets.prepend(otherTypeSet);
      if (otherTypeSet.maxDepth < depth) {
        depth = otherTypeSet.maxDepth;
      }
    } while (iterator.moveNext());

    List<ClassEntity> commonSupertypes = <ClassEntity>[];
    OUTER:
    for (Link<InterfaceType> link = typeSet[depth];
        link.head.element != commonElements.objectClass;
        link = link.tail) {
      ClassEntity cls = link.head.element;
      for (Link<OrderedTypeSet> link = otherTypeSets;
          !link.isEmpty;
          link = link.tail) {
        if (link.head.asInstanceOf(cls, getHierarchyDepth(cls)) == null) {
          continue OUTER;
        }
      }
      commonSupertypes.add(cls);
    }
    commonSupertypes.add(commonElements.objectClass);
    return commonSupertypes;
  }

  Iterable<ClassEntity> commonSubclasses(ClassEntity cls1, ClassQuery query1,
      ClassEntity cls2, ClassQuery query2) {
    // TODO(johnniwinther): Use [ClassSet] to compute this.
    // Compute the set of classes that are contained in both class subsets.
    Set<ClassEntity> common =
        _commonContainedClasses(cls1, query1, cls2, query2);
    if (common == null || common.isEmpty) return const <ClassEntity>[];
    // Narrow down the candidates by only looking at common classes
    // that do not have a superclass or supertype that will be a
    // better candidate.
    return common.where((ClassEntity each) {
      bool containsSuperclass = common.contains(getSuperClass(each));
      // If the superclass is also a candidate, then we don't want to
      // deal with this class. If we're only looking for a subclass we
      // know we don't have to look at the list of interfaces because
      // they can never be in the common set.
      if (containsSuperclass ||
          query1 == ClassQuery.SUBCLASS ||
          query2 == ClassQuery.SUBCLASS) {
        return !containsSuperclass;
      }
      // Run through the direct supertypes of the class. If the common
      // set contains the direct supertype of the class, we ignore the
      // the class because the supertype is a better candidate.

      for (ClassEntity interface in getInterfaces(each)) {
        if (common.contains(interface)) return false;
      }
      return true;
    });
  }

  /// Returns an iterable over the live mixin applications that mixin [cls].
  Iterable<ClassEntity> mixinUsesOf(ClassEntity cls) {
    if (_liveMixinUses == null) {
      _liveMixinUses = new Map<ClassEntity, List<ClassEntity>>();
      for (ClassEntity mixin in mixinUses.keys) {
        List<ClassEntity> uses = <ClassEntity>[];

        void addLiveUse(ClassEntity mixinApplication) {
          if (isInstantiated(mixinApplication)) {
            uses.add(mixinApplication);
          } else if (isNamedMixinApplication(mixinApplication)) {
            Set<ClassEntity> next = mixinUses[mixinApplication];
            if (next != null) {
              next.forEach(addLiveUse);
            }
          }
        }

        mixinUses[mixin].forEach(addLiveUse);
        if (uses.isNotEmpty) {
          _liveMixinUses[mixin] = uses;
        }
      }
    }
    Iterable<ClassEntity> uses = _liveMixinUses[cls];
    return uses != null ? uses : const <ClassEntity>[];
  }

  /// Returns `true` if any live class that mixes in [mixin] is also a subclass
  /// of [superclass].
  bool hasAnySubclassThatMixes(ClassEntity superclass, ClassEntity mixin) {
    return mixinUsesOf(mixin).any((ClassEntity each) {
      return isSubclassOf(each, superclass);
    });
  }

  /// Returns `true` if [cls] or any superclass mixes in [mixin].
  bool isSubclassOfMixinUseOf(ClassEntity cls, ClassEntity mixin) {
    assert(checkClass(cls));
    assert(checkClass(mixin));
    if (isUsedAsMixin(mixin)) {
      ClassEntity current = cls;
      while (current != null) {
        ClassEntity currentMixin = getAppliedMixin(current);
        if (currentMixin == mixin) return true;
        current = getSuperClass(current);
      }
    }
    return false;
  }

  /// Returns [ClassHierarchyNode] for [cls] used to model the class hierarchies
  /// of known classes.
  ///
  /// This method is only provided for testing. For queries on classes, use the
  /// methods defined in [ClosedWorld].
  ClassHierarchyNode getClassHierarchyNode(ClassEntity cls) {
    assert(checkClass(cls));
    return _classHierarchyNodes[cls];
  }

  /// Returns [ClassSet] for [cls] used to model the extends and implements
  /// relations of known classes.
  ///
  /// This method is only provided for testing. For queries on classes, use the
  /// methods defined in [ClosedWorld].
  ClassSet getClassSet(ClassEntity cls) {
    assert(checkClass(cls));
    return _classSets[cls];
  }

  Iterable<TypedefEntity> get allTypedefs => _allTypedefs;

  void _ensureFunctionSet() {
    if (_allFunctions == null) {
      // [FunctionSet] is created lazily because it is not used when we switch
      // from a frontend to a backend model before inference.
      _allFunctions = new FunctionSet(liveInstanceMembers);
    }
  }

  TypeMask computeReceiverType(Selector selector, TypeMask mask) {
    _ensureFunctionSet();
    return _allFunctions.receiverType(selector, mask, this);
  }

  Iterable<MemberEntity> locateMembers(Selector selector, TypeMask mask) {
    _ensureFunctionSet();
    return _allFunctions.filter(selector, mask, this);
  }

  bool hasAnyUserDefinedGetter(Selector selector, TypeMask mask) {
    _ensureFunctionSet();
    return _allFunctions
        .filter(selector, mask, this)
        .any((each) => each.isGetter);
  }

  FieldEntity locateSingleField(Selector selector, TypeMask mask) {
    MemberEntity result = locateSingleElement(selector, mask);
    return (result != null && result.isField) ? result : null;
  }

  MemberEntity locateSingleElement(Selector selector, TypeMask mask) {
    mask ??= commonMasks.dynamicType;
    return mask.locateSingleElement(selector, this);
  }

  TypeMask extendMaskIfReachesAll(Selector selector, TypeMask mask) {
    bool canReachAll = true;
    if (mask != null) {
      canReachAll = backendUsage.isInvokeOnUsed &&
          mask.needsNoSuchMethodHandling(selector, this);
    }
    return canReachAll ? commonMasks.dynamicType : mask;
  }

  bool fieldNeverChanges(MemberEntity element) {
    if (!element.isField) return false;
    if (nativeData.isNativeMember(element)) {
      // Some native fields are views of data that may be changed by operations.
      // E.g. node.firstChild depends on parentNode.removeBefore(n1, n2).
      // TODO(sra): Refine the effect classification so that native effects are
      // distinct from ordinary Dart effects.
      return false;
    }

    if (!element.isAssignable) {
      return true;
    }
    if (element.isInstanceMember) {
      return !assignedInstanceMembers.contains(element);
    }
    return false;
  }

  SideEffects getSideEffectsOfSelector(Selector selector, TypeMask mask) {
    // We're not tracking side effects of closures.
    if (selector.isClosureCall) return new SideEffects();
    SideEffects sideEffects = new SideEffects.empty();
    _ensureFunctionSet();
    for (MemberEntity e in _allFunctions.filter(selector, mask, this)) {
      if (e.isField) {
        if (selector.isGetter) {
          if (!fieldNeverChanges(e)) {
            sideEffects.setDependsOnInstancePropertyStore();
          }
        } else if (selector.isSetter) {
          sideEffects.setChangesInstanceProperty();
        } else {
          assert(selector.isCall);
          sideEffects.setAllSideEffects();
          sideEffects.setDependsOnSomething();
        }
      } else {
        sideEffects.add(getSideEffectsOfElement(e));
      }
    }
    return sideEffects;
  }

  SideEffects getSideEffectsOfElement(FunctionEntity element) {
    assert(checkEntity(element));
    return _sideEffects.putIfAbsent(element, _makeSideEffects);
  }

  static SideEffects _makeSideEffects() => new SideEffects();

  @override
  SideEffects getCurrentlyKnownSideEffects(FunctionEntity element) {
    return getSideEffectsOfElement(element);
  }

  void registerSideEffects(FunctionEntity element, SideEffects effects) {
    assert(checkEntity(element));
    if (_sideEffectsFreeElements.contains(element)) return;
    _sideEffects[element] = effects;
  }

  void registerSideEffectsFree(FunctionEntity element) {
    assert(checkEntity(element));
    _sideEffects[element] = new SideEffects.empty();
    _sideEffectsFreeElements.add(element);
  }

  void addFunctionCalledInLoop(MemberEntity element) {
    assert(checkEntity(element));
    _functionsCalledInLoop.add(element);
  }

  bool isCalledInLoop(MemberEntity element) {
    assert(checkEntity(element));
    return _functionsCalledInLoop.contains(element);
  }

  void registerCannotThrow(FunctionEntity element) {
    assert(checkEntity(element));
    _elementsThatCannotThrow.add(element);
  }

  bool getCannotThrow(FunctionEntity element) {
    return _elementsThatCannotThrow.contains(element);
  }

  void registerMightBePassedToApply(FunctionEntity element) {
    _functionsThatMightBePassedToApply.add(element);
  }

  bool getMightBePassedToApply(FunctionEntity element) {
    // We assume all functions reach Function.apply if no functions are
    // registered so.  We get an empty set in two circumstances (1) a trivial
    // program and (2) when compiling without type inference
    // (i.e. --disable-type-inference). Returning `true` has consequences (extra
    // metadata for Function.apply) only when Function.apply is also part of the
    // program. It is an unusual trivial program that includes Function.apply
    // but does not call it on a function.
    //
    // TODO(sra): We should reverse the sense of this set and register functions
    // that we have proven do not reach Function.apply.
    if (_functionsThatMightBePassedToApply.isEmpty) return true;
    return _functionsThatMightBePassedToApply.contains(element);
  }

  @override
  bool getCurrentlyKnownMightBePassedToApply(FunctionEntity element) {
    return _functionsThatMightBePassedToApply.contains(element);
  }

  @override
  String dump([ClassEntity cls]) {
    if (cls is! ClassElement) {
      // TODO(johnniwinther): Support [cls] as a [ClassEntity].
      cls = null;
    }
    StringBuffer sb = new StringBuffer();
    if (cls != null) {
      sb.write("Classes in the closed world related to $cls:\n");
    } else {
      sb.write("Instantiated classes in the closed world:\n");
    }
    getClassHierarchyNode(commonElements.objectClass)
        .printOn(sb, ' ', instantiatedOnly: cls == null, withRespectTo: cls);
    return sb.toString();
  }

  /// Should only be called by subclasses.
  void addClassHierarchyNode(ClassEntity cls, ClassHierarchyNode node) {
    _classHierarchyNodes[cls] = node;
  }

  /// Should only be called by subclasses.
  void addClassSet(ClassEntity cls, ClassSet classSet) {
    _classSets[cls] = classSet;
  }
}

class ClosedWorldImpl extends ClosedWorldBase with ClosedWorldRtiNeedMixin {
  ClosedWorldImpl(
      {CompilerOptions options,
      ElementEnvironment elementEnvironment,
      DartTypes dartTypes,
      CommonElements commonElements,
      ConstantSystem constantSystem,
      NativeData nativeData,
      InterceptorData interceptorData,
      BackendUsage backendUsage,
      ResolutionWorldBuilder resolutionWorldBuilder,
      RuntimeTypesNeedBuilder rtiNeedBuilder,
      Set<ClassEntity> implementedClasses,
      Iterable<ClassEntity> liveNativeClasses,
      Iterable<MemberEntity> liveInstanceMembers,
      Iterable<MemberEntity> assignedInstanceMembers,
      Iterable<MemberEntity> processedMembers,
      Set<TypedefEntity> allTypedefs,
      Map<ClassEntity, Set<ClassEntity>> mixinUses,
      Map<ClassEntity, Set<ClassEntity>> typesImplementedBySubclasses,
      Map<ClassEntity, ClassHierarchyNode> classHierarchyNodes,
      Map<ClassEntity, ClassSet> classSets})
      : super(
            elementEnvironment,
            dartTypes,
            commonElements,
            constantSystem,
            nativeData,
            interceptorData,
            backendUsage,
            implementedClasses,
            liveNativeClasses,
            liveInstanceMembers,
            assignedInstanceMembers,
            processedMembers,
            allTypedefs,
            mixinUses,
            typesImplementedBySubclasses,
            classHierarchyNodes,
            classSets) {
    computeRtiNeed(resolutionWorldBuilder, rtiNeedBuilder,
        enableTypeAssertions: options.enableTypeAssertions);
  }

  bool checkClass(ClassElement cls) => cls.isDeclaration;

  bool checkEntity(Element element) => element.isDeclaration;

  bool checkInvariants(ClassElement cls, {bool mustBeInstantiated: true}) {
    assert(cls.isDeclaration, failedAt(cls, '$cls must be the declaration.'));
    assert(cls.isResolved, failedAt(cls, '$cls must be resolved.'));

    // TODO(johnniwinther): Reinsert this or similar invariant. Currently
    // various call sites use uninstantiated classes for isSubtypeOf or
    // isSubclassOf. Some are valid, some are not. Work out better invariants
    // to catch the latter.
    // if (mustBeInstantiated) {
    //  assert(isInstantiated(cls), failedAt(cls, '$cls is not instantiated.'));
    // }
    return true;
  }

  OrderedTypeSet getOrderedTypeSet(ClassElement cls) =>
      cls.allSupertypesAndSelf;

  int getHierarchyDepth(ClassElement cls) => cls.hierarchyDepth;

  ClassEntity getSuperClass(ClassElement cls) => cls.superclass;

  Iterable<ClassEntity> getInterfaces(ClassElement cls) sync* {
    for (Link link = cls.interfaces; !link.isEmpty; link = link.tail) {
      yield link.head.element;
    }
  }

  bool isNamedMixinApplication(ClassElement cls) => cls.isNamedMixinApplication;

  ClassEntity getAppliedMixin(ClassElement cls) {
    if (cls.isMixinApplication) {
      MixinApplicationElement application = cls;
      return application.mixin;
    }
    return null;
  }

  @override
  bool hasElementIn(ClassEntity cls, Selector selector, Element element) {
    // Use [:implementation:] of [element]
    // because our function set only stores declarations.
    Element result = findMatchIn(cls, selector);
    return result == null
        ? false
        : result.implementation == element.implementation;
  }

  MemberElement findMatchIn(ClassElement cls, Selector selector,
      {ClassElement stopAtSuperclass}) {
    // Use the [:implementation] of [cls] in case the found [element]
    // is in the patch class.
    return cls.implementation
        .lookupByName(selector.memberName, stopAt: stopAtSuperclass);
  }

  /// Returns whether a [selector] call on an instance of [cls]
  /// will hit a method at runtime, and not go through [noSuchMethod].
  bool hasConcreteMatch(ClassElement cls, Selector selector,
      {ClassElement stopAtSuperclass}) {
    assert(
        isInstantiated(cls), failedAt(cls, '$cls has not been instantiated.'));
    MemberElement element = findMatchIn(cls, selector);
    if (element == null) return false;

    if (element.isAbstract) {
      ClassElement enclosingClass = element.enclosingClass;
      return hasConcreteMatch(enclosingClass.superclass, selector);
    }
    return selector.appliesUntyped(element);
  }

  void registerClosureClass(covariant ClassElement cls) {
    ClassHierarchyNode parentNode = getClassHierarchyNode(cls.superclass);
    ClassHierarchyNode node = _classHierarchyNodes[cls] =
        new ClassHierarchyNode(parentNode, cls, cls.hierarchyDepth);
    for (ResolutionInterfaceType type in cls.allSupertypes) {
      ClassSet subtypeSet = getClassSet(type.element);
      subtypeSet.addSubtype(node);
    }
    _classSets[cls] = new ClassSet(node);
    _updateSuperClassHierarchyNodeForClass(node);
    node.isDirectlyInstantiated = true;
  }

  void _updateSuperClassHierarchyNodeForClass(ClassHierarchyNode node) {
    // Ensure that classes implicitly implementing `Function` are in its
    // subtype set.
    ClassElement cls = node.cls;
    if (cls != commonElements.functionClass &&
        cls.implementsFunction(commonElements)) {
      ClassSet subtypeSet = getClassSet(commonElements.functionClass);
      subtypeSet.addSubtype(node);
    }
    if (!node.isInstantiated && node.parentNode != null) {
      _updateSuperClassHierarchyNodeForClass(node.parentNode);
    }
  }

  SideEffects getSideEffectsOfElement(covariant MethodElement element) {
    // The type inferrer (where the side effects are being computed),
    // does not see generative constructor bodies because they are
    // created by the backend. Also, it does not make any distinction
    // between a constructor and its body for side effects. This
    // implies that currently, the side effects of a constructor body
    // contain the side effects of the initializers.
    assert(!element.isGenerativeConstructorBody);
    assert(!element.isField);
    return super.getSideEffectsOfElement(element);
  }
}

abstract class ClosedWorldRtiNeedMixin implements ClosedWorld {
  RuntimeTypesNeed _rtiNeed;

  void computeRtiNeed(ResolutionWorldBuilder resolutionWorldBuilder,
      RuntimeTypesNeedBuilder rtiNeedBuilder,
      {bool enableTypeAssertions}) {
    _rtiNeed = rtiNeedBuilder.computeRuntimeTypesNeed(
        resolutionWorldBuilder, this,
        enableTypeAssertions: enableTypeAssertions);
  }

  RuntimeTypesNeed get rtiNeed => _rtiNeed;
}
