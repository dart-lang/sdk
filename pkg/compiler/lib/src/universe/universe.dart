// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library universe;

import 'dart:collection';

import '../common/names.dart' show
    Identifiers,
    Names,
    Selectors;
import '../compiler.dart' show
    Compiler;
import '../diagnostics/invariant.dart' show
    invariant;
import '../diagnostics/spannable.dart' show
    SpannableAssertionFailure;
import '../elements/elements.dart';
import '../dart_types.dart';
import '../tree/tree.dart';
import '../types/types.dart';
import '../util/util.dart';
import '../world.dart' show
    ClassWorld,
    World;

part 'call_structure.dart';
part 'function_set.dart';
part 'selector.dart';
part 'side_effects.dart';

class UniverseSelector {
  final Selector selector;
  final ReceiverMask mask;

  UniverseSelector(this.selector, this.mask);

  bool appliesUnnamed(Element element, ClassWorld world) {
    return selector.appliesUnnamed(element, world) &&
        (mask == null || mask.canHit(element, selector, world));
  }

  String toString() => '$selector,$mask';
}

/// A potential receiver for a dynamic call site.
abstract class ReceiverMask {
  /// Returns whether [element] is a potential target when being
  /// invoked on this receiver mask. [selector] is used to ensure library
  /// privacy is taken into account.
  bool canHit(Element element, Selector selector, ClassWorld classWorld);
}

/// A set of potential receivers for the dynamic call sites of the same
/// selector.
///
/// For instance for these calls
///
///     new A().foo(a, b);
///     new B().foo(0, 42);
///
/// the receiver mask set for dynamic calls to 'foo' with to positional
/// arguments will contain receiver masks abstracting `new A()` and `new B()`.
abstract class ReceiverMaskSet {
  /// Returns `true` if [selector] applies to any of the potential receivers
  /// in this set given the closed [world].
  bool applies(Element element, Selector selector, ClassWorld world);

  /// Returns `true` if any potential receivers in this set given the closed
  /// [world] have no implementation matching [selector].
  ///
  /// For instance for this code snippet
  ///
  ///     class A {}
  ///     class B { foo() {} }
  ///     m(b) => (b ? new A() : new B()).foo();
  ///
  /// the potential receiver `new A()` have no implementation of `foo` and thus
  /// needs to handle the call though its `noSuchMethod` handler.
  bool needsNoSuchMethodHandling(Selector selector, ClassWorld world);
}

/// A mutable [ReceiverMaskSet] used in [Universe].
abstract class UniverseReceiverMaskSet extends ReceiverMaskSet {
  /// Adds [mask] to this set of potential receivers. Return `true` if the
  /// set expanded due to the new mask.
  bool addReceiverMask(ReceiverMask mask);
}

/// Strategy for computing potential receivers of dynamic call sites.
abstract class ReceiverMaskStrategy {
  /// Create a [UniverseReceiverMaskSet] to represent the potential receiver for
  /// a dynamic call site with [selector].
  UniverseReceiverMaskSet createReceiverMaskSet(Selector selector);
}

class Universe {
  /// The set of all directly instantiated classes, that is, classes with a
  /// generative constructor that has been called directly and not only through
  /// a super-call.
  ///
  /// Invariant: Elements are declaration elements.
  // TODO(johnniwinther): [_directlyInstantiatedClasses] and
  // [_instantiatedTypes] sets should be merged.
  final Set<ClassElement> _directlyInstantiatedClasses =
      new Set<ClassElement>();

  /// The set of all directly instantiated types, that is, the types of the
  /// directly instantiated classes.
  ///
  /// See [_directlyInstantiatedClasses].
  final Set<DartType> _instantiatedTypes = new Set<DartType>();

  /// The set of all instantiated classes, either directly, as superclasses or
  /// as supertypes.
  ///
  /// Invariant: Elements are declaration elements.
  final Set<ClassElement> _allInstantiatedClasses = new Set<ClassElement>();

  /// The set of all referenced static fields.
  ///
  /// Invariant: Elements are declaration elements.
  final Set<FieldElement> allReferencedStaticFields = new Set<FieldElement>();

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: Elements are declaration elements.
   */
  final Set<FunctionElement> staticFunctionsNeedingGetter =
      new Set<FunctionElement>();
  final Set<FunctionElement> methodsNeedingSuperGetter =
      new Set<FunctionElement>();
  final Map<String, Map<Selector, ReceiverMaskSet>> _invokedNames =
      <String, Map<Selector, ReceiverMaskSet>>{};
  final Map<String, Map<Selector, ReceiverMaskSet>> _invokedGetters =
      <String, Map<Selector, ReceiverMaskSet>>{};
  final Map<String, Map<Selector, ReceiverMaskSet>> _invokedSetters =
      <String, Map<Selector, ReceiverMaskSet>>{};

  /**
   * Fields accessed. Currently only the codegen knows this
   * information. The resolver is too conservative when seeing a
   * getter and only registers an invoked getter.
   */
  final Set<Element> fieldGetters = new Set<Element>();

  /**
   * Fields set. See comment in [fieldGetters].
   */
  final Set<Element> fieldSetters = new Set<Element>();
  final Set<DartType> isChecks = new Set<DartType>();

  /**
   * Set of (live) [:call:] methods whose signatures reference type variables.
   *
   * A live [:call:] method is one whose enclosing class has been instantiated.
   */
  final Set<Element> callMethodsWithFreeTypeVariables = new Set<Element>();

  /**
   * Set of (live) local functions (closures) whose signatures reference type
   * variables.
   *
   * A live function is one whose enclosing member function has been enqueued.
   */
  final Set<Element> closuresWithFreeTypeVariables = new Set<Element>();

  /**
   * Set of all closures in the program. Used by the mirror tracking system
   * to find all live closure instances.
   */
  final Set<LocalFunctionElement> allClosures = new Set<LocalFunctionElement>();

  /**
   * Set of methods in instantiated classes that are potentially
   * closurized.
   */
  final Set<Element> closurizedMembers = new Set<Element>();

  final ReceiverMaskStrategy receiverMaskStrategy;

  Universe(this.receiverMaskStrategy);

  /// All directly instantiated classes, that is, classes with a generative
  /// constructor that has been called directly and not only through a
  /// super-call.
  // TODO(johnniwinther): Improve semantic precision.
  Iterable<ClassElement> get directlyInstantiatedClasses {
    return _directlyInstantiatedClasses;
  }

  /// All instantiated classes, either directly, as superclasses or as
  /// supertypes.
  // TODO(johnniwinther): Improve semantic precision.
  Iterable<ClassElement> get allInstantiatedClasses {
    return _allInstantiatedClasses;
  }

  /// All directly instantiated types, that is, the types of the directly
  /// instantiated classes.
  ///
  /// See [directlyInstantiatedClasses].
  // TODO(johnniwinther): Improve semantic precision.
  Iterable<DartType> get instantiatedTypes => _instantiatedTypes;

  /// Returns `true` if [cls] is considered to be instantiated, either directly,
  /// through subclasses or through subtypes. The latter case only contains
  /// spurious information from instatiations through factory constructors and
  /// mixins.
  // TODO(johnniwinther): Improve semantic precision.
  bool isInstantiated(ClassElement cls) {
    return _allInstantiatedClasses.contains(cls);
  }

  /// Register [type] as (directly) instantiated.
  ///
  /// If [byMirrors] is `true`, the instantiation is through mirrors.
  // TODO(johnniwinther): Fully enforce the separation between exact, through
  // subclass and through subtype instantiated types/classes.
  // TODO(johnniwinther): Support unknown type arguments for generic types.
  void registerTypeInstantiation(InterfaceType type,
                                 {bool byMirrors: false}) {
    _instantiatedTypes.add(type);
    ClassElement cls = type.element;
    if (!cls.isAbstract
        // We can't use the closed-world assumption with native abstract
        // classes; a native abstract class may have non-abstract subclasses
        // not declared to the program.  Instances of these classes are
        // indistinguishable from the abstract class.
        || cls.isNative
        // Likewise, if this registration comes from the mirror system,
        // all bets are off.
        // TODO(herhut): Track classes required by mirrors seperately.
        || byMirrors) {
      _directlyInstantiatedClasses.add(cls);
    }

    // TODO(johnniwinther): Replace this by separate more specific mappings.
    if (!_allInstantiatedClasses.add(cls)) return;
    cls.allSupertypes.forEach((InterfaceType supertype) {
      _allInstantiatedClasses.add(supertype.element);
    });
  }

  bool _hasMatchingSelector(Map<Selector, ReceiverMaskSet> selectors,
                            Element member,
                            World world) {
    if (selectors == null) return false;
    for (Selector selector in selectors.keys) {
      if (selector.appliesUnnamed(member, world)) {
        ReceiverMaskSet masks = selectors[selector];
        if (masks.applies(member, selector, world)) {
          return true;
        }
      }
    }
    return false;
  }

  bool hasInvocation(Element member, World world) {
    return _hasMatchingSelector(_invokedNames[member.name], member, world);
  }

  bool hasInvokedGetter(Element member, World world) {
    return _hasMatchingSelector(_invokedGetters[member.name], member, world);
  }

  bool hasInvokedSetter(Element member, World world) {
    return _hasMatchingSelector(_invokedSetters[member.name], member, world);
  }

  bool registerInvocation(UniverseSelector selector) {
    return _registerNewSelector(selector, _invokedNames);
  }

  bool registerInvokedGetter(UniverseSelector selector) {
    return _registerNewSelector(selector, _invokedGetters);
  }

  bool registerInvokedSetter(UniverseSelector selector) {
    return _registerNewSelector(selector, _invokedSetters);
  }

  bool _registerNewSelector(
      UniverseSelector universeSelector,
      Map<String, Map<Selector, ReceiverMaskSet>> selectorMap) {
    Selector selector = universeSelector.selector;
    String name = selector.name;
    ReceiverMask mask = universeSelector.mask;
    Map<Selector, ReceiverMaskSet> selectors = selectorMap.putIfAbsent(
        name, () => new Maplet<Selector, ReceiverMaskSet>());
    UniverseReceiverMaskSet masks = selectors.putIfAbsent(
        selector, () => receiverMaskStrategy.createReceiverMaskSet(selector));
    return masks.addReceiverMask(mask);
  }

  Map<Selector, ReceiverMaskSet> _asUnmodifiable(
      Map<Selector, ReceiverMaskSet> map) {
    if (map == null) return null;
    return new UnmodifiableMapView(map);
  }

  Map<Selector, ReceiverMaskSet> invocationsByName(String name) {
    return _asUnmodifiable(_invokedNames[name]);
  }

  Map<Selector, ReceiverMaskSet> getterInvocationsByName(String name) {
    return _asUnmodifiable(_invokedGetters[name]);
  }

  Map<Selector, ReceiverMaskSet> setterInvocationsByName(String name) {
    return _asUnmodifiable(_invokedSetters[name]);
  }

  void forEachInvokedName(
      f(String name, Map<Selector, ReceiverMaskSet> selectors)) {
    _invokedNames.forEach(f);
  }

  void forEachInvokedGetter(
      f(String name, Map<Selector, ReceiverMaskSet> selectors)) {
    _invokedGetters.forEach(f);
  }

  void forEachInvokedSetter(
      f(String name, Map<Selector, ReceiverMaskSet> selectors)) {
    _invokedSetters.forEach(f);
  }

  DartType registerIsCheck(DartType type, Compiler compiler) {
    type = type.unalias(compiler);
    // Even in checked mode, type annotations for return type and argument
    // types do not imply type checks, so there should never be a check
    // against the type variable of a typedef.
    isChecks.add(type);
    return type;
  }

  void registerStaticFieldUse(FieldElement staticField) {
    assert(Elements.isStaticOrTopLevel(staticField) && staticField.isField);
    assert(staticField.isDeclaration);

    allReferencedStaticFields.add(staticField);
  }

  void forgetElement(Element element, Compiler compiler) {
    allClosures.remove(element);
    slowDirectlyNestedClosures(element).forEach(compiler.forgetElement);
    closurizedMembers.remove(element);
    fieldSetters.remove(element);
    fieldGetters.remove(element);
    _directlyInstantiatedClasses.remove(element);
    _allInstantiatedClasses.remove(element);
    if (element is ClassElement) {
      assert(invariant(
          element, element.thisType.isRaw,
          message: 'Generic classes not supported (${element.thisType}).'));
      _instantiatedTypes
          ..remove(element.rawType)
          ..remove(element.thisType);
    }
  }

  // TODO(ahe): Replace this method with something that is O(1), for example,
  // by using a map.
  List<LocalFunctionElement> slowDirectlyNestedClosures(Element element) {
    // Return new list to guard against concurrent modifications.
    return new List<LocalFunctionElement>.from(
        allClosures.where((LocalFunctionElement closure) {
          return closure.executableContext == element;
        }));
  }
}
