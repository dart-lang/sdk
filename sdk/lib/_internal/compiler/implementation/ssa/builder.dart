// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of ssa;

/**
 * A special element for the extra parameter taken by intercepted
 * methods. We need to override [Element.computeType] because our
 * optimizers may look at its declared type.
 */
class InterceptedElement extends ElementX {
  final DartType type;
  InterceptedElement(this.type, SourceString name, Element enclosing)
      : super(name, ElementKind.PARAMETER, enclosing);

  DartType computeType(Compiler compiler) => type;
}

class SsaBuilderTask extends CompilerTask {
  final CodeEmitterTask emitter;
  final JavaScriptBackend backend;

  String get name => 'SSA builder';

  SsaBuilderTask(JavaScriptBackend backend)
    : emitter = backend.emitter,
      backend = backend,
      super(backend.compiler);

  HGraph build(CodegenWorkItem work) {
    return measure(() {
      Element element = work.element.implementation;
      HInstruction.idCounter = 0;
      ConstantSystem constantSystem = compiler.backend.constantSystem;
      SsaBuilder builder = new SsaBuilder(constantSystem, this, work);
      HGraph graph;
      ElementKind kind = element.kind;
      if (kind == ElementKind.GENERATIVE_CONSTRUCTOR) {
        graph = compileConstructor(builder, work);
      } else if (kind == ElementKind.GENERATIVE_CONSTRUCTOR_BODY ||
                 kind == ElementKind.FUNCTION ||
                 kind == ElementKind.GETTER ||
                 kind == ElementKind.SETTER) {
        graph = builder.buildMethod(element);
      } else if (kind == ElementKind.FIELD) {
        graph = builder.buildLazyInitializer(element);
      } else {
        compiler.internalErrorOnElement(element,
                                        'unexpected element kind $kind');
      }
      assert(graph.isValid());
      if (!identical(kind, ElementKind.FIELD)) {
        FunctionElement function = element;
        graph.calledInLoop = compiler.world.isCalledInLoop(function);
        OptionalParameterTypes defaultValueTypes = null;
        FunctionSignature signature = function.computeSignature(compiler);
        if (signature.optionalParameterCount > 0) {
          defaultValueTypes =
              new OptionalParameterTypes(signature.optionalParameterCount);
          int index = 0;
          signature.forEachOptionalParameter((Element parameter) {
            Constant defaultValue = builder.compileVariable(parameter);
            HType type = HGraph.mapConstantTypeToSsaType(defaultValue);
            defaultValueTypes.update(index, parameter.name, type);
            index++;
          });
        } else {
          // TODO(ahe): I have disabled type optimizations for
          // optional arguments as the types are stored in the wrong
          // order.
          HTypeList parameterTypes =
              backend.optimisticParameterTypes(element.declaration,
                                               defaultValueTypes);
          if (!parameterTypes.allUnknown) {
            int i = 0;
            signature.forEachParameter((Element param) {
              builder.parameters[param].instructionType = parameterTypes[i++];
            });
          }
          backend.registerParameterTypesOptimization(
              element.declaration, parameterTypes, defaultValueTypes);
        }
      }

      if (compiler.tracer.enabled) {
        String name;
        if (element.isMember()) {
          String className = element.getEnclosingClass().name.slowToString();
          String memberName = element.name.slowToString();
          name = "$className.$memberName";
          if (element.isGenerativeConstructorBody()) {
            name = "$name (body)";
          }
        } else {
          name = "${element.name.slowToString()}";
        }
        compiler.tracer.traceCompilation(name, work.compilationContext);
        compiler.tracer.traceGraph('builder', graph);
      }
      return graph;
    });
  }

  HGraph compileConstructor(SsaBuilder builder, CodegenWorkItem work) {
    // The body of the constructor will be generated in a separate function.
    final ClassElement classElement = work.element.getEnclosingClass();
    return builder.buildFactory(classElement.implementation,
                                work.element.implementation);
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
   * [directLocals] is iterated, so it is a [LinkedHashMap] to make the
   * iteration order a function only of insertions and not a function of
   * e.g. Element hash codes.  I'd prefer to use a SortedMap but some elements
   * don't have source locations for [Elements.compareByPosition].
   */
  LinkedHashMap<Element, HInstruction> directLocals;
  Map<Element, Element> redirectionMapping;
  SsaBuilder builder;
  ClosureClassMap closureData;

  LocalsHandler(this.builder)
      : directLocals = new LinkedHashMap<Element, HInstruction>(),
        redirectionMapping = new Map<Element, Element>();

  get typesTask => builder.compiler.typesTask;

  /**
   * Creates a new [LocalsHandler] based on [other]. We only need to
   * copy the [directLocals], since the other fields can be shared
   * throughout the AST visit.
   */
  LocalsHandler.from(LocalsHandler other)
      : directLocals =
            new LinkedHashMap<Element, HInstruction>.from(other.directLocals),
        redirectionMapping = other.redirectionMapping,
        builder = other.builder,
        closureData = other.closureData;

  /**
   * Redirects accesses from element [from] to element [to]. The [to] element
   * must be a boxed variable or a variable that is stored in a closure-field.
   */
  void redirectElement(Element from, Element to) {
    assert(redirectionMapping[from] == null);
    redirectionMapping[from] = to;
    assert(isStoredInClosureField(from) || isBoxed(from));
  }

  HInstruction createBox() {
    // TODO(floitsch): Clean up this hack. Should we create a box-object by
    // just creating an empty object literal?
    HInstruction box = new HForeign(const LiteralDartString("{}"),
                                    HType.UNKNOWN,
                                    <HInstruction>[]);
    builder.add(box);
    return box;
  }

  /**
   * If the scope (function or loop) [node] has captured variables then this
   * method creates a box and sets up the redirections.
   */
  void enterScope(Node node, Element element) {
    // See if any variable in the top-scope of the function is captured. If yes
    // we need to create a box-object.
    ClosureScope scopeData = closureData.capturingScopes[node];
    if (scopeData == null) return;
    HInstruction box;
    // The scope has captured variables.
    if (element != null && element.isGenerativeConstructorBody()) {
      // The box is passed as a parameter to a generative
      // constructor body.
      box = builder.addParameter(scopeData.boxElement);
    } else {
      box = createBox();
    }
    // Add the box to the known locals.
    directLocals[scopeData.boxElement] = box;
    // Make sure that accesses to the boxed locals go into the box. We also
    // need to make sure that parameters are copied into the box if necessary.
    scopeData.capturedVariableMapping.forEach((Element from, Element to) {
      // The [from] can only be a parameter for function-scopes and not
      // loop scopes.
      if (from.isParameter() && !element.isGenerativeConstructorBody()) {
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
  void updateCaptureBox(Element boxElement, List<Element> toBeCopiedElements) {
    // Create a new box and copy over the values from the old box into the
    // new one.
    HInstruction oldBox = readLocal(boxElement);
    HInstruction newBox = createBox();
    for (Element boxedVariable in toBeCopiedElements) {
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
  void startFunction(Element element, Expression node) {
    assert(invariant(node, element.isImplementation));
    Compiler compiler = builder.compiler;
    closureData = compiler.closureToClassMapper.computeClosureToClassMapping(
            element, node, builder.elements);

    if (element is FunctionElement) {
      FunctionElement functionElement = element;
      FunctionSignature params = functionElement.computeSignature(compiler);
      params.orderedForEachParameter((Element parameterElement) {
        if (element.isGenerativeConstructorBody()) {
          ClosureScope scopeData = closureData.capturingScopes[node];
          if (scopeData != null
              && scopeData.capturedVariableMapping.containsKey(
                  parameterElement)) {
            // The parameter will be a field in the box passed as the
            // last parameter. So no need to have it.
            return;
          }
        }
        HInstruction parameter = builder.addParameter(parameterElement);
        builder.parameters[parameterElement] = parameter;
        directLocals[parameterElement] = parameter;
        parameter.instructionType =
            new HType.inferredTypeForElement(parameterElement, compiler);
      });
    }

    enterScope(node, element);

    // If the freeVariableMapping is not empty, then this function was a
    // nested closure that captures variables. Redirect the captured
    // variables to fields in the closure.
    closureData.freeVariableMapping.forEach((Element from, Element to) {
      redirectElement(from, to);
    });
    if (closureData.isClosure()) {
      // Inside closure redirect references to itself to [:this:].
      HThis thisInstruction = new HThis(closureData.thisElement);
      builder.graph.thisInstruction = thisInstruction;
      builder.graph.entry.addAtEntry(thisInstruction);
      updateLocal(closureData.closureElement, thisInstruction);
    } else if (element.isInstanceMember()
               || element.isGenerativeConstructor()) {
      // Once closures have been mapped to classes their instance members might
      // not have any thisElement if the closure was created inside a static
      // context.
      HThis thisInstruction = new HThis(
          closureData.thisElement, builder.getTypeOfThis());
      builder.graph.thisInstruction = thisInstruction;
      builder.graph.entry.addAtEntry(thisInstruction);
      directLocals[closureData.thisElement] = thisInstruction;
    }

    // If this method is an intercepted method, add the extra
    // parameter to it, that is the actual receiver for intercepted
    // classes, or the same as [:this:] for non-intercepted classes.
    ClassElement cls = element.getEnclosingClass();
    JavaScriptBackend backend = compiler.backend;
    if (backend.isInterceptedMethod(element)) {
      bool isInterceptorClass = backend.isInterceptorClass(cls.declaration);
      SourceString name = isInterceptorClass
          ? const SourceString('receiver')
          : const SourceString('_');
      Element parameter = new InterceptedElement(
          cls.computeType(compiler), name, element);
      HParameterValue value = new HParameterValue(parameter);
      builder.graph.explicitReceiverParameter = value;
      builder.graph.entry.addAfter(
          directLocals[closureData.thisElement], value);
      if (isInterceptorClass) {
        // Only use the extra parameter in intercepted classes.
        directLocals[closureData.thisElement] = value;
      }
      value.instructionType = builder.getTypeOfThis();
    }
  }

  bool hasValueForDirectLocal(Element element) {
    assert(element != null);
    assert(isAccessedDirectly(element));
    return directLocals[element] != null;
  }

  /**
   * Returns true if the local can be accessed directly. Boxed variables or
   * captured variables that are stored in the closure-field return [false].
   */
  bool isAccessedDirectly(Element element) {
    assert(element != null);
    return redirectionMapping[element] == null
        && !closureData.usedVariablesInTry.contains(element);
  }

  bool isStoredInClosureField(Element element) {
    assert(element != null);
    if (isAccessedDirectly(element)) return false;
    Element redirectTarget = redirectionMapping[element];
    if (redirectTarget == null) return false;
    if (redirectTarget.isMember()) {
      assert(redirectTarget is ClosureFieldElement);
      return true;
    }
    return false;
  }

  bool isBoxed(Element element) {
    if (isAccessedDirectly(element)) return false;
    if (isStoredInClosureField(element)) return false;
    return redirectionMapping[element] != null;
  }

  bool isUsedInTry(Element element) {
    return closureData.usedVariablesInTry.contains(element);
  }

  /**
   * Returns an [HInstruction] for the given element. If the element is
   * boxed or stored in a closure then the method generates code to retrieve
   * the value.
   */
  HInstruction readLocal(Element element) {
    if (isAccessedDirectly(element)) {
      if (directLocals[element] == null) {
        builder.compiler.internalError("Cannot find value $element",
                                       element: element);
      }
      return directLocals[element];
    } else if (isStoredInClosureField(element)) {
      Element redirect = redirectionMapping[element];
      HInstruction receiver = readLocal(closureData.closureElement);
      HInstruction fieldGet = new HFieldGet(redirect, receiver);
      fieldGet.instructionType = builder.getTypeOfCapturedVariable(element);
      builder.add(fieldGet);
      return fieldGet;
    } else if (isBoxed(element)) {
      Element redirect = redirectionMapping[element];
      // In the function that declares the captured variable the box is
      // accessed as direct local. Inside the nested closure the box is
      // accessed through a closure-field.
      // Calling [readLocal] makes sure we generate the correct code to get
      // the box.
      assert(redirect.enclosingElement.isVariable());
      HInstruction box = readLocal(redirect.enclosingElement);
      HInstruction lookup = new HFieldGet(redirect, box);
      lookup.instructionType = builder.getTypeOfCapturedVariable(element);
      builder.add(lookup);
      return lookup;
    } else {
      assert(isUsedInTry(element));
      HLocalValue local = getLocal(element);
      HInstruction variable = new HLocalGet(element, local);
      builder.add(variable);
      return variable;
    }
  }

  HInstruction readThis() {
    HInstruction res = readLocal(closureData.thisElement);
    if (res.instructionType == null) {
      res.instructionType = builder.getTypeOfThis();
    }
    return res;
  }

  HLocalValue getLocal(Element element) {
    // If the element is a parameter, we already have a
    // HParameterValue for it. We cannot create another one because
    // it could then have another name than the real parameter. And
    // the other one would not know it is just a copy of the real
    // parameter.
    if (element.isParameter()) return builder.parameters[element];

    return builder.activationVariables.putIfAbsent(element, () {
      HLocalValue local = new HLocalValue(element);
      builder.graph.entry.addAtExit(local);
      return local;
    });
  }

  /**
   * Sets the [element] to [value]. If the element is boxed or stored in a
   * closure then the method generates code to set the value.
   */
  void updateLocal(Element element, HInstruction value) {
    assert(!isStoredInClosureField(element));
    if (isAccessedDirectly(element)) {
      directLocals[element] = value;
    } else if (isBoxed(element)) {
      Element redirect = redirectionMapping[element];
      // The box itself could be captured, or be local. A local variable that
      // is captured will be boxed, but the box itself will be a local.
      // Inside the closure the box is stored in a closure-field and cannot
      // be accessed directly.
      assert(redirect.enclosingElement.isVariable());
      HInstruction box = readLocal(redirect.enclosingElement);
      builder.add(new HFieldSet(redirect, box, value));
    } else {
      assert(isUsedInTry(element));
      HLocalValue local = getLocal(element);
      builder.add(new HLocalSet(element, local, value));
    }
  }

  /**
   * This function, startLoop, must be called before visiting any children of
   * the loop. In particular it needs to be called before executing the
   * initializers.
   *
   * The [LocalsHandler] will make the boxes and updates at the right moment.
   * The builder just needs to call [enterLoopBody] and [enterLoopUpdates] (for
   * [For] loops) at the correct places. For phi-handling [beginLoopHeader] and
   * [endLoop] must also be called.
   *
   * The correct place for the box depends on the given loop. In most cases
   * the box will be created when entering the loop-body: while, do-while, and
   * for-in (assuming the call to [:next:] is inside the body) can always be
   * constructed this way.
   *
   * Things are slightly more complicated for [For] loops. If no declared
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
   * We solve this by emitting the following code (only for [For] loops):
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
  void startLoop(Node node) {
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
    Map<Element, HInstruction> savedDirectLocals =
        new LinkedHashMap<Element, HInstruction>.from(directLocals);

    // Create phis for all elements in the definitions environment.
    savedDirectLocals.forEach((Element element, HInstruction instruction) {
      if (isAccessedDirectly(element)) {
        // We know 'this' cannot be modified.
        if (!identical(element, closureData.thisElement)) {
          HPhi phi = new HPhi.singleInput(element, instruction);
          loopEntry.addPhi(phi);
          directLocals[element] = phi;
        } else {
          directLocals[element] = instruction;
        }
      }
    });
  }

  void enterLoopBody(Node node) {
    ClosureScope scopeData = closureData.capturingScopes[node];
    if (scopeData == null) return;
    // If there are no declared boxed loop variables then we did not create the
    // box before the initializer and we have to create the box now.
    if (!scopeData.hasBoxedLoopVariables()) {
      enterScope(node, null);
    }
  }

  void enterLoopUpdates(Loop node) {
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
      Element element = phi.sourceElement;
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
    Map<Element, HInstruction> joinedLocals =
        new LinkedHashMap<Element, HInstruction>();
    otherLocals.directLocals.forEach((element, instruction) {
      // We know 'this' cannot be modified.
      if (identical(element, closureData.thisElement)) {
        assert(directLocals[element] == instruction);
        joinedLocals[element] = instruction;
      } else {
        HInstruction mine = directLocals[element];
        if (mine == null) return;
        if (identical(instruction, mine)) {
          joinedLocals[element] = instruction;
        } else {
          HInstruction phi =
              new HPhi.manyInputs(element, <HInstruction>[mine, instruction]);
          joinBlock.addPhi(phi);
          joinedLocals[element] = phi;
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
    Map<Element, HInstruction> joinedLocals =
        new LinkedHashMap<Element,HInstruction>();
    HInstruction thisValue = null;
    directLocals.forEach((Element element, HInstruction instruction) {
      if (element != closureData.thisElement) {
        HPhi phi = new HPhi.noInputs(element);
        joinedLocals[element] = phi;
        joinBlock.addPhi(phi);
      } else {
        // We know that "this" never changes, if it's there.
        // Save it for later. While merging, there is no phi for "this",
        // so we don't have to special case it in the merge loop.
        thisValue = instruction;
      }
    });
    for (LocalsHandler handler in localsHandlers) {
      handler.directLocals.forEach((Element element, HInstruction instruction) {
        HPhi phi = joinedLocals[element];
        if (phi != null) {
          phi.addInput(instruction);
        }
      });
    }
    if (thisValue != null) {
      // If there was a "this" for the scope, add it to the new locals.
      joinedLocals[closureData.thisElement] = thisValue;
    }

    // Remove locals that are not in all handlers.
    directLocals = new LinkedHashMap<Element, HInstruction>();
    joinedLocals.forEach((element, instruction) {
      if (instruction is HPhi
          && instruction.inputs.length != localsHandlers.length) {
        joinBlock.removePhi(instruction);
      } else {
        directLocals[element] = instruction;
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
  factory JumpHandler(SsaBuilder builder, TargetElement target) {
    return new TargetJumpHandler(builder, target);
  }
  void generateBreak([LabelElement label]);
  void generateContinue([LabelElement label]);
  void forEachBreak(void action(HBreak instruction, LocalsHandler locals));
  void forEachContinue(void action(HContinue instruction,
                                   LocalsHandler locals));
  bool hasAnyContinue();
  bool hasAnyBreak();
  void close();
  final TargetElement target;
  List<LabelElement> labels();
}

// Insert break handler used to avoid null checks when a target isn't
// used as the target of a break, and therefore doesn't need a break
// handler associated with it.
class NullJumpHandler implements JumpHandler {
  final Compiler compiler;

  NullJumpHandler(this.compiler);

  void generateBreak([LabelElement label]) {
    compiler.internalError('generateBreak should not be called');
  }

  void generateContinue([LabelElement label]) {
    compiler.internalError('generateContinue should not be called');
  }

  void forEachBreak(Function ignored) { }
  void forEachContinue(Function ignored) { }
  void close() { }
  bool hasAnyContinue() => false;
  bool hasAnyBreak() => false;

  List<LabelElement> labels() => const <LabelElement>[];
  TargetElement get target => null;
}

// Records breaks until a target block is available.
// Breaks are always forward jumps.
// Continues in loops are implemented as breaks of the body.
// Continues in switches is currently not handled.
class TargetJumpHandler implements JumpHandler {
  final SsaBuilder builder;
  final TargetElement target;
  final List<JumpHandlerEntry> jumps;

  TargetJumpHandler(SsaBuilder builder, this.target)
      : this.builder = builder,
        jumps = <JumpHandlerEntry>[] {
    assert(builder.jumpTargets[target] == null);
    builder.jumpTargets[target] = this;
  }

  void generateBreak([LabelElement label]) {
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

  void generateContinue([LabelElement label]) {
    HInstruction continueInstruction;
    if (label == null) {
      continueInstruction = new HContinue(target);
    } else {
      continueInstruction = new HContinue.toLabel(label);
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

  List<LabelElement> labels() {
    List<LabelElement> result = null;
    for (LabelElement element in target.labels) {
      if (result == null) result = <LabelElement>[];
      result.add(element);
    }
    return (result == null) ? const <LabelElement>[] : result;
  }
}

class SsaBuilder extends ResolvedVisitor implements Visitor {
  final SsaBuilderTask builder;
  final JavaScriptBackend backend;
  final CodegenWorkItem work;
  final ConstantSystem constantSystem;
  HGraph graph;
  LocalsHandler localsHandler;
  HInstruction rethrowableException;
  Map<Element, HInstruction> parameters;
  final RuntimeTypes rti;
  HParameterValue lastAddedParameter;

  Map<TargetElement, JumpHandler> jumpTargets;

  /**
   * Variables stored in the current activation. These variables are
   * being updated in try/catch blocks, and should be
   * accessed indirectly through [HLocalGet] and [HLocalSet].
   */
  Map<Element, HLocalValue> activationVariables;

  // We build the Ssa graph by simulating a stack machine.
  List<HInstruction> stack;

  /**
   * The current block to add instructions to. Might be null, if we are
   * visiting dead code, but see [isReachable].
   */
  HBasicBlock _current;

  /**
   * The most recently opened block. Has the same value as [_current] while
   * the block is open, but unlike [_current], it isn't cleared when the
   * current block is closed.
   */
  HBasicBlock lastOpenedBlock;

  /**
   * Indicates whether the current block is dead (because it has a throw or a
   * return further up).  If this is false, then [_current] may be null.  If the
   * block is dead then it may also be aborted, but for simplicity we only
   * abort on statement boundaries, not in the middle of expressions.  See
   * isAborted.
   */
  bool isReachable = true;

  final List<Element> sourceElementStack;

  Element get currentElement => sourceElementStack.last.declaration;
  Compiler get compiler => builder.compiler;
  CodeEmitterTask get emitter => builder.emitter;

  SsaBuilder(this.constantSystem, SsaBuilderTask builder, CodegenWorkItem work)
    : this.builder = builder,
      this.backend = builder.backend,
      this.work = work,
      graph = new HGraph(),
      stack = new List<HInstruction>(),
      activationVariables = new Map<Element, HLocalValue>(),
      jumpTargets = new Map<TargetElement, JumpHandler>(),
      parameters = new Map<Element, HInstruction>(),
      sourceElementStack = <Element>[work.element],
      inliningStack = <InliningState>[],
      rti = builder.backend.rti,
      super(work.resolutionTree) {
    localsHandler = new LocalsHandler(this);
  }

  static const MAX_INLINING_DEPTH = 3;
  static const MAX_INLINING_NODES = 46;
  List<InliningState> inliningStack;
  Element returnElement;
  DartType returnType;
  bool inTryStatement = false;

  HBasicBlock get current => _current;
  void set current(c) {
    isReachable = c != null;
    _current = c;
  }

  /**
   * Compiles compile-time constants. Never returns [:null:]. If the
   * initial value is not a compile-time constants, it reports an
   * internal error.
   */
  Constant compileConstant(VariableElement element) {
    return compiler.constantHandler.compileConstant(element);
  }

  Constant compileVariable(VariableElement element) {
    return compiler.constantHandler.compileVariable(element);
  }

  bool isLazilyInitialized(VariableElement element) {
    Constant initialValue = compileVariable(element);
    return initialValue == null;
  }

  HType cachedTypeOfThis;

  HType getTypeOfThis() {
    HType result = cachedTypeOfThis;
    if (result == null) {
      Element element = localsHandler.closureData.thisElement;
      ClassElement cls = element.enclosingElement.getEnclosingClass();
      // Use the raw type because we don't have the type context for the
      // type parameters.
      DartType type = cls.rawType;
      if (compiler.world.isUsedAsMixin(cls)) {
        // If the enclosing class is used as a mixin, [:this:] can be
        // of the class that mixins the enclosing class. These two
        // classes do not have a subclass relationship, so, for
        // simplicity, we mark the type as an interface type.
        result = new HType.nonNullSubtype(type, compiler);
      } else {
        result = new HType.nonNullSubclass(type, compiler);
      }
      cachedTypeOfThis = result;
    }
    return result;
  }

  Map<Element, HType> cachedTypesOfCapturedVariables =
      new Map<Element, HType>();

  HType getTypeOfCapturedVariable(Element element) {
    return cachedTypesOfCapturedVariables.putIfAbsent(element, () {
      return new HType.inferredTypeForElement(element, compiler);
    });
  }

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [functionElement] must be an implementation element.
   */
  HGraph buildMethod(FunctionElement functionElement) {
    assert(invariant(functionElement, functionElement.isImplementation));
    FunctionExpression function = functionElement.parseNode(compiler);
    assert(function != null);
    assert(!function.modifiers.isExternal());
    assert(elements[function] != null);
    openFunction(functionElement, function);
    SourceString name = functionElement.name;
    // If [functionElement] is `operator==` we explicitely add a null check at
    // the beginning of the method. This is to avoid having call sites do the
    // null check.
    if (name == const SourceString('==')) {
      if (!backend.operatorEqHandlesNullArgument(functionElement)) {
        handleIf(
            function,
            () {
              HParameterValue parameter = parameters.values.first;
              push(new HIdentity(
                  parameter, graph.addConstantNull(constantSystem)));
            },
            () {
              closeAndGotoExit(new HReturn(
                  graph.addConstantBool(false, constantSystem)));
            },
            null);
      }
    }
    function.body.accept(this);
    return closeFunction();
  }

  HGraph buildLazyInitializer(VariableElement variable) {
    SendSet node = variable.parseNode(compiler);
    openFunction(variable, node);
    Link<Node> link = node.arguments;
    assert(!link.isEmpty && link.tail.isEmpty);
    visit(link.head);
    HInstruction value = pop();
    value = potentiallyCheckType(value, variable.computeType(compiler));
    closeAndGotoExit(new HReturn(value));
    return closeFunction();
  }

  /**
   * Returns the constructor body associated with the given constructor or
   * creates a new constructor body, if none can be found.
   *
   * Returns [:null:] if the constructor does not have a body.
   */
  ConstructorBodyElement getConstructorBody(FunctionElement constructor) {
    assert(constructor.isGenerativeConstructor());
    assert(invariant(constructor, constructor.isImplementation));
    if (constructor.isSynthesized) return null;
    FunctionExpression node = constructor.parseNode(compiler);
    // If we know the body doesn't have any code, we don't generate it.
    if (!node.hasBody()) return null;
    if (node.hasEmptyBody()) return null;
    ClassElement classElement = constructor.getEnclosingClass();
    ConstructorBodyElement bodyElement;
    classElement.forEachBackendMember((Element backendMember) {
      if (backendMember.isGenerativeConstructorBody()) {
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
      // [:resolveMethodElement:] require the passed element to be a
      // declaration.
      TreeElements treeElements =
          compiler.enqueuer.resolution.getCachedElements(
              constructor.declaration);
      classElement.addBackendMember(bodyElement);

      if (constructor.isPatch) {
        // Create origin body element for patched constructors.
        bodyElement.origin = new ConstructorBodyElementX(constructor.origin);
        bodyElement.origin.patch = bodyElement;
        classElement.origin.addBackendMember(bodyElement.origin);
      }
      compiler.enqueuer.codegen.addToWorkList(bodyElement.declaration,
                                              treeElements);
    }
    assert(bodyElement.isGenerativeConstructorBody());
    return bodyElement;
  }

  HParameterValue addParameter(Element element) {
    HParameterValue result = new HParameterValue(element);
    if (lastAddedParameter == null) {
      graph.entry.addBefore(graph.entry.first, result);
    } else {
      graph.entry.addAfter(lastAddedParameter, result);
    }
    lastAddedParameter = result;
    return result;
  }

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [function] must be an implementation element.
   */
  InliningState enterInlinedMethod(PartialFunctionElement function,
                                   Selector selector,
                                   Link<Node> arguments,
                                   Node currentNode) {
    assert(invariant(function, function.isImplementation));

    // Once we start to compile the arguments we must be sure that we don't
    // abort.
    List<HInstruction> compiledArguments = new List<HInstruction>();
    bool succeeded = addStaticSendArgumentsToList(selector,
                                                  arguments,
                                                  function,
                                                  compiledArguments);
    assert(succeeded);

    // Create the inlining state after evaluating the arguments, that
    // may have an impact on the state of the current method.
    InliningState state = new InliningState(
        function, returnElement, returnType, elements, stack, localsHandler);
    localsHandler = new LocalsHandler.from(localsHandler);

    FunctionSignature signature = function.computeSignature(compiler);
    int index = 0;
    signature.orderedForEachParameter((Element parameter) {
      HInstruction argument = compiledArguments[index++];
      localsHandler.updateLocal(parameter, argument);
      potentiallyCheckType(argument, parameter.computeType(compiler));
    });

    if (function.isConstructor()) {
      ClassElement enclosing = function.getEnclosingClass();
      if (backend.needsRti(enclosing)) {
        assert(currentNode is NewExpression);
        InterfaceType type = elements.getType(currentNode);
        Link<DartType> typeVariable = enclosing.typeVariables;
        type.typeArguments.forEach((DartType argument) {
          HInstruction instruction =
              analyzeTypeArgument(argument, currentNode);
          localsHandler.updateLocal(typeVariable.head.element, instruction);
          typeVariable = typeVariable.tail;
        });
        while (!typeVariable.isEmpty) {
          localsHandler.updateLocal(typeVariable.head.element,
                                    graph.addConstantNull(constantSystem));
          typeVariable = typeVariable.tail;
        }
      }
    }

    // TODO(kasperl): Bad smell. We shouldn't be constructing elements here.
    returnElement = new ElementX(const SourceString("result"),
                                 ElementKind.VARIABLE,
                                 function);
    localsHandler.updateLocal(returnElement,
                              graph.addConstantNull(constantSystem));
    elements = compiler.enqueuer.resolution.getCachedElements(function);
    assert(elements != null);
    returnType = signature.returnType;
    stack = <HInstruction>[];
    inliningStack.add(state);
    return state;
  }

  void leaveInlinedMethod(InliningState state) {
    InliningState poppedState = inliningStack.removeLast();
    assert(state == poppedState);
    elements = state.oldElements;
    stack.add(localsHandler.readLocal(returnElement));
    returnElement = state.oldReturnElement;
    returnType = state.oldReturnType;
    assert(stack.length == 1);
    state.oldStack.add(stack[0]);
    stack = state.oldStack;
    localsHandler = state.oldLocalsHandler;
  }

  /**
   * Try to inline [element] within the currect context of the
   * builder. The insertion point is the state of the builder.
   */
  bool tryInlineMethod(Element element,
                       Selector selector,
                       Link<Node> arguments,
                       Node currentNode) {
    // We cannot inline a method from a deferred library into a method
    // which isn't deferred.
    // TODO(ahe): But we should still inline into the same
    // connected-component of the deferred library.
    if (compiler.deferredLoadTask.isDeferred(element)) return false;

    if (compiler.disableInlining) return false;
    // Ensure that [element] is an implementation element.
    element = element.implementation;
    // TODO(floitsch): we should be able to inline inside lazy initializers.
    if (!currentElement.isFunction()) return false;
    // TODO(floitsch): find a cleaner way to know if the element is a function
    // containing nodes.
    // [PartialFunctionElement]s are [FunctionElement]s that have [Node]s.
    if (element is !PartialFunctionElement) return false;
    // TODO(ngeoffray): try to inline generative constructors. They
    // don't have any body, which make it more difficult.
    if (element.isGenerativeConstructor()) return false;
    if (inliningStack.length > MAX_INLINING_DEPTH) return false;
    // Don't inline recursive calls. We use the same elements for the inlined
    // functions and would thus clobber our local variables.
    // Use [:element.declaration:] since [work.element] is always a declaration.
    if (currentElement == element.declaration) return false;
    for (int i = 0; i < inliningStack.length; i++) {
      if (inliningStack[i].function == element) return false;
    }

    PartialFunctionElement function = element;
    bool canBeInlined = backend.canBeInlined[function];
    if (canBeInlined == false) return false;
    if (!selector.applies(function, compiler)) return false;

    FunctionExpression functionExpression = function.parseNode(compiler);
    TreeElements newElements =
        compiler.enqueuer.resolution.getCachedElements(function);
    if (newElements == null) {
      compiler.internalError("Element not resolved: $function");
    }

    if (canBeInlined == null) {
      canBeInlined = InlineWeeder.canBeInlined(functionExpression, newElements);
      backend.canBeInlined[function] = canBeInlined;
      if (!canBeInlined) return false;
    }

    assert(canBeInlined);
    InliningState state = enterInlinedMethod(
        function, selector, arguments, currentNode);
    inlinedFrom(element, () {
      functionExpression.body.accept(this);
    });
    leaveInlinedMethod(state);
    return true;
  }

  inlinedFrom(Element element, f()) {
    assert(element is FunctionElement || element is VariableElement);
    return compiler.withCurrentElement(element, () {
      sourceElementStack.add(element);
      var result = f();
      sourceElementStack.removeLast();
      return result;
    });
  }

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [constructor] and [constructors] must all be implementation
   * elements.
   */
  void inlineSuperOrRedirect(FunctionElement constructor,
                             Selector selector,
                             Link<Node> arguments,
                             List<FunctionElement> constructors,
                             Map<Element, HInstruction> fieldValues,
                             FunctionElement inlinedFromElement,
                             Node callNode) {
    compiler.withCurrentElement(constructor, () {
      assert(invariant(constructor, constructor.isImplementation));
      constructors.add(constructor);

      List<HInstruction> compiledArguments = new List<HInstruction>();
      bool succeeded =
          inlinedFrom(inlinedFromElement,
                       () => addStaticSendArgumentsToList(selector,
                                                          arguments,
                                                          constructor,
                                                          compiledArguments));
      if (!succeeded) {
        // Non-matching super and redirects are compile-time errors and thus
        // checked by the resolver.
        compiler.internalError(
            "Parameters and arguments didn't match for super/redirect call",
            element: constructor);
      }

      ClassElement superclass = constructor.getEnclosingClass();
      if (backend.needsRti(superclass)) {
        // If [superclass] needs RTI, we have to give a value to its
        // type parameters. Those values are in the [supertype]
        // declaration of [subclass].
        ClassElement subclass = inlinedFromElement.getEnclosingClass();
        InterfaceType supertype = subclass.supertype;
        Link<DartType> typeVariables = superclass.typeVariables;
        supertype.typeArguments.forEach((DartType argument) {
          localsHandler.updateLocal(typeVariables.head.element,
              analyzeTypeArgument(argument, callNode));
          typeVariables = typeVariables.tail;
        });
        // If the supertype is a raw type, we need to set to null the
        // type variables.
        assert(typeVariables.isEmpty
               || superclass.typeVariables == typeVariables);
        while (!typeVariables.isEmpty) {
          localsHandler.updateLocal(typeVariables.head.element,
              graph.addConstantNull(constantSystem));
          typeVariables = typeVariables.tail;
        }
      }

      inlinedFrom(constructor, () {
        buildFieldInitializers(constructor.enclosingElement.implementation,
                               fieldValues);
      });

      int index = 0;
      FunctionSignature params = constructor.computeSignature(compiler);
      params.orderedForEachParameter((Element parameter) {
        HInstruction argument = compiledArguments[index++];
        // Because we are inlining the initializer, we must update
        // what was given as parameter. This will be used in case
        // there is a parameter check expression in the initializer.
        parameters[parameter] = argument;
        localsHandler.updateLocal(parameter, argument);
        // Don't forget to update the field, if the parameter is of the
        // form [:this.x:].
        if (parameter.kind == ElementKind.FIELD_PARAMETER) {
          FieldParameterElement fieldParameterElement = parameter;
          fieldValues[fieldParameterElement.fieldElement] = argument;
        }
      });

      // Build the initializers in the context of the new constructor.
      TreeElements oldElements = elements;
      elements =
          compiler.enqueuer.resolution.getCachedElements(constructor);

      ClosureClassMap oldClosureData = localsHandler.closureData;
      Node node = constructor.parseNode(compiler);
      ClosureClassMap newClosureData =
          compiler.closureToClassMapper.computeClosureToClassMapping(
              constructor, node, elements);
      // The [:this:] element now refers to the one in the new closure
      // data, that is the [:this:] of the super constructor. We
      // update the element to refer to the current [:this:].
      localsHandler.updateLocal(newClosureData.thisElement,
                                localsHandler.readThis());
      localsHandler.closureData = newClosureData;

      params.orderedForEachParameter((Element parameterElement) {
        if (elements.isParameterChecked(parameterElement)) {
          addParameterCheckInstruction(parameterElement);
        }
      });
      localsHandler.enterScope(node, constructor);
      buildInitializers(constructor, constructors, fieldValues);
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
  void buildInitializers(FunctionElement constructor,
                         List<FunctionElement> constructors,
                         Map<Element, HInstruction> fieldValues) {
    assert(invariant(constructor, constructor.isImplementation));
    FunctionExpression functionNode = constructor.parseNode(compiler);

    bool foundSuperOrRedirect = false;

    if (functionNode.initializers != null) {
      Link<Node> initializers = functionNode.initializers.nodes;
      for (Link<Node> link = initializers; !link.isEmpty; link = link.tail) {
        assert(link.head is Send);
        if (link.head is !SendSet) {
          // A super initializer or constructor redirection.
          Send call = link.head;
          assert(Initializers.isSuperConstructorCall(call) ||
                 Initializers.isConstructorRedirect(call));
          FunctionElement target = elements[call];
          Selector selector = elements.getSelector(call);
          Link<Node> arguments = call.arguments;
          inlineSuperOrRedirect(target, selector, arguments, constructors,
                                fieldValues, constructor, call);
          foundSuperOrRedirect = true;
        } else {
          // A field initializer.
          SendSet init = link.head;
          Link<Node> arguments = init.arguments;
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
      ClassElement enclosingClass = constructor.getEnclosingClass();
      ClassElement superClass = enclosingClass.superclass;
      if (!enclosingClass.isObject(compiler)) {
        assert(superClass != null);
        assert(superClass.resolutionState == STATE_DONE);
        Selector selector =
            new Selector.callDefaultConstructor(enclosingClass.getLibrary());
        // TODO(johnniwinther): Should we find injected constructors as well?
        FunctionElement target = superClass.lookupConstructor(selector);
        if (target == null) {
          compiler.internalError("no default constructor available");
        }
        inlineSuperOrRedirect(target.implementation,
                              selector,
                              const Link<Node>(),
                              constructors,
                              fieldValues,
                              constructor,
                              functionNode);
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
        (ClassElement enclosingClass, Element member) {
          compiler.withCurrentElement(member, () {
            TreeElements definitions = compiler.analyzeElement(member);
            Node node = member.parseNode(compiler);
            SendSet assignment = node.asSendSet();
            HInstruction value;
            if (assignment == null) {
              value = graph.addConstantNull(constantSystem);
            } else {
              Node right = assignment.arguments.head;
              TreeElements savedElements = elements;
              elements = definitions;
              // In case the field initializer uses closures, run the
              // closure to class mapper.
              compiler.closureToClassMapper.computeClosureToClassMapping(
                  member, node, elements);
              inlinedFrom(member, () => right.accept(this));
              elements = savedElements;
              value = pop();
            }
            fieldValues[member] = value;
          });
        },
        includeBackendMembers: true,
        includeSuperMembers: false);
  }


  /**
   * Build the factory function corresponding to the constructor
   * [functionElement]:
   *  - Initialize fields with the values of the field initializers of the
   *    current constructor and super constructors or constructors redirected
   *    to, starting from the current constructor.
   *  - Call the the constructor bodies, starting from the constructor(s) in the
   *    super class(es).
   *
   * Invariant: Both [classElement] and [functionElement] must be
   * implementation elements.
   */
  HGraph buildFactory(ClassElement classElement,
                      FunctionElement functionElement) {
    assert(invariant(classElement, classElement.isImplementation));
    assert(invariant(functionElement, functionElement.isImplementation));
    FunctionExpression function = functionElement.parseNode(compiler);
    // Note that constructors (like any other static function) do not need
    // to deal with optional arguments. It is the callers job to provide all
    // arguments as if they were positional.

    // The initializer list could contain closures.
    openFunction(functionElement, function);

    Map<Element, HInstruction> fieldValues = new Map<Element, HInstruction>();

    // Compile the possible initialization code for local fields and
    // super fields.
    buildFieldInitializers(classElement, fieldValues);

    // Compile field-parameters such as [:this.x:].
    FunctionSignature params = functionElement.computeSignature(compiler);
    params.orderedForEachParameter((Element element) {
      if (element.kind == ElementKind.FIELD_PARAMETER) {
        // If the [element] is a field-parameter then
        // initialize the field element with its value.
        FieldParameterElement fieldParameterElement = element;
        HInstruction parameterValue = localsHandler.readLocal(element);
        fieldValues[fieldParameterElement.fieldElement] = parameterValue;
      }
    });

    // Analyze the constructor and all referenced constructors and collect
    // initializers and constructor bodies.
    List<FunctionElement> constructors = <FunctionElement>[functionElement];
    buildInitializers(functionElement, constructors, fieldValues);

    // Call the JavaScript constructor with the fields as argument.
    List<HInstruction> constructorArguments = <HInstruction>[];
    classElement.forEachInstanceField(
        (ClassElement enclosingClass, Element member) {
          constructorArguments.add(potentiallyCheckType(
              fieldValues[member], member.computeType(compiler)));
        },
        includeBackendMembers: true,
        includeSuperMembers: true);

    InterfaceType type = classElement.computeType(compiler);
    HType ssaType = new HType.nonNullExact(type, compiler);
    HForeignNew newObject = new HForeignNew(classElement,
                                            ssaType,
                                            constructorArguments);
    add(newObject);

    // Create the runtime type information, if needed.
    if (backend.needsRti(classElement)) {
      List<HInstruction> rtiInputs = <HInstruction>[];
      classElement.typeVariables.forEach((TypeVariableType typeVariable) {
        rtiInputs.add(localsHandler.readLocal(typeVariable.element));
      });
      callSetRuntimeTypeInfo(classElement, rtiInputs, newObject);
    }

    // Generate calls to the constructor bodies.
    for (int index = constructors.length - 1; index >= 0; index--) {
      FunctionElement constructor = constructors[index];
      assert(invariant(functionElement, constructor.isImplementation));
      ConstructorBodyElement body = getConstructorBody(constructor);
      if (body == null) continue;
      List bodyCallInputs = <HInstruction>[];
      bodyCallInputs.add(newObject);
      TreeElements elements =
          compiler.enqueuer.resolution.getCachedElements(constructor);
      Node node = constructor.parseNode(compiler);
      ClosureClassMap parameterClosureData =
          compiler.closureToClassMapper.getMappingForNestedFunction(node);


      FunctionSignature functionSignature = body.computeSignature(compiler);
      // Provide the parameters to the generative constructor body.
      functionSignature.orderedForEachParameter((parameter) {
        // If [parameter] is boxed, it will be a field in the box passed as the
        // last parameter. So no need to directly pass it.
        if (!localsHandler.isBoxed(parameter)) {
          bodyCallInputs.add(localsHandler.readLocal(parameter));
        }
      });

      // Provide the parameter checks to the generative constructor
      // body.
      functionSignature.orderedForEachParameter((parameter) {
        // If [parameter] is checked, we pass the already computed
        // boolean to the constructor body.
        if (elements.isParameterChecked(parameter)) {
          Element fieldCheck =
              parameterClosureData.parametersWithSentinel[parameter];
          bodyCallInputs.add(localsHandler.readLocal(fieldCheck));
        }
      });

      ClassElement currentClass = constructor.getEnclosingClass();
      if (backend.needsRti(currentClass)) {
        // If [currentClass] needs RTI, we add the type variables as
        // parameters of the generative constructor body.
        currentClass.typeVariables.forEach((DartType argument) {
          bodyCallInputs.add(localsHandler.readLocal(argument.element));
        });
      }

      // If there are locals that escape (ie mutated in closures), we
      // pass the box to the constructor.
      ClosureScope scopeData = parameterClosureData.capturingScopes[node];
      if (scopeData != null) {
        bodyCallInputs.add(localsHandler.readLocal(scopeData.boxElement));
      }

      // TODO(ahe): The constructor name is statically resolved. See
      // SsaCodeGenerator.visitInvokeDynamicMethod. Is there a cleaner
      // way to do this?
      SourceString name =
          new SourceString(backend.namer.getName(body.declaration));
      // TODO(kasperl): This seems fishy. We shouldn't be inventing all
      // these selectors. Maybe the resolver can do more of the work
      // for us here?
      LibraryElement library = body.getLibrary();
      Selector selector = new Selector.call(
          name, library, bodyCallInputs.length - 1);
      HInvokeDynamic invoke =
          new HInvokeDynamicMethod(selector, bodyCallInputs);
      invoke.element = body;
      add(invoke);
    }
    closeAndGotoExit(new HReturn(newObject));
    return closeFunction();
  }

  void addParameterCheckInstruction(Element element) {
    HInstruction check;
    Element checkResultElement =
        localsHandler.closureData.parametersWithSentinel[element];
    if (currentElement.isGenerativeConstructorBody()) {
      // A generative constructor body receives extra parameters that
      // indicate if a parameter was passed to the factory.
      check = addParameter(checkResultElement);
    } else {
      // This is the code we emit for a parameter that is being checked
      // on whether it was given at value at the call site:
      //
      // foo([a = 42]) {
      //   if (?a) print('parameter passed $a');
      // }
      //
      // foo([a = 42]) {
      //   var t1 = identical(a, sentinel);
      //   if (t1) a = 42;
      //   if (!t1) print('parameter passed ' + a);
      // }

      // Fetch the original default value of [element];
      Constant constant = compileVariable(element);
      HConstant defaultValue = constant == null
          ? graph.addConstantNull(constantSystem)
          : graph.addConstant(constant);

      // Emit the equality check with the sentinel.
      HConstant sentinel = graph.addConstant(SentinelConstant.SENTINEL);
      HInstruction operand = parameters[element];
      check = new HIdentity(sentinel, operand);
      add(check);

      // If the check succeeds, we must update the parameter with the
      // default value.
      handleIf(element.parseNode(compiler),
               () => stack.add(check),
               () => localsHandler.updateLocal(element, defaultValue),
               null);

      // Create the instruction that parameter checks will use.
      check = new HNot(check);
      add(check);
    }

    localsHandler.updateLocal(checkResultElement, check);
  }

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [functionElement] must be the implementation element.
   */
  void openFunction(Element element, Expression node) {
    assert(invariant(element, element.isImplementation));
    HBasicBlock block = graph.addNewBlock();
    open(graph.entry);

    localsHandler.startFunction(element, node);
    close(new HGoto()).addSuccessor(block);

    open(block);

    if (element is FunctionElement) {
      FunctionElement functionElement = element;
      FunctionSignature signature = functionElement.computeSignature(compiler);
      signature.orderedForEachParameter((Element parameterElement) {
        if (elements.isParameterChecked(parameterElement)) {
          addParameterCheckInstruction(parameterElement);
        }
      });

      // Put the type checks in the first successor of the entry,
      // because that is where the type guards will also be inserted.
      // This way we ensure that a type guard will dominate the type
      // check.
      signature.orderedForEachParameter((Element parameterElement) {
        if (element.isGenerativeConstructorBody()) {
          ClosureScope scopeData =
              localsHandler.closureData.capturingScopes[node];
          if (scopeData != null
              && scopeData.capturedVariableMapping.containsKey(
                  parameterElement)) {
            // The parameter will be a field in the box passed as the
            // last parameter. So no need to have it.
            return;
          }
        }
        HInstruction newParameter = potentiallyCheckType(
            localsHandler.directLocals[parameterElement],
            parameterElement.computeType(compiler));
        localsHandler.directLocals[parameterElement] = newParameter;
      });

      returnType = signature.returnType;
    } else {
      // Otherwise it is a lazy initializer which does not have parameters.
      assert(element is VariableElement);
    }

    // Add the type parameters of the class as parameters of this
    // method.
    var enclosing = element.enclosingElement;
    if ((element.isConstructor() || element.isGenerativeConstructorBody())
        && backend.needsRti(enclosing)) {
      enclosing.typeVariables.forEach((TypeVariableType typeVariable) {
        HParameterValue param = addParameter(typeVariable.element);
        localsHandler.directLocals[typeVariable.element] = param;
      });
    }
  }

  HInstruction potentiallyCheckType(
      HInstruction original, DartType type,
      { int kind: HTypeConversion.CHECKED_MODE_CHECK }) {
    if (!compiler.enableTypeAssertions) return original;
    HInstruction other = original.convertType(compiler, type, kind);
    if (other != original) add(other);
    return other;
  }

  HGraph closeFunction() {
    // TODO(kasperl): Make this goto an implicit return.
    if (!isAborted()) closeAndGotoExit(new HGoto());
    graph.finalize();
    return graph;
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
    return _current == null;
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

  void addWithPosition(HInstruction instruction, Node node) {
    add(attachPosition(instruction, node));
  }

  void push(HInstruction instruction) {
    add(instruction);
    stack.add(instruction);
  }

  void pushWithPosition(HInstruction instruction, Node node) {
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
    if (compiler.enableTypeAssertions) {
      return potentiallyCheckType(
          value,
          compiler.boolClass.computeType(compiler),
          kind: HTypeConversion.BOOLEAN_CONVERSION_CHECK);
    }
    HInstruction result = new HBoolify(value);
    add(result);
    return result;
  }

  HInstruction attachPosition(HInstruction target, Node node) {
    target.sourcePosition = sourceFileLocationForBeginToken(node);
    return target;
  }

  SourceFileLocation sourceFileLocationForBeginToken(Node node) =>
      sourceFileLocationForToken(node, node.getBeginToken());

  SourceFileLocation sourceFileLocationForEndToken(Node node) =>
      sourceFileLocationForToken(node, node.getEndToken());

  SourceFileLocation sourceFileLocationForToken(Node node, Token token) {
    Element element = sourceElementStack.last;
    // TODO(johnniwinther): remove the 'element.patch' hack.
    if (element is FunctionElement) {
      FunctionElement functionElement = element;
      if (functionElement.patch != null) element = functionElement.patch;
    }
    Script script = element.getCompilationUnit().script;
    SourceFile sourceFile = script.file;
    SourceFileLocation location = new SourceFileLocation(sourceFile, token);
    if (!location.isValid()) {
      throw MessageKind.INVALID_SOURCE_FILE_LOCATION.message(
          {'offset': token.charOffset,
           'fileName': sourceFile.filename,
           'length': sourceFile.text.length});
    }
    return location;
  }

  void visit(Node node) {
    if (node != null) node.accept(this);
  }

  visitBlock(Block node) {
    assert(!isAborted());
    if (!isReachable) return;  // This can only happen when inlining.
    for (Link<Node> link = node.statements.nodes;
         !link.isEmpty;
         link = link.tail) {
      visit(link.head);
      if (!isReachable) {
        // The block has been aborted by a return or a throw.
        if (!stack.isEmpty) compiler.cancel('non-empty instruction stack');
        return;
      }
    }
    assert(!current.isClosed());
    if (!stack.isEmpty) compiler.cancel('non-empty instruction stack');
  }

  visitClassNode(ClassNode node) {
    compiler.internalError('visitClassNode should not be called', node: node);
  }

  visitExpressionStatement(ExpressionStatement node) {
    assert(isReachable);
    visit(node.expression);
    pop();
  }

  /**
   * Creates a new loop-header block. The previous [current] block
   * is closed with an [HGoto] and replaced by the newly created block.
   * Also notifies the locals handler that we're entering a loop.
   */
  JumpHandler beginLoopHeader(Node node) {
    assert(!isAborted());
    HBasicBlock previousBlock = close(new HGoto());

    JumpHandler jumpHandler = createJumpHandler(node);
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
   * - creates a new block and adds it as successor to the [branchBlock] and
   *   any blocks that end in break.
   * - opens the new block (setting as [current]).
   * - notifies the locals handler that we're exiting a loop.
   * [savedLocals] are the locals from the end of the loop condition.
   * [branchBlock] is the exit (branching) block of the condition.  For the
   * while and for loops this is at the top of the loop.  For do-while it is
   * the end of the body.  It is null for degenerate do-while loops that have
   * no back edge because they abort (throw/return/break in the body and have
   * no continues).
   */
  void endLoop(HBasicBlock loopEntry,
               HBasicBlock branchBlock,
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
    if (branchBlock != null) {
      branchBlock.addSuccessor(loopExitBlock);
    }
    // Update the phis at the loop entry with the current values of locals.
    localsHandler.endLoop(loopEntry);

    // Start generating code for the exit block.
    open(loopExitBlock);

    // Create a new localsHandler for the loopExitBlock with the correct phis.
    if (!breakHandlers.isEmpty) {
      if (branchBlock != null) {
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
  void handleLoop(Node loop,
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

    JumpHandler jumpHandler = beginLoopHeader(loop);
    HLoopInformation loopInfo = current.loopInformation;
    HBasicBlock conditionBlock = current;
    if (startBlock == null) startBlock = conditionBlock;

    HInstruction conditionInstruction = condition();
    HBasicBlock conditionExitBlock =
        close(new HLoopBranch(conditionInstruction));
    SubExpression conditionExpression =
        new SubExpression(conditionBlock, conditionExitBlock);

    // Save the values of the local variables at the end of the condition
    // block.  These are the values that will flow to the loop exit if the
    // condition fails.
    LocalsHandler savedLocals = new LocalsHandler.from(localsHandler);

    // The body.
    HBasicBlock beginBodyBlock = addNewBlock();
    conditionExitBlock.addSuccessor(beginBodyBlock);
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

      HLabeledBlockInformation labelInfo;
      List<LabelElement> labels = jumpHandler.labels();
      TargetElement target = elements[loop];
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
              sourceFileLocationForBeginToken(loop),
              sourceFileLocationForEndToken(loop));

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
      HInstruction condition = conditionExitBlock.last.inputs[0];
      conditionExitBlock.addAtExit(new HIf(condition));
      conditionExitBlock.addSuccessor(elseBlock);
      conditionExitBlock.remove(conditionExitBlock.last);
      HIfBlockInformation info =
          new HIfBlockInformation(
              wrapExpressionGraph(conditionExpression),
              wrapStatementGraph(bodyGraph),
              wrapStatementGraph(elseGraph));

      conditionExitBlock.setBlockFlow(info, current);
      HIf ifBlock = conditionExitBlock.last;
      ifBlock.blockInformation = conditionExitBlock.blockFlow;

      // If the body has any break, attach a synthesized label to the
      // if block.
      if (jumpHandler.hasAnyBreak()) {
        TargetElement target = elements[loop];
        LabelElement label = target.addLabel(null, 'loop');
        label.setBreakTarget();
        SubGraph labelGraph = new SubGraph(conditionBlock, current);
        HLabeledBlockInformation labelInfo = new HLabeledBlockInformation(
                new HSubGraphBlockInformation(labelGraph),
                <LabelElement>[label]);

        conditionBlock.setBlockFlow(labelInfo, current);

        jumpHandler.forEachBreak((HBreak breakInstruction, _) {
          HBasicBlock block = breakInstruction.block;
          block.addAtExit(new HBreak.toLabel(label));
          block.remove(breakInstruction);
        });
      }
    }
    jumpHandler.close();
  }

  visitFor(For node) {
    assert(isReachable);
    assert(node.body != null);
    void buildInitializer() {
      if (node.initializer == null) return;
      Node initializer = node.initializer;
      if (initializer != null) {
        visit(initializer);
        if (initializer.asExpression() != null) {
          pop();
        }
      }
    }
    HInstruction buildCondition() {
      if (node.condition == null) {
        return graph.addConstantBool(true, constantSystem);
      }
      visit(node.condition);
      return popBoolified();
    }
    void buildUpdate() {
      for (Expression expression in node.update) {
        visit(expression);
        assert(!isAborted());
        // The result of the update instruction isn't used, and can just
        // be dropped.
        HInstruction updateInstruction = pop();
      }
    }
    void buildBody() {
      visit(node.body);
    }
    handleLoop(node, buildInitializer, buildCondition, buildUpdate, buildBody);
  }

  visitWhile(While node) {
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

  visitDoWhile(DoWhile node) {
    assert(isReachable);
    LocalsHandler savedLocals = new LocalsHandler.from(localsHandler);
    localsHandler.startLoop(node);
    JumpHandler jumpHandler = beginLoopHeader(node);
    HLoopInformation loopInfo = current.loopInformation;
    HBasicBlock loopEntryBlock = current;
    HBasicBlock bodyEntryBlock = current;
    TargetElement target = elements[node];
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
        List<LabelElement> labels = jumpHandler.labels();
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

      endLoop(loopEntryBlock, conditionEndBlock, jumpHandler, localsHandler);

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
              sourceFileLocationForBeginToken(node),
              sourceFileLocationForEndToken(node));
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
        TargetElement target = elements[node];
        LabelElement label = target.addLabel(null, 'loop');
        label.setBreakTarget();
        HLabeledBlockInformation info = new HLabeledBlockInformation(
            new HSubGraphBlockInformation(bodyGraph), <LabelElement>[label]);
        loopEntryBlock.setBlockFlow(info, current);
        jumpHandler.forEachBreak((HBreak breakInstruction, _) {
          HBasicBlock block = breakInstruction.block;
          block.addAtExit(new HBreak.toLabel(label));
          block.remove(breakInstruction);
        });
      }
    }
    jumpHandler.close();
  }

  visitFunctionExpression(FunctionExpression node) {
    ClosureClassMap nestedClosureData =
        compiler.closureToClassMapper.getMappingForNestedFunction(node);
    assert(nestedClosureData != null);
    assert(nestedClosureData.closureClassElement != null);
    ClassElement closureClassElement =
        nestedClosureData.closureClassElement;
    FunctionElement callElement = nestedClosureData.callElement;
    // TODO(ahe): This should be registered in codegen, not here.
    compiler.enqueuer.codegen.addToWorkList(callElement, elements);
    // TODO(ahe): This should be registered in codegen, not here.
    compiler.enqueuer.codegen.registerInstantiatedClass(
        closureClassElement, work.resolutionTree);
    assert(!closureClassElement.hasLocalScopeMembers);

    List<HInstruction> capturedVariables = <HInstruction>[];
    closureClassElement.forEachBackendMember((Element member) {
      // The backendMembers also contains the call method(s). We are only
      // interested in the fields.
      if (member.isField()) {
        Element capturedLocal = nestedClosureData.capturedFieldMapping[member];
        assert(capturedLocal != null);
        capturedVariables.add(localsHandler.readLocal(capturedLocal));
      }
    });

    HType type = new HType.nonNullExact(
        compiler.functionClass.computeType(compiler),
        compiler);
    push(new HForeignNew(closureClassElement, type, capturedVariables));
  }

  visitFunctionDeclaration(FunctionDeclaration node) {
    assert(isReachable);
    visit(node.function);
    localsHandler.updateLocal(elements[node], pop());
  }

  visitIdentifier(Identifier node) {
    if (node.isThis()) {
      stack.add(localsHandler.readThis());
    } else {
      compiler.internalError("SsaBuilder.visitIdentifier on non-this",
                             node: node);
    }
  }

  visitIf(If node) {
    assert(isReachable);
    handleIf(node,
             () => visit(node.condition),
             () => visit(node.thenPart),
             node.elsePart != null ? () => visit(node.elsePart) : null);
  }

  void handleIf(Node diagnosticNode,
                void visitCondition(), void visitThen(), void visitElse()) {
    SsaBranchBuilder branchBuilder = new SsaBranchBuilder(this, diagnosticNode);
    branchBuilder.handleIf(visitCondition, visitThen, visitElse);
  }

  void visitLogicalAndOr(Send node, Operator op) {
    SsaBranchBuilder branchBuilder = new SsaBranchBuilder(this, node);
    branchBuilder.handleLogicalAndOrWithLeftNode(
        node.receiver,
        () { visit(node.argumentsNode); },
        isAnd: (const SourceString("&&") == op.source));
  }

  void visitLogicalNot(Send node) {
    assert(node.argumentsNode is Prefix);
    visit(node.receiver);
    HNot not = new HNot(popBoolified());
    pushWithPosition(not, node);
  }

  void visitUnary(Send node, Operator op) {
    if (node.isParameterCheck) {
      Element element = elements[node.receiver];
      Node function = element.enclosingElement.parseNode(compiler);
      ClosureClassMap parameterClosureData =
          compiler.closureToClassMapper.getMappingForNestedFunction(function);
      Element fieldCheck =
          parameterClosureData.parametersWithSentinel[element];
      stack.add(localsHandler.readLocal(fieldCheck));
      return;
    }
    assert(node.argumentsNode is Prefix);
    visit(node.receiver);
    assert(!identical(op.token.kind, PLUS_TOKEN));
    HInstruction operand = pop();

    // See if we can constant-fold right away. This avoids rewrites later on.
    if (operand is HConstant) {
      UnaryOperation operation = constantSystem.lookupUnary(op.source);
      HConstant constant = operand;
      Constant folded = operation.fold(constant.constant);
      if (folded != null) {
        stack.add(graph.addConstant(folded));
        return;
      }
    }

    HInvokeDynamicMethod result =
        buildInvokeDynamic(node, elements.getSelector(node), operand, []);
    pushWithPosition(result, node);
  }

  void visitBinary(HInstruction left,
                   Operator op,
                   HInstruction right,
                   Selector selector,
                   Send send) {
    switch (op.source.stringValue) {
      case "===":
        pushWithPosition(new HIdentity(left, right), op);
        return;
      case "!==":
        HIdentity eq = new HIdentity(left, right);
        add(eq);
        pushWithPosition(new HNot(eq), op);
        return;
    }

    pushWithPosition(
          buildInvokeDynamic(send, selector, left, [right]),
          op);
    if (op.source.stringValue == '!=') {
      pushWithPosition(new HNot(popBoolified()), op);
    }
  }

  HInstruction generateInstanceSendReceiver(Send send) {
    assert(Elements.isInstanceSend(send, elements));
    if (send.receiver == null) {
      return localsHandler.readThis();
    }
    visit(send.receiver);
    return pop();
  }

  String getTargetName(ErroneousElement error, [String prefix]) {
    String result = error.name.slowToString();
    if (?prefix) {
      result = '$prefix $result';
    }
    return result;
  }

  /**
   * Returns a set of interceptor classes that contain the given
   * [selector].
   */
  void generateInstanceGetterWithCompiledReceiver(Send send,
                                                  Selector selector,
                                                  HInstruction receiver) {
    assert(Elements.isInstanceSend(send, elements));
    assert(selector.isGetter());
    SourceString getterName = selector.name;
    Set<ClassElement> interceptedClasses =
        backend.getInterceptedClassesOn(getterName);

    bool hasGetter = compiler.world.hasAnyUserDefinedGetter(selector);
    HInstruction instruction;
    if (interceptedClasses != null) {
      // If we're using an interceptor class, emit a call to the
      // interceptor method and then the actual dynamic call on the
      // interceptor object.
      instruction =
          invokeInterceptor(interceptedClasses, receiver, send);
      instruction = new HInvokeDynamicGetter(
          selector, null, instruction, !hasGetter);
      // Add the receiver as an argument to the getter call on the
      // interceptor.
      instruction.inputs.add(receiver);
    } else {
      instruction = new HInvokeDynamicGetter(
          selector, null, receiver, !hasGetter);
    }
    pushWithPosition(instruction, send);
  }

  void generateGetter(Send send, Element element) {
    if (Elements.isStaticOrTopLevelField(element)) {
      Constant value;
      if (element.isField() && !element.isAssignable()) {
        // A static final or const. Get its constant value and inline it if
        // the value can be compiled eagerly.
        value = compileVariable(element);
      }
      if (value != null) {
        stack.add(graph.addConstant(value));
      } else if (element.isField() && isLazilyInitialized(element)) {
        push(new HLazyStatic(element));
      } else {
        if (element.isGetter()) {
          Selector selector = elements.getSelector(send);
          if (tryInlineMethod(element, selector, const Link<Node>(), send)) {
            return;
          }
        }
        // TODO(5346): Try to avoid the need for calling [declaration] before
        // creating an [HStatic].
        push(new HStatic(element.declaration));
        if (element.isGetter()) {
          push(new HInvokeStatic(<HInstruction>[pop()], HType.UNKNOWN));
        }
      }
    } else if (Elements.isInstanceSend(send, elements)) {
      HInstruction receiver = generateInstanceSendReceiver(send);
      generateInstanceGetterWithCompiledReceiver(
          send, elements.getSelector(send), receiver);
    } else if (Elements.isStaticOrTopLevelFunction(element)) {
      // TODO(5346): Try to avoid the need for calling [declaration] before
      // creating an [HStatic].
      push(new HStatic(element.declaration));
      // TODO(ahe): This should be registered in codegen.
      compiler.enqueuer.codegen.registerGetOfStaticFunction(element);
    } else if (Elements.isErroneousElement(element)) {
      // An erroneous element indicates an unresolved static getter.
      generateThrowNoSuchMethod(send,
                                getTargetName(element, 'get'),
                                argumentNodes: const Link<Node>());
    } else {
      stack.add(localsHandler.readLocal(element));
    }
  }

  void generateInstanceSetterWithCompiledReceiver(Send send,
                                                  HInstruction receiver,
                                                  HInstruction value,
                                                  {Selector selector,
                                                   Node location}) {
    assert(send == null || Elements.isInstanceSend(send, elements));
    if (selector == null) {
      assert(send != null);
      selector = elements.getSelector(send);
    }
    if (location == null) {
      assert(send != null);
      location = send;
    }
    assert(selector.isSetter());
    bool hasSetter = compiler.world.hasAnyUserDefinedSetter(selector);
    Set<ClassElement> interceptedClasses =
        backend.getInterceptedClassesOn(selector.name);
    HInstruction instruction;
    if (interceptedClasses != null) {
      // If we're using an interceptor class, emit a call to the
      // getInterceptor method and then the actual dynamic call on the
      // interceptor object.
      instruction = invokeInterceptor(interceptedClasses, receiver, send);
      instruction = new HInvokeDynamicSetter(
          selector, null, instruction, receiver, !hasSetter);
      // Add the value as an argument to the setter call on the
      // interceptor.
      instruction.inputs.add(value);
    } else {
      instruction = new HInvokeDynamicSetter(
          selector, null, receiver, value, !hasSetter);
    }
    addWithPosition(instruction, location);
    stack.add(value);
  }

  void generateNonInstanceSetter(SendSet send,
                                 Element element,
                                 HInstruction value) {
    assert(!Elements.isInstanceSend(send, elements));
    if (Elements.isStaticOrTopLevelField(element)) {
      if (element.isSetter()) {
        HStatic target = new HStatic(element);
        add(target);
        addWithPosition(
            new HInvokeStatic(<HInstruction>[target, value], HType.UNKNOWN),
            send);
      } else {
        value = potentiallyCheckType(value, element.computeType(compiler));
        addWithPosition(new HStaticStore(element, value), send);
      }
      stack.add(value);
    } else if (Elements.isErroneousElement(element)) {
      // An erroneous element indicates an unresolved static setter.
      generateThrowNoSuchMethod(send,
                                getTargetName(element, 'set'),
                                argumentNodes: send.arguments);
    } else {
      stack.add(value);
      // If the value does not already have a name, give it here.
      if (value.sourceElement == null) {
        value.sourceElement = element;
      }
      HInstruction checked = potentiallyCheckType(
          value, element.computeType(compiler));
      if (!identical(checked, value)) {
        pop();
        stack.add(checked);
      }
      localsHandler.updateLocal(element, checked);
    }
  }

  HInstruction invokeInterceptor(Set<ClassElement> intercepted,
                                 HInstruction receiver,
                                 Send send) {
    HInterceptor interceptor = new HInterceptor(intercepted, receiver);
    add(interceptor);
    return interceptor;
  }

  void pushInvokeHelper0(Element helper, HType type) {
    HInstruction reference = new HStatic(helper);
    add(reference);
    List<HInstruction> inputs = <HInstruction>[reference];
    HInstruction result = new HInvokeStatic(inputs, type);
    push(result);
  }

  void pushInvokeHelper1(Element helper, HInstruction a0, HType type) {
    HInstruction reference = new HStatic(helper);
    add(reference);
    List<HInstruction> inputs = <HInstruction>[reference, a0];
    HInstruction result = new HInvokeStatic(inputs, type);
    push(result);
  }

  void pushInvokeHelper2(Element helper,
                         HInstruction a0,
                         HInstruction a1,
                         HType type) {
    HInstruction reference = new HStatic(helper);
    add(reference);
    List<HInstruction> inputs = <HInstruction>[reference, a0, a1];
    HInstruction result = new HInvokeStatic(inputs, type);
    push(result);
  }

  void pushInvokeHelper3(Element helper,
                         HInstruction a0,
                         HInstruction a1,
                         HInstruction a2,
                         HType type) {
    HInstruction reference = new HStatic(helper);
    add(reference);
    List<HInstruction> inputs = <HInstruction>[reference, a0, a1, a2];
    HInstruction result = new HInvokeStatic(inputs, type);
    push(result);
  }

  void pushInvokeHelper4(Element helper,
                         HInstruction a0,
                         HInstruction a1,
                         HInstruction a2,
                         HInstruction a3,
                         HType type) {
    HInstruction reference = new HStatic(helper);
    add(reference);
    List<HInstruction> inputs = <HInstruction>[reference, a0, a1, a2, a3];
    HInstruction result = new HInvokeStatic(inputs, type);
    push(result);
  }

  void pushInvokeHelper5(Element helper,
                         HInstruction a0,
                         HInstruction a1,
                         HInstruction a2,
                         HInstruction a3,
                         HInstruction a4,
                         HType type) {
    HInstruction reference = new HStatic(helper);
    add(reference);
    List<HInstruction> inputs = <HInstruction>[reference, a0, a1, a2, a3, a4];
    HInstruction result = new HInvokeStatic(inputs, type);
    push(result);
  }

  HForeign createForeign(String code,
                         HType type,
                         List<HInstruction> inputs,
                         {bool isSideEffectFree: false}) {
    return new HForeign(new LiteralDartString(code),
                        type,
                        inputs,
                        isSideEffectFree: isSideEffectFree);
  }

  HInstruction getRuntimeTypeInfo(HInstruction target) {
    pushInvokeHelper1(backend.getGetRuntimeTypeInfo(), target, HType.UNKNOWN);
    return pop();
  }

  // TODO(karlklose): change construction of the representations to be GVN'able
  // (dartbug.com/7182).
  HInstruction buildTypeArgumentRepresentations(DartType type) {
    // Compute the representation of the type arguments, including access
    // to the runtime type information for type variables as instructions.
    if (type.kind == TypeKind.TYPE_VARIABLE) {
      return new HLiteralList(<HInstruction>[addTypeVariableReference(type)]);
    } else {
      assert(type.element.isClass());
      InterfaceType interface = type;
      List<HInstruction> inputs = <HInstruction>[];
      bool first = true;
      List<String> templates = <String>[];
      for (DartType argument in interface.typeArguments) {
        templates.add(rti.getTypeRepresentation(argument, (variable) {
          HInstruction runtimeType = addTypeVariableReference(variable);
          inputs.add(runtimeType);
        }));
      }
      String template = '[${templates.join(', ')}]';
      HInstruction representation =
        createForeign(template, HType.READABLE_ARRAY, inputs);
      return representation;
    }
  }

  visitOperatorSend(node) {
    Operator op = node.selector;
    if (const SourceString("[]") == op.source) {
      visitDynamicSend(node);
    } else if (const SourceString("&&") == op.source ||
               const SourceString("||") == op.source) {
      visitLogicalAndOr(node, op);
    } else if (const SourceString("!") == op.source) {
      visitLogicalNot(node);
    } else if (node.argumentsNode is Prefix) {
      visitUnary(node, op);
    } else if (const SourceString("is") == op.source) {
      visitIsSend(node);
    } else if (const SourceString("as") == op.source) {
      visit(node.receiver);
      HInstruction expression = pop();
      Node argument = node.arguments.head;
      TypeAnnotation typeAnnotation = argument.asTypeAnnotation();
      DartType type = elements.getType(typeAnnotation);
      HInstruction converted = expression.convertType(
          compiler, type, HTypeConversion.CAST_TYPE_CHECK);
      if (converted != expression) add(converted);
      stack.add(converted);
    } else {
      visit(node.receiver);
      visit(node.argumentsNode);
      var right = pop();
      var left = pop();
      visitBinary(left, op, right, elements.getSelector(node), node);
    }
  }

  void visitIsSend(Send node) {
    Node argument = node.arguments.head;
    visit(node.receiver);
    HInstruction expression = pop();
    TypeAnnotation typeAnnotation = argument.asTypeAnnotation();
    bool isNot = false;
    // TODO(ngeoffray): Duplicating pattern in resolver. We should
    // add a new kind of node.
    if (typeAnnotation == null) {
      typeAnnotation = argument.asSend().receiver;
      isNot = true;
    }
    DartType type = elements.getType(typeAnnotation);
    if (type.isMalformed) {
      String reasons = Types.fetchReasonsFromMalformedType(type);
      if (compiler.enableTypeAssertions) {
        generateMalformedSubtypeError(node, expression, type, reasons);
      } else {
        generateRuntimeError(node, '$type is malformed: $reasons');
      }
      return;
    }

    HInstruction instruction;
    if (type.kind == TypeKind.TYPE_VARIABLE) {
      HInstruction runtimeType = addTypeVariableReference(type);
      Element helper = backend.getGetObjectIsSubtype();
      HInstruction helperCall = new HStatic(helper);
      add(helperCall);
      List<HInstruction> inputs = <HInstruction>[helperCall, expression,
                                                 runtimeType];
      HInstruction call = new HInvokeStatic(inputs, HType.BOOLEAN);
      add(call);
      instruction = new HIs(type, <HInstruction>[expression, call],
                            HIs.VARIABLE_CHECK);
    } else if (RuntimeTypes.hasTypeArguments(type)) {
      Element element = type.element;
      Element helper = backend.getCheckSubtype();
      HInstruction helperCall = new HStatic(helper);
      add(helperCall);
      HInstruction representations =
        buildTypeArgumentRepresentations(type);
      add(representations);
      HInstruction isFieldName =
          addConstantString(node, backend.namer.operatorIs(element));
      // TODO(karlklose): use [:null:] for [asField] if [element] does not
      // have a subclass.
      HInstruction asFieldName =
          addConstantString(node, backend.namer.substitutionName(element));
      List<HInstruction> inputs = <HInstruction>[helperCall,
                                                 expression,
                                                 isFieldName,
                                                 representations,
                                                 asFieldName];
      HInstruction call = new HInvokeStatic(inputs, HType.BOOLEAN);
      add(call);
      instruction = new HIs(type, <HInstruction>[expression, call],
                            HIs.COMPOUND_CHECK);
    } else {
      instruction = new HIs(type, <HInstruction>[expression], HIs.RAW_CHECK);
    }
    if (isNot) {
      add(instruction);
      instruction = new HNot(instruction);
    }
    push(instruction);
  }

  void addDynamicSendArgumentsToList(Send node, List<HInstruction> list) {
    Selector selector = elements.getSelector(node);
    if (selector.namedArgumentCount == 0) {
      addGenericSendArgumentsToList(node.arguments, list);
    } else {
      // Visit positional arguments and add them to the list.
      Link<Node> arguments = node.arguments;
      int positionalArgumentCount = selector.positionalArgumentCount;
      for (int i = 0;
           i < positionalArgumentCount;
           arguments = arguments.tail, i++) {
        visit(arguments.head);
        list.add(pop());
      }

      // Visit named arguments and add them into a temporary map.
      Map<SourceString, HInstruction> instructions =
          new Map<SourceString, HInstruction>();
      List<SourceString> namedArguments = selector.namedArguments;
      int nameIndex = 0;
      for (; !arguments.isEmpty; arguments = arguments.tail) {
        visit(arguments.head);
        instructions[namedArguments[nameIndex++]] = pop();
      }

      // Iterate through the named arguments to add them to the list
      // of instructions, in an order that can be shared with
      // selectors with the same named arguments.
      List<SourceString> orderedNames = selector.getOrderedNamedArguments();
      for (SourceString name in orderedNames) {
        list.add(instructions[name]);
      }
    }
  }

  /**
   * Returns true if the arguments were compatible with the function signature.
   *
   * Invariant: [element] must be an implementation element.
   */
  bool addStaticSendArgumentsToList(Selector selector,
                                    Link<Node> arguments,
                                    FunctionElement element,
                                    List<HInstruction> list) {
    assert(invariant(element, element.isImplementation));

    HInstruction compileArgument(Node argument) {
      visit(argument);
      return pop();
    }

    HInstruction handleConstant(Element parameter) {
      Constant constant;
      TreeElements calleeElements =
          compiler.enqueuer.resolution.getCachedElements(element);
      if (calleeElements.isParameterChecked(parameter)) {
        constant = SentinelConstant.SENTINEL;
      } else {
        constant = compileConstant(parameter);
      }
      return graph.addConstant(constant);
    }

    return selector.addArgumentsToList(arguments,
                                       list,
                                       element,
                                       compileArgument,
                                       handleConstant,
                                       compiler);
  }

  void addGenericSendArgumentsToList(Link<Node> link, List<HInstruction> list) {
    for (; !link.isEmpty; link = link.tail) {
      visit(link.head);
      list.add(pop());
    }
  }

  bool isThisSend(Send send) {
    Node receiver = send.receiver;
    if (receiver == null) return true;
    Identifier identifier = receiver.asIdentifier();
    return identifier != null && identifier.isThis();
  }

  visitDynamicSend(Send node, {bool inline: true}) {
    Selector selector = elements.getSelector(node);

    // TODO(kasperl): It would be much better to try to get the
    // guaranteed type of the receiver after we've evaluated it, but
    // because of the way inlining currently works that is hard to do
    // with re-evaluating the receiver.
    if (isThisSend(node)) {
      HType receiverType = getTypeOfThis();
      selector = receiverType.refine(selector, compiler);
    }

    Element element = compiler.world.locateSingleElement(selector);
    bool isClosureCall = false;
    if (inline && element != null) {
      if (tryInlineMethod(element, selector, node.arguments, node)) {
        if (element.isGetter()) {
          // If the element is a getter, we are doing a closure call
          // on what this getter returns.
          assert(selector.isCall());
          isClosureCall = true;
        } else {
          return;
        }
      }
    }

    List<HInstruction> inputs = <HInstruction>[];
    if (isClosureCall) inputs.add(pop());

    HInstruction receiver;
    if (!isClosureCall) {
      if (node.receiver == null) {
        receiver = localsHandler.readThis();
      } else {
        visit(node.receiver);
        receiver = pop();
      }
    }

    addDynamicSendArgumentsToList(node, inputs);

    HInstruction invoke;
    if (isClosureCall) {
      Selector closureSelector = new Selector.callClosureFrom(selector);
      invoke = new HInvokeClosure(closureSelector, inputs);
    } else {
      invoke = buildInvokeDynamic(node, selector, receiver, inputs);
    }

    pushWithPosition(invoke, node);
  }

  visitClosureSend(Send node) {
    Selector selector = elements.getSelector(node);
    assert(node.receiver == null);
    Element element = elements[node];
    HInstruction closureTarget;
    if (element == null) {
      visit(node.selector);
      closureTarget = pop();
    } else {
      assert(Elements.isLocal(element));
      closureTarget = localsHandler.readLocal(element);
    }
    var inputs = <HInstruction>[];
    inputs.add(closureTarget);
    addDynamicSendArgumentsToList(node, inputs);
    Selector closureSelector = new Selector.callClosureFrom(selector);
    pushWithPosition(new HInvokeClosure(closureSelector, inputs), node);
  }

  void handleForeignJs(Send node) {
    Link<Node> link = node.arguments;
    // If the invoke is on foreign code, don't visit the first
    // argument, which is the type, and the second argument,
    // which is the foreign code.
    if (link.isEmpty || link.tail.isEmpty) {
      compiler.cancel('At least two arguments expected',
                      node: node.argumentsNode);
    }
    List<HInstruction> inputs = <HInstruction>[];
    Node type = link.head;
    Node code = link.tail.head;
    addGenericSendArgumentsToList(link.tail.tail, inputs);

    native.NativeBehavior nativeBehavior =
        compiler.enqueuer.resolution.nativeEnqueuer.getNativeBehaviorOf(node);
    HType ssaType = new HType.fromNativeBehavior(nativeBehavior, compiler);
    if (code is StringNode) {
      StringNode codeString = code;
      if (!codeString.isInterpolation) {
        // codeString may not be an interpolation, but may be a juxtaposition.
        push(new HForeign(codeString.dartString, ssaType, inputs));
        return;
      }
    }
    compiler.cancel('JS code must be a string literal', node: code);
  }

  void handleForeignJsCurrentIsolate(Send node) {
    if (!node.arguments.isEmpty) {
      compiler.cancel(
          'Too many arguments to JS_CURRENT_ISOLATE', node: node);
    }

    if (!compiler.hasIsolateSupport()) {
      // If the isolate library is not used, we just generate code
      // to fetch the Leg's current isolate.
      String name = backend.namer.CURRENT_ISOLATE;
      push(new HForeign(new DartString.literal(name),
                        HType.UNKNOWN,
                        <HInstruction>[]));
    } else {
      // Call a helper method from the isolate library. The isolate
      // library uses its own isolate structure, that encapsulates
      // Leg's isolate.
      Element element = compiler.isolateHelperLibrary.find(
          const SourceString('_currentIsolate'));
      if (element == null) {
        compiler.cancel(
            'Isolate library and compiler mismatch', node: node);
      }
      pushInvokeHelper0(element, HType.UNKNOWN);
    }
  }

  void handleForeignJsCallInIsolate(Send node) {
    Link<Node> link = node.arguments;
    if (!compiler.hasIsolateSupport()) {
      // If the isolate library is not used, we just invoke the
      // closure.
      visit(link.tail.head);
      Selector selector = new Selector.callClosure(0);
      push(new HInvokeClosure(selector, <HInstruction>[pop()]));
    } else {
      // Call a helper method from the isolate library.
      Element element = compiler.isolateHelperLibrary.find(
          const SourceString('_callInIsolate'));
      if (element == null) {
        compiler.cancel(
            'Isolate library and compiler mismatch', node: node);
      }
      HStatic target = new HStatic(element);
      add(target);
      List<HInstruction> inputs = <HInstruction>[target];
      addGenericSendArgumentsToList(link, inputs);
      push(new HInvokeStatic(inputs, HType.UNKNOWN));
    }
  }

  FunctionSignature handleForeignRawFunctionRef(Send node, String name) {
    if (node.arguments.isEmpty || !node.arguments.tail.isEmpty) {
      compiler.cancel('"$name" requires exactly one argument',
                      node: node.argumentsNode);
    }
    Node closure = node.arguments.head;
    Element element = elements[closure];
    if (!Elements.isStaticOrTopLevelFunction(element)) {
      compiler.cancel(
          '"$name" requires a static or top-level method',
          node: closure);
    }
    FunctionElement function = element;
    // TODO(johnniwinther): Try to eliminate the need to distinguish declaration
    // and implementation signatures. Currently it is need because the
    // signatures have different elements for parameters.
    FunctionElement implementation = function.implementation;
    FunctionSignature params = implementation.computeSignature(compiler);
    if (params.optionalParameterCount != 0) {
      compiler.cancel(
          '"$name" does not handle closure with optional parameters',
          node: closure);
    }
    visit(closure);
    return params;
  }

  void handleForeignDartClosureToJs(Send node, String name) {
    FunctionSignature params = handleForeignRawFunctionRef(node, name);
    List<HInstruction> inputs = <HInstruction>[pop()];
    String invocationName = backend.namer.invocationName(
        new Selector.callClosure(params.requiredParameterCount));
    push(new HForeign(new DartString.literal('#.$invocationName'),
                      HType.UNKNOWN,
                      inputs));
  }

  void handleForeignSetCurrentIsolate(Send node) {
    if (node.arguments.isEmpty || !node.arguments.tail.isEmpty) {
      compiler.cancel('Exactly one argument required',
                      node: node.argumentsNode);
    }
    visit(node.arguments.head);
    String isolateName = backend.namer.CURRENT_ISOLATE;
    push(new HForeign(new DartString.literal("$isolateName = #"),
                      HType.UNKNOWN,
                      <HInstruction>[pop()]));
  }

  void handleForeignCreateIsolate(Send node) {
    if (!node.arguments.isEmpty) {
      compiler.cancel('Too many arguments',
                      node: node.argumentsNode);
    }
    String constructorName = backend.namer.isolateName;
    push(new HForeign(new DartString.literal("new $constructorName()"),
                      HType.UNKNOWN,
                      <HInstruction>[]));
  }

  void handleForeignDartObjectJsConstructorFunction(Send node) {
    if (!node.arguments.isEmpty) {
      compiler.cancel('Too many arguments', node: node.argumentsNode);
    }
    String jsClassReference = backend.namer.isolateAccess(compiler.objectClass);
    push(new HForeign(new DartString.literal(jsClassReference),
                      HType.UNKNOWN,
                      <HInstruction>[]));
  }

  visitForeignSend(Send node) {
    Selector selector = elements.getSelector(node);
    SourceString name = selector.name;
    if (name == const SourceString('JS')) {
      handleForeignJs(node);
    } else if (name == const SourceString('JS_CURRENT_ISOLATE')) {
      handleForeignJsCurrentIsolate(node);
    } else if (name == const SourceString('JS_CALL_IN_ISOLATE')) {
      handleForeignJsCallInIsolate(node);
    } else if (name == const SourceString('DART_CLOSURE_TO_JS')) {
      handleForeignDartClosureToJs(node, 'DART_CLOSURE_TO_JS');
    } else if (name == const SourceString('RAW_DART_FUNCTION_REF')) {
      handleForeignRawFunctionRef(node, 'RAW_DART_FUNCTION_REF');
    } else if (name == const SourceString('JS_SET_CURRENT_ISOLATE')) {
      handleForeignSetCurrentIsolate(node);
    } else if (name == const SourceString('JS_CREATE_ISOLATE')) {
      handleForeignCreateIsolate(node);
    } else if (name == const SourceString('JS_OPERATOR_IS_PREFIX')) {
      stack.add(addConstantString(node, backend.namer.operatorIsPrefix()));
    } else if (name == const SourceString('JS_OPERATOR_AS_PREFIX')) {
      stack.add(addConstantString(node, backend.namer.operatorAsPrefix()));
    } else if (name == const SourceString('JS_DART_OBJECT_CONSTRUCTOR')) {
      handleForeignDartObjectJsConstructorFunction(node);
    } else {
      throw "Unknown foreign: ${selector}";
    }
  }

  generateSuperNoSuchMethodSend(Send node,
                                Selector selector,
                                List<HInstruction> arguments) {
    SourceString name = selector.name;

    ClassElement cls = currentElement.getEnclosingClass();
    Element element = cls.lookupSuperMember(Compiler.NO_SUCH_METHOD);
    if (element.enclosingElement.declaration != compiler.objectClass) {
      // Register the call as dynamic if [:noSuchMethod:] on the super class
      // is _not_ the default implementation from [:Object:], in case
      // the [:noSuchMethod:] implementation does an [:invokeOn:] on
      // the invocation mirror.
      compiler.enqueuer.codegen.registerSelectorUse(selector);
    }
    HStatic target = new HStatic(element);
    add(target);
    HInstruction self = localsHandler.readThis();
    Constant nameConstant = constantSystem.createString(
        new DartString.literal(name.slowToString()), node);

    String internalName = backend.namer.invocationName(selector);
    Constant internalNameConstant =
        constantSystem.createString(new DartString.literal(internalName), node);

    Element createInvocationMirror = backend.getCreateInvocationMirror();
    var argumentsInstruction = new HLiteralList(arguments);
    add(argumentsInstruction);

    var argumentNames = new List<HInstruction>();
    for (SourceString argumentName in selector.namedArguments) {
      Constant argumentNameConstant =
          constantSystem.createString(new DartString.literal(
              argumentName.slowToString()), node);
      argumentNames.add(graph.addConstant(argumentNameConstant));
    }
    var argumentNamesInstruction = new HLiteralList(argumentNames);
    add(argumentNamesInstruction);

    Constant kindConstant =
        constantSystem.createInt(selector.invocationMirrorKind);

    pushInvokeHelper5(createInvocationMirror,
                      graph.addConstant(nameConstant),
                      graph.addConstant(internalNameConstant),
                      graph.addConstant(kindConstant),
                      argumentsInstruction,
                      argumentNamesInstruction,
                      HType.UNKNOWN);

    var inputs = <HInstruction>[target, self];
    if (backend.isInterceptedMethod(element)) {
      inputs.add(self);
    }
    inputs.add(pop());
    push(new HInvokeSuper(inputs));
  }

  visitSend(Send node) {
    Element element = elements[node];
    if (element != null && identical(element, currentElement)) {
      graph.isRecursiveMethod = true;
    }
    super.visitSend(node);
  }

  visitSuperSend(Send node) {
    Selector selector = elements.getSelector(node);
    Element element = elements[node];
    if (Elements.isUnresolved(element)) {
      List<HInstruction> arguments = <HInstruction>[];
      if (!node.isPropertyAccess) {
        addGenericSendArgumentsToList(node.arguments, arguments);
      }
      return generateSuperNoSuchMethodSend(node, selector, arguments);
    }
    List<HInstruction> inputs = buildSuperAccessorInputs(element);
    if (node.isPropertyAccess) {
      HInstruction invokeSuper = new HInvokeSuper(inputs);
      invokeSuper.instructionType =
          new HType.inferredTypeForElement(element, compiler);
      push(invokeSuper);
    } else if (element.isFunction() || element.isGenerativeConstructor()) {
      // TODO(5347): Try to avoid the need for calling [implementation] before
      // calling [addStaticSendArgumentsToList].
      FunctionElement function = element.implementation;
      bool succeeded = addStaticSendArgumentsToList(selector, node.arguments,
                                                    function, inputs);
      if (!succeeded) {
        generateWrongArgumentCountError(node, element, node.arguments);
      } else {
        HInstruction invokeSuper = new HInvokeSuper(inputs);
        invokeSuper.instructionType =
            new HType.inferredReturnTypeForElement(element, compiler);
        push(invokeSuper);
      }
    } else {
      HInstruction target = new HInvokeSuper(inputs);
      target.instructionType =
          new HType.inferredTypeForElement(element, compiler);
      add(target);
      inputs = <HInstruction>[target];
      addDynamicSendArgumentsToList(node, inputs);
      Selector closureSelector = new Selector.callClosureFrom(selector);
      push(new HInvokeClosure(closureSelector, inputs));
    }
  }

  /**
   * Generate code to extract the type arguments from the object, substitute
   * them as an instance of the type we are testing against (if necessary), and
   * extract the type argument by the index of the variable in the list of type
   * variables for that class.
   */
  HInstruction readTypeVariable(ClassElement cls,
                                TypeVariableElement variable) {
    assert(currentElement.isInstanceMember());
    int index = RuntimeTypes.getTypeVariableIndex(variable);
    String substitutionNameString = backend.namer.substitutionName(cls);
    HInstruction substitutionName = graph.addConstantString(
        new LiteralDartString(substitutionNameString), null, constantSystem);
    HInstruction target = localsHandler.readThis();
    HInstruction substitution = createForeign('#[#]', HType.UNKNOWN,
        <HInstruction>[target, substitutionName]);
    add(substitution);
    pushInvokeHelper3(backend.getGetRuntimeTypeArgument(),
                      target,
                      substitution,
                      graph.addConstantInt(index, constantSystem),
                      HType.UNKNOWN);
    return pop();
  }

  /**
   * Helper to create an instruction that gets the value of a type variable.
   */
  HInstruction addTypeVariableReference(TypeVariableType type) {
    Element member = currentElement;
    if (member.enclosingElement.isClosure()) {
      ClosureClassElement closureClass = member.enclosingElement;
      member = closureClass.methodElement;
      member = member.getOutermostEnclosingMemberOrTopLevel();
    }
    if (member.isConstructor()
        || member.isGenerativeConstructorBody()
        || member.isField()) {
      // The type variable is stored in a parameter of the method.
      return localsHandler.readLocal(type.element);
    } else if (member.isInstanceMember()) {
      // The type variable is stored on the object.
      return readTypeVariable(member.getEnclosingClass(),
                              type.element);
    } else {
      // TODO(ngeoffray): Match the VM behavior and throw an
      // exception at runtime.
      compiler.cancel('Unimplemented unresolved type variable',
                      element: type.element);
    }
  }

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [argument] must not be malformed in checked mode.
   */
  HInstruction analyzeTypeArgument(DartType argument, Node currentNode) {
    assert(invariant(currentNode,
                     !compiler.enableTypeAssertions || !argument.isMalformed,
                     message: '$argument is malformed in checked mode'));
    if (argument == compiler.types.dynamicType || argument.isMalformed) {
      // Represent [dynamic] as [null].
      return graph.addConstantNull(constantSystem);
    }

    List<HInstruction> inputs = <HInstruction>[];

    String template = rti.getTypeRepresentation(argument, (variable) {
      inputs.add(addTypeVariableReference(variable));
    });

    HInstruction result = createForeign(
        template, HType.STRING, inputs, isSideEffectFree: true);
    add(result);
    return result;
  }

  void handleListConstructor(InterfaceType type,
                             Node currentNode,
                             HInstruction newObject) {
    if (!backend.needsRti(type.element)) return;
    if (!type.isRaw) {
      List<HInstruction> inputs = <HInstruction>[];
      type.typeArguments.forEach((DartType argument) {
        inputs.add(analyzeTypeArgument(argument, currentNode));
      });
      callSetRuntimeTypeInfo(type.element, inputs, newObject);
    }
  }

  void callSetRuntimeTypeInfo(ClassElement element,
                              List<HInstruction> rtiInputs,
                              HInstruction newObject) {
    if (!backend.needsRti(element) || element.typeVariables.isEmpty) {
      return;
    }

    HInstruction typeInfo = new HLiteralList(rtiInputs);
    add(typeInfo);

    // Set the runtime type information on the object.
    Element typeInfoSetterElement = backend.getSetRuntimeTypeInfo();
    HInstruction typeInfoSetter = new HStatic(typeInfoSetterElement);
    add(typeInfoSetter);
    add(new HInvokeStatic(
        <HInstruction>[typeInfoSetter, newObject, typeInfo], HType.UNKNOWN));
  }

  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [type] must not be malformed in checked mode.
   */
  visitNewSend(Send node, InterfaceType type) {
    assert(invariant(node,
                     !compiler.enableTypeAssertions || !type.isMalformed,
                     message: '$type is malformed in checked mode'));
    bool isListConstructor = false;
    computeType(element) {
      Element originalElement = elements[node];
      if (Elements.isFixedListConstructorCall(
              originalElement, node, compiler)) {
        isListConstructor = true;
        return HType.FIXED_ARRAY;
      } else if (Elements.isGrowableListConstructorCall(
                    originalElement, node, compiler)) {
        isListConstructor = true;
        return HType.EXTENDABLE_ARRAY;
      } else if (element.isGenerativeConstructor()) {
        ClassElement cls = element.getEnclosingClass();
        return new HType.nonNullExact(cls.thisType, compiler);
      } else {
        return HType.UNKNOWN;
      }
    }

    Element constructor = elements[node];
    Selector selector = elements.getSelector(node);
    if (compiler.enqueuer.resolution.getCachedElements(constructor) == null) {
      compiler.internalError("Unresolved element: $constructor", node: node);
    }
    FunctionElement functionElement = constructor;
    constructor = functionElement.redirectionTarget;
    // TODO(5346): Try to avoid the need for calling [declaration] before
    // creating an [HStatic].
    HInstruction target = new HStatic(constructor.declaration);
    add(target);
    var inputs = <HInstruction>[];
    inputs.add(target);
    // TODO(5347): Try to avoid the need for calling [implementation] before
    // calling [addStaticSendArgumentsToList].
    bool succeeded = addStaticSendArgumentsToList(selector, node.arguments,
                                                  constructor.implementation,
                                                  inputs);
    if (!succeeded) {
      generateWrongArgumentCountError(node, constructor, node.arguments);
      return;
    }

    ClassElement cls = constructor.getEnclosingClass();
    if (cls.isAbstract(compiler) && constructor.isGenerativeConstructor()) {
      generateAbstractClassInstantiationError(node, cls.name.slowToString());
      return;
    }
    if (backend.needsRti(cls)) {
      Link<DartType> typeVariable = cls.typeVariables;
      type.typeArguments.forEach((DartType argument) {
        inputs.add(analyzeTypeArgument(argument, node));
        typeVariable = typeVariable.tail;
      });
      // Also add null to non-provided type variables to call the
      // constructor with the right number of arguments.
      while (!typeVariable.isEmpty) {
        inputs.add(graph.addConstantNull(constantSystem));
        typeVariable = typeVariable.tail;
      }
    }

    if (constructor.isFactoryConstructor() && !type.typeArguments.isEmpty) {
      compiler.enqueuer.codegen.registerFactoryWithTypeArguments(elements);
    }
    HType elementType = computeType(constructor);
    HInstruction newInstance = new HInvokeStatic(inputs, elementType);
    pushWithPosition(newInstance, node);

    // The List constructor forwards to a Dart static method that does
    // not know about the type argument. Therefore we special case
    // this constructor to have the setRuntimeTypeInfo called where
    // the 'new' is done.
    if (isListConstructor && backend.needsRti(compiler.listClass)) {
      handleListConstructor(type, node, newInstance);
    }
  }

  visitStaticSend(Send node) {
    Selector selector = elements.getSelector(node);
    Element element = elements[node];
    if (element.isForeign(compiler)) {
      visitForeignSend(node);
      return;
    }
    if (element.isErroneous()) {
      generateThrowNoSuchMethod(node,
                                getTargetName(element),
                                argumentNodes: node.arguments);
      return;
    }
    if (identical(element, compiler.assertMethod)
        && !compiler.enableUserAssertions) {
      stack.add(graph.addConstantNull(constantSystem));
      return;
    }
    compiler.ensure(!element.isGenerativeConstructor());
    if (element.isFunction()) {
      bool isIdenticalFunction = element == compiler.identicalFunction;

      if (!isIdenticalFunction
          && tryInlineMethod(element, selector, node.arguments, node)) {
        return;
      }

      HInstruction target = new HStatic(element);
      add(target);
      var inputs = <HInstruction>[target];
      // TODO(5347): Try to avoid the need for calling [implementation] before
      // calling [addStaticSendArgumentsToList].
      bool succeeded = addStaticSendArgumentsToList(selector, node.arguments,
                                                    element.implementation,
                                                    inputs);
      if (!succeeded) {
        generateWrongArgumentCountError(node, element, node.arguments);
        return;
      }

      if (isIdenticalFunction) {
        pushWithPosition(new HIdentity(inputs[1], inputs[2]), node);
        return;
      }

      HInvokeStatic instruction = new HInvokeStatic(inputs, HType.UNKNOWN);
      HType returnType =
          new HType.inferredReturnTypeForElement(element, compiler);
      if (returnType.isUnknown()) {
        // TODO(ngeoffray): Only do this if knowing the return type is
        // useful.
        returnType =
            builder.backend.optimisticReturnTypesWithRecompilationOnTypeChange(
                currentElement, element);
      }
      if (returnType != null) instruction.instructionType = returnType;
      pushWithPosition(instruction, node);
    } else {
      generateGetter(node, element);
      List<HInstruction> inputs = <HInstruction>[pop()];
      addDynamicSendArgumentsToList(node, inputs);
      Selector closureSelector = new Selector.callClosureFrom(selector);
      pushWithPosition(new HInvokeClosure(closureSelector, inputs), node);
    }
  }

  HConstant addConstantString(Node node, String string) {
    DartString dartString = new DartString.literal(string);
    Constant constant = constantSystem.createString(dartString, node);
    return graph.addConstant(constant);
  }

  visitTypeReferenceSend(Send node) {
    Element element = elements[node];
    if (element.isClass() || element.isTypedef()) {
      // TODO(karlklose): add type representation
      ConstantHandler handler = compiler.constantHandler;
      Constant constant = handler.compileNodeWithDefinitions(node, elements);
      stack.add(graph.addConstant(constant));
    } else if (element.isTypeVariable()) {
      HInstruction value =
          addTypeVariableReference(element.computeType(compiler));
      pushInvokeHelper1(backend.getRuntimeTypeToString(),
                        value, HType.STRING);
      pushInvokeHelper1(backend.getCreateRuntimeType(),
                        pop(), HType.UNKNOWN);
    } else {
      internalError('unexpected element kind $element', node: node);
    }
    if (node.isCall) {
      // This send is of the form 'e(...)', where e is resolved to a type
      // reference. We create a regular closure call on the result of the type
      // reference instead of creating a NoSuchMethodError to avoid pulling it
      // in if it is not used (e.g., in a try/catch).
      HInstruction target = pop();
      Selector selector = elements.getSelector(node);
      List<HInstruction> inputs = <HInstruction>[target];
      addDynamicSendArgumentsToList(node, inputs);
      Selector closureSelector = new Selector.callClosureFrom(selector);
      push(new HInvokeClosure(closureSelector, inputs));
    }
  }

  visitGetterSend(Send node) {
    generateGetter(node, elements[node]);
  }

  // TODO(antonm): migrate rest of SsaBuilder to internalError.
  internalError(String reason, {Node node}) {
    compiler.internalError(reason, node: node);
  }

  void generateError(Node node, String message, Element helper) {
    HInstruction errorMessage = addConstantString(node, message);
    pushInvokeHelper1(helper, errorMessage, HType.UNKNOWN);
  }

  void generateRuntimeError(Node node, String message) {
    generateError(node, message, backend.getThrowRuntimeError());
  }

  void generateAbstractClassInstantiationError(Node node, String message) {
    generateError(node,
                  message,
                  backend.getThrowAbstractClassInstantiationError());
  }

  void generateThrowNoSuchMethod(Node diagnosticNode,
                                 String methodName,
                                 {Link<Node> argumentNodes,
                                  List<HInstruction> argumentValues,
                                  List<String> existingArguments}) {
    Element helper = backend.getThrowNoSuchMethod();
    Constant receiverConstant =
        constantSystem.createString(new DartString.empty(), diagnosticNode);
    HInstruction receiver = graph.addConstant(receiverConstant);
    DartString dartString = new DartString.literal(methodName);
    Constant nameConstant =
        constantSystem.createString(dartString, diagnosticNode);
    HInstruction name = graph.addConstant(nameConstant);
    if (argumentValues == null) {
      argumentValues = <HInstruction>[];
      argumentNodes.forEach((argumentNode) {
        visit(argumentNode);
        HInstruction value = pop();
        argumentValues.add(value);
      });
    }
    HInstruction arguments = new HLiteralList(argumentValues);
    add(arguments);
    HInstruction existingNamesList;
    if (existingArguments != null) {
      List<HInstruction> existingNames = <HInstruction>[];
      for (String name in existingArguments) {
        HInstruction nameConstant =
            graph.addConstantString(new DartString.literal(name),
                                    diagnosticNode, constantSystem);
        existingNames.add(nameConstant);
      }
      existingNamesList = new HLiteralList(existingNames);
      add(existingNamesList);
    } else {
      existingNamesList = graph.addConstantNull(constantSystem);
    }
    pushInvokeHelper4(
        helper, receiver, name, arguments, existingNamesList, HType.UNKNOWN);
  }

  /**
   * Generate code to throw a [NoSuchMethodError] exception for calling a
   * method with a wrong number of arguments or mismatching named optional
   * arguments.
   */
  void generateWrongArgumentCountError(Node diagnosticNode,
                                       FunctionElement function,
                                       Link<Node> argumentNodes) {
    List<String> existingArguments = <String>[];
    FunctionSignature signature = function.computeSignature(compiler);
    signature.forEachParameter((Element parameter) {
      existingArguments.add(parameter.name.slowToString());
    });
    generateThrowNoSuchMethod(diagnosticNode,
                              function.name.slowToString(),
                              argumentNodes: argumentNodes,
                              existingArguments: existingArguments);
  }

  void generateMalformedSubtypeError(Node node, HInstruction value,
                                     DartType type, String reasons) {
    HInstruction typeString = addConstantString(node, type.toString());
    HInstruction reasonsString = addConstantString(node, reasons);
    Element helper = backend.getThrowMalformedSubtypeError();
    pushInvokeHelper3(helper, value, typeString, reasonsString, HType.UNKNOWN);
  }

  visitNewExpression(NewExpression node) {
    Element element = elements[node.send];
    if (!Elements.isErroneousElement(element)) {
      FunctionElement function = element;
      element = function.redirectionTarget;
    }
    if (Elements.isErroneousElement(element)) {
      ErroneousElement error = element;
      if (error.messageKind == MessageKind.CANNOT_FIND_CONSTRUCTOR) {
        generateThrowNoSuchMethod(node.send,
                                  getTargetName(error, 'constructor'),
                                  argumentNodes: node.send.arguments);
      } else {
        Message message = error.messageKind.message(error.messageArguments);
        generateRuntimeError(node.send, message.toString());
      }
    } else if (node.isConst()) {
      // TODO(karlklose): add type representation
      ConstantHandler handler = compiler.constantHandler;
      Constant constant = handler.compileNodeWithDefinitions(node, elements);
      stack.add(graph.addConstant(constant));
    } else {
      DartType type = elements.getType(node);
      if (compiler.enableTypeAssertions && type.isMalformed) {
        String reasons = Types.fetchReasonsFromMalformedType(type);
        // TODO(johnniwinther): Change to resemble type errors from bounds check
        // on type arguments.
        generateRuntimeError(node, '$type is malformed: $reasons');
      } else {
        // TODO(karlklose): move this type registration to the codegen.
        compiler.codegenWorld.instantiatedTypes.add(type);
        Send send = node.send;
        Element constructor = elements[send];
        Selector selector = elements.getSelector(send);
        if (!tryInlineMethod(constructor, selector, send.arguments, node)) {
          visitNewSend(send, type);
        }
      }
    }
  }

  HInvokeDynamicMethod buildInvokeDynamic(Node node,
                                          Selector selector,
                                          HInstruction receiver,
                                          List<HInstruction> arguments) {
    Set<ClassElement> interceptedClasses =
        backend.getInterceptedClassesOn(selector.name);
    List<HInstruction> inputs = <HInstruction>[];
    bool isIntercepted = interceptedClasses != null;
    if (isIntercepted) {
      assert(!interceptedClasses.isEmpty);
      inputs.add(invokeInterceptor(interceptedClasses, receiver, node));
    }
    inputs.add(receiver);
    inputs.addAll(arguments);
    return new HInvokeDynamicMethod(selector, inputs, isIntercepted);
  }

  void handleComplexOperatorSend(SendSet node,
                                 HInstruction receiver,
                                 Link<Node> arguments) {
    HInstruction rhs;
    if (node.isPrefix || node.isPostfix) {
      rhs = graph.addConstantInt(1, constantSystem);
    } else {
      visit(arguments.head);
      assert(arguments.tail.isEmpty);
      rhs = pop();
    }
    visitBinary(receiver, node.assignmentOperator, rhs,
                elements.getOperatorSelectorInComplexSendSet(node), node);
  }

  List<HInstruction> buildSuperAccessorInputs(Element element) {
    List<HInstruction> inputs = <HInstruction>[];
    if (Elements.isUnresolved(element)) return inputs;
    // TODO(5346): Try to avoid the need for calling [declaration] before
    // creating an [HStatic].
    HInstruction target = new HStatic(element.declaration);
    add(target);
    inputs.add(target);
    HInstruction context = localsHandler.readThis();
    inputs.add(context);
    if (backend.isInterceptedMethod(element)) {
      inputs.add(context);
    }
    return inputs;
  }


  visitSendSet(SendSet node) {
    Element element = elements[node];
    if (!Elements.isUnresolved(element) && element.impliesType()) {
      Identifier selector = node.selector;
      generateThrowNoSuchMethod(node, selector.source.slowToString(),
                                argumentNodes: node.arguments);
      return;
    }
    Operator op = node.assignmentOperator;
    if (node.isSuperCall) {
      HInstruction result;
      List<HInstruction> setterInputs = buildSuperAccessorInputs(element);
      if (identical(node.assignmentOperator.source.stringValue, '=')) {
        addDynamicSendArgumentsToList(node, setterInputs);
        result = setterInputs.last;
      } else {
        Element getter = elements[node.selector];
        List<HInstruction> getterInputs = buildSuperAccessorInputs(getter);
        Link<Node> arguments = node.arguments;
        if (node.isIndex) {
          // If node is of the from [:super.foo[0] += 2:], the send has
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
        if (Elements.isUnresolved(getter)) {
          generateSuperNoSuchMethodSend(
              node,
              elements.getGetterSelectorInComplexSendSet(node),
              getterInputs);
          getterInstruction = pop();
        } else {
          getterInstruction = new HInvokeSuper(getterInputs);
          add(getterInstruction);
        }
        handleComplexOperatorSend(node, getterInstruction, arguments);
        setterInputs.add(pop());

        if (node.isPostfix) {
          result = getterInstruction;
        } else {
          result = setterInputs.last;
        }
      }
      if (Elements.isUnresolved(element)) {
        generateSuperNoSuchMethodSend(
            node, elements.getSelector(node), setterInputs);
        pop();
      } else {
        add(new HInvokeSuper(setterInputs, isSetter: true));
      }
      stack.add(result);
    } else if (node.isIndex) {
      if (const SourceString("=") == op.source) {
        // TODO(kasperl): We temporarily disable inlining because the
        // code here cannot deal with it yet.
        visitDynamicSend(node, inline: false);
        HInvokeDynamicMethod method = pop();
        // Push the value.
        stack.add(method.inputs.last);
      } else {
        visit(node.receiver);
        HInstruction receiver = pop();
        Link<Node> arguments = node.arguments;
        HInstruction index;
        if (node.isIndex) {
          visit(arguments.head);
          arguments = arguments.tail;
          index = pop();
        }

        HInvokeDynamicMethod getterInstruction = buildInvokeDynamic(
            node,
            elements.getGetterSelectorInComplexSendSet(node),
            receiver,
            <HInstruction>[index]);
        add(getterInstruction);

        handleComplexOperatorSend(node, getterInstruction, arguments);
        HInstruction value = pop();

        HInvokeDynamicMethod assign = buildInvokeDynamic(
            node, elements.getSelector(node), receiver, [index, value]);
        add(assign);

        if (node.isPostfix) {
          stack.add(getterInstruction);
        } else {
          stack.add(value);
        }
      }
    } else if (const SourceString("=") == op.source) {
      Link<Node> link = node.arguments;
      assert(!link.isEmpty && link.tail.isEmpty);
      if (Elements.isInstanceSend(node, elements)) {
        HInstruction receiver = generateInstanceSendReceiver(node);
        visit(link.head);
        generateInstanceSetterWithCompiledReceiver(node, receiver, pop());
      } else {
        visit(link.head);
        generateNonInstanceSetter(node, element, pop());
      }
    } else if (identical(op.source.stringValue, "is")) {
      compiler.internalError("is-operator as SendSet", node: op);
    } else {
      assert(const SourceString("++") == op.source ||
             const SourceString("--") == op.source ||
             node.assignmentOperator.source.stringValue.endsWith("="));

      // [receiver] is only used if the node is an instance send.
      HInstruction receiver = null;
      if (Elements.isInstanceSend(node, elements)) {
        receiver = generateInstanceSendReceiver(node);
        generateInstanceGetterWithCompiledReceiver(
            node, elements.getGetterSelectorInComplexSendSet(node), receiver);
      } else {
        generateGetter(node, elements[node.selector]);
      }
      HInstruction getterInstruction = pop();
      handleComplexOperatorSend(node, getterInstruction, node.arguments);
      HInstruction value = pop();
      assert(value != null);
      if (Elements.isInstanceSend(node, elements)) {
        assert(receiver != null);
        generateInstanceSetterWithCompiledReceiver(node, receiver, value);
      } else {
        assert(receiver == null);
        generateNonInstanceSetter(node, element, value);
      }
      if (node.isPostfix) {
        pop();
        stack.add(getterInstruction);
      }
    }
  }

  void visitLiteralInt(LiteralInt node) {
    stack.add(graph.addConstantInt(node.value, constantSystem));
  }

  void visitLiteralDouble(LiteralDouble node) {
    stack.add(graph.addConstantDouble(node.value, constantSystem));
  }

  void visitLiteralBool(LiteralBool node) {
    stack.add(graph.addConstantBool(node.value, constantSystem));
  }

  void visitLiteralString(LiteralString node) {
    stack.add(graph.addConstantString(node.dartString, node, constantSystem));
  }

  void visitStringJuxtaposition(StringJuxtaposition node) {
    if (!node.isInterpolation) {
      // This is a simple string with no interpolations.
      stack.add(graph.addConstantString(node.dartString, node, constantSystem));
      return;
    }
    StringBuilderVisitor stringBuilder = new StringBuilderVisitor(this, node);
    stringBuilder.visit(node);
    stack.add(stringBuilder.result);
  }

  void visitLiteralNull(LiteralNull node) {
    stack.add(graph.addConstantNull(constantSystem));
  }

  visitNodeList(NodeList node) {
    for (Link<Node> link = node.nodes; !link.isEmpty; link = link.tail) {
      if (isAborted()) {
        compiler.reportWarning(link.head, 'dead code');
      } else {
        visit(link.head);
      }
    }
  }

  void visitParenthesizedExpression(ParenthesizedExpression node) {
    visit(node.expression);
  }

  visitOperator(Operator node) {
    // Operators are intercepted in their surrounding Send nodes.
    compiler.internalError('visitOperator should not be called', node: node);
  }

  visitCascade(Cascade node) {
    visit(node.expression);
    // Remove the result and reveal the duplicated receiver on the stack.
    pop();
  }

  visitCascadeReceiver(CascadeReceiver node) {
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

  visitReturn(Return node) {
    if (identical(node.getBeginToken().stringValue, 'native')) {
      native.handleSsaNative(this, node.expression);
      return;
    }
    assert(invariant(node, !node.isRedirectingFactoryBody));
    HInstruction value;
    if (node.expression == null) {
      value = graph.addConstantNull(constantSystem);
    } else {
      visit(node.expression);
      value = pop();
      value = potentiallyCheckType(value, returnType);
    }

    handleInTryStatement();

    if (!inliningStack.isEmpty) {
      localsHandler.updateLocal(returnElement, value);
    } else {
      closeAndGotoExit(attachPosition(new HReturn(value), node));
    }
  }

  visitThrow(Throw node) {
    if (node.expression == null) {
      HInstruction exception = rethrowableException;
      if (exception == null) {
        exception = graph.addConstantNull(constantSystem);
        compiler.internalError(
            'rethrowableException should not be null', node: node);
      }
      handleInTryStatement();
      closeAndGotoExit(new HThrow(exception, isRethrow: true));
    } else {
      visit(node.expression);
      handleInTryStatement();
      if (inliningStack.isEmpty) {
        closeAndGotoExit(new HThrow(pop()));
      } else if (isReachable) {
        // We don't close the block when we are inlining, because we could be
        // inside an expression, and it is rather complicated to close the
        // block at an arbitrary place in an expression.
        add(new HThrowExpression(pop()));
        isReachable = false;
      }
    }
  }

  visitTypeAnnotation(TypeAnnotation node) {
    compiler.internalError('visiting type annotation in SSA builder',
                           node: node);
  }

  visitVariableDefinitions(VariableDefinitions node) {
    assert(isReachable);
    for (Link<Node> link = node.definitions.nodes;
         !link.isEmpty;
         link = link.tail) {
      Node definition = link.head;
      if (definition is Identifier) {
        HInstruction initialValue = graph.addConstantNull(constantSystem);
        localsHandler.updateLocal(elements[definition], initialValue);
      } else {
        assert(definition is SendSet);
        visitSendSet(definition);
        pop();  // Discard value.
      }
    }
  }

  visitLiteralList(LiteralList node) {
    if (node.isConst()) {
      ConstantHandler handler = compiler.constantHandler;
      Constant constant = handler.compileNodeWithDefinitions(node, elements);
      stack.add(graph.addConstant(constant));
      return;
    }

    List<HInstruction> inputs = <HInstruction>[];
    for (Link<Node> link = node.elements.nodes;
         !link.isEmpty;
         link = link.tail) {
      visit(link.head);
      inputs.add(pop());
    }
    push(new HLiteralList(inputs));
  }

  visitConditional(Conditional node) {
    SsaBranchBuilder brancher = new SsaBranchBuilder(this, node);
    brancher.handleConditional(() => visit(node.condition),
                               () => visit(node.thenExpression),
                               () => visit(node.elseExpression));
  }

  visitStringInterpolation(StringInterpolation node) {
    StringBuilderVisitor stringBuilder = new StringBuilderVisitor(this, node);
    stringBuilder.visit(node);
    stack.add(stringBuilder.result);
  }

  visitStringInterpolationPart(StringInterpolationPart node) {
    // The parts are iterated in visitStringInterpolation.
    compiler.internalError('visitStringInterpolation should not be called',
                           node: node);
  }

  visitEmptyStatement(EmptyStatement node) {
    // Do nothing, empty statement.
  }

  visitModifiers(Modifiers node) {
    compiler.unimplemented('SsaBuilder.visitModifiers', node: node);
  }

  visitBreakStatement(BreakStatement node) {
    assert(!isAborted());
    handleInTryStatement();
    TargetElement target = elements[node];
    assert(target != null);
    JumpHandler handler = jumpTargets[target];
    assert(handler != null);
    if (node.target == null) {
      handler.generateBreak();
    } else {
      LabelElement label = elements[node.target];
      handler.generateBreak(label);
    }
  }

  visitContinueStatement(ContinueStatement node) {
    handleInTryStatement();
    TargetElement target = elements[node];
    assert(target != null);
    JumpHandler handler = jumpTargets[target];
    assert(handler != null);
    if (node.target == null) {
      handler.generateContinue();
    } else {
      LabelElement label = elements[node.target];
      assert(label != null);
      handler.generateContinue(label);
    }
  }

  /**
   * Creates a [JumpHandler] for a statement. The node must be a jump
   * target. If there are no breaks or continues targeting the statement,
   * a special "null handler" is returned.
   */
  JumpHandler createJumpHandler(Statement node) {
    TargetElement element = elements[node];
    if (element == null || !identical(element.statement, node)) {
      // No breaks or continues to this node.
      return new NullJumpHandler(compiler);
    }
    return new JumpHandler(this, element);
  }

  visitForIn(ForIn node) {
    // Generate a structure equivalent to:
    //   Iterator<E> $iter = <iterable>.iterator;
    //   while ($iter.moveNext()) {
    //     E <declaredIdentifier> = $iter.current;
    //     <body>
    //   }

    // The iterator is shared between initializer, condition and body.
    HInstruction iterator;
    void buildInitializer() {
      Selector selector = compiler.iteratorSelector;
      Set<ClassElement> interceptedClasses =
          backend.getInterceptedClassesOn(selector.name);
      visit(node.expression);
      HInstruction receiver = pop();
      bool hasGetter = compiler.world.hasAnyUserDefinedGetter(selector);
      if (interceptedClasses == null) {
        iterator =
            new HInvokeDynamicGetter(selector, null, receiver, !hasGetter);
      } else {
        HInterceptor interceptor =
            invokeInterceptor(interceptedClasses, receiver, null);
        iterator =
            new HInvokeDynamicGetter(selector, null, interceptor, !hasGetter);
        // Add the receiver as an argument to the getter call on the
        // interceptor.
        iterator.inputs.add(receiver);
      }
      add(iterator);
    }
    HInstruction buildCondition() {
      Selector selector = compiler.moveNextSelector;
      push(new HInvokeDynamicMethod(selector, <HInstruction>[iterator]));
      return popBoolified();
    }
    void buildBody() {
      Selector call = compiler.currentSelector;
      bool hasGetter = compiler.world.hasAnyUserDefinedGetter(call);
      push(new HInvokeDynamicGetter(call, null, iterator, !hasGetter));

      Element variable = elements[node.declaredIdentifier];
      Selector selector = elements.getSelector(node.declaredIdentifier);

      HInstruction oldVariable = pop();
      if (Elements.isUnresolved(variable)) {
        if (Elements.isInStaticContext(currentElement)) {
          generateThrowNoSuchMethod(
              node.declaredIdentifier,
              'set ${selector.name.slowToString()}',
              argumentValues: <HInstruction>[oldVariable]);
        } else {
          // The setter may have been defined in a subclass.
          generateInstanceSetterWithCompiledReceiver(
              null,
              localsHandler.readThis(),
              oldVariable,
              selector: selector,
              location: node.declaredIdentifier);
        }
        pop();
      } else {
        localsHandler.updateLocal(variable, oldVariable);
      }

      visit(node.body);
    }
    handleLoop(node, buildInitializer, buildCondition, () {}, buildBody);
  }

  visitLabel(Label node) {
    compiler.internalError('SsaBuilder.visitLabel', node: node);
  }

  visitLabeledStatement(LabeledStatement node) {
    Statement body = node.statement;
    if (body is Loop || body is SwitchStatement) {
      // Loops and switches handle their own labels.
      visit(body);
      return;
    }
    // Non-loop statements can only be break targets, not continue targets.
    TargetElement targetElement = elements[body];
    if (targetElement == null || !identical(targetElement.statement, body)) {
      // Labeled statements with no element on the body have no breaks.
      // A different target statement only happens if the body is itself
      // a break or continue for a different target. In that case, this
      // label is also always unused.
      visit(body);
      return;
    }
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

  visitLiteralMap(LiteralMap node) {
    if (node.isConst()) {
      ConstantHandler handler = compiler.constantHandler;
      Constant constant = handler.compileNodeWithDefinitions(node, elements);
      stack.add(graph.addConstant(constant));
      return;
    }
    List<HInstruction> inputs = <HInstruction>[];
    for (Link<Node> link = node.entries.nodes;
         !link.isEmpty;
         link = link.tail) {
      visit(link.head);
      inputs.add(pop());
      inputs.add(pop());
    }
    HLiteralList keyValuePairs = new HLiteralList(inputs);
    add(keyValuePairs);
    HType mapType = new HType.nonNullSubtype(
        backend.mapLiteralClass.computeType(compiler), compiler);
    pushInvokeHelper1(backend.getMapMaker(), keyValuePairs, mapType);
  }

  visitLiteralMapEntry(LiteralMapEntry node) {
    visit(node.value);
    visit(node.key);
  }

  visitNamedArgument(NamedArgument node) {
    visit(node.expression);
  }

  visitSwitchStatement(SwitchStatement node) {
    if (tryBuildConstantSwitch(node)) return;

    LocalsHandler savedLocals = new LocalsHandler.from(localsHandler);
    HBasicBlock startBlock = openNewBlock();
    visit(node.expression);
    HInstruction expression = pop();
    if (node.cases.isEmpty) {
      return;
    }

    Link<Node> cases = node.cases.nodes;
    JumpHandler jumpHandler = createJumpHandler(node);

    buildSwitchCases(cases, expression);

    HBasicBlock lastBlock = lastOpenedBlock;

    // Create merge block for break targets.
    HBasicBlock joinBlock = new HBasicBlock();
    List<LocalsHandler> caseHandlers = <LocalsHandler>[];
    jumpHandler.forEachBreak((HBreak instruction, LocalsHandler locals) {
      instruction.block.addSuccessor(joinBlock);
      caseHandlers.add(locals);
    });
    if (!isAborted()) {
      // The current flow is only aborted if the switch has a default that
      // aborts (all previous cases must abort, and if there is no default,
      // it's possible to miss all the cases).
      caseHandlers.add(localsHandler);
      goto(current, joinBlock);
    }
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
    startBlock.setBlockFlow(
        new HLabeledBlockInformation.implicit(
            new HSubGraphBlockInformation(new SubGraph(startBlock, lastBlock)),
            elements[node]),
        joinBlock);
    jumpHandler.close();
  }

  bool tryBuildConstantSwitch(SwitchStatement node) {
    Map<CaseMatch, Constant> constants = new Map<CaseMatch, Constant>();
    // First check whether all case expressions are compile-time constants,
    // and all have the same type that doesn't override operator==.
    // TODO(lrn): Move the constant resolution to the resolver, so
    // we can report an error before reaching the backend.
    DartType firstConstantType = null;
    bool failure = false;
    for (SwitchCase switchCase in node.cases) {
      for (Node labelOrCase in switchCase.labelsAndCases) {
        if (labelOrCase is CaseMatch) {
          CaseMatch match = labelOrCase;
          Constant constant =
            compiler.constantHandler.tryCompileNodeWithDefinitions(
                match.expression, elements);
          if (constant == null) {
            compiler.reportWarning(match.expression,
                MessageKind.NOT_A_COMPILE_TIME_CONSTANT.error());
            failure = true;
            continue;
          }
          if (firstConstantType == null) {
            firstConstantType = constant.computeType(compiler);
            if (nonPrimitiveTypeOverridesEquals(constant)) {
              compiler.reportWarning(match.expression,
                  MessageKind.SWITCH_CASE_VALUE_OVERRIDES_EQUALS.error());
              failure = true;
            }
          } else {
            DartType constantType =
                constant.computeType(compiler);
            if (constantType != firstConstantType) {
              compiler.reportWarning(match.expression,
                  MessageKind.SWITCH_CASE_TYPES_NOT_EQUAL.error());
              failure = true;
            }
          }
          constants[labelOrCase] = constant;
        } else {
          compiler.reportWarning(node, "Unsupported: Labels on cases");
          failure = true;
        }
      }
    }
    if (failure) {
      return false;
    }

    // TODO(ngeoffray): Handle switch-instruction in bailout code.
    work.allowSpeculativeOptimization = false;
    // Then build a switch structure.
    HBasicBlock expressionStart = openNewBlock();
    visit(node.expression);
    HInstruction expression = pop();
    if (node.cases.isEmpty) {
      return true;
    }
    HBasicBlock expressionEnd = current;

    HSwitch switchInstruction = new HSwitch(<HInstruction>[expression]);
    HBasicBlock expressionBlock = close(switchInstruction);
    JumpHandler jumpHandler = createJumpHandler(node);
    LocalsHandler savedLocals = localsHandler;

    List<List<Constant>> matchExpressions = <List<Constant>>[];
    List<HStatementInformation> statements = <HStatementInformation>[];
    bool hasDefault = false;
    Element getFallThroughErrorElement = backend.getFallThroughError();
    HasNextIterator<Node> caseIterator =
        new HasNextIterator<Node>(node.cases.iterator);
    while (caseIterator.hasNext) {
      SwitchCase switchCase = caseIterator.next();
      List<Constant> caseConstants = <Constant>[];
      HBasicBlock block = graph.addNewBlock();
      for (Node labelOrCase in switchCase.labelsAndCases) {
        if (labelOrCase is CaseMatch) {
          Constant constant = constants[labelOrCase];
          caseConstants.add(constant);
          HConstant hConstant = graph.addConstant(constant);
          switchInstruction.inputs.add(hConstant);
          hConstant.usedBy.add(switchInstruction);
          expressionBlock.addSuccessor(block);
        }
      }
      matchExpressions.add(caseConstants);

      if (switchCase.isDefaultCase) {
        // An HSwitch has n inputs and n+1 successors, the last being the
        // default case.
        expressionBlock.addSuccessor(block);
        hasDefault = true;
      }
      open(block);
      localsHandler = new LocalsHandler.from(savedLocals);
      visit(switchCase.statements);
      if (!isAborted() && caseIterator.hasNext) {
        pushInvokeHelper0(getFallThroughErrorElement, HType.UNKNOWN);
        HInstruction error = pop();
        closeAndGotoExit(new HThrow(error));
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
    if (!isAborted()) {
      current.close(new HGoto());
      lastOpenedBlock.addSuccessor(joinBlock);
      caseHandlers.add(localsHandler);
    }
    if (!hasDefault) {
      // The current flow is only aborted if the switch has a default that
      // aborts (all previous cases must abort, and if there is no default,
      // it's possible to miss all the cases).
      expressionEnd.addSuccessor(joinBlock);
      caseHandlers.add(savedLocals);
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
                                    matchExpressions,
                                    statements,
                                    hasDefault,
                                    jumpHandler.target,
                                    jumpHandler.labels()),
        joinBlock);

    jumpHandler.close();
    return true;
  }

  bool nonPrimitiveTypeOverridesEquals(Constant constant) {
    // Function values override equals. Even static ones, since
    // they inherit from [Function].
    if (constant.isFunction()) return true;

    // [Map] and [List] do not override equals.
    // If constant is primitive, just return false. We know
    // about the equals methods of num/String classes.
    if (!constant.isConstructedObject()) return false;

    ConstructedConstant constructedConstant = constant;
    DartType type = constructedConstant.type;
    assert(type != null);
    Element element = type.element;
    // If the type is not a class, we'll just assume it overrides
    // operator==. Typedefs do, since [Function] does.
    if (!element.isClass()) return true;
    ClassElement classElement = element;
    return typeOverridesObjectEquals(classElement);
  }

  bool typeOverridesObjectEquals(ClassElement classElement) {
    Element operatorEq =
        lookupOperator(classElement, const SourceString('=='));
    if (operatorEq == null) return false;
    // If the operator== declaration is in Object, it's not overridden.
    return (operatorEq.getEnclosingClass() != compiler.objectClass);
  }

  Element lookupOperator(ClassElement classElement, SourceString operatorName) {
    SourceString dartMethodName =
        Elements.constructOperatorName(operatorName, false);
    return classElement.lookupMember(dartMethodName);
  }


  // Recursively build an if/else structure to match the cases.
  void buildSwitchCases(Link<Node> cases, HInstruction expression,
                        [int encounteredCaseTypes = 0]) {
    final int NO_TYPE = 0;
    final int INT_TYPE = 1;
    final int STRING_TYPE = 2;
    final int CONFLICT_TYPE = 3;
    int combine(int type1, int type2) => type1 | type2;

    SwitchCase node = cases.head;
    // Called for the statements on all but the last case block.
    // Ensures that a user expecting a fallthrough gets an error.
    void visitStatementsAndAbort() {
      visit(node.statements);
      if (!isAborted()) {
        compiler.reportWarning(node, 'Missing break at end of switch case');
        Element element =
            compiler.findHelper(const SourceString("getFallThroughError"));
        pushInvokeHelper0(element, HType.UNKNOWN);
        HInstruction error = pop();
        closeAndGotoExit(new HThrow(error));
      }
    }

    Link<Node> skipLabels(Link<Node> labelsAndCases) {
      while (!labelsAndCases.isEmpty && labelsAndCases.head is Label) {
        labelsAndCases = labelsAndCases.tail;
      }
      return labelsAndCases;
    }

    Link<Node> labelsAndCases = skipLabels(node.labelsAndCases.nodes);
    if (labelsAndCases.isEmpty) {
      // Default case with no expressions.
      if (!node.isDefaultCase) {
        compiler.internalError("Case with no expression and not default",
                               node: node);
      }
      visit(node.statements);
      // This must be the final case (otherwise "default" would be invalid),
      // so we don't need to check for fallthrough.
      return;
    }

    // Recursively build the test conditions. Leaves the result on the
    // expression stack.
    void buildTests(Link<Node> remainingCases) {
      // Build comparison for one case expression.
      void left() {
        CaseMatch match = remainingCases.head;
        // TODO(lrn): Move the constant resolution to the resolver, so
        // we can report an error before reaching the backend.
        Constant constant =
            compiler.constantHandler.tryCompileNodeWithDefinitions(
                match.expression, elements);
        if (constant != null) {
          stack.add(graph.addConstant(constant));
        } else {
          visit(match.expression);
        }
        push(new HIdentity(pop(), expression));
      }

      // If this is the last expression, just return it.
      Link<Node> tail = skipLabels(remainingCases.tail);
      if (tail.isEmpty) {
        left();
        return;
      }

      void right() {
        buildTests(tail);
      }
      SsaBranchBuilder branchBuilder =
          new SsaBranchBuilder(this, remainingCases.head);
      branchBuilder.handleLogicalAndOr(left, right, isAnd: false);
    }

    if (node.isDefaultCase) {
      // Default case must be last.
      assert(cases.tail.isEmpty);
      // Perform the tests until one of them match, but then always execute the
      // statements.
      // TODO(lrn): Stop performing tests when all expressions are compile-time
      // constant strings or integers.
      handleIf(node, () { buildTests(labelsAndCases); }, (){}, null);
      visit(node.statements);
    } else {
      if (cases.tail.isEmpty) {
        handleIf(node,
                 () { buildTests(labelsAndCases); },
                 () { visit(node.statements); },
                 null);
      } else {
        handleIf(node,
                 () { buildTests(labelsAndCases); },
                 () { visitStatementsAndAbort(); },
                 () { buildSwitchCases(cases.tail, expression,
                                       encounteredCaseTypes); });
      }
    }
  }

  visitSwitchCase(SwitchCase node) {
    compiler.internalError('SsaBuilder.visitSwitchCase');
  }

  visitCaseMatch(CaseMatch node) {
    compiler.internalError('SsaBuilder.visitCaseMatch');
  }

  visitTryStatement(TryStatement node) {
    work.allowSpeculativeOptimization = false;
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
    if (!isAborted()) endTryBlock = close(new HGoto());
    SubGraph bodyGraph = new SubGraph(startTryBlock, lastOpenedBlock);
    SubGraph catchGraph = null;
    HLocalValue exception = null;

    if (!node.catchBlocks.isEmpty) {
      localsHandler = new LocalsHandler.from(savedLocals);
      startCatchBlock = graph.addNewBlock();
      open(startCatchBlock);
      // TODO(kasperl): Bad smell. We shouldn't be constructing elements here.
      // Note that the name of this element is irrelevant.
      Element element = new ElementX(const SourceString('exception'),
                                     ElementKind.PARAMETER,
                                     currentElement);
      exception = new HLocalValue(element);
      add(exception);
      HInstruction oldRethrowableException = rethrowableException;
      rethrowableException = exception;

      pushInvokeHelper1(
          backend.getExceptionUnwrapper(), exception, HType.UNKNOWN);
      HInvokeStatic unwrappedException = pop();
      tryInstruction.exception = exception;
      Link<Node> link = node.catchBlocks.nodes;

      void pushCondition(CatchBlock catchBlock) {
        if (catchBlock.onKeyword != null) {
          DartType type = elements.getType(catchBlock.type);
          if (type == null) {
            compiler.internalError('On with no type', node: catchBlock.type);
          }
          if (type.isMalformed) {
            // TODO(johnniwinther): Handle malformed types in [HIs] instead.
            HInstruction condition =
                graph.addConstantBool(true, constantSystem);
            stack.add(condition);
          } else {
            // TODO(karlkose): support type arguments here.
            HInstruction condition = new HIs(type,
                                             <HInstruction>[unwrappedException],
                                             HIs.RAW_CHECK);
            push(condition);
          }
        } else {
          VariableDefinitions declaration = catchBlock.formals.nodes.head;
          HInstruction condition = null;
          if (declaration.type == null) {
            condition = graph.addConstantBool(true, constantSystem);
            stack.add(condition);
          } else {
            // TODO(aprelev@gmail.com): Once old catch syntax is removed
            // "if" condition above and this "else" branch should be deleted as
            // type of declared variable won't matter for the catch
            // condition.
            DartType type = elements.getType(declaration.type);
            if (type == null) {
              compiler.cancel('Catch with unresolved type', node: catchBlock);
            }
            // TODO(karlkose): support type arguments here.
            condition = new HIs(type, <HInstruction>[unwrappedException],
                                HIs.RAW_CHECK, nullOk: true);
            push(condition);
          }
        }
      }

      void visitThen() {
        CatchBlock catchBlock = link.head;
        link = link.tail;

        if (compiler.enableTypeAssertions) {
          // In checked mode: throw a type error if the on-catch type is
          // malformed.
          if (catchBlock.onKeyword != null) {
            DartType type = elements.getType(catchBlock.type);
            if (type != null && type.isMalformed) {
              String reasons = Types.fetchReasonsFromMalformedType(type);
              generateMalformedSubtypeError(node,
                  unwrappedException, type, reasons);
              pop();
              return;
            }
          }
        }
        if (catchBlock.exception != null) {
          localsHandler.updateLocal(elements[catchBlock.exception],
                                    unwrappedException);
        }
        Node trace = catchBlock.trace;
        if (trace != null) {
          pushInvokeHelper1(
              backend.getTraceFromException(), exception, HType.UNKNOWN);
          HInstruction traceInstruction = pop();
          localsHandler.updateLocal(elements[trace], traceInstruction);
        }
        visit(catchBlock);
      }

      void visitElse() {
        if (link.isEmpty) {
          closeAndGotoExit(new HThrow(exception, isRethrow: true));
        } else {
          CatchBlock newBlock = link.head;
          handleIf(node,
                   () { pushCondition(newBlock); },
                   visitThen, visitElse);
        }
      }

      CatchBlock firstBlock = link.head;
      handleIf(node, () { pushCondition(firstBlock); }, visitThen, visitElse);
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

  visitScriptTag(ScriptTag node) {
    compiler.unimplemented('SsaBuilder.visitScriptTag', node: node);
  }

  visitCatchBlock(CatchBlock node) {
    visit(node.block);
  }

  visitTypedef(Typedef node) {
    compiler.unimplemented('SsaBuilder.visitTypedef', node: node);
  }

  visitTypeVariable(TypeVariable node) {
    compiler.internalError('SsaBuilder.visitTypeVariable');
  }
}

/**
 * Visitor that handles generation of string literals (LiteralString,
 * StringInterpolation), and otherwise delegates to the given visitor for
 * non-literal subexpressions.
 * TODO(lrn): Consider whether to handle compile time constant int/boolean
 * expressions as well.
 */
class StringBuilderVisitor extends Visitor {
  final SsaBuilder builder;
  final Node diagnosticNode;

  /**
   * The string value generated so far.
   */
  HInstruction result = null;

  StringBuilderVisitor(this.builder, this.diagnosticNode);

  void visit(Node node) {
    node.accept(this);
  }

  visitNode(Node node) {
    builder.compiler.internalError('unexpected node', node: node);
  }

  void visitExpression(Node node) {
    node.accept(builder);
    HInstruction expression = builder.pop();
    if (!expression.isConstantString()) {
      expression = new HStringify(expression, node);
      builder.add(expression);
    }
    result = (result == null) ? expression : concat(result, expression);
  }

  void visitStringInterpolation(StringInterpolation node) {
    node.visitChildren(this);
  }

  void visitStringInterpolationPart(StringInterpolationPart node) {
    visit(node.expression);
    visit(node.string);
  }

  void visitStringJuxtaposition(StringJuxtaposition node) {
    node.visitChildren(this);
  }

  void visitNodeList(NodeList node) {
     node.visitChildren(this);
  }

  HInstruction concat(HInstruction left, HInstruction right) {
    HInstruction instruction = new HStringConcat(left, right, diagnosticNode);
    builder.add(instruction);
    return instruction;
  }
}

/**
 * This class visits the method that is a candidate for inlining and
 * finds whether it is too difficult to inline.
 */
class InlineWeeder extends Visitor {
  final TreeElements elements;

  bool seenReturn = false;
  bool tooDifficult = false;
  int nodeCount = 0;

  InlineWeeder(this.elements);

  static bool canBeInlined(FunctionExpression functionExpression,
                           TreeElements elements) {
    InlineWeeder weeder = new InlineWeeder(elements);
    weeder.visit(functionExpression.body);
    if (weeder.tooDifficult) return false;
    return true;
  }

  bool registerNode() {
    if (nodeCount++ > SsaBuilder.MAX_INLINING_NODES) {
      tooDifficult = true;
      return false;
    } else {
      return true;
    }
  }

  void visit(Node node) {
    node.accept(this);
  }

  void visitNode(Node node) {
    if (!registerNode()) return;
    if (seenReturn) {
      tooDifficult = true;
    } else {
      node.visitChildren(this);
    }
  }

  void visitFunctionExpression(Node node) {
    if (!registerNode()) return;
    tooDifficult = true;
  }

  void visitFunctionDeclaration(Node node) {
    if (!registerNode()) return;
    tooDifficult = true;
  }

  void visitSend(Send node) {
    if (!registerNode()) return;
    if (node.isParameterCheck) {
      tooDifficult = true;
      return;
    }
    node.visitChildren(this);
  }

  visitLoop(Node node) {
    if (!registerNode()) return;
    node.visitChildren(this);
    if (seenReturn) tooDifficult = true;
  }

  void visitReturn(Return node) {
    if (!registerNode()) return;
    if (seenReturn
        || identical(node.getBeginToken().stringValue, 'native')
        || node.isRedirectingFactoryBody) {
      tooDifficult = true;
      return;
    }
    node.visitChildren(this);
    seenReturn = true;
  }

  void visitTryStatement(Node node) {
    if (!registerNode()) return;
    tooDifficult = true;
  }

  void visitThrow(Throw node) {
    if (!registerNode()) return;
    // We can't inline rethrows and we don't want to handle throw after a return
    // even if it is in an "if".
    if (seenReturn || node.expression == null) tooDifficult = true;
  }
}

class InliningState {
  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [function] must be an implementation element.
   */
  final PartialFunctionElement function;
  final Element oldReturnElement;
  final DartType oldReturnType;
  final TreeElements oldElements;
  final List<HInstruction> oldStack;
  final LocalsHandler oldLocalsHandler;

  InliningState(this.function,
                this.oldReturnElement,
                this.oldReturnType,
                this.oldElements,
                this.oldStack,
                this.oldLocalsHandler) {
    assert(function.isImplementation);
  }
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
  final Node diagnosticNode;

  SsaBranchBuilder(this.builder, [this.diagnosticNode]);

  Compiler get compiler => builder.compiler;

  void checkNotAborted() {
    if (builder.isAborted()) {
      compiler.unimplemented("aborted control flow", node: diagnosticNode);
    }
  }

  void buildCondition(void visitCondition(),
                      SsaBranch conditionBranch,
                      SsaBranch thenBranch,
                      SsaBranch elseBranch) {
    startBranch(conditionBranch);
    visitCondition();
    checkNotAborted();
    assert(identical(builder.current, builder.lastOpenedBlock));
    HInstruction conditionValue = builder.popBoolified();
    HIf branch = new HIf(conditionValue);
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

  handleIf(void visitCondition(), void visitThen(), void visitElse()) {
    if (visitElse == null) {
      // Make sure to have an else part to avoid a critical edge. A
      // critical edge is an edge that connects a block with multiple
      // successors to a block with multiple predecessors. We avoid
      // such edges because they prevent inserting copies during code
      // generation of phi instructions.
      visitElse = () {};
    }

    _handleDiamondBranch(visitCondition, visitThen, visitElse, false);
  }

  handleConditional(void visitCondition(), void visitThen(), void visitElse()) {
    assert(visitElse != null);
    _handleDiamondBranch(visitCondition, visitThen, visitElse, true);
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
        builder.push(new HNot(builder.pop()));
      }
    }

    void visitThen() {
      right();
      boolifiedRight = builder.popBoolified();
    }

    handleIf(visitCondition, visitThen, null);
    HConstant notIsAnd =
        builder.graph.addConstantBool(!isAnd, builder.constantSystem);
    HPhi result = new HPhi.manyInputs(null,
                                      <HInstruction>[boolifiedRight, notIsAnd]);
    builder.current.addPhi(result);
    builder.stack.add(result);
  }

  void handleLogicalAndOrWithLeftNode(Node left,
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

    Send send = left.asSend();
    if (send != null &&
        (isAnd ? send.isLogicalAnd : send.isLogicalOr)) {
      Node newLeft = send.receiver;
      Link<Node> link = send.argumentsNode.nodes;
      assert(link.tail.isEmpty);
      Node middle = link.head;
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
                            bool isExpression) {
    SsaBranch conditionBranch = new SsaBranch(this);
    SsaBranch thenBranch = new SsaBranch(this);
    SsaBranch elseBranch = new SsaBranch(this);
    SsaBranch joinBranch = new SsaBranch(this);

    conditionBranch.startLocals = builder.localsHandler;
    builder.goto(builder.current, conditionBranch.block);

    buildCondition(visitCondition, conditionBranch, thenBranch, elseBranch);
    HInstruction thenValue =
        buildBranch(thenBranch, visitThen, joinBranch, isExpression);
    HInstruction elseValue =
        buildBranch(elseBranch, visitElse, joinBranch, isExpression);

    if (isExpression) {
      assert(thenValue != null && elseValue != null);
      HPhi phi =
          new HPhi.manyInputs(null, <HInstruction>[thenValue, elseValue]);
      joinBranch.block.addPhi(phi);
      builder.stack.add(phi);
    }

    HBasicBlock thenBlock = thenBranch.block;
    HBasicBlock elseBlock = elseBranch.block;
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
