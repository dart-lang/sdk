// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of js_backend;

const VERBOSE_OPTIMIZER_HINTS = false;

class JavaScriptItemCompilationContext extends ItemCompilationContext {
  final Set<HInstruction> boundsChecked = new Set<HInstruction>();
  final Set<HInstruction> allocatedFixedLists = new Set<HInstruction>();
}

/*
 * Invariants:
 *   canInline(function) implies canInline(function, insideLoop:true)
 *   !canInline(function, insideLoop: true) implies !canInline(function)
 */
class FunctionInlineCache {
  final Map<FunctionElement, bool> canBeInlined =
      new Map<FunctionElement, bool>();

  final Map<FunctionElement, bool> canBeInlinedInsideLoop =
      new Map<FunctionElement, bool>();

  // Returns [:true:]/[:false:] if we have a cached decision.
  // Returns [:null:] otherwise.
  bool canInline(FunctionElement element, {bool insideLoop}) {
    return insideLoop ? canBeInlinedInsideLoop[element] : canBeInlined[element];
  }

  void markAsInlinable(FunctionElement element, {bool insideLoop}) {
    if (insideLoop) {
      canBeInlinedInsideLoop[element] = true;
    } else {
      // If we can inline a function outside a loop then we should do it inside
      // a loop as well.
      canBeInlined[element] = true;
      canBeInlinedInsideLoop[element] = true;
    }
  }

  void markAsNonInlinable(FunctionElement element, {bool insideLoop}) {
    if (insideLoop == null || insideLoop) {
      // If we can't inline a function inside a loop, then we should not inline
      // it outside a loop either.
      canBeInlined[element] = false;
      canBeInlinedInsideLoop[element] = false;
    } else {
      canBeInlined[element] = false;
    }
  }
}

class JavaScriptBackend extends Backend {
  static final Uri DART_JS_MIRRORS =
      new Uri(scheme: 'dart', path: '_js_mirrors');
  static final Uri DART_JS_NAMES =
      new Uri(scheme: 'dart', path: '_js_names');

  SsaBuilderTask builder;
  SsaOptimizerTask optimizer;
  SsaCodeGeneratorTask generator;
  CodeEmitterTask emitter;

  /**
   * The generated code as a js AST for compiled methods.
   */
  Map<Element, jsAst.Expression> get generatedCode {
    return compiler.enqueuer.codegen.generatedCode;
  }

  FunctionInlineCache inlineCache = new FunctionInlineCache();

  ClassElement jsInterceptorClass;
  ClassElement jsStringClass;
  ClassElement jsArrayClass;
  ClassElement jsNumberClass;
  ClassElement jsIntClass;
  ClassElement jsDoubleClass;
  ClassElement jsNullClass;
  ClassElement jsBoolClass;
  ClassElement jsPlainJavaScriptObjectClass;
  ClassElement jsUnknownJavaScriptObjectClass;

  ClassElement jsIndexableClass;
  ClassElement jsMutableIndexableClass;

  ClassElement jsMutableArrayClass;
  ClassElement jsFixedArrayClass;
  ClassElement jsExtendableArrayClass;
  ClassElement jsPositiveIntClass;
  ClassElement jsUInt32Class;
  ClassElement jsUInt31Class;

  Element jsIndexableLength;
  Element jsArrayTypedConstructor;
  Element jsArrayRemoveLast;
  Element jsArrayAdd;
  Element jsStringSplit;
  Element jsStringToString;
  Element jsStringOperatorAdd;
  Element objectEquals;

  ClassElement typeLiteralClass;
  ClassElement mapLiteralClass;
  ClassElement constMapLiteralClass;
  ClassElement typeVariableClass;
  ConstructorElement mapLiteralConstructor;
  ConstructorElement mapLiteralConstructorEmpty;

  ClassElement noSideEffectsClass;
  ClassElement noThrowsClass;
  ClassElement noInlineClass;
  ClassElement irRepresentationClass;

  Element getInterceptorMethod;
  Element interceptedNames;

  /// If [true], the compiler will emit code that writes the name of the current
  /// method together with its class and library to the console the first time
  /// the method is called.
  static const bool TRACE_CALLS = false;
  Element traceHelper;

  /**
   * This element is a top-level variable (in generated output) that the
   * compiler initializes to a datastructure used to map from a Type to the
   * interceptor.  See declaration of `mapTypeToInterceptor` in
   * `interceptors.dart`.
   */
  Element mapTypeToInterceptor;

  TypeMask get stringType => compiler.typesTask.stringType;
  TypeMask get doubleType => compiler.typesTask.doubleType;
  TypeMask get intType => compiler.typesTask.intType;
  TypeMask get uint32Type => compiler.typesTask.uint32Type;
  TypeMask get uint31Type => compiler.typesTask.uint31Type;
  TypeMask get positiveIntType => compiler.typesTask.positiveIntType;
  TypeMask get numType => compiler.typesTask.numType;
  TypeMask get boolType => compiler.typesTask.boolType;
  TypeMask get dynamicType => compiler.typesTask.dynamicType;
  TypeMask get nullType => compiler.typesTask.nullType;
  TypeMask get emptyType => const TypeMask.nonNullEmpty();
  TypeMask indexablePrimitiveType;
  TypeMask readableArrayType;
  TypeMask mutableArrayType;
  TypeMask fixedArrayType;
  TypeMask extendableArrayType;
  TypeMask nonNullType;

  /// Maps special classes to their implementation (JSXxx) class.
  Map<ClassElement, ClassElement> implementationClasses;

  Element getNativeInterceptorMethod;
  bool needToInitializeIsolateAffinityTag = false;
  bool needToInitializeDispatchProperty = false;

  /// Holds the method "getIsolateAffinityTag" when dart:_js_helper has been
  /// loaded.
  FunctionElement getIsolateAffinityTagMarker;

  final Namer namer;

  /**
   * Interface used to determine if an object has the JavaScript
   * indexing behavior. The interface is only visible to specific
   * libraries.
   */
  ClassElement jsIndexingBehaviorInterface;

  /**
   * A collection of selectors that must have a one shot interceptor
   * generated.
   */
  final Map<String, Selector> oneShotInterceptors;

  /**
   * The members of instantiated interceptor classes: maps a member name to the
   * list of members that have that name. This map is used by the codegen to
   * know whether a send must be intercepted or not.
   */
  final Map<String, Set<Element>> interceptedElements;

  /**
   * The members of mixin classes that are mixed into an instantiated
   * interceptor class.  This is a cached subset of [interceptedElements].
   *
   * Mixin methods are not specialized for the class they are mixed into.
   * Methods mixed into intercepted classes thus always make use of the explicit
   * receiver argument, even when mixed into non-interceptor classes.
   *
   * These members must be invoked with a correct explicit receiver even when
   * the receiver is not an intercepted class.
   */
  final Map<String, Set<Element>> interceptedMixinElements =
      new Map<String, Set<Element>>();

  /**
   * A map of specialized versions of the [getInterceptorMethod].
   * Since [getInterceptorMethod] is a hot method at runtime, we're
   * always specializing it based on the incoming type. The keys in
   * the map are the names of these specialized versions. Note that
   * the generic version that contains all possible type checks is
   * also stored in this map.
   */
  final Map<String, Set<ClassElement>> specializedGetInterceptors;

  /**
   * Set of classes whose methods are intercepted.
   */
  final Set<ClassElement> _interceptedClasses = new Set<ClassElement>();

  /**
   * Set of classes used as mixins on intercepted (native and primitive)
   * classes.  Methods on these classes might also be mixed in to regular Dart
   * (unintercepted) classes.
   */
  final Set<ClassElement> classesMixedIntoInterceptedClasses =
      new Set<ClassElement>();

  /**
   * Set of classes whose `operator ==` methods handle `null` themselves.
   */
  final Set<ClassElement> specialOperatorEqClasses = new Set<ClassElement>();

  List<CompilerTask> get tasks {
    return <CompilerTask>[builder, optimizer, generator, emitter];
  }

  final RuntimeTypes rti;

  /// Holds the method "disableTreeShaking" in js_mirrors when
  /// dart:mirrors has been loaded.
  FunctionElement disableTreeShakingMarker;

  /// Holds the method "preserveNames" in js_mirrors when
  /// dart:mirrors has been loaded.
  FunctionElement preserveNamesMarker;

  /// Holds the method "preserveMetadata" in js_mirrors when
  /// dart:mirrors has been loaded.
  FunctionElement preserveMetadataMarker;

  /// True if a call to preserveMetadataMarker has been seen.  This means that
  /// metadata must be retained for dart:mirrors to work correctly.
  bool mustRetainMetadata = false;

  /// True if any metadata has been retained.  This is slightly different from
  /// [mustRetainMetadata] and tells us if any metadata was retained.  For
  /// example, if [mustRetainMetadata] is true but there is no metadata in the
  /// program, this variable will stil be false.
  bool hasRetainedMetadata = false;

  /// True if a call to preserveNames has been seen.
  bool mustPreserveNames = false;

  /// True if a call to disableTreeShaking has been seen.
  bool isTreeShakingDisabled = false;

  /// True if there isn't sufficient @MirrorsUsed data.
  bool hasInsufficientMirrorsUsed = false;

  /// List of constants from metadata.  If metadata must be preserved,
  /// these constants must be registered.
  final List<Dependency> metadataConstants = <Dependency>[];

  /// List of symbols that the user has requested for reflection.
  final Set<String> symbolsUsed = new Set<String>();

  /// List of elements that the user has requested for reflection.
  final Set<Element> targetsUsed = new Set<Element>();

  /// List of annotations provided by user that indicate that the annotated
  /// element must be retained.
  final Set<Element> metaTargetsUsed = new Set<Element>();

  /// List of elements that the backend may use.
  final Set<Element> helpersUsed = new Set<Element>();


  /// Set of typedefs that are used as type literals.
  final Set<TypedefElement> typedefTypeLiterals = new Set<TypedefElement>();

  /// All the checked mode helpers.
  static const checkedModeHelpers = CheckedModeHelper.helpers;

  // Checked mode helpers indexed by name.
  Map<String, CheckedModeHelper> checkedModeHelperByName =
      new Map<String, CheckedModeHelper>.fromIterable(
          checkedModeHelpers,
          key: (helper) => helper.name);

  TypeVariableHandler typeVariableHandler;

  /// Number of methods compiled before considering reflection.
  int preMirrorsMethodCount = 0;

  /// Resolution and codegen support for generating table of interceptors and
  /// constructors for custom elements.
  CustomElementsAnalysis customElementsAnalysis;

  JavaScriptConstantTask constantCompilerTask;

  JavaScriptBackend(Compiler compiler, bool generateSourceMap)
      : namer = determineNamer(compiler),
        oneShotInterceptors = new Map<String, Selector>(),
        interceptedElements = new Map<String, Set<Element>>(),
        rti = new RuntimeTypes(compiler),
        specializedGetInterceptors = new Map<String, Set<ClassElement>>(),
        super(compiler) {
    emitter = new CodeEmitterTask(compiler, namer, generateSourceMap);
    builder = new SsaBuilderTask(this);
    optimizer = new SsaOptimizerTask(this);
    generator = new SsaCodeGeneratorTask(this);
    typeVariableHandler = new TypeVariableHandler(this);
    customElementsAnalysis = new CustomElementsAnalysis(this);
    constantCompilerTask = new JavaScriptConstantTask(compiler);
  }

  ConstantSystem get constantSystem => constants.constantSystem;

  /// Returns constant environment for the JavaScript interpretation of the
  /// constants.
  JavaScriptConstantCompiler get constants {
    return constantCompilerTask.jsConstantCompiler;
  }

  static Namer determineNamer(Compiler compiler) {
    return compiler.enableMinification ?
        new MinifyNamer(compiler) :
        new Namer(compiler);
  }

  bool usedByBackend(Element element) {
    if (element.isParameter
        || element.isFieldParameter
        || element.isField) {
      if (usedByBackend(element.enclosingElement)) return true;
    }
    return helpersUsed.contains(element.declaration);
  }

  bool invokedReflectively(Element element) {
    if (element.isParameter || element.isFieldParameter) {
      if (invokedReflectively(element.enclosingElement)) return true;
    }

    if (element.isField) {
      if (Elements.isStaticOrTopLevel(element)
          && (element.isFinal || element.isConst)) {
        return false;
      }
    }

    return isNeededForReflection(element.declaration);
  }

  bool canBeUsedForGlobalOptimizations(Element element) {
    return !usedByBackend(element) && !invokedReflectively(element);
  }

  bool isInterceptorClass(ClassElement element) {
    if (element == null) return false;
    if (Elements.isNativeOrExtendsNative(element)) return true;
    if (interceptedClasses.contains(element)) return true;
    if (classesMixedIntoInterceptedClasses.contains(element)) return true;
    return false;
  }

  String registerOneShotInterceptor(Selector selector) {
    Set<ClassElement> classes = getInterceptedClassesOn(selector.name);
    String name = namer.getOneShotInterceptorName(selector, classes);
    if (!oneShotInterceptors.containsKey(name)) {
      registerSpecializedGetInterceptor(classes);
      oneShotInterceptors[name] = selector;
    }
    return name;
  }

  bool isInterceptedMethod(Element element) {
    if (!element.isInstanceMember) return false;
    if (element.isGenerativeConstructorBody) {
      return Elements.isNativeOrExtendsNative(element.enclosingClass);
    }
    return interceptedElements[element.name] != null;
  }

  bool fieldHasInterceptedGetter(Element element) {
    assert(element.isField);
    return interceptedElements[element.name] != null;
  }

  bool fieldHasInterceptedSetter(Element element) {
    assert(element.isField);
    return interceptedElements[element.name] != null;
  }

  bool isInterceptedName(String name) {
    return interceptedElements[name] != null;
  }

  bool isInterceptedSelector(Selector selector) {
    return interceptedElements[selector.name] != null;
  }

  /**
   * Returns `true` iff [selector] matches an element defined in a class mixed
   * into an intercepted class.  These selectors are not eligible for the 'dummy
   * explicit receiver' optimization.
   */
  bool isInterceptedMixinSelector(Selector selector) {
    Set<Element> elements = interceptedMixinElements.putIfAbsent(
        selector.name,
        () {
          Set<Element> elements = interceptedElements[selector.name];
          if (elements == null) return null;
          return elements
              .where((element) =>
                  classesMixedIntoInterceptedClasses.contains(
                      element.enclosingClass))
              .toSet();
        });

    if (elements == null) return false;
    if (elements.isEmpty) return false;
    return elements.any((element) => selector.applies(element, compiler));
  }

  final Map<String, Set<ClassElement>> interceptedClassesCache =
      new Map<String, Set<ClassElement>>();

  /**
   * Returns a set of interceptor classes that contain a member named
   * [name]. Returns [:null:] if there is no class.
   */
  Set<ClassElement> getInterceptedClassesOn(String name) {
    Set<Element> intercepted = interceptedElements[name];
    if (intercepted == null) return null;
    return interceptedClassesCache.putIfAbsent(name, () {
      // Populate the cache by running through all the elements and
      // determine if the given selector applies to them.
      Set<ClassElement> result = new Set<ClassElement>();
      for (Element element in intercepted) {
        ClassElement classElement = element.enclosingClass;
        if (Elements.isNativeOrExtendsNative(classElement)
            || interceptedClasses.contains(classElement)) {
          result.add(classElement);
        }
        if (classesMixedIntoInterceptedClasses.contains(classElement)) {
          Set<ClassElement> nativeSubclasses =
              nativeSubclassesOfMixin(classElement);
          if (nativeSubclasses != null) result.addAll(nativeSubclasses);
        }
      }
      return result;
    });
  }

  Set<ClassElement> nativeSubclassesOfMixin(ClassElement mixin) {
    Set<MixinApplicationElement> uses = compiler.world.mixinUses[mixin];
    if (uses == null) return null;
    Set<ClassElement> result = null;
    for (MixinApplicationElement use in uses) {
      Iterable<ClassElement> subclasses = compiler.world.subclassesOf(use);
      if (subclasses != null) {
        for (ClassElement subclass in subclasses) {
          if (Elements.isNativeOrExtendsNative(subclass)) {
            if (result == null) result = new Set<ClassElement>();
            result.add(subclass);
          }
        }
      }
    }
    return result;
  }

  bool operatorEqHandlesNullArgument(FunctionElement operatorEqfunction) {
    return specialOperatorEqClasses.contains(
        operatorEqfunction.enclosingClass);
  }

  void validateInterceptorImplementsAllObjectMethods(
      ClassElement interceptorClass) {
    if (interceptorClass == null) return;
    interceptorClass.ensureResolved(compiler);
    compiler.objectClass.forEachMember((_, Element member) {
      if (member.isGenerativeConstructor) return;
      Element interceptorMember = interceptorClass.lookupMember(member.name);
      // Interceptors must override all Object methods due to calling convention
      // differences.
      assert(interceptorMember.enclosingClass == interceptorClass);
    });
  }

  void addInterceptorsForNativeClassMembers(
      ClassElement cls, Enqueuer enqueuer) {
    if (enqueuer.isResolutionQueue) {
      cls.ensureResolved(compiler);
      cls.forEachMember((ClassElement classElement, Element member) {
        if (member.name == Compiler.CALL_OPERATOR_NAME) {
          compiler.reportError(
              member,
              MessageKind.CALL_NOT_SUPPORTED_ON_NATIVE_CLASS);
          return;
        }
        if (member.isSynthesized) return;
        // All methods on [Object] are shadowed by [Interceptor].
        if (classElement == compiler.objectClass) return;
        Set<Element> set = interceptedElements.putIfAbsent(
            member.name, () => new Set<Element>());
        set.add(member);
      },
      includeSuperAndInjectedMembers: true);

      // Walk superclass chain to find mixins.
      for (; cls != null; cls = cls.superclass) {
        if (cls.isMixinApplication) {
          MixinApplicationElement mixinApplication = cls;
          classesMixedIntoInterceptedClasses.add(mixinApplication.mixin);
        }
      }
    }
  }

  void addInterceptors(ClassElement cls,
                       Enqueuer enqueuer,
                       Registry registry) {
    if (enqueuer.isResolutionQueue) {
      _interceptedClasses.add(jsInterceptorClass);
      _interceptedClasses.add(cls);
      cls.ensureResolved(compiler);
      cls.forEachMember((ClassElement classElement, Element member) {
          // All methods on [Object] are shadowed by [Interceptor].
          if (classElement == compiler.objectClass) return;
          Set<Element> set = interceptedElements.putIfAbsent(
              member.name, () => new Set<Element>());
          set.add(member);
        },
        includeSuperAndInjectedMembers: true);
    }
    enqueueClass(enqueuer, cls, registry);
  }

  Set<ClassElement> get interceptedClasses {
    assert(compiler.enqueuer.resolution.queueIsClosed);
    return _interceptedClasses;
  }

  void registerSpecializedGetInterceptor(Set<ClassElement> classes) {
    String name = namer.getInterceptorName(getInterceptorMethod, classes);
    if (classes.contains(jsInterceptorClass)) {
      // We can't use a specialized [getInterceptorMethod], so we make
      // sure we emit the one with all checks.
      specializedGetInterceptors[name] = interceptedClasses;
    } else {
      specializedGetInterceptors[name] = classes;
    }
  }

  void registerCompileTimeConstant(Constant constant, Registry registry) {
    registerCompileTimeConstantInternal(constant, registry);
    for (Constant dependency in constant.getDependencies()) {
      registerCompileTimeConstant(dependency, registry);
    }
  }

  void registerCompileTimeConstantInternal(Constant constant,
                                           Registry registry) {
    DartType type = constant.computeType(compiler);
    registerInstantiatedConstantType(type, registry);

    if (constant.isFunction) {
      FunctionConstant function = constant;
      compiler.enqueuer.codegen.registerGetOfStaticFunction(function.element);
    } else if (constant.isInterceptor) {
      // An interceptor constant references the class's prototype chain.
      InterceptorConstant interceptor = constant;
      registerInstantiatedConstantType(interceptor.dispatchedType, registry);
    } else if (constant.isType) {
      enqueueInResolution(getCreateRuntimeType(), registry);
      compiler.enqueuer.codegen.registerInstantiatedClass(
          typeImplementation, registry);
    }
  }

  void registerInstantiatedConstantType(DartType type, Registry registry) {
    Enqueuer enqueuer = compiler.enqueuer.codegen;
    DartType instantiatedType =
        type.isFunctionType ? compiler.functionClass.rawType : type;
    if (type is InterfaceType) {
      enqueuer.registerInstantiatedType(instantiatedType, registry);
      if (!type.treatAsRaw && classNeedsRti(type.element)) {
        enqueuer.registerStaticUse(getSetRuntimeTypeInfo());
      }
      if (type.element == typeImplementation) {
        // If we use a type literal in a constant, the compile time
        // constant emitter will generate a call to the createRuntimeType
        // helper so we register a use of that.
        enqueuer.registerStaticUse(getCreateRuntimeType());
      }
    }
  }

  void registerMetadataConstant(Constant constant, Registry registry) {
    if (mustRetainMetadata) {
      registerCompileTimeConstant(constant, registry);
    } else {
      metadataConstants.add(new Dependency(constant, registry));
    }
  }

  void registerInstantiatedClass(ClassElement cls,
                                 Enqueuer enqueuer,
                                 Registry registry) {
    if (!cls.typeVariables.isEmpty) {
      typeVariableHandler.registerClassWithTypeVariables(cls);
    }

    // Register any helper that will be needed by the backend.
    if (enqueuer.isResolutionQueue) {
      if (cls == compiler.intClass
          || cls == compiler.doubleClass
          || cls == compiler.numClass) {
        // The backend will try to optimize number operations and use the
        // `iae` helper directly.
        enqueue(enqueuer,
                compiler.findHelper('iae'),
                registry);
      } else if (cls == compiler.listClass
                 || cls == compiler.stringClass) {
        // The backend will try to optimize array and string access and use the
        // `ioore` and `iae` helpers directly.
        enqueue(enqueuer,
                compiler.findHelper('ioore'),
                registry);
        enqueue(enqueuer,
                compiler.findHelper('iae'),
                registry);
      } else if (cls == compiler.functionClass) {
        enqueueClass(enqueuer, compiler.closureClass, registry);
      } else if (cls == compiler.mapClass) {
        // The backend will use a literal list to initialize the entries
        // of the map.
        enqueueClass(enqueuer, compiler.listClass, registry);
        enqueueClass(enqueuer, mapLiteralClass, registry);
        // For map literals, the dependency between the implementation class
        // and [Map] is not visible, so we have to add it manually.
        rti.registerRtiDependency(mapLiteralClass, cls);
      } else if (cls == compiler.boundClosureClass) {
        // TODO(ngeoffray): Move the bound closure class in the
        // backend.
        enqueueClass(enqueuer, compiler.boundClosureClass, registry);
      } else if (Elements.isNativeOrExtendsNative(cls)) {
        enqueue(enqueuer, getNativeInterceptorMethod, registry);
        enqueueClass(enqueuer, jsInterceptorClass, compiler.globalDependencies);
        enqueueClass(enqueuer, jsPlainJavaScriptObjectClass, registry);
      } else if (cls == mapLiteralClass) {
        // For map literals, the dependency between the implementation class
        // and [Map] is not visible, so we have to add it manually.
        Element getFactory(String name, int arity) {
          // The constructor is on the patch class, but dart2js unit tests don't
          // have a patch class.
          ClassElement implementation = cls.patch != null ? cls.patch : cls;
          return implementation.lookupConstructor(
            new Selector.callConstructor(
                name, mapLiteralClass.library, arity),
            (element) {
              compiler.internalError(mapLiteralClass,
                  "Map literal class $mapLiteralClass missing "
                  "'$name' constructor"
                  "  ${mapLiteralClass.constructors}");
            });
        }
        mapLiteralConstructor = getFactory('_literal', 1);
        mapLiteralConstructorEmpty = getFactory('_empty', 0);
        enqueueInResolution(mapLiteralConstructor, registry);
        enqueueInResolution(mapLiteralConstructorEmpty, registry);
      }
    }
    if (cls == compiler.closureClass) {
      enqueue(enqueuer,
              compiler.findHelper('closureFromTearOff'),
              registry);
    }
    ClassElement result = null;
    if (cls == compiler.stringClass || cls == jsStringClass) {
      addInterceptors(jsStringClass, enqueuer, registry);
    } else if (cls == compiler.listClass
               || cls == jsArrayClass
               || cls == jsFixedArrayClass
               || cls == jsExtendableArrayClass) {
      addInterceptors(jsArrayClass, enqueuer, registry);
      addInterceptors(jsMutableArrayClass, enqueuer, registry);
      addInterceptors(jsFixedArrayClass, enqueuer, registry);
      addInterceptors(jsExtendableArrayClass, enqueuer, registry);
    } else if (cls == compiler.intClass || cls == jsIntClass) {
      addInterceptors(jsIntClass, enqueuer, registry);
      addInterceptors(jsPositiveIntClass, enqueuer, registry);
      addInterceptors(jsUInt32Class, enqueuer, registry);
      addInterceptors(jsUInt31Class, enqueuer, registry);
      addInterceptors(jsNumberClass, enqueuer, registry);
    } else if (cls == compiler.doubleClass || cls == jsDoubleClass) {
      addInterceptors(jsDoubleClass, enqueuer, registry);
      addInterceptors(jsNumberClass, enqueuer, registry);
    } else if (cls == compiler.boolClass || cls == jsBoolClass) {
      addInterceptors(jsBoolClass, enqueuer, registry);
    } else if (cls == compiler.nullClass || cls == jsNullClass) {
      addInterceptors(jsNullClass, enqueuer, registry);
    } else if (cls == compiler.numClass || cls == jsNumberClass) {
      addInterceptors(jsIntClass, enqueuer, registry);
      addInterceptors(jsPositiveIntClass, enqueuer, registry);
      addInterceptors(jsUInt32Class, enqueuer, registry);
      addInterceptors(jsUInt31Class, enqueuer, registry);
      addInterceptors(jsDoubleClass, enqueuer, registry);
      addInterceptors(jsNumberClass, enqueuer, registry);
    } else if (cls == jsPlainJavaScriptObjectClass) {
      addInterceptors(jsPlainJavaScriptObjectClass, enqueuer, registry);
    } else if (cls == jsUnknownJavaScriptObjectClass) {
      addInterceptors(jsUnknownJavaScriptObjectClass, enqueuer, registry);
    } else if (Elements.isNativeOrExtendsNative(cls)) {
      addInterceptorsForNativeClassMembers(cls, enqueuer);
    } else if (cls == jsIndexingBehaviorInterface) {
      // These two helpers are used by the emitter and the codegen.
      // Because we cannot enqueue elements at the time of emission,
      // we make sure they are always generated.
      enqueue(
          enqueuer,
          compiler.findHelper('isJsIndexable'),
          registry);
      enqueue(
          enqueuer,
          compiler.findInterceptor('dispatchPropertyName'),
          registry);
    }

    customElementsAnalysis.registerInstantiatedClass(cls, enqueuer);
  }

  void registerUseInterceptor(Enqueuer enqueuer) {
    assert(!enqueuer.isResolutionQueue);
    if (!enqueuer.nativeEnqueuer.hasInstantiatedNativeClasses()) return;
    Registry registry = compiler.globalDependencies;
    enqueue(enqueuer, getNativeInterceptorMethod, registry);
    enqueueClass(enqueuer, jsPlainJavaScriptObjectClass, registry);
    needToInitializeIsolateAffinityTag = true;
    needToInitializeDispatchProperty = true;
  }

  JavaScriptItemCompilationContext createItemCompilationContext() {
    return new JavaScriptItemCompilationContext();
  }

  void enqueueHelpers(ResolutionEnqueuer world, Registry registry) {
    assert(compiler.interceptorsLibrary != null);
    // TODO(ngeoffray): Not enqueuing those two classes currently make
    // the compiler potentially crash. However, any reasonable program
    // will instantiate those two classes.
    addInterceptors(jsBoolClass, world, registry);
    addInterceptors(jsNullClass, world, registry);
    if (compiler.enableTypeAssertions) {
      // Unconditionally register the helper that checks if the
      // expression in an if/while/for is a boolean.
      // TODO(ngeoffray): Should we have the resolver register those instead?
      Element e =
          compiler.findHelper('boolConversionCheck');
      if (e != null) enqueue(world, e, registry);
    }
    if (TRACE_CALLS) {
      traceHelper = compiler.findHelper('traceHelper');
      assert(traceHelper != null);
      enqueueInResolution(traceHelper, registry);
    }
    registerCheckedModeHelpers(registry);
  }

  onResolutionComplete() => rti.computeClassesNeedingRti();

  void onStringInterpolation(Registry registry) {
    assert(registry.isForResolution);
    registerBackendStaticInvocation(getStringInterpolationHelper(), registry);
  }

  void onCatchStatement(Registry registry) {
    assert(registry.isForResolution);
    registerBackendStaticInvocation(getExceptionUnwrapper(), registry);
    registerBackendInstantiation(jsPlainJavaScriptObjectClass, registry);
    registerBackendInstantiation(jsUnknownJavaScriptObjectClass, registry);
  }

  void onThrowExpression(Registry registry) {
    assert(registry.isForResolution);
    // We don't know ahead of time whether we will need the throw in a
    // statement context or an expression context, so we register both
    // here, even though we may not need the throwExpression helper.
    registerBackendStaticInvocation(getWrapExceptionHelper(), registry);
    registerBackendStaticInvocation(getThrowExpressionHelper(), registry);
  }

  void onLazyField(Registry registry) {
    assert(registry.isForResolution);
    registerBackendStaticInvocation(getCyclicThrowHelper(), registry);
  }

  void onTypeLiteral(DartType type, Registry registry) {
    assert(registry.isForResolution);
    registerBackendInstantiation(typeImplementation, registry);
    registerBackendStaticInvocation(getCreateRuntimeType(), registry);
    // TODO(ahe): Might want to register [element] as an instantiated class
    // when reflection is used.  However, as long as we disable tree-shaking
    // eagerly it doesn't matter.
    if (type.isTypedef) {
      typedefTypeLiterals.add(type.element);
    }
    customElementsAnalysis.registerTypeLiteral(type, registry);
  }

  void onStackTraceInCatch(Registry registry) {
    assert(registry.isForResolution);
    registerBackendStaticInvocation(getTraceFromException(), registry);
  }

  void registerGetRuntimeTypeArgument(Registry registry) {
    enqueueInResolution(getGetRuntimeTypeArgument(), registry);
    enqueueInResolution(getGetTypeArgumentByIndex(), registry);
    enqueueInResolution(getCopyTypeArguments(), registry);
  }

  void registerGenericCallMethod(Element callMethod,
                                 Enqueuer enqueuer, Registry registry) {
    if (enqueuer.isResolutionQueue || methodNeedsRti(callMethod)) {
      registerComputeSignature(enqueuer, registry);
    }
  }

  void registerGenericClosure(Element closure,
                              Enqueuer enqueuer, Registry registry) {
    if (enqueuer.isResolutionQueue || methodNeedsRti(closure)) {
      registerComputeSignature(enqueuer, registry);
    }
  }

  void registerComputeSignature(Enqueuer enqueuer, Registry registry) {
    // Calls to [:computeSignature:] are generated by the emitter and we
    // therefore need to enqueue the used elements in the codegen enqueuer as
    // well as in the resolution enqueuer.
    enqueue(enqueuer, getSetRuntimeTypeInfo(), registry);
    enqueue(enqueuer, getGetRuntimeTypeInfo(), registry);
    enqueue(enqueuer, getComputeSignature(), registry);
    enqueue(enqueuer, getGetRuntimeTypeArguments(), registry);
    enqueueClass(enqueuer, compiler.listClass, registry);
  }

  void registerRuntimeType(Enqueuer enqueuer, Registry registry) {
    registerComputeSignature(enqueuer, registry);
    enqueueInResolution(getSetRuntimeTypeInfo(), registry);
    enqueueInResolution(getGetRuntimeTypeInfo(), registry);
    registerGetRuntimeTypeArgument(registry);
    enqueueClass(enqueuer, compiler.listClass, registry);
  }

  void onTypeVariableExpression(Registry registry) {
    assert(registry.isForResolution);
    registerBackendStaticInvocation(getSetRuntimeTypeInfo(), registry);
    registerBackendStaticInvocation(getGetRuntimeTypeInfo(), registry);
    registerGetRuntimeTypeArgument(registry);
    registerBackendInstantiation(compiler.listClass, registry);
    registerBackendStaticInvocation(getRuntimeTypeToString(), registry);
    registerBackendStaticInvocation(getCreateRuntimeType(), registry);
  }

  // TODO(johnniwinther): Maybe split this into [onAssertType] and [onTestType].
  void onIsCheck(DartType type, Registry registry) {
    assert(registry.isForResolution);
    type = type.unalias(compiler);
    registerBackendInstantiation(compiler.boolClass, registry);
    bool inCheckedMode = compiler.enableTypeAssertions;
    if (inCheckedMode) {
      registerBackendStaticInvocation(getThrowRuntimeError(), registry);
    }
    if (type.isMalformed) {
      registerBackendStaticInvocation(getThrowTypeError(), registry);
    }
    if (!type.treatAsRaw || type.containsTypeVariables) {
      // TODO(johnniwinther): Investigate why this is needed.
      registerBackendStaticInvocation(getSetRuntimeTypeInfo(), registry);
      registerBackendStaticInvocation(getGetRuntimeTypeInfo(), registry);
      registerGetRuntimeTypeArgument(registry);
      if (inCheckedMode) {
        registerBackendStaticInvocation(getAssertSubtype(), registry);
      }
      registerBackendStaticInvocation(getCheckSubtype(), registry);
      if (type.isTypeVariable) {
        registerBackendStaticInvocation(
            getCheckSubtypeOfRuntimeType(), registry);
        if (inCheckedMode) {
          registerBackendStaticInvocation(
              getAssertSubtypeOfRuntimeType(), registry);
        }
      }
      registerBackendInstantiation(compiler.listClass, registry);
    }
    if (type is FunctionType) {
      registerBackendStaticInvocation(
          compiler.findHelper('functionTypeTestMetaHelper'), registry);
    }
    if (type.element != null && type.element.isNative) {
      // We will neeed to add the "$is" and "$as" properties on the
      // JavaScript object prototype, so we make sure
      // [:defineProperty:] is compiled.
      registerBackendStaticInvocation(
              compiler.findHelper('defineProperty'),
              registry);
    }
  }

  void registerIsCheckForCodegen(DartType type,
                                 Enqueuer world,
                                 Registry registry) {
    assert(!registry.isForResolution);
    type = type.unalias(compiler);
    enqueueClass(world, compiler.boolClass, registry);
    bool inCheckedMode = compiler.enableTypeAssertions;
    // [registerIsCheck] is also called for checked mode checks, so we
    // need to register checked mode helpers.
    if (inCheckedMode) {
      // All helpers are added to resolution queue in enqueueHelpers. These
      // calls to enqueueInResolution serve as assertions that the helper was
      // in fact added.
      // TODO(13155): Find a way to enqueue helpers lazily.
      CheckedModeHelper helper = getCheckedModeHelper(type, typeCast: false);
      if (helper != null) {
        enqueue(world, helper.getElement(compiler), registry);
      }
      // We also need the native variant of the check (for DOM types).
      helper = getNativeCheckedModeHelper(type, typeCast: false);
      if (helper != null) {
        enqueue(world, helper.getElement(compiler), registry);
      }
    }
    if (!type.treatAsRaw || type.containsTypeVariables) {
      enqueueClass(world, compiler.listClass, registry);
    }
    if (type.element != null && type.element.isNative) {
      // We will neeed to add the "$is" and "$as" properties on the
      // JavaScript object prototype, so we make sure
      // [:defineProperty:] is compiled.
      enqueue(world,
              compiler.findHelper('defineProperty'),
              registry);
    }
  }

  void onAsCheck(DartType type, Registry registry) {
    assert(registry.isForResolution);
    registerBackendStaticInvocation(getThrowRuntimeError(), registry);
  }

  void onThrowNoSuchMethod(Registry registry) {
    assert(registry.isForResolution);
    registerBackendStaticInvocation(getThrowNoSuchMethod(), registry);
    // Also register the types of the arguments passed to this method.
    registerBackendInstantiation(compiler.listClass, registry);
    registerBackendInstantiation(compiler.stringClass, registry);
  }

  void onThrowRuntimeError(Registry registry) {
    assert(registry.isForResolution);
    registerBackendStaticInvocation(getThrowRuntimeError(), registry);
    // Also register the types of the arguments passed to this method.
    registerBackendInstantiation(compiler.stringClass, registry);
  }

  void registerTypeVariableBoundsSubtypeCheck(DartType typeArgument,
                                              DartType bound) {
    rti.registerTypeVariableBoundsSubtypeCheck(typeArgument, bound);
  }

  void onTypeVariableBoundCheck(Registry registry) {
    assert(registry.isForResolution);
    registerBackendStaticInvocation(getThrowTypeError(), registry);
    registerBackendStaticInvocation(getAssertIsSubtype(), registry);
  }

  void onAbstractClassInstantiation(Registry registry) {
    assert(registry.isForResolution);
    registerBackendStaticInvocation(getThrowAbstractClassInstantiationError(),
                                    registry);
    // Also register the types of the arguments passed to this method.
    registerBackendInstantiation(compiler.stringClass, registry);
  }

  void onFallThroughError(Registry registry) {
    assert(registry.isForResolution);
    registerBackendStaticInvocation(getFallThroughError(), registry);
  }

  void registerCheckDeferredIsLoaded(Registry registry) {
    enqueueInResolution(getCheckDeferredIsLoaded(), registry);
    // Also register the types of the arguments passed to this method.
    enqueueClass(compiler.enqueuer.resolution, compiler.stringClass, registry);
  }

  void enableNoSuchMethod(Enqueuer world) {
    enqueue(world, getCreateInvocationMirror(), compiler.globalDependencies);
    world.registerInvocation(compiler.noSuchMethodSelector);
  }

  void onSuperNoSuchMethod(Registry registry) {
    assert(registry.isForResolution);
    registerBackendStaticInvocation(getCreateInvocationMirror(), registry);
    registerBackendStaticInvocation(
        compiler.objectClass.lookupLocalMember(Compiler.NO_SUCH_METHOD),
        registry);
    registerBackendInstantiation(compiler.listClass, registry);
  }

  void registerRequiredType(DartType type, Element enclosingElement) {
    // If [argument] has type variables or is a type variable, this method
    // registers a RTI dependency between the class where the type variable is
    // defined (that is the enclosing class of the current element being
    // resolved) and the class of [type]. If the class of [type] requires RTI,
    // then the class of the type variable does too.
    ClassElement contextClass = Types.getClassContext(type);
    if (contextClass != null) {
      assert(contextClass == enclosingElement.enclosingClass.declaration);
      rti.registerRtiDependency(type.element, contextClass);
    }
  }

  void registerClassUsingVariableExpression(ClassElement cls) {
    rti.classesUsingTypeVariableExpression.add(cls);
  }

  bool classNeedsRti(ClassElement cls) {
    return rti.classesNeedingRti.contains(cls.declaration) ||
        compiler.enabledRuntimeType;
  }

  bool isDefaultNoSuchMethodImplementation(Element element) {
    assert(element.name == Compiler.NO_SUCH_METHOD);
    ClassElement classElement = element.enclosingClass;
    return classElement == compiler.objectClass
        || classElement == jsInterceptorClass
        || classElement == jsNullClass;
  }

  bool isDefaultEqualityImplementation(Element element) {
    assert(element.name == '==');
    ClassElement classElement = element.enclosingClass;
    return classElement == compiler.objectClass
        || classElement == jsInterceptorClass
        || classElement == jsNullClass;
  }

  bool methodNeedsRti(FunctionElement function) {
    return rti.methodsNeedingRti.contains(function) ||
           compiler.enabledRuntimeType;
  }

  /// The backend must *always* call this method when enqueuing an
  /// element. Calls done by the backend are not seen by global
  /// optimizations, so they would make these optimizations unsound.
  /// Therefore we need to collect the list of helpers the backend may
  /// use.
  Element registerBackendUse(Element element) {
    if (element != null) {
      helpersUsed.add(element.declaration);
      if (element.isClass && element.isPatched) {
        // Both declaration and implementation may declare fields, so we
        // add both to the list of helpers.
        helpersUsed.add(element.implementation);
      }
    }
    return element;
  }

  void registerBackendStaticInvocation(Element element, Registry registry) {
    registry.registerStaticInvocation(registerBackendUse(element));
  }

  void registerBackendInstantiation(ClassElement element, Registry registry) {
    registry.registerInstantiation(registerBackendUse(element));
  }

  /// Enqueue [e] in [enqueuer].
  ///
  /// This method calls [registerBackendUse].
  void enqueue(Enqueuer enqueuer, Element e, Registry registry) {
    if (e == null) return;
    registerBackendUse(e);
    enqueuer.addToWorkList(e);
    registry.registerDependency(e);
  }

  /// Enqueue [e] in the resolution enqueuer.
  ///
  /// This method calls [registerBackendUse].
  void enqueueInResolution(Element e, Registry registry) {
    if (e == null) return;
    ResolutionEnqueuer enqueuer = compiler.enqueuer.resolution;
    enqueue(enqueuer, e, registry);
  }

  /// Register instantiation of [cls] in [enqueuer].
  ///
  /// This method calls [registerBackendUse].
  void enqueueClass(Enqueuer enqueuer, Element cls, Registry registry) {
    if (cls == null) return;
    registerBackendUse(cls);
    helpersUsed.add(cls.declaration);
    if (cls.declaration != cls.implementation) {
      helpersUsed.add(cls.implementation);
    }
    enqueuer.registerInstantiatedClass(cls, registry);
  }

  void onConstantMap(Registry registry) {
    assert(registry.isForResolution);
    void enqueue(String name) {
      Element e = compiler.findHelper(name);
      registerBackendInstantiation(e, registry);
    }

    enqueue(MapConstant.DART_CLASS);
    enqueue(MapConstant.DART_PROTO_CLASS);
    enqueue(MapConstant.DART_STRING_CLASS);
    enqueue(MapConstant.DART_GENERAL_CLASS);
  }

  void codegen(CodegenWorkItem work) {
    Element element = work.element;
    var kind = element.kind;
    if (kind == ElementKind.TYPEDEF) return;
    if (element.isConstructor && element.enclosingClass == jsNullClass) {
      // Work around a problem compiling JSNull's constructor.
      return;
    }
    if (kind.category == ElementCategory.VARIABLE) {
      Constant initialValue = constants.getConstantForVariable(element);
      if (initialValue != null) {
        registerCompileTimeConstant(initialValue, work.registry);
        constants.addCompileTimeConstantForEmission(initialValue);
        // We don't need to generate code for static or top-level
        // variables. For instance variables, we may need to generate
        // the checked setter.
        if (Elements.isStaticOrTopLevel(element)) return;
      } else {
        // If the constant-handler was not able to produce a result we have to
        // go through the builder (below) to generate the lazy initializer for
        // the static variable.
        // We also need to register the use of the cyclic-error helper.
        compiler.enqueuer.codegen.registerStaticUse(getCyclicThrowHelper());
      }
    }
    HGraph graph = builder.build(work);
    optimizer.optimize(work, graph);
    jsAst.Expression code = generator.generateCode(work, graph);
    generatedCode[element] = code;
  }

  native.NativeEnqueuer nativeResolutionEnqueuer(Enqueuer world) {
    return new native.NativeResolutionEnqueuer(world, compiler);
  }

  native.NativeEnqueuer nativeCodegenEnqueuer(Enqueuer world) {
    return new native.NativeCodegenEnqueuer(world, compiler, emitter);
  }

  ClassElement defaultSuperclass(ClassElement element) {
    // Native classes inherit from Interceptor.
    return element.isNative ? jsInterceptorClass : compiler.objectClass;
  }

  /**
   * Unit test hook that returns code of an element as a String.
   *
   * Invariant: [element] must be a declaration element.
   */
  String assembleCode(Element element) {
    assert(invariant(element, element.isDeclaration));
    return jsAst.prettyPrint(generatedCode[element], compiler).getText();
  }

  void assembleProgram() {
    emitter.assembleProgram();
    int totalMethodCount = generatedCode.length;
    if (totalMethodCount != preMirrorsMethodCount) {
      int mirrorCount = totalMethodCount - preMirrorsMethodCount;
      double percentage = (mirrorCount / totalMethodCount) * 100;
      compiler.reportHint(
          compiler.mainApp, MessageKind.MIRROR_BLOAT,
          {'count': mirrorCount,
           'total': totalMethodCount,
           'percentage': percentage.round()});
      for (LibraryElement library in compiler.libraries.values) {
        if (library.isInternalLibrary) continue;
        for (LibraryTag tag in library.tags) {
          Import importTag = tag.asImport();
          if (importTag == null) continue;
          LibraryElement importedLibrary = library.getLibraryFromTag(tag);
          if (importedLibrary != compiler.mirrorsLibrary) continue;
          MessageKind kind =
              compiler.mirrorUsageAnalyzerTask.hasMirrorUsage(library)
              ? MessageKind.MIRROR_IMPORT
              : MessageKind.MIRROR_IMPORT_NO_USAGE;
          compiler.withCurrentElement(library, () {
            compiler.reportInfo(importTag, kind);
          });
        }
      }
    }
  }

  Element getDartClass(Element element) {
    for (ClassElement dartClass in implementationClasses.keys) {
      if (element == implementationClasses[dartClass]) {
        return dartClass;
      }
    }
    return element;
  }

  /**
   * Returns the checked mode helper that will be needed to do a type check/type
   * cast on [type] at runtime. Note that this method is being called both by
   * the resolver with interface types (int, String, ...), and by the SSA
   * backend with implementation types (JSInt, JSString, ...).
   */
  CheckedModeHelper getCheckedModeHelper(DartType type, {bool typeCast}) {
    return getCheckedModeHelperInternal(
        type, typeCast: typeCast, nativeCheckOnly: false);
  }

  /**
   * Returns the native checked mode helper that will be needed to do a type
   * check/type cast on [type] at runtime. If no native helper exists for
   * [type], [:null:] is returned.
   */
  CheckedModeHelper getNativeCheckedModeHelper(DartType type, {bool typeCast}) {
    return getCheckedModeHelperInternal(
        type, typeCast: typeCast, nativeCheckOnly: true);
  }

  /**
   * Returns the checked mode helper for the type check/type cast for [type]. If
   * [nativeCheckOnly] is [:true:], only names for native helpers are returned.
   */
  CheckedModeHelper getCheckedModeHelperInternal(DartType type,
                                                 {bool typeCast,
                                                  bool nativeCheckOnly}) {
    String name = getCheckedModeHelperNameInternal(type,
        typeCast: typeCast, nativeCheckOnly: nativeCheckOnly);
    if (name == null) return null;
    CheckedModeHelper helper = checkedModeHelperByName[name];
    assert(helper != null);
    return helper;
  }

  String getCheckedModeHelperNameInternal(DartType type,
                                          {bool typeCast,
                                           bool nativeCheckOnly}) {
    assert(type.kind != TypeKind.TYPEDEF);
    if (type.isMalformed) {
      // The same error is thrown for type test and type cast of a malformed
      // type so we only need one check method.
      return 'checkMalformedType';
    }
    Element element = type.element;
    bool nativeCheck = nativeCheckOnly ||
        emitter.nativeEmitter.requiresNativeIsCheck(element);

    // TODO(13955), TODO(9731).  The test for non-primitive types should use an
    // interceptor.  The interceptor should be an argument to HTypeConversion so
    // that it can be optimized by standard interceptor optimizations.
    nativeCheck = true;

    if (type.isVoid) {
      assert(!typeCast); // Cannot cast to void.
      if (nativeCheckOnly) return null;
      return 'voidTypeCheck';
    } else if (element == jsStringClass || element == compiler.stringClass) {
      if (nativeCheckOnly) return null;
      return typeCast
          ? 'stringTypeCast'
          : 'stringTypeCheck';
    } else if (element == jsDoubleClass || element == compiler.doubleClass) {
      if (nativeCheckOnly) return null;
      return typeCast
          ? 'doubleTypeCast'
          : 'doubleTypeCheck';
    } else if (element == jsNumberClass || element == compiler.numClass) {
      if (nativeCheckOnly) return null;
      return typeCast
          ? 'numTypeCast'
          : 'numTypeCheck';
    } else if (element == jsBoolClass || element == compiler.boolClass) {
      if (nativeCheckOnly) return null;
      return typeCast
          ? 'boolTypeCast'
          : 'boolTypeCheck';
    } else if (element == jsIntClass || element == compiler.intClass
               || element == jsUInt32Class || element == jsUInt31Class
               || element == jsPositiveIntClass) {
      if (nativeCheckOnly) return null;
      return typeCast
          ? 'intTypeCast'
          : 'intTypeCheck';
    } else if (Elements.isNumberOrStringSupertype(element, compiler)) {
      if (nativeCheck) {
        return typeCast
            ? 'numberOrStringSuperNativeTypeCast'
            : 'numberOrStringSuperNativeTypeCheck';
      } else {
        return typeCast
          ? 'numberOrStringSuperTypeCast'
          : 'numberOrStringSuperTypeCheck';
      }
    } else if (Elements.isStringOnlySupertype(element, compiler)) {
      if (nativeCheck) {
        return typeCast
            ? 'stringSuperNativeTypeCast'
            : 'stringSuperNativeTypeCheck';
      } else {
        return typeCast
            ? 'stringSuperTypeCast'
            : 'stringSuperTypeCheck';
      }
    } else if ((element == compiler.listClass || element == jsArrayClass) &&
               type.treatAsRaw) {
      if (nativeCheckOnly) return null;
      return typeCast
          ? 'listTypeCast'
          : 'listTypeCheck';
    } else {
      if (Elements.isListSupertype(element, compiler)) {
        if (nativeCheck) {
          return typeCast
              ? 'listSuperNativeTypeCast'
              : 'listSuperNativeTypeCheck';
        } else {
          return typeCast
              ? 'listSuperTypeCast'
              : 'listSuperTypeCheck';
        }
      } else {
        if (type.isInterfaceType && !type.treatAsRaw) {
          return typeCast
              ? 'subtypeCast'
              : 'assertSubtype';
        } else if (type.isTypeVariable) {
          return typeCast
              ? 'subtypeOfRuntimeTypeCast'
              : 'assertSubtypeOfRuntimeType';
        } else if (type.isFunctionType) {
          return null;
        } else {
          if (nativeCheck) {
            // TODO(karlklose): can we get rid of this branch when we use
            // interceptors?
            return typeCast
                ? 'interceptedTypeCast'
                : 'interceptedTypeCheck';
          } else {
            return typeCast
                ? 'propertyTypeCast'
                : 'propertyTypeCheck';
          }
        }
      }
    }
  }

  void registerCheckedModeHelpers(Registry registry) {
    // We register all the helpers in the resolution queue.
    // TODO(13155): Find a way to register fewer helpers.
    for (CheckedModeHelper helper in checkedModeHelpers) {
      enqueueInResolution(helper.getElement(compiler), registry);
    }
  }

  /**
   * Returns [:true:] if the checking of [type] is performed directly on the
   * object and not on an interceptor.
   */
  bool hasDirectCheckFor(DartType type) {
    Element element = type.element;
    return element == compiler.stringClass ||
        element == compiler.boolClass ||
        element == compiler.numClass ||
        element == compiler.intClass ||
        element == compiler.doubleClass ||
        element == jsArrayClass ||
        element == jsMutableArrayClass ||
        element == jsExtendableArrayClass ||
        element == jsFixedArrayClass;
  }

  Element getExceptionUnwrapper() {
    return compiler.findHelper('unwrapException');
  }

  Element getThrowRuntimeError() {
    return compiler.findHelper('throwRuntimeError');
  }

  Element getThrowTypeError() {
    return compiler.findHelper('throwTypeError');
  }

  Element getThrowAbstractClassInstantiationError() {
    return compiler.findHelper('throwAbstractClassInstantiationError');
  }

  Element getStringInterpolationHelper() {
    return compiler.findHelper('S');
  }

  Element getWrapExceptionHelper() {
    return compiler.findHelper(r'wrapException');
  }

  Element getThrowExpressionHelper() {
    return compiler.findHelper('throwExpression');
  }

  Element getClosureConverter() {
    return compiler.findHelper('convertDartClosureToJS');
  }

  Element getTraceFromException() {
    return compiler.findHelper('getTraceFromException');
  }

  Element getSetRuntimeTypeInfo() {
    return compiler.findHelper('setRuntimeTypeInfo');
  }

  Element getGetRuntimeTypeInfo() {
    return compiler.findHelper('getRuntimeTypeInfo');
  }

  Element getGetTypeArgumentByIndex() {
    return compiler.findHelper('getTypeArgumentByIndex');
  }

  Element getCopyTypeArguments() {
    return compiler.findHelper('copyTypeArguments');
  }

  Element getComputeSignature() {
    return compiler.findHelper('computeSignature');
  }

  Element getGetRuntimeTypeArguments() {
    return compiler.findHelper('getRuntimeTypeArguments');
  }

  Element getGetRuntimeTypeArgument() {
    return compiler.findHelper('getRuntimeTypeArgument');
  }

  Element getRuntimeTypeToString() {
    return compiler.findHelper('runtimeTypeToString');
  }

  Element getAssertIsSubtype() {
    return compiler.findHelper('assertIsSubtype');
  }

  Element getCheckSubtype() {
    return compiler.findHelper('checkSubtype');
  }

  Element getAssertSubtype() {
    return compiler.findHelper('assertSubtype');
  }

  Element getCheckSubtypeOfRuntimeType() {
    return compiler.findHelper('checkSubtypeOfRuntimeType');
  }

  Element getCheckDeferredIsLoaded() {
    return compiler.findHelper('checkDeferredIsLoaded');
  }

  Element getAssertSubtypeOfRuntimeType() {
    return compiler.findHelper('assertSubtypeOfRuntimeType');
  }

  Element getThrowNoSuchMethod() {
    return compiler.findHelper('throwNoSuchMethod');
  }

  Element getCreateRuntimeType() {
    return compiler.findHelper('createRuntimeType');
  }

  Element getFallThroughError() {
    return compiler.findHelper("getFallThroughError");
  }

  Element getCreateInvocationMirror() {
    return compiler.findHelper(Compiler.CREATE_INVOCATION_MIRROR);
  }

  Element getCyclicThrowHelper() {
    return compiler.findHelper("throwCyclicInit");
  }

  bool isNullImplementation(ClassElement cls) {
    return cls == jsNullClass;
  }

  ClassElement get intImplementation => jsIntClass;
  ClassElement get uint32Implementation => jsUInt32Class;
  ClassElement get uint31Implementation => jsUInt31Class;
  ClassElement get positiveIntImplementation => jsPositiveIntClass;
  ClassElement get doubleImplementation => jsDoubleClass;
  ClassElement get numImplementation => jsNumberClass;
  ClassElement get stringImplementation => jsStringClass;
  ClassElement get listImplementation => jsArrayClass;
  ClassElement get constListImplementation => jsArrayClass;
  ClassElement get fixedListImplementation => jsFixedArrayClass;
  ClassElement get growableListImplementation => jsExtendableArrayClass;
  ClassElement get mapImplementation => mapLiteralClass;
  ClassElement get constMapImplementation => constMapLiteralClass;
  ClassElement get typeImplementation => typeLiteralClass;
  ClassElement get boolImplementation => jsBoolClass;
  ClassElement get nullImplementation => jsNullClass;

  void registerStaticUse(Element element, Enqueuer enqueuer) {
    if (element == disableTreeShakingMarker) {
      compiler.disableTypeInferenceForMirrors = true;
      isTreeShakingDisabled = true;
      typeVariableHandler.onTreeShakingDisabled(enqueuer);
    } else if (element == preserveNamesMarker) {
      mustPreserveNames = true;
    } else if (element == preserveMetadataMarker) {
      mustRetainMetadata = true;
    } else if (element == getIsolateAffinityTagMarker) {
      needToInitializeIsolateAffinityTag = true;
    } else if (element.isDeferredLoaderGetter) {
      // TODO(sigurdm): Create a function registerLoadLibraryAccess.
      if (compiler.loadLibraryFunction == null) {
        compiler.loadLibraryFunction =
            compiler.findHelper("_loadLibraryWrapper");
        enqueueInResolution(compiler.loadLibraryFunction,
                            compiler.globalDependencies);
      }
    }
    customElementsAnalysis.registerStaticUse(element, enqueuer);
  }

  /// Called when [:const Symbol(name):] is seen.
  void registerConstSymbol(String name, Registry registry) {
    symbolsUsed.add(name);
    if (name.endsWith('=')) {
      symbolsUsed.add(name.substring(0, name.length - 1));
    }
  }

  /// Called when [:new Symbol(...):] is seen.
  void registerNewSymbol(Registry registry) {
  }

  /// Called when resolving the `Symbol` constructor.
  void onSymbolConstructor(Registry registry) {
    assert(registry.isForResolution);
    // Make sure that _internals.Symbol.validated is registered.
    assert(compiler.symbolValidatedConstructor != null);
    registerBackendStaticInvocation(compiler.symbolValidatedConstructor,
                                    registry);
  }

  /// Should [element] (a getter) be retained for reflection?
  bool shouldRetainGetter(Element element) => isNeededForReflection(element);

  /// Should [element] (a setter) be retained for reflection?
  bool shouldRetainSetter(Element element) => isNeededForReflection(element);

  /// Should [name] be retained for reflection?
  bool shouldRetainName(String name) {
    if (hasInsufficientMirrorsUsed) return mustPreserveNames;
    if (name == '') return false;
    return symbolsUsed.contains(name);
  }

  bool get rememberLazies => isTreeShakingDisabled;

  bool retainMetadataOf(Element element) {
    if (mustRetainMetadata) hasRetainedMetadata = true;
    if (mustRetainMetadata && isNeededForReflection(element)) {
      for (MetadataAnnotation metadata in element.metadata) {
        metadata.ensureResolved(compiler);
        Constant constant = constants.getConstantForMetadata(metadata);
        constants.addCompileTimeConstantForEmission(constant);
      }
      return true;
    }
    return false;
  }

  void onLibraryScanned(LibraryElement library) {
    Uri uri = library.canonicalUri;

    // TODO(johnniwinther): Assert that the elements are found.
    VariableElement findVariable(String name) {
      return library.find(name);
    }

    FunctionElement findMethod(String name) {
      return library.find(name);
    }

    ClassElement findClass(String name) {
      return library.find(name);
    }

    if (uri == Compiler.DART_INTERCEPTORS) {
      getInterceptorMethod = findMethod('getInterceptor');
      interceptedNames = findVariable('interceptedNames');
      mapTypeToInterceptor = findVariable('mapTypeToInterceptor');
      getNativeInterceptorMethod = findMethod('getNativeInterceptor');

      List<ClassElement> classes = [
        jsInterceptorClass = findClass('Interceptor'),
        jsStringClass = findClass('JSString'),
        jsArrayClass = findClass('JSArray'),
        // The int class must be before the double class, because the
        // emitter relies on this list for the order of type checks.
        jsIntClass = findClass('JSInt'),
        jsPositiveIntClass = findClass('JSPositiveInt'),
        jsUInt32Class = findClass('JSUInt32'),
        jsUInt31Class = findClass('JSUInt31'),
        jsDoubleClass = findClass('JSDouble'),
        jsNumberClass = findClass('JSNumber'),
        jsNullClass = findClass('JSNull'),
        jsBoolClass = findClass('JSBool'),
        jsMutableArrayClass = findClass('JSMutableArray'),
        jsFixedArrayClass = findClass('JSFixedArray'),
        jsExtendableArrayClass = findClass('JSExtendableArray'),
        jsPlainJavaScriptObjectClass = findClass('PlainJavaScriptObject'),
        jsUnknownJavaScriptObjectClass = findClass('UnknownJavaScriptObject'),
      ];

      jsIndexableClass = findClass('JSIndexable');
      jsMutableIndexableClass = findClass('JSMutableIndexable');
    } else if (uri == Compiler.DART_JS_HELPER) {
      typeLiteralClass = findClass('TypeImpl');
      constMapLiteralClass = findClass('ConstantMap');
      typeVariableClass = findClass('TypeVariable');

      jsIndexingBehaviorInterface = findClass('JavaScriptIndexingBehavior');

      noSideEffectsClass = findClass('NoSideEffects');
      noThrowsClass = findClass('NoThrows');
      noInlineClass = findClass('NoInline');
      irRepresentationClass = findClass('IrRepresentation');
    } else if (uri == DART_JS_MIRRORS) {
      disableTreeShakingMarker = library.find('disableTreeShaking');
      preserveMetadataMarker = library.find('preserveMetadata');
    } else if (uri == DART_JS_NAMES) {
      preserveNamesMarker = library.find('preserveNames');
    } else if (uri == Compiler.DART_JS_HELPER) {
      getIsolateAffinityTagMarker = library.find('getIsolateAffinityTag');
    }
  }

  Future onLibrariesLoaded(Map<Uri, LibraryElement> loadedLibraries) {
    if (!loadedLibraries.containsKey(Compiler.DART_CORE)) {
      return new Future.value();
    }
    assert(loadedLibraries.containsKey(Compiler.DART_CORE));
    assert(loadedLibraries.containsKey(Compiler.DART_INTERCEPTORS));
    assert(loadedLibraries.containsKey(Compiler.DART_JS_HELPER));

    // [LinkedHashMap] is reexported from dart:collection and can therefore not
    // be loaded from dart:core in [onLibraryScanned].
    mapLiteralClass = compiler.coreLibrary.find('LinkedHashMap');

    implementationClasses = <ClassElement, ClassElement>{};
    implementationClasses[compiler.intClass] = jsIntClass;
    implementationClasses[compiler.boolClass] = jsBoolClass;
    implementationClasses[compiler.numClass] = jsNumberClass;
    implementationClasses[compiler.doubleClass] = jsDoubleClass;
    implementationClasses[compiler.stringClass] = jsStringClass;
    implementationClasses[compiler.listClass] = jsArrayClass;
    implementationClasses[compiler.nullClass] = jsNullClass;

    // These methods are overwritten with generated versions.
    inlineCache.markAsNonInlinable(getInterceptorMethod, insideLoop: true);

    // TODO(kasperl): Some tests do not define the special JSArray
    // subclasses, so we check to see if they are defined before
    // trying to resolve them.
    if (jsFixedArrayClass != null) {
      jsFixedArrayClass.ensureResolved(compiler);
    }
    if (jsExtendableArrayClass != null) {
      jsExtendableArrayClass.ensureResolved(compiler);
    }

    jsIndexableClass.ensureResolved(compiler);
    jsIndexableLength = compiler.lookupElementIn(
        jsIndexableClass, 'length');
    if (jsIndexableLength != null && jsIndexableLength.isAbstractField) {
      AbstractFieldElement element = jsIndexableLength;
      jsIndexableLength = element.getter;
    }

    jsArrayClass.ensureResolved(compiler);
    jsArrayTypedConstructor = compiler.lookupElementIn(jsArrayClass, 'typed');
    jsArrayRemoveLast = compiler.lookupElementIn(jsArrayClass, 'removeLast');
    jsArrayAdd = compiler.lookupElementIn(jsArrayClass, 'add');

    jsStringClass.ensureResolved(compiler);
    jsStringSplit = compiler.lookupElementIn(jsStringClass, 'split');
    jsStringOperatorAdd = compiler.lookupElementIn(jsStringClass, '+');
    jsStringToString = compiler.lookupElementIn(jsStringClass, 'toString');

    objectEquals = compiler.lookupElementIn(compiler.objectClass, '==');

    specialOperatorEqClasses
        ..add(compiler.objectClass)
        ..add(jsInterceptorClass)
        ..add(jsNullClass);

    indexablePrimitiveType = new TypeMask.nonNullSubtype(jsIndexableClass);
    readableArrayType = new TypeMask.nonNullSubclass(jsArrayClass);
    mutableArrayType = new TypeMask.nonNullSubclass(jsMutableArrayClass);
    fixedArrayType = new TypeMask.nonNullExact(jsFixedArrayClass);
    extendableArrayType = new TypeMask.nonNullExact(jsExtendableArrayClass);
    nonNullType = compiler.typesTask.dynamicType.nonNullable();

    validateInterceptorImplementsAllObjectMethods(jsInterceptorClass);
    // The null-interceptor must also implement *all* methods.
    validateInterceptorImplementsAllObjectMethods(jsNullClass);
    return new Future.value();
  }

  void registerMirrorUsage(Set<String> symbols,
                           Set<Element> targets,
                           Set<Element> metaTargets) {
    if (symbols == null && targets == null && metaTargets == null) {
      // The user didn't specify anything, or there are imports of
      // 'dart:mirrors' without @MirrorsUsed.
      hasInsufficientMirrorsUsed = true;
      return;
    }
    if (symbols != null) symbolsUsed.addAll(symbols);
    if (targets != null) {
      for (Element target in targets) {
        if (target.isAbstractField) {
          AbstractFieldElement field = target;
          targetsUsed.add(field.getter);
          targetsUsed.add(field.setter);
        } else {
          targetsUsed.add(target);
        }
      }
    }
    if (metaTargets != null) metaTargetsUsed.addAll(metaTargets);
  }

  /**
   * Returns `true` if [element] can be accessed through reflection, that is,
   * is in the set of elements covered by a `MirrorsUsed` annotation.
   *
   * This property is used to tag emitted elements with a marker which is
   * checked by the runtime system to throw an exception if an element is
   * accessed (invoked, get, set) that is not accessible for the reflective
   * system.
   */
  bool isAccessibleByReflection(Element element) {
    // TODO(ahe): This isn't sufficient: simply importing dart:mirrors
    // causes hasInsufficientMirrorsUsed to become true.
    if (hasInsufficientMirrorsUsed) return true;
    return isNeededForReflection(element);
  }

  /**
   * Returns `true` if the emitter must emit the element even though there
   * is no direct use in the program, but because the reflective system may
   * need to access it.
   */
  bool isNeededForReflection(Element element) {
    if (!isTreeShakingDisabled) return false;
    element = getDartClass(element);
    if (hasInsufficientMirrorsUsed) return isTreeShakingDisabled;
    /// Record the name of [element] in [symbolsUsed]. Return true for
    /// convenience.
    bool registerNameOf(Element element) {
      symbolsUsed.add(element.name);
      if (element.isConstructor) {
        symbolsUsed.add(element.enclosingClass.name);
      }
      return true;
    }

    Element enclosing = element.enclosingElement;
    if (enclosing != null && isNeededForReflection(enclosing)) {
      return registerNameOf(element);
    }

    if (isNeededThroughMetaTarget(element)) {
      return registerNameOf(element);
    }

    if (!targetsUsed.isEmpty && targetsUsed.contains(element)) {
      return registerNameOf(element);
    }

    // TODO(kasperl): Consider caching this information. It is consulted
    // multiple times because of the way we deal with the enclosing element.
    return false;
  }

  /**
   * Returns `true` if the element is needed because it has an annotation
   * of a type that is used as a meta target for reflection.
   */
  bool isNeededThroughMetaTarget(Element element) {
    if (metaTargetsUsed.isEmpty) return false;
    for (Link link = element.metadata; !link.isEmpty; link = link.tail) {
      MetadataAnnotation metadata = link.head;
      // TODO(kasperl): It would be nice if we didn't have to resolve
      // all metadata but only stuff that potentially would match one
      // of the used meta targets.
      metadata.ensureResolved(compiler);
      Constant value = metadata.value;
      if (value == null) continue;
      DartType type = value.computeType(compiler);
      if (metaTargetsUsed.contains(type.element)) return true;
    }
    return false;
  }

  jsAst.Call generateIsJsIndexableCall(jsAst.Expression use1,
                                       jsAst.Expression use2) {
    String dispatchPropertyName = 'init.dispatchPropertyName';

    // We pass the dispatch property record to the isJsIndexable
    // helper rather than reading it inside the helper to increase the
    // chance of making the dispatch record access monomorphic.
    jsAst.PropertyAccess record = new jsAst.PropertyAccess(
        use2, js(dispatchPropertyName));

    List<jsAst.Expression> arguments = <jsAst.Expression>[use1, record];
    FunctionElement helper = compiler.findHelper('isJsIndexable');
    jsAst.Expression helperExpression = namer.elementAccess(helper);
    return new jsAst.Call(helperExpression, arguments);
  }

  bool isTypedArray(TypeMask mask) {
    // Just checking for [:TypedData:] is not sufficient, as it is an
    // abstract class any user-defined class can implement. So we also
    // check for the interface [JavaScriptIndexingBehavior].
    return compiler.typedDataClass != null
        && mask.satisfies(compiler.typedDataClass, compiler)
        && mask.satisfies(jsIndexingBehaviorInterface, compiler);
  }

  bool couldBeTypedArray(TypeMask mask) {
    bool intersects(TypeMask type1, TypeMask type2) =>
        !type1.intersection(type2, compiler).isEmpty;

    return compiler.typedDataClass != null
        && intersects(mask, new TypeMask.subtype(compiler.typedDataClass))
        && intersects(mask, new TypeMask.subtype(jsIndexingBehaviorInterface));
  }

  /// Returns all static fields that are referenced through [targetsUsed].
  /// If the target is a library or class all nested static fields are
  /// included too.
  Iterable<Element> _findStaticFieldTargets() {
    List staticFields = [];

    void addFieldsInContainer(ScopeContainerElement container) {
      container.forEachLocalMember((Element member) {
        if (!member.isInstanceMember && member.isField) {
          staticFields.add(member);
        } else if (member.isClass) {
          addFieldsInContainer(member);
        }
      });
    }

    for (Element target in targetsUsed) {
      if (target == null) continue;
      if (target.isField) {
        staticFields.add(target);
      } else if (target.isLibrary || target.isClass) {
        addFieldsInContainer(target);
      }
    }
    return staticFields;
  }

  /// Called when [enqueuer] is empty, but before it is closed.
  void onQueueEmpty(Enqueuer enqueuer) {
    // Add elements referenced only via custom elements.  Return early if any
    // elements are added to avoid counting the elements as due to mirrors.
    customElementsAnalysis.onQueueEmpty(enqueuer);
    if (!enqueuer.queueIsEmpty) return;

    if (!enqueuer.isResolutionQueue && preMirrorsMethodCount == 0) {
      preMirrorsMethodCount = generatedCode.length;
    }

    if (isTreeShakingDisabled) {
      enqueuer.enqueueEverything();
    } else if (!targetsUsed.isEmpty && enqueuer.isResolutionQueue) {
      // Add all static elements (not classes) that have been requested for
      // reflection. If there is no mirror-usage these are probably not
      // necessary, but the backend relies on them being resolved.
      enqueuer.enqueueReflectiveStaticFields(_findStaticFieldTargets());
    }

    if (mustPreserveNames) compiler.log('Preserving names.');

    if (mustRetainMetadata) {
      compiler.log('Retaining metadata.');

      compiler.libraries.values.forEach(retainMetadataOf);
      for (Dependency dependency in metadataConstants) {
        registerCompileTimeConstant(
            dependency.constant, dependency.registry);
      }
      metadataConstants.clear();
    }
  }

  void onElementResolved(Element element, TreeElements elements) {
    LibraryElement library = element.library;
    if (!library.isPlatformLibrary && !library.canUseNative) return;
    bool hasNoInline = false;
    bool hasNoThrows = false;
    bool hasNoSideEffects = false;
    for (MetadataAnnotation metadata in element.metadata) {
      metadata.ensureResolved(compiler);
      if (!metadata.value.isConstructedObject) continue;
      ObjectConstant value = metadata.value;
      ClassElement cls = value.type.element;
      if (cls == noInlineClass) {
        hasNoInline = true;
        if (VERBOSE_OPTIMIZER_HINTS) {
          compiler.reportHint(element,
              MessageKind.GENERIC,
              {'text': "Cannot inline"});
        }
        inlineCache.markAsNonInlinable(element);
      } else if (cls == noThrowsClass) {
        hasNoThrows = true;
        if (!Elements.isStaticOrTopLevelFunction(element)) {
          compiler.internalError(element,
              "@NoThrows() is currently limited to top-level"
              " or static functions");
        }
        if (VERBOSE_OPTIMIZER_HINTS) {
          compiler.reportHint(element,
              MessageKind.GENERIC,
              {'text': "Cannot throw"});
        }
        compiler.world.registerCannotThrow(element);
      } else if (cls == noSideEffectsClass) {
        hasNoSideEffects = true;
        if (VERBOSE_OPTIMIZER_HINTS) {
          compiler.reportHint(element,
              MessageKind.GENERIC,
              {'text': "Has no side effects"});
        }
        compiler.world.registerSideEffectsFree(element);
      }
    }
    if (hasNoThrows && !hasNoInline) {
      compiler.internalError(element,
          "@NoThrows() should always be combined with @NoInline.");
    }
    if (hasNoSideEffects && !hasNoInline) {
      compiler.internalError(element,
          "@NoSideEffects() should always be combined with @NoInline.");
    }
  }

  CodeBuffer codeOf(Element element) {
    return generatedCode.containsKey(element)
        ? jsAst.prettyPrint(generatedCode[element], compiler)
        : null;
  }
}

/// Records that [constant] is used by the element behind [registry].
class Dependency {
  final Constant constant;
  // TODO(johnniwinther): Change to [Element] when dependency nodes are added.
  final Registry registry;

  const Dependency(this.constant, this.registry);
}
