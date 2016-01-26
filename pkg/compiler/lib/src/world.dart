// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.world;

import 'closure.dart' show
    SynthesizedCallMethodElementX;
import 'common.dart';
import 'common/backend_api.dart' show
    Backend;
import 'compiler.dart' show
    Compiler;
import 'core_types.dart' show
    CoreClasses;
import 'dart_types.dart';
import 'elements/elements.dart' show
    ClassElement,
    Element,
    FunctionElement,
    MixinApplicationElement,
    TypedefElement,
    VariableElement;
import 'ordered_typeset.dart';
import 'types/types.dart' as ti;
import 'universe/class_set.dart';
import 'universe/function_set.dart' show
    FunctionSet;
import 'universe/selector.dart' show
    Selector;
import 'universe/side_effects.dart' show
    SideEffects;
import 'util/util.dart' show
    Link;

abstract class ClassWorld {
  // TODO(johnniwinther): Refine this into a `BackendClasses` interface.
  Backend get backend;

  // TODO(johnniwinther): Remove the need for this getter.
  @deprecated
  Compiler get compiler;

  /// The [ClassElement] for the [Object] class defined in 'dart:core'.
  ClassElement get objectClass;

  /// The [ClassElement] for the [Function] class defined in 'dart:core'.
  ClassElement get functionClass;

  /// The [ClassElement] for the [bool] class defined in 'dart:core'.
  ClassElement get boolClass;

  /// The [ClassElement] for the [num] class defined in 'dart:core'.
  ClassElement get numClass;

  /// The [ClassElement] for the [int] class defined in 'dart:core'.
  ClassElement get intClass;

  /// The [ClassElement] for the [double] class defined in 'dart:core'.
  ClassElement get doubleClass;

  /// The [ClassElement] for the [String] class defined in 'dart:core'.
  ClassElement get stringClass;

  /// Returns `true` if [cls] is either directly or indirectly instantiated.
  bool isInstantiated(ClassElement cls);

  /// Returns `true` if [cls] is directly instantiated.
  bool isDirectlyInstantiated(ClassElement cls);

  /// Returns `true` if [cls] is indirectly instantiated, that is through a
  /// subclass.
  bool isIndirectlyInstantiated(ClassElement cls);

  /// Returns `true` if [cls] is implemented by an instantiated class.
  bool isImplemented(ClassElement cls);

  /// Returns `true` if the class world is closed.
  bool get isClosed;

  /// Return `true` if [x] is a subclass of [y].
  bool isSubclassOf(ClassElement x, ClassElement y);

  /// Returns `true` if [x] is a subtype of [y], that is, if [x] implements an
  /// instance of [y].
  bool isSubtypeOf(ClassElement x, ClassElement y);

  /// Returns an iterable over the live classes that extend [cls] including
  /// [cls] itself.
  Iterable<ClassElement> subclassesOf(ClassElement cls);

  /// Returns an iterable over the live classes that extend [cls] _not_
  /// including [cls] itself.
  Iterable<ClassElement> strictSubclassesOf(ClassElement cls);

  /// Returns an iterable over the directly instantiated that implement [cls]
  /// possibly including [cls] itself, if it is live.
  Iterable<ClassElement> subtypesOf(ClassElement cls);

  /// Returns an iterable over the live classes that implement [cls] _not_
  /// including [cls] if it is live.
  Iterable<ClassElement> strictSubtypesOf(ClassElement cls);

  /// Returns `true` if [a] and [b] have any known common subtypes.
  bool haveAnyCommonSubtypes(ClassElement a, ClassElement b);

  /// Returns `true` if any live class other than [cls] extends [cls].
  bool hasAnyStrictSubclass(ClassElement cls);

  /// Returns `true` if any live class other than [cls] implements [cls].
  bool hasAnyStrictSubtype(ClassElement cls);

  /// Returns `true` if all live classes that implement [cls] extend it.
  bool hasOnlySubclasses(ClassElement cls);

  /// Returns the most specific subclass of [cls] (including [cls]) that is
  /// directly instantiated or a superclass of all directly instantiated
  /// subclasses. If [cls] is not instantiated, `null` is returned.
  ClassElement getLubOfInstantiatedSubclasses(ClassElement cls);

  /// Returns the most specific subtype of [cls] (including [cls]) that is
  /// directly instantiated or a superclass of all directly instantiated
  /// subtypes. If no subtypes of [cls] are instantiated, `null` is returned.
  ClassElement getLubOfInstantiatedSubtypes(ClassElement cls);

  /// Returns an iterable over the common supertypes of the [classes].
  Iterable<ClassElement> commonSupertypesOf(Iterable<ClassElement> classes);

  /// Returns an iterable over the live mixin applications that mixin [cls].
  Iterable<MixinApplicationElement> mixinUsesOf(ClassElement cls);

  /// Returns `true` if [cls] is mixed into a live class.
  bool isUsedAsMixin(ClassElement cls);

  /// Returns `true` if any live class that mixes in [cls] implements [type].
  bool hasAnySubclassOfMixinUseThatImplements(ClassElement cls,
                                              ClassElement type);

  /// Returns `true` if any live class that mixes in [mixin] is also a subclass
  /// of [superclass].
  bool hasAnySubclassThatMixes(ClassElement superclass, ClassElement mixin);

  /// Returns `true` if any subclass of [superclass] implements [type].
  bool hasAnySubclassThatImplements(ClassElement superclass, ClassElement type);

  /// Returns `true` if closed-world assumptions can be made, that is,
  /// incremental compilation isn't enabled.
  bool get hasClosedWorldAssumption;

  /// Returns a string representation of the closed world.
  ///
  /// If [cls] is provided, the dump will contain only classes related to [cls].
  String dump([ClassElement cls]);
}

class World implements ClassWorld {
  ClassElement get objectClass => coreClasses.objectClass;
  ClassElement get functionClass => coreClasses.functionClass;
  ClassElement get boolClass => coreClasses.boolClass;
  ClassElement get numClass => coreClasses.numClass;
  ClassElement get intClass => coreClasses.intClass;
  ClassElement get doubleClass => coreClasses.doubleClass;
  ClassElement get stringClass => coreClasses.stringClass;
  ClassElement get nullClass => coreClasses.nullClass;

  /// Cache of [ti.FlatTypeMask]s grouped by the 8 possible values of the
  /// [ti.FlatTypeMask.flags] property.
  List<Map<ClassElement, ti.TypeMask>> canonicalizedTypeMasks =
      new List<Map<ClassElement, ti.TypeMask>>.filled(8, null);

  bool checkInvariants(ClassElement cls, {bool mustBeInstantiated: true}) {
    return
      invariant(cls, cls.isDeclaration,
                message: '$cls must be the declaration.') &&
      invariant(cls, cls.isResolved,
                message: '$cls must be resolved.')/* &&
      // TODO(johnniwinther): Reinsert this or similar invariant.
      (!mustBeInstantiated ||
       invariant(cls, isInstantiated(cls),
                 message: '$cls is not instantiated.'))*/;
 }

  /// Returns `true` if [x] is a subtype of [y], that is, if [x] implements an
  /// instance of [y].
  bool isSubtypeOf(ClassElement x, ClassElement y) {
    assert(checkInvariants(x));
    assert(checkInvariants(y, mustBeInstantiated: false));

    if (y == objectClass) return true;
    if (x == objectClass) return false;
    if (x.asInstanceOf(y) != null) return true;
    if (y != functionClass) return false;
    return x.callType != null;
  }

  /// Return `true` if [x] is a (non-strict) subclass of [y].
  bool isSubclassOf(ClassElement x, ClassElement y) {
    assert(checkInvariants(x));
    assert(checkInvariants(y));

    if (y == objectClass) return true;
    if (x == objectClass) return false;
    while (x != null && x.hierarchyDepth >= y.hierarchyDepth) {
      if (x == y) return true;
      x = x.superclass;
    }
    return false;
  }

  @override
  bool isInstantiated(ClassElement cls) {
    ClassHierarchyNode node = _classHierarchyNodes[cls.declaration];
    return node != null && node.isInstantiated;
  }

  @override
  bool isDirectlyInstantiated(ClassElement cls) {
    ClassHierarchyNode node = _classHierarchyNodes[cls.declaration];
    return node != null && node.isDirectlyInstantiated;
  }

  @override
  bool isIndirectlyInstantiated(ClassElement cls) {
    ClassHierarchyNode node = _classHierarchyNodes[cls.declaration];
    return node != null && node.isIndirectlyInstantiated;
  }

  /// Returns `true` if [cls] is implemented by an instantiated class.
  bool isImplemented(ClassElement cls) {
    return compiler.resolverWorld.isImplemented(cls);
  }

  /// Returns an iterable over the directly instantiated classes that extend
  /// [cls] possibly including [cls] itself, if it is live.
  Iterable<ClassElement> subclassesOf(ClassElement cls) {
    ClassHierarchyNode hierarchy = _classHierarchyNodes[cls.declaration];
    if (hierarchy == null) return const <ClassElement>[];
    return hierarchy.subclassesByMask(
        ClassHierarchyNode.DIRECTLY_INSTANTIATED);
  }

  /// Returns an iterable over the directly instantiated classes that extend
  /// [cls] _not_ including [cls] itself.
  Iterable<ClassElement> strictSubclassesOf(ClassElement cls) {
    ClassHierarchyNode subclasses = _classHierarchyNodes[cls.declaration];
    if (subclasses == null) return const <ClassElement>[];
    return subclasses.subclassesByMask(
        ClassHierarchyNode.DIRECTLY_INSTANTIATED, strict: true);
  }

  /// Returns an iterable over the directly instantiated that implement [cls]
  /// possibly including [cls] itself, if it is live.
  Iterable<ClassElement> subtypesOf(ClassElement cls) {
    ClassSet classSet = _classSets[cls.declaration];
    if (classSet == null) {
      return const <ClassElement>[];
    } else {
      return classSet.subtypesByMask(ClassHierarchyNode.DIRECTLY_INSTANTIATED);
    }
  }

  /// Returns an iterable over the directly instantiated that implement [cls]
  /// _not_ including [cls].
  Iterable<ClassElement> strictSubtypesOf(ClassElement cls) {
    ClassSet classSet = _classSets[cls.declaration];
    if (classSet == null) {
      return const <ClassElement>[];
    } else {
      return classSet.subtypesByMask(
          ClassHierarchyNode.DIRECTLY_INSTANTIATED,
          strict: true);
    }
  }

  /// Returns `true` if [a] and [b] have any known common subtypes.
  bool haveAnyCommonSubtypes(ClassElement a, ClassElement b) {
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
    ClassHierarchyNode subclasses = _classHierarchyNodes[cls.declaration];
    if (subclasses == null) return false;
    return subclasses.isIndirectlyInstantiated;
  }

  /// Returns `true` if any directly instantiated class other than [cls]
  /// implements [cls].
  bool hasAnyStrictSubtype(ClassElement cls) {
    return !strictSubtypesOf(cls).isEmpty;
  }

  /// Returns `true` if all directly instantiated classes that implement [cls]
  /// extend it.
  bool hasOnlySubclasses(ClassElement cls) {
    // TODO(johnniwinther): move this to ClassSet?
    if (cls == objectClass) return true;
    Iterable<ClassElement> subtypes = strictSubtypesOf(cls);
    if (subtypes == null) return true;
    Iterable<ClassElement> subclasses = strictSubclassesOf(cls);
    return subclasses != null && (subclasses.length == subtypes.length);
  }

  @override
  ClassElement getLubOfInstantiatedSubclasses(ClassElement cls) {
    ClassHierarchyNode hierarchy = _classHierarchyNodes[cls.declaration];
    return hierarchy != null
        ? hierarchy.getLubOfInstantiatedSubclasses() : null;
  }

  @override
  ClassElement getLubOfInstantiatedSubtypes(ClassElement cls) {
    ClassSet classSet = _classSets[cls.declaration];
    return classSet != null
        ? classSet.getLubOfInstantiatedSubtypes() : null;
  }

  /// Returns an iterable over the common supertypes of the [classes].
  Iterable<ClassElement> commonSupertypesOf(Iterable<ClassElement> classes) {
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
    OUTER: for (Link<DartType> link = typeSet[depth];
                link.head.element != objectClass;
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
    commonSupertypes.add(objectClass);
    return commonSupertypes;
  }

  /// Returns an iterable over all mixin applications that mixin [cls].
  Iterable<MixinApplicationElement> allMixinUsesOf(ClassElement cls) {
    Iterable<MixinApplicationElement> uses = _mixinUses[cls];
    return uses != null ? uses : const <MixinApplicationElement>[];
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
            List<MixinApplicationElement> next = _mixinUses[mixinApplication];
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
    return !mixinUsesOf(cls).isEmpty;
  }

  /// Returns `true` if any live class that mixes in [cls] implements [type].
  bool hasAnySubclassOfMixinUseThatImplements(ClassElement cls,
                                              ClassElement type) {
    return mixinUsesOf(cls).any(
        (use) => hasAnySubclassThatImplements(use, type));
  }

  /// Returns `true` if any live class that mixes in [mixin] is also a subclass
  /// of [superclass].
  bool hasAnySubclassThatMixes(ClassElement superclass, ClassElement mixin) {
    return mixinUsesOf(mixin).any((each) => each.isSubclassOf(superclass));
  }

  /// Returns `true` if any subclass of [superclass] implements [type].
  bool hasAnySubclassThatImplements(ClassElement superclass,
                                    ClassElement type) {
    Set<ClassElement> subclasses = typesImplementedBySubclassesOf(superclass);
    if (subclasses == null) return false;
    return subclasses.contains(type);
  }

  final Compiler compiler;
  Backend get backend => compiler.backend;
  final FunctionSet allFunctions;
  final Set<Element> functionsCalledInLoop = new Set<Element>();
  final Map<Element, SideEffects> sideEffects = new Map<Element, SideEffects>();

  final Set<TypedefElement> allTypedefs = new Set<TypedefElement>();

  final Map<ClassElement, List<MixinApplicationElement>> _mixinUses =
      new Map<ClassElement, List<MixinApplicationElement>>();
  Map<ClassElement, List<MixinApplicationElement>> _liveMixinUses;

  final Map<ClassElement, Set<ClassElement>> _typesImplementedBySubclasses =
      new Map<ClassElement, Set<ClassElement>>();

  // We keep track of subtype and subclass relationships in four
  // distinct sets to make class hierarchy analysis faster.
  final Map<ClassElement, ClassHierarchyNode> _classHierarchyNodes =
      <ClassElement, ClassHierarchyNode>{};
  final Map<ClassElement, ClassSet> _classSets =
        <ClassElement, ClassSet>{};

  final Set<Element> sideEffectsFreeElements = new Set<Element>();

  final Set<Element> elementsThatCannotThrow = new Set<Element>();

  final Set<Element> functionsThatMightBePassedToApply =
      new Set<FunctionElement>();

  final Set<Element> alreadyPopulated;

  bool get isClosed => compiler.phase > Compiler.PHASE_RESOLVING;

  // Used by selectors.
  bool isForeign(Element element) {
    return compiler.backend.isForeign(element);
  }

  Set<ClassElement> typesImplementedBySubclassesOf(ClassElement cls) {
    return _typesImplementedBySubclasses[cls.declaration];
  }

  World(Compiler compiler)
      : allFunctions = new FunctionSet(compiler),
        this.compiler = compiler,
        alreadyPopulated = compiler.cacheStrategy.newSet();

  CoreClasses get coreClasses => compiler.coreClasses;

  DiagnosticReporter get reporter => compiler.reporter;

  /// Called to add [cls] to the set of known classes.
  ///
  /// This ensures that class hierarchy queries can be performed on [cls] and
  /// classes that extend or implement it.
  void registerClass(ClassElement cls, {bool isDirectlyInstantiated: false}) {
    _ensureClassSet(cls);
    if (isDirectlyInstantiated) {
      _updateClassHierarchyNodeForClass(cls, directlyInstantiated: true);
    }
  }

  /// Returns [ClassHierarchyNode] for [cls] used to model the class hierarchies
  /// of known classes.
  ///
  /// This method is only provided for testing. For queries on classes, use the
  /// methods defined in [ClassWorld].
  ClassHierarchyNode getClassHierarchyNode(ClassElement cls) {
    return _classHierarchyNodes[cls.declaration];
  }

  ClassHierarchyNode _ensureClassHierarchyNode(ClassElement cls) {
    cls = cls.declaration;
    return _classHierarchyNodes.putIfAbsent(cls, () {
      ClassHierarchyNode node = new ClassHierarchyNode(cls);
      if (cls.superclass != null) {
        _ensureClassHierarchyNode(cls.superclass).addDirectSubclass(node);
      }
      return node;
    });
  }

  /// Returns [ClassSet] for [cls] used to model the extends and implements
  /// relations of known classes.
  ///
  /// This method is only provided for testing. For queries on classes, use the
  /// methods defined in [ClassWorld].
  ClassSet getClassSet(ClassElement cls) {
    return _classSets[cls.declaration];
  }

  ClassSet _ensureClassSet(ClassElement cls) {
    cls = cls.declaration;
    return _classSets.putIfAbsent(cls, () {
      ClassHierarchyNode node = _ensureClassHierarchyNode(cls);
      ClassSet classSet = new ClassSet(node);

      for (InterfaceType type in cls.allSupertypes) {
        // TODO(johnniwinther): Optimization: Avoid adding [cls] to
        // superclasses.
        ClassSet subtypeSet = _ensureClassSet(type.element);
        subtypeSet.addSubtype(node);
      }
      return classSet;
    });
  }

  void _updateClassHierarchyNodeForClass(
      ClassElement cls,
      {bool directlyInstantiated: false,
       bool indirectlyInstantiated: false}) {
    ClassHierarchyNode node = getClassHierarchyNode(cls);
    bool changed = false;
    if (directlyInstantiated && !node.isDirectlyInstantiated) {
      node.isDirectlyInstantiated = true;
      changed = true;
    }
    if (indirectlyInstantiated && !node.isIndirectlyInstantiated) {
      node.isIndirectlyInstantiated = true;
      changed = true;
    }
    if (changed && cls.superclass != null) {
      _updateClassHierarchyNodeForClass(
          cls.superclass, indirectlyInstantiated: true);
    }
    // Ensure that classes implicitly implementing `Function` are in its
    // subtype set.
    if (cls != coreClasses.functionClass &&
        cls.implementsFunction(compiler)) {
      ClassSet subtypeSet = _ensureClassSet(coreClasses.functionClass);
      subtypeSet.addSubtype(node);
    }
  }

  void populate() {
    /// Updates the `isDirectlyInstantiated` and `isIndirectlyInstantiated`
    /// properties of the [ClassHierarchyNode] for [cls].

    void addSubtypes(ClassElement cls) {
      if (compiler.hasIncrementalSupport && !alreadyPopulated.add(cls)) {
        return;
      }
      assert(cls.isDeclaration);
      if (!cls.isResolved) {
        reporter.internalError(cls, 'Class "${cls.name}" is not resolved.');
      }

      _updateClassHierarchyNodeForClass(cls, directlyInstantiated: true);

      // Walk through the superclasses, and record the types
      // implemented by that type on the superclasses.
      ClassElement superclass = cls.superclass;
      while (superclass != null) {
        Set<Element> typesImplementedBySubclassesOfCls =
            _typesImplementedBySubclasses.putIfAbsent(
                superclass, () => new Set<ClassElement>());
        for (DartType current in cls.allSupertypes) {
          typesImplementedBySubclassesOfCls.add(current.element);
        }
        superclass = superclass.superclass;
      }
    }

    // Use the [:seenClasses:] set to include non-instantiated
    // classes: if the superclass of these classes require RTI, then
    // they also need RTI, so that a constructor passes the type
    // variables to the super constructor.
    compiler.resolverWorld.directlyInstantiatedClasses.forEach(addSubtypes);
  }

  @override
  String dump([ClassElement cls]) {
    StringBuffer sb = new StringBuffer();
    if (cls != null) {
      sb.write("Classes in the closed world related to $cls:\n");
    } else {
      sb.write("Instantiated classes in the closed world:\n");
    }
    getClassHierarchyNode(coreClasses.objectClass)
        .printOn(sb, ' ', instantiatedOnly: cls == null, withRespectTo: cls);
    return sb.toString();
  }

  void registerMixinUse(MixinApplicationElement mixinApplication,
                        ClassElement mixin) {
    // TODO(johnniwinther): Add map restricted to live classes.
    // We don't support patch classes as mixin.
    assert(mixin.isDeclaration);
    List<MixinApplicationElement> users =
        _mixinUses.putIfAbsent(mixin, () =>
                               new List<MixinApplicationElement>());
    users.add(mixinApplication);
  }

  bool hasAnyUserDefinedGetter(Selector selector, ti.TypeMask mask) {
    return allFunctions.filter(selector, mask).any((each) => each.isGetter);
  }

  void registerUsedElement(Element element) {
    if (element.isInstanceMember && !element.isAbstract) {
      allFunctions.add(element);
    }
  }

  VariableElement locateSingleField(Selector selector, ti.TypeMask mask) {
    Element result = locateSingleElement(selector, mask);
    return (result != null && result.isField) ? result : null;
  }

  Element locateSingleElement(Selector selector, ti.TypeMask mask) {
    mask = mask == null
        ? compiler.typesTask.dynamicType
        : mask;
    return mask.locateSingleElement(selector, mask, compiler);
  }

  ti.TypeMask extendMaskIfReachesAll(Selector selector, ti.TypeMask mask) {
    bool canReachAll = true;
    if (mask != null) {
      canReachAll =
          compiler.enabledInvokeOn &&
          mask.needsNoSuchMethodHandling(selector, this);
    }
    return canReachAll ? compiler.typesTask.dynamicType : mask;
  }

  void addFunctionCalledInLoop(Element element) {
    functionsCalledInLoop.add(element.declaration);
  }

  bool isCalledInLoop(Element element) {
    return functionsCalledInLoop.contains(element.declaration);
  }

  bool fieldNeverChanges(Element element) {
    if (!element.isField) return false;
    if (backend.isNative(element)) {
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
      return !compiler.resolverWorld.hasInvokedSetter(element, this) &&
             !compiler.resolverWorld.fieldSetters.contains(element);
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

  void registerSideEffects(Element element, SideEffects effects) {
    if (sideEffectsFreeElements.contains(element)) return;
    sideEffects[element.declaration] = effects;
  }

  void registerSideEffectsFree(Element element) {
    sideEffects[element.declaration] = new SideEffects.empty();
    sideEffectsFreeElements.add(element);
  }

  SideEffects getSideEffectsOfSelector(Selector selector, ti.TypeMask mask) {
    // We're not tracking side effects of closures.
    if (selector.isClosureCall) return new SideEffects();
    SideEffects sideEffects = new SideEffects.empty();
    for (Element e in allFunctions.filter(selector, mask)) {
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

  bool get hasClosedWorldAssumption => !compiler.hasIncrementalSupport;
}
