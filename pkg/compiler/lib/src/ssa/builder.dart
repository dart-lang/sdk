// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of ssa;

class SsaFunctionCompiler implements FunctionCompiler {
  final SsaCodeGeneratorTask generator;
  final SsaBuilderTask builder;
  final SsaOptimizerTask optimizer;
  final JavaScriptBackend backend;

  SsaFunctionCompiler(JavaScriptBackend backend,
                      SourceInformationStrategy sourceInformationFactory)
      : generator = new SsaCodeGeneratorTask(backend, sourceInformationFactory),
        builder = new SsaBuilderTask(backend, sourceInformationFactory),
        optimizer = new SsaOptimizerTask(backend),
        backend = backend;

  /// Generates JavaScript code for `work.element`.
  /// Using the ssa builder, optimizer and codegenerator.
  js.Fun compile(CodegenWorkItem work) {
    HGraph graph = builder.build(work);
    optimizer.optimize(work, graph);
    Element element = work.element;
    js.Expression result = generator.generateCode(work, graph);
    if (element is FunctionElement) {
      result = backend.rewriteAsync(element, result);
    }
    return result;
  }

  Iterable<CompilerTask> get tasks {
    return <CompilerTask>[builder, optimizer, generator];
  }
}

/// A synthetic local variable only used with the SSA graph.
///
/// For instance used for holding return value of function or the exception of a
/// try-catch statement.
class SyntheticLocal extends Local {
  final String name;
  final ExecutableElement executableContext;

  SyntheticLocal(this.name, this.executableContext);

  toString() => 'SyntheticLocal($name)';
}

class SsaBuilderTask extends CompilerTask {
  final CodeEmitterTask emitter;
  final JavaScriptBackend backend;
  final SourceInformationStrategy sourceInformationFactory;

  String get name => 'SSA builder';

  SsaBuilderTask(JavaScriptBackend backend, this.sourceInformationFactory)
    : emitter = backend.emitter,
      backend = backend,
      super(backend.compiler);

  DiagnosticReporter get reporter => compiler.reporter;

  HGraph build(CodegenWorkItem work) {
    return measure(() {
      Element element = work.element.implementation;
      return reporter.withCurrentElement(element, () {
        SsaBuilder builder =
            new SsaBuilder(work.element.implementation,
                work.resolutionTree, work.compilationContext, work.registry,
                backend, emitter.nativeEmitter,
                sourceInformationFactory);
        HGraph graph = builder.build();

        // Default arguments are handled elsewhere, but we must ensure
        // that the default values are computed during codegen.
        if (!identical(element.kind, ElementKind.FIELD)) {
          FunctionElement function = element;
          FunctionSignature signature = function.functionSignature;
          signature.forEachOptionalParameter((ParameterElement parameter) {
            // This ensures the default value will be computed.
            ConstantValue constant =
                backend.constants.getConstantValueForVariable(parameter);
            work.registry.registerCompileTimeConstant(constant);
          });
        }
        if (compiler.tracer.isEnabled) {
          String name;
          if (element.isClassMember) {
            String className = element.enclosingClass.name;
            String memberName = element.name;
            name = "$className.$memberName";
            if (element.isGenerativeConstructorBody) {
              name = "$name (body)";
            }
          } else {
            name = "${element.name}";
          }
          compiler.tracer.traceCompilation(
              name, work.compilationContext);
          compiler.tracer.traceGraph('builder', graph);
        }
        return graph;
      });
    });
  }

}

/**
 * Keeps track of locals (including parameters and phis) when building. The
 * 'this' reference is treated as parameter and hence handled by this class,
 * too.
 */
class LocalsHandler {
  /**
   * The values of locals that can be directly accessed (without redirections
   * to boxes or closure-fields).
   *
   * [directLocals] is iterated, so it is "insertion ordered" to make the
   * iteration order a function only of insertions and not a function of
   * e.g. Element hash codes.  I'd prefer to use a SortedMap but some elements
   * don't have source locations for [Elements.compareByPosition].
   */
  Map<Local, HInstruction> directLocals =
      new Map<Local, HInstruction>();
  Map<Local, CapturedVariable> redirectionMapping =
      new Map<Local, CapturedVariable>();
  SsaBuilder builder;
  ClosureClassMap closureData;
  Map<TypeVariableType, TypeVariableLocal> typeVariableLocals =
      new Map<TypeVariableType, TypeVariableLocal>();
  final ExecutableElement executableContext;

  /// The class that defines the current type environment or null if no type
  /// variables are in scope.
  ClassElement get contextClass => executableContext.contextClass;

  /// The type of the current instance, if concrete.
  ///
  /// This allows for handling fixed type argument in case of inlining. For
  /// instance, checking `'foo'` against `String` instead of `T` in `main`:
  ///
  ///     class Foo<T> {
  ///       T field;
  ///       Foo(this.field);
  ///     }
  ///     main() {
  ///       new Foo<String>('foo');
  ///     }
  ///
  /// [instanceType] is not used if it contains type variables, since these
  /// might not be in scope or from the current instance.
  ///
  final InterfaceType instanceType;

  SourceInformationBuilder get sourceInformationBuilder {
    return builder.sourceInformationBuilder;
  }

  LocalsHandler(this.builder, this.executableContext,
                InterfaceType instanceType)
      : this.instanceType =
          instanceType == null || instanceType.containsTypeVariables
              ? null : instanceType;

  /// Substituted type variables occurring in [type] into the context of
  /// [contextClass].
  DartType substInContext(DartType type) {
    if (contextClass != null) {
      ClassElement typeContext = Types.getClassContext(type);
      if (typeContext != null) {
        type = type.substByContext(
            contextClass.asInstanceOf(typeContext));
      }
    }
    if (instanceType != null) {
      type = type.substByContext(instanceType);
    }
    return type;
  }

  get typesTask => builder.compiler.typesTask;

  /**
   * Creates a new [LocalsHandler] based on [other]. We only need to
   * copy the [directLocals], since the other fields can be shared
   * throughout the AST visit.
   */
  LocalsHandler.from(LocalsHandler other)
      : directLocals = new Map<Local, HInstruction>.from(other.directLocals),
        redirectionMapping = other.redirectionMapping,
        executableContext = other.executableContext,
        instanceType = other.instanceType,
        builder = other.builder,
        closureData = other.closureData;

  /**
   * Redirects accesses from element [from] to element [to]. The [to] element
   * must be a boxed variable or a variable that is stored in a closure-field.
   */
  void redirectElement(Local from, CapturedVariable to) {
    assert(redirectionMapping[from] == null);
    redirectionMapping[from] = to;
    assert(isStoredInClosureField(from) || isBoxed(from));
  }

  HInstruction createBox() {
    // TODO(floitsch): Clean up this hack. Should we create a box-object by
    // just creating an empty object literal?
    JavaScriptBackend backend = builder.backend;
    HInstruction box = new HForeignCode(
        js.js.parseForeignJS('{}'),
        backend.nonNullType,
        <HInstruction>[],
        nativeBehavior: native.NativeBehavior.PURE_ALLOCATION);
    builder.add(box);
    return box;
  }

  /**
   * If the scope (function or loop) [node] has captured variables then this
   * method creates a box and sets up the redirections.
   */
  void enterScope(ast.Node node, Element element) {
    // See if any variable in the top-scope of the function is captured. If yes
    // we need to create a box-object.
    ClosureScope scopeData = closureData.capturingScopes[node];
    if (scopeData == null) return;
    HInstruction box;
    // The scope has captured variables.
    if (element != null && element.isGenerativeConstructorBody) {
      // The box is passed as a parameter to a generative
      // constructor body.
      JavaScriptBackend backend = builder.backend;
      box = builder.addParameter(scopeData.boxElement, backend.nonNullType);
    } else {
      box = createBox();
    }
    // Add the box to the known locals.
    directLocals[scopeData.boxElement] = box;
    // Make sure that accesses to the boxed locals go into the box. We also
    // need to make sure that parameters are copied into the box if necessary.
    scopeData.forEachCapturedVariable(
        (LocalVariableElement from, BoxFieldElement to) {
      // The [from] can only be a parameter for function-scopes and not
      // loop scopes.
      if (from.isParameter && !element.isGenerativeConstructorBody) {
        // Now that the redirection is set up, the update to the local will
        // write the parameter value into the box.
        // Store the captured parameter in the box. Get the current value
        // before we put the redirection in place.
        // We don't need to update the local for a generative
        // constructor body, because it receives a box that already
        // contains the updates as the last parameter.
        HInstruction instruction = readLocal(from);
        redirectElement(from, to);
        updateLocal(from, instruction);
      } else {
        redirectElement(from, to);
      }
    });
  }

  /**
   * Replaces the current box with a new box and copies over the given list
   * of elements from the old box into the new box.
   */
  void updateCaptureBox(BoxLocal boxElement,
                        List<LocalVariableElement> toBeCopiedElements) {
    // Create a new box and copy over the values from the old box into the
    // new one.
    HInstruction oldBox = readLocal(boxElement);
    HInstruction newBox = createBox();
    for (LocalVariableElement boxedVariable in toBeCopiedElements) {
      // [readLocal] uses the [boxElement] to find its box. By replacing it
      // behind its back we can still get to the old values.
      updateLocal(boxElement, oldBox);
      HInstruction oldValue = readLocal(boxedVariable);
      updateLocal(boxElement, newBox);
      updateLocal(boxedVariable, oldValue);
    }
    updateLocal(boxElement, newBox);
  }

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [function] must be an implementation element.
   */
  void startFunction(Element element, ast.Node node) {
    assert(invariant(element, element.isImplementation));
    Compiler compiler = builder.compiler;
    closureData = compiler.closureToClassMapper.computeClosureToClassMapping(
            element, node, builder.elements);

    if (element is FunctionElement) {
      FunctionElement functionElement = element;
      FunctionSignature params = functionElement.functionSignature;
      ClosureScope scopeData = closureData.capturingScopes[node];
      params.orderedForEachParameter((ParameterElement parameterElement) {
        if (element.isGenerativeConstructorBody) {
          if (scopeData != null &&
              scopeData.isCapturedVariable(parameterElement)) {
            // The parameter will be a field in the box passed as the
            // last parameter. So no need to have it.
            return;
          }
        }
        HInstruction parameter = builder.addParameter(
            parameterElement,
            TypeMaskFactory.inferredTypeForElement(parameterElement, compiler));
        builder.parameters[parameterElement] = parameter;
        directLocals[parameterElement] = parameter;
      });
    }

    enterScope(node, element);

    // If the freeVariableMapping is not empty, then this function was a
    // nested closure that captures variables. Redirect the captured
    // variables to fields in the closure.
    closureData.forEachFreeVariable((Local from, CapturedVariable to) {
      redirectElement(from, to);
    });
    JavaScriptBackend backend = compiler.backend;
    if (closureData.isClosure) {
      // Inside closure redirect references to itself to [:this:].
      HThis thisInstruction = new HThis(closureData.thisLocal,
                                        backend.nonNullType);
      builder.graph.thisInstruction = thisInstruction;
      builder.graph.entry.addAtEntry(thisInstruction);
      updateLocal(closureData.closureElement, thisInstruction);
    } else if (element.isInstanceMember) {
      // Once closures have been mapped to classes their instance members might
      // not have any thisElement if the closure was created inside a static
      // context.
      HThis thisInstruction = new HThis(
          closureData.thisLocal, builder.getTypeOfThis());
      builder.graph.thisInstruction = thisInstruction;
      builder.graph.entry.addAtEntry(thisInstruction);
      directLocals[closureData.thisLocal] = thisInstruction;
    }

    // If this method is an intercepted method, add the extra
    // parameter to it, that is the actual receiver for intercepted
    // classes, or the same as [:this:] for non-intercepted classes.
    ClassElement cls = element.enclosingClass;

    // When the class extends a native class, the instance is pre-constructed
    // and passed to the generative constructor factory function as a parameter.
    // Instead of allocating and initializing the object, the constructor
    // 'upgrades' the native subclass object by initializing the Dart fields.
    bool isNativeUpgradeFactory = element.isGenerativeConstructor
        && backend.isNativeOrExtendsNative(cls);
    if (backend.isInterceptedMethod(element)) {
      bool isInterceptorClass = backend.isInterceptorClass(cls.declaration);
      String name = isInterceptorClass ? 'receiver' : '_';
      SyntheticLocal parameter = new SyntheticLocal(name, executableContext);
      HParameterValue value =
          new HParameterValue(parameter, builder.getTypeOfThis());
      builder.graph.explicitReceiverParameter = value;
      builder.graph.entry.addAfter(directLocals[closureData.thisLocal], value);
      if (builder.lastAddedParameter == null) {
        // If this is the first parameter inserted, make sure it stays first.
        builder.lastAddedParameter = value;
      }
      if (isInterceptorClass) {
        // Only use the extra parameter in intercepted classes.
        directLocals[closureData.thisLocal] = value;
      }
    } else if (isNativeUpgradeFactory) {
      SyntheticLocal parameter =
          new SyntheticLocal('receiver', executableContext);
      // Unlike `this`, receiver is nullable since direct calls to generative
      // constructor call the constructor with `null`.
      ClassWorld classWorld = compiler.world;
      HParameterValue value =
          new HParameterValue(parameter, new TypeMask.exact(cls, classWorld));
      builder.graph.explicitReceiverParameter = value;
      builder.graph.entry.addAtEntry(value);
    }
  }

  /**
   * Returns true if the local can be accessed directly. Boxed variables or
   * captured variables that are stored in the closure-field return [:false:].
   */
  bool isAccessedDirectly(Local local) {
    assert(local != null);
    return !redirectionMapping.containsKey(local)
        && !closureData.variablesUsedInTryOrGenerator.contains(local);
  }

  bool isStoredInClosureField(Local local) {
    assert(local != null);
    if (isAccessedDirectly(local)) return false;
    CapturedVariable redirectTarget = redirectionMapping[local];
    if (redirectTarget == null) return false;
    return redirectTarget is ClosureFieldElement;
  }

  bool isBoxed(Local local) {
    if (isAccessedDirectly(local)) return false;
    if (isStoredInClosureField(local)) return false;
    return redirectionMapping.containsKey(local);
  }

  bool isUsedInTryOrGenerator(Local local) {
    return closureData.variablesUsedInTryOrGenerator.contains(local);
  }

  /**
   * Returns an [HInstruction] for the given element. If the element is
   * boxed or stored in a closure then the method generates code to retrieve
   * the value.
   */
  HInstruction readLocal(Local local,
                         {SourceInformation sourceInformation}) {
    if (isAccessedDirectly(local)) {
      if (directLocals[local] == null) {
        if (local is TypeVariableElement) {
          builder.reporter.internalError(builder.compiler.currentElement,
              "Runtime type information not available for $local.");
        } else {
          builder.reporter.internalError(local,
              "Cannot find value $local.");
        }
      }
      HInstruction value = directLocals[local];
      if (sourceInformation != null) {
        value = new HRef(value, sourceInformation);
        builder.add(value);
      }
      return value;
    } else if (isStoredInClosureField(local)) {
      ClosureFieldElement redirect = redirectionMapping[local];
      HInstruction receiver = readLocal(closureData.closureElement);
      TypeMask type = local is BoxLocal
          ? builder.backend.nonNullType
          : builder.getTypeOfCapturedVariable(redirect);
      HInstruction fieldGet = new HFieldGet(redirect, receiver, type);
      builder.add(fieldGet);
      return fieldGet..sourceInformation = sourceInformation;
    } else if (isBoxed(local)) {
      BoxFieldElement redirect = redirectionMapping[local];
      // In the function that declares the captured variable the box is
      // accessed as direct local. Inside the nested closure the box is
      // accessed through a closure-field.
      // Calling [readLocal] makes sure we generate the correct code to get
      // the box.
      HInstruction box = readLocal(redirect.box);
      HInstruction lookup = new HFieldGet(
          redirect, box, builder.getTypeOfCapturedVariable(redirect));
      builder.add(lookup);
      return lookup..sourceInformation = sourceInformation;
    } else {
      assert(isUsedInTryOrGenerator(local));
      HLocalValue localValue = getLocal(local);
      HInstruction instruction = new HLocalGet(
          local, localValue, builder.backend.dynamicType, sourceInformation);
      builder.add(instruction);
      return instruction;
    }
  }

  HInstruction readThis() {
    HInstruction res = readLocal(closureData.thisLocal);
    if (res.instructionType == null) {
      res.instructionType = builder.getTypeOfThis();
    }
    return res;
  }

  HLocalValue getLocal(Local local,
                       {SourceInformation sourceInformation}) {
    // If the element is a parameter, we already have a
    // HParameterValue for it. We cannot create another one because
    // it could then have another name than the real parameter. And
    // the other one would not know it is just a copy of the real
    // parameter.
    if (local is ParameterElement) return builder.parameters[local];

    return builder.activationVariables.putIfAbsent(local, () {
      JavaScriptBackend backend = builder.backend;
      HLocalValue localValue = new HLocalValue(local, backend.nonNullType)
          ..sourceInformation = sourceInformation;
      builder.graph.entry.addAtExit(localValue);
      return localValue;
    });
  }

  Local getTypeVariableAsLocal(TypeVariableType type) {
    return typeVariableLocals.putIfAbsent(type, () {
      return new TypeVariableLocal(type, executableContext);
    });
  }

  /**
   * Sets the [element] to [value]. If the element is boxed or stored in a
   * closure then the method generates code to set the value.
   */
  void updateLocal(Local local, HInstruction value,
                   {SourceInformation sourceInformation}) {
    if (value is HRef) {
      HRef ref = value;
      value = ref.value;
    }
    assert(!isStoredInClosureField(local));
    if (isAccessedDirectly(local)) {
      directLocals[local] = value;
    } else if (isBoxed(local)) {
      BoxFieldElement redirect = redirectionMapping[local];
      // The box itself could be captured, or be local. A local variable that
      // is captured will be boxed, but the box itself will be a local.
      // Inside the closure the box is stored in a closure-field and cannot
      // be accessed directly.
      HInstruction box = readLocal(redirect.box);
      builder.add(new HFieldSet(redirect, box, value)
          ..sourceInformation = sourceInformation);
    } else {
      assert(isUsedInTryOrGenerator(local));
      HLocalValue localValue = getLocal(local);
      builder.add(new HLocalSet(local, localValue, value)
          ..sourceInformation = sourceInformation);
    }
  }

  /**
   * This function, startLoop, must be called before visiting any children of
   * the loop. In particular it needs to be called before executing the
   * initializers.
   *
   * The [LocalsHandler] will make the boxes and updates at the right moment.
   * The builder just needs to call [enterLoopBody] and [enterLoopUpdates]
   * (for [ast.For] loops) at the correct places. For phi-handling
   * [beginLoopHeader] and [endLoop] must also be called.
   *
   * The correct place for the box depends on the given loop. In most cases
   * the box will be created when entering the loop-body: while, do-while, and
   * for-in (assuming the call to [:next:] is inside the body) can always be
   * constructed this way.
   *
   * Things are slightly more complicated for [ast.For] loops. If no declared
   * loop variable is boxed then the loop-body approach works here too. If a
   * loop-variable is boxed we need to introduce a new box for the
   * loop-variable before we enter the initializer so that the initializer
   * writes the values into the box. In any case we need to create the box
   * before the condition since the condition could box the variable.
   * Since the first box is created outside the actual loop we have a second
   * location where a box is created: just before the updates. This is
   * necessary since updates are considered to be part of the next iteration
   * (and can again capture variables).
   *
   * For example the following Dart code prints 1 3 -- 3 4.
   *
   *     var fs = [];
   *     for (var i = 0; i < 3; (f() { fs.add(f); print(i); i++; })()) {
   *       i++;
   *     }
   *     print("--");
   *     for (var i = 0; i < 2; i++) fs[i]();
   *
   * We solve this by emitting the following code (only for [ast.For] loops):
   *  <Create box>    <== move the first box creation outside the loop.
   *  <initializer>;
   *  loop-entry:
   *    if (!<condition>) goto loop-exit;
   *    <body>
   *    <update box>  // create a new box and copy the captured loop-variables.
   *    <updates>
   *    goto loop-entry;
   *  loop-exit:
   */
  void startLoop(ast.Node node) {
    ClosureScope scopeData = closureData.capturingScopes[node];
    if (scopeData == null) return;
    if (scopeData.hasBoxedLoopVariables()) {
      // If there are boxed loop variables then we set up the box and
      // redirections already now. This way the initializer can write its
      // values into the box.
      // For other loops the box will be created when entering the body.
      enterScope(node, null);
    }
  }

  /**
   * Create phis at the loop entry for local variables (ready for the values
   * from the back edge).  Populate the phis with the current values.
   */
  void beginLoopHeader(HBasicBlock loopEntry) {
    // Create a copy because we modify the map while iterating over it.
    Map<Local, HInstruction> savedDirectLocals =
        new Map<Local, HInstruction>.from(directLocals);

    JavaScriptBackend backend = builder.backend;
    // Create phis for all elements in the definitions environment.
    savedDirectLocals.forEach((Local local,
                               HInstruction instruction) {
      if (isAccessedDirectly(local)) {
        // We know 'this' cannot be modified.
        if (local != closureData.thisLocal) {
          HPhi phi = new HPhi.singleInput(
              local, instruction, backend.dynamicType);
          loopEntry.addPhi(phi);
          directLocals[local] = phi;
        } else {
          directLocals[local] = instruction;
        }
      }
    });
  }

  void enterLoopBody(ast.Node node) {
    ClosureScope scopeData = closureData.capturingScopes[node];
    if (scopeData == null) return;
    // If there are no declared boxed loop variables then we did not create the
    // box before the initializer and we have to create the box now.
    if (!scopeData.hasBoxedLoopVariables()) {
      enterScope(node, null);
    }
  }

  void enterLoopUpdates(ast.Node node) {
    // If there are declared boxed loop variables then the updates might have
    // access to the box and we must switch to a new box before executing the
    // updates.
    // In all other cases a new box will be created when entering the body of
    // the next iteration.
    ClosureScope scopeData = closureData.capturingScopes[node];
    if (scopeData == null) return;
    if (scopeData.hasBoxedLoopVariables()) {
      updateCaptureBox(scopeData.boxElement, scopeData.boxedLoopVariables);
    }
  }

  /**
   * Goes through the phis created in beginLoopHeader entry and adds the
   * input from the back edge (from the current value of directLocals) to them.
   */
  void endLoop(HBasicBlock loopEntry) {
    // If the loop has an aborting body, we don't update the loop
    // phis.
    if (loopEntry.predecessors.length == 1) return;
    loopEntry.forEachPhi((HPhi phi) {
      Local element = phi.sourceElement;
      HInstruction postLoopDefinition = directLocals[element];
      phi.addInput(postLoopDefinition);
    });
  }

  /**
   * Merge [otherLocals] into this locals handler, creating phi-nodes when
   * there is a conflict.
   * If a phi node is necessary, it will use this handler's instruction as the
   * first input, and the otherLocals instruction as the second.
   */
  void mergeWith(LocalsHandler otherLocals, HBasicBlock joinBlock) {
    // If an element is in one map but not the other we can safely
    // ignore it. It means that a variable was declared in the
    // block. Since variable declarations are scoped the declared
    // variable cannot be alive outside the block. Note: this is only
    // true for nodes where we do joins.
    Map<Local, HInstruction> joinedLocals =
        new Map<Local, HInstruction>();
    JavaScriptBackend backend = builder.backend;
    otherLocals.directLocals.forEach((Local local,
                                      HInstruction instruction) {
      // We know 'this' cannot be modified.
      if (local == closureData.thisLocal) {
        assert(directLocals[local] == instruction);
        joinedLocals[local] = instruction;
      } else {
        HInstruction mine = directLocals[local];
        if (mine == null) return;
        if (identical(instruction, mine)) {
          joinedLocals[local] = instruction;
        } else {
          HInstruction phi = new HPhi.manyInputs(
              local, <HInstruction>[mine, instruction], backend.dynamicType);
          joinBlock.addPhi(phi);
          joinedLocals[local] = phi;
        }
      }
    });
    directLocals = joinedLocals;
  }

  /**
   * When control flow merges, this method can be used to merge several
   * localsHandlers into a new one using phis.  The new localsHandler is
   * returned.  Unless it is also in the list, the current localsHandler is not
   * used for its values, only for its declared variables. This is a way to
   * exclude local values from the result when they are no longer in scope.
   */
  LocalsHandler mergeMultiple(List<LocalsHandler> localsHandlers,
                              HBasicBlock joinBlock) {
    assert(localsHandlers.length > 0);
    if (localsHandlers.length == 1) return localsHandlers[0];
    Map<Local, HInstruction> joinedLocals =
        new Map<Local, HInstruction>();
    HInstruction thisValue = null;
    JavaScriptBackend backend = builder.backend;
    directLocals.forEach((Local local, HInstruction instruction) {
      if (local != closureData.thisLocal) {
        HPhi phi = new HPhi.noInputs(local, backend.dynamicType);
        joinedLocals[local] = phi;
        joinBlock.addPhi(phi);
      } else {
        // We know that "this" never changes, if it's there.
        // Save it for later. While merging, there is no phi for "this",
        // so we don't have to special case it in the merge loop.
        thisValue = instruction;
      }
    });
    for (LocalsHandler handler in localsHandlers) {
      handler.directLocals.forEach((Local local,
                                    HInstruction instruction) {
        HPhi phi = joinedLocals[local];
        if (phi != null) {
          phi.addInput(instruction);
        }
      });
    }
    if (thisValue != null) {
      // If there was a "this" for the scope, add it to the new locals.
      joinedLocals[closureData.thisLocal] = thisValue;
    }

    // Remove locals that are not in all handlers.
    directLocals = new Map<Local, HInstruction>();
    joinedLocals.forEach((Local local,
                          HInstruction instruction) {
      if (local != closureData.thisLocal
          && instruction.inputs.length != localsHandlers.length) {
        joinBlock.removePhi(instruction);
      } else {
        directLocals[local] = instruction;
      }
    });
    return this;
  }
}


// Represents a single break/continue instruction.
class JumpHandlerEntry {
  final HJump jumpInstruction;
  final LocalsHandler locals;
  bool isBreak() => jumpInstruction is HBreak;
  bool isContinue() => jumpInstruction is HContinue;
  JumpHandlerEntry(this.jumpInstruction, this.locals);
}


abstract class JumpHandler {
  factory JumpHandler(SsaBuilder builder, JumpTarget target) {
    return new TargetJumpHandler(builder, target);
  }
  void generateBreak([LabelDefinition label]);
  void generateContinue([LabelDefinition label]);
  void forEachBreak(void action(HBreak instruction, LocalsHandler locals));
  void forEachContinue(void action(HContinue instruction,
                                   LocalsHandler locals));
  bool hasAnyContinue();
  bool hasAnyBreak();
  void close();
  final JumpTarget target;
  List<LabelDefinition> labels();
}

// Insert break handler used to avoid null checks when a target isn't
// used as the target of a break, and therefore doesn't need a break
// handler associated with it.
class NullJumpHandler implements JumpHandler {
  final DiagnosticReporter reporter;

  NullJumpHandler(this.reporter);

  void generateBreak([LabelDefinition label]) {
    reporter.internalError(CURRENT_ELEMENT_SPANNABLE,
        'NullJumpHandler.generateBreak should not be called.');
  }

  void generateContinue([LabelDefinition label]) {
    reporter.internalError(CURRENT_ELEMENT_SPANNABLE,
        'NullJumpHandler.generateContinue should not be called.');
  }

  void forEachBreak(Function ignored) { }
  void forEachContinue(Function ignored) { }
  void close() { }
  bool hasAnyContinue() => false;
  bool hasAnyBreak() => false;

  List<LabelDefinition> labels() => const <LabelDefinition>[];
  JumpTarget get target => null;
}

// Records breaks until a target block is available.
// Breaks are always forward jumps.
// Continues in loops are implemented as breaks of the body.
// Continues in switches is currently not handled.
class TargetJumpHandler implements JumpHandler {
  final SsaBuilder builder;
  final JumpTarget target;
  final List<JumpHandlerEntry> jumps;

  TargetJumpHandler(SsaBuilder builder, this.target)
      : this.builder = builder,
        jumps = <JumpHandlerEntry>[] {
    assert(builder.jumpTargets[target] == null);
    builder.jumpTargets[target] = this;
  }

  void generateBreak([LabelDefinition label]) {
    HInstruction breakInstruction;
    if (label == null) {
      breakInstruction = new HBreak(target);
    } else {
      breakInstruction = new HBreak.toLabel(label);
    }
    LocalsHandler locals = new LocalsHandler.from(builder.localsHandler);
    builder.close(breakInstruction);
    jumps.add(new JumpHandlerEntry(breakInstruction, locals));
  }

  void generateContinue([LabelDefinition label]) {
    HInstruction continueInstruction;
    if (label == null) {
      continueInstruction = new HContinue(target);
    } else {
      continueInstruction = new HContinue.toLabel(label);
      // Switch case continue statements must be handled by the
      // [SwitchCaseJumpHandler].
      assert(label.target.statement is! ast.SwitchCase);
    }
    LocalsHandler locals = new LocalsHandler.from(builder.localsHandler);
    builder.close(continueInstruction);
    jumps.add(new JumpHandlerEntry(continueInstruction, locals));
  }

  void forEachBreak(Function action) {
    for (JumpHandlerEntry entry in jumps) {
      if (entry.isBreak()) action(entry.jumpInstruction, entry.locals);
    }
  }

  void forEachContinue(Function action) {
    for (JumpHandlerEntry entry in jumps) {
      if (entry.isContinue()) action(entry.jumpInstruction, entry.locals);
    }
  }

  bool hasAnyContinue() {
    for (JumpHandlerEntry entry in jumps) {
      if (entry.isContinue()) return true;
    }
    return false;
  }

  bool hasAnyBreak() {
    for (JumpHandlerEntry entry in jumps) {
      if (entry.isBreak()) return true;
    }
    return false;
  }

  void close() {
    // The mapping from TargetElement to JumpHandler is no longer needed.
    builder.jumpTargets.remove(target);
  }

  List<LabelDefinition> labels() {
    List<LabelDefinition> result = null;
    for (LabelDefinition element in target.labels) {
      if (result == null) result = <LabelDefinition>[];
      result.add(element);
    }
    return (result == null) ? const <LabelDefinition>[] : result;
  }
}

/// Special [JumpHandler] implementation used to handle continue statements
/// targeting switch cases.
class SwitchCaseJumpHandler extends TargetJumpHandler {
  /// Map from switch case targets to indices used to encode the flow of the
  /// switch case loop.
  final Map<JumpTarget, int> targetIndexMap = new Map<JumpTarget, int>();

  SwitchCaseJumpHandler(SsaBuilder builder,
                        JumpTarget target,
                        ast.SwitchStatement node)
      : super(builder, target) {
    // The switch case indices must match those computed in
    // [SsaFromAstMixin.buildSwitchCaseConstants].
    // Switch indices are 1-based so we can bypass the synthetic loop when no
    // cases match simply by branching on the index (which defaults to null).
    int switchIndex = 1;
    for (ast.SwitchCase switchCase in node.cases) {
      for (ast.Node labelOrCase in switchCase.labelsAndCases) {
        ast.Node label = labelOrCase.asLabel();
        if (label != null) {
          LabelDefinition labelElement =
              builder.elements.getLabelDefinition(label);
          if (labelElement != null && labelElement.isContinueTarget) {
            JumpTarget continueTarget = labelElement.target;
            targetIndexMap[continueTarget] = switchIndex;
            assert(builder.jumpTargets[continueTarget] == null);
            builder.jumpTargets[continueTarget] = this;
          }
        }
      }
      switchIndex++;
    }
  }

  void generateBreak([LabelDefinition label]) {
    if (label == null) {
      // Creates a special break instruction for the synthetic loop generated
      // for a switch statement with continue statements. See
      // [SsaFromAstMixin.buildComplexSwitchStatement] for detail.

      HInstruction breakInstruction =
          new HBreak(target, breakSwitchContinueLoop: true);
      LocalsHandler locals = new LocalsHandler.from(builder.localsHandler);
      builder.close(breakInstruction);
      jumps.add(new JumpHandlerEntry(breakInstruction, locals));
    } else {
      super.generateBreak(label);
    }
  }

  bool isContinueToSwitchCase(LabelDefinition label) {
    return label != null && targetIndexMap.containsKey(label.target);
  }

  void generateContinue([LabelDefinition label]) {
    if (isContinueToSwitchCase(label)) {
      // Creates the special instructions 'label = i; continue l;' used in
      // switch statements with continue statements. See
      // [SsaFromAstMixin.buildComplexSwitchStatement] for detail.

      assert(label != null);
      HInstruction value = builder.graph.addConstantInt(
          targetIndexMap[label.target],
          builder.compiler);
      builder.localsHandler.updateLocal(target, value);

      assert(label.target.labels.contains(label));
      HInstruction continueInstruction = new HContinue(target);
      LocalsHandler locals = new LocalsHandler.from(builder.localsHandler);
      builder.close(continueInstruction);
      jumps.add(new JumpHandlerEntry(continueInstruction, locals));
    } else {
      super.generateContinue(label);
    }
  }

  void close() {
    // The mapping from TargetElement to JumpHandler is no longer needed.
    for (JumpTarget target in targetIndexMap.keys) {
      builder.jumpTargets.remove(target);
    }
    super.close();
  }
}

/**
 * This class builds SSA nodes for functions represented in AST.
 */
class SsaBuilder extends ast.Visitor
    with BaseImplementationOfCompoundsMixin,
         BaseImplementationOfSetIfNullsMixin,
         SemanticSendResolvedMixin,
         NewBulkMixin,
         ErrorBulkMixin
    implements SemanticSendVisitor {

  /// The element for which this SSA builder is being used.
  final Element target;

  /// Reference to resolved elements in [target]'s AST.
  TreeElements elements;

  /// Used to report information about inlining (which occurs while building the
  /// SSA graph), when dump-info is enabled.
  final InfoReporter infoReporter;

  /// If not null, the builder will store in [context] data that is used later
  /// during the optimization phases.
  final JavaScriptItemCompilationContext context;

  /// Registry used to enqueue work during codegen, may be null to avoid
  /// enqueing any work.
  // TODO(sigmund,johnniwinther): get rid of registry entirely. We should be
  // able to return the impact as a result after building and avoid enqueing
  // things here. Later the codegen task can decide whether to enqueue
  // something. In the past this didn't matter as much because the SSA graph was
  // used only for codegen, but currently we want to experiment using it for
  // code-analysis too.
  final CodegenRegistry registry;
  final Compiler compiler;
  final JavaScriptBackend backend;
  final ConstantSystem constantSystem;
  final RuntimeTypes rti;

  SourceInformationBuilder sourceInformationBuilder;

  bool inLazyInitializerExpression = false;

  // TODO(sigmund): make all comments /// instead of /* */
  /* This field is used by the native handler. */
  final NativeEmitter nativeEmitter;

  /// Holds the resulting SSA graph.
  final HGraph graph = new HGraph();

  /**
   * The current block to add instructions to. Might be null, if we are
   * visiting dead code, but see [isReachable].
   */
  HBasicBlock _current;

  HBasicBlock get current => _current;

  void set current(c) {
    isReachable = c != null;
    _current = c;
  }

  /**
   * The most recently opened block. Has the same value as [current] while
   * the block is open, but unlike [current], it isn't cleared when the
   * current block is closed.
   */
  HBasicBlock lastOpenedBlock;

  /**
   * Indicates whether the current block is dead (because it has a throw or a
   * return further up). If this is false, then [current] may be null. If the
   * block is dead then it may also be aborted, but for simplicity we only
   * abort on statement boundaries, not in the middle of expressions. See
   * isAborted.
   */
  bool isReachable = true;

  /**
   * True if we are visiting the expression of a throw statement; we assume this
   * is a slow path.
   */
  bool inExpressionOfThrow = false;

  /**
   * The loop nesting is consulted when inlining a function invocation in
   * [tryInlineMethod]. The inlining heuristics take this information into
   * account.
   */
  int loopNesting = 0;

  /**
   * This stack contains declaration elements of the functions being built
   * or inlined by this builder.
   */
  final List<Element> sourceElementStack = <Element>[];

  LocalsHandler localsHandler;

  HInstruction rethrowableException;

  HParameterValue lastAddedParameter;

  Map<ParameterElement, HInstruction> parameters =
      <ParameterElement, HInstruction>{};

  Map<JumpTarget, JumpHandler> jumpTargets = <JumpTarget, JumpHandler>{};

  /**
   * Variables stored in the current activation. These variables are
   * being updated in try/catch blocks, and should be
   * accessed indirectly through [HLocalGet] and [HLocalSet].
   */
  Map<Local, HLocalValue> activationVariables =
      <Local, HLocalValue>{};

  // We build the Ssa graph by simulating a stack machine.
  List<HInstruction> stack = <HInstruction>[];

  /// Returns `true` if the current element is an `async` function.
  bool get isBuildingAsyncFunction {
    Element element = sourceElement;
    return (element is FunctionElement &&
            element.asyncMarker == AsyncMarker.ASYNC);
  }

  // TODO(sigmund): make most args optional
  SsaBuilder(this.target, this.elements, this.context, this.registry,
      JavaScriptBackend backend, this.nativeEmitter,
      SourceInformationStrategy sourceInformationFactory)
    : this.compiler = backend.compiler,
      this.infoReporter = backend.compiler.dumpInfoTask,
      this.backend = backend,
      this.constantSystem = backend.constantSystem,
      this.rti = backend.rti {
    assert(target.isImplementation);
    graph.element = target;
    localsHandler = new LocalsHandler(this, target, null);
    sourceElementStack.add(target);
    sourceInformationBuilder = sourceInformationFactory.createBuilderForContext(
            target);
    graph.sourceInformation =
        sourceInformationBuilder.buildVariableDeclaration();
  }

  BackendHelpers get helpers => backend.helpers;

  RuntimeTypesEncoder get rtiEncoder => backend.rtiEncoder;

  DiagnosticReporter get reporter => compiler.reporter;

  CoreClasses get coreClasses => compiler.coreClasses;

  @override
  SemanticSendVisitor get sendVisitor => this;

  @override
  void visitNode(ast.Node node) {
    internalError(node, "Unhandled node: $node");
  }

  @override
  void apply(ast.Node node, [_]) {
    node.accept(this);
  }

  /// Returns the current source element.
  ///
  /// The returned element is a declaration element.
  // TODO(johnniwinther): Check that all usages of sourceElement agree on
  // implementation/declaration distinction.
  Element get sourceElement => sourceElementStack.last;

  bool get _checkOrTrustTypes =>
      compiler.enableTypeAssertions || compiler.trustTypeAnnotations;

  /// Build the graph for [target].
  HGraph build() {
    assert(invariant(target, target.isImplementation));
    HInstruction.idCounter = 0;
    // TODO(sigmund): remove `result` and return graph directly, need to ensure
    // that it can never be null (see result in buildFactory for instance).
    var result;
    if (target.isGenerativeConstructor) {
      result = buildFactory(target);
    } else if (target.isGenerativeConstructorBody ||
               target.isFactoryConstructor ||
               target.isFunction ||
               target.isGetter ||
               target.isSetter) {
      result = buildMethod(target);
    } else if (target.isField) {
      if (target.isInstanceMember) {
        assert(compiler.enableTypeAssertions);
        result = buildCheckedSetter(target);
      } else {
        result = buildLazyInitializer(target);
      }
    } else {
      reporter.internalError(target, 'Unexpected element kind $target.');
    }
    assert(result.isValid());
    return result;
  }


  HBasicBlock addNewBlock() {
    HBasicBlock block = graph.addNewBlock();
    // If adding a new block during building of an expression, it is due to
    // conditional expressions or short-circuit logical operators.
    return block;
  }

  void open(HBasicBlock block) {
    block.open();
    current = block;
    lastOpenedBlock = block;
  }

  HBasicBlock close(HControlFlow end) {
    HBasicBlock result = current;
    current.close(end);
    current = null;
    return result;
  }

  HBasicBlock closeAndGotoExit(HControlFlow end) {
    HBasicBlock result = current;
    current.close(end);
    current = null;
    result.addSuccessor(graph.exit);
    return result;
  }

  void goto(HBasicBlock from, HBasicBlock to) {
    from.close(new HGoto());
    from.addSuccessor(to);
  }

  bool isAborted() {
    return current == null;
  }

  /**
   * Creates a new block, transitions to it from any current block, and
   * opens the new block.
   */
  HBasicBlock openNewBlock() {
    HBasicBlock newBlock = addNewBlock();
    if (!isAborted()) goto(current, newBlock);
    open(newBlock);
    return newBlock;
  }

  void add(HInstruction instruction) {
    current.add(instruction);
  }

  void addWithPosition(HInstruction instruction, ast.Node node) {
    add(attachPosition(instruction, node));
  }

  /**
   * Returns a complete argument list for a call of [function].
   */
  List<HInstruction> completeSendArgumentsList(
      FunctionElement function,
      Selector selector,
      List<HInstruction> providedArguments,
      ast.Node currentNode) {
    assert(invariant(function, function.isImplementation));
    assert(providedArguments != null);

    bool isInstanceMember = function.isInstanceMember;
    // For static calls, [providedArguments] is complete, default arguments
    // have been included if necessary, see [makeStaticArgumentList].
    if (!isInstanceMember
        || currentNode == null // In erroneous code, currentNode can be null.
        || providedArgumentsKnownToBeComplete(currentNode)
        || function.isGenerativeConstructorBody
        || selector.isGetter) {
      // For these cases, the provided argument list is known to be complete.
      return providedArguments;
    } else {
      return completeDynamicSendArgumentsList(
          selector, function, providedArguments);
    }
  }

  /**
   * Returns a complete argument list for a dynamic call of [function]. The
   * initial argument list [providedArguments], created by
   * [addDynamicSendArgumentsToList], does not include values for default
   * arguments used in the call. The reason is that the target function (which
   * defines the defaults) is not known.
   *
   * However, inlining can only be performed when the target function can be
   * resolved statically. The defaults can therefore be included at this point.
   *
   * The [providedArguments] list contains first all positional arguments, then
   * the provided named arguments (the named arguments that are defined in the
   * [selector]) in a specific order (see [addDynamicSendArgumentsToList]).
   */
  List<HInstruction> completeDynamicSendArgumentsList(
      Selector selector,
      FunctionElement function,
      List<HInstruction> providedArguments) {
    assert(selector.applies(function, compiler.world));
    FunctionSignature signature = function.functionSignature;
    List<HInstruction> compiledArguments = new List<HInstruction>(
        signature.parameterCount + 1); // Plus one for receiver.

    compiledArguments[0] = providedArguments[0]; // Receiver.
    int index = 1;
    for (; index <= signature.requiredParameterCount; index++) {
      compiledArguments[index] = providedArguments[index];
    }
    if (!signature.optionalParametersAreNamed) {
      signature.forEachOptionalParameter((element) {
        if (index < providedArguments.length) {
          compiledArguments[index] = providedArguments[index];
        } else {
          compiledArguments[index] =
              handleConstantForOptionalParameter(element);
        }
        index++;
      });
    } else {
      /* Example:
       *   void foo(a, {b, d, c})
       *   foo(0, d = 1, b = 2)
       *
       * providedArguments = [0, 2, 1]
       * selectorArgumentNames = [b, d]
       * signature.orderedOptionalParameters = [b, c, d]
       *
       * For each parameter name in the signature, if the argument name matches
       * we use the next provided argument, otherwise we get the default.
       */
      List<String> selectorArgumentNames =
          selector.callStructure.getOrderedNamedArguments();
      int namedArgumentIndex = 0;
      int firstProvidedNamedArgument = index;
      signature.orderedOptionalParameters.forEach((element) {
        if (namedArgumentIndex < selectorArgumentNames.length &&
            element.name == selectorArgumentNames[namedArgumentIndex]) {
          // The named argument was provided in the function invocation.
          compiledArguments[index] = providedArguments[
              firstProvidedNamedArgument + namedArgumentIndex++];
        } else {
          compiledArguments[index] =
              handleConstantForOptionalParameter(element);
        }
        index++;
      });
    }
    return compiledArguments;
  }

  /**
   * Try to inline [element] within the currect context of the builder. The
   * insertion point is the state of the builder.
   */
  bool tryInlineMethod(Element element,
                       Selector selector,
                       TypeMask mask,
                       List<HInstruction> providedArguments,
                       ast.Node currentNode,
                       {InterfaceType instanceType}) {
    // TODO(johnniwinther): Register this on the [registry]. Currently the
    // [CodegenRegistry] calls the enqueuer, but [element] should _not_ be
    // enqueued.
    backend.registerStaticUse(element, compiler.enqueuer.codegen);

    if (backend.isJsInterop(element) && !element.isFactoryConstructor) {
      // We only inline factory JavaScript interop constructors.
      return false;
    }

    // Ensure that [element] is an implementation element.
    element = element.implementation;

    if (compiler.elementHasCompileTimeError(element)) return false;

    FunctionElement function = element;
    bool insideLoop = loopNesting > 0 || graph.calledInLoop;

    // Bail out early if the inlining decision is in the cache and we can't
    // inline (no need to check the hard constraints).
    bool cachedCanBeInlined =
        backend.inlineCache.canInline(function, insideLoop: insideLoop);
    if (cachedCanBeInlined == false) return false;

    bool meetsHardConstraints() {
      if (compiler.disableInlining) return false;

      assert(invariant(
          currentNode != null ? currentNode : element,
          selector != null ||
          Elements.isStaticOrTopLevel(element) ||
          element.isGenerativeConstructorBody,
          message: "Missing selector for inlining of $element."));
      if (selector != null) {
        if (!selector.applies(function, compiler.world)) return false;
        if (mask != null && !mask.canHit(function, selector, compiler.world)) {
          return false;
        }
      }

      if (backend.isJsInterop(element)) return false;

      // Don't inline operator== methods if the parameter can be null.
      if (element.name == '==') {
        if (element.enclosingClass != coreClasses.objectClass
            && providedArguments[1].canBeNull()) {
          return false;
        }
      }

      // Generative constructors of native classes should not be called directly
      // and have an extra argument that causes problems with inlining.
      if (element.isGenerativeConstructor
          && backend.isNativeOrExtendsNative(element.enclosingClass)) {
        return false;
      }

      // A generative constructor body is not seen by global analysis,
      // so we should not query for its type.
      if (!element.isGenerativeConstructorBody) {
        // Don't inline if the return type was inferred to be non-null empty.
        // This means that the function always throws an exception.
        TypeMask returnType =
            compiler.typesTask.getGuaranteedReturnTypeOfElement(element);
        if (returnType != null && returnType.isEmpty) {
          isReachable = false;
          return false;
        }
      }

      return true;
    }

    bool doesNotContainCode() {
      // A function with size 1 does not contain any code.
      return InlineWeeder.canBeInlined(function, 1, true,
          enableUserAssertions: compiler.enableUserAssertions);
    }

    bool reductiveHeuristic() {
      // The call is on a path which is executed rarely, so inline only if it
      // does not make the program larger.
      if (isCalledOnce(element)) {
        return InlineWeeder.canBeInlined(function, -1, false,
            enableUserAssertions: compiler.enableUserAssertions);
      }
      // TODO(sra): Measure if inlining would 'reduce' the size.  One desirable
      // case we miss by doing nothing is inlining very simple constructors
      // where all fields are initialized with values from the arguments at this
      // call site.  The code is slightly larger (`new Foo(1)` vs `Foo$(1)`) but
      // that usually means the factory constructor is left unused and not
      // emitted.
      // We at least inline bodies that are empty (and thus have a size of 1).
      return doesNotContainCode();
    }

    bool heuristicSayGoodToGo() {
      // Don't inline recursively
      if (inliningStack.any((entry) => entry.function == function)) {
        return false;
      }

      if (element.isSynthesized) return true;

      // Don't inline across deferred import to prevent leaking code. The only
      // exception is an empty function (which does not contain code).
      bool hasOnlyNonDeferredImportPaths = compiler.deferredLoadTask
          .hasOnlyNonDeferredImportPaths(compiler.currentElement, element);

      if (!hasOnlyNonDeferredImportPaths) {
        return doesNotContainCode();
      }

      // Do not inline code that is rarely executed unless it reduces size.
      if (inExpressionOfThrow || inLazyInitializerExpression) {
        return reductiveHeuristic();
      }

      if (cachedCanBeInlined == true) {
        // We may have forced the inlining of some methods. Therefore check
        // if we can inline this method regardless of size.
        assert(InlineWeeder.canBeInlined(function, -1, false,
                allowLoops: true,
                enableUserAssertions: compiler.enableUserAssertions));
        return true;
      }

      int numParameters = function.functionSignature.parameterCount;
      int maxInliningNodes;
      bool useMaxInliningNodes = true;
      if (insideLoop) {
        maxInliningNodes = InlineWeeder.INLINING_NODES_INSIDE_LOOP +
            InlineWeeder.INLINING_NODES_INSIDE_LOOP_ARG_FACTOR * numParameters;
      } else {
        maxInliningNodes = InlineWeeder.INLINING_NODES_OUTSIDE_LOOP +
            InlineWeeder.INLINING_NODES_OUTSIDE_LOOP_ARG_FACTOR * numParameters;
      }

      // If a method is called only once, and all the methods in the
      // inlining stack are called only once as well, we know we will
      // save on output size by inlining this method.
      if (isCalledOnce(element)) {
        useMaxInliningNodes = false;
      }
      bool canInline;
      canInline = InlineWeeder.canBeInlined(
          function, maxInliningNodes, useMaxInliningNodes,
          enableUserAssertions: compiler.enableUserAssertions);
      if (canInline) {
        backend.inlineCache.markAsInlinable(element, insideLoop: insideLoop);
      } else {
        backend.inlineCache.markAsNonInlinable(element, insideLoop: insideLoop);
      }
      return canInline;
    }

    void doInlining() {
      // Add an explicit null check on the receiver before doing the
      // inlining. We use [element] to get the same name in the
      // NoSuchMethodError message as if we had called it.
      if (element.isInstanceMember &&
          !element.isGenerativeConstructorBody &&
          (mask == null || mask.isNullable)) {
        addWithPosition(
            new HFieldGet(null, providedArguments[0], backend.dynamicType,
                          isAssignable: false),
            currentNode);
      }
      List<HInstruction> compiledArguments = completeSendArgumentsList(
          function, selector, providedArguments, currentNode);
      enterInlinedMethod(
          function, currentNode, compiledArguments, instanceType: instanceType);
      inlinedFrom(function, () {
        if (!isReachable) {
          emitReturn(graph.addConstantNull(compiler), null);
        } else {
          doInline(function);
        }
      });
      leaveInlinedMethod();
    }

    if (meetsHardConstraints() && heuristicSayGoodToGo()) {
      doInlining();
      infoReporter?.reportInlined(element,
          inliningStack.isEmpty ? target : inliningStack.last.function);
      return true;
    }

    return false;
  }

  bool get allInlinedFunctionsCalledOnce {
    return inliningStack.isEmpty || inliningStack.last.allFunctionsCalledOnce;
  }

  bool isCalledOnce(Element element) {
    if (!allInlinedFunctionsCalledOnce) return false;
    TypesInferrer inferrer = compiler.typesTask.typesInferrer;
    return inferrer.isCalledOnce(element);
  }

  inlinedFrom(Element element, f()) {
    assert(element is FunctionElement || element is VariableElement);
    return reporter.withCurrentElement(element, () {
      // The [sourceElementStack] contains declaration elements.
      SourceInformationBuilder oldSourceInformationBuilder =
          sourceInformationBuilder;
      sourceInformationBuilder =
          sourceInformationBuilder.forContext(element.implementation);
      sourceElementStack.add(element.declaration);
      var result = f();
      sourceInformationBuilder = oldSourceInformationBuilder;
      sourceElementStack.removeLast();
      return result;
    });
  }

  /**
   * Return null so it is simple to remove the optional parameters completely
   * from interop methods to match JavaScript semantics for ommitted arguments.
   */
  HInstruction handleConstantForOptionalParameterJsInterop(Element parameter) =>
      null;

  HInstruction handleConstantForOptionalParameter(Element parameter) {
    ConstantValue constantValue =
        backend.constants.getConstantValueForVariable(parameter);
    assert(invariant(parameter, constantValue != null,
        message: 'No constant computed for $parameter'));
    return graph.addConstant(constantValue, compiler);
  }

  Element get currentNonClosureClass {
    ClassElement cls = sourceElement.enclosingClass;
    if (cls != null && cls.isClosure) {
      var closureClass = cls;
      return closureClass.methodElement.enclosingClass;
    } else {
      return cls;
    }
  }

  /// A stack of [DartType]s the have been seen during inlining of factory
  /// constructors.  These types are preserved in [HInvokeStatic]s and
  /// [HForeignNew]s inside the inline code and registered during code
  /// generation for these nodes.
  // TODO(karlklose): consider removing this and keeping the (substituted)
  // types of the type variables in an environment (like the [LocalsHandler]).
  final List<DartType> currentInlinedInstantiations = <DartType>[];

  final List<AstInliningState> inliningStack = <AstInliningState>[];

  Local returnLocal;
  DartType returnType;

  bool inTryStatement = false;

  ConstantValue getConstantForNode(ast.Node node) {
    ConstantValue constantValue =
        backend.constants.getConstantValueForNode(node, elements);
    assert(invariant(node, constantValue != null,
        message: 'No constant computed for $node'));
    return constantValue;
  }

  HInstruction addConstant(ast.Node node) {
    return graph.addConstant(getConstantForNode(node), compiler);
  }

  TypeMask cachedTypeOfThis;

  TypeMask getTypeOfThis() {
    TypeMask result = cachedTypeOfThis;
    if (result == null) {
      ThisLocal local = localsHandler.closureData.thisLocal;
      ClassElement cls = local.enclosingClass;
      ClassWorld classWorld = compiler.world;
      if (classWorld.isUsedAsMixin(cls)) {
        // If the enclosing class is used as a mixin, [:this:] can be
        // of the class that mixins the enclosing class. These two
        // classes do not have a subclass relationship, so, for
        // simplicity, we mark the type as an interface type.
        result = new TypeMask.nonNullSubtype(cls.declaration, compiler.world);
      } else {
        result = new TypeMask.nonNullSubclass(cls.declaration, compiler.world);
      }
      cachedTypeOfThis = result;
    }
    return result;
  }

  Map<Element, TypeMask> cachedTypesOfCapturedVariables =
      new Map<Element, TypeMask>();

  TypeMask getTypeOfCapturedVariable(Element element) {
    assert(element.isField);
    return cachedTypesOfCapturedVariables.putIfAbsent(element, () {
      return TypeMaskFactory.inferredTypeForElement(element, compiler);
    });
  }

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [functionElement] must be an implementation element.
   */
  HGraph buildMethod(FunctionElement functionElement) {
    assert(invariant(functionElement, functionElement.isImplementation));
    graph.calledInLoop = compiler.world.isCalledInLoop(functionElement);
    ast.FunctionExpression function = functionElement.node;
    assert(function != null);
    assert(elements.getFunctionDefinition(function) != null);
    openFunction(functionElement, function);
    String name = functionElement.name;
    if (backend.isJsInterop(functionElement)) {
      push(invokeJsInteropFunction(functionElement, parameters.values.toList(),
          sourceInformationBuilder.buildGeneric(function)));
      var value = pop();
      closeAndGotoExit(new HReturn(value,
          sourceInformationBuilder.buildReturn(functionElement.node)));
      return closeFunction();
    }
    assert(invariant(functionElement, !function.modifiers.isExternal));

    // If [functionElement] is `operator==` we explicitely add a null check at
    // the beginning of the method. This is to avoid having call sites do the
    // null check.
    if (name == '==') {
      if (!backend.operatorEqHandlesNullArgument(functionElement)) {
        handleIf(
            function,
            visitCondition: () {
              HParameterValue parameter = parameters.values.first;
              push(new HIdentity(
                  parameter, graph.addConstantNull(compiler), null,
                  backend.boolType));
            },
            visitThen: () {
              closeAndGotoExit(new HReturn(
                  graph.addConstantBool(false, compiler),
                  sourceInformationBuilder
                      .buildImplicitReturn(functionElement)));
            },
            visitElse: null,
            sourceInformation: sourceInformationBuilder.buildIf(function.body));
      }
    }
    if (const bool.fromEnvironment('unreachable-throw') == true) {
      var emptyParameters = parameters.values
          .where((p) => p.instructionType.isEmpty);
      if (emptyParameters.length > 0) {
        addComment('${emptyParameters} inferred as [empty]');
        pushInvokeStatic(function.body, helpers.assertUnreachableMethod, []);
        pop();
        return closeFunction();
      }
    }
    function.body.accept(this);
    return closeFunction();
  }

  /// Adds a JavaScript comment to the output. The comment will be omitted in
  /// minified mode.  Each line in [text] is preceded with `//` and indented.
  /// Use sparingly. In order for the comment to be retained it is modeled as
  /// having side effects which will inhibit code motion.
  // TODO(sra): Figure out how to keep comment anchored without effects.
  void addComment(String text) {
    add(new HForeignCode(
        js.js.statementTemplateYielding(new js.Comment(text)),
        backend.dynamicType,
        <HInstruction>[],
        isStatement: true));
  }

  HGraph buildCheckedSetter(VariableElement field) {
    openFunction(field, field.node);
    HInstruction thisInstruction = localsHandler.readThis();
    // Use dynamic type because the type computed by the inferrer is
    // narrowed to the type annotation.
    HInstruction parameter = new HParameterValue(field, backend.dynamicType);
    // Add the parameter as the last instruction of the entry block.
    // If the method is intercepted, we want the actual receiver
    // to be the first parameter.
    graph.entry.addBefore(graph.entry.last, parameter);
    HInstruction value = potentiallyCheckOrTrustType(parameter, field.type);
    add(new HFieldSet(field, thisInstruction, value));
    return closeFunction();
  }

  HGraph buildLazyInitializer(VariableElement variable) {
    inLazyInitializerExpression = true;
    assert(invariant(variable, variable.initializer != null,
        message: "Non-constant variable $variable has no initializer."));
    ast.VariableDefinitions node = variable.node;
    openFunction(variable, node);
    visit(variable.initializer);
    HInstruction value = pop();
    value = potentiallyCheckOrTrustType(value, variable.type);
    ast.SendSet sendSet = node.definitions.nodes.head;
    closeAndGotoExit(new HReturn(value,
        sourceInformationBuilder.buildReturn(sendSet.assignmentOperator)));
    return closeFunction();
  }

  /**
   * Returns the constructor body associated with the given constructor or
   * creates a new constructor body, if none can be found.
   *
   * Returns [:null:] if the constructor does not have a body.
   */
  ConstructorBodyElement getConstructorBody(FunctionElement constructor) {
    assert(constructor.isGenerativeConstructor);
    assert(invariant(constructor, constructor.isImplementation));
    if (constructor.isSynthesized) return null;
    ast.FunctionExpression node = constructor.node;
    // If we know the body doesn't have any code, we don't generate it.
    if (!node.hasBody()) return null;
    if (node.hasEmptyBody()) return null;
    ClassElement classElement = constructor.enclosingClass;
    ConstructorBodyElement bodyElement;
    classElement.forEachBackendMember((Element backendMember) {
      if (backendMember.isGenerativeConstructorBody) {
        ConstructorBodyElement body = backendMember;
        if (body.constructor == constructor) {
          // TODO(kasperl): Find a way of stopping the iteration
          // through the backend members.
          bodyElement = backendMember;
        }
      }
    });
    if (bodyElement == null) {
      bodyElement = new ConstructorBodyElementX(constructor);
      classElement.addBackendMember(bodyElement);

      if (constructor.isPatch) {
        // Create origin body element for patched constructors.
        ConstructorBodyElementX patch = bodyElement;
        ConstructorBodyElementX origin =
            new ConstructorBodyElementX(constructor.origin);
        origin.applyPatch(patch);
        classElement.origin.addBackendMember(bodyElement.origin);
      }
    }
    assert(bodyElement.isGenerativeConstructorBody);
    return bodyElement;
  }

  HParameterValue addParameter(Entity parameter, TypeMask type) {
    assert(inliningStack.isEmpty);
    HParameterValue result = new HParameterValue(parameter, type);
    if (lastAddedParameter == null) {
      graph.entry.addBefore(graph.entry.first, result);
    } else {
      graph.entry.addAfter(lastAddedParameter, result);
    }
    lastAddedParameter = result;
    return result;
  }

  /**
   * This method sets up the local state of the builder for inlining [function].
   * The arguments of the function are inserted into the [localsHandler].
   *
   * When inlining a function, [:return:] statements are not emitted as
   * [HReturn] instructions. Instead, the value of a synthetic element is
   * updated in the [localsHandler]. This function creates such an element and
   * stores it in the [returnLocal] field.
   */
  void setupStateForInlining(FunctionElement function,
                             List<HInstruction> compiledArguments,
                             {InterfaceType instanceType}) {
    localsHandler = new LocalsHandler(this, function, instanceType);
    localsHandler.closureData =
        compiler.closureToClassMapper.computeClosureToClassMapping(
            function, function.node, elements);
    returnLocal = new SyntheticLocal("result", function);
    localsHandler.updateLocal(returnLocal,
        graph.addConstantNull(compiler));

    inTryStatement = false; // TODO(lry): why? Document.

    int argumentIndex = 0;
    if (function.isInstanceMember) {
      localsHandler.updateLocal(localsHandler.closureData.thisLocal,
          compiledArguments[argumentIndex++]);
    }

    FunctionSignature signature = function.functionSignature;
    signature.orderedForEachParameter((ParameterElement parameter) {
      HInstruction argument = compiledArguments[argumentIndex++];
      localsHandler.updateLocal(parameter, argument);
    });

    ClassElement enclosing = function.enclosingClass;
    if ((function.isConstructor || function.isGenerativeConstructorBody)
        && backend.classNeedsRti(enclosing)) {
      enclosing.typeVariables.forEach((TypeVariableType typeVariable) {
        HInstruction argument = compiledArguments[argumentIndex++];
        localsHandler.updateLocal(
            localsHandler.getTypeVariableAsLocal(typeVariable), argument);
      });
    }
    assert(argumentIndex == compiledArguments.length);

    elements = function.resolvedAst.elements;
    assert(elements != null);
    returnType = signature.type.returnType;
    stack = <HInstruction>[];

    insertTraceCall(function);
    insertCoverageCall(function);
  }

  void restoreState(AstInliningState state) {
    localsHandler = state.oldLocalsHandler;
    returnLocal = state.oldReturnLocal;
    inTryStatement = state.inTryStatement;
    elements = state.oldElements;
    returnType = state.oldReturnType;
    assert(stack.isEmpty);
    stack = state.oldStack;
  }

  /**
   * Run this builder on the body of the [function] to be inlined.
   */
  void visitInlinedFunction(FunctionElement function) {
    potentiallyCheckInlinedParameterTypes(function);

    if (function.isGenerativeConstructor) {
      buildFactory(function);
    } else {
      ast.FunctionExpression functionNode = function.node;
      functionNode.body.accept(this);
    }
  }


  addInlinedInstantiation(DartType type) {
    if (type != null) {
      currentInlinedInstantiations.add(type);
    }
  }

  removeInlinedInstantiation(DartType type) {
    if (type != null) {
      currentInlinedInstantiations.removeLast();
    }
  }

  bool providedArgumentsKnownToBeComplete(ast.Node currentNode) {
    /* When inlining the iterator methods generated for a [:for-in:] loop, the
     * [currentNode] is the [ForIn] tree. The compiler-generated iterator
     * invocations are known to have fully specified argument lists, no default
     * arguments are used. See invocations of [pushInvokeDynamic] in
     * [visitForIn].
     */
    return currentNode.asForIn() != null;
  }

  /**
   * In checked mode, generate type tests for the parameters of the inlined
   * function.
   */
  void potentiallyCheckInlinedParameterTypes(FunctionElement function) {
    if (!_checkOrTrustTypes) return;

    FunctionSignature signature = function.functionSignature;
    signature.orderedForEachParameter((ParameterElement parameter) {
      HInstruction argument = localsHandler.readLocal(parameter);
      potentiallyCheckOrTrustType(argument, parameter.type);
    });
  }

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [constructors] must contain only implementation elements.
   */
  void inlineSuperOrRedirect(ConstructorElement callee,
                             List<HInstruction> compiledArguments,
                             List<FunctionElement> constructors,
                             Map<Element, HInstruction> fieldValues,
                             FunctionElement caller) {
    callee = callee.implementation;
    reporter.withCurrentElement(callee, () {
      constructors.add(callee);
      ClassElement enclosingClass = callee.enclosingClass;
      if (backend.classNeedsRti(enclosingClass)) {
        // If [enclosingClass] needs RTI, we have to give a value to its
        // type parameters.
        ClassElement currentClass = caller.enclosingClass;
        // For a super constructor call, the type is the supertype of
        // [currentClass]. For a redirecting constructor, the type is
        // the current type. [InterfaceType.asInstanceOf] takes care
        // of both.
        InterfaceType type = currentClass.thisType.asInstanceOf(enclosingClass);
        type = localsHandler.substInContext(type);
        List<DartType> arguments = type.typeArguments;
        List<DartType> typeVariables = enclosingClass.typeVariables;
        if (!type.isRaw) {
          assert(arguments.length == typeVariables.length);
          Iterator<DartType> variables = typeVariables.iterator;
          type.typeArguments.forEach((DartType argument) {
            variables.moveNext();
            TypeVariableType typeVariable = variables.current;
            localsHandler.updateLocal(
                localsHandler.getTypeVariableAsLocal(typeVariable),
                analyzeTypeArgument(argument));
          });
        } else {
          // If the supertype is a raw type, we need to set to null the
          // type variables.
          for (TypeVariableType variable in typeVariables) {
            localsHandler.updateLocal(
                localsHandler.getTypeVariableAsLocal(variable),
                graph.addConstantNull(compiler));
          }
        }
      }

      // For redirecting constructors, the fields will be initialized later
      // by the effective target.
      if (!callee.isRedirectingGenerative) {
        inlinedFrom(callee, () {
          buildFieldInitializers(callee.enclosingClass.implementation,
                               fieldValues);
        });
      }

      int index = 0;
      FunctionSignature params = callee.functionSignature;
      params.orderedForEachParameter((ParameterElement parameter) {
        HInstruction argument = compiledArguments[index++];
        // Because we are inlining the initializer, we must update
        // what was given as parameter. This will be used in case
        // there is a parameter check expression in the initializer.
        parameters[parameter] = argument;
        localsHandler.updateLocal(parameter, argument);
        // Don't forget to update the field, if the parameter is of the
        // form [:this.x:].
        if (parameter.isInitializingFormal) {
          InitializingFormalElement fieldParameterElement = parameter;
          fieldValues[fieldParameterElement.fieldElement] = argument;
        }
      });

      // Build the initializers in the context of the new constructor.
      TreeElements oldElements = elements;
      ResolvedAst resolvedAst = callee.resolvedAst;
      elements = resolvedAst.elements;
      ClosureClassMap oldClosureData = localsHandler.closureData;
      ast.Node node = resolvedAst.node;
      ClosureClassMap newClosureData =
          compiler.closureToClassMapper.computeClosureToClassMapping(
              callee, node, elements);
      localsHandler.closureData = newClosureData;
      localsHandler.enterScope(node, callee);
      buildInitializers(callee, constructors, fieldValues);
      localsHandler.closureData = oldClosureData;
      elements = oldElements;
    });
  }

  /**
   * Run through the initializers and inline all field initializers. Recursively
   * inlines super initializers.
   *
   * The constructors of the inlined initializers is added to [constructors]
   * with sub constructors having a lower index than super constructors.
   *
   * Invariant: The [constructor] and elements in [constructors] must all be
   * implementation elements.
   */
  void buildInitializers(ConstructorElement constructor,
                         List<FunctionElement> constructors,
                         Map<Element, HInstruction> fieldValues) {
    assert(invariant(constructor, constructor.isImplementation));
    if (constructor.isSynthesized) {
      List<HInstruction> arguments = <HInstruction>[];
      HInstruction compileArgument(ParameterElement parameter) {
        return localsHandler.readLocal(parameter);
      }

      Element target = constructor.definingConstructor.implementation;
      bool match = !target.isMalformed &&
          CallStructure.addForwardingElementArgumentsToList(
              constructor,
              arguments,
              target,
              compileArgument,
              handleConstantForOptionalParameter);
      if (!match) {
        if (compiler.elementHasCompileTimeError(constructor)) {
          return;
        }
        // If this fails, the selector we constructed for the call to a
        // forwarding constructor in a mixin application did not match the
        // constructor (which, for example, may happen when the libraries are
        // not compatible for private names, see issue 20394).
        reporter.internalError(constructor,
                               'forwarding constructor call does not match');
      }
      inlineSuperOrRedirect(
          target,
          arguments,
          constructors,
          fieldValues,
          constructor);
      return;
    }
    ast.FunctionExpression functionNode = constructor.node;

    bool foundSuperOrRedirect = false;
    if (functionNode.initializers != null) {
      Link<ast.Node> initializers = functionNode.initializers.nodes;
      for (Link<ast.Node> link = initializers; !link.isEmpty; link = link.tail) {
        assert(link.head is ast.Send);
        if (link.head is !ast.SendSet) {
          // A super initializer or constructor redirection.
          foundSuperOrRedirect = true;
          ast.Send call = link.head;
          assert(ast.Initializers.isSuperConstructorCall(call) ||
                 ast.Initializers.isConstructorRedirect(call));
          FunctionElement target = elements[call].implementation;
          CallStructure callStructure =
              elements.getSelector(call).callStructure;
          Link<ast.Node> arguments = call.arguments;
          List<HInstruction> compiledArguments;
          inlinedFrom(constructor, () {
            compiledArguments =
                makeStaticArgumentList(callStructure, arguments, target);
          });
          inlineSuperOrRedirect(target,
                                compiledArguments,
                                constructors,
                                fieldValues,
                                constructor);
        } else {
          // A field initializer.
          ast.SendSet init = link.head;
          Link<ast.Node> arguments = init.arguments;
          assert(!arguments.isEmpty && arguments.tail.isEmpty);
          inlinedFrom(constructor, () {
            visit(arguments.head);
          });
          fieldValues[elements[init]] = pop();
        }
      }
    }

    if (!foundSuperOrRedirect) {
      // No super initializer found. Try to find the default constructor if
      // the class is not Object.
      ClassElement enclosingClass = constructor.enclosingClass;
      ClassElement superClass = enclosingClass.superclass;
      if (!enclosingClass.isObject) {
        assert(superClass != null);
        assert(superClass.isResolved);
        // TODO(johnniwinther): Should we find injected constructors as well?
        FunctionElement target = superClass.lookupDefaultConstructor();
        if (target == null) {
          reporter.internalError(superClass,
              "No default constructor available.");
        }
        List<HInstruction> arguments =
            CallStructure.NO_ARGS.makeArgumentsList(
                const Link<ast.Node>(),
                target.implementation,
                null,
                handleConstantForOptionalParameter);
        inlineSuperOrRedirect(target,
                              arguments,
                              constructors,
                              fieldValues,
                              constructor);
      }
    }
  }

  /**
   * Run through the fields of [cls] and add their potential
   * initializers.
   *
   * Invariant: [classElement] must be an implementation element.
   */
  void buildFieldInitializers(ClassElement classElement,
                              Map<Element, HInstruction> fieldValues) {
    assert(invariant(classElement, classElement.isImplementation));
    classElement.forEachInstanceField(
        (ClassElement enclosingClass, VariableElement member) {
          if (compiler.elementHasCompileTimeError(member)) return;
          reporter.withCurrentElement(member, () {
            TreeElements definitions = member.treeElements;
            ast.Node node = member.node;
            ast.Expression initializer = member.initializer;
            if (initializer == null) {
              // Unassigned fields of native classes are not initialized to
              // prevent overwriting pre-initialized native properties.
              if (!backend.isNativeOrExtendsNative(classElement)) {
                fieldValues[member] = graph.addConstantNull(compiler);
              }
            } else {
              ast.Node right = initializer;
              TreeElements savedElements = elements;
              elements = definitions;
              // In case the field initializer uses closures, run the
              // closure to class mapper.
              compiler.closureToClassMapper.computeClosureToClassMapping(
                  member, node, elements);
              inlinedFrom(member, () => right.accept(this));
              elements = savedElements;
              fieldValues[member] = pop();
            }
          });
        });
  }

  /**
   * Build the factory function corresponding to the constructor
   * [functionElement]:
   *  - Initialize fields with the values of the field initializers of the
   *    current constructor and super constructors or constructors redirected
   *    to, starting from the current constructor.
   *  - Call the constructor bodies, starting from the constructor(s) in the
   *    super class(es).
   */
  HGraph buildFactory(ConstructorElement functionElement) {
    functionElement = functionElement.implementation;
    ClassElement classElement =
        functionElement.enclosingClass.implementation;
    bool isNativeUpgradeFactory =
        backend.isNativeOrExtendsNative(classElement)
            && !backend.isJsInterop(classElement);
    ast.FunctionExpression function = functionElement.node;
    // Note that constructors (like any other static function) do not need
    // to deal with optional arguments. It is the callers job to provide all
    // arguments as if they were positional.

    if (inliningStack.isEmpty) {
      // The initializer list could contain closures.
      openFunction(functionElement, function);
    }

    Map<Element, HInstruction> fieldValues = new Map<Element, HInstruction>();

    // Compile the possible initialization code for local fields and
    // super fields, unless this is a redirecting constructor, in which case
    // the effective target will initialize these.
    if (!functionElement.isRedirectingGenerative) {
      buildFieldInitializers(classElement, fieldValues);
    }

    // Compile field-parameters such as [:this.x:].
    FunctionSignature params = functionElement.functionSignature;
    params.orderedForEachParameter((ParameterElement parameter) {
      if (parameter.isInitializingFormal) {
        // If the [element] is a field-parameter then
        // initialize the field element with its value.
        InitializingFormalElement fieldParameter = parameter;
        HInstruction parameterValue =
            localsHandler.readLocal(fieldParameter);
        fieldValues[fieldParameter.fieldElement] = parameterValue;
      }
    });

    // Analyze the constructor and all referenced constructors and collect
    // initializers and constructor bodies.
    List<FunctionElement> constructors = <FunctionElement>[functionElement];
    buildInitializers(functionElement, constructors, fieldValues);

    // Call the JavaScript constructor with the fields as argument.
    List<HInstruction> constructorArguments = <HInstruction>[];
    List<Element> fields = <Element>[];

    classElement.forEachInstanceField(
        (ClassElement enclosingClass, VariableElement member) {
          HInstruction value = fieldValues[member];
          if (value == null) {
            // Uninitialized native fields are pre-initialized by the native
            // implementation.
            assert(invariant(
                member, isNativeUpgradeFactory || compiler.compilationFailed));
          } else {
            fields.add(member);
            DartType type = localsHandler.substInContext(member.type);
            constructorArguments.add(potentiallyCheckOrTrustType(value, type));
          }
        },
        includeSuperAndInjectedMembers: true);

    InterfaceType type = classElement.thisType;
    TypeMask ssaType =
        new TypeMask.nonNullExact(classElement.declaration, compiler.world);
    List<DartType> instantiatedTypes;
    addInlinedInstantiation(type);
    if (!currentInlinedInstantiations.isEmpty) {
      instantiatedTypes = new List<DartType>.from(currentInlinedInstantiations);
    }

    HInstruction newObject;
    if (!isNativeUpgradeFactory) {
      newObject = new HForeignNew(classElement,
          ssaType,
          constructorArguments,
          instantiatedTypes);
      if (function != null) {
        // TODO(johnniwinther): Provide source information for creation
        // through synthetic constructors.
        newObject.sourceInformation =
            sourceInformationBuilder.buildCreate(function);
      }
      add(newObject);
    } else {
      // Bulk assign to the initialized fields.
      newObject = graph.explicitReceiverParameter;
      // Null guard ensures an error if we are being called from an explicit
      // 'new' of the constructor instead of via an upgrade. It is optimized out
      // if there are field initializers.
      add(new HFieldGet(
          null, newObject, backend.dynamicType, isAssignable: false));
      for (int i = 0; i < fields.length; i++) {
        add(new HFieldSet(fields[i], newObject, constructorArguments[i]));
      }
    }
    removeInlinedInstantiation(type);
    // Create the runtime type information, if needed.
    if (backend.classNeedsRti(classElement)) {
      // Read the values of the type arguments and create a list to set on the
      // newly create object.  We can identify the case where the new list
      // would be of the form:
      //  [getTypeArgumentByIndex(this, 0), .., getTypeArgumentByIndex(this, k)]
      // and k is the number of type arguments of this.  If this is the case,
      // we can simply copy the list from this.

      // These locals are modified by [isIndexedTypeArgumentGet].
      HThis source;  // The source of the type arguments.
      bool allIndexed = true;
      int expectedIndex = 0;
      ClassElement contextClass;  // The class of `this`.
      int remainingTypeVariables;  // The number of 'remaining type variables'
                                   // of `this`.

      /// Helper to identify instructions that read a type variable without
      /// substitution (that is, directly use the index). These instructions
      /// are of the form:
      ///   HInvokeStatic(getTypeArgumentByIndex, this, index)
      ///
      /// Return `true` if [instruction] is of that form and the index is the
      /// next index in the sequence (held in [expectedIndex]).
      bool isIndexedTypeArgumentGet(HInstruction instruction) {
        if (instruction is! HInvokeStatic) return false;
        HInvokeStatic invoke = instruction;
        if (invoke.element != helpers.getTypeArgumentByIndex) {
          return false;
        }
        HConstant index = invoke.inputs[1];
        HInstruction newSource = invoke.inputs[0];
        if (newSource is! HThis) {
          return false;
        }
        if (source == null) {
          // This is the first match. Extract the context class for the type
          // variables and get the list of type variables to keep track of how
          // many arguments we need to process.
          source = newSource;
          contextClass = source.sourceElement.enclosingClass;
          remainingTypeVariables = contextClass.typeVariables.length;
        } else {
          assert(source == newSource);
        }
        // If there are no more type variables, then there are more type
        // arguments for the new object than the source has, and it can't be
        // a copy.  Otherwise remove one argument.
        if (remainingTypeVariables == 0) return false;
        remainingTypeVariables--;
        // Check that the index is the one we expect.
        IntConstantValue constant = index.constant;
        return constant.primitiveValue == expectedIndex++;
      }

      List<HInstruction> typeArguments = <HInstruction>[];
      classElement.typeVariables.forEach((TypeVariableType typeVariable) {
        HInstruction argument = localsHandler.readLocal(
            localsHandler.getTypeVariableAsLocal(typeVariable));
        if (allIndexed && !isIndexedTypeArgumentGet(argument)) {
          allIndexed = false;
        }
        typeArguments.add(argument);
      });

      if (source != null && allIndexed && remainingTypeVariables == 0) {
        copyRuntimeTypeInfo(source, newObject);
      } else {
        newObject =
            callSetRuntimeTypeInfo(classElement, typeArguments, newObject);
      }
    }

    // Generate calls to the constructor bodies.
    HInstruction interceptor = null;
    for (int index = constructors.length - 1; index >= 0; index--) {
      FunctionElement constructor = constructors[index];
      assert(invariant(functionElement, constructor.isImplementation));
      ConstructorBodyElement body = getConstructorBody(constructor);
      if (body == null) continue;

      List bodyCallInputs = <HInstruction>[];
      if (isNativeUpgradeFactory) {
        if (interceptor == null) {
          ConstantValue constant =
              new InterceptorConstantValue(classElement.thisType);
          interceptor = graph.addConstant(constant, compiler);
        }
        bodyCallInputs.add(interceptor);
      }
      bodyCallInputs.add(newObject);
      ResolvedAst resolvedAst = constructor.resolvedAst;
      ast.Node node = resolvedAst.node;
      ClosureClassMap parameterClosureData =
          compiler.closureToClassMapper.getMappingForNestedFunction(node);

      FunctionSignature functionSignature = body.functionSignature;
      // Provide the parameters to the generative constructor body.
      functionSignature.orderedForEachParameter((ParameterElement parameter) {
        // If [parameter] is boxed, it will be a field in the box passed as the
        // last parameter. So no need to directly pass it.
        if (!localsHandler.isBoxed(parameter)) {
          bodyCallInputs.add(localsHandler.readLocal(parameter));
        }
      });

      // If there are locals that escape (ie mutated in closures), we
      // pass the box to the constructor.
      // The box must be passed before any type variable.
      ClosureScope scopeData = parameterClosureData.capturingScopes[node];
      if (scopeData != null) {
        bodyCallInputs.add(localsHandler.readLocal(scopeData.boxElement));
      }

      // Type variables arguments must come after the box (if there is one).
      ClassElement currentClass = constructor.enclosingClass;
      if (backend.classNeedsRti(currentClass)) {
        // If [currentClass] needs RTI, we add the type variables as
        // parameters of the generative constructor body.
        currentClass.typeVariables.forEach((TypeVariableType argument) {
          // TODO(johnniwinther): Substitute [argument] with
          // `localsHandler.substInContext(argument)`.
          bodyCallInputs.add(localsHandler.readLocal(
              localsHandler.getTypeVariableAsLocal(argument)));
        });
      }

      if (!isNativeUpgradeFactory && // TODO(13836): Fix inlining.
          tryInlineMethod(body, null, null, bodyCallInputs, function)) {
        pop();
      } else {
        HInvokeConstructorBody invoke = new HInvokeConstructorBody(
            body.declaration, bodyCallInputs, backend.nonNullType);
        invoke.sideEffects =
            compiler.world.getSideEffectsOfElement(constructor);
        add(invoke);
      }
    }
    if (inliningStack.isEmpty) {
      closeAndGotoExit(new HReturn(newObject,
          sourceInformationBuilder.buildImplicitReturn(functionElement)));
      return closeFunction();
    } else {
      localsHandler.updateLocal(returnLocal, newObject);
      return null;
    }
  }

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [functionElement] must be the implementation element.
   */
  void openFunction(Element element, ast.Node node) {
    assert(invariant(element, element.isImplementation));
    HBasicBlock block = graph.addNewBlock();
    open(graph.entry);

    localsHandler.startFunction(element, node);
    close(new HGoto()).addSuccessor(block);

    open(block);

    // Add the type parameters of the class as parameters of this method.  This
    // must be done before adding the normal parameters, because their types
    // may contain references to type variables.
    var enclosing = element.enclosingElement;
    if ((element.isConstructor || element.isGenerativeConstructorBody)
        && backend.classNeedsRti(enclosing)) {
      enclosing.typeVariables.forEach((TypeVariableType typeVariable) {
        HParameterValue param = addParameter(
            typeVariable.element, backend.nonNullType);
        localsHandler.directLocals[
            localsHandler.getTypeVariableAsLocal(typeVariable)] = param;
      });
    }

    if (element is FunctionElement) {
      FunctionElement functionElement = element;
      FunctionSignature signature = functionElement.functionSignature;

      // Put the type checks in the first successor of the entry,
      // because that is where the type guards will also be inserted.
      // This way we ensure that a type guard will dominate the type
      // check.
      ClosureScope scopeData =
          localsHandler.closureData.capturingScopes[node];
      signature.orderedForEachParameter((ParameterElement parameterElement) {
        if (element.isGenerativeConstructorBody) {
          if (scopeData != null &&
              scopeData.isCapturedVariable(parameterElement)) {
            // The parameter will be a field in the box passed as the
            // last parameter. So no need to have it.
            return;
          }
        }
        HInstruction newParameter =
            localsHandler.directLocals[parameterElement];
        if (!element.isConstructor ||
            !(element as ConstructorElement).isRedirectingFactory) {
          // Redirection factories must not check their argument types.
          // Example:
          //
          //     class A {
          //       A(String foo) = A.b;
          //       A(int foo) { print(foo); }
          //     }
          //     main() {
          //       new A(499);    // valid even in checked mode.
          //       new A("foo");  // invalid in checked mode.
          //
          // Only the final target is allowed to check for the argument types.
          newParameter =
              potentiallyCheckOrTrustType(newParameter, parameterElement.type);
        }
        localsHandler.directLocals[parameterElement] = newParameter;
      });

      returnType = signature.type.returnType;
    } else {
      // Otherwise it is a lazy initializer which does not have parameters.
      assert(element is VariableElement);
    }

    insertTraceCall(element);
    insertCoverageCall(element);
  }

  insertTraceCall(Element element) {
    if (JavaScriptBackend.TRACE_METHOD == 'console') {
      if (element == backend.traceHelper) return;
      n(e) => e == null ? '' : e.name;
      String name = "${n(element.library)}:${n(element.enclosingClass)}."
        "${n(element)}";
      HConstant nameConstant = addConstantString(name);
      add(new HInvokeStatic(backend.traceHelper,
                            <HInstruction>[nameConstant],
                            backend.dynamicType));
    }
  }

  insertCoverageCall(Element element) {
    if (JavaScriptBackend.TRACE_METHOD == 'post') {
      if (element == backend.traceHelper) return;
      // TODO(sigmund): create a better uuid for elements.
      HConstant idConstant = graph.addConstantInt(element.hashCode, compiler);
      HConstant nameConstant = addConstantString(element.name);
      add(new HInvokeStatic(backend.traceHelper,
                            <HInstruction>[idConstant, nameConstant],
                            backend.dynamicType));
    }
  }

  /// Check that [type] is valid in the context of `localsHandler.contextClass`.
  /// This should only be called in assertions.
  bool assertTypeInContext(DartType type, [Spannable spannable]) {
    return invariant(spannable == null ? CURRENT_ELEMENT_SPANNABLE : spannable,
        () {
          ClassElement contextClass = Types.getClassContext(type);
          return contextClass == null ||
                 contextClass == localsHandler.contextClass;
        },
        message: "Type '$type' is not valid context of "
                 "${localsHandler.contextClass}.");
  }

  /// Build a [HTypeConversion] for convertion [original] to type [type].
  ///
  /// Invariant: [type] must be valid in the context.
  /// See [LocalsHandler.substInContext].
  HInstruction buildTypeConversion(HInstruction original,
                                   DartType type,
                                   int kind) {
    if (type == null) return original;
    type = type.unaliased;
    assert(assertTypeInContext(type, original));
    if (type.isInterfaceType && !type.treatAsRaw) {
      TypeMask subtype = new TypeMask.subtype(type.element, compiler.world);
      HInstruction representations = buildTypeArgumentRepresentations(type);
      add(representations);
      return new HTypeConversion.withTypeRepresentation(type, kind, subtype,
          original, representations);
    } else if (type.isTypeVariable) {
      TypeMask subtype = original.instructionType;
      HInstruction typeVariable = addTypeVariableReference(type);
      return new HTypeConversion.withTypeRepresentation(type, kind, subtype,
          original, typeVariable);
    } else if (type.isFunctionType) {
      String name = kind == HTypeConversion.CAST_TYPE_CHECK
          ? '_asCheck' : '_assertCheck';

      List<HInstruction> arguments =
          <HInstruction>[buildFunctionType(type), original];
      pushInvokeDynamic(
          null,
          new Selector.call(
              new Name(name, helpers.jsHelperLibrary), CallStructure.ONE_ARG),
          null,
          arguments);

      return new HTypeConversion(type, kind, original.instructionType, pop());
    } else {
      return original.convertType(compiler, type, kind);
    }
  }

  HInstruction _trustType(HInstruction original, DartType type) {
    assert(compiler.trustTypeAnnotations);
    assert(type != null);
    type = localsHandler.substInContext(type);
    type = type.unaliased;
    if (type.isDynamic) return original;
    if (!type.isInterfaceType) return original;
    if (type.isObject) return original;
    // The type element is either a class or the void element.
    Element element = type.element;
    TypeMask mask = new TypeMask.subtype(element, compiler.world);
    return new HTypeKnown.pinned(mask, original);
  }

  HInstruction _checkType(HInstruction original, DartType type, int kind) {
    assert(compiler.enableTypeAssertions);
    assert(type != null);
    type = localsHandler.substInContext(type);
    HInstruction other = buildTypeConversion(original, type, kind);
    registry?.registerTypeUse(new TypeUse.isCheck(type));
    return other;
  }

  HInstruction potentiallyCheckOrTrustType(HInstruction original, DartType type,
      { int kind: HTypeConversion.CHECKED_MODE_CHECK }) {
    if (type == null) return original;
    HInstruction checkedOrTrusted = original;
    if (compiler.trustTypeAnnotations) {
      checkedOrTrusted = _trustType(original, type);
    } else if (compiler.enableTypeAssertions) {
      checkedOrTrusted = _checkType(original, type, kind);
    }
    if (checkedOrTrusted == original) return original;
    add(checkedOrTrusted);
    return checkedOrTrusted;
  }

  void assertIsSubtype(ast.Node node, DartType subtype, DartType supertype,
                       String message) {
    HInstruction subtypeInstruction =
        analyzeTypeArgument(localsHandler.substInContext(subtype));
    HInstruction supertypeInstruction =
        analyzeTypeArgument(localsHandler.substInContext(supertype));
    HInstruction messageInstruction =
        graph.addConstantString(new ast.DartString.literal(message), compiler);
    Element element = helpers.assertIsSubtype;
    var inputs = <HInstruction>[subtypeInstruction, supertypeInstruction,
                                messageInstruction];
    HInstruction assertIsSubtype = new HInvokeStatic(
        element, inputs, subtypeInstruction.instructionType);
    registry?.registerTypeVariableBoundsSubtypeCheck(subtype, supertype);
    add(assertIsSubtype);
  }

  HGraph closeFunction() {
    // TODO(kasperl): Make this goto an implicit return.
    if (!isAborted()) closeAndGotoExit(new HGoto());
    graph.finalize();
    return graph;
  }

  void push(HInstruction instruction) {
    add(instruction);
    stack.add(instruction);
  }

  void pushWithPosition(HInstruction instruction, ast.Node node) {
    push(attachPosition(instruction, node));
  }

  HInstruction pop() {
    return stack.removeLast();
  }

  void dup() {
    stack.add(stack.last);
  }

  HInstruction popBoolified() {
    HInstruction value = pop();
    if (_checkOrTrustTypes) {
      return potentiallyCheckOrTrustType(
          value,
          compiler.coreTypes.boolType,
          kind: HTypeConversion.BOOLEAN_CONVERSION_CHECK);
    }
    HInstruction result = new HBoolify(value, backend.boolType);
    add(result);
    return result;
  }

  HInstruction attachPosition(HInstruction target, ast.Node node) {
    if (node != null) {
      target.sourceInformation = sourceInformationBuilder.buildGeneric(node);
    }
    return target;
  }

  void visit(ast.Node node) {
    if (node != null) node.accept(this);
  }

  /// Visit [node] and pop the resulting [HInstruction].
  HInstruction visitAndPop(ast.Node node) {
    node.accept(this);
    return pop();
  }

  visitAssert(ast.Assert node) {
    if (!compiler.enableUserAssertions) return;

    if (!node.hasMessage) {
      // Generate:
      //
      //     assertHelper(condition);
      //
      visit(node.condition);
      pushInvokeStatic(node, helpers.assertHelper, [pop()]);
      pop();
      return;
    }
    // Assert has message. Generate:
    //
    //     if (assertTest(condition)) assertThrow(message);
    //
    void buildCondition() {
      visit(node.condition);
      pushInvokeStatic(node, helpers.assertTest, [pop()]);
    }
    void fail() {
      visit(node.message);
      pushInvokeStatic(node, helpers.assertThrow, [pop()]);
      pop();
    }
    handleIf(node,
             visitCondition: buildCondition,
             visitThen: fail);
  }

  visitBlock(ast.Block node) {
    assert(!isAborted());
    if (!isReachable) return;  // This can only happen when inlining.
    for (Link<ast.Node> link = node.statements.nodes;
         !link.isEmpty;
         link = link.tail) {
      visit(link.head);
      if (!isReachable) {
        // The block has been aborted by a return or a throw.
        if (!stack.isEmpty) {
          reporter.internalError(node, 'Non-empty instruction stack.');
        }
        return;
      }
    }
    assert(!current.isClosed());
    if (!stack.isEmpty) {
      reporter.internalError(node, 'Non-empty instruction stack.');
    }
  }

  visitClassNode(ast.ClassNode node) {
    reporter.internalError(node,
        'SsaBuilder.visitClassNode should not be called.');
  }

  visitThrowExpression(ast.Expression expression) {
    bool old = inExpressionOfThrow;
    try {
      inExpressionOfThrow = true;
      visit(expression);
    } finally {
      inExpressionOfThrow = old;
    }
  }

  visitExpressionStatement(ast.ExpressionStatement node) {
    if (!isReachable) return;
    ast.Throw throwExpression = node.expression.asThrow();
    if (throwExpression != null && inliningStack.isEmpty) {
      visitThrowExpression(throwExpression.expression);
      handleInTryStatement();
      closeAndGotoExit(
          new HThrow(pop(), sourceInformationBuilder.buildThrow(node)));
    } else {
      visit(node.expression);
      pop();
    }
  }

  /**
   * Creates a new loop-header block. The previous [current] block
   * is closed with an [HGoto] and replaced by the newly created block.
   * Also notifies the locals handler that we're entering a loop.
   */
  JumpHandler beginLoopHeader(ast.Node node) {
    assert(!isAborted());
    HBasicBlock previousBlock = close(new HGoto());

    JumpHandler jumpHandler = createJumpHandler(node, isLoopJump: true);
    HBasicBlock loopEntry = graph.addNewLoopHeaderBlock(
        jumpHandler.target,
        jumpHandler.labels());
    previousBlock.addSuccessor(loopEntry);
    open(loopEntry);

    localsHandler.beginLoopHeader(loopEntry);
    return jumpHandler;
  }

  /**
   * Ends the loop:
   * - creates a new block and adds it as successor to the [branchExitBlock] and
   *   any blocks that end in break.
   * - opens the new block (setting as [current]).
   * - notifies the locals handler that we're exiting a loop.
   * [savedLocals] are the locals from the end of the loop condition.
   * [branchExitBlock] is the exit (branching) block of the condition. Generally
   * this is not the top of the loop, since this would lead to critical edges.
   * It is null for degenerate do-while loops that have
   * no back edge because they abort (throw/return/break in the body and have
   * no continues).
   */
  void endLoop(HBasicBlock loopEntry,
               HBasicBlock branchExitBlock,
               JumpHandler jumpHandler,
               LocalsHandler savedLocals) {
    HBasicBlock loopExitBlock = addNewBlock();

    List<LocalsHandler> breakHandlers = <LocalsHandler>[];
    // Collect data for the successors and the phis at each break.
    jumpHandler.forEachBreak((HBreak breakInstruction, LocalsHandler locals) {
      breakInstruction.block.addSuccessor(loopExitBlock);
      breakHandlers.add(locals);
    });

    // The exit block is a successor of the loop condition if it is reached.
    // We don't add the successor in the case of a while/for loop that aborts
    // because the caller of endLoop will be wiring up a special empty else
    // block instead.
    if (branchExitBlock != null) {
      branchExitBlock.addSuccessor(loopExitBlock);
    }
    // Update the phis at the loop entry with the current values of locals.
    localsHandler.endLoop(loopEntry);

    // Start generating code for the exit block.
    open(loopExitBlock);

    // Create a new localsHandler for the loopExitBlock with the correct phis.
    if (!breakHandlers.isEmpty) {
      if (branchExitBlock != null) {
        // Add the values of the locals at the end of the condition block to
        // the phis.  These are the values that flow to the exit if the
        // condition fails.
        breakHandlers.add(savedLocals);
      }
      localsHandler = savedLocals.mergeMultiple(breakHandlers, loopExitBlock);
    } else {
      localsHandler = savedLocals;
    }
  }

  HSubGraphBlockInformation wrapStatementGraph(SubGraph statements) {
    if (statements == null) return null;
    return new HSubGraphBlockInformation(statements);
  }

  HSubExpressionBlockInformation wrapExpressionGraph(SubExpression expression) {
    if (expression == null) return null;
    return new HSubExpressionBlockInformation(expression);
  }

  // For while loops, initializer and update are null.
  // The condition function must return a boolean result.
  // None of the functions must leave anything on the stack.
  void handleLoop(ast.Node loop,
                  void initialize(),
                  HInstruction condition(),
                  void update(),
                  void body()) {
    // Generate:
    //  <initializer>
    //  loop-entry:
    //    if (!<condition>) goto loop-exit;
    //    <body>
    //    <updates>
    //    goto loop-entry;
    //  loop-exit:

    localsHandler.startLoop(loop);

    // The initializer.
    SubExpression initializerGraph = null;
    HBasicBlock startBlock;
    if (initialize != null) {
      HBasicBlock initializerBlock = openNewBlock();
      startBlock = initializerBlock;
      initialize();
      assert(!isAborted());
      initializerGraph =
          new SubExpression(initializerBlock, current);
    }

    loopNesting++;
    JumpHandler jumpHandler = beginLoopHeader(loop);
    HLoopInformation loopInfo = current.loopInformation;
    HBasicBlock conditionBlock = current;
    if (startBlock == null) startBlock = conditionBlock;

    HInstruction conditionInstruction = condition();
    HBasicBlock conditionEndBlock =
        close(new HLoopBranch(conditionInstruction));
    SubExpression conditionExpression =
        new SubExpression(conditionBlock, conditionEndBlock);

    // Save the values of the local variables at the end of the condition
    // block.  These are the values that will flow to the loop exit if the
    // condition fails.
    LocalsHandler savedLocals = new LocalsHandler.from(localsHandler);

    // The body.
    HBasicBlock beginBodyBlock = addNewBlock();
    conditionEndBlock.addSuccessor(beginBodyBlock);
    open(beginBodyBlock);

    localsHandler.enterLoopBody(loop);
    body();

    SubGraph bodyGraph = new SubGraph(beginBodyBlock, lastOpenedBlock);
    HBasicBlock bodyBlock = current;
    if (current != null) close(new HGoto());

    SubExpression updateGraph;

    bool loopIsDegenerate = !jumpHandler.hasAnyContinue() && bodyBlock == null;
    if (!loopIsDegenerate) {
      // Update.
      // We create an update block, even when we are in a while loop. There the
      // update block is the jump-target for continue statements. We could avoid
      // the creation if there is no continue, but for now we always create it.
      HBasicBlock updateBlock = addNewBlock();

      List<LocalsHandler> continueHandlers = <LocalsHandler>[];
      jumpHandler.forEachContinue((HContinue instruction,
                                   LocalsHandler locals) {
        instruction.block.addSuccessor(updateBlock);
        continueHandlers.add(locals);
      });


      if (bodyBlock != null) {
        continueHandlers.add(localsHandler);
        bodyBlock.addSuccessor(updateBlock);
      }

      open(updateBlock);
      localsHandler =
          continueHandlers[0].mergeMultiple(continueHandlers, updateBlock);

      List<LabelDefinition> labels = jumpHandler.labels();
      JumpTarget target = elements.getTargetDefinition(loop);
      if (!labels.isEmpty) {
        beginBodyBlock.setBlockFlow(
            new HLabeledBlockInformation(
                new HSubGraphBlockInformation(bodyGraph),
                jumpHandler.labels(),
                isContinue: true),
            updateBlock);
      } else if (target != null && target.isContinueTarget) {
        beginBodyBlock.setBlockFlow(
            new HLabeledBlockInformation.implicit(
                new HSubGraphBlockInformation(bodyGraph),
                target,
                isContinue: true),
            updateBlock);
      }

      localsHandler.enterLoopUpdates(loop);

      update();

      HBasicBlock updateEndBlock = close(new HGoto());
      // The back-edge completing the cycle.
      updateEndBlock.addSuccessor(conditionBlock);
      updateGraph = new SubExpression(updateBlock, updateEndBlock);

      // Avoid a critical edge from the condition to the loop-exit body.
      HBasicBlock conditionExitBlock = addNewBlock();
      open(conditionExitBlock);
      close(new HGoto());
      conditionEndBlock.addSuccessor(conditionExitBlock);

      endLoop(conditionBlock, conditionExitBlock, jumpHandler, savedLocals);

      conditionBlock.postProcessLoopHeader();
      HLoopBlockInformation info =
          new HLoopBlockInformation(
              HLoopBlockInformation.loopType(loop),
              wrapExpressionGraph(initializerGraph),
              wrapExpressionGraph(conditionExpression),
              wrapStatementGraph(bodyGraph),
              wrapExpressionGraph(updateGraph),
              conditionBlock.loopInformation.target,
              conditionBlock.loopInformation.labels,
              sourceInformationBuilder.buildLoop(loop));

      startBlock.setBlockFlow(info, current);
      loopInfo.loopBlockInformation = info;
    } else {
      // The body of the for/while loop always aborts, so there is no back edge.
      // We turn the code into:
      // if (condition) {
      //   body;
      // } else {
      //   // We always create an empty else block to avoid critical edges.
      // }
      //
      // If there is any break in the body, we attach a synthetic
      // label to the if.
      HBasicBlock elseBlock = addNewBlock();
      open(elseBlock);
      close(new HGoto());
      // Pass the elseBlock as the branchBlock, because that's the block we go
      // to just before leaving the 'loop'.
      endLoop(conditionBlock, elseBlock, jumpHandler, savedLocals);

      SubGraph elseGraph = new SubGraph(elseBlock, elseBlock);
      // Remove the loop information attached to the header.
      conditionBlock.loopInformation = null;

      // Remove the [HLoopBranch] instruction and replace it with
      // [HIf].
      HInstruction condition = conditionEndBlock.last.inputs[0];
      conditionEndBlock.addAtExit(new HIf(condition));
      conditionEndBlock.addSuccessor(elseBlock);
      conditionEndBlock.remove(conditionEndBlock.last);
      HIfBlockInformation info =
          new HIfBlockInformation(
              wrapExpressionGraph(conditionExpression),
              wrapStatementGraph(bodyGraph),
              wrapStatementGraph(elseGraph));

      conditionEndBlock.setBlockFlow(info, current);
      HIf ifBlock = conditionEndBlock.last;
      ifBlock.blockInformation = conditionEndBlock.blockFlow;

      // If the body has any break, attach a synthesized label to the
      // if block.
      if (jumpHandler.hasAnyBreak()) {
        JumpTarget target = elements.getTargetDefinition(loop);
        LabelDefinition label = target.addLabel(null, 'loop');
        label.setBreakTarget();
        SubGraph labelGraph = new SubGraph(conditionBlock, current);
        HLabeledBlockInformation labelInfo = new HLabeledBlockInformation(
                new HSubGraphBlockInformation(labelGraph),
                <LabelDefinition>[label]);

        conditionBlock.setBlockFlow(labelInfo, current);

        jumpHandler.forEachBreak((HBreak breakInstruction, _) {
          HBasicBlock block = breakInstruction.block;
          block.addAtExit(new HBreak.toLabel(label));
          block.remove(breakInstruction);
        });
      }
    }
    jumpHandler.close();
    loopNesting--;
  }

  visitFor(ast.For node) {
    assert(isReachable);
    assert(node.body != null);
    void buildInitializer() {
      ast.Node initializer = node.initializer;
      if (initializer == null) return;
      visit(initializer);
      if (initializer.asExpression() != null) {
        pop();
      }
    }
    HInstruction buildCondition() {
      if (node.condition == null) {
        return graph.addConstantBool(true, compiler);
      }
      visit(node.condition);
      return popBoolified();
    }
    void buildUpdate() {
      for (ast.Expression expression in node.update) {
        visit(expression);
        assert(!isAborted());
        // The result of the update instruction isn't used, and can just
        // be dropped.
        pop();
      }
    }
    void buildBody() {
      visit(node.body);
    }
    handleLoop(node, buildInitializer, buildCondition, buildUpdate, buildBody);
  }

  visitWhile(ast.While node) {
    assert(isReachable);
    HInstruction buildCondition() {
      visit(node.condition);
      return popBoolified();
    }
    handleLoop(node,
               () {},
               buildCondition,
               () {},
               () { visit(node.body); });
  }

  visitDoWhile(ast.DoWhile node) {
    assert(isReachable);
    LocalsHandler savedLocals = new LocalsHandler.from(localsHandler);
    localsHandler.startLoop(node);
    loopNesting++;
    JumpHandler jumpHandler = beginLoopHeader(node);
    HLoopInformation loopInfo = current.loopInformation;
    HBasicBlock loopEntryBlock = current;
    HBasicBlock bodyEntryBlock = current;
    JumpTarget target = elements.getTargetDefinition(node);
    bool hasContinues = target != null && target.isContinueTarget;
    if (hasContinues) {
      // Add extra block to hang labels on.
      // It doesn't currently work if they are on the same block as the
      // HLoopInfo. The handling of HLabeledBlockInformation will visit a
      // SubGraph that starts at the same block again, so the HLoopInfo is
      // either handled twice, or it's handled after the labeled block info,
      // both of which generate the wrong code.
      // Using a separate block is just a simple workaround.
      bodyEntryBlock = openNewBlock();
    }
    localsHandler.enterLoopBody(node);
    visit(node.body);

    // If there are no continues we could avoid the creation of the condition
    // block. This could also lead to a block having multiple entries and exits.
    HBasicBlock bodyExitBlock;
    bool isAbortingBody = false;
    if (current != null) {
      bodyExitBlock = close(new HGoto());
    } else {
      isAbortingBody = true;
      bodyExitBlock = lastOpenedBlock;
    }

    SubExpression conditionExpression;
    bool loopIsDegenerate = isAbortingBody && !hasContinues;
    if (!loopIsDegenerate) {
      HBasicBlock conditionBlock = addNewBlock();

      List<LocalsHandler> continueHandlers = <LocalsHandler>[];
      jumpHandler.forEachContinue((HContinue instruction,
                                   LocalsHandler locals) {
        instruction.block.addSuccessor(conditionBlock);
        continueHandlers.add(locals);
      });

      if (!isAbortingBody) {
        bodyExitBlock.addSuccessor(conditionBlock);
      }

      if (!continueHandlers.isEmpty) {
        if (!isAbortingBody) continueHandlers.add(localsHandler);
        localsHandler =
            savedLocals.mergeMultiple(continueHandlers, conditionBlock);
        SubGraph bodyGraph = new SubGraph(bodyEntryBlock, bodyExitBlock);
        List<LabelDefinition> labels = jumpHandler.labels();
        HSubGraphBlockInformation bodyInfo =
            new HSubGraphBlockInformation(bodyGraph);
        HLabeledBlockInformation info;
        if (!labels.isEmpty) {
          info = new HLabeledBlockInformation(bodyInfo, labels,
                                              isContinue: true);
        } else {
          info = new HLabeledBlockInformation.implicit(bodyInfo, target,
                                                       isContinue: true);
        }
        bodyEntryBlock.setBlockFlow(info, conditionBlock);
      }
      open(conditionBlock);

      visit(node.condition);
      assert(!isAborted());
      HInstruction conditionInstruction = popBoolified();
      HBasicBlock conditionEndBlock = close(
          new HLoopBranch(conditionInstruction, HLoopBranch.DO_WHILE_LOOP));

      HBasicBlock avoidCriticalEdge = addNewBlock();
      conditionEndBlock.addSuccessor(avoidCriticalEdge);
      open(avoidCriticalEdge);
      close(new HGoto());
      avoidCriticalEdge.addSuccessor(loopEntryBlock); // The back-edge.

      conditionExpression =
          new SubExpression(conditionBlock, conditionEndBlock);

      // Avoid a critical edge from the condition to the loop-exit body.
      HBasicBlock conditionExitBlock = addNewBlock();
      open(conditionExitBlock);
      close(new HGoto());
      conditionEndBlock.addSuccessor(conditionExitBlock);

      endLoop(loopEntryBlock, conditionExitBlock, jumpHandler, localsHandler);

      loopEntryBlock.postProcessLoopHeader();
      SubGraph bodyGraph = new SubGraph(loopEntryBlock, bodyExitBlock);
      HLoopBlockInformation loopBlockInfo =
          new HLoopBlockInformation(
              HLoopBlockInformation.DO_WHILE_LOOP,
              null,
              wrapExpressionGraph(conditionExpression),
              wrapStatementGraph(bodyGraph),
              null,
              loopEntryBlock.loopInformation.target,
              loopEntryBlock.loopInformation.labels,
              sourceInformationBuilder.buildLoop(node));
      loopEntryBlock.setBlockFlow(loopBlockInfo, current);
      loopInfo.loopBlockInformation = loopBlockInfo;
    } else {
      // Since the loop has no back edge, we remove the loop information on the
      // header.
      loopEntryBlock.loopInformation = null;

      if (jumpHandler.hasAnyBreak()) {
        // Null branchBlock because the body of the do-while loop always aborts,
        // so we never get to the condition.
        endLoop(loopEntryBlock, null, jumpHandler, localsHandler);

        // Since the body of the loop has a break, we attach a synthesized label
        // to the body.
        SubGraph bodyGraph = new SubGraph(bodyEntryBlock, bodyExitBlock);
        JumpTarget target = elements.getTargetDefinition(node);
        LabelDefinition label = target.addLabel(null, 'loop');
        label.setBreakTarget();
        HLabeledBlockInformation info = new HLabeledBlockInformation(
            new HSubGraphBlockInformation(bodyGraph), <LabelDefinition>[label]);
        loopEntryBlock.setBlockFlow(info, current);
        jumpHandler.forEachBreak((HBreak breakInstruction, _) {
          HBasicBlock block = breakInstruction.block;
          block.addAtExit(new HBreak.toLabel(label));
          block.remove(breakInstruction);
        });
      }
    }
    jumpHandler.close();
    loopNesting--;
  }

  visitFunctionExpression(ast.FunctionExpression node) {
    ClosureClassMap nestedClosureData =
        compiler.closureToClassMapper.getMappingForNestedFunction(node);
    assert(nestedClosureData != null);
    assert(nestedClosureData.closureClassElement != null);
    ClosureClassElement closureClassElement =
        nestedClosureData.closureClassElement;
    FunctionElement callElement = nestedClosureData.callElement;
    // TODO(ahe): This should be registered in codegen, not here.
    // TODO(johnniwinther): Is [registerStaticUse] equivalent to
    // [addToWorkList]?
    registry?.registerStaticUse(new StaticUse.foreignUse(callElement));

    List<HInstruction> capturedVariables = <HInstruction>[];
    closureClassElement.closureFields.forEach((ClosureFieldElement field) {
      Local capturedLocal =
          nestedClosureData.getLocalVariableForClosureField(field);
      assert(capturedLocal != null);
      capturedVariables.add(localsHandler.readLocal(capturedLocal));
    });

    TypeMask type =
        new TypeMask.nonNullExact(closureClassElement, compiler.world);
    push(new HForeignNew(closureClassElement, type, capturedVariables)
        ..sourceInformation = sourceInformationBuilder.buildCreate(node));

    Element methodElement = nestedClosureData.closureElement;
    registry?.registerInstantiatedClosure(methodElement);
  }

  visitFunctionDeclaration(ast.FunctionDeclaration node) {
    assert(isReachable);
    visit(node.function);
    LocalFunctionElement localFunction =
        elements.getFunctionDefinition(node.function);
    localsHandler.updateLocal(localFunction, pop());
  }

  @override
  void visitThisGet(ast.Identifier node, [_]) {
    stack.add(localsHandler.readThis());
  }

  visitIdentifier(ast.Identifier node) {
    if (node.isThis()) {
      visitThisGet(node);
    } else {
      reporter.internalError(node,
          "SsaFromAstMixin.visitIdentifier on non-this.");
    }
  }

  visitIf(ast.If node) {
    assert(isReachable);
    handleIf(
        node,
        visitCondition: () => visit(node.condition),
        visitThen: () => visit(node.thenPart),
        visitElse: node.elsePart != null ? () => visit(node.elsePart) : null,
        sourceInformation: sourceInformationBuilder.buildIf(node));
  }

  void handleIf(ast.Node diagnosticNode,
                {void visitCondition(),
                 void visitThen(),
                 void visitElse(),
                 SourceInformation sourceInformation}) {
    SsaBranchBuilder branchBuilder = new SsaBranchBuilder(this, diagnosticNode);
    branchBuilder.handleIf(
        visitCondition, visitThen, visitElse,
        sourceInformation: sourceInformation);
  }

  @override
  void visitIfNull(ast.Send node, ast.Node left, ast.Node right, _) {
    SsaBranchBuilder brancher = new SsaBranchBuilder(this, node);
    brancher.handleIfNull(() => visit(left), () => visit(right));
  }

  @override
  void visitLogicalAnd(ast.Send node, ast.Node left, ast.Node right, _) {
    SsaBranchBuilder branchBuilder = new SsaBranchBuilder(this, node);
    branchBuilder.handleLogicalAndOrWithLeftNode(
        left,
        () { visit(right); },
        isAnd: true);
  }

  @override
  void visitLogicalOr(ast.Send node, ast.Node left, ast.Node right, _) {
    SsaBranchBuilder branchBuilder = new SsaBranchBuilder(this, node);
    branchBuilder.handleLogicalAndOrWithLeftNode(
        left,
        () { visit(right); },
        isAnd: false);
  }

  @override
  void visitNot(ast.Send node, ast.Node expression, _) {
    assert(node.argumentsNode is ast.Prefix);
    visit(expression);
    SourceInformation sourceInformation =
        sourceInformationBuilder.buildGeneric(node);
    push(new HNot(popBoolified(), backend.boolType)
        ..sourceInformation = sourceInformation);
  }

  @override
  void visitUnary(ast.Send node,
                  UnaryOperator operator,
                  ast.Node expression,_) {
    assert(node.argumentsNode is ast.Prefix);
    HInstruction operand = visitAndPop(expression);

    // See if we can constant-fold right away. This avoids rewrites later on.
    if (operand is HConstant) {
      UnaryOperation operation = constantSystem.lookupUnary(operator);
      HConstant constant = operand;
      ConstantValue folded = operation.fold(constant.constant);
      if (folded != null) {
        stack.add(graph.addConstant(folded, compiler));
        return;
      }
    }

    pushInvokeDynamic(
        node,
        elements.getSelector(node),
        elements.getTypeMask(node),
        [operand],
        sourceInformation: sourceInformationBuilder.buildGeneric(node));
  }

  @override
  void visitBinary(ast.Send node,
                   ast.Node left,
                   BinaryOperator operator,
                   ast.Node right, _) {
    handleBinary(node, left, right);
  }

  @override
  void visitIndex(ast.Send node, ast.Node receiver, ast.Node index, _) {
    generateDynamicSend(node);
  }

  @override
  void visitEquals(ast.Send node, ast.Node left, ast.Node right, _) {
    handleBinary(node, left, right);
  }

  @override
  void visitNotEquals(ast.Send node, ast.Node left, ast.Node right, _) {
    handleBinary(node, left, right);
    pushWithPosition(new HNot(popBoolified(), backend.boolType), node.selector);
  }

  void handleBinary(ast.Send node, ast.Node left, ast.Node right) {
    visitBinarySend(
        visitAndPop(left),
        visitAndPop(right),
        elements.getSelector(node),
        elements.getTypeMask(node),
        node,
        sourceInformation:
            sourceInformationBuilder.buildGeneric(node.selector));
  }

  /// TODO(johnniwinther): Merge [visitBinarySend] with [handleBinary] and
  /// remove use of [location] for source information.
  void visitBinarySend(HInstruction left,
                       HInstruction right,
                       Selector selector,
                       TypeMask mask,
                       ast.Send send,
                       {SourceInformation sourceInformation}) {
    pushInvokeDynamic(send, selector, mask, [left, right],
        sourceInformation: sourceInformation);
  }

  HInstruction generateInstanceSendReceiver(ast.Send send) {
    assert(Elements.isInstanceSend(send, elements));
    if (send.receiver == null) {
      return localsHandler.readThis();
    }
    visit(send.receiver);
    return pop();
  }

  String noSuchMethodTargetSymbolString(Element error, [String prefix]) {
    String result = error.name;
    if (prefix == "set") return "$result=";
    return result;
  }

  /**
   * Returns a set of interceptor classes that contain the given
   * [selector].
   */
  void generateInstanceGetterWithCompiledReceiver(
      ast.Send send,
      Selector selector,
      TypeMask mask,
      HInstruction receiver) {
    assert(Elements.isInstanceSend(send, elements));
    assert(selector.isGetter);
    pushInvokeDynamic(send, selector, mask, [receiver],
        sourceInformation: sourceInformationBuilder.buildGet(send));
  }

  /// Inserts a call to checkDeferredIsLoaded for [prefixElement].
  /// If [prefixElement] is [null] ndo nothing.
  void generateIsDeferredLoadedCheckIfNeeded(PrefixElement prefixElement,
                                             ast.Node location) {
    if (prefixElement == null) return;
    String loadId =
        compiler.deferredLoadTask.getImportDeferName(location, prefixElement);
    HInstruction loadIdConstant = addConstantString(loadId);
    String uri = prefixElement.deferredImport.uri.toString();
    HInstruction uriConstant = addConstantString(uri);
    Element helper = helpers.checkDeferredIsLoaded;
    pushInvokeStatic(location, helper, [loadIdConstant, uriConstant]);
    pop();
  }

  /// Inserts a call to checkDeferredIsLoaded if the send has a prefix that
  /// resolves to a deferred library.
  void generateIsDeferredLoadedCheckOfSend(ast.Send node) {
    generateIsDeferredLoadedCheckIfNeeded(
        compiler.deferredLoadTask.deferredPrefixElement(node, elements),
        node);
  }

  void handleInvalidStaticGet(ast.Send node, Element element) {
    SourceInformation sourceInformation =
        sourceInformationBuilder.buildGet(node);
    generateThrowNoSuchMethod(
        node,
        noSuchMethodTargetSymbolString(element, 'get'),
        argumentNodes: const Link<ast.Node>(),
        sourceInformation: sourceInformation);
  }

  /// Generate read access of an unresolved static or top level entity.
  void generateStaticUnresolvedGet(ast.Send node, Element element) {
    if (element is ErroneousElement) {
      SourceInformation sourceInformation =
          sourceInformationBuilder.buildGet(node);
      // An erroneous element indicates an unresolved static getter.
      handleInvalidStaticGet(node, element);
    } else {
      // This happens when [element] has parse errors.
      assert(invariant(node, element == null || element.isMalformed));
      // TODO(ahe): Do something like the above, that is, emit a runtime
      // error.
      stack.add(graph.addConstantNull(compiler));
    }
  }

  /// Read a static or top level [field] of constant value.
  void generateStaticConstGet(
      ast.Send node,
      FieldElement field,
      ConstantExpression constant,
      SourceInformation sourceInformation) {
    ConstantValue value = backend.constants.getConstantValue(constant);
    HConstant instruction;
    // Constants that are referred via a deferred prefix should be referred
    // by reference.
    PrefixElement prefix = compiler.deferredLoadTask
        .deferredPrefixElement(node, elements);
    if (prefix != null) {
      instruction =
          graph.addDeferredConstant(value, prefix, sourceInformation, compiler);
    } else {
      instruction = graph.addConstant(
          value, compiler, sourceInformation: sourceInformation);
    }
    stack.add(instruction);
    // The inferrer may have found a better type than the constant
    // handler in the case of lists, because the constant handler
    // does not look at elements in the list.
    TypeMask type =
        TypeMaskFactory.inferredTypeForElement(field, compiler);
    if (!type.containsAll(compiler.world) &&
        !instruction.isConstantNull()) {
      // TODO(13429): The inferrer should know that an element
      // cannot be null.
      instruction.instructionType = type.nonNullable();
    }
  }

  @override
  void previsitDeferredAccess(ast.Send node, PrefixElement prefix, _) {
    generateIsDeferredLoadedCheckIfNeeded(prefix, node);
  }

  /// Read a static or top level [field].
  void generateStaticFieldGet(ast.Send node, FieldElement field) {
    ConstantExpression constant =
        backend.constants.getConstantForVariable(field);
    SourceInformation sourceInformation =
        sourceInformationBuilder.buildGet(node);
    if (constant != null) {
      if (!field.isAssignable) {
        // A static final or const. Get its constant value and inline it if
        // the value can be compiled eagerly.
        generateStaticConstGet(node, field, constant, sourceInformation);
      } else {
        // TODO(5346): Try to avoid the need for calling [declaration] before
        // creating an [HStatic].
        HInstruction instruction = new HStatic(
            field.declaration,
            TypeMaskFactory.inferredTypeForElement(field, compiler))
                ..sourceInformation = sourceInformation;
        push(instruction);
      }
    } else {
      HInstruction instruction = new HLazyStatic(
          field,
          TypeMaskFactory.inferredTypeForElement(field, compiler))
              ..sourceInformation = sourceInformation;
      push(instruction);
    }
  }

  /// Generate a getter invocation of the static or top level [getter].
  void generateStaticGetterGet(ast.Send node, MethodElement getter) {
    SourceInformation sourceInformation =
        sourceInformationBuilder.buildGet(node);
    if (getter.isDeferredLoaderGetter) {
      generateDeferredLoaderGet(node, getter, sourceInformation);
    } else {
      pushInvokeStatic(node, getter, <HInstruction>[],
                       sourceInformation: sourceInformation);
    }
  }

  /// Generate a dynamic getter invocation.
  void generateDynamicGet(ast.Send node) {
    HInstruction receiver = generateInstanceSendReceiver(node);
    generateInstanceGetterWithCompiledReceiver(
        node, elements.getSelector(node), elements.getTypeMask(node), receiver);
  }

  /// Generate a closurization of the static or top level [function].
  void generateStaticFunctionGet(ast.Send node, MethodElement function) {
    // TODO(5346): Try to avoid the need for calling [declaration] before
    // creating an [HStatic].
    SourceInformation sourceInformation =
        sourceInformationBuilder.buildGet(node);
    push(new HStatic(function.declaration, backend.nonNullType)
        ..sourceInformation = sourceInformation);
  }

  /// Read a local variable, function or parameter.
  void buildLocalGet(LocalElement local, SourceInformation sourceInformation) {
    stack.add(localsHandler.readLocal(
              local, sourceInformation: sourceInformation));
  }

  void handleLocalGet(ast.Send node, LocalElement local) {
    buildLocalGet(local, sourceInformationBuilder.buildGet(node));
  }

  @override
  void visitDynamicPropertyGet(
      ast.Send node,
      ast.Node receiver,
      Name name,
      _) {
    generateDynamicGet(node);
  }

  @override
  void visitIfNotNullDynamicPropertyGet(
      ast.Send node,
      ast.Node receiver,
      Name name,
      _) {
    // exp?.x compiled as:
    //   t1 = exp;
    //   result = t1 == null ? t1 : t1.x;
    // This is equivalent to t1 == null ? null : t1.x, but in the current form
    // we will be able to later compress it as:
    //   t1 || t1.x
    HInstruction expression;
    SsaBranchBuilder brancher = new SsaBranchBuilder(this, node);
    brancher.handleConditional(
        () {
          expression = visitAndPop(receiver);
          pushCheckNull(expression);
        },
        () => stack.add(expression),
        () {
          generateInstanceGetterWithCompiledReceiver(
              node,
              elements.getSelector(node),
              elements.getTypeMask(node),
              expression);
        });
  }

  /// Pushes a boolean checking [expression] against null.
  pushCheckNull(HInstruction expression) {
    push(new HIdentity(expression, graph.addConstantNull(compiler),
          null, backend.boolType));
  }

  @override
  void visitLocalVariableGet(ast.Send node, LocalVariableElement variable, _) {
    handleLocalGet(node, variable);
  }

  @override
  void visitParameterGet(ast.Send node, ParameterElement parameter, _) {
    handleLocalGet(node, parameter);
  }

  @override
  void visitLocalFunctionGet(ast.Send node, LocalFunctionElement function, _) {
    handleLocalGet(node, function);
  }

  @override
  void visitStaticFieldGet(
      ast.Send node,
      FieldElement field,
      _) {
    generateStaticFieldGet(node, field);
  }

  @override
  void visitStaticFunctionGet(
      ast.Send node,
      MethodElement function,
      _) {
    generateStaticFunctionGet(node, function);
  }

  @override
  void visitStaticGetterGet(
      ast.Send node,
      FunctionElement getter,
      _) {
    generateStaticGetterGet(node, getter);
  }

  @override
  void visitThisPropertyGet(
      ast.Send node,
      Name name,
      _) {
    generateDynamicGet(node);
  }

  @override
  void visitTopLevelFieldGet(
      ast.Send node,
      FieldElement field,
      _) {
    generateStaticFieldGet(node, field);
  }

  @override
  void visitTopLevelFunctionGet(
      ast.Send node,
      MethodElement function,
      _) {
    generateStaticFunctionGet(node, function);
  }

  @override
  void visitTopLevelGetterGet(
      ast.Send node,
      FunctionElement getter,
      _) {
    generateStaticGetterGet(node, getter);
  }

  void generateInstanceSetterWithCompiledReceiver(ast.Send send,
                                                  HInstruction receiver,
                                                  HInstruction value,
                                                  {Selector selector,
                                                   TypeMask mask,
                                                   ast.Node location}) {
    assert(invariant(
        send == null ? location : send,
        send == null || Elements.isInstanceSend(send, elements),
        message: "Unexpected instance setter"
                 "${send != null ? " element: ${elements[send]}" : ""}"));
    if (selector == null) {
      assert(send != null);
      selector = elements.getSelector(send);
      if (mask == null) {
        mask = elements.getTypeMask(send);
      }
    }
    if (location == null) {
      assert(send != null);
      location = send;
    }
    assert(selector.isSetter);
    pushInvokeDynamic(location, selector, mask, [receiver, value],
        sourceInformation: sourceInformationBuilder.buildAssignment(location));
    pop();
    stack.add(value);
  }

  void generateNoSuchSetter(ast.Node location,
                            Element element,
                            HInstruction value) {
    List<HInstruction> arguments =
        value == null ? const <HInstruction>[] : <HInstruction>[value];
    // An erroneous element indicates an unresolved static setter.
    generateThrowNoSuchMethod(
        location, noSuchMethodTargetSymbolString(element, 'set'),
        argumentValues: arguments);
  }

  void generateNonInstanceSetter(ast.SendSet send,
                                 Element element,
                                 HInstruction value,
                                 {ast.Node location}) {
    if (location == null) {
      assert(send != null);
      location = send;
    }
    assert(invariant(location,
        send == null || !Elements.isInstanceSend(send, elements),
        message: "Unexpected non instance setter: $element."));
    if (Elements.isStaticOrTopLevelField(element)) {
      if (element.isSetter) {
        pushInvokeStatic(location, element, <HInstruction>[value]);
        pop();
      } else {
        VariableElement field = element;
        value = potentiallyCheckOrTrustType(value, field.type);
        addWithPosition(new HStaticStore(element, value), location);
      }
      stack.add(value);
    } else if (Elements.isError(element)) {
      generateNoSuchSetter(location, element,  send == null ? null : value);
    } else if (Elements.isMalformed(element)) {
      // TODO(ahe): Do something like [generateWrongArgumentCountError].
      stack.add(graph.addConstantNull(compiler));
    } else {
      stack.add(value);
      LocalElement local = element;
      // If the value does not already have a name, give it here.
      if (value.sourceElement == null) {
        value.sourceElement = local;
      }
      HInstruction checkedOrTrusted =
          potentiallyCheckOrTrustType(value, local.type);
      if (!identical(checkedOrTrusted, value)) {
        pop();
        stack.add(checkedOrTrusted);
      }

      localsHandler.updateLocal(local, checkedOrTrusted,
          sourceInformation:
              sourceInformationBuilder.buildAssignment(location));
    }
  }

  HInstruction invokeInterceptor(HInstruction receiver) {
    HInterceptor interceptor = new HInterceptor(receiver, backend.nonNullType);
    add(interceptor);
    return interceptor;
  }

  HLiteralList buildLiteralList(List<HInstruction> inputs) {
    return new HLiteralList(inputs, backend.extendableArrayType);
  }

  // TODO(karlklose): change construction of the representations to be GVN'able
  // (dartbug.com/7182).
  HInstruction buildTypeArgumentRepresentations(DartType type) {
    // Compute the representation of the type arguments, including access
    // to the runtime type information for type variables as instructions.
    if (type.isTypeVariable) {
      return buildLiteralList(<HInstruction>[addTypeVariableReference(type)]);
    } else {
      assert(type.element.isClass);
      InterfaceType interface = type;
      List<HInstruction> inputs = <HInstruction>[];
      List<js.Expression> templates = <js.Expression>[];
      for (DartType argument in interface.typeArguments) {
        // As we construct the template in stages, we have to make sure that for
        // each part the generated sub-template's holes match the index of the
        // inputs that are later used to instantiate it. We do this by starting
        // the indexing with the number of inputs from previous sub-templates.
        templates.add(
            rtiEncoder.getTypeRepresentationWithPlaceholders(
                argument, (variable) {
              HInstruction runtimeType = addTypeVariableReference(variable);
              inputs.add(runtimeType);
            }, firstPlaceholderIndex: inputs.length));
      }
      // TODO(sra): This is a fresh template each time.  We can't let the
      // template manager build them.
      js.Template code = new js.Template(null,
                                         new js.ArrayInitializer(templates));
      HInstruction representation =
          new HForeignCode(code, backend.readableArrayType, inputs,
              nativeBehavior: native.NativeBehavior.PURE_ALLOCATION);
      return representation;
    }
  }

  @override
  void visitAs(ast.Send node, ast.Node expression, DartType type, _) {
    HInstruction expressionInstruction = visitAndPop(expression);
    if (type.isMalformed) {
      ErroneousElement element = type.element;
      generateTypeError(node, element.message);
    } else {
      HInstruction converted = buildTypeConversion(
          expressionInstruction,
          localsHandler.substInContext(type),
          HTypeConversion.CAST_TYPE_CHECK);
      if (converted != expressionInstruction) add(converted);
      stack.add(converted);
    }
  }

  @override
  void visitIs(ast.Send node, ast.Node expression, DartType type, _) {
    HInstruction expressionInstruction = visitAndPop(expression);
    push(buildIsNode(node, type, expressionInstruction));
  }

  @override
  void visitIsNot(ast.Send node, ast.Node expression, DartType type, _) {
    HInstruction expressionInstruction = visitAndPop(expression);
    HInstruction instruction = buildIsNode(node, type, expressionInstruction);
    add(instruction);
    push(new HNot(instruction, backend.boolType));
  }

  HInstruction buildIsNode(ast.Node node,
                           DartType type,
                           HInstruction expression) {
    type = localsHandler.substInContext(type).unaliased;
    if (type.isFunctionType) {
      List arguments = [buildFunctionType(type), expression];
      pushInvokeDynamic(
          node,
          new Selector.call(
              new PrivateName('_isTest', helpers.jsHelperLibrary),
              CallStructure.ONE_ARG),
          null,
          arguments);
      return new HIs.compound(type, expression, pop(), backend.boolType);
    } else if (type.isTypeVariable) {
      HInstruction runtimeType = addTypeVariableReference(type);
      Element helper = helpers.checkSubtypeOfRuntimeType;
      List<HInstruction> inputs = <HInstruction>[expression, runtimeType];
      pushInvokeStatic(null, helper, inputs, typeMask: backend.boolType);
      HInstruction call = pop();
      return new HIs.variable(type, expression, call, backend.boolType);
    } else if (RuntimeTypes.hasTypeArguments(type)) {
      ClassElement element = type.element;
      Element helper = helpers.checkSubtype;
      HInstruction representations =
          buildTypeArgumentRepresentations(type);
      add(representations);
      js.Name operator = backend.namer.operatorIs(element);
      HInstruction isFieldName = addConstantStringFromName(operator);
      HInstruction asFieldName = compiler.world.hasAnyStrictSubtype(element)
          ? addConstantStringFromName(backend.namer.substitutionName(element))
          : graph.addConstantNull(compiler);
      List<HInstruction> inputs = <HInstruction>[expression,
                                                 isFieldName,
                                                 representations,
                                                 asFieldName];
      pushInvokeStatic(node, helper, inputs, typeMask: backend.boolType);
      HInstruction call = pop();
      return new HIs.compound(type, expression, call, backend.boolType);
    } else if (type.isMalformed) {
      ErroneousElement element = type.element;
      generateTypeError(node, element.message);
      HInstruction call = pop();
      return new HIs.compound(type, expression, call, backend.boolType);
    } else {
      if (backend.hasDirectCheckFor(type)) {
        return new HIs.direct(type, expression, backend.boolType);
      }
      // The interceptor is not always needed.  It is removed by optimization
      // when the receiver type or tested type permit.
      return new HIs.raw(
          type, expression, invokeInterceptor(expression), backend.boolType);
    }
  }

  HInstruction buildFunctionType(FunctionType type) {
    type.accept(new TypeBuilder(compiler.world), this);
    return pop();
  }

  void addDynamicSendArgumentsToList(ast.Send node, List<HInstruction> list) {
    CallStructure callStructure = elements.getSelector(node).callStructure;
    if (callStructure.namedArgumentCount == 0) {
      addGenericSendArgumentsToList(node.arguments, list);
    } else {
      // Visit positional arguments and add them to the list.
      Link<ast.Node> arguments = node.arguments;
      int positionalArgumentCount = callStructure.positionalArgumentCount;
      for (int i = 0;
           i < positionalArgumentCount;
           arguments = arguments.tail, i++) {
        visit(arguments.head);
        list.add(pop());
      }

      // Visit named arguments and add them into a temporary map.
      Map<String, HInstruction> instructions =
          new Map<String, HInstruction>();
      List<String> namedArguments = callStructure.namedArguments;
      int nameIndex = 0;
      for (; !arguments.isEmpty; arguments = arguments.tail) {
        visit(arguments.head);
        instructions[namedArguments[nameIndex++]] = pop();
      }

      // Iterate through the named arguments to add them to the list
      // of instructions, in an order that can be shared with
      // selectors with the same named arguments.
      List<String> orderedNames = callStructure.getOrderedNamedArguments();
      for (String name in orderedNames) {
        list.add(instructions[name]);
      }
    }
  }

  /**
   * Returns a list with the evaluated [arguments] in the normalized order.
   *
   * Precondition: `this.applies(element, world)`.
   * Invariant: [element] must be an implementation element.
   */
  List<HInstruction> makeStaticArgumentList(CallStructure callStructure,
                                            Link<ast.Node> arguments,
                                            FunctionElement element) {
    assert(invariant(element, element.isImplementation));

    HInstruction compileArgument(ast.Node argument) {
      visit(argument);
      return pop();
    }

    return callStructure.makeArgumentsList(
        arguments,
        element,
        compileArgument,
        backend.isJsInterop(element) ?
            handleConstantForOptionalParameterJsInterop :
            handleConstantForOptionalParameter);
  }

  void addGenericSendArgumentsToList(Link<ast.Node> link, List<HInstruction> list) {
    for (; !link.isEmpty; link = link.tail) {
      visit(link.head);
      list.add(pop());
    }
  }

  /// Generate a dynamic method, getter or setter invocation.
  void generateDynamicSend(ast.Send node) {
    HInstruction receiver = generateInstanceSendReceiver(node);
    _generateDynamicSend(node, receiver);
  }

  void _generateDynamicSend(ast.Send node, HInstruction receiver) {
    Selector selector = elements.getSelector(node);
    TypeMask mask = elements.getTypeMask(node);
    SourceInformation sourceInformation =
        sourceInformationBuilder.buildCall(node, node.selector);

    List<HInstruction> inputs = <HInstruction>[];
    inputs.add(receiver);
    addDynamicSendArgumentsToList(node, inputs);

    pushInvokeDynamic(node, selector, mask, inputs,
                      sourceInformation: sourceInformation);
    if (selector.isSetter || selector.isIndexSet) {
      pop();
      stack.add(inputs.last);
    }
  }

  @override
  visitDynamicPropertyInvoke(
      ast.Send node,
      ast.Node receiver,
      ast.NodeList arguments,
      Selector selector,
      _) {
    generateDynamicSend(node);
  }

  @override
  visitIfNotNullDynamicPropertyInvoke(
      ast.Send node,
      ast.Node receiver,
      ast.NodeList arguments,
      Selector selector,
      _) {
    /// Desugar `exp?.m()` to `(t1 = exp) == null ? t1 : t1.m()`
    HInstruction receiver;
    SsaBranchBuilder brancher = new SsaBranchBuilder(this, node);
    brancher.handleConditional(
        () {
          receiver = generateInstanceSendReceiver(node);
          pushCheckNull(receiver);
        },
        () => stack.add(receiver),
        () => _generateDynamicSend(node, receiver));
  }

  @override
  visitThisPropertyInvoke(
      ast.Send node,
      ast.NodeList arguments,
      Selector selector,
      _) {
    generateDynamicSend(node);
  }

  @override
  visitExpressionInvoke(
      ast.Send node,
      ast.Node expression,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    generateCallInvoke(
        node,
        visitAndPop(expression),
        sourceInformationBuilder.buildCall(node, node.argumentsNode));
  }

  @override
  visitThisInvoke(
      ast.Send node,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    generateCallInvoke(
        node,
        localsHandler.readThis(),
        sourceInformationBuilder.buildCall(node, node.argumentsNode));
  }

  @override
  visitParameterInvoke(
      ast.Send node,
      ParameterElement parameter,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    generateCallInvoke(
        node,
            localsHandler.readLocal(parameter),
        sourceInformationBuilder.buildCall(node, node.argumentsNode));
  }

  @override
  visitLocalVariableInvoke(
      ast.Send node,
      LocalVariableElement variable,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    generateCallInvoke(
        node,
        localsHandler.readLocal(variable),
        sourceInformationBuilder.buildCall(node, node.argumentsNode));
  }

  @override
  visitLocalFunctionInvoke(
      ast.Send node,
      LocalFunctionElement function,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    generateCallInvoke(
        node,
        localsHandler.readLocal(function),
        sourceInformationBuilder.buildCall(node, node.argumentsNode));
  }

  @override
  visitLocalFunctionIncompatibleInvoke(
      ast.Send node,
      LocalFunctionElement function,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    generateCallInvoke(node, localsHandler.readLocal(function),
        sourceInformationBuilder.buildCall(node, node.argumentsNode));
  }

  void handleForeignJs(ast.Send node) {
    Link<ast.Node> link = node.arguments;
    // Don't visit the first argument, which is the type, and the second
    // argument, which is the foreign code.
    if (link.isEmpty || link.tail.isEmpty) {
      // We should not get here because the call should be compiled to NSM.
      reporter.internalError(node.argumentsNode,
          'At least two arguments expected.');
    }
    native.NativeBehavior nativeBehavior =
        compiler.enqueuer.resolution.nativeEnqueuer.getNativeBehaviorOf(node);

    List<HInstruction> inputs = <HInstruction>[];
    addGenericSendArgumentsToList(link.tail.tail, inputs);

    if (nativeBehavior.codeTemplate.positionalArgumentCount != inputs.length) {
      reporter.reportErrorMessage(
          node, MessageKind.GENERIC,
          {'text':
            'Mismatch between number of placeholders'
            ' and number of arguments.'});
      stack.add(graph.addConstantNull(compiler));  // Result expected on stack.
      return;
    }

    if (native.HasCapturedPlaceholders.check(nativeBehavior.codeTemplate.ast)) {
      reporter.reportErrorMessage(node, MessageKind.JS_PLACEHOLDER_CAPTURE);
    }

    TypeMask ssaType =
        TypeMaskFactory.fromNativeBehavior(nativeBehavior, compiler);

    SourceInformation sourceInformation =
        sourceInformationBuilder.buildCall(node, node.argumentsNode);
    if (nativeBehavior.codeTemplate.isExpression) {
      push(new HForeignCode(
          nativeBehavior.codeTemplate, ssaType, inputs,
          effects: nativeBehavior.sideEffects,
          nativeBehavior: nativeBehavior)
              ..sourceInformation = sourceInformation);
    } else {
      push(new HForeignCode(
          nativeBehavior.codeTemplate, ssaType, inputs,
          isStatement: true,
          effects: nativeBehavior.sideEffects,
          nativeBehavior: nativeBehavior)
              ..sourceInformation = sourceInformation);
    }
  }

  void handleJsStringConcat(ast.Send node) {
    List<HInstruction> inputs = <HInstruction>[];
    addGenericSendArgumentsToList(node.arguments, inputs);
    if (inputs.length != 2) {
      reporter.internalError(node.argumentsNode, 'Two arguments expected.');
    }
    push(new HStringConcat(inputs[0], inputs[1], node, backend.stringType));
  }

  void handleForeignJsCurrentIsolateContext(ast.Send node) {
    if (!node.arguments.isEmpty) {
      reporter.internalError(node,
          'Too many arguments to JS_CURRENT_ISOLATE_CONTEXT.');
    }

    if (!compiler.hasIsolateSupport) {
      // If the isolate library is not used, we just generate code
      // to fetch the static state.
      String name = backend.namer.staticStateHolder;
      push(new HForeignCode(
          js.js.parseForeignJS(name),
          backend.dynamicType,
          <HInstruction>[],
          nativeBehavior: native.NativeBehavior.DEPENDS_OTHER));
    } else {
      // Call a helper method from the isolate library. The isolate
      // library uses its own isolate structure, that encapsulates
      // Leg's isolate.
      Element element = helpers.currentIsolate;
      if (element == null) {
        reporter.internalError(node,
            'Isolate library and compiler mismatch.');
      }
      pushInvokeStatic(null, element, [], typeMask: backend.dynamicType);
    }
  }

  void handleForeignJsGetFlag(ast.Send node) {
    List<ast.Node> arguments = node.arguments.toList();
     ast.Node argument;
     switch (arguments.length) {
     case 0:
       reporter.reportErrorMessage(
           node, MessageKind.GENERIC,
           {'text': 'Error: Expected one argument to JS_GET_FLAG.'});
       return;
     case 1:
       argument = arguments[0];
       break;
     default:
       for (int i = 1; i < arguments.length; i++) {
         reporter.reportErrorMessage(
             arguments[i], MessageKind.GENERIC,
             {'text': 'Error: Extra argument to JS_GET_FLAG.'});
       }
       return;
     }
     ast.LiteralString string = argument.asLiteralString();
     if (string == null) {
       reporter.reportErrorMessage(
           argument, MessageKind.GENERIC,
           {'text': 'Error: Expected a literal string.'});
     }
     String name = string.dartString.slowToString();
     bool value = false;
     switch (name) {
       case 'MUST_RETAIN_METADATA':
         value = backend.mustRetainMetadata;
         break;
       case 'USE_CONTENT_SECURITY_POLICY':
         value = compiler.useContentSecurityPolicy;
         break;
       default:
         reporter.reportErrorMessage(
             node, MessageKind.GENERIC,
             {'text': 'Error: Unknown internal flag "$name".'});
     }
     stack.add(graph.addConstantBool(value, compiler));
  }

  void handleForeignJsGetName(ast.Send node) {
    List<ast.Node> arguments = node.arguments.toList();
    ast.Node argument;
    switch (arguments.length) {
    case 0:
      reporter.reportErrorMessage(
          node, MessageKind.GENERIC,
          {'text': 'Error: Expected one argument to JS_GET_NAME.'});
      return;
    case 1:
      argument = arguments[0];
      break;
    default:
      for (int i = 1; i < arguments.length; i++) {
        reporter.reportErrorMessage(
            arguments[i], MessageKind.GENERIC,
            {'text': 'Error: Extra argument to JS_GET_NAME.'});
      }
      return;
    }
    Element element = elements[argument];
    if (element == null ||
        element is! FieldElement ||
        element.enclosingClass != helpers.jsGetNameEnum) {
      reporter.reportErrorMessage(
          argument, MessageKind.GENERIC,
          {'text': 'Error: Expected a JsGetName enum value.'});
    }
    EnumClassElement enumClass = element.enclosingClass;
    int index = enumClass.enumValues.indexOf(element);
    stack.add(
        addConstantStringFromName(
            backend.namer.getNameForJsGetName(
                argument, JsGetName.values[index])));
  }

  void handleForeignJsBuiltin(ast.Send node) {
    List<ast.Node> arguments = node.arguments.toList();
    ast.Node argument;
    if (arguments.length < 2) {
      reporter.reportErrorMessage(
          node, MessageKind.GENERIC,
          {'text': 'Error: Expected at least two arguments to JS_BUILTIN.'});
    }

    Element builtinElement = elements[arguments[1]];
    if (builtinElement == null ||
        (builtinElement is! FieldElement) ||
        builtinElement.enclosingClass != helpers.jsBuiltinEnum) {
      reporter.reportErrorMessage(
          argument, MessageKind.GENERIC,
          {'text': 'Error: Expected a JsBuiltin enum value.'});
    }
    EnumClassElement enumClass = builtinElement.enclosingClass;
    int index = enumClass.enumValues.indexOf(builtinElement);

    js.Template template =
        backend.emitter.builtinTemplateFor(JsBuiltin.values[index]);

    List<HInstruction> compiledArguments = <HInstruction>[];
    for (int i = 2; i < arguments.length; i++) {
      visit(arguments[i]);
      compiledArguments.add(pop());
    }

    native.NativeBehavior nativeBehavior =
        compiler.enqueuer.resolution.nativeEnqueuer.getNativeBehaviorOf(node);

    TypeMask ssaType =
        TypeMaskFactory.fromNativeBehavior(nativeBehavior, compiler);

    push(new HForeignCode(template,
                          ssaType,
                          compiledArguments,
                          nativeBehavior: nativeBehavior));
  }

  void handleForeignJsEmbeddedGlobal(ast.Send node) {
    List<ast.Node> arguments = node.arguments.toList();
    ast.Node globalNameNode;
    switch (arguments.length) {
    case 0:
    case 1:
      reporter.reportErrorMessage(
          node, MessageKind.GENERIC,
          {'text': 'Error: Expected two arguments to JS_EMBEDDED_GLOBAL.'});
      return;
    case 2:
      // The type has been extracted earlier. We are only interested in the
      // name in this function.
      globalNameNode = arguments[1];
      break;
    default:
      for (int i = 2; i < arguments.length; i++) {
        reporter.reportErrorMessage(
            arguments[i], MessageKind.GENERIC,
            {'text': 'Error: Extra argument to JS_EMBEDDED_GLOBAL.'});
      }
      return;
    }
    visit(globalNameNode);
    HInstruction globalNameHNode = pop();
    if (!globalNameHNode.isConstantString()) {
      reporter.reportErrorMessage(
          arguments[1], MessageKind.GENERIC,
          {'text': 'Error: Expected String as second argument '
                   'to JS_EMBEDDED_GLOBAL.'});
      return;
    }
    HConstant hConstant = globalNameHNode;
    StringConstantValue constant = hConstant.constant;
    String globalName = constant.primitiveValue.slowToString();
    js.Template expr = js.js.expressionTemplateYielding(
        backend.emitter.generateEmbeddedGlobalAccess(globalName));
    native.NativeBehavior nativeBehavior =
        compiler.enqueuer.resolution.nativeEnqueuer.getNativeBehaviorOf(node);
    TypeMask ssaType =
        TypeMaskFactory.fromNativeBehavior(nativeBehavior, compiler);
    push(new HForeignCode(expr, ssaType, const [],
            nativeBehavior: nativeBehavior));
  }

  void handleJsInterceptorConstant(ast.Send node) {
    // Single argument must be a TypeConstant which is converted into a
    // InterceptorConstant.
    if (!node.arguments.isEmpty && node.arguments.tail.isEmpty) {
      ast.Node argument = node.arguments.head;
      visit(argument);
      HInstruction argumentInstruction = pop();
      if (argumentInstruction is HConstant) {
        ConstantValue argumentConstant = argumentInstruction.constant;
        if (argumentConstant is TypeConstantValue) {
          ConstantValue constant =
              new InterceptorConstantValue(argumentConstant.representedType);
          HInstruction instruction = graph.addConstant(constant, compiler);
          stack.add(instruction);
          return;
        }
      }
    }
    reporter.reportErrorMessage(
        node,
        MessageKind.WRONG_ARGUMENT_FOR_JS_INTERCEPTOR_CONSTANT);
    stack.add(graph.addConstantNull(compiler));
  }

  void handleForeignJsCallInIsolate(ast.Send node) {
    Link<ast.Node> link = node.arguments;
    if (!compiler.hasIsolateSupport) {
      // If the isolate library is not used, we just invoke the
      // closure.
      visit(link.tail.head);
      push(new HInvokeClosure(new Selector.callClosure(0),
                              <HInstruction>[pop()],
                              backend.dynamicType));
    } else {
      // Call a helper method from the isolate library.
      Element element = helpers.callInIsolate;
      if (element == null) {
        reporter.internalError(node,
            'Isolate library and compiler mismatch.');
      }
      List<HInstruction> inputs = <HInstruction>[];
      addGenericSendArgumentsToList(link, inputs);
      pushInvokeStatic(node, element, inputs, typeMask: backend.dynamicType);
    }
  }

  FunctionSignature handleForeignRawFunctionRef(ast.Send node, String name) {
    if (node.arguments.isEmpty || !node.arguments.tail.isEmpty) {
      reporter.internalError(node.argumentsNode,
          '"$name" requires exactly one argument.');
    }
    ast.Node closure = node.arguments.head;
    Element element = elements[closure];
    if (!Elements.isStaticOrTopLevelFunction(element)) {
      reporter.internalError(closure,
          '"$name" requires a static or top-level method.');
    }
    FunctionElement function = element;
    // TODO(johnniwinther): Try to eliminate the need to distinguish declaration
    // and implementation signatures. Currently it is need because the
    // signatures have different elements for parameters.
    FunctionElement implementation = function.implementation;
    FunctionSignature params = implementation.functionSignature;
    if (params.optionalParameterCount != 0) {
      reporter.internalError(closure,
          '"$name" does not handle closure with optional parameters.');
    }

    registry?.registerStaticUse(
        new StaticUse.foreignUse(function));
    push(new HForeignCode(
        js.js.expressionTemplateYielding(
            backend.emitter.staticFunctionAccess(function)),
        backend.dynamicType,
        <HInstruction>[],
        nativeBehavior: native.NativeBehavior.PURE));
    return params;
  }

  void handleForeignDartClosureToJs(ast.Send node, String name) {
    // TODO(ahe): This implements DART_CLOSURE_TO_JS and should probably take
    // care to wrap the closure in another closure that saves the current
    // isolate.
    handleForeignRawFunctionRef(node, name);
  }

  void handleForeignJsSetStaticState(ast.Send node) {
    if (node.arguments.isEmpty || !node.arguments.tail.isEmpty) {
      reporter.internalError(node.argumentsNode,
          'Exactly one argument required.');
    }
    visit(node.arguments.head);
    String isolateName = backend.namer.staticStateHolder;
    SideEffects sideEffects = new SideEffects.empty();
    sideEffects.setAllSideEffects();
    push(new HForeignCode(
        js.js.parseForeignJS("$isolateName = #"),
        backend.dynamicType,
        <HInstruction>[pop()],
        nativeBehavior: native.NativeBehavior.CHANGES_OTHER,
        effects: sideEffects));
  }

  void handleForeignJsGetStaticState(ast.Send node) {
    if (!node.arguments.isEmpty) {
      reporter.internalError(node.argumentsNode, 'Too many arguments.');
    }
    push(new HForeignCode(js.js.parseForeignJS(backend.namer.staticStateHolder),
                          backend.dynamicType,
                          <HInstruction>[],
                          nativeBehavior: native.NativeBehavior.DEPENDS_OTHER));
  }

  void handleForeignSend(ast.Send node, FunctionElement element) {
    String name = element.name;
    if (name == 'JS') {
      handleForeignJs(node);
    } else if (name == 'JS_CURRENT_ISOLATE_CONTEXT') {
      handleForeignJsCurrentIsolateContext(node);
    } else if (name == 'JS_CALL_IN_ISOLATE') {
      handleForeignJsCallInIsolate(node);
    } else if (name == 'DART_CLOSURE_TO_JS') {
      handleForeignDartClosureToJs(node, 'DART_CLOSURE_TO_JS');
    } else if (name == 'RAW_DART_FUNCTION_REF') {
      handleForeignRawFunctionRef(node, 'RAW_DART_FUNCTION_REF');
    } else if (name == 'JS_SET_STATIC_STATE') {
      handleForeignJsSetStaticState(node);
    } else if (name == 'JS_GET_STATIC_STATE') {
      handleForeignJsGetStaticState(node);
    } else if (name == 'JS_GET_NAME') {
      handleForeignJsGetName(node);
    } else if (name == 'JS_EMBEDDED_GLOBAL') {
      handleForeignJsEmbeddedGlobal(node);
    } else if (name == 'JS_BUILTIN') {
      handleForeignJsBuiltin(node);
    } else if (name == 'JS_GET_FLAG') {
      handleForeignJsGetFlag(node);
    } else if (name == 'JS_EFFECT') {
      stack.add(graph.addConstantNull(compiler));
    } else if (name == 'JS_INTERCEPTOR_CONSTANT') {
      handleJsInterceptorConstant(node);
    } else if (name == 'JS_STRING_CONCAT') {
      handleJsStringConcat(node);
    } else {
      reporter.internalError(node, "Unknown foreign: ${element}");
    }
  }

  generateDeferredLoaderGet(ast.Send node,
                            FunctionElement deferredLoader,
                            SourceInformation sourceInformation) {
    // Until now we only handle these as getters.
    invariant(node, deferredLoader.isDeferredLoaderGetter);
    Element loadFunction = compiler.loadLibraryFunction;
    PrefixElement prefixElement = deferredLoader.enclosingElement;
    String loadId =
        compiler.deferredLoadTask.getImportDeferName(node, prefixElement);
    var inputs = [graph.addConstantString(
        new ast.DartString.literal(loadId), compiler)];
    push(new HInvokeStatic(loadFunction, inputs, backend.nonNullType,
                           targetCanThrow: false)
        ..sourceInformation = sourceInformation);
  }

  generateSuperNoSuchMethodSend(ast.Send node,
                                Selector selector,
                                List<HInstruction> arguments) {
    String name = selector.name;

    ClassElement cls = currentNonClosureClass;
    MethodElement element = cls.lookupSuperMember(Identifiers.noSuchMethod_);
    if (!Selectors.noSuchMethod_.signatureApplies(element)) {
      element = coreClasses.objectClass.lookupMember(Identifiers.noSuchMethod_);
    }
    if (compiler.enabledInvokeOn && !element.enclosingClass.isObject) {
      // Register the call as dynamic if [noSuchMethod] on the super
      // class is _not_ the default implementation from [Object], in
      // case the [noSuchMethod] implementation calls
      // [JSInvocationMirror._invokeOn].
      // TODO(johnniwinther): Register this more precisely.
      registry?.registerDynamicUse(new DynamicUse(selector, null));
    }
    String publicName = name;
    if (selector.isSetter) publicName += '=';

    ConstantValue nameConstant = constantSystem.createString(
        new ast.DartString.literal(publicName));

    js.Name internalName = backend.namer.invocationName(selector);

    Element createInvocationMirror = helpers.createInvocationMirror;
    var argumentsInstruction = buildLiteralList(arguments);
    add(argumentsInstruction);

    var argumentNames = new List<HInstruction>();
    for (String argumentName in selector.namedArguments) {
      ConstantValue argumentNameConstant =
          constantSystem.createString(new ast.DartString.literal(argumentName));
      argumentNames.add(graph.addConstant(argumentNameConstant, compiler));
    }
    var argumentNamesInstruction = buildLiteralList(argumentNames);
    add(argumentNamesInstruction);

    ConstantValue kindConstant =
        constantSystem.createInt(selector.invocationMirrorKind);

    pushInvokeStatic(null,
                     createInvocationMirror,
                     [graph.addConstant(nameConstant, compiler),
                      graph.addConstantStringFromName(internalName, compiler),
                      graph.addConstant(kindConstant, compiler),
                      argumentsInstruction,
                      argumentNamesInstruction],
                     typeMask: backend.dynamicType);

    var inputs = <HInstruction>[pop()];
    push(buildInvokeSuper(Selectors.noSuchMethod_, element, inputs));
  }

  /// Generate a call to a super method or constructor.
  void generateSuperInvoke(ast.Send node,
                           FunctionElement function,
                           SourceInformation sourceInformation) {
    // TODO(5347): Try to avoid the need for calling [implementation] before
    // calling [makeStaticArgumentList].
    Selector selector = elements.getSelector(node);
    assert(invariant(node,
        selector.applies(function.implementation, compiler.world),
        message: "$selector does not apply to ${function.implementation}"));
    List<HInstruction> inputs =
        makeStaticArgumentList(selector.callStructure,
                               node.arguments,
                               function.implementation);
    push(buildInvokeSuper(selector, function, inputs, sourceInformation));
  }

  /// Access the value from the super [element].
  void handleSuperGet(ast.Send node, Element element) {
    Selector selector = elements.getSelector(node);
    SourceInformation sourceInformation =
        sourceInformationBuilder.buildGet(node);
    push(buildInvokeSuper(
        selector, element, const <HInstruction>[], sourceInformation));
  }

  /// Invoke .call on the value retrieved from the super [element].
  void handleSuperCallInvoke(ast.Send node, Element element) {
    Selector selector = elements.getSelector(node);
    HInstruction target = buildInvokeSuper(
        selector, element, const <HInstruction>[],
        sourceInformationBuilder.buildGet(node));
    add(target);
    generateCallInvoke(
        node,
        target,
        sourceInformationBuilder.buildCall(node, node.argumentsNode));
  }

  /// Invoke super [method].
  void handleSuperMethodInvoke(
      ast.Send node,
      MethodElement method) {
    generateSuperInvoke(node, method,
        sourceInformationBuilder.buildCall(node, node.selector));
  }

  /// Access an unresolved super property.
  void handleUnresolvedSuperInvoke(ast.Send node) {
    Selector selector = elements.getSelector(node);
    List<HInstruction> arguments = <HInstruction>[];
    if (!node.isPropertyAccess) {
      addGenericSendArgumentsToList(node.arguments, arguments);
    }
    generateSuperNoSuchMethodSend(node, selector, arguments);
  }

  @override
  void visitUnresolvedSuperIndex(
      ast.Send node,
      Element element,
      ast.Node index,
      _) {
    handleUnresolvedSuperInvoke(node);
  }

  @override
  void visitUnresolvedSuperUnary(
      ast.Send node,
      UnaryOperator operator,
      Element element,
      _) {
    handleUnresolvedSuperInvoke(node);
  }

  @override
  void visitUnresolvedSuperBinary(
      ast.Send node,
      Element element,
      BinaryOperator operator,
      ast.Node argument,
      _) {
    handleUnresolvedSuperInvoke(node);
  }

  @override
  void visitUnresolvedSuperGet(
      ast.Send node,
      Element element,
      _) {
    handleUnresolvedSuperInvoke(node);
  }

  @override
  void visitUnresolvedSuperSet(
      ast.Send node,
      Element element,
      ast.Node rhs,
      _) {
    handleSuperSendSet(node);
  }

  @override
  void visitSuperSetterGet(
      ast.Send node,
      MethodElement setter,
      _) {
    handleUnresolvedSuperInvoke(node);
  }

  @override
  void visitUnresolvedSuperInvoke(
      ast.Send node,
      Element element,
      ast.Node argument,
      Selector selector,
      _) {
    handleUnresolvedSuperInvoke(node);
  }

  @override
  void visitSuperFieldGet(
      ast.Send node,
      FieldElement field,
      _) {
    handleSuperGet(node, field);
  }

  @override
  void visitSuperGetterGet(
      ast.Send node,
      MethodElement method,
      _) {
    handleSuperGet(node, method);
  }

  @override
  void visitSuperMethodGet(
      ast.Send node,
      MethodElement method,
      _) {
    handleSuperGet(node, method);
  }

  @override
  void visitSuperFieldInvoke(
      ast.Send node,
      FieldElement field,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    handleSuperCallInvoke(node, field);
  }

  @override
  void visitSuperGetterInvoke(
      ast.Send node,
      MethodElement getter,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    handleSuperCallInvoke(node, getter);
  }

  @override
  void visitSuperMethodInvoke(
      ast.Send node,
      MethodElement method,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    handleSuperMethodInvoke(node, method);
  }

  @override
  void visitSuperIndex(
      ast.Send node,
      MethodElement method,
      ast.Node index,
      _) {
    handleSuperMethodInvoke(node, method);
  }

  @override
  void visitSuperEquals(
      ast.Send node,
      MethodElement method,
      ast.Node argument,
      _) {
    handleSuperMethodInvoke(node, method);
  }

  @override
  void visitSuperBinary(
      ast.Send node,
      MethodElement method,
      BinaryOperator operator,
      ast.Node argument,
      _) {
    handleSuperMethodInvoke(node, method);
  }

  @override
  void visitSuperNotEquals(
      ast.Send node,
      MethodElement method,
      ast.Node argument,
      _) {
    handleSuperMethodInvoke(node, method);
    pushWithPosition(new HNot(popBoolified(), backend.boolType), node.selector);
  }

  @override
  void visitSuperUnary(
      ast.Send node,
      UnaryOperator operator,
      MethodElement method,
      _) {
    handleSuperMethodInvoke(node, method);
  }

  @override
  void visitSuperMethodIncompatibleInvoke(
      ast.Send node,
      MethodElement method,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    handleInvalidSuperInvoke(node, arguments);
  }

  @override
  void visitSuperSetterInvoke(
      ast.Send node,
      SetterElement setter,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    handleInvalidSuperInvoke(node, arguments);
  }

  void handleInvalidSuperInvoke(ast.Send node, ast.NodeList arguments) {
    Selector selector = elements.getSelector(node);
    List<HInstruction> inputs = <HInstruction>[];
    addGenericSendArgumentsToList(arguments.nodes, inputs);
    generateSuperNoSuchMethodSend(node, selector, inputs);
  }

  bool needsSubstitutionForTypeVariableAccess(ClassElement cls) {
    ClassWorld classWorld = compiler.world;
    if (classWorld.isUsedAsMixin(cls)) return true;

    return compiler.world.anyStrictSubclassOf(cls, (ClassElement subclass) {
      return !rti.isTrivialSubstitution(subclass, cls);
    });
  }

  /**
   * Generate code to extract the type arguments from the object, substitute
   * them as an instance of the type we are testing against (if necessary), and
   * extract the type argument by the index of the variable in the list of type
   * variables for that class.
   */
  HInstruction readTypeVariable(
      ClassElement cls,
      TypeVariableElement variable,
      {SourceInformation sourceInformation}) {
    assert(sourceElement.isInstanceMember);

    HInstruction target = localsHandler.readThis();
    HConstant index = graph.addConstantInt(variable.index, compiler);

    if (needsSubstitutionForTypeVariableAccess(cls)) {
      // TODO(ahe): Creating a string here is unfortunate. It is slow (due to
      // string concatenation in the implementation), and may prevent
      // segmentation of '$'.
      js.Name substitutionName = backend.namer.runtimeTypeName(cls);
      HInstruction substitutionNameInstr = graph.addConstantStringFromName(
          substitutionName, compiler);
      pushInvokeStatic(null,
                       helpers.getRuntimeTypeArgument,
                       [target, substitutionNameInstr, index],
                       typeMask: backend.dynamicType,
                       sourceInformation: sourceInformation);
    } else {
      pushInvokeStatic(
          null,
          helpers.getTypeArgumentByIndex,
          [target, index],
          typeMask: backend.dynamicType,
          sourceInformation: sourceInformation);
    }
    return pop();
  }

  // TODO(karlklose): this is needed to avoid a bug where the resolved type is
  // not stored on a type annotation in the closure translator. Remove when
  // fixed.
  bool hasDirectLocal(Local local) {
    return !localsHandler.isAccessedDirectly(local) ||
            localsHandler.directLocals[local] != null;
  }

  /**
   * Helper to create an instruction that gets the value of a type variable.
   */
  HInstruction addTypeVariableReference(
      TypeVariableType type,
      {SourceInformation sourceInformation}) {

    assert(assertTypeInContext(type));
    Element member = sourceElement;
    bool isClosure = member.enclosingElement.isClosure;
    if (isClosure) {
      ClosureClassElement closureClass = member.enclosingElement;
      member = closureClass.methodElement;
      member = member.outermostEnclosingMemberOrTopLevel;
    }
    bool isInConstructorContext = member.isConstructor ||
        member.isGenerativeConstructorBody;
    Local typeVariableLocal = localsHandler.getTypeVariableAsLocal(type);
    if (isClosure) {
      if (member.isFactoryConstructor ||
          (isInConstructorContext && hasDirectLocal(typeVariableLocal))) {
        // The type variable is used from a closure in a factory constructor.
        // The value of the type argument is stored as a local on the closure
        // itself.
        return localsHandler.readLocal(
            typeVariableLocal, sourceInformation: sourceInformation);
      } else if (member.isFunction ||
                 member.isGetter ||
                 member.isSetter ||
                 isInConstructorContext) {
        // The type variable is stored on the "enclosing object" and needs to be
        // accessed using the this-reference in the closure.
        return readTypeVariable(
            member.enclosingClass,
            type.element,
            sourceInformation: sourceInformation);
      } else {
        assert(member.isField);
        // The type variable is stored in a parameter of the method.
        return localsHandler.readLocal(typeVariableLocal);
      }
    } else if (isInConstructorContext ||
               // When [member] is a field, we can be either
               // generating a checked setter or inlining its
               // initializer in a constructor. An initializer is
               // never built standalone, so in that case [target] is not
               // the [member] itself.
               (member.isField && member != target)) {
      // The type variable is stored in a parameter of the method.
      return localsHandler.readLocal(
          typeVariableLocal, sourceInformation: sourceInformation);
    } else if (member.isInstanceMember) {
      // The type variable is stored on the object.
      return readTypeVariable(
          member.enclosingClass,
          type.element,
          sourceInformation: sourceInformation);
    } else {
      reporter.internalError(type.element,
          'Unexpected type variable in static context.');
      return null;
    }
  }

  HInstruction analyzeTypeArgument(
      DartType argument,
      {SourceInformation sourceInformation}) {

    assert(assertTypeInContext(argument));
    if (argument.treatAsDynamic) {
      // Represent [dynamic] as [null].
      return graph.addConstantNull(compiler);
    }

    if (argument.isTypeVariable) {
      return addTypeVariableReference(
          argument, sourceInformation: sourceInformation);
    }

    List<HInstruction> inputs = <HInstruction>[];

    js.Expression template =
        rtiEncoder.getTypeRepresentationWithPlaceholders(argument, (variable) {
            inputs.add(addTypeVariableReference(variable));
        });

    js.Template code = new js.Template(null, template);
    HInstruction result = new HForeignCode(code, backend.stringType, inputs,
        nativeBehavior: native.NativeBehavior.PURE);
    add(result);
    return result;
  }

  HInstruction handleListConstructor(InterfaceType type,
                                     ast.Node currentNode,
                                     HInstruction newObject) {
    if (!backend.classNeedsRti(type.element) || type.treatAsRaw) {
      return newObject;
    }
    List<HInstruction> inputs = <HInstruction>[];
    type = localsHandler.substInContext(type);
    type.typeArguments.forEach((DartType argument) {
      inputs.add(analyzeTypeArgument(argument));
    });
    // TODO(15489): Register at codegen.
    registry?.registerInstantiation(type);
    return callSetRuntimeTypeInfo(type.element, inputs, newObject);
  }

  void copyRuntimeTypeInfo(HInstruction source, HInstruction target) {
    Element copyHelper = helpers.copyTypeArguments;
    pushInvokeStatic(null, copyHelper, [source, target],
        sourceInformation: target.sourceInformation);
    pop();
  }

  HInstruction callSetRuntimeTypeInfo(ClassElement element,
                                      List<HInstruction> rtiInputs,
                                      HInstruction newObject) {
    if (!backend.classNeedsRti(element) || element.typeVariables.isEmpty) {
      return newObject;
    }

    HInstruction typeInfo = buildLiteralList(rtiInputs);
    add(typeInfo);

    // Set the runtime type information on the object.
    Element typeInfoSetterElement = helpers.setRuntimeTypeInfo;
    pushInvokeStatic(
        null,
        typeInfoSetterElement,
        <HInstruction>[newObject, typeInfo],
        typeMask: backend.dynamicType,
        sourceInformation: newObject.sourceInformation);

    // The new object will now be referenced through the
    // `setRuntimeTypeInfo` call. We therefore set the type of that
    // instruction to be of the object's type.
    assert(invariant(
        CURRENT_ELEMENT_SPANNABLE,
        stack.last is HInvokeStatic || stack.last == newObject,
        message:
          "Unexpected `stack.last`: Found ${stack.last}, "
          "expected ${newObject} or an HInvokeStatic. "
          "State: element=$element, rtiInputs=$rtiInputs, stack=$stack."));
    stack.last.instructionType = newObject.instructionType;
    return pop();
  }

  void handleNewSend(ast.NewExpression node) {
    ast.Send send = node.send;
    generateIsDeferredLoadedCheckOfSend(send);

    bool isFixedList = false;
    bool isFixedListConstructorCall =
        Elements.isFixedListConstructorCall(elements[send], send, compiler);
    bool isGrowableListConstructorCall =
        Elements.isGrowableListConstructorCall(elements[send], send, compiler);

    TypeMask computeType(element) {
      Element originalElement = elements[send];
      if (isFixedListConstructorCall
          || Elements.isFilledListConstructorCall(
                  originalElement, send, compiler)) {
        isFixedList = true;
        TypeMask inferred =
            TypeMaskFactory.inferredForNode(sourceElement, send, compiler);
        return inferred.containsAll(compiler.world)
            ? backend.fixedArrayType
            : inferred;
      } else if (isGrowableListConstructorCall) {
        TypeMask inferred =
            TypeMaskFactory.inferredForNode(sourceElement, send, compiler);
        return inferred.containsAll(compiler.world)
            ? backend.extendableArrayType
            : inferred;
      } else if (Elements.isConstructorOfTypedArraySubclass(
                    originalElement, compiler)) {
        isFixedList = true;
        TypeMask inferred =
            TypeMaskFactory.inferredForNode(sourceElement, send, compiler);
        ClassElement cls = element.enclosingClass;
        assert(backend.isNative(cls.thisType.element));
        return inferred.containsAll(compiler.world)
            ? new TypeMask.nonNullExact(cls.thisType.element, compiler.world)
            : inferred;
      } else if (element.isGenerativeConstructor) {
        ClassElement cls = element.enclosingClass;
        if (cls.isAbstract) {
          // An error will be thrown.
          return new TypeMask.nonNullEmpty();
        } else {
          return new TypeMask.nonNullExact(
              cls.thisType.element, compiler.world);
        }
      } else {
        return TypeMaskFactory.inferredReturnTypeForElement(
            originalElement, compiler);
      }
    }

    Element constructor = elements[send];
    CallStructure callStructure = elements.getSelector(send).callStructure;
    ConstructorElement constructorDeclaration = constructor;
    ConstructorElement constructorImplementation = constructor.implementation;
    constructor = constructorImplementation.effectiveTarget;

    final bool isSymbolConstructor =
        constructorDeclaration == compiler.symbolConstructor;
    final bool isJSArrayTypedConstructor =
        constructorDeclaration == helpers.jsArrayTypedConstructor;

    if (isSymbolConstructor) {
      constructor = compiler.symbolValidatedConstructor;
      assert(invariant(send, constructor != null,
                       message: 'Constructor Symbol.validated is missing'));
      callStructure = compiler.symbolValidatedConstructorSelector.callStructure;
      assert(invariant(send, callStructure != null,
                       message: 'Constructor Symbol.validated is missing'));
    }

    bool isRedirected = constructorDeclaration.isRedirectingFactory;
    if (!constructorDeclaration.isCyclicRedirection) {
      // Insert a check for every deferred redirection on the path to the
      // final target.
      ConstructorElement target = constructorDeclaration;
      while (target.isRedirectingFactory) {
        if (constructorDeclaration.redirectionDeferredPrefix != null) {
          generateIsDeferredLoadedCheckIfNeeded(
              target.redirectionDeferredPrefix,
              node);
        }
        target = target.immediateRedirectionTarget;
      }
    }
    InterfaceType type = elements.getType(node);
    InterfaceType expectedType =
        constructorDeclaration.computeEffectiveTargetType(type);
    expectedType = localsHandler.substInContext(expectedType);

    if (compiler.elementHasCompileTimeError(constructor)) {
      // TODO(ahe): Do something like [generateWrongArgumentCountError].
      stack.add(graph.addConstantNull(compiler));
      return;
    }

    if (checkTypeVariableBounds(node, type)) return;

    // Abstract class instantiation error takes precedence over argument
    // mismatch.
    ClassElement cls = constructor.enclosingClass;
    if (cls.isAbstract && constructor.isGenerativeConstructor) {
      // However, we need to ensure that all arguments are evaluated before we
      // throw the ACIE exception.
      send.arguments.forEach((arg) {
        visit(arg);
        pop();
      });
      generateAbstractClassInstantiationError(send, cls.name);
      return;
    }

    // TODO(5347): Try to avoid the need for calling [implementation] before
    // calling [makeStaticArgumentList].
    constructorImplementation = constructor.implementation;
    if (constructorImplementation.isMalformed ||
        !callStructure.signatureApplies(
            constructorImplementation.functionSignature)) {
      generateWrongArgumentCountError(send, constructor, send.arguments);
      return;
    }

    var inputs = <HInstruction>[];
    if (constructor.isGenerativeConstructor &&
        backend.isNativeOrExtendsNative(constructor.enclosingClass) &&
        !backend.isJsInterop(constructor)) {
      // Native class generative constructors take a pre-constructed object.
      inputs.add(graph.addConstantNull(compiler));
    }
    inputs.addAll(makeStaticArgumentList(callStructure,
                                         send.arguments,
                                         constructorImplementation));

    TypeMask elementType = computeType(constructor);
    if (isFixedListConstructorCall) {
      if (!inputs[0].isNumber(compiler)) {
        HTypeConversion conversion = new HTypeConversion(
          null, HTypeConversion.ARGUMENT_TYPE_CHECK, backend.numType,
          inputs[0], null);
        add(conversion);
        inputs[0] = conversion;
      }
      js.Template code = js.js.parseForeignJS('new Array(#)');
      var behavior = new native.NativeBehavior();
      behavior.typesReturned.add(expectedType);
      // The allocation can throw only if the given length is a double or
      // outside the unsigned 32 bit range.
      // TODO(sra): Array allocation should be an instruction so that canThrow
      // can depend on a length type discovered in optimization.
      bool canThrow = true;
      if (inputs[0].isInteger(compiler) && inputs[0] is HConstant) {
        var constant = inputs[0];
        int value = constant.constant.primitiveValue;
        if (0 <= value && value < 0x100000000) canThrow = false;
      }
      HForeignCode foreign = new HForeignCode(code, elementType, inputs,
          nativeBehavior: behavior,
          throwBehavior: canThrow
              ? native.NativeThrowBehavior.MAY
              : native.NativeThrowBehavior.NEVER);
      push(foreign);
      TypesInferrer inferrer = compiler.typesTask.typesInferrer;
      if (inferrer.isFixedArrayCheckedForGrowable(send)) {
        js.Template code = js.js.parseForeignJS(r'#.fixed$length = Array');
        // We set the instruction as [canThrow] to avoid it being dead code.
        // We need a finer grained side effect.
        add(new HForeignCode(code, backend.nullType, [stack.last],
                throwBehavior: native.NativeThrowBehavior.MAY));
      }
    } else if (isGrowableListConstructorCall) {
      push(buildLiteralList(<HInstruction>[]));
      stack.last.instructionType = elementType;
    } else {
      SourceInformation sourceInformation =
          sourceInformationBuilder.buildNew(send);
      potentiallyAddTypeArguments(inputs, cls, expectedType);
      addInlinedInstantiation(expectedType);
      pushInvokeStatic(node, constructor, inputs,
          typeMask: elementType,
          instanceType: expectedType,
          sourceInformation: sourceInformation);
      removeInlinedInstantiation(expectedType);
    }
    HInstruction newInstance = stack.last;
    if (isFixedList) {
      // Overwrite the element type, in case the allocation site has
      // been inlined.
      newInstance.instructionType = elementType;
      if (context != null) {
        context.allocatedFixedLists.add(newInstance);
      }
    }

    // The List constructor forwards to a Dart static method that does
    // not know about the type argument. Therefore we special case
    // this constructor to have the setRuntimeTypeInfo called where
    // the 'new' is done.
    if (backend.classNeedsRti(coreClasses.listClass) &&
        (isFixedListConstructorCall || isGrowableListConstructorCall ||
         isJSArrayTypedConstructor)) {
      newInstance = handleListConstructor(type, send, pop());
      stack.add(newInstance);
    }

    // Finally, if we called a redirecting factory constructor, check the type.
    if (isRedirected) {
      HInstruction checked = potentiallyCheckOrTrustType(newInstance, type);
      if (checked != newInstance) {
        pop();
        stack.add(checked);
      }
    }
  }

  void potentiallyAddTypeArguments(List<HInstruction> inputs, ClassElement cls,
                                   InterfaceType expectedType,
                                   {SourceInformation sourceInformation}) {
    if (!backend.classNeedsRti(cls)) return;
    assert(expectedType.typeArguments.isEmpty ||
        cls.typeVariables.length == expectedType.typeArguments.length);
    expectedType.typeArguments.forEach((DartType argument) {
      inputs.add(analyzeTypeArgument(
          argument, sourceInformation: sourceInformation));
    });
  }

  /// In checked mode checks the [type] of [node] to be well-bounded. The method
  /// returns [:true:] if an error can be statically determined.
  bool checkTypeVariableBounds(ast.NewExpression node, InterfaceType type) {
    if (!compiler.enableTypeAssertions) return false;

    Map<DartType, Set<DartType>> seenChecksMap =
        new Map<DartType, Set<DartType>>();
    bool definitelyFails = false;

    addTypeVariableBoundCheck(GenericType instance,
                              DartType typeArgument,
                              TypeVariableType typeVariable,
                              DartType bound) {
      if (definitelyFails) return;

      int subtypeRelation = compiler.types.computeSubtypeRelation(typeArgument, bound);
      if (subtypeRelation == Types.IS_SUBTYPE) return;

      String message =
          "Can't create an instance of malbounded type '$type': "
          "'${typeArgument}' is not a subtype of bound '${bound}' for "
          "type variable '${typeVariable}' of type "
          "${type == instance
              ? "'${type.element.thisType}'"
              : "'${instance.element.thisType}' on the supertype "
                "'${instance}' of '${type}'"
            }.";
      if (subtypeRelation == Types.NOT_SUBTYPE) {
        generateTypeError(node, message);
        definitelyFails = true;
        return;
      } else if (subtypeRelation == Types.MAYBE_SUBTYPE) {
        Set<DartType> seenChecks =
            seenChecksMap.putIfAbsent(typeArgument, () => new Set<DartType>());
        if (!seenChecks.contains(bound)) {
          seenChecks.add(bound);
          assertIsSubtype(node, typeArgument, bound, message);
        }
      }
    }

    compiler.types.checkTypeVariableBounds(type, addTypeVariableBoundCheck);
    if (definitelyFails) {
      return true;
    }
    for (InterfaceType supertype in type.element.allSupertypes) {
      DartType instance = type.asInstanceOf(supertype.element);
      compiler.types.checkTypeVariableBounds(instance,
          addTypeVariableBoundCheck);
      if (definitelyFails) {
        return true;
      }
    }
    return false;
  }

  visitStaticSend(ast.Send node) {
    internalError(node, "Unexpected visitStaticSend");
  }

  /// Generate an invocation to the static or top level [function].
  void generateStaticFunctionInvoke(
      ast.Send node,
      FunctionElement function,
      CallStructure callStructure) {
    List<HInstruction> inputs = makeStaticArgumentList(
        callStructure,
        node.arguments,
        function.implementation);

    if (function == compiler.identicalFunction) {
      pushWithPosition(
          new HIdentity(inputs[0], inputs[1], null, backend.boolType), node);
      return;
    } else {
      pushInvokeStatic(node, function, inputs,
          sourceInformation: sourceInformationBuilder.buildCall(
              node, node.selector));
    }
  }

  /// Generate an invocation to a static or top level function with the wrong
  /// number of arguments.
  void generateStaticFunctionIncompatibleInvoke(ast.Send node,
                                                Element element) {
    generateWrongArgumentCountError(node, element, node.arguments);
  }

  @override
  void visitStaticFieldInvoke(
      ast.Send node,
      FieldElement field,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    generateStaticFieldGet(node, field);
    generateCallInvoke(
        node,
        pop(),
        sourceInformationBuilder.buildCall(node, node.argumentsNode));
  }

  @override
  void visitStaticFunctionInvoke(
      ast.Send node,
      MethodElement function,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    generateStaticFunctionInvoke(node, function, callStructure);
  }

  @override
  void visitStaticFunctionIncompatibleInvoke(
      ast.Send node,
      MethodElement function,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    generateStaticFunctionIncompatibleInvoke(node, function);
  }

  @override
  void visitStaticGetterInvoke(
      ast.Send node,
      FunctionElement getter,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    generateStaticGetterGet(node, getter);
    generateCallInvoke(
        node,
        pop(),
        sourceInformationBuilder.buildCall(node, node.argumentsNode));
  }

  @override
  void visitTopLevelFieldInvoke(
      ast.Send node,
      FieldElement field,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    generateStaticFieldGet(node, field);
    generateCallInvoke(
        node,
        pop(),
        sourceInformationBuilder.buildCall(node, node.argumentsNode));
  }

  @override
  void visitTopLevelFunctionInvoke(
      ast.Send node,
      MethodElement function,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    if (backend.isForeign(function)) {
      handleForeignSend(node, function);
    } else {
      generateStaticFunctionInvoke(node, function, callStructure);
    }
  }

  @override
  void visitTopLevelFunctionIncompatibleInvoke(
      ast.Send node,
      MethodElement function,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    generateStaticFunctionIncompatibleInvoke(node, function);
  }

  @override
  void visitTopLevelGetterInvoke(
      ast.Send node,
      FunctionElement getter,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    generateStaticGetterGet(node, getter);
    generateCallInvoke(
        node,
        pop(),
        sourceInformationBuilder.buildCall(node, node.argumentsNode));
  }

  @override
  void visitTopLevelSetterGet(
      ast.Send node,
      MethodElement setter,
      _) {
    handleInvalidStaticGet(node, setter);
  }

  @override
  void visitStaticSetterGet(
      ast.Send node,
      MethodElement setter,
      _) {
    handleInvalidStaticGet(node, setter);
  }

  @override
  void visitUnresolvedGet(
      ast.Send node,
      Element element,
      _) {
    generateStaticUnresolvedGet(node, element);
  }

  void handleInvalidStaticInvoke(ast.Send node, Element element) {
    generateThrowNoSuchMethod(node,
                              noSuchMethodTargetSymbolString(element),
                              argumentNodes: node.arguments);
  }

  @override
  void visitStaticSetterInvoke(
      ast.Send node,
      MethodElement setter,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    handleInvalidStaticInvoke(node, setter);
  }

  @override
  void visitTopLevelSetterInvoke(
      ast.Send node,
      MethodElement setter,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    handleInvalidStaticInvoke(node, setter);
  }

  @override
  void visitUnresolvedInvoke(
      ast.Send node,
      Element element,
      ast.NodeList arguments,
      Selector selector,
      _) {
    if (element is ErroneousElement) {
      // An erroneous element indicates that the function could not be
      // resolved (a warning has been issued).
      handleInvalidStaticInvoke(node, element);
    } else {
      // TODO(ahe): Do something like [generateWrongArgumentCountError].
      stack.add(graph.addConstantNull(compiler));
    }
    return;
  }

  HConstant addConstantString(String string) {
    ast.DartString dartString = new ast.DartString.literal(string);
    return graph.addConstantString(dartString, compiler);
  }

  HConstant addConstantStringFromName(js.Name name) {
    return graph.addConstantStringFromName(name, compiler);
  }

  visitClassTypeLiteralGet(
      ast.Send node,
      ConstantExpression constant,
      _) {
    generateConstantTypeLiteral(node);
  }

  visitClassTypeLiteralInvoke(
      ast.Send node,
      ConstantExpression constant,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    generateConstantTypeLiteral(node);
    generateTypeLiteralCall(node);
  }

  visitTypedefTypeLiteralGet(
      ast.Send node,
      ConstantExpression constant,
      _) {
    generateConstantTypeLiteral(node);
  }

  visitTypedefTypeLiteralInvoke(
      ast.Send node,
      ConstantExpression constant,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    generateConstantTypeLiteral(node);
    generateTypeLiteralCall(node);
  }

  visitTypeVariableTypeLiteralGet(
      ast.Send node,
      TypeVariableElement element,
      _) {
    generateTypeVariableLiteral(node, element.type);
  }

  visitTypeVariableTypeLiteralInvoke(
      ast.Send node,
      TypeVariableElement element,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    generateTypeVariableLiteral(node, element.type);
    generateTypeLiteralCall(node);
  }

  visitDynamicTypeLiteralGet(
      ast.Send node,
      ConstantExpression constant,
      _) {
    generateConstantTypeLiteral(node);
  }

  visitDynamicTypeLiteralInvoke(
      ast.Send node,
      ConstantExpression constant,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    generateConstantTypeLiteral(node);
    generateTypeLiteralCall(node);
  }

  /// Generate the constant value for a constant type literal.
  void generateConstantTypeLiteral(ast.Send node) {
    // TODO(karlklose): add type representation
    if (node.isCall) {
      // The node itself is not a constant but we register the selector (the
      // identifier that refers to the class/typedef) as a constant.
      stack.add(addConstant(node.selector));
    } else {
      stack.add(addConstant(node));
    }
  }

  /// Generate the literal for [typeVariable] in the current context.
  void generateTypeVariableLiteral(ast.Send node,
                                   TypeVariableType typeVariable) {
    DartType type = localsHandler.substInContext(typeVariable);
    HInstruction value = analyzeTypeArgument(type,
        sourceInformation: sourceInformationBuilder.buildGet(node));
    pushInvokeStatic(node,
                     helpers.runtimeTypeToString,
                     [value],
                     typeMask: backend.stringType);
    pushInvokeStatic(node,
                     helpers.createRuntimeType,
                     [pop()]);
  }

  /// Generate a call to a type literal.
  void generateTypeLiteralCall(ast.Send node) {
    // This send is of the form 'e(...)', where e is resolved to a type
    // reference. We create a regular closure call on the result of the type
    // reference instead of creating a NoSuchMethodError to avoid pulling it
    // in if it is not used (e.g., in a try/catch).
    HInstruction target = pop();
    generateCallInvoke(node, target,
        sourceInformationBuilder.buildCall(node, node.argumentsNode));
  }

  /// Generate a '.call' invocation on [target].
  void generateCallInvoke(ast.Send node,
                          HInstruction target,
                          SourceInformation sourceInformation) {
    Selector selector = elements.getSelector(node);
    List<HInstruction> inputs = <HInstruction>[target];
    addDynamicSendArgumentsToList(node, inputs);
    push(new HInvokeClosure(
            new Selector.callClosureFrom(selector),
            inputs, backend.dynamicType)
        ..sourceInformation = sourceInformation);
  }

  visitGetterSend(ast.Send node) {
    internalError(node, "Unexpected visitGetterSend");
  }

  // TODO(antonm): migrate rest of SsaFromAstMixin to internalError.
  internalError(Spannable node, String reason) {
    reporter.internalError(node, reason);
  }

  void generateError(ast.Node node, String message, Element helper) {
    HInstruction errorMessage = addConstantString(message);
    pushInvokeStatic(node, helper, [errorMessage]);
  }

  void generateRuntimeError(ast.Node node, String message) {
    generateError(node, message, helpers.throwRuntimeError);
  }

  void generateTypeError(ast.Node node, String message) {
    generateError(node, message, helpers.throwTypeError);
  }

  void generateAbstractClassInstantiationError(ast.Node node, String message) {
    generateError(node,
                  message,
                  helpers.throwAbstractClassInstantiationError);
  }

  void generateThrowNoSuchMethod(ast.Node diagnosticNode,
                                 String methodName,
                                 {Link<ast.Node> argumentNodes,
                                  List<HInstruction> argumentValues,
                                  List<String> existingArguments,
                                  SourceInformation sourceInformation}) {
    Element helper = helpers.throwNoSuchMethod;
    ConstantValue receiverConstant =
        constantSystem.createString(new ast.DartString.empty());
    HInstruction receiver = graph.addConstant(receiverConstant, compiler);
    ast.DartString dartString = new ast.DartString.literal(methodName);
    ConstantValue nameConstant = constantSystem.createString(dartString);
    HInstruction name = graph.addConstant(nameConstant, compiler);
    if (argumentValues == null) {
      argumentValues = <HInstruction>[];
      argumentNodes.forEach((argumentNode) {
        visit(argumentNode);
        HInstruction value = pop();
        argumentValues.add(value);
      });
    }
    HInstruction arguments = buildLiteralList(argumentValues);
    add(arguments);
    HInstruction existingNamesList;
    if (existingArguments != null) {
      List<HInstruction> existingNames = <HInstruction>[];
      for (String name in existingArguments) {
        HInstruction nameConstant =
            graph.addConstantString(new ast.DartString.literal(name), compiler);
        existingNames.add(nameConstant);
      }
      existingNamesList = buildLiteralList(existingNames);
      add(existingNamesList);
    } else {
      existingNamesList = graph.addConstantNull(compiler);
    }
    pushInvokeStatic(diagnosticNode,
                     helper,
                     [receiver, name, arguments, existingNamesList],
                     sourceInformation: sourceInformation);
  }

  /**
   * Generate code to throw a [NoSuchMethodError] exception for calling a
   * method with a wrong number of arguments or mismatching named optional
   * arguments.
   */
  void generateWrongArgumentCountError(ast.Node diagnosticNode,
                                       FunctionElement function,
                                       Link<ast.Node> argumentNodes) {
    List<String> existingArguments = <String>[];
    FunctionSignature signature = function.functionSignature;
    signature.forEachParameter((Element parameter) {
      existingArguments.add(parameter.name);
    });
    generateThrowNoSuchMethod(diagnosticNode,
                              function.name,
                              argumentNodes: argumentNodes,
                              existingArguments: existingArguments);
  }

  @override
  void bulkHandleNode(ast.Node node, String message, _) {
    internalError(node, "Unexpected bulk handled node: $node");
  }

  @override
  void bulkHandleNew(ast.NewExpression node, [_]) {
    Element element = elements[node.send];
    final bool isSymbolConstructor = element == compiler.symbolConstructor;
    if (!Elements.isMalformed(element)) {
      ConstructorElement function = element;
      element = function.effectiveTarget;
    }
    if (Elements.isError(element)) {
      ErroneousElement error = element;
      if (error.messageKind == MessageKind.CANNOT_FIND_CONSTRUCTOR ||
          error.messageKind == MessageKind.CANNOT_FIND_UNNAMED_CONSTRUCTOR) {
        generateThrowNoSuchMethod(
            node.send,
            noSuchMethodTargetSymbolString(error, 'constructor'),
            argumentNodes: node.send.arguments);
      } else {
        MessageTemplate template = MessageTemplate.TEMPLATES[error.messageKind];
        Message message = template.message(error.messageArguments);
        generateRuntimeError(node.send, message.toString());
      }
    } else if (Elements.isMalformed(element)) {
      // TODO(ahe): Do something like [generateWrongArgumentCountError].
      stack.add(graph.addConstantNull(compiler));
    } else if (node.isConst) {
      stack.add(addConstant(node));
      if (isSymbolConstructor) {
        ConstructedConstantValue symbol = getConstantForNode(node);
        StringConstantValue stringConstant = symbol.fields.values.single;
        String nameString = stringConstant.toDartString().slowToString();
        registry?.registerConstSymbol(nameString);
      }
    } else {
      handleNewSend(node);
    }
  }

  @override
  void errorNonConstantConstructorInvoke(
      ast.NewExpression node,
      Element element,
      DartType type,
      ast.NodeList arguments,
      CallStructure callStructure,
      _) {
    bulkHandleNew(node);
  }

  void pushInvokeDynamic(ast.Node node,
                         Selector selector,
                         TypeMask mask,
                         List<HInstruction> arguments,
                         {SourceInformation sourceInformation}) {

    // We prefer to not inline certain operations on indexables,
    // because the constant folder will handle them better and turn
    // them into simpler instructions that allow further
    // optimizations.
    bool isOptimizableOperationOnIndexable(Selector selector, Element element) {
      bool isLength = selector.isGetter
          && selector.name == "length";
      if (isLength || selector.isIndex) {
        return compiler.world.isSubtypeOf(
            element.enclosingClass.declaration,
            helpers.jsIndexableClass);
      } else if (selector.isIndexSet) {
        return compiler.world.isSubtypeOf(
            element.enclosingClass.declaration,
            helpers.jsMutableIndexableClass);
      } else {
        return false;
      }
    }

    bool isOptimizableOperation(Selector selector, Element element) {
      ClassElement cls = element.enclosingClass;
      if (isOptimizableOperationOnIndexable(selector, element)) return true;
      if (!backend.interceptedClasses.contains(cls)) return false;
      if (selector.isOperator) return true;
      if (selector.isSetter) return true;
      if (selector.isIndex) return true;
      if (selector.isIndexSet) return true;
      if (element == helpers.jsArrayAdd ||
          element == helpers.jsArrayRemoveLast ||
          element == helpers.jsStringSplit) {
        return true;
      }
      return false;
    }

    Element element = compiler.world.locateSingleElement(selector, mask);
    if (element != null &&
        !element.isField &&
        !(element.isGetter && selector.isCall) &&
        !(element.isFunction && selector.isGetter) &&
        !isOptimizableOperation(selector, element)) {
      if (tryInlineMethod(element, selector, mask, arguments, node)) {
        return;
      }
    }

    HInstruction receiver = arguments[0];
    List<HInstruction> inputs = <HInstruction>[];
    bool isIntercepted = backend.isInterceptedSelector(selector);
    if (isIntercepted) {
      inputs.add(invokeInterceptor(receiver));
    }
    inputs.addAll(arguments);
    TypeMask type =
        TypeMaskFactory.inferredTypeForSelector(selector, mask, compiler);
    if (selector.isGetter) {
      push(
          new HInvokeDynamicGetter(selector, mask, null, inputs, type)
              ..sourceInformation = sourceInformation);
    } else if (selector.isSetter) {
      push(
          new HInvokeDynamicSetter(selector, mask, null, inputs, type)
              ..sourceInformation = sourceInformation);
    } else {
      push(
          new HInvokeDynamicMethod(selector, mask, inputs, type, isIntercepted)
              ..sourceInformation = sourceInformation);
    }
  }

  bool _hasNamedParameters(FunctionElement function) {
    FunctionSignature params = function.functionSignature;
    return params.optionalParameterCount > 0
        && params.optionalParametersAreNamed;
  }

  HForeignCode invokeJsInteropFunction(FunctionElement element,
                                       List<HInstruction> arguments,
                                       SourceInformation sourceInformation) {
    assert(backend.isJsInterop(element));
    nativeEmitter.nativeMethods.add(element);
    String templateString;

    if (element.isFactoryConstructor &&
        backend.jsInteropAnalysis.hasAnonymousAnnotation(element.contextClass)) {
      // Factory constructor that is syntactic sugar for creating a JavaScript
      // object literal.
      ConstructorElement constructor = element;
      FunctionSignature params = constructor.functionSignature;
      int i = 0;
      int positions = 0;
      var filteredArguments = <HInstruction>[];
      var parameterNameMap = new Map<String, js.Expression>();
      params.orderedForEachParameter((ParameterElement parameter) {
        // TODO(jacobr): throw if parameter names do not match names of property
        // names in the class.
        assert (parameter.isNamed);
        HInstruction argument = arguments[i];
        if (argument != null) {
          filteredArguments.add(argument);
          parameterNameMap[parameter.name] =
              new js.InterpolatedExpression(positions++);
        }
        i++;
      });
      var codeTemplate = new js.Template(null,
          js.objectLiteral(parameterNameMap));

      var nativeBehavior = new native.NativeBehavior()
        ..codeTemplate = codeTemplate;
      if (compiler.trustJSInteropTypeAnnotations) {
        nativeBehavior.typesReturned.add(constructor.enclosingClass.thisType);
      }
      return new HForeignCode(
          codeTemplate,
          backend.dynamicType, filteredArguments,
          nativeBehavior: nativeBehavior)
        ..sourceInformation = sourceInformation;
    }
    var target = new HForeignCode(js.js.parseForeignJS(
            "${backend.namer.fixedBackendPath(element)}."
            "${backend.getFixedBackendName(element)}"),
        backend.dynamicType,
        <HInstruction>[]);
    add(target);
    // Strip off trailing arguments that were not specified.
    // we could assert that the trailing arguments are all null.
    // TODO(jacobr): rewrite named arguments to an object literal matching
    // the factory constructor case.
    arguments = arguments.where((arg) => arg != null).toList();
    var inputs = <HInstruction>[target]..addAll(arguments);

    var nativeBehavior = new native.NativeBehavior()
      ..sideEffects.setAllSideEffects();

    DartType type = element.isConstructor ?
        element.enclosingClass.thisType : element.type.returnType;
    // Native behavior effects here are similar to native/behavior.dart.
    // The return type is dynamic if we don't trust js-interop type
    // declarations.
    nativeBehavior.typesReturned.add(
        compiler.trustJSInteropTypeAnnotations ? type : const DynamicType());

    // The allocation effects include the declared type if it is native (which
    // includes js interop types).
    if (type.element != null && backend.isNative(type.element)) {
      nativeBehavior.typesInstantiated.add(type);
    }

    // It also includes any other JS interop type if we don't trust the
    // annotation or if is declared too broad.
    if (!compiler.trustJSInteropTypeAnnotations || type.isObject ||
        type.isDynamic) {
      nativeBehavior.typesInstantiated.add(
          backend.helpers.jsJavaScriptObjectClass.thisType);
    }

    String code;
    if (element.isGetter) {
      code = "#";
    } else if (element.isSetter) {
      code = "# = #";
    } else {
      var args = new List.filled(arguments.length, '#').join(',');
      code = element.isConstructor ? "new #($args)" : "#($args)";
    }
    js.Template codeTemplate = js.js.parseForeignJS(code);
    nativeBehavior.codeTemplate = codeTemplate;

    return new HForeignCode(
        codeTemplate,
        backend.dynamicType, inputs,
        nativeBehavior: nativeBehavior)
      ..sourceInformation = sourceInformation;
  }

  void pushInvokeStatic(ast.Node location,
                        Element element,
                        List<HInstruction> arguments,
                        {TypeMask typeMask,
                         InterfaceType instanceType,
                         SourceInformation sourceInformation}) {
    // TODO(johnniwinther): Use [sourceInformation] instead of [location].
    if (tryInlineMethod(element, null, null, arguments, location,
                        instanceType: instanceType)) {
      return;
    }

    if (typeMask == null) {
      typeMask =
          TypeMaskFactory.inferredReturnTypeForElement(element, compiler);
    }
    bool targetCanThrow = !compiler.world.getCannotThrow(element);
    // TODO(5346): Try to avoid the need for calling [declaration] before
    var instruction;
    if (backend.isJsInterop(element)) {
      instruction = invokeJsInteropFunction(element, arguments,
          sourceInformation);
    } else {
      // creating an [HInvokeStatic].
      instruction = new HInvokeStatic(
          element.declaration, arguments, typeMask,
          targetCanThrow: targetCanThrow)
        ..sourceInformation = sourceInformation;
      if (!currentInlinedInstantiations.isEmpty) {
        instruction.instantiatedTypes = new List<DartType>.from(
            currentInlinedInstantiations);
      }
      instruction.sideEffects = compiler.world.getSideEffectsOfElement(element);
    }
    if (location == null) {
      push(instruction);
    } else {
      pushWithPosition(instruction, location);
    }
  }

  HInstruction buildInvokeSuper(Selector selector,
                                Element element,
                                List<HInstruction> arguments,
                                [SourceInformation sourceInformation]) {
    HInstruction receiver = localsHandler.readThis();
    // TODO(5346): Try to avoid the need for calling [declaration] before
    // creating an [HStatic].
    List<HInstruction> inputs = <HInstruction>[];
    if (backend.isInterceptedSelector(selector) &&
        // Fields don't need an interceptor; consider generating HFieldGet/Set
        // instead.
        element.kind != ElementKind.FIELD) {
      inputs.add(invokeInterceptor(receiver));
    }
    inputs.add(receiver);
    inputs.addAll(arguments);
    TypeMask type;
    if (!element.isGetter && selector.isGetter) {
      type = TypeMaskFactory.inferredTypeForElement(element, compiler);
    } else {
      type = TypeMaskFactory.inferredReturnTypeForElement(element, compiler);
    }
    HInstruction instruction = new HInvokeSuper(
        element,
        currentNonClosureClass,
        selector,
        inputs,
        type,
        sourceInformation,
        isSetter: selector.isSetter || selector.isIndexSet);
    instruction.sideEffects =
        compiler.world.getSideEffectsOfSelector(selector, null);
    return instruction;
  }

  void handleComplexOperatorSend(ast.SendSet node,
                                 HInstruction receiver,
                                 Link<ast.Node> arguments) {
    HInstruction rhs;
    if (node.isPrefix || node.isPostfix) {
      rhs = graph.addConstantInt(1, compiler);
    } else {
      visit(arguments.head);
      assert(arguments.tail.isEmpty);
      rhs = pop();
    }
    visitBinarySend(
        receiver,
        rhs,
        elements.getOperatorSelectorInComplexSendSet(node),
        elements.getOperatorTypeMaskInComplexSendSet(node),
        node,
        sourceInformation:
          sourceInformationBuilder.buildGeneric(node.assignmentOperator));
  }

  void handleSuperSendSet(ast.SendSet node) {
    Element element = elements[node];
    List<HInstruction> setterInputs = <HInstruction>[];
    void generateSuperSendSet() {
      Selector setterSelector = elements.getSelector(node);
      if (Elements.isUnresolved(element)
          || !setterSelector.applies(element, compiler.world)) {
        generateSuperNoSuchMethodSend(
            node, setterSelector, setterInputs);
        pop();
      } else {
        add(buildInvokeSuper(setterSelector, element, setterInputs));
      }
    }
    if (identical(node.assignmentOperator.source, '=')) {
      addDynamicSendArgumentsToList(node, setterInputs);
      generateSuperSendSet();
      stack.add(setterInputs.last);
    } else {
      Element getter = elements[node.selector];
      List<HInstruction> getterInputs = <HInstruction>[];
      Link<ast.Node> arguments = node.arguments;
      if (node.isIndex) {
        // If node is of the form [:super.foo[0] += 2:], the send has
        // two arguments: the index and the left hand side. We get
        // the index and add it as input of the getter and the
        // setter.
        visit(arguments.head);
        arguments = arguments.tail;
        HInstruction index = pop();
        getterInputs.add(index);
        setterInputs.add(index);
      }
      HInstruction getterInstruction;
      Selector getterSelector =
          elements.getGetterSelectorInComplexSendSet(node);
      if (Elements.isUnresolved(getter)) {
        generateSuperNoSuchMethodSend(
            node,
            getterSelector,
            getterInputs);
        getterInstruction = pop();
      } else {
        getterInstruction = buildInvokeSuper(
            getterSelector, getter, getterInputs);
        add(getterInstruction);
      }

      if (node.isIfNullAssignment) {
        SsaBranchBuilder brancher = new SsaBranchBuilder(this, node);
        brancher.handleIfNull(() => stack.add(getterInstruction),
            () {
              addDynamicSendArgumentsToList(node, setterInputs);
              generateSuperSendSet();
              stack.add(setterInputs.last);
            });
      } else {
        handleComplexOperatorSend(node, getterInstruction, arguments);
        setterInputs.add(pop());
        generateSuperSendSet();
        stack.add(node.isPostfix ? getterInstruction : setterInputs.last);
      }
    }
  }

  @override
  void handleSuperCompounds(
      ast.SendSet node,
      Element getter,
      CompoundGetter getterKind,
      Element setter,
      CompoundSetter setterKind,
      CompoundRhs rhs,
      _) {
    handleSuperSendSet(node);
  }

  @override
  void visitFinalSuperFieldSet(
      ast.SendSet node,
      FieldElement field,
      ast.Node rhs,
      _) {
    handleSuperSendSet(node);
  }

  @override
  void visitSuperFieldSet(
      ast.SendSet node,
      FieldElement field,
      ast.Node rhs,
      _) {
    handleSuperSendSet(node);
  }

  @override
  void visitSuperGetterSet(
      ast.SendSet node,
      FunctionElement getter,
      ast.Node rhs,
      _) {
    handleSuperSendSet(node);
  }

  @override
  void visitSuperIndexSet(
      ast.SendSet node,
      FunctionElement function,
      ast.Node index,
      ast.Node rhs,
      _) {
    handleSuperSendSet(node);
  }

  @override
  void visitSuperMethodSet(
      ast.Send node,
      MethodElement method,
      ast.Node rhs,
      _) {
    handleSuperSendSet(node);
  }

  @override
  void visitSuperSetterSet(
      ast.SendSet node,
      FunctionElement setter,
      ast.Node rhs,
      _) {
    handleSuperSendSet(node);
  }

  @override
  void visitUnresolvedSuperIndexSet(
      ast.Send node,
      Element element,
      ast.Node index,
      ast.Node rhs,
      _) {
    handleSuperSendSet(node);
  }

  @override
  void visitSuperIndexPrefix(
      ast.Send node,
      MethodElement indexFunction,
      MethodElement indexSetFunction,
      ast.Node index,
      IncDecOperator operator,
      _) {
    handleSuperSendSet(node);
  }

  @override
  void visitSuperIndexPostfix(
      ast.Send node,
      MethodElement indexFunction,
      MethodElement indexSetFunction,
      ast.Node index,
      IncDecOperator operator,
      _) {
    handleSuperSendSet(node);
  }

  @override
  void visitUnresolvedSuperGetterIndexPrefix(
      ast.Send node,
      Element element,
      MethodElement setter,
      ast.Node index,
      IncDecOperator operator,
      _) {
    handleSuperSendSet(node);
  }

  @override
  void visitUnresolvedSuperGetterIndexPostfix(
      ast.Send node,
      Element element,
      MethodElement setter,
      ast.Node index,
      IncDecOperator operator,
      _) {
    handleSuperSendSet(node);
  }

  @override
  void visitUnresolvedSuperSetterIndexPrefix(
      ast.Send node,
      MethodElement indexFunction,
      Element element,
      ast.Node index,
      IncDecOperator operator,
      _) {
    handleSuperSendSet(node);
  }

  @override
  void visitUnresolvedSuperSetterIndexPostfix(
      ast.Send node,
      MethodElement indexFunction,
      Element element,
      ast.Node index,
      IncDecOperator operator,
      _) {
    handleSuperSendSet(node);
  }

  @override
  void visitUnresolvedSuperIndexPrefix(
      ast.Send node,
      Element element,
      ast.Node index,
      IncDecOperator operator,
      _) {
    handleSuperSendSet(node);
  }

  @override
  void visitUnresolvedSuperIndexPostfix(
      ast.Send node,
      Element element,
      ast.Node index,
      IncDecOperator operator,
      _) {
    handleSuperSendSet(node);
  }

  @override
  void visitSuperCompoundIndexSet(
      ast.SendSet node,
      MethodElement getter,
      MethodElement setter,
      ast.Node index,
      AssignmentOperator operator,
      ast.Node rhs,
      _) {
    handleSuperSendSet(node);
  }

  @override
  void visitUnresolvedSuperGetterCompoundIndexSet(
      ast.Send node,
      Element element,
      MethodElement setter,
      ast.Node index,
      AssignmentOperator operator,
      ast.Node rhs,
      _) {
    handleSuperSendSet(node);
  }

  @override
  void visitUnresolvedSuperSetterCompoundIndexSet(
      ast.Send node,
      MethodElement getter,
      Element element,
      ast.Node index,
      AssignmentOperator operator,
      ast.Node rhs,
      _) {
    handleSuperSendSet(node);
  }

  @override
  void visitUnresolvedSuperCompoundIndexSet(
      ast.Send node,
      Element element,
      ast.Node index,
      AssignmentOperator operator,
      ast.Node rhs,
      _) {
    handleSuperSendSet(node);
  }

  @override
  void visitSuperFieldCompound(
      ast.Send node,
      FieldElement field,
      AssignmentOperator operator,
      ast.Node rhs,
      _) {
    handleSuperSendSet(node);
  }

  @override
  void visitFinalSuperFieldCompound(
      ast.Send node,
      FieldElement field,
      AssignmentOperator operator,
      ast.Node rhs,
      _) {
    handleSuperSendSet(node);
  }

  @override
  void visitFinalSuperFieldPrefix(
      ast.Send node,
      FieldElement field,
      IncDecOperator operator,
      _) {
    handleSuperSendSet(node);
  }

  @override
  void visitUnresolvedSuperPrefix(
      ast.Send node,
      Element element,
      IncDecOperator operator,
      _) {
    handleSuperSendSet(node);
  }

  @override
  void visitUnresolvedSuperPostfix(
      ast.Send node,
      Element element,
      IncDecOperator operator,
      _) {
    handleSuperSendSet(node);
  }

  @override
  void visitUnresolvedSuperCompound(
      ast.Send node,
      Element element,
      AssignmentOperator operator,
      ast.Node rhs,
      _) {
    handleSuperSendSet(node);
  }

  @override
  void visitFinalSuperFieldPostfix(
      ast.Send node,
      FieldElement field,
      IncDecOperator operator,
      _) {
    handleSuperSendSet(node);
  }

  @override
  void visitSuperFieldFieldCompound(
      ast.Send node,
      FieldElement readField,
      FieldElement writtenField,
      AssignmentOperator operator,
      ast.Node rhs,
      _) {
    handleSuperSendSet(node);
  }

  @override
  void visitSuperGetterSetterCompound(
      ast.Send node,
      FunctionElement getter,
      FunctionElement setter,
      AssignmentOperator operator,
      ast.Node rhs,
      _) {
    handleSuperSendSet(node);
  }

  @override
  void visitSuperMethodSetterCompound(
      ast.Send node,
      FunctionElement method,
      FunctionElement setter,
      AssignmentOperator operator,
      ast.Node rhs,
      _) {
    handleSuperSendSet(node);
  }

  @override
  void visitSuperMethodCompound(
      ast.Send node,
      FunctionElement method,
      AssignmentOperator operator,
      ast.Node rhs,
      _) {
    handleSuperSendSet(node);
  }

  @override
  void visitUnresolvedSuperGetterCompound(
      ast.Send node,
      Element element,
      MethodElement setter,
      AssignmentOperator operator,
      ast.Node rhs,
      _) {
    handleSuperSendSet(node);
  }

  @override
  void visitUnresolvedSuperSetterCompound(
      ast.Send node,
      MethodElement getter,
      Element element,
      AssignmentOperator operator,
      ast.Node rhs,
      _) {
    handleSuperSendSet(node);
  }

  @override
  void visitSuperFieldSetterCompound(
      ast.Send node,
      FieldElement field,
      FunctionElement setter,
      AssignmentOperator operator,
      ast.Node rhs,
      _) {
    handleSuperSendSet(node);
  }

  @override
  void visitSuperGetterFieldCompound(
      ast.Send node,
      FunctionElement getter,
      FieldElement field,
      AssignmentOperator operator,
      ast.Node rhs,
      _) {
    handleSuperSendSet(node);
  }

  @override
  void visitIndexSet(
      ast.SendSet node,
      ast.Node receiver,
      ast.Node index,
      ast.Node rhs,
      _) {
    generateDynamicSend(node);
  }

  @override
  void visitCompoundIndexSet(
      ast.SendSet node,
      ast.Node receiver,
      ast.Node index,
      AssignmentOperator operator,
      ast.Node rhs,
      _) {
    generateIsDeferredLoadedCheckOfSend(node);
    handleIndexSendSet(node);
  }

  @override
  void visitIndexPrefix(
      ast.Send node,
      ast.Node receiver,
      ast.Node index,
      IncDecOperator operator,
      _) {
    generateIsDeferredLoadedCheckOfSend(node);
    handleIndexSendSet(node);
  }

  @override
  void visitIndexPostfix(
      ast.Send node,
      ast.Node receiver,
      ast.Node index,
      IncDecOperator operator,
      _) {
    generateIsDeferredLoadedCheckOfSend(node);
    handleIndexSendSet(node);
  }

  void handleIndexSendSet(ast.SendSet node) {
    ast.Operator op = node.assignmentOperator;
    if ("=" == op.source) {
      internalError(node, "Unexpected index set.");
    } else {
      visit(node.receiver);
      HInstruction receiver = pop();
      Link<ast.Node> arguments = node.arguments;
      HInstruction index;
      if (node.isIndex) {
        visit(arguments.head);
        arguments = arguments.tail;
        index = pop();
      }

      pushInvokeDynamic(
          node,
          elements.getGetterSelectorInComplexSendSet(node),
          elements.getGetterTypeMaskInComplexSendSet(node),
          [receiver, index]);
      HInstruction getterInstruction = pop();
      if (node.isIfNullAssignment) {
        // Compile x[i] ??= e as:
        //   t1 = x[i]
        //   if (t1 == null)
        //      t1 = x[i] = e;
        //   result = t1
        SsaBranchBuilder brancher = new SsaBranchBuilder(this, node);
        brancher.handleIfNull(() => stack.add(getterInstruction),
            () {
              visit(arguments.head);
              HInstruction value = pop();
              pushInvokeDynamic(
                  node,
                  elements.getSelector(node),
                  elements.getTypeMask(node),
                  [receiver, index, value]);
              pop();
              stack.add(value);
            });
      } else {
        handleComplexOperatorSend(node, getterInstruction, arguments);
        HInstruction value = pop();
        pushInvokeDynamic(
            node,
            elements.getSelector(node),
            elements.getTypeMask(node),
            [receiver, index, value]);
        pop();
        if (node.isPostfix) {
          stack.add(getterInstruction);
        } else {
          stack.add(value);
        }
      }
    }
  }

  @override
  void visitThisPropertySet(
      ast.SendSet node,
      Name name,
      ast.Node rhs,
      _) {
    generateInstanceSetterWithCompiledReceiver(
        node,
        localsHandler.readThis(),
        visitAndPop(rhs));
  }

  @override
  void visitDynamicPropertySet(
      ast.SendSet node,
      ast.Node receiver,
      Name name,
      ast.Node rhs,
      _) {
    generateInstanceSetterWithCompiledReceiver(
        node,
        generateInstanceSendReceiver(node),
        visitAndPop(rhs));
  }

  @override
  void visitIfNotNullDynamicPropertySet(
      ast.SendSet node,
      ast.Node receiver,
      Name name,
      ast.Node rhs,
      _) {
    // compile e?.x = e2 to:
    //
    // t1 = e
    // if (t1 == null)
    //   result = t1 // same as result = null
    // else
    //   result = e.x = e2
    HInstruction receiverInstruction;
    SsaBranchBuilder brancher = new SsaBranchBuilder(this, node);
    brancher.handleConditional(
        () {
          receiverInstruction = generateInstanceSendReceiver(node);
          pushCheckNull(receiverInstruction);
        },
        () => stack.add(receiverInstruction),
        () {
          generateInstanceSetterWithCompiledReceiver(
              node,
              receiverInstruction,
              visitAndPop(rhs));
        });
  }

  @override
  void visitParameterSet(
      ast.SendSet node,
      ParameterElement parameter,
      ast.Node rhs,
      _) {
    generateNonInstanceSetter(node, parameter, visitAndPop(rhs));
  }

  @override
  void visitFinalParameterSet(
      ast.SendSet node,
      ParameterElement parameter,
      ast.Node rhs,
      _) {
    generateNoSuchSetter(node, parameter, visitAndPop(rhs));
  }

  @override
  void visitLocalVariableSet(
      ast.SendSet node,
      LocalVariableElement variable,
      ast.Node rhs,
      _) {
    generateNonInstanceSetter(node, variable, visitAndPop(rhs));
  }

  @override
  void visitFinalLocalVariableSet(
      ast.SendSet node,
      LocalVariableElement variable,
      ast.Node rhs,
      _) {
    generateNoSuchSetter(node, variable, visitAndPop(rhs));
  }

  @override
  void visitLocalFunctionSet(
      ast.SendSet node,
      LocalFunctionElement function,
      ast.Node rhs,
      _) {
    generateNoSuchSetter(node, function, visitAndPop(rhs));
  }

  @override
  void visitTopLevelFieldSet(
      ast.SendSet node,
      FieldElement field,
      ast.Node rhs,
      _) {
    generateIsDeferredLoadedCheckOfSend(node);
    generateNonInstanceSetter(node, field, visitAndPop(rhs));
  }

  @override
  void visitFinalTopLevelFieldSet(
      ast.SendSet node,
      FieldElement field,
      ast.Node rhs,
      _) {
    generateIsDeferredLoadedCheckOfSend(node);
    generateNoSuchSetter(node, field, visitAndPop(rhs));
  }

  @override
  void visitTopLevelGetterSet(
      ast.SendSet node,
      GetterElement getter,
      ast.Node rhs,
      _) {
    generateIsDeferredLoadedCheckOfSend(node);
    generateNoSuchSetter(node, getter, visitAndPop(rhs));
  }

  @override
  void visitTopLevelSetterSet(
      ast.SendSet node,
      SetterElement setter,
      ast.Node rhs,
      _) {
    generateIsDeferredLoadedCheckOfSend(node);
    generateNonInstanceSetter(node, setter, visitAndPop(rhs));
  }

  @override
  void visitTopLevelFunctionSet(
      ast.SendSet node,
      MethodElement function,
      ast.Node rhs,
      _) {
    generateIsDeferredLoadedCheckOfSend(node);
    generateNoSuchSetter(node, function, visitAndPop(rhs));
  }

  @override
  void visitStaticFieldSet(
      ast.SendSet node,
      FieldElement field,
      ast.Node rhs,
      _) {
    generateIsDeferredLoadedCheckOfSend(node);
    generateNonInstanceSetter(node, field, visitAndPop(rhs));
  }

  @override
  void visitFinalStaticFieldSet(
      ast.SendSet node,
      FieldElement field,
      ast.Node rhs,
      _) {
    generateIsDeferredLoadedCheckOfSend(node);
    generateNoSuchSetter(node, field, visitAndPop(rhs));
  }

  @override
  void visitStaticGetterSet(
      ast.SendSet node,
      GetterElement getter,
      ast.Node rhs,
      _) {
    generateIsDeferredLoadedCheckOfSend(node);
    generateNoSuchSetter(node, getter, visitAndPop(rhs));
  }

  @override
  void visitStaticSetterSet(
      ast.SendSet node,
      SetterElement setter,
      ast.Node rhs,
      _) {
    generateIsDeferredLoadedCheckOfSend(node);
    generateNonInstanceSetter(node, setter, visitAndPop(rhs));
  }

  @override
  void visitStaticFunctionSet(
      ast.SendSet node,
      MethodElement function,
      ast.Node rhs,
      _) {
    generateIsDeferredLoadedCheckOfSend(node);
    generateNoSuchSetter(node, function, visitAndPop(rhs));
  }

  @override
  void visitUnresolvedSet(
      ast.SendSet node,
      Element element,
      ast.Node rhs,
      _) {
    generateIsDeferredLoadedCheckOfSend(node);
    generateNonInstanceSetter(node, element, visitAndPop(rhs));
  }

  @override
  void visitClassTypeLiteralSet(
      ast.SendSet node,
      TypeConstantExpression constant,
      ast.Node rhs,
      _) {
    generateThrowNoSuchMethod(node, constant.type.name,
                              argumentNodes: node.arguments);
  }

  @override
  void visitTypedefTypeLiteralSet(
      ast.SendSet node,
      TypeConstantExpression constant,
      ast.Node rhs,
      _) {
    generateThrowNoSuchMethod(node, constant.type.name,
                              argumentNodes: node.arguments);
  }

  @override
  void visitDynamicTypeLiteralSet(
      ast.SendSet node,
      TypeConstantExpression constant,
      ast.Node rhs,
      _) {
    generateThrowNoSuchMethod(node, constant.type.name,
                              argumentNodes: node.arguments);
  }

  @override
  void visitTypeVariableTypeLiteralSet(
      ast.SendSet node,
      TypeVariableElement element,
      ast.Node rhs,
      _) {
    generateThrowNoSuchMethod(node, element.name,
                              argumentNodes: node.arguments);
  }

  void handleCompoundSendSet(ast.SendSet node) {
    Element element = elements[node];
    Element getter = elements[node.selector];

    if (!Elements.isUnresolved(getter) && getter.impliesType) {
      if (node.isIfNullAssignment) {
        // C ??= x is compiled just as C.
        stack.add(addConstant(node.selector));
      } else {
        ast.Identifier selector = node.selector;
        generateThrowNoSuchMethod(node, selector.source,
                                  argumentNodes: node.arguments);
      }
      return;
    }

    if (Elements.isInstanceSend(node, elements)) {
      void generateAssignment(HInstruction receiver) {
        // desugars `e.x op= e2` to `e.x = e.x op e2`
        generateInstanceGetterWithCompiledReceiver(
            node,
            elements.getGetterSelectorInComplexSendSet(node),
            elements.getGetterTypeMaskInComplexSendSet(node),
            receiver);
        HInstruction getterInstruction = pop();
        if (node.isIfNullAssignment) {
          SsaBranchBuilder brancher = new SsaBranchBuilder(this, node);
          brancher.handleIfNull(() => stack.add(getterInstruction),
              () {
                visit(node.arguments.head);
                generateInstanceSetterWithCompiledReceiver(
                    node, receiver, pop());
              });
        } else {
          handleComplexOperatorSend(node, getterInstruction, node.arguments);
          HInstruction value = pop();
          generateInstanceSetterWithCompiledReceiver(node, receiver, value);
        }
        if (node.isPostfix) {
          pop();
          stack.add(getterInstruction);
        }
      }
      if (node.isConditional) {
        // generate `e?.x op= e2` as:
        //   t1 = e
        //   t1 == null ? t1 : (t1.x = t1.x op e2);
        HInstruction receiver;
        SsaBranchBuilder brancher = new SsaBranchBuilder(this, node);
        brancher.handleConditional(
            () {
              receiver = generateInstanceSendReceiver(node);
              pushCheckNull(receiver);
            },
            () => stack.add(receiver),
            () => generateAssignment(receiver));
      } else {
        generateAssignment(generateInstanceSendReceiver(node));
      }
      return;
    }

    if (getter.isMalformed) {
      generateStaticUnresolvedGet(node, getter);
    } else if (getter.isField) {
      generateStaticFieldGet(node, getter);
    } else if (getter.isGetter) {
      generateStaticGetterGet(node, getter);
    } else if (getter.isFunction) {
      generateStaticFunctionGet(node, getter);
    } else if (getter.isLocal) {
      handleLocalGet(node, getter);
    } else {
      internalError(node, "Unexpected getter: $getter");
    }
    HInstruction getterInstruction = pop();
    if (node.isIfNullAssignment) {
      SsaBranchBuilder brancher = new SsaBranchBuilder(this, node);
      brancher.handleIfNull(() => stack.add(getterInstruction),
          () {
            visit(node.arguments.head);
            generateNonInstanceSetter(node, element, pop());
          });
    } else {
      handleComplexOperatorSend(node, getterInstruction, node.arguments);
      HInstruction value = pop();
      generateNonInstanceSetter(node, element, value);
    }
    if (node.isPostfix) {
      pop();
      stack.add(getterInstruction);
    }
  }

  @override
  void handleDynamicCompounds(
      ast.Send node,
      ast.Node receiver,
      Name name,
      CompoundRhs rhs,
      _) {
    handleCompoundSendSet(node);
  }

  @override
  void handleLocalCompounds(
      ast.SendSet node,
      LocalElement local,
      CompoundRhs rhs,
      _,
      {bool isSetterValid}) {
    handleCompoundSendSet(node);
  }

  @override
  void handleStaticCompounds(
      ast.SendSet node,
      Element getter,
      CompoundGetter getterKind,
      Element setter,
      CompoundSetter setterKind,
      CompoundRhs rhs,
      _) {
    handleCompoundSendSet(node);
  }

  @override
  handleDynamicSetIfNulls(
      ast.Send node,
      ast.Node receiver,
      Name name,
      ast.Node rhs,
      arg) {
    handleCompoundSendSet(node);
  }

  @override
  handleLocalSetIfNulls(
      ast.SendSet node,
      LocalElement local,
      ast.Node rhs,
      arg,
      {bool isSetterValid}) {
    handleCompoundSendSet(node);
  }

  @override
  handleStaticSetIfNulls(
      ast.SendSet node,
      Element getter,
      CompoundGetter getterKind,
      Element setter,
      CompoundSetter setterKind,
      ast.Node rhs,
      arg) {
    handleCompoundSendSet(node);
  }

  @override
  handleSuperSetIfNulls(
      ast.SendSet node,
      Element getter,
      CompoundGetter getterKind,
      Element setter,
      CompoundSetter setterKind,
      ast.Node rhs,
      arg) {
    handleSuperSendSet(node);
  }

  @override
  handleTypeLiteralConstantSetIfNulls(
      ast.SendSet node,
      ConstantExpression constant,
      ast.Node rhs,
      arg) {
    // The type variable is never `null`.
    generateConstantTypeLiteral(node);
  }

  @override
  visitTypeVariableTypeLiteralSetIfNull(
      ast.Send node,
      TypeVariableElement element,
      ast.Node rhs,
      arg) {
    // The type variable is never `null`.
    generateTypeVariableLiteral(node, element.type);
  }

  void visitLiteralInt(ast.LiteralInt node) {
    stack.add(graph.addConstantInt(node.value, compiler));
  }

  void visitLiteralDouble(ast.LiteralDouble node) {
    stack.add(graph.addConstantDouble(node.value, compiler));
  }

  void visitLiteralBool(ast.LiteralBool node) {
    stack.add(graph.addConstantBool(node.value, compiler));
  }

  void visitLiteralString(ast.LiteralString node) {
    stack.add(graph.addConstantString(node.dartString, compiler));
  }

  void visitLiteralSymbol(ast.LiteralSymbol node) {
    stack.add(addConstant(node));
    registry?.registerConstSymbol(node.slowNameString);
  }

  void visitStringJuxtaposition(ast.StringJuxtaposition node) {
    if (!node.isInterpolation) {
      // This is a simple string with no interpolations.
      stack.add(graph.addConstantString(node.dartString, compiler));
      return;
    }
    StringBuilderVisitor stringBuilder = new StringBuilderVisitor(this, node);
    stringBuilder.visit(node);
    stack.add(stringBuilder.result);
  }

  void visitLiteralNull(ast.LiteralNull node) {
    stack.add(graph.addConstantNull(compiler));
  }

  visitNodeList(ast.NodeList node) {
    for (Link<ast.Node> link = node.nodes; !link.isEmpty; link = link.tail) {
      if (isAborted()) {
        reporter.reportHintMessage(
            link.head,
            MessageKind.GENERIC,
            {'text': 'dead code'});
      } else {
        visit(link.head);
      }
    }
  }

  void visitParenthesizedExpression(ast.ParenthesizedExpression node) {
    visit(node.expression);
  }

  visitOperator(ast.Operator node) {
    // Operators are intercepted in their surrounding Send nodes.
    reporter.internalError(node,
        'SsaBuilder.visitOperator should not be called.');
  }

  visitCascade(ast.Cascade node) {
    visit(node.expression);
    // Remove the result and reveal the duplicated receiver on the stack.
    pop();
  }

  visitCascadeReceiver(ast.CascadeReceiver node) {
    visit(node.expression);
    dup();
  }

  void handleInTryStatement() {
    if (!inTryStatement) return;
    HBasicBlock block = close(new HExitTry());
    HBasicBlock newBlock = graph.addNewBlock();
    block.addSuccessor(newBlock);
    open(newBlock);
  }

  visitRethrow(ast.Rethrow node) {
    HInstruction exception = rethrowableException;
    if (exception == null) {
      exception = graph.addConstantNull(compiler);
      reporter.internalError(node,
          'rethrowableException should not be null.');
    }
    handleInTryStatement();
    closeAndGotoExit(
        new HThrow(exception,
                   sourceInformationBuilder.buildThrow(node),
                   isRethrow: true));
  }

  visitRedirectingFactoryBody(ast.RedirectingFactoryBody node) {
    ConstructorElement targetConstructor =
        elements.getRedirectingTargetConstructor(node).implementation;
    ConstructorElement redirectingConstructor = sourceElement.implementation;
    List<HInstruction> inputs = <HInstruction>[];
    FunctionSignature targetSignature = targetConstructor.functionSignature;
    FunctionSignature redirectingSignature =
        redirectingConstructor.functionSignature;

    List<Element> targetRequireds = targetSignature.requiredParameters;
    List<Element> redirectingRequireds
        = redirectingSignature.requiredParameters;

    List<Element> targetOptionals =
        targetSignature.orderedOptionalParameters;
    List<Element> redirectingOptionals =
        redirectingSignature.orderedOptionalParameters;

    // TODO(25579): This code can do the wrong thing redirecting constructor and
    // the target do not correspond. It is correct if there is no
    // warning. Ideally the redirecting constructor and the target would be the
    // same function.

    void loadLocal(ParameterElement parameter) {
      inputs.add(localsHandler.readLocal(parameter));
    }
    void loadPosition(int position, ParameterElement optionalParameter) {
      if (position < redirectingRequireds.length) {
        loadLocal(redirectingRequireds[position]);
      } else if (position < redirectingSignature.parameterCount &&
                 !redirectingSignature.optionalParametersAreNamed) {
        loadLocal(redirectingOptionals[position - redirectingRequireds.length]);
      } else if (optionalParameter != null) {
        inputs.add(handleConstantForOptionalParameter(optionalParameter));
      } else {
        // Wrong.
        inputs.add(graph.addConstantNull(compiler));
      }
    }

    int position = 0;

    for (ParameterElement targetParameter in targetRequireds) {
      loadPosition(position++, null);
    }

    if (targetOptionals.isNotEmpty) {
      if (targetSignature.optionalParametersAreNamed) {
        for (ParameterElement parameter in targetOptionals) {
          ParameterElement redirectingParameter =
              redirectingOptionals.firstWhere(
                  (p) => p.name == parameter.name,
                  orElse: () => null);
          if (redirectingParameter == null) {
            inputs.add(handleConstantForOptionalParameter(parameter));
          } else {
            inputs.add(localsHandler.readLocal(redirectingParameter));
          }
        }
      } else {
        for (ParameterElement parameter in targetOptionals) {
          loadPosition(position++, parameter);
        }
      }
    }

    ClassElement targetClass = targetConstructor.enclosingClass;
    if (backend.classNeedsRti(targetClass)) {
      ClassElement cls = redirectingConstructor.enclosingClass;
      InterfaceType targetType =
          redirectingConstructor.computeEffectiveTargetType(cls.thisType);
      targetType = localsHandler.substInContext(targetType);
      targetType.typeArguments.forEach((DartType argument) {
        inputs.add(analyzeTypeArgument(argument));
      });
    }
    pushInvokeStatic(node, targetConstructor, inputs);
    HInstruction value = pop();
    emitReturn(value, node);
  }

  /// Returns true if the [type] is a valid return type for an asynchronous
  /// function.
  ///
  /// Asynchronous functions return a `Future`, and a valid return is thus
  /// either dynamic, Object, or Future.
  ///
  /// We do not accept the internal Future implementation class.
  bool isValidAsyncReturnType(DartType type) {
    assert (isBuildingAsyncFunction);
    // TODO(sigurdm): In an internal library a function could be declared:
    //
    // _FutureImpl foo async => 1;
    //
    // This should be valid (because the actual value returned from an async
    // function is a `_FutureImpl`), but currently false is returned in this
    // case.
    return type.isDynamic ||
           type.isObject ||
           (type is InterfaceType &&
               type.element == coreClasses.futureClass);
  }

  visitReturn(ast.Return node) {
    if (identical(node.beginToken.stringValue, 'native')) {
      native.handleSsaNative(this, node.expression);
      return;
    }
    HInstruction value;
    if (node.expression == null) {
      value = graph.addConstantNull(compiler);
    } else {
      visit(node.expression);
      value = pop();
      if (isBuildingAsyncFunction) {
        if (compiler.enableTypeAssertions &&
            !isValidAsyncReturnType(returnType)) {
          String message =
                "Async function returned a Future, "
                "was declared to return a $returnType.";
          generateTypeError(node, message);
          pop();
          return;
        }
      } else {
        value = potentiallyCheckOrTrustType(value, returnType);
      }
    }

    handleInTryStatement();
    emitReturn(value, node);
  }

  visitThrow(ast.Throw node) {
    visitThrowExpression(node.expression);
    if (isReachable) {
      handleInTryStatement();
      push(new HThrowExpression(
          pop(), sourceInformationBuilder.buildThrow(node)));
      isReachable = false;
    }
  }

  visitYield(ast.Yield node) {
    visit(node.expression);
    HInstruction yielded = pop();
    add(new HYield(yielded, node.hasStar));
  }

  visitAwait(ast.Await node) {
    visit(node.expression);
    HInstruction awaited = pop();
    // TODO(herhut): Improve this type.
    push(new HAwait(awaited, new TypeMask.subclass(
        coreClasses.objectClass, compiler.world)));
  }

  visitTypeAnnotation(ast.TypeAnnotation node) {
    reporter.internalError(node,
        'Visiting type annotation in SSA builder.');
  }

  visitVariableDefinitions(ast.VariableDefinitions node) {
    assert(isReachable);
    for (Link<ast.Node> link = node.definitions.nodes;
         !link.isEmpty;
         link = link.tail) {
      ast.Node definition = link.head;
      LocalElement local = elements[definition];
      if (definition is ast.Identifier) {
        HInstruction initialValue = graph.addConstantNull(compiler);
        localsHandler.updateLocal(local, initialValue);
      } else {
        ast.SendSet node = definition;
        generateNonInstanceSetter(
            node, local, visitAndPop(node.arguments.first));
        pop();  // Discard value.
      }
    }
  }

  HInstruction setRtiIfNeeded(HInstruction object, ast.Node node) {
    InterfaceType type = localsHandler.substInContext(elements.getType(node));
    if (!backend.classNeedsRti(type.element) || type.treatAsRaw) {
      return object;
    }
    List<HInstruction> arguments = <HInstruction>[];
    for (DartType argument in type.typeArguments) {
      arguments.add(analyzeTypeArgument(argument));
    }
    // TODO(15489): Register at codegen.
    registry?.registerInstantiation(type);
    return callSetRuntimeTypeInfo(type.element, arguments, object);
  }

  visitLiteralList(ast.LiteralList node) {
    HInstruction instruction;

    if (node.isConst) {
      instruction = addConstant(node);
    } else {
      List<HInstruction> inputs = <HInstruction>[];
      for (Link<ast.Node> link = node.elements.nodes;
           !link.isEmpty;
           link = link.tail) {
        visit(link.head);
        inputs.add(pop());
      }
      instruction = buildLiteralList(inputs);
      add(instruction);
      instruction = setRtiIfNeeded(instruction, node);
    }

    TypeMask type =
        TypeMaskFactory.inferredForNode(sourceElement, node, compiler);
    if (!type.containsAll(compiler.world)) instruction.instructionType = type;
    stack.add(instruction);
  }

  visitConditional(ast.Conditional node) {
    SsaBranchBuilder brancher = new SsaBranchBuilder(this, node);
    brancher.handleConditional(() => visit(node.condition),
                               () => visit(node.thenExpression),
                               () => visit(node.elseExpression));
  }

  visitStringInterpolation(ast.StringInterpolation node) {
    StringBuilderVisitor stringBuilder = new StringBuilderVisitor(this, node);
    stringBuilder.visit(node);
    stack.add(stringBuilder.result);
  }

  visitStringInterpolationPart(ast.StringInterpolationPart node) {
    // The parts are iterated in visitStringInterpolation.
    reporter.internalError(node,
      'SsaBuilder.visitStringInterpolation should not be called.');
  }

  visitEmptyStatement(ast.EmptyStatement node) {
    // Do nothing, empty statement.
  }

  visitModifiers(ast.Modifiers node) {
    compiler.unimplemented(node, 'SsaFromAstMixin.visitModifiers.');
  }

  visitBreakStatement(ast.BreakStatement node) {
    assert(!isAborted());
    handleInTryStatement();
    JumpTarget target = elements.getTargetOf(node);
    assert(target != null);
    JumpHandler handler = jumpTargets[target];
    assert(handler != null);
    if (node.target == null) {
      handler.generateBreak();
    } else {
      LabelDefinition label = elements.getTargetLabel(node);
      handler.generateBreak(label);
    }
  }

  visitContinueStatement(ast.ContinueStatement node) {
    handleInTryStatement();
    JumpTarget target = elements.getTargetOf(node);
    assert(target != null);
    JumpHandler handler = jumpTargets[target];
    assert(handler != null);
    if (node.target == null) {
      handler.generateContinue();
    } else {
      LabelDefinition label = elements.getTargetLabel(node);
      assert(label != null);
      handler.generateContinue(label);
    }
  }

  /**
   * Creates a [JumpHandler] for a statement. The node must be a jump
   * target. If there are no breaks or continues targeting the statement,
   * a special "null handler" is returned.
   *
   * [isLoopJump] is [:true:] when the jump handler is for a loop. This is used
   * to distinguish the synthetized loop created for a switch statement with
   * continue statements from simple switch statements.
   */
  JumpHandler createJumpHandler(ast.Statement node, {bool isLoopJump}) {
    JumpTarget element = elements.getTargetDefinition(node);
    if (element == null || !identical(element.statement, node)) {
      // No breaks or continues to this node.
      return new NullJumpHandler(reporter);
    }
    if (isLoopJump && node is ast.SwitchStatement) {
      // Create a special jump handler for loops created for switch statements
      // with continue statements.
      return new SwitchCaseJumpHandler(this, element, node);
    }
    return new JumpHandler(this, element);
  }

  visitAsyncForIn(ast.AsyncForIn node) {
    // The async-for is implemented with a StreamIterator.
    HInstruction streamIterator;

    visit(node.expression);
    HInstruction expression = pop();
    pushInvokeStatic(node,
                     helpers.streamIteratorConstructor,
                     [expression, graph.addConstantNull(compiler)]);
    streamIterator = pop();

    void buildInitializer() {}

    HInstruction buildCondition() {
      Selector selector = Selectors.moveNext;
      TypeMask mask = elements.getMoveNextTypeMask(node);
      pushInvokeDynamic(node, selector, mask, [streamIterator]);
      HInstruction future = pop();
      push(new HAwait(future,
          new TypeMask.subclass(coreClasses.objectClass, compiler.world)));
      return popBoolified();
    }
    void buildBody() {
      Selector call = Selectors.current;
      TypeMask callMask = elements.getCurrentTypeMask(node);
      pushInvokeDynamic(node, call, callMask, [streamIterator]);

      ast.Node identifier = node.declaredIdentifier;
      Element variable = elements.getForInVariable(node);
      Selector selector = elements.getSelector(identifier);
      TypeMask mask = elements.getTypeMask(identifier);

      HInstruction value = pop();
      if (identifier.asSend() != null
          && Elements.isInstanceSend(identifier, elements)) {
        HInstruction receiver = generateInstanceSendReceiver(identifier);
        assert(receiver != null);
        generateInstanceSetterWithCompiledReceiver(
            null,
            receiver,
            value,
            selector: selector,
            mask: mask,
            location: identifier);
      } else {
        generateNonInstanceSetter(
            null, variable, value, location: identifier);
      }
      pop(); // Pop the value pushed by the setter call.

      visit(node.body);
    }

    void buildUpdate() {};

    buildProtectedByFinally(() {
      handleLoop(node,
                 buildInitializer,
                 buildCondition,
                 buildUpdate,
                 buildBody);
    }, () {
      pushInvokeDynamic(node,
          Selectors.cancel,
          null,
          [streamIterator]);
      push(new HAwait(pop(), new TypeMask.subclass(
          coreClasses.objectClass, compiler.world)));
      pop();
    });
  }

  visitSyncForIn(ast.SyncForIn node) {
    // The 'get iterator' selector for this node has the inferred receiver type.
    // If the receiver supports JavaScript indexing we generate an indexing loop
    // instead of allocating an iterator object.

    // This scheme recognizes for-in on direct lists.  It does not recognize all
    // uses of ArrayIterator.  They still occur when the receiver is an Iterable
    // with a `get iterator` method that delegate to another Iterable and the
    // method is inlined.  We would require full scalar replacement in that
    // case.

    Selector selector = Selectors.iterator;
    TypeMask mask = elements.getIteratorTypeMask(node);

    ClassWorld classWorld = compiler.world;
    if (mask != null &&
        mask.satisfies(helpers.jsIndexableClass, classWorld) &&
        // String is indexable but not iterable.
        !mask.satisfies(helpers.jsStringClass, classWorld)) {
      return buildSyncForInIndexable(node, mask);
    }
    buildSyncForInIterator(node);
  }

  buildSyncForInIterator(ast.SyncForIn node) {
    // Generate a structure equivalent to:
    //   Iterator<E> $iter = <iterable>.iterator;
    //   while ($iter.moveNext()) {
    //     <declaredIdentifier> = $iter.current;
    //     <body>
    //   }

    // The iterator is shared between initializer, condition and body.
    HInstruction iterator;

    void buildInitializer() {
      Selector selector = Selectors.iterator;
      TypeMask mask = elements.getIteratorTypeMask(node);
      visit(node.expression);
      HInstruction receiver = pop();
      pushInvokeDynamic(node, selector, mask, [receiver]);
      iterator = pop();
    }

    HInstruction buildCondition() {
      Selector selector = Selectors.moveNext;
      TypeMask mask = elements.getMoveNextTypeMask(node);
      pushInvokeDynamic(node, selector, mask, [iterator]);
      return popBoolified();
    }

    void buildBody() {
      Selector call = Selectors.current;
      TypeMask mask = elements.getCurrentTypeMask(node);
      pushInvokeDynamic(node, call, mask, [iterator]);
      buildAssignLoopVariable(node, pop());
      visit(node.body);
    }

    handleLoop(node, buildInitializer, buildCondition, () {}, buildBody);
  }

  buildAssignLoopVariable(ast.ForIn node, HInstruction value) {
    ast.Node identifier = node.declaredIdentifier;
    Element variable = elements.getForInVariable(node);
    Selector selector = elements.getSelector(identifier);
    TypeMask mask = elements.getTypeMask(identifier);

    if (identifier.asSend() != null &&
        Elements.isInstanceSend(identifier, elements)) {
      HInstruction receiver = generateInstanceSendReceiver(identifier);
      assert(receiver != null);
      generateInstanceSetterWithCompiledReceiver(
          null,
          receiver,
          value,
          selector: selector,
          mask: mask,
          location: identifier);
    } else {
      generateNonInstanceSetter(null, variable, value, location: identifier);
    }
    pop();  // Discard the value pushed by the setter call.
  }

  buildSyncForInIndexable(ast.ForIn node, TypeMask arrayType) {
    // Generate a structure equivalent to:
    //
    //     int end = a.length;
    //     for (int i = 0;
    //          i < a.length;
    //          checkConcurrentModificationError(a.length == end, a), ++i) {
    //       <declaredIdentifier> = a[i];
    //       <body>
    //     }
    Element loopVariable = elements.getForInVariable(node);
    SyntheticLocal indexVariable = new SyntheticLocal('_i', loopVariable);
    TypeMask boolType = backend.boolType;

    // These variables are shared by initializer, condition, body and update.
    HInstruction array;  // Set in buildInitializer.
    bool isFixed;  // Set in buildInitializer.
    HInstruction originalLength = null;  // Set for growable lists.

    HInstruction buildGetLength() {
      Element lengthElement = helpers.jsIndexableLength;
      HFieldGet result = new HFieldGet(
          lengthElement, array, backend.positiveIntType,
          isAssignable: !isFixed);
      add(result);
      return result;
    }

    void buildConcurrentModificationErrorCheck() {
      if (originalLength == null) return;
      // The static call checkConcurrentModificationError() is expanded in
      // codegen to:
      //
      //     array.length == _end || throwConcurrentModificationError(array)
      //
      HInstruction length = buildGetLength();
      push(new HIdentity(length, originalLength, null, boolType));
      pushInvokeStatic(node,
          helpers.checkConcurrentModificationError,
          [pop(), array]);
      pop();
    }

    void buildInitializer() {
      visit(node.expression);
      array = pop();
      isFixed = isFixedLength(array.instructionType, compiler);
      localsHandler.updateLocal(indexVariable,
          graph.addConstantInt(0, compiler));
      originalLength = buildGetLength();
    }

    HInstruction buildCondition() {
      HInstruction index = localsHandler.readLocal(indexVariable);
      HInstruction length = buildGetLength();
      HInstruction compare = new HLess(index, length, null, boolType);
      add(compare);
      return compare;
    }

    void buildBody() {
      // If we had mechanically inlined ArrayIterator.moveNext(), it would have
      // inserted the ConcurrentModificationError check as part of the
      // condition.  It is not necessary on the first iteration since there is
      // no code between calls to `get iterator` and `moveNext`, so the test is
      // moved to the loop update.

      // Find a type for the element. Use the element type of the indexer of the
      // array, as this is stronger than the iterator's `get current` type, for
      // example, `get current` includes null.
      // TODO(sra): The element type of a container type mask might be better.
      Selector selector = new Selector.index();
      TypeMask type = TypeMaskFactory.inferredTypeForSelector(
          selector, arrayType, compiler);

      HInstruction index = localsHandler.readLocal(indexVariable);
      HInstruction value = new HIndex(array, index, null, type);
      add(value);

      buildAssignLoopVariable(node, value);
      visit(node.body);
    }

    void buildUpdate() {
      // See buildBody as to why we check here.
      buildConcurrentModificationErrorCheck();

      // TODO(sra): It would be slightly shorter to generate `a[i++]` in the
      // body (and that more closely follows what an inlined iterator would do)
      // but the code is horrible as `i+1` is carried around the loop in an
      // additional variable.
      HInstruction index = localsHandler.readLocal(indexVariable);
      HInstruction one = graph.addConstantInt(1, compiler);
      HInstruction addInstruction =
          new HAdd(index, one, null, backend.positiveIntType);
      add(addInstruction);
      localsHandler.updateLocal(indexVariable, addInstruction);
    }

    handleLoop(node, buildInitializer, buildCondition, buildUpdate, buildBody);
  }

  visitLabel(ast.Label node) {
    reporter.internalError(node, 'SsaFromAstMixin.visitLabel.');
  }

  visitLabeledStatement(ast.LabeledStatement node) {
    ast.Statement body = node.statement;
    if (body is ast.Loop
        || body is ast.SwitchStatement
        || Elements.isUnusedLabel(node, elements)) {
      // Loops and switches handle their own labels.
      visit(body);
      return;
    }
    JumpTarget targetElement = elements.getTargetDefinition(body);
    LocalsHandler beforeLocals = new LocalsHandler.from(localsHandler);
    assert(targetElement.isBreakTarget);
    JumpHandler handler = new JumpHandler(this, targetElement);
    // Introduce a new basic block.
    HBasicBlock entryBlock = openNewBlock();
    visit(body);
    SubGraph bodyGraph = new SubGraph(entryBlock, lastOpenedBlock);

    HBasicBlock joinBlock = graph.addNewBlock();
    List<LocalsHandler> breakHandlers = <LocalsHandler>[];
    handler.forEachBreak((HBreak breakInstruction, LocalsHandler locals) {
      breakInstruction.block.addSuccessor(joinBlock);
      breakHandlers.add(locals);
    });
    bool hasBreak = breakHandlers.length > 0;
    if (!isAborted()) {
      goto(current, joinBlock);
      breakHandlers.add(localsHandler);
    }
    open(joinBlock);
    localsHandler = beforeLocals.mergeMultiple(breakHandlers, joinBlock);

    if (hasBreak) {
      // There was at least one reachable break, so the label is needed.
      entryBlock.setBlockFlow(
          new HLabeledBlockInformation(new HSubGraphBlockInformation(bodyGraph),
                                       handler.labels()),
          joinBlock);
    }
    handler.close();
  }

  visitLiteralMap(ast.LiteralMap node) {
    if (node.isConst) {
      stack.add(addConstant(node));
      return;
    }
    List<HInstruction> listInputs = <HInstruction>[];
    for (Link<ast.Node> link = node.entries.nodes;
         !link.isEmpty;
         link = link.tail) {
      visit(link.head);
      listInputs.add(pop());
      listInputs.add(pop());
    }

    Element constructor;
    List<HInstruction> inputs = <HInstruction>[];

    if (listInputs.isEmpty) {
      constructor = helpers.mapLiteralConstructorEmpty;
    } else {
      constructor = helpers.mapLiteralConstructor;
      HLiteralList keyValuePairs = buildLiteralList(listInputs);
      add(keyValuePairs);
      inputs.add(keyValuePairs);
    }

    assert(constructor.isFactoryConstructor);

    ConstructorElement functionElement = constructor;
    constructor = functionElement.effectiveTarget;

    InterfaceType type = elements.getType(node);
    InterfaceType expectedType =
        functionElement.computeEffectiveTargetType(type);
    expectedType = localsHandler.substInContext(expectedType);

    ClassElement cls = constructor.enclosingClass;

    if (backend.classNeedsRti(cls)) {
      List<HInstruction> typeInputs = <HInstruction>[];
      expectedType.typeArguments.forEach((DartType argument) {
        typeInputs.add(analyzeTypeArgument(argument));
      });

      // We lift this common call pattern into a helper function to save space
      // in the output.
      if (typeInputs.every((HInstruction input) => input.isNull())) {
        if (listInputs.isEmpty) {
          constructor = helpers.mapLiteralUntypedEmptyMaker;
        } else {
          constructor = helpers.mapLiteralUntypedMaker;
        }
      } else {
        inputs.addAll(typeInputs);
      }
    }

    // If rti is needed and the map literal has no type parameters,
    // 'constructor' is a static function that forwards the call to the factory
    // constructor without type parameters.
    assert(constructor is ConstructorElement || constructor is FunctionElement);

    // The instruction type will always be a subtype of the mapLiteralClass, but
    // type inference might discover a more specific type, or find nothing (in
    // dart2js unit tests).
    TypeMask mapType =
        new TypeMask.nonNullSubtype(helpers.mapLiteralClass, compiler.world);
    TypeMask returnTypeMask = TypeMaskFactory.inferredReturnTypeForElement(
        constructor, compiler);
    TypeMask instructionType =
        mapType.intersection(returnTypeMask, compiler.world);

    addInlinedInstantiation(expectedType);
    pushInvokeStatic(node, constructor, inputs,
        typeMask: instructionType, instanceType: expectedType);
    removeInlinedInstantiation(expectedType);
  }

  visitLiteralMapEntry(ast.LiteralMapEntry node) {
    visit(node.value);
    visit(node.key);
  }

  visitNamedArgument(ast.NamedArgument node) {
    visit(node.expression);
  }

  Map<ast.CaseMatch, ConstantValue> buildSwitchCaseConstants(
      ast.SwitchStatement node) {

    Map<ast.CaseMatch, ConstantValue> constants =
        new Map<ast.CaseMatch, ConstantValue>();
    for (ast.SwitchCase switchCase in node.cases) {
      for (ast.Node labelOrCase in switchCase.labelsAndCases) {
        if (labelOrCase is ast.CaseMatch) {
          ast.CaseMatch match = labelOrCase;
          ConstantValue constant = getConstantForNode(match.expression);
          constants[labelOrCase] = constant;
        }
      }
    }
    return constants;
  }

  visitSwitchStatement(ast.SwitchStatement node) {
    Map<ast.CaseMatch, ConstantValue> constants =
        buildSwitchCaseConstants(node);

    // The switch case indices must match those computed in
    // [SwitchCaseJumpHandler].
    bool hasContinue = false;
    Map<ast.SwitchCase, int> caseIndex = new Map<ast.SwitchCase, int>();
    int switchIndex = 1;
    bool hasDefault = false;
    for (ast.SwitchCase switchCase in node.cases) {
      for (ast.Node labelOrCase in switchCase.labelsAndCases) {
        ast.Node label = labelOrCase.asLabel();
        if (label != null) {
          LabelDefinition labelElement = elements.getLabelDefinition(label);
          if (labelElement != null && labelElement.isContinueTarget) {
            hasContinue = true;
          }
        }
      }
      if (switchCase.isDefaultCase) {
        hasDefault = true;
      }
      caseIndex[switchCase] = switchIndex;
      switchIndex++;
    }
    if (!hasContinue) {
      // If the switch statement has no switch cases targeted by continue
      // statements we encode the switch statement directly.
      buildSimpleSwitchStatement(node, constants);
    } else {
      buildComplexSwitchStatement(node, constants, caseIndex, hasDefault);
    }
  }

  /**
   * Builds a simple switch statement which does not handle uses of continue
   * statements to labeled switch cases.
   */
  void buildSimpleSwitchStatement(ast.SwitchStatement node,
                                  Map<ast.CaseMatch, ConstantValue> constants) {
    JumpHandler jumpHandler = createJumpHandler(node, isLoopJump: false);
    HInstruction buildExpression() {
      visit(node.expression);
      return pop();
    }
    Iterable<ConstantValue> getConstants(ast.SwitchCase switchCase) {
      List<ConstantValue> constantList = <ConstantValue>[];
      for (ast.Node labelOrCase in switchCase.labelsAndCases) {
        if (labelOrCase is ast.CaseMatch) {
          constantList.add(constants[labelOrCase]);
        }
      }
      return constantList;
    }
    bool isDefaultCase(ast.SwitchCase switchCase) {
      return switchCase.isDefaultCase;
    }
    void buildSwitchCase(ast.SwitchCase node) {
      visit(node.statements);
    }
    handleSwitch(node,
                 jumpHandler,
                 buildExpression,
                 node.cases,
                 getConstants,
                 isDefaultCase,
                 buildSwitchCase);
    jumpHandler.close();
  }

  /**
   * Builds a switch statement that can handle arbitrary uses of continue
   * statements to labeled switch cases.
   */
  void buildComplexSwitchStatement(ast.SwitchStatement node,
                                   Map<ast.CaseMatch, ConstantValue> constants,
                                   Map<ast.SwitchCase, int> caseIndex,
                                   bool hasDefault) {
    // If the switch statement has switch cases targeted by continue
    // statements we create the following encoding:
    //
    //   switch (e) {
    //     l_1: case e0: s_1; break;
    //     l_2: case e1: s_2; continue l_i;
    //     ...
    //     l_n: default: s_n; continue l_j;
    //   }
    //
    // is encoded as
    //
    //   var target;
    //   switch (e) {
    //     case e1: target = 1; break;
    //     case e2: target = 2; break;
    //     ...
    //     default: target = n; break;
    //   }
    //   l: while (true) {
    //    switch (target) {
    //       case 1: s_1; break l;
    //       case 2: s_2; target = i; continue l;
    //       ...
    //       case n: s_n; target = j; continue l;
    //     }
    //   }

    JumpTarget switchTarget = elements.getTargetDefinition(node);
    HInstruction initialValue = graph.addConstantNull(compiler);
    localsHandler.updateLocal(switchTarget, initialValue);

    JumpHandler jumpHandler = createJumpHandler(node, isLoopJump: false);
    var switchCases = node.cases;
    if (!hasDefault) {
      // Use [:null:] as the marker for a synthetic default clause.
      // The synthetic default is added because otherwise, there would be no
      // good place to give a default value to the local.
      switchCases = node.cases.nodes.toList()..add(null);
    }
    HInstruction buildExpression() {
      visit(node.expression);
      return pop();
    }
    Iterable<ConstantValue> getConstants(ast.SwitchCase switchCase) {
      List<ConstantValue> constantList = <ConstantValue>[];
      if (switchCase != null) {
        for (ast.Node labelOrCase in switchCase.labelsAndCases) {
          if (labelOrCase is ast.CaseMatch) {
            constantList.add(constants[labelOrCase]);
          }
        }
      }
      return constantList;
    }
    bool isDefaultCase(ast.SwitchCase switchCase) {
      return switchCase == null || switchCase.isDefaultCase;
    }
    void buildSwitchCase(ast.SwitchCase switchCase) {
      if (switchCase != null) {
        // Generate 'target = i; break;' for switch case i.
        int index = caseIndex[switchCase];
        HInstruction value = graph.addConstantInt(index, compiler);
        localsHandler.updateLocal(switchTarget, value);
      } else {
        // Generate synthetic default case 'target = null; break;'.
        HInstruction value = graph.addConstantNull(compiler);
        localsHandler.updateLocal(switchTarget, value);
      }
      jumpTargets[switchTarget].generateBreak();
    }
    handleSwitch(node,
                 jumpHandler,
                 buildExpression,
                 switchCases,
                 getConstants,
                 isDefaultCase,
                 buildSwitchCase);
    jumpHandler.close();

    HInstruction buildCondition() =>
        graph.addConstantBool(true, compiler);

    void buildSwitch() {
      HInstruction buildExpression() {
        return localsHandler.readLocal(switchTarget);
      }
      Iterable<ConstantValue> getConstants(ast.SwitchCase switchCase) {
        return <ConstantValue>[constantSystem.createInt(caseIndex[switchCase])];
      }
      void buildSwitchCase(ast.SwitchCase switchCase) {
        visit(switchCase.statements);
        if (!isAborted()) {
          // Ensure that we break the loop if the case falls through. (This
          // is only possible for the last case.)
          jumpTargets[switchTarget].generateBreak();
        }
      }
      // Pass a [NullJumpHandler] because the target for the contained break
      // is not the generated switch statement but instead the loop generated
      // in the call to [handleLoop] below.
      handleSwitch(node,
                   new NullJumpHandler(reporter),
                   buildExpression, node.cases, getConstants,
                   (_) => false, // No case is default.
                   buildSwitchCase);
    }

    void buildLoop() {
      handleLoop(node,
          () {},
          buildCondition,
          () {},
          buildSwitch);
    }

    if (hasDefault) {
      buildLoop();
    } else {
      // If the switch statement has no default case, surround the loop with
      // a test of the target.
      void buildCondition() {
        js.Template code = js.js.parseForeignJS('#');
        push(new HForeignCode(
            code,
            backend.boolType,
            [localsHandler.readLocal(switchTarget)],
            nativeBehavior: native.NativeBehavior.PURE));
      }
      handleIf(node,
          visitCondition: buildCondition,
          visitThen: buildLoop,
          visitElse: () => {});
    }
  }

  /**
   * Creates a switch statement.
   *
   * [jumpHandler] is the [JumpHandler] for the created switch statement.
   * [buildExpression] creates the switch expression.
   * [switchCases] must be either an [Iterable] of [ast.SwitchCase] nodes or
   *   a [Link] or a [ast.NodeList] of [ast.SwitchCase] nodes.
   * [getConstants] returns the set of constants for a switch case.
   * [isDefaultCase] returns [:true:] if the provided switch case should be
   *   considered default for the created switch statement.
   * [buildSwitchCase] creates the statements for the switch case.
   */
  void handleSwitch(
      ast.Node errorNode,
      JumpHandler jumpHandler,
      HInstruction buildExpression(),
      var switchCases,
      Iterable<ConstantValue> getConstants(ast.SwitchCase switchCase),
      bool isDefaultCase(ast.SwitchCase switchCase),
      void buildSwitchCase(ast.SwitchCase switchCase)) {

    HBasicBlock expressionStart = openNewBlock();
    HInstruction expression = buildExpression();
    if (switchCases.isEmpty) {
      return;
    }

    HSwitch switchInstruction = new HSwitch(<HInstruction>[expression]);
    HBasicBlock expressionEnd = close(switchInstruction);
    LocalsHandler savedLocals = localsHandler;

    List<HStatementInformation> statements = <HStatementInformation>[];
    bool hasDefault = false;
    Element getFallThroughErrorElement = helpers.fallThroughError;
    HasNextIterator<ast.Node> caseIterator =
        new HasNextIterator<ast.Node>(switchCases.iterator);
    while (caseIterator.hasNext) {
      ast.SwitchCase switchCase = caseIterator.next();
      HBasicBlock block = graph.addNewBlock();
      for (ConstantValue constant in getConstants(switchCase)) {
        HConstant hConstant = graph.addConstant(constant, compiler);
        switchInstruction.inputs.add(hConstant);
        hConstant.usedBy.add(switchInstruction);
        expressionEnd.addSuccessor(block);
      }

      if (isDefaultCase(switchCase)) {
        // An HSwitch has n inputs and n+1 successors, the last being the
        // default case.
        expressionEnd.addSuccessor(block);
        hasDefault = true;
      }
      open(block);
      localsHandler = new LocalsHandler.from(savedLocals);
      buildSwitchCase(switchCase);
      if (!isAborted()) {
        if (caseIterator.hasNext) {
          pushInvokeStatic(switchCase, getFallThroughErrorElement, []);
          HInstruction error = pop();
          closeAndGotoExit(new HThrow(error, error.sourceInformation));
        } else if (!isDefaultCase(switchCase)) {
          // If there is no default, we will add one later to avoid
          // the critical edge. So we generate a break statement to make
          // sure the last case does not fall through to the default case.
          jumpHandler.generateBreak();
        }
      }
      statements.add(
          new HSubGraphBlockInformation(new SubGraph(block, lastOpenedBlock)));
    }

    // Add a join-block if necessary.
    // We create [joinBlock] early, and then go through the cases that might
    // want to jump to it. In each case, if we add [joinBlock] as a successor
    // of another block, we also add an element to [caseHandlers] that is used
    // to create the phis in [joinBlock].
    // If we never jump to the join block, [caseHandlers] will stay empty, and
    // the join block is never added to the graph.
    HBasicBlock joinBlock = new HBasicBlock();
    List<LocalsHandler> caseHandlers = <LocalsHandler>[];
    jumpHandler.forEachBreak((HBreak instruction, LocalsHandler locals) {
      instruction.block.addSuccessor(joinBlock);
      caseHandlers.add(locals);
    });
    jumpHandler.forEachContinue((HContinue instruction, LocalsHandler locals) {
      assert(invariant(errorNode, false,
                       message: 'Continue cannot target a switch.'));
    });
    if (!isAborted()) {
      current.close(new HGoto());
      lastOpenedBlock.addSuccessor(joinBlock);
      caseHandlers.add(localsHandler);
    }
    if (!hasDefault) {
      // Always create a default case, to avoid a critical edge in the
      // graph.
      HBasicBlock defaultCase = addNewBlock();
      expressionEnd.addSuccessor(defaultCase);
      open(defaultCase);
      close(new HGoto());
      defaultCase.addSuccessor(joinBlock);
      caseHandlers.add(savedLocals);
      statements.add(new HSubGraphBlockInformation(new SubGraph(
          defaultCase, defaultCase)));
    }
    assert(caseHandlers.length == joinBlock.predecessors.length);
    if (caseHandlers.length != 0) {
      graph.addBlock(joinBlock);
      open(joinBlock);
      if (caseHandlers.length == 1) {
        localsHandler = caseHandlers[0];
      } else {
        localsHandler = savedLocals.mergeMultiple(caseHandlers, joinBlock);
      }
    } else {
      // The joinblock is not used.
      joinBlock = null;
    }

    HSubExpressionBlockInformation expressionInfo =
        new HSubExpressionBlockInformation(new SubExpression(expressionStart,
                                                             expressionEnd));
    expressionStart.setBlockFlow(
        new HSwitchBlockInformation(expressionInfo,
                                    statements,
                                    jumpHandler.target,
                                    jumpHandler.labels()),
        joinBlock);

    jumpHandler.close();
  }

  visitSwitchCase(ast.SwitchCase node) {
    reporter.internalError(node, 'SsaFromAstMixin.visitSwitchCase.');
  }

  visitCaseMatch(ast.CaseMatch node) {
    reporter.internalError(node, 'SsaFromAstMixin.visitCaseMatch.');
  }

  /// Calls [buildTry] inside a synthetic try block with [buildFinally] in the
  /// finally block.
  ///
  /// Note that to get the right locals behavior, the code visited by [buildTry]
  /// and [buildFinally] must have been analyzed as if inside a try-statement by
  /// [ClosureTranslator].
  void buildProtectedByFinally(void buildTry(), void buildFinally()) {
    // Save the current locals. The finally block must not reuse the existing
    // locals handler. None of the variables that have been defined in the
    // body-block will be used, but for loops we will add (unnecessary) phis
    // that will reference the body variables. This makes it look as if the
    // variables were used in a non-dominated block.
    LocalsHandler savedLocals = new LocalsHandler.from(localsHandler);
    HBasicBlock enterBlock = openNewBlock();
    HTry tryInstruction = new HTry();
    close(tryInstruction);
    bool oldInTryStatement = inTryStatement;
    inTryStatement = true;

    HBasicBlock startTryBlock;
    HBasicBlock endTryBlock;
    HBasicBlock startFinallyBlock;
    HBasicBlock endFinallyBlock;

    startTryBlock = graph.addNewBlock();
    open(startTryBlock);
    buildTry();
    // We use a [HExitTry] instead of a [HGoto] for the try block
    // because it will have two successors: the join block, and
    // the finally block.
    if (!isAborted()) endTryBlock = close(new HExitTry());
    SubGraph bodyGraph = new SubGraph(startTryBlock, lastOpenedBlock);

    SubGraph finallyGraph = null;

    localsHandler = new LocalsHandler.from(savedLocals);
    startFinallyBlock = graph.addNewBlock();
    open(startFinallyBlock);
    buildFinally();
    if (!isAborted()) endFinallyBlock = close(new HGoto());
    tryInstruction.finallyBlock = startFinallyBlock;
    finallyGraph = new SubGraph(startFinallyBlock, lastOpenedBlock);

    HBasicBlock exitBlock = graph.addNewBlock();

    void addExitTrySuccessor(HBasicBlock successor) {
      // Iterate over all blocks created inside this try/catch, and
      // attach successor information to blocks that end with
      // [HExitTry].
      for (int i = startTryBlock.id; i < successor.id; i++) {
        HBasicBlock block = graph.blocks[i];
        var last = block.last;
        if (last is HExitTry) {
          block.addSuccessor(successor);
        }
      }
    }

    // Setup all successors. The entry block that contains the [HTry]
    // has 1) the body 2) the finally, and 4) the exit
    // blocks as successors.
    enterBlock.addSuccessor(startTryBlock);
    enterBlock.addSuccessor(startFinallyBlock);
    enterBlock.addSuccessor(exitBlock);

    // The body has the finally block as successor.
    if (endTryBlock != null) {
      endTryBlock.addSuccessor(startFinallyBlock);
      endTryBlock.addSuccessor(exitBlock);
    }

    // The finally block has the exit block as successor.
    endFinallyBlock.addSuccessor(exitBlock);

    // If a block inside try/catch aborts (eg with a return statement),
    // we explicitely mark this block a predecessor of the catch
    // block and the finally block.
    addExitTrySuccessor(startFinallyBlock);

    // Use the locals handler not altered by the catch and finally
    // blocks.
    // TODO(sigurdm): We can probably do this, because try-variables are boxed.
    // Need to verify.
    localsHandler = savedLocals;
    open(exitBlock);
    enterBlock.setBlockFlow(
        new HTryBlockInformation(
          wrapStatementGraph(bodyGraph),
          null, // No catch-variable.
          null, // No catchGraph.
          wrapStatementGraph(finallyGraph)),
        exitBlock);
    inTryStatement = oldInTryStatement;
  }

  visitTryStatement(ast.TryStatement node) {
    // Save the current locals. The catch block and the finally block
    // must not reuse the existing locals handler. None of the variables
    // that have been defined in the body-block will be used, but for
    // loops we will add (unnecessary) phis that will reference the body
    // variables. This makes it look as if the variables were used
    // in a non-dominated block.
    LocalsHandler savedLocals = new LocalsHandler.from(localsHandler);
    HBasicBlock enterBlock = openNewBlock();
    HTry tryInstruction = new HTry();
    close(tryInstruction);
    bool oldInTryStatement = inTryStatement;
    inTryStatement = true;

    HBasicBlock startTryBlock;
    HBasicBlock endTryBlock;
    HBasicBlock startCatchBlock;
    HBasicBlock endCatchBlock;
    HBasicBlock startFinallyBlock;
    HBasicBlock endFinallyBlock;

    startTryBlock = graph.addNewBlock();
    open(startTryBlock);
    visit(node.tryBlock);
    // We use a [HExitTry] instead of a [HGoto] for the try block
    // because it will have multiple successors: the join block, and
    // the catch or finally block.
    if (!isAborted()) endTryBlock = close(new HExitTry());
    SubGraph bodyGraph = new SubGraph(startTryBlock, lastOpenedBlock);
    SubGraph catchGraph = null;
    HLocalValue exception = null;

    if (!node.catchBlocks.isEmpty) {
      localsHandler = new LocalsHandler.from(savedLocals);
      startCatchBlock = graph.addNewBlock();
      open(startCatchBlock);
      // Note that the name of this local is irrelevant.
      SyntheticLocal local =
          new SyntheticLocal('exception', localsHandler.executableContext);
      exception = new HLocalValue(local, backend.nonNullType);
      add(exception);
      HInstruction oldRethrowableException = rethrowableException;
      rethrowableException = exception;

      pushInvokeStatic(node, helpers.exceptionUnwrapper, [exception]);
      HInvokeStatic unwrappedException = pop();
      tryInstruction.exception = exception;
      Link<ast.Node> link = node.catchBlocks.nodes;

      void pushCondition(ast.CatchBlock catchBlock) {
        if (catchBlock.onKeyword != null) {
          DartType type = elements.getType(catchBlock.type);
          if (type == null) {
            reporter.internalError(catchBlock.type, 'On with no type.');
          }
          HInstruction condition =
              buildIsNode(catchBlock.type, type, unwrappedException);
          push(condition);
        } else {
          ast.VariableDefinitions declaration = catchBlock.formals.nodes.head;
          HInstruction condition = null;
          if (declaration.type == null) {
            condition = graph.addConstantBool(true, compiler);
            stack.add(condition);
          } else {
            // TODO(aprelev@gmail.com): Once old catch syntax is removed
            // "if" condition above and this "else" branch should be deleted as
            // type of declared variable won't matter for the catch
            // condition.
            DartType type = elements.getType(declaration.type);
            if (type == null) {
              reporter.internalError(catchBlock, 'Catch with unresolved type.');
            }
            condition = buildIsNode(declaration.type, type, unwrappedException);
            push(condition);
          }
        }
      }

      void visitThen() {
        ast.CatchBlock catchBlock = link.head;
        link = link.tail;
        if (catchBlock.exception != null) {
          LocalVariableElement exceptionVariable =
              elements[catchBlock.exception];
          localsHandler.updateLocal(exceptionVariable,
                                    unwrappedException);
        }
        ast.Node trace = catchBlock.trace;
        if (trace != null) {
          pushInvokeStatic(trace, helpers.traceFromException, [exception]);
          HInstruction traceInstruction = pop();
          LocalVariableElement traceVariable = elements[trace];
          localsHandler.updateLocal(traceVariable, traceInstruction);
        }
        visit(catchBlock);
      }

      void visitElse() {
        if (link.isEmpty) {
          closeAndGotoExit(
              new HThrow(exception,
                         exception.sourceInformation,
                         isRethrow: true));
        } else {
          ast.CatchBlock newBlock = link.head;
          handleIf(node,
                   visitCondition: () { pushCondition(newBlock); },
                   visitThen: visitThen,
                   visitElse: visitElse);
        }
      }

      ast.CatchBlock firstBlock = link.head;
      handleIf(node,
          visitCondition: () { pushCondition(firstBlock); },
          visitThen: visitThen,
          visitElse: visitElse);
      if (!isAborted()) endCatchBlock = close(new HGoto());

      rethrowableException = oldRethrowableException;
      tryInstruction.catchBlock = startCatchBlock;
      catchGraph = new SubGraph(startCatchBlock, lastOpenedBlock);
    }

    SubGraph finallyGraph = null;
    if (node.finallyBlock != null) {
      localsHandler = new LocalsHandler.from(savedLocals);
      startFinallyBlock = graph.addNewBlock();
      open(startFinallyBlock);
      visit(node.finallyBlock);
      if (!isAborted()) endFinallyBlock = close(new HGoto());
      tryInstruction.finallyBlock = startFinallyBlock;
      finallyGraph = new SubGraph(startFinallyBlock, lastOpenedBlock);
    }

    HBasicBlock exitBlock = graph.addNewBlock();

    addOptionalSuccessor(b1, b2) { if (b2 != null) b1.addSuccessor(b2); }
    addExitTrySuccessor(successor) {
      if (successor == null) return;
      // Iterate over all blocks created inside this try/catch, and
      // attach successor information to blocks that end with
      // [HExitTry].
      for (int i = startTryBlock.id; i < successor.id; i++) {
        HBasicBlock block = graph.blocks[i];
        var last = block.last;
        if (last is HExitTry) {
          block.addSuccessor(successor);
        }
      }
    }

    // Setup all successors. The entry block that contains the [HTry]
    // has 1) the body, 2) the catch, 3) the finally, and 4) the exit
    // blocks as successors.
    enterBlock.addSuccessor(startTryBlock);
    addOptionalSuccessor(enterBlock, startCatchBlock);
    addOptionalSuccessor(enterBlock, startFinallyBlock);
    enterBlock.addSuccessor(exitBlock);

    // The body has either the catch or the finally block as successor.
    if (endTryBlock != null) {
      assert(startCatchBlock != null || startFinallyBlock != null);
      endTryBlock.addSuccessor(
          startCatchBlock != null ? startCatchBlock : startFinallyBlock);
      endTryBlock.addSuccessor(exitBlock);
    }

    // The catch block has either the finally or the exit block as
    // successor.
    if (endCatchBlock != null) {
      endCatchBlock.addSuccessor(
          startFinallyBlock != null ? startFinallyBlock : exitBlock);
    }

    // The finally block has the exit block as successor.
    if (endFinallyBlock != null) {
      endFinallyBlock.addSuccessor(exitBlock);
    }

    // If a block inside try/catch aborts (eg with a return statement),
    // we explicitely mark this block a predecessor of the catch
    // block and the finally block.
    addExitTrySuccessor(startCatchBlock);
    addExitTrySuccessor(startFinallyBlock);

    // Use the locals handler not altered by the catch and finally
    // blocks.
    localsHandler = savedLocals;
    open(exitBlock);
    enterBlock.setBlockFlow(
        new HTryBlockInformation(
          wrapStatementGraph(bodyGraph),
          exception,
          wrapStatementGraph(catchGraph),
          wrapStatementGraph(finallyGraph)),
        exitBlock);
    inTryStatement = oldInTryStatement;
  }

  visitCatchBlock(ast.CatchBlock node) {
    visit(node.block);
  }

  visitTypedef(ast.Typedef node) {
    compiler.unimplemented(node, 'SsaFromAstMixin.visitTypedef.');
  }

  visitTypeVariable(ast.TypeVariable node) {
    reporter.internalError(node, 'SsaFromAstMixin.visitTypeVariable.');
  }

  /**
   * This method is invoked before inlining the body of [function] into this
   * [SsaBuilder].
   */
  void enterInlinedMethod(FunctionElement function,
                          ast.Node _,
                          List<HInstruction> compiledArguments,
                          {InterfaceType instanceType}) {
    TypesInferrer inferrer = compiler.typesTask.typesInferrer;
    AstInliningState state = new AstInliningState(
        function, returnLocal, returnType, elements, stack, localsHandler,
        inTryStatement,
        allInlinedFunctionsCalledOnce && inferrer.isCalledOnce(function));
    inliningStack.add(state);

    // Setting up the state of the (AST) builder is performed even when the
    // inlined function is in IR, because the irInliner uses the [returnElement]
    // of the AST builder.
    setupStateForInlining(
        function, compiledArguments, instanceType: instanceType);
  }

  void leaveInlinedMethod() {
    HInstruction result = localsHandler.readLocal(returnLocal);
    AstInliningState state = inliningStack.removeLast();
    restoreState(state);
    stack.add(result);
  }

  void doInline(FunctionElement function) {
    visitInlinedFunction(function);
  }

  void emitReturn(HInstruction value, ast.Node node) {
    if (inliningStack.isEmpty) {
      closeAndGotoExit(new HReturn(value,
          sourceInformationBuilder.buildReturn(node)));
    } else {
      localsHandler.updateLocal(returnLocal, value);
    }
  }

  @override
  void handleTypeLiteralConstantCompounds(
      ast.SendSet node,
      ConstantExpression constant,
      CompoundRhs rhs,
      _) {
    handleTypeLiteralCompound(node);
  }

  @override
  void handleTypeVariableTypeLiteralCompounds(
      ast.SendSet node,
      TypeVariableElement typeVariable,
      CompoundRhs rhs,
      _) {
    handleTypeLiteralCompound(node);
  }

  void handleTypeLiteralCompound(ast.SendSet node) {
    generateIsDeferredLoadedCheckOfSend(node);
    ast.Identifier selector = node.selector;
    generateThrowNoSuchMethod(node, selector.source,
                              argumentNodes: node.arguments);
  }

  @override
  void visitConstantGet(
    ast.Send node,
    ConstantExpression constant,
    _) {
    visitNode(node);
  }

  @override
  void visitConstantInvoke(
    ast.Send node,
    ConstantExpression constant,
    ast.NodeList arguments,
    CallStructure callStreucture,
    _) {
    visitNode(node);
  }

  @override
  void errorUndefinedBinaryExpression(
      ast.Send node,
      ast.Node left,
      ast.Operator operator,
      ast.Node right,
      _) {
    visitNode(node);
  }

  @override
  void errorUndefinedUnaryExpression(
      ast.Send node,
      ast.Operator operator,
      ast.Node expression,
      _) {
    visitNode(node);
  }

  @override
  void bulkHandleError(ast.Node node, ErroneousElement error, _) {
    // TODO(johnniwinther): Use an uncatchable error when supported.
    generateRuntimeError(node, error.message);
  }
}

/**
 * Visitor that handles generation of string literals (LiteralString,
 * StringInterpolation), and otherwise delegates to the given visitor for
 * non-literal subexpressions.
 */
class StringBuilderVisitor extends ast.Visitor {
  final SsaBuilder builder;
  final ast.Node diagnosticNode;

  /**
   * The string value generated so far.
   */
  HInstruction result = null;

  StringBuilderVisitor(this.builder, this.diagnosticNode);

  Compiler get compiler => builder.compiler;

  void visit(ast.Node node) {
    node.accept(this);
  }

  visitNode(ast.Node node) {
    builder.reporter.internalError(node, 'Unexpected node.');
  }

  void visitExpression(ast.Node node) {
    node.accept(builder);
    HInstruction expression = builder.pop();

    // We want to use HStringify when:
    //   1. The value is known to be a primitive type, because it might get
    //      constant-folded and codegen has some tricks with JavaScript
    //      conversions.
    //   2. The value can be primitive, because the library stringifier has
    //      fast-path code for most primitives.
    if (expression.canBePrimitive(compiler)) {
      append(stringify(node, expression));
      return;
    }

    // If the `toString` method is guaranteed to return a string we can call it
    // directly.
    Selector selector = Selectors.toString_;
    TypeMask type = TypeMaskFactory.inferredTypeForSelector(
        selector, expression.instructionType, compiler);
    if (type.containsOnlyString(compiler.world)) {
      builder.pushInvokeDynamic(
          node, selector,
          expression.instructionType, <HInstruction>[expression]);
      append(builder.pop());
      return;
    }

    append(stringify(node, expression));
  }

  void visitStringInterpolation(ast.StringInterpolation node) {
    node.visitChildren(this);
  }

  void visitStringInterpolationPart(ast.StringInterpolationPart node) {
    visit(node.expression);
    visit(node.string);
  }

  void visitStringJuxtaposition(ast.StringJuxtaposition node) {
    node.visitChildren(this);
  }

  void visitNodeList(ast.NodeList node) {
     node.visitChildren(this);
  }

  void append(HInstruction expression) {
    result = (result == null) ? expression : concat(result, expression);
  }

  HInstruction concat(HInstruction left, HInstruction right) {
    HInstruction instruction = new HStringConcat(
        left, right, diagnosticNode, builder.backend.stringType);
    builder.add(instruction);
    return instruction;
  }

  HInstruction stringify(ast.Node node, HInstruction expression) {
    HInstruction instruction =
        new HStringify(expression, node, builder.backend.stringType);
    builder.add(instruction);
    return instruction;
  }
}

/**
 * This class visits the method that is a candidate for inlining and
 * finds whether it is too difficult to inline.
 */
// TODO(karlklose): refactor to make it possible to distinguish between
// implementation restrictions (for example, we *can't* inline multiple returns)
// and heuristics (we *shouldn't* inline large functions).
class InlineWeeder extends ast.Visitor {
  // Invariant: *INSIDE_LOOP* > *OUTSIDE_LOOP*
  static const INLINING_NODES_OUTSIDE_LOOP = 18;
  static const INLINING_NODES_OUTSIDE_LOOP_ARG_FACTOR = 3;
  static const INLINING_NODES_INSIDE_LOOP = 42;
  static const INLINING_NODES_INSIDE_LOOP_ARG_FACTOR = 4;

  bool seenReturn = false;
  bool tooDifficult = false;
  int nodeCount = 0;
  final int maxInliningNodes;
  final bool useMaxInliningNodes;
  final bool allowLoops;
  final bool enableUserAssertions;

  InlineWeeder(this.maxInliningNodes,
               this.useMaxInliningNodes,
               this.allowLoops,
               this.enableUserAssertions);

  static bool canBeInlined(FunctionElement function,
                           int maxInliningNodes,
                           bool useMaxInliningNodes,
                           {bool allowLoops: false,
                            bool enableUserAssertions: null}) {
    assert(enableUserAssertions is bool); // Ensure we passed it.
    if (function.resolvedAst.elements.containsTryStatement) return false;

    InlineWeeder weeder =
        new InlineWeeder(maxInliningNodes, useMaxInliningNodes, allowLoops,
            enableUserAssertions);
    ast.FunctionExpression functionExpression = function.node;
    weeder.visit(functionExpression.initializers);
    weeder.visit(functionExpression.body);
    weeder.visit(functionExpression.asyncModifier);
    return !weeder.tooDifficult;
  }

  bool registerNode() {
    if (!useMaxInliningNodes) return true;
    if (nodeCount++ > maxInliningNodes) {
      tooDifficult = true;
      return false;
    } else {
      return true;
    }
  }

  void visit(ast.Node node) {
    if (node != null) node.accept(this);
  }

  void visitNode(ast.Node node) {
    if (!registerNode()) return;
    if (seenReturn) {
      tooDifficult = true;
    } else {
      node.visitChildren(this);
    }
  }

  @override
  void visitAssert(ast.Assert node) {
    if (enableUserAssertions) {
      visitNode(node);
    }
  }

  @override
  void visitAsyncModifier(ast.AsyncModifier node) {
    if (node.isYielding || node.isAsynchronous) {
      tooDifficult = true;
    }
  }

  void visitFunctionExpression(ast.Node node) {
    if (!registerNode()) return;
    tooDifficult = true;
  }

  void visitFunctionDeclaration(ast.Node node) {
    if (!registerNode()) return;
    tooDifficult = true;
  }

  void visitSend(ast.Send node) {
    if (!registerNode()) return;
    node.visitChildren(this);
  }

  visitLoop(ast.Node node) {
    // It's actually not difficult to inline a method with a loop, but
    // our measurements show that it's currently better to not inline a
    // method that contains a loop.
    if (!allowLoops) tooDifficult = true;
  }

  void visitRedirectingFactoryBody(ast.RedirectingFactoryBody node) {
    if (!registerNode()) return;
    tooDifficult = true;
  }

  void visitRethrow(ast.Rethrow node) {
    if (!registerNode()) return;
    tooDifficult = true;
  }

  void visitReturn(ast.Return node) {
    if (!registerNode()) return;
    if (seenReturn
        || identical(node.beginToken.stringValue, 'native')) {
      tooDifficult = true;
      return;
    }
    node.visitChildren(this);
    seenReturn = true;
  }

  void visitThrow(ast.Throw node) {
    if (!registerNode()) return;
    // For now, we don't want to handle throw after a return even if
    // it is in an "if".
    if (seenReturn) {
      tooDifficult = true;
    } else {
      node.visitChildren(this);
    }
  }
}

abstract class InliningState {
  /**
   * Invariant: [function] must be an implementation element.
   */
  final FunctionElement function;

  InliningState(this.function) {
    assert(function.isImplementation);
  }
}

class AstInliningState extends InliningState {
  final Local oldReturnLocal;
  final DartType oldReturnType;
  final TreeElements oldElements;
  final List<HInstruction> oldStack;
  final LocalsHandler oldLocalsHandler;
  final bool inTryStatement;
  final bool allFunctionsCalledOnce;

  AstInliningState(FunctionElement function,
                   this.oldReturnLocal,
                   this.oldReturnType,
                   this.oldElements,
                   this.oldStack,
                   this.oldLocalsHandler,
                   this.inTryStatement,
                   this.allFunctionsCalledOnce)
      : super(function);
}

class SsaBranch {
  final SsaBranchBuilder branchBuilder;
  final HBasicBlock block;
  LocalsHandler startLocals;
  LocalsHandler exitLocals;
  SubGraph graph;

  SsaBranch(this.branchBuilder) : block = new HBasicBlock();
}

class SsaBranchBuilder {
  final SsaBuilder builder;
  final ast.Node diagnosticNode;

  SsaBranchBuilder(this.builder, [this.diagnosticNode]);

  Compiler get compiler => builder.compiler;

  void checkNotAborted() {
    if (builder.isAborted()) {
      compiler.unimplemented(diagnosticNode, "aborted control flow");
    }
  }

  void buildCondition(void visitCondition(),
                      SsaBranch conditionBranch,
                      SsaBranch thenBranch,
                      SsaBranch elseBranch,
                      SourceInformation sourceInformation) {
    startBranch(conditionBranch);
    visitCondition();
    checkNotAborted();
    assert(identical(builder.current, builder.lastOpenedBlock));
    HInstruction conditionValue = builder.popBoolified();
    HIf branch = new HIf(conditionValue)..sourceInformation = sourceInformation;
    HBasicBlock conditionExitBlock = builder.current;
    builder.close(branch);
    conditionBranch.exitLocals = builder.localsHandler;
    conditionExitBlock.addSuccessor(thenBranch.block);
    conditionExitBlock.addSuccessor(elseBranch.block);
    bool conditionBranchLocalsCanBeReused =
        mergeLocals(conditionBranch, thenBranch, mayReuseFromLocals: true);
    mergeLocals(conditionBranch, elseBranch,
                mayReuseFromLocals: conditionBranchLocalsCanBeReused);

    conditionBranch.graph =
        new SubExpression(conditionBranch.block, conditionExitBlock);
  }

  /**
   * Returns true if the locals of the [fromBranch] may be reused. A [:true:]
   * return value implies that [mayReuseFromLocals] was set to [:true:].
   */
  bool mergeLocals(SsaBranch fromBranch, SsaBranch toBranch,
                   {bool mayReuseFromLocals}) {
    LocalsHandler fromLocals = fromBranch.exitLocals;
    if (toBranch.startLocals == null) {
      if (mayReuseFromLocals) {
        toBranch.startLocals = fromLocals;
        return false;
      } else {
        toBranch.startLocals = new LocalsHandler.from(fromLocals);
        return true;
      }
    } else {
      toBranch.startLocals.mergeWith(fromLocals, toBranch.block);
      return true;
    }
  }

  void startBranch(SsaBranch branch) {
    builder.graph.addBlock(branch.block);
    builder.localsHandler = branch.startLocals;
    builder.open(branch.block);
  }

  HInstruction buildBranch(SsaBranch branch,
                           void visitBranch(),
                           SsaBranch joinBranch,
                           bool isExpression) {
    startBranch(branch);
    visitBranch();
    branch.graph = new SubGraph(branch.block, builder.lastOpenedBlock);
    branch.exitLocals = builder.localsHandler;
    if (!builder.isAborted()) {
      builder.goto(builder.current, joinBranch.block);
      mergeLocals(branch, joinBranch, mayReuseFromLocals: true);
    }
    if (isExpression) {
      checkNotAborted();
      return builder.pop();
    }
    return null;
  }

  handleIf(void visitCondition(),
           void visitThen(),
           void visitElse(),
           {SourceInformation sourceInformation}) {
    if (visitElse == null) {
      // Make sure to have an else part to avoid a critical edge. A
      // critical edge is an edge that connects a block with multiple
      // successors to a block with multiple predecessors. We avoid
      // such edges because they prevent inserting copies during code
      // generation of phi instructions.
      visitElse = () {};
    }

    _handleDiamondBranch(
        visitCondition, visitThen, visitElse, isExpression: false,
        sourceInformation: sourceInformation);
  }

  handleConditional(void visitCondition(),
                    void visitThen(),
                    void visitElse()) {
    assert(visitElse != null);
    _handleDiamondBranch(
        visitCondition, visitThen, visitElse, isExpression: true);
  }

  handleIfNull(void left(), void right()) {
    // x ?? y is transformed into: x == null ? y : x
    HInstruction leftExpression;
    handleConditional(
        () {
          left();
          leftExpression = builder.pop();
          builder.pushCheckNull(leftExpression);
        },
        right,
        () => builder.stack.add(leftExpression));
  }

  void handleLogicalAndOr(void left(), void right(), {bool isAnd}) {
    // x && y is transformed into:
    //   t0 = boolify(x);
    //   if (t0) {
    //     t1 = boolify(y);
    //   }
    //   result = phi(t1, false);
    //
    // x || y is transformed into:
    //   t0 = boolify(x);
    //   if (not(t0)) {
    //     t1 = boolify(y);
    //   }
    //   result = phi(t1, true);
    HInstruction boolifiedLeft;
    HInstruction boolifiedRight;

    void visitCondition() {
      left();
      boolifiedLeft = builder.popBoolified();
      builder.stack.add(boolifiedLeft);
      if (!isAnd) {
        builder.push(new HNot(builder.pop(), builder.backend.boolType));
      }
    }

    void visitThen() {
      right();
      boolifiedRight = builder.popBoolified();
    }

    handleIf(visitCondition, visitThen, null);
    HConstant notIsAnd =
        builder.graph.addConstantBool(!isAnd, builder.compiler);
    JavaScriptBackend backend = builder.backend;
    HPhi result = new HPhi.manyInputs(null,
                                      <HInstruction>[boolifiedRight, notIsAnd],
                                      backend.dynamicType);
    builder.current.addPhi(result);
    builder.stack.add(result);
  }

  void handleLogicalAndOrWithLeftNode(ast.Node left,
                                      void visitRight(),
                                      {bool isAnd}) {
    // This method is similar to [handleLogicalAndOr] but optimizes the case
    // where left is a logical "and" or logical "or".
    //
    // For example (x && y) && z is transformed into x && (y && z):
    //   t0 = boolify(x);
    //   if (t0) {
    //     t1 = boolify(y);
    //     if (t1) {
    //       t2 = boolify(z);
    //     }
    //     t3 = phi(t2, false);
    //   }
    //   result = phi(t3, false);

    ast.Send send = left.asSend();
    if (send != null &&
        (isAnd ? send.isLogicalAnd : send.isLogicalOr)) {
      ast.Node newLeft = send.receiver;
      Link<ast.Node> link = send.argumentsNode.nodes;
      assert(link.tail.isEmpty);
      ast.Node middle = link.head;
      handleLogicalAndOrWithLeftNode(
          newLeft,
          () => handleLogicalAndOrWithLeftNode(middle, visitRight,
                                               isAnd: isAnd),
          isAnd: isAnd);
    } else {
      handleLogicalAndOr(() => builder.visit(left), visitRight, isAnd: isAnd);
    }
  }

  void _handleDiamondBranch(void visitCondition(),
                            void visitThen(),
                            void visitElse(),
                            {bool isExpression,
                             SourceInformation sourceInformation}) {
    SsaBranch conditionBranch = new SsaBranch(this);
    SsaBranch thenBranch = new SsaBranch(this);
    SsaBranch elseBranch = new SsaBranch(this);
    SsaBranch joinBranch = new SsaBranch(this);

    conditionBranch.startLocals = builder.localsHandler;
    builder.goto(builder.current, conditionBranch.block);

    buildCondition(visitCondition, conditionBranch, thenBranch, elseBranch,
                   sourceInformation);
    HInstruction thenValue =
        buildBranch(thenBranch, visitThen, joinBranch, isExpression);
    HInstruction elseValue =
        buildBranch(elseBranch, visitElse, joinBranch, isExpression);

    if (isExpression) {
      assert(thenValue != null && elseValue != null);
      JavaScriptBackend backend = builder.backend;
      HPhi phi = new HPhi.manyInputs(
          null, <HInstruction>[thenValue, elseValue], backend.dynamicType);
      joinBranch.block.addPhi(phi);
      builder.stack.add(phi);
    }

    HBasicBlock joinBlock;
    // If at least one branch did not abort, open the joinBranch.
    if (!joinBranch.block.predecessors.isEmpty) {
      startBranch(joinBranch);
      joinBlock = joinBranch.block;
    }

    HIfBlockInformation info =
        new HIfBlockInformation(
          new HSubExpressionBlockInformation(conditionBranch.graph),
          new HSubGraphBlockInformation(thenBranch.graph),
          new HSubGraphBlockInformation(elseBranch.graph));

    HBasicBlock conditionStartBlock = conditionBranch.block;
    conditionStartBlock.setBlockFlow(info, joinBlock);
    SubGraph conditionGraph = conditionBranch.graph;
    HIf branch = conditionGraph.end.last;
    assert(branch is HIf);
    branch.blockInformation = conditionStartBlock.blockFlow;
  }
}

class TypeBuilder implements DartTypeVisitor<dynamic, SsaBuilder> {
  final ClassWorld classWorld;

  TypeBuilder(this.classWorld);

  void visit(DartType type, SsaBuilder builder) => type.accept(this, builder);

  void visitVoidType(VoidType type, SsaBuilder builder) {
    ClassElement cls = builder.backend.helpers.VoidRuntimeType;
    builder.push(new HVoidType(type, new TypeMask.exact(cls, classWorld)));
  }

  void visitTypeVariableType(TypeVariableType type,
                             SsaBuilder builder) {
    ClassElement cls = builder.backend.helpers.RuntimeType;
    TypeMask instructionType = new TypeMask.subclass(cls, classWorld);
    if (!builder.sourceElement.enclosingElement.isClosure &&
        builder.sourceElement.isInstanceMember) {
      HInstruction receiver = builder.localsHandler.readThis();
      builder.push(new HReadTypeVariable(type, receiver, instructionType));
    } else {
      builder.push(
          new HReadTypeVariable.noReceiver(
              type, builder.addTypeVariableReference(type), instructionType));
    }
  }

  void visitFunctionType(FunctionType type, SsaBuilder builder) {
    type.returnType.accept(this, builder);
    HInstruction returnType = builder.pop();
    List<HInstruction> inputs = <HInstruction>[returnType];

    for (DartType parameter in type.parameterTypes) {
      parameter.accept(this, builder);
      inputs.add(builder.pop());
    }

    for (DartType parameter in type.optionalParameterTypes) {
      parameter.accept(this, builder);
      inputs.add(builder.pop());
    }

    List<DartType> namedParameterTypes = type.namedParameterTypes;
    List<String> names = type.namedParameters;
    for (int index = 0; index < names.length; index++) {
      ast.DartString dartString = new ast.DartString.literal(names[index]);
      inputs.add(
          builder.graph.addConstantString(dartString, builder.compiler));
      namedParameterTypes[index].accept(this, builder);
      inputs.add(builder.pop());
    }

    ClassElement cls = builder.backend.helpers.RuntimeFunctionType;
    builder.push(new HFunctionType(inputs, type,
        new TypeMask.exact(cls, classWorld)));
  }

  void visitMalformedType(MalformedType type, SsaBuilder builder) {
    visitDynamicType(const DynamicType(), builder);
  }

  void visitStatementType(StatementType type, SsaBuilder builder) {
    throw 'not implemented visitStatementType($type)';
  }

  void visitInterfaceType(InterfaceType type, SsaBuilder builder) {
    List<HInstruction> inputs = <HInstruction>[];
    for (DartType typeArgument in type.typeArguments) {
      typeArgument.accept(this, builder);
      inputs.add(builder.pop());
    }
    ClassElement cls;
    if (type.typeArguments.isEmpty) {
      cls = builder.backend.helpers.RuntimeTypePlain;
    } else {
      cls = builder.backend.helpers.RuntimeTypeGeneric;
    }
    builder.push(new HInterfaceType(inputs, type,
        new TypeMask.exact(cls, classWorld)));
  }

  void visitTypedefType(TypedefType type, SsaBuilder builder) {
    DartType unaliased = type.unaliased;
    if (unaliased is TypedefType) throw 'unable to unalias $type';
    unaliased.accept(this, builder);
  }

  void visitDynamicType(DynamicType type, SsaBuilder builder) {
    JavaScriptBackend backend = builder.compiler.backend;
    ClassElement cls = backend.helpers.DynamicRuntimeType;
    builder.push(new HDynamicType(type, new TypeMask.exact(cls, classWorld)));
  }
}
