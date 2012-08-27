// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Interceptors {
  Compiler compiler;
  Interceptors(Compiler this.compiler);

  SourceString mapOperatorToMethodName(Operator op) {
    String name = op.source.stringValue;
    if (name === '+') return const SourceString('add');
    if (name === '-') return const SourceString('sub');
    if (name === '*') return const SourceString('mul');
    if (name === '/') return const SourceString('div');
    if (name === '~/') return const SourceString('tdiv');
    if (name === '%') return const SourceString('mod');
    if (name === '<<') return const SourceString('shl');
    if (name === '>>') return const SourceString('shr');
    if (name === '|') return const SourceString('or');
    if (name === '&') return const SourceString('and');
    if (name === '^') return const SourceString('xor');
    if (name === '<') return const SourceString('lt');
    if (name === '<=') return const SourceString('le');
    if (name === '>') return const SourceString('gt');
    if (name === '>=') return const SourceString('ge');
    if (name === '==') return const SourceString('eq');
    if (name === '!=') return const SourceString('eq');
    if (name === '===') return const SourceString('eqq');
    if (name === '!==') return const SourceString('eqq');
    if (name === '+=') return const SourceString('add');
    if (name === '-=') return const SourceString('sub');
    if (name === '*=') return const SourceString('mul');
    if (name === '/=') return const SourceString('div');
    if (name === '~/=') return const SourceString('tdiv');
    if (name === '%=') return const SourceString('mod');
    if (name === '<<=') return const SourceString('shl');
    if (name === '>>=') return const SourceString('shr');
    if (name === '|=') return const SourceString('or');
    if (name === '&=') return const SourceString('and');
    if (name === '^=') return const SourceString('xor');
    if (name === '++') return const SourceString('add');
    if (name === '--') return const SourceString('sub');
    compiler.unimplemented('Unknown operator', node: op);
  }

  Element getStaticInterceptor(SourceString name, int parameters) {
    String mangledName = name.slowToString();
    Element element = compiler.findInterceptor(new SourceString(mangledName));
    if (element !== null && element.isFunction()) {
      // Only pick the function element with the short name if the
      // number of parameters it expects matches the number we're
      // passing modulo the receiver.
      FunctionElement function = element;
      if (function.parameterCount(compiler) == parameters + 1) return element;
    }
    String longMangledName = "$mangledName\$$parameters";
    return compiler.findInterceptor(new SourceString(longMangledName));
  }

  Element getStaticGetInterceptor(SourceString name) {
    String mangledName = "get\$${name.slowToString()}";
    return compiler.findInterceptor(new SourceString(mangledName));
  }

  Element getStaticSetInterceptor(SourceString name) {
    String mangledName = "set\$${name.slowToString()}";
    return compiler.findInterceptor(new SourceString(mangledName));
  }

  Element getOperatorInterceptor(Operator op) {
    SourceString name = mapOperatorToMethodName(op);
    return compiler.findHelper(name);
  }

  Element getBoolifiedVersionOf(Element interceptor) {
    if (interceptor === null) return interceptor;
    String boolifiedName = "${interceptor.name.slowToString()}B";
    return compiler.findHelper(new SourceString(boolifiedName));
  }

  Element getPrefixOperatorInterceptor(Operator op) {
    String name = op.source.stringValue;
    if (name === '~') {
      return compiler.findHelper(const SourceString('not'));
    }
    if (name === '-') {
      return compiler.findHelper(const SourceString('neg'));
    }
    compiler.unimplemented('Unknown operator', node: op);
  }

  Element getIndexInterceptor() {
    return compiler.findHelper(const SourceString('index'));
  }

  Element getIndexAssignmentInterceptor() {
    return compiler.findHelper(const SourceString('indexSet'));
  }

  Element getExceptionUnwrapper() {
    return compiler.findHelper(const SourceString('unwrapException'));
  }

  Element getClosureConverter() {
    return compiler.findHelper(const SourceString('convertDartClosureToJS'));
  }

  Element getTraceFromException() {
    return compiler.findHelper(const SourceString('getTraceFromException'));
  }

  Element getEqualsInterceptor() {
    return compiler.findHelper(const SourceString('eq'));
  }

  Element getTripleEqualsInterceptor() {
    return compiler.findHelper(const SourceString('eqq'));
  }

  Element getMapMaker() {
    return compiler.findHelper(const SourceString('makeLiteralMap'));
  }

  // TODO(karlklose): move these to different class or rename class?
  Element getSetRuntimeTypeInfo() {
    return compiler.findHelper(const SourceString('setRuntimeTypeInfo'));
  }

  Element getGetRuntimeTypeInfo() {
    return compiler.findHelper(const SourceString('getRuntimeTypeInfo'));
  }
}

class SsaBuilderTask extends CompilerTask {
  final Interceptors interceptors;
  final CodeEmitterTask emitter;
  // Loop tracking information.
  final Set<FunctionElement> functionsCalledInLoop;
  final Map<SourceString, Selector> selectorsCalledInLoop;
  final JavaScriptBackend backend;

  String get name => 'SSA builder';

  SsaBuilderTask(JavaScriptBackend backend)
    : interceptors = new Interceptors(backend.compiler),
      emitter = backend.emitter,
      functionsCalledInLoop = new Set<FunctionElement>(),
      selectorsCalledInLoop = new Map<SourceString, Selector>(),
      backend = backend,
      super(backend.compiler);

  HGraph build(WorkItem work) {
    return measure(() {
      FunctionElement element = work.element;
      HInstruction.idCounter = 0;
      SsaBuilder builder = new SsaBuilder(this, work);
      HGraph graph;
      ElementKind kind = element.kind;
      if (kind === ElementKind.GENERATIVE_CONSTRUCTOR) {
        graph = compileConstructor(builder, work);
      } else if (kind === ElementKind.GENERATIVE_CONSTRUCTOR_BODY ||
                 kind === ElementKind.FUNCTION ||
                 kind === ElementKind.GETTER ||
                 kind === ElementKind.SETTER) {
        graph = builder.buildMethod(work.element);
      }
      assert(graph.isValid());
      bool inLoop = functionsCalledInLoop.contains(element);
      if (!inLoop) {
        Selector selector = selectorsCalledInLoop[element.name];
        inLoop = selector !== null && selector.applies(element, compiler);
      }
      graph.calledInLoop = inLoop;

      // If there is an estimate of the parameter types assume these types when
      // compiling.
      List<HType> parameterTypes =
          backend.optimisticParameterTypesWithRecompilationOnTypeChange(
              element);
      if (parameterTypes != null) {
        // TODO(kasperl): Allow this also for static elements.
        if (element.isMember()) {
          backend.optimizedFunctions.add(element);
          backend.optimizedTypes[element] = parameterTypes;
        }
        FunctionSignature signature = element.computeSignature(compiler);
        int i = 0;
        signature.forEachParameter((Element param) {
          builder.parameters[param].guaranteedType = parameterTypes[i++];
        });
      } else {
        // TODO(kasperl): Allow this also for static elements.
        if (element.isMember()) {
          backend.optimizedFunctions.remove(element);
          backend.optimizedTypes.remove(element);
        }
      }

      if (compiler.tracer.enabled) {
        String name;
        if (element.isMember()) {
          String className = element.getEnclosingClass().name.slowToString();
          String memberName = element.name.slowToString();
          name = "$className.$memberName";
          if (element.kind == ElementKind.GENERATIVE_CONSTRUCTOR_BODY) {
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

  HGraph compileConstructor(SsaBuilder builder, WorkItem work) {
    // The body of the constructor will be generated in a separate function.
    final ClassElement classElement = work.element.getEnclosingClass();
    return builder.buildFactory(classElement, work.element);
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
    assert(redirectionMapping[from] === null);
    redirectionMapping[from] = to;
    assert(isStoredInClosureField(from) || isBoxed(from));
  }

  HInstruction createBox() {
    // TODO(floitsch): Clean up this hack. Should we create a box-object by
    // just creating an empty object literal?
    HInstruction box = new HForeign(const LiteralDartString("{}"),
                                    const LiteralDartString('Object'),
                                    <HInstruction>[]);
    builder.add(box);
    return box;
  }

  /**
   * If the scope (function or loop) [node] has captured variables then this
   * method creates a box and sets up the redirections.
   */
  void enterScope(Node node) {
    // See if any variable in the top-scope of the function is captured. If yes
    // we need to create a box-object.
    ClosureScope scopeData = closureData.capturingScopes[node];
    if (scopeData !== null) {
      // The scope has captured variables. Create a box.
      // TODO(floitsch): Clean up this hack. Should we create a box-object by
      // just creating an empty object literal?
      HInstruction box = createBox();
      // Add the box to the known locals.
      directLocals[scopeData.boxElement] = box;
      // Make sure that accesses to the boxed locals go into the box. We also
      // need to make sure that parameters are copied into the box if necessary.
      scopeData.capturedVariableMapping.forEach((Element from, Element to) {
        // The [from] can only be a parameter for function-scopes and not
        // loop scopes.
        if (from.kind == ElementKind.PARAMETER) {
          // Store the captured parameter in the box. Get the current value
          // before we put the redirection in place.
          HInstruction instruction = readLocal(from);
          redirectElement(from, to);
          // Now that the redirection is set up, the update to the local will
          // write the parameter value into the box.
          updateLocal(from, instruction);
        } else {
          redirectElement(from, to);
        }
      });
    }
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

  void startFunction(FunctionElement function,
                     FunctionExpression node) {
    Compiler compiler = builder.compiler;
    closureData = compiler.closureToClassMapper.computeClosureToClassMapping(
            node, builder.elements);

    FunctionSignature signature = function.computeSignature(compiler);
    signature.forEachParameter((Element element) {
      HInstruction parameter = new HParameterValue(element);
      builder.add(parameter);
      builder.parameters[element] = parameter;
      directLocals[element] = parameter;
      parameter.guaranteedType =
        builder.mapInferredType(typesTask.getGuaranteedTypeOfElement(element));
    });

    enterScope(node);

    // If the freeVariableMapping is not empty, then this function was a
    // nested closure that captures variables. Redirect the captured
    // variables to fields in the closure.
    closureData.freeVariableMapping.forEach((Element from, Element to) {
      redirectElement(from, to);
    });
    if (closureData.isClosure()) {
      // Inside closure redirect references to itself to [:this:].
      HInstruction thisInstruction = new HThis();
      builder.add(thisInstruction);
      updateLocal(closureData.closureElement, thisInstruction);
    } else if (function.isInstanceMember()
               || function.isGenerativeConstructor()) {
      // Once closures have been mapped to classes their instance members might
      // not have any thisElement if the closure was created inside a static
      // context.
      ClassElement cls = function.getEnclosingClass();
      Type type = cls.computeType(builder.compiler);
      HInstruction thisInstruction = new HThis(new HBoundedType.nonNull(type));
      builder.add(thisInstruction);
      directLocals[closureData.thisElement] = thisInstruction;
    }
  }

  bool hasValueForDirectLocal(Element element) {
    assert(element !== null);
    assert(isAccessedDirectly(element));
    return directLocals[element] !== null;
  }

  /**
   * Returns true if the local can be accessed directly. Boxed variables or
   * captured variables that are stored in the closure-field return [false].
   */
  bool isAccessedDirectly(Element element) {
    assert(element !== null);
    return redirectionMapping[element] === null
        && !closureData.usedVariablesInTry.contains(element);
  }

  bool isStoredInClosureField(Element element) {
    assert(element !== null);
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
    return redirectionMapping[element] !== null;
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
      builder.add(fieldGet);
      return fieldGet;
    } else if (isBoxed(element)) {
      Element redirect = redirectionMapping[element];
      // In the function that declares the captured variable the box is
      // accessed as direct local. Inside the nested closure the box is
      // accessed through a closure-field.
      // Calling [readLocal] makes sure we generate the correct code to get
      // the box.
      assert(redirect.enclosingElement.kind == ElementKind.VARIABLE);
      HInstruction box = readLocal(redirect.enclosingElement);
      HInstruction lookup = new HFieldGet(redirect, box);
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

  HType cachedTypeOfThis;

  HInstruction readThis() {
    HInstruction res = readLocal(closureData.thisElement);
    if (res.guaranteedType === null) {
      if (cachedTypeOfThis === null) {
        assert(closureData.isClosure());
        Element element = closureData.thisElement;
        ClassElement cls = element.enclosingElement.getEnclosingClass();
        Type type = cls.computeType(builder.compiler);
        cachedTypeOfThis = new HBoundedType.nonNull(type);
      }
      res.guaranteedType = cachedTypeOfThis;
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
      assert(redirect.enclosingElement.kind == ElementKind.VARIABLE);
      HInstruction box = readLocal(redirect.enclosingElement);
      builder.add(new HFieldSet(redirect, box, value));
    } else {
      assert(isUsedInTry(element));
      HLocalValue local = getLocal(element);
      builder.add(new HLocalSet(element, local, value));
    }
  }

  /**
   * This function must be called before visiting any children of the loop. In
   * particular it needs to be called before executing the initializers.
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
      enterScope(node);
    }
  }

  void beginLoopHeader(Node node, HBasicBlock loopEntry) {
    // Create a copy because we modify the map while iterating over
    // it.
    Map<Element, HInstruction> saved =
        new Map<Element, HInstruction>.from(directLocals);

    // Create phis for all elements in the definitions environment.
    saved.forEach((Element element, HInstruction instruction) {
      if (isAccessedDirectly(element)) {
        // We know 'this' cannot be modified.
        if (element !== closureData.thisElement) {
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
      enterScope(node);
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

  void endLoop(HBasicBlock loopEntry) {
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
    Map<Element, HInstruction> joinedLocals = new Map<Element, HInstruction>();
    otherLocals.directLocals.forEach((element, instruction) {
      // We know 'this' cannot be modified.
      if (element === closureData.thisElement) {
        assert(directLocals[element] == instruction);
        joinedLocals[element] = instruction;
      } else {
        HInstruction mine = directLocals[element];
        if (mine === null) return;
        if (instruction === mine) {
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
   * The current localsHandler is not used for its values, only for its
   * declared variables. This is a way to exclude local values from the
   * result when they are no longer in scope.
   * Returns the new LocalsHandler to use (may not be [this]).
   */
  LocalsHandler mergeMultiple(List<LocalsHandler> locals,
                              HBasicBlock joinBlock) {
    assert(locals.length > 0);
    if (locals.length == 1) return locals[0];
    Map<Element, HInstruction> joinedLocals = new Map<Element,HInstruction>();
    HInstruction thisValue = null;
    directLocals.forEach((Element element, HInstruction instruction) {
      if (element !== closureData.thisElement) {
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
    for (LocalsHandler local in locals) {
      local.directLocals.forEach((Element element, HInstruction instruction) {
        HPhi phi = joinedLocals[element];
        if (phi !== null) {
          phi.addInput(instruction);
        }
      });
    }
    if (thisValue !== null) {
      // If there was a "this" for the scope, add it to the new locals.
      joinedLocals[closureData.thisElement] = thisValue;
    }
    directLocals = joinedLocals;
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


interface JumpHandler default JumpHandlerImpl {
  JumpHandler(SsaBuilder builder, TargetElement target);
  void generateBreak([LabelElement label]);
  void generateContinue([LabelElement label]);
  void forEachBreak(void action(HBreak instruction, LocalsHandler locals));
  void forEachContinue(void action(HContinue instruction,
                                   LocalsHandler locals));
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
    // TODO(lrn): Need a compiler object and a location. Since label
    // is optional, it may be null so we also need a position.
    compiler.internalError('generateBreak should not be called');
  }

  void generateContinue([LabelElement label]) {
    // TODO(lrn): Need a compiler object and a location. Since label
    // is optional, it may be null so we also need a position.
    compiler.internalError('generateContinue should not be called');
  }

  void forEachBreak(Function ignored) { }
  void forEachContinue(Function ignored) { }
  void close() { }
  final TargetElement target = null;
  List<LabelElement> labels() => const <LabelElement>[];
}

// Records breaks until a target block is available.
// Breaks are always forward jumps.
// Continues in loops are implemented as breaks of the body.
// Continues in switches is currently not handled.
class JumpHandlerImpl implements JumpHandler {
  final SsaBuilder builder;
  final TargetElement target;
  final List<JumpHandlerEntry> jumps;

  JumpHandlerImpl(SsaBuilder builder, this.target)
      : this.builder = builder,
        jumps = <JumpHandlerEntry>[] {
    assert(builder.jumpTargets[target] === null);
    builder.jumpTargets[target] = this;
  }

  void generateBreak([LabelElement label]) {
    HInstruction breakInstruction;
    if (label === null) {
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
    if (label === null) {
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

  void close() {
    // The mapping from TargetElement to JumpHandler is no longer needed.
    builder.jumpTargets.remove(target);
  }

  List<LabelElement> labels() {
    List<LabelElement> result = null;
    for (LabelElement element in target.labels) {
      if (result === null) result = <LabelElement>[];
      result.add(element);
    }
    return (result === null) ? const <LabelElement>[] : result;
  }
}

class SsaBuilder extends ResolvedVisitor implements Visitor {
  final SsaBuilderTask builder;
  final Interceptors interceptors;
  final WorkItem work;
  bool methodInterceptionEnabled;
  HGraph graph;
  LocalsHandler localsHandler;
  HInstruction rethrowableException;
  Map<Element, HParameterValue> parameters;

  Map<TargetElement, JumpHandler> jumpTargets;

  /**
   * Variables stored in the current activation. These variables are
   * being updated in try/catch blocks, and should be
   * accessed indirectly through HFieldGet and HFieldSet.
   */
  Map<Element, HLocalValue> activationVariables;

  // We build the Ssa graph by simulating a stack machine.
  List<HInstruction> stack;

  // The current block to add instructions to. Might be null, if we are
  // visiting dead code.
  HBasicBlock current;
  // The most recently opened block. Has the same value as [current] while
  // the block is open, but unlike [current], it isn't cleared when the current
  // block is closed.
  HBasicBlock lastOpenedBlock;

  LibraryElement get currentLibrary => work.element.getLibrary();
  Compiler get compiler => builder.compiler;
  CodeEmitterTask get emitter => builder.emitter;

  SsaBuilder(SsaBuilderTask builder, WorkItem work)
    : this.builder = builder,
      this.work = work,
      interceptors = builder.interceptors,
      methodInterceptionEnabled = true,
      graph = new HGraph(),
      stack = new List<HInstruction>(),
      activationVariables = new Map<Element, HLocalValue>(),
      jumpTargets = new Map<TargetElement, JumpHandler>(),
      parameters = new Map<Element, HParameterValue>(),
      inliningStack = <InliningState>[],
      super(work.resolutionTree) {
    localsHandler = new LocalsHandler(this);
  }

  static const MAX_INLINING_DEPTH = 3;
  static const MAX_INLINING_SOURCE_SIZE = 100;
  List<InliningState> inliningStack;
  Element returnElement = null;

  void disableMethodInterception() {
    assert(methodInterceptionEnabled);
    methodInterceptionEnabled = false;
  }

  void enableMethodInterception() {
    assert(!methodInterceptionEnabled);
    methodInterceptionEnabled = true;
  }

  HGraph buildMethod(FunctionElement functionElement) {
    FunctionExpression function = functionElement.parseNode(compiler);
    openFunction(functionElement, function);
    function.body.accept(this);
    return closeFunction();
  }

  /**
   * Returns the constructor body associated with the given constructor or
   * creates a new constructor body, if none can be found.
   *
   * Returns [:null:] if the constructor does not have a body.
   */
  ConstructorBodyElement getConstructorBody(FunctionElement constructor) {
    assert(constructor.kind === ElementKind.GENERATIVE_CONSTRUCTOR);
    if (constructor is SynthesizedConstructorElement) return null;
    FunctionExpression node = constructor.parseNode(compiler);
    // If we know the body doesn't have any code, we don't generate
    // it.
    if (node.body.asBlock() !== null) {
      NodeList statements = node.body.asBlock().statements;
      if (statements.isEmpty()) return null;
    }
    ClassElement classElement = constructor.getEnclosingClass();
    ConstructorBodyElement bodyElement;
    for (Link<Element> backendMembers = classElement.backendMembers;
         !backendMembers.isEmpty();
         backendMembers = backendMembers.tail) {
      Element backendMember = backendMembers.head;
      if (backendMember.kind == ElementKind.GENERATIVE_CONSTRUCTOR_BODY) {
        ConstructorBodyElement body = backendMember;
        if (body.constructor == constructor) {
          bodyElement = backendMember;
          break;
        }
      }
    }
    if (bodyElement === null) {
      bodyElement = new ConstructorBodyElement(constructor);
      TreeElements treeElements =
          compiler.resolver.resolveMethodElement(constructor);
      compiler.enqueuer.codegen.addToWorkList(bodyElement, treeElements);
      classElement.backendMembers =
          classElement.backendMembers.prepend(bodyElement);
    }
    assert(bodyElement.kind === ElementKind.GENERATIVE_CONSTRUCTOR_BODY);
    return bodyElement;
  }

  InliningState enterInlinedMethod(PartialFunctionElement function,
                                   Selector selector,
                                   Link<Node> arguments) {
    // Once we start to compile the arguments we must be sure that we don't
    // abort.
    List<HInstruction> compiledArguments = new List<HInstruction>();
    bool succeeded = addStaticSendArgumentsToList(selector,
                                                  arguments,
                                                  function,
                                                  compiledArguments);
    assert(succeeded);

    InliningState state =
        new InliningState(function, returnElement, elements, stack);
    inliningStack.add(state);
    stack = <HInstruction>[];
    returnElement = new Element(const SourceString("result"),
                                ElementKind.VARIABLE,
                                function);
    localsHandler.updateLocal(returnElement, graph.addConstantNull());
    elements = compiler.enqueuer.resolution.getCachedElements(function);
    FunctionSignature signature = function.computeSignature(compiler);
    int index = 0;
    signature.forEachParameter((Element parameter) {
      HInstruction argument = compiledArguments[index++];
      localsHandler.updateLocal(parameter, argument);
      potentiallyCheckType(argument, parameter);
    });
    return state;
  }

  void leaveInlinedMethod(InliningState state) {
    InliningState poppedState = inliningStack.removeLast();
    assert(state == poppedState);
    elements = state.oldElements;
    stack.add(localsHandler.readLocal(returnElement));
    returnElement = state.oldReturnElement;
    assert(stack.length == 1);
    state.oldStack.add(stack[0]);
    stack = state.oldStack;
  }

  bool tryInlineMethod(Element element,
                       Selector selector,
                       Link<Node> arguments) {
    if (element.kind != ElementKind.FUNCTION) return false;
    if (element is !PartialFunctionElement) return false;
    if (inliningStack.length > MAX_INLINING_DEPTH) return false;
    // Don't inline recursive calls. We use the same elements for the inlined
    // functions and would thus clobber our local variables.
    if (work.element == element) return false;
    for (int i = 0; i < inliningStack.length; i++) {
      if (inliningStack[i].function == element) return false;
    }
    // TODO(ngeoffray): Inlining currently does not work in the presence of
    // private calls.
    if (currentLibrary != element.getLibrary()) return false;
    PartialFunctionElement function = element;
    int sourceSize =
        function.endToken.charOffset - function.beginToken.charOffset;
    if (sourceSize > MAX_INLINING_SOURCE_SIZE) return false;
    if (!selector.applies(function, compiler)) return false;
    FunctionExpression functionExpression = function.parseNode(compiler);
    TreeElements newElements =
        compiler.enqueuer.resolution.getCachedElements(function);
    if (newElements === null) {
      compiler.internalError("Element not resolved: $function");
    }
    if (!InlineWeeder.canBeInlined(functionExpression, newElements)) {
      return false;
    }

    InliningState state = enterInlinedMethod(function, selector, arguments);
    functionExpression.body.accept(this);
    leaveInlinedMethod(state);
    return true;
  }

  void inlineSuperOrRedirect(FunctionElement constructor,
                             Selector selector,
                             Link<Node> arguments,
                             List<FunctionElement> constructors,
                             Map<Element, HInstruction> fieldValues) {
    constructors.addLast(constructor);

    List<HInstruction> compiledArguments = new List<HInstruction>();
    bool succeeded = addStaticSendArgumentsToList(selector,
                                                  arguments,
                                                  constructor,
                                                  compiledArguments);
    if (!succeeded) {
      // Non-matching super and redirects are compile-time errors and thus
      // checked by the resolver.
      compiler.internalError(
          "Parameters and arguments didn't match for super/redirect call",
          element: constructor);
    }

    buildFieldInitializers(constructor.enclosingElement, fieldValues);

    int index = 0;
    FunctionSignature params = constructor.computeSignature(compiler);
    params.forEachParameter((Element parameter) {
      HInstruction argument = compiledArguments[index++];
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
    elements = compiler.resolver.resolveMethodElement(constructor);
    buildInitializers(constructor, constructors, fieldValues);
    elements = oldElements;
  }

  /**
   * Run through the initializers and inline all field initializers. Recursively
   * inlines super initializers.
   *
   * The constructors of the inlined initializers is added to [constructors]
   * with sub constructors having a lower index than super constructors.
   */
  void buildInitializers(FunctionElement constructor,
                         List<FunctionElement> constructors,
                         Map<Element, HInstruction> fieldValues) {
    FunctionExpression functionNode = constructor.parseNode(compiler);

    bool foundSuperOrRedirect = false;

    if (functionNode.initializers !== null) {
      Link<Node> initializers = functionNode.initializers.nodes;
      for (Link<Node> link = initializers; !link.isEmpty(); link = link.tail) {
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
                                fieldValues);
          foundSuperOrRedirect = true;
        } else {
          // A field initializer.
          SendSet init = link.head;
          Link<Node> arguments = init.arguments;
          assert(!arguments.isEmpty() && arguments.tail.isEmpty());
          visit(arguments.head);
          fieldValues[elements[init]] = pop();
        }
      }
    }

    if (!foundSuperOrRedirect) {
      // No super initializer found. Try to find the default constructor if
      // the class is not Object.
      ClassElement enclosingClass = constructor.getEnclosingClass();
      ClassElement superClass = enclosingClass.superclass;
      if (enclosingClass != compiler.objectClass) {
        assert(superClass !== null);
        assert(superClass.resolutionState == STATE_DONE);
        Selector selector =
            new Selector.call(superClass.name, enclosingClass.getLibrary(), 0);
        FunctionElement target = superClass.lookupConstructor(superClass.name);
        if (target === null) {
          compiler.internalError("no default constructor available");
        }
        inlineSuperOrRedirect(target,
                              selector,
                              const EmptyLink<Node>(),
                              constructors,
                              fieldValues);
      }
    }
  }

  /**
   * Run through the fields of [cls] and add their potential
   * initializers.
   */
  void buildFieldInitializers(ClassElement classElement,
                              Map<Element, HInstruction> fieldValues) {
    classElement.forEachInstanceField(
        includeBackendMembers: true,
        includeSuperMembers: false,
        f: (ClassElement enclosingClass, Element member) {
      TreeElements definitions = compiler.analyzeElement(member);
      Node node = member.parseNode(compiler);
      SendSet assignment = node.asSendSet();
      HInstruction value;
      if (assignment === null) {
        value = graph.addConstantNull();
      } else {
        Node right = assignment.arguments.head;
        TreeElements savedElements = elements;
        elements = definitions;
        right.accept(this);
        elements = savedElements;
        value = pop();
      }
      fieldValues[member] = value;
    });
  }


  /**
   * Build the factory function corresponding to the constructor
   * [functionElement]:
   *  - Initialize fields with the values of the field initializers of the
   *    current constructor and super constructors or constructors redirected
   *    to, starting from the current constructor.
   *  - Call the the constructor bodies, starting from the constructor(s) in the
   *    super class(es).
   */
  HGraph buildFactory(ClassElement classElement,
                      FunctionElement functionElement) {
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
    params.forEachParameter((Element element) {
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
        includeBackendMembers: true,
        includeSuperMembers: true,
        f: (ClassElement enclosingClass, Element member) {
      constructorArguments.add(fieldValues[member]);
    });

    HForeignNew newObject = new HForeignNew(classElement, constructorArguments);
    add(newObject);
    // Generate calls to the constructor bodies.
    for (int index = constructors.length - 1; index >= 0; index--) {
      FunctionElement constructor = constructors[index];
      ConstructorBodyElement body = getConstructorBody(constructor);
      if (body === null) continue;
      List bodyCallInputs = <HInstruction>[];
      bodyCallInputs.add(newObject);
      int arity = body.functionSignature.parameterCount;
      body.functionSignature.forEachParameter((parameter) {
        bodyCallInputs.add(localsHandler.readLocal(parameter));
      });
      // TODO(ahe): The constructor name is statically resolved. See
      // SsaCodeGenerator.visitInvokeDynamicMethod. Is there a cleaner
      // way to do this?
      SourceString name = new SourceString(compiler.namer.getName(body));
      // TODO(kasperl): This seems fishy. We shouldn't be inventing all
      // these selectors. Maybe the resolver can do more of the work
      // for us here?
      LibraryElement library = body.getLibrary();
      Selector selector = new Selector.call(name, library, arity);
      add(new HInvokeDynamicMethod(selector, bodyCallInputs));
    }
    close(new HReturn(newObject)).addSuccessor(graph.exit);
    return closeFunction();
  }

  void openFunction(FunctionElement functionElement,
                    FunctionExpression node) {
    HBasicBlock block = graph.addNewBlock();
    open(graph.entry);

    localsHandler.startFunction(functionElement, node);
    close(new HGoto()).addSuccessor(block);

    open(block);

    // Put the type checks in the first successor of the entry,
    // because that is where the type guards will also be inserted.
    // This way we ensure that a type guard will dominate the type
    // check.
    FunctionSignature params = functionElement.computeSignature(compiler);
    params.forEachParameter((Element element) {
      HInstruction newParameter = potentiallyCheckType(
          localsHandler.directLocals[element], element);
      localsHandler.directLocals[element] = newParameter;
    });
  }

  HInstruction potentiallyCheckType(HInstruction original,
                                    Element sourceElement) {
    if (!compiler.enableTypeAssertions) return original;
    return convertType(original, sourceElement,
                       HTypeConversion.CHECKED_MODE_CHECK);
  }

  HInstruction convertType(HInstruction original,
                           Element sourceElement,
                           int kind) {
    Type type = sourceElement.computeType(compiler);
    if (type === null) return original;
    if (type.element === compiler.dynamicClass) return original;
    if (type.element === compiler.objectClass) return original;

    // If the original can't be null, type conversion also can't produce null.
    bool canBeNull = original.guaranteedType.canBeNull();
    HType convertedType =
        new HType.fromBoundedType(type, compiler, canBeNull);

    // No need to convert if we know the instruction has
    // [convertedType] as a bound.
    if (original.guaranteedType == convertedType) {
      return original;
    }

    HInstruction instruction =
        new HTypeConversion(convertedType, original, kind);
    add(instruction);
    return instruction;
  }

  HGraph closeFunction() {
    // TODO(kasperl): Make this goto an implicit return.
    if (!isAborted()) close(new HGoto()).addSuccessor(graph.exit);
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

  void goto(HBasicBlock from, HBasicBlock to) {
    from.close(new HGoto());
    from.addSuccessor(to);
  }

  bool isAborted() {
    return current === null;
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
    stack.add(stack.last());
  }

  HBoolify popBoolified() {
    HBoolify boolified = new HBoolify(pop());
    add(boolified);
    return boolified;
  }

  HInstruction attachPosition(HInstruction target, Node node) {
    target.sourcePosition = node.getBeginToken();
    return target;
  }

  void visit(Node node) {
    if (node !== null) node.accept(this);
  }

  visitBlock(Block node) {
    for (Link<Node> link = node.statements.nodes;
         !link.isEmpty();
         link = link.tail) {
      visit(link.head);
      if (isAborted()) {
        // The block has been aborted by a return or a throw.
        if (!stack.isEmpty()) compiler.cancel('non-empty instruction stack');
        return;
      }
    }
    assert(!current.isClosed());
    if (!stack.isEmpty()) compiler.cancel('non-empty instruction stack');
  }

  visitClassNode(ClassNode node) {
    compiler.internalError('visitClassNode should not be called', node: node);
  }

  visitExpressionStatement(ExpressionStatement node) {
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

    localsHandler.beginLoopHeader(node, loopEntry);
    return jumpHandler;
  }

  /**
   * Ends the loop:
   * - creates a new block and adds it as successor to the [branchBlock].
   * - opens the new block (setting as [current]).
   * - notifies the locals handler that we're exiting a loop.
   */
  void endLoop(HBasicBlock loopEntry,
               HBasicBlock branchBlock,
               JumpHandler jumpHandler,
               LocalsHandler savedLocals) {
    HBasicBlock loopExitBlock = addNewBlock();
    assert(branchBlock.successors.length == 1);
    List<LocalsHandler> breakLocals = <LocalsHandler>[];
    jumpHandler.forEachBreak((HBreak breakInstruction, LocalsHandler locals) {
      breakInstruction.block.addSuccessor(loopExitBlock);
      breakLocals.add(locals);
    });
    branchBlock.addSuccessor(loopExitBlock);
    open(loopExitBlock);
    localsHandler.endLoop(loopEntry);
    if (!breakLocals.isEmpty()) {
      breakLocals.add(savedLocals);
      localsHandler = savedLocals.mergeMultiple(breakLocals, loopExitBlock);
    } else {
      localsHandler = savedLocals;
    }
  }

  HSubGraphBlockInformation wrapStatementGraph(SubGraph statements) {
    if (statements === null) return null;
    return new HSubGraphBlockInformation(statements);
  }

  HSubExpressionBlockInformation wrapExpressionGraph(SubExpression expression) {
    if (expression === null) return null;
    return new HSubExpressionBlockInformation(expression);
  }

  // For while loops, initializer and update are null.
  // The condition function must return a boolean result.
  // None of the functions must leave anything on the stack.
  handleLoop(Node loop,
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
    if (initialize !== null) {
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
    if (startBlock === null) startBlock = conditionBlock;

    HInstruction conditionInstruction = condition();
    HBasicBlock conditionExitBlock =
        close(new HLoopBranch(conditionInstruction));
    SubExpression conditionExpression =
        new SubExpression(conditionBlock, conditionExitBlock);

    LocalsHandler savedLocals = new LocalsHandler.from(localsHandler);

    // The body.
    HBasicBlock beginBodyBlock = addNewBlock();
    conditionExitBlock.addSuccessor(beginBodyBlock);
    open(beginBodyBlock);

    localsHandler.enterLoopBody(loop);
    hackAroundPossiblyAbortingBody(loop, body);

    SubGraph bodyGraph = new SubGraph(beginBodyBlock, current);
    HBasicBlock bodyBlock = close(new HGoto());

    // Update.
    // We create an update block, even when we are in a while loop. There the
    // update block is the jump-target for continue statements. We could avoid
    // the creation if there is no continue, but for now we always create it.
    HBasicBlock updateBlock = addNewBlock();

    List<LocalsHandler> continueLocals = <LocalsHandler>[];
    jumpHandler.forEachContinue((HContinue instruction, LocalsHandler locals) {
      instruction.block.addSuccessor(updateBlock);
      continueLocals.add(locals);
    });
    bodyBlock.addSuccessor(updateBlock);
    continueLocals.add(localsHandler);

    open(updateBlock);

    localsHandler = localsHandler.mergeMultiple(continueLocals, updateBlock);

    HLabeledBlockInformation labelInfo;
    List<LabelElement> labels = jumpHandler.labels();
    TargetElement target = elements[loop];
    if (!labels.isEmpty()) {
      beginBodyBlock.setBlockFlow(
          new HLabeledBlockInformation(
              new HSubGraphBlockInformation(bodyGraph),
              jumpHandler.labels(),
              isContinue: true),
          updateBlock);
    } else if (target !== null && target.isContinueTarget) {
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
    conditionBlock.postProcessLoopHeader();
    SubExpression updateGraph = new SubExpression(updateBlock, updateEndBlock);

    endLoop(conditionBlock, conditionExitBlock, jumpHandler, savedLocals);
    HLoopBlockInformation info =
        new HLoopBlockInformation(
            HLoopBlockInformation.loopType(loop),
            wrapExpressionGraph(initializerGraph),
            wrapExpressionGraph(conditionExpression),
            wrapStatementGraph(bodyGraph),
            wrapExpressionGraph(updateGraph),
            conditionBlock.loopInformation.target,
            conditionBlock.loopInformation.labels,
            loop);

    startBlock.setBlockFlow(info, current);
    loopInfo.loopBlockInformation = info;
  }

  visitFor(For node) {
    assert(node.body !== null);
    void buildInitializer() {
      if (node.initializer === null) return;
      Node initializer = node.initializer;
      if (initializer !== null) {
        visit(initializer);
        if (initializer.asExpression() !== null) {
          pop();
        }
      }
    }
    HInstruction buildCondition() {
      if (node.condition === null) {
        return graph.addConstantBool(true);
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
    LocalsHandler savedLocals = new LocalsHandler.from(localsHandler);
    localsHandler.startLoop(node);
    JumpHandler jumpHandler = beginLoopHeader(node);
    HLoopInformation loopInfo = current.loopInformation;
    HBasicBlock loopEntryBlock = current;
    HBasicBlock bodyEntryBlock = current;
    TargetElement target = elements[node];
    bool hasContinues = target !== null && target.isContinueTarget;
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
    hackAroundPossiblyAbortingBody(node, () { visit(node.body); });

    // If there are no continues we could avoid the creation of the condition
    // block. This could also lead to a block having multiple entries and exits.
    HBasicBlock bodyExitBlock = close(new HGoto());
    HBasicBlock conditionBlock = addNewBlock();

    List<LocalsHandler> continueLocals = <LocalsHandler>[];
    jumpHandler.forEachContinue((HContinue instruction, LocalsHandler locals) {
      instruction.block.addSuccessor(conditionBlock);
      continueLocals.add(locals);
    });
    bodyExitBlock.addSuccessor(conditionBlock);
    if (!continueLocals.isEmpty()) {
      continueLocals.add(localsHandler);
      localsHandler = savedLocals.mergeMultiple(continueLocals, conditionBlock);
      SubGraph bodyGraph = new SubGraph(bodyEntryBlock, bodyExitBlock);
      List<LabelElement> labels = jumpHandler.labels();
      HSubGraphBlockInformation bodyInfo =
          new HSubGraphBlockInformation(bodyGraph);
      HLabeledBlockInformation info;
      if (!labels.isEmpty()) {
        info = new HLabeledBlockInformation(bodyInfo, labels, isContinue: true);
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
    HBasicBlock conditionEndBlock =
        close(new HLoopBranch(conditionInstruction, HLoopBranch.DO_WHILE_LOOP));

    conditionEndBlock.addSuccessor(loopEntryBlock);  // The back-edge.
    loopEntryBlock.postProcessLoopHeader();

    endLoop(loopEntryBlock, conditionEndBlock, jumpHandler, localsHandler);
    jumpHandler.close();

    SubExpression conditionExpression =
        new SubExpression(conditionBlock, conditionEndBlock);
    SubGraph bodyGraph = new SubGraph(bodyEntryBlock, bodyExitBlock);

    HLoopBlockInformation loopBlockInfo =
        new HLoopBlockInformation(
            HLoopBlockInformation.DO_WHILE_LOOP,
            null,
            wrapExpressionGraph(conditionExpression),
            wrapStatementGraph(bodyGraph),
            null,
            loopEntryBlock.loopInformation.target,
            loopEntryBlock.loopInformation.labels,
            node);
    loopEntryBlock.setBlockFlow(loopBlockInfo, current);
    loopInfo.loopBlockInformation = loopBlockInfo;
  }

  visitFunctionExpression(FunctionExpression node) {
    ClosureClassMap nestedClosureData =
        compiler.closureToClassMapper.getMappingForNestedFunction(node);
    assert(nestedClosureData !== null);
    assert(nestedClosureData.closureClassElement !== null);
    ClassElement closureClassElement =
        nestedClosureData.closureClassElement;
    FunctionElement callElement = nestedClosureData.callElement;
    // TODO(ahe): This should be registered in codegen, not here.
    compiler.enqueuer.codegen.addToWorkList(callElement, elements);
    // TODO(ahe): This should be registered in codegen, not here.
    compiler.enqueuer.codegen.registerInstantiatedClass(closureClassElement);
    assert(closureClassElement.localScope.isEmpty());

    List<HInstruction> capturedVariables = <HInstruction>[];
    for (Element member in closureClassElement.backendMembers) {
      // The backendMembers also contains the call method(s). We are only
      // interested in the fields.
      if (member.kind == ElementKind.FIELD) {
        Element capturedLocal = nestedClosureData.capturedFieldMapping[member];
        assert(capturedLocal != null);
        capturedVariables.add(localsHandler.readLocal(capturedLocal));
      }
    }

    push(new HForeignNew(closureClassElement, capturedVariables));
  }

  visitFunctionDeclaration(FunctionDeclaration node) {
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
    assert(node.argumentsNode is Prefix);
    visit(node.receiver);
    assert(op.token.kind !== PLUS_TOKEN);
    HInstruction operand = pop();

    HInstruction target =
        new HStatic(interceptors.getPrefixOperatorInterceptor(op));
    add(target);
    HInvokeUnary result;
    String value = op.source.stringValue;
    switch (value) {
      case "-": result = new HNegate(target, operand); break;
      case "~": result = new HBitNot(target, operand); break;
      default:
        compiler.internalError('Unexpected unary operator: $value.', node: op);
        break;
    }
    // See if we can constant-fold right away. This avoids rewrites later on.
    if (operand is HConstant) {
      HConstant constant = operand;
      Constant folded = result.operation.fold(constant.constant);
      if (folded !== null) {
        stack.add(graph.addConstant(folded));
        return;
      }
    }
    pushWithPosition(result, node);
  }

  void visitBinary(HInstruction left, Operator op, HInstruction right) {
    Element element = interceptors.getOperatorInterceptor(op);
    assert(element != null);
    HInstruction target = new HStatic(element);
    add(target);
    switch (op.source.stringValue) {
      case "+":
      case "++":
      case "+=":
        pushWithPosition(new HAdd(target, left, right), op);
        break;
      case "-":
      case "--":
      case "-=":
        pushWithPosition(new HSubtract(target, left, right), op);
        break;
      case "*":
      case "*=":
        pushWithPosition(new HMultiply(target, left, right), op);
        break;
      case "/":
      case "/=":
        pushWithPosition(new HDivide(target, left, right), op);
        break;
      case "~/":
      case "~/=":
        pushWithPosition(new HTruncatingDivide(target, left, right), op);
        break;
      case "%":
      case "%=":
        pushWithPosition(new HModulo(target, left, right), op);
        break;
      case "<<":
      case "<<=":
        pushWithPosition(new HShiftLeft(target, left, right), op);
        break;
      case ">>":
      case ">>=":
        pushWithPosition(new HShiftRight(target, left, right), op);
        break;
      case "|":
      case "|=":
        pushWithPosition(new HBitOr(target, left, right), op);
        break;
      case "&":
      case "&=":
        pushWithPosition(new HBitAnd(target, left, right), op);
        break;
      case "^":
      case "^=":
        pushWithPosition(new HBitXor(target, left, right), op);
        break;
      case "==":
        pushWithPosition(new HEquals(target, left, right), op);
        break;
      case "===":
        pushWithPosition(new HIdentity(target, left, right), op);
        break;
      case "!==":
        HIdentity eq = new HIdentity(target, left, right);
        add(eq);
        pushWithPosition(new HNot(eq), op);
        break;
      case "<":
        pushWithPosition(new HLess(target, left, right), op);
        break;
      case "<=":
        pushWithPosition(new HLessEqual(target, left, right), op);
        break;
      case ">":
        pushWithPosition(new HGreater(target, left, right), op);
        break;
      case ">=":
        pushWithPosition(new HGreaterEqual(target, left, right), op);
        break;
      case "!=":
        HEquals eq = new HEquals(target, left, right);
        add(eq);
        HBoolify bl = new HBoolify(eq);
        add(bl);
        pushWithPosition(new HNot(bl), op);
        break;
      default: compiler.unimplemented("SsaBuilder.visitBinary");
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

  void generateInstanceGetterWithCompiledReceiver(Send send,
                                                  HInstruction receiver) {
    assert(Elements.isInstanceSend(send, elements));
    // TODO(kasperl): This is a convoluted way of checking if we're
    // generating code for a compound assignment. If we are, we need
    // to get the selector from the mapping for the AST selector node.
    Selector selector = (send.asSendSet() === null)
        ? elements.getSelector(send)
        : elements.getSelector(send.selector);
    assert(selector.isGetter());
    SourceString getterName = selector.name;
    Element staticInterceptor = null;
    if (methodInterceptionEnabled) {
      staticInterceptor = interceptors.getStaticGetInterceptor(getterName);
    }
    if (staticInterceptor != null) {
      HStatic target = new HStatic(staticInterceptor);
      add(target);
      List<HInstruction> inputs = <HInstruction>[target, receiver];
      push(new HInvokeInterceptor(selector, inputs));
    } else {
      push(new HInvokeDynamicGetter(selector, null, receiver));
    }
  }

  void generateGetter(Send send, Element element) {
    if (Elements.isStaticOrTopLevelField(element)) {
      if (element.kind == ElementKind.FIELD && !element.isAssignable()) {
        // A static const. Get its constant value and inline it.
        Constant value = compiler.constantHandler.compileVariable(element);
        stack.add(graph.addConstant(value));
      } else {
        push(new HStatic(element));
        if (element.kind == ElementKind.GETTER) {
          push(new HInvokeStatic(<HInstruction>[pop()]));
        }
      }
    } else if (Elements.isInstanceSend(send, elements)) {
      HInstruction receiver = generateInstanceSendReceiver(send);
      generateInstanceGetterWithCompiledReceiver(send, receiver);
    } else if (Elements.isStaticOrTopLevelFunction(element)) {
      push(new HStatic(element));
      // TODO(ahe): This should be registered in codegen.
      compiler.enqueuer.codegen.registerGetOfStaticFunction(element);
    } else {
      stack.add(localsHandler.readLocal(element));
    }
  }

  void generateInstanceSetterWithCompiledReceiver(Send send,
                                                  HInstruction receiver,
                                                  HInstruction value) {
    assert(Elements.isInstanceSend(send, elements));
    Selector selector = elements.getSelector(send);
    assert(selector.isSetter());
    SourceString setterName = selector.name;
    Element staticInterceptor = null;
    if (methodInterceptionEnabled) {
      staticInterceptor = interceptors.getStaticSetInterceptor(setterName);
    }
    if (staticInterceptor != null) {
      HStatic target = new HStatic(staticInterceptor);
      add(target);
      List<HInstruction> inputs = <HInstruction>[target, receiver, value];
      add(new HInvokeInterceptor(selector, inputs));
    } else {
      add(new HInvokeDynamicSetter(selector, null, receiver, value));
    }
    stack.add(value);
  }

  void generateSetter(SendSet send, Element element, HInstruction value) {
    if (Elements.isStaticOrTopLevelField(element)) {
      if (element.kind == ElementKind.SETTER) {
        HStatic target = new HStatic(element);
        add(target);
        add(new HInvokeStatic(<HInstruction>[target, value]));
      } else {
        add(new HStaticStore(element, value));
      }
      stack.add(value);
    } else if (element === null || Elements.isInstanceField(element)) {
      HInstruction receiver = generateInstanceSendReceiver(send);
      generateInstanceSetterWithCompiledReceiver(send, receiver, value);
    } else {
      stack.add(value);
      // If the value does not already have a name, give it here.
      if (value.sourceElement === null) {
        value.sourceElement = element;
      }
      HInstruction checked = potentiallyCheckType(value, element);
      if (checked !== value) {
        pop();
        stack.add(checked);
      }
      localsHandler.updateLocal(element, checked);
    }
  }

  void pushInvokeHelper0(Element helper) {
    HInstruction reference = new HStatic(helper);
    add(reference);
    List<HInstruction> inputs = <HInstruction>[reference];
    HInstruction result = new HInvokeStatic(inputs);
    push(result);
  }

  void pushInvokeHelper1(Element helper, HInstruction a0) {
    HInstruction reference = new HStatic(helper);
    add(reference);
    List<HInstruction> inputs = <HInstruction>[reference, a0];
    HInstruction result = new HInvokeStatic(inputs);
    push(result);
  }

  void pushInvokeHelper2(Element helper, HInstruction a0, HInstruction a1) {
    HInstruction reference = new HStatic(helper);
    add(reference);
    List<HInstruction> inputs = <HInstruction>[reference, a0, a1];
    HInstruction result = new HInvokeStatic(inputs);
    push(result);
  }

  void pushInvokeHelper3(Element helper, HInstruction a0, HInstruction a1,
                         HInstruction a2) {
    HInstruction reference = new HStatic(helper);
    add(reference);
    List<HInstruction> inputs = <HInstruction>[reference, a0, a1, a2];
    HInstruction result = new HInvokeStatic(inputs);
    push(result);
  }

  visitOperatorSend(node) {
    assert(node.selector is Operator);
    if (!methodInterceptionEnabled) {
      visitDynamicSend(node);
      return;
    }

    Operator op = node.selector;
    if (const SourceString("[]") == op.source) {
      HStatic target = new HStatic(interceptors.getIndexInterceptor());
      add(target);
      visit(node.receiver);
      HInstruction receiver = pop();
      visit(node.argumentsNode);
      HInstruction index = pop();
      push(new HIndex(target, receiver, index));
    } else if (const SourceString("&&") == op.source ||
               const SourceString("||") == op.source) {
      visitLogicalAndOr(node, op);
    } else if (const SourceString("!") == op.source) {
      visitLogicalNot(node);
    } else if (node.argumentsNode is Prefix) {
      visitUnary(node, op);
    } else if (const SourceString("is") == op.source) {
      visit(node.receiver);
      HInstruction expression = pop();
      Node argument = node.arguments.head;
      TypeAnnotation typeAnnotation = argument.asTypeAnnotation();
      bool isNot = false;
      // TODO(ngeoffray): Duplicating pattern in resolver. We should
      // add a new kind of node.
      if (typeAnnotation == null) {
        typeAnnotation = argument.asSend().receiver;
        isNot = true;
      }

      Type type = elements.getType(typeAnnotation);
      HInstruction typeInfo = null;
      if (compiler.codegenWorld.rti.hasTypeArguments(type)) {
        pushInvokeHelper1(interceptors.getGetRuntimeTypeInfo(), expression);
        typeInfo = pop();
      }
      if (type.element.kind === ElementKind.TYPE_VARIABLE) {
        // TODO(karlklose): We emulate the behavior of the old frog
        // compiler and answer true to any is check involving a type variable
        // -- both is T and is !T -- until we have a proper implementation of
        // reified generics.
        stack.add(graph.addConstantBool(true));
      } else {
        HInstruction instruction;
        if (typeInfo !== null) {
          instruction = new HIs.withTypeInfoCall(type, expression, typeInfo);
        } else {
          instruction = new HIs(type, expression);
        }
        if (isNot) {
          add(instruction);
          instruction = new HNot(instruction);
        }
        push(instruction);
      }
    } else if (const SourceString("as") == op.source) {
      visit(node.receiver);
      HInstruction expression = pop();
      Node argument = node.arguments.head;
      TypeAnnotation typeAnnotation = argument.asTypeAnnotation();
      Type type = elements.getType(typeAnnotation);
      HInstruction converted = convertType(expression, type.element,
                                           HTypeConversion.CAST_TYPE_CHECK);
      stack.add(converted);
    } else {
      visit(node.receiver);
      visit(node.argumentsNode);
      var right = pop();
      var left = pop();
      visitBinary(left, op, right);
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
      Map<SourceString, HInstruction> instructions =
          new Map<SourceString, HInstruction>();
      List<SourceString> namedArguments = selector.namedArguments;
      int nameIndex = 0;
      for (; !arguments.isEmpty(); arguments = arguments.tail) {
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
   */
  bool addStaticSendArgumentsToList(Selector selector,
                                    Link<Node> arguments,
                                    FunctionElement element,
                                    List<HInstruction> list) {
    HInstruction compileArgument(Node argument) {
      visit(argument);
      return pop();
    }

    HInstruction compileConstant(Element constantElement) {
      Constant constant = compiler.compileVariable(constantElement);
      return graph.addConstant(constant);
    }

    return selector.addArgumentsToList(arguments,
                                       list,
                                       element,
                                       compileArgument,
                                       compileConstant,
                                       compiler);
  }

  void addGenericSendArgumentsToList(Link<Node> link, List<HInstruction> list) {
    for (; !link.isEmpty(); link = link.tail) {
      visit(link.head);
      list.add(pop());
    }
  }

  visitDynamicSend(Send node) {
    Selector selector = elements.getSelector(node);
    var inputs = <HInstruction>[];

    SourceString dartMethodName;
    bool isNotEquals = false;
    if (node.isIndex && !node.arguments.tail.isEmpty()) {
      dartMethodName = Elements.constructOperatorName(
          const SourceString('operator'),
          const SourceString('[]='));
    } else if (node.selector.asOperator() != null) {
      SourceString name = node.selector.asIdentifier().source;
      isNotEquals = name.stringValue === '!=';
      dartMethodName = Elements.constructOperatorName(
          const SourceString('operator'),
          name,
          node.argumentsNode is Prefix);
    } else {
      dartMethodName = node.selector.asIdentifier().source;
    }

    Element interceptor = null;
    if (methodInterceptionEnabled && node.receiver !== null) {
      interceptor = interceptors.getStaticInterceptor(dartMethodName,
                                                      node.argumentCount());
    }
    if (interceptor != null) {
      HStatic target = new HStatic(interceptor);
      add(target);
      inputs.add(target);
      visit(node.receiver);
      inputs.add(pop());
      addGenericSendArgumentsToList(node.arguments, inputs);
      push(new HInvokeInterceptor(selector, inputs));
      return;
    }

    if (node.receiver === null) {
      inputs.add(localsHandler.readThis());
    } else {
      visit(node.receiver);
      inputs.add(pop());
    }

    addDynamicSendArgumentsToList(node, inputs);

    // The first entry in the inputs list is the receiver.
    pushWithPosition(new HInvokeDynamicMethod(selector, inputs), node);

    if (isNotEquals) {
      HNot not = new HNot(popBoolified());
      push(not);
    }
  }

  visitClosureSend(Send node) {
    Selector selector = elements.getSelector(node);
    assert(node.receiver === null);
    Element element = elements[node];
    HInstruction closureTarget;
    if (element === null) {
      visit(node.selector);
      closureTarget = pop();
    } else {
      assert(Elements.isLocal(element));
      closureTarget = localsHandler.readLocal(element);
    }
    var inputs = <HInstruction>[];
    inputs.add(closureTarget);
    addDynamicSendArgumentsToList(node, inputs);
    pushWithPosition(new HInvokeClosure(selector, inputs), node);
  }

  void handleForeignJs(Send node) {
    Link<Node> link = node.arguments;
    // If the invoke is on foreign code, don't visit the first
    // argument, which is the type, and the second argument,
    // which is the foreign code.
    if (link.isEmpty() || link.isEmpty()) {
      compiler.cancel('At least two arguments expected',
                      node: node.argumentsNode);
    }
    link = link.tail.tail;
    List<HInstruction> inputs = <HInstruction>[];
    addGenericSendArgumentsToList(link, inputs);
    Node type = node.arguments.head;
    Node literal = node.arguments.tail.head;
    if (literal is !StringNode || literal.dynamic.isInterpolation) {
      compiler.cancel('JS code must be a string literal', node: literal);
    }
    if (type is !LiteralString) {
      compiler.cancel(
          'The type of a JS expression must be a string literal', node: type);
    }
    push(new HForeign(
        literal.dynamic.dartString, type.dynamic.dartString, inputs));
  }

  void handleForeignUnintercepted(Send node) {
    Link<Node> link = node.arguments;
    if (!link.tail.isEmpty()) {
      compiler.cancel(
          'More than one expression in UNINTERCEPTED()', node: node);
    }
    Expression expression = link.head;
    disableMethodInterception();
    visit(expression);
    enableMethodInterception();
  }

  void handleForeignJsHasEquals(Send node) {
    List<HInstruction> inputs = <HInstruction>[];
    if (!node.arguments.tail.isEmpty()) {
      compiler.cancel(
          'More than one expression in JS_HAS_EQUALS()', node: node);
    }
    addGenericSendArgumentsToList(node.arguments, inputs);
    String name = compiler.namer.instanceMethodName(
        currentLibrary, Elements.OPERATOR_EQUALS, 1);
    push(new HForeign(new DartString.literal('!!#.$name'),
                      const LiteralDartString('bool'),
                      inputs));
  }

  void handleForeignJsCurrentIsolate(Send node) {
    if (!node.arguments.isEmpty()) {
      compiler.cancel(
          'Too many arguments to JS_CURRENT_ISOLATE', node: node);
    }

    if (!compiler.hasIsolateSupport()) {
      // If the isolate library is not used, we just generate code
      // to fetch the Leg's current isolate.
      String name = compiler.namer.CURRENT_ISOLATE;
      push(new HForeign(new DartString.literal(name),
                        const LiteralDartString('var'),
                        <HInstruction>[]));
    } else {
      // Call a helper method from the isolate library. The isolate
      // library uses its own isolate structure, that encapsulates
      // Leg's isolate.
      Element element = compiler.isolateLibrary.find(
          const SourceString('_currentIsolate'));
      if (element === null) {
        compiler.cancel(
            'Isolate library and compiler mismatch', node: node);
      }
      pushInvokeHelper0(element);
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
      Element element = compiler.isolateLibrary.find(
          const SourceString('_callInIsolate'));
      if (element === null) {
        compiler.cancel(
            'Isolate library and compiler mismatch', node: node);
      }
      HStatic target = new HStatic(element);
      add(target);
      List<HInstruction> inputs = <HInstruction>[target];
      addGenericSendArgumentsToList(link, inputs);
      push(new HInvokeStatic(inputs));
    }
  }

  void handleForeignDartClosureToJs(Send node) {
    if (node.arguments.isEmpty() || !node.arguments.tail.isEmpty()) {
      compiler.cancel('Exactly one argument required',
                      node: node.argumentsNode);
    }
    Node closure = node.arguments.head;
    Element element = elements[closure];
    if (!Elements.isStaticOrTopLevelFunction(element)) {
      compiler.cancel(
          'JS_TO_CLOSURE requires a static or top-level method',
          node: closure);
    }
    FunctionElement function = element;
    FunctionSignature params = function.computeSignature(compiler);
    if (params.optionalParameterCount !== 0) {
      compiler.cancel(
          'JS_TO_CLOSURE does not handle closure with optional parameters',
          node: closure);
    }
    visit(closure);
    List<HInstruction> inputs = <HInstruction>[pop()];
    String invocationName = compiler.namer.closureInvocationName(
        new Selector.callClosure(params.requiredParameterCount));
    push(new HForeign(new DartString.literal('#.$invocationName'),
                      const LiteralDartString('var'),
                      inputs));
  }

  visitForeignSend(Send node) {
    Selector selector = elements.getSelector(node);
    SourceString name = selector.name;
    if (name == const SourceString('JS')) {
      handleForeignJs(node);
    } else if (name == const SourceString('UNINTERCEPTED')) {
      handleForeignUnintercepted(node);
    } else if (name == const SourceString('JS_HAS_EQUALS')) {
      handleForeignJsHasEquals(node);
    } else if (name == const SourceString('JS_CURRENT_ISOLATE')) {
      handleForeignJsCurrentIsolate(node);
    } else if (name == const SourceString('JS_CALL_IN_ISOLATE')) {
      handleForeignJsCallInIsolate(node);
    } else if (name == const SourceString('DART_CLOSURE_TO_JS')) {
      handleForeignDartClosureToJs(node);
    } else {
      throw "Unknown foreign: ${selector}";
    }
  }

  generateSuperNoSuchMethodSend(Send node) {
    ClassElement cls = work.element.getEnclosingClass();
    Element element = cls.lookupSuperMember(Compiler.NO_SUCH_METHOD);
    HStatic target = new HStatic(element);
    add(target);
    HInstruction self = localsHandler.readThis();
    Identifier identifier = node.selector.asIdentifier();
    String name = identifier.source.slowToString();
    // TODO(ahe): Add the arguments to this list.
    push(new HLiteralList([]));
    var inputs = <HInstruction>[
        target,
        self,
        graph.addConstantString(new DartString.literal(name), node),
        pop()];
    push(new HInvokeSuper(inputs));
  }

  visitSend(Send node) {
    Element element = elements[node];
    if (element !== null && element === work.element) {
      graph.isRecursiveMethod = true;
    }
    super.visitSend(node);
  }

  visitSuperSend(Send node) {
    Selector selector = elements.getSelector(node);
    Element element = elements[node];
    if (element === null) return generateSuperNoSuchMethodSend(node);
    HInstruction target = new HStatic(element);
    HInstruction context = localsHandler.readThis();
    add(target);
    var inputs = <HInstruction>[target, context];
    if (node.isPropertyAccess) {
      push(new HInvokeSuper(inputs));
    } else if (element.kind == ElementKind.FUNCTION ||
               element.kind == ElementKind.GENERATIVE_CONSTRUCTOR) {
      bool succeeded = addStaticSendArgumentsToList(selector, node.arguments,
                                                    element, inputs);
      if (!succeeded) {
        // TODO(ngeoffray): Match the VM behavior and throw an
        // exception at runtime.
        compiler.cancel('Unimplemented non-matching static call', node);
      }
      push(new HInvokeSuper(inputs));
    } else {
      target = new HInvokeSuper(inputs);
      add(target);
      inputs = <HInstruction>[target];
      addDynamicSendArgumentsToList(node, inputs);
      push(new HInvokeClosure(selector, inputs));
    }
  }

  visitNewSend(Send node) {
    computeType(element) {
      Element originalElement = elements[node];
      if (originalElement.getEnclosingClass() === compiler.listClass) {
        if (node.arguments.isEmpty()) {
          return HType.EXTENDABLE_ARRAY;
        } else {
          return HType.MUTABLE_ARRAY;
        }
      } else if (element.isGenerativeConstructor()) {
        ClassElement cls = element.getEnclosingClass();
        return new HBoundedType.exact(cls.type);
      } else {
        return HType.UNKNOWN;
      }
    }

    Selector selector = elements.getSelector(node);
    Element element = elements[node];
    if (compiler.enqueuer.resolution.getCachedElements(element) === null) {
      compiler.internalError("Unresolved element: $element", node: node);
    }
    FunctionElement functionElement = element;
    element = functionElement.defaultImplementation;
    HInstruction target = new HStatic(element);
    add(target);
    var inputs = <HInstruction>[];
    inputs.add(target);
    bool succeeded = addStaticSendArgumentsToList(selector, node.arguments,
                                                  element, inputs);
    if (!succeeded) {
      // TODO(ngeoffray): Match the VM behavior and throw an
      // exception at runtime.
      compiler.cancel('Unimplemented non-matching static call', node: node);
    }

    HType elementType = computeType(element);
    HInstruction newInstance = new HInvokeStatic(inputs, elementType);
    pushWithPosition(newInstance, node);

    TypeAnnotation annotation = getTypeAnnotationFromSend(node);
    Type type = elements.getType(annotation);
    generateSetRuntimeTypeInformation(newInstance, type);
  }

  generateSetRuntimeTypeInformation(HInstruction instance, Type type) {
    if (compiler.codegenWorld.rti.hasTypeArguments(type)) {
      String typeString = compiler.codegenWorld.rti.asJsString(type);
      HInstruction typeInfo = new HForeign(new LiteralDartString(typeString),
                                           new LiteralDartString('Object'),
                                           <HInstruction>[]);
      add(typeInfo);
      Element typeInfoSetterElement = interceptors.getSetRuntimeTypeInfo();
      HInstruction typeInfoSetter = new HStatic(typeInfoSetterElement);
      add(typeInfoSetter);
      var inputs = <HInstruction>[typeInfoSetter, instance, typeInfo];
      add(new HInvokeStatic(inputs));
    }
  }

  visitStaticSend(Send node) {
    Selector selector = elements.getSelector(node);
    Element element = elements[node];
    if (element === compiler.assertMethod && !compiler.enableUserAssertions) {
      stack.add(graph.addConstantNull());
      return;
    }
    compiler.ensure(element.kind !== ElementKind.GENERATIVE_CONSTRUCTOR);

    if (tryInlineMethod(element, selector, node.arguments)) return;

    HInstruction target = new HStatic(element);
    add(target);
    var inputs = <HInstruction>[];
    inputs.add(target);
    if (element.kind == ElementKind.FUNCTION) {
      bool succeeded = addStaticSendArgumentsToList(selector, node.arguments,
                                                    element, inputs);
      if (!succeeded) {
        // TODO(ngeoffray): Match the VM behavior and throw an
        // exception at runtime.
        compiler.cancel('Unimplemented non-matching static call', node: node);
      }
      HInvokeStatic instruction = new HInvokeStatic(inputs);
      // TODO(ngeoffray): Only do this if knowing the return type is
      // useful.
      HType returnType =
          builder.backend.optimisticReturnTypesWithRecompilationOnTypeChange(
              work.element, element);
      if (returnType != null) instruction.guaranteedType = returnType;
      pushWithPosition(instruction, node);
    } else {
      if (element.kind == ElementKind.GETTER) {
        target = new HInvokeStatic(inputs);
        add(target);
        inputs = <HInstruction>[target];
      }
      addDynamicSendArgumentsToList(node, inputs);
      pushWithPosition(new HInvokeClosure(selector, inputs), node);
    }
  }

  visitGetterSend(Send node) {
    generateGetter(node, elements[node]);
  }

  // TODO(antonm): migrate rest of SsaBuilder to internalError.
  internalError(String reason, [Node node]) {
    compiler.internalError(reason, node: node);
  }

  // TODO(karlklose): share with resolver.
  TypeAnnotation getTypeAnnotationFromSend(Send send) {
    if (send.selector is TypeAnnotation) {
      return send.selector;
    } else if (send.selector is Send) {
      Send selector = send.selector;
      if (selector.receiver is TypeAnnotation) {
        return selector.receiver;
      }
    } else {
      compiler.internalError("malformed send in new expression");
    }
  }

  visitNewExpression(NewExpression node) {
    Element element = elements[node.send];
    if (Element.isInvalid(element)) {
      ErroneousElement error = element;
      Message message = error.errorMessage;
      if (message.kind === MessageKind.CANNOT_FIND_CONSTRUCTOR) {
        Element helper =
            compiler.findHelper(const SourceString('throwNoSuchMethod'));
        DartString receiverLiteral = new DartString.literal('');
        HInstruction receiver = graph.addConstantString(receiverLiteral, node);
        String constructorName = 'constructor ${message.arguments[0]}';
        DartString nameLiteral = new DartString.literal(constructorName);
        HInstruction name = graph.addConstantString(nameLiteral, node.send);
        List<HInstruction> inputs = <HInstruction>[];
        node.send.arguments.forEach((argumentNode) {
          visit(argumentNode);
          HInstruction value = pop();
          inputs.add(value);
        });
        HInstruction arguments = new HLiteralList(inputs);
        add(arguments);
        pushInvokeHelper3(helper, receiver, name, arguments);
      } else {
        compiler.cancel('Unimplemented unresolved constructor call',
                        node: node);
      }
    } else if (node.isConst()) {
      // TODO(karlklose): add type representation
      ConstantHandler handler = compiler.constantHandler;
      Constant constant = handler.compileNodeWithDefinitions(node, elements);
      stack.add(graph.addConstant(constant));
    } else {
      visitNewSend(node.send);
    }
  }

  visitSendSet(SendSet node) {
    Operator op = node.assignmentOperator;
    if (node.isSuperCall) {
      Element element = elements[node];
      if (element === null) return generateSuperNoSuchMethodSend(node);
      HInstruction target = new HStatic(element);
      HInstruction context = localsHandler.readThis();
      add(target);
      var inputs = <HInstruction>[target, context];
      addDynamicSendArgumentsToList(node, inputs);
      if (node.assignmentOperator.source.stringValue !== '=') {
        compiler.unimplemented('complex super assignment',
                               node: node.assignmentOperator);
      }
      push(new HInvokeSuper(inputs, isSetter: true));
    } else if (node.isIndex) {
      if (!methodInterceptionEnabled) {
        assert(op.source.stringValue === '=');
        visitDynamicSend(node);
      } else {
        HStatic target = new HStatic(
            interceptors.getIndexAssignmentInterceptor());
        add(target);
        visit(node.receiver);
        HInstruction receiver = pop();
        visit(node.argumentsNode);
        if (const SourceString("=") == op.source) {
          HInstruction value = pop();
          HInstruction index = pop();
          add(new HIndexAssign(target, receiver, index, value));
          stack.add(value);
        } else {
          HInstruction value;
          HInstruction index;
          bool isCompoundAssignment = op.source.stringValue.endsWith('=');
          // Compound assignments are considered as being prefix.
          bool isPrefix = !node.isPostfix;
          Element getter = elements[node.selector];
          if (isCompoundAssignment) {
            value = pop();
            index = pop();
          } else {
            index = pop();
            value = graph.addConstantInt(1);
          }
          HStatic indexMethod = new HStatic(interceptors.getIndexInterceptor());
          add(indexMethod);
          HInstruction left = new HIndex(indexMethod, receiver, index);
          add(left);
          Element opElement = elements[op];
          visitBinary(left, op, value);
          value = pop();
          HInstruction assign = new HIndexAssign(
              target, receiver, index, value);
          add(assign);
          if (isPrefix) {
            stack.add(value);
          } else {
            stack.add(left);
          }
        }
      }
    } else if (const SourceString("=") == op.source) {
      Element element = elements[node];
      Link<Node> link = node.arguments;
      assert(!link.isEmpty() && link.tail.isEmpty());
      visit(link.head);
      HInstruction value = pop();
      generateSetter(node, element, value);
    } else if (op.source.stringValue === "is") {
      compiler.internalError("is-operator as SendSet", node: op);
    } else {
      assert(const SourceString("++") == op.source ||
             const SourceString("--") == op.source ||
             node.assignmentOperator.source.stringValue.endsWith("="));
      Element element = elements[node];
      bool isCompoundAssignment = !node.arguments.isEmpty();
      bool isPrefix = !node.isPostfix;  // Compound assignments are prefix.

      // [receiver] is only used if the node is an instance send.
      HInstruction receiver = null;
      if (Elements.isInstanceSend(node, elements)) {
        receiver = generateInstanceSendReceiver(node);
        generateInstanceGetterWithCompiledReceiver(node, receiver);
      } else {
        generateGetter(node, elements[node.selector]);
      }
      HInstruction left = pop();
      HInstruction right;
      if (isCompoundAssignment) {
        visit(node.argumentsNode);
        right = pop();
      } else {
        right = graph.addConstantInt(1);
      }
      visitBinary(left, op, right);
      HInstruction operation = pop();
      assert(operation !== null);
      if (Elements.isInstanceSend(node, elements)) {
        assert(receiver !== null);
        generateInstanceSetterWithCompiledReceiver(node, receiver, operation);
      } else {
        assert(receiver === null);
        generateSetter(node, element, operation);
      }
      if (!isPrefix) {
        pop();
        stack.add(left);
      }
    }
  }

  void visitLiteralInt(LiteralInt node) {
    stack.add(graph.addConstantInt(node.value));
  }

  void visitLiteralDouble(LiteralDouble node) {
    stack.add(graph.addConstantDouble(node.value));
  }

  void visitLiteralBool(LiteralBool node) {
    stack.add(graph.addConstantBool(node.value));
  }

  void visitLiteralString(LiteralString node) {
    stack.add(graph.addConstantString(node.dartString, node));
  }

  void visitStringJuxtaposition(StringJuxtaposition node) {
    if (!node.isInterpolation) {
      // This is a simple string with no interpolations.
      stack.add(graph.addConstantString(node.dartString, node));
      return;
    }
    StringBuilderVisitor stringBuilder = new StringBuilderVisitor(this, node);
    stringBuilder.visit(node);
    stack.add(stringBuilder.result);
  }

  void visitLiteralNull(LiteralNull node) {
    stack.add(graph.addConstantNull());
  }

  visitNodeList(NodeList node) {
    for (Link<Node> link = node.nodes; !link.isEmpty(); link = link.tail) {
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

  visitReturn(Return node) {
    if (node.getBeginToken().stringValue === 'native') {
      native.handleSsaNative(this, node.expression);
      return;
    }
    HInstruction value;
    if (node.expression === null) {
      value = graph.addConstantNull();
    } else {
      visit(node.expression);
      value = pop();
    }
    if (!inliningStack.isEmpty()) {
      localsHandler.updateLocal(returnElement, value);
    } else {
      close(attachPosition(new HReturn(value), node)).addSuccessor(graph.exit);
    }
  }

  visitThrow(Throw node) {
    if (node.expression === null) {
      HInstruction exception = rethrowableException;
      if (exception === null) {
        exception = graph.addConstantNull();
        compiler.reportError(node,
                             'throw without expression outside catch block');
      }
      close(new HThrow(exception, isRethrow: true));
    } else {
      visit(node.expression);
      close(new HThrow(pop()));
    }
  }

  visitTypeAnnotation(TypeAnnotation node) {
    compiler.internalError('visiting type annotation in SSA builder',
                           node: node);
  }

  visitVariableDefinitions(VariableDefinitions node) {
    for (Link<Node> link = node.definitions.nodes;
         !link.isEmpty();
         link = link.tail) {
      Node definition = link.head;
      if (definition is Identifier) {
        HInstruction initialValue = graph.addConstantNull();
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
         !link.isEmpty();
         link = link.tail) {
      visit(link.head);
      inputs.add(pop());
    }
    push(new HLiteralList(inputs));
  }

  visitConditional(Conditional node) {
    SsaBranchBuilder brancher =
        new SsaBranchBuilder(this, diagnosticNode: node);
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
    TargetElement target = elements[node];
    assert(target !== null);
    JumpHandler handler = jumpTargets[target];
    assert(handler !== null);
    if (node.target === null) {
      handler.generateBreak();
    } else {
      LabelElement label = elements[node.target];
      handler.generateBreak(label);
    }
  }

  visitContinueStatement(ContinueStatement node) {
    TargetElement target = elements[node];
    assert(target !== null);
    JumpHandler handler = jumpTargets[target];
    assert(handler !== null);
    if (node.target === null) {
      handler.generateContinue();
    } else {
      LabelElement label = elements[node.target];
      assert(label !== null);
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
    if (element === null || element.statement !== node) {
      // No breaks or continues to this node.
      return new NullJumpHandler(compiler);
    }
    return new JumpHandler(this, element);
  }

  visitForIn(ForIn node) {
    // Generate a structure equivalent to:
    //   Iterator<E> $iter = <iterable>.iterator()
    //   while ($iter.hasNext()) {
    //     E <declaredIdentifier> = $iter.next();
    //     <body>
    //   }

    // The iterator is shared between initializer, condition and body.
    HInstruction iterator;
    void buildInitializer() {
      SourceString iteratorName = const SourceString("iterator");
      Element interceptor = interceptors.getStaticInterceptor(iteratorName, 0);
      assert(interceptor != null);
      visit(node.expression);
      pushInvokeHelper1(interceptor, pop());
      iterator = pop();
    }
    HInstruction buildCondition() {
      SourceString name = const SourceString('hasNext');
      Selector call = new Selector.call(name, work.element.getLibrary(), 0);
      push(new HInvokeDynamicMethod(call, <HInstruction>[iterator]));
      return popBoolified();
    }
    void buildBody() {
      SourceString name = const SourceString('next');
      Selector call = new Selector.call(name, work.element.getLibrary(), 0);
      push(new HInvokeDynamicMethod(call, <HInstruction>[iterator]));

      Element variable;
      if (node.declaredIdentifier.asSend() !== null) {
        variable = elements[node.declaredIdentifier];
      } else {
        assert(node.declaredIdentifier.asVariableDefinitions() !== null);
        VariableDefinitions variableDefinitions = node.declaredIdentifier;
        variable = elements[variableDefinitions.definitions.nodes.head];
      }
      localsHandler.updateLocal(variable, pop());

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
    if (targetElement === null || targetElement.statement !== body) {
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
    hackAroundPossiblyAbortingBody(node, () { visit(body); });
    SubGraph bodyGraph = new SubGraph(entryBlock, lastOpenedBlock);

    HBasicBlock joinBlock = graph.addNewBlock();
    List<LocalsHandler> breakLocals = <LocalsHandler>[];
    handler.forEachBreak((HBreak breakInstruction, LocalsHandler locals) {
      breakInstruction.block.addSuccessor(joinBlock);
      breakLocals.add(locals);
    });
    bool hasBreak = breakLocals.length > 0;
    if (!isAborted()) {
      goto(current, joinBlock);
      breakLocals.add(localsHandler);
    }
    open(joinBlock);
    localsHandler = beforeLocals.mergeMultiple(breakLocals, joinBlock);

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
         !link.isEmpty();
         link = link.tail) {
      visit(link.head);
      inputs.addLast(pop());
      inputs.addLast(pop());
    }
    HLiteralList keyValuePairs = new HLiteralList(inputs);
    add(keyValuePairs);
    pushInvokeHelper1(interceptors.getMapMaker(), keyValuePairs);
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
    if (node.cases.isEmpty()) {
      return;
    }

    Link<Node> cases = node.cases.nodes;
    JumpHandler jumpHandler = createJumpHandler(node);

    buildSwitchCases(cases, expression);

    HBasicBlock lastBlock = lastOpenedBlock;

    // Create merge block for break targets.
    HBasicBlock joinBlock = new HBasicBlock();
    List<LocalsHandler> caseLocals = <LocalsHandler>[];
    jumpHandler.forEachBreak((HBreak instruction, LocalsHandler locals) {
      instruction.block.addSuccessor(joinBlock);
      caseLocals.add(locals);
    });
    if (!isAborted()) {
      // The current flow is only aborted if the switch has a default that
      // aborts (all previous cases must abort, and if there is no default,
      // it's possible to miss all the cases).
      caseLocals.add(localsHandler);
      goto(current, joinBlock);
    }
    if (caseLocals.length != 0) {
      graph.addBlock(joinBlock);
      open(joinBlock);
      if (caseLocals.length == 1) {
        localsHandler = caseLocals[0];
      } else {
        localsHandler = savedLocals.mergeMultiple(caseLocals, joinBlock);
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
    // First check whether all case expressions are compile-time constants.
    for (SwitchCase switchCase in node.cases) {
      for (Node labelOrCase in switchCase.labelsAndCases) {
        if (labelOrCase is CaseMatch) {
          CaseMatch match = labelOrCase;
          Constant constant =
            compiler.constantHandler.tryCompileNodeWithDefinitions(
                match.expression, elements);
          if (constant === null) return false;
          constants[labelOrCase] = constant;
        } else {
          // We don't handle labels yet.
          return false;
        }
      }
    }
    // TODO(ngeoffray): Handle switch-instruction in bailout code.
    work.allowSpeculativeOptimization = false;
    // Then build a switch structure.
    HBasicBlock expressionStart = openNewBlock();
    visit(node.expression);
    HInstruction expression = pop();
    if (node.cases.isEmpty()) {
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
    Element getFallThroughErrorElement =
        compiler.findHelper(const SourceString("getFallThroughError"));
    Iterator<Node> caseIterator = node.cases.iterator();
    while (caseIterator.hasNext()) {
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
      if (!isAborted() && caseIterator.hasNext()) {
        pushInvokeHelper0(getFallThroughErrorElement);
        HInstruction error = pop();
        close(new HThrow(error));
      }
      statements.add(
          new HSubGraphBlockInformation(new SubGraph(block, lastOpenedBlock)));
    }

    // Add a join-block if necessary.
    // We create [joinBlock] early, and then go through the cases that might
    // want to jump to it. In each case, if we add [joinBlock] as a successor
    // of another block, we also add an element to [caseLocals] that is used
    // to create the phis in [joinBlock].
    // If we never jump to the join block, [caseLocals] will stay empty, and
    // the join block is never added to the graph.
    HBasicBlock joinBlock = new HBasicBlock();
    List<LocalsHandler> caseLocals = <LocalsHandler>[];
    jumpHandler.forEachBreak((HBreak instruction, LocalsHandler locals) {
      instruction.block.addSuccessor(joinBlock);
      caseLocals.add(locals);
    });
    if (!isAborted()) {
      current.close(new HGoto());
      lastOpenedBlock.addSuccessor(joinBlock);
      caseLocals.add(localsHandler);
    }
    if (!hasDefault) {
      // The current flow is only aborted if the switch has a default that
      // aborts (all previous cases must abort, and if there is no default,
      // it's possible to miss all the cases).
      expressionEnd.addSuccessor(joinBlock);
      caseLocals.add(savedLocals);
    }
    assert(caseLocals.length == joinBlock.predecessors.length);
    if (caseLocals.length != 0) {
      graph.addBlock(joinBlock);
      open(joinBlock);
      if (caseLocals.length == 1) {
        localsHandler = caseLocals[0];
      } else {
        localsHandler = savedLocals.mergeMultiple(caseLocals, joinBlock);
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
        pushInvokeHelper0(element);
        HInstruction error = pop();
        close(new HThrow(error));
      }
    }

    Link<Node> skipLabels(Link<Node> labelsAndCases) {
      while (!labelsAndCases.isEmpty() && labelsAndCases.head is Label) {
        labelsAndCases = labelsAndCases.tail;
      }
      return labelsAndCases;
    }

    Link<Node> labelsAndCases = skipLabels(node.labelsAndCases.nodes);
    if (labelsAndCases.isEmpty()) {
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
        Element equalsHelper = interceptors.getEqualsInterceptor();
        HInstruction target = new HStatic(equalsHelper);
        add(target);
        CaseMatch match = remainingCases.head;
        // TODO(lrn): Move the constant resolution to the resolver, so
        // we can report an error before reaching the backend.
        Constant constant =
            compiler.constantHandler.tryCompileNodeWithDefinitions(
                match.expression, elements);
        if (constant !== null) {
          if (constant.isInt()) {
            // Report the first mixed-string/int type error only.
            if (encounteredCaseTypes == STRING_TYPE) {
              compiler.reportWarning(
                  match, MessageKind.INVALID_CASE_EXPRESSION_TYPE);
            }
            encounteredCaseTypes = combine(encounteredCaseTypes, INT_TYPE);
          } else if (constant.isString()) {
            if (encounteredCaseTypes == INT_TYPE) {
              compiler.reportWarning(
                  match, MessageKind.INVALID_CASE_EXPRESSION_TYPE);
            }
            encounteredCaseTypes = combine(encounteredCaseTypes, STRING_TYPE);
          } else {
            compiler.reportWarning(match,
                                   MessageKind.INVALID_CASE_EXPRESSION);
            encounteredCaseTypes = CONFLICT_TYPE;
          }
          stack.add(graph.addConstant(constant));
        } else {
          // TODO(lrn): Remove this else branch, and make the constant
          // evaluation mandatory when we are ready to break existing code using
          // non constant-int-or-string expressions.
          compiler.reportWarning(match,
              'case expressions not compile-time constant int or string.');
          visit(match.expression);
          encounteredCaseTypes = CONFLICT_TYPE;
        }
        push(new HEquals(target, pop(), expression));
      }

      // If this is the last expression, just return it.
      Link<Node> tail = skipLabels(remainingCases.tail);
      if (tail.isEmpty()) {
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
      assert(cases.tail.isEmpty());
      // Perform the tests until one of them match, but then always execute the
      // statements.
      // TODO(lrn): Stop performing tests when all expressions are compile-time
      // constant strings or integers.
      handleIf(node, () { buildTests(labelsAndCases); }, (){}, null);
      visit(node.statements);
    } else {
      if (cases.tail.isEmpty()) {
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
    List<HBasicBlock> blocks = <HBasicBlock>[];
    blocks.add(close(tryInstruction));

    HBasicBlock tryBody = graph.addNewBlock();
    enterBlock.addSuccessor(tryBody);
    open(tryBody);
    visit(node.tryBlock);
    if (!isAborted()) blocks.add(close(new HGoto()));
    SubGraph bodyGraph = new SubGraph(tryBody, lastOpenedBlock);
    SubGraph catchGraph = null;
    HParameterValue exception = null;
    if (!node.catchBlocks.isEmpty()) {
      localsHandler = new LocalsHandler.from(savedLocals);
      HBasicBlock block = graph.addNewBlock();
      enterBlock.addSuccessor(block);
      open(block);
      // Note that the name of this element is irrelevant.
      Element element = new Element(
          const SourceString('exception'), ElementKind.PARAMETER, work.element);
      exception = new HParameterValue(element);
      add(exception);
      HInstruction oldRethrowableException = rethrowableException;
      rethrowableException = exception;

      pushInvokeHelper1(interceptors.getExceptionUnwrapper(), exception);
      HInvokeStatic unwrappedException = pop();
      tryInstruction.exception = exception;
      Link<Node> link = node.catchBlocks.nodes;

      void pushCondition(CatchBlock catchBlock) {
        if (catchBlock.onKeyword != null) {
          Type type = elements.getType(catchBlock.type);
          if (type == null) {
            compiler.cancel('On with unresolved type',
                            node: catchBlock.type);
          }
          HInstruction condition = new HIs(type, unwrappedException);
          push(condition);
        }
        else {
          VariableDefinitions declaration = catchBlock.formals.nodes.head;
          HInstruction condition = null;
          if (declaration.type == null) {
            condition = graph.addConstantBool(true);
            stack.add(condition);
          } else {
            // TODO(aprelev@gmail.com): Once old catch syntax is removed
            // "if" condition above and this "else" branch should be deleted as
            // type of declared variable won't matter for the catch
            // condition
            Type type = elements.getType(declaration.type);
            if (type == null) {
              compiler.cancel('Catch with unresolved type', node: catchBlock);
            }
            condition = new HIs(type, unwrappedException, nullOk: true);
            push(condition);
          }
        }
      }

      void visitThen() {
        CatchBlock catchBlock = link.head;
        link = link.tail;
        localsHandler.updateLocal(elements[catchBlock.exception],
                                  unwrappedException);
        Node trace = catchBlock.trace;
        if (trace != null) {
          pushInvokeHelper1(interceptors.getTraceFromException(), exception);
          HInstruction traceInstruction = pop();
          localsHandler.updateLocal(elements[trace], traceInstruction);
        }
        visit(catchBlock);
      }

      void visitElse() {
        if (link.isEmpty()) {
          close(new HThrow(exception, isRethrow: true));
        } else {
          CatchBlock newBlock = link.head;
          handleIf(node,
                   () { pushCondition(newBlock); },
                   visitThen, visitElse);
        }
      }

      CatchBlock firstBlock = link.head;
      handleIf(node, () { pushCondition(firstBlock); }, visitThen, visitElse);
      if (!isAborted()) blocks.add(close(new HGoto()));

      rethrowableException = oldRethrowableException;
      tryInstruction.catchBlock = block;
      catchGraph = new SubGraph(block, lastOpenedBlock);
    }

    SubGraph finallyGraph = null;
    if (node.finallyBlock != null) {
      localsHandler = new LocalsHandler.from(savedLocals);
      HBasicBlock finallyBlock = graph.addNewBlock();
      enterBlock.addSuccessor(finallyBlock);
      open(finallyBlock);
      visit(node.finallyBlock);
      if (!isAborted()) blocks.add(close(new HGoto()));
      tryInstruction.finallyBlock = finallyBlock;
      finallyGraph = new SubGraph(finallyBlock, lastOpenedBlock);
    }

    HBasicBlock exitBlock = graph.addNewBlock();

    for (HBasicBlock block in blocks) {
      block.addSuccessor(exitBlock);
    }

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

  HType mapInferredType(Element element) {
    if (element === builder.compiler.boolClass) return HType.BOOLEAN;
    if (element === builder.compiler.doubleClass) return HType.DOUBLE;
    if (element === builder.compiler.intClass) return HType.INTEGER;
    if (element === builder.compiler.listClass) return HType.READABLE_ARRAY;
    if (element === builder.compiler.nullClass) return HType.NULL;
    if (element === builder.compiler.stringClass) return HType.STRING;
    return HType.UNKNOWN;
  }

  /** HACK HACK HACK */
  void hackAroundPossiblyAbortingBody(Node statement, void body()) {
    visitCondition() {
      stack.add(graph.addConstantBool(true));
    }
    buildBody() {
      // TODO(lrn): Make sure to take continue into account.
      body();
    }
    handleIf(statement, visitCondition, buildBody, null);
  }
}

/**
 * Visitor that handles generation of string literals (LiteralString,
 * StringInterpolation), and otherwise delegates to the given visitor for
 * non-literal subexpressions.
 * TODO(lrn): Consider whether to handle compile time constant int/boolean
 * expressions as well.
 */
class StringBuilderVisitor extends AbstractVisitor {
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
    result = (result === null) ? expression : concat(result, expression);
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
class InlineWeeder extends AbstractVisitor {
  final TreeElements elements;
  bool seenReturn = false;
  bool tooDifficult = false;

  InlineWeeder(this.elements);

  static bool canBeInlined(FunctionExpression functionExpression,
                           TreeElements elements) {
    InlineWeeder weeder = new InlineWeeder(elements);
    weeder.visit(functionExpression.body);
    if (weeder.tooDifficult) return false;
    return true;
  }

  void visit(Node node) {
    node.accept(this);
  }

  void visitNode(Node node) {
    if (seenReturn) {
      tooDifficult = true;
    } else {
      node.visitChildren(this);
    }
  }

  void visitFunctionExpression(Node node) {
    tooDifficult = true;
  }

  void visitFunctionDeclaration(Node node) {
    tooDifficult = true;
  }

  void visitSend(Node node) {
    node.visitChildren(this);
  }

  visitLoop(Node node) {
    node.visitChildren(this);
    if (seenReturn) tooDifficult = true;
  }

  void visitReturn(Node node) {
    if (seenReturn || node.getBeginToken().stringValue === 'native') {
      tooDifficult = true;
      return;
    }
    node.visitChildren(this);
    seenReturn = true;
  }

  void visitTryStatement(Node node) {
    tooDifficult = true;
  }

  void visitThrow(Node node) {
    tooDifficult = true;
  }
}

class InliningState {
  final PartialFunctionElement function;
  final Element oldReturnElement;
  final TreeElements oldElements;
  final List<HInstruction> oldStack;

  InliningState(this.function,
                this.oldReturnElement,
                this.oldElements,
                this.oldStack);
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
    assert(builder.current === builder.lastOpenedBlock);
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
                   [bool mayReuseFromLocals]) {
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

  void handleLogicalAndOr(void left(), void right(), [bool isAnd]) {
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
    HPhi result = new HPhi.manyInputs(null,
        <HInstruction>[boolifiedRight, builder.graph.addConstantBool(!isAnd)]);
    builder.current.addPhi(result);
    builder.stack.add(result);
  }

  void handleLogicalAndOrWithLeftNode(Node left,
                                      void visitRight(),
                                      [bool isAnd]) {
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
    if (send !== null &&
        (isAnd ? send.isLogicalAnd : send.isLogicalOr)) {
      Node newLeft = send.receiver;
      Link<Node> link = send.argumentsNode.nodes;
      assert(link.tail.isEmpty());
      Node middle = link.head;
      handleLogicalAndOrWithLeftNode(
          newLeft,
          () => handleLogicalAndOrWithLeftNode(middle, visitRight, isAnd),
          isAnd: isAnd);
    } else {
      handleLogicalAndOr(() => builder.visit(left), visitRight, isAnd);
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
    if (!joinBranch.block.predecessors.isEmpty()) {
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
