// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef void Recompile(Element element);

// Gather the type information provided. If the types contains no
// useful information there is no need to actually store them.
List<HType> computeProvidedTypes(HInvoke node, HTypeMap types) {
  bool allUnknown = true;
  for (int i = 1; i < node.inputs.length; i++) {
    if (types[node.inputs[i]] != HType.UNKNOWN) {
      allUnknown = false;
      break;
    }
  }
  if (allUnknown) return null;

  List<HType> result = new List<HType>(node.inputs.length - 1);
  for (int i = 0; i < result.length; i++) {
    result[i] = types[node.inputs[i + 1]];
  }
  return result;
}

// TODO(kasperl): Refactor this method once we've gotten rid of
// InvocationInfo.
void updateTypes(List<HType> old, HInvoke node, HTypeMap types,
                 callback(bool typesChanged, bool allUnknown)) {
  // Update the type information with the provided types.
  if (old === null) {
    callback(false, true);
    return;
  }

  bool typesChanged = false;
  bool allUnknown = true;
  if (old.length != node.inputs.length - 1) {
    // If the signatures don't match, remove all optimizations on
    // that selector.
    typesChanged = true;
    allUnknown = true;
  } else {
    for (int i = 0; i < old.length; i++) {
      HType newType = old[i].union(types[node.inputs[i + 1]]);
      if (newType != old[i]) {
        typesChanged = true;
        old[i] = newType;
      }
      if (old[i] != HType.UNKNOWN) allUnknown = false;
    }
  }
  callback(typesChanged, allUnknown);
}

class InvocationInfo {
  int parameterCount = -1;
  List<HType> providedTypes;
  List<Element> compiledFunctions;

  InvocationInfo(HInvoke node, HTypeMap types)
      : compiledFunctions = new List<Element>() {
    assert(node != null);
    providedTypes = computeProvidedTypes(node, types);
    if (providedTypes !== null) {
      parameterCount = providedTypes.length;
    }
  }

  InvocationInfo.unknownTypes();

  void update(HInvoke node, HTypeMap types, Recompile recompile) {
    // If we don't know anything useful about the types adding more
    // information will not help.
    updateTypes(providedTypes, node, types,
        (bool typesChanged, bool allUnknown) {
      // If the provided types change we need to recompile all functions which
      // have been compiled under the now invalidated assumptions.
      if (typesChanged && compiledFunctions.length != 0) {
        if (recompile != null) {
          compiledFunctions.forEach(recompile);
        }
        compiledFunctions.clear();
      }
      // If all information is lost no need to keep it around.
      if (allUnknown) clearTypeInformation();
    });
  }

  addCompiledFunction(FunctionElement function) =>
      compiledFunctions.add(function);

  void clearTypeInformation() { providedTypes = null; }
  bool get hasTypeInformation => providedTypes != null;

}

class ReturnInfo {
  HType returnType;
  List<Element> compiledFunctions;

  ReturnInfo(HType this.returnType)
      : compiledFunctions = new List<Element>();

  ReturnInfo.unknownType()
      : this.returnType = null,
        compiledFunctions = new List<Element>();

  void update(HType type, Recompile recompile) {
    HType newType = returnType != null ? returnType.union(type) : type;
    if (newType != returnType) {
      if (returnType == null && newType === HType.UNKNOWN) {
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

  addCompiledFunction(FunctionElement function) =>
      compiledFunctions.add(function);
}

class JavaScriptItemCompilationContext extends ItemCompilationContext {
  final HTypeMap types;

  JavaScriptItemCompilationContext() : types = new HTypeMap();
}

class JavaScriptBackend extends Backend {
  SsaBuilderTask builder;
  SsaOptimizerTask optimizer;
  SsaCodeGeneratorTask generator;
  CodeEmitterTask emitter;
  final Map<Element, Map<Element, HType>> fieldInitializers;
  final Map<Element, Map<Element, HType>> fieldConstructorSetters;
  final Map<Element, Map<Element, HType>> fieldSettersType;

  final Map<Element, InvocationInfo> staticInvocationInfo;
  final Map<SourceString, Map<Selector, InvocationInfo>> invocationInfo;
  final Map<Element, ReturnInfo> returnInfo;

  final List<Element> invalidateAfterCodegen;
  final SelectorMap<List<HType>> selectorTypeMap;
  final FunctionSet optimizedFunctions;
  final Map<Element, List<HType>> optimizedTypes;

  List<CompilerTask> get tasks {
    return <CompilerTask>[builder, optimizer, generator, emitter];
  }

  JavaScriptBackend(Compiler compiler, bool generateSourceMap)
      : emitter = new CodeEmitterTask(compiler, generateSourceMap),
        fieldInitializers = new Map<Element, Map<Element, HType>>(),
        fieldConstructorSetters = new Map<Element, Map<Element, HType>>(),
        fieldSettersType = new Map<Element, Map<Element, HType>>(),
        invocationInfo = new Map<SourceString, Map<Selector, InvocationInfo>>(),
        staticInvocationInfo = new Map<Element, InvocationInfo>(),
        returnInfo = new Map<Element, ReturnInfo>(),
        invalidateAfterCodegen = new List<Element>(),
        selectorTypeMap = new SelectorMap<List<HType>>(compiler),
        optimizedFunctions = new FunctionSet(compiler),
        optimizedTypes = new Map<Element, List<HType>>(),
        super(compiler) {
    builder = new SsaBuilderTask(this);
    optimizer = new SsaOptimizerTask(this);
    generator = new SsaCodeGeneratorTask(this);
  }

  JavaScriptItemCompilationContext createItemCompilationContext() {
    return new JavaScriptItemCompilationContext();
  }

  void enqueueHelpers(Enqueuer world) {
    enqueueAllTopLevelFunctions(compiler.jsHelperLibrary, world);
    enqueueAllTopLevelFunctions(compiler.interceptorsLibrary, world);
    for (var helper in [const SourceString('Closure'),
                        const SourceString('ConstantMap'),
                        const SourceString('ConstantProtoMap')]) {
      var e = compiler.findHelper(helper);
      if (e !== null) world.registerInstantiatedClass(e);
    }
  }

  void codegen(WorkItem work) {
    HGraph graph = builder.build(work);
    optimizer.optimize(work, graph);
    if (work.allowSpeculativeOptimization
        && optimizer.trySpeculativeOptimizations(work, graph)) {
      CodeBuffer codeBuffer = generator.generateBailoutMethod(work, graph);
      compiler.codegenWorld.addBailoutCode(work, codeBuffer);
      optimizer.prepareForSpeculativeOptimizations(work, graph);
      optimizer.optimize(work, graph);
    }
    CodeBuffer codeBuffer = generator.generateMethod(work, graph);
    compiler.codegenWorld.addGeneratedCode(work, codeBuffer);
    invalidateAfterCodegen.forEach(
      compiler.enqueuer.codegen.eagerRecompile);
    invalidateAfterCodegen.clear();
  }

  void processNativeClasses(Enqueuer world,
                            Collection<LibraryElement> libraries) {
    native.processNativeClasses(world, emitter, libraries);
  }

  void assembleProgram() {
    emitter.assembleProgram();
  }

  void updateFieldInitializers(Element field, HType propagatedType) {
    assert(field.isField());
    assert(field.isMember());
    Map<Element, HType> fields =
        fieldInitializers.putIfAbsent(
          field.getEnclosingClass(), () => new Map<Element, HType>());
    if (!fields.containsKey(field)) {
      fields[field] = propagatedType;
    } else {
      fields[field] = fields[field].union(propagatedType);
    }
  }

  HType typeFromInitializersSoFar(Element field) {
    assert(field.isField());
    assert(field.isMember());
    if (!fieldInitializers.containsKey(field.getEnclosingClass())) {
      return HType.CONFLICTING;
    }
    Map<Element, HType> fields = fieldInitializers[field.getEnclosingClass()];
    return fields[field];
  }

  void updateFieldConstructorSetters(Element field, HType type) {
    assert(field.isField());
    assert(field.isMember());
    Map<Element, HType> fields =
        fieldConstructorSetters.putIfAbsent(
            field.getEnclosingClass(), () => new Map<Element, HType>());
    if (!fields.containsKey(field)) {
      fields[field] = type;
    } else {
      fields[field] = fields[field].union(type);
    }
  }

  // Check if this field is set in the constructor body.
  bool hasConstructorBodyFieldSetter(Element field) {
    ClassElement enclosingClass = field.getEnclosingClass();
    if (!fieldConstructorSetters.containsKey(enclosingClass)) {
      return false;
    }
    return fieldConstructorSetters[enclosingClass][field] != null;
  }

  // Provide an optimistic estimate of the type of a field after construction.
  // If the constructor body has setters for fields returns HType.UNKNOWN.
  // This only takes the initializer lists and field assignments in the
  // constructor body into account. The constructor body might have method calls
  // that could alter the field.
  HType optimisticFieldTypeAfterConstruction(Element field) {
    assert(field.isField());
    assert(field.isMember());

    ClassElement classElement = field.getEnclosingClass();
    if (hasConstructorBodyFieldSetter(field)) {
      // If there are field setters but there is only constructor then the type
      // of the field is determined by the assignments in the constructor
      // body.
      var constructors = classElement.constructors;
      if (constructors.head !== null && constructors.tail.isEmpty()) {
        return fieldConstructorSetters[classElement][field];
      } else {
        return HType.UNKNOWN;
      }
    } else if (fieldInitializers.containsKey(classElement)) {
      HType type = fieldInitializers[classElement][field];
      return type == null ? HType.CONFLICTING : type;
    } else {
      return HType.CONFLICTING;
    }
  }

  void updateFieldSetters(Element field, HType type) {
    assert(field.isField());
    assert(field.isMember());
    Map<Element, HType> fields =
        fieldSettersType.putIfAbsent(
          field.getEnclosingClass(), () => new Map<Element, HType>());
    if (!fields.containsKey(field)) {
      fields[field] = type;
    } else {
      fields[field] = fields[field].union(type);
    }
  }

  // Returns the type that field setters are setting the field to based on what
  // have been seen during compilation so far.
  HType fieldSettersTypeSoFar(Element field) {
    assert(field.isField());
    assert(field.isMember());
    ClassElement enclosingClass = field.getEnclosingClass();
    if (!fieldSettersType.containsKey(enclosingClass)) {
      return HType.CONFLICTING;
    }
    Map<Element, HType> fields = fieldSettersType[enclosingClass];
    if (!fields.containsKey(field)) return HType.CONFLICTING;
    return fields[field];
  }

  void recompile(Element element) {
    if (compiler.phase == Compiler.PHASE_COMPILING) {
      invalidateAfterCodegen.add(element);
    }
  }

  /**
   *  Register a dynamic invocation and collect the provided types for the
   *  named selector.
   */
  void registerDynamicInvocation(HInvokeDynamicMethod node,
                                 Selector selector,
                                 HTypeMap types) {
    // If there are any getters for this method we cannot know anything about
    // the types of the provided parameters. Use resolverWorld for now as that
    // information does not change during compilation.
    // TODO(sgjesse): These checks should use the codegenWorld and keep track
    // of changes to this information.
    Element element = node.element;
    Universe resolverWorld = compiler.resolverWorld;
    if (element != null &&
        (resolverWorld.hasFieldGetter(element, compiler) ||
         resolverWorld.hasInvokedGetter(element, compiler))) {
      return;
    }

    // TODO(kasperl): For now, we're only dealing with non-named arguments.
    // We should generalize this.
    List<HType> providedTypes = selector.namedArguments.isEmpty()
        ? computeProvidedTypes(node, types)
        : null;
    if (!selectorTypeMap.containsKey(selector)) {
      selectorTypeMap[selector] = providedTypes;
    } else {
      List<HType> oldTypes = selectorTypeMap[selector];
      updateTypes(oldTypes, node, types, (bool typesChanged, bool allUnknown) {
        if (!typesChanged) return;
        if (allUnknown) selectorTypeMap[selector] = null;
      });
    }

    // If we're not compiling, we don't have to do anything.
    if (compiler.phase != Compiler.PHASE_COMPILING) return;

    // Run through all optimized functions and figure out if they need
    // to be recompiled because of this new invocation.
    optimizedFunctions.filterBySelector(selector).forEach((Element element) {
      // TODO(kasperl): Maybe check if the element is already marked for
      // recompilation? Could be pretty cheap compared to computing
      // union types.
      List<HType> newTypes =
          optimisticParameterTypesWithRecompilationOnTypeChange(element);
      bool recompile = false;
      if (newTypes === null) {
        recompile = true;
      } else {
        List<HType> oldTypes = optimizedTypes[element];
        if (newTypes.length != oldTypes.length) {
          // TODO(kasperl): This can be improved. If the newTypes aren't in
          // conflict we can avoid the recompilation.
          recompile = true;
        } else for (int i = 0; i < oldTypes.length; i++) {
          if (newTypes[i] != oldTypes[i]) {
            recompile = true;
            break;
          }
        }
      }
      if (recompile) invalidateAfterCodegen.add(element);
    });
  }

  /**
   *  Register a static invocation and collect the provided types for the
   *  named selector.
   */
  void registerStaticInvocation(HInvokeStatic node, HTypeMap types) {
    InvocationInfo info = staticInvocationInfo[node.element];
    if (info != null) {
      info.update(node, types, recompile);
    } else {
      staticInvocationInfo[node.element] = new InvocationInfo(node, types);
    }
  }

  /**
   *  Register that a static is used for something else than a call target.
   */
  void registerNonCallStaticUse(HStatic node) {
    // When a static is used for anything else than a call target we cannot
    // infer anything about its parameter types.
    InvocationInfo info = staticInvocationInfo[node.element];
    if (info == null) {
      staticInvocationInfo[node.element] = new InvocationInfo.unknownTypes();
    } else {
      info.clearTypeInformation();
      if (info.compiledFunctions != null &&
          info.compiledFunctions.length != 0) {
        if (compiler.phase == Compiler.PHASE_COMPILING) {
          info.compiledFunctions.forEach(invalidateAfterCodegen.add);
          info.compiledFunctions.clear();
        }
      }
    }
  }

  /**
   * Retrieve the types of the parameters used for calling the [element]
   * function. The types are optimistic in the sense as they are based on the
   * possible invocations of the function seen so far. As compiling more
   * code can invalidate this asumption the function is registered for being
   * re-compiled if new possible invocations of this function invalidate these
   * asumptions.
   */
  List<HType> optimisticParameterTypesWithRecompilationOnTypeChange(
      FunctionElement element) {

    // TODO(kasperl): Fold this into the visitMatching code somehow.
    if (Elements.isStaticOrTopLevelFunction(element)) {
      InvocationInfo found = staticInvocationInfo[element];
      if (found != null && found.hasTypeInformation) {
        FunctionSignature signature = element.computeSignature(compiler);
        if (signature.parameterCount == found.parameterCount) {
          found.addCompiledFunction(element);
          return found.providedTypes;
        }
      }
      return null;
    }

    // TODO(kasperl): What kind of non-members do we get here?
    if (!element.isMember()) return null;

    // TODO(kasperl): Clean this up.
    FunctionSignature signature = element.computeSignature(compiler);
    List<HType> found = null;
    selectorTypeMap.visitMatching(element,
        (Selector selector, List<HType> types) {
      if (selector.argumentCount != signature.parameterCount ||
          types === null) {
        found = null;
        return false;
      } else if (found === null) {
        found = types;
        return true;
      } else {
        found = null;
        return false;
      }
    });
    return found;
  }

  void registerReturnType(FunctionElement element, HType returnType) {
    ReturnInfo info = returnInfo[element];
    if (info != null) {
      info.update(returnType, recompile);
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
   */
  HType optimisticReturnTypesWithRecompilationOnTypeChange(
      FunctionElement caller, FunctionElement callee) {
    returnInfo.putIfAbsent(callee, () => new ReturnInfo.unknownType());
    ReturnInfo info = returnInfo[callee];
    if (info.returnType != HType.UNKNOWN && caller != null) {
      info.addCompiledFunction(caller);
    }
    return info.returnType;
  }
}
