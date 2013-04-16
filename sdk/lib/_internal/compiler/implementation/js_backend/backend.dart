// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of js_backend;

typedef void Recompile(Element element);

class ReturnInfo {
  HType returnType;
  List<Element> compiledFunctions;

  ReturnInfo(HType this.returnType)
      : compiledFunctions = new List<Element>();

  ReturnInfo.unknownType() : this(null);

  void update(HType type, Recompile recompile, Compiler compiler) {
    HType newType =
        returnType != null ? returnType.union(type, compiler) : type;
    if (newType != returnType) {
      if (returnType == null && identical(newType, HType.UNKNOWN)) {
        // If the first actual piece of information is not providing any type
        // information there is no need to recompile callers.
        compiledFunctions.clear();
      }
      returnType = newType;
      if (recompile != null) {
        compiledFunctions.forEach(recompile);
      }
      compiledFunctions.clear();
    }
  }

  // Note that lazy initializers are treated like functions (but are not
  // of type [FunctionElement].
  addCompiledFunction(Element function) => compiledFunctions.add(function);
}

class OptionalParameterTypes {
  final List<SourceString> names;
  final List<HType> types;

  OptionalParameterTypes(int optionalArgumentsCount)
      : names = new List<SourceString>(optionalArgumentsCount),
        types = new List<HType>(optionalArgumentsCount);

  int get length => names.length;
  SourceString name(int index) => names[index];
  HType type(int index) => types[index];
  int indexOf(SourceString name) => names.indexOf(name);

  HType typeFor(SourceString name) {
    int index = indexOf(name);
    if (index == -1) return null;
    return type(index);
  }

  void update(int index, SourceString name, HType type) {
    names[index] = name;
    types[index] = type;
  }

  String toString() => "OptionalParameterTypes($names, $types)";
}

class HTypeList {
  final List<HType> types;
  final List<SourceString> namedArguments;

  HTypeList(int length)
      : types = new List<HType>(length),
        namedArguments = null;
  HTypeList.withNamedArguments(int length, this.namedArguments)
      : types = new List<HType>(length);
  const HTypeList.withAllUnknown()
      : types = null,
        namedArguments = null;

  factory HTypeList.fromStaticInvocation(HInvokeStatic node) {
    bool allUnknown = true;
    for (int i = 1; i < node.inputs.length; i++) {
      if (node.inputs[i].instructionType != HType.UNKNOWN) {
        allUnknown = false;
        break;
      }
    }
    if (allUnknown) return HTypeList.ALL_UNKNOWN;

    HTypeList result = new HTypeList(node.inputs.length - 1);
    for (int i = 0; i < result.types.length; i++) {
      result.types[i] = node.inputs[i + 1].instructionType;
      assert(!result.types[i].isConflicting());
    }
    return result;
  }

  factory HTypeList.fromDynamicInvocation(HInvokeDynamic node,
                                          Selector selector) {
    HTypeList result;
    int argumentsCount = node.inputs.length - 1;
    int startInvokeIndex = HInvoke.ARGUMENTS_OFFSET;

    if (node.isInterceptedCall) {
      argumentsCount--;
      startInvokeIndex++;
    }

    if (selector.namedArgumentCount > 0) {
      result =
          new HTypeList.withNamedArguments(
              argumentsCount, selector.namedArguments);
    } else {
      result = new HTypeList(argumentsCount);
    }

    for (int i = 0; i < result.types.length; i++) {
      result.types[i] = node.inputs[i + startInvokeIndex].instructionType;
      assert(!result.types[i].isConflicting());
    }
    return result;
  }

  static const HTypeList ALL_UNKNOWN = const HTypeList.withAllUnknown();

  bool get allUnknown => types == null;
  bool get hasNamedArguments => namedArguments != null;
  int get length => types.length;
  HType operator[](int index) => types[index];
  void operator[]=(int index, HType type) { types[index] = type; }

  HTypeList union(HTypeList other, Compiler compiler) {
    if (allUnknown) return this;
    if (other.allUnknown) return other;
    if (length != other.length) return HTypeList.ALL_UNKNOWN;
    bool onlyUnknown = true;
    HTypeList result = this;
    for (int i = 0; i < length; i++) {
      HType newType = this[i].union(other[i], compiler);
      if (result == this && newType != this[i]) {
        // Create a new argument types object with the matching types copied.
        result = new HTypeList(length);
        result.types.setRange(0, i, this.types);
      }
      if (result != this) {
        result.types[i] = newType;
      }
      if (result[i] != HType.UNKNOWN) onlyUnknown = false;
    }
    return onlyUnknown ? HTypeList.ALL_UNKNOWN : result;
  }

  HTypeList unionWithOptionalParameters(
      Selector selector,
      FunctionSignature signature,
      OptionalParameterTypes defaultValueTypes) {
    assert(allUnknown || selector.argumentCount == this.length);
    // Create a new HTypeList for holding types for all parameters.
    HTypeList result = new HTypeList(signature.parameterCount);

    // First fill in the type of the positional arguments.
    int nextTypeIndex = -1;
    if (allUnknown) {
      for (int i = 0; i < selector.positionalArgumentCount; i++) {
        result.types[i] = HType.UNKNOWN;
      }
    } else {
      result.types.setRange(0, selector.positionalArgumentCount, this.types);
      nextTypeIndex = selector.positionalArgumentCount;
    }

    // Next fill the type of the optional arguments.
    // As the selector can pass optional arguments positionally some of the
    // optional arguments might already have a type set. We only need to look
    // at the optional arguments not passed positionally.
    // The variable 'index' is counting the signatures optional arguments, the
    // variable 'next' is set to the next optional arguments to look at and
    // is used to skip some optional arguments.
    int next = selector.positionalArgumentCount;
    int index = signature.requiredParameterCount;
    signature.forEachOptionalParameter((Element element) {
      // If some optional parameters were passed positionally these have
      // already been filled.
      if (index == next) {
        assert(result.types[index] == null);
        HType type = null;
        if (hasNamedArguments &&
            selector.namedArguments.indexOf(element.name) >= 0) {
          type = types[nextTypeIndex++];
        } else {
          type = defaultValueTypes.typeFor(element.name);
        }
        result.types[index] = type;
        next++;
      }
      index++;
    });
    return result;
  }

  String toString() =>
      allUnknown ? "HTypeList.ALL_UNKNOWN" : "HTypeList $types";
}

class FieldTypesRegistry {
  final JavaScriptBackend backend;

  /**
   * For each class, [constructors] holds the set of constructors. If there is
   * more than one constructor for a class it is currently not possible to
   * infer the field types from construction, as the information collected does
   * not correlate the generative constructors and generative constructor
   * body/bodies.
   */
  final Map<ClassElement, Set<Element>> constructors;

  /**
   * The collected type information is stored in three maps. One for types
   * assigned in the initializer list(s) [fieldInitializerTypeMap], one for
   * types assigned in the constructor(s) [fieldConstructorTypeMap], and one
   * for types assigned in the rest of the code, where the field can be
   * resolved [fieldTypeMap].
   *
   * If a field has a type both from constructors and from the initializer
   * list(s), then the type from the constructor(s) will owerride the one from
   * the initializer list(s).
   *
   * Because the order in which generative constructors, generative constructor
   * bodies and normal method/function bodies are compiled is undefined, and
   * because they can all be recompiled, it is not possible to combine this
   * information into one map at the moment.
   */
  final Map<Element, HType> fieldInitializerTypeMap;
  final Map<Element, HType> fieldConstructorTypeMap;
  final Map<Element, HType> fieldTypeMap;

  /**
   * The set of current names setter selectors used. If a named selector is
   * used it is currently not possible to infer the type of the field.
   */
  final Set<SourceString> setterSelectorsUsed;

  final Map<Element, Set<Element>> optimizedStaticFunctions;
  final Map<Element, FunctionSet> optimizedFunctions;

  FieldTypesRegistry(JavaScriptBackend backend)
      : constructors =  new Map<ClassElement, Set<Element>>(),
        fieldInitializerTypeMap = new Map<Element, HType>(),
        fieldConstructorTypeMap = new Map<Element, HType>(),
        fieldTypeMap = new Map<Element, HType>(),
        setterSelectorsUsed = new Set<SourceString>(),
        optimizedStaticFunctions = new Map<Element, Set<Element>>(),
        optimizedFunctions = new Map<Element, FunctionSet>(),
        this.backend = backend;

  Compiler get compiler => backend.compiler;

  void scheduleRecompilation(Element field) {
    Set optimizedStatics = optimizedStaticFunctions[field];
    if (optimizedStatics != null) {
      optimizedStatics.forEach(backend.scheduleForRecompilation);
      optimizedStaticFunctions.remove(field);
    }
    FunctionSet optimized = optimizedFunctions[field];
    if (optimized != null) {
      optimized.forEach(backend.scheduleForRecompilation);
      optimizedFunctions.remove(field);
    }
  }

  int constructorCount(Element element) {
    assert(element.isClass());
    Set<Element> ctors = constructors[element];
    return ctors == null ? 0 : ctors.length;
  }

  void registerFieldType(Map<Element, HType> typeMap,
                         Element field,
                         HType type) {
    assert(field.isField());
    assert(!type.isConflicting());
    HType before = optimisticFieldType(field);

    HType oldType = typeMap[field];
    HType newType;

    if (oldType != null) {
      newType = oldType.union(type, compiler);
    } else {
      newType = type;
    }
    typeMap[field] = newType;
    if (oldType != newType) {
      scheduleRecompilation(field);
    }
  }

  void registerConstructor(Element element) {
    assert(element.isGenerativeConstructor());
    Element cls = element.getEnclosingClass();
    constructors.putIfAbsent(cls, () => new Set<Element>());
    Set<Element> ctors = constructors[cls];
    if (ctors.contains(element)) return;
    ctors.add(element);
    // We cannot infer field types for classes with more than one constructor.
    // When the second constructor is seen, recompile all functions relying on
    // optimistic field types for that class.
    // TODO(sgjesse): Handle field types for classes with more than one
    // constructor.
    if (ctors.length == 2) {
      optimizedFunctions.keys.toList().forEach((Element field) {
        if (identical(field.enclosingElement, cls)) {
          scheduleRecompilation(field);
        }
      });
    }
  }

  void registerFieldInitializer(Element field, HType type) {
    registerFieldType(fieldInitializerTypeMap, field, type);
  }

  void registerFieldConstructor(Element field, HType type) {
    registerFieldType(fieldConstructorTypeMap, field, type);
  }

  void registerFieldSetter(FunctionElement element, Element field, HType type) {
    HType initializerType = fieldInitializerTypeMap[field];
    HType constructorType = fieldConstructorTypeMap[field];
    HType setterType = fieldTypeMap[field];
    if (type == HType.UNKNOWN
        && initializerType == null
        && constructorType == null
        && setterType == null) {
      // Don't register UNKNOWN if there is currently no type information
      // present for the field. Instead register the function holding the
      // setter for recompilation if better type information for the field
      // becomes available.
      registerOptimizedFunction(element, field, type);
      return;
    }
    registerFieldType(fieldTypeMap, field, type);
  }

  void addedDynamicSetter(Selector setter, HType type) {
    // Field type optimizations are disabled for all fields matching a
    // setter selector.
    assert(setter.isSetter());
    // TODO(sgjesse): Take the type of the setter into account.
    if (setterSelectorsUsed.contains(setter.name)) return;
    setterSelectorsUsed.add(setter.name);
    optimizedStaticFunctions.keys.toList().forEach((Element field) {
      if (field.name == setter.name) {
        scheduleRecompilation(field);
      }
    });
    optimizedFunctions.keys.toList().forEach((Element field) {
      if (field.name == setter.name) {
        scheduleRecompilation(field);
      }
    });
  }

  HType optimisticFieldType(Element field) {
    assert(field.isField());
    if (constructorCount(field.getEnclosingClass()) > 1) {
      return HType.UNKNOWN;
    }
    if (setterSelectorsUsed.contains(field.name)) {
      return HType.UNKNOWN;
    }
    HType initializerType = fieldInitializerTypeMap[field];
    HType constructorType = fieldConstructorTypeMap[field];
    if (initializerType == null && constructorType == null) {
      // If there are no constructor type information return UNKNOWN. This
      // ensures that the function will be recompiled if useful constructor
      // type information becomes available.
      return HType.UNKNOWN;
    }
    // A type set through the constructor overrides the type from the
    // initializer list.
    HType result = constructorType != null ? constructorType : initializerType;
    HType type = fieldTypeMap[field];
    if (type != null) result = result.union(type, compiler);
    return result;
  }

  void registerOptimizedFunction(FunctionElement element,
                                 Element field,
                                 HType type) {
    assert(field.isField());
    if (Elements.isStaticOrTopLevel(element)) {
      optimizedStaticFunctions.putIfAbsent(
          field, () => new Set<Element>());
      optimizedStaticFunctions[field].add(element);
    } else {
      optimizedFunctions.putIfAbsent(
          field, () => new FunctionSet(backend.compiler));
      optimizedFunctions[field].add(element);
    }
  }

  void dump() {
    Set<Element> allFields = new Set<Element>();
    fieldInitializerTypeMap.keys.forEach(allFields.add);
    fieldConstructorTypeMap.keys.forEach(allFields.add);
    fieldTypeMap.keys.forEach(allFields.add);
    allFields.forEach((Element field) {
      print("Inferred $field has type ${optimisticFieldType(field)}");
    });
  }
}

class ArgumentTypesRegistry {
  final JavaScriptBackend backend;

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: Keys must be declaration elements.
   */
  final Map<Element, HTypeList> staticTypeMap;

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: Elements must be declaration elements.
   */
  final Set<Element> optimizedStaticFunctions;
  final SelectorMap<HTypeList> selectorTypeMap;
  final FunctionSet optimizedFunctions;

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: Keys must be declaration elements.
   */
  final Map<Element, HTypeList> optimizedTypes;
  final Map<Element, OptionalParameterTypes> optimizedDefaultValueTypes;

  ArgumentTypesRegistry(JavaScriptBackend backend)
      : staticTypeMap = new Map<Element, HTypeList>(),
        optimizedStaticFunctions = new Set<Element>(),
        selectorTypeMap = new SelectorMap<HTypeList>(backend.compiler),
        optimizedFunctions = new FunctionSet(backend.compiler),
        optimizedTypes = new Map<Element, HTypeList>(),
        optimizedDefaultValueTypes =
            new Map<Element, OptionalParameterTypes>(),
        this.backend = backend;

  Compiler get compiler => backend.compiler;

  bool updateTypes(HTypeList oldTypes, HTypeList newTypes, var key, var map) {
    if (oldTypes.allUnknown) return false;
    newTypes = oldTypes.union(newTypes, backend.compiler);
    if (identical(newTypes, oldTypes)) return false;
    map[key] = newTypes;
    return true;
  }

  void registerStaticInvocation(HInvokeStatic node) {
    Element element = node.element;
    assert(invariant(node, element.isDeclaration));
    HTypeList oldTypes = staticTypeMap[element];
    HTypeList newTypes = new HTypeList.fromStaticInvocation(node);
    if (oldTypes == null) {
      staticTypeMap[element] = newTypes;
    } else if (updateTypes(oldTypes, newTypes, element, staticTypeMap)) {
      if (optimizedStaticFunctions.contains(element)) {
        backend.scheduleForRecompilation(element);
      }
    }
  }

  void registerNonCallStaticUse(HStatic node) {
    // When a static is used for anything else than a call target we cannot
    // infer anything about its parameter types.
    Element element = node.element;
    assert(invariant(node, element.isDeclaration));
    if (optimizedStaticFunctions.contains(element)) {
      backend.scheduleForRecompilation(element);
    }
    staticTypeMap[element] = HTypeList.ALL_UNKNOWN;
  }

  void registerDynamicInvocation(HTypeList providedTypes, Selector selector) {
    if (selector.isClosureCall()) {
      // We cannot use the current framework to do optimizations based
      // on the 'call' selector because we are also generating closure
      // calls during the emitter phase, which at this point, does not
      // track parameter types, nor invalidates optimized methods.
      return;
    }
    if (!selectorTypeMap.containsKey(selector)) {
      selectorTypeMap[selector] = providedTypes;
    } else {
      HTypeList oldTypes = selectorTypeMap[selector];
      updateTypes(oldTypes, providedTypes, selector, selectorTypeMap);
    }

    // If we're not compiling, we don't have to do anything.
    if (compiler.phase != Compiler.PHASE_COMPILING) return;

    // Run through all optimized functions and figure out if they need
    // to be recompiled because of this new invocation.
    for (Element element in optimizedFunctions.filter(selector)) {
      // TODO(kasperl): Maybe check if the element is already marked for
      // recompilation? Could be pretty cheap compared to computing
      // union types.
      HTypeList newTypes =
          parameterTypes(element, optimizedDefaultValueTypes[element]);
      bool recompile = false;
      if (newTypes.allUnknown) {
        recompile = true;
      } else {
        HTypeList oldTypes = optimizedTypes[element];
        assert(newTypes.length == oldTypes.length);
        for (int i = 0; i < oldTypes.length; i++) {
          if (newTypes[i] != oldTypes[i]) {
            recompile = true;
            break;
          }
        }
      }
      if (recompile) backend.scheduleForRecompilation(element);
    }
  }

  HTypeList parameterTypes(FunctionElement element,
                           OptionalParameterTypes defaultValueTypes) {
    assert(invariant(element, element.isDeclaration));
    // Handle static functions separately.
    if (Elements.isStaticOrTopLevelFunction(element) ||
        element.kind == ElementKind.GENERATIVE_CONSTRUCTOR) {
      HTypeList types = staticTypeMap[element];
      if (types != null) {
        if (!optimizedStaticFunctions.contains(element)) {
          optimizedStaticFunctions.add(element);
        }
        return types;
      } else {
        return HTypeList.ALL_UNKNOWN;
      }
    }

    // Getters have no parameters.
    if (element.isGetter()) return HTypeList.ALL_UNKNOWN;

    // TODO(kasperl): What kind of non-members do we get here?
    if (!element.isMember()) return HTypeList.ALL_UNKNOWN;

    // If there are any getters for this method we cannot know anything about
    // the types of the provided parameters. Use resolverWorld for now as that
    // information does not change during compilation.
    // TODO(ngeoffray): These checks should use the codegenWorld and keep track
    // of changes to this information.
    if (compiler.resolverWorld.hasInvokedGetter(element, compiler)) {
      return HTypeList.ALL_UNKNOWN;
    }

    FunctionSignature signature = element.computeSignature(compiler);
    HTypeList found = null;
    selectorTypeMap.visitMatching(element,
        (Selector selector, HTypeList types) {
      if (selector.argumentCount != signature.parameterCount ||
          selector.namedArgumentCount > 0) {
        types = types.unionWithOptionalParameters(selector,
                                                  signature,
                                                  defaultValueTypes);
      }
      assert(types.allUnknown || types.length == signature.parameterCount);
      found = (found == null) ? types : found.union(types, compiler);
      return !found.allUnknown;
    });
    return found != null ? found : HTypeList.ALL_UNKNOWN;
  }

  void registerOptimizedFunction(Element element,
                                 HTypeList parameterTypes,
                                 OptionalParameterTypes defaultValueTypes) {
    if (Elements.isStaticOrTopLevelFunction(element)) {
      if (parameterTypes.allUnknown) {
        optimizedStaticFunctions.remove(element);
      } else {
        optimizedStaticFunctions.add(element);
      }
    }

    // TODO(kasperl): What kind of non-members do we get here?
    if (!element.isInstanceMember()) return;

    if (parameterTypes.allUnknown) {
      optimizedFunctions.remove(element);
      optimizedTypes.remove(element);
      optimizedDefaultValueTypes.remove(element);
    } else {
      optimizedFunctions.add(element);
      optimizedTypes[element] = parameterTypes;
      optimizedDefaultValueTypes[element] = defaultValueTypes;
    }
  }

  void dump() {
    optimizedFunctions.forEach((Element element) {
      HTypeList types = optimizedTypes[element];
      print("Inferred $element has argument types ${types.types}");
    });
  }
}

class JavaScriptItemCompilationContext extends ItemCompilationContext {
  final Set<HInstruction> boundsChecked;

  JavaScriptItemCompilationContext()
      : boundsChecked = new Set<HInstruction>();
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
  ClassElement jsFunctionClass;
  ClassElement jsNullClass;
  ClassElement jsBoolClass;

  ClassElement jsIndexableClass;
  ClassElement jsMutableArrayClass;
  ClassElement jsFixedArrayClass;
  ClassElement jsExtendableArrayClass;

  Element jsArrayLength;
  Element jsStringLength;
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

  // TODO(9577): Make it so that these are not needed when there are no native
  // classes.
  Element dispatchPropertyName;
  Element getNativeInterceptorMethod;
  Element defineNativeMethodsFinishMethod;
  Element getDispatchPropertyMethod;
  Element setDispatchPropertyMethod;

  bool seenAnyClass = false;

  final Namer namer;

  /**
   * Interface used to determine if an object has the JavaScript
   * indexing behavior. The interface is only visible to specific
   * libraries.
   */
  ClassElement jsIndexingBehaviorInterface;

  final Map<Element, ReturnInfo> returnInfo;

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: Elements must be declaration elements.
   */
  final List<Element> invalidateAfterCodegen;
  ArgumentTypesRegistry argumentTypes;
  FieldTypesRegistry fieldTypes;

  /**
   * A collection of selectors of intercepted method calls. The
   * emitter uses this set to generate the [:ObjectInterceptor:] class
   * whose members just forward the call to the intercepted receiver.
   */
  final Set<Selector> usedInterceptors;

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

  JavaScriptBackend(Compiler compiler, bool generateSourceMap, bool disableEval)
      : namer = determineNamer(compiler),
        returnInfo = new Map<Element, ReturnInfo>(),
        invalidateAfterCodegen = new List<Element>(),
        usedInterceptors = new Set<Selector>(),
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
    argumentTypes = new ArgumentTypesRegistry(this);
    fieldTypes = new FieldTypesRegistry(this);
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

  void addInterceptedSelector(Selector selector) {
    usedInterceptors.add(selector);
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
        result.add(classElement);
      }
      return result;
    });
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
      jsFunctionClass =
          compiler.findInterceptor(const SourceString('JSFunction')),
      jsBoolClass = compiler.findInterceptor(const SourceString('JSBool')),
      jsMutableArrayClass =
          compiler.findInterceptor(const SourceString('JSMutableArray')),
      jsFixedArrayClass =
          compiler.findInterceptor(const SourceString('JSFixedArray')),
      jsExtendableArrayClass =
          compiler.findInterceptor(const SourceString('JSExtendableArray'))];

    jsIndexableClass =
        compiler.findInterceptor(const SourceString('JSIndexable'));

    // TODO(kasperl): Some tests do not define the special JSArray
    // subclasses, so we check to see if they are defined before
    // trying to resolve them.
    if (jsFixedArrayClass != null) {
      jsFixedArrayClass.ensureResolved(compiler);
    }
    if (jsExtendableArrayClass != null) {
      jsExtendableArrayClass.ensureResolved(compiler);
    }

    jsArrayClass.ensureResolved(compiler);
    jsArrayLength = compiler.lookupElementIn(
        jsArrayClass, const SourceString('length'));
    jsArrayRemoveLast = compiler.lookupElementIn(
        jsArrayClass, const SourceString('removeLast'));
    jsArrayAdd = compiler.lookupElementIn(
        jsArrayClass, const SourceString('add'));

    jsStringClass.ensureResolved(compiler);
    jsStringLength = compiler.lookupElementIn(
        jsStringClass, const SourceString('length'));
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
  }

  void validateInterceptorImplementsAllObjectMethods(
      ClassElement interceptorClass) {
    if (interceptorClass == null) return;
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
          // All methods on [Object] are shadowed by [Interceptor].
          if (classElement == compiler.objectClass) return;
          Set<Element> set = interceptedElements.putIfAbsent(
              member.name, () => new Set<Element>());
          set.add(member);
          if (!classElement.isNative()) {
            MixinApplicationElement mixinApplication = classElement;
            assert(member.getEnclosingClass() == mixinApplication.mixin);
            classesMixedIntoNativeClasses.add(mixinApplication.mixin);
          }
        },
        includeSuperMembers: true);
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
        includeSuperMembers: true);
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

  void initializeNoSuchMethod() {
    // In case the emitter generates noSuchMethod calls, we need to
    // make sure all [noSuchMethod] methods know they might take a
    // [JsInvocationMirror] as parameter.
    HTypeList types = new HTypeList(1);
    types[0] = new HType.nonNullExact(
        compiler.jsInvocationMirrorClass.computeType(compiler),
        compiler);
    argumentTypes.registerDynamicInvocation(types, new Selector.noSuchMethod());
  }

  void registerInstantiatedClass(ClassElement cls,
                                 Enqueuer enqueuer,
                                 TreeElements elements) {
    if (!seenAnyClass) {
      initializeNoSuchMethod();
      seenAnyClass = true;
      if (enqueuer.isResolutionQueue) {
        // TODO(9577): Make it so that these are not needed when there are no
        // native classes.
        enqueuer.registerStaticUse(getNativeInterceptorMethod);
        enqueuer.registerStaticUse(defineNativeMethodsFinishMethod);
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
    } else if (cls == compiler.functionClass || cls == jsFunctionClass) {
      addInterceptors(jsFunctionClass, enqueuer, elements);
    } else if (cls == compiler.boolClass || cls == jsBoolClass) {
      addInterceptors(jsBoolClass, enqueuer, elements);
    } else if (cls == compiler.nullClass || cls == jsNullClass) {
      addInterceptors(jsNullClass, enqueuer, elements);
    } else if (cls == compiler.numClass || cls == jsNumberClass) {
      addInterceptors(jsIntClass, enqueuer, elements);
      addInterceptors(jsDoubleClass, enqueuer, elements);
      addInterceptors(jsNumberClass, enqueuer, elements);
    } else if (cls.isNative()) {
      addInterceptorsForNativeClassMembers(cls, enqueuer);
    }

    if (compiler.enableTypeAssertions) {
      // We need to register is checks for assignments to fields.
      cls.forEachLocalMember((Element member) {
        if (!member.isInstanceMember() || !member.isField()) return;
        DartType type = member.computeType(compiler);
        enqueuer.registerIsCheck(type, elements);
      });
    }
  }

  void registerUseInterceptor(Enqueuer enqueuer) {
    assert(!enqueuer.isResolutionQueue);
    // TODO(9577): Make it so that these are not needed when there are no native
    // classes.
    enqueuer.registerStaticUse(getNativeInterceptorMethod);
    enqueuer.registerStaticUse(defineNativeMethodsFinishMethod);
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

  void registerCatchStatement(TreeElements elements) {
    enqueueInResolution(getExceptionUnwrapper(), elements);
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

  void registerTypeLiteral(TreeElements elements) {
    enqueueInResolution(getCreateRuntimeType(), elements);
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

  void registerRuntimeType(TreeElements elements) {
    enqueueInResolution(getSetRuntimeTypeInfo(), elements);
    enqueueInResolution(getGetRuntimeTypeInfo(), elements);
    enqueueInResolution(getGetRuntimeTypeArgument(), elements);
    compiler.enqueuer.resolution.registerInstantiatedClass(
        compiler.listClass, elements);
  }

  void registerTypeVariableExpression(TreeElements elements) {
    registerRuntimeType(elements);
    enqueueInResolution(getRuntimeTypeToString(), elements);
    enqueueInResolution(getCreateRuntimeType(), elements);
  }

  void registerIsCheck(DartType type, Enqueuer world, TreeElements elements) {
    world.registerInstantiatedClass(compiler.boolClass, elements);
    bool isTypeVariable = type.kind == TypeKind.TYPE_VARIABLE;
    if (!type.isRaw || isTypeVariable) {
      enqueueInResolution(getSetRuntimeTypeInfo(), elements);
      enqueueInResolution(getGetRuntimeTypeInfo(), elements);
      enqueueInResolution(getGetRuntimeTypeArgument(), elements);
      enqueueInResolution(getCheckSubtype(), elements);
      if (isTypeVariable) {
        enqueueInResolution(getGetObjectIsSubtype(), elements);
      }
      world.registerInstantiatedClass(compiler.listClass, elements);
    }
    // [registerIsCheck] is also called for checked mode checks, so we
    // need to register checked mode helpers.
    if (compiler.enableTypeAssertions) {
      Element e = getCheckedModeHelper(type, typeCast: false);
      if (e != null) world.addToWorkList(e);
      // We also need the native variant of the check (for DOM types).
      e = getNativeCheckedModeHelper(type, typeCast: false);
      if (e != null) world.addToWorkList(e);
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
    Element e = getCheckedModeHelper(type, typeCast: true);
    enqueueInResolution(e, elements);
    // We also need the native variant of the check (for DOM types).
    e = getNativeCheckedModeHelper(type, typeCast: true);
    enqueueInResolution(e, elements);
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

  bool needsRti(ClassElement cls) {
    return rti.classesNeedingRti.contains(cls.declaration)
        || compiler.enabledRuntimeType;
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

  void enqueueInResolution(Element e, TreeElements elements) {
    if (e == null) return;
    ResolutionEnqueuer enqueuer = compiler.enqueuer.resolution;
    enqueuer.addToWorkList(e);
    elements.registerDependency(e);
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
    if (element.kind.category == ElementCategory.VARIABLE) {
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
    invalidateAfterCodegen.forEach(eagerRecompile);
    invalidateAfterCodegen.clear();
  }

  native.NativeEnqueuer nativeResolutionEnqueuer(Enqueuer world) {
    return new native.NativeResolutionEnqueuer(world, compiler);
  }

  native.NativeEnqueuer nativeCodegenEnqueuer(Enqueuer world) {
    return new native.NativeCodegenEnqueuer(world, compiler, emitter);
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

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [element] must be a declaration element.
   */
  void scheduleForRecompilation(Element element) {
    assert(invariant(element, element.isDeclaration));
    if (compiler.phase == Compiler.PHASE_COMPILING) {
      invalidateAfterCodegen.add(element);
    }
  }

  /**
   *  Register a dynamic invocation and collect the provided types for the
   *  named selector.
   */
  void registerDynamicInvocation(HInvokeDynamic node, Selector selector) {
    HTypeList providedTypes =
        new HTypeList.fromDynamicInvocation(node, selector);
    argumentTypes.registerDynamicInvocation(providedTypes, selector);
  }

  /**
   *  Register a static invocation and collect the provided types for the
   *  named selector.
   */
  void registerStaticInvocation(HInvokeStatic node) {
    argumentTypes.registerStaticInvocation(node);
  }

  /**
   *  Register that a static is used for something else than a direct call
   *  target.
   */
  void registerNonCallStaticUse(HStatic node) {
    argumentTypes.registerNonCallStaticUse(node);
  }

  /**
   * Retrieve the types of the parameters used for calling the [element]
   * function. The types are optimistic in the sense as they are based on the
   * possible invocations of the function seen so far.
   *
   * Invariant: [element] must be a declaration element.
   */
  HTypeList optimisticParameterTypes(
      FunctionElement element,
      OptionalParameterTypes defaultValueTypes) {
    assert(invariant(element, element.isDeclaration));
    if (element.parameterCount(compiler) == 0) return HTypeList.ALL_UNKNOWN;
    return argumentTypes.parameterTypes(element, defaultValueTypes);
  }

  /**
   * Register that the function [element] has been optimized under the
   * assumptions that the types [parameterType] will be used for calling it.
   * The passed [defaultValueTypes] holds the types of default values for
   * the optional parameters. If this assumption fail the function will be
   * scheduled for recompilation.
   *
   * Invariant: [element] must be a declaration element.
   */
  registerParameterTypesOptimization(
      FunctionElement element,
      HTypeList parameterTypes,
      OptionalParameterTypes defaultValueTypes) {
    assert(invariant(element, element.isDeclaration));
    if (element.parameterCount(compiler) == 0) return;
    argumentTypes.registerOptimizedFunction(
        element, parameterTypes, defaultValueTypes);
  }

  registerFieldTypesOptimization(FunctionElement element,
                                 Element field,
                                 HType type) {
    fieldTypes.registerOptimizedFunction(element, field, type);
  }

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [element] must be a declaration element.
   */
  void registerReturnType(FunctionElement element, HType returnType) {
    assert(invariant(element, element.isDeclaration));
    ReturnInfo info = returnInfo[element];
    if (info != null) {
      info.update(returnType, scheduleForRecompilation, compiler);
    } else {
      returnInfo[element] = new ReturnInfo(returnType);
    }
  }

  /**
   * Retrieve the return type of the function [callee]. The type is optimistic
   * in the sense that is is based on the compilation of [callee]. If [callee]
   * is recompiled the return type might change to someting broader. For that
   * reason [caller] is registered for recompilation if this happens. If the
   * function [callee] has not yet been compiled the returned type is [null].
   *
   * Invariant: Both [caller] and [callee] must be declaration elements.
   */
  HType optimisticReturnTypesWithRecompilationOnTypeChange(
      Element caller, FunctionElement callee) {
    assert(invariant(callee, callee.isDeclaration));
    returnInfo.putIfAbsent(callee, () => new ReturnInfo.unknownType());
    ReturnInfo info = returnInfo[callee];
    HType returnType = info.returnType;
    if (returnType != HType.UNKNOWN && returnType != null && caller != null) {
      assert(invariant(caller, caller.isDeclaration));
      info.addCompiledFunction(caller);
    }
    return info.returnType;
  }

  void dumpReturnTypes() {
    returnInfo.forEach((Element element, ReturnInfo info) {
      if (info.returnType != HType.UNKNOWN) {
        print("Inferred $element has return type ${info.returnType}");
      }
    });
  }

  void registerConstructor(Element element) {
    fieldTypes.registerConstructor(element);
  }

  void registerFieldInitializer(Element field, HType type) {
    fieldTypes.registerFieldInitializer(field, type);
  }

  void registerFieldConstructor(Element field, HType type) {
    fieldTypes.registerFieldConstructor(field, type);
  }

  void registerFieldSetter(FunctionElement element, Element field, HType type) {
    fieldTypes.registerFieldSetter(element, field, type);
  }

  void addedDynamicSetter(Selector setter, HType type) {
    fieldTypes.addedDynamicSetter(setter, type);
  }

  HType optimisticFieldType(Element element) {
    return fieldTypes.optimisticFieldType(element);
  }

  /**
   * Returns the checked mode helper that will be needed to do a type check/type
   * cast on [type] at runtime. Note that this method is being called both by
   * the resolver with interface types (int, String, ...), and by the SSA
   * backend with implementation types (JSInt, JSString, ...).
   */
  Element getCheckedModeHelper(DartType type, {bool typeCast}) {
    return compiler.findHelper(getCheckedModeHelperName(
        type, typeCast: typeCast, nativeCheckOnly: false));
  }

  /**
   * Returns the native checked mode helper that will be needed to do a type
   * check/type cast on [type] at runtime. If no native helper exists for
   * [type], [:null:] is returned.
   */
  Element getNativeCheckedModeHelper(DartType type, {bool typeCast}) {
    SourceString sourceName = getCheckedModeHelperName(
        type, typeCast: typeCast, nativeCheckOnly: true);
    if (sourceName == null) return null;
    return compiler.findHelper(sourceName);
  }

  /**
   * Returns the name of the type check/type cast helper method for [type]. If
   * [nativeCheckOnly] is [:true:], only names for native helpers are returned.
   */
  SourceString getCheckedModeHelperName(DartType type,
                                        {bool typeCast,
                                         bool nativeCheckOnly}) {
    Element element = type.element;
    bool nativeCheck = nativeCheckOnly ||
        emitter.nativeEmitter.requiresNativeIsCheck(element);
    if (type.isMalformed) {
      // Check for malformed types first, because the type may be a list type
      // with a malformed argument type.
      if (nativeCheckOnly) return null;
      return typeCast
          ? const SourceString('malformedTypeCast')
          : const SourceString('malformedTypeCheck');
    } else if (type == compiler.types.voidType) {
      assert(!typeCast); // Cannot cast to void.
      if (nativeCheckOnly) return null;
      return const SourceString('voidTypeCheck');
    } else if (element == jsStringClass || element == compiler.stringClass) {
      if (nativeCheckOnly) return null;
      return typeCast
          ? const SourceString("stringTypeCast")
          : const SourceString('stringTypeCheck');
    } else if (element == jsDoubleClass || element == compiler.doubleClass) {
      if (nativeCheckOnly) return null;
      return typeCast
          ? const SourceString("doubleTypeCast")
          : const SourceString('doubleTypeCheck');
    } else if (element == jsNumberClass || element == compiler.numClass) {
      if (nativeCheckOnly) return null;
      return typeCast
          ? const SourceString("numTypeCast")
          : const SourceString('numTypeCheck');
    } else if (element == jsBoolClass || element == compiler.boolClass) {
      if (nativeCheckOnly) return null;
      return typeCast
          ? const SourceString("boolTypeCast")
          : const SourceString('boolTypeCheck');
    } else if (element == jsFunctionClass ||
               element == compiler.functionClass) {
      if (nativeCheckOnly) return null;
      return typeCast
          ? const SourceString("functionTypeCast")
          : const SourceString('functionTypeCheck');
    } else if (element == jsIntClass || element == compiler.intClass) {
      if (nativeCheckOnly) return null;
      return typeCast ?
          const SourceString("intTypeCast") :
          const SourceString('intTypeCheck');
    } else if (Elements.isNumberOrStringSupertype(element, compiler)) {
      if (nativeCheck) {
        return typeCast
            ? const SourceString("numberOrStringSuperNativeTypeCast")
            : const SourceString('numberOrStringSuperNativeTypeCheck');
      } else {
        return typeCast
          ? const SourceString("numberOrStringSuperTypeCast")
          : const SourceString('numberOrStringSuperTypeCheck');
      }
    } else if (Elements.isStringOnlySupertype(element, compiler)) {
      if (nativeCheck) {
        return typeCast
            ? const SourceString("stringSuperNativeTypeCast")
            : const SourceString('stringSuperNativeTypeCheck');
      } else {
        return typeCast
            ? const SourceString("stringSuperTypeCast")
            : const SourceString('stringSuperTypeCheck');
      }
    } else if (element == compiler.listClass || element == jsArrayClass) {
      if (nativeCheckOnly) return null;
      return typeCast
          ? const SourceString("listTypeCast")
          : const SourceString('listTypeCheck');
    } else {
      if (Elements.isListSupertype(element, compiler)) {
        if (nativeCheck) {
          return typeCast
              ? const SourceString("listSuperNativeTypeCast")
              : const SourceString('listSuperNativeTypeCheck');
        } else {
          return typeCast
              ? const SourceString("listSuperTypeCast")
              : const SourceString('listSuperTypeCheck');
        }
      } else {
        if (nativeCheck) {
          return typeCast
              ? const SourceString("interceptedTypeCast")
              : const SourceString('interceptedTypeCheck');
        } else {
          return typeCast
              ? const SourceString("propertyTypeCast")
              : const SourceString('propertyTypeCheck');
        }
      }
    }
  }

  void dumpInferredTypes() {
    print("Inferred argument types:");
    print("------------------------");
    argumentTypes.dump();
    print("");
    print("Inferred return types:");
    print("----------------------");
    dumpReturnTypes();
    print("");
    print("Inferred field types:");
    print("------------------------");
    fieldTypes.dump();
    print("");
  }

  Element getExceptionUnwrapper() {
    return compiler.findHelper(const SourceString('unwrapException'));
  }

  Element getThrowRuntimeError() {
    return compiler.findHelper(const SourceString('throwRuntimeError'));
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

  Element getGetRuntimeTypeArgument() {
    return compiler.findHelper(const SourceString('getRuntimeTypeArgument'));
  }

  Element getRuntimeTypeToString() {
    return compiler.findHelper(const SourceString('runtimeTypeToString'));
  }

  Element getCheckSubtype() {
    return compiler.findHelper(const SourceString('checkSubtype'));
  }

  Element getGetObjectIsSubtype() {
    return compiler.findHelper(const SourceString('objectIsSubtype'));
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
  ClassElement get functionImplementation => jsFunctionClass;
  ClassElement get typeImplementation => typeLiteralClass;
  ClassElement get boolImplementation => jsBoolClass;
  ClassElement get nullImplementation => jsNullClass;
}
