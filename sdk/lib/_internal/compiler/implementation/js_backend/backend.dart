// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of js_backend;

class JavaScriptItemCompilationContext extends ItemCompilationContext {
  final Set<HInstruction> boundsChecked;

  JavaScriptItemCompilationContext()
      : boundsChecked = new Set<HInstruction>();
}

class CheckedModeHelper {
  final SourceString name;

  const CheckedModeHelper(SourceString this.name);

  Element getElement(Compiler compiler) => compiler.findHelper(name);

  jsAst.Expression generateCall(SsaCodeGenerator codegen,
                                HTypeConversion node) {
    Element helperElement = getElement(codegen.compiler);
    codegen.world.registerStaticUse(helperElement);
    List<jsAst.Expression> arguments = <jsAst.Expression>[];
    codegen.use(node.checkedInput);
    arguments.add(codegen.pop());
    generateAdditionalArguments(codegen, node, arguments);
    String helperName = codegen.backend.namer.isolateAccess(helperElement);
    return new jsAst.Call(new jsAst.VariableUse(helperName), arguments);
  }

  void generateAdditionalArguments(SsaCodeGenerator codegen,
                                   HTypeConversion node,
                                   List<jsAst.Expression> arguments) {
    assert(!node.typeExpression.isMalformed);
    // No additional arguments needed.
  }
}

class PropertyCheckedModeHelper extends CheckedModeHelper {
  const PropertyCheckedModeHelper(SourceString name) : super(name);

  void generateAdditionalArguments(SsaCodeGenerator codegen,
                                   HTypeConversion node,
                                   List<jsAst.Expression> arguments) {
    DartType type = node.typeExpression;
    assert(!type.isMalformed);
    String additionalArgument = codegen.backend.namer.operatorIsType(type);
    arguments.add(js.string(additionalArgument));
  }
}

class TypeVariableCheckedModeHelper extends CheckedModeHelper {
  const TypeVariableCheckedModeHelper(SourceString name) : super(name);

  void generateAdditionalArguments(SsaCodeGenerator codegen,
                                   HTypeConversion node,
                                   List<jsAst.Expression> arguments) {
    assert(node.typeExpression.kind == TypeKind.TYPE_VARIABLE);
    codegen.use(node.typeRepresentation);
    arguments.add(codegen.pop());
  }
}

class SubtypeCheckedModeHelper extends CheckedModeHelper {
  const SubtypeCheckedModeHelper(SourceString name) : super(name);

  void generateAdditionalArguments(SsaCodeGenerator codegen,
                                   HTypeConversion node,
                                   List<jsAst.Expression> arguments) {
    DartType type = node.typeExpression;
    Element element = type.element;
    String isField = codegen.backend.namer.operatorIs(element);
    arguments.add(js.string(isField));
    codegen.use(node.typeRepresentation);
    arguments.add(codegen.pop());
    String asField = codegen.backend.namer.substitutionName(element);
    arguments.add(js.string(asField));
  }
}

class FunctionTypeCheckedModeHelper extends CheckedModeHelper {
  const FunctionTypeCheckedModeHelper(SourceString name) : super(name);

  void generateAdditionalArguments(SsaCodeGenerator codegen,
                                   HTypeConversion node,
                                   List<jsAst.Expression> arguments) {
    DartType type = node.typeExpression;
    String signatureName = codegen.backend.namer.getFunctionTypeName(type);
    arguments.add(js.string(signatureName));

    if (type.containsTypeVariables) {
      ClassElement contextClass = Types.getClassContext(type);
      String contextName = codegen.backend.namer.getName(contextClass);
      arguments.add(js.string(contextName));

      if (node.contextIsTypeArguments) {
        arguments.add(new jsAst.LiteralNull());
        codegen.use(node.context);
        arguments.add(codegen.pop());
      } else {
        codegen.use(node.context);
        arguments.add(codegen.pop());
      }
    }
  }
}

class MalformedCheckedModeHelper extends CheckedModeHelper {
  const MalformedCheckedModeHelper(SourceString name) : super(name);

  void generateAdditionalArguments(SsaCodeGenerator codegen,
                                   HTypeConversion node,
                                   List<jsAst.Expression> arguments) {
    DartType type = node.typeExpression;
    assert(type.isMalformed);
    String reasons = Types.fetchReasonsFromMalformedType(type);
    arguments.add(js.string('$type'));
    // TODO(johnniwinther): Handle escaping correctly.
    arguments.add(js.string(reasons));
  }
}


class JavaScriptBackend extends Backend {
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

  /**
   * The generated code as a js AST for compiled bailout methods.
   */
  final Map<Element, jsAst.Expression> generatedBailoutCode =
      new Map<Element, jsAst.Expression>();

  /**
   * Keep track of which function elements are simple enough to be
   * inlined in callers.
   */
  final Map<FunctionElement, bool> canBeInlined =
      new Map<FunctionElement, bool>();

  ClassElement jsInterceptorClass;
  ClassElement jsStringClass;
  ClassElement jsArrayClass;
  ClassElement jsNumberClass;
  ClassElement jsIntClass;
  ClassElement jsDoubleClass;
  ClassElement jsNullClass;
  ClassElement jsBoolClass;
  ClassElement jsUnknownClass;

  ClassElement jsIndexableClass;
  ClassElement jsMutableIndexableClass;

  ClassElement jsMutableArrayClass;
  ClassElement jsFixedArrayClass;
  ClassElement jsExtendableArrayClass;

  Element jsIndexableLength;
  Element jsArrayRemoveLast;
  Element jsArrayAdd;
  Element jsStringSplit;
  Element jsStringConcat;
  Element jsStringToString;
  Element objectEquals;

  ClassElement typeLiteralClass;
  ClassElement mapLiteralClass;
  ClassElement constMapLiteralClass;

  Element getInterceptorMethod;
  Element interceptedNames;

  HType stringType;
  HType indexablePrimitiveType;
  HType readableArrayType;
  HType mutableArrayType;
  HType fixedArrayType;
  HType extendableArrayType;

  // TODO(9577): Make it so that these are not needed when there are no native
  // classes.
  Element dispatchPropertyName;
  Element getNativeInterceptorMethod;
  Element defineNativeMethodsFinishMethod;
  Element getDispatchPropertyMethod;
  Element setDispatchPropertyMethod;
  Element initializeDispatchPropertyMethod;
  bool needToInitializeDispatchProperty = false;

  bool seenAnyClass = false;

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
  final Map<SourceString, Set<Element>> interceptedElements;
  // TODO(sra): Not all methods in the Set always require an interceptor.  A
  // method may be mixed into a true interceptor *and* a plain class. For the
  // method to work on the interceptor class it needs to use the explicit
  // receiver.  This constrains the call on a known plain receiver to pass the
  // explicit receiver.  https://code.google.com/p/dart/issues/detail?id=8942

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
  final Set<ClassElement> interceptedClasses = new Set<ClassElement>();

  /**
   * Set of classes used as mixins on native classes.  Methods on these classes
   * might also be mixed in to non-native classes.
   */
  final Set<ClassElement> classesMixedIntoNativeClasses =
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

  /// List of instantiated types from metadata.  If metadata must be preserved,
  /// these types must registered.
  final List<Dependency> metadataInstantiatedTypes = <Dependency>[];

  /// List of elements used from metadata.  If metadata must be preserved,
  /// these elements must be compiled.
  final List<Element> metadataStaticUse = <Element>[];

  /// List of tear-off functions referenced from metadata.  If metadata must be
  /// preserved, these elements must be compiled.
  final List<FunctionElement> metadataGetOfStaticFunction = <FunctionElement>[];

  JavaScriptBackend(Compiler compiler, bool generateSourceMap, bool disableEval)
      : namer = determineNamer(compiler),
        oneShotInterceptors = new Map<String, Selector>(),
        interceptedElements = new Map<SourceString, Set<Element>>(),
        rti = new RuntimeTypes(compiler),
        specializedGetInterceptors = new Map<String, Set<ClassElement>>(),
        super(compiler, JAVA_SCRIPT_CONSTANT_SYSTEM) {
    emitter = disableEval
        ? new CodeEmitterNoEvalTask(compiler, namer, generateSourceMap)
        : new CodeEmitterTask(compiler, namer, generateSourceMap);
    builder = new SsaBuilderTask(this);
    optimizer = new SsaOptimizerTask(this);
    generator = new SsaCodeGeneratorTask(this);
  }

  static Namer determineNamer(Compiler compiler) {
    return compiler.enableMinification ?
        new MinifyNamer(compiler) :
        new Namer(compiler);
  }

  bool isInterceptorClass(ClassElement element) {
    if (element == null) return false;
    if (element.isNative()) return true;
    if (interceptedClasses.contains(element)) return true;
    if (classesMixedIntoNativeClasses.contains(element)) return true;
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
    return element.isInstanceMember()
        && !element.isGenerativeConstructorBody()
        && interceptedElements[element.name] != null;
  }

  bool fieldHasInterceptedGetter(Element element) {
    assert(element.isField());
    return interceptedElements[element.name] != null;
  }

  bool fieldHasInterceptedSetter(Element element) {
    assert(element.isField());
    return interceptedElements[element.name] != null;
  }

  bool isInterceptedName(SourceString name) {
    return interceptedElements[name] != null;
  }

  bool isInterceptedSelector(Selector selector) {
    return interceptedElements[selector.name] != null;
  }

  final Map<SourceString, Set<ClassElement>> interceptedClassesCache =
      new Map<SourceString, Set<ClassElement>>();

  /**
   * Returns a set of interceptor classes that contain a member named
   * [name]. Returns [:null:] if there is no class.
   */
  Set<ClassElement> getInterceptedClassesOn(SourceString name) {
    Set<Element> intercepted = interceptedElements[name];
    if (intercepted == null) return null;
    return interceptedClassesCache.putIfAbsent(name, () {
      // Populate the cache by running through all the elements and
      // determine if the given selector applies to them.
      Set<ClassElement> result = new Set<ClassElement>();
      for (Element element in intercepted) {
        ClassElement classElement = element.getEnclosingClass();
        if (classElement.isNative()
            || interceptedClasses.contains(classElement)) {
          result.add(classElement);
        }
        if (classesMixedIntoNativeClasses.contains(classElement)) {
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
          if (subclass.isNative()) {
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
        operatorEqfunction.getEnclosingClass());
  }

  void initializeHelperClasses() {
    getInterceptorMethod =
        compiler.findInterceptor(const SourceString('getInterceptor'));
    interceptedNames =
        compiler.findInterceptor(const SourceString('interceptedNames'));
    dispatchPropertyName =
        compiler.findInterceptor(const SourceString('dispatchPropertyName'));
    getDispatchPropertyMethod =
        compiler.findInterceptor(const SourceString('getDispatchProperty'));
    setDispatchPropertyMethod =
        compiler.findInterceptor(const SourceString('setDispatchProperty'));
    getNativeInterceptorMethod =
        compiler.findInterceptor(const SourceString('getNativeInterceptor'));
    initializeDispatchPropertyMethod =
        compiler.findInterceptor(
            new SourceString(emitter.nameOfDispatchPropertyInitializer));
    defineNativeMethodsFinishMethod =
        compiler.findHelper(const SourceString('defineNativeMethodsFinish'));

    // These methods are overwritten with generated versions.
    canBeInlined[getInterceptorMethod] = false;
    canBeInlined[getDispatchPropertyMethod] = false;
    canBeInlined[setDispatchPropertyMethod] = false;

    List<ClassElement> classes = [
      jsInterceptorClass =
          compiler.findInterceptor(const SourceString('Interceptor')),
      jsStringClass = compiler.findInterceptor(const SourceString('JSString')),
      jsArrayClass = compiler.findInterceptor(const SourceString('JSArray')),
      // The int class must be before the double class, because the
      // emitter relies on this list for the order of type checks.
      jsIntClass = compiler.findInterceptor(const SourceString('JSInt')),
      jsDoubleClass = compiler.findInterceptor(const SourceString('JSDouble')),
      jsNumberClass = compiler.findInterceptor(const SourceString('JSNumber')),
      jsNullClass = compiler.findInterceptor(const SourceString('JSNull')),
      jsBoolClass = compiler.findInterceptor(const SourceString('JSBool')),
      jsMutableArrayClass =
          compiler.findInterceptor(const SourceString('JSMutableArray')),
      jsFixedArrayClass =
          compiler.findInterceptor(const SourceString('JSFixedArray')),
      jsExtendableArrayClass =
          compiler.findInterceptor(const SourceString('JSExtendableArray')),
      jsUnknownClass =
          compiler.findInterceptor(const SourceString('JSUnknown')),
    ];

    jsIndexableClass =
        compiler.findInterceptor(const SourceString('JSIndexable'));
    jsMutableIndexableClass =
        compiler.findInterceptor(const SourceString('JSMutableIndexable'));

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
        jsIndexableClass, const SourceString('length'));
    if (jsIndexableLength != null && jsIndexableLength.isAbstractField()) {
      AbstractFieldElement element = jsIndexableLength;
      jsIndexableLength = element.getter;
    }

    jsArrayClass.ensureResolved(compiler);
    jsArrayRemoveLast = compiler.lookupElementIn(
        jsArrayClass, const SourceString('removeLast'));
    jsArrayAdd = compiler.lookupElementIn(
        jsArrayClass, const SourceString('add'));

    jsStringClass.ensureResolved(compiler);
    jsStringSplit = compiler.lookupElementIn(
        jsStringClass, const SourceString('split'));
    jsStringConcat = compiler.lookupElementIn(
        jsStringClass, const SourceString('concat'));
    jsStringToString = compiler.lookupElementIn(
        jsStringClass, const SourceString('toString'));

    for (ClassElement cls in classes) {
      if (cls != null) interceptedClasses.add(cls);
    }

    typeLiteralClass = compiler.findHelper(const SourceString('TypeImpl'));
    mapLiteralClass =
        compiler.coreLibrary.find(const SourceString('LinkedHashMap'));
    constMapLiteralClass =
        compiler.findHelper(const SourceString('ConstantMap'));

    objectEquals = compiler.lookupElementIn(
        compiler.objectClass, const SourceString('=='));

    specialOperatorEqClasses
        ..add(compiler.objectClass)
        ..add(jsInterceptorClass)
        ..add(jsNullClass);

    validateInterceptorImplementsAllObjectMethods(jsInterceptorClass);

    stringType = new HBoundedType(
        new TypeMask.nonNullExact(jsStringClass.rawType));
    indexablePrimitiveType = new HBoundedType(
        new TypeMask.nonNullSubtype(jsIndexableClass.rawType));
    readableArrayType = new HBoundedType(
        new TypeMask.nonNullSubclass(jsArrayClass.rawType));
    mutableArrayType = new HBoundedType(
        new TypeMask.nonNullSubclass(jsMutableArrayClass.rawType));
    fixedArrayType = new HBoundedType(
        new TypeMask.nonNullExact(jsFixedArrayClass.rawType));
    extendableArrayType = new HBoundedType(
        new TypeMask.nonNullExact(jsExtendableArrayClass.rawType));
  }

  void validateInterceptorImplementsAllObjectMethods(
      ClassElement interceptorClass) {
    if (interceptorClass == null) return;
    interceptorClass.ensureResolved(compiler);
    compiler.objectClass.forEachMember((_, Element member) {
      if (member.isGenerativeConstructor()) return;
      Element interceptorMember = interceptorClass.lookupMember(member.name);
      // Interceptors must override all Object methods due to calling convention
      // differences.
      assert(interceptorMember.getEnclosingClass() != compiler.objectClass);
    });
  }

  void addInterceptorsForNativeClassMembers(
      ClassElement cls, Enqueuer enqueuer) {
    if (enqueuer.isResolutionQueue) {
      cls.ensureResolved(compiler);
      cls.forEachMember((ClassElement classElement, Element member) {
        if (member.isSynthesized) return;
        // All methods on [Object] are shadowed by [Interceptor].
        if (classElement == compiler.objectClass) return;
        Set<Element> set = interceptedElements.putIfAbsent(
            member.name, () => new Set<Element>());
        set.add(member);
        if (classElement == jsInterceptorClass) return;
        if (!classElement.isNative()) {
          MixinApplicationElement mixinApplication = classElement;
          assert(member.getEnclosingClass() == mixinApplication.mixin);
          classesMixedIntoNativeClasses.add(mixinApplication.mixin);
        }
      },
      includeSuperAndInjectedMembers: true);
    }
  }

  void addInterceptors(ClassElement cls,
                       Enqueuer enqueuer,
                       TreeElements elements) {
    if (enqueuer.isResolutionQueue) {
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
    enqueuer.registerInstantiatedClass(cls, elements);
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

  void registerInstantiatedClass(ClassElement cls,
                                 Enqueuer enqueuer,
                                 TreeElements elements) {
    if (!seenAnyClass) {
      seenAnyClass = true;
      if (enqueuer.isResolutionQueue) {
        // TODO(9577): Make it so that these are not needed when there are no
        // native classes.
        enqueuer.registerStaticUse(getNativeInterceptorMethod);
        enqueuer.registerStaticUse(defineNativeMethodsFinishMethod);
        enqueuer.registerStaticUse(initializeDispatchPropertyMethod);
        enqueuer.registerInstantiatedClass(jsInterceptorClass,
                                           compiler.globalDependencies);
      }
    }

    // Register any helper that will be needed by the backend.
    if (enqueuer.isResolutionQueue) {
      if (cls == compiler.intClass
          || cls == compiler.doubleClass
          || cls == compiler.numClass) {
        // The backend will try to optimize number operations and use the
        // `iae` helper directly.
        enqueuer.registerStaticUse(
            compiler.findHelper(const SourceString('iae')));
      } else if (cls == compiler.listClass
                 || cls == compiler.stringClass) {
        // The backend will try to optimize array and string access and use the
        // `ioore` and `iae` helpers directly.
        enqueuer.registerStaticUse(
            compiler.findHelper(const SourceString('ioore')));
        enqueuer.registerStaticUse(
            compiler.findHelper(const SourceString('iae')));
      } else if (cls == compiler.functionClass) {
        enqueuer.registerInstantiatedClass(compiler.closureClass, elements);
      } else if (cls == compiler.mapClass) {
        // The backend will use a literal list to initialize the entries
        // of the map.
        enqueuer.registerInstantiatedClass(compiler.listClass, elements);
        enqueuer.registerInstantiatedClass(mapLiteralClass, elements);
        enqueueInResolution(getMapMaker(), elements);
      }
    }
    ClassElement result = null;
    if (cls == compiler.stringClass || cls == jsStringClass) {
      addInterceptors(jsStringClass, enqueuer, elements);
    } else if (cls == compiler.listClass
               || cls == jsArrayClass
               || cls == jsFixedArrayClass
               || cls == jsExtendableArrayClass) {
      addInterceptors(jsArrayClass, enqueuer, elements);
      enqueuer.registerInstantiatedClass(jsFixedArrayClass, elements);
      enqueuer.registerInstantiatedClass(jsExtendableArrayClass, elements);
    } else if (cls == compiler.intClass || cls == jsIntClass) {
      addInterceptors(jsIntClass, enqueuer, elements);
      addInterceptors(jsNumberClass, enqueuer, elements);
    } else if (cls == compiler.doubleClass || cls == jsDoubleClass) {
      addInterceptors(jsDoubleClass, enqueuer, elements);
      addInterceptors(jsNumberClass, enqueuer, elements);
    } else if (cls == compiler.boolClass || cls == jsBoolClass) {
      addInterceptors(jsBoolClass, enqueuer, elements);
    } else if (cls == compiler.nullClass || cls == jsNullClass) {
      addInterceptors(jsNullClass, enqueuer, elements);
    } else if (cls == compiler.numClass || cls == jsNumberClass) {
      addInterceptors(jsIntClass, enqueuer, elements);
      addInterceptors(jsDoubleClass, enqueuer, elements);
      addInterceptors(jsNumberClass, enqueuer, elements);
    } else if (cls == jsUnknownClass) {
      addInterceptors(jsUnknownClass, enqueuer, elements);
    } else if (cls.isNative()) {
      addInterceptorsForNativeClassMembers(cls, enqueuer);
    }
  }

  void registerUseInterceptor(Enqueuer enqueuer) {
    assert(!enqueuer.isResolutionQueue);
    if (!enqueuer.nativeEnqueuer.hasNativeClasses()) return;
    enqueuer.registerStaticUse(getNativeInterceptorMethod);
    enqueuer.registerStaticUse(defineNativeMethodsFinishMethod);
    enqueuer.registerStaticUse(initializeDispatchPropertyMethod);
    TreeElements elements = compiler.globalDependencies;
    enqueuer.registerInstantiatedClass(jsInterceptorClass, elements);
    needToInitializeDispatchProperty = true;
  }

  JavaScriptItemCompilationContext createItemCompilationContext() {
    return new JavaScriptItemCompilationContext();
  }

  void enqueueHelpers(ResolutionEnqueuer world, TreeElements elements) {
    jsIndexingBehaviorInterface =
        compiler.findHelper(const SourceString('JavaScriptIndexingBehavior'));
    if (jsIndexingBehaviorInterface != null) {
      world.registerIsCheck(jsIndexingBehaviorInterface.computeType(compiler),
                            elements);
      world.registerStaticUse(
          compiler.findHelper(const SourceString('isJsIndexable')));
      world.registerStaticUse(
          compiler.findInterceptor(const SourceString('dispatchPropertyName')));
    }

    if (compiler.enableTypeAssertions) {
      // Unconditionally register the helper that checks if the
      // expression in an if/while/for is a boolean.
      // TODO(ngeoffray): Should we have the resolver register those instead?
      Element e =
          compiler.findHelper(const SourceString('boolConversionCheck'));
      if (e != null) world.addToWorkList(e);
    }
  }

  onResolutionComplete() => rti.computeClassesNeedingRti();

  void registerStringInterpolation(TreeElements elements) {
    enqueueInResolution(getStringInterpolationHelper(), elements);
  }

  void registerCatchStatement(Enqueuer enqueuer, TreeElements elements) {
    enqueueInResolution(getExceptionUnwrapper(), elements);
    if (jsUnknownClass != null) {
      enqueuer.registerInstantiatedClass(jsUnknownClass, elements);
    }
  }

  void registerWrapException(TreeElements elements) {
    enqueueInResolution(getWrapExceptionHelper(), elements);
  }

  void registerThrowExpression(TreeElements elements) {
    enqueueInResolution(getThrowExpressionHelper(), elements);
  }

  void registerLazyField(TreeElements elements) {
    enqueueInResolution(getCyclicThrowHelper(), elements);
  }

  void registerTypeLiteral(Element element, TreeElements elements) {
    enqueueInResolution(getCreateRuntimeType(), elements);
    // TODO(ahe): Might want to register [element] as an instantiated class
    // when reflection is used.  However, as long as we disable tree-shaking
    // eagerly it doesn't matter.
  }

  void registerStackTraceInCatch(TreeElements elements) {
    enqueueInResolution(getTraceFromException(), elements);
  }

  void registerSetRuntimeType(TreeElements elements) {
    enqueueInResolution(getSetRuntimeTypeInfo(), elements);
  }

  void registerGetRuntimeTypeArgument(TreeElements elements) {
    enqueueInResolution(getGetRuntimeTypeArgument(), elements);
  }

  void registerGenericCallMethod(Element callMethod,
                                 Enqueuer enqueuer, TreeElements elements) {
    if (enqueuer.isResolutionQueue || methodNeedsRti(callMethod)) {
      registerComputeSignature(enqueuer, elements);
    }
  }

  void registerGenericClosure(Element closure,
                              Enqueuer enqueuer, TreeElements elements) {
    if (enqueuer.isResolutionQueue || methodNeedsRti(closure)) {
      registerComputeSignature(enqueuer, elements);
    }
  }

  void registerComputeSignature(Enqueuer enqueuer, TreeElements elements) {
    // Calls to [:computeSignature:] are generated by the emitter and we
    // therefore need to enqueue the used elements in the codegen enqueuer as
    // well as in the resolution enqueuer.
    enqueue(enqueuer, getSetRuntimeTypeInfo(), elements);
    enqueue(enqueuer, getGetRuntimeTypeInfo(), elements);
    enqueue(enqueuer, getComputeSignature(), elements);
    enqueue(enqueuer, getGetRuntimeTypeArguments(), elements);
    enqueuer.registerInstantiatedClass(compiler.listClass, elements);
  }

  void registerRuntimeType(Enqueuer enqueuer, TreeElements elements) {
    registerComputeSignature(enqueuer, elements);
    enqueueInResolution(getSetRuntimeTypeInfo(), elements);
    enqueueInResolution(getGetRuntimeTypeInfo(), elements);
    registerGetRuntimeTypeArgument(elements);
    compiler.enqueuer.resolution.registerInstantiatedClass(
        compiler.listClass, elements);
  }

  void registerTypeVariableExpression(TreeElements elements) {
    enqueueInResolution(getSetRuntimeTypeInfo(), elements);
    enqueueInResolution(getGetRuntimeTypeInfo(), elements);
    registerGetRuntimeTypeArgument(elements);
    compiler.enqueuer.resolution.registerInstantiatedClass(
        compiler.listClass, elements);
    enqueueInResolution(getRuntimeTypeToString(), elements);
    enqueueInResolution(getCreateRuntimeType(), elements);
  }

  void registerIsCheck(DartType type, Enqueuer world, TreeElements elements) {
    type = type.unalias(compiler);
    world.registerInstantiatedClass(compiler.boolClass, elements);
    bool inCheckedMode = compiler.enableTypeAssertions;
    // [registerIsCheck] is also called for checked mode checks, so we
    // need to register checked mode helpers.
    if (inCheckedMode) {
      CheckedModeHelper helper = getCheckedModeHelper(type, typeCast: false);
      if (helper != null) world.addToWorkList(helper.getElement(compiler));
      // We also need the native variant of the check (for DOM types).
      helper = getNativeCheckedModeHelper(type, typeCast: false);
      if (helper != null) world.addToWorkList(helper.getElement(compiler));
      if (type.isMalformed) {
        enqueueInResolution(getThrowMalformedSubtypeError(), elements);
        return;
      }
    } else if (type.isMalformed) {
      registerThrowRuntimeError(elements);
      return;
    }
    bool isTypeVariable = type.kind == TypeKind.TYPE_VARIABLE;
    if (!type.isRaw || type.containsTypeVariables) {
      enqueueInResolution(getSetRuntimeTypeInfo(), elements);
      enqueueInResolution(getGetRuntimeTypeInfo(), elements);
      enqueueInResolution(getGetRuntimeTypeArgument(), elements);
      if (inCheckedMode) {
        enqueueInResolution(getAssertSubtype(), elements);
      }
      enqueueInResolution(getCheckSubtype(), elements);
      if (isTypeVariable) {
        enqueueInResolution(getCheckSubtypeOfRuntimeType(), elements);
        if (inCheckedMode) {
          enqueueInResolution(getAssertSubtypeOfRuntimeType(), elements);
        }
      }
      world.registerInstantiatedClass(compiler.listClass, elements);
    }
    if (type is FunctionType) {
      enqueueInResolution(getCheckFunctionSubtype(), elements);
    }
    if (type.element.isNative()) {
      // We will neeed to add the "$is" and "$as" properties on the
      // JavaScript object prototype, so we make sure
      // [:defineProperty:] is compiled.
      world.addToWorkList(
          compiler.findHelper(const SourceString('defineProperty')));
    }
   }

  void registerAsCheck(DartType type, TreeElements elements) {
    type = type.unalias(compiler);
    CheckedModeHelper helper = getCheckedModeHelper(type, typeCast: true);
    enqueueInResolution(helper.getElement(compiler), elements);
    // We also need the native variant of the check (for DOM types).
    helper = getNativeCheckedModeHelper(type, typeCast: true);
    if (helper != null) {
      enqueueInResolution(helper.getElement(compiler), elements);
    }
  }

  void registerThrowNoSuchMethod(TreeElements elements) {
    enqueueInResolution(getThrowNoSuchMethod(), elements);
  }

  void registerThrowRuntimeError(TreeElements elements) {
    enqueueInResolution(getThrowRuntimeError(), elements);
  }

  void registerAbstractClassInstantiation(TreeElements elements) {
    enqueueInResolution(getThrowAbstractClassInstantiationError(), elements);
  }

  void registerFallThroughError(TreeElements elements) {
    enqueueInResolution(getFallThroughError(), elements);
  }

  void registerSuperNoSuchMethod(TreeElements elements) {
    enqueueInResolution(getCreateInvocationMirror(), elements);
    enqueueInResolution(
        compiler.objectClass.lookupLocalMember(Compiler.NO_SUCH_METHOD),
        elements);
    compiler.enqueuer.resolution.registerInstantiatedClass(
        compiler.listClass, elements);
  }

  void registerRequiredType(DartType type, Element enclosingElement) {
    /**
     * If [argument] has type variables or is a type variable, this
     * method registers a RTI dependency between the class where the
     * type variable is defined (that is the enclosing class of the
     * current element being resolved) and the class of [annotation].
     * If the class of [annotation] requires RTI, then the class of
     * the type variable does too.
     */
    void analyzeTypeArgument(DartType annotation, DartType argument) {
      if (argument == null) return;
      if (argument.element.isTypeVariable()) {
        ClassElement enclosing = argument.element.getEnclosingClass();
        assert(enclosing == enclosingElement.getEnclosingClass().declaration);
        rti.registerRtiDependency(annotation.element, enclosing);
      } else if (argument is InterfaceType) {
        InterfaceType type = argument;
        type.typeArguments.forEach((DartType argument) {
          analyzeTypeArgument(annotation, argument);
        });
      }
    }

    if (type is InterfaceType) {
      InterfaceType itf = type;
      itf.typeArguments.forEach((DartType argument) {
        analyzeTypeArgument(type, argument);
      });
    }
    // TODO(ngeoffray): Also handle T a (in checked mode).
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
    ClassElement classElement = element.getEnclosingClass();
    return classElement == compiler.objectClass
        || classElement == jsInterceptorClass;
  }

  bool isDefaultEqualityImplementation(Element element) {
    assert(element.name == const SourceString('=='));
    ClassElement classElement = element.getEnclosingClass();
    return classElement == compiler.objectClass
        || classElement == jsInterceptorClass
        || classElement == jsNullClass;
  }

  bool methodNeedsRti(FunctionElement function) {
    return rti.methodsNeedingRti.contains(function) ||
           compiler.enabledRuntimeType;
  }

  void enqueue(Enqueuer enqueuer, Element e, TreeElements elements) {
    enqueuer.addToWorkList(e);
    elements.registerDependency(e);
  }

  void enqueueInResolution(Element e, TreeElements elements) {
    if (e == null) return;
    ResolutionEnqueuer enqueuer = compiler.enqueuer.resolution;
    enqueue(enqueuer, e, elements);
  }

  void registerConstantMap(TreeElements elements) {
    Element e = compiler.findHelper(const SourceString('ConstantMap'));
    if (e != null) {
      compiler.enqueuer.resolution.registerInstantiatedClass(e, elements);
    }
    e = compiler.findHelper(const SourceString('ConstantProtoMap'));
    if (e != null) {
      compiler.enqueuer.resolution.registerInstantiatedClass(e, elements);
    }
  }

  void codegen(CodegenWorkItem work) {
    Element element = work.element;
    var kind = element.kind;
    if (kind == ElementKind.TYPEDEF) return;
    if (element.isConstructor() && element.getEnclosingClass() == jsNullClass) {
      // Work around a problem compiling JSNull's constructor.
      return;
    }
    if (kind.category == ElementCategory.VARIABLE) {
      Constant initialValue = compiler.constantHandler.compileWorkItem(work);
      if (initialValue != null) {
        return;
      } else {
        // If the constant-handler was not able to produce a result we have to
        // go through the builder (below) to generate the lazy initializer for
        // the static variable.
        // We also need to register the use of the cyclic-error helper.
        compiler.enqueuer.codegen.registerStaticUse(getCyclicThrowHelper());
      }
    }

    HGraph graph = builder.build(work);
    optimizer.optimize(work, graph, false);
    if (work.allowSpeculativeOptimization
        && optimizer.trySpeculativeOptimizations(work, graph)) {
      jsAst.Expression code = generator.generateBailoutMethod(work, graph);
      generatedBailoutCode[element] = code;
      optimizer.prepareForSpeculativeOptimizations(work, graph);
      optimizer.optimize(work, graph, true);
    }
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
    return element.isNative() ? jsInterceptorClass : compiler.objectClass;
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
  }

  Element getImplementationClass(Element element) {
    if (element == compiler.intClass) {
      return jsIntClass;
    } else if (element == compiler.boolClass) {
      return jsBoolClass;
    } else if (element == compiler.numClass) {
      return jsNumberClass;
    } else if (element == compiler.doubleClass) {
      return jsDoubleClass;
    } else if (element == compiler.stringClass) {
      return jsStringClass;
    } else if (element == compiler.listClass) {
      return jsArrayClass;
    } else {
      return element;
    }
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
    assert(type.kind != TypeKind.TYPEDEF);
    Element element = type.element;
    bool nativeCheck = nativeCheckOnly ||
        emitter.nativeEmitter.requiresNativeIsCheck(element);
    if (type.isMalformed) {
      // Check for malformed types first, because the type may be a list type
      // with a malformed argument type.
      if (nativeCheckOnly) return null;
      return typeCast
          ? const MalformedCheckedModeHelper(
              const SourceString('malformedTypeCast'))
          : const MalformedCheckedModeHelper(
              const SourceString('malformedTypeCheck'));
    } else if (type == compiler.types.voidType) {
      assert(!typeCast); // Cannot cast to void.
      if (nativeCheckOnly) return null;
      return const CheckedModeHelper(const SourceString('voidTypeCheck'));
    } else if (element == jsStringClass || element == compiler.stringClass) {
      if (nativeCheckOnly) return null;
      return typeCast
          ? const CheckedModeHelper(const SourceString("stringTypeCast"))
          : const CheckedModeHelper(const SourceString('stringTypeCheck'));
    } else if (element == jsDoubleClass || element == compiler.doubleClass) {
      if (nativeCheckOnly) return null;
      return typeCast
          ? const CheckedModeHelper(const SourceString("doubleTypeCast"))
          : const CheckedModeHelper(const SourceString('doubleTypeCheck'));
    } else if (element == jsNumberClass || element == compiler.numClass) {
      if (nativeCheckOnly) return null;
      return typeCast
          ? const CheckedModeHelper(const SourceString("numTypeCast"))
          : const CheckedModeHelper(const SourceString('numTypeCheck'));
    } else if (element == jsBoolClass || element == compiler.boolClass) {
      if (nativeCheckOnly) return null;
      return typeCast
          ? const CheckedModeHelper(const SourceString("boolTypeCast"))
          : const CheckedModeHelper(const SourceString('boolTypeCheck'));
    } else if (element == jsIntClass || element == compiler.intClass) {
      if (nativeCheckOnly) return null;
      return typeCast
          ? const CheckedModeHelper(const SourceString("intTypeCast"))
          : const CheckedModeHelper(const SourceString('intTypeCheck'));
    } else if (Elements.isNumberOrStringSupertype(element, compiler)) {
      if (nativeCheck) {
        return typeCast
            ? const PropertyCheckedModeHelper(
                const SourceString("numberOrStringSuperNativeTypeCast"))
            : const PropertyCheckedModeHelper(
                const SourceString('numberOrStringSuperNativeTypeCheck'));
      } else {
        return typeCast
          ? const PropertyCheckedModeHelper(
              const SourceString("numberOrStringSuperTypeCast"))
          : const PropertyCheckedModeHelper(
              const SourceString('numberOrStringSuperTypeCheck'));
      }
    } else if (Elements.isStringOnlySupertype(element, compiler)) {
      if (nativeCheck) {
        return typeCast
            ? const PropertyCheckedModeHelper(
                const SourceString("stringSuperNativeTypeCast"))
            : const PropertyCheckedModeHelper(
                const SourceString('stringSuperNativeTypeCheck'));
      } else {
        return typeCast
            ? const PropertyCheckedModeHelper(
                const SourceString("stringSuperTypeCast"))
            : const PropertyCheckedModeHelper(
                const SourceString('stringSuperTypeCheck'));
      }
    } else if ((element == compiler.listClass || element == jsArrayClass) &&
               type.isRaw) {
      if (nativeCheckOnly) return null;
      return typeCast
          ? const CheckedModeHelper(const SourceString("listTypeCast"))
          : const CheckedModeHelper(const SourceString('listTypeCheck'));
    } else {
      if (Elements.isListSupertype(element, compiler)) {
        if (nativeCheck) {
          return typeCast
              ? const PropertyCheckedModeHelper(
                  const SourceString("listSuperNativeTypeCast"))
              : const PropertyCheckedModeHelper(
                  const SourceString('listSuperNativeTypeCheck'));
        } else {
          return typeCast
              ? const PropertyCheckedModeHelper(
                  const SourceString("listSuperTypeCast"))
              : const PropertyCheckedModeHelper(
                  const SourceString('listSuperTypeCheck'));
        }
      } else {
        if (nativeCheck) {
          // TODO(karlklose): can we get rid of this branch when we use
          // interceptors?
          return typeCast
              ? const PropertyCheckedModeHelper(
                  const SourceString("interceptedTypeCast"))
              : const PropertyCheckedModeHelper(
                  const SourceString('interceptedTypeCheck'));
        } else {
          if (type.kind == TypeKind.INTERFACE && !type.isRaw) {
            return typeCast
                ? const SubtypeCheckedModeHelper(
                    const SourceString('subtypeCast'))
                : const SubtypeCheckedModeHelper(
                    const SourceString('assertSubtype'));
          } else if (type.kind == TypeKind.TYPE_VARIABLE) {
            return typeCast
                ? const TypeVariableCheckedModeHelper(
                    const SourceString('subtypeOfRuntimeTypeCast'))
                : const TypeVariableCheckedModeHelper(
                    const SourceString('assertSubtypeOfRuntimeType'));
          } else if (type.kind == TypeKind.FUNCTION) {
            return typeCast
                ? const FunctionTypeCheckedModeHelper(
                    const SourceString('functionSubtypeCast'))
                : const FunctionTypeCheckedModeHelper(
                    const SourceString('assertFunctionSubtype'));
          } else {
            return typeCast
                ? const PropertyCheckedModeHelper(
                    const SourceString('propertyTypeCast'))
                : const PropertyCheckedModeHelper(
                    const SourceString('propertyTypeCheck'));
          }
        }
      }
    }
  }

  Element getExceptionUnwrapper() {
    return compiler.findHelper(const SourceString('unwrapException'));
  }

  Element getThrowRuntimeError() {
    return compiler.findHelper(const SourceString('throwRuntimeError'));
  }

  Element getMalformedTypeCheck() {
    return compiler.findHelper(const SourceString('malformedTypeCheck'));
  }

  Element getThrowMalformedSubtypeError() {
    return compiler.findHelper(
        const SourceString('throwMalformedSubtypeError'));
  }

  Element getThrowAbstractClassInstantiationError() {
    return compiler.findHelper(
        const SourceString('throwAbstractClassInstantiationError'));
  }

  Element getStringInterpolationHelper() {
    return compiler.findHelper(const SourceString('S'));
  }

  Element getWrapExceptionHelper() {
    return compiler.findHelper(const SourceString(r'wrapException'));
  }

  Element getThrowExpressionHelper() {
    return compiler.findHelper(const SourceString('throwExpression'));
  }

  Element getClosureConverter() {
    return compiler.findHelper(const SourceString('convertDartClosureToJS'));
  }

  Element getTraceFromException() {
    return compiler.findHelper(const SourceString('getTraceFromException'));
  }

  Element getMapMaker() {
    return compiler.findHelper(const SourceString('makeLiteralMap'));
  }

  Element getSetRuntimeTypeInfo() {
    return compiler.findHelper(const SourceString('setRuntimeTypeInfo'));
  }

  Element getGetRuntimeTypeInfo() {
    return compiler.findHelper(const SourceString('getRuntimeTypeInfo'));
  }

  Element getComputeSignature() {
    return compiler.findHelper(const SourceString('computeSignature'));
  }

  Element getGetRuntimeTypeArguments() {
    return compiler.findHelper(const SourceString('getRuntimeTypeArguments'));
  }

  Element getGetRuntimeTypeArgument() {
    return compiler.findHelper(const SourceString('getRuntimeTypeArgument'));
  }

  Element getRuntimeTypeToString() {
    return compiler.findHelper(const SourceString('runtimeTypeToString'));
  }

  Element getCheckSubtype() {
    return compiler.findHelper(const SourceString('checkSubtype'));
  }

  Element getAssertSubtype() {
    return compiler.findHelper(const SourceString('assertSubtype'));
  }

  Element getCheckSubtypeOfRuntimeType() {
    return compiler.findHelper(const SourceString('checkSubtypeOfRuntimeType'));
  }

  Element getAssertSubtypeOfRuntimeType() {
    return compiler.findHelper(
        const SourceString('assertSubtypeOfRuntimeType'));
  }

  Element getCheckFunctionSubtype() {
    return compiler.findHelper(const SourceString('checkFunctionSubtype'));
  }

  Element getThrowNoSuchMethod() {
    return compiler.findHelper(const SourceString('throwNoSuchMethod'));
  }

  Element getCreateRuntimeType() {
    return compiler.findHelper(const SourceString('createRuntimeType'));
  }

  Element getFallThroughError() {
    return compiler.findHelper(const SourceString("getFallThroughError"));
  }

  Element getCreateInvocationMirror() {
    return compiler.findHelper(Compiler.CREATE_INVOCATION_MIRROR);
  }

  Element getCyclicThrowHelper() {
    return compiler.findHelper(const SourceString("throwCyclicInit"));
  }

  /**
   * Remove [element] from the set of generated code, and put it back
   * into the worklist.
   *
   * Invariant: [element] must be a declaration element.
   */
  void eagerRecompile(Element element) {
    assert(invariant(element, element.isDeclaration));
    generatedCode.remove(element);
    generatedBailoutCode.remove(element);
    compiler.enqueuer.codegen.addToWorkList(element);
  }

  bool isNullImplementation(ClassElement cls) {
    return cls == jsNullClass;
  }

  ClassElement get intImplementation => jsIntClass;
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
      enqueuer.enqueueEverything();
      if (isTreeShakingDisabled) return;
      compiler.disableTypeInferenceForMirrors = true;
      isTreeShakingDisabled = true;
    } else if (element == preserveNamesMarker) {
      if (mustPreserveNames) return;
      mustPreserveNames = true;
      compiler.log('Preserving names.');
    } else if (element == preserveMetadataMarker) {
      if (mustRetainMetadata) return;
      compiler.log('Retaining metadata.');
      mustRetainMetadata = true;
      for (LibraryElement library in compiler.libraries.values) {
        if (retainMetadataOf(library)) {
          for (Link link = library.metadata; !link.isEmpty; link = link.tail) {
            link.head.ensureResolved(compiler);
          }
        }
      }
      for (Dependency dependency in metadataInstantiatedTypes) {
        registerMetadataInstantiatedType(dependency.type, dependency.user);
      }
      metadataInstantiatedTypes.clear();
      for (Element e in metadataStaticUse) {
        registerMetadataStaticUse(e);
      }
      metadataStaticUse.clear();
      for (Element e in metadataGetOfStaticFunction) {
        registerMetadataGetOfStaticFunction(e);
      }
      metadataGetOfStaticFunction.clear();
    }
  }

  /// Called when [:const Symbol(name):] is seen.
  void registerConstSymbol(String name, TreeElements elements) {
  }

  /// Called when [:new Symbol(...):] is seen.
  void registerNewSymbol(TreeElements elements) {
  }

  bool retainGetter(Element element) => isTreeShakingDisabled;

  bool retainSetter(Element element) => isTreeShakingDisabled;

  bool retainName(SourceString name) => mustPreserveNames;

  bool retainMetadataOf(Element element) {
    if (mustRetainMetadata) {
      // TODO(ahe): This is a little hacky, but I'll have to rewrite this when
      // implementing @MirrorsUsed anyways.
      compiler.constantHandler.compiledConstants.addAll(
          compiler.metadataHandler.compiledConstants);
      compiler.metadataHandler.compiledConstants.clear();
    }
    if (mustRetainMetadata) hasRetainedMetadata = true;
    return mustRetainMetadata;
  }

  void onLibraryScanned(LibraryElement library, Uri uri) {
    if (uri == Uri.parse('dart:_js_mirrors')) {
      disableTreeShakingMarker =
          library.find(const SourceString('disableTreeShaking'));
      preserveMetadataMarker =
          library.find(const SourceString('preserveMetadata'));
    } else if (uri == Uri.parse('dart:_js_names')) {
      preserveNamesMarker =
          library.find(const SourceString('preserveNames'));
    }
  }

  void registerMetadataInstantiatedType(DartType type, TreeElements elements) {
    if (mustRetainMetadata) {
      compiler.constantHandler.registerInstantiatedType(type, elements);
    } else {
      metadataInstantiatedTypes.add(new Dependency(type, elements));
    }
  }

  void registerMetadataStaticUse(Element element) {
    if (mustRetainMetadata) {
      compiler.constantHandler.registerStaticUse(element);
    } else {
      metadataStaticUse.add(element);
    }
  }

  void registerMetadataGetOfStaticFunction(FunctionElement element) {
    if (mustRetainMetadata) {
      compiler.constantHandler.registerGetOfStaticFunction(element);
    } else {
      metadataGetOfStaticFunction.add(element);
    }
  }
}

/// Records that [type] is used by [user.element].
class Dependency {
  final DartType type;
  final TreeElements user;

  const Dependency(this.type, this.user);
}
