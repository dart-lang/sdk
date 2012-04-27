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
    String mangledName = "builtin\$${name.slowToString()}\$${parameters}";
    Element result = compiler.findHelper(new SourceString(mangledName));
    return result;
  }

  Element getStaticGetInterceptor(SourceString name) {
    String mangledName = "builtin\$get\$${name.slowToString()}";
    Element result = compiler.findHelper(new SourceString(mangledName));
    return result;
  }

  Element getStaticSetInterceptor(SourceString name) {
    String mangledName = "builtin\$set\$${name.slowToString()}";
    Element result = compiler.findHelper(new SourceString(mangledName));
    return result;
  }

  Element getOperatorInterceptor(Operator op) {
    SourceString name = mapOperatorToMethodName(op);
    Element result = compiler.findHelper(name);
    return result;
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

  Element getEqualsNullInterceptor() {
    return compiler.findHelper(const SourceString('eqNull'));
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
}

class SsaBuilderTask extends CompilerTask {
  final Interceptors interceptors;
  final Map<Node, ClosureData> closureDataCache;

  String get name() => 'SSA builder';

  SsaBuilderTask(Compiler compiler)
    : interceptors = new Interceptors(compiler),
      closureDataCache = new HashMap<Node, ClosureData>(),
      super(compiler);

  HGraph build(WorkItem work) {
    return measure(() {
      FunctionElement element = work.element;
      HInstruction.idCounter = 0;
      SsaBuilder builder = new SsaBuilder(compiler, work);
      HGraph graph;
      switch (element.kind) {
        case ElementKind.GENERATIVE_CONSTRUCTOR:
          graph = compileConstructor(builder, work);
          break;
        case ElementKind.GENERATIVE_CONSTRUCTOR_BODY:
        case ElementKind.FUNCTION:
        case ElementKind.GETTER:
        case ElementKind.SETTER:
          graph = builder.buildMethod(work.element);
          break;
      }
      assert(graph.isValid());
      if (compiler.tracer.enabled) {
        String name;
        if (element.enclosingElement !== null &&
            element.enclosingElement.kind == ElementKind.CLASS) {
          String className = element.enclosingElement.name.slowToString();
          String memberName = element.name.slowToString();
          name = "$className.$memberName";
          if (element.kind == ElementKind.GENERATIVE_CONSTRUCTOR_BODY) {
            name = "$name (body)";
          }
        } else {
          name = "${element.name.slowToString()}";
        }
        compiler.tracer.traceCompilation(name);
        compiler.tracer.traceGraph('builder', graph);
      }
      return graph;
    });
  }

  HGraph compileConstructor(SsaBuilder builder, WorkItem work) {
    // The body of the constructor will be generated in a separate function.
    final ClassElement classElement = work.element.enclosingElement;
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
  ClosureData closureData;

  LocalsHandler(this.builder)
      : directLocals = new Map<Element, HInstruction>(),
        redirectionMapping = new Map<Element, Element>();

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

    ClosureTranslator translator =
        new ClosureTranslator(builder.compiler, builder.elements);
    closureData = translator.translate(node);

    FunctionParameters params = function.computeParameters(builder.compiler);
    params.forEachParameter((Element element) {
      HParameterValue parameter = new HParameterValue(element);
      builder.add(parameter);
      directLocals[element] = parameter;
    });
    if (closureData.thisElement !== null) {
      // Once closures have been mapped to classes their instance members might
      // not have any thisElement if the closure was created inside a static
      // context.
      assert(function.isInstanceMember() || function.isGenerativeConstructor());
      // We have to introduce 'this' before we enter the scope, since it might
      // need to be copied into a box (if it is captured). This is similar
      // to all other parameters that are introduced.
      HInstruction thisInstruction = new HThis();
      builder.add(thisInstruction);
      directLocals[closureData.thisElement] = thisInstruction;
    }

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
    if (redirectTarget.enclosingElement.kind == ElementKind.CLASS) {
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
      // We must not use the [LocalsHandler.readThis()] since that could
      // point to a captured this which would be stored in a closure-field
      // itself.
      HInstruction receiver = new HThis();
      builder.add(receiver);
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
      HInstruction variable = new HFieldGet.fromActivation(element);
      builder.add(variable);
      return variable;
    }
  }

  HInstruction readThis() {
    return readLocal(closureData.thisElement);
  }

  /**
   * Sets the [element] to [value]. If the element is boxed or stored in a
   * closure then the method generates code to set the value.
   */
  void updateLocal(Element element, HInstruction value) {
    if (isAccessedDirectly(element)) {
      directLocals[element] = value;
    } else if (isStoredInClosureField(element)) {
      Element redirect = redirectionMapping[element];
      // We must not use the [LocalsHandler.readThis()] since that could
      // point to a captured this which would be stored in a closure-field
      // itself.
      HInstruction receiver = new HThis();
      builder.add(receiver);
      builder.add(new HFieldSet(redirect, receiver, value));
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
      builder.add(new HFieldSet.fromActivation(element,value));
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
      // We know 'this' cannot be modified.
      if (element !== closureData.thisElement) {
        HPhi phi = new HPhi.singleInput(element, instruction);
        loopEntry.addPhi(phi);
        directLocals[element] = phi;
      } else {
        directLocals[element] = instruction;
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
   * If a phi node is necessary, it will use the otherLocals instruction as the
   * first input, and this handler's instruction as the second.
   * NOTICE: This means that the predecessor corresponding to [otherLocals]
   * should be the first predecessor of the current block, and the one
   * corresponding to this locals handler should be the second.
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
              new HPhi.manyInputs(element, <HInstruction>[instruction, mine]);
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
  final HGoto jumpInstruction;
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
  const NullJumpHandler();
  void generateBreak([LabelElement label]) { unreachable(); }
  void generateContinue([LabelElement label]) { unreachable(); }
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

class SsaBuilder implements Visitor {
  final Compiler compiler;
  TreeElements elements;
  final Interceptors interceptors;
  final WorkItem work;
  bool methodInterceptionEnabled;
  HGraph graph;
  LocalsHandler localsHandler;
  HInstruction rethrowableException;

  Map<TargetElement, JumpHandler> jumpTargets;

  // We build the Ssa graph by simulating a stack machine.
  List<HInstruction> stack;

  // The current block to add instructions to. Might be null, if we are
  // visiting dead code.
  HBasicBlock current;
  // The most recently opened block. Has the same value as [current] while
  // the block is open, but unlike [current], it isn't cleared when the current
  // block is closed.
  HBasicBlock lastOpenedBlock;

  LibraryElement get currentLibrary() => work.element.getLibrary();

  SsaBuilder(Compiler compiler, WorkItem work)
    : this.compiler = compiler,
      this.work = work,
      interceptors = compiler.builder.interceptors,
      methodInterceptionEnabled = true,
      elements = work.resolutionTree,
      graph = new HGraph(),
      stack = new List<HInstruction>(),
      jumpTargets = new Map<TargetElement, JumpHandler>() {
    localsHandler = new LocalsHandler(this);
  }

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
   */
  ConstructorBodyElement getConstructorBody(ClassElement classElement,
                                            FunctionElement constructor) {
    assert(constructor.kind === ElementKind.GENERATIVE_CONSTRUCTOR);
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
      compiler.enqueue(new WorkItem.toCodegen(bodyElement, treeElements));
      classElement.backendMembers =
          classElement.backendMembers.prepend(bodyElement);
    }
    assert(bodyElement.kind === ElementKind.GENERATIVE_CONSTRUCTOR_BODY);
    return bodyElement;
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

    int index = 0;
    FunctionParameters parameters = constructor.computeParameters(compiler);
    parameters.forEachParameter((Element parameter) {
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
      ClassElement enclosingClass = constructor.enclosingElement;
      ClassElement superClass = enclosingClass.superclass;
      if (enclosingClass != compiler.objectClass) {
        assert(superClass !== null);
        assert(superClass.isResolved);
        FunctionElement target = superClass.lookupConstructor(superClass.name);
        if (target === null) {
          compiler.internalError("no default constructor available");
        }
        inlineSuperOrRedirect(target,
                              Selector.INVOCATION_0,
                              const EmptyLink<Node>(),
                              constructors,
                              fieldValues);
      }
    }
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
    FunctionParameters parameters = functionElement.computeParameters(compiler);
    parameters.forEachParameter((Element element) {
      if (element.kind == ElementKind.FIELD_PARAMETER) {
        // If the [element] is a field-parameter (such as [:this.x:] then
        // initialize the field element with its value.
        FieldParameterElement fieldParameterElement = element;
        HInstruction parameterValue = localsHandler.readLocal(element);
        fieldValues[fieldParameterElement.fieldElement] = parameterValue;
      }
    });

    final Map<FunctionElement, TreeElements> constructorElements =
        compiler.resolver.constructorElements;
    List<FunctionElement> constructors = <FunctionElement>[functionElement];

    // Analyze the constructor and all referenced constructors and collect
    // initializers and constructor bodies.
    buildInitializers(functionElement, constructors, fieldValues);

    // Call the JavaScript constructor with the fields as argument.
    List<HInstruction> constructorArguments = <HInstruction>[];
    classElement.forEachInstanceField(
        includeBackendMembers: true,
        includeSuperMembers: true,
        f: (ClassElement enclosingClass, Element member) {
      HInstruction value = fieldValues[member];
      if (value === null) {
        // The field has no value in the initializer list. Initialize it
        // with the declaration-site constant (if any).
        Constant fieldValue = compiler.constantHandler.compileVariable(member);
        value = graph.addConstant(fieldValue);
      }
      constructorArguments.add(value);
    });

    HForeignNew newObject = new HForeignNew(classElement, constructorArguments);
    add(newObject);
    // Generate calls to the constructor bodies.
    for (int index = constructors.length - 1; index >= 0; index--) {
      FunctionElement constructor = constructors[index];
      // TODO(floitsch): find better way to detect that constructor body is
      // empty.
      if (constructor is SynthesizedConstructorElement) continue;
      ConstructorBodyElement body = getConstructorBody(classElement,
                                                       constructor);
      List bodyCallInputs = <HInstruction>[];
      bodyCallInputs.add(newObject);
      body.functionParameters.forEachParameter((parameter) {
        bodyCallInputs.add(localsHandler.readLocal(parameter));
      });
      // TODO(ahe): The constructor name is statically resolved. See
      // SsaCodeGenerator.visitInvokeDynamicMethod. Is there a cleaner
      // way to do this?
      SourceString methodName = new SourceString(compiler.namer.getName(body));
      add(new HInvokeDynamicMethod(null, methodName, bodyCallInputs));
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

  void push(HInstruction instruction) {
    add(instruction);
    stack.add(instruction);
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
    unreachable();
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
        HLoopInformation.loopType(node),
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
    HBasicBlock initializerBlock = openNewBlock();
    initialize();
    assert(!isAborted());
    SubGraph initializerGraph = new SubGraph(initializerBlock, current);

    JumpHandler jumpHandler = beginLoopHeader(loop);
    HBasicBlock conditionBlock = current;
    HLoopInformation loopInfo = current.blockInformation;
    // The initializer graph is currently unused due to the way we
    // generate code.
    loopInfo.initializer = initializerGraph;

    HInstruction conditionInstruction = condition();
    HBasicBlock conditionExitBlock =
        close(new HLoopBranch(conditionInstruction));
    loopInfo.condition = new SubExpression(conditionBlock,
                                           conditionExitBlock,
                                           conditionInstruction);

    LocalsHandler savedLocals = new LocalsHandler.from(localsHandler);

    // The body.
    HBasicBlock beginBodyBlock = addNewBlock();
    conditionExitBlock.addSuccessor(beginBodyBlock);
    open(beginBodyBlock);

    localsHandler.enterLoopBody(loop);
    hackAroundPossiblyAbortingBody(loop, body);

    SubGraph bodyGraph = new SubGraph(beginBodyBlock, current);
    HBasicBlock bodyBlock = close(new HGoto());
    loopInfo.body = bodyGraph;

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
      beginBodyBlock.blockInformation =
          new HLabeledBlockInformation(bodyGraph, updateBlock,
                                       jumpHandler.labels(), isContinue: true);
    } else if (target !== null && target.isContinueTarget) {
      beginBodyBlock.blockInformation =
          new HLabeledBlockInformation.implicit(bodyGraph, updateBlock,
                                                target, isContinue: true);
    }

    localsHandler.enterLoopUpdates(loop);

    update();

    HBasicBlock updateEndBlock = close(new HGoto());
    // The back-edge completing the cycle.
    updateEndBlock.addSuccessor(conditionBlock);
    conditionBlock.postProcessLoopHeader();
    loopInfo.updates = new SubGraph(updateBlock, updateEndBlock);

    endLoop(conditionBlock, conditionExitBlock, jumpHandler, savedLocals);
    loopInfo.joinBlock = current;
    initializerBlock.blockInformation = loopInfo;
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
    HLoopInformation loopInfo = current.blockInformation;
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
      if (!labels.isEmpty()) {
        bodyEntryBlock.blockInformation =
            new HLabeledBlockInformation(bodyGraph,
                                         conditionBlock,
                                         labels,
                                         isContinue: true);
      } else {
        bodyEntryBlock.blockInformation =
            new HLabeledBlockInformation.implicit(bodyGraph,
                                                  conditionBlock,
                                                  target,
                                                  isContinue: true);
      }
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

    loopInfo.body = new SubGraph(bodyEntryBlock, bodyExitBlock);
    loopInfo.condition = new SubExpression(conditionBlock, conditionEndBlock,
                                           conditionInstruction);
    loopInfo.joinBlock = current;
  }

  visitFunctionExpression(FunctionExpression node) {
    ClosureData nestedClosureData = compiler.builder.closureDataCache[node];
    if (nestedClosureData === null) {
      // TODO(floitsch): we can only assume that the reason for not having a
      // closure data here is, because the function is inside an initializer.
      compiler.unimplemented("Closures inside initializers", node: node);
    }
    assert(nestedClosureData !== null);
    assert(nestedClosureData.closureClassElement !== null);
    ClassElement closureClassElement =
        nestedClosureData.closureClassElement;
    FunctionElement callElement = nestedClosureData.callElement;
    compiler.enqueue(new WorkItem.toCodegen(callElement, elements));
    compiler.registerInstantiatedClass(closureClassElement);
    assert(closureClassElement.members.isEmpty());

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
    handleIf(() => visit(node.condition),
             () => visit(node.thenPart),
             node.elsePart != null ? () => visit(node.elsePart) : null);
  }

  void handleIf(void visitCondition(), void visitThen(), void visitElse()) {
    HBasicBlock conditionStartBlock = openNewBlock();
    visitCondition();
    SubExpression conditionGraph =
        new SubExpression(conditionStartBlock, lastOpenedBlock, stack.last());
    bool hasElse = visitElse != null;
    HInstruction condition = popBoolified();
    HIf branch = new HIf(condition, hasElse);
    HBasicBlock conditionBlock = close(branch);

    LocalsHandler savedLocals = new LocalsHandler.from(localsHandler);

    // The then part.
    HBasicBlock thenBlock = addNewBlock();
    conditionBlock.addSuccessor(thenBlock);
    open(thenBlock);
    visitThen();
    SubGraph thenGraph = new SubGraph(thenBlock, lastOpenedBlock);
    thenBlock = current;

    // Reset the locals state to the state after the condition and keep the
    // current state in [thenLocals].
    LocalsHandler thenLocals = localsHandler;

    // Now the else part.
    localsHandler = savedLocals;
    HBasicBlock elseBlock = null;
    SubGraph elseGraph = null;
    if (hasElse) {
      elseBlock = addNewBlock();
      conditionBlock.addSuccessor(elseBlock);
      open(elseBlock);
      visitElse();
      elseGraph = new SubGraph(elseBlock, lastOpenedBlock);
      elseBlock = current;
    }

    HBasicBlock joinBlock = null;
    if (thenBlock !== null || elseBlock !== null || !hasElse) {
      joinBlock = addNewBlock();
      if (thenBlock !== null) goto(thenBlock, joinBlock);
      if (elseBlock !== null) goto(elseBlock, joinBlock);
      else if (!hasElse) conditionBlock.addSuccessor(joinBlock);
      // If the join block has two predecessors we have to merge the
      // locals. The current locals is what either the
      // condition or the else block left us with, so we merge that
      // with the set of locals we got after visiting the then
      // part of the if.
      open(joinBlock);
      if (joinBlock.predecessors.length == 2) {
        localsHandler.mergeWith(thenLocals, joinBlock);
      } else if (thenBlock !== null) {
        // The only predecessor is the then branch.
        localsHandler = thenLocals;
      }
    }
    HIfBlockInformation info = new HIfBlockInformation(conditionGraph,
                                                       thenGraph,
                                                       elseGraph,
                                                       joinBlock);
    conditionStartBlock.blockInformation = info;
    branch.blockInformation = info;
  }

  void visitLogicalAndOr(Send node, Operator op) {
    handleLogicalAndOr(() { visit(node.receiver); },
                       () { visit(node.argumentsNode); },
                       isAnd: (const SourceString("&&") == op.source));
  }


  void handleLogicalAndOr(void left(), void right(), [bool isAnd = true]) {
    // x && y is transformed into:
    //   t0 = boolify(x);
    //   if (t0) t1 = boolify(y);
    //   result = phi(t0, t1);
    //
    // x || y is transformed into:
    //   t0 = boolify(x);
    //   if (not(t0)) t1 = boolify(y);
    //   result = phi(t0, t1);
    HBasicBlock leftBlock = openNewBlock();
    left();
    HInstruction boolifiedLeft = popBoolified();
    HInstruction condition;
    if (isAnd) {
      condition = boolifiedLeft;
    } else {
      condition = new HNot(boolifiedLeft);
      add(condition);
    }
    SubExpression leftGraph =
        new SubExpression(leftBlock, lastOpenedBlock, boolifiedLeft);
    HIf branch = new HIf(condition, false);
    leftBlock = close(branch);
    LocalsHandler savedLocals = new LocalsHandler.from(localsHandler);

    HBasicBlock rightBlock = addNewBlock();
    leftBlock.addSuccessor(rightBlock);
    open(rightBlock);

    right();
    HInstruction boolifiedRight = popBoolified();
    SubExpression rightGraph =
        new SubExpression(rightBlock, current, boolifiedRight);
    rightBlock = close(new HGoto());

    HBasicBlock joinBlock = addNewBlock();
    leftBlock.addSuccessor(joinBlock);
    rightBlock.addSuccessor(joinBlock);
    open(joinBlock);

    leftGraph.start.blockInformation =
        new HAndOrBlockInformation(isAnd, leftGraph, rightGraph, joinBlock);
    branch.blockInformation =
        new HIfBlockInformation(leftGraph, rightGraph, null, joinBlock);

    localsHandler.mergeWith(savedLocals, joinBlock);
    HPhi result = new HPhi.manyInputs(null,
        <HInstruction>[boolifiedLeft, boolifiedRight]);
    joinBlock.addPhi(result);
    stack.add(result);
  }

  void visitLogicalNot(Send node) {
    assert(node.argumentsNode is Prefix);
    visit(node.receiver);
    HNot not = new HNot(popBoolified());
    push(not);
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
    switch (op.source.stringValue) {
      case "-": result = new HNegate(target, operand); break;
      case "~": result = new HBitNot(target, operand); break;
      default: unreachable();
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
    push(result);
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
        push(new HAdd(target, left, right));
        break;
      case "-":
      case "--":
      case "-=":
        push(new HSubtract(target, left, right));
        break;
      case "*":
      case "*=":
        push(new HMultiply(target, left, right));
        break;
      case "/":
      case "/=":
        push(new HDivide(target, left, right));
        break;
      case "~/":
      case "~/=":
        push(new HTruncatingDivide(target, left, right));
        break;
      case "%":
      case "%=":
        push(new HModulo(target, left, right));
        break;
      case "<<":
      case "<<=":
        push(new HShiftLeft(target, left, right));
        break;
      case ">>":
      case ">>=":
        push(new HShiftRight(target, left, right));
        break;
      case "|":
      case "|=":
        push(new HBitOr(target, left, right));
        break;
      case "&":
      case "&=":
        push(new HBitAnd(target, left, right));
        break;
      case "^":
      case "^=":
        push(new HBitXor(target, left, right));
        break;
      case "==":
        push(new HEquals(target, left, right));
        break;
      case "===":
        push(new HIdentity(target, left, right));
        break;
      case "!==":
        HIdentity eq = new HIdentity(target, left, right);
        add(eq);
        push(new HNot(eq));
        break;
      case "<":
        push(new HLess(target, left, right));
        break;
      case "<=":
        push(new HLessEqual(target, left, right));
        break;
      case ">":
        push(new HGreater(target, left, right));
        break;
      case ">=":
        push(new HGreaterEqual(target, left, right));
        break;
      case "!=":
        HEquals eq = new HEquals(target, left, right);
        add(eq);
        HBoolify bl = new HBoolify(eq);
        add(bl);
        push(new HNot(bl));
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
    SourceString getterName = send.selector.asIdentifier().source;
    Selector selector = elements.getSelector(send);
    Element staticInterceptor = null;
    if (methodInterceptionEnabled) {
      staticInterceptor = interceptors.getStaticGetInterceptor(getterName);
    }
    if (staticInterceptor != null) {
      HStatic target = new HStatic(staticInterceptor);
      add(target);
      List<HInstruction> inputs = <HInstruction>[target, receiver];
      push(new HInvokeInterceptor(selector, getterName, true, inputs));
    } else {
      push(new HInvokeDynamicGetter(selector, null, getterName, receiver));
    }
  }

  void generateGetter(Send send, Element element) {
    if (Elements.isStaticOrTopLevelField(element)) {
      if (element.kind == ElementKind.FIELD && !element.isAssignable()) {
        // A static final. Get its constant value and inline it.
        Constant value = compiler.constantHandler.compileVariable(element);
        stack.add(graph.addConstant(value));
      } else {
        Selector selector = elements.getSelector(send);
        push(new HStatic(element));
        if (element.kind == ElementKind.GETTER) {
          push(new HInvokeStatic(selector, <HInstruction>[pop()]));
        }
      }
    } else if (Elements.isInstanceSend(send, elements)) {
      HInstruction receiver = generateInstanceSendReceiver(send);
      generateInstanceGetterWithCompiledReceiver(send, receiver);
    } else if (Elements.isStaticOrTopLevelFunction(element)) {
      push(new HStatic(element));
      compiler.registerGetOfStaticFunction(element);
    } else {
      stack.add(localsHandler.readLocal(element));
    }
  }

  void generateInstanceSetterWithCompiledReceiver(Send send,
                                                  HInstruction receiver,
                                                  HInstruction value) {
    assert(Elements.isInstanceSend(send, elements));
    SourceString dartSetterName = send.selector.asIdentifier().source;
    Selector selector = elements.getSelector(send);
    Element staticInterceptor = null;
    if (methodInterceptionEnabled) {
      staticInterceptor = interceptors.getStaticSetInterceptor(dartSetterName);
    }
    if (staticInterceptor != null) {
      HStatic target = new HStatic(staticInterceptor);
      add(target);
      List<HInstruction> inputs = <HInstruction>[target, receiver, value];
      add(new HInvokeInterceptor(selector, dartSetterName, false, inputs));
    } else {
      add(new HInvokeDynamicSetter(selector, null, dartSetterName,
                                   receiver, value));
    }
    stack.add(value);
  }

  void generateSetter(SendSet send, Element element, HInstruction value) {
    if (Elements.isStaticOrTopLevelField(element)) {
      Selector selector = elements.getSelector(send);
      if (element.kind == ElementKind.SETTER) {
        HStatic target = new HStatic(element);
        add(target);
        add(new HInvokeStatic(selector, <HInstruction>[target, value]));
      } else {
        add(new HStaticStore(element, value));
      }
      stack.add(value);
    } else if (element === null || Elements.isInstanceField(element)) {
      HInstruction receiver = generateInstanceSendReceiver(send);
      generateInstanceSetterWithCompiledReceiver(send, receiver, value);
    } else {
      localsHandler.updateLocal(element, value);
      stack.add(value);
      // If the value does not already have a name, give it here.
      if (value.sourceElement === null) {
        value.sourceElement = element;
      }
    }
  }

  visitOperatorSend(node) {
    assert(node.selector is Operator);
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
      if (type.element.kind === ElementKind.TYPE_VARIABLE) {
        // TODO(karlklose): We emulate the frog behavior and answer
        // true to any is check involving a type variable -- both is T
        // and is !T -- until we have a proper implementation of
        // reified generics.
        stack.add(graph.addConstantBool(true));
      } else {
        HInstruction instruction = new HIs(type, expression);
        if (isNot) {
          add(instruction);
          instruction = new HNot(instruction);
        }
        push(instruction);
      }
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
      push(new HInvokeInterceptor(selector, dartMethodName, false, inputs));
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
    push(new HInvokeDynamicMethod(selector, dartMethodName, inputs));

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
    push(new HInvokeClosure(selector, inputs));
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
        currentLibrary, Namer.OPERATOR_EQUALS, 1);
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
      HStatic target = new HStatic(element);
      add(target);
      push(new HInvokeStatic(Selector.INVOCATION_0,
                             <HInstruction>[target]));
    }
  }

  void handleForeignJsCallInIsolate(Send node) {
    Link<Node> link = node.arguments;
    if (!compiler.hasIsolateSupport()) {
      // If the isolate library is not used, we just invoke the
      // closure.
      visit(link.tail.head);
      push(new HInvokeClosure(Selector.INVOCATION_0,
                              <HInstruction>[pop()]));
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
      push(new HInvokeStatic(Selector.INVOCATION_0, inputs));
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
    FunctionParameters parameters = function.computeParameters(compiler);
    if (parameters.optionalParameterCount !== 0) {
      compiler.cancel(
          'JS_TO_CLOSURE does not handle closure with optional parameters',
          node: closure);
    }
    visit(closure);
    List<HInstruction> inputs = <HInstruction>[pop()];
    String invocationName = compiler.namer.closureInvocationName(
        new Selector(SelectorKind.INVOCATION,
                     parameters.requiredParameterCount));
    push(new HForeign(new DartString.literal('#.$invocationName'),
                      const LiteralDartString('var'),
                      inputs));
  }

  handleForeignSend(Send node) {
    Element element = elements[node];
    if (element.name == const SourceString('JS')) {
      handleForeignJs(node);
    } else if (element.name == const SourceString('UNINTERCEPTED')) {
      handleForeignUnintercepted(node);
    } else if (element.name == const SourceString('JS_HAS_EQUALS')) {
      handleForeignJsHasEquals(node);
    } else if (element.name == const SourceString('JS_CURRENT_ISOLATE')) {
      handleForeignJsCurrentIsolate(node);
    } else if (element.name == const SourceString('JS_CALL_IN_ISOLATE')) {
      handleForeignJsCallInIsolate(node);
    } else if (element.name == const SourceString('DART_CLOSURE_TO_JS')) {
      handleForeignDartClosureToJs(node);
    } else if (element.name == const SourceString('native')) {
      native.handleSsaNative(this, node);
    } else {
      throw "Unknown foreign: ${node.selector}";
    }
  }

  visitSuperSend(Send node) {
    Selector selector = elements.getSelector(node);
    Element element = elements[node];
    if (element === null) {
      ClassElement cls = work.element.getEnclosingClass();
      element = cls.lookupSuperMember(Compiler.NO_SUCH_METHOD);
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
          graph.addConstantString(new DartString.literal(name)),
          pop()];
      push(new HInvokeSuper(Selector.INVOCATION_2, inputs));
      return;
    }
    HInstruction target = new HStatic(element);
    HInstruction context = localsHandler.readThis();
    add(target);
    var inputs = <HInstruction>[target, context];
    if (element.kind == ElementKind.FUNCTION ||
        element.kind == ElementKind.GENERATIVE_CONSTRUCTOR) {
      bool succeeded = addStaticSendArgumentsToList(selector, node.arguments,
                                                    element, inputs);
      if (!succeeded) {
        // TODO(ngeoffray): Match the VM behavior and throw an
        // exception at runtime.
        compiler.cancel('Unimplemented non-matching static call', node);
      }
      push(new HInvokeSuper(selector, inputs));
    } else {
      target = new HInvokeSuper(Selector.GETTER, inputs);
      add(target);
      inputs = <HInstruction>[target];
      addDynamicSendArgumentsToList(node, inputs);
      push(new HInvokeClosure(selector, inputs));
    }
  }

  visitStaticSend(Send node) {
    Selector selector = elements.getSelector(node);
    Element element = elements[node];
    if (element.kind === ElementKind.GENERATIVE_CONSTRUCTOR) {
      compiler.resolver.resolveMethodElement(element);
      FunctionElement functionElement = element;
      element = functionElement.defaultImplementation;
    }
    HInstruction target = new HStatic(element);
    add(target);
    var inputs = <HInstruction>[];
    inputs.add(target);
    if (element.kind == ElementKind.FUNCTION ||
        element.kind == ElementKind.GENERATIVE_CONSTRUCTOR) {
      bool succeeded = addStaticSendArgumentsToList(selector, node.arguments,
                                                    element, inputs);
      if (!succeeded) {
        // TODO(ngeoffray): Match the VM behavior and throw an
        // exception at runtime.
        compiler.cancel('Unimplemented non-matching static call', node: node);
      }
      HType type = HType.UNKNOWN;
      Element originalElement = elements[node];
      if (originalElement.isGenerativeConstructor()
          && originalElement.enclosingElement === compiler.listClass) {
        if (node.arguments.isEmpty()) {
          type = HType.EXTENDABLE_ARRAY;
        } else {
          type = HType.MUTABLE_ARRAY;
        }
      } else if (element.isGenerativeConstructor()) {
        ClassElement cls = element.enclosingElement;
        type = new HNonPrimitiveType(cls.type);
      }
      push(new HInvokeStatic(selector, inputs, type));
    } else {
      if (element.kind == ElementKind.GETTER) {
        target = new HInvokeStatic(Selector.GETTER, inputs);
        add(target);
        inputs = <HInstruction>[target];
      }
      addDynamicSendArgumentsToList(node, inputs);
      push(new HInvokeClosure(selector, inputs));
    }
  }

  visitSend(Send node) {
    if (node.isSuperCall) {
      if (node.isPropertyAccess) {
        compiler.unimplemented('super property read', node: node);
      }
      visitSuperSend(node);
    } else if (node.selector is Operator && methodInterceptionEnabled) {
      visitOperatorSend(node);
    } else if (node.isPropertyAccess) {
      generateGetter(node, elements[node]);
    } else if (Elements.isClosureSend(node, elements)) {
      visitClosureSend(node);
    } else {
      Element element = elements[node];
      if (element === null) {
        // Example: f() with 'f' unbound.
        // This can only happen inside an instance method.
        visitDynamicSend(node);
      } else if (element.kind == ElementKind.CLASS) {
        compiler.internalError("Cannot generate code for send", node: node);
      } else if (element.isInstanceMember()) {
        // Example: f() with 'f' bound to instance method.
        visitDynamicSend(node);
      } else if (element.kind === ElementKind.FOREIGN) {
        handleForeignSend(node);
      } else if (!element.isInstanceMember()) {
        // Example: A.f() or f() with 'f' bound to a static function.
        // Also includes new A() or new A.named() which is treated like a
        // static call to a factory.
        visitStaticSend(node);
      } else {
        compiler.internalError("Cannot generate code for send", node: node);
      }
    }
  }

  visitNewExpression(NewExpression node) {
    if (node.isConst()) {
      ConstantHandler handler = compiler.constantHandler;
      Constant constant = handler.compileNodeWithDefinitions(node, elements);
      stack.add(graph.addConstant(constant));
    } else {
      visitSend(node.send);
    }
  }

  visitSendSet(SendSet node) {
    Operator op = node.assignmentOperator;
    if (node.isSuperCall) {
      compiler.unimplemented('super property store', node: node);
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
    stack.add(graph.addConstantString(node.dartString));
  }

  void visitStringJuxtaposition(StringJuxtaposition node) {
    if (!node.isInterpolation) {
      // This is a simple string with no interpolations.
      stack.add(graph.addConstantString(node.dartString));
      return;
    }
    int offset = node.getBeginToken().charOffset;
    StringBuilderVisitor stringBuilder =
        new StringBuilderVisitor(this, offset);
    stringBuilder.visit(node);
    stack.add(stringBuilder.result());
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
    unreachable();
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
    HInstruction value;
    if (node.expression === null) {
      value = graph.addConstantNull();
    } else {
      visit(node.expression);
      value = pop();
    }
    close(new HReturn(value)).addSuccessor(graph.exit);
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
    HBasicBlock conditionStartBlock = openNewBlock();
    visit(node.condition);
    HIf condition = new HIf(popBoolified(), true);
    SubExpression conditionGraph =
        new SubExpression(conditionStartBlock, current, condition);
    HBasicBlock conditionBlock = close(condition);
    LocalsHandler savedLocals = new LocalsHandler.from(localsHandler);

    HBasicBlock thenBlock = addNewBlock();
    conditionBlock.addSuccessor(thenBlock);
    open(thenBlock);
    visit(node.thenExpression);
    HInstruction thenInstruction = pop();
    SubGraph thenGraph = new SubGraph(thenBlock, current);
    thenBlock = close(new HGoto());
    LocalsHandler thenLocals = localsHandler;
    localsHandler = savedLocals;

    HBasicBlock elseBlock = addNewBlock();
    conditionBlock.addSuccessor(elseBlock);
    open(elseBlock);
    visit(node.elseExpression);
    HInstruction elseInstruction = pop();
    SubGraph elseGraph = new SubGraph(elseBlock, current);
    elseBlock = close(new HGoto());

    HBasicBlock joinBlock = addNewBlock();
    thenBlock.addSuccessor(joinBlock);
    elseBlock.addSuccessor(joinBlock);
    condition.blockInformation = new HIfBlockInformation(conditionGraph,
                                                         thenGraph,
                                                         elseGraph,
                                                         joinBlock);
    open(joinBlock);

    localsHandler.mergeWith(thenLocals, joinBlock);
    HPhi phi = new HPhi.manyInputs(null,
        <HInstruction>[thenInstruction, elseInstruction]);
    joinBlock.addPhi(phi);
    stack.add(phi);
  }

  visitStringInterpolation(StringInterpolation node) {
    int offset = node.getBeginToken().charOffset;
    StringBuilderVisitor stringBuilder =
        new StringBuilderVisitor(this, offset);
    stringBuilder.visit(node);
    stack.add(stringBuilder.result());
  }

  visitStringInterpolationPart(StringInterpolationPart node) {
    // The parts are iterated in visitStringInterpolation.
    unreachable();
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
    work.allowSpeculativeOptimization = false;
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
      return const NullJumpHandler();
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

    // All the generated calls are to zero-argument functions.
    Selector selector = Selector.INVOCATION_0;
    // The iterator is shared between initializer, condition and body.
    HInstruction iterator;
    void buildInitializer() {
      SourceString iteratorName = const SourceString("iterator");
      Element interceptor = interceptors.getStaticInterceptor(iteratorName, 0);
      assert(interceptor != null);
      HStatic target = new HStatic(interceptor);
      add(target);
      visit(node.expression);
      List<HInstruction> inputs = <HInstruction>[target, pop()];
      iterator = new HInvokeInterceptor(selector, iteratorName, false, inputs);
      add(iterator);
    }
    HInstruction buildCondition() {
      push(new HInvokeDynamicMethod(
           selector, const SourceString('hasNext'), <HInstruction>[iterator]));
      return popBoolified();
    }
    void buildBody() {
      push(new HInvokeDynamicMethod(
           selector, const SourceString('next'), <HInstruction>[iterator]));

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

  visitLabeledStatement(LabeledStatement node) {
    Statement body = node.getBody();
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
      entryBlock.blockInformation =
          new HLabeledBlockInformation(bodyGraph, joinBlock, handler.labels());
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
    HStatic mapMaker = new HStatic(interceptors.getMapMaker());
    add(keyValuePairs);
    add(mapMaker);
    inputs = <HInstruction>[mapMaker, keyValuePairs];
    // TODO(ngeoffray): give the concrete type of our map literal.
    push(new HInvokeStatic(Selector.INVOCATION_1, inputs, HType.UNKNOWN));
  }

  visitLiteralMapEntry(LiteralMapEntry node) {
    visit(node.value);
    visit(node.key);
  }

  visitNamedArgument(NamedArgument node) {
    visit(node.expression);
  }

  visitSwitchStatement(SwitchStatement node) {
    work.allowSpeculativeOptimization = false;
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
    startBlock.blockInformation = new HLabeledBlockInformation.implicit(
        new SubGraph(startBlock, lastBlock),
        joinBlock,
        elements[node]);
    jumpHandler.close();
  }


  // Recursively build an if/else structure to match the cases.
  buildSwitchCases(Link<Node> cases, HInstruction expression) {
    SwitchCase node = cases.head;

    // Called for the statements on all but the last case block.
    // Ensures that a user expecting a fallthrough gets an error.
    void visitStatementsAndAbort() {
      visit(node.statements);
      if (!isAborted()) {
        compiler.reportWarning(node, 'Missing break at end of switch case');
        Element element =
            compiler.findHelper(const SourceString("getFallThroughError"));
        push(new HStatic(element));
        HInstruction error = new HInvokeStatic(
             Selector.INVOCATION_0, <HInstruction>[pop()]);
        add(error);
        close(new HThrow(error));
      }
    }

    Link<Node> expressions = node.expressions.nodes;
    if (expressions.isEmpty()) {
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
    void buildTests(Link<Node> remainingExpressions) {
      // Build comparison for one case expression.
      void left() {
        Element equalsHelper = interceptors.getEqualsInterceptor();
        HInstruction target = new HStatic(equalsHelper);
        add(target);
        visit(remainingExpressions.head);
        push(new HEquals(target, pop(), expression));
      }

      // If this is the last expression, just return it.
      if (remainingExpressions.tail.isEmpty()) {
        left();
        return;
      }

      void right() {
        buildTests(remainingExpressions.tail);
      }
      handleLogicalAndOr(left, right, isAnd: false);
    }

    if (node.isDefaultCase) {
      buildTests(expressions);
      // Throw away the test result. We always execute the default case.
      pop();
      visit(node.statements);
    } else {
      if (cases.tail.isEmpty()) {
        handleIf(() { buildTests(expressions); },
                 () { visit(node.statements); },
                 null);
      } else {
        handleIf(() { buildTests(expressions); },
                 () { visitStatementsAndAbort(); },
                 () { buildSwitchCases(cases.tail, expression); });
      }
    }
  }

  visitSwitchCase(SwitchCase node) {
    unreachable();
  }

  visitTryStatement(TryStatement node) {
    work.allowSpeculativeOptimization = false;
    HBasicBlock enterBlock = openNewBlock();
    HTry tryInstruction = new HTry();
    List<HBasicBlock> blocks = <HBasicBlock>[];
    blocks.add(close(tryInstruction));

    HBasicBlock tryBody = graph.addNewBlock();
    enterBlock.addSuccessor(tryBody);
    open(tryBody);
    visit(node.tryBlock);
    if (!isAborted()) blocks.add(close(new HGoto()));

    if (!node.catchBlocks.isEmpty()) {
      HBasicBlock block = graph.addNewBlock();
      enterBlock.addSuccessor(block);
      open(block);
      // Note that the name of this element is irrelevant.
      Element element = new Element(
          const SourceString('exception'), ElementKind.PARAMETER, work.element);
      HParameterValue exception = new HParameterValue(element);
      add(exception);
      HInstruction oldRethrowableException = rethrowableException;
      rethrowableException = exception;
      push(new HStatic(interceptors.getExceptionUnwrapper()));
      List<HInstruction> inputs = <HInstruction>[pop(), exception];
      HInvokeStatic unwrappedException =
          new HInvokeStatic(Selector.INVOCATION_1, inputs);
      add(unwrappedException);
      tryInstruction.exception = exception;

      Link<Node> link = node.catchBlocks.nodes;

      void pushCondition(CatchBlock catchBlock) {
        VariableDefinitions declaration = catchBlock.formals.nodes.head;
        HInstruction condition = null;
        if (declaration.type == null) {
          condition = graph.addConstantBool(true);
          stack.add(condition);
        } else {
          Type type = elements.getType(declaration.type);
          if (type == null) {
            compiler.cancel('Catch with unresolved type', node: catchBlock);
          }
          condition = new HIs(type, unwrappedException, nullOk: true);
          push(condition);
        }
      }

      void visitThen() {
        CatchBlock catchBlock = link.head;
        link = link.tail;
        localsHandler.updateLocal(elements[catchBlock.exception],
                                  unwrappedException);
        Node trace = catchBlock.trace;
        if (trace != null) {
          push(new HStatic(interceptors.getTraceFromException()));
          HInstruction traceInstruction = new HInvokeStatic(
              Selector.INVOCATION_1, <HInstruction>[pop(), exception]);
          add(traceInstruction);
          localsHandler.updateLocal(elements[trace], traceInstruction);
        }
        visit(catchBlock);
      }

      void visitElse() {
        if (link.isEmpty()) {
          close(new HThrow(exception, isRethrow: true));
        } else {
          CatchBlock newBlock = link.head;
          handleIf(() { pushCondition(newBlock); },
                   visitThen, visitElse);
        }
      }

      CatchBlock firstBlock = link.head;
      handleIf(() { pushCondition(firstBlock); }, visitThen, visitElse);
      if (!isAborted()) blocks.add(close(new HGoto()));
      rethrowableException = oldRethrowableException;
    }

    if (node.finallyBlock != null) {
      HBasicBlock finallyBlock = graph.addNewBlock();
      enterBlock.addSuccessor(finallyBlock);
      open(finallyBlock);
      visit(node.finallyBlock);
      if (!isAborted()) blocks.add(close(new HGoto()));
      tryInstruction.finallyBlock = finallyBlock;
    }

    HBasicBlock exitBlock = graph.addNewBlock();

    for (HBasicBlock block in blocks) {
      block.addSuccessor(exitBlock);
    }

    open(exitBlock);
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

  generateUnimplemented(String reason, [bool isExpression = false]) {
    DartString string = new DartString.literal(reason);
    HInstruction message = graph.addConstantString(string);

    // Normally, we would call [close] here. However, then we hit
    // another unimplemented feature: aborting loop body. Simply
    // calling [add] does not work as it asserts that the instruction
    // isn't a control flow instruction. So we inline parts of [add].
    current.addAfter(current.last, new HThrow(message));
    if (isExpression) {
      stack.add(graph.addConstantNull());
    }
  }

  /** HACK HACK HACK */
  void hackAroundPossiblyAbortingBody(Node statement, void body()) {
    visitCondition() {
      stack.add(graph.addConstantBool(true));
    }
    buildBody() {
      // TODO(lrn): Make sure to take continue into account.
      body();
      if (isAborted()) {
        compiler.reportWarning(statement, "aborting loop body");
      }
    }
    handleIf(visitCondition, buildBody, null);
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

  /**
   * Offset used for the synthetic operator token used by concat.
   * Can probably be removed when we stop using String.operator+.
   */
  final int offset;

  /**
   * Used to collect concatenated string literals into a single literal
   * instead of introducing unnecessary concatenations.
   */
  DartString literalAccumulator = const LiteralDartString("");

  /**
   * The string value generated so far (not including that which is still
   * in [literalAccumulator]).
   */
  HInstruction prefix = null;

  StringBuilderVisitor(this.builder, this.offset);

  void visit(Node node) {
    node.accept(this);
  }

  visitNode(Node node) {
    builder.compiler.internalError('unexpected node', node: node);
  }

  void visitExpression(Node node) {
    flushLiterals();
    node.accept(builder);
    HInstruction asString = buildToString(node, builder.pop());
    prefix = concat(prefix, asString);
  }

  void visitLiteralNull(LiteralNull node) {
    addLiteral(const LiteralDartString("null"));
  }

  void visitLiteralInt(LiteralInt node) {
    addLiteral(new DartString.literal(node.value.toString()));
  }

  void visitLiteralDouble(LiteralDouble node) {
    addLiteral(new DartString.literal(node.value.toString()));
  }

  void visitLiteralBool(LiteralBool node) {
    addLiteral(node.value ? const LiteralDartString("true")
                          : const LiteralDartString("false"));
  }

  void visitStringInterpolation(StringInterpolation node) {
    node.visitChildren(this);
  }

  void visitStringInterpolationPart(StringInterpolationPart node) {
    visit(node.expression);
    visit(node.string);
  }

  void visitLiteralString(LiteralString node) {
    addLiteral(node.dartString);
  }

  void visitStringJuxtaposition(StringJuxtaposition node) {
    node.visitChildren(this);
  }

  void visitNodeList(NodeList node) {
     node.visitChildren(this);
  }

  /**
   * Add another literal string to the literalAccumulator.
   */
  void addLiteral(DartString dartString) {
    literalAccumulator = new DartString.concat(literalAccumulator, dartString);
  }

  /**
   * Combine the strings in [literalAccumulator] into the prefix instruction.
   * After this, the [literalAccumulator] is empty and [prefix] is non-null.
   */
  void flushLiterals() {
    if (literalAccumulator.isEmpty()) {
      if (prefix === null) {
        prefix = builder.graph.addConstantString(literalAccumulator);
      }
      return;
    }
    HInstruction string = builder.graph.addConstantString(literalAccumulator);
    literalAccumulator = new DartString.empty();
    if (prefix !== null) {
      prefix = concat(prefix, string);
    } else {
      prefix = string;
    }
  }

  HInstruction concat(HInstruction left, HInstruction right) {
    SourceString dartMethodName = const SourceString("concat");
    if (!builder.methodInterceptionEnabled) {
      builder.compiler.internalError(
        "Using string interpolations in non-intercepted code.",
        instruction: right);
    }
    Element interceptor =
        builder.interceptors.getStaticInterceptor(dartMethodName, 1);
    if (interceptor === null) {
      builder.compiler.internalError(
          "concat not intercepted.", instruction: left);
    }
    HStatic target = new HStatic(interceptor);
    builder.add(target);
    builder.push(new HInvokeInterceptor(Selector.INVOCATION_1,
                                        dartMethodName,
                                        false,
                                        <HInstruction>[target, left, right]));
    return builder.pop();
  }

  HInstruction buildToString(Node node, HInstruction input) {
    SourceString dartMethodName = const SourceString("toString");
    if (!builder.methodInterceptionEnabled) {
      builder.compiler.internalError(
        "Using string interpolations in non-intercepted code.", node: node);
    }
    Element interceptor =
        builder.interceptors.getStaticInterceptor(dartMethodName, 0);
    if (interceptor === null) {
      builder.compiler.internalError(
        "toString not intercepted.", node: node);
    }
    HStatic target = new HStatic(interceptor);
    builder.add(target);
    builder.push(new HInvokeInterceptor(Selector.INVOCATION_0,
                                        dartMethodName,
                                        false,
                                        <HInstruction>[target, input]));
    return builder.pop();
  }

  HInstruction result() {
    flushLiterals();
    return prefix;
  }
}
