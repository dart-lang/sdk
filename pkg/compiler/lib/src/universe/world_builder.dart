// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library universe;

import 'dart:collection';

import '../cache_strategy.dart';
import '../common.dart';
import '../common/backend_api.dart' show Backend;
import '../common/resolution.dart' show Resolution;
import '../compiler.dart' show Compiler;
import '../core_types.dart' show CoreClasses;
import '../dart_types.dart';
import '../elements/elements.dart';
import '../universe/class_set.dart' show Instantiation;
import '../util/util.dart';
import '../world.dart' show World, ClosedWorld, OpenWorld, WorldImpl;
import 'selector.dart' show Selector;
import 'use.dart' show DynamicUse, DynamicUseKind, StaticUse, StaticUseKind;

/// The known constraint on receiver for a dynamic call site.
///
/// This can for instance be used to constrain this dynamic call to `foo` to
/// 'receivers of the exact instance `Bar`':
///
///     class Bar {
///        void foo() {}
///     }
///     main() => new Bar().foo();
///
abstract class ReceiverConstraint {
  /// Returns whether [element] is a potential target when being
  /// invoked on a receiver with this constraint. [selector] is used to ensure
  /// library privacy is taken into account.
  bool canHit(Element element, Selector selector, World world);

  /// Returns whether this [TypeMask] applied to [selector] can hit a
  /// [noSuchMethod].
  bool needsNoSuchMethodHandling(Selector selector, World world);
}

/// The combined constraints on receivers all the dynamic call sites of the same
/// selector.
///
/// For instance for these calls
///
///     class A {
///        foo(a, b) {}
///     }
///     class B {
///        foo(a, b) {}
///     }
///     class C {
///        foo(a, b) {}
///     }
///     new A().foo(a, b);
///     new B().foo(0, 42);
///
/// the selector constraints for dynamic calls to 'foo' with two positional
/// arguments could be 'receiver of exact instance `A` or `B`'.
abstract class SelectorConstraints {
  /// Returns `true` if [selector] applies to [element] under these constraints
  /// given the closed [world].
  ///
  /// Consider for instance in this world:
  ///
  ///     class A {
  ///        foo(a, b) {}
  ///     }
  ///     class B {
  ///        foo(a, b) {}
  ///     }
  ///     new A().foo(a, b);
  ///
  /// Ideally the selector constraints for calls `foo` with two positional
  /// arguments apply to `A.foo` but `B.foo`.
  bool applies(Element element, Selector selector, World world);

  /// Returns `true` if at least one of the receivers matching these constraints
  /// in the closed [world] have no implementation matching [selector].
  ///
  /// For instance for this code snippet
  ///
  ///     class A {}
  ///     class B { foo() {} }
  ///     m(b) => (b ? new A() : new B()).foo();
  ///
  /// the potential receiver `new A()` has no implementation of `foo` and thus
  /// needs to handle the call through its `noSuchMethod` handler.
  bool needsNoSuchMethodHandling(Selector selector, World world);
}

/// A mutable [SelectorConstraints] used in [WorldBuilder].
abstract class UniverseSelectorConstraints extends SelectorConstraints {
  /// Adds [constraint] to these selector constraints. Return `true` if the set
  /// of potential receivers expanded due to the new constraint.
  bool addReceiverConstraint(ReceiverConstraint constraint);
}

/// Strategy for computing the constraints on potential receivers of dynamic
/// call sites.
abstract class SelectorConstraintsStrategy {
  /// Create a [UniverseSelectorConstraints] to represent the global receiver
  /// constraints for dynamic call sites with [selector].
  UniverseSelectorConstraints createSelectorConstraints(Selector selector);
}

/// The [WorldBuilder] is an auxiliary class used in the process of computing
/// the [ClosedWorld].
// TODO(johnniwinther): Move common implementation to a [WorldBuilderBase] when
// universes and worlds have been unified.
abstract class WorldBuilder {
  /// All directly instantiated classes, that is, classes with a generative
  /// constructor that has been called directly and not only through a
  /// super-call.
  // TODO(johnniwinther): Improve semantic precision.
  Iterable<ClassElement> get directlyInstantiatedClasses;

  /// All types that are checked either through is, as or checked mode checks.
  Iterable<DartType> get isChecks;

  /// Registers that [type] is checked in this universe. The unaliased type is
  /// returned.
  DartType registerIsCheck(DartType type, Resolution resolution);

  /// All directly instantiated types, that is, the types of the directly
  /// instantiated classes.
  // TODO(johnniwinther): Improve semantic precision.
  Iterable<DartType> get instantiatedTypes;

  /// Returns `true` if [member] is invoked as a setter.
  bool hasInvokedSetter(Element member, World world);
}

abstract class ResolutionWorldBuilder implements WorldBuilder {
  /// Set of (live) local functions (closures) whose signatures reference type
  /// variables.
  ///
  /// A live function is one whose enclosing member function has been enqueued.
  Set<Element> get closuresWithFreeTypeVariables;

  /// Set of (live) `call` methods whose signatures reference type variables.
  ///
  /// A live `call` method is one whose enclosing class has been instantiated.
  Iterable<Element> get callMethodsWithFreeTypeVariables;

  /// Set of all closures in the program. Used by the mirror tracking system
  /// to find all live closure instances.
  Iterable<LocalFunctionElement> get allClosures;

  /// Set of methods in instantiated classes that are potentially closurized.
  Iterable<Element> get closurizedMembers;

  /// Returns `true` if [cls] is considered to be implemented by an
  /// instantiated class, either directly, through subclasses or through
  /// subtypes. The latter case only contains spurious information from
  /// instantiations through factory constructors and mixins.
  bool isImplemented(ClassElement cls);

  /// Set of all fields that are statically known to be written to.
  Iterable<Element> get fieldSetters;

  /// Call [f] for all classes with instantiated types. This includes the
  /// directly and abstractly instantiated classes but also classes whose type
  /// arguments are used in live factory constructors.
  void forEachInstantiatedClass(f(ClassElement cls, InstantiationInfo info));

  /// `true` of `Object.runtimeType` is supported.
  bool get hasRuntimeTypeSupport;

  /// `true` of use of the `dart:isolate` library is supported.
  bool get hasIsolateSupport;

  /// `true` of `Function.apply` is supported.
  bool get hasFunctionApplySupport;

  /// The [OpenWorld] being created by this world builder.
  // TODO(johnniwinther): Merge this with [ResolutionWorldBuilder].
  OpenWorld get openWorld;
}

/// The type and kind of an instantiation registered through
/// `ResolutionWorldBuilder.registerTypeInstantiation`.
class Instance {
  final InterfaceType type;
  final Instantiation kind;
  final bool isRedirection;

  Instance(this.type, this.kind, {this.isRedirection: false});

  int get hashCode {
    return Hashing.objectHash(
        type, Hashing.objectHash(kind, Hashing.objectHash(isRedirection)));
  }

  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! Instance) return false;
    return type == other.type &&
        kind == other.kind &&
        isRedirection == other.isRedirection;
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write(type);
    if (kind == Instantiation.DIRECTLY_INSTANTIATED) {
      sb.write(' directly');
    } else if (kind == Instantiation.ABSTRACTLY_INSTANTIATED) {
      sb.write(' abstractly');
    } else if (kind == Instantiation.UNINSTANTIATED) {
      sb.write(' none');
    }
    if (isRedirection) {
      sb.write(' redirect');
    }
    return sb.toString();
  }
}

/// Information about instantiations of a class.
class InstantiationInfo {
  /// A map from constructor of the class to their instantiated types.
  ///
  /// For instance
  ///
  ///    import 'dart:html';
  ///
  ///    abstract class AbstractClass<S> {
  ///      factory AbstractClass.a() = Class<S>.a;
  ///      factory AbstractClass.b() => new Class<S>.b();
  ///    }
  ///    class Class<T> implements AbstractClass<T> {
  ///      Class.a();
  ///      Class.b();
  ///      factory Class.c() = Class.b<T>;
  ///    }
  ///
  ///
  ///    main() {
  ///      new Class.a();
  ///      new Class<int>.a();
  ///      new Class<String>.b();
  ///      new Class<num>.c();
  ///      new AbstractClass<double>.a();
  ///      new AbstractClass<bool>.b();
  ///      new DivElement(); // native instantiation
  ///    }
  ///
  /// will generate the mappings
  ///
  ///    AbstractClass: {
  ///      AbstractClass.a: {
  ///        AbstractClass<double> none, // from `new AbstractClass<double>.a()`
  ///      },
  ///      AbstractClass.b: {
  ///        AbstractClass<bool> none, // from `new AbstractClass<bool>.b()`
  ///      },
  ///    },
  ///    Class: {
  ///      Class.a: {
  ///        Class directly, // from `new Class.a()`
  ///        Class<int> directly, // from `new Class<int>.a()`
  ///        Class<S> directly redirect, // from `factory AbstractClass.a`
  ///      },
  ///      Class.b: {
  ///        Class<String> directly, // from `new Class<String>.b()`
  ///        Class<T> directly redirect, // from `factory Class.c`
  ///        Class<S> directly, // from `factory AbstractClass.b`
  ///      },
  ///      Class.c: {
  ///        Class<num> directly, // from `new Class<num>.c()`
  ///      },
  ///    },
  ///    DivElement: {
  ///      DivElement: {
  ///        DivElement abstractly, // from `new DivElement()`
  ///      },
  ///    }
  ///
  /// If the constructor is unknown, for instance for native or mirror usage,
  /// `null` is used as key.
  Map<ConstructorElement, Set<Instance>> instantiationMap;

  /// Register [type] as the instantiation [kind] using [constructor].
  void addInstantiation(
      ConstructorElement constructor, InterfaceType type, Instantiation kind,
      {bool isRedirection: false}) {
    instantiationMap ??= <ConstructorElement, Set<Instance>>{};
    instantiationMap
        .putIfAbsent(constructor, () => new Set<Instance>())
        .add(new Instance(type, kind, isRedirection: isRedirection));
    switch (kind) {
      case Instantiation.DIRECTLY_INSTANTIATED:
        isDirectlyInstantiated = true;
        break;
      case Instantiation.ABSTRACTLY_INSTANTIATED:
        isAbstractlyInstantiated = true;
        break;
      case Instantiation.UNINSTANTIATED:
        break;
      default:
        throw new StateError("Instantiation $kind is not allowed.");
    }
  }

  /// `true` if the class is either directly or abstractly instantiated.
  bool get hasInstantiation =>
      isDirectlyInstantiated || isAbstractlyInstantiated;

  /// `true` if the class is directly instantiated.
  bool isDirectlyInstantiated = false;

  /// `true` if the class is abstractly instantiated.
  bool isAbstractlyInstantiated = false;

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('InstantiationInfo[');
    if (instantiationMap != null) {
      bool needsComma = false;
      instantiationMap
          .forEach((ConstructorElement constructor, Set<Instance> set) {
        if (needsComma) {
          sb.write(', ');
        }
        if (constructor != null) {
          sb.write(constructor);
        } else {
          sb.write('<unknown>');
        }
        sb.write(': ');
        sb.write(set);
        needsComma = true;
      });
    }
    sb.write(']');
    return sb.toString();
  }
}

class ResolutionWorldBuilderImpl implements ResolutionWorldBuilder {
  /// Instantiation information for all classes with instantiated types.
  ///
  /// Invariant: Elements are declaration elements.
  final Map<ClassElement, InstantiationInfo> _instantiationInfo =
      <ClassElement, InstantiationInfo>{};

  /// Classes implemented by directly instantiated classes.
  final Set<ClassElement> _implementedClasses = new Set<ClassElement>();

  /// The set of all referenced static fields.
  ///
  /// Invariant: Elements are declaration elements.
  final Set<FieldElement> allReferencedStaticFields = new Set<FieldElement>();

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: Elements are declaration elements.
   */
  final Set<FunctionElement> methodsNeedingSuperGetter =
      new Set<FunctionElement>();
  final Map<String, Map<Selector, SelectorConstraints>> _invokedNames =
      <String, Map<Selector, SelectorConstraints>>{};
  final Map<String, Map<Selector, SelectorConstraints>> _invokedGetters =
      <String, Map<Selector, SelectorConstraints>>{};
  final Map<String, Map<Selector, SelectorConstraints>> _invokedSetters =
      <String, Map<Selector, SelectorConstraints>>{};

  /// Fields set.
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

  final SelectorConstraintsStrategy selectorConstraintsStrategy;

  bool hasRuntimeTypeSupport = false;
  bool hasIsolateSupport = false;
  bool hasFunctionApplySupport = false;

  /// Used for testing the new more precise computation of instantiated types
  /// and classes.
  bool useInstantiationMap = false;

  OpenWorld _openWorld;

  ResolutionWorldBuilderImpl(Backend backend, CoreClasses coreClasses,
      CacheStrategy cacheStrategy, this.selectorConstraintsStrategy) {
    _openWorld = new WorldImpl(this, backend, coreClasses, cacheStrategy);
  }

  OpenWorld get openWorld => _openWorld;

  /// All directly instantiated classes, that is, classes with a generative
  /// constructor that has been called directly and not only through a
  /// super-call.
  // TODO(johnniwinther): Improve semantic precision.
  Iterable<ClassElement> get directlyInstantiatedClasses {
    Set<ClassElement> classes = new Set<ClassElement>();
    getInstantiationMap().forEach((ClassElement cls, InstantiationInfo info) {
      if (info.hasInstantiation) {
        classes.add(cls);
      }
    });
    return classes;
  }

  /// All directly instantiated types, that is, the types of the directly
  /// instantiated classes.
  ///
  /// See [directlyInstantiatedClasses].
  // TODO(johnniwinther): Improve semantic precision.
  Iterable<DartType> get instantiatedTypes {
    Set<InterfaceType> types = new Set<InterfaceType>();
    getInstantiationMap().forEach((_, InstantiationInfo info) {
      if (info.instantiationMap != null) {
        for (Set<Instance> instances in info.instantiationMap.values) {
          for (Instance instance in instances) {
            types.add(instance.type);
          }
        }
      }
    });
    return types;
  }

  /// Returns `true` if [cls] is considered to be implemented by an
  /// instantiated class, either directly, through subclasses or through
  /// subtypes. The latter case only contains spurious information from
  /// instantiations through factory constructors and mixins.
  // TODO(johnniwinther): Improve semantic precision.
  bool isImplemented(ClassElement cls) {
    return _implementedClasses.contains(cls.declaration);
  }

  /// Register [type] as (directly) instantiated.
  ///
  /// If [byMirrors] is `true`, the instantiation is through mirrors.
  // TODO(johnniwinther): Fully enforce the separation between exact, through
  // subclass and through subtype instantiated types/classes.
  // TODO(johnniwinther): Support unknown type arguments for generic types.
  void registerTypeInstantiation(InterfaceType type,
      {ConstructorElement constructor,
      bool byMirrors: false,
      bool isNative: false,
      bool isRedirection: false,
      void onImplemented(ClassElement cls)}) {
    ClassElement cls = type.element;
    InstantiationInfo info =
        _instantiationInfo.putIfAbsent(cls, () => new InstantiationInfo());
    Instantiation kind = Instantiation.UNINSTANTIATED;
    if (!cls.isAbstract
        // We can't use the closed-world assumption with native abstract
        // classes; a native abstract class may have non-abstract subclasses
        // not declared to the program.  Instances of these classes are
        // indistinguishable from the abstract class.
        ||
        isNative
        // Likewise, if this registration comes from the mirror system,
        // all bets are off.
        // TODO(herhut): Track classes required by mirrors seperately.
        ||
        byMirrors) {
      if (isNative || byMirrors) {
        kind = Instantiation.ABSTRACTLY_INSTANTIATED;
      } else {
        kind = Instantiation.DIRECTLY_INSTANTIATED;
      }
    }
    info.addInstantiation(constructor, type, kind,
        isRedirection: isRedirection);

    // TODO(johnniwinther): Use [_instantiationInfo] to compute this information
    // instead.
    if (_implementedClasses.add(cls)) {
      onImplemented(cls);
      cls.allSupertypes.forEach((InterfaceType supertype) {
        if (_implementedClasses.add(supertype.element)) {
          onImplemented(supertype.element);
        }
      });
    }
  }

  @override
  void forEachInstantiatedClass(f(ClassElement cls, InstantiationInfo info)) {
    getInstantiationMap().forEach(f);
  }

  bool _hasMatchingSelector(Map<Selector, SelectorConstraints> selectors,
      Element member, OpenWorld world) {
    if (selectors == null) return false;
    for (Selector selector in selectors.keys) {
      if (selector.appliesUnnamed(member)) {
        SelectorConstraints masks = selectors[selector];
        if (masks.applies(member, selector, world)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Returns the instantiation map used for computing the closed world.
  ///
  /// If [useInstantiationMap] is `true`, redirections are removed and
  /// redirecting factories are converted to their effective target and type.
  Map<ClassElement, InstantiationInfo> getInstantiationMap() {
    if (!useInstantiationMap) return _instantiationInfo;

    Map<ClassElement, InstantiationInfo> instantiationMap =
        <ClassElement, InstantiationInfo>{};

    InstantiationInfo infoFor(ClassElement cls) {
      return instantiationMap.putIfAbsent(cls, () => new InstantiationInfo());
    }

    _instantiationInfo.forEach((cls, info) {
      if (info.instantiationMap != null) {
        info.instantiationMap
            .forEach((ConstructorElement constructor, Set<Instance> set) {
          for (Instance instance in set) {
            if (instance.isRedirection) {
              continue;
            }
            if (constructor == null || !constructor.isRedirectingFactory) {
              infoFor(cls)
                  .addInstantiation(constructor, instance.type, instance.kind);
            } else {
              ConstructorElement target = constructor.effectiveTarget;
              InterfaceType targetType =
                  constructor.computeEffectiveTargetType(instance.type);
              Instantiation kind = Instantiation.DIRECTLY_INSTANTIATED;
              if (target.enclosingClass.isAbstract) {
                // If target is a factory constructor on an abstract class.
                kind = Instantiation.UNINSTANTIATED;
              }
              infoFor(targetType.element)
                  .addInstantiation(target, targetType, kind);
            }
          }
        });
      }
    });
    return instantiationMap;
  }

  bool hasInvocation(Element member, OpenWorld world) {
    return _hasMatchingSelector(_invokedNames[member.name], member, world);
  }

  bool hasInvokedGetter(Element member, OpenWorld world) {
    return _hasMatchingSelector(_invokedGetters[member.name], member, world) ||
        member.isFunction && methodsNeedingSuperGetter.contains(member);
  }

  bool hasInvokedSetter(Element member, OpenWorld world) {
    return _hasMatchingSelector(_invokedSetters[member.name], member, world);
  }

  bool registerDynamicUse(DynamicUse dynamicUse) {
    switch (dynamicUse.kind) {
      case DynamicUseKind.INVOKE:
        return _registerNewSelector(dynamicUse, _invokedNames);
      case DynamicUseKind.GET:
        return _registerNewSelector(dynamicUse, _invokedGetters);
      case DynamicUseKind.SET:
        return _registerNewSelector(dynamicUse, _invokedSetters);
    }
  }

  bool _registerNewSelector(DynamicUse dynamicUse,
      Map<String, Map<Selector, SelectorConstraints>> selectorMap) {
    Selector selector = dynamicUse.selector;
    String name = selector.name;
    ReceiverConstraint mask = dynamicUse.mask;
    Map<Selector, SelectorConstraints> selectors = selectorMap.putIfAbsent(
        name, () => new Maplet<Selector, SelectorConstraints>());
    UniverseSelectorConstraints constraints =
        selectors.putIfAbsent(selector, () {
      return selectorConstraintsStrategy.createSelectorConstraints(selector);
    });
    return constraints.addReceiverConstraint(mask);
  }

  DartType registerIsCheck(DartType type, Resolution resolution) {
    type.computeUnaliased(resolution);
    type = type.unaliased;
    // Even in checked mode, type annotations for return type and argument
    // types do not imply type checks, so there should never be a check
    // against the type variable of a typedef.
    isChecks.add(type);
    return type;
  }

  void registerStaticUse(StaticUse staticUse) {
    Element element = staticUse.element;
    if (Elements.isStaticOrTopLevel(element) && element.isField) {
      allReferencedStaticFields.add(element);
    }
    switch (staticUse.kind) {
      case StaticUseKind.SUPER_FIELD_SET:
      case StaticUseKind.FIELD_SET:
        fieldSetters.add(element);
        break;
      case StaticUseKind.SUPER_TEAR_OFF:
        methodsNeedingSuperGetter.add(element);
        break;
      case StaticUseKind.GENERAL:
      case StaticUseKind.DIRECT_USE:
      case StaticUseKind.STATIC_TEAR_OFF:
      case StaticUseKind.FIELD_GET:
      case StaticUseKind.CONSTRUCTOR_INVOKE:
      case StaticUseKind.CONST_CONSTRUCTOR_INVOKE:
      case StaticUseKind.REDIRECTION:
        break;
      case StaticUseKind.CLOSURE:
        allClosures.add(element);
        break;
      case StaticUseKind.DIRECT_INVOKE:
        invariant(
            element, 'Direct static use is not supported for resolution.');
        break;
    }
  }

  void forgetElement(Element element, Compiler compiler) {
    allClosures.remove(element);
    slowDirectlyNestedClosures(element).forEach(compiler.forgetElement);
    closurizedMembers.remove(element);
    fieldSetters.remove(element);
    _instantiationInfo.remove(element);
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

/// World builder specific to codegen.
///
/// This adds additional access to liveness of selectors and elements.
abstract class CodegenWorldBuilder implements WorldBuilder {
  void forEachInvokedName(
      f(String name, Map<Selector, SelectorConstraints> selectors));

  void forEachInvokedGetter(
      f(String name, Map<Selector, SelectorConstraints> selectors));

  void forEachInvokedSetter(
      f(String name, Map<Selector, SelectorConstraints> selectors));

  bool hasInvokedGetter(Element member, ClosedWorld world);

  Map<Selector, SelectorConstraints> invocationsByName(String name);

  Map<Selector, SelectorConstraints> getterInvocationsByName(String name);

  Map<Selector, SelectorConstraints> setterInvocationsByName(String name);

  Iterable<FunctionElement> get staticFunctionsNeedingGetter;
  Iterable<FunctionElement> get methodsNeedingSuperGetter;

  /// The set of all referenced static fields.
  ///
  /// Invariant: Elements are declaration elements.
  Iterable<FieldElement> get allReferencedStaticFields;
}

class CodegenWorldBuilderImpl implements CodegenWorldBuilder {
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

  /// Classes implemented by directly instantiated classes.
  final Set<ClassElement> _implementedClasses = new Set<ClassElement>();

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
  final Map<String, Map<Selector, SelectorConstraints>> _invokedNames =
      <String, Map<Selector, SelectorConstraints>>{};
  final Map<String, Map<Selector, SelectorConstraints>> _invokedGetters =
      <String, Map<Selector, SelectorConstraints>>{};
  final Map<String, Map<Selector, SelectorConstraints>> _invokedSetters =
      <String, Map<Selector, SelectorConstraints>>{};

  final Set<DartType> isChecks = new Set<DartType>();

  final SelectorConstraintsStrategy selectorConstraintsStrategy;

  CodegenWorldBuilderImpl(this.selectorConstraintsStrategy);

  /// All directly instantiated classes, that is, classes with a generative
  /// constructor that has been called directly and not only through a
  /// super-call.
  // TODO(johnniwinther): Improve semantic precision.
  Iterable<ClassElement> get directlyInstantiatedClasses {
    return _directlyInstantiatedClasses;
  }

  /// All directly instantiated types, that is, the types of the directly
  /// instantiated classes.
  ///
  /// See [directlyInstantiatedClasses].
  // TODO(johnniwinther): Improve semantic precision.
  Iterable<DartType> get instantiatedTypes => _instantiatedTypes;

  /// Register [type] as (directly) instantiated.
  ///
  /// If [byMirrors] is `true`, the instantiation is through mirrors.
  // TODO(johnniwinther): Fully enforce the separation between exact, through
  // subclass and through subtype instantiated types/classes.
  // TODO(johnniwinther): Support unknown type arguments for generic types.
  void registerTypeInstantiation(InterfaceType type,
      {bool byMirrors: false,
      bool isNative: false,
      void onImplemented(ClassElement cls)}) {
    _instantiatedTypes.add(type);
    ClassElement cls = type.element;
    if (!cls.isAbstract
        // We can't use the closed-world assumption with native abstract
        // classes; a native abstract class may have non-abstract subclasses
        // not declared to the program.  Instances of these classes are
        // indistinguishable from the abstract class.
        ||
        isNative
        // Likewise, if this registration comes from the mirror system,
        // all bets are off.
        // TODO(herhut): Track classes required by mirrors separately.
        ||
        byMirrors) {
      _directlyInstantiatedClasses.add(cls);
    }

    // TODO(johnniwinther): Replace this by separate more specific mappings that
    // include the type arguments.
    if (_implementedClasses.add(cls)) {
      onImplemented(cls);
      cls.allSupertypes.forEach((InterfaceType supertype) {
        if (_implementedClasses.add(supertype.element)) {
          onImplemented(supertype.element);
        }
      });
    }
  }

  bool _hasMatchingSelector(Map<Selector, SelectorConstraints> selectors,
      Element member, ClosedWorld world) {
    if (selectors == null) return false;
    for (Selector selector in selectors.keys) {
      if (selector.appliesUnnamed(member)) {
        SelectorConstraints masks = selectors[selector];
        if (masks.applies(member, selector, world)) {
          return true;
        }
      }
    }
    return false;
  }

  bool hasInvocation(Element member, ClosedWorld world) {
    return _hasMatchingSelector(_invokedNames[member.name], member, world);
  }

  bool hasInvokedGetter(Element member, ClosedWorld world) {
    return _hasMatchingSelector(_invokedGetters[member.name], member, world) ||
        member.isFunction && methodsNeedingSuperGetter.contains(member);
  }

  bool hasInvokedSetter(Element member, ClosedWorld world) {
    return _hasMatchingSelector(_invokedSetters[member.name], member, world);
  }

  bool registerDynamicUse(DynamicUse dynamicUse) {
    switch (dynamicUse.kind) {
      case DynamicUseKind.INVOKE:
        return _registerNewSelector(dynamicUse, _invokedNames);
      case DynamicUseKind.GET:
        return _registerNewSelector(dynamicUse, _invokedGetters);
      case DynamicUseKind.SET:
        return _registerNewSelector(dynamicUse, _invokedSetters);
    }
  }

  bool _registerNewSelector(DynamicUse dynamicUse,
      Map<String, Map<Selector, SelectorConstraints>> selectorMap) {
    Selector selector = dynamicUse.selector;
    String name = selector.name;
    ReceiverConstraint mask = dynamicUse.mask;
    Map<Selector, SelectorConstraints> selectors = selectorMap.putIfAbsent(
        name, () => new Maplet<Selector, SelectorConstraints>());
    UniverseSelectorConstraints constraints =
        selectors.putIfAbsent(selector, () {
      return selectorConstraintsStrategy.createSelectorConstraints(selector);
    });
    return constraints.addReceiverConstraint(mask);
  }

  Map<Selector, SelectorConstraints> _asUnmodifiable(
      Map<Selector, SelectorConstraints> map) {
    if (map == null) return null;
    return new UnmodifiableMapView(map);
  }

  Map<Selector, SelectorConstraints> invocationsByName(String name) {
    return _asUnmodifiable(_invokedNames[name]);
  }

  Map<Selector, SelectorConstraints> getterInvocationsByName(String name) {
    return _asUnmodifiable(_invokedGetters[name]);
  }

  Map<Selector, SelectorConstraints> setterInvocationsByName(String name) {
    return _asUnmodifiable(_invokedSetters[name]);
  }

  void forEachInvokedName(
      f(String name, Map<Selector, SelectorConstraints> selectors)) {
    _invokedNames.forEach(f);
  }

  void forEachInvokedGetter(
      f(String name, Map<Selector, SelectorConstraints> selectors)) {
    _invokedGetters.forEach(f);
  }

  void forEachInvokedSetter(
      f(String name, Map<Selector, SelectorConstraints> selectors)) {
    _invokedSetters.forEach(f);
  }

  DartType registerIsCheck(DartType type, Resolution resolution) {
    type = type.unaliased;
    // Even in checked mode, type annotations for return type and argument
    // types do not imply type checks, so there should never be a check
    // against the type variable of a typedef.
    isChecks.add(type);
    return type;
  }

  void registerStaticUse(StaticUse staticUse) {
    Element element = staticUse.element;
    if (Elements.isStaticOrTopLevel(element) && element.isField) {
      allReferencedStaticFields.add(element);
    }
    switch (staticUse.kind) {
      case StaticUseKind.STATIC_TEAR_OFF:
        staticFunctionsNeedingGetter.add(element);
        break;
      case StaticUseKind.SUPER_TEAR_OFF:
        methodsNeedingSuperGetter.add(element);
        break;
      case StaticUseKind.SUPER_FIELD_SET:
      case StaticUseKind.FIELD_SET:
      case StaticUseKind.GENERAL:
      case StaticUseKind.DIRECT_USE:
      case StaticUseKind.CLOSURE:
      case StaticUseKind.FIELD_GET:
      case StaticUseKind.CONSTRUCTOR_INVOKE:
      case StaticUseKind.CONST_CONSTRUCTOR_INVOKE:
      case StaticUseKind.REDIRECTION:
      case StaticUseKind.DIRECT_INVOKE:
        break;
    }
  }

  void forgetElement(Element element, Compiler compiler) {
    _directlyInstantiatedClasses.remove(element);
    if (element is ClassElement) {
      assert(invariant(element, element.thisType.isRaw,
          message: 'Generic classes not supported (${element.thisType}).'));
      _instantiatedTypes..remove(element.rawType)..remove(element.thisType);
    }
  }
}
