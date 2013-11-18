// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of js_backend;

class JavaScriptItemCompilationContext extends ItemCompilationContext {
  final Set<HInstruction> boundsChecked = new Set<HInstruction>();
  final Set<HInstruction> allocatedFixedLists = new Set<HInstruction>();
}

class CheckedModeHelper {
  final String name;

  const CheckedModeHelper(String this.name);

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
    // No additional arguments needed.
  }
}

class MalformedCheckedModeHelper extends CheckedModeHelper {
  const MalformedCheckedModeHelper(String name) : super(name);

  void generateAdditionalArguments(SsaCodeGenerator codegen,
                                   HTypeConversion node,
                                   List<jsAst.Expression> arguments) {
    ErroneousElement element = node.typeExpression.element;
    arguments.add(js.string(element.message));
  }
}

class PropertyCheckedModeHelper extends CheckedModeHelper {
  const PropertyCheckedModeHelper(String name) : super(name);

  void generateAdditionalArguments(SsaCodeGenerator codegen,
                                   HTypeConversion node,
                                   List<jsAst.Expression> arguments) {
    DartType type = node.typeExpression;
    String additionalArgument = codegen.backend.namer.operatorIsType(type);
    arguments.add(js.string(additionalArgument));
  }
}

class TypeVariableCheckedModeHelper extends CheckedModeHelper {
  const TypeVariableCheckedModeHelper(String name) : super(name);

  void generateAdditionalArguments(SsaCodeGenerator codegen,
                                   HTypeConversion node,
                                   List<jsAst.Expression> arguments) {
    assert(node.typeExpression.kind == TypeKind.TYPE_VARIABLE);
    codegen.use(node.typeRepresentation);
    arguments.add(codegen.pop());
  }
}

class SubtypeCheckedModeHelper extends CheckedModeHelper {
  const SubtypeCheckedModeHelper(String name) : super(name);

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
  const FunctionTypeCheckedModeHelper(String name) : super(name);

  void generateAdditionalArguments(SsaCodeGenerator codegen,
                                   HTypeConversion node,
                                   List<jsAst.Expression> arguments) {
    DartType type = node.typeExpression;
    String signatureName = codegen.backend.namer.getFunctionTypeName(type);
    arguments.add(js.string(signatureName));

    if (type.containsTypeVariables) {
      ClassElement contextClass = Types.getClassContext(type);
      // TODO(ahe): Creating a string here is unfortunate. It is slow (due to
      // string concatenation in the implementation), and may prevent
      // segmentation of '$'.
      String contextName = codegen.backend.namer.getNameForRti(contextClass);
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
    if (insideLoop) {
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

  Element jsIndexableLength;
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

  Element getInterceptorMethod;
  Element interceptedNames;

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
  bool needToInitializeDispatchProperty = false;

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
  final Set<ClassElement> _interceptedClasses = new Set<ClassElement>();

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
  static const checkedModeHelpers = const [
      const MalformedCheckedModeHelper('checkMalformedType'),
      const CheckedModeHelper('voidTypeCheck'),
      const CheckedModeHelper('stringTypeCast'),
      const CheckedModeHelper('stringTypeCheck'),
      const CheckedModeHelper('doubleTypeCast'),
      const CheckedModeHelper('doubleTypeCheck'),
      const CheckedModeHelper('numTypeCast'),
      const CheckedModeHelper('numTypeCheck'),
      const CheckedModeHelper('boolTypeCast'),
      const CheckedModeHelper('boolTypeCheck'),
      const CheckedModeHelper('intTypeCast'),
      const CheckedModeHelper('intTypeCheck'),
      const PropertyCheckedModeHelper('numberOrStringSuperNativeTypeCast'),
      const PropertyCheckedModeHelper('numberOrStringSuperNativeTypeCheck'),
      const PropertyCheckedModeHelper('numberOrStringSuperTypeCast'),
      const PropertyCheckedModeHelper('numberOrStringSuperTypeCheck'),
      const PropertyCheckedModeHelper('stringSuperNativeTypeCast'),
      const PropertyCheckedModeHelper('stringSuperNativeTypeCheck'),
      const PropertyCheckedModeHelper('stringSuperTypeCast'),
      const PropertyCheckedModeHelper('stringSuperTypeCheck'),
      const CheckedModeHelper('listTypeCast'),
      const CheckedModeHelper('listTypeCheck'),
      const PropertyCheckedModeHelper('listSuperNativeTypeCast'),
      const PropertyCheckedModeHelper('listSuperNativeTypeCheck'),
      const PropertyCheckedModeHelper('listSuperTypeCast'),
      const PropertyCheckedModeHelper('listSuperTypeCheck'),
      const PropertyCheckedModeHelper('interceptedTypeCast'),
      const PropertyCheckedModeHelper('interceptedTypeCheck'),
      const SubtypeCheckedModeHelper('subtypeCast'),
      const SubtypeCheckedModeHelper('assertSubtype'),
      const TypeVariableCheckedModeHelper('subtypeOfRuntimeTypeCast'),
      const TypeVariableCheckedModeHelper('assertSubtypeOfRuntimeType'),
      const FunctionTypeCheckedModeHelper('functionSubtypeCast'),
      const FunctionTypeCheckedModeHelper('assertFunctionSubtype'),
      const PropertyCheckedModeHelper('propertyTypeCast'),
      const PropertyCheckedModeHelper('propertyTypeCheck') ];

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

  JavaScriptBackend(Compiler compiler, bool generateSourceMap)
      : namer = determineNamer(compiler),
        oneShotInterceptors = new Map<String, Selector>(),
        interceptedElements = new Map<String, Set<Element>>(),
        rti = new RuntimeTypes(compiler),
        specializedGetInterceptors = new Map<String, Set<ClassElement>>(),
        super(compiler, JAVA_SCRIPT_CONSTANT_SYSTEM) {
    emitter = new CodeEmitterTask(compiler, namer, generateSourceMap);
    builder = new SsaBuilderTask(this);
    optimizer = new SsaOptimizerTask(this);
    generator = new SsaCodeGeneratorTask(this);
    typeVariableHandler = new TypeVariableHandler(this);
    customElementsAnalysis = new CustomElementsAnalysis(this);
  }

  static Namer determineNamer(Compiler compiler) {
    return compiler.enableMinification ?
        new MinifyNamer(compiler) :
        new Namer(compiler);
  }

  bool usedByBackend(Element element) {
    if (element.isParameter()
        || element.isFieldParameter()
        || element.isField()) {
      if (usedByBackend(element.enclosingElement)) return true;
    }
    return helpersUsed.contains(element.declaration);
  }

  bool invokedReflectively(Element element) {
    if (element.isParameter() || element.isFieldParameter()) {
      if (invokedReflectively(element.enclosingElement)) return true;
    }

    if (element.isField()) {
      if (Elements.isStaticOrTopLevel(element)
          && (element.modifiers.isFinal() || element.modifiers.isConst())) {
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
    if (!element.isInstanceMember()) return false;
    if (element.isGenerativeConstructorBody()) {
      return Elements.isNativeOrExtendsNative(element.getEnclosingClass());
    }
    return interceptedElements[element.name] != null;
  }

  bool fieldHasInterceptedGetter(Element element) {
    assert(element.isField());
    return interceptedElements[element.name] != null;
  }

  bool fieldHasInterceptedSetter(Element element) {
    assert(element.isField());
    return interceptedElements[element.name] != null;
  }

  bool isInterceptedName(String name) {
    return interceptedElements[name] != null;
  }

  bool isInterceptedSelector(Selector selector) {
    return interceptedElements[selector.name] != null;
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
        ClassElement classElement = element.getEnclosingClass();
        if (Elements.isNativeOrExtendsNative(classElement)
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
        operatorEqfunction.getEnclosingClass());
  }

  void initializeHelperClasses() {
    getInterceptorMethod = compiler.findInterceptor('getInterceptor');
    interceptedNames = compiler.findInterceptor('interceptedNames');
    mapTypeToInterceptor = compiler.findInterceptor('mapTypeToInterceptor');
    getNativeInterceptorMethod =
        compiler.findInterceptor('getNativeInterceptor');

    // These methods are overwritten with generated versions.
    inlineCache.markAsNonInlinable(getInterceptorMethod, insideLoop: true);

    List<ClassElement> classes = [
      jsInterceptorClass =
          compiler.findInterceptor('Interceptor'),
      jsStringClass = compiler.findInterceptor('JSString'),
      jsArrayClass = compiler.findInterceptor('JSArray'),
      // The int class must be before the double class, because the
      // emitter relies on this list for the order of type checks.
      jsIntClass = compiler.findInterceptor('JSInt'),
      jsDoubleClass = compiler.findInterceptor('JSDouble'),
      jsNumberClass = compiler.findInterceptor('JSNumber'),
      jsNullClass = compiler.findInterceptor('JSNull'),
      jsBoolClass = compiler.findInterceptor('JSBool'),
      jsMutableArrayClass = compiler.findInterceptor('JSMutableArray'),
      jsFixedArrayClass = compiler.findInterceptor('JSFixedArray'),
      jsExtendableArrayClass = compiler.findInterceptor('JSExtendableArray'),
      jsPlainJavaScriptObjectClass =
          compiler.findInterceptor('PlainJavaScriptObject'),
      jsUnknownJavaScriptObjectClass =
          compiler.findInterceptor('UnknownJavaScriptObject'),
    ];

    implementationClasses = <ClassElement, ClassElement>{};
    implementationClasses[compiler.intClass] = jsIntClass;
    implementationClasses[compiler.boolClass] = jsBoolClass;
    implementationClasses[compiler.numClass] = jsNumberClass;
    implementationClasses[compiler.doubleClass] = jsDoubleClass;
    implementationClasses[compiler.stringClass] = jsStringClass;
    implementationClasses[compiler.listClass] = jsArrayClass;

    jsIndexableClass = compiler.findInterceptor('JSIndexable');
    jsMutableIndexableClass = compiler.findInterceptor('JSMutableIndexable');

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
    if (jsIndexableLength != null && jsIndexableLength.isAbstractField()) {
      AbstractFieldElement element = jsIndexableLength;
      jsIndexableLength = element.getter;
    }

    jsArrayClass.ensureResolved(compiler);
    jsArrayRemoveLast = compiler.lookupElementIn(jsArrayClass, 'removeLast');
    jsArrayAdd = compiler.lookupElementIn(jsArrayClass, 'add');

    jsStringClass.ensureResolved(compiler);
    jsStringSplit = compiler.lookupElementIn(jsStringClass, 'split');
    jsStringOperatorAdd = compiler.lookupElementIn(jsStringClass, '+');
    jsStringToString = compiler.lookupElementIn(jsStringClass, 'toString');

    typeLiteralClass = compiler.findHelper('TypeImpl');
    mapLiteralClass = compiler.coreLibrary.find('LinkedHashMap');
    constMapLiteralClass = compiler.findHelper('ConstantMap');

    objectEquals = compiler.lookupElementIn(compiler.objectClass, '==');

    jsIndexingBehaviorInterface =
        compiler.findHelper('JavaScriptIndexingBehavior');

    specialOperatorEqClasses
        ..add(compiler.objectClass)
        ..add(jsInterceptorClass)
        ..add(jsNullClass);

    validateInterceptorImplementsAllObjectMethods(jsInterceptorClass);

    typeVariableClass = compiler.findHelper('TypeVariable');

    indexablePrimitiveType = new TypeMask.nonNullSubtype(jsIndexableClass);
    readableArrayType = new TypeMask.nonNullSubclass(jsArrayClass);
    mutableArrayType = new TypeMask.nonNullSubclass(jsMutableArrayClass);
    fixedArrayType = new TypeMask.nonNullExact(jsFixedArrayClass);
    extendableArrayType = new TypeMask.nonNullExact(jsExtendableArrayClass);
    nonNullType = compiler.typesTask.dynamicType.nonNullable();
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
      },
      includeSuperAndInjectedMembers: true);

      // Walk superclass chain to find mixins.
      for (; cls != null; cls = cls.superclass) {
        if (cls.isMixinApplication) {
          MixinApplicationElement mixinApplication = cls;
          classesMixedIntoNativeClasses.add(mixinApplication.mixin);
        }
      }
    }
  }

  void addInterceptors(ClassElement cls,
                       Enqueuer enqueuer,
                       TreeElements elements) {
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
    enqueueClass(enqueuer, cls, elements);
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

  Constant registerCompileTimeConstant(Constant constant,
                                       TreeElements elements) {
    registerCompileTimeConstantInternal(constant, elements);
    for (Constant dependency in constant.getDependencies()) {
      registerCompileTimeConstant(dependency, elements);
    }
  }

  void registerCompileTimeConstantInternal(Constant constant,
                                           TreeElements elements) {
    DartType type = constant.computeType(compiler);
    registerInstantiatedConstantType(type, elements);

    if (constant.isFunction()) {
      FunctionConstant function = constant;
      compiler.enqueuer.codegen.registerGetOfStaticFunction(function.element);
    } else if (constant.isInterceptor()) {
      // An interceptor constant references the class's prototype chain.
      InterceptorConstant interceptor = constant;
      registerInstantiatedConstantType(interceptor.dispatchedType, elements);
    } else if (constant.isType()) {
      TypeConstant typeConstant = constant;
      registerTypeLiteral(typeConstant.representedType.element,
          compiler.enqueuer.codegen, elements);
    }
  }

  void registerInstantiatedConstantType(DartType type, TreeElements elements) {
    Enqueuer enqueuer = compiler.enqueuer.codegen;
    enqueuer.registerInstantiatedType(type, elements);
    if (type is InterfaceType && !type.treatAsRaw &&
        classNeedsRti(type.element)) {
      enqueuer.registerStaticUse(getSetRuntimeTypeInfo());
    }
    if (type.element == typeImplementation) {
      // If we use a type literal in a constant, the compile time
      // constant emitter will generate a call to the createRuntimeType
      // helper so we register a use of that.
      enqueuer.registerStaticUse(getCreateRuntimeType());
    }
  }

  void registerMetadataConstant(Constant constant, TreeElements elements) {
    if (mustRetainMetadata) {
      registerCompileTimeConstant(constant, elements);
    } else {
      metadataConstants.add(new Dependency(constant, elements));
    }
  }

  void registerInstantiatedClass(ClassElement cls,
                                 Enqueuer enqueuer,
                                 TreeElements elements) {
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
                elements);
      } else if (cls == compiler.listClass
                 || cls == compiler.stringClass) {
        // The backend will try to optimize array and string access and use the
        // `ioore` and `iae` helpers directly.
        enqueue(enqueuer,
                compiler.findHelper('ioore'),
                elements);
        enqueue(enqueuer,
                compiler.findHelper('iae'),
                elements);
      } else if (cls == compiler.functionClass) {
        enqueueClass(enqueuer, compiler.closureClass, elements);
      } else if (cls == compiler.mapClass) {
        // The backend will use a literal list to initialize the entries
        // of the map.
        enqueueClass(enqueuer, compiler.listClass, elements);
        enqueueClass(enqueuer, mapLiteralClass, elements);
        enqueueInResolution(getMapMaker(), elements);
      } else if (cls == compiler.boundClosureClass) {
        // TODO(ngeoffray): Move the bound closure class in the
        // backend.
        enqueueClass(enqueuer, compiler.boundClosureClass, elements);
      } else if (Elements.isNativeOrExtendsNative(cls)) {
        enqueue(enqueuer, getNativeInterceptorMethod, elements);
        enqueueClass(enqueuer, jsInterceptorClass, compiler.globalDependencies);
        enqueueClass(enqueuer, jsPlainJavaScriptObjectClass, elements);
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
      addInterceptors(jsMutableArrayClass, enqueuer, elements);
      addInterceptors(jsFixedArrayClass, enqueuer, elements);
      addInterceptors(jsExtendableArrayClass, enqueuer, elements);
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
    } else if (cls == jsPlainJavaScriptObjectClass) {
      addInterceptors(jsPlainJavaScriptObjectClass, enqueuer, elements);
    } else if (cls == jsUnknownJavaScriptObjectClass) {
      addInterceptors(jsUnknownJavaScriptObjectClass, enqueuer, elements);
    } else if (Elements.isNativeOrExtendsNative(cls)) {
      addInterceptorsForNativeClassMembers(cls, enqueuer);
    } else if (cls == jsIndexingBehaviorInterface) {
      // These two helpers are used by the emitter and the codegen.
      // Because we cannot enqueue elements at the time of emission,
      // we make sure they are always generated.
      enqueue(
          enqueuer,
          compiler.findHelper('isJsIndexable'),
          elements);
      enqueue(
          enqueuer,
          compiler.findInterceptor('dispatchPropertyName'),
          elements);
    }

    customElementsAnalysis.registerInstantiatedClass(cls, enqueuer);
  }

  void registerUseInterceptor(Enqueuer enqueuer) {
    assert(!enqueuer.isResolutionQueue);
    if (!enqueuer.nativeEnqueuer.hasInstantiatedNativeClasses()) return;
    TreeElements elements = compiler.globalDependencies;
    enqueue(enqueuer, getNativeInterceptorMethod, elements);
    enqueueClass(enqueuer, jsPlainJavaScriptObjectClass, elements);
    needToInitializeDispatchProperty = true;
  }

  JavaScriptItemCompilationContext createItemCompilationContext() {
    return new JavaScriptItemCompilationContext();
  }

  void enqueueHelpers(ResolutionEnqueuer world, TreeElements elements) {
    // TODO(ngeoffray): Not enqueuing those two classes currently make
    // the compiler potentially crash. However, any reasonable program
    // will instantiate those two classes.
    addInterceptors(jsBoolClass, world, elements);
    addInterceptors(jsNullClass, world, elements);
    if (compiler.enableTypeAssertions) {
      // Unconditionally register the helper that checks if the
      // expression in an if/while/for is a boolean.
      // TODO(ngeoffray): Should we have the resolver register those instead?
      Element e =
          compiler.findHelper('boolConversionCheck');
      if (e != null) enqueue(world, e, elements);
    }
    registerCheckedModeHelpers(elements);
  }

  onResolutionComplete() => rti.computeClassesNeedingRti();

  void registerStringInterpolation(TreeElements elements) {
    enqueueInResolution(getStringInterpolationHelper(), elements);
  }

  void registerCatchStatement(Enqueuer enqueuer, TreeElements elements) {
    void ensure(ClassElement classElement) {
      if (classElement != null) {
        enqueueClass(enqueuer, classElement, elements);
      }
    }
    enqueueInResolution(getExceptionUnwrapper(), elements);
    ensure(jsPlainJavaScriptObjectClass);
    ensure(jsUnknownJavaScriptObjectClass);
  }

  void registerThrowExpression(TreeElements elements) {
    // We don't know ahead of time whether we will need the throw in a
    // statement context or an expression context, so we register both
    // here, even though we may not need the throwExpression helper.
    enqueueInResolution(getWrapExceptionHelper(), elements);
    enqueueInResolution(getThrowExpressionHelper(), elements);
  }

  void registerLazyField(TreeElements elements) {
    enqueueInResolution(getCyclicThrowHelper(), elements);
  }

  void registerTypeLiteral(Element element,
                           Enqueuer enqueuer,
                           TreeElements elements) {
    enqueuer.registerInstantiatedClass(typeImplementation, elements);
    enqueueInResolution(getCreateRuntimeType(), elements);
    // TODO(ahe): Might want to register [element] as an instantiated class
    // when reflection is used.  However, as long as we disable tree-shaking
    // eagerly it doesn't matter.
    if (element.isTypedef()) {
      typedefTypeLiterals.add(element);
    }
    customElementsAnalysis.registerTypeLiteral(element, enqueuer);
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
    enqueueClass(enqueuer, compiler.listClass, elements);
  }

  void registerRuntimeType(Enqueuer enqueuer, TreeElements elements) {
    registerComputeSignature(enqueuer, elements);
    enqueueInResolution(getSetRuntimeTypeInfo(), elements);
    enqueueInResolution(getGetRuntimeTypeInfo(), elements);
    registerGetRuntimeTypeArgument(elements);
    enqueueClass(enqueuer, compiler.listClass, elements);
  }

  void registerTypeVariableExpression(TreeElements elements) {
    enqueueInResolution(getSetRuntimeTypeInfo(), elements);
    enqueueInResolution(getGetRuntimeTypeInfo(), elements);
    registerGetRuntimeTypeArgument(elements);
    enqueueClass(compiler.enqueuer.resolution, compiler.listClass, elements);
    enqueueInResolution(getRuntimeTypeToString(), elements);
    enqueueInResolution(getCreateRuntimeType(), elements);
  }

  void registerIsCheck(DartType type, Enqueuer world, TreeElements elements) {
    type = type.unalias(compiler);
    enqueueClass(world, compiler.boolClass, elements);
    bool inCheckedMode = compiler.enableTypeAssertions;
    // [registerIsCheck] is also called for checked mode checks, so we
    // need to register checked mode helpers.
    if (inCheckedMode) {
      if (!world.isResolutionQueue) {
        // All helpers are added to resolution queue in enqueueHelpers. These
        // calls to enqueueInResolution serve as assertions that the helper was
        // in fact added.
        // TODO(13155): Find a way to enqueue helpers lazily.
        CheckedModeHelper helper = getCheckedModeHelper(type, typeCast: false);
        if (helper != null) {
          enqueue(world, helper.getElement(compiler), elements);
        }
        // We also need the native variant of the check (for DOM types).
        helper = getNativeCheckedModeHelper(type, typeCast: false);
        if (helper != null) {
          enqueue(world, helper.getElement(compiler), elements);
        }
      }
    }
    bool isTypeVariable = type.kind == TypeKind.TYPE_VARIABLE;
    if (type.kind == TypeKind.MALFORMED_TYPE) {
      enqueueInResolution(getThrowTypeError(), elements);
    }
    if (!type.treatAsRaw || type.containsTypeVariables) {
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
      enqueueClass(world, compiler.listClass, elements);
    }
    if (type is FunctionType) {
      enqueueInResolution(getCheckFunctionSubtype(), elements);
    }
    if (type.element.isNative()) {
      // We will neeed to add the "$is" and "$as" properties on the
      // JavaScript object prototype, so we make sure
      // [:defineProperty:] is compiled.
      enqueue(world,
              compiler.findHelper('defineProperty'),
              elements);
    }
  }

  void registerAsCheck(DartType type, Enqueuer world, TreeElements elements) {
    type = type.unalias(compiler);
    if (!world.isResolutionQueue) {
      // All helpers are added to resolution queue in enqueueHelpers. These
      // calls to enqueueInResolution serve as assertions that the helper was in
      // fact added.
      // TODO(13155): Find a way to enqueue helpers lazily.
      CheckedModeHelper helper = getCheckedModeHelper(type, typeCast: true);
      enqueueInResolution(helper.getElement(compiler), elements);
      // We also need the native variant of the check (for DOM types).
      helper = getNativeCheckedModeHelper(type, typeCast: true);
      if (helper != null) {
        enqueueInResolution(helper.getElement(compiler), elements);
      }
    }
  }

  void registerThrowNoSuchMethod(TreeElements elements) {
    enqueueInResolution(getThrowNoSuchMethod(), elements);
    // Also register the types of the arguments passed to this method.
    enqueueClass(compiler.enqueuer.resolution, compiler.listClass, elements);
    enqueueClass(compiler.enqueuer.resolution, compiler.stringClass, elements);
  }

  void registerThrowRuntimeError(TreeElements elements) {
    enqueueInResolution(getThrowRuntimeError(), elements);
    // Also register the types of the arguments passed to this method.
    enqueueClass(compiler.enqueuer.resolution, compiler.stringClass, elements);
  }

  void registerTypeVariableBoundsSubtypeCheck(DartType typeArgument,
                                              DartType bound) {
    rti.registerTypeVariableBoundsSubtypeCheck(typeArgument, bound);
  }

  void registerTypeVariableBoundCheck(TreeElements elements) {
    enqueueInResolution(getThrowTypeError(), elements);
    enqueueInResolution(getAssertIsSubtype(), elements);
  }

  void registerAbstractClassInstantiation(TreeElements elements) {
    enqueueInResolution(getThrowAbstractClassInstantiationError(), elements);
    // Also register the types of the arguments passed to this method.
    enqueueClass(compiler.enqueuer.resolution, compiler.stringClass, elements);
  }

  void registerFallThroughError(TreeElements elements) {
    enqueueInResolution(getFallThroughError(), elements);
  }

  void enableNoSuchMethod(Enqueuer world) {
    enqueue(world, getCreateInvocationMirror(), compiler.globalDependencies);
    world.registerInvocation(compiler.noSuchMethodSelector);
  }

  void registerSuperNoSuchMethod(TreeElements elements) {
    enqueueInResolution(getCreateInvocationMirror(), elements);
    enqueueInResolution(
        compiler.objectClass.lookupLocalMember(Compiler.NO_SUCH_METHOD),
        elements);
    enqueueClass(compiler.enqueuer.resolution, compiler.listClass, elements);
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
    assert(element.name == '==');
    ClassElement classElement = element.getEnclosingClass();
    return classElement == compiler.objectClass
        || classElement == jsInterceptorClass
        || classElement == jsNullClass;
  }

  bool methodNeedsRti(FunctionElement function) {
    return rti.methodsNeedingRti.contains(function) ||
           compiler.enabledRuntimeType;
  }

  // Enqueue [e] in [enqueuer].
  //
  // The backend must *always* call this method when enqueuing an
  // element. Calls done by the backend are not seen by global
  // optimizations, so they would make these optimizations unsound.
  // Therefore we need to collect the list of helpers the backend may
  // use.
  void enqueue(Enqueuer enqueuer, Element e, TreeElements elements) {
    if (e == null) return;
    helpersUsed.add(e.declaration);
    enqueuer.addToWorkList(e);
    elements.registerDependency(e);
  }

  void enqueueInResolution(Element e, TreeElements elements) {
    if (e == null) return;
    ResolutionEnqueuer enqueuer = compiler.enqueuer.resolution;
    enqueue(enqueuer, e, elements);
  }

  void enqueueClass(Enqueuer enqueuer, Element cls, TreeElements elements) {
    if (cls == null) return;
    helpersUsed.add(cls.declaration);
    // Both declaration and implementation may declare fields, so we
    // add both to the list of helpers.
    if (cls.declaration != cls.implementation) {
      helpersUsed.add(cls.implementation);
    }
    enqueuer.registerInstantiatedClass(cls, elements);
  }

  void registerConstantMap(TreeElements elements) {
    void enqueue(String name) {
      Element e = compiler.findHelper(name);
      if (e != null) {
        enqueueClass(compiler.enqueuer.resolution, e, elements);
      }
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
    if (element.isConstructor() && element.getEnclosingClass() == jsNullClass) {
      // Work around a problem compiling JSNull's constructor.
      return;
    }
    if (kind.category == ElementCategory.VARIABLE) {
      Constant initialValue =
          compiler.constantHandler.getConstantForVariable(element);
      if (initialValue != null) {
        registerCompileTimeConstant(initialValue, work.resolutionTree);
        compiler.constantHandler.addCompileTimeConstantForEmission(
            initialValue);
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
          compiler.withCurrentElement(library, () {
            compiler.reportInfo(importTag, MessageKind.MIRROR_IMPORT);
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

  Element getImplementationClass(Element element) {
    for (ClassElement dartClass in implementationClasses.keys) {
      if (element == dartClass) {
        return implementationClasses[dartClass];
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
    if (type.kind == TypeKind.MALFORMED_TYPE) {
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

    if (type == compiler.types.voidType) {
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
    } else if (element == jsIntClass || element == compiler.intClass) {
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
        if (type.kind == TypeKind.INTERFACE && !type.treatAsRaw) {
          return typeCast
              ? 'subtypeCast'
              : 'assertSubtype';
        } else if (type.kind == TypeKind.TYPE_VARIABLE) {
          return typeCast
              ? 'subtypeOfRuntimeTypeCast'
              : 'assertSubtypeOfRuntimeType';
        } else if (type.kind == TypeKind.FUNCTION) {
          return typeCast
              ? 'functionSubtypeCast'
              : 'assertFunctionSubtype';
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

  void registerCheckedModeHelpers(TreeElements elements) {
    // We register all the helpers in the resolution queue.
    // TODO(13155): Find a way to register fewer helpers.
    for (CheckedModeHelper helper in checkedModeHelpers) {
      enqueueInResolution(helper.getElement(compiler), elements);
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

  Element getMapMaker() {
    return compiler.findHelper('makeLiteralMap');
  }

  Element getSetRuntimeTypeInfo() {
    return compiler.findHelper('setRuntimeTypeInfo');
  }

  Element getGetRuntimeTypeInfo() {
    return compiler.findHelper('getRuntimeTypeInfo');
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

  Element getAssertSubtypeOfRuntimeType() {
    return compiler.findHelper('assertSubtypeOfRuntimeType');
  }

  Element getCheckFunctionSubtype() {
    return compiler.findHelper('checkFunctionSubtype');
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
    } else if (element == preserveNamesMarker) {
      mustPreserveNames = true;
    } else if (element == preserveMetadataMarker) {
      mustRetainMetadata = true;
    }
    customElementsAnalysis.registerStaticUse(element, enqueuer);
  }

  /// Called when [:const Symbol(name):] is seen.
  void registerConstSymbol(String name, TreeElements elements) {
    symbolsUsed.add(name);
    if (name.endsWith('=')) {
      symbolsUsed.add(name.substring(0, name.length - 1));
    }
  }

  /// Called when [:new Symbol(...):] is seen.
  void registerNewSymbol(TreeElements elements) {
  }

  /// Called when resolving the `Symbol` constructor.
  void registerSymbolConstructor(TreeElements elements) {
    // Make sure that collection_dev.Symbol.validated is registered.
    assert(compiler.symbolValidatedConstructor != null);
    enqueueInResolution(compiler.symbolValidatedConstructor, elements);
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
        compiler.constantHandler.addCompileTimeConstantForEmission(
            metadata.value);
      }
      return true;
    }
    return false;
  }

  Future onLibraryLoaded(LibraryElement library, Uri uri) {
    if (uri == Uri.parse('dart:_js_mirrors')) {
      disableTreeShakingMarker =
          library.find('disableTreeShaking');
      preserveMetadataMarker =
          library.find('preserveMetadata');
    } else if (uri == Uri.parse('dart:_js_names')) {
      preserveNamesMarker =
          library.find('preserveNames');
    }
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
        if (target.isAbstractField()) {
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
    if (hasInsufficientMirrorsUsed) return true;
    return isNeededForReflection(element);
  }

  /**
   * Returns `true` if the emitter must emit the element even though there
   * is no direct use in the program, but because the reflective system may
   * need to access it.
   */
  bool isNeededForReflection(Element element) {
    element = getDartClass(element);
    if (hasInsufficientMirrorsUsed) return isTreeShakingDisabled;
    /// Record the name of [element] in [symbolsUsed]. Return true for
    /// convenience.
    bool registerNameOf(Element element) {
      symbolsUsed.add(element.name);
      if (element.isConstructor()) {
        symbolsUsed.add(element.getEnclosingClass().name);
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

    if (element is ClosureClassElement) {
      // TODO(ahe): Try to fix the enclosing element of ClosureClassElement
      // instead.
      ClosureClassElement closureClass = element;
      if (isNeededForReflection(closureClass.methodElement)) {
        return registerNameOf(element);
      }
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
        use2, new jsAst.VariableUse(dispatchPropertyName));

    List<jsAst.Expression> arguments = <jsAst.Expression>[use1, record];
    FunctionElement helper =
        compiler.findHelper('isJsIndexable');
    String helperName = namer.isolateAccess(helper);
    return new jsAst.Call(new jsAst.VariableUse(helperName), arguments);
  }

  bool isTypedArray(TypeMask mask) {
    // Just checking for [:TypedData:] is not sufficient, as it is an
    // abstract class any user-defined class can implement. So we also
    // check for the interface [JavaScriptIndexingBehavior].
    return compiler.typedDataClass != null
        && mask.satisfies(compiler.typedDataClass, compiler)
        && mask.satisfies(jsIndexingBehaviorInterface, compiler);
  }

  /// Called when [enqueuer] is empty, but before it is closed.
  void onQueueEmpty(Enqueuer enqueuer) {
    if (!enqueuer.isResolutionQueue && preMirrorsMethodCount == 0) {
      preMirrorsMethodCount = generatedCode.length;
    }

    if (isTreeShakingDisabled) enqueuer.enqueueEverything();

    if (mustPreserveNames) compiler.log('Preserving names.');

    if (mustRetainMetadata) {
      compiler.log('Retaining metadata.');

      compiler.libraries.values.forEach(retainMetadataOf);
      for (Dependency dependency in metadataConstants) {
        registerCompileTimeConstant(
            dependency.constant, dependency.user);
      }
      metadataConstants.clear();
    }

    if (isTreeShakingDisabled) {
      if (enqueuer.isResolutionQueue) {
        typeVariableHandler.onResolutionQueueEmpty(enqueuer);
      } else {
        typeVariableHandler.onCodegenQueueEmpty();
      }
    }
    customElementsAnalysis.onQueueEmpty(enqueuer);
  }
}

/// Records that [constant] is used by [user.element].
class Dependency {
  final Constant constant;
  final TreeElements user;

  const Dependency(this.constant, this.user);
}

/// Used to copy metadata to the the actual constant handler.
class ConstantCopier implements ConstantVisitor {
  final ConstantHandler target;

  ConstantCopier(this.target);

  void copy(/* Constant or List<Constant> */ value) {
    if (value is Constant) {
      target.compiledConstants.add(value);
    } else {
      target.compiledConstants.addAll(value);
    }
  }

  void visitFunction(FunctionConstant constant) => copy(constant);

  void visitNull(NullConstant constant) => copy(constant);

  void visitInt(IntConstant constant) => copy(constant);

  void visitDouble(DoubleConstant constant) => copy(constant);

  void visitTrue(TrueConstant constant) => copy(constant);

  void visitFalse(FalseConstant constant) => copy(constant);

  void visitString(StringConstant constant) => copy(constant);

  void visitType(TypeConstant constant) => copy(constant);

  void visitInterceptor(InterceptorConstant constant) => copy(constant);

  void visitList(ListConstant constant) {
    copy(constant.entries);
    copy(constant);
  }
  void visitMap(MapConstant constant) {
    copy(constant.keys);
    copy(constant.values);
    copy(constant.protoValue);
    copy(constant);
  }

  void visitConstructed(ConstructedConstant constant) {
    copy(constant.fields);
    copy(constant);
  }
}
