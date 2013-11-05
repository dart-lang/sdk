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
  InterceptedElement(this.type, String name, Element enclosing)
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
      return compiler.withCurrentElement(element, () {
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
          assert(!element.isInstanceMember());
          graph = builder.buildLazyInitializer(element);
        } else {
          compiler.internalErrorOnElement(element,
                                          'unexpected element kind $kind');
        }
        assert(graph.isValid());
        if (!identical(kind, ElementKind.FIELD)) {
          FunctionElement function = element;
          FunctionSignature signature = function.computeSignature(compiler);
          signature.forEachOptionalParameter((Element parameter) {
            // This ensures the default value will be computed.
            Constant constant =
                compiler.constantHandler.getConstantForVariable(parameter);
            backend.registerCompileTimeConstant(constant, work.resolutionTree);
            compiler.constantHandler.addCompileTimeConstantForEmission(
                constant);
          });
        }
        if (compiler.tracer.enabled) {
          String name;
          if (element.isMember()) {
            String className = element.getEnclosingClass().name;
            String memberName = element.name;
            name = "$className.$memberName";
            if (element.isGenerativeConstructorBody()) {
              name = "$name (body)";
            }
          } else {
            name = "${element.name}";
          }
          compiler.tracer.traceCompilation(
              name, work.compilationContext, compiler);
          compiler.tracer.traceGraph('builder', graph);
        }
        return graph;
      });
    });
  }

  HGraph compileConstructor(SsaBuilder builder, CodegenWorkItem work) {
    return builder.buildFactory(work.element);
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
  Map<Element, HInstruction> directLocals;
  Map<Element, Element> redirectionMapping;
  SsaBuilder builder;
  ClosureClassMap closureData;

  LocalsHandler(this.builder)
      : directLocals = new Map<Element, HInstruction>(),
        redirectionMapping = new Map<Element, Element>();

  get typesTask => builder.compiler.typesTask;

  /**
   * Creates a new [LocalsHandler] based on [other]. We only need to
   * copy the [directLocals], since the other fields can be shared
   * throughout the AST visit.
   */
  LocalsHandler.from(LocalsHandler other)
      : directLocals = new Map<Element, HInstruction>.from(other.directLocals),
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
    JavaScriptBackend backend = builder.backend;
    HInstruction box = new HForeign(new js.ObjectInitializer([]),
                                    backend.nonNullType,
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
      JavaScriptBackend backend = builder.backend;
      box = builder.addParameter(scopeData.boxElement, backend.nonNullType);
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
    assert(invariant(element, element.isImplementation));
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
    closureData.freeVariableMapping.forEach((Element from, Element to) {
      redirectElement(from, to);
    });
    JavaScriptBackend backend = compiler.backend;
    if (closureData.isClosure()) {
      // Inside closure redirect references to itself to [:this:].
      HThis thisInstruction = new HThis(closureData.thisElement,
                                        backend.nonNullType);
      builder.graph.thisInstruction = thisInstruction;
      builder.graph.entry.addAtEntry(thisInstruction);
      updateLocal(closureData.closureElement, thisInstruction);
    } else if (element.isInstanceMember()) {
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

    // When the class extends a native class, the instance is pre-constructed
    // and passed to the generative constructor factory function as a parameter.
    // Instead of allocating and initializing the object, the constructor
    // 'upgrades' the native subclass object by initializing the Dart fields.
    bool isNativeUpgradeFactory = element.isGenerativeConstructor()
        && Elements.isNativeOrExtendsNative(cls);
    if (backend.isInterceptedMethod(element)) {
      bool isInterceptorClass = backend.isInterceptorClass(cls.declaration);
      String name = isInterceptorClass ? 'receiver' : '_';
      Element parameter = new InterceptedElement(
          cls.computeType(compiler), name, element);
      HParameterValue value =
          new HParameterValue(parameter, builder.getTypeOfThis());
      builder.graph.explicitReceiverParameter = value;
      builder.graph.entry.addAfter(
          directLocals[closureData.thisElement], value);
      if (isInterceptorClass) {
        // Only use the extra parameter in intercepted classes.
        directLocals[closureData.thisElement] = value;
      }
    } else if (isNativeUpgradeFactory) {
      Element parameter = new InterceptedElement(
          cls.computeType(compiler), 'receiver', element);
      // Unlike `this`, receiver is nullable since direct calls to generative
      // constructor call the constructor with `null`.
      HParameterValue value =
          new HParameterValue(parameter, new TypeMask.exact(cls));
      builder.graph.explicitReceiverParameter = value;
      builder.graph.entry.addAtEntry(value);
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
        if (element.isTypeVariable()) {
          builder.compiler.internalError(
              "Runtime type information not available for $element",
              element: builder.compiler.currentElement);
        } else {
          builder.compiler.internalError(
              "Cannot find value $element",
              element: element);
        }
      }
      return directLocals[element];
    } else if (isStoredInClosureField(element)) {
      Element redirect = redirectionMapping[element];
      HInstruction receiver = readLocal(closureData.closureElement);
      TypeMask type = (element.kind == ElementKind.VARIABLE_LIST)
          ? builder.backend.nonNullType
          : builder.getTypeOfCapturedVariable(redirect);
      assert(element.kind != ElementKind.VARIABLE_LIST
             || element is BoxElement);
      HInstruction fieldGet = new HFieldGet(redirect, receiver, type);
      builder.add(fieldGet);
      return fieldGet;
    } else if (isBoxed(element)) {
      Element redirect = redirectionMapping[element];
      // In the function that declares the captured variable the box is
      // accessed as direct local. Inside the nested closure the box is
      // accessed through a closure-field.
      // Calling [readLocal] makes sure we generate the correct code to get
      // the box.
      assert(redirect.enclosingElement is BoxElement);
      HInstruction box = readLocal(redirect.enclosingElement);
      HInstruction lookup = new HFieldGet(
          redirect, box, builder.getTypeOfCapturedVariable(redirect));
      builder.add(lookup);
      return lookup;
    } else {
      assert(isUsedInTry(element));
      HLocalValue local = getLocal(element);
      HInstruction variable = new HLocalGet(
          element, local, builder.backend.dynamicType);
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
      JavaScriptBackend backend = builder.backend;
      HLocalValue local = new HLocalValue(element, backend.nonNullType);
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
      assert(redirect.enclosingElement is BoxElement);
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
        new Map<Element, HInstruction>.from(directLocals);

    JavaScriptBackend backend = builder.backend;
    // Create phis for all elements in the definitions environment.
    savedDirectLocals.forEach((Element element, HInstruction instruction) {
      if (isAccessedDirectly(element)) {
        // We know 'this' cannot be modified.
        if (!identical(element, closureData.thisElement)) {
          HPhi phi = new HPhi.singleInput(
              element, instruction, backend.dynamicType);
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

  void enterLoopUpdates(Node node) {
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
        new Map<Element, HInstruction>();
    JavaScriptBackend backend = builder.backend;
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
          HInstruction phi = new HPhi.manyInputs(
              element, <HInstruction>[mine, instruction], backend.dynamicType);
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
        new Map<Element,HInstruction>();
    HInstruction thisValue = null;
    JavaScriptBackend backend = builder.backend;
    directLocals.forEach((Element element, HInstruction instruction) {
      if (element != closureData.thisElement) {
        HPhi phi = new HPhi.noInputs(element, backend.dynamicType);
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
    directLocals = new Map<Element, HInstruction>();
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
      // Switch case continue statements must be handled by the
      // [SwitchCaseJumpHandler].
      assert(label.target.statement is! SwitchCase);
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

/// Special [JumpHandler] implementation used to handle continue statements
/// targeting switch cases.
class SwitchCaseJumpHandler extends TargetJumpHandler {
  /// Map from switch case targets to indices used to encode the flow of the
  /// switch case loop.
  final Map<TargetElement, int> targetIndexMap = new Map<TargetElement, int>();

  SwitchCaseJumpHandler(SsaBuilder builder,
                        TargetElement target,
                        SwitchStatement node)
      : super(builder, target) {
    // The switch case indices must match those computed in
    // [SsaBuilder.buildSwitchCaseConstants].
    // Switch indices are 1-based so we can bypass the synthetic loop when no
    // cases match simply by branching on the index (which defaults to null).
    int switchIndex = 1;
    for (SwitchCase switchCase in node.cases) {
      for (Node labelOrCase in switchCase.labelsAndCases) {
        Node label = labelOrCase.asLabel();
        if (label != null) {
          LabelElement labelElement = builder.elements[label];
          if (labelElement != null && labelElement.isContinueTarget) {
            TargetElement continueTarget = labelElement.target;
            targetIndexMap[continueTarget] = switchIndex;
            assert(builder.jumpTargets[continueTarget] == null);
            builder.jumpTargets[continueTarget] = this;
          }
        }
      }
      switchIndex++;
    }
  }

  void generateBreak([LabelElement label]) {
    if (label == null) {
      // Creates a special break instruction for the synthetic loop generated
      // for a switch statement with continue statements. See
      // [SsaBuilder.buildComplexSwitchStatement] for detail.

      HInstruction breakInstruction =
          new HBreak(target, breakSwitchContinueLoop: true);
      LocalsHandler locals = new LocalsHandler.from(builder.localsHandler);
      builder.close(breakInstruction);
      jumps.add(new JumpHandlerEntry(breakInstruction, locals));
    } else {
      super.generateBreak(label);
    }
  }

  bool isContinueToSwitchCase(LabelElement label) {
    return label != null && targetIndexMap.containsKey(label.target);
  }

  void generateContinue([LabelElement label]) {
    if (isContinueToSwitchCase(label)) {
      // Creates the special instructions 'label = i; continue l;' used in
      // switch statements with continue statements. See
      // [SsaBuilder.buildComplexSwitchStatement] for detail.

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
    for (TargetElement target in targetIndexMap.keys) {
      builder.jumpTargets.remove(target);
    }
    super.close();
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

  /**
   * True if we are visiting the expression of a throw expression.
   */
  bool inThrowExpression = false;

  final List<Element> sourceElementStack;

  Element get currentElement => sourceElementStack.last.declaration;
  Element get currentNonClosureClass {
    ClassElement cls = currentElement.getEnclosingClass();
    if (cls != null && cls.isClosure()) {
      var closureClass = cls;
      return closureClass.methodElement.getEnclosingClass();
    } else {
      return cls;
    }
  }

  /// A stack of [DartType]s the have been seen during inlining of factory
  /// constructors.  These types are preserved in [HInvokeStatic]s and
  /// [HForeignNews] inside the inline code and registered during code
  /// generation for these nodes.
  // TODO(karlklose): consider removing this and keeping the (substituted)
  // types of the type variables in an environment (like the [LocalsHandler]).
  final List<DartType> currentInlinedInstantiations = <DartType>[];

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
      super(work.resolutionTree, builder.compiler) {
    localsHandler = new LocalsHandler(this);
  }

  List<InliningState> inliningStack;

  Element returnElement;
  DartType returnType;

  bool inTryStatement = false;
  int loopNesting = 0;

  HBasicBlock get current => _current;
  void set current(c) {
    isReachable = c != null;
    _current = c;
  }

  Constant getConstantForNode(Node node) {
    ConstantHandler handler = compiler.constantHandler;
    Constant constant = elements.getConstant(node);
    assert(invariant(node, constant != null,
        message: 'No constant computed for $node'));
    return constant;
  }

  HInstruction addConstant(Node node) {
    return graph.addConstant(getConstantForNode(node), compiler);
  }

  bool isLazilyInitialized(VariableElement element) {
    Constant initialValue =
        compiler.constantHandler.getConstantForVariable(element);
    return initialValue == null;
  }

  TypeMask cachedTypeOfThis;

  TypeMask getTypeOfThis() {
    TypeMask result = cachedTypeOfThis;
    if (result == null) {
      Element element = localsHandler.closureData.thisElement;
      ClassElement cls = element.enclosingElement.getEnclosingClass();
      if (compiler.world.isUsedAsMixin(cls)) {
        // If the enclosing class is used as a mixin, [:this:] can be
        // of the class that mixins the enclosing class. These two
        // classes do not have a subclass relationship, so, for
        // simplicity, we mark the type as an interface type.
        result = new TypeMask.nonNullSubtype(cls.declaration);
      } else {
        result = new TypeMask.nonNullSubclass(cls.declaration);
      }
      cachedTypeOfThis = result;
    }
    return result;
  }

  Map<Element, TypeMask> cachedTypesOfCapturedVariables =
      new Map<Element, TypeMask>();

  TypeMask getTypeOfCapturedVariable(Element element) {
    assert(element.isField());
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
    FunctionExpression function = functionElement.parseNode(compiler);
    assert(function != null);
    assert(!function.modifiers.isExternal());
    assert(elements[function] != null);
    openFunction(functionElement, function);
    String name = functionElement.name;
    // If [functionElement] is `operator==` we explicitely add a null check at
    // the beginning of the method. This is to avoid having call sites do the
    // null check.
    if (name == '==') {
      if (!backend.operatorEqHandlesNullArgument(functionElement)) {
        handleIf(
            function,
            () {
              HParameterValue parameter = parameters.values.first;
              push(new HIdentity(
                  parameter, graph.addConstantNull(compiler), null,
                  backend.boolType));
            },
            () {
              closeAndGotoExit(new HReturn(
                  graph.addConstantBool(false, compiler)));
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
      classElement.addBackendMember(bodyElement);

      if (constructor.isPatch) {
        // Create origin body element for patched constructors.
        bodyElement.origin = new ConstructorBodyElementX(constructor.origin);
        bodyElement.origin.patch = bodyElement;
        classElement.origin.addBackendMember(bodyElement.origin);
      }
    }
    assert(bodyElement.isGenerativeConstructorBody());
    return bodyElement;
  }

  HParameterValue addParameter(Element element, TypeMask type) {
    assert(inliningStack.isEmpty);
    HParameterValue result = new HParameterValue(element, type);
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
  InliningState enterInlinedMethod(FunctionElement function,
                                   Selector selector,
                                   List<HInstruction> providedArguments,
                                   Node currentNode) {
    assert(invariant(function, function.isImplementation));

    List<HInstruction> compiledArguments;
    bool isInstanceMember = function.isInstanceMember();

    if (currentNode == null
        || currentNode.asForIn() != null
        || !isInstanceMember
        || function.isGenerativeConstructorBody()) {
      // For these cases, the provided arguments must match the
      // expected parameters.
      assert(providedArguments != null);
      compiledArguments = providedArguments;
    } else {
      Send send = currentNode.asSend();
      assert(providedArguments != null);
      compiledArguments = new List<HInstruction>();
      compiledArguments.add(providedArguments[0]);
      // [providedArguments] contains the arguments given in our
      // internal order (see [addDynamicSendArgumentsToList]). So we
      // call [Selector.addArgumentsToList] only for getting the
      // default values of the optional parameters.
      bool succeeded = selector.addArgumentsToList(
          send.isPropertyAccess ? null : send.arguments,
          compiledArguments,
          function,
          (node) => null,
          handleConstantForOptionalParameter,
          compiler);
      int argumentIndex = 1; // Skip receiver.
      // [compiledArguments] now only contains the default values of
      // the optional parameters that were not provided by
      // [argumentsNodes]. So we iterate over [providedArguments] to fill
      // in all the arguments.
      for (int i = 1; i < compiledArguments.length; i++) {
        if (compiledArguments[i] == null) {
          compiledArguments[i] = providedArguments[argumentIndex++];
        }
      }
      // The caller of [enterInlinedMethod] has ensured the selector
      // matches the element.
      assert(succeeded);
    }

    // Create the inlining state after evaluating the arguments, that
    // may have an impact on the state of the current method.
    InliningState state = new InliningState(
        function, returnElement, returnType, elements, stack,
        localsHandler, inTryStatement);
    inTryStatement = false;
    LocalsHandler newLocalsHandler = new LocalsHandler(this);
    newLocalsHandler.closureData =
        compiler.closureToClassMapper.computeClosureToClassMapping(
            function, function.parseNode(compiler), elements);
    int argumentIndex = 0;
    if (isInstanceMember) {
      newLocalsHandler.updateLocal(newLocalsHandler.closureData.thisElement,
                                   compiledArguments[argumentIndex++]);
    }

    FunctionSignature signature = function.computeSignature(compiler);
    signature.orderedForEachParameter((Element parameter) {
      HInstruction argument = compiledArguments[argumentIndex++];
      newLocalsHandler.updateLocal(parameter, argument);
    });

    ClassElement enclosing = function.getEnclosingClass();
    if ((function.isConstructor() || function.isGenerativeConstructorBody())
        && backend.classNeedsRti(enclosing)) {
      enclosing.typeVariables.forEach((TypeVariableType typeVariable) {
        HInstruction argument = compiledArguments[argumentIndex++];
        newLocalsHandler.updateLocal(typeVariable.element, argument);
      });
    }
    assert(argumentIndex == compiledArguments.length);

    // TODO(kasperl): Bad smell. We shouldn't be constructing elements here.
    returnElement = new ElementX("result",
                                 ElementKind.VARIABLE,
                                 function);
    newLocalsHandler.updateLocal(returnElement,
                                 graph.addConstantNull(compiler));
    elements = compiler.enqueuer.resolution.getCachedElements(function);
    assert(elements != null);
    returnType = signature.returnType;
    stack = <HInstruction>[];
    inliningStack.add(state);
    localsHandler = newLocalsHandler;
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
    inTryStatement = state.inTryStatement;
  }

  /**
   * Try to inline [element] within the currect context of the
   * builder. The insertion point is the state of the builder.
   */
  bool tryInlineMethod(Element element,
                       Selector selector,
                       List<HInstruction> providedArguments,
                       Node currentNode,
                       [DartType instantiatedType]) {
    backend.registerStaticUse(element, compiler.enqueuer.codegen);

    // Ensure that [element] is an implementation element.
    element = element.implementation;
    FunctionElement function = element;

    bool insideLoop = loopNesting > 0 || graph.calledInLoop;

    // Bail out early if the inlining decision is in the cache and we can't
    // inline (no need to check the hard constraints).
    bool cachedCanBeInlined =
        backend.inlineCache.canInline(function, insideLoop: insideLoop);
    if (cachedCanBeInlined == false) return false;

    bool meetsHardConstraints() {
      // We cannot inline a method from a deferred library into a method
      // which isn't deferred.
      // TODO(ahe): But we should still inline into the same
      // connected-component of the deferred library.
      if (compiler.deferredLoadTask.isDeferred(element)) return false;
      if (compiler.disableInlining) return false;

      assert(selector != null
             || Elements.isStaticOrTopLevel(element)
             || element.isGenerativeConstructorBody());
      if (selector != null && !selector.applies(function, compiler)) {
        return false;
      }

      // Don't inline operator== methods if the parameter can be null.
      if (element.name == '==') {
        if (element.getEnclosingClass() != compiler.objectClass
            && providedArguments[1].canBeNull()) {
          return false;
        }
      }

      // Generative constructors of native classes should not be called directly
      // and have an extra argument that causes problems with inlining.
      if (element.isGenerativeConstructor()
          && Elements.isNativeOrExtendsNative(element.getEnclosingClass())) {
        return false;
      }

      // A generative constructor body is not seen by global analysis,
      // so we should not query for its type.
      if (!element.isGenerativeConstructorBody()) {
        // Don't inline if the return type was inferred to be non-null empty.
        // This means that the function always throws an exception.
        TypeMask returnType =
            compiler.typesTask.getGuaranteedReturnTypeOfElement(element);
        if (returnType != null
            && returnType.isEmpty
            && !returnType.isNullable) {
          isReachable = false;
          return false;
        }
      }

      return true;
    }

    bool heuristicSayGoodToGo(FunctionExpression functionExpression) {
      // Don't inline recursivly
      if (inliningStack.any((entry) => entry.function == function)) {
        return false;
      }

      if (element.isSynthesized) return true;

      if (cachedCanBeInlined == true) return cachedCanBeInlined;

      if (inThrowExpression) return false;

      int numParameters = function.functionSignature.parameterCount;
      int maxInliningNodes;
      if (insideLoop) {
        maxInliningNodes = InlineWeeder.INLINING_NODES_INSIDE_LOOP +
            InlineWeeder.INLINING_NODES_INSIDE_LOOP_ARG_FACTOR * numParameters;
      } else {
        maxInliningNodes = InlineWeeder.INLINING_NODES_OUTSIDE_LOOP +
            InlineWeeder.INLINING_NODES_OUTSIDE_LOOP_ARG_FACTOR * numParameters;
      }
      bool canBeInlined = InlineWeeder.canBeInlined(
          functionExpression, maxInliningNodes);
      if (canBeInlined) {
        backend.inlineCache.markAsInlinable(element, insideLoop: insideLoop);
      } else {
        backend.inlineCache.markAsNonInlinable(element, insideLoop: insideLoop);
      }
      return canBeInlined;
    }

    void doInlining(FunctionExpression functionExpression) {
      // Add an explicit null check on the receiver before doing the
      // inlining. We use [element] to get the same name in the
      // NoSuchMethodError message as if we had called it.
      if (element.isInstanceMember()
          && !element.isGenerativeConstructorBody()
          && (selector.mask == null || selector.mask.isNullable)) {
        addWithPosition(
            new HFieldGet(null, providedArguments[0], backend.dynamicType,
                          isAssignable: false),
            currentNode);
      }
      InliningState state = enterInlinedMethod(
          function, selector, providedArguments, currentNode);

      inlinedFrom(element, () {
        FunctionElement function = element;
        FunctionSignature signature = function.computeSignature(compiler);
        signature.orderedForEachParameter((Element parameter) {
          HInstruction argument = localsHandler.readLocal(parameter);
          potentiallyCheckType(argument, parameter.computeType(compiler));
        });
        addInlinedInstantiation(instantiatedType);
        if (element.isGenerativeConstructor()) {
          buildFactory(element);
        } else {
          functionExpression.body.accept(this);
        }
        removeInlinedInstantiation(instantiatedType);
      });
      leaveInlinedMethod(state);
    }

    if (meetsHardConstraints()) {
      FunctionExpression functionExpression = function.parseNode(compiler);

      if (heuristicSayGoodToGo(functionExpression)) {
        doInlining(functionExpression);
        return true;
      }
    }

    return false;
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
   * Invariant: [constructors] must contain only implementation elements.
   */
  void inlineSuperOrRedirect(FunctionElement callee,
                             List<HInstruction> compiledArguments,
                             List<FunctionElement> constructors,
                             Map<Element, HInstruction> fieldValues,
                             FunctionElement caller) {
    callee = callee.implementation;
    compiler.withCurrentElement(callee, () {
      constructors.add(callee);
      ClassElement enclosingClass = callee.getEnclosingClass();
      if (backend.classNeedsRti(enclosingClass)) {
        // If [enclosingClass] needs RTI, we have to give a value to its
        // type parameters.
        ClassElement currentClass = caller.getEnclosingClass();
        // For a super constructor call, the type is the supertype of
        // [currentClass]. For a redirecting constructor, the type is
        // the current type. [InterfaceType.asInstanceOf] takes care
        // of both.
        InterfaceType type = currentClass.thisType.asInstanceOf(enclosingClass);
        Link<DartType> typeVariables = enclosingClass.typeVariables;
        type.typeArguments.forEach((DartType argument) {
          localsHandler.updateLocal(
              typeVariables.head.element,
              analyzeTypeArgument(argument));
          typeVariables = typeVariables.tail;
        });
        // If the supertype is a raw type, we need to set to null the
        // type variables.
        assert(typeVariables.isEmpty
               || enclosingClass.typeVariables == typeVariables);
        while (!typeVariables.isEmpty) {
          localsHandler.updateLocal(typeVariables.head.element,
              graph.addConstantNull(compiler));
          typeVariables = typeVariables.tail;
        }
      }

      // For redirecting constructors, the fields have already been
      // initialized by the caller.
      if (callee.getEnclosingClass() != caller.getEnclosingClass()) {
        inlinedFrom(callee, () {
          buildFieldInitializers(callee.enclosingElement.implementation,
                               fieldValues);
        });
      }

      int index = 0;
      FunctionSignature params = callee.computeSignature(compiler);
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
      elements = compiler.enqueuer.resolution.getCachedElements(callee);
      ClosureClassMap oldClosureData = localsHandler.closureData;
      Node node = callee.parseNode(compiler);
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
  void buildInitializers(FunctionElement constructor,
                         List<FunctionElement> constructors,
                         Map<Element, HInstruction> fieldValues) {
    assert(invariant(constructor, constructor.isImplementation));
    if (constructor.isSynthesized) {
      List<HInstruction> arguments = <HInstruction>[];
      HInstruction compileArgument(Element element) {
        return localsHandler.readLocal(element);
      }

      Element target = constructor.targetConstructor.implementation;
      Selector.addForwardingElementArgumentsToList(
          constructor,
          arguments,
          target,
          compileArgument,
          handleConstantForOptionalParameter,
          compiler);
      inlineSuperOrRedirect(
          target,
          arguments,
          constructors,
          fieldValues,
          constructor);
      return;
    }
    FunctionExpression functionNode = constructor.parseNode(compiler);

    bool foundSuperOrRedirect = false;
    if (functionNode.initializers != null) {
      Link<Node> initializers = functionNode.initializers.nodes;
      for (Link<Node> link = initializers; !link.isEmpty; link = link.tail) {
        assert(link.head is Send);
        if (link.head is !SendSet) {
          // A super initializer or constructor redirection.
          foundSuperOrRedirect = true;
          Send call = link.head;
          assert(Initializers.isSuperConstructorCall(call) ||
                 Initializers.isConstructorRedirect(call));
          FunctionElement target = elements[call].implementation;
          Selector selector = elements.getSelector(call);
          Link<Node> arguments = call.arguments;
          List<HInstruction> compiledArguments = new List<HInstruction>();
          inlinedFrom(constructor, () {
            addStaticSendArgumentsToList(selector,
                                         arguments,
                                         target,
                                         compiledArguments);
          });
          inlineSuperOrRedirect(target,
                                compiledArguments,
                                constructors,
                                fieldValues,
                                constructor);
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
        List<HInstruction> arguments = <HInstruction>[];
        selector.addArgumentsToList(const Link<Node>(),
                                    arguments,
                                    target.implementation,
                                    null,
                                    handleConstantForOptionalParameter,
                                    compiler);
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
        (ClassElement enclosingClass, Element member) {
          compiler.withCurrentElement(member, () {
            TreeElements definitions = compiler.analyzeElement(member);
            Node node = member.parseNode(compiler);
            SendSet assignment = node.asSendSet();
            if (assignment == null) {
              // Unassigned fields of native classes are not initialized to
              // prevent overwriting pre-initialized native properties.
              if (!Elements.isNativeOrExtendsNative(classElement)) {
                fieldValues[member] = graph.addConstantNull(compiler);
              }
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
  HGraph buildFactory(FunctionElement functionElement) {
    functionElement = functionElement.implementation;
    ClassElement classElement =
        functionElement.getEnclosingClass().implementation;
    bool isNativeUpgradeFactory =
        Elements.isNativeOrExtendsNative(classElement);
    FunctionExpression function = functionElement.parseNode(compiler);
    // Note that constructors (like any other static function) do not need
    // to deal with optional arguments. It is the callers job to provide all
    // arguments as if they were positional.

    if (inliningStack.isEmpty) {
      // The initializer list could contain closures.
      openFunction(functionElement, function);
    }

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
    List<Element> fields = <Element>[];

    classElement.forEachInstanceField(
        (ClassElement enclosingClass, Element member) {
          HInstruction value = fieldValues[member];
          if (value == null) {
            // Uninitialized native fields are pre-initialized by the native
            // implementation.
            assert(isNativeUpgradeFactory);
          } else {
            fields.add(member);
            constructorArguments.add(
                potentiallyCheckType(value, member.computeType(compiler)));
          }
        },
        includeSuperAndInjectedMembers: true);

    InterfaceType type = classElement.computeType(compiler);
    TypeMask ssaType = new TypeMask.nonNullExact(classElement.declaration);
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
      List<HInstruction> rtiInputs = <HInstruction>[];
      classElement.typeVariables.forEach((TypeVariableType typeVariable) {
        rtiInputs.add(localsHandler.readLocal(typeVariable.element));
      });
      callSetRuntimeTypeInfo(classElement, rtiInputs, newObject);
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
          Constant constant = new InterceptorConstant(
              classElement.computeType(compiler));
          interceptor = graph.addConstant(constant, compiler);
        }
        bodyCallInputs.add(interceptor);
      }
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

      ClassElement currentClass = constructor.getEnclosingClass();
      if (backend.classNeedsRti(currentClass)) {
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

      if (!isNativeUpgradeFactory && // TODO(13836): Fix inlining.
          tryInlineMethod(body, null, bodyCallInputs, function)) {
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
      closeAndGotoExit(new HReturn(newObject));
      return closeFunction();
    } else {
      localsHandler.updateLocal(returnElement, newObject);
      return null;
    }
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

    // Add the type parameters of the class as parameters of this method.  This
    // must be done before adding the normal parameters, because their types
    // may contain references to type variables.
    var enclosing = element.enclosingElement;
    if ((element.isConstructor() || element.isGenerativeConstructorBody())
        && backend.classNeedsRti(enclosing)) {
      enclosing.typeVariables.forEach((TypeVariableType typeVariable) {
        HParameterValue param = addParameter(
            typeVariable.element, backend.nonNullType);
        localsHandler.directLocals[typeVariable.element] = param;
      });
    }

    if (element is FunctionElement) {
      FunctionElement functionElement = element;
      FunctionSignature signature = functionElement.computeSignature(compiler);

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
  }

  HInstruction buildTypeConversion(HInstruction original,
                                   DartType type,
                                   int kind) {
    if (type == null) return original;
    type = type.unalias(compiler);
    if (type.kind == TypeKind.INTERFACE && !type.treatAsRaw) {
      TypeMask subtype = new TypeMask.subtype(type.element);
      HInstruction representations = buildTypeArgumentRepresentations(type);
      add(representations);
      return new HTypeConversion.withTypeRepresentation(type, kind, subtype,
          original, representations);
    } else if (type.kind == TypeKind.TYPE_VARIABLE) {
      TypeMask subtype = original.instructionType;
      HInstruction typeVariable = addTypeVariableReference(type);
      return new HTypeConversion.withTypeRepresentation(type, kind, subtype,
          original, typeVariable);
    } else if (type.kind == TypeKind.FUNCTION) {
      if (backend.rti.isSimpleFunctionType(type)) {
        return original.convertType(compiler, type, kind);
      }
      TypeMask subtype = original.instructionType;
      if (type.containsTypeVariables) {
        bool contextIsTypeArguments = false;
        HInstruction context;
        if (!currentElement.enclosingElement.isClosure()
            && currentElement.isInstanceMember()) {
          context = localsHandler.readThis();
        } else {
          ClassElement contextClass = Types.getClassContext(type);
          context = buildTypeVariableList(contextClass);
          add(context);
          contextIsTypeArguments = true;
        }
        return new HTypeConversion.withContext(type, kind, subtype,
            original, context, contextIsTypeArguments: contextIsTypeArguments);
      } else {
        return new HTypeConversion(type, kind, subtype, original);
      }
    } else {
      return original.convertType(compiler, type, kind);
    }
  }

  HInstruction potentiallyCheckType(HInstruction original, DartType type,
      { int kind: HTypeConversion.CHECKED_MODE_CHECK }) {
    if (!compiler.enableTypeAssertions) return original;
    HInstruction other = buildTypeConversion(original, type, kind);
    if (other != original) add(other);
    compiler.enqueuer.codegen.registerIsCheck(type, work.resolutionTree);
    return other;
  }

  void assertIsSubtype(Node node, DartType subtype, DartType supertype,
                       String message) {
    HInstruction subtypeInstruction = analyzeTypeArgument(subtype);
    HInstruction supertypeInstruction = analyzeTypeArgument(supertype);
    HInstruction messageInstruction =
        graph.addConstantString(new DartString.literal(message),
                                node, compiler);
    Element element = backend.getAssertIsSubtype();
    var inputs = <HInstruction>[subtypeInstruction, supertypeInstruction,
                                messageInstruction];
    HInstruction assertIsSubtype = new HInvokeStatic(
        element, inputs, subtypeInstruction.instructionType);
    compiler.backend.registerTypeVariableBoundsSubtypeCheck(subtype, supertype);
    add(assertIsSubtype);
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

  HInstruction peek() => stack.last;

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
    HInstruction result = new HBoolify(value, backend.boolType);
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
           'length': sourceFile.length});
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

  visitThrowExpression(Expression expression) {
    bool old = inThrowExpression;
    try {
      inThrowExpression = true;
      visit(expression);
    } finally {
      inThrowExpression = old;
    }
  }

  visitExpressionStatement(ExpressionStatement node) {
    if (!isReachable) return;
    Throw throwExpression = node.expression.asThrow();
    if (throwExpression != null && inliningStack.isEmpty) {
      visitThrowExpression(throwExpression.expression);
      handleInTryStatement();
      closeAndGotoExit(new HThrow(pop()));
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
  JumpHandler beginLoopHeader(Node node) {
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

    loopNesting++;
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
    loopNesting--;
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
        return graph.addConstantBool(true, compiler);
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
    loopNesting++;
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
    loopNesting--;
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
    compiler.enqueuer.codegen.addToWorkList(callElement);
    // TODO(ahe): This should be registered in codegen, not here.
    compiler.enqueuer.codegen.registerInstantiatedClass(
        closureClassElement, work.resolutionTree);

    List<HInstruction> capturedVariables = <HInstruction>[];
    closureClassElement.forEachMember((_, Element member) {
      // The backendMembers also contains the call method(s). We are only
      // interested in the fields.
      if (member.isField()) {
        Element capturedLocal = nestedClosureData.capturedFieldMapping[member];
        assert(capturedLocal != null);
        capturedVariables.add(localsHandler.readLocal(capturedLocal));
      }
    });

    TypeMask type = new TypeMask.nonNullExact(compiler.functionClass);
    push(new HForeignNew(closureClassElement, type, capturedVariables));

    Element methodElement = nestedClosureData.closureElement;
    if (compiler.backend.methodNeedsRti(methodElement)) {
      compiler.backend.registerGenericClosure(
          methodElement, compiler.enqueuer.codegen, work.resolutionTree);
    }
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
        isAnd: ("&&" == op.source));
  }

  void visitLogicalNot(Send node) {
    assert(node.argumentsNode is Prefix);
    visit(node.receiver);
    HNot not = new HNot(popBoolified(), backend.boolType);
    pushWithPosition(not, node);
  }

  void visitUnary(Send node, Operator op) {
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
        stack.add(graph.addConstant(folded, compiler));
        return;
      }
    }

    pushInvokeDynamic(node, elements.getSelector(node), [operand]);
  }

  void visitBinary(HInstruction left,
                   Operator op,
                   HInstruction right,
                   Selector selector,
                   Send send) {
    switch (op.source) {
      case "===":
        pushWithPosition(
            new HIdentity(left, right, null, backend.boolType), op);
        return;
      case "!==":
        HIdentity eq = new HIdentity(left, right, null, backend.boolType);
        add(eq);
        pushWithPosition(new HNot(eq, backend.boolType), op);
        return;
    }

    pushInvokeDynamic(send, selector, [left, right], location: op);
    if (op.source == '!=') {
      pushWithPosition(new HNot(popBoolified(), backend.boolType), op);
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
    String result = error.name;
    if (prefix != null) {
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
    pushInvokeDynamic(send, selector, [receiver]);
  }

  void generateGetter(Send send, Element element) {
    if (Elements.isStaticOrTopLevelField(element)) {
      Constant value;
      if (element.isField() && !element.isAssignable()) {
        // A static final or const. Get its constant value and inline it if
        // the value can be compiled eagerly.
        value = compiler.constantHandler.getConstantForVariable(element);
      }
      if (value != null) {
        HInstruction instruction = graph.addConstant(value, compiler);
        stack.add(instruction);
        // The inferrer may have found a better type than the constant
        // handler in the case of lists, because the constant handler
        // does not look at elements in the list.
        TypeMask type =
            TypeMaskFactory.inferredTypeForElement(element, compiler);
        if (!type.containsAll(compiler)) instruction.instructionType = type;
      } else if (element.isField() && isLazilyInitialized(element)) {
        HInstruction instruction = new HLazyStatic(
            element,
            TypeMaskFactory.inferredTypeForElement(element, compiler));
        push(instruction);
      } else {
        if (element.isGetter()) {
          pushInvokeStatic(send, element, <HInstruction>[]);
        } else {
          // TODO(5346): Try to avoid the need for calling [declaration] before
          // creating an [HStatic].
          HInstruction instruction = new HStatic(
              element.declaration,
              TypeMaskFactory.inferredTypeForElement(element, compiler));
          push(instruction);
        }
      }
    } else if (Elements.isInstanceSend(send, elements)) {
      HInstruction receiver = generateInstanceSendReceiver(send);
      generateInstanceGetterWithCompiledReceiver(
          send, elements.getSelector(send), receiver);
    } else if (Elements.isStaticOrTopLevelFunction(element)) {
      // TODO(5346): Try to avoid the need for calling [declaration] before
      // creating an [HStatic].
      push(new HStatic(element.declaration, backend.nonNullType));
      // TODO(ahe): This should be registered in codegen.
      compiler.enqueuer.codegen.registerGetOfStaticFunction(
          element.declaration);
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
    pushInvokeDynamic(location, selector, [receiver, value]);
    pop();
    stack.add(value);
  }

  void generateNonInstanceSetter(SendSet send,
                                 Element element,
                                 HInstruction value,
                                 {Node location}) {
    assert(send == null || !Elements.isInstanceSend(send, elements));
    if (location == null) {
      assert(send != null);
      location = send;
    }
    if (Elements.isStaticOrTopLevelField(element)) {
      if (element.isSetter()) {
        pushInvokeStatic(location, element, <HInstruction>[value]);
        pop();
      } else {
        value =
            potentiallyCheckType(value, element.computeType(compiler));
        addWithPosition(new HStaticStore(element, value), location);
      }
      stack.add(value);
    } else if (Elements.isErroneousElement(element)) {
      List<HInstruction> arguments =
          send == null ? const <HInstruction>[] : <HInstruction>[value];
      // An erroneous element indicates an unresolved static setter.
      generateThrowNoSuchMethod(location, getTargetName(element, 'set'),
                                argumentValues: arguments);
    } else {
      stack.add(value);
      // If the value does not already have a name, give it here.
      if (value.sourceElement == null) {
        value.sourceElement = element;
      }
      HInstruction checked =
          potentiallyCheckType(value, element.computeType(compiler));
      if (!identical(checked, value)) {
        pop();
        stack.add(checked);
      }
      localsHandler.updateLocal(element, checked);
    }
  }

  HInstruction invokeInterceptor(HInstruction receiver) {
    HInterceptor interceptor = new HInterceptor(receiver, backend.nonNullType);
    add(interceptor);
    return interceptor;
  }

  HForeign createForeign(js.Expression code,
                         TypeMask type,
                         List<HInstruction> inputs) {
    return new HForeign(code, type, inputs);
  }

  HInstruction getRuntimeTypeInfo(HInstruction target) {
    pushInvokeStatic(null, backend.getGetRuntimeTypeInfo(), [target]);
    return pop();
  }

  HLiteralList buildLiteralList(List<HInstruction> inputs) {
    return new HLiteralList(inputs, backend.extendableArrayType);
  }

  // TODO(karlklose): change construction of the representations to be GVN'able
  // (dartbug.com/7182).
  HInstruction buildTypeArgumentRepresentations(DartType type) {
    // Compute the representation of the type arguments, including access
    // to the runtime type information for type variables as instructions.
    if (type.kind == TypeKind.TYPE_VARIABLE) {
      return buildLiteralList(<HInstruction>[addTypeVariableReference(type)]);
    } else {
      assert(type.element.isClass());
      InterfaceType interface = type;
      List<HInstruction> inputs = <HInstruction>[];
      bool first = true;
      List<String> templates = <String>[];
      for (DartType argument in interface.typeArguments) {
        templates.add(rti.getTypeRepresentationWithHashes(argument, (variable) {
          HInstruction runtimeType = addTypeVariableReference(variable);
          inputs.add(runtimeType);
        }));
      }
      String template = '[${templates.join(', ')}]';
      js.Expression code = js.js.parseForeignJS(template);
      HInstruction representation =
        createForeign(code, backend.readableArrayType, inputs);
      return representation;
    }
  }

  visitOperatorSend(Send node) {
    Operator op = node.selector;
    if ("[]" == op.source) {
      visitDynamicSend(node);
    } else if ("&&" == op.source ||
               "||" == op.source) {
      visitLogicalAndOr(node, op);
    } else if ("!" == op.source) {
      visitLogicalNot(node);
    } else if (node.argumentsNode is Prefix) {
      visitUnary(node, op);
    } else if ("is" == op.source) {
      visitIsSend(node);
    } else if ("as" == op.source) {
      visit(node.receiver);
      HInstruction expression = pop();
      DartType type = elements.getType(node.typeAnnotationFromIsCheckOrCast);
      if (type.kind == TypeKind.MALFORMED_TYPE) {
        ErroneousElement element = type.element;
        generateTypeError(node, element.message);
      } else {
        HInstruction converted = buildTypeConversion(
            expression, type, HTypeConversion.CAST_TYPE_CHECK);
        if (converted != expression) add(converted);
        stack.add(converted);
      }
    } else {
      visit(node.receiver);
      visit(node.argumentsNode);
      var right = pop();
      var left = pop();
      visitBinary(left, op, right, elements.getSelector(node), node);
    }
  }

  void visitIsSend(Send node) {
    visit(node.receiver);
    HInstruction expression = pop();
    bool isNot = node.isIsNotCheck;
    DartType type = elements.getType(node.typeAnnotationFromIsCheckOrCast);
    type = type.unalias(compiler);
    HInstruction instruction = buildIsNode(node, type, expression);
    if (isNot) {
      add(instruction);
      instruction = new HNot(instruction, backend.boolType);
    }
    push(instruction);
  }

  HLiteralList buildTypeVariableList(ClassElement contextClass) {
    List<HInstruction> inputs = <HInstruction>[];
    for (Link<DartType> link = contextClass.typeVariables;
        !link.isEmpty;
        link = link.tail) {
      inputs.add(addTypeVariableReference(link.head));
    }
    return buildLiteralList(inputs);
  }

  HInstruction buildIsNode(Node node, DartType type, HInstruction expression) {
    type = type.unalias(compiler);
    if (type.kind == TypeKind.FUNCTION) {
      if (backend.rti.isSimpleFunctionType(type)) {
        // TODO(johnniwinther): Avoid interceptor if unneeded.
        return new HIs.raw(
            type, expression, invokeInterceptor(expression), backend.boolType);
      }
      Element checkFunctionSubtype = backend.getCheckFunctionSubtype();

      HInstruction signatureName = graph.addConstantString(
          new DartString.literal(backend.namer.getFunctionTypeName(type)),
          node, compiler);

      HInstruction contextName;
      HInstruction context;
      HInstruction typeArguments;
      if (type.containsTypeVariables) {
        ClassElement contextClass = Types.getClassContext(type);
        contextName = graph.addConstantString(
            new DartString.literal(backend.namer.getNameOfClass(contextClass)),
            node, compiler);
        if (!currentElement.enclosingElement.isClosure()
            && currentElement.isInstanceMember()) {
          context = localsHandler.readThis();
          typeArguments = graph.addConstantNull(compiler);
        } else {
          context = graph.addConstantNull(compiler);
          typeArguments = buildTypeVariableList(contextClass);
          add(typeArguments);
        }
      } else {
        contextName = graph.addConstantNull(compiler);
        context = graph.addConstantNull(compiler);
        typeArguments = graph.addConstantNull(compiler);
      }

      List<HInstruction> inputs = <HInstruction>[expression,
                                                 signatureName,
                                                 contextName,
                                                 context,
                                                 typeArguments];
      pushInvokeStatic(node, checkFunctionSubtype, inputs, backend.boolType);
      HInstruction call = pop();
      return new HIs.compound(type, expression, call, backend.boolType);
    } else if (type.kind == TypeKind.TYPE_VARIABLE) {
      HInstruction runtimeType = addTypeVariableReference(type);
      Element helper = backend.getCheckSubtypeOfRuntimeType();
      List<HInstruction> inputs = <HInstruction>[expression, runtimeType];
      pushInvokeStatic(null, helper, inputs, backend.boolType);
      HInstruction call = pop();
      return new HIs.variable(type, expression, call, backend.boolType);
    } else if (RuntimeTypes.hasTypeArguments(type)) {
      ClassElement element = type.element;
      Element helper = backend.getCheckSubtype();
      HInstruction representations =
          buildTypeArgumentRepresentations(type);
      add(representations);
      String operator =
          backend.namer.operatorIs(backend.getImplementationClass(element));
      HInstruction isFieldName = addConstantString(node, operator);
      HInstruction asFieldName = compiler.world.hasAnySubtype(element)
          ? addConstantString(node, backend.namer.substitutionName(element))
          : graph.addConstantNull(compiler);
      List<HInstruction> inputs = <HInstruction>[expression,
                                                 isFieldName,
                                                 representations,
                                                 asFieldName];
      pushInvokeStatic(node, helper, inputs, backend.boolType);
      HInstruction call = pop();
      return new HIs.compound(type, expression, call, backend.boolType);
    } else if (type.kind == TypeKind.MALFORMED_TYPE) {
      ErroneousElement element = type.element;
      generateTypeError(node, element.message);
      HInstruction call = pop();
      return new HIs.compound(type, expression, call, backend.boolType);
    } else {
      if (backend.hasDirectCheckFor(type)) {
        return new HIs.direct(type, expression, backend.boolType);
      }
      // TODO(johnniwinther): Avoid interceptor if unneeded.
      return new HIs.raw(
          type, expression, invokeInterceptor(expression), backend.boolType);
    }
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
      Map<String, HInstruction> instructions =
          new Map<String, HInstruction>();
      List<String> namedArguments = selector.namedArguments;
      int nameIndex = 0;
      for (; !arguments.isEmpty; arguments = arguments.tail) {
        visit(arguments.head);
        instructions[namedArguments[nameIndex++]] = pop();
      }

      // Iterate through the named arguments to add them to the list
      // of instructions, in an order that can be shared with
      // selectors with the same named arguments.
      List<String> orderedNames = selector.getOrderedNamedArguments();
      for (String name in orderedNames) {
        list.add(instructions[name]);
      }
    }
  }

  HInstruction handleConstantForOptionalParameter(Element parameter) {
    Constant constant =
        compiler.constantHandler.getConstantForVariable(parameter);
    assert(invariant(parameter, constant != null,
        message: 'No constant computed for $parameter'));
    return graph.addConstant(constant, compiler);
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

    return selector.addArgumentsToList(arguments,
                                       list,
                                       element,
                                       compileArgument,
                                       handleConstantForOptionalParameter,
                                       compiler);
  }

  void addGenericSendArgumentsToList(Link<Node> link, List<HInstruction> list) {
    for (; !link.isEmpty; link = link.tail) {
      visit(link.head);
      list.add(pop());
    }
  }

  visitDynamicSend(Send node) {
    Selector selector = elements.getSelector(node);

    List<HInstruction> inputs = <HInstruction>[];
    HInstruction receiver = generateInstanceSendReceiver(node);
    inputs.add(receiver);
    addDynamicSendArgumentsToList(node, inputs);

    pushInvokeDynamic(node, selector, inputs);
    if (selector.isSetter() || selector.isIndexSet()) {
      pop();
      stack.add(inputs.last);
    }
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
    pushWithPosition(
        new HInvokeClosure(closureSelector, inputs, backend.dynamicType),
        node);
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
    native.NativeBehavior nativeBehavior =
        compiler.enqueuer.resolution.nativeEnqueuer.getNativeBehaviorOf(node);

    List<HInstruction> inputs = <HInstruction>[];
    addGenericSendArgumentsToList(link.tail.tail, inputs);

    TypeMask ssaType =
        TypeMaskFactory.fromNativeBehavior(nativeBehavior, compiler);
    push(new HForeign(nativeBehavior.codeAst, ssaType, inputs,
                      effects: nativeBehavior.sideEffects,
                      nativeBehavior: nativeBehavior));
    return;
  }

  void handleForeignJsCurrentIsolateContext(Send node) {
    if (!node.arguments.isEmpty) {
      compiler.cancel(
          'Too many arguments to JS_CURRENT_ISOLATE_CONTEXT', node: node);
    }

    if (!compiler.hasIsolateSupport()) {
      // If the isolate library is not used, we just generate code
      // to fetch the current isolate.
      String name = backend.namer.CURRENT_ISOLATE;
      push(new HForeign(new js.LiteralString(name),
                        backend.dynamicType,
                        <HInstruction>[]));
    } else {
      // Call a helper method from the isolate library. The isolate
      // library uses its own isolate structure, that encapsulates
      // Leg's isolate.
      Element element = compiler.isolateHelperLibrary.find('_currentIsolate');
      if (element == null) {
        compiler.cancel(
            'Isolate library and compiler mismatch', node: node);
      }
      pushInvokeStatic(null, element, [], backend.dynamicType);
    }
  }

  void handleForeignJsGetName(Send node) {
    List<Node> arguments = node.arguments.toList();
    Node argument;
    switch (arguments.length) {
    case 0:
      compiler.reportError(
          node, MessageKind.GENERIC,
          {'text': 'Error: Expected one argument to JS_GET_NAME.'});
      return;
    case 1:
      argument = arguments[0];
      break;
    default:
      for (int i = 1; i < arguments.length; i++) {
        compiler.reportError(
            arguments[i], MessageKind.GENERIC,
            {'text': 'Error: Extra argument to JS_GET_NAME.'});
      }
      return;
    }
    LiteralString string = argument.asLiteralString();
    if (string == null) {
      compiler.reportError(
          argument, MessageKind.GENERIC,
          {'text': 'Error: Expected a literal string.'});
    }
    stack.add(
        addConstantString(
            argument,
            backend.namer.getNameForJsGetName(
                argument, string.dartString.slowToString())));
  }

  void handleJsInterceptorConstant(Send node) {
    // Single argument must be a TypeConstant which is converted into a
    // InterceptorConstant.
    if (!node.arguments.isEmpty && node.arguments.tail.isEmpty) {
      Node argument = node.arguments.head;
      visit(argument);
      HInstruction argumentInstruction = pop();
      if (argumentInstruction is HConstant) {
        Constant argumentConstant = argumentInstruction.constant;
        if (argumentConstant is TypeConstant) {
          Constant constant =
              new InterceptorConstant(argumentConstant.representedType);
          HInstruction instruction = graph.addConstant(constant, compiler);
          stack.add(instruction);
          return;
        }
      }
    }
    compiler.reportError(node,
        MessageKind.WRONG_ARGUMENT_FOR_JS_INTERCEPTOR_CONSTANT);
    stack.add(graph.addConstantNull(compiler));
  }

  void handleForeignJsCallInIsolate(Send node) {
    Link<Node> link = node.arguments;
    if (!compiler.hasIsolateSupport()) {
      // If the isolate library is not used, we just invoke the
      // closure.
      visit(link.tail.head);
      Selector selector = new Selector.callClosure(0);
      push(new HInvokeClosure(selector,
                              <HInstruction>[pop()],
                              backend.dynamicType));
    } else {
      // Call a helper method from the isolate library.
      Element element = compiler.isolateHelperLibrary.find('_callInIsolate');
      if (element == null) {
        compiler.cancel(
            'Isolate library and compiler mismatch', node: node);
      }
      List<HInstruction> inputs = <HInstruction>[];
      addGenericSendArgumentsToList(link, inputs);
      pushInvokeStatic(node, element, inputs, backend.dynamicType);
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
    push(new HForeign(js.js('#.$invocationName'),
                      backend.dynamicType,
                      inputs));
  }

  void handleForeignSetCurrentIsolate(Send node) {
    if (node.arguments.isEmpty || !node.arguments.tail.isEmpty) {
      compiler.cancel('Exactly one argument required',
                      node: node.argumentsNode);
    }
    visit(node.arguments.head);
    String isolateName = backend.namer.CURRENT_ISOLATE;
    SideEffects sideEffects = new SideEffects.empty();
    sideEffects.setAllSideEffects();
    push(new HForeign(js.js("$isolateName = #"),
                      backend.dynamicType,
                      <HInstruction>[pop()],
                      effects: sideEffects));
  }

  void handleForeignCreateIsolate(Send node) {
    if (!node.arguments.isEmpty) {
      compiler.cancel('Too many arguments',
                      node: node.argumentsNode);
    }
    String constructorName = backend.namer.isolateName;
    push(new HForeign(js.js("new $constructorName()"),
                      backend.dynamicType,
                      <HInstruction>[]));
  }

  void handleForeignDartObjectJsConstructorFunction(Send node) {
    if (!node.arguments.isEmpty) {
      compiler.cancel('Too many arguments', node: node.argumentsNode);
    }
    String jsClassReference = backend.namer.isolateAccess(compiler.objectClass);
    push(new HForeign(new js.LiteralString(jsClassReference),
                      backend.dynamicType,
                      <HInstruction>[]));
  }

  void handleForeignJsCurrentIsolate(Send node) {
    if (!node.arguments.isEmpty) {
      compiler.cancel('Too many arguments', node: node.argumentsNode);
    }
    push(new HForeign(new js.LiteralString(backend.namer.CURRENT_ISOLATE),
                      backend.dynamicType,
                      <HInstruction>[]));
  }

  visitForeignSend(Send node) {
    Selector selector = elements.getSelector(node);
    String name = selector.name;
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
    } else if (name == 'JS_SET_CURRENT_ISOLATE') {
      handleForeignSetCurrentIsolate(node);
    } else if (name == 'JS_CREATE_ISOLATE') {
      handleForeignCreateIsolate(node);
    } else if (name == 'JS_OPERATOR_IS_PREFIX') {
      stack.add(addConstantString(node, backend.namer.operatorIsPrefix()));
    } else if (name == 'JS_OBJECT_CLASS_NAME') {
      String name = backend.namer.getRuntimeTypeName(compiler.objectClass);
      stack.add(addConstantString(node, name));
    } else if (name == 'JS_NULL_CLASS_NAME') {
      String name = backend.namer.getRuntimeTypeName(compiler.nullClass);
      stack.add(addConstantString(node, name));
    } else if (name == 'JS_FUNCTION_CLASS_NAME') {
      String name = backend.namer.getRuntimeTypeName(compiler.functionClass);
      stack.add(addConstantString(node, name));
    } else if (name == 'JS_OPERATOR_AS_PREFIX') {
      stack.add(addConstantString(node, backend.namer.operatorAsPrefix()));
    } else if (name == 'JS_SIGNATURE_NAME') {
      stack.add(addConstantString(node, backend.namer.operatorSignature()));
    } else if (name == 'JS_FUNCTION_TYPE_TAG') {
      stack.add(addConstantString(node, backend.namer.functionTypeTag()));
    } else if (name == 'JS_FUNCTION_TYPE_VOID_RETURN_TAG') {
      stack.add(addConstantString(node,
                                  backend.namer.functionTypeVoidReturnTag()));
    } else if (name == 'JS_FUNCTION_TYPE_RETURN_TYPE_TAG') {
      stack.add(addConstantString(node,
                                  backend.namer.functionTypeReturnTypeTag()));
    } else if (name ==
               'JS_FUNCTION_TYPE_REQUIRED_PARAMETERS_TAG') {
      stack.add(addConstantString(node,
          backend.namer.functionTypeRequiredParametersTag()));
    } else if (name ==
               'JS_FUNCTION_TYPE_OPTIONAL_PARAMETERS_TAG') {
      stack.add(addConstantString(node,
          backend.namer.functionTypeOptionalParametersTag()));
    } else if (name ==
               'JS_FUNCTION_TYPE_NAMED_PARAMETERS_TAG') {
      stack.add(addConstantString(node,
          backend.namer.functionTypeNamedParametersTag()));
    } else if (name == 'JS_DART_OBJECT_CONSTRUCTOR') {
      handleForeignDartObjectJsConstructorFunction(node);
    } else if (name == 'JS_IS_INDEXABLE_FIELD_NAME') {
      Element element = compiler.findHelper(
          'JavaScriptIndexingBehavior');
      stack.add(addConstantString(node, backend.namer.operatorIs(element)));
    } else if (name == 'JS_CURRENT_ISOLATE') {
      handleForeignJsCurrentIsolate(node);
    } else if (name == 'JS_GET_NAME') {
      handleForeignJsGetName(node);
    } else if (name == 'JS_EFFECT') {
      stack.add(graph.addConstantNull(compiler));
    } else if (name == 'JS_INTERCEPTOR_CONSTANT') {
      handleJsInterceptorConstant(node);
    } else {
      throw "Unknown foreign: ${selector}";
    }
  }

  generateSuperNoSuchMethodSend(Send node,
                                Selector selector,
                                List<HInstruction> arguments) {
    String name = selector.name;

    ClassElement cls = currentNonClosureClass;
    Element element = cls.lookupSuperMember(Compiler.NO_SUCH_METHOD);
    if (compiler.enabledInvokeOn
        && element.enclosingElement.declaration != compiler.objectClass) {
      // Register the call as dynamic if [noSuchMethod] on the super
      // class is _not_ the default implementation from [Object], in
      // case the [noSuchMethod] implementation calls
      // [JSInvocationMirror._invokeOn].
      compiler.enqueuer.codegen.registerSelectorUse(selector.asUntyped);
    }
    String publicName = name;
    if (selector.isSetter()) publicName += '=';

    Constant nameConstant = constantSystem.createString(
        new DartString.literal(publicName), node);

    String internalName = backend.namer.invocationName(selector);
    Constant internalNameConstant =
        constantSystem.createString(new DartString.literal(internalName), node);

    Element createInvocationMirror = backend.getCreateInvocationMirror();
    var argumentsInstruction = buildLiteralList(arguments);
    add(argumentsInstruction);

    var argumentNames = new List<HInstruction>();
    for (String argumentName in selector.namedArguments) {
      Constant argumentNameConstant =
          constantSystem.createString(new DartString.literal(argumentName),
                                      node);
      argumentNames.add(graph.addConstant(argumentNameConstant, compiler));
    }
    var argumentNamesInstruction = buildLiteralList(argumentNames);
    add(argumentNamesInstruction);

    Constant kindConstant =
        constantSystem.createInt(selector.invocationMirrorKind);

    pushInvokeStatic(null,
                     createInvocationMirror,
                     [graph.addConstant(nameConstant, compiler),
                      graph.addConstant(internalNameConstant, compiler),
                      graph.addConstant(kindConstant, compiler),
                      argumentsInstruction,
                      argumentNamesInstruction],
                      backend.dynamicType);

    var inputs = <HInstruction>[pop()];
    push(buildInvokeSuper(compiler.noSuchMethodSelector, element, inputs));
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
    List<HInstruction> inputs = <HInstruction>[];
    if (node.isPropertyAccess) {
      push(buildInvokeSuper(selector, element, inputs));
    } else if (element.isFunction() || element.isGenerativeConstructor()) {
      if (selector.applies(element, compiler)) {
        // TODO(5347): Try to avoid the need for calling [implementation] before
        // calling [addStaticSendArgumentsToList].
        FunctionElement function = element.implementation;
        bool succeeded = addStaticSendArgumentsToList(selector, node.arguments,
                                                      function, inputs);
        assert(succeeded);
        push(buildInvokeSuper(selector, element, inputs));
      } else if (element.isGenerativeConstructor()) {
        generateWrongArgumentCountError(node, element, node.arguments);
      } else {
        addGenericSendArgumentsToList(node.arguments, inputs);
        generateSuperNoSuchMethodSend(node, selector, inputs);
      }
    } else {
      HInstruction target = buildInvokeSuper(selector, element, inputs);
      add(target);
      inputs = <HInstruction>[target];
      addDynamicSendArgumentsToList(node, inputs);
      Selector closureSelector = new Selector.callClosureFrom(selector);
      push(new HInvokeClosure(closureSelector, inputs, backend.dynamicType));
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
    // TODO(ahe): Creating a string here is unfortunate. It is slow (due to
    // string concatenation in the implementation), and may prevent
    // segmentation of '$'.
    String substitutionNameString = backend.namer.getNameForRti(cls);
    HInstruction substitutionName = graph.addConstantString(
        new LiteralDartString(substitutionNameString), null, compiler);
    HInstruction target = localsHandler.readThis();
    pushInvokeStatic(null,
                     backend.getGetRuntimeTypeArgument(),
                     [target,
                      substitutionName,
                      graph.addConstantInt(index, compiler)],
                      backend.dynamicType);
    return pop();
  }

  // TODO(karlklose): this is needed to avoid a bug where the resolved type is
  // not stored on a type annotation in the closure translator. Remove when
  // fixed.
  bool hasDirectLocal(Element element) {
    return !localsHandler.isAccessedDirectly(element) ||
        localsHandler.directLocals[element] != null;
  }

  /**
   * Helper to create an instruction that gets the value of a type variable.
   */
  HInstruction addTypeVariableReference(TypeVariableType type) {
    Element member = currentElement;
    bool isClosure = member.enclosingElement.isClosure();
    if (isClosure) {
      ClosureClassElement closureClass = member.enclosingElement;
      member = closureClass.methodElement;
      member = member.getOutermostEnclosingMemberOrTopLevel();
    }
    bool isInConstructorContext = member.isConstructor() ||
        member.isGenerativeConstructorBody();
    if (isClosure) {
      if (member.isFactoryConstructor() ||
          (isInConstructorContext && hasDirectLocal(type.element))) {
        // The type variable is used from a closure in a factory constructor.
        // The value of the type argument is stored as a local on the closure
        // itself.
        return localsHandler.readLocal(type.element);
      } else if (member.isFunction() ||
          member.isGetter() ||
          member.isSetter() ||
          isInConstructorContext) {
        // The type variable is stored on the "enclosing object" and needs to be
        // accessed using the this-reference in the closure.
        return readTypeVariable(member.getEnclosingClass(), type.element);
      } else {
        assert(member.isField());
        // The type variable is stored in a parameter of the method.
        return localsHandler.readLocal(type.element);
      }
    } else if (isInConstructorContext || member.isField()) {
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

  HInstruction analyzeTypeArgument(DartType argument) {
    if (argument.treatAsDynamic) {
      // Represent [dynamic] as [null].
      return graph.addConstantNull(compiler);
    }

    List<HInstruction> inputs = <HInstruction>[];

    String template = rti.getTypeRepresentationWithHashes(argument, (variable) {
      inputs.add(addTypeVariableReference(variable));
    });

    js.Expression code = js.js.parseForeignJS(template);
    HInstruction result = createForeign(code, backend.stringType, inputs);
    add(result);
    return result;
  }

  void handleListConstructor(InterfaceType type,
                             Node currentNode,
                             HInstruction newObject) {
    if (!backend.classNeedsRti(type.element)) return;
    if (!type.treatAsRaw) {
      List<HInstruction> inputs = <HInstruction>[];
      type.typeArguments.forEach((DartType argument) {
        inputs.add(analyzeTypeArgument(argument));
      });
      callSetRuntimeTypeInfo(type.element, inputs, newObject);
    }
  }

  void callSetRuntimeTypeInfo(ClassElement element,
                              List<HInstruction> rtiInputs,
                              HInstruction newObject) {
    if (!backend.classNeedsRti(element) || element.typeVariables.isEmpty) {
      return;
    }

    HInstruction typeInfo = buildLiteralList(rtiInputs);
    add(typeInfo);

    // Set the runtime type information on the object.
    Element typeInfoSetterElement = backend.getSetRuntimeTypeInfo();
    pushInvokeStatic(
        null,
        typeInfoSetterElement,
        <HInstruction>[newObject, typeInfo],
        backend.dynamicType);
    pop();
  }

  handleNewSend(NewExpression node) {
    Send send = node.send;
    bool isListConstructor = false;
    bool isFixedList = false;

    TypeMask computeType(element) {
      Element originalElement = elements[send];
      if (Elements.isFixedListConstructorCall(originalElement, send, compiler)
          || Elements.isFilledListConstructorCall(
                  originalElement, send, compiler)) {
        isListConstructor = true;
        isFixedList = true;
        TypeMask inferred =
            TypeMaskFactory.inferredForNode(currentElement, send, compiler);
        return inferred.containsAll(compiler)
            ? backend.fixedArrayType
            : inferred;
      } else if (Elements.isGrowableListConstructorCall(
                    originalElement, send, compiler)) {
        isListConstructor = true;
        TypeMask inferred =
            TypeMaskFactory.inferredForNode(currentElement, send, compiler);
        return inferred.containsAll(compiler)
            ? backend.extendableArrayType
            : inferred;
      } else if (Elements.isConstructorOfTypedArraySubclass(
                    originalElement, compiler)) {
        isFixedList = true;
        TypeMask inferred =
            TypeMaskFactory.inferredForNode(currentElement, send, compiler);
        ClassElement cls = element.getEnclosingClass();
        return inferred.containsAll(compiler)
            ? new TypeMask.nonNullExact(cls.thisType.element)
            : inferred;
      } else if (element.isGenerativeConstructor()) {
        ClassElement cls = element.getEnclosingClass();
        return new TypeMask.nonNullExact(cls.thisType.element);
      } else {
        return TypeMaskFactory.inferredReturnTypeForElement(
            originalElement, compiler);
      }
    }

    Element constructor = elements[send];
    Selector selector = elements.getSelector(send);
    FunctionElement functionElement = constructor;
    constructor = functionElement.redirectionTarget;

    final bool isSymbolConstructor =
        functionElement == compiler.symbolConstructor;

    if (isSymbolConstructor) {
      constructor = compiler.symbolValidatedConstructor;
      assert(invariant(send, constructor != null,
                       message: 'Constructor Symbol.validated is missing'));
      selector = compiler.symbolValidatedConstructorSelector;
      assert(invariant(send, selector != null,
                       message: 'Constructor Symbol.validated is missing'));
    }

    bool isRedirected = functionElement.isRedirectingFactory;
    InterfaceType type = elements.getType(node);
    DartType expectedType = type;
    if (isRedirected) {
      type = functionElement.computeTargetType(compiler, type);
    }

    if (checkTypeVariableBounds(node, type)) return;

    var inputs = <HInstruction>[];
    if (constructor.isGenerativeConstructor() &&
        Elements.isNativeOrExtendsNative(constructor.getEnclosingClass())) {
      // Native class generative constructors take a pre-constructed object.
      inputs.add(graph.addConstantNull(compiler));
    }
    // TODO(5347): Try to avoid the need for calling [implementation] before
    // calling [addStaticSendArgumentsToList].
    bool succeeded = addStaticSendArgumentsToList(selector, send.arguments,
                                                  constructor.implementation,
                                                  inputs);
    if (!succeeded) {
      generateWrongArgumentCountError(send, constructor, send.arguments);
      return;
    }

    ClassElement cls = constructor.getEnclosingClass();
    if (cls.isAbstract(compiler) && constructor.isGenerativeConstructor()) {
      generateAbstractClassInstantiationError(send, cls.name);
      return;
    }
    if (backend.classNeedsRti(cls)) {
      Link<DartType> typeVariable = cls.typeVariables;
      type.typeArguments.forEach((DartType argument) {
        inputs.add(analyzeTypeArgument(argument));
        typeVariable = typeVariable.tail;
      });
      assert(typeVariable.isEmpty);
    }

    if (constructor.isFactoryConstructor() && !type.typeArguments.isEmpty) {
      compiler.enqueuer.codegen.registerFactoryWithTypeArguments(elements);
    }
    TypeMask elementType = computeType(constructor);
    addInlinedInstantiation(expectedType);
    pushInvokeStatic(node, constructor, inputs, elementType);
    removeInlinedInstantiation(expectedType);
    HInstruction newInstance = stack.last;

    if (isFixedList) {
      JavaScriptItemCompilationContext context = work.compilationContext;
      context.allocatedFixedLists.add(newInstance);
    }

    // The List constructor forwards to a Dart static method that does
    // not know about the type argument. Therefore we special case
    // this constructor to have the setRuntimeTypeInfo called where
    // the 'new' is done.
    if (isListConstructor && backend.classNeedsRti(compiler.listClass)) {
      handleListConstructor(type, send, newInstance);
    }

    // Finally, if we called a redirecting factory constructor, check the type.
    if (isRedirected) {
      HInstruction checked = potentiallyCheckType(newInstance, expectedType);
      if (checked != newInstance) {
        pop();
        stack.add(checked);
      }
    }
  }

  /// In checked mode checks the [type] of [node] to be well-bounded. The method
  /// returns [:true:] if an error can be statically determined.
  bool checkTypeVariableBounds(NewExpression node, InterfaceType type) {
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

  visitAssert(node) {
    if (!compiler.enableUserAssertions) {
      stack.add(graph.addConstantNull(compiler));
      return;
    }
    visitStaticSend(node);
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
    compiler.ensure(!element.isGenerativeConstructor());
    if (element.isFunction()) {
      var inputs = <HInstruction>[];
      // TODO(5347): Try to avoid the need for calling [implementation] before
      // calling [addStaticSendArgumentsToList].
      bool succeeded = addStaticSendArgumentsToList(selector, node.arguments,
                                                    element.implementation,
                                                    inputs);
      if (!succeeded) {
        generateWrongArgumentCountError(node, element, node.arguments);
        return;
      }

      if (element == compiler.identicalFunction) {
        pushWithPosition(
            new HIdentity(inputs[0], inputs[1], null, backend.boolType), node);
        return;
      }

      pushInvokeStatic(node, element, inputs);
    } else {
      generateGetter(node, element);
      List<HInstruction> inputs = <HInstruction>[pop()];
      addDynamicSendArgumentsToList(node, inputs);
      Selector closureSelector = new Selector.callClosureFrom(selector);
      pushWithPosition(
          new HInvokeClosure(closureSelector, inputs, backend.dynamicType),
          node);
    }
  }

  HConstant addConstantString(Node node, String string) {
    DartString dartString = new DartString.literal(string);
    Constant constant = constantSystem.createString(dartString, node);
    return graph.addConstant(constant, compiler);
  }

  visitTypeReferenceSend(Send node) {
    Element element = elements[node];
    if (element.isClass() || element.isTypedef()) {
      // TODO(karlklose): add type representation
      if (node.isCall) {
        // The node itself is not a constant but we register the selector (the
        // identifier that refers to the class/typedef) as a constant.
        stack.add(addConstant(node.selector));
      } else {
        stack.add(addConstant(node));
      }
    } else if (element.isTypeVariable()) {
      HInstruction value =
          addTypeVariableReference(element.computeType(compiler));
      pushInvokeStatic(node,
                       backend.getRuntimeTypeToString(),
                       [value],
                       backend.stringType);
      pushInvokeStatic(node,
                       backend.getCreateRuntimeType(),
                       [pop()]);
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
      push(new HInvokeClosure(closureSelector, inputs, backend.dynamicType));
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
    pushInvokeStatic(node, helper, [errorMessage]);
  }

  void generateRuntimeError(Node node, String message) {
    generateError(node, message, backend.getThrowRuntimeError());
  }

  void generateTypeError(Node node, String message) {
    generateError(node, message, backend.getThrowTypeError());
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
    HInstruction receiver = graph.addConstant(receiverConstant, compiler);
    DartString dartString = new DartString.literal(methodName);
    Constant nameConstant =
        constantSystem.createString(dartString, diagnosticNode);
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
            graph.addConstantString(new DartString.literal(name),
                                    diagnosticNode, compiler);
        existingNames.add(nameConstant);
      }
      existingNamesList = buildLiteralList(existingNames);
      add(existingNamesList);
    } else {
      existingNamesList = graph.addConstantNull(compiler);
    }
    pushInvokeStatic(diagnosticNode,
                     helper,
                     [receiver, name, arguments, existingNamesList]);
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
      existingArguments.add(parameter.name);
    });
    generateThrowNoSuchMethod(diagnosticNode,
                              function.name,
                              argumentNodes: argumentNodes,
                              existingArguments: existingArguments);
  }

  visitNewExpression(NewExpression node) {
    Element element = elements[node.send];
    final bool isSymbolConstructor = element == compiler.symbolConstructor;
    if (!Elements.isErroneousElement(element)) {
      FunctionElement function = element;
      element = function.redirectionTarget;
    }
    if (Elements.isErroneousElement(element)) {
      ErroneousElement error = element;
      if (error.messageKind == MessageKind.CANNOT_FIND_CONSTRUCTOR.error) {
        generateThrowNoSuchMethod(node.send,
                                  getTargetName(error, 'constructor'),
                                  argumentNodes: node.send.arguments);
      } else {
        Message message = error.messageKind.message(error.messageArguments);
        generateRuntimeError(node.send, message.toString());
      }
    } else if (node.isConst()) {
      stack.add(addConstant(node));
      if (isSymbolConstructor) {
        ConstructedConstant symbol = elements.getConstant(node);
        StringConstant stringConstant = symbol.fields.single;
        String nameString = stringConstant.toDartString().slowToString();
        compiler.enqueuer.codegen.registerConstSymbol(nameString, elements);
      }
    } else {
      handleNewSend(node);
    }
  }

  void pushInvokeDynamic(Node node,
                         Selector selector,
                         List<HInstruction> arguments,
                         {Node location}) {
    if (location == null) location = node;

    // We prefer to not inline certain operations on indexables,
    // because the constant folder will handle them better and turn
    // them into simpler instructions that allow further
    // optimizations.
    bool isOptimizableOperationOnIndexable(Selector selector, Element element) {
      bool isLength = selector.isGetter()
          && selector.name == "length";
      if (isLength || selector.isIndex()) {
        TypeMask type = new TypeMask.nonNullExact(
            element.getEnclosingClass().declaration);
        return type.satisfies(backend.jsIndexableClass, compiler);
      } else if (selector.isIndexSet()) {
        TypeMask type = new TypeMask.nonNullExact(
            element.getEnclosingClass().declaration);
        return type.satisfies(backend.jsMutableIndexableClass, compiler);
      } else {
        return false;
      }
    }

    bool isOptimizableOperation(Selector selector, Element element) {
      ClassElement cls = element.getEnclosingClass();
      if (isOptimizableOperationOnIndexable(selector, element)) return true;
      if (!backend.interceptedClasses.contains(cls)) return false;
      if (selector.isOperator()) return true;
      if (selector.isSetter()) return true;
      if (selector.isIndex()) return true;
      if (selector.isIndexSet()) return true;
      if (element == backend.jsArrayAdd
          || element == backend.jsArrayRemoveLast
          || element == backend.jsStringSplit) {
        return true;
      }
      return false;
    }

    Element element = compiler.world.locateSingleElement(selector);
    if (element != null
        && !element.isField()
        && !(element.isGetter() && selector.isCall())
        && !(element.isFunction() && selector.isGetter())
        && !isOptimizableOperation(selector, element)) {
      if (tryInlineMethod(element, selector, arguments, node)) {
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
    TypeMask type = TypeMaskFactory.inferredTypeForSelector(selector, compiler);
    if (selector.isGetter()) {
      bool hasGetter = compiler.world.hasAnyUserDefinedGetter(selector);
      pushWithPosition(
          new HInvokeDynamicGetter(selector, null, inputs, type, !hasGetter),
          location);
    } else if (selector.isSetter()) {
      bool hasSetter = compiler.world.hasAnyUserDefinedSetter(selector);
      pushWithPosition(
          new HInvokeDynamicSetter(selector, null, inputs, type, !hasSetter),
          location);
    } else {
      pushWithPosition(
          new HInvokeDynamicMethod(selector, inputs, type, isIntercepted),
          location);
    }
  }

  void pushInvokeStatic(Node location,
                        Element element,
                        List<HInstruction> arguments,
                        [TypeMask type = null]) {
    if (tryInlineMethod(element, null, arguments, location)) {
      return;
    }

    if (type == null) {
      type = TypeMaskFactory.inferredReturnTypeForElement(element, compiler);
    }
    // TODO(5346): Try to avoid the need for calling [declaration] before
    // creating an [HInvokeStatic].
    HInvokeStatic instruction =
        new HInvokeStatic(element.declaration, arguments, type);
    if (!currentInlinedInstantiations.isEmpty) {
      instruction.instantiatedTypes = new List<DartType>.from(
          currentInlinedInstantiations);
    }
    instruction.sideEffects = compiler.world.getSideEffectsOfElement(element);
    if (location == null) {
      push(instruction);
    } else {
      pushWithPosition(instruction, location);
    }
  }

  HInstruction buildInvokeSuper(Selector selector,
                                Element element,
                                List<HInstruction> arguments) {
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
    if (!element.isGetter() && selector.isGetter()) {
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
        isSetter: selector.isSetter() || selector.isIndexSet());
    instruction.sideEffects = compiler.world.getSideEffectsOfElement(element);
    return instruction;
  }

  void handleComplexOperatorSend(SendSet node,
                                 HInstruction receiver,
                                 Link<Node> arguments) {
    HInstruction rhs;
    if (node.isPrefix || node.isPostfix) {
      rhs = graph.addConstantInt(1, compiler);
    } else {
      visit(arguments.head);
      assert(arguments.tail.isEmpty);
      rhs = pop();
    }
    visitBinary(receiver, node.assignmentOperator, rhs,
                elements.getOperatorSelectorInComplexSendSet(node), node);
  }

  visitSendSet(SendSet node) {
    Element element = elements[node];
    if (!Elements.isUnresolved(element) && element.impliesType()) {
      Identifier selector = node.selector;
      generateThrowNoSuchMethod(node, selector.source,
                                argumentNodes: node.arguments);
      return;
    }
    Operator op = node.assignmentOperator;
    if (node.isSuperCall) {
      HInstruction result;
      List<HInstruction> setterInputs = <HInstruction>[];
      if (identical(node.assignmentOperator.source, '=')) {
        addDynamicSendArgumentsToList(node, setterInputs);
        result = setterInputs.last;
      } else {
        Element getter = elements[node.selector];
        List<HInstruction> getterInputs = <HInstruction>[];
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
        handleComplexOperatorSend(node, getterInstruction, arguments);
        setterInputs.add(pop());

        if (node.isPostfix) {
          result = getterInstruction;
        } else {
          result = setterInputs.last;
        }
      }
      Selector setterSelector = elements.getSelector(node);
      if (Elements.isUnresolved(element)
          || !setterSelector.applies(element, compiler)) {
        generateSuperNoSuchMethodSend(
            node, setterSelector, setterInputs);
        pop();
      } else {
        add(buildInvokeSuper(setterSelector, element, setterInputs));
      }
      stack.add(result);
    } else if (node.isIndex) {
      if ("=" == op.source) {
        visitDynamicSend(node);
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

        pushInvokeDynamic(
            node,
            elements.getGetterSelectorInComplexSendSet(node),
            [receiver, index]);
        HInstruction getterInstruction = pop();

        handleComplexOperatorSend(node, getterInstruction, arguments);
        HInstruction value = pop();

        pushInvokeDynamic(
            node, elements.getSelector(node), [receiver, index, value]);
        pop();

        if (node.isPostfix) {
          stack.add(getterInstruction);
        } else {
          stack.add(value);
        }
      }
    } else if ("=" == op.source) {
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
    } else if (identical(op.source, "is")) {
      compiler.internalError("is-operator as SendSet", node: op);
    } else {
      assert("++" == op.source || "--" == op.source ||
             node.assignmentOperator.source.endsWith("="));

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
    stack.add(graph.addConstantInt(node.value, compiler));
  }

  void visitLiteralDouble(LiteralDouble node) {
    stack.add(graph.addConstantDouble(node.value, compiler));
  }

  void visitLiteralBool(LiteralBool node) {
    stack.add(graph.addConstantBool(node.value, compiler));
  }

  void visitLiteralString(LiteralString node) {
    stack.add(graph.addConstantString(node.dartString, node, compiler));
  }

  void visitLiteralSymbol(LiteralSymbol node) {
    stack.add(addConstant(node));
    compiler.enqueuer.codegen.registerConstSymbol(
        node.slowNameString, elements);
  }

  void visitStringJuxtaposition(StringJuxtaposition node) {
    if (!node.isInterpolation) {
      // This is a simple string with no interpolations.
      stack.add(graph.addConstantString(node.dartString, node, compiler));
      return;
    }
    StringBuilderVisitor stringBuilder = new StringBuilderVisitor(this, node);
    stringBuilder.visit(node);
    stack.add(stringBuilder.result);
  }

  void visitLiteralNull(LiteralNull node) {
    stack.add(graph.addConstantNull(compiler));
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

  visitRethrow(Rethrow node) {
    HInstruction exception = rethrowableException;
    if (exception == null) {
      exception = graph.addConstantNull(compiler);
      compiler.internalError(
          'rethrowableException should not be null', node: node);
    }
    handleInTryStatement();
    closeAndGotoExit(new HThrow(exception, isRethrow: true));
  }

  visitReturn(Return node) {
    if (identical(node.getBeginToken().stringValue, 'native')) {
      native.handleSsaNative(this, node.expression);
      return;
    }
    HInstruction value;
    if (node.isRedirectingFactoryBody) {
      FunctionElement element = elements[node.expression].implementation;
      FunctionElement function = currentElement;
      List<HInstruction> inputs = <HInstruction>[];
      FunctionSignature calleeSignature = element.functionSignature;
      FunctionSignature callerSignature = function.functionSignature;
      callerSignature.forEachRequiredParameter((Element element) {
        inputs.add(localsHandler.readLocal(element));
      });
      List<Element> calleeOptionals =
          calleeSignature.orderedOptionalParameters;
      List<Element> callerOptionals =
          callerSignature.orderedOptionalParameters;
      int i = 0;
      for (; i < callerOptionals.length; i++) {
        inputs.add(localsHandler.readLocal(callerOptionals[i]));
      }
      for (; i < calleeOptionals.length; i++) {
        inputs.add(handleConstantForOptionalParameter(calleeOptionals[i]));
      }

      if (backend.classNeedsRti(element.getEnclosingClass())) {
        ClassElement cls = function.getEnclosingClass();
        Link<DartType> typeVariable = cls.typeVariables;
        InterfaceType type = elements.getType(node.expression);
        type.typeArguments.forEach((DartType argument) {
          inputs.add(analyzeTypeArgument(argument));
          typeVariable = typeVariable.tail;
        });
        assert(typeVariable.isEmpty);
      }
      pushInvokeStatic(node, element, inputs);
      value = pop();
    } else if (node.expression == null) {
      value = graph.addConstantNull(compiler);
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
    visitThrowExpression(node.expression);
    if (isReachable) {
      handleInTryStatement();
      push(new HThrowExpression(pop()));
      isReachable = false;
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
        HInstruction initialValue = graph.addConstantNull(compiler);
        localsHandler.updateLocal(elements[definition], initialValue);
      } else {
        assert(definition is SendSet);
        visitSendSet(definition);
        pop();  // Discard value.
      }
    }
  }

  void setRtiIfNeeded(HInstruction object, Node node) {
    InterfaceType type = elements.getType(node);
    if (!backend.classNeedsRti(type.element) || type.treatAsRaw) return;
    List<HInstruction> arguments = <HInstruction>[];
    for (DartType argument in type.typeArguments) {
      arguments.add(analyzeTypeArgument(argument));
    }
    callSetRuntimeTypeInfo(type.element, arguments, object);
    compiler.enqueuer.codegen.registerInstantiatedType(type, elements);
  }

  visitLiteralList(LiteralList node) {
    HInstruction instruction;

    if (node.isConst()) {
      instruction = addConstant(node);
    } else {
      List<HInstruction> inputs = <HInstruction>[];
      for (Link<Node> link = node.elements.nodes;
           !link.isEmpty;
           link = link.tail) {
        visit(link.head);
        inputs.add(pop());
      }
      instruction = buildLiteralList(inputs);
      add(instruction);
      setRtiIfNeeded(instruction, node);
    }

    TypeMask type =
        TypeMaskFactory.inferredForNode(currentElement, node, compiler);
    if (!type.containsAll(compiler)) instruction.instructionType = type;
    stack.add(instruction);
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
   *
   * [isLoopJump] is [:true:] when the jump handler is for a loop. This is used
   * to distinguish the synthetized loop created for a switch statement with
   * continue statements from simple switch statements.
   */
  JumpHandler createJumpHandler(Statement node, {bool isLoopJump}) {
    TargetElement element = elements[node];
    if (element == null || !identical(element.statement, node)) {
      // No breaks or continues to this node.
      return new NullJumpHandler(compiler);
    }
    if (isLoopJump && node is SwitchStatement) {
      // Create a special jump handler for loops created for switch statements
      // with continue statements.
      return new SwitchCaseJumpHandler(this, element, node);
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
      Selector selector = elements.getIteratorSelector(node);
      visit(node.expression);
      HInstruction receiver = pop();
      pushInvokeDynamic(node, selector, [receiver]);
      iterator = pop();
    }
    HInstruction buildCondition() {
      Selector selector = elements.getMoveNextSelector(node);
      pushInvokeDynamic(node, selector, [iterator]);
      return popBoolified();
    }
    void buildBody() {
      Selector call = elements.getCurrentSelector(node);
      pushInvokeDynamic(node, call, [iterator]);

      Node identifier = node.declaredIdentifier;
      Element variable = elements[identifier];
      Selector selector = elements.getSelector(identifier);

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
            location: identifier);
      } else {
        generateNonInstanceSetter(null, variable, value, location: identifier);
      }
      pop(); // Pop the value pushed by the setter call.

      visit(node.body);
    }
    handleLoop(node, buildInitializer, buildCondition, () {}, buildBody);
  }

  visitLabel(Label node) {
    compiler.internalError('SsaBuilder.visitLabel', node: node);
  }

  visitLabeledStatement(LabeledStatement node) {
    Statement body = node.statement;
    if (body is Loop
        || body is SwitchStatement
        || Elements.isUnusedLabel(node, elements)) {
      // Loops and switches handle their own labels.
      visit(body);
      return;
    }
    TargetElement targetElement = elements[body];
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
      stack.add(addConstant(node));
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
    HLiteralList keyValuePairs = buildLiteralList(inputs);
    add(keyValuePairs);
    TypeMask mapType = new TypeMask.nonNullSubtype(backend.mapLiteralClass);
    pushInvokeStatic(node, backend.getMapMaker(), [keyValuePairs], mapType);
    setRtiIfNeeded(peek(), node);
  }

  visitLiteralMapEntry(LiteralMapEntry node) {
    visit(node.value);
    visit(node.key);
  }

  visitNamedArgument(NamedArgument node) {
    visit(node.expression);
  }

  Map<CaseMatch, Constant> buildSwitchCaseConstants(SwitchStatement node) {
    Map<CaseMatch, Constant> constants = new Map<CaseMatch, Constant>();
    for (SwitchCase switchCase in node.cases) {
      for (Node labelOrCase in switchCase.labelsAndCases) {
        if (labelOrCase is CaseMatch) {
          CaseMatch match = labelOrCase;
          Constant constant = getConstantForNode(match.expression);
          constants[labelOrCase] = constant;
        }
      }
    }
    return constants;
  }

  visitSwitchStatement(SwitchStatement node) {
    Map<CaseMatch,Constant> constants = buildSwitchCaseConstants(node);

    // The switch case indices must match those computed in
    // [SwitchCaseJumpHandler].
    bool hasContinue = false;
    Map<SwitchCase, int> caseIndex = new Map<SwitchCase, int>();
    int switchIndex = 1;
    bool hasDefault = false;
    for (SwitchCase switchCase in node.cases) {
      for (Node labelOrCase in switchCase.labelsAndCases) {
        Node label = labelOrCase.asLabel();
        if (label != null) {
          LabelElement labelElement = elements[label];
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
  void buildSimpleSwitchStatement(SwitchStatement node,
                                  Map<CaseMatch, Constant> constants) {
    JumpHandler jumpHandler = createJumpHandler(node, isLoopJump: false);
    HInstruction buildExpression() {
      visit(node.expression);
      return pop();
    }
    Iterable<Constant> getConstants(SwitchCase switchCase) {
      List<Constant> constantList = <Constant>[];
      for (Node labelOrCase in switchCase.labelsAndCases) {
        if (labelOrCase is CaseMatch) {
          constantList.add(constants[labelOrCase]);
        }
      }
      return constantList;
    }
    bool isDefaultCase(SwitchCase switchCase) {
      return switchCase.isDefaultCase;
    }
    void buildSwitchCase(SwitchCase node) {
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
  void buildComplexSwitchStatement(SwitchStatement node,
                                   Map<CaseMatch, Constant> constants,
                                   Map<SwitchCase, int> caseIndex,
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

    TargetElement switchTarget = elements[node];
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
    Iterable<Constant> getConstants(SwitchCase switchCase) {
      List<Constant> constantList = <Constant>[];
      if (switchCase != null) {
        for (Node labelOrCase in switchCase.labelsAndCases) {
          if (labelOrCase is CaseMatch) {
            constantList.add(constants[labelOrCase]);
          }
        }
      }
      return constantList;
    }
    bool isDefaultCase(SwitchCase switchCase) {
      return switchCase == null || switchCase.isDefaultCase;
    }
    void buildSwitchCase(SwitchCase switchCase) {
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
      Iterable<Constant> getConstants(SwitchCase switchCase) {
        return <Constant>[constantSystem.createInt(caseIndex[switchCase])];
      }
      void buildSwitchCase(SwitchCase switchCase) {
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
                   new NullJumpHandler(compiler),
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
        js.Expression code = js.js.parseForeignJS('#');
        push(createForeign(code,
                           backend.boolType,
                           [localsHandler.readLocal(switchTarget)]));
      }
      handleIf(node, buildCondition, buildLoop, () => {});
    }
  }

  /**
   * Creates a switch statement.
   *
   * [jumpHandler] is the [JumpHandler] for the created switch statement.
   * [buildExpression] creates the switch expression.
   * [switchCases] must be either an [Iterable] of [SwitchCase] nodes or
   *   a [Link] or a [NodeList] of [SwitchCase] nodes.
   * [getConstants] returns the set of constants for a switch case.
   * [isDefaultCase] returns [:true:] if the provided switch case should be
   *   considered default for the created switch statement.
   * [buildSwitchCase] creates the statements for the switch case.
   */
  void handleSwitch(Node errorNode,
                    JumpHandler jumpHandler,
                    HInstruction buildExpression(),
                    var switchCases,
                    Iterable<Constant> getConstants(SwitchCase switchCase),
                    bool isDefaultCase(SwitchCase switchCase),
                    void buildSwitchCase(SwitchCase switchCase)) {
    Map<CaseMatch, Constant> constants = new Map<CaseMatch, Constant>();

    HBasicBlock expressionStart = openNewBlock();
    HInstruction expression = buildExpression();
    if (switchCases.isEmpty) {
      return;
    }

    HSwitch switchInstruction = new HSwitch(<HInstruction>[expression]);
    HBasicBlock expressionEnd = close(switchInstruction);
    LocalsHandler savedLocals = localsHandler;

    List<List<Constant>> matchExpressions = <List<Constant>>[];
    List<HStatementInformation> statements = <HStatementInformation>[];
    bool hasDefault = false;
    Element getFallThroughErrorElement = backend.getFallThroughError();
    HasNextIterator<Node> caseIterator =
        new HasNextIterator<Node>(switchCases.iterator);
    while (caseIterator.hasNext) {
      SwitchCase switchCase = caseIterator.next();
      List<Constant> caseConstants = <Constant>[];
      HBasicBlock block = graph.addNewBlock();
      for (Constant constant in getConstants(switchCase)) {
        caseConstants.add(constant);
        HConstant hConstant = graph.addConstant(constant, compiler);
        switchInstruction.inputs.add(hConstant);
        hConstant.usedBy.add(switchInstruction);
        expressionEnd.addSuccessor(block);
      }
      matchExpressions.add(caseConstants);

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
          closeAndGotoExit(new HThrow(error));
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
      matchExpressions.add(<Constant>[]);
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
                                    matchExpressions,
                                    statements,
                                    jumpHandler.target,
                                    jumpHandler.labels()),
        joinBlock);

    jumpHandler.close();
  }

  Element lookupOperator(ClassElement classElement, String operatorName) {
    String dartMethodName =
        Elements.constructOperatorName(operatorName, false);
    return classElement.lookupMember(dartMethodName);
  }

  visitSwitchCase(SwitchCase node) {
    compiler.internalError('SsaBuilder.visitSwitchCase');
  }

  visitCaseMatch(CaseMatch node) {
    compiler.internalError('SsaBuilder.visitCaseMatch');
  }

  visitTryStatement(TryStatement node) {
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
      // TODO(kasperl): Bad smell. We shouldn't be constructing elements here.
      // Note that the name of this element is irrelevant.
      Element element = new ElementX('exception',
                                     ElementKind.PARAMETER,
                                     currentElement);
      exception = new HLocalValue(element, backend.nonNullType);
      add(exception);
      HInstruction oldRethrowableException = rethrowableException;
      rethrowableException = exception;

      pushInvokeStatic(node, backend.getExceptionUnwrapper(), [exception]);
      HInvokeStatic unwrappedException = pop();
      tryInstruction.exception = exception;
      Link<Node> link = node.catchBlocks.nodes;

      void pushCondition(CatchBlock catchBlock) {
        if (catchBlock.onKeyword != null) {
          DartType type = elements.getType(catchBlock.type);
          if (type == null) {
            compiler.internalError('On with no type', node: catchBlock.type);
          }
          HInstruction condition =
              buildIsNode(catchBlock.type, type, unwrappedException);
          push(condition);
        } else {
          VariableDefinitions declaration = catchBlock.formals.nodes.head;
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
              compiler.cancel('Catch with unresolved type', node: catchBlock);
            }
            condition = buildIsNode(declaration.type, type, unwrappedException);
            push(condition);
          }
        }
      }

      void visitThen() {
        CatchBlock catchBlock = link.head;
        link = link.tail;
        if (catchBlock.exception != null) {
          localsHandler.updateLocal(elements[catchBlock.exception],
                                    unwrappedException);
        }
        Node trace = catchBlock.trace;
        if (trace != null) {
          pushInvokeStatic(trace, backend.getTraceFromException(), [exception]);
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
      expression = new HStringify(expression, node, builder.backend.stringType);
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
    HInstruction instruction = new HStringConcat(
        left, right, diagnosticNode, builder.backend.stringType);
    builder.add(instruction);
    return instruction;
  }
}

/**
 * This class visits the method that is a candidate for inlining and
 * finds whether it is too difficult to inline.
 */
class InlineWeeder extends Visitor {
  // Invariant: *INSIDE_LOOP* > *OUTSIDE_LOOP*
  static const INLINING_NODES_OUTSIDE_LOOP = 18;
  static const INLINING_NODES_OUTSIDE_LOOP_ARG_FACTOR = 3;
  static const INLINING_NODES_INSIDE_LOOP = 42;
  static const INLINING_NODES_INSIDE_LOOP_ARG_FACTOR = 4;

  bool seenReturn = false;
  bool tooDifficult = false;
  int nodeCount = 0;
  final int maxInliningNodes;

  InlineWeeder(this.maxInliningNodes);

  static bool canBeInlined(FunctionExpression functionExpression,
                           int maxInliningNodes) {
    InlineWeeder weeder = new InlineWeeder(maxInliningNodes);
    weeder.visit(functionExpression.initializers);
    weeder.visit(functionExpression.body);
    return !weeder.tooDifficult;
  }

  bool registerNode() {
    if (nodeCount++ > maxInliningNodes) {
      tooDifficult = true;
      return false;
    } else {
      return true;
    }
  }

  void visit(Node node) {
    if (node != null) node.accept(this);
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
    node.visitChildren(this);
  }

  visitLoop(Node node) {
    // It's actually not difficult to inline a method with a loop, but
    // our measurements show that it's currently better to not inline a
    // method that contains a loop.
    tooDifficult = true;
  }

  void visitRethrow(Rethrow node) {
    if (!registerNode()) return;
    tooDifficult = true;
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
    // For now, we don't want to handle throw after a return even if
    // it is in an "if".
    if (seenReturn) tooDifficult = true;
  }
}

class InliningState {
  /**
   * Documentation wanted -- johnniwinther
   *
   * Invariant: [function] must be an implementation element.
   */
  final FunctionElement function;
  final Element oldReturnElement;
  final DartType oldReturnType;
  final TreeElements oldElements;
  final List<HInstruction> oldStack;
  final LocalsHandler oldLocalsHandler;
  final bool inTryStatement;

  InliningState(this.function,
                this.oldReturnElement,
                this.oldReturnType,
                this.oldElements,
                this.oldStack,
                this.oldLocalsHandler,
                this.inTryStatement) {
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
      JavaScriptBackend backend = builder.backend;
      HPhi phi = new HPhi.manyInputs(
          null, <HInstruction>[thenValue, elseValue], backend.dynamicType);
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
