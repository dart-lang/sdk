// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class InvocationInfo {
  int parameterCount;
  List<HType> providedTypes;
  List<Element> compiledFunctions;

  InvocationInfo(List<HType> types)
      : parameterCount = types != null ? types.length : -1,
        providedTypes = types,
        compiledFunctions = new List<Element>();

  addCompiledFunction(FunctionElement function) =>
      compiledFunctions.add(function);

  void clearTypeInformation() => providedTypes = null;
  bool get hasTypeInformation() => providedTypes != null;

}

class JavaScriptBackend extends Backend {
  SsaBuilderTask builder;
  SsaOptimizerTask optimizer;
  SsaCodeGeneratorTask generator;
  CodeEmitterTask emitter;
  final Map<Element, Map<Element, HType>> fieldInitializers;
  final Map<Element, Map<Element, HType>> fieldConstructorSetters;
  final Map<Element, Map<Element, HType>> fieldSettersType;

  final Map<SourceString, Map<Selector, InvocationInfo>> invocationInfo;

  List<CompilerTask> get tasks() {
    return <CompilerTask>[builder, optimizer, generator, emitter];
  }

  JavaScriptBackend(Compiler compiler, bool generateSourceMap)
      : emitter = new CodeEmitterTask(compiler, generateSourceMap),
        fieldInitializers = new Map<Element, Map<Element, HType>>(),
        fieldConstructorSetters = new Map<Element, Map<Element, HType>>(),
        fieldSettersType = new Map<Element, Map<Element, HType>>(),
        invocationInfo = new Map<SourceString, Map<Selector, InvocationInfo>>(),
        super(compiler) {
    builder = new SsaBuilderTask(this);
    optimizer = new SsaOptimizerTask(this);
    generator = new SsaCodeGeneratorTask(this);
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

  CodeBuffer codegen(WorkItem work) {
    HGraph graph = builder.build(work);
    optimizer.optimize(work, graph);
    if (work.allowSpeculativeOptimization
        && optimizer.trySpeculativeOptimizations(work, graph)) {
      CodeBuffer codeBuffer = generator.generateBailoutMethod(work, graph);
      compiler.codegenWorld.addBailoutCode(work, codeBuffer);
      optimizer.prepareForSpeculativeOptimizations(work, graph);
      optimizer.optimize(work, graph);
    }
    return generator.generateMethod(work, graph);
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
      if (classElement.constructors.length == 1) {
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

  /**
   *  Register a dynamic invocation and collect the provided types for the
   *  named selector.
   */
  void registerDynamicInvocation(HInvokeDynamicMethod node, Selector selector) {
    Map<Selector, InvocationInfo> invocationInfos =
        invocationInfo.putIfAbsent(node.name,
                                   () => new Map<Selector, InvocationInfo>());
    InvocationInfo info = invocationInfos[selector];
    if (info != null) {
      // If we don't know anything useful about the types adding more
      // information will not help.
      if (!info.hasTypeInformation) return;

      // Update the type information with the provided types.
      bool typesChanged = false;
      List<HType> types = info.providedTypes;
      bool allUnknown = true;
      for (int i = 0; i < types.length; i++) {
        HType newType = types[i].union(node.inputs[i + 1].propagatedType);
        if (newType != types[i]) {
          typesChanged = true;
          types[i] = newType;
        }
        if (types[i] != HType.UNKNOWN) allUnknown = false;
      }
      // If the provided types change we need to recompile all functions which
      // have been compiled under the now invalidated assumptions.
      if (typesChanged && info.compiledFunctions.length != 0) {
        if (compiler.phase == Compiler.PHASE_COMPILING) {
          info.compiledFunctions.forEach(
              compiler.enqueuer.codegen.eagerRecompile);
          info.compiledFunctions.clear();
        }
      }
      // If all information is lost no need to keep it around.
      if (allUnknown) info.clearTypeInformation();
    } else {
      // Gather the type information provided. If the types contains no useful
      // information there is no need to actually store them.
      bool allUnknown = true;
      for (int i = 1; i < node.inputs.length; i++) {
        if (node.inputs[i].propagatedType != HType.UNKNOWN) {
          allUnknown = false;
          break;
        }
      }
      List<HType> types = null;
      if (!allUnknown) {
        types = new List<HType>(node.inputs.length - 1);
        for (int i = 0; i < types.length; i++) {
          types[i] = node.inputs[i + 1].propagatedType;
        }
      }
      InvocationInfo info = new InvocationInfo(types);
      invocationInfos[selector] = info;
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
