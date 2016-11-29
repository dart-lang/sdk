// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js.enqueue;

import 'dart:collection' show Queue;

import '../common/backend_api.dart' show Backend;
import '../common/codegen.dart' show CodegenWorkItem;
import '../common/names.dart' show Identifiers;
import '../common/tasks.dart' show CompilerTask;
import '../common/work.dart' show WorkItem;
import '../common.dart';
import '../compiler.dart' show Compiler;
import '../dart_types.dart' show DartType, InterfaceType;
import '../elements/elements.dart'
    show
        ClassElement,
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
    show ImpactUseCase, ImpactStrategy, WorldImpact, WorldImpactVisitor;
import '../util/util.dart' show Setlet;
import '../world.dart';

/// [Enqueuer] which is specific to code generation.
class CodegenEnqueuer extends EnqueuerImpl {
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

  bool queueIsClosed = false;
  final CompilerTask task;
  final native.NativeEnqueuer nativeEnqueuer;

  WorldImpactVisitor impactVisitor;

  CodegenEnqueuer(this.task, Compiler compiler, this.strategy)
      : queue = new Queue<CodegenWorkItem>(),
        newlyEnqueuedElements = compiler.cacheStrategy.newSet(),
        newlySeenSelectors = compiler.cacheStrategy.newSet(),
        nativeEnqueuer = compiler.backend.nativeCodegenEnqueuer(),
        this.name = 'codegen enqueuer',
        this._compiler = compiler {
    impactVisitor = new EnqueuerImplImpactVisitor(this);
  }

  CodegenWorldBuilder get universe => _universe;

  Backend get backend => _compiler.backend;

  CompilerOptions get options => _compiler.options;

  ClosedWorld get _world => _compiler.closedWorld;

  bool get queueIsEmpty => queue.isEmpty;

  /// Returns [:true:] if this enqueuer is the resolution enqueuer.
  bool get isResolutionQueue => false;

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
    queue.add(new CodegenWorkItem(backend, element));
    // TODO(sigmund): add other missing dependencies (internals, selectors
    // enqueued after allocations).
    _compiler.dumpInfoTask
        .registerDependency(_compiler.currentElement, element);
  }

  void applyImpact(WorldImpact worldImpact, {Element impactSource}) {
    if (worldImpact.isEmpty) return;
    impactStrategy.visitImpact(
        impactSource, worldImpact, impactVisitor, impactUse);
  }

  void registerInstantiatedType(InterfaceType type) {
    _registerInstantiatedType(type);
  }

  void _registerInstantiatedType(InterfaceType type,
      {bool mirrorUsage: false, bool nativeUsage: false}) {
    task.measure(() {
      ClassElement cls = type.element;
      bool isNative = backend.isNative(cls);
      _universe.registerTypeInstantiation(type,
          isNative: isNative,
          byMirrors: mirrorUsage, onImplemented: (ClassElement cls) {
        applyImpact(
            backend.registerImplementedClass(cls, forResolution: false));
      });
      if (nativeUsage) {
        nativeEnqueuer.onInstantiatedType(type);
      }
      backend.registerInstantiatedType(type);
      // TODO(johnniwinther): Share this reasoning with [Universe].
      if (!cls.isAbstract || isNative || mirrorUsage) {
        processInstantiatedClass(cls);
      }
    });
  }

  bool checkNoEnqueuedInvokedInstanceMethods() {
    return strategy.checkEnqueuerConsistency(this);
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
        applyImpact(backend.registerInstantiatedClass(superclass,
            forResolution: false));
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
    applyImpact(backend.registerStaticUse(element, forResolution: false));
    bool addElement = true;
    switch (staticUse.kind) {
      case StaticUseKind.STATIC_TEAR_OFF:
        applyImpact(backend.registerGetOfStaticFunction());
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
      case StaticUseKind.DIRECT_USE:
        break;
      case StaticUseKind.CONSTRUCTOR_INVOKE:
      case StaticUseKind.CONST_CONSTRUCTOR_INVOKE:
      case StaticUseKind.REDIRECTION:
        registerTypeUseInternal(new TypeUse.instantiation(staticUse.type));
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
    strategy.processTypeUse(this, typeUse);
  }

  void registerTypeUseInternal(TypeUse typeUse) {
    DartType type = typeUse.type;
    switch (typeUse.kind) {
      case TypeUseKind.INSTANTIATION:
        _registerInstantiatedType(type);
        break;
      case TypeUseKind.MIRROR_INSTANTIATION:
        _registerInstantiatedType(type, mirrorUsage: true);
        break;
      case TypeUseKind.NATIVE_INSTANTIATION:
        _registerInstantiatedType(type, nativeUsage: true);
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
    type = _universe.registerIsCheck(type, _compiler.resolution);
    // Even in checked mode, type annotations for return type and argument
    // types do not imply type checks, so there should never be a check
    // against the type variable of a typedef.
    assert(!type.isTypeVariable || !type.element.enclosingElement.isTypedef);
  }

  void registerCallMethodWithFreeTypeVariables(Element element) {
    applyImpact(backend.registerCallMethodWithFreeTypeVariables(element,
        forResolution: false));
  }

  void registerClosurizedMember(TypedElement element) {
    assert(element.isInstanceMember);
    if (element.type.containsTypeVariables) {
      applyImpact(backend.registerClosureWithFreeTypeVariables(element,
          forResolution: false));
    }
    applyImpact(backend.registerBoundClosure());
  }

  void forEach(void f(WorkItem work)) {
    do {
      while (queue.isNotEmpty) {
        // TODO(johnniwinther): Find an optimal process order.
        WorkItem work = queue.removeLast();
        if (!isProcessed(work.element)) {
          strategy.processWorkItem(f, work);
          // TODO(johnniwinther): Register the processed element here. This
          // is currently a side-effect of calling `work.run`.
        }
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

  void registerNoSuchMethod(Element element) {
    if (!enabledNoSuchMethod && backend.enabledNoSuchMethod) {
      applyImpact(backend.enableNoSuchMethod());
      enabledNoSuchMethod = true;
    }
  }

  void _logSpecificSummary(log(message)) {
    log('Compiled ${generatedCode.length} methods.');
  }

  void forgetElement(Element element, Compiler compiler) {
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

  @override
  Iterable<ClassElement> get processedClasses => _processedClasses;
}

void removeFromSet(Map<String, Set<Element>> map, Element element) {
  Set<Element> set = map[element.name];
  if (set == null) return;
  set.remove(element);
}
