// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef void Recompile(Element element);

class InvocationInfo {
  int parameterCount = -1;
  List<HType> providedTypes;
  List<Element> compiledFunctions;

  InvocationInfo(HInvoke node, HTypeMap types)
      : compiledFunctions = new List<Element>() {
    assert(node != null);
    // Gather the type information provided. If the types contains no useful
    // information there is no need to actually store them.
    bool allUnknown = true;
    for (int i = 1; i < node.inputs.length; i++) {
      if (types[node.inputs[i]] != HType.UNKNOWN) {
        allUnknown = false;
        break;
      }
    }
    if (!allUnknown) {
      providedTypes = new List<HType>(node.inputs.length - 1);
      for (int i = 0; i < providedTypes.length; i++) {
        providedTypes[i] = types[node.inputs[i + 1]];
      }
      parameterCount = providedTypes.length;
    }
  }

  InvocationInfo.unknownTypes();

  void update(HInvoke node, HTypeMap types, Recompile recompile) {
    // If we don't know anything useful about the types adding more
    // information will not help.
    if (!hasTypeInformation) return;

    // Update the type information with the provided types.
    bool typesChanged = false;
    bool allUnknown = true;

    if (providedTypes.length != node.inputs.length - 1) {
      // If the signatures don't match, remove all optimizations on
      // that selector.
      typesChanged = true;
      allUnknown = true;
    } else {
      for (int i = 0; i < providedTypes.length; i++) {
        HType newType = providedTypes[i].union(types[node.inputs[i + 1]]);
        if (newType != providedTypes[i]) {
          typesChanged = true;
          providedTypes[i] = newType;
        }
        if (providedTypes[i] != HType.UNKNOWN) allUnknown = false;
      }
    }
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
    Element element = node.element;
    Universe resolverWorld = compiler.resolverWorld;
    // If there are any getters for this method we cannot know anything about
    // the types of the provided parameters. Use resolverWorld for now as that
    // information does not change during compilation.
    // TODO(sgjesse): These checks should use the codegenWorld and keep track
    // of changes to this information.
    if (element != null &&
        (resolverWorld.hasFieldGetter(element, compiler) ||
         resolverWorld.hasInvokedGetter(element, compiler))) {
      return;
    }
    Map<Selector, InvocationInfo> invocationInfos =
        invocationInfo.putIfAbsent(selector.name,
                                   () => new Map<Selector, InvocationInfo>());
    if (!invocationInfos.isEmpty()) {
      invocationInfos.forEach((Selector _, InvocationInfo info) {
        // TODO(ngeoffray): Check that the signature of [info] applies to
        // [element]. We cannot do that right now because the
        // strategy is all or nothing. We should actually retain the
        // methods that don't apply to [selector].
        info.update(node, types, recompile);
      });
    } else {
      invocationInfos[selector] = new InvocationInfo(node, types);
    }
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
   * Retreive the types of the parameters used for calling the [element]
   * function. The types are optimistic in the sense as they are based on the
   * possible invocations of the function seen so far. As compiling more
   * code can invalidate this asumption the function is registered for being
   * re-compiled if new possible invocations of this function invalidate these
   * asumptions.
   */
  List<HType> optimisticParameterTypesWithRecompilationOnTypeChange(
      FunctionElement element) {
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
    } else {
      Map<Selector, InvocationInfo> invocationInfos =
          invocationInfo[element.name];
      if (invocationInfos == null) return null;

      int foundCount = 0;
      InvocationInfo found = null;
      invocationInfos.forEach((Selector selector, InvocationInfo info) {
        if (selector.applies(element, compiler)) {
          found = info;
          foundCount++;
        }
      });

      if (foundCount == 1 && found.hasTypeInformation) {
        FunctionSignature signature = element.computeSignature(compiler);
        if (signature.parameterCount == found.parameterCount) {
          found.addCompiledFunction(element);
          return found.providedTypes;
        }
      }
      return null;
    }
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
   * Retreive the return type of the function [callee]. The type is optimistic
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
