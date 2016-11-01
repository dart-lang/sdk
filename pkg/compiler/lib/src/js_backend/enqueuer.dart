// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js.enqueue;

import 'dart:collection' show Queue;

import '../common/backend_api.dart' show Backend;
import '../common/codegen.dart' show CodegenWorkItem;
import '../common/registry.dart' show Registry;
import '../common/names.dart' show Identifiers;
import '../common/work.dart' show WorkItem;
import '../common.dart';
import '../compiler.dart' show Compiler;
import '../dart_types.dart' show DartType, InterfaceType;
import '../elements/elements.dart'
    show
        ClassElement,
        ConstructorElement,
        Element,
        Elements,
        Entity,
        FunctionElement,
        LibraryElement,
        Member,
        MemberElement,
        MethodElement,
        Name,
        TypedElement,
        TypedefElement;
import '../enqueue.dart';
import '../js/js.dart' as js;
import '../native/native.dart' as native;
import '../options.dart';
import '../types/types.dart' show TypeMaskStrategy;
import '../universe/selector.dart' show Selector;
import '../universe/world_builder.dart';
import '../universe/use.dart'
    show DynamicUse, StaticUse, StaticUseKind, TypeUse, TypeUseKind;
import '../universe/world_impact.dart'
    show ImpactUseCase, WorldImpact, WorldImpactVisitor;
import '../util/util.dart' show Setlet;
import '../world.dart';

/// [Enqueuer] which is specific to code generation.
class CodegenEnqueuer implements Enqueuer {
  final String name;
  @deprecated
  final Compiler _compiler; // TODO(ahe): Remove this dependency.
  final EnqueuerStrategy strategy;
  final Map<String, Set<Element>> instanceMembersByName =
      new Map<String, Set<Element>>();
  final Map<String, Set<Element>> instanceFunctionsByName =
      new Map<String, Set<Element>>();
  final Set<ClassElement> _processedClasses = new Set<ClassElement>();
  Set<ClassElement> recentClasses = new Setlet<ClassElement>();
  final CodegenWorldBuilderImpl _universe =
      new CodegenWorldBuilderImpl(const TypeMaskStrategy());

  static final TRACE_MIRROR_ENQUEUING =
      const bool.fromEnvironment("TRACE_MIRROR_ENQUEUING");

  bool queueIsClosed = false;
  EnqueueTask task;
  native.NativeEnqueuer nativeEnqueuer; // Set by EnqueueTask

  bool hasEnqueuedReflectiveElements = false;
  bool hasEnqueuedReflectiveStaticFields = false;

  WorldImpactVisitor impactVisitor;

  CodegenEnqueuer(Compiler compiler, this.strategy)
      : queue = new Queue<CodegenWorkItem>(),
        newlyEnqueuedElements = compiler.cacheStrategy.newSet(),
        newlySeenSelectors = compiler.cacheStrategy.newSet(),
        this.name = 'codegen enqueuer',
        this._compiler = compiler {
    impactVisitor = new _EnqueuerImpactVisitor(this);
  }

  CodegenWorldBuilder get universe => _universe;

  Backend get backend => _compiler.backend;

  CompilerOptions get options => _compiler.options;

  Registry get globalDependencies => _compiler.globalDependencies;

  Registry get mirrorDependencies => _compiler.mirrorDependencies;

  ClosedWorld get _world => _compiler.closedWorld;

  bool get queueIsEmpty => queue.isEmpty;

  /// Returns [:true:] if this enqueuer is the resolution enqueuer.
  bool get isResolutionQueue => false;

  QueueFilter get filter => _compiler.enqueuerFilter;

  DiagnosticReporter get reporter => _compiler.reporter;

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [element] must be a declaration element.
   */
  void addToWorkList(Element element) {
    assert(invariant(element, element.isDeclaration));
    // Don't generate code for foreign elements.
    if (backend.isForeign(element)) return;

    // Codegen inlines field initializers. It only needs to generate
    // code for checked setters.
    if (element.isField && element.isInstanceMember) {
      if (!options.enableTypeAssertions || element.enclosingElement.isClosure) {
        return;
      }
    }

    if (options.hasIncrementalSupport && !isProcessed(element)) {
      newlyEnqueuedElements.add(element);
    }

    if (queueIsClosed) {
      throw new SpannableAssertionFailure(
          element, "Codegen work list is closed. Trying to add $element");
    }
    queue.add(new CodegenWorkItem(_compiler, element));
    if (options.dumpInfo) {
      // TODO(sigmund): add other missing dependencies (internals, selectors
      // enqueued after allocations), also enable only for the codegen enqueuer.
      _compiler.dumpInfoTask
          .registerDependency(_compiler.currentElement, element);
    }
  }

  void applyImpact(WorldImpact worldImpact, {Element impactSource}) {
    _compiler.impactStrategy
        .visitImpact(impactSource, worldImpact, impactVisitor, impactUse);
  }

  void registerInstantiatedType(InterfaceType type, {bool mirrorUsage: false}) {
    task.measure(() {
      ClassElement cls = type.element;
      bool isNative = backend.isNative(cls);
      _universe.registerTypeInstantiation(type,
          isNative: isNative,
          byMirrors: mirrorUsage, onImplemented: (ClassElement cls) {
        backend.registerImplementedClass(cls, this, globalDependencies);
      });
      // TODO(johnniwinther): Share this reasoning with [Universe].
      if (!cls.isAbstract || isNative || mirrorUsage) {
        processInstantiatedClass(cls);
      }
    });
  }

  bool checkNoEnqueuedInvokedInstanceMethods() {
    return filter.checkNoEnqueuedInvokedInstanceMethods(this);
  }

  void processInstantiatedClassMembers(ClassElement cls) {
    strategy.processInstantiatedClass(this, cls);
  }

  void processInstantiatedClassMember(ClassElement cls, Element member) {
    assert(invariant(member, member.isDeclaration));
    if (isProcessed(member)) return;
    if (!member.isInstanceMember) return;
    String memberName = member.name;

    if (member.isField) {
      // The obvious thing to test here would be "member.isNative",
      // however, that only works after metadata has been parsed/analyzed,
      // and that may not have happened yet.
      // So instead we use the enclosing class, which we know have had
      // its metadata parsed and analyzed.
      // Note: this assumes that there are no non-native fields on native
      // classes, which may not be the case when a native class is subclassed.
      if (backend.isNative(cls)) {
        if (_universe.hasInvokedGetter(member, _world) ||
            _universe.hasInvocation(member, _world)) {
          addToWorkList(member);
          return;
        } else if (universe.hasInvokedSetter(member, _world)) {
          addToWorkList(member);
          return;
        }
        // Native fields need to go into instanceMembersByName as they
        // are virtual instantiation points and escape points.
      } else {
        // All field initializers must be resolved as they could
        // have an observable side-effect (and cannot be tree-shaken
        // away).
        addToWorkList(member);
        return;
      }
    } else if (member.isFunction) {
      FunctionElement function = member;
      if (function.name == Identifiers.noSuchMethod_) {
        registerNoSuchMethod(function);
      }
      if (function.name == Identifiers.call && !cls.typeVariables.isEmpty) {
        registerCallMethodWithFreeTypeVariables(function);
      }
      // If there is a property access with the same name as a method we
      // need to emit the method.
      if (_universe.hasInvokedGetter(function, _world)) {
        registerClosurizedMember(function);
        addToWorkList(function);
        return;
      }
      _registerInstanceMethod(function);
      if (_universe.hasInvocation(function, _world)) {
        addToWorkList(function);
        return;
      }
    } else if (member.isGetter) {
      FunctionElement getter = member;
      if (_universe.hasInvokedGetter(getter, _world)) {
        addToWorkList(getter);
        return;
      }
      // We don't know what selectors the returned closure accepts. If
      // the set contains any selector we have to assume that it matches.
      if (_universe.hasInvocation(getter, _world)) {
        addToWorkList(getter);
        return;
      }
    } else if (member.isSetter) {
      FunctionElement setter = member;
      if (_universe.hasInvokedSetter(setter, _world)) {
        addToWorkList(setter);
        return;
      }
    }

    // The element is not yet used. Add it to the list of instance
    // members to still be processed.
    instanceMembersByName
        .putIfAbsent(memberName, () => new Set<Element>())
        .add(member);
  }

  // Store the member in [instanceFunctionsByName] to catch
  // getters on the function.
  void _registerInstanceMethod(MethodElement element) {
    instanceFunctionsByName
        .putIfAbsent(element.name, () => new Set<Element>())
        .add(element);
  }

  void enableIsolateSupport() {}

  void processInstantiatedClass(ClassElement cls) {
    task.measure(() {
      if (_processedClasses.contains(cls)) return;

      void processClass(ClassElement superclass) {
        if (_processedClasses.contains(superclass)) return;
        // TODO(johnniwinther): Re-insert this invariant when unittests don't
        // fail. There is already a similar invariant on the members.
        /*assert(invariant(superclass,
              superclass.isClosure ||
              _compiler.enqueuer.resolution.isClassProcessed(superclass),
              message: "Class $superclass has not been "
                       "processed in resolution."));
        */

        _processedClasses.add(superclass);
        recentClasses.add(superclass);
        superclass.implementation.forEachMember(processInstantiatedClassMember);
        // We only tell the backend once that [superclass] was instantiated, so
        // any additional dependencies must be treated as global
        // dependencies.
        backend.registerInstantiatedClass(superclass, this, globalDependencies);
      }

      ClassElement superclass = cls;
      while (superclass != null) {
        processClass(superclass);
        superclass = superclass.superclass;
      }
    });
  }

  void registerDynamicUse(DynamicUse dynamicUse) {
    task.measure(() {
      if (_universe.registerDynamicUse(dynamicUse)) {
        handleUnseenSelector(dynamicUse);
      }
    });
  }

  void logEnqueueReflectiveAction(action, [msg = ""]) {
    if (TRACE_MIRROR_ENQUEUING) {
      print("MIRROR_ENQUEUE (C): $action $msg");
    }
  }

  /// Enqeue the constructor [ctor] if it is required for reflection.
  ///
  /// [enclosingWasIncluded] provides a hint whether the enclosing element was
  /// needed for reflection.
  void enqueueReflectiveConstructor(
      ConstructorElement ctor, bool enclosingWasIncluded) {
    if (shouldIncludeElementDueToMirrors(ctor,
        includedEnclosing: enclosingWasIncluded)) {
      logEnqueueReflectiveAction(ctor);
      ClassElement cls = ctor.declaration.enclosingClass;
      backend.registerInstantiatedType(cls.rawType, this, mirrorDependencies,
          mirrorUsage: true);
      registerStaticUse(new StaticUse.foreignUse(ctor.declaration));
    }
  }

  /// Enqeue the member [element] if it is required for reflection.
  ///
  /// [enclosingWasIncluded] provides a hint whether the enclosing element was
  /// needed for reflection.
  void enqueueReflectiveMember(Element element, bool enclosingWasIncluded) {
    if (shouldIncludeElementDueToMirrors(element,
        includedEnclosing: enclosingWasIncluded)) {
      logEnqueueReflectiveAction(element);
      if (element.isTypedef) {
        // Do nothing.
      } else if (Elements.isStaticOrTopLevel(element)) {
        registerStaticUse(new StaticUse.foreignUse(element.declaration));
      } else if (element.isInstanceMember) {
        // We need to enqueue all members matching this one in subclasses, as
        // well.
        // TODO(herhut): Use TypedSelector.subtype for enqueueing
        DynamicUse dynamicUse =
            new DynamicUse(new Selector.fromElement(element), null);
        registerDynamicUse(dynamicUse);
        if (element.isField) {
          DynamicUse dynamicUse = new DynamicUse(
              new Selector.setter(
                  new Name(element.name, element.library, isSetter: true)),
              null);
          registerDynamicUse(dynamicUse);
        }
      }
    }
  }

  /// Enqeue the member [element] if it is required for reflection.
  ///
  /// [enclosingWasIncluded] provides a hint whether the enclosing element was
  /// needed for reflection.
  void enqueueReflectiveElementsInClass(ClassElement cls,
      Iterable<ClassElement> recents, bool enclosingWasIncluded) {
    if (cls.library.isInternalLibrary || cls.isInjected) return;
    bool includeClass = shouldIncludeElementDueToMirrors(cls,
        includedEnclosing: enclosingWasIncluded);
    if (includeClass) {
      logEnqueueReflectiveAction(cls, "register");
      ClassElement decl = cls.declaration;
      backend.registerInstantiatedType(decl.rawType, this, mirrorDependencies,
          mirrorUsage: true);
    }
    // If the class is never instantiated, we know nothing of it can possibly
    // be reflected upon.
    // TODO(herhut): Add a warning if a mirrors annotation cannot hit.
    if (recents.contains(cls.declaration)) {
      logEnqueueReflectiveAction(cls, "members");
      cls.constructors.forEach((Element element) {
        enqueueReflectiveConstructor(element, includeClass);
      });
      cls.forEachClassMember((Member member) {
        enqueueReflectiveMember(member.element, includeClass);
      });
    }
  }

  /// Enqeue special classes that might not be visible by normal means or that
  /// would not normally be enqueued:
  ///
  /// [Closure] is treated specially as it is the superclass of all closures.
  /// Although it is in an internal library, we mark it as reflectable. Note
  /// that none of its methods are reflectable, unless reflectable by
  /// inheritance.
  void enqueueReflectiveSpecialClasses() {
    Iterable<ClassElement> classes = backend.classesRequiredForReflection;
    for (ClassElement cls in classes) {
      if (backend.referencedFromMirrorSystem(cls)) {
        logEnqueueReflectiveAction(cls);
        backend.registerInstantiatedType(cls.rawType, this, mirrorDependencies,
            mirrorUsage: true);
      }
    }
  }

  /// Enqeue all local members of the library [lib] if they are required for
  /// reflection.
  void enqueueReflectiveElementsInLibrary(
      LibraryElement lib, Iterable<ClassElement> recents) {
    bool includeLibrary =
        shouldIncludeElementDueToMirrors(lib, includedEnclosing: false);
    lib.forEachLocalMember((Element member) {
      if (member.isInjected) return;
      if (member.isClass) {
        enqueueReflectiveElementsInClass(member, recents, includeLibrary);
      } else {
        enqueueReflectiveMember(member, includeLibrary);
      }
    });
  }

  /// Enqueue all elements that are matched by the mirrors used
  /// annotation or, in lack thereof, all elements.
  void enqueueReflectiveElements(Iterable<ClassElement> recents) {
    if (!hasEnqueuedReflectiveElements) {
      logEnqueueReflectiveAction("!START enqueueAll");
      // First round of enqueuing, visit everything that is visible to
      // also pick up static top levels, etc.
      // Also, during the first round, consider all classes that have been seen
      // as recently seen, as we do not know how many rounds of resolution might
      // have run before tree shaking is disabled and thus everything is
      // enqueued.
      recents = _processedClasses.toSet();
      reporter.log('Enqueuing everything');
      for (LibraryElement lib in _compiler.libraryLoader.libraries) {
        enqueueReflectiveElementsInLibrary(lib, recents);
      }
      enqueueReflectiveSpecialClasses();
      hasEnqueuedReflectiveElements = true;
      hasEnqueuedReflectiveStaticFields = true;
      logEnqueueReflectiveAction("!DONE enqueueAll");
    } else if (recents.isNotEmpty) {
      // Keep looking at new classes until fixpoint is reached.
      logEnqueueReflectiveAction("!START enqueueRecents");
      recents.forEach((ClassElement cls) {
        enqueueReflectiveElementsInClass(
            cls,
            recents,
            shouldIncludeElementDueToMirrors(cls.library,
                includedEnclosing: false));
      });
      logEnqueueReflectiveAction("!DONE enqueueRecents");
    }
  }

  /// Enqueue the static fields that have been marked as used by reflective
  /// usage through `MirrorsUsed`.
  void enqueueReflectiveStaticFields(Iterable<Element> elements) {
    if (hasEnqueuedReflectiveStaticFields) return;
    hasEnqueuedReflectiveStaticFields = true;
    for (Element element in elements) {
      enqueueReflectiveMember(element, true);
    }
  }

  void processSet(
      Map<String, Set<Element>> map, String memberName, bool f(Element e)) {
    Set<Element> members = map[memberName];
    if (members == null) return;
    // [f] might add elements to [: map[memberName] :] during the loop below
    // so we create a new list for [: map[memberName] :] and prepend the
    // [remaining] members after the loop.
    map[memberName] = new Set<Element>();
    Set<Element> remaining = new Set<Element>();
    for (Element member in members) {
      if (!f(member)) remaining.add(member);
    }
    map[memberName].addAll(remaining);
  }

  processInstanceMembers(String n, bool f(Element e)) {
    processSet(instanceMembersByName, n, f);
  }

  processInstanceFunctions(String n, bool f(Element e)) {
    processSet(instanceFunctionsByName, n, f);
  }

  void _handleUnseenSelector(DynamicUse universeSelector) {
    strategy.processDynamicUse(this, universeSelector);
  }

  void handleUnseenSelectorInternal(DynamicUse dynamicUse) {
    Selector selector = dynamicUse.selector;
    String methodName = selector.name;
    processInstanceMembers(methodName, (Element member) {
      if (dynamicUse.appliesUnnamed(member, _world)) {
        if (member.isFunction && selector.isGetter) {
          registerClosurizedMember(member);
        }
        addToWorkList(member);
        return true;
      }
      return false;
    });
    if (selector.isGetter) {
      processInstanceFunctions(methodName, (Element member) {
        if (dynamicUse.appliesUnnamed(member, _world)) {
          registerClosurizedMember(member);
          return true;
        }
        return false;
      });
    }
  }

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [element] must be a declaration element.
   */
  void registerStaticUse(StaticUse staticUse) {
    strategy.processStaticUse(this, staticUse);
  }

  void registerStaticUseInternal(StaticUse staticUse) {
    Element element = staticUse.element;
    assert(invariant(element, element.isDeclaration,
        message: "Element ${element} is not the declaration."));
    _universe.registerStaticUse(staticUse);
    backend.registerStaticUse(element, forResolution: false);
    bool addElement = true;
    switch (staticUse.kind) {
      case StaticUseKind.STATIC_TEAR_OFF:
        backend.registerGetOfStaticFunction(this);
        break;
      case StaticUseKind.FIELD_GET:
      case StaticUseKind.FIELD_SET:
      case StaticUseKind.CLOSURE:
        // TODO(johnniwinther): Avoid this. Currently [FIELD_GET] and
        // [FIELD_SET] contains [BoxFieldElement]s which we cannot enqueue.
        // Also [CLOSURE] contains [LocalFunctionElement] which we cannot
        // enqueue.
        addElement = false;
        break;
      case StaticUseKind.SUPER_FIELD_SET:
      case StaticUseKind.SUPER_TEAR_OFF:
      case StaticUseKind.GENERAL:
        break;
      case StaticUseKind.CONSTRUCTOR_INVOKE:
      case StaticUseKind.CONST_CONSTRUCTOR_INVOKE:
        registerTypeUse(new TypeUse.instantiation(staticUse.type));
        break;
      case StaticUseKind.DIRECT_INVOKE:
        _registerInstanceMethod(staticUse.element);
        break;
    }
    if (addElement) {
      addToWorkList(element);
    }
  }

  void registerTypeUse(TypeUse typeUse) {
    DartType type = typeUse.type;
    switch (typeUse.kind) {
      case TypeUseKind.INSTANTIATION:
        registerInstantiatedType(type);
        break;
      case TypeUseKind.IS_CHECK:
      case TypeUseKind.AS_CAST:
      case TypeUseKind.CATCH_TYPE:
        _registerIsCheck(type);
        break;
      case TypeUseKind.CHECKED_MODE_CHECK:
        if (options.enableTypeAssertions) {
          _registerIsCheck(type);
        }
        break;
      case TypeUseKind.TYPE_LITERAL:
        break;
    }
  }

  void _registerIsCheck(DartType type) {
    type = _universe.registerIsCheck(type, _compiler);
    // Even in checked mode, type annotations for return type and argument
    // types do not imply type checks, so there should never be a check
    // against the type variable of a typedef.
    assert(!type.isTypeVariable || !type.element.enclosingElement.isTypedef);
  }

  void registerCallMethodWithFreeTypeVariables(Element element) {
    backend.registerCallMethodWithFreeTypeVariables(
        element, this, globalDependencies);
  }

  void registerClosurizedMember(TypedElement element) {
    assert(element.isInstanceMember);
    if (element.type.containsTypeVariables) {
      backend.registerClosureWithFreeTypeVariables(
          element, this, globalDependencies);
    }
    backend.registerBoundClosure(this);
  }

  void forEach(void f(WorkItem work)) {
    do {
      while (queue.isNotEmpty) {
        // TODO(johnniwinther): Find an optimal process order.
        filter.processWorkItem(f, queue.removeLast());
      }
      List recents = recentClasses.toList(growable: false);
      recentClasses.clear();
      if (!onQueueEmpty(recents)) recentClasses.addAll(recents);
    } while (queue.isNotEmpty || recentClasses.isNotEmpty);
  }

  /// [onQueueEmpty] is called whenever the queue is drained. [recentClasses]
  /// contains the set of all classes seen for the first time since
  /// [onQueueEmpty] was called last. A return value of [true] indicates that
  /// the [recentClasses] have been processed and may be cleared. If [false] is
  /// returned, [onQueueEmpty] will be called once the queue is empty again (or
  /// still empty) and [recentClasses] will be a superset of the current value.
  bool onQueueEmpty(Iterable<ClassElement> recentClasses) {
    return backend.onQueueEmpty(this, recentClasses);
  }

  void logSummary(log(message)) {
    _logSpecificSummary(log);
    nativeEnqueuer.logSummary(log);
  }

  String toString() => 'Enqueuer($name)';

  void _forgetElement(Element element) {
    _universe.forgetElement(element, _compiler);
    _processedClasses.remove(element);
    instanceMembersByName[element.name]?.remove(element);
    instanceFunctionsByName[element.name]?.remove(element);
  }

  final Queue<CodegenWorkItem> queue;
  final Map<Element, js.Expression> generatedCode = <Element, js.Expression>{};

  final Set<Element> newlyEnqueuedElements;

  final Set<DynamicUse> newlySeenSelectors;

  bool enabledNoSuchMethod = false;

  static const ImpactUseCase IMPACT_USE =
      const ImpactUseCase('CodegenEnqueuer');

  ImpactUseCase get impactUse => IMPACT_USE;

  bool isProcessed(Element member) =>
      member.isAbstract || generatedCode.containsKey(member);

  /**
   * Decides whether an element should be included to satisfy requirements
   * of the mirror system.
   *
   * For code generation, we rely on the precomputed set of elements that takes
   * subtyping constraints into account.
   */
  bool shouldIncludeElementDueToMirrors(Element element,
      {bool includedEnclosing}) {
    return backend.isAccessibleByReflection(element);
  }

  void registerNoSuchMethod(Element element) {
    if (!enabledNoSuchMethod && backend.enabledNoSuchMethod) {
      backend.enableNoSuchMethod(this);
      enabledNoSuchMethod = true;
    }
  }

  void _logSpecificSummary(log(message)) {
    log('Compiled ${generatedCode.length} methods.');
  }

  void forgetElement(Element element) {
    _forgetElement(element);
    generatedCode.remove(element);
    if (element is MemberElement) {
      for (Element closure in element.nestedClosures) {
        generatedCode.remove(closure);
        removeFromSet(instanceMembersByName, closure);
        removeFromSet(instanceFunctionsByName, closure);
      }
    }
  }

  void handleUnseenSelector(DynamicUse dynamicUse) {
    if (options.hasIncrementalSupport) {
      newlySeenSelectors.add(dynamicUse);
    }
    _handleUnseenSelector(dynamicUse);
  }

  @override
  Iterable<Entity> get processedEntities => generatedCode.keys;
}

void removeFromSet(Map<String, Set<Element>> map, Element element) {
  Set<Element> set = map[element.name];
  if (set == null) return;
  set.remove(element);
}

class _EnqueuerImpactVisitor implements WorldImpactVisitor {
  final CodegenEnqueuer enqueuer;

  _EnqueuerImpactVisitor(this.enqueuer);

  @override
  void visitDynamicUse(DynamicUse dynamicUse) {
    enqueuer.registerDynamicUse(dynamicUse);
  }

  @override
  void visitStaticUse(StaticUse staticUse) {
    enqueuer.registerStaticUse(staticUse);
  }

  @override
  void visitTypeUse(TypeUse typeUse) {
    enqueuer.registerTypeUse(typeUse);
  }
}
