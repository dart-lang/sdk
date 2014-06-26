// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of ssa;

/**
 * A special element for the extra parameter taken by intercepted
 * methods. We need to implement [TypedElement.type] because our
 * optimizers may look at its declared type.
 */
class InterceptedElement extends ElementX implements TypedElement {
  final DartType type;
  InterceptedElement(this.type, String name, Element enclosing)
      : super(name, ElementKind.PARAMETER, enclosing);

  DartType computeType(Compiler compiler) => type;

  accept(ElementVisitor visitor) => visitor.visitInterceptedElement(this);
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
        SsaBuilder builder =
            new SsaBuilder(backend, work, emitter.nativeEmitter);
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
          if (element.isInstanceMember) {
            assert(compiler.enableTypeAssertions);
            graph = builder.buildCheckedSetter(element);
          } else {
            graph = builder.buildLazyInitializer(element);
          }
        } else {
          compiler.internalError(element, 'Unexpected element kind $kind.');
        }
        assert(graph.isValid());
        if (!identical(kind, ElementKind.FIELD)) {
          FunctionElement function = element;
          FunctionSignature signature = function.functionSignature;
          signature.forEachOptionalParameter((Element parameter) {
            // This ensures the default value will be computed.
            Constant constant =
                backend.constants.getConstantForVariable(parameter);
            CodegenRegistry registry = work.registry;
            registry.registerCompileTimeConstant(constant);
          });
        }
        if (compiler.tracer.isEnabled) {
          String name;
          if (element.isMember) {
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

  /// The class that defines the current type environment or null if no type
  /// variables are in scope.
  final ClassElement contextClass;

  LocalsHandler(this.builder, this.contextClass)
      : redirectionMapping = new Map<Element, Element>(),
        directLocals = new Map<Element, HInstruction>();

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
    return type;
  }

  get typesTask => builder.compiler.typesTask;

  /**
   * Creates a new [LocalsHandler] based on [other]. We only need to
   * copy the [directLocals], since the other fields can be shared
   * throughout the AST visit.
   */
  LocalsHandler.from(LocalsHandler other)
      : directLocals = new Map<Element, HInstruction>.from(other.directLocals),
        redirectionMapping = other.redirectionMapping,
        contextClass = other.contextClass,
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
    HInstruction box = new HForeign(js.js.parseForeignJS('{}'),
                                    backend.nonNullType,
                                    <HInstruction>[]);
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
    scopeData.capturedVariableMapping.forEach((Element from, Element to) {
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
  void startFunction(Element element, ast.Node node) {
    assert(invariant(element, element.isImplementation));
    Compiler compiler = builder.compiler;
    closureData = compiler.closureToClassMapper.computeClosureToClassMapping(
            element, node, builder.elements);

    if (element is FunctionElement) {
      FunctionElement functionElement = element;
      FunctionSignature params = functionElement.functionSignature;
      params.orderedForEachParameter((Element parameterElement) {
        if (element.isGenerativeConstructorBody) {
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
    if (closureData.isClosure) {
      // Inside closure redirect references to itself to [:this:].
      HThis thisInstruction = new HThis(closureData.thisElement,
                                        backend.nonNullType);
      builder.graph.thisInstruction = thisInstruction;
      builder.graph.entry.addAtEntry(thisInstruction);
      updateLocal(closureData.closureElement, thisInstruction);
    } else if (element.isInstanceMember) {
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
    ClassElement cls = element.enclosingClass;

    // When the class extends a native class, the instance is pre-constructed
    // and passed to the generative constructor factory function as a parameter.
    // Instead of allocating and initializing the object, the constructor
    // 'upgrades' the native subclass object by initializing the Dart fields.
    bool isNativeUpgradeFactory = element.isGenerativeConstructor
        && Elements.isNativeOrExtendsNative(cls);
    if (backend.isInterceptedMethod(element)) {
      bool isInterceptorClass = backend.isInterceptorClass(cls.declaration);
      String name = isInterceptorClass ? 'receiver' : '_';
      Element parameter = new InterceptedElement(
          cls.thisType, name, element);
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
          cls.thisType, 'receiver', element);
      // Unlike `this`, receiver is nullable since direct calls to generative
      // constructor call the constructor with `null`.
      HParameterValue value =
          new HParameterValue(parameter, new TypeMask.exact(cls));
      builder.graph.explicitReceiverParameter = value;
      builder.graph.entry.addAtEntry(value);
    }
  }

  /**
   * Returns true if the local can be accessed directly. Boxed variables or
   * captured variables that are stored in the closure-field return [:false:].
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
    if (redirectTarget.isMember) {
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
        if (element.isTypeVariable) {
          builder.compiler.internalError(builder.compiler.currentElement,
              "Runtime type information not available for $element.");
        } else {
          builder.compiler.internalError(element,
              "Cannot find value $element.");
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
    if (element.isParameter) return builder.parameters[element];

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
      if (element != closureData.thisElement
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
    compiler.internalError(CURRENT_ELEMENT_SPANNABLE,
        'NullJumpHandler.generateBreak should not be called.');
  }

  void generateContinue([LabelElement label]) {
    compiler.internalError(CURRENT_ELEMENT_SPANNABLE,
        'NullJumpHandler.generateContinue should not be called.');
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

  bool isContinueToSwitchCase(LabelElement label) {
    return label != null && targetIndexMap.containsKey(label.target);
  }

  void generateContinue([LabelElement label]) {
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
    for (TargetElement target in targetIndexMap.keys) {
      builder.jumpTargets.remove(target);
    }
    super.close();
  }
}

/**
 * This class builds SSA nodes for functions represented in AST.
 */
class SsaBuilder extends ResolvedVisitor {
  final JavaScriptBackend backend;
  final ConstantSystem constantSystem;
  final CodegenWorkItem work;
  final RuntimeTypes rti;

  /* This field is used by the native handler. */
  final NativeEmitter nativeEmitter;

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

  Map<Element, HInstruction> parameters = <Element, HInstruction>{};

  Map<TargetElement, JumpHandler> jumpTargets = <TargetElement, JumpHandler>{};

  /**
   * Variables stored in the current activation. These variables are
   * being updated in try/catch blocks, and should be
   * accessed indirectly through [HLocalGet] and [HLocalSet].
   */
  Map<Element, HLocalValue> activationVariables = <Element, HLocalValue>{};

  // We build the Ssa graph by simulating a stack machine.
  List<HInstruction> stack = <HInstruction>[];

  SsaBuilder(JavaScriptBackend backend,
             CodegenWorkItem work,
             this.nativeEmitter)
    : this.backend = backend,
      this.constantSystem = backend.constantSystem,
      this.work = work,
      this.rti = backend.rti,
      super(work.resolutionTree, backend.compiler) {
    localsHandler = new LocalsHandler(this, work.element.contextClass);
    sourceElementStack.add(work.element);
  }

  CodegenRegistry get registry => work.registry;

  Element get sourceElement => sourceElementStack.last;

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

  SourceFile currentSourceFile() {
    return sourceElement.implementation.compilationUnit.script.file;
  }

  void checkValidSourceFileLocation(
      SourceFileLocation location, SourceFile sourceFile, int offset) {
    if (!location.isValid()) {
      throw MessageKind.INVALID_SOURCE_FILE_LOCATION.message(
          {'offset': offset,
           'fileName': sourceFile.filename,
           'length': sourceFile.length});
    }
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
    // have been included if necessary, see [addStaticSendArgumentsToList].
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
    assert(selector.applies(function, compiler));
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
      List<String> selectorArgumentNames = selector.getOrderedNamedArguments();
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
                       List<HInstruction> providedArguments,
                       ast.Node currentNode) {
    // TODO(johnniwinther): Register this on the [registry]. Currently the
    // [CodegenRegistry] calls the enqueuer, but [element] should _not_ be
    // enqueued.
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
      // Don't inline from one output unit to another. If something is deferred
      // it is to save space in the loading code.
      if (!compiler.deferredLoadTask
          .inSameOutputUnit(element,compiler.currentElement)) {
        return false;
      }
      if (compiler.disableInlining) return false;

      assert(selector != null
             || Elements.isStaticOrTopLevel(element)
             || element.isGenerativeConstructorBody);
      if (selector != null && !selector.applies(function, compiler)) {
        return false;
      }

      // Don't inline operator== methods if the parameter can be null.
      if (element.name == '==') {
        if (element.enclosingClass != compiler.objectClass
            && providedArguments[1].canBeNull()) {
          return false;
        }
      }

      // Generative constructors of native classes should not be called directly
      // and have an extra argument that causes problems with inlining.
      if (element.isGenerativeConstructor
          && Elements.isNativeOrExtendsNative(element.enclosingClass)) {
        return false;
      }

      // A generative constructor body is not seen by global analysis,
      // so we should not query for its type.
      if (!element.isGenerativeConstructorBody) {
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

    bool heuristicSayGoodToGo() {
      // Don't inline recursivly
      if (inliningStack.any((entry) => entry.function == function)) {
        return false;
      }

      if (inExpressionOfThrow) return false;

      if (element.isSynthesized) return true;

      if (cachedCanBeInlined == true) return cachedCanBeInlined;

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
      TypesInferrer inferrer = compiler.typesTask.typesInferrer;
      if (inferrer.isCalledOnce(element)
          && (inliningStack.every(
                  (entry) => inferrer.isCalledOnce(entry.function)))) {
        useMaxInliningNodes = false;
      }
      bool canInline;
      ast.FunctionExpression functionNode = function.node;
      canInline = InlineWeeder.canBeInlined(
          functionNode, maxInliningNodes, useMaxInliningNodes);
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
      if (element.isInstanceMember
          && !element.isGenerativeConstructorBody
          && (selector.mask == null || selector.mask.isNullable)) {
        addWithPosition(
            new HFieldGet(null, providedArguments[0], backend.dynamicType,
                          isAssignable: false),
            currentNode);
      }
      List<HInstruction> compiledArguments = completeSendArgumentsList(
          function, selector, providedArguments, currentNode);
      enterInlinedMethod(function, currentNode, compiledArguments);
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
      return true;
    }

    return false;
  }

  inlinedFrom(Element element, f()) {
    assert(element is FunctionElement || element is VariableElement);
    return compiler.withCurrentElement(element, () {
      // The [sourceElementStack] contains declaration elements.
      sourceElementStack.add(element.declaration);
      var result = f();
      sourceElementStack.removeLast();
      return result;
    });
  }

  HInstruction handleConstantForOptionalParameter(Element parameter) {
    Constant constant =
        backend.constants.getConstantForVariable(parameter);
    assert(invariant(parameter, constant != null,
        message: 'No constant computed for $parameter'));
    return graph.addConstant(constant, compiler);
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

  /**
   * Returns whether this builder is building code for [element].
   */
  bool isBuildingFor(Element element) {
    return work.element == element;
  }

  /// A stack of [DartType]s the have been seen during inlining of factory
  /// constructors.  These types are preserved in [HInvokeStatic]s and
  /// [HForeignNews] inside the inline code and registered during code
  /// generation for these nodes.
  // TODO(karlklose): consider removing this and keeping the (substituted)
  // types of the type variables in an environment (like the [LocalsHandler]).
  final List<DartType> currentInlinedInstantiations = <DartType>[];

  final List<AstInliningState> inliningStack = <AstInliningState>[];

  Element returnElement;
  DartType returnType;

  bool inTryStatement = false;

  Constant getConstantForNode(ast.Node node) {
    Constant constant =
        backend.constants.getConstantForNode(node, elements);
    assert(invariant(node, constant != null,
        message: 'No constant computed for $node'));
    return constant;
  }

  HInstruction addConstant(ast.Node node) {
    return graph.addConstant(getConstantForNode(node), compiler);
  }

  bool isLazilyInitialized(VariableElement element) {
    Constant initialValue =
        backend.constants.getConstantForVariable(element);
    return initialValue == null;
  }

  TypeMask cachedTypeOfThis;

  TypeMask getTypeOfThis() {
    TypeMask result = cachedTypeOfThis;
    if (result == null) {
      Element element = localsHandler.closureData.thisElement;
      ClassElement cls = element.enclosingElement.enclosingClass;
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
    assert(!function.modifiers.isExternal);
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
    HInstruction value =
        potentiallyCheckType(parameter, field.type);
    add(new HFieldSet(field, thisInstruction, value));
    return closeFunction();
  }

  HGraph buildLazyInitializer(VariableElement variable) {
    ast.Node node = variable.node;
    openFunction(variable, node);
    assert(variable.initializer != null);
    visit(variable.initializer);
    HInstruction value = pop();
    value = potentiallyCheckType(value, variable.type);
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
   * This method sets up the local state of the builder for inlining [function].
   * The arguments of the function are inserted into the [localsHandler].
   *
   * When inlining a function, [:return:] statements are not emitted as
   * [HReturn] instructions. Instead, the value of a synthetic element is
   * updated in the [localsHandler]. This function creates such an element and
   * stores it in the [returnElement] field.
   */
  void setupStateForInlining(FunctionElement function,
                             List<HInstruction> compiledArguments) {
    localsHandler = new LocalsHandler(this, function.contextClass);
    localsHandler.closureData =
        compiler.closureToClassMapper.computeClosureToClassMapping(
            function, function.node, elements);
    // TODO(kasperl): Bad smell. We shouldn't be constructing elements here.
    returnElement = new VariableElementX.synthetic("result",
        ElementKind.VARIABLE, function);
    localsHandler.updateLocal(returnElement,
        graph.addConstantNull(compiler));

    inTryStatement = false; // TODO(lry): why? Document.

    int argumentIndex = 0;
    if (function.isInstanceMember) {
      localsHandler.updateLocal(localsHandler.closureData.thisElement,
          compiledArguments[argumentIndex++]);
    }

    FunctionSignature signature = function.functionSignature;
    signature.orderedForEachParameter((Element parameter) {
      HInstruction argument = compiledArguments[argumentIndex++];
      localsHandler.updateLocal(parameter, argument);
    });

    ClassElement enclosing = function.enclosingClass;
    if ((function.isConstructor || function.isGenerativeConstructorBody)
        && backend.classNeedsRti(enclosing)) {
      enclosing.typeVariables.forEach((TypeVariableType typeVariable) {
        HInstruction argument = compiledArguments[argumentIndex++];
        localsHandler.updateLocal(typeVariable.element, argument);
      });
    }
    assert(argumentIndex == compiledArguments.length);

    elements = function.resolvedAst.elements;
    assert(elements != null);
    returnType = signature.type.returnType;
    stack = <HInstruction>[];

    insertTraceCall(function);
  }

  void restoreState(AstInliningState state) {
    localsHandler = state.oldLocalsHandler;
    returnElement = state.oldReturnElement;
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
    if (!compiler.enableTypeAssertions) return;

    FunctionSignature signature = function.functionSignature;
    signature.orderedForEachParameter((ParameterElement parameter) {
      HInstruction argument = localsHandler.readLocal(parameter);
      potentiallyCheckType(argument, parameter.type);
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
      if (callee.enclosingClass != caller.enclosingClass) {
        inlinedFrom(callee, () {
          buildFieldInitializers(callee.enclosingElement.implementation,
                               fieldValues);
        });
      }

      int index = 0;
      FunctionSignature params = callee.functionSignature;
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
      HInstruction compileArgument(Element element) {
        return localsHandler.readLocal(element);
      }

      Element target = constructor.definingConstructor.implementation;
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
          Selector selector = elements.getSelector(call);
          Link<ast.Node> arguments = call.arguments;
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
      if (!enclosingClass.isObject(compiler)) {
        assert(superClass != null);
        assert(superClass.resolutionState == STATE_DONE);
        Selector selector =
            new Selector.callDefaultConstructor(enclosingClass.library);
        // TODO(johnniwinther): Should we find injected constructors as well?
        FunctionElement target = superClass.lookupConstructor(selector);
        if (target == null) {
          compiler.internalError(superClass,
              "No default constructor available.");
        }
        List<HInstruction> arguments = <HInstruction>[];
        selector.addArgumentsToList(const Link<ast.Node>(),
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
        (ClassElement enclosingClass, VariableElement member) {
          compiler.withCurrentElement(member, () {
            TreeElements definitions = member.treeElements;
            ast.Node node = member.node;
            ast.Expression initializer = member.initializer;
            if (initializer == null) {
              // Unassigned fields of native classes are not initialized to
              // prevent overwriting pre-initialized native properties.
              if (!Elements.isNativeOrExtendsNative(classElement)) {
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
  HGraph buildFactory(FunctionElement functionElement) {
    functionElement = functionElement.implementation;
    ClassElement classElement =
        functionElement.enclosingClass.implementation;
    bool isNativeUpgradeFactory =
        Elements.isNativeOrExtendsNative(classElement);
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
    // super fields.
    buildFieldInitializers(classElement, fieldValues);

    // Compile field-parameters such as [:this.x:].
    FunctionSignature params = functionElement.functionSignature;
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
        (ClassElement enclosingClass, VariableElement member) {
          HInstruction value = fieldValues[member];
          if (value == null) {
            // Uninitialized native fields are pre-initialized by the native
            // implementation.
            assert(isNativeUpgradeFactory);
          } else {
            fields.add(member);
            DartType type = localsHandler.substInContext(member.type);
            constructorArguments.add(potentiallyCheckType(value, type));
          }
        },
        includeSuperAndInjectedMembers: true);

    InterfaceType type = classElement.thisType;
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
      // Read the values of the type arguments and create a list to set on the
      // newly create object.  We can identify the case where the new list
      // would be of the form:
      //  [getTypeArgumentByIndex(this, 0), .., getTypeArgumentByIndex(this, k)]
      // and k is the number of type arguments of this.  If this is the case,
      // we can simply copy the list from this.

      // These locals are modified by [isIndexedTypeArgumentGet].
      HInstruction source;  // The source of the type arguments.
      bool allIndexed = true;
      int expectedIndex = 0;
      ClassElement contextClass;  // The class of `this`.
      Link typeVariables;  // The list of 'remaining type variables' of `this`.

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
        if (invoke.element != backend.getGetTypeArgumentByIndex()) {
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
          typeVariables = contextClass.typeVariables;
        } else {
          assert(source == newSource);
        }
        // If there are no more type variables, then there are more type
        // arguments for the new object than the source has, and it can't be
        // a copy.  Otherwise remove one argument.
        if (typeVariables.isEmpty) return false;
        typeVariables = typeVariables.tail;
        // Check that the index is the one we expect.
        IntConstant constant = index.constant;
        return constant.value == expectedIndex++;
      }

      List<HInstruction> typeArguments = <HInstruction>[];
      classElement.typeVariables.forEach((TypeVariableType typeVariable) {
        HInstruction argument = localsHandler.readLocal(typeVariable.element);
        if (allIndexed && !isIndexedTypeArgumentGet(argument)) {
          allIndexed = false;
        }
        typeArguments.add(argument);
      });

      if (source != null && allIndexed && typeVariables.isEmpty) {
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
          Constant constant = new InterceptorConstant(classElement.thisType);
          interceptor = graph.addConstant(constant, compiler);
        }
        bodyCallInputs.add(interceptor);
      }
      bodyCallInputs.add(newObject);
      ResolvedAst resolvedAst = constructor.resolvedAst;
      TreeElements elements = resolvedAst.elements;
      ast.Node node = resolvedAst.node;
      ClosureClassMap parameterClosureData =
          compiler.closureToClassMapper.getMappingForNestedFunction(node);

      FunctionSignature functionSignature = body.functionSignature;
      // Provide the parameters to the generative constructor body.
      functionSignature.orderedForEachParameter((parameter) {
        // If [parameter] is boxed, it will be a field in the box passed as the
        // last parameter. So no need to directly pass it.
        if (!localsHandler.isBoxed(parameter)) {
          bodyCallInputs.add(localsHandler.readLocal(parameter));
        }
      });

      ClassElement currentClass = constructor.enclosingClass;
      if (backend.classNeedsRti(currentClass)) {
        // If [currentClass] needs RTI, we add the type variables as
        // parameters of the generative constructor body.
        currentClass.typeVariables.forEach((DartType argument) {
          // TODO(johnniwinther): Substitute [argument] with
          // `localsHandler.substInContext(argument)`.
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
        localsHandler.directLocals[typeVariable.element] = param;
      });
    }

    if (element is FunctionElement) {
      FunctionElement functionElement = element;
      FunctionSignature signature = functionElement.functionSignature;

      // Put the type checks in the first successor of the entry,
      // because that is where the type guards will also be inserted.
      // This way we ensure that a type guard will dominate the type
      // check.
      signature.orderedForEachParameter((ParameterElement parameterElement) {
        if (element.isGenerativeConstructorBody) {
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
            parameterElement.type);
        localsHandler.directLocals[parameterElement] = newParameter;
      });

      returnType = signature.type.returnType;
    } else {
      // Otherwise it is a lazy initializer which does not have parameters.
      assert(element is VariableElement);
    }

    insertTraceCall(element);
  }

  insertTraceCall(Element element) {
    if (JavaScriptBackend.TRACE_CALLS) {
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
    type = type.unalias(compiler);
    assert(assertTypeInContext(type, original));
    if (type.isInterfaceType && !type.treatAsRaw) {
      TypeMask subtype = new TypeMask.subtype(type.element);
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

      List arguments = [buildFunctionType(type), original];
      pushInvokeDynamic(
          null,
          new Selector.call(name, backend.jsHelperLibrary, 1),
          arguments);

      return new HTypeConversion(type, kind, original.instructionType, pop());
    } else {
      return original.convertType(compiler, type, kind);
    }
  }

  HInstruction potentiallyCheckType(HInstruction original, DartType type,
      { int kind: HTypeConversion.CHECKED_MODE_CHECK }) {
    if (!compiler.enableTypeAssertions) return original;
    type = localsHandler.substInContext(type);
    HInstruction other = buildTypeConversion(original, type, kind);
    if (other != original) add(other);
    registry.registerIsCheck(type);
    return other;
  }

  void assertIsSubtype(ast.Node node, DartType subtype, DartType supertype,
                       String message) {
    HInstruction subtypeInstruction =
        analyzeTypeArgument(localsHandler.substInContext(subtype));
    HInstruction supertypeInstruction =
        analyzeTypeArgument(localsHandler.substInContext(supertype));
    HInstruction messageInstruction =
        graph.addConstantString(new ast.DartString.literal(message), compiler);
    Element element = backend.getAssertIsSubtype();
    var inputs = <HInstruction>[subtypeInstruction, supertypeInstruction,
                                messageInstruction];
    HInstruction assertIsSubtype = new HInvokeStatic(
        element, inputs, subtypeInstruction.instructionType);
    registry.registerTypeVariableBoundsSubtypeCheck(subtype, supertype);
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
    if (compiler.enableTypeAssertions) {
      return potentiallyCheckType(
          value,
          compiler.boolClass.rawType,
          kind: HTypeConversion.BOOLEAN_CONVERSION_CHECK);
    }
    HInstruction result = new HBoolify(value, backend.boolType);
    add(result);
    return result;
  }

  HInstruction attachPosition(HInstruction target, ast.Node node) {
    if (node != null) {
      target.sourcePosition = sourceFileLocationForBeginToken(node);
    }
    return target;
  }

  SourceFileLocation sourceFileLocationForBeginToken(ast.Node node) =>
      sourceFileLocationForToken(node, node.getBeginToken());

  SourceFileLocation sourceFileLocationForEndToken(ast.Node node) =>
      sourceFileLocationForToken(node, node.getEndToken());

  SourceFileLocation sourceFileLocationForToken(ast.Node node, Token token) {
    SourceFile sourceFile = currentSourceFile();
    SourceFileLocation location =
        new TokenSourceFileLocation(sourceFile, token, sourceElement.name);
    checkValidSourceFileLocation(location, sourceFile, token.charOffset);
    return location;
  }

  void visit(ast.Node node) {
    if (node != null) node.accept(this);
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
          compiler.internalError(node, 'Non-empty instruction stack.');
        }
        return;
      }
    }
    assert(!current.isClosed());
    if (!stack.isEmpty) {
      compiler.internalError(node, 'Non-empty instruction stack.');
    }
  }

  visitClassNode(ast.ClassNode node) {
    compiler.internalError(node,
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

  visitFor(ast.For node) {
    assert(isReachable);
    assert(node.body != null);
    void buildInitializer() {
      if (node.initializer == null) return;
      ast.Node initializer = node.initializer;
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
      for (ast.Expression expression in node.update) {
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

  visitFunctionExpression(ast.FunctionExpression node) {
    ClosureClassMap nestedClosureData =
        compiler.closureToClassMapper.getMappingForNestedFunction(node);
    assert(nestedClosureData != null);
    assert(nestedClosureData.closureClassElement != null);
    ClassElement closureClassElement =
        nestedClosureData.closureClassElement;
    FunctionElement callElement = nestedClosureData.callElement;
    // TODO(ahe): This should be registered in codegen, not here.
    // TODO(johnniwinther): Is [registerStaticUse] equivalent to
    // [addToWorkList]?
    registry.registerStaticUse(callElement);
    // TODO(ahe): This should be registered in codegen, not here.
    registry.registerInstantiatedClass(closureClassElement);

    List<HInstruction> capturedVariables = <HInstruction>[];
    closureClassElement.forEachMember((_, Element member) {
      // The backendMembers also contains the call method(s). We are only
      // interested in the fields.
      if (member.isField) {
        Element capturedLocal = nestedClosureData.capturedFieldMapping[member];
        assert(capturedLocal != null);
        capturedVariables.add(localsHandler.readLocal(capturedLocal));
      }
    });

    TypeMask type = new TypeMask.nonNullExact(compiler.functionClass);
    push(new HForeignNew(closureClassElement, type, capturedVariables));

    Element methodElement = nestedClosureData.closureElement;
    if (compiler.backend.methodNeedsRti(methodElement)) {
      registry.registerGenericClosure(methodElement);
    }
  }

  visitFunctionDeclaration(ast.FunctionDeclaration node) {
    assert(isReachable);
    visit(node.function);
    localsHandler.updateLocal(elements[node], pop());
  }

  visitIdentifier(ast.Identifier node) {
    if (node.isThis()) {
      stack.add(localsHandler.readThis());
    } else {
      compiler.internalError(node,
          "SsaFromAstMixin.visitIdentifier on non-this.");
    }
  }

  visitIf(ast.If node) {
    assert(isReachable);
    handleIf(node,
             () => visit(node.condition),
             () => visit(node.thenPart),
             node.elsePart != null ? () => visit(node.elsePart) : null);
  }

  void handleIf(ast.Node diagnosticNode,
                void visitCondition(), void visitThen(), void visitElse()) {
    SsaBranchBuilder branchBuilder = new SsaBranchBuilder(this, diagnosticNode);
    branchBuilder.handleIf(visitCondition, visitThen, visitElse);
  }

  void visitLogicalAndOr(ast.Send node, ast.Operator op) {
    SsaBranchBuilder branchBuilder = new SsaBranchBuilder(this, node);
    branchBuilder.handleLogicalAndOrWithLeftNode(
        node.receiver,
        () { visit(node.argumentsNode); },
        isAnd: ("&&" == op.source));
  }

  void visitLogicalNot(ast.Send node) {
    assert(node.argumentsNode is ast.Prefix);
    visit(node.receiver);
    HNot not = new HNot(popBoolified(), backend.boolType);
    pushWithPosition(not, node);
  }

  void visitUnary(ast.Send node, ast.Operator op) {
    assert(node.argumentsNode is ast.Prefix);
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
                   ast.Operator op,
                   HInstruction right,
                   Selector selector,
                   ast.Send send) {
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

  HInstruction generateInstanceSendReceiver(ast.Send send) {
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
  void generateInstanceGetterWithCompiledReceiver(ast.Send send,
                                                  Selector selector,
                                                  HInstruction receiver) {
    assert(Elements.isInstanceSend(send, elements));
    assert(selector.isGetter);
    pushInvokeDynamic(send, selector, [receiver]);
  }

  /// Inserts a call to checkDeferredIsLoaded if the send has a prefix that
  /// resolves to a deferred library.
  void generateIsDeferredLoadedCheckIfNeeded(ast.Send node) {
    DeferredLoadTask deferredTask = compiler.deferredLoadTask;
    PrefixElement prefixElement =
         deferredTask.deferredPrefixElement(node, elements);
    if (prefixElement != null) {
      String loadId =
          deferredTask.importDeferName[prefixElement.deferredImport];
      HInstruction loadIdConstant = addConstantString(loadId);
      String uri = prefixElement.deferredImport.uri.dartString.slowToString();
      HInstruction uriConstant = addConstantString(uri);
      Element helper = backend.getCheckDeferredIsLoaded();
      pushInvokeStatic(node, helper, [loadIdConstant, uriConstant]);
      pop();
    }
  }

  void generateGetter(ast.Send send, Element element) {
    if (element != null && element.isForeign(compiler)) {
      visitForeignGetter(send);
    } else if (Elements.isStaticOrTopLevelField(element)) {
      Constant value;
      if (element.isField && !element.isAssignable) {
        // A static final or const. Get its constant value and inline it if
        // the value can be compiled eagerly.
        value = backend.constants.getConstantForVariable(element);
      }
      if (value != null) {
        HConstant instruction;
        // Constants that are referred via a deferred prefix should be referred
        // by reference.
        PrefixElement prefix = compiler.deferredLoadTask
            .deferredPrefixElement(send, elements);
        if (prefix != null) {
          instruction = graph.addDeferredConstant(value, prefix, compiler);
        } else {
          instruction = graph.addConstant(value, compiler);
        }
        stack.add(instruction);
        // The inferrer may have found a better type than the constant
        // handler in the case of lists, because the constant handler
        // does not look at elements in the list.
        TypeMask type =
            TypeMaskFactory.inferredTypeForElement(element, compiler);
        if (!type.containsAll(compiler) && !instruction.isConstantNull()) {
          // TODO(13429): The inferrer should know that an element
          // cannot be null.
          instruction.instructionType = type.nonNullable();
        }
      } else if (element.isField && isLazilyInitialized(element)) {
        HInstruction instruction = new HLazyStatic(
            element,
            TypeMaskFactory.inferredTypeForElement(element, compiler));
        push(instruction);
      } else {
        if (element.isGetter) {
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
      registry.registerGetOfStaticFunction(element.declaration);
    } else if (Elements.isErroneousElement(element)) {
      // An erroneous element indicates an unresolved static getter.
      generateThrowNoSuchMethod(send,
                                getTargetName(element, 'get'),
                                argumentNodes: const Link<ast.Node>());
    } else {
      stack.add(localsHandler.readLocal(element));
    }
  }

  void generateInstanceSetterWithCompiledReceiver(ast.Send send,
                                                  HInstruction receiver,
                                                  HInstruction value,
                                                  {Selector selector,
                                                   ast.Node location}) {
    assert(send == null || Elements.isInstanceSend(send, elements));
    if (selector == null) {
      assert(send != null);
      selector = elements.getSelector(send);
    }
    if (location == null) {
      assert(send != null);
      location = send;
    }
    assert(selector.isSetter);
    pushInvokeDynamic(location, selector, [receiver, value]);
    pop();
    stack.add(value);
  }

  void generateNonInstanceSetter(ast.SendSet send,
                                 Element element,
                                 HInstruction value,
                                 {ast.Node location}) {
    assert(send == null || !Elements.isInstanceSend(send, elements));
    if (location == null) {
      assert(send != null);
      location = send;
    }
    if (Elements.isStaticOrTopLevelField(element)) {
      if (element.isSetter) {
        pushInvokeStatic(location, element, <HInstruction>[value]);
        pop();
      } else {
        VariableElement field = element;
        value =
            potentiallyCheckType(value, field.type);
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

  HForeign createForeign(js.Template code,
                         TypeMask type,
                         List<HInstruction> inputs) {
    return new HForeign(code, type, inputs);
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
      bool first = true;
      List<String> templates = <String>[];
      for (DartType argument in interface.typeArguments) {
        templates.add(rti.getTypeRepresentationWithHashes(argument, (variable) {
          HInstruction runtimeType = addTypeVariableReference(variable);
          inputs.add(runtimeType);
        }));
      }
      String template = '[${templates.join(', ')}]';
      // TODO(sra): This is a fresh template each time.  We can't let the
      // template manager build them.
      js.Template code = js.js.uncachedExpressionTemplate(template);
      HInstruction representation =
        createForeign(code, backend.readableArrayType, inputs);
      return representation;
    }
  }

  visitOperatorSend(ast.Send node) {
    ast.Operator op = node.selector;
    if ("[]" == op.source) {
      visitDynamicSend(node);
    } else if ("&&" == op.source ||
               "||" == op.source) {
      visitLogicalAndOr(node, op);
    } else if ("!" == op.source) {
      visitLogicalNot(node);
    } else if (node.argumentsNode is ast.Prefix) {
      visitUnary(node, op);
    } else if ("is" == op.source) {
      visitIsSend(node);
    } else if ("as" == op.source) {
      visit(node.receiver);
      HInstruction expression = pop();
      DartType type = elements.getType(node.typeAnnotationFromIsCheckOrCast);
      if (type.isMalformed) {
        ErroneousElement element = type.element;
        generateTypeError(node, element.message);
      } else {
        HInstruction converted = buildTypeConversion(
            expression,
            localsHandler.substInContext(type),
            HTypeConversion.CAST_TYPE_CHECK);
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

  void visitIsSend(ast.Send node) {
    visit(node.receiver);
    HInstruction expression = pop();
    bool isNot = node.isIsNotCheck;
    DartType type = elements.getType(node.typeAnnotationFromIsCheckOrCast);
    HInstruction instruction = buildIsNode(node, type, expression);
    if (isNot) {
      add(instruction);
      instruction = new HNot(instruction, backend.boolType);
    }
    push(instruction);
  }

  HInstruction buildIsNode(ast.Node node,
                           DartType type,
                           HInstruction expression) {
    type = localsHandler.substInContext(type).unalias(compiler);
    if (type.isFunctionType) {
      List arguments = [buildFunctionType(type), expression];
      pushInvokeDynamic(
          node, new Selector.call('_isTest', backend.jsHelperLibrary, 1),
          arguments);
      return new HIs.compound(type, expression, pop(), backend.boolType);
    } else if (type.isTypeVariable) {
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
      String operator = backend.namer.operatorIs(element);
      HInstruction isFieldName = addConstantString(operator);
      HInstruction asFieldName = compiler.world.hasAnySubtype(element)
          ? addConstantString(backend.namer.substitutionName(element))
          : graph.addConstantNull(compiler);
      List<HInstruction> inputs = <HInstruction>[expression,
                                                 isFieldName,
                                                 representations,
                                                 asFieldName];
      pushInvokeStatic(node, helper, inputs, backend.boolType);
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
      // TODO(johnniwinther): Avoid interceptor if unneeded.
      return new HIs.raw(
          type, expression, invokeInterceptor(expression), backend.boolType);
    }
  }

  HInstruction buildFunctionType(FunctionType type) {
    type.accept(new TypeBuilder(), this);
    return pop();
  }

  void addDynamicSendArgumentsToList(ast.Send node, List<HInstruction> list) {
    Selector selector = elements.getSelector(node);
    if (selector.namedArgumentCount == 0) {
      addGenericSendArgumentsToList(node.arguments, list);
    } else {
      // Visit positional arguments and add them to the list.
      Link<ast.Node> arguments = node.arguments;
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

  /**
   * Returns true if the arguments were compatible with the function signature.
   *
   * Invariant: [element] must be an implementation element.
   */
  bool addStaticSendArgumentsToList(Selector selector,
                                    Link<ast.Node> arguments,
                                    FunctionElement element,
                                    List<HInstruction> list) {
    assert(invariant(element, element.isImplementation));

    HInstruction compileArgument(ast.Node argument) {
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

  void addGenericSendArgumentsToList(Link<ast.Node> link, List<HInstruction> list) {
    for (; !link.isEmpty; link = link.tail) {
      visit(link.head);
      list.add(pop());
    }
  }

  visitDynamicSend(ast.Send node) {
    Selector selector = elements.getSelector(node);

    List<HInstruction> inputs = <HInstruction>[];
    HInstruction receiver = generateInstanceSendReceiver(node);
    inputs.add(receiver);
    addDynamicSendArgumentsToList(node, inputs);

    pushInvokeDynamic(node, selector, inputs);
    if (selector.isSetter || selector.isIndexSet) {
      pop();
      stack.add(inputs.last);
    }
  }

  visitClosureSend(ast.Send node) {
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

  void handleForeignJs(ast.Send node) {
    Link<ast.Node> link = node.arguments;
    // If the invoke is on foreign code, don't visit the first
    // argument, which is the type, and the second argument,
    // which is the foreign code.
    if (link.isEmpty || link.tail.isEmpty) {
      compiler.internalError(node.argumentsNode,
          'At least two arguments expected.');
    }
    native.NativeBehavior nativeBehavior =
        compiler.enqueuer.resolution.nativeEnqueuer.getNativeBehaviorOf(node);

    List<HInstruction> inputs = <HInstruction>[];
    addGenericSendArgumentsToList(link.tail.tail, inputs);

    TypeMask ssaType =
        TypeMaskFactory.fromNativeBehavior(nativeBehavior, compiler);

    if (nativeBehavior.codeTemplate.isExpression) {
      push(new HForeign(nativeBehavior.codeTemplate, ssaType, inputs,
                        effects: nativeBehavior.sideEffects,
                        nativeBehavior: nativeBehavior));
    } else {
      push(new HForeign(nativeBehavior.codeTemplate, ssaType, inputs,
                        isStatement: true,
                        effects: nativeBehavior.sideEffects,
                        nativeBehavior: nativeBehavior,
                        canThrow: true));
    }
  }

  void handleJsStringConcat(ast.Send node) {
    List<HInstruction> inputs = <HInstruction>[];
    addGenericSendArgumentsToList(node.arguments, inputs);
    if (inputs.length != 2) {
      compiler.internalError(node.argumentsNode, 'Two arguments expected.');
    }
    push(new HStringConcat(inputs[0], inputs[1], node, backend.stringType));
  }

  void handleForeignJsCurrentIsolateContext(ast.Send node) {
    if (!node.arguments.isEmpty) {
      compiler.internalError(node,
          'Too many arguments to JS_CURRENT_ISOLATE_CONTEXT.');
    }

    if (!compiler.hasIsolateSupport) {
      // If the isolate library is not used, we just generate code
      // to fetch the current isolate.
      String name = backend.namer.currentIsolate;
      push(new HForeign(js.js.parseForeignJS(name),
                        backend.dynamicType,
                        <HInstruction>[]));
    } else {
      // Call a helper method from the isolate library. The isolate
      // library uses its own isolate structure, that encapsulates
      // Leg's isolate.
      Element element = backend.isolateHelperLibrary.find('_currentIsolate');
      if (element == null) {
        compiler.internalError(node,
            'Isolate library and compiler mismatch.');
      }
      pushInvokeStatic(null, element, [], backend.dynamicType);
    }
  }

  void handleForeingJsGetFlag(ast.Send node) {
    List<ast.Node> arguments = node.arguments.toList();
     ast.Node argument;
     switch (arguments.length) {
     case 0:
       compiler.reportError(
           node, MessageKind.GENERIC,
           {'text': 'Error: Expected one argument to JS_GET_FLAG.'});
       return;
     case 1:
       argument = arguments[0];
       break;
     default:
       for (int i = 1; i < arguments.length; i++) {
         compiler.reportError(
             arguments[i], MessageKind.GENERIC,
             {'text': 'Error: Extra argument to JS_GET_FLAG.'});
       }
       return;
     }
     ast.LiteralString string = argument.asLiteralString();
     if (string == null) {
       compiler.reportError(
           argument, MessageKind.GENERIC,
           {'text': 'Error: Expected a literal string.'});
     }
     String name = string.dartString.slowToString();
     bool value = false;
     if (name == 'MUST_RETAIN_METADATA') {
       value = backend.mustRetainMetadata;
     } else {
       compiler.reportError(
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
    ast.LiteralString string = argument.asLiteralString();
    if (string == null) {
      compiler.reportError(
          argument, MessageKind.GENERIC,
          {'text': 'Error: Expected a literal string.'});
    }
    stack.add(
        addConstantString(
            backend.namer.getNameForJsGetName(
                argument, string.dartString.slowToString())));
  }

  void handleJsInterceptorConstant(ast.Send node) {
    // Single argument must be a TypeConstant which is converted into a
    // InterceptorConstant.
    if (!node.arguments.isEmpty && node.arguments.tail.isEmpty) {
      ast.Node argument = node.arguments.head;
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

  void handleForeignJsCallInIsolate(ast.Send node) {
    Link<ast.Node> link = node.arguments;
    if (!compiler.hasIsolateSupport) {
      // If the isolate library is not used, we just invoke the
      // closure.
      visit(link.tail.head);
      Selector selector = new Selector.callClosure(0);
      push(new HInvokeClosure(selector,
                              <HInstruction>[pop()],
                              backend.dynamicType));
    } else {
      // Call a helper method from the isolate library.
      Element element = backend.isolateHelperLibrary.find('_callInIsolate');
      if (element == null) {
        compiler.internalError(node,
            'Isolate library and compiler mismatch.');
      }
      List<HInstruction> inputs = <HInstruction>[];
      addGenericSendArgumentsToList(link, inputs);
      pushInvokeStatic(node, element, inputs, backend.dynamicType);
    }
  }

  FunctionSignature handleForeignRawFunctionRef(ast.Send node, String name) {
    if (node.arguments.isEmpty || !node.arguments.tail.isEmpty) {
      compiler.internalError(node.argumentsNode,
          '"$name" requires exactly one argument.');
    }
    ast.Node closure = node.arguments.head;
    Element element = elements[closure];
    if (!Elements.isStaticOrTopLevelFunction(element)) {
      compiler.internalError(closure,
          '"$name" requires a static or top-level method.');
    }
    FunctionElement function = element;
    // TODO(johnniwinther): Try to eliminate the need to distinguish declaration
    // and implementation signatures. Currently it is need because the
    // signatures have different elements for parameters.
    FunctionElement implementation = function.implementation;
    FunctionSignature params = implementation.functionSignature;
    if (params.optionalParameterCount != 0) {
      compiler.internalError(closure,
          '"$name" does not handle closure with optional parameters.');
    }

    registry.registerStaticUse(element);
    push(new HForeign(js.js.expressionTemplateYielding(
                          backend.namer.elementAccess(element)),
                      backend.dynamicType,
                      <HInstruction>[]));
    return params;
  }

  void handleForeignDartClosureToJs(ast.Send node, String name) {
    // TODO(ahe): This implements DART_CLOSURE_TO_JS and should probably take
    // care to wrap the closure in another closure that saves the current
    // isolate.
    handleForeignRawFunctionRef(node, name);
  }

  void handleForeignSetCurrentIsolate(ast.Send node) {
    if (node.arguments.isEmpty || !node.arguments.tail.isEmpty) {
      compiler.internalError(node.argumentsNode,
          'Exactly one argument required.');
    }
    visit(node.arguments.head);
    String isolateName = backend.namer.currentIsolate;
    SideEffects sideEffects = new SideEffects.empty();
    sideEffects.setAllSideEffects();
    push(new HForeign(js.js.parseForeignJS("$isolateName = #"),
                      backend.dynamicType,
                      <HInstruction>[pop()],
                      effects: sideEffects));
  }

  void handleForeignCreateIsolate(ast.Send node) {
    if (!node.arguments.isEmpty) {
      compiler.internalError(node.argumentsNode, 'Too many arguments.');
    }
    String constructorName = backend.namer.isolateName;
    push(new HForeign(js.js.parseForeignJS("new $constructorName()"),
                      backend.dynamicType,
                      <HInstruction>[]));
  }

  void handleForeignDartObjectJsConstructorFunction(ast.Send node) {
    if (!node.arguments.isEmpty) {
      compiler.internalError(node.argumentsNode, 'Too many arguments.');
    }
    push(new HForeign(js.js.expressionTemplateYielding(
                          backend.namer.elementAccess(compiler.objectClass)),
                      backend.dynamicType,
                      <HInstruction>[]));
  }

  void handleForeignJsCurrentIsolate(ast.Send node) {
    if (!node.arguments.isEmpty) {
      compiler.internalError(node.argumentsNode, 'Too many arguments.');
    }
    push(new HForeign(js.js.parseForeignJS(backend.namer.currentIsolate),
                      backend.dynamicType,
                      <HInstruction>[]));
  }

  visitForeignSend(ast.Send node) {
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
      stack.add(addConstantString(backend.namer.operatorIsPrefix()));
    } else if (name == 'JS_OBJECT_CLASS_NAME') {
      String name = backend.namer.getRuntimeTypeName(compiler.objectClass);
      stack.add(addConstantString(name));
    } else if (name == 'JS_NULL_CLASS_NAME') {
      String name = backend.namer.getRuntimeTypeName(compiler.nullClass);
      stack.add(addConstantString(name));
    } else if (name == 'JS_FUNCTION_CLASS_NAME') {
      String name = backend.namer.getRuntimeTypeName(compiler.functionClass);
      stack.add(addConstantString(name));
    } else if (name == 'JS_OPERATOR_AS_PREFIX') {
      stack.add(addConstantString(backend.namer.operatorAsPrefix()));
    } else if (name == 'JS_SIGNATURE_NAME') {
      stack.add(addConstantString(backend.namer.operatorSignature()));
    } else if (name == 'JS_FUNCTION_TYPE_TAG') {
      stack.add(addConstantString(backend.namer.functionTypeTag()));
    } else if (name == 'JS_FUNCTION_TYPE_VOID_RETURN_TAG') {
      stack.add(addConstantString(backend.namer.functionTypeVoidReturnTag()));
    } else if (name == 'JS_FUNCTION_TYPE_RETURN_TYPE_TAG') {
      stack.add(addConstantString(backend.namer.functionTypeReturnTypeTag()));
    } else if (name ==
               'JS_FUNCTION_TYPE_REQUIRED_PARAMETERS_TAG') {
      stack.add(addConstantString(
          backend.namer.functionTypeRequiredParametersTag()));
    } else if (name ==
               'JS_FUNCTION_TYPE_OPTIONAL_PARAMETERS_TAG') {
      stack.add(addConstantString(
          backend.namer.functionTypeOptionalParametersTag()));
    } else if (name ==
               'JS_FUNCTION_TYPE_NAMED_PARAMETERS_TAG') {
      stack.add(addConstantString(
          backend.namer.functionTypeNamedParametersTag()));
    } else if (name == 'JS_DART_OBJECT_CONSTRUCTOR') {
      handleForeignDartObjectJsConstructorFunction(node);
    } else if (name == 'JS_IS_INDEXABLE_FIELD_NAME') {
      Element element = backend.findHelper('JavaScriptIndexingBehavior');
      stack.add(addConstantString(backend.namer.operatorIs(element)));
    } else if (name == 'JS_CURRENT_ISOLATE') {
      handleForeignJsCurrentIsolate(node);
    } else if (name == 'JS_GET_NAME') {
      handleForeignJsGetName(node);
    } else if (name == 'JS_GET_FLAG') {
      handleForeingJsGetFlag(node);
    } else if (name == 'JS_EFFECT') {
      stack.add(graph.addConstantNull(compiler));
    } else if (name == 'JS_INTERCEPTOR_CONSTANT') {
      handleJsInterceptorConstant(node);
    } else if (name == 'JS_STRING_CONCAT') {
      handleJsStringConcat(node);
    } else {
      throw "Unknown foreign: ${selector}";
    }
  }

  visitForeignGetter(ast.Send node) {
    Element element = elements[node];
    // Until now we only handle these as getters.
    invariant(node, element.isDeferredLoaderGetter);
    FunctionElement deferredLoader = element;
    Element loadFunction = compiler.loadLibraryFunction;
    PrefixElement prefixElement = deferredLoader.enclosingElement;
    String loadId = compiler.deferredLoadTask
        .importDeferName[prefixElement.deferredImport];
    var inputs = [graph.addConstantString(
        new ast.DartString.literal(loadId), compiler)];
    push(new HInvokeStatic(loadFunction, inputs, backend.nonNullType,
                           targetCanThrow: false));
  }

  generateSuperNoSuchMethodSend(ast.Send node,
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
      registry.registerSelectorUse(selector.asUntyped);
    }
    String publicName = name;
    if (selector.isSetter) publicName += '=';

    Constant nameConstant = constantSystem.createString(
        new ast.DartString.literal(publicName));

    String internalName = backend.namer.invocationName(selector);
    Constant internalNameConstant =
        constantSystem.createString(new ast.DartString.literal(internalName));

    Element createInvocationMirror = backend.getCreateInvocationMirror();
    var argumentsInstruction = buildLiteralList(arguments);
    add(argumentsInstruction);

    var argumentNames = new List<HInstruction>();
    for (String argumentName in selector.namedArguments) {
      Constant argumentNameConstant =
          constantSystem.createString(new ast.DartString.literal(argumentName));
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

  visitSuperSend(ast.Send node) {
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
    } else if (element.isFunction || element.isGenerativeConstructor) {
      if (selector.applies(element, compiler)) {
        // TODO(5347): Try to avoid the need for calling [implementation] before
        // calling [addStaticSendArgumentsToList].
        FunctionElement function = element.implementation;
        bool succeeded = addStaticSendArgumentsToList(selector, node.arguments,
                                                      function, inputs);
        assert(succeeded);
        push(buildInvokeSuper(selector, element, inputs));
      } else if (element.isGenerativeConstructor) {
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

  bool needsSubstitutionForTypeVariableAccess(ClassElement cls) {
    if (compiler.world.isUsedAsMixin(cls)) return true;

    Set<ClassElement> subclasses = compiler.world.subclassesOf(cls);
    return subclasses != null && subclasses.any((ClassElement subclass) {
      return !rti.isTrivialSubstitution(subclass, cls);
    });
  }

  /**
   * Generate code to extract the type arguments from the object, substitute
   * them as an instance of the type we are testing against (if necessary), and
   * extract the type argument by the index of the variable in the list of type
   * variables for that class.
   */
  HInstruction readTypeVariable(ClassElement cls,
                                TypeVariableElement variable) {
    assert(sourceElement.isInstanceMember);

    HInstruction target = localsHandler.readThis();
    HConstant index = graph.addConstantInt(
        RuntimeTypes.getTypeVariableIndex(variable),
        compiler);

    if (needsSubstitutionForTypeVariableAccess(cls)) {
      // TODO(ahe): Creating a string here is unfortunate. It is slow (due to
      // string concatenation in the implementation), and may prevent
      // segmentation of '$'.
      String substitutionNameString = backend.namer.getNameForRti(cls);
      HInstruction substitutionName = graph.addConstantString(
          new ast.LiteralDartString(substitutionNameString), compiler);
      pushInvokeStatic(null,
                       backend.getGetRuntimeTypeArgument(),
                       [target, substitutionName, index],
                        backend.dynamicType);
    } else {
      pushInvokeStatic(null, backend.getGetTypeArgumentByIndex(),
          [target, index],
          backend.dynamicType);
    }
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
    if (isClosure) {
      if (member.isFactoryConstructor ||
          (isInConstructorContext && hasDirectLocal(type.element))) {
        // The type variable is used from a closure in a factory constructor.
        // The value of the type argument is stored as a local on the closure
        // itself.
        return localsHandler.readLocal(type.element);
      } else if (member.isFunction ||
          member.isGetter ||
          member.isSetter ||
          isInConstructorContext) {
        // The type variable is stored on the "enclosing object" and needs to be
        // accessed using the this-reference in the closure.
        return readTypeVariable(member.enclosingClass, type.element);
      } else {
        assert(member.isField);
        // The type variable is stored in a parameter of the method.
        return localsHandler.readLocal(type.element);
      }
    } else if (isInConstructorContext ||
               // When [member] is a field, we can be either
               // generating a checked setter or inlining its
               // initializer in a constructor. An initializer is
               // never built standalone, so [isBuildingFor] will
               // always return true when seeing one.
               (member.isField && !isBuildingFor(member))) {
      // The type variable is stored in a parameter of the method.
      return localsHandler.readLocal(type.element);
    } else if (member.isInstanceMember) {
      // The type variable is stored on the object.
      return readTypeVariable(member.enclosingClass,
                              type.element);
    } else {
      // TODO(ngeoffray): Match the VM behavior and throw an
      // exception at runtime.
      compiler.internalError(type.element,
          'Unimplemented unresolved type variable.');
      return null;
    }
  }

  HInstruction analyzeTypeArgument(DartType argument) {
    assert(assertTypeInContext(argument));
    if (argument.treatAsDynamic) {
      // Represent [dynamic] as [null].
      return graph.addConstantNull(compiler);
    }

    if (argument.isTypeVariable) {
      return addTypeVariableReference(argument);
    }

    List<HInstruction> inputs = <HInstruction>[];

    String template = rti.getTypeRepresentationWithHashes(argument, (variable) {
      inputs.add(addTypeVariableReference(variable));
    });

    js.Template code = js.js.uncachedExpressionTemplate(template);
    HInstruction result = createForeign(code, backend.stringType, inputs);
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
    registry.registerInstantiatedType(type);
    return callSetRuntimeTypeInfo(type.element, inputs, newObject);
  }

  void copyRuntimeTypeInfo(HInstruction source, HInstruction target) {
    Element copyHelper = backend.getCopyTypeArguments();
    pushInvokeStatic(null, copyHelper, [source, target]);
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
    Element typeInfoSetterElement = backend.getSetRuntimeTypeInfo();
    pushInvokeStatic(
        null,
        typeInfoSetterElement,
        <HInstruction>[newObject, typeInfo],
        backend.dynamicType);

    // The new object will now be referenced through the
    // `setRuntimeTypeInfo` call. We therefore set the type of that
    // instruction to be of the object's type.
    assert(stack.last is HInvokeStatic || stack.last == newObject);
    stack.last.instructionType = newObject.instructionType;
    return pop();
  }

  handleNewSend(ast.NewExpression node) {
    ast.Send send = node.send;
    generateIsDeferredLoadedCheckIfNeeded(send);

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
        return inferred.containsAll(compiler)
            ? backend.fixedArrayType
            : inferred;
      } else if (isGrowableListConstructorCall) {
        TypeMask inferred =
            TypeMaskFactory.inferredForNode(sourceElement, send, compiler);
        return inferred.containsAll(compiler)
            ? backend.extendableArrayType
            : inferred;
      } else if (Elements.isConstructorOfTypedArraySubclass(
                    originalElement, compiler)) {
        isFixedList = true;
        TypeMask inferred =
            TypeMaskFactory.inferredForNode(sourceElement, send, compiler);
        ClassElement cls = element.enclosingClass;
        assert(cls.thisType.element.isNative);
        return inferred.containsAll(compiler)
            ? new TypeMask.nonNullExact(cls.thisType.element)
            : inferred;
      } else if (element.isGenerativeConstructor) {
        ClassElement cls = element.enclosingClass;
        return new TypeMask.nonNullExact(cls.thisType.element);
      } else {
        return TypeMaskFactory.inferredReturnTypeForElement(
            originalElement, compiler);
      }
    }

    Element constructor = elements[send];
    Selector selector = elements.getSelector(send);
    ConstructorElement constructorDeclaration = constructor;
    constructor = constructorDeclaration.effectiveTarget;

    final bool isSymbolConstructor =
        constructorDeclaration == compiler.symbolConstructor;
    final bool isJSArrayTypedConstructor =
        constructorDeclaration == backend.jsArrayTypedConstructor;

    if (isSymbolConstructor) {
      constructor = compiler.symbolValidatedConstructor;
      assert(invariant(send, constructor != null,
                       message: 'Constructor Symbol.validated is missing'));
      selector = compiler.symbolValidatedConstructorSelector;
      assert(invariant(send, selector != null,
                       message: 'Constructor Symbol.validated is missing'));
    }

    bool isRedirected = constructorDeclaration.isRedirectingFactory;
    InterfaceType type = elements.getType(node);
    InterfaceType expectedType =
        constructorDeclaration.computeEffectiveTargetType(type);
    expectedType = localsHandler.substInContext(expectedType);

    if (checkTypeVariableBounds(node, type)) return;

    var inputs = <HInstruction>[];
    if (constructor.isGenerativeConstructor &&
        Elements.isNativeOrExtendsNative(constructor.enclosingClass)) {
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

    if (constructor.isFactoryConstructor &&
        !expectedType.typeArguments.isEmpty) {
      registry.registerFactoryWithTypeArguments();
    }

    TypeMask elementType = computeType(constructor);
    if (isFixedListConstructorCall) {
      if (!inputs[0].isNumber(compiler)) {
        HTypeConversion conversion = new HTypeConversion(
          null, HTypeConversion.ARGUMENT_TYPE_CHECK, backend.numType,
          inputs[0], null);
        add(conversion);
        inputs[0] = conversion;
      }
      js.Template code = js.js.parseForeignJS('Array(#)');
      var behavior = new native.NativeBehavior();
      behavior.typesReturned.add(expectedType);
      // The allocation can throw only if the given length is a double
      // or negative.
      bool canThrow = true;
      if (inputs[0].isInteger(compiler) && inputs[0] is HConstant) {
        var constant = inputs[0];
        if (constant.constant.value >= 0) canThrow = false;
      }
      HForeign foreign = new HForeign(
          code, elementType, inputs, nativeBehavior: behavior,
          canThrow: canThrow);
      push(foreign);
      TypesInferrer inferrer = compiler.typesTask.typesInferrer;
      if (inferrer.isFixedArrayCheckedForGrowable(send)) {
        js.Template code = js.js.parseForeignJS(r'#.fixed$length = init');
        // We set the instruction as [canThrow] to avoid it being dead code.
        // We need a finer grained side effect.
        add(new HForeign(
              code, backend.nullType, [stack.last], canThrow: true));
      }
    } else if (isGrowableListConstructorCall) {
      push(buildLiteralList(<HInstruction>[]));
      stack.last.instructionType = elementType;
    } else {
      ClassElement cls = constructor.enclosingClass;
      if (cls.isAbstract && constructor.isGenerativeConstructor) {
        generateAbstractClassInstantiationError(send, cls.name);
        return;
      }
      if (backend.classNeedsRti(cls)) {
        Link<DartType> typeVariable = cls.typeVariables;
        expectedType.typeArguments.forEach((DartType argument) {
          inputs.add(analyzeTypeArgument(argument));
          typeVariable = typeVariable.tail;
        });
        assert(typeVariable.isEmpty);
      }

      addInlinedInstantiation(expectedType);
      pushInvokeStatic(node, constructor, inputs, elementType);
      removeInlinedInstantiation(expectedType);
    }
    HInstruction newInstance = stack.last;
    if (isFixedList) {
      // Overwrite the element type, in case the allocation site has
      // been inlined.
      newInstance.instructionType = elementType;
      JavaScriptItemCompilationContext context = work.compilationContext;
      context.allocatedFixedLists.add(newInstance);
    }

    // The List constructor forwards to a Dart static method that does
    // not know about the type argument. Therefore we special case
    // this constructor to have the setRuntimeTypeInfo called where
    // the 'new' is done.
    if (backend.classNeedsRti(compiler.listClass) &&
        (isFixedListConstructorCall || isGrowableListConstructorCall ||
         isJSArrayTypedConstructor)) {
      newInstance = handleListConstructor(type, send, pop());
      stack.add(newInstance);
    }

    // Finally, if we called a redirecting factory constructor, check the type.
    if (isRedirected) {
      HInstruction checked = potentiallyCheckType(newInstance, type);
      if (checked != newInstance) {
        pop();
        stack.add(checked);
      }
    }
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

  visitAssert(node) {
    if (!compiler.enableUserAssertions) {
      stack.add(graph.addConstantNull(compiler));
      return;
    }
    // TODO(johnniwinther): Don't handle assert like a regular static call.
    // It breaks the selector name check since the assert helper method cannot
    // be called `assert` and therefore does not match the selector like a
    // regular method.
    visitStaticSend(node);
  }

  visitStaticSend(ast.Send node) {
    Selector selector = elements.getSelector(node);
    Element element = elements[node];
    if (elements.isAssert(node)) {
      element = backend.assertMethod;
    }
    if (element.isForeign(compiler) && element.isFunction) {
      visitForeignSend(node);
      return;
    }
    if (element.isErroneous) {
      // An erroneous element indicates that the funciton could not be resolved
      // (a warning has been issued).
      generateThrowNoSuchMethod(node,
                                getTargetName(element),
                                argumentNodes: node.arguments);
      return;
    }
    invariant(element, !element.isGenerativeConstructor);
    generateIsDeferredLoadedCheckIfNeeded(node);
    if (element.isFunction) {
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

  HConstant addConstantString(String string) {
    ast.DartString dartString = new ast.DartString.literal(string);
    Constant constant = constantSystem.createString(dartString);
    return graph.addConstant(constant, compiler);
  }

  visitTypeReferenceSend(ast.Send node) {
    Element element = elements[node];
    if (element.isClass || element.isTypedef) {
      // TODO(karlklose): add type representation
      if (node.isCall) {
        // The node itself is not a constant but we register the selector (the
        // identifier that refers to the class/typedef) as a constant.
        stack.add(addConstant(node.selector));
      } else {
        stack.add(addConstant(node));
      }
    } else if (element.isTypeVariable) {
      TypeVariableElement typeVariable = element;
      DartType type = localsHandler.substInContext(typeVariable.type);
      HInstruction value = analyzeTypeArgument(type);
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

  visitGetterSend(ast.Send node) {
    generateIsDeferredLoadedCheckIfNeeded(node);
    generateGetter(node, elements[node]);
  }

  // TODO(antonm): migrate rest of SsaFromAstMixin to internalError.
  internalError(String reason, {ast.Node node}) {
    compiler.internalError(node, reason);
  }

  void generateError(ast.Node node, String message, Element helper) {
    HInstruction errorMessage = addConstantString(message);
    pushInvokeStatic(node, helper, [errorMessage]);
  }

  void generateRuntimeError(ast.Node node, String message) {
    generateError(node, message, backend.getThrowRuntimeError());
  }

  void generateTypeError(ast.Node node, String message) {
    generateError(node, message, backend.getThrowTypeError());
  }

  void generateAbstractClassInstantiationError(ast.Node node, String message) {
    generateError(node,
                  message,
                  backend.getThrowAbstractClassInstantiationError());
  }

  void generateThrowNoSuchMethod(ast.Node diagnosticNode,
                                 String methodName,
                                 {Link<ast.Node> argumentNodes,
                                  List<HInstruction> argumentValues,
                                  List<String> existingArguments}) {
    Element helper = backend.getThrowNoSuchMethod();
    Constant receiverConstant =
        constantSystem.createString(new ast.DartString.empty());
    HInstruction receiver = graph.addConstant(receiverConstant, compiler);
    ast.DartString dartString = new ast.DartString.literal(methodName);
    Constant nameConstant = constantSystem.createString(dartString);
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
                     [receiver, name, arguments, existingNamesList]);
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

  visitNewExpression(ast.NewExpression node) {
    Element element = elements[node.send];
    final bool isSymbolConstructor = element == compiler.symbolConstructor;
    if (!Elements.isErroneousElement(element)) {
      ConstructorElement function = element;
      element = function.effectiveTarget;
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
    } else if (node.isConst) {
      stack.add(addConstant(node));
      if (isSymbolConstructor) {
        ConstructedConstant symbol = getConstantForNode(node);
        StringConstant stringConstant = symbol.fields.single;
        String nameString = stringConstant.toDartString().slowToString();
        registry.registerConstSymbol(nameString);
      }
    } else {
      handleNewSend(node);
    }
  }

  void pushInvokeDynamic(ast.Node node,
                         Selector selector,
                         List<HInstruction> arguments,
                         {ast.Node location}) {
    if (location == null) location = node;

    // We prefer to not inline certain operations on indexables,
    // because the constant folder will handle them better and turn
    // them into simpler instructions that allow further
    // optimizations.
    bool isOptimizableOperationOnIndexable(Selector selector, Element element) {
      bool isLength = selector.isGetter
          && selector.name == "length";
      if (isLength || selector.isIndex) {
        TypeMask type = new TypeMask.nonNullExact(
            element.enclosingClass.declaration);
        return type.satisfies(backend.jsIndexableClass, compiler);
      } else if (selector.isIndexSet) {
        TypeMask type = new TypeMask.nonNullExact(
            element.enclosingClass.declaration);
        return type.satisfies(backend.jsMutableIndexableClass, compiler);
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
      if (element == backend.jsArrayAdd
          || element == backend.jsArrayRemoveLast
          || element == backend.jsStringSplit) {
        return true;
      }
      return false;
    }

    Element element = compiler.world.locateSingleElement(selector);
    if (element != null
        && !element.isField
        && !(element.isGetter && selector.isCall)
        && !(element.isFunction && selector.isGetter)
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
    if (selector.isGetter) {
      pushWithPosition(
          new HInvokeDynamicGetter(selector, null, inputs, type),
          location);
    } else if (selector.isSetter) {
      pushWithPosition(
          new HInvokeDynamicSetter(selector, null, inputs, type),
          location);
    } else {
      pushWithPosition(
          new HInvokeDynamicMethod(selector, inputs, type, isIntercepted),
          location);
    }
  }

  void pushInvokeStatic(ast.Node location,
                        Element element,
                        List<HInstruction> arguments,
                        [TypeMask type]) {
    if (tryInlineMethod(element, null, arguments, location)) {
      return;
    }

    if (type == null) {
      type = TypeMaskFactory.inferredReturnTypeForElement(element, compiler);
    }
    bool targetCanThrow = !compiler.world.getCannotThrow(element);
    // TODO(5346): Try to avoid the need for calling [declaration] before
    // creating an [HInvokeStatic].
    HInvokeStatic instruction = new HInvokeStatic(
        element.declaration, arguments, type, targetCanThrow: targetCanThrow);
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
        isSetter: selector.isSetter || selector.isIndexSet);
    instruction.sideEffects = compiler.world.getSideEffectsOfSelector(selector);
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
    visitBinary(receiver, node.assignmentOperator, rhs,
                elements.getOperatorSelectorInComplexSendSet(node), node);
  }

  visitSendSet(ast.SendSet node) {
    generateIsDeferredLoadedCheckIfNeeded(node);
    Element element = elements[node];
    if (!Elements.isUnresolved(element) && element.impliesType) {
      ast.Identifier selector = node.selector;
      generateThrowNoSuchMethod(node, selector.source,
                                argumentNodes: node.arguments);
      return;
    }
    ast.Operator op = node.assignmentOperator;
    if (node.isSuperCall) {
      HInstruction result;
      List<HInstruction> setterInputs = <HInstruction>[];
      if (identical(node.assignmentOperator.source, '=')) {
        addDynamicSendArgumentsToList(node, setterInputs);
        result = setterInputs.last;
      } else {
        Element getter = elements[node.selector];
        List<HInstruction> getterInputs = <HInstruction>[];
        Link<ast.Node> arguments = node.arguments;
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
      Link<ast.Node> link = node.arguments;
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
      compiler.internalError(op, "is-operator as SendSet.");
    } else {
      assert("++" == op.source || "--" == op.source ||
             node.assignmentOperator.source.endsWith("="));

      // [receiver] is only used if the node is an instance send.
      HInstruction receiver = null;
      Element getter = elements[node.selector];

      if (!Elements.isUnresolved(getter) && getter.impliesType) {
        ast.Identifier selector = node.selector;
        generateThrowNoSuchMethod(node, selector.source,
                                  argumentNodes: node.arguments);
        return;
      } else if (Elements.isInstanceSend(node, elements)) {
        receiver = generateInstanceSendReceiver(node);
        generateInstanceGetterWithCompiledReceiver(
            node, elements.getGetterSelectorInComplexSendSet(node), receiver);
      } else {
        generateGetter(node, getter);
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
    registry.registerConstSymbol(node.slowNameString);
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
        compiler.reportWarning(link.head,
            MessageKind.GENERIC, {'text': 'dead code'});
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
    compiler.internalError(node,
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
      compiler.internalError(node,
          'rethrowableException should not be null.');
    }
    handleInTryStatement();
    closeAndGotoExit(new HThrow(exception, isRethrow: true));
  }

  visitReturn(ast.Return node) {
    if (identical(node.beginToken.stringValue, 'native')) {
      native.handleSsaNative(this, node.expression);
      return;
    }
    HInstruction value;
    if (node.isRedirectingFactoryBody) {
      FunctionElement targetConstructor =
          elements[node.expression].implementation;
      ConstructorElement redirectingConstructor = sourceElement;
      List<HInstruction> inputs = <HInstruction>[];
      FunctionSignature targetSignature = targetConstructor.functionSignature;
      FunctionSignature redirectingSignature =
          redirectingConstructor.functionSignature;
      redirectingSignature.forEachRequiredParameter((Element element) {
        inputs.add(localsHandler.readLocal(element));
      });
      List<Element> targetOptionals =
          targetSignature.orderedOptionalParameters;
      List<Element> redirectingOptionals =
          redirectingSignature.orderedOptionalParameters;
      int i = 0;
      for (; i < redirectingOptionals.length; i++) {
        inputs.add(localsHandler.readLocal(redirectingOptionals[i]));
      }
      for (; i < targetOptionals.length; i++) {
        inputs.add(handleConstantForOptionalParameter(targetOptionals[i]));
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
      value = pop();
    } else if (node.expression == null) {
      value = graph.addConstantNull(compiler);
    } else {
      visit(node.expression);
      value = pop();
      value = potentiallyCheckType(value, returnType);
    }

    handleInTryStatement();
    emitReturn(value, node);
  }

  visitThrow(ast.Throw node) {
    visitThrowExpression(node.expression);
    if (isReachable) {
      handleInTryStatement();
      push(new HThrowExpression(pop()));
      isReachable = false;
    }
  }

  visitTypeAnnotation(ast.TypeAnnotation node) {
    compiler.internalError(node,
        'Visiting type annotation in SSA builder.');
  }

  visitVariableDefinitions(ast.VariableDefinitions node) {
    assert(isReachable);
    for (Link<ast.Node> link = node.definitions.nodes;
         !link.isEmpty;
         link = link.tail) {
      ast.Node definition = link.head;
      if (definition is ast.Identifier) {
        HInstruction initialValue = graph.addConstantNull(compiler);
        localsHandler.updateLocal(elements[definition], initialValue);
      } else {
        assert(definition is ast.SendSet);
        visitSendSet(definition);
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
    registry.registerInstantiatedType(type);
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
    if (!type.containsAll(compiler)) instruction.instructionType = type;
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
    compiler.internalError(node,
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

  visitContinueStatement(ast.ContinueStatement node) {
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
  JumpHandler createJumpHandler(ast.Statement node, {bool isLoopJump}) {
    TargetElement element = elements[node];
    if (element == null || !identical(element.statement, node)) {
      // No breaks or continues to this node.
      return new NullJumpHandler(compiler);
    }
    if (isLoopJump && node is ast.SwitchStatement) {
      // Create a special jump handler for loops created for switch statements
      // with continue statements.
      return new SwitchCaseJumpHandler(this, element, node);
    }
    return new JumpHandler(this, element);
  }

  visitForIn(ast.ForIn node) {
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

      ast.Node identifier = node.declaredIdentifier;
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

  visitLabel(ast.Label node) {
    compiler.internalError(node, 'SsaFromAstMixin.visitLabel.');
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

    ConstructorElement constructor;
    List<HInstruction> inputs = <HInstruction>[];

    if (listInputs.isEmpty) {
      constructor = backend.mapLiteralConstructorEmpty;
    } else {
      constructor = backend.mapLiteralConstructor;
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

    if (constructor.isFactoryConstructor) {
      registry.registerFactoryWithTypeArguments();
    }

    ClassElement cls = constructor.enclosingClass;

    if (backend.classNeedsRti(cls)) {
      Link<DartType> typeVariable = cls.typeVariables;
      expectedType.typeArguments.forEach((DartType argument) {
            inputs.add(analyzeTypeArgument(argument));
            typeVariable = typeVariable.tail;
          });
      assert(typeVariable.isEmpty);
    }

    // The instruction type will always be a subtype of the mapLiteralClass, but
    // type inference might discover a more specific type, or find nothing (in
    // dart2js unit tests).
    TypeMask mapType = new TypeMask.nonNullSubtype(backend.mapLiteralClass);
    TypeMask returnTypeMask = TypeMaskFactory.inferredReturnTypeForElement(
        constructor, compiler);
    TypeMask instructionType = mapType.intersection(returnTypeMask, compiler);

    addInlinedInstantiation(expectedType);
    pushInvokeStatic(node, constructor, inputs, instructionType);
    removeInlinedInstantiation(expectedType);
  }

  visitLiteralMapEntry(ast.LiteralMapEntry node) {
    visit(node.value);
    visit(node.key);
  }

  visitNamedArgument(ast.NamedArgument node) {
    visit(node.expression);
  }

  Map<ast.CaseMatch, Constant> buildSwitchCaseConstants(ast.SwitchStatement node) {
    Map<ast.CaseMatch, Constant> constants = new Map<ast.CaseMatch, Constant>();
    for (ast.SwitchCase switchCase in node.cases) {
      for (ast.Node labelOrCase in switchCase.labelsAndCases) {
        if (labelOrCase is ast.CaseMatch) {
          ast.CaseMatch match = labelOrCase;
          Constant constant = getConstantForNode(match.expression);
          constants[labelOrCase] = constant;
        }
      }
    }
    return constants;
  }

  visitSwitchStatement(ast.SwitchStatement node) {
    Map<ast.CaseMatch, Constant> constants = buildSwitchCaseConstants(node);

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
  void buildSimpleSwitchStatement(ast.SwitchStatement node,
                                  Map<ast.CaseMatch, Constant> constants) {
    JumpHandler jumpHandler = createJumpHandler(node, isLoopJump: false);
    HInstruction buildExpression() {
      visit(node.expression);
      return pop();
    }
    Iterable<Constant> getConstants(ast.SwitchCase switchCase) {
      List<Constant> constantList = <Constant>[];
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
                                   Map<ast.CaseMatch, Constant> constants,
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
    Iterable<Constant> getConstants(ast.SwitchCase switchCase) {
      List<Constant> constantList = <Constant>[];
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
      Iterable<Constant> getConstants(ast.SwitchCase switchCase) {
        return <Constant>[constantSystem.createInt(caseIndex[switchCase])];
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
        js.Template code = js.js.parseForeignJS('#');
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
   * [switchCases] must be either an [Iterable] of [ast.SwitchCase] nodes or
   *   a [Link] or a [ast.NodeList] of [ast.SwitchCase] nodes.
   * [getConstants] returns the set of constants for a switch case.
   * [isDefaultCase] returns [:true:] if the provided switch case should be
   *   considered default for the created switch statement.
   * [buildSwitchCase] creates the statements for the switch case.
   */
  void handleSwitch(ast.Node errorNode,
                    JumpHandler jumpHandler,
                    HInstruction buildExpression(),
                    var switchCases,
                    Iterable<Constant> getConstants(ast.SwitchCase switchCase),
                    bool isDefaultCase(ast.SwitchCase switchCase),
                    void buildSwitchCase(ast.SwitchCase switchCase)) {
    Map<ast.CaseMatch, Constant> constants = new Map<ast.CaseMatch, Constant>();

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
    Element getFallThroughErrorElement = backend.getFallThroughError();
    HasNextIterator<ast.Node> caseIterator =
        new HasNextIterator<ast.Node>(switchCases.iterator);
    while (caseIterator.hasNext) {
      ast.SwitchCase switchCase = caseIterator.next();
      HBasicBlock block = graph.addNewBlock();
      for (Constant constant in getConstants(switchCase)) {
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
    compiler.internalError(node, 'SsaFromAstMixin.visitSwitchCase.');
  }

  visitCaseMatch(ast.CaseMatch node) {
    compiler.internalError(node, 'SsaFromAstMixin.visitCaseMatch.');
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
      // TODO(kasperl): Bad smell. We shouldn't be constructing elements here.
      // Note that the name of this element is irrelevant.
      Element element = new VariableElementX.synthetic('exception',
          ElementKind.PARAMETER, sourceElement);
      exception = new HLocalValue(element, backend.nonNullType);
      add(exception);
      HInstruction oldRethrowableException = rethrowableException;
      rethrowableException = exception;

      pushInvokeStatic(node, backend.getExceptionUnwrapper(), [exception]);
      HInvokeStatic unwrappedException = pop();
      tryInstruction.exception = exception;
      Link<ast.Node> link = node.catchBlocks.nodes;

      void pushCondition(ast.CatchBlock catchBlock) {
        if (catchBlock.onKeyword != null) {
          DartType type = elements.getType(catchBlock.type);
          if (type == null) {
            compiler.internalError(catchBlock.type, 'On with no type.');
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
              compiler.internalError(catchBlock, 'Catch with unresolved type.');
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
          localsHandler.updateLocal(elements[catchBlock.exception],
                                    unwrappedException);
        }
        ast.Node trace = catchBlock.trace;
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
          ast.CatchBlock newBlock = link.head;
          handleIf(node,
                   () { pushCondition(newBlock); },
                   visitThen, visitElse);
        }
      }

      ast.CatchBlock firstBlock = link.head;
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

  visitCatchBlock(ast.CatchBlock node) {
    visit(node.block);
  }

  visitTypedef(ast.Typedef node) {
    compiler.unimplemented(node, 'SsaFromAstMixin.visitTypedef.');
  }

  visitTypeVariable(ast.TypeVariable node) {
    compiler.internalError(node, 'SsaFromAstMixin.visitTypeVariable.');
  }

  /**
   * This method is invoked before inlining the body of [function] into this
   * [SsaBuilder].
   */
  void enterInlinedMethod(FunctionElement function,
                          ast.Node _,
                          List<HInstruction> compiledArguments) {
    AstInliningState state = new AstInliningState(
        function, returnElement, returnType, elements, stack, localsHandler,
        inTryStatement);
    inliningStack.add(state);

    // Setting up the state of the (AST) builder is performed even when the
    // inlined function is in IR, because the irInliner uses the [returnElement]
    // of the AST builder.
    setupStateForInlining(function, compiledArguments);
  }

  void leaveInlinedMethod() {
    HInstruction result = localsHandler.readLocal(returnElement);
    AstInliningState state = inliningStack.removeLast();
    restoreState(state);
    stack.add(result);
  }

  void doInline(FunctionElement function) {
    visitInlinedFunction(function);
  }

  void emitReturn(HInstruction value, ast.Node node) {
    if (inliningStack.isEmpty) {
      closeAndGotoExit(attachPosition(new HReturn(value), node));
    } else {
      localsHandler.updateLocal(returnElement, value);
    }
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
    builder.compiler.internalError(node, 'Unexpected node.');
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
    Selector selector =
        new TypedSelector(expression.instructionType,
            new Selector.call('toString', null, 0), compiler);
    TypeMask type = TypeMaskFactory.inferredTypeForSelector(selector, compiler);
    if (type.containsOnlyString(compiler)) {
      builder.pushInvokeDynamic(node, selector, <HInstruction>[expression]);
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

  InlineWeeder(this.maxInliningNodes, this.useMaxInliningNodes);

  static bool canBeInlined(ast.FunctionExpression functionExpression,
                           int maxInliningNodes,
                           bool useMaxInliningNodes) {
    InlineWeeder weeder =
        new InlineWeeder(maxInliningNodes, useMaxInliningNodes);
    weeder.visit(functionExpression.initializers);
    weeder.visit(functionExpression.body);
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
    tooDifficult = true;
  }

  void visitRethrow(ast.Rethrow node) {
    if (!registerNode()) return;
    tooDifficult = true;
  }

  void visitReturn(ast.Return node) {
    if (!registerNode()) return;
    if (seenReturn
        || identical(node.beginToken.stringValue, 'native')
        || node.isRedirectingFactoryBody) {
      tooDifficult = true;
      return;
    }
    node.visitChildren(this);
    seenReturn = true;
  }

  void visitTryStatement(ast.Node node) {
    if (!registerNode()) return;
    tooDifficult = true;
  }

  void visitThrow(ast.Throw node) {
    if (!registerNode()) return;
    // For now, we don't want to handle throw after a return even if
    // it is in an "if".
    if (seenReturn) tooDifficult = true;
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
  final Element oldReturnElement;
  final DartType oldReturnType;
  final TreeElements oldElements;
  final List<HInstruction> oldStack;
  final LocalsHandler oldLocalsHandler;
  final bool inTryStatement;

  AstInliningState(FunctionElement function,
                   this.oldReturnElement,
                   this.oldReturnType,
                   this.oldElements,
                   this.oldStack,
                   this.oldLocalsHandler,
                   this.inTryStatement): super(function);
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

class TypeBuilder implements DartTypeVisitor<dynamic, SsaBuilder> {
  void visitType(DartType type, _) {
    throw 'Internal error $type';
  }

  void visitVoidType(VoidType type, SsaBuilder builder) {
    ClassElement cls = builder.backend.findHelper('VoidRuntimeType');
    builder.push(new HVoidType(type, new TypeMask.exact(cls)));
  }

  void visitTypeVariableType(TypeVariableType type,
                             SsaBuilder builder) {
    ClassElement cls = builder.backend.findHelper('RuntimeType');
    TypeMask instructionType = new TypeMask.subclass(cls);
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

    Link<DartType> namedParameterTypes = type.namedParameterTypes;
    for (String name in type.namedParameters) {
      ast.DartString dartString = new ast.DartString.literal(name);
      inputs.add(
          builder.graph.addConstantString(dartString, builder.compiler));
      namedParameterTypes.head.accept(this, builder);
      inputs.add(builder.pop());
      namedParameterTypes = namedParameterTypes.tail;
    }

    ClassElement cls = builder.backend.findHelper('RuntimeFunctionType');
    builder.push(new HFunctionType(inputs, type, new TypeMask.exact(cls)));
  }

  void visitMalformedType(MalformedType type, SsaBuilder builder) {
    visitDynamicType(const DynamicType(), builder);
  }

  void visitStatementType(StatementType type, SsaBuilder builder) {
    throw 'not implemented visitStatementType($type)';
  }

  void visitGenericType(GenericType type, SsaBuilder builder) {
    throw 'not implemented visitGenericType($type)';
  }

  void visitInterfaceType(InterfaceType type, SsaBuilder builder) {
    List<HInstruction> inputs = <HInstruction>[];
    for (DartType typeArgument in type.typeArguments) {
      typeArgument.accept(this, builder);
      inputs.add(builder.pop());
    }
    ClassElement cls;
    if (type.typeArguments.isEmpty) {
      cls = builder.backend.findHelper('RuntimeTypePlain');
    } else {
      cls = builder.backend.findHelper('RuntimeTypeGeneric');
    }
    builder.push(new HInterfaceType(inputs, type, new TypeMask.exact(cls)));
  }

  void visitTypedefType(TypedefType type, SsaBuilder builder) {
    DartType unaliased = type.unalias(builder.compiler);
    if (unaliased is TypedefType) throw 'unable to unalias $type';
    unaliased.accept(this, builder);
  }

  void visitDynamicType(DynamicType type, SsaBuilder builder) {
    JavaScriptBackend backend = builder.compiler.backend;
    ClassElement cls = backend.findHelper('DynamicRuntimeType');
    builder.push(new HDynamicType(type, new TypeMask.exact(cls)));
  }
}
