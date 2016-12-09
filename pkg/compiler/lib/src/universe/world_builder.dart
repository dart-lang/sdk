// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library universe;

import 'dart:collection';

import '../cache_strategy.dart';
import '../common.dart';
import '../common/backend_api.dart' show Backend;
import '../common/names.dart' show Identifiers;
import '../common/resolution.dart' show Resolution;
import '../compiler.dart' show Compiler;
import '../dart_types.dart';
import '../elements/elements.dart';
import '../elements/entities.dart';
import '../universe/class_set.dart' show Instantiation;
import '../util/enumset.dart';
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
}

abstract class ResolutionWorldBuilder implements WorldBuilder {
  /// Set of (live) local functions (closures) whose signatures reference type
  /// variables.
  ///
  /// A live function is one whose enclosing member function has been enqueued.
  Iterable<Element> get closuresWithFreeTypeVariables;

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

  /// Returns `true` if [member] is invoked as a setter.
  bool hasInvokedSetter(Element member);

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

  final Map<ClassElement, _ClassUsage> _processedClasses =
      <ClassElement, _ClassUsage>{};

  /// Map of registered usage of static members of live classes.
  final Map<Entity, _StaticMemberUsage> _staticMemberUsage =
      <Entity, _StaticMemberUsage>{};

  /// Map of registered usage of instance members of live classes.
  final Map<MemberEntity, _MemberUsage> _instanceMemberUsage =
      <MemberEntity, _MemberUsage>{};

  /// Map containing instance members of live classes that are not yet live
  /// themselves.
  final Map<String, Set<_MemberUsage>> _instanceMembersByName =
      <String, Set<_MemberUsage>>{};

  /// Map containing instance methods of live classes that are not yet
  /// closurized.
  final Map<String, Set<_MemberUsage>> _instanceFunctionsByName =
      <String, Set<_MemberUsage>>{};

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

  final Backend _backend;
  final Resolution _resolution;

  ResolutionWorldBuilderImpl(Backend backend, Resolution resolution,
      CacheStrategy cacheStrategy, this.selectorConstraintsStrategy)
      : this._backend = backend,
        this._resolution = resolution {
    _openWorld =
        new WorldImpl(this, backend, resolution.coreClasses, cacheStrategy);
  }

  Iterable<ClassElement> get processedClasses => _processedClasses.keys
      .where((cls) => _processedClasses[cls].isInstantiated);

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
  void registerTypeInstantiation(
      InterfaceType type, ClassUsedCallback classUsed,
      {ConstructorElement constructor,
      bool byMirrors: false,
      bool isRedirection: false}) {
    ClassElement cls = type.element;
    cls.ensureResolved(_resolution);
    InstantiationInfo info =
        _instantiationInfo.putIfAbsent(cls, () => new InstantiationInfo());
    Instantiation kind = Instantiation.UNINSTANTIATED;
    bool isNative = _backend.isNative(cls);
    if (!cls.isAbstract ||
        // We can't use the closed-world assumption with native abstract
        // classes; a native abstract class may have non-abstract subclasses
        // not declared to the program.  Instances of these classes are
        // indistinguishable from the abstract class.
        isNative ||
        // Likewise, if this registration comes from the mirror system,
        // all bets are off.
        // TODO(herhut): Track classes required by mirrors seperately.
        byMirrors) {
      if (isNative || byMirrors) {
        kind = Instantiation.ABSTRACTLY_INSTANTIATED;
      } else {
        kind = Instantiation.DIRECTLY_INSTANTIATED;
      }
      _processInstantiatedClass(cls, classUsed);
    }
    info.addInstantiation(constructor, type, kind,
        isRedirection: isRedirection);

    // TODO(johnniwinther): Use [_instantiationInfo] to compute this information
    // instead.
    if (_implementedClasses.add(cls)) {
      void onImplemented(ClassElement cls) {
        _ClassUsage usage = _getClassUsage(cls);
        classUsed(usage.cls, usage.implement());
      }

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

  bool _hasMatchingSelector(
      Map<Selector, SelectorConstraints> selectors, Element member) {
    if (selectors == null) return false;
    for (Selector selector in selectors.keys) {
      if (selector.appliesUnnamed(member)) {
        SelectorConstraints masks = selectors[selector];
        if (masks.applies(member, selector, _openWorld)) {
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

  bool _hasInvocation(Element member) {
    return _hasMatchingSelector(_invokedNames[member.name], member);
  }

  bool _hasInvokedGetter(Element member) {
    return _hasMatchingSelector(_invokedGetters[member.name], member) ||
        member.isFunction && methodsNeedingSuperGetter.contains(member);
  }

  bool hasInvokedSetter(Element member) {
    return _hasMatchingSelector(_invokedSetters[member.name], member);
  }

  void registerDynamicUse(
      DynamicUse dynamicUse, MemberUsedCallback memberUsed) {
    Selector selector = dynamicUse.selector;
    String methodName = selector.name;
    switch (dynamicUse.kind) {
      case DynamicUseKind.INVOKE:
        if (_registerNewSelector(dynamicUse, _invokedNames)) {
          _processInstanceMembers(methodName, (_MemberUsage usage) {
            if (dynamicUse.appliesUnnamed(usage.entity, _openWorld)) {
              memberUsed(usage.entity, usage.invoke());
              return true;
            }
            return false;
          });
        }
        break;
      case DynamicUseKind.GET:
        if (_registerNewSelector(dynamicUse, _invokedGetters)) {
          _processInstanceMembers(methodName, (_MemberUsage usage) {
            if (dynamicUse.appliesUnnamed(usage.entity, _openWorld)) {
              memberUsed(usage.entity, usage.read());
              return true;
            }
            return false;
          });
          _processInstanceFunctions(methodName, (_MemberUsage usage) {
            if (dynamicUse.appliesUnnamed(usage.entity, _openWorld)) {
              memberUsed(usage.entity, usage.read());
              return true;
            }
            return false;
          });
        }
        break;
      case DynamicUseKind.SET:
        if (_registerNewSelector(dynamicUse, _invokedSetters)) {
          _processInstanceMembers(methodName, (_MemberUsage usage) {
            if (dynamicUse.appliesUnnamed(usage.entity, _openWorld)) {
              memberUsed(usage.entity, usage.write());
              return true;
            }
            return false;
          });
        }
        break;
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

  void registerStaticUse(StaticUse staticUse, MemberUsedCallback memberUsed) {
    Element element = staticUse.element;
    assert(invariant(element, element.isDeclaration,
        message: "Element ${element} is not the declaration."));
    _StaticMemberUsage usage = _staticMemberUsage.putIfAbsent(element, () {
      if ((element.isStatic || element.isTopLevel) && element.isFunction) {
        return new _StaticFunctionUsage(element);
      } else {
        return new _GeneralStaticMemberUsage(element);
      }
    });
    EnumSet<MemberUse> useSet = new EnumSet<MemberUse>();

    if (Elements.isStaticOrTopLevel(element) && element.isField) {
      allReferencedStaticFields.add(element);
    }
    // TODO(johnniwinther): Avoid this. Currently [FIELD_GET] and
    // [FIELD_SET] contains [BoxFieldElement]s which we cannot enqueue.
    // Also [CLOSURE] contains [LocalFunctionElement] which we cannot
    // enqueue.
    switch (staticUse.kind) {
      case StaticUseKind.FIELD_GET:
        break;
      case StaticUseKind.FIELD_SET:
        fieldSetters.add(element);
        break;
      case StaticUseKind.CLOSURE:
        LocalFunctionElement closure = staticUse.element;
        if (closure.type.containsTypeVariables) {
          closuresWithFreeTypeVariables.add(closure);
        }
        allClosures.add(element);
        break;
      case StaticUseKind.SUPER_TEAR_OFF:
        useSet.addAll(usage.tearOff());
        methodsNeedingSuperGetter.add(element);
        break;
      case StaticUseKind.SUPER_FIELD_SET:
        fieldSetters.add(element);
        useSet.addAll(usage.normalUse());
        break;
      case StaticUseKind.STATIC_TEAR_OFF:
        useSet.addAll(usage.tearOff());
        break;
      case StaticUseKind.GENERAL:
      case StaticUseKind.DIRECT_USE:
      case StaticUseKind.CONSTRUCTOR_INVOKE:
      case StaticUseKind.CONST_CONSTRUCTOR_INVOKE:
      case StaticUseKind.REDIRECTION:
        useSet.addAll(usage.normalUse());
        break;
      case StaticUseKind.DIRECT_INVOKE:
        invariant(
            element, 'Direct static use is not supported for resolution.');
        break;
    }
    if (useSet.isNotEmpty) {
      memberUsed(usage.entity, useSet);
    }
  }

  void forgetEntity(Entity entity, Compiler compiler) {
    allClosures.remove(entity);
    slowDirectlyNestedClosures(entity).forEach(compiler.forgetElement);
    closurizedMembers.remove(entity);
    fieldSetters.remove(entity);
    _instantiationInfo.remove(entity);

    void removeUsage(Set<_MemberUsage> set, Entity entity) {
      if (set == null) return;
      set.removeAll(
          set.where((_MemberUsage usage) => usage.entity == entity).toList());
    }

    _processedClasses.remove(entity);
    removeUsage(_instanceMembersByName[entity.name], entity);
    removeUsage(_instanceFunctionsByName[entity.name], entity);
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

  /// Return the canonical [_ClassUsage] for [cls].
  _ClassUsage _getClassUsage(ClassElement cls) {
    return _processedClasses.putIfAbsent(cls, () {
      cls.ensureResolved(_resolution);
      _ClassUsage usage = new _ClassUsage(cls);
      _resolution.ensureClassMembers(cls);
      return usage;
    });
  }

  /// Register [cls] and all its superclasses as instantiated.
  void _processInstantiatedClass(
      ClassElement cls, ClassUsedCallback classUsed) {
    // Registers [superclass] as instantiated. Returns `true` if it wasn't
    // already instantiated and we therefore have to process its superclass as
    // well.
    bool processClass(ClassElement superclass) {
      _ClassUsage usage = _getClassUsage(superclass);
      if (!usage.isInstantiated) {
        classUsed(usage.cls, usage.instantiate());
        return true;
      }
      return false;
    }

    while (cls != null && processClass(cls)) {
      cls = cls.superclass;
    }
  }

  /// Computes usage for all members declared by [cls]. Calls [membersUsed] with
  /// the usage changes for each member.
  void processClassMembers(ClassElement cls, MemberUsedCallback memberUsed) {
    cls.implementation.forEachMember((ClassElement cls, MemberElement member) {
      _processInstantiatedClassMember(cls, member, memberUsed);
    });
  }

  /// Call [updateUsage] on all [MemberUsage]s in the set in [map] for
  /// [memberName]. If [updateUsage] returns `true` the usage is removed from
  /// the set.
  void _processSet(Map<String, Set<_MemberUsage>> map, String memberName,
      bool updateUsage(_MemberUsage e)) {
    Set<_MemberUsage> members = map[memberName];
    if (members == null) return;
    // [f] might add elements to [: map[memberName] :] during the loop below
    // so we create a new list for [: map[memberName] :] and prepend the
    // [remaining] members after the loop.
    map[memberName] = new Set<_MemberUsage>();
    Set<_MemberUsage> remaining = new Set<_MemberUsage>();
    for (_MemberUsage usage in members) {
      if (!updateUsage(usage)) remaining.add(usage);
    }
    map[memberName].addAll(remaining);
  }

  void _processInstanceMembers(String name, bool updateUsage(_MemberUsage e)) {
    _processSet(_instanceMembersByName, name, updateUsage);
  }

  void _processInstanceFunctions(
      String name, bool updateUsage(_MemberUsage e)) {
    _processSet(_instanceFunctionsByName, name, updateUsage);
  }

  void _processInstantiatedClassMember(
      ClassElement cls, MemberElement member, MemberUsedCallback memberUsed) {
    assert(invariant(member, member.isDeclaration));
    if (!member.isInstanceMember) return;
    String memberName = member.name;
    member.computeType(_resolution);
    EnumSet<MemberUse> useSet = new EnumSet<MemberUse>();
    // The obvious thing to test here would be "member.isNative",
    // however, that only works after metadata has been parsed/analyzed,
    // and that may not have happened yet.
    // So instead we use the enclosing class, which we know have had
    // its metadata parsed and analyzed.
    // Note: this assumes that there are no non-native fields on native
    // classes, which may not be the case when a native class is subclassed.
    bool isNative = _backend.isNative(cls);
    _MemberUsage usage = _instanceMemberUsage.putIfAbsent(member, () {
      _MemberUsage usage = new _MemberUsage(member, isNative: isNative);
      useSet.addAll(usage.appliedUse);
      if (member.isField && isNative) {
        _openWorld.registerUsedElement(member);
      }
      if (member.isFunction &&
          member.name == Identifiers.call &&
          !cls.typeVariables.isEmpty) {
        callMethodsWithFreeTypeVariables.add(member);
      }

      if (_hasInvokedGetter(member)) {
        useSet.addAll(usage.read());
      }
      if (_hasInvocation(member)) {
        useSet.addAll(usage.invoke());
      }
      if (hasInvokedSetter(member)) {
        useSet.addAll(usage.write());
      }

      if (usage.pendingUse.contains(MemberUse.NORMAL)) {
        // The element is not yet used. Add it to the list of instance
        // members to still be processed.
        _instanceMembersByName
            .putIfAbsent(memberName, () => new Set<_MemberUsage>())
            .add(usage);
      }
      if (usage.pendingUse.contains(MemberUse.CLOSURIZE_INSTANCE)) {
        // Store the member in [instanceFunctionsByName] to catch
        // getters on the function.
        _instanceFunctionsByName
            .putIfAbsent(memberName, () => new Set<_MemberUsage>())
            .add(usage);
      }

      memberUsed(usage.entity, useSet);
      return usage;
    });
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

  /// Returns `true` if [member] is invoked as a setter.
  bool hasInvokedSetter(Element member, ClosedWorld world);

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

abstract class _AbstractUsage<T> {
  final EnumSet<T> _pendingUse = new EnumSet<T>();

  _AbstractUsage() {
    _pendingUse.addAll(_originalUse);
  }

  /// Returns the possible uses of [entity] that have not yet been registered.
  EnumSet<T> get pendingUse => _pendingUse;

  /// Returns the uses of [entity] that have been registered.
  EnumSet<T> get appliedUse => _originalUse.minus(_pendingUse);

  EnumSet<T> get _originalUse;
}

/// Registry for the observed use of a member [entity] in the open world.
abstract class _MemberUsage extends _AbstractUsage<MemberUse> {
  // TODO(johnniwinther): Change [Entity] to [MemberEntity].
  final Entity entity;

  _MemberUsage.internal(this.entity);

  factory _MemberUsage(MemberEntity member, {bool isNative: false}) {
    if (member.isField) {
      if (member.isAssignable) {
        return new _FieldUsage(member, isNative: isNative);
      } else {
        return new _FinalFieldUsage(member, isNative: isNative);
      }
    } else if (member.isGetter) {
      return new _GetterUsage(member);
    } else if (member.isSetter) {
      return new _SetterUsage(member);
    } else {
      assert(member.isFunction);
      return new _FunctionUsage(member);
    }
  }

  /// `true` if [entity] has been read as a value. For a field this is a normal
  /// read access, for a function this is a closurization.
  bool get hasRead => false;

  /// `true` if a value has been written to [entity].
  bool get hasWrite => false;

  /// `true` if an invocation has been performed on the value [entity]. For a
  /// function this is a normal invocation, for a field this is a read access
  /// followed by an invocation of the function-like value.
  bool get hasInvoke => false;

  /// `true` if [entity] has been used in all the ways possible.
  bool get fullyUsed;

  /// Registers a read of the value of [entity] and returns the new [MemberUse]s
  /// that it caused.
  ///
  /// For a field this is a normal read access, for a function this is a
  /// closurization.
  EnumSet<MemberUse> read() => MemberUses.NONE;

  /// Registers a write of a value to [entity] and returns the new [MemberUse]s
  /// that it caused.
  EnumSet<MemberUse> write() => MemberUses.NONE;

  /// Registers an invocation on the value of [entity] and returns the new
  /// [MemberUse]s that it caused.
  ///
  /// For a function this is a normal invocation, for a field this is a read
  /// access followed by an invocation of the function-like value.
  EnumSet<MemberUse> invoke() => MemberUses.NONE;

  /// Registers all possible uses of [entity] and returns the new [MemberUse]s
  /// that it caused.
  EnumSet<MemberUse> fullyUse() => MemberUses.NONE;

  @override
  EnumSet<MemberUse> get _originalUse => MemberUses.NORMAL_ONLY;

  int get hashCode => entity.hashCode;

  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! _MemberUsage) return false;
    return entity == other.entity;
  }

  String toString() => entity.toString();
}

class _FieldUsage extends _MemberUsage {
  bool hasRead = false;
  bool hasWrite = false;

  _FieldUsage(FieldEntity field, {bool isNative: false})
      : super.internal(field) {
    if (!isNative) {
      // All field initializers must be resolved as they could
      // have an observable side-effect (and cannot be tree-shaken
      // away).
      fullyUse();
    }
  }

  @override
  bool get fullyUsed => hasRead && hasWrite;

  @override
  EnumSet<MemberUse> read() {
    if (fullyUsed) {
      return MemberUses.NONE;
    }
    hasRead = true;
    return _pendingUse.removeAll(MemberUses.NORMAL_ONLY);
  }

  @override
  EnumSet<MemberUse> write() {
    if (fullyUsed) {
      return MemberUses.NONE;
    }
    hasWrite = true;
    return _pendingUse.removeAll(MemberUses.NORMAL_ONLY);
  }

  @override
  EnumSet<MemberUse> invoke() => read();

  @override
  EnumSet<MemberUse> fullyUse() {
    if (fullyUsed) {
      return MemberUses.NONE;
    }
    hasRead = hasWrite = true;
    return _pendingUse.removeAll(MemberUses.NORMAL_ONLY);
  }
}

class _FinalFieldUsage extends _MemberUsage {
  bool hasRead = false;

  _FinalFieldUsage(FieldEntity field, {bool isNative: false})
      : super.internal(field) {
    if (!isNative) {
      // All field initializers must be resolved as they could
      // have an observable side-effect (and cannot be tree-shaken
      // away).
      read();
    }
  }

  @override
  bool get fullyUsed => hasRead;

  @override
  EnumSet<MemberUse> read() {
    if (hasRead) {
      return MemberUses.NONE;
    }
    hasRead = true;
    return _pendingUse.removeAll(MemberUses.NORMAL_ONLY);
  }

  @override
  EnumSet<MemberUse> invoke() => read();

  @override
  EnumSet<MemberUse> fullyUse() => read();
}

class _FunctionUsage extends _MemberUsage {
  bool hasInvoke = false;
  bool hasRead = false;

  _FunctionUsage(FunctionEntity function) : super.internal(function);

  EnumSet<MemberUse> get _originalUse => MemberUses.ALL_INSTANCE;

  @override
  EnumSet<MemberUse> read() => fullyUse();

  @override
  EnumSet<MemberUse> invoke() {
    if (hasInvoke) {
      return MemberUses.NONE;
    }
    hasInvoke = true;
    return _pendingUse
        .removeAll(hasRead ? MemberUses.NONE : MemberUses.NORMAL_ONLY);
  }

  @override
  EnumSet<MemberUse> fullyUse() {
    if (hasInvoke) {
      if (hasRead) {
        return MemberUses.NONE;
      }
      hasRead = true;
      return _pendingUse.removeAll(MemberUses.CLOSURIZE_INSTANCE_ONLY);
    } else if (hasRead) {
      hasInvoke = true;
      return _pendingUse.removeAll(MemberUses.NORMAL_ONLY);
    } else {
      hasRead = hasInvoke = true;
      return _pendingUse.removeAll(MemberUses.ALL_INSTANCE);
    }
  }

  @override
  bool get fullyUsed => hasInvoke && hasRead;
}

class _GetterUsage extends _MemberUsage {
  bool hasRead = false;

  _GetterUsage(FunctionEntity getter) : super.internal(getter);

  @override
  bool get fullyUsed => hasRead;

  @override
  EnumSet<MemberUse> read() {
    if (hasRead) {
      return MemberUses.NONE;
    }
    hasRead = true;
    return _pendingUse.removeAll(MemberUses.NORMAL_ONLY);
  }

  @override
  EnumSet<MemberUse> invoke() => read();

  @override
  EnumSet<MemberUse> fullyUse() => read();
}

class _SetterUsage extends _MemberUsage {
  bool hasWrite = false;

  _SetterUsage(FunctionEntity setter) : super.internal(setter);

  @override
  bool get fullyUsed => hasWrite;

  @override
  EnumSet<MemberUse> write() {
    if (hasWrite) {
      return MemberUses.NONE;
    }
    hasWrite = true;
    return MemberUses.NORMAL_ONLY;
  }

  @override
  EnumSet<MemberUse> fullyUse() => write();
}

/// Enum class for the possible kind of use of [MemberEntity] objects.
enum MemberUse { NORMAL, CLOSURIZE_INSTANCE, CLOSURIZE_STATIC }

/// Common [EnumSet]s used for [MemberUse].
class MemberUses {
  static const EnumSet<MemberUse> NONE = const EnumSet<MemberUse>.fixed(0);
  static const EnumSet<MemberUse> NORMAL_ONLY =
      const EnumSet<MemberUse>.fixed(1);
  static const EnumSet<MemberUse> CLOSURIZE_INSTANCE_ONLY =
      const EnumSet<MemberUse>.fixed(2);
  static const EnumSet<MemberUse> CLOSURIZE_STATIC_ONLY =
      const EnumSet<MemberUse>.fixed(4);
  static const EnumSet<MemberUse> ALL_INSTANCE =
      const EnumSet<MemberUse>.fixed(3);
  static const EnumSet<MemberUse> ALL_STATIC =
      const EnumSet<MemberUse>.fixed(5);
}

typedef void MemberUsedCallback(MemberEntity member, EnumSet<MemberUse> useSet);

/// Registry for the observed use of a class [entity] in the open world.
// TODO(johnniwinther): Merge this with [InstantiationInfo].
class _ClassUsage extends _AbstractUsage<ClassUse> {
  bool isInstantiated = false;
  bool isImplemented = false;

  final ClassEntity cls;

  _ClassUsage(this.cls);

  EnumSet<ClassUse> instantiate() {
    if (isInstantiated) {
      return ClassUses.NONE;
    }
    isInstantiated = true;
    return _pendingUse.removeAll(ClassUses.INSTANTIATED_ONLY);
  }

  EnumSet<ClassUse> implement() {
    if (isImplemented) {
      return ClassUses.NONE;
    }
    isImplemented = true;
    return _pendingUse.removeAll(ClassUses.IMPLEMENTED_ONLY);
  }

  @override
  EnumSet<ClassUse> get _originalUse => ClassUses.ALL;

  String toString() => cls.toString();
}

/// Enum class for the possible kind of use of [ClassEntity] objects.
enum ClassUse { INSTANTIATED, IMPLEMENTED }

/// Common [EnumSet]s used for [ClassUse].
class ClassUses {
  static const EnumSet<ClassUse> NONE = const EnumSet<ClassUse>.fixed(0);
  static const EnumSet<ClassUse> INSTANTIATED_ONLY =
      const EnumSet<ClassUse>.fixed(1);
  static const EnumSet<ClassUse> IMPLEMENTED_ONLY =
      const EnumSet<ClassUse>.fixed(2);
  static const EnumSet<ClassUse> ALL = const EnumSet<ClassUse>.fixed(3);
}

typedef void ClassUsedCallback(ClassEntity cls, EnumSet<ClassUse> useSet);

// TODO(johnniwinther): Merge this with [_MemberUsage].
abstract class _StaticMemberUsage extends _AbstractUsage<MemberUse> {
  final Entity entity;

  bool hasNormalUse = false;
  bool get hasClosurization => false;

  _StaticMemberUsage.internal(this.entity);

  EnumSet<MemberUse> normalUse() {
    if (hasNormalUse) {
      return MemberUses.NONE;
    }
    hasNormalUse = true;
    return _pendingUse.removeAll(MemberUses.NORMAL_ONLY);
  }

  EnumSet<MemberUse> tearOff();

  @override
  EnumSet<MemberUse> get _originalUse => MemberUses.NORMAL_ONLY;

  String toString() => entity.toString();
}

class _GeneralStaticMemberUsage extends _StaticMemberUsage {
  _GeneralStaticMemberUsage(Entity entity) : super.internal(entity);

  EnumSet<MemberUse> tearOff() => normalUse();
}

class _StaticFunctionUsage extends _StaticMemberUsage {
  bool hasClosurization = false;

  _StaticFunctionUsage(Entity entity) : super.internal(entity);

  EnumSet<MemberUse> tearOff() {
    if (hasClosurization) {
      return MemberUses.NONE;
    }
    hasNormalUse = hasClosurization = true;
    return _pendingUse.removeAll(MemberUses.ALL_STATIC);
  }

  @override
  EnumSet<MemberUse> get _originalUse => MemberUses.ALL_STATIC;
}
