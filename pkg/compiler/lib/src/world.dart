// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.world;

import 'closure.dart' show ClosureClassElement, SynthesizedCallMethodElementX;
import 'common/backend_api.dart' show BackendClasses;
import 'common.dart';
import 'constants/constant_system.dart';
import 'core_types.dart' show CommonElements;
import 'elements/entities.dart';
import 'elements/elements.dart'
    show
        ClassElement,
        Element,
        Entity,
        FunctionElement,
        MemberElement,
        MixinApplicationElement,
        TypedefElement,
        FieldElement;
import 'elements/resolution_types.dart';
import 'js_backend/backend.dart' show JavaScriptBackend;
import 'ordered_typeset.dart';
import 'types/masks.dart' show CommonMasks, FlatTypeMask, TypeMask;
import 'universe/class_set.dart';
import 'universe/function_set.dart' show FunctionSet, FunctionSetBuilder;
import 'universe/selector.dart' show Selector;
import 'universe/side_effects.dart' show SideEffects;
import 'universe/world_builder.dart' show ResolutionWorldBuilder;
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
  /// Access to core classes used by the backend.
  BackendClasses get backendClasses;

  CommonElements get commonElements;

  CommonMasks get commonMasks;

  ConstantSystem get constantSystem;

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
  Iterable<ClassElement> subtypesOf(ClassEntity cls);

  /// Returns an iterable over the live classes that implement [cls] _not_
  /// including [cls] if it is live.
  Iterable<ClassElement> strictSubtypesOf(ClassEntity cls);

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
  Iterable<ClassEntity> commonSubclasses(ClassElement cls1, ClassQuery query1,
      ClassElement cls2, ClassQuery query2);

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
  bool hasElementIn(ClassEntity cls, Selector selector, Entity element);

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

  /// Returns the [FunctionSet] containing all live functions in the closed
  /// world.
  FunctionSet get allFunctions;

  /// Returns `true` if the field [element] is known to be effectively final.
  bool fieldNeverChanges(MemberEntity element);

  /// Extends the receiver type [mask] for calling [selector] to take live
  /// `noSuchMethod` handlers into account.
  TypeMask extendMaskIfReachesAll(Selector selector, TypeMask mask);

  /// Returns all resolved typedefs.
  Iterable<TypedefElement> get allTypedefs;

  /// Returns the single [Element] that matches a call to [selector] on a
  /// receiver of type [mask]. If multiple targets exist, `null` is returned.
  MemberEntity locateSingleElement(Selector selector, TypeMask mask);

  /// Returns the single field that matches a call to [selector] on a
  /// receiver of type [mask]. If multiple targets exist or the single target
  /// is not a field, `null` is returned.
  FieldEntity locateSingleField(Selector selector, TypeMask mask);

  /// Returns the side effects of executing [element].
  SideEffects getSideEffectsOfElement(Element element);

  /// Returns the side effects of calling [selector] on a receiver of type
  /// [mask].
  SideEffects getSideEffectsOfSelector(Selector selector, TypeMask mask);

  /// Returns `true` if [element] is guaranteed not to throw an exception.
  bool getCannotThrow(Element element);

  /// Returns `true` if [element] is called in a loop.
  // TODO(johnniwinther): Is this 'potentially called' or 'known to be called'?
  bool isCalledInLoop(Element element);

  /// Returns `true` if [element] might be passed to `Function.apply`.
  // TODO(johnniwinther): Is this 'passed invocation target` or
  // `passed as argument`?
  bool getMightBePassedToApply(Element element);

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
  void registerSideEffects(Element element, SideEffects effects);

  /// Registers the executing of [element] as without side effects.
  void registerSideEffectsFree(Element element);

  /// Returns the currently known side effects of executing [element].
  SideEffects getCurrentlyKnownSideEffects(Element element);

  /// Registers that [element] might be passed to `Function.apply`.
  // TODO(johnniwinther): Is this 'passed invocation target` or
  // `passed as argument`?
  void registerMightBePassedToApply(Element element);

  /// Returns `true` if [element] might be passed to `Function.apply` given the
  /// currently inferred information.
  bool getCurrentlyKnownMightBePassedToApply(Element element);

  /// Registers that [element] is called in a loop.
  // TODO(johnniwinther): Is this 'potentially called' or 'known to be called'?
  void addFunctionCalledInLoop(Element element);

  /// Registers that [element] is guaranteed not to throw an exception.
  void registerCannotThrow(Element element);

  /// Adds the closure class [cls] to the inference world. The class is
  /// considered directly instantiated.
  void registerClosureClass(ClassElement cls);
}

abstract class OpenWorld implements World {
  /// Called to add [cls] to the set of known classes.
  ///
  /// This ensures that class hierarchy queries can be performed on [cls] and
  /// classes that extend or implement it.
  void registerClass(ClassElement cls);

  void registerUsedElement(MemberElement element);
  void registerTypedef(TypedefElement typedef);

  ClosedWorld closeWorld(DiagnosticReporter reporter);

  /// Returns an iterable over all mixin applications that mixin [cls].
  Iterable<MixinApplicationElement> allMixinUsesOf(ClassElement cls);
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

class ClosedWorldImpl implements ClosedWorld, ClosedWorldRefiner {
  final JavaScriptBackend _backend;
  BackendClasses get backendClasses => _backend.backendClasses;
  FunctionSet _allFunctions;

  final Iterable<TypedefElement> _allTypedefs;

  final Map<ClassElement, Set<MixinApplicationElement>> _mixinUses;
  Map<ClassElement, List<MixinApplicationElement>> _liveMixinUses;

  final Map<ClassElement, Set<ClassElement>> _typesImplementedBySubclasses;

  // We keep track of subtype and subclass relationships in four
  // distinct sets to make class hierarchy analysis faster.
  final Map<ClassElement, ClassHierarchyNode> _classHierarchyNodes;
  final Map<ClassElement, ClassSet> _classSets;

  final Map<ClassElement, Map<ClassElement, bool>> _subtypeCoveredByCache =
      <ClassElement, Map<ClassElement, bool>>{};

  final Set<Element> functionsCalledInLoop = new Set<Element>();
  final Map<Element, SideEffects> sideEffects = new Map<Element, SideEffects>();

  final Set<Element> sideEffectsFreeElements = new Set<Element>();

  final Set<Element> elementsThatCannotThrow = new Set<Element>();

  final Set<Element> functionsThatMightBePassedToApply =
      new Set<FunctionElement>();

  CommonMasks _commonMasks;

  final CommonElements commonElements;

  final ResolutionWorldBuilder _resolverWorld;

  bool get isClosed => true;

  ClosedWorldImpl(
      {JavaScriptBackend backend,
      this.commonElements,
      ResolutionWorldBuilder resolutionWorldBuilder,
      FunctionSetBuilder functionSetBuilder,
      Iterable<TypedefElement> allTypedefs,
      Map<ClassElement, Set<MixinApplicationElement>> mixinUses,
      Map<ClassElement, Set<ClassElement>> typesImplementedBySubclasses,
      Map<ClassElement, ClassHierarchyNode> classHierarchyNodes,
      Map<ClassElement, ClassSet> classSets})
      : this._backend = backend,
        this._resolverWorld = resolutionWorldBuilder,
        this._allTypedefs = allTypedefs,
        this._mixinUses = mixinUses,
        this._typesImplementedBySubclasses = typesImplementedBySubclasses,
        this._classHierarchyNodes = classHierarchyNodes,
        this._classSets = classSets {
    _commonMasks = new CommonMasks(this);
    _allFunctions = functionSetBuilder.close(this);
  }

  @override
  ClosedWorld get closedWorld => this;

  /// Cache of [FlatTypeMask]s grouped by the 8 possible values of the
  /// `FlatTypeMask.flags` property.
  final List<Map<ClassElement, TypeMask>> _canonicalizedTypeMasks =
      new List<Map<ClassElement, TypeMask>>.filled(8, null);

  FunctionSet get allFunctions => _allFunctions;

  CommonMasks get commonMasks {
    assert(isClosed);
    return _commonMasks;
  }

  ConstantSystem get constantSystem => _backend.constantSystem;

  TypeMask getCachedMask(ClassElement base, int flags, TypeMask createMask()) {
    Map<ClassElement, TypeMask> cachedMasks =
        _canonicalizedTypeMasks[flags] ??= <ClassElement, TypeMask>{};
    return cachedMasks.putIfAbsent(base, createMask);
  }

  bool checkInvariants(ClassElement cls, {bool mustBeInstantiated: true}) {
    return invariant(cls, cls.isDeclaration,
                message: '$cls must be the declaration.') &&
            invariant(cls, cls.isResolved,
                message:
                    '$cls must be resolved.') /* &&
      // TODO(johnniwinther): Reinsert this or similar invariant.
      (!mustBeInstantiated ||
       invariant(cls, isInstantiated(cls),
                 message: '$cls is not instantiated.'))*/
        ;
  }

  /// Returns `true` if [x] is a subtype of [y], that is, if [x] implements an
  /// instance of [y].
  bool isSubtypeOf(ClassElement x, ClassElement y) {
    assert(isClosed);
    assert(checkInvariants(x));
    assert(checkInvariants(y, mustBeInstantiated: false));

    if (y == commonElements.objectClass) return true;
    if (x == commonElements.objectClass) return false;
    if (x.asInstanceOf(y) != null) return true;
    if (y != commonElements.functionClass) return false;
    return x.callType != null;
  }

  /// Return `true` if [x] is a (non-strict) subclass of [y].
  bool isSubclassOf(ClassElement x, ClassElement y) {
    assert(isClosed);
    assert(checkInvariants(x));
    assert(checkInvariants(y));

    if (y == commonElements.objectClass) return true;
    if (x == commonElements.objectClass) return false;
    while (x != null && x.hierarchyDepth >= y.hierarchyDepth) {
      if (x == y) return true;
      x = x.superclass;
    }
    return false;
  }

  @override
  bool isInstantiated(ClassElement cls) {
    assert(isClosed);
    ClassHierarchyNode node = _classHierarchyNodes[cls.declaration];
    return node != null && node.isInstantiated;
  }

  @override
  bool isDirectlyInstantiated(ClassElement cls) {
    assert(isClosed);
    ClassHierarchyNode node = _classHierarchyNodes[cls.declaration];
    return node != null && node.isDirectlyInstantiated;
  }

  @override
  bool isAbstractlyInstantiated(ClassElement cls) {
    assert(isClosed);
    ClassHierarchyNode node = _classHierarchyNodes[cls.declaration];
    return node != null && node.isAbstractlyInstantiated;
  }

  @override
  bool isExplicitlyInstantiated(ClassElement cls) {
    assert(isClosed);
    ClassHierarchyNode node = _classHierarchyNodes[cls.declaration];
    return node != null && node.isExplicitlyInstantiated;
  }

  @override
  bool isIndirectlyInstantiated(ClassElement cls) {
    assert(isClosed);
    ClassHierarchyNode node = _classHierarchyNodes[cls.declaration];
    return node != null && node.isIndirectlyInstantiated;
  }

  @override
  bool isAbstract(ClassElement cls) => cls.isAbstract;

  /// Returns `true` if [cls] is implemented by an instantiated class.
  bool isImplemented(ClassElement cls) {
    assert(isClosed);
    return _resolverWorld.isImplemented(cls);
  }

  /// Returns an iterable over the directly instantiated classes that extend
  /// [cls] possibly including [cls] itself, if it is live.
  Iterable<ClassElement> subclassesOf(ClassElement cls) {
    assert(isClosed);
    ClassHierarchyNode hierarchy = _classHierarchyNodes[cls.declaration];
    if (hierarchy == null) return const <ClassElement>[];
    return hierarchy
        .subclassesByMask(ClassHierarchyNode.EXPLICITLY_INSTANTIATED);
  }

  /// Returns an iterable over the directly instantiated classes that extend
  /// [cls] _not_ including [cls] itself.
  Iterable<ClassElement> strictSubclassesOf(ClassElement cls) {
    assert(isClosed);
    ClassHierarchyNode subclasses = _classHierarchyNodes[cls.declaration];
    if (subclasses == null) return const <ClassElement>[];
    return subclasses.subclassesByMask(
        ClassHierarchyNode.EXPLICITLY_INSTANTIATED,
        strict: true);
  }

  /// Returns the number of live classes that extend [cls] _not_
  /// including [cls] itself.
  int strictSubclassCount(ClassElement cls) {
    assert(isClosed);
    ClassHierarchyNode subclasses = _classHierarchyNodes[cls.declaration];
    if (subclasses == null) return 0;
    return subclasses.instantiatedSubclassCount;
  }

  /// Applies [f] to each live class that extend [cls] _not_ including [cls]
  /// itself.
  void forEachStrictSubclassOf(
      ClassElement cls, IterationStep f(ClassElement cls)) {
    assert(isClosed);
    ClassHierarchyNode subclasses = _classHierarchyNodes[cls.declaration];
    if (subclasses == null) return;
    subclasses.forEachSubclass(f, ClassHierarchyNode.EXPLICITLY_INSTANTIATED,
        strict: true);
  }

  /// Returns `true` if [predicate] applies to any live class that extend [cls]
  /// _not_ including [cls] itself.
  bool anyStrictSubclassOf(ClassElement cls, bool predicate(ClassElement cls)) {
    assert(isClosed);
    ClassHierarchyNode subclasses = _classHierarchyNodes[cls.declaration];
    if (subclasses == null) return false;
    return subclasses.anySubclass(
        predicate, ClassHierarchyNode.EXPLICITLY_INSTANTIATED,
        strict: true);
  }

  /// Returns an iterable over the directly instantiated that implement [cls]
  /// possibly including [cls] itself, if it is live.
  Iterable<ClassElement> subtypesOf(ClassElement cls) {
    assert(isClosed);
    ClassSet classSet = _classSets[cls.declaration];
    if (classSet == null) {
      return const <ClassElement>[];
    } else {
      return classSet
          .subtypesByMask(ClassHierarchyNode.EXPLICITLY_INSTANTIATED);
    }
  }

  /// Returns an iterable over the directly instantiated that implement [cls]
  /// _not_ including [cls].
  Iterable<ClassElement> strictSubtypesOf(ClassElement cls) {
    assert(isClosed);
    ClassSet classSet = _classSets[cls.declaration];
    if (classSet == null) {
      return const <ClassElement>[];
    } else {
      return classSet.subtypesByMask(ClassHierarchyNode.EXPLICITLY_INSTANTIATED,
          strict: true);
    }
  }

  /// Returns the number of live classes that implement [cls] _not_
  /// including [cls] itself.
  int strictSubtypeCount(ClassElement cls) {
    assert(isClosed);
    ClassSet classSet = _classSets[cls.declaration];
    if (classSet == null) return 0;
    return classSet.instantiatedSubtypeCount;
  }

  /// Applies [f] to each live class that implements [cls] _not_ including [cls]
  /// itself.
  void forEachStrictSubtypeOf(
      ClassElement cls, IterationStep f(ClassElement cls)) {
    assert(isClosed);
    ClassSet classSet = _classSets[cls.declaration];
    if (classSet == null) return;
    classSet.forEachSubtype(f, ClassHierarchyNode.EXPLICITLY_INSTANTIATED,
        strict: true);
  }

  /// Returns `true` if [predicate] applies to any live class that extend [cls]
  /// _not_ including [cls] itself.
  bool anyStrictSubtypeOf(ClassElement cls, bool predicate(ClassElement cls)) {
    assert(isClosed);
    ClassSet classSet = _classSets[cls.declaration];
    if (classSet == null) return false;
    return classSet.anySubtype(
        predicate, ClassHierarchyNode.EXPLICITLY_INSTANTIATED,
        strict: true);
  }

  /// Returns `true` if [a] and [b] have any known common subtypes.
  bool haveAnyCommonSubtypes(ClassElement a, ClassElement b) {
    assert(isClosed);
    ClassSet classSetA = _classSets[a.declaration];
    ClassSet classSetB = _classSets[b.declaration];
    if (classSetA == null || classSetB == null) return false;
    // TODO(johnniwinther): Implement an optimized query on [ClassSet].
    Set<ClassElement> subtypesOfB = classSetB.subtypes().toSet();
    for (ClassElement subtypeOfA in classSetA.subtypes()) {
      if (subtypesOfB.contains(subtypeOfA)) {
        return true;
      }
    }
    return false;
  }

  /// Returns `true` if any directly instantiated class other than [cls] extends
  /// [cls].
  bool hasAnyStrictSubclass(ClassElement cls) {
    assert(isClosed);
    ClassHierarchyNode subclasses = _classHierarchyNodes[cls.declaration];
    if (subclasses == null) return false;
    return subclasses.isIndirectlyInstantiated;
  }

  /// Returns `true` if any directly instantiated class other than [cls]
  /// implements [cls].
  bool hasAnyStrictSubtype(ClassElement cls) {
    return strictSubtypeCount(cls) > 0;
  }

  /// Returns `true` if all directly instantiated classes that implement [cls]
  /// extend it.
  bool hasOnlySubclasses(ClassElement cls) {
    assert(isClosed);
    // TODO(johnniwinther): move this to ClassSet?
    if (cls == commonElements.objectClass) return true;
    ClassSet classSet = _classSets[cls.declaration];
    if (classSet == null) {
      // Vacuously true.
      return true;
    }
    return classSet.hasOnlyInstantiatedSubclasses;
  }

  @override
  ClassElement getLubOfInstantiatedSubclasses(ClassElement cls) {
    assert(isClosed);
    if (_backend.isJsInterop(cls)) {
      return _backend.helpers.jsJavaScriptObjectClass;
    }
    ClassHierarchyNode hierarchy = _classHierarchyNodes[cls.declaration];
    return hierarchy != null
        ? hierarchy.getLubOfInstantiatedSubclasses()
        : null;
  }

  @override
  ClassElement getLubOfInstantiatedSubtypes(ClassElement cls) {
    assert(isClosed);
    if (_backend.isJsInterop(cls)) {
      return _backend.helpers.jsJavaScriptObjectClass;
    }
    ClassSet classSet = _classSets[cls.declaration];
    return classSet != null ? classSet.getLubOfInstantiatedSubtypes() : null;
  }

  /// Returns an iterable over the common supertypes of the [classes].
  Iterable<ClassElement> commonSupertypesOf(Iterable<ClassElement> classes) {
    assert(isClosed);
    Iterator<ClassElement> iterator = classes.iterator;
    if (!iterator.moveNext()) return const <ClassElement>[];

    ClassElement cls = iterator.current;
    assert(checkInvariants(cls));
    OrderedTypeSet typeSet = cls.allSupertypesAndSelf;
    if (!iterator.moveNext()) return typeSet.types.map((type) => type.element);

    int depth = typeSet.maxDepth;
    Link<OrderedTypeSet> otherTypeSets = const Link<OrderedTypeSet>();
    do {
      ClassElement otherClass = iterator.current;
      assert(checkInvariants(otherClass));
      OrderedTypeSet otherTypeSet = otherClass.allSupertypesAndSelf;
      otherTypeSets = otherTypeSets.prepend(otherTypeSet);
      if (otherTypeSet.maxDepth < depth) {
        depth = otherTypeSet.maxDepth;
      }
    } while (iterator.moveNext());

    List<ClassElement> commonSupertypes = <ClassElement>[];
    OUTER:
    for (Link<ResolutionDartType> link = typeSet[depth];
        link.head.element != commonElements.objectClass;
        link = link.tail) {
      ClassElement cls = link.head.element;
      for (Link<OrderedTypeSet> link = otherTypeSets;
          !link.isEmpty;
          link = link.tail) {
        if (link.head.asInstanceOf(cls) == null) {
          continue OUTER;
        }
      }
      commonSupertypes.add(cls);
    }
    commonSupertypes.add(commonElements.objectClass);
    return commonSupertypes;
  }

  Iterable<ClassElement> commonSubclasses(ClassElement cls1, ClassQuery query1,
      ClassElement cls2, ClassQuery query2) {
    // TODO(johnniwinther): Use [ClassSet] to compute this.
    // Compute the set of classes that are contained in both class subsets.
    Set<ClassEntity> common =
        _commonContainedClasses(cls1, query1, cls2, query2);
    if (common == null || common.isEmpty) return const <ClassElement>[];
    // Narrow down the candidates by only looking at common classes
    // that do not have a superclass or supertype that will be a
    // better candidate.
    return common.where((ClassElement each) {
      bool containsSuperclass = common.contains(each.supertype.element);
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
      for (Link link = each.interfaces; !link.isEmpty; link = link.tail) {
        if (common.contains(link.head.element)) return false;
      }
      return true;
    });
  }

  Set<ClassElement> _commonContainedClasses(ClassElement cls1,
      ClassQuery query1, ClassElement cls2, ClassQuery query2) {
    Iterable<ClassElement> xSubset = _containedSubset(cls1, query1);
    if (xSubset == null) return null;
    Iterable<ClassElement> ySubset = _containedSubset(cls2, query2);
    if (ySubset == null) return null;
    return xSubset.toSet().intersection(ySubset.toSet());
  }

  Iterable<ClassElement> _containedSubset(ClassElement cls, ClassQuery query) {
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

  /// Returns an iterable over the live mixin applications that mixin [cls].
  Iterable<MixinApplicationElement> mixinUsesOf(ClassElement cls) {
    assert(isClosed);
    if (_liveMixinUses == null) {
      _liveMixinUses = new Map<ClassElement, List<MixinApplicationElement>>();
      for (ClassElement mixin in _mixinUses.keys) {
        List<MixinApplicationElement> uses = <MixinApplicationElement>[];

        void addLiveUse(MixinApplicationElement mixinApplication) {
          if (isInstantiated(mixinApplication)) {
            uses.add(mixinApplication);
          } else if (mixinApplication.isNamedMixinApplication) {
            Set<MixinApplicationElement> next = _mixinUses[mixinApplication];
            if (next != null) {
              next.forEach(addLiveUse);
            }
          }
        }

        _mixinUses[mixin].forEach(addLiveUse);
        if (uses.isNotEmpty) {
          _liveMixinUses[mixin] = uses;
        }
      }
    }
    Iterable<MixinApplicationElement> uses = _liveMixinUses[cls];
    return uses != null ? uses : const <MixinApplicationElement>[];
  }

  /// Returns `true` if [cls] is mixed into a live class.
  bool isUsedAsMixin(ClassElement cls) {
    assert(isClosed);
    return !mixinUsesOf(cls).isEmpty;
  }

  /// Returns `true` if any live class that mixes in [cls] implements [type].
  bool hasAnySubclassOfMixinUseThatImplements(
      ClassElement cls, ClassElement type) {
    assert(isClosed);
    return mixinUsesOf(cls)
        .any((use) => hasAnySubclassThatImplements(use, type));
  }

  /// Returns `true` if any live class that mixes in [mixin] is also a subclass
  /// of [superclass].
  bool hasAnySubclassThatMixes(ClassElement superclass, ClassElement mixin) {
    assert(isClosed);
    return mixinUsesOf(mixin).any((each) => each.isSubclassOf(superclass));
  }

  /// Returns `true` if [cls] or any superclass mixes in [mixin].
  bool isSubclassOfMixinUseOf(ClassElement cls, ClassElement mixin) {
    assert(isClosed);
    assert(cls.isDeclaration);
    assert(mixin.isDeclaration);
    if (isUsedAsMixin(mixin)) {
      ClassElement current = cls;
      while (current != null) {
        if (current.isMixinApplication) {
          MixinApplicationElement application = current;
          if (application.mixin == mixin) return true;
        }
        current = current.superclass;
      }
    }
    return false;
  }

  /// Returns `true` if every subtype of [x] is a subclass of [y] or a subclass
  /// of a mixin application of [y].
  bool everySubtypeIsSubclassOfOrMixinUseOf(ClassElement x, ClassElement y) {
    assert(isClosed);
    assert(x.isDeclaration);
    assert(y.isDeclaration);
    Map<ClassElement, bool> secondMap =
        _subtypeCoveredByCache[x] ??= <ClassElement, bool>{};
    return secondMap[y] ??= subtypesOf(x).every((ClassElement cls) =>
        isSubclassOf(cls, y) || isSubclassOfMixinUseOf(cls, y));
  }

  /// Returns `true` if any subclass of [superclass] implements [type].
  bool hasAnySubclassThatImplements(
      ClassElement superclass, ClassElement type) {
    assert(isClosed);

    Set<ClassElement> subclasses =
        _typesImplementedBySubclasses[superclass.declaration];
    if (subclasses == null) return false;
    return subclasses.contains(type);
  }

  @override
  bool hasElementIn(ClassElement cls, Selector selector, Element element) {
    // Use [:implementation:] of [element]
    // because our function set only stores declarations.
    Element result = findMatchIn(cls, selector);
    return result == null
        ? false
        : result.implementation == element.implementation;
  }

  Element findMatchIn(ClassElement cls, Selector selector,
      {ClassElement stopAtSuperclass}) {
    // Use the [:implementation] of [cls] in case the found [element]
    // is in the patch class.
    var result = cls.implementation
        .lookupByName(selector.memberName, stopAt: stopAtSuperclass);
    return result;
  }

  /// Returns whether a [selector] call on an instance of [cls]
  /// will hit a method at runtime, and not go through [noSuchMethod].
  bool hasConcreteMatch(ClassElement cls, Selector selector,
      {ClassElement stopAtSuperclass}) {
    assert(invariant(cls, isInstantiated(cls),
        message: '$cls has not been instantiated.'));
    Element element = findMatchIn(cls, selector);
    if (element == null) return false;

    if (element.isAbstract) {
      ClassElement enclosingClass = element.enclosingClass;
      return hasConcreteMatch(enclosingClass.superclass, selector);
    }
    return selector.appliesUntyped(element);
  }

  @override
  bool needsNoSuchMethod(
      ClassElement base, Selector selector, ClassQuery query) {
    /// Returns `true` if subclasses in the [rootNode] tree needs noSuchMethod
    /// handling.
    bool subclassesNeedNoSuchMethod(ClassHierarchyNode rootNode) {
      if (!rootNode.isInstantiated) {
        // No subclass needs noSuchMethod handling since they are all
        // uninstantiated.
        return false;
      }
      ClassElement rootClass = rootNode.cls;
      if (hasConcreteMatch(rootClass, selector)) {
        // The root subclass has a concrete implementation so no subclass needs
        // noSuchMethod handling.
        return false;
      } else if (rootNode.isExplicitlyInstantiated) {
        // The root class need noSuchMethod handling.
        return true;
      }
      IterationStep result = rootNode.forEachSubclass((ClassElement subclass) {
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

  /// Returns [ClassHierarchyNode] for [cls] used to model the class hierarchies
  /// of known classes.
  ///
  /// This method is only provided for testing. For queries on classes, use the
  /// methods defined in [ClosedWorld].
  ClassHierarchyNode getClassHierarchyNode(ClassElement cls) {
    return _classHierarchyNodes[cls.declaration];
  }

  /// Returns [ClassSet] for [cls] used to model the extends and implements
  /// relations of known classes.
  ///
  /// This method is only provided for testing. For queries on classes, use the
  /// methods defined in [ClosedWorld].
  ClassSet getClassSet(ClassElement cls) {
    return _classSets[cls.declaration];
  }

  void registerClosureClass(ClosureClassElement cls) {
    ClassHierarchyNode parentNode = getClassHierarchyNode(cls.superclass);
    ClassHierarchyNode node =
        _classHierarchyNodes[cls] = new ClassHierarchyNode(parentNode, cls);
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

  Iterable<TypedefElement> get allTypedefs => _allTypedefs;

  @override
  String dump([ClassElement cls]) {
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

  bool hasAnyUserDefinedGetter(Selector selector, TypeMask mask) {
    return allFunctions.filter(selector, mask).any((each) => each.isGetter);
  }

  FieldElement locateSingleField(Selector selector, TypeMask mask) {
    Element result = locateSingleElement(selector, mask);
    return (result != null && result.isField) ? result : null;
  }

  MemberElement locateSingleElement(Selector selector, TypeMask mask) {
    assert(isClosed);
    mask ??= commonMasks.dynamicType;
    return mask.locateSingleElement(selector, this);
  }

  TypeMask extendMaskIfReachesAll(Selector selector, TypeMask mask) {
    assert(isClosed);
    bool canReachAll = true;
    if (mask != null) {
      canReachAll = _backend.hasInvokeOnSupport &&
          mask.needsNoSuchMethodHandling(selector, this);
    }
    return canReachAll ? commonMasks.dynamicType : mask;
  }

  void addFunctionCalledInLoop(Element element) {
    functionsCalledInLoop.add(element.declaration);
  }

  bool isCalledInLoop(Element element) {
    return functionsCalledInLoop.contains(element.declaration);
  }

  bool fieldNeverChanges(MemberElement element) {
    if (!element.isField) return false;
    if (_backend.isNative(element)) {
      // Some native fields are views of data that may be changed by operations.
      // E.g. node.firstChild depends on parentNode.removeBefore(n1, n2).
      // TODO(sra): Refine the effect classification so that native effects are
      // distinct from ordinary Dart effects.
      return false;
    }

    if (element.isFinal || element.isConst) {
      return true;
    }
    if (element.isInstanceMember) {
      return !_resolverWorld.hasInvokedSetter(element) &&
          !_resolverWorld.fieldSetters.contains(element);
    }
    return false;
  }

  SideEffects getSideEffectsOfElement(Element element) {
    // The type inferrer (where the side effects are being computed),
    // does not see generative constructor bodies because they are
    // created by the backend. Also, it does not make any distinction
    // between a constructor and its body for side effects. This
    // implies that currently, the side effects of a constructor body
    // contain the side effects of the initializers.
    assert(!element.isGenerativeConstructorBody);
    assert(!element.isField);
    return sideEffects.putIfAbsent(element.declaration, () {
      return new SideEffects();
    });
  }

  @override
  SideEffects getCurrentlyKnownSideEffects(Element element) {
    return getSideEffectsOfElement(element);
  }

  void registerSideEffects(Element element, SideEffects effects) {
    if (sideEffectsFreeElements.contains(element)) return;
    sideEffects[element.declaration] = effects;
  }

  void registerSideEffectsFree(Element element) {
    sideEffects[element.declaration] = new SideEffects.empty();
    sideEffectsFreeElements.add(element);
  }

  SideEffects getSideEffectsOfSelector(Selector selector, TypeMask mask) {
    // We're not tracking side effects of closures.
    if (selector.isClosureCall) return new SideEffects();
    SideEffects sideEffects = new SideEffects.empty();
    for (MemberElement e in allFunctions.filter(selector, mask)) {
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

  void registerCannotThrow(Element element) {
    elementsThatCannotThrow.add(element);
  }

  bool getCannotThrow(Element element) {
    return elementsThatCannotThrow.contains(element);
  }

  void registerMightBePassedToApply(Element element) {
    functionsThatMightBePassedToApply.add(element);
  }

  bool getMightBePassedToApply(Element element) {
    // We have to check whether the element we look at was created after
    // type inference ran. This is currently only the case for the call
    // method of function classes that were generated for function
    // expressions. In such a case, we have to look at the original
    // function expressions's element.
    // TODO(herhut): Generate classes for function expressions earlier.
    if (element is SynthesizedCallMethodElementX) {
      return getMightBePassedToApply(element.expression);
    }
    return functionsThatMightBePassedToApply.contains(element);
  }

  @override
  bool getCurrentlyKnownMightBePassedToApply(Element element) {
    return getMightBePassedToApply(element);
  }
}
